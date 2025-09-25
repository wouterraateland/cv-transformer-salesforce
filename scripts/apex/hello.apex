Id contact_id = '000';
List<Map<String, String>> attachments = new List<Map<String, String>>();

List<ContentDocumentLink> cdls = true
  ? Database.query(
      'SELECT ' +
        'ContentDocument.LatestPublishedVersion.FileType, ' +
        'ContentDocument.LatestPublishedVersion.Id, ' +
        'ContentDocument.LatestPublishedVersion.Title ' +
        'FROM ContentDocumentLink ' +
        'WHERE ContentDocument.LatestPublishedVersion.seven20__file_type__c IN (\'CV\', \'CV (Parser)\', \'CV (PDF Converted)\') ' +
        'AND LinkedEntityId = \'' +
        contact_id +
        '\''
    )
  : [
      SELECT
        ContentDocument.LatestPublishedVersion.FileType,
        ContentDocument.LatestPublishedVersion.Id,
        ContentDocument.LatestPublishedVersion.Title
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :contact_id
    ];

for (ContentDocumentLink cdl : cdls) {
  ContentVersion cv = cdl.ContentDocument.LatestPublishedVersion;
  Map<String, String> attachment = new Map<String, String>();
  attachment.put('type', 'SalesforceContentVersion');
  attachment.put('id', cv.Id);
  attachment.put('fileType', cv.FileType);
  attachments.add(attachment);
}

if (true) {
  List<SObject> rels = Database.query(
    'SELECT ' +
      'seven20__External_Id__c, seven20__File_Name__c ' +
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
    attachment.put('type', 'Seven20AWS');
    attachment.put('title', (String) rel.get('seven20__File_Name__c'));
    attachment.put('externalId', (String) rel.get('seven20__External_Id__c'));
    attachments.add(attachment);
  }
}
System.debug(JSON.serializePretty(attachments));
