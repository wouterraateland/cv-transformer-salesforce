public with sharing class CVTransformerApi {
  public class CVTransformerOrganization {
    public String id;
    public String avatar;
    public String name;
  }

  public class CVTransformerCandidateAttachment {
    public Map<String, String> text;
    public String type;
    public String url;
  }

  public class CVTransformerCandidate {
    public String id;
    public String organization_id;
    public String secret_editable;
    public String secret;
    public String secret_anonymous;
    public Map<String, CVTransformerCandidateAttachment> attachments;
  }

  private static CVTransformerCandidate candidateGet(
    String api_key,
    String id
  ) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      'callout:' + nsPrefix('API') + '/candidates?id=eq.' + id
    );
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer ' + api_key);

    Http http = new Http();
    HttpResponse response = http.send(request);
    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300)
      throw new AuraHandledException(
        'Could not get candidate: ' + response.getBody()
      );
    String responseBody = response.getBody();
    System.debug('Response: ' + responseBody);

    List<CVTransformerCandidate> candidates = (List<CVTransformerCandidate>) JSON.deserialize(
      responseBody,
      List<CVTransformerCandidate>.class
    );
    return candidates[0];
  }

  private static CVTransformerCandidate candidateCreate(String api_key) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:' + nsPrefix('API') + '/candidates');
    request.setMethod('POST');
    request.setHeader('Authorization', 'Bearer ' + api_key);
    request.setHeader('Content-Type', 'application/json');
    request.setBody('{}');

    Http http = new Http();
    HttpResponse response = http.send(request);
    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300)
      throw new AuraHandledException(
        'Could not create candidate: ' + response.getBody()
      );

    return (CVTransformerCandidate) JSON.deserialize(
      response.getBody(),
      CVTransformerCandidate.class
    );
  }

  public class CandidateSalesforceData {
    public String birthdate = '';
    public String email = '';
    public String first_name = '';
    public String last_name = '';
    public String phone = '';
    public String title = '';

    public CandidateSalesforceData() {
    }
  }

  private static CandidateSalesforceData candidateExtract(
    String api_key,
    String candidate_id
  ) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      'callout:' + nsPrefix('API') + '/candidates/' + candidate_id + '/extract'
    );
    request.setMethod('POST');
    request.setHeader('Authorization', 'Bearer ' + api_key);
    request.setHeader('Content-Type', 'application/json');
    request.setBody(
      '{' +
        '  "type": "object",' +
        '  "properties": {' +
        '    "birthdate": {' +
        '      "description": "Format as YYYY-MM-DD.",' +
        '      "format": "date",' +
        '      "type": "string"' +
        '    },' +
        '    "email": { "type": "string" },' +
        '    "first_name": { "type": "string" },' +
        '    "last_name": { "type": "string" },' +
        '    "phone": { "type": "string" },' +
        '    "title": { "type": "string" }' +
        '  },' +
        '  "additionalProperties": false,' +
        '  "$schema": "http://json-schema.org/draft-07/schema#"' +
        '}'
    );

    Http http = new Http();
    HttpResponse response = http.send(request);

    try {
      return (CandidateSalesforceData) JSON.deserialize(
        response.getBody(),
        CandidateSalesforceData.class
      );
    } catch (Exception e) {
      System.debug('Error deserializing response: ' + e.getMessage());
      return new CandidateSalesforceData();
    }
  }

  public static Date stringToDate(String dateString) {
    if (String.isBlank(dateString))
      return null;
    try {
      return Date.valueOf(dateString);
    } catch (Exception e) {
      System.debug('Invalid date format: ' + dateString);
      return null;
    }
  }

  public class UtilPageData {
    @AuraEnabled
    public String organization_id;
    @AuraEnabled
    public String color_scheme;
    @AuraEnabled
    public String language;

    public UtilPageData() {
    }

    public UtilPageData(CVTransformerConfiguration__c config) {
      this.organization_id = config.Name;
      this.color_scheme = config.color_scheme__c;
      this.language = config.language__c;
    }
  }

  public class ContactPageData {
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

    public ContactPageData() {
    }

    public ContactPageData(
      CVTransformerConfiguration__c config,
      Contact contact
    ) {
      this.organization_id = config.Name;
      this.color_scheme = config.color_scheme__c;
      this.language = config.language__c;
      this.candidate_id = contact.cvt_id__c;
      this.candidate_secret = contact.cvt_secret__c;
    }
  }

  private static Set<String> listObjectFields(String objectName) {
    return new Set<String>(
      Schema.getGlobalDescribe()
        .get(objectName)
        .getDescribe()
        .fields.getMap()
        .keySet()
    );
  }

  public static Set<String> contactFields = listObjectFields('Contact');
  public static Set<String> contentVersionFields = listObjectFields(
    'ContentVersion'
  );

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

  private static String nsPrefix(String baseName) {
    return 'CVTransformer__' + baseName; // Production
    // return baseName; // Development
  }

  private static HttpResponse attach(
    String api_key,
    String candidate_id,
    String location,
    ContentVersion contentVersion
  ) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      'callout:' +
        nsPrefix('API') +
        '/candidates/' +
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

  @AuraEnabled(cacheable=true)
  public static UtilPageData utilDataGet() {
    List<CVTransformerConfiguration__c> configs = [
      SELECT Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configs.isEmpty())
      return new UtilPageData();
    CVTransformerConfiguration__c config = configs[0];

    return new UtilPageData(config);
  }

  @AuraEnabled(cacheable=true)
  public static ContactPageData contactDataGet(Id contact_id) {
    List<CVTransformerConfiguration__c> configs = [
      SELECT Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configs.isEmpty())
      return new ContactPageData();
    CVTransformerConfiguration__c config = configs[0];
    Contact contact = [
      SELECT cvt_id__c, cvt_secret__c
      FROM Contact
      WHERE Id = :contact_id
      LIMIT 1
    ];

    return new ContactPageData(config, contact);
  }

  @AuraEnabled(cacheable=true)
  public static List<ContentVersion> getRelatedContentVersions(Id recordId) {
    List<ContentDocumentLink> contentDocumentLinks = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId
    ];
    List<String> contentDocumentIds = new List<String>();
    for (ContentDocumentLink cdl : contentDocumentLinks)
      contentDocumentIds.add(cdl.ContentDocumentId);

    return [
      SELECT Id, Title
      FROM ContentVersion
      WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE
    ];
  }

  @AuraEnabled
  public static String configUpsert(String api_key) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:' + nsPrefix('API') + '/organizations');
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
  public static String contactCreate(
    Id content_document_id,
    Id content_version_id
  ) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c, color_scheme__c, language__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    ContentVersion contentVersion = [
      SELECT ContentDocumentId, FileType, PathOnClient, Title, VersionData
      FROM ContentVersion
      WHERE Id = :content_version_id
      LIMIT 1
    ];

    // Create new candidate in CVTransformer
    CVTransformerCandidate candidate = candidateCreate(config.api_key__c);
    // Attach the document to the candidate
    attach(config.api_key__c, candidate.id, 'cv', contentVersion);

    CandidateSalesforceData data = candidateExtract(
      config.api_key__c,
      candidate.id
    );

    // Create new contact in Salesforce
    Contact contact = new Contact();
    contact.Birthdate = stringToDate(data.birthdate);
    contact.Email = data.email;
    contact.FirstName = data.first_name;
    contact.LastName = String.isBlank(data.last_name)
      ? 'Unknown'
      : data.last_name;
    contact.Phone = data.phone;
    contact.Title = data.title;
    contact.cvt_id__c = candidate.id;
    contact.cvt_secret__c = candidate.secret_editable;

    try {
      if (contactFields.contains('seven20__cv_file_id__c'))
        contact.put('seven20__cv_file_id__c', content_document_id);
      insert contact;
    } catch (DmlException e) {
      throw new AuraHandledException('Could not create contact: Duplicate');
    }

    ContentDocumentLink contentLink = new ContentDocumentLink();
    contentLink.ContentDocumentId = content_document_id;
    contentLink.LinkedEntityId = contact.Id;
    contentLink.ShareType = 'V';
    contentLink.Visibility = 'AllUsers';
    insert contentLink;

    if (contentVersionFields.contains('seven20__file_type__c')) {
      ContentVersion newVersion = new ContentVersion();
      newVersion.ContentDocumentId = contentVersion.ContentDocumentId;
      newVersion.PathOnClient = contentVersion.PathOnClient;
      newVersion.Title = contentVersion.Title;
      newVersion.VersionData = contentVersion.VersionData;
      try {
        newVersion.put('seven20__file_type__c', 'CV');
      } catch (Exception e) {
        System.debug('Error setting seven20__file_type__c: ' + e.getMessage());
      }
      insert newVersion;
    }

    return contact.Id;
  }

  @AuraEnabled
  public static ContactPageData contactTransformCv(Id contact_id) {
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

    CVTransformerCandidate candidate = candidateCreate(config.api_key__c);

    contact.cvt_id__c = candidate.id;
    contact.cvt_secret__c = candidate.secret_editable;

    if (!contact.ContentDocumentLinks.isEmpty()) {
      List<String> contentDocumentIds = new List<String>();
      if (contentVersionFields.contains('seven20__file_type__c'))
        for (ContentDocumentLink cdl : contact.ContentDocumentLinks)
          contentDocumentIds.add('\'' + cdl.ContentDocumentId + '\'');
      else
        for (ContentDocumentLink cdl : contact.ContentDocumentLinks)
          contentDocumentIds.add(cdl.ContentDocumentId);
      List<ContentVersion> contentVersions = contentVersionFields.contains(
          'seven20__file_type__c'
        )
        ? Database.query(
            'SELECT ' +
              String.join(contentVersionFields, ', ') +
              ' FROM ContentVersion WHERE ContentDocumentId IN (' +
              String.join(contentDocumentIds, ', ') +
              ') AND IsLatest = TRUE AND seven20__file_type__c = \'CV\''
          )
        : [
            SELECT Id, Title, VersionData, FileType
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE
          ];
      if (!contentVersions.isEmpty()) {
        ContentVersion contentVersion = contentVersions[0];
        if (contentVersion != null)
          attach(config.api_key__c, contact.cvt_id__c, 'cv', contentVersion);
      }
    }

    update contact;

    return new ContactPageData(config, contact);
  }

  @AuraEnabled
  public static ContactPageData candidateLink(
    Id contact_id,
    String candidate_id
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

    return new ContactPageData(config, contact);
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
  public static ContactPageData candidateAttachCV(
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
      SELECT FileType, Title, VersionData
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

    return new ContactPageData(config, contact);
  }

  @AuraEnabled
  public static String candidateExportCV(Id contact_id, String export_type) {
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
    CVTransformerCandidate candidate = candidateGet(
      config.api_key__c,
      contact.cvt_id__c
    );
    if (candidate == null)
      throw new AuraHandledException('Candidate not found');

    HttpRequest request = new HttpRequest();
    request.setEndpoint(
      'callout:' +
        nsPrefix('API') +
        '/candidates/' +
        candidate.id +
        '/pdf?s=' +
        (export_type == 'anonymous'
          ? candidate.secret_anonymous
          : candidate.secret)
    );
    request.setMethod('GET');
    Http http = new Http();
    HttpResponse response = http.send(request);
    if (response.getStatusCode() < 200 || response.getStatusCode() >= 300)
      throw new AuraHandledException(
        'Could not export CV: ' + response.getBody()
      );

    String contentType = response.getHeader('Content-Type');
    String contentDisposition = response.getHeader('Content-Disposition');
    String fileName = contentDisposition.replaceAll('.*filename=', '');
    fileName = fileName.replaceAll('\"', '');
    fileName = fileName.replaceAll(';.*', '');
    Blob fileBody = response.getBodyAsBlob();

    // Step 1: Insert ContentVersion
    ContentVersion contentVersion = new ContentVersion();
    contentVersion.Title = fileName;
    contentVersion.PathOnClient = '/' + fileName;
    contentVersion.VersionData = fileBody;
    contentVersion.IsMajorVersion = true;
    if (contentVersionFields.contains('seven20__file_type__c'))
      contentVersion.put('seven20__file_type__c', 'CV');
    insert contentVersion;

    // Step 2: Get the ContentDocumentId
    ContentDocument contentDoc = [
      SELECT Id
      FROM ContentDocument
      WHERE
        Id IN (
          SELECT ContentDocumentId
          FROM ContentVersion
          WHERE Id = :contentVersion.Id
        )
      LIMIT 1
    ];

    // Step 3: Link ContentDocument to Contact
    ContentDocumentLink contentLink = new ContentDocumentLink();
    contentLink.ContentDocumentId = contentDoc.Id;
    contentLink.LinkedEntityId = contact_id;
    contentLink.ShareType = 'V';
    contentLink.Visibility = 'AllUsers';
    insert contentLink;

    // Step 4: Set Contact.seven20__cv_file_id__c when empty
    if (
      contentVersionFields.contains('seven20__cv_file_id__c') &&
      contact.get('seven20__cv_file_id__c') == null
    ) {
      contact.put('seven20__cv_file_id__c', contentDoc.Id);
      update contact;
    }

    return 'Ok';
  }
}
