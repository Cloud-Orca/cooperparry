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

        System.debug('@@@companyIds: ' + companyIds);

        if(!companyRecordIds.isEmpty()){
            for(Collection_Item__c cItem : [SELECT Id, Company_ID__r.beauhurst_id__c, Company_Collection__r.collection_name__c FROM Collection_Item__c WHERE Company_ID__c IN: companyRecordIds]){
                beauhurstIdToCollectionNameMap.put(cItem.Company_ID__r.beauhurst_id__c, cItem.Company_Collection__r.collection_name__c);
            }
        }

        System.debug('@@@beauhurstIdToCollectionNameMap: ' + beauhurstIdToCollectionNameMap);

        String append = '/companies?' + companyIds + 'includes=name&includes=registered_name&includes=other_trading_names&includes=website&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees&includes=emails&includes=directors';

        Http http = new Http();
        HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));

        System.debug('@@@res code: ' + res.getStatusCode());
        System.debug('@@@res body: ' + res.getBody());

        if(res.getStatusCode() == 200){
            Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> results = (List<Object>)resp.get('results');

            if(results != null && results.size() > 0){
                List<User> users = [SELECT Id FROM User WHERE Name = 'Sal Mingoia' AND isActive = true LIMIT 1];
                System.debug('@@@users: ' + users);
                if(!users.isEmpty()){
                    List<Account> accountsToInsert = new List<Account>();

                    for(Object result : results){
                        Map<String, Object> resultItem = (Map<String, Object>)result;
                        if(resultItem.get('id') != null){
                            String resultId = String.valueOf(resultItem.get('id'));
                            Account acc = BeauhurstAPIUtility.collectAccount(null, resultItem);
                            acc.Type = 'Target';
                            if(beauhurstIdToCollectionNameMap.containsKey(resultId)){
                                acc.BH_Collection_Name__c = beauhurstIdToCollectionNameMap.get(resultId);
                            }
                            acc.RecordTypeId = BeauhurstAPIUtility.getRecordTypeIdbyName('Account', 'Business Account');
                            acc.OwnerId = users[0].Id;
                            accountsToInsert.add(acc);
                        }
                    }

                    System.debug('@@@accountsToInsert: ' + accountsToInsert);
                    if(!accountsToInsert.isEmpty()){
                        Database.SaveResult[] saveResults = Database.insert(accountsToInsert, false);
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
    }

    public class Basic{
        public String registered_name;
        public String companies_house_id;
        public String employee_count_range;
    }

    public class Accounts{
        public String turnover;
        public String ebitda;
        public String total_assets;
    }
}