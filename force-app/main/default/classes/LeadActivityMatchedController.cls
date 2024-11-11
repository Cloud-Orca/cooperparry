public with sharing class LeadActivityMatchedController {

    @AuraEnabled(cacheable=true)
    public static List<ActivityWrapper> getDataToDisplayActivity(Id leadId){
        System.debug('@@@ getDataToDisplayActivity');

        List<ActivityWrapper> activityWrapperList = new List<ActivityWrapper>();

        Set<Id> matchedLeadIds = LeadMatchingRuleUtility.getAllLeadMatching(leadId);
        System.debug('@@@ matchedLeadIds: ' + matchedLeadIds);
        matchedLeadIds.add(leadId);

        Map<String, List<ActivityDetails>> mapHeaderNameToListOfAct = new Map<String, List<ActivityDetails>>();
        
        if(!matchedLeadIds.isEmpty()){

            List<Task> taskRecords = [SELECT Id, Subject, OwnerId, Owner.Name, WhoId, Who.Name, ActivityDate FROM Task WHERE WhoId IN: matchedLeadIds];
            
            for(Task taskRecord: taskRecords){
                Date activityDate = taskRecord.ActivityDate;
                if(activityDate != null){
                    Datetime dateTimeActivityDate = DateTime.newInstance(activityDate.year(), activityDate.month(),activityDate.day());

                    String headerValue = getHeaderValueBasedOnDate(dateTimeActivityDate);

                    ActivityDetails actDet = new ActivityDetails();
                    if(taskRecord.Subject != null && taskRecord.Subject.contains('Email')){
                        actDet.icon = 'standard:email';
                        actDet.middleText = 'sent an email to';
                    }
                    else if(taskRecord.Subject != null && taskRecord.Subject.contains('Call')){
                        actDet.icon = 'standard:log_a_call';
                        actDet.middleText = 'logged a call with';
                    }
                    else{
                        actDet.icon = 'standard:task';
                        actDet.middleText = 'had a task for';
                    }
                    
                    actDet.leadName = taskRecord.Who.Name;
                    actDet.leadId = taskRecord.WhoId;
                    String dayString = String.valueOf(activityDate.day());
                    dayString = (dayString.length() == 1) ? '0'+dayString : dayString;
                    actDet.dateDisplay = dayString + '-' + headerValue.substring(0,3);
                    actDet.userName = taskRecord.Owner.Name;
                    actDet.userId = taskRecord.OwnerId;
                    actDet.dateValue = dateTimeActivityDate;

                    if(mapHeaderNameToListOfAct.containsKey(headerValue)){
                        mapHeaderNameToListOfAct.get(headerValue).add(actDet);
                    }
                    else{
                        mapHeaderNameToListOfAct.put(headerValue, new List<ActivityDetails> {actDet});
                    }
                }
            }
            
            List<Event> eventRecords = [SELECT Id, Subject, OwnerId, Owner.Name, WhoId, Who.Name, EndDateTime FROM Event WHERE WhoId IN: matchedLeadIds];

            for(Event eventRecord: eventRecords){
                if(eventRecord.EndDateTime != null){
                    String headerValue = getHeaderValueBasedOnDate(eventRecord.EndDateTime);
                    
                    ActivityDetails actDet = new ActivityDetails();
                    if(eventRecord.Subject != null && eventRecord.Subject.contains('Email')){
                        actDet.icon = 'standard:email';
                        actDet.middleText = 'sent an email to';
                    }
                    else if(eventRecord.Subject != null && eventRecord.Subject.contains('Call')){
                        actDet.icon = 'standard:log_a_call';
                        actDet.middleText = 'logged a call with';
                    }
                    else{
                        actDet.icon = 'standard:event';
                        actDet.middleText = 'had an event with';
                    }
                    
                    actDet.leadName = eventRecord.Who.Name;
                    actDet.leadId = eventRecord.WhoId;
                    String dayString = String.valueOf(eventRecord.EndDateTime.day());
                    dayString = (dayString.length() == 1) ? '0'+dayString : dayString;
                    actDet.dateDisplay = dayString + '-' + headerValue.substring(0,3);
                    actDet.userName = eventRecord.Owner.Name;
                    actDet.userId = eventRecord.OwnerId;
                    actDet.dateValue = eventRecord.EndDateTime;

                    if(mapHeaderNameToListOfAct.containsKey(headerValue)){
                        mapHeaderNameToListOfAct.get(headerValue).add(actDet);
                    }
                    else{
                        mapHeaderNameToListOfAct.put(headerValue, new List<ActivityDetails> {actDet});
                    }
                }
            }
            
        }

        for(String stringHeaderName: mapHeaderNameToListOfAct.keySet()){
            ActivityWrapper activityWrap = new ActivityWrapper();
            activityWrap.headerValue = stringHeaderName;
            activityWrap.actDetails = new List<ActivityDetails>();
            activityWrap.actDetails = mapHeaderNameToListOfAct.get(stringHeaderName);

            activityWrapperList.add(activityWrap);
        }

        return sortWrapper(activityWrapperList);
    }

    public static List<ActivityWrapper> sortWrapper(List<ActivityWrapper> activityWrapperList){
        List<ActivityWrapper> activityWrapperListFinal = new List<ActivityWrapper>();
        Map<DateTime, String> mapDateToHeader = new Map<DateTime, String>();
        Map<String, ActivityWrapper> mapHeaderValToWrap = new Map<String, ActivityWrapper>();
        Map<Integer, String> mapOrderToHeader = new Map<Integer, String>();

        for(ActivityWrapper wrapp: activityWrapperList){
            mapDateToHeader.put(wrapp.actDetails.get(0).dateValue, wrapp.headerValue);
            mapHeaderValToWrap.put(wrapp.headerValue, wrapp);
        }    

        Set<DateTime> dateTimeListSortedSet = mapDateToHeader.keySet();
        List<DateTime> dateTimeListSortedList = new List<DateTime>();
        for(DateTime dateTimeVal: dateTimeListSortedSet){
            dateTimeListSortedList.add(dateTimeVal);
        }

        dateTimeListSortedList.sort();
        Integer activitySize = activityWrapperList.size() - 1;

        System.debug('@@@ dateTimeListSortedList: ' + dateTimeListSortedList);
        for(DateTime dateTimeVal: dateTimeListSortedList){
            System.debug('@@@ dateTimeVal: ' + dateTimeVal);
            mapOrderToHeader.put(activitySize, mapDateToHeader.get(dateTimeVal));
            activitySize -= 1;
        }

        System.debug('@@@ mapOrderToHeader: ' + mapOrderToHeader);
        for(Integer i=0; i<activityWrapperList.size(); i++){
            System.debug('@@@ i: ' + i);
            String headerValueString = mapOrderToHeader.get(i);
            System.debug('@@@ headerValueString: ' + headerValueString);
            activityWrapperListFinal.add(mapHeaderValToWrap.get(headerValueString));
        }
        /*

        List<ActivityWrapper> activityWrapperListFinal = new List<ActivityWrapper>();
        Map<Integer, String> mapOrderToHeader = new Map<Integer, String>();
        Map<String, ActivityWrapper> mapHeaderValToWrap = new Map<String, ActivityWrapper>();
        Integer activitySize = activityWrapperList.size() - 1;

        for(ActivityWrapper wrapp: activityWrapperList){
            mapOrderToHeader.put(activitySize, wrapp.headerValue);
            activitySize -= 1;
            mapHeaderValToWrap.put(wrapp.headerValue, wrapp);
        }
        System.debug('@@@ mapOrderToHeader: ' + mapOrderToHeader);

        for(Integer i=0; i<activityWrapperList.size(); i++){
            System.debug('@@@ i: ' + i);
            String headerValueString = mapOrderToHeader.get(i);
            System.debug('@@@ headerValueString: ' + headerValueString);
            activityWrapperListFinal.add(mapHeaderValToWrap.get(headerValueString));
        }

        */


        /*
        for(Integer headerVal: mapOrderToHeader.keySet()){
            System.debug('@@@ headerVal: ' + headerVal);
            String headerValueString = mapOrderToHeader.get(headerVal);
            System.debug('@@@ headerValueString: ' + headerValueString);
            activityWrapperListFinal.add(mapHeaderValToWrap.get(headerValueString));
        }
        */

        /*
        Map<String, ActivityWrapper> mapHeaderValToWrap = new Map<String, ActivityWrapper>();
        for(ActivityWrapper wrapp: activityWrapperList){
            mapHeaderValToWrap.put(wrapp.headerValue, wrapp);
        }

        List<ActivityWrapper> activityWrapperListFinal = new List<ActivityWrapper>();
        Map<Integer, String> mapOrderToHeader = new Map<Integer, String>();

        
        for(Integer i=0; i<activityWrapperList.size(); i++){
            for(Integer j=i + 1; j<=activityWrapperList.size()-1; j++){
                
                ActivityWrapper wrappTempFirst = activityWrapperList.get(i);
                DateTime dateFirst = wrappTempFirst.actDetails.get(0).dateValue;

                ActivityWrapper wrappTempSecond= activityWrapperList.get(j);
                DateTime dateSecond = wrappTempSecond.actDetails.get(0).dateValue;

                System.debug('@@@ dateFirst: ' + dateFirst);
                System.debug('@@@ dateSecond: ' + dateSecond);

                System.debug('@@@ i: ' + i);
                System.debug('@@@ j: ' + j);
                
                if(dateFirst < dateSecond){
                    mapOrderToHeader.put(i, wrappTempSecond.headerValue);
                    mapOrderToHeader.put(j, wrappTempFirst.headerValue);
                }
                else{
                    mapOrderToHeader.put(i, wrappTempFirst.headerValue);
                    mapOrderToHeader.put(j, wrappTempSecond.headerValue);
                }
                System.debug('@@@ mapOrderToHeader: ' + mapOrderToHeader);
            }
        }
        System.debug('@@@ mapOrderToHeader Final: ' + mapOrderToHeader);

        for(Integer headerVal: mapOrderToHeader.keySet()){
            String headerValueString = mapOrderToHeader.get(headerVal);
            activityWrapperListFinal.add(mapHeaderValToWrap.get(headerValueString));
        }
        */
        return activityWrapperListFinal;
    }

    public static String getHeaderValueBasedOnDate(DateTime dateValue){
        String headerNameToReturn = '';
        String monthName = getMonthName(dateValue.month());
        String yearValue = String.valueOf(dateValue.year());
        headerNameToReturn = monthName + ' ' + yearValue;
        return headerNameToReturn;
    }

    public static String getMonthName(Integer monthValue){
        String monthNameToReturn = '';
        if(monthValue == 1){
            return 'January';
        }
        else if(monthValue == 2){
            return 'February';
        }
        else if(monthValue == 3){
            return 'March';
        }
        else if(monthValue == 4){
            return 'April';
        }
        else if(monthValue == 5){
            return 'May';
        }
        else if(monthValue == 6){
            return 'June';
        }
        else if(monthValue == 7){
            return 'July';
        }
        else if(monthValue == 8){
            return 'August';
        }
        else if(monthValue == 9){
            return 'September';
        }
        else if(monthValue == 10){
            return 'October';
        }
        else if(monthValue == 11){
            return 'November';
        }
        else if(monthValue == 12){
            return 'December';
        }
        return monthNameToReturn;
    }

    public class ActivityWrapper{
        @AuraEnabled public String headerValue; 
        @AuraEnabled public List<ActivityDetails> actDetails;
    }

    public class ActivityDetails{
        @AuraEnabled public String type;
        @AuraEnabled public String icon;
        @AuraEnabled public String middleText;
        @AuraEnabled public String leadName;
        @AuraEnabled public Id leadId;
        @AuraEnabled public String dateDisplay;
        @AuraEnabled public String userName;
        @AuraEnabled public String userId;
        @AuraEnabled public DateTime dateValue;
    }
}