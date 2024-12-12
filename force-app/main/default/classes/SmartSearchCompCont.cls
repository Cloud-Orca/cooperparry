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
    public static UKIndividualResponse searchNameToSmartSearch(Id recordId, Beneficial_Owner__c benOwnerToSearch){
        try {
            UKIndividualResponse resp = new UKIndividualResponse();
            resp.isPass = false;
            resp.subjectId = '';

            List<Smart_Search_API__c> smartSearchAPIList = [SELECT Id, access_token__c FROM Smart_Search_API__c LIMIT 1];
            String accessToken = smartSearchAPIList.get(0).access_token__c;
            if(!smartSearchAPIList.isEmpty()){
                Boolean isUpdateAccessToken = false;

                HttpResponse httpRes = (benOwnerToSearch.Search_ID__c != null) ? SmartSearchAPIUtility.getUKSummary(accessToken, benOwnerToSearch.Search_ID__c) : SmartSearchAPIUtility.postSearchUKIndividual(accessToken, benOwnerToSearch);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = (benOwnerToSearch.Search_ID__c != null) ? SmartSearchAPIUtility.getUKSummary(accessToken, benOwnerToSearch.Search_ID__c) : SmartSearchAPIUtility.postSearchUKIndividual(accessToken, benOwnerToSearch);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                    PostSearchDetails postSearchDetail = (PostSearchDetails)JSON.deserialize(httpRes.getBody(), PostSearchDetails.class);
                    String searchSubjectId = '';
                    String searchId = '';
                    String outcome = '';
                    if(!postSearchDetail.included.isEmpty()){
                        for(IncludedDetails include: postSearchDetail.included){
                            if(include.type == 'search-subject'){
                                searchSubjectId = include.id;
                            }
                            if(include.type == 'uk-individual-result'){
                                searchId = include.id;
                                outcome = include.attributes.outcome;
                            }
                        }
                    }   

                    benOwnerToSearch.Subject_ID__c = searchSubjectId;
                    benOwnerToSearch.Search_ID__c = searchId;
                    String finalOutcome = (outcome == 'pass') ? 'Pass' : outcome;
                    finalOutcome = (outcome == 'refer') ? 'Refer' : outcome;
                    benOwnerToSearch.Smart_Search_Status__c = finalOutcome;

                    resp.isPass = (benOwnerToSearch.Smart_Search_Status__c == 'Pass') ? true : false;
                    resp.subjectId = benOwnerToSearch.Subject_ID__c;

                    Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();
                    benOwnerToSearch.Smart_Search_Link__c = smartSearchSetting.smart_search_url__c + '/subjects/' + searchSubjectId + '/' + searchId;
                    update benOwnerToSearch;

                    Case caseToUpdate = new Case(Id = recordId);
                    caseToUpdate.Case_Referred__c = (benOwnerToSearch.Smart_Search_Status__c == 'Pass') ? false: true;
                    update caseToUpdate;
                    
                    if(isUpdateAccessToken){
                        updateSmartSearchAccessToken(smartSearchAPIList.get(0).Id, accessToken);
                    }
                }
            }
            return resp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void getDocument(Id recordId, String benOwnerId, String subjectId){
        try {
            List<Smart_Search_API__c> smartSearchAPIList = [SELECT Id, access_token__c FROM Smart_Search_API__c LIMIT 1];
            String accessToken = smartSearchAPIList.get(0).access_token__c;
            if(!smartSearchAPIList.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SmartSearchAPIUtility.getDocument(accessToken, subjectId);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SmartSearchAPIUtility.getDocument(accessToken, subjectId);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                    DocumentResponse docResp = (DocumentResponse)JSON.deserialize(httpRes.getBody(), DocumentResponse.class);
                    if(docResp.data != null){
                        if(docResp.data.attributes != null){
                            if(docResp.data.attributes.base64 != null){
                                Beneficial_Owner__c benOwner = [SELECT Id, First_Name__c, Middle_Name__c, Last_Name__c, Search_ID__c FROM Beneficial_Owner__c WHERE Id =: benOwnerId];

                                String fileName = benOwner.First_Name__c;
                                fileName += (benOwner.Middle_Name__c != null) ? '-' + benOwner.Middle_Name__c + '-' + benOwner.Last_Name__c : '-' + benOwner.Last_Name__c;
                                fileName += '-' + benOwner.Search_ID__c;

                                ContentVersion cv = new ContentVersion();
                                cv.VersionData = EncodingUtil.base64Decode(docResp.data.attributes.base64);
                                cv.Title = fileName + '.pdf';
                                cv.PathOnClient = fileName;
                                cv.ContentLocation = 'S';
                                cv.SharingOption = 'A';
                                cv.Origin = 'C';
                                insert cv;

                                Id cdId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;

                                ContentDocumentLink cdl = new ContentDocumentLink();
                                cdl.ContentDocumentId = cdId;
                                cdl.LinkedEntityId = recordId;
                                cdl.Visibility = 'AllUsers';
                                cdl.ShareType= 'V';
                                insert cdl;
                            }
                        }
                    }

                    if(isUpdateAccessToken){
                        updateSmartSearchAccessToken(smartSearchAPIList.get(0).Id, accessToken);
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean getLifeCycleRole(Id recordId){
        try {
            Id accountId = [SELECT Id, AccountId FROM Case WHERE Id =: recordId].AccountId;
            if(accountId != null){
                List<AccountTeamMember> accTeamMemberLifeCycle = [SELECT Id FROM AccountTeamMember WHERE AccountId =: accountId AND TeamMemberRole = 'Lifecycle Coordinator'];
                return !accTeamMemberLifeCycle.isEmpty();
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Beneficial_Owner__c> getAllBeneficialOwners(Id recordId){
        try {
            List<Beneficial_Owner__c> beneficialOwnerList = new List<Beneficial_Owner__c>();

            Set<Id> benOwnerIds = new Set<Id>();
            for(Beneficial_Owner_Cases__c benOwnerCase: [SELECT Id, Beneficial_Owner__c FROM Beneficial_Owner_Cases__c where Case__c =: recordId]){
                benOwnerIds.add(benOwnerCase.Beneficial_Owner__c);
            }

            if(!benOwnerIds.isEmpty()){
                beneficialOwnerList = [SELECT Id, Account__c, Address_Line_1__c, Address_Line_2__c, Building_Name_Number__c, Case__c, County__c, 
                                            Date_of_Birth__c, First_Name__c, Flat__c, Last_Name__c, Middle_Name__c, Months_at_this_address__c, Postcode__c,
                                            Search_ID__c, Search_Reference__c, Smart_Search_Link__c, Smart_Search_Status__c, Subject_ID__c, Title__c, Town__c, 
                                            Years_at_this_address__c
                                            FROM Beneficial_Owner__c 
                                            WHERE Id IN: benOwnerIds ORDER BY CreatedDate ASC];
            }
            return beneficialOwnerList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<PicklistWrapp> getPicklistValues(String sObjectAPI, String fieldAPI){
        List<PicklistWrapp> plValues = new List<PicklistWrapp>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectAPI);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get(fieldAPI).getDescribe();
        List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry plv: picklistvalues) {
            PicklistWrapp wrapp = new PicklistWrapp();
            wrapp.label = plv.getLabel();
            wrapp.value = plv.getValue();
            plValues.add(wrapp);
        }
        return plValues;
    }

    public class PicklistWrapp{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
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
        public AttributeDetails2 attributes;
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
    
    public class AttributeDetails2{
        public String outcome;
        public String base64;
    }

    public class SmartSearchResult{
        @AuraEnabled public Boolean isPEP;
        @AuraEnabled public Boolean isRCA;
    }

    public class UKIndividualResponse{
        @AuraEnabled public Boolean isPass;
        @AuraEnabled public String subjectId;
    }

    public class DocumentResponse{
        public DataDetails data;
    }

    public class DataDetails{
        public AttributeDetails2 attributes;
    }
}