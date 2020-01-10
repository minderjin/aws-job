#!/bin/sh

if [ $# -ne 2 ]; then
  echo "Usage: sh s3sync.sh [S3 Source path] [S3 Target path]"
  exit 0
fi

startTime=$(date +%s)
now=$(date)
echo "[$now] Job start."

aws s3 sync $1 $2

endTime=$(date +%s)
now=$(date)
echo "[$now] Job end."

echo "[It takes $(($endTime - $startTime)) seconds to complete this task.]"
