global class GetCompanyIdBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful, Database.AllowsCallouts {
    global Set<Id> collectionIds;
    global Set<String> validCompanyIds;

    global void execute(SchedulableContext SC) {
        Database.executebatch(new GetCompanyIdBatch(), 1); 
    }

    //Database.executeBatch(new GetCompanyIdBatch(), 1);
    global GetCompanyIdBatch(){
        this.collectionIds = new Set<Id>();
        this.validCompanyIds = new Set<String>();
    }

    global GetCompanyIdBatch(Set<Id> collectionIds){
        this.collectionIds = collectionIds;
        this.validCompanyIds = validCompanyIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, beauhurst_id__c, collection_name__c';
        query += ' FROM Company_Collection__c';
        query += ' WHERE beauhurst_id__c != null';
        query += ' AND sync__c = true';
        if(!collectionIds.isEmpty()){
            query += ' AND Id IN: collectionIds';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Company_Collection__c> scope){
        Set<String> retrievedCompanyIds = new Set<String>();
        Integer offsetVal = 0;
        Integer limitVal = 100;
        Boolean isLoop = true;

        while(isLoop){
            String append = '/companies/search?collection_id=' + scope[0].beauhurst_id__c + '&limit=' + limitVal + '&offset=' + offsetVal;

            Http http = new Http();
            HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
            if(res.getStatusCode() == 200){
                Response getData = (Response) JSON.deserialize(res.getBody(), Response.class);
                if(!getData.results.isEmpty()){
                    offsetVal += 100;
                    for(Result result : getData.results){
                        retrievedCompanyIds.add(result.id);
                    }
                }else{
                    isLoop = false;
                }
            }else{
                isLoop = false;
            }
        }

        if(!retrievedCompanyIds.isEmpty()){
            List<Company_ID__c> companyIdsToUpsert = new List<Company_ID__c>();
            Map<String, Account> bhIdToAccountMap = new Map<String, Account>();

            for(Account acc : [SELECT Id, Beauhurst_ID__c FROM Account WHERE Beauhurst_ID__c IN: retrievedCompanyIds]){
                bhIdToAccountMap.put(acc.Beauhurst_ID__c, acc);
            }

            for(String compId : retrievedCompanyIds){
                if(!bhIdToAccountMap.containsKey(compId)){
                    Company_ID__c comId = new Company_ID__c();
                    comId.beauhurst_id__c = compId;
                    companyIdsToUpsert.add(comId);
                }
            }

            if(!companyIdsToUpsert.isEmpty()){
                Schema.SObjectField extId = Company_ID__c.Fields.beauhurst_id__c;
                Database.UpsertResult[] results = Database.upsert(companyIdsToUpsert, extId, false);
    
                List<Collection_Item__c> collectionItemsToUpsert = new List<Collection_Item__c>();
                for(Integer index = 0, size = results.size(); index < size; index++) {
                    if(results[index].isSuccess()){
                        validCompanyIds.add(companyIdsToUpsert.get(index).beauhurst_id__c);
                        if(results[index].isCreated()){
                            Collection_Item__c itm = new Collection_Item__c();
                            itm.Company_Collection__c = scope[0].Id;
                            itm.Company_ID__c = results[index].getId();
                            itm.Item_Key__c = scope[0].beauhurst_id__c + '-' + companyIdsToUpsert.get(index).beauhurst_id__c;
                            collectionItemsToUpsert.add(itm);
                        }
                    }
                }
    
                if(!collectionItemsToUpsert.isEmpty()){
                    upsert collectionItemsToUpsert Item_Key__c;
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('@@@validCompanyIds: ' + validCompanyIds);
        Database.executeBatch(new CreateAccountsFromBHBatch(validCompanyIds), 10);
    }

    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
    }
}