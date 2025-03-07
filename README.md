# Data Toolkit

A Rails web application for CollectionSpace data related activities.

```bash
rbenv install -s
bundle install
./bin/setup
```

```bash
./bin/rake crud:create:user["https://core.dev.collectionspace.org","admin@core.collectionspace.org","Administrator"]
./bin/rake crud:create:data_config["record_type","core","9035928","collectionobjects","https://ex.com/c-9035928.json"]
./bin/rake crud:create:activity[1,1,"Activities::CreateRecordActivity","test/fixtures/files/test.csv"]
```
