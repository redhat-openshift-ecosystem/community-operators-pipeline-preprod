#!/bin/bash

VALIDATION_PASSED_LABEL="validation/passed"
VALIDATION_FAILED_LABEL="validation/failed"

timeout=600  # Timeout in seconds (10 minutes)

echo "Waiting for GitHub labels on repository '$GITHUB_REPO' and Pull Request #$PR_NUMBER..."

start_time=$(date +%s)

while :; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [[ $elapsed_time -ge $timeout ]]; then
        echo "Timeout reached. Labels not found, check static tests logs."
        exit 1
    fi

    API_RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/pulls/$PR_NUMBER/labels")

    if echo "$API_RESPONSE" | grep -q "\"name\":\"$VALIDATION_PASSED_LABEL\""; then
        echo "Label '$VALIDATION_PASSED_LABEL' found! Running dynamic tests."
        python3 main.py  # dummy script for now
        break
    elif echo "$API_RESPONSE" | grep -q "\"name\":\"$VALIDATION_FAILED_LABEL\""; then
        echo "Static tests failed, dynamic tests will not be executed. Exiting."
        exit 1
    fi

    echo "Waiting for static tests labels..."
    sleep 5

done

echo "Prow complete."