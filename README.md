# Data Toolkit

A Rails web application for CollectionSpace data related activities.

## Prerequisites

Install [mise](https://mise.jdx.dev/installing-mise.html) then run:

```bash
mise trust
mise install # install Ruby, Node
make install # install gems
```

### PostgreSQL Setup

This application requires PostgreSQL. The default development/test db urls are:

- `postgres://toolkit:toolkit@localhost:5432/toolkit_[development|test]`

To create the `toolkit` databases with Docker:

```bash
docker compose up -d db
./bin/rails db:setup
```

The development/test connection settings are in `config/database.yml`.

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

## Configuration

The project provides a prefab `.env` file that is ready for local use and shows what
needs to be configured for a production environment. You can override the defaults
set in `.env` by creating `.env.local` and redefining the value. This is useful for
testing CloudWatch publishing: `CW_ENABLED=true`.

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
ACT_TYPE=create_or_update_records
DATA_CFG_ID=$(./bin/rake "crud:read:data_configs[$USER_ID,$DATA_CFG_TYPE,$DATA_CFG_RECORD_TYPE]" | jq -r '.[0].id')
FILE=test/fixtures/files/test.csv
./bin/rake "crud:create:activity[$USER_ID,$LABEL,$ACT_TYPE,$DATA_CFG_ID,$FILE]" | jq .

# list tasks for activity
./bin/rake "crud:read:tasks[1]" | jq .
```

There is a task for generating basic sample data for objects:

```bash
bundle exec rake sample:objects[20000]
```

## QA with the production image

`docker compose` runs the **production** image (the same `Dockerfile` that ships to
Docker Hub) against a local PostgreSQL, for QA of a release candidate. It is not a
development environment, for that use `bin/dev` on the host with `docker compose up -d db`.

```bash
docker compose build
docker compose up -d
```

The app is served by Thruster on <http://localhost:3000> (container port 80). The
entrypoint runs `db:prepare` on boot, creating `toolkit_qa`, `toolkit_qa_cable`,
`toolkit_qa_cache` and `toolkit_qa_queue` on first start.

Because it runs as `RAILS_ENV=production`, Active Storage uses S3
(`config/environments/production.rb`). Set your QA bucket in `.env`:

```bash
ACTIVE_STORAGE_S3_BUCKET=your-qa-bucket
AWS_REGION=us-east-1
```

and export credentials in your shell before `docker compose up` — they are passed
through to the container and deliberately not committed:

```bash
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...
```

`.env` also sets `RAILS_ASSUME_SSL=false` and `RAILS_FORCE_SSL=false` so QA is
reachable over plain HTTP.
