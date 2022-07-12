public with sharing class WarehouseCalloutService implements Queueable{

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    
    public void execute(QueueableContext context) {
        getWareHouseEquips();
    }

    @Future(Callout=true)
    private static void getWareHouseEquips() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200) {
            List<EquipmentWrapper> eqWrapResults = new EquipmentWrapper().parse(response.getBody());
            Map<String,EquipmentWrapper> eqWrapResultsBySKU = new Map<String,EquipmentWrapper>();
            for(EquipmentWrapper eq: eqWrapResults) {
                eqWrapResultsBySKU.put(eq.id, eq);
            }
            updateEquipments(eqWrapResultsBySKU);
        }
    }

    private static void updateEquipments(Map<String,EquipmentWrapper> eqWrapResultsBySKU) {
        if (!eqWrapResultsBySKU.isEmpty()){
            List<Product2> existingEquips = [
                SELECT Id, Warehouse_SKU__c, Cost__c, Current_Inventory__c, Lifespan_Months__c, Maintenance_Cycle__c
                FROM Product2
                WHERE Warehouse_SKU__c IN :eqWrapResultsBySKU.keySet()
            ];
            List<Product2> equipsToUpsert = new List<Product2>();
            if (!existingEquips.isEmpty()){
                for(Product2 eq : existingEquips){
                    eq.Replacement_Part__c = true;
                    eq.Cost__c = eqWrapResultsBySKU.get(eq.Warehouse_SKU__c).cost;
                    eq.Current_Inventory__c = eqWrapResultsBySKU.get(eq.Warehouse_SKU__c).quantity;
                    eq.Lifespan_Months__c = eqWrapResultsBySKU.get(eq.Warehouse_SKU__c).lifespan;
                    eq.Maintenance_Cycle__c = eqWrapResultsBySKU.get(eq.Warehouse_SKU__c).maintenanceperiod;
                    eq.StockKeepingUnit = eqWrapResultsBySKU.get(eq.Warehouse_SKU__c).sku;
                    equipsToUpsert.add(eq);                          
                    eqWrapResultsBySKU.remove(eq.Warehouse_SKU__c);                
                }
            }
            for (EquipmentWrapper eq: eqWrapResultsBySKU.values()){
                equipsToUpsert.add(
                    new Product2(
                        Name = eq.name,
                        Replacement_Part__c = true,
                        Cost__c = eq.cost,
                        Current_Inventory__c = eq.quantity,
                        Lifespan_Months__c = eq.lifespan,
                        Maintenance_Cycle__c = eq.maintenanceperiod,
                        Warehouse_SKU__c = eq.id,
                        StockKeepingUnit = eq.sku
                    )
                );
            }
            upsert equipsToUpsert;
        }        
    }

    private class EquipmentWrapper {
        public Integer maintenanceperiod{get;set;}
		public String name{get;set;}
		public Integer lifespan{get;set;}
		public Integer quantity{get;set;}
		public Integer cost{get;set;}
		public Boolean replacement{get;set;}
		public String sku{get;set;}
		public String id{get;set;}

        public List<EquipmentWrapper> parse(String json){
            return (List<EquipmentWrapper>) System.JSON.deserialize(
                json.replaceAll('\"_id\"', '\"id\"'), 
                List<EquipmentWrapper>.class
            );
        }
    }
}