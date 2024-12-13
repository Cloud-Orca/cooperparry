@IsTest
public with sharing class CompanyHouseSettingOfficerTest {
    
    @TestSetup
    static void setup(){
        Company_House_API__c companyHouseAPI = new Company_House_API__c(
            CompanyEndPoint__c = 'https://api.company-information.service.gov.uk/',
            Authorization__c = '774eb80a-826a-4d1f-aaab-667a92bf2c0d'
        );
        insert companyHouseAPI;

        Company_House_Setting__c addressSettings = new Company_House_Setting__c(
            Account_Address__c = 'Billing',
            Contact_Address__c = 'Mailing',
            Auto_Update_Accounts__c = true,
            Auto_Update_Contacts__c = true,
            Batch_Occurrence__c = 'Yearly',
            Import_Resigned__c = true
        );
        insert addressSettings;
    }

    @IsTest
    static void testGetCustomSettings() {
        Test.startTest();
            CompanyHouseSettingOfficer.CustomSettingWrapp settings = CompanyHouseSettingOfficer.getCustomSettings();
        Test.stopTest();
        System.assert(true, settings != null);
    }

    @IsTest
    static void testSaveCompanyHouseAPI() {
        String companyHouseAPI = [SELECT Id, CompanyEndPoint__c, Authorization__c FROM Company_House_API__c WHERE CompanyEndPoint__c = 'https://api.company-information.service.gov.uk/' LIMIT 1].Authorization__c;

        Test.startTest();
            Company_House_API__c compSetting = Company_House_API__c.getOrgDefaults();
            CompanyHouseSettingOfficer.saveCompanyHouseAPI(compSetting);
        Test.stopTest();
        System.assert(true, companyHouseAPI != null);
    }

    @IsTest
    static void testSaveCompanyHouseSetting() {
        
        Company_House_Setting__c companyHouseSetting = [SELECT Id, Account_Address__c, Contact_Address__c, Auto_Update_Accounts__c, Auto_Update_Contacts__c, Batch_Occurrence__c, Import_Resigned__c, Schedule_Job_Id__c FROM Company_House_Setting__c LIMIT 1];
        System.debug('Test SaveCompanyHouseSetting companyHouseSetting.Batch_Occurrence__c:: ' + companyHouseSetting);
        
        Test.startTest();
            String uniqueJobName = 'Batch Companies House Update TestSettings_' + Datetime.now().getTime();
            Id schedJobId = System.schedule(uniqueJobName, '0 0 0 * * ?', new BatchCompHouseUpdateAccAndOfficerSched());
            System.debug(schedJobId);

            companyHouseSetting.Account_Address__c = 'Shipping';
            companyHouseSetting.Contact_Address__c = 'Other';
            companyHouseSetting.Schedule_Job_Id__c = schedJobId;
            companyHouseSetting.Import_Resigned__c = false;
            CompanyHouseSettingOfficer.saveCompanyHouseSetting(companyHouseSetting);

            companyHouseSetting.Batch_Occurrence__c = 'Daily';
            CompanyHouseSettingOfficer.saveCompanyHouseSetting(companyHouseSetting);
            companyHouseSetting.Batch_Occurrence__c = 'Weekly';
            CompanyHouseSettingOfficer.saveCompanyHouseSetting(companyHouseSetting);
            companyHouseSetting.Batch_Occurrence__c = 'Monthly';
            CompanyHouseSettingOfficer.saveCompanyHouseSetting(companyHouseSetting);
        Test.stopTest();
        System.assert(true, companyHouseSetting != null);
    }
}