trigger AccountTrigger on Account (before update, after insert) {
    if(trigger.isBefore){
        if(trigger.isUpdate){
            AccountTriggerHandler.onBeforeUpdate(trigger.new, trigger.oldMap);
        }
    }
    
    if(trigger.isInsert){
        if(trigger.isAfter){
            AccountTriggerHandler.onAfterInsert(trigger.new);
        }
    }
}