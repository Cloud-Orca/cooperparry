/**
 * @author: Jomark
 * @updated by: Clifford U.
 * @description: Use in UploadLeadComp(LWC), For creating Leads from the CSV uploaded from the component.
 */
public without sharing class UploadLeadController {


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
        for (Lead_Mapping__mdt mapping : [SELECT Column_Name__c, Lead_API_Name__c FROM Lead_Mapping__mdt]) {
            columnToFieldMap.put(mapping.Column_Name__c, mapping.Lead_API_Name__c);
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
                lead.OwnerId = '00GKD000000mzFk';
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
}