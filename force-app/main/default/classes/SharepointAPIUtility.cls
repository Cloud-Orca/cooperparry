public class SharepointAPIUtility {

    public static HttpResponse getAccessToken(){
        Sharepoint_Setting__c sharepointSetting = Sharepoint_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint('https://login.microsoftonline.com/' + sharepointSetting.tenant_identifier__c + '.onmicrosoft.com/oauth2/v2.0/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/x-www-form-urlencoded');
        req.setHeader('Host', 'login.microsoftonline.com:443');

        String clientId = sharepointSetting.client_id__c;
        String scope = 'https://graph.microsoft.com/.default';
        String clientSecret = sharepointSetting.client_secret__c;
        String grantType = 'client_credentials';

        String body = 'client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
            '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
            '&grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse getChildrenFromDriveItemId(String accessToken, String driveItemId){
        Sharepoint_Setting__c sharepointSetting = Sharepoint_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://graph.microsoft.com/v1.0/drives/' + sharepointSetting.drive_id__c + '/items/' + driveItemId + '/children');
        req.setMethod('GET');
        req.setHeader('Accept', '*/*');
        req.setHeader('Content-Type', 'application/json;');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        System.debug('@@@ req getEndpoint: ' + req.getEndpoint());
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse uploadFileToDriveItem(String accessToken, String driveItemId, String fileName, Blob fileBody){
        Sharepoint_Setting__c sharepointSetting = Sharepoint_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        String encodedPath =  ':/' + fileName + ':/content';
        encodedPath = EncodingUtil.urlEncode(encodedPath, 'UTF-8').replace('+', '%20');

        req.setEndpoint('https://graph.microsoft.com/v1.0/drives/' + sharepointSetting.drive_id__c + '/items/' + driveItemId + encodedPath);

        req.setMethod('PUT');
        req.setHeader('Accept', '*/*');
        req.setHeader('Content-Type', 'application/json;');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setBodyAsBlob(fileBody);

        System.debug('@@@ req getEndpoint: ' + req.getEndpoint());
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse createNewFolderFromDriveId(String accessToken, String driveItemId, String folderName){
        Sharepoint_Setting__c sharepointSetting = Sharepoint_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://graph.microsoft.com/v1.0/drives/' + sharepointSetting.drive_id__c + '/items/' + driveItemId + '/children');
        req.setMethod('POST');
        req.setHeader('Accept', '*/*');
        req.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        String body = '{"name":"'+ folderName +'","folder":{},"@microsoft.graph.conflictBehavior":"rename"}';
        req.setBody(body);

        System.debug('@@@ req getEndpoint: ' + req.getEndpoint());
        System.debug('@@@ req getBody: ' + req.getBody());
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse createNewFolderFromParentDocument(String accessToken, String folderName){
        Sharepoint_Setting__c sharepointSetting = Sharepoint_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();

        String encodedPath =  '/root/children';
        encodedPath = EncodingUtil.urlEncode(encodedPath, 'UTF-8').replace('+', '%20');
        req.setEndpoint('https://graph.microsoft.com/v1.0/drives/' + sharepointSetting.drive_id__c + encodedPath);
        
        req.setMethod('POST');
        req.setHeader('Accept', '*/*');
        req.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        String body = '{"name":"'+ folderName +'","folder":{},"@microsoft.graph.conflictBehavior":"rename"}';
        req.setBody(body);

        System.debug('@@@ req getEndpoint: ' + req.getEndpoint());
        System.debug('@@@ req getBody: ' + req.getBody());
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }
}