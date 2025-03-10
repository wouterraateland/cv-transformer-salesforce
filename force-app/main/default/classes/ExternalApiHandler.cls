public with sharing class CVTransformerApiHandler {
  @AuraEnabled
  public static void sendDataToApi(Id contactId) {
    Contact contact = [
      SELECT Id, Name, Email
      FROM Contact
      WHERE Id = :contactId
      LIMIT 1
    ];

    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:CV_Transformer/sendData');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setBody(JSON.serialize(contact));

    HttpResponse response = http.send(request);

    if (response.getStatusCode() != 200) {
      throw new ApexException('Error calling API: ' + response.getBody());
    }
  }
}
