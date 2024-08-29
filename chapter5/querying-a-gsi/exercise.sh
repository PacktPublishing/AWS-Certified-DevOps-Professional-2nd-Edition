aws dynamodb update-table --table-name projects \
  --attribute-definitions AttributeName=Language,AttributeType=S AttributeName=Contact,AttributeType=S \
  --global-secondary-index-updates file://global-indexes.json

aws dynamodb query \
  --table-name projects \
  --index-name contact \
  --key-condition-expression "Contact = :c" \
  --expression-attribute-values file://query-by-contact.json \
  --return-consumed-capacity TOTAL

aws dynamodb query \
  --table-name projects \
  --index-name contact \
  --key-condition-expression "Contact = :c and #language = :l" \
  --expression-attribute-values file://query-by-contact-and-language.json \
  --expression-attribute-names '{"#language":"Language"}' \
  --return-consumed-capacity TOTAL
