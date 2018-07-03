trigger CustomerInvoice on Customer_Invoice__c (before insert, before update, before delete, after insert, after update) {
	
	if(DML.checkTriggerDispatch(Customer_Invoice__c.getSobjectType())){return;}
													
	if(ExceptionService.ignoreTrigger('Customer_Invoice__c')){return;}
	//VoidCancelService.validateHeader();																	          
	CustomerInvoiceService.updatePrepaymentReceivedOnSO();																	          
     If ( Trigger.isAfter){ 
        
        // This method updates the open invoices and open credit memos bucket on corp customer
        lisT<Customer_invoice__c> lCI = new list<Customer_invoice__c>();
        for(Customer_Invoice__c ci : trigger.new)
        {
        	if( KSE.isFieldChanging('Balance__c', ci, trigger.oldmap) || KSE.isFieldChanging('Total_Sales_Tax__c', ci, trigger.oldmap) || 
				KSE.isFieldChanging('Status__c', ci, trigger.oldmap)){
					lCI.add(ci);
				}
        }
        
				
        
        
     }
     
     if ( Trigger.isbefore ) { 
		if(trigger.isInsert || trigger.isUpdate){
	       	
			CustomerInvoiceService CIS = new CustomerInvoiceService(); 
	      	
	      	// sets the invoice/credit memo status to Closed if needed
	     	CIS.setStatus();
	   		
	   		// sets the bill to customer if missing and sold to addr and bill to addr
	     	CIS.setCustomerInformation();
	   		
	     	CIS.setPeriodPaid(); 
	     	
	     	// set finalized hidden flag and validate user action of unfinalize
	       	KSE.setValidateFinalizedFlagonSD();
       	
       		//FIN-209 set finalized date on the customer invoice
			FinalizeService.setFinalizedDate(Trigger.new);
			
			CustomerInvoiceService.setPaymentDueDate(); //AR-3	//needs to be placed after CIS.setCustomerInformation();
			CustomerInvoiceService.checkIfQuantityShippedIsZero();
			/**
			if(trigger.isInsert){			
				set<Id> companyIdSet = new set<Id>();
				map<Id,Id> mCompanyDefaultCurr = new map<Id,Id>();
				List<Customer_Invoice__c> ciUpdateList = new List<Customer_Invoice__c>();
				for(Customer_Invoice__c Ci: Trigger.new){
					if((Ci.currency__c == null || Ci.currency__c == '') && Ci.company__c != null){
						companyIdSet.add(Ci.company__c);
						ciUpdateList.add(ci);
					}
					
				}
				
				if(companyIdSet != null && companyIdSet.size()> 0){
					mCompanyDefaultCurr = CompanyService.setDefaultCurrency(companyIdSet);
				
				
					      
					for(Customer_Invoice__c Ci: ciUpdateList){
						if((Ci.currency__c == null || Ci.currency__c == '' ) && mCompanyDefaultCurr != null && mCompanyDefaultCurr.containsKey(Ci.company__c)){
							Ci.currency__c = mCompanyDefaultCurr.get(Ci.company__c);
						}
						
					}
				}
			}
			**/
	      	          
		}			
       	
       	if(trigger.isUpdate || trigger.isDelete){
       		//FIN-209 validate the header for finalize
			FinalizeService.validateHeaderFinalize();
		}
       	
       /*  The following was in the Ship Invoice Line trigger and was causing havoc.  TODO
       	if(ciMap.get(ci.Id).RecordType.DeveloperName != CustomerInvoiceService.RT_CREDIT_MEMO){
			ci.Credit_Memo_Amount__c = null;
		}
		*/
     }
     
     if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
        	// maintain the exception field 
            CustomerInvoiceService.setExceptions(trigger.new);
            CustomerInvoiceService.exService.finishTasks();
        }
    }
    
    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Customer_Invoice__c> recWithoutCurrency = new List<Customer_Invoice__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Customer_Invoice__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Customer_Invoice__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }    
    

}