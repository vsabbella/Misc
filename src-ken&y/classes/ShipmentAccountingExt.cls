public with sharing class ShipmentAccountingExt { 
 /*   
    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public list<Shipment__c> objectList {get;set;}
    set<ID> shipmentIDs = new set<ID>();
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; } 
    
    //GenerateAccountingService GAS = new GenerateAccountingService();
    ShipmentAccounting sa = new ShipmentAccounting();
    
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
	AccountingRuleService ARS = new AccountingRuleService();
	
    public ShipmentAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Shipment__c shipment: (List<Shipment__c>)setCon.getSelected() ) {      
            shipmentIDs.add(shipment.ID);
        }
        
       // String objectQuery =  'Select id, Name, Date_Shipped__c, Finalized__c, Transaction_Currency__c, Company__c,'+
	   //						'( Select id, Name, Extended_Cost__c, Extended_Price__c, Quantity_Shipped__c, Sales_Order_Line__r.id, Sales_Order_Line__r.Name, '+
       //                         'Sales_Order_Line__r.Sales_Order__c , Product__r.Item__c, Sales_Order_Line__r.Sales_Order__r.Type__c,  '+
       //                         'Unit_Price__c, Sales_Order_Line__r.Transaction_Currency__c'+
	   //						' from Shipment_Lines__r)'+
       //                         ' from Shipment__c '+
       //                         ' where id in :shipmentIds'+
       //                         ' and Finalized__c = true' +
       //                         ' AND transaction_date__c != null ' +
       //                         ' AND finalized_date__c != null ' +
       //                         ' and id not in ( Select Shipment__c from Accounting_Entry__c where Shipment__c in :shipmentIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        
        
        String whereClause = ' id in :shipmentIds'+
                            ' and Finalized__c = true' +
                            ' AND transaction_date__c != null ' +
                            ' AND finalized_date__c != null ' +
                            ' and id not in ( Select Shipment__c from Accounting_Entry__c where Shipment__c in :shipmentIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        
	    SOQLUtil soql = new SOQLUtil('Shipment__c');
	    soql.addFields(new Set<String>{'id', 'Name', 'Date_Shipped__c', 'Finalized__c', 'Currency__c', 'Company__c','Type__c','transaction_type__c'});
	    soql.setWhereClause(whereClause);
	    
	    SOQLUtil.ChildRelationship shLines = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
	    shLines.addFields(new Set<String>{'id', 'Name', 'Extended_Cost__c', 'Extended_Price__c', 'Quantity_Shipped__c', 
	    						'Sales_Order_Line__r.id', 'Sales_Order_Line__r.Name',
                                'Sales_Order_Line__r.Sales_Order__c' , 'Product__r.Item__c', 'Sales_Order_Line__r.Sales_Order__r.Type__c',
                                'Unit_Price__c', 'Sales_Order_Line__r.Currency__c'});
	    soql.addChildRelationship(shLines);
	    
        objectList = (List<Shipment__c>) Database.query(soql.getQuery());
        
        if (selecterror ) {
            return ;
        }
        
        list<string> transactionTypeList = new list<string>();
        
        for(Shipment__c sh: (list<Shipment__c>)objectList){
        		if(sh.transaction_type__c != null && sh.transaction_type__c != '')
        			transactionTypeList.add(sh.transaction_type__c);
        		else
        			transactionTypeList.add(sh.type__c);
        
        }
        if(!ARS.isRuleDefined(new List<String>{'Shipment__c'}, transactionTypeList)){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Define_Accounting_rules));
    		requiredFielderror = true;
        	selecterror = true;
        	return;
        }
        
        if(objectList == null || objectList.size() < 1){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process) );
          	requiredFielderror = true;
          	selecterror = true;
        	return;
        }
        for(integer i = 0; i < objectList.size(); i++){
        	if(objectList[i].Date_Shipped__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Date_shipped_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Currency__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Company__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        }
    } // End of Constructor
    
    //Function to generate the accounting entries for the shipment lines
    public pagereference GenerateShipmentAccounting() {
        Map<Id,Shipment__c> shipmentMapUpd = new Map<Id,Shipment__c>();
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
			try{
				set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();   
                for(Shipment__c sh : objectList){
                    companyIds.add(sh.company__c);
                    sourceDocIds.add(sh.Id);
                }             
                ShipmentAccountingBatch  batch = new ShipmentAccountingBatch(companyIds);
                batch.setSourceDocId(sourceDocIds);
                batch.setuseSuperWhere(true);
                string jobid= Database.ExecuteBatch(batch);  
			    	
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
                BatchInitiated=true;  	
			}catch(Exception e){
				Database.rollback(sp);
				String errorMessage = e.getMessage();
				ApexPages.addMessages(e);
				return null;
			}
        }
        //KNDY-2020 Checking for Pg msgs before moving the page forward. Hiding the button if any error or fatal msgs
        if (Apexpages.hasMessages(ApexPages.Severity.FATAL) || Apexpages.hasMessages(ApexPages.Severity.ERROR)){
        	requiredFielderror = true;
        	selecterror = true;
        	
        }
        return (Apexpages.hasMessages() ? null : this.setcon.cancel() ); 
        //return setcon.cancel();
    }
*/
}