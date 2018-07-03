trigger GLAccount on GL_Account__c (after insert, after update, before insert, before update, before delete) {
    
    if(DML.checkTriggerDispatch(GL_Account__c.getSobjectType())){return;}
    
    GLAccountService GLAService = new GLAccountService();
    
   
    if(Trigger.isAfter){
    	if(Trigger.isUpdate){
        GLAService.validateGLAccountTypeONGL(Trigger.new); 
        }       
        if(Trigger.isInsert || Trigger.isUpdate){
            GLAService.validateGLAccountNumberwithGLTypeRange(trigger.new);
        }
    }
    if( Trigger.isBefore && Trigger.isDelete){
        //GLAService.validateGLAccountDeletion(trigger.old);
        GLAService.GLAccountDeleteValidation(trigger.old);
    }    
	if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate ) ) {
	    List<GL_Account__c>   changingGls            = new List<GL_Account__c>();
	    
		List<GL_Account__c> GLAccountListWithRFX = new List<GL_Account__c> ();
		List<GL_Account__c> GLAccountListWithUFX = new List<GL_Account__c> ();
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
													'GL_Type__c' ,	
													'GL_Type__c', 
													'GL_Type_Code__c',
													'Primary_Key__c'		);	
		if(Trigger.isUpdate){
			For(GL_Account__c thisGL :trigger.new){
				GL_Account__c oldGL = trigger.oldmap.get(thisGL.id);
				if(oldGL.FX_Type__c != 'RFX' && thisGL.FX_Type__c == 'RFX'){
					GLAccountListWithRFX.add(thisGL);
				}
				
				if(oldGL.FX_Type__c != 'UFX' && thisGL.FX_Type__c == 'UFX'){
					GLAccountListWithUFX.add(thisGL);
				}
				//------KNDY-15497--------GL Account Active to Inactive-------//
				if(KSE.isFieldChanging('active__c',thisGL,trigger.oldMap)&& thisGL.active__c==false) {
    	            changingGls.add(thisGL);
    	       } 
			} 
			Set<Id> glsWithTxnsinOpenPeriod =  GLAService.GLAccountUpdateValidation(changingGls);   
			For(GL_Account__c thisGL :trigger.new){
				  
				   if(glsWithTxnsinOpenPeriod.size()>0 && glsWithTxnsinOpenPeriod.contains(thisGL.id)==true){ 
				          thisGL.active__C.addError(Label.Cannot_make_GL_Account_Inactive_for_an_open_period);
				   }
				   
			}
			 
		}
		if(Trigger.isInsert){
			For(GL_Account__c thisGL :trigger.new){
				if(thisGL.FX_Type__c == 'RFX'){
					GLAccountListWithRFX.add(thisGL);
				}
				if(thisGL.FX_Type__c == 'UFX'){
					GLAccountListWithUFX.add(thisGL);
				}
			}
		}
		if(GLAccountListWithRFX != null && GLAccountListWithRFX.size()>0){
			GLAService.CheckExistingRFXGLAccount(GLAccountListWithRFX);
		}
		if(GLAccountListWithUFX != null && GLAccountListWithUFX.size()>0){
			GLAService.CheckExistingUFXGLAccount(GLAccountListWithUFX);
		}
	}
}