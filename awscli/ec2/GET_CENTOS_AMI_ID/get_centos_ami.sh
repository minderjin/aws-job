#!/bin/bash

# centOS6 Product code: 6x5jmcajty9edm3f211pqjfn21
# centOS7 Product code: aw0evgkw8e5c1q413zgy5pjce 

input=$1
if [ $# -ne 1 ]; then
	echo "Usage: $0 6|7"
	exit -1
elif [ $input = '7' ]
then
	aws ec2 describe-images \
	 --owners 'aws-marketplace' \
	 --filters 'Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce' \
	 --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
	 --output 'text' \
	 --region ap-northeast-2
elif [ $input = '6' ]
then
	aws ec2 describe-images \
	 --owners 'aws-marketplace' \
	 --filters 'Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce' \
	 --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
	 --output 'text' \
	 --region ap-northeast-2 
else
	echo "Usage: $0 6|7"
fi

