public with sharing class ShipmentLineService implements ServiceRequestHandler {
	
	public static ExceptionService exService = new ExceptionService();
    private static final String SKID_TYPE_SO_DEMAND = SKIDService.SKID_TYPE_SO_DEMAND;
    
    public ServiceResponse serviceResponse = new ServiceResponse();
    
    public class ShipmentLineWrapper extends ServiceParam {
    	public String serialNumber;
		
		public override ServiceParam inflate(Object obj){
			
			map<String, Object> mObjs = (map<String, Object>)JSON.deserializeUntyped(string.valueOf(obj));
			
			ShipmentLineWrapper shlWrapper = new ShipmentLineWrapper();
			shlWrapper.serialNumber = (String) mObjs.get(KSE.NamespaceUU + 'Parameter_Value__c');
			shlWrapper.targetId = (String) mObjs.get(KSE.NamespaceUU + 'Target_Document_Id__c');
			shlWrapper.requestId = (String) mObjs.get('Id');
			return shlWrapper;
		}
    } 
    
    class ShipmentLineServiceException extends Exception{}
    
    public ServiceResponse handleRequest(ServiceRequest serviceRequest){
		
		//List<ShipmentLineWrapper> shlWrappers = (List<ShipmentLineWrapper>) ServiceUtil.getParameters(serviceRequest.params, 'ShipmentLineService.ShipmentLineWrapper');
		List<ShipmentLineWrapper> shlWrappers = new List<ShipmentLineWrapper>();
		for(String reqParams : (list<string>)serviceRequest.params){
			ShipmentLineWrapper slw = new ShipmentLineWrapper();
			shlWrappers.add((ShipmentLineWrapper)slw.inflate(reqParams));
		}
	    	
		Map<Id, List<ShipmentLineWrapper>> shlWrapperMap = new Map<Id, List<ShipmentLineWrapper>>(); 
		
		for(ShipmentLineWrapper shlWrapper : shlWrappers){
    		if(String.isBlank(shlWrapper.targetId)){
    			serviceResponse.addMessage(shlWrapper.requestId, new Message(Message.SEVERITY_ERROR, 'Target Id cannot be blank.', ''));
    			continue;
    		}
    		
			if(shlWrapperMap.containsKey(shlWrapper.targetId) == false){
				shlWrapperMap.put(shlWrapper.targetId, new List<ShipmentLineWrapper>());
			}
			
			shlWrapperMap.get(shlWrapper.targetId).add(shlWrapper);
    	}
    	
    	if(serviceRequest.actionName == 'Pick Shipment Line'){	
			manageSerials('Pick', shlWrapperMap);
    	}
    	else
    	if(serviceRequest.actionName == 'UndoPick Shipment Line'){	
    		manageSerials('Unpick', shlWrapperMap);
    	}
    	else{
    		serviceResponse.isSuccess = false;
	    	serviceResponse.addErrorMessage('Invalid service action.');
	    }
	    
    	return serviceResponse;
    }
    
    public void manageSerials(String action, Map<Id, List<ShipmentLineWrapper>> shlWrapperMap) {
        try {
            List<String> attributes = SkidService3.attributesForPutaway();
            Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Id' => '(\'' + String.join(new List<Id>(shlWrapperMap.keySet()), '\',\'') + '\')' }, 'pick'));
            Map<Id, List<LineWrapper>> wrapperMap = ShipmentWorkbenchExt.getInventory(shipmentLines.values(), 'pick');
            
            List<LineWrapper> wrappers = new List<LineWrapper>();
            for (Id shlId:shlWrapperMap.keySet()) {
                Shipment_Line__c shl = shipmentLines.get(shlId);
                Map<List<String>, SkidService3.SerialWrapper> swMap = new Map<List<String>, SkidService3.SerialWrapper>();

                for (ShipmentLineWrapper shlWrapper:shlWrapperMap.get(shlId)) {
                    Boolean serialFound = false;

                    for (LineWrapper wrapper:wrapperMap.get(shlId)) {
                        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                            for (Serial__c serial:sw.serialList) {
                                if (serial.Name == shlWrapper.SerialNumber) {
                                    if (action == 'Pick' && String.isBlank(serial.Temporary_Value_Holder__c)) serial.Temporary_Value_Holder__c = action;
                                    else if (action == 'Unpick' && serial.Temporary_Value_Holder__c == 'Picked') serial.Temporary_Value_Holder__c = action;

                                    if (serial.Temporary_Value_Holder__c == 'Pick' || serial.Temporary_Value_Holder__c == 'Unpick') {
                                        List<String> key = SkidService3.generateKey(sw.skid, attributes);
                                        if (swMap.containsKey(key)) {
                                            SkidService3.SerialWrapper existingSw = swMap.get(key);
                                            if (serial.Temporary_Value_Holder__c == 'Pick') {
                                                sw.skid.Input_Quantity__c++;
                                                if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 3) sw.skid.Quantity_to_Scrap__c++;
                                                else if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 2) sw.skid.Quantity_To_Return__c++;
                                                else sw.skid.Quantity_to_Issue__c++;
                                            } else {
                                                sw.skid.Input_Quantity__c--;
                                                if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 3) sw.skid.Quantity_to_Scrap__c--;
                                                else if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 2) sw.skid.Quantity_To_Return__c--;
                                                else sw.skid.Quantity_to_Issue__c--;
                                            }
                                            existingSw.serialList.add(serial);
                                        } else {
                                            sw.skid.Item__r = shl.Item__r;
                                            sw.skid.Quantity_to_Issue__c = 0;
                                            sw.skid.Quantity_To_Return__c = 0;
                                            sw.skid.Quantity_to_Scrap__c = 0;

                                            //ONLY CHANGE LEVEL 1 QUANTITY INPUT FIELD SINCE WE'RE PICKING A SINGLE SERIAL
                                            if (serial.Temporary_Value_Holder__c == 'Pick') {
                                                sw.skid.Input_Quantity__c = 1;
                                                if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 3) sw.skid.Quantity_to_Scrap__c = 1;
                                                else if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 2) sw.skid.Quantity_To_Return__c = 1;
                                                else sw.skid.Quantity_to_Issue__c = 1;
                                            } else {
                                                sw.skid.Input_Quantity__c = -1;
                                                if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 3) sw.skid.Quantity_to_Scrap__c = -1;
                                                else if (sw.skid.Packaging_UOM__r.Package_Class__r.Level__c == 2) sw.skid.Quantity_To_Return__c = -1;
                                                else sw.skid.Quantity_to_Issue__c = -1;
                                            }

                                            swMap.put(key, new SkidService3.SerialWrapper(sw.skid, new List<Serial__c>{ serial }));
                                        }
                                    }

                                    serialFound = true;
                                    break;
                                }
                            }

                            if (serialFound) break;
                        }

                        if (serialFound) break;
                    }

                    if (!serialFound) serviceResponse.addMessage(shlWrapper.requestId, new Message(Message.SEVERITY_ERROR, 'Serial not found: ' + shlWrapper.SerialNumber, ''));
                }

                if (swMap.size() > 0) wrappers.add(new LineWrapper(shl.Shipment__r, shl, swMap.values()));
            }
            
            if (wrappers.size() > 0) ShipmentInventoryService.pick(wrappers);

            serviceResponse.isSuccess = true;  
        } catch (Exception e) {
            serviceResponse.isSuccess = false;
            serviceResponse.addErrorMessage(e.getMessage());
    	}
    }
    
    public static void rollupSalesOrderLineQuantities(){
	
		if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isDelete)){
			Set<Id> solIdSet = new Set<Id>();
			if(trigger.isInsert || trigger.isUpdate){
				for(Shipment_Line__c shLine : (List<Shipment_Line__c>) trigger.new){
					if ( shLine.Sales_Order_Line__c != null ){
		                if (KSE.isFieldChanging('Quantity_Planned__c', shLine, trigger.oldMap) ||
		                    //KSE.isFieldChanging('Quantity_Shipped__c', shLine, trigger.oldMap) ||
		                    KSE.isFieldChanging('Sales_Order_Line__c', shLine, trigger.oldMap)
		                ){
		                    solIdSet.add(shLine.Sales_Order_Line__c);
		                }
			        }
				}
			}
			else
			if (trigger.isDelete) {
				for(Shipment_Line__c shLine : (List<Shipment_Line__c>) trigger.old){
			    	if ( shLine.Sales_Order_Line__c != null ){
	                	solIdSet.add(shLine.Sales_Order_Line__c);
	                }
				}
			}			
			
			if(! solIdSet.isEmpty()){
				rollupSalesOrderLineQuantities(solIdSet);
			}
		}
	}
	
	public static void rollupSalesOrderLineQuantities(Set<Id> solIdSet){
		// Rollup the following quantity fields to the corresponding sales order lines.
		// - Quantity Planned
		// - Quantity Shipped
		Map<Id, Sales_Order_Line__c> solUpdateMap = new Map<Id, Sales_Order_Line__c>();
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Quantity_Planned__c','Quantity_Shipped__c'
		});
		soql.setWhereClause('Id IN :solIdSet FOR UPDATE');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
		childRel.addFields(new set<string>{
			'Id','Quantity_Planned__c','Quantity_Shipped__c'
		});
		childRel.setWhereClause('Shipment__r.Status__c NOT IN (\'Confirmed\', \'Delivered\')');
		
		soql.addChildRelationship(childRel);
		
		for(Sales_Order_Line__c sol : Database.query(soql.getQuery())){
			sol.Quantity_Planned__c = 0;
			
			for(Shipment_Line__c shl : sol.Shipment_Lines__r){
				if(shl.Quantity_Shipped__c == null || shl.Quantity_Shipped__c == 0){
					sol.Quantity_Planned__c = KSE.addQuantityToField(sol.Quantity_Planned__c, shl.Quantity_Planned__c);
				} 
			}
			
			solUpdateMap.put(sol.Id, sol);
		}
			
		if(! solUpdateMap.isEmpty()){
			DML.updateAsUser(solUpdateMap.values());
		}
	}
	
	public static void calculateRollupFields() {
		
		List<Shipment_Line__c> shipLinesList = new List<Shipment_Line__c>();

		if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)){
			
	        Set<ID> solSet = new Set<ID>();
	        List<Shipment_Line__c> shipmentLines = new List<Shipment_Line__c>();

			for(Shipment_Line__c SHL: (List<Shipment_Line__c>) Trigger.new){
				if (Trigger.isUpdate) { //Before Update
	            	Shipment_Line__c oldSHL = (Shipment_Line__c) Trigger.oldMap.get(SHL.Id);
	                //Kndy-4665 to update the number of pallets planned when product or the quantity shipped is changed
	                if (SHL.Product__c != oldSHL.Product__c || SHL.Quantity_Planned__c != oldSHL.Quantity_Planned__c || SHL.Sales_Order_Line__c != oldShL.Sales_Order_Line__c){
	                    shipmentLines.add(SHL);
	                    solSet.add(SHL.Sales_Order_Line__c);
	                }
	            } else if (Trigger.isInsert) { //Before Insert
	                if ( SHL.Sales_Order_Line__c != null ){
	                	shipmentLines.add(SHL);
	                    solSet.add(SHL.Sales_Order_Line__c);
	                }
		        }
			}


			if (solSet.size() > 0){
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Product__r.Dimension_UOM__r.Name','Dimension_UOM__r.Name','Product__r.Item__c','Product__r.Weight_UOM__c','Weight_UOM__c',
					'Product__r.Weight_UOM__r.Name','Weight_UOM__r.Name','Product__r.Width__c','Product__r.Length__c','Product__r.Height__c',
					'Product__r.Weight__c','Product__r.Units_per_Pallet__c','Quantity_From_Stock__c','Quantity_Ordered__c', 'Product__r.Item__r.Packaging_UOM__c',
					'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
				});
				soql.setWhereClause('Id IN :solSet');

				Map<Id, Sales_Order_Line__c> solMap = new Map<Id, Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));

				calculateRollupFields(shipmentLines, solMap);

			}
		}
	}
	
	public static void calculateRollupFields(List<Shipment_Line__c> shipmentLines, Map<Id, Sales_Order_Line__c> solMap){
		decimal conversionFactorForWeight;
		decimal conversionFactorForVolume;
		Map<Id, List<Id>> itemPackagingUOM = new Map<Id, List<Id>> ();
		for (Shipment_Line__c shipLine : shipmentLines){
			if(shipLine.Sales_Order_Line__c!=null){
    			if(solMap.get(shipLine.Sales_Order_Line__c).Product__r!=null){
    			    
    			    if ( !itemPackagingUOM.containsKey(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__c )  ) {
    			        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__r.Packaging_UOM__c , List<Id>.class);
    			        itemPackagingUOM.put(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__c, lstPkgUom ) ;
    			    }
    			    
					shipLine.Weight__c = solMap.get(shipLine.Sales_Order_Line__c).Product__r.Weight__c;
			        shipLine.Weight_UOM__c = solMap.get(shipLine.Sales_Order_Line__c).Product__r.Weight_UOM__c;
			        //kndy-4665 To calculate the product weight and the number of pallets planned when the quantity shipped or the product gets updated
			        conversionFactorForWeight = KSE.getConversionFactor(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__c, solMap.get(shipLine.Sales_Order_Line__c).Ship_From_Location__r.Facility__r.Facility_Identifier__c, solMap.get(shipLine.Sales_Order_Line__c).Product__r.Weight_UOM__c, solMap.get(shipLine.Sales_Order_Line__c).Weight_UOM__c, itemPackagingUOM.get( solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__c ) );
			        
			        shipLine.Product_Weight__c = (KSE.addQuantityToField(shipLine.Quantity_Planned__c, 0) * KSE.addQuantityToField(solMap.get(shipLine.Sales_Order_Line__c).Product__r.weight__c, 0) * conversionFactorForWeight).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Weight_UOM__r.Name, solMap.get(shipLine.Sales_Order_Line__c).Weight_UOM__r.Name);
		
			        if(shipLine.Quantity_Planned__c != null && solMap.get(shipLine.Sales_Order_Line__c).Product__r.Units_per_Pallet__c != null && solMap.get(shipLine.Sales_Order_Line__c).Product__r.Units_per_Pallet__c != 0){
			            Decimal numberOfPalletsPlanned = KSE.addQuantityToField(shipLine.Quantity_Planned__c, 0) / KSE.addQuantityToField(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Units_per_Pallet__c, 0);
			            shipLine.Number_of_Pallets_Planned__c = numberOfPalletsPlanned;
			        }
			        
					if(shipLine.Quantity_Planned__c != null && solMap.get(shipLine.Sales_Order_Line__c).Product__r.Width__c !=null && solMap.get(shipLine.Sales_Order_Line__c).Product__r.Length__c !=null && solMap.get(shipLine.Sales_Order_Line__c).Product__r.Height__c !=null){
						conversionFactorForVolume = KSE.getConversionFactor(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__c,solMap.get(shipLine.Sales_Order_Line__c).Ship_From_Location__r.Facility__r.Facility_Identifier__c, solMap.get(shipLine.Sales_Order_Line__c).Product__r.Dimension_UOM__c, solMap.get(shipLine.Sales_Order_Line__c).Dimension_UOM__c, itemPackagingUOM.get( solMap.get(shipLine.Sales_Order_Line__c).Product__r.Item__c ));
							
						shipLine.Planned_Product_Volume__c = (solMap.get(shipLine.Sales_Order_Line__c).Product__r.Width__c * solMap.get(shipLine.Sales_Order_Line__c).Product__r.Length__c * solMap.get(shipLine.Sales_Order_Line__c).Product__r.Height__c * KSE.addQuantityToField(shipLine.Quantity_Planned__c, 0) * conversionFactorForVolume).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(solMap.get(shipLine.Sales_Order_Line__c).Product__r.Dimension_UOM__r.Name, solMap.get(shipLine.Sales_Order_Line__c).Dimension_UOM__r.Name);
			    	}
    			}
			}
		}
	}
	
	// OTC-16: Reprice sales order lines after aggregation and disaggregation.
    public static void validateSalesOrderLinePrices() {
    	Set<Id> shipmentIds = new Set<Id>();
    	Boolean isAggregation = false;
    	if(trigger.isBefore && trigger.isDelete){
    		shipmentIds = KSE.grepRelatedIdSetFromList( trigger.old, 'Shipment__c');
    		isAggregation = false;
    	}	
	    
    	if(shipmentIds.size() > 0){
   			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Shipment__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Movement_Number__c'
			});
			soql.setWhereClause('Id IN :shipmentIds');
			ShipmentService.validateSalesOrderLinePrices( Database.query(soql.getQuery()), isAggregation );
    	}
    }

    public static void manageSkids() {
        if ((Trigger.isBefore == true && Trigger.isDelete == true) || (Trigger.isAfter == true && (Trigger.isInsert == true || Trigger.isUpdate == true))) {
            List<Shipment_Line__c> shipmentLines = Trigger.isDelete == true ? Trigger.old.clone() : Trigger.new.clone();
            if (Trigger.isUpdate == true) {
                for (Integer i = 0; i < shipmentLines.size(); i++) {
                    Shipment_Line__c shl = shipmentLines[i];
                    if ((KSE.isFieldChanging('Quantity_Planned__c', shl, Trigger.oldMap) == false &&
                    KSE.isFieldChanging('Quantity_Allocated__c', shl, Trigger.oldMap) == false &&
                    KSE.isFieldChanging('Quantity_To_Pick__c', shl, Trigger.oldMap) == false &&
                    KSE.isFieldChanging('Quantity_Picked__c', shl, Trigger.oldMap) == false &&
                    KSE.isFieldChanging('Quantity_Shipped__c', shl, Trigger.oldMap) == false) ||
                    shl.Sales_Order_Line__c == null) {
                        shipmentLines.remove(i--);
                    }
                }
            }

            if (shipmentLines.size() > 0) {
                Map<Id, Shipment_Line__c> queriedShls = new Map<Id, Shipment_Line__c>();
                if (Trigger.isDelete == false) {
                    SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
                    shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Location__c', 'Quantity_Allocated__c',
                        'Quantity_Planned__c', 'Quantity_Picked__c', 'Quantity_Shipped__c', 'Quantity_To_Pick__c', 'Sales_Order_Line__c', 'Shipment__c',

                        'Facility__r.Facility_Identifier__c',

                        'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c',

                        'Sales_Order_Line__r.Selling_UOM__c',

                        'Shipment__r.Status__c' });
                    shlQuery.setWhereClause('Id IN :shipmentLines AND (Sales_Order_Line__c != null AND Sales_Order_Line__r.Fulfillment_Source__c != \'Drop Ship\')');
                    queriedShls = new Map<Id, Shipment_Line__c>((List<Shipment_Line__c>)Database.query(shlQuery.getQuery()));
                }


                Map<Id, SKID__c> skids = new Map<Id, SKID__c>();
                SOQLUtil skidQuery = new SOQLUtil('SKID__c');
                skidQuery.addFields(new Set<String>{ 'Id', 'Quantity__c', 'Shipment_Line__c' });
                skidQuery.setWhereClause('Shipment_Line__c IN :shipmentLines AND Type__c = :SKID_TYPE_SO_DEMAND');
                skidQuery.setForUpdate();
                for (SKID__c skid:Database.query(skidQuery.getQuery())) skids.put(skid.Shipment_Line__c, skid);

                List<SKID__c> skidsToDelete = new List<SKID__c>();
                List<SKID__c> skidsToUpsert = new List<SKID__c>();
                for (Shipment_Line__c shl:shipmentLines) {
                    SKID__c skid = skids.get(shl.Id);
                    if (Trigger.isDelete == true) {
                        if (skid != null) skidsToDelete.add(skid);
                    } else {
                        if (queriedShls.containsKey(shl.Id) == false) continue;
                        shl = queriedShls.get(shl.Id);

                        Decimal convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class));
                        Decimal qty = (shl.Quantity_Planned__c * convFactor) - (shl.Quantity_Allocated__c * convFactor) - shl.Quantity_To_Pick__c - shl.Quantity_Picked__c - (shl.Quantity_Shipped__c * convFactor);
                        if ((shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED || shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_DELIVERED || qty == 0) && skid != null) {
                            skidsToDelete.add(skid);
                        } else if (shl.Shipment__r.Status__c != ShipmentService.SHIPMENT_STATUS_CONFIRMED && shl.Shipment__r.Status__c != ShipmentService.SHIPMENT_STATUS_DELIVERED && qty > 0 && (skid == null || skid.Quantity__c != qty)) {
                            if (skid == null) {
                                skid = new SKID__c(
                                    Company__c = shl.Company__c,
                                    Container_Item__c = shl.Item__c,
                                    Facility2__c = shl.Facility__c,
                                    Item__c = shl.Item__c,
                                    Location__c = shl.Location__c,
                                    Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                                    Sales_Order_Line__c = shl.Sales_Order_Line__c,
                                    Shipment_Line__c = shl.Id,
                                    Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                                    Type__c = SkidService3.SKID_TYPE_SO_DEMAND
                                );
                                skid.Unique_Key__c = SkidService3.generateSkidUniqueKey(skid);

                            }

                            skid.Quantity__c = qty;
                            skid.Quantity_Stocking_UOM__c = qty;
                            skidsToUpsert.add(skid);
                        }
                    }
                }

                if (skidsToDelete.size() > 0) DML.deleteAsSystem(skidsToDelete);
                if (skidsToUpsert.size() > 0) { DML.upsertAsSystem(); upsert skidsToUpsert; }
            }
        }
    }
    
    public static void validateShipDate(){
    	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
    		Set<Id> shipmentIds = new Set<Id>();
    		
    		for(Shipment_Line__c shl : (List<Shipment_Line__c>) trigger.new){
    			if(shl.Sales_Order_Line__c != null){
		    		if(KSE.isFieldChanging('Sales_Order_Line__c', shl, trigger.oldMap) || 
		    		   KSE.isFieldChanging('Shipment__c', shl, trigger.oldMap)
		    		){
		    			shipmentIds.add(shl.Shipment__c);
		    		}
    			}
    		}
    		
    		if(! shipmentIds.isEmpty() ){
    			ShipmentLineService.validateShipDate(shipmentIds);
       		}
    	}
    }
    
    public static void validateShipDate(Set<Id> shipmentIds){
    	ExceptionService exServ = new ExceptionService();
    	 	
    	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Shipment_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Shipment__r.Shipment_Date_Estimated__c','Shipment__r.Customer__r.Aggregate_Shipments__c','Sales_Order_Line__r.Earliest_Ship_Date__c',
			'Sales_Order_Line__r.Latest_Ship_Date__c', 'Need_Date__c', 'Location__r.Facility__r.Shipping_Calendar__c','Estimated_Ship_Date__c',
			'Shipment__r.Customer__r.Earliest_Delivery_Window__c','Shipment__r.Customer__r.Latest_Delivery_Window__c', 'Facility__r.Facility_Identifier__c'
		});
		soql.setWhereClause('Shipment__c IN :shipmentIds');
		
		for(Shipment_Line__c shl : Database.query(soql.getQuery())){	
    		if(shl.Shipment__r.Customer__r.Aggregate_Shipments__c){
	    								 	
				// ba-todo Consider not having this code. Might be better to create new fields to track Customer's Shipping window
				Date needDate = shl.Need_Date__c;
				Id facilityCal = shl.Location__r.Facility__r.Shipping_Calendar__c;

				DateTime earliestShipDate = KSE.calculateStartDate(shl.Estimated_Ship_Date__c, Integer.valueOf(shl.Shipment__r.Customer__r.Earliest_Delivery_Window__c), facilityCal);
				
				if (earliestShipDate != null) {
					earliestShipDate = KSE.convertTimeZones( earliestShipDate, Timezone.getTimeZone( 'GMT' ), UserInfo.getTimeZone() );
				}
				
				DateTime latestShipDate = KSE.calculateEndDate(shl.Estimated_Ship_Date__c, Integer.valueOf(shl.Shipment__r.Customer__r.Latest_Delivery_Window__c), facilityCal);
				if (latestShipDate != null) {
					latestShipDate = KSE.convertTimeZones( latestShipDate, Timezone.getTimeZone( 'GMT' ), UserInfo.getTimeZone() );
				}
    
				// Check to see the SHL plan window is the range of the Shipment's Estimated Ship Date range
	    		if( earliestShipDate != null && latestShipDate !=null && (shl.Shipment__r.Shipment_Date_Estimated__c < earliestShipDate.date() ||
	    			shl.Shipment__r.Shipment_Date_Estimated__c > latestShipDate.date())
	    		){
	    			exServ.setException(shl, ExceptionUtil.SHIP_DATE_OUT_OF_RANGE);
				} else {
					exServ.clearException(shl, ExceptionUtil.SHIP_DATE_OUT_OF_RANGE);
				}
    		}
    	}
    	
    	exServ.finish();
    }
    			
}