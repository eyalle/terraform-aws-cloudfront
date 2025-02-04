resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  count               = var.create_cf ? 1 : 0
  aliases             = var.alias
  comment             = var.comment
  default_root_object = var.default_root_object
  enabled             = var.enable
  http_version        = var.http_version
  is_ipv6_enabled     = var.enable_ipv6
  price_class         = var.price
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment
  web_acl_id          = var.webacl

  dynamic "origin" {
    for_each = [for i in var.dynamic_s3_origin_config : {
      name          = i.domain_name
      id            = i.origin_id
      identity      = lookup(i, "origin_access_identity", null)
      path          = lookup(i, "origin_path", "")
      custom_header = lookup(i, "custom_header", null)
    }]

    content {
      domain_name = origin.value.name
      origin_id   = origin.value.id
      origin_path = origin.value.path
      dynamic "custom_header" {
        for_each = origin.value.custom_header == null ? [] : [for i in origin.value.custom_header : {
          name  = i.name
          value = i.value
        }]
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
      dynamic "s3_origin_config" {
        for_each = origin.value.identity == null ? [] : [origin.value.identity]
        content {
          origin_access_identity = s3_origin_config.value
        }
      }
    }
  }

  dynamic "origin" {
    for_each = [for i in var.dynamic_custom_origin_config : {
      name                     = i.domain_name
      id                       = i.origin_id
      path                     = lookup(i, "origin_path", "")
      http_port                = i.http_port
      https_port               = i.https_port
      origin_keepalive_timeout = i.origin_keepalive_timeout
      origin_read_timeout      = i.origin_read_timeout
      origin_protocol_policy   = i.origin_protocol_policy
      origin_ssl_protocols     = i.origin_ssl_protocols
      custom_header            = lookup(i, "custom_header", null)
    }]
    content {
      domain_name = origin.value.name
      origin_id   = origin.value.id
      origin_path = origin.value.path
      dynamic "custom_header" {
        for_each = origin.value.custom_header == null ? [] : [for i in origin.value.custom_header : {
          name  = i.name
          value = i.value
        }]
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
      custom_origin_config {
        http_port                = origin.value.http_port
        https_port               = origin.value.https_port
        origin_keepalive_timeout = origin.value.origin_keepalive_timeout
        origin_read_timeout      = origin.value.origin_read_timeout
        origin_protocol_policy   = origin.value.origin_protocol_policy
        origin_ssl_protocols     = origin.value.origin_ssl_protocols
      }
    }
  }

  dynamic "origin_group" {
    for_each = [for i in var.dynamic_origin_group : {
      id           = i.origin_id
      status_codes = i.status_codes
      member       = lookup(i, "member", null)
    }]
    content {
      origin_id = origin_group.value.id
      failover_criteria {
        status_codes = origin_group.value.status_codes
      }
      dynamic "member" {
        for_each = origin_group.value.member == null ? [] : [for i in origin_group.value.member : {
          id = i.origin_id
        }]
        content {
          origin_id = member.value.id
        }
      }
    }
  }

  dynamic "default_cache_behavior" {
    for_each = var.dynamic_default_cache_behavior[*]
    iterator = j

    content {
      allowed_methods        = j.value.allowed_methods
      cached_methods         = j.value.cached_methods
      target_origin_id       = j.value.target_origin_id
      compress               = lookup(j.value, "compress", null)
      viewer_protocol_policy = j.value.viewer_protocol_policy

      cache_policy_id          = lookup(j.value, "cache_policy_id", null)
      origin_request_policy_id = lookup(j.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(j.value, "response_headers_policy_id", null)

      min_ttl     = lookup(j.value, "min_ttl", null)
      default_ttl = lookup(j.value, "default_ttl", null)
      max_ttl     = lookup(j.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(j.value, "use_forwarded_values", true) ? [true] : []
        content {
          query_string = lookup(j.value, "query_string", null)
          headers      = lookup(j.value, "headers", null)

          cookies {
            forward = lookup(j.value, "cookies_forward", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        iterator = lambda
        for_each = lookup(j.value, "lambda_function_association", [])
        content {
          event_type   = lambda.value.event_type
          lambda_arn   = lambda.value.lambda_arn
          include_body = lookup(lambda.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        iterator = cffunction
        for_each = lookup(j.value, "function_association", [])
        content {
          event_type   = cffunction.value.event_type
          function_arn   = cffunction.value.function_arn
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.dynamic_ordered_cache_behavior
    iterator = j
    content {
      path_pattern           = j.value.path_pattern
      allowed_methods        = j.value.allowed_methods
      cached_methods         = j.value.cached_methods
      target_origin_id       = j.value.target_origin_id
      compress               = lookup(j.value, "compress", null)
      viewer_protocol_policy = j.value.viewer_protocol_policy

      cache_policy_id          = lookup(j.value, "cache_policy_id", null)
      origin_request_policy_id = lookup(j.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(j.value, "response_headers_policy_id", null)

      min_ttl     = lookup(j.value, "min_ttl", null)
      default_ttl = lookup(j.value, "default_ttl", null)
      max_ttl     = lookup(j.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(j.value, "use_forwarded_values", true) ? [true] : []
        content {
          query_string = lookup(j.value, "query_string", null)
          headers      = lookup(j.value, "headers", null)

          cookies {
            forward = lookup(j.value, "cookies_forward", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        iterator = lambda
        for_each = lookup(j.value, "lambda_function_association", [])
        content {
          event_type   = lambda.value.event_type
          lambda_arn   = lambda.value.lambda_arn
          include_body = lookup(lambda.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        iterator = cffunction
        for_each = lookup(j.value, "function_association", [])
        content {
          event_type   = cffunction.value.event_type
          function_arn   = cffunction.value.function_arn
        }
      }

    }
  }

  dynamic "custom_error_response" {
    for_each = var.dynamic_custom_error_response

    content {
      error_code            = custom_error_response.value.error_code
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
    }
  }

  dynamic "logging_config" {
    for_each = var.dynamic_logging_config[*]

    content {
      bucket          = logging_config.value.bucket
      include_cookies = lookup(logging_config.value, "include_cookies", null)
      prefix          = lookup(logging_config.value, "prefix", null)
    }
  }

  tags = merge(
    var.additional_tags,
  { Name = var.tag_name })

  restrictions {
    geo_restriction {
      locations        = var.restriction_location
      restriction_type = var.restriction_type
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    iam_certificate_id             = var.iam_certificate_id
    cloudfront_default_certificate = var.acm_certificate_arn == null && var.iam_certificate_id == null ? true : false
    ssl_support_method             = var.acm_certificate_arn == null && var.iam_certificate_id == null ? null : "sni-only"
    minimum_protocol_version       = var.acm_certificate_arn == null && var.iam_certificate_id == null ? "TLSv1" : var.minimum_protocol_version
  }
}
