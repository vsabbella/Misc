public with sharing class OperationTriggerHandler {
    private static final Set<String> fieldsToRound = new Set<String>{ 'Quantity_Completed__c', 'Quantity_Scrapped__c', 'Quantity_Available__c' };

    public static void beforeInsert() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }
    public static void beforeUpdate() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }


    public static void afterUpdate() { validateOSP(Trigger.new,(Map<Id,Operation_Tracking__c>)Trigger.oldMap); }
    public static void beforeDelete() { validateDeleteForOSP(Trigger.old); }

    public static void validateOSP(List<Operation_Tracking__c> operations,Map<Id,Operation_Tracking__c> oldOperations) {
        Map<Id,List<Operation_Tracking__c>> opMap = new Map<Id,List<Operation_Tracking__c>>();
        for (Operation_Tracking__c op:operations) {
            if (KSE.isFieldChanging('Sequence__c',op,oldOperations)) {
                if (!opMap.containsKey(op.Work_Order__c)) {
                    opMap.put(op.Work_Order__c,new List<Operation_Tracking__c>());
                }
                opMap.get(op.Work_Order__c).add(op);
            }
        }

        SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
        opQuery.addFields(new Set<String>{ 'Id','Name','Work_Order__c','Work_Order__r.Name' });
        opQuery.setWhereClause('Work_Order__c IN (\'' + String.join(new List<Id>(opMap.keySet()),'\',\'') + '\')');
        opQuery.setOrderByClause('Sequence__c DESC');

        SOQLUtil.ChildRelationship mtSubquery = new SOQLUtil.ChildRelationship(opQuery,'Material_Trackings__r');
        mtSubquery.addFields(new Set<String>{ 'Id','Name','Item__r.Source__c' });
        opQuery.addChildRelationship(mtSubquery);

        for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
            if (opMap.containsKey(op.Work_Order__c)) {
                for (Material_Tracking__c mt:op.Material_Trackings__r) {
                    if (mt.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP) {
                        opMap.get(op.Work_Order__c)[0].addError(op.Work_Order__r.Name + ': Outside processing components cannot be associated with the last operation');
                        break;
                    }
                }
                opMap.remove(op.Work_Order__c);
            }
        }

    }
    
    // KNDY-15483
    public static void validateOSPAfterDelete(Map<Id,Operation_Tracking__c> operations) {
        Map<Id,List<Operation_Tracking__c>> opMap = new Map<Id,List<Operation_Tracking__c>>();
        for (Operation_Tracking__c op:operations.values () ) {
            if (!opMap.containsKey(op.Work_Order__c)) {
                opMap.put(op.Work_Order__c,new List<Operation_Tracking__c>());
            }
            opMap.get(op.Work_Order__c).add(op);
        }
        Set<Id> woIDs = opMap.keySet();
        
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addField ('Id');
        woQuery.setWhereClause ('Id in :woIds');
        
        SOQLUtil.ChildRelationship opQuery = new SOQLUtil.ChildRelationship( woQuery, 'Operation_Trackings__r' );
        opQuery.addField ('Id');
        opQuery.setOrderByClause('Sequence__c DESC');
        opQuery.setLimit (1); // Limitng to last operation for a work order 
        
        woQuery.addChildRelationship(opQuery);
        
        Set<Id> opIds = new Set<Id> ();
        
        for ( Work_Order__c wo : Database.query ( woQuery.getQuery() ) ) {
            if ( wo.Operation_Trackings__r != null && wo.Operation_Trackings__r.size() > 0 ) {
                opIds.add( wo.Operation_Trackings__r[0].Id ); 
            }
        }
        
        SOQLUtil mtQuery = new SOQLUtil ( 'Material_Tracking__c' ) ;
        mtQuery.addFields (new Set<String> {'Id', 'Name', 'Work_Order__c', 'Work_Order__r.Name', 'Item__r.Source__c', 'Operation_Tracking__c', 'Operation_Tracking__r.Name' } );
        mtQuery.setWhereClause ('Operation_Tracking__c in : opIds');
        
        for ( Material_Tracking__c mt : Database.query (mtQuery.getQuery() ) ) {
            if ( mt.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP )
                opMap.get(mt.Work_Order__c)[0].addError(mt.Operation_Tracking__r.Name + ': Outside processing components cannot be associated with the last operation');
        }
    }

    public static void validateDeleteForOSP(List<Operation_Tracking__c> operations) {
        Map<Id,Operation_Tracking__c> opMap = new Map<Id,Operation_Tracking__c>(operations);

        SOQLUtil materialQuery = new SOQLUtil('Material_Tracking__c');
        materialQuery.addFields(new Set<String>{ 'Id','Name','Item__r.Source__c','Operation_Tracking__r.Name' });
        materialQuery.setWhereClause('Operation_Tracking__c IN :operations');
        for (Material_Tracking__c mt:Database.query(materialQuery.getQuery())) {
            if (mt.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP) {
                Operation_Tracking__c operation = opMap.get(mt.Operation_Tracking__c);
                operation.addError(operation.Name + ': Unable to delete an operation with an outside processing item tied to it');
            }
        }
    }


    public static void afterInsert() { }
    public static void afterDelete() { validateOSPAfterDelete ((Map<Id,Operation_Tracking__c>)Trigger.oldMap); }
    public static void afterUndelete() { }
}