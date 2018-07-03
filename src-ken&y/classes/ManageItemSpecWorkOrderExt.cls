public with sharing class ManageItemSpecWorkOrderExt extends BaseController {
    private sObject header;

    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public String pageTitle { get; set; }
    public String subtitle { get; set; }
    public String componentTitle { get; set; }
    public String operationTitle { get; set; }
    public String objType { get; set; }
    public String headerJson { get; set; }

    public String operationConfigJson { get; set; }
    public String operationFieldListJson { get; set; }
    
    public String componentConfigJson { get; set; }
    public String componentFieldListJson { get; set; }

    @RemoteAction 
    public static JsonResult getRecords(Id headerId,String objType,String type) {
        JsonResult result = new JsonResult();
        try {
            SOQLUtil soql;
            
            if (objType == 'Item Specification') {
                if (type == 'Operation') {
                    soql = new SOQLUtil('Routing__c');
                    soql.addFields('Routing_Edit');
                    soql.setOrderByClause('Resource_Sequence__c ASC');
                } else if (type == 'Component') {
                    soql = new SOQLUtil('Component__c');
                    soql.addFields(new Set<String>{ 'Component_Item__r.Source__c'});
                    soql.addFields('Component_Edit');
                }
                soql.setWhereClause('Assembly_Item_Specification__c = :headerId');
            } else if (objType == 'Work Order') {
                String whereClause = '';
                if (type == 'Operation') {
                    soql = new SOQLUtil('Operation_Tracking__c');
                    soql.addFields('ManageOperations');
                    soql.addField('Work_Order__c');
                    soql.setOrderByClause('Sequence__c ASC');
                } else if (type == 'Component') {
                    soql = new SOQLUtil('Material_Tracking__c');
                    soql.addFields(new Set<String>{ 'Item__r.Source__c' });
                    soql.addFields('ManageMaterialEdit');
                    soql.addFields('ManageMaterialRead');
                    whereClause = 'Type__c NOT IN (\'Repair\') AND ';
                }
                
                soql.addAllCustomFields();
                
                whereClause += 'Work_Order__c = :headerId';
                soql.setWhereClause(whereClause);
            }
            
            if (type == 'Component') {
                soql.setOrderByClause('Component_Sequence__c ASC NULLS LAST');
            }
            
            result.records = Database.query(soql.getQuery());
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getItemRecord(Id itemId) {
        JsonResult result = new JsonResult();
        try {
            SOQLUtil soql;
            soql = new SOQLUtil('Item__c');
            soql.addFields(new Set<String>{'Name', 'Source__c','Description__c','Supplier__c','Non_Inventory__c','Active__c'});
        	soql.setWhereClause('Id = :itemId');
           
            result.records = Database.query(soql.getQuery());
            result.total = result.records.size();
            
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult addRecord(sObject header,String objType,String type) {
        sObject record;
        if (objType == 'Item Specification') {
            if (type == 'Operation') {
                record = new Routing__c(Facility__c = (Id)header.get('Facility__c'));
            } else if (type == 'Component') {
                record = new Component__c(Component_Item__r = new Item__c(),Yield__c = 100);
            }
            record.put('Assembly_Item_Specification__c',header.Id);
            record.put('Company__c',header.get('Company__c'));
        } else if (objType == 'Work Order') {
            if (type == 'Operation') {
                record = new Operation_Tracking__c(
                    Hours_Consumed__c = 0,
                    Quantity_Available__c = 0,
                    Quantity_Completed__c = 0,
                    Quantity_Scrapped__c = 0
                );
            } else if (type == 'Component') {
                record = new Material_Tracking__c(Type__c = 'Backflush');
            }
            record.put('Work_Order__c',header.Id);
        }
        return new JsonResult(new List<sObject>{record},1);
    }

    @RemoteAction
    public static JsonResult deleteRecords(List<sObject> records) {
        JsonResult result = new JsonResult();
        if ( records == null || records.size() == 0) return result; 
        
        Savepoint sp = Database.setSavepoint();
        try {
            SObjectType objType = records[0].getSObjectType();
            if ( objType == Operation_Tracking__c.SObjectType) {
                Map<Id, Operation_Tracking__c> mapDeleteRecords = new Map<Id, Operation_Tracking__c> ( (List<Operation_Tracking__c>) records );
                List<Operation_Tracking__c> opsToUpdate = new List<Operation_Tracking__c> ();
                Id woId;
                
                for ( Operation_Tracking__c op : (List<Operation_Tracking__c>) records ) {
                     if ( records[0].get('Work_Order__c') != null ) {
                         woId  = (Id)records[0].get('Work_Order__c');
                         break;
                     }
                }
                
                SOQLUtil opsQuery = new SOQLUtil ('Operation_Tracking__c');
                opsQuery.addFields(new Set<String> {'id','Name', 'Work_Order__r.Name', 'Quantity_Available__c','Quantity_Completed__c','Quantity_Scrapped__c','Sequence__c'});
                opsQuery.setWhereClause('Work_Order__c =:woId');
                opsQuery.setOrderByClause('Sequence__c ASC');
                
                SOQLUtil.ChildRelationship mtQuery = new SOQLUtil.ChildRelationship(opsQuery, 'Material_Trackings__r');
                mtQuery.addField('Id');
                mtQuery.setWhereClause('Item__r.Source__c = \''+ ItemService.ITEM_SOURCE_OSP + '\'');
                
                opsQuery.addChildRelationship(mtQuery);
                
                List<Operation_Tracking__c> ops = Database.query ( opsQuery.getQuery() );
                
                // Valdiate for Delete
                validateForDelete (ops, mapDeleteRecords);
                
                // Any available quantity needs to be trickled down to the next level
                for ( Integer i=0; i< ops.size(); i ++ ) {
                    if ( mapDeleteRecords.containsKey( ops[i].Id ) && ops[i].Quantity_Available__c > 0 ) {
                        Decimal qtyToComplete = ops[i].Quantity_Available__c;
                        for ( Integer j=i+1; j< ops.size(); j++ ) {
                            // this loop basically adds up all the possible qtyToComplete till the next op which is not deleted
                            if ( mapDeleteRecords.containsKey(ops[j].id ) ) { // when the next op is being deleted too
                                // note completed op cannot be deleted - controlled from UI
                                qtyToComplete = KSE.addQuantityToField(qtyToComplete,ops[j].Quantity_Available__c);
                                continue;
                            } else {
                                ops[j].Quantity_Available__c = KSE.addQuantityToField(ops[j].Quantity_Available__c,qtyToComplete);
                                opsToUpdate.add ( ops[j] );
                                qtyToComplete = null; // setting to null after assigning the qty to new op
                                i=j; // skipping the deleted ops in the chunk we have traversed
                                break;
                            }
                        }
                        
                        // cannot delete if the completed operation qty available cannot be assigned
                        // case when you are delete the last few operations
                        if ( qtyToComplete != null ) {
                            throw new ManageItemSpecWorkOrderException(ops[i].Name + ' Cannot delete as there are outstanding Quantity Available');
                        }
                    }
                }
                
                DML.updateAsUser(opsToUpdate);
            }
            else if(objType == Material_Tracking__c.SObjectType){
            	//KNDY-14682 -Cancelling PO Lines related to Material Trackings to be deleted.
                Set<Id> mtIds = new Set<Id>();
                for ( Material_Tracking__c mt : (List<Material_Tracking__c>) records ) {
                    mtIds.add(mt.Id);
                }
                
                SOQLUtil polQuery = new SOQLUtil ('Purchase_Order_Line__c');
                polQuery.addFields(new Set<String> {'id','Status__c', 'Material_Tracking__c', 'Purchase_Order__c'});
                polQuery.setWhereClause('Material_Tracking__c IN:mtIds and Quantity_Received__c = 0');
                
                
                List<Purchase_Order_Line__c> polines = Database.query ( polQuery.getQuery() );
                
                if(polines.size()>0){
                	PurchaseOrderService.cancelPOLines(polines,false);
	            }
		        
            }
            DMl.deleteAsUser(records);
            
            
        } catch(Exception e) {
            Database.rollback(sp);
            result.success = false;
			Database.rollback( sp );
            String msg;
            if (e instanceof DMLException) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            result.addMessage(msg,ApexPages.Severity.FATAL);
        }
        
        return result;
    }
    
    static void validateForDelete ( List<Operation_Tracking__c> ops, Map<Id, Operation_Tracking__c> mapDeleteRecords) {
        if ( mapDeleteRecords.containsKey( ops[ops.size()-1 ].Id) && ops[ops.size()-1 ].Quantity_Available__c > 0  ) {
            throw new ManageItemSpecWorkOrderException ('You can’t delete the last operation of this work order because you’ve already recorded all previous operations.' );
        }
    }
    
    @RemoteAction 
    public static JsonResult saveRecords(Id headerId,String objType,String type,List<sObject> updatedRows,List<String> dateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            Set<String> requiredFields;
            if (objType == 'Item Specification') {
                if (type == 'Operation') {
                    requiredFields = new Set<String>{ 'Resource_Sequence__c','Work_Center__c','Work_Center_Resource__c','Resource_Quantity__c','Standard_Hours__c' };
                    requiredFields.addAll(SchemaUtil.getInstance().getFieldsFromFieldSetString(Routing__c.sObjectType,'RequiredFields'));
                } else if (type == 'Component') {
                    requiredFields = new Set<String>{ 'Component_Item__c','Quantity_per_Assembly__c','Type__c' };
                    requiredFields.addAll(SchemaUtil.getInstance().getFieldsFromFieldSetString(Component__c.sObjectType,'RequiredFields'));
                }
            } else if (objType == 'Work Order') {
                if (type == 'Operation') {
                    requiredFields = new Set<String>{ 'Sequence__c','Work_Center__c','Work_Center_Resource__c','Resource_Quantity__c','Standard_Hours__c' };
                    requiredFields.addAll(SchemaUtil.getInstance().getFieldsFromFieldSetString(Operation_Tracking__c.sObjectType,'RequiredFields'));
                } else if (type == 'Component') {
                    requiredFields = new Set<String>{ 'Item__c','Quantity_Required__c','Type__c' };
                    requiredFields.addAll(SchemaUtil.getInstance().getFieldsFromFieldSetString(Material_Tracking__c.sObjectType,'RequiredFields'));
                }
            }
           
            for (sObject record:updatedRows) {
                KendoUtils.UpdateDateFields(record,dateFields);
                
                for (String fld:requiredFields) {
                    if (record.get(fld) == null && (fld != 'Quantity_Required__c' || objType != 'Work Order' || type != 'Component' || record.getSObject('Item__r').get('Source__c') != ItemService.ITEM_SOURCE_OSP)) {
                        String obj;
                        if (objType == 'Item Specification') {
                            if (type == 'Operation') obj = 'Routing__c';
                            else obj = 'Component__c';
                        } else {
                            if (type == 'Operation') obj = 'Operation_Tracking__c';
                            else obj = 'Material_Tracking__c';
                        }

                        throw new ManageItemSpecWorkOrderException(Schema.getGlobalDescribe().get(KSE.NamespaceUU + obj).getDescribe().fields.getMap().get(KSE.NamespaceUU + fld).getDescribe().getLabel() + ' ' + Label.is_required);
                    }
                }
            }
            
            if (objType == 'Item Specification') {
                if (type == 'Operation') {
                    List<Routing__c> routings = new List<Routing__c>();
                    routings.addAll((List<Routing__c>)updatedRows);

                    List<Routing__c> routingsToUpdate = new List<Routing__c>();
                    List<Routing__c> routingsToInsert = new List<Routing__c>();
                    for (Routing__c routing:routings) {
                        routing.Assembly_Item_Specification_Sequence__c = null;

                        if (routing.Id != null) {
                            routingsToUpdate.add(routing);
                        } else {
                            routingsToInsert.add(routing);
                        }
                    }
                
                    DML.updateAsUser(routingsToUpdate);
                    DML.insertAsUser(routingsToInsert);
                } else if (type == 'Component') {
                    List<Component__c> components = new List<Component__c>();
                    components.addAll((List<Component__c>)updatedRows);

                    Set<Id> itemIds = new Set<Id>();
                    for (Component__c component:components) {
                        if (component.Supplier__c == null) itemIds.add(component.Component_Item__c);
                    }

                    if (itemIds.size() > 0) {
                        SOQLUtil itemQuery = new SOQLUtil('Item__c');
                        itemQuery.addFields(new Set<String>{ 'Id','Name','Supplier__c','Source__c' });
                        itemQuery.setWhereClause('Id IN :itemIds');
                        Map<Id,Item__c> items = new Map<Id,Item__c>((List<Item__c>)Database.query(itemQuery.getQuery()));

                        for (Component__c component:components) {
                            Item__c item = items.get(component.Component_Item__c);
                            if (component.Supplier__c == null && item.Source__c == ItemService.ITEM_SOURCE_OSP) {
                                component.Supplier__c = item.Supplier__c;
                            }
                        }
                    }
                
                    DML.checkUpsertAsUser(components); upsert components;
                }
            } else if (objType == 'Work Order') {
                SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
                woQuery.addAllCustomFields();
                woQuery.setWhereClause('Id = :headerId');
                Work_Order__c wo = (Work_Order__c)Database.query(woQuery.getQuery())[0];
                
                if (type == 'Operation') {
                    List<Operation_Tracking__c> ops = new List<Operation_Tracking__c>();
                    ops.addAll((List<Operation_Tracking__c>)updatedRows);
                    
                    SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
                    opQuery.addAllCustomFields();
                    opQuery.setWhereClause('Id IN :ops');
                    opQuery.setOrderByClause('Sequence__c ASC');
                    Map<Id,Operation_Tracking__c> existingOps = new Map<Id,Operation_Tracking__c>((List<Operation_Tracking__c>)Database.query(opQuery.getQuery()));
                    
                    Map<Id,DateTime> oldStartDates = new Map<Id,DateTime>();
                    Map<Id,DateTime> newStartDates = new Map<Id,DateTime>();
                    List<Operation_Tracking__c> opsToUpdate = new List<Operation_Tracking__c>();
                    List<Operation_Tracking__c> opsToInsert = new List<Operation_Tracking__c>();
                    
                    List<OperationsSortWrapper> sortedOperations = new List<OperationsSortWrapper>();
                    for (Operation_Tracking__c op:ops) { 
                        OperationsSortWrapper wrapper = new OperationsSortWrapper (op);
                        sortedOperations.add( wrapper);
                    }
                    
                    sortedOperations.sort();
                    
                    Integer opIndx = 0;
                    for (Integer index=0; index < sortedOperations.size(); index ++) {
                        Operation_Tracking__c op = sortedOperations[index].op;
                        Operation_Tracking__c existingOp = existingOps.get(op.Id);
                        op.Unique__c = null;

                        if (existingOp != null) {
                            if (op.Start_Date__c != existingOp.Start_Date__c) {
                                oldStartDates.put(op.Id,existingOp.Start_Date__c);
                                newStartDates.put(op.Id,op.Start_Date__c);
                            }

                            opsToUpdate.add(op);
                        } else {
                            if ( index == 0 || (index < (sortedOperations.size()-1) && !isNewOperationTracking(sortedOperations[index-1].op)) ) { // if prev operation is nota new operation
                                for (Integer jIndex=index+1;jIndex < sortedOperations.size(); jIndex ++ ) {
                                    if ( !isNewOperationTracking ( sortedOperations[jIndex].op ) ) {
                                        op.Quantity_Available__c = KSE.addQuantityToField(op.Quantity_Available__c, KSE.addQuantityToField(sortedOperations[jIndex].op.Quantity_Available__c,sortedOperations[jIndex].op.Quantity_Completed__c)   );
                                        
                                        // updating Qty To Complete for the operation, if the prev operation is a new op
                                        // when the previous operation is a new operation 
                                        if ( isOperationCompleted ( sortedOperations[jIndex].op )) { 
                                            sortedOperations[jIndex].op.Quantity_Available__c =  KSE.subtractDecimals( 0, sortedOperations[jIndex].op.Quantity_Completed__c );
                                        } else {
                                            sortedOperations[jIndex].op.Quantity_Available__c = 0;
                                        }    
                                        break;
                                    }
                                }
                            }
                            
                            opsToInsert.add(op);
                        }
                    }
                    
                    if (oldStartDates.size() > 0) {
                        Set<Id> opIds = oldStartDates.keySet();
                        SOQLUtil materialQuery = new SOQLUtil('Material_Tracking__c');
                        materialQuery.addAllCustomFields();
                        materialQuery.setWhereClause('Operation_Tracking__c IN :opIds');
                        
                        List<Material_Tracking__c> materialsToUpdate = new List<Material_Tracking__c>();
                        for (Material_Tracking__c material:Database.query(materialQuery.getQuery())) {
                            if (material.Required_Date__c == oldStartDates.get(material.Operation_Tracking__c)) {
                                material.Required_Date__c = newStartDates.get(material.Operation_Tracking__c);
                                materialsToUpdate.add(material);
                            }
                        }
                        
                        if (materialsToUpdate.size() > 0) DML.updateAsUser(materialsToUpdate);
                    }
                    
                    DML.updateAsUser(opsToUpdate);
                    DML.insertAsUser(opsToInsert);
                } else if (type == 'Component') {
                    List<Material_Tracking__c> mts = new List<Material_Tracking__c>();
                    mts.addAll((List<Material_Tracking__c>)updatedRows);
                    Map<Id, List<Material_Tracking__c>> mtOperationMap = new Map<Id, List<Material_Tracking__c>>();
                    for (Material_Tracking__c mt:mts) {
                        if (mt.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP && mt.Quantity_Required__c == null) mt.Quantity_Required__c = wo.Order_Quantity__c;
                        mt.Quantity_Per_Assembly__c = mt.Quantity_Required__c / wo.Order_Quantity__c;

                        if (mt.Id == null) {
                            if (mt.Type__c == WorkOrderService.MATERIAL_TYPE_BYPRODUCT) {
                                mt.Quantity_Completed__c = 0;
                            } else {
                                mt.Quantity_Allocated__c = 0;
                                mt.Quantity_Issued__c = 0;
                                mt.Quantity_Used__c = 0;
                                mt.Quantity_Scrapped__c = 0;
                            }

                            if (mt.Required_Date__c == null) {
                                if (mt.Operation_Tracking__c != null) {
                                    if (mtOperationMap.containsKey(mt.Operation_Tracking__c) == false) mtOperationMap.put(mt.Operation_Tracking__c, new List<Material_Tracking__c>{ mt });
                                    else mtOperationMap.get(mt.Operation_Tracking__c).add(mt);
                                } else {
                                    mt.Required_Date__c = wo.Start_Date2__c;
                                }
                            }
                        }
                    }

                    if (mtOperationMap.size() > 0) {
                        Set<Id> opIds = mtOperationMap.keySet();
                        SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
                        opQuery.addFields(new Set<String>{ 'Id', 'Name', 'Start_Date__c' });
                        opQuery.setWhereClause('Id IN :opIds');
                        for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
                            for (Material_Tracking__c mt:mtOperationMap.get(op.Id)) mt.Required_Date__c = op.Start_Date__c;
                        }
                    }
                
                    DML.checkUpsertAsUser(mts); upsert mts;
                }
            }
        } catch(Exception e) {
            Database.rollback(sp);
            result.success = false;

            String msg;
            if (e instanceof DMLException) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            result.addMessage(msg,ApexPages.Severity.FATAL);
        }
        return result;
    }

    @RemoteAction 
    public static JsonResult getStdRecords(String type,Id templateId,sObject header) {
        JsonResult result = new JsonResult();

        try {
            SOQLUtil soql;

            if (type == 'Operation') {
                soql = new SOQLUtil('Routing__c');
                soql.addFields('Routing_Edit');
                soql.setOrderByClause('Resource_Sequence__c ASC');
            } else if (type == 'Component') {
                soql = new SOQLUtil('Component__c');
                soql.addFields('Component_Edit');
                soql.setOrderByClause('Component_Sequence__c ASC');
            }
            soql.setWhereClause('Assembly_Item_Specification__c = :templateId');

            List<sObject> records = Database.query(soql.getQuery());

            if (header.getSObjectType() == Item_Specification__c.sObjectType) {
                for (sObject rec:records) {
                    rec.Id = null;
                    rec.put('Assembly_Item_Specification__c',header.Id);
                    rec.put('Company__c',(Id)header.get('Company__c'));

                    if (type == 'Operation') {
                        rec.put('Facility__c',(Id)header.get('Facility__c'));
                    }
                }
            }
            
            result.records = records;
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction 
    public static JsonResult getpkgFieldList() {  
    	JSONResult result = new JSONResult();
    	//Getting Package Fields from MT:
        List<String>mtPackagefields = new List<String>(SchemaUtil.getInstance().getAllPackagedFieldsFromSObject(KSE.NamespaceUU,'Material_Tracking__c'));
        
        List<object> records = (List<object>) mtPackagefields;
        result.records = records;
        return result;
    }

    public ManageItemSpecWorkOrderExt() {
        Id recordId;
        try {
            recordId = (Id)ApexPages.currentPage().getParameters().get('id');
            if (recordId.getSObjectType() != Item_Specification__c.sObjectType && recordId.getSObjectType() != Work_Order__c.sObjectType)
                throw new ManageItemSpecWorkOrderException('Wrong type');
        } catch(Exception e) {
            throw new ManageItemSpecWorkOrderException('Invalid Id: ' + ApexPages.currentPage().getParameters().get('id'));
        }
        
        GridRelatedListController.GridRelatedListConfig operationConfig = new GridRelatedListController.GridRelatedListConfig();
        operationConfig.uniqueId = 'operationGrid';
        
        GridRelatedListController.GridRelatedListConfig componentConfig = new GridRelatedListController.GridRelatedListConfig();
        componentConfig.uniqueId = 'componentGrid';
        
        List<FieldInfo> operationFIList;
        List<FieldInfo> componentFIList;
        
        if (recordId.getSObjectType() == Item_Specification__c.sObjectType) {
            objType = 'Item Specification';
            pageTitle = 'Manage Routings/Components';
            operationTitle = 'Routings';
            componentTitle = 'Components';
            
            SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
            itemSpecQuery.addFields(new Set<String>{ 'Id','Name','Company__c','Facility__c' });
            itemSpecQuery.setWhereClause('Id = :recordId');
            
            header = Database.query(itemSpecQuery.getQuery());
            
            operationConfig.objectName = 'Routing__c';
            operationConfig.parentField = 'Assembly_Item_Specification__c';
            
            componentConfig.objectName = 'Component__c';
            componentConfig.parentField = 'Assembly_Item_Specification__c';
            
            operationFIList = FieldInfo.fetchJsonFieldInfos('Routing__c','Routing_Edit',null);
            
            componentFIList = FieldInfo.fetchJsonFieldInfos('Component__c','Component_Edit',null);
        } else if (recordId.getSObjectType() == Work_Order__c.sObjectType) {
            objType = 'Work Order';
            pageTitle = 'Manage Operations/Material';
            operationTitle = 'Operations';
            componentTitle = 'Material';
            
            SOQLUtil workOrderQuery = new SOQLUtil('Work_Order__c');
            workOrderQuery.addFields(new Set<String>{ 'Id','Name','Status__c','Company__c','Type__c','Order_Quantity__c','Quantity_Complete__c','Quantity_Scrapped__c','Facility__c' });
            workOrderQuery.setWhereClause('Id = :recordId');
            
            header = Database.query(workOrderQuery.getQuery());

            if ((String)header.get('Status__c') == WorkOrderService.WO_STATUS_CANCELLED) {
                throw new ManageItemSpecWorkOrderException(Label.WorkOrder_accounted_or_cancelled);
            } else if ((String)header.get('Status__c') == WorkOrderService.WO_STATUS_DRAFT) {
                throw new ManageItemSpecWorkOrderException(Label.WorkOrder_not_released);
            } else if ((String)header.get('Status__c') == WorkOrderService.WO_STATUS_CLOSED) {
                throw new ManageItemSpecWorkOrderException(Label.WorkOrder_already_closed);
            }
            
            operationConfig.objectName = 'Operation_Tracking__c';
            operationConfig.parentField = 'Work_Order__c';
            
            componentConfig.objectName = 'Material_Tracking__c';
            componentConfig.parentField = 'Work_Order__c';
            if ((Decimal)header.get('Quantity_Complete__c') > 0 || (Decimal)header.get('Quantity_Scrapped__c') > 0) {
                operationFIList = FieldInfo.fetchJsonFieldInfos('Operation_Tracking__c','ManageOperations',null,true);
            } else {
                operationFIList = FieldInfo.fetchJsonFieldInfos('Operation_Tracking__c','ManageOperations',null);
            }

            componentFIList = FieldInfo.fetchJsonFieldInfos('Material_Tracking__c','ManageMaterialEdit',null);
            List<FieldInfo> addlComponentFields = FieldInfo.fetchJsonFieldInfos('Material_Tracking__c','ManageMaterialRead',null,true);
            addlComponentFields.remove(0);
            componentFIList.addAll(addlComponentFields);
        }
        
        headerJson = JSON.serialize(header);
        subtitle = (String)header.get('Name');
        
        operationConfig.title = operationTitle;
        operationConfig.parentRecord = header;
        operationConfig.alwaysUseFullDateTimeFormat = false;
        operationConfigJson = JSON.serialize(operationConfig);
        
        operationFIList.remove(0);
        for (FieldInfo fi:operationFIList) {
        	fi.required = false;
            if (fi.field.toLowerCase() == 'name' || fi.field.toLowerCase() == 'quantity_available__c' || fi.field.toLowerCase() == 'quantity_completed__c' || fi.field.toLowerCase() == 'quantity_scrapped__c') {
                fi.editable = false;
            }
        }
        operationFieldListJson = JSON.serialize(operationFIList);
        
        componentConfig.title = componentTitle;
        componentConfig.parentRecord = header;
        componentConfig.alwaysUseFullDateTimeFormat = false;
        componentConfigJson = JSON.serialize(componentConfig);
        
        componentFIList.remove(0);
        for (FieldInfo fi:componentFIList) {
            fi.required = false;
            if (fi.field.toLowerCase() == 'quantity_issued__c' || fi.field.toLowerCase() == 'quantity_short__c' || fi.field.toLowerCase() == 'quantity_used__c' || fi.field.toLowerCase() == 'quantity_scrapped__c') {
                fi.editable = false;
            }
        }
        componentFieldListJson = JSON.serialize(componentFIList);
    }

    public String stdOperationFieldListJson {
        get {
            if (stdOperationFieldListJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Routing__c','Routing_Edit',null,true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) {
                    fi.required = false;

                    if (fi.field.toLowerCase() == 'resource_sequence__c') {
                        fi.editable = true;
                    }
                }
                stdOperationFieldListJson = JSON.serialize(fiList);
            }
            return stdOperationFieldListJson;
        } set;
    }

    public String stdComponentFieldListJson {
        get {
            if (stdComponentFieldListJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Component__c','Component_Edit',null,true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) {
                    fi.required = false;

                    if (fi.field.toLowerCase() == 'component_sequence__c') {
                        fi.editable = true;
                    }
                }
                stdComponentFieldListJson = JSON.serialize(fiList);
            }
            return stdComponentFieldListJson;
        } set;
    }

    public PageReference cancel() {
        return new PageReference('/' + header.Id);
    }
    
    // Will return true in partial complete/scrap cases too
    static Boolean isOperationCompleted ( Operation_Tracking__c op ) {
        return ( op.quantity_scrapped__c > 0 || op.quantity_completed__c > 0);
    }
    
    static Boolean isNewOperationTracking ( Operation_Tracking__c op ) {
        return op.Id == null;
    }
    
    public class ManageItemSpecWorkOrderException extends Exception { }
    
    
    // Primarily for sorting the Operations list based on sequence 
    public class OperationsSortWrapper implements Comparable {
        public Operation_Tracking__c op {get;set;}
        
        public OperationsSortWrapper ( Operation_Tracking__c op ) {
            this.op = op;
        }
        
        public Integer compareTo (Object compOp) {
            OperationsSortWrapper compareOp = (OperationsSortWrapper) compOp;
            if ( op.Sequence__c == compareOp.op.Sequence__c ) {
                return 0;
            } else if ( op.Sequence__c > compareOp.op.Sequence__c ) {
                return 1;
            } 
            return -1;
        }
    }   
}