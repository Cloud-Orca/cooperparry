public class BeauhurstAPIUtility {
    public static HttpRequest constructReq(String append){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BeauhurstAPI' + append);
        req.setMethod('GET');
        req.setTimeOut(120000);
        return req;
    }

    @AuraEnabled
    public static UIWrapper updateFromBH(Id accId){
        UIWrapper wrap = new UIWrapper();
        wrap.success = false;
        wrap.errorMsg = '';
        try{
            List<Account> accounts = [SELECT Id, Beauhurst_ID__c FROM Account WHERE Id =: accId LIMIT 1];
            if(!accounts.isEmpty()){
                String append = '/companies?company_ids=' + accounts[0].Beauhurst_ID__c + '&includes=registered_name&includes=other_trading_names&includes=website&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees&includes=emails&includes=directors';
                
                Http http = new Http();
                HttpResponse res = http.send(constructReq(append));

                System.debug('@@@res status code: ' + res.getStatusCode());
                System.debug('@@@res body: ' + res.getBody());

                if(res.getStatusCode() == 200){
                    wrap.success = true;
					
                    Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    List<Object> results = (List<Object>)resp.get('results');
                    if(results != null && results.size() > 0){
                        Map<String, Object> resultItem = (Map<String, Object>)results[0];
                        
                        Account acc = collectAccount(accounts[0].Id, resultItem);
                        update acc;
                    }
                    
                    /*Response getData = (Response) JSON.deserialize(res.getBody(), Response.class);
                    if(!getData.results.isEmpty()){
                        Account acc = collectAccount(accounts[0].Id, getData.results[0]);
                        update acc;
                    }*/
                }else{
                    wrap.errorMsg = 'API Error';
                }
            }
        }catch(Exception e) {
            wrap.success = false;
            wrap.errorMsg = e.getMessage() + ' line ' + e.getLineNumber();
        }
        return wrap;
    }
    
    public static Account collectAccount(Id accId, Map<String, Object> resultItem){
        Account acc = new Account();
        if(accId != null){
            acc.Id = accId;
        }else{
            acc.Beauhurst_ID__c = String.valueOf(resultItem.get('id'));
        }
        acc.Beauhurst_Updated_Date__c = System.now();
        if(resultItem.get('basic') != null){
            Map<String, Object> basic = (Map<String, Object>)resultItem.get('basic');
            if(basic.get('registered_name') != null){
                acc.Registered_Name__c = String.valueOf(basic.get('registered_name'));
            }
            if(basic.get('other_trading_names') != null){
                List<Object> other_trading_names_obj = (List<Object>)basic.get('other_trading_names'); 
                if(!other_trading_names_obj.isEmpty()){
                    List<String> other_trading_names = String.join(other_trading_names_obj,';').split(';');
                    acc.Other_Trading_Names__c = listToString(other_trading_names);
                }
            }
            if(basic.get('website') != null){
                acc.Website = String.valueOf(basic.get('website'));
            }
            if(basic.get('ultimate_parent_company') != null){
                Map<String, Object> parent = (Map<String, Object>)basic.get('ultimate_parent_company');
                if(parent.get('companies_house_id') != null){
                    acc.Parent_Company_Companies_House_Id__c = String.valueOf(parent.get('companies_house_id'));
                }
                if(parent.get('name') != null){
                    acc.Ultimate_Parent_Company_Name__c = String.valueOf(parent.get('name'));
                }
            }
        }
        
        if(resultItem.get('classification') != null){
            Map<String, Object> classification = (Map<String, Object>)resultItem.get('classification');
            
            if(classification.get('top_level_industry_groups') != null){
                List<Object> top_level_industry_groups_obj = (List<Object>)classification.get('top_level_industry_groups'); 
                if(!top_level_industry_groups_obj.isEmpty()){
                    List<String> top_level_industry_groups = String.join(top_level_industry_groups_obj,';').split(';');
                    acc.Top_Level_Industry_Groups__c = listToString(top_level_industry_groups);
                }
            }
            if(classification.get('top_level_sector_groups') != null){
                List<Object> top_level_sector_groups_obj = (List<Object>)classification.get('top_level_sector_groups'); 
                if(!top_level_sector_groups_obj.isEmpty()){
                    List<String> top_level_sector_groups = String.join(top_level_sector_groups_obj,';').split(';');
                    acc.Top_Level_Sector_Groups__c = listToString(top_level_sector_groups);
                }
            }
            if(classification.get('buzzwords') != null){
                List<Object> buzzwords_obj = (List<Object>)classification.get('buzzwords'); 
                if(!buzzwords_obj.isEmpty()){
                    List<String> buzzwords = String.join(buzzwords_obj,';').split(';');
                    acc.Buzzwords__c = listToString(buzzwords);
                }
            }
            if(classification.get('latest_stage_of_evolution') != null){
                acc.Latest_Stage_Of_Evolution__c = String.valueOf(classification.get('latest_stage_of_evolution'));
            }
            if(classification.get('legal_form') != null){
                acc.Legal_Form__c = String.valueOf(classification.get('legal_form'));
            }
        }
        
        if(resultItem.get('latest_accounts') != null){
			Map<String, Object> latest = (Map<String, Object>)resultItem.get('latest_accounts');       
            
            if(latest.get('year_end_date') != null){
                acc.Year_End_Date__c = stringToDate(String.valueOf(latest.get('year_end_date')));
            }
            if(latest.get('turnover') != null){
                acc.Turnover__c = Decimal.valueOf(String.valueOf(latest.get('turnover')));
            }
            if(latest.get('ebitda') != null){
                acc.EBITDA__c = Decimal.valueOf(String.valueOf(latest.get('ebitda')));
            }
            if(latest.get('total_assets') != null){
                acc.Total_Assets__c = Decimal.valueOf(String.valueOf(latest.get('total_assets')));
            }
            if(latest.get('number_of_employees') != null){
                acc.NumberOfEmployees = Integer.valueOf(latest.get('number_of_employees'));
            }
            if(latest.get('auditor') != null){
                acc.Auditor__c = String.valueOf(latest.get('auditor'));
            }
            if(latest.get('audit_fees') != null){
                acc.Audit_Fees__c = String.valueOf(latest.get('audit_fees'));
            }
            System.debug('@@@acc: ' + acc);
        }
        return acc;
    }

    /*public static Account collectAccount(Id accId, Result res){
        Account acc = new Account();
        if(accId != null){
            acc.Id = accId;
        }else{
            acc.Beauhurst_ID__c = res.id;
        }
        acc.Beauhurst_Updated_Date__c = System.now();
        if(res.basic != null){
            Basic basic = res.basic;
            if(basic.name != null){
                acc.Name = basic.name;
            }
            if(basic.registered_name != null){
                acc.Registered_Name__c = basic.registered_name;
            }
            if(!basic.other_trading_names.isEmpty()){
                acc.Other_Trading_Names__c = listToString(basic.other_trading_names);
            }
            if(basic.website != null){
                acc.Website = basic.website;
            }
            if(basic.ultimate_parent_company != null){
                ParentCompany parent = basic.ultimate_parent_company;
                if(parent.companies_house_id != null){
                    acc.Parent_Company_Companies_House_Id__c = parent.companies_house_id;
                }
                if(parent.name != null){
                    acc.Ultimate_Parent_Company_Name__c = parent.name;
                }
            }
        }
        if(res.classification != null){
            Classification classInfo = res.classification;
            if(!classInfo.top_level_industry_groups.isEmpty()){
                acc.Top_Level_Industry_Groups__c = listToString(classInfo.top_level_industry_groups);
            }
            if(classInfo.top_level_sector_groups != null){
                if(!classInfo.top_level_sector_groups.isEmpty()){
                    acc.Top_Level_Sector_Groups__c = listToString(classInfo.top_level_sector_groups);
                }
             }
            if(!classInfo.buzzwords.isEmpty()){
                acc.Buzzwords__c = listToString(classInfo.buzzwords);
            }
            if(classInfo.latest_stage_of_evolution != null){
                acc.Latest_Stage_Of_Evolution__c = classInfo.latest_stage_of_evolution;
            }
            if(classInfo.legal_form != null){
                acc.Legal_Form__c = classInfo.legal_form;
            }
        }
        if(res.latest_accounts != null){
            Accounts latest = res.latest_accounts;
            if(latest.year_end_date != null){
                acc.Year_End_Date__c = Date.valueOf(latest.year_end_date);
            }
            if(latest.turnover != null){
                acc.Turnover__c = Decimal.valueOf(latest.turnover);
            }
            if(latest.ebitda != null){
                acc.EBITDA__c = Decimal.valueOf(latest.ebitda);
            }
            if(latest.total_assets != null){
                acc.Total_Assets__c = Decimal.valueOf(latest.total_assets);
            }
            if(latest.number_of_employees != null){
                acc.NumberOfEmployees = latest.number_of_employees;
            }
            if(latest.auditor != null){
                acc.Auditor__c = latest.auditor;
            }
            if(latest.audit_fees != null){
                acc.Audit_Fees__c = String.valueOf(latest.audit_fees);
            }
        }
        return acc;
    }*/

    public static String listToString(List<String> strList){
        String strVal = String.join(strList, ',');
        return (strVal.length() > 255) ? strVal.left(255) : strVal;
    }
    
    public static Date stringToDate(String strDate){
        List<String> strDates = strDate.split('-');
        return Date.newInstance(Integer.valueOf(strDates[0]), Integer.valueOf(strDates[1]), Integer.valueOf(strDates[2]));
    }

    public static Id getRecordTypeIdbyName(String objectName, String strRecordTypeName){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
    }

    /*public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
        public Basic basic;
        public Classification classification;
        public ContactInfo contact_information;
        public Accounts latest_accounts;
        public List<Director> directors;
    }

    public class Basic{
        public String name;
        public String registered_name;
        public List<String> other_trading_names;
        public String website;
        public ParentCompany ultimate_parent_company;
    }

    public class ParentCompany{
        public String name;
        public String companies_house_id;
    }

    public class Classification{
        public List<String> top_level_sector_groups;
        public List<String> top_level_industry_groups;
        public List<String> buzzwords;
        public String latest_stage_of_evolution;
        public String legal_form;
    }

    public class ContactInfo{
        public List<String> emails;
    }

    public class Accounts{
        public String year_end_date;
        public String turnover;
        public String ebitda;
        public String total_assets;
        public Integer number_of_employees;
        public String auditor;
        public Integer audit_fees;
    }
    
    public class Director{
        public String people_id;
        public String name;
        public String email;
        public String from_date;
        public String until_date;
        public Boolean currently_active;
    }*/

    public class UIWrapper{
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMsg;
    }
}