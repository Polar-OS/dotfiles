#!/bin/bash
export QML_IMPORT_PATH=$(pwd):$(pwd)/tests/mocks

# Regenerate wrappers to ensure fresh code
./tests/setup_wrappers.sh

FAILED=0

run_test() {
    TEST_FILE="$1"
    echo "------------------------------------------------"
    echo "Running $TEST_FILE..."
    
    OUTFILE=$(mktemp)
    quickshell -p "$TEST_FILE" > "$OUTFILE" 2>&1 &
    PID=$!

    LOG_FILE=""
    MAX_RETRIES=20
    count=0
    while [ -z "$LOG_FILE" ] && [ $count -lt $MAX_RETRIES ]; do
        sleep 0.5
        LOG_FILE=$(grep "Saving logs to" "$OUTFILE" | cut -d '"' -f 2)
        count=$((count+1))
    done

    if [ -z "$LOG_FILE" ]; then
        echo "Failed to find log file for $TEST_FILE."
        cat "$OUTFILE"
        kill $PID 2>/dev/null
        rm "$OUTFILE"
        return 1
    fi

    DETAILED_LOG=$(grep "Saving detailed logs to" "$OUTFILE" | cut -d '"' -f 2)
    if [ -z "$DETAILED_LOG" ]; then
        DETAILED_LOG="${LOG_FILE%.qslog}.log"
    fi

    wait $PID

    if grep -q "TEST_SUITE_FAILED" "$DETAILED_LOG"; then
        echo "TESTS FAILED: $TEST_FILE"
        cat "$DETAILED_LOG" # PRINT EVERYTHING
        rm "$OUTFILE"
        return 1
    elif grep -q "TEST_SUITE_PASSED" "$DETAILED_LOG"; then
        echo "TESTS PASSED: $TEST_FILE"
        grep "FINISHED:" "$DETAILED_LOG"
        rm "$OUTFILE"
        return 0
    else
        echo "NO TESTS FOUND OR CRASHED: $TEST_FILE"
        cat "$DETAILED_LOG"
        rm "$OUTFILE"
        return 1
    fi
}

TESTS=$(find tests -name "tst_*.qml" | sort)

for t in $TESTS; do
    run_test "$t"
    if [ $? -ne 0 ]; then
        FAILED=1
    fi
done

if [ $FAILED -ne 0 ]; then
    exit 1
else
    exit 0
fi
