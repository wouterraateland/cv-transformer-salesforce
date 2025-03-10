public with sharing class CVTransformerApi {
  @AuraEnabled(cacheable=true)
  public static CVTransformerConfiguration__c configurationGet(Id contactId) {
    List<CVTransformerConfiguration__c> rows = [
      SELECT api_key__c, name
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];
    if (rows.isEmpty())
      return null;

    return rows[0];
  }

  @AuraEnabled
  public static void candidateCreate(Id contactId) {
    CVTransformerConfiguration__c config = [
      SELECT api_key__c
      FROM CVTransformerConfiguration__c
      LIMIT 1
    ];

    Contact contact = [
      SELECT Id, Name, Email
      FROM Contact
      WHERE Id = :contactId
      LIMIT 1
    ];

    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CV_Transformer/candidates');
    request.setMethod('POST');
    request.setHeader('Authorization', 'Bearer ' + config.api_key__c);
    request.setHeader('Content-Type', 'application/json');
    request.setBody(JSON.serialize(contact));

    Http http = new Http();
    HttpResponse response = http.send(request);

    Integer statusCode = response.getStatusCode();
    if (statusCode < 200 || statusCode >= 300) {
      throw new AuraHandledException(
        'Error calling API: ' + response.getBody()
      );
    }

    CVTransformerCandidate candidate = (CVTransformerCandidate) JSON.deserialize(
      response.getBody(),
      CVTransformerCandidate.class
    );
    contact.cv_transformer_id__c = candidate.id;
    update contact;
  }

  public class CVTransformerCandidate {
    public String id;
  }
}
