#!/bin/sh -l

COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty=format:'%an')
COMMIT_AUTHOR_EMAIL=$(git log -1 --pretty=format:'%ae')
COMMIT_COMITTER=$(git log -1 --pretty=format:'%cn')
COMMIT_COMITTER_EMAIL=$(git log -1 --pretty=format:'%ce')
COMMIT_CREATED=$(git log -1 --format=%cI)

EVENT="push"
URL="https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/commit/$CIRCLE_SHA1"
if [[ -v CIRCLE_PULL_REQUEST ]];
then
    EVENT="pr"
    SOURCE_BRANCH=$CIRCLE_BRANCH
    TARGET_BRANCH=todo
    URL=$CIRCLE_PULL_REQUESTS
fi

if [[ -v CIRCLE_TAG ]];
then
    EVENT="tag"
fi

VARS=$(printenv | grep CIRCLE | awk '$0="--var "$0')

./gimlet artifact create \
--repository "$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME" \
--sha "$CIRCLE_SHA1" \
--created "$COMMIT_CREATED" \
--branch "$CIRCLE_BRANCH" \
--event "$EVENT" \
--sourceBranch "$SOURCE_BRANCH" \
--targetBranch "$TARGET_BRANCH" \
--tag "$CIRCLE_TAG" \
--authorName "$COMMIT_AUTHOR" \
--authorEmail "$COMMIT_AUTHOR_EMAIL" \
--committerName "$COMMIT_COMITTER" \
--committerEmail "$COMMIT_COMITTER_EMAIL" \
--message "$COMMIT_MESSAGE" \
--url "$URL" \
> artifact.json

./gimlet artifact add \
-f artifact.json \
--field "name=CI" \
--field "url=$CIRCLE_BUILD_URL"

./gimlet artifact add \
-f artifact.json \
--field "name=docker-image" \
--field "url=<< parameters.image-tag >>"

for file in .gimlet/*
do
    if [[ -f $file ]]; then
    ./gimlet artifact add -f artifact.json --envFile $file
    fi
done

./gimlet artifact add -f artifact.json $VARS
./gimlet artifact push -f artifact.json

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"
