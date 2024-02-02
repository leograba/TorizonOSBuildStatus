#!/bin/bash

JENKINS_URL="https://jenkins.int.toradex.com/buildStatus/text"
JOB_LIST=(
    "kirkstone-6.x.y-nightly"
    "kirkstone-6.x.y-release"
    "dunfell-5.x.y-nightly"
    "dunfell-5.x.y-release"
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

if [[ -n "$DEBUG" ]]; then
    POLL_INTERVAL_SEC=60
    echo "Debug mode enabled"
else
    POLL_INTERVAL_SEC=3600
    echo "Debug mode disabled"
fi
echo "Polling interval set to $POLL_INTERVAL_SEC seconds"

# Trap Ctrl+C and clean up before exiting
function cleanup() {
    echo "Exiting..."
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
            if [ -n "$jobstatus" ]; then
                buildstatus="${buildstatus}${image}-${job}=\"${jobstatus}\","
                echo "Element: $job     | Value: $jobstatus"
            else
                echo "Element: $job returned an empty value"
                buildstatus="${buildstatus}${image}-${job}=\"Unavailable\","
            fi
        done
    done

    # Remove trailing comma
    buildstatus=${buildstatus::-1}
    echo "Line protocol data: $buildstatus"

    # Write data into DB
    influx write --bucket $INFLUX_BUCKET_NAME "$buildstatus"
}

# Wait for services to be up and running
while ! influx ping; do
    echo "Waiting for InfluxDB to be ready..."
    sleep 1
done
echo "InfluxDB ready!"

# Create bucket with a defined retention period
create_update_bucket

while true; do
    # Get data points into database
    insert_into_influxdb

    # Wait POLL_INTERVAL_SEC until the next data acquisition
    sleep $POLL_INTERVAL_SEC
done
