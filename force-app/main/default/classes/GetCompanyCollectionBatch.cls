global class GetCompanyCollectionBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String collectionId {get; set;}
    
    global GetCompanyCollectionBatch(String collectionId) {
        this.collectionId = collectionId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name FROM User LIMIT 1';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<User> scope){
        System.debug('collectionId collectionId collectionId ' + this.collectionId);
        List<Company_Collection__c> companyCollections = new List<Company_Collection__c>();
        Integer offsetVal = 0;
        Integer limitVal = 100;
        Boolean isLoop = true;

        while(isLoop){
            String append = '/collections/company?offset=' + offsetVal + '&limit=' + limitVal;

            Http http = new Http();
            HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
            if(res.getStatusCode() == 200){
                Response getData = (Response) JSON.deserialize(res.getBody(), Response.class);
                if(!getData.results.isEmpty()){
                    offsetVal += 100;
                    for(Result result : getData.results){
                        if( this.collectionId == result.id ){
                            Company_Collection__c col = new Company_Collection__c();
                            col.beauhurst_id__c = result.id;
                            col.collection_name__c = result.name;
                            col.count__c = result.count;
                            col.processed__c = false;
                            col.sync__c = true;
                            companyCollections.add(col);
                            
                            isLoop = false;
                            break;
                        } 
                    }
                }else{
                    isLoop = false;
                }
            }else{
                isLoop = false;
            }
        }

        if(!companyCollections.isEmpty()){
            upsert companyCollections beauhurst_id__c;
        }
    }

    global void finish(Database.BatchableContext BC){
        if(!Test.isRunningTest()){
            Database.executeBatch(new GetCompanyIdBatch(), 1);
        }
    }

    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
        public String name;
        public Integer count;
    }
}