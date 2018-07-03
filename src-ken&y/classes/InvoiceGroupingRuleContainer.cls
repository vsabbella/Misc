public with sharing class InvoiceGroupingRuleContainer {
	
		public Id companyId;
		public String transactionCurrency;
		public Id transactionCurrencyID;
		public Id paymentTerm;
		public Id customerId;
		public Id billToId;
		public Id agreementId;
		public Id salesOrderId;
		public String salesOrderType;
		public string SOCondition;
		public Id shipmentId;
		public Id categoryId;
		public Id productId;
		public Date recurrenceStartDate;
		public String periodicity;
		public integer everyPeriodicity;
		public Id groupingRule;
		public Id fulfillmentId;
		public DateTime recurrenceStartDateTime;
		
		public InvoiceGroupingRuleContainer(Fulfillment__c f, InvoiceGroupingRuleDefinition ruleDef, map<id, Id> mapCorpToOneBillTo) {
			this.companyId = f.Company__c;
			this.transactionCurrency = f.Currency__r.ISO_code__c;
			this.transactionCurrencyID = f.Currency__c != null ? f.Currency__c  : f.Sales_order_line__r.Sales_order__r.Currency__c;
			this.paymentTerm = f.Payment_Term__c;
			
			//BILLING INFORMATION
			//If use billing from fulfillment is true and fulfillment has valid data (not blank) then container should get data from fulfillment, else from rule (ruel will ALWAYS HAVE THE DATA POPULATED)
			boolean isValidBillingOnFulfillment = false;
			if((f.Billing_UOM__c != null && f.Recurrence_Start_Date__c != null) || (f.Billing_UOM__c == null && f.Recurrence_Start_Date__c == null))
				isValidBillingOnFulfillment = true;
			
			
			if(ruleDef.UseBillingFromFulfillment && isValidBillingOnFulfillment) {
				this.periodicity = f.Billing_UOM__r.Recurrence__c == null ? FrequencyService.FREQUENCY_PERIOD_IMMEDIATE : f.Billing_UOM__r.Recurrence__c;
				this.everyPeriodicity = this.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE  ? 1 : Integer.valueOf(f.Billing_UOM__r.Every__c);
				this.recurrenceStartDate = this.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? null : f.Recurrence_Start_Date__c.date();
				this.recurrenceStartDateTime = this.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? null : f.Recurrence_Start_Date__c;
			}else {
				this.periodicity = ruleDef.periodicity == null ? FrequencyService.FREQUENCY_PERIOD_IMMEDIATE : ruleDef.periodicity;
				this.everyPeriodicity = this.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE  ? 1 : ruleDef.everyPeriodicity;
				this.recurrenceStartDate = ruleDef.recurrenceStartDate;
				this.recurrenceStartDateTime = ruleDef.recurrenceStartDateTime;
			}
			this.groupingRule = ruleDef.groupingRule;
			 
			
			if(ruleDef.groupByCustomers != null) {  //If Selecting Group By Hierarchy
				if(ruleDef.groupByCustomers == 'Corporate Parent') {
					if(f.Customer__r.RecordType.DeveloperName != 'Corporate_Parent')
						this.customerId = f.Customer__r.Top_Parent_Customer__c;
					else
					 	this.customerId = f.Customer__c;
					this.billToId = !mapCorpToOneBillTo.IsEmpty() && mapCorpToOneBillTo.get(customerId) != null ? mapCorpToOneBillTo.get(customerId) : f.Customer__r.Top_Parent_Customer__r.Default_Bill_To_Customer__c; 
				}
					
				else if(ruleDef.groupByCustomers == 'Bill To') {
					if(f.Customer__r.RecordType.DeveloperName == 'Sold_To') {
						 this.customerId = f.Customer__r.Parent_Customer__c;
					} else if(f.Customer__r.RecordType.DeveloperName == 'Ship_To') {
						this.customerId = f.Customer__r.Parent_Customer__r.Parent_Customer__c;
					}else if(f.Customer__r.RecordType.DeveloperName == 'Site') {
						this.customerId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
					}else 
						this.customerId = f.Customer__c;
					this.billToId = this.customerId;
				} 
				else if(ruleDef.groupByCustomers == 'Sold To') {
					if(f.Customer__r.RecordType.DeveloperName == 'Ship_To') {
						this.customerId = f.Customer__r.Parent_Customer__c;
						this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__c;
					}else if(f.Customer__r.RecordType.DeveloperName == 'Site') {
						this.customerId = f.Customer__r.Parent_Customer__r.Parent_Customer__c;
						this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
					}else {
						this.customerId = f.Customer__c;
						this.billToId = f.Customer__r.Parent_Customer__c;
					}
				}
				else if(ruleDef.groupByCustomers == 'Ship To') {
					if(f.Customer__r.RecordType.DeveloperName == 'Site') {
						this.customerId = f.Customer__r.Parent_Customer__c;
						this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
						 
					}else {
						this.customerId = f.Customer__c;
						this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
					}
					   
					
				}
				else {
					this.customerId = f.Customer__c; //the Customer is Site and grouping is Site;
					this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
				}

			}
			else { //Else selected for a specific customer
				this.customerId = f.Customer__c;
				//KNDY-8689 should set Bill to if rule is set for specific customer!
				if(f.Customer__r.RecordType.DeveloperName == 'Site') {
					this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
				}else if(f.Customer__r.RecordType.DeveloperName == 'Ship_To') {
					this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__c;
				}else if(f.Customer__r.RecordType.DeveloperName == 'Sold_To') {
					this.billToId = f.Customer__r.Parent_Customer__c;
				}else if(f.Customer__r.RecordType.DeveloperName == 'Bill_To') {
					this.billToId = f.Customer__c;
				}else {
					this.billToId =  !mapCorpToOneBillTo.IsEmpty() && mapCorpToOneBillTo.get(customerId) != null ? mapCorpToOneBillTo.get(customerId) : f.Customer__r.Top_Parent_Customer__r.Default_Bill_To_Customer__c;
				}
			}
			
            
			if(ruleDef.groupBySalesOrders == true)
				this.salesOrderId = f.Sales_Order_Line__r.Sales_Order__c;
			if(ruleDef.groupBySalesOrderTypes == true)
				this.salesOrderType = f.Sales_Order_Line__r.Sales_Order__r.Type__c;
			
			this.SOCondition = ruleDef.groupSOIf;
			
			if(ruleDef.groupByShipments == true)
				this.shipmentId = f.Shipment_Line__r.Shipment__c;
            
			if(ruleDef.forAgreements != null  || ruleDef.groupByAgreements == true)
				this.agreementId = f.Agreement_Line__r.Agreement__c;
            
            if(ruleDef.forCategories != null || ruleDef.groupByCategory == true)
				this.categoryId = f.Category__c;
            
			if(ruleDef.forProducts != null || ruleDef.groupByProduct == true)
				this.productId = f.Product__c;
		 
            if(ruleDef.forCustomers != null || ruleDef.groupByCustomers != null)
				this.customerId = f.Customer__c;
		}

		public InvoiceGroupingRuleContainer(Fulfillment__c f, map<id, Id> mapCorpToOneBillTo) { //KNDY-14713
			this.companyId = f.Company__c;
			this.transactionCurrency = f.Currency__r.ISO_code__c;
			this.transactionCurrencyID = f.Currency__c != null ? f.Currency__c  : f.Sales_order_line__r.Sales_order__r.Currency__c;
			this.paymentTerm = f.Payment_Term__c;
			this.periodicity = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;
			this.recurrenceStartDate = null;

			this.customerId = f.Customer__c;
			//KNDY-8689 should set Bill to if rule is set for specific customer!
			if(f.Customer__r.RecordType.DeveloperName == 'Site') {
				this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c;
			}else if(f.Customer__r.RecordType.DeveloperName == 'Ship_To') {
				this.billToId = f.Customer__r.Parent_Customer__r.Parent_Customer__c;
			}else if(f.Customer__r.RecordType.DeveloperName == 'Sold_To') {
				this.billToId = f.Customer__r.Parent_Customer__c;
			}else if(f.Customer__r.RecordType.DeveloperName == 'Bill_To') {
				this.billToId = f.Customer__c;
			}else {
				this.billToId =  !mapCorpToOneBillTo.IsEmpty() && mapCorpToOneBillTo.get(customerId) != null ? mapCorpToOneBillTo.get(customerId) : f.Customer__r.Top_Parent_Customer__r.Default_Bill_To_Customer__c;
			}
			
			this.salesOrderId = f.Sales_Order_Line__r.Sales_Order__c;
			this.salesOrderType = f.Sales_Order_Line__r.Sales_Order__r.Type__c;
			this.shipmentId = f.Shipment_Line__r.Shipment__c;
			this.agreementId = f.Agreement_Line__r.Agreement__c;
			this.categoryId = f.Category__c;
			this.productId = f.Product__c;
			this.customerId = f.Customer__c;
			this.fulfillmentId = f.Id;
		}
		
		public integer hashCode(){
			return HashCodeGenerator.getHashCode(this);  
		}
		
		public boolean equals(object obj){
			InvoiceGroupingRuleContainer rd = (InvoiceGroupingRuleContainer)obj;
			if(companyId == rd.companyId &&
			   customerId == rd.customerId &&
			   billToId == rd.billToId &&
			   agreementId == rd.agreementId &&
			   salesOrderId == rd.salesOrderId &&
			   salesOrderType == rd.salesOrderType &&
			   SOCondition == rd.SOCondition &&
			   shipmentId == rd.shipmentId &&
			   categoryId == rd.categoryId &&
			   productId == rd.productId &&
			   transactionCurrency == rd.transactionCurrency &&
			   transactionCurrencyID == rd.transactionCurrencyID &&			   
			   paymentTerm == rd.paymentTerm &&
			   recurrenceStartDate == rd.recurrenceStartDate &&
			   periodicity == rd.periodicity &&
			   groupingRule == rd.groupingRule &&
			   everyPeriodicity == rd.everyPeriodicity &&
			   fulfillmentId == rd.fulfillmentId){ 
				return true;			
			}else{
				return false;
			}
		}
}