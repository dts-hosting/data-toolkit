# Data Toolkit

A Rails web application for CollectionSpace data related activities.

## Prerequisites

Install [mise](https://mise.jdx.dev/installing-mise.html) then run:

```bash
mise trust
mise install # install Ruby, Node, pnpm
make install # install gems, packages
```

### PostgreSQL Setup

This application requires PostgreSQL. The default development/test db urls are:

- `postgres://toolkit:toolkit@localhost:5432/toolkit_[development|test]`

To create the `toolkit` databases with Docker:

```bash
docker compose up -d db
./bin/rails db:setup
```

For production `DATABASE_URL` is required as an environment variable in the form:

- `postgres://$username:$password@$host:$port/$db_name`

### Rails Setup

Initial setup and run the application:

```bash
./bin/setup
```

For just running the server without redoing the setup steps:

```bash
./bin/dev
```

## CLI tasks

```bash
# create a user
CSPACE_URL=https://anthro.collectionspace.org
EMAIL_ADDRESS=admin@anthro.collectionspace.org
PASSWORD=Administrator
./bin/rake "crud:create:user[$CSPACE_URL,$EMAIL_ADDRESS,$PASSWORD]" | jq .

# import data configs from a manifest registry
MR_URL=https://gist.githubusercontent.com/mark-cooper/0492cc97d53a47105dd29ca86799c8c7/raw/f376621f1c2e110f88fc1bdd10c5437f0abc99a5/meta-manifest2.json
./bin/rake "crud:import:manifest_registry[$MR_URL]" | jq .

# display data configs scoped to user
USER_ID=1
DATA_CFG_TYPE=record_type
DATA_CFG_RECORD_TYPE=collectionobject
./bin/rake "crud:read:data_configs[$USER_ID,$DATA_CFG_TYPE,$DATA_CFG_RECORD_TYPE]" | jq .

# create an activity
USER_ID=1
LABEL=coll1
ACT_TYPE=Activities::CreateOrUpdateRecords
DATA_CFG_ID=$(./bin/rake "crud:read:data_configs[$USER_ID,$DATA_CFG_TYPE,$DATA_CFG_RECORD_TYPE]" | jq -r '.[0].id')
FILE=test/fixtures/files/test.csv
./bin/rake "crud:create:activity[$USER_ID,$LABEL,$ACT_TYPE,$DATA_CFG_ID,$FILE]" | jq .

# list tasks for activity
./bin/rake "crud:read:tasks[1]" | jq .
```

## Deployment

Locally with Docker.

```bash
docker compose build
docker compose up
```
