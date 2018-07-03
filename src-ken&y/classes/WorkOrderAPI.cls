global with sharing class WorkOrderAPI {
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static List<String> attributeFields = new List<String>(util.getAllCustomFieldsFromObject(null,'Item_Attribute__c'));
    private static List<String> attributesForDisplay = new List<String>(SkidService2.attributesForPutaway(new List<String>(attributeFields)));

    global static Map<Id,WorkOrderAPIStatus> release(Set<Id> woIds) {
        if (woIds == null || woIds.size() == 0)
            return new Map<Id,WorkOrderAPIStatus>();
        woIds = woIds.clone();
        Map<Id,WorkOrderAPIStatus> result = new Map<Id,WorkOrderAPIStatus>();
        
        WorkOrderPlanningService.release(woIds);
        return result;
    }
    
    global static Map<Id,WorkOrderAPIStatus> kit(Map<Id,WorkOrderWrapper> workOrderWrappers) {
        if (workOrderWrappers == null || workOrderWrappers.size() == 0)
            return null; 
        workOrderWrappers = workOrderWrappers.clone();
        Map<Id,WorkOrderAPIStatus> result = new Map<Id,WorkOrderAPIStatus>();
        
        Set<String> materialFields = new set<string>{ 'Id','Name','Item__c','Item__r.Item_Attribute__c','Item__r.Source__c',
            'Item__r.Non_Inventory__c','Item__r.Name','Work_Order__r.Company__c','Work_Order__r.Default_WIP_Location__c','Work_Order__r.Currency__c' };
        materialFields.addAll(util.getAllCustomFieldsFromObject(null,'Material_Tracking__c')); 
        materialFields.addAll(util.getAllCustomFieldsFromObject('Item__r.','Item__c'));
        materialFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c'));                     
        for (Stock_Movement_Rule_Settings__c smrs:Stock_Movement_Rule_Settings__c.getAll().values())
            if (smrs.Source_Document__c == 'Work Order')
                materialFields.add(smrs.Source_Document_Path__c.toLowerCase());
        /*String materialsQuery = '(' + util.generateQueryFromFieldSet('Material_Tracking__c',new Set<String>(),materialFields,
            ' Type__c = \'Kit\' AND Item__r.Non_Inventory__c = false ').replace('FROM Material_Tracking__c','FROM Material_Trackings__r') + ')';*/
        Set<Id> workOrderIds = workOrderWrappers.keySet();
        // KNDY-10473 FLS Security Fixes for SOQL queries
        SOQLUtil soql = new SOQLUtil ( 'Work_Order__c' ) ;
        soql.addFields ( new Set<String>{'Id','Name','Status__c','Company__c','Facility__c','Default_WIP_Location__c','Facility__r.Facility_Identifier__c'} ) ;
        soql.setWhereClause ( ' Id IN :workOrderIds ' ) ;
        
        SOQLUtil.ChildRelationship mtSoql = new SOQLUtil.ChildRelationship ( soql , 'Material_Trackings__r' ) ;
        mtSoql.addFields ( materialFields ) ;
        mtSoql.setWhereClause ( ' Type__c = \'Kit\' AND Item__r.Non_Inventory__c = false ' ) ;
        
        SOQLUtil.ChildRelationship aeSoql = new SOQLUtil.ChildRelationship ( soql , 'Accounting_Entries__r' ) ;
        aeSoql.addFields ( new Set<String> {'Id'} ) ;
        aeSoql.setWhereClause ( ' Void__c = false ' ) ;
        
        soql.addChildRelationship ( mtSoql ) ;
        soql.addChildRelationship ( aeSoql ) ;
        
        Map<Id,Work_Order__c> workOrders = new Map<Id,Work_Order__c>((List<Work_Order__c>)Database.query( soql.getQuery() ));
        Map<Id,Material_Tracking__c> materials = new Map<Id,Material_Tracking__c>();              
        for (Id workOrderId:workOrderWrappers.keySet()) {
            WorkOrderWrapper workOrderWrapper = workOrderWrappers.get(workOrderId);
            if (!workOrders.containsKey(workOrderId)) {
                result.put(workOrderId,createErrorResult(Label.Invalid_work_order_Id));
                workOrderWrappers.remove(workOrderId);
                continue;
            }
            Work_Order__c workOrder = workOrders.get(workOrderId);
            String error = '';
            if (workOrder.Status__c == 'Draft')
                error = Label.WorkOrder_not_released;
            else if (workOrder.Status__c == 'Closed')
                error = Label.Work_Order_closed;
            else if ((workOrder.Accounting_Entries__r != null && workOrder.Accounting_Entries__r.size() > 0) || workOrder.Status__c == 'Cancelled')
                error = Label.WorkOrder_closed_or_cancelled_or_accounted;
            else if (workOrder.Material_Trackings__r == null || workOrder.Material_Trackings__r.size() == 0)
                error = Label.No_items_to_kit;
            if (error != '') {
                result.put(workOrderId,createErrorResult(error));
                workOrderWrappers.remove(workOrderId);
                workOrders.remove(workOrderId);
            }
            for (Material_Tracking__c material:workOrder.Material_Trackings__r)
                materials.put(material.Id,material);
        }
        if (workOrderWrappers.size() == 0)
            return result;
            
        Map<Id,List<Location__c>> locationsByHeader = SkidService2.locationsFromStockMovementRules(materials.values(),'Pick','Work Order',null);
        Map<String,List<SKID__c>> itemLocationSkidMap = SkidService2.pullSortedSkids((List<sObject>)materials.values(),null,locationsByHeader,' AND Location__r.Nettable__c = true ','Item__c',null,null);
        List<String> attributes = InventoryAPI.getAttributesForSorting();
        Map<String,List<SKID__c>> sortedSkidList = InventoryAPI.sortSkidsByAttributes(itemLocationSkidMap,attributes);

        List<WorkOrderService.MaterialWrapper> mWrappers = new List<WorkOrderService.MaterialWrapper>();       
        Map<String,Lot__c> lotMap = new Map<String,Lot__c>();
        Set<String> lotNames = new Set<String>();
        List<SKID__c> newQuantitySkids = new List<SKID__c>();  
        for (Id workOrderId:workOrderWrappers.keySet()) {
            WorkOrderWrapper workOrderWrapper = workOrderWrappers.get(workOrderId);
            Work_Order__c workOrder = workOrders.get(workOrderId);
            Map<Id,List<SKID__c>> materialToIssuedSkids = new Map<Id,List<SKID__c>>();
            String errorMessage = '';
            for (Id materialId:workOrderWrapper.demandSKIDs.keySet()) {
                DemandSKIDWrapper demandSkidWrapper = workOrderWrapper.demandSKIDs.get(materialId);
                if (!materials.containsKey(materialId)) {
                    errorMessage = Label.One_or_more_items_are_not_available_for_kitting;
                    break;
                }
                if (locationsByHeader == null || locationsByHeader.size() == 0 || !locationsByHeader.containsKey(materialId)) {
                    errorMessage = Label.Stock_movement_rules_are_not_setup;
                    break;
                }
                Material_Tracking__c material = materials.get(materialId);
                Decimal totalQtyIssued = 0;
                for (IssuedQuantity iq:demandSkidWrapper.quantities) {
                    SKID__c tempSkid = new SKID__c(Item__c = material.Item__c,Location__c = locationsByHeader.get(material.Id)[0].Id,Item__r = material.Item__r,Quantity__c = 0,
                    								Quantity_To_Issue__c = iq.quantity,Type__c = 'Location', Company__c = workOrder.Company__c);
                    if (tempSkid.Item__r.Item_Attribute__r.Lot_Number__c) {
                        if (iq.lot == null || iq.lot == '')
                            errorMessage = Label.Missing_a_lot_number;
                        else
                            tempSkid.Lot_Number__c = iq.lot;
                    }
                    if (tempSkid.Item__r.Item_Attribute__r.Expiration_Date__c) {
                        if (iq.expirationDate == null)
                            errorMessage = Label.Missing_an_expiration_date;
                        else
                           tempSkid.Expiration_Date__c = iq.expirationDate;
                    } 
                    if (tempSkid.Item__r.Item_Attribute__r.Date_Received__c) {
                        if (iq.dateReceived == null)
                            errorMessage = Label.Missing_a_date_received;
                        else
                            tempSkid.Date_Received__c = iq.dateReceived;
                    }
                    for (String attributeField:iq.attributes.keySet()) 
                        if ((Boolean)tempSkid.Item__r.Item_Attribute__r.get(attributeField))
                            tempSkid.put(attributeField,iq.attributes.get(attributeField));
                    if (errorMessage != '')
                        break;
                    String key = SkidService2.generateKeyforSkid(tempSkid,attributes,null,null);
                    totalQtyIssued += iq.quantity;
                    List<SKID__c> skidList = new List<SKID__c>();
                    if (!sortedSkidList.containsKey(key)) {
                        //If no inventory exists, create a zero-quantity location SKID
                        SkidService2.populateLotNames(tempSkid,null,lotMap,lotNames);
                        newQuantitySkids.add(tempSkid);
                        skidList.add(tempSkid);
                    } else {
                        Decimal tempQty = iq.quantity;
                        skidList = sortedSkidList.get(key).deepClone(true,true,true);
                        for (SKID__c skid:skidList) {
                            if (skid.Quantity__c < tempQty)
                                skid.Quantity_To_Issue__c = skid.Quantity__c;
                            else
                                skid.Quantity_To_Issue__c = tempQty;
                            tempQty -= skid.Quantity_To_Issue__c;
                        }
                        //If there is reminaing quantity, drive the first SKID negative
                        if (tempQty > 0)
                            skidList[0].Quantity_To_Issue__c = KSE.addQuantityToField(skidList[0].Quantity_To_Issue__c,tempQty);
                    }
                    for (Integer i=0;i<skidList.size();i++) {
                        if (skidList[i].Quantity_To_Issue__c == null || skidList[i].Quantity_To_Issue__c <= 0) {
                            skidList.remove(i);
                            i--;
                        }
                    }
                    if (!materialToIssuedSkids.containsKey(materialId))
                        materialToIssuedSkids.put(materialId,new List<SKID__c>());
                    materialToIssuedSkids.get(materialId).addAll(skidList);
                }
                if (totalQtyIssued > KSE.subtractDecimals(material.Quantity_Required__c,material.Quantity_Issued__c))
                    errorMessage = Label.Issuing_more_quantity_than_quantity_short_on_one_or_more_demand_SKIDs;
                if (errorMessage != '')
                    break;
            }
            if (errorMessage != '') {
                result.put(workOrderId,createErrorResult(errorMessage));
                workOrderWrappers.remove(workOrderId);
                if (workOrder.Material_Trackings__r != null && workOrder.Material_Trackings__r.size() > 0)
                    for (Material_Tracking__c material:workOrder.Material_Trackings__r)
                        materials.remove(material.Id);
                workOrders.remove(workOrderId);
            } else {
                result.put(workOrderId,createSuccessResult());
                if (workOrder.Material_Trackings__r != null && workOrder.Material_Trackings__r.size() > 0) {
                    for (Material_Tracking__c material:workOrder.Material_Trackings__r) {
                        if (materialToIssuedSkids.containsKey(material.Id)) {
                            WorkOrderService.MaterialWrapper mWrapper = new WorkOrderService.MaterialWrapper();
                            mWrapper.material = material;
                            mWrapper.skids = materialToIssuedSkids.get(material.Id);
                            mWrappers.add(mWrapper);
                        }
                    }
                }
            }
        }
        Map<String,Lot__c> createdLotMap = SkidService2.createLots(lotMap,lotNames);
        Map<String,List<SKID__c>> quantitySkids = new Map<String,List<SKID__c>>();
        Map<String,SKID__c> skidsToInsert = new Map<String,SKID__c>();
        for (SKID__c qtySkid:newQuantitySkids) {
            String uniqueLotString = SkidService2.lotUniqueKey(qtySkid,null);
            qtySkid.Lot__c = createdLotMap.get(uniqueLotString).Id;
            String skidKey = SkidService2.generateKeyForSkid(qtySkid,attributesForDisplay,null,null);
            if (!quantitySkids.containsKey(skidKey))
                quantitySkids.put(skidKey,new List<SKID__c>());
            quantitySkids.get(skidKey).add(qtySkid);
            if (!skidsToInsert.containsKey(skidKey)) {
                SKID__c skidToInsert = qtySkid.clone(false,true);
                skidToInsert.Quantity_To_Issue__c = 0;
                skidsToInsert.put(skidKey,skidToInsert);
            }
        }
        DML.insertAsSystem(skidsToInsert.values());
        for (String skidKey:skidsToInsert.keySet()) {
            Id skidId = skidsToInsert.get(skidKey).Id;
            for (SKID__c qtySkid:quantitySkids.get(skidKey))
                qtySkid.Id = skidId;
        }
        WorkOrderService.kit(mWrappers,workOrders,attributesForDisplay);
        return result;
    }
    
    global static Map<Id,WorkOrderAPIStatus> dekit(Map<Id,WorkOrderWrapper> workOrderWrappers) {
        if (workOrderWrappers == null || workOrderWrappers.size() == 0)
            return null;
        workOrderWrappers = workOrderWrappers.clone();
        Map<Id,WorkOrderAPIStatus> result = new Map<Id,WorkOrderAPIStatus>();
        
        Set<String> materialFields = new set<string>{ 'Id','Name','Item__r.Name','Work_Order__r.Default_WIP_Location__c' };
        materialFields.addAll(util.getAllCustomFieldsFromObject(null,'Material_Tracking__c')); 
        materialFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c'));   
        materialFields.addAll(util.getAllCustomFieldsFromObject('Item__r.','Item__c'));                    
        for (Stock_Movement_Rule_Settings__c smrs:Stock_Movement_Rule_Settings__c.getAll().values())
            if (smrs.Source_Document__c == 'Work Order')
                materialFields.add(smrs.Source_Document_Path__c.toLowerCase());
        /*String materialsQuery = '(' + util.generateQueryFromFieldSet('Material_Tracking__c',new Set<String>(),materialFields,
            ' Type__c = \'Kit\' AND Item__r.Non_Inventory__c = false AND Quantity_Issued__c > 0 ').replace('FROM Material_Tracking__c','FROM Material_Trackings__r') + ')';*/
        Set<Id> workOrderIds = workOrderWrappers.keySet();
        // KNDY-10473 FLS Security Fixes for SOQL queries
        SOQLUtil soql = new SOQLUtil ( 'Work_Order__c' ) ;
        soql.addFields ( new Set<String>{'Id','Name','Status__c','Facility__c', 'Company__c', 'Facility__r.Facility_Identifier__c'} ) ;
        soql.setWhereClause ( ' Id IN :workOrderIds ' ) ;
        
        SOQLUtil.ChildRelationship mtSoql = new SOQLUtil.ChildRelationship ( soql , 'Material_Trackings__r' ) ;
        mtSoql.addFields ( materialFields ) ;
        mtSoql.setWhereClause ( ' Type__c = \'Kit\' AND Item__r.Non_Inventory__c = false AND Quantity_Issued__c > 0 ' ) ;
        
        SOQLUtil.ChildRelationship aeSoql = new SOQLUtil.ChildRelationship ( soql , 'Accounting_Entries__r' ) ;
        aeSoql.addFields ( new Set<String> {'Id'} ) ;
        aeSoql.setWhereClause ( ' Void__c = false ' ) ;
        
        soql.addChildRelationship ( mtSoql ) ;
        soql.addChildRelationship ( aeSoql ) ;
        
        Map<Id,Work_Order__c> workOrders = new Map<Id,Work_Order__c>((List<Work_Order__c>)Database.query( soql.getQuery() ));
        Map<Id,Material_Tracking__c> materials = new Map<Id,Material_Tracking__c>();
        
        for (Id workOrderId:workOrderWrappers.keySet()) {
            WorkOrderWrapper workOrderWrapper = workOrderWrappers.get(workOrderId);
            if (!workOrders.containsKey(workOrderId)) {
                result.put(workOrderId,createErrorResult(Label.Invalid_work_order_Id));
                workOrderWrappers.remove(workOrderId);
                continue;
            }
            Work_Order__c workOrder = workOrders.get(workOrderId);
            String error = '';
            if (workOrder.Status__c == 'Draft')
                error = Label.WorkOrder_not_released;
            else if (workOrder.Status__c == 'Closed')
                error = Label.Work_Order_closed;
            else if ((workOrder.Accounting_Entries__r != null && workOrder.Accounting_Entries__r.size() > 0) || workOrder.Status__c == 'Cancelled')
                error = Label.WorkOrder_closed_or_cancelled_or_accounted;
            else if (workOrder.Material_Trackings__r == null || workOrder.Material_Trackings__r.size() == 0)
                error = Label.No_items_to_Dekit;
            if (error != '') {
                result.put(workOrderId,createErrorResult(error));
                workOrderWrappers.remove(workOrderId);
                workOrders.remove(workOrderId);
                continue;
            }            
            
            for (Material_Tracking__c material:workOrder.Material_Trackings__r)
                materials.put(material.Id,material);
        }
        if (workOrderWrappers.size() == 0)
            return result;
        
        List<WorkOrderService.MaterialWrapper> mWrappers = new List<WorkOrderService.MaterialWrapper>();
        for (Id workOrderId:workOrderWrappers.keySet()) {
            WorkOrderWrapper workOrderWrapper = workOrderWrappers.get(workOrderId);
            Work_Order__c workOrder = workOrders.get(workOrderId);
            String error = '';
            Map<Id,List<SKID__c>> skidsForPutaway = new Map<Id,List<SKID__c>>();            
            for (Id materialId:workOrderWrapper.demandSKIDs.keySet()) {
                DemandSKIDWrapper demandSKIDWrapper = workOrderWrapper.demandSKIDs.get(materialId);
                for (IssuedQuantity iq:demandSKIDWrapper.quantities) {
                    if (!materials.containsKey(materialId)) {
                        error = Label.One_or_more_items_are_not_available_for_dekitting;
                        break;
                    }
                    Material_Tracking__c material = materials.get(materialId);
                    SKID__c skid = new SKID__c(
                        Item__c = material.Item__c,
                        Item__r = material.Item__r,
                        Type__c = 'Location',
                        Company__c = workOrder.Company__c
                    );
                    if (iq.locationId == null) {
                        error = Label.One_or_more_items_is_missing_a_location;
                        break;
                    }
                    skid.Location__c = iq.locationId;
                    if (iq.quantity == null || iq.quantity <= 0) {
                        error = Label.Quantity_must_be_non_zero;
                        break;
                    }
                    if (iq.quantity > material.Quantity_Issued__c) {
                        error = Label.One_or_more_quantities_is_returning_more_than_quantity_issued;
                        break;
                    }
                    skid.Quantity__c = iq.quantity;
                    if (skid.Item__r.Item_Attribute__r.Expiration_Date__c) {
                        if (iq.expirationDate == null) {
                            error = Label.Missing_an_expiration_date;
                            break;
                        }
                        skid.Expiration_Date__c = iq.expirationDate;
                    }
                    if (skid.Item__r.Item_Attribute__r.Date_Received__c) {
                        if (iq.dateReceived == null) {
                            error = Label.Missing_a_date_received;
                            break;
                        }
                        skid.Date_Received__c = iq.dateReceived;
                    }
                    if (skid.Item__r.Item_Attribute__r.Lot_Number__c) {
                        if (iq.lot == null || iq.lot == '') {
                            error = Label.Missing_a_lot_number;
                            break;
                        }
                        skid.Lot_Number__c = iq.lot;
                    }
                    for (String attributeField:iq.attributes.keySet())
                        if ((Boolean)skid.Item__r.Item_Attribute__r.get(attributeField))
                            skid.put(attributeField,iq.attributes.get(attributeField));
                    if (!skidsForPutaway.containsKey(material.Id))
                        skidsForPutaway.put(material.Id,new List<SKID__c>());
                    skidsForPutaway.get(material.Id).add(skid);
                }
                if (error != '')
                    break;
            }
            if (error != '') {
                result.put(workOrderId,createErrorResult(error));
                for (Material_Tracking__c material:workOrder.Material_Trackings__r)
                    materials.remove(material.Id);
                workOrderWrappers.remove(workOrderId);
                workOrders.remove(workOrderId);
            } else {
                result.put(workOrderId,createSuccessResult());
                for (Material_Tracking__c material:workOrder.Material_Trackings__r) {
                    if (skidsForPutaway.containsKey(material.Id)) {
                        WorkOrderService.MaterialWrapper mWrapper = new WorkOrderService.MaterialWrapper();
                        mWrapper.material = material;
                        mWrapper.skids = skidsForPutaway.get(material.Id);
                        mWrappers.add(mWrapper);
                    }
                }
            }
        }
        WorkOrderService.dekit(mWrappers,attributesForDisplay);        
        return result;
    }
    

    global class WorkOrderWrapper {
        global Id workOrderId { get; private set; }
        global Map<Id,DemandSKIDWrapper> demandSKIDs { get; private set; }
        global IssuedQuantity qtyCompleted { get; set; }
        global Decimal qtyScrapped { get; set; }
        global WorkOrderWrapper(Id woId) { 
            workOrderId = woId;
            demandSKIDs = new Map<Id,DemandSKIDWrapper>(); 
            qtyCompleted = new IssuedQuantity();
            qtyScrapped = 0;
        }
    }
    global class DemandSKIDWrapper {
        global List<IssuedQuantity> quantities { get; private set; }
        global DemandSKIDWrapper() { quantities = new List<IssuedQuantity>(); } 
    }
    global class IssuedQuantity {
        global Decimal quantity { get; set; }
        global Id locationId { get; set; }
        global String lot { get; set; }
        global Date expirationDate { get; set; }
        global Date dateReceived { get; set; }
        global Map<String,Object> attributes { get; private set; }
        global IssuedQuantity() { 
            attributes = new Map<String,Object>(); 
            quantity = 0;
        }
    }
    global class WorkOrderAPIException extends Exception {  }
    global class WorkOrderAPIStatus {
        global Boolean success { get; set; }
        global String errorMessage { get; set; }
    }
    private static WorkOrderAPIStatus createErrorResult(String errorMessage) {
        WorkOrderAPIStatus status = new WorkOrderAPIStatus();
        status.success = false;
        status.errorMessage = errorMessage;
        return status;
    }
    private static WorkOrderAPIStatus createSuccessResult() {
        WorkOrderAPIStatus status = new WorkOrderAPIStatus();
        status.success = true;
        return status;
    }
    
    global static Map<Id,WorkOrderAPIStatus> complete(Map<Id,WorkOrderWrapper> workOrderWrappers) { throw new WorkOrderAPIException('This method has been deprecated'); }
}