public with sharing class CVTransformerApi {
  @AuraEnabled(cacheable=false)
  public static String iframeTokenGet() {
    Auth.JWT jwt = new Auth.JWT();
    jwt.setIss('cv-transformer-salesforce');
    jwt.setSub(UserInfo.getUserId());
    jwt.setAud(URL.getOrgDomainUrl().toExternalForm());
    jwt.setAdditionalClaims(
      new Map<String, Object>{ 'org_id' => UserInfo.getOrganizationId() }
    );
    Auth.JWS jws = new Auth.JWS(jwt, 'CVTransformerJWT');
    return jws.getCompactSerialization();
  }

  @AuraEnabled
  public static String contactCreate(Id content_version_id) {
    String token = iframeTokenGet();

    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      'callout:' +
        // 'CVTransformer__' + // Only include in production
        'API' +
        '/salesforce-contact' +
        '?content_version_id=' +
        content_version_id
    );
    request.setMethod('POST');
    request.setHeader('Authorization', token);

    Http http = new Http();
    HttpResponse response = http.send(request);
    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300)
      throw new AuraHandledException(
        'Could not create candidate: ' + response.getBody()
      );

    return response.getBody();
  }
}
