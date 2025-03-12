@isTest
private class ContentVersionControllerTest {
  @isTest
  static void testGetRelatedContentVersions() {
    // Create a test record
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    ContentVersion contentVersion = new ContentVersion(
      Title = 'Test Document',
      PathOnClient = 'TestDocument.pdf',
      VersionData = Blob.valueOf('Test Content')
    );
    insert contentVersion;
    contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersion.Id
      LIMIT 1
    ];

    // Link ContentDocument to the test record
    ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
      LinkedEntityId = testAccount.Id,
      ContentDocumentId = contentVersion.ContentDocumentId,
      ShareType = 'V'
    );
    insert contentDocumentLink;

    // Call the method and verify the results
    Test.startTest();
    List<ContentVersion> result = ContentVersionController.getRelatedContentVersions(
      testAccount.Id
    );
    Test.stopTest();

    System.assertEquals(1, result.size());
    System.assertEquals(contentVersion.Id, result[0].Id);
    System.assertEquals('Test Document', result[0].Title);
  }

  @isTest
  static void testGetRelatedContentVersions_NoContent() {
    // Create a test record
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    // Call the method and verify the results
    Test.startTest();
    List<ContentVersion> result = ContentVersionController.getRelatedContentVersions(
      testAccount.Id
    );
    Test.stopTest();

    System.assertEquals(0, result.size());
  }
}
