aws dynamodb scan \
  --table-name projects \
  --filter-expression "Dept = :d" \
  --expression-attribute-values file://scan-values.json \
  --return-consumed-capacity TOTAL
