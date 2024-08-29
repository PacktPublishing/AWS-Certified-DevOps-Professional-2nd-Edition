REPO_NAME=chapter8

git clone \
    --config credential.helper='!aws codecommit credential-helper $@' \
    --config credential.UseHttpPath=true \
    "$(aws codecommit get-repository \
        --repository-name "${REPO_NAME}" \
        --query 'repositoryMetadata.cloneUrlHttp' \
        --output text)"

cp src-test/* "${REPO_NAME}"
cd "${REPO_NAME}"
git add .
git commit --message 'Added tests'
git push
