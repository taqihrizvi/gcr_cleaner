#!/bin/bash

ENV=$1

# Check required argument
if [[ $# -ne 1 ]]; then
  echo "Error: 1 arg are required: /gcr-cleaner ENV GCR_URL" >&2
  exit 2
fi

LIST_GCR_URL=(asia.gcr.io gcr.io us.gcr.io)
PROJECT_ID=""
IMAGES_TO_KEEP="20"


if [ $ENV == "production" ]
then
  PROJECT_ID="gotoko-infra-prod"
else
  PROJECT_ID="peak-nimbus-307910"
fi

for GCR_URL in ${LIST_GCR_URL[@]}
do


IMAGE_REPO="$GCR_URL/$PROJECT_ID"

RED='\033[0;31m'
YELL='\033[1;33m'
NC='\033[0m' # No Color

# Get all images at the given image repo
echo -e "${YELL}Getting all images${NC}"
IMAGELIST=$(gcloud container images list --repository=${IMAGE_REPO} --format='get(name)')
echo "$IMAGELIST"

while IFS= read -r IMAGENAME; do
  IMAGENAME=$(echo $IMAGENAME|tr -d '\r')
  echo -e "${YELL}Checking ${IMAGENAME} for cleanup requirements${NC}"

  # Get all the digests for the tag ordered by timestamp (oldest first)
  DIGESTLIST=$(gcloud container images list-tags ${IMAGENAME} --sort-by timestamp --format='get(digest)')
  DIGESTLISTCOUNT=$(echo "${DIGESTLIST}" | wc -l)

  if [ ${IMAGES_TO_KEEP} -ge "${DIGESTLISTCOUNT}" ]; then
    echo -e "${YELL}Found ${DIGESTLISTCOUNT} digests, nothing to delete${NC}"
    continue
  fi

  # Filter the ordered list
  DIGESTLISTTOREMOVE=$(echo "${DIGESTLIST}" | head -n -${IMAGES_TO_KEEP})
  DIGESTLISTTOREMOVECOUNT=$(echo "${DIGESTLISTTOREMOVE}" | wc -l)

  echo -e "${YELL}Found ${DIGESTLISTCOUNT} digests, ${DIGESTLISTTOREMOVECOUNT} to delete${NC}"

  # Do deletion or say nothing to do
  if [ "${DIGESTLISTTOREMOVECOUNT}" -gt "0" ]; then
    echo -e "${YELL}Removing ${DIGESTLISTTOREMOVECOUNT} digests${NC}"
    while IFS= read -r LINE; do
      LINE=$(echo $LINE|tr -d '\r')
        gcloud container images delete ${IMAGENAME}@${LINE} --force-delete-tags --quiet
    done <<< "${DIGESTLISTTOREMOVE}"
  else
    echo -e "${YELL}No digests to remove${NC}"
  fi
done <<< "${IMAGELIST}"

# for loop LIST_GCR_URL
done
