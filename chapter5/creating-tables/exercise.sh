aws dynamodb create-table --table-name projects \
  --attribute-definitions AttributeName=Project_ID,AttributeType=S \
  --key-schema AttributeName=Project_ID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
