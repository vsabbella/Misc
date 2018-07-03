public with sharing class CustomerOutstandingBalanceService implements ICustomAction{
	
	public list<Object> executeAction(List<Customer__c> lSoldTos) {
		
		Id batchJobId = Process.info.getJobID();
		String allowanceAccrualType = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Name','Parent_Customer__c', 'Parent_Customer__r.Parent_Customer__c','Open_Sales_Orders__c','Uninvoiced_Shipments__c','Open_Credits__c',
			'Open_Invoices__c', 'Open_Invoices__c','Open_Invoices__c','Open_Past_Due__c','Days_Past_Due_Max__c','Average_Days_To_Pay_30__c'
		});
		
		soql.setWhereClause('Id in :lSoldTos and REcordType.Name = \'Sold To\'');
		
		//GET OPEN SOs that are not on credit hold
		SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Sales_Orders__r');
		childRel1.addFields(new set<string>{
			'ID','Backorder_Value__c','Sales_Tax__c'
		});
		childRel1.setWhereClause('Status__c = \'Open\' and Credit_Hold__c = false  And  (not Type__c Like \'RMA%\')');
		soql.addChildRelationship(childRel1);
		
		//GET Fulfillments (exclude allowance accrual), need a separate query to take care of sales fulfillments being invoiced or not. 
		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Fulfillments__r');
		childRel2.addFields(new set<string>{
			'ID','Fulfillment_Fully_Invoiced_2__c','Extended_Price__c','Status__c','Invoice_Ready__c','Price_Type__c'
		});
		childRel2.setWhereClause('Status__c = \'Complete\' and Invoice_Ready__c = true and Fulfillment_Fully_Invoiced_2__c = false and Type__c != :allowanceAccrualType');
		soql.addChildRelationship(childRel2);
		
		//CUSTOMER INVOICES (exclude allowance accrual)
		SOQLUtil.ChildRelationship childRel3 = new SOQLUtil.ChildRelationship(soql, 'Sold_To_Customer_Invoices__r');
		childRel3.addFields(new set<string>{
			'ID','Status__c','Days_to_Pay_30__c','Balance__c','Amount_past_due__c','Days_Past_Due__c','Invoice_Type__c',
			'Total_Sales_Tax__c'
		});
		childRel3.setWhereClause('((Status__c = \'Open\' AND Finalized__c = true) OR Days_to_Pay_30__c > 0) and Invoice_Type__c != :allowanceAccrualType');
		soql.addChildRelationship(childRel3);
		
		system.debug('SoldTo Query='+soql.getQuery());
		
		
		map<Id, Customer__c> mSoldTos = new map<id,Customer__c>((list<Customer__c>) Database.query(soql.getQuery()));
		set<id> salesFulfillments = new set<id>();
		set<id> parentCustomers = new set<id>();
		for(Customer__c soldTo : mSoldTos.values()) {
			
			if(!soldTo.Fulfillments__r.isEmpty()) {
				for(Fulfillment__c f : soldTo.Fulfillments__r) {
					if(f.Price_Type__c == 'Sales')
						salesFulfillments.add(f.id);
				}
			}
			if(soldTo.Parent_Customer__c != null)
				parentCustomers.add(soldTo.Parent_Customer__c);
			if(soldTo.Parent_Customer__r.Parent_Customer__c != null)
				parentCustomers.add(soldTo.Parent_Customer__r.Parent_Customer__c);
		}
		system.debug('salesFulfillments '+salesFulfillments);
		map<Id, Fulfillment__c> salesUnInvoicedFulfillments = new map<id,Fulfillment__c>();
		if(!salesFulfillments.isEmpty()) {
			soql = new SOQLUtil('Fulfillment__c', true); //enforceFLS=false, running in user mode
			soql.addFields(new set<string>{
				'Id'
			});
			soql.setWhereClause('Id in :salesFulfillments and ID not in (Select Fulfillment__c from Customer_Invoice_Sub_Line__c where Fulfillment__r.Type__c != :allowanceAccrualType and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c in(\'Open\',\'Closed\') )');
			salesUnInvoicedFulfillments = new map<id,Fulfillment__c>( (list<Fulfillment__c>)Database.query(soql.getQuery()));
		}
		system.debug('salesUnInvoicedFulfillments '+salesUnInvoicedFulfillments);
		
		//GET BILL TO AND CORP TIED TO SOLD TO
		map<Id, Customer__c> mParents = new map<Id,Customer__c>();
		map<Id, Customer__c> mCorps = new map<Id,Customer__c>();
		soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','RecordType.DeveloperName','Open_Credits__c','Open_Invoices__c','Open_Sales_Orders__c','Uninvoiced_Shipments__c','Open_Past_Due__c',
			'Average_Days_To_Pay_30__c','Days_Past_Due_Max__c','Batch_Job_ID__c'
		});
		soql.setWhereClause('ID in :parentCustomers and RecordType.DeveloperName in (\'Bill_To\',\'Corporate_Parent\')');
		SOQLUtil.ChildRelationship childRel4 = new SOQLUtil.ChildRelationship(soql, 'Bill_To_Customer_Invoices__r');
		childRel4.addFields(new set<string>{
			'ID','Status__c','Days_to_Pay_30__c','Balance__c','Amount_past_due__c','Days_Past_Due__c','Invoice_Type__c',
			'Total_Sales_Tax__c'
		});
		childRel4.setWhereClause('((Status__c = \'Open\' AND Finalized__c = true) OR Days_to_Pay_30__c > 0) and Sold_To_Customer__c = null and Bill_To_Customer__c != null and Invoice_Type__c != :allowanceAccrualType');
		soql.addChildRelationship(childRel4);
		//KNDY-15808
		SOQLUtil.ChildRelationship childRel5 = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoices__r');
		childRel5.addFields(new set<string>{
			'ID','Status__c','Days_to_Pay_30__c','Balance__c','Amount_past_due__c','Days_Past_Due__c','Invoice_Type__c',
			'Total_Sales_Tax__c'
		});
		childRel5.setWhereClause('((Status__c = \'Open\' AND Finalized__c = true) OR Days_to_Pay_30__c > 0) and Sold_To_Customer__c = null and Bill_To_Customer__c = null and Invoice_Type__c != :allowanceAccrualType' );
		soql.addChildRelationship(childRel5);
		for(Customer__c c : Database.query(soql.getQuery())) {
			
			// STORE BATCHJOBID|SUM|COUNT 
			//implies updating records within the same btach, so need to append values
			if(c.Batch_Job_ID__c != null && c.Batch_Job_ID__c == String.valueOf(batchJobID)) {
				mParents.put(c.Id, c);
				
			} else { //implies calcualting it from scratch so reset the values. 
				c.Open_Credits__c = 0.0;
				c.Open_Invoices__c = 0.0;
				c.Open_Sales_Orders__c = 0.0;
				c.Uninvoiced_Shipments__c = 0.0;
				c.Open_Past_Due__c = 0.0;
				c.Average_Days_To_Pay_30__c = 0.0;
				c.Days_Past_Due_Max__c = 0.0;
				c.Batch_Job_ID__c = batchJobId;
				mParents.put(c.Id, c);
		
			}
		}
		system.debug('parentCustomers=='+parentCustomers);
		system.debug('mParents '+mParents);
		//WE HAVE ALL OUR DATA NOW. TIME TO CALCUALTE ALL TH FIELDS
		list<Customer__c> customersToUpdate = new list<Customer__c>();
		
		
		for(Customer__c soldToC : mSoldTos.values()) {
			integer count_dtp = 0;
			decimal totalDTP = 0;
			soldToC.Open_Credits__c = 0.0;
			soldToC.Open_Invoices__c = 0.0;
			soldToC.Open_Sales_Orders__c = 0.0;
			soldToC.Uninvoiced_Shipments__c = 0.0;
			soldToC.Open_Past_Due__c = 0.0;
			soldToC.Average_Days_To_Pay_30__c = 0.0;
			soldToC.Days_Past_Due_Max__c = 0.0;
			soldToC.Batch_Job_ID__c = batchJobId;
			
			//1. BACKORDERED SOs - CREDIT HOLDS
			for(Sales_Order__c so : soldToC.Sales_Orders__r) {
				soldToC.Open_Sales_Orders__c = KSE.addQuantityToField(soldToC.Open_Sales_Orders__c, so.Backorder_Value__c);
			}
			
			//2. UNINVOICED FULFILLMENTS
			for(Fulfillment__c f : soldToC.Fulfillments__r) {
				if(f.Price_Type__c == 'Recurring' || salesUnInvoicedFulfillments.containsKey(f.Id))
					soldToC.Uninvoiced_Shipments__c = KSE.addQuantityToField(soldToC.Uninvoiced_Shipments__c, f.Extended_Price__c);
			}
			
			//3. OPEN CUSTOMER INVOICES
			system.debug('soldToC.Customer_Invoices__r '+soldToC.Sold_To_Customer_Invoices__r);
			for(Customer_Invoice__c ci : soldToC.Sold_To_Customer_Invoices__r) {
				system.debug('ci '+ci.Balance__c);
				 if (ci.Balance__c < 0 ) { //4. OPEN CREDIT MEMOS
                    if ( ci.Status__c == 'Open') {
						soldToC.Open_Credits__c = KSE.addQuantityToField(soldToC.Open_Credits__c, ci.Balance__c);
                    }                                           
                }
                else if (ci.Balance__c > 0){
            		if ( ci.Status__c == 'Open') {
                		//KNDY-16823
						soldToC.Open_Invoices__c = KSE.addQuantityToField(soldToC.Open_Invoices__c,ci.Balance__c);
						system.debug('***Open_Invoices__c***'+soldToC.Open_Invoices__c);
						soldToC.Open_Past_Due__c = KSE.addQuantityToField(soldToC.Open_Past_Due__c, ci.Amount_past_due__c);
            		}	
					
					// we must to consider open and closed to average past 30 days of DTP
					soldToC.Average_Days_To_Pay_30__c = KSE.addQuantityToField(soldToC.Average_Days_To_Pay_30__c, ci.Days_to_Pay_30__c );
					totalDTP = soldToC.Average_Days_To_Pay_30__c;
					if ( ci.Days_to_Pay_30__c > 0 ) count_dtp++;
                    
                    soldToC.Days_Past_Due_Max__c = math.max(KSE.addQuantityToField(ci.Days_Past_Due__c, 0), soldToC.Days_Past_Due_Max__c); //KNDY-2114
                }
			}
			
			 if ( count_dtp > 0 ) { // KNDY-714
        		soldToC.Average_Days_To_Pay_30__c = Math.floor(soldToC.Average_Days_To_Pay_30__c / count_dtp ); 
        		// STORE BATCHJOBID 
        		soldToC.Batch_Job_ID__c = batchJobId;
            }
            
            //ADD TO BILL TO
            system.debug('soldToC '+soldToC);
            Customer__c billTo = mParents.get(soldToC.Parent_Customer__c);
            system.debug('billTo '+billTo);
            
            Decimal mOpenCredits = 0;
        	Decimal mOpenInvoices = 0; 
        	Decimal mOpenPastDue = 0;
            if(billTo != null) {
	        	billTo.Open_Sales_Orders__c = KSE.addQuantityToField(soldToC.Open_Sales_Orders__c, billTo.Open_Sales_Orders__c);
	        	billTo.Uninvoiced_Shipments__c = KSE.addQuantityToField(soldToC.Uninvoiced_Shipments__c, billTo.Uninvoiced_Shipments__c);
	        	billTo.Open_Credits__c = KSE.addQuantityToField(billTo.Open_Credits__c, soldToC.Open_Credits__c);
	        	billTo.Open_Invoices__c = KSE.addQuantityToField(billTo.Open_Invoices__c, soldToC.Open_Invoices__c);
	        	billTo.Open_Past_Due__c = KSE.addQuantityToField(billTo.Open_Past_Due__c, soldToC.Open_Past_Due__c);
	        	billTo.Days_Past_Due_Max__c = math.max(KSE.addQuantityToField(billTo.Days_Past_Due_Max__c, 0), soldToC.Days_Past_Due_Max__c); //KNDY-2114
	        	
	        	
	        	//THIS TAKES CARE OF MANUAL CIs THAT WONT HAVE BILL TO
	        	if(!CustomerService.manualCICustomers.contains(billTo.Id) && !billTo.Bill_To_Customer_Invoices__r.isEmpty()) {
	        		system.debug('calculating manual CIs');
	        		for(Customer_invoice__c ci : billTo.Bill_To_Customer_Invoices__r) {
	        			CustomerService.manualCICustomers.add(billTo.Id);
	        			
	        			if (ci.Balance__c < 0 ) { //4. OPEN CREDIT MEMOS
		                    if ( ci.Status__c == 'Open') {
								billTo.Open_Credits__c = KSE.addQuantityToField(billTo.Open_Credits__c, ci.Balance__c);
								mOpenCredits = KSE.addQuantityToField(mOpenCredits, ci.Balance__c);
		                    }                                           
		                }
		                else if (ci.Balance__c > 0){
		            		if ( ci.Status__c == 'Open') {
		                		Decimal balanceDue = ci.Balance__c;
								billTo.Open_Invoices__c = KSE.addQuantityToField(billTo.Open_Invoices__c, balanceDue);
								mOpenInvoices = KSE.addQuantityToField(mOpenInvoices,balanceDue);
								billTo.Open_Past_Due__c = KSE.addQuantityToField(billTo.Open_Past_Due__c, ci.Amount_past_due__c);
								mOpenPastDue = KSE.addQuantityToField(mOpenPastDue,ci.Amount_past_due__c);
		            		}	
							
							// we must to consider open and closed to average past 30 days of DTP
							totalDTP = KSE.addQuantityToField(totalDTP, ci.Days_to_Pay_30__c );
							if ( ci.Days_to_Pay_30__c > 0 ) count_dtp++;
		                    
		                    billTo.Days_Past_Due_Max__c = math.max(KSE.addQuantityToField(ci.Days_Past_Due__c, 0), billTo.Days_Past_Due_Max__c); //KNDY-2114
		                }
	        			
	        		}
	        	}
	        	
	        	
	        	CustomerService.runningAverage billToAverage;
	        	if(CustomerService.runningAverages.containskey(billTo.Id))
	        		billToAverage = CustomerService.runningAverages.get(billTo.Id);
	        	else
	        		billToAverage = new CustomerService.RunningAverage(billTo.ID);
	        		
	        	billTo.Average_Days_To_Pay_30__c = billToAverage.calculateNewAverage(totalDTP, count_dtp);
	        	
	        	CustomerService.runningAverages.put(billTo.Id,billToAverage);
	        	
	        	billTo.Batch_Job_ID__c = batchJOBID;
            	
            }
        	 
            	
            
            Customer__c corpParent = mParents.get(soldToC.Parent_Customer__r.Parent_Customer__c);
            if(corpParent != null) {
            	
        	
	        	corpParent.Open_Sales_Orders__c = KSE.addQuantityToField(corpParent.Open_Sales_Orders__c, soldToC.Open_Sales_Orders__c);
	        	corpParent.Uninvoiced_Shipments__c = KSE.addQuantityToField(corpParent.Uninvoiced_Shipments__c, soldToC.Uninvoiced_Shipments__c);
	        	corpParent.Open_Credits__c = KSE.addQuantityToField(corpParent.Open_Credits__c, soldToC.Open_Credits__c) +mOpenCredits;
	        	corpParent.Open_Invoices__c = KSE.addQuantityToField(corpParent.Open_Invoices__c, soldToC.Open_Invoices__c) + mOpenInvoices;
	        	corpParent.Open_Past_Due__c = KSE.addQuantityToField(corpParent.Open_Past_Due__c, soldToC.Open_Past_Due__c) +mOpenPastDue;
	        	corpParent.Days_Past_Due_Max__c = math.max(KSE.addQuantityToField(corpParent.Days_Past_Due_Max__c, 0), soldToC.Days_Past_Due_Max__c); //KNDY-2114
	        	
	        	//KNDY-15808
	        	//THIS TAKES CARE OF MANUAL CIs THAT WONT HAVE BILL TO and Sold To
	        	if(!CustomerService.manualCICorpCustomers.contains(corpParent.Id) && !corpParent.Customer_Invoices__r.isEmpty()) {
	        		system.debug('calculating manual CIs corps' + corpParent.Customer_Invoices__r);
	        		for(Customer_invoice__c ci : corpParent.Customer_Invoices__r) {
	        			CustomerService.manualCICorpCustomers.add(corpParent.Id);
	        			
	        			if (ci.Balance__c < 0 ) { //4. OPEN CREDIT MEMOS
		                    if ( ci.Status__c == 'Open') {
								corpParent.Open_Credits__c = KSE.addQuantityToField(corpParent.Open_Credits__c, ci.Balance__c);
								mOpenCredits = KSE.addQuantityToField(mOpenCredits, ci.Balance__c);
		                    }                                           
		                }
		                else if (ci.Balance__c > 0){
		            		if ( ci.Status__c == 'Open') {
		                		Decimal balanceDue = ci.Balance__c;
								corpParent.Open_Invoices__c = KSE.addQuantityToField(corpParent.Open_Invoices__c, balanceDue);
								mOpenInvoices = KSE.addQuantityToField(mOpenInvoices,balanceDue);
								corpParent.Open_Past_Due__c = KSE.addQuantityToField(corpParent.Open_Past_Due__c, ci.Amount_past_due__c);
								mOpenPastDue = KSE.addQuantityToField(mOpenPastDue,ci.Amount_past_due__c);
		            		}	
							
							// we must to consider open and closed to average past 30 days of DTP
							totalDTP = KSE.addQuantityToField(totalDTP, ci.Days_to_Pay_30__c );
							if ( ci.Days_to_Pay_30__c > 0 ) count_dtp++;
		                    
		                    corpParent.Days_Past_Due_Max__c = math.max(KSE.addQuantityToField(ci.Days_Past_Due__c, 0), corpParent.Days_Past_Due_Max__c); //KNDY-2114
		                }
	        			
	        		}
	        	}
	        	system.debug('manualCICorpCustomers=='+CustomerService.manualCICorpCustomers);
	        	
	        	CustomerService.runningAverage corpAverage;
	        	if(CustomerService.runningAverages.containskey(corpParent.Id))
	        		corpAverage = CustomerService.runningAverages.get(corpParent.Id);
	        	else
	        		corpAverage = new CustomerService.RunningAverage(corpParent.ID);
	        		
	        	corpParent.Average_Days_To_Pay_30__c = corpAverage.calculateNewAverage(totalDTP, count_dtp);
	        	
	        	CustomerService.runningAverages.put(corpParent.Id,corpAverage);
	        	
	        	
	        	corpParent.Batch_Job_ID__c = batchJOBID;
            }
        	
            
            system.debug('CustomerService.runningAverages '+CustomerService.runningAverages);
            system.debug('CustomerService.manualCICustomers '+CustomerService.manualCICustomers);
			customersToUpdate.add(soldToC);
		}
		
		if(!customersToUpdate.isEmpty()) {
			customersToUpdate.addAll(mParents.values());
		
			DML.updateAsSystem(customersToUpdate);
		}
		
		
		
		
			
		
		
		
		return lSoldTos;
	}
    
}