public with sharing class ReconciliationDetail {
	
/*	private id recordid ;
	public ApexPages.Standardcontroller controller;
	public String URLParametertopicId = '';
	public String URLParameterTitle = '';
	public String whereClause {get; set;}
	public Reconciliation__c recon {get; set;} //controller record
	public list<Reconciliation_Item__c> reconItems {get;set;}// {reconItems = new List<Reconciliation_Item__c>();}
	public ReconciliationDetail( ApexPages.Standardcontroller con) {   
		    controller = con; 
		    recordid = controller.getId(); 
		    recon = (Reconciliation__c) con.getRecord();
		    // get URL Parameters
		    URLParametertopicId = ApexPages.currentPage().getParameters().get('topicId');
		    URLParametertitle = ApexPages.currentPage().getParameters().get('title');
		    if(URLParametertopicId != null && URLParametertopicId != '' &&
		    	URLParametertitle != null && URLParametertitle != '' ){
				whereClause   = ' Reconciliation_Topic__c = \'' + URLParametertopicId+'\' AND Type__c = \'' + URLParametertitle+'\' ';   	
		    }
            //else{
		    //	whereClause   = ' Reconciliation_Topic__c =' + URLParametertopicId; 
		    //}
                //FIN-571 Fix - Recon Items of type 'Other'  are not getting filterd as they dont have recon topic.
                else{
		    	whereClause   = ' Type__c = \'' + URLParametertitle+'\' ';
		    }
    } 
    
    public pageReference review(){
    	Pagereference reviewRecon = Page.Reconciliation;
    	reviewRecon.getParameters().put('Id', controller.getId());
    	return reviewRecon;
    } 
    
    public string getReadOnlyFields(){
    	return string.join(SchemaUtil.getInstance().getFieldsFromFieldSetString(Reconciliation_Item__c.getSObjectType(), 'Recon_Detail'), ',');
    }*/
    }