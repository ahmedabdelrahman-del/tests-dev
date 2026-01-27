locals {
    role_policies = {
        readonly  = ["ReadOnlyAccess"]
        admin     = ["AdministratorAccess"]
        audit     = ["SecurityAudit"]
        developer = ["AmazonVPCFullAccess", "AmazonS3FullAccess", "AmazonEC2FullAccess", "AmazonRDSFullAccess"]
    }

    role_policy_pairs = {
        for rp in flatten([
            for role, policies in local.role_policies : [for p in policies : { role = role, policy = p }]
        ]) : "${rp.role}-${rp.policy}" => rp
    }
}

# IAM groups per role
resource "aws_iam_group" "iam_groups" {
    for_each = local.role_policies
    name     = each.key
}

# Fetch AWS managed policies referenced above
data "aws_iam_policy" "named_policy" {
    for_each = toset(flatten(values(local.role_policies)))
    name     = each.key
}

# Attach all policies to each group
resource "aws_iam_group_policy_attachment" "group_policy" {
    for_each   = local.role_policy_pairs
    group      = aws_iam_group.iam_groups[each.value.role].name
    policy_arn = data.aws_iam_policy.named_policy[each.value.policy].arn
}
