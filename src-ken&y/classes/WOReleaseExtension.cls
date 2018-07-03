public with sharing class WOReleaseExtension {
    public String namespace { get; set; } { namespace = KSE.NamespaceUU; }
    public String workOrdersJson { get; set; } { workOrdersJson = JSON.serialize(new List<Work_Order__c>()); }
    public Boolean disable { get; set; } { disable = false; }
    public String retUrl { get; set; } { retUrl = '/' + Work_Order__c.sObjectType.getDescribe().getKeyPrefix(); }

    public WOReleaseExtension(ApexPages.StandardSetController setCon) {
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Work_Orders_Selected));
            disable = true;
            return;
        }
        
        try {
            Set<Id> woIds = new Set<Id>();
            for (Work_Order__c wo:(List<Work_Order__c>)setCon.getSelected()) woIds.add(wo.Id);
            List<Work_Order__c> workOrders = WorkOrderService.getWorkOrders(woIds, null, null, null);
            workOrdersJson = JSON.serialize(workOrders);

            WorkOrderPlanningService.validateForRelease(workOrders);
           	Set<Id> assemblyIds = new Set<Id>();
          	Map<Id,Work_Order__c> worderAssemblymap = new Map<Id,Work_Order__c>();
            Map<Id,List<SObject>> ospComponentmap = new Map<Id,List<SObject>>();
            Map<Id,Id> routingAssemblymap = new Map<Id,Id>();
		    for(Work_Order__c worder:workOrders){
				if (worder.Status__c == WorkOrderService.WO_STATUS_DRAFT && worder.Assembly_Item_Specification__c != null) {
		        	assemblyIds.add(worder.Assembly_Item_Specification__c);
	        		if(!worderAssemblymap.containskey(worder.Assembly_Item_Specification__c)){
	         	 		worderAssemblymap.put(worder.Assembly_Item_Specification__c,worder);
	         		}
		      	}
		   	}
		   	if(assemblyIds.size()>0){
		   		String errorWORecs = '';
		   		SOQLUtil componentQuery = new SOQLUtil('Component__c');
		        componentQuery.addAllCustomFields();
		        componentQuery.addAllCustomFields(Item__c.sObjectType,'Component_Item__r');
		        componentQuery.setOrderByClause('Component_Item__r.Name');
		        componentQuery.setWhereClause('Assembly_Item_Specification__c IN :assemblyIds AND Component_Item__r.Source__c = \'' + ItemService.ITEM_SOURCE_OSP + '\'');
		        for (Component__c component:Database.query(componentQuery.getQuery())) {
		            if (!ospComponentmap.containskey(component.Routing__c)) {
			        		ospComponentmap.put(component.Routing__c,new list<SObject>{component});
		             }
		             else{
		             	ospComponentmap.get(component.Routing__c).add(component);
		             	Work_Order__c woRec = worderAssemblymap.get(component.Assembly_Item_Specification__c);
		             	errorWORecs = errorWORecs + woRec.Name+ ' ,';
		             }
		        }
		       if (errorWORecs.length() > 0){
		    		errorWORecs = errorWORecs.subString(0,errorWORecs.length()-1);
		    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can release subcontracted work orders with more than one supplier from the Work Order Detail view. The following work orders with more than one supplier were not released:'+errorWORecs));
		            disable = true;
		            return;
		    	}
		   	}
	       	
            
            
            
        } catch (Exception e) {
            CustomException.addError(e);
            disable = true;
        }
    }

    @RemoteAction
    public static JsonResult release(List<Id> woIds) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            WorkOrderPlanningService.release(new Set<Id>(woIds));
        } catch (Exception e) {
            Database.rollback(sp);
            CustomException.addError(result, e);
        }
        return result;
    }

    public String woFieldsJson {
        get {
            if (woFieldsJson == null) woFieldsJson = JSON.serialize(FieldInfo.fetchJsonFieldInfos('Work_Order__c', 'Release_Display_List'));
            return woFieldsJson;
        } set;
    }
}