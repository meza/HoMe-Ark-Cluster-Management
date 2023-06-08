#!/bin/bash
WEBHOOK_URL="https://discord.com/api/webhooks/941301089305767986/6LCTr29ms0edoQBepOMj_hIGiSepp_IgYsPGf3sc_hojjImUxCNHoW64LfqckvnVmxug"
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


# -------------------------------------------- Functions ---------------------------------------------------------------

get_long_name() {
  local short_name="{$1,,}"

  case $short_name in
    vday)
      echo "Love Evolved"
      ;;
    easter)
      echo "Eggcelect Adventure"
      ;;
    birthday)
      echo "Anniversary"
      ;;
    summer)
      echo "Summer Bash"
      ;;
    fearevolved)
      echo "Fear Evolved"
      ;;
    turkeytrial)
      echo "Turkey Trial"
      ;;
    winterwonderland)
      echo "Winter Wonderland"
      ;;
    *)
      echo ""
      ;;
  esac
}

get_active_event() {
  # Parse the events.csv file and return the active event string for today
  # The events.csv file should be in the following format:
  # start_year;start_month;start_day;end_year;end_month;end_day;event_name
  # all dates are inclusive

  echo "Fetching the list of events"
  curl -s -o $EVENTS_FILE -f https://raw.githubusercontent.com/meza/HoMe-Ark-Cluster-Management/main/events.csv

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

# ----------------------------------------- SET ACTIVE EVENT -----------------------------------------------------------

ACTIVE_EVENT="$(get_active_event)"

if [ -n "$ACTIVE_EVENT" ]; then
  echo "Active event: $ACTIVE_EVENT"
else
  echo "No active event"
fi

## Clear the flag
sed -i "s/%%EVENT%%/-ActiveEvent=$ACTIVE_EVENT/g" "$GSA_CONTROL"

if [ ! -f "${BASEDIR}/currentevent.txt" ] && [ -n "$ACTIVE_EVENT" ]; then
  echo "$ACTIVE_EVENT" > "${BASEDIR}/currentevent.txt"
  echo "The event $ACTIVE_EVENT is active"
  if grep -q "$PREFIX Island" "$GSA_CONTROL"; then
    echo "Broadcasting the event"
  fi
fi

if [ -f "${BASEDIR}/currentevent.txt" ] && [ -z "$ACTIVE_EVENT" ]; then
  CURRENT_EVENT=$(cat "${BASEDIR}/currentevent.txt")
  rm "${BASEDIR}/currentevent.txt"
  echo "The event $CURRENT_EVENT is no longer active"
  if grep -q "$PREFIX Island" "$GSA_CONTROL"; then
      echo "Broadcasting the end of the event"
  fi
fi


# ----------------------------------------------------------------------------------------------------------------------

# Override Settings

## Aberration
if grep -q "$PREFIX Aberration" "$GSA_CONTROL"; then
  echo "Overriding the DayTimeScale to be default"
  sed -i "s/DayTimeSpeedScale=.5/DayTimeSpeedScale=1/g" $GUS
fi

## Svartalfheim
if grep -q "No Transfer" "$GSA_CONTROL"; then
  echo "Overriding Transfer Prevention for Svartalfheim"
  sed -i "s/PreventDownloadSurvivors=False/PreventDownloadSurvivors=True/g" $GUS
  sed -i "s/PreventUploadSurvivors=False/PreventUploadSurvivors=True/g" $GUS
  sed -i "s/PreventUploadItems=False/PreventUploadItems=True/g" $GUS
  sed -i "s/PreventUploadDinos=False/PreventUploadDinos=True/g" $GUS
  sed -i "s/PreventDownloadItems=False/PreventDownloadItems=True/g" $GUS
  sed -i "s/PreventDownloadDinos=False/PreventDownloadDinos=True/g" $GUS
fi

## Overrides Non-Story maps
if grep -q "No Item / Dino Transfer" "$GSA_CONTROL"; then
  echo "Overriding Transfer Prevention"
  sed -i "s/PreventUploadItems=False/PreventUploadItems=True/g" $GUS
  sed -i "s/PreventUploadDinos=False/PreventUploadDinos=True/g" $GUS
  sed -i "s/PreventDownloadItems=False/PreventDownloadItems=True/g" $GUS
  sed -i "s/PreventDownloadDinos=False/PreventDownloadDinos=True/g" $GUS
fi
