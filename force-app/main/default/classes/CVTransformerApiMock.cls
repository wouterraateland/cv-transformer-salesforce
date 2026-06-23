@isTest
global class CVTransformerApiMock implements HttpCalloutMock {
  public Integer statusCode = 200;

  global HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setStatusCode(this.statusCode);
    res.setBody('0041t0000000T0TAAA0');
    return res;
  }
}
