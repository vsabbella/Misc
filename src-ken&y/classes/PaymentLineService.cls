public with sharing class PaymentLineService {
    
    public static ExceptionService exService = new ExceptionService();
    
    public static void managePaymentMatches(List<Payment_Line__c> paymentLines){
    	
    	List<Payment_Match__c> paymentMatches = new List<Payment_Match__c>();
    	List<Payment_Match__c> existingMatches = [SELECT Id, amount__c, type__c, invoice__c, payment_line__c
    												FROM Payment_Match__c
    												WHERE Payment_Line__c IN :paymentLines];
    	map<Id, List<Payment_Match__c>> mPaymentMatches = new map<Id, List<Payment_Match__c>>();
    	for(Payment_Match__c pm : existingMatches){
    		if(mPaymentMatches.containsKey(pm.Payment_Line__c)){
    			mPaymentMatches.get(pm.Payment_Line__c).add(pm);
    		}else{
    			mPaymentMatches.put(pm.Payment_Line__c, new List<Payment_Match__c>{pm});
    		}
    	}
    	/*
    	for(Payment_Line__c pml : paymentLines){
    		if(pml.Invoice__c != null 
    				&& pml.Finalized__c
    				&& !mPaymentMatches.containsKey(pml.Id)){
    			paymentMatches.add(new Payment_Match__c(payment_line__c = pml.Id, amount__c = pml.amount__c, invoice__c = pml.invoice__c, type__c = pml.type__c));
    		}	
    	}
    	*/
    	if(paymentMatches.size() > 0){
    		insert paymentMatches;
    	}
    	
    }
    
    public static void validations(){
    	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
    		map<Id, Payment_Line__c> mPaymentLines = new map<Id, Payment_Line__c>([SELECT Id, Payment__r.From_Company__c, Payment__r.To_Company__c,
    																				
    																				(SELECT Id, Invoice__r.From_Company__c, Invoice__r.To_Company__c
    																				FROM Payment_Matches__r)
																	FROM Payment_Line__c
																	WHERE Id IN :trigger.new]);
    		for(Payment_Line__c pml : (List<Payment_Line__c>)trigger.new){
    			if(mPaymentLines.containsKey(pml.Id)){
    				Payment_Line__c refPml = mPaymentLines.get(pml.Id);
    				boolean misMatch = false;
    				for(Payment_Match__c pm : refPml.Payment_Matches__r){
	    				if((refPml.Payment__r.From_Company__c != pm.Invoice__r.To_Company__c && refPml.Payment__r.From_Company__c != pm.Invoice__r.From_Company__c) 
								|| (refPml.Payment__r.To_Company__c != pm.Invoice__r.To_Company__c && refPml.Payment__r.To_Company__c != pm.Invoice__r.From_Company__c)){
	    					misMatch = true;
	    				}
    				}
    				if(misMatch){
    					exService.setException(pml, ExceptionUtil.PML_CHECK_COMPANIES);
    				}else{
    					exService.clearException(pml, ExceptionUtil.PML_CHECK_COMPANIES);
    				}
    			}
    		}
    	}
    }
    
    public static void calculateLineTotals(){
    	
    	if(trigger.isAfter){
	    	list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions =  new list<RollUpSummaryUtility.fieldDefinition> {
		        new RollUpSummaryUtility.fieldDefinition('SUM', 'Amount__c', 'Payment_Amount__c')
		    };
		    
		    set<Payment__c> payments = new set<Payment__c>();
		    List<Payment_Line__c> paymentLines = new List<Payment_Line__c>();
		    if(trigger.isInsert || trigger.isUpdate){
		    	paymentLines.addAll((List<Payment_Line__c>)trigger.new);
		    }else if(trigger.isUpdate){
		    	paymentLines.addAll((List<Payment_Line__c>)trigger.new);
		    	paymentLines.addAll((List<Payment_Line__c>)trigger.old);
		    }else if(trigger.isDelete || trigger.isUndelete){
		    	paymentLines.addAll((List<Payment_Line__c>)trigger.old);
		    }
		    
	    	RollUpSummaryUtility.rollUpTrigger( fieldDefinitions, paymentLines, 'Payment_Line__c', 'Payment__c', 'Payment__c', '');	
    	}
    }
    
    
    public static void paymentLineCleanup(){
    	if(trigger.isBefore && trigger.isDelete){
    		set<Id> paymentIds = new set<Id>();
    		for(Payment_Line__c pml : (List<Payment_Line__c>)trigger.old){
    			paymentIds.add(pml.Payment__c);
    		}
    		if(paymentIds.size() > 0){
    			paymentMatchCleanup(paymentIds);
    		}
    	}
    }
    
    public static void paymentMatchCleanup(set<Id> paymentIds){
    	if(trigger.isBefore && trigger.isDelete){
    		delete [SELECT Id FROM Payment_Match__c WHERE Payment_Line__r.Payment__c IN :paymentIds];
    	}
    }
}