# Upload the file to S3
aws s3 cp dynamodb-table.yaml s3://devopspro-beyond-2/cloudformation/templates/
aws cloudformation deploy --template dynamodb-table.yaml --stack-name dynamodb-table-cli --parameter-overrides Name=projects-cli BillingMode=PAY_PER_REQUEST
