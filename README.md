# Data Toolkit

A Rails web application for CollectionSpace data related activities.

Initial use/re-setup the application:

```bash
rbenv install -s
bundle install
./bin/setup
```

Restart dev server without re-installing, etc.:

```bash
./bin/dev
```

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

Remote with Kamal.

```bash
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

_To run Kamal locally you must first [export these envvars](.kamal/secrets-common)._

A deployment can also be made via Github:

1. Pushes to `main` will deploy to production (TODO).
2. Pushes to `qa` will deploy to `qa`.
3. A deployment can be triggered via the Github Actions UI.
4. A deployment can be triggered via the Github Actions CLI.

```bash
# deploy via push to qa
git checkout qa
git reset --hard $my-branch && git push --force origin qa

# deploy via gh cli
gh workflow run deploy.yml # uses the current branch
gh workflow run deploy.yml --ref qa # specify the branch to run from
```
