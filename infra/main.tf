# Infrastructure de TaskFlow (AWS) — securisee.
# Ce code sert uniquement a l'analyse.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

variable "trusted_cidr" {
  description = "Plage IP autorisee a acceder a TaskFlow"
  type        = string
  default     = "10.0.0.0/24"
}

resource "aws_s3_bucket" "exports" {
  #checkov:skip=CKV2_AWS_62: Aucun consommateur evenementiel dans le TP. Echeance 2026-12-01.
  #checkov:skip=CKV_AWS_18: Infrastructure de demonstration non deployee. Journalisation a configurer avant deploiement. Echeance 2026-12-01.
  #checkov:skip=CKV_AWS_144: Replication interregion non requise pour cette demonstration. Echeance 2026-12-01.

  bucket = "taskflow-exports-demo"
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket = aws_s3_bucket.exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_security_group" "web" {
  name        = "taskflow-web"
  description = "Acces a l'API TaskFlow"

  ingress {
    description = "SSH depuis le reseau autorise"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_cidr]
  }

  ingress {
    description = "API depuis le reseau autorise"
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = [var.trusted_cidr]
  }

  egress {
    description = "Trafic HTTPS sortant"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "api" {
  #checkov:skip=CKV2_AWS_41: Aucun appel AWS requis par cette instance de demonstration. Echeance 2026-12-01.

  ami                         = "ami-0123456789abcdef0"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = false
  monitoring                  = true
  ebs_optimized               = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "taskflow-api"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "performance_insights" {
  description             = "Chiffrement Performance Insights TaskFlow"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_db_instance" "tasks" {
  #checkov:skip=CKV_AWS_118: Monitoring avance non configure pour cette infrastructure non deployee. Echeance 2026-12-01.
  #checkov:skip=CKV_AWS_157: Haute disponibilite Multi-AZ non requise pour le TP. Echeance 2026-12-01.
  #checkov:skip=CKV2_AWS_30: Journalisation SQL detaillee a configurer selon la version PostgreSQL retenue avant deploiement. Echeance 2026-12-01.

  identifier                  = "taskflow-db"
  engine                      = "postgres"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  username                    = "taskflow"
  manage_master_user_password = true
  publicly_accessible         = false
  storage_encrypted           = true
  auto_minor_version_upgrade  = true
  deletion_protection         = true
  copy_tags_to_snapshot       = true
  backup_retention_period     = 7
  skip_final_snapshot         = false
  final_snapshot_identifier   = "taskflow-db-final"

  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id      = aws_kms_key.performance_insights.arn

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}