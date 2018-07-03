public with sharing class BracketPricingUpchargeManageExt {
    
    public class BracketPriceWrapper extends BracketPricingService.BracketPrice{
        
        public boolean inUse {get;set;}
        
        public BracketPriceWrapper(Reason_Code__c r, Boolean iu) {
            super(r);
            this.inUse = iu;
        }    	
    	public BracketPriceWrapper(Id companyId, Boolean iu) {
            super(companyId);
            this.inUse = iu;
        }       
    }

    Id companyId;
    public List<BracketPriceWrapper> bracketWraps {get;set;}
    
    public BracketPricingUpchargeManageExt(ApexPages.StandardController stdController) {
        this.companyId = stdController.getId();
        init();   
    }
    
    void init () {
    	this.bracketWraps = new List<BracketPriceWrapper>();
        Map<Id, Reason_Code__c[]> codesByCompanyId = BracketPricingService.loadBrackets(new Set<Id>{companyId});
        Reason_Code__c[] codes = codesByCompanyId.get(companyId);
        if (codes != null) {
            for (Reason_Code__c rc : codes) {
                this.bracketWraps.add(new BracketPriceWrapper(rc, true));
            }            
        }

        while (bracketWraps.size () < 5) {            
            this.bracketWraps.add(new BracketPriceWrapper(companyId, false));
        }    	
    }

    public void onSave() {
        List<BracketPriceWrapper> wrappers2Save = new List<BracketPriceWrapper>();
        List<Reason_Code__c> brackets2Delete = new List<Reason_Code__c>();
        for (BracketPriceWrapper rcw: bracketWraps) {
            if (rcw.inUse) {
                wrappers2Save.add(rcw);
            } else if (rcw.reasonCode.Id != null) {
            	brackets2Delete.add(rcw.reasonCode);
            }
        }
        if (!brackets2Delete.isEmpty()) {
            // KNDY-3590
            DML.deleteAsUser(brackets2Delete);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Deleted_brackets + brackets2Delete.size()));

        }
        if (!wrappers2Save.isEmpty()) {
            List<Reason_Code__c> brackets2Save = new List<Reason_Code__c>();

        	Set<Decimal> bracketBottoms = new Set<Decimal>();
        	Set<Decimal> upcharges = new Set<Decimal>();
        	Set<String> priceFieldsUsed = new Set<String>();
        	for (BracketPriceWrapper rcw : wrappers2Save) { 
        		if (priceFieldsUsed.contains(rcw.pricebookLineField)) {
        			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Pricebook_line_field_used_in_one_price_bracket_only + rcw.pricebookLineField ));
        			return;		
        		}
        		priceFieldsUsed.add(rcw.pricebookLineField);
        		
        		if (bracketBottoms.contains(rcw.volumeRangeBottom)) {
        			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.VolumeRangeBottom_used_in_one_price_bracket + rcw.volumeRangeBottom ));
        			return;		
        		}
        		bracketBottoms.add(rcw.volumeRangeBottom);
        		
        		if (upcharges.contains(rcw.percentUpCharge)) {
        			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Following_upcharge_used_in_one_price_bracket + rcw.percentUpCharge + ' % '));
        			return;		
        		}
        		upcharges.add(rcw.percentUpCharge);        		

                brackets2Save.add(rcw.reasonCode);
        	}
        	
        	
        	try { 
        		DML.checkUpsertAsUser(brackets2Save); upsert brackets2Save;
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Brackets_saved + brackets2Save.size()));
        	} catch (Dmlexception dmle) {
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Brackets_failed_to_save + dmle.getNumDml() + ' / '+ brackets2Save.size()));
	    		for (Integer idx = 0; idx < dmle.getNumDml() ; idx++) {
	    			Reason_Code__c rc = brackets2Save[dmle.getDmlIndex(idx)];
					rc.addError(dmle.getDmlMessage(idx));
	    		}
	    		return;
        	}
    	}
    	
    	// start with clean slate again
    	init();
	}   
}