@isTest
global class CVTransformerApiMock implements HttpCalloutMock {
  public Integer statusCode = 200;
  public String first_name = 'Mark';
  public String last_name = 'Williams';
  public String email = 'mark@williams.com';
  public Boolean extractValid = true;

  global HTTPResponse respond(HTTPRequest req) {
    String candidate = '{"id":"12345","organization_id":"123","secret_editable":"true","attachments":{}}';
    String organization = '{"id":"12345","name":"Sample Name","avatar":"Sample Avatar"}';

    HttpResponse res = new HttpResponse();
    res.setStatusCode(this.statusCode);
    if (req.getEndpoint().contains('/organizations'))
      res.setBody('[' + organization + ']');
    else if (req.getEndpoint().contains('/extract'))
      if (this.extractValid)
        res.setBody(
          '{' +
            '  "birthdate": "1992-01-20",' +
            '  "email": "' +
            this.email +
            '",' +
            '  "first_name": "' +
            this.first_name +
            '",' +
            '  "last_name": "' +
            this.last_name +
            '",' +
            '  "phone": "01 234 567 89",' +
            '  "title": "Senior specialist IT-ondersteuning"' +
            '}'
        );
      else
        res.setBody('[{ "invalid_json": "invalid_value"]');
    else if (req.getEndpoint().contains('/candidates?id=eq.'))
      res.setBody('[' + candidate + ']');
    else if (req.getEndpoint().contains('/candidates/'))
      res.setBody('');
    else if (req.getEndpoint().contains('/candidates'))
      res.setBody(candidate);

    return res;
  }
}
