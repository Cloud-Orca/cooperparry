/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs) 
 **/
trigger dlrs_ffscpq_Estimate_Role_RequestTrigger on ffscpq__Estimate_Role_Request__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(ffscpq__Estimate_Role_Request__c.SObjectType);
}