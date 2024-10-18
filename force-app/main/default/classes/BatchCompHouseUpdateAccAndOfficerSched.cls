global with sharing class BatchCompHouseUpdateAccAndOfficerSched implements Schedulable{
    global void execute(SchedulableContext SC) {
        System.debug(SC.getTriggerId());
        Database.executebatch(new BatchCompHouseUpdateAccAndOfficer(new List<String>()), 1); 
    }
}