public with sharing class FixedAssetManageAdjustmentsExt {
	
	public Fixed_Asset_Adjustment__c faa {get;set;} {faa = new Fixed_Asset_Adjustment__c();}
	public Fixed_Asset__c fa {get;set;} {fa = new Fixed_Asset__c();}
	public List<Fixed_Asset__c> fas {get;set;} {fas = new List<Fixed_Asset__c>();}
	public List<Supplier_Invoice_Line__c> rils {get;set;}
	public string selectedRIL {get;set;}
	public string selectedAction {get;set;}
	public string fixedAssetId {get;set;}
	public RILDetail selectedRILDetail {get;set;}
	public List<RILDetail> RILDetails {get;set;}
	public List<Fixed_Asset_Adjustment__c> newAdjustments {get;set;}
	public transient List<Fixed_Asset_Adjustment__c> existingAdjustments {get;set;}
	public Integer   faaAdjustmentListIndex{get;set;}
	public String pageSubtitle{get;set;}
	public Boolean renderAdjustmentOptions{get;set;}
	public Boolean renderGroupLinesButton{get;set;}
	public Boolean notRetiredAsset {get;set{
        notRetiredAsset = true;
    }}
    public boolean displayAddAdditionalButton{get;set;}
    public boolean displayAddCustomButton{get;set;}
	
	public FixedAssetManageAdjustmentsExt(Apexpages.standardcontroller controller){
		
		fixedAssetId = controller.getId();
		renderGroupLinesButton = FALSE;
		displayAddAdditionalButton = String.isNotBlank(Label.Display_Add_Addl_Button) 
										&& Label.Display_Add_Addl_Button.toLowerCase() == 'yes';
		displayAddCustomButton = String.isNotBlank(Label.Display_Add_Custom_Button) 
										&& Label.Display_Add_Custom_Button.toLowerCase() == 'yes';

		if(fixedAssetId!=null){
			SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); 
			soql.addFields(new set<string>{'id','name','Status__c'});
			soql.setWhereClause('Id=:fixedAssetId');
			
			Fixed_Asset__c currentAsset = Database.query(soql.getQuery());
			
			 if(currentAsset.Status__c=='Retired'){
                notRetiredAsset = false;
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'A retired asset cannot be adjusted.'));
            }
			
			pageSubtitle = Label.Add_Adjustments_To_Asset +' : ' + currentAsset.name;
			renderAdjustmentOptions = false;
		}else{
			pageSubtitle = Label.Manage_Fixed_Assets;
			renderAdjustmentOptions = true;
		}
		updateReceiptInvoiceLines();
		renderGroupLinesButton = rils.size() > 0 && fixedAssetId == NULL;
	}
	
	
	public void updateReceiptInvoiceLines(){
		RILDetails = new List<RILDetail>();
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
		//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
		soql.addFields(new set<string>{
			'id','name','purchase_order__c','purchase_order_line__c','item__c','description__c','item__r.name',
			'unit_price__c','invoice_quantity__c','supplier_invoice__r.currency__c',
			'supplier_invoice__r.company__c',
			'Supplier_Invoice__c','Supplier_Invoice__r.Name','supplier_invoice__r.supplier__c','extended_cost__c',
			'Total_Fixed_Asset_Adjustments__c', 'supplier_invoice__r.transaction_date__c',
			'Extended_Price__c','item__r.source__c', 'supplier_invoice__r.company__r.Comp_Currency__c'
		});
		soql.setWhereClause(' Track_as_Asset__c = \'Yes\' AND Supplier_Invoice__r.Finalized__c = true');
		soql.setOrderByClause('supplier_invoice__r.name, name');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
		childRel.addFields(new set<string>{
			'Id','name','type__c','amount__c','Fixed_Asset__c','Adjustment_Date__c','Units__c'
		});
		soql.addChildRelationship(childRel);
		SOQLUtil.ChildRelationship childAccEntries = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
		childAccEntries.addFields(new set<string>{
			'Id','name','Comp_Functional_Currency_Amount_DR__c'
		});
		childAccEntries.setWhereClause(' Status__c = \'Active\' and Accounting_Entry__r.Has_Exceptions__c = false and Comp_Functional_Currency_Amount_DR__c > 0');
		childAccEntries.setOrderByClause('Comp_Functional_Currency_Amount_DR__c DESC'); 
		childAccEntries.setLimit(1);
		soql.addChildRelationship(childAccEntries);
		rils = new List<Supplier_Invoice_Line__c>();
		List<Supplier_Invoice_Line__c> tempRILs = new List<Supplier_Invoice_Line__c>();
		tempRILs = Database.query(soql.getQuery());
		//Add the Invoice Lines to the UI only if Accounting is done for those lines.
		for(Supplier_Invoice_Line__c invoiceLine: tempRILs){
			if(invoiceLine.Accounting_Entry_Lines__r.size() > 0){
				rils.add(invoiceLine);
			}
		}
        system.debug('rils: ' + rils);
		if(rils.size() > 0){
		    updateDetails(); 
		}
	}
	
	public void updateDetails(){
		if(rils != null){
			for(Supplier_Invoice_Line__c ril : rils){
				RILDetail iRD = new RILDetail();
				iRD.ril = ril;
				if(iRD.ril.total_fixed_asset_adjustments__c == null){
					iRD.ril.total_fixed_asset_adjustments__c = 0.00000;
				}
				//if(iRD.ril.extended_cost__c == null || iRD.ril.unit_price__c == null){
				//	iRD.ril.invoice_quantity__c = iRD.ril.invoice_quantity__c != NULL ? iRD.ril.invoice_quantity__c : 0;
				//	//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price. Commented below line since unit price will have values
				//	//iRD.ril.Unit_Price__c = iRD.ril.Unit_Price__c == null ? iRD.ril.invoice_unit_price__c : iRD.ril.unit_price__c;
				//	iRD.ril.extended_cost__c = (iRD.ril.invoice_quantity__c * iRD.ril.unit_price__c)+1;
				//}
				//iRD.newfaas = new List<Fixed_Asset_Adjustment__c>{new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = iRD.ril.Id, supplier_invoice__c = ril.supplier_invoice__c, purchase_order_line__c = iRD.ril.purchase_order_line__c, fixed_asset__c = fixedAssetId)};
				if(ril.Accounting_Entry_Lines__r.size() > 0){
					ril.Functional_Amount__c = ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c;
				}
				RILDetails.add(iRD);
			}
		}
	}
	
	
	public Supplier_Invoice_Line__c updateSelectedRIL(){
		try{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
			//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
			soql.addFields(new set<string>{
				'id','name','purchase_order__c','purchase_order_line__c','item__c','description__c','item__r.name',
				'unit_price__c','invoice_quantity__c','supplier_invoice__r.currency__c','supplier_invoice__r.company__c',
				'supplier_invoice__r.company__r.Comp_Currency__c','Supplier_Invoice__c','Supplier_Invoice__r.Name','supplier_invoice__r.supplier__c','extended_cost__c',
				'Total_Fixed_Asset_Adjustments__c', 'supplier_invoice__r.transaction_date__c', 'item__r.source__c','Extended_Price__c'
			});
			soql.setWhereClause('Id = :selectedRIL');
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
			childRel.addFields(new set<string>{
				'Id','name','type__c','amount__c','Fixed_Asset__c','Adjustment_Date__c','Units__c'
			});
			soql.addChildRelationship(childRel);
			SOQLUtil.ChildRelationship childAccEntries = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
			childAccEntries.addFields(new set<string>{
				'Id','name','Comp_Functional_Currency_Amount_DR__c'
			});
			childAccEntries.setWhereClause(' Status__c = \'Active\' and Accounting_Entry__r.Has_Exceptions__c = false and Comp_Functional_Currency_Amount_DR__c > 0');
			soql.addChildRelationship(childAccEntries);
			Supplier_Invoice_Line__c ril = Database.query(soql.getQuery());
            System.debug(logginglevel.error,'ril--->'+ril);
			//if(ril.extended_cost__c == null || ril.unit_price__c == null){
			//	ril.invoice_quantity__c = ril.invoice_quantity__c != NULL ? ril.invoice_quantity__c : 0;
			//	//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price. Commented below line since unit price will have values
			//	//ril.Unit_Price__c = ril.Unit_Price__c == null ? ril.invoice_unit_price__c : ril.unit_price__c;
			//	ril.extended_cost__c = ril.invoice_quantity__c * ril.unit_price__c;
			//}
			return ril;
		}catch(Exception ex){
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			return null;
		}
	}
	
	public void addAdjustment(){
		Supplier_Invoice_Line__c ril = updateSelectedRIL();
		newAdjustments.add(new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = ril.Id, 
		                       supplier_invoice__c = ril.supplier_invoice__c, fixed_asset__c = fixedAssetId));
	}
	
	public void addAdditional(){
		Supplier_Invoice_Line__c ril = updateSelectedRIL();
		fas.add(new Fixed_Asset__c(Supplier_Invoice_line__c = ril.Id, supplier_invoice__c = ril.supplier_invoice__c, fixed_asset__c = fixedAssetId, name = ril.item__r.name, 
										company__c = ril.Supplier_Invoice__r.company__c, residual_value__c = 0, supplier__c = ril.Supplier_Invoice__r.Supplier__c, 
										purchase_order__c = ril.purchase_order__c, purchase_order_line__c = ril.purchase_order_line__c));
		for(Fixed_Asset__c fa: fas){
			fa.Purchase_Price__c = ril.Extended_Price__c/fas.size();
		}
	}
	
	public void updateAction(){
		//system.debug('action: ' + selectedAction);
		//system.debug('selectedRIL: ' + selectedRIL);
		Set<Id> fromCurrencies = new Set<Id>();
		Set<Id> toCurrencies = new Set<Id>();
		List<DateTime> exchangeRateDates = new List<DateTime>();		
		if(selectedAction == 'GROUP'){
			fa = new Fixed_Asset__c();
			fa.residual_value__c = 0;
			//newAdjustments = new List<Fixed_Asset_Adjustment__c>();
			decimal totalFuncCost = 0;
			decimal totalPurchaseCost = 0;
			for(RILDetail rd : RILDetails){
				if(rd.selected){
					exchangeRateDates.add(rd.ril.Supplier_Invoice__r.Transaction_date__c);
					fromCurrencies.add(rd.ril.Supplier_Invoice__r.Currency__c);
					toCurrencies.add(rd.ril.Supplier_Invoice__r.company__r.Comp_Currency__c);
				}
			}
			for(RILDetail rd : RILDetails){
				if(rd.selected){
					decimal amount = rd.ril.extended_price__c == null ? 0 : rd.ril.extended_price__c;
					totalPurchaseCost += amount;
					if(rd.ril.Accounting_Entry_Lines__r.size() > 0){
						totalFuncCost += rd.ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c;
					}							  
					/*newAdjustments.add(new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = rd.ril.Id, 
					                                                    supplier_invoice__c = rd.ril.supplier_invoice__c, 
    				                                                    amount__c = amount, type__c = 'Upgrade',
    																	company__c = rd.ril.supplier_invoice__r.company__c,
    																	currency__c = rd.ril.supplier_invoice__r.currency__c,
    																	adjustment_date__c = system.today()));*/
					fa.company__c = rd.ril.Supplier_Invoice__r.company__c;
					fa.name = 'Fixed Asset';
					fa.purchase_currency__c = rd.ril.Supplier_Invoice__r.Currency__c;
				}
			}
			fa.Acquisition_Cost__c = totalFuncCost;
			fa.purchase_price__c = totalPurchaseCost;
		}else if(selectedAction == 'MULTIPLE' || selectedAction == 'CUSTOM'){
			Supplier_Invoice_Line__c ril = updateSelectedRIL();
			fas = new List<Fixed_Asset__c>();
			if(selectedAction == 'MULTIPLE'){
				decimal count = (ril.invoice_quantity__c == null || ril.invoice_quantity__c == 0) ? 1 : ril.invoice_quantity__c;
				count = count > 1000 ? 1000 : count;
				for(integer i=0; i<count; i++){
					//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
					fas.add(new Fixed_Asset__c(acquisition_cost__c = ril.unit_price__c, residual_value__c = 0, 
					        supplier_invoice__c = ril.supplier_invoice__c, Supplier_Invoice_line__c = ril.Id, units__c = 1, 
													fixed_asset__c = fixedAssetId, company__c = ril.supplier_invoice__r.company__c, 
													name = ril.item__r.name, purchase_price__c = ril.extended_price__c/count,
													supplier__c = ril.Supplier_Invoice__r.supplier__c,
													purchase_order__c = ril.purchase_order__c, 
													purchase_order_line__c = ril.purchase_order_line__c,
													purchase_currency__c = ril.supplier_invoice__r.Currency__c));
					if(ril.Accounting_Entry_Lines__r.size() > 0){
						fas[i].Acquisition_Cost__c = ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c/count;
					}
				}
			}else if(selectedAction == 'CUSTOM'){
				Fixed_Asset__c fa = new Fixed_Asset__c(Supplier_Invoice_line__c = ril.Id, units__c = ril.invoice_quantity__c,
				                                acquisition_cost__c = ril.extended_price__c, residual_value__c = 0, 
												supplier_invoice__c = ril.supplier_invoice__c, fixed_asset__c = fixedAssetId, 
												company__c = ril.supplier_invoice__r.company__c, name = ril.item__r.name,
												supplier__c = ril.Supplier_Invoice__r.supplier__c, 
												purchase_order__c = ril.purchase_order__c, 
												purchase_order_line__c = ril.purchase_order_line__c, 
												purchase_price__c = ril.extended_price__c,
												purchase_currency__c = ril.supplier_invoice__r.Currency__c);
				if(ril.Accounting_Entry_Lines__r.size() > 0){
					fa.Acquisition_Cost__c = ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c;
				}
				fas.add(fa);
			}
		}else if(selectedAction == 'SINGLE'){
			Supplier_Invoice_Line__c ril = updateSelectedRIL();
			fa = new Fixed_Asset__c();
			fa.Supplier_Invoice_Line__c = selectedRil;
			fa.purchase_price__c = ril.extended_price__c;
			fa.Units__c = ril.invoice_quantity__c;
			fa.company__c = ril.supplier_invoice__r.company__c;
			fa.name = ril.item__r.name;
			fa.residual_value__c = 0;
			fa.supplier__c = ril.Supplier_Invoice__r.supplier__c; 
			fa.purchase_order__c = ril.purchase_order__c;
			fa.purchase_order_line__c = ril.purchase_order_line__c;
			fa.supplier_invoice__c = ril.supplier_invoice__c;
			fa.Date_Purchased__c = ril.Supplier_Invoice__r.transaction_date__c != NULL ? 
									Date.valueOf(ril.Supplier_Invoice__r.transaction_date__c) : NULL;
			//Calculates the costs in functional currency and assigns to FA's acquisition cost.
			fa.purchase_currency__c = ril.Supplier_Invoice__r.Currency__c;
			//Changing the below assignment to Accounting Entry Line's COMP Functional Currency Amount.
			if(ril.Accounting_Entry_Lines__r.size() > 0){
				fa.Acquisition_Cost__c = ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c;
			}
		}else if(selectedAction == 'ADJUST'){
			Supplier_Invoice_Line__c ril = updateSelectedRIL();
			
			//existingAdjustments = ril.Fixed_Asset_Adjustments__r;
			newAdjustments = new List<Fixed_Asset_Adjustment__c>();
			newAdjustments.add(new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = ril.Id, 
			                                                  supplier_invoice__c = ril.supplier_invoice__c, 
			                                                  fixed_asset__c = fixedAssetId,company__c = ril.supplier_invoice__r.company__c, 
			                                                  currency__c = ril.Accounting_Entry_Lines__r.size() > 0 ? ril.supplier_invoice__r.company__r.Comp_Currency__c : ril.supplier_invoice__r.currency__c,
															  amount__c = ril.Accounting_Entry_Lines__r.size() > 0 ? ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c : ril.extended_price__c,
															  units__c = ril.invoice_quantity__c));

		}
	}
	
	public void addFixedAsset(){
		try{
			if(fa.name != null && fa.name != ''
					&& fa.company__c != null
					&& fa.Asset_Class__c != null){
				DML.insertAsUser(fa);
				fixedAssetId = fa.Id;
				Supplier_Invoice_Line__c ril = updateSelectedRIL();
				/*
				for(Fixed_Asset_Adjustment__c faa : rd.newfaas){
					if(faa.fixed_asset__c == null){
						faa.fixed_asset__c = fa.Id;
					}
				}
				*/
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.CONFIRM, Label.FixedAsset_was_successfully_created + ' ' + fa.name));
				fa = new Fixed_Asset__c();
			}else{
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Label.Enter_Name_Company_AssetClass_for_this_FixedAsset));
			}
		}catch(Exception ex){
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
	}
	
	
	/* Navigation */
	
	public pageReference cancel(){
		if(fixedAssetId != null){
			return new pageReference('/' + fixedAssetId);
		}else{
			return new pageReference('/' + schemaUtil.getInstance().getObjectPrefix(new Fixed_Asset__c()) + '/o');
		}
	}
	
	public pageReference save(){
		
		Savepoint sp = Database.setSavepoint();
		
		try{
		    System.debug(logginglevel.error,'selectedAction--->'+selectedAction);
			if(selectedAction == 'GROUP'){
				List<Supplier_Invoice_Line__c> updateRILs = new List<Supplier_Invoice_Line__c>();
				FixedAssetService.isAcqCostCalculated = TRUE;//To avoid re-calculating Acquisition cost at trigger level.
				DML.insertAsUser(fa);
				if(fa.Id != NULL){
					for(RILDetail rd : RILDetails){
						if(rd.selected){
							updateRILs.add(new Supplier_Invoice_Line__c(Id = rd.ril.id, Track_as_Asset__c = 'Closed'));
						}
					}
				}
				//fa.acquisition_cost__c = 0; 
				/*for(Fixed_Asset_Adjustment__c faa : newAdjustments){
					faa.fixed_asset__c = fa.Id;
					faa.subtransaction_type__c = faa.type__c;
					faa.transaction_date__c = system.now();
					//faa.finalized_date__c = system.now();
					if(faa.Supplier_Invoice_Line__c != null){
						updateRILs.add(new Supplier_Invoice_Line__c(Id = faa.Supplier_Invoice_Line__c, Track_as_Asset__c = 'Closed'));
					}
				}
				DML.insertAsUser(newAdjustments);
				
				for(Fixed_Asset_Adjustment__c faa : newAdjustments){
					faa.finalized__c = true;
				}
				
				DML.updateAsUser(newAdjustments);*/
				
				if(updateRILs.size() > 0){
					DML.updateAsUser(updateRILs);
				}
					
			}else if(selectedAction == 'SINGLE'){
				FixedAssetService.isAcqCostCalculated = TRUE;//To avoid re-calculating Acquisition cost at trigger level.
				DML.insertAsUser(fa);
                
				Supplier_Invoice_Line__c ril = updateSelectedRIL();
				//Only update what we need
				Supplier_Invoice_Line__c updateRIL = new Supplier_Invoice_Line__c(Id = ril.Id);
				updateRIL.Track_as_Asset__c = 'Closed';
				DML.updateAsUser(updateRIL);
				/*
				Fixed_Asset_Adjustment__c faa = new Fixed_Asset_Adjustment__c();
				faa.company__c = fa.company__c;
				faa.fixed_asset__c = fa.Id;
				faa.amount__c = fa.acquisition_cost__c;
				faa.type__c = 'Acquisition';
				faa.subtransaction_type__c = faa.type__c;
				faa.adjustment_date__c = system.today();
				faa.transaction_date__c = system.now();
				//faa.finalized_date__c = system.now();
				faa.currency__c = ril.supplier_invoice__r.currency__c;
				faa.units__c = fa.units__c;
				faa.Supplier_Invoice_line__c = ril.Id;
				//faa.finalized__c = true;
				faa.transaction_date__c = system.now();
				//faa.finalized_date__c = system.now();
				DML.insertAsUser(faa);
				
				faa.finalized__c = true;
				DML.updateAsUser(faa);*/
				
				
			}else if(selectedAction == 'MULTIPLE' || selectedAction == 'CUSTOM'){
				FixedAssetService.isAcqCostCalculated = TRUE;//To avoid re-calculating Acquisition cost at trigger level.
				DML.insertAsUser(fas);
				
				Supplier_Invoice_Line__c ril = updateSelectedRIL();
				//Only update what we need
				Supplier_Invoice_Line__c updateRIL = new Supplier_Invoice_Line__c(Id = ril.Id);
				updateRIL.Track_as_Asset__c = 'Closed';
				DML.updateAsUser(updateRIL);
				
			    /*
				List<Fixed_Asset_Adjustment__c> insertFAAs = new List<Fixed_Asset_Adjustment__c>();
				for(Fixed_Asset__c fa : fas){
					Fixed_Asset_Adjustment__c faa = new Fixed_Asset_Adjustment__c();
					faa.company__c = fa.company__c;
					faa.fixed_asset__c = fa.Id;
					faa.amount__c = fa.acquisition_cost__c;
					faa.type__c = 'Acquisition';
					faa.subtransaction_type__c = faa.type__c;
					faa.adjustment_date__c = system.today();
					faa.transaction_date__c = system.now();
					//faa.finalized_date__c = system.now();
					faa.currency__c = ril.supplier_invoice__r.currency__c;
					faa.units__c = fa.units__c;
					faa.Supplier_Invoice_line__c = ril.Id;
					//faa.finalized__c = true;
					faa.transaction_date__c = system.now();
					//faa.finalized_date__c = system.now();
					insertFAAs.add(faa);
				}
				DML.insertAsUser(insertFAAs);
				
				for(Fixed_Asset_Adjustment__c faa : insertFAAs){
					faa.finalized__c = true;
				}
				
				DML.updateAsUser(insertFAAs);*/
				
			}else if(selectedAction == 'ADJUST'){
                map<id,date> mFAToLastDepDate = new map<id,date>();
                set<id> FAIds = new set<id>();

                Supplier_Invoice_Line__c ril = updateSelectedRIL();
				//Only update what we need
				Supplier_Invoice_Line__c updateRIL = new Supplier_Invoice_Line__c(Id = ril.Id);
				updateRIL.Track_as_Asset__c = 'Closed';
                
				for(Fixed_Asset_Adjustment__c faa : newAdjustments){
					faa.transaction_date__c = datetime.newInstance(faa.adjustment_Date__c.year(), 
                                                                   faa.adjustment_Date__c.month(),
                                                                   faa.adjustment_Date__c.day()); 
					faa.company__c = ril.Supplier_Invoice__r.company__c;
					if(faa.Currency__c == NULL){
						faa.currency__c = ril.Accounting_Entry_Lines__r.size() > 0 ? ril.supplier_invoice__r.company__r.Comp_Currency__c : ril.supplier_invoice__r.currency__c;															  
					}
					FAIds.add(faa.Fixed_Asset__c);
				}
              
                //Grab the fixed asset ids.
                list<Fixed_Asset__c> FAs = [select id,name,Date_Last_Depreciated__c 
                                            from Fixed_Asset__c where id in :FAIds];
                for(Fixed_Asset__c FA:FAs){
                    mFAToLastDepDate.put(FA.id,FA.Date_Last_Depreciated__c);
                }

                //Check if depreciation rec already exists for the FA for the given FAA adjustment date.
 				for(Fixed_Asset_Adjustment__c faa : newAdjustments){
                    if(mFAToLastDepDate.containskey(faa.Fixed_Asset__c)){
                        if(mFAToLastDepDate.get(faa.Fixed_Asset__c)>=faa.Adjustment_Date__c){
                            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR,'The '+faa.Adjustment_Date__c+' date is invalid for the fixed asset adjustment because it is in a period that has depreciation.'));
                            return null;                      
                        }                      
                    }
				} 
				
                //Do DML Actions after adjustment date validation check.
				DML.updateAsUser(updateRIL);
				
               DML.insertAsUser(newAdjustments);
                
                system.debug(LOGGINGLEVEL.error,'inside save action before finalize:'+newAdjustments);

				for(Fixed_Asset_Adjustment__c faa : newAdjustments){
					faa.finalized__c = true;
				}
				
				DML.updateAsUser(newAdjustments);
                system.debug(LOGGINGLEVEL.error,'inside save action after finalize:'+newAdjustments);
				
				Map<Id, Fixed_Asset_Adjustment__c> mFAAs = new Map<Id, Fixed_Asset_Adjustment__c>(newAdjustments);
				//FixedAssetService.updateFixedAssetAcquisitionCost(mFAAs.keySet());
			}else{
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Label.You_have_not_selected_an_action_to_perform));
				return null;
			}
			updateReceiptInvoiceLines();
			if(selectedAction=='ADJUST'){
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.CONFIRM, Label.Successfully_added_adjustment));
			}else{
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.CONFIRM, Label.Successfully_created_new_FixedAssets));
			}
			selectedAction = null;
			renderGroupLinesButton = rils.size() > 0 && fixedAssetId == NULL;
			return null;
			//return Page.FixedAssetWorkbench;
		}catch(Exception ex){
			system.debug(logginglevel.info, 'EXCEPTION: ' + ex);
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			Database.rollback(sp);
			return null;
		}
		
	}
	
	public void saveAndMore(){
		save();
		//reset();
	}
	
	public class RILDetail{// implements Comparable
		
		public boolean selected {get;set;}
		public Supplier_Invoice_Line__c ril {get;set;}
		
		public RILDetail(){
			
		}

	}
	public void removeAdjustment(){
        newAdjustments.remove(faaAdjustmentListIndex);
    }
}