# Torizon OS Build Status - Data Acquisition #

This application gathers data from a local Jenkins instance (requires VPN)
and stores it on a InfluxDB database.

## Testing ##

This works locally on a PC, there are no specific dependencies on the hardware.

Bring up the debug Docker Compose file:

```shell
docker compose -f docker-compose.prod.yml down && docker compose -f docker-compose.prod.yml up --pull always --force-recreate
```
