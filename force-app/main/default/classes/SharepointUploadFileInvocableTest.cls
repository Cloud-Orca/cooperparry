@isTest
public class SharepointUploadFileInvocableTest {

    public class API_UploadFile_ResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        public API_UploadFile_ResponseMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest request) {
            System.debug('ENDPOINT: ' + request.getEndPoint());
            String  insertBody = '{"id":"asdasd", "webUrl": "adasdaasd"}';
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(insertBody);
            response.setStatus('OK');
            response.setStatusCode(this.statusCode);
            System.debug('response::' + response);
            return response;
        }
    }

    @TestSetup
    static void makeData(){
        Sharepoint_Setting__c sett = new Sharepoint_Setting__c();
        sett.tenant_identifier__c = '123';
        sett.client_id__c = '1234';
        sett.client_secret__c = '1rdedw';
        sett.drive_id__c = '12323';
        insert sett;

        Sharepoint_API__c api = new Sharepoint_API__c();
        api.access_token__c = '123';
        insert api;

        Account newAccount = new Account();
        newAccount.Name = 'test';
        newAccount.Sharepoint_Folder_ID__c = 'asdadasdas';
        newAccount.Sharepoint_Secure_Folder_ID__c = 'asdadasdas';
        insert newAccount;

        Case cas = new Case();
        cas.Subject = 'Test';
        cas.Sharepoint_Folder_ID__c = 'asdadasdas';
        cas.Sharepoint_Secure_Folder_ID__c = 'asdadasdas';
        insert cas;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'test.pdf';
        cv.VersionData = Blob.valueOf('testpdf');
        cv.PathOnClient ='test.pdf';
        cv.ContentLocation = 'S';
        cv.SharingOption = 'A';
        cv.Origin = 'C';
        insert cv;
    }

    @isTest static void testMethodUploadFileFromDriveId(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_UploadFile_ResponseMock(200));

        List<String> fileIds = new List<String>{cvId};

        SharepointUploadFileInvocable.RequestPublicFlowParam req = new SharepointUploadFileInvocable.RequestPublicFlowParam();
        req.fileIds = fileIds;
        req.caseId = caseId;
        List<SharepointUploadFileInvocable.RequestPublicFlowParam> reqParam = new List<SharepointUploadFileInvocable.RequestPublicFlowParam>{req};
        SharepointUploadFileInvocable.uploadFileToSharepoint(reqParam);

        test.stopTest();
    }
}