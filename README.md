# Data Toolkit

A Rails web application for CollectionSpace data related activities.

Initial use/re-setup the application:

```bash
rbenv install -s
bundle install
./bin/setup
```

Restart dev server without re-installing, etc:

```bash
./bin/dev
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

## Deployment

Locally with Docker.

```bash
docker compose build
docker compose up
```

Remote with Kamal.

```bash
# TODO: download .kamal/secrets.qa

# verify connections to the server
bundle exec kamal server bootstrap -d qa

# verify access to docker registry
bundle exec kamal registry login -d qa

# run the deploy process
bundle exec kamal deploy -d qa

# run a command on the container
bundle exec kamal app exec -d qa "bin/rails about"

# connect to the container
bundle exec kamal app exec -i -d qa "bin/rails console"
```
