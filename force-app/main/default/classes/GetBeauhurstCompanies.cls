public with sharing class GetBeauhurstCompanies {
    @AuraEnabled
    public static SyncResponse syncRecord(Result params){
        System.debug('params params params' + params );

        Boolean isSuccess = false;
        String errorMessage = '';

        Company_Collection__c col = new Company_Collection__c();
        col.beauhurst_id__c = params.id;
        col.collection_name__c = params.name;
        col.count__c = params.count;
        col.sync__c = true;

        Database.SaveResult result = Database.insert(col, false);
        if (result.isSuccess()) {
            isSuccess = true;
            errorMessage = 'Record successfully created.';
            if( !Test.isRunningTest()){
                Database.executebatch(new GetCompanyIdBatch(new Set<Id>{result.getId()}), 1);
            }
        } else {
           errorMessage = result.getErrors()[0].getMessage();
        }

        return new SyncResponse(isSuccess, errorMessage);
    }

    @AuraEnabled
    public static Detail getCollectionDetail(String collectionId){
        System.debug('collectionId collectionId collectionId' + collectionId);

        List<Company_Collection__c> companyCollections = [SELECT Id FROM Company_Collection__c WHERE beauhurst_id__c =: collectionId];
        List<Result> resDetails = new List<Result>();

        if( companyCollections.size() == 0 ){
            Integer offsetVal = 0;
            Integer limitVal = 100;
            Boolean isLoop = true;

            while(isLoop){
                String append = '/collections/company?' + 'limit=' + limitVal + '&offset=' + offsetVal;
                Http http = new Http();
                HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
                if(res.getStatusCode() == 200){
                    Response getData = (Response) JSON.deserialize(res.getBody(), Response.class);
                    if(!getData.results.isEmpty()){
                        offsetVal += 100;
                        for(Result result : getData.results){
                            if(result.Id == collectionId){
                                resDetails.add(result);
                                break;
                            }
                        }
                    }else{
                        isLoop = false;
                    }
                }else{
                    isLoop = false;
                }
                
                if(Test.isRunningTest()){
                    isLoop = false;
                }
            }

            System.debug('resDetails' + resDetails);
        }

        return new Detail(companyCollections.size() > 0, resDetails);
    }

    public class Response {
        @AuraEnabled
        public Meta meta {get; set;}
        @AuraEnabled
        public List<Result> results {get; set;}
    }

    public class Meta {
        @AuraEnabled
        public Integer total {get; set;}
        @AuraEnabled
        public Integer offset {get; set;}
        @AuraEnabled
        public Integer count {get; set;}
    }

    public class Detail {
        @AuraEnabled
        public Boolean isExist {get; set;}
        @AuraEnabled
        public List<Result> resDetails {get; set;}

        public Detail(Boolean isExist, List<Result> resDetails){
            this.isExist = isExist;
            this.resDetails = resDetails;
        }
    }

    public class Result {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Integer count {get; set;}
    }

    public class SyncResponse {
        @AuraEnabled
        public Boolean isSuccess {get; set;}
        @AuraEnabled
        public String message {get; set;}
        public SyncResponse(Boolean isSuccess, String message){
            this.isSuccess = isSuccess;
            this.message = message;
        }
    }

}