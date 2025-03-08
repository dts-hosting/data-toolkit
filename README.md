# Data Toolkit

A Rails web application for CollectionSpace data related activities.

```bash
rbenv install -s
bundle install
./bin/setup
```

```bash
# create a user
CSPACE_URL=https://core.dev.collectionspace.org
EMAIL_ADDRESS=admin@core.collectionspace.org
PASSWORD=Administrator
./bin/rake "crud:create:user[$CSPACE_URL,$EMAIL_ADDRESS,$PASSWORD]"

# create a data config
CFG_TYPE=record_type
PROFILE=core
UI_VERSION=9035928
REC_TYPE=collectionobjects
CFG_URL=https://ex.com/c-9035928.json
./bin/rake "crud:create:data_config[$CFG_TYPE,$PROFILE,$UI_VERSION,$REC_TYPE,$CFG_URL]"

# TODO: import data configs from manifest
MF_URL=
./bin/rake crud:import:data_config[$MF_URL]

# create an activity
USER_ID=1
DATA_CFG_ID=1
ACT_TYPE=Activities::CreateRecordActivity
FILE=test/fixtures/files/test.csv
./bin/rake "crud:create:activity[$USER_ID,$DATA_CFG_ID,$ACT_TYPE,$FILE]"
```
