public class SmartSearchCompCont {

    public static String getNewAccessToken(){
        HttpResponse httpRes = SmartSearchAPIUtility.getAccessToken();
        String accessToken = '';
        if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
            AccessTokenResponse clientResultWrap = (AccessTokenResponse)JSON.deserialize(httpRes.getBody(), AccessTokenResponse.class);
            accessToken = clientResultWrap.meta.token;
        }
        return accessToken;
    }

    public static void updateSmartSearchAccessToken(Id smartSearchId, String accessToken){
        Smart_Search_API__c smartSearchAPI = new Smart_Search_API__c(Id = smartSearchId);
        smartSearchAPI.access_token__c = accessToken;
        update smartSearchAPI;
    }

    @AuraEnabled
    public static String searchNameToSmartSearch(Id recordId, String firstName, String middleName, String lastName){
        try {
            List<Smart_Search_API__c> smartSearchAPIList = [SELECT Id, access_token__c FROM Smart_Search_API__c LIMIT 1];
            String accessToken = smartSearchAPIList.get(0).access_token__c;
            if(!smartSearchAPIList.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SmartSearchAPIUtility.postSearchSubject(accessToken, firstName, middleName, lastName);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SmartSearchAPIUtility.postSearchSubject(accessToken, firstName, middleName, lastName);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                    PostSearchDetails postSearchDetail = (PostSearchDetails)JSON.deserialize(httpRes.getBody(), PostSearchDetails.class);
                    String searchSubjectId = '';
                    if(!postSearchDetail.included.isEmpty()){
                        for(IncludedDetails include: postSearchDetail.included){
                            if(include.type == 'search-subject'){
                                searchSubjectId = include.id;
                                break;
                            }
                        }
                    }   

                    if(isUpdateAccessToken){
                        updateSmartSearchAccessToken(smartSearchAPIList.get(0).Id, accessToken);
                    }

                    if(searchSubjectId != ''){
                        return searchSubjectId;
                    }
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static SmartSearchResult getWactchlistSummary(Id recordId, String searchSubjectId){
        try {
            SmartSearchResult result = new SmartSearchResult();
            result.isPEP = false;
            result.isRCA = false;

            List<Smart_Search_API__c> smartSearchAPIList = [SELECT Id, access_token__c FROM Smart_Search_API__c LIMIT 1];
            String accessToken = smartSearchAPIList.get(0).access_token__c;
            if(!smartSearchAPIList.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SmartSearchAPIUtility.getWatchList(accessToken, searchSubjectId);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SmartSearchAPIUtility.getWatchList(accessToken, searchSubjectId);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                    WatchListResponse watchlistResp = (WatchListResponse)JSON.deserialize(httpRes.getBody(), WatchListResponse.class);
                    Boolean isPEP = false;
                    Boolean isRCA = false;
                    if(!watchlistResp.data.isEmpty()){
                        for(WatchlistDetails watchlistDetail: watchlistResp.data){
                            if(watchlistDetail.attributes != null){
                                if(watchlistDetail.attributes.num_matches > 0){
                                    if(watchlistDetail.attributes.category == 'Politically Exposed Person (PEP)'){
                                        isPEP = true;
                                        result.isPEP = true;
                                    }
                                    if(watchlistDetail.attributes.category == 'Relative or Close Associate (RCA)'){
                                        isRCA = true;
                                        result.isRCA = true;
                                    }
                                }   
                            }
                        }
                    }

                    if(isPEP || isRCA){
                        Case caseToUpdate = new Case(Id = recordId);
                        caseToUpdate.PEP_RCA_Identified__c = true;
                        update caseToUpdate;
                    }

                    if(isUpdateAccessToken){
                        updateSmartSearchAccessToken(smartSearchAPIList.get(0).Id, accessToken);
                    }
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
   
    public class AccessTokenResponse{
        public AccessTokenDetails meta;
    }

    public class AccessTokenDetails{
        public String token;
    }

    public class PostSearchDetails{
        public List<IncludedDetails> included;
    }

    public class IncludedDetails{
        public String type;
        public String id;
    }

    public class WatchListResponse{
        public List<WatchlistDetails> data;
    }

    public class WatchlistDetails{
        public AttributeDetails attributes; 
    }

    public class AttributeDetails{
        public String category;
        public Decimal num_matches;
    }

    public class SmartSearchResult{
        @AuraEnabled public Boolean isPEP;
        @AuraEnabled public Boolean isRCA;
    }
}