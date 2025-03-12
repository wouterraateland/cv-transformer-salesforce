@isTest
global class CVTransformerApiMock implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
    String candidate = '{"id":"12345","organization_id":"123","secret_editable":"true","attachments":{}}';
    String organization = '{"id":"12345","name":"Sample Name","avatar":"Sample Avatar"}';

    HttpResponse res = new HttpResponse();
    res.setStatusCode(200);
    if (req.getEndpoint().contains('/organizations'))
      res.setBody('[' + organization + ']');
    else if (req.getEndpoint().contains('/candidates?id=eq.'))
      res.setBody('[' + candidate + ']');
    else if (req.getEndpoint().contains('/candidates/'))
      res.setBody('');
    else if (req.getEndpoint().contains('/candidates'))
      res.setBody(candidate);

    return res;
  }
}
