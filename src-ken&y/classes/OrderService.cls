public with sharing class OrderService {
    public static final String O_STATUS_DRAFT = 'Draft';
    public static final String O_STATUS_OPEN = 'Open';
    public static final String O_STATUS_CLOSED = 'Closed';
    public static final String O_STATUS_CANCEL = 'Cancelled';
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    public static set<Id> orderIds{
        get {
            if (orderIds == null) {
               	orderIds = new set<Id>();
            }
            return orderIds;
        }
        set;
    }
    
    public static set<Id> orderIdsDraft{
        get {
            if (orderIdsDraft == null) {
               	orderIdsDraft = new set<Id>();
            }
            return orderIdsDraft;
        }
        set;
    }
    
    public class OrderWrapper{
        
        public SObject order { get; set;}
        public list<SKID__c> skidList { get; set; }
        public list<Inventory_Transaction__c> itList { get; set;}
        public list<SObject> additionalInfo { get; set;} // used for storing things like demand skids , inventory transactions as js remoting does not support nested query results
        
        
        public OrderWrapper( SObject orderObj , List<SKID__c> skids, List<SObject> additionalList, List<Inventory_Transaction__c> inventoryTransactions ){
            
            order = orderObj;
            skidList = skids;
            additionalInfo = additionalList;
            itList = inventoryTransactions;
        }
      
    }
    
    public static list<OrderWrapper> populateOrderWrapper( list<SObject> sObjectList, map<Id, list<SKID__c>> skidsMap, map<Id, list<SObject>> additionalInfoMap, map<Id, list<Inventory_Transaction__c>> itMap  ){
        
        list<OrderWrapper> orderWrapperList = new list<OrderWrapper>();
        
        try
        {
        for( SObject sobj : sObjectList ){
        	
        	list<Skid__c> skidList;
        	list<SObject> additionalList;
        	list<Inventory_Transaction__c> itList;
            
            if( skidsMap != null )
                skidList = skidsMap.get(sobj.id);
                
            if( additionalInfoMap != null && additionalInfoMap.containsKey(sobj.id)  ){
                additionalList = additionalInfoMap.get(sobj.id);
            }    
            
            if( itMap != null && itMap.containsKey(sobj.id) ){
                itList = itMap.get(sobj.id);
            }
            
            OrderWrapper ow = new OrderWrapper( sobj, skidList, additionalList, itList );
            orderWrapperList.add( ow );
          
        }
        }
        catch(exception ex)
        {
        	setExceptionServiceMessage(ex);
	    	return new list<orderwrapper>();
        }
        return orderWrapperList;
    }
    
    public static String getConfigJson(GridRelatedListController.GridRelatedListConfig config) {
		if (String.isNotBlank(config.namespace)) {
		util.namespace = config.namespace;
        }
        
        String configStr = JSON.serialize(config);
          
        return configStr;
    }
       
    public static void release(Map<Id, Id> orderToShipment) {
        if (orderToShipment == null || orderToShipment.size() == 0) return;

        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Order_Line__c');

        Set<Id> orderIdSet = orderToShipment.keySet();
        SOQLUtil olQuery = new SOQLUtil('Order_Line__c');
        olQuery.addFields(new Set<String>{ 'Id', 'Name', 'Deliver_To_Facility__c', 'Deliver_To_Location__c', 'Description__c', 'Order__c', 'Quantity_Ordered__c',
            'Quantity_Allocated__c', 'Quantity_Received__c', 'Quantity_Shipped__c', 'Receiving_Company__c', 'Receiving_Item__c', 'Required_Date__c', 'Ship_From_Facility__c',

            'Ship_From_Location__c', 'Shipping_Company__c', 'Shipping_Item__c','Status__c','Quantity_Allocated__c', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Facility_Identifier__c',
            'Ship_From_Facility__r.Shipping_Calendar__c',

            'Order__r.Currency__c', 'Order__r.Need_Date__c', 'Order__r.Status__c',

            'Receiving_Item__r.Non_Inventory__c', 'Receiving_Item__r.Stocking_UOM__c', 'Receiving_Item__r.Packaging_UOM__c',

            'Shipping_Item__r.Non_Inventory__c', 'Shipping_Item__r.Stocking_UOM__c', 'Shipping_Item__r.Packaging_UOM__c', 'Shipping_Item__r.Lead_Time__c', 'Packaging_UOM__r.Package_Class__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c' // 5
        });
        olQuery.setWhereClause('Order__c IN :orderIdSet AND Status__c NOT IN (\'' + O_STATUS_CLOSED + '\', \'' + O_STATUS_CANCEL + '\')');
        List<Order_Line__c> orderLines = Database.query(olQuery.getQuery());

        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        for ( Order_Line__c orderLine : orderLines ) {
            itemIds.add(orderLine.Shipping_Item__c);
            facilityIds.add(orderLine.Ship_From_Facility__c);
        }

        SOQLUtil util = new SOQLUtil('Facility_Item__c');
        util.addFields(new Set<String>{
           'Id', 'Lead_Time__c', 'Item__c', 'Facility__c'
        });
        // filter by facility

        util.setWhereClause('Item__c in :itemIds AND Facility__c in :facilityIds');
        Map<Id, Map<Id, Decimal>> facilityItemLeadTimes = new Map<Id, Map<Id, Decimal>>();

        for ( Facility_Item__c fi : Database.query(util.getQuery()) ) {
            if ( !facilityItemLeadTimes.containsKey(fi.Item__c) ) {
                facilityItemLeadTimes.put(fi.Item__c, new Map<Id, Decimal>());
            }
            facilityItemLeadTimes.get(fi.Item__c).put(fi.Facility__c, fi.Lead_time__c);
        }

        Set<Id> shipmentIds = new Set<Id>(orderToShipment.values());
        shipmentIds.remove(null);
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>();
        if (shipmentIds.size() > 0) {
            Set<Id> olIds = (new Map<Id, Order_Line__c>(orderLines)).keySet();
            SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
            shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Order_Line__c', 'Quantity_Planned__c' });
            shlQuery.setWhereClause('Shipment__c IN :shipmentIds AND Order_Line__c IN :olIds AND Shipment__r.Status__c NOT IN (\'' + ShipmentService.SHIPMENT_STATUS_CONFIRMED + '\', \'' + ShipmentService.SHIPMENT_STATUS_DELIVERED + '\')');
            for (Shipment_Line__c shl:Database.query(shlQuery.getQuery())) shipmentLines.put(shl.Order_Line__c, shl);
        }

        Map<Id, Shipment__c> shipmentsToInsert = new Map<Id, Shipment__c>();
        Map<Id, Order__c> ordersToUpdate = new Map<Id, Order__c>();
        List<Order_Line__c> orderLinesToUpdate = new List<Order_Line__c>();
        List<SKID__c> demandSkids = new List<SKID__c>();
        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        for (Order_Line__c ol:orderLines) {
            if(ol.Required_Date__c == null){
              throw new CustomException('Enter required date.');  
            }
            Id facilityCal = ol.Ship_From_Facility__r.Shipping_Calendar__c;
            Shipment_Line__c shl = shipmentLines.containsKey(ol.Id) ? shipmentLines.get(ol.Id) : new Shipment_Line__c(Quantity_Planned__c = 0);
            Decimal qtyForRelease = (ol.Quantity_Ordered__c - ol.Quantity_Shipped__c);
            if (qtyForRelease == shl.Quantity_Planned__c) {
                shipmentLines.remove(ol.Id);
                continue;
            }

            shl.Company__c = ol.Shipping_Company__c;
            shl.Description__c = ol.Description__c;
            shl.Quantity_Planned__c = qtyForRelease;
            shl.Quantity_Shipped__c = 0;
            shl.Quantity_From_Stock__c = 0;
            shl.Extended_Cost__c = 0;
            shl.Facility__c = ol.Ship_From_Facility__c;
            shl.Location__c = ol.Ship_From_Location__c;
            shl.Item__c = ol.Shipping_Item__c;
            shl.Item__r = ol.Shipping_Item__r;
            shl.Order__c = ol.Order__c;
            shl.Order_Line__c = ol.Id;
            shl.Need_Date__c = ol.Required_Date__c;

            Decimal itemLeadTime = ol.Shipping_Item__r.Lead_Time__c;
            Decimal facilityItemLeadTime = facilityItemLeadTimes.containsKey(shl.Item__c) && facilityItemLeadTimes.get(shl.Item__c).containsKey(shl.Facility__c) ? facilityItemLeadTimes.get(shl.Item__c).get(shl.Facility__c) : null;
            Integer prepTime = facilityItemLeadTime != null ? (Integer)facilityItemLeadTime : (Integer)itemLeadTime;
            shl.Estimated_ship_date__c  = KSE.calculateEndDate(system.today(), prepTime, facilityCal);

            if (orderToShipment.get(ol.Order__c) != null) {
                shl.Shipment__c = orderToShipment.get(ol.Order__c);
            } else {
                if (!shipmentsToInsert.containsKey(ol.Order__c)) {
                    shipmentsToInsert.put(ol.Order__c, new Shipment__c(
                        Company__c = ol.Shipping_Company__c,
                        Currency__c = ol.Order__r.Currency__c,
                        Planned_Delivery_Date__c = ol.Order__r.Need_Date__c,
                        Ship_From_Facility__c = ol.Ship_From_Facility__c,
                        Ship_From_Location__c = ol.Ship_From_Location__c,
                        Status__c = ShipmentService.SHIPMENT_STATUS_PLANNED,
                        Type__c = ShipmentService.SHIPMENT_TYPE_TRANSFER_ORDER
                    ));
                }
            }

            shipmentLines.put(ol.Id, shl);

            if (ol.Order__r.Status__c == O_STATUS_DRAFT && !ordersToUpdate.containsKey(ol.Order__c)) ordersToUpdate.put(ol.Order__c, new Order__c(Id = ol.Order__c, Status__c = O_STATUS_OPEN));
            if (ol.Status__c == O_STATUS_DRAFT) orderLinesToUpdate.add(new Order_Line__c(Id = ol.Id, Status__c = O_STATUS_OPEN));
			
            if (ol.Shipping_Item__r.Non_Inventory__c == false) {
                SKID__c demandSkid = new SKID__c(
                    Company__c = ol.Shipping_Company__c,
                    Type__c = SkidService3.SKID_TYPE_TO_DEMAND,
                    Quantity__c = KSE.subtractDecimals(qtyForRelease, ol.Quantity_Allocated__c),
                    Packaging_UOM__c = ol.Shipping_Item__r.Stocking_UOM__c,
                    Stocking_UOM__c = ol.Shipping_Item__r.Stocking_UOM__c,
                    Item__c = ol.Shipping_Item__c,
                    Item__r = ol.Shipping_Item__r,
                    Container_Item__c = ol.Shipping_Item__c,
                    Facility2__c = ol.Ship_From_Facility__c,
                    Facility2__r = ol.Ship_From_Facility__r,
                    Location__c = ol.Ship_From_Location__c,
                    Order_Line__c = ol.Id,
                    Order_Date__c = ol.Required_Date__c
                );
                if (shl.Id != null) {
                    demandSkid.Shipment_Line__c = shl.Id;
                    skidsToPutaway.add(new SkidService3.SerialWrapper(demandSkid, new List<Serial__c>()));
                } else {
                    demandSkids.add(demandSkid);
                }
            }

            if (ol.Receiving_Item__r.Non_Inventory__c == false) {
                skidsToPutaway.add(new SkidService3.SerialWrapper(new SKID__c(
                    Company__c = ol.Receiving_Company__c,
                    Type__c = SkidService3.SKID_TYPE_TO_SUPPLY,
                    Quantity__c = qtyForRelease,
                    Packaging_UOM__c = ol.Receiving_Item__r.Stocking_UOM__c, //
                    Stocking_UOM__c = ol.Receiving_Item__r.Stocking_UOM__c,
                    Item__c = ol.Receiving_Item__c,
                    Item__r = ol.Shipping_Item__r,
                    Container_Item__c = ol.Receiving_Item__c,
                    Facility2__c = ol.Deliver_To_Facility__c,
                    Facility2__r = ol.Deliver_To_Facility__r,
                    Location__c = ol.Deliver_To_Location__c,
                    Order_Line__c = ol.Id,
                    Order_Date__c = ol.Required_Date__c
                ), new List<Serial__c>()));
            }
        }

        if (shipmentsToInsert.size() > 0) DML.insertAsUser(shipmentsToInsert.values());

        if (shipmentLines.size() > 0) {
            for (Shipment_Line__c shl:shipmentLines.values()) {
                if (shl.Shipment__c == null) shl.Shipment__c = shipmentsToInsert.get(shl.Order__c).Id;
            }
            DML.checkUpsertAsUser(shipmentLines.values()); upsert shipmentLines.values();
        }

        if (ordersToUpdate.size() > 0) DML.updateAsUser(ordersToUpdate.values());
        if (orderLinesToUpdate.size() > 0) DML.updateAsUser(orderLinesToUpdate);

        for (SKID__c demandSkid:demandSkids) {
            demandSkid.Shipment_Line__c = shipmentLines.get(demandSkid.Order_Line__c).Id;
            skidsToPutaway.add(new SkidService3.SerialWrapper(demandSkid, new List<Serial__c>()));
        }

        if (skidsToPutaway.size() > 0) SkidService3.putAwayService(skidsToPutaway, attributes, new Map<String, Boolean>{ SkidService3.UPDATE_SKID_QUANTITY => true, SkidService3.DELETE_SKIDS => true });
    }
    
    
    /************************************************************************************************************************************************************
    *   @Method Name  : UndoRelease
    *
    *   @Created Date : 10/10/2014
    *
    *   @Description  : This method is used to bring back the Transfer order back to the Draft stage. This method is invoked
    *                   from the OrderLinesAddManageExt class. This method will delete the TO demand skids 
    *                   associated with the TO lines and delete the Shipment Lines and Shipment header associated with the TO Lines.
    *                   It also changes the status of the TO Lines and the TO Header back to Draft
    *
    *   @Parameters : 
    *					1. List<OrderService.OrderWrapper> orderWrapperList : List of Transfer Orders
    *
    ****************************************************************************************************************************************************************/   
    public static void undoRelease( list<orderWrapper> orderWrapperList ){
        
        List<SObject> ols = new List<SObject>();
		map<id,SObject> orders = new map<id,SObject>();
		List<Sobject> shipLines = new list<SObject>();
        map<id,SObject> orderLinesMap =new map<Id,SObject>();
        map<Id, Shipment__c> shipmentMap = new map<Id, Shipment__c>();
		boolean resetOrderStatus=true;
		id orderId;
        Savepoint sp = Database.setSavepoint();
	    
        try {
        	for( orderWrapper ow : orderWrapperList ){
                
                if( ow.order.getSObject('Order__r').get('Status__c') == O_STATUS_CLOSED ){
                    ExceptionService.addMessage( MessageUtil.Severity.FATAL.name(), 'Order is not Open!', 'Order is not Open!');
	    			return;
                }
                orderId = (Id)ow.order.getSObject('Order__r').get('Id');
                //TODO RESET ORDERSTATUS FOR MULTIPLE ORDERS.
                
                if((decimal)ow.order.get('Quantity_BackOrdered__c')>0)
                {
                	resetOrderStatus = false;
                }
                else{
                	orderLinesMap.put(ow.Order.Id,ow.Order);
                }
            }
            
            if((orderLinesMap.size()==0))
            {
            	ExceptionService.addMessage( MessageUtil.Severity.ERROR.name(),  'Transfer Order has no lines to be Undo Release','Transfer Order has no lines to be Undo Release');
                return;
            }
            else
            {
            	if(resetOrderStatus==true)
                {
                   
                    /*
                    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                    */
                    SOQLUtil soql = new SOQLUtil('Order_Line__c', true); //enforceFLS=true, running in user mode
                    soql.addFields(new set<string>{
                        'id'
                    });
                    soql.setWhereClause('Order__r.Id = : orderId');
                    Map<id,Order_Line__c> olAllocatedMap=new Map<id,Order_Line__c>((list<Order_Line__c>)Database.query(soql.getQuery()));

                    if(olAllocatedMap.size()>0)
                    {
                        if(orderLinesMap.values().size()!=olAllocatedMap.size())
                            resetOrderStatus = false;
                    }
                }
				for(Order_Line__c ol : (List<Order_Line__c>)orderLinesMap.values())
				{
					
					ol.status__c = O_STATUS_DRAFT;
					ols.add(ol);
					
					if(resetOrderStatus==true){
					 	ol.Order__r.Status__c=O_STATUS_DRAFT;
					 	if(!orders.containsKey(ol.Order__r.Id))
							orders.put(ol.Order__r.Id,ol.Order__r);
					}
						
					
				}
				
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Shipment_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','name','shipment__c'
            });
            soql.setWhereClause('Order_Line__c IN :ols AND Shipment__r.Status__c != \'Confirmed\' AND Shipment__r.Status__c != \'Delivered\'');
            shipLines = Database.query(soql.getQuery());
                
				if(shipLines.size() > 0){
                  

                    /*
                    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                    */
                    soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
                    soql.addFields(new set<string>{
                        'Id'
                    });
                    string skidTypeDemand = SKIDService2.SKID_TYPE_TO_DEMAND;
                    string skidTypeSupply = SKIDService2.SKID_TYPE_TO_SUPPLY;
                    soql.setWhereClause('Order_Line__c IN :ols AND (Type__c = :skidTypeDemand or Type__c = :skidTypeSupply)');
                    List<SKID__c> demandSkids = Database.query(soql.getQuery());



    
                    if(demandSkids.size() > 0){
                        DML.deleteAsSystem(demandSkids);
                    }
                }  
				if(shipLines.size() > 0)
				{
					DML.deleteAsUser(shipLines);
				}
				
				if(ols.size() > 0)
				{
					DML.updateAsUser(ols);
				}
					
				if(orders.size() > 0)
				{
					DML.updateAsUser(orders.values());
				}
        	}
        	
        }
        catch (Exception e) {
        	
            Database.rollback(sp);
	    	setExceptionServiceMessage(e);
    	    return;
        }
    }
    
    public static set<String> getattributesWithName( String objectName ){
        
        Map<String, sObjectField> itFieldMap = util.getFieldsMap( objectName );
        String namespaceUU = String.isNotBlank(util.namespace)  ? util.namespace+'__' : '' ;
        set<String> fieldList = new set<String>();
        for( String attr : SkidService2.attributesForPutaway( new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'))) ){
            
            Schema.DescribeFieldResult dfr;
            
            if (objectName == 'Inventory_Transaction__c' && attr == 'Facility2__c') {
                dfr = itFieldMap.get('To_Facility__c').getDescribe();
            } else if (objectName == 'Inventory_Transaction__c' && attr == 'Location__c') {
                dfr = itFieldMap.get('To_Location__c').getDescribe();
            } else {
                dfr = itFieldMap.get(attr).getDescribe();
            }  
			    
			if ( dfr.getType() == Schema.DisplayType.REFERENCE ) 
			{
				String refName = dfr.getName().replace('__c','__r.Name');
				fieldList.add(  refName.replace( namespaceUU, '').toLowerCase() ); 
	       	}  
	    
        }
        return fieldList;
    }

    public static void setExceptionServiceMessage(Exception e)
    {
    	string errorSeverity='';
    	if(string.valueof(e.getTypeName()).contains('SkidService2Exception'))
        {
        	errorSeverity = MessageUtil.Severity.ERROR.name();
        }
        else
        {
        	errorSeverity = MessageUtil.Severity.FATAL.name();
        }
        ExceptionService.addMessage( errorSeverity, e.getMessage(), e.getMessage());
    }
    
    private static Set<String> requiredFields = new Set<String>{ 'Shipping_Item__c', 'Receiving_Item__c', 'Quantity_Ordered__c', 'Ship_From_Facility__c', 'Ship_From_Location__c', 'Deliver_To_Facility__c', 'Deliver_To_Location__c' };
    public static void checkRequiredFields(List<SObject> records, String objectName, String fieldSetName) {
        try {
            Map<String, sObjectField> fieldMap = util.addNoNSfieldsToMap(util.getGlobalDescribe(objectName).getDescribe().fields.getMap());  
            
            for (sObject record:records) {
                for (String requiredFieldName:requiredFields) {
                    Schema.DescribeFieldResult fieldResult = fieldMap.get(requiredFieldName).getDescribe();
                    if( ! String.isNotBlank( String.valueOf( record.get(requiredFieldName) ))  ){ 
                    	if(record.get('Name')==null)
                    	{   
                    		ExceptionService.addMessage( MessageUtil.Severity.ERROR.name(),  fieldResult.getLabel() + ' is required',fieldResult.getLabel() + ' is required');
                    	    return;
                        	
                    	}else
                        {	
                        	ExceptionService.addMessage( MessageUtil.Severity.ERROR.name(),  fieldResult.getLabel() + ' is required for ' + record.get('Name'),fieldResult.getLabel() + ' is required for ' + record.get('Name'));
                        	return;
                       
                        }
                    }
                    else
                    {
                    	if(((fieldResult.gettype()==schema.displaytype.double) ||(fieldResult.gettype()==schema.displaytype.integer)) )
                    	{
                			if((double)record.get(requiredFieldName)<0)
                			{	
                				ExceptionService.addMessage( MessageUtil.Severity.ERROR.name(),  fieldResult.getLabel() + ' cannot be less than 0',fieldResult.getLabel() + ' cannot be less than 0');
                    	        return;
                				
                			}
                    	}
                	}
            	}
        	}
        }
        catch( Exception ex ){
            
            setExceptionServiceMessage(ex);
            
            return;
        }
    }
    
    
    
    public static void ClearExceptions( List<sObject> orderLineList){
        
       ClearAllOrderLinesExceptions(orderLineList);
        
    }
    public static void ClearAllOrderLinesExceptions( List<sObject> orderLineList){
        
       
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('task', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id'
        });
        soql.setWhereClause('whatid in: orderLineList');
        Map<id,task> activities=new Map<id,task>((list<task>)Database.query(soql.getQuery()));

        List<Task> tasks=new list<Task>();
        for(task t: activities.values())
        {
            t.status='Closed';
            tasks.Add(t);
        }
        
        DML.updateAsUser(tasks);
        
    }
    
    
    
    
    public static void orderLineTriggerBeforeActions(){
        
        if(!trigger.isdelete){   
        for( Order_Line__c ol : (List<Order_Line__c>) trigger.new ){
            
            if( KSE.addQuantityToField(ol.Quantity_Allocated__c,ol.Quantity_Shipped__c) > 0 ){
                
                ol.Quantity_BackOrdered__c = KSE.subtractDecimals(ol.Quantity_Ordered__c, KSE.addQuantityToField(ol.Quantity_Allocated__c,ol.Quantity_Shipped__c));
            }
	        else
	        {
	        	ol.Quantity_BackOrdered__c = 0;
	        }
            
            if( (ol.Quantity_received__c >= ol.Quantity_Ordered__c) && ol.Has_Exceptions__c==false ){
                
                ol.Status__c = 'Closed';
            }
            
            if( ol.Status__c  == 'Closed' ){
                
                OrderService.orderIds.add( ol.Order__c );
            }
	            
	            
	        }
        }
        else
        {
        	for( Order_Line__c olDeleted : (List<Order_Line__c>) trigger.old ){
        		OrderService.orderIdsDraft.add(olDeleted.Order__c);
        	}
        }

        if(Trigger.isUpdate){
            for(SObject olSobj: Trigger.new){
                Id newShippingItem= (Id) olSobj.get(Schema.Order_Line__c.Shipping_Item__c);
                Id oldShippingItem= (Id)  Trigger.oldMap.get(olSobj.Id).get(Schema.Order_Line__c.Shipping_Item__c);

                Id newSReceivingItem= (Id) olSobj.get(Schema.Order_Line__c.Receiving_Item__c);
                Id oldReceivingItem= (Id) Trigger.oldMap.get(olSobj.Id).get(Schema.Order_Line__c.Receiving_Item__c);

                if(!newShippingItem.equals(oldShippingItem) || !newSReceivingItem.equals(oldReceivingItem)){
                    List<AggregateResult> AggList = [select count(Id), Type__c from SKID__c  where (Shipment_Line__r.Order_Line__c = :(Id)olSobj.get('Id') or Order_Line__c = :(Id)olSobj.get('Id')) and  Type__c  In ('Planned Pick', 'Allocated', 'Location','In-Transit')
                                                     group by Type__c having COUNT(Id) >0];
                    if(AggList.size()>0){
                        olSobj.addError('Cannot Update Shipping Item or Receiving Item for In progress orders.');
                        break;

                    }
                }

            }
        }

    }
    
    
    public static void orderTriggerBeforeActions()
    {
    	if(trigger.isbefore && trigger.isDelete){

	            for(Order__c ord : (List<Order__c>)Trigger.old){
	            	if(ord.Status__c!='Draft')
	            		ord.addError(Label.Transfer_Order_Delete);
	            }
	    }
    	
    }
    
    public static void orderLineTriggerAfterActions(){
      Savepoint sp = Database.setSavepoint();
        
        try{   
        if(OrderService.orderIds.size() != 0){
    		List<Order__c> ordersToClose = new List<Order__c>();
    	

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            
            //V2
            SOQLUtil soql = new SOQLUtil('Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Status__c'
            });
            set<id> oIds = OrderService.orderIds;
            soql.setWhereClause('id IN:oIds  and Status__c = \'Open\'');
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Order_Lines__r');
            childRel.addFields(new set<string>{
                'Id','Status__c'
            });
            childRel.setWhereClause('Status__c = \'Open\' or Status__c = \'Draft\'');
            soql.addChildRelationship(childRel);
            for(Order__c order : Database.query(soql.getQuery())){

    			// If there are no open order lines, then close the order.	    										
    			if(order.Order_Lines__r == null || order.Order_Lines__r.size() == 0){
    				order.Status__c = 'Closed';
    				order.Finalized__c = true;
    				order.Date_Closed__c = system.today();
    				ordersToClose.add(order);
    			}
    		}
    		
    		if(ordersToClose.size() > 0){
    			DML.updateAsUser(ordersToClose);
    		}
    	}   
	    	if(trigger.isdelete){
	    		if(OrderService.orderIdsDraft.size() != 0){
		    		List<Order__c> ordersToDraft = new List<Order__c>();
		    		

                    /*
                    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                    */
                    Set<Id> oIds = OrderService.orderIdsDraft;
                    SOQLUtil soql = new SOQLUtil('Order__c', true); //enforceFLS=true, running in user mode
                    soql.addFields(new set<string>{
                        'Id','Status__c'
                    });
                    soql.setWhereClause('id IN :oIds');
                    SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Order_Lines__r');
                    childRel.addFields(new set<string>{
                        'Id','Status__c'
                    });
                    soql.addChildRelationship(childRel);
                    for(Order__c orderD : Database.query(soql.getQuery())){

		    			// If there are no  order lines, then draft the order.	    										
		    			if(orderD.Order_Lines__r == null || orderD.Order_Lines__r.size() == 0){
		    				orderD.Status__c = 'Draft';
		    				ordersToDraft.add(orderD);
		    			}
		    		}
		    		if(ordersToDraft.size() > 0){
		    			DML.updateAsUser(ordersToDraft);
		    		}
		    	} 
	    	}
	    	  
    }
        catch (Exception e)
	    {
	    	Database.rollback(sp);
	    	throw e;
	    	
		}
    		  
    }

    public static void cancelLines(Set<Id> lineIds) {
        if (lineIds == null || lineIds.size() == 0) return;

        SOQLUtil olQuery = new SOQLUtil('Order_Line__c');
        olQuery.addFields(new Set<String>{ 'Id', 'Name', 'Quantity_Allocated__c', 'Quantity_Received__c', 'Quantity_Shipped__c', 'Status__c' });
        olQuery.setWhereClause('Id IN :lineIds');

         List<Order_Line__c>  linesToCancel = new List<Order_Line__c>();
         for (Order_Line__c ol:Database.query(olQuery.getQuery())) {
            if (ol.Status__c != 'Draft' && ol.Status__c != 'Open') throw new CustomException('You can only cancel draft and open lines.');
            if (ol.Quantity_Allocated__c > 0 || ol.Quantity_Shipped__c > 0 || ol.Quantity_Received__c > 0) throw new CustomException('You can\'t cancel lines that have been allocated, shipped, or received.');
            linesToCancel.add(new Order_Line__c(Id = ol.Id, Status__c = OrderService.O_STATUS_CANCEL));
        }

        if (linesToCancel.size() == 0) return;
        DML.updateAsUser(linesToCancel);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addField('Id');
        skidQuery.setWhereClause('Order_Line__c IN :linesToCancel');
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        if (skids.size() > 0) DML.deleteAsSystem(skids);

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Shipment__c' });
        shlQuery.setWhereClause('Order_Line__c IN :linesToCancel');
        List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
        if (shipmentLines.size() == 0) return;

        Set<Id> shipmentIds = new Set<Id>();
        for (Shipment_Line__c shl:shipmentLines) shipmentIds.add(shl.Shipment__c);
        DML.deleteAsUser(shipmentLines);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        shipmentQuery.setWhereClause('Id IN :shipmentIds');

        SOQLUtil.ChildRelationship shlSubquery = new SOQLUtil.ChildRelationship(shipmentQuery, 'Shipment_Lines__r');
        shlSubquery.addField('Id');
        shipmentQuery.addChildRelationship(shlSubquery);

        List<Shipment__c> shipmentsToDelete = new List<Shipment__c>();
        for (Shipment__c shipment:Database.query(shipmentQuery.getQuery())) {
            if (shipment.Shipment_Lines__r.size() == 0) shipmentsToDelete.add(shipment);
        }
        if (shipmentsToDelete.size() > 0) DML.deleteAsUser(shipmentsToDelete);
    }
}