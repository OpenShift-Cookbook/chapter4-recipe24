#!/bin/bash
function load_env {
    [ -z "$1" ] && return 1
    [ -f "$1" ] || return 0
 
    local key=$(basename $1)
    export $key="$(< $1)"
}
 
for f in ~/.env/mongodb/*
do
  load_env $f
done

set -x
if [ `date +%H:%M` == "23:50" ]
then
	FILE_NAME=$(date +"%Y%m%d%H%M")
	mongodump --host $OPENSHIFT_MONGODB_DB_HOST --port  $OPENSHIFT_MONGODB_DB_PORT --username $OPENSHIFT_MONGODB_DB_USERNAME --password $OPENSHIFT_MONGODB_DB_PASSWORD --db $OPENSHIFT_APP_NAME --out $OPENSHIFT_DATA_DIR/$FILE_NAME
	cd $OPENSHIFT_DATA_DIR
	zip -r $FILE_NAME.zip $FILE_NAME
	echo "Took MongoDB Dump" >> $OPENSHIFT_CRON_DIR/log/backup.log
	$OPENSHIFT_DATA_DIR/s3-bash/s3-put -k $AWS_ACCESS_KEY_ID -s $OPENSHIFT_DATA_DIR/s3-bash/AWSSecretAccessKeyIdFile -T $OPENSHIFT_DATA_DIR/$FILE_NAME.zip /$AWS_S3_BUCKET/$FILE_NAME.zip
	echo "Uploaded dump to Amazon S3" >> $OPENSHIFT_CRON_DIR/log/backup.log
	rm -f $OPENSHIFT_DATA_DIR/$FILE_NAME.zip
	rm -rf $OPENSHIFT_DATA_DIR/$FILE_NAME
fi

