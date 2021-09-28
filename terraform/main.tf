terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.4"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14.9"
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "site_bucket" {
  bucket = var.fqdn

  force_destroy = true

  tags = {
    Name        = var.fqdn
  }
}

resource "aws_s3_bucket_website_configuration" "site_bucket_config" {
  bucket = aws_s3_bucket.site_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = var.spa_routing ? "index.html" : "404.html"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.site_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "bucket_block" {
  bucket = aws_s3_bucket.site_bucket.id

  ignore_public_acls      = true
  block_public_policy     = true
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudflare" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudflare.json
}

data "aws_iam_policy_document" "allow_access_from_cloudflare" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]

    resources = [
      aws_s3_bucket.site_bucket.arn,
      "${aws_s3_bucket.site_bucket.arn}/*",
    ]

    condition{
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values = [
            "2400:cb00::/32",
            "2606:4700::/32",
            "2803:f800::/32",
            "2405:b500::/32",
            "2405:8100::/32",
            "2a06:98c0::/29",
            "2c0f:f248::/32",
            "173.245.48.0/20",
            "103.21.244.0/22",
            "103.22.200.0/22",
            "103.31.4.0/22",
            "141.101.64.0/18",
            "108.162.192.0/18",
            "190.93.240.0/20",
            "188.114.96.0/20",
            "197.234.240.0/22",
            "198.41.128.0/17",
            "162.158.0.0/15",
            "172.64.0.0/13",
            "131.0.72.0/22",
            "104.16.0.0/13",
            "104.24.0.0/14"
        ]
    }
  }
}

resource "cloudflare_page_rule" "flex_ssl" {
  zone_id = var.cloudflare_zone_id
  target  = "${cloudflare_record.site_cname.hostname}/*"
  priority = 1

  actions {
    ssl = "flexible"
    minify {
      html = "off"
      css  = "on"
      js   = "on"
    }
  }
}

resource "random_id" "script_name" {
  keepers = {
    cloudflare_subdomain = var.cloudflare_zone_id
  }

  byte_length = 8
}

resource "cloudflare_record" "site_cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.sub
  value   = "${var.fqdn}.s3-website.${data.aws_region.current.name}.amazonaws.com"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_worker_script" "main_script" {
  count = var.spa_routing ? 1 : 0
  content = "${file("${path.module}/spa_redirect.js")}"
  name = "spa_routing-${random_id.script_name.hex}"
}

resource "cloudflare_worker_route" "catch_all_route" {
  count = var.spa_routing ? 1 : 0
  zone_id = var.cloudflare_zone_id
  pattern = "${cloudflare_record.site_cname.hostname}/*"
  script_name = cloudflare_worker_script.main_script[count.index].name
}