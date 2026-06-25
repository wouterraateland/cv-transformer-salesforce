public with sharing class CVTransformerApi {
  private static String base64UrlEncode(Blob input) {
    return EncodingUtil.base64Encode(input)
      .replace('+', '-')
      .replace('/', '_')
      .replace('=', '');
  }

  private static String sign(Map<String, Object> claims, String secret) {
    String signingInput =
      base64UrlEncode(Blob.valueOf('{"alg":"HS256","typ":"JWT"}')) +
      '.' +
      base64UrlEncode(Blob.valueOf(JSON.serialize(claims)));

    Blob mac = Crypto.generateMac(
      'HmacSHA256',
      Blob.valueOf(signingInput),
      Blob.valueOf(secret)
    );

    return signingInput + '.' + base64UrlEncode(mac);
  }

  @AuraEnabled(cacheable=false)
  public static String iframeTokenGet() {
    try {
      CVTransformerAccess__c access = [
        SELECT Name
        FROM CVTransformerAccess__c
        LIMIT 1
      ];
      return sign(
        new Map<String, Object>{
          'exp' => (DateTime.now().addMinutes(5).getTime() / 1000),
          'iat' => DateTime.now().getTime() / 1000,
          'iss' => 'cv-transformer-salesforce',
          'org_domain' => URL.getOrgDomainUrl().toExternalForm(),
          'sub' => UserInfo.getUserId()
        },
        access.Name
      );
    } catch (QueryException e) {
      return null;
    }
  }
}
