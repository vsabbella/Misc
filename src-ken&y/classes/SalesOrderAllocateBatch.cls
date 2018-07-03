public without sharing class SalesOrderAllocateBatch implements Database.Batchable<Sales_Order__c>, Database.Stateful, Process.Runnable2 {
    private Date endDate = System.today();
    private Id companyId;
    private Id facilityId;
    private Id salesOrderId;
    private List<Notify.Message> errors = new List<Notify.Message>();

    public void runBatch(Process_Job__c job) {
        if (job.Days_Ahead__c != null) endDate = System.today().addDays(job.Days_Ahead__c.intValue());
        if (job.Company__c != null) companyId = job.Company__c;
        if (job.Facility__c != null) facilityId = job.Facility__c;
        Database.executeBatch(this, 1);
    }
    
    public SalesOrderAllocateBatch( Id soId ){
        salesOrderId = soId;
        endDate = null;
    }
    
    public SalesOrderAllocateBatch(){
        
    }
    
    private Map<Id, List<Id>> soLines = new Map<Id, List<Id>>();
    public List<Sales_Order__c> start(Database.BatchableContext bc) {
        Set<String> soTypesToExclude = new Set<String>{ SalesOrderService.SO_TYPE_REPAIR };
        soTypesToExclude.addAll(SalesOrderService.SO_RMA_TYPES);
        soTypesToExclude.addAll(SalesOrderService.SO_RMA_REPLACEMENT_TYPES);
        
        SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c');
        solQuery.addFields(new Set<String>{ 'Id', 'Name', 'Sales_Order__c', 'Sales_Order__r.Auto_Allocate_Complete__c' });
        solQuery.setWhereClause('Sales_Order__r.Ready__c = true ' +
                                'AND Sales_Order__r.Type__c NOT IN :soTypesToExclude ' +
                                (companyId != null ? 'AND Sales_Order__r.Company__c = \'' + companyId + '\' ' : '') +
                                (salesOrderId != null ? 'AND Sales_Order__c = \'' + salesOrderId + '\' ' : '') +
                                'AND Status__c = \'' + SalesOrderLineService.SO_LINE_STATUS_OPEN + '\' ' +
                                'AND Quantity_Backordered__c > 0 ' +
                                (endDate != null ? 'AND Required_Date__c <= :endDate ' : '') +
                                'AND Fulfillment_Source__c = \'' + SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY + '\' ' +
                                (facilityId != null ? 'AND Ship_From_Location__r.Facility__c = \'' + facilityId + '\'' : ''));
        solQuery.setOrderByClause('Required_Date__c ASC');
        
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
        for (Sales_Order_Line__c sol:Database.query(solQuery.getQuery())) {
            Sales_Order__c so = sol.Sales_Order__r;
            if (soLines.containsKey(so.Id) == false) {
                soLines.put(so.Id, new List<Id>{ sol.Id });
                salesOrders.add(so);
            } else {
                soLines.get(so.Id).add(sol.Id);
            }
        }

        Set<Id> soIds = soLines.keySet();
        solQuery = new SOQLUtil('Sales_Order_Line__c', false, true);
        solQuery.addField('Sales_Order__c');
        solQuery.setWhereClause('Sales_Order__c IN :soIds ' +
                                'AND (Sales_Order__r.Auto_Allocate_Complete__c = true AND (' +
                                (endDate != null ? ' Required_Date__c > :endDate OR ' : '') +
                                ' Fulfillment_Source__c != \'' + SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY + '\' ' +
                                (facilityId != null ? 'OR Ship_From_Location__r.Facility__c != \'' + facilityId + '\'' : '') +
                                ')) ' +
                                'GROUP BY Sales_Order__c');

        for (AggregateResult ar:Database.query(solQuery.getQuery())) soLines.remove((Id)ar.get(KSE.NamespaceUU + 'Sales_Order__c'));

        for (Integer i = 0; i < salesOrders.size(); i++) {
            if (soLines.containsKey(salesOrders[i].Id) == false) salesOrders.remove(i--);
        }

        return salesOrders;
    }
    
    public void execute(Database.BatchableContext bc, List<Sales_Order__c> salesOrders) {
        Savepoint sp = Database.setSavepoint();
        Sales_Order__c so = salesOrders[0];
        try {
            String whereClause = 'AND Sales_Order_Line__c IN (\'' + String.join(soLines.get(so.Id), '\',\'') + '\')';
            Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(whereClause, 'allocate'));
            List<LineWrapper> shlWrappers = AllocationService.getInventory(shipmentLines.values());

            List<LineWrapper> shlsToAllocate = new List<LineWrapper>();
            List<Id> shlsToPick = new List<Id>();
            for (LineWrapper shlWrapper:shlWrappers) {
                Shipment_Line__c shl = shipmentLines.get(shlWrapper.line.Id);
                
                Decimal qtyToAllocate = 0;
                List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) {
                    if (sw.skid.Input_Quantity__c > 0) {
                        qtyToAllocate += sw.skid.Input_Quantity__c;
                        sw.skid.Item__r = shl.Item__r;
                        swList.add(sw);
                    }
                }

                if (so.Auto_Allocate_Complete__c == true && qtyToAllocate != (shl.Quantity_Planned__c - shl.Quantity_Allocated__c - shl.Quantity_To_Pick__c - shl.Quantity_Picked__c - shl.Quantity_Shipped__c)) {
                    return;
                }

                if (swList.size() > 0) {
                    shlsToAllocate.add(new LineWrapper(shl.Shipment__r, shl, swList));
                    if (shl.Company__r.Auto_Plan_Pick__c == true && shl.Location__r.Bin_Tracked__c != true && shl.Facility__r.Auto_Confirm_Pick_On_Allocation__c == true) shlsToPick.add(shl.Id);
                }
            }

            if (shlsToAllocate.size() > 0) {
                AllocationService.allocate(shlsToAllocate);
                if (shlsToPick.size() > 0) {
                    try {
                        ShipmentInventoryService.autoPick(shlsToPick);
                    } catch (Exception e) {
                        throw new CustomException('Unable to auto-pick: ' + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            Database.rollback(sp);
            errors.add(new Notify.Message(e.getMessage() + ' (' + so.Name + ')', e.getStackTraceString()));
            throw e;
        }
    }
    
    public void finish (Database.BatchableContext bc) {
        Notify.sendEmailBatchFinish(errors.size(), null, errors, bc);
        MasterControlProgram.finishedBatch(this);
    }
}