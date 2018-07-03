public with sharing class ComponentTriggerHandler {
    public static void afterInsert() { validateOSP(Trigger.new); }
    public static void afterUpdate() { validateOSP(Trigger.new); }

    public static void validateOSP(List<sObject> components) {
        sObjectType objType;
        String itemField;
        String operationField;
        String companyField;
        Map<Id,Id> itemIds = new Map<Id,Id>();
        Set<Id> woIds = new Set<Id>();
        for (sObject component:components) {
            objType = component.getSObjectType();
            if (objType == Component__c.sObjectType) {
                itemField = 'Component_Item__';
                operationField = 'Routing__c';
                companyField = 'Company__r';
            } else {
                itemField = 'Item__';
                operationField = 'Operation_Tracking__c';
                companyField = 'Work_Order__r.Company__r';
                woIds.add((Id)component.get('Work_Order__c'));
            }
            itemIds.put(component.Id,(Id)component.get(itemField + 'c'));
        }

        SOQLUtil itemQuery = new SOQLUtil('Item__c');
        itemQuery.addFields(new Set<String>{ 'Id','Name','Source__c','Supplier__c','Description__c','Non_Inventory__c'});
        itemQuery.setWhereClause('Id IN (\'' + String.join(itemIds.values(),'\',\'') + '\')');
        Map<Id,Item__c> items = new Map<Id,Item__c>((List<Item__c>)Database.query(itemQuery.getQuery()));

        Map<Id,Id> lastOperations = new Map<Id,Id>();
        if (woIds.size() > 0) {
            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addFields(new Set<String>{ 'Id','Name','Sequence__c','Work_Order__c' });
            opQuery.setWhereClause('Work_Order__c IN :woIds');
            opQuery.setOrderByClause('Sequence__c DESC');
            for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
                if (!lastOperations.containsKey(op.Work_Order__c)) {
                    lastOperations.put(op.Work_Order__c,op.Id);
                }
            }
        }

        Set<Id> operationIds = new Set<Id>();
        for (sObject component:components) {
            Item__c item = items.get(itemIds.get(component.Id));

            if (item.Source__c == ItemService.ITEM_SOURCE_OSP) {
                if ((String)component.get('Type__c') != WorkOrderService.MATERIAL_TYPE_BACKFLUSH && (String)component.get('Type__c') != WorkOrderService.MATERIAL_TYPE_KIT) {
                    component.addError(item.Name + ': Outside processing components must be of type backflush or kit');
                    return;
                }
                if (component.get(operationField) == null) {
                    component.addError(item.Name + ': Outside processing components must be associated with a routing/operation');
                    return;
                }
                if (objType == Material_Tracking__c.sObjectType && lastOperations.get((Id)component.get('Work_Order__c')) == (Id)component.get(operationField)) {
                    component.addError(item.Name + ': Outside processing components cannot be associated with the last operation');
                    return;
                }
                if(objType == Component__c.sObjectType && component.get('Supplier__c') == null || component.get('Supplier__c') == ''){
                	component.addError(item.Name + ': You can’t create an outside processing component without a supplier.');
                    return;
                }
                else if(objType == Material_Tracking__c.sObjectType && component.get('Supplier__c') == null || component.get('Supplier__c') == ''){
                	component.addError(item.Name + ': You can’t create an outside processing material tracking  without a supplier.');
                    return;
                }
                if(objType == Component__c.sObjectType && ((Decimal)component.get('Quantity_per_Assembly__c') >1 || (Decimal)component.get('Quantity_per_Assembly__c') <1)){
                	component.addError(item.Name + ': Quantity per Assembly cannot be greater/less than 1 for an outside processing item.');
                    return;
                }
            }

            if (component.get(operationField) != null) {
                operationIds.add((Id)component.get(operationField));
            }
        }

        if (operationIds.size() > 0) {
            SOQLUtil operationQuery = new SOQLUtil(operationField);
            operationQuery.addFields(new Set<String>{ 'Id','Name' });
            operationQuery.setWhereClause('Id IN :operationIds');

            SOQLUtil.ChildRelationship componentSubquery = objType == Component__c.sObjectType ? new SOQLUtil.ChildRelationship(operationQuery,'Components__r') : new SOQLUtil.ChildRelationship(operationQuery,'Material_Trackings__r');
            componentSubquery.addFields(new Set<String>{ 'Id','Name','Type__c',itemField + 'c','Supplier__c',itemField + 'r.Source__c',companyField + '.Serial_Control__c',itemField + 'r.Item_Attribute__c',itemField + 'r.Item_Attribute__r.Serial_Number__c' });
            if(objType == Component__c.sObjectType){
            	componentSubquery.addFields(new Set<String>{ 'Routing__c'});
            }
            else{
            	componentSubquery.addFields(new Set<String>{'Operation_Tracking__c'});
            }
            operationQuery.addChildRelationship(componentSubquery);
			List<sObject> operations = Database.query(operationQuery.getQuery());
			
            for (sObject operation:operations) {
                Boolean ospFound = false;
                Boolean bpFound = false;
                Boolean serialItemFound = false;
                List<sObject> componentList = objType == Component__c.sObjectType ? operation.getSObjects('Components__r') : operation.getSObjects('Material_Trackings__r');
                Map<Id,sObject> ospSuppliermap = new Map<Id,sObject>();
				Map<String,Id> routingOpItemmap = new Map<String,Id>();
                		
                for (sObject component:componentList) {
                    String serialControl;
                    String key = '';
                    sObject curObj = component;
                    for (String companyPart:companyField.split('\\.')) {
                        curObj = curObj.getSObject(companyPart);
                    }

                    if ((String)component.get('Type__c') == WorkOrderService.MATERIAL_TYPE_BYPRODUCT) {
                        bpFound = true;
                    }

                    if ((String)component.getSObject(itemField + 'r').get('Source__c') == ItemService.ITEM_SOURCE_OSP) {
                    	key = (Id)component.get('Supplier__c');
                    	if(!ospSuppliermap.containskey(key)){
							ospSuppliermap.put(key,component);
						}
						else if (ospSuppliermap.containskey(key)) {
							components[0].addError((String)operation.get('Name') + ': You can’t choose same supplier on a outside processing component associated to same routing/operation.');
                            return;
                        }
                        Id rkey;
                        if(objType == Component__c.sObjectType){
                        	rkey = (Id)component.get('Routing__c');
                        }
                        else if(objType != Component__c.sObjectType){
                        	rkey = (Id)component.get('Operation_Tracking__c');
                        }
                        
                        if(!routingOpItemmap.containskey(rkey)){
                        	routingOpItemmap.put(rkey,(Id)component.get(itemField + 'c'));
                        }		
                        
                        

                        ospFound = true;
                    } else if ((String)curObj.get('Serial_Control__c') == SkidService3.AT_RECEIPT && component.getSObject(itemField + 'r').get('Item_Attribute__c') != null && (Boolean)component.getSObject(itemField + 'r').getSObject('Item_Attribute__r').get('Serial_Number__c')) {
                        serialItemFound = true;
                    }
                }
                if (ospFound) {
                    if (bpFound) {
                        components[0].addError((String)operation.get('Name') + ': Outside processing components and byproduct components cannot be associated with the same routing/operation');
                        return;
                    }
                    if (serialItemFound) {
                        components[0].addError((String)operation.get('Name') + ': Outside processing components and serialized components cannot be associated with the same routing/operation');
                        return;
                    }
                }
            }
        }
    }


    public static void beforeInsert() { }
    public static void beforeUpdate() { }
    public static void beforeDelete() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}