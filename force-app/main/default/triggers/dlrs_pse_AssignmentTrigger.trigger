trigger dlrs_pse_AssignmentTrigger on pse__Assignment__c (before delete, before insert, before update, after delete, after insert, after undelete, after update) {
dlrs.RollupService.triggerHandler(pse__Assignment__c.SObjectType); 
}