#!/bin/bash
read -r GITHUB_TOKEN </var/run/cred/operator_bundle_bot_github_token
export GITHUB_TOKEN
start_time="$(date +%s)"
deadline="$((start_time+1800))"

fail() {
    echo "$@"
    gh pr edit "${pr_url}" \
        --remove-label "ocp/${OCP_CLUSTER_VERSION}/start" \
        --remove-label "ocp/${OCP_CLUSTER_VERSION}/running" \
        --add-label "ocp/${OCP_CLUSTER_VERSION}/fail" \
        >/dev/null
    echo "Test failed at $(date)"
    exit 1
}

skip() {
    echo "$@"
    echo "Test skipped at $(date)"
    exit 0
}

echo "Prow script initiated at $(date)."
echo "Deadline is $(date --date="@${deadline}")."
echo "Openshift account in use: $(oc whoami)"
oc version

pr_url=$(jq -r '.refs[0].pulls[0].link' <<<"${CLONEREFS_OPTIONS}")
pr_author=$(jq -r '.refs[0].pulls[0].author' <<<"${CLONEREFS_OPTIONS}")
pr_info=$(gh pr view "${pr_url}" \
    --json title,state -q '"[\(.state)] \(.title)"')

echo "Processing PR #${PULL_NUMBER} from ${pr_author}: ${pr_info}"

gh pr edit "${pr_url}" \
    --remove-label "ocp/${OCP_CLUSTER_VERSION}/pass" \
    --remove-label "ocp/${OCP_CLUSTER_VERSION}/fail" \
    --remove-label "ocp/${OCP_CLUSTER_VERSION}/running" \
    >/dev/null

echo "Waiting for ocp/${OCP_CLUSTER_VERSION}/start or /skip label..."
while [ "$(date +%s)" -lt "${deadline}" ] ; do
    labels=$(gh pr view "${pr_url}" --json labels -q '.labels[].name')
    echo "${labels}" | grep -Fq "ocp/${OCP_CLUSTER_VERSION}/skip" \
        && skip "Bundle does not support OCP ${OCP_CLUSTER_VERSION}"
    echo "${labels}" | grep -Fq "community-hosted-pipeline/failed" \
        && fail "Tekton pipeline failed"
    echo "${labels}" | grep -Fq "ocp/${OCP_CLUSTER_VERSION}/start" \
        && break
    sleep 30
done

[ "$(date +%s)" -ge "${deadline}" ] \
    && fail "Timed out waiting for ocp/${OCP_CLUSTER_VERSION}/start label"

gh pr edit "${pr_url}" \
    --remove-label "ocp/${OCP_CLUSTER_VERSION}/start" \
    --add-label "ocp/${OCP_CLUSTER_VERSION}/running" \
    >/dev/null

echo "Starting test at $(date)"

python3 operatorcert/entrypoints/start_community_prow.py

gh pr edit "${pr_url}" \
    --remove-label "ocp/${OCP_CLUSTER_VERSION}/running" \
    --add-label "ocp/${OCP_CLUSTER_VERSION}/pass" \
    >/dev/null

echo "Test completed successfully at $(date)"
