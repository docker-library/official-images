#!/bin/bash

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cname="silverpeas-container-$RANDOM-$RANDOM"

# when running the first time, a silverpeas process is spawn before starting Silverpeas
# (this configuration process can take some time)
cid="$(docker run -d -e DB_SERVERTYPE="H2" -e DB_SERVER=":file:" -e DB_PASSWORD="sa" --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

# the maximum time for Silverpeas to be configured and to be started (if no errors)
sleep 120s

silverpeas_status="$(docker exec "$cname" /opt/silverpeas/bin/silverpeas status)"

[ "`echo $silverpeas_status`" = "Configured: [OK] Running: [OK] Active: [OK] INFO: JBoss is running" ]
