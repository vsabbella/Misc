public with sharing class AllowanceAccrualConsolidateInvoicing implements InvoiceGroupingRuleService.ConsolidatedInvoice{	//KNDY-14713

	public void consolidate(map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> containerToFulfillments, map<String,Customer_Invoice__c> mCIs, map<String,Customer_Invoice_Line__c> mCILs,
									 Id batchJobId, map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap, map<Id,Fulfillment__c> mFulfillmentsToUpdate) {
		  dateTime timeNow  = system.now(); //KNDY-11232
		  system.debug(LoggingLevel.Error, 'inside allowance accrual, containerToFulfillments '+containerToFulfillments);
		  
		  for(InvoiceGroupingRuleContainer container : containerToFulfillments.keySet()) {
				system.debug(LoggingLevel.Error, 'container: '+container);

				Fulfillment__c f = new Fulfillment__c();
				system.debug(LoggingLevel.Error,'containerToFulfillments.get(container): ' + containerToFulfillments.get(container));
				f = containerToFulfillments.get(container)[0];
					
					system.debug(LoggingLevel.Error,'fulfillment f '+ f);

					Date recurrenceStartDate = container.recurrenceStartDate;
					Integer dateOn = recurrenceStartDate == null ? null : recurrenceStartDate.day();
					Date dateInvoiced = container.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? system.today() : FrequencyService.closestFutureBillingDate(f.Fulfillment_Date__c.date(), recurrenceStartDate, container.periodicity, 
																																										  dateOn, container.everyPeriodicity);

					system.debug(LoggingLevel.Error,'String.valueOf(container.hashCode()) '+String.valueOf(container.hashCode()));
					String headerKey = String.valueOf(container.hashCode())+'|'+(batchJobId == null ? String.valueOf(timeNow) : batchJobId) +'|'+ dateInvoiced;
					system.debug(LoggingLevel.Error,'ci headerKey '+headerKey);
					Customer_Invoice__c ci;
					
					//1. create the header
	   				ci = new Customer_Invoice__c(Source_Key__c = headerKey, Company__c = container.companyId, Status__c = 'Open',
	   														// if grouped by SO or SO Type then invoice type is copied from SO.Type else we give it a new type.	 
	   													    Invoice_Type__c = f.Type__c,
										 				    Currency__c =container.transactionCurrencyID,
										 				    Payment_Term__c = container.paymentTerm, 
										 				    Bill_To_Customer__c = container.billToId,
										 				    Matches_To_Grouping_Rule__c = container.groupingRule, 
															Batch_Job_ID__c = batchJobId, //KNDY-8546
															Planned_Invoice_Date__c = DateTime.newInstance(dateInvoiced, Time.newInstance(0,0,0,0)),  //KNDY-8636
											                Date_Invoiced__c = system.now(),
											                Transaction_Date__c = f.Fulfillment_Date__c);////KNDY-8625 Transaction Date should default from fulfillment date (when multiple, choose most recent)
					//Assumption: Allowance Accrual Fulfilments will not have a shipment line lookup
					//so not handling that case here
					if(container.salesOrderId != null) {
							ci.Sales_Order__c = container.salesOrderId;
							ci.Sold_To_Customer__c = null;//KNDY-12094 KNDY-16332
					}if(container.agreementId != null) {
							ci.Agreement__c  = container.agreementId;
					}
					system.debug(LoggingLevel.Error,'ci: '+ci);
					mCIs.put(headerKey,ci);
	   				
	   				
	   				//2. create the lines
	   				String lineKey = headerKey + '|' + f.Sales_Order_Line__c + '|' +f.Unit_Price__c;
	   				system.debug(LoggingLevel.Error,'ci lineKey '+lineKey);
	   				
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
																  	  Allowance_Applied__c = f.Allowance_Applied__c,
																  	  Discount_Amount__c  = null,//KNDY-16310
																  	  Discount_Percent__c = null,//KNDY-16310
																  	  Off_Invoice_Rate__c =null,//KNDY-16310
																  	  Allowances__c = null, //KNDY-16310
																  	  Freight_Allowance__c = null//KNDY-16310
																  	  ));
	   			
	   				
	   				//3. create the map
	   				mFulfillmentMap.put(f.Id+'|'+lineKey, new Customer_Invoice_Sub_Line__c (Fulfillment__c = f.id, Customer_Invoice_Line__r = new Customer_Invoice_Line__c(Source_Key__c = lineKey)));
					 	
	   				
	   				
					
				//}//END OF FULFIL
		  }
		  
	}

}