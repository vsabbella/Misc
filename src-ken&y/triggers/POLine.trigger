trigger POLine on Purchase_Order_Line__c (  before insert, before update, after insert, after update,
                                                                    before delete, after delete, after undelete  ) {

	if(DML.checkTriggerDispatch(Purchase_Order_Line__c.getSobjectType())){return;}

    Integer i, i1;
    Decimal poline;  
    Set< Id > mcrSet = new Set<Id>();
    List<SKID__c> newSKID = new List<SKID__c>();
    List<SKID__c> updSKID = new List<SKID__c>();
    Decimal oldRecvdQty;
    
    set <ID> poset = new set<ID>(); 
    
    set<ID> itemsSet = new set<ID>();
    set<ID> facilitySet = new set<ID>();
    set<ID> supplierSet = new set<ID>();
    set<Id> purchaseAgreementSet = new set<Id>();
    
    Map< Id, Item__c > itemsForUpdate = new Map< Id, Item__c >();       
    Map<id,Decimal> maxMap = new Map<id,Decimal>();
    map<id,Purchase_Order__c> poMap = new map<id,Purchase_Order__c>();
    map<Id, Item__c> items;
    
    Map<Id,Decimal> poLineQuantityToConsume = new Map<Id,Decimal>();
    
    static SchemaUtil util = SchemaUtil.getInstance();
    
    map<id,Contract_Line__c> contractLinesMap = new map<id,Contract_Line__c>();
    map<string,Contract_Line__c> uniqueContractLinesMap = new map<string,Contract_Line__c>();

    Map<Id, Facility__c> mapFacility = new Map<Id, Facility__c>();
    map<Id,Contract_Line__c> contractLinesToUpdate = new map<Id,Contract_Line__c>();
    Set<Id> consignedRecalcItemSet = new Set<Id>(); // PTP-388
    List<Purchase_Order_Line__c> consignedRecalcPOLineList = new List<Purchase_Order_Line__c>(); // PTP-388
    
    set<id> contractLineIds = new set<id>();
    
    boolean checkForApprovedSupplier = false;
    map<string,Item_Cross_Reference__c> itemCrossReferenceMap = new map<string,Item_Cross_Reference__c>();

	Boolean shouldPObeSaved = false; //PTM-94 Variable to track the change in PO MAP and save only if the PO Map has changed. This is to avoid infinite looping for updates from PO to PO Line and vice versa
    
    list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions =  new list<RollUpSummaryUtility.fieldDefinition> {
        new RollUpSummaryUtility.fieldDefinition('SUM', 'Total_Weight__c', 'Total_Weight__c'),
        new RollUpSummaryUtility.fieldDefinition('MAX', 'Weight_UOM__c', 'Weight_UOM__c')
    };
    
    if ( ! Trigger.isDelete ) {
        CompanyService.setDefaultCompany(Trigger.new, Trigger.isBefore) ;       
    
        CompanyService.setLookupUsingField(Trigger.new, Trigger.isBefore, 
                    'Purchase_Order__c', 'Purchase_Order__c', 'Purchase_Order_Number__c','Purchase_Order_Number__c');
        
        CompanyService.setLookupUsingField(Trigger.new, Trigger.isBefore, 
                    'Item__c', 'Item__c', 'Item_Name__c','Name');       
    }
    
    VoidCancelService.validateLines();
    
    if( ( Trigger.isInsert || Trigger.isUpdate ) && Trigger.isBefore ){
    	for(Purchase_Order_Line__c POL:Trigger.New) { 
    		
            poset.add(POL.Purchase_Order__c);   
            contractLineIds.add(POL.Contract_Line__c);
            
            facilitySet.add(POL.Delivery_Facility__c);
            supplierSet.add(POL.Supplier__c);
            
            if( POL.Item__c != null )   
                itemsSet.add( POL.Item__c );
        }

        mapFacility = PurchaseOrderLineService.cachedFacilities(facilitySet);

        // KNDY-10473 FLS Security Fixes for SOQL queries
        SOQLUtil poSoql = new SOQLUtil ('Purchase_Order__c');
        poSoql.addFields ( new Set<String> { 'Id','Purchase_Agreement__c','Approval_Status__c','Status__c','Total_Number_of_Lines__c','Type__c', 'Supplier__c' } ) ;
        poSoql.setWhereClause ( ' id in :poset ' );
        
        SOQLUtil.ChildRelationship polSoql = new SOQLUtil.ChildRelationship ( poSoql , 'Purchase_Order_Lines__r' ) ;
        polSoql.addFields ( new Set<String> {'Id', 'Line__c'} ) ; 
        polSoql.setOrderByClause ( 'Line__c DESC' );
        polSoql.setLimit(1);
        poSoql.addChildRelationship ( polSoql ) ;
        
        /*for ( Purchase_Order__c p: [Select (Select Id, Line__c From Purchase_Order_Lines__r order by Line__c DESC limit 1), Id, Purchase_Agreement__c, Approval_Status__c, Status__c, Total_Number_of_Lines__c  
                                        From Purchase_Order__c where id in :poset ]) {*/
        for (  Purchase_Order__c p: Database.query ( poSoql.getQuery() ) ) {
            // populate a map containing the current max line number for each PO
            maxMap.put(p.id, p.Purchase_Order_Lines__r.size() > 0 ? p.Purchase_Order_Lines__r[0].Line__c :0.0 );
            poMap.put(p.Id,p);
            purchaseAgreementSet.add(p.Purchase_Agreement__c);
        }

        for(Purchase_Order_Line__c POL:Trigger.New) {
            pol.Delivery_Facility__r = mapFacility.get(pol.Delivery_Facility__c);
        }


        SOQLUtil polinesSoql = new SOQLUtil ('Purchase_Order_Line__c');
        polinesSoql.addFields ( new Set<String> { 'Id','Order_Quantity__c','Purchase_Order__c','Contract_Line__c' } ) ;
        polinesSoql.setWhereClause ( ' Purchase_Order__c in :poset ' );
        
        SOQLUtil.ChildRelationship rcptLinesSoql = new SOQLUtil.ChildRelationship ( poSoql , 'Receipt_Lines__r' ) ;
        rcptLinesSoql.addFields ( new Set<String> {'Id', 'Quantity_To_Consume__c'} ) ; 
        
        polinesSoql.addChildRelationship ( rcptLinesSoql ) ;
        
        /*for (Purchase_Order_Line__c POL : [Select Id, Order_Quantity__c, Purchase_Order__c, Contract_Line__c, 
        										 (SELECT Id, Quantity_To_Consume__c FROM Receipt_Lines__r)
        								  FROM Purchase_Order_Line__c
        								  WHERE Purchase_Order__c IN :poset]) {*/
        for ( Purchase_Order_Line__c POL : Database.query ( polinesSoql.getQuery() ) ) {
            if(POL.Receipt_Lines__r.size() > 0) {							  	
                // When PO is Approved, this query will fetch POLines not in Trigger.New
                if (Trigger.isUpdate && Trigger.NewMap.containsKey(POL.Id) && Trigger.NewMap.get(POL.Id).Approved__c == true
                      && KSE.isFieldChanging('Delivery_Facility__c', Trigger.NewMap.get(POL.Id), Trigger.oldMap)){ // PTP-388
                    Trigger.NewMap.get(POL.Id).addError(Label.Facility_cannot_change_on_Approved_Purchase_Order_Line_with_Receipts);
                }
	        	for(Receipt_Line__c rLine : POL.Receipt_Lines__r) {							  	
		        	if(poLineQuantityToConsume.containsKey(POL.Id)) {
		        		poLineQuantityToConsume.put(POL.Id,poLineQuantityToConsume.get(POL.Id)+rLine.Quantity_To_Consume__c);
		        	}
		        	else {
		        		poLineQuantityToConsume.put(POL.Id,rLine.Quantity_To_Consume__c);
		        	}
	        	}	
        	}
        	else {
            	poLineQuantityToConsume.put(POL.Id,POL.Order_Quantity__c);
            	// PTP-388 consigned flag should be recalculated for updated POLs without PA and Receipts on:
            	// 1. non-approved POlines, and 
            	// 2. approved POLs when Facility changes
            	if (Trigger.isUpdate && Trigger.NewMap.containsKey(POL.Id) && 
                    	poMap.get(POL.purchase_order__c).Purchase_Agreement__c == null &&
                    	POL.Contract_Line__c == null){
                	if(Trigger.NewMap.get(POL.Id).Approved__c == false){
                    	consignedRecalcItemSet.add(Trigger.NewMap.get(POL.Id).Item__c);
                    	consignedRecalcPOLineList.add(Trigger.NewMap.get(POL.Id));
                	}
                	else {
                    	if (KSE.isFieldChanging('Delivery_Facility__c', Trigger.NewMap.get(POL.Id), Trigger.oldMap)){
                        	consignedRecalcItemSet.add(Trigger.NewMap.get(POL.Id).Item__c);
                        	consignedRecalcPOLineList.add(Trigger.NewMap.get(POL.Id));
                    	}
                	}
            	}
        	}					  	
	    }
        
        SOQLUtil soql = new SOQLUtil('Contract_Line__c');
        soql.addFields(new set<string>{'Contract__r.Supplier__c', 'Invoice_Matching__c'});
        soql.addAllFields();

        string conditional = ' (Id IN : contractLineIds) OR ' +
                             ' (Item__c IN :itemsSet AND ' +
                             ' Contract__c IN :purchaseAgreementSet)';
                             
        soql.setWhereClause(conditional);

        String queryString = soql.getQuery();
        List<Contract_Line__c> contractLinesList = Database.query( queryString );

        for(Contract_Line__c cl : contractLinesList) {
            contractLinesMap.put(cl.Id, cl);
            for(Purchase_Order_Line__c pol : Trigger.New) {
            	System.Debug(LoggingLevel.Info, cl);
            	if(pol.Contract_Line__c == cl.Id) {
            		//String key = '' + cl.Item__c + cl.Blanket_Number__c;
                    uniqueContractLinesMap.put(cl.Id,cl);
            	}
                else if(pol.Need_Date__c >= cl.Contract_Start__c && pol.Need_Date__c <= cl.Contract_End__c) {
                    //String key = '' + cl.Item__c + cl.Contract__c;
                    uniqueContractLinesMap.put(cl.Id,cl);
                }
            }
        }
        
        if( itemsSet.size() > 0 ) {
            SOQLUtil itmSoql = new SOQLUtil ( 'Item__c' ) ;
            Set<String> itmFields = new Set<String> {
                                            'ID','Name','Company__c','Approved_Supplier_Required__c','Purchasing_UOM__c','Purchasing_UOM__r.Name',
                                            'Source__c', 'Stocking_UOM__c','Stocking_UOM__r.Name','Weight__c','Weight_UOM__c','Weight_UOM__r.Name',
                                            'Packaging_UOM__c'
                                        } ;
            itmSoql.addFields ( itmFields ) ;
            itmSoql.setWhereClause ( 'ID IN: itemsSet' ) ;
            //items = new map< Id, item__c >( [ select ID, Name,Company__c, Approved_Supplier_Required__c,Purchasing_UOM__c, Purchasing_UOM__r.Name, Stocking_UOM__c, Stocking_UOM__r.Name, Weight__c, Weight_UOM__c, Weight_UOM__r.Name from Item__c where ID IN: itemsSet ]);
            items = new map< Id, item__c>( (List<Item__c>)  Database.query ( itmSoql.getQuery() ) ) ;
        }
        
        PurchaseOrderLineService.defaultPurchaseUOMFromItem (Trigger.New, items); //KNDY-10604
        
        if (Trigger.isInsert && Trigger.isBefore) { // set line numbers
	        for(Purchase_Order_Line__c POL:Trigger.New){                // add one so line numbers increment by 1
	            POL.Line__c = maxMap.get(POL.Purchase_Order__c) + 1;    // actual setting of the line number
	            maxMap.put(POL.Purchase_Order__c, POL.Line__c );        // update the map as more lines may be in .New list
	            
	        }
            //Call Service Method for UOM Conversion
            
            itemsForUpdate = PurchaseOrderLineService.setUOM(items,itemsForUpdate);
	            	
	        if( itemsForUpdate.values().size() > 0 )
	        	DML.updateAsUser(itemsForUpdate.values());
	        
	        { // When Inserts, Copies the Weight of the Product.  KNDY-614
	            
	            for(Purchase_Order_Line__c POL: Trigger.new) {
	                if ( POL.Item__c != null && POL.Status__c != 'Closed' ) {
	                    Item__c item = items.get(POL.Item__c);
	                    POL.Weight__c = item.Weight__c;
	                    POL.Weight_UOM__c = item.Weight_UOM__c;
	                    } 
	            }
	        } 
	    }  // end before insert
        
        if (consignedRecalcItemSet.size() > 0){ // PTP-388
            Set<String> icrFields = new Set<String> { 'id','Name','Active__c','Approval_Status__c','Item__c','Item__r.Name','Item__r.Approved_Supplier_Required__c','Supplier__c','Ship_to_Facility__c','Consigned__c' } ;
            SOQLUtil icrSoql = new SOQLUtil ( 'Item_Cross_Reference__c' ) ;
            icrSoql.addFields ( icrFields ) ;
            icrSoql.setWhereClause ( 'Item__c IN :consignedRecalcItemSet AND Active__c = true AND Approval_Status__c = \'Approved\'' ) ;
            
            /*for( Item_Cross_Reference__c icr : [ SELECT id,Name, Active__c, Approval_Status__c, Item__c, Item__r.Name, Item__r.Approved_Supplier_Required__c,
                   Supplier__c, Ship_to_Facility__c, Consigned__c 
                   FROM Item_Cross_Reference__c WHERE Item__c IN :consignedRecalcItemSet AND Active__c = true AND Approval_Status__c = 'Approved']){*/
            for ( Item_Cross_Reference__c icr: Database.query ( icrSoql.getQuery() )  ) {
                itemCrossReferenceMap.put(''+icr.Item__c+icr.Ship_to_Facility__c+icr.Supplier__c,icr);  	
            } 
        }
        
        for (Purchase_Order_Line__c pol: consignedRecalcPOLineList){ // PTP-388
            String facilityKey = '' + pol.Item__c + pol.Delivery_Facility__c + pol.Supplier__c;
            string companyKey = '' + pol.Item__c + 'null' + pol.Supplier__c;
            pol.Consigned__c = false;
            pol.Item_Cross_Reference__c = null;
            if(itemCrossReferenceMap.containsKey(facilityKey)) { // FACILITY SPECIFIC
                pol.Consigned__c = itemCrossReferenceMap.get(facilityKey).Consigned__c;
                pol.Item_Cross_Reference__c = itemCrossReferenceMap.get(facilityKey).Id;
            }
            else if(itemCrossReferenceMap.containsKey(companyKey)) { // COMPANY WIDE
                pol.Consigned__c = itemCrossReferenceMap.get(companyKey).Consigned__c;
                pol.Item_Cross_Reference__c = itemCrossReferenceMap.get(companyKey).Id;
            }
        }
    	
    	
    	//KNDY - 1807
    //	System.Debug(LoggingLevel.Info, uniqueContractLinesMap);
    	for( Purchase_Order_Line__c POL:Trigger.New ){
    		
            //KNDY-11957 Approval process is controlled by 'Source Document Approval' custom setting
            boolean useApproval = false;
            if (KSE.getSourceDocumentApprovals().containsKey('Purchase Order')){
                Source_Document_Approval__c sda = Source_Document_Approval__c.getValues('Purchase Order');
                useApproval = sda.Allow_Approval__c; //set the approval to true if the custom setting says so
                system.debug('useApproval--'+useApproval);
            }
            if (poMap.get(POL.purchase_order__c).Type__c == 'SubContract'){
                useApproval = true;
            }
    		
    		if(trigger.isInsert){
    			//PTM-94 Flip PO Approval status when a new PO line is added
    			if (poMap.containsKey(POL.purchase_order__c)){
    				if(poMap.get(POL.purchase_order__c).Purchase_Agreement__c == null && poMap.get(POL.purchase_order__c).Approval_Status__c == 'Approved' && useApproval){
     					poMap.get(POL.purchase_order__c).Approval_Status__c = 'Pending Authorization';
     					shouldPObeSaved = true;
    				}
    				else {
    					if(poMap.get(POL.purchase_order__c).Total_number_of_Lines__c > 0 && poMap.get(POL.purchase_order__c).Approval_Status__c == 'Approved' && useApproval){
    						poMap.get(POL.purchase_order__c).Approval_Status__c = 'Pending Authorization';
    						shouldPObeSaved = true;
    					}
    				}
 				} 
                if (!useApproval){
                    POL.Approved__c = true; //if approval step is not required, then insert the lines as approved
                }
                //POL.Quantity_Uninvoiced__c = POL.Order_Quantity__c;
    		}
    		
    		//system.debug('**Quantity_Uninvoiced__c*before***'+POL.Quantity_Uninvoiced__c);
    		
    		if( Trigger.isUpdate ){
    			/* if (KSE.isFieldChanging('Order_Quantity__c',POL,Trigger.oldMap)) {
                    //PTP-666 When order qty is changed check if any invoices are against the PO, accordingly calculate the qty uninvoiced
                    //if no invoice was created then just apply the order qty as the qty uninvoiced
                    if (KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Order_Quantity__c'))) == KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Uninvoiced__c')))){
						POL.Quantity_Uninvoiced__c = POL.Order_Quantity__c;
					}
                    //else calculate the delta in order qty and apply the delta to the qty invoiced
                    else{
                        POL.Quantity_Uninvoiced__c = POL.Order_Quantity__c - (KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Order_Quantity__c'))) - POL.Quantity_Uninvoiced__c);
                    }

                } */
    			//PTM-94 Flip PO Approval Status when any of the field in the field set has changed
				Boolean flipPOStatus = false;
				//PTP-389 Reopen Closed PO Lines
				//Below logic flips the status of PO Line to closed when received in full, the WF that does this is now deactivated
				if ((KSE.isFieldChanging('Quantity_Still_Due__c',POL,Trigger.oldMap)) && (POL.Quantity_Still_Due__c == 0) && 
                    (POL.Status__c != 'Cancelled')){
					POL.Status__c = 'Closed';
					POL.Date_Closed__c = system.today(); 
				}
                if (useApproval){
    			for(String str: util.getFieldsFromFieldSetString(Purchase_Order_Line__c.sObjectType , 'FlipPOApprovalStatus')){
					if (KSE.isFieldChanging(str, POL, Trigger.oldMap)){
						flipPOStatus = true;
						break;
					}
    			}
                }
				if (flipPOStatus){
					if (poMap.containsKey(POL.purchase_order__c)){
						if (poMap.get(POL.purchase_order__c).Approval_Status__c == 'Approved'){
	     					poMap.get(POL.purchase_order__c).Approval_Status__c = 'Pending Authorization';
	     					shouldPObeSaved = true;
						}
     				}	
				}
				//PTP-253 Un-cancel a purchase order
				//Flip PO Approval Status to Pending Authorization when Line Status changes from Cancelled to Open to enable Sub Contract flow to go through successfully 
				if ((KSE.isFieldChanging('Status__c', POL, Trigger.oldMap) && (POL.Status__c == 'Open') && (poMap.get(POL.purchase_order__c).Status__c != 'Open'))) {
					poMap.get(POL.purchase_order__c).Status__c = 'Open';
	     			shouldPObeSaved = true;
				}
    		} //end KNDY-1807
    		//system.debug('**Quantity_Uninvoiced__c****'+POL.Quantity_Uninvoiced__c);
    		
    		//KNDY-2303
            //KNDY-3956
            Purchase_Order__c po = poMap.get(POL.Purchase_Order__c);
            if(po.Purchase_Agreement__c != null) {
                if(POL.Contract_Line__c != null && uniqueContractLinesMap.containsKey(POL.Contract_Line__c)) {
                    Contract_Line__c cLine = uniqueContractLinesMap.get(POL.Contract_Line__c);
                    if (Trigger.isInsert){
                    	POL.Consigned__c = cLine.Consigned__c; //PTP-180 Get the consigned flag from the agreement only on insert
                    	POL.Item_Cross_Reference__c = cLine.Item_Cross_Reference__c;
                    }
                    if (Trigger.isUpdate && KSE.isFieldChanging('Item__c', POL, Trigger.oldMap)) {
                    	if(cLine.Invoice_Matching__c != null){
                    		POL.Invoice_Matching__c = cLine.Invoice_Matching__c;
                    	}else{
                    		POL.Invoice_Matching__c = POL.Supplier__r.Invoice_Matching__c;
                    	}
                   
                    	POL.Consigned__c = cLine.Consigned__c; //PTP-180 Get the consigned flag from the agreement for updates only if the Item is changed
                    	POL.Item_Cross_Reference__c = cLine.Item_Cross_Reference__c;
                    }
                    	
                    if(POL.Contract_Line__c != null && ((POL.Consigned__c && poLineQuantityToConsume.get(POL.Id) > 0) || !POL.Consigned__c && POL.Status__c == 'Open')) {
                    	if (Trigger.isInsert){//PTP-296
	                    	if (cLine.Type__c == 'Tiered'){
	                            if (POL.Order_Quantity__c > cLine.Tier_9_Max__c && POL.Order_Quantity__c <= cLine.Tier_10_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_10_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_8_Max__c && POL.Order_Quantity__c <= cLine.Tier_9_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_9_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_7_Max__c && POL.Order_Quantity__c <= cLine.Tier_8_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_8_Price__c;      
	                            else if (POL.Order_Quantity__c > cLine.Tier_6_Max__c && POL.Order_Quantity__c <= cLine.Tier_7_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_7_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_5_Max__c && POL.Order_Quantity__c <= cLine.Tier_6_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_6_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_4_Max__c && POL.Order_Quantity__c <= cLine.Tier_5_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_5_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_3_Max__c && POL.Order_Quantity__c <= cLine.Tier_4_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_4_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_2_Max__c && POL.Order_Quantity__c <= cLine.Tier_3_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_3_Price__c;
	                            else if (POL.Order_Quantity__c > cLine.Tier_1_Max__c && POL.Order_Quantity__c <= cLine.Tier_2_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_2_Price__c;
	                            else if (POL.Order_Quantity__c >= 0 && POL.Order_Quantity__c <= cLine.Tier_1_Max__c)
	                                POL.Unit_Price__c = cLine.Tier_1_Price__c;
	                        } 
	                        else{ 
                            	POL.Unit_Price__c = KSE.addQuantityToField(cLine.Negotiated_Price__c, 0);
	                        }
                    	}
                    }
                    Contract_Line__c cl;
                    if(contractLinesToUpdate.containsKey(POL.Contract_Line__c)) {
                    	cl = contractLinesToUpdate.get(POL.Contract_Line__c);
                    }
                    else {
                    	cl = contractLinesMap.get(POL.Contract_Line__c);
                    }
                    
                 	Decimal oldQty = 0.00;
            		oldQty = ((Trigger.oldMap != null && Trigger.oldMap.containsKey(POL.Id) && Trigger.oldMap.get(POL.Id).Order_Quantity__c != null) ? Trigger.oldMap.get(POL.Id).Order_Quantity__c : oldQty);
            	
                	Decimal newQty = (POL.Order_Quantity__c == null ? 0.00 : POL.Order_Quantity__c);
                	Decimal netQtyChange = newQty - oldQty;
                	
                	System.Debug(loggingLevel.info,'oldQty on PO Line: ' + oldQty);
                	System.Debug(loggingLevel.info,'newQty on PO Line: ' + newQty);
                	System.Debug(loggingLevel.info,'netQtyChange on PO Line: ' + netQtyChange);
                	
                	Decimal qtyToVerify = 0;
                	if (KSE.FieldUsedtoReleasePO == 'Remaining_Quantity__c')
                		qtyToVerify = cl.Remaining_Quantity__c;
            		else
            			qtyToVerify = cl.Available_Quantity__c;
                	
                	if((netQtyChange != 0) && (netQtyChange > qtyToVerify)) { // PTP-341 or KNDY-6627 Only throw error if net change is anything but 0
                   		POL.addError(Label.Net_change_in_OrderQuantity_is_greater_than_RemainingQuantity + 'PO Line-' + POL.Line__c + ' (' + items.get(POL.Item__c).Name + ')');
              	    }
                	else if(netQtyChange != 0) {
                    	cl.Purchased_Quantity__c += netQtyChange; 
			     	    //cl.Purchased_Value__c += netQtyChange * POL.Unit_Price__c; PTP-399
			     	    contractLinesToUpdate.put(cl.Id, cl);
                	} 
                	if(Trigger.isInsert){
						cl.Quantity_Still_Due__c+= KSE.addQuantitytoField(pol.Quantity_Still_Due__c,0);
						contractLinesToUpdate.put(cl.Id, cl);		
                	}
                	//PTP-120 When RTV is done, put the quantity back to the Agreement
                	//Qty adjustment is done with delta of OLD and NEW Values
                	if (Trigger.isUpdate){
	                	Decimal qtyRecd = 0;
	                	Decimal qtyRetdsc = 0;
	                	Decimal qtyRetds = 0;
	                	Decimal qtyStillDue = 0;
	                	if (!KSE.hasAlreadyfired() || Test.isRunningTest()){
	                	//Update Contract's Qty Returned when Qty returned is updated on PO. 
	                	if (KSE.isFieldChanging('Quantity_Returned_to_Supplier_for_Credit__c',POL, Trigger.oldMap)){
							qtyRetdsc = KSE.addQuantitytoField(pol.Quantity_Returned_to_Supplier_for_Credit__c,0) - KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Returned_to_Supplier_for_Credit__c')));
							cl.Purchased_Quantity__c = KSE.addQuantitytoField(cl.Purchased_Quantity__c, 0) - KSE.addQuantitytoField(pol.Quantity_Returned_to_Supplier_for_Credit__c,0) + KSE.addQuantitytoField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Returned_to_Supplier_for_Credit__c')));
							cl.Quantity_Returned__c += qtyRetdsc;
							contractLinesToUpdate.put(cl.Id, cl);
						}
						if (KSE.isFieldChanging('Quantity_Returned_to_Supplier__c',POL, Trigger.oldMap)){
							qtyRetds = KSE.addQuantitytoField(pol.Quantity_Returned_to_Supplier__c,0) - KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Returned_to_Supplier__c')));
							cl.Purchased_Quantity__c = KSE.addQuantitytoField(cl.Purchased_Quantity__c, 0) - KSE.addQuantitytoField(pol.Quantity_Returned_to_Supplier__c,0) + KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Returned_to_Supplier__c')));
							cl.Quantity_Returned__c += qtyRetds;
							contractLinesToUpdate.put(cl.Id, cl);
						}
						//Update contract's Qty Received when receipt happens on PO
						if (KSE.isFieldChanging('Quantity_Received__c',POL, Trigger.oldMap)){
							qtyRecd = KSE.addQuantitytoField(pol.Quantity_Received__c,0) - KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Received__c')));
							cl.Quantity_Received__c += qtyRecd;
							contractLinesToUpdate.put(cl.Id, cl);
						}
						//Update Contract's Qty Still Due when still due changes on PO
						if (KSE.isFieldChanging('Quantity_Still_Due__c',POL, Trigger.oldMap)){
							qtyStillDue = KSE.addQuantitytoField(pol.Quantity_Still_Due__c,0) - KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Still_Due__c')));
							cl.Quantity_Still_Due__c+= qtyStillDue;
							contractLinesToUpdate.put(cl.Id, cl);
						}
						//Update Contract's purchased qty when PO is cancelled
						if ((KSE.isFieldChanging('Status__c',POL, Trigger.oldMap)) && (POL.Status__c == 'Cancelled')){
							cl.Purchased_Quantity__c -= KSE.addQuantitytoField(POL.Order_Quantity__c, 0);
							contractLinesToUpdate.put(cl.Id, cl);
						}
						//Update Contract's purchased qty when PO is short closed
						if ((KSE.isFieldChanging('Status__c',POL, Trigger.oldMap)) && (POL.Status__c == 'Closed') && (POL.Short_Close__c)){
							cl.Purchased_Quantity__c -= KSE.addQuantityToField(0,Double.valueOf(Trigger.oldMap.get( POL.id ).get('Quantity_Still_Due__c')));
							contractLinesToUpdate.put(cl.Id, cl);
						}
                	}	
            }
    	}
    	}
    	}
    	DML.updateAsUser(contractLinesToUpdate.values());
    	if (shouldPObeSaved)
    		DML.updateAsUser(poMap.values()); //PTM-94 Updating PO header approval status value changes, if any
    	
    	KSE.setAlreadyfired();
    }
    
    

    if (Trigger.isDelete) {
        Set<Id>PoLineIdSet = new Set<Id>();
                    
        for(Purchase_Order_Line__c POL:Trigger.Old){        
            if (POL.Quantity_Received__c != null && POL.Quantity_Received__c != 0) {  
                POL.addError(Label.Cannot_delete_a_line_with_quantity_received);
            } else {
                PoLineIdSet.add( POL.Id );  
            }
        }
        // SKID stuff should be moved to SKIDService ?
        SOQLUtil skidSoql = new SOQLUtil ( 'SKID__c' ) ;
        skidSoql.addField ('Id') ;
        string poSupply = SKIDService.SKID_TYPE_PO_SUPPLY;
        skidSoql.setWhereClause ( 'Type__c = :poSupply and Purchase_Order_Line__c in :PoLineIdSet') ;
        //delete [select ID from SKID__c where Type__c = :SKIDService.SKID_TYPE_PO_SUPPLY and Purchase_Order_Line__c in :PoLineIdSet];
        DML.deleteAsUser(Database.query ( skidSoql.getQuery() ));
    }
   
       if (trigger.isBefore && Trigger.isUpdate ){
        
           //Call Service Method for UOM Conversion
            itemsForUpdate = PurchaseOrderLineService.setUOM(items,itemsForUpdate);
    
            
	           if( itemsForUpdate.values().size() > 0 )
	           		DML.updateAsUser(itemsForUpdate.values());
       }

    /**
     *  allow for the POL to be an indirect , in which case we will not create skids
    */
    if ( Trigger.isAfter ){// after trigger
        // Create skids only for items with indirect=false
        map<id,Purchase_Order_Line__c> newMap = new map<id,Purchase_Order_Line__c>();
        map<id,Purchase_Order_Line__c> oldMap = new map<id,Purchase_Order_Line__c>();
        map<id,Purchase_Order_Line__c> cancelOldMap = new map<id,Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> RollupList = new List<Purchase_Order_Line__c>();
        
        if ( trigger.isInsert || trigger.isUpdate || trigger.isUnDelete){
            for(Purchase_Order_Line__c POL:Trigger.New) {
                if( trigger.isInsert ){
                    RollupList.add(POL);
                    if(POL.Indirect__c==false){
                        newmap.put(POL.id, POL);
                    }
                }else if( trigger.isUpdate ){
                    Purchase_Order_Line__c oldPOL = Trigger.oldMap.get(POL.ID);
                    if ( POL.Item__c != null && (POL.Item__c != oldPOL.Item__c || POL.Order_Quantity__c!= oldPOL.Order_Quantity__c ) 
                            && POL.Status__c != 'Closed' && POL.Status__c != 'Cancelled' ) {
                        RollupList.add(POL);   
                    }
                    
                    if(POL.Indirect__c==false){
                        if(POL.Status__c == 'Cancelled'){
                            cancelOldmap.put(POL.id, trigger.oldmap.get(POL.id));
                        }else{
                            newmap.put(POL.id, POL);
                            oldmap.put(POL.id, trigger.oldmap.get(POL.id));
                        }
                    }         
                    if( POL.Status__c == 'Closed' ){ //KNDY-1594
                    	cancelOldmap.put(POL.id, trigger.oldmap.get(POL.id));
                    }
                             
                }else if(trigger.isUnDelete){
                        RollupList.add(POL);
                }
            }
        }
        
        if(trigger.isInsert){
            SKIDService.insertSkids(newMap, SKIDService.SKID_TYPE_PO_SUPPLY, new map<Id,Id>());
        }
        
        if(trigger.isUpdate){
            
            if(cancelOldmap.size() > 0){
                //delete skids with type POL Cancelled
                SKIDService.deleteSkids(cancelOldmap, SKIDService.SKID_TYPE_PO_SUPPLY);
            }
            if(oldmap.size() > 0){
                SKIDService.updateSkids(oldMap, newMap, SKIDService.SKID_TYPE_PO_SUPPLY, new map<Id,Id>());
            }
        }
        
        // Roll up Summary (Calculate POL Total Weight) KNDY-1091
        if ( trigger.isInsert || trigger.isUpdate || trigger.isUnDelete ) {
            if(RollupList.Size() > 0){
                
                //RollUpSummaryUtility.rollUpTrigger( fieldDefinitions, RollupList, 'Purchase_Order_Line__c', 'Purchase_Order__c', 'Purchase_Order__c', '');            
            }      
        } // End of trigger.isInsert || trigger.isUpdate || trigger.isUnDelete
        
        if( trigger.isDelete ) {  
             
                //RollUpSummaryUtility.rollUpTrigger( fieldDefinitions, trigger.old, 'Purchase_Order_Line__c', 'Purchase_Order__c', 'Purchase_Order__c', '');
             
        } // End of trigger.isDelete
    }  // 
        if(trigger.isBefore && trigger.isDelete){
           system.debug(logginglevel.error, 'before delete');
    	   purchaseOrderLineService.dropshipPOLDeleteValidation();  
    	   purchaseOrderLineService.approvedPOLDeleteValidation();
        }
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        	purchaseOrderLineService.defaultsFromSupplier();
        }
    
   /* if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate)
    	 	|| (trigger.isBefore && trigger.isDelete))
        	|| (trigger.isAfter && trigger.isUndelete)){
        
    	FinalizeService.validateLineFinalize();
        
	}*/
    
}