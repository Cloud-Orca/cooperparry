@isTest
public class SharepointCompContTest {

    public class API_GetDriveItem_ResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        public API_GetDriveItem_ResponseMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest request) {
            System.debug('ENDPOINT: ' + request.getEndPoint());
            String  insertBody = '{"@odata.context":"https://graph.microsoft.com/v1.0/$metadata#Collection(driveItem)","value":[{"createdBy":{"application":{"id":"31c57064-f464-417d-920d-4aea9bb38960","displayName":"CloudOrca Sharepoint GraphAPI"},"user":{"displayName":"SharePoint App"}},"createdDateTime":"2024-11-01T10:09:37Z","id":"01HUYBFMAHLLPI2CFLNJDJMWHHYR2SYRXC","lastModifiedBy":{"application":{"id":"31c57064-f464-417d-920d-4aea9bb38960","displayName":"CloudOrca Sharepoint GraphAPI"},"user":{"displayName":"SharePoint App"}},"lastModifiedDateTime":"2024-11-01T10:09:37Z","name":"YHRF - Onboarding","parentReference":{"driveType":"documentLibrary","driveId":"b!fY0371Sv8kmO0vxnKJhvyx3crZosJA1PiP4ZFuc05xtBMdMD10c1Sp4r2o3gJFXT","id":"01HUYBFMFRGPY6D6BFZNAY4FOL3TIPYI3B","name":"YHRF - PanAgora Asset Management","path":"/drives/b!fY0371Sv8kmO0vxnKJhvyx3crZosJA1PiP4ZFuc05xtBMdMD10c1Sp4r2o3gJFXT/root:/YHRF - PanAgora Asset Management","siteId":"ef378d7d-af54-49f2-8ed2-fc6728986fcb"},"webUrl":"https://qqpx.sharepoint.com/sites/CloudOrca/Shared%20Documents/YHRF%20-%20PanAgora%20Asset%20Management/YHRF%20-%20Onboarding","fileSystemInfo":{"createdDateTime":"2024-11-01T10:09:37Z","lastModifiedDateTime":"2024-11-01T10:09:37Z"},"folder":{"childCount":8},"shared":{"scope":"users"},"size":1255070}]}';
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(insertBody);
            response.setStatus('OK');
            response.setStatusCode(this.statusCode);
            System.debug('response::' + response);
            return response;
        }
    }   

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
        insert newAccount;

        Case cas = new Case();
        cas.Subject = 'Test';
        cas.Sharepoint_Folder_ID__c = 'asdadasdas';
        insert cas;
    }

    @isTest static void testMethodLoadData(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;

        SharepointCompCont.getDriveItemId(accountId);
        SharepointCompCont.getDriveItemId(caseId);
        SharepointCompCont.getSecurePublicGroup();
    }

    @isTest static void testMethodGetPathDriveItems(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_GetDriveItem_ResponseMock(200));
        SharepointCompCont.getPathDriveItems(accountId);
        test.stopTest();
    }

    @isTest static void testMethodGetPathDriveItemsExpired(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_GetDriveItem_ResponseMock(401));
        SharepointCompCont.getPathDriveItems(accountId);
        test.stopTest();
    }

    @isTest static void testMethodGetChildrenFromDriveId(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_GetDriveItem_ResponseMock(200));
        SharepointCompCont.getChildrenFromDriveId('01HUYBFMAHLLPI2CFLNJDJMWHHYR2SYRXC', accountId);
        test.stopTest();
    }

    @isTest static void testMethodGetChildrenFromDriveIdExpired(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_GetDriveItem_ResponseMock(401));
        SharepointCompCont.getChildrenFromDriveId('01HUYBFMAHLLPI2CFLNJDJMWHHYR2SYRXC', accountId);
        test.stopTest();
    }

    @isTest static void testMethodUploadDocument(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_UploadFile_ResponseMock(200));

        ContentVersion cv = new ContentVersion();
        cv.Title = 'test.pdf';
        cv.VersionData = Blob.valueOf('testpdf');
        cv.PathOnClient ='test.pdf';
        cv.ContentLocation = 'S';
        cv.SharingOption = 'A';
        cv.Origin = 'C';

        SharepointCompCont.FileWrapper fileWrapp = new SharepointCompCont.FileWrapper();
        fileWrapp.filename = 'test.pdf';
        fileWrapp.base64 = 'adasdasdasdasd';

        List<SharepointCompCont.FileWrapper> fileWrappList = new List<SharepointCompCont.FileWrapper>{fileWrapp};
        SharepointCompCont.uploadDocument(accountId, '01HUYBFMAHLLPI2CFLNJDJMWHHYR2SYRXC', JSON.serialize(fileWrappList));
        test.stopTest();
    }

    @isTest static void testMethodUploadDocument2(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_UploadFile_ResponseMock(200));

        ContentVersion cv = new ContentVersion();
        cv.Title = 'test.pdf';
        cv.VersionData = Blob.valueOf('testpdf');
        cv.PathOnClient ='test.pdf';
        cv.ContentLocation = 'S';
        cv.SharingOption = 'A';
        cv.Origin = 'C';

        SharepointCompCont.FileWrapper fileWrapp = new SharepointCompCont.FileWrapper();
        fileWrapp.filename = 'test.pdf';
        fileWrapp.base64 = 'adasdasdasdasd';

        List<SharepointCompCont.FileWrapper> fileWrappList = new List<SharepointCompCont.FileWrapper>{fileWrapp};
        SharepointCompCont.uploadDocument(accountId, null, JSON.serialize(fileWrappList));
        test.stopTest();
    }

    @isTest static void testMethodUploadFileFromDriveId(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_UploadFile_ResponseMock(200));

        ContentVersion cv = new ContentVersion();
        cv.Title = 'test.pdf';
        cv.VersionData = Blob.valueOf('testpdf');
        cv.PathOnClient ='test.pdf';
        cv.ContentLocation = 'S';
        cv.SharingOption = 'A';
        cv.Origin = 'C';

        List<ContentVersion> cvList = new List<ContentVersion>{cv};
        SharepointCompCont.uploadFileFromDriveId('01HUYBFMAHLLPI2CFLNJDJMWHHYR2SYRXC', cvList, accountId);
        test.stopTest();
    }

    @isTest static void testMethodUploadFileFromDriveIdExpired(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_UploadFile_ResponseMock(401));

        ContentVersion cv = new ContentVersion();
        cv.Title = 'test.pdf';
        cv.VersionData = Blob.valueOf('testpdf');
        cv.PathOnClient ='test.pdf';
        cv.ContentLocation = 'S';
        cv.SharingOption = 'A';
        cv.Origin = 'C';
        List<ContentVersion> cvList = new List<ContentVersion>{cv};
        SharepointCompCont.uploadFileFromDriveId('01HUYBFMAHLLPI2CFLNJDJMWHHYR2SYRXC', cvList, accountId);
        test.stopTest();
    }

}