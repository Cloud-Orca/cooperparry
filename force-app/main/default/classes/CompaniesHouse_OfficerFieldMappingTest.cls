@isTest
public with sharing class CompaniesHouse_OfficerFieldMappingTest {
    @testSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Officer__c testOfficer = new Officer__c(
            Name = 'Test Officer',
            Account__c = testAccount.Id,
            Officer_Key__c = '123456',
            Title__c = 'Director',
            Resident_Country__c = 'United Kingdom',
            Nationality__c = 'British'
        );
        insert testOfficer;

        Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testAdminUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
            Username = 'testadmin' + System.currentTimeMillis() + '@example.com',
            Alias = 'tadmin',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = systemAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testAdminUser;
    }

    @isTest
    static void testUpdateOfficerFields() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Officer__c testOfficer = [SELECT Id, Officer_Key__c FROM Officer__c LIMIT 1];
        String jsonString = '{"items":[{"name":"John Doe","officer_role":"Director","country_of_residence":"United Kingdom","nationality":"British","links":{"self":"/officers/123456"}}]}';
        Test.startTest();
            List<User> getUser = [SELECT Id FROM User LIMIT 1];
            System.runAs(getUser[0]) {
                List<Officer__c> updatedOfficers = CompaniesHouse_OfficerFieldMapping.updateOfficerFields(
                    testAccount.Id,
                    jsonString,
                    true
                );
            }
        Test.stopTest();
    }

    @isTest
    static void testCreateNewOfficers() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String jsonString = '{"items":[{"name":"Smith, John","officer_role":"Director","country_of_residence":"United Kingdom","nationality":"British","date_of_birth":{"month":"5","year":"1980"},"links":{"self":"/officers/654321"}}]}';
        String jsonString2 = '[{"name_elements":{"title":"Mr","forename":"John","middle_name":"Edward","surname":"Smith"},"nationality":"British","country_of_residence":"United Kingdom","address":{"address_line_1":"123 Test Street","address_line_2":"Apt 456","locality":"Test City","country":"United Kingdom","postal_code":"AB1 2CD"}}]';
        Test.startTest();
        List<Officer__c> newOfficers = CompaniesHouse_OfficerFieldMapping.createNewOfficers(
            testAccount.Id,
            new List<String>{'654321'},
            jsonString,
            jsonString2,
            true
        );
        Test.stopTest();
    }

    @isTest
    static void testEmptyInput() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<User> getUser = [SELECT Id FROM User LIMIT 1];

        Test.startTest();
            System.runAs(getUser[0]) {
                List<Officer__c> updatedOfficers = CompaniesHouse_OfficerFieldMapping.updateOfficerFields(
                    testAccount.Id,
                    '{"items": []}',
                    true
                );
                System.runAs(getUser[0]) {
                    List<Officer__c> newOfficers = CompaniesHouse_OfficerFieldMapping.createNewOfficers(
                        testAccount.Id,
                        new List<String>(),
                        '{"items": []}',
                        null,
                        true
                    );
                }
            }
        Test.stopTest();
    }
}