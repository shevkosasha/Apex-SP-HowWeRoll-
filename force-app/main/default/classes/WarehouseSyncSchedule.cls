public with sharing class WarehouseSyncSchedule implements Schedulable {
    // implement scheduled code here
    public void execute(SchedulableContext ctx) {
        ID WarehouseSyncScheduleJob = System.enqueueJob(new WarehouseCalloutService());
    }
}