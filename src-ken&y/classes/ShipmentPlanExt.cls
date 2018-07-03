public with sharing class ShipmentPlanExt extends GridRelatedListController {
		
	public String salesOrderLineFieldList ;
	public String fulfillmentLinesFieldList ;
	
	public GridRelatedListController.GridRelatedListConfig salesOrderLinesGridConfig {get; set;}
	public GridRelatedListController.GridRelatedListConfig fulfillmentLinesGridConfig {get; set;}
	
	public class PlanWrapper {
		public Shipment__c selectedPlan ;
		public List<Shipment__c> availablePlans ;
		public List<Sales_Order_Line__c> linesToPlan ;
		
		public PlanWrapper(){
			
		}
	}
	
	public ShipmentPlanExt(ApexPages.StandardController sCon){
		
		if(! Test.isRunningTest()){
			sCon.addFields(new List<string>{'Name','Id'});
		}
		
		// Sales Order Lines Grid Config
        salesOrderLinesGridConfig = new GridRelatedListController.GridRelatedListConfig();
        salesOrderLinesGridConfig.uniqueId = 'salesOrderLinesGrid';
        salesOrderLinesGridConfig.title = '';
        salesOrderLinesGridConfig.objectName = 'Shipment__c';
        salesOrderLinesGridConfig.fieldset = 'Planning_Detail';
        salesOrderLinesGridConfig.buttons = '';
        salesOrderLinesGridConfig.alwaysUseFullDateTimeFormat = false;
        
        // Available shipments Grid Config
        fulfillmentLinesGridConfig = new GridRelatedListController.GridRelatedListConfig();
        fulfillmentLinesGridConfig.uniqueId = 'fulfillmentLinesGrid';
        fulfillmentLinesGridConfig.title = '';
        fulfillmentLinesGridConfig.objectName = 'Sales_Order_Line__c'; 
        fulfillmentLinesGridConfig.fieldset = 'Planning_Detail';
        fulfillmentLinesGridConfig.buttons = '';
        fulfillmentLinesGridConfig.alwaysUseFullDateTimeFormat = false;
	}
	
	public String getSalesOrderLinesGridConfigJson() {
        String configStr = JSON.serialize(this.salesOrderLinesGridConfig);
        return configStr;
    }
    
    public String getFulfillmentLinesGridConfigJson() {
        String configStr = JSON.serialize(this.fulfillmentLinesGridConfig);
        return configStr;
    }
    
	public String getSalesOrderLineFieldList() {
		
        if (String.isBlank(salesOrderLineFieldList) && salesOrderLinesGridConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	
        	// get the Payment line details field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(salesOrderLinesGridConfig.objectName, salesOrderLinesGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> {'Id'};
            
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	
            	if(fieldName != 'Id' && fieldName != 'Name'){
                    fieldInfoList[i].field = 'selectedPlan.' + fieldName;
                }
                
            	fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            salesOrderLineFieldList = JSON.serialize(fieldInfoList);
        }
        
        return salesOrderLineFieldList;
    }
    
    public String getFulfillmentLinesFieldList() {
       
        if (String.isBlank(fulfillmentLinesFieldList) && fulfillmentLinesGridConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	
        	// get the Substitutions field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(fulfillmentLinesGridConfig.objectName, fulfillmentLinesGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	if(fieldName != 'Id' && fieldName != 'Name'){
            		//fieldInfoList[i].field = NamespaceUU + fieldName;
            	}
            	fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
        	
            fulfillmentLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return fulfillmentLinesFieldList;
    }
    
	@RemoteAction
	public static JsonResult getSalesOrderLines(List<String> filters){
		
		List<PlanWrapper> solWrapperList = new List<PlanWrapper>();
		Map<Shipment__c, List<Shipment__c>> shipmentsMap = new Map<Shipment__c, List<Shipment__c>>();
		Map<Shipment__c, List<Sales_Order_Line__c>> fulfillmentLinesMap = new Map<Shipment__c, List<Sales_Order_Line__c>>();
		Map<String, Set<String>> shipmentFilters = new Map<String, Set<String>>(); 
		List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>(); 
		Set<String> shipFromLocationIds = new Set<String>();
		Set<String> shipToIds = new Set<String>();
		
		SchemaUtil shUtil = new SchemaUtil();
		
		String whereClause = '';
		
		filters.add(' Quantity_Backordered__c > 0 ');
		filters.add(' Status__c = \'Open\' ');
							 
		Iterator<String> iFilters = filters.iterator();
        
        while(iFilters.hasNext()){
            whereClause += iFilters.next();
            
            if(iFilters.hasNext()){
                whereClause += ' and ';    
            }
        }
        					 
		/*String solQuery = shUtil.generateQueryFromFieldSet('Sales_Order_Line__c', 
															  new Set<String>{'Planning_Detail'}, 
															  new Set<String>{'Id', 'Name', 'Ship_From_Location__c', 'Quantity_Planned__c', 'Quantity_Shipped__c', 
															  				  'Quantity_Ordered__c', 'Ship_From_Location__r.Name', 
															  				  'Sales_Order__r.Ship_To__c', 'Sales_Order__r.Ship_To__r.Name'}, 
															  whereClause
														  );*/
		
		SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
	    soql.addFields('Planning_Detail');
	    soql.addFields(new Set<String>{'Id', 'Name', 'Ship_From_Location__c', 'Quantity_Planned__c', 'Quantity_Shipped__c', 
															  				  'Quantity_Ordered__c', 'Ship_From_Location__r.Name', 
															  				  'Sales_Order__r.Ship_To__c', 'Sales_Order__r.Ship_To__r.Name'
					  });
	    soql.setWhereClause(whereClause);
	    	
		for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) Database.query(soql.getQuery())){
			if(sol.Quantity_Ordered__c > KSE.addQuantityToField(sol.Quantity_Planned__c, sol.Quantity_Shipped__c)){
				Shipment__c solKey = new Shipment__c(
										Ship_From_Location__r = sol.Ship_From_Location__r, 
							   			Customer__r = sol.Sales_Order__r.Ship_To__r
							   		 );
										
				if(fulfillmentLinesMap.containsKey(solKey) == false){
					fulfillmentLinesMap.put(solKey, new List<Sales_Order_Line__c>());
				}
				
				fulfillmentLinesMap.get(solKey).add(sol);
				
				shipFromLocationIds.add(sol.Ship_From_Location__c);
				shipToIds.add(sol.Sales_Order__r.Ship_To__c);
			}
		}					 
		
		String shipmentWhereClause = '';
		shipmentWhereClause += ' Status__c NOT IN (\'Confirmed\', \'Delivered\') ';
		shipmentWhereClause += ' AND Ship_From_Location__c IN :shipFromLocationIds ';
		shipmentWhereClause += ' AND Customer__c IN :shipToIds ';
							 
		/*String shipmentQuery = shUtil.generateQueryFromFieldSet(
									  'Shipment__c', 
									  new Set<String>{'Sales_Order_Plan_Detail'}, 
									  new Set<String>{'Id', 'Name', 'Ship_From_Location__c', 'Customer__c', 
									  				  'Ship_From_Location__r.Name', 'Customer__r.Name'}, 
									  shipmentWhereClause
							   );*/
		
		soql = new SOQLUtil('Shipment__c');
	    soql.addFields('Sales_Order_Plan_Detail');
	    soql.addFields(new Set<String>{'Id', 'Name', 'Ship_From_Location__c', 'Customer__c', 
									  				  'Ship_From_Location__r.Name', 'Customer__r.Name'});
	    soql.setWhereClause(shipmentWhereClause);
	    
		List<Shipment__c> availableShipments = (List<Shipment__c>) Database.query(soql.getQuery());
		
		for(Shipment__c shipment : availableShipments){
			Shipment__c shipmentKey = new Shipment__c(
											Ship_From_Location__r = shipment.Ship_From_Location__r, 
							   				Customer__r = shipment.Customer__r
							   		  );
										
			if(shipmentsMap.containsKey(shipmentKey) == false){
				shipmentsMap.put(shipmentKey, new List<Shipment__c>());
			}
			
			shipmentsMap.get(shipmentKey).add(shipment);
		} 
		
		for(Shipment__c planningKey : fulfillmentLinesMap.keySet()){
			
			PlanWrapper planningWrapper = new PlanWrapper();
			planningWrapper.selectedPlan = planningKey;
			planningWrapper.availablePlans = shipmentsMap.get(planningKey);
			planningWrapper.linesToPlan = fulfillmentLinesMap.get(planningKey);
			
			// Add available shipments with zero lines.
		    solWrapperList.add(planningWrapper);
		}
		
		JsonResult result = new JsonResult();
		result.records = solWrapperList;
        result.total = solWrapperList.size();
        
        if(solWrapperList.isEmpty()){
        	result.addMessage('No open sales order lines found for planning.', ApexPages.Severity.INFO);
        }
        
        return result;   
	}
	
	@RemoteAction
	public static JsonResult plan(List<PlanWrapper> planWrapperList){
		
		JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        
        try{
        	
        	//List<PlanWrapper> planWrapperList = (List<PlanWrapper>) JSON.deserialize(planWrappersString, List<PlanWrapper>.class);
        
        
		    List<ShipmentService.FulfillmentLineWrapper> fulfillmentLines = new List<ShipmentService.FulfillmentLineWrapper>();
			
			for(PlanWrapper planningWrapper : planWrapperList){
				for(Sales_Order_Line__c soLine : planningWrapper.linesToPlan){
					ShipmentService.FulfillmentLineWrapper fulfillmentLine = new ShipmentService.FulfillmentLineWrapper();
					fulfillmentLine.salesOrderLineId = soLine.Id;
					
					if(String.isBlank(planningWrapper.selectedPlan.Id)){
						fulfillmentLine.estimatedShipmentDate = planningWrapper.selectedPlan.Shipment_Date_Estimated__c;
					}else{
						fulfillmentLine.shipmentId = planningWrapper.selectedPlan.Id;
					}
					
					fulfillmentLines.add(fulfillmentLine);
				}
			}
			
			// Create a plan for the sales order lines.
			ShipmentService.plan(fulfillmentLines);
			
			result.success  = true; //(ExceptionService.hasErrors == true ? false : true);
	        
	        if(result.success){
	        	result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
	        }else{
	        	result.messages.addAll(ExceptionService.messages);
	        }
	        
        }catch ( DML.InsuffientAccessException e ) { 
 			Database.rollback(sp);
            result.success = false;
 			result.addMessage(Label.Insufficient_access_contact_administrator_for_permissions, ApexPages.Severity.ERROR); 
 			
 		}catch (Exception e) {
        	Database.rollback(sp);
            result.success = false;
            string errorMsg = e.getMessage();
            
            if(errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                List<String> tempErr = errorMsg.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                errorMsg = tempErr[1].split(':')[0];
            }
            
            result.addMessage(errorMsg, ApexPages.Severity.ERROR);
        }

        return result;
	}
}