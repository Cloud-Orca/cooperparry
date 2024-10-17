global class UpdateLeadsFromBHBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global Set<Id> ids;
    
    global UpdateLeadsFromBHBatch(){
        this.ids = new Set<Id>();
    }

    global UpdateLeadsFromBHBatch(Set<Id> ids){
        this.ids = ids;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, Beauhurst_ID__c';
        query += ' FROM Lead';
        query += ' WHERE Beauhurst_ID__c != null';
        if(!ids.isEmpty()){
            query += ' AND Id IN: ids';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope){
        String companyIds = '';
        for(Lead ld : scope){
            companyIds += 'company_ids=' + ld.Beauhurst_ID__c + '&';
        }

        String append = '/companies?' + companyIds + 'includes=registered_name&includes=other_trading_names&includes=website&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees&includes=emails&includes=directors';

        Http http = new Http();
        HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
        if(res.getStatusCode() == 200){
            BeauhurstAPIUtility.Response getData = (BeauhurstAPIUtility.Response) JSON.deserialize(res.getBody(), BeauhurstAPIUtility.Response.class);
            if(!getData.results.isEmpty()){
                Set<String> retrievedCompanyIds = new Set<String>();
                Map<String, Id> bhIdToLeadIdMap = new Map<String, Id>();
                List<Lead> leadsToUpdate = new List<Lead>();
                for(BeauhurstAPIUtility.Result result : getData.results){
                    retrievedCompanyIds.add(result.id);
                }

                for(Lead ld : [SELECT Id, Beauhurst_ID__c FROM Lead WHERE Beauhurst_ID__c IN: retrievedCompanyIds]){
                    bhIdToLeadIdMap.put(ld.Beauhurst_ID__c, ld.Id);
                }

                for(BeauhurstAPIUtility.Result result : getData.results){
                    if(bhIdToLeadIdMap.containsKey(result.id)){
                        Id ldId = bhIdToLeadIdMap.get(result.id);
                        leadsToUpdate.add(BeauhurstAPIUtility.collectLead(ldId, result));
                    }
                }

                if(!leadsToUpdate.isEmpty()){
                    update leadsToUpdate;
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