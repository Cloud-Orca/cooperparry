public class BeauhurstAPIUtility {
    public static HttpRequest constructReq(String append){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BeauhurstAPI' + append);
        req.setMethod('GET');
        req.setTimeOut(120000);
        return req;
    }
}