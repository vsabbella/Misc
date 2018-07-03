public with sharing class PurchaseOrderReturnToVendorExt {
        
    private apexpages.StandardSetController setCont;
    public Boolean uncaughtException {get; set;} { uncaughtException = false;}
    
    public List< Purchase_Order_Line__c > newPOLines { get; set; }{newPOLines = new List<Purchase_Order_Line__c>(); }
    public List< Purchase_Order_Line__c > oldPOLines { get; set; }{oldPOLines = new List<Purchase_Order_Line__c>(); }
    public List< Purchase_Order_Line__c > newPOLinesForDisplay { get; set; }{newPOLinesForDisplay = new List<Purchase_Order_Line__c>(); }
    map<Id, String> poStatusMap = new map<Id, String>();
    public Purchase_Order__c newPOHeader;
    public List<Purchase_Order__c> newPOHeaderList = new List<Purchase_Order__c>();
    public List< Supplier_Invoice__c > creditMemos { get; set; } { creditMemos = new List< Supplier_Invoice__c >(); }
    public List< Supplier_Invoice_Line__c >  creditMemoLines = new List< Supplier_Invoice_Line__c >(); 
    public String Supplier { get; set; }
    public String Company { get; set; }
    public String SupplierId;
    public String CompanyId;

    public String poID { get; private set; }



    public Boolean subcontractPOsExist {get;private set;} { subcontractPOsExist = false;}
    public Boolean dropShipPOsExist {get;private set;} { dropShipPOsExist = false;}
    
    //public String queryString;
    public SOQLUtil soql ;
    
    public List< ReturnToVendorService.POLineWrapper > POLinesForDisplay { get ; set ; } { POLinesForDisplay = new List< ReturnToVendorService.POLineWrapper >(); } 
    
    public PurchaseOrderReturnToVendorExt(apexpages.standardSetController controller){
 
        setCont = controller;

        poID = ApexPages.currentPage().getParameters().get('poID');

       

    }
    
    public void retrievePOLines(){
        Set<Id> POIds = new Set<Id>();

        if(poID == null || poID == '' ) { 
            if( setCont.getSelected().size() == 0){
            
                ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.FATAL, Label.No_records_selected) );
                return;
            }
        
            for( Purchase_Order__c po : ( List<Purchase_Order__c> ) setCont.getSelected()  ){
            
                POIds.add( po.id ); 
                
            }
        }
        else
        {
           POIds.add( poID );  
            
        }
 
        try{
        
        POLinesForDisplay = ReturnToVendorService.getreturningLines(POIds, new Set<Id>(),new Set<String>{'Purchase_Order_Line__c'.toLowerCase()});
        }Catch(DMLException e){
            system.debug('Error Found: ' + e.getStackTraceString() ); 
        }
    }
    
    public PageReference cancel(){
        
        PageReference prRef;
        if( apexPages.currentPage().getParameters().get('retUrl') != null ){
            
            prRef = new PageReference('/' + apexPages.currentPage().getParameters().get('retUrl') );    
        }
        else{
        
            Schema.DescribeSObjectResult dsr = Purchase_Order__c.SObjectType.getDescribe();
            prRef = new PageReference('/' + dsr.getKeyPrefix());            
        }       
        
        prRef.setRedirect(true);
        return prRef;
    }
    
    public PageReference save(){
 
        Boolean isvalid = false;
        integer count = 0;
        for( ReturnToVendorService.POLineWrapper polw : POLinesForDisplay ){
            
            if(polw.newPolRecord.Quantity_Returned_To_Supplier__c > 0|| polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c > 0) {
                isvalid = true;
                break;
            }
            else {
                count ++;
            }
        }   
        if(isvalid == false && count >0) {
            
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, 'Quantity to return must be specified with a value greater than zero.' ));
            return null;
        }   

		Savepoint sp1 = Database.setSavepoint();
		
		try{
			Map<String, List<SObject>> sObjectmap = new Map<String,List<SObject>>();
			Boolean hasError = ReturnToVendorService.checkUserErrors(POLinesForDisplay);
			
			if(!hasError){
				
				sObjectmap.putAll( new Map<String,List<SObject>>(ReturnToVendorService.returnToVendor(POLinesForDisplay, new Map<Id,Receipt_Line__c>(),new Map<Id,Sales_Order_Line__c>())));
				
 				for(String s:sObjectmap.keyset()){
 					
 					if(s.contains('oldPOLines')){
 						oldPOLines.addAll((List<Purchase_Order_Line__c>)sObjectmap.get(s));
 						 
 					}
 					else if(s.contains('newPOLinesForDisplay')){
 						newPOLinesForDisplay.addAll((List<Purchase_Order_Line__c>)sObjectmap.get(s));
 					}
 					else if(s.contains('creditMemos')){
 						creditMemos.addAll((List<Supplier_Invoice__c>)sObjectmap.get(s));
 					}
 					else if(s.contains('creditMemoLines')){
 						creditMemoLines.addAll((List<Supplier_Invoice_Line__c>)sObjectmap.get(s));
 					}
 					else if(s.contains('newPLines')){
 						newPOLines.addAll((List<Purchase_Order_Line__c>)sObjectmap.get(s));
 						
 					}
 					else if(s.contains('newPOHeader')){
 						newPOHeaderList.addAll((List<Purchase_Order__c>)sObjectmap.get(s));
 						if(newPOHeaderList.size()>0){
 							newPOHeader = newPOHeaderList[0];
 						}
 						
 					}
 					
 					
 				}
			}
			else{
				return null;
			}
		}
		catch( Exception e){
			
			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
			Database.rollback( sp1 );
			uncaughtException = true;
			return null;
		}
		
		PageReference resultsPage = Page.PurchaseOrderReturnToVendorResults;
		return resultsPage;
	}

    
}