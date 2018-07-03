public with sharing class AggregateConsolidateInvoicing implements InvoiceGroupingRuleService.ConsolidatedInvoice{	
	/*
	The aggregate service will aggregate multiple fulfillments belonging to the same order line to a single invoice line
	 (provided that the rate across the fulfillments are the same, may need to consider other factors like allowance, tax..etc)
	*/
	public void consolidate(map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> containerToFulfillments, map<String,Customer_Invoice__c> mCIs, map<String,Customer_Invoice_Line__c> mCILs,
									 Id batchJobId, map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap, map<Id,Fulfillment__c> mFulfillmentsToUpdate) {
		  dateTime timeNow  = system.now(); //KNDY-11232
		  for(InvoiceGroupingRuleContainer container : containerToFulfillments.keySet()) {
				for(Fulfillment__c f : containerToFulfillments.get(container)) {
					system.debug(logginglevel.error,'container '+container);
					system.debug(logginglevel.error,'fulfillment date '+ f.Fulfillment_Date__c.date());
					Date recurrenceStartDate = container.recurrenceStartDate;
					Integer dateOn = recurrenceStartDate == null ? null : recurrenceStartDate.day();
					Date dateInvoiced = container.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? system.today() : FrequencyService.closestFutureBillingDate(f.Fulfillment_Date__c.date(), recurrenceStartDate, container.periodicity, 
																																										  dateOn, container.everyPeriodicity);
					system.debug(' dateInvoiced after nextBilling '+dateInvoiced);
					
					if(dateInvoiced > system.today()) { //KNDY-9322 If the rule dictates the fulfillmnet should be invoiced in the future, then do not invoice it now!
						if(InvoiceGroupingRuleService.mapFlErrorMsgWrapper.containskey(f.Id)){
							InvoiceGroupingRuleService.mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add('Fulfillment can only be invoiced on '+dateInvoiced);
						}else{
							InvoiceGroupingRuleService.mapFlErrorMsgWrapper.put(f.Id,new InvoiceGroupingRuleService.FlErrMsgWrapper(f.Id, 
																			  new list<string>{'Fulfillment can only be invoiced on '+dateInvoiced}, 
																			  f.name));
						}
						continue;
					}
					
					system.debug('String.valueOf(container.hashCode()) '+String.valueOf(container.hashCode()));
					String headerKey = String.valueOf(container.hashCode())+'|'+(batchJobId == null ? String.valueOf(timeNow) : batchJobId) +'|'+ dateInvoiced;
					system.debug('headerKey '+headerKey);
					Customer_Invoice__c ci;
					//1. create the header
					if(mCIs.containsKey(headerKey)) {
	   					ci = mCIs.get(headerKey);
	   					ci.Transaction_Date__c = ci.Transaction_Date__c < f.Fulfillment_Date__c ? f.Fulfillment_Date__c : ci.Transaction_Date__c; //KNDY-8625 Transaction Date should default from fulfillment date (when multiple, choose most recent)
					}
	   				else
	   				{
	   					ci = new Customer_Invoice__c(Source_Key__c = headerKey, Company__c = container.companyId, Status__c = 'Open',
	   														// if grouped by SO or SO Type then invoice type is copied from SO.Type else we give it a new type.	 
	   													    Invoice_Type__c = (container.salesOrderId != null || container.salesOrderType != null) ? f.Sales_Order_Line__r.Sales_Order__r.Type__c : 'Consolidated Invoice',
										 				    Currency__c =container.transactionCurrencyID,
										 				    Payment_Term__c = container.paymentTerm, 
										 				    Bill_To_Customer__c = container.billToId,
										 				    Matches_To_Grouping_Rule__c = container.groupingRule, 
															Batch_Job_ID__c = batchJobId, //KNDY-8546
															Planned_Invoice_Date__c = DateTime.newInstance(dateInvoiced, Time.newInstance(0,0,0,0)),  //KNDY-8636
											                Date_Invoiced__c = system.now(),
											                Transaction_Date__c = f.Fulfillment_Date__c);////KNDY-8625 Transaction Date should default from fulfillment date (when multiple, choose most recent)
						system.debug('inside aggregate, container: '+container);
						 if(container.ShipmentId != null) {
							ci.Shipment__c = container.shipmentId;
							ci.Sold_To_Customer__c = f.Shipment_Line__r.Shipment__r.Customer__r.Parent_Customer__c;//KNDY-12094
							//if SO is null, then set up the lookup
							//then keep checking if the SO lookup's value is the same, the fine, but if not then reset to null.
							if(ci.Sales_Order__c == null)//KNDY-12094 
								ci.Sales_Order__c = f.Shipment_Line__r.Sales_Order_Line__r.Sales_Order__c;
							ci.Sales_Order__c = ci.Sales_Order__c ==  f.Shipment_Line__r.Sales_Order_Line__r.Sales_Order__c ? ci.Sales_Order__c : null;
						}if(container.salesOrderId != null) {
							ci.Sales_Order__c = container.salesOrderId;
							ci.Sold_To_Customer__c = f.Sales_Order_Line__r.Sales_Order__r.Customer__c;//KNDY-12094
						}if(container.agreementId != null) {
							ci.Agreement__c  = container.agreementId;
						}
						system.debug('ci: '+ci);
						mCIs.put(headerKey,ci);
	   				}
	   				//2. create the lines
	   				String lineKey = headerKey + '|' + f.Sales_Order_Line__c + '|' +f.Unit_Price__c;
	   				system.debug('lineKey '+lineKey);
	   				if(mCILs.containsKey(lineKey)) {
	   					Customer_Invoice_Line__c cil = mCILs.get(lineKey);
	   					cil.Quantity_Shipped__c += f.Quantity__c;
						cil.Discount_Amount__c = (cil.Quantity_Shipped__c * (cil.Unit_Price__c - (f.Sales_Order_Line__r.Off_Invoice_Rate__c == null ? 0 : f.Sales_Order_Line__r.Off_Invoice_Rate__c)) * ((f.Sales_Order_Line__r.Discount_Percent__c == null ? 0 : f.Sales_Order_Line__r.Discount_Percent__c) / 100)).setScale(2);
						mCILs.put(lineKey,cil);
	   				}else {
	   					mCILs.put(lineKey, new Customer_Invoice_Line__c(Customer_Invoice__r = new Customer_Invoice__c(Source_Key__c = headerKey),
					 												  Product__c = f.Product__c,
                                                                      Product_Reference__c = f.Sales_Order_Line__r.Product_Reference__c,
					 												  Quantity_Shipped__c = f.Quantity__c, 
																  	  Unit_Price__c = f.Unit_Price__c,
																  	  Sales_Order__c = f.Sales_Order_Line__r.Sales_Order__c, 
																  	  Sales_Order_Line__c = f.Sales_Order_Line__c, 
																  	  Company__c = container.companyId,
																  	  Shipment__c = container.shipmentId != null ? container.shipmentId : null, //show shipment line only if grouped by Shipment. Coz if it is grouped BY SO, then one CIL can come come from multiple shipments
																  	  Shipment_Line__c = container.shipmentId != null ? f.Shipment_Line__c : null, 
																  	  Agreement_Line__c = container.agreementId != null ? f.Agreement_Line__c  : null,
																  	  Agreement__c = container.agreementId != null ? container.agreementId  : null,
																  	  Discount_Percent__c = f.Sales_Order_Line__r.Discount_Percent__c,
																  	  Off_Invoice_Rate__c =f.Sales_Order_Line__r.Off_Invoice_Rate__c,
																  	  BillBack_Rate__c = f.Sales_Order_Line__r.BillBack_Rate__c,
																  	  List_Price__c = f.Sales_Order_Line__r.List_Price__c, 
																  	  Line_Type__c = f.Sales_Order_Line__r.Line_Type__c,
																  	  Rate_Basis__c = f.Rate_Basis__c,
																  	  Price_Type__c = f.Price_Type__c,
																  	  Pricing_UOM__c = f.Pricing_UOM__c,
																  	  Description__c = f.Sales_Order_Line__r.Description__c, //KNDY-12324
																  	  Start_Date__c = f.Sales_Order_Line__r.Start_Date__c,
																  	  End_Date__c = f.Sales_Order_Line__r.End_Date__c,   
																  	  Source_Key__c = lineKey,
								 									  Discount_Amount__c = (f.Quantity__c * (f.Unit_Price__c - (f.Sales_Order_Line__r.Off_Invoice_Rate__c == null ? 0 : f.Sales_Order_Line__r.Off_Invoice_Rate__c)) * ((f.Sales_Order_Line__r.Discount_Percent__c == null ? 0 : f.Sales_Order_Line__r.Discount_Percent__c) / 100)).setScale(2)
                                                                       ));
	   				}
	   				
	   				//3. create the map
	   				mFulfillmentMap.put(f.Id+'|'+lineKey, new Customer_Invoice_Sub_Line__c (Fulfillment__c = f.id, Customer_Invoice_Line__r = new Customer_Invoice_Line__c(Source_Key__c = lineKey)));
					 	
	   				
	   				
					
				}//END OF FULFIL
		  }
	}

}