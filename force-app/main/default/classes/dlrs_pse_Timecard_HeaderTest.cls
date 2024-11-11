/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs) 
 **/
@IsTest
private class dlrs_pse_Timecard_HeaderTest
{
    @IsTest(SeeAllData=true)
    private static void testTrigger()
    {
pse__Timecard_Header__c testTimecard = [select id from pse__Timecard_Header__c limit 1];

update testTimecard;
    }
}