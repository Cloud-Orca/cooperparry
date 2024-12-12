global with sharing class BatchCompHouseUpdateAccAndOfficer implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public List<String> ids {get; set;}
    global BatchCompHouseUpdateAccAndOfficer(List<String> ids) {
        this.ids = ids; 
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Company_registration_number__c, Companies_House_Id__c, Beauhurst_ID__c, (SELECT Id, Officer_Key__c FROM Officers__r WHERE Officer_Key__c != null) FROM Account WHERE Beauhurst_ID__c != null';

        if( ids.size() > 0 ){
            query += ' AND Id IN : ids';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> accountList){
        Company_House_Setting__c companyHouseSetting = Company_House_Setting__c.getOrgDefaults();
        List<Account> accountListToUpdate = new List<Account>();
        List<Officer__c> officerListToUpdate = new List<Officer__c>();
        
        Account account = accountList.get(0);
        if(companyHouseSetting.Auto_Update_Accounts__c){
            String responseDetails = CompaniesHouseController.getCompanyByNumber(account.Beauhurst_ID__c);
            CompaniesHouseController.ResponseWrapper responseWrapp = (CompaniesHouseController.ResponseWrapper) JSON.deserialize(responseDetails, CompaniesHouseController.ResponseWrapper.class);
            if(responseWrapp.statusCode == 200){

                String responseDetails2 = CompaniesHouseController.getCompanyOfficers(account.Beauhurst_ID__c);
                CompaniesHouseController.ResponseWrapper responseWrapp2 = (CompaniesHouseController.ResponseWrapper) JSON.deserialize(responseDetails2, CompaniesHouseController.ResponseWrapper.class);
                if(responseWrapp2.statusCode == 200){
                    CompaniesHouse_AccountFieldMapping.Officers_Request_Data offReqData =  (CompaniesHouse_AccountFieldMapping.Officers_Request_Data) JSON.deserialize(responseWrapp2.body, CompaniesHouse_AccountFieldMapping.Officers_Request_Data.class);
                    String jsonOfficers = JSON.serialize(offReqData);

                    Account updatedAccount = CompaniesHouse_AccountFieldMapping.updateAccountFields(account.Id, account.Beauhurst_ID__c, responseWrapp.body, false, jsonOfficers);
                    accountListToUpdate.add(updatedAccount);
                }
            }
        }

        if(companyHouseSetting.Auto_Update_Contacts__c){
            if(!accountList.get(0).Contacts.isEmpty()){
                String responseDetails = CompaniesHouseController.getCompanyOfficers(account.Beauhurst_ID__c);
                CompaniesHouseController.ResponseWrapper responseWrapp = (CompaniesHouseController.ResponseWrapper) JSON.deserialize(responseDetails, CompaniesHouseController.ResponseWrapper.class);
                if(responseWrapp.statusCode == 200){
                    List<Officer__c> officerList = CompaniesHouse_OfficerFieldMapping.updateOfficerFields(account.Id, responseWrapp.body, false);
                    if(!officerList.isEmpty()){
                        officerListToUpdate.addAll(officerList);
                    }
                }
            }
        }

        String responseDetailsPSC = CompaniesHouseController.getCompanyPeronsSignificantControl(account.Companies_House_Id__c);
        System.debug('responseDetailsPSC' + responseDetailsPSC);
        CompaniesHouseController.ResponseWrapper responseWrappPSC = (CompaniesHouseController.ResponseWrapper) JSON.deserialize(responseDetailsPSC, CompaniesHouseController.ResponseWrapper.class);

        if(responseWrappPSC.statusCode == 200){
            System.debug('responseWrappPSC.body' + responseWrappPSC.body);
            CompaniesHouseController.PSCResponse pcsData  = ( CompaniesHouseController.PSCResponse) JSON.deserialize(responseWrappPSC.body, CompaniesHouseController.PSCResponse.class);
            System.debug('pcsData' + pcsData);
            if(pcsData.items.size() > 0){
                Set<String> keys = new Set<String>();
                for(CompaniesHouseController.Item singlePCS : pcsData.items ){
                    if( !singlePCS.ceased ){
                        keys.add(singlePCS.etag);
                    }
                }

                List<Person_with_Significant_Control__c> getPSCS = [SELECT Id, ETag__c FROM Person_with_Significant_Control__c WHERE ETag__c IN :keys];
                Map<String, Person_with_Significant_Control__c> mapOfPSCS = new Map<String, Person_with_Significant_Control__c>();

                if( getPSCS.size() > 0 ){
                    for( Person_with_Significant_Control__c psc : getPSCS){
                        mapOfPSCS.put(psc.ETag__c, psc);
                    }
                }

                List<Person_with_Significant_Control__c> pcss = new List<Person_with_Significant_Control__c>();
                for(CompaniesHouseController.Item singlePCS : pcsData.items ){
                    if( !singlePCS.ceased ){
                        Person_with_Significant_Control__c pcs = new Person_with_Significant_Control__c();
                        if( mapOfPSCS.containsKey(singlePCS.etag)){
                            pcs.Id = mapOfPSCS?.get(singlePCS.etag)?.Id;
                        }
                        pcs.Name = singlePCS.name;
                        pcs.Ceased_On__c = singlePCS.ceased_on;
                        pcs.Description__c = singlePCS.description;
                        pcs.ETag__c = singlePCS.etag;
                        pcs.Is_Ceased__c = singlePCS.ceased;
                        pcs.Nationality__c = singlePCS.nationality;
                        pcss.add(pcs);
                    }
                }
    
               if(pcss.size() > 0){
                    upsert pcss;
               }
            }
        }

        if(!accountListToUpdate.isEmpty()){
            update accountListToUpdate;
        }
        if(!officerListToUpdate.isEmpty()){
            update officerListToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}