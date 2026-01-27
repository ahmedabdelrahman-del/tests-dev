#create s3 bucket for static website hosting
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = var.s3_bucket_name
  tags = {
    Name       = var.s3_bucket_name
    managed_by = "terraform"
  }
}
#block public access to the s3 bucket
resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
#set bucket policy to make it read only access 
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_website_bucket.arn}/*"
      }
    ]
  })
}
resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_website_bucket.id
  key    = "index.html"
  source = "${path.module}/index.html"
  content_type = "text/html"
}
resource "aws_s3_object" "error_html" {
  bucket = aws_s3_bucket.static_website_bucket.id
  key    = "error.html"
  source = "${path.module}/error.html"
  content_type = "text/html"
}
resource "aws_s3_object" "styles_css" {
  bucket = aws_s3_bucket.static_website_bucket.id
  key    = "style.css"
  source = "${path.module}/style.css"
  content_type = "text/css"
}
output "s3_bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  value       = aws_s3_bucket.static_website_bucket.bucket
}