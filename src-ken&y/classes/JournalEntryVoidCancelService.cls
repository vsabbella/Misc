public with sharing class JournalEntryVoidCancelService extends VoidCancelService {
	public Datetime currDate;
	public JournalEntryVoidCancelService(List<Journal_Entry__c> JournalEntries){
    	super(JournalEntries);  
    }
    public JournalEntryVoidCancelService(){
    }
    
    
    
    
    public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
    	if(currDate == null){
    		currDate = VoidCancelService.voidDate;
    	}
    	VoidCancelService.voidDate = currDate;
    	Map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new Map<Id, VoidCancelService.VoidCancelDetail>();
    	set<Id> sourceDocIds = new set<Id>();
		for(sObject sObj : sObjRecs) {
    		sourceDocIds.add(sObj.Id);
    	}
		
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        //V2
        SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name','has_Exceptions__c','type__c','period__c','period__r.JE_cutoff__c','void__c','void_date__c','auto_reverse__c',
            'finalized__c', 'Description__c', 'period__r.GL_Close__c'
        });
        soql.setWhereClause('id in :sourceDocIds');
        SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Journal_Entry_Lines__r');
        childRel1.addFields(new set<string>{
            'id','Name','GL_Account__c','Amount_CR__c','Amount_DR__c'
        });
        soql.addChildRelationship(childRel1);
        SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
        childRel2.addFields(new set<string>{
            'id','name'
        });
        childRel2.setWhereClause('status__c = \'Active\' and Has_Exceptions__c != true');
        soql.addChildRelationship(childRel2);
        List<Journal_Entry__c> jeList = Database.query(soql.getQuery());



		
		for(Journal_Entry__c je : jeList) {
			VoidCancelDetail iVCD = new VoidCancelDetail();
            iVCD.recordId = je.Id;
            iVCD.recordName = je.Name;
            iVCD.isVoidable = true;
            iVCD.isCancellable = true;
            iVCD.voidMessages = new List<string>();
            iVCD.cancelMessages = new List<string>();
            list<Accounting_Entry__c> aelist = je.Accounting_Entries__r;
                        
            /*if(je.void__c){
           		iVCD.isVoidable = false;
			}else{
				iVCD.isVoidable = true;
			}
			
			if(!je.finalized__c && je.status__c == 'Cancelled' ){
            	iVCD.isCancellable = false;
			}else{
				iVCD.isCancellable = true;
			}*/
			system.debug(logginglevel.info,'voidDate:'+voidDate);
			if(je.type__c.equalsIgnoreCase('Year End')){
				iVCD.voidMessages.add(Label.Cannot_Void_Journal_Entry_is_system_generated);
				iVCD.cancelMessages.add(label.Cannot_Cancel_Journal_Entry_is_system_generated);
			}
			if(je.void__c == true){
    			iVCD.voidMessages.add(label.Cannot_Void_this_Journal_Entry_is_voided);
				iVCD.cancelMessages.add(label.Cannot_Cancel_this_Journal_Entry_is_voided);
    		}
	    	if(voidDate < je.Period__r.JE_Cutoff__c){
				iVCD.voidMessages.add(label.Cannot_void_JE_Cutoff_not_past_yet);
	    	}
	    	if( je.Type__c.equalsIgnoreCase('Year End Adjustment')){
	    		id periodId = je.period__c;
		        soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(new set<string>{'id','Name'});
		        soql.setWhereClause('Type__c  = \'Year End\' and period__c =: periodId and finalized__c = true');
		        List<Journal_Entry__c> YEJE = Database.query(soql.getQuery());
		        
		        if(YEJE.size() > 0 ){
					iVCD.cancelMessages.add('You cannot cancel this journal entry because the year end transfer has already been made. You must first cancel the year end transfer, then you can cancel this journal entry.');
					iVCD.voidMessages.add('You cannot void this journal entry because the year end transfer has already been made. You must first cancel the year end transfer, then you can cancel this journal entry.');
		        }else
					iVCD.voidMessages.add('Year End Adjustment cannot be voided, they can only be cancelled');
	    	}
	    	
	    	if(je.auto_reverse__c == true){
				iVCD.voidMessages.add(label.Cannot_Void_this_Journal_Entry_is_auto_reversal);
	    	}
	    	if(je.type__c.equalsIgnoreCase('Accrual - Manual')){
				iVCD.voidMessages.add(label.Cannot_Void_this_Journal_Entry_is_Accrual);
			}
			if(je.type__c.equalsIgnoreCase('UFX')){
				iVCD.voidMessages.add(label.Cannot_Void_this_Journal_Entry_is_a_UFX);
			}
			if(voidDate >= je.Period__r.GL_Close__c){
				iVCD.cancelMessages.add(label.Cannot_Cancel_this_journal_entry_is_in_a_closed_period);
			}
            
	    	if(!(aelist.size()> 0)){
				iVCD.voidMessages.add('Cannot Void, this Journal Entry does not have Accounting Entry generated or have Exceptions');
			}
            if(iVCD.voidMessages.size() > 0) {
				iVCD.isVoidable = false;
			}
			if(iVCD.cancelMessages.size() > 0) {
				iVCD.isCancellable = false;
			}
			
			mBusinessVoidCancelDetails.put(je.Id, iVCD);
		}

    	return mBusinessVoidCancelDetails; 
    }
    
    public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){
	 	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
	 	businessVoidCancelAction((list<Journal_Entry__c>) sObjRecs);
    	for(sObject sObj : sObjRecs){
    		List<String> messages = new List<String>{'Successfully Voided!'};	
    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
    	}
        return mResponses;
    }
    

	public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){
		Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
		businessVoidCancelAction((list<Journal_Entry__c>) sObjRecs);
    	for(sObject sObj : sObjRecs){
    		List<String> messages = new List<String>{'Successfully Cancelled!'};	
    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
    	}
    	return mResponses;
    }
    
    private void businessVoidCancelAction(list<Journal_Entry__c> lJEs) {
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id'
        });
        soql.setWhereClause('Journal_Entry_Line__r.Journal_Entry__c in :lJEs');
        list<Bank_Transaction_Match__c> lBTM2Delete = Database.query(soql.getQuery());

    	if(!lBTM2Delete.isEmpty()) {
    		DML.deleteAsUser(lBTM2Delete);	
    	}
    }
    
}