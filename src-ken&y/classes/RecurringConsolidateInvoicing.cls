public with sharing class RecurringConsolidateInvoicing implements InvoiceGroupingRuleService.ConsolidatedInvoice {
	
	/*
	1. If Subscribing monthly and billing quarterly ==> each bill per quarter will contain 3 lines (one for each month)
	2. last Bill Date on Fulfillment tells us the last time i created the subscription. 
	
	Example 1:  Fulfillment starts on 24th April 2015 to 24th april 2016 , on a monthly cycle. It is not invoiced ahead
	Rule implies invoice monthly starting on 10th 
	
	then on May 10th, invoice for 24th april to 10th may
	on June 10th, invoice for 10th may to 10th june
	on july 10th, invoice for 10th june to 10th july....and so on
	
	
	Example 2: Fulfillment starts on 24th April 2015 to 24th april 2016 , on a monthly cycle. It IS  invoiced ahead
	Rule implies invoice monthly starting on 10th 
	
	then on April 24th, invoice for 24th april to 10th may
	on may 10th, invoice for 10th may to 10th june
	on june 10th, invoice for 10th june to 10th july....and so on
	
	*/
	public void consolidate(map<InvoiceGroupingRuleContainer, list<Fulfillment__c>> containerToFulfillments, map<String, Customer_Invoice__c> mCIs, map<String, Customer_Invoice_Line__c> mCILs, Id batchJobId, map<String, Customer_Invoice_Sub_Line__c> mFulfillmentMap, map<Id, Fulfillment__c> mFulfillmentsToUpdate) {

		system.debug('Inside Recurring method' + containerToFulfillments);

		dateTime timeNow = system.now(); //KNDY-11232
		for (InvoiceGroupingRuleContainer container : containerToFulfillments.keySet()) {
			system.debug('container ' + container);
			for (Fulfillment__c f : containerToFulfillments.get(container)) {

				system.debug('f ' + f);

				//SET BILLING VARIABLES!!
				boolean invoiceAhead = f.Invoice_Ahead__c == null ? false : f.Invoice_Ahead__c;
				Date lastBillDate = f.Last_Bill_Date__c == null ? null : f.Last_Bill_Date__c.date();
				Date recurrenceStartDate = container.recurrenceStartDate;
				String billingCycle = container.periodicity;
				integer billingEveryCount = container.everyPeriodicity;
				integer invoiceOn = billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? (lastBillDate == null ? integer.valueOf(f.Start_date__c.day()) : lastBillDate.day()) : container.recurrenceStartDate.day();

				//SET CHARGING CYCLE VARIABLES!!!
				String chargingCycle = f.Price_Type__c == 'Sales' ? FrequencyService.FREQUENCY_PERIOD_IMMEDIATE : f.Pricing_UOM__r.Recurrence__c;
				Integer chargingEveryCount = chargingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? 1 : Integer.valueOf(f.Pricing_UOM__r.Every__c);

				Date headerStartDate = null;

				// starting point based on grouping rule
				if (billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE)
					headerStartDate = date.today(); else if (lastBillDate == null) {//FIRST BILLING CYCLE
					if (invoiceAhead) {
						headerStartDate = f.Start_Date__c.date();
					} else {
						headerStartDate = f.Start_Date__c < recurrenceStartDate ? recurrenceStartDate : FrequencyService.closestFutureBillingDate(f.Start_Date__c.date(), recurrenceStartDate, billingCycle, invoiceOn, billingEveryCount);
						headerStartDate = headerStartDate == f.Start_Date__c.date() ? FrequencyService.nextBillingDate(billingCycle, headerStartDate, invoiceON, billingEveryCount)
								: headerStartDate;
					}
				} else {

					if (invoiceAhead) {
						headerStartDate = FrequencyService.closestFutureBillingDate(lastBillDate, recurrenceStartDate, billingCycle, invoiceOn, billingEveryCount);
						if (headerStartDate == lastBillDate)
							headerStartDate = FrequencyService.nextBillingDate(billingCycle, headerStartDate, invoiceON, billingEveryCount);
					} else {
						headerStartDate = FrequencyService.closestFutureBillingDate(lastBillDate, recurrenceStartDate, billingCycle, invoiceOn, billingEveryCount);
						headerStartDate = FrequencyService.nextBillingDate(billingCycle, headerStartDate, invoiceON, billingEveryCount);
					}

				}//END headerStartDate


				//ending point based on grouping rule
				Date headerEndDate = null;
				//If we reached the last billing cycle of a fulfillment, then calculate the cycle accordingly
				if (f.End_Date__c != null && (f.End_Date__c.date() <= Date.today())) {
					headerEndDate = FrequencyService.nextBillingDate(billingCycle, f.End_Date__c.date(), invoiceON, billingEveryCount);
				} else {//now if we werent invoicing ahead, then the end date would be today's date
					if (!invoiceAhead)
						headerEndDate = system.now().date(); else { //else it is the next cycle.
						headerEndDate = FrequencyService.nextBillingDate(billingCycle, system.now().date(), invoiceON, billingEveryCount);
					}

				}
				system.debug('headerStartDate ' + headerStartDate);
				system.debug('headerEndDate ' + headerEndDate);

				//DateInvoiced gets updated as we progress through the iterations based on grouping->periodicity.
				Date dateInvoiced = headerStartDate;
				system.debug('dateInvoiced ' + dateInvoiced);

				Date lineStartDate = lastBillDate == null ? f.Start_Date__c.date()
						: invoiceAhead ? FrequencyService.nextBillingDate(chargingCycle, lastBillDate, lastBillDate.day(), chargingEveryCount) : lastBillDate;//KNDY-9945


				system.debug('lineStartDate ' + lineStartDate);
				if (lineStartDate > system.today()) {//go to next fulfillment if this fulfillment can only be invoiced in the future
					if (InvoiceGroupingRuleService.mapFlErrorMsgWrapper.containskey(f.Id)) {
						InvoiceGroupingRuleService.mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add('Fulfillment can only be invoiced on ' + lineStartDate);
					} else {
						InvoiceGroupingRuleService.mapFlErrorMsgWrapper.put(f.Id, new InvoiceGroupingRuleService.FlErrMsgWrapper(f.Id,
								new list<string>{
										'Fulfillment can only be invoiced on ' + lineStartDate
								},
								f.name));
					}
					continue;
				}

				//lineEndDate implies the end point for each invoice header. 
				Date lineEndDate = null;
				if (billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE)
					lineEndDate = date.today(); else if (lastBillDate == null) {
					if (recurrenceStartDate == null)
						lineEndDate = FrequencyService.nextBillingDate(chargingCycle, f.Start_Date__c.date(), f.Start_Date__c.date().day(), chargingEveryCount); else {
						lineEndDate = f.Start_Date__c < recurrenceStartDate ? recurrenceStartDate : FrequencyService.closestFutureBillingDate(f.Start_Date__c.date(), recurrenceStartDate, billingCycle, invoiceOn, billingEveryCount);
						if (lineEndDate == f.Start_Date__c.date())
							lineEndDate = FrequencyService.nextBillingDate(billingCycle, lineEndDate, lineEndDate.day(), billingEveryCount);
					}
				} else {
					if (!invoiceAhead) {
						lineEndDate = dateInvoiced;
					} else {
						lineEndDate = FrequencyService.nextBillingDate(billingCycle, dateInvoiced, invoiceOn, billingEveryCount);
					}
				}

				system.debug('lineEndDate ' + lineEndDate);


				//setting conditions for outer loop -- >used to create/maintain headers
				while ((dateInvoiced <= headerEndDate || billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE) && dateInvoiced <= Date.today()) {
					system.debug('dateInvoiced ' + dateInvoiced);
					String headerKey = String.valueOf(container.hashCode()) + '|' + (batchJobId == null ? String.valueOf(timeNow) : batchJobId) + '|' + dateInvoiced;
					boolean headerKeyExists = false; //KNDY-15125 to let us know if another invoice was created in previous run using the same headerKey
					system.debug('headerKey ' + headerKey);
					Customer_Invoice__c ci;
					if (!mCIs.containsKey(headerKey)) {
						ci = new Customer_Invoice__c(Source_Key__c = headerKey, Company__c = container.companyId, Status__c = 'Open',
								// if grouped by SO or SO Type then invoice type is copied from SO.Type else we give it a new type.
								Invoice_Type__c = (container.salesOrderId != null || container.salesOrderType != null) ? f.Sales_Order_Line__r.Sales_Order__r.Type__c : 'Consolidated Invoice',
								Currency__c = container.transactionCurrencyID,
								Payment_Term__c = container.paymentTerm,
								Bill_To_Customer__c = container.billToId,
								Matches_To_Grouping_Rule__c = container.groupingRule,
								Batch_Job_ID__c = batchJobId,//KNDY-8546
								Planned_Invoice_Date__c = DateTime.newInstance(dateInvoiced, Time.newInstance(0, 0, 0, 0)),  //KNDY-8636
								Date_Invoiced__c = system.now());
						if (container.ShipmentId != null) {
							ci.Shipment__c = container.shipmentId;
						}if (container.salesOrderId != null) {
							ci.Sales_Order__c = container.salesOrderId;
						}if (container.agreementId != null) {
							ci.Agreement__c = container.agreementId;
						}
						mCIs.put(headerKey, ci);
					} else {
						ci = mCIs.get(headerKey);
						ci.Planned_Invoice_Date__c = !invoiceAhead ? DateTime.newInstance(dateInvoiced, Time.newInstance(0, 0, 0, 0)) : ci.Planned_Invoice_Date__c ; //KNDY-12095
						headerKeyExists = true; //header exists!!
					}
					//2. Create Lines based on Last Bill Date.
					Date NextInvoiceLineStartDate = lineStartDate;


					Integer countLines = 0;
					DateTime CIL_StartDate, CIL_EndDate;

					do {

						//KNDY-9945
						if (lastBillDate == null) {// First invoice for this fulfillment, consider pro rate
							system.debug('running first charging cycle!!');
							CIL_StartDate = DateTime.newInstance(f.Start_Date__c.date(), Time.newInstance(0, 0, 0, 0)) ;

							if (billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE) {
								CIL_EndDate = DateTime.newInstance(FrequencyService.nextBillingDate(chargingCycle, f.Start_date__c.date(), f.Start_date__c.date().day(), chargingEveryCount), Time.newInstance(0, 0, 0, 0));
							}


							else {
								CIL_EndDate = DateTime.newInstance(FrequencyService.closestFutureBillingDate(f.Start_Date__c.date(), recurrenceStartDate, chargingCycle, invoiceOn, chargingEveryCount), Time.newInstance(0, 0, 0, 0));
								if (CIL_EndDate <= CIL_StartDate) {
									CIL_EndDate = DateTime.newInstance(FrequencyService.nextBillingDate(chargingCycle, CIL_EndDate.date(), invoiceOn, chargingEveryCount), Time.newInstance(0, 0, 0, 0));
								}
							}

						} else {
							CIL_StartDate = invoiceAhead ? DateTime.newInstance(NextInvoiceLineStartDate, Time.newInstance(0, 0, 0, 0)) : DateTime.newInstance(lastBillDate, Time.newInstance(0, 0, 0, 0));

							CIL_EndDate = DateTime.newInstance(FrequencyService.nextBillingDate(chargingCycle, (invoiceAhead ? CIL_startDate.date() : lastBillDate), invoiceOn, chargingEveryCount), Time.newInstance(0, 0, 0, 0));

						}

						//If this is the last invoice for the fulfillment, take care of prorate and dont overinvoice.
						CIL_EndDate = f.End_Date__c != null && CIL_EndDate > f.End_Date__c.date() ? DateTime.newInstance(f.End_Date__c.date(), Time.newInstance(0, 0, 0, 0)) : CIL_EndDate ;

						system.debug('CIL_StartDate ' + CIL_StartDate);
						system.debug('CIL_EndDate ' + CIL_EndDate);

						//if we are not invoicing ahead, then the end date of an invoice line should never be after dateInvoiced
						if (!invoiceAhead && (CIL_EndDate.date() > dateInvoiced)) {

							break;
						} else if (billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE) { //billing immediate, example of ad hoc without checking rule
							////if invoicing at end of cycle do not create line if its end date is future. EX: you are invoiceing today = 12/2/2016 and invoice line gets created for 11/27 to 12/3
							// then you cannot invoice for 12/3 as that is in future.
							if (!invoiceAhead && CIL_EndDate.date() > Date.today()) {
								break;
							}
							//if invoicing at start of cycle do not create line if its start date is future. EX: you are invoiceing today = 12/2/2016 and invoice line gets created for 12/3 to 12/10
							// then you cannot invoice for 12/3 as that is in future.
							else if (invoiceAhead && CIL_StartDate.date() > Date.today()) {
								break;
							}
						}

						if (lastBillDate == null)
							NextInvoiceLineStartDate = CIL_EndDate.date(); //after the first round, the invoice line's start date should be tied to pro rated date
						else
								NextInvoiceLineStartDate = invoiceAhead ? CIL_EndDate.date() : FrequencyService.nextBillingDate(chargingCycle, CIL_EndDate.date(), invoiceOn, chargingEveryCount);

						lastBillDate = invoiceAhead ? CIL_StartDate.date() : CIL_EndDate.date();

						system.debug('lastBillDate at end of inner while loop ' + lastBillDate);
						system.debug('NextInvoiceLineStartDate at end of outer while loop ' + NextInvoiceLineStartDate);

						countLines++;


						String lineKey = headerKey + '|' + CIL_StartDate.date() + '|' + CIL_EndDate.date() + '|' + f.Sales_Order_Line__c + '|' + f.Unit_Price__c + '|' + invoiceAhead; //KNDY=12819
						system.debug('lineKey ' + lineKey);
						if (!mCILs.containsKey(lineKey)) {


							mCILs.put(lineKey, new Customer_Invoice_Line__c(Customer_Invoice__r = new Customer_Invoice__c(Source_Key__c = headerKey),
									Product__c = f.Product__c,
									Product_Reference__c = f.Sales_Order_Line__r.Product_Reference__c,
									Quantity_Shipped__c = f.Quantity__c,
									Unit_Price__c = f.Unit_Price__c,
									Sales_Order__c = f.Sales_Order_Line__r.Sales_Order__c,
									Sales_Order_Line__c = f.Sales_Order_Line__c,
									Sales_Order_Line__r = f.Sales_Order_Line__r,
									Agreement_Line__c = container.agreementId != null ? f.Agreement_Line__c : null,
									Agreement_Line__r = f.Agreement_Line__c != null ? f.Agreement_Line__r : null, // KNDY-19504
									Agreement__c = container.agreementId != null ? container.agreementId : null,
									Company__c = container.companyId,
									Shipment__c = container.shipmentId != null ? container.shipmentId : null, //show shipment line only if grouped by Shipment. Coz if it is grouped BY SO, then one CIL can come come from multiple shipments
									Shipment_Line__c = container.shipmentId != null ? f.Shipment_Line__c : null,
									Discount_Percent__c = f.Sales_Order_Line__r.Discount_Percent__c,
									Off_Invoice_Rate__c = f.Sales_Order_Line__r.Off_Invoice_Rate__c,
									BillBack_Rate__c = f.Sales_Order_Line__r.BillBack_Rate__c,
									List_Price__c = f.Sales_Order_Line__r.List_Price__c,
									Line_Type__c = f.Sales_Order_Line__r.Line_Type__c,
									Rate_Basis__c = f.Rate_Basis__c,
									Price_Type__c = f.Price_Type__c,
									Pricing_UOM__c = f.Pricing_UOM__c,
									Pricing_UOM__r = f.Pricing_UOM__r,
									Recurrence_Start_Date__c = recurrenceStartDate == null ? f.Start_date__c : DateTime.newInstance(recurrenceStartDate, Time.newInstance(0, 0, 0, 0)),
									Description__c = f.Sales_Order_Line__r.Description__c, //KNDY-12324
									Start_Date__c = CIL_StartDate, //KNDY-9863
									End_Date__c = CIL_EndDate, //KNDY-9863
									Source_Key__c = lineKey,
									Discount_Amount__c = (f.Quantity__c * (f.Unit_Price__c - (f.Sales_Order_Line__r.Off_Invoice_Rate__c == null ? 0 : f.Sales_Order_Line__r.Off_Invoice_Rate__c)) * ((f.Sales_Order_Line__r.Discount_Percent__c == null ? 0 : f.Sales_Order_Line__r.Discount_Percent__c) / 100)).setScale(2)
							));

						} else {
							Customer_Invoice_Line__c cil = mCILs.get(lineKey);
							cil.Quantity_Shipped__c += f.Quantity__c;
							mCILs.get(lineKey).Discount_Amount__c = (cil.Quantity_Shipped__c * (cil.Unit_Price__c - (f.Sales_Order_Line__r.Off_Invoice_Rate__c == null ? 0 : f.Sales_Order_Line__r.Off_Invoice_Rate__c)) * ((f.Sales_Order_Line__r.Discount_Percent__c == null ? 0 : f.Sales_Order_Line__r.Discount_Percent__c) / 100)).setScale(2);
						}
						system.debug(countLines);
						Customer_Invoice_Line__c cil = mCILs.get(lineKey);
						system.debug(cil);

						//Adding fulfillment map . in Recurring there will always be one Fulfillment map per invoice line. so do not need to roll up values like (qty)
						mFulfillmentMap.put(f.Id + '|' + lineKey, new Customer_Invoice_Sub_Line__c(Fulfillment__c = f.id, Customer_Invoice_Line__r = new Customer_Invoice_Line__c(Source_Key__c = lineKey)));


						if (f.End_Date__c != null && CIL_EndDate.date() == f.End_Date__c.date()) {
							system.debug('no more line generation');
							break;
						}
						boolean hasfullCycle = FrequencyService.hasFullCycle(invoiceAhead ? NextInvoiceLineStartDate : lastBillDate, lineEndDate, chargingCycle, chargingEveryCount);
						system.debug('hasfullCycle ' + hasfullCycle);


					} while (FrequencyService.hasFullCycle(invoiceAhead ? NextInvoiceLineStartDate : lastBillDate, lineEndDate, chargingCycle, chargingEveryCount) || billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE);//END OF WHILE LOOP FOR LINES

					if (countLines == 0) { // if there are no lines being created for this header, then remove the header.
						if (!headerKeyExists) { //if headerKey DOESN'T exist, then we do not want to create the CI without any CI lines.
							system.debug('headerKey removed: ' + headerKey);
							mCIs.remove(headerKey);
						}
						dateInvoiced = FrequencyService.nextBillingDate(billingCycle, dateInvoiced, invoiceOn, billingEveryCount);
						CIL_EndDate = null; //reset the dateTime fields
						CIL_StartDate = null; //reset the dateTime fields
					} else {
						mFulfillmentsToUpdate.put(f.Id, new Fulfillment__c(Id = f.Id, Last_Bill_Date__c = DateTime.newInstance(lastBillDate, Time.newInstance(0, 0, 0, 0))));
						ci.Transaction_Date__c = ci.Transaction_Date__c == null || ci.Transaction_Date__c < DateTime.newInstance(lastBillDate, Time.newInstance(0, 0, 0, 0))
								? DateTime.newInstance(lastBillDate, Time.newInstance(0, 0, 0, 0))
								: ci.Transaction_Date__c;
					}

					//ALL MY BREAK CONDITIONS.
					if (CIL_EndDate != null && f.End_Date__c != null && CIL_EndDate.date() == f.End_Date__c.date()) {
						system.debug('first break cil_enddate == f.End_Date__c');
						break;
					}
					if (lineStartDate > system.today()) {
						system.debug('lineStartDate > system.today()');
						break;
					}
					if (billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE) {
						system.debug('billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE');
						break;
					}

					//SETTING UP VARIABLES FOR NEXT CI ROUND.
					if (countLines > 0) {
						//if we are invoicing ahead and this is the frst invoice we create, then the date invoiced should be changed to reflect the pro-rated date in next cycle
						if ((mFulfillmentsToUpdate.get(f.Id) == null || mFulfillmentsToUpdate.get(f.Id).Last_Bill_Date__c == null) && invoiceAhead) {
							dateInvoiced = FrequencyService.closestFutureBillingDate(CIL_EndDate.date(), recurrenceStartDate, billingCycle, invoiceOn, billingEveryCount);
							system.debug(LoggingLevel.Error, 'dateInvoice on first invoiceAhead cycle ' + dateInvoiced);
						} else {
							Date nextInvoiceDate = FrequencyService.closestFutureBillingDate(CIL_EndDate.date(), recurrenceStartDate, billingCycle, invoiceOn, billingEveryCount);
							system.debug('nextInvoiceDate ' + nextInvoiceDate);
							if (dateInvoiced == nextInvoiceDate)
								dateInvoiced = FrequencyService.nextBillingDate(billingCycle, dateInvoiced, invoiceOn, billingEveryCount); else
									dateInvoiced = nextInvoiceDate;
							system.debug('dateInvoiced for other cycles ' + dateInvoiced);
						}
					}

					//set our variables for next iteration
					lineStartDate = NextInvoiceLineStartDate;
					lineEndDate = invoiceAhead ? FrequencyService.nextBillingDate(billingCycle, dateInvoiced, invoiceOn, billingEveryCount) : dateInvoiced;
					system.debug('dateInvoiced for next cycle ' + dateInvoiced);
					system.debug('lineStartDate for next cycle ' + lineStartDate);
					system.debug('lineEndDate for next cycle ' + lineEndDate);


					system.debug('will go next round on headers: ' + ((dateInvoiced <= headerEndDate || billingCycle == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE) && dateInvoiced <= Date.today()));

				}//END OF WHILELOOP FOR HEADERS

			}//END OF FULFILLMENT LOOP
		}

	}


}