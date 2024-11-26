@isTest
public class GetBeauhurstCompaniesTest {
    @isTest
    static void scenarioCollectionDetails(){
        BeauhurstHttpCalloutMock.setTestMockResponse(200, 'Success', '{"meta": {"total": 1,"limit": 20,"offset": 0,"count": 1},"results": [{"id": "u2r9ir","name": "O/M , Growth, West Midlands","count": 199}]}');
        Test.startTest();
        GetBeauhurstCompanies.getCollectionDetail('u2r9ir');
        Test.stopTest();
    }

    @isTest
    static void scenarioSync(){
        GetBeauhurstCompanies.Result params = new GetBeauhurstCompanies.Result();
        params.id       = 'u2r9ir';
        params.name     = 'O/M , Growth, West Midlands';
        params.count    = 1;
        BeauhurstHttpCalloutMock.setTestMockResponse(200, 'Success', '{"meta": {"total": 1,"limit": 20,"offset": 0,"count": 1},"results": [{"id": "jsqccg"}]}');
        Test.startTest();
        GetBeauhurstCompanies.syncRecord(params);
        Test.stopTest();
    }
}