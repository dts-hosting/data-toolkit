import { test as base, expect } from "@playwright/test";
// import { CheckMediaDerivativesPage } from './page_check_media';
// import { CreateUpdateRecordsPage } from './page_create_update';
import { DataToolkitBasePage } from "./datatoolkit-basepage";
import { DeleteRecordsPage } from "./page_delete_records";
import { CheckMediaDerivativesPage } from "./page_check_media_derivatives";
import { CheckManifestRegistryPage } from "./page_manifest_registry";
import { CSpaceFixture } from "./cspace-fixture";

// Declare the types of your fixtures.
type MyFixtures = {
  checkMediaDerivativesPage: CheckMediaDerivativesPage;
  checkImportTerms: DataToolkitBasePage;
  checkExportRecords: DataToolkitBasePage;
  checkCreateUpdateRecords: DataToolkitBasePage;
  checkProfilePage: DataToolkitBasePage;
  checkCspace: CSpaceFixture;
  checkManifestRegistryPage: CheckManifestRegistryPage;
  // Extended file example
  checkDeleteRecordsPage: DeleteRecordsPage;

  // Add Profile Page
  // Refactor Manifest Registries Page
};

// Extend base test by providing "todoPage" and "settingsPage".
// This new "test" can be used in multiple test files, and each of them will get the fixtures.

export const test = base.extend<MyFixtures>({
  checkMediaDerivativesPage: async ({ page }, use) => {
    // Set up the fixture.
    const checkMediaDerivativesPage = new CheckMediaDerivativesPage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkMediaDerivativesPage.doLogin();

    // Use the fixture value in the test.
    await use(checkMediaDerivativesPage);
  },

  checkImportTerms: async ({ page }, use) => {
    // Set up the fixture.
    const checkImportTerms = new DataToolkitBasePage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkImportTerms.doLogin();

    // Use the fixture value in the test.
    await use(checkImportTerms);
  },

  checkExportRecords: async ({ page }, use) => {
    // Set up the fixture.
    const checkExportRecords = new DataToolkitBasePage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkExportRecords.doLogin();

    // Use the fixture value in the test.
    await use(checkExportRecords);
  },

  checkCreateUpdateRecords: async ({ page }, use) => {
    // Set up the fixture.
    const checkCreateUpdateRecords = new DataToolkitBasePage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkCreateUpdateRecords.doLogin();

    // Use the fixture value in the test.
    await use(checkCreateUpdateRecords);
  },

  checkDeleteRecordsPage: async ({ page }, use) => {
    // Set up the fixture.
    const checkDeleteRecordsPage = new DeleteRecordsPage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkDeleteRecordsPage.doLogin();

    // Use the fixture value in the test.
    await use(checkDeleteRecordsPage);
  },

  checkProfilePage: async ({ page }, use) => {
    // Set up the fixture.
    const checkProfilePage = new DataToolkitBasePage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkProfilePage.doLogin();

    // Use the fixture value in the test.
    await use(checkProfilePage);
  },

  checkManifestRegistryPage: async ({ page }, use) => {
    // Set up the fixture.
    const checkManifestRegistryPage = new DataToolkitBasePage(
      page,
      process.env.DATA_TOOLKIT_URL,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    await checkManifestRegistryPage.doLogin();

    // Use the fixture value in the test.
    await use(checkManifestRegistryPage);
  },

  checkCspace: async ({ page }, use) => {
    // Set up the fixture.
    const checkCspace = new CSpaceFixture(
      page,
      process.env.CSPACE_URL,
      process.env.CSPACE_ADMIN,
      process.env.CSPACE_PASSWORD
    );
    // await checkCspace.doLogin();

    // Use the fixture value in the test.
    await use(checkCspace);
  },
});
export { expect } from "@playwright/test";
