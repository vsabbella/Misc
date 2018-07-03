public with sharing class PTPCleanup implements Database.Batchable<sObject>, Database.Stateful{

	public Set<Id> polIds;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public Id parentId;

    private static Set<String> matchingStatuses = new Set<String>{'Draft','Approved','Paid','Closed'};

    public void errMsg() {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, Label.Button_Not_Available + '. ' + Label.Please_use_the_PTP_Cleanup_button_on_Purchase_Order_Line);
        ApexPages.addMessage(myMsg);
    }
    
	public PTPCleanup(Set<Id> polIds) {
		this.polIds = polIds;
	}
	
	public PTPCleanup(Id parentId) {
		this.parentId = parentId;
	}
	
	public PTPCleanup(ApexPages.StandardController sc) {
		String objectType = sc.getRecord().getsObjectType().getDescribe().getLocalName();
		parentId = sc.getId();
		polIds = new Set<Id>();
		
		if(objectType == 'Purchase_Order_Line__c') {
			polIds.add(sc.getId());
		}
	}
	
	public void startBatch() {
		PTPCleanup cleanup;

		if(polIds == null || polIds.isEmpty()) {
			cleanup = new PTPCleanup(parentId);
		}
		else {
			cleanup = new PTPCleanup(polIds);
		}
        ID jobId = Database.executeBatch(cleanup, 25); 
        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.CONFIRM, 'Clean up batch has started.  You will be notified by email when complete!'));
	}
	
	public pageReference goBack() {
		return new pageReference('/'+parentId);
	}

	
	public Database.QueryLocator start(Database.BatchableContext BC){
    	string query = 'SELECT Id, Name FROM Purchase_Order_Line__c WHERE Status__c NOT IN (\'Void\',\'Cancelled\')'; //FOR ALL OPEN PO LINES
    	if(polIds == null || polIds.isEmpty()) {
    		query = 'SELECT Id, Name FROM Purchase_Order_Line__c WHERE Company__c = :parentId AND Status__c NOT IN (\'Void\',\'Cancelled\')'; //FOR COMPANY SPECIFIC PO LINES
    	}
    	else{
    		query =	'SELECT Id, Name FROM Purchase_Order_Line__c  WHERE Id IN :polIds'; //FOR A SPECIFIC SET OF PO LINES
    	}
    	return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Purchase_Order_Line__c> scope){
    	Savepoint sp = Database.setSavepoint(); 
        try{
        	Set<Id> pols = new Set<Id>();
        	for(Purchase_Order_Line__c pl : scope) {
        		pols.add(pl.Id);
        	}
        	doReset(pols, true);
        }
        catch(Exception e) {
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }

	public static void doReset(Set<Id> polIds, Boolean doCleanup) {
		List<Purchase_Order_Line__c> POLines = new List<Purchase_Order_Line__c>();
		if(polIds != null && polIds.size() > 0) {
		
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        //V2
        SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Quantity_Received__c','Order_Quantity__c'}); 
        soql.setWhereClause('Status__c IN (\'Open\',\'Closed\') AND Id IN :polIds ');      
        SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Supplier_Invoice_Lines__r');
        //KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
        childRel1.addFields(new set<string>{
            'Id','Invoice_Quantity__c','Unit_Price__c','Quantity_Received__c','Supplier_Invoice__r.Status__c',
            'Supplier_Invoice__r.Invoice_Type__c','Matched__c'
        });
        soql.addChildRelationship(childRel1);
        SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
        childRel2.addFields(new set<string>{
            'Id','Item__c','Company__c','Facility__c','Quantity_Received__c','Uninvoiced_Quantity__c','Status__c',
            'Matched__c','Invoiced__c'
        });
        childRel2.setWhereClause('Receiving_Document__r.Type__c IN (\'Advanced Shipment Notice\',\'Purchase Order Receipt\')');
        soql.addChildRelationship(childRel2);
        POLines = Database.query(soql.getQuery());

		}
		else {
		

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            //V2
            SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Quantity_Received__c','Order_Quantity__c'
            });
            soql.setWhereClause('Status__c IN (\'Open\',\'Closed\')');
            SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Supplier_Invoice_Lines__r');
            //KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
            childRel1.addFields(new set<string>{
                'Id','Invoice_Quantity__c','Unit_Price__c','Quantity_Received__c','Supplier_Invoice__r.Status__c',
                'Supplier_Invoice__r.Invoice_Type__c','Matched__c'
            });
            soql.addChildRelationship(childRel1); 
            SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
            childRel2.addFields(new set<string>{
                'Id','Item__c','Company__c','Facility__c','Quantity_Received__c','Uninvoiced_Quantity__c','Status__c',
                'Matched__c','Invoiced__c'
            });
            childRel2.setWhereClause('Receiving_Document__r.Type__c IN (\'Advanced Shipment Notice\',\'Purchase Order Receipt\')');
            soql.addChildRelationship(childRel2);
            POLines = Database.query(soql.getQuery());



		}
		
									 		   
		Map<Id, Decimal> POQuantityReceived = new Map<Id, Decimal>();
		Map<Id, Decimal> POLQuantityInvoiced = new Map<Id, Decimal>();//PTP-620, PTP-402
		Map<Id, Decimal> POQuantityCredited = new Map<Id, Decimal>();
		Map<Id, Decimal> POAmountCredited = new Map<Id, Decimal>();
		
		Set<Id> poLineIds = new Set<Id>();
		Set<Id> siLineIds = new Set<Id>();
		
		
		List<Supplier_Invoice_Line__c> siLinesToUpdate = new List<Supplier_Invoice_Line__c>();
		List<Receipt_Line__c> rlLinesToUpdate = new List<Receipt_Line__c>();
		
		// KNDY-8356 Rematching Info for POLs without any Draft SIs
		Map<Id, List<Receipt_Line__c>> mapPOLIdMatchedReceiptLines = new    Map<Id, List<Receipt_Line__c>>();
		Map<Id, List<Receipt_Line__c>> mapPOLIdUnmatchedReceiptLines = new  Map<Id, List<Receipt_Line__c>>();
		Map<Id, Decimal> mapPOLIdSILQtyToRematch = new  Map<Id, Decimal>();
		Set<Id> polIdsWithDraftSIs = new Set<Id>();
		
		
		//default PO Quantities to 0
		for(Purchase_Order_Line__c pl : POLines) {
			POQuantityReceived.put(pl.Id,0);
			POLQuantityInvoiced.put(pl.Id, 0);
			POQuantityCredited.put(pl.Id,0);
			POAmountCredited.put(pl.Id,0);
		}
		
		Set<Id> itemSet = new Set<Id>();
		Set<Id> facilitySet = new Set<Id>();
		for(Purchase_Order_Line__c pl : POLines) {
			for(Receipt_Line__c rl : pl.Receipt_Lines__r) {
				itemSet.add(rl.Item__c);
				facilitySet.add(rl.Facility__c);
			}
		}
		
		// KNDY-8356 collect all POLs with Draft SIs, 
		// as inspect method will re-match Receipt Lines iff Draft SIs exist
		for(Purchase_Order_Line__c pl : POLines) {
			for(Supplier_Invoice_Line__c sil : pl.Supplier_Invoice_Lines__r) {
				if (sil.Supplier_Invoice__r.Status__c =='Draft'){
					polIdsWithDraftSIs.add(pl.Id);
				}
			}
		}
		
		for(Purchase_Order_Line__c pl : POLines) {
			Decimal SILqtytoReMatch = 0; // KNDY-8356
			poLineIds.add(pl.Id);
			for(Receipt_Line__c rl : pl.Receipt_Lines__r) {//SUM Open and Closed Receipt Lines for PO Line Quantity Received
				if(rl.Status__c != 'Void' && rl.Status__c != 'Cancelled') {
					if(rl.Quantity_Received__c == null) {
						rl.Quantity_Received__c = 0;
					}
					POQuantityReceived.put(pl.Id,POQuantityReceived.get(pl.Id) + rl.Quantity_Received__c);
					
					if (rl.Matched__c == true && rl.Invoiced__c == true) { //KNDY-8356
						rl.Uninvoiced_Quantity__c = 0;
					}
					
					// for POLs without Draft SIs, any Matched SIL quantities and RL quantities need be cleaned up
					// as inspect job will not process them
					if (!polIdsWithDraftSIs.contains(pl.Id)){
						if (rl.Matched__c == true && rl.Invoiced__c == true) {
							if (!mapPOLIdMatchedReceiptLines.containsKey(pl.id)){
								mapPOLIdMatchedReceiptLines.put(pl.Id, new List<Receipt_Line__c>());
							}
							mapPOLIdMatchedReceiptLines.get(pl.Id).add(rl);
						}
						else{
							if (!mapPOLIdUnmatchedReceiptLines.containsKey(pl.id)){
								mapPOLIdUnmatchedReceiptLines.put(pl.Id, new List<Receipt_Line__c>());
							}
							mapPOLIdUnmatchedReceiptLines.get(pl.Id).add(rl);
						}
					}
					else if (rl.Matched__c == false || rl.Invoiced__c == false){   // POL has Draft SIs                            
						rl.Uninvoiced_Quantity__c = rl.Quantity_Received__c;//reset Uninvoiced Quantity on Receipt Line to rerun Matching logic
						rl.Matched__c = false;
					}
					rlLinesToUpdate.add(rl);
				}
			}

			pl.Quantity_Received__c = POQuantityReceived.get(pl.Id);//assign true Received Quantity on PO Line
			//pl.Quantity_Uninvoiced__c = pl.Order_Quantity__c; //PTP-620 PTP-402
			
			for(Supplier_Invoice_Line__c sil : pl.Supplier_Invoice_Lines__r) {//SUM Open and Closed Supplier Invoice Lines for PO Line Quantity Uninvoiced
				if(sil.Supplier_Invoice__r.Status__c != 'Void' && sil.Supplier_Invoice__r.Status__c != 'Cancelled') {
					//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
					if(sil.Invoice_Quantity__c * sil.Unit_Price__c < 0){
                        if(sil.Invoice_Quantity__c < 0) {
                            POQuantityCredited.put(pl.Id,POQuantityCredited.get(pl.Id) + sil.Invoice_Quantity__c);
	            			}
	            			POAmountCredited.put(pl.Id,POAmountCredited.get(pl.Id) + (sil.Invoice_Quantity__c * sil.Unit_Price__c));                    
            			}
            			else { //PTP-620 PTP-402
            				POLQuantityInvoiced.put(pl.Id, POLQuantityInvoiced.get(pl.Id) + sil.Invoice_Quantity__c);
            			}
            			
					// Incomplete, Draft, Approved, Paid, Closed
					if(sil.Supplier_Invoice__r.Status__c == 'Incomplete' || matchingStatuses.contains(sil.Supplier_Invoice__r.Status__c)) {
						if (sil.Supplier_Invoice__r.Status__c != 'Approved' && sil.Supplier_Invoice__r.Status__c != 'Closed'  && sil.Supplier_Invoice__r.Status__c != 'Paid'){
							sil.Quantity_Received__c = 0;//reset Quantity Received on Receipt Line to rerun Matching logic
							sil.Matched__c = false;
						}
						else if (sil.Supplier_Invoice__r.Invoice_Type__c == 'Invoice'){ // KNDY-8356
							SILqtytoReMatch += sil.Invoice_Quantity__c;
							sil.Matched__c = true;
							if (sil.Quantity_Received__c != sil.Invoice_Quantity__c)  {// messed up approved sil
								sil.Quantity_Received__c = sil.Invoice_Quantity__c ; 
							}
						}
						
						if(matchingStatuses.contains(sil.Supplier_Invoice__r.Status__c)) { //only rerun matching for Invoices in Draft, Approved, Paid, Closed Statuses
							siLineIds.add(sil.Id);
						}
						siLinesToUpdate.add(sil);
					}
				}
			}
			mapPOLIdSILQtyToRematch.put(pl.Id, SILqtytoReMatch);// KNDY-8356
			//pl.Quantity_Uninvoiced__c -= POLQuantityInvoiced.get(pl.Id);//assign true Uninvoiced Quantity on PO Line
			pl.Quantity_Credited__c = POQuantityCredited.get(pl.Id);//assign true Quantity Credited on PO Line
			pl.Amount_Credited__c = POAmountCredited.get(pl.Id);//assign true Amount Credited on PO Line	
		}
		
		// KNDY-8356 for POLs without any Draft SIs, clean up RL Uninvoiced_Qty if messed up
		// Rls are already in list for update
		for(Purchase_Order_Line__c pl : POLines) {
			if ( polIdsWithDraftSIs.contains(pl.Id)){
				continue;
			}
			List<Receipt_Line__c> matchedReceiptLines = new List<Receipt_Line__c>();
			if (mapPOLIdMatchedReceiptLines.containsKey(pl.Id)){
				matchedReceiptLines = mapPOLIdMatchedReceiptLines.get(pl.Id);
			}
			List<Receipt_Line__c> unmatchedReceiptLines = new List<Receipt_Line__c>();
			if (mapPOLIdUnmatchedReceiptLines.containsKey(pl.Id)){
				unmatchedReceiptLines = mapPOLIdUnmatchedReceiptLines.get(pl.Id);
			}
			
			Decimal SILqtytoReMatch = mapPOLIdSILQtyToRematch.get(pl.Id);
			system.debug(LoggingLevel.Error, '>>> pre SILqtytoReMatch: ' + SILqtytoReMatch);
			for (Receipt_Line__c rl : matchedReceiptLines){
				if (SILqtytoReMatch > 0 ){
					if (SILqtytoReMatch == rl.Quantity_Received__c){
						rl.Uninvoiced_Quantity__c = 0;
						SILqtytoReMatch = 0;
					}
					else if (SILqtytoReMatch > rl.Quantity_Received__c){
						rl.Uninvoiced_Quantity__c = 0;
						SILqtytoReMatch -= rl.Quantity_Received__c;
					}
					else{
						rl.Uninvoiced_Quantity__c =  rl.Quantity_Received__c - SILqtytoReMatch;
						rl.Matched__c = false;
						rl.Invoiced__c = false;
						SILqtytoReMatch = 0;
					}
				}
				else{
					rl.Uninvoiced_Quantity__c = rl.Quantity_Received__c;
					rl.Matched__c = false;
					rl.Invoiced__c = false;
				}
			}
			for (Receipt_Line__c rl : unmatchedReceiptLines){
				if (SILqtytoReMatch <= 0){
					rl.Uninvoiced_Quantity__c = rl.Quantity_Received__c; // unmatched receipt line
					rl.Matched__c = false;
					rl.Invoiced__c = false;
				}
				else{
					if ( SILqtytoReMatch == rl.Quantity_Received__c){
						rl.Uninvoiced_Quantity__c = 0;
						rl.Invoiced__c = true; //Invoiced in full = true 
						rl.Matched__c = true; 
						SILqtytoReMatch = 0;
					}
					else if ( SILqtytoReMatch < rl.Quantity_Received__c){
						rl.Uninvoiced_Quantity__c = rl.Quantity_Received__c - SILqtytoReMatch;
						rl.Invoiced__c = false;
						rl.Matched__c = false;
						SILqtytoReMatch = 0; 
					}
					else{ //  SILqtytoReMatch will be reset to +ve 
						rl.Uninvoiced_Quantity__c = 0;
						rl.Invoiced__c = true;
						rl.Matched__c = true; 
						SILqtytoReMatch -= rl.Quantity_Received__c ; 
					}
				}
			}
			system.debug(LoggingLevel.Error, '>>> post SILqtytoReMatch: ' + SILqtytoReMatch);
		}

		DML.updateAsSystem(POLines);
		system.debug(LoggingLevel.Error, '>>> rlLinesToUpdate: ' + rlLinesToUpdate);
		DML.updateAsSystem(rlLinesToUpdate);
		system.debug(LoggingLevel.Error, '>>> siLinesToUpdate: ' + siLinesToUpdate);		
		DML.updateAsSystem(siLinesToUpdate);
		
		// KNDY-8356 Receipt Lines will be matched iff Draft SIs exist on a POL
		if(doCleanup && polIdsWithDraftSIs.size() > 0) {
			doCleanup(polIdsWithDraftSIs, siLineIds); //rerun Matching Logic without having to go through the entire inspect batch processes
		}
	}
	
	public static void doCleanup(Set<Id> poLineIds, Set<Id> siLineIds) {
		SchemaUtil util = SchemaUtil.getInstance();
		Set<String> additionalFields = new set<string>{'Id','Name','CreatedById','Supplier_Invoice__r.Name'};
		additionalFields.addAll(util.getAllCustomFieldsFromObject('','Supplier_Invoice_Line__c'));
    	additionalFields.addAll(util.getAllCustomFieldsFromObject('Item__r.','Item__c'));
    	additionalFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Class__r.','Class__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Supplier_Invoice__r.','Supplier_Invoice__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.','Purchase_Order__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.','Purchase_Order__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.FOB_Term__r.','FOB_Terms__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.','Purchase_Order_Line__c'));
		
		additionalFields.remove('has_exceptions__c');
		additionalFields.remove('exceptions_count__c');
		additionalFields.remove('supplier_invoice__r.has_exceptions__c');
		additionalFields.remove('supplier_invoice__r.exceptions_count__c');
		additionalFields.remove('supplier_invoice__r.line_exceptions_count__c');
		
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c');
	    soql.addFields('Supplier_Invoice_Line');
	    soql.addFields(additionalFields);
	    soql.setWhereClause(' Supplier_Invoice__r.Hold__c = false AND Id IN :siLineIds ');
		
		Map<Id, Supplier_Invoice_Line__c> supplierInvoiceLines = new Map<Id, Supplier_Invoice_Line__c>();
        supplierInvoiceLines = new Map<Id, Supplier_Invoice_Line__c>((List<Supplier_Invoice_Line__c>) Database.query(soql.getQuery()));
        /*supplierInvoiceLines = new Map<Id, Supplier_Invoice_Line__c>((List<Supplier_Invoice_Line__c>) database.query(util.generateQueryFromFieldSet('Supplier_Invoice_Line__c',
																			                        new set<string>{'Supplier_Invoice_Line'},
																			                        additionalFields,
																			                        ' Supplier_Invoice__r.Hold__c = false AND Id IN :siLineIds '))) ;*/  
        // KNDY-9637
        Map<Id, List<Supplier_Invoice_Line__c>> mapPOLIdSILines = new Map<Id, List<Supplier_Invoice_Line__c>>();
        Map<Id, List<Receipt_Line__c>> mapPOLIdReceiptLines = new Map<Id, List<Receipt_Line__c>>();
        List<Purchase_Order_Line__c> purchaseOrderLines = new List<Purchase_Order_Line__c>();
        SupplierInvoiceService.fetchRecordsByPOL(poLineIds, purchaseOrderLines, mapPOLIdSILines, mapPOLIdReceiptLines);

        List<Purchase_Order_Line__c> twoWayPOLines = new List<Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> threeWayPOLines = new List<Purchase_Order_Line__c>();
          
        for(Purchase_Order_Line__c poLine : purchaseOrderLines) {
            if(poLine.Invoice_Matching__c == 'Two Way') {
              twoWayPOLines.add(poLine);
            }
            else {
              threeWayPOLines.add(poLine);
            }
        }
        SupplierInvoiceService.twoWayMatching(twoWayPOLines,mapPOLIdSILines);
        SupplierInvoiceService.threeWayMatching(threeWayPOLines,supplierInvoiceLines.values(),mapPOLIdSILines, mapPOLIdReceiptLines);
          
        SupplierInvoiceService.finish(supplierInvoiceLines.values(), null);                              
	}
}