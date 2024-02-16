#!/bin/bash

# This script gets the filesystem usage of a mount point from a remote server via SSH and sends the values to Home Assistant. It can also notify you via Apprise API if the storage gets low.
# The script is optimised to work with Hetzner Storage Boxes but should work on most Linux servers.
# Call this script regularily via a scheduler like cron. Remember to chmod +x this script.
# https://github.com/MadWalnut/disk-usage-to-home-assistant

# ----------------------------------
# ---------- CONFIG START ----------
# ----------------------------------

# SSH server IP / hostname.
SSH_SERVER=u123456.your-storagebox.de

# SSH port. Usually 22. For Hetzner Storage Boxes use 23 and enable the SSH service in Hetzner Robot.
SSH_PORT=23

# SSH user.
SSH_USER=u123456

# SSH private key path (identity file). Set chmod 600.
SSH_KEY_PATH=~/.ssh/id_rsa

# Server name. Used as the entity name in Home Assistant and for Apprise alerts.
SERVER_NAME="Hetzner Storage Box"

# Home Assistant sensor prefix (part of the entity ID). Usually the server name. Use underscores instead of spaces and lowercase only.
SENSOR_PREFIX="hetzner_storage_box"

# df path. / for most Linux servers or /home for Hetzner Storage Boxes.
DF_PATH=/home

# Home Assistant URL (without trailing slash).
HOME_ASSISTANT_URL=https://home-assistant.example.com

# Home Assistant long-lived access token. Create one in your profile (scroll down).
TOKEN=XXX

# Healthchecks URL: https://healthchecks.io. Also supports other services like Uptime Kuma (push type). Leave empty if not to be used. To disable the Healthchecks feature (not recommended), comment out the curl call at the end of this script.
HEALTHCHECKS_URL=https://hc-ping.com/XXX

# Apprise URL: https://github.com/caronc/apprise-api. Set THRESHOLD to 101 or higher if not to be used.
APPRISE_URL=https://apprise.example.com/notify/apprise

# Apprise tag / notification channel.
APPRISE_TAG=all

# Apprise alert threshold. If the storage percentage reaches this value, an alert is sent via Apprise. Set to value 101 or higher to disable the notification (for example if you prefer using a Home Assistant automation).
THRESHOLD=90

# ----------------------------------
# ----------- CONFIG END -----------
# ----------------------------------

# Abort the script if any command fails (non-zero exit code). This ensures Healthchecks is only notified if all commands succeed and no incomplete data is sent to Home Assistant.
set -Eeuo pipefail

# Read storage information from server.
OUTPUT=$(ssh ${SSH_SERVER} -l ${SSH_USER} -p ${SSH_PORT} -i ${SSH_KEY_PATH} df -m)

# Extract total MB and convert to GB.
TOTAL_MB=$(echo "${OUTPUT}" | awk '$NF == "'${DF_PATH}'" { print $2 }')
TOTAL_GB="$((${TOTAL_MB} / 1024))"

# Extract used MB and convert to GB.
USED_MB=$(echo "${OUTPUT}" | awk '$NF == "'${DF_PATH}'" { print $3 }')
USED_GB="$((${USED_MB} / 1024))"

# Extract available MB and convert to GB.
AVAILABLE_MB=$(echo "${OUTPUT}" | awk '$NF == "'${DF_PATH}'" { print $4 }')
AVAILABLE_GB="$((${AVAILABLE_MB} / 1024))"

# Extract used percentage and remove trailing "%".
USED_PERCENTAGE=$(echo "${OUTPUT}" | awk '$NF == "'${DF_PATH}'" { print $5 }')
USED_PERCENTAGE_RAW=${USED_PERCENTAGE::-1}

# Send relevant values to Home Assistant.
# TOTAL_GB.
curl -sSf -o /dev/null -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "{\"state\": \"${TOTAL_GB}\", \"attributes\": {\"unit_of_measurement\": \"GB\", \"friendly_name\": \"${SERVER_NAME} Total GB\"}}" ${HOME_ASSISTANT_URL}/api/states/sensor.${SENSOR_PREFIX}_total_gb
# USED_GB.
curl -sSf -o /dev/null -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "{\"state\": \"${USED_GB}\", \"attributes\": {\"unit_of_measurement\": \"GB\", \"friendly_name\": \"${SERVER_NAME} Used GB\"}}" ${HOME_ASSISTANT_URL}/api/states/sensor.${SENSOR_PREFIX}_used_gb
# AVAILABLE_GB.
curl -sSf -o /dev/null -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "{\"state\": \"${AVAILABLE_GB}\", \"attributes\": {\"unit_of_measurement\": \"GB\", \"friendly_name\": \"${SERVER_NAME} Available GB\"}}" ${HOME_ASSISTANT_URL}/api/states/sensor.${SENSOR_PREFIX}_available_gb
# USED_PERCENTAGE_RAW.
curl -sSf -o /dev/null -X POST -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "{\"state\": \"${USED_PERCENTAGE_RAW}\", \"attributes\": {\"unit_of_measurement\": \"%\", \"friendly_name\": \"${SERVER_NAME} Used Percentage\"}}" ${HOME_ASSISTANT_URL}/api/states/sensor.${SENSOR_PREFIX}_used_percentage

# Trigger Apprise if percentage is at or over threshold.
if [ ${USED_PERCENTAGE_RAW} -ge ${THRESHOLD} ]; then
  curl -sSf -o /dev/null -X POST -d "tag=${APPRISE_TAG}&type=warning&title=${SERVER_NAME} Alert&body=Storage usage is at ${USED_PERCENTAGE}." ${APPRISE_URL}
fi

# Notify Healthchecks. This will not be called if there is an error due to the enabled pipefail at the beginning of the script. If no call reaches Healthchecks in your specified time, Healthchecks will notify you about the failure.
curl -sSf -m 10 --retry 5 ${HEALTHCHECKS_URL}

# Cleaner console output by printing a newline.
echo
