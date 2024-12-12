@isTest
public with sharing class BeauhurstHttpCalloutMock implements HttpCalloutMock{
    HttpResponse res;
    Map<String, HttpResponse> responseByEndpointOrContent;
    public BeauhurstHttpCalloutMock(HttpResponse r, Map<String, HttpResponse> responseByEndpointOrContent) {
        res = r;
        this.responseByEndpointOrContent = responseByEndpointOrContent;
    }
 
    public HttpResponse respond(HttpRequest req) {
        if (responseByEndpointOrContent == null) {
            return res;
        } else {
            if (responseByEndpointOrContent.containsKey(req.getEndpoint())) {
                return responseByEndpointOrContent.get(req.getEndpoint());
            }
 
            for (String bodyPart : responseByEndpointOrContent.keySet()) {
                if (req.getBody() != null && req.getBody().containsIgnoreCase(bodyPart)) {
                    return responseByEndpointOrContent.get(bodyPart);
                }
            }
 
        }
        return res;
    }
 
    public static void setTestMockResponse(Integer statusCode, String status, String body) {
        setTestMockResponse(statusCode, status, body, null);
    }
 
    public static void setTestMockResponse(Integer statusCode, String status, String body, Map<String, HttpResponse> responseByEndpointOrContent) {
        HttpResponse mockResp = new HttpResponse();
 
        if (statusCode != null) {
            mockResp.setStatusCode(statusCode);
        }
 
        if (status != null) {
            mockResp.setStatus(status);
        }
 
        if (body != null) {
            mockResp.setBody(body);
        }
 
        Test.setMock(HttpCalloutMock.class, new BeauhurstHttpCalloutMock(mockResp, responseByEndpointOrContent));
    }
}