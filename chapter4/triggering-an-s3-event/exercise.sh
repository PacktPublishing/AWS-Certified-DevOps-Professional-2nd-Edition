BUCKET_NAME=devopspro-beyond-2
TEST_FILE_NAME=notification_test.txt #hello there
TOPIC_ARN="$(aws sns create-topic --name s3-events --output text --query TopicArn)"
echo ${TOPIC_ARN}
aws sns subscribe --topic-arn "${TOPIC_ARN}" --protocol email --notification-endpoint youremail@you.com
UPDATED_POLICY="$(aws sns get-topic-attributes \
    --topic-arn "${TOPIC_ARN}" \
    --output text \
    --query 'Attributes.Policy' | \
        jq --arg topicArn "${TOPIC_ARN}" \
            --arg bucketName "${BUCKET_NAME}" \
            --arg accountNumber "$(echo $TOPIC_ARN | cut -d':' -f5)" \
            '. | { "Version": .Version, "Id": .Id, "Statement": [.Statement[], { "Sid": "s3-publish", "Effect": "Allow", "Principal": { "Service": "s3.amazonaws.com" }, "Action": "SNS:Publish", "Resource": $topicArn, "Condition": { "StringEquals": { "aws:SourceAccount": $accountNumber }, "ArnLike": { "aws:SourceArn": ("arn:aws:s3:::" + $bucketName) }}}] }' \
    )"
echo $UPDATED_POLICY | jq '.'
aws sns set-topic-attributes --topic-arn "${TOPIC_ARN}" --attribute-name Policy --attribute-value "${UPDATED_POLICY}"
aws s3api put-bucket-notification-configuration \
    --bucket "${BUCKET_NAME}" \
    --notification-configuration \
        "$(jq -n --arg topicArn "${TOPIC_ARN}" '{ "TopicConfigurations": [{ "TopicArn": $topicArn, "Events": [ "s3:ObjectCreated:*" ], "Filter": { "Key": { "FilterRules": [ { "Name": "suffix", "Value": ".txt" } ] } } }] }')"
echo "this file will trigger a notification" > "${TEST_FILE_NAME}"
aws s3 cp "${TEST_FILE_NAME}" "s3://${BUCKET_NAME}/${TEST_FILE_NAME}"
aws s3api put-bucket-notification-configuration \
    --bucket "${BUCKET_NAME}" \
    --notification-configuration {}
