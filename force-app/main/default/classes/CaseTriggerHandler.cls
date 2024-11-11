public class CaseTriggerHandler {
   
    public static void onAfterInsert(List<Case> newCaseList){
        onNewCaseCreateSharepointFolder(newCaseList);
    }

    public static void onNewCaseCreateSharepointFolder(List<Case> newCaseList){
        Set<Id> caseIds = new Set<Id>();
        for(Case newCase: newCaseList){
            caseIds.add(newCase.Id);
        }

        if(!caseIds.isEmpty() && !System.isFuture()){
            Database.executeBatch(new BatchCreateSharepointFolderCase(caseIds), 1);
        }
    }
}