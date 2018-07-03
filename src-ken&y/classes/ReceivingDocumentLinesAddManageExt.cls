public with sharing class ReceivingDocumentLinesAddManageExt{

    private apexpages.StandardController controller;
    public Boolean selecterror {get; set;}
    public Id RDocId;
    public String namespace { get; set;} { namespace = KSE.NamespaceUU;}
    private static SchemaUtil util = SchemaUtil.getInstance();
    
    public ReceivingDocumentLinesAddManageExt(apexpages.standardController con){
        controller=con;
        
        if ( ! Test.isRunningTest() ) {
            this.controller.addFields( new List<String>{ 'Company__c'} );
        }

        Receiving_Document__c theObject=(Receiving_Document__c)controller.getRecord();
        RDocId = theObject.ID;
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Status__c','Type__c'
		});
		soql.setWhereClause('ID = :RDocId');

		List<Receiving_Document__c> rdList = Database.query(soql.getQuery());
        
        map<Id,Receipt_Line__c> receiptLineMap = (map<Id,Receipt_Line__c>) ReceivingDocumentService.cachedReceiptLines( new set<Id>{ theObject.id}, 'Status__c != \'Closed\'' );
        objectList = receiptLineMap.values();
        
        selecterror = false;
        if (rdList.size() == 0 || (rdList[0].Status__c != 'Open' && rdList[0].Status__c != 'Draft')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Receiving_Document_is_not_Open) );
            selecterror = true;
            return;
        }
        
        if (rdList[0].Type__c != 'Miscellaneous Receipt' ) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Editing_is_allowed_only_for_Receiving_Documents_of_type_Miscellaneous) );
            selecterror = true;
            return;
        }
    }
   
    public pageReference save() {
        
        try  {
        	
        	//Validate if packaging uom is part of the Items Packaging UOMs...
        	SOQLUtil soql = new SOQLUtil('Receipt_Line__c');
		    soql.addFields(new Set<String>{ 'Id','Name','Item__r.Packaging_UOM__c','Receiving_Document__c','Packaging_UOM__c' });
            soql.addFields('Receiving_Line');
	    	soql.setWhereClause('Receiving_Document__c = :RDocId');
        	Map<Id,Receipt_Line__c> receiptlinesmap = new Map<Id,Receipt_Line__c>((List<Receipt_Line__c>)Database.query(soql.getQuery()));
        	
        	for(Receipt_Line__c rl:objectList){
        		Receipt_Line__c queriedrline;
        		Set<ID> lstPkgUom = new Set<Id>();
        		if(receiptlinesmap.containskey(rl.Id)){
        			queriedrline = (Receipt_Line__c)receiptlinesmap.get(rl.Id);
        			lstPkgUom = (Set<Id>) JSON.deserialize(queriedrline.Item__r.Packaging_UOM__c, Set<Id>.class );
        		}
        			
        		if(lstPkgUom.size()>0 && !lstPkgUom.contains(rl.Packaging_UOM__c)){
        			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, 'Packaging UOM needs to be present in items packaging UOMs. ') );
            		return null;
        		}
        	} 
            DML.checkUpsertAsUser(objectList); upsert objectList;
        } catch( Exception e) { // could be caused by validations
            Apexpages.addMessages(e);
            return null;
        }
        return new PageReference('/'+controller.getId());
    }

     public pageReference cloneporline() {
     
        List<Receipt_Line__c> POLList = new List<Receipt_Line__c> ();
    
        String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
        
        for ( Integer i : ArrayUtils.getIntegerList( selected_indexes ) ) {
            if (objectList[i].Line__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_clone_a_line_that_has_not_been_saved) );
                return null;
            }      
        }

        for ( Integer i : ArrayUtils.getIntegerList( selected_indexes ) ) {       
            Sobject ob = objectList[i];

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id objectId = ob.ID;
			
			SOQLUtil soql = new SOQLUtil('Receipt_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Company__c','Extended_Cost__c','Facility__c','Item__c','Line__c','Location__c','Number_of_Boxes__c','Purchase_Order__c',
				'Purchase_Order_Line__c','Receiving_Document__c','Supplier__c','Unit_Price__c','Status__c','Packaging_UOM__c'
			});
			soql.setWhereClause('ID = :objectId');

			Receipt_Line__c oldPORObject = Database.query(soql.getQuery());

            if (oldPORObject != null) {
                Receipt_Line__c newPORObject = new Receipt_Line__c();
                newPORObject = oldPORObject.clone(false,true);
                newPORObject.Quantity_Declared__c = null;
                newPORObject.Quantity_Received__c = null;
                newPORObject.Status__c = 'Draft';
                objectList.add(newPORObject);         
            }
        }
    	return null;
    }
    
    public pageReference remove() {     
        String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes'); 
        for (Integer i : ArrayUtils.getIntegerList( selected_indexes ) ) {
            Sobject ob = objectList[i];
            if (ob.id !=null) {
                try {
                    DML.deleteAsUser(ob);
                }
                catch(Exception e) { // could be caused by validations
                    Apexpages.addMessages(e);
                    return null;
                }
                
            }          
            objectList.remove(i);
            
        } 
        return null;
    }
    
    public pageReference addNewRow() {
        Receiving_Document__c theObject=(Receiving_Document__c)controller.getRecord();
        Receipt_Line__c rl = new Receipt_Line__c(Receiving_Document__c=theObject.id, Company__c=theObject.Company__c,
                                                     Status__c = 'Draft', Supplier__c=theObject.Supplier__c);
        rl.Purchase_Order_Line__c = null;
        objectList.add(rl);
        return null;
    }
    
    public list<Receipt_Line__c> objectList {get;set;}
    
  }