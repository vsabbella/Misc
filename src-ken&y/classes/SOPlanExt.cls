public with sharing class SOPlanExt {
        
    Id salesOrderId;
    public Boolean hasErrors {get;set;}

    public SOPlanExt(ApexPages.StandardController sc){
		this.salesOrderId = sc.getId();		
		
		if (this.salesOrderId == null) {
        	ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Parameter: Sales order \'Id\' cannot be null.'));
        	return;
        }		
	}
	
	public void initialize(){
		List<Sales_Order_Line__c> soLines = getSoLinesToRelease(this.salesOrderId);
		List<Sales_Order_Line__c> soLinesToRelease = new List<Sales_Order_Line__c>();
		for(Sales_Order_Line__c sol: soLines) {
			if(sol.Status__c.equals(SalesOrderLineService.SO_LINE_STATUS_DRAFT)){
				soLinesToRelease.add(sol);
			} else if(sol.Status__c.equals(SalesOrderLineService.SO_LINE_STATUS_OPEN) &&
					  (sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY) ||
					   sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER)) &&
					  sol.Quantity_Ordered__c != sol.Quantity_Planned__c + sol.Quantity_Fulfilled__c){
				
				if(sol.Item_Source__c != null && sol.Item_Source__c.equals(SalesOrderLineService.SO_LINE_TYPE_KIT)){
					continue;
				} else {
					soLinesToRelease.add(sol);
				}

			}else if(sol.Status__c.equals(SalesOrderLineService.SO_LINE_STATUS_OPEN)  && 
				     sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP) || sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK) ){
		          if(sol.Quantity_Ordered__c != sol.Quantity_Planned__c){
				      
				  	soLinesToRelease.add(sol);
				  }   	 
			}
		}
		if(soLinesToRelease.size() > 0){
			plan(salesOrderId);
		} else {
			this.hasErrors = true;
			ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'No pending Sales Order Lines to be released.'));
		}

	}

	/**
	 *	getSoLinesToRelease fetches Sales Order Lines to be released for a given sales order id
	 *	@param Id sales order Id
	 *	@return List<Sales_Order_Line__c> List of Sales order lines
	 *
	 */
	public List<Sales_Order_Line__c> getSoLinesToRelease(Id soId){

		SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c', true); 

		solQuery.addFields(new set<string>{
			'Id',
			'Status__c',
			'Type__c',
			'Product__c',
			'Selling_UOM__c',
			'Ship_From_Location__c',
			'Ship_From_Location__r.Name',
			'Fulfillment_Source__c',
			'Item_Source__c',
			'Quantity_Ordered__c', 
			'Quantity_Planned__c',
			'Quantity_Shipped__c', 
			'Quantity_Fulfilled__c', 
			'Quantity_Allocated__c',
			'Sales_Order__c',
			'Sales_Order__r.Type__c',
			'Sales_Order__r.Status__c'
		});
		solQuery.setWhereClause(' Sales_Order__c = :soId AND Status__c NOT in (\'' + SalesOrderLineService.SO_LINE_STATUS_CANCELLED + '\',\'' + SalesOrderLineService.SO_LINE_STATUS_CLOSED + '\') ' + 
								  'AND (Status__c IN (\'' + SalesOrderLineService.SO_LINE_STATUS_DRAFT + '\') ' +
								  	  ' OR (Status__c IN (\'' + SalesOrderLineService.SO_LINE_STATUS_OPEN + '\') ))');

		List<Sales_Order_line__c> soLines = Database.query(solQuery.getQuery());

		return soLines;
	}

	//Proxy method: To Be removed
	public void plan(){
		plan(this.salesOrderId);
	}

	public void plan(Id salesOrderId) {	
		try{
	        //Release sales order
	        SalesOrderReleaseService.release(salesOrderId);
	        
	        JSONResult jsonResult = new JSONResult();
	        jsonResult.success  = (ExceptionService.hasErrors == true ? false : true);
	        jsonResult.messages.addAll(ExceptionService.messages);
            
            hasErrors = ExceptionService.hasErrors;
            
            if(SalesOrderReleaseService.futureCall){
            	
            	ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, Label.SO_Future_release));
            } else {
            	
            	if(jsonResult.success){

		            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, Label.SO_released));
				} else{

					ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, 'Sales Order is not (or partially) released due to the following reasons:'));

					// KNDY-3760 : Show any warnings if present.
					if(jsonResult.messages != null && jsonResult.messages.size() > 0){
						for (Map<String, String> msg : jsonResult.messages) {
						    ApexPages.addMessage(MessageUtil.toApexPageMessage(msg));
						}
					}
				}
            }
		} catch(Exception e){
			hasErrors = true;
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            System.debug(LoggingLevel.ERROR, e.getStackTraceString() + ' ' + e.getMessage());
		}
	}
}