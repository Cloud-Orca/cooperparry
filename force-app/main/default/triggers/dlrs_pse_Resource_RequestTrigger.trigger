/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs) 
 **/
trigger dlrs_pse_Resource_RequestTrigger on pse__Resource_Request__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(pse__Resource_Request__c.SObjectType);
}