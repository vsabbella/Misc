public with sharing class OrderLinesAddManageExt extends BaseController {
    
    public class OrderLinesAddManageException extends Exception{}
    
    public static final String Order_Lines_FieldSet_Name = 'Order_Lines_Add_Manage';
    public static final String Order_Lines_Exceptions_FieldSet_Name = 'Order_Lines_Exceptions';
    public static final String Order_Lines_Closed_FieldSet_Name = 'Order_Lines_Closed';
    public static final String Order_Lines_All_FieldSet_Name = 'Order_Lines_All';
    
    public Order__c orderHeader{get;set;} { orderHeader = new Order__c(); }
    public static Integer orderLinesCount{get;set;} { orderLinesCount = 0; }
    public string NamespaceUU { get { return KSE.NamespaceUU; }} 
    
    public string fieldList{get;set;}
    public string closedFieldList{get;set;}
    public string exceptionsFieldList{get;set;}

    public string exceptionGridId { get; set;} { exceptionGridId  = 'exceptionsGrid';}
    public string closedGridId { get; set;} { closedGridId  = 'closedGrid';}
    
    public GridRelatedListController.GridRelatedListConfig config{ get; set;} {config = new GridRelatedListController.GridRelatedListConfig();}
    public String configJsonGrid1{get;set;}
    public GridRelatedListController.GridRelatedListConfig closedConfig{ get; set;} {closedConfig = new GridRelatedListController.GridRelatedListConfig();}
    public String configJsonClosedGrid{get;set;}
    public GridRelatedListController.GridRelatedListConfig exceptionsConfig{ get; set;} {exceptionsConfig = new GridRelatedListController.GridRelatedListConfig();}
    public String configJsonExceptionsGrid{get;set;}
    
    public List<FieldInfo> fieldInfoList;
    public list<String> tabs { get; set; } { tabs = new list<String> { Label.Manage, Label.Exceptions, Label.Closed_Cancelled }; }
    public static JsonResult errorResult {get;set;}
    public Id orderId;
    public Id selectedShipment {get;set;}
    public List<SelectOption> shipmentOptions {get;set;} { shipmentOptions = new List<SelectOption>();}
   	public Map<Id, Shipment__c> shipmentsMap = new Map<Id, Shipment__c>();
    public Boolean errorOnPageLoad {get;set;}{errorOnPageLoad = false;}
    
    
    public OrderLinesAddManageExt(Apexpages.StandardController sc){
        
        try{
            orderId = sc.getId();
            
            if (orderId == null) {
            	throw new OrderLinesAddManageException(Label.Bad_page_access_Try_accessing_via_the_order_tab);
            }
            
            set<String> fieldStrings = new set<string>{ 'ID','Ship_From_Location__r.Name','Ship_From_Facility__r.Name', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Name',
											'Deliver_To_Facility__r.Facility_Identifier__c', 'Deliver_To_Location__r.Name'};
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( null, 'Order__c'));
            
            SOQLUtil soql = new SOQLUtil('Order__c');
		    soql.addFields(fieldStrings);
		    soql.setWhereClause('Id =:OrderId limit 1');
		    
		    orderHeader =  Database.query(soql.getQuery()) ;
		    /*orderHeader =  Database.query( Schemautil.getInstance().generateQueryFromFieldSet( 'Order__c', new set<string>{}, 
                            fieldStrings,
                            'Id =:orderId limit 1' ) );*/   
            updateLineCount(orderId);   
            
            getOrderFieldInfos();
            
            initialize ();
        }
        catch(exception ex)
        {
        	ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        	errorOnPageLoad = true;
        }
        
    }
    
    public void initialize(){
        shipmentsMap.clear();
        shipmentOptions.clear();
		// OTC-18 : Check if there are existing shipments related to the sales order.
		

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Shipment_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Shipment__r.Name'
        });
        string shipConfirm = ShipmentService.SHIPMENT_STATUS_CONFIRMED;
        string shipDel = ShipmentService.SHIPMENT_STATUS_DELIVERED;
        soql.setWhereClause('Order_Line__r.Order__c = :orderId and Shipment__r.Status__c NOT IN (:shipConfirm, :shipDel)');
        for(Shipment_Line__c shipLine : Database.query(soql.getQuery())){



		  	shipmentsMap.put(shipLine.Shipment__c, shipLine.Shipment__r);
			
		}
		
		if(shipmentsMap.isEmpty() == false){
			
			for(Id shipmentId : shipmentsMap.keySet()){
				Shipment__c shipment = shipmentsMap.get(shipmentId);
				shipmentOptions.add(new SelectOption(shipment.Id, shipment.Name));
			}
			
			// Select the first shipment by default, since there will be onlyone shipment most of the time.
			selectedShipment = shipmentsMap.values()[0].Id;
			return;
		}
	}
	
    public void getOrderFieldInfos(){
        
        config.uniqueId = 'kendoOrderGridDiv';
        config.title = 'Order Lines';
        config.objectName = 'Order_Line__c';
        config.fieldset = Order_Lines_FieldSet_Name;
        config.buttons = 'create,save,cancel,delete,search,Release All Lines';
        config.readOnlyFields = 'Name,Quantity_Allocated__c,Status__c';    
        configJsonGrid1 = OrderService.getConfigJson(config);

        List<FieldInfo> addManageFields = FieldInfo.fetchJsonFieldInfos('Order_Line__c', new List<String>{ 'Name', 'Shipping_Item__c', 'Receiving_Item__c', 'Quantity_Ordered__c', 'Ship_From_Facility__c',
            'Ship_From_Location__c', 'Deliver_To_Facility__c', 'Deliver_To_Location__c', 'Status__c' });
        for (FieldInfo fi:addManageFields) {
            if (fi.field == 'Name' || fi.field == 'Status__c') fi.editable = false;
            else fi.required = true;
            fi.field = 'order.' + fi.field;
        }
        for (FieldInfo fi:FieldInfo.fetchJsonFieldInfos('Order_Line__c', 'Order_Lines_Add_Manage')) {
            fi.field = 'order.' + fi.field;
            addManageFields.add(fi);
        }
        fieldList = JSON.serialize(addManageFields);
        
        closedConfig.uniqueId = 'closedGrid';
        closedConfig.title = 'Order Lines';
        closedConfig.objectName = 'Order_Line__c';
        closedConfig.fieldset = Order_Lines_Closed_FieldSet_Name;
        closedConfig.buttons = 'search';
        closedConfig.readOnlyFields = '';    
        configJsonClosedGrid = OrderService.getConfigJson(closedConfig);
        closedFieldList = getFieldListJSON(closedConfig.objectName, closedConfig.fieldset, null, null, null, 'order.',null, false, null);
        
        exceptionsConfig.uniqueId = 'exceptionsGrid';
        exceptionsConfig.title = 'Order Lines';
        exceptionsConfig.objectName = 'Order_Line__c';
        exceptionsConfig.fieldset = Order_Lines_Exceptions_FieldSet_Name;
        exceptionsConfig.buttons = 'search';
        exceptionsConfig.readOnlyFields = '';    
        configJsonExceptionsGrid = OrderService.getConfigJson(exceptionsConfig);
        exceptionsFieldList = getFieldListJSON(exceptionsConfig.objectName, exceptionsConfig.fieldset, null, null, null, 'order.',null, false, null);
    }
    
    public static void updateLineCount( Id orderId ){
        
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name'
        });
        soql.setWhereClause('Order__c =:orderId');
        List<Order_Line__c> orderLineList = Database.query(soql.getQuery());



        orderLinesCount = orderLineList.size();
    }
    
    public static String getFieldListJSON( String objectName, String fieldSetName, List<String> fieldList, set<String> readOnlyFields, 
                                            set<String> editableFields, String prefix, String configReadOnlyFields, Boolean defaultReadOnly, list<FieldInfo> additionalFieldInfo ){
        
        String JSONString='';
        List<FieldInfo> fieldInfoList = new list<FieldInfo>();
        errorResult = new jsonResult();
        
        if( fieldList != null ){
            fieldInfoList.addAll( FieldInfo.fetchJsonFieldInfos(objectName, fieldList) );
        }
        if( fieldSetName != null ){
            fieldInfoList.addAll( FieldInfo.fetchJsonFieldInfos(objectName, fieldSetName, configReadOnlyFields) );
        }
      
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            
            fieldInfoList[i].required = false;
            
            if(configReadOnlyFields != null && (! configReadOnlyFields.contains(fieldInfoList[i].field)) )
                fieldInfoList[i].editable = defaultReadOnly;
            
            if( readOnlyFields != null && readOnlyFields.contains( (fieldInfoList[i].field).toLowerCase()) ){
                fieldInfoList[i].editable = false;
            }
            if( editableFields != null && editableFields.contains( (fieldInfoList[i].field).toLowerCase()) ){
                fieldInfoList[i].editable = true;
            }
            if( prefix != null )
                fieldInfoList[i].field = prefix+ fieldInfoList[i].field;
            
        } 
        if( additionalFieldInfo != null && additionalFieldInfo.size() > 0 ){
            fieldInfoList.addAll( additionalFieldInfo );
        }
        JSONString = JSON.serialize(fieldInfoList);
        
        return JSONString;
    }
    
    @RemoteAction
	public static JsonResult getLinesForAddManage(ID OrderId) {
		JsonResult result = new JsonResult();
		SchemaUtil util = SchemaUtil.getInstance();  
		try{
			SOQLUtil soql = new SOQLUtil('Order__c');
		    soql.addFields(new Set<String>{'Status__c'});
		    soql.setWhereClause('Id =:OrderId limit 1');
		    
		    Order__c orderH =  Database.query(soql.getQuery()) ;
			//Order__c orderH =  Database.query( 'select status__c from Order__c where Id =:OrderId limit 1' ) ;   
	        
	        set<String> fieldStrings = new set<string>{ 'ID','Name','Order__r.Shipping_Company__c','Order__r.Status__c','Ship_From_Location__r.Facility__c','Order__r.currency__c',
					'Ship_From_Location__r.Facility__r.Company__c', 'Shipping_Item__r.Non_Inventory__c', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Facility_Identifier__c'};
	        fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( null, 'Order_Line__c'));
        	
        	soql = new SOQLUtil('Order_Line__c');
		    soql.addFields(Order_Lines_FieldSet_Name);
		    soql.addFields(fieldStrings);
		    soql.setWhereClause('Order__c =:orderId  and (Status__c =\'Draft\' or Status__c =\'Open\') and Order__r.Status__c !=\'Closed\'');
		    
		    List<SObject> orderLineList =  Database.query(soql.getQuery());
		    /*List<SObject> orderLineList =  Database.query( util.generateQueryFromFieldSet( 'Order_Line__c', new set<string>{Order_Lines_FieldSet_Name}, 
	                        fieldStrings,
	                        'Order__c =:orderId  and (Status__c =\'Draft\' or Status__c =\'Open\') and Order__r.Status__c !=\'Closed\'' ) );*/                   

			result.records = OrderService.populateOrderWrapper( orderLineList, null, null, null );
			result.total = orderLineList.size();
			
			if(string.valueof(orderH.Status__c)=='Closed')
	        {
	        	ExceptionService.addmessage(ApexPages.Severity.FATAL.name(), Label.Order_is_Closed, Label.Order_is_Closed);
	        }
		           
	        if(string.valueof(orderH.Status__c)=='Cancelled')
	        {
	        	ExceptionService.addmessage(ApexPages.Severity.FATAL.name(), Label.Order_is_Cancelled, Label.Order_is_Cancelled);//PTM-391
	        }
	        }
		catch(exception ex)
        {
        	ExceptionService.addmessage(ApexPages.Severity.FATAL.name(),ex.getMessage(),ex.getMessage());
        }
        finally
        {
        	GetExceptions(result);
        }
				
        return result;
	}
	
	@RemoteAction
	public static JsonResult getClosedLines(ID OrderId) {
		JsonResult result = new JsonResult();
		SchemaUtil util = SchemaUtil.getInstance();  
		try{
	        set<String> fieldStrings = new set<string>{ 'ID','Name','Order__r.Shipping_Company__c','Order__r.Status__c','Ship_From_Location__r.Facility__c',
	        'Ship_From_Location__r.Facility__r.Company__c', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Facility_Identifier__c'};
	        fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( null, 'Order_Line__c'));
	        
	        SOQLUtil soql = new SOQLUtil('Order_Line__c');
		    soql.addFields(Order_Lines_Closed_FieldSet_Name);
		    soql.addFields(fieldStrings);
		    soql.setWhereClause('Order__c =:orderId and (Status__c = \'Closed\' or Status__c = \'Cancelled\')');
		    
		    List<SObject> orderLineList =  Database.query(soql.getQuery());
			/*List<SObject> orderLineList =  Database.query( util.generateQueryFromFieldSet( 'Order_Line__c', new set<string>{Order_Lines_Closed_FieldSet_Name}, 
	                        fieldStrings,
	                        'Order__c =:orderId and (Status__c = \'Closed\' or Status__c = \'Cancelled\')'));*/                   
	   
			result.records = OrderService.populateOrderWrapper( orderLineList, null, null, null );
	        result.total = orderLineList.size();
		}
		catch(exception ex)
        {
        	ExceptionService.addmessage(ApexPages.Severity.FATAL.name(),ex.getMessage(),ex.getMessage());
        }
        finally
        {
        	GetExceptions(result);
        }
        return result;
	}
	
	@RemoteAction
	public static JsonResult getExceptionLines(ID OrderId) {
		JsonResult result = new JsonResult();
		SchemaUtil util = SchemaUtil.getInstance();  
		try{
	        set<String> fieldStrings = new set<string>{ 'ID','Name','Order__r.Shipping_Company__c','Order__r.Status__c','Ship_From_Location__r.Facility__c',
	        'Ship_From_Location__r.Facility__r.Company__c', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Facility_Identifier__c'};
	        fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( null, 'Order_Line__c'));
	        
	        SOQLUtil soql = new SOQLUtil('Order_Line__c');
		    soql.addFields(Order_Lines_Exceptions_FieldSet_Name);
		    soql.addFields(fieldStrings);
		    soql.setWhereClause('Order__c =:orderId  and Has_Exceptions__c = true ');
		    
		    List<SObject> orderLineList =  Database.query(soql.getQuery());
	        /*List<SObject> orderLineList =  Database.query( util.generateQueryFromFieldSet( 'Order_Line__c', new set<string>{Order_Lines_Exceptions_FieldSet_Name}, 
	                        fieldStrings,
	                        'Order__c =:orderId  and Has_Exceptions__c = true ' ) );                   */
	           //and Has_Exceptions__c = false and Product__r.Item__r.Non_Inventory__c = false order by Line__c ASC
	   
			result.records = OrderService.populateOrderWrapper( orderLineList, null, null, null );
	        result.total = orderLineList.size();
		}
		catch(exception ex)
        {
        	ExceptionService.addmessage(ApexPages.Severity.FATAL.name(),ex.getMessage(),ex.getMessage());
        }
        finally
        {
        	GetExceptions(result);
        }
        return result;
	}
	
	private static boolean GetExceptions(JsonResult result)
	{
		
		  boolean hasError = ExceptionService.hasErrors;
		  result.hasExceptions = false;
		  if(ExceptionService.messages.size()>0)
		  {
			result.success = (!hasError);
        	result.reason = ExceptionService.ExceptionSeverity;
            result.hasExceptions = true;
            // Update Page messages for display on UI
			for (Map<String, String> msg : ExceptionService.messages) {
			    result.addMessage(msg.get('message'), GetMessageSeverity(msg.get('severity')));
			}	
    	  }
    	  return hasError;
	}
	
	
	private static ApexPages.Severity GetMessageSeverity(string msgSeverity)
	{
		Map<string, ApexPages.Severity> severity = new Map<string, ApexPages.Severity>{'INFO'  => ApexPages.Severity.INFO,'WARNING' => ApexPages.Severity.WARNING,'ERROR' => ApexPages.Severity.ERROR,'FATAL' => ApexPages.Severity.FATAL };
		
		return severity.get(msgSeverity.toUpperCase());
	}

	@RemoteAction
	public static boolean ShipmentExist(List<OrderService.OrderWrapper> orderlinesWrapper)
    {
        
        list<Order_Line__c> olList = new list<Order_Line__c>();
        for( OrderService.OrderWrapper ow : orderlinesWrapper ){
               
            olList.add( (Order_Line__c) ow.order );
        }
        
       

        /* 
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('shipment_line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','shipment__c','Quantity_Planned__c','shipment__r.Id'
        });
        string shipConfirm = ShipmentService.SHIPMENT_STATUS_CONFIRMED;
        string shipDelievered = ShipmentService.SHIPMENT_STATUS_DELIVERED;
        soql.setWhereClause('order_line__c in : olList and Shipment__r.Status__c NOT IN (:shipConfirm, :shipDelievered)');
        soql.setLimit(1);
        Map<Id,Shipment_Line__c> sl = new Map<Id,Shipment_Line__c>((list<Shipment_Line__c>)Database.query(soql.getQuery()));




        if(sl.size()>0)
            return true;
        
        return false;
    }
    
    public void release() { 
        Savepoint sp = Database.setSavepoint(); 
        try {
            shipmentOptions.clear();
            
            OrderService.release(new Map<Id,Id>{ orderId => selectedShipment });
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,Label.SO_released));
        } catch(Exception e){
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
    
    @RemoteAction
    public static JsonResult releaseList(Id orderId) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            OrderService.release(new Map<Id,Id>{ orderId => null });
        } catch(Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.FATAL);
        }
        
        return result;
    }
    
    /************************************************************************************************************************************************************
    *   @Method Name  : UndoRelease
    *
    *   @Created Date : 10/10/2014
    *
    *   @Description  : This method is used to bring back the Transfer order back to the Draft stage. This method is invoked
    *                   from the Allocate grid using the UndoRelease button. Invoking the button will delete the TO demand skids 
    *                   associated with the TO lines and delete the Shipment Lines and Shipment header associated with the TO Lines.
    *                   It also changes the status of the TO Lines and the TO Header back to Draft
    *
    *   @Parameters : 
    *					1. List<OrderService.OrderWrapper> updatedList : List of Transfer Orders
    *					2. List<String> dateFields                     : NULL value passed here to have the Undo Release as generalised per the page perspective
    *					3. List<String> detailDateFields               : NULL value passed here to have the Undo Release as generalised per the page perspective
    *
    ****************************************************************************************************************************************************************/
    @RemoteAction
    public static JsonResult UndoRelease(List<OrderService.OrderWrapper> updatedList, List<String> dateFields, List<String> detailDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            for (Integer i = 0; i < updatedList.size(); i++) {
                Order_Line__c ol = (Order_Line__c)updatedList[i].order;
                if (ol.Quantity_Allocated__c > 0 || ol.Quantity_Shipped__c > 0) updatedList.remove(i--);
            }

            if (updatedList.size() == 0) {
                result.success = false;
                result.addMessage('This order has no lines for undo release.', ApexPages.Severity.INFO);
                return result;
            }
            
            OrderService.undoRelease(updatedList);
        } catch (Exception e) {
            Database.rollback(sp);
            ExceptionService.addmessage(ApexPages.Severity.FATAL.name(),e.getMessage(),e.getMessage());
        }
        finally
        {
        	GetExceptions(result);
        }
        
    	
    	return result;
    }
    
    public static list<String> cleanWrapperDateFields( list<String> dateFields ){
        
        list<String> cleanDateFields = new list<String>();
        
        for( String dateField : dateFields ){
    	   
    	   if( dateField != null && dateField.length() > 0 ){ 
        	    List<String> splitResults = dateField.split('\\.');
        	    cleanDateFields.add(splitResults[splitResults.size()-1]);
    	   }
    	}
        	
        return cleanDateFields;
    }

    @RemoteAction
    public static JsonResult cancelLines(List<OrderService.OrderWrapper> lines, List<String> dateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> lineIds = new Set<Id>();
            for (OrderService.OrderWrapper ow:lines) lineIds.add(ow.order.Id);
            OrderService.cancelLines(lineIds);
        } catch (Exception e) {
            Database.rollback(sp);
            CustomException.addError(result, e);
        }
        return result;
    }
	
	@RemoteAction
    public static JsonResult saveList(Id orderId, List<OrderService.OrderWrapper> updatedList, List<OrderService.OrderWrapper> newList, List<OrderService.OrderWrapper> deletedList, List<String> dateFields) {
    	JsonResult result = new JsonResult();
    	list<SObject> updatedOrderLines = new list<SObject>();
    	list<SObject> newOrderLines = new list<SObject>();
    	list<SObject> deleteOrderLines = new list<SObject>();
    	list<String> cleanDateFields = new list<String>();
    	    
    	list<SObject> deleteShipmentLines = new list<SObject>();  
    	list<SObject> deleteShipments = new list<SObject>(); 
    	SchemaUtil util = SchemaUtil.getInstance();  
        Savepoint sp = Database.setSavepoint();
        Map<Id,sObject> olMap=new Map<Id,sObject>();
        boolean isError=false;
        boolean isErrorDelete=false;
        boolean isErrorFullyShipped=false;
        boolean isErrorEdit=false;
        string errorMessage=Label.Order_Line_Quantity_Required_Less_Than_Allocated_And_Shipped;
        string errorMessageEdit=Label.Open_Order_Lines_Cannot_Be_Edited;
        string errorMessageFullyShipped=Label.Fully_Shipped_Order_Lines_Cannot_Be_Edited;
    	string errorMessageDelete=Label.Open_Order_Lines_Cannot_Be_Deleted;
    	Schema.SObjectType objectType = util.getGlobalDescribe('Order_Line__c');
        
		//KNDY-7410
		//Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
		Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(objectType.getDescribe().fields.getMap());              
        
        List<Schema.FieldSetMember> fieldSetMemberList = util.getFieldsFromFieldSet(objectType, Order_Lines_FieldSet_Name);

    	try {
        	cleanDateFields = cleanWrapperDateFields( dateFields );
        	updatedOrderLines.clear();
        	
        	if(updatedList.size()>0)
        	{
        		for (OrderService.OrderWrapper oline : updatedList) {
	                KendoUtils.UpdateDateFields(oline.Order, dateFields);
	            }
	            
        	    set<String> fieldStrings = new set<string>{ 'ID','Name','Order__r.Shipping_Company__c','Order__r.Status__c','Ship_From_Location__r.Facility__c',
                                                            'Ship_From_Location__r.Facility__r.Company__c', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Facility_Identifier__c'};
                                                            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( null, 'Order_Line__c'));
        		
        		SOQLUtil soql = new SOQLUtil('Order_Line__c');
			    soql.addFields(Order_Lines_All_FieldSet_Name);
			    soql.addFields(fieldStrings);
			    soql.setWhereClause('Order__c =:orderId');
	    
	    		List<sObject> olines =  Database.query(soql.getQuery());
                /*List<sObject> olines =  Database.query( util.generateQueryFromFieldSet( 'Order_Line__c', new set<string>{Order_Lines_All_FieldSet_Name}, 
                        fieldStrings,
                        'Order__c =:orderId' ) );*/ 
        	    for(sObject ol:olines)
        	    {
        	        olMap.put(ol.id,ol);
        	    }

        	}
        	
        	for (OrderService.OrderWrapper row: updatedList) { 
        	    
        	    
        	    if(row.Order.get('Shipping_Item__c')<>row.Order.get('Receiving_Item__c'))
        	    {
        	        ExceptionService.addmessage(ApexPages.Severity.ERROR.name(),row.Order.get('Name') + ':  ' + Label.TO_Shipping_Receiving_Item_Mismatch , row.Order.get('Name') + ':  ' + Label.TO_Shipping_Receiving_Item_Mismatch );
        	    }
        	    decimal quantityAllocated=0;
    	        decimal quantityShipped=0;
    	        
    	        if(row.Order.get('Quantity_Allocated__c')!=null)
    	            quantityAllocated = (decimal)row.Order.get('Quantity_Allocated__c');
    	        if(row.Order.get('Quantity_Shipped__c')!=null)
    	            quantityShipped = (decimal)row.Order.get('Quantity_Shipped__c');
    	         
        	    if((decimal)row.Order.get('Quantity_Ordered__c') < (KSE.addQuantityToField(quantityAllocated ,quantityShipped)))
        	    {
        	        isError=true;  
            	    errorMessage +=  (string)row.Order.get('Name') + ',';
        	    }
        	    else if((decimal)olMap.get(row.Order.Id).get('Quantity_Ordered__c') == quantityShipped && quantityShipped >0)
        	    {
        	        isErrorFullyShipped=true;  
            	    errorMessageFullyShipped +=  (string)row.Order.get('Name') + ',';
        	    }
        	    else{
            	KendoUtils.UpdateDateFields(row.Order, cleanDateFields);
                	
                	sObject olsObject = olMap.get(row.Order.Id);
        	        if((string)row.Order.get('Status__c')=='Open')
        	        {
            	        for (Schema.FieldSetMember fsm : fieldSetMemberList) {
                        
                            string field = fsm.getFieldPath().replace(KSE.NamespaceUU, '');
                            if(field!='Quantity_Ordered__c')
                            {         
                                if(olsObject.get(field)!=row.Order.get(field))
                                {
                                    isErrorEdit=true;
                                    errorMessageEdit+=row.Order.get('Name') + ',';
                                    break;
                                }
                            }
                        }
        	        }
                	
                	
                	if(!isErrorEdit)
            	updatedOrderLines.add( row.Order );
    		}
    		
    		}
    		errorMessageEdit = errorMessageEdit.substring(0,errorMessageEdit.length()-1);
    		errorMessage = errorMessage.substring(0,errorMessage.length()-1);
    		errorMessageFullyShipped = errorMessageFullyShipped.substring(0,errorMessageFullyShipped.length()-1);
    		
    		newOrderLines.clear();
    		if(newList.size()>0)
    		{
    			for (OrderService.OrderWrapper oline : newList) {
	                KendoUtils.UpdateDateFields(oline.Order, dateFields);
	            }
	            
    		}

//			throw new OrderLinesAddManageException(JSON.serialize(newList));

    		for (OrderService.OrderWrapper row: newList) { 
    		    if(row.Order.get('Shipping_Item__c')<>row.Order.get('Receiving_Item__c'))
        	    {
        	        ExceptionService.addmessage(ApexPages.Severity.ERROR.name(), Label.TO_Shipping_Receiving_Item_Mismatch , Label.TO_Shipping_Receiving_Item_Mismatch );
        	    }
            	KendoUtils.UpdateDateFields(row.Order, cleanDateFields);
            	row.Order.put( 'Order__c', orderId );
            	row.Order.put( 'Status__c', Orderservice.O_STATUS_DRAFT );
            	newOrderLines.add( row.Order );
    		}
    		integer count=0;
    		deleteOrderLines.clear();
    		for (OrderService.OrderWrapper row: deletedList) { 
    		
    		    if(row.Order.get('Status__c')==Orderservice.O_STATUS_DRAFT)
            	deleteOrderLines.add( row.Order );
            	else{
            	      isErrorDelete=true;
            	      errorMessageDelete += (string)row.Order.get('Name') + ',';
            	}
    		}
    		
    		if(!string.isBlank(errorMessageDelete))
            	  errorMessageDelete = errorMessageDelete.substring(0,errorMessageDelete.length()-1);

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('shipment_line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','Shipment__r.Id'
            });
            soql.setWhereClause('order_line__c in :deleteOrderLines');
            deleteShipmentLines = Database.query(soql.getQuery());

    	    for(sObject shl: deleteShipmentLines)
    	    {
    	        deleteShipments.Add((sObject)shl.getSobject('Shipment__r'));
    		}
    		
    		OrderService.checkRequiredFields(updatedOrderLines, 'Order_Line__c', Order_Lines_FieldSet_Name );
    		OrderService.checkRequiredFields(newOrderLines, 'Order_Line__c', Order_Lines_FieldSet_Name );
    		
        	if(!ExceptionService.hasErrors)
			{
				
                if (updatedList.size() > 0) {
                    DML.updateAsUser(updatedOrderLines); 
                }
                
                if (newList.size() > 0) {
                    DML.insertAsUser(newOrderLines);
                }
                
                if (deleteShipments.size() > 0) {
                    DML.deleteAsUser(deleteShipments);
                }
                    
                if (deletedList.size() > 0) {
                    DML.deleteAsUser(deleteOrderLines);
                }
            
			}
			else{
			    result.success = false;
			}


        }
        catch (Exception ex)
        {
            Database.rollback(sp);
            ExceptionService.addmessage(ApexPages.Severity.FATAL.name(),ex.getMessage(),ex.getMessage());
        }
        finally
        {
            if(isError)
    		{
    		    result.Addmessage(errorMessage,ApexPages.Severity.ERROR);
    		}
    		if(isErrorEdit)
    		{
    		    result.Addmessage(errorMessageEdit,ApexPages.Severity.ERROR);
    		}
    		
    		if(isErrorFullyShipped)
    		{
    		    result.Addmessage(errorMessageFullyShipped,ApexPages.Severity.ERROR);
    		}  
    		if(isErrorDelete)
    		{
    		    result.Addmessage(errorMessageDelete,ApexPages.Severity.ERROR);
    		}  
    		    
        	GetExceptions(result);
        	updateLineCount( orderId );
        	result.total = orderLinesCount;
        }
        return result;
    }
}