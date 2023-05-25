#!/bin/bash

BASEDIR=${1:-/serverfiles}
EVENTS_FILE=/tmp/events.csv
PREFIX="\[HoMe\]"
GSA_CONTROL="${BASEDIR}/gsa-control.sh"
GUS="${BASEDIR}/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
GINI="${BASEDIR}/ShooterGame/Saved/Config/LinuxServer/Game.ini"

if [ ! -f $GSA_CONTROL ]; then
  echo "GSA_CONTROL file not found";
  exit 1;
fi

echo "Fetching the list of events"
curl -s -o /tmp/events.csv -f https://raw.githubusercontent.com/meza/HoMe-Ark-Cluster-Management/main/events.csv

# Set active event

#Parse the events.csv file and return the active event string for today
#The events.csv file should be in the following format:
#start_year;start_month;start_day;end_year;end_month;end_day;event_name
#all dates are inclusive
#If no event is active, return an empty string
get_active_event() {
  local date=$(date +%s)
  local start_year start_month start_day end_year end_month end_day event_name
  while IFS=';' read -r start_year start_month start_day end_year end_month end_day event_name; do
    local start_date="$start_year-$start_month-$start_day"
    local end_date="$end_year-$end_month-$end_day"
    if [[ $date -ge $(date -d "$start_date" +%s) && "$date" -le $(date -d "$end_date" +%s) ]]; then
      echo "$event_name"
      break
    fi
  done < $EVENTS_FILE
  echo ""
}

ACTIVE_EVENT="$(get_active_event)"

if [ -n "$ACTIVE_EVENT" ]; then
  echo "Active event: $ACTIVE_EVENT"
else
  echo "No active event"
fi

## Clear the flag
sed -i "s/%%EVENT%%/-ActiveEvent=$ACTIVE_EVENT/g" $GSA_CONTROL

# Override Settings

## Aberration
if grep -q "$PREFIX Aberration" $GSA_CONTROL; then
  echo "Overriding the DayTimeScale to be default"
  sed -i "s/DayTimeSpeedScale=.5/DayTimeSpeedScale=1/g" $GUS
fi

## Overrides Non-Story maps
if grep -q "No Item / Dino Transfer" $GSA_CONTROL; then
  echo "Overriding Transfer Prevention"
  sed -i "s/PreventUploadItems=False/PreventUploadItems=True/g" $GUS
  sed -i "s/PreventUploadDinos=False/PreventUploadDinos=True/g" $GUS
  sed -i "s/PreventDownloadItems=False/PreventDownloadItems=True/g" $GUS
  sed -i "s/PreventDownloadDinos=False/PreventDownloadDinos=True/g" $GUS
fi
