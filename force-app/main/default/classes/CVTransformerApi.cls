public with sharing class CVTransformerApi {
  @AuraEnabled(cacheable=true)
  public static ResponseData dataGet(Id contact_id) {
    List<CVTransformerConfiguration__c> configurations = [
      SELECT Name, api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configurations.isEmpty())
      return new ResponseData(null, null, null);
    CVTransformerConfiguration__c configuration = configurations[0];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    return new ResponseData(
      configuration.Name,
      contact.cvt_id__c,
      contact.cvt_secret__c
    );
  }

  @AuraEnabled
  public static String configurationUpsert(String api_key) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CV_Transformer/organizations');
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer ' + api_key);
    request.setHeader('Content-Type', 'application/json');
    Http http = new Http();
    HttpResponse response = http.send(request);
    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300)
      throw new AuraHandledException('Invalid API key');

    List<CVTransformerOrganization> organizations = (List<CVTransformerOrganization>) JSON.deserialize(
      response.getBody(),
      List<CVTransformerOrganization>.class
    );
    CVTransformerOrganization organization = organizations[0];

    List<CVTransformerConfiguration__c> configs = [
      SELECT Id, Name, api_key__c
      FROM CVTransformerConfiguration__c
    ];
    if (configs.isEmpty())
      configs.add(new CVTransformerConfiguration__c());
    for (CVTransformerConfiguration__c config : configs) {
      config.Name = organization == null ? '' : organization.id;
      config.api_key__c = api_key;
    }
    upsert configs;

    return configs[0].Name;
  }

  @AuraEnabled
  public static ResponseData candidateCreate(Id contact_id) {
    CVTransformerConfiguration__c config = [
      SELECT api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];
    if (contact.cvt_id__c != null)
      throw new AuraHandledException('Candidate already exists');

    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CV_Transformer/candidates');
    request.setMethod('POST');
    request.setHeader('Authorization', 'Bearer ' + config.api_key__c);
    request.setHeader('Content-Type', 'application/json');
    request.setBody('{}');
    Http http = new Http();
    HttpResponse response = http.send(request);

    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300) {
      throw new AuraHandledException(
        'Could not create candidate: ' + response.getBody()
      );
    }

    CVTransformerCandidate candidate = (CVTransformerCandidate) JSON.deserialize(
      response.getBody(),
      CVTransformerCandidate.class
    );

    contact.cvt_id__c = candidate.id;
    contact.cvt_secret__c = candidate.secret_editable;
    update contact;

    return new ResponseData(
      candidate.organization_id,
      candidate.id,
      candidate.secret_editable
    );
  }

  @AuraEnabled
  public static ResponseData contactAttachmentsSync(Id contact_id) {
    List<CVTransformerConfiguration__c> configurations = [
      SELECT Name, api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configurations.isEmpty())
      return new ResponseData(null, null, null);
    CVTransformerConfiguration__c configuration = configurations[0];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    return new ResponseData(
      configuration.Name,
      contact.cvt_id__c,
      contact.cvt_secret__c
    );
  }

  @AuraEnabled
  public static ResponseData candidateAttachmentsSync(Id contact_id) {
    List<CVTransformerConfiguration__c> configurations = [
      SELECT Name, api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configurations.isEmpty())
      return new ResponseData(null, null, null);
    CVTransformerConfiguration__c configuration = configurations[0];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    return new ResponseData(
      configuration.Name,
      contact.cvt_id__c,
      contact.cvt_secret__c
    );
  }

  @AuraEnabled
  public static ResponseData pdfGenerate(Id contact_id) {
    List<CVTransformerConfiguration__c> configurations = [
      SELECT Name, api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configurations.isEmpty())
      return new ResponseData(null, null, null);
    CVTransformerConfiguration__c configuration = configurations[0];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    return new ResponseData(
      configuration.Name,
      contact.cvt_id__c,
      contact.cvt_secret__c
    );
  }

  public class CVTransformerOrganization {
    public String id;
    public String avatar;
    public String name;
  }

  public class CVTransformerCandidate {
    public String id;
    public String organization_id;
    public String secret_editable;
  }

  public class ResponseData {
    @AuraEnabled
    public String organization_id;
    @AuraEnabled
    public String candidate_id;
    @AuraEnabled
    public String candidate_secret;

    public ResponseData(
      String organization_id,
      String candidate_id,
      String candidate_secret
    ) {
      this.organization_id = organization_id;
      this.candidate_id = candidate_id;
      this.candidate_secret = candidate_secret;
    }

    // JSON serialization
  }
}
