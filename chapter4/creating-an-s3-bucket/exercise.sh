aws s3 mb s3://devopspro-beyond --region eu-west-1
make_bucket failed: s3://devopspro-beyond An error occurred (BucketAlreadyExists) when calling the CreateBucket operation: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again.
make_bucket: devopspro-beyond
aws s3 ls
2024-02-25 04:00:54 devopspro-beyond-2
aws s3 ls s3://devopspro-beyond-2
