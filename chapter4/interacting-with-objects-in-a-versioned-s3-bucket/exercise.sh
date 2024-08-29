BUCKET_NAME=devopspro-beyond-2
MY_FILE=myfile.txt
aws s3api put-bucket-versioning --bucket ${BUCKET_NAME} --versioning-configuration Status=Enabled
aws s3api get-bucket-versioning --bucket ${BUCKET_NAME}
echo "this is version 1 of my file" > ${MY_FILE}
aws s3 cp ${MY_FILE} s3://${BUCKET_NAME}/${MY_FILE}
aws s3api list-object-versions --bucket ${BUCKET_NAME} --prefix ${MY_FILE}
echo "this is version 2 of my file" > ${MY_FILE}
aws s3 cp ${MY_FILE} s3://${BUCKET_NAME}/${MY_FILE}
aws s3api list-object-versions --bucket ${BUCKET_NAME} --prefix ${MY_FILE}
aws s3api get-object --bucket ${BUCKET_NAME} --key ${MY_FILE} --version-id Z7tSEmFnI3woHAWSzxnoU3E3pd5IZz5v ${MY_FILE}.old
cat ${MY_FILE}.old
aws s3 rm s3://${BUCKET_NAME}/${MY_FILE}
aws s3 cp s3://${BUCKET_NAME}/${MY_FILE} ${MY_FILE}.missing
aws s3api list-object-versions --bucket ${BUCKET_NAME} --prefix ${MY_FILE}
aws s3api delete-object --bucket ${BUCKET_NAME} --key ${MY_FILE} --version-id GR1Xb1rAHNl9sJ6S75_g7T9rR14HGaWi
aws s3 cp s3://${BUCKET_NAME}/${MY_FILE} ${MY_FILE}.recovered
