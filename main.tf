data "aws_caller_identity" "self" {}

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
      type        = "*"
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
      type        = "*"
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
  bucket       = aws_s3_bucket.blue.id
  key          = "index.html"
  source       = "blue/index.html"
  content_type = "text/html"
  etag         = filemd5("blue/index.html")
}

resource "aws_s3_object" "blue_test" {
  bucket       = aws_s3_bucket.blue.id
  key          = "test/index.html"
  source       = "blue/test/index.html"
  content_type = "text/html"
  etag         = filemd5("blue/test/index.html")
}

resource "aws_s3_object" "blue_banner" {
  bucket       = aws_s3_bucket.blue.id
  key          = "image/banner.png"
  source       = "blue/image/banner.png"
  content_type = "image/png"
  etag         = filemd5("blue/image/banner.png")
}

resource "aws_s3_object" "green_index" {
  bucket       = aws_s3_bucket.green.id
  key          = "index.html"
  source       = "green/index.html"
  content_type = "text/html"
  etag         = filemd5("blue/index.html")
}

resource "aws_s3_object" "_green_index" {
  bucket       = aws_s3_bucket.green.id
  key          = "_green/index.html"
  source       = "green/index.html"
  content_type = "text/html"
  etag         = filemd5("blue/index.html")
}

resource "aws_s3_object" "green_test" {
  bucket       = aws_s3_bucket.green.id
  key          = "test/index.html"
  source       = "green/test/index.html"
  content_type = "text/html"
  etag         = filemd5("green/test/index.html")
}

resource "aws_s3_object" "_green_test" {
  bucket       = aws_s3_bucket.green.id
  key          = "_green/test/index.html"
  source       = "green/test/index.html"
  content_type = "text/html"
  etag         = filemd5("green/test/index.html")
}

resource "aws_s3_object" "green_banner" {
  bucket       = aws_s3_bucket.green.id
  key          = "image/banner.png"
  source       = "green/image/banner.png"
  content_type = "image/png"
  etag         = filemd5("green/image/banner.png")
}

resource "aws_s3_object" "_green_banner" {
  bucket       = aws_s3_bucket.green.id
  key          = "_green/image/banner.png"
  source       = "green/image/banner.png"
  content_type = "image/png"
  etag         = filemd5("green/image/banner.png")
}

# CloudFront Distribution

resource "aws_cloudfront_distribution" "blue_green" {
  origin {
    domain_name = aws_s3_bucket.blue.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.blue.id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  origin {
    domain_name = aws_s3_bucket.green.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.green.id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    prefix          = "log/cf/"
  }

  aliases = []

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.blue.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/_green/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.green.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }


  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "Blue/Green Canary"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
