public with sharing class CompaniesHouseController {

    public class ResponseWrapper {
        @AuraEnabled
        public String status;
        @AuraEnabled 
        public Integer statusCode;
        @AuraEnabled
        public String body;
    }

    private static Company_House_API__c settings = Company_House_API__c.getOrgDefaults();

    @AuraEnabled
    public static String getCompanyByName(String companyName){
        HttpRequest req = new HttpRequest();
        String endpoint = settings.CompanyEndPoint__c+'/search/companies?q='+EncodingUtil.urlEncode(companyName,'UTF-8');
        System.debug('endpoint: '+endpoint);
        req.setMethod('GET'); 
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', settings.Authorization__c);

        Http http = new Http();
        HttpResponse response = http.send(req);

        ResponseWrapper result = new ResponseWrapper();
        result.status = response.getStatus();
        result.statusCode = response.getStatusCode();

        if(response.getStatus() == 'OK' && response.getStatusCode() == 200){
            result.body = response.getBody();
        }

        System.debug('ResponseBody (getCompanyByName):: ' + result.body);
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static void savePdfFromUrl(List<FileWrapper> params, String recordId) {
        if( params.size() > 0 ){
            for( FileWrapper param : params ){
                savePdf(param.fileType, param.downloadURL, recordId);
            }
        }
    }

    @future(callout=true)
    public static void savePdf(String name, String pdfUrl, String recordId){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(pdfUrl);
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 302) {
            String redirectUrl = response.getHeader('Location');
            request.setEndpoint(redirectUrl);
            response = http.send(request);
        }

        if (response.getStatusCode() == 200) {
            // Upload files to sharepoint
            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;

            if(!sharepointAPIlist.isEmpty()){
                String publicFolderId = [SELECT Id, Sharepoint_Public_Folder_ID__c FROM Account WHERE Id =: recordId].Sharepoint_Public_Folder_ID__c;
                if(publicFolderId != null){
                    Boolean isUpdateAccessToken = false;
                    HttpResponse httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, publicFolderId, name + '.pdf', response.getBodyAsBlob());
                    if(httpRes.getStatusCode() == 401){
                        accessToken = SharepointCompCont.getNewAccessToken();
                        httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, publicFolderId, name + '.pdf', response.getBodyAsBlob());
                        isUpdateAccessToken = true;
                    }
    
                    if(isUpdateAccessToken){
                        SharepointCompCont.updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                    }
                }
            }

            // Create a ContentVersion to store the PDF
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = name;
            contentVersion.PathOnClient = name + '.pdf';
            contentVersion.VersionData = response.getBodyAsBlob();
            contentVersion.IsMajorVersion = true;
            insert contentVersion;

            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = contentDocumentId;
            link.LinkedEntityId = recordId; 
            link.ShareType = 'V'; 
            insert link;
        }
    }

    @AuraEnabled
    public static String getCompanyByNumber(String companyNum){
        HttpRequest req = new HttpRequest();
        String endpoint = settings.CompanyEndPoint__c+'/company/'+companyNum;
        System.debug('endpoint: '+endpoint);
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', settings.Authorization__c);

        Http http = new Http();
        HttpResponse response = http.send(req);

        ResponseWrapper result = new ResponseWrapper();
        result.status = response.getStatus();
        result.statusCode = response.getStatusCode();
        if(response.getStatus() == 'OK' && response.getStatusCode() == 200){
            result.body = response.getBody();
        } 
        System.debug('ResponseBody (getCompanyByNumber):: ' + result.body);
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String getCompanyOfficers(String companyNum){
        HttpRequest req = new HttpRequest();
        String endpoint = settings.CompanyEndPoint__c+'/company/'+companyNum+'/officers';
        System.debug('endpoint: '+endpoint);
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', settings.Authorization__c);

        Http http = new Http();
        HttpResponse response = http.send(req);

        ResponseWrapper result = new ResponseWrapper();
        result.status = response.getStatus();
        result.statusCode = response.getStatusCode();
        if(response.getStatus() == 'OK' && response.getStatusCode() == 200){
            result.body = response.getBody();
        } 
        
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String getCompanyPeronsSignificantControl(String companyNum){
        HttpRequest req = new HttpRequest();
        String endpoint = settings.CompanyEndPoint__c+'/company/'+companyNum+'/persons-with-significant-control';
        System.debug('endpoint: '+endpoint);    
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', settings.Authorization__c);

        Http http = new Http();
        HttpResponse response = http.send(req);

        ResponseWrapper result = new ResponseWrapper();
        result.status = response.getStatus();
        result.statusCode = response.getStatusCode();
        if(response.getStatus() == 'OK' && response.getStatusCode() == 200){
            result.body = response.getBody();
        } 
        System.debug('getCompanyPeronsSignificantControl' + result.body);
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String getFillingHistories(String companyNum){
        HttpRequest req = new HttpRequest();
        String endpoint = settings.CompanyEndPoint__c+'/company/'+companyNum+'/filing-history';
        System.debug('endpoint: '+endpoint);
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', settings.Authorization__c);

        Http http = new Http();
        HttpResponse response = http.send(req);

        ResponseWrapper result = new ResponseWrapper();
        result.status = response.getStatus();
        result.statusCode = response.getStatusCode();
        if(response.getStatus() == 'OK' && response.getStatusCode() == 200){
            result.body = response.getBody();
        } 
        
        System.debug('getFillingHistories' + result.body);
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static Map<String, Officer__c> getExactMatchContacts(List<String> officerNums, Id recordId){
        System.debug('@@@ getExactMatchContacts');
        Map<String, Officer__c> officerKeyToOffMap = new Map<String, Officer__c>();

        Id accountId;
        if(recordId.getsobjecttype() == Schema.Account.getSObjectType()){
            accountId = recordId;
        }
        else if(recordId.getsobjecttype() == Schema.Opportunity.getSObjectType()){
            Id accId = [SELECT Id, AccountId FROM Opportunity WHERE Id =: recordId].AccountId;
            accountId = accId;
        }
        System.debug('@@@ accountId: ' + accountId);

        for(Officer__c off : [SELECT 
                                Id, 
                                First_Name__c, 
                                Last_Name__c,
                                Officer_Key__c
                            FROM 
                            Officer__c 
                            WHERE 
                                Officer_Key__c IN :officerNums
                            AND
                                Account__c =: accountId]){
            officerKeyToOffMap.put(off.Officer_Key__c, off);
            System.debug('@@@ off.Id: ' + off.Id);
        }

        return officerKeyToOffMap;
    }

     /*******************************************************************************
    * @description  Returns List of Officers searched in the input custom lookup
    *******************************************************************************/
    @AuraEnabled
    public static List<Officer__c> searchOfficer(List<String> searchKey){
        System.debug('searchKey:: ' + searchKey);

        List<Officer__c> allSearchedOfficers = new List<Officer__c>();

        List<String> contactNames = new List<String>();
        for(String keyName : searchKey){
            contactNames.addAll(keyName.split(', '));
        }
        
        List<String> searchTerms = new List<String>();
        for(String name : contactNames) {
            List<String> words = name.split(' ');
            searchTerms.addAll(words);
        }

        System.debug('contactNames:: ' + contactNames);
        System.debug('searchTerms:: ' + searchTerms);

        //ACCESS FIELD API NAME AND LABEL FROM METADATA
        List<Companies_House_Setting__mdt> metadataSettings = [SELECT Id, DeveloperName, Field_Label__c, FieldAPIName__c  FROM Companies_House_Setting__mdt ORDER BY DeveloperName ASC];
        Map<String, String> fieldAPIToLabelMap = new Map<String, String>();
        for (Companies_House_Setting__mdt setting : metadataSettings) {
            fieldAPIToLabelMap.put(setting.FieldAPIName__c, setting.Field_Label__c);
        }
        System.debug('fieldAPIToLabelMap: ' + fieldAPIToLabelMap);

        String searchQuery = 'SELECT Id, Name';
        for (String apiName : fieldAPIToLabelMap.keySet()) {
            searchQuery += ', ' + apiName;
        }
        searchQuery += ' FROM Officer__c WHERE ';
        

        for (Integer i = 0; i < searchTerms.size(); i++) {
            System.debug('searchTerms: ' + searchTerms);
            System.debug('searchTerms[i]: ' + searchTerms[i]);
            if (i > 0) {
                searchQuery += ' OR ';
            }
            searchQuery += 'First_Name__c LIKE \'%' + searchTerms[i] + '%\' OR Last_Name__c LIKE \'%' + searchTerms[i] + '%\'';
        }

        System.debug('searchQuery: ' + searchQuery);
        try{
            allSearchedOfficers = Database.query(searchQuery);
            System.debug('allSearchedOfficers: ' + allSearchedOfficers);
        } catch (Exception e) {
            System.debug('Error in searchOfficer: ' + e.getMessage());
        }

        return allSearchedOfficers;
    }

    /*******************************************************************************
    * @description  4th Step : Merging Searched and Created Officers
    *******************************************************************************/
    @AuraEnabled
    public static List<Officer__c> mergeSelectedOfficers(List<Id> existingOfficerIds, List<Id> searchedofficerIds, List<Officer__c> createdContactList, List<Id> matchofficerIds){
        System.debug('Existing Officer Ids:: ' + existingOfficerIds);
        System.debug('Searched Contact Ids:: ' + searchedofficerIds);
        System.debug('New Contacts to Insert:: ' + createdContactList);
        System.debug('Match Contact Ids:: ' + matchofficerIds);

        try {
            // Set<Id> createdIdSet = new Set<Id>();
            // for (Contact createdContacts : contactList) {
            //     createdIdSet.add(createdContacts.Id);
            // }

            List<Officer__c> mergedOfficerList = [ 
                SELECT Id, Name, Account__c, Account__r.Name, First_Name__c, Middle_Name__c, Last_Name__c, Officer_Key__c, Title__c, Resident_Country__c, Nationality__c, MailingStreet__c, MailingCity__c, MailingState__c, MailingCountry__c, MailingPostalCode__c, Date_of_Birth_Month__c, Date_of_Birth_Year__c, Birthdate__c
                FROM Officer__c 
                WHERE Id IN : existingOfficerIds OR Id IN :searchedofficerIds OR Id IN :createdContactList OR Id IN : matchofficerIds
                ORDER BY CreatedDate DESC
            ];

            System.debug('Merged Officer__c List:: ' + mergedOfficerList);
            System.debug('mergedOfficerList.size:: ' + mergedOfficerList.size());
            return mergedOfficerList;
        } catch (Exception e) {
            System.debug('Error in searchOfficer: ' + e.getMessage());
            return new List<Officer__c>();
        } 
    }

    /*******************************************************************************
    * @description  Final Step : Updates Officers and Account Records to Match Companies House Data
    *******************************************************************************/
    @AuraEnabled
    public static List<Officer__c> updateAccountOfficerFields(Id accountId, String companyKey, String jsonString, List<Officer__c> officersForUpdates, String jsonOfficers, List<FileWrapper> params, List<PSCWrapper> pcsData ){
        
        System.debug('accountId:: ' + accountId);
        System.debug('companyKey:: ' + companyKey);
        System.debug('jsonString:: ' + jsonString);
        System.debug('officersForUpdates:: ' + officersForUpdates);
        System.debug('params:: ' + params);
        System.debug('pcsData:: ' + pcsData);
        List<Account> accountToUpdate = new List<Account>();
        List<Officer__c> officersToUpdate = new List<Officer__c>();
        List<Map<String, Object>> fieldsToUpdateList = new List<Map<String, Object>>();

        if(!officersForUpdates.isEmpty()){
            Set<Id> officerIds = new Set<Id>();
            for (Officer__c officer : officersForUpdates) {
                Map<String, Object> fieldsToUpdate = officer.getPopulatedFieldsAsMap();
                fieldsToUpdateList.add(fieldsToUpdate);
                officerIds.add(officer.Id);
            }
            System.debug('officerIds:: ' + officerIds);
            System.debug('fieldsToUpdateList:: ' + fieldsToUpdateList);
            
            List<Officer__c> updateCurrentOfficerList = [
                SELECT Id, Name, Last_Name__c, First_Name__c, Middle_Name__c, Salutation__c, Officer_Key__c, Title__c, Resident_Country__c, Nationality__c, MailingStreet__c, 
                    MailingCity__c, MailingState__c, MailingCountry__c, MailingPostalCode__c, Birthdate__c, Companies_House_Run__c, Companies_House_Run_Date__c,
                    Date_of_Birth_Year__c, Date_of_Birth_Month__c
                FROM Officer__c
                WHERE /*AccountId =: accountId AND*/ Id IN :officerIds /*AND Officer_Key__c != null*/
            ];
            System.debug('updateCurrentOfficerList:: ' + updateCurrentOfficerList);
            System.debug('updateCurrentOfficerList.size():: ' + updateCurrentOfficerList.size());

            for (Integer i = 0; i < updateCurrentOfficerList.size(); i++) {
                Map<String, Object> fieldsToUpdate = fieldsToUpdateList[i];
                
                for(String fieldName : fieldsToUpdate.keySet()) {
                    Object fieldValue = fieldsToUpdate.get(fieldName);
                    if (fieldName != 'Name') {
                        updateCurrentOfficerList[i].put(fieldName, fieldValue);
                        if (fieldName == 'Date_of_Birth_Month__c' || fieldName == 'Date_of_Birth_Year__c') {
                            String strBirthMonth = (fieldsToUpdate.get('Date_of_Birth_Month__c') != null) ? (String) fieldsToUpdate.get('Date_of_Birth_Month__c'): updateCurrentOfficerList[i].Date_of_Birth_Month__c;
                            String strBirthYear = (fieldsToUpdate.get('Date_of_Birth_Year__c') != null) ? (String) fieldsToUpdate.get('Date_of_Birth_Year__c'): updateCurrentOfficerList[i].Date_of_Birth_Year__c;

                            // String strBirthMonth = (String) fieldsToUpdate.get('Date_of_Birth_Month__c');
                            // String strBirthYear = (String) fieldsToUpdate.get('Date_of_Birth_Year__c');

                            if(strBirthMonth != null && strBirthYear != null) {
                                Map<String, Integer> monthToNumber = new Map<String, Integer>{
                                    'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6,
                                    'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
                                };
                                
                                Integer existingBirthDay = (Integer) updateCurrentOfficerList[i].Birthdate__c.day();
                                System.debug('existingBirthDay:: ' + existingBirthDay);
 
                                Integer birthMonth = monthToNumber.get(strBirthMonth);
                                Integer birthYear = Integer.valueOf(strBirthYear);
                                Integer birthDay = existingBirthDay != null ? existingBirthDay : 1;

                                Date birthDate = Date.newInstance(birthYear, birthMonth, birthDay);
                                updateCurrentOfficerList[i].Date_of_Birth_Month__c = String.valueOf(birthMonth);
                                updateCurrentOfficerList[i].Date_of_Birth_Year__c = strBirthYear;
                                updateCurrentOfficerList[i].Birthdate__c = birthDate;
                            }
                            System.debug('updateCurrentOfficerList[i].Date_of_Birth_Month__c:: ' + updateCurrentOfficerList[i].Date_of_Birth_Month__c);
                            System.debug('updateCurrentOfficerList[i].Date_of_Birth_Year__c:: ' + updateCurrentOfficerList[i].Date_of_Birth_Year__c);
                            System.debug('updateCurrentOfficerList[i].Birthdate:: ' + updateCurrentOfficerList[i].Birthdate__c);
                        }
                    } else if (fieldName == 'Name') {
                        String[] nameParts = ((String)fieldValue).split(' ');
                        String firstName = '';
                        String middleName = '';
                        String lastName = '';
                        Boolean lastNameFound = false;

                        for (Integer j = 0; j < nameParts.size(); j++) {
                            // If ALL CAPS, consider it as the last name
                            if (nameParts[j].equals(nameParts[j].toUpperCase())) {
                                lastNameFound = true;
                            }
                
                            if (lastNameFound) {
                                lastName += nameParts[j] + ' ';
                            } else if (j > 0){
                                middleName += nameParts[j] + ' ';
                            } else {
                                firstName += nameParts[j] + ' ';
                            }
                        }

                        updateCurrentOfficerList[i].First_Name__c = firstName.trim();
                        updateCurrentOfficerList[i].Middle_Name__c = middleName != null ? middleName.trim() : null;
                        updateCurrentOfficerList[i].Last_Name__c = lastName.trim();
                        updateCurrentOfficerList[i].Account__c = accountId;
                        updateCurrentOfficerList[i].Companies_House_Run__c = true;
                        updateCurrentOfficerList[i].Companies_House_Run_Date__c = Date.today();
                        System.debug('updateCurrentOfficerList[i].FirstName:: ' + updateCurrentOfficerList[i].First_Name__c);
                        System.debug('updateCurrentOfficerList[i].MiddleName:: ' + updateCurrentOfficerList[i].Middle_Name__c);
                        System.debug('updateCurrentOfficerList[i].LastName:: ' + updateCurrentOfficerList[i].Last_Name__c);
                    }
                }
                officersToUpdate.add(updateCurrentOfficerList[i]);
            }
            System.debug('officersToUpdate:: ' + officersToUpdate);
            update officersToUpdate;
        }

        if(jsonString != null){
            Account updatedAccount = CompaniesHouse_AccountFieldMapping.updateAccountFields(accountId, companyKey, jsonString, true, jsonOfficers);
            accountToUpdate.add(updatedAccount);
        }
    
        if(params.size() > 0){
            savePdfFromUrl(params, accountId);
        }

        if( pcsData.size() > 0 ){
            createPSC(pcsData, accountId);
        }

        System.debug('accountToUpdate:: ' + accountToUpdate);
        
        return officersToUpdate;
    }

    public static void createPSC(List<PSCWrapper> pcsData, String accountId){
        if(pcsData.size() > 0){
            List<Person_with_Significant_Control__c> pcss = new List<Person_with_Significant_Control__c>();
            for(PSCWrapper singlePCS : pcsData ){
                if(!singlePCS.importData.donotimport){
                    Person_with_Significant_Control__c pcs = new Person_with_Significant_Control__c();
                    if( singlePCS.importData.isMatch ){
                        pcs.Id = singlePCS.isSelectedRecord;
                    }
                    pcs.Name = singlePCS.fullName;
                    pcs.Ceased_On__c = singlePCS.item.ceased_on;
                    pcs.Description__c = singlePCS.item.description;
                    pcs.ETag__c = singlePCS.Id;
                    pcs.Is_Ceased__c = singlePCS.item.ceased;
                    pcs.Nationality__c = singlePCS.item.nationality;
                    pcs.Account__c = accountId;
                    pcss.add(pcs);
                }
            }

           if(pcss.size() > 0){
                upsert pcss;
           }
        }
    }

    /*******************************************************************************
    * @description  Return Officer__c Field Label
    *******************************************************************************/
    @AuraEnabled
    public static String getOfficerFieldNameAndAPI(String fieldApiName){
        String fieldLabel = '';
        String objectApiName = 'Officer__c';
        SObjectType officerType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String,Schema.SObjectField> mfields = officerType.getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = mfields.get(fieldApiName).getDescribe();
        fieldLabel = fieldResult.getLabel();

        System.debug('Officer__c fieldApiName::' + fieldApiName);
        System.debug('Officer__c fieldLabel::' + fieldLabel);
        return fieldLabel;
    }

    /*******************************************************************************
    * @description  Return Company_House_Setting__c Custom Settings
    *******************************************************************************/
    @AuraEnabled(cacheable=true) 
    public static Company_House_Setting__c getCustomSettings(){
        return Company_House_Setting__c.getOrgDefaults();
    }

    /*******************************************************************************
    * @description  Return Companies_House_Setting__mdt  Custom Metadata
    *******************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Companies_House_Setting__mdt> getCompaniesHouseMetadata() {
        return [
            SELECT Id, DeveloperName, Field_Label__c, FieldAPIName__c 
            FROM Companies_House_Setting__mdt 
            ORDER BY DeveloperName ASC
        ];
    }
    
    public class FileWrapper {
        @AuraEnabled
        public String fileDate {get; set;}
        @AuraEnabled
        public String fileType {get; set;}
        @AuraEnabled
        public String fileDescription {get; set;}
        @AuraEnabled
        public String fileDownloadName {get; set;}
        @AuraEnabled
        public String downloadURL {get; set;}
    }

    public class PSCWrapper {
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public String fullName {get; set;}
        @AuraEnabled
        public ImportData importData {get; set;}
        @AuraEnabled
        public String isSelectedRecord {get; set;}
        @AuraEnabled
        public Item item {get; set;}
    }

    public class ImportData{ 
        @AuraEnabled
        public Boolean donotimport {get; set;}
        @AuraEnabled
        public Boolean isMatch {get; set;}
        @AuraEnabled
        public Boolean isNew {get; set;}
    }

    public class PSCResponse {
        @AuraEnabled
        public Integer active_count {get; set;}
        @AuraEnabled
        public Integer ceased_count {get; set;}
        @AuraEnabled
        public Integer items_per_page {get; set;}
        @AuraEnabled
        public Integer start_index {get; set;}
        @AuraEnabled
        public Integer total_results {get; set;}
        @AuraEnabled
        public Links links {get; set;}
        @AuraEnabled
        public List<Item> items {get; set;}
    }

    public class Item {
        @AuraEnabled
        public Address address {get; set;}
        @AuraEnabled
        public Boolean ceased {get; set;}
        @AuraEnabled
        public Date ceased_on {get; set;}
        @AuraEnabled
        public DateOfBirth date_of_birth {get; set;}
        @AuraEnabled
        public String description {get; set;}
        @AuraEnabled
        public String etag {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String nationality {get; set;}
    }

    public class DateOfBirth { 
        @AuraEnabled
        public Integer day {get; set;}
        @AuraEnabled
        public Integer month {get; set;}
        @AuraEnabled
        public Integer year {get; set;}
    }

    public class Address { 
        @AuraEnabled
        public String address_line_1 {get; set;}
        @AuraEnabled
        public String address_line_2 {get; set;}
        @AuraEnabled
        public String care_of {get; set;}
        @AuraEnabled
        public String country {get; set;}
        @AuraEnabled
        public String locality {get; set;}
        @AuraEnabled
        public String po_box {get; set;}
        @AuraEnabled
        public String postal_code {get; set;}
        @AuraEnabled
        public String premises {get; set;}
        @AuraEnabled
        public String region {get; set;}
    }

    public class Links {
        @AuraEnabled
        public String persons_with_significant_control_list {get; set;}
        @AuraEnabled
        public String self {get; set;}
    }
}