public with sharing class CompanyHouseFilingHistoryOfficer {

    private static Company_House_API__c settings = Company_House_API__c.getOrgDefaults();

    @AuraEnabled
    public static String getCompanyName(String recordId){
        String compName = [SELECT Name, Company_registration_number__c FROM Account WHERE Id =: recordId].Name;
        return compName;
    }

    @AuraEnabled
    public static String getCompanyNumber(String recordId){
        String compNumber = [SELECT Company_registration_number__c FROM Account WHERE Company_registration_number__c != NULL AND Id =: recordId].Company_registration_number__c;
        return compNumber;
    }
    

    @AuraEnabled
    public static FilingHistoryLWCWrapper getFilingHistory(String companyHouseName){
        
        String companyHouseNumber = '';

        //SEARCH COMPANY BY COMPANY NAME
        HttpRequest req = new HttpRequest();
        String endpoint = settings.CompanyEndPoint__c+'/search/companies?q='+EncodingUtil.urlEncode(companyHouseName,'UTF-8');
        System.debug('endpoint: '+endpoint);
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', settings.Authorization__c);

        Http httpSearch = new Http();
        HttpResponse searchResponse = httpSearch.send(req);

        ResponseWrapper result = new ResponseWrapper();
        result.status = searchResponse.getStatus();
        result.statusCode = searchResponse.getStatusCode();

        if(searchResponse.getStatus() == 'OK' && searchResponse.getStatusCode() == 200){
            result.body = searchResponse.getBody();
            SearchCompanyWrapper results = (SearchCompanyWrapper) JSON.deserialize(result.body, SearchCompanyWrapper.class);
            if(!results.items.isEmpty()){
                companyHouseNumber = results.items[0].company_number;
            }
        }

        System.debug('CompanyHouseNumber:: ' + companyHouseNumber);

        //GET FILING HISTORY
        FilingHistoryLWCWrapper wrap = new FilingHistoryLWCWrapper();
        wrap.isFound = false;
        wrap.items = new List<FileItemsLWCHandler>();

        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('GET');
        httpReq.setEndPoint(settings.CompanyEndPoint__c + '/company/'+companyHouseNumber+'/filing-history');
        httpReq.setHeader('Authorization', settings.Authorization__c);
        httpReq.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse httpRes = http.send(httpReq);
        if(httpRes.getStatusCode() == 200){
            String apiDetails = httpRes.getBody().replaceAll('"date"', '"dateVal"');
            FilingHistoryWrapper getData = (FilingHistoryWrapper) JSON.deserialize(apiDetails, FilingHistoryWrapper.class);
            if(getData != null){
                if(getData.items != null){
                    if(!getData.items.isEmpty()){
                        wrap.isFound = true;
                        List<FileItemsLWCHandler> wrapItems = new List<FileItemsLWCHandler>();
                        for(FileItemsHandler item : getData.items){
                            FileItemsLWCHandler wrapItem = new FileItemsLWCHandler();
                            wrapItem.actionDate = item.dateVal;
                            wrapItem.type = item.type;
                            wrapItem.description = (isValid(item.description)) ? item.description.replaceAll('-', ' ') : '';
                            wrapItem.downloadURL = 'https://beta.companieshouse.gov.uk/company/'+companyHouseNumber+'/filing-history/'+item.transaction_id+'/document?format=pdf&download=0';
                            wrapItems.add(wrapItem);
                        }
                        wrap.items = wrapItems;
                    }
                }
            }
        }
        return wrap;
    }

    // @AuraEnabled
    // public static FilingHistoryLWCWrapper getFilingHistory(String companyHouseNumber){
    //     Company_House_API__c companyHouseApi = Company_House_API__c.getOrgDefaults();

    //     FilingHistoryLWCWrapper wrap = new FilingHistoryLWCWrapper();
    //     wrap.isFound = false;
    //     wrap.items = new List<FileItemsLWCHandler>();

    //     HttpRequest httpReq = new HttpRequest();
    //     httpReq.setMethod('GET');
    //     httpReq.setEndPoint(companyHouseApi.CompanyEndPoint__c + '/company/'+companyHouseNumber+'/filing-history');
    //     httpReq.setHeader('Authorization', companyHouseApi.Authorization__c);
    //     httpReq.setHeader('Accept', 'application/json');

    //     Http http = new Http();
    //     HttpResponse httpRes = http.send(httpReq);
    //     if(httpRes.getStatusCode() == 200){
    //         String apiDetails = httpRes.getBody().replaceAll('"date"', '"dateVal"');
    //         FilingHistoryWrapper getData = (FilingHistoryWrapper) JSON.deserialize(apiDetails, FilingHistoryWrapper.class);
    //         if(getData != null){
    //             if(getData.items != null){
    //                 if(!getData.items.isEmpty()){
    //                     wrap.isFound = true;
    //                     List<FileItemsLWCHandler> wrapItems = new List<FileItemsLWCHandler>();
    //                     for(FileItemsHandler item : getData.items){
    //                         FileItemsLWCHandler wrapItem = new FileItemsLWCHandler();
    //                         wrapItem.actionDate = item.dateVal;
    //                         wrapItem.type = item.type;
    //                         wrapItem.description = (isValid(item.description)) ? item.description.replaceAll('-', ' ') : '';
    //                         wrapItem.downloadURL = 'https://beta.companieshouse.gov.uk/company/'+companyHouseNumber+'/filing-history/'+item.transaction_id+'/document?format=pdf&download=0';
    //                         wrapItems.add(wrapItem);
    //                     }
    //                     wrap.items = wrapItems;
    //                 }
    //             }
    //         }
    //     }
    //     return wrap;
    // }

    public static Boolean isValid(Object obj){
        Boolean isValid = false;
        if(obj instanceof String){
            if(obj != null && obj != ''){
                isValid = true;
            }
        }else{
            if(obj != null){
                isValid = true;
            }
        }
        return isValid;
    }

    public class FilingHistoryWrapper{
        @AuraEnabled
        public List<FileItemsHandler> items;
    }

    public class FileItemsHandler{
        @AuraEnabled
        public String dateVal;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String transaction_id;
    }

    public class FilingHistoryLWCWrapper{
        @AuraEnabled
        public Boolean isFound;
        @AuraEnabled
        public List<FileItemsLWCHandler> items;
    }

    public class FileItemsLWCHandler{
        @AuraEnabled
        public String actionDate;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String downloadURL;
    }

    public class ResponseWrapper {
        public String status;
        public Integer statusCode;
        public String body;
    }

    public class SearchCompanyWrapper{
        @AuraEnabled
        public List<ItemHandler> items;
    }

    public class ItemHandler{
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String company_number;
        @AuraEnabled
        public String company_status;
    }
}