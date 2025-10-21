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

  private static Set<String> blacklistedFields = new Set<String>{
    'Accepts_Floats__c',
    'AccountId',
    'Ambition_Record_Type_Banner__c',
    'AmbTech_Candidate__c',
    'Candidate_Cleared__c',
    'CreatedById',
    'CreatedDate',
    'CVTransformer__cvt_id__c',
    'CVTransformer__cvt_secret__c',
    'Dashboard_Access__c',
    'Disable_Hot_Boss__c',
    'DoNotCall',
    'et4ae5__HasOptedOutOfMobile__c',
    'Group_Office__c',
    'HasOptedOutOfEmail',
    'HomePhone',
    'Hot_Boss__c',
    'IsDeleted',
    'IsEmailBounced',
    'IsPriorityRecord',
    'LastModifiedById',
    'LastModifiedDate',
    'LastReferencedDate',
    'LastViewedDate',
    'MailingAddress',
    'MobilePhone',
    'Opted_In_SMS_Message__c',
    'Opted_Out_Marketing_Emails__c',
    'OtherAddress',
    'OtherPhone',
    'Phone',
    'PhotoUrl',
    'Record_Type_Name',
    'RecordTypeId',
    'seven20__Account__c',
    'seven20__Candidate__c',
    'seven20__Candidate_Source_Detail__c',
    'seven20__Candidate_Status__c',
    'seven20__Created_via_Daxtra__c',
    'seven20__CV_File_Id__c',
    'seven20__CV_File_Name__c',
    'seven20__Full_CV__c',
    'seven20__Is_Indexed_on_Daxtra__c',
    'seven20__Job__c',
    'seven20__Job_ATS__c',
    'seven20__Job_Board_Id__c',
    'seven20__Job_Board_Id__c',
    'seven20__Parser_Status__c',
    'seven20__Record_Type_Name__c',
    'seven20__Sync_Status__c',
    'Status_Icon__c',
    'SystemModstamp',
    'Temp_Traitor__c',
    'Temp_Traitor_Client__c',
    'To_Archive__c',
    'Traitor__c',
    'tubl__TextUs_Indexed_Phone_3__c',
    'tubl__TextUs_Indexed_Phone_5__c',
    'tubl__TextUs_Phone__c'
  };

  public static Set<String> relevantChildRelationships = new Set<String>{
    'seven20__Accounts__r',
    'seven20__Applications__r',
    'seven20__Candidate_Shifts__r',
    'seven20__Compliances__r',
    'seven20__Contacts__r',
    'seven20__Education_History__r',
    'seven20__Employment_History__r',
    'seven20__Interviews__r',
    'seven20__Job_Board_Applications__r',
    'seven20__Job_Leads__r',
    'seven20__Jobs__r',
    'seven20__Placements__r',
    'seven20__References__r',
    'seven20__Relationships__r'
  };

  public static String atsInfer() {
    return contactFields.contains('seven20__cv_file_id__c')
      ? 'Seven20'
      : contactFields.contains('msf__Place_of_birth__c')
          ? 'MySolution'
          : 'Salesforce';
  }

  public class ContactPageData {
    @AuraEnabled
    public String ats;
    @AuraEnabled
    public String candidate_id;
    @AuraEnabled
    public String candidate_secret;
    @AuraEnabled
    public String organization_id;

    public ContactPageData() {
      this.ats = CVTransformerApi.atsInfer();
    }

    public ContactPageData(
      CVTransformerConfiguration__c config,
      Contact contact
    ) {
      this.ats = CVTransformerApi.atsInfer();
      this.candidate_id = contact.cvt_id__c;
      this.candidate_secret = contact.cvt_secret__c;
      this.organization_id = config.Name;
    }
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

  public static String fieldnameNormalize(String fieldname) {
    if (fieldname.startsWith('seven20__'))
      fieldname = fieldname.substring(9);
    if (fieldname.endsWith('__c'))
      fieldname = fieldname.substring(0, fieldname.length() - 3);
    if (fieldname.endsWith('__r'))
      fieldname = fieldname.substring(0, fieldname.length() - 3);
    return fieldname;
  }

  public static Set<String> blacklistApply(Set<String> fields) {
    Set<String> lowercaseBlacklistedFields = new Set<String>();
    for (String field : blacklistedFields)
      lowercaseBlacklistedFields.add(field.toLowerCase());
    Set<String> result = new Set<String>();
    for (String field : fields)
      if (!lowercaseBlacklistedFields.contains(field.toLowerCase()))
        result.add(field);

    return result;
  }

  public static String mimeTypeInfer(String fileType) {
    Map<String, String> mimeMap = new Map<String, String>{
      'DOC' => 'application/msword',
      'WORD' => 'application/msword',
      'DOCX' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'WORD_X' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'JPG' => 'image/jpeg',
      'JPEG' => 'image/jpeg',
      'PDF' => 'application/pdf',
      'PNG' => 'image/png',
      'WEBP' => 'image/webp',
      'TXT' => 'text/plain',
      'TEXT' => 'text/plain'
    };
    return mimeMap.containsKey(fileType)
      ? mimeMap.get(fileType)
      : 'application/octet-stream';
  }

  private static String nsPrefix(String baseName) {
    return 'CVTransformer__' + baseName; // Production
    // return baseName; // Development
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
    request.setHeader('Content-Type', mimeTypeInfer(contentVersion.FileType));
    request.setHeader(
      'Content-Disposition',
      'attachment; filename="' + contentVersion.Title + '"'
    );
    request.setBodyAsBlob(contentVersion.VersionData);
    Http http = new Http();
    return http.send(request);
  }

  @AuraEnabled(cacheable=true)
  public static String organizationIdGet() {
    List<CVTransformerConfiguration__c> configs = [
      SELECT Name, api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (configs.isEmpty())
      return null;
    return configs[0].Name;
  }

  @AuraEnabled(cacheable=true)
  public static ContactPageData contactDataGet(Id contact_id) {
    List<CVTransformerConfiguration__c> configs = [
      SELECT Name, api_key__c
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
  public static String candidateContextGet(Id contact_id) {
    SObject contactObject = Database.query(
      'SELECT ' +
        String.join(new List<String>(blacklistApply(contactFields)), ',') +
        ' FROM Contact WHERE Id = :contact_id'
    );
    Map<String, Object> contactData = contactObject.getPopulatedFieldsAsMap();

    Map<String, Object> data = new Map<String, Object>();
    for (String key : contactData.keySet())
      data.put(fieldnameNormalize(key), contactData.get(key));

    String phone = (String) contactData.get('MobilePhone');
    if (phone == null)
      phone = (String) contactData.get('OtherPhone');
    if (phone == null)
      phone = (String) contactData.get('HomePhone');
    if (phone == null)
      phone = (String) contactData.get('Phone');
    data.put('Phone', phone);

    List<Schema.ChildRelationship> contactChildRelationships = Schema.getGlobalDescribe()
      .get('Contact')
      .getDescribe()
      .getChildRelationships();

    for (Schema.ChildRelationship cr : contactChildRelationships) {
      String relName = cr.getRelationshipName();
      if (!relevantChildRelationships.contains(relName))
        continue;

      Schema.DescribeSObjectResult childDescription = cr.getChildSObject()
        .getDescribe();
      Set<String> childFields = blacklistApply(
        childDescription.fields.getMap().keySet()
      );

      List<SObject> childRecords = Database.query(
        'SELECT ' +
          String.join(new List<String>(childFields), ',') +
          ' FROM ' +
          childDescription.getName() +
          ' WHERE ' +
          cr.getField().getDescribe().getName() +
          ' = :contact_id'
      );
      List<Map<String, Object>> result = new List<Map<String, Object>>();
      for (SObject rec : childRecords) {
        Map<String, Object> recData = new Map<String, Object>();
        Map<String, Object> recPopulatedFields = rec.getPopulatedFieldsAsMap();
        for (String key : recPopulatedFields.keySet())
          recData.put(fieldnameNormalize(key), recPopulatedFields.get(key));

        result.add(recData);
      }

      data.put(fieldnameNormalize(relName), result);
    }

    return JSON.serialize(data);
  }

  @AuraEnabled(cacheable=true)
  public static String candidateAttachmentsList(Id contact_id) {
    List<Map<String, String>> attachments = new List<Map<String, String>>();

    List<ContentDocumentLink> cdls = (contentVersionFields.contains(
        'seven20__file_type__c'
      ))
      ? Database.query(
          'SELECT ' +
            'ContentDocument.LatestPublishedVersion.Id, ' +
            'ContentDocument.LatestPublishedVersion.Title ' +
            'FROM ContentDocumentLink ' +
            'WHERE ContentDocument.LatestPublishedVersion.seven20__file_type__c IN (\'CV\', \'CV (Parser)\', \'CV (PDF Converted)\') ' +
            'AND LinkedEntityId = :contact_id'
        )
      : [
          SELECT
            ContentDocument.LatestPublishedVersion.Id,
            ContentDocument.LatestPublishedVersion.Title
          FROM ContentDocumentLink
          WHERE LinkedEntityId = :contact_id
        ];

    for (ContentDocumentLink cdl : cdls) {
      ContentVersion cv = cdl.ContentDocument.LatestPublishedVersion;
      Map<String, String> attachment = new Map<String, String>();
      attachment.put('id', cv.Id);
      attachment.put('title', cv.Title);
      attachment.put('type', 'Salesforce');
      attachments.add(attachment);
    }

    if (contactFields.contains('seven20__cv_file_id__c')) {
      List<SObject> rels = Database.query(
        'SELECT ' +
          'seven20__External_Id__c, seven20__File_Name__c ' +
          'FROM seven20__Document__c ' +
          'WHERE seven20__Type__c IN (\'CV\', \'CV (Parser)\', \'CV (PDF Converted)\')' +
          'AND Id IN (' +
          'SELECT seven20__Document__c ' +
          'FROM seven20__Document_Relationship__c ' +
          'WHERE seven20__Contact__c = :contact_id)'
      );

      for (SObject rel : rels) {
        Map<String, String> attachment = new Map<String, String>();
        attachment.put('id', (String) rel.get('seven20__External_Id__c'));
        attachment.put('title', (String) rel.get('seven20__File_Name__c'));
        attachment.put('type', 'Seven20AWS');
        attachments.add(attachment);
      }
    }

    return JSON.serialize(attachments);
  }

  @AuraEnabled
  public static Map<String, String> contentVersionDataGet(
    Id content_version_id
  ) {
    ContentVersion cv = [
      SELECT FileExtension, Title, VersionData
      FROM ContentVersion
      WHERE Id = :content_version_id
      LIMIT 1
    ];
    Map<String, String> data = new Map<String, String>();
    data.put('base64', EncodingUtil.base64Encode(cv.VersionData));
    data.put('extension', cv.FileExtension);
    data.put('title', cv.Title);
    return data;
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
  public static String contactCreate(
    Id content_document_id,
    Id content_version_id
  ) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c
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
      SELECT Name, api_key__c
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

    CVTransformerCandidate candidate = candidateCreate(config.api_key__c);

    contact.cvt_id__c = candidate.id;
    contact.cvt_secret__c = candidate.secret_editable;

    update contact;

    return new ContactPageData(config, contact);
  }

  @AuraEnabled
  public static ContactPageData candidateLink(
    Id contact_id,
    String candidate_id
  ) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c
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
  public static String candidateExportCV(Id contact_id, String export_type) {
    CVTransformerConfiguration__c config = [
      SELECT Name, api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    Contact contact = contactFields.contains('seven20__cv_file_id__c')
      ? Database.query(
          'SELECT' +
            '	cvt_id__c, cvt_secret__c, seven20__cv_file_id__c' +
            ' FROM Contact WHERE Id = :contact_id'
        )
      : [
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

    String fileName = '';
    for (String part : contentDisposition.split(';')) {
      part = part.trim();

      if (part.contains('filename*=')) {
        part = part.replaceAll('filename\\*=', '');
        List<String> subparts = part.split('\'\'');
        if (subparts.size() == 2)
          fileName = EncodingUtil.urlDecode(subparts[1], subparts[0]);
      }

      if (part.contains('filename=') && fileName == '')
        fileName = part.replaceAll('filename=', '').replaceAll('"', '').trim();
    }

    Blob fileBody = response.getBodyAsBlob();

    // Step 1: Insert ContentVersion
    ContentVersion contentVersion = new ContentVersion();
    contentVersion.Title = fileName.replaceAll('\\.pdf$', '');
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
      contactFields.contains('seven20__cv_file_id__c') &&
      contact.get('seven20__cv_file_id__c') == null
    ) {
      contact.put('seven20__cv_file_id__c', contentDoc.Id);
      update contact;
    }

    return 'Ok';
  }
}
