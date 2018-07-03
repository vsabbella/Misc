public with sharing class CustomerInvoiceVoidCancelService extends VoidCancelService{
	public list<Customer_Invoice__c> lCIs;
    public Map<Id,list<Customer_Invoice_Sub_Line__c>> mapCISubline= new Map<Id,list<Customer_Invoice_Sub_Line__c>>();
    public Map<id,list<Customer_Invoice_Sub_Line__c>> mapFulfilmentInvoiceSubline= new Map<id,list<Customer_Invoice_Sub_Line__c>> ();
     public  Map<id,list<Id>> mapCustInvoiceFulfilment= new Map<id,list<Id>> ();
    Public set<id> solWithoutFulfilments = new Set<id>();
    
   
    
	public boolean calledFromUI;
	public CustomerInvoiceVoidCancelService(list<Customer_Invoice__c> sObjects)
	{
		super(sObjects);
		lCIs = new list<Customer_Invoice__c>();  
    
		calledFromUI = false;
	}
	
	//AR-75
	public CustomerInvoiceVoidCancelService(list<Customer_Invoice__c> sObjects, boolean calledFromUI) // This constructor would be called from the UI controller and will set the boolena to true. 
	{
		super(sObjects);
		lCIs = new list<Customer_Invoice__c>();
     
		this.calledFromUI = calledFromUI;
	}    
	
    public CustomerInvoiceVoidCancelService(){
    }

  

	 public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
	 	Map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new Map<Id, VoidCancelService.VoidCancelDetail>();
	 	set<String> ciTypes_NotVC = new set<String>{CustomerInvoiceService.TYPE_SETTLEMENT, CustomerInvoiceService.TYPE_CHARGEBACK,CustomerInvoiceService.CM_OVERPAYMENT, CustomerInvoiceService.CM_PREPAYMENT};
	 	
	 	set<Id> sourceDocIds = new set<id>();
	 	
	 	for(sObject sObj : sObjRecs) {
	 		sourceDocIds.add(sObj.id);
	 	}
	 		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Status__c','Invoice_Type__c','Finalized__c','Balance__c','Void__c','Sales_Order__c','Total_Amount__c'
		});
		soql.setWhereClause('id in :sourceDocIds');
		SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');
		childRel1.addFields(new set<string>{
			'id','Shipment__c','Sales_Order_Line__c'
		});
		soql.addChildRelationship(childRel1);
		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipt_Lines__r');
		childRel2.addFields(new set<string>{
			'id'
		});
		childRel2.setWhereClause('Finalized__c = true');
		soql.addChildRelationship(childRel2);
		
		/*KNDY-13995
		SOQLUtil.ChildRelationship childRel3 = new SOQLUtil.ChildRelationship(soql, 'Customer_Credit_Memos_Applied__r');
		childRel3.addFields(new set<string>{
			'ID'
		});
		childRel3.setWhereClause('Finalized__c = true');
		soql.addChildRelationship(childRel3);*/
		SOQLUtil.ChildRelationship childRel4 = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
		childRel4.addFields(new set<string>{
			'id','name'
		});
		childRel4.setWhereClause('status__c = \'Active\' and Has_Exceptions__c != true');
		soql.addChildRelationship(childRel4);
		lCIs = Database.query(soql.getQuery());

	 	if(!lCIs.isEmpty())
	 	{
            	// create map for consolidated invoices
            	// KNDY-8545 
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Customer_Invoice_Sub_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Customer_Invoice_Line__r.Customer_Invoice__c','Customer_Invoice_Line__r.End_Date__c','Customer_Invoice_Line__r.Start_Date__c',
			'fulfillment__C','fulfillment__r.Type__C','fulfillment__r.start_date__c','fulfillment__r.Last_Bill_Date__c',
			'fulfillment__r.Pricing_UOM__c','fulfillment__r.Pricing_UOM__r.Recurrence__c','fulfillment__r.Pricing_UOM__r.Every__c', //PRICING UOM ON F
			'fulfillment__r.Billing_UOM__c','fulfillment__r.Billing_UOM__r.Recurrence__c','fulfillment__r.Billing_UOM__r.Every__c', 'fulfillment__r.Recurrence_Start_Date__c', //BILLING UOM ON F
			'Customer_Invoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Billing_UOM__c','Customer_Invoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Billing_UOM__r.Every__c', //BILLING UOM ON IGR
			'Customer_Invoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Use_Billing_Frequency_on_Fulfillment__c','Fulfillment__r.Price_Type__c',
			'Customer_Invoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Billing_UOM__r.Recurrence__c','Customer_Invoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Recurrence_Start_Date__c','Customer_Invoice_Line__r.Recurrence_Start_Date__c',
			
			'fulfillment__r.Fulfillment_date__c','Fulfillment__r.Invoice_Ahead__c','Fulfillment__r.Fulfillment_Fully_Invoiced_2__c'
		});
		String fpi = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;
		soql.setWhereClause(
			'Customer_Invoice_Line__r.Customer_Invoice__c in :sourceDocIds ' +
			'and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c !=\'Cancelled\' ' + 
			'and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c !=\'Void\' ' +
			'and Fulfillment__r.Price_Type__c = \'Recurring\' '
		);
		soql.setOrderByClause('Customer_Invoice_Line__r.End_Date__c desc');
		for( Customer_Invoice_Sub_Line__c csl: Database.query(soql.getQuery())) {
            if(mapCISubline.containsKey(csl.Customer_Invoice_Line__r.Customer_Invoice__c)){
		 		list<Customer_Invoice_Sub_Line__c> listSubline =  mapCISubline.get(csl.Customer_Invoice_Line__r.Customer_Invoice__c); 
		 		listSubline.add(csl);
		 		mapCISubline.put(csl.Customer_Invoice_Line__r.Customer_Invoice__c,listSubline);
		 	}else{
		 		mapCISubline.put(csl.Customer_Invoice_Line__r.Customer_Invoice__c,new list<Customer_Invoice_Sub_Line__c>{csl } );
		 	}
                                                     //| csl.Fulfillment__r.Start_date__C<>null || csl.Fulfillment__r.fulfillment_date_c<>null
            
                //prepare map of fulfilemnt and CISL mapFulfilmentInvoiceSubline                                                                                      
                if(mapFulfilmentInvoiceSubline.containsKey(csl.fulfillment__C)){
                    list<Customer_Invoice_Sub_Line__c> listSubline2 =  mapFulfilmentInvoiceSubline.get(csl.fulfillment__C); 
                    listSubline2.add(csl);
                    mapFulfilmentInvoiceSubline.put(csl.fulfillment__C,listSubline2);
                }else{
                    mapFulfilmentInvoiceSubline.put(csl.fulfillment__C,new list<Customer_Invoice_Sub_Line__c>{csl } );
                }                                      
            
           //prepareMap of CI and fulfilments
               if(mapCustInvoiceFulfilment.containsKey(csl.Customer_Invoice_Line__r.Customer_Invoice__c)){
                    list<id> listCustInvoice =  mapCustInvoiceFulfilment.get(csl.Customer_Invoice_Line__r.Customer_Invoice__c); 
                    listCustInvoice.add(csl.fulfillment__C );
                    mapCustInvoiceFulfilment.put(csl.Customer_Invoice_Line__r.Customer_Invoice__c ,listCustInvoice);
                }else{
                    mapCustInvoiceFulfilment.put(csl.Customer_Invoice_Line__r.Customer_Invoice__c ,new list<ID>{csl.fulfillment__C } );
                }                                      
                                             
                                                     
          } 
          
          system.debug('mapCISubline '+mapCISubline);
          system.debug('mapFulfilmentInvoiceSubline '+mapFulfilmentInvoiceSubline);
          system.debug('mapCustInvoiceFulfilment '+mapCustInvoiceFulfilment);
            
            
            
	 		for(Customer_Invoice__c ci : lCIs)
	 		{  	
	 			VoidCancelDetail iVCD = new VoidCancelDetail();
	            iVCD.recordId = ci.Id;
	            iVCD.recordName = ci.Name;
	            iVCD.isVoidable = true;
	            iVCD.isCancellable = true;
	            iVCD.voidMessages = new List<string>();
	            iVCD.cancelMessages = new List<string>();
	            list<Accounting_Entry__c> aelist = ci.Accounting_Entries__r;
	            
	            if(ci.Void__c)
	            	iVCD.cancelMessages.add( ci.Name + ': Cannot Cancel, this Customer Invoice is already Void');
	            if(ci.Status__c == 'Cancelled')
	            	iVCD.voidMessages.add(ci.Name + ': Cannot Void, this Customer Invoice is already Cancelled');
	            if(!(aelist.size()> 0))
					iVCD.voidMessages.add(ci.Name + ': Cannot Void, this Customer Invoice does not have Accounting Entries generated or has Exceptions');
				if(ci.Customer_Receipt_Lines__r.size() > 0  && ci.Balance__c != ci.Total_Amount__c) //|| ci.Customer_Credit_Memos_Applied__r.size() >0 KNDY-13995
				{
					iVCD.cancelMessages.add(ci.Name + ': Cannot Cancel this Customer Invoice as payment have already been made against them. please Void/Cancel the downstream Customer Receipt(s)');
					iVCD.voidMessages.add(ci.Name + ': Cannot Void this Customer Invoice as payment have already been made against them. Please Void/Cancel the downstream Customer Receipt(s)');
				}
				if(!ci.Finalized__c)
				{
					//iVCD.cancelMessages.add(ci.Name + ': Cannot Cancel this Customer Invoice as it has not been finalized yet');AR-143 should be able to cancel Unfinalized CI
				    iVCD.voidMessages.add(ci.Name + ': Cannot Void this Customer Invoice as it has not been finalized yet');
					
				}
                //KNDY-8545
                if(!mapCISubline.isEmpty()){
	                if(mapCISubline.containskey(ci.id)){// for consolidated invoices 
		 			list<Customer_Invoice_Sub_Line__c> listSubline = mapCISubline.get(ci.id);
	                   Customer_Invoice_Sub_Line__c subline =mapCISubline.get(ci.id)[0];
	                   system.debug('subline '+subline);
	                   system.debug('subline.Fulfillment__r.Last_Bill_Date__c '+subline.Fulfillment__r.Last_Bill_Date__c);
	                   system.debug('subline.Customer_Invoice_Line__r.Start_Date__c '+subline.Customer_Invoice_Line__r.Start_Date__c);
	                   system.debug('subline.Customer_Invoice_Line__r.End_Date__c '+subline.Customer_Invoice_Line__r.End_Date__c);
	                   boolean invoiceAhead = subline.Fulfillment__r.Invoice_Ahead__c == null ? false : subline.Fulfillment__r.Invoice_Ahead__c;
	                   boolean doDatesMatch = false;
	                   boolean fullyInvoiced = subLine.Fulfillment__r.Fulfillment_Fully_Invoiced_2__c;
	                   if(fullyInvoiced)
	                   			doDatesMatch = false;
	                   else if(invoiceAhead) {
	                   	
	                   	doDatesMatch = subline.Fulfillment__r.Last_Bill_Date__c.date() > subline.Customer_Invoice_Line__r.Start_Date__c.date();
	                   } else{
	                   		doDatesMatch = subline.Fulfillment__r.Last_Bill_Date__c.date() > subline.Customer_Invoice_Line__r.End_Date__c.date();
	                   }
	                   	
	                   
	                   if(subline.Fulfillment__r.Price_Type__c == 'Recurring' &&  doDatesMatch){ // cannot cancel/void invoices which are not current.
	                   		 iVCD.voidMessages.add(ci.Name + ': Cannot Void this Customer Invoice. New invoices have been generated after this invoice. Please cancel/void the latest invoice first.');
	                         iVCD.cancelMessages.add(ci.Name + ': Cannot Cancel this Customer Invoice. New invoices have been generated after this invoice. Please cancel/void the latest invoice first.');
	                 	
	                      }
	                   
		 			}
                }
                
                
				if(ciTypes_NotVC.contains(ci.Invoice_Type__c) && !SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(ci.Invoice_Type__c) && calledFromUI) //IF CI is with Chargeback, settlement , PP, OP and we try to V/C from UI throw error
				{
					iVCD.cancelMessages.add(ci.Name + ': Cannot Cancel '+ci.Invoice_Type__c+'  Customer Invoice.');
					iVCD.voidMessages.add(ci.Name + ': Cannot Void '+ci.Invoice_Type__c+' Customer Invoice.');
				}
				if(iVCD.voidMessages.size() > 0) {
				iVCD.isVoidable = false;
				}
				if(iVCD.cancelMessages.size() > 0) {
					iVCD.isCancellable = false;
				}
				
				
				mBusinessVoidCancelDetails.put(ci.Id, iVCD);
				
	 		}
	 	}
	 	
	 	
	 	return mBusinessVoidCancelDetails; 
	 
	 }
	 
	 public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
    	Savepoint sp = Database.setSavepoint();
    	try {
    		
    		businessVoidCancel(lCIs);
    		AllowanceRuleService.clearUniqueKeys(lCIs);
    		List<String> messages = new List<String>{'Successfully Voided!'};
    		for(sObject sObj : sObjRecs)
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
    	}
    	catch(Exception ex){
        if(calledFromUI)    Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.VOIDDOC));
            }
            Database.rollback(sp);  
            return mResponses;
        }
    	return mResponses;
	 }
	 
	 public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
    	try {
    		
    		businessVoidCancel(lCIs);
    		AllowanceRuleService.clearUniqueKeys(lCIs);
    		List<String> messages = new List<String>{'Successfully Cancelled!'};
	    	for(sObject sObj : sObjRecs)
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
    	}
    	catch(Exception ex){
        if(calledFromUI)     Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.CANCELDOC));
            }
            Database.rollback(sp);  
            return mResponses;
        }
    	return mResponses;
	 }
	 
	 public void businessVoidCancel(list<Customer_Invoice__c> lCIs)
	 {
	 	Map<Id, fulfillment__c>fulfillmentIdsForVOIDCANCEL = new Map<Id, fulfillment__c>();
	 	list<Shipment__c> shipmentsToUpdate = new list<Shipment__c>();
	 	list<Sales_Order__c> salesOrdersToUpdate = new list<Sales_Order__c>();
	 	list<Sales_Order_Line__c> solToUpdate = new list<Sales_Order_Line__c>();
	 	system.debug('lCIs: '+lCIs);
       Map<Id, Fulfillment__c> mFulfillments = new Map<Id, Fulfillment__c>();
        system.debug('lCIs 204' + lCIs);
	 	for(Customer_Invoice__c ci : lCIs)
	 	{ 
           
         system.debug('here at 318');
         //KNDY-8545  - set fulfilement last bill date to previous billing date 
         if(mapCISubline.containskey(ci.id)){// for consolidated invoices 
              
             for(Id fulfilId: mapCustInvoiceFulfilment.get(ci.id)){
             		if(!fulfillmentIdsForVOIDCANCEL.containsKey(fulfilId)) {
             			list<Customer_Invoice_Sub_Line__c>  cislListforFulfilmnt=  mapFulfilmentInvoiceSubline.get(fulfilId);
              
	       	            boolean invoiceAhead = cislListforFulfilmnt[0].Fulfillment__r.Invoice_Ahead__c == null ? false : cislListforFulfilmnt[0].Fulfillment__r.Invoice_Ahead__c;
		                integer counter = cislListforFulfilmnt.size() -1;
		                Customer_Invoice_Sub_Line__c CISubL = cislListforFulfilmnt.get(counter);
		                
		                string chargingCycle = CISubl.Fulfillment__r.Pricing_UOM__r.Recurrence__c;
		                integer everyCount = Integer.valueOf(CISubl.Fulfillment__r.Pricing_UOM__r.Every__c);
		                //integer invoiceOn = CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Use_Billing_Frequency_on_Fulfillment__c ?
		                	//			    (CISubl.Fulfillment__r.Recurrence_Start_Date != null ? CISubl.Fulfillment__r.Recurrence_Start_Date.day() : CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Recurrence_Start_Date__c.day()) :
		                				    
		                integer invoiceOn;
		                if(CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Use_Billing_Frequency_on_Fulfillment__c)	 {
		                	if(CISubl.Fulfillment__r.Recurrence_Start_Date__c != null) 
		                		invoiceOn = Integer.valueOf(CISubl.Fulfillment__r.Recurrence_Start_Date__c.day());
		                	else if(CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Recurrence_Start_Date__c != null)
		                		invoiceOn = Integer.valueOf(CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Recurrence_Start_Date__c.day());
		                	else
		                		invoiceOn = Integer.valueOf(CISubl.Fulfillment__r.Start_date__c.day());
		                	 	
		                }else {
		                	if(CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Recurrence_Start_Date__c != null)
		                		invoiceOn = Integer.valueOf(CISubl.Customer_INvoice_Line__r.Customer_Invoice__r.Matches_To_Grouping_Rule__r.Recurrence_Start_Date__c.day());
		                	else
		                		invoiceOn = Integer.valueOf(CISubl.Fulfillment__r.Start_date__c.day());
		                }			     
		                
		                Date previousBillDate;
		                system.debug('invoiceAhead '+invoiceAhead);
		                if(invoiceAhead) {
		                	system.debug('invoice ahead cil sd '+CISubL.Customer_Invoice_Line__r.Start_Date__c.date());
		                	
		                	previousBillDate = FrequencyService.previousBillingDate(chargingCycle, CISubL.Customer_Invoice_Line__r.Start_Date__c.date(), invoiceOn, everyCount);
		                	system.debug('previousBillDate '+previousBillDate);
		                	if(previousBillDate <= CISubL.Fulfillment__r.Start_Date__c.date()){
		                		if(CISubL.Fulfillment__r.Start_Date__c.date() == CISubL.Customer_Invoice_Line__r.Start_Date__c.date()){
		                			previousBillDate = null;
		                		}else{
		                			previousBillDate = CISubL.Fulfillment__r.Start_Date__c.date();
		                		}
		                	}else if(previousBillDate<CISubL.Fulfillment__r.Recurrence_Start_Date__c.date()){
		                		previousBillDate = CISubL.Fulfillment__r.Start_Date__c.date();
		                	}
		                }else{
		                	 previousBillDate = CISubL.Customer_Invoice_Line__r.Start_Date__c.date();
		                	 system.debug('previousBillDate '+previousBillDate);
		                	 if(previousBillDate == CISubL.Fulfillment__r.Start_Date__c.date())
		                		previousBillDate = null;
	                 }
	                	                fulfillMent__C ful = new fulfillMent__C (id=fulfilId,last_bill_Date__C= previousBillDate == null ? null : DateTime.newInstance(previousBillDate,Time.newInstance(0,0,0,0)));
		                system.debug('ful '+ful);
	               fulfillmentIdsForVOIDCANCEL.put(ful.Id, ful);
             	}
                
               
             }
         }
     
         
	 	}

	 	system.debug(LoggingLevel.Error, 'salesOrdersToUpdate: '+salesOrdersToUpdate);
	 	system.debug(LoggingLevel.Error, 'shipmentsToUpdate: '+shipmentsToUpdate);
	 	system.debug(LoggingLevel.Error, 'solToUpdate: '+solToUpdate);
	 	system.debug(LoggingLevel.Error, 'fulfillmentIdsForVOIDCANCEL.values(): '+fulfillmentIdsForVOIDCANCEL.values());
		if(!salesOrdersToUpdate.isEmpty())
	 		DML.updateAsUser(salesOrdersToUpdate);
	 	if(!shipmentsToUpdate.isEmpty())
	 		DML.updateAsUser(shipmentsToUpdate);
	 	if(!solToUpdate.isEmpty())
	 		DML.updateAsUser(solToUpdate);
      	if(!fulfillmentIdsForVOIDCANCEL.isEmpty())
      		DML.checkUpsertAsUser(fulfillmentIdsForVOIDCANCEL.values()); upsert fulfillmentIdsForVOIDCANCEL.values();
	 }

}