#!/bin/bash
echo "Prow script initiated."
oc whoami
read GITHUB_TOKEN </var/run/cred/operator_bundle_bot_github_token
export GITHUB_TOKEN
PR_URL=$(echo "${CLONEREFS_OPTIONS}" | jq -r '.refs[0].pulls[0].link')
gh pr view "${PR_URL}" --json title,state -q '"[\(.state)] \(.title)"'
echo "Prow complete."
