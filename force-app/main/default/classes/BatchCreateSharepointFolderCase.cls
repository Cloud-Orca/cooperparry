global class BatchCreateSharepointFolderCase implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Set<Id> caseIds;

    global BatchCreateSharepointFolderCase(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Subject FROM Case WHERE Id IN: caseIds]);
    }

    global void execute(Database.BatchableContext BC, List<Case> caseList){
        try {
            Case caseRec = caseList.get(0);

            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;

            if(!sharepointAPIlist.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SharepointAPIUtility.createNewFolderFromParentDocument(accessToken, caseRec.Subject);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SharepointAPIUtility.createNewFolderFromParentDocument(accessToken, caseRec.Subject);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                    String folderId = (String) responseMap.get('id');
                    caseRec.Sharepoint_Folder_ID__c = folderId;

                    HttpResponse httpRes2 = SharepointAPIUtility.createNewFolderFromDriveId(accessToken, folderId, 'Public Folder');
                    if(httpRes2.getStatusCode() == 200 || httpRes2.getStatusCode() == 201){
                        responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes2.getBody());
                        caseRec.Sharepoint_Public_Folder_ID__c = (String) responseMap.get('id');
                        caseRec.Sharepoint_Public_Folder_URL__c = (String) responseMap.get('webUrl');
                    } 

                    httpRes2 = SharepointAPIUtility.createNewFolderFromDriveId(accessToken, folderId, 'Secure Folder');
                    if(httpRes2.getStatusCode() == 200 || httpRes2.getStatusCode() == 201){
                        responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes2.getBody());
                        caseRec.Sharepoint_Secure_Folder_ID__c = (String) responseMap.get('id');
                        caseRec.Sharepoint_Secure_Folder_URL__c = (String) responseMap.get('webUrl');
                    } 
                    
                    if(isUpdateAccessToken){
                        updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                    }

                    update caseRec;
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getLineNumber());
        }
    }

    global void finish(Database.BatchableContext BC){
    }

    public static void updateSharepointAccessToken(Id sharepointId, String accessToken){
        Sharepoint_API__c sharepointAPI = new Sharepoint_API__c(Id = sharepointId);
        sharepointAPI.access_token__c = accessToken;
        update sharepointAPI;
    }

    public static String getNewAccessToken(){
        HttpResponse httpRes = SharepointAPIUtility.getAccessToken();
        String accessToken = '';
        if(httpRes.getStatusCode() == 200){
            AccessTokenResponse clientResultWrap = (AccessTokenResponse)JSON.deserialize(httpRes.getBody(), AccessTokenResponse.class);
            accessToken = clientResultWrap.access_token;
        }
        return accessToken;
    }

    public class AccessTokenResponse{
        public String access_token;
    }
}