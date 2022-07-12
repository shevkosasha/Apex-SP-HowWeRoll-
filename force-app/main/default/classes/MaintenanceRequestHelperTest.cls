@IsTest
public class MaintenanceRequestHelperTest {
    // implement scheduled code here
    @TestSetup
    static void init(){
        CreateDefaultData.createDefaultData();
    }

    @IsTest
    static void updateCase() {
        Integer requestsBefore = [SELECT Id, Status, IsClosed FROM Case].size();
        Integer eqItemsBefore = [SELECT Id FROM Equipment_Maintenance_Item__c].size();
        List<Case> requests = [SELECT Id FROM Case];
        requests[0].Status = 'Closed';
        update requests;
        Integer requestsAfter = [SELECT Id, Status, IsClosed FROM Case].size();
        Integer eqItemsAfter = [SELECT Id FROM Equipment_Maintenance_Item__c].size();
        System.assert(requestsAfter > requestsBefore);
        System.assert(eqItemsAfter > eqItemsBefore);
    }
}