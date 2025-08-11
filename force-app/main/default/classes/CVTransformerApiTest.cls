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
      Email = 'test@example.com',
      FirstName = 'Test',
      LastName = 'Example',
      cvt_id__c = null,
      cvt_secret__c = null
    );
    insert contact;

    ContentVersion contentVersion = new ContentVersion(
      Title = 'Test CV',
      PathOnClient = 'TestCV.pdf',
      VersionData = Blob.valueOf('Test Data')
    );
    insert contentVersion;
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
  static void testGetMimeTypeOctet() {
    Test.startTest();
    String mimeType = CVTransformerApi.getMimeType('Invalid');
    Test.stopTest();
    System.assertEquals(
      'application/octet-stream',
      mimeType,
      'Expected MIME type for Invalid'
    );
  }

  @isTest
  static void testUtilDataGet() {
    Test.startTest();
    CVTransformerApi.UtilPageData response = CVTransformerApi.utilDataGet();
    Test.stopTest();
    System.assertEquals(
      'TestOrg',
      response.organization_id,
      'Expected organization_id to be TestOrg'
    );
  }

  @isTest
  static void testUtilDataGetEmpty() {
    Test.startTest();
    delete [SELECT Id FROM CVTransformerConfiguration__c];
    CVTransformerApi.UtilPageData response = CVTransformerApi.utilDataGet();
    Test.stopTest();
    System.assertEquals(
      null,
      response.organization_id,
      'Expected organization_id to be null'
    );
  }

  @isTest
  static void testContactDataGet() {
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
  static void testContactDataEmpty() {
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    delete [SELECT Id FROM CVTransformerConfiguration__c];
    CVTransformerApi.ContactPageData response = CVTransformerApi.contactDataGet(
      contact.Id
    );
    Test.stopTest();
    System.assertEquals(
      null,
      response.organization_id,
      'Expected organization_id to be null'
    );
  }

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
    List<ContentVersion> result = CVTransformerApi.getRelatedContentVersions(
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
    List<ContentVersion> result = CVTransformerApi.getRelatedContentVersions(
      testAccount.Id
    );
    Test.stopTest();

    System.assertEquals(0, result.size());
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
  static void testConfigUpsertEmpty() {
    delete [SELECT Id FROM CVTransformerConfiguration__c];
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
  static void testConfigUpsertError() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.statusCode = 400;
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    try {
      CVTransformerApi.configUpsert('test_api_key');
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected error message');
    }
    Test.stopTest();
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
  static void testContactCreate() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String response = CVTransformerApi.contactCreate(
      contentVersion.ContentDocumentId,
      contentVersion.Id
    );
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');
  }

  @isTest
  static void testContactCreateInvalidExtract() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.extractValid = false;
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String response = CVTransformerApi.contactCreate(
      contentVersion.ContentDocumentId,
      contentVersion.Id
    );
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');
  }

  @isTest
  static void testContactCreateBlankLastName() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.last_name = '';
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String response = CVTransformerApi.contactCreate(
      contentVersion.ContentDocumentId,
      contentVersion.Id
    );
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');
  }

  @isTest
  static void testContactCreateDuplicate() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.first_name = 'Test';
    mock.last_name = 'Example';
    mock.email = 'test@example.com';
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    try {
      CVTransformerApi.contactCreate(
        contentVersion.ContentDocumentId,
        contentVersion.Id
      );
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected duplicate contact error');
    }
    Test.stopTest();
  }

  @isTest
  static void testContactCreateWithSeven20OutsideOfSeven20() {
    CVTransformerApi.contactFields.add('seven20__cv_file_id__c');

    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    try {
      CVTransformerApi.contactCreate(
        contentVersion.ContentDocumentId,
        contentVersion.Id
      );
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected contact error');
    }
    Test.stopTest();

    CVTransformerApi.contactFields.remove('seven20__cv_file_id__c');
  }

  @isTest
  static void testContactCreateWithSeven20FileType() {
    CVTransformerApi.contentVersionFields.add('seven20__file_type__c');

    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Test.startTest();
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String response = CVTransformerApi.contactCreate(
      contentVersion.ContentDocumentId,
      contentVersion.Id
    );
    Test.stopTest();
    System.assertNotEquals(null, response, 'Expected non-null response');

    CVTransformerApi.contentVersionFields.remove('seven20__file_type__c');
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
  static void testContactTransformCvExisting() {
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    contact.cvt_id__c = '12345';
    update contact;

    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Test.startTest();
    try {
      CVTransformerApi.contactTransformCv(contact.Id);
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected error message');
    }
    Test.stopTest();
  }

  @isTest
  static void testContactTransformCvError() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.statusCode = 400;
    Test.setMock(HttpCalloutMock.class, mock);
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    try {
      CVTransformerApi.contactTransformCv(contact.Id);
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected error message');
    }
    Test.stopTest();
  }

  @isTest
  static void testContactTransformCvLinked() {
    Test.setMock(HttpCalloutMock.class, new CVTransformerApiMock());
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    ContentVersion contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    contentVersion = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersion.Id
      LIMIT 1
    ];
    ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
      LinkedEntityId = contact.Id,
      ContentDocumentId = contentVersion.ContentDocumentId,
      ShareType = 'V'
    );
    insert contentDocumentLink;

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
  static void testCandidateLinkError() {
    CVTransformerApiMock mock = new CVTransformerApiMock();
    mock.statusCode = 400;
    Test.setMock(HttpCalloutMock.class, mock);
    Contact contact = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    try {
      CVTransformerApi.candidateLink(contact.Id, '12345');
      System.assert(false, 'Expected exception not thrown');
    } catch (Exception e) {
      System.assert(true, 'Expected error message');
    }
    Test.stopTest();
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

  @isTest
  static void testCandidateSalesforceData() {
    CVTransformerApi.CandidateSalesforceData data = new CVTransformerApi.CandidateSalesforceData();
    System.assertEquals(
      data.last_name,
      '',
      'Expected last_name to be empty string'
    );
  }

  @isTest
  static void testStringToDate() {
    String dateString = '2023-10-01';
    Date result = CVTransformerApi.stringToDate(dateString);
    System.assertEquals(
      Date.valueOf(dateString),
      result,
      'Expected date to be ' + dateString
    );

    dateString = 'invalid-date';
    result = CVTransformerApi.stringToDate(dateString);
    System.assertEquals(null, result, 'Expected null for invalid date string');

    dateString = null;
    result = CVTransformerApi.stringToDate(dateString);
    System.assertEquals(null, result, 'Expected null for null date string');
  }

  @isTest
  static void testEmptyUtilPageData() {
    CVTransformerApi.UtilPageData data = new CVTransformerApi.UtilPageData();
    System.assertEquals(
      data.organization_id,
      null,
      'Expected organization_id to be null'
    );
    System.assertEquals(data.language, null, 'Expected language to be null');
    System.assertEquals(
      data.color_scheme,
      null,
      'Expected color_scheme to be null'
    );
  }

  @isTest
  static void testEmptyContactPageData() {
    CVTransformerApi.ContactPageData data = new CVTransformerApi.ContactPageData();
    System.assertEquals(
      data.organization_id,
      null,
      'Expected organization_id to be null'
    );
    System.assertEquals(data.language, null, 'Expected language to be null');
    System.assertEquals(
      data.color_scheme,
      null,
      'Expected color_scheme to be null'
    );
  }
}
