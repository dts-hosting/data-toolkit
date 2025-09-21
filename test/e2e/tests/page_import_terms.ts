import { Page, Locator, test, expect } from '@playwright/test';

export class CheckMediaDerivativesPage {
  constructor(page) {
    this.page = page;
  }

  async navigateTo(toolkitUrl) {
    await this.page.goto(toolkitUrl);
    await expect(this.page).toHaveTitle(/Data Toolkit/);

    // Navigate to the Import Terms page
    await this.page.getByRole('link', { name: 'Import Terms' }).click();
    
    // Verify that we are on the correct page
    await expect(this.page.getByText('New Import Terms')).toBeVisible();
  }

  async checkMediaDerivates(file, statusExpected, countExpected) {
    // Locate the opetion of Collection Object 
    const option = await this.page.locator('option:has-text("anthro 9.1.0 media")').textContent();
    // Select the Option 
    await this.page.selectOption('#activity_data_config_id', option);

    // Upload the CSV file
    await this.page.locator('#activity_files').setInputFiles(file);
    // Submit the form
    await this.page.getByRole('button', { name: /submit/i }).click();

    // Verify the success message
    await expect(this.page.getByText('Workflow Tasks')).toBeVisible();
    // Verify that two actions were executed successfully
    await expect(this.page.getByText(statusExpected)).toHaveCount(countExpected);

  }
}
