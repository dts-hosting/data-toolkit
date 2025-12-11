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

test("Check Cspace", async ({
  checkCspace,
  page,
}, testInfo) => {
  // checkCspace
  await test.step(
    "Check CSpace",
    async (step) => {
      await checkCspace.doLogin();
    },
    { box: true }
  );
});
