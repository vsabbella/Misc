trigger CustomerReceipt on Customer_Receipt__c (before insert, before update, before delete, after insert, after update) {
    
    if(DML.checkTriggerDispatch(Customer_Receipt__c.getSobjectType())){return;}
    
    if(ExceptionService.ignoreTrigger('Customer_Receipt__c')){return;}
//    VoidCancelService.validateHeader();	
    CustomerReceiptService.finalize();
    CustomerReceiptService.checkCustomerHeirarchyOnReceiptLines();//AR-139
    CustomerReceiptService.populateAmountInWords(); //KNDY-16976
    if(Trigger.isBefore){
		if( Trigger.isInsert ){
			for( Customer_Receipt__c cr : trigger.new ){				
				cr.Amount_unapplied__c = cr.Amount_Received__c;
				cr.Status__c =cr.Status__c == null || cr.Status__c == '' ?  'Open' : cr.Status__c;//KNDY-11375 since WFR is deactivated, need to default the status.
			}
		}
		if (trigger.isInsert || trigger.isUpdate){
		KSE.setValidateFinalizedFlagonSD();
	
			set<Id> companyIdSet = new set<Id>();
			map<Id,Id> mCompanyDefaultCurr = new map<Id,Id>();
			//FIN-209 set finalized date on the customer receipt
			FinalizeService.setFinalizedDate(Trigger.new);
		}
		
		if(trigger.isUpdate || trigger.isDelete){
       		//FIN-209 validate the header for finalize
			FinalizeService.validateHeaderFinalize();
		}
       	
	}
    
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
           try
            {
	            CustomerReceiptService.validateReceipts(trigger.new);
	            CustomerReceiptService.exService.finishTasks();
	            CustomerReceiptService.onFinalize();
	            CustomerReceiptService.onUnfinalize();
           	
            }catch(Exception ex)
            {
            	for(Customer_Receipt__c cr : trigger.new)
            		cr.addError(ex.getMessage()); //AR-130
            }
          	
          
            
        }
    }
    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Customer_Receipt__c> recWithoutCurrency = new List<Customer_Receipt__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Customer_Receipt__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Customer_Receipt__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }
    
}