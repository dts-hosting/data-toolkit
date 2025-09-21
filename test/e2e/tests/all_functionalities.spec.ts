import { test, expect } from '@playwright/test';
const CreateUpdateRecordsPage = require('./page_create_update');
const CheckMediaDerivativesPage = require('./page_check_media');

test.afterEach(async ({ page }, testInfo) => {
  // Check if the test has failed
  if (testInfo.status !== testInfo.expectedStatus) {

    const screenshotPath = testInfo.outputPath(`failure.png`); 
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true
    }); // Take the screenshot
    
    // Optionally, attach the screenshot to the test report
    testInfo.attachments.push({
      name: 'Test Failed Screenshot',
      path: screenshotPath,
      contentType: 'image/png',
    });
  }
});

test('Data Toolkit CSpace', async ({ page }) => {
  await test.step('Required Configuration', async () => {
    expect(process.env.DATA_TOOLKIT_URL).toBeDefined();
    // expect(process.env.CSPACE_URL).toBeDefined();
    // expect(process.env.USERNAME).toBeDefined();
    // expect(process.env.PASS).toBeDefined();

  }, { box: true });

  await test.step('Webpage Live', async () => {
    await page.goto(process.env.DATA_TOOLKIT_URL);
  
    await expect(page).toHaveTitle(/Data Toolkit/);
  }), { box: true };

  await test.step('Login', async () => {
    // await page.goto('https://toolkit.lyrasistechnology.org/');

    // await page.locator('#cspace_url').fill(process.env.CSPACE_URL);
    // await page.locator('#email_address').fill(process.env.USERNAME);
    // await page.locator('#password').fill(process.env.PASS);

    await page.locator('#cspace_url').fill('https://anthro.collectionspace.org/');
    await page.locator('#email_address').fill('admin@anthro.collectionspace.org');
    await page.locator('#password').fill('Administrator');
    
    await page.getByRole('button').click({ force: true });

    await expect(page.getByText('Welcome to your activities dashboard.')).toBeVisible();

    await page.context().storageState({ path: 'storageState.json' });
  }, { box: true });

  await test.step('Create/Update Records - Success', async (step) => {

    const recordsPage = new CreateUpdateRecordsPage(page);
    await recordsPage.navigateTo(process.env.DATA_TOOLKIT_URL);
    await recordsPage.createUpdateRecords('data/test.csv', 'Succeeded', 2);

    // Take a screenshot for verification
    await page.screenshot({ path: `test-results/${step.titlePath.join('_').replaceAll(' ', '').replaceAll('\/', '-')}.png`, fullPage: true });
    
  }, { box: true });

  await test.step('Create/Update Records - Failure', async (step) => {

    const recordsPage = new CreateUpdateRecordsPage(page);
    await recordsPage.navigateTo(process.env.DATA_TOOLKIT_URL);
    await recordsPage.createUpdateRecords('data/test-failure.csv', 'Failed', 1);

    // Take a screenshot for verification
    await page.screenshot({ path: `test-results/${step.titlePath.join('_').replaceAll(' ', '').replaceAll('\/', '-')}.png`, fullPage: true });
    
  }, { box: true });


  await test.step('Check Media Derivatives - Success', async (step) => {

    const checkMediaPage = new CheckMediaDerivativesPage(page);
    await checkMediaPage.navigateTo(process.env.DATA_TOOLKIT_URL);
    await checkMediaPage.checkMediaDerivates('data/test.csv', 'Succeeded', 1);

    // Take a screenshot for verification
    await page.screenshot({ path: `test-results/${step.titlePath.join('_').replaceAll(' ', '').replaceAll('\/', '-')}.png`, fullPage: true });
    
  }, { box: true });
});
