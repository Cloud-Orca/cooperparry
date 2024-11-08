public with sharing class CSVRecordUploaderController {

    /**
     * @description: Splits the CSV rows then generates a lead records out of it.
     * @param: (String) content of the csv file
     * @return: returns a map of String which consist of 2 main keys, errorFile and successFile.
     */
    @AuraEnabled
    public static Map<String, String> createLeads(String csvData) {
        Map<String, String> result = new Map<String, String>();
        List<String> validatedRcrds = new List<String>(); // Validated Lead records for CSV generation.
        String errorFile = '';
        String successFile = '';

        csvData = csvData.replace('\r\n', '\n').replace('\r', '\n');

        Map<String, String> columnToFieldMap = new Map<String, String>();
        for (Uploader_Mapping__mdt mapping : [SELECT Column_Name__c, Field_API_Name__c FROM Uploader_Mapping__mdt WHERE Object_Name__c = 'Lead' OR Object_Name__c = 'lead']) {
            columnToFieldMap.put(mapping.Column_Name__c, mapping.Field_API_Name__c);
        }
        List<Lead> leadsToCreate = new List<Lead>();
        List<String> rows = csvData.split('\n');
        List<String> headers = rows[0].split(',');

        successFile = 'RecordId,' + rows[0] + '\n'; // Final Success CSV String
        errorFile += rows[0] + ',Error\n'; // Final Error CSV String

        for (Integer i = 1; i < rows.size(); i++) {
            List<String> rowValues = rows[i].split(',');
            Lead lead = new Lead();
            Boolean hasError = false;
            String errorMessage = ' ';
            List<String> fieldsMappingError = new List<String>();
            for (Integer j = 0; j < rowValues.size(); j++) {
                String columnHeader = headers[j];
                if (columnToFieldMap.containsKey(columnHeader)) {
                    String leadField = columnToFieldMap.get(columnHeader);
                    if (leadField != null) {
                        try {
                            lead.put(leadField, rowValues[j]);
                        } catch (Exception e) {
                            hasError = true;
                            errorMessage += e.getMessage() + ';';
                        }
                    }
                }else{
                    hasError = true;
                    fieldsMappingError.add(columnHeader);
                }
            }
            if(fieldsMappingError.size() > 0) errorMessage += 'Mismatched Field Mapping [' + String.join(fieldsMappingError, ';') + '];';
            
            if (hasError) {
                errorFile += rows[i] + ',' + errorMessage + '\n';
            } else { // no error
                validatedRcrds.add(rows[i]); // mark current Item as Validated.
                leadsToCreate.add(lead);
            }
        }


        if (!leadsToCreate.isEmpty()) {
            Database.SaveResult[] res = Database.Insert(leadsToCreate, false);

            Integer count = 0; // determines specific validated item from the list.

            for (Database.SaveResult sr : res) {
                String csvRow = '';
                if (sr.isSuccess()) { // if success 
                    Id recId = sr.getId(); // get the record Id
                    csvRow = recId + ',' + validatedRcrds[count]; // concatinate the record Id and the validated item
                    successFile += csvRow + '\n'; // add the row to the final success csv string
                }else{ // if error
                    String errMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errMsg = 'The following error has occurred. ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields(); // get the error message
                    }
                    csvRow = validatedRcrds[count] + ',' + errMsg; // concatinate the error message and the validated item
                    errorFile += csvRow + '\n'; // add the row to the final error csv string
                }
                count ++;
            }
        }

        result.put('successFile', successFile);
        result.put('errorFile', errorFile);
        return result;
    }


    /**
     * @description: counts the number of rows a given csv content has
     * @param: (String) content of the csv file
     * @return: (Decimal) the total number of rows
     */
    @AuraEnabled
    public static Decimal getNumberOfRows(String csvData){
        csvData = csvData.replace('\r\n', '\n').replace('\r', '\n');
        List<String> rows = csvData.split('\n');
        return rows.size();
    }


    /**
     * @description: Splits the CSV rows then generates a lead records out of it.
     * @param: (String) content of the csv file
     * @return: returns a map of String which consist of 2 main keys, errorFile and successFile.
     */
    @AuraEnabled
    public static Map<String, Map<String, String>> createAccountAndContact(String csvData) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();

        csvData = csvData.replace('\r\n', '\n').replace('\r', '\n');
        List<String> rows = csvData.split('\n');
        List<String> headers = rows[0].split(',');
        // Map<String, Map<String, String>> columnToFieldMap = new Map<String, Map<String, String>>();
        // List<String> objectNames = new List<String>{'Account', 'account', 'contact', 'Contact'};
        List<Uploader_Mapping__mdt> uploadAccountMapping = [SELECT Column_Name__c, Field_API_Name__c, Object_Name__c FROM Uploader_Mapping__mdt WHERE (Object_Name__c  = 'Account' OR Object_Name__c  = 'account') AND Column_Name__c IN :headers];
        Map<String, Object> accDynamic = fieldColumnMapping(uploadAccountMapping, rows, headers, 'Account');
        String accErrorFile = (String)accDynamic.get('errorFile');
        String accSuccessFile = (String)accDynamic.get('successFile');
        List<String> accValidatedRcrds = (List<String>) accDynamic.get('validatedRcrds');
        List<SObject> accRetSObj = (List<SObject>) accDynamic.get('retSObj');
        List<Account> accs = accRetSObj;
        // for (Account acc : accs) {
        //     System.debug('acc: ' + acc);
        // }
        // Map<String, String> accountCreated = dmlFunction(accs, accValidatedRcrds, accSuccessFile, accErrorFile);

        List<Uploader_Mapping__mdt> uploadContactMapping = [SELECT Column_Name__c, Field_API_Name__c, Object_Name__c FROM Uploader_Mapping__mdt WHERE (Object_Name__c  = 'Contact' OR Object_Name__c  = 'contact') AND Column_Name__c IN :headers];
        Map<String, Object> contDynamic = fieldColumnMapping(uploadContactMapping, rows, headers, 'Contact');
        String contErrorFile = (String)contDynamic.get('errorFile');
        String contSuccessFile = (String)contDynamic.get('successFile');
        List<String> contValidatedRcrds = (List<String>) contDynamic.get('validatedRcrds');
        List<SObject> contRetSObj = (List<SObject>) contDynamic.get('retSObj');
        List<Contact> conts = contRetSObj;
        // List<Contact> contactWithAccount = new List<Contact>();
        // for (Contact cont : conts) {
        //     System.debug('cont: ' + cont);
        // }

        if (!accs.isEmpty()) {
            Database.SaveResult[] res = Database.Insert(accs, false);
            Integer count = 0; // determines specific validated item from the list.
            for (Database.SaveResult sr : res) {
                String csvRow = '';
                if (sr.isSuccess()) { // if success 
                    Id recId = sr.getId(); // get the record Id
                    csvRow = recId + ',' + accValidatedRcrds[count]; // concatinate the record Id and the validated item
                    accSuccessFile += csvRow + '\n'; // add the row to the final success csv string
                    conts[count].AccountId = recId;
                    // contactWithAccount.add(conts[count]);
                }else{ // if error
                    String errMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errMsg = 'The following error has occurred. ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields(); // get the error message
                        System.debug('errMsg; ' + errMsg);
                    }
                    csvRow = errMsg + ',' + accValidatedRcrds[count]; // concatinate the error message and the validated item
                    accErrorFile += csvRow + '\n'; // add the row to the final error csv string
                    // contErrorFile += 'There is an error when creating parent Account ' + errMsg;
                }
                count ++;
            }
        }
        
        Map<String, String> contactCreated = dmlFunction(conts, contValidatedRcrds, contSuccessFile, contErrorFile);
        result.put('accountResult', new Map<String, String>{
                                                            'successFile' => accSuccessFile,
                                                            'errorFile' => accErrorFile
                                                        });
        result.put('contactResult', new Map<String, String>{
                                                            'successFile' => contactCreated.get('successFile'),
                                                            'errorFile' => contactCreated.get('errorFile')
                                                        });
        return result;

    }

    private static Map<String, String> dmlFunction(list<SObject> recs, List<String> validatedRcrds, String successFile, String errorFile) {
        Map<String, String> mapRet = new Map<String, String>();
        
        if (!recs.isEmpty()) {
            Database.SaveResult[] res = Database.Insert(recs, false);
            Integer count = 0; // determines specific validated item from the list.
            for (Database.SaveResult sr : res) {
                String csvRow = '';
                if (sr.isSuccess()) { // if success 
                    Id recId = sr.getId(); // get the record Id
                    csvRow = recId + ',' + validatedRcrds[count]; // concatinate the record Id and the validated item
                    successFile += csvRow + '\n'; // add the row to the final success csv string
                }else{ // if error
                    String errMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errMsg = 'The following error has occurred. ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields(); // get the error message
                    }
                    csvRow = errMsg + ',' + validatedRcrds[count]; // concatinate the error message and the validated item
                    errorFile += csvRow + '\n'; // add the row to the final error csv string
                }
                count ++;
            }
        }
        mapRet.put('successFile', successFile);
        mapRet.put('errorFile', errorFile);
        
        return mapRet;
    }

    public static Map<String, Object> fieldColumnMapping(List<Uploader_Mapping__mdt> uploadMapping, List<String> csvRows, List<String> headers, String objType) {
        Map<String, String> uploadMap = new Map<String, String>();
        String errorFile = 'Error';
        String successFile = 'RecordId';
        List<String> validatedRcrds = new List<String>(); // Validated Lead records for CSV generation.
        for (Uploader_Mapping__mdt mapping : uploadMapping) {
            uploadMap.put(mapping.Column_Name__c, mapping.Field_API_Name__c);
        }
        List<SObject> retSObj = new List<SObject>();
        Map<String, Object> mapRet = new Map<String, Object>();
        for (String header : headers) {
            if(uploadMap.containsKey(header)){
                errorFile += ',' + header;
                successFile += ',' + header;
            }
        }
        for (Integer i = 1; i < csvRows.size(); i++) {
            List<String> rowValues = csvRows[i].split(',');
            SObject obj = createObject(objType);
            Boolean hasError = false;
            String errorMessage = ' ';
            List<String> potentialRecs = new List<String>();
            List<String> fieldsMappingError = new List<String>();
            for (Integer j = 0; j < rowValues.size(); j++) {
                String columnHeader = headers[j];          
                if(uploadMap.containsKey(columnHeader)){
                    String field = uploadMap.get(columnHeader);
                    if (field != null) {
                        try {
                            obj.put(field, rowValues[j]);
                            potentialRecs.add(rowValues[j]);
                        } catch (Exception e) {
                            hasError = true;
                            errorMessage += e.getMessage() + ';';
                        }
                    }
                }
            }
            if(!hasError){
                validatedRcrds.add(String.join(potentialRecs, ',')); // mark current Item as Validated.
                retSObj.add(obj);
            }else{
                errorFile += csvRows[i] + ',' + errorMessage + '\n';
            }
        }
        successFile += '\n';
        errorFile += '\n';
        mapRet.put('successFile', successFile);
        mapRet.put('errorFile', errorFile);
        mapRet.put('validatedRcrds', validatedRcrds);
        mapRet.put('retSObj', retSObj);
        return mapRet;
    }

    public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        return targetType.newSObject(); 
    }

}