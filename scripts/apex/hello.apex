Id contact_id = '003e2000008l6myAAA';
List<Map<String, String>> attachments = new List<Map<String, String>>();

List<ContentDocumentLink> cdls = Database.query(
  'SELECT ' +
    'ContentDocument.LatestPublishedVersion.FileType, ' +
    'ContentDocument.LatestPublishedVersion.Id, ' +
    'ContentDocument.LatestPublishedVersion.PathOnClient, ' +
    'ContentDocument.LatestPublishedVersion.Title ' +
    'FROM ContentDocumentLink ' +
    'WHERE ContentDocument.LatestPublishedVersion.seven20__file_type__c IN (\'CV\', \'CV (Parser)\', \'CV (PDF Converted)\') ' +
    'AND LinkedEntityId = \'' +
    contact_id +
    '\''
);

for (ContentDocumentLink cdl : cdls) {
  ContentVersion cv = cdl.ContentDocument.LatestPublishedVersion;
  Map<String, String> attachment = new Map<String, String>();
  attachment.put('fileType', cv.FileType);
  attachment.put('id', cv.Id);
  attachment.put('pathOnClient', cv.PathOnClient);
  attachment.put('title', cv.Title);
  attachment.put('type', 'SalesforceContentVersion');
  attachments.add(attachment);
}

List<SObject> rels = Database.query(
  'SELECT ' +
    'seven20__Download_Name__c, ' +
    'seven20__External_Id__c, ' +
    'seven20__File_Extension__c, ' +
    'seven20__File_Name__c ' +
    'FROM seven20__Document__c ' +
    'WHERE seven20__Type__c IN (\'CV\', \'CV (Parser)\', \'CV (PDF Converted)\')' +
    'AND Id IN (' +
    'SELECT seven20__Document__c ' +
    'FROM seven20__Document_Relationship__c ' +
    'WHERE seven20__Contact__c = \'' +
    contact_id +
    '\')'
);

for (SObject rel : rels) {
  Map<String, String> attachment = new Map<String, String>();
  attachment.put('downloadName', (String) rel.get('seven20__Download_Name__c'));
  attachment.put('externalId', (String) rel.get('seven20__External_Id__c'));
  attachment.put(
    'fileExtension',
    (String) rel.get('seven20__File_Extension__c')
  );
  attachment.put('title', (String) rel.get('seven20__File_Name__c'));
  attachment.put('type', 'Seven20AWS');
  attachments.add(attachment);
}

System.debug(JSON.serializePretty(attachments));
