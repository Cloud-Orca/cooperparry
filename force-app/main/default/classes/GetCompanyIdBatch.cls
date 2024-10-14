global class GetCompanyIdBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global Set<Id> collectionIds;

    global GetCompanyIdBatch(){
        this.collectionIds = new Set<Id>();
    }

    global GetCompanyIdBatch(Set<Id> collectionIds){
        this.collectionIds = collectionIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, beauhurst_id__c FROM Company_Collection__c';
        query += ' WHERE beauhurst_id__c != null';
        if(!collectionIds.isEmpty()){
            query += ' AND Id IN: collectionIds';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Company_Collection__c> scope){
        List<Company_ID__c> companyIds = new List<Company_ID__c>();
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
                        Company_ID__c comId = new Company_ID__c();
                        comId.beauhurst_id__c = result.id;
                        //comId.Company_Collection__c = scope[0].Id;
                        companyIds.add(comId);
                    }
                }else{
                    isLoop = false;
                }
            }else{
                isLoop = false;
            }
        }

        if(!companyIds.isEmpty()){
            upsert companyIds beauhurst_id__c;
        }

        scope[0].processed__c = true;
        update scope;
    }

    global void finish(Database.BatchableContext BC){

    }

    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
    }
}