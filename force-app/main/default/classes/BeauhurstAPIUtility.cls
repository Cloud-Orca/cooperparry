public class BeauhurstAPIUtility {
    public static HttpRequest constructReq(String append){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BeauhurstAPI' + append);
        //req.setEndpoint('https://platform.beauhurst.com/_api/v1' + append);
        //req.setHeader('Authorization', 'apikey OxbSnsga7gM-qhvNDgBbQ3AtNg1ptj8c');
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
                if(res.getStatusCode() == 200){
                    wrap.success = true;
                    Response getData = (Response) JSON.deserialize(res.getBody(), Response.class);
                    if(!getData.results.isEmpty()){
                        Account acc = collectAccount(accounts[0].Id, getData.results[0]);
                        update acc;
                    }
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

    public static Account collectAccount(Id accId, Result res){
        Account acc = new Account();
        if(accId != null){
            acc.Id = accId;
        }else{
            acc.Beauhurst_ID__c = res.id;
        }
        acc.Beauhurst_Updated_Date__c = System.now();
        if(res.basic != null){
            Basic basic = res.basic;
            acc.Name = basic.name;
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
        ld.Beauhurst_Updated_Date__c = System.now();
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

    public static Id getRecordTypeIdbyName(String objectName, String strRecordTypeName){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
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

    public class UIWrapper{
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMsg;
    }
}