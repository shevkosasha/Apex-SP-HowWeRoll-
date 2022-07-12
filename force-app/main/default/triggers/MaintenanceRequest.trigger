trigger MaintenanceRequest on Case (before update, after update) {
    // ToDo: Call MaintenanceRequestHelper.updateWorkOrders
    // List<Case> caseIds = new List<Case>();
    // if (Trigger.isAfter) {
    //     for (MaintenanceRequest mr : )
    // }
    if (Trigger.isAfter) {
        MaintenanceRequestHelper.updateWorkOrders(Trigger.newMap);
    }    
}