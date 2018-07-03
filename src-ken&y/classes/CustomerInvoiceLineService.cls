public with sharing class CustomerInvoiceLineService {
	
	public static void customerInvoiceLinePricing(){
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
			list<Customer_Invoice_Line__c> lstCil = new list<Customer_Invoice_Line__c>();
			for(Customer_Invoice_Line__c cil:(list<Customer_Invoice_Line__c>) trigger.new){
				if(!cil.Finalized__c){
					lstCil.add(cil);
				}
			}
			if(!lstCil.isEmpty()){
				PricingService.customerInvoiceLinePricing(lstCil);
			}
		}
	}
	
	public static void setLineNumbers(list<Customer_Invoice_Line__c> CILines)
	{
		set<Id> parentIds = KSE.grepRelatedIdSetFromList(CILines,'Customer_Invoice__c');
        map<Id,Decimal> parentValueMap = new Map<Id,Decimal>();
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('Id IN :parentIds FOR UPDATE');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');
		childRel.addFields(new set<string>{
			'Line__c'
		});
		soql.addChildRelationship(childRel);
		list<Customer_Invoice__c> listCIs = Database.query(soql.getQuery());

         for (Customer_Invoice__c ci : listCIs) {
            parentValueMap.put(ci.Id,0);
            
            for (Customer_Invoice_Line__c cil:ci.Customer_Invoice_Lines__r){
                if (cil.Line__c > parentValueMap.get(ci.Id)){
                    parentValueMap.put(ci.Id,cil.Line__c);
                }
            }
        }
        
        // Assign line numbers
        for (SObject cil : CILines) {
            Id myOrder = (Id)cil.get('Customer_Invoice__c');
            
            if (!parentValueMap.containsKey(myOrder)){
                parentValueMap.put(myOrder,0);
            }
            
            Decimal val = parentValueMap.get(myOrder);
            ++val;              
            if ( cil.get('Line__c') != null ) {
                val = (Decimal)cil.get('Line__c');
            } 
            parentValueMap.put(myOrder,val);
            cil.put('Line__c',val);
            
        }
	}

	public static void setProRateFactor() {
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
			for(Customer_Invoice_Line__c cil : (list<Customer_Invoice_Line__c>) trigger.new) {
				Date sd = cil.Start_Date__c == null ? system.today() : Date.newInstance(cil.Start_Date__c.year(), cil.Start_Date__c.month(), cil.Start_Date__c.day());
				Date ed = cil.End_Date__c == null ? system.today() : Date.newInstance(cil.End_Date__c.year(), cil.End_Date__c.month(), cil.End_Date__c.day());
				if(trigger.isInsert || (trigger.isUpdate &&  (KSE.isFieldChanging('Start_Date__c', cil, trigger.oldMap) || KSE.isFieldChanging('End_Date__c', cil, trigger.oldMap) || KSE.isFieldChanging('Pricing_UOM__c', cil, trigger.oldMap)))) {
					cil.ProRate_Factor__c = cil.Price_Type__c == 'Sales' ? 1 : (PricingService.occurrenceMultiplier(sd, ed, PricingService.getOccurrence(cil.Pricing_UOM_Recurrence__c),
																										 		   cil.Recurrence_Start_Date__c == null ? 0 : cil.Recurrence_Start_Date__c.date().day(), PricingService.getEvery(cil.Pricing_UOM_Every__c))).setScale(6); 
				} 
			}
			
			
		}
	}
	
	public static void roundSalesTax() {
		
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
			
			if(trigger.isInsert){
				roundSalesTax((list<Customer_Invoice_Line__c>) trigger.new);
			}
			else {
				set<Id> sCILs = new set<Id>();
				for(Customer_Invoice_Line__c cil :(list<Customer_Invoice_Line__c>) trigger.new) {
					if(KSE.isFieldChanging('Sales_Tax__c',cil,trigger.oldMap))
						sCILs.add(cil.id);
				}
				if(!sCILs.isEmpty()) {
					map<Id,Customer_Invoice_Line__c> lCILs = new map<Id, Customer_Invoice_Line__c>((list<Customer_Invoice_Line__c>) trigger.new);
					set<Id> IdKeyset = lCILs.keySet();
					SOQLUtil soql = new SOQLUtil('Customer_invoice_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'Id','Sales_Tax__c'
					});
					soql.setWhereClause('Id in :IdKeyset and Customer_Invoice__r.Status__c = \'Open\'');
					for(Customer_Invoice_Line__c cil : Database.query(soql.getQuery())) {
						if(!sCILs.contains(cil.Id))
							lCILs.remove(cil.ID);
					}
					roundSalesTax(lCILs.values());
				}
				
				
			}
		}
		
		
	}
	
	
	public static void roundSalesTax(list<Customer_Invoice_Line__c> lCILs) {
		for(Customer_Invoice_Line__c cil : lCILs) {
			cil.Sales_Tax__c = cil.Sales_Tax__c != null ? cil.Sales_Tax__c.setScale(2, System.RoundingMode.HALF_EVEN) : cil.Sales_Tax__c;
		}
	}

}