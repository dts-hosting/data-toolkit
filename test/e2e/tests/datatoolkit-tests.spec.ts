import { test, expect } from "./datatoolkit-test";

test.afterEach(async ({ page }, testInfo) => {
  // Check if the test has failed
  if (testInfo.status !== testInfo.expectedStatus) {
    const screenshotPath = testInfo.outputPath(`failure.png`);
    await page.screenshot({
      path: screenshotPath,
      fullPage: true,
    }); // Take the screenshot

    // Optionally, attach the screenshot to the test report
    testInfo.attachments.push({
      name: "Test Failed Screenshot",
      path: screenshotPath,
      contentType: "image/png",
    });
  }
});

test("Check Create/Update Records", async ({
  checkCreateUpdateRecords,
  checkCspace,
  page,
  browser
}, testInfo) => {
  test.setTimeout(120000); // Override test timeout for this specific test
  await test.step(
    "Create/Update Records - Success",
    async (step) => {
      await checkCreateUpdateRecords.goto(
        "Create or Update Records",
        "New Create or Update Records"
      );
      await checkCreateUpdateRecords.fillFormAndSubmit(
        "collectionobject",
        "data/test.csv"
      );

      // Wait for workflow tasks page to load and verify the results
      await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
      await expect(page.getByText("Succeeded")).toHaveCount(2, { timeout: 60000 });

      // Take a screenshot for verification
      const screenshotPath = testInfo.outputPath(
        `test-results/${step.titlePath
          .join("_")
          .replaceAll(" ", "")
          .replaceAll("/", "-")}.png`
      );

      await page.screenshot({ path: screenshotPath, fullPage: true });
      // Optionally, attach the screenshot to the test report
      testInfo.attachments.push({
        name: "Create/Update Records - Successt",
        path: screenshotPath,
        contentType: "image/png",
      });
    },
    { box: true }
  );

  await test.step(
    "Create/Update Records - Failure",
    async (step) => {
      await checkCreateUpdateRecords.goto(
        "Create or Update Records",
        "New Create or Update Records"
      );
      await checkCreateUpdateRecords.fillFormAndSubmit(
        "collectionobject",
        "data/test-failure.csv"
      );

      // Wait for workflow tasks page to load and verify the results
      await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
      await expect(page.getByText("Failed")).toHaveCount(1, { timeout: 60000 });

      // Take a screenshot for verification
      const screenshotPath = testInfo.outputPath(
        `test-results/${step.titlePath
          .join("_")
          .replaceAll(" ", "")
          .replaceAll("/", "-")}.png`
      );

      await page.screenshot({ path: screenshotPath, fullPage: true });
      // Optionally, attach the screenshot to the test report
      testInfo.attachments.push({
        name: "Create/Update Records - Failure",
        path: screenshotPath,
        contentType: "image/png",
      });
    },
    { box: true }
  );

  // checkCspace
  await test.step(
    "Check CSpace",
    async (step) => {
      const newContext = await browser.newContext();
      const newPage = await newContext.newPage();
      await checkCspace.doLogin(newPage);
      await newContext.close();
    },
    { box: true }
  );
});

test("Check Export Records Page", async ({
  checkExportRecords,
  page,
}, testInfo) => {
  await checkExportRecords.goto("Export Record IDs", "New Export Record IDs");
});

test("Check Import Terms Page", async ({
  checkImportTerms,
  page,
}, testInfo) => {
  await checkImportTerms.goto("Import Terms", "New Import Terms");
  // Commented out while we don't have options to select
  // await checkPages.fillFormAndSubmit('anthro 9.1.0 media','data/test.csv');

  // // Wait for workflow tasks page to load and verify the results
  // await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
  // await expect(page.getByText("Succeeded")).toHaveCount(1);
});

test("Check Media Derivatives Page", async ({
  checkMediaDerivativesPage,
  page,
}, testInfo) => {
  await checkMediaDerivativesPage.goto(
    "Check Media Derivatives",
    "New Check Media Derivatives"
  );
  await checkMediaDerivativesPage.fillFormAndSubmit(
    "anthro 9.1.0 media",
    "data/derivatives.csv"
  );

  // Wait for workflow tasks page to load and verify the results
  await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
  await expect(page.getByText("Succeeded")).toHaveCount(3, { timeout: 60000 });
});

test("Check Profile Page", async ({ checkProfilePage, page }, testInfo) => {
  await checkProfilePage.goto("My profile", "Email address");

  await page.getByText("Email address:").waitFor({ timeout: 15000 });
  await expect(
    page.getByText("admin@anthro.collectionspace.org")
  ).toBeVisible();
});

test("Check Manifest Registry Page", async ({
  checkManifestRegistryPage,
  page,
}, testInfo) => {
  await checkManifestRegistryPage.goto(
    "Manifest Registries",
    "Add New Manifest Registry"
  );
});

test("Check Delete Records Page", async ({
  checkDeleteRecordsPage,
  page,
}, testInfo) => {
  await checkDeleteRecordsPage.goto("Delete Records", "New Delete Records");
  await checkDeleteRecordsPage.fillFormAndSubmit(
    "collectionobject",
    "data/test.csv"
  );

  // Wait for workflow tasks page to load and verify the results
  await page.getByText("Workflow Tasks").waitFor({ timeout: 15000 });
  await expect(page.getByText("Succeeded")).toHaveCount(1, { timeout: 60000 });
});
