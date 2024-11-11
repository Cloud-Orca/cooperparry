public without sharing class LeadMatchingRuleUtility {

    public static String getFieldToFilter(List<Matching_Lead_Criteria__mdt> matchingLeadRule){
        String fieldToFilterReturn = '';
        Set<String> stringToQuery = new Set<String>();
        for(Matching_Lead_Criteria__mdt metadataRec: matchingLeadRule){
            if(!stringToQuery.contains(metadataRec.API_Name__c)){
                fieldToFilterReturn += ', ' + metadataRec.API_Name__c;

                stringToQuery.add(metadataRec.API_Name__c);
            }
        }
        return fieldToFilterReturn;
    }

    public static Set<Id> getAllLeadMatching(Id leadId){
        System.debug('leadId:: ' + leadId);
        Set<Id> listOfLeadIdsToReturn = new Set<Id>();
        List<Matching_Lead_Criteria__mdt> matchingLeadRule = [SELECT Id, API_Name__c, Order_No__c, Is_Email__c, Operator__c FROM Matching_Lead_Criteria__mdt ORDER BY Order_No__c ASC];

        if(!matchingLeadRule.isEmpty()){
            String fieldToFilter = getFieldToFilter(matchingLeadRule);
            String queryExistingLead = 'SELECT Id' + fieldToFilter + ' FROM Lead WHERE Id =: leadId';
            Lead existingLead = Database.query(queryExistingLead);

            Map<String, String> fieldApiNameToType = getDataTypeForFields(matchingLeadRule);

            String queryMatchedLeads = 'SELECT Id, IsConverted FROM Lead WHERE ';
            for(Matching_Lead_Criteria__mdt matching: matchingLeadRule){
                if(matching.Operator__c == 'AND'){
                    if(matching.Is_Email__c){
                        String filterAPIemail = (String) existingLead.get(matching.API_Name__c);
                        if(filterAPIemail != '' && filterAPIemail != null){
                            String filterAPI = filterAPIemail.substringAfter('@');
                            queryMatchedLeads += matching.API_Name__c + ' LIKE \'%' + filterAPI + '\' AND ';
                        }
                    }
                    else{
                        String filterAPI = (String) existingLead.get(matching.API_Name__c);
                        if(filterAPI != '' && filterAPI != null){
                            queryMatchedLeads += matching.API_Name__c + ' = \'' + filterAPI + '\' AND ';
                        }
                    }
                }
                else if(matching.Operator__c == 'OR'){
                    if(matching.Is_Email__c){
                        String filterAPIemail = (String) existingLead.get(matching.API_Name__c);
                        if(filterAPIemail != '' && filterAPIemail != null){
                            String filterAPI = filterAPIemail.substringAfter('@');
                            queryMatchedLeads += matching.API_Name__c + ' LIKE \'%' + filterAPI + '\' OR ';
                        }
                    }
                    else{
                        String filterAPI = (String) existingLead.get(matching.API_Name__c);
                        if(filterAPI != '' && filterAPI != null){
                            queryMatchedLeads += matching.API_Name__c + ' = \'' + filterAPI + '\' OR ';
                        }
                    }
                    
                }
                else if(matching.Operator__c == 'END'){
                    if(matching.Is_Email__c){
                        String filterAPIemail = (String) existingLead.get(matching.API_Name__c);
                        if(filterAPIemail != '' && filterAPIemail != null){
                            String filterAPI = filterAPIemail.substringAfter('@');
                            queryMatchedLeads += matching.API_Name__c + ' LIKE \'%' + filterAPI + '\'';
                        }
                    }
                    else{
                        String filterAPI = (String) existingLead.get(matching.API_Name__c);
                        if(filterAPI != '' && filterAPI != null){
                            queryMatchedLeads += matching.API_Name__c + ' = \'' + filterAPI + '\'';
                        }
                    }

                    System.debug('@@@ queryMatchedLeads: ' + queryMatchedLeads);
                    listOfLeadIdsToReturn.addAll(performQueryLead(queryMatchedLeads, leadId));

                    queryMatchedLeads = 'SELECT Id, IsConverted FROM Lead WHERE ';
                }

                System.debug('@@@ final listOfLeadIdsToReturn: ' + listOfLeadIdsToReturn.size());
            }
        }
        return listOfLeadIdsToReturn;
    }

    public static Map<String, String> getDataTypeForFields(List<Matching_Lead_Criteria__mdt> matchingLeadRule){
        Map<String, String> fieldApiNameToType = new Map<String, String>();
        SObjectType r = ((SObject)(Type.forName('Schema.Lead').newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        for(Matching_Lead_Criteria__mdt matching: matchingLeadRule){
            try{
                fieldApiNameToType.put(matching.API_Name__c, String.valueOf(d.fields.getMap().get(matching.API_Name__c).getDescribe().getType()));
            } catch(Exception e){
                fieldApiNameToType.put(matching.API_Name__c, 'STRING');
            }
        }
        return fieldApiNameToType;
    }

    public static Set<Id> performQueryLead(String queryLead, Id leadId){
        System.debug('@@@ performQueryLead: ' + queryLead);
        Set<Id> leadIdsToReturn = new Set<Id>();
        
        List<Lead> leadListRecords = Database.query(queryLead);
        System.debug('@@@ leadListRecords: ' + leadListRecords);
        if(!leadListRecords.isEmpty()){
            for(Lead leadRecord: leadListRecords){
                if(leadRecord.Id != leadId && !leadRecord.isConverted){
                    leadIdsToReturn.add(leadRecord.Id);
                }
            }
            System.debug('@@@ leadIdsToReturn: ' + leadIdsToReturn.size());
        }
        return leadIdsToReturn;
    }

}