public with sharing class GetBeauhurstCompanies {
    @AuraEnabled
    public static void callBatch(String collectionId){
        Database.executeBatch(new GetCompanyCollectionBatch(collectionId));
    }

    @AuraEnabled
    public static Response getTotal(String collectionId){
        Response response = new Response();

        String append = '/companies/search?collection_id=' + collectionId;
        Http http = new Http();
        HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));

        if(res.getStatusCode() == 200){
            response = (Response) JSON.deserialize(res.getBody(), Response.class);
        } 

        System.debug('response' + response);

        return response;
    }

    public class Response {
        @AuraEnabled
        public Meta meta {get; set;}
        @AuraEnabled
        public List<Result> results {get; set;}
    }

    public class Result {
        @AuraEnabled
        public String id {get; set;}
    }

    public class Meta {
        @AuraEnabled
        public Integer total {get; set;}
    }
}