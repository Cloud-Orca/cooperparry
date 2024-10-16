public class SmartSearchAPIUtility {
    
    public static HttpResponse getAccessToken(){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/auth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', 'application/vnd.api+json');

        String body = '{"data":{"type":"app-token","attributes":{"app_id":"' + smartSearchSetting.app_id__c + '","secret":"' + smartSearchSetting.secret__c + '"}}}';
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse postSearchSubject(String accessToken, String firstName, String middleName, String lastName){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/watchlist/searches');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        String body = '{"data":{"type":"watchlist-only-individual","attributes":{"name":{"first":"' + firstName + '","middle":"' + middleName + '","last":"' + lastName + '"}}}}';
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse getWatchList(String accessToken, String searchSubjectId){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/watchlist/subjects/' + searchSubjectId);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

}