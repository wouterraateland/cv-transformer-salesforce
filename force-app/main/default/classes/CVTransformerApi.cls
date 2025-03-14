public with sharing class CVTransformerApi {
  private static Set<String> contentVersionFieldsList() {
    Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
      .get('ContentVersion')
      .getDescribe()
      .fields.getMap();

    return fieldMap.keySet();
  }

  public static String getMimeType(String fileType) {
    Map<String, String> mimeMap = new Map<String, String>{
      'DOC' => 'application/msword',
      'DOCX' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'JPG' => 'image/jpeg',
      'PDF' => 'application/pdf',
      'PNG' => 'image/png',
      'WEBP' => 'image/webp',
      'TXT' => 'text/plain'
    };
    return mimeMap.containsKey(fileType)
      ? mimeMap.get(fileType)
      : 'application/octet-stream';
  }

  @AuraEnabled(cacheable=true)
  public static ResponseData dataGet(Id contact_id) {
    List<CVTransformerConfiguration__c> configs = [
      SELECT Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configs.isEmpty())
      return new ResponseData();
    CVTransformerConfiguration__c config = configs[0];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    return new ResponseData(config, contact);
  }

  @AuraEnabled
  public static String configUpsert(String api_key) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CVTransformer__API/organizations');
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
  public static void configUpdate(String language, String color_scheme) {
    CVTransformerConfiguration__c config = [
      SELECT Id, Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
    ];
    config.color_scheme__c = color_scheme;
    config.language__c = language;
    update config;
  }

  @AuraEnabled
  public static ResponseData candidateCreate(Id contact_id) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    Contact contact = [
      SELECT
        cvt_id__c,
        cvt_secret__c,
        (SELECT ContentDocumentId FROM ContentDocumentLinks)
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];
    if (contact.cvt_id__c != null)
      throw new AuraHandledException('Candidate already exists');

    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CVTransformer__API/candidates');
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

    Set<String> contentVersionFields = contentVersionFieldsList();

    if (
      contentVersionFields.contains('seven20__file_type__c') &&
      !contact.ContentDocumentLinks.isEmpty()
    ) {
      List<String> contentDocumentIds = new List<String>();
      for (ContentDocumentLink cdl : contact.ContentDocumentLinks)
        contentDocumentIds.add('\'' + cdl.ContentDocumentId + '\'');
      List<ContentVersion> contentVersions = Database.query(
        'SELECT ' +
          String.join(contentVersionFields, ', ') +
          ' FROM ContentVersion WHERE ContentDocumentId IN (' +
          String.join(contentDocumentIds, ', ') +
          ') AND IsLatest = TRUE AND seven20__file_type__c = \'CV\''
      );
      ContentVersion contentVersion = contentVersions[0];

      if (contentVersion != null)
        attach(config.api_key__c, contact.cvt_id__c, 'cv', contentVersion);
    }

    update contact;

    return new ResponseData(config, contact);
  }

  @AuraEnabled
  public static ResponseData candidateLink(Id contact_id, String candidate_id) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c, color_scheme__c, language__c
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

    CVTransformerCandidate candidate = candidateGet(
      config.api_key__c,
      candidate_id
    );
    if (candidate == null)
      throw new AuraHandledException('Candidate not found');

    contact.cvt_id__c = candidate.id;
    contact.cvt_secret__c = candidate.secret_editable;
    update contact;

    return new ResponseData(config, contact);
  }

  @AuraEnabled
  public static void candidateUnlink(Id contact_id) {
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    contact.cvt_id__c = null;
    contact.cvt_secret__c = null;
    update contact;
  }

  @AuraEnabled
  public static ResponseData candidateAttachCV(
    Id contact_id,
    Id content_version_id
  ) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];
    ContentVersion contentVersion = [
      SELECT Title, VersionData, FileType
      FROM ContentVersion
      WHERE Id = :content_version_id
      LIMIT 1
    ];

    HttpResponse response = attach(
      config.api_key__c,
      contact.cvt_id__c,
      'cv',
      contentVersion
    );
    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300) {
      throw new AuraHandledException(
        'Could not sync attachment: ' + response.getBody()
      );
    }

    return new ResponseData(config, contact);
  }

  public class CVTransformerOrganization {
    public String id;
    public String avatar;
    public String name;
  }

  public class CVTransformerCandidateAttachment {
    public String text;
    public String type;
    public String url;
  }

  public class CVTransformerCandidate {
    public String id;
    public String organization_id;
    public String secret_editable;
    public Map<String, CVTransformerCandidateAttachment> attachments;
  }

  private static CVTransformerCandidate candidateGet(
    String api_key,
    String id
  ) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CVTransformer__API/candidates?id=eq.' + id);
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer ' + api_key);
    Http http = new Http();
    HttpResponse response = http.send(request);
    List<CVTransformerCandidate> candidates = (List<CVTransformerCandidate>) JSON.deserialize(
      response.getBody(),
      List<CVTransformerCandidate>.class
    );
    return candidates[0];
  }

  private static HttpResponse attach(
    String api_key,
    String candidate_id,
    String location,
    ContentVersion contentVersion
  ) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      'callout:CVTransformer__API/candidates/' +
        candidate_id +
        '/attach?location=' +
        location
    );
    request.setMethod('POST');
    request.setHeader('Authorization', 'Bearer ' + api_key);
    request.setHeader('Content-Type', getMimeType(contentVersion.FileType));
    request.setHeader(
      'Content-Disposition',
      'attachment; filename="' + contentVersion.Title + '"'
    );
    request.setBodyAsBlob(contentVersion.VersionData);
    Http http = new Http();
    return http.send(request);
  }

  public class ResponseData {
    @AuraEnabled
    public String organization_id;
    @AuraEnabled
    public String color_scheme;
    @AuraEnabled
    public String language;
    @AuraEnabled
    public String candidate_id;
    @AuraEnabled
    public String candidate_secret;

    public ResponseData() {
    }

    public ResponseData(CVTransformerConfiguration__c config, Contact contact) {
      this.organization_id = config.Name;
      this.color_scheme = config.color_scheme__c;
      this.language = config.language__c;
      this.candidate_id = contact.cvt_id__c;
      this.candidate_secret = contact.cvt_secret__c;
    }
  }
}
