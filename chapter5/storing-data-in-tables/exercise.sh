aws dynamodb put-item \
  --table-name projects \
  --item file://project_item.json \
  --return-consumed-capacity TOTAL

aws dynamodb batch-write-item \
  --request-items file://projects_bulk.json \
  --return-consumed-capacity TOTAL
