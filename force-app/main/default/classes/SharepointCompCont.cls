public class SharepointCompCont {
   
    public static String getNewAccessToken(){
        HttpResponse httpRes = SharepointAPIUtility.getAccessToken();
        String accessToken = '';
        if(httpRes.getStatusCode() == 200){
            AccessTokenResponse clientResultWrap = (AccessTokenResponse)JSON.deserialize(httpRes.getBody(), AccessTokenResponse.class);
            accessToken = clientResultWrap.access_token;
        }
        return accessToken;
    }

    public static void updateSharepointAccessToken(Id sharepointId, String accessToken){
        Sharepoint_API__c sharepointAPI = new Sharepoint_API__c(Id = sharepointId);
        sharepointAPI.access_token__c = accessToken;
        update sharepointAPI;
    }

    @AuraEnabled
    public static String getDriveItemId(Id recordId){
        if(recordId.getsobjecttype() == Schema.Account.getSObjectType()){
            return  [SELECT Id, Sharepoint_Folder_ID__c FROM Account WHERE Id =: recordId].Sharepoint_Folder_ID__c;
        }
        else if(recordId.getsobjecttype() == Schema.Case.getSObjectType()){
            return  [SELECT Id, Sharepoint_Folder_ID__c FROM Case WHERE Id =: recordId].Sharepoint_Folder_ID__c;
        }
        return '';
    }

    @AuraEnabled
    public static Boolean getSecurePublicGroup(){
        try {
            List<GroupMember> secureGroupMember = [SELECT Id, GroupId, Group.Name, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Secure Public Group' AND UserOrGroupId =: UserInfo.getUserId()];
            return !secureGroupMember.isEmpty();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DriveItemDetails> getPathDriveItems(Id recordId){
        try {
            String driveItemId = '';
            if(recordId.getsobjecttype() == Schema.Account.getSObjectType()){
                driveItemId = [SELECT Id, Sharepoint_Folder_ID__c FROM Account WHERE Id =: recordId].Sharepoint_Folder_ID__c;
            }
            else if(recordId.getsobjecttype() == Schema.Case.getSObjectType()){
                driveItemId = [SELECT Id, Sharepoint_Folder_ID__c FROM Case WHERE Id =: recordId].Sharepoint_Folder_ID__c;
            }
            if(driveItemId != '' && driveItemId != null){
                List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
                String accessToken = sharepointAPIlist.get(0).access_token__c;
                if(!sharepointAPIlist.isEmpty()){
                    Boolean isUpdateAccessToken = false;
                    HttpResponse httpRes = SharepointAPIUtility.getChildrenFromDriveItemId(accessToken, driveItemId);
                    if(httpRes.getStatusCode() == 401){
                        accessToken = getNewAccessToken();
                        httpRes = SharepointAPIUtility.getChildrenFromDriveItemId(accessToken, driveItemId);
                        isUpdateAccessToken = true;
                    }
        
                    if(httpRes.getStatusCode() == 200){
                        DriveItemResponse driveResp = (DriveItemResponse)JSON.deserialize(httpRes.getBody(), DriveItemResponse.class);
                        if(!driveResp.value.isEmpty()){
                            for(DriveItemDetails driveItem: driveResp.value){
                                driveItem.isFolder = (driveItem.folder != null) ? true: false;
                                driveItem.sizeToDisplay = (driveItem.isFolder) ? String.valueOf(driveItem.folder.childCount) + ' items' : String.valueOf((driveItem.size / 1024).setScale(1, RoundingMode.HALF_UP)) + ' KB';

                                driveItem.modifiedByName = driveItem.lastModifiedBy?.user?.displayName;
                                driveItem.createdByName = driveItem.createdBy?.user?.displayName;

                                driveItem.currentDriveItemId = driveItem.parentReference?.id;
                            }

                            if(isUpdateAccessToken){
                                updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                            }
                            
                            return driveResp.value;
                        }
                    }
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DriveItemDetails> getChildrenFromDriveId(String driveItemId, Id recordId){
        try {
            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;
            if(!sharepointAPIlist.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SharepointAPIUtility.getChildrenFromDriveItemId(accessToken, driveItemId);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SharepointAPIUtility.getChildrenFromDriveItemId(accessToken, driveItemId);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200){
                    DriveItemResponse driveResp = (DriveItemResponse)JSON.deserialize(httpRes.getBody(), DriveItemResponse.class);
                    if(!driveResp.value.isEmpty()){
                        for(DriveItemDetails driveItem: driveResp.value){
                            driveItem.isFolder = (driveItem.folder != null) ? true: false;
                            Decimal fileSizeInKB = driveItem.size / 1024;
                            driveItem.sizeToDisplay = (driveItem.isFolder) ? String.valueOf(driveItem.folder.childCount) + ' items' : String.valueOf((driveItem.size / 1024).setScale(1, RoundingMode.HALF_UP)) + ' KB';

                            driveItem.modifiedByName = driveItem.lastModifiedBy?.user?.displayName;
                            driveItem.createdByName = driveItem.createdBy?.user?.displayName;
                        }

                        if(isUpdateAccessToken){
                            updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                        }

                        return driveResp.value;
                    }
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' - ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static Boolean uploadDocument(Id recordId, String driveItemId, String fileDataList){
        List<FileWrapper> fileWrappList = (List<FileWrapper>) JSON.deserialize(fileDataList, List<FileWrapper>.class);

        System.debug('@@@ fileWrappList: ' + fileWrappList);
        if(!fileWrappList.isEmpty()){
            FileWrapper fileWrapp = fileWrappList.get(0);
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(fileWrapp.base64);
            cv.Title = fileWrapp.filename;
            cv.PathOnClient = fileWrapp.filename;
            cv.ContentLocation = 'S';
            cv.SharingOption = 'A';
            cv.Origin = 'C';

            if(driveItemId != null){
                return uploadFileFromDriveId(driveItemId, cv, recordId);
            }
        }
        return false;
    }

    @AuraEnabled
    public static Boolean uploadFileFromDriveId(String driveItemId, ContentVersion cv, Id recordId){
        try {
            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;

            if(!sharepointAPIlist.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, driveItemId, cv.Title, cv.VersionData);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, driveItemId, cv.Title, cv.VersionData);
                    isUpdateAccessToken = true;
                }

                if(isUpdateAccessToken){
                    updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                }
    
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                    return true;
                    // Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                    // String webUrl = (String) responseMap.get('webUrl');
                    // webUrl = EncodingUtil.urlDecode(webUrl, 'UTF-8');
                    // cv.Sharepoint_File_Address__c = webUrl;
                    // cv.Sharepoint_File_ID__c =  (String) responseMap.get('id');
                    // insert cv;

                    // Id contentDocId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;

                    // ContentDocumentLink cdl = new ContentDocumentLink();
                    // cdl.ContentDocumentId = contentDocId;
                    // cdl.LinkedEntityId = recordId;
                    // cdl.Visibility = 'AllUsers';
                    // cdl.ShareType= 'V';
                    // insert cdl;

                    // return true;
                }
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class AccessTokenResponse{
        public String access_token;
    }

    public class DriveItemResponse{
        @AuraEnabled public List<DriveItemDetails> value;
    }

    public class DriveItemDetails{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String webUrl;
        @AuraEnabled public Decimal size;
        @AuraEnabled public String sizeToDisplay;
        @AuraEnabled public FolderDetails folder;
        @AuraEnabled public Boolean isFolder;
        @AuraEnabled public String modifiedByName;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String currentDriveItemId;

        @AuraEnabled public UserInfoDetail createdBy;
        @AuraEnabled public UserInfoDetail lastModifiedBy;
        @AuraEnabled public ParentInfo parentReference;
    }

    public class FolderDetails{
        @AuraEnabled public Decimal childCount;
    }

    public class UserInfoDetail{
        public UserDetails user;
    }

    public class UserDetails{
        public String displayName;
    }

    public class FileWrapper{
        @AuraEnabled public String filename;
        @AuraEnabled public String base64;
        @AuraEnabled public String fileSection;
        @AuraEnabled public String caseFieldAPI;
    }

    public class ParentInfo{
        public String id;
    }
}