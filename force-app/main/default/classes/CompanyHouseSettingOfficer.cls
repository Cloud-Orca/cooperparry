public with sharing class CompanyHouseSettingOfficer {
  
    @AuraEnabled
    public static CustomSettingWrapp getCustomSettings(){
        try {
            CustomSettingWrapp customSettWrapp = new CustomSettingWrapp();
            customSettWrapp.companyHouseAPI = Company_House_API__c.getOrgDefaults();
            customSettWrapp.companyHouseSetting = Company_House_Setting__c.getOrgDefaults();
            return customSettWrapp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProfileWrapper{
        @AuraEnabled public String profileName;
        @AuraEnabled public String profileId;
        @AuraEnabled public Boolean isDisabled;
        @AuraEnabled public Boolean isNew;
        @AuraEnabled public Integer ctr;
    }

    public class CustomSettingWrapp{
        @AuraEnabled public Company_House_API__c companyHouseAPI;
        @AuraEnabled public Company_House_Setting__c companyHouseSetting;
    }

    @AuraEnabled
    public static void saveCompanyHouseAPI(Company_House_API__c companyHouseAPI){
        try {
            update companyHouseAPI;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveCompanyHouseSetting(Company_House_Setting__c companyHouseSetting){
        try {
            Company_House_Setting__c existingCompHouseSetting = Company_House_Setting__c.getOrgDefaults();
            if(existingCompHouseSetting.Batch_Occurrence__c != companyHouseSetting.Batch_Occurrence__c){
                if(existingCompHouseSetting.Schedule_Job_Id__c != null){
                    Id cronTriggerId = [SELECT CronExpression, CronJobDetailId, Id, State FROM CronTrigger WHERE Id =: existingCompHouseSetting.Schedule_Job_Id__c].Id;
                    System.abortJob(cronTriggerId);
                }

                if(companyHouseSetting.Batch_Occurrence__c != null){
                    String cronString = '';
                    if(companyHouseSetting.Batch_Occurrence__c == 'Daily'){
                        cronString = '0 0 0 1/1 * ? *';
                    }
                    else if(companyHouseSetting.Batch_Occurrence__c == 'Weekly'){
                        cronString = '0 0 0 ? * MON *';
                    }
                    else if(companyHouseSetting.Batch_Occurrence__c == 'Monthly'){
                        cronString = '0 0 0 1 1/1 ? *';
                    }
                    
                    if(!test.isRunningTest()){
                        Id schedJobId = System.schedule('Batch Companies House Update', cronString, new BatchCompHouseUpdateAccAndOfficerSched());
                        System.debug(schedJobId);
                        companyHouseSetting.Schedule_Job_Id__c = schedJobId;
                    }
                    else{
                        Id schedJobId = System.schedule('Batch Companies House Update Test', cronString, new BatchCompHouseUpdateAccAndOfficerSched());
                        System.debug(schedJobId);
                        companyHouseSetting.Schedule_Job_Id__c = schedJobId;
                    }
                    
                }
            }
            update companyHouseSetting;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}