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

    @isTest
    static void onAccountInsertBH(){
        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse getComp = new HttpResponse();
        getComp.setStatusCode(200);
        getComp.setBody('{"meta":{"total":1,"limit":20,"offset":0,"count":1},"results":[{"id":"4mzwas","basic":{"registered_name":"Proampac London Limited","other_trading_names":[],"website":"https://www.rapuk.com/","ultimate_parent_company":{"name":"Ampac Holding LLC","companies_house_id":""}},"classification":{"top_level_sector_groups":["Industrials","Technology/IP-based businesses"],"top_level_industry_groups":["Supply chain, manufacturing and commerce models"],"buzzwords":[],"latest_stage_of_evolution":"Exited","legal_form":"Private limited with Share Capital"},"contact_information":{"emails":["info@rapuk.com"]},"latest_accounts":{"year_end_date":"2023-12-31","turnover":53030000,"ebitda":7962000,"total_assets":40839000,"number_of_employees":296,"auditor":"MOORE & CO","audit_fees":30000},"historic_accounts":[{"year_end_date":"2023-12-31","turnover":53030000,"ebitda":7962000,"total_assets":40839000,"number_of_employees":296,"auditor":"MOORE & CO","audit_fees":30000},{"year_end_date":"2022-12-31","turnover":46039000,"ebitda":6870000,"total_assets":37110000,"number_of_employees":295,"auditor":"MOORE & CO","audit_fees":45000},{"year_end_date":"2021-12-31","turnover":33384000,"ebitda":4041000,"total_assets":27699000,"number_of_employees":253,"auditor":"MOORE & CO","audit_fees":35000},{"year_end_date":"2020-09-30","turnover":26839000,"ebitda":2163000,"total_assets":21772000,"number_of_employees":254,"auditor":"BDO","audit_fees":46000},{"year_end_date":"2019-09-30","turnover":35227000,"ebitda":2952000,"total_assets":23641000,"number_of_employees":295,"auditor":"BDO","audit_fees":28000}],"directors":[{"people_id":"2jq6qe","name":"Lord Beaver","email":null,"from_date":"2006-06-20","until_date":"2021-01-09","currently_active":false},{"people_id":"bcyfsx","name":"Graham Williams","email":null,"from_date":"1996-04-23","until_date":"2021-01-09","currently_active":false},{"people_id":"dyn8h8","name":"Eric Bradford","email":null,"from_date":"2021-01-09","until_date":null,"currently_active":true},{"people_id":"6k5jb5","name":"Simon Flamank","email":null,"from_date":"1998-04-30","until_date":"2000-03-31","currently_active":false},{"people_id":"pnwr3i","name":"Ekaterina Sharashidze Voskamp","email":null,"from_date":"2015-09-01","until_date":"2021-01-09","currently_active":false},{"people_id":"g9gixb","name":"Gijs-Jan Voskamp","email":null,"from_date":"2014-03-01","until_date":"2021-01-09","currently_active":false},{"people_id":"fhtti7","name":"John McKimmie","email":null,"from_date":"2000-03-29","until_date":"2021-01-09","currently_active":false},{"people_id":"2vbmsn","name":"Tony Prior","email":null,"from_date":"1996-04-23","until_date":"1997-04-18","currently_active":false},{"people_id":"873853","name":"Andrew Drummond","email":null,"from_date":"2008-01-02","until_date":"2021-01-09","currently_active":false},{"people_id":"7khdn9","name":"John Curtis","email":null,"from_date":"2011-06-13","until_date":"2015-08-31","currently_active":false},{"people_id":"fhwsth","name":"David Venus","email":null,"from_date":"1996-04-22","until_date":"1996-04-23","currently_active":false},{"people_id":"wkinpe","name":"Gregory Tucker","email":null,"from_date":"2021-01-09","until_date":null,"currently_active":true},{"people_id":"jmdnq2","name":"Nicholas Pople","email":null,"from_date":"2008-05-22","until_date":"2014-02-28","currently_active":false},{"people_id":"d4yxr9","name":"Sean O\'Brien","email":null,"from_date":"1997-04-17","until_date":"1997-06-30","currently_active":false},{"people_id":"iv787e","name":"Julian Money","email":null,"from_date":"1997-04-18","until_date":"2021-01-09","currently_active":false},{"people_id":"pqx2vk","name":"Katherine Pethick","email":null,"from_date":"1997-04-18","until_date":"2021-01-09","currently_active":false}]}]}');
        mock.addResponse(getComp);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Account newAccount = new Account();
        newAccount.Name = 'test';
        newAccount.Beauhurst_ID__c = '12343';
        insert newAccount;
        Test.stopTest();
    }
}