REMOTE_GIT_REPO_URL=https://github.com/startnow65/chapter8.git
export REPO_NAME="$(echo ${REMOTE_GIT_REPO_URL} | sed --regexp-extended 's|.*/(.*).git|\1|g')"

# Read in the access token
read REMOTE_GIT_REPO_TOKEN

Clone the remote git repository
git clone "$(echo ${REMOTE_GIT_REPO_URL} | sed --regexp-extended "s|^https://(.*)$|https://oauth:${REMOTE_GIT_REPO_TOKEN}@\1|g")"

cp src-test/* "${REPO_NAME}"
cd "${REPO_NAME}"
git add .
git commit --message 'Added tests'
git push
