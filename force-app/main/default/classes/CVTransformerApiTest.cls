@isTest
private class CVTransformerApiTest {
  @testSetup
  static void setup() {
    // Create a test ContentVersion record
    ContentVersion contentVersion = new ContentVersion();
    contentVersion.Title = 'Test Document';
    contentVersion.PathOnClient = 'TestDocument.pdf';
    contentVersion.VersionData = Blob.valueOf('Test content');
    insert contentVersion;
  }

  @isTest
  static void testIframeTokenGet() {
    Test.startTest();
    String token = CVTransformerApi.iframeTokenGet();
    Test.stopTest();
    System.assertNotEquals(null, token, 'Expected non-null token');
  }

  @isTest
  static void testContactCreateValid() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String response = CVTransformerApi.contactCreate(contentVersion.Id);
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');
  }

  @isTest
  static void testContactCreateInvalid() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.statusCode = 400;
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    try {
      CVTransformerApi.contactCreate(contentVersion.Id);
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected error message');
    }
    Test.stopTest();
  }
}
