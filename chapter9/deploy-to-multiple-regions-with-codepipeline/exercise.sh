export S3_BUCKET_NAME=devopspro-beyond-2
export AWS_REGION=eu-west-1
export S3_BUCKET_BASE_PREFIX=chapter9/deploy-to-multiple-regions-with-codepipeline
export INFRA_CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX=${S3_BUCKET_BASE_PREFIX}/infra
export CLOUDFORMATION_STACK_NAME=ss-roles
export CLOUDFORMATION_STACKSET_NAME=webservers
export APPLICATION_NAME=hello-web-service
export DEPLOYMENT_GROUP_DEV=${APPLICATION_NAME}-Dev
export DEPLOYMENT_GROUP_PROD=${APPLICATION_NAME}-Prod
export REPO_NAME=chapter8
export AWS_REGION_SECONDARY_1=eu-west-2
export AWS_REGION_SECONDARY_2=eu-central-1

# Upload the cloudformation templates to s3
aws s3 sync infra s3://${S3_BUCKET_NAME}/${INFRA_CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX}/

# Use cloudformation to create the infrastructure
aws cloudformation deploy --template infra/nested-stacks-root.yaml --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM --stack-name ${CLOUDFORMATION_STACK_NAME} --parameter-overrides S3Bucket=${S3_BUCKET_NAME}

# Get the ARN of required IAM roles
STACKSET_ADMIN_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`StackSetAdminRoleArn`].OutputValue | [0]' --output text)"
STACKSET_EXECUTION_ROLE_NAME="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`StackSetExecutionRoleName`].OutputValue | [0]' --output text)"
CODEDEPLOY_SERVICE_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`CodeDeployServiceRoleArn`].OutputValue | [0]' --output text)"
CODEDEPLOY_EC2_INSTANCE_PROFILE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`CodeDeployEC2InstanceProfileArn`].OutputValue | [0]' --output text)"
CODEPIPELINE_SERVICE_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`CodePipelineServiceRoleArn`].OutputValue | [0]' --output text)"

aws cloudformation create-stack-set --capabilities CAPABILITY_AUTO_EXPAND --stack-set-name ${CLOUDFORMATION_STACKSET_NAME} --description "Create the environment for multi-region deployment of ${APPLICATION_NAME}" --template-body file://infra/nested-stacks-stackset.yaml --administration-role-arn "${STACKSET_ADMIN_ROLE_ARN}"  --execution-role-name "${STACKSET_EXECUTION_ROLE_NAME}" --managed-execution Active=true --parameters ParameterKey=NetworkCIDR,ParameterValue=10.1.0.0/19 ParameterKey=AppName,ParameterValue=${APPLICATION_NAME} ParameterKey=CodeDeployServiceRoleArn,ParameterValue=${CODEDEPLOY_SERVICE_ROLE_ARN} ParameterKey=CodeDeploEC2InstanceProfileArn,ParameterValue=${CODEDEPLOY_EC2_INSTANCE_PROFILE_ARN} ParameterKey=S3Bucket,ParameterValue=${S3_BUCKET_NAME}

ACCOUNT_ID="$(aws sts get-caller-identity --output text --query 'Account')"
for region in ${AWS_REGION} ${AWS_REGION_SECONDARY_1} ${AWS_REGION_SECONDARY_2}; do
    aws cloudformation create-stack-instances --stack-set-name ${CLOUDFORMATION_STACKSET_NAME} --regions ${region} --accounts ${ACCOUNT_ID}
done

REMOTE_GIT_REPO_CONNECTION_ARN="$(aws codeconnections list-connections --provider-type-filter GitHub --max-results 1 --output text --query Connections[0].ConnectionArn)"
REMOTE_GIT_REPO_ID="$(echo ${REMOTE_GIT_REPO_URL} | sed --regexp-extended "s|^https://[^/]+/(.*).git$|\1|g")"

# Render the pipeline
sed \
  --expression="s|<<PIPELINE_NAME>>|${APPLICATION_NAME}-multi-region|g" \
  --expression="s|<<CODEPIPELINE_ROLE_ARN>>|${CODEPIPELINE_SERVICE_ROLE_ARN}|g" \
  --expression="s|<<S3_BUCKET_NAME>>|${S3_BUCKET_NAME}|g" \
  --expression="s|<<REMOTE_GIT_REPO_CONNECTION_ARN>>|${REMOTE_GIT_REPO_CONNECTION_ARN}|g" \
  --expression="s|<<REMOTE_GIT_REPO_ID>>|${REMOTE_GIT_REPO_ID}|g" \
  --expression="s|<<CODEBUILD_PROJECT_NAME>>|${REPO_NAME}|g" \
  --expression="s|<<CODEDEPLOY_APPLICATION_NAME>>|${APPLICATION_NAME}|g" \
  --expression="s|<<CODEDEPLOY_DEPLOYMENT_GROUP_NAME_DEV>>|${DEPLOYMENT_GROUP_DEV}|g" \
  --expression="s|<<CODEDEPLOY_DEPLOYMENT_GROUP_NAME_PROD>>|${DEPLOYMENT_GROUP_PROD}|g" \
  --expression="s|<<AWS_REGION>>|${AWS_REGION}|g" \
  --expression="s|<<AWS_REGION_SECONDARY_1>>|${AWS_REGION_SECONDARY_1}|g" \
  --expression="s|<<AWS_REGION_SECONDARY_2>>|${AWS_REGION_SECONDARY_2}|g" \
  pipeline.yaml.tmpl > pipeline.yaml

aws codepipeline create-pipeline --cli-input-yaml file://pipeline.yaml

for stackid in $(aws cloudformation list-stack-instances --stack-set-name ${CLOUDFORMATION_STACKSET_NAME} --output text --query 'Summaries[*].StackId'); do
    stackRegion=$(echo "${stackid}" | cut -d: -f4)
    stackName=$(echo "${stackid}" | cut -d: -f6 | cut -d/ -f2)
    prodUrl=$(aws cloudformation describe-stacks --stack-name ${stackName} --region ${stackRegion} --query 'Stacks[0].Outputs[?OutputKey==`ProdUrl`].OutputValue | [0]' --output text)

    echo Prod URL for ${stackRegion} is ${prodUrl}
    echo curl response is $(curl --silent ${prodUrl})
done

aws codepipeline delete-pipeline --name ${APPLICATION_NAME}
aws codepipeline delete-pipeline --name ${APPLICATION_NAME}-multi-region

for region in ${AWS_REGION} ${AWS_REGION_SECONDARY_1} ${AWS_REGION_SECONDARY_2}; do
    aws s3 rm --recursive s3://${S3_BUCKET_NAME}-${region}/
    aws cloudformation delete-stack-instances --stack-set-name ${CLOUDFORMATION_STACKSET_NAME} --no-retain-stacks --regions ${region} --accounts ${ACCOUNT_ID}
done

aws cloudformation delete-stack-set --stack-set-name ${CLOUDFORMATION_STACKSET_NAME}
aws cloudformation delete-stack --stack-name ${CLOUDFORMATION_STACK_NAME}
