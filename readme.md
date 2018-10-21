# Backup to S3

## Potential for improvment

- check return codes of commands and retry/abort

## Motivation

Having a backup can be really expensive. And to be honest, who can be really sure to have it fireproof, geo-redundant and 99.99% accessible? I cannot do this, but a colleague of mine pointed me to AWS Glacier. With Glacier you have to pay 0.0045$ per GB atm in eu-central-1. So if you have e.g. 100 GB of data for backup, you have to pay like ```100 * 0.0045$ = 0.45$``` per month. Calculating for a backup solution for 50 years, results in ```50 * 12 * 0.45$ = 270$```. And that is - for a geo redundant and hardware failure free solution (after all, we calculated for 50 years) - very, very cheap.

## Precondition

- zip installed
- gpg installed
- aws-cli installed
- terraform installed

## Algorithm

### One time

In the terraform directory, perform the following steps:

    terraform init
    terraform plan (validate the plan, if it fits your needs)
    terraform apply

This will setup a user, some policies and setup an s3 bucket with the glacier policy.

### Backup and push

1. Start script with a name for the backup. That should make it easy for you to identify the backup later on.

    ```./backup.sh photos_2000```

    There are a lot environment variables that have to be set for all the stuff working:

    - ```AWS_ACCESS_KEY_ID```
    - ```AWS_SECRET_ACCESS_KEY```
    - ```AWS_DEFAULT_REGION```
    - ```BACKUP_PATH BACKUP_ZIP_PW```
    - ```BACKUP_GPG_NAME```
    - ```BACKUP_GPG_PW```
    - ```BACKUP_S3_BUCKET```

2. Delete macos files

    ```find . -name '.DS_Store' -type f -delete```

3. Everything under $HOME/Backup is zipped (including password) to a zip file with the given backup name, here it is e.g. photos_2000.

    ```zip -r -X -9 -e -m -P ${BACKUP_PW} photos_2000.zip photos_2000```

4. Encrypt the zip with a given gpg key-pair.

    ```gpg -e -r "Stefan Jacobs" photos_2000.zip```

5. Push encrypted file to s3.

    ```aws s3 cp $HOME/Backup/photos_2000.zip.gpg  s3://s3.tf.backup/```

6. Let amazon take care of the glacier thing with the s3 lifecycle hook.

### Restore Backup

1. Restore from glacier
2. Download files from aws s3, e.g. with browser or with

    ```aws s3 cp s3://s3.tf.backup/* $HOME/Backup```

3. decrypt gpg with private key

    ```gpg -d photos_2000.zip.gpg > photos_2000.zip```

4. Unzip zip file with password

    ```unzip photos_2000.zip```
