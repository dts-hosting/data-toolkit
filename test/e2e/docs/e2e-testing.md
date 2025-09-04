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
- Inside *e2e* directory run npm install 

## Running Tests
- Data Toolkit e2e
  - Required environment variables
    - DATA_TOOLKIT_URL
    - USERNAME
    - PASSWORD
  - Command line: npx playwright test
