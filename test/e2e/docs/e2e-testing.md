# Directory Structure

```
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

- Inside _e2e_ directory run npm install

## Running Tests

- Data Toolkit e2e
  - Required environment variables
    - DATA_TOOLKIT_URL
    - CSPACE_URL
    - CSPACE_ADMIN
    - CSPACE_PASSWORD
  - Command line: npx playwright test --trace on

## Current Tests

- Test Steps
  - Media Derivatives (file: page_check_media_derivatives.ts)
    - Login Data Toolkit
    - Access Page
    - Fill the form uploading the file **_derivates.csv_**
      - Wait for **\*Succeeded** 3 times in the Workflow Page
  - Import Terms
  - Export Records
  - Create Update Records
  - Profile
  - Manifest Registry
  - Delete RecordsP
  - Cspace
