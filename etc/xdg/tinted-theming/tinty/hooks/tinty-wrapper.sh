#!/usr/bin/env bash
LOG_FILE="/var/home/frieser/.local/bin/tinty-wrapper.log"
echo "--- Wrapper Start: $(date) ---" >> "$LOG_FILE"
echo "Args: $@" >> "$LOG_FILE"
echo "Environment:" >> "$LOG_FILE"
env >> "$LOG_FILE"

# Run tinty and capture output
echo "Running tinty..." >> "$LOG_FILE"
/var/home/frieser/.cargo/bin/tinty "$@" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

echo "Tinty exit code: $EXIT_CODE" >> "$LOG_FILE"
echo "--- Wrapper End ---" >> "$LOG_FILE"
exit $EXIT_CODE
