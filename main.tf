data "aws_caller_identity" "self" { }

# create S3 Bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "aws-study-minatomirai-log-bucket"
}

resource "aws_s3_bucket_acl" "log_bucket" {
    bucket = aws_s3_bucket.log_bucket.id
    acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "blue" {
    bucket = "aws-study-minatomirai-blue"

    tags = {
        Name = "Blue bucket for aws_study_minatomirai/blue_green_canary"
    }
}

resource "aws_s3_bucket_logging" "blue" {
    bucket = aws_s3_bucket.blue.id

    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/blue/"
}

resource "aws_s3_bucket_acl" "blue" {
    bucket = aws_s3_bucket.blue.id
    acl    = "public-read"
}

resource "aws_s3_bucket_policy" "blue" {
    bucket = aws_s3_bucket.blue.id
    policy = data.aws_iam_policy_document.blue.json
}

data "aws_iam_policy_document" "blue" {
  statement {
    principals {
        type = "*"
        identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.blue.arn}",
      "${aws_s3_bucket.blue.arn}/*"
    ]
  }
}

resource "aws_s3_bucket" "green" {
    bucket = "aws-study-minatomirai-green"

    tags = {
        Name = "Green bucket for aws_study_minatomirai/blue_green_canary"
    }
}

resource "aws_s3_bucket_logging" "green" {
    bucket = aws_s3_bucket.green.id

    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/green/"
}

resource "aws_s3_bucket_acl" "green" {
    bucket = aws_s3_bucket.green.id
    acl    = "public-read"
}

resource "aws_s3_bucket_policy" "green" {
    bucket = aws_s3_bucket.green.id
    policy = data.aws_iam_policy_document.green.json
}

data "aws_iam_policy_document" "green" {
  statement {
    principals {
        type = "*"
        identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.green.arn}",
      "${aws_s3_bucket.green.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_website_configuration" "blue" {
  bucket = aws_s3_bucket.blue.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_website_configuration" "green" {
  bucket = aws_s3_bucket.green.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "blue_index" {
  bucket = aws_s3_bucket.blue.id
  key    = "index.html"
  source = "blue/index.html"
  content_type = "text/html"
  etag = filemd5("blue/index.html")
}

resource "aws_s3_object" "blue_test" {
  bucket = aws_s3_bucket.blue.id
  key    = "test/index.html"
  source = "blue/test/index.html"
  content_type = "text/html"
  etag = filemd5("blue/test/index.html")
}

resource "aws_s3_object" "blue_banner" {
  bucket = aws_s3_bucket.blue.id
  key    = "image/banner.png"
  source = "blue/image/banner.png"
  content_type = "image/png"
  etag = filemd5("blue/image/banner.png")
}

resource "aws_s3_object" "green_index" {
  bucket = aws_s3_bucket.green.id
  key    = "index.html"
  source = "green/index.html"
  content_type = "text/html"
  etag = filemd5("blue/index.html")
}

resource "aws_s3_object" "green_test" {
  bucket = aws_s3_bucket.green.id
  key    = "test/index.html"
  source = "green/test/index.html"
  content_type = "text/html"
  etag = filemd5("green/test/index.html")
}

resource "aws_s3_object" "green_banner" {
  bucket = aws_s3_bucket.green.id
  key    = "image/banner.png"
  source = "green/image/banner.png"
  content_type = "image/png"
  etag = filemd5("green/image/banner.png")
}
