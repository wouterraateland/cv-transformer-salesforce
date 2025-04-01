@isTest
global class CVTransformerApiMock implements HttpCalloutMock {
  public Integer statusCode = 200;

  global HTTPResponse respond(HTTPRequest req) {
    String candidate = '{"id":"12345","organization_id":"123","secret_editable":"true","attachments":{}}';
    String organization = '{"id":"12345","name":"Sample Name","avatar":"Sample Avatar"}';

    HttpResponse res = new HttpResponse();
    res.setStatusCode(this.statusCode);
    if (req.getEndpoint().contains('/organizations'))
      res.setBody('[' + organization + ']');
    else if (req.getEndpoint().contains('/extract'))
      res.setBody(
        '{' +
          '  "birthdate": "1992-01-20",' +
          '  "email": "Mark@Williams.com",' +
          '  "first_name": "Mark",' +
          '  "last_name": "Williams",' +
          '  "phone": "01 234 567 89",' +
          '  "title": "Senior specialist IT-ondersteuning"' +
          '}'
      );
    else if (req.getEndpoint().contains('/candidates?id=eq.'))
      res.setBody('[' + candidate + ']');
    else if (req.getEndpoint().contains('/candidates/'))
      res.setBody('');
    else if (req.getEndpoint().contains('/candidates'))
      res.setBody(candidate);

    return res;
  }
}
