public class BeauhurstAPIUtility {
    public static HttpRequest constructReq(String append){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BeauhurstAPI' + append);
        req.setMethod('GET');
        req.setTimeOut(120000);
        return req;
    }

    public static Account collectAccount(Id accId, Result res){
        Account acc = new Account(Id=accId);
        if(res.basic != null){
            Basic basic = res.basic;
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
            if(!classInfo.top_level_sector_groups.isEmpty()){
                acc.Top_Level_Sector_Groups__c = listToString(classInfo.top_level_sector_groups);
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
    }

    public static Lead collectLead(Id ldId, Result res){
        Lead ld = new Lead();
        if(ldId != null){
            ld.Id = ldId;
        }else{
            ld.Beauhurst_ID__c = res.id;
        }
        if(res.basic != null){
            Basic basic = res.basic;
            if(basic.registered_name != null){
                ld.FirstName = (basic.registered_name.length() > 40) ? basic.registered_name.left(40) : basic.registered_name;
                ld.LastName = 'Unknown';
                
                ld.Company = basic.registered_name;
                ld.Registered_Name__c = basic.registered_name;
            }
            if(!basic.other_trading_names.isEmpty()){
                ld.Other_Trading_Names__c = listToString(basic.other_trading_names);
            }
            if(basic.website != null){
                ld.Website = basic.website;
            }
            if(basic.ultimate_parent_company != null){
                ParentCompany parent = basic.ultimate_parent_company;
                if(parent.companies_house_id != null){
                    ld.Parent_Company_Companies_House_Id__c = parent.companies_house_id;
                }
                if(parent.name != null){
                    ld.Ultimate_Parent_Company_Name__c = parent.name;
                }
            }
        }
        if(res.classification != null){
            Classification classInfo = res.classification;
            if(!classInfo.top_level_industry_groups.isEmpty()){
                ld.Top_Level_Industry_Groups__c = listToString(classInfo.top_level_industry_groups);
            }
            if(!classInfo.top_level_sector_groups.isEmpty()){
                ld.Top_Level_Sector_Groups__c = listToString(classInfo.top_level_sector_groups);
            }
            if(!classInfo.buzzwords.isEmpty()){
                ld.Buzzwords__c = listToString(classInfo.buzzwords);
            }
            if(classInfo.latest_stage_of_evolution != null){
                ld.Latest_Stage_Of_Evolution__c = classInfo.latest_stage_of_evolution;
            }
            if(classInfo.legal_form != null){
                ld.Legal_Form__c = classInfo.legal_form;
            }
        }
        if(res.latest_accounts != null){
            Accounts latest = res.latest_accounts;
            if(latest.year_end_date != null){
                ld.Year_End_Date__c = Date.valueOf(latest.year_end_date);
            }
            if(latest.turnover != null){
                ld.Turnover__c = Decimal.valueOf(latest.turnover);
            }
            if(latest.ebitda != null){
                ld.EBITDA__c = Decimal.valueOf(latest.ebitda);
            }
            if(latest.total_assets != null){
                ld.Total_Assets__c = Decimal.valueOf(latest.total_assets);
            }
            if(latest.number_of_employees != null){
                ld.NumberOfEmployees = latest.number_of_employees;
            }
            if(latest.auditor != null){
                ld.Auditor__c = latest.auditor;
            }
            if(latest.audit_fees != null){
                ld.Audit_Fees__c = String.valueOf(latest.audit_fees);
            }
        }
        if(res.contact_information != null){
            if(!res.contact_information.emails.isEmpty()){
                ld.Email = res.contact_information.emails[0];
            }
        }
        if(!res.directors.isEmpty()){
            String activeDirectors = '';
            for(Director dir : res.directors){
                if(dir.currently_active){
                    activeDirectors += dir.Name + ',';
                }
            }
            ld.Directors__c = activeDirectors.removeEnd(',');
        }
        return ld;
    }

    public static String listToString(List<String> strList){
        String strVal = String.join(strList, ',');
        return (strVal.length() > 255) ? strVal.left(255) : strVal;
    }


    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
        public Basic basic;
        public Classification classification;
        public ContactInfo contact_information;
        public Accounts latest_accounts;
        public List<Accounts> historic_accounts;
        public List<Director> directors;
    }

    public class Basic{
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
        public Integer turnover;
        public Integer ebitda;
        public Integer total_assets;
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
    }
}