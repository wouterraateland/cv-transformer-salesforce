@isTest
global class CVTransformerApiMock implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
    return new HttpResponse();
  }
}
