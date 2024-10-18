#!/bin/bash

LOG_FILE="/var/log/app.log"
DATABASE="logdb"
TABLE="log_entries"

# Get the latest timestamp from the database and trim any whitespace
LAST_TIMESTAMP=$(psql -d $DATABASE -t -c "SELECT MAX(timestamp) FROM $TABLE;")
LAST_TIMESTAMP=$(echo $LAST_TIMESTAMP | xargs) # Remove leading/trailing whitespace

# If there is no timestamp in the database, set it to a default value
if [ -z "$LAST_TIMESTAMP" ]; then
    LAST_TIMESTAMP="1970-01-01 00:00:00"
fi

# Extract and process new logs
timeout 10s tail -n +1 -F $LOG_FILE | while read -r line; do
    TIMESTAMP=$(echo $line | awk '{print $1" "$2}')
    LEVEL=$(echo $line | awk '{print $3}' | sed 's/\[//;s/\]//')
    MESSAGE=$(echo $line | cut -d']' -f2- | sed 's/^[[:space:]]*//')

    # Escape single quotes in MESSAGE
    ESCAPED_MESSAGE=$(echo $MESSAGE | sed "s/'/''/g")

    if [[ "$TIMESTAMP" > "$LAST_TIMESTAMP" && ( "$LEVEL" == "ERROR" || "$LEVEL" == "FATAL" ) ]]; then
        psql -d $DATABASE -c "INSERT INTO $TABLE (timestamp, level, message) VALUES ('$TIMESTAMP', '$LEVEL', '$ESCAPED_MESSAGE');"
    fi
done

# Run the alert system
/home/mikey/revature/p1/path/to/venv/bin/python3 /home/mikey/revature/p1/alert_system.py
