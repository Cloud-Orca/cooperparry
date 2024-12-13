@isTest
public class AccountTriggerHandlerTest {
   
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
    static void onAccountInsert(){
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
            Account newAccount = new Account();
            newAccount.Name = 'test';
            insert newAccount;
        Test.stopTest();
    }

    @isTest
    static void onAccountUpdate(){
        Account newAccount = new Account();
        newAccount.Name = 'test';
        newAccount.Source__c = 'Inbound';
        newAccount.Source_Type__c = 'Website';
        insert newAccount;

        AccountTeamMember accTeamMember = new AccountTeamMember();
        accTeamMember.UserId = UserInfo.getUserId();
        accTeamMember.AccountId = newAccount.Id;
        insert accTeamMember;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='testusernamexyz@asdsad.dsadsaa', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testusernamexyz@asdsad.dsadsaa');
        insert u;

        Test.startTest();
            newAccount.OwnerId = u.Id;
            update newAccount;
        Test.stopTest();
    }
}