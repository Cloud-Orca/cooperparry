global class CreateLeadsFromBHBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global Set<String> ids;
    
    global CreateLeadsFromBHBatch(){
        this.ids = new Set<String>();
    }

    global CreateLeadsFromBHBatch(Set<String> ids){
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
        String companyIds = '';
        for(Company_ID__c ci : scope){
            companyIds += 'company_ids=' + ci.beauhurst_id__c + '&';
        }

        String append = '/companies?' + companyIds + 'includes=registered_name&includes=other_trading_names&includes=website&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees&includes=emails&includes=directors';

        Http http = new Http();
        HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
        if(res.getStatusCode() == 200){
            BeauhurstAPIUtility.Response getData = (BeauhurstAPIUtility.Response) JSON.deserialize(res.getBody(), BeauhurstAPIUtility.Response.class);
            if(!getData.results.isEmpty()){
                List<Lead> leadsToInsert = new List<Lead>();
                for(BeauhurstAPIUtility.Result result : getData.results){
                    leadsToInsert.add(BeauhurstAPIUtility.collectLead(null, result));
                }

                if(!leadsToInsert.isEmpty()){
                    insert leadsToInsert;
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