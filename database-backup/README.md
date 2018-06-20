# AbarCloud Database Backup
Using this template you can backup multiple databases regularly and automatically. 

## Backup

1. [Contact us](https://docs.abarcloud.com/support.html) to get an [object storage](https://docs.abarcloud.com/additional-services/object-storage.html) for your backups, if you don't have one already.
2. Create a `config.json` file with the connection details for the databases you wish to backup.  
   See [`config-example.json`](latest/config-example.json) for an example.  
   *NOTE*: If you are backing up a MongoDB replica set you can specify the replica set string as the `host` parameter. See [the MongoDB docs](https://docs.mongodb.com/manual/reference/program/mongodump/) for more information.

3. From dashboard navigate to Add to Project > Browse Catalog > Data Stores > Database Backup

For larger database dumps you may need to increase the memory limit of the CronJob.

By default this runs once an hour, but you can change the SCHEDULE to update the frequency. For help generating a cron schedule see [https://crontab.guru](https://crontab.guru). You should not create cron jobs that run every minute as they might increase your costs compared to running a single pod that runs continuously, and runs your tasks then sleeps for 60 seconds.

### Updating the config

You can update the config by editing the config secret in AbarCloud.

```
oc edit secret database-backup-config
```

You will need to edit the `config.json` value to the base64 encoded value of the config file. You can get this by running:
```
cat config-example.json | base64
```

The next time the CronJob runs it will use the value from the new config file.

## Restore

This guide assumes you already have a database installed on AbarCloud. If not then see [this guide for setting it up](https://docs.abarcloud.com/quickstart/database.html).

1. First we want to suspend the CronJob so we are not writing backups while restoring:
  ```
  oc patch cronjob database-backup -p '{"spec":{"suspend":true}}'
  ```

2. The template created a DeploymentConfig that can be used for restoring the data. We can now scale this up to 1 pod:
  ```
  oc scale --replicas=1 dc/database-backup-restore
  ```

3. Open a terminal on the `database-backup-restore` pod, using `oc rsh dc/database-backup-restore` to open the terminal

4. Download the backup you wish to restore:
  ```
  ossutil ls oss://bucket/path
  ossutil cp oss://bucket/path/file.dump backups/backup_to_restore.dump
  ```

5. Run the restore command:

  For PostgreSQL:
  ```
  pg_restore --no-owner --no-acl \
     --host=<DESTINATION POSTGRESQL HOST> \
     --port=5432 \
     --username=<DESTINATION POSTGRESQL USER> \
     --password \
     --dbname=<DESTINATION POSTGRESQL DB> \
     backups/backup_to_restore.dump
  ```

  For MySQL:
  ```
  mysql \
    --host=<DESTINATION MYSQL HOST> \
    --port=3306 \
    --user=<DESTINATION MYSQL USER> \
    --password \
    <DESTINATION MYSQL DB> < backups/backup_to_restore.dump
  ```

  For MongoDB:
  ```
  mongorestore \
    --host=<DESTINATION MONGODB HOST> \
    --port=27017 \
    --username=<DESTINATION MONGODB USER> \
    --db=<DESTINATION MONGODB DB> \
    --archive=backups/backup_to_restore.dump
  ```

6. We can now scale down the restore pod and reactivate the CronJob:
  ```
  oc scale --replicas=0 dc/database-backup-restore
  oc patch cronjob database-backup -p '{"spec":{"suspend":false}}'
  ```
