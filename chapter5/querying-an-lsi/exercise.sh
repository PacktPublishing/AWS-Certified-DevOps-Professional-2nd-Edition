aws dynamodb delete-table --table-name projects

aws dynamodb create-table --table-name projects \
  --attribute-definitions AttributeName=Dept,AttributeType=S AttributeName=Project_Name,AttributeType=S AttributeName=Owner,AttributeType=S \
  --key-schema AttributeName=Dept,KeyType=HASH AttributeName=Project_Name,KeyType=RANGE \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --local-secondary-indexes file://local-indexes.json

aws dynamodb batch-write-item \
  --request-items file://projects_bulk.json \
  --return-consumed-capacity TOTAL

aws dynamodb query \
  --table-name projects \
  --key-condition-expression "Dept = :dept" \
  --expression-attribute-values file://query-by-department.json \
  --return-consumed-capacity TOTAL

aws dynamodb query \
  --table-name projects \
  --index-name owner \
  --key-condition-expression "Dept = :dept and #owner = :owner" \
  --expression-attribute-values file://query-by-department-and-owner.json \
  --expression-attribute-names '{"#owner":"Owner"}' \
  --projection-expression "Dept,#owner,Builds" \
  --return-consumed-capacity TOTAL

aws dynamodb query \
  --table-name projects \
  --index-name owner \
  --key-condition-expression "Dept = :dept and #owner = :owner" \
  --expression-attribute-values file://query-by-department-and-owner.json \
  --expression-attribute-names '{"#owner":"Owner"}' \
  --return-consumed-capacity TOTAL
