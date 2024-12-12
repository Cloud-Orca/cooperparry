public with sharing class CompaniesHouse_AccountFieldMapping {

    public class Request_Data{
        public Links links;
        public String company_name;
        public List<String> sic_codes;
        public String company_number;
        public Confirmation_statement confirmation_statement;
        public String company_status;
        public Boolean has_insolvency_history;
        public Boolean undeliverable_registered_office_address;
        public Boolean registered_office_is_in_dispute;
        public String type;
        public String jurisdiction;
        public Accounts accounts;
        public Boolean has_charges;
        public Registered_office_address registered_office_address;
        public Date date_of_cessation;
        public Date date_of_creation;
        public String etag;
        public Boolean has_super_secure_pscs;
        public Boolean can_file;
        public Date last_full_members_list_date;
    }

    public class Links {
        //public String filing_history;
        //public String persons_with_significant_control;
        public String self;
        public String officers;
    }

    public class Confirmation_statement {
        public Boolean overdue;
        public Date next_made_up_to;
        public Date last_made_up_to;
        public Date next_due;
    }

    public class Accounts {
        //public Accounting_reference_date accounting_reference_date;
        public Date next_due;
        // public String next_made_up_to;
        public Boolean overdue;
        public Last_accounts last_accounts;
        public Next_accounts next_accounts;
    }

    // public class Accounting_reference_date {
    //  public String month;
    //  public String day;
    // }

    public class Last_accounts {
        public Date made_up_to;
        public Date period_end_on;
        public String type;
        public Date period_start_on;
    }

    public class Next_accounts {
        public Date period_end_on;
        public Date due_on;
        public Date period_start_on;
        //public Boolean overdue;
    }

    public class Registered_office_address {
        public String postal_code;
        public String address_line_1;
        public String address_line_2;
        public String country;
        public String locality;
        public String region;
    }

    public class Officers_Request_Data{
        public Integer active_count;
        public Integer resigned_count;
        public Integer inactive_count;
    }


    @AuraEnabled
    public static Account updateAccountFields(Id recordId, String companyKey, String jsonString, Boolean proceedUpdate, String jsonOfficers){
        Request_Data reqData = (Request_Data)System.JSON.deserialize(jsonString, Request_Data.class);
        //Officers_Request_Data officersData = (Officers_Request_Data)System.JSON.deserialize(jsonOfficers, Officers_Request_Data.class);
        Company_House_Setting__c settings = Company_House_Setting__c.getOrgDefaults();
        
        List<Account> accountList = [
            SELECT Id, Name, Company_Legal_Name__c, Company_registration_number__c, CH_Company_Type__c, Legal_Type__c, 
                    BillingAddress, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet,
                    Incorporation_Date__c, Source__c, Source_Type__c, Date_of_Creation__c, Companies_House_Run__c, Companies_House_Run_Date__c
            FROM Account
            WHERE Id =: recordId /* AND (Company_registration_number__c =: companyKey) */
            WITH SECURITY_ENFORCED
        ];
        System.debug('accountList:: ' + accountList);
        System.debug('accountList[0]:: ' + accountList[0]);
        Account currentRecord = accountList[0];
        System.debug('currentRecord:: ' + currentRecord);
        // try{
            String sicCodesAsString = String.join(reqData.sic_codes, ', ');
            if(reqData != null){
                // currentRecord.Name = reqData.company_name;
                currentRecord.CH_Name__c = reqData.company_name;
                currentRecord.Legal_Name__c = reqData.company_name;
                currentRecord.Company_Legal_Name__c = reqData.company_name;
                // currentRecord.Company_registration_number__c = reqData.company_number; 
                currentRecord.Companies_House_Id__c = reqData.company_number; 
                /*currentRecord.Company_status__c = reqData.company_status; 
                currentRecord.CH_Company_Type__c = reqData.type; 
                currentRecord.Company_Profile__c = reqData.links.self;
                currentRecord.Date_of_Cessation__c = reqData.date_of_cessation; 
                currentRecord.Date_of_Creation__c = reqData.date_of_creation; 
                currentRecord.SIC_Codes__c = sicCodesAsString; 
                if(settings.Account_Address__c == 'Billing'){*/
                currentRecord.CH_Company_Type__c = reqData.type; 
                // currentRecord.Legal_Type__c = reqData.type;
                currentRecord.CH_SIC_Codes__c = sicCodesAsString; 
                currentRecord.Companies_House_Data_Last_Updated_On__c = reqData.last_full_members_list_date;

                if(reqData.registered_office_address != null){
                    currentRecord.BillingStreet = '';
                    if(reqData.registered_office_address.address_line_1 != null && reqData.registered_office_address.address_line_1 != ''){
                        currentRecord.BillingStreet = reqData.registered_office_address.address_line_1;
                        currentRecord.CH_Address__Street__s = reqData.registered_office_address.address_line_1;
                    }
                    if(reqData.registered_office_address.address_line_2 != null && reqData.registered_office_address.address_line_2 != ''){
                        currentRecord.BillingStreet += ', ' + reqData.registered_office_address.address_line_2;
                        currentRecord.CH_Address__Street__s += ', ' + reqData.registered_office_address.address_line_2;
                    }
                    if(reqData.registered_office_address.locality != null && reqData.registered_office_address.locality != ''){
                        currentRecord.BillingCity = reqData.registered_office_address.locality;
                        currentRecord.CH_Address__City__s = reqData.registered_office_address.locality;
                    }
                    if(reqData.registered_office_address.postal_code != null && reqData.registered_office_address.postal_code != ''){
                        currentRecord.BillingPostalCode = reqData.registered_office_address.postal_code;
                        currentRecord.CH_Address__PostalCode__s = reqData.registered_office_address.postal_code;
                    }
                    if(reqData.registered_office_address.country != null && reqData.registered_office_address.country != ''){
                        currentRecord.BillingCountry = reqData.registered_office_address.country;
                        currentRecord.CH_Address__CountryCode__s = getCountryCode(reqData.registered_office_address.country);
                    }
                }
             
                // currentRecord.BillingStreet = reqData.registered_office_address?.address_line_1;
                // currentRecord.BillingCity = reqData.registered_office_address?.address_line_2;
                // currentRecord.BillingState = reqData.registered_office_address?.locality;
                // currentRecord.BillingPostalCode = reqData.registered_office_address?.postal_code;
                // currentRecord.BillingCountry = reqData.registered_office_address?.country;

                currentRecord.Incorporation_Date__c = reqData.date_of_creation != null ? Date.valueOf(reqData.date_of_creation) : null;
                currentRecord.CH_Incorporation_Date__c = reqData.date_of_creation != null ? Date.valueOf(reqData.date_of_creation) : null;
                currentRecord.Date_of_Creation__c = reqData.date_of_creation; 
                currentRecord.Companies_House_Run__c = true;
                currentRecord.Companies_House_Run_Date__c = Date.today();

                /*} else if(settings.Account_Address__c == 'Shipping') {
                    currentRecord.ShippingStreet = reqData.registered_office_address.address_line_1;
                    currentRecord.ShippingCity = reqData.registered_office_address.locality;
                    currentRecord.ShippingState = reqData.registered_office_address.region;
                    currentRecord.ShippingPostalCode = reqData.registered_office_address.postal_code;
                    currentRecord.ShippingCountry = reqData.registered_office_address.country;
                }*/

                // currentRecord.Confirmation_Statement_Overdue__c = reqData.confirmation_statement.overdue; 
                // currentRecord.Confirmation_Statement_Next_Made_Up_To__c = reqData.confirmation_statement.next_made_up_to; 
                // currentRecord.Confirmation_Statement_Next_Due__c = reqData.confirmation_statement.next_due; 
                // currentRecord.Confirmation_Statement_Last_Made_Up_To__c = reqData.confirmation_statement.last_made_up_to; 
                // currentRecord.Has_Insolvency_History__c = reqData.has_insolvency_history; 
                // currentRecord.Undeliverable_Registered_Office_Address__c = reqData.undeliverable_registered_office_address; 
                // currentRecord.Registered_Office_Is_In_Dispute__c = reqData.registered_office_is_in_dispute; 
                // currentRecord.Company_Jurisdiction__c = reqData.jurisdiction; 
                // currentRecord.Company_Accounts_Next_Due__c = reqData.accounts.next_due; 
                // currentRecord.Company_Accounts_Period_End_On__c = reqData.accounts.next_accounts.period_end_on;
                // currentRecord.Company_Accounts_Due_On__c = reqData.accounts.next_accounts.due_on; 
                // currentRecord.Company_Accounts_Period_Start_On__c = reqData.accounts.next_accounts.period_start_on;
                // currentRecord.Company_Accounts_Overdue__c = reqData.accounts.overdue;
                // currentRecord.Last_Accounts_Type__c = reqData.accounts.last_accounts.type;
                // currentRecord.Last_Accounts_Period_Start_On__c = reqData.accounts.last_accounts.period_start_on;
                // currentRecord.Last_Accounts_Made_Up_To__c = reqData.accounts.last_accounts.made_up_to;
                // currentRecord.Last_Accounts_Period_End_On__c = reqData.accounts.last_accounts.period_end_on;
                 currentRecord.CH_Year_End_Date__c = reqData.accounts.last_accounts.period_end_on != null ? Date.valueOf(reqData.accounts.last_accounts.period_end_on) : null;
                 currentRecord.CH_Accounts_Next_Due__c = reqData?.accounts?.next_accounts?.due_on != null ? Date.valueOf(reqData.accounts.next_accounts.due_on) : null; 
                // currentRecord.Company_Has_Charges__c = reqData.has_charges;
                // currentRecord.Etag__c = reqData.etag;
                // currentRecord.Active_Company_Directors__c = officersData.active_count;
                // currentRecord.Inactive_Company_Directors__c = officersData.inactive_count;
                // currentRecord.Resigned_Company_Directors__c = officersData.resigned_count;
                // currentRecord.Company_Officer_Link__c = reqData.links.officers;
            }


            if(proceedUpdate){
                currentRecord.Bypass_Validation__c = true;
                
                System.debug('currentRecord (mapped?): '+currentRecord);
                update currentRecord;

                Account deactBypass = new Account(
                    Id = currentRecord.Id,
                    Bypass_Validation__c = false
                );
                System.debug('deacting: '+deactBypass);
                update deactBypass;
            }

            return currentRecord;
        // }catch(Exception ex){
        //     System.debug('Error updating Account' + ex.getMessage());
        //     return null;
        // }
    }

    public static String getCountryCode(String country){
        String code;

        if( country == 'England' ){
            country = 'United Kingdom';
        }

        List<Schema.PicklistEntry> values = Account.CH_Address__CountryCode__s.getDescribe().getPickListValues();
        for (Schema.PicklistEntry v : values) {
            if(country == v.getLabel() ){
                code = v.getValue();
            }
        }
        return code;
    }
}