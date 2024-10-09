/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs) 
 **/
@IsTest
private class dlrs_ffscpq_Estimate_Role_RequestTest
{
    @IsTest(SeeAllData=true)
    private static void testTrigger()
    {
ffscpq__Estimate_Role_Request__c testRequest = [select id from ffscpq__Estimate_Role_Request__c limit 1];

update testRequest;
    }
}