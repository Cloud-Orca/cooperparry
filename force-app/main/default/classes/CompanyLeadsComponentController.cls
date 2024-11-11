public with sharing class CompanyLeadsComponentController {

    @AuraEnabled(cacheable=true)
    public static List<CompanyWrapper> getDataToDisplayActivity(Id leadId, String fieldsToDisplay){ 
        System.debug('leadId::' + leadId);
        System.debug('fieldsToDisplay::' + fieldsToDisplay);
        Set<Id> matchedLeadIds = LeadMatchingRuleUtility.getAllLeadMatching(leadId);
        System.debug('@@@ fieldsToDisplay: ' + fieldsToDisplay);
        String queryAPIfields = '';
        List<String> fieldsToDisplayList = new List<String>();
        if(fieldsToDisplay != ''){
            fieldsToDisplayList = fieldsToDisplay.split(',');
        }
        System.debug('@@@ fieldsToDisplayList: ' + fieldsToDisplayList);
        Map<String, String> mapAPInameToLabel = new Map<String, String>();
        for(String fieldsVal: fieldsToDisplayList){
            List<String> fieldsValDetail = fieldsVal.split(':');
            String fieldLabel = fieldsValDetail.get(0);
            String fieldAPIname = fieldsValDetail.get(1);

            queryAPIfields += ',' + fieldAPIname;

            mapAPInameToLabel.put(fieldAPIname, fieldLabel);
        }

        Map<String, String> fieldApiNameToType = getDataTypeForFields(mapAPInameToLabel.keySet());

        String query = 'SELECT Id, Name ' + queryAPIfields + ' FROM Lead WHERE Id IN: matchedLeadIds';
        System.debug('@@@ query: ' + query);
    
        List<Lead> leadRecords = Database.query(query);
        List<CompanyWrapper> compWrapList = new List<CompanyWrapper>();
        for(Lead leadRec: leadRecords){
            CompanyWrapper compWrap = new CompanyWrapper();
            compWrap.leadId = leadRec.Id;
            compWrap.leadName = leadRec.Name;
            compWrap.leadDetailsVal = new List<LeadDetails>();

            List<LeadDetails> leadDetailList = new List<LeadDetails>();
            for(String apiName: mapAPInameToLabel.keySet()){
                System.debug('@@@ apiName: ' + apiName);
                LeadDetails leadDetail = new LeadDetails();
                leadDetail.valueToDisplay = mapAPInameToLabel.get(apiName) + ': ';

                if(fieldApiNameToType.get(apiName) == 'DATE' || fieldApiNameToType.get(apiName) == 'DATETIME'){
                    DateTime dateRec = (DateTime) leadRec.get(apiName);
                    if(dateRec != null){
                        String dateString = dateRec.format('dd/MM/yyyy');
                        leadDetail.valueToDisplay += dateString;
                    }
                }
                else if(fieldApiNameToType.get(apiName) == 'BOOLEAN'){
                    Boolean booleanVal = (Boolean) leadRec.get(apiName);
                    leadDetail.valueToDisplay += (booleanVal) ? 'True' : 'False';
                }
                else if(fieldApiNameToType.get(apiName) == 'CURRENCY'){
                    Decimal decimalVal = (Decimal) leadRec.get(apiName);
                    if(decimalVal != null){
                        leadDetail.valueToDisplay += String.valueOf(decimalVal);
                    }
                }
                else{
                    leadDetail.valueToDisplay += (String) leadRec.get(apiName);
                }

                System.debug('@@@ leadDetail: ' + leadDetail);
                leadDetailList.add(leadDetail);
            }

            compWrap.leadDetailsVal = leadDetailList;
            compWrapList.add(compWrap);
        }
        //return [SELECT Id, Name, Company, Title, LastActivityDate FROM Lead WHERE Id IN: matchedLeadIds];
        System.debug('@@@ compWrapList: ' + compWrapList);
        return compWrapList;
    }

    public static Map<String, String> getDataTypeForFields(Set<String> apiNames){
        Map<String, String> fieldApiNameToType = new Map<String, String>();
        SObjectType r = ((SObject)(Type.forName('Schema.Lead').newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        for(String api: apiNames){
            try{
                fieldApiNameToType.put(api, String.valueOf(d.fields.getMap().get(api).getDescribe().getType()));
            } catch(Exception e){
                fieldApiNameToType.put(api, 'STRING');
            }
        }
        return fieldApiNameToType;
    }

    public class CompanyWrapper{
        @AuraEnabled public Id leadId; 
        @AuraEnabled public String leadName; 
        @AuraEnabled public List<LeadDetails> leadDetailsVal;
    }

    public class LeadDetails{
        @AuraEnabled public String valueToDisplay;
    }
}