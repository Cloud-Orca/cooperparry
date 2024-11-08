@IsTest
private class dlrs_pse_AssignmentTest { 
    
    @IsTest(SeeAllData=true)
    private static void testTrigger()
    {
        pse__Assignment__c testAssignment = [select id from pse__Assignment__c limit 1];
        update testAssignment;
    }
        

}