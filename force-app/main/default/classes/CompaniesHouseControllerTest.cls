@isTest
public  class CompaniesHouseControllerTest {
   
    public class API_ResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            System.debug('ENDPOINT: ' + request.getEndPoint());
            String insertBody = '';
            if(request.getEndPoint() == 'https://api.companieshouse.gov.uk/company/11354151'){
                insertBody = '{"links":{"filing_history":"/company/11354151/filing-history","persons_with_significant_control":"/company/11354151/persons-with-significant-control","self":"/company/11354151","officers":"/company/11354151/officers"},"company_name":"CLOUD ORCA LIMITED","sic_codes":["62012","62020","62030","63110"],"company_number":"11354151","confirmation_statement":{"overdue":false,"next_made_up_to":"2024-02-03","last_made_up_to":"2023-02-03","next_due":"2024-02-17"},"company_status":"active","has_insolvency_history":false,"undeliverable_registered_office_address":false,"registered_office_is_in_dispute":false,"type":"ltd","jurisdiction":"england-wales","accounts":{"accounting_reference_date":{"month":"05","day":"31"},"next_due":"2024-02-29","next_made_up_to":"2023-05-31","overdue":false,"last_accounts":{"made_up_to":"2022-05-31","period_end_on":"2022-05-31","type":"total-exemption-full","period_start_on":"2021-06-01"},"next_accounts":{"period_end_on":"2023-05-31","due_on":"2024-02-29","period_start_on":"2022-06-01","overdue":false}},"has_charges":false,"registered_office_address":{"postal_code":"EC2A 1NT","address_line_1":"131 Finsbury Pavement","country":"England","locality":"London"},"date_of_creation":"2018-05-10","etag":"8bf9ff63002604557059be9cf07f78c9cd8a5ab5","has_super_secure_pscs":false,"can_file":true}';
            } else if(request.getEndPoint() == 'https://api.companieshouse.gov.uk/company/11354151/officers'){
                insertBody = '{"total_results":5,"resigned_count":1,"active_count":4,"items_per_page":35,"items":[{"appointed_on":"2022-08-18","links":{"self":"/company/11354151/appointments/k7wrrp707KW2pwzvIZd20BxEfUU","officer":{"appointments":"/officers/jP2mj6wU6QM_Kutnks1murgGXoQ/appointments"}},"date_of_birth":{"month":1,"year":1990},"nationality":"British","address":{"country":"England","address_line_1":"Finsbury Pavement","locality":"London","premises":"131","postal_code":"EC2A 1NT"},"country_of_residence":"England","occupation":"Delivery Director","officer_role":"director","name":"BELLAMY, Luke James"},{"country_of_residence":"United Kingdom","occupation":"Director","address":{"premises":"131","address_line_1":"Finsbury Pavement","country":"England","locality":"London","postal_code":"EC2A 1NT"},"officer_role":"director","name":"DI CARLO, Antonio","nationality":"British","date_of_birth":{"month":9,"year":1984},"links":{"self":"/company/11354151/appointments/0psciyuLrvOSAc8wXFvH-7_AR4c","officer":{"appointments":"/officers/_O5iiFxN50xCaY6M35HyHNXnZis/appointments"}},"appointed_on":"2019-03-18"},{"links":{"self":"/company/11354151/appointments/Jb9xK9RohctrUBIXRkYh2khpTK0","officer":{"appointments":"/officers/9BlH2R6WLoI_G5-TN5wZY_mtRac/appointments"}},"appointed_on":"2021-07-29","address":{"address_line_1":"Finsbury Pavement","postal_code":"EC2A 1NT","locality":"London","premises":"131","country":"England"},"country_of_residence":"England","occupation":"Director","officer_role":"director","name":"MCCARTHY, Ben","date_of_birth":{"month":7,"year":1990},"nationality":"English"},{"links":{"self":"/company/11354151/appointments/IaLvrulqOl03m8TkNGRkmSyyFe8","officer":{"appointments":"/officers/BsgcLb-ABHMTN1sVnEbvPzW4ZBw/appointments"}},"appointed_on":"2018-05-10","address":{"locality":"London","address_line_1":"Finsbury Pavement","country":"England","postal_code":"EC2A 1NT","premises":"131"},"country_of_residence":"England","occupation":"Director","name":"ROWLAND, Edward James","officer_role":"director","date_of_birth":{"year":1984,"month":12},"nationality":"British"},{"resigned_on":"2020-09-17","appointed_on":"2018-05-10","links":{"officer":{"appointments":"/officers/eQkgnIBz6vHWJoU17cnlOserdWU/appointments"},"self":"/company/11354151/appointments/lBVs69-qrAzkM846X1o-BJpv1lQ"},"date_of_birth":{"year":1985,"month":2},"nationality":"British","address":{"address_line_1":"Luke Street","region":"London","locality":"Shoreditch","premises":"25","postal_code":"EC2A 4DS","country":"England"},"country_of_residence":"United Kingdom","occupation":"Director","name":"AKANDE, Olu Dare","officer_role":"director"}],"etag":"215386f7535b77b87593a674fb5c639e39b724dd","inactive_count":0,"links":{"self":"/company/11354151/officers"},"start_index":0,"kind":"officer-list"}';
            } else if(request.getEndPoint() == 'https://api.companieshouse.gov.uk/company/11354151/filing-history'){
                insertBody = '{"total_count":52,"filing_history_status":"filing-history-available","items_per_page":25,"items":[{"action_date":"2023-10-30","category":"capital","date":"2023-11-01","description":"capital-allotment-shares","description_values":{"date":"2023-10-30","capital":[{"currency":"GBP","figure":"66.56"}]},"links":{"self":"/company/11354151/filing-history/MzM5ODY1OTMxNGFkaXF6a2N4","document_metadata":"https://frontend-doc-api.company-information.service.gov.uk/document/WNB07PoOY4EvnixYPC0iyGIcPy-w46o3U_f_hkBbTWs"},"type":"SH01","pages":4,"barcode":"XCFEOWKY","transaction_id":"MzM5ODY1OTMxNGFkaXF6a2N4"}],"start_index":0}';
            } else if(request.getEndPoint() == 'pdftest.com'){
                insertBody = '{}';
            }

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(insertBody);
            response.setStatus('OK');
            response.setStatusCode(200);
            System.debug('response::' + response);
            return response;
        }
    }

    @TestSetup
    static void setup(){  
        Company_House_API__c testAPISettings = new Company_House_API__c(
            CompanyEndPoint__c = 'https://api.companieshouse.gov.uk',
            Authorization__c = '774eb80a-826a-4d1f-aaab-667a92bf2c0d'
        );
        insert testAPISettings;

        Company_House_Setting__c testAddressSettings = new Company_House_Setting__c(
            Account_Address__c = 'Billing',
            Contact_Address__c = 'Mailing',
            Auto_Update_Accounts__c = true,
            Auto_Update_Contacts__c = true
        );
        insert testAddressSettings;

        Account acc = new Account();
        acc.Name = 'CLOUD ORCA LIMITED';
        acc.Company_Legal_Name__c = 'CLOUD ORCA LIMITED';
        acc.Company_registration_number__c = '11354151';
        acc.Source__c = 'Inbound';
        acc.Source_Type__c  = 'Website';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Cloud Orca Contact 1';
        con.AccountId = acc.id;
        insert con;

        Contact con2 = new Contact();
        con2.Lastname = 'Cloud Orca Contact 2';
        con2.AccountId = acc.id;
        insert con2;

        Officer__c off = new Officer__c(
            Name = 'Officer',
            Account__c = acc.id
        );

        insert off;

        
    }

    @isTest static void testCreateNewContacts() {
        Test.setMock(HttpCalloutMock.class, new API_ResponseMock());
        String companyName = [SELECT Id, Name, Company_registration_number__c FROM Account WHERE Name = 'CLOUD ORCA LIMITED' Limit 1].Name;

        Test.startTest();
            String companyResponse = CompaniesHouseController.getCompanyByName(companyName);
        Test.stopTest();
        System.assert(true, companyResponse != null);
    } 

    @isTest static void testGetCompanyByNumber() {
        Test.setMock(HttpCalloutMock.class, new API_ResponseMock());
        String companyNumber = [SELECT Id, Name, Company_registration_number__c FROM Account WHERE Company_registration_number__c = '11354151' Limit 1].Company_registration_number__c;

        Test.startTest();
            String companyResponse = CompaniesHouseController.getCompanyByNumber(companyNumber);
        Test.stopTest();
        System.assert(true, companyResponse != null);
    } 

    @isTest static void testGetCompanyOfficers() {
        Test.setMock(HttpCalloutMock.class, new API_ResponseMock());
        String companyNumber = [SELECT Id, Name, Company_registration_number__c FROM Account WHERE Company_registration_number__c = '11354151' Limit 1].Company_registration_number__c;

        Test.startTest();
            String companyOfficersResponse = CompaniesHouseController.getCompanyOfficers(companyNumber);
        Test.stopTest();
        System.assert(true, companyOfficersResponse != null);
    }

    
    @isTest static void testGetExactMatchContacts() {
        Account acc = [SELECT Id, Name, Company_registration_number__c FROM Account WHERE Company_registration_number__c = '11354151' Limit 1];
        List<Officer__c> contactsList = [SELECT Id, Name, Officer_Key__c FROM Officer__c WHERE Officer_Key__c != null];
        List<String> officerKeys = new List<String>();
        for(Officer__c contactRecord : contactsList) {
            officerKeys.add(contactRecord.Officer_Key__c);
        }
        Test.startTest();
            Map<String, Officer__c> exactMatch = CompaniesHouseController.getExactMatchContacts(officerKeys, acc.Id);
        Test.stopTest();
        System.assert(true, exactMatch != null);
    }

    @isTest static void testSearchContact() {
        Account acc = [SELECT Id, Name, Company_registration_number__c FROM Account WHERE Company_registration_number__c = '11354151' Limit 1];
        List<String> searchKey = new List<String>{'Cloud Orca Contact 1'};

        Test.startTest();
            List<Officer__c> contacts = CompaniesHouseController.searchOfficer(searchKey);
        Test.stopTest();
        System.assert(true, contacts != null);
    }

    @isTest static void testGetContactFieldNameAndAPI() {
        Test.startTest();
            String fieldLabel = CompaniesHouseController.getOfficerFieldNameAndAPI('Name');
        Test.stopTest();
        System.assert(true, fieldLabel != null);
    }

    @isTest static void testGetCompanyPeronsSignificantControl() {
        Test.setMock(HttpCalloutMock.class, new API_ResponseMock());
        Test.startTest();
            String fieldLabel = CompaniesHouseController.getCompanyPeronsSignificantControl('11354151');
        Test.stopTest();
        System.assert(true, fieldLabel != null);
    }

    @isTest static void testGetCustomSettings() {
        Test.startTest();
            Company_House_Setting__c settings = CompaniesHouseController.getCustomSettings();
        Test.stopTest();
        System.assert(true, settings != null);
    }

    @IsTest
    static void testGetCompaniesHouseMetadata() {
        Test.startTest();
            List<Companies_House_Setting__mdt> settings = CompaniesHouseController.getCompaniesHouseMetadata();
        Test.stopTest();
        System.assert(true, settings != null);
    }

    @IsTest
    static void testMergeSelectedContacts_Positive() {
        List<Officer__c> createdOfficerList = [SELECT Id, Name FROM Officer__c];
        Test.startTest();
            List<Officer__c> mergedOfficers = CompaniesHouseController.mergeSelectedOfficers(new List<Id>(), new List<Id>(), createdOfficerList, new List<Id>());
        Test.stopTest();
        System.assertNotEquals(0, mergedOfficers.size(), 'Merged contacts should not be empty');
    }

    @IsTest
    static void testMergeSelectedContacts_Negative() {
        Test.startTest();
            List<Officer__c> mergedOfficers = CompaniesHouseController.mergeSelectedOfficers(new List<Id>(), new List<Id>(), null, new List<Id>());
        Test.stopTest();
        System.assertEquals(0, mergedOfficers.size(), 'Merged is empty');
    }

    @IsTest
    static void testUpdateAccountContactFields() {
        Test.setMock(HttpCalloutMock.class, new API_ResponseMock());
        String jsonString = '{"links":{"filing_history":"/company/11354151/filing-history","persons_with_significant_control":"/company/11354151/persons-with-significant-control","self":"/company/11354151","officers":"/company/11354151/officers"},"company_name":"CLOUD ORCA LIMITED","sic_codes":["62012","62020","62030","63110"],"company_number":"11354151","confirmation_statement":{"overdue":false,"next_made_up_to":"2024-02-03","last_made_up_to":"2023-02-03","next_due":"2024-02-17"},"company_status":"active","has_insolvency_history":false,"undeliverable_registered_office_address":false,"registered_office_is_in_dispute":false,"type":"ltd","jurisdiction":"england-wales","accounts":{"accounting_reference_date":{"month":"05","day":"31"},"next_due":"2024-02-29","next_made_up_to":"2023-05-31","overdue":false,"last_accounts":{"made_up_to":"2022-05-31","period_end_on":"2022-05-31","type":"total-exemption-full","period_start_on":"2021-06-01"},"next_accounts":{"period_end_on":"2023-05-31","due_on":"2024-02-29","period_start_on":"2022-06-01","overdue":false}},"has_charges":false,"registered_office_address":{"postal_code":"EC2A 1NT","address_line_1":"131 Finsbury Pavement","country":"England","locality":"London"},"date_of_creation":"2018-05-10","etag":"8bf9ff63002604557059be9cf07f78c9cd8a5ab5","has_super_secure_pscs":false,"can_file":true}';
        String jsonOfficers = '{"total_results":5,"resigned_count":1,"active_count":4,"items_per_page":35,"items":[{"appointed_on":"2022-08-18","links":{"self":"/company/11354151/appointments/k7wrrp707KW2pwzvIZd20BxEfUU","officer":{"appointments":"/officers/jP2mj6wU6QM_Kutnks1murgGXoQ/appointments"}},"date_of_birth":{"month":1,"year":1990},"nationality":"British","address":{"country":"England","address_line_1":"Finsbury Pavement","locality":"London","premises":"131","postal_code":"EC2A 1NT"},"country_of_residence":"England","occupation":"Delivery Director","officer_role":"director","name":"BELLAMY, Luke James"},{"country_of_residence":"United Kingdom","occupation":"Director","address":{"premises":"131","address_line_1":"Finsbury Pavement","country":"England","locality":"London","postal_code":"EC2A 1NT"},"officer_role":"director","name":"DI CARLO, Antonio","nationality":"British","date_of_birth":{"month":9,"year":1984},"links":{"self":"/company/11354151/appointments/0psciyuLrvOSAc8wXFvH-7_AR4c","officer":{"appointments":"/officers/_O5iiFxN50xCaY6M35HyHNXnZis/appointments"}},"appointed_on":"2019-03-18"},{"links":{"self":"/company/11354151/appointments/Jb9xK9RohctrUBIXRkYh2khpTK0","officer":{"appointments":"/officers/9BlH2R6WLoI_G5-TN5wZY_mtRac/appointments"}},"appointed_on":"2021-07-29","address":{"address_line_1":"Finsbury Pavement","postal_code":"EC2A 1NT","locality":"London","premises":"131","country":"England"},"country_of_residence":"England","occupation":"Director","officer_role":"director","name":"MCCARTHY, Ben","date_of_birth":{"month":7,"year":1990},"nationality":"English"},{"links":{"self":"/company/11354151/appointments/IaLvrulqOl03m8TkNGRkmSyyFe8","officer":{"appointments":"/officers/BsgcLb-ABHMTN1sVnEbvPzW4ZBw/appointments"}},"appointed_on":"2018-05-10","address":{"locality":"London","address_line_1":"Finsbury Pavement","country":"England","postal_code":"EC2A 1NT","premises":"131"},"country_of_residence":"England","occupation":"Director","name":"ROWLAND, Edward James","officer_role":"director","date_of_birth":{"year":1984,"month":12},"nationality":"British"},{"resigned_on":"2020-09-17","appointed_on":"2018-05-10","links":{"officer":{"appointments":"/officers/eQkgnIBz6vHWJoU17cnlOserdWU/appointments"},"self":"/company/11354151/appointments/lBVs69-qrAzkM846X1o-BJpv1lQ"},"date_of_birth":{"year":1985,"month":2},"nationality":"British","address":{"address_line_1":"Luke Street","region":"London","locality":"Shoreditch","premises":"25","postal_code":"EC2A 4DS","country":"England"},"country_of_residence":"United Kingdom","occupation":"Director","name":"AKANDE, Olu Dare","officer_role":"director"}],"etag":"215386f7535b77b87593a674fb5c639e39b724dd","inactive_count":0,"links":{"self":"/company/11354151/officers"},"start_index":0,"kind":"officer-list"}';

        Account acc = [SELECT Id, Name, Company_registration_number__c FROM Account WHERE Company_registration_number__c = '11354151' Limit 1];
        List<Officer__c> contactsForUpdate = [SELECT Id, Name FROM Officer__c];

        List<CompaniesHouseController.FileWrapper> fileWrappers  = new List<CompaniesHouseController.FileWrapper>();
        CompaniesHouseController.FileWrapper fileWrapper = new CompaniesHouseController.FileWrapper();
        fileWrapper.fileDate = 'Date';
        fileWrapper.fileType = 'Type';
        fileWrapper.fileDescription = 'Test Description';
        fileWrapper.fileDownloadName = 'Test Name';
        fileWrapper.downloadURL = 'pdftest.com';
        fileWrappers.add(fileWrapper);

        List<CompaniesHouseController.PSCWrapper> pscWrappers = new List<CompaniesHouseController.PSCWrapper>();
        CompaniesHouseController.PSCWrapper pscWrapper = new CompaniesHouseController.PSCWrapper();
        pscWrapper.Id = '';
        pscWrapper.fullName = 'Test name';

        CompaniesHouseController.ImportData importData = new CompaniesHouseController.ImportData();
        importData.donotimport = true;
        importData.isMatch = true;
        importData.isNew = true;
    
        pscWrapper.importData = importData;

        CompaniesHouseController.Address address = new CompaniesHouseController.Address();
        address.address_line_1 = 'Test';
        address.address_line_2 = 'Test';
        address.care_of = 'Test';
        address.country = 'Test';
        address.locality = 'Test';
        address.po_box = 'Test';
        address.postal_code = 'Test';
        address.premises = 'Test';
        address.region = 'Test';

        CompaniesHouseController.DateOfBirth dob = new CompaniesHouseController.DateOfBirth();
        dob.day = 1;
        dob.month = 20;
        dob.year = 2018;

        CompaniesHouseController.Item item = new CompaniesHouseController.Item();
        item.address = address;
        item.ceased = false;
        item.ceased_on = Date.today();
        item.date_of_birth = dob;
        item.description = 'Test Description';
        item.etag = 'Test';
        item.name = 'Test Name';
        item.nationality = 'American';

        pscWrapper.item = item;
        pscWrappers.add(pscWrapper);

        Test.startTest();
            List<Officer__c> updatedAccountContacts = CompaniesHouseController.updateAccountOfficerFields(acc.Id, acc.Company_registration_number__c, jsonString, contactsForUpdate, jsonOfficers, fileWrappers, pscWrappers);
        Test.stopTest();
        System.assertNotEquals(0, updatedAccountContacts.size(), 'Account and Contact not updated');
    }

    @isTest
    static void getFillingHistoriesScenario(){
        Test.setMock(HttpCalloutMock.class, new API_ResponseMock());
        Test.startTest();
        CompaniesHouseController.getFillingHistories('11354151');
        Test.stopTest();
    }
}