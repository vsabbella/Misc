public with sharing class BankTransactionGroupService {
    public static ExceptionService exService = new ExceptionService();
    public static void setExceptions(list<Bank_Transaction_Group__c> lstbankTransactionGroup) {
       if(!lstbankTransactionGroup.isEmpty()){       	
   	       for(Bank_Transaction_Group__c bankTransactionGroup : lstbankTransactionGroup){	            
	            if (true){
	            //	ExceptionService.setExceptions(bankTransactionGroup, '');
	            }else{
	              //  ExceptionService.clearException(bankTransactionGroup, '');
	            }
	            
	        }
        }
    }
    
    public static void uncheckFinalizedFlagOnBT(){
    	if(Trigger.isAfter){
            if(Trigger.isUpdate){
            	set<Id> setBTGId = new set<Id>();
            	for(Bank_Transaction_Group__c btg: (list<Bank_Transaction_Group__c>) trigger.new){
            		if(KSE.isFieldChanging('Finalized__c',btg,(map<Id,Bank_Transaction_Group__c>) trigger.oldMap) && !btg.Finalized__c){
    					setBTGId.add(btg.Id); 
            		}
    			}
                uncheckFinalizedFlagOnBT(setBTGId);
            }      
        }
    }
    public static void uncheckFinalizedFlagOnBT(set<Id> setBTGId){
    	list<Bank_Transaction__c> lstBT = new list<Bank_Transaction__c>();
    	if(!setBTGId.isEmpty()){
    		lstBT = [Select Finalized_2__c, Finalized_Hidden__c from Bank_Transaction__c where Bank_Transaction_Group__c in: setBTGId];
    		if(!lstBT.isEmpty()){
    			for(Bank_Transaction__c bt: lstBT){
    				bt.Finalized_2__c = false;
                    bt.Finalized_Hidden__c = false;

    			}
    			try{
    				DML.updateAsUser(lstBT);
    			}catch(DMLexception ex){
    				for(Bank_Transaction_Group__c btg: (list<Bank_Transaction_Group__c>) trigger.new){
    					btg.addError(ex.getMessage());
    				}
    			}
    		}
   		}
    }
}