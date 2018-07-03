public with sharing class CreditProfileExt{
	
    public Apexpages.Standardcontroller con {get;set;}
    public string recId {get;set;}
    public CreditRule newRule { get; set; } 

    public list<CreditRule> rules {get; set; } { rules = new List<CreditRule>(); }
    
    public CreditProfileExt(Apexpages.StandardController controller){
        con = controller;   
        load();        
    }
    public void load() { 
        rules.clear();
        for ( Credit_Profile_Rules__c r: Credit_Profile_Rules__c.getall().values()) { 
            rules.add( new CreditRule(r) ); 
        }
    	newRule = new CreditRule();
    }
    public pageReference saveNewRule() {
     	try { 
     		newRule.insertRule();
            load();
     	} catch( Exception ex ) { 
     		Apexpages.addMessages( ex );
     	}
     	return ( Apexpages.hasMessages() ? null : editPage() ); 
    }
    
    public pageReference saveSSCon(){
        for( CreditRule r : rules) { r.updateRule(); }
        return Page.CreditProfileEdit;
    }
    
    private PageReference editPage() { 
        pageReference newPage = Page.CreditProfileEdit;
        newPage.setRedirect(true);
        return newPage;
    }
    
    public pageReference deleteRef(){
        try {
            if(recId != null && recId != ''){
                DML.deleteAsUser(new List<Id>{recId}, true);
            }
        } catch(Exception ex) {
            Apexpages.addMessages(ex); 
        }
        return ( Apexpages.hasMessages() ? null : editPage() ); 
        
    }
    
    public class CreditRule { 
        public Id Id {get;set;}		
        public String Name {get;set;}        
        public String AR_Percent_Past_Due {get; set; }
        public String Days_Past_Due {get; set; }
        public String Percent_Over_Credit {get; set; }
        
        public CreditRule(Credit_Profile_Rules__c record) {
            this.Id = record.Id;
            this.Name = record.Name;
            this.AR_Percent_Past_Due  = String.valueof(record.AR_Percent_Past_Due__c) ;
            this.Days_Past_Due  = String.valueof(record.Days_Past_Due__c );
            this.Percent_Over_Credit	 = String.valueof(record.Percent_Over_Credit__c)	;
        }
        public CreditRule() {}
        
        public Credit_Profile_Rules__c getCreditRule() {
            Credit_Profile_Rules__c tmp = new Credit_Profile_Rules__c(Id = this.Id, Name = this.Name );
            if (this.AR_Percent_Past_Due!=null && this.AR_Percent_Past_Due!='')
                tmp.AR_Percent_Past_Due__c = Decimal.valueof(this.AR_Percent_Past_Due);     
            if ( this.AR_Percent_Past_Due=='')
                tmp.AR_Percent_Past_Due__c = null;
            
            if (this.Days_Past_Due!=null && this.Days_Past_Due!='')
                tmp.Days_Past_Due__c= Decimal.valueof(this.Days_Past_Due);            
            if (this.Days_Past_Due == '')
                tmp.Days_Past_Due__c = null;
                
            if ( this.Percent_Over_Credit!=null && this.Percent_Over_Credit !='')
                tmp.Percent_Over_Credit__c= Decimal.valueof(this.Percent_Over_Credit);           
			if (this.Percent_Over_Credit =='')
                tmp.Percent_Over_Credit__c = null;
                
			return tmp;
        }
        
        public void insertRule() {
            Credit_Profile_Rules__c  rule = this.getCreditRule();
            DML.insertAsSystem(rule); //intended to allow insert for non admin user            
        }
        public void updateRule() { 
            Credit_Profile_Rules__c  rule = this.getCreditRule();
            DML.updateAsSystem(rule); //intended to allow update for non admin user            
        }
    }   
}