#!/bin/bash
echo "Prow script initiated."
oc whoami

if [ -f /var/run/cred/operator_bundle_bot_github_token ]; then
  echo "Operator bot github token available."
else
  >&2 echo "Operator bot github token NOT available!"
  exit 1
fi

# HTTP_RESPONSE=$(curl -L -I \
#     -u operator-bundle-bot:$(/var/run/cred/operator_bundle_bot_github_token) \
#     -H "Accept: application/vnd.github+json" \
#     -H "X-GitHub-Api-Version: 2022-11-28" \
#     https://api.github.com/emojis)

echo "Prow complete."
