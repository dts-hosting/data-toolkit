import type {
  Page,
  Locator,
  expect,
  Browser,
  BrowserContext,
} from "@playwright/test";

export class CSpaceFixture {
  private readonly taskLabel: string = "Testing Script";
  private readonly optionFieldId: string = "#activity_data_config_id";
  private readonly fileFieldId: string = "#activity_files";

  constructor(
    public readonly page: Page,
    public readonly baseURL: string,
    private readonly username: string,
    private readonly password: string
  ) {}

  async doLogin(local_page = this.page) {
    await local_page.goto(this.baseURL);
    await local_page.waitForLoadState("load", { timeout: 60000 });

    await local_page
      .getByRole("link", { name: "Sign in" })
      .click({ timeout: 60000 });
    // await this.page.locator('#cspace_url').fill(this.cspaceUrl);
    await local_page.waitForLoadState("load", { timeout: 60000 });

    await local_page.getByLabel("Email").fill(this.username);
    await local_page.getByLabel("Password").fill(this.password);
    // await this.page.locator('#password').fill(this.password);

    await local_page.getByRole("button").click({ force: true, timeout: 60000 });
    await local_page.waitForLoadState("load", { timeout: 60000 });

    await local_page
      .getByText("My CollectionSpace")
      .waitFor({ timeout: 60000 });
  }

  async goto(
    linkToClick: string,
    titleToValidate: string,
    local_page = this.page
  ) {
    // Navigate to the Link page
    await local_page.getByRole("link", { name: linkToClick }).click();
    await local_page.getByText(titleToValidate).waitFor({ timeout: 15000 });

    await local_page.waitForLoadState();
  }

  async selectOption(optionTextToSearch: string, local_page = this.page) {
    // Locate the opetion of Collection Object
    const option = await local_page
      .locator(`option:has-text("${optionTextToSearch}")`)
      .textContent();
    // Select the Option
    await local_page.selectOption(this.optionFieldId, option);
  }

  async uploadFile(file: string, local_page = this.page) {
    // Upload the CSV file
    await local_page.locator(this.fileFieldId).setInputFiles(file);
  }

  async fillFormAndSubmit(
    optionTextToSearch: string,
    file: string,
    local_page = this.page
  ) {
    await local_page.locator("#activity_label").fill(this.taskLabel);
    await this.selectOption(optionTextToSearch);
    await this.uploadFile(file);
    // Submit the form
    await local_page
      .getByRole("button", { name: /submit/i })
      .click({ force: true });

    await local_page.waitForURL(/activities\/\d+$/, {
      waitUntil: "networkidle",
    });
  }

  async searchItem(
    itemToSearch: string,
    itemType: string = "All Records",
    local_page = this.page
  ) {
    // Search for the created task
    const headerDiv = local_page.locator(".cspace-ui-BannerMain--common");

    await headerDiv.getByRole("textbox").first().click();
    await headerDiv.getByRole("option", { name: itemType }).click();

    await headerDiv.getByPlaceholder("Search").fill(itemToSearch);
    await headerDiv
      .getByRole("button", { name: /search/i })
      .click({ force: true });

    await local_page.getByRole("row", { name: `${itemToSearch}` }).click();
  }

  async searchByIdAndTitle(
    itemId: string,
    itemTitle: string,
    local_page = this.page
  ) {
    // Search for the created task

    await local_page.goto(
      this.baseURL + "cspace/anthro/search/collectionobject"
    );
    await local_page
      .locator(".cspace-ui-TitleBar--common")
      .getByText("Search")
      .waitFor();

    await local_page
      .locator("header")
      .filter({ hasText: "of the following conditions" })
      .getByRole("textbox")
      .click();
    await local_page.getByRole("option", { name: "All" }).click();
    await local_page.getByRole("textbox").nth(5).click();
    await local_page.getByRole("option", { name: "matches" }).click();
    await local_page
      .locator("div:nth-child(2) > .cspace-input-LineInput--embedded")
      .first()
      .click();
    await local_page
      .locator("div:nth-child(2) > .cspace-input-LineInput--embedded")
      .first()
      .fill(itemId);
    await local_page
      .locator(
        "li:nth-child(7) > .cspace-ui-FieldConditionInput--normal > .cspace-input-DropdownMenuInput--common > .cspace-input-LineInput--normal"
      )
      .click();
    await local_page.getByRole("option", { name: "matches" }).click();
    await local_page
      .locator(
        "li:nth-child(7) > .cspace-ui-FieldConditionInput--normal > div:nth-child(3) > .cspace-input-RepeatingInput--normal > div > div > div:nth-child(2) > .cspace-input-LineInput--embedded"
      )
      .click();
    await local_page
      .locator(
        "li:nth-child(7) > .cspace-ui-FieldConditionInput--normal > div:nth-child(3) > .cspace-input-RepeatingInput--normal > div > div > div:nth-child(2) > .cspace-input-LineInput--embedded"
      )
      .fill(itemTitle);
    await local_page
      .getByRole("contentinfo")
      .filter({ hasText: "SearchClear" })
      .locator('button[name="search"]')
      .click();

    await local_page.getByRole("row", { name: `${itemTitle}` }).click();
  }

  async fetchRelatedObjects(itemToSearch: string, local_page = this.page) {
    const relatedObjects = await local_page.getByRole("button", {
      name: "Related Objects:",
    });
    await relatedObjects.click();
    return local_page
      .locator(".cspace-ui-SearchResultTable--common")
      .locator(".ReactVirtualized__Grid__innerScrollContainer")
      .count();
  }
}
