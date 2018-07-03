public with sharing class BankTransactionService {
	public static ExceptionService exService = new ExceptionService();

    
    public static void deleteBTM(){
    	if(trigger.isAfter){
    		if(trigger.isUpdate){
    			deleteBTM((list<Bank_Transaction__c>) trigger.new);	
    		}
    	}
    	if(trigger.isBefore){
    		if(trigger.isUpdate){
    			updateBT((list<Bank_Transaction__c>) trigger.new);	
    		}
    	}
    	
    }
    public static void updateBT(list<Bank_Transaction__c> lstBT){
    	if(!lstBT.isEmpty()){
	    	for(Bank_Transaction__c bt: lstBT){
		    	if( KSE.isFieldChanging('Finalized_2__c' , bt,(map<Id,Bank_Transaction__c>) Trigger.oldMap) 
		    	    && !bt.Finalized_2__c) {
		            bt.Match_Approved__c = false;   
		            bt.Reconciled_As_Of_Date__c = null;
		            bt.Reconciled_Hidden__c = false;    
	    		}
	    	}
    	}
    }
    public static void deleteBTM(list<Bank_Transaction__c> lstBT){
    	if(!lstBT.isEmpty()){
    		set<Id> setUnfinalizedBTId = new set<Id>();
	    	for(Bank_Transaction__c bt: lstBT){
		    	if( KSE.isFieldChanging('Finalized_2__c' , bt,(map<Id,Bank_Transaction__c>) Trigger.oldMap) 
		    	    && !bt.Finalized_2__c) {
		            setUnfinalizedBTId.add(bt.Id);        
	    		}
	    	}
	    	if(!setUnfinalizedBTId.isEmpty()){
	    		list<Bank_Transaction_Match__c> lstBTM = new list<Bank_Transaction_Match__c>();
	    		lstBTM = [Select Id,Name,Bank_Transaction__c from Bank_Transaction_Match__c where Bank_Transaction__c in :setUnfinalizedBTId];
	    		if(!lstBTM.isEmpty()){
	    			DML.deleteAsUser(lstBTM);
	    		}
	    	}
    	}
    }
    
    public static void restrictDeletionOfFinalizedTransaction(){
        if(Trigger.isBefore){
            if(Trigger.isdelete){
                restrictDeletionOfFinalizedTransaction((list<Bank_Transaction__c>) Trigger.old);
            }      
        }
    }
	
	public static void restrictDeletionOfFinalizedTransaction(list<Bank_Transaction__c> lstBankTransaction){
        if(!lstBankTransaction.isEmpty()){
        	map<Id,Bank_Transaction_Group__c> mapBTGToBeDeleted = new map<Id,Bank_Transaction_Group__c>();
			for(Bank_Transaction__c bankTransaction: lstBankTransaction){
				if(bankTransaction.Finalized__c){
					bankTransaction.addError(Label.BT_cannot_be_deleted);
				}else{
					mapBTGToBeDeleted.put(bankTransaction.Bank_Transaction_Group__c,
					                      new Bank_Transaction_Group__c(Id=bankTransaction.Bank_Transaction_Group__c));
				}
			}
			if(!mapBTGToBeDeleted.isEmpty()){
				DML.deleteAsUser(mapBTGToBeDeleted.values()); 
			}
        }
    }
    
    //should be called from main page when approved match button is clicked.
    public static list<Bank_Transaction__c> approvedMatchedBankTransaction(list<Bank_Transaction__c> lstBankTransaction){
        if(!lstBankTransaction.isEmpty()){
			for(Bank_Transaction__c bankTransaction: lstBankTransaction){
				bankTransaction.Match_Approved__c = true;
			}
			DML.updateAsUser(lstBankTransaction);
        }
        return lstBankTransaction;
    }
    
    public static void createGroupOnCreationOfBankTransaction(){
    	try {
			if (trigger.isAfter && trigger.isInsert) {
				createGroupOnCreationOfBankTransaction((list<Bank_Transaction__c>) trigger.new);
			}
		}catch(Exception ex) {
			string errorMessage = ex.getMessage();
			integer location;
			if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
				if(!msgArray.isEmpty()){
					errorMessage = msgArray.get(msgArray.size()-1);
					if(errorMessage.contains(': []: []')){
						location = errorMessage.lastIndexOf(': []: []');
						errorMessage = errorMessage.mid(0, location);
					}
					if(errorMessage.contains(': []')){
						location = errorMessage.lastIndexOf(': []');
						errorMessage = errorMessage.mid(0, location);
					}
				}
			}
			for(Bank_Transaction__c bt : (list<Bank_Transaction__c>) trigger.new) {
				bt.addError(errorMessage);
			}
		}
    }
    public static void createGroupOnCreationOfBankTransaction(list<Bank_Transaction__c> lstBankTransactions){

		map<Id,Bank_Transaction_Group__c> mapBankTransactionGroup = new map<Id,Bank_Transaction_Group__c>();
        list<Bank_Transaction__c> lstBankTransaction = new list<Bank_Transaction__c>();
        if(!lstBankTransactions.isEmpty()){
            for(Bank_Transaction__c bankTransaction: lstBankTransactions){
                Bank_Transaction_Group__c bankTransactionGroup = new Bank_Transaction_Group__c();
                bankTransactionGroup.Finalized__c = true;
                bankTransactionGroup.Currency__c = bankTransaction.Currency__c;
                bankTransactionGroup.Transaction_Date__c = bankTransaction.Transaction_Date__c;
                bankTransactionGroup.Transaction_Type__c = 'Standard';
                bankTransactionGroup.Company__c = bankTransaction.Company__c;
                bankTransactionGroup.Total_Number_Of_Lines__c = 1;
                //bankTransactionGroup.Finalized_Date__c = System.now();
                mapBankTransactionGroup.put(bankTransaction.Id,bankTransactionGroup);
            }

	        if(!mapBankTransactionGroup.isEmpty()){
	          	DML.insertAsUser(mapBankTransactionGroup.values());
	        }
            //update Bank Transaction with newly created bank transaction groups
	        lstBankTransaction = [Select Id,Bank_Transaction_Group__c from Bank_Transaction__c
                                                            where Id in :lstBankTransactions];
            if(!lstBankTransaction.isEmpty() && !mapBankTransactionGroup.isEmpty()){
                for(Bank_Transaction__c bankTransaction: lstBankTransaction){
                	if(mapBankTransactionGroup.containskey(bankTransaction.Id)){
                    	bankTransaction.Bank_Transaction_Group__c = mapBankTransactionGroup.get(bankTransaction.Id).Id;
                	}
                }

                //updating bank transaction with newly created bank transaction group
                DML.updateAsUser(lstBankTransaction);
            }
        }
    }
    
    public static sObject createBankTransactionMatching(Bank_Transaction__c bankTransaction,
                                                       string fieldToPopulate, dateTime matchedToTransactionDate,
                                                       dateTime bankTransactionDate,Id CRSPJEBTId, Decimal amountMatched){
        SchemaUtil util = new SchemaUtil();
        sObject record = util.getGlobalDescribe('Bank_Transaction_Match__c').newSObject() ;
        record.put('Bank_Transaction__c',bankTransaction.Id);
        record.put('Bank_Transaction_Date__c',bankTransactionDate);
        record.put('Matched_To_Transaction_Date__c',matchedToTransactionDate);
        record.put(fieldToPopulate,CRSPJEBTId);
        record.put('Amount__c',amountMatched);
        return record;                                                                             
    }
    
    public static list<sObject> save(list<BankTransactionMatchService.MatchingWrapper> 
    								 lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords,
                                     Bank_Transaction__c bankTransaction){
		list<sObject> lstSobject = new list<sObject>();
        if(!lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords.isEmpty()){
            for(BankTransactionMatchService.MatchingWrapper matchedRecord: 
                                            (list<BankTransactionMatchService.MatchingWrapper>) lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords){
                
                sObject record; 
                if(string.isNotBlank(matchedRecord.objectType) &&
                   matchedRecord.objectType.equalsIgnoreCase('Customer_Receipt__c')){
                	record = createBankTransactionMatching(bankTransaction,
                                                           'Customer_Receipt__c',
                                                            matchedRecord.transactionDate,
                                                            bankTransaction.Transaction_Date__c,
                                                            matchedRecord.recordId,
                                                            matchedRecord.amountMatched); 

                }else if(string.isNotBlank(matchedRecord.objectType) &&
                   		matchedRecord.objectType.equalsIgnoreCase('Supplier_Payment__c')){
                    record = createBankTransactionMatching(bankTransaction,
                                                           'Supplier_Payment__c',
                                                            matchedRecord.transactionDate,
                                                            bankTransaction.Transaction_Date__c,
                                                            matchedRecord.recordId,
                                                            matchedRecord.amountMatched); 
 
                }else if(string.isNotBlank(matchedRecord.objectType) &&
                   		matchedRecord.objectType.equalsIgnoreCase('Journal_Entry_Line__c')){
                    record = createBankTransactionMatching(bankTransaction,
                                                           'Journal_Entry_Line__c',
                                                            matchedRecord.transactionDate,
                                                            bankTransaction.Transaction_Date__c,
                                                            matchedRecord.recordId,
                                                            matchedRecord.amountMatched);         
                  
                }else if(string.isNotBlank(matchedRecord.objectType) &&
                   		matchedRecord.objectType.equalsIgnoreCase('Payment__c')){
                    record = createBankTransactionMatching(bankTransaction,
                                                           'Payment__c',
                                                            matchedRecord.transactionDate,
                                                            bankTransaction.Transaction_Date__c,
                                                            matchedRecord.recordId,
                                                            matchedRecord.amountMatched);         
                  
                }
                lstSobject.add(record);
            }
            if(!lstSobject.isEmpty()){
            	Database.insert(lstSobject);
            }  
        } 
   		return lstSobject;
    }
    
    public static void validateAmountOnBankTransactionBeforeApproved(){
        if(trigger.isBefore){
            if(trigger.isUpdate){
                set<Bank_Transaction__c> setApprovedBankTransaction = new set<Bank_Transaction__c>();
                for(Bank_Transaction__c bankTransaction: (list<Bank_Transaction__c>)trigger.new){
                    if(bankTransaction.Match_Approved__c &&
                       KSE.isFieldChanging('Match_Approved__c', bankTransaction, trigger.oldMap)){
                        setApprovedBankTransaction.add(bankTransaction);
                    }
                }
                if(!setApprovedBankTransaction.isEmpty()){
                    validateAmountOnBankTransactionBeforeApproved(setApprovedBankTransaction);
                }
            }
        }
    }
    public static void validateAmountOnBankTransactionBeforeApproved(set<Bank_Transaction__c> setApprovedBankTransaction){
        if(!setApprovedBankTransaction.isEmpty()){
        	map<Id,decimal> mapBankTransactionAndMatchingSummedAmount = new map<Id,decimal>();
        	list<Bank_Transaction_Match__c> lstBankTransactionMatch = new list<Bank_Transaction_Match__c> ();
            lstBankTransactionMatch = [Select Id, Amount__c,Bank_Transaction__c,
                                       Bank_Transaction__r.Amount__c
                                       from Bank_Transaction_Match__c where Bank_Transaction__c in: setApprovedBankTransaction];
            if(!lstBankTransactionMatch.isEmpty()){
            	for(Bank_Transaction_Match__c bankTransactionMatch: lstBankTransactionMatch){
                	if(bankTransactionMatch.Bank_Transaction__c != null){
                    	if(mapBankTransactionAndMatchingSummedAmount.containskey(bankTransactionMatch.Bank_Transaction__c)){
                        	if(bankTransactionMatch.Amount__c == null){
                            	bankTransactionMatch.Amount__c = 0.0;
                            }
                            decimal tempVariable = mapBankTransactionAndMatchingSummedAmount.get(bankTransactionMatch.Bank_Transaction__c)
                                                   + bankTransactionMatch.Amount__c;
                            mapBankTransactionAndMatchingSummedAmount.put(bankTransactionMatch.Bank_Transaction__c,
                            tempVariable);                            
                        }else{
                        	if(bankTransactionMatch.Amount__c == null){
                            	bankTransactionMatch.Amount__c = 0.0;
                            }
                            mapBankTransactionAndMatchingSummedAmount.put(bankTransactionMatch.Bank_Transaction__c,
                            bankTransactionMatch.Amount__c);
                        }
                    }
                }
                if(!mapBankTransactionAndMatchingSummedAmount.isEmpty()){
                	for(Bank_Transaction__c bankTransaction: setApprovedBankTransaction){
                		if(mapBankTransactionAndMatchingSummedAmount.containsKey(bankTransaction.Id)){
                			if(bankTransaction.Amount__c == null ||
                			   (bankTransaction.Amount__c != null && 
                			    bankTransaction.Amount__c != mapBankTransactionAndMatchingSummedAmount.get(bankTransaction.Id))){
                			    bankTransaction.addError(Label.BT_cannot_be_approved);	
                			}
                		}else{
                			bankTransaction.addError(Label.BT_does_not_have_BTM);
                		}
                	}
                }
            }
        }
    }
    public static void populateFinalizedFlag(){
    	if(Trigger.isBefore){
           if(Trigger.isInsert){
                populateFinalizedFlag((list<Bank_Transaction__c>) trigger.new);
            }  
            if(Trigger.isUpdate){//Handle re-finalize.
                for(Bank_Transaction__c bt:(list<Bank_Transaction__c>) trigger.new){
                    if( KSE.isFieldChanging('Finalized_2__c' , bt, Trigger.oldMap) && bt.Finalized_2__c==true)//False to true user action.User trying re-finalize.
                        bt.finalized_Hidden__c= true;
                    if(KSE.isFieldChanging('Amount__c' , bt, Trigger.oldMap)){//False to true user action.User trying re-finalize.                   	
                        if(bt.Amount__c >= 0){
		    				bt.SubTransaction_Type__c = 'Debit';
		    			}else{
		    				bt.SubTransaction_Type__c = 'Credit';
		    			}
                    }
                }
            }   
        } 
    }
    public static void populateFinalizedFlag(list<Bank_Transaction__c> lstBT){
    	if(!lstBT.isEmpty()){
    		set<Id> setBankAccountId = new set<Id>();
    		for(Bank_Transaction__c bt: lstBT){
    			bt.Finalized_2__c = true;
    			bt.Finalized_Hidden__c = true;
    			if(bt.Amount__c >= 0){
    				bt.SubTransaction_Type__c = 'Debit';
    			}else{
    				bt.SubTransaction_Type__c = 'Credit';
    			}
    			if(bt.Bank_Account__c != null){
    				setBankAccountId.add(bt.Bank_Account__c);
    			}
    		}
    		if(!setBankAccountId.isEmpty()){
    			populateTransactionCurrency(lstBT,setBankAccountId);
    		}
    	}
    }
    public static void populateTransactionCurrency(list<Bank_Transaction__c> lstBT,set<Id> setBankAccountId){
  		map<Id,Bank_Account__c> mapBankAccount = new map<Id,Bank_Account__c>([Select Id,Currency__c,Company__c from Bank_Account__c
  																			  where Id in: setBankAccountId]);
  		if(!mapBankAccount.isEmpty()){
  			for(Bank_Transaction__c bt: lstBT){
    			if(mapBankAccount.containsKey(bt.Bank_Account__c)){
    				bt.Currency__c = mapBankAccount.get(bt.Bank_Account__c).Currency__c;
    				if(bt.Company__c == null && mapBankAccount.get(bt.Bank_Account__c).Company__c != null){
    					bt.Company__c = mapBankAccount.get(bt.Bank_Account__c).Company__c;
    				}
    			}
    		}
  		}
    }
    
    public static void setValidateFinalizedFlagonBT(){
        for(sObject sObj: Trigger.new){
            if((boolean) sObj.get('Finalized__c') == true){
                sObj.put('Finalized_hidden__c',true);
            }
        }
        if(Trigger.isUpdate){
            for(sObject sObj: Trigger.new){
                Bank_Transaction__c bt = (Bank_Transaction__c)sObj;
                    if( KSE.isFieldChanging('Finalized_2__c' , bt, Trigger.oldMap) && bt.Finalized_2__c == false && bt.Finalized_Hidden__c != false) {
                        bt.addError(Label.Click_Unfinalize);
                    
                }
            }
        }
    }
 /*   public static void populateFinalizeDate(){ 
    	set<Id> setBTGId = new set<Id>();
    	for(Bank_Transaction__c bt: (list<Bank_Transaction__c> ) trigger.new){
    		if(bt.Bank_Transaction_Group__c != null){
    			setBTGId.add(bt.Bank_Transaction_Group__c);
    		}
    	}
    	if(!setBTGId.isEmpty()){
    		list<Bank_Transaction_Group__c> lstBTG = [Select Id,Company__c, Finalized__c, Finalized_Date__c,transaction_date__c,posting_date__c,Total_Number_Of_Lines__c  ,Currency__c  , Finalized_Hidden__c, 
    												  Void__c, Historical__c from Bank_Transaction_Group__c where Id in: setBTGId];
    		if(!lstBTG.isEmpty()){
    			FinalizeService.setFinalizedDate(lstBTG);
    		}
    	}
    }*/
    
     public static void syncBTChangesOnBTG(){
    	if(Trigger.isAfter){
            if(Trigger.isUpdate){
            	map<id,Bank_Transaction__c> mapBTGIdAndBT = new map<id,Bank_Transaction__c>();
            	for(Bank_Transaction__c bt: (list<Bank_Transaction__c>) trigger.new){
            		if(KSE.isFieldChanging('Currency__c',bt,(map<Id,Bank_Transaction__c>) trigger.oldMap)
            		   || KSE.isFieldChanging('Transaction_Date__c',bt,(map<Id,Bank_Transaction__c>) trigger.oldMap)
            		   || KSE.isFieldChanging('Company__c',bt,(map<Id,Bank_Transaction__c>) trigger.oldMap)
            	       || (KSE.isFieldChanging('Finalized_2__c',bt,(map<Id,Bank_Transaction__c>) trigger.oldMap) && bt.Finalized_2__c)){
            		   	if(bt.Bank_Transaction_Group__c != null){
    						mapBTGIdAndBT.put(bt.Bank_Transaction_Group__c,bt);
            		   	}
            		}
    			}
    			if(!mapBTGIdAndBT.isEmpty()){
               		syncBTChangesOnBTG(mapBTGIdAndBT);
    			}
            }      
        }
    }
    
    public static void syncBTChangesOnBTG(map<id,Bank_Transaction__c> mapBTGIdAndBT){
    	list<Bank_Transaction_Group__c> lstBTG = new list<Bank_Transaction_Group__c>();
    	if(!mapBTGIdAndBT.isEmpty()){
    		for(Bank_Transaction__c bt: mapBTGIdAndBT.values()){
    			lstBTG.add(new Bank_Transaction_Group__c(Id = bt.Bank_Transaction_Group__c, Currency__c = bt.Currency__c,
    													 Transaction_Date__c = bt.Transaction_Date__c, Company__c = bt.Company__c, 
    													 Finalized__c = bt.Finalized_2__c, Finalized_Hidden__c = bt.Finalized_2__c));
    		}
    		if(!lstBTG.isEmpty()){
	    		Database.SaveResult[] lstSaveResult = DML.updateAsUser(lstBTG,false);
	    		for(integer counter=0;counter<lstSaveResult.size();counter++){
	    			string message = '';
	    			if(lstSaveResult.get(counter).isSuccess()){
	    				
	    			}else{
	    				for(Database.Error err : lstSaveResult.get(counter).getErrors()) {
		    				message = message + ' '+  err.getMessage();
		    			}
		    			if(message.contains('Bank Transaction Group')){
		    				message = message.replaceAll('Bank Transaction Group','Bank Transaction');
		    			}
	    				mapBTGIdAndBT.get(lstBTG.get(counter).id).addError(message);
	    			}
	    		} 
    		}
   		}
    }
}