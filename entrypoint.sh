#!/usr/bin/env bash

set -e

git version
git config --global --add safe.directory /github/workspace

echo "Creating artifact.."

COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty=format:'%an')
COMMIT_AUTHOR_EMAIL=$(git log -1 --pretty=format:'%ae')
COMMIT_COMITTER=$(git log -1 --pretty=format:'%cn')
COMMIT_COMITTER_EMAIL=$(git log -1 --pretty=format:'%ce')
COMMIT_CREATED=$(git log -1 --format=%cI)

BRANCH=${GITHUB_HEAD_REF} # For PRs this var has the branch, see https://docs.github.com/en/actions/reference/environment-variables
if [ -z "$BRANCH" ]; then BRANCH=${GITHUB_REF##refs/heads/}; fi
export GITHUB_BRANCH=$BRANCH
# TODO check if head sha is better suited for the workflows: https://github.community/t/github-sha-isnt-the-value-expected/17903/2

EVENT="push"
SHA=$GITHUB_SHA
URL="https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
if [[ -n "$GITHUB_BASE_REF" ]];
then
    EVENT="pr"
    SHA=$INPUT_BRANCHHEAD
    SOURCE_BRANCH=$GITHUB_BASE_REF
    TARGET_BRANCH=$GITHUB_TARGET_REF
    PR_NUMBER=$(echo "$GITHUB_REF" | awk -F / '{print $3}')
    URL="https://github.com/$GITHUB_REPOSITORY/pull/$PR_NUMBER"
fi

if [[ $GITHUB_REF == refs/tags/* ]]   # True if $GITHUB_REF starts with a "refs/tags/" (wildcard matching).
then
    TAG=${GITHUB_REF##refs/tags/}
    EVENT="tag"
fi

gimlet artifact create \
--repository "$GITHUB_REPOSITORY" \
--sha "$SHA" \
--created "$COMMIT_CREATED" \
--branch "$BRANCH" \
--event "$EVENT" \
--sourceBranch "$SOURCE_BRANCH" \
--targetBranch "$TARGET_BRANCH" \
--tag "$TAG" \
--authorName "$COMMIT_AUTHOR" \
--authorEmail "$COMMIT_AUTHOR_EMAIL" \
--committerName "$COMMIT_COMITTER" \
--committerEmail "$COMMIT_COMITTER_EMAIL" \
--message "$COMMIT_MESSAGE" \
--url "$URL" \
> artifact.json

echo "Attaching CI run URL.."
gimlet artifact add \
-f artifact.json \
--field "name=CI" \
--field "url=$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

echo "Attaching custom fields.."
fields=$(echo $INPUT_FIELDS | tr ";" "\n")
for field in $fields
do
    # Set the delimiter
    OLDIFS=$IFS
    IFS='='
    #Read the split words into an array based on delimiter
    read -a key_value <<< "$field"
    IFS=$OLDIFS

    gimlet artifact add \
      -f artifact.json \
      --field "name=${key_value[0]}" \
      --field "url=${key_value[1]}"
done

echo "Attaching Gimlet manifests.."
for file in .gimlet/*
do
    if [[ -f $file ]]; then
    gimlet artifact add -f artifact.json --envFile $file
    fi
done

echo "Attaching environment variable context.."
VARS=$(printenv | grep GITHUB | grep -v '=$' | awk '$0="--var "$0')
gimlet artifact add -f artifact.json $VARS

echo "Attaching common Gimlet variables.."
gimlet artifact add \
-f artifact.json \
--var "REPO=$GITHUB_REPOSITORY" \
--var "OWNER=$GITHUB_REPOSITORY_OWNER" \
--var "BRANCH=$BRANCH" \
--var "TAG=$TAG" \
--var "SHA=$GITHUB_SHA" \
--var "ACTOR=$GITHUB_ACTOR" \
--var "EVENT=$GITHUB_EVENT_NAME" \
--var "JOB=$GITHUB_JOB"

if [[ "$INPUT_DEBUG" == "true" ]]; then
    cat artifact.json
    exit 0
fi

echo "Shipping artifact.."
ARTIFACT_ID=$(gimlet artifact push -f artifact.json --output json | jq -r '.id' )
if [ $? -ne 0 ]; then
    echo $ARTIFACT_ID
    exit 1
fi

echo "Shipped artifact ID is: $ARTIFACT_ID"

echo "::set-output name=artifact-id::$ARTIFACT_ID"

while true; do
    artifact_json=$(gimlet release track --output json $ARTIFACT_ID)
    artifact_status=$(echo $artifact_json | jq -r '.status')

    artifact_gitops_hashes_count=$(echo $artifact_json | jq -r '.gitopsHashes' | jq -c '.[]' | wc -l)
    artifact_gitops_hash_failed_count=$(echo $artifact_json | jq -r '.gitopsHashes' | jq -c '.[].status' | grep "Failed" | wc -l)
    artifact_gitops_hashes_succeeded_count=$(echo $artifact_json | jq -r '.gitopsHashes' | jq -c '.[].status' | grep "Succeeded" | wc -l)

    artifact_results_count=$(echo $artifact_json | jq -r '.results' | jq -c '.[]' | wc -l)
    artifact_result_failed_count=$(echo $artifact_json | jq -r '.results' | jq -c '.[].gitopsCommitStatus' | grep "Failed" | wc -l)
    artifact_result_succeeded_count=$(echo $artifact_json | jq -r '.results' | jq -c '.[].gitopsCommitStatus' | grep "Succeeded" | wc -l)

    echo $artifact_json

    if [[ "$artifact_status" == "error" ||
    "$artifact_gitops_hash_failed_count" -gt 0 ||
    "$artifact_gitops_hashes_count" -eq "$artifact_gitops_hashes_succeeded_count" ||
    "$artifact_result_failed_count" -gt 0 ||
    "$artifact_results_count" -eq "$artifact_result_succeeded_count" ]] && [[ "$artifact_status" != "new" ]];then
        break
    else
        gimlet release track $ARTIFACT_ID
    fi

    sleep 5
done

gimlet release track $ARTIFACT_ID
