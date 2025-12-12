#!/bin/bash

export DATA_TOOLKIT_URL=https://toolkit.lyrasistechnology.org/
export CSPACE_URL=https://anthro.collectionspace.org/
export CSPACE_ADMIN=admin@anthro.collectionspace.org
export CSPACE_PASSWORD=Administrator

npx playwright test --trace on
npx playwright show-report
