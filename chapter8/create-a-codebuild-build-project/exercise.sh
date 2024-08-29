REPO_NAME=chapter8
CODEBUILD_SERVICE_ROLE_NAME=codebuild
CODEBUILD_POLICY_NAME=codebuild
ARTIFACT_S3_BUCKET_NAME=devopspro-beyond-2
DOCKER_IMAGE_REPO_NAME=codebuild-app

aws iam create-role --role-name ${CODEBUILD_SERVICE_ROLE_NAME} --assume-role-policy-document file://codebuild-assume-role-policy.json

aws iam put-role-policy --role-name ${CODEBUILD_SERVICE_ROLE_NAME} --policy-name ${CODEBUILD_POLICY_NAME} --policy-document file://codebuild-policy.json

aws ecr create-repository --repository-name ${DOCKER_IMAGE_REPO_NAME}

codecommit_repo_url_http="$(aws codecommit get-repository \
        --repository-name "${REPO_NAME}" \
        --query 'repositoryMetadata.cloneUrlHttp' \
        --output text)"

aws codebuild create-project \
  --name "${REPO_NAME}" \
  --description "Builds the source code in the ${REPO_NAME} repository." \
  --source type=CODECOMMIT,location="${codecommit_repo_url_http}"\
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL \
  --service-role ${CODEBUILD_SERVICE_ROLE_NAME} \
  --artifacts type=S3,location=${ARTIFACT_S3_BUCKET_NAME},path=codebuild,name=${REPO_NAME}

git clone \
    --config credential.helper='!aws codecommit credential-helper $@' \
    --config credential.UseHttpPath=true \
    "${codecommit_repo_url_http}"

cp src/* "${REPO_NAME}"
cd "${REPO_NAME}"
git add .
git commit --message 'Added source files'
git push
