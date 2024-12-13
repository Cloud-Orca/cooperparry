@isTest
private class CaseTriggerHandlerTest {
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
    }

    @isTest
    static void onCaseInsert(){
        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse newFolderError = new HttpResponse();
        newFolderError.setStatusCode(401);
        newFolderError.setBody('{"message": "sample"}');
        mock.addResponse(newFolderError);

        HttpResponse getToken = new HttpResponse();
        getToken.setStatusCode(200);
        getToken.setBody('{"access_token": "1234343"}');
        mock.addResponse(getToken);

        HttpResponse newFolderOK = new HttpResponse();
        newFolderOK.setStatusCode(200);
        newFolderOK.setBody('{"id": "65454534"}');
        mock.addResponse(newFolderOK);

        HttpResponse publicFolder = new HttpResponse();
        publicFolder.setStatusCode(200);
        publicFolder.setBody('{"id": "65454534", "webUrl": "https://test.sharepoint.com/sites/rfdfdf"}');
        mock.addResponse(publicFolder);

        HttpResponse secureFolder = new HttpResponse();
        secureFolder.setStatusCode(200);
        secureFolder.setBody('{"id": "3434343", "webUrl": "https://test.sharepoint.com/sites/fdjdfksd"}');
        mock.addResponse(secureFolder);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Case cas = new Case();
            cas.Subject = 'Test';
            insert cas;
        Test.stopTest();
    }


}