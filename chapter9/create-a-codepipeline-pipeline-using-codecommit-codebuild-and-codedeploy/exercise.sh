export S3_BUCKET_NAME=devopspro-beyond-2
export AWS_REGION=eu-west-1
export S3_BUCKET_BASE_PREFIX=chapter9/create-a-codepipeline-pipeline-using-codecommit-codebuild-and-codedeploy
export INFRA_CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX=${S3_BUCKET_BASE_PREFIX}/infra
export CLOUDFORMATION_STACK_NAME=webservers
export APPLICATION_NAME=hello-web-service
export DEPLOYMENT_GROUP_BASE_NAME=web-servers
export DEPLOYMENT_GROUP_DEV=${DEPLOYMENT_GROUP_BASE_NAME}-dev
export DEPLOYMENT_GROUP_PROD=${DEPLOYMENT_GROUP_BASE_NAME}-prod
export REPO_NAME=chapter8

# Upload the cloudformation templates to s3
aws s3 sync infra s3://${S3_BUCKET_NAME}/${INFRA_CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX}/

# Use cloudformation to create the infrastructure
aws cloudformation deploy --template infra/nested-stacks-root.yaml --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM --stack-name ${CLOUDFORMATION_STACK_NAME} --parameter-overrides NetworkCIDR=10.1.0.0/19 S3Bucket=${S3_BUCKET_NAME}

# This sets up the dev and prod environment. View the URL of the loadbalancer for dev environment:
aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`ProdUrl`].OutputValue | [0]' --output text

# Clone the CodeCommit repository
git clone \
    --config credential.helper='!aws codecommit credential-helper $@' \
    --config credential.UseHttpPath=true \
    "$(aws codecommit get-repository \
        --repository-name "${REPO_NAME}" \
        --query 'repositoryMetadata.cloneUrlHttp' \
        --output text)"

cp --recursive app/* "${REPO_NAME}"
cd "${REPO_NAME}"
git add .
git commit --message 'Added deployment spec'
git push
cd -

# Create the CodeDeploy application:
aws deploy create-application --compute-platform Server --application-name ${APPLICATION_NAME}

CODEDEPLOY_SERVICE_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`CodeDeployServiceRole`].OutputValue | [0]' --output text)"

# Get environment details for dev
DOCKER_SERVERS_ASG="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`DevDockerAsg`].OutputValue | [0]' --output text)"

# Create the deployment group for the application on dev
aws deploy create-deployment-group --service-role-arn ${CODEDEPLOY_SERVICE_ROLE_ARN} --auto-scaling-groups ${DOCKER_SERVERS_ASG} --deployment-config-name CodeDeployDefault.OneAtATime --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_DEV}

# Get environment details for PROD
DOCKER_SERVERS_ASG="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`ProdDockerAsg`].OutputValue | [0]' --output text)"

# Create the deployment group for the application on dev
aws deploy create-deployment-group --service-role-arn ${CODEDEPLOY_SERVICE_ROLE_ARN} --auto-scaling-groups ${DOCKER_SERVERS_ASG} --deployment-config-name CodeDeployDefault.OneAtATime --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_PROD}


CODEPIPELINE_SERVICE_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`CodePipelineServiceRole`].OutputValue | [0]' --output text)"

# Render the pipeline

sed \
  --expression="s|<<PIPELINE_NAME>>|${APPLICATION_NAME}|g" \
  --expression="s|<<CODEPIPELINE_ROLE_ARN>>|${CODEPIPELINE_SERVICE_ROLE_ARN}|g" \
  --expression="s|<<S3_BUCKET_NAME>>|${S3_BUCKET_NAME}|g" \
  --expression="s|<<CODECOMMIT_REPO_NAME>>|${REPO_NAME}|g" \
  --expression="s|<<CODEBUILD_PROJECT_NAME>>|${REPO_NAME}|g" \
  --expression="s|<<CODEDEPLOY_APPLICATION_NAME>>|${APPLICATION_NAME}|g" \
  --expression="s|<<CODEDEPLOY_DEPLOYMENT_GROUP_NAME_DEV>>|${DEPLOYMENT_GROUP_DEV}|g" \
  --expression="s|<<CODEDEPLOY_DEPLOYMENT_GROUP_NAME_PROD>>|${DEPLOYMENT_GROUP_PROD}|g" \
  pipeline.yaml.tmpl > pipeline.yaml

aws codepipeline create-pipeline --cli-input-yaml file://pipeline.yaml
# if you get
# Parameter validation failed:
# Unknown parameter in pipeline: "pipelineType", must be one of: name, roleArn, artifactStore, artifactStores, stages, version
# Unknown parameter in pipeline: "executionMode", must be one of: name, roleArn, artifactStore, artifactStores, stages, version

# upgrade to the latest AWS CLI version

# Once the deployment is complete, you can use
# curl $(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`DevUrl`].OutputValue | [0]' --output text)
# to access the dev environment. You should get
# Hello World!

# Use curl $(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`ProdUrl`].OutputValue | [0]' --output text)
# for prod environment

# Delete the deployment groups
aws deploy delete-deployment-group --deployment-group-name ${DEPLOYMENT_GROUP_DEV} --application-name ${APPLICATION_NAME}
aws deploy delete-deployment-group --deployment-group-name ${DEPLOYMENT_GROUP_PROD} --application-name ${APPLICATION_NAME}

aws cloudformation delete-stack --stack-name ${CLOUDFORMATION_STACK_NAME}
