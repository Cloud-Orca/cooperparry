global class UpdateAccountsFromBHBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful, Database.AllowsCallouts {
    global Boolean isInitialRun;
    global Set<Id> ids;

    global void execute(SchedulableContext SC) {
        Database.executebatch(new UpdateAccountsFromBHBatch(), 10); 
    }
    
    global UpdateAccountsFromBHBatch(){
        this.isInitialRun = false;
        this.ids = new Set<Id>();
    }

    global UpdateAccountsFromBHBatch(Set<Id> ids){
        this.isInitialRun = false;
        this.ids = ids;
    }

    //Database.executeBatch(new UpdateAccountsFromBHBatch(true), 10);
    global UpdateAccountsFromBHBatch(Boolean isInitialRun){
        this.isInitialRun = isInitialRun;
        this.ids = new Set<Id>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, Beauhurst_ID__c';
        query += ' FROM Account';
        query += ' WHERE Beauhurst_ID__c != null';
        if(!ids.isEmpty()){
            query += ' AND Id IN: ids';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope){
        String companyIds = '';
        for(Account acc : scope){
            companyIds += 'company_ids=' + acc.Beauhurst_ID__c + '&';
        }

        String append = '/companies?' + companyIds + 'includes=registered_name&includes=other_trading_names&includes=website&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees&includes=emails&includes=directors';

        Http http = new Http();
        HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));

        System.debug('@@@UpdateAccountsFromBHBatch status code: ' + res.getStatusCode());
        System.debug('@@@UpdateAccountsFromBHBatch body: ' + res.getBody());

        if(res.getStatusCode() == 200){
            String resBody = res.getBody();

            String apiBody = resBody.replace(resBody.substringBetween('"turnover":', ','), '"' + resBody.substringBetween('"turnover":', ',') + '"')
                    	  .replace(resBody.substringBetween('"ebitda":', ','), '"' + resBody.substringBetween('"ebitda":', ',') + '"')
                    	  .replace(resBody.substringBetween('"total_assets":', ','), '"' + resBody.substringBetween('"total_assets":', ',') + '"');
                    	//.replace(resBody.substringBetween('"audit_fees":', '}'), '"' + resBody.substringBetween('"audit_fees":', '}') + '"');
            System.debug('@@@apiBody: ' + apiBody);

            BeauhurstAPIUtility.Response getData = (BeauhurstAPIUtility.Response) JSON.deserialize(apiBody, BeauhurstAPIUtility.Response.class);
            if(!getData.results.isEmpty()){
                Set<String> retrievedCompanyIds = new Set<String>();
                Map<String, Id> bhIdToAccountIdMap = new Map<String, Id>();
                List<Account> accountsToUpdate = new List<Account>();
                for(BeauhurstAPIUtility.Result result : getData.results){
                    retrievedCompanyIds.add(result.id);
                }

                for(Account acc : [SELECT Id, Beauhurst_ID__c FROM Account WHERE Beauhurst_ID__c IN: retrievedCompanyIds]){
                    bhIdToAccountIdMap.put(acc.Beauhurst_ID__c, acc.Id);
                }

                for(BeauhurstAPIUtility.Result result : getData.results){
                    if(bhIdToAccountIdMap.containsKey(result.id)){
                        Id accId = bhIdToAccountIdMap.get(result.id);
                        accountsToUpdate.add(BeauhurstAPIUtility.collectAccount(accId, result));
                    }
                }

                if(!accountsToUpdate.isEmpty()){
                    update accountsToUpdate;
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }
}