public with sharing class MassConvertLeadsController {

    @AuraEnabled(cacheable=true)
    public static List<Lead> getDataToDisplayActivity(Id leadId){ 
        Set<Id> matchedLeadIds = LeadMatchingRuleUtility.getAllLeadMatching(leadId);
        matchedLeadIds.add(leadId);
        return [SELECT Id, Name, Company, Is_Primary__c FROM Lead WHERE Id IN: matchedLeadIds];
    }

    @AuraEnabled
    public static String massConvertLeads(List<String> leadConvertIds, Id primaryLeadId, Id accountIdToUpdate, Id opportunityIdToUpdate, Boolean createNewOpportunity, Id accountRecordTypeId, String opportunityRecordTypeId){
        
        Savepoint sp = Database.setSavepoint();

        // Lead Converted Status
        List<String> convertedStatusesNames = new List<String>();
        List<LeadStatus> convertedStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true];
        for(LeadStatus status : convertedStatuses) {
            convertedStatusesNames.add(status.MasterLabel);
        }

        
        try {
            if(accountIdToUpdate == null && opportunityIdToUpdate == null){
                // PRIMARY LEAD CONVERSION START
                Database.LeadConvert lcPrimaryLead = new Database.LeadConvert();
                lcPrimaryLead.setLeadId(primaryLeadId);
                lcPrimaryLead.setConvertedStatus(convertedStatusesNames.get(0));

                if(!createNewOpportunity){
                    lcPrimaryLead.setDoNotCreateOpportunity(true);
                }
                // PRIMARY LEAD CONVERSION END

                Id convertedAccountId;
                Id convertedOpportunityId;
                Database.LeadConvertResult lcrPrimaryLead = Database.convertLead(lcPrimaryLead);
                if(lcrPrimaryLead.isSuccess()){

                    // Get the Id of Created Account of the converted Primary Lead
                    convertedAccountId = lcrPrimaryLead.getAccountId();
                    
                    // Get the Id of Created Opportunity of the converted Primary Lead if createNewOpportunity is True
                    if(createNewOpportunity){
                        convertedOpportunityId = lcrPrimaryLead.getOpportunityId();
                    }
                }

                // NOT PRIMARY LEAD CONVERSION START
                List<Database.LeadConvert> massConvertLeads = new List<Database.LeadConvert>();
                for (String leadConvertId : leadConvertIds) {    
                    Database.LeadConvert lcNotPrimary = new database.LeadConvert();   
                    if(leadConvertId != primaryLeadId){ // Not Primary Lead
                        lcNotPrimary.setLeadId(leadConvertId);
                        lcNotPrimary.setConvertedStatus(convertedStatusesNames.get(0));
                        lcNotPrimary.setAccountId(convertedAccountId);
                        lcNotPrimary.setDoNotCreateOpportunity(true);
                        massConvertLeads.add(lcNotPrimary);
                    }
                }

                // NOT PRIMARY LEAD CONVERSION END 
                Set<Id> convertedContactIds = new Set<Id>();
                if(!massConvertLeads.isEmpty()){
                    Database.LeadConvertResult[] lcrList = Database.convertLead(massConvertLeads);
                    for(Database.LeadConvertResult lcrFinal : lcrList){
                        convertedContactIds.add(lcrFinal.getContactId());
                    }
                    System.debug('@@@ convertedContactIds:: ' + convertedContactIds);
                }

                // UPDATE ACCOUNT RECORD TYPE
                if(convertedAccountId != null && accountRecordTypeId != null && Schema.sObjectType.Account.fields.RecordTypeId.isUpdateable()){
                    System.debug('@@@ Updating Account Record Type. Account Id: ' + convertedAccountId + ', Record Type Id: ' + accountRecordTypeId);
                    Account updateAccount = new Account(Id = convertedAccountId, RecordTypeId = accountRecordTypeId);
                    update updateAccount;

                    System.debug('@@@ UpdatedAccount:: ' + updateAccount);
                }
                

                // UPDATE OPPORTUNITY RECORD TYPE
                if(createNewOpportunity && convertedOpportunityId != null && opportunityRecordTypeId != null && Schema.sObjectType.Opportunity.fields.RecordTypeId.isUpdateable()){
                    System.debug('@@@ Updating Opportunity Record Type. Opportunity Id: ' + convertedOpportunityId + ', Record Type Id: ' + opportunityRecordTypeId);
                    Opportunity updateOpportunity = new Opportunity(Id = convertedOpportunityId, RecordTypeId = opportunityRecordTypeId);
                    update updateOpportunity;

                    System.debug('@@@ UpdatedOpportunity:: ' + updateOpportunity);
                }           

                if(!convertedContactIds.isEmpty()){
                    List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
                    
                    for(Id contactId: convertedContactIds){
                        if (createNewOpportunity && opportunityIdToUpdate == null) {   
                            OpportunityContactRole ocr = new OpportunityContactRole();   
                            if(Schema.sObjectType.OpportunityContactRole.fields.OpportunityId.isCreateable()){
                                ocr.OpportunityId = convertedOpportunityId;
                            }
                            if(Schema.sObjectType.OpportunityContactRole.fields.ContactId.isCreateable()){
                                ocr.ContactId = contactId;
                            }
                            ocrList.add(ocr); 
                        }
                    }
                    if (!ocrList.isEmpty()){
                        insert ocrList;
                    }
                }
            } else {
                // LEAD CONVERSION - EXISTING ACCOUNT & OPPORTUNITY START
                Id convertedOpportunityId;
                List<Database.LeadConvert> massConvertLeads = new List<Database.LeadConvert>();
                for (String leadConvertId : leadConvertIds) {    
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(leadConvertId);
                    lc.setConvertedStatus(convertedStatusesNames.get(0));
                    lc.setAccountId(accountIdToUpdate);

                    if(createNewOpportunity){
                        if(leadConvertId != primaryLeadId){  
                            lc.setDoNotCreateOpportunity(true);
                        } else {
                            lc.setDoNotCreateOpportunity(false);
                        }
                    } else {
                        lc.setDoNotCreateOpportunity(true);
                    }

                    massConvertLeads.add(lc);
                }

                Set<Id> convertedContactIds = new Set<Id>();
                if(!massConvertLeads.isEmpty()){
                    Database.LeadConvertResult[] lcrList = Database.convertLead(massConvertLeads);
                    System.debug('@@@ lcrList:: ' + lcrList);

                    for(Database.LeadConvertResult lcrFinal : lcrList){
                        if (lcrFinal.isSuccess()) {
                            if (createNewOpportunity && lcrFinal.getLeadId() == primaryLeadId) {
                                convertedOpportunityId = lcrFinal.getOpportunityId();
                            } else if (lcrFinal.getLeadId() != primaryLeadId) {
                                convertedContactIds.add(lcrFinal.getContactId()); 
                            } else if(!createNewOpportunity && opportunityIdToUpdate != null){
                                convertedContactIds.add(lcrFinal.getContactId()); 
                            }
                        }
                    }

                    if(createNewOpportunity && convertedOpportunityId != null && opportunityRecordTypeId != null && Schema.sObjectType.Opportunity.fields.RecordTypeId.isUpdateable()){
                        System.debug('@@@ Updating Opportunity Record Type. Opportunity Id: ' + convertedOpportunityId + ', Record Type Id: ' + opportunityRecordTypeId);
                        Opportunity updateOpportunity = new Opportunity(Id = convertedOpportunityId, RecordTypeId = opportunityRecordTypeId);
                        update updateOpportunity;

                        System.debug('@@@ UpdatedOpportunity:: ' + updateOpportunity);
                    }

                    System.debug('@@@ convertedContactIds:: ' + convertedContactIds);
                    System.debug('@@@ convertedOpportunityId:: ' + convertedOpportunityId);
                }

                if(!convertedContactIds.isEmpty()){
                    List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
                    
                    for(Id contactId: convertedContactIds){
                        OpportunityContactRole ocr = new OpportunityContactRole();   
                        if(Schema.sObjectType.OpportunityContactRole.fields.OpportunityId.isCreateable()){
                            ocr.OpportunityId = createNewOpportunity ? convertedOpportunityId : opportunityIdToUpdate != null ? opportunityIdToUpdate : null;
                        }
                        if(Schema.sObjectType.OpportunityContactRole.fields.ContactId.isCreateable()){
                            ocr.ContactId = contactId;
                        }
                        ocrList.add(ocr);
                    }
                    if (!ocrList.isEmpty()){
                        insert ocrList;
                    }
                }
            }
            
            return 'Leads Successfully Converted';
        } catch(Exception e){
            System.debug('@@@ catch error: ' + e.getMessage());
            Database.rollback(sp);
            return e.getMessage();
        }
    }



    // MassConvertLeads for New Create Account AND/OR New Opportunity
    // @AuraEnabled
    // public static String massConvertLeads(List<String> leadConvertIds, Id leadPrimaryId, String recordTypeId, Boolean createNewOpportunity){
    //     System.debug('leadConvertIds::' + leadConvertIds);
    //     System.debug('leadPrimaryId::' + leadPrimaryId);
    //     System.debug('recordTypeId::' + recordTypeId);
    //     System.debug('createNewOpportunity::' + createNewOpportunity);

    //     Set<Id> leadIdsToNotPrimary = getSetOfLeadNotPrimary(leadConvertIds, leadPrimaryId);
    //     Set<Id> convertedContactIds = new Set<Id>();
        
    //     Savepoint sp = Database.setSavepoint();

    //     //SET PRIMARY LEAD                                                                                                                                                                                                                                                                              
    //     Database.LeadConvert lcPrimaryLead = new database.LeadConvert();
    //     lcPrimaryLead.setLeadId(leadPrimaryId);

    //     //LEAD STATUS
    //     List<String> convertedStatusesNames = new List<String>();
    //     List<LeadStatus> convertedStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true];
    //     for(LeadStatus status : convertedStatuses) {
    //         convertedStatusesNames.add(status.MasterLabel);
    //     }
    //     lcPrimaryLead.setConvertedStatus(convertedStatusesNames.get(0));

    //     if(!createNewOpportunity){
    //         lcPrimaryLead.setDoNotCreateOpportunity(true);
    //     }        

    //     try{
    //         System.debug('@@@ lcPrimaryLead: ' + lcPrimaryLead);
    //         Database.LeadConvertResult lcrPrimaryLead = Database.convertLead(lcPrimaryLead);

    //         if(lcrPrimaryLead.isSuccess()){
                
    //             // CREATE NEW ACCOUNT
    //             Id convertedAccountId = lcrPrimaryLead.getAccountId(); 

    //             //CREATE NEW OPPORTUNITY
    //             Id convertedOpportunityId;
    //             if(createNewOpportunity){
    //                 convertedOpportunityId = lcrPrimaryLead.getOpportunityId();
    //             }

    //             if(!leadIdsToNotPrimary.isEmpty()){
    //                 List<Database.LeadConvert> massConvertLeads = new List<Database.LeadConvert>();
    //                 for(Id leadIdNotPrimary: leadIdsToNotPrimary){
    //                     Database.LeadConvert lcNotPrimary = new database.LeadConvert();
    //                     lcNotPrimary.setLeadId(leadIdNotPrimary);
    //                     lcNotPrimary.setConvertedStatus(convertedStatusesNames.get(0));
    //                     lcNotPrimary.setDoNotCreateOpportunity(true);
    //                     lcNotPrimary.setAccountId(convertedAccountId);
                        
    //                     massConvertLeads.add(lcNotPrimary);
    //                 }

    //                 System.debug('@@@ Converted Leads (massConvertLeads):: ' + massConvertLeads);

    //                 if(!massConvertLeads.isEmpty()){
    //                     Database.LeadConvertResult[] lcrList = Database.convertLead(massConvertLeads, true);
    //                     for(Database.LeadConvertResult lcrFinal : lcrList){
    //                         convertedContactIds.add(lcrFinal.getContactId());
    //                     }
    //                     System.debug('@@@ convertedContactIds:: ' + convertedContactIds);
    //                 }
    //             }
            
    //             // UPDATE ACCOUNT RECORD TYPE
    //             Account updateAccount = [
    //                 SELECT Id, Name, RecordTypeId, RecordType.Name 
    //                 FROM Account
    //                 WHERE Id =: convertedAccountId
    //             ];

    //             if(recordTypeId != null){
    //                 updateAccount.RecordTypeId = recordTypeId;
    //                 update updateAccount;
    //             }

    //             if(!convertedContactIds.isEmpty()){
    //                 if(createNewOpportunity){
    //                     List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
    //                     for(Id contactId: convertedContactIds){
    //                         OpportunityContactRole ocr = new OpportunityContactRole();
    //                         if(Schema.sObjectType.OpportunityContactRole.fields.OpportunityId.isCreateable()){
    //                             ocr.OpportunityId = convertedOpportunityId;
    //                         }
    //                         if(Schema.sObjectType.OpportunityContactRole.fields.ContactId.isCreateable()){
    //                             ocr.ContactId = contactId;
    //                         }
    //                         ocrList.add(ocr);
    //                     }
    //                     insert ocrList;
    //                 }
    //             }
    //         }
    //     } catch(Exception e){
    //         System.debug('@@@ catch error: ' + e.getMessage());
    //         Database.rollback(sp);
    //         return e.getMessage();
    //     }
    //     return 'true';
    // }


    // @AuraEnabled
    // public static String updateMassConvertLeads(List<String> leadsToConvert, String accountIdToUpdate, String opptyIdToUpdate){
    //     System.debug('leadsToConvert::' + leadsToConvert);
    //     System.debug('accountIdToUpdate::' + accountIdToUpdate);
    //     System.debug('opptyIdToUpdate::' + opptyIdToUpdate);

    //     Savepoint sp = Database.setSavepoint();

    //     List<Lead> leadList = [SELECT Id, Name, Company FROM Lead WHERE Id IN :leadsToConvert];
    //     LeadStatus convertedStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];

    //     try{
    //         List<Database.LeadConvert> mergeMassLeadConverts = new List<Database.LeadConvert>();
    //         for (Lead lead : leadList) {
    //             Database.LeadConvert lc = new Database.LeadConvert();
    //             lc.setLeadId(lead.Id);
    //             lc.setAccountId(accountIdToUpdate);
    //             lc.setConvertedStatus(convertedStatus.MasterLabel);
    //             lc.setDoNotCreateOpportunity(true);

    //             mergeMassLeadConverts.add(lc);
    //             System.debug('@updateMassConvertLeads mergeMassLeadConverts:' + mergeMassLeadConverts);
    //         }

        
    //         // CONVERT LEAD TO CONTACTS
    //         Set<Id> convertedContactIds = new Set<Id>();
    //         if(!mergeMassLeadConverts.isEmpty()){
    //             List<Database.LeadConvertResult> convertedLeads = Database.convertLead(mergeMassLeadConverts, true);
    //             for(Database.LeadConvertResult lcr : convertedLeads){
    //                 if (lcr.isSuccess()) {
    //                     convertedContactIds.add(lcr.getContactId());
    //                 }
    //             }
    //         } 
    //         System.debug('@updateMassConvertLeads convertedContactIds:' + convertedContactIds);
    //         // CONVERT CONTACTS TO OPPORTUNITY
    //         List<OpportunityContactRole> oppContactRoleList  = new List<OpportunityContactRole>();
    //         if(!convertedContactIds.isEmpty()){
    //             for(Id contactId : convertedContactIds){
    //                 OpportunityContactRole oppContactRole = new OpportunityContactRole();
    //                 if(opptyIdToUpdate != null){
    //                     if(Schema.sObjectType.OpportunityContactRole.fields.OpportunityId.isCreateable()){
    //                         oppContactRole.OpportunityId = opptyIdToUpdate;
    //                     }
    //                     if(Schema.sObjectType.OpportunityContactRole.fields.ContactId.isCreateable()){
    //                         oppContactRole.ContactId = contactId;
    //                     }
    //                     oppContactRoleList.add(oppContactRole);
    //                 }
    //             }
    //         }

    //         if (!oppContactRoleList.isEmpty()){
    //             insert oppContactRoleList;
    //         } 

    //     } catch(Exception e){
    //         System.debug('@@@ catch error: ' + e.getMessage());
    //         Database.rollback(sp);
    //         return e.getMessage();
    //     }
    //     return 'true';
    // }

    // NOT USED
    // public static Set<Id> getSetValueOfList(List<String> opportunityConvertIds){
    //     Set<Id> opportunityConvertedSet = new Set<Id>();
    //     for(String idOpp: opportunityConvertIds){
    //         opportunityConvertedSet.add(idOpp);
    //     }
        
    //     return opportunityConvertedSet;
    // }

    // public static Set<Id> getSetOfLeadNotPrimary(List<String> leadConvertIds, Id leadPriorityId){
    //     Set<Id> leadIdsToReturn = new Set<Id>();
    //     for(String leadStringId: leadConvertIds){
    //         if(leadStringId != leadPriorityId){
    //             leadIdsToReturn.add(leadStringId);
    //         }
    //     }

    //     return leadIdsToReturn;
    // }

}