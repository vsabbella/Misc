public with sharing class CheckService{
    public CheckService(){
    }
    /*************************
    Description : Method used to cloneObjects with all fields populated from given object record
    Params : @sObjects - List of sobjects to be cloned
    @ objectType = object type
    */
    public static List<sObject> cloneObjects(List<sObject> sObjects,Schema.SObjectType objectType){
    
	    // A list of IDs representing the objects to clone
	    List<Id> sObjectIds = new List<Id>{};
	    // A list of fields for the sObject being cloned
	    List<String> sObjectFields = new List<String>{};
	    // A list of new cloned sObjects
	    List<sObject> clonedSObjects = new List<sObject>{};
	    
	    // Get all the fields from the selected object type using 
	    // the get describe method on the object type.
	    if(objectType != null){
	    	sObjectFields.addAll(objectType.getDescribe().fields.getMap().keySet());
	    }
	    
	    // If there are no objects sent into the method, 
	    // then return an empty list
	    if (sObjects != null && !sObjects.isEmpty() && !sObjectFields.isEmpty()){
		      // Strip down the objects to just a list of Ids.
		      for (sObject objectInstance: sObjects){
		        sObjectIds.add(objectInstance.Id);
		      }
	
		      /* Using the list of sObject IDs and the object type, 
			 we can construct a string based SOQL query 
			 to retrieve the field values of all the objects.*/
		    
		      String allSObjectFieldsQuery = 'SELECT ' + sObjectFields.get(0); 
		    
		      for (Integer i=1 ; i < sObjectFields.size() ; i++){
		        	allSObjectFieldsQuery += ', ' + sObjectFields.get(i);
		      }
		    
		      allSObjectFieldsQuery += ' FROM ' + 
		                               objectType.getDescribe().getName() + 
		                               ' WHERE ID IN (\'' + sObjectIds.get(0) + 
		                               '\'';
		
		      for (Integer i=1 ; i < sObjectIds.size() ; i++){
		        	allSObjectFieldsQuery += ', \'' + sObjectIds.get(i) + '\'';
		      }
		    
		      allSObjectFieldsQuery += ')';
		    
		      try{
		      
			        // Execute the query. For every result returned, 
			        // use the clone method on the generic sObject 
			        // and add to the collection of cloned objects
			        for (SObject sObjectFromDatabase:
			             Database.query(allSObjectFieldsQuery)){
			          clonedSObjects.add(sObjectFromDatabase.clone(false,false));  
			        }
		    
		      } catch (exception e){
			        // Write exception capture method 
			        // relevant to your organisation. 
			        // Debug message, Apex page message or 
			        // generated email are all recommended options.
		      }
	    }    
	    
	    // return the cloned sObject collection.
	    return clonedSObjects;
  	}

  	/*************************
    Description : Method used to fetch skipped check details once number of advice lines are applied
    Params : @sObjChildLinesList : List<AggregateResult> - List of child objects agrregate result showing id of main object and count of lines as cnt
    e.g SELECT  Supplier_Payment__c Id, COUNT(Id) cnt FROM Supplier_Payment_Line__c WHERE Supplier_Payment__c IN :supplierPaymentBySupplierMap.values() GROUP BY Supplier_Payment__c
    @bankAcc: Bank_Account__c - bank account object with necessary fields including next check number
    Return params :
     Map<id,Map<decimal,sObject>> : map of Id of main object and followed by check number and sobject id( cloned object returns null initially) map. 
    @ objectType = object type
    */
  	public static Map<id,Map<decimal,sObject>> getSkippedCheckDetails(Map<Id,integer> sObjectChildLinesAggregateMap,Bank_Account__c bankAcc){
  		
  		Map<id,Map<decimal,sObject>> skippedCheckRecordMap = new Map<Id,Map<decimal,sObject>>();
  		Map<decimal,sObject> tempCheckMap = new Map<decimal,sObject>();
  		//KNDY-18900 Replace next check number (number) field with text field  
		decimal checkNumber = bankAcc.Next_Check_Number_2__c == null ? 1 : Decimal.valueOf(bankAcc.Next_Check_Number_2__c) + 1;
		for (id recordId :sObjectChildLinesAggregateMap.keyset()){
			skippedCheckRecordMap.put(recordId,null);
			tempCheckMap = new Map<decimal,sObject>();
			integer childCnt =  sObjectChildLinesAggregateMap.get(recordId);
			if (bankAcc.Use_Pre_Printed_Check_Stock__c && bankAcc.Number_of_Advice_Lines_Per_Page__c < childCnt ){
				//create cancelled SPs
				decimal skipChecks = childCnt/bankAcc.Number_of_Advice_Lines_Per_Page__c;
				system.debug(LoggingLevel.Error,'skipChecks=' + skipChecks +'=' + skipChecks.setScale(0,System.Roundingmode.UP) );
				for (integer i = 0 ; i< skipChecks.setScale(0,System.Roundingmode.UP)-1 ; i++){
					tempCheckMap.put(checkNumber,null);
					checkNumber++;
				}
				skippedCheckRecordMap.put(recordId,tempCheckMap);
			}
			system.debug(LoggingLevel.Error,'skippedCheckRecordMap=='+skippedCheckRecordMap);
		}		
		return skippedCheckRecordMap;
  	} 
  	/*************************
    Description : Method used to fetch skipped check details once number of advice lines are applied. Used for single record
    Params : @childRecCount : integer - child record count    
    @recordId : Id : pass master record Id
    @bankAcc: Bank_Account__c - bank account object with necessary fields including next check number
    Return params :
     Map<id,Map<decimal,sObject>> : map of Id of main object and followed by check number and sobject id( cloned object returns null initially) map. 
    @ objectType = object type
    */
  	public static Map<id,Map<decimal,sObject>> getSkippedCheckDetailsForSingleRecord(integer childRecCount, Id recordId,Bank_Account__c bankAcc){
  		Map<Id,integer> sObjectChildLinesAggregateMap = new Map<id,integer>();
  		Map<id,Map<decimal,sObject>> skippedCheckRecordMap = new Map<Id,Map<decimal,sObject>>();
  		Map<decimal,sObject> tempCheckMap = new Map<decimal,sObject>();
  		
		sObjectChildLinesAggregateMap.put(recordId, childRecCount);
		skippedCheckRecordMap.put(recordId,null); 
		//KNDY-18900 Replace next check number (number) field with text field 
		decimal checkNumber = bankAcc.Next_Check_Number_2__c == null ? 1 : Decimal.valueOf(bankAcc.Next_Check_Number_2__c) + 1;		
		tempCheckMap = new Map<decimal,sObject>();
		if (bankAcc.Use_Pre_Printed_Check_Stock__c && bankAcc.Number_of_Advice_Lines_Per_Page__c < childRecCount ){
			//create cancelled SPs
			decimal skipChecks = childRecCount/bankAcc.Number_of_Advice_Lines_Per_Page__c;
			system.debug(LoggingLevel.Error,'skipChecks=' + skipChecks +'=' + skipChecks.setScale(0,System.Roundingmode.UP) );
			for (integer i = 0 ; i< skipChecks.setScale(0,System.Roundingmode.UP)-1 ; i++){
				tempCheckMap.put(checkNumber,null);
				checkNumber++;
			}
			skippedCheckRecordMap.put(recordId,tempCheckMap);			
			system.debug(LoggingLevel.Error,'skippedCheckRecordMap=='+skippedCheckRecordMap);
		}		
		return skippedCheckRecordMap;
  	} 
  	
  	/*************************
    Description : Method used to create clone of main object with skipped check details and will be updated into check,sobject map
    Params : @originalSObject - send original object to be cloned into sobject type
    @updateClonedObject : Map<decimal,sObject>  send skipped checks map
    Return params :
    Map<decimal,sObject>  :map with check number and cloned object  and returned 
    @ objectType = object type
    */
  	public static Map<decimal,sObject> updateClonedObject (sObject originalSObject,Map<decimal,sObject> skippedCheckNumberObjMap){
  		//sObject originalSObject = (sObject) payment;
		Map<decimal,sObject> skippedCheckNumberObj = new Map<decimal,sObject>();
		List<sObject> originalSObjects;
		system.debug(LoggingLevel.Error,'inside updateClonedObject intrim method=' +skippedCheckNumberObjMap);
		originalSObjects = new List<sObject>{originalSObject};
		system.debug(LoggingLevel.Error,'originalSObjects=='+originalSObjects);
		List<sObject> clonedSObjects;
		
		for (decimal checkNumber :skippedCheckNumberObjMap.keyset()){
			clonedSObjects = CheckService.cloneObjects(originalSobjects, originalSObject.getsObjectType());
			system.debug(LoggingLevel.Error,'clonedSObjects=='+clonedSObjects);
			if (originalSObject.getsObjectType().getDescribe().getLabel()  =='Supplier Payment' ){   
				Supplier_Payment__c clonedSP;                                        
				clonedSP = (Supplier_Payment__c)clonedSObjects.get(0);						
				//KNDY-17923 - deperecated 'Check_Number__c' 				
				//clonedSP.check_number__c = checkNumber;
				clonedSP.Reference__c = String.valueOf(checkNumber);	
				//KNDY-17923 - deperecated 'payment_number__c' 	
				//clonedSP.payment_number__c = checkNumber;
				clonedSP.Status__C = PaymentService.STATUS_CANCELLED;
				clonedSP.Status_Reason__c = PaymentService.STATUS_REASON_VOID_FROM_OVERFLOW_ADVICE;
				clonedSP.Finalized__c = false;
				clonedSP.Payment_Amount__c = 0;
				//change source key (append bank account and check number to make source key unique and it will help user to figure out for which bank it was cancelled in future)
				clonedSP.Source_Key__c = String.valueOf(originalSObject.get('Source_Key__c')) + String.valueOf(originalSObject.get('Bank_Account__c')) + String.valueOf(checkNumber);
				system.debug('inside cloneObject = '+skippedCheckNumberObjMap.get(checkNumber));
				skippedCheckNumberObjMap.put(checkNumber,(sObject) clonedSP);
			}
			if (originalSObject.getsObjectType().getDescribe().getLabel()  =='Customer Receipt' ){   
				Customer_Receipt__c clonedCR;                                        
				clonedCR = (Customer_Receipt__c)clonedSObjects.get(0);						
				clonedCR.Reference_Number__c = String.valueOf(checkNumber);				
				clonedCR.Status__C = PaymentService.STATUS_CANCELLED;
				clonedCR.Status_Reason__c = PaymentService.STATUS_REASON_VOID_FROM_OVERFLOW_ADVICE;
				clonedCR.Finalized__c = false;
				clonedCR.Amount_To_Apply__c = 0;
				clonedCR.Amount_Received__c = 0;
				clonedCR.Amount_Unapplied__c = 0;			
				clonedCR.Claim__c = null;	
				skippedCheckNumberObjMap.put(checkNumber,(sObject) clonedCR);
				system.debug('inside cloneObject = '+skippedCheckNumberObjMap.get(checkNumber));
			}
		}
		
		return skippedCheckNumberObjMap;
  	}
  	/*************************
    Description : Method used to update latest check/ach/wire number into bank object back
    Params : @bankAccount - send original object to be cloned into sobject type
    @nextNumberFromBank  : decimal - next sequence number check once payment/refunds receipts are created
    @paymentMethod: string - payment method used for creating payment/refunds receipt
    Return params : none
    */
  	public static void updateBankAccount(Bank_Account__c bankAccount,decimal nextNumberFromBank, string paymentMethod){
  		//KNDY-18900 Replace next check number (number) field with text field
  		if (paymentMethod == PaymentService.PAYMENT_METHOD_CHECK) bankAccount.Next_Check_Number_2__c = string.ValueOf(nextNumberFromBank);	
		DML.updateAsUser( bankAccount );
  	}
  	
  	
}