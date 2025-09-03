import { test, expect } from '@playwright/test';

test('Data Toolkit CSpace', async ({ page }) => {
  await test.step('Required Configuration', async () => {
    expect(process.env.DATA_TOOLKIT_URL).toBeDefined();

  }, { box: true });

  await test.step('Webpage Live', async () => {
    await page.goto(process.env.DATA_TOOLKIT_URL);
  
    await expect(page).toHaveTitle(/Data Toolkit/);
  }), { box: true };

  await test.step('Login', async () => {
    // await page.goto('https://toolkit.lyrasistechnology.org/');

    await page.locator('#cspace_url').fill('https://anthro.collectionspace.org/');
    await page.locator('#email_address').fill('admin@anthro.collectionspace.org');
    await page.locator('#password').fill('Administrator');
    // await page.locator('button[type="submit"]').click();
    await page.getByRole('button').click({ force: true });

    await expect(page.getByText('Welcome to your activities dashboard.')).toBeVisible();

    await page.context().storageState({ path: 'storageState.json' });
  }, { box: true });

});
