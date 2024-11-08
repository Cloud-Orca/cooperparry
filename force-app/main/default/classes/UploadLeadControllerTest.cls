@isTest
public with sharing class UploadLeadControllerTest {
    @IsTest
    static void testImportLeadNoError(){
        String csvStrContent = 'Last Name\nTest';
        
        Map<String, String> results = UploadLeadController.createLeads(csvStrContent);
        
        System.assertEquals(true, results.get('successFile').contains('00Q')); // Lead is Created
    }
    
    @IsTest
    static void testImportLeadWithError(){
        String csvStrContent = 'testField\nTest';
        
        Map<String, String> results = UploadLeadController.createLeads(csvStrContent);
        
        System.assertEquals(true, results.get('errorFile').contains('Mismatched')); // Mismatch mapping testField is a dumme field
    }
    @IsTest
    static void testImportLeadWithValidationError(){
        String csvStrContent = 'First Name\nTest';
        
        Map<String, String> results = UploadLeadController.createLeads(csvStrContent);
        System.debug('With Val error ==> ' + results);
        System.assertEquals(true, results.get('errorFile').contains('REQUIRED_FIELD_MISSING')); // Required Error. No LastName added in the CSV content
        
    }

    @IsTest
    static void testGetNumberOfRows(){
        
        Test.startTest();
        String csvStrContent = 'First Name\nTest';
        Decimal count = UploadLeadController.getNumberOfRows(csvStrContent);
        System.assertEquals(2, count);
        Test.stopTest();
        
    }
    
}