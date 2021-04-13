#!/usr/bin/env bash

set -e

COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty=format:'%an')
COMMIT_AUTHOR_EMAIL=$(git log -1 --pretty=format:'%ae')
COMMIT_COMITTER=$(git log -1 --pretty=format:'%cn')
COMMIT_COMITTER_EMAIL=$(git log -1 --pretty=format:'%ce')
COMMIT_CREATED=$(git log -1 --format=%cI)

BRANCH=${GITHUB_REF##*/}

EVENT="push"
URL="https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
if [[ -n "$GITHUB_BASE_REF" ]];
then
    EVENT="pr"
    SOURCE_BRANCH=$GITHUB_BASE_REF
    TARGET_BRANCH=$GITHUB_TARGET_REF
    URL="TBD"
fi

if [[ $GITHUB_REF == refs/tags/* ]]   # True if $GITHUB_REF starts with a "refs/tags/" (wildcard matching).
then
    TAG=${GITHUB_REF##*/}
    EVENT="tag"
fi

gimlet artifact create \
--repository "$GITHUB_REPOSITORY" \
--sha "$GITHUB_SHA" \
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

gimlet artifact add \
-f artifact.json \
--field "name=CI" \
--field "url=$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

fields=$(echo $1 | tr ";" "\n")
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

for file in .gimlet/*
do
    if [[ -f $file ]]; then
    gimlet artifact add -f artifact.json --envFile $file
    fi
done

VARS=$(printenv | grep GITHUB | grep -v '=$' | awk '$0="--var "$0')
gimlet artifact add -f artifact.json $VARS

if [ $2 = "true" ]; then
    cat artifact.json
    exit 0
fi

ARTIFACT_ID=$(gimlet artifact push -f artifact.json)
if [ $? -ne 0 ]; then
    echo $ARTIFACT_ID
    exit 1
fi

echo "::set-output name=artifact-id::$ARTIFACT_ID"
