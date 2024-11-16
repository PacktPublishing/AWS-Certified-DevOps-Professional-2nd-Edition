# Set require variables for subsequent commands
BUCKET_NAME=devopspro-beyond-2
TEST_FILES_FOLDER=test-files

# Create a new folder to hold the test files you will upload to the s3 bucket
mkdir ${TEST_FILES_FOLDER}

# Generate test files
for i in {1..20}; do
  str="$(head /dev/urandom | LC_ALL=C tr -dc A-Za-z0-9 | head -c 16)"
  fileName="${TEST_FILES_FOLDER}/${str}.txt"
  echo ${str} > ${fileName}
  echo "${BUCKET_NAME},${fileName}" >> ${TEST_FILES_FOLDER}/manifest.csv
done

# Upload the manifest file and test files to your s3 bucket
aws s3 sync ${TEST_FILES_FOLDER} s3://${BUCKET_NAME}/${TEST_FILES_FOLDER}
