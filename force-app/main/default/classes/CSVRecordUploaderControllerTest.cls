@IsTest 
public class CSVRecordUploaderControllerTest {

    @IsTest
    static void testGetNumberOfRows(){
        
        Test.startTest();
        String csvStrContent = 'First Name\nTest';
        Decimal count = CSVRecordUploaderController.getNumberOfRows(csvStrContent);
        System.assertEquals(2, count);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateRecordAccount(){
        
        Test.startTest();
        String csvStrContent = 'Company Name\n"Test, test-test"';
        Map<String, String> recordCreate = CSVRecordUploaderController.createRecord(csvStrContent, 'Account');
        String successFile = recordCreate.get('successFile');
        system.assertEquals(2, successFile.split('\n', 2).size());
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateRecordContact(){
        
        Test.startTest();
        Account newAcc = new Account();
        newAcc.Name = 'test';
        newAcc.Beauhurst_ID__c = '3245';
        insert newAcc;
        String csvStrContent = 'FirstName,LastName,Registered Number\nTest,Test,3245';
        Map<String, String> recordCreate = CSVRecordUploaderController.createRecord(csvStrContent, 'Contact');
        Test.stopTest();
    }
    

}