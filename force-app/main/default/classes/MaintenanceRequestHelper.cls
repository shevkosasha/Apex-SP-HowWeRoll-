public with sharing class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(Map<Id,Case> triggerNewCases) {
        // TODO: Complete the method to update workorders
        Map<Id,Case> closedCases = new Map<Id,Case>();
        List<Case> newCases = new List<Case>();
        for (Case c : triggerNewCases.values()) {            
            if (c.IsClosed) {
                closedCases.put(c.Id, c);
            } 
        }
        if (!closedCases.isEmpty()) {            
            Map<Id, List<Equipment_Maintenance_Item__c>> eqItemsMapByCases = new Map<Id,List<Equipment_Maintenance_Item__c>>();            
            List<Equipment_Maintenance_Item__c> eqItems = new List<Equipment_Maintenance_Item__c>([
                SELECT Id, Name, Quantity__c, Equipment__c, Maintenance_Request__c, Equipment__r.Maintenance_Cycle__c 
                FROM Equipment_Maintenance_Item__c 
                WHERE Maintenance_Request__c IN : closedCases.keySet()
            ]); 
            if (!eqItems.isEmpty()) {                
                for (Equipment_Maintenance_Item__c item : eqItems) {
                    if (eqItemsMapByCases.get(item.Maintenance_Request__c) != null) {
                        eqItemsMapByCases.get(item.Maintenance_Request__c).add(item);
                        
                    } else {
                        List<Equipment_Maintenance_Item__c> newLst = new List<Equipment_Maintenance_Item__c>();
                        newLst.add(item);
                        eqItemsMapByCases.put(item.Maintenance_Request__c, newLst);
                    }                    
                }
                Map<Id, Integer> casesByEarlyDays = suchEarlyDay(closedCases, eqItems);
                Map<Id, Case> casesByOriginID = new Map<Id, Case>();
                Map<Id, List<Equipment_Maintenance_Item__c>> eqItemsByCaseOriginID = new Map<Id, List<Equipment_Maintenance_Item__c>>();
                for (Case c : closedCases.values()) {                    
                    for (Equipment_Maintenance_Item__c item : eqItems) {
                        if (casesByOriginID.get(c.Id) == null) {
                            Case newCase = new Case(
                                Type = 'Routine Maintenance',
                                AccountId = c.AccountId,
                                Subject = 'Maintenance request',
                                Origin = c.Origin,
                                Status = 'New',
                                Vehicle__c = c.Vehicle__c,
                                Date_Reported__c = Date.today(),
                                Date_Due__c = Date.today().addDays(casesByEarlyDays.get(c.Id)),// + casesByEarlyDays.get(c.Id),
                                Original_ID__c = c.Id,
                                Equipment_ID__c = item.Equipment__c
                            );
                            casesByOriginID.put(c.Id, newCase);
                            newCases.add(newCase);
                        }
                    }                                    
                }
                insert newCases;

                List<Equipment_Maintenance_Item__c> eqItemsNew = new List<Equipment_Maintenance_Item__c>();
                for(List<Equipment_Maintenance_Item__c> eqItemLst : eqItemsMapByCases.values()) {
                    for (Equipment_Maintenance_Item__c eqItem : eqItemLst) {
                        Equipment_Maintenance_Item__c newItem = eqItem.clone(false, true, false, false);
                        newItem.Maintenance_Request__c = casesByOriginID.get(eqItem.Maintenance_Request__c).id;
                        eqItemsNew.add(newItem);
                    } 
                }                
                insert eqItemsNew;     
            }
        }
    }        

    private static Map<Id, Integer> suchEarlyDay(Map<Id, Case> caseMap, List<Equipment_Maintenance_Item__c> eqItems) {
        Map<Id, Integer> lessDate = new Map<Id, Integer>();    
        for (Id caseId : caseMap.keySet()) {
            for (Equipment_Maintenance_Item__c item : eqItems) {
                if (!lessDate.containsKey(caseId) && caseId == item.Maintenance_Request__c) {
                    lessDate.put(caseId, (Integer) item.Equipment__r.Maintenance_Cycle__c);
                } else if (lessDate.containsKey(caseId) && lessDate.get(caseId) > (Integer) item.Equipment__r.Maintenance_Cycle__c) {
                    lessDate.put(caseId, (Integer) item.Equipment__r.Maintenance_Cycle__c);
                }
            }
        }
        return lessDate;
    } 
    
}