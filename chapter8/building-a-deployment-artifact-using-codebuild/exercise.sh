REMOTE_GIT_REPO_URL=https://github.com/startnow65/chapter8.git
CODEBUILD_SERVICE_ROLE_NAME=codebuild
CODEBUILD_POLICY_NAME=codebuild
ARTIFACT_S3_BUCKET_NAME=devopspro-beyond-2
DOCKER_IMAGE_REPO_NAME=codebuild-app
export REPO_NAME="$(echo ${REMOTE_GIT_REPO_URL} | sed --regexp-extended 's|.*/(.*).git|\1|g')"

aws iam create-role --role-name ${CODEBUILD_SERVICE_ROLE_NAME} --assume-role-policy-document file://codebuild-assume-role-policy.json

aws iam put-role-policy --role-name ${CODEBUILD_SERVICE_ROLE_NAME} --policy-name ${CODEBUILD_POLICY_NAME} --policy-document file://codebuild-policy.json

aws ecr create-repository --repository-name ${DOCKER_IMAGE_REPO_NAME}

# Read in the access token
read REMOTE_GIT_REPO_TOKEN

# Import it into CodeBuild
aws codebuild import-source-credentials --server-type GITHUB --auth-type PERSONAL_ACCESS_TOKEN --token ${REMOTE_GIT_REPO_TOKEN}

aws codebuild create-project \
  --name "${REPO_NAME}" \
  --description "Builds the source code in the ${REPO_NAME} repository." \
  --source type=GITHUB,location="${REMOTE_GIT_REPO_URL}"\
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:7.0,computeType=BUILD_GENERAL1_SMALL \
  --service-role ${CODEBUILD_SERVICE_ROLE_NAME} \
  --artifacts type=S3,location=${ARTIFACT_S3_BUCKET_NAME},path=codebuild,name=${REPO_NAME}

aws codebuild create-webhook \
    --project-name "${REPO_NAME}" \
    --filter-groups "[[{\"type\":\"EVENT\",\"pattern\":\"PUSH\"},{\"type\":\"HEAD_REF\",\"pattern\":\"^refs/heads/$(git branch --show-current)\"}]]" \
    --build-type BUILD \
    --no-manual-creation

# Clone the remote git repository
git clone "$(echo ${REMOTE_GIT_REPO_URL} | sed --regexp-extended "s|^https://(.*)$|https://oauth:${REMOTE_GIT_REPO_TOKEN}@\1|g")"

# Copy the source files into the cloned git repository
cp src/* "${REPO_NAME}"

cd "${REPO_NAME}"
git add .
git commit --message 'Added source files'
git push
