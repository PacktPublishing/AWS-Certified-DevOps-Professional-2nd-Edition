BUCKET_NAME=devopspro-beyond-2
sed --regexp-extended --expression "s/(.*),(.*)/${BUCKET_NAME},\2/g" manifest.csv
aws s3 sync . s3://${BUCKET_NAME}
