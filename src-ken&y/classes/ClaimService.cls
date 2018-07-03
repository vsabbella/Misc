global with sharing class ClaimService {
    
    //STATICS
    public static final string STATUS_NEW = 'New';
    public static final string STATUS_OPEN = 'Open';
    public static final string STATUS_CLOSED = 'Closed';
    public static final string STATUS_CANCELLED = 'Cancelled';
    
    public static final string SETTLE_SPLIT = 'Split';
    public static final string SETTLE_ADJUSTMENT = 'Adjustment';
    //public static final string SETTLE_WRITEOFF = 'Write Off';
	public static final string SETTLE_MANUAL = 'Manual';
	public static final string SETTLE_AUTO = 'Automatic';
	public static final string SETTLE_CHARGEBACK = 'Chargeback';
	public static final string SETTLE_CREDIT_CONSUME = 'Credit';
	public static final string SETTLE_CLAIM_AGAINST_CLAIM = 'Claim Against Claim';
	public static final string SETTLE_CLAIM_AGAINST_CASH = 'Payment';
	
	public static final string SOURCE_MANUAL = 'Manual'; //KNDY-15037
	public static final string SETTLEMENT_METHOD_REFUND = 'Refund'; //KNDY-15255
	public static final string SETTLEMENT_METHOD_REJECTED = 'Rejected'; // KNDY-15531
	//Specify flag to override SETTLE_AUTO with SETTLE_MANUAL in various service methods when called from UI
	public static boolean isManual = false;
	
	public class ClaimException extends Exception{}
	
	public static set<Id> claimStatusMods = new set<Id>();

	// assumption: claims are not rejected via api
	// all validations are complete
	public static void reject(List<Claim__c> claims){ // KNDY-15531
		List<Claim__c> claimsToSave = new List<Claim__c>();
		List<Claim_Line__c> cLinesToSave = new List<Claim_Line__c>();
		for (Claim__c c:claims){
			if(c.Settlement_Method__c == null || c.Settlement_Method__c == '') {
				// Claim to update
				Claim__c claim = new Claim__c ( Id = c.Id,
						 						Settlement_Method__c = ClaimService.SETTLEMENT_METHOD_REJECTED,
						 						Settlement_Date__c = date.today(),
												Status__c = ClaimService.STATUS_CLOSED,
												Enter_Claims_Notes__c = c.Enter_Claims_Notes__c,
												Resolution_Code__c = c.Resolution_Code__c);
				claimsToSave.add(claim);
				//Claim line to insert
				Claim_Line__c cl = new Claim_Line__c();
				cl.Resolution_Code__c = c.Resolution_Code__c;
				cl.Reason_Code__c = c.Resolution_Code__c;
				cl.Claim__c= c.Id;
				cl.Total_Amount__c= c.Amount__c;
				cLinesToSave.add(cl);
			}

		}
		if (claimsToSave.size() > 0){
			Savepoint sp = Database.setSavepoint();
			try{
				if (cLinesToSave.size() > 0){
					DML.insertAsUser(cLinesToSave);
				}
				DML.updateAsUser(claimsToSave);
			}catch(Exception ex){
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
				Database.rollback(sp);
				throw new ClaimException(' ' + ex.getMessage());
			}
		}
	}

	public static void resolve(set<Id> claimIds){ //OTC-511 when resolving multiple claims, claim lines must be created for each claim resolved. 
		//KNDY-15529
		set<string> errorClaims = new set<string>();
    	boolean hasError = false;
		
		Map<Id, Customer_Invoice__c> mCustInvs = new Map<Id, Customer_Invoice__c>();
		Map<Id, List<Customer_Invoice_Line__c>> mCustInvLines = new Map<Id, List<Customer_Invoice_Line__c>>();
		map<Id,list<Claim_Line__c>> mClaimLines = new map<id,list<Claim_Line__c>>();	//List<Claim_Line__c> lstClaimLines = new List<Claim_Line__c>();
		List<Claim__c> claims = returnClaimDetails(claimIds);
		for(Claim__c c : claims){
			 if (c.Source__c == ClaimService.SOURCE_MANUAL){ //KNDY-15529
				hasError = true;
				errorClaims.add(c.Name + ' - ' + Label.Cannot_Chargeback_Writeoff_Manual_Claim);
				system.debug('resolve error claims--'+errorClaims);
				continue;
			}
			else if(c.Settlement_Method__c == null || c.Settlement_Method__c == '') //OTC-647
			{
				if(c.Amount__c == null || c.Amount__c == 0) //OTC-661
					throw new ClaimException(Label.Claim_amount_cannot_be_empty_or_zero+ c.Name);
				//lstClaimLines.clear();
				c.Status__c = STATUS_CLOSED;
				c.Currently_Reopened_Flag__c = false;
				c.Settlement_Method__c = isManual ? SETTLE_MANUAL : SETTLE_AUTO;
				c.Settlement_Date__c = system.today();
				
				//Customer Invoice
				Customer_Invoice__c iCI = new Customer_Invoice__c();
				iCI.Claim__c = c.Id;
				iCI.Date_Invoiced__c = system.now();
				iCI.Status__c = 'Closed';
				iCI.Invoice_Type__c = CustomerInvoiceService.TYPE_SETTLEMENT;
				iCI.transaction_date__c = system.now();
				//iCI.Finalized__c = true;
				iCI.Bill_To_Customer__c = c.Bill_to_Customer__c;
				iCI.Company__c = c.Company__c;
				iCI.Sold_To_Customer__c = c.Sold_to_Customer__c;
				iCI.Customer__c = c.Parent_Customer__c; //OTC-656
				iCI.Amount_Paid__c =  c.Claim_Lines__r.size() == 0 ? c.Amount__c : c.Total_Line_Amount__c; //AR-80 ,AR-106
				iCI.Resolution_Code__c = c.Resolution_Code__c; //AR-58
				
				
				List<Customer_Invoice_Line__c> iCILs = new List<Customer_Invoice_Line__c>();
				List<Claim_Line__c> lstClaimLines = new List<Claim_Line__c>();
				if(c.Claim_Lines__r.size() > 0){
					//Lines found - build customer invoice lines from claim line details
					for(Claim_Line__c cl : c.Claim_Lines__r){
						if(cl.Resolution_Code__c == null){
							throw new ClaimException(Label.Update_all_claim_lines_with_a_resolution_code + ' ' + c.Name + ', '+ cl.Name);
						}
						// AR-106 should auto complete. if(c.Claim_Balance__c != 0){
			            	//throw new ClaimException(Label.Balance_must_be_zero_before_you_resolve_this_claim +  c.Name);	
			           // }
						Customer_Invoice_Line__c iCIL = new Customer_Invoice_Line__c();
						iCIL.Company__c = c.Company__c;
						iCIL.Unit_Price__c = cl.Total_Amount__c;
						iCIL.Quantity_Shipped__c = 1;
						iCIL.Extended_Price__c = iCIL.Unit_Price__c * iCIL.Quantity_Shipped__c;
						iCIL.Product__c = cl.Customer_Invoice_Line__r.Product__c;
						iCIL.Claim_Line__c = cl.Id;
						iCILs.add(iCIL);
					}
				}else{
					if(c.Resolution_Code__c == null){
						throw new ClaimException(Label.Update_this_claim_with_a_resolution_code  + c.Name);
					}
					//No line found - default to single customer invoice line
					Customer_Invoice_Line__c iCIL = new Customer_Invoice_Line__c();
					iCIL.Company__c = c.Company__c;
					iCIL.Unit_Price__c = c.Amount__c;
					iCIL.Quantity_Shipped__c = 1;
					iCIL.Extended_Price__c = iCIL.Unit_Price__c * iCIL.Quantity_Shipped__c;
					iCILs.add(iCIL);
					
					
					Claim_Line__c cl = new Claim_Line__c();
	    			cl.Resolution_Code__c = c.Resolution_Code__c;
	    			cl.Reason_Code__c = c.Resolution_Code__c;
	    			cl.Claim__c= c.Id;
	    			cl.Total_Amount__c= iCIL.Extended_Price__c;
					lstClaimLines.Add(cl);
					
					
									
				}
				if(!lstClaimLines.isEmpty()) //OTC-511
					mClaimLines.put(c.Id,lstClaimLines);
				
				mCustInvs.put(c.Id, iCI);
				mCustInvLines.put(c.Id, iCILs);
			}
			
		}
		if(hasError){//KNDY-15529
    		string errorMsg = string.join(new List<string>(errorClaims), ', ');
    		system.debug('resolve errorMsg=='+errorMsg);
            throw new ClaimException(errorMsg);
    	}
		Savepoint sp = Database.setSavepoint();
		try{
			DML.insertAsUser(mCustInvs.values());
			//List<Customer_Invoice_Line__c> insertCILs = new List<Customer_Invoice_Line__c>();
			for(Claim__c c : claims){
				
				if(mCustInvs.containsKey(c.Id) && mCustInvLines.containsKey(c.Id)){
					
					for(Customer_Invoice_Line__c cil : mCustInvLines.get(c.Id)){
						
						cil.Customer_Invoice__c = mCustInvs.get(c.Id).Id;
						//insertCILs.add(cil);
						mCustInvs.get(c.Id).finalized__c = true;
					}
				}
			}
			list<Customer_Invoice_Line__c> CILs = new list<Customer_Invoice_Line__c>();
			for(list<Customer_Invoice_Line__c> lists : mCustInvLines.values())
				CILs.addAll(lists);
			DML.insertAsUser(CILs);
			DML.updateAsUser(mCustInvs.values());
			
			
			for(Id claimId : mClaimLines.keyset()) //OTC-511
			{
				if(mCustInvLines.containsKey(claimId))
				{
					mClaimLines.get(claimId)[0].Customer_Invoice_Line__c = mCustInvLines.get(claimId)[0].Id;
					mClaimLines.get(claimId)[0].Customer_Invoice__c = mCustInvLines.get(claimId)[0].Customer_Invoice__c;
				}
			}
			list<Claim_Line__c> claimLines = new list<Claim_Line__c>();
			for(list<Claim_Line__c> lists : mClaimLines.values())
				claimLines.addAll(lists);
			DML.insertAsUser(claimLines);
			
			DML.updateAsUser(claims); //update Claims in the end. 
			
		}catch(Exception ex){
			system.debug('EXCEPTION: ' + ex);
			Database.rollback(sp);
			throw new ClaimException(' ' + ex.getMessage());
		}
		
	}
    
    
    public static void finishSplit(set<Id> claimIds){
        
        List<Claim__c> claims = returnClaimDetails(claimIds);
        List<AggregateResult> arClaims = [SELECT related_claim__c relatedClaimId, SUM(Amount__c) totalAmount
                                            FROM Claim__c
                                            WHERE related_claim__c IN :claimIds
                                            GROUP BY related_claim__c];
       
           for(Claim__c c :[SELECT related_claim__c ,related_claim__r.amount__c  ,amount__c 
                                            FROM Claim__c 
                                            WHERE related_claim__c IN :claimIds]){
  if((c.related_claim__r.amount__c <0 && c.amount__c>0 )||(c.related_claim__r.amount__c >0 && c.amount__c < 0) ){
	 throw new ClaimException(Label.Claim_amount_cannot_be_split_using_reverse_amounts +' ('+ c.amount__c+' => ' +c.related_claim__r.Amount__c + ')' );
	return;
			}               	
                                            	
         }
                                            
        Map<Id, Decimal> mTotalSplits = new Map<Id, Decimal>();
        for(AggregateResult ar : arClaims){
            mTotalSplits.put((Id)ar.get('relatedClaimId'), (decimal)ar.get('totalAmount'));
        }
        
        for(Claim__c c : claims){
            if(mTotalSplits.containsKey(c.Id)){
                if(c.Amount__c == mTotalSplits.get(c.Id)){
                    c.Status__c = STATUS_CLOSED;
                    c.Settlement_Method__c = SETTLE_SPLIT;
                    c.Settlement_date__c = system.today();
                    c.Currently_Reopened_Flag__c = false;
                }else{
                    throw new ClaimException(Label.Total_split_amount_doesnot_equal_to_claim_amount+' ' + c.Name +', '+ mTotalSplits.get(c.Id) + ' / ' + c.Amount__c );
                }
            }else{
                throw new ClaimException(Label.There_are_no_related_claims_for+' ' + c.Name);
            }
        }
        
        DML.updateAsUser(claims);
                                            
    }
    
    public static void undoSplit(set<Id> claimIds){
        
        boolean hasError = false;
        set<string> errorClaims = new set<string>();
        
        List<Claim__c> relatedClaims = [SELECT Id, Name, Status__c,
                                            (SELECT Id, Name, Status__c
                                            FROM Customer_Invoices__r WHERE Status__c <> :STATUS_CANCELLED)
                                        FROM Claim__c 
                                        WHERE Related_Claim__c IN :claimIds];
                                        
        for(Claim__c c : relatedClaims){
            if(c.status__c == STATUS_CLOSED){
                hasError = true;
                errorClaims.add(c.Name + ' - '+ Label.Cannot_undo_a_split_if_related_claims_have_been_closed);
            }
            if(c.Customer_Invoices__r.size() > 0){
                hasError = true;
                errorClaims.add(c.Name + ' - '+ Label.Cannot_undo_a_split_if_related_claims_have_settlement_invoice);
            }
        }
        
        if(hasError){
            string errorMsg = string.join(new List<string>(errorClaims), ', ');
            throw new ClaimException(errorMsg);
        }
        
        List<Claim__c> claims = returnClaimDetails(claimIds);
        for(Claim__c c : claims){
            c.Status__c = STATUS_OPEN;
            c.Settlement_Date__c = null;
            c.Settlement_Method__c = null;
            c.Currently_Reopened_Flag__c = true;
            
        }
        
        Savepoint sp = Database.setSavePoint();
        try{
            DML.deleteAsUser(relatedClaims);
            DML.updateAsUser(claims);
        }catch(Exception ex){
            database.rollback(sp);
            throw new ClaimException(ex.getMessage());
        }
        
    }
    
    	public static Exception getClaimReopenException_SettlementTypeRefund(Set<Id> claimIds){ //KNDY-15255
		set<string> errorClaims = new set<string>();
		Exception ex; 
		List<Claim__c> claims = returnClaimDetails(claimIds); 
		for (Claim__c c: claims){
			if (c.Settlement_Method__c == SETTLEMENT_METHOD_REFUND){
    				String msg = Label.You_can_t_reopen_a_claim_with_a_refund_settlement_method;
    				String crLinks = '';
    				List<Customer_Receipt__c> crs = c.Customer_Receipts__r;
    				if (crs != null && crs.size() > 0){
    					for (Customer_Receipt__c cr: crs){
    						String link = '<a href="/'+cr.Id+'">' +cr.Name + '</a>';
    						crLinks += ' ' + link + ',';
    					}
    					crLinks = crLinks.removeStart(' ');
    					crLinks = crLinks.removeEnd(',');
    					msg += ' You must cancel or void the ';
    					msg += crLinks;
    					msg += ' refund receipt to automatically reopen the claim.';
    				}
    				errorClaims.add( c.Name+ ' '+ msg);
			}
    		}
    		if (errorClaims.size() > 0){
    			string errorMsg = string.join(new List<string>(errorClaims), ', ');
    			ex =  new ClaimException(errorMsg);
    		}
    		return ex;
	}
	
    //KNDY-2721 - Re-open a claim
    public static void reopen(set<Id> claimIds){
    	
    	set<string> errorClaims = new set<string>();
    	boolean hasError = false;
    	
    	List<Claim__c> claims = returnClaimDetails(claimIds); 
    	set<Id> againstClaimIds = new set<id>();
    	//If we reopen the main Claim that settles x other claims, then those x claim should be reopened too. So we grab their details too and add them to the main claim list
    	for(Claim__c c : claims)
    		for(Claim_Line__c cl : c.Claim_Lines__r) 
    			if(cl.Settling_Claim__c != null)
    				againstClaimIds.add(cl.Settling_Claim__c);
    	if(!againstClaimIds.isEmpty())
    		claims.addAll(returnClaimDetails(againstClaimIds));
    		
    		
    	List<Claim__c> relatedClaims = new List<Claim__c>();
    	list<Claim_Line__c> deleteLines =  new list<Claim_Line__c>();
    	List<Customer_Invoice__c> relatedCustInvoices = new List<Customer_Invoice__c>();
    	List<Customer_Invoice__c> updateSettlementCIs = new List<Customer_Invoice__c>();
    	set<Id> custInvIds = new set<Id>();
    	
    	for(Claim__c c : claims){
    		
    		if(c.Status__c != STATUS_CLOSED){
    			hasError = true;
		 		errorClaims.add(Label.Claim_not_closed_and_cannot_be_reopened + c.Name);
		 		continue;
    		}
    		//OTC-167 - A closed claim using "Split" should not reopened using Reopen button.
            if (c.Related_Claims__r.size() > 0 && c.Settlement_Method__c == SETTLE_SPLIT){
                hasError = true;
                errorClaims.add(Label.Cannot_reopen_a_closed_claim_use_UndoSplit_feature);
                continue;
            }
    		if(c.Status__c == STATUS_CANCELLED)
    		{
    			hasError = true;
    			errorClaims.add('Claim is cancelled and cannot be reopened.' + c.Name);
		 		continue;
    		}
    		
    		//This is to ensure that if the claim being settled against is reopened directly we block it. Please refer to comments on settleClaims method for detailed explaantion. 
    		if(c.Settlement_Method__c == SETTLE_CLAIM_AGAINST_CLAIM && claimIds.contains(c.Id) && c.Settled_Against_Claim__c != null) {
    			hasError = true;
    			String link = '<a href="/'+c.Settled_Against_Claim__c+'">' + c.Settled_Against_Claim__r.Name + '</a>';
    			errorClaims.add( c.Name+ Label.Claim_Against_Claim_Cannot_Reopen +link);
		 		continue;
    		}
    		c.Status__c = STATUS_OPEN;
    		c.Settlement_Method__c = null;
    		c.Settlement_Date__c = null;
            c.Resolution_Code__c = null;
            c.Settled_Against_Claim__c = null; //KNDY-7740
            c.Currently_Reopened_Flag__c = true;
    		c.Ready__c = false; //OTC-680 so that the process automation doesnt re-close it.
    		
    		//Check if any child related Claims have already been closed.
    		for(Claim__c cc : c.Related_Claims__r){
			 	if(cc.Status__c == STATUS_CLOSED){
			 		hasError = true;
			 		errorClaims.add(Label.Claim_cannot_be_reversed_because_it_has_related_claim_that_is_closed + c.Name + ', ' + cc.Name );
				 }else{
			 		//Add related claim to list, will be deleted later if no errors are found
			 		relatedClaims.add(cc);
			 	}
			}
    		
    		
    		//Collect related Settlements
    		for(Customer_Invoice__c ci : c.Customer_Invoices__r){
    			//OTC-159 A chargeback claim with a closed related Invoice cannot be reopened.
    			if(ci.Status__c == CustomerInvoiceService.STATUS_CLOSED && ci.Invoice_Type__c == CustomerInvoiceService.TYPE_CHARGEBACK)
    			{
    				hasError = true;
    				errorClaims.add(Label.Cannot_reopen_claim_as_related_Customer_Invoice_has_been_closed+' '+c.Name);
    			}
    			else if(ci.Status__c != CustomerInvoiceService.STATUS_CANCEL && !ci.Void__c){ //AR-75 we do no want to unfinalize void CIs (look at CRService.onVoid method)
	    			custInvIds.add(ci.Id);
	    			if(ci.Invoice_Type__c == CustomerInvoiceService.TYPE_SETTLEMENT)
	    			{
	    				//ci.Amount_Paid__c = 0; //AR-87, since cannot unfinalize paid invoices, need to first update the settlement invoices with amt paid = 0 --> CI is open
	    				updateSettlementCIs.add(new Customer_Invoice__c(Id = ci.Id, Amount_Paid__c = 0));
	    			}
	    			relatedCustInvoices.add(ci);
    			}
    		}
    		
    		//AR-165
    		for(Customer_Receipt_Line__c crl :c.Customer_Receipt_Lines__r)
    			if(crl.Finalized__c && !crl.Customer_Receipt__r.Void__c)
    				throw new ClaimException('Cannot reopen claim as it is tied to a Customer Receipt '+'<a href="/'+crl.Customer_Receipt__c+'">' + crl.Customer_Receipt__r.Name + '</a>'+'. Please click on the link and unfinalize/void/cancel the CR to reopen it');
    		
    		for(Claim_Line__c cl : c.Claim_Lines__r)
    			deleteLines.add(cl);
    	}
    	
    	
    	
    	if(hasError){
            string errorMsg = string.join(new List<string>(errorClaims), ', ');
            throw new ClaimException(errorMsg);
        }									
    	
    	Savepoint sp = Database.setSavepoint();
    	try{
    		
    		system.debug('update CIs: '+updateSettlementCIs);
    		if(!updateSettlementCIs.isEmpty())
    			DML.updateAsUser(updateSettlementCIs);
    	    
    	   //CANCEL or VOID Invoices
    	   list<Customer_Invoice__c> invoicesToCancel = new list<Customer_Invoice__c>();
    	   list<Customer_Invoice__c> invoicesToVoid = new list<Customer_Invoice__c>();
    	  
    	   for(Customer_Invoice__c ci : [select Id, Name, Status__c , Posting_Date__c ,Finalized__c ,Transaction_Date__c,Finalized_Date__c,Void__c,Historical__c,Void_Date__c, 
    	    												  (select id, name from Accounting_Entries__r  where status__c = 'Active' and Has_Exceptions__c != true) from Customer_Invoice__c where id in :relatedCustInvoices])
    	    
    	   {
    	    	
    	    	if(!ci.Accounting_Entries__r.isEmpty())
    	    		invoicesToVoid.add(ci);
    	    	else
    	    		invoicesToCancel.add(ci);
    	   }
    	   system.debug('invoicesToCancel '+invoicesToCancel);
    	   system.debug('invoicesToVoid '+invoicesToVoid);
    	   if(!invoicesToVoid.isEmpty()) {
	    	   	VoidCancelService vcS  = new CustomerInvoiceVoidCancelService(invoicesToVoid);
	    	   	list<String> messages = new list<String>();
				for(VoidCancelService.VoidCancelResponse response : vcS.voidSourceDocuments(invoicesToVoid).values())
				{
					if(!response.success)
					{
						messages.addAll(response.messages);
						
					}
				}
	    	
				if(!messages.isEmpty())
					throw new ClaimException(String.join(messages,','));
    	   }
	    	
    	   if(!invoicesToCancel.isEmpty()) {
	    	   	VoidCancelService vcS  = new CustomerInvoiceVoidCancelService(invoicesToCancel);
	    	   	list<String> messages = new list<String>();
				for(VoidCancelService.VoidCancelResponse response : vcS.cancelSourceDocuments(invoicesToCancel).values())
				{
					if(!response.success)
	    	{
						messages.addAll(response.messages);
						
		    		}
		    	}
				
				if(!messages.isEmpty())
					throw new ClaimException(String.join(messages,','));
	    	}
	    	
	    	DML.updateAsUser(claims);
	    	if(!deleteLines.isEmpty())
	    		DML.deleteAsUser(deleteLines);
	    	
	    	DML.deleteAsUser(relatedClaims);	
	    	//DML.deleteAsUser(relatedCustReceipts);
	    	
    	}catch(Exception ex){
    		system.debug('Claim reopen exception: '+ex.getMessage());
    		database.rollback(sp);
    		throw ex;
    	}
    }
    
    public static Map<Id, Customer_Invoice__c> chargeback(set<Id> claimIds){
    	
    	set<string> errorClaims = new set<string>();
    	boolean hasError = false;
    	List<Claim__c> claims = returnClaimDetails(claimIds);
    	Map<Id, Customer_Invoice__c> mChargebacks = new Map<Id, Customer_Invoice__c>();
    	List<Customer_Invoice_Line__c> chargebackLines = new List<Customer_Invoice_Line__c>();
    	Map<Id, Claim_Line__c> mClaimLine = new Map<Id, Claim_Line__c>();
    	
    	//Loop through the claims - create the chargeback headers, and default any claim lines where missing
    	for(Claim__c c : claims){
    		
    		if(c.status__c == STATUS_CLOSED || c.status__c == STATUS_CANCELLED){
                hasError = true;
                errorClaims.add(c.Name + ' - ' + Label.Claim_is_closed);
                continue;
    		}else if (c.Source__c == ClaimService.SOURCE_MANUAL){ //KNDY-15529
				hasError = true;
				errorClaims.add(c.Name + ' - ' + Label.Cannot_Chargeback_Writeoff_Manual_Claim);
				continue;
			}
    		else{
    			
    			c.Status__c = STATUS_CLOSED;
    			c.Currently_Reopened_Flag__c = false;
    			c.Settlement_Method__c = SETTLE_CHARGEBACK;
    			c.Settlement_Date__c = system.today();
    			
    			Customer_Invoice__c iCB = new Customer_Invoice__c();
    			if(c.Bill_to_Customer__c != null){
    				iCB.Bill_To_Customer__c = c.Bill_to_Customer__c;
    			}
    			//OTC-244 IF Claim doesnt have a bill to, then ensure it has a parent customer and assign that to CI, if no Parent Customer on Claiim, then throw an error. 
    			else if(c.Parent_Customer__c != null)
    			{
    				iCB.Customer__c = c.Parent_Customer__c;
    			}
    			else{
    				hasError = true;
                	errorClaims.add('Claim must have parent customer to create an invoice.' + c.Name );
                	continue;
    			}
    			
    			iCB.Company__c = c.Company__c;
    			iCB.Invoice_Type__c = CustomerInvoiceService.TYPE_CHARGEBACK;
    			iCB.Sold_to_Customer__c = c.Sold_to_Customer__c;
    			iCB.Claim__c = c.Id;
    			iCB.Currency__c = c.Currency__c;
    			iCB.Date_Invoiced__c = system.now();
    			iCB.transaction_date__c = system.now();
				iCB.Memo__c = c.Reference__c;//KNDY-18766
    			system.debug('ICB Amount_Paid__c'+ iCB.Amount_Paid__c);
    			mChargebacks.put(c.Id, iCB);
    			
    			if(c.Claim_Lines__r.size() == 0){
    				Claim_Line__c iCL = new Claim_Line__c();
    				iCL.Claim__c = c.Id;
    				iCL.Total_Amount__c = c.Amount__c;
    				iCL.Resolution_Code__c = c.Resolution_Code__c;
    				mClaimLine.put(c.Id, iCL);
    			}
    		}
    	}
    	
    	if(hasError){
    		string errorMsg = string.join(new List<string>(errorClaims), ', ');
            throw new ClaimException(errorMsg);
    	}
    	
    	Savepoint sp = Database.setSavepoint();
    	try{
	    	//DML.insertAsUser(mChargebacks.values());
	    	DML.insertAsUser(mClaimLine.values());
	    	DML.insertAsUser(mChargebacks.values());
	    	//DML.insertAsUser(mClaimLine.values());
	    	//Loop back through the claims, create the lines and assign to their corresponding headers and claim lines
	    	for(Claim__c c : claims){
	    		if(mChargebacks.containsKey(c.Id)){
	    			
	    			List<Customer_Invoice_Line__c> mCILs = new List<Customer_Invoice_Line__c>();
	    			List<Claim_Line__c> claimLines = new List<Claim_Line__c>();
	    			
	    			if(c.Claim_Lines__r.size() > 0){
	    				claimLines = c.Claim_Lines__r;
	    			}else if(mClaimLine.containsKey(c.Id)){
	    				claimLines = new List<Claim_Line__c>{mClaimLine.get(c.Id)};
	    			}
	    			
	    			if(!claimLines.isEmpty())
	    			{
	    				for(Claim_Line__c cl : claimLines){
		    				Customer_Invoice_Line__c iCIL = new Customer_Invoice_Line__c();
		    				iCIL.Customer_Invoice__c  = mChargebacks.get(c.Id).Id;
		    				iCIL.Claim_Line__c = cl.Id;
		    				iCIL.Quantity_Shipped__c = 1;
		    				iCIL.Unit_Price__c = cl.Total_Amount__c;
		    				iCIL.Company__c = c.Company__c;
		    				iCIL.Product__c = cl.Customer_Invoice_Line__r.Product__c;
		    				iCIL.Sales_Order_Line__c = cl.Customer_Invoice_Line__r.Sales_Order_Line__c;
		    				iCIL.Sales_Order__c = cl.Customer_Invoice_Line__r.Sales_Order__c;
		    				chargebackLines.add(iCIL);
		    			}
	    			}
	    			else //OTC-679, if no claim lines, then create one CIL from claim data. 
	    			{
	    				chargebackLines.add(new Customer_Invoice_Line__c(Customer_Invoice__c  = mChargebacks.get(c.Id).Id,Quantity_Shipped__c = 1, Unit_Price__c = c.Amount__c));
	    			}
	    			
	    			mChargebacks.get(c.Id).finalized__c = true;
	    		}
	    		
	    	}
	    	

    		DML.insertAsUser(chargebackLines);
    		//update invoice header to set to finalized
    		DML.updateAsUser(mChargebacks.values());

    		DML.updateAsUser(claims);
    		
    		return mChargebacks;
    		
    	}catch(Exception ex){
    		database.rollback(sp);
    		throw ex;
    	}
    	
    }
    /*
    The credit method will collect a set of claims and Invoices and tie them to a single CR, 
    The outer set is a collection of each credit scenario, while the inner set represents claims that will be tied to each Custoemr Receipt
    This method will only create the CRs, the act of finalizing the CR will close the claim. 
    */



	public static list<Customer_Receipt__c> credit2(map<id, list<RefundCreditService.InvoiceCreditsWrapper>> claim2InvoiceWrappers ) {

		map<Id,Claim__c> mClaims = new map<Id,Claim__c>(returnClaimDetails(claim2InvoiceWrappers.keyset()));
		list<Claim_Line__c> lClaimLines = new list<Claim_Line__c>();
		map<Id,Customer_Receipt__c> mCRs = new map<Id,Customer_Receipt__c>();
		map<Id, list<Customer_Receipt_Line__c>> mCRLs = new map<Id, list<Customer_Receipt_Line__c>>();
		if(claim2InvoiceWrappers.isEmpty())
			return null;

		for(Id claimId : claim2InvoiceWrappers.keySet()) {

			//BUILD CR
			Claim__c c = mCLaims.get(claimId);
			list<RefundCreditService.InvoiceCreditsWrapper> wrappers = claim2InvoiceWrappers.get(claimId);
			mCRs.put(c.ID, new Customer_Receipt__c(Type__c = CustomerReceiptService.TYPE_CLAIM_SETTLEMENT, Company__c = c.Company__c,
					Customer__c = c.Bill_to_Customer__c != null ? c.Bill_to_Customer__c : c.Parent_Customer__c,
					amount_received__c = 0, Date_Received__c = system.now(),Currency__c = c.Currency__c));


			Double amountCRL_Claim = 0;
			list<Customer_Receipt_Line__c> lCRLs = new list<Customer_Receipt_Line__c>();

			//BUILD CL and CRL
			for(RefundCreditService.InvoiceCreditsWrapper wrapper : wrappers) {
				lClaimLines.add(new CLaim_Line__c(Claim__c = claimId, Total_Amount__c = wrapper.refundAmount, Customer_Invoice__c = wrapper.cusInv.Id));
				//BUILD CRL FOR EACH INVOICE, ADD MEMO
				lCRLs.add(new Customer_Receipt_Line__c(Amount__c = wrapper.refundAmount,
						Customer_Invoice__c = wrapper.cusInv.Id, Memo__c = wrapper.cusInv.Memo__c,
						Type__c = getCreditMemoCRLType(wrapper.cusInv)));
				amountCRL_Claim += wrapper.refundAmount;
			}
			//BUILD ONE CRL FOR THE CLAIM, AMOUNT IS TOTAL AGAINST CIs
			lCRLs.add(new Customer_Receipt_Line__c(Amount__c = amountCRL_Claim,
					Claim__c = claimId,
					Type__c = PaymentService.TYPE_DEBIT_CLAIM));

			mCRLs.put(claimId, lCRLs);

		}

		system.debug(LoggingLevel.Error,'mCRs '+mCRs);
		system.debug(LoggingLevel.Error,'mCRLs '+mCRLs);


		//NOW LETS COMMIT TO DB
		if(!mCRs.isEmpty())
			DML.insertAsUser(mCRs.values());
		if(!lClaimLines.isEmpty())
			DML.insertAsUser(lClaimLines);

		list<Customer_Receipt_Line__c> masterCRLs = new list<Customer_Receipt_Line__c>();
		for(Id claimId : mCRLs.keySet()) {
			for(list<Customer_Receipt_Line__c> crls : mCRLs.values()) {
				for(Customer_Receipt_Line__c crl : crls)
					crl.Customer_Receipt__c = mCRs.get(claimId).Id;
				masterCRls.addAll(crls);
			}
		}
		if(!masterCRLs.isEmpty()) {
			DML.insertAsUser(masterCRLs);
		}

		for(Customer_Receipt__c cr : mCRs.values()) {
			cr.Finalized__c = true;
		}

		DML.updateAsUser(mCRs.values());



		return mCRs.values();
	}

    // Assumption: parameter is not null and has customer invoice details
    private static String getCreditMemoCRLType(Customer_Invoice__c ci){
        String crlType = '';
        if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){
            crlType = PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED;
        }
        else if (ci.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT){ //KNDY-16069
                crlType = PaymentService.TYPE_PREPAYMENT_CREDIT;
		}
		else if (ci.Invoice_Type__c == PaymentService.TYPE_OVERPAYMENT){//KNDY-16069
			crlType = PaymentService.TYPE_OVERPAYMENT_CREDIT;
		}
		else{
			crlType = PaymentService.TYPE_CREDIT_MEMO;
		}

        return crlType;
    }
    
    public static void consumeCredit(set<Id> claimIds){
        List<Claim__c> claims = returnClaimDetails(claimIds);
        set<Id> creditMemoIds = new set<Id>();
        Map<Id, Customer_Receipt__c> mCustReceipts = new Map<Id, Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> insertCustReceiptLines = new List<Customer_Receipt_Line__c>();
        
        for(Claim__c c : claims){
            
            Customer_Receipt__c iCR = new Customer_Receipt__c();
            
            //if(c.amount__c <= 0){
                //TODO: Verbiage
            //    throw new ClaimException(c.Name + ' must have a claim amount greater than zero if attempting to consume a credit.');
            //}
            
            if((c.claim_balance__c) != 0){
                throw new ClaimException(c.Name + Label.Must_have_a_balance_of_zero);
            }
            
            if(c.Bill_To_Customer__c != null){
                iCR.Customer__c = c.Bill_To_Customer__c;
            }else if(c.Parent_Customer__c != null){
                iCR.Customer__c = c.Parent_Customer__c;
            }else{
                throw new ClaimException(c.Name + Label.Requires_either_Parent_or_BillToCustomer);
            }
            
            iCR.Company__c = c.Company__c;
            iCR.amount_received__c = 0;
            iCR.Date_Received__c = c.claim_date__c;
            iCR.Currency__c = c.Currency__c;
            iCR.transaction_date__c = DateTime.newInstance(c.claim_date__c.year(), c.claim_date__c.month(), c.claim_date__c.day());
            iCR.Claim__c = c.Id;
            
            mCustReceipts.put(c.Id, iCR);
            
        }
        
        Savepoint sp = Database.setSavepoint();
        try{
            DML.insertAsUser(mCustReceipts.values());
            
            for(Claim__c c : claims){
                
                if(mCustReceipts.containsKey(c.Id)){
                
                    for(Claim_Line__c cl : c.Claim_Lines__r){
                        
                        if(cl.Customer_Invoice__c == null){
                            //KNDY-4971
                            throw new ClaimException(cl.Name+Label.CannotCreditClaim_NoCI);
                        }
                        
                        //if(cl.Customer_Invoice__r.Balance__c >= 0){
                        	//KNDY-4971
                            //throw new ClaimException('Claim Line ' + cl.Name + ' on Claim ' + c.Name + ' is referencing a Credit Memo without an available balance.');
                        //}
                        
                        Customer_Receipt_Line__c iCRL = new Customer_Receipt_Line__c();
                        iCRL.Amount__c = math.abs(cl.Total_Amount__c);
                        if (cl.Total_Amount__c > 0){
                            iCRL.Type__c = PaymentService.TYPE_DEBIT_MEMO;
                        } else {
                            iCRL.Type__c = PaymentService.TYPE_CREDIT_MEMO;
                        }
                        iCRL.Customer_Invoice__c = cl.Customer_Invoice__c;//KNDY-13995
                        iCRL.Customer_Receipt__c = mCustReceipts.get(c.Id).Id;
                        iCRL.Claim__c = c.Id; //AR-7
                        creditMemoIds.add(cl.Customer_Invoice__c);
                        
                        insertCustReceiptLines.add(iCRL);
                    }       
                    mCustReceipts.get(c.Id).finalized__c = true;      
                }
                c.Status__c = STATUS_CLOSED;
                c.Settlement_Date__c = system.today();
                c.Settlement_Method__c = SETTLE_CREDIT_CONSUME;
            }
            
            DML.insertAsUser(insertCustReceiptLines);
            system.debug(logginglevel.info,'after inserting the CR Lines');
            DML.updateAsUser(mCustReceipts.values());
            system.debug(logginglevel.info,'after updating the CR headers');
            DML.updateAsUser(claims);
            system.debug(logginglevel.info,'after updating the claims:'+claims);
            
            //CustomerInvoiceService cis = new CustomerInvoiceService();
            //cis.updateCreditMemoBalance(creditMemoIds);
           //suminvoicepmts? 
        }catch(Exception ex){
            Database.rollback(sp);
            throw ex;
        }
    }
    
    
    public static void createClaims(list<Customer_Receipt_Line__c> paymentLines){
        //OTC-830 now need to map bill to and sold to from receipt lines to claims if info provided. 
		SoqlUtil soql = new SoqlUtil('Customer_Receipt_Line__c', true);
		soql.addFields(new set<String>{'Id', 'Customer__c','Customer__r.Top_Parent_Customer__c', 'Sold_To_Customer__c', 'Customer_Receipt__r.Currency__c', 'Customer_Receipt__r.Company__c',
				'Customer_Invoice__c', 'Customer_Invoice__r.Sold_to_Customer__c',
				'Customer_Invoice__r.Bill_To_Customer__c',
				'Customer_Invoice__r.Sold_to_Customer__r.Top_Parent_Customer__c',
				'Customer_Invoice__r.Bill_to_Customer__r.Top_Parent_Customer__c',
				'Customer_Receipt__r.Date_Received__c', 'Customer_Receipt__c',
				'Customer_Receipt__r.Customer__c', 'Customer_Receipt__r.Customer__r.Top_Parent_Customer__c', 'Customer_Receipt__r.Customer__r.RecordType.developername',
				'Reason_Code__c', 'Reason_Code__r.Name',
				'Reason_Code__r.Category__c', 'Reason_Code__r.Subcategory__c',
				'Customer_Receipt__r.Amount_Received__c',
				'Reference__c', 'Invoice_Amount__c', 'Payment_Amount__c', 'Type__c','Notes__c'});
		soql.setWhereClause('Id IN :paymentLines');


		Map<Id, Customer_Receipt_Line__c> mPaymentLines = new Map<Id, Customer_Receipt_Line__c>((list<Customer_Receipt_line__c>) Database.query(soql.getQuery()));
                                                                
        Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>();
        Map<Id, List<Claim_Line__c>> mClaimLines = new Map<Id, List<Claim_Line__c>>();
        
        for(Customer_Receipt_Line__c pl : paymentLines){
            if(pl.Type__c.contains('Deduction')){
                Claim__c iClaim = new Claim__c();
                iClaim.Customer_Receipt_Line__c = pl.Id;
                iClaim.Status__c = ClaimService.STATUS_NEW;
                iClaim.Amount__c = pl.Amount__c;
                iClaim.Customer_Receipt__c = pl.Customer_Receipt__c;
                iClaim.Source__c = pl.Type__c;
                if(mPaymentLines.containsKey(pl.Id)){
                    Customer_Receipt_Line__c iPayment = mPaymentLines.get(pl.Id);
                    system.debug('reciept line: '+iPayment);
                    iClaim.Company__c = iPayment.Customer_Receipt__r.Company__c;
                    if(iPayment.Customer_Invoice__c != null){ //this for Invoice Deduction
	                    iClaim.Sold_To_Customer__c = iPayment.Customer_Invoice__r.Sold_To_Customer__c;
	                    iClaim.Bill_To_Customer__c = iPayment.Customer_Invoice__r.Bill_To_Customer__c;
	                    
	                    iClaim.Parent_Customer__c = iPayment.Customer_Invoice__r.Bill_To_Customer__r.Top_Parent_Customer__c == null ? iPayment.Customer_Invoice__r.Bill_To_Customer__r.Parent_Customer__r.Parent_Customer__c : 
	                    iPayment.Customer_Invoice__r.Bill_To_Customer__r.Top_Parent_Customer__c; 
                    }else{
                    	//OTC-830 Gen Deduction. 
                    	if(iPayment.Customer__c != null)
                    	{
                    		iClaim.Bill_To_Customer__c = iPayment.Customer__c;
                    		iClaim.Parent_Customer__c = iPayment.Customer__r.Top_Parent_Customer__c;
                    	}	
                    	if(iPayment.Sold_To_Customer__c != null)
                    		iClaim.Sold_To_Customer__c = iPayment.Sold_To_Customer__c;
                    	
                    	if(String.isEmpty(iClaim.Bill_To_Customer__c))
                    	{
                    		if(iPayment.Customer_Receipt__r.Customer__r.RecordType.developername == 'Corporate_Parent'){
                    			iClaim.Parent_Customer__c = iPayment.Customer_Receipt__r.Customer__c;
	                    	}else if(iPayment.Customer_Receipt__r.Customer__r.RecordType.developername == 'Bill_To'){
	                    		iClaim.Bill_To_Customer__c = iPayment.Customer_Receipt__r.Customer__c;
	                    		iClaim.Parent_Customer__c = iPayment.Customer_Receipt__r.Customer__r.Top_Parent_Customer__c;
	                    	}
                    	}
                    	
                    }
                    iClaim.Currency__c = iPayment.Customer_Receipt__r.Currency__c;
                    iClaim.Claim_Date__c = iPayment.Customer_Receipt__r.Date_Received__c.date();
                    iClaim.Aging_Date__c = iPayment.Customer_Receipt__r.Date_Received__c.date();
                    iClaim.AR_Reason_Code__c = iPayment.Reason_Code__c;
                    iClaim.Payment_Amount__c = iPayment.Customer_Receipt__r.Amount_Received__c;
                    iClaim.Payment_Date__c = iPayment.Customer_Receipt__r.Date_Received__c.date();
                    iClaim.Customer_Invoice__c = iPayment.Customer_Invoice__c;
                    iClaim.Reference__c = iPayment.Reference__c;
					iClaim.Enter_Claims_Notes__c = iPayment.Notes__c;
                    iClaim.Type__c = iPayment.Reason_Code__r.Category__c;
                    iClaim.Subtype__c = iPayment.Reason_Code__r.Subcategory__c;
                   //JIRA OTC-318. Calim.Correspondent is poulated from ParentCompany.Claim_Coresspondent. 
                   /* if(iClaim.ownerId != null && string.valueOf(iClaim.ownerId.getsObjectType()) == 'User'){  
                        iClaim.Correspondant__c = iClaim.ownerId;
                    }else{
                        iClaim.Correspondant__c = userInfo.getUserId();
                    }*/
                    }
                
                system.debug('Claim: '+iClaim);
                mClaims.put(pl.Id, iClaim);
            }
        }
        
        if(mClaims.values().size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                DML.insertAsUser(mClaims.values());
            }catch(Exception ex){
                Notify.chatterOnMe( new ClaimService(), 
                                    new List<Notify.Message>{new Notify.Message(' ', ex.getMessage())});
                system.debug('EXCEPTION: ' + ex);
                Database.rollback(sp);
                throw new ClaimException(' ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            }
        }
        
    }
    
    public static void createClaimLines(set<Id> claimIds){
        
        List<Claim_Line__c> insertClaimLines = new List<Claim_Line__c>();
        List<Claim__c> claims = returnClaimDetails(claimIds);
        List<Claim__c> processClaims = new List<Claim__c>();
        set<Id> custInvIds = new set<Id>();
        
        for(Claim__c c : claims){
            //Only attempt to create new lines if there are none present
            //if(c.Claim_Lines__r.size() == 0){
                processClaims.add(c);
                custInvIds.add(c.Customer_Invoice__c);
            //}
        }
        system.debug('processClaims +'+processClaims);
        
        Map<Id, Customer_Invoice__c> mCustInvs = new Map<Id, Customer_Invoice__c>([SELECT Id, name, Balance__c
        
                                                                                    FROM Customer_Invoice__c
                                                                                    WHERE Id IN :custInvIds]);
        Savepoint sp = Database.setSavepoint();
        try {
        for(Claim__c c : processClaims){
            if(mCustInvs.containsKey(c.Customer_Invoice__c)){
                    Claim_Line__c iClaimLine = new Claim_Line__c();
                    iClaimLine.Claim__c = c.Id;
	                iClaimLine.Total_Amount__c = (-1) * mCustInvs.get(c.Customer_Invoice__c).Balance__c;
                    insertClaimLines.add(iClaimLine);
                    
                }
            }
        
	        DML.insertAsUser(insertClaimLines);
        }catch(Exception ex){
        	system.debug('createClaimLine exception '+ex.getMessage() +' '+ex.getStacktraceString());
            Database.rollback(sp);
            throw ex;
        }
        
    }
    
    public static void cancelClaims(list<Customer_Receipt_Line__c> paymentLines){
        
        List<Claim__c> cancelClaims = [SELECT Id, Status__c, Customer_Receipt_Line__r.Name FROM Claim__c WHERE Customer_Receipt_Line__c IN :paymentLines];
        
        for(Claim__c c : cancelClaims){
            if(c.Status__c == STATUS_CLOSED){
            	system.debug('inside claimservice remove claims');
            	throw new ClaimException(c.Customer_Receipt_Line__r.Name + Label.Cannot_be_deleted_because_there_are_related_closed_claims);
            }
            c.Status__c = 'Cancelled';
        }
        
        if(cancelClaims.size() > 0 ){ 
            DML.updateAsUser(cancelClaims);    
        }
        
    }
    
    public static void removeClaims(list<Customer_Receipt_Line__c> paymentLines){
        
        List<Claim__c> deleteClaims = [SELECT Id, Status__c, Customer_Receipt_Line__r.Name FROM Claim__c WHERE Customer_Receipt_Line__c IN :paymentLines];
        
        for(Claim__c c : deleteClaims){
            if(c.Status__c == STATUS_CLOSED){
            	//throw new ClaimException(c.Customer_Receipt_Line__r.Name + Label.Cannot_be_deleted_because_there_are_related_closed_claims);
                system.debug('inside claimservice remove claims');
                //OTC-301 replace the throw method with Exception Service to avoid trigger expections tack being displayed on the VF page. 
                ExceptionService.addMessage( MessageUtil.Severity.FATAL.name(), c.Customer_Receipt_Line__r.Name + ' '+Label.Cannot_be_deleted_because_there_are_related_closed_claims, '' );
               	continue;
            }
        }
        
        if(deleteClaims.size() > 0 && !ExceptionService.hasErrors){ //
            DML.deleteAsUser(deleteClaims);    
        }
        
    }
    
    public static List<Claim__c> returnClaimDetails(set<Id> claimIds){
    	//KNDY-15529
    	SOQLUtil soql = new SOQLUtil('Claim__c', false); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name', 'amount__c', 'currency__c', 'status__c', 'type__c', 'ar_reason_code__c', 'resolution_code__c', 'customer_invoice__c','source__c', //KNDY-15529
                                    'Settlement_Method__c','Enter_Claims_Notes__c', 'claim_date__c', 'Company__c',  'Parent_Customer__c', 'Bill_to_Customer__c', 'Sold_to_Customer__c', 'Claim_Balance__c', 'Settled_Against_Claim__c',  'Settled_Against_Claim__r.Name', 
                                    'Customer_Invoice__r.Sales_Order__c', 'manage__c',
                                    'Customer_Invoice__r.Sales_Order__r.Company__c',
                                    'Customer_Invoice__r.Sales_Order__r.Customer__c',
                                    'Customer_Invoice__r.Sales_Order__r.Bill_to__c',
                                    'Customer_Invoice__r.Sales_Order__r.Ship_to__c',
                                    'Customer_Invoice__r.Sales_Order__r.Pricebook__c',
                                    'Customer_Invoice__r.Sales_Order__r.Payment_Term__c',
                                    'Customer_Invoice__r.Sales_Order__r.Currency__c',
                                    'Customer_Invoice__r.Company__c', 
                                    'Customer_Invoice__r.Bill_To_Customer__c',
                                    'Customer_Invoice__r.Sold_To_Customer__c', 
                                    'Customer_Invoice__r.Date_Invoiced__c',
                                    'Customer_Invoice__r.Currency__c', 'Customer_Receipt_Line__c',
                                    'customer_receipt_line__r.Customer_Receipt__r.Company__c',
                                    'settlement_method__c', 'total_line_amount__c','Enter_Claims_Notes__c','Reference__c'
		});
		soql.setWhereClause('Id IN :claimIds');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Claim_Lines__r');
		childRel.addFields(new set<string>{
			'Id','name', 'item__c', 'sales_order_line__c', 'customer_invoice_line__c',
                                        'total_amount__c', 'Claim__c',
                                        'customer_invoice_line__r.Product__c',
                                        'customer_invoice_line__r.Company__c',
                                        'customer_invoice_line__r.Sales_Order_Line__c',
                                        'customer_invoice_line__r.Sales_Order__c',
                                        'resolution_code__c', 'customer_invoice__c','customer_invoice__r.bill_to_customer__c',
                                        'Customer_Invoice__r.Balance__c', 'Customer_Invoice__r.Invoice_Type__c', 'Settling_Claim__c' 
		});
		soql.addChildRelationship(childRel);
		SOQLUtil.ChildRelationship relatedClaimRel = new SOQLUtil.ChildRelationship(soql, 'Related_Claims__r');
		relatedClaimRel.addFields(new set<string>{
			'Id','name', 'Status__c'
		});
		soql.addChildRelationship(relatedClaimRel);
		SOQLUtil.ChildRelationship relatedCIRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoices__r');
		relatedCIRel.addFields(new set<string>{
			'Id','name', 'Status__c', 'Finalized__c', 'Company__c', 'Invoice_Type__c', 'historical__c','Void__c' 
		});
		soql.addChildRelationship(relatedCIRel);
		SOQLUtil.ChildRelationship relatedCRRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipts__r');
		relatedCRRel.addFields(new set<string>{
			'Id','Name','Finalized__c', 'historical__c'
		});
		soql.addChildRelationship(relatedCRRel);
		SOQLUtil.ChildRelationship relatedCRLRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipt_Lines__r');
		relatedCRLRel.addFields(new set<string>{
			'Id','Finalized__c','Customer_Receipt__c', 'Customer_Receipt__r.Name', 'Customer_Receipt__r.Void__c'
		});
		soql.addChildRelationship(relatedCRLRel);
		return Database.query(soql.getQuery());
    }
    
    public static void populateCorrespondent(){
    	List<Claim__c> claimsToPopulate = new List<Claim__c>();
    	
    	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate) ){ //OTC-318 lettting a user populate calim correspondant if Claim has updated its Parent Customer.
	    	for(Claim__c claim : (List<Claim__c>) trigger.new){
	    		if(claim.Correspondant__c == null){
					claimsToPopulate.add(claim);
	    		}			
	    	}
    	}
    	
    	if(claimsToPopulate.size() > 0){
    		populateCorrespondent(claimsToPopulate);
    	}
    }
    
	public static void populateCorrespondent(List<Claim__c> claims){
		
		Set<Id> parentCustomerIds = new Set<Id>();
		
		for(Claim__c claim : claims){
			if(String.isBlank(claim.Parent_Customer__c) == false){
				parentCustomerIds.add(claim.Parent_Customer__c);
			}
		}
		
		if(parentCustomerIds.size() > 0){
			Map<Id, Customer__c> parentCustMap = new Map<Id, Customer__c>([select Id, Claims_Correspondent__c 
																			 from Customer__c 
																			where Id IN :parentCustomerIds]);
			
	    	for(Claim__c claim : claims){
	    		if(parentCustMap.containsKey(claim.Parent_Customer__c)){
	    			claim.Correspondant__c = parentCustMap.get(claim.Parent_Customer__c).Claims_Correspondent__c;
	    		}
	    	}
		}
    }
    
    public static Customer_Receipt__c settleClaims(Id sourceClaimId, list<Id> againstClaimsListIds) {
    	
    	
    	set<Id> allIds = new set<Id>(againstClaimsListIds);
    	allIds.add(sourceClaimId);
    	map<Id, Claim__c> mAgainstClaimsList = new map<Id,Claim__c>(returnClaimDetails(allIds));
    	
    	Claim__c sourceClaim = mAgainstClaimsList.remove(sourceClaimId);
    	Decimal total =0;
    	if(sourceClaim != null)
    	{
    		
    		for(Claim__c c : mAgainstClaimsList.values())
    		{
    			if(c.Claim_lines__r.size() > 0)
    				throw new ClaimException('the claims against which the source is being paid cannot have any lines');
    			
    			system.debug('AGAINST CLAIMS, CLAIM ID: '+c.Id+' '+c.Name);
    			total += c.Amount__c;
    			
    			
    		}
    	}
    	system.debug('TOTAL: '+total);
    	system.debug('SOURCE CLAIM AMOUNT: '+sourceClaim.Amount__c);
    	if(sourceClaim.Amount__c != (-1)*total)
    		throw new ClaimException('The amounts between the source claim and the list do not match');
    	
   		Savepoint sp = Database.setSavepoint();
    	
    	Customer_Receipt__c iCR = new Customer_Receipt__c();
    	list<Customer_Receipt_Line__c> iCRLs = new list<Customer_Receipt_Line__c>(); 
    	if(sourceClaim.Bill_To_Customer__c != null){
            iCR.Customer__c = sourceClaim.Bill_To_Customer__c;
        }else if(sourceClaim.Parent_Customer__c != null){
            iCR.Customer__c = sourceClaim.Parent_Customer__c;
        }else{
            throw new ClaimException(sourceClaim.Name + Label.Requires_either_Parent_or_BillToCustomer);
        }
        try
		{
	        iCR.Company__c = sourceClaim.Company__c;
	        iCR.amount_received__c = 0;
	        iCR.Date_Received__c = sourceClaim.claim_date__c;
	        iCR.Currency__c = sourceClaim.Currency__c;
	        iCR.transaction_date__c = system.now(); //AR-9
		
			DML.insertAsUser(iCR);
			
			iCRLs.add(new Customer_Receipt_Line__c(Customer_Receipt__c =iCR.id, Type__c =PaymentService.TYPE_PAYMENT, Claim__c = sourceClaim.id, Amount__c = sourceClaim.Amount__c));
			
			for(Claim__c c : mAgainstClaimsList.values())
				iCRLs.add(new Customer_Receipt_Line__c(Customer_Receipt__c =iCR.id, Type__c =PaymentService.TYPE_PAYMENT, Claim__c = c.id, Amount__c = c.Amount__c));
			
			if(!iCRLs.isEmpty())
			{
				DML.insertAsUser(iCRls);
				iCR.Finalized__c =true;
				iCR.Finalized_Date__c = system.now();
				DML.insertAsUser(iCR);
				
				iCR = [Select Id, Name, Finalized__c from Customer_Receipt__c where id = :iCR.id limit 1];
				if(!iCR.finalized__c)
					throw new ClaimException('The CR could not be finalized.');
			}
		}catch(Exception ex)
		{
			Database.rollback(sp);
			system.debug('ClaimService settleClaims exception: '+ex);
			throw ex;
		}
    	
    	
    	
    	return iCR;
    } 
    
    
	/* AR-106
    * This method is called after update if status changes from open to closed and balance != 0. This will create a new claim with amount equals to the balance. New field (or maybe use Related Claim field) 
    * will store lookup to original claim. 
    */
    public static void autoCreate() {
    	list<Claim__c> autoClaims = new list<Claim__c>();
    	if(trigger.isAfter && trigger.isUpdate) {
    		for(Claim__c c : (list<Claim__c>) trigger.new) {
    			if(KSE.isFieldChanging('Status__c', c, trigger.oldmap) && c.Status__c == 'Closed' && c.Amount__c != c.Total_Line_Amount__c && c.Settlement_Method__c != SETTLE_SPLIT) {
    				
    				Claim__c tmpClaim = c.clone(false, true, false, false);
					tmpClaim.name = null;
					tmpClaim.Amount__c = c.Amount__c - c.Total_Line_Amount__c; //c.Claim_Balance__C will not work since we are setting 0 for closed claims. KNDY-15252
					tmpClaim.Resolution_Code__c = null; 
					tmpClaim.Related_Claim__c = c.Id;
					tmpClaim.Status__c = 'Open';
					tmpClaim.Settlement_Method__c = null;
					tmpClaim.Settlement_Date__c = null;
					autoClaims.add(tmpClaim);
    			}
    				
    		}
    		
    		if(!autoClaims.isEmpty()) {
    			DML.insertAsUser(autoClaims);
    		}
    	}
    }
    
   /* KNDY-7704 Settle one claims against many
   * Earlier we were creating a source doc to settle claims against each other. Claims are not inherently being accounted, so we do not need to create any source docs ( CR and CI)
   * The concept is that there is one claim C1 with a large amount that is settling x claims collectively. The user goes to the C1 detail page and clicks on the Settle against Claim button. Selects x claims with an amount
   * These will be stored on C1 via claim lines. Then calling the below method will close all the claims  and set the valid settlement method. 
   
   */
    public static void settleClaims (set<id> claimIds) {
    	
    	
    	map<Id,Claim__c> mapClaimDetails = new map<Id,Claim__c>(returnClaimDetails(claimIds));
    	
    	
    	for(Claim__c c : mapClaimDetails.values()) {
    		for(Claim_Line__c cl : c.Claim_Lines__r) {
    			if(cl.Settling_Claim__c  == null)
    				throw new ClaimException(Label.Claim_Against_Claim_Lines_Not_Defines);
    		}
    		boolean isException = c.Amount__c < 0 ? (c.Amount__c > c.Total_Line_Amount__c ? true : false) : (c.Amount__c < c.Total_Line_Amount__c ? true : false);
    		if(isException) { //should check that each claim line has settling claim populated and only then match the amount < total line amount condition. 
    			throw new ClaimException(Label.Claim_Against_Claim_Amount_Mismatch+c.Amount__c+' '+c.Total_Line_Amount__c);
    		}
    	}
    	
    	list<Claim__c> updateClaims = new list<Claim__c>();
    	list<Claim_Line__c> insertLines = new list<Claim_Line__c>();
    	Savepoint sp = Database.setSavepoint();
    	try {
    		for(Claim__c sourceClaim : mapClaimDetails.values()) {
    			updateClaims.add(new Claim__c(Id= sourceClaim.Id, Status__c ='Closed', Settlement_Method__c = SETTLE_CLAIM_AGAINST_CLAIM, Settlement_Date__c = system.today()));
    			
    			for(Claim_Line__c claimLine  :  sourceClaim.Claim_Lines__r) {
    				insertLines.add(new Claim_Line__c(Claim__c = claimLine.Settling_Claim__c, Total_Amount__c = (-1)*claimLine.Total_Amount__c));
    				updateClaims.add(new Claim__c(Id= claimLine.Settling_Claim__c, Status__c ='Closed', Settlement_Method__c = SETTLE_CLAIM_AGAINST_CLAIM, Settlement_Date__c = system.today(), Settled_Against_Claim__c = sourceClaim.Id));
    			}
    		}
    		
    		if(!insertLines.isEmpty())
    			DML.insertAsUser(insertLines);
    		if(!updateClaims.isEmpty()) 
    			DML.updateAsUser(updateClaims);
    	}catch(Exception ex) {
    		Database.rollback(sp);
			system.debug('ClaimService settleClaims exception: '+ex);
			throw ex;
    	}
    }

    public static String settleRefundCreditClaims(Set<Id> claimIds, Map<Id, List<Customer_Receipt_Line__c>> mapCRIdCRLlist,
                                                  /*outgoing*/List<Claim_Line__c> claimLines, 
                                                  /*outgoing*/map<Id,Claim__c> closeClaims) { //KNDY-15033
        String errMsg = '';
        if (claimIds.size() == 0) return errMsg;
        errMsg =  validateRefundCreditClaims(claimIds);
        if(!String.isBlank(errMsg)){
            return errMsg;
        }

        for (Id claimId : claimIds){
            for (Id crId :  mapCRIdCRLlist.keySet()){
               List<Customer_Receipt_Line__c> crls = mapCRIdCRLlist.get(crId);
               for (Customer_Receipt_Line__c crl: crls){
                   if (crl.Customer_Receipt__r.Claim__c == claimId){
                       Claim_Line__c cline = new Claim_Line__c();
                       cline.Total_Amount__c = -1 * crl.Amount__c; 
                       cline.Customer_Invoice__c = crl.Customer_Invoice__c;//KNDY-13995
                       cline.Claim__c = claimId;
                       claimLines.add(cline);
					   DateTime dateReceived = crl.Customer_Receipt__r.Date_Received__c;
					   if(!closeClaims.containsKey(claimId)) {
						   Claim__c cl = new Claim__c (Id = claimId,
								   Settlement_Method__c = 'Refund', Settlement_Date__c = Date.newInstance(dateReceived.year(),dateReceived.month(),dateReceived.day()),
								   Status__c = ClaimService.STATUS_CLOSED);
						   closeClaims.put(claimId, cl);
					   }
                   }
               }

            }
        }
        return errMsg;
    }
    
    public static String validateRefundCreditClaims(Set<Id> claimIds){
        String errMsg = '';
        List<Claim__c> claims = new List<Claim__c>();
        String errorClaimIds = '';
        if (claimIds.size() == 0) return errMsg;
        claims = returnClaimDetails(claimIds);
        for (Claim__c cl: claims){
             if( cl.Source__c != 'Manual' || cl.Claim_Balance__c <= 0 || 
                (cl.Claim_Lines__r != null && cl.Claim_Lines__r.size() != 0) ){
                errorClaimIds += cl.Id + ',';
            }
        }
        if (!String.isBlank(errorClaimIds)){
            errMsg = label.Refund_Credit_Invalid_Claim;
        }
         
        return errMsg;
    }
}