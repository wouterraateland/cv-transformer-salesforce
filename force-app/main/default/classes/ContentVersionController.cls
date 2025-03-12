public with sharing class ContentVersionController {
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
}
