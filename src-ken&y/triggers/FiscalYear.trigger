trigger FiscalYear on Fiscal_Year__c (before delete,before update) {
	
	if(DML.checkTriggerDispatch(Fiscal_Year__c.getSobjectType())){return;}
	
  List<Period__c> zeroPeriods = new List<Period__c>();
  Set <Id> fyIds = new Set<Id>();
  //Set <Id> cIds = new Set<Id>();
  
  Map<Id,Period__c> mFiscalYearIDZeroPeriod = new Map<Id,Period__c>();
    
  if(trigger.isBefore && trigger.isDelete){
  
	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	
	SOQLUtil soql = new SOQLUtil('Fiscal_Year__c', true); //enforceFLS=true, running in user mode
	soql.addFields(new set<string>{
		'Id'
	});
	soql.setWhereClause('Id IN :trigger.old');
	SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Periods__r');
	childRel.addFields(new set<string>{
		'Id','Type__c','Closed__c'
	});
	soql.addChildRelationship(childRel);
	
	Map<Id, Fiscal_Year__c> mOldFYs = new Map<Id, Fiscal_Year__c>((List<Fiscal_Year__c>)Database.query(soql.getQuery()));

    for(Fiscal_Year__c fy : trigger.old){
        if(mOldFYs.containsKey(fy.Id)){
            if(mOldFYs.get(fy.Id).Periods__r != null 
                  && mOldFYs.get(fy.Id).Periods__r.size() > 0){
                fy.addError(Label.Unable_to_delete_Fiscal_Year );
            }
        }
    }
    
    
  }
 
      
	if(trigger.isBefore && trigger.isUpdate){
		for(Fiscal_Year__c fy : trigger.new){
            fyIds.add(fy.ID);
		}
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Type__c','Open__c','Closed__c','Permanently_Closed__c','Period_Start__c','FiscalYear__c'
		});
		soql.setWhereClause('FiscalYear__c IN :fyIds');
		
		Map<Id,Period__c> mPeriod = new Map<Id,Period__c>((List<Period__c>)Database.query(soql.getQuery()));

		for(Period__c p : mPeriod.values()){
		    if(p.Type__c =='Zero'){
				if(!(mFiscalYearIDZeroPeriod.containsKey(p.FiscalYear__c))){
					mFiscalYearIDZeroPeriod.put(p.FiscalYear__c,p);
				}
		    }
		}  
      
		for(Fiscal_Year__c fy : trigger.new){
			Period__c p = mFiscalYearIDZeroPeriod.get(fy.ID);
	        if(p!= null){
				if(KSE.isFieldChanging('GL_Account__c', fy, trigger.oldMap)){
		            if(p.Type__c == 'Zero' && p.Closed__c==true){
		              fy.addError('Retained Earnings account cannot be changed when the Zero Period is closed' );
		            }
	          	}
	        }
	    }
	}
}