public with sharing class CompaniesHouse_OfficerFieldMapping {
    
    public class Request_Data{
        // public Integer total_results;
        // public String kind;
        // public String etag;
        public List<Items> items;
        // public Integer items_per_page;
        // public Integer active_count;
        // public Integer resigned_count;
        // public Integer start_index;
        // public Integer inactive_count;
        public ItemLinks links;
    }

    public class PersonWrapper {
        public NameElements name_elements;
        public String nationality;
        public String country_of_residence;
        public Address address;
    }

    public class NameElements {
        public String title;
        public String forename;
        public String middle_name;
        public String surname;
    }

    public class Items {
        public String name;
        public String occupation;
        public Address address;
        public Links links;
        public String nationality;
        public String country_of_residence;
        public String officer_role;
        public Date appointed_on;
        public Date_of_birth date_of_birth;
        public Date resigned_on;
    }

    public class Links {
        public String self;
        public Officer officer;
    }

    public class Address {
        public String country;
        public String address_line_1;
        public String address_line_2;
        public String region;
        public String locality;
        public String premises;
        public String postal_code;
    }

    public class ItemLinks {
        // public String self;
        public Officer officer;
    }

    public class Officer {
        public String appointments;
    }
    
    public class Date_of_birth {
        public String month;
        public String year;
    }
    
    @AuraEnabled
    public static List<Officer__c> updateOfficerFields(Id accountId, String jsonString, Boolean proceedUpdate){
        Request_Data reqData = (Request_Data)System.JSON.deserialize(jsonString, Request_Data.class);
        Company_House_Setting__c settings = Company_House_Setting__c.getOrgDefaults();
        List<Officer__c> officerToUpdate = new List<Officer__c>();

        List<Officer__c> officerList = [
            SELECT Id, Officer_Key__c, Name, Title__c, Resident_Country__c, Nationality__c FROM Officer__c
            WHERE Account__c =: accountId
            AND Officer_Key__c != null
            WITH SECURITY_ENFORCED
        ];

        try{
            if(!reqData.items.isEmpty()){
                Map<String, Officer__c> mapKeyToOfficer = new Map<String, Officer__c>();
                for(Officer__c officerRec : officerList){
                    mapKeyToOfficer.put(officerRec.Officer_Key__c, officerRec);
                }

                if(!mapKeyToOfficer.isEmpty()){
                    for(Items item: reqData.items){
                        List<String> splitLink = item.links.self.split('/');
                        String officerKey = splitLink.get(splitLink.size() - 1);

                        if(mapKeyToOfficer.containsKey(officerKey)){
                            Officer__c officerRecord = mapKeyToOfficer.get(officerKey);

                            /*String premises =  item.address.premises;
                            String addressLine1 = item.address.address_line_1;
                            String streetValue = premises + ' ' + addressLine1;
                            System.debug('premises::' + premises);
                            System.debug('addressLine1::' + addressLine1);
                            System.debug('streetValue::' + streetValue);

                            if(settings.Contact_Address__c == 'Mailing'){
                                officerRecord.MailingStreet = streetValue; //MISMATCH IN THE MAPPING DOCU
                                officerRecord.MailingCity = item.address.locality; 
                                officerRecord.MailingState = item.address.region;
                                officerRecord.MailingPostalCode = item.address.postal_code;
                                officerRecord.MailingCountry = item.address.country;
                            } else if(settings.Contact_Address__c == 'Other'){
                                officerRecord.OtherStreet = streetValue;
                                officerRecord.OtherCity = item.address.locality;
                                officerRecord.OtherState = item.address.region;
                                officerRecord.OtherPostalCode = item.address.postal_code;
                                officerRecord.OtherCountry = item.address.country;
                            }
                            officerRecord.Appointed_On__c = item.appointed_on;*/
                            officerRecord.Title__c = item.officer_role;   
                            officerRecord.Resident_Country__c = item.country_of_residence;
                            officerRecord.Nationality__c = item.nationality;   
                            /*officerRecord.Resigned_On__c = item.resigned_on;   
                            officerRecord.Date_of_Birth_Month__c = item.date_of_birth.month;   
                            officerRecord.Date_of_Birth_Year__c = item.date_of_birth.year;*/
                            // officerRecord.Company_Director__c = item.officer_role.equalsIgnoreCase('director') ? true : false;
                            officerRecord.Companies_House_Run__c = true;
                            officerRecord.Companies_House_Run_Date__c = Date.today();
                            officerToUpdate.add(officerRecord);
                        }
                    }
                }
                
            }
            if(proceedUpdate){
                update officerToUpdate;
            }
            
            return officerToUpdate;
        }catch(Exception ex){
            System.debug('Error updating Contact' + ex.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static List<Officer__c> createNewOfficers(Id accountId, List<String> officerKey, String jsonString, String jsonString2, Boolean proceedCreate){
        System.debug('accountId:: ' + accountId);
        System.debug('officerKey:: ' + officerKey);
        System.debug('jsonString:: ' + jsonString);

        Company_House_Setting__c settings = Company_House_Setting__c.getOrgDefaults();
        List<Officer__c> officersToInsert = new List<Officer__c>();

        Request_Data reqData = (Request_Data)System.JSON.deserialize(jsonString, Request_Data.class);
        System.debug('Request_Data (createNewOfficers):: ' + reqData);
        
        List<PersonWrapper> personsData = new List<PersonWrapper>();
        if(jsonString2 != null){
            personsData =  (List<PersonWrapper>)JSON.deserialize(jsonString2, List<PersonWrapper>.class);
        }
        System.debug('PersonWrapper (personsData):: ' + personsData);
        
        try{
            if(!reqData.items.isEmpty()){
                for(Items item: reqData.items){
                    String[] nameParts = item.name.split(', ');
                    System.debug('nameParts: ' + nameParts);

                    List<String> splitLink = item.links.self.split('/');
                    String itemOfficerKey = splitLink.get(splitLink.size() - 1);

                    for (String key : officerKey) {
                        if (itemOfficerKey.equals(key)){
                            //Pass Item Name to Contact
                            String[] splitName = nameParts[1].split('\\s+', 2);
                            System.debug('splitName: ' + splitName);

                            String itemLastName = nameParts[0];
                            String itemFirstName = splitName[0];
                            String itemMiddleName = splitName.size() > 1 ? splitName[1] : '';
                            String itemSalutation = '';

                            String[] salutations = new String[]{'Mr', 'Ms', 'Mrs', 'Dr', 'Prof', 'Mx'};
                            for (String part : nameParts) {
                                if (salutations.contains(part)) {
                                    itemSalutation = part+'.';
                                }
                            }

                            System.debug('itemLastName: ' + itemLastName);
                            System.debug('itemMiddleName: ' + itemMiddleName);
                            System.debug('itemFirstName: ' + itemFirstName);
                            System.debug('itemSalutation: ' + itemSalutation);
                            Integer birthMonth = item.date_of_birth?.month != null ? Integer.valueOf(item.date_of_birth.month) : null;
                            Integer birthYear = item.date_of_birth?.year != null ? Integer.valueOf(item.date_of_birth.year) : null;
                            
                            System.debug('birthMonth: ' + birthMonth);
                            System.debug('birthYear: ' + birthYear);
                            /*String premises =  item.address.premises;
                            String addressLine1 = item.address.address_line_1;
                            String streetValue = premises + ' ' + addressLine1;
                            System.debug('premises::' + premises);
                            System.debug('addressLine1::' + addressLine1);
                            System.debug('streetValue::' + streetValue);*/

                            Officer__c newOfficer = new Officer__c();
                            newOfficer.Account__c = accountId;
                            newOfficer.Salutation__c = itemSalutation;
                            newOfficer.Last_Name__c = itemLastName;
                            newOfficer.First_Name__c = itemFirstName;
                            newOfficer.Middle_Name__c = itemMiddleName;
                            newOfficer.Officer_Key__c = itemOfficerKey;
                            /*if(settings.Contact_Address__c == 'Mailing'){
                                newOfficer.MailingStreet = streetValue;
                                newOfficer.MailingCity = item.address.locality ; 
                                newOfficer.MailingState = item.address.region;
                                newOfficer.MailingPostalCode = item.address.postal_code;
                                newOfficer.MailingCountry = item.address.country ;
                            } else if(settings.Contact_Address__c == 'Other'){
                                newOfficer.OtherStreet = streetValue;
                                newOfficer.OtherCity = item.address.locality ;
                                newOfficer.OtherState = item.address.region;
                                newOfficer.OtherPostalCode = item.address.postal_code;
                                newOfficer.OtherCountry = item.address.country ;
                            }
                            newOfficer.Appointed_On__c = item.appointed_on;
                            newOfficer.Title = item.officer_role;
                            newOfficer.Resident_Country__c = item.country_of_residence;
                            newOfficer.Nationality__c = item.nationality;
                            newOfficer.Description = item.occupation;
                            newOfficer.Date_of_Birth_Month__c = item.date_of_birth.month;
                            newOfficer.Date_of_Birth_Year__c = item.date_of_birth.year;
                            newOfficer.Birthdate = Date.newInstance(birthYear, birthMonth, 1);
                            newOfficer.Resigned_On__c = item.resigned_on;
                            newOfficer.Company_Director__c = item.officer_role.equalsIgnoreCase('director') ? true : false;*/
                            newOfficer.Date_of_Birth_Month__c = item.date_of_birth?.month;
                            newOfficer.Date_of_Birth_Year__c = item.date_of_birth?.year;
                            System.debug(' newOfficer.Date_of_Birth_Month__c: ' +  newOfficer.Date_of_Birth_Month__c);
                            System.debug(' newOfficer.Date_of_Birth_Year__: ' + newOfficer.Date_of_Birth_Year__c);
                            newOfficer.Birthdate__c = (birthYear != null && birthMonth != null ) ? Date.newInstance(birthYear, birthMonth, 1) : null;
                            newOfficer.Nationality__c = item.nationality;
                            newOfficer.Resident_Country__c = item.country_of_residence;
                            newOfficer.Title__c = item.officer_role;
                            newOfficer.Resigned_On__c = item.resigned_on;
                            newOfficer.Companies_House_Run__c = true;
                            newOfficer.Companies_House_Run_Date__c = Date.today();

                            PersonWrapper personData;

                            if(!personsData.isEmpty()){
                                for(PersonWrapper personItem : personsData){
                                    String personName = personItem.name_elements?.surname+', '+personItem.name_elements?.forename+(!String.isBlank(personItem.name_elements?.middle_name) ? ' '+personItem.name_elements.middle_name : '');
                                    System.debug('personName: ' + personName);
                                    if(personName != null && personName.toLowerCase() == item.name.toLowerCase()){
                                        personData = personItem;
                                    }
                                }
                            }
                            
                            if(personData != null){
                                if(newOfficer.First_Name__c == null && personData.name_elements.forename != null){
                                    newOfficer.First_Name__c = personData.name_elements.forename;
                                }
                                if(newOfficer.Middle_Name__c == null && personData.name_elements.middle_name != null){
                                    newOfficer.Middle_Name__c = personData.name_elements.middle_name;
                                }
                                if(newOfficer.Last_Name__c == null && personData.name_elements.surname != null){
                                    newOfficer.Last_Name__c = personData.name_elements.surname;
                                }
                                if(newOfficer.Nationality__c == null && personData.nationality != null){
                                    newOfficer.Nationality__c = personData.nationality;
                                }
                                if(newOfficer.Resident_Country__c == null && personData.country_of_residence != null){
                                    newOfficer.Resident_Country__c = personData.country_of_residence;
                                }
    
                                if(personData.address != null){
                                    newOfficer.MailingStreet__c = persondata.address.address_line_1 + ', ' + persondata.address.address_line_2;
                                    newOfficer.MailingCity__c = persondata.address.locality;
                                    newOfficer.MailingCountry__c = persondata.address.country;
                                    newOfficer.MailingPostalCode__c = persondata.address.postal_code;
                                }
                            }

                            officersToInsert.add(newOfficer);
                        }
                    }
                }
            }

            System.debug('officersToInsert:: ' + officersToInsert);
            System.debug('officersToInsert.size:: ' + officersToInsert.size());
            System.debug('proceedCreate?:: ' + proceedCreate);
            if(!officersToInsert.isEmpty() && proceedCreate){
                insert officersToInsert;
            }

            return officersToInsert;
        }catch(Exception ex){
            System.debug('Error creating Contacts: ' + ex.getMessage());
            return null;
        }
        
    }
}