# Directory Structure

```text
data-toolkit/
├── test/
│   └── e2e/
│       └── docs/
│           └── e2e-testing.md
│       └── tests/
```

- `data-toolkit/`: Root project directory.
- `test/`: Contains all test-related files and folders.
- `e2e/`: End-to-end testing resources.
- `docs/`: Documentation for E2E tests.
- `tests/`: End-to-end test scripts.

# How to Test

## Requirements

- Node v22
- npm
- nvm (optional)

## Install Playwright

- Inside _e2e_ directory run `npm install`

Install all browser dependencies:

```bash
npx playwright install-deps
npx playwright install chromium
npx playwright install firefox
npx playwright install webkit
```

## Running Tests

- Data Toolkit e2e
  - Required environment variables
    - DATA_TOOLKIT_URL
    - CSPACE_URL
    - CSPACE_ADMIN
    - CSPACE_PASSWORD
  - Command line: `npx playwright test --trace on`

There is a script to help with this:

- `./run_test.sh`

## Current Tests

- Test Steps
  - Login Data Toolkit
  - Access Page
  - Media Derivatives
  - Import Terms
  - Export Records
  - Create Update Records
  - Profile
  - Manifest Registry
  - Delete RecordsP
  - Cspace

# Validate GitHub Action (https://github.com/nektos/act)

It's possible to validate the GitHub Action using ACT.
The recomendation is to use the Visual Code Extension.

It can also run from the `gh cli`:

```bash
gh extension install https://github.com/nektos/gh-act
# from data-toolkit root
gh act -W ".github/workflows/playwright.yml"
```

## Configuration File

There is a configuration file called **.actrc** at the root level of the repository.
