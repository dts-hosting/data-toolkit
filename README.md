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
CSPACE_URL=https://anthro.collectionspace.org
EMAIL_ADDRESS=admin@anthro.collectionspace.org
PASSWORD=Administrator
./bin/rake "crud:create:user[$CSPACE_URL,$EMAIL_ADDRESS,$PASSWORD]"

# import data configs from a manifest registry
MR_URL=https://gist.githubusercontent.com/mark-cooper/e8c7a5469ee9e365dc3265068726ed94/raw/8d1384a9172f508c326508aa86c97fa24acf4f21/meta-manifest.json
./bin/rake crud:import:manifest_registry[$MR_URL]

# create an activity
USER_ID=1
DATA_CFG_ID=1
ACT_TYPE=Activities::CreateOrUpdateRecords
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
