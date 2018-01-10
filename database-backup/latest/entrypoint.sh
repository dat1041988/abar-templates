#!/usr/bin/env bash

cat <<EOF > /.ossutilconfig
[Credentials]
language=EN
endpoint=oss-eu-central-1.aliyuncs.com
accessKeyID=$OSS_ID
accessKeySecret=$OSS_KEY
EOF

exec "$@"
