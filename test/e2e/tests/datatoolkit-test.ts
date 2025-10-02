import { test as base, expect} from '@playwright/test';
// import { CheckMediaDerivativesPage } from './page_check_media';
// import { CreateUpdateRecordsPage } from './page_create_update';
import { DataToolkitBasePage } from './datatoolkit-basepage';
import { DeleteRecordsPage } from './page_delete_records';

// Declare the types of your fixtures.
type MyFixtures = {
  // checkMediaDerivatesPage: DataToolkitBasePage;
  checkPages: DataToolkitBasePage;
  // Extended file example
  checkDeleteRecordsPage: DeleteRecordsPage;
};

// Extend base test by providing "todoPage" and "settingsPage".
// This new "test" can be used in multiple test files, and each of them will get the fixtures.

export const test = base.extend<MyFixtures>({
  // checkMediaDerivatesPage: async ({ page }, use) => {
  //   // Set up the fixture.
  //   const checkMediaDerivatesPage = new DataToolkitBasePage(page, process.env.DATA_TOOLKIT_URL, 'https://anthro.collectionspace.org/','admin@anthro.collectionspace.org','Administrator' );
  //   await checkMediaDerivatesPage.doLogin();

  //   // Use the fixture value in the test.
  //   await use(checkMediaDerivatesPage);
  // },

  checkPages: async ({ page }, use) => {
    // Set up the fixture.
    const checkPages = new DataToolkitBasePage(page, process.env.DATA_TOOLKIT_URL, 'https://anthro.collectionspace.org/','admin@anthro.collectionspace.org','Administrator' );
    await checkPages.doLogin();
    
    // Use the fixture value in the test.
    await use(checkPages);
  },

  checkDeleteRecordsPage: async ({ page }, use) => {
    // Set up the fixture.
    const checkDeleteRecordsPage = new DeleteRecordsPage(page, process.env.DATA_TOOLKIT_URL, 'https://anthro.collectionspace.org/','admin@anthro.collectionspace.org','Administrator' );
    await checkDeleteRecordsPage.doLogin();
    
    // Use the fixture value in the test.
    await use(checkDeleteRecordsPage);
  },

});
export { expect } from '@playwright/test';