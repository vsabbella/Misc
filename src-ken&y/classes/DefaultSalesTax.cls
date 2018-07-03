public with sharing class DefaultSalesTax implements TaxService.ITaxAction {
		
		public List<FieldInfo> getDisplayFieldSet(Schema.sObjectType objectType){

			if(objectType == Sales_Order__c.getSobjectType()){
				List<FieldInfo> taxFields = FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', new List<String>{'Sales_Tax__c','Sales_Tax_Rate__c'});

				for(FieldInfo f : taxFields){
					f.editable = false;
				}
				return taxFields;
			}else if(objectType == Customer_Invoice__c.getSobjectType()){
				List<FieldInfo> taxFields = FieldInfo.fetchJsonFieldInfos('Customer_Invoice_Line__c', new List<String>{'Sales_Tax__c','Sales_Tax_Rate__c'});

				for(FieldInfo f : taxFields){
					f.editable = false;
				}
				return taxFields;
			}else if(objectType == Supplier_Invoice__c.getSobjectType()){
				List<FieldInfo> taxFields = new List<FieldInfo>();
				taxFields.add(new FieldInfo('Ship_From_Street__c', 'Ship From Street', 'textarea'));
            	taxFields.add(new FieldInfo('Ship_From_City__c', 'Ship From City', 'string'));
            	taxFields.add(new FieldInfo('Ship_From_State__c', 'Ship From State', 'string'));
            	taxFields.add(new FieldInfo('Ship_From_Country__c', 'Ship From Country', 'string'));
            	taxFields.add(new FieldInfo('Ship_From_Zip_Code__c', 'Ship From Zip Code', 'string'));
            	
            	taxFields.add(new FieldInfo('Ship_To_Street__c', 'Ship To Street', 'textarea'));
            	taxFields.add(new FieldInfo('Ship_To_City__c', 'Ship To City', 'string'));
            	taxFields.add(new FieldInfo('Ship_To_State__c', 'Ship To State', 'string'));
            	taxFields.add(new FieldInfo('Ship_To_Country__c', 'Ship To Country', 'string'));
            	taxFields.add(new FieldInfo('Ship_To_Zip_Code__c', 'Ship To Zip Code', 'string'));
				return taxFields;
			}else{
				return null;
			}
		}

		public List<TaxService.TaxResult> getTaxes(List<Id>ids){
			if(ids.get(0).getSObjectType()  == Sales_Order__c.getSobjectType()){
				return getSalesOrderTax(ids);
			}else if(ids.get(0).getSObjectType()  == Customer_Invoice__c.getSobjectType()){
				return getCustomerInvoiceTax(ids);
			}else if(ids.get(0).getSObjectType() == Purchase_Order__c.getSobjectType()){
				return getPurchaseOrderTax(ids);
			}else if(ids.get(0).getSObjectType() == Supplier_Invoice__c.getSobjectType()){
				return getSupplierInvoiceTax(ids);
			}else{
				//do nothing
				return null;
			}
		}

		public List<TaxService.TaxResult> voidTaxes(List<id>ids){
			return null;
		}

		private List<TaxService.TaxResult> getSalesOrderTax(List<Id>ids){

			SoqlUtil soql = new SoqlUtil('Sales_Order_Line__c');
			soql.addFields(new Set<String>{'Id', 'Sales_Order__c', 'Extended_Price__c', 'Sales_Tax__c', 'Sales_Tax_Rate__c',
												'Product__r.Non_Taxable__c', 'Sales_Order__r.Ship_to__r.Sales_Tax_Rate__c',
												'Sales_Order__r.Ship_To__c'});
			soql.setWhereClause('Sales_Order__c in:ids');
			List<Sales_Order_Line__c> lines = Database.Query(soql.getQuery());

			Map<Id, TaxService.TaxResult> results = new Map<Id, TaxService.TaxResult>();
			for(Sales_Order_Line__c l : lines){
				TaxService.TaxResult tr = new TaxService.TaxResult();
				if(l.Sales_Order__r.Ship_To__c != null){
					l.Sales_Tax_Rate__c = l.Product__r.Non_Taxable__c == false && l.Sales_Order__r.Ship_to__r.Sales_Tax_Rate__c != null ? l.Sales_Order__r.Ship_to__r.Sales_Tax_Rate__c : 0;
				l.Sales_Tax__c = (l.Sales_Tax_Rate__c / 100) * l.Extended_Price__c;
					tr.isSuccess = true;
					tr.message = 'Tax Calculated for this sales order.';
				}else{
					tr.isSuccess = false;
					tr.message = 'Unable to calculate sales tax.  Ship To Customer is missing.';
				}

				results.put(l.Sales_Order__c, tr);


			}
			update lines;

			if(lines.size() == 0){
				TaxService.TaxResult tr = new TaxService.TaxResult();
				tr.isSuccess = true;
				tr.message = 'No lines to get tax for.';
				results.put(null, tr);
			}

			return results.values();
		}

		private List<TaxService.TaxResult> getPurchaseOrderTax(List<Id>ids){
			return null;
		}

		private List<TaxService.TaxResult>getCustomerInvoiceTax(List<Id>ids){
			Map<Id, TaxService.TaxResult> results = new Map<Id, TaxService.TaxResult>();

			SoqlUtil soql = new SoqlUtil('Customer_Invoice_Line__c');
			soql.addFields(new Set<String>{'Id', 'Customer_Invoice__c','Extended_Price__c', 'Sales_Tax__c', 'Sales_Tax_Rate__c', 'Product__r.Non_Taxable__c',
											'Shipment_Line__r.Shipment__r.Customer__r.Sales_Tax_Rate__c', 'Shipment_Line__c',
											'Customer_Invoice__r.Ship_To__r.Sales_Tax_Rate__c', 
											'Sales_Order_Line__r.Sales_Order__r.Ship_to__r.Sales_Tax_Rate__c'});
			soql.setWhereClause('Customer_Invoice__c in:ids');

			List<Customer_Invoice_Line__c> lines = Database.Query(soql.getQuery());

			for(Customer_Invoice_Line__c cil : lines){
				TaxService.TaxResult tr = new TaxService.TaxResult();
				tr.isSuccess = true;
				tr.message = 'Taxes Calculated.'; 
				tr.obj = (SObject) new Customer_Invoice__c(Id=cil.Customer_Invoice__c);

				if(cil.Shipment_Line__c != null){
					cil.Sales_Tax_Rate__c = cil.Product__r.Non_Taxable__c == false && cil.Shipment_Line__r.Shipment__r.Customer__r.Sales_Tax_Rate__c != null ? cil.Shipment_Line__r.Shipment__r.Customer__r.Sales_Tax_Rate__c : 0;
					cil.Sales_Tax__c = (cil.Sales_Tax_Rate__c/100) * cil.Extended_Price__c;
				}else if(cil.Sales_Order_Line__r != null){
					cil.Sales_Tax_Rate__c = cil.Product__r.Non_Taxable__c == false && cil.Sales_Order_Line__r.Sales_Order__r.Ship_to__r.Sales_Tax_Rate__c != null ? cil.Sales_Order_Line__r.Sales_Order__r.Ship_to__r.Sales_Tax_Rate__c : 0;
					cil.Sales_Tax__c = (cil.Sales_Tax_Rate__c/100) * cil.Extended_Price__c;
				}else if(cil.Customer_Invoice__r.Ship_to__r != null){
					cil.Sales_Tax_Rate__c = cil.Product__r.Non_Taxable__c == false && cil.Customer_Invoice__r.Ship_to__r.Sales_Tax_Rate__c != null ? cil.Customer_Invoice__r.Ship_to__r.Sales_Tax_Rate__c : 0;
					cil.Sales_Tax__c = (cil.Sales_Tax_Rate__c/100) * cil.Extended_Price__c;
				}else{
					tr.obj = (SObject) new Customer_Invoice__c(Id=cil.Customer_Invoice__c);
					tr.isSuccess = false;
					tr.message = 'Ship To Customer is required to get Tax.';
				}
				results.put(cil.Customer_Invoice__c, tr);
			}

			update lines;

			if(lines.size() == 0){
				TaxService.TaxResult tr = new TaxService.TaxResult();
				tr.isSuccess = true;
				tr.message = 'No lines to get tax for.';
				results.put(null, tr);
			}
			return results.values();
		}

		private List<TaxService.TaxResult>getSupplierInvoiceTax(List<Id>ids){
			system.debug('getSupplierInvoiceTax**'+ids);
			List<TaxService.TaxResult> results = new List<TaxService.TaxResult>();
			try{
				list<Supplier_Invoice__c> lstSI = [Select Id, Name,
                                                  (Select Id, Name,Ship_To_State__c, Ship_To_Street__c, Ship_To_City__c, Ship_To_Zip_Code__c, 
                                                  Ship_To_Country__c, Ship_From_Street__c, Ship_From_City__c,
                                                  Ship_From_State__c, Ship_From_Zip_Code__c, Ship_From_Country__c,
                                                  Sales_Tax_Rate__c, Sales_Tax_Amount__c,Unit_Price__c,
                                                  Invoice_Quantity__c From Supplier_Invoice_Lines__r) 
                                                  From Supplier_Invoice__c
                                                  Where Id in:ids];
				list<Supplier_Invoice_Line__c> lstSIL = new list<Supplier_Invoice_Line__c>();
			    system.debug('getSupplierInvoiceTax***'+lstSI);
				if(!lstSI.isEmpty()){
					for(Supplier_Invoice__c si : lstSI){
						TaxService.TaxResult t = new TaxService.TaxResult();
						system.debug('si.Supplier_Invoice_Lines__r****'+si.Supplier_Invoice_Lines__r);
						for(Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
							sil.Sales_Tax_Rate__c = 1.79;
							sil.Sales_Tax_Amount__c = (sil.Unit_Price__c*sil.Invoice_Quantity__c)*.0179;
							lstSIL.add(sil);
						}
						t.isSuccess = true;
	                    t.obj = si;
	                    t.message = 'Tax calculated for ' + si.Name;
	                    results.add(t);
					}
					if(!lstSIL.isEmpty()){
						system.debug('lstSIL****'+lstSIL);
						update lstSIL;
					}
				}
			}catch(exception ex){
				results.clear();
				system.debug('exception**'+ex.getMessage());
				TaxService.TaxResult t = new TaxService.TaxResult();
				t.isSuccess = false;
				t.message = 'Error while calculating tax';
				results.add(t);
			}
			return results;
		}

}