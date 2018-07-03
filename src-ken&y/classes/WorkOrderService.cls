public with sharing class WorkOrderService {
    public static final String WO_TYPE_REGULAR = 'Regular';
    public static final String WO_TYPE_REPAIR = 'Repair';
    public static final String WO_TYPE_SUBCONTRACT = 'SubContract';

    public static final String WO_STATUS_DRAFT = 'Draft';
    public static final String WO_STATUS_RELEASED = 'Released';
    public static final String WO_STATUS_IN_PROCESS = 'In Process';
    public static final String WO_STATUS_COMPLETE = 'Complete';
    public static final String WO_STATUS_CLOSED = 'Closed';
    public static final String WO_STATUS_CANCELLED = 'Cancelled';

    public static final String MATERIAL_TYPE_BACKFLUSH = 'Backflush';
    public static final String MATERIAL_TYPE_KIT = 'Kit';
    public static final String MATERIAL_TYPE_BYPRODUCT = 'By-product';
    public static final String MATERIAL_TYPE_REPAIR = 'Repair';

    public static final Set<String> materialQtyFields = new Set<String>{ 'Quantity_Allocated__c', 'Quantity_Completed__c', 'Quantity_Issued__c', 'Quantity_Scrapped__c', 'Quantity_Used__c' };
    public static final Set<String> operationQtyFields = new Set<String>{ 'Hours_Consumed__c', 'Quantity_Completed__c', 'Quantity_Scrapped__c' };

    public enum SaveType { SAVE, CONSOLIDATE_AND_SAVE }

    public static Boolean allowWorkOrderUpdate = false;

    private static SchemaUtil util = SchemaUtil.getInstance();
    private static final Map<String, Schema.sObjectField> skidFieldMap = util.getFieldsMap('SKID__c');
    private static final Map<String, Schema.SObjectField> otFields = util.getFieldsMap('Operation_Transaction__c');

    public class WorkOrderServiceException extends Exception { }

    public static List<Work_Order__c> getWorkOrders(Set<Id> woIds,Set<String> fieldSets,Set<String> additionalFields,Set<String> subQueries) { return (List<Work_Order__c>)Database.query(getWorkOrderQuery(woIds,fieldSets,additionalFields,subQueries)); }
    public static String getWorkOrderQuery(Set<Id> woIds,Set<String> fieldSets,Set<String> additionalFields,Set<String> subQueries) {
        if (fieldSets == null) {
            fieldSets = new Set<String>();
        }
        if (additionalFields == null) {
            additionalFields = new Set<String>();
        }
        if (subQueries == null) {
            subQueries = new Set<String>();
        }

        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addAllCustomFields();
        woQuery.addFields(new Set<String>{ 'Company__r.Serial_Control__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Packaging_UOM__r.Package_Class__c', 'Assembly_Item_Specification__r.Item__r.Container__c', 'Assembly_Item_Specification__r.Item__r.Packaging_UOM__c',
            'Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__r.Level__c',
            'Item__r.Stocking_UOM__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
            'Facility__r.Facility_Identifier__c','Completed__c', 'Quantity_Value_Holder__c'
        });
        woQuery.addAllCustomFields(Item_Specification__c.sObjectType,'Assembly_Item_Specification__r');
        woQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        woQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        woQuery.addAllCustomFields(Location__c.sObjectType,'Complete_to_Location__r');
        woQuery.addAllCustomFields(Location__c.sObjectType,'MRB_Location__r');
        woQuery.addAllCustomFields(Location__c.sObjectType,'Default_WIP_Location__r');
        woQuery.addFields(additionalFields);
        for (String fieldSet:fieldSets) {
            woQuery.addFields(fieldSet);
        }

        String whereClause;
        if (woIds != null && woIds.size() > 0) {
            whereClause = 'Id IN (\'' + String.join(new List<Id>(woIds),'\',\'') + '\')';
        }
        woQuery.setWhereClause(whereClause);
        woQuery.setForUpdate();

        for (String subQ:subQueries) {
            SOQLUtil.ChildRelationship subQuery = new SOQLUtil.ChildRelationship(woQuery,subQ);
            subQuery.addAllCustomFields();
            woQuery.addChildRelationship(subQuery);
        }

        return woQuery.getQuery();
    }

    public static List<Material_Tracking__c> getMaterials(Set<Id> woIds,Set<Id> opIds,Set<String> materialTypes,Set<String> fieldSets,Set<String> additionalFields,String additionalWhere) { return (List<Material_Tracking__c>)Database.query(getMaterialsQuery(woIds,opIds,materialTypes,fieldSets,additionalFields,additionalWhere,false)); }
    public static List<Material_Tracking__c> getMaterials(Set<Id> woIds,Set<Id> opIds,Set<String> materialTypes,Set<String> fieldSets,Set<String> additionalFields,String additionalWhere,Boolean forUpdate) { return (List<Material_Tracking__c>)Database.query(getMaterialsQuery(woIds,opIds,materialTypes,fieldSets,additionalFields,additionalWhere,forUpdate)); }
    public static String getMaterialsQuery(Set<Id> woIds,Set<Id> opIds,Set<String> materialTypes,Set<String> fieldSets,Set<String> additionalFields,String additionalWhere) { return getMaterialsQuery(woIds,opIds,materialTypes,fieldSets,additionalFields,additionalWhere,false); }
    public static String getMaterialsQuery(Set<Id> woIds,Set<Id> opIds,Set<String> materialTypes,Set<String> fieldSets,Set<String> additionalFields,String additionalWhere,Boolean forUpdate) {
        if (fieldSets == null) {
            fieldSets = new Set<String>();
        }
        if (additionalFields == null) {
            additionalFields = new Set<String>();
        }

        SOQLUtil materialQuery = new SOQLUtil('Material_Tracking__c');
        materialQuery.addAllCustomFields();
        materialQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        materialQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        materialQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        materialQuery.addFields(new Set<String>{ 'Item__r.Stocking_UOM__r.Package_Class__c', 'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Work_Order__r.Shipment_line__r.Sales_Order_Line__r.Related_Sales_Order_Line__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Item__r.Stocking_UOM__r.Package_Class__r.Level__c',

            'Work_Order__r.Company__r.Serial_Control__c', 'Work_Order__r.Facility__r.Facility_Identifier__c' });
        materialQuery.addFields(additionalFields);
        for (Stock_Movement_Rule_Settings__c smrs:Stock_Movement_Rule_Settings__c.getAll().values()) {
            if (smrs.Source_Document__c == 'Work Order') {
                materialQuery.addField(smrs.Source_Document_Path__c);
                materialQuery.addField(smrs.Source_Document_Path_Putaway__c);
            }
        }
        for (String fieldSet:fieldSets) {
            materialQuery.addFields(fieldSet);
        }

        String whereClause = ' Item__r.Non_Inventory__c = false ';
        if (materialTypes != null && materialTypes.size() > 0) {
            whereClause += ' AND Type__c IN (\'' + String.join(new List<String>(materialTypes),'\',\'') + '\')';
        }
        if (woIds != null && woIds.size() > 0) {
            whereClause += ' AND Work_Order__c IN (\'' + String.join(new List<Id>(woIds),'\',\'') + '\')';
        }
        if (opIds != null && opIds.size() > 0) {
            whereClause += ' AND Operation_Tracking__c IN (\'' + String.join(new List<Id>(opIds),'\',\'') + '\')';
        }
        if (additionalWhere != null) {
            whereClause += ' ' + additionalWhere;
        }
        materialQuery.setWhereClause(whereClause);
        if (!forUpdate) {
            materialQuery.setOrderByClause('Component_Sequence__c ASC');
        } else {
            materialQuery.setForUpdate();
        }

        return materialQuery.getQuery();
    }

    /*
     * KIT SECTION
     */
    public static void validateForKit(List<Work_Order__c> workOrders) {
        if (workOrders == null || workOrders.size() == 0) {
            return;
        }

        for (Work_Order__c wo:workOrders) {
            if (wo.Status__c == WO_STATUS_DRAFT) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.WorkOrder_not_released);
            } else if (wo.Status__c == WO_STATUS_CANCELLED) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.WorkOrder_accounted_or_cancelled);
            } else if (wo.Status__c == WO_STATUS_CLOSED) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.WorkOrder_already_closed);
            } else if (wo.Default_WIP_Location__c == null) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.WIP_location_should_be_specified);
            }
        }
    }

    public static List<WorkOrderWrapper> getKitData(Set<Id> woIds) {
        List<WorkOrderWrapper> wrappers = new List<WorkOrderWrapper>();
        if (woIds == null || woIds.size() == 0) return wrappers;

        List<Material_Tracking__c> materials = getMaterials(woIds, null, new Set<String>{ MATERIAL_TYPE_KIT, MATERIAL_TYPE_REPAIR }, new Set<String>{ 'Kit' }, new Set<String>{ 'Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Related_Sales_Order_Line__c','Work_Order__r.Shipment_Line__r.Sales_Order_Line__c','Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c' }, ' AND Operation_Tracking__c = null ');
        if (materials.size() == 0) return wrappers;

        Id companyId;
        Id facilityId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Set<Id> nonShippableWos = new Set<Id>();
        Set<Id> rlIds = new Set<Id>();
        Set<Id> solIds = new Set<Id>();
        Set<Id> allocatedMaterials = new Set<Id>();
        Set<Id> repairWOIds = new Set<Id>();
        Map<Id, List<Shipment_Line__c>> shipmentLines = new Map<Id, List<Shipment_Line__c>>();
        for (Material_Tracking__c mt1:materials) {
        	if (mt1.Type__c == MATERIAL_TYPE_REPAIR) {
            	
                if(mt1.Work_Order__r.Field_Service__c == false && mt1.Work_Order__r.Receipt_Line__c == null && mt1.Work_Order__r.Shipment_line__r.Sales_Order_Line__r.Receipt_Line__c ==null){
	                repairWOIds.add(mt1.Work_Order__c);
	            }
        	}
        }
        if(repairWOIds.size()>0)
        	shipmentLines = getShipmentLinesForWorkOrders(repairWOIds, 'Sales_Order_Line__r.Required_Date__c, Sales_Order_Line__r.CreatedDate ASC,Sales_Order_Line__c');
        
        
        Set<Id> relatedSOlineIds = new Set<Id>();
        Map<Id,Shipment_Line__c> shlineWOmap = new Map<Id,Shipment_Line__c>();
        Map<Id,Id> rmaSOLinemap = new Map<Id,Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        for(Id woId:shipmentLines.keyset()){
        	
        	if(shipmentLines.containsKey(woId)) {
        		for (Shipment_Line__c shline:shipmentLines.get(woId)) {
        			salesOrderIds.add(shline.Sales_Order_Line__r.Sales_Order__c);
	        		relatedSOlineIds.add(shline.Sales_Order_Line__r.Related_Sales_Order_Line__c);//Get Related SOL and Query with that to get non repair line.
	        		if(!shlineWOmap.containskey(shline.Work_Order__c))
            			shlineWOmap.put(shline.Work_Order__c,shline);
	        	}
        	}
        }
        
        if(relatedSOlineIds.size()>0){
        	SOQLUtil solineQuery = new SOQLUtil('Sales_Order_Line__c',false);
        	solineQuery.addFields(new Set<String>{ 'Id','Status__c','Name','Related_Sales_Order_Line__r.Name','Related_Sales_Order_Line__c', 'Product__r.Item__r.Packaging_UOM__c' });
        	solineQuery.setWhereClause('Sales_Order__c in :salesOrderIds and Related_Sales_Order_Line__c in :relatedSOlineIds and (Type__c != \'Repair\')');
        	
        	for(Sales_Order_Line__c rmaSOL : Database.query(solineQuery.getQuery())){
	          if(!rmaSOLinemap.containskey(rmaSOL.Related_Sales_Order_Line__c)){
	    	  		rmaSOLinemap.put(rmaSOL.Related_Sales_Order_Line__c,rmaSOL.Id);
	    	  }
        	}
        }
        
        for (Material_Tracking__c mt:materials) {
            companyId = mt.Work_Order__r.Company__c;
            facilityId = mt.Work_Order__r.Facility__c;
            items.put(mt.Item__c, mt.Item__r);

            if (mt.Type__c == MATERIAL_TYPE_REPAIR) {
                if (mt.Work_Order__r.Field_Service__c) nonShippableWos.add(mt.Work_Order__c);
                else if (mt.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c != null) solIds.add(mt.Work_Order__r.Shipment_line__r.Sales_Order_Line__r.Related_Sales_Order_Line__c);
                else if (mt.Work_Order__r.Receipt_Line__c != null) rlIds.add(mt.Work_Order__r.Receipt_Line__c);
                else if (mt.Work_Order__r.Shipment_Line__c == null && shlineWOmap.containskey(mt.Work_Order__c)){
                	
            	 	Sales_Order_Line__c soline = shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__r;
            	 	if(rmaSOLinemap.containskey(soline.Related_Sales_Order_Line__c)){
            	 		solIds.add(rmaSOLinemap.get(soline.Related_Sales_Order_Line__c));
            	 	}
                	 
                }
            } else if (mt.Allocation_Required__c) {
                allocatedMaterials.add(mt.Id);
            }
        }
        
        
		
		Map<Id, List<String>> attributes = AllocationService.getSkidAttributes(companyId, items);
        List<String> planAttributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'license_plate_number__c' });

        Set<Id> locationIds = new Set<Id>();
        Map<String, List<Location__c>> locationMap = SkidService3.locationsFromStockMovementRules(materials, 'Pick', new Set<String>{ 'material_tracking__c' }, null, locationIds);

        Map<Id, Id> installBaseSkids = new Map<Id, Id>();
        if (nonShippableWos.size() > 0) {
            SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c');
            solQuery.addFields(new Set<String>{ 'Id', 'Name', 'Work_Order__c', 'SKID__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c' });
            solQuery.setWhereClause('Status__c = \'Open\' AND Work_Order__c IN :nonShippableWos AND Sales_Order__r.Type__c = \'' + SalesOrderService.SO_TYPE_REPAIR + '\' AND SKID__c != null');
            for (Sales_Order_Line__c soLine:Database.query(solQuery.getQuery())) installBaseSkids.put(soLine.Work_Order__c, soLine.SKID__c);
        }

        Set<Id> itemIds = items.keySet();
        List<Id> ibSkidIds = installBaseSkids.values();

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Sales_Order_Line__r.Related_Sales_Order_Line__c','Sales_Order_Line__r.Type__c','Company__c', 'Lot_Number__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Lot__r.Lot_Hold__c', 'Facility2__r.Facility_Identifier__c' });
        skidQuery.addFields(new Set<String>(SkidService3.attributesForUniqueKey));
        skidQuery.setWhereClause('Item__c IN :itemIds ' +
                                 'AND (Id IN :ibSkidIds ' +
                                 'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' AND (Receipt_Line__c IN :rlIds OR Sales_Order_Line__c IN :solIds)) ' +
                                 'OR (Facility2__c = :facilityId ' +
                                 'AND Receipt_Line__c = null ' +
                                 'AND Customer__c = null ' +
                                 'AND (Lot__c = null OR Lot__r.Lot_Hold__c = false) ' +
                                 'AND (Location__c IN :locationIds OR Location__c = null) ' +
                                 'AND (Type__c IN (\'' + SkidService3.SKID_TYPE_ALLOCATED + '\', \'' + SkidService3.SKID_TYPE_PLANNED + '\') ' +
                                 'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' AND Shipment_Line__c = null))))');
        skidQuery.setOrderByClause(String.join(SkidService3.populateSortCriteria(null, companyId), ','));

        Set<Id> skidIds = new Set<Id>();
        Map<Id, List<SKID__c>> skidMap = new Map<Id, List<SKID__c>>();
        Map<List<String>, Decimal> allocatedQtys = new Map<List<String>, Decimal>();
        Map<List<String>, List<SKID__c>> itemLocSkids = new Map<List<String>, List<SKID__c>>();
        Map<List<String>, Decimal> allQtys = new Map<List<String>, Decimal>();
        for (SKID__c skid:Database.query(skidQuery.getQuery())) {
            SKID__c skidClone = skid.clone(false, true);
            skidClone.Shipment_Line__c = null;
            skidClone.Material_Tracking__c = null;

            List<String> allocKey = SkidService3.generateKey(skidClone, attributes.get(skid.Item__c));
            List<String> planKey = SkidService3.generateKey(skidClone, planAttributes);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                if (allocatedMaterials.contains(skid.Material_Tracking__c)) {
                    if (!skidMap.containsKey(skid.Material_Tracking__c)) skidMap.put(skid.Material_Tracking__c, new List<SKID__c>{ skid });
                    else skidMap.get(skid.Material_Tracking__c).add(skid);
                }

                allocatedQtys.put(allocKey, KSE.addQuantityToField(allocatedQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
            } else if (skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                allocatedQtys.put(allocKey, KSE.addQuantityToField(allocatedQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
                allocatedQtys.put(planKey, KSE.addQuantityToField(allocatedQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
            } else if (skid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE) {
                skidIds.add(skid.Id);
                skidMap.put(skid.Id, new List<SKID__c>{ skid });
            } else {
                skidIds.add(skid.Id);
                if (skid.Receipt_Line__c != null) {
                    if (!skidMap.containsKey(skid.Receipt_Line__c)) skidMap.put(skid.Receipt_Line__c, new List<SKID__c>{ skid });
                    else skidMap.get(skid.Receipt_Line__c).add(skid);
                } 
                else if (skid.Receipt_Line__c == null && skid.Sales_Order_Line__c != null && skid.Sales_Order_Line__r.Type__c == null && (rmaSOLinemap.isEmpty() || rmaSOLinemap.containskey(skid.Sales_Order_Line__r.Related_Sales_Order_Line__c))){// Do we need to check anything related to RMA..&& skid.Sales_Order_Line__r.Type__c == 'Repair'
                	if (!skidMap.containsKey(skid.Sales_Order_Line__c)) skidMap.put(skid.Sales_Order_Line__c, new List<SKID__c>{ skid });
                    else skidMap.get(skid.Sales_Order_Line__c).add(skid);
                } else {
                    List<String> itemLocKey = new List<String>{ skid.Item__c, skid.Location__c };
                    if (!itemLocSkids.containsKey(itemLocKey)) itemLocSkids.put(itemLocKey, new List<SKID__c>{ skid });
                    else itemLocSkids.get(itemLocKey).add(skid);

                    allQtys.put(allocKey, KSE.addQuantityToField(allQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
                    allQtys.put(planKey, KSE.addQuantityToField(allQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
                }
            }
        }

        Map<Id, List<Serial__c>> serialMap = new Map<Id, List<Serial__c>>();
        if (skidIds.size() > 0) {
            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Allocated_SKID__c', 'Allow_Reentry__c', 'Company__c', 'Item__c', 'SKID__c', 'Temporary_Value_Holder__c' });
            serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
            serialQuery.addFields('Serial');
            serialQuery.setWhereClause('SKID__c IN :skidIds');
            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                if (!serialMap.containsKey(serial.SKID__c)) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
                else serialMap.get(serial.SKID__c).add(serial);
            }
        }

        for (Material_Tracking__c mt:materials) {
            WorkOrderWrapper wrapper = new WorkOrderWrapper(mt.Work_Order__r, mt, new List<SkidService3.SerialWrapper>());
            List<String> allocAttrs = attributes.get(mt.Item__c);

            List<String> displayFields = new List<String>();
            if (mt.Type__c == MATERIAL_TYPE_REPAIR && mt.Work_Order__r.Field_Service__c == true) {
                displayFields.add('Customer__c');
            } else {
                displayFields = new List<String>{ 'Location__c', 'Bin__c' };
                if (mt.Type__c == MATERIAL_TYPE_REPAIR) displayFields.add('Customer__c');
            }
            displayFields.addAll(SkidService3.trackedAttributes(null, null, mt.Item__r));
            if (mt.Type__c != MATERIAL_TYPE_REPAIR) displayFields.add('Consigned_Owner__c');
            for (Integer i = 0; i < displayFields.size(); i++) {
                if (displayFields[i] == 'Lot_Number__c') {
                    displayFields[i] = 'Lot__c';
                    break;
                }
            }
            List<FieldInfo> skidFlds = FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields);

            List<FieldInfo> readFields = FieldInfo.fetchJsonFieldInfos('SKID__c', SchemaUtil.getInstance().getFieldsFromFieldSetString(SKID__c.sObjectType, 'Kit_RO'));
            for (FieldInfo fi:readFields) {
                fi.editable = false;
            }
            skidFlds.addAll(readFields);

            skidFlds.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Quantity_Available__c', 'Quantity_to_Issue__c' }));

            for (FieldInfo fi:skidFlds) {
                if (fi.field == 'Customer__c' || fi.field == 'Consigned_Owner__c' || fi.field == 'Quantity_Available__c') {
                    fi.editable = false;
                }
                fi.field = 'skid.' + fi.field;
            }
            wrapper.skidFields = skidFlds;
            if (mt.Type__c == MATERIAL_TYPE_REPAIR && (mt.Work_Order__r.Field_Service__c == true || mt.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c != null || mt.Work_Order__r.Receipt_Line__c != null || (shlineWOmap.containskey(mt.Work_Order__c) && shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__c !=null ))) {//&& mt.Work_Order__r.Receipt_Line__c ==null//shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__r.Type__c == Repair
                
                Id relatedRMALineId;
                if(shlineWOmap.containskey(mt.Work_Order__c) && shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__c !=null){
                	if(rmaSOLinemap.containskey(shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__r.Related_Sales_Order_Line__c)){
                		relatedRMALineId = rmaSOLinemap.get(shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__r.Related_Sales_Order_Line__c);
                	}
                	
                }
                List<SKID__c> skids = mt.Work_Order__r.Field_Service__c == true ? skidMap.get(installBaseSkids.get(mt.Work_Order__c)) : skidMap.get(mt.Work_Order__r.Receipt_Line__c != null ? mt.Work_Order__r.Receipt_Line__c : (shlineWOmap.containskey(mt.Work_Order__c) && shlineWOmap.get(mt.Work_Order__c).Sales_Order_Line__c !=null && relatedRMALineId !=null) ? relatedRMALineId:mt.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Related_Sales_Order_Line__c);
                if (skids != null) {
                    for (SKID__c skid:skids) {
                        skid.Quantity_Available__c = skid.Quantity__c;
                        skid.Quantity_Allocated__c = 0;
                        skid.Quantity_Required__c = skid.Quantity__c;
                        skid.Total_Material__c = skid.Quantity__c;
                        skid.Quantity_to_Issue__c = 0;
                        skid.Lot_Number__c = skid.Lot__r.Name;
                        skid.Item__r = mt.Item__r;

                        wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(skid, serialMap.containsKey(skid.Id) ? serialMap.get(skid.Id) : new List<Serial__c>()));
                    }
                }
            } else {
                if (!locationMap.containsKey(mt.Id)) throw new WorkOrderServiceException(mt.Name + ': ' + 'Matching stock movement rule not found');

                if (mt.Allocation_Required__c) {
                    Map<List<String>, List<SKID__c>> aggregatedSkids = new Map<List<String>, List<SKID__c>>();
                    for (Location__c loc:locationMap.get(mt.Id)) {
                        List<String> itemLocKey = new List<String>{ mt.Item__c, loc.Id };
                        if (itemLocSkids.containsKey(itemLocKey) == false) continue;

                        for (SKID__c skid:itemLocSkids.get(itemLocKey)) {
                            skid = skid.clone(true, true);
                            List<String> allocKey = SkidService3.generateKey(skid, allocAttrs);
                            if (!aggregatedSkids.containsKey(allocKey)) aggregatedSkids.put(allocKey, new List<SKID__c>{ skid });
                            else aggregatedSkids.get(allocKey).add(skid);
                        }
                    }

                    for (SKID__c allocatedSkid:skidMap.get(mt.Id)) {
                        SKID__c skidClone = allocatedSkid.clone(false, true);
                        skidClone.Material_Tracking__c = null;

                        List<String> allocKey = SkidService3.generateKey(skidClone, allocAttrs);
                        for (SKID__c skid:aggregatedSkids.get(allocKey)) {
                            skid.Temporary_Value_Holder__c = allocatedSkid.Id;
                            if (skid.Quantity__c < 0) skid.Quantity__c = 0;
                            skid.Quantity_Available__c = Math.min(allocatedSkid.Quantity__c, skid.Quantity__c);
                            skid.Quantity_Allocated__c = allocatedSkid.Quantity__c;
                            skid.Quantity_to_Issue__c = 0;
                            skid.Lot_Number__c = skid.Lot__r.Name;
                            skid.Item__r = mt.Item__r;

                            List<Serial__c> allocatedSerials = new List<Serial__c>();
                            List<Serial__c> serials = new List<Serial__c>();
                            if (serialMap.containsKey(skid.Id)) {
                                for (Serial__c serial:serialMap.get(skid.Id)) {
                                    if (serial.Allocated_SKID__c == allocatedSkid.Id) allocatedSerials.add(serial);
                                    else if (serial.Allocated_SKID__c == null) serials.add(serial);
                                }
                                allocatedSerials.addAll(serials);
                            }

                            wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(skid, allocatedSerials));
                        }
                    }
                } else {
                    for (Location__c loc:locationMap.get(mt.Id)) {
                        List<String> itemLocKey = new List<String>{ mt.Item__c, loc.Id };
                        if (itemLocSkids.containsKey(itemLocKey) == false) continue;

                        for (SKID__c skid:itemLocSkids.get(itemLocKey)) {
                            if ((mt.Type__c != MATERIAL_TYPE_REPAIR && skid.Stocking_UOM__c != skid.Packaging_UOM__c) || (mt.Type__c == MATERIAL_TYPE_REPAIR && skid.Packaging_UOM__c != mt.Work_Order__r.Packaging_UOM__c)) continue;
                            skid = skid.clone(true, true);

                            List<String> allocKey = SkidService3.generateKey(skid, allocAttrs);
                            List<String> planKey = SkidService3.generateKey(skid, planAttributes);

                            skid.Quantity_Required__c = allQtys.get(allocKey);
                            skid.Total_Material__c = allQtys.get(planKey);

                            if (allocatedQtys.containsKey(allocKey) == true) {
                                skid.Temporary_Value_Holder__c = JSON.serialize(allocKey);
                                skid.Quantity_Required__c -= allocatedQtys.get(allocKey);
                            }
                            if (allocatedQtys.containsKey(planKey) == true) {
                                skid.Temporary_Value_Holder1__c = JSON.serialize(planKey);
                                skid.Total_Material__c -= allocatedQtys.get(planKey);
                            }
                            if (skid.Quantity_Required__c < 0) skid.Quantity_Required__c = 0;
                            if (skid.Total_Material__c < 0) skid.Total_Material__c = 0;
                            if (skid.Quantity__c < 0) skid.Quantity__c = 0;
                            skid.Quantity_Available__c = Math.min(skid.Quantity__c, Math.min(skid.Quantity_Required__c, skid.Total_Material__c));

                            skid.Quantity_Allocated__c = 0;
                            skid.Quantity_to_Issue__c = 0;
                            skid.Lot_Number__c = skid.Lot__r.Name;
                            skid.Item__r = mt.Item__r;

                            List<Serial__c> serials = new List<Serial__c>();
                            if (serialMap.containsKey(skid.Id)) {
                                for (Serial__c serial:serialMap.get(skid.Id)) {
                                    if (serial.Allocated_SKID__c == null) serials.add(serial);
                                }
                            }

                            wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(skid, serials));
                        }
                    }
                }
            }

            wrappers.add(wrapper);
        }

        return wrappers;
    }

    public static List<WorkOrderWrapper> getDeKitData(Set<Id> workOrderIds) {
        List<WorkOrderWrapper> wowList = new List<WorkOrderWrapper>();

        List<Material_Tracking__c> materials = getMaterials(workOrderIds,null,new Set<String>{ MATERIAL_TYPE_KIT, MATERIAL_TYPE_REPAIR },new Set<String>{'Kit'},null,' AND Quantity_Issued__c > 0 AND Operation_Tracking__c = null');

        if (materials.size() == 0) {
            return wowList;
        }

        Map<String,List<Location__c>> locationsByHeader = SkidService3.locationsFromStockMovementRules(materials,'Pick',new Set<String>{'Material_Tracking__c'},null,null);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id','Name','Company__c','Customer__c','Lot_Number__c','Material_Tracking__c','Quantity__c','Sales_Order_Line__c','Stocking_UOM__c','Packaging_UOM__c',
            'Item__r.Stocking_UOM__c','Type__c','Unique_Key__c','Work_Order__c','Location__r.Bin_Tracked__c','Location__r.Facility__c', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c' });
        skidQuery.addFields(new Set<String>(SkidService3.attributesForPutaway()));
        skidQuery.setWhereClause('Type__c = \'WIP\' AND Material_Tracking__c IN :materials');

        Set<Id> skidIds = new Set<Id> ();
        Map<Id,List<SKID__c>> wipSkids = new Map<Id,List<SKID__c>>();
        for (SKID__c wipSkid:Database.query(skidQuery.getQuery())) {
            if (!wipSkids.containsKey(wipSkid.Material_Tracking__c)) {
                wipSkids.put(wipSkid.Material_Tracking__c,new List<SKID__c>());
            }
            wipSkids.get(wipSkid.Material_Tracking__c).add(wipSkid);
            skidIds.add(wipSkid.id);
        }

        SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        serialQuery.addFields(new Set<String>{ 'Id','Name','Allocated_SKID__c','Allow_Reentry__c','Company__c','Item__c','SKID__c','Temporary_Value_Holder__c' });
        serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
        serialQuery.addFields('Serial');
        serialQuery.setWhereClause('SKID__c IN :skidIds');

        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
        for (Serial__c serial:Database.query(serialQuery.getQuery())) {
        	if (!serialMap.containsKey(serial.SKID__c)) {
        		serialMap.put(serial.SKID__c,new List<Serial__c>());
        	}
        	serialMap.get(serial.SKID__c).add(serial);
        }

        for (Material_Tracking__c mt:materials) {
            WorkOrderWrapper wow = new WorkOrderWrapper(mt.Work_Order__r,mt,new List<SkidService3.SerialWrapper>());

            List<String> displayFields = new List<String>();
            if (mt.Type__c == MATERIAL_TYPE_REPAIR && mt.Work_Order__r.Field_Service__c == true) {
                displayFields.add('Customer__c');
            } else {
                displayFields = new List<String>{ 'Location__c', 'Bin__c' };
                if (mt.Type__c == MATERIAL_TYPE_REPAIR) displayFields.add('Customer__c');
            }
            displayFields.addAll(SkidService3.trackedAttributes(null, null, mt.Item__r));
            if (mt.Type__c != MATERIAL_TYPE_REPAIR) displayFields.add('Consigned_Owner__c');
            for (Integer i = 0; i < displayFields.size(); i++) {
                if (displayFields[i] == 'Lot_Number__c') {
                    displayFields[i] = 'Lot__c';
                    break;
                }
            }
            List<FieldInfo> skidFlds = FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields);
            FieldInfo f = new FieldInfo('ScrapLocation__c','Scrap Location','reference');
            f.referenceTo = 'Location__c';
            f.editable = true;
            skidFlds.add(f);

            f = new FieldInfo('ScrapBin__c','Scrap Bin','reference');
            f.referenceTo = 'Bin__c';
            f.editable = true;
            skidFlds.add(f);

            skidFlds.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',new List<String>{ 'Quantity__c', 'Quantity_to_Issue__c', 'Quantity_to_Scrap__c' }));

            for (FieldInfo fi:skidFlds) {
                if (fi.field == 'Customer__c' || fi.field == 'Consigned_Owner__c' || fi.field == 'Quantity_Available__c') {
                    fi.editable = false;
                }
                if (fi.field == 'Quantity__c') {
                    fi.title = 'Quantity Available';
                    fi.editable = false;
                } else if (fi.field == 'Quantity_to_Issue__c') {
                    fi.title = 'Quantity To Return';
                } else if (fi.field == 'Location__c') {
                    fi.title = 'Dekit Location';
                } else if (fi.field == 'Bin__c') {
                    fi.title = 'Dekit Bin';
                }
                fi.field = 'skid.' + fi.field;
            }
            wow.skidFields = skidFlds;


            if (wipSkids.containsKey(mt.Id)) {
                for (SKID__c skid:wipSkids.get(mt.Id)) {
                    Location__c loc = new Location__c();
                    if (locationsByHeader.containsKey(mt.Id)) loc = locationsByHeader.get(mt.Id)[0];

                    SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid,serialMap.containsKey(skid.Id) ? serialMap.geT(skid.Id) : new List<Serial__c>());
                    sw.trackedAttributes = new List<String>();

                    if (mt.Work_Order__r.Type__c == WO_TYPE_REPAIR && mt.Work_Order__r.Shipment_Line__c == null && mt.Work_Order__r.Field_Service__c == true) {
                        skid.Location__c = null;
                        skid.Location__r = null;
                    } else {
                        skid.Location__c = loc.Id;
                        skid.Location__r = loc;

                        if (loc.Bin_Tracked__c) {
                            sw.trackedAttributes.add('skid.bin__c');
                        }
                    }

                    skid.Quantity_to_Issue__c = 0;
                    skid.Quantity_To_Scrap__c = 0;

                    wow.serialWrapperList.add(sw);
                }
            }

            if (wow.serialWrapperList.size() > 0) {
                wowList.add(wow);
            }
        }
        return wowList;
    }

    public static void checkKitErrors(List<WorkOrderWrapper> wrappers) {
        if (wrappers == null || wrappers.size() == null) {
            return;
        }

        Set<Id> allocatedSkidIds = new Set<Id>();
        Set<Id> skidIds = new Set<Id>();
        List<Lot__c> lots = new List<Lot__c>();
        for (WorkOrderWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.workOrder;
            Material_Tracking__c mt = wrapper.material;

            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Id != null) {
                    skidIds.add(sw.skid.Id);
                } else if (sw.skid.Lot_Number__c != null && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Lot_Number__c) {
                    lots.add(SkidService3.populateLotNames(sw.skid, null));
                }

                if (mt.Allocation_Required__c && sw.skid.Temporary_Value_Holder__c != null && wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && mt.Item__r.Item_Attribute__c != null && mt.Item__r.Item_Attribute__r.Serial_Number__c) {
                    allocatedSkidIds.add((Id)sw.skid.Temporary_Value_Holder__c);
                }
            }
        }

        Map<Id, List<String>> allocatedSerials = new Map<Id, List<String>>();
        if (allocatedSkidIds.size() > 0) {
            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Allocated_SKID__c' });
            serialQuery.setWhereClause('Allocated_SKID__c IN :allocatedSkidIds');
            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                if (!allocatedSerials.containsKey(serial.Allocated_SKID__c)) allocatedSerials.put(serial.Allocated_SKID__c, new List<String>());
                allocatedSerials.get(serial.Allocated_SKID__c).add(serial.Name);
            }
        }

        Map<Id, Decimal> skidQtys = new Map<Id, Decimal>();
        if (skidIds.size() > 0) {
            SOQLUtil skidQuery = new SOQLUtil('SKID__c');
            skidQuery.addFields(new Set<String>{ 'Id', 'Quantity__c' });
            skidQuery.setWhereClause('Id IN :skidIds');
            skidQuery.setForUpdate();
            for (SKID__c skid:Database.query(skidQuery.getQuery())) {
                skidQtys.put(skid.Id, skid.Quantity__c);
            }
        }

        Map<List<String>,Lot__c> lotMap = lots.size() > 0 ? SkidService3.createLots(lots) : new Map<List<String>, Lot__c>();

        Boolean hasQuantity = false;
        Set<String> serialKeys = new Set<String>();
        Map<Id,Decimal> skidMap = new Map<Id,Decimal>();
        for (WorkOrderWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.workOrder;
            Material_Tracking__c mt = wrapper.material;

            Decimal totalKitted = 0;
            Map<Id,Decimal> allocatedSerialsLeft = new Map<Id,Decimal>();
            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Id != null) {
                    if (skidQtys.containsKey(sw.skid.Id)) {
                        sw.skid.Quantity__c = skidQtys.get(sw.skid.Id);
                    } else {
                        sw.skid.Id = null;
                        sw.skid.Quantity__c = 0;
                    }
                } else if (sw.skid.Lot_Number__c != null && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Lot_Number__c) {
                    sw.skid.Lot__r = lotMap.get(SkidService3.lotUniqueKey(sw.skid));
                    sw.skid.Lot__c = sw.skid.Lot__r.Id;
                }

                if (sw.skid.Quantity_to_Issue__c < 0) {
                    throw new WorkOrderServiceException(mt.Name + ': Quantity to issue cannot be negative');
                } else if (sw.skid.Quantity_to_Issue__c > 0) {
                    hasQuantity = true;
                    totalKitted += sw.skid.Quantity_to_Issue__c;

                    if (sw.skid.Lot__c != null && sw.skid.Lot__r.Lot_Hold__c) {
                       throw new WorkOrderServiceException(mt.Name + ': ' + Label.Lot_Number_is_on_hold + ': ' + sw.skid.Lot__r.Name);
                    }

                    if (sw.skid.Expiration_Date__c != null && sw.skid.Expiration_Date__c < System.today()) {
                       throw new WorkOrderServiceException(mt.Name + ': ' + Label.Expiration_Date_is_in_the_past);
                    }

                    Id allocatedSkidId = mt.Allocation_Required__c && sw.skid.Temporary_Value_Holder__c != null ? (Id)sw.skid.Temporary_Value_Holder__c : null;
                    if (sw.skid.Id == null) {
                        if (sw.skid.Location__c == null) throw new WorkOrderServiceException(mt.Name + ': Location is required');
                        SkidService3.checkRequiredAttributes(sw.skid, SkidService3.trackedAttributes(null, sw.skid.Location__r, sw.skid.Item__r), null, null, ' is required for ' + mt.Name);
                    } else if ((mt.Type__c == MATERIAL_TYPE_REPAIR && (wo.Field_Service__c == true || mt.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c != null || mt.Work_Order__r.Receipt_Line__c != null)) || allocatedSkidId != null) {
                        Decimal qtyAvailable = sw.skid.Quantity_Available__c;
                        if (skidMap.containsKey(sw.skid.Id)) qtyAvailable = Math.min(skidMap.get(sw.skid.Id), qtyAvailable);
                        if (allocatedSkidId != null && skidMap.containsKey(allocatedSkidId)) qtyAvailable = Math.min(skidMap.get(allocatedSkidId), qtyAvailable);

                        if (sw.skid.Quantity_to_Issue__c > qtyAvailable) {
                            throw new WorkOrderServiceException(mt.Name + ': Cannot issue more quantity (' + sw.skid.Quantity_to_Issue__c + ') than quantity available (' + qtyAvailable + ')');
                        }

                        skidMap.put(sw.skid.Id, (skidMap.containsKey(sw.skid.Id) ? skidMap.get(sw.skid.Id) : sw.skid.Quantity__c) - sw.skid.Quantity_to_Issue__c);
                        if (allocatedSkidId != null) skidMap.put(allocatedSkidId, (skidMap.containsKey(allocatedSkidId) ? skidMap.get(allocatedSkidId) : sw.skid.Quantity_Allocated__c) - sw.skid.Quantity_to_Issue__c);
                    }

                    if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && mt.Item__r.Item_Attribute__r != null && mt.Item__r.Item_Attribute__r.Serial_Number__c) {
                        if (allocatedSkidId != null && !allocatedSerialsLeft.containsKey(allocatedSkidId) && allocatedSerials.containsKey(allocatedSkidId)) {
                            allocatedSerialsLeft.put(allocatedSkidId, allocatedSerials.get(allocatedSkidId).size());
                        }

                        Integer serialsToKit = 0;
                        for (Serial__c serial:sw.serialList) {
                            if (serial.Temporary_Value_Holder__c == 'Kit') {
                                String serialKey = wo.Company__c + '-' + mt.Item__c + '-' + serial.Name;
                                if (serialKeys.contains(serialKey)) {
                                    throw new WorkOrderServiceException(Label.Serial + ' ' + serial.Name + ' specified more than once');
                                } else {
                                    serialKeys.add(serialKey);
                                }
                                serialsToKit++;

                                if (serial.Allocated_SKID__c != null) allocatedSerialsLeft.put(allocatedSkidId, KSE.subtractDecimals(allocatedSerialsLeft.get(allocatedSkidId), 1));
                            }
                        }

                        if (serialsToKit != sw.skid.Quantity_to_Issue__c) {
                            throw new WorkOrderServiceException(mt.Name + ': Number of serials to issue (' + serialsToKit + ') does not match quantity to issue (' + sw.skid.Quantity_to_Issue__c + ')');
                        }
                    }
                }
            }

            if (mt.Allocation_Required__c && allocatedSerialsLeft.size() > 0) {
                for (Id allocatedSkidId:allocatedSerialsLeft.keySet()) {
                    Decimal qtyLeft = skidMap.get(allocatedSkidId);
                    Decimal serialsLeft = allocatedSerialsLeft.get(allocatedSkidId);
                    List<String> allocSerials = allocatedSerials.get(allocatedSkidId);

                    if (serialsLeft > qtyLeft) {
                        Decimal serialsRequired = allocSerials.size() - qtyLeft;
                        String errMsg = mt.Name + ': Must kit ';
                        if (serialsRequired != allocSerials.size()) {
                            errMsg += 'at least ' + serialsRequired;
                        } else {
                            errMsg += 'all';
                        }
                        errMsg += ' allocated serials';
                        if (allocSerials.size() <= 20) errMsg += ': ' + String.join(allocSerials,', ');

                        throw new WorkOrderServiceException(errMsg);
                    }
                }
            }

            Decimal qtyToKit = mt.Allocation_Required__c ? mt.Quantity_Allocated__c : mt.Quantity_Short__c;
            if (totalKitted > qtyToKit) {
                throw new WorkOrderServiceException(mt.Name + ': Cannot issue more quantity (' + totalKitted + ') than quantity required (' + qtyToKit + ')');
            }
        }

        if (!hasQuantity) {
            throw new WorkOrderServiceException(Label.No_Quantities_Entered);
        }
    }

    public static void checkDeKitErrors(Map<Id,Work_Order__c> woMap,Map<Id,List<WorkOrderWrapper>> wowMap) {
        if (woMap == null || woMap.size() == 0) {
            return;
        }

        Map<String,Serial__c> userSpecifiedSerials = new Map<String,Serial__c>();

        Set<Id> locationIds = new Set<Id>();
        Set<Id> materialIds = new Set<Id> ();
        Set<Id> skidIds = new Set<Id> ();

        for (Id woId:woMap.keySet()) {
            if (wowMap.containsKey(woId)) {
                for (WorkOrderWrapper wow:wowMap.get(woId)) {
                    materialIds.add(wow.material.id);

                    for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                        skidIds.add( sw.skid.Id );

                        if (sw.skid.Quantity_to_Scrap__c > 0) {
                            List<String> scrapLocBin = sw.skid.Temporary_Value_Holder1__c.split(',');
                            if (scrapLocBin[0] != 'null') {
                                locationIds.add(scrapLocBin[0]);
                            }
                        }
                    }

                }
            }
        }

        // KNDY-15415 - Locking the material tracking and Skid rows to avoid race
        SOQLUtil compSkidQuery = new SOQLUtil ('Skid__c');
        compSkidQuery.addFields( new Set<String> { 'Id', 'quantity__c'} );
        compSkidQuery.setWhereClause(' Id in :skidIds ');
        compSkidQuery.setForUpdate();
        Map<Id, Skid__c> componentSkidMap = new Map<Id,Skid__c>( (List<Skid__c>) Database.query ( compSkidQuery.getQuery () ) );

        SOQLUtil mtQuery = new SOQLUtil('Material_Tracking__c');
        mtQuery.addAllCustomFields();
        mtQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        mtQuery.addFields(new Set<String>{ 'Work_Order__r.Item__r.Id', 'Work_Order__r.Item__r.Item_Attribute__r.Serial_Number__c', 'Work_Order__r.Company__c',
            'Work_Order__r.Company__r.Serial_Control__c', 'Work_Order__r.Default_WIP_Location__r.Facility__c', 'Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c' });
        mtQuery.addAllCustomFields(Work_Order__c.sObjectType, 'Work_Order__r');
        mtQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        mtQuery.setWhereClause('Id IN :materialIds');
        mtQuery.setForUpdate();
        Map<Id, Material_Tracking__c> matlTrackingMap = new Map<Id,Material_Tracking__c>( (List<Material_Tracking__c>) Database.query ( mtQuery.getQuery () ) );

        SOQLUtil locationQuery = new SOQLUtil('Location__c');
        locationQuery.addAllCustomFields();
        locationQuery.setWhereClause('Id IN :locationIds');
        Map<Id,Location__c> locations = new Map<Id,Location__c>((List<Location__c>)Database.query(locationQuery.getQuery()));

        for (Id woId:woMap.keySet()) {
            Work_Order__c wo = woMap.get(woId);
            Boolean hasAnyInputQuantity = false;

            if (wowMap.containsKey(woId)) {
                List<WorkOrderWrapper> wowList = wowMap.get(woId);
                for (WorkOrderWrapper wow:wowList) {
                    if ( matlTrackingMap.containsKey ( wow.material.id ) ) {
                        wow.material = matlTrackingMap.get ( wow.material.id );
                    }

                    Boolean fieldServiceOrRmaRepair = false;

                    if(wow.workOrder.Type__c == MATERIAL_TYPE_REPAIR && (wow.workOrder.Field_Service__c == true ||
                                                wow.material.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c != null) ){
                        fieldServiceOrRmaRepair = true;
                    }

                    for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                        if ( componentSkidMap.containsKey(sw.skid.Id) ) {
                            sw.skid.Quantity__c = componentSkidMap.get(sw.skid.Id).Quantity__c;
                        } else {
                            // Possible that the location skid is consumed (and deleted) in a parallel operation
                            // and the skid is still pointing to the skid record
                            sw.skid.Id = null;
                            sw.skid.Quantity__c = 0;
                        }

                        List<Serial__c> serialsToDekit = new List<Serial__c>();
                        List<Serial__c> serialsToScrap = new List<Serial__c>();
                        for (Serial__c serial:sw.serialList) {
                            if (serial.Temporary_Value_Holder__c == 'Dekit') {
                                serialsToDekit.add(serial);
                            } else if (serial.Temporary_Value_Holder__c == 'Scrap') {
                                serialsToScrap.add(serial);
                            }
                        }

                        Decimal totalQuantity = KSE.addQuantityToField(sw.skid.Quantity_to_Issue__c,sw.skid.Quantity_to_Scrap__c);

                        if (totalQuantity > KSE.subtractDecimals(wow.material.Quantity_Issued__c,wow.material.Quantity_Scrapped__c)) {
                            throw new WorkOrderServiceException(Label.Cannot_return_more_than_effective_quantity_issued);
                        }

                        if (sw.skid.Quantity_to_Issue__c < 0) {
                            throw new WorkOrderServiceException(wow.material.Name + ': ' + Label.Quantity_to_issue_cannot_be_negative);
                        } else if (sw.skid.Quantity_to_Issue__c > 0) {
                            hasAnyInputQuantity = true;

                            if (!fieldServiceOrRmaRepair) {
                                if (sw.skid.Location__c == null) {
                                    throw new WorkOrderServiceException(wow.material.Name + ': Dekit Location is required');
                                } else if (sw.skid.Location__r.Bin_Tracked__c && sw.skid.Bin__c == null) {
                                    throw new WorkOrderServiceException(wow.material.Name + ': Dekit bin is required');
                                }
                            }

                            if (wow.workOrder.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && wow.material.Item__r.Item_Attribute__r != null && wow.material.Item__r.Item_Attribute__r.Serial_Number__c) {
                                if (serialsToDekit.size() != sw.skid.Quantity_to_Issue__c) {
                                    throw new WorkOrderServiceException(wow.material.Name + ': ' + Label.Serials_do_not_match_with_the_dekit_quantity + ' Number Of Serials: ' + serialsToDekit.size() + ' Specified Quantity: ' + sw.skid.Quantity_to_Issue__c);
                                }

                                for (Serial__c ser:serialsToDekit) {
                                    Id companyId = wow.workOrder.Company__c;
                                    Id itemId = wow.material.Item__c;
                                    String uniqueKey = companyId + '-' + itemId + '-' + ser.Name;

                                    if (!userSpecifiedSerials.containsKey(uniqueKey)){
                                        userSpecifiedSerials.put(uniqueKey,ser);
                                    } else {
                                        throw new WorkOrderServiceException(ser.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                                    }
                                }
                            }
                        }

                        if (sw.skid.Quantity_to_Scrap__c < 0) {
                            throw new WorkOrderServiceException(wow.material.Name + ': Quantity to scrap cannot be negative');
                        } else if (sw.skid.Quantity_To_Scrap__c > 0 ) {
                            hasAnyInputQuantity = true;

                            SKID__c scrapSkid = sw.skid.clone(false,true);
                            scrapSkid.Location__c = null;
                            scrapSkid.Bin__c = null;

                            List<String> scrapLocBin = sw.skid.Temporary_Value_Holder1__c.split(',');
                            if (scrapLocBin[0] != 'null') {
                                scrapSkid.Location__c = scrapLocBin[0];
                                scrapSkid.Location__r = locations.get(scrapLocBin[0]);
                            }
                            if (scrapLocBin[1] != 'null') {
                                scrapSkid.Bin__c = scrapLocBin[1];
                            }

                            if (scrapSkid.Location__c == null) {
                                throw new WorkOrderServiceException(wow.material.Name + ': Scrap location is required');
                            } else if (scrapSkid.Location__r.Bin_Tracked__c && scrapSkid.Bin__c == null) {
                                throw new WorkOrderServiceException(wow.material.Name + ': Scrap bin is required');
                            }

                            if (wow.workOrder.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && wow.material.Item__r.Item_Attribute__r != null && wow.material.Item__r.Item_Attribute__r.Serial_Number__c) {
                                if (serialsToScrap.size() != sw.skid.Quantity_to_Scrap__c) {
                                    throw new WorkOrderServiceException(wow.material.Name + ': ' + Label.Quantity_to_scrap_does_not_match_number_of_serials + ' Number Of Serials: ' + serialsToScrap.size() + ' Specified Quantity: ' + sw.skid.Quantity_to_Scrap__c);
                                }

                                for (Serial__c ser:serialsToScrap) {
                                    Id companyId = wow.workOrder.Company__c;
                                    Id itemId = wow.material.Item__c;
                                    String uniqueKey = companyId + '-' + itemId + '-' + ser.Name;

                                    if (!userSpecifiedSerials.containsKey(uniqueKey)){
                                        userSpecifiedSerials.put(uniqueKey,ser);
                                    } else {
                                        throw new WorkOrderServiceException(ser.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                                    }
                                }
                            }
                        }
                    }
                }

                if (!hasAnyInputQuantity) {
                    throw new WorkOrderServiceException(Label.No_Quantities_Entered);
                }
            }
        }
    }

    public static void kit(List<WorkOrderWrapper> wrappers) {
        if (wrappers == null || wrappers.size() == null) {
            return;
        }

        checkKitErrors(wrappers);

        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Material_Tracking__c');
        attributes.add('Customer__c');

        Id companyId;
        Map<Id,Item__c> items = new Map<Id,Item__c>();
        List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        for (WorkOrderWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Id == null && sw.skid.Quantity_to_Issue__c > 0) {
                    sw.skid.Container_Item__c = sw.skid.Item__c;
                    skidsForPutaway.add(new SkidService3.SerialWrapper(sw.skid,new List<Serial__c>()));
                }
            }

            if (wrapper.material.Allocation_Required__c) {
                companyId = wrapper.workOrder.Company__c;
                items.put(wrapper.material.Item__c,wrapper.material.Item__r);
            }
        }

        Map<Id,List<String>> skidAttributes = items.size() > 0 ? AllocationService.getSkidAttributes(companyId,items) : null;

        Map<List<String>,SkidService3.SerialWrapper> toSkids;
        if (skidsForPutaway.size() > 0) {
            toSkids = SkidService3.putAwayService(skidsForPutaway,null,null);
            skidsForPutaway.clear();
        }

        List<SkidService3.SerialWrapper> allocatedSkidsForPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> itData = new Map<Id,SkidService3.ParameterData>();
        List<Material_Tracking__c> mtsToUpdate = new List<Material_Tracking__c>();
        Map<Id,Work_Order__c> wosToUpdate = new Map<Id,Work_Order__c>();
        Map<List<String>,List<String>> keyMap = new Map<List<String>,List<String>>();
        for (WorkOrderWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.workOrder;
            Material_Tracking__c mt = wrapper.material;
            Material_Tracking__c mtToUpdate = new Material_Tracking__c(Id = mt.Id, Quantity_Issued__c = mt.Quantity_Issued__c, Quantity_Allocated__c = mt.Quantity_Allocated__c);

            SkidService3.ParameterData itInfo = itData.get(wo.Id);
            if (itInfo == null) {
                itInfo = new SkidService3.ParameterData();
                itInfo.sourceDoc = new Work_Order__c(Company__c = wo.Company__c);
                itInfo.icType = 'Work Order Kit';
            }

            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (!(sw.skid.Quantity_to_Issue__c > 0)) {
                    continue;
                }

                SKID__c wipSkid = sw.skid.clone(false,true);
                wipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                wipSkid.Quantity__c = wipSkid.Quantity_to_Issue__c;
                wipSkid.Facility2__c = wo.Facility__c;
                wipSkid.Location__c = wo.Default_WIP_Location__c;
                wipSkid.Material_Tracking__c = mt.Id;
                wipSkid.Receipt_Line__c = null;
                if (mt.Type__c != MATERIAL_TYPE_REPAIR) {
                    wipSkid.Consigned_Owner__c = null;
                    wipSkid.Purchase_Order_Line__c = null;
                }
                else if(mt.Type__c == MATERIAL_TYPE_REPAIR){
                	
                    wipSkid.Sales_Order_Line__c = null;
                }
                wipSkid.Bin__c = null;

                List<Serial__c> serialsToIssue = new List<Serial__c>();
                for (Serial__c serial:sw.serialList) {
                    if (serial.Temporary_Value_Holder__c == 'Kit') {
                        serial.Temporary_Value_Holder__c = null;
                        serial.Allocated_SKID__c = null;
                        serialsToIssue.add(serial);
                    }
                }
                skidsForPutaway.add(new SkidService3.SerialWrapper(wipSkid,serialsToIssue));

                // Negative skid for WIP consumptions
                SKID__c negativeSkid = sw.skid.clone(false, true);
                negativeSkid.Quantity__c = KSE.subtractDecimals(0, wipSkid.Quantity__c);
                skidsForPutaway.add (new SkidService3.SerialWrapper(negativeSkid,null));

                SKID__c fromSkid = sw.skid;
                if (sw.skid.Id == null) fromSkid = toSkids.get(SkidService3.generateKey(fromSkid,null)).skid;

                String itType = 'Work Order Component Issue';
                if (mt.Type__c == MATERIAL_TYPE_REPAIR) {
                    itType = 'Work Order Repair Component Issue';
                }

                Inventory_Transaction__c it = SkidService3.createInventoryTransaction(mt,itType,sw.skid.Quantity_to_Issue__c,fromSkid,wipSkid,attributes);
                it.Purchase_Order_Line__c = wipSkid.Purchase_Order_Line__c;
                it.Receipt_Line__c = sw.skid.Receipt_Line__c;
                itInfo.itList.add(it);

                keyMap.put(SkidService3.generateKey(it, attributes), SkidService3.generateKey(wipSkid, attributes));

                mtToUpdate.Quantity_Issued__c = KSE.addQuantityToField(mtToUpdate.Quantity_Issued__c,sw.skid.Quantity_to_Issue__c).setScale(6, System.RoundingMode.HALF_UP);

                if (mt.Allocation_Required__c) {
                    SKID__c allocatedSkid = new SKID__c(
                        Company__c = wo.Company__c,
                        Facility2__c = wo.Facility__c,
                        Item__c = mt.Item__c,
                        Quantity__c = -sw.skid.Quantity_to_Issue__c,
                        Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                        Material_Tracking__c = mt.Id
                    );
                    for (String attr:skidAttributes.get(mt.Item__c)) {
                        allocatedSkid.put(attr,sw.skid.get(attr));
                    }

                    allocatedSkidsForPutaway.add(new SkidService3.SerialWrapper(allocatedSkid,new List<Serial__c>()));

                    mtToUpdate.Quantity_Allocated__c = KSE.subtractDecimals(mtToUpdate.Quantity_Allocated__c,sw.skid.Quantity_to_Issue__c).setScale(6, System.RoundingMode.HALF_UP);
                }
            }

            if (itInfo.itList.size() > 0) {
                itData.put(wo.Id,itInfo);
                mtsToUpdate.add(mtToUpdate);
                if (!wosToUpdate.containsKey(wo.Id) && wo.Status__c != WO_STATUS_COMPLETE) {
                    wosToUpdate.put(wo.Id,new Work_Order__c(Id = wo.Id, Status__c = WO_STATUS_IN_PROCESS));
                }
            }
        }

        if (skidsForPutaway.size() > 0) {
            toSkids = SkidService3.putAwayService(skidsForPutaway,attributes,null);

            Map<Id, List<String>> toSkidsMap = new Map<Id, List<String>>();
            for ( List<String> key : toSkids.keySet() ) {
                toSkidsMap.put(toSkids.get(key).skid.Id, key );
            }

            for ( SkidService3.ParameterData itWrapper : itData.values() ) {
                for ( Inventory_Transaction__c it : itWrapper.itList ) {
                    if( toSkidsMap.containsKey(it.From_Skid__c) ){
                        List<String> key = toSkidsMap.get(it.From_Skid__c);
                        it.From_Skid__r = toSkids.get(key).skid;
                    }
                }
            }

            for (List<String> itKey:keyMap.keySet()) {
                List<String> skidKey = keyMap.get(itKey);
                if (toSkids.containsKey(skidKey)) {
                    toSkids.put(itKey,toSkids.get(skidKey));
                }
            }



            SkidService3.inventoryTransactionsForPutaway(itData,attributes,toSkids,new Map<String,String>{ 'transferofowner' => 'true','consume' => 'true', 'adjustFromSkidQuantity'=> null });
        }

        if (allocatedSkidsForPutaway.size() > 0) {
            SkidService3.putAwayService(allocatedSkidsForPutaway,attributes,new Map<String,Boolean>{ SkidService3.DELETE_SKIDS => true });
        }

        if (mtsToUpdate.size() > 0) DML.updateAsUser(mtsToUpdate);
        if (wosToUpdate.size() > 0) {
            allowWorkOrderUpdate = true;
            DML.updateAsUser(wosToUpdate.values());
            allowWorkOrderUpdate = false;
        }
    }

    public static void kit(List<MaterialWrapper> mWrappers,Map<Id,Work_Order__c> workOrders,List<String> attributes) {
        List<SKID__c> wipSkids = new List<SKID__c>();
        Set<Id> uniqueLocations = new Set<Id>();
        for (MaterialWrapper mWrapper:mWrappers) {
            Work_Order__c wo = workOrders.get(mWrapper.material.Work_Order__c);
            uniqueLocations.add(wo.Default_WIP_Location__c);
            for (SKID__c skid:mWrapper.skids) {
                if (skid.Quantity_To_Issue__c > 0) {
                    SKID__c wipSkid = skid.clone(false,true);
                    wipSkid.Type__c = SkidService2.SKID_TYPE_WIP;
                    wipSkid.Quantity__c = wipSkid.Quantity_To_Issue__c;
                    wipSkid.Quantity_To_Issue__c = 0;
                    wipSkid.Location__c = wo.Default_WIP_Location__c;
                    wipSkid.Material_Tracking__c = mWrapper.material.Id;
                    wipSkids.add(wipSkid);
                }
            }
        }
        List<String> tempAttributes = attributes.clone();
        tempAttributes.add('Material_Tracking__c');
        Map<String,SKID__c> toSkids = SkidService2.putAwayService(wipSkids,tempAttributes,uniqueLocations,SkidService2.SKID_TYPE_WIP,true);

        List<Material_Tracking__c> materials = new List<Material_Tracking__c>();
        Map<Id,List<SKID__c>> quantitySkidsByHeader = new Map<Id,List<SKID__c>>();
        Map<String,SKID__c> fromToSkidMap = new Map<String,SKID__c>();
        Map<Id,String> icTypes = new Map<Id,String>();
        Map<Id,Work_Order__c> workOrdersToUpdate = new Map<Id,Work_Order__c>();
        for (MaterialWrapper mWrapper:mWrappers) {
            Work_Order__c wo = workOrders.get(mWrapper.material.Work_Order__c);
            materials.add(mWrapper.material);
            quantitySkidsByHeader.put(mWrapper.material.Id,mWrapper.skids);
            icTypes.put(wo.Id,'Work Order Kit');
            if (wo.Status__c != 'Complete')
                workOrdersToUpdate.put(wo.Id,new Work_Order__c(Id=wo.Id,Status__c = 'In Process'));
            for (SKID__c skid:mWrapper.skids) {
                if (skid.Quantity_To_Issue__c > 0) {
                    SKID__c wipSkid = skid.clone(false,true);
                    wipSkid.Location__c = wo.Default_WIP_Location__c;
                    wipSkid.Material_Tracking__c = mWrapper.material.Id;
                    fromToSkidMap.put(SkidService2.generateKeyForSkid(skid,attributes,null,null) + ',' + mWrapper.material.Id,toSkids.get(SkidService2.generateKeyForSkid(wipSkid,tempAttributes,null,null)));
                }
            }
        }
        SkidService2.inventoryTransactionForPullFrom(materials,quantitySkidsByHeader,'Work Order Component Issue',attributes,'Kit','Quantity_To_Issue__c',fromToSkidMap,false,null,null,icTypes,null);
        allowWorkOrderUpdate = true;
        DML.updateAsUser(workOrdersToUpdate.values());
        allowWorkOrderUpdate = false;
    }


    /*
     *  DEKIT SECTION
     */
    public static void dekit(List<MaterialWrapper> mWrappers,List<String> attributes) {
        Set<Id> materialIds = new Set<Id>();
        for (WorkOrderService.MaterialWrapper mWrapper:mWrappers) {
            for (SKID__c skid:mWrapper.skids) {
                if (skid.Quantity__c > 0) {
                    materialIds.add(mWrapper.material.Id);
                }
            }
        }

        List<String> wipAttributes = attributes.clone();
        wipAttributes.add('Material_Tracking__c');

        List<String> ibAttributes = attributes.clone();
        ibAttributes.add('Customer__c');

        Set<String> skidFields = new Set<String>{ 'Id','Name' };
        skidFields.addAll(util.getAllCustomFieldsFromObject(null,'SKID__c'));
        List<SKID__c> wipSkidsList = (List<SKID__c>)Database.query(util.generateQueryFromFieldSet('SKID__c',new Set<String>(),skidFields,' Type__c = \'WIP\' AND Material_Tracking__c IN :materialIds '));
        Map<String,SKID__c> wipSkidsMap = new Map<String,SKID__c>();
        for (SKID__c wipSkid:wipSkidsList)
            wipSkidsMap.put(SkidService2.generateKeyForSkid(wipSkid,wipAttributes,null,null),wipSkid);

        List<SKID__c> locationSkidsForPutaway = new List<SKID__c>();
        List<SKID__c> wipSkidsForPutaway = new List<SKID__c>();
        List<SKID__c> ibSkidsForPutaway = new List<SKID__c>();
        Set<Id> uniqueLocations = new Set<Id>();
        for (WorkOrderService.MaterialWrapper mWrapper:mWrappers) {
            for (SKID__c skid:mWrapper.skids) {
                if (skid.Quantity__c == null || skid.Quantity__c <= 0)
                    continue;

                if (skid.Location__c != null) {
                    uniqueLocations.add(skid.Location__c);
                }

                if (skid.Type__c == 'Location') {
                    locationSkidsForPutaway.add(skid);
                } else if (skid.Type__c == 'Install Base') {
                    ibSkidsForPutaway.add(skid);
                }

                SKID__c wipSkid = skid.clone(false,true);
                wipSkid.Location__c = mWrapper.material.Work_Order__r.Default_WIP_Location__c;
                wipSkid.Material_Tracking__c = mWrapper.material.Id;
                if (!wipSkidsMap.containsKey(SkidService2.generateKeyForSkid(wipSkid,wipAttributes,null,null))) {
                    wipSkid.Quantity__c = 0;
                    wipSkid.Type__c = SkidService2.SKID_TYPE_WIP;
                    wipSkidsForPutaway.add(wipSkid);
                }
            }
        }
        Map<String,SKID__c> toSkidsMap = SkidService2.putAwayService(locationSkidsForPutaway,attributes,uniqueLocations,'Location',false);
        Map<String,SKID__c> wipToSkidsMap = SkidService2.putAwayService(wipSkidsForPutaway,wipAttributes,uniqueLocations,'WIP',false);
        Map<String,SKID__c> ibToSkidsMap = SkidService2.putAwayService(ibSkidsForPutaway,ibAttributes,null,'Install Base',false);

        List<Material_Tracking__c> materialsToUpdate = new List<Material_Tracking__c>();
        Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
        Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
        Map<Id,String> icTypes = new Map<Id,String>();
        for (WorkOrderService.MaterialWrapper mWrapper:mWrappers) {
            for (SKID__c skid:mWrapper.skids) {
                if (skid.Quantity__c == null || skid.Quantity__c <= 0)
                    continue;

                SKID__c toSkid = toSkidsMap.get(SkidService2.generateKeyForSkid(skid,attributes,null,null));
                if (toSkid == null) {
                    toSkid = ibToSkidsMap.get(SkidService2.generateKeyForSkid(skid,ibAttributes,null,null));
                }

                SKID__c fromSkid = toSkid.clone(false,true);
                fromSkid.Location__c = mWrapper.material.Work_Order__r.Default_WIP_Location__c;
                fromSkid.Material_Tracking__c = mWrapper.material.Id;
                String fromSkidKey = SkidService2.generateKeyForSkid(fromSkid,wipAttributes,null,null);
                if (wipSkidsMap.containsKey(fromSkidKey))
                    fromSkid = wipSkidsMap.get(fromSkidKey);
                else
                    fromSkid = wipToSkidsMap.get(fromSkidKey);

                String itType = 'Work Order Component Return';
                if (mWrapper.material.Type__c == MATERIAL_TYPE_REPAIR) {
                    itType = 'Work Order Repair Component Return';
                }

                //Inventory_Transaction__c it = SkidService2.createIT(fromSkid,skid.Item__c,itType,null,null,null,skid.Location__c,toSkid,attributes);
                Inventory_Transaction__c it = SkidService3.createInventoryTransaction(mWrapper.material,itType,skid.Quantity__c,fromSkid,toSkid,attributes);
                it.Customer__c = fromSkid.Customer__c;

                if (!sourceDocs.containsKey(mWrapper.material.Work_Order__c))
                    sourceDocs.put(mWrapper.material.Work_Order__c,new Work_Order__c(Company__c = mWrapper.material.Work_Order__r.Company__c));
                if (!itMap.containsKey(mWrapper.material.Work_Order__c))
                    itMap.put(mWrapper.material.Work_Order__c,new List<Inventory_Transaction__c>());
                itMap.get(mWrapper.material.Work_Order__c).add(it);
                if (!icTypes.containsKey(mWrapper.material.Work_Order__c))
                    icTypes.put(mWrapper.material.Work_Order__c,'Work Order DeKit');
                mWrapper.material.Quantity_Issued__c -= it.Quantity__c;
            }
            materialsToUpdate.add(mWrapper.material);
        }

        DML.updateAsUser(materialsToUpdate);
        SkidService2.inventoryTransactionsForPutaway(sourceDocs,itMap,icTypes,null,attributes,toSkidsMap,null,null);    //will not find IB skid, but that's okay since it was put on the IT in createIT
    }

    public static void dekitV2(Map<Id,Work_Order__c> woMap,Map<Id,List<WorkOrderWrapper>> wowMap) {
        if (woMap == null || woMap.size() == 0) {
            return;
        }

        checkDekitErrors(woMap,wowMap);

        List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        List<SkidService3.SerialWrapper> allocatedSkidsForPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> itData = new Map<Id,SkidService3.ParameterData>();
        Map<List<String>,List<String>> keyMap = new Map<List<String>,List<String>>();

        Map<Id,Material_Tracking__c> materialsToUpdate = new Map<Id,Material_Tracking__c>();

        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Material_Tracking__c');
        attributes.add('Customer__c');
        attributes.add('Receipt_Line__c');

        Id companyId;
        Map<Id,Item__c> items = new Map<Id,Item__c>();
        Map<Id, List<Shipment_Line__c>> shipmentLines = new Map<Id, List<Shipment_Line__c>>();
        Set<Id> repairWOIds = new Set<Id>();
        for (Id woId:woMap.keySet()) {
            companyId = woMap.get(woId).Company__c;

            if (wowMap.containsKey(woId)) {
                for (WorkOrderWrapper wow:wowMap.get(woId)) {
                    Material_Tracking__c material = wow.material;
                    items.put(material.Item__c,material.Item__r);
                    if(material.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c == null && material.Work_Order__r.Receipt_Line__c == null){
	                	repairWOIds.add(material.Work_Order__c);
	            	}
                }
            }
        }

        if(repairWOIds.size()>0)
        	shipmentLines = getShipmentLinesForWorkOrders(repairWOIds, 'Sales_Order_Line__r.Required_Date__c, Sales_Order_Line__r.CreatedDate ASC');
        
		Set<Id> relatedSOlineIds = new Set<Id>();
        Map<Id,Shipment_Line__c> shlineWOmap = new Map<Id,Shipment_Line__c>();
        Map<Id,Id> rmaSOLinemap = new Map<Id,Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        for(Id woId:shipmentLines.keyset()){
        	if(shipmentLines.containsKey(woId)) {
        		for (Shipment_Line__c shline:shipmentLines.get(woId)) {
        			salesOrderIds.add(shline.Sales_Order_Line__r.Sales_Order__c);
	        		relatedSOlineIds.add(shline.Sales_Order_Line__r.Related_Sales_Order_Line__c);//Get Related SOL and Query with that to get non repair line.
	        		if(!shlineWOmap.containskey(shline.Work_Order__c))
            			shlineWOmap.put(shline.Work_Order__c,shline);
	        	}
        	}
        }
        
    	SOQLUtil solineQuery = new SOQLUtil('Sales_Order_Line__c',false);
        solineQuery.addFields(new Set<String>{ 'Id','Status__c','Related_Sales_Order_Line__c', 'Product__r.Item__r.Packaging_UOM__c' });
        solineQuery.setWhereClause('Sales_Order__c in :salesOrderIds and Related_Sales_Order_Line__c in :relatedSOlineIds and (Type__c != \'Repair\')');	

        for(Sales_Order_Line__c rmaSOL : Database.query(solineQuery.getQuery())){
    	  if(!rmaSOLinemap.containskey(rmaSOL.Related_Sales_Order_Line__c)){
    	  	rmaSOLinemap.put(rmaSOL.Related_Sales_Order_Line__c,rmaSOL.Id);
    	  }
        }
        
        Map<Id,List<String>> skidAttributes = AllocationService.getSkidAttributes(companyId,items);

        for (Id woId:woMap.keySet()) {
            if (wowMap.containsKey(woId)) {
                Work_Order__c wo = woMap.get(woId);

                SkidService3.ParameterData itInfo = itData.get(woId);
                if (itInfo == null) {
                    itInfo = new SkidService3.ParameterData();
                    itInfo.sourceDoc = new Work_Order__c(Company__c = wo.Company__c);
                    itInfo.icType = 'Work Order DeKit';
                }

                for (WorkOrderWrapper wow:wowMap.get(woId)) {
                    Material_Tracking__c material = wow.material;

                    if (!materialsToUpdate.containsKey(material.Id)) materialsToUpdate.put(material.Id,newMaterialTracking(material));
                    Material_Tracking__c materialToUpdate = materialsToUpdate.get(material.Id);

                    for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                        SKID__c wipSkid = sw.skid.clone(true,true);
                        wipSkid.Location__c = wo.Default_WIP_Location__c;
                        wipSkid.Location__r = wo.Default_WIP_Location__r;
                        wipSkid.Bin__c = null;
                        wipSkid.Bin__r = null;

                        sw.skid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                        sw.skid.Material_Tracking__c = null;

                        List<Serial__c> serialsToDekit = new List<Serial__c>();
                        List<Serial__c> serialsToScrap = new List<Serial__c>();
                        for (Serial__c serial:sw.serialList) {
                            String tempVal = serial.Temporary_Value_Holder__c;
                            serial.Temporary_Value_Holder__c = null;
                            if (tempVal == 'Dekit') {
                                serialsToDekit.add(serial);
                            } else if (tempVal == 'Scrap') {
                                serialsToScrap.add(serial);
                            }
                        }

                        Skid__c negativeWIPSkid =  wipSkid.clone(false,true);
                        negativeWIPSkid.Quantity__c = 0;
                        if (sw.skid.Quantity_to_Issue__c > 0) {
                            SKID__c skid = sw.skid.clone(false,true);
                            skid.Quantity__c = sw.skid.Quantity_to_Issue__c;
                            negativeWIPSkid.Quantity__c = KSE.subtractDecimals(negativeWIPSkid.Quantity__c, sw.skid.Quantity_to_Issue__c);

                            if (material.Type__c == MATERIAL_TYPE_REPAIR) {
                                if (material.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c != null) {
                                    skid.Receipt_Line__c = material.Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c;
                                } else if (material.Work_Order__r.Receipt_Line__c != null) {
                                    skid.Receipt_Line__c = material.Work_Order__r.Receipt_Line__c;
                                }
                                else if(shlineWOmap.containskey(material.Work_Order__c) && shlineWOmap.get(material.Work_Order__c).Sales_Order_Line__c !=null && material.Work_Order__r.Receipt_Line__c ==null && shlineWOmap.get(material.Work_Order__c).Sales_Order_Line__r.Type__c == 'Repair'){
                                	if(rmaSOLinemap.containskey(shlineWOmap.get(material.Work_Order__c).Sales_Order_Line__r.Related_Sales_Order_Line__c)){
				                		skid.Sales_Order_Line__c = rmaSOLinemap.get(shlineWOmap.get(material.Work_Order__c).Sales_Order_Line__r.Related_Sales_Order_Line__c);
				                	}
                                	
                                }

                                if (material.Work_Order__r.Field_Service__c) {
                                    skid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
                                }
                            }

                            skidsForPutaway.add(new SkidService3.SerialWrapper(skid,serialsToDekit));

                            String itType = 'Work Order Component Return';
                            if (material.Type__c == MATERIAL_TYPE_REPAIR) {
                                itType = 'Work Order Repair Component Return';
                            }

                            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(material,itType,skid.Quantity__c,wipSkid,skid,attributes);
                            it.Item__r = sw.skid.Item__r;
                            itInfo.itList.add(it);
                            keyMap.put(SkidService3.generateKey(it,attributes),SkidService3.generateKey(skid,attributes));

                            materialToUpdate.Quantity_Issued__c = KSE.subtractDecimals(materialToUpdate.Quantity_Issued__c,skid.Quantity__c).setScale(6, System.RoundingMode.HALF_UP);

                            if (material.Allocation_Required__c) {
                                SKID__c allocatedSkid = new SKID__c(
                                    Company__c = wo.Company__c,
                                    Facility2__c = wo.Facility__c,
                                    Item__c = material.Item__c,
                                    Quantity__c = skid.Quantity__c,
                                    Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                                    Material_Tracking__c = material.Id
                                );
                                for (String attr:skidAttributes.get(material.Item__c)) {
                                    allocatedSkid.put(attr,skid.get(attr));
                                }

                                allocatedSkidsForPutaway.add(new SkidService3.SerialWrapper(allocatedSkid,new List<Serial__c>()));

                                materialToUpdate.Quantity_Allocated__c = KSE.addQuantityToField(materialToUpdate.Quantity_Allocated__c,skid.Quantity__c).setScale(6, System.RoundingMode.HALF_UP);
                            }
                        }

                        if (sw.skid.Quantity_to_Scrap__c > 0) {
                            SKID__c scrapSkid = sw.skid.clone(false,true);
                            scrapSkid.Quantity__c = sw.skid.Quantity_to_Scrap__c;
                            scrapSkid.Receipt_Line__c = null;
                            negativeWIPSkid.Quantity__c = KSE.subtractDecimals(negativeWIPSkid.Quantity__c, sw.skid.Quantity_to_Scrap__c);

                            List<String> scrapInfo = sw.skid.Temporary_Value_Holder1__c.split(',');
                            scrapSkid.Location__c = scrapInfo[0];
                            if (scrapInfo.size() > 1 && scrapInfo[1] != null && scrapInfo[1] != 'null' && scrapInfo[1] != 'undefined') scrapSkid.Bin__c = scrapInfo[1];

                            skidsForPutaway.add(new SkidService3.SerialWrapper(scrapSkid,serialsToScrap));

                            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(material, material.Type__c == MATERIAL_TYPE_REPAIR ? 'Work Order Repair Component Scrap' : 'Work Order Component Scrap',scrapSkid.Quantity__c,wipSkid,scrapSkid,attributes);
                            it.Item__r = sw.skid.Item__r;
                            itInfo.itList.add(it);
                            keyMap.put(SkidService3.generateKey(it,attributes),SkidService3.generateKey(scrapSkid,attributes));

                            materialToUpdate.Quantity_Scrapped__c = KSE.addQuantityToField(materialToUpdate.Quantity_Scrapped__c,scrapSkid.Quantity__c).setScale(6, System.RoundingMode.HALF_UP);
                        }

                        if ( negativeWIPSkid.Quantity__c < 0 ) {
                            skidsForPutaway.add(new SkidService3.SerialWrapper (negativeWIPSkid, null));
                        }

                    }
                }

                if (itInfo.itList.size() > 0) {
                    itData.put(woId,itInfo);
                }
            }
        }

        Map<List<String>,SkidService3.SerialWrapper> toSkids = SkidService3.putAwayService(skidsForPutaway,attributes,null);
        Map<Id, List<String>> toSkidsMap = new Map<Id, List<String>>();
        for ( List<String> key : toSkids.keySet() ) {
            toSkidsMap.put(toSkids.get(key).skid.Id, key );
        }

        for ( SkidService3.ParameterData itWrapper : itData.values() ) {
            for ( Inventory_Transaction__c it : itWrapper.itList ) {
                if( toSkidsMap.containsKey(it.From_Skid__c) ){
                    List<String> key = toSkidsMap.get(it.From_Skid__c);
                    it.From_Skid__r = toSkids.get(key).skid;
                }
            }
        }

        for (List<String> itKey:keyMap.keySet()) {
            toSkids.put(itKey,toSkids.get(keyMap.get(itKey)));
        }
        SkidService3.inventoryTransactionsForPutaway(itData,attributes,toSkids, new Map<String,String>{'adjustFromSkidQuantity'=> null});

        if (allocatedSkidsForPutaway.size() > 0) {
            SkidService3.putAwayService(allocatedSkidsForPutaway,attributes,null);
        }

        DML.updateAsUser(materialsToUpdate.values());

        Set<Id> woIds = woMap.keySet();
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addFields(new Set<String>{ 'Id','Name','Quantity_Complete__c' });
        woQuery.setWhereClause('Id IN :woIds');

        SOQLUtil.ChildRelationship mtQuery = new SOQLUtil.ChildRelationship(woQuery,'Material_Trackings__r');
        mtQuery.addFields(new Set<String>{ 'Id','Name','Quantity_Completed__c','Quantity_Issued__c','Quantity_Allocated__c' });
        woQuery.addChildRelationship(mtQuery);

        List<Work_Order__c> workOrdersToUpdate = new List<Work_Order__c>();
        for (Work_Order__c wo:Database.query(woQuery.getQuery())) {
            if (wo.Quantity_Complete__c == null || wo.Quantity_Complete__c == 0) {
                Boolean qtyFound = false;

                for (Material_Tracking__c mt:wo.Material_Trackings__r) {
                    if (mt.Quantity_Allocated__c > 0 || mt.Quantity_Issued__c > 0 || mt.Quantity_Completed__c > 0) {
                        qtyFound = true;
                        break;
                    }
                }

                if (!qtyFound) {
                    wo.Status__c = WO_STATUS_RELEASED;
                    workOrdersToUpdate.add(wo);
                }
            }
        }

        if (workOrdersToUpdate.size() > 0) {
            allowWorkOrderUpdate = true;
            DML.updateAsUser(workOrdersToUpdate);
            allowWorkOrderUpdate = false;
        }
    }


    /*
     *  COMPLETE SECTION
     */
    public static Map<Id,String> validateForComplete(Map<Id,Work_Order__c> workOrders,Boolean fromAutoComplete) {
        Map<Id,String> errors = new Map<Id,String>();

        Set<Id> subcontract = new Set<Id>();
        if (!fromAutoComplete) {
            Set<Id> opIds = workOrders.keySet();
            SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
            polQuery.addFields(new Set<String>{ 'Id','Operation_Tracking__c' });
            polQuery.setWhereClause('Operation_Tracking__c IN :opIds');
            for (Purchase_Order_Line__c pol:Database.query(polQuery.getQuery())) {
                subcontract.add(pol.Operation_Tracking__c);
            }
        }

        for (Id opId:workOrders.keySet()) {
            Work_Order__c wo = workOrders.get(opId);
            if (wo.Status__c == WO_STATUS_DRAFT) {
                errors.put(wo.Id,wo.Name + ': ' + Label.WorkOrder_not_released);
            } else if (wo.Status__c  == WO_STATUS_CLOSED && (wo.Completed__c == 0 || wo.Completed__c == null)) {
                errors.put(wo.Id,wo.Name + ': ' + Label.WorkOrder_already_closed);
            } else if (wo.Status__c  == WO_STATUS_CANCELLED) {
                errors.put(wo.Id,wo.Name + ': ' + Label.WorkOrder_cancelled);
            } else if (wo.Complete_to_Location__c == null) {
                errors.put(wo.Id,wo.Name + ': ' + Label.Complete_to_Location_not_present);
            } else if (wo.Default_WIP_Location__c == null) {
                errors.put(wo.Id,wo.Name + ': ' + Label.WIP_location_should_be_specified);
            } else if (wo.MRB_Location__c == null) {
                errors.put(wo.Id,wo.Name + ': ' + Label.Scrap_Location_not_present);
            } else if (!fromAutoComplete && subcontract.contains(opId)) {
                errors.put(wo.Id,wo.Name + ': This operation is subcontracted. Please receive against the associated purchase order.');
            }
        }

        return errors;
    }

    public static Map<Id, List<SkidService3.SerialWrapper>> getCompleteAssemblyData(List<CompleteWrapper> wrappers) {
        List<String> attributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'location__c', 'bin__c' });
        attributes.add('Customer__c');
        attributes.add('Sales_Order_Line__c');

        Map<Id, CompleteWrapper> wrapperMap = new Map<Id, CompleteWrapper>();
        Set<Id> woIds = new Set<Id>();
        Set<Id> opIds = new Set<Id>();
        Set<Id> lastWoIds = new Set<Id>();
        Set<Id> completedWoIds = new Set<Id>();
        Set<Id> repairWoIds = new Set<Id>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        for (CompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;
            Boolean last = wrapper.lastOp;

            wrapperMap.put(wo.Id, wrapper);
            woIds.add(wo.Id);
            opIds.add(op.Id);
            if (last == true) lastWoIds.add(wo.Id);
            if (wo.Quantity_Complete_Stocking_UOM__c > 0) completedWoIds.add(wo.Id);
            if (wo.Type__c == WO_TYPE_REPAIR && (last == false || wo.Number_of_Operations__c == 1)) repairWoIds.add(wo.Id);

            if (packagingUoms.containsKey(wo.Item__c) == false) packagingUoms.put(wo.Item__c, (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class));
        }

        Map<Id, SkidService3.SerialWrapper> wipSkids = new Map<Id, SkidService3.SerialWrapper>();
        Map<Id, Map<List<String>, SkidService3.SerialWrapper>> assemblyWipSkidMap = new Map<Id, Map<List<String>, SkidService3.SerialWrapper>>();
        Map<Id, Map<List<String>, SkidService3.SerialWrapper>> repairMaterialMap = new Map<Id, Map<List<String>, SkidService3.SerialWrapper>>();
        String whereClause = 'Type__c = \'' + SkidService3.SKID_TYPE_WIP + '\' AND (Work_Order__c IN :woIds OR (Material_Tracking__r.Type__c = :MATERIAL_TYPE_REPAIR AND Material_Tracking__r.Work_Order__c IN :repairWoIds))';
        for (SKID__c wipSkid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause }))) {
            Work_Order__c wo = wrapperMap.get(wipSkid.Work_Order__c != null ? wipSkid.Work_Order__c : wipSkid.Material_Tracking__r.Work_Order__c).wo;
            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(wipSkid);

            wipSkids.put(wipSkid.Id, sw);

            List<String> skidKey = SkidService3.generateKey(wipSkid, attributes);
            if (wipSkid.Work_Order__c != null) {
                if (assemblyWipSkidMap.containsKey(wo.Id) == false) assemblyWipSkidMap.put(wo.Id, new Map<List<String>, SkidService3.SerialWrapper>{ skidKey => sw });
                else if (assemblyWipSkidMap.get(wo.Id).containsKey(skidKey) == false) assemblyWipSkidMap.get(wo.Id).put(skidKey, sw);
                else assemblyWipSkidMap.get(wo.Id).get(skidKey).skid.Quantity__c += sw.skid.Quantity__c;
            } else {
                if (repairMaterialMap.containsKey(wo.Id) == false) repairMaterialMap.put(wo.Id, new Map<List<String>, SkidService3.SerialWrapper>{ skidKey => sw });
                else if (repairMaterialMap.get(wo.Id).containsKey(skidKey) == false) repairMaterialMap.get(wo.Id).put(skidKey, sw);
                else repairMaterialMap.get(wo.Id).get(skidKey).skid.Quantity__c += sw.skid.Quantity__c;
            }
        }

        if (wipSkids.size() > 0) {
            Set<Id> skidIds = wipSkids.keySet();
            for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => 'SKID__c IN :skidIds', 'ORDER' => 'Name ASC' }))) {
                SkidService3.SerialWrapper sw = wipSkids.get(serial.SKID__c);
                if (sw.skid.Material_Tracking__c != null) serial.Temporary_Value_Holder__c = 'Material';
                sw.serialList.add(serial);
            }
        }

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addFields(new Set<String>{ 'Bin__r.Blocked__c', 'Bin__r.Location__c', 'Bin__r.Max_Capacity__c', 'Bin__r.Packaging_UOM__c',
            'Bin__r.Packaging_UOM__r.Package_Class__c',

            'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',

            'Facility__r.Facility_Identifier__c',

            'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c',

            'Location__r.Bin_Tracked__c', 'Location__r.Facility__c', 'Location__r.Mixed_Bins_Allowed__c', 'Location__r.Track_Bin_Capacity__c',

            'Lot__r.Lot_Hold__c',

            'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c', 'Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c',
            'Packaging_UOM__r.Package_Class__r.Level__c' });
        otQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Container_Item__r.Item_Attribute__r');
        otQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        otQuery.setWhereClause('(Quantity_Completed__c != 0 OR Quantity_Scrapped__c != 0) AND (Operation_Tracking__c IN :opIds OR Work_Order__c IN :lastWoIds)');
        otQuery.setOrderByClause('CreatedDate ASC');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Serial__c', 'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Item__c', 'Serial__r.SKID__c',
            'Serial__r.Status__c', 'Serial__r.Temporary_Value_Holder__c' });
        for (String attr:SkidService3.serialAttributes) stQuery.addField('Serial__r.' + attr);
        for (String fld:SchemaUtil.getInstance().getFieldsFromFieldSetString(Serial__c.sObjectType, 'Serial')) stQuery.addField('Serial__r.' + fld);
        otQuery.addChildRelationship(stQuery);

        Map<Id, Map<List<String>, Map<Id, SkidService3.SerialWrapper>>> qtyCompletedMap = new Map<Id, Map<List<String>, Map<Id, SkidService3.SerialWrapper>>>();
        for (Operation_Transaction__c ot:Database.query(otQuery.getQuery())) {
            Work_Order__c wo = wrapperMap.get(ot.Work_Order__c).wo;
            Id opId = ot.Operation_Tracking__c;

            SKID__c skid = SkidService3.generateOtSkid(ot, attributes);
            skid.Quantity__c = ot.Quantity_Completed__c;
            skid.Quantity_Scrapped__c = ot.Quantity_Scrapped__c;

            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid);
            for (Serial_Transaction__c st:ot.Serial_Transactions__r) {
                st.Serial__r.Temporary_Value_Holder__c = 'Completed';
                sw.serialList.add(st.Serial__r);
            }

            List<String> key = SkidService3.generateKey(skid, attributes);
            if (qtyCompletedMap.containsKey(wo.Id) == false) {
                qtyCompletedMap.put(wo.Id, new Map<List<String>, Map<Id, SkidService3.SerialWrapper>>{ key => new Map<Id, SkidService3.SerialWrapper>{ opId => sw }});
            } else if (qtyCompletedMap.get(wo.Id).containsKey(key) == false) {
                qtyCompletedMap.get(wo.Id).put(key, new Map<Id, SkidService3.SerialWrapper>{ opId => sw });
            } else if (qtyCompletedMap.get(wo.Id).get(key).containsKey(opId) == false) {
                qtyCompletedMap.get(wo.Id).get(key).put(opId, sw);
            } else {
                SkidService3.SerialWrapper sw2 = qtyCompletedMap.get(wo.Id).get(key).get(opId);
                sw2.skid.Quantity__c += sw.skid.Quantity__c;
                sw2.skid.Quantity_Scrapped__c += sw.skid.Quantity_Scrapped__c;

                if (sw.serialList.size() > 0) {
                    if (sw.skid.Quantity__c > 0) {
                        sw2.serialList.addAll(sw.serialList);
                    } else {
                        Map<Id, Serial__c> serials = new Map<Id, Serial__c>(sw2.serialList);
                        for (Serial__c serial:sw.serialList) serials.remove(serial.Id);
                        sw2.serialList = serials.values();
                    }
                }

                if (sw2.skid.Quantity__c == 0 && sw2.skid.Quantity_Scrapped__c == 0) {
                    qtyCompletedMap.get(wo.Id).get(key).remove(opId);
                    if (qtyCompletedMap.get(wo.Id).get(key).size() == 0) qtyCompletedMap.get(wo.Id).remove(key);
                    if (qtyCompletedMap.get(wo.Id).size() == 0) qtyCompletedMap.remove(wo.Id);
                }
            }
        }

        Map<Id, Map<List<String>, SKID__c>> finishedSkidMap = new Map<Id, Map<List<String>, SKID__c>>();
        whereClause = '(Type__c IN (\'Work Order Assembly Completion\', \'Work Order Repair Assembly Completion\', \'Work Order Assembly Uncompletion\', \'Work Order Repair Assembly Uncompletion\') AND Inventory_Change__r.Work_Order__c IN :completedWoIds) OR (Type__c IN (\'Work Order Assembly Scrap\', \'Work Order Repair Assembly Scrap\') AND Inventory_Change__r.Work_Order__c IN :woIds)';
        for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'CreatedDate ASC' }))) {
            CompleteWrapper wrapper = wrapperMap.get(it.Inventory_Change__r.Work_Order__c);
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;

            if ((it.Type__c == 'Work Order Assembly Scrap' || it.Type__c == 'Work Order Repair Assembly Scrap') && it.Operation_Tracking__r.Sequence__c <= op.Sequence__c) continue;

            SKID__c skid = SkidService3.generateFromSkid(it, attributes);
            if (it.Type__c == 'Work Order Assembly Completion' || it.Type__c == 'Work Order Repair Assembly Completion') skid.Temporary_Value_Holder__c = it.From_SKID_Identifier__c;   //Used to preserve geneaology when mapping to assemblies that already went out into FG
            Decimal qty = it.Net_Quantity__c / KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, it.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, packagingUoms.get(wo.Item__c));
            if (it.Type__c == 'Work Order Assembly Scrap' || it.Type__c == 'Work Order Repair Assembly Scrap') {
                skid.Quantity__c = 0;
                skid.Quantity_Scrapped__c = qty;
            } else {
                skid.Quantity__c = qty;
                skid.Quantity_Scrapped__c = 0;
            }

            List<String> skidKey = SkidService3.generateKey(skid, attributes);
            if (finishedSkidMap.containsKey(wo.Id) == false) {
                finishedSkidMap.put(wo.Id, new Map<List<String>, SKID__c>{ skidKey => skid });
            } else if (finishedSkidMap.get(wo.Id).containsKey(skidKey) == false) {
                finishedSkidMap.get(wo.Id).put(skidKey, skid);
            } else {
                SKID__c finishedSk = finishedSkidMap.get(wo.Id).get(skidKey);
                finishedSk.Quantity__c += skid.Quantity__c;
                finishedSk.Quantity_Scrapped__c += skid.Quantity_Scrapped__c;

                if (finishedSk.Quantity__c == 0 && finishedSk.Quantity_Scrapped__c == 0) {
                    finishedSkidMap.get(wo.Id).remove(skidKey);
                    if (finishedSkidMap.get(wo.Id).size() == 0) finishedSkidMap.remove(wo.Id);
                }
            }
        }

        /*
         * Quantity Fields
         *
         * Quantity Issued = Quantity in WIP
         * Quantity Short = Quantity Completed for Operation
         * Total Material = Quantity Scrapped for Operation
         * Quantity Allocated = Quantity from Repair Material
         * Quantity Required = Quantity Completed for Work Order
         * Quantity Available = Quantity Available for Completion (Repair and Last Operation Only)
         * Quantity Used = Quantity to Complete (input)
         * Quantity Scrapped = Quantity to Scrap (input)
         * Input Quantity = Hours Consumed (input)
         */
        Map<Id, List<SkidService3.SerialWrapper>> swMap = new Map<Id, List<SkidService3.SerialWrapper>>();
        for (CompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;
            Boolean last = wrapper.lastOp;
            List<Id> pkgUoms = packagingUoms.get(wo.Item__c);
            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();

            Map<List<String>, SkidService3.SerialWrapper> assemblyWipSkids = assemblyWipSkidMap.containsKey(wo.Id) == true ? assemblyWipSkidMap.get(wo.Id) : new Map<List<String>, SkidService3.SerialWrapper>();
            Map<List<String>, Map<Id, SkidService3.SerialWrapper>> qtyCompletedWo = qtyCompletedMap.containsKey(wo.Id) == true ? qtyCompletedMap.get(wo.Id) : new Map<List<String>, Map<Id, SkidService3.SerialWrapper>>();
            Map<List<String>, SkidService3.SerialWrapper> repairMaterial = repairMaterialMap.containsKey(wo.Id) == true ? repairMaterialMap.get(wo.Id) : new Map<List<String>, SkidService3.SerialWrapper>();
            Map<List<String>, SKID__c> finishedSkids = finishedSkidMap.containsKey(wo.Id) == true ? finishedSkidMap.get(wo.Id) : new Map<List<String>, SKID__c>();

            Map<List<String>, SkidService3.SerialWrapper> qtyCompleted = new Map<List<String>, SkidService3.SerialWrapper>();
            for (List<String> key:qtyCompletedWo.keySet()) {
                if (qtyCompletedWo.get(key).containsKey(op.Id)) qtyCompleted.put(key, qtyCompletedWo.get(key).get(op.Id));
            }

            Boolean populated = false;
            for (List<String> skidKey:assemblyWipSkids.keySet()) {
                SkidService3.SerialWrapper sw =  new SkidService3.SerialWrapper(assemblyWipSkids.get(skidKey));
                sw.skid.Quantity_Issued__c = sw.skid.Quantity__c;

                Map<Id, Serial__c> serialsCompleted = new Map<Id, Serial__c>();
                if (qtyCompleted.containsKey(skidKey) == true) {
                    SkidService3.SerialWrapper completedSw = qtyCompleted.get(skidKey);
                    sw.skid.Quantity_Short__c = completedSw.skid.Quantity__c;
                    sw.skid.Total_Material__c = completedSw.skid.Quantity_Scrapped__c;
                    qtyCompleted.remove(skidKey);

                    if (completedSw.serialList.size() > 0) {
                        serialsCompleted = new Map<Id, Serial__c>(completedSw.serialList);
                        for (Integer i = 0; i < sw.serialList.size(); i++) {
                            if (serialsCompleted.containsKey(sw.serialList[i].Id) == true) sw.serialList.remove(i--);
                        }
                    }
                } else {
                    sw.skid.Quantity_Short__c = 0;
                    sw.skid.Total_Material__c = 0;
                }

                if (repairMaterial.containsKey(skidKey) == true) {
                    SkidService3.SerialWrapper repairSw = repairMaterial.get(skidKey);
                    sw.skid.Quantity_Allocated__c = repairSw.skid.Quantity__c;
                    sw.serialList.addAll(repairSw.serialList);
                    repairMaterial.remove(skidKey);
                } else {
                    sw.skid.Quantity_Allocated__c = 0;
                }

                if (finishedSkids.containsKey(skidKey) == true) {
                    SKID__c finishedSkid = finishedSkids.get(skidKey);
                    sw.skid.Quantity_Required__c = finishedSkid.Quantity__c + finishedSkid.Quantity_Scrapped__c;
                } else {
                    sw.skid.Quantity_Required__c = 0;
                }

                Decimal convFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, pkgUoms);
                if (last == true && wo.Number_of_Operations__c > 1) {
                    if (qtyCompletedWo.get(skidKey).size() == wo.Number_of_Operations__c - 1 || qtyCompletedWo.get(skidKey).size() == wo.Number_of_Operations__c) {
                        sw.skid.Quantity_Available__c = sw.skid.Quantity_Issued__c;
                        for (Id opId:qtyCompletedWo.get(skidKey).keySet()) {
                            if (opId == op.Id) continue;

                            SkidService3.SerialWrapper completedSw = qtyCompletedWo.get(skidKey).get(opId);
                            if (completedSw.serialList.size() > 0) {
                                Set<Id> compSerials = (new Map<Id, Serial__c>(completedSw.serialList)).keySet();
                                for (Integer i = 0; i < sw.serialList.size(); i++) {
                                    Serial__c serial = sw.serialList[i];
                                    if (compSerials.contains(serial.Id) == false) sw.serialList.remove(i--);
                                }
                                sw.skid.Quantity_Available__c = sw.serialList.size() / convFactor;
                            } else {
                                sw.skid.Quantity_Available__c = Math.min(sw.skid.Quantity_Available__c, (completedSw.skid.Quantity__c - sw.skid.Quantity_Required__c));
                            }
                        }
                    } else {
                        sw.skid.Quantity_Available__c = 0;
                    }

                    if (sw.skid.Quantity_Available__c == 0 && sw.skid.Quantity_Required__c == 0) continue;
                } else if (wo.Type__c == WO_TYPE_REPAIR) {
                    sw.skid.Quantity_Available__c = sw.serialList.size() > 0 ? (sw.serialList.size() / convFactor) : (sw.skid.Quantity_Issued__c + sw.skid.Quantity_Required__c - sw.skid.Quantity_Short__c + sw.skid.Quantity_Allocated__c);
                }

                sw.serialList.addAll(serialsCompleted.values());

                if (populated == false) {
                    convFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, sw.skid.Packaging_UOM__c, pkgUoms);
                    sw.skid.Quantity_Used__c = sw.skid.Quantity_Available__c != null ? sw.skid.Quantity_Available__c : Math.max(op.Quantity_Available__c * convFactor, 0);
                    if (sw.skid.Quantity_Used__c > 0) {
                        if (op.Backflush_Resource__c == true) sw.skid.Input_Quantity__c = op.Standard_Hours__c * (op.Fixed_Hours__c == true ? 1 : (sw.skid.Quantity_Used__c / convFactor));
                        populated = true;
                    }
                }

                if (sw.skid.Quantity_Used__c == null) sw.skid.Quantity_Used__c = 0;
                sw.skid.Quantity_Scrapped__c = 0;
                if (sw.skid.Input_Quantity__c == null) sw.skid.Input_Quantity__c = 0;

                swList.add(sw);
            }

            for (List<String> skidKey:repairMaterial.keySet()) {
                SkidService3.SerialWrapper sw =  new SkidService3.SerialWrapper(repairMaterial.get(skidKey));
                sw.skid.Quantity_Issued__c = 0;
                sw.skid.Quantity_Allocated__c = sw.skid.Quantity__c;

                if (qtyCompleted.containsKey(skidKey) == true) {
                    SkidService3.SerialWrapper completedSw = qtyCompleted.get(skidKey);
                    sw.skid.Quantity_Short__c = completedSw.skid.Quantity__c;
                    sw.skid.Total_Material__c = completedSw.skid.Quantity_Scrapped__c;
                    sw.serialList.addAll(completedSw.serialList);
                    qtyCompleted.remove(skidKey);
                } else {
                    sw.skid.Quantity_Short__c = 0;
                    sw.skid.Total_Material__c = 0;
                }

                if (finishedSkids.containsKey(skidKey) == true) {
                    SKID__c finishedSkid = finishedSkids.get(skidKey);
                    sw.skid.Quantity_Required__c = finishedSkid.Quantity__c + finishedSkid.Quantity_Scrapped__c;
                    sw.skid.Temporary_Value_Holder__c = finishedSkid.Temporary_Value_Holder__c;
                } else {
                    sw.skid.Quantity_Required__c = 0;
                }

                sw.skid.Quantity_Available__c = sw.skid.Quantity_Allocated__c;

                if (populated == false) {
                    Decimal convFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, sw.skid.Packaging_UOM__c, pkgUoms);
                    sw.skid.Quantity_Used__c = sw.skid.Quantity_Available__c;
                    if (op.Backflush_Resource__c == true) sw.skid.Input_Quantity__c = op.Standard_Hours__c * (op.Fixed_Hours__c == true ? 1 : (sw.skid.Quantity_Used__c / convFactor));
                    populated = true;
                }

                if (sw.skid.Quantity_Used__c == null) sw.skid.Quantity_Used__c = 0;
                sw.skid.Quantity_Scrapped__c = 0;
                if (sw.skid.Input_Quantity__c == null) sw.skid.Input_Quantity__c = 0;

                swList.add(sw);
            }

            for (List<String> skidKey:qtyCompleted.keySet()) {
                SkidService3.SerialWrapper sw =  new SkidService3.SerialWrapper(qtyCompleted.get(skidKey));
                sw.skid.Quantity_Issued__c = 0;
                sw.skid.Quantity_Short__c = sw.skid.Quantity__c;
                sw.skid.Total_Material__c = sw.skid.Quantity_Scrapped__c;
                sw.skid.Quantity_Allocated__c = 0;

                if (finishedSkids.containsKey(skidKey) == true) {
                    SKID__c finishedSkid = finishedSkids.get(skidKey);
                    sw.skid.Quantity_Required__c = finishedSkid.Quantity__c + finishedSkid.Quantity_Scrapped__c;
                    sw.skid.Temporary_Value_Holder__c = finishedSkid.Temporary_Value_Holder__c;
                } else {
                    sw.skid.Quantity_Required__c = 0;
                }

                if ((last == true && wo.Number_of_Operations__c > 1) || wo.Type__c == WO_TYPE_REPAIR) {
                    sw.skid.Quantity_Available__c = 0;
                } else if (populated == false) {
                    Decimal convFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, sw.skid.Packaging_UOM__c, pkgUoms);
                    sw.skid.Quantity_Used__c = Math.max(op.Quantity_Available__c * convFactor, 0);
                    if (sw.skid.Quantity_Used__c > 0) {
                        if (op.Backflush_Resource__c == true) sw.skid.Input_Quantity__c = op.Standard_Hours__c * (op.Fixed_Hours__c == true ? 1 : (sw.skid.Quantity_Used__c / convFactor));
                        populated = true;
                    }
                }

                if (sw.skid.Quantity_Used__c == null) sw.skid.Quantity_Used__c = 0;
                sw.skid.Quantity_Scrapped__c = 0;
                if (sw.skid.Input_Quantity__c == null) sw.skid.Input_Quantity__c = 0;

                swList.add(sw);
            }

            swMap.put(op.Id, swList);
        }

        return swMap;
    }

    public static Map<Id, List<WorkOrderWrapper>> getCompleteBackflushData(List<CompleteWrapper> completeWrappers) {
        Map<Id, List<WorkOrderWrapper>> wrappers = new Map<Id, List<WorkOrderWrapper>>();
        if (completeWrappers == null || completeWrappers.size() == 0) return wrappers;

        String whereClause = ' AND (';
        for (Integer i = 0; i < completeWrappers.size(); i++) {
            CompleteWrapper wrapper = completeWrappers[i];
            if (i > 0) whereClause += ' OR ';
            whereClause += ' (Work_Order__c = \'' + wrapper.wo.Id + '\' AND ';

            if (wrapper.lastOp == false) whereClause += ' Operation_Tracking__c = \'' + wrapper.op.Id + '\' AND Type__c IN (\'Backflush\', \'Kit\')) ';
            else whereClause += ' ((Operation_Tracking__c = \'' + wrapper.op.Id + '\' AND Type__c = \'Kit\') OR (Operation_Tracking__c IN (\'' + wrapper.op.Id + '\', null) AND Type__c = \'Backflush\'))) ';
        }
        whereClause += ') ';

        List<Material_Tracking__c> materials = getMaterials(null, null, null, new Set<String>{ 'Complete' }, new Set<String>{ 'Work_Order__r.MRB_Location__r.Bin_Tracked__c' }, whereClause);
        if (materials.size() == 0) return wrappers;

        Id companyId;
        Id facilityId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Set<Id> allocatedMaterials = new Set<Id>();
        Set<Id> repairWOIds = new Set<Id>();
        Map<Id, List<Shipment_Line__c>> shipmentLines = new Map<Id, List<Shipment_Line__c>>();
        for (Material_Tracking__c mt:materials) {
            companyId = mt.Work_Order__r.Company__c;
            facilityId = mt.Work_Order__r.Facility__c;
            items.put(mt.Item__c, mt.Item__r);
            if (mt.Allocation_Required__c == true) allocatedMaterials.add(mt.Id);
        }

        Map<Id, List<String>> attributes = AllocationService.getSkidAttributes(companyId, items);
        List<String> planAttributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'license_plate_number__c' });

        Set<Id> locationIds = new Set<Id>();
        Map<String, List<Location__c>> locationMap = SkidService3.locationsFromStockMovementRules(materials, 'Pick', new Set<String>{ 'material_tracking__c' }, null, locationIds);

        Set<Id> itemIds = items.keySet();
        whereClause = 'Item__c IN :itemIds ' +
                      'AND Facility2__c = :facilityId ' +
                      'AND Receipt_Line__c = null ' +
                      'AND Customer__c = null ' +
                      'AND (Lot__c = null OR Lot__r.Lot_Hold__c = false) ' +
                      'AND (Location__c IN :locationIds OR Location__c = null) ' +
                      'AND (Type__c IN (\'' + SkidService3.SKID_TYPE_ALLOCATED + '\', \'' + SkidService3.SKID_TYPE_PLANNED + '\') ' +
                      'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' AND Shipment_Line__c = null AND Sales_Order_Line__c = null))';

        Set<Id> skidIds = new Set<Id>();
        Map<Id, List<SKID__c>> allocatedSkids = new Map<Id, List<SKID__c>>();
        Map<List<String>, Decimal> allocatedQtys = new Map<List<String>, Decimal>();
        Map<List<String>, List<SKID__c>> itemLocSkids = new Map<List<String>, List<SKID__c>>();
        Map<List<String>, Decimal> allQtys = new Map<List<String>, Decimal>();
        for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => String.join(SkidService3.populateSortCriteria(null, companyId), ',') }))) {
            SKID__c skidClone = skid.clone(false, true);
            skidClone.Shipment_Line__c = null;
            skidClone.Material_Tracking__c = null;

            List<String> allocKey = SkidService3.generateKey(skidClone, attributes.get(skid.Item__c));
            List<String> planKey = SkidService3.generateKey(skidClone, planAttributes);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                if (allocatedMaterials.contains(skid.Material_Tracking__c)) {
                    if (!allocatedSkids.containsKey(skid.Material_Tracking__c)) allocatedSkids.put(skid.Material_Tracking__c, new List<SKID__c>{ skid });
                    else allocatedSkids.get(skid.Material_Tracking__c).add(skid);
                }

                allocatedQtys.put(allocKey, KSE.addQuantityToField(allocatedQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
            } else if (skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                allocatedQtys.put(allocKey, KSE.addQuantityToField(allocatedQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
                allocatedQtys.put(planKey, KSE.addQuantityToField(allocatedQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
            } else {
                skidIds.add(skid.Id);

                List<String> itemLocKey = new List<String>{ skid.Item__c, skid.Location__c };
                if (!itemLocSkids.containsKey(itemLocKey)) itemLocSkids.put(itemLocKey, new List<SKID__c>{ skid });
                else itemLocSkids.get(itemLocKey).add(skid);

                allQtys.put(allocKey, KSE.addQuantityToField(allQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
                allQtys.put(planKey, KSE.addQuantityToField(allQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
            }
        }

        Map<Id, List<Serial__c>> serialMap = new Map<Id, List<Serial__c>>();
        if (skidIds.size() > 0) {
            for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => 'SKID__c IN :skidIds', 'ORDER' => 'Name ASC' }))) {
                if (serialMap.containsKey(serial.SKID__c) == false) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
                else serialMap.get(serial.SKID__c).add(serial);
            }
        }

        for (Material_Tracking__c mt:materials) {
            WorkOrderWrapper wrapper = new WorkOrderWrapper(mt.Work_Order__r, mt, new List<SkidService3.SerialWrapper>());
            List<String> allocAttrs = attributes.get(mt.Item__c);

            if (locationMap.containsKey(mt.Id) == false) throw new CustomException(mt.Name + ': Matching stock movement rule not found');

            wrapper.skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Location__c', 'Bin__c' });
            if (mt.Work_Order__r.MRB_Location__r.Bin_Tracked__c == true) {
                FieldInfo fi = new FieldInfo('Scrap_Bin__c', 'Scrap Bin', 'reference');
                fi.referenceTo = 'Bin__c';
                fi.editable = true;
                wrapper.skidFields.add(fi);
            }
            List<String> skidFields = SkidService3.trackedAttributes(null, null, mt.Item__r, new Item__c(Item_Attribute__r = new Item_Attribute__c(License_Plate_Number__c = true)));
            skidFields.addAll(new List<String>{ 'Consigned_Owner__c', 'Quantity_Available__c', 'Quantity_to_Issue__c', 'Quantity_to_Scrap__c' });
            wrapper.skidFields.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields));
            for (FieldInfo fi:wrapper.skidFields) {
                if (fi.field == 'Consigned_Owner__c' || fi.field == 'Quantity_Available__c') fi.editable = false;
                fi.field = 'skid.' + fi.field;
            }

            if (mt.Allocation_Required__c) {
                if (allocatedSkids.containsKey(mt.Id)) {
                    Map<List<String>, List<SKID__c>> aggregatedSkids = new Map<List<String>, List<SKID__c>>();
                    for (Location__c loc:locationMap.get(mt.Id)) {
                        List<String> itemLocKey = new List<String>{ mt.Item__c, loc.Id };
                        if (itemLocSkids.containsKey(itemLocKey) == false) continue;

                        for (SKID__c skid:itemLocSkids.get(itemLocKey)) {
                            skid = skid.clone(true, true);
                            List<String> allocKey = SkidService3.generateKey(skid, allocAttrs);
                            if (!aggregatedSkids.containsKey(allocKey)) aggregatedSkids.put(allocKey, new List<SKID__c>{ skid });
                            else aggregatedSkids.get(allocKey).add(skid);
                        }
                    }

                    for (SKID__c allocatedSkid:allocatedSkids.get(mt.Id)) {
                        SKID__c skidClone = allocatedSkid.clone(false, true);
                        skidClone.Material_Tracking__c = null;

                        List<String> allocKey = SkidService3.generateKey(skidClone, allocAttrs);
                        for (SKID__c skid:aggregatedSkids.get(allocKey)) {
                            skid.Temporary_Value_Holder__c = allocatedSkid.Id;
                            if (skid.Quantity__c < 0) skid.Quantity__c = 0;
                            skid.Quantity_Available__c = Math.min(allocatedSkid.Quantity__c, skid.Quantity__c);
                            skid.Quantity_Allocated__c = allocatedSkid.Quantity__c;
                            skid.Quantity_to_Issue__c = null;
                            skid.Quantity_to_Scrap__c = 0;
                            skid.Lot_Number__c = skid.Lot__r.Name;
                            skid.Item__r = mt.Item__r;

                            List<Serial__c> allocatedSerials = new List<Serial__c>();
                            List<Serial__c> serials = new List<Serial__c>();
                            if (serialMap.containsKey(skid.Id)) {
                                for (Serial__c serial:serialMap.get(skid.Id)) {
                                    if (serial.Allocated_SKID__c == allocatedSkid.Id) allocatedSerials.add(serial);
                                    else if (serial.Allocated_SKID__c == null) serials.add(serial);
                                }
                                allocatedSerials.addAll(serials);
                            }

                            wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(skid, allocatedSerials));
                        }
                    }
                }
            } else {
                for (Location__c loc:locationMap.get(mt.Id)) {
                    List<String> itemLocKey = new List<String>{ mt.Item__c, loc.Id };
                    if (itemLocSkids.containsKey(itemLocKey) == false) continue;

                    for (SKID__c skid:itemLocSkids.get(itemLocKey)) {
                        if (skid.Stocking_UOM__c != skid.Packaging_UOM__c) continue;
                        skid = skid.clone(true, true);

                        Set<Id> skidsProcessed = new Set<Id>();
                        List<String> allocKey = SkidService3.generateKey(skid, allocAttrs);
                        List<String> planKey = SkidService3.generateKey(skid, planAttributes);

                        skid.Quantity_Required__c = allQtys.get(allocKey);
                        skid.Total_Material__c = allQtys.get(planKey);
                        if (allocatedQtys.containsKey(allocKey) == true) {
                            skid.Temporary_Value_Holder__c = JSON.serialize(allocKey);
                            skid.Quantity_Required__c -= allocatedQtys.get(allocKey);
                        }
                        if (allocatedQtys.containsKey(planKey) == true) {
                            skid.Temporary_Value_Holder1__c = JSON.serialize(planKey);
                            skid.Total_Material__c -= allocatedQtys.get(planKey);
                        }
                        if (skid.Quantity_Required__c < 0) skid.Quantity_Required__c = 0;
                        if (skid.Total_Material__c < 0) skid.Total_Material__c = 0;
                        if (skid.Quantity__c < 0) skid.Quantity__c = 0;
                        skid.Quantity_Available__c = Math.min(skid.Quantity__c, Math.min(skid.Quantity_Required__c, skid.Total_Material__c));

                        skid.Quantity_to_Issue__c = null;
                        skid.Quantity_to_Scrap__c = 0;
                        skid.Lot_Number__c = skid.Lot__r.Name;
                        skid.Item__r = mt.Item__r;

                        List<Serial__c> serials = new List<Serial__c>();
                        if (serialMap.containsKey(skid.Id)) {
                            for (Serial__c serial:serialMap.get(skid.Id)) {
                                if (serial.Allocated_SKID__c == null) serials.add(serial);
                            }
                        }

                        wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(skid, serials));
                    }
                }
            }

            if (!wrappers.containsKey(mt.Work_Order__c)) wrappers.put(mt.Work_Order__c, new List<WorkOrderWrapper>());
            wrappers.get(mt.Work_Order__c).add(wrapper);
        }

        return wrappers;
    }

    public static List<SkidService3.SerialWrapper> getCompleteByproductData(Set<Id> workOrderIds, Set<Id> opIds, Boolean last) {
        List<SkidService3.SerialWrapper> byproductWrappers = new List<SkidService3.SerialWrapper>();
        List<Material_Tracking__c> materials = getMaterials(workOrderIds, last == true ? null : opIds, new Set<String>{ 'By-product' }, null, null, last == true ? ' AND (Operation_Tracking__c IN (\'' + String.join(new List<Id>(opIds),'\', \'') + '\') OR Operation_Tracking__c = null) ' : null);
        if (materials.size() == 0) return byproductWrappers;

        Map<String, List<Location__c>> locMap = SkidService3.locationsFromStockMovementRules(materials, 'Putaway', new Set<String>{ 'material_tracking__c' }, null, null);

        for (Material_Tracking__c mt:materials) {
            SKID__c skid = new SKID__c(
                Quantity__c = 0,
                Item__c = mt.Item__c,
                Item__r = mt.Item__r,
                Packaging_UOM__c = mt.Item__r.Stocking_UOM__c,
                Packaging_UOM__r = mt.Item__r.Stocking_UOM__r,
                Material_Tracking__c = mt.Id,
                Material_Tracking__r = mt
            );
            skid.Container_Item__r = SkidService3.getContainerforItem(mt.Item__r, skid.Packaging_UOM__r);
            skid.Container_Item__c = skid.Container_Item__r.Id;
            if (locMap.containsKey(mt.Id) && locMap.get(mt.Id).size() > 0) {
                skid.Location__r = locMap.get(mt.Id)[0];
                skid.Location__c = skid.Location__r.Id;
            }

            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid);
            for (String attr:SkidService3.trackedAttributes(null, null, mt.Item__r)) sw.trackedAttributes.add('skid.' + attr.toLowerCase());
            byproductWrappers.add(sw);
        }

        return byproductWrappers;
    }

    public static Map<Id, List<WorkOrderWrapper>> getCompleteWIPData(Set<Id> woIds, Boolean last) {
        Map<Id, List<WorkOrderWrapper>> wipWrappers = new Map<Id, List<WorkOrderWrapper>>();
        List<Material_Tracking__c> materials = getMaterials(woIds, null, new Set<String>{ MATERIAL_TYPE_KIT, MATERIAL_TYPE_BACKFLUSH }, new Set<String>{ 'Complete' }, null, null);
        if (materials.size() == 0) return wipWrappers;

        Map<Id, List<SKID__c>> wipSkids = new Map<Id, List<SKID__c>>();
        Set<Id> skidIds = new Set<Id>();
        for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => 'Type__c = \'' + SkidService3.SKID_TYPE_WIP + '\' AND Material_Tracking__c IN :materials' }))) {
            skidIds.add(skid.Id);
            if (wipSkids.containsKey(skid.Material_Tracking__c) == false) wipSkids.put(skid.Material_Tracking__c, new List<SKID__c>{ skid });
            else wipSkids.get(skid.Material_Tracking__c).add(skid);
        }

        Map<Id, List<Serial__c>> serialMap = new Map<Id, List<Serial__c>>();
        if (skidIds.size() > 0) {
            for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => 'SKID__c IN :skidIds', 'ORDER' => 'Name ASC' }))) {
                if (serialMap.containsKey(serial.SKID__c) == false) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
                else serialMap.get(serial.SKID__c).add(serial);
            }
        }

        for (Material_Tracking__c mt:materials) {
            if (wipSkids.containsKey(mt.Id) == true || (mt.Type__c == MATERIAL_TYPE_KIT && mt.Operation_Tracking__c == null && !(mt.Quantity_Used__c > 0) && last)) {
                WorkOrderWrapper wrapper = new WorkOrderWrapper(mt.Work_Order__r, mt);

                if (wipSkids.containsKey(mt.Id) == true) {
                    for (SKID__c skid:wipSkids.get(mt.Id)) {
                        skid.Quantity_Available__c = skid.Quantity__c;
                        if (last == false) skid.Quantity_to_Issue__c = 0;
                        skid.Lot_Number__c = skid.Lot__r.Name;
                        wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(skid, serialMap.containsKey(skid.Id) == true ? serialMap.get(skid.Id) : null));
                    }
                } else {
                    wrapper.serialWrapperList.add(new SkidService3.SerialWrapper(new SKID__c(Quantity_Available__c = 0, Type__c = SkidService3.SKID_TYPE_WIP)));
                }

                List<String> displayFields = SkidService3.trackedAttributes(null, null, mt.Item__r, new Item__c(Item_Attribute__r = new Item_Attribute__c(License_Plate_Number__c = true)));
                for (Integer i = 0; i < displayFields.size(); i++) {
                    if (displayFields[i] == 'Lot_Number__c') {
                        displayFields[i] = 'Lot__c';
                        break;
                    }
                }
                displayFields.addAll(new List<String>{ 'Quantity_Available__c', 'Quantity_to_Issue__c' });
                wrapper.skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields);
                for (FieldInfo fi:wrapper.skidFields) {
                    if (fi.field != 'Quantity_to_Issue__c') fi.editable = false;
                    fi.field = 'skid.' + fi.field;
                }

                if (wipWrappers.containsKey(mt.Work_Order__c) == false) wipWrappers.put(mt.Work_Order__c, new List<WorkOrderWrapper>{ wrapper });
                else wipWrappers.get(mt.Work_Order__c).add(wrapper);
            }
        }

        return wipWrappers;
    }

    public static void checkCompleteErrors(List<CompleteWrapper> wrappers, Boolean autoComplete) {
        if (wrappers == null || wrappers.size() == 0) return;

        Map<Id, Work_Order__c> validateMap = new Map<Id, Work_Order__c>();
        List<Lot__c> lots = new List<Lot__c>();
        Map<String, LPN__c> lpns = new Map<String, LPN__c>();
        Set<Id> allocSkidIds = new Set<Id>();
        for (CompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;
            SkidService3.SerialWrapper assembly = wrapper.assemblyInfo;

            validateMap.put(op.Id, wo);

            if (assembly != null && assembly.skid.Quantity_Issued__c == 0 && assembly.skid.Quantity_Short__c == 0 && assembly.skid.Total_Material__c == 0 && assembly.skid.Quantity_Allocated__c == 0) {
                if (wo.Item__r.Item_Attribute__c != null && wo.Item__r.Item_Attribute__r.Lot_Number__c == true && String.isBlank(assembly.skid.Lot_Number__c) == false) {
                    lots.add(SkidService3.populateLotNames(assembly.skid, null));
                }
                if (assembly.skid.Container_Item__r.Item_Attribute__c != null && assembly.skid.Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true && assembly.skid.License_Plate_Number__c == null && String.isBlank(assembly.skid.Temporary_LPN_Holder__c) == false) {
                    lpns.put(assembly.skid.Temporary_LPN_Holder__c, new LPN__c(Name = assembly.skid.Temporary_LPN_Holder__c));
                }
            }

            for (WorkOrderWrapper wow:wrapper.componentInfo) {
                Material_Tracking__c mt = wow.material;
                for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                    Decimal inputQty = mt.Type__c == MATERIAL_TYPE_BYPRODUCT ? sw.skid.Quantity__c : sw.skid.Quantity_to_Issue__c;
                    if ((mt.Type__c == MATERIAL_TYPE_BYPRODUCT || sw.skid.Type__c != SkidService3.SKID_TYPE_WIP) && (inputQty > 0 || sw.skid.Quantity_To_Scrap__c > 0)) {
                        if (sw.skid.Id == null && mt.Item__r.Item_Attribute__c != null && mt.Item__r.Item_Attribute__r.Lot_Number__c == true && String.isBlank(sw.skid.Lot_Number__c) == false) {
                            sw.skid.Company__c = wo.Company__c;
                            sw.skid.Item__c = mt.Item__c;
                            lots.add(SkidService3.populateLotNames(sw.skid, null));
                        }

                        if (mt.Type__c != MATERIAL_TYPE_BYPRODUCT && wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && mt.Item__r.Item_Attribute__c != null && mt.Item__r.Item_Attribute__r.Serial_Number__c == true && mt.Allocation_Required__c == true) {
                            allocSkidIds.add((Id)sw.skid.Temporary_Value_Holder__c);
                        }
                    }
                }
            }
        }

        Map<Id, String> errors = validateForComplete(validateMap, autoComplete);
        if (errors.size() > 0) throw new CustomException(errors.values()[0]);

        Map<List<String>, Lot__c> lotMap = lots.size() > 0 ? SkidService3.createLots(lots) : new Map<List<String>, Lot__c>();
        lpns = lpns.size() > 0 ? SkidService3.createLPNs(lpns) : new Map<String, LPN__c>();

        Map<Id, List<String>> allocSerials = new Map<Id, List<String>>();
        if (allocSkidIds.size() > 0) {
            for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => 'Allocated_SKID__c IN :allocSkidIds', 'ORDER' => 'Name ASC' }))) {
                if (allocSerials.containsKey(serial.Allocated_SKID__c) == false) allocSerials.put(serial.Allocated_SKID__c, new List<String>{ serial.Name });
                else allocSerials.get(serial.Allocated_SKID__c).add(serial.Name);
            }
        }

        Set<String> serialKeys = new Set<String>();
        Map<Id, Decimal> qtyAvailableMap = new Map<Id, Decimal>();
        for (CompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;

            if (wrapper.assemblyInfo != null) {
                SkidService3.SerialWrapper assembly = wrapper.assemblyInfo;
                Boolean last = wrapper.lastOp;

                if (assembly.skid.Quantity_Used__c < 0) throw new CustomException(wo.Name + ': You can\'t complete a negative number of assemblies.');
                if (assembly.skid.Quantity_Scrapped__c < 0) throw new CustomException(wo.Name + ': You can\'t scrap a negative number of assemblies.');
                if (assembly.skid.Input_Quantity__c < 0) throw new CustomException(wo.Name + ': You can\'t consume a negative number of hours.');

                if (assembly.skid.Quantity_Issued__c == 0 && assembly.skid.Quantity_Short__c == 0 && assembly.skid.Total_Material__c == 0) {
                    if (!(assembly.skid.Quantity_Used__c > 0) && !(assembly.skid.Quantity_Scrapped__c > 0)) throw new CustomException(wo.Name + ': You must enter a quantity to complete or quantity to scrap to complete or scrap new assemblies.');

                    if (assembly.skid.Quantity_Allocated__c == 0) {
                        if (assembly.skid.Packaging_UOM__r.Package_Class__r.Level__c > wo.Packaging_UOM__r.Package_Class__r.Level__c) {
                            throw new CustomException(wo.Name + ': You can\'t complete assemblies in a packaging UOM (' + assembly.skid.Packaging_UOM__r.Name + ') larger than the work order\'s packaging UOM (' + wo.Packaging_UOM__r.Name + ').');
                        }

                        SkidService3.checkRequiredAttributes(assembly.skid, SkidService3.trackedAttributes(null, null, wo.Item__r, assembly.skid.Container_Item__r), null, null, ' is required to ' + (assembly.skid.Quantity_Used__c > 0 ? 'complete' : 'scrap') + ' assemblies.');

                        if (wo.Item__r.Item_Attribute__c != null && wo.Item__r.Item_Attribute__r.Lot_Number__c == true) {
                            assembly.skid.Lot__r = lotMap.get(SkidService3.lotUniqueKey(assembly.skid));
                            assembly.skid.Lot__c = assembly.skid.Lot__r.Id;
                        }
                        if (assembly.skid.Container_Item__r.Item_Attribute__c != null && assembly.skid.Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true && assembly.skid.License_Plate_Number__c == null) {
                            assembly.skid.License_Plate_Number__c = lpns.get(assembly.skid.Temporary_LPN_Holder__c).Id;
                        }
                    }
                }

                Decimal totalQty = KSE.addQuantityToField(assembly.skid.Quantity_Used__c, assembly.skid.Quantity_Scrapped__c);
                if (totalQty > 0) {
                    if (last == true && wo.Complete_to_Location__r.Bin_Tracked__c == true && assembly.skid.Quantity_Used__c > 0 && assembly.skid.Bin__c == null) throw new CustomException(wo.Name + ': You must enter a bin to complete assemblies.');
                    if (wo.MRB_Location__r.Bin_Tracked__c == true && assembly.skid.Quantity_Scrapped__c > 0 && assembly.toskid == null) throw new CustomException(wo.Name + ': You must enter a scrap bin to scrap assemblies.');
                    if (assembly.skid.Quantity_Available__c != null && totalQty > assembly.skid.Quantity_Available__c) throw new CustomException(wo.Name + ': You can\'t complete/scrap more assemblies (' + totalQty + ') than available (' + assembly.skid.Quantity_Available__c + ').');

                    if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && wo.Item__r.Item_Attribute__c != null && wo.Item__r.Item_Attribute__r.Serial_Number__c == true) {
                        Decimal serialsToComplete = 0;
                        Decimal serialsToScrap = 0;
                        for (Serial__c serial:assembly.serialList) {
                            if (String.isBlank(serial.Temporary_Value_Holder__c) == true) continue;
                            List<String> flags = serial.Temporary_Value_Holder__c.split('\\|');
                            if (flags[0] != 'Complete' && flags[0] != 'Scrap') continue;

                            String uniqueKey = wo.Company__c + '-' + wo.Item__c + '-' + serial.Name;
                            if (autoComplete == true) uniqueKey += '-' + op.Id;
                            if (serialKeys.contains(uniqueKey) == true) throw new CustomException('You can\'t specify serial ' + serial.Name + ' more than once for item ' + wo.Item__r.Name + '.');
                            else serialKeys.add(uniqueKey);

                            if (flags[0] == 'Complete') serialsToComplete++;
                            else serialsToScrap++;
                        }

                        if (assembly.skid.Quantity_Used__c > 0) {
                            Decimal qtyToComplete = assembly.skid.Quantity_Used__c * assembly.conversionFactor;
                            if (qtyToComplete != serialsToComplete) throw new CustomException(wo.Name + ': You can\'t complete a different number of serials (' + serialsToComplete + ') than the quantity to complete (' + qtyToComplete + ').');
                        }
                        if (assembly.skid.Quantity_Scrapped__c > 0) {
                            Decimal qtyToScrap = assembly.skid.Quantity_Scrapped__c * assembly.conversionFactor;
                            if (qtyToScrap != serialsToScrap) throw new CustomException(wo.Name + ': You can\'t scrap a different number of serials (' + serialsToScrap + ') than the quantity to scrap (' + qtyToScrap + ').');
                        }
                    }
                }
            }

            for (WorkOrderWrapper wow:wrapper.componentInfo) {
                Material_Tracking__c mt = wow.material;

                Map<Id, Decimal> allocSerialsLeft = new Map<Id, Decimal>();
                for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                    if (sw.skid.Type__c == SkidService3.SKID_TYPE_WIP && sw.skid.Id == null) throw new CustomException(mt.Name + ': No material has been kitted. Please go back and kit the work order');

                    Decimal inputQty = mt.Type__c == MATERIAL_TYPE_BYPRODUCT ? sw.skid.Quantity__c : sw.skid.Quantity_to_Issue__c;
                    if (inputQty < 0) throw new CustomException(mt.Name + ': You can\'t ' + (mt.Type__c == MATERIAL_TYPE_BYPRODUCT ? 'complete a negative number of byproducts.' : 'issue a negative number of components.'));
                    if (sw.skid.Quantity_To_Scrap__c < 0) throw new CustomException(mt.Name + ': You can\'t scrap a negative number of components.');

                    if (inputQty > 0 || sw.skid.Quantity_To_Scrap__c > 0) {
                        Id allocSkidId;
                        if (sw.skid.Id == null) {
                            if (sw.skid.Location__c == null) throw new CustomException(mt.Name + ': You must enter a location to ' + (mt.Type__c == MATERIAL_TYPE_BYPRODUCT ? 'complete byproducts' : (inputQty > 0 ? 'issue components' : 'scrap components')) + '.');
                            SkidService3.checkRequiredAttributes(sw.skid, SkidService3.trackedAttributes(null, sw.skid.Location__r, mt.Item__r, sw.skid.Container_Item__r), mt, null, null);

                            if (mt.Item__r.Item_Attribute__c != null && mt.Item__r.Item_Attribute__r.Lot_Number__c == true) {
                                sw.skid.Lot__r = lotMap.get(SkidService3.lotUniqueKey(sw.skid));
                                sw.skid.Lot__c = sw.skid.Lot__r.Id;
                            }
                        } else if (mt.Type__c != MATERIAL_TYPE_BYPRODUCT && (sw.skid.Type__c == SkidService3.SKID_TYPE_WIP || mt.Allocation_Required__c == true)) {
                            Decimal totalQty = KSE.addQuantityToField(inputQty, sw.skid.Quantity_To_Scrap__c);
                            allocSkidId = sw.skid.Type__c != SkidService3.SKID_TYPE_WIP && mt.Allocation_Required__c == true ? (Id)sw.skid.Temporary_Value_Holder__c : null;

                            if (qtyAvailableMap.containsKey(sw.skid.Id) == true) sw.skid.Quantity_Available__c = Math.min(sw.skid.Quantity_Available__c, qtyAvailableMap.get(sw.skid.Id));
                            if (allocSkidId != null && qtyAvailableMap.containsKey(allocSkidId) == true) sw.skid.Quantity_Available__c = Math.min(sw.skid.Quantity_Available__c, qtyAvailableMap.get(allocSkidId) / sw.conversionFactor);

                            if (totalQty > sw.skid.Quantity_Available__c) throw new CustomException(mt.Name + ': You can\'t issue/scrap more quantity (' + totalQty + ') than available (' + sw.skid.Quantity_Available__c + ').');

                            qtyAvailableMap.put(sw.skid.Id, (qtyAvailableMap.containsKey(sw.skid.Id) == true ? qtyAvailableMap.get(sw.skid.Id) : sw.skid.Quantity__c) - totalQty);
                            if (allocSkidId != null) qtyAvailableMap.put(allocSkidId, (qtyAvailableMap.containsKey(allocSkidId) == true ? qtyAvailableMap.get(allocSkidId) : sw.skid.Quantity_Allocated__c) - (totalQty * sw.conversionFactor));
                        }

                        if (mt.Type__c != MATERIAL_TYPE_BYPRODUCT && sw.skid.Lot__c != null && sw.skid.Lot__r.Lot_Hold__c == true) throw new CustomException(mt.Name + ': You can\'t ' + (inputQty > 0 ? 'issue' : 'scrap') + ' components from a lot on hold.');
                        if (inputQty > 0 && sw.skid.Expiration_Date__c < System.today()) throw new CustomException(mt.Name + ': You can\'t ' + (mt.Type__c == MATERIAL_TYPE_BYPRODUCT ? 'complete byproducts with expiration dates in the past.' : 'issue expired components.'));
                        if (sw.skid.Quantity_To_Scrap__c > 0 && wo.MRB_Location__r.Bin_Tracked__c == true && sw.toskid == null) {
                            throw new CustomException(mt.Name + ': You must enter a scrap bin to scrap components.');
                        }

                        if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && mt.Item__r.Item_Attribute__c != null && mt.Item__r.Item_Attribute__r.Serial_Number__c == true) {
                            if (allocSkidId != null && allocSerialsLeft.containsKey(allocSkidId) == false && allocSerials.containsKey(allocSkidId) == true) {
                                allocSerialsLeft.put(allocSkidId, allocSerials.get(allocSkidId).size());
                            }

                            Decimal serialCt = 0;
                            Decimal serialsToScrap = 0;
                            for (Serial__c serial:sw.serialList) {
                                if (mt.Type__c == MATERIAL_TYPE_BYPRODUCT || String.isBlank(serial.Temporary_Value_Holder__c) == false) {
                                    String uniqueKey = wo.Company__c + '-' + mt.Item__c + '-' + serial.Name;
                                    if (serialKeys.contains(uniqueKey) == true) throw new CustomException('You can\'t specify serial ' + serial.Name + ' more than once for item ' + mt.Item__r.Name + '.');
                                    else serialKeys.add(uniqueKey);

                                    if (serial.Temporary_Value_Holder__c != 'COMPONENT SCRAP') serialCt++;
                                    else serialsToScrap++;

                                    if (allocSkidId != null && serial.Allocated_SKID__c != null) allocSerialsLeft.put(allocSkidId, KSE.subtractDecimals(allocSerialsLeft.get(allocSkidId), 1));
                                }
                            }

                            if (inputQty > 0) {
                                String action = mt.Type__c == MATERIAL_TYPE_BYPRODUCT ? 'complete' : 'issue';
                                Decimal qty = inputQty * sw.conversionFactor;
                                if (qty != serialCt) throw new CustomException(mt.Name + 'You can\'t ' + action + ' a different number of serials (' + serialCt + ') than the quantity to ' + action + ' (' + qty + ').');
                            }
                            if (sw.skid.Quantity_to_Scrap__c > 0) {
                                Decimal qtyToScrap = sw.skid.Quantity_to_Scrap__c * sw.conversionFactor;
                                if (qtyToScrap != serialsToScrap) throw new CustomException(mt.Name + 'You can\'t scrap a different number of serials (' + serialsToScrap + ') than the quantity to scrap (' + qtyToScrap + ').');
                            }
                        }
                    }
                }

                if (mt.Allocation_Required__c == true && allocSerialsLeft.size() > 0) {
                    for (Id allocSkidId:allocSerialsLeft.keySet()) {
                        Decimal qtyLeft = qtyAvailableMap.get(allocSkidId);
                        Decimal serialsLeft = allocSerialsLeft.get(allocSkidId);
                        List<String> allocatedSerials = allocSerials.get(allocSkidId);

                        if (serialsLeft > qtyLeft) {
                            Decimal serialsRequired = allocatedSerials.size() - qtyLeft;

                            String errMsg = mt.Name + ': You must issue ';
                            if (serialsRequired != allocatedSerials.size()) errMsg += 'at least ' + serialsRequired;
                            else errMsg += 'all';
                            errMsg += ' allocated serials';
                            if (allocatedSerials.size() <= 20) errMsg += ': ' + String.join(allocatedSerials,', ');

                            throw new CustomException(errMsg);
                        }
                    }
                }
            }
        }
    }

    public static Map<Id, List<Shipment_Line__c>> getShipmentLinesForWorkOrders(Set<Id> woIds, String orderByClause) {
        Map<Id, List<Shipment_Line__c>> shipmentLines = new Map<Id, List<Shipment_Line__c>>();
        if (woIds == null || woIds.size() == 0) return shipmentLines;

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Facility__c', 'Product__c', 'Quantity_Allocated__c', 'Quantity_Picked__c',
            'Quantity_Planned__c', 'Quantity_Shipped__c', 'Quantity_To_Pick__c', 'Sales_Order_Line__c', 'Shipment__c', 'Work_Order__c',

            'Company__r.Auto_Plan_Pick__c','Facility__r.Facility_Identifier__c','Sales_Order_Line__r.Related_Sales_Order_Line__c','Sales_Order_Line__r.Type__c','Sales_Order_Line__c',

            'Product__r.Item__c', 'Product__r.Item__r.Non_Inventory__c','Sales_Order_Line__r.Sales_Order__c','Sales_Order_Line__r.Sales_Order__r.Type__c',

            'Sales_Order_Line__r.Fulfillment_Source__c', 'Sales_Order_Line__r.Selling_UOM__c', 'Sales_Order_Line__r.Quantity_From_Stock__c',
            'Sales_Order_Line__r.Quantity_Ordered__c',

            'Shipment__r.Status__c' });
        shlQuery.setWhereClause('Work_Order__c IN :woIds');
        if (String.isBlank(orderByClause) == false) shlQuery.setOrderByClause(orderByClause);

        for (Shipment_Line__c shl:Database.query(shlQuery.getQuery())) {
            if (shipmentLines.containsKey(shl.Work_Order__c) == false) shipmentLines.put(shl.Work_Order__c, new List<Shipment_Line__c>{ shl });
            else shipmentLines.get(shl.Work_Order__c).add(shl);
        }
        return shipmentLines;
    }

    public static void scannerComplete(List<CompleteWrapper> completeWrappers) { complete(completeWrappers, false, true); }
    public static void completeV2(List<CompleteWrapper> completeWrappers) { complete(completeWrappers, false, false); }
    public static void completeV2(List<CompleteWrapper> completeWrappers, Boolean fromAutoComplete) { complete(completeWrappers, fromAutoComplete, false); }
    public static void complete(List<CompleteWrapper> wrappers, Boolean autoComplete, Boolean scanner) {
        if (wrappers == null || wrappers.size() == 0) return;

        checkCompleteErrors(wrappers, autoComplete);

        Set<Id> woIds = new Set<Id>();
        Set<Id> nonShippableWoIds = new Set<Id>();
        Id companyId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        for (CompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            if (wrapper.lastOp == true) woIds.add(wo.Id);
            if (wo.Type__c == WO_TYPE_REPAIR && wo.Field_Service__c == true) nonShippableWoIds.add(wo.Id);
            companyId = wo.Company__c;
            for (WorkOrderWrapper wow:wrapper.componentInfo) {
                Material_Tracking__c mt = wow.material;
                if (mt.Type__c != MATERIAL_TYPE_BYPRODUCT && mt.Allocation_Required__c == true) items.put(mt.Item__c, mt.Item__r);
            }
        }

        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Customer__c');
        attributes.add('Sales_Order_Line__c');
        attributes.add('Work_Order__c');
        attributes.add('Material_Tracking__c');

        Map<Id, List<Shipment_Line__c>> shipmentLines = woIds.size() > 0 ? getShipmentLinesForWorkOrders(woIds, 'Sales_Order_Line__r.Required_Date__c, Sales_Order_Line__r.CreatedDate ASC') : new Map<Id, List<Shipment_Line__c>>();
        Map<Id, List<String>> allocAttributes = items.size() > 0 ? AllocationService.getSkidAttributes(companyId, items) : new Map<Id, List<String>>();

        Map<Id,Shipment_Line__c> shlineWOmap = new Map<Id,Shipment_Line__c>();
       
        for(Id woId:shipmentLines.keyset()){
        	
        	if(shipmentLines.containsKey(woId)) {
        		for (Shipment_Line__c shline:shipmentLines.get(woId)) {
        			if(!shlineWOmap.containskey(shline.Work_Order__c))
            			shlineWOmap.put(shline.Work_Order__c,shline);
	        	}
        	}
        }
        Map<Id, Id> soLines = new Map<Id, Id>();
        if (nonShippableWoIds.size() > 0) {
            SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c');
            solQuery.addFields(new Set<String>{ 'Id', 'Name', 'Work_Order__c' });
            solQuery.setWhereClause('Status__c = \'Open\' AND Work_Order__c IN :nonShippableWoIds AND Sales_Order__r.Type__c = \'' + SalesOrderService.SO_TYPE_REPAIR + '\' AND SKID__c != null');
            for (Sales_Order_Line__c sol:Database.query(solQuery.getQuery())) soLines.put(sol.Work_Order__c, sol.Id);
        }

        Map<Id, Work_Order__c> wosToUpdate = new Map<Id, Work_Order__c>();
        Map<Id, Operation_Tracking__c> opsToUpdate = new Map<Id, Operation_Tracking__c>();
        Map<Id, Operation_Transaction__c> otsToInsert = new Map<Id, Operation_Transaction__c>();
        Map<Id,List<Serial_Transaction__c>> stsToInsert = new Map<Id,List<Serial_Transaction__c>>();
        Map<Id, Material_Tracking__c> materialsToUpdate = new Map<Id, Material_Tracking__c>();

        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        Map<List<String>, SkidService3.SerialWrapper> serialsForTransactions = new Map<List<String>, SkidService3.SerialWrapper>();
        Map<Id, SkidService3.ParameterData> itData = new Map<Id, SkidService3.ParameterData>();
        Map<Id,Map<Id,List<SkidService3.SerialWrapper>>> skidsToAllocate = new Map<Id,Map<Id,List<SkidService3.SerialWrapper>>>();

        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        Map<List<String>, SkidService3.SerialWrapper> assemblyWipSkids = new Map<List<String>, SkidService3.SerialWrapper>();
        Map<Id, SkidService3.SerialWrapper> repairMaterialSkids = new Map<Id, SkidService3.SerialWrapper>();
        for (CompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;

            SkidService3.ParameterData itInfo = new SkidService3.ParameterData();
            itInfo.sourceDoc = new Work_Order__c(Company__c = wo.Company__c);
            itInfo.icType = 'Work Order Complete';

            Operation_Transaction__c ot = wrapper.ot != null ? wrapper.ot : new Operation_Transaction__c();
            ot.Operation_Tracking__c = op.Id;
            ot.Operation_Sequence__c = op.Sequence__c;
            ot.Quantity_Completed__c = 0;
            ot.Quantity_Scrapped__c = 0;
            ot.Hours_Consumed__c = 0;
            ot.Work_Order__c = wo.Id;

            SkidService3.SerialWrapper assembly;
            SKID__c assemblyWipSkid;
            if (wrapper.assemblyInfo != null) {
                if (wosToUpdate.containsKey(wo.Id) == false) wosToUpdate.put(wo.Id, new Work_Order__c(
                    Id = wo.Id,
                    Quantity_Complete__c = 0,
                    Quantity_Complete_Stocking_UOM__c = 0,
                    Completed__c = 0,
                    Quantity_Scrapped__c = 0,
                    Quantity_Scrapped_Stocking_UOM__c = 0
                ));
                Work_Order__c woToUpdate = wosToUpdate.get(wo.Id);

                assembly = wrapper.assemblyInfo;
                Boolean last = wrapper.lastOp;

                if (packagingUoms.containsKey(wo.Item__c) == false) packagingUoms.put(wo.Item__c, (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class));
                List<Id> pkgUoms = packagingUoms.get(wo.Item__c);
                Decimal woConvFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__c, pkgUoms);

                if (assembly.skid.Quantity_Used__c == null) assembly.skid.Quantity_Used__c = 0;
                if (assembly.skid.Quantity_Scrapped__c == null) assembly.skid.Quantity_Scrapped__c = 0;
                if (assembly.skid.Input_Quantity__c == null) assembly.skid.Input_Quantity__c = 0;
                Decimal totalQty = assembly.skid.Quantity_Used__c + assembly.skid.Quantity_Scrapped__c;

                SKID__c assemblySkidTemplate = new SKID__c(
                    Company__c = wo.Company__c,
                    Stocking_UOM__c = wo.Item__r.Stocking_UOM__c,
                    Item__c = wo.Item__c,
                    Item__r = wo.Item__r,
                    Facility2__c = wo.Facility__c,
                    Facility2__r = wo.Facility__r,
                    Sales_Order_Line__c = soLines.get(wo.Id)
                );
                SkidService3.copyAttributes(assembly.skid, assemblySkidTemplate, attributes, new Set<String>{ 'Location__c', 'Work_Order__c', 'Material_Tracking__c' });

                assemblyWipSkid = assemblySkidTemplate.clone(false, true);
                assemblyWipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                assemblyWipSkid.Quantity__c = 0;
                assemblyWipSkid.Quantity_Stocking_UOM__c = 0;
                assemblyWipSkid.Location__c = wo.Default_WIP_Location__c;
                assemblyWipSkid.Location__r = wo.Default_WIP_Location__r;
                assemblyWipSkid.Bin__c = null;
                assemblyWipSkid.Bin__r = null;
                assemblyWipSkid.Work_Order__c = wo.Id;
				if(wo.Type__c == WO_TYPE_REPAIR && wo.Field_Service__c == false && shlineWOmap.containskey(wo.Id)){//shlineWOmap.containskey(wo.Id) && shlineWOmap.get(wo.Id).Sales_Order_Line__r.Type__c == 'Repair' && SalesOrderService.SO_TYPE_RMA_REPAIR.contains(shlineWOmap.get(wo.Id).Sales_Order_Line__r.Sales_Order__r.Type__c
                	assemblyWipSkid.Sales_Order_Line__c = (Id)shlineWOmap.get(wo.Id).Sales_Order_Line__c;
                }
                SkidService3.SerialWrapper assemblyWipSw = new SkidService3.SerialWrapper(assemblyWipSkid);

                SkidService3.SerialWrapper repairMaterialSw;
                if (wo.Type__c == WO_TYPE_REPAIR && (last == false || wo.Number_of_Operations__c == 1)) {
                    SKID__c repairMaterialSkid = assemblySkidTemplate.clone(false, true);
                    repairMaterialSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                    repairMaterialSkid.Quantity__c = 0;
                    repairMaterialSkid.Quantity_Stocking_UOM__c = 0;
                    repairMaterialSkid.Location__c = wo.Default_WIP_Location__c;
                    repairMaterialSkid.Location__r = wo.Default_WIP_Location__r;
                    repairMaterialSkid.Bin__c = null;
                    repairMaterialSkid.Bin__r = null;
                    repairMaterialSkid.Material_Tracking__c = assembly.skid.Material_Tracking__c;
                    repairMaterialSw = new SkidService3.SerialWrapper(repairMaterialSkid);
                }

                SkidService3.SerialWrapper scrappedSw;
                if (assembly.skid.Quantity_Scrapped__c > 0) {
                    SKID__c scrappedSkid = assemblySkidTemplate.clone(false, true);
                    scrappedSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                    scrappedSkid.Quantity__c = assembly.skid.Quantity_Scrapped__c;
                    scrappedSkid.Quantity_Stocking_UOM__c = scrappedSkid.Quantity__c * assembly.conversionFactor;
                    scrappedSkid.Location__c = wo.MRB_Location__c;
                    scrappedSkid.Location__r = wo.MRB_Location__r;
                    if (assembly.toskid != null) {
                        scrappedSkid.Bin__c = assembly.toskid.Bin__c;
                        scrappedSkid.Bin__r = assembly.toskid.Bin__r;
                    } else {
                        scrappedSkid.Bin__c = null;
                        scrappedSkid.Bin__r = null;
                    }

                    scrappedSw = new SkidService3.SerialWrapper(scrappedSkid);
                    skidsToPutaway.add(scrappedSw);

                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(wo.Item__r, wo, wo.Type__c != WO_TYPE_REPAIR ? 'Work Order Assembly Scrap' : 'Work Order Repair Assembly Scrap', scrappedSkid.Quantity__c, assemblyWipSkid, scrappedSkid, attributes);
                    it.Operation_Tracking__c = op.Id;
                    itInfo.itList.add(it);
                    if (assembly.serialList.size() > 0) serialsForTransactions.put(SkidService3.generateKey(it, attributes), new SkidService3.SerialWrapper(it, scrappedSw.serialList));

                    woToUpdate.Quantity_Scrapped__c += (scrappedSkid.Quantity__c / woConvFactor);
                    woToUpdate.Quantity_Scrapped_Stocking_UOM__c += scrappedSkid.Quantity_Stocking_UOM__c;
                }

                SkidService3.SerialWrapper finishedSw;
                if (last == true && assembly.skid.Quantity_Used__c > 0) {
                    SKID__c finishedSkid = assemblySkidTemplate.clone(false, true);
                    finishedSkid.Quantity__c = assembly.skid.Quantity_Used__c;
                    finishedSkid.Quantity_Stocking_UOM__c = finishedSkid.Quantity__c * assembly.conversionFactor;
                    if (wo.Type__c != WO_TYPE_REPAIR || wo.Field_Service__c == false) {
                        finishedSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                        finishedSkid.Location__c = wo.Complete_to_Location__c;
                        finishedSkid.Location__r = wo.Complete_to_Location__r;
                    } else {
                        finishedSkid.Facility2__c = null;
                        finishedSkid.Facility2__r = null;
                        finishedSkid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
                    }
                    
                    if(wo.Type__c == WO_TYPE_REPAIR && wo.Field_Service__c == false && shlineWOmap.containskey(wo.Id)){
	                	finishedSkid.Sales_Order_Line__c = (Id)shlineWOmap.get(wo.Id).Sales_Order_Line__c;
	                }
                    finishedSw = new SkidService3.SerialWrapper(finishedSkid);
                    skidsToPutaway.add(finishedSw);

                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(wo.Item__r, wo, wo.Type__c != WO_TYPE_REPAIR ? 'Work Order Assembly Completion' : 'Work Order Repair Assembly Completion', finishedSkid.Quantity__c, assemblyWipSkid, finishedSkid, attributes);
                    it.Operation_Tracking__c = op.Id;
                    itInfo.itList.add(it);
                    if (assembly.serialList.size() > 0) serialsForTransactions.put(SkidService3.generateKey(it, attributes), new SkidService3.SerialWrapper(it, finishedSw.serialList));

                    Decimal qtyCompleted = finishedSkid.Quantity__c / woConvFactor;
                    woToUpdate.Quantity_Complete__c += qtyCompleted;
                    woToUpdate.Quantity_Complete_Stocking_UOM__c += finishedSkid.Quantity_Stocking_UOM__c;
                    if (scanner == true) woToUpdate.Completed__c += qtyCompleted;
                }

                if (assembly.serialList.size() > 0) {
                    for (Serial__c serial:assembly.serialList) {
                        if (String.isBlank(serial.Temporary_Value_Holder__c) == true) continue;
                        List<String> flags = serial.Temporary_Value_Holder__c.split('\\|');
                        if (flags[0] != 'Complete' && flags[0] != 'Scrap') continue;

                        if (flags[0] == 'Complete') {
                            if (last == false) {
                                if (serial.Id == null || (flags.size() > 1 && flags[1] == 'Material')) {
                                    assemblyWipSw.serialList.add(serial);
                                    assemblyWipSkid.Quantity_Stocking_UOM__c++;
                                    if (serial.Id != null) {
                                        serial.Temporary_Value_Holder__c = serial.Name;
                                        repairMaterialSw.serialList.add(serial);
                                        repairMaterialSw.skid.Quantity_Stocking_UOM__c--;
                                    }
                                }
                            } else {
                                finishedSw.serialList.add(serial);
                                if (wo.Number_of_Operations__c > 1) {
                                    assemblyWipSkid.Quantity_Stocking_UOM__c--;
                                } else if (repairMaterialSw != null) {
                                    serial.Temporary_Value_Holder__c = serial.Name;
                                    repairMaterialSw.serialList.add(serial);
                                    repairMaterialSw.skid.Quantity_Stocking_UOM__c--;
                                }
                            }

                            Serial_Transaction__c st = new Serial_Transaction__c(
                                Company__c = wo.Company__c,
                                Facility__c = wo.Facility__c,
                                Item__c = wo.Item__c,
                                Serial__r = new Serial__c(Unique_Key2__c = wo.Company__c + '-' + wo.Item__c + '-' + serial.Name),
                                Type__c = 'Operation Completion'
                            );
                            if (stsToInsert.containsKey(op.Id) == false) stsToInsert.put(op.Id, new List<Serial_Transaction__c>{ st });
                            else stsToInsert.get(op.Id).add(st);
                        } else {
                            scrappedSw.serialList.add(serial);
                            if (serial.Id != null) {
                                if (flags.size() > 1 && flags[1] == 'Material') {
                                    serial.Temporary_Value_Holder__c = serial.Name;
                                    repairMaterialSw.serialList.add(serial);
                                    repairMaterialSw.skid.Quantity_Stocking_UOM__c--;
                                } else {
                                    assemblyWipSkid.Quantity_Stocking_UOM__c--;
                                }
                            }

                            Serial_Transaction__c st = new Serial_Transaction__c(
                                Company__c = wo.Company__c,
                                Facility__c = wo.Facility__c,
                                Item__c = wo.Item__c,
                                Serial__r = new Serial__c(Unique_Key2__c = wo.Company__c + '-' + wo.Item__c + '-' + serial.Name),
                                Type__c = 'Operation Scrap'
                            );
                            if (stsToInsert.containsKey(op.Id) == false) stsToInsert.put(op.Id, new List<Serial_Transaction__c>{ st });
                            else stsToInsert.get(op.Id).add(st);
                        }
                    }

                    assemblyWipSkid.Quantity__c = assemblyWipSkid.Quantity_Stocking_UOM__c / assembly.conversionFactor;
                    if (repairMaterialSw != null) repairMaterialSw.skid.Quantity__c = repairMaterialSw.skid.Quantity_Stocking_UOM__c / assembly.conversionFactor;
                } else {
                    if (assembly.skid.Quantity_Scrapped__c > 0) {
                        if (last == false) {
                            Decimal wipQty = Math.min(assembly.skid.Quantity_Issued__c - assembly.skid.Quantity_Short__c + assembly.skid.Quantity_Required__c, assembly.skid.Quantity_Scrapped__c);
                            assembly.skid.Quantity_Issued__c -= wipQty;
                            assemblyWipSkid.Quantity__c -= wipQty;
                            if (repairMaterialSw != null) repairMaterialSw.skid.Quantity__c -= (assembly.skid.Quantity_Scrapped__c - wipQty);
                        } else if (wo.Number_of_Operations__c > 1) {
                            assemblyWipSkid.Quantity__c = -assembly.skid.Quantity_Scrapped__c;
                        } else if (repairMaterialSw != null) {
                            repairMaterialSw.skid.Quantity__c = -assembly.skid.Quantity_Scrapped__c;
                        }
                    }

                    if (assembly.skid.Quantity_Used__c > 0) {
                        if (last == false) {
                            Decimal wipQty = Math.max(assembly.skid.Quantity_Used__c + assembly.skid.Quantity_Short__c - assembly.skid.Quantity_Issued__c - assembly.skid.Quantity_Required__c, 0);
                            assemblyWipSkid.Quantity__c += wipQty;
                            if (repairMaterialSw != null) repairMaterialSw.skid.Quantity__c -= wipQty;
                        } else if (wo.Number_of_Operations__c > 1) {
                            assemblyWipSkid.Quantity__c -= assembly.skid.Quantity_Used__c;
                        } else if (repairMaterialSw != null) {
                            repairMaterialSw.skid.Quantity__c -= assembly.skid.Quantity_Used__c;
                        }
                    }

                    assemblyWipSkid.Quantity_Stocking_UOM__c = assemblyWipSkid.Quantity__c * assembly.conversionFactor;
                    if (repairMaterialSw != null) repairMaterialSw.skid.Quantity_Stocking_UOM__c = repairMaterialSw.skid.Quantity__c * assembly.conversionFactor;
                }

                if (autoComplete == true) {
                    List<String> assemblyWipKey = SkidService3.generateKey(assemblyWipSkid, attributes);
                    if (assemblyWipSkids.containsKey(assemblyWipKey) == true) {
                        SkidService3.SerialWrapper wipSw = assemblyWipSkids.get(assemblyWipKey);
                        if (assemblyWipSw.serialList.size() > 0) {
                            Set<String> serialNames = new Set<String>();
                            for (Serial__c serial:wipSw.serialList) serialNames.add(serial.Name);
                            for (Serial__c serial:assemblyWipSw.serialList) {
                                if (serialNames.contains(serial.Name) == false) wipSw.serialList.add(serial);
                            }
                            wipSw.skid.Quantity_Stocking_UOM__c = wipSw.serialList.size();
                            wipSw.skid.Quantity__c = wipSw.skid.Quantity_Stocking_UOM__c / assembly.conversionFactor;
                        } else {
                            wipSw.skid.Quantity__c = Math.max(assemblyWipSw.skid.Quantity__c, wipSw.skid.Quantity__c);
                            wipSw.skid.Quantity_Stocking_UOM__c = wipSw.skid.Quantity__c * assembly.conversionFactor;
                        }
                    } else {
                        skidsToPutaway.add(assemblyWipSw);
                        assemblyWipSkids.put(assemblyWipKey, assemblyWipSw);
                    }
                } else {
                    skidsToPutaway.add(assemblyWipSw);
                }

                if (repairMaterialSw != null && repairMaterialSw.skid.Quantity__c < 0) {
                    skidsToPutaway.add(repairMaterialSw);

                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(wo.Item__r, wo, 'Work Order Repair Issue From WIP', -repairMaterialSw.skid.Quantity__c, repairMaterialSw.skid, assemblyWipSkid, attributes);
                    it.Assembly_Packaging_UOM__c = it.Packaging_UOM__c;
                    it.Operation_Tracking__c = op.Id;
                    itInfo.itList.add(it);

                    repairMaterialSw.it = it;
                    repairMaterialSkids.put(wo.Id, repairMaterialSw);
                }

                SKID__c skidForOt = finishedSw != null ? finishedSw.skid : assemblyWipSkid;
                ot.Quantity_Completed__c = assembly.skid.Quantity_Used__c;
                ot.Quantity_Scrapped__c = assembly.skid.Quantity_Scrapped__c;
                ot.Hours_Consumed__c = assembly.skid.Input_Quantity__c;
                for (String attr:attributes) {
                    String otAttr = attr == 'Facility2__c' ? 'Facility__c' : attr;
                    if (otFields.containsKey(otAttr) == false || skidForOt.get(attr) == null) continue;
                    ot.put(otAttr, skidForOt.get(attr));
                }

                if (totalQty > 0 || assembly.skid.Input_Quantity__c > 0) {
                    if (opsToUpdate.containsKey(op.Id) == false) opsToUpdate.put(op.Id, new Operation_Tracking__c(
                        Id = op.Id,
                        Hours_Consumed__c = 0,
                        Quantity_Completed__c = 0,
                        Quantity_Scrapped__c = 0,
                        Quantity_Available__c = 0
                    ));

                    Operation_Tracking__c opToUpdate = opsToUpdate.get(op.Id);
                    opToUpdate.Hours_Consumed__c += ot.Hours_Consumed__c;
                    opToUpdate.Quantity_Completed__c += (ot.Quantity_Completed__c / woConvFactor);
                    opToUpdate.Quantity_Scrapped__c += (ot.Quantity_Scrapped__c / woConvFactor);
                    opToUpdate.Quantity_Available__c -= ((ot.Quantity_Completed__c + ot.Quantity_Scrapped__c) / woConvFactor);

                    if (wrapper.nextOp != null && ot.Quantity_Completed__c > 0) {
                        Operation_Tracking__c nextOp = wrapper.nextOp;
                        if (opsToUpdate.containsKey(nextOp.Id) == false) opsToUpdate.put(nextOp.Id, new Operation_Tracking__c(
                            Id = nextOp.Id,
                            Hours_Consumed__c = 0,
                            Quantity_Completed__c = 0,
                            Quantity_Scrapped__c = 0,
                            Quantity_Available__c = 0
                        ));

                        nextOp = opsToUpdate.get(nextOp.Id);
                        nextOp.Quantity_Available__c += (ot.Quantity_Completed__c / woConvFactor);
                    }
                }

                if (last == true && finishedSw != null && shipmentLines.containsKey(wo.Id) == true) {
                    Decimal qtyCompleted = finishedSw.skid.Quantity_Stocking_UOM__c;
                    List<Serial__c> serialsCompleted = finishedSw.serialList.clone();

                    for (Shipment_Line__c shl:shipmentLines.get(wo.Id)) {
                        if (qtyCompleted == 0) break;
                        Decimal sellingToStocking = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, wo.Item__r.Stocking_UOM__c, pkgUoms);
                        Decimal qtyToAllocate = (shl.Quantity_Planned__c * sellingToStocking) - (shl.Quantity_Allocated__c * sellingToStocking) - shl.Quantity_To_Pick__c - shl.Quantity_Picked__c - (shl.Quantity_Shipped__c * sellingToStocking);

                        if (qtyToAllocate<=0 || (shl.Sales_Order_Line__c != null && shl.Sales_Order_Line__r.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP)) continue;
                        
                        SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(finishedSw.skid.clone(false, true));
                        sw.skid.Input_Quantity__c = Math.min(qtyCompleted, qtyToAllocate);
                        qtyCompleted -= sw.skid.Input_Quantity__c;
                        if (finishedSw.serialList.size() > 0) {
                            Decimal serialsToAdd = sw.skid.Input_Quantity__c;
                            while (serialsToAdd > 0) {
                                sw.serialList.add(serialsCompleted[0]);
                                serialsCompleted.remove(0);
                                serialsToAdd--;
                            }
                        }

                        if (skidsToAllocate.containsKey(shl.Shipment__c) == false) skidsToAllocate.put(shl.Shipment__c, new Map<Id, List<SkidService3.SerialWrapper>>{ shl.Id => new List<SkidService3.SerialWrapper>{ sw }});
                        else if (skidsToAllocate.get(shl.Shipment__c).containsKey(shl.Id) == false) skidsToAllocate.get(shl.Shipment__c).put(shl.Id, new List<SkidService3.SerialWrapper>{ sw });
                        else skidsToAllocate.get(shl.Shipment__c).get(shl.Id).add(sw);
                    }
                }
            }

            otsToInsert.put(op.Id, ot);

            for (WorkOrderWrapper component:wrapper.componentInfo) {
                Material_Tracking__c mt = component.material;

                if (materialsToUpdate.containsKey(mt.Id) == false) materialsToUpdate.put(mt.Id, newMaterialTracking(mt));
                Material_Tracking__c mtToUpdate = materialsToUpdate.get(mt.Id);

                for (SkidService3.SerialWrapper sw:component.serialWrapperList) {
                    if (mt.Type__c != MATERIAL_TYPE_BYPRODUCT) {
                        if (!(sw.skid.Quantity_to_Issue__c > 0) && !(sw.skid.Quantity_To_Scrap__c > 0)) continue;

                        Decimal totalQty = KSE.addQuantityToField(sw.skid.Quantity_to_Issue__c, sw.skid.Quantity_To_Scrap__c);
                        List<Serial__c> allSerials = new List<Serial__c>();
                        List<Serial__c> serialsToIssue = new List<Serial__c>();
                        List<Serial__c> serialsToScrap = new List<Serial__c>();
                        for (Serial__c serial:sw.serialList) {
                            if (String.isBlank(serial.Temporary_Value_Holder__c) == true) continue;
                            serial.Allocated_SKID__c = null;
                            allSerials.add(serial);
                            if (serial.Temporary_Value_Holder__c != 'COMPONENT SCRAP') serialsToIssue.add(serial);
                            else serialsToScrap.add(serial);
                            if (serial.Temporary_Value_Holder__c == 'COMPONENT SCRAP' || serial.Temporary_Value_Holder__c == 'COMPONENT ISSUE') serial.Temporary_Value_Holder__c = null;
                        }

                        SKID__c skidTemplate = new SKID__c(
                            Company__c = wo.Company__c,
                            Stocking_UOM__c = mt.Item__r.Stocking_UOM__c,
                            Item__c = mt.Item__c,
                            Item__r = mt.Item__r,
                            Facility2__c = wo.Facility__c,
                            Facility2__r = wo.Facility__r
                        );
                        SkidService3.copyAttributes(sw.skid, skidTemplate, attributes, new Set<String>{ 'Material_Tracking__c' });

                        SKID__c wipSkid = skidTemplate.clone(false, true);
                        wipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                        wipSkid.Location__c = wo.Default_WIP_Location__c;
                        wipSkid.Location__r = wo.Default_WIP_Location__r;
                        wipSkid.Bin__c = null;
                        wipSkid.Bin__r = null;
                        wipSkid.Material_Tracking__c = mt.Id;
                        wipSkid.Consigned_Owner__c = null;
                        wipSkid.Purchase_Order_Line__c = null;
                        skidsToPutaway.add(new SkidService3.SerialWrapper(wipSkid));

                        if (sw.skid.Type__c != SkidService3.SKID_TYPE_WIP) {
                            SKID__c stockSkid = skidTemplate.clone(false, true);
                            stockSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                            stockSkid.Quantity__c = -totalQty;
                            stockSkid.Quantity_Stocking_UOM__c = stockSkid.Quantity__c * sw.conversionFactor;
                            skidsToPutaway.add(new SkidService3.SerialWrapper(stockSkid));

                            wipSkid.Quantity__c = 0;
                            wipSkid.Quantity_Stocking_UOM__c = 0;

                            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(mt.Item__r, mt, 'Work Order Component Issue', -stockSkid.Quantity__c, stockSkid, wipSkid, attributes);
                            it.Operation_Tracking__c = op.Id;
                            itInfo.itList.add(it);
                            if (allSerials.size() > 0) serialsForTransactions.put(SkidService3.generateKey(it, attributes), new SkidService3.SerialWrapper(it, allSerials));

                            mtToUpdate.Quantity_Issued__c += it.Quantity_Stocking_UOM__c;

                            if (mt.Allocation_Required__c == true) {
                                SKID__c allocatedSkid = new SKID__c(
                                    Company__c = wo.Company__c,
                                    Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                                    Quantity__c = stockSkid.Quantity_Stocking_UOM__c,
                                    Quantity_Stocking_UOM__c = stockSkid.Quantity_Stocking_UOM__c,
                                    Stocking_UOM__c = mt.Item__r.Stocking_UOM__c,
                                    Item__c = mt.Item__c,
                                    Item__r = mt.Item__r,
                                    Container_Item__c = mt.Item__c,
                                    Container_Item__r = mt.Item__r,
                                    Packaging_UOM__c = mt.Item__r.Stocking_UOM__c,
                                    Packaging_UOM__r = mt.Item__r.Stocking_UOM__r,
                                    Facility2__c = wo.Facility__c,
                                    Facility2__r = wo.Facility__r,
                                    Material_Tracking__c = mt.Id
                                );
                                SkidService3.copyAttributes(sw.skid, allocatedSkid, allocAttributes.get(mt.Item__c), null);
                                skidsToPutaway.add(new SkidService3.SerialWrapper(allocatedSkid));

                                mtToUpdate.Quantity_Allocated__c -= totalQty;
                            }
                        } else {
                            wipSkid.Quantity__c = -totalQty;
                            wipSkid.Quantity_Stocking_UOM__c = wipSkid.Quantity__c * sw.conversionFactor;
                        }

                        if (sw.skid.Quantity_to_Issue__c > 0) {
                            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(mt.Item__r, mt, 'Work Order Issue From WIP', sw.skid.Quantity_to_Issue__c, wipSkid, assemblyWipSkid, attributes);
                            it.Packaging_UOM__c = wipSkid.Packaging_UOM__c;
                            it.Assembly_Packaging_UOM__c = assemblyWipSkid.Packaging_UOM__c;
                            it.Operation_Tracking__c = op.Id;
                            if (assembly.skid.Quantity_Used__c == 0 && assembly.skid.Quantity_Scrapped__c == 0 && assembly.skid.Quantity_Issued__c == 0 && assembly.skid.Quantity_Required__c > 0) {
                                it.To_SKID_Identifier__c = assembly.skid.Temporary_Value_Holder__c;
                            }
                            itInfo.itList.add(it);
                            if (serialsToIssue.size() > 0) {
                                skidsToPutaway.add(new SkidService3.SerialWrapper(it, serialsToIssue));

                                List<String> key = SkidService3.generateKey(wipSkid, attributes);
                                key.addAll(SkidService3.generateKey(assemblyWipSkid, attributes));
                                serialsForTransactions.put(key, new SkidService3.SerialWrapper(it, serialsToIssue));
                            }

                            mtToUpdate.Quantity_Used__c += it.Quantity_Stocking_UOM__c;
                        }

                        if (sw.skid.Quantity_To_Scrap__c > 0) {
                            SKID__c scrapSkid = skidTemplate.clone(false, true);
                            scrapSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                            scrapSkid.Quantity__c = sw.skid.Quantity_To_Scrap__c;
                            scrapSkid.Quantity_Stocking_UOM__c = scrapSkid.Quantity__c * sw.conversionFactor;
                            scrapSkid.Location__c = wo.MRB_Location__c;
                            scrapSkid.Location__r = wo.MRB_Location__r;
                            scrapSkid.Consigned_Owner__c = null;
                            scrapSkid.Purchase_Order_Line__c = null;
                            if (sw.toskid != null) {
                                scrapSkid.Bin__c = sw.toskid.Bin__c;
                                scrapSkid.Bin__r = sw.toskid.Bin__r;
                            } else {
                                scrapSkid.Bin__c = null;
                                scrapSkid.Bin__r = null;
                            }
                            skidsToPutaway.add(new SkidService3.SerialWrapper(scrapSkid, serialsToScrap));

                            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(mt.Item__r, mt, 'Work Order Component Scrap', sw.skid.Quantity_To_Scrap__c, wipSkid, scrapSkid, attributes);
                            it.Operation_Tracking__c = op.Id;
                            itInfo.itList.add(it);
                            if (serialsToScrap.size() > 0) serialsForTransactions.put(SkidService3.generateKey(it, attributes), new SkidService3.SerialWrapper(it, serialsToScrap));

                            mtToUpdate.Quantity_Scrapped__c += it.Quantity_Stocking_UOM__c;
                        }
                    } else {
                        if (!(sw.skid.Quantity__c > 0)) continue;

                        SKID__c skid = new SKID__c(
                            Company__c = wo.Company__c,
                            Type__c = SkidService3.SKID_TYPE_LOCATION,
                            Quantity__c = sw.skid.Quantity__c,
                            Quantity_Stocking_UOM__c = sw.skid.Quantity__c * sw.conversionFactor,
                            Stocking_UOM__c = mt.Item__r.Stocking_UOM__c,
                            Item__c = mt.Item__c,
                            Item__r = mt.Item__r,
                            Facility2__c = wo.Facility__c,
                            Facility2__r = wo.Facility__r
                        );
                        SkidService3.copyAttributes(sw.skid, skid, attributes, new Set<String>{ 'Material_Tracking__c' });
                        skidsToPutaway.add(new SkidService3.SerialWrapper(skid, sw.serialList));

                        Inventory_Transaction__c it = SkidService3.createInventoryTransaction(mt.Item__r, mt, 'By-product', skid.Quantity__c, null, skid, attributes);
                        it.Operation_Tracking__c = op.Id;
                        itInfo.itList.add(it);
                        if (sw.serialList.size() > 0) serialsForTransactions.put(SkidService3.generateKey(it, attributes), new SkidService3.SerialWrapper(it, sw.serialList));

                        mtToUpdate.Quantity_Completed__c += skid.Quantity_Stocking_UOM__c;
                    }
                }
            }

            if (itData.containskey(wo.Id) == false) itData.put(wo.Id, itInfo);
            else itData.get(wo.Id).itList.addAll(itInfo.itList);
        }

        if (repairMaterialSkids.size() > 0) {
            Set<Id> repairWoIds = repairMaterialSkids.keySet();
            SOQLUtil materialQuery = new SOQLUtil('Material_Tracking__c');
            materialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Quantity_Used__c', 'Work_Order__c' });
            materialQuery.setWhereClause('Work_Order__c IN :repairWoIds AND Type__c = :MATERIAL_TYPE_REPAIR');
            for (Material_Tracking__c mt:Database.query(materialQuery.getQuery())) {
                SkidService3.SerialWrapper repairMaterialSw = repairMaterialSkids.get(mt.Work_Order__c);
                repairMaterialSw.skid.Material_Tracking__c = mt.Id;

                Inventory_Transaction__c it = repairMaterialSw.it;
                it.Material_Tracking__c = mt.Id;
                it.From_SKID__r.Material_Tracking__c = mt.Id;
                repairMaterialSw.it = null;

                if (repairMaterialSw.serialList.size() > 0) {
                    List<String> key = SkidService3.generateKey(it.From_SKID__r, attributes);
                    key.addAll(SkidService3.generateKey(it.To_SKID__r, attributes));
                    serialsForTransactions.put(key, new SkidService3.SerialWrapper(it, repairMaterialSw.serialList));
                    repairMaterialSw.serialList = new List<Serial__c>();
                }

                materialsToUpdate.put(mt.Id, new Material_Tracking__c(Id = mt.Id, Quantity_Used__c = mt.Quantity_Used__c - repairMaterialSw.skid.Quantity_Stocking_UOM__c));
            }
        }

        if (skidsToPutaway.size() > 0) {
            Map<List<String>, SkidService3.SerialWrapper> putawaySkids = SkidService3.putAwayService(skidsToPutaway, attributes, new Map<String, Boolean>{ SkidService3.MIXED_SERIAL => true, SkidService3.ALLOW_SERIAL_REENTRY => false });

            if (itData.size() > 0) {
                for (SkidService3.ParameterData itInfo:itData.values()) {
                    for (Inventory_Transaction__c it:itInfo.itList) {
                        if (it.From_SKID__r != null) it.From_SKID__c = putawaySkids.get(SkidService3.generateKey(it.From_SKID__r, attributes)).skid.Id;
                        it.To_SKID__c = putawaySkids.get(SkidService3.generateKey(it.To_SKID__r, attributes)).skid.Id;
                    }
                }
                SkidService3.inventoryTransactionsForPutaway(itData, attributes, serialsForTransactions, new Map<String,String>{ 'transferofowner' => 'true', 'consume' => 'true', 'adjustFromSkidQuantity' => null, 'deleteToSkids' => 'false' });
            }

            SkidService3.deleteSkids(putawaySkids.values());
        }

        allowWorkOrderUpdate = true;
        if (wosToUpdate.size() > 0) {
            woIds = wosToUpdate.keySet();
            SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
            woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Completed__c', 'Date_Completed2__c', 'Order_Quantity_Stocking_UOM__c', 'Quantity_Complete__c',
                'Quantity_Complete_Stocking_UOM__c', 'Quantity_Scrapped__c', 'Quantity_Scrapped_Stocking_UOM__c' });
            woQuery.setWhereClause('Id IN :woIds');
            Map<Id, Work_Order__c> queriedWorkOrders = new Map<Id, Work_Order__c>((List<Work_Order__c>)Database.query(woQuery.getQuery()));

            for (Work_Order__c wo:wosToUpdate.values()) {
                Work_Order__c queriedWorkOrder = queriedWorkOrders.get(wo.Id);
                wo.Completed__c = KSE.addQuantityToField(queriedWorkOrder.Completed__c, wo.Completed__c);
                wo.Quantity_Complete__c = KSE.addQuantityToField(queriedWorkOrder.Quantity_Complete__c, wo.Quantity_Complete__c);
                wo.Quantity_Complete_Stocking_UOM__c = KSE.addQuantityToField(queriedWorkOrder.Quantity_Complete_Stocking_UOM__c, wo.Quantity_Complete_Stocking_UOM__c);
                wo.Quantity_Scrapped__c = KSE.addQuantityToField(queriedWorkOrder.Quantity_Scrapped__c, wo.Quantity_Scrapped__c);
                wo.Quantity_Scrapped_Stocking_UOM__c = KSE.addQuantityToField(queriedWorkOrder.Quantity_Scrapped_Stocking_UOM__c, wo.Quantity_Scrapped_Stocking_UOM__c);

                if ((wo.Quantity_Complete_Stocking_UOM__c + wo.Quantity_Scrapped_Stocking_UOM__c) >= queriedWorkOrder.Order_Quantity_Stocking_UOM__c) {
                    wo.Status__c = WO_STATUS_COMPLETE;
                    wo.Date_Completed2__c = queriedWorkOrder.Date_Completed2__c == null ? System.now() : queriedWorkOrder.Date_Completed2__c;
                } else {
                    wo.Status__c = WO_STATUS_IN_PROCESS;
                }
            }

            DML.updateAsUser(wosToUpdate.values());
        }

        if (opsToUpdate.size() > 0) {
            Set<Id> opIds = opsToUpdate.keySet();
            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addFields(new Set<String>{ 'Id', 'Name', 'Hours_Consumed__c', 'Quantity_Completed__c', 'Quantity_Scrapped__c', 'Quantity_Available__c' });
            opQuery.setWhereClause('Id IN :opIds');
            Map<Id, Operation_Tracking__c> queriedOperations = new Map<Id, Operation_Tracking__c>((List<Operation_Tracking__c>)Database.query(opQuery.getQuery()));

            for (Operation_Tracking__c op:opsToUpdate.values()) {
                Operation_Tracking__c queriedOperation = queriedOperations.get(op.Id);
                op.Hours_Consumed__c = KSE.addQuantityToField(queriedOperation.Hours_Consumed__c, op.Hours_Consumed__c);
                op.Quantity_Completed__c = KSE.addQuantityToField(queriedOperation.Quantity_Completed__c, op.Quantity_Completed__c);
                op.Quantity_Scrapped__c = KSE.addQuantityToField(queriedOperation.Quantity_Scrapped__c, op.Quantity_Scrapped__c);
                op.Quantity_Available__c = KSE.addQuantityToField(queriedOperation.Quantity_Available__c, op.Quantity_Available__c);
            }

            DML.updateAsUser(opsToUpdate.values());
        }

        if (otsToInsert.size() > 0) DML.insertAsUser(otsToInsert.values());
        if (stsToInsert.size() > 0) {
            List<Serial_Transaction__c> stList = new List<Serial_Transaction__c>();
            for (Id opId:stsToInsert.keySet()) {
                for (Serial_Transaction__c st:stsToInsert.get(opId)) {
                    st.Operation_Transaction__c = otsToInsert.get(opId).Id;
                    stList.add(st);
                }
            }
            DML.insertAsSystem(stList);
        }
        if (materialsToUpdate.size() > 0) DML.updateAsUser(materialsToUpdate.values());
        allowWorkOrderUpdate = false;

        if (skidsToAllocate.size() > 0) {
            try {
                AllocationService.autoAllocate(skidsToAllocate);
            } catch (Exception e) {
                throw new CustomException('Unable to auto-allocate: ' + e.getMessage());
            }
        }
    }

    private static Work_Order__c newWorkOrder(Work_Order__c wo) {
        return new Work_Order__c(Id = wo.Id, Quantity_Complete__c = wo.Quantity_Complete__c, Quantity_Scrapped__c = wo.Quantity_Scrapped__c, Status__c = wo.Status__c, Completed__c = wo.Completed__c, Quantity_Complete_Stocking_UOM__c = wo.Quantity_Complete_Stocking_UOM__c,Quantity_Scrapped_Stocking_UOM__c = wo.Quantity_Scrapped_Stocking_UOM__c);
    }
    private static Operation_Tracking__c newOpTracking(Operation_Tracking__c op) {
        return new Operation_Tracking__c(Id = op.Id, Hours_Consumed__c = op.Hours_Consumed__c, Quantity_Completed__c = op.Quantity_Completed__c, Quantity_Scrapped__c = op.Quantity_Scrapped__c, Quantity_Available__c = op.Quantity_Available__c);
    }
    private static Material_Tracking__c newMaterialTracking(Material_Tracking__c material) {
        return new Material_Tracking__c(Id = material.Id, Quantity_Allocated__c = material.Quantity_Allocated__c, Quantity_Issued__c = material.Quantity_Issued__c, Quantity_Used__c = material.Quantity_Used__c, Quantity_Scrapped__c = material.Quantity_Scrapped__c, Quantity_Completed__c = material.Quantity_Completed__c);
    }
    private static Operation_Transaction__c newOpTransaction(Operation_Tracking__c op) {
    	return new Operation_Transaction__c(Operation_Sequence__c = op.Sequence__c, Operation_Tracking__c = op.Id, Work_Order__c = op.Work_Order__c, Hours_Consumed__c = 0, Quantity_Completed__c = 0, Quantity_Scrapped__c = 0);
    }

    public class CompleteWrapper {
        public Work_Order__c wo { get; set; }
        public Operation_Tracking__c op { get; set; }
        public Operation_Tracking__c nextOp { get; set; }
        public SkidService3.SerialWrapper assemblyInfo { get; set; }
        public List<WorkOrderWrapper> componentInfo { get; set; } { componentInfo = new List<WorkOrderWrapper>(); }
        public Operation_Transaction__c ot { get; set; }
        public Decimal hoursConsumed { get; set; } { hoursConsumed = 0; }
        public Boolean lastOp { get; set; } { lastOp = false; }

        public CompleteWrapper(Work_Order__c wo,Operation_Tracking__c op,Operation_Tracking__c nextOp,SkidService3.SerialWrapper assemblyInfo,List<WorkOrderWrapper> componentInfo,Decimal hoursConsumed,Boolean lastOp) {
            this.wo = wo;
            this.op = op;
            this.nextOp = nextOp;
            this.assemblyInfo = assemblyInfo;
            if (componentInfo != null) this.componentInfo = componentInfo;
            if (hoursConsumed != null) this.hoursConsumed = hoursConsumed;
            if (lastOp != null) this.lastOp = lastOp;
        }
    }

    public static void autoComplete(List<ReceivingWrapper> rWrappers) {
        List<String> attributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'location__c', 'bin__c' });
        attributes.add('Customer__c');
        attributes.add('Sales_Order_Line__c');

        Set<Id> woIds = new Set<Id>();
        for (ReceivingWrapper rWrapper:rWrappers) {
            Purchase_Order_Line__c pol = rWrapper.pol;
            if (pol.Operation_Tracking__c == null) throw new CustomException(pol.Name + ': No operation tracking is found on the purchase order line.');
            woIds.add(pol.Operation_Tracking__r.Work_Order__c);
        }

        Map<Id, Work_Order__c> workOrders = new Map<Id, Work_Order__c>((List<Work_Order__c>)Database.query(WorkOrderCompleteExtV2.getWorkOrderQuery('Id IN :woIds')));

        Map<Id, CompleteWrapper> wrappers = new Map<Id, CompleteWrapper>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        for (ReceivingWrapper rWrapper:rWrappers) {
            Purchase_Order_Line__c pol = rWrapper.pol;
            Work_Order__c wo = workOrders.get(pol.Operation_Tracking__r.Work_Order__c);
            Operation_Tracking__c op;
            Operation_Tracking__c nextOp;
            for (Integer i = 1; i < wo.Number_of_Operations__c; i++) {
                Operation_Tracking__c operation = wo.Operation_Trackings__r[i];
                if (operation.Id == pol.Operation_Tracking__c) {
                    op = operation;
                    nextOp = wo.Operation_Trackings__r[i - 1];
                    break;
                }
            }

            wrappers.put(op.Id, new CompleteWrapper(wo, op, nextOp, null, null, null, false));

            if (packagingUoms.containsKey(wo.Item__c) == false) packagingUoms.put(wo.Item__c, (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class));
        }

        Map<Id, List<SkidService3.SerialWrapper>> assemblyMap = getCompleteAssemblyData(wrappers.values());
        Map<Id, List<WorkOrderWrapper>> backflushData = getCompleteBackflushData(wrappers.values());

        Map<Id, Decimal> qtyAvailableMap = new Map<Id, Decimal>();
        Map<String, Decimal> qtyTaken = new Map<String, Decimal>();
        for (ReceivingWrapper rWrapper:rWrappers) {
            Purchase_Order_Line__c pol = rWrapper.pol;
            CompleteWrapper wrapper = wrappers.get(pol.Operation_Tracking__c);
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;

            Map<List<String>, SkidService3.SerialWrapper> assemblies = new Map<List<String>, SkidService3.SerialWrapper>();
            for (SkidService3.SerialWrapper assembly:assemblyMap.get(op.Id)) assemblies.put(SkidService3.generateKey(assembly.skid, attributes), assembly);

            SkidService3.SerialWrapper assemblySw = rWrapper.serialWrapperList[0];
            assemblySw.skid.Item__c = wo.Item__c;
            assemblySw.skid.Item__r = wo.Item__r;
            assemblySw.skid.Container_Item__r = SkidService3.getContainerforItem(wo.Item__r, assemblySw.skid.Packaging_UOM__r);
            assemblySw.skid.Container_Item__c = assemblySw.skid.Container_Item__r.Id;

            List<String> skidKey = SkidService3.generateKey(assemblySw.skid, attributes);
            SkidService3.SerialWrapper assembly;
            if (assemblies.containsKey(skidKey) == true) {
                assembly = assemblies.get(skidKey);
            } else {
                assembly = WorkOrderCompleteExtV2.generateNewAssembly(wo);
                SkidService3.copyAttributes(assemblySw.skid, assembly.skid, attributes);
            }
            assembly.skid.Item__r = wo.Item__r;
            assembly.skid.Quantity_Used__c = assemblySw.skid.Quantity__c;
            assembly.skid.Input_Quantity__c = 0;
            
            List<Id> pkgUoms = packagingUoms.get(wo.Item__c);
            Decimal convFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__c, pkgUoms);
                   
            if (assembly.skid.Quantity_Used__c > 0) {
                if (op.Backflush_Resource__c == true) assembly.skid.Input_Quantity__c = op.Standard_Hours__c * (op.Fixed_Hours__c == true ? 1 : (assembly.skid.Quantity_Used__c / convFactor));
            }
		   
		    Map<String, Serial__c> serialMap = new Map<String, Serial__c>();
            for (Serial__c serial:assembly.serialList) serialMap.put(serial.Name, serial);
            List<Serial__c> serials = new List<Serial__c>();
            for (Serial__c serial:assemblySw.serialList) {
                if (serialMap.containsKey(serial.Name) == true) {
                    Serial__c existingSerial = serialMap.get(serial.Name);
                    if (existingSerial.Temporary_Value_Holder__c != 'Completed') {
                        existingSerial.Temporary_Value_Holder__c = 'Complete' + (String.isBlank(existingSerial.Temporary_Value_Holder__c) == false ? ('|' + existingSerial.Temporary_Value_Holder__c) : '');
                        serials.add(existingSerial);
                    } else {
                        throw new CustomException(wo.Name + ': You can\'t record a serial (' + serial.Name + ') that has already been recorded');
                    }
                } else {
                    serials.add(new Serial__c(Name = serial.Name, Temporary_Value_Holder__c = 'Complete'));
                }
            }
            assembly.serialList = serials;

            wrapper.assemblyInfo = assembly;

            if (backflushData.containsKey(wo.Id) == true) {
                Decimal qtyToComplete = assembly.skid.Quantity_Used__c / KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__c, packagingUoms.get(wo.Item__c));

                for (WorkOrderWrapper wow:backflushData.get(wo.Id)) {
                    Material_Tracking__c mt = wow.material;

                    if (mt.Operation_Tracking__c != op.Id || (mt.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP && mt.Supplier__c != pol.Supplier__c)) continue;

                    Decimal yield = mt.Yield__c != null ? (mt.Yield__c / 100) : 1;
                    Decimal qtyToIssue = (qtyToComplete * mt.Quantity_Per_Assembly__c) / yield;

                    List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                    for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                        Decimal qtyAvailable = sw.skid.Quantity_Stocking_UOM__c;
                        if (qtyAvailableMap.containsKey(sw.skid.Id) == true) qtyAvailable = Math.min(qtyAvailable, qtyAvailableMap.get(sw.skid.Id));
                        if (String.isBlank(sw.skid.Temporary_Value_Holder__c) == false) qtyAvailable = Math.min(qtyAvailable, sw.skid.Quantity_Required__c - (qtyTaken.containsKey(sw.skid.Temporary_Value_Holder__c) == true ? qtyTaken.get(sw.skid.Temporary_Value_Holder__c) : 0));
                        if (String.isBlank(sw.skid.Temporary_Value_Holder1__c) == false) qtyAvailable = Math.min(qtyAvailable, sw.skid.Total_Material__c - (qtyTaken.containsKey(sw.skid.Temporary_Value_Holder1__c) == true ? qtyTaken.get(sw.skid.Temporary_Value_Holder1__c) : 0));

                        sw.skid.Quantity_to_Issue__c = Math.max(Math.min(qtyAvailable, qtyToIssue) / sw.conversionFactor, 0);

                        if (sw.skid.Quantity_to_Issue__c > 0) {
                            Decimal qtyIssued = sw.skid.Quantity_to_Issue__c * sw.conversionFactor;
                            qtyToIssue -= qtyIssued;

                            qtyAvailableMap.put(sw.skid.Id, (qtyAvailableMap.containsKey(sw.skid.Id) == true ? qtyAvailableMap.get(sw.skid.Id) : sw.skid.Quantity_Stocking_UOM__c) - qtyIssued);
                            if (String.isBlank(sw.skid.Temporary_Value_Holder__c) == false) qtyTaken.put(sw.skid.Temporary_Value_Holder__c, KSE.addQuantityToField(qtyTaken.get(sw.skid.Temporary_Value_Holder__c), 0) + qtyIssued);
                            if (String.isBlank(sw.skid.Temporary_Value_Holder1__c) == false) qtyTaken.put(sw.skid.Temporary_Value_Holder1__c, KSE.addQuantityToField(qtyTaken.get(sw.skid.Temporary_Value_Holder1__c), 0) + qtyIssued);

                            swList.add(sw);
                        }
                    }

                    if (swList.size() > 0) {
                        wow.serialWrapperList = swList;
                        wrapper.componentInfo.add(wow);
                    }
                }
            }
        }

        complete(wrappers.values(), true, false);
    }


    /*
     * UNCOMPLETE SECTION
     */
    public static Map<Id,String> validateForUncomplete(List<Work_Order__c> workOrders) {
        Map<Id,String> errors = new Map<Id,String>();

        for (Work_Order__c wo:workOrders) {
            if (wo.Status__c  == WO_STATUS_CLOSED) {
                errors.put(wo.Id,Label.WorkOrder_already_closed);
            } else if (wo.Status__c  == WO_STATUS_DRAFT) {
                errors.put(wo.Id,Label.WorkOrder_not_released);
            } else if (wo.Status__c  == WO_STATUS_CANCELLED) {
                errors.put(wo.Id,Label.WorkOrder_cancelled);
            }

        }

        return errors;
    }

    public static List<SkidService3.SerialWrapper> getUncompleteAssemblyData(List<UncompleteWrapper> uncompleteWrappers) {
        List<String> attributes = SkidService3.attributesForPutaway(null,new Set<String>{'shipment_line__c'});
        attributes.add('Customer__c');
        attributes.add('Work_Order__c');

        List<String> attributesWithoutLocationBin = SkidService3.attributesForPutaway(null,new Set<String>{'shipment_line__c', 'location__c','bin__c'});
        attributesWithoutLocationBin.add('Customer__c');
        attributesWithoutLocationBin.add('Work_Order__c');

        Set<Id> lastOpWorkOrders = new Set<Id>();
        Set<Id> notLastOpWorkOrders = new Set<Id>();
        set<Id> workOrders = new set<Id>();
        Set<Id> opIds = new Set<Id>();
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>> ();
        Map<Id,UncompleteWrapper> wrapperMap = new Map<Id,UncompleteWrapper>();
        for (UncompleteWrapper wrapper:uncompleteWrappers) {
            Work_Order__c wo = wrapper.wo;

            workOrders.add(wo.Id);
            opIds.add(wrapper.op.Id);
            wrapperMap.put(wo.Id,wrapper);

            if (wrapper.last) {
                lastOpWorkOrders.add(wo.Id);
            } else {
                notLastOpWorkOrders.add(wo.Id);
            }
        }

        //the map with location and bin is needed to query the existing finished good skid and match against it further down
        Map<Id,Map<List<String>,SKID__c>> assemblySkidMap = new Map<Id,Map<List<String>,SKID__c>>();
        Map<Id,Map<List<String>,SKID__c>> assemblySkidWithoutLocationMap = new Map<Id,Map<List<String>,SKID__c>>();
        Map<Id,Map<List<String>,Set<Id>>> assemblySerialMap = new Map<Id,Map<List<String>,Set<Id>>>();
        List<SKID__c> skids = new List<SKID__c>();
        String whereClause = 'Inventory_Change__r.Work_Order__c IN :workOrders AND Type__c IN (\'Work Order Assembly Completion\', \'Work Order Repair Assembly Completion\', \'Work Order Assembly Uncompletion\', \'Work Order Repair Assembly Uncompletion\')';
        for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'CreatedDate ASC', 'SERIALS' => 'true' }))) {
            SKID__c skid = it.Type__c == 'Work Order Assembly Completion' || it.Type__c == 'Work Order Repair Assembly Completion' ? SkidService3.generateToSkid(it, attributes) : SkidService3.generateFromSkid(it, attributes);
            skid.Company__c = it.Company__c;
            skid.Quantity__c = 0;
            skid.Quantity_Available__c = 0;
            skid.Quantity_To_Return__c = 0;
            skid.Quantity_Short__c = 0;
            skid.Input_Quantity__c = 0;
            skid.Type__c = (it.Type__c == 'Work Order Repair Assembly Completion' || it.Type__c == 'Work Order Repair Assembly Uncompletion') && it.Inventory_Change__r.Work_Order__r.Field_Service__c == true ? SkidService3.SKID_TYPE_INSTALLBASE : SkidService3.SKID_TYPE_LOCATION;
            if (it.Type__c == 'Work Order Assembly Completion' || it.Type__c == 'Work Order Repair Assembly Completion') skid.Temporary_Value_Holder__c = it.From_SKID_Identifier__c;
			if(it.Type__c == 'Work Order Repair Assembly Completion' && it.Sales_Order_Line__c!=null){
				skid.Sales_Order_Line__c = it.Sales_Order_Line__c;
			}
            SKID__c skidWithoutLocation = skid.Clone(true, true);
            skidWithoutLocation.Location__c = null;
            skidWithoutLocation.Bin__c = null;

            if (!assemblySkidMap.containsKey(it.Inventory_Change__r.Work_Order__c)) {
                assemblySkidMap.put(it.Inventory_Change__r.Work_Order__c,new Map<List<String>,SKID__c>());
                assemblySkidWithoutLocationMap.put(it.Inventory_Change__r.Work_Order__c,new Map<List<String>,SKID__c>());
                assemblySerialMap.put(it.Inventory_Change__r.Work_Order__c,new Map<List<String>,Set<Id>>());
            }

            Map<List<String>,SKID__c> skidMap = assemblySkidMap.get(it.Inventory_Change__r.Work_Order__c);
            Map<List<String>,SKID__c> skidWithoutLocationMap = assemblySkidWithoutLocationMap.get(it.Inventory_Change__r.Work_Order__c);
            Map<List<String>,Set<Id>> serialMap = assemblySerialMap.get(it.Inventory_Change__r.Work_Order__c);
            List<String> key = SkidService3.generateKey(skid,attributes);
            List<String> keyWithoutLocation = SkidService3.generateKey(skidWithoutLocation,attributesWithoutLocationBin);
            if (!skidMap.containsKey(key)) {
                skidMap.put(key,skid);
                serialMap.put(key,new Set<Id>());
                skids.add(skid);
            }

            if(!skidWithoutLocationMap.containsKey(keyWithoutLocation)){
                skidWithoutLocationMap.put(keyWithoutLocation, skidWithoutLocation);
            }

            skid = skidMap.get(key);
            skidWithoutLocation = skidWithoutLocationMap.get(keyWithoutLocation);
            Set<Id> serialIds = serialMap.get(key);

            if ( !itemPackagingUomCache.containsKey(it.Item__c) ) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize(it.Item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUomCache.put(it.Item__c, lstPkgUom );
            }

            Decimal netQuantity = it.Net_Quantity__c / KSE.getConversionFactor ( it.Item__c, it.To_Facility__r.Facility_Identifier__c, it.Packaging_UOM__c, it.Stocking_UOM__c, itemPackagingUomCache.get(it.Item__c) ) ; // conversion factor
            //using quantity short to hold the net quantity completed, used for populating component quantity later as well
            skid.Quantity_Short__c += netQuantity;
            skidWithoutLocation.Quantity_Short__c += netQuantity;

            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                if (it.Type__c == 'Work Order Assembly Completion' || it.Type__c == 'Work Order Repair Assembly Completion') {
                    serialIds.add(st.Serial__c);
                } else if (it.Type__c == 'Work Order Assembly Uncompletion' || it.Type__c == 'Work Order Repair Assembly Uncompletion') {
                    serialIds.remove(st.Serial__c);
                }
            }

            if(skidWithoutLocation.Quantity_Short__c == 0){
                skidWithoutLocationMap.remove(keyWithoutLocation);
            }

            if (skid.Quantity_Short__c == 0) {
                skidMap.remove(key);
                serialMap.remove(key);
            }
        }

        // get operation transaction and serial transactions
        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addFields(new set<String>{'Work_Order__r.Complete_To_Location__c'});
        otQuery.addAllCustomFields(Operation_Tracking__c.sObjectType,'Operation_Tracking__r');
        otQuery.setWhereClause('Operation_Tracking__c IN :opIds');
        otQuery.setOrderByClause('CreatedDate ASC');

        SOQLUtil.ChildRelationship stQuery2 = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery2.addFields(new Set<String>{ 'Id', 'Name', 'Serial__c' });
        otQuery.addChildRelationship(stQuery2);

        Map<Id,Map<List<String>,Decimal>> hoursConsumed = new Map<Id,Map<List<String>,Decimal>>();
        Map<Id, Set<List<String>>> processedKeys = new Map<Id, Set<List<String>>>();
        Map<Id,Map<List<String>,Decimal>> qtyCompleted = new Map<Id,Map<List<String>,Decimal>>();
        Map<Id,Map<List<String>,Decimal>> totalQtyCompleted = new Map<Id,Map<List<String>,Decimal>>();
        Map<Id,Set<Id>> serialsCompletedMap = new Map<Id,Set<Id>>();

        // Tracking the completion by qty or hours consumed
        for (Operation_Transaction__c ot:Database.query(otQuery.getQuery())) {
            UncompleteWrapper wrapper = wrapperMap.get(ot.Work_Order__c);

            Operation_Transaction__c otForKey = ot.clone(true,true);
            otForKey.Work_Order__c = null;

            List<String> key = SkidService3.generateKey(otForKey,attributesWithoutLocationBin);

            if (ot.Quantity_Completed__c != 0 || ot.Quantity_Scrapped__c != 0) {
                if (totalQtyCompleted.containsKey(ot.Operation_Tracking__c) == false) totalQtyCompleted.put(ot.Operation_Tracking__c, new Map<List<String>, Decimal>());
                totalQtyCompleted.get(ot.Operation_Tracking__c).put(key, KSE.addQuantityToField(totalQtyCompleted.get(ot.Operation_Tracking__c).get(key), ot.Quantity_Completed__c + ot.Quantity_Scrapped__c));

                if (ot.Quantity_Completed__c != 0) {
                    if (qtyCompleted.containsKey(ot.Operation_Tracking__c) == false) qtyCompleted.put(ot.Operation_Tracking__c, new Map<List<String>, Decimal>());
                    qtyCompleted.get(ot.Operation_Tracking__c).put(key, KSE.addQuantityToField(qtyCompleted.get(ot.Operation_Tracking__c).get(key), ot.Quantity_Completed__c));

                    if (processedKeys.containsKey(ot.Operation_Tracking__c) == false) processedKeys.put(ot.Operation_Tracking__c, new Set<List<String>>());
                    if (processedKeys.get(ot.Operation_Tracking__c).contains(key) == false && assemblySkidWithoutLocationMap.containsKey(ot.Work_Order__c) == true && assemblySkidWithoutLocationMap.get(ot.Work_Order__c).containsKey(key) == true) {
                        qtyCompleted.get(ot.Operation_Tracking__c).put(key, KSE.subtractDecimals(qtyCompleted.get(ot.Operation_Tracking__c).get(key), assemblySkidWithoutLocationMap.get(ot.Work_Order__c).get(key).Quantity_Short__c));
                        processedKeys.get(ot.Operation_Tracking__c).add(key);
                    }

                    if (qtyCompleted.get(ot.Operation_Tracking__c).get(key) == 0) qtyCompleted.get(ot.Operation_Tracking__c).remove(key);

                    for (Serial_Transaction__c st:ot.Serial_Transactions__r) {
                        if (serialsCompletedMap.containsKey(ot.Operation_Tracking__c) == false) serialsCompletedMap.put(ot.Operation_Tracking__c, new Set<Id>());

                        if (ot.Quantity_Completed__c > 0) serialsCompletedMap.get(ot.Operation_Tracking__c).add(st.Serial__c);
                        else serialsCompletedMap.get(ot.Operation_Tracking__c).remove(st.Serial__c);
                    }
                }
            }

            if (ot.Hours_Consumed__c != 0) {
                if (ot.Quantity_Completed__c == 0 && ot.Quantity_Scrapped__c == 0) key = null;
                else if (wrapper.last == true) key = SkidService3.generateKey(otForKey, attributes);

                if (hoursConsumed.containsKey(ot.Operation_Tracking__c) == false) hoursConsumed.put(ot.Operation_Tracking__c, new Map<List<String>, Decimal>{ key => ot.Hours_Consumed__c });
                else hoursConsumed.get(ot.Operation_Tracking__c).put(key, KSE.addQuantityToField(hoursConsumed.get(ot.Operation_Tracking__c).get(key), ot.Hours_Consumed__c));

                if (hoursConsumed.get(ot.Operation_Tracking__c).get(key) == 0) hoursConsumed.get(ot.Operation_Tracking__c).remove(key);
                if (hoursConsumed.get(ot.Operation_Tracking__c).size() == 0) hoursConsumed.remove(ot.Operation_Tracking__c);
            }
        }

        List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
        Boolean populated = false;

        if (lastOpWorkOrders.size() > 0) {

            Map<List<String>, SKID__c> existingSkids = new Map<List<String>, SKID__c>();
            Map<Id, List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
            if (skids.size() > 0) {
                existingSkids = SkidService3.generateExistingSkidMap(attributes, skids, false, null);

                if (existingSkids.size() > 0) {
                    Set<Id> skidIds = new Set<Id>();
                    for (SKID__c skid:existingSkids.values()) skidIds.add(skid.id);

                    SOQLUtil serialQuery = new SOQLUtil('Serial__c');
                    serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Allocated_SKID__c', 'Allow_Reentry__c', 'Company__c', 'Item__c', 'SKID__c', 'Temporary_Value_Holder__c' });
                    serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
                    serialQuery.addFields('Serial');
                    serialQuery.setWhereClause('SKID__c IN :skidIds');
                    for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                        if (!serialMap.containsKey(serial.SKID__c)) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
                        else serialMap.get(serial.SKID__c).add(serial);
                    }
                }
            }

            for (Id woId:assemblySkidMap.keySet()) {
                UncompleteWrapper wrapper = wrapperMap.get(woId);
                Work_Order__c wo = wrapper.wo;
                Id opId = wrapper.op.Id;
                List<Id> pkgUoms = (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class);

                for (List<String> key:assemblySkidMap.get(woId).keySet()) {
                    if (existingSkids.containsKey(key) == false) continue;

                    SKID__c skid = assemblySkidMap.get(woId).get(key);
                    SKID__c existingSkid = existingSkids.get(key);

                    List<Serial__c> serials = new List<Serial__c>();
                    if (serialMap.containsKey(existingSkid.Id) == true) {
                        Map<Id, Serial__c> existingSerials = new Map<Id, Serial__c>(serialMap.get(existingSkid.Id));
                        for (Id serialId:assemblySerialMap.get(woId).get(key)) {
                            if (existingSerials.containsKey(serialId) == true) serials.add(existingSerials.get(serialId));
                        }

                        skid.Quantity_Available__c = serials.size() / KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, skid.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, pkgUoms);
                    } else {
                        skid.Quantity_Available__c = Math.min(skid.Quantity_Short__c, existingSkid.Quantity__c);
                    }

                    if (skid.Quantity_Available__c > 0) {
                        skid.Id = existingSkid.Id;
                        skid.Quantity__c = existingSkid.Quantity__c;
                        skid.Item__r = existingSkid.Item__r;
                        skid.Quantity_Short__c = totalQtyCompleted.get(opId).get(SkidService3.generateKey(skid, attributesWithoutLocationBin));

                        if (populated == false) {
                            skid.Quantity_To_Return__c = skid.Quantity_Available__c;

                            if (hoursConsumed.containsKey(opId) == true) {
                                if (hoursConsumed.get(opId).containsKey(key) == true) skid.Input_Quantity__c += hoursConsumed.get(opId).get(key);
                                if (hoursConsumed.get(opId).containsKey(null) == true) skid.Input_Quantity__c += hoursConsumed.get(opId).get(null);
                                skid.Input_Quantity__c = (skid.Input_Quantity__c / skid.Quantity_Short__c) * skid.Quantity_To_Return__c;
                            }

                            populated = true;
                        }

                        swList.add(new SkidService3.SerialWrapper(skid, serials));
                    }
                }
            }
        }

        if (notLastOpWorkOrders.size() > 0) {
            whereClause = 'Type__c = \'' + SkidService3.SKID_TYPE_WIP + '\' AND Work_Order__c IN :notLastOpWorkOrders AND Quantity__c > 0';

            Set<Id> skidIds = new Set<Id>();
            Map<Id,List<SKID__c>> wipSkids = new Map<Id,List<SKID__c>>();
            for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause }))) {
                if (!wipSkids.containsKey(skid.Work_Order__c)) {
                    wipSkids.put(skid.Work_Order__c,new List<SKID__c>());
                }
                wipSkids.get(skid.Work_Order__c).add(skid);
                skidIds.add(skid.id);
            }

            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
	        serialQuery.addAllCustomFields();
	        serialQuery.setWhereClause('Skid__c IN :skidIds ');

	        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
	        for (Serial__c serial:Database.query(serialQuery.getQuery())) {
	        	if (!serialMap.containsKey(serial.SKID__c)) {
	        		serialMap.put(serial.SKID__c,new List<Serial__c>());
	        	}
	        	serialMap.get(serial.SKID__c).add(serial);
	        }

            for (Id woId:notLastOpWorkOrders) {
                UncompleteWrapper wrapper = wrapperMap.get(woId);
                Work_Order__c wo = wrapper.wo;
                Id opId = wrapper.op.Id;
                List<Id> pkgUoms = (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class);

                if (wipSkids.containsKey(wo.Id) == false) continue;

                Map<List<String>, Decimal> completedQty = qtyCompleted.containsKey(opId) == true ? qtyCompleted.get(opId) : new Map<List<String>, Decimal>();
                Map<List<String>, Decimal> totalCompletedQty = totalQtyCompleted.containsKey(opId) == true ? totalQtyCompleted.get(opId) : new Map<List<String>, Decimal>();
                Set<Id> serialsCompleted = serialsCompletedMap.containsKey(opId) == true ? serialsCompletedMap.get(opId) : new Set<Id>();

                for (SKID__c skid:wipSkids.get(wo.Id)) {
                    SKID__c skidClone = skid.clone(false, true);
                    skidClone.Work_Order__c = null;

                    List<String> keyNoLocBin = SkidService3.generateKey(skidClone, attributesWithoutLocationBin);

                    List<Serial__c> serials = new List<Serial__c>();
                    if (serialMap.containsKey(skid.Id) == true) {
                        for (Serial__c serial:serialMap.get(skid.Id)) {
                            if (serialsCompleted.contains(serial.Id) == true) serials.add(serial);
                        }

                        skid.Quantity_Available__c = serials.size() / KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, skid.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, pkgUoms);
                    } else {
                        skid.Quantity_Available__c = completedQty.containsKey(keyNoLocBin) == true ? completedQty.get(keyNoLocBin) : 0;
                    }

                    if (skid.Quantity_Available__c > 0) {
                        skid.Item__r = wo.Item__r;
                        skid.Quantity_To_Return__c = 0;
                        skid.Input_Quantity__c = 0;
                        skid.Quantity_Short__c = totalCompletedQty.get(keyNoLocBin);

                        if (populated == false) {
                            skid.Quantity_To_Return__c = skid.Quantity_Available__c;

                            if (hoursConsumed.containsKey(opId) == true) {
                                if (hoursConsumed.get(opId).containsKey(keyNoLocBin) == true) skid.Input_Quantity__c += hoursConsumed.get(opId).get(keyNoLocBin);
                                if (hoursConsumed.get(opId).containsKey(null) == true) skid.Input_Quantity__c += hoursConsumed.get(opId).get(null);
                                skid.Input_Quantity__c = (skid.Input_Quantity__c / skid.Quantity_Short__c) * skid.Quantity_To_Return__c;
                            }

                            populated = true;
                        }

                        swList.add(new SkidService3.SerialWrapper(skid, serials));
                    }
                }
            }
        }

        return swList;
    }

    public static List<WorkOrderWrapper> getUncompleteComponentData(List<UncompleteWrapper> wrappers) {
        List<String> attributes = SkidService3.attributesForPutaway();

        Map<Id, UncompleteWrapper> wrapperMap = new Map<Id, UncompleteWrapper>();
        String whereClause = ' AND (';
        for (Integer i = 0; i < wrappers.size(); i++) {
            UncompleteWrapper wrapper = wrappers[i];
            Id woId = wrapper.wo.Id;
            Id opId = wrapper.op.Id;

            wrapperMap.put(woId, wrapper);

            if (i > 0) whereClause += ' OR ';
            whereClause += ' (Work_Order__c = \'' + woId + '\' AND ';
            if (wrapper.last == false) whereClause += ' ((Operation_Tracking__c = \'' + opId + '\' AND Type__c IN (\'Backflush\', \'Kit\')) OR (Operation_Tracking__c = null AND Type__c = \'Kit\')) ';
            else whereClause += ' (Operation_Tracking__c = \'' + opId + '\' OR Operation_Tracking__c = null) AND Type__c IN (\'Backflush\', \'Kit\') ';
            whereClause += ') ';
        }
        whereClause += ') ';

        Map<Id, Material_Tracking__c> materials = new Map<Id, Material_Tracking__c>(getMaterials(null, null, null, new Set<String>{ 'Complete' }, null, whereClause));
        if (materials.size() == 0) return new List<WorkOrderWrapper>();

        Set<Id> woIds = wrapperMap.keySet();
        Set<Id> materialIds = materials.keySet();
        Map<String, List<Location__c>> locMap = SkidService3.locationsFromStockMovementRules(materials.values(), 'Pick', new Set<String>{ 'material_tracking__c' }, null, null);

        Set<String> itTypes = new Set<String>{ 'Work Order Component Issue', 'Work Order Repair Component Issue', 'Work Order Issue From WIP', 'Work Order Return To WIP', 'Work Order Assembly Completion', 'Work Order Repair Assembly Completion', 'Work Order Assembly Uncompletion', 'Work Order Repair Assembly Uncompletion' };
        whereClause = 'Inventory_Change__r.Work_Order__c IN :woIds AND (Material_Tracking__c IN :materialIds OR Material_Tracking__c = null) AND Type__c IN :itTypes';

        Map<String, SKID__c> skidMap = new Map<String, SKID__c>();
        List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
        for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'CreatedDate ASC', 'SERIALS' => 'true' }))) {
            UncompleteWrapper wrapper = wrapperMap.get(it.Inventory_Change__r.Work_Order__c);
            Work_Order__c wo = wrapper.wo;
            Boolean last = wrapper.last;

            if (it.Type__c == 'Work Order Issue From WIP' || it.Type__c == 'Work Order Return To WIP') itList.add(it);

            if (it.Type__c == 'Work Order Component Issue' || it.Type__c == 'Work Order Repair Component Issue' || it.Type__c == 'Work Order Return To WIP') {
                SKID__c skid = SkidService3.generateToSkid(it, attributes);
                skid.Company__c = wo.Company__c;
                skid.Stocking_UOM__c = it.Stocking_UOM__c;
                skid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                skid.Material_Tracking__c = it.Material_Tracking__c;
                if(it.Inventory_Change__r.Work_Order__r.Field_Service__c == false && it.Sales_Order_Line__c !=null ){
                	skid.Sales_Order_Line__c = it.Sales_Order_Line__c;
                }
                skidMap.put(it.To_SKID_Identifier__c, skid);
            } else if (wo.Number_of_Operations__c == 1) {
                if (it.Type__c == 'Work Order Assembly Completion' || it.Type__c == 'Work Order Repair Assembly Completion') {
                	SKID__c skid = SkidService3.generateToSkid(it, attributes);
                	if(it.Inventory_Change__r.Work_Order__r.Field_Service__c == false && it.Sales_Order_Line__c !=null ){
	                	skid.Sales_Order_Line__c = it.Sales_Order_Line__c;
	                }
	                skidMap.put(it.From_SKID_Identifier__c, skid);
                } else if (it.Type__c == 'Work Order Assembly Uncompletion' || it.Type__c == 'Work Order Repair Assembly Uncompletion') {
                    skidMap.put(it.To_SKID_Identifier__c, SkidService3.generateFromSkid(it, attributes));
                }
            } else {
                if (it.Type__c == 'Work Order Issue From WIP') {
                    SKID__c skid = SkidService3.generateToSkid(it, attributes);
                    skid.Item__c = wo.Item__c;
                    skid.Item__r = wo.Item__r;
                    skid.Packaging_UOM__c = it.Assembly_Packaging_UOM__c;
                    skid.Packaging_UOM__r = it.Assembly_Packaging_UOM__r;
                    skidMap.put(it.To_SKID_Identifier__c, skid);
                } else if (it.Type__c == 'Work Order Assembly Uncompletion' || it.Type__c == 'Work Order Repair Assembly Uncompletion') {
                    skidMap.put(it.To_SKID_Identifier__c, SkidService3.generateToSkid(it, attributes));
                }
            }
        }

        Map<Id, Map<List<String>, Map<List<String>, SkidService3.SerialWrapper>>> assemblyToComponents = new Map<Id, Map<List<String>, Map<List<String>, SkidService3.SerialWrapper>>>();
        for (Inventory_Transaction__c it:itList) {
            Id woId = it.Inventory_Change__r.Work_Order__c;

            SKID__c assembly;
            SkidService3.SerialWrapper component;
            if (it.Type__c == 'Work Order Issue From WIP') {
                assembly = skidMap.get(it.To_SKID_Identifier__c);
                component = new SkidService3.SerialWrapper(skidMap.get(it.From_SKID_Identifier__c).clone(false, true));
                component.skid.Quantity__c = it.Quantity__c;
            } else {
                assembly = skidMap.get(it.From_SKID_Identifier__c);
                component = new SkidService3.SerialWrapper(skidMap.get(it.To_SKID_Identifier__c).clone(false, true));
                component.skid.Quantity__c = -it.Quantity__c;
            }

            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                Serial__c serial = st.Serial__r;
                if (st.Serial_Parent__c != null) serial.Temporary_Value_Holder__c = st.Serial_Parent__r.Name;
                component.serialList.add(serial);
            }

            List<String> assemblyKey = SkidService3.generateKey(assembly, attributes);
            List<String> componentKey = SkidService3.generateKey(component.skid, attributes);
            if (assemblyToComponents.containsKey(woId) == false) {
                assemblyToComponents.put(woId, new Map<List<String>, Map<List<String>, SkidService3.SerialWrapper>>{ assemblyKey => new Map<List<String>, SkidService3.SerialWrapper>{ componentKey => component }});
            } else if (assemblyToComponents.get(woId).containsKey(assemblyKey) == false) {
                assemblyToComponents.get(woId).put(assemblyKey, new Map<List<String>, SkidService3.SerialWrapper>{ componentKey => component });
            } else if (assemblyToComponents.get(woId).get(assemblyKey).containsKey(componentKey) == false) {
                assemblyToComponents.get(woId).get(assemblyKey).put(componentKey, component);
            } else {
                SkidService3.SerialWrapper existingComponent = assemblyToComponents.get(woId).get(assemblyKey).get(componentKey);
                existingComponent.skid.Quantity__c += component.skid.Quantity__c;

                if (existingComponent.skid.Quantity__c > 0) {
                    if (component.serialList.size() > 0) {
                        if (it.Type__c == 'Work Order Issue From WIP') {
                            existingComponent.serialList.addAll(component.serialList);
                        } else {
                            Map<Id, Serial__c> existingSerials = new Map<Id, Serial__c>(existingComponent.serialList);
                            for (Serial__c serial:component.serialList) existingSerials.remove(serial.Id);
                            existingComponent.serialList = existingSerials.values();
                        }
                    }
                } else {
                    assemblyToComponents.get(woId).get(assemblyKey).remove(componentKey);
                    if (assemblyToComponents.get(woId).get(assemblyKey).size() == 0) assemblyToComponents.get(woId).remove(assemblyKey);
                    if (assemblyToComponents.get(woId).size() == 0) assemblyToComponents.remove(woId);
                }
            }
        }

        Map<Id, WorkOrderWrapper> componentMap = new Map<Id, WorkOrderWrapper>();
        for (UncompleteWrapper wrapper:wrappers) {
            Work_Order__c wo = wrapper.wo;
            SkidService3.SerialWrapper selectedAssembly = wrapper.assemblyInfo;

            if (wo.Number_of_Operations__c != 1) {
                selectedAssembly.skid.Location__c = wo.Default_WIP_Location__c;
                selectedAssembly.skid.Bin__c = null;
            }
            List<String> selectedKey = SkidService3.generateKey(selectedAssembly.skid, attributes);

            if (assemblyToComponents.containsKey(wo.Id) == false || assemblyToComponents.get(wo.Id).containsKey(selectedKey) == false) continue;

            Set<String> serialNames = new Set<String>();
            for (Serial__c serial:selectedAssembly.serialList) serialNames.add(serial.Name);

            Map<Id, Decimal> qtyToReturnMap = new Map<Id, Decimal>();
            for (SkidService3.SerialWrapper sw:assemblyToComponents.get(wo.Id).get(selectedKey).values()) {
                if (sw.serialList.size() > 0 && serialNames.size() > 0) {
                    List<Serial__c> serials = new List<Serial__c>();
                    for (Serial__c serial:sw.serialList) {
                        if (serialNames.contains(serial.Temporary_Value_Holder__c) == true) serials.add(serial);
                    }
                    sw.serialList = serials;
                    sw.skid.Quantity__c = serials.size() / sw.conversionFactor;
                }

                if (sw.skid.Quantity__c <= 0) continue;

                Material_Tracking__c mt = materials.get(sw.skid.Material_Tracking__c);
                if (componentMap.containsKey(mt.Id) == false) {
                    WorkOrderWrapper wow = new WorkOrderWrapper(wo, mt, null);

                    List<String> skidFields = new List<String>{ 'Location__c', 'Bin__c' };
                    skidFields.addAll(SkidService3.trackedAttributes(null, null, mt.Item__r));
                    skidFields.addAll(new List<String>{ 'Quantity__c', 'Quantity_To_Return__c' });
                    for (Integer i = 2; i < skidFields.size(); i++) {
                        if (skidFields[i] == 'Lot_Number__c') {
                            skidFields[i] = 'Lot__c';
                            break;
                        }
                    }
                    wow.skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields);
                    for (FieldInfo fi:wow.skidFields) {
                        if (fi.field != 'Quantity_To_Return__c' && fi.field != 'Location__c' && fi.field != 'Bin__c') {
                            fi.editable = false;

                            if (fi.field == 'Quantity__c') fi.title = 'Quantity Available';
                            else if (fi.field == 'Location__c') fi.title = 'Putaway Location';
                        }
                        fi.field = 'skid.' + fi.field;
                    }

                    componentMap.put(mt.Id, wow);
                }

                if (selectedAssembly.skid.Quantity_To_Return__c >= selectedAssembly.skid.Quantity_Short__c) {
                    sw.skid.Quantity_To_Return__c = sw.skid.Quantity__c;
                } else {
                    Decimal yield = mt.Yield__c != null ? (mt.Yield__c / 100) : 1;
                    Decimal qtyToReturn = qtyToReturnMap.containsKey(mt.Id) == true ? qtyToReturnMap.get(mt.Id) : (mt.Quantity_Per_Assembly__c * KSE.addQuantityToField(selectedAssembly.skid.Quantity_To_Return__c, 0)) / (yield * sw.conversionFactor * KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, selectedAssembly.skid.Packaging_UOM__c, (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class)));
                    sw.skid.Quantity_To_Return__c = Math.min(qtyToReturn, sw.skid.Quantity__c);
                    qtyToReturnMap.put(mt.Id, qtyToReturn - sw.skid.Quantity_To_Return__c);
                }

                if ((mt.Type__c == MATERIAL_TYPE_KIT && mt.Operation_Tracking__c == null) || locMap.containsKey(mt.Id) == false || locMap.get(mt.Id).size() == 0) {
                    sw.skid.Location__c = null;
                    sw.skid.Location__r = null;
                } else {
                    sw.skid.Location__r = locMap.get(mt.Id)[0];
                    sw.skid.Location__c = sw.skid.Location__r.Id;
                }

                componentMap.get(mt.Id).serialWrapperList.add(sw);
            }
        }

        return componentMap.values();
    }

    public static List<WorkOrderWrapper> getUncompleteByproductData(Set<Id> woIds, Set<Id> opIds, Boolean last) {
        List<WorkOrderWrapper> bpWrappers = new List<WorkOrderWrapper>();

        String whereClause;
        Set<Id> operationIds;
        if (last) whereClause = ' AND (Operation_Tracking__c IN (\'' + String.join(new List<Id>(opIds),'\',\'') + '\') OR Operation_Tracking__c = null) ';
        else operationIds = opIds;

        List<Material_Tracking__c> materials = getMaterials(woIds, operationIds, new Set<String>{ 'By-product' }, null, null, whereClause);
        if (materials.size() == 0) return bpWrappers;

        Map<Id, Map<List<String>, SkidService3.SerialWrapper>> skidMap = new Map<Id, Map<List<String>, SkidService3.SerialWrapper>>();
        List<SKID__c> skids = new List<SKID__c>();
        whereClause = 'Material_Tracking__c IN :materials AND Type__c IN (\'By-product\', \'By-product Uncompletion\')';
        for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'CreatedDate ASC', 'SERIALS' => 'true' }))) {
            SKID__c skid = it.Type__c == 'By-product' ? SkidService3.generateToSkid(it, null) : SkidService3.generateFromSkid(it, null);
            skid.Quantity__c = it.Net_Quantity__c;

            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid);
            for (Serial_Transaction__c st:it.Serial_Transactions__r) sw.serialList.add(st.Serial__r);

            List<String> skidKey = SkidService3.generateKey(skid, null);
            if (skidMap.containsKey(it.Material_Tracking__c) == false) {
                skidMap.put(it.Material_Tracking__c, new Map<List<String>, SkidService3.SerialWrapper>{ skidKey => sw });
                skids.add(skid);
            } else if (skidMap.get(it.Material_Tracking__c).containsKey(skidKey) == false) {
                skidMap.get(it.Material_Tracking__c).put(skidKey, sw);
                skids.add(skid);
            } else {
                SkidService3.SerialWrapper sw2 = skidMap.get(it.Material_Tracking__c).get(skidKey);
                sw2.skid.Quantity__c += skid.Quantity__c;

                if (skid.Quantity__c > 0) {
                    sw2.serialList.addAll(sw.serialList);
                } else if (sw2.skid.Quantity__c == 0) {
                    skidMap.get(it.Material_Tracking__c).remove(skidKey);
                    if (skidMap.get(it.Material_Tracking__c).size() == 0) skidMap.remove(it.Material_Tracking__c);
                } else {
                    Map<Id, Serial__c> serMap = new Map<Id, Serial__c>(sw2.serialList);
                    for (Serial__c serial:sw.serialList) serMap.remove(serial.Id);
                    sw2.serialList = serMap.values();
                }
            }
        }

        if (skids.size() == 0) return bpWrappers;

        Map<List<String>, SKID__c> existingSkids = SkidService3.generateExistingSkidMap(null, skids, false, null);
        if (existingSkids.size() == 0) return bpWrappers;

        Set<Id> skidIds = (new Map<Id, SKID__c>(existingSkids.values())).keySet(); 
        Map<Id, List<Serial__c>> serialMap = new Map<Id, List<Serial__c>>();
        for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => 'SKID__c IN :skidIds', 'ORDER' => 'Name ASC' }))) {
            if (serialMap.containsKey(serial.SKID__c) == false) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
            else serialMap.get(serial.SKID__c).add(serial);
        }

        for (Material_Tracking__c mt:materials) {
            if (skidMap.containsKey(mt.Id) == false) continue;

            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
            for (List<String> skidKey:skidMap.get(mt.Id).keySet()) {
                if (existingSkids.containsKey(skidKey) == false) continue;

                SkidService3.SerialWrapper sw = skidMap.get(mt.Id).get(skidKey);
                SKID__c existingSkid = existingSkids.get(skidKey);

                if (sw.serialList.size() > 0) {
                    List<Serial__c> serials = new List<Serial__c>();
                    Set<Id> existingSerialIds = (new Map<Id, Serial__c>(serialMap.get(existingSkid.Id))).keySet();
                    for (Serial__c serial:sw.serialList) {
                        if (existingSerialIds.contains(serial.Id)) serials.add(serial);
                    }

                    sw.serialList = serials;
                    sw.skid.Quantity_Available__c = sw.serialList.size() / sw.conversionFactor;
                } else {
                    sw.skid.Quantity_Available__c = Math.min(sw.skid.Quantity__c, existingSkid.Quantity__c);
                }

                if (sw.skid.Quantity_Available__c > 0) {
                    sw.skid.Id = existingSkid.Id;
                    sw.skid.Quantity__c = existingSkid.Quantity__c;
                    sw.skid.Quantity_To_Return__c = sw.skid.Quantity_Available__c;
                    swList.add(sw);
                }
            }

            if (swList.size() > 0) {
                WorkOrderWrapper bpWrapper = new WorkOrderWrapper(mt.Work_Order__r, mt, swList);

                List<String> skidFields = new List<String>{ 'Location__c', 'Bin__c' };
                skidFields.addAll(SkidService3.trackedAttributes(null, null, mt.Item__r, new Item__c(Item_Attribute__r = new Item_Attribute__c(License_Plate_Number__c = true))));
                skidFields.addAll(new List<String>{ 'Quantity_Available__c', 'Quantity_To_Return__c' });
                for (Integer i = 2; i < skidFields.size(); i++) {
                    if (skidFields[i] == 'Lot_Number__c') {
                        skidFields[i] = 'Lot__c';
                        break;
                    }
                }
                bpWrapper.skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields);
                for (FieldInfo fi:bpWrapper.skidFields) {
                    if (fi.field != 'Quantity_To_Return__c') fi.editable = false;
                    fi.field = 'skid.' + fi.field;
                }
                
                bpWrappers.add(bpWrapper);
            }
        }

        return bpWrappers;
    }

    public static List<WorkOrderWrapper> getUncompleteWIPData(Set<Id> workOrderIds,Set<Id> opIds,Boolean last) {
        List<WorkOrderWrapper> wowList = new List<WorkOrderWrapper>();
        Map<Id,List<SKID__c>> wipSkidsByMaterial = new Map<Id,List<SKID__c>>();

        String whereClause;
        Set<Id> operationIds;
        Set<String> materialTypes;
        if (last) {
            whereClause = ' AND ((Type__c = \'' + MATERIAL_TYPE_BACKFLUSH + '\' AND (Operation_Tracking__c IN (\'' + String.join(new List<Id>(opIds),'\',\'') + '\') OR Operation_Tracking__c = null)) OR (Type__c = \'' + MATERIAL_TYPE_KIT + '\' AND Operation_Tracking__c IN (\'' + String.join(new List<Id>(opIds),'\',\'') + '\'))) ';
        } else {
            operationIds = opIds;
            materialTypes = new Set<String>{ MATERIAL_TYPE_BACKFLUSH, MATERIAL_TYPE_KIT };
        }

        List<Material_Tracking__c> materials = getMaterials(workOrderIds,operationIds,materialTypes,new Set<String>{'Complete'},null,whereClause);

        if (materials.size() == 0) {
            return wowList;
        }

        Map<String,List<Location__c>> locations = SkidService3.locationsFromStockMovementRules(materials,'Pick',new Set<String>{'Material_Tracking__c'},null,null);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id','Name','Company__c','Customer__c','Lot_Number__c','Material_Tracking__c','Quantity__c','Sales_Order_Line__c',
            'Type__c','Unique_Key__c','Work_Order__c','Location__r.Bin_Tracked__c','Location__r.Facility__c','Facility2__r.Facility_Identifier__c' });
        skidQuery.addFields(new Set<String>(SkidService3.attributesForPutaway()));
        skidQuery.setWhereClause('Type__c = \'WIP\' AND Material_Tracking__c IN :materials');
        skidQuery.setOrderByClause('Lot__r.CreatedDate');

        Set<Id> skidIds = new Set<Id>();
        for (SKID__c skid:Database.query(skidQuery.getQuery())) {
            skidIds.add(skid.Id);
            if (!wipSkidsByMaterial.containsKey(skid.Material_Tracking__c)) {
                wipSkidsByMaterial.put(skid.Material_Tracking__c,new List<SKID__c>());
            }
            wipSkidsByMaterial.get(skid.Material_Tracking__c).add(skid);
        }

        SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        serialQuery.addFields(new Set<String>{ 'Id','Name','Allocated_SKID__c','Allow_Reentry__c','Company__c','Item__c','SKID__c','Temporary_Value_Holder__c' });
        serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
        serialQuery.addFields('Serial');
        serialQuery.setWhereClause('Skid__c IN :skidIds ');

        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
        for (Serial__c serial:Database.query(serialQuery.getQuery())) {
        	if (!serialMap.containsKey(serial.SKID__c)) {
        		serialMap.put(serial.SKID__c,new List<Serial__c>());
        	}
        	serialMap.get(serial.SKID__c).add(serial);
        }

        for (Material_Tracking__c mt:materials) {
            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();

            Location__c loc = new Location__c();
            if (locations.containsKey(mt.Id) && locations.get(mt.Id).size() > 0) {
                loc = locations.get(mt.Id)[0];
            }

            if (wipSkidsByMaterial.containsKey(mt.Id)) {
                for (SKID__c skid:wipSkidsByMaterial.get(mt.Id)) {
                    skid.Quantity_To_Return__c = skid.Quantity__c;
                    skid.Location__c = loc.Id;
                    skid.Location__r = loc;

                    swList.add(new SkidService3.SerialWrapper(skid,serialMap.containsKey(skid.Id) ? serialMap.get(skid.Id) : new List<Serial__c>()));
                }
            }

            if (swList.size() > 0) {
                wowList.add(new WorkOrderWrapper(mt.Work_Order__r,mt,swList));
            }
        }

        return wowList;
    }

    public static void checkUncompleteErrors(List<UncompleteWrapper> uncompleteWrappers) {
        Set<Id> locationIds = new Set<Id>();
        Set<Id> serialTracked = new Set<Id>();
        Set<Id> compSkidIds = new Set<Id> ();

        for (UncompleteWrapper wrapper:uncompleteWrappers) {
        	Work_Order__c wo = wrapper.wo;
        	if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && wo.Item__r.Item_Attribute__c != null && wo.Item__r.Item_Attribute__r.Serial_Number__c) {
        		serialTracked.add(wo.Item__c);
        	}

        	for (WorkOrderWrapper wow:wrapper.componentInfo) {
        		if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && wow.material.Item__r.Item_Attribute__c != null && wow.material.Item__r.Item_Attribute__r.Serial_Number__c) {
                    serialTracked.add(wow.material.Item__c);
                }

                for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                    compSkidIds.add(sw.skid.id);
                    if (sw.skid.Location__c != null) {
                        locationIds.add(sw.skid.Location__c);
                    }
                }
            }
        }

        SOQLUtil compSkidQuery = new SOQLUtil ('Skid__c');
        compSkidQuery.addFields( new Set<String> { 'Id', 'quantity__c'} );
        compSkidQuery.setWhereClause(' Id in :compSkidIds ');
        compSkidQuery.setForUpdate();
        Map<Id, Skid__c> componentSkidMap = new Map<Id,Skid__c>( (List<Skid__c>) Database.query ( compSkidQuery.getQuery () ) );

        Map<Id,Location__c> locations = new Map<Id,Location__c>([SELECT Id,Name,Bin_Tracked__c,Facility__c FROM Location__c WHERE Id IN :locationIds]);
        Set<String> userSpecifiedSerials = new Set<String>();

        for (UncompleteWrapper wrapper:uncompleteWrappers) {
            Work_Order__c wo = wrapper.wo;

            for ( Operation_Tracking__c op : wo.Operation_Trackings__r ) {
                if ( wrapper.op.Id == op.Id ) {
                    wrapper.op.Quantity_Completed__c = op.Quantity_Completed__c;
                    wrapper.op.Quantity_Scrapped__c = op.Quantity_Scrapped__c;
                    wrapper.op.Quantity_Available__c = op.Quantity_Available__c;
                    wrapper.op.Hours_Consumed__c = op.Hours_Consumed__c;
                    wrapper.op.Serial_List__c = op.Serial_List__c;
                    break;
                }
            }
            SkidService3.SerialWrapper assemblyInfo = wrapper.assemblyInfo;

        	if(!String.isBlank(wo.Contents__c) && assemblyInfo.skid.Quantity_To_Return__c >0){
            	throw new WorkOrderServiceException(Label.Unrecord_Clear_Contents);
            }

            if (assemblyInfo != null && assemblyInfo.skid.Quantity_To_Return__c > 0 && serialTracked.contains(wo.Item__c) == true) {
                Decimal qtyToReturn = assemblyInfo.skid.Quantity_To_Return__c * assemblyInfo.conversionFactor;
                if (assemblyInfo.serialList.size() != qtyToReturn) throw new CustomException(wo.Name + ': You can\'t uncomplete a different number of serials (' + assemblyInfo.serialList.size() + ') than the quantity to uncomplete (' + qtyToReturn + ').');

                for (Serial__c serial:assemblyInfo.serialList) {
                    String uniqueKey = wo.Company__c + '-' + wo.Item__c + '-' + serial.Name;
                    if (userSpecifiedSerials.contains(uniqueKey) == true) throw new CustomException('You can\'t specify serial ' + serial.Name + ' more than once for item ' + wo.Item__r.Name + '.');
                    else userSpecifiedSerials.add(uniqueKey);
                }
            }

            for (WorkOrderWrapper wow:wrapper.componentInfo) {
                Material_Tracking__c mt = wow.material;
                
                for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                    if (mt.Type__c != MATERIAL_TYPE_BYPRODUCT && sw.skid.Location__c != null && sw.skid.Quantity_To_Return__c > 0) {
                        if ( componentSkidMap.containsKey(sw.skid.Id) ) {
                            sw.skid.Quantity__c = componentSkidMap.get(sw.skid.Id).Quantity__c;
                        } else {
                            sw.skid.Id = null;
                            sw.skid.Quantity__c = 0;
                        }

                        sw.skid.Location__r = locations.get(sw.skid.Location__c);

                        if (sw.skid.Location__r.Bin_Tracked__c && sw.skid.Bin__c == null) {
                            throw new WorkOrderServiceException(mt.Name + ': Bin is required');
                        }
                    } else if (mt.Type__c == MATERIAL_TYPE_BYPRODUCT) {
                        if (sw.skid.Quantity_To_Return__c > sw.skid.Quantity_Available__c) throw new CustomException(mt.Name + ': Quantity to return (' + sw.skid.Quantity_To_Return__c + ') can\'t be greater than quantity available (' + sw.skid.Quantity_Available__c + ').');
                    }

                    if (serialTracked.contains(sw.skid.Item__c)) {
                        if (sw.serialList.size() != sw.skid.Quantity_To_Return__c) {
                            throw new WorkOrderServiceException(mt.Name + ': ' + Label.Number_Of_Serials_Not_Matching_Quantity + ' Number Of Serials: ' + sw.serialList.size() + ' Specified Quantity: ' + sw.skid.Quantity_To_Return__c);
                        }

                        if (mt.Type__c != MATERIAL_TYPE_REPAIR) {
							for (Serial__c serial:sw.serialList) {
								String uniqueKey = wo.Company__c + '-' + sw.skid.Item__c + '-' + serial.Name;

								if (!userSpecifiedSerials.contains(uniqueKey)) {
									userSpecifiedSerials.add(uniqueKey);
								} else {
									throw new WorkOrderServiceException(serial.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
								}
							}
						}
                    }
                }
            }
        }
    }
    public static void uncompleteV2(List<UncompleteWrapper> uncompleteWrappers) {
        uncompleteV2(uncompleteWrappers,false);
    }
    public static void uncompleteV2(List<UncompleteWrapper> uncompleteWrappers, Boolean fromScanner) {
        List<SkidService3.SerialWrapper> wrappersForPutaway = new List<SkidService3.SerialWrapper>();
        List<SkidService3.SerialWrapper> wrappersForPutaway2 = new List<SkidService3.SerialWrapper>();
        List<SkidService3.SerialWrapper> wrappersForPutaway3 = new List<SkidService3.SerialWrapper>();

        Map<List<String>,SkidService3.SerialWrapper> toWrappers = new Map<List<String>,SkidService3.SerialWrapper>();
        Map<List<String>,SkidService3.SerialWrapper> toWrappers2 = new Map<List<String>,SkidService3.SerialWrapper>();

        Map<Id,SkidService3.ParameterData> itData = new Map<Id,SkidService3.ParameterData>();

        Map<List<String>,List<String>> keyMap = new Map<List<String>,List<String>>();
        Map<Id,Map<Id,List<SkidService3.SerialWrapper>>> skidsToUnallocate = new Map<Id,Map<Id,List<SkidService3.SerialWrapper>>>();

        Map<Id,Work_Order__c> workOrdersToUpdate = new Map<Id,Work_Order__c>();
        Map<Id,Material_Tracking__c> materialsToUpdate = new Map<Id,Material_Tracking__c>();
        Map<Id,Operation_Tracking__c> operationsToUpdate = new Map<Id,Operation_Tracking__c>();
        Map<Id,Operation_Transaction__c> otsToInsert = new Map<Id,Operation_Transaction__c>();
        Map<Id,List<Serial_Transaction__c>> stsToInsert = new Map<Id,List<Serial_Transaction__c>>();

        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>> ();

        List<String> attributes = SkidService3.attributesForPutaway(null,new Set<String>{ 'shipment_line__c' });
        attributes.add('Customer__c');
        attributes.add('Work_Order__c');
        List<String> otAttributes = attributes.clone();
        attributes.add('Material_Tracking__c');
        attributes.add('Shipment_Line__c');

        Set<Id> woIds = new Set<Id>();
        Set<Id> opIds = new Set<Id>();
        Map<Id,Decimal> maxOpSequence = new Map<Id,Decimal>();
        Id companyId;
        Map<Id,Item__c> items = new Map<Id,Item__c>();
        for (UncompleteWrapper wrapper:uncompleteWrappers) {
            Work_Order__c wo = wrapper.wo;
            woIds.add(wo.Id);
            companyId = wo.Company__c;

            for (Operation_Tracking__c op:wrapper.wo.Operation_Trackings__r) {
                opIds.add(op.Id);

                if (!maxOpSequence.containsKey(wo.Id) || op.Sequence__c > maxOpSequence.get(wo.Id)) {
                    maxOpSequence.put(wo.Id,op.Sequence__c);
                }
            }

            for (WorkOrderWrapper wow:wrapper.componentInfo) {
                items.put(wow.material.Item__c,wow.material.Item__r);
            }
        }

        Map<Id,List<Shipment_Line__c>> shipmentLines = getShipmentLinesForWorkOrders(woIds,'Sales_Order_Line__r.Required_Date__c DESC, Sales_Order_Line__r.CreatedDate DESC');

        Map<Id, Map<List<String>, Decimal>> opCompletedQtys = new Map<Id, Map<List<String>, Decimal>>();
        Map<Id, Set<Id>> completedSerials = new Map<Id, Set<Id>>();

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.setWhereClause('Operation_Tracking__c IN :opIds AND Quantity_Completed__c != 0');
        otQuery.setOrderByClause('CreatedDate ASC');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Serial__c' });
        stQuery.setWhereClause('Type__c IN (\'Operation Completion\', \'Operation Uncompletion\')');
        otQuery.addChildRelationship(stQuery);

        for (Operation_Transaction__c ot:Database.query(otQuery.getQuery())) {
            ot.Location__c = null;
            ot.Bin__c = null;

            List<String> key = SkidService3.generateKey(ot, otAttributes);
            if (opCompletedQtys.containsKey(ot.Operation_Tracking__c) == false) opCompletedQtys.put(ot.Operation_Tracking__c, new Map<List<String>, Decimal>{ key => ot.Quantity_Completed__c });
            else opCompletedQtys.get(ot.Operation_Tracking__c).put(key, KSE.addQuantityToField(opCompletedQtys.get(ot.Operation_Tracking__c).get(key), ot.Quantity_Completed__c));

            for (Serial_Transaction__c st:ot.Serial_Transactions__r) {
                if (completedSerials.containsKey(ot.Operation_Tracking__c) == false) completedSerials.put(ot.Operation_Tracking__c, new Set<Id>());

                if (ot.Quantity_Completed__c > 0) completedSerials.get(ot.Operation_Tracking__c).add(st.Serial__c);
                else completedSerials.get(ot.Operation_Tracking__c).remove(st.Serial__c);
            }
        }

        Map<Id,List<String>> skidAttributes = AllocationService.getSkidAttributes(companyId,items);

        Map<List<String>,List<Serial__c>> toSerials = new Map<List<String>,List<Serial__c>>();
        Map<Id,List<Material_Tracking__c>> materialMap = new Map<Id,List<Material_Tracking__c>>();
        for (UncompleteWrapper wrapper:uncompleteWrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;
            Operation_Tracking__c nextOp = wrapper.nextOp;
            SkidService3.SerialWrapper assemblyInfo = wrapper.assemblyInfo;
            List<WorkOrderWrapper> componentInfo = wrapper.componentInfo;
            Decimal hoursToUnconsume = wrapper.hoursToUnconsume;
            Boolean last = wrapper.last;

            Work_Order__c woToUpdate = newWorkOrder(wo);
            Operation_Tracking__c operationToUpdate = newOpTracking(op);
            Operation_Transaction__c otToInsert = newOpTransaction(op);

            if (hoursToUnconsume > 0) {
                operationToUpdate.Hours_Consumed__c = KSE.subtractDecimals(operationToUpdate.Hours_Consumed__c,hoursToUnconsume);
                otToInsert.Hours_Consumed__c = 0 - hoursToUnconsume;
            }

            if (assemblyInfo != null) {
                if ( !itemPackagingUomCache.containsKey(wo.Item__c) ) {
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.class);
                    itemPackagingUomCache.put(wo.Item__c, lstPkgUom );
                }
                // conversion factor for completion uom to work order uom
                Decimal assemblyToWOConvFactor = KSE.getConversionFactor (wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, assemblyInfo.skid.Packaging_UOM__c, itemPackagingUomCache.get(wo.Item__c) );
                Decimal assemblyToItemStockingConvFactor = KSE.getConversionFactor (wo.Item__c, wo.Facility__r.Facility_Identifier__c, assemblyInfo.skid.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, itemPackagingUomCache.get(wo.Item__c) );
                if ((assemblyInfo.skid.Type__c == SkidService3.SKID_TYPE_LOCATION || assemblyInfo.skid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE) && assemblyInfo.skid.Quantity_To_Return__c > 0) {
                    SKID__c wipSkid = assemblyInfo.skid.clone(false,true);
                    wipSkid.Quantity__c = KSE.addQuantityToField(wipSkid.Quantity_To_Return__c,0);
                    wipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                    wipSkid.Work_Order__c = wo.Id;
                    wipSkid.Location__c = wo.Default_WIP_Location__c;
                    wipSkid.bin__c = null;

                    wrappersForPutaway.add(new SkidService3.SerialWrapper(wipSkid, wo.Type__c != WO_TYPE_REPAIR || wo.Operation_Trackings__r.size() > 1 ? assemblyInfo.serialList : new List<Serial__c>()));
                    if (wo.Type__c == WO_TYPE_REPAIR && wo.Operation_Trackings__r.size() == 1) toSerials.put(SkidService3.generateKey(wipSkid,attributes), assemblyInfo.serialList);

                        woToUpdate.Quantity_Complete__c = KSE.subtractDecimals(woToUpdate.Quantity_Complete__c, ( assemblyInfo.skid.Quantity_To_Return__c / assemblyToWOConvFactor ) );
						//Update Qty in Stocking UOM
                        woToUpdate.Quantity_Complete_Stocking_UOM__c = KSE.subtractDecimals(woToUpdate.Quantity_Complete_Stocking_UOM__c, ( (assemblyInfo.skid.Quantity_To_Return__c * assemblyToItemStockingConvFactor).setscale(6,System.RoundingMode.HALF_UP) ) );
                        // KNDY-19038
                        if (fromScanner == true) woToUpdate.Completed__c = KSE.subtractDecimals(woToUpdate.Completed__c, (assemblyInfo.skid.Quantity_To_Return__c / assemblyToWOConvFactor));

                    if (shipmentLines.containsKey(wo.Id) == true) {
                        Decimal qtyForUnallocation = assemblyInfo.skid.Quantity_To_Return__c * assemblyToItemStockingConvFactor;
                        for (Shipment_Line__c shl:shipmentLines.get(wo.Id)) {
                            if (qtyForUnallocation <= 0) break;
                            if (shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED || shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_DELIVERED || shl.Product__r.Item__r.Non_Inventory__c == true || shl.Sales_Order_Line__r.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP) {
                                continue;
                            }

                            Decimal sellingConvFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, wo.Item__r.Stocking_UOM__c, itemPackagingUomCache.get(wo.Item__c));
                            Decimal qtyToUnallocate = shl.Company__r.Auto_Plan_Pick__c == true ? shl.Quantity_To_Pick__c : (shl.Quantity_Allocated__c * sellingConvFactor);
                            if (qtyToUnallocate > 0) {
                                SKID__c skidToUnallocate = assemblyInfo.skid.clone(false, true);
                                skidToUnallocate.Input_Quantity__c = Math.min(qtyForUnallocation, qtyToUnallocate);
                                qtyForUnallocation -= skidToUnallocate.Input_Quantity__c;

                                SkidService3.SerialWrapper swToUnallocate = new SkidService3.SerialWrapper(skidToUnallocate, assemblyInfo.serialList);
                                if (skidsToUnallocate.containsKey(shl.Shipment__c) == false) skidsToUnallocate.put(shl.Shipment__c, new Map<Id, List<SkidService3.SerialWrapper>>{ shl.Id => new List<SkidService3.SerialWrapper>{ swToUnallocate }});
                                else if (skidsToUnallocate.get(shl.Shipment__c).containsKey(shl.Id) == false) skidsToUnallocate.get(shl.Shipment__c).put(shl.Id, new List<SkidService3.SerialWrapper>{ swToUnallocate });
                                else skidsToUnallocate.get(shl.Shipment__c).get(shl.Id).add(swToUnallocate);
                            }
                        }
                    }
                }
                if ((wo.Operation_Trackings__r.size() == 1 || assemblyInfo.skid.Type__c == SkidService3.SKID_TYPE_WIP) && assemblyInfo.skid.Quantity_To_Return__c > 0) {
                    SKID__c wipSkid = assemblyInfo.skid.clone(false,true);
                    Decimal newOpQty = KSE.subtractDecimals(wipSkid.Quantity__c, assemblyInfo.skid.Quantity_To_Return__c);

                    if (wo.Operation_Trackings__r.size() == 1) {
                        wipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                        wipSkid.Work_Order__c = wo.Id;
                        wipSkid.Location__c = wo.Default_WIP_Location__c;
                        wipSkid.bin__c = null;
                    }

                    SKID__c skidClone = wipSkid.clone(false, true);
                    skidClone.Location__c = null;

                    List<String> key = SkidService3.generateKey(skidClone, otAttributes);
                    Decimal maxQty = 0;
                    Decimal finishedQty = 0;
                    Map<Id,Serial__c> serialsToRemove = new Map<Id,Serial__c>(assemblyInfo.serialList);
                    for (Operation_Tracking__c operation:wo.Operation_Trackings__r) {
                        if (operation.Id != op.Id) {
                            if (operation.Sequence__c != maxOpSequence.get(wo.Id)) {
                                if (opCompletedQtys.containsKey(operation.Id) == true && opCompletedQtys.get(operation.Id).containsKey(key) == true && (opCompletedQtys.get(operation.Id).get(key) > maxQty)) {
                                    maxQty = opCompletedQtys.get(operation.Id).get(key);
                                }

                                if (completedSerials.containsKey(operation.Id) == true) {
                                    for (Id serialId:completedSerials.get(operation.Id)) serialsToRemove.remove(serialId);
                                }
                            } else if (opCompletedQtys.containsKey(operation.Id) == true && opCompletedQtys.get(operation.Id).containsKey(key) == true) {
                                finishedQty = opCompletedQtys.get(operation.Id).get(key);
                            }
                        }
                    }

                    maxQty -= finishedQty;
                    if (newOpQty > maxQty) maxQty = newOpQty;

                    if (assemblyInfo.serialList.size() > 0) {
                        wipSkid.Quantity__c = 0 - serialsToRemove.size() / assemblyInfo.conversionFactor;
                    } else if (wipSkid.Quantity__c > maxQty) {
                        wipSkid.Quantity__c = maxQty - wipSkid.Quantity__c;
                    } else {
                        wipSkid.Quantity__c = 0;
                    }

                    wrappersForPutaway.add(new SkidService3.SerialWrapper(wipSkid,new List<Serial__c>()));

                    if (wo.Type__c == WO_TYPE_REPAIR && wipSkid.Quantity__c < 0) {
                        for (WorkOrderWrapper wow:componentInfo) {
                            Material_Tracking__c mt = wow.material;

                            if (mt.Type__c != MATERIAL_TYPE_REPAIR) continue;

                            SKID__c componentWipSkid = wipSkid.clone(false, true);
                            componentWipSkid.Location__c = null;
                            componentWipSkid.Quantity_To_Return__c = -componentWipSkid.Quantity__c;
                            componentWipSkid.Work_Order__c = null;
                            componentWipSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;

                            for (Serial__c serial:serialsToRemove.values()) {
                                serial.Temporary_Value_Holder__c = serial.Name;
                            }

                            wow.serialWrapperList.add(new SkidService3.SerialWrapper(componentWipSkid, serialsToRemove.values()));
                        }
                    } else if (serialsToRemove.size() > 0 && wo.Type__c != WO_TYPE_REPAIR) {
                        Inventory_Transaction__c dummyIt = new Inventory_Transaction__c(Item__c = assemblyInfo.skid.Item__c,Item__r = new Item__c());
                        dummyIt.Company__c = assemblyInfo.skid.Company__c;
                        wrappersForPutaway3.add(new SkidService3.SerialWrapper(dummyIt,serialsToRemove.values()));
                    }
                }

                if (assemblyInfo.skid.Quantity_To_Return__c > 0) {
                    operationToUpdate.Quantity_Completed__c = KSE.subtractDecimals(operationToUpdate.Quantity_Completed__c,assemblyInfo.skid.Quantity_To_Return__c / assemblyToWOConvFactor);
                    operationToUpdate.Quantity_Available__c = KSE.addQuantityToField(operationToUpdate.Quantity_Available__c,assemblyInfo.skid.Quantity_To_Return__c/assemblyToWOConvFactor);
                    otToInsert.Quantity_Completed__c = 0 - assemblyInfo.skid.Quantity_To_Return__c;

                    if (nextOp != null) {
                        Operation_Tracking__c nextOpToUpdate = new Operation_Tracking__c(Id = nextOp.Id, Quantity_Available__c = KSE.subtractDecimals(nextOp.Quantity_Available__c,assemblyInfo.skid.Quantity_To_Return__c / assemblyToWOConvFactor));
                        operationsToUpdate.put(nextOpToUpdate.Id,nextOpToUpdate);
                    }

                    for (String attr:otAttributes) {
                        if (attr == 'Facility2__c') {
                            otToInsert.Facility__c = assemblyInfo.skid.Facility2__c;
                        } else {
                            otToInsert.put(attr,assemblyInfo.skid.get(attr));
                        }
                    }
                    otToInsert.Work_Order__c = wo.Id;

                    for (Serial__c serial:assemblyInfo.serialList) {
                        if (!stsToInsert.containsKey(op.Id)) {
                            stsToInsert.put(op.Id, new List<Serial_Transaction__c>());
                        }
                        stsToInsert.get(op.Id).add(new Serial_Transaction__c(
                            Company__c = wo.Company__c,
                            Facility__c = wo.Facility__c,
                            Item__c = wo.Item__c,
                            Serial__c = serial.Id,
                            Type__c = 'Operation Uncompletion'
                        ));
                    }
                }
            }

            otsToInsert.put(op.Id,otToInsert);
            operationsToUpdate.put(operationToUpdate.Id,operationToUpdate);
            workOrdersToUpdate.put(wo.Id,woToUpdate);
            if (!materialMap.containsKey(wo.Id)) materialMap.put(wo.Id,new List<Material_Tracking__c>());

            for (WorkOrderWrapper wow:componentInfo) {
                Material_Tracking__c material = wow.material;

                materialMap.get(wo.Id).add(material);
                if (wow.serialWrapperList.size() == 0) continue;

                if (material.Type__c != MATERIAL_TYPE_BYPRODUCT) {
                    for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                        if (sw.skid.Quantity_To_Return__c > 0) {
                            if (sw.skid.Type__c == SkidService3.SKID_TYPE_LOCATION) {
                                SKID__c wipSkid = sw.skid.clone(false,true);
                                wipSkid.Bin__c = null;
                                wipSkid.Bin__r = null;
                                wipSkid.Location__c = wo.Default_WIP_Location__c;
                                wipSkid.Location__r = wo.Default_WIP_Location__r;
                                wipSkid.Material_Tracking__c = material.Id;
                                wipSkid.Work_Order__c = null;
                                wipSkid.Quantity__c = wipSkid.Quantity_To_Return__c;
                                wipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                                wipSkid.Receipt_Line__c = null;

                                wrappersForPutaway.add(new SkidService3.SerialWrapper(wipSkid,sw.serialList));
                            }

                            if (sw.skid.Location__c != null && material.Allocation_Required__c) {
                                SKID__c allocatedSkid = new SKID__c(
                                    Company__c = wo.Company__c,
                                    Facility2__c = wo.Facility__c,
                                    Facility2__r = wo.Facility__r,
                                    Item__c = material.Item__c,
                                    Quantity__c = sw.skid.Quantity_To_Return__c,
                                    Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                                    Material_Tracking__c = material.Id
                                );
                                for (String attr:skidAttributes.get(material.Item__c)) {
                                    allocatedSkid.put(attr,sw.skid.get(attr));
                                }

                                wrappersForPutaway2.add(new SkidService3.SerialWrapper(allocatedSkid,new List<Serial__c>()));
                            }
                        }
                    }
                }
            }
        }

        if (wrappersForPutaway.size() > 0) {
            //Assembly WIP, component return WIP,
            toWrappers = SkidService3.putAwayService(wrappersForPutaway,attributes,new Map<String,Boolean>{ SkidService3.MIXED_SERIAL => true });

            for (List<String> key:toWrappers.keySet()) {
                if (toSerials.containsKey(key)) {
                    toWrappers.get(key).serialList = toSerials.get(key);
                }
            }
        }

        wrappersForPutaway.clear();

        if (wrappersForPutaway2.size() > 0) {
            //allocated skids
            toWrappers2 = SkidService3.putAwayService(wrappersForPutaway2,attributes,null);
        }

        Map<Id,SKID__c> skidsToDelete = new Map<Id,SKID__c>();
        for (UncompleteWrapper wrapper:uncompleteWrappers) {
            Work_Order__c wo = wrapper.wo;
            Operation_Tracking__c op = wrapper.op;
            SkidService3.SerialWrapper assemblyInfo = wrapper.assemblyInfo;
            List<WorkOrderWrapper> componentInfo = wrapper.componentInfo;

            SKID__c assemblyWipSkid;

            SkidService3.ParameterData itInfo = new SkidService3.ParameterData();
            itInfo.sourceDoc = new Work_Order__c(Company__c = wo.Company__c);
            itInfo.icType = 'Work Order Uncomplete';

            if (assemblyInfo != null) {
                if (assemblyInfo.skid.Type__c == SkidService3.SKID_TYPE_LOCATION || assemblyInfo.skid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE) {
                    assemblyWipSkid = assemblyInfo.skid.clone(false, true);
                    assemblyWipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                    assemblyWipSkid.Work_Order__c = wo.Id;
                    assemblyWipSkid.Location__c = wo.Default_WIP_Location__c;
                    assemblyWipSkid.Bin__c = null;

                    if (assemblyInfo.skid.Quantity_To_Return__c > 0) {
                        assemblyWipSkid = toWrappers.get(SkidService3.generateKey(assemblyWipSkid, attributes)).skid;
                        Inventory_Transaction__c it = SkidService3.createInventoryTransaction(wo.Item__r, wo, wo.Type__c != WO_TYPE_REPAIR ? 'Work Order Assembly Uncompletion' : 'Work Order Repair Assembly Uncompletion', assemblyInfo.skid.Quantity_To_Return__c, assemblyInfo.skid, assemblyWipSkid, attributes);
                        if (it.From_Facility__c != null) it.From_Facility__r = wo.Facility__r;
                        else it.To_Facility__r = wo.Facility__r;
                        itInfo.itList.add(it);
                    }
                } else if (assemblyInfo.skid.Type__c == SkidService3.SKID_TYPE_WIP) {
                    assemblyWipSkid = assemblyInfo.skid.clone(true, true);
                    if (assemblyInfo.skid.Quantity_To_Return__c > 0) {
                        assemblyWipSkid = toWrappers.get(SkidService3.generateKey(assemblyWipSkid, attributes)).skid;
                        if (assemblyWipSkid.Quantity__c == 0) skidsToDelete.put(assemblyWipSkid.Id, new SKID__c(Id = assemblyWipSkid.Id));
                    }
                }
            }

            for (WorkOrderWrapper wow:componentInfo) {
                if (wow.serialWrapperList.size() == 0) continue;

                Material_Tracking__c material = wow.material;

                for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                    if (material.Type__c != MATERIAL_TYPE_BYPRODUCT) {
                        if (sw.skid.Quantity_To_Return__c > 0) {
                            SKID__c wipSkid = sw.skid.clone(true,true);
                            wipSkid.Bin__c = null;
                            wipSkid.Location__c = wo.Default_WIP_Location__c;
                            wipSkid.Material_Tracking__c = material.Id;
                            wipSkid.Type__c = SkidService3.SKID_TYPE_WIP;
                            wipSkid.Receipt_Line__c = null;
                            List<String> wipSkidKey = SkidService3.generateKey(wipSkid,attributes);
                            if (toWrappers.containsKey(wipSkidKey)) wipSkid = toWrappers.get(wipSkidKey).skid;

                            if (!materialsToUpdate.containsKey(material.Id)) {
                                materialsToUpdate.put(material.Id,newMaterialTracking(material));
                            }
                            Material_Tracking__c materialToUpdate = materialsToUpdate.get(material.Id);

                            if (sw.skid.Type__c == SkidService3.SKID_TYPE_LOCATION) {
                                Inventory_Transaction__c returnWipIt = SkidService3.createInventoryTransaction(material, material.Type__c == MATERIAL_TYPE_REPAIR ? 'Work Order Repair Return To WIP' : 'Work Order Return To WIP', sw.skid.Quantity_To_Return__c, assemblyWipSkid, wipSkid, attributes);
                                if (assemblyWipSkid.Id == null) returnWipIt.From_SKID_Identifier__c = assemblyWipSkid.Temporary_Value_Holder__c;
                                returnWipIt.Work_Order__c = wo.Id;
                                itInfo.itList.add(returnWipIt);
                                toWrappers.put(SkidService3.generateKey(returnWipIt, attributes), toWrappers.get(wipSkidKey));

                                materialToUpdate.Quantity_Used__c = KSE.subtractDecimals(materialToUpdate.Quantity_Used__c,sw.skid.Quantity_To_Return__c).setScale(6, System.RoundingMode.HALF_UP);
                            }

                            if (sw.skid.Location__c != null) {
                                SKID__c skidForPutaway = sw.skid.clone(false,true);
                                skidForPutaway.Quantity__c = skidForPutaway.Quantity_To_Return__c;
                                skidForPutaway.Material_Tracking__c = null;
                                skidForPutaway.Type__c = SkidService3.SKID_TYPE_LOCATION;

                                wrappersForPutaway.add(new SkidService3.SerialWrapper(skidForPutaway,sw.serialList));

                                String itType = 'Work Order Component Return';
                                if (material.Type__c == MATERIAL_TYPE_REPAIR) {
                                    itType = 'Work Order Repair Component Return';
                                }

                                Inventory_Transaction__c returnIt = SkidService3.createInventoryTransaction(material.Item__r, material, itType, sw.skid.Quantity_To_Return__c, wipSkid, skidForPutaway, attributes);
                                returnIt.From_Facility__r = wo.Facility__r;
                                itInfo.itList.add(returnIt);

                                keyMap.put(SkidService3.generateKey(skidForPutaway,attributes),SkidService3.generateKey(returnIt,attributes));

                                materialToUpdate.Quantity_Issued__c = KSE.subtractDecimals(materialToUpdate.Quantity_Issued__c,sw.skid.Quantity_To_Return__c).setScale(6, System.RoundingMode.HALF_UP);

                                if (material.Allocation_Required__c) {
                                    materialToUpdate.Quantity_Allocated__c += sw.skid.Quantity_to_Return__c;
                                    materialToUpdate.Quantity_Allocated__c = materialToUpdate.Quantity_Allocated__c.setScale(6, System.RoundingMode.HALF_UP);
                                }
                            }
                        }
                    } else {
                        Inventory_Transaction__c bpUncompleteIt = SkidService3.createInventoryTransaction(material.Item__r, material, 'By-product Uncompletion', sw.skid.Quantity_To_Return__c, sw.skid, sw.skid, attributes);
                        bpUncompleteIt.From_Facility__r = wo.Facility__r;
                        bpUncompleteIt.To_SKID__c = null;
                        bpUncompleteIt.To_SKID__r = null;
                        itInfo.itList.add(bpUncompleteIt);

                        toWrappers.put(SkidService3.generateKey(bpUncompleteIt,attributes),new SkidService3.SerialWrapper(bpUncompleteIt,sw.serialList));

                        Inventory_Transaction__c dummyIt = new Inventory_Transaction__c(Item__c = sw.skid.Item__c,Item__r = new Item__c());
                        dummyIt.Company__c = sw.skid.Company__c;
                        wrappersForPutaway3.add(new SkidService3.SerialWrapper(dummyIt,sw.serialList));

                        if (!materialsToUpdate.containsKey(material.Id)) {
                            materialsToUpdate.put(material.Id,newMaterialTracking(material));
                        }
                        Material_Tracking__c materialToUpdate = materialsToUpdate.get(material.Id);
                        materialToUpdate.Quantity_Completed__c = KSE.subtractDecimals(materialToUpdate.Quantity_Completed__c,sw.skid.Quantity_To_Return__c).setScale(6, System.RoundingMode.HALF_UP);
                    }
                }
            }

            Work_Order__c woToUpdate = workOrdersToUpdate.get(wo.Id);
            if (KSE.addQuantityToField(woToUpdate.Quantity_Complete__c,woToUpdate.Quantity_Scrapped__c) >= wo.Order_Quantity__c) {
                woToUpdate.Status__c = WO_STATUS_COMPLETE;
            } else {
            	woToUpdate.Date_Completed2__c = null;

                Boolean qtyFound = false;

                if (woToUpdate.Quantity_Complete__c > 0 || woToUpdate.Quantity_Scrapped__c > 0) {
                    qtyFound = true;
                }

                if (!qtyFound) {
                	if ( materialMap.containsKey(wo.Id) ) {
	                    for (Material_Tracking__c material:materialMap.get(wo.Id)) {
	                        Material_Tracking__c mt = material;
	                        if (materialsToUpdate.containsKey(mt.Id)) mt = materialsToUpdate.get(mt.Id);

	                        if (mt.Quantity_Issued__c > 0 || mt.Quantity_Completed__c > 0) {
	                            qtyFound = true;
	                            break;
	                        }
	                    }
                	}
                }

                if (!qtyFound) {
                    for (Operation_Tracking__c operation:wo.Operation_Trackings__r) {
                        Operation_Tracking__c oper = operation;
                        if (operationsToUpdate.containsKey(oper.Id)) oper = operationsToUpdate.get(oper.Id);

                        if (oper.Quantity_Completed__c > 0 || oper.Quantity_Scrapped__c > 0) {
                            qtyFound = true;
                            break;
                        }
                    }
                }

                if (qtyFound) {
                    woToUpdate.Status__c = WO_STATUS_IN_PROCESS;
                } else {
                    woToUpdate.Status__c = WO_STATUS_RELEASED;
                }
            }

            if (itInfo.itList.size() > 0) {
                for (Inventory_Transaction__c it:itInfo.itList) {
                    it.Operation_Tracking__c = op.Id;
                }

                itData.put(wo.Id,itInfo);
            }
        }

        toWrappers.putAll(SkidService3.putAwayService(wrappersForPutaway,attributes,new Map<String,Boolean>{ SkidService3.MIXED_SERIAL => true }));

        for (List<String> key:keyMap.keySet()) {
            toWrappers.put(keyMap.get(key),toWrappers.get(key));
        }

        SkidService3.inventoryTransactionsForPutaway(itData,attributes,toWrappers,null);

        if (wrappersForPutaway3.size() > 0) {
            SkidService3.putAwayService(wrappersForPutaway3,attributes,new Map<String,Boolean>{ SkidService3.VOID_SERIALS => true, SkidService3.UNDO_SERIAL => true });
        }

        allowWorkOrderUpdate = true;
        DML.updateAsUser(workOrdersToUpdate.values());
        DML.updateAsUser(operationsToUpdate.values());
        DML.updateAsUser(materialsToUpdate.values());

        DML.insertAsUser(otsToInsert.values());
        if (stsToInsert.size() > 0) {
            List<Serial_Transaction__c> stList = new List<Serial_Transaction__c>();
            for (Id opId:stsToInsert.keySet()) {
                for (Serial_Transaction__c st:stsToInsert.get(opId)) {
                    st.Operation_Transaction__c = otsToInsert.get(opId).Id;
                    stList.add(st);
                }
            }
            DML.insertAsSystem(stList);
        }

        DML.deleteAsSystem(skidsToDelete.values());
        allowWorkOrderUpdate = false;

        if (skidsToUnallocate.size() > 0) {
        	try {
        		AllocationService.autoUnallocate(skidsToUnallocate);
        	} catch (Exception e) {
        		throw new WorkOrderServiceException('Unable to auto-unallocate: ' + e.getMessage());
        	}
        }
    }

    public class UncompleteWrapper {
        public Work_Order__c wo { get; set; }
        public Operation_Tracking__c op { get; set; }
        public Operation_Tracking__c nextOp { get; set; }
        public SkidService3.SerialWrapper assemblyInfo { get; set; }
        public List<WorkOrderWrapper> componentInfo { get; set; } { componentInfo = new List<WorkOrderWrapper>(); }
        public Boolean last { get; set; }
        public Decimal hoursToUnconsume { get; set; } { hoursToUnconsume = 0; }

        public UncompleteWrapper(Work_Order__c wo,Operation_Tracking__c op,Operation_Tracking__c nextOp,SkidService3.SerialWrapper assemblyInfo,List<WorkOrderWrapper> componentInfo,Boolean last,Decimal hoursToUnconsume) {
            this.wo = wo;
            this.op = op;
            this.nextOp = nextOp;
            this.assemblyInfo = assemblyInfo;
            if (componentInfo != null) this.componentInfo = componentInfo;
            if (last != null) this.last = last;
            if (hoursToUnconsume != null) this.hoursToUnconsume = hoursToUnconsume;
        }
    }


    /*
     * CLOSE/CANCEL SECTION
     */
    public static void validateForClose(Set<Id> woIds) {
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Quantity_Complete__c', 'Quantity_To_Complete__c', 'Status__c' });
        woQuery.setWhereClause('Id IN :woIds');

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Material_Tracking__c', 'Material_Tracking__r.Work_Order__c', 'Work_Order__c' });
        skidQuery.setWhereClause('(Work_Order__c IN :woIds OR Material_Tracking__r.Work_Order__c IN :woIds) AND Type__c = \'WIP\'');
        Map<Id, List<SKID__c>> skids = new Map<Id, List<SKID__c>>();
        for (SKID__c skid:Database.query(skidQuery.getQuery())) {
            Id woId = skid.Work_Order__c != null ? skid.Work_Order__c : skid.Material_Tracking__r.Work_Order__c;
            if (!skids.containsKey(woId)) skids.put(woId, new List<SKID__c>());
            skids.get(woId).add(skid);
        }

        for (Work_Order__c wo:Database.query(woQuery.getQuery())) {
            if (wo.Status__c == WO_STATUS_DRAFT || wo.Status__c == WO_STATUS_CLOSED || wo.Status__c == WO_STATUS_CANCELLED) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.Cannot_close_work_order + wo.Status__c);
            } else if (skids.containsKey(wo.Id)) {
                if (skids.get(wo.Id)[0].Work_Order__c != null) {
                    throw new WorkOrderServiceException(wo.Name + ': Unable to close a work order with assembly quantity in WIP');
                } else if (skids.get(wo.Id)[0].Material_Tracking__c != null) {
                    throw new WorkOrderServiceException(wo.Name + ': Unable to close a work order with components in WIP');
                }
            } else if (ApexPages.currentPage() == Page.WorkOrderClosed && wo.Quantity_Complete__c > 0 && wo.Quantity_To_Complete__c > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.WorkOrder_partially_completed + wo.Quantity_To_Complete__c));
            }
        }
    }

    public static void validateForCancel(Set<Id> woIds) {
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Quantity_Complete__c', 'Status__c' });
        woQuery.setWhereClause('Id IN :woIds');

        SOQLUtil.ChildRelationship materialQuery = new SOQLUtil.ChildRelationship(woQuery, 'Material_Trackings__r');
        materialQuery.addField('Id');
        materialQuery.setWhereClause('Quantity_Issued__c > 0');
        woQuery.addChildRelationship(materialQuery);

        SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(woQuery, 'SKIDs__r');
        skidQuery.addField('Id');
        skidQuery.setWhereClause('Type__c = \'WIP\'');
        woQuery.addChildRelationship(skidQuery);

        for (Work_Order__c wo:Database.query(woQuery.getQuery())) {
            if (wo.Status__c == WO_STATUS_CANCELLED) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.WorkOrder_cancelled);
            } else if ((wo.Material_Trackings__r != null && wo.Material_Trackings__r.size() > 0) || wo.Quantity_Complete__c > 0 || (wo.SKIDs__r != null && wo.SKIDs__r.size() > 0)) {
                throw new WorkOrderServiceException(wo.Name + ': ' + Label.Work_Order_cannot_be_cancelled);
            }
        }
    }

    public static void  closeCancel(Set<Id> woIds, String status) {
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addFields(new Set<String>{ 'Id', 'Receipt_Line__c', 'Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c', 'Item__r.Stocking_UOM__c', 'Facility__r.Facility_Identifier__c' });
        woQuery.setWhereClause('Id IN :woIds');

        if (status == WO_STATUS_CANCELLED) {
            SOQLUtil.ChildRelationship solQuery = new SOQLUtil.ChildRelationship(woQuery, 'Sales_Order_Lines__r');
            solQuery.addField('Id');
            solQuery.setWhereClause('Status__c IN (\'Draft\', \'Open\')');
            woQuery.addChildRelationship(solQuery);
        }

        List<Work_Order__c> workOrders = Database.query(woQuery.getQuery());

        Set<Id> rlIds = new Set<Id>();
        List<Sales_Order_Line__c> soLinesToUpdate = new List<Sales_Order_Line__c>();
        for (Work_Order__c wo:workOrders) {
            wo.Status__c = status;

            if (status == WO_STATUS_CLOSED) {
                wo.Close_Date__c = System.now();
            } else if (status == WO_STATUS_CANCELLED && wo.Sales_Order_Lines__r.size() > 0) {
                for (Sales_Order_Line__c sol:wo.Sales_Order_Lines__r) {
                    sol.Work_Order__c = null;
                    soLinesToUpdate.add(sol);
                }
            }

            if (wo.Receipt_Line__c != null) {
                rlIds.add(wo.Receipt_Line__c);
            } else if (wo.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c != null) {
                rlIds.add(wo.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c);
            }
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addFields(new Set<String>{ 'Facility2__r.Facility_Identifier__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c' });
        skidQuery.setWhereClause('(Work_Order__c IN :woIds AND Type__c = \'' + SkidService3.SKID_TYPE_WO_SUPPLY + '\') OR Receipt_Line__c IN :rlIds');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skidsToDelete = new List<SKID__c>();
        List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        for (SKID__c skid:Database.query(skidQuery.getQuery())) {
            if (skid.Type__c == SkidService3.SKID_TYPE_WO_SUPPLY) {
                skidsToDelete.add(skid);
            } else {
                SKID__c skidClone = skid.clone(false, true);
                skidClone.Receipt_Line__c = null;
                skidsForPutaway.add(new SkidService3.SerialWrapper(skidClone, skid.Serials__r));

                skid.Quantity__c = -skid.Quantity__c;
                skidsForPutaway.add(new SkidService3.SerialWrapper(skid, new List<Serial__c>()));
            }
        }

        if (soLinesToUpdate.size() > 0) DML.updateAsUser(soLinesToUpdate);
        if (skidsToDelete.size() > 0) DML.deleteAsUser(skidsToDelete);
        if (skidsForPutaway.size() > 0) SkidService3.putAwayService(skidsForPutaway, null, new Map<String, Boolean>{ SkidService3.DELETE_SKIDS => true });

        allowWorkOrderUpdate = true;
        DML.updateAsUser(workOrders);
        allowWorkOrderUpdate = false;

        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.setWhereClause('Status__c = \'' + PurchaseOrderService.PO_STATUS_OPEN + '\' AND Operation_Tracking__r.Work_Order__c IN :woIds');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());
        if (poLines.size() > 0) {
            JsonResult result = status == WO_STATUS_CLOSED ? PurchaseOrderService.closePOLines(poLines, false) : PurchaseOrderService.cancelPOLines(poLines, false);
            if (!result.success) {
                throw new WorkOrderServiceException(result.messages[0].get('message'));
            }
        }
    }


    /*
     * REOPEN SECTION
     */
    public static void reopen(Set<Id> woIds) {
        if (woIds == null || woIds.size() == 0) return;

        List<Work_Order__c> workOrders = getWorkOrders(woIds, null, null, new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' });

        Map<Id, Work_Order__c> wosForSkids = new Map<Id, Work_Order__c>();
        for (Work_Order__c wo:workOrders) {
            wo.Close_Date__c = null;

            if(String.isBlank(wo.Packaging_UOM__c))
				wo.Packaging_UOM__c = wo.Item__r.Stocking_UOM__c;
            if (KSE.addQuantityToField(wo.Quantity_Complete__c, wo.Quantity_Scrapped__c) >= wo.Order_Quantity__c) {
                wo.Status__c = WO_STATUS_COMPLETE;
            } else {
                wosForSkids.put(wo.Id, wo);

                Boolean hasQty = false;
                for (Material_Tracking__c material:wo.Material_Trackings__r) {
                    for (String qtyField:materialQtyFields) {
                        if ((Decimal)material.get(qtyField) > 0) {
                            hasQty = true;
                            break;
                        }
                    }
                }

                if (!hasQty) {
                    for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
                        for (String qtyField:operationQtyFields) {
                            if ((Decimal)op.get(qtyField) > 0) {
                                hasQty = true;
                                break;
                            }
                        }
                    }
                }

                if (hasQty) {
                    wo.Status__c = WO_STATUS_IN_PROCESS;
                } else {
                    wo.Status__c = WO_STATUS_RELEASED;
                }
            }
        }

        if (wosForSkids.size() > 0) SKIDService.insertSkids(wosForSkids, SkidService3.SKID_TYPE_WO_SUPPLY, null);

        allowWorkOrderUpdate = true;
        DML.updateAsUser(workOrders);
        allowWorkOrderUpdate = false;
    }


    public class MaterialWrapper {
        public Material_Tracking__c material { get; set; }
        public List<SKID__c> skids { get; set; } { skids = new List<SKID__c>(); }
        public List<SKID__c> additionalSkids { get; set; } { additionalSkids = new List<SKID__c>(); }
        public List<String> attributes { get; set; } { attributes = new List<String>(); }
    }


    public static void updateWOStatuses(Map<Id, Map<Id, Sales_Order_Line__c>> soLines) {
        Set<Id> woIds = soLines.keySet();
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addFields(new Set<String>{ 'Id', 'Quantity_To_Complete__c','Item__r.Source__c' ,'Status__c'});
        woQuery.setWhereClause('Id IN :woIds');

        SOQLUtil.ChildRelationship solQuery = new SOQLUtil.ChildRelationship(woQuery, 'Sales_Order_Lines__r');
        solQuery.addFields(new Set<String>{'Id','Fulfillment_Source__c','Status__c'});
        solQuery.setWhereClause('Status__c = \'Open\'');
        woQuery.addChildRelationship(solQuery);

        List<Work_Order__c> workOrders = Database.query(woQuery.getQuery());

        Set<Id> wosToCancel = new Set<Id>();
        Set<Id> wosToClose = new Set<Id>();
        List<Work_Order__c> wosToUpdate = new List<Work_Order__c>();
        for (Work_Order__c wo:workOrders) {
            Boolean hasOpenSol = false;
            for (Sales_Order_Line__c sol:wo.Sales_Order_Lines__r) {
                if (!soLines.get(wo.Id).containsKey(sol.Id) || soLines.get(wo.Id).get(sol.Id).Status__c == 'Open')  {
                    hasOpenSol = true;
                    break;
                }
            }

            for (Sales_Order_Line__c sol:soLines.get(wo.Id).values()) {
                if (sol.Status__c == 'Cancelled') {
                    if (wo.Item__r.Source__c !=  ItemService.ITEM_SOURCE_MAKE_TO_ORDER && sol.Fulfillment_Source__c != SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER && !hasOpenSol && wo.Status__c != 'Cancelled') {
                        wosToCancel.add(wo.Id);
                    }
                } else if (sol.Status__c == 'Closed') {
                    if (wo.Quantity_To_Complete__c == 0 && !hasOpenSol && wo.Status__c != 'Closed') wosToClose.add(wo.Id);
                } else if (sol.Status__c == 'Open') {
                    wo.Close_Date__c = null;
                    if (wo.Quantity_To_Complete__c == 0){
                        wo.Status__c = WO_STATUS_COMPLETE;
                    } else if (wo.Quantity_To_Complete__c > 0) {
                        wo.Status__c = WO_STATUS_IN_PROCESS;
                    }
                    wosToUpdate.add(wo);
                }
            }
        }

        if (wosToCancel.size() > 0) {
            validateForCancel(wosToCancel);
            closeCancel(wosToCancel, WO_STATUS_CANCELLED);
        }

        if (wosToClose.size() > 0) {
            validateForClose(wosToClose);
            closeCancel(wosToClose, WO_STATUS_CLOSED);
        }

        if (wosToUpdate.size() > 0) {
            allowWorkOrderUpdate = true;
            DML.updateAsUser(wosToUpdate);
            allowWorkOrderUpdate = false;
        }
    }

    public static void syncWorkOrdersWithSalesOrderLines(Map<Id, Sales_Order_Line__c> newSols, Map<Id, Sales_Order_Line__c> oldSols, Map<Id, Shipment_Line__c> shls, SaveType st) {
        Set<Id> woIds = new Set<Id>();
        for (Id solId:newSols.keySet()) {
            Sales_Order_Line__c oldSol = oldSols.get(solId);
            Sales_Order_Line__c newSol = newSols.get(solId);
            if (oldSol.Work_Order__c != null) woIds.add(oldSol.Work_Order__c);
            if (newSol.Work_Order__c != null) woIds.add(newSol.Work_Order__c);
        }

        Map<Id, Work_Order__c> existingWos = new Map<Id, Work_Order__c>();
        Map<String, Work_Order__c> wos = new Map<String, Work_Order__c>();
        if (woIds.size() > 0) {
            SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
            woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Assembly_Item_Specification__c', 'Facility__c', 'Item__c', 'Order_Quantity__c',
                'Order_Quantity_Stocking_UOM__c', 'Packaging_UOM__c', 'Quantity_Complete_Stocking_UOM__c', 'Status__c',

                'Facility__r.Facility_Identifier__c',

                'Item__r.Stocking_UOM__c' });
            woQuery.setWhereClause('Id IN :woIds');
            for (Work_Order__c wo:Database.query(woQuery.getQuery())) {
                existingWos.put(wo.Id, wo);
                wos.put(wo.Id, wo.clone(true, true));
            }
        }

        for (Id solId:newSols.keySet()) {
            Sales_Order_Line__c oldSol = oldSols.get(solId);
            Sales_Order_Line__c newSol = newSols.get(solId);
            Shipment_Line__c shl = shls.get(solId);
            List<Id> pkgUoms = ItemService.getPackagingUoms(oldSol.Product__r.Item__r);
            
            if (oldSol.Status__c != SalesOrderLineService.SO_LINE_STATUS_OPEN) continue;
            if (shl == null) throw new CustomException(oldSol.Name + ': Shipment line not found.');

            if (oldSol.Work_Order__c != null) {
                Work_Order__c prevWo = wos.get(oldSol.Work_Order__c);
                prevWo.Order_Quantity_Stocking_UOM__c -= (oldSol.Quantity_Shipped__c + shl.Quantity_Planned__c) * KSE.getConversionFactor(prevWo.Item__c, prevWo.Facility__r.Facility_Identifier__c, oldSol.Selling_UOM__c, prevWo.Item__r.Stocking_UOM__c, pkgUoms);
                prevWo.Order_Quantity__c = prevWo.Order_Quantity_Stocking_UOM__c / KSE.getConversionFactor(prevWo.Item__c, prevWo.Facility__r.Facility_Identifier__c, prevWo.Packaging_UOM__c, prevWo.Item__r.Stocking_UOM__c, pkgUoms);
            }

            if (newSol.Work_Order__c != null || st == SaveType.CONSOLIDATE_AND_SAVE || (st == SaveType.SAVE && oldSol.Work_Order__c == null)) {
                String key = newSol.Work_Order__c != null ? (String)newSol.Work_Order__c : (st == SaveType.CONSOLIDATE_AND_SAVE ? (oldSol.Product__r.Item__c + '-' + oldSol.Ship_From_Location__r.Facility__c) : (String)oldSol.Id);
                Work_Order__c curWo;
                if (newSol.Work_Order__c != null) {
                    curWo = wos.get(newSol.Work_Order__c);
                } else if (st == SaveType.CONSOLIDATE_AND_SAVE && wos.containsKey(key) == true) {
                    curWo = wos.get(key);
                } else {
                    curWo = new Work_Order__c(
                        Company__c = oldSol.Company__c,
                        Type__c = oldSol.Type__c == SalesOrderLineService.SO_LINE_TYPE_REPAIR ? WO_TYPE_REPAIR : WO_TYPE_REGULAR,
                        Status__c = WO_STATUS_DRAFT,
                        Item__c = oldSol.Product__r.Item__c,
                        Item__r = oldSol.Product__r.Item__r,
                        Assembly_Item_Specification__c = oldSol.Item_Specification__c,
                        Facility__c = oldSol.Ship_From_Location__r.Facility__c,
                        Facility__r = oldSol.Ship_From_Location__r.Facility__r,
                        Packaging_UOM__c = oldSol.Item_Specification__c != null ? oldSol.Item_Specification__r.Default_Work_Order_Packaging_UOM__c : oldSol.Selling_UOM__c,
                        Order_Quantity__c = 0,
                        Order_Quantity_Stocking_UOM__c = 0,
                        Quantity_Complete__c = 0,
                        Complete_To_Location__c = oldSol.Ship_From_Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c,
                        MRB_Location__c = oldSol.Ship_From_Location__r.Facility__r.Default_Work_Order_MRB_Location__c,
                        Default_WIP_Location__c = oldSol.Ship_From_Location__r.Facility__r.Default_Work_Order_WIP_Location__c,
                        Start_Date2__c = oldSol.Product__r.Item__r.Lead_Time__c != null ? oldSol.Required_Date__c.addDays(0 - (Integer)oldSol.Product__r.Item__r.Lead_Time__c) : oldSol.Required_Date__c,
                        Need_Date2__c = DateTime.newInstance(oldSol.Required_Date__c, Time.newInstance(0, 0, 0, 0)),
                        Shipment_Line__c = oldSol.Type__c == SalesOrderLineService.SO_LINE_TYPE_REPAIR ? shl.Id : null,
                        Field_Service__c = oldSol.SKID__c != null
                    );
                }

                if (curWo.Status__c == WO_STATUS_CANCELLED || curWo.Status__c == WO_STATUS_CLOSED) throw new CustomException(curWo.Name + ': ' + Label.Disallow_Closed_Cancelled_WorkOrder_For_Sales_Order_Line);
                if (curWo.Item__c != oldSol.Product__r.Item__c || curWo.Assembly_Item_Specification__c != oldSol.Item_Specification__c) throw new CustomException(curWo.Name + ': ' + Label.Cannot_change_ItemSpecification_for_Released_WorkOrder);

                curWo.Order_Quantity_Stocking_UOM__c += oldSol.Quantity_Ordered__c * KSE.getConversionFactor(curWo.Item__c, curWo.Facility__r.Facility_Identifier__c, oldSol.Selling_UOM__c, curWo.Item__r.Stocking_UOM__c, pkgUoms);
                curWo.Order_Quantity__c = curWo.Order_Quantity_Stocking_UOM__c / KSE.getConversionFactor(curWo.Item__c, curWo.Facility__r.Facility_Identifier__c, curWo.Packaging_UOM__c, curWo.Item__r.Stocking_UOM__c, pkgUoms);
                wos.put(key, curWo);
            }
        }

        ExceptionService exServ = new ExceptionService();
        Set<Id> wosToCancel = new Set<Id>();
        Set<Id> wosToClose = new Set<Id>();
        Set<Id> wosToRelease = new Set<Id>();
        Map<String, Work_Order__c> wosToUpsert = new Map<String, Work_Order__c>();
        for (String key:wos.keySet()) {
            Work_Order__c wo = wos.get(key);
            wo.Last_Sync_Date__c = System.now();

            if (wo.Id != null) {
                Work_Order__c existingWo = existingWos.get(wo.Id);
                if (existingWo.Status__c == WO_STATUS_CANCELLED || existingWo.Status__c == WO_STATUS_CLOSED || wo.Order_Quantity__c == existingWo.Order_Quantity__c) continue;

                if (wo.Order_Quantity__c <= 0) {
                    if (wo.Status__c == WO_STATUS_DRAFT) wosToCancel.add(wo.Id);
                    else wosToClose.add(wo.Id);
                } else {
                    existingWo.Quantity_Complete_Stocking_UOM__c = KSE.addQuantityToField(existingWo.Quantity_Complete_Stocking_UOM__c, 0);

                    TaskType t;
                    Boolean changeQty = true;
                    if (wo.Order_Quantity_Stocking_UOM__c < existingWo.Quantity_Complete_Stocking_UOM__c) {
                        t = ExceptionUtil.WO_QTY_CHANGE_DEC_EX;
                        changeQty = false;
                    } else if (wo.Order_Quantity__c < existingWo.Order_Quantity__c) {
                        t = ExceptionUtil.WO_QTY_CHANGE_DEC;
                    } else {
                        t = ExceptionUtil.WO_QTY_CHANGE_INC;
                    }
                    t.description += ' from ' + existingWo.Order_Quantity__c + ' to ' + wo.Order_Quantity__c;
                    exServ.setException(wo, t);

                    if (changeQty == true) {
                        if (wo.Order_Quantity_Stocking_UOM__c == existingWo.Quantity_Complete_Stocking_UOM__c) wo.Status__c = WO_STATUS_COMPLETE;
                        wosToUpsert.put(key, wo);
                        if (wo.Status__c != WO_STATUS_DRAFT) wosToRelease.add(wo.Id);
                    }
                }
            } else {
                wosToUpsert.put(key, wo);
            }
        }

        

        if (wosToCancel.size() > 0) {
            validateForCancel(wosToCancel);
            closeCancel(wosToCancel, WO_STATUS_CANCELLED);
        }

        if (wosToClose.size() > 0) {
            validateForClose(wosToClose);
            closeCancel(wosToClose, WO_STATUS_CLOSED);
        }

        if (wosToUpsert.size() > 0) {
            allowWorkOrderUpdate = true;
            DML.checkUpsertAsUser(wosToUpsert.values()); upsert wosToUpsert.values();
            allowWorkOrderUpdate = false;
        }

        if (wosToRelease.size() > 0) WorkOrderPlanningService.release(wosToRelease);
        
        exServ.finish();

        List<Sales_Order_Line__c> solsToUpdate = new List<Sales_Order_Line__c>();
        List<Shipment_Line__c> shlsToUpdate = new List<Shipment_Line__c>();
        for (Id solId:newSols.keySet()) {
            Sales_Order_Line__c oldSol = oldSols.get(solId);
            Sales_Order_Line__c newSol = newSols.get(solId);
            Shipment_Line__c shl = shls.get(solId);
            String key = newSol.Work_Order__c != null ? (String)newSol.Work_Order__c : (st == SaveType.CONSOLIDATE_AND_SAVE ? (oldSol.Product__r.Item__c + '-' + oldSol.Ship_From_Location__r.Facility__c) : (String)oldSol.Id);

            if (wosToUpsert.containsKey(key) == true) {
                Id woId = wosToUpsert.get(key).Id;
                solsToUpdate.add(new Sales_Order_Line__c(Id = solId, Work_Order__c = woId));
                shlsToUpdate.add(new Shipment_Line__c(Id = shl.Id, Work_Order__c = woId));
            }
        }

        DML.updateAsUser(solsToUpdate);
        DML.updateAsUser(shlsToUpdate);
    }
}
