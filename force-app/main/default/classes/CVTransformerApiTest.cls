@isTest
private class CVTransformerApiTest {
  @isTest
  static void testIframeTokenGetValid() {
    CVTransformerAccess__c access = new CVTransformerAccess__c();
    access.Name = 'test_token';
    insert access;

    Test.startTest();
    String token = CVTransformerApi.iframeTokenGet();
    Test.stopTest();
    System.assertNotEquals(null, token, 'Expected non-null token');
  }

  @isTest
  static void testIframeTokenGetInvalid() {
    Test.startTest();
    String token = CVTransformerApi.iframeTokenGet();
    Test.stopTest();
    System.assertEquals(
      null,
      token,
      'Expected null token when no access record exists'
    );
  }
}
