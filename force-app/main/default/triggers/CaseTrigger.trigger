trigger CaseTrigger on Case (after insert) {
    if(trigger.isInsert){
        if(trigger.isAfter){
            CaseTriggerHandler.onAfterInsert(trigger.new);
        }
    }
}