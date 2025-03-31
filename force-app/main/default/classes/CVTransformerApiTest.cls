@isTest
private class CVTransformerApiTest {
  @testSetup
  static void setup() {
    // Create test data
    CVTransformerConfiguration__c config = new CVTransformerConfiguration__c(
      Name = 'TestOrg',
      api_key__c = 'test_api_key',
      color_scheme__c = 'blue',
      language__c = 'en'
    );
    insert config;

    Contact contact = new Contact(
      LastName = 'Test',
      cvt_id__c = null,
      cvt_secret__c = null
    );
    insert contact;
  }

  @isTest
  static void testGetMimeType() {
    Test.startTest();
    String mimeType = CVTransformerApi.getMimeType('PDF');
    Test.stopTest();
    System.assertEquals(
      'application/pdf',
      mimeType,
      'Expected MIME type for PDF'
    );
  }

  @isTest
  static void testDataGet() {
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    CVTransformerApi.ContactPageData response = CVTransformerApi.contactDataGet(
      contact.Id
    );
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');
    System.assertEquals(
      'TestOrg',
      response.organization_id,
      'Expected organization_id to be TestOrg'
    );
  }

  @isTest
  static void testConfigUpsert() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Test.startTest();
    String organization_id = CVTransformerApi.configUpsert('test_api_key');
    Test.stopTest();
    System.assertEquals(
      '12345',
      organization_id,
      'Expected organization name to be 12345'
    );
  }

  @isTest
  static void testConfigUpdate() {
    Test.startTest();
    CVTransformerApi.configUpdate('fr', 'red');
    Test.stopTest();
    CVTransformerConfiguration__c config = [
      SELECT language__c, color_scheme__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    System.assertEquals('fr', config.language__c, 'Expected language to be fr');
    System.assertEquals(
      'red',
      config.color_scheme__c,
      'Expected color scheme to be red'
    );
  }

  @isTest
  static void testContactTransformCv() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    CVTransformerApi.ContactPageData response = CVTransformerApi.contactTransformCv(
      contact.Id
    );
    Test.stopTest();
    System.assertNotEquals(
      null,
      response.candidate_id,
      'Expected candidate_id to be set'
    );
  }

  @isTest
  static void testCandidateLink() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    CVTransformerApi.ContactPageData response = CVTransformerApi.candidateLink(
      contact.Id,
      '12345'
    );
    Test.stopTest();
    System.assertEquals(
      '12345',
      response.candidate_id,
      'Expected candidate_id to be 12345'
    );
  }

  @isTest
  static void testCandidateUnlink() {
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    CVTransformerApi.candidateUnlink(contact.Id);
    Test.stopTest();
    contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact.Id
    ];
    System.assertEquals(
      null,
      contact.cvt_id__c,
      'Expected cvt_id__c to be null'
    );
    System.assertEquals(
      null,
      contact.cvt_secret__c,
      'Expected cvt_secret__c to be null'
    );
  }

  @isTest
  static void testCandidateAttachCV() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    ContentVersion contentVersion = new ContentVersion(
      Title = 'Test CV',
      PathOnClient = 'TestCV.pdf',
      VersionData = Blob.valueOf('Test Data')
    );
    insert contentVersion;
    Test.startTest();
    CVTransformerApi.ContactPageData response = CVTransformerApi.candidateAttachCV(
      contact.Id,
      contentVersion.Id
    );
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');
  }
}
