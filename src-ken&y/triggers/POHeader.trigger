trigger POHeader on Purchase_Order__c (before insert, before update, after update, before delete) {

	if(DML.checkTriggerDispatch(Purchase_Order__c.getSobjectType())){return;}

static SchemaUtil util = SchemaUtil.getInstance();
    
    //KNDY-15740
    if ( trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
         PurchaseOrderService.updateDefaultPOAmountTolerance();
    } 
    
    
    //VoidCancelService.validateHeader();
    // TODO rewrite this to load payment terms from Customer table....
    if ( trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
    	
        Set<Id> supplierSet = new Set<Id>();
        Set<Id> poIds = new Set<Id>();
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>(); //List of all Trigger.New records

        for( Purchase_Order__c p: Trigger.New) {
        	poList.add(p);
            // set the buyer if empty
            if ( p.Buyer__c == null ) {
                p.Buyer__c = UserInfo.getUserID(); 
            }
            
            // fill in terms, 
            // Remit to Supplier is read only in Page Layout, only supplier can be changed. PTP-567
            // KNDY-10259 - Acknowledge Via should default from Supplier if it is blank
            if ((((p.Payment_Term__c == null && p.Supplier__c != null ) || ( p.FOB_Term__c == null && p.Supplier__c != null ) || ( p.Acknowledge_Via__c == null && p.Supplier__c != null ))
            	&& Trigger.isInsert)
                  || (Trigger.isUpdate && KSE.isFieldChanging('Supplier__c', p, Trigger.oldMap))) { 
                supplierSet.add( p.Supplier__c );       
            }
            
            //KNDY-11957 Approval process is controlled by 'Source Document Approval' custom setting
            boolean useApproval = false;
            if (KSE.getSourceDocumentApprovals().containsKey('Purchase Order')){
            	Source_Document_Approval__c sda = Source_Document_Approval__c.getValues('Purchase Order');
            	useApproval = sda.Allow_Approval__c; //set the approval to true if the custom setting says so
            	system.debug('useApproval--'+useApproval);
            }
            if (p.Type__c == 'SubContract'){
                useApproval = true; //if PO is subcontract, always set approval to true
            }
            
            if (trigger.isInsert){
            	if (!useApproval && p.Approval_Status__c == 'Pending Authorization') 
            		p.Approval_Status__c = 'Approved'; //if use approval flag is false, then insert PO as 'Approved'
            }
            
            //PTM-94 Flip the PO Approval status when any field other than Status, Date Closed or Approval Status is changed
	     	if(trigger.isUpdate){
	     		Boolean flipPOStatus = false;
	     		for(String str: util.getFieldsFromFieldSetString(Purchase_Order__c.sObjectType , 'FlipPOApprovalStatus')){
					if ((KSE.isFieldChanging(str, p, Trigger.oldMap)) && (p.Total_number_of_Lines__c <> 0 )){
						flipPOStatus = true;
						break;
					}
    			}
    			//PTP-373 Approval status getting flipped when voiding a Receiving doc
    			//if (KSE.isFieldChanging('Status__c', p, Trigger.oldMap) && (p.Status__c == 'Open')){
    			if ((Trigger.oldMap.get(p.id).Status__c == 'Cancelled') && (p.Status__c == 'Open')){
    				flipPOStatus = true;
    			}
				if (flipPOStatus && p.Approval_Status__c == 'Approved' && useApproval){ //check if approval to be used, if yes, then set to pending else just skip
     					p.Approval_Status__c = 'Pending Authorization';	
				}
				if(KSE.isFieldChanging('FOB_Term__c', p, Trigger.oldMap)){
					poIds.add(p.Id);
				}
            }
        } 
        
        if(poIds.size()>0){
        	Map<Id,List<Purchase_Order_Line__c>> pordermap = new Map<Id,List<Purchase_Order_Line__c>>();
        	pordermap = PurchaseOrderService.queryPOLinesWithASN(poIds,'Purchase_Order__c');
        	for(Purchase_Order__c po : Trigger.new){
	           if (pordermap.containskey(po.Id) && pordermap.get(po.Id).size()>0) {
					po.addError('You cannot change the FOB Terms if purchase order is associated with the asn or quantity received greater than 0');
				}
			}
        }
        
        if ( supplierSet.size() > 0 ) {  // avoid query if the terms are all set and supplier has not changed

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Remit_To__c','Remit_To__r.Payment_Term__c','FOB_Term__c','Preferred_Correspondence__c','RecordType.Name','RecordType.DeveloperName',
				'RecordTypeId','Company__c'
			});
			soql.setWhereClause('id in :supplierSet');

			Map<Id,Supplier__c> myMap = new Map<Id,Supplier__c>((List<Supplier__c>)Database.query(soql.getQuery()));
	        
	        for( Purchase_Order__c p: Trigger.New) {
	        	
	        	if(myMap != null && myMap.containsKey(p.Supplier__c)){
                
                    //PTP-652
                    if(myMap.get(p.Supplier__c).Company__c != null 
                    	&& (p.Company__c != myMap.get(p.Supplier__c).Company__c)){
                        
                        p.addError(Label.Purchase_from_Supplier_not_tagged_to_the_Company);
                    }
		            // PTP-567 auto-populate Remit To supplier
		            if(Trigger.isUpdate && KSE.isFieldChanging('Supplier__c', p, Trigger.oldMap)
		               && myMap.containsKey(p.Supplier__c)){
		                p.Remit_To_Supplier__c = myMap.get(p.Supplier__c).Remit_To__c;
		            }
		            
		            if ( p.Payment_Term__c == null && p.Supplier__c != null && myMap.containsKey(p.Supplier__c) ) {
		                p.Payment_Term__c = myMap.get(p.Supplier__c).Remit_To__r.Payment_Term__c; //PTP-218 Getting pymt term from Remit-To
		            }

		            if ( p.Acknowledge_Via__c == null && p.Supplier__c != null && myMap.containsKey(p.Supplier__c) ) { //KNDY-10259
		                p.Acknowledge_Via__c = myMap.get(p.Supplier__c).Preferred_Correspondence__c;
		            }
		            
		            if (p.FOB_Term__c == null && p.Supplier__c != null && myMap.containsKey(p.Supplier__c)){
		            	p.FOB_Term__c = myMap.get(p.Supplier__c).FOB_Term__c;
		            }
	        	}    
	        }
	        
	    }
	    //PTP-253 Un-cancel a Purchase Order
	    //Preventing SetFinalizeDate method to be called when the PO status changes from Cancelled to Open
	    if (trigger.isUpdate){
		    for (integer i = 0; i<Trigger.new.size() ; i++){	
		       	if (Trigger.old[i].Status__c == 'Cancelled' && Trigger.new[i].Status__c == 'Open'){
		       		poList.remove(i);
		       	}
		    }
	    }
    }
	if( Trigger.isAfter && Trigger.isUpdate ){
	    
	    //an optimization would be to avoid an update to PO lines in one of the two methods below as both of them update po lines. 
	    //the logic is different enough , that it would require some rework to merge them.
	    PurchaseOrderService.approvePOLines();
	    PurchaseOrderService.updatesupplieronPOLines(trigger.newMap);
    }

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Purchase_Order__c> recWithoutCurrency = new List<Purchase_Order__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Purchase_Order__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Purchase_Order__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }    
    
}