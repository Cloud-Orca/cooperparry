public class SmartSearchAPIUtility {
    
    public static HttpResponse getAccessToken(){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/auth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', 'application/vnd.api+json');

        String body = '{"data":{"type":"app-token","attributes":{"app_id":"' + smartSearchSetting.app_id__c + '","secret":"' + smartSearchSetting.secret__c + '"}}}';
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse postSearchSubject(String accessToken, String firstName, String middleName, String lastName){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/watchlist/searches');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        middleName = (middleName != null) ? middleName : '';
        String body = '{"data":{"type":"watchlist-only-individual","attributes":{"name":{"first":"' + firstName + '","middle":"' + middleName + '","last":"' + lastName + '"}}}}';
        // {"data":{"type":"watchlist-only-individual","attributes":{"name":{"first":"test","middle":"jo","last":"last"},"date_of_birth":"1994-12-27"}}}
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse postSearchUKIndividual(String accessToken, Beneficial_Owner__c benOwnerToSearch){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/ukindividual/searches');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        RequestWrapp reqWrapp = new RequestWrapp();
        reqWrapp.data = new DataDetails();
        reqWrapp.data.type = 'uk-individual';

        AttributeDetails attributeDetail = new AttributeDetails();
        attributeDetail.name = new NameDetails();
        attributeDetail.name.title = benOwnerToSearch.Title__c;
        attributeDetail.name.first = benOwnerToSearch.First_Name__c;
        attributeDetail.name.middle = (benOwnerToSearch.Middle_Name__c != null) ? benOwnerToSearch.Middle_Name__c : '';
        attributeDetail.name.last = benOwnerToSearch.Last_Name__c;

        attributeDetail.date_of_birth = String.valueOf(benOwnerToSearch.Date_of_Birth__c);
        attributeDetail.client_reference = benOwnerToSearch.Search_Reference__c;

        AddressDetails addDetail = new AddressDetails();
        addDetail.flat = benOwnerToSearch.Flat__c;
        addDetail.building = benOwnerToSearch.Building_Name_Number__c;
        addDetail.street_1 = benOwnerToSearch.Address_Line_1__c;
        addDetail.street_2 = benOwnerToSearch.Address_Line_2__c;
        addDetail.town = benOwnerToSearch.Town__c;
        addDetail.region = benOwnerToSearch.County__c;
        addDetail.postcode = benOwnerToSearch.Postcode__c;

        Decimal numOfDuration = 0;
        numOfDuration = (benOwnerToSearch.Years_at_this_address__c != null) ? benOwnerToSearch.Years_at_this_address__c * 12 : 0;
        numOfDuration += (benOwnerToSearch.Months_at_this_address__c != null) ? benOwnerToSearch.Months_at_this_address__c: 0;
        addDetail.duration = numOfDuration;
        List<AddressDetails> addresses = new List<AddressDetails>{addDetail};
        attributeDetail.addresses = addresses;

        reqWrapp.data.attributes = attributeDetail;

        DataDetails2 detail2 = new DataDetails2();
        detail2.type = 'search-config';
        detail2.id = smartSearchSetting.high_risk_id__c;

        RelationshipDetails relationships = new RelationshipDetails();
        relationships.config = new ConfigDetails();
        relationships.config.data = detail2;

        reqWrapp.data.relationships = relationships;
        req.setBody(JSON.serialize(reqWrapp));

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse getUKSummary(String accessToken, String searchId){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/ukindividual/searches/' + searchId);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse getWatchList(String accessToken, String searchSubjectId){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/watchlist/subjects/' + searchSubjectId);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public static HttpResponse getDocument(String accessToken, String searchSubjectId){
        Smart_Search_Setting__c smartSearchSetting = Smart_Search_Setting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(smartSearchSetting.base_url__c + '/v3/exports/pdf/subject/' + searchSubjectId + '/base64');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', 'application/vnd.api+json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('@@@ resp status and code: '+ res.getStatus()+' ' + res.getStatusCode());
        System.debug('@@@ resp body: ' + res.getBody());
        return res;
    }

    public class RequestWrapp{
        public DataDetails data;
    }

    public class DataDetails{
        public String type;
        public AttributeDetails attributes;
        public RelationshipDetails relationships;
    }

    public class AttributeDetails{
        public NameDetails name;
        public String date_of_birth;
        public String client_reference;
        public List<AddressDetails> addresses;
    }
    
    public class NameDetails{
        public String title;
        public String first;
        public String middle;
        public String last;
    }

    public class AddressDetails{
        public String flat;
        public String building;
        public String street_1;
        public String street_2;
        public String town;
        public String region;
        public String postcode;
        public Decimal duration;
    }

    public class RelationshipDetails{
        public ConfigDetails config;
    }

    public class ConfigDetails{
        public DataDetails2 data;
    }

    public class DataDetails2{
        public String type;
        public String id;
    }
}