public with sharing class CSVRecordUploaderController {
    

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
    

    @AuraEnabled
    public static Map<String, String> createRecord(String csvData, String obj) {
        Map<String, String> result = new Map<String, String>();
        csvData = csvData.replace('\r\n', '\n').replace('\r', '\n');
        List<String> rows = csvData.split('\n');
        List<String> headers = rows[0].split(',');
        List<Uploader_Mapping__mdt> uploadAccountMapping = [SELECT Column_Name__c, Field_API_Name__c, Object_Name__c FROM Uploader_Mapping__mdt WHERE (Object_Name__c  = :obj OR Object_Name__c  = :obj.toLowerCase()) AND Column_Name__c IN :headers];
        Map<String, Id> regNumAcc = new Map<String, Id>();
        if(obj == 'Contact'){
            List<String> regNumbers = new List<String>();
            for (Integer i = 1; i < rows.size(); i++) {
                String csvLine = removeCommaValueCSV(rows[i]);
                List<String> rowValues = csvLine.split(',');
                for (Integer j = 0; j < rowValues.size(); j++) {
                    String columnHeader = headers[j];
                    if(columnHeader == 'Registered Number'){
                        String regNum = rowValues[j].replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                        regNumbers.add( rowValues[j] );
                    }
                }
            }
            if(!regNumbers.isEmpty()){
                List<Account> parentAccounts = [SELECT Id, Beauhurst_ID__c FROM Account WHERE Beauhurst_ID__c IN:regNumbers];
                if(!parentAccounts.isEmpty()){
                    for (Account parentAccount : parentAccounts) {
                        regNumAcc.put(parentAccount.Beauhurst_ID__c, parentAccount.Id);
                    }    
                }
            }
        }
        Map<String, Object> accDynamic = fieldColumnMapping(uploadAccountMapping, rows, headers, obj, regNumAcc);
        String errorFile = (String)accDynamic.get('errorFile');
        String successFile = (String)accDynamic.get('successFile');
        List<String> validatedRcrds = (List<String>) accDynamic.get('validatedRcrds');
        List<SObject> retSObj = (List<SObject>) accDynamic.get('retSObj');
        result = dmlFunction(retSObj, validatedRcrds, successFile, errorFile);
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
                    csvRow = recId + ',' + validatedRcrds[count].replaceAll(':quotes:', '"').replaceAll(':comma:', ','); // concatinate the record Id and the validated item
                    successFile += csvRow + '\n'; // add the row to the final success csv string
                }else{ // if error
                    String errMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errMsg = 'The following error has occurred. ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields(); // get the error message
                    }
                    csvRow = errMsg + ',' + validatedRcrds[count].replaceAll(':quotes:', '"').replaceAll(':comma:', ','); // concatinate the error message and the validated item
                    errorFile += csvRow + '\n'; // add the row to the final error csv string
                }
                count ++;
            }
        }
        mapRet.put('successFile', successFile);
        mapRet.put('errorFile', errorFile);
        
        return mapRet;
    }
    
    public static Map<String, Object> fieldColumnMapping(List<Uploader_Mapping__mdt> uploadMapping, List<String> csvRows, List<String> headers, String objType, Map<String, Id> regNumAcc) {
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
            
            errorFile += ',' + header;
            successFile += ',' + header;
            
        }

        for (Integer i = 1; i < csvRows.size(); i++) {
            String csvLine = removeCommaValueCSV(csvRows[i]);
            List<String> rowValues = csvLine.split(',');
            SObject obj = createObject(objType);
            Boolean hasError = false;
            String errorMessage = ' ';
            List<String> potentialRecs = new List<String>();
            List<String> fieldsMappingError = new List<String>();
            for (Integer j = 0; j < rowValues.size(); j++) {
                String columnHeader = headers[j];
                if(objType == 'Contact' && columnHeader == 'Registered Number'){
                    if(regNumAcc.containsKey(rowValues[j])){
                        obj.put('AccountId', regNumAcc.get(rowValues[j]));
                    }
                }
                if(uploadMap.containsKey(columnHeader)){
                    String field = uploadMap.get(columnHeader);
                    if (field != null) {
                        try {
                            String val = rowValues[j].replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                            obj.put(field, val);
                        }catch (Exception e) {
                            hasError = true;
                            errorMessage += e.getMessage() + ';';
                        }
                    }
                }
                potentialRecs.add(rowValues[j]);
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


    public static String removeCommaValueCSV(String rowCsv){

        String csvLine = rowCsv;
        String prevLine = csvLine;
        Integer startIndex;
        Integer endIndex;
        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                }
            }

            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }

        return csvLine;
    }

    public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        return targetType.newSObject(); 
    }
    
}