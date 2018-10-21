#!/bin/bash

declare -a vars=(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION BACKUP_PATH BACKUP_ZIP_PW BACKUP_GPG_NAME BACKUP_GPG_PW BACKUP_S3_BUCKET)

for var_name in "${vars[@]}"
do
  if [ -z "$(eval "echo \$$var_name")" ]; then
    echo "Missing environment variable $var_name"
    exit 1
  fi
done

declare -a files=('.DS_Store')

echo "Cleaning ${BACKUP_PATH}"
for var_name in "${files[@]}"
do
  find . -name '$var_name' -type f -delete
done
echo "Cleaning done"


ZIP_FILE="${BACKUP_PATH}/$1.zip"

echo "Creating zip file ${ZIP_FILE}"
zip -r -X -9 -e -m -P ${BACKUP_ZIP_PW} ${ZIP_FILE} ${BACKUP_PATH}/*
echo "Creating zip file ${ZIP_FILE} done!"

GPG_FILE="${ZIP_FILE}.gpg"

echo "PGP encryption of ${ZIP_FILE}"
gpg -e -r "${BACKUP_GPG_NAME}" --passphrase "${BACKUP_GPG_PW}" "${ZIP_FILE}"
echo "PGP encryption done, ${GPG_FILE} created!"

echo "Pushing ${GPG_FILE} to AWS S3 ${BACKUP_S3_BUCKET}"
aws configure set default.s3.max_bandwidth 100KB/s
aws configure set default.s3.payload_signing_enabled true
aws s3 mv "${GPG_FILE}" s3://"${BACKUP_S3_BUCKET}"/
echo "Pushing ${GPG_FILE} to AWS S3 ${BACKUP_S3_BUCKET} done."

echo "Your backup is now stored at s3://${BACKUP_S3_BUCKET}/${$1}.zip.gpg"

echo "Cleaning backup dir ${BACKUP_PATH}"
rm -rf ${BACKUP_PATH}/*
echo "Cleaning backup dir ${BACKUP_PATH} done."