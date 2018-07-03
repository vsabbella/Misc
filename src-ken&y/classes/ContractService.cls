public with sharing class ContractService {
    
     public static Set<Id> openPAIds = new set<Id>();
     public static Set<String> itemsSourceRequiringUOM = new Set<String>{'Purchased', 'Miscellaneous', 'Expense', 'Outside Processing'};
     
    //------------------------------- Constructor ---------------------------------------------------
    /*
     * @description Constructor placeholder
     *
     */
     public ContractService(){
        
     }
    
    //------------------------------------------------------------------------------------------------
      private static Map<String, List<Contract_Line__c>> checkForPALineExistance(List<Contract_Line__c> records){
        //Initilize a set hold the catalog item ids we need to query
        Set<Id> contractIds = new Set<Id>();
        Set<String> itemIdUOMIdKeys = new Set<String>(); //KNDY-11176
        
        // KNDY-10599 Key is item/UOM name
        Map<String, List<Contract_Line__c>> newPALinesInError = new Map<String, List<Contract_Line__c>>();
        for(Contract_Line__c record:records){
        	if(trigger.isUpdate){
        		if(KSE.isFieldChanging('Contract_Start__c', record, trigger.oldMap) ||KSE.isFieldChanging('Contract_End__c', record, trigger.oldMap) || KSE.isFieldChanging('Item__c', record, trigger.oldMap) || KSE.isFieldChanging('Purchase_UOM__c', record, trigger.oldMap) ){
        			contractIds.add(record.Contract__c);
            		itemIdUOMIdKeys.add(record.ItemUOMKey__c); //KNDY-11176	
        		}	
        	}else{
        		contractIds.add(record.Contract__c);
            	itemIdUOMIdKeys.add(record.ItemUOMKey__c); //KNDY-11176			
        	}
       	
        }
        
        Map<String,List<Contract_Line__c>> mapKeylistPALines = new Map<String,List<Contract_Line__c>>();
        if(contractIds.size() > 0 && itemIdUOMIdKeys.size() > 0){
        	mapKeylistPALines =  getContractLinesMap(contractIds,itemIdUOMIdKeys);	
        }
        
        system.debug(LoggingLevel.Error, '>>>--- mapKeylistPALines: ' + mapKeylistPALines);

        for(Contract_Line__c newpaLine:records){
            String key = newpaLine.ItemUOMKey__c;
            if (mapKeylistPALines.containsKey(key)){
                List<Contract_Line__c> paLines = mapKeylistPALines.get(key);
                //Loop through the contract lines with same item/Purchase UOM
                for (Contract_Line__c existingLine : paLines){
                    //Check if the current line is overlaping with another line
                    String itemNameUOM = existingLine.Item__r.Name + '/' + existingLine.Purchase_UOM__r.Name; // Used in error message
                    if(existingline.Contract_End__c >= newpaLine.Contract_Start__c && existingline.Contract_Start__c <= newpaLine.Contract_End__c && existingline.ID != newpaLine.Id && existingline.Contract__c == newpaLine.Contract__c){
                        if (newPALinesInError.containsKey(itemNameUOM)){
                            newPALinesInError.get(itemNameUOM).add(newpaLine);
                        }else{
                            newPALinesInError.put(itemNameUOM,new List<Contract_Line__c> {newpaLine});
                        }
                        break;
                    }
               }
            }
        }
        return newPALinesInError;
    }
    
    // KNDY-11176 KNDY-10599 This method is called from a trigger context and also from controller remoteAction context
    public static Map<String,List<Contract_Line__c>> getContractLinesMap(Set<Id> contractIds, Set<String> itemIdUOMIdKeys){
        Map<String,List<Contract_Line__c>> mapKeylistPALines = new  Map<String,List<Contract_Line__c>>();
        
        String whereClause = 'Contract__c IN: contractIds and (Status__c = \'Open\') and ItemUOMKey__c in :itemIdUOMIdKeys';
        SOQLUtil soql = new SOQLUtil('Contract_Line__c');
        soql.addFields(new set<string>{'Id','Line__c','ItemUOMKey__c', 'Contract__c', 'Contract_End__c','Contract_Start__c','Purchase_UOM__c', 'Purchase_UOM__r.Name', 'Item__c', 'Item__r.Name'});
        soql.setWhereClause(whereClause);
        
        //Query the open agreement lines with Purchase UOM
        for(Contract_Line__c paLine: Database.query(soql.getQuery())){
            String key = paline.ItemUOMKey__c;
            if(mapKeylistPALines.containsKey(key)){    
                    mapKeylistPALines.get(key).add(paLine);
            }else{
                mapKeylistPALines.put(key,new List<Contract_Line__c>{paLine});
            }
       }
       return mapKeylistPALines;
    }

    //KNDY-10599 Called from Controller
    public static JSONResult validateMOQ(List<Contract_Line__c> updatedList, List<Contract_Line__c> newList) {
        JSONResult result = new JSONResult();
        String negativeMOQLines = '';
        String invalidMOQContractQtyLines = '';
        List<Contract_Line__c> palines = new List<Contract_Line__c>();
        if (newList.size() > 0 ){
            palines.addall(newList);
        } 
        
        if (updatedList.size() > 0 ){
            palines.addall(updatedList);
        }   

        for(Contract_Line__c pal: palines){
            if(pal.Minimum_Order_Quantity__c != null && pal.Minimum_Order_Quantity__c < 0){
                negativeMOQLines += pal.Line__c +', '; 
            }
            else if(pal.Minimum_Order_Quantity__c != null &&
                    pal.Contract_Quantity__c != null &&
                    pal.Contract_Quantity__c  < pal.Minimum_Order_Quantity__c ){
                invalidMOQContractQtyLines +=  pal.Line__c +', ';
           }
            
        }
        if(negativeMOQLines != ''){
            negativeMOQLines = (negativeMOQLines.subString(0,negativeMOQLines.length()-2) + '.');
            result.success = false;
            result.addMessage(Label.Minimum_Order_Quantity_cannot_be_negative + ' Lines: ' + negativeMOQLines, ApexPages.Severity.ERROR);
        }
        
        if(invalidMOQContractQtyLines != ''){
            invalidMOQContractQtyLines = (invalidMOQContractQtyLines.subString(0,invalidMOQContractQtyLines.length()-2) + '.');
            result.success = false;
            result.addMessage(Label.Purchase_Agreement_Quantity_cannot_be_less_than_minimum_order_quantity + ' Lines: ' + invalidMOQContractQtyLines, ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    //KNDY-10599 Default Purchase UOM from Item if possible
    public void checkifPALinehasUOMFromTrigger (List<Contract_Line__c> recordsNew){
        Set<Id> itemIds = new Set<Id>();
        List<Contract_Line__c> linesWithItemWithoutUOM = new List<Contract_Line__c>();
        
        for (Contract_Line__c paLine : recordsNew){
            if (paLine.Item__c != null){
                if (paLine.Purchase_UOM__c == null){
                    itemIds.add(paLine.Item__c);
                    linesWithItemWithoutUOM.add(paLine);
                }
            }
            else {
                if (paLine.Purchase_UOM__c == null){
                    paLine.addError(Label.Purchase_UOM_and_Item_are_required + ' Line ' + paLine.Line__c);
                }
                else{
                    paLine.addError(Label.Item_is_required + ' Line ' + paLine.Line__c);
                }
            }
            
        }
        if (linesWithItemWithoutUOM.size() == 0){
            return;
        }
        defaultPAuomFromItem(linesWithItemWithoutUOM, itemIds);
    }
    
    // KNDY-10599 Assumptions: 
    // This method is called from a trigger.isBefore context
    // and defaults a blank Purchase UOM field
    // on PALine with Item`s Purchasing UOM 
    private void defaultPAuomFromItem (List<Contract_Line__c> recordsNew, Set<Id> itemIds){
        Map<Id,Item__c> itemsMap = new Map<Id,Item__c>();
        List<Contract_Line__c> linesRequiringUOM = new List<Contract_Line__c>();
        if (itemIds.size() == 0) return;
        for(List<Item__c> itemList:[select Id, Name, Purchasing_UOM__c, Source__c 
                        from Item__c where Id IN :itemIds and Source__c in :itemsSourceRequiringUOM]){
            for (Item__c item: itemList){
                itemsMap.put(item.Id, item);
            }
        } 
        for (Contract_Line__c paLine : recordsNew){
            if (paLine.Item__c == null || !itemsMap.containsKey(paLine.Item__c)){
                continue;
            }
            else if(itemsMap.get(paLine.Item__c).Purchasing_UOM__c == null){
                paLine.addError(Label.Purchase_UOM_is_required_Cannot_default_from_item_as_there_is_no_purchasing_uom + 'Purchase Agreement Line ' + paLine.Line__c);
            }
            else{// Default from Item
                paLine.Purchase_UOM__c = itemsMap.get(paLine.Item__c).Purchasing_UOM__c;
            }
        }
    }
    
    //------------------------------------------------------------------------------------------------
    /*
     * @description  This takes a cart and a request item and adds it to the database.  May need to bulkify later.
     *   Checks for duplicate item/Purchase UOM combination
     */
    public static void checkForDuplicateLineExistanceTrigger(List<Contract_Line__c> recordsNew, Map<Id, Contract_Line__c> recordsOldMap){
        //Pass the records to the core method
        Map<String, List<Contract_Line__c>> results = checkForPALineExistance(recordsNew);
        if (results.size() > 0){
            for (String key: results.keySet()){
                for (Contract_Line__c newPALine : results.get(key)){
                    String msg = Label.Duplicate_open_lines_exist_with_given_start_end_dates + ' for Line ' + newPALine.Line__c + '  Item/UOM: '+ key + '.';
                    if (recordsOldMap != null && recordsOldMap.containsKey(newPALine.Id)
                        && KSE.isFieldChanging('Status__c', newPALine, recordsOldMap)
                        && newPALine.Status__c == 'Open') {
                        msg += ' Unable to open Line ' + newPALine.Line__c;
                    }
                    newPALine.addError(msg);
                }
            }
        }
    }

    //-----------------------------------------------------------------------------------------------------
    /*
     *  @description - Prevents changes to the contract line if the contract line has a PO
     *  Fix for KNDY-5474
     */
    public void checkifContractLinehasPOLine (List<Contract_Line__C> NewRec, List<Contract_Line__C> OldRec){
        
        set<Id> itemIds = new Set<Id>();
        for (Contract_Line__c record: NewRec){
            itemIds.add(record.Id);
        }
        List<Purchase_Order_Line__c> RelatedPOLine = new List<Purchase_Order_Line__c>();
        RelatedPOLine = [Select ID, Contract_Line__c from Purchase_Order_Line__c where Contract_Line__c in :itemIds];
        set<Id> itemswithPOLine = new Set<ID>();
        for (Purchase_Order_Line__c pol : RelatedPOLine){
            itemswithPOLine.add(pol.Contract_Line__c);
        }
        for (integer i=0; i < NewRec.size(); i++){
            if(itemswithPOLine.contains(NewRec[i].Id) && (NewRec[i].item__c <> OldRec[i].item__c)){
                NewRec[i].addError(Label.PurchaseAgreementLine_cannot_be_changed_if_PurchaseOrder_is_created + NewRec[i].Line__c);
            }
        }   
    }

        
    public void updatePOLines(List<Contract_Line__c> records, Map<Id,Contract_Line__c> oldMap) {
    	SchemaUtil util = SchemaUtil.getInstance();

    	Map<Id,List<Purchase_Order_Line__c>> fixedContractLinesAndPOLines = new Map<Id,List<Purchase_Order_Line__c>>();
    	Map<Id,List<Purchase_Order_Line__c>> tieredContractLinesAndPOLines = new Map<Id,List<Purchase_Order_Line__c>>();
    	List<Purchase_Order_Line__c> poLinesToUpdate = new List<Purchase_Order_Line__c>();
    	map<id,Contract_Line__c> contractLinesMap = new map<id,Contract_Line__c>();
   		set<id> contractLineIds = new set<id>();
    	Set<String> fixedControllingFields = new Set<String>();
    	Set<String> tieredControllingFields = new Set<String>();
    	Schema.sObjectType sObjectType = Schema.getGlobalDescribe().get(KSE.NamespaceUU+'Contract_Line__c');
    	
    	List<Schema.FieldSetMember> tieredFields = new List<Schema.FieldSetMember>();
	    	tieredFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'Tiers'));
	    	tieredFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'Extended_Tiers'));
    	
    	for(Schema.FieldSetMember fsm : tieredFields) {
    		tieredControllingFields.add(fsm.getFieldPath());
    	}
    	tieredControllingFields.add(KSE.NamespaceUU+'Type__c');
    	tieredControllingFields.add(KSE.NamespaceUU+'Contract_Quantity__c');
    	
    	fixedControllingFields.add(KSE.NamespaceUU+'Type__c');
    	fixedControllingFields.add(KSE.NamespaceUU+'Negotiated_Price__c');
    	fixedControllingFields.add(KSE.NamespaceUU+'Contract_Quantity__c');
    	
    	for(Contract_Line__c cl : records) {
    		if(cl.Status__c == 'Open') {
	    		if(cl.Type__c == 'Fixed') {
	    			for(String field : fixedControllingFields) {
		    			if(KSE.isFieldChanging(field, cl, oldMap)) {
		    				fixedContractLinesAndPOLines.put(cl.Id,new List<Purchase_Order_Line__c>());
		    			}
	    			}
	    		}
	    		else if(cl.Type__c == 'Tiered') {
	    			for(String field : tieredControllingFields) {
		    			if(KSE.isFieldChanging(field, cl, oldMap)) {
		    				tieredContractLinesAndPOLines.put(cl.Id,new List<Purchase_Order_Line__c>());
		    			}
	    			}
	    			contractLineIds.add(cl.Id);
	    		}
	    	}
    	}
    	//PTP-299 Re-writing PTP-245 as a side effect of fixing PTP-296
    	set<String> clFields = new set<String>();
        clFields.addAll(util.getAllCustomFieldsFromObject('', 'Contract_Line__c'));
        clFields.add('Contract__r.Supplier__c');
        
        string conditional = ' (Id IN : contractLineIds) ';
        SOQLUtil soql = new SOQLUtil('Contract_Line__c', TRUE);
        soql.addFields(clFields);
        soql.setWhereClause(conditional);
        for(Contract_Line__c cl : Database.query(soql.getQuery())) {
            contractLinesMap.put(cl.Id, cl);
    	}
    	
    	for(Purchase_Order_Line__c pol : [SELECT Id, Quantity_Still_Due__c, Status__c, Contract_Line__c, Order_Quantity__c, Contract_Line__r.Contract__r.Update_Open_PO_Lines__c, Contract_Line__r.Negotiated_Price__c,Purchase_Order__r.Status__c,
				    			          (SELECT Id, Line_Type__c, Quantity_Consumed__c, Quantity_Received__c FROM Receipt_Lines__r) 
				    			   FROM Purchase_Order_Line__c
				    			   WHERE (Contract_Line__c IN :fixedContractLinesAndPOLines.keySet() OR Contract_Line__c IN :tieredContractLinesAndPOLines.keySet())
				    			   AND (Contract_Line__r.Contract__r.Update_Open_PO_Lines__c = true) and Status__c = 'Open' and Purchase_Order__r.Status__c = 'Open']) {
			if(fixedContractLinesAndPOLines.containsKey(pol.Contract_Line__c)) {
				List<Purchase_Order_Line__c> poLines = fixedContractLinesAndPOLines.get(pol.Contract_Line__c);
				pol.Unit_Price__c = pol.Contract_Line__r.Negotiated_Price__c; //PTP-299
				poLines.add(pol);
				fixedContractLinesAndPOLines.put(pol.Contract_Line__c, poLines);
			}	
			else if(tieredContractLinesAndPOLines.containsKey(pol.Contract_Line__c)) {
				List<Purchase_Order_Line__c> poLines = tieredContractLinesAndPOLines.get(pol.Contract_Line__c);
				Contract_Line__c cLine = contractLinesMap.get(pol.Contract_Line__c);
				
				//PTP-299 logic to retrieve unit price from tiers and push with PO
				 if (pol.Order_Quantity__c > cLine.Tier_9_Max__c && pol.Order_Quantity__c <= cLine.Tier_10_Max__c)
                    pol.Unit_Price__c = cLine.Tier_10_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_8_Max__c && pol.Order_Quantity__c <= cLine.Tier_9_Max__c)
                    pol.Unit_Price__c = cLine.Tier_9_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_7_Max__c && pol.Order_Quantity__c <= cLine.Tier_8_Max__c)
                    pol.Unit_Price__c = cLine.Tier_8_Price__c;      
                else if (pol.Order_Quantity__c > cLine.Tier_6_Max__c && pol.Order_Quantity__c <= cLine.Tier_7_Max__c)
                    pol.Unit_Price__c = cLine.Tier_7_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_5_Max__c && pol.Order_Quantity__c <= cLine.Tier_6_Max__c)
                    pol.Unit_Price__c = cLine.Tier_6_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_4_Max__c && pol.Order_Quantity__c <= cLine.Tier_5_Max__c)
                    pol.Unit_Price__c = cLine.Tier_5_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_3_Max__c && pol.Order_Quantity__c <= cLine.Tier_4_Max__c)
                    pol.Unit_Price__c = cLine.Tier_4_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_2_Max__c && pol.Order_Quantity__c <= cLine.Tier_3_Max__c)
                    pol.Unit_Price__c = cLine.Tier_3_Price__c;
                else if (pol.Order_Quantity__c > cLine.Tier_1_Max__c && pol.Order_Quantity__c <= cLine.Tier_2_Max__c)
                    pol.Unit_Price__c = cLine.Tier_2_Price__c;
                else if (pol.Order_Quantity__c >= 0 && pol.Order_Quantity__c <= cLine.Tier_1_Max__c)
                    pol.Unit_Price__c = cLine.Tier_1_Price__c;
				
				poLines.add(pol);
				tieredContractLinesAndPOLines.put(pol.Contract_Line__c, poLines);
			}		  			   	
		}
		
		System.Debug(LoggingLevel.Info, fixedContractLinesAndPOLines);
		System.Debug(LoggingLevel.Info, tieredContractLinesAndPOLines);
		
		
		for(Contract_Line__c cl : records) {
			if(fixedContractLinesAndPOLines.containsKey(cl.Id)) {
				for(Purchase_Order_Line__c pol : fixedContractLinesAndPOLines.get(cl.Id)) {
					poLinesToUpdate.add(pol);
				}
			}
			else if(tieredContractLinesAndPOLines.containsKey(cl.Id)) {
				for(Purchase_Order_Line__c pol : tieredContractLinesAndPOLines.get(cl.Id)) {
					poLinesToUpdate.add(pol);
				}
			}
		}
		
		DML.updateAsUser(poLinesToUpdate);
		
    			   
    	
    }

    
    // Defaults the payment terms on purchasing contract header from supplier
    public void defaultPymtTermsFromSupplier(List<Contract__c> contractHeadersToDefault){
    	
    	Set<Id> supplierSet = new Set<Id>();
    
        for( Contract__c ct: contractHeadersToDefault) {
            // set the buyer if empty
            if ( ct.Corporate_Buyer__c == null ) {
                ct.Corporate_Buyer__c = UserInfo.getUserID(); 
            }
    
            // fill in terms
            if (( ct.Payment_Term__c == null && ct.Supplier__c != null ) || (ct.FOB_Term__c == null && ct.Supplier__c != null)){ 
                supplierSet.add( ct.Supplier__c );       
            }
        }
        
        if ( supplierSet.size() > 0 ) {  // avoid query if the terms are all set
	        Map<Id,Supplier__c> myMap = new Map<Id,Supplier__c>( 
	            [ select id, Remit_To__c, Remit_To__r.Payment_Term__c, FOB_Term__c, RecordType.Name, RecordType.DeveloperName, RecordTypeId from Supplier__c where id in :supplierSet ] );
	        
	        for( Contract__c ct: contractHeadersToDefault) {
	            if ( ct.Payment_Term__c == null && ct.Supplier__c != null && myMap.containsKey(ct.Supplier__c) ) {
	                ct.Payment_Term__c = myMap.get(ct.Supplier__c).Remit_To__r.Payment_Term__c; //PTP-218
	            }
	            if ( ct.FOB_Term__c == null && ct.Supplier__c != null && myMap.containsKey(ct.Supplier__c) ) {
	                ct.FOB_Term__c = myMap.get(ct.Supplier__c).FOB_Term__c;
	            }
	        }
        }
    	
    }
    
    //PTP-68 Remove Active flag from Purchase Agreement
    //Flip the approval status to Pending Approval when any field in the FlipPAApprovalStatus fieldset changes
    public void flipPAApprovalStatus_ContractChange (List<Contract__c> records, Map<Id,Contract__c> oldMap) {
    	boolean flipPAStatus = false;
    	for (Contract__c c : records){
	     	SchemaUtil util = SchemaUtil.getInstance();
			for(String str: util.getFieldsFromFieldSetString(Contract__c.sObjectType , 'FlipPAApprovalStatus')){
				if (KSE.isFieldChanging(str, c, oldMap)){
					flipPAStatus = true;
					break;
				}
			}
			if (flipPAStatus && c.Approval_Status__c == 'Approved'){
	 			c.Approval_Status__c = 'Pending Authorization';	
			}
    	}
    }
       //Flip the approval status to Pending Authorization 
       //1. When a new line is added 
       //2. Any field in the FlipPAApprovalStatus fieldset changes
    public void flipPAApprovalStatus_ContractLineChange(){
    	List<Contract_Line__c> clListNew = trigger.new;
    	Map<Id, Contract__c> conMap = new Map<Id, Contract__c>();
    	Set<Id> conIds = new Set<Id>();
    	Boolean updateContract = false;
    	
    	if(trigger.isUpdate || trigger.isInsert){
    		
    		for(Contract_Line__c cl : clListNew){
    			conIds.add(cl.Contract__c);
    		}
    		String whereClause = 'Id IN :conIds';
    		SOQLUtil soql = new SOQLUtil('Contract__c'); 
    		soql.addFields(new set<string>{'Id', 'Approval_Status__c', 'Status__c'});
    		soql.setWhereClause(whereClause);
    		List<Contract__c> conList = Database.query(soql.getQuery());
    		conMap.putAll(conList);	
    		
    		if(trigger.isInsert){
    			for(Contract_Line__c cl : clListNew){
    				if(conMap.containsKey(cl.Contract__c)){
    					if(conMap.get(cl.Contract__c).Approval_Status__c == 'Approved'){
    						conMap.get(cl.Contract__c).Approval_Status__c = 'Pending Authorization';
    					    updateContract = true;	
    					}
    				}
    			}
    		}
    		else{
    			for(Contract_Line__c cl :clListNew){
    				Boolean flipConStatus = false;
	     			SchemaUtil util = SchemaUtil.getInstance();
	     			
	     			for(String str : util.getFieldsFromFieldSetString(Contract_Line__c.sObjectType , 'FlipPAApprovalStatus')){
	     				if (KSE.isFieldChanging(str, cl, Trigger.oldMap)){
    					    flipConStatus = true;
    					    break;		
	     				}
	     			}
	     			if(flipConStatus){
	     				if(conMap.containsKey(cl.Contract__c)){
	     					if(conMap.get(cl.Contract__c).Approval_Status__c == 'Approved'){
    							conMap.get(cl.Contract__c).Approval_Status__c = 'Pending Authorization';
    					    	updateContract = true;
	     					}
	     				}
	     			}
    			}
    		}
    		if(updateContract) {
    		    try{
    		    	DML.updateAsUser(conMap.values());	
    		    }catch(Exception e){
    		    	clListNew[0].addError(e.getMessage());		
    		    }
    		}    
    				
    	}
    }
  
    //Update the Purchase Agreement to Cancelled
    public String CancelPurchaseAgreement ( Id ContractID){
    	Contract__c con = [select id, name, Status__c, PurchasedValue__c from Contract__c where id = :contractID];
    	if (con.PurchasedValue__c == 0)
    		con.Status__c = 'Cancelled';
    	else
			return 'Purchase Agreement with a Purchase Order cannot be Cancelled!';
    	try{
    		DML.updateAsUser(con);
    	}
    	catch (Exception e){
    		return e.getMessage();
    	}
    	return 'Purchase Agreement has been Cancelled!';	
    }
    //Update the Purchase Agreement to Closed
    public String ClosePurchaseAgreement ( Id ContractID){
    	Contract__c con = [select id, name, Status__c from Contract__c where id = :contractID];
		con.Status__c = 'Closed';
    	try{
    		DML.updateAsUser(con);
    	}
    	catch (Exception e){
    		return e.getMessage();
    	}
    	return 'Purchase Agreement has been Closed!';
    }
    //Change Agreement Status to Open when the Agreement is approved first time
    public void updatePAStatusWhenApproved (List<Contract__c> newrecords, List<Contract__c> oldrecords) {
		for (integer i=0; i<newrecords.size(); i++){
			if((newrecords[i].Approval_Status__c <> oldrecords[i].Approval_Status__c) 
				&& (newrecords[i].Approval_Status__c == 'Approved')
				&& (newrecords[i].Status__c == 'Draft')) {
				newrecords[i].Status__c = 'Open';
			}
		}
    }
    //Update Contract Line status to Open when End Date or Qty is updated
    public void updatecLineStatus (List<Contract_Line__c> newrecords, List<Contract_Line__c> oldrecords) {
    	
    	set<id>Ids = new set<id>();
    	for (Contract_Line__c cLine : newrecords){
    		Ids.add(cLine.Contract__c);
    	}
    	Map<id,Contract__c> contractList = new Map<id,Contract__c>([select id, name, Status__c from Contract__c where id in :Ids]);
    	List<Contract__c> contractToUpdate = new List<Contract__c>();
    	set<Contract__c> tempContract = new set<Contract__c>();
   
    	for (integer i=0; i<newrecords.size(); i++){
    		if ((newrecords[i].Contract_End__c <> oldrecords[i].Contract_End__c) || (newrecords[i].Contract_Quantity__c <> oldrecords[i].Contract_Quantity__c)
    			|| (newrecords[i].Remaining_Quantity__c <> oldrecords[i].Remaining_Quantity__c)){ //Adding Remaining Qty here to make sure when netting batch updates remaining qty, status is flipped to open
    			if (newrecords[i].Status__c == 'Closed' || newrecords[i].status__c == 'Expired'){
    				newrecords[i].Status__c = 'Open';
    				Contract__c c = contractList.get(newrecords[i].Contract__c);
    				if(c.Status__c != 'Open'){
    					c.Status__c = 'Open';
    					tempContract.add(c);
    				}
				}
			}
    		//KNDY-6196 Flip the contract status to Open when the line status is flipped to open
    		if ((newrecords[i].Status__c <> oldrecords[i].Status__c) && (newrecords[i].Status__c == 'Open' && oldrecords[i].Status__c != 'Draft')){
    			Contract__c c = contractList.get(newrecords[i].Contract__c);
				if(c.Status__c != 'Open'){
					c.Status__c = 'Open';
					tempContract.add(c);
				}
    		}
    	}
    	contractToUpdate.addall(tempContract);
    	if (contractToUpdate.size() > 0){
    		try{
    			DML.updateAsUser(contractToUpdate);
    		}catch(Exception e){
    			newrecords[0].addError(e.getmessage());
    		}
    	}
    }
    //Update all lines to Closed/Cancelled when Agreement is closed/cancelled
    //Agreement can be closed/cancelled only from UI so only one record is processed at a time
    public void updatelineStatusonHeaderChange (List<Contract__c> newrecords, List<Contract__c> oldrecords){ 
    	
    	List<Contract_Line__c> cLinestoUpdate = new List<Contract_Line__c> ();
    	boolean saveCLines = false;
    	cLinestoUpdate = [select id, name, Status__c from Contract_Line__c where Contract__c = :newrecords[0].id and Status__c = 'Open'];
		if(newrecords[0].Status__c <> oldrecords[0].Status__c && 
			(newrecords[0].Status__c == 'Closed' || newrecords[0].Status__c == 'Cancelled')){
			for (Contract_Line__c cLine : cLinestoUpdate){
				cLine.Status__c = newrecords[0].Status__c; 
				saveCLines = true;
			}	
		}
		if (saveCLines){
			try{
    			DML.updateAsUser(cLinestoUpdate); //save only if any records are changed
    		}catch(Exception e){
    			newrecords[0].addError(e.getmessage());
    		}
		}
    }
    //Update Agreement Header to Expired when the Agreement End Date<today
    public void updateAgreementtoExpired (List<Contract_Line__c> newrecords){
    	
    	set<id> Ids = new set<id>();
    	for (Contract_Line__c cLineId : newrecords){
    		Ids.add(cLineId.Contract__c);
    	}
    	
    	Map<id,contract__c> contractList = new Map<id,Contract__c> ([select id, name, status__c, Contract_End__c from Contract__c where id in :Ids]);
    	List<Contract__c> contractToUpdate = new List<Contract__c>();
    	for (Contract_Line__c cLine : newrecords){
    		Contract__c c = contractList.get(cLine.Contract__c);
    		if (c.Status__c == 'Open' && c.Contract_End__c < system.today()){
    			c.Status__c = 'Expired';
    			contractToUpdate.add(c);
    		}
    	}
    	if (contractToUpdate.size() > 0){
    		DML.updateAsUser(contractToUpdate);
    	}
    }
    /****Commented this method since this logic is covered in VoidCancelService  (as part of PTP-392)
    
    //Check if the Agreement can be edited
    public void checkifAgreementCanbeEdited (List<Contract__c> newrecords, List<Contract__c> oldrecords){
    	
    	for (integer i=0; i<newrecords.size(); i++){
			if (oldrecords[i].status__c == 'Cancelled'){    //PTP-302 Changed the conditions so that statuses with open, closed, expired agreements can be edited. 
				if (newrecords[i].status__c == 'Cancelled') {         
					newrecords[i].addError('Cancelled Purchase Agreement cannot be edited');
				}
			}
    	}
    }
    ******/
    //Validate for Item Cross reference on items with ASL Override OFF
    public Map<String,String> ValidateItemCrossReference (List<Contract_Line__c> records, ID supplierID, ID facilityID){
    	
    	set<id> itemIds = new set<id>();    	
    	map<String,String> cLinesErroredforICR = new Map<String,String>(); //This map is used to verify what lines errored out for ASL on and ASL off
    	string errorsforASLOn = '';
    	string errorsforASLOff = '';
    	List<Item_Cross_Reference__c> icrList = new List<Item_Cross_Reference__c>();
    	Map<string,Item_Cross_Reference__c> icrMap = new Map<string,Item_Cross_Reference__c>();
        for(Contract_Line__c record:records){
    		if (record.ASL_Override__c == false){
    			itemIds.add(record.Item__c);
    		}
        }
		map<id,Item__c> itemsApprovedSuppliermap = new map<id,Item__c>([select id, name, Approved_Supplier_Required__c from Item__c where id in:ItemIds]);
        //Set consigned flag by fetching all the Item Cross Reference Records
        icrList = [Select id, Name, Active__c, Approval_Status__c, Item__c, Item__r.name, Item__r.Approved_Supplier_Required__c, Consigned__c, Supplier__c, Ship_to_Facility__c FROM Item_Cross_Reference__c where Item__c in:itemIds and Active__c = true and Approval_Status__c = 'Approved' and Cross_Reference_Type__c = 'Supplier' order by createdDate];
        for (Item_Cross_Reference__c icr:icrList){
        	if (icrMap.containsKey(icr.Item__c + ',' + icr.Supplier__c + ',' + icr.Ship_to_Facility__c)==false){
        	icrMap.put(icr.Item__c + ',' + icr.Supplier__c + ',' + icr.Ship_to_Facility__c, icr);
        }
        }
        for (Contract_Line__c cLine:records){
        	boolean isConsignedSet = false;
    	
            //KNDY-9593 - If ICR exists add the link to the agreement line
            if(icrMap.containsKey(cLine.Item__c+','+ supplierID + ',' + facilityID)){
                cLine.Item_Cross_Reference__c = icrMap.get(cLine.Item__c+','+supplierID + ',' + facilityID).id;
            }
            else if (icrMap.containsKey(cLine.Item__c+','+supplierID + ','+null)){
                cLine.Item_Cross_Reference__c = icrMap.get(cLine.Item__c+','+ supplierID + ','+null).id;
            }
    	
        	if (cLine.ASL_Override__c == false){
				if(icrMap.containsKey(cLine.Item__c+','+ supplierID + ',' + facilityID)){
					isConsignedSet = true;
					cLine.consigned__c = icrMap.get(cLine.Item__c+','+supplierID + ',' + facilityID).consigned__c;
				}
				if(isConsignedSet == false && icrMap.containsKey(cLine.Item__c+','+supplierID + ','+null)){
					isConsignedSet = true;
					cLine.consigned__c = icrMap.get(cLine.Item__c+','+ supplierID + ','+null).consigned__c;
				}
				if(isConsignedSet == false){
					if (itemsApprovedSuppliermap.get(cLine.Item__c).Approved_Supplier_Required__c){ 
						errorsforASLOn = errorsforASLOn + cLine.Line__c+ ',';
					}
					else {
						errorsforASLOff = errorsforASLOff + cLine.Line__c+ ',';
					}
				}
        	}
        }
        if (errorsforASLOn.length() > 0 )
			errorsforASLOn = errorsforASLOn.subString(0,errorsforASLOn.length()-1);
		if (errorsforASLOff.length() > 0 )
			errorsforASLOff = errorsforASLOff.subString(0,errorsforASLOff.length()-1);

        cLinesErroredforICR.put('ASLOn',errorsforASLOn);
        cLinesErroredforICR.put('ASLOff',errorsforASLOff);
        return cLinesErroredforICR;
    }
    //PTP-63 Tier based pricing error when the quantity released is greater than the largest tier
    public boolean isQtyWithinTiers (Double quantityToRelease, Contract_Line__c cLine){
    	
    	boolean isQtywithinTiers = false;
    	if (cLine.Type__c == 'Fixed'){
    		isQtywithinTiers = True;
    	}else{
    		if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_9_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_10_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_8_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_9_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_7_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_8_Max__c,0)) 
				isQtywithinTiers = True;	
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_6_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_7_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_5_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_6_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_4_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_5_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_3_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_4_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_2_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_3_Max__c,0)) 
				isQtywithinTiers = True;
			else if ((quantityToRelease > KSE.addQuantityToField(cLine.Tier_1_Max__c,0)) && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_2_Max__c,0)) 
				isQtywithinTiers = True;
			else if (quantityToRelease >= 0 && quantityToRelease <= KSE.addQuantityToField(cLine.Tier_1_Max__c,0)) 
				isQtywithinTiers = True;
    	}
    	return isQtywithinTiers;
    }
    //PTP-178 Set Lines to approved when the header is Approved
    public void setContractLinestoApproved (List<Contract__c> newrecords, List<Contract__c> oldrecords){
    	
    	set<id> cIds = new set<id>();
    	List<Contract_Line__c> cLines = new List<Contract_Line__c>();
    	
    	for (integer i = 0 ; i<newrecords.size() ; i++){
    		if ((newrecords[i].Approval_Status__c <> oldrecords[i].Approval_Status__c) && (newrecords[i].Approval_Status__c == 'Approved'))
    			cIds.add(newrecords[i].id);
    	}
    	cLines = [select id, name, Approved__c from Contract_Line__c where contract__c in :cIds and Approved__c = false];
    	if(cLines.size() > 0){
	    	for (Contract_Line__c cLine : cLines){
	    		cLine.Approved__c = true;
	    	}
	    	try{
	    		DML.updateAsUser(cLines);
	    	}catch(exception e){
	    		newrecords[0].addError(e.getmessage());
	    	}
    	}
    }
    
    //PTP-306 Run AVL validations on Cloned PA Lines
    //if the cloned PA line fails AVL validation, retain the PA Line in draft status so that one can't release against that PA line
    public void runAVLValidationsOnClonedLines () {
    	if(trigger.isExecuting){
			if(trigger.isBefore && trigger.isUpdate){
				
				List<Contract__c> paToOpenRecords = new List<Contract__c>();
				List<Contract_Line__c> paLinesToUpdate = new List<Contract_Line__c>();
		        
		        for (Contract__c recordToOpen: (List<Contract__c>)Trigger.new){
		        	
		        	if (KSE.isFieldChanging('Status__c', recordToOpen, Trigger.oldMap)){
			        	if (recordToOpen.Status__c == 'Open' && ((Contract__c)Trigger.oldMap.get(recordToOpen.Id)).Status__c == 'Draft'){ // only look at records where status moves from Draft to Open
			        
			            	if (!openPAIds.contains(recordToOpen.id)){ // if ID is not in static list then move forward
			            		paToOpenRecords.add(recordToOpen); // build a list of trigger records to iterate over
			            		openPAIds.add(recordToOpen.id); // add it to static set of IDs to prevent recursion
			            	}
			        	}
		        	}
		        }
		        
		        //Now we have a list of all PA records which are going to Open status and need to pass ASL validation
    			if (paToOpenRecords.size() > 0){ // Only process if any records present
			        //Query all related lines to the header records. 
			        Map<Id, List<Contract_Line__c>> mapPAToPALines = new Map<Id, List<Contract_Line__c>>();
			     	for (Contract_Line__c paLine: [select id, Name,Contract__c, ASL_Override__c, Item__c, Line__c, Status__c from Contract_Line__c where Status__c = 'Draft' and Contract__c in :paToOpenRecords]){
			     		if (mapPAToPALines.containsKey(paLine.Contract__c)){
			     			mapPAToPALines.get(paLine.Contract__c).add(paLine);
			     		}else{
			     			mapPAToPALines.put(paLine.Contract__c, new List<Contract_Line__c>{paLine});
			     		}
			     	}
			     	
			     	//Now we have all related PA Lines tied to those PA headers in a Map  							
			    	//iterate over the trigger PA records in question
			        for (Contract__c paToOpen: paToOpenRecords){
			        	Map<Decimal, Contract_Line__c> paLineClonedRecordsMap = new Map<Decimal, Contract_Line__c>(); //Line # to PA Line map	
			    	    
			    	    if (mapPAToPALines.containsKey(paToOpen.id)){ //Sanity check for PAs where line is in Open mode. Not originating from a Cloned PA. This will allow to skip processing below
	    					if (mapPAToPALines.get(paToOpen.id).size() > 0){
	    						for (Contract_Line__c paLine: mapPAToPALines.get(paToOpen.id)){
				        			paLineClonedRecordsMap.put(paLine.Line__c, paLine); //Build a map of Line # to PA Line 
				        		}
	    					}
	    					//Now pass this along to validation service
	    					map<String,string> errorRec = ValidateItemCrossReference(paLineClonedRecordsMap.values(),paToOpen.Supplier__c, paToOpen.Ship_to_Facility__c); 
				        	
				        	//errorRec returns a list of Line #'s that have ASL turned on that fail ASL validation and ones turned off which pass ASL validation
	    					List<String> lineNumberTokensASLOn = new List<String>();
	    					if (errorRec.containsKey('ASLOn')){// line numbers that have ASL on and failed validation
						        if (errorRec.get('ASLOn').length() > 0){
						        	
						        	lineNumberTokensASLOn = errorRec.get('ASLOn').split(',', -1); //extracting the line number tokens
						        	
						        	for (String lineNumberToken: lineNumberTokensASLOn){
						        		paLineClonedRecordsMap.get(Decimal.valueOf(lineNumberToken)).Status__c = 'Draft'; // Setting the status to Draft on Line(s) that failed validation
						        	}
						        	paToOpen.Status__c = 'Draft';
						        }
						        if (errorRec.get('ASLOff').length() > 0){// line numbers that have ASL off and passed validation
						        	
						        	List<String> lineNumberTokensASLOff = errorRec.get('ASLOff').split(',', -1);
						        	
						        	for (String lineNumberToken: lineNumberTokensASLOff){
						        		paLineClonedRecordsMap.get(Decimal.valueOf(lineNumberToken)).Status__c = 'Open';// Setting the status to Open on Line(s) that passed validation
						        	}
						        }//else{// Lines that have ASL turned on and passed validation meaning ICR was found
						        	Map<String, String> lineNumberTokensASLOnMap = new Map<String, String>();
						        	for (String token: lineNumberTokensASLOn){
						        		lineNumberTokensASLOnMap.put(token, token);
						        	}
	    							
						        	for (Contract_Line__c paLineICRFound: paLineClonedRecordsMap.values()){
						        		if (!lineNumberTokensASLOnMap.containsKey(String.valueOf(paLineICRFound.Line__c) ))
						        			paLineICRFound.Status__c = 'Open';
						        	}
						       // }
					        }
					    	paLinesToUpdate.addAll(paLineClonedRecordsMap.values());    
			        	}
			        }
			        
			        Savepoint sp = Database.setSavepoint();
					try{
						if (paLinesToUpdate.size() > 0)	
			        		DML.updateAsUser(paLinesToUpdate);
		        	}catch(Exception ex){
		    			database.rollback(sp);
		    		}
			        
    			}
			}
    	}
    	
    }
    
    //PTP-503
    public static DataSourceResult checkifPaLineisApproved (List<Contract_Line__c> deletePALines){
        DataSourceResult result = new DataSourceResult();
        String errorRecords = '';
        
        for (Contract_Line__c cLine : deletePALines){
            if (cLine.Approved__c == true){
                errorRecords = errorRecords + cLine.Line__c +', ';
            }
        }
        
        if(errorRecords != ''){
            errorRecords = (errorRecords.subString(0,errorRecords.length()-2) + '.');
            result.success = false;
            result.addMessage(Label.Purchase_Agreement_Line_cannot_be_deleted + errorRecords, ApexPages.Severity.ERROR);
        }
        return result;   
    }
    
    public void approvedContractLineValidation(List<Contract_Line__c> deleteConLines){
    	for( Contract_Line__c ctl : deleteConLines) {
			if(ctl.Approved__c) {
				ctl.addError('Approved Contract lines cannot be deleted.');
			}
		}	
    } 
    
    //PTM-505 MRP Unable to Lock row - Making item as an optional field and including the validation on page layout and trigger to capture the item
	public void checkifContractLinehasItem (List<Contract_Line__c> newLines){
    	
    	for (Contract_Line__c cLine : newLines){
    		if (cLine.Item__c == null){
    			cLine.addError(Label.Cannot_add_a_Contract_Line_without_an_item);
    		}
    	}	
    }
    //PTP-452
    public static DataSourceResult paLineItemnotblank(List<Contract_Line__c> updatedList, List<sObject> newList) {
        DataSourceResult result = new DataSourceResult();
        String errorRecords = '';
        List<Contract_Line__c> newclList = new List<Contract_Line__c>();
        for(sobject row : newList){
        	Contract_Line__c ctl = (Contract_Line__c)row;
        	newclList.add(ctl);
        }
        
        if (updatedList.size() > 0 ){
        	newcllist.addall(updatedList);
        } 	
        	
    	for(Contract_Line__c ctl: newclList){
        	if(ctl.Item__c == null){
        		errorRecords = errorRecords + ctl.Line__c +', ';
        	}
        }
        if(errorRecords != ''){
        	errorRecords = (errorRecords.subString(0,errorRecords.length()-2) + '.');
	        result.success = false;
	        result.addMessage(Label.Item_cannot_be_blank + ' ' + errorRecords, ApexPages.Severity.ERROR);
	    }
	    return result;	
    }
    
    @future
    public static void futurecall(Id purchaseAgreementId){ 
    	Boolean savePa = false;
    	JsonResult result = new JsonResult();
    	
    	if (!String.isEmpty(purchaseAgreementId)){
        	SOQLUtil paSoql = new SOQLUtil ( 'Contract__c' );
    	    Set<String> paFields = new Set<String> {
    	                              'ID', 'Name', 'Status__c', 'Approval_Status__c'
    	                       };
    	    paSoql.addFields( paFields);
    	    paSoql.setWhereClause ( 'ID = :purchaseAgreementId');
    	    Contract__c pa = Database.query(paSoql.getQuery());
        	pa.Approval_Status__c = pa.Approval_Status__c == 'Pending Authorization' ? 'Approved' : pa.Approval_Status__c;
        	Savepoint sp = Database.setSavepoint(); 
        	try{
        		DML.updateAsUser(new List<Contract__c>{pa});	
        		savepa = true;
        	
       		}catch(Exception e){ 
       			Database.rollback(sp);	 
       			sendApproveFailedEmail(purchaseAgreementId, e);	
         	 
         	}
         	
         	
         	if(savepa){
              sendApproveSuccessEmail(purchaseAgreementId);
        	} 
    	} else{
        	result.success = false; 
     	}
      
    }
    public static String getPAData(Id purchaseAgreementId, String fieldName){
      
      Contract__c PA;
      
      if(PA == Null){
        PA = new Contract__c();
        PA = getPADetails(purchaseAgreementId);
        
      }             
      if(fieldName.equals('PAName')){
        
        return String.valueOf(PA.name);
      }
      
      return null;
                        
    }
    public static Contract__c getPADetails(Id purchaseAgreementId){
      
        Contract__c PA = [select name,
                        Approval_Status__c
                       from Contract__c
                          WHERE id = :String.valueOf(purchaseAgreementId)
                           ];
                           
    	return PA;
    }
    public static void sendApproveSuccessEmail(Id purchaseAgreementId){
      
      String emailSubject = label.PA_Approve_email_subject ;
      String emailMessage = Label.PA_Approve_email_success_message;
      String PAId = String.valueOf(purchaseAgreementId);
      
      String PAName = getPAData(purchaseAgreementId, 'PAName');
      
      String PASubjectMatchingString = '{PAName}';
      String PAMessageMatchingString = '{PALink}';
            
      if(emailSubject.contains(PASubjectMatchingString)){
        
        emailSubject = emailSubject.replace(PASubjectMatchingString, PAName);
      }
      
      if(emailMessage.contains(PAMessageMatchingString)){
        
        String PALink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + PAId.substring(0, PAId.length() - 3);
        
        emailMessage = emailMessage.replace(PAMessageMatchingString, PALink);
      }
      
      KSE.sendEmailBatchCompletion(emailMessage, emailSubject);
      
      
    }
    Public static void sendApproveFailedEmail(Id purchaseAgreementId, Exception e){
      String emailSubject = label.PA_Approve_email_failure_subject;
      String emailMessage = label.PA_Approve_email_failure_message;
      String PAId = String.valueOf(purchaseAgreementId);
      
      String PAName = getPAData(purchaseAgreementId, 'PAName');
      
      String PASubjectMatchingString = '{PAName}';
      String PAMessageMatchingString = '{PALink}';
            
      if(emailSubject.contains(PASubjectMatchingString)){
        
        emailSubject = emailSubject.replace(PASubjectMatchingString, PAName);
      }
      
      if(emailMessage.contains(PAMessageMatchingString)){
        
        String PALink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + PAId.substring(0, PAId.length() - 3);
        
        String eMessage = emailMessage.replace(PAMessageMatchingString, PALink);
        emailMessage = eMessage + '<br/>'+ e;
        
      }
      
      KSE.sendEmailBatchCompletion(emailMessage, emailSubject);	
    }
    
    public JsonResult headerActions (id purchaseAgreementId, string status){

        JsonResult result = new JsonResult();
        List<Contract_Line__c> paLinestoUpdate = new List<Contract_Line__c>();
        Boolean savePa = false;
        Boolean deletePa = true;
            
        if (!String.isEmpty(purchaseAgreementId)){
           Contract__c pa = [select Id, Name, Status__c, Approval_Status__c, (select Id, Name, Line__c, Status__c, Approved__c, Quantity_Still_Due__c,PurchasedValue__c,Remaining_Quantity__c from Contract_Lines__r where Approved__c = false ) from Contract__c where id = :purchaseAgreementId];
      				
            //For Approval, just set the header to approved and exit the function
            
            if (status == 'Approved') { 
            	//If CS is null just return 100 as default value (This is needed for Unit test cases)
      			Configuration__c c = Configuration__c.getValues('MaxLinesforAction');
      			Integer AsyncThreshold = (c != null ? Integer.valueOf(c.Value__c) : 100) ;
      			//Check if total PA lines > 100 
      			
      			if(pa.Contract_Lines__r.size() >= AsyncThreshold){
        			result.addMessage(label.Purchase_Agreement_Approval_batch_warning_message , ApexPages.Severity.CONFIRM);
        			
        			futurecall(purchaseAgreementId);
        			return result;
      			} else {
                	pa.Approval_Status__c = pa.Approval_Status__c == 'Pending Authorization' ? status : pa.Approval_Status__c;
                	savePa = true;
      			}
            }
            else if (status == 'Closed'){
                pa.Status__c = pa.Status__c == 'Open' ? status : pa.Status__c;
                savePa = true;
                if (pa.Contract_Lines__r.size() > 0){
                    result = closeContractLines(pa.Contract_Lines__r);
                }
            }
            else if (status == 'Cancelled') {
                pa.Status__c = pa.Status__c == 'Open' ? status : pa.Status__c;
                savePa = true;
                if (pa.Contract_Lines__r.size() > 0){
                    result = cancelContractLines(pa.Contract_Lines__r);
                }
            }
            else if (status == 'Delete') {
                for (Contract_Line__c pal : pa.Contract_Lines__r){
                    if (pal.Approved__c){
                        deletePa = false;
                        break;
                    }
                }
                if (deletePa){
                    DML.deleteAsUser(new List<Contract__c>{pa});
                }
                else{
                    result.success = false;
                    result.addMessage(Label.Cannot_delete_purchase_agreement,ApexPages.Severity.ERROR);
                }
            }

            if (result.success == true){
                //Update the PA
                if (savePa)
                    DML.updateAsUser(new List<Contract__c>{pa});
                
            }
        }
        else{
            result.success = false;
            result.addMessage(Label.Cannot_perform_any_action_save_the_purchase_agreement_to_proceed, ApexPages.Severity.ERROR);
        }

        return result;
    }
    
    public JsonResult closeContractLines (List<Contract_Line__c> paLines){

        JsonResult result = new JsonResult();
        List<Contract_Line__c> paLinestoUpdate = new List<Contract_Line__c>();
        String errorPaLines = '';
        for (Contract_Line__c pal : paLines){
            if (pal.Approved__c && pal.Status__c == 'Open'){
                pal.Status__c = 'Closed';
                paLinestoUpdate.add(pal);
            }
            else{
                errorPaLines = errorPaLines + pal.Line__c + ', ';
            }
        }

        if (!String.isBlank(errorPaLines)){
            errorPaLines = errorPaLines.subString(0,errorPaLines.length()-2);
            result.addMessage(Label.Agreement_Lines_cannot_be_closed + errorPaLines ,ApexPages.Severity.ERROR);
            result.success = false;
            return result;
        }

        Savepoint sp = Database.setSavepoint();
        try{
            if (paLinestoUpdate.size() >0 )
                DML.updateAsUser(paLines);
        }
        catch(Exception e){
            Database.rollback( sp );
            result.success = false;
            result.addMessage('Cannot close/cancel', ApexPages.Severity.ERROR);
        }
        return result; 
    }
    
    public void reopenContractLines (List<Contract_Line__c> newList,List<Contract_Line__c> oldList) {
       
        List<Contract_Line__c> contractLinesList = new List<Contract_Line__c>();
        
        for (integer i=0; i<newList.size(); i++){
                if ((newList[i].Negotiated_Price__c <> oldList[i].Negotiated_Price__c) || (newList[i].Contract_Quantity__c <> oldList[i].Contract_Quantity__c)){
                    contractLinesList.add(newList[i]);
                }
        }
        
        if (contractLinesList.size()>0){
            for (Contract_Line__c cLine : contractLinesList){
                if (cLine.ID != null) {
                    if ((cLine.Status__c == 'Closed'||cLine.Status__c == 'Cancelled') && cLine.Approved__c == true && cLine.Remaining_Quantity__c > 0){
                        cLine.Status__c = 'Open';
                    }
                    
                }   
            }   
        }
    }
    
    public  JsonResult cancelContractLines (List<Contract_Line__c> updatedList) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        List<Contract_Line__c> contractLinesList = new List<Contract_Line__c>();
        
        string errorRecords_POs = '';
        string errorRecords_Status = '';
        string errorRecords_Approved = '';
        
        if (updatedList.size()>0){
            for (Contract_Line__c cLine : updatedList){
                if(KSE.addQuantityToField(cLine.PurchasedValue__c,0) != 0){
                    errorRecords_POs = errorRecords_POs + cLine.Line__c + ',';
                }
                else if(cLine.Status__c != 'Open'){
                    errorRecords_Status = errorRecords_Status + cLine.Line__c + ',';
                }
                else if(cLine.Approved__c != true){
                    errorRecords_Approved = errorRecords_Approved + cLine.Line__c + ',';
                }   
                else {
                    cLine.Status__c = 'Cancelled';
                    contractLinesList.add(cLine);
                }
                    }
            if (errorRecords_POs.length() > 0 || errorRecords_Status.length() > 0 || errorRecords_Approved.length() > 0){
                if (errorRecords_POs.length() > 0){
                    errorRecords_POs = errorRecords_POs.subString(0,errorRecords_POs.length()-1);
                    result.success = false;
                    result.addMessage(Label.Agreement_lines_with_PO_cannot_be_cancelled+errorRecords_POs, ApexPages.Severity.Error);
                }
                if (errorRecords_Status.length() > 0){
                    errorRecords_Status = errorRecords_Status.subString(0,errorRecords_Status.length()-1);
                    result.success = false;
                    result.addMessage(Label.Agreement_Lines_not_open_cannot_be_cancelled+errorRecords_Status, ApexPages.Severity.Error);
                }
                if(errorRecords_Approved.length() > 0){
                    errorRecords_Approved = errorRecords_Approved.subString(0,errorRecords_Approved.length()-1);
                result.success = false;
                    result.addMessage(Label.Unapproved_Agreement_Lines_cannot_be_cancelled+errorRecords_Approved, ApexPages.Severity.Error);
                }
                return result;
            }   
            else{
                try{
                    if (contractLinesList.size() > 0){
                        DML.updateAsUser(contractLinesList);
                            result.addMessage(Label.Lines_cancelled_successfully, ApexPages.Severity.CONFIRM); 
                    }
                } catch (Exception e) {
                Database.rollback(sp);
                result.success = false;
                result.addMessage(e, ApexPages.Severity.ERROR);
                }   
            }
        }
        
        Integer total = (contractLinesList != null) ? contractLinesList.size() : 0;
        result.total = total;
        result.records = contractLinesList;
        
        return result;
    }
    public void defaultInvoiceMatchingFromSupplier(List<Contract_Line__c>paLines){
    	set<Id> ctIds = new set<Id>();
    	List<Contract_Line__c> ctl = new List<Contract_Line__c>();
    	for(Contract_Line__c ctLine : paLines){
    		if(ctLine.Invoice_Matching__c == null && ctLine.Approved__c == false){
    			ctIds.add(ctLine.Contract__c);
    		}
    	} 
    	if(ctIds.size() > 0){
    	    SOQLUtil conSoql = new SOQLUtil ( 'Contract__c');
    	    Set<String> conFields = new Set<String> {
    	                                 'ID', 'Supplier__c', 'Approval_Status__c','Supplier__r.Invoice_Matching__c'
    	                             };
    	    conSoql.addFields( conFields );
    	    conSoql.setWhereClause ( 'ID IN :ctIds' );
    	    Map<Id,Contract__c> paWithNullInvoiceMatching = new Map<Id,Contract__c>( (List<Contract__c>) Database.query ( conSoql.getQuery() ) );
    	//	Map<Id,Contract__c> paWithNullInvoiceMatching = new Map<Id,Contract__c>([select id, Supplier__c, Supplier__r.Invoice_Matching__c FROM Contract__c WHERE Id IN :ctIds]);
    	
			for (Contract_Line__c ctLine : paLines){
				if(ctLine.Invoice_Matching__c == null && paWithNullInvoiceMatching.containsKey(ctLine.Contract__c) ){
					ctLine.Invoice_Matching__c = paWithNullInvoiceMatching.get(ctLine.Contract__c).Supplier__r.Invoice_Matching__c;
					ctl.add(ctline);
				}
				
			}
    	}
	
    }

    public static boolean showHideSourcingGrid(){

        Configuration__c c = Configuration__c.getValues('showSourcingGrid');
        if (c != null) {
            return true;
        }
        else{
            return false;
        }

    }

}