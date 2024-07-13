#!/bin/bash

JENKINS_URL="https://jenkins.int.toradex.com/buildStatus/text"
JOB_LIST=(
    "scarthgap-7.x.y-nightly"
    "scarthgap-7.x.y-monthly"
    "scarthgap-7.x.y-release"
    "scarthgap-7.x.y-extint"
    "kirkstone-6.x.y-nightly"
    "kirkstone-6.x.y-monthly"
    "kirkstone-6.x.y-release"
    "kirkstone-6.x.y-extint"
    "dunfell-5.x.y-nightly"
    "dunfell-5.x.y-monthly"
    "dunfell-5.x.y-release"
    "dunfell-5.x.y-extint"
    "master-extint"
)
IMAGE_TYPE=(
    "tdxref"
    "torizoncore"
)
INFLUX_MEASUREMENT_NAME="jenkinsbuild"
INFLUX_BUCKET_NAME="jenkinsdatabucket"
INFLUX_BUCKET_RETENTION="180d"
CURL_MAX_RETRIES=30
declare -A log_levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
script_logging_level="INFO"

# Logging function
logger() {
    local log_message=$1
    local log_priority=$2

    #check if level exists
    [[ ${log_levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${log_levels[$log_priority]} < ${log_levels[$script_logging_level]} )) && return 2

    #log here
    echo "${log_priority} : ${log_message}"
}

# Initialization checks
if [[ -n "$DEBUG" ]]; then
    POLL_INTERVAL_SEC_DEBUG=60
    POLL_INTERVAL_SEC=${POLL_INTERVAL_SEC_DEBUG}
    script_logging_level="$DEBUG"
    logger "Debug mode enabled. Log level set to ${script_logging_level}" "INFO"
else
    POLL_INTERVAL_SEC=3600
    logger "Debug mode disabled" "INFO"
fi
logger "Polling interval set to $POLL_INTERVAL_SEC seconds" "INFO"

if [[ -n "$DEMO" ]]; then
    logger "Demo mode enabled" "INFO"
    logger "Generating fake data at every poll interval" "INFO"
    FAKEDATECOUNT=190
else
    logger "Demo mode disabled" "INFO"
fi

# Trap Ctrl+C and clean up before exiting
function cleanup() {
    logger "Exiting..." "WARN"
    exit
}

trap cleanup SIGINT SIGTERM

function create_update_bucket() {
    # Check if bucket already exists, get the bucket ID, and act accordingly
    if ! influx_bucket_id=$(\
            influx bucket list --name $INFLUX_BUCKET_NAME --json | jq -r '.[] | .id')
    then
        influx bucket create --name $INFLUX_BUCKET_NAME --retention $INFLUX_BUCKET_RETENTION
    else
        influx bucket update --id "$influx_bucket_id" --retention $INFLUX_BUCKET_RETENTION
    fi
}

function gen_fake_data() {
    FAKES=(
        "Aborted"
        "Failed"
        "In progress"
        "Not built"
        "Success"
        "Not available"
        "Unstable"
    )
    # Get data points in a line protocol format
    # https://docs.influxdata.com/influxdb/v2/get-started/write/?t=influx+CLI#line-protocol
    local buildstatus="$INFLUX_MEASUREMENT_NAME "
    local jobstatus=""
    local randn="100"

    for image in "${IMAGE_TYPE[@]}"; do
        for job in "${JOB_LIST[@]}"; do
            jobstatus=${FAKES[ $randn % ${#FAKES[@]} ]}
            buildstatus="${buildstatus}${image}-${job}=\"${jobstatus}\","
            logger "Element: $job     | Value: $jobstatus" "DEBUG"
            ((randn++))
        done
    done

    # Remove trailing comma
    buildstatus=${buildstatus::-1}

    # Add timestamp during the first iterations
    if [ "$FAKEDATECOUNT" -ne "0" ]; then
        buildstatus="${buildstatus} $(date -d "$FAKEDATECOUNT day ago" +%s)"
        ((FAKEDATECOUNT--))
        POLL_INTERVAL_SEC=0.1
    else
        buildstatus="${buildstatus} $(date +%s)"
        POLL_INTERVAL_SEC=${POLL_INTERVAL_SEC_DEBUG}
    fi

    # Write data into DB
    logger "Line protocol data: $buildstatus" "DEBUG"
    influx write --bucket $INFLUX_BUCKET_NAME --precision s "$buildstatus"
}

function insert_into_influxdb() {
    # Get data points in a line protocol format
    # https://docs.influxdata.com/influxdb/v2/get-started/write/?t=influx+CLI#line-protocol
    local buildstatus="$INFLUX_MEASUREMENT_NAME "

    for image in "${IMAGE_TYPE[@]}"; do
        for job in "${JOB_LIST[@]}"; do
            # Jenkins Embeddable Build Status strings
            # https://plugins.jenkins.io/embeddable-build-status/#plugin-content-text-variant
            jobstatus=$(curl \
                            --silent --retry $CURL_MAX_RETRIES \
                            --retry-delay 1 --retry-all-errors \
                            "${JENKINS_URL}?job=image-${image}-${job}-matrix")
            # Validate the data
            if [ -z "$jobstatus" ]; then
                logger "Element: $job returned an empty value" "WARN"
                buildstatus="${buildstatus}${image}-${job}=\"Unavailable\","
            elif [[ "$jobstatus" =~ "<html>" ]]; then
                logger "Element: $job returned an HTML page which is invalid" "WARN"
                buildstatus="${buildstatus}${image}-${job}=\"Invalid\","
            else
                buildstatus="${buildstatus}${image}-${job}=\"${jobstatus}\","
                logger "Element: $job     | Value: $jobstatus" "DEBUG"
            fi
        done
    done

    # Remove trailing comma
    buildstatus=${buildstatus::-1}
    logger "Line protocol data: $buildstatus" "DEBUG"

    # Write data into DB
    influx write --bucket $INFLUX_BUCKET_NAME "$buildstatus"
}

# Wait for services to be up and running
while ! influx ping; do
    logger "Waiting for InfluxDB to be ready..." "DEBUG"
    sleep 1
done
logger "InfluxDB ready!" "INFO"

# Create bucket with a defined retention period
create_update_bucket

while true; do

    if [[ -n "$DEMO" ]]; then
        gen_fake_data
    else
        # Get real data points into database
        insert_into_influxdb
    fi

    # Wait POLL_INTERVAL_SEC until the next data acquisition
    sleep "$POLL_INTERVAL_SEC"
done
