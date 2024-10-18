public class AccountTriggerHandler {
    
    public static void onAfterInsert(List<Account> newAccountList){
        onNewAccountCreateSharepointFolder(newAccountList);
    }

    public static void onNewAccountCreateSharepointFolder(List<Account> newAccountList){
        Set<Id> accountIds = new Set<Id>();
        for(Account newAccount: newAccountList){
            accountIds.add(newAccount.Id);
        }

        if(!accountIds.isEmpty() && !System.isFuture()){
            Database.executeBatch(new BatchCreateSharepointFolderAccount(accountIds), 1);
        }
    }
}