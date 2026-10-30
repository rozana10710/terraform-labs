# Copy this file into the main lab folder for Step 7.
# It creates 3 buckets with COUNT, tracked by POSITION: [0], [1], [2]

locals {
  demo_colors = ["red", "green", "blue"]
}

resource "aws_s3_bucket" "count_demo" {
  count = length(local.demo_colors)

  bucket = "${local.name_prefix}-demo-${local.demo_colors[count.index]}"
  tags   = local.common_tags
}
