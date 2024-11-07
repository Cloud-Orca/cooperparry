global class CreateAccountsFromBHBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global Set<String> ids;
    
    global CreateAccountsFromBHBatch(){
        this.ids = new Set<String>();
    }

    global CreateAccountsFromBHBatch(Set<String> ids){
        this.ids = ids;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, beauhurst_id__c';
        query += ' FROM Company_ID__c';
        query += ' WHERE beauhurst_id__c != null';
        if(!ids.isEmpty()){
            query += ' AND beauhurst_id__c IN: ids';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Company_ID__c> scope){
        Set<Id> companyRecordIds = new Set<Id>();
        String companyIds = '';
        Map<String, String> beauhurstIdToCollectionNameMap = new Map<String, String>();
        for(Company_ID__c ci : scope){
            companyRecordIds.add(ci.Id);
            companyIds += 'company_ids=' + ci.beauhurst_id__c + '&';
        }

        if(!companyRecordIds.isEmpty()){
            for(Collection_Item__c cItem : [SELECT Id, Company_ID__r.beauhurst_id__c, Company_Collection__r.collection_name__c FROM Collection_Item__c WHERE Company_ID__c IN: companyRecordIds]){
                beauhurstIdToCollectionNameMap.put(cItem.Company_ID__r.beauhurst_id__c, cItem.Company_Collection__r.collection_name__c);
            }
        }

        String append = '/companies?' + companyIds + 'includes=registered_name&includes=other_trading_names&includes=website&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees&includes=emails&includes=directors';

        Http http = new Http();
        HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
        if(res.getStatusCode() == 200){
            BeauhurstAPIUtility.Response getData = (BeauhurstAPIUtility.Response) JSON.deserialize(res.getBody(), BeauhurstAPIUtility.Response.class);
            if(!getData.results.isEmpty()){
                List<User> users = [SELECT Id FROM User WHERE Name = 'Sal Mingoia' AND isActive = true LIMIT 1];
                if(!users.isEmpty()){
                    List<Account> accountsToInsert = new List<Account>();
                    for(BeauhurstAPIUtility.Result result : getData.results){
                        Account acc = BeauhurstAPIUtility.collectAccount(null, result);
                        acc.Type = 'Target';
                        if(beauhurstIdToCollectionNameMap.containsKey(result.id)){
                            acc.BH_Collection_Name__c = beauhurstIdToCollectionNameMap.get(result.id);
                        }
                        acc.RecordTypeId = BeauhurstAPIUtility.getRecordTypeIdbyName('Account', 'Business Account');
                        acc.OwnerId = users[0].Id;
                        accountsToInsert.add(acc);
                    }
    
                    if(!accountsToInsert.isEmpty()){
                        Database.SaveResult[] results = Database.insert(accountsToInsert, false);
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }

    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
        public Basic basic;
        public Accounts latest_accounts;
        public List<Accounts> historic_accounts;
    }

    public class Basic{
        public String companies_house_id;
        public String employee_count_range;
    }

    public class Accounts{
        public Integer turnover;
        public Integer ebitda;
        public Integer total_assets;
    }
}