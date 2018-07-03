public with sharing class CustomerReceiptLineService {
    
    public static ExceptionService exService = new ExceptionService();
    public static boolean isDupeChecked = false;
    
    //KNDY-10476
    public static void validateSalesOrder(){
        set<Id> setSalesOrderId = new set<Id>();
        set<Id> setPrepaymentCRL = new set<Id>();
        if((trigger.isBefore && trigger.isUpdate) || (trigger.isAfter && trigger.isInsert)){
        	if(CustomerReceiptService.isCRUnfinalized){
        		return;
        	}
            for(Customer_Receipt_Line__c crl: (list<Customer_Receipt_Line__c>)trigger.new){
		    	if(crl.Type__c.equalsIgnoreCase('Prepayment') && crl.Sales_Order__c != null){
		        	setSalesOrderId.add(crl.Sales_Order__c);
		            setPrepaymentCRL.add(crl.Id);
		         }
            }
            if(!setSalesOrderId.isEmpty()){
                set<Customer_Receipt_Line__c> setErroredCRL = new set<Customer_Receipt_Line__c>();
                map<Id,Sales_Order__c> mapSalesOrder = new map<Id,Sales_Order__c>([Select Id,Bill_to__c,Bill_to__r.Parent_Customer__c,
                																   Status__c,Currency__c  from Sales_Order__c where Id in: setSalesOrderId]);
                map<Id,Customer_Receipt_Line__c> mapQueriedCRL = new map<Id,Customer_Receipt_Line__c>([Select Id,Customer_Receipt__c,Sales_Order__c,Customer_Receipt__r.Status__c,
                																					   Customer_Receipt__r.Customer__c,Customer_Receipt__r.Currency__c	 
                               																		   from Customer_Receipt_Line__c where Id in: setPrepaymentCRL]);
                system.debug(logginglevel.info,'mapSalesOrder---'+mapSalesOrder);
                system.debug(logginglevel.info,'mapQueriedCRL---'+mapQueriedCRL);
                if(!mapSalesOrder.isEmpty() && !mapQueriedCRL.isEmpty()){
                	setErroredCRL = validateSalesOrder(mapSalesOrder,mapQueriedCRL,trigger.new);
                	if(!setErroredCRL.isEmpty()){
                        addErrorToReceiptLine(setErroredCRL,System.Label.SalesOrderValidation);
                    }
                }              
            }
        }
    }
    public static void addErrorToReceiptLine(set<Customer_Receipt_Line__c> setErroredCRL, string message){
        if(!setErroredCRL.isEmpty()){
            for(Customer_Receipt_Line__c crl: setErroredCRL){
				crl.addError(message);
            }
        }
    }
    public static set<Customer_Receipt_Line__c> validateSalesOrder(map<Id,Sales_Order__c> mapSalesOrder,map<Id,Customer_Receipt_Line__c> mapQueriedCRL,
    										list<Customer_Receipt_Line__c> lstNewCRL){
        set<Customer_Receipt_Line__c> setErroredCRL = new set<Customer_Receipt_Line__c>();
        for(Customer_Receipt_Line__c crl: lstNewCRL){
            if(mapQueriedCRL.containsKey(crl.Id) && crl.Sales_Order__c != null && mapSalesOrder.containsKey(crl.Sales_Order__c)){
		    	if(mapQueriedCRL.get(crl.Id).Customer_Receipt__c != null && 
		         !(mapQueriedCRL.get(crl.Id).Customer_Receipt__r.Status__c.equalsIgnoreCase('Void') || 
		         mapQueriedCRL.get(crl.Id).Customer_Receipt__r.Status__c.equalsIgnoreCase('Cancelled'))){
		            if((crl.Type__c.equalsIgnoreCase('Overpayment')) || 
		              (crl.Type__c.equalsIgnoreCase('Prepayment') &&
                      (mapQueriedCRL.get(crl.Id).Customer_Receipt__r.Currency__c.equals(mapSalesOrder.get(crl.Sales_Order__c).Currency__c)) && //KNDY-11566
		              mapSalesOrder.get(crl.Sales_Order__c).Status__c.equalsIgnoreCase('Cancelled')) ||
		              (crl.Type__c.equalsIgnoreCase('Prepayment') &&
		              !mapSalesOrder.get(crl.Sales_Order__c).Status__c.equalsIgnoreCase('Cancelled') &&
		              mapSalesOrder.get(crl.Sales_Order__c).Bill_to__c != null && mapQueriedCRL.get(crl.Id).Customer_Receipt__r.Customer__c != null &&
		              mapSalesOrder.get(crl.Sales_Order__c).Bill_to__c != mapQueriedCRL.get(crl.Id).Customer_Receipt__r.Customer__c && 
		              mapSalesOrder.get(crl.Sales_Order__c).Bill_to__r.Parent_Customer__c != null &&
		              mapSalesOrder.get(crl.Sales_Order__c).Bill_to__r.Parent_Customer__c != mapQueriedCRL.get(crl.Id).Customer_Receipt__r.Customer__c)){ 
		              	setErroredCRL.add(crl);
		             }
		       }
            }
        }
        return setErroredCRL;
    }
    
    public static void validateLines(){
    	/*
    	   The first part of this method solves for OTC-750, where we want to raise exceptions if duplicate Earned Terms Discount are created for the same invoice within the same receipt
    	   We use a key of CR.Id+ CI.Id+Type in a map (String -> CRL)
    	   This code will raise exceptions if duplicates are found and cleear them if the duplicate  is removed (the code clears the exception if the type or the reference to the CI is changed).
    	*/
    	system.debug('isDupeChecked '+ isDupeChecked );
       	map<String,Customer_Receipt_Line__c> countDuplicateEDT = new map<String, Customer_Receipt_Line__c>(); //OTC-750
	    set<Id> sCRIds = new set<Id>();
	    set<Id> sCrlIds = new set<id>();
        
        for(Customer_Receipt_Line__c crl : (list<Customer_Receipt_Line__c>)trigger.new)
        {
        	
        	if( isDupeChecked == false) 
        	{
        		if ((trigger.isInsert && crl.Type__c == PaymentService.TYPE_EARNED_DISCOUNT)  || (trigger.isUpdate && ((KSE.isFieldChanging('Type__c',crl,trigger.oldmap))
        																						   || KSE.isFieldChanging('Customer_Invoice__c',crl,trigger.oldmap))))
	        	{
	        		sCRIds.add(crl.Customer_Receipt__c);
	        		sCrlIds.add(crl.Id);
	        		
	        	}
        	}
        	
        		
        }
        system.debug('sCRids '+sCRIds);
        if(!sCRIds.isEmpty())
        {
        	isDupeChecked = true;
        	for(Customer_Receipt_Line__c crl : [Select id, Type__c, Customer_Receipt__c, Customer_Invoice__c, Name from Customer_Receipt_Line__c where Customer_Receipt__c in :sCRIds and (Type__c = :PaymentService.TYPE_EARNED_DISCOUNT or id in :sCrlIds) ])
        	{
        		system.debug('crl: '+ crl);
        		String key = String.valueOf(crl.Customer_Receipt__c) + String.valueOf(crl.Customer_Invoice__c) + crl.Type__c;
        		system.debug('key: '+key);
        		if(countDuplicateEDT.containsKey(key))
        		{
        			system.debug('found duplicate');
        			ExceptionUtil.CRL_DUPLICATE_EARNED_TERMS.description += '. Duplicate of '+countDuplicateEDT.get(key).Name;
        			exService.setException(crl, ExceptionUtil.CRL_DUPLICATE_EARNED_TERMS);
        		}
        		else
        		{
        			countDuplicateEDT.put(key,crl);
        			exService.clearException(crl, ExceptionUtil.CRL_DUPLICATE_EARNED_TERMS);
        		}
        	}
        }
        
        
        
        for(Customer_Receipt_Line__c crl : (list<Customer_Receipt_Line__c>)trigger.new){
            
            if(crl.Type__c == null){
                exService.setException(crl, ExceptionUtil.CRL_MISSING_TYPE);
                continue;
            }else{
                exService.clearException(crl, ExceptionUtil.CRL_MISSING_TYPE);
            }
            
            string iType = crl.Type__c == null ? '' : crl.Type__c;
            //KNDY-13995 check for customer invoice and amount > 0  for all other invoices
            if(crl.Customer_Invoice__c == null && crl.Claim__c == null && crl.Amount__c > 0 &&
                    (iType == 'Payment' 
                    || iType == 'Invoice Deduction'
                    || iType == 'Earned Terms Discount'
                    || iType == 'Unearned Terms Discount'
                    )){
                exService.setException(crl, ExceptionUtil.CRL_MISSING_INVOICE);        
            }else{
                exService.clearException(crl, ExceptionUtil.CRL_MISSING_INVOICE);
            }
            //KNDY-13995 check for customer invoice and amount < 0 for credit 
            if(crl.Customer_Invoice__c == null  && (iType == PaymentService.TYPE_CREDIT_MEMO || iType == PaymentService.TYPE_DEBIT_MEMO)){
               exService.setException(crl, ExceptionUtil.CRL_MISSING_CREDIT);        
            }else if(crl.Customer_Invoice__c != null  && ((iType == PaymentService.TYPE_CREDIT_MEMO && crl.Customer_Invoice__r.Total_Amount__c < 0) 
            		|| (iType == PaymentService.TYPE_DEBIT_MEMO && crl.Customer_Invoice__r.Total_Amount__c > 0))){
           		system.debug('check for credit.debit=' + crl.Customer_Invoice__c +'=' +  crl.Customer_Invoice__r.Total_Amount__c );
               exService.setException(crl, ExceptionUtil.CRL_MISSING_CREDIT);        
            }
            else{
                exService.clearException(crl, ExceptionUtil.CRL_MISSING_CREDIT);
            }
            
            if(crl.Amount__c == null || crl.Amount__c == 0) {
            	exService.setException(crl, ExceptionUtil.CRL_ZERO_EMPTY_AMOUNT); 
            }
            else {
            	exService.clearException(crl, ExceptionUtil.CRL_ZERO_EMPTY_AMOUNT); 
            
            }
            	
            
            
            if((crl.Type__c == 'Prepayment' || crl.Type__c == 'Overpayment') && crl.Amount__c < 0) {
            	exService.setException(crl, ExceptionUtil.NEGATIVE_ADDITIONAL_PAYMENTS); 
            }
            else {
            	exService.clearException(crl, ExceptionUtil.NEGATIVE_ADDITIONAL_PAYMENTS); 
            }
            
            /*if(crl.Type__c == 'Prepayment' && crl.Sales_Order__c == null) {
            	exService.setException(crl, ExceptionUtil.CRL_PREPAYMENT_WITHOUT_SO); 
            }
            else {
            	exService.clearException(crl, ExceptionUtil.CRL_PREPAYMENT_WITHOUT_SO); 
            }*/
            

        }
    }
    
    
}