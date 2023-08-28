#!/bin/bash
echo "Prow script initiated."
oc whoami

HTTP_RESPONSE=$(curl -L -I \
    -u operator-bundle-bot:$(/var/run/cred/operator_bundle_bot_github_token) \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/emojis)

HTTP_STATUS=$(echo ${HTTP_RESPONSE} | head --lines 1 | cut -d ' ' -f 2)

if [ ${HTTP_STATUS} = 200 ]; then
    echo "Operator bot available."
else
    echo ${HTTP_RESPONSE}
    >&2 echo "Operator bot NOT available!"
fi

echo "Prow complete."
