public with sharing class RunBatchCompHouse {
    @InvocableMethod
    public static void execute(List<Request> requests) {
        System.debug('requests requests requests' + requests);
        List<String> ids = new List<String>();
        for(Request request : requests) {
           ids .add(request.recordId);
        }

        System.debug('ids ids ids' + ids);
        if( ids.size() > 0 ){
            Database.executebatch(new BatchCompHouseUpdateAccAndOfficer(ids), 1);
        }
    }

    public class Request{
        @InvocableVariable(label='Record Id' required=true)
        public String recordId;
    }
}