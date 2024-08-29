aws dynamodb query \
  --table-name projects \
  --projection-expression "Dept,Project_Name" \
  --key-condition-expression "Project_ID = :v1" \
  --expression-attribute-values file://query-values.json \
  --return-consumed-capacity TOTAL
