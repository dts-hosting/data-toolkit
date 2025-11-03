import type { Page, Locator, expect} from '@playwright/test';

export class CSpaceFixture {
  private readonly taskLabel: string = 'Testing Script';
  private readonly optionFieldId: string = '#activity_data_config_id';
  private readonly fileFieldId: string = '#activity_files';

  constructor(public readonly page: Page, public readonly baseURL: string, private readonly username: string, private readonly password: string) {

  }

  
  async doLogin() {
    await this.page.goto(this.baseURL);
    await this.page.waitForLoadState();

    await this.page.getByRole('link', { name: "Sign in" }).click();
    // await this.page.locator('#cspace_url').fill(this.cspaceUrl);

    await this.page.getByLabel('Email').fill(this.username);
    await this.page.getByLabel('Password').fill(this.password);
    // await this.page.locator('#password').fill(this.password);
    
    await this.page.getByRole('button').click({ force: true });

    await this.page.getByText("My CollectionSpace").waitFor({ timeout: 15000 });
  }

  async goto(linkToClick: string, titleToValidate: string) {
    // Navigate to the Link page
    await this.page.getByRole('link', { name: linkToClick }).click();
    await this.page.getByText(titleToValidate).waitFor({ timeout: 15000 });

    await this.page.waitForLoadState();
  }


  async selectOption( optionTextToSearch: string) {
    // Locate the opetion of Collection Object 
    const option = await this.page.locator(`option:has-text("${optionTextToSearch}")`).textContent();
    // Select the Option 
    await this.page.selectOption(this.optionFieldId, option);
  }

  async uploadFile(file: string) {
      // Upload the CSV file
    await this.page.locator(this.fileFieldId).setInputFiles(file);
  }
  
  async fillFormAndSubmit(optionTextToSearch: string, file: string) {
    await this.page.locator('#activity_label').fill(this.taskLabel);
    await this.selectOption(optionTextToSearch);
    await this.uploadFile(file);
    // Submit the form
    await this.page.getByRole('button', { name: /submit/i }).click({ force: true });
    
    await this.page.waitForURL(/activities\/\d+$/, { waitUntil: 'networkidle' });
  }

}
