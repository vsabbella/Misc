public with sharing class ContractLineService {
	
	 //KNDY-2292 The below service will run through all non-inactive contract lines and re-calculate the netting buckets 
   public static void recalculateNettingBuckets(List< Contract_Line__c > scopeCTLines){
   		SchemaUtil util = SchemaUtil.getInstance();
        Set<String> additionalFieldsToQuery = new Set<String>();
        Set<Id> keys = new Set<Id>();
        Map<Id, Contract_Line__c> ctlMap = new Map<Id, Contract_Line__c>();
        Map<Id, List<Purchase_Order_Line__c>> ctlToPOLinesMap = new Map<Id, List<Purchase_Order_Line__c>>();
        for(Contract_Line__c ctl: scopeCTLines){
            keys.add(ctl.id);
            
        } 
        
        additionalFieldsToQuery.addAll( new set<string>{'Id', 'Name', 'Company__c','Contract__c', 'Line__c', 'Exception__c', 'Exception_Details__c', 'Purchased_Quantity__c', 'PurchasedValue__c ','Purchase_Agreement_Line_Value__c'} ); //KNDY-6641 Breaking the PO Line query in its own so as to not lock on it
        SOQLUtil soql = new SOQLUtil('Contract_Line__c', TRUE);
        soql.addFields('Line_Release');
        soql.addFields(additionalFieldsToQuery);
        soql.setWhereClause('Id IN :keys FOR UPDATE');
        list< Contract_Line__c > ctlList = database.query(soql.getQuery()) ;
                        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Name','Status__c','Short_Close__c','Order_Quantity__c','Quantity_Received__c','Quantity_Returned_to_Supplier__c','Quantity_Returned_to_Supplier_for_Credit__c',
			'Quantity_Still_Due__c','Unit_Price__c','Contract_Line__c'
		});
		soql.setWhereClause('Contract_Line__c in :keys');
		for (Purchase_Order_Line__c poLine: Database.query(soql.getQuery())) {
        	if (ctlToPOLinesMap.containsKey(poLine.Contract_Line__c))
        		ctlToPOLinesMap.get(poLine.Contract_Line__c).add(poLine);
        	else
        		ctlToPOLinesMap.put(poLine.Contract_Line__c, new List<Purchase_Order_Line__c>{poLine});
        }
        system.debug(Logginglevel.info, 'ctlToPOLinesMap: ' + ctlToPOLinesMap);
                          
        if(ctlList.size() > 0){ 
        	for (Contract_Line__c ctLine: ctlList){
        		ctlMap.put(ctLine.id, ctLine);
        		
        //		ctlToPOLinesMap.put(ctLine.id, ctLine.Purchase_Order_Lines__r);
        		
        	}
        }
        
        /*
        	iterate over the PO lines per CT line and calculate the purchased quantity
        	Purchased Quantity on the Contract line = Sum of (Quantity Received - Quantity returned to supplier - Quantity returned to supplier for credit + Quantity Still Due)  
        */
        for (Id ctlId: ctlToPOLinesMap.keySet()){
        	system.debug(Logginglevel.info, 'Agreement line currently being processed: ' + ctlId);
        	Decimal purchasedQtySum = 0;
        	Decimal qtyRecd = 0;
        	Decimal purchasedValue = 0; 
        	Decimal valuerecd = 0; 
        	Decimal qtyStillDue = 0;
        	Decimal qtyReturned = 0;
        	Decimal remValue = 0;
        	for (Purchase_Order_Line__c poLine: ctlToPOLinesMap.get(ctlId)){
        		system.debug(Logginglevel.info, 'PO Line currently being processed: ' + poLine);
        		if ((poLine.Status__c == 'Open') || (poLine.Status__c == 'Closed' && poLine.Short_Close__c == false))
        			purchasedQtySum += (KSE.addQuantityToField(poLine.Order_Quantity__c,0));
    			else if ((poLine.Status__c == 'Closed') && (poLine.Short_Close__c))
    				purchasedQtySum += KSE.addQuantityToField(poLine.Quantity_Received__c,0) - KSE.addQuantityToField(poLine.Quantity_Returned_to_Supplier_for_Credit__c, 0);
				qtyStillDue += (KSE.addQuantityToField(poLine.Quantity_Still_Due__c, 0));
				qtyReturned += (KSE.addQuantityToField(poLine.Quantity_Returned_to_Supplier__c,0) + KSE.addQuantityToField(poLine.Quantity_Returned_to_Supplier_for_Credit__c,0));
				qtyRecd += (KSE.addQuantityToField(poLine.Quantity_Received__c,0));
				/* PTP-399 Value are converted to formula fields: will be calculated as qty x Agreement Price.
				purchasedValue += KSE.addQuantityToField(poLine.Order_Quantity__c,0) * KSE.addQuantityToField(poLine.Unit_Price__c, 0);
				valuerecd += (KSE.addQuantityToField(poLine.Quantity_Received__c,0)) * KSE.addQuantityToField(poLine.Unit_Price__c, 0); //KNDY-6576
				remValue += (KSE.addQuantityToField(poLine.Quantity_Received__c, 0) 
								+ KSE.addQuantityToField(poLine.Quantity_Still_Due__c, 0) 
								- (KSE.addQuantityToField(poLine.Quantity_Returned_to_Supplier__c,0) + KSE.addQuantityToField(poLine.Quantity_Returned_to_Supplier_for_Credit__c,0)))
								* KSE.addQuantityToField(poLine.Unit_Price__c, 0);
				*/
        	}
        	
        	ctlMap.get(ctlId).Purchased_Quantity__c = purchasedQtySum;
        	ctlMap.get(ctlId).Quantity_Received__c = qtyRecd;
        	ctlMap.get(ctlId).Quantity_Still_Due__c = qtyStillDue;
        	ctlMap.get(ctlId).Quantity_Returned__c = qtyReturned;
        	system.debug(Logginglevel.info, 'Agreement line - Purchased Quantity calculated: ' + purchasedQtySum);
        	system.debug(Logginglevel.info, 'Agreement line - Quantity_Received__c calculated: ' + qtyRecd);
        	
        	//TODO flag as exception
        }
        
        
       DML.updateAsUser(ctlMap.values());
        
   }
   //PTP-68 Remove Active flag from Purchase Agreement
   //Function to get Purchase Agreement lines and if the end date is < today's date, set status to Expired
   public static void updateExpiredStatus (List< Contract_Line__c > scopeCTLines){
   	
		List<Contract_Line__c> cLinetoUpdate = new List<Contract_Line__c>();
		for (Contract_Line__c cLine : scopeCTLines) {
			if (cLine.Contract_End__c < system.today() && (cLine.Status__c != 'Closed' || cLine.Status__c != 'Cancelled')) { //KNDY-7561 - Added the status condition filter
				cLine.Status__c = 'Expired';
				cLinetoUpdate.add(cLine);
			}
		}

		if (cLinetoUpdate.size() > 0){
			DML.updateAsUser(cLinetoUpdate);
		}	
   }
}