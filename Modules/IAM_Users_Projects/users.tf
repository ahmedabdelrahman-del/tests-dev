locals{
    user_from_yaml = yamldecode(file("${path.module}/user-role.yaml"))
    users_map      = {for u in local.user_from_yaml.users : u.username => u}
}
resource "aws_iam_user" "users"{
    for_each = local.users_map
    name     = each.value.username
}
resource "aws_iam_user_login_profile" "user_login"{
    for_each = aws_iam_user.users
    user     = each.value.name
    password_length = 8
    password_reset_required = true
    lifecycle {
        ignore_changes = [password_length, password_reset_required]
    }
}

# Add users to groups based on roles listed in YAML
resource "aws_iam_user_group_membership" "user_groups" {
    for_each = local.users_map
    user     = aws_iam_user.users[each.key].name
    groups   = [for r in each.value.roles : aws_iam_group.iam_groups[r].name]
}


output "user"{
    value = local.user_from_yaml
}
output "password"{
    value = {for u, user in aws_iam_user_login_profile.user_login : u => user.encrypted_password}
}
output "aws_iam_user_groups"{
  value = {for u, m in aws_iam_user_group_membership.user_groups : u => m.groups}
}