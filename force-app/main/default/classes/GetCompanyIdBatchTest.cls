@isTest
private class GetCompanyIdBatchTest {
    @IsTest
    static void createAccountFromBHBatch(){
        Company_Collection__c col = new Company_Collection__c();
        col.beauhurst_id__c = 'kafjwd';
        col.collection_name__c = 'Sample Collection';
        col.count__c = 34;
        col.sync__c = true;
        insert col;

        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse collection1 = new HttpResponse();
        collection1.setStatusCode(200);
        collection1.setBody('{"meta":{"total":162,"limit":100,"offset":100,"count":62},"results":[{"id":"5myiqz","name":"Rebecca list - TK","count":33333},{"id":"kafjwd","name":"Tech Nation Upscale 8","count":34},{"id":"wptzyf","name":"FinTech 5.0","count":43},{"id":"wgbd9b","name":"Tech Nation Applied AI 4.0","count":32},{"id":"m4bnbc","name":"East Midlands Companies 10-200m turnover","count":19},{"id":"5aujy3","name":"Private Equity backed Tech Scale-ups","count":93},{"id":"ecs3iy","name":"Acquisition","count":149},{"id":"wtthfn","name":"eSports/GB Gaming Space","count":55},{"id":"p88u7v","name":"THG Nurture","count":295},{"id":"siehr5","name":"THG Early Stage","count":185},{"id":"mstg2s","name":"Early Stage targets","count":100},{"id":"utn9w2","name":"TK - list for Mel 51% shareholding","count":1425},{"id":"gb76jh","name":"Transition Acclivity Clients","count":15},{"id":"jqhh9c","name":"Transition IHorizon Clients","count":63},{"id":"c4a8wf","name":"THG ES Client List","count":78},{"id":"8sjbyn","name":"Deeptech Founders dinner 1","count":21},{"id":"qui4gn","name":"Ultimate parent £1m to £10m","count":7682},{"id":"zptfrr","name":"Tech CFO23","count":159},{"id":"ndaswr","name":"Venture CEO List","count":321},{"id":"r2dwtz","name":"New FDs","count":1073},{"id":"wk3kn4","name":"Venture North","count":28},{"id":"rjkyk4","name":"eagle Labs / Plexal ScaleUp cohort","count":20},{"id":"6b9sm4","name":"THG CFO Dinners - Targets","count":147},{"id":"2yvcuk","name":"THG Clients Nov 23","count":324},{"id":"mx493i","name":"Capsule F1nTech event","count":57},{"id":"25jumg","name":"THG Clients Jan 24","count":372},{"id":"wjwgym","name":"CFO drinks attendees","count":70},{"id":"aczx54","name":"Companies for Cliff","count":33},{"id":"utkfep","name":"Capsule Scale Up 50 2024","count":50},{"id":"cwjg5r","name":"THG Clients 04-03-24","count":393},{"id":"ay6tmw","name":"THG Clients 18-03-24","count":409},{"id":"iq9ukp","name":"Capsule Clients","count":467},{"id":"2dr7d7","name":"THG Clients 19-04-24","count":428},{"id":"vbf798","name":"Capsule 50 attendees","count":122},{"id":"y862ys","name":"Tech CFO 24","count":74},{"id":"343x9r","name":"THG Event import company names 17-05-24","count":522},{"id":"sqeqgf","name":"THG Client 28-05-24","count":584},{"id":"b9ktgi","name":"ES Clients - June 2024","count":292},{"id":"gha3wz","name":"Early Stage - 18.06.24","count":464},{"id":"jik633","name":"TechCFO24 Attendees from CRM","count":189},{"id":"rp5ftf","name":"CFO Forum","count":197},{"id":"prtatj","name":"THG Nurture_Olivia Hilliard","count":54},{"id":"9kerqm","name":"Scottish Scale-ups","count":3},{"id":"tgnk8b","name":"THG Clients 07-08-24","count":448},{"id":"v74z5w","name":"CFO Forum Wave 2","count":319},{"id":"dnaer5","name":"CFO Forum Wave 3 contacts","count":223},{"id":"jbdnyx","name":"FF Wave 3","count":143},{"id":"vfjijd","name":"CFO Forum 10Sept Attendees","count":84},{"id":"rxd2vu","name":"Upscale 2024","count":26},{"id":"2dxnhn","name":"Future Fifty 2.0 2024","count":25},{"id":"djbmhe","name":"Super Startups 2025 Tempo list","count":100},{"id":"eipxwv","name":"Strategic Finance webinar 17.10.24","count":32},{"id":"xs53uu","name":"Plexal ScaleUp Cohort 2024","count":22},{"id":"gdxqwg","name":"Future of Media 21/10/24","count":50},{"id":"dnbxtq","name":"Companies backed by VC Funds","count":4189},{"id":"qd5v5a","name":"Consumer THG Businesses","count":406},{"id":"drgnht","name":"ES Clients - November 2024","count":201},{"id":"xxqpqh","name":"THG Consumer products","count":340},{"id":"d4n2d9","name":"Passion Capital Portfolio","count":90},{"id":"wzw756","name":"Audited by 1-8 in Rankings","count":45464},{"id":"k3kmhg","name":"Audited by 9-30","count":40573},{"id":"6rj8t8","name":"F1NTech 2024","count":120}]}');
        mock.addResponse(collection1);

        HttpResponse collection2 = new HttpResponse();
        collection2.setStatusCode(200);
        collection2.setBody('{"meta":{"total":162,"limit":100,"offset":100,"count":62},"results":[]}');
        mock.addResponse(collection2);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Database.executeBatch(new GetCompanyIdBatch(), 1);
        Test.stopTest();
    }

    @IsTest
    static void createAccountFromBHBatchIDParam(){
        Company_Collection__c col = new Company_Collection__c();
        col.beauhurst_id__c = 'kafjwd';
        col.collection_name__c = 'Sample Collection';
        col.count__c = 34;
        col.sync__c = true;
        insert col;

        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse collection1 = new HttpResponse();
        collection1.setStatusCode(200);
        collection1.setBody('{"meta":{"total":162,"limit":100,"offset":100,"count":62},"results":[{"id":"5myiqz","name":"Rebecca list - TK","count":33333},{"id":"kafjwd","name":"Tech Nation Upscale 8","count":34},{"id":"wptzyf","name":"FinTech 5.0","count":43},{"id":"wgbd9b","name":"Tech Nation Applied AI 4.0","count":32},{"id":"m4bnbc","name":"East Midlands Companies 10-200m turnover","count":19},{"id":"5aujy3","name":"Private Equity backed Tech Scale-ups","count":93},{"id":"ecs3iy","name":"Acquisition","count":149},{"id":"wtthfn","name":"eSports/GB Gaming Space","count":55},{"id":"p88u7v","name":"THG Nurture","count":295},{"id":"siehr5","name":"THG Early Stage","count":185},{"id":"mstg2s","name":"Early Stage targets","count":100},{"id":"utn9w2","name":"TK - list for Mel 51% shareholding","count":1425},{"id":"gb76jh","name":"Transition Acclivity Clients","count":15},{"id":"jqhh9c","name":"Transition IHorizon Clients","count":63},{"id":"c4a8wf","name":"THG ES Client List","count":78},{"id":"8sjbyn","name":"Deeptech Founders dinner 1","count":21},{"id":"qui4gn","name":"Ultimate parent £1m to £10m","count":7682},{"id":"zptfrr","name":"Tech CFO23","count":159},{"id":"ndaswr","name":"Venture CEO List","count":321},{"id":"r2dwtz","name":"New FDs","count":1073},{"id":"wk3kn4","name":"Venture North","count":28},{"id":"rjkyk4","name":"eagle Labs / Plexal ScaleUp cohort","count":20},{"id":"6b9sm4","name":"THG CFO Dinners - Targets","count":147},{"id":"2yvcuk","name":"THG Clients Nov 23","count":324},{"id":"mx493i","name":"Capsule F1nTech event","count":57},{"id":"25jumg","name":"THG Clients Jan 24","count":372},{"id":"wjwgym","name":"CFO drinks attendees","count":70},{"id":"aczx54","name":"Companies for Cliff","count":33},{"id":"utkfep","name":"Capsule Scale Up 50 2024","count":50},{"id":"cwjg5r","name":"THG Clients 04-03-24","count":393},{"id":"ay6tmw","name":"THG Clients 18-03-24","count":409},{"id":"iq9ukp","name":"Capsule Clients","count":467},{"id":"2dr7d7","name":"THG Clients 19-04-24","count":428},{"id":"vbf798","name":"Capsule 50 attendees","count":122},{"id":"y862ys","name":"Tech CFO 24","count":74},{"id":"343x9r","name":"THG Event import company names 17-05-24","count":522},{"id":"sqeqgf","name":"THG Client 28-05-24","count":584},{"id":"b9ktgi","name":"ES Clients - June 2024","count":292},{"id":"gha3wz","name":"Early Stage - 18.06.24","count":464},{"id":"jik633","name":"TechCFO24 Attendees from CRM","count":189},{"id":"rp5ftf","name":"CFO Forum","count":197},{"id":"prtatj","name":"THG Nurture_Olivia Hilliard","count":54},{"id":"9kerqm","name":"Scottish Scale-ups","count":3},{"id":"tgnk8b","name":"THG Clients 07-08-24","count":448},{"id":"v74z5w","name":"CFO Forum Wave 2","count":319},{"id":"dnaer5","name":"CFO Forum Wave 3 contacts","count":223},{"id":"jbdnyx","name":"FF Wave 3","count":143},{"id":"vfjijd","name":"CFO Forum 10Sept Attendees","count":84},{"id":"rxd2vu","name":"Upscale 2024","count":26},{"id":"2dxnhn","name":"Future Fifty 2.0 2024","count":25},{"id":"djbmhe","name":"Super Startups 2025 Tempo list","count":100},{"id":"eipxwv","name":"Strategic Finance webinar 17.10.24","count":32},{"id":"xs53uu","name":"Plexal ScaleUp Cohort 2024","count":22},{"id":"gdxqwg","name":"Future of Media 21/10/24","count":50},{"id":"dnbxtq","name":"Companies backed by VC Funds","count":4189},{"id":"qd5v5a","name":"Consumer THG Businesses","count":406},{"id":"drgnht","name":"ES Clients - November 2024","count":201},{"id":"xxqpqh","name":"THG Consumer products","count":340},{"id":"d4n2d9","name":"Passion Capital Portfolio","count":90},{"id":"wzw756","name":"Audited by 1-8 in Rankings","count":45464},{"id":"k3kmhg","name":"Audited by 9-30","count":40573},{"id":"6rj8t8","name":"F1NTech 2024","count":120}]}');
        mock.addResponse(collection1);

        HttpResponse collection2 = new HttpResponse();
        collection2.setStatusCode(200);
        collection2.setBody('{"meta":{"total":162,"limit":100,"offset":100,"count":62},"results":[]}');
        mock.addResponse(collection2);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Set<Id> collectionIds = new Set<Id>{col.Id};
            Database.executeBatch(new GetCompanyIdBatch(collectionIds), 1);
        Test.stopTest();
    }
}