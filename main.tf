# Create the S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = "elias-clawson-portfolio-2026" # Must be globally unique
}

# Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Block public access (we'll use CloudFront to get in later)
resource "aws_s3_account_public_access_block" "block_public" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create Origin Access Control (for HTTPS)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "website-oac"
  description                       = "OAC for S3 portfolio"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create the CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  aliases = ["eliasclawson.com"]
  
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:542672133182:certificate/63ae8670-9adc-440d-a7b0-1c285fda8243"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Security policy
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

output "website_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

# Create the DynamoDB Table
resource "aws_dynamodb_table" "projects_table" {
  name           = "PortfolioProjects"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ProjectId"

  attribute {
    name = "ProjectId"
    type = "S"
  }
}

# Archive the Python code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

# Create the Lambda Function
resource "aws_lambda_function" "get_projects_api" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "GetPortfolioProjects"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "get_projects.lambda_handler"
  runtime       = "python3.12"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "portfolio_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policy to allow Lambda to read DynamoDB
resource "aws_iam_role_policy" "dynamo_lambda_policy" {
  name = "portfolio_lambda_dynamo_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:Scan", "dynamodb:GetItem"],
        Effect   = "Allow",
        Resource = [aws_dynamodb_table.projects_table.arn]
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function_url" "projects_url" {
  function_name      = aws_lambda_function.get_projects_api.function_name
  authorization_type = "NONE"

}

output "api_url" {
  value = aws_lambda_function_url.projects_url.function_url
}

resource "aws_lambda_permission" "allow_public_url" {
  statement_id           = "FunctionUrlAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.get_projects_api.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "allow_invoke_standard" {
  statement_id           = "AllowInvokeStandard"
  action                 = "lambda:InvokeFunction"
  function_name          = aws_lambda_function.get_projects_api.function_name
  principal              = "*"
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}