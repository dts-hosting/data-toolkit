import { test, expect } from './datatoolkit-test';

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



test('Check Pages', async ({ checkPages, page }, testInfo) => {
  await test.step('Create/Update Records - Success', async (step) => {
    await checkPages.goto('Create or Update Records','New Create or Update Records');
    await checkPages.fillFormAndSubmit('collectionobject', 'data/test.csv');
    
    // Wait for workflow tasks page to load and verify the results
    await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
    await expect(page.getByText("Succeeded")).toHaveCount(2, { timeout: 15000 });

     // Take a screenshot for verification
    const screenshotPath = testInfo.outputPath(`test-results/${step.titlePath.join('_').replaceAll(' ', '').replaceAll('\/', '-')}.png`); 

    await page.screenshot({ path: screenshotPath, fullPage: true });
    // Optionally, attach the screenshot to the test report
    testInfo.attachments.push({
      name: 'Create/Update Records - Successt',
      path: screenshotPath,
      contentType: 'image/png',
    });
  }, { box: true });

  await test.step('Create/Update Records - Failure', async (step) => {
    await checkPages.goto('Create or Update Records','New Create or Update Records');
    await checkPages.fillFormAndSubmit('collectionobject', 'data/test-failure.csv');
    
    // Wait for workflow tasks page to load and verify the results
    await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
    await expect(page.getByText("Failed")).toHaveCount(1, { timeout: 15000 });

    // Take a screenshot for verification
    const screenshotPath = testInfo.outputPath(`test-results/${step.titlePath.join('_').replaceAll(' ', '').replaceAll('\/', '-')}.png`); 

    await page.screenshot({ path: screenshotPath, fullPage: true });
    // Optionally, attach the screenshot to the test report
    testInfo.attachments.push({
      name: 'Create/Update Records - Failure',
      path: screenshotPath,
      contentType: 'image/png',
    });
  }, { box: true });

  await test.step('Check Export Records Page', async (step) => {
    await checkPages.goto('Export Record IDs','New Export Record IDs');
    // await checkPages.fillFormAndSubmit('anthro 9.1.0 media','data/test.csv');
    
    // Wait for workflow tasks page to load and verify the results
    // await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
    // await expect(page.getByText("Succeeded")).toHaveCount(1);
  }, { box: true });

  await test.step('Check Import Terms Page', async (step) => {

    await checkPages.goto('Import Terms','New Import Terms');
    await checkPages.fillFormAndSubmit('anthro 9.1.0 media','data/test.csv');
    
    // Wait for workflow tasks page to load and verify the results
    await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
    await expect(page.getByText("Succeeded")).toHaveCount(1);
  }, { box: true });

  await test.step('Check Media Derivates Page', async (step) => {
    await checkPages.goto('Check Media Derivatives','New Check Media Derivatives');
    await checkPages.fillFormAndSubmit('anthro 9.1.0 media','data/test.csv');
    
    // Wait for workflow tasks page to load and verify the results
    await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
    await expect(page.getByText("Succeeded")).toHaveCount(1);
  }, { box: true });
});

test('Check Delete Records Page', async ({ checkDeleteRecordsPage, page }, testInfo) => {
  await checkDeleteRecordsPage.goto('Delete Records','New Delete Records');
  await checkDeleteRecordsPage.fillFormAndSubmit('collectionobject', 'data/test.csv');
  
  // Wait for workflow tasks page to load and verify the results
  await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
  await expect(page.getByText("Succeeded")).toHaveCount(1);
});
