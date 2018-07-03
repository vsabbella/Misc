public with sharing class ActivateProposedCostsExt {

    ApexPages.StandardController con;
    //public ID CompanyID;
    public Boolean have_jobid {get; set;}
    public String selectedScopeRange {get;set;}
	public Item_Cost__c inputHolder {get;set;} {
		inputHolder = new Item_Cost__c();
	}
	public Item_Cost__c icRec;
	
    public ActivateProposedCostsExt(ApexPages.StandardController controller) {     
          
        con = controller;
        icRec = (Item_Cost__c)controller.getRecord();
        inputHolder.Item__c = icRec.Item__c;
        inputHolder.Facility__c = icRec.Facility__c;
        inputHolder.Company__c = icRec.Company__c;
        //CompanyID = icRec.Company__c;
        selectedScopeRange = 'SINGLE';
        have_jobid = false;
  
    }

    
    public pagereference activate() {
    		
    	if(selectedScopeRange == 'SINGLE' && inputHolder.Item__c==null)
        {
        	inputHolder.AddError(Label.Select_a_valid_Item);
        	return null;
        }
        
        if(selectedScopeRange == 'SINGLE' && icRec.Status__c!='Proposed')
        {
        	inputHolder.AddError(Label.Proposed_Costs_Can_Be_Activated);
        	return null;
        }
    	
        ActivateProposedCostsBatch Obj=new ActivateProposedCostsBatch();
        Obj.companyId = inputHolder.Company__c;
        Obj.facilityId = inputHolder.Facility__c;
        Obj.itemId = inputHolder.Item__c;
        Obj.scopeRange = selectedScopeRange;
        Obj.isUICall = true;
        
        Id jobId=Database.executebatch(obj,200);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Activate_Proposed_Costs_Batch_Scheduled ));
        have_jobid = true;
        return null;
    }
    
 
}