GROUP_NAME=Admins
POLICY_NAME=AdministratorAccess

aws iam create-group --group-name "${GROUP_NAME}"
POLICY_ARN="$(aws iam list-policies --scope AWS --query 'Policies[*].Arn' | grep "/${POLICY_NAME}\"" | cut --delimiter='"' --fields=2)"
echo $POLICY_ARN
aws iam attach-group-policy --policy-arn "${POLICY_ARN}" --group-name "${GROUP_NAME}"
aws iam list-attached-group-policies --group-name "${GROUP_NAME}"
