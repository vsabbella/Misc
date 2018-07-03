trigger AccountingEntryLine on Accounting_Entry_Line__c (after delete, after insert, after update, before insert, before update, before delete) {
   
   if(DML.checkTriggerDispatch(Accounting_Entry_Line__c.getSobjectType())){return;}
   
   if(ExceptionService.ignoreTrigger('Accounting_Entry_Line__c')){return;}
   	Set <Id> AEIds = new Set<Id>();	
    // Set the Segment Exception flag to true if GL Account is null
    if ( Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {
    	if(AEIds!=null)
    		AEIds.clear();
    	
		//FIN-795
		//set up some variables we only need once for the trigger context so we don't get them in a loop
    	List<String> changeableAELfieldsClosedPeriod;
    	Set<String> nonChangeableAELfieldsClosedPeriod;
    	if (Trigger.isUpdate) {
			//only applicable in update context
    		changeableAELfieldsClosedPeriod = AccountingEntryLinesService.getAELallowedEditFields();	
    	}
    	if (changeableAELfieldsClosedPeriod != null) {
    		nonChangeableAELfieldsClosedPeriod = AccountingEntryLinesService.getNonChangeableAELfieldsClosedPeriod(changeableAELfieldsClosedPeriod);	
    	}
    	
        for(Accounting_Entry_Line__c thisEntry: Trigger.new){
        	
        	AEIds.add(thisEntry.Accounting_Entry__c);
        	
            if(thisEntry.GL_Account__c == null){
                thisEntry.Mandatory_Segment_Exception__c = true;
            }else{
                thisEntry.Mandatory_Segment_Exception__c = false;
            }  
            if(thisEntry.Mandatory_Segment_Exception__c == true || thisEntry.Segment_Combination_Exception__c == true){
                thisEntry.Exception__c = true;
            }else{
                thisEntry.Exception__c = false;
            }
            
            // FIN-852 dont store more than 6 decimal places
            if(thisEntry.Amount_CR__c == null){
                //thisEntry.Amount_CR__c = 0;
            }
            if(thisEntry.Amount_DR__c == null){
                //thisEntry.Amount_DR__c = 0;
            }
            if(thisEntry.Amount_DR__c != null && thisEntry.Amount_CR__c != null){
            thisEntry.Amount_CR__c = thisEntry.Amount_CR__c.setScale(6,RoundingMode.FLOOR);
            thisEntry.Amount_DR__c = thisEntry.Amount_DR__c.setScale(6,RoundingMode.FLOOR);}
                
        }
       
        //FIN-689 Prevent AE Line changes on a closed period.
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Company__c','Company__r.Name','source_document_object_name__c','status__c','Period_Status__c','Void__c','Related_Accounting_Entry__c',
			'reversed_journal__c','source_key__c','source_reference__c'
		});
		soql.setWhereClause('id in :AEIds');
		
		Map <id, Accounting_Entry__c> AEHdrMap = new map <id, Accounting_Entry__c>((List<Accounting_Entry__c>)Database.query(soql.getQuery()));

        for(Accounting_Entry_Line__c ael: Trigger.new){
        	if(AEHdrMap.containsKey(ael.Accounting_Entry__c)){
                //FIN-689
                Accounting_Entry__c aeHdr = AEHdrMap.get(ael.Accounting_Entry__c);
                string AEPeriodStatus = aeHdr.Period_Status__c ;
                
                //FIN-795                
				if ((aeHdr.status__c == 'Active' || aeHdr.status__c == null || aeHdr.status__c == '') && (AEPeriodStatus.equalsIgnoreCase('Closed') || AEPeriodStatus.equalsIgnoreCase('Permanently closed'))) {
	                if (changeableAELfieldsClosedPeriod == null) {
						//if the custom setting isn't set, don't allow any changes on AELs in closed periods
		                ael.addError(Label.Cannot_create_AccountingEntries_for_closed_period);
	                } else { 
	                	//if the custom setting is set, do validation down to the field level to allow some fields to be changed in closed periods
	                	AccountingEntryLinesService.checkNonChangeableFieldsClosedPeriod(ael, Trigger.oldMap, nonChangeableAELfieldsClosedPeriod);
	                }
				}
    
        		// KNDY - 2362
        		ael.Company__c = AEHdrMap.get(ael.Accounting_Entry__c).Company__c ; // get header from map
        		if(AEHdrMap.get(ael.accounting_entry__c).source_document_object_name__c == 'Manual'){
			        ael.source_key__c = null;   
			    }else if(ael.accounting_rule__c != null){
                    //ael.source_key__c = AEHdrMap.get(ael.accounting_entry__c).source_key__c + '|' + ael.source_id__c + '|' + ael.accounting_rule__c;
                    //ael.source_key__c = AEHdrMap.get(ael.accounting_entry__c).source_key__c + '|' + ael.source_id__c + '|' + ael.accounting_rule__c + '|' + aeHdrMap.get(ael.accounting_entry__c).status__c;
                    ael.source_reference__c = AEHdrMap.get(ael.accounting_entry__c).source_reference__c + '|' + ael.source_id__c + '|' + ael.accounting_rule__c;
                    if(!string.isEmpty(ael.allocation_id__c)){
                    	//ael.source_key__c += '|' + ael.allocation_id__c;
                    	ael.source_reference__c += '|' + ael.allocation_id__c;
                    }
                }else if(ael.source_id__c != null && ael.source_id__c != ''){
                	ael.source_key__c = null;
                	ael.source_reference__c = ael.source_id__c;
                }else{
                    ael.source_key__c = null;
                    ael.source_reference__c = null; 
                }
                
                if(AEHdrMap.get(ael.accounting_entry__c).status__c == 'Obsolete' && ael.source_key__c != null){
                	//ael.source_key__c += string.valueOf(ael.createdDate);
                }
                
                ael.source_key__c = null;
                
                
        	} 
        	//TODO: What is to become of this source key on the line?
        	//TODO: The rounding check is STRICTLY temporary until full roll-out of LDA
            /* FIN-889
            if(ael.journal_entry_line__c != null 
            		|| ael.supplier_invoice_line__c != null 
            		|| ael.supplier_payment_line__c != null 
            		|| ael.purchase_order_line__c != null
            		|| ael.customer_invoice_line__c != null
            		|| ael.bank_file_line__c != null 
            		|| ael.customer_receipt_line__c != null
            		|| ael.subtransaction_type__c == 'Rounding'
            		|| (ael.allocation_id__c != null && ael.allocation_id__c != '')){
           		ael.source_key__c = null;
            }*/
        }
        
    }
    
    
    if ( Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {
   
   	    AccountingEntryLinesService.ValidateAELFields(trigger.new);
     	AccountingEntryLinesService.exService.finishTasks();
	} 
	
	if(trigger.isBefore && trigger.isDelete){
		for(Accounting_Entry_Line__c ael : trigger.old){
			if(ael.Subledger_Closed__c 
					&& (ael.status__c == 'Active' || ael.status__c == '' || ael.status__c == null)){
				ael.addError('You cannot delete records in closed areas.');
			}
		}
	}  
}