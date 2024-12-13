@isTest
public class SmartSearchCompContTest {

    public class API_SearchSubject_ResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        public API_SearchSubject_ResponseMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest request) {
            System.debug('ENDPOINT: ' + request.getEndPoint());
            String insertBody = '{"data":{"type":"watchlist-only-individual","id":"100150702","attributes":{"client_reference":"testreference","rule_adjustments":null,"date_of_birth":"","name":{"title":null,"first":"Boris","middle":"","last":"Johnson"},"address":null},"relationships":{"parent":{"data":{"type":"group","id":"c821801e-ba9c-4f9f-8a74-2532a73205e5"}},"subject":{"data":{"type":"search-subject","id":"a264cbd0-11a5-44fd-9123-410e8f937f48"}},"searched_by":{"data":null},"config":{"data":null},"bundle":{"data":null}},"meta":{"search_type":null,"status":"complete","status_detail":null,"created_at":"2024-12-12T08:35:21+00:00","expires_at":null}},"meta":{"timestamp":"2024-12-12T08:35:20+00:00","duration":2.053,"reference":"d66e5833-ab9f-4b44-8573-a911c278db60","version":"v3.9"},"included":[{"type":"search-subject","id":"a264cbd0-11a5-44fd-9123-410e8f937f48","attributes":{"client_reference":"testreference","subject_type":"individual","name":"Boris Johnson","postcode":null,"watchlist_rule_adjustments":null,"monitoring_status":"disabled","document_last_updated_at":null},"relationships":{"parent":{"data":{"type":"group","id":"c821801e-ba9c-4f9f-8a74-2532a73205e5"}},"watchlist_config":{"data":{"type":"search-config","id":"8b0dfab3-d9c2-41ba-b368-0bc30b6542f6"}}},"meta":{"is_monitoring_enabled":false,"shard":null}},{"type":"group","id":"c821801e-ba9c-4f9f-8a74-2532a73205e5","attributes":{"name":"Cooper Parry Advisory Limited","group_type":"company","status":"active","has_storage":true},"relationships":{"parent":{"data":{"type":"group","id":"9917d289-1c03-4915-850b-e8a439f03127"}},"company":{"data":null}}}]}';
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(insertBody);
            response.setStatus('OK');
            response.setStatusCode(this.statusCode);
            System.debug('response::' + response);
            return response;
        }
    }  

    public class API_GetDocument_ResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        public API_GetDocument_ResponseMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest request) {
            System.debug('ENDPOINT: ' + request.getEndPoint());
            String insertBody = '{"data":{"type":"export","id":"f3c86991-d54c-4ef6-9875-4aec580d3554","attributes":{"base64":"asdasdsad"}},"meta":{"timestamp":"2024-12-12T08:48:24+00:00","duration":2.25,"reference":"f1224f5e-13d8-4739-a701-a0f2c373d22c","version":"v3.9"}}';
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
        Smart_Search_Setting__c sett = new Smart_Search_Setting__c();
        sett.app_id__c = '123';
        sett.base_url__c = '1234';
        sett.high_risk_id__c = '1rdedw';
        sett.secret__c = '12323';
        sett.smart_search_url__c = 'asdadad';
        insert sett;

        Smart_Search_API__c api = new Smart_Search_API__c();
        api.access_token__c = '123';
        insert api;

        Account newAccount = new Account();
        newAccount.Name = 'test';
        insert newAccount;

        Case cas = new Case();
        cas.Subject = 'Test';
        cas.AccountId = newAccount.Id;
        insert cas;

        Beneficial_Owner__c benOwner = new Beneficial_Owner__c();
        benOwner.Account__c = newAccount.Id;
        benOwner.Case__c = cas.Id;
        benOwner.Title__c = 'Mr';
        benOwner.First_Name__c = 'test';
        benOwner.Middle_Name__c = 'test';
        benOwner.Date_of_Birth__c = Date.today().addYears(-30);
        benOwner.Search_Reference__c = 'test';
        benOwner.Flat__c = 'test';
        benOwner.Building_Name_Number__c = 'test';
        benOwner.Address_Line_1__c = 'test';
        benOwner.Address_Line_2__c = 'test';
        benOwner.Town__c = 'test';
        benOwner.County__c = 'test';
        benOwner.Postcode__c = 'asdad';
        benOwner.Years_at_this_address__c = 3;
        benOwner.Months_at_this_address__c = 11;
        insert benOwner;

        Beneficial_Owner_Cases__c benOwnerCases = new Beneficial_Owner_Cases__c();
        benOwnerCases.Beneficial_Owner__c = benOwner.Id;
        benOwnerCases.Case__c = cas.Id;
        insert benOwnerCases;
    }

    @isTest static void testMethodLoadData(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        SmartSearchCompCont.getLifeCycleRole(caseId);
        SmartSearchCompCont.getAllBeneficialOwners(caseId);
        SmartSearchCompCont.getPicklistValues('Beneficial_Owner__c', 'Title__c');
    }

    @isTest static void testMethodPostSearch(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Beneficial_Owner__c benOwner = [SELECT Id, Account__c, Address_Line_1__c, Address_Line_2__c, Building_Name_Number__c, Case__c, County__c, 
                                            Date_of_Birth__c, First_Name__c, Flat__c, Last_Name__c, Middle_Name__c, Months_at_this_address__c, Postcode__c,
                                            Search_ID__c, Search_Reference__c, Smart_Search_Link__c, Smart_Search_Status__c, Subject_ID__c, Title__c, Town__c, 
                                            Years_at_this_address__c FROM Beneficial_Owner__c LIMIT 1];

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_SearchSubject_ResponseMock(200));
        SmartSearchCompCont.searchNameToSmartSearch(caseId, benOwner);
        test.stopTest();
    }

    @isTest static void testMethodGetSummary(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Beneficial_Owner__c benOwner = [SELECT Id, Account__c, Address_Line_1__c, Address_Line_2__c, Building_Name_Number__c, Case__c, County__c, 
                                            Date_of_Birth__c, First_Name__c, Flat__c, Last_Name__c, Middle_Name__c, Months_at_this_address__c, Postcode__c,
                                            Search_ID__c, Search_Reference__c, Smart_Search_Link__c, Smart_Search_Status__c, Subject_ID__c, Title__c, Town__c, 
                                            Years_at_this_address__c FROM Beneficial_Owner__c LIMIT 1];
        benOwner.Search_ID__c = '123123';
        update benOwner;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_SearchSubject_ResponseMock(200));
        SmartSearchCompCont.searchNameToSmartSearch(caseId, benOwner);
        test.stopTest();
    }

    @isTest static void testMethodGetSummaryExpired(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Beneficial_Owner__c benOwner = [SELECT Id, Account__c, Address_Line_1__c, Address_Line_2__c, Building_Name_Number__c, Case__c, County__c, 
                                            Date_of_Birth__c, First_Name__c, Flat__c, Last_Name__c, Middle_Name__c, Months_at_this_address__c, Postcode__c,
                                            Search_ID__c, Search_Reference__c, Smart_Search_Link__c, Smart_Search_Status__c, Subject_ID__c, Title__c, Town__c, 
                                            Years_at_this_address__c FROM Beneficial_Owner__c LIMIT 1];
        benOwner.Search_ID__c = '123123';
        update benOwner;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_SearchSubject_ResponseMock(401));
        SmartSearchCompCont.searchNameToSmartSearch(caseId, benOwner);
        test.stopTest();
    }

    @isTest static void testMethodGetDocument(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Beneficial_Owner__c benOwner = [SELECT Id, Account__c, Address_Line_1__c, Address_Line_2__c, Building_Name_Number__c, Case__c, County__c, 
                                            Date_of_Birth__c, First_Name__c, Flat__c, Last_Name__c, Middle_Name__c, Months_at_this_address__c, Postcode__c,
                                            Search_ID__c, Search_Reference__c, Smart_Search_Link__c, Smart_Search_Status__c, Subject_ID__c, Title__c, Town__c, 
                                            Years_at_this_address__c FROM Beneficial_Owner__c LIMIT 1];
        benOwner.Search_ID__c = '123123';
        update benOwner;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_GetDocument_ResponseMock(200));
        SmartSearchCompCont.getDocument(caseId, benOwner.Id, benOwner.Search_ID__c);
        test.stopTest();
    }

    @isTest static void testMethodGetDocumentExpired(){
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Beneficial_Owner__c benOwner = [SELECT Id, Account__c, Address_Line_1__c, Address_Line_2__c, Building_Name_Number__c, Case__c, County__c, 
                                            Date_of_Birth__c, First_Name__c, Flat__c, Last_Name__c, Middle_Name__c, Months_at_this_address__c, Postcode__c,
                                            Search_ID__c, Search_Reference__c, Smart_Search_Link__c, Smart_Search_Status__c, Subject_ID__c, Title__c, Town__c, 
                                            Years_at_this_address__c FROM Beneficial_Owner__c LIMIT 1];
        benOwner.Search_ID__c = '123123';
        update benOwner;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new API_GetDocument_ResponseMock(401));
        SmartSearchCompCont.getDocument(caseId, benOwner.Id, benOwner.Search_ID__c);
        test.stopTest();
    }

    

}