REPO_NAME=chapter8
APPROVAL_RULE_TEMPLATE_NAME=require-at-least-one-from-any
REPO_LOCAL_FOLDER_NAME="${REPO_NAME}-ssh"
IAM_USER_NAME=ci
SSH_KEYPAIR_NAME=codecommit
REPO_PATH=folder/in/repo
TEST_FILE=git-add-via-pull-request.txt
BRANCH_NAME=new-fle

aws codecommit create-approval-rule-template \
    --approval-rule-template-name "${APPROVAL_RULE_TEMPLATE_NAME}" \
    --approval-rule-template-content file://approval-rule.json \
    --approval-rule-template-description 'Require at least one approval from anyone with access to the repository'

aws codecommit associate-approval-rule-template-with-repository --repository-name "${REPO_NAME}" --approval-rule-template-name "${APPROVAL_RULE_TEMPLATE_NAME}"

aws codecommit update-default-branch --repository-name "${REPO_NAME}" --default-branch-name main

git clone \
    --config core.sshCommand="ssh -i '$(pwd)/${SSH_KEYPAIR_NAME}' \
        -o StrictHostKeyChecking=accept-new \
        -o User='$(aws iam list-ssh-public-keys \
            --user-name "${IAM_USER_NAME}" \
            --query 'SSHPublicKeys[0].SSHPublicKeyId' \
            --output text)'" \
    "$(aws codecommit get-repository \
        --repository-name "${REPO_NAME}" \
        --query 'repositoryMetadata.cloneUrlSsh' \
        --output text)" \
    "${REPO_LOCAL_FOLDER_NAME}"

cd "${REPO_LOCAL_FOLDER_NAME}"

git branch "${BRANCH_NAME}"

git checkout "${BRANCH_NAME}"
echo 'added via pull request' > "${REPO_PATH}/${TEST_FILE}"
git add "${REPO_PATH}/${TEST_FILE}"
git commit --message 'Added via pull request'
git push origin "${BRANCH_NAME}:origin/${BRANCH_NAME}"
