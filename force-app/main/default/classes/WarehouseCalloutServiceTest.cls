@IsTest
public class WarehouseCalloutServiceTest {
  // implement your mock callout test here
    @TestSetup
    static void init(){
        CreateDefaultData.createDefaultData();
    }

	@IsTest
    static void WarehouseEquipmentSyncQueue(){
        Integer before = [SELECT COUNT() FROM Product2];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock()); 
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();   
        System.assertEquals(before + 1, [SELECT COUNT() FROM Product2]);        
    }    
}