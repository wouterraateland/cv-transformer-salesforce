Set<string> contentVersionFields = Schema.getGlobalDescribe()
  .get('ContentVersion')
  .getDescribe()
  .fields.getMap()
  .keySet();

ID contact_id = '003gK0000017ZGbQAM';

Contact contact = [
  SELECT
    cvtransformer__cvt_id__c,
    cvtransformer__cvt_secret__c,
    (SELECT ContentDocumentId FROM ContentDocumentLinks)
  FROM Contact
  WHERE Id = :contact_id
  LIMIT 1
];

List<String> contentDocumentIds = new List<String>();
for (ContentDocumentLink cdl : contact.ContentDocumentLinks)
  contentDocumentIds.add('\'' + cdl.ContentDocumentId + '\'');

List<ContentVersion> contentVersions = Database.query(
  'SELECT ' +
    String.join(contentVersionFields, ', ') +
    ' FROM ContentVersion WHERE ContentDocumentId IN (' +
    String.join(contentDocumentIds, ', ') +
    ') AND IsLatest = TRUE'
);

System.debug(contentVersions);
