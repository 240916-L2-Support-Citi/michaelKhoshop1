#!/usr/bin/env python3
import psycopg2
import datetime
import os

# Database connection parameters
db_params = {
    'dbname': 'logdb',
}

# Error thresholds
error_threshold = 5
fatal_threshold = 1

# Use the absolute path for the log file
log_file_path = '/home/mikey/revature/p1/alert_system.log'

def log_message(message):
    with open(log_file_path, 'w') as log_file:  # 'w' mode overwrites the file
        log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")

def check_logs():
    try:
        # Connect to the database
        conn = psycopg2.connect(**db_params)
        cursor = conn.cursor()

        # Check for errors and fatal logs
        cursor.execute("SELECT COUNT(*) FROM log_entries WHERE level = 'ERROR'")
        error_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM log_entries WHERE level = 'FATAL'")
        fatal_count = cursor.fetchone()[0]

        # Log alerts if thresholds are exceeded
        status_message = f"{error_count} ERRORS, {fatal_count} FATALS in the database."
        if error_count >= error_threshold:
            status_message = f"ALERT: {status_message}"
        if fatal_count >= fatal_threshold:
            status_message = f" {status_message}"
        log_message(status_message)

        cursor.close()
        conn.close()

    except Exception as e:
        log_message(f"An error occurred: {e}")

if __name__ == "__main__":
    check_logs()

