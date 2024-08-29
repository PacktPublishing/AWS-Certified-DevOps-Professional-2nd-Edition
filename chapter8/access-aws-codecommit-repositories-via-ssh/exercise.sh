REPO_NAME=chapter8
REPO_LOCAL_FOLDER_NAME="${REPO_NAME}-ssh"
DEVELOPERS_GROUP_NAME=developers
IAM_USER_NAME=ci
SSH_KEYPAIR_NAME=codecommit
REPO_PATH=folder/in/repo
TEST_FILE=git-add-via-ssh.txt

aws iam create-group --group-name "${DEVELOPERS_GROUP_NAME}"

aws iam attach-group-policy --group-name "${DEVELOPERS_GROUP_NAME}" --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser

aws iam create-user --user-name "${IAM_USER_NAME}"
aws iam add-user-to-group --group-name "${DEVELOPERS_GROUP_NAME}" --user-name "${IAM_USER_NAME}"

ssh-keygen -t RSA -b 4096 -C "codecommit chapter8" -f "${SSH_KEYPAIR_NAME}"

aws iam upload-ssh-public-key --user-name "${IAM_USER_NAME}" --ssh-public-key-body "file://${SSH_KEYPAIR_NAME}.pub"

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

echo 'added using git over ssh' > "${REPO_PATH}/${TEST_FILE}"
git add "${REPO_PATH}/${TEST_FILE}"
git commit --message 'Added file using git over ssh'
git push
cd -

aws codecommit get-folder --repository-name "${REPO_NAME}" --folder-path "${REPO_PATH}"
