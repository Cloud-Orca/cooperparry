trigger AccountTrigger on Account (after insert) {
    if(trigger.isInsert){
        if(trigger.isAfter){
            AccountTriggerHandler.onAfterInsert(trigger.new);
        }
    }
}