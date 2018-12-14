provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "exae" {
  ami           = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}
#testing

resource "aws_s3_bucket" "example" {

  bucket = "terraform-getting-started-guide"
  acl    = "${var.acl1}"
}

resource "aws_s3_bucket" "example2" {

  bucket = "mah-bucket"
  acl    = "${var.acl2}"
}


resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = "${var.enable_deletion_protection}"

  access_logs {
    bucket  = "${aws_s3_bucket.lb_logs.bucket}"
    prefix  = "test-lb"
    enabled = true
  }

  tags {
    Environment = "production"
  }
}

#testing



resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = "${var.minimum_password_length}"
  require_lowercase_characters   = "${var.require_lowercase_characters}"
  require_numbers                = "${var.require_numbers}"
  require_uppercase_characters   = "${var.require_uppercase_characters}"
  require_symbols                = "${var.require_symbols}"
  allow_users_to_change_password = "${var.allow_users_to_change_password}"
  max_password_age = "${var.max_password_age}"
  password_reuse_prevention = "${var.password_reuse_prevention}"
}




resource "aws_cloudtrail" "example" {

  is_multi_region_trail = "${var.is_multi_region_trail}"

  cloud_watch_logs_group_arn    = "${var.cloud_watch_logs_group_arn}"
  event_selector {
    read_write_type = "${var.read_write_type}"
    include_management_events = "${var.include_management_events}"

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}


#Ensure a log metric filter and alarm exist for Management Console sign-in without MFA
resource "aws_cloudwatch_log_metric_filter" "MFAUsed" {
  name           = "${var.name}"
  pattern        = "${var.pattern}"
  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name1      = "${var.name1}"
    namespace = "${var.namespace}"
    value     = "${var.value}"
  }
}



#Ensure SNS topics do not allow global send or subscribe

resource "aws_sns_topic_policy" "sns_policy" {
  arn = "${var.arn_name}"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "someTopic"
      },
      "Action": [
        "SNS:Publish",
        "SNS:RemovePermission",
        "SNS:SetTopicAttributes",
        "SNS:DeleteTopic",
        "SNS:ListSubscriptionsByTopic",
        "SNS:GetTopicAttributes",
        "SNS:Receive",
        "SNS:AddPermission",
        "SNS:Subscribe"
      ],
      "Resource": "arn:aws:sns:us-west-2:054106316361:someTopic",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "054106316361"
        }
      }
    },
    {
      "Sid": "__console_pub_0",
      "Effect": "Allow",
      "Principal": {
        "AWS": "someTopic"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:us-west-2:054106316361:someTopic"
    },
    {
      "Sid": "__console_sub_0",
      "Effect": "Allow",
      "Principal": {
        "AWS": "someTopic"
      },
      "Action": [
        "SNS:Subscribe",
        "SNS:Receive"
      ],
      "Resource": "arn:aws:sns:us-west-2:054106316361:someTopic"
    }
  ]
}
EOF
}