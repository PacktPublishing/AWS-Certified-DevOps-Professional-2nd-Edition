REPO_NAME=chapter8
REPO_PATH=folder/in/repo
TEST_FILE1=aws-put-file.txt
TEST_FILE2=git-add.txt

aws codecommit create-repository --repository-name "${REPO_NAME}" --repository-description 'Chapter 8 exercises'

echo 'added using aws put-file' > "${TEST_FILE1}"
aws codecommit put-file \
    --repository-name "${REPO_NAME}" \
    --branch-name main \
    --file-content "fileb://${TEST_FILE1}" \
    --file-path "${REPO_PATH}/${TEST_FILE1}" \
    --commit-message 'Added file using aws cli' \
    --name 'Your name' \
    --email yourname@foo.bar.com

aws codecommit get-folder --repository-name "${REPO_NAME}" --folder-path "${REPO_PATH}"
aws codecommit get-file --repository-name "${REPO_NAME}" --file-path "${REPO_PATH}/${TEST_FILE1}"
aws codecommit get-file \
    --repository-name "${REPO_NAME}" \
    --file-path "${REPO_PATH}/${TEST_FILE1}" \
    --query 'fileContent' \
    --output text | base64 --decode

git clone \
    --config credential.helper='!aws codecommit credential-helper $@' \
    --config credential.UseHttpPath=true \
    "$(aws codecommit get-repository \
        --repository-name "${REPO_NAME}" \
        --query 'repositoryMetadata.cloneUrlHttp' \
        --output text)"

cd "${REPO_NAME}"
git log
echo 'added using git' > "${REPO_PATH}/${TEST_FILE2}"
git add "${REPO_PATH}/${TEST_FILE2}"
git commit --message 'Added file using git'
git push
cd -

aws codecommit get-folder --repository-name "${REPO_NAME}" --folder-path "${REPO_PATH}"
