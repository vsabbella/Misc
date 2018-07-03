public class AgreementService {
//KNDY-8247	
	public static void  getPaymentTerms(List <Agreement__c> arList) {
	    set<id> agId =new set<id>();
	    list<Agreement__c> aglist = new list<Agreement__c>();
	    for(Agreement__c al:arList){
	           agId.add(al.id); 
	    }
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Customer__r.Payment_Term__c','Payment_Terms__c'
		});
		soql.setWhereClause('ID IN :agId');
		arList = Database.query(soql.getQuery());

    	for(Agreement__c al:arList){
             
    		if(al.Payment_Terms__c == null && al.Customer__r.Payment_Term__c != null){
	         	al.Payment_Terms__c = al.Customer__r.Payment_Term__c;
	         	aglist.add(al);
    		}
        }
    	if(!aglist.isEmpty()){
        	DML.updateAsUser(aglist);
    	}
    
	}

	/* KNDY-11699 - Serial Allocate in Agreement release process
	@Description - Future call to perform auto release and auto allocate of sales orders that are created from sales agreements

	@param - 1. set of sales order ids (SOs that get created in Agreement release process)
	2. set of serial ids(serials selected in the agreement release ui)
	*/
	@future
	public static void autoReleaseAllocateSOs (Set<id> SOs, Set<id> SOLs, Set<id> Serials){

		//Have this handled for exceptions and create SO exception to indicate auto release/allocate failure
		Savepoint sp = Database.setSavepoint();
		Schemautil util = new Schemautil();
		try {
			/*
			@Block 1 - Auto release
			1. Plan function is invoked to release the SOs
			2. SOs are created and immediately released, so it is safe to assume there will not be any shipments ie., the second parameter is null in plan method
			*/
			for (id so : SOs){
				SalesOrderService SOSerivce = new SalesOrderService();
				SOSerivce.plan(so, null);
			}

			/*
			@Block 2 - Auto allocate
			1. After plan is successful, Shipments are created
			2. Query the shipment lines using the SOL ids passed to this function
			3. Get the serials and its SKID based on the Serial ids passed to this function
			*/

            List<Shipment_Line__c> shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order_Line__c IN (\'' + String.join(new List<Id>(SOLs), '\', \'') + '\')', 'allocate');

            SOQLUtil serialQuery = SkidService3.getSerialSoql(new Map<String, String>{ 'WHERE' => 'Id IN :Serials' });
            for (String skidField:SkidService3.getSkidSoql(new Map<String, String>()).getFields()) serialQuery.addField('SKID__r.' + skidField);
            List<Serial__c> serialList = Database.query(serialQuery.getQuery());

			/* Build the line wrapper for allocation serials and invoke the ShipmentInventoryService
			1. Associate the shipment to serials.
			1.1 Loop through shipments and find matching serial ie., shipment's product's item should match serial's item
			1.2 Build Serial wrapper and group by SKID
			2. Invoke the ShipmentInventoryService validate method to check for any error
			3. Invoke the ShipmentInventoryService validate method to save the allocations
			*/

			// step 1.1
			Set<id> serialsUsed = new Set<id>();
			Map<id, List<Serial__c>> solIDtoSerials = new Map<id, List<Serial__c>>();
			for (Shipment_Line__c shl : shipmentLines){
				boolean isSOLRental = false;
				if (shl.Sales_Order_Line__r.Price_Type__c == 'Recurring'){
					isSOLRental = true;
				}else{
					isSOLRental = false; 
				}
				List<Serial__c> tmpSerialList = new List<Serial__c>();
				for (Serial__c srl : serialList){
					if (shl.Item__c == srl.Item__c){
						if (!serialsUsed.contains(srl.id)){ //Dont use the same serial, so check if it is used and then assign it to the map
							if ((srl.SKID__r.Used__c == shl.Sales_Order_Line__r.Product__r.Used__c) && (isSOLRental == srl.SKID__r.Rental__c)) {
								if (!solIDtoSerials.containsKey(shl.Sales_Order_Line__c)){
									srl.Temporary_Value_Holder__c = 'Allocate';
									tmpSerialList.add(srl);
									solIDtoSerials.put(shl.Sales_Order_Line__c,tmpSerialList);
									serialsUsed.add(srl.id);
								}
								else{
									if (!isSOLRental){
										tmpSerialList = solIDtoSerials.get(shl.Sales_Order_Line__c);
										srl.Temporary_Value_Holder__c = 'Allocate';
										tmpSerialList.add(srl);
										solIDtoSerials.put(shl.Sales_Order_Line__c,tmpSerialList);
										serialsUsed.add(srl.id);
									}
								}
							}
						}
					}
				}
			}

			//step 1.2
            List<LineWrapper> shlWrappers = new List<LineWrapper>();
            for (Shipment_Line__c shl:shipmentLines) {
                if (solIDtoSerials.containsKey(shl.Sales_Order_Line__c)) {
                    LineWrapper shlWrapper = new LineWrapper(shl.Shipment__r, shl, new List<SkidService3.SerialWrapper>());

                    Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
                    for (Serial__c serial:solIDtoSerials.get(shl.Sales_Order_Line__c)) {
                        if (serialMap.containsKey(serial.SKID__c) == false) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
                        else serialMap.get(serial.SKID__c).add(serial);
                    }

                    for (Id skidId:serialMap.keySet()) {
                        List<Serial__c> serList = serialMap.get(skidId);

                        SKID__c skid = serList[0].SKID__r;
                        skid.Quantity_Allocated__c = skid.Quantity_Stocking_UOM__c / shlWrapper.convFactor;
                        skid.Quantity_Available__c = skid.Quantity_Allocated__c;
                        skid.Input_Quantity__c = serList.size() / shlWrapper.convFactor;

                        shlWrapper.serialWrappers.add(new SkidService3.SerialWrapper(skid, serList));
                    }

                    shlWrappers.add(shlWrapper);
                }
            }

            AllocationService.allocate(shlWrappers);
		}catch (Exception e){
            Database.rollback(sp);
            //Should add logic to create exception task on SOs
        }

	}

	public static void setRecurrenceStartDate() {
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
			for(Agreement__c ag : (list<Agreement__c>) trigger.new) {
				if(KSE.isFieldChanging('Activation_Date__c', ag, trigger.oldMap) && ag.Activation_Date__c != null && ag.Recurrence_Start_Date__c == null && ag.Billing_UOM__c != null)
						ag.Recurrence_Start_Date__c = DateTime.newInstance(ag.Activation_Date__c,Time.newInstance(0,0,0,0));
			}
		}


	}
}