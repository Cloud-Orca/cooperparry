public with sharing class SharepointUploadFileInvocable {
   

    @InvocableMethod(label='Upload File to Sharepoint')    
    public static List<ResponseFlowParam> uploadFileToSharepoint(List<RequestPublicFlowParam> requestList) {
        List<ResponseFlowParam> resList = new List<ResponseFlowParam>();
        ResponseFlowParam newRes = new ResponseFlowParam();

        List<String> fileIds = requestList[0].fileIds;
        String caseId = requestList[0].caseId;

        List<ContentVersion> cvList = [SELECT Id, Title, VersionData, FileExtension, PathOnClient FROM ContentVersion WHERE Id IN: fileIds];

        List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
        String accessToken = sharepointAPIlist.get(0).access_token__c;

        if(!sharepointAPIlist.isEmpty()){
            String publicFolderId = [SELECT Id, Sharepoint_Secure_Folder_ID__c FROM Case WHERE Id =: caseId].Sharepoint_Secure_Folder_ID__c;
            if(publicFolderId != null){
                Boolean isUpdateAccessToken = false;
                for(ContentVersion cv: cvList){
                    HttpResponse httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, publicFolderId, cv.PathOnClient, cv.VersionData);
                    if(httpRes.getStatusCode() == 401){
                        accessToken = SharepointCompCont.getNewAccessToken();
                        httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, publicFolderId, cv.PathOnClient, cv.VersionData);
                        isUpdateAccessToken = true;
                    }
                }

                if(isUpdateAccessToken){
                    SharepointCompCont.updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                }

                newRes.isSuccess = true;
            }
        }
        resList.add(newRes);
        if(!newRes.isSuccess){
            throw new CustomException('Error Uploading File in Sharepoint');
        }
        return resList;
        // ContentVersion cv = [SELECT Id, Title, VersionData, FileExtension, PathOnClient FROM ContentVersion WHERE Id =: fileId];

        
        // String accessToken = sharepointAPIlist.get(0).access_token__c;
        // if(!sharepointAPIlist.isEmpty()){
        //     String publicFolderId = [SELECT Id, Sharepoint_Public_Folder_ID__c FROM Case WHERE Id =: caseId].Sharepoint_Public_Folder_ID__c;
        //     if(publicFolderId != null){
        //         Boolean isUpdateAccessToken = false;
        //         HttpResponse httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, publicFolderId, cv.PathOnClient, cv.VersionData);
        //         if(httpRes.getStatusCode() == 401){
        //             accessToken = SharepointCompCont.getNewAccessToken();
        //             httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, publicFolderId, cv.PathOnClient, cv.VersionData);
        //             isUpdateAccessToken = true;
        //         }

        //         if(isUpdateAccessToken){
        //             SharepointCompCont.updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
        //         }

        //         if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
        //             newRes.isSuccess = true;
        //         }
        //         else{
        //             newRes.isSuccess = false;
        //         }
        //     }
        // }
        // resList.add(newRes);

        // if(!newRes.isSuccess){
        //     throw new CustomException('Error Uploading File in Sharepoint: fileId: ' + fileId);
        // }
        // return resList;
    }

    public class CustomException extends Exception {}

    public class RequestPublicFlowParam{
        @InvocableVariable(label='File Ids')
        public List<String> fileIds;

        @InvocableVariable(label='Case Id')
        public String caseId;
    }

    public class ResponseFlowParam {
        @InvocableVariable(label='Is Success?')
        public Boolean isSuccess;
    }
}