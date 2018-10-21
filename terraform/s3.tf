
# This configures aws – required in all terraform files
provider "aws" {}

# Create a specific user that is responsible only for the backups
resource "aws_iam_user" "backup_user" {
  name = "backup_user"
}

# Create an access key
resource "aws_iam_access_key" "backup_user" {
  user = "${aws_iam_user.backup_user.name}"
}

# Create an iam user policy to access s3
resource "aws_iam_user_policy" "backup_user_policy" {
  name = "backup_user_policy"
  user = "${aws_iam_user.backup_user.name}"
  
  policy= <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::s3.tf.backup",
                "arn:aws:s3:::s3.tf.backup/*"
            ]
        }
   ]
}
EOF
}

# Create an kms key
resource "aws_kms_key" "s3_tf_backup_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10

  # tags for this ressource
  tags {
    Name        = "s3.tf Backup Key"
    Environment = "Production"
    CostReference = "Backup"
  }
}

# Create the backup s3 bucket with encryption and a lifecycle rule
resource "aws_s3_bucket" "s3_tf_backup" {

  bucket = "s3.tf.backup"
  acl    = "private"
  
  # tags for this ressource
  tags {
    Name        = "s3.tf Backup"
    Environment = "Production"
    CostReference = "Backup"
  }

  # enable server side encryption with kms
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.s3_tf_backup_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # create a lifecycle rule that all objects are moved to glacier after 1 day
  lifecycle_rule {

    enabled = true

    # immediatly after upload, transition files to glacier
    transition {
      days          = 0
      storage_class = "GLACIER"
    }

    # no expiration rule for a backup ;-)
  }

}
