public with sharing class GLAccountService {
	public void validateGLAccountNumberwithGLTypeRange(List<GL_Account__c> GLAccountList){
		
		List<String> accountRangeList, parentChildList;
		for(GL_Account__c thisGL: GLAccountList){
			accountRangeList = new List<String>();
			parentChildList = new List<String>();
			if(thisGL.GL_Type__c != null){
				if(thisGL.account_range_from__c != null & thisGL.account_range_to__c != null){
					//As per KNDY-12496 - The below validation is no longer a valid business use case scenario.So commenting the same.
					/*// Check if the parent's GL Number is before the current / first element in the list					
					if(thisGL.subaccount_of__c != null){
						parentChildList.add(thisGL.Parent_GL_Account_Number__c);
						parentChildList.add(thisGL.GL_Account_Number__c);
						parentChildList.sort();
						if(parentChildList[0] != thisGL.Parent_GL_Account_Number__c){
							thisGL.addError(label.Child_GL_Account_Number_cannot_be_greater_than_Parent_GL_Account_Number);
						}
					}*/
					accountRangeList.add(thisGL.GL_Account_Number__c);
					accountRangeList.add(thisGL.account_range_from__c);
					accountRangeList.add(thisGL.account_range_to__c);
					accountRangeList.sort();
					Integer lastElementIndex = accountRangeList.size()-1;
					if(!(accountRangeList[0] == thisGL.account_range_from__c && accountRangeList[lastElementIndex] == thisGL.account_range_to__c)){
						thisGL.addError('This GL Account Number: '+thisGL.GL_Account_Number__c+' does not fit in the account range of associated GL Type: '+thisGL.Name+'  between '+thisGL.account_range_from__c + ' and '+ thisGL.account_range_to__c);
					}
				}
			
			}
			
		}
	
	}
    public void validateGLAccountTypeONGL(List<GL_Account__c> GLAccountList){
        map<id, GL_Account__c> idsInContext = new map<id, GL_Account__c>();
        for(GL_Account__c glaInContext: GLAccountList){
            if(KSE.isFieldChanging('Gl_Type__c', glaInContext , trigger.oldMap)){
                idsInContext.put(glaInContext.id,glaInContext);
            }
        }
        if(idsInContext.size() > 0){
			/*
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			*/
			SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','GL_Account__c'
			});
			soql.setWhereClause('GL_Account__r.Id IN : GLAccountList AND Status__c = \'Active\'');
			soql.setLimit(1);
			List<Accounting_Entry_Line__c> ael = Database.query(soql.getQuery());

            for(GL_Account__c thisGL : GLAccountList){    
                if( (thisGL.Active__C == TRUE  && ael.size() > 0 ) && (KSE.isFieldChanging('Gl_Type__c', thisGL , trigger.oldMap)) && Trigger.NewMap.KeySet().contains(thisGL.id) ){        
                    thisGL.AddError(System.label.GLAccount_Change_Type_Restriction_With_Transactions);
                }
            }
        }

    }
    /*
    //Method to prevent deletion of GL Account with transactions 
    public void validateGLAccountDeletion(List<GL_Account__c> GLAccountList){
        map<id, GL_Account__c> idsInContext = new map<id, GL_Account__c>();
        for(GL_Account__c glaInContext: GLAccountList){
            if((glaInContext.Active__C == TRUE && Trigger.OldMap.KeySet().contains(glaInContext.id) )){
                idsInContext.put(glaInContext.id,glaInContext);
            }
        }    
            if(idsInContext.size() > 0){        
		        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c');
		        soql.addFields(new set<string>{'Id','GL_Account__c'});
		        soql.setWhereClause('GL_Account__r.Id IN : GLAccountList AND Status__c = \'Active\'');
		        soql.setLimit(1);
              	List<Accounting_Entry_Line__c> ael = Database.query(soql.getQuery());
                
                for(GL_Account__c thisGL : GLAccountList){
                    if((thisGL.Active__C == TRUE  && ael.size() > 0 &&  Trigger.OldMap.KeySet().contains(thisGL.id) )){
                     thisGL.AddError(System.Label.GLAccount_Delete_Restriction_With_Transactions);
                    }
                }
            }

    }*/

    public void CheckExistingRFXGLAccount(List<GL_Account__c> GLAccountList){
    	if(trigger.isInsert){
	        SOQLUtil soql = new SOQLUtil('GL_Account__c');
	        soql.addFields(new set<string>{'Id','gl_type__c'});
	        soql.setWhereClause('FX_Type__c = \'RFX\''); 
			soql.setLimit(1);
  	    	list<GL_Account__c> rfxGLs = Database.query(soql.getQuery());
		    if(rfxGLs.size() > 0 && rFxGLs != null){
		    	for(GL_Account__c GLA:GLAccountList){
		    		GLA.addError(System.Label.Check_EXISTING_RFX_Account);
		    	}
		    }
    	}    	
    	if(trigger.isupdate){
	        SOQLUtil soql = new SOQLUtil('GL_Account__c');
	        soql.addFields(new set<string>{'Id','gl_type__c'});
	        soql.setWhereClause('FX_Type__c = \'RFX\''
	                             +' AND id NOT IN:GLAccountList'); 
			soql.setLimit(1);
  	    	list<GL_Account__c> rfxGLs = Database.query(soql.getQuery());
		    if(rfxGLs.size() > 0 && rFxGLs != null){
		    	for(GL_Account__c GLA:GLAccountList){
		    		GLA.addError(System.Label.Check_EXISTING_RFX_Account);
		    	}
		    }else if(rfxGLs.size() ==  0 || rFxGLs == null){
		    	for(integer i=1; i< GLAccountList.size(); i++){
		    		GLAccountList[i].addError(System.Label.Check_EXISTING_RFX_Account);
		    	
		    	}
		    }
    	}    	
    }
    public void CheckExistingUFXGLAccount(List<GL_Account__c> GLAccountList){
    	if(trigger.isInsert){
	        SOQLUtil soql = new SOQLUtil('GL_Account__c');
	        soql.addFields(new set<string>{'Id','gl_type__c'});
	        soql.setWhereClause('FX_Type__c = \'UFX\''); 
			soql.setLimit(1);
  	    	list<GL_Account__c> ufxGLs = Database.query(soql.getQuery());
		    if(ufxGLs.size() > 0 && uFxGLs != null){
		    	for(GL_Account__c GLA:GLAccountList){
		    		GLA.addError(System.Label.Check_EXISTING_UFX_Account);
		    	}
		    }
    	}    	
    	if(trigger.isupdate){
	        SOQLUtil soql = new SOQLUtil('GL_Account__c');
	        soql.addFields(new set<string>{'Id','gl_type__c'});
	        soql.setWhereClause('FX_Type__c = \'UFX\''
	                             +' AND id NOT IN:GLAccountList'); 
			soql.setLimit(1);
  	    	list<GL_Account__c> ufxGLs = Database.query(soql.getQuery());
		    if(ufxGLs.size() > 0 && ufxGLs != null){
		    	for(GL_Account__c GLA:GLAccountList){
		    		GLA.addError(System.Label.Check_EXISTING_UFX_Account);
		    	}
		    }else if(ufxGLs.size() ==  0 || ufxGLs == null){
		    	for(integer i=1; i< GLAccountList.size(); i++){
		    		GLAccountList[i].addError(System.Label.Check_EXISTING_UFX_Account);
		    	
		    	}
		    }
    	}    	
    }
    //Method to prevent deletion of GL Account with transactions --KNDY-15219
     public   void GLAccountDeleteValidation(List<GL_Account__c> GLAccountList){
		if(trigger.isBefore && trigger.isDelete){
			map<Id,Integer> mAEGLAccnt = new map<Id, Integer>();
			map<Id,Integer> mJEGLAccnt = new map<Id, Integer>();
			 
			
			SOQLUtil glAccntQuery = new SOQLUtil('GL_Account__c');
			glAccntQuery.addFields(new set<String>{'Id','Name'});
			glAccntQuery.setWhereClause('id IN :GLAccountList');
			 
			SOQLUtil.ChildRelationship aeLinesQuery = new SOQLUtil.ChildRelationship(glAccntQuery, 
			                                                    'Accounting_Entry_Lines__r');
            aeLinesQuery.addFields(new set<String>{'Id'});
            glAccntQuery.addChildRelationship(aeLinesQuery);
            aeLinesQuery.setLimit(1);
			SOQLUtil.ChildRelationship jeLinesQuery = new SOQLUtil.ChildRelationship(glAccntQuery, 
			                                                     'Journal_Entry_Lines__r');
			jeLinesQuery.addFields(new set<String>{'Id'});
			glAccntQuery.addChildRelationship(jeLinesQuery);
			jeLinesQuery.setLimit(1);
			 
			List<GL_Account__c> glaccntList = Database.query(glAccntQuery.getQuery());
		   
			
			for(GL_Account__c currGlAcc: glaccntList){
				mAEGLAccnt.put(currGlAcc.id, currGlAcc.Accounting_Entry_Lines__r.size());
				mJEGLAccnt.put(currGlAcc.id, currGlAcc.Journal_Entry_Lines__r.size());
			}
			
			for(GL_Account__c thisGL : (List<GL_Account__c>)GLAccountList){
				if(mAEGLAccnt.get(thisGL.id) > 0 || mJEGLAccnt.get(thisGL.id) > 0) 
                {
                    thisGL.AddError(Label.GLAccount_Delete_Restriction_With_Transactions);
                }else if (thisGL.Active__C == true){
                    thisGL.AddError(' You cannot delete an active GL account. ');
                } 
			} 
		}
	}
	
     //---------KNDY-15497 Method to prevent GL Account Inactive 
     //------if the Period in which it is used is still "OPEN"---
	 public Set<Id>  GLAccountUpdateValidation(List<GL_Account__c> changingGls){ 
    	 
	    List<GL_Account__c> glAccountLst = new List<GL_Account__c>();
	    Set<Id> resultIds                = new Set<Id>();
	    
	    if(	trigger.isBefore && trigger.isUpdate ){   
    	   
    	    if(changingGls.size()>0){
    	        
        	    SOQLUtil glAccountLstQuery = new SOQLUtil('GL_Account__c');
    			glAccountLstQuery.addFields(new set<String>{'Id','Name'});
    			glAccountLstQuery.setWhereClause('id IN :changingGls');
    			
    			SOQLUtil.ChildRelationship aeLinesQuery = new SOQLUtil.ChildRelationship(glAccountLstQuery, 
			                                                    'Accounting_Entry_Lines__r');
    	        
    	        aeLinesQuery.addFields(new set<String>{'Id','Accounting_Entry__r.Period__r.Open__c'});
    	        aeLinesQuery.setWhereClause('Status__c =\'Active\' and Has_Exceptions__c = false  and Accounting_Entry__r.Period__r.Open__c = true ');
    	        aeLinesQuery.setLimit(1);
                
                glAccountLstQuery.addChildRelationship(aeLinesQuery);
                
                
                SOQLUtil.ChildRelationship jeLinesQuery = new SOQLUtil.ChildRelationship(glAccountLstQuery, 
			                                                    'Journal_Entry_Lines__r');
    	        
    	        jeLinesQuery.addFields(new set<String>{'Id','Journal_Entry__r.Period__r.Open__c'});
    	        jeLinesQuery.setWhereClause('Journal_Entry__r.Period__r.Open__c = true');
    	        jeLinesQuery.setLimit(1);
    	        
                glAccountLstQuery.addChildRelationship(jeLinesQuery); 
                 
                glAccountLst = Database.query(glAccountLstQuery.getQuery()); 
                
                system.debug('query'+ glAccountLstQuery.getQuery());
                
                if(glAccountLst.size()>0){
                    	for(GL_Account__c glAccnt: glAccountLst){
                 	     Set<Accounting_Entry_Line__c> aelst = new Set<Accounting_Entry_Line__c>(glAccnt.Accounting_Entry_Lines__r);
                 	     Set<Journal_Entry_Line__c> jelst    = new Set<Journal_Entry_Line__c>(glAccnt.Journal_Entry_Lines__r);
                 	      
                 	      system.debug('aelst' +aelst);
                 	      system.debug('jelst' +jelst);  
                 	      
                 	      if(aelst.size()>0 || jelst.size()>0){
                 	          resultIds.add(glAccnt.id); 
                 	      }
             	       }  
                }
                 
    	    }
    	    
	    } 
       return  resultIds;
	 } 
	
}