public class AccountTriggerHandler {
    public static void onBeforeUpdate(List<Account> accounts, Map<Id, Account> oldAccountMap){
        recreateTeamMembers(accounts, oldAccountMap);
    }
    
    public static void onAfterInsert(List<Account> newAccountList){
        onNewAccountCreateSharepointFolder(newAccountList);
    }
    
    public static void recreateTeamMembers(List<Account> accounts, Map<Id, Account> oldAccountMap){
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : accounts){
            Account oldAcc = oldAccountMap.get(acc.Id);
            if(acc.OwnerId != oldAcc.OwnerId){
                accountIds.add(acc.Id);
            }
        }
        
        if(!accountIds.isEmpty()){
            Map<Id, List<AccountTeamMember>> accIdToMembersMap = new Map<Id, List<AccountTeamMember>>();
            for(AccountTeamMember mem : [SELECT Id, AccountId, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, 
                                         	CurrencyIsoCode, OpportunityAccessLevel, UserId, TeamMemberRole
                                        	FROM AccountTeamMember WHERE AccountId IN: accountIds]){
            	if(!accIdToMembersMap.containsKey(mem.AccountId)){
                    accIdToMembersMap.put(mem.AccountId, new List<AccountTeamMember>{mem});                     
                }else{
                    accIdToMembersMap.get(mem.AccountId).add(mem);
                }
            }
            
            if(!accIdToMembersMap.isEmpty() && !System.isFuture() && !System.isBatch()){
                recreateTeamMembersFuture(JSON.serialize(accIdToMembersMap));
            }
        }
    }
    
    @future
    public static void recreateTeamMembersFuture(String accIdToMembersMapStr){
        List<AccountTeamMember> insertAccountTeams = new List<AccountTeamMember>();
        Map<Id, List<AccountTeamMember>> accIdToMembersMap = (Map<Id, List<AccountTeamMember>>)JSON.deserialize(accIdToMembersMapStr, Map<Id, List<AccountTeamMember>>.class);
        
        for(Id accId : accIdToMembersMap.keySet()){
            for(AccountTeamMember mem : accIdToMembersMap.get(accId)){
                AccountTeamMember insertMem = new AccountTeamMember();
                insertMem.AccountId = mem.AccountId;
                insertMem.AccountAccessLevel = mem.AccountAccessLevel;
                insertMem.CaseAccessLevel = mem.CaseAccessLevel;
                insertMem.ContactAccessLevel = mem.ContactAccessLevel;
                insertMem.OpportunityAccessLevel = mem.OpportunityAccessLevel;
                insertMem.CurrencyIsoCode = mem.CurrencyIsoCode;
                insertMem.UserId = mem.UserId;
                insertMem.TeamMemberRole = mem.TeamMemberRole;
                insertAccountTeams.add(insertMem);
            }
        }
        
        if(!insertAccountTeams.isEmpty()){
            insert insertAccountTeams;
        }
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