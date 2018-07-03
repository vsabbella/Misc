@isTest
public class InventoryChangeAccountingTest {
	@testsetup static void SampleData(){
		 //TestDataForFinance data = new TestDataForFinance();      
		testfuel fuel = new testfuel();
        List<Accounting_Rule__c> accRules = fuel.shipmentRuleList;
        
        List<Accounting_Rule__c>addedRules = new List<Accounting_Rule__c>();
        Accounting_Rule__c transferAccCreditDRCI = new Accounting_Rule__c();
        transferAccCreditDRCI.Object_Name__c = 'Inventory_Change__c';
        transferAccCreditDRCI.Transaction__c = 'Transfer Order Shipment';
        transferAccCreditDRCI.Subtransaction_Type__c = 'Transfer Order Shipment';
        transferAccCreditDRCI.Line_Type__c = null;
        transferAccCreditDRCI.Rule_Type__c = 'DR';
        transferAccCreditDRCI.Default_GL_Account__c = true;
        transferAccCreditDRCI.Amount_Reference__c = 'To_Standard_Cost__c';
        transferAccCreditDRCI.GL_Account__c = fuel.receivablesGL.id;
        transferAccCreditDRCI.Effective_Start_Date__c= fuel.effStartDate;
        transferAccCreditDRCI.Accounting_Standard__c = fuel.accountingStandard.Id;
        //addedRules.add(transferAccCreditDRCI);
        
         Accounting_Rule__c transferAccDebitDRCI = new Accounting_Rule__c();
        transferAccDebitDRCI.Object_Name__c = 'Inventory_Change__c';
        transferAccDebitDRCI.Transaction__c = 'Transfer Order Shipment';
        transferAccDebitDRCI.Subtransaction_Type__c = 'Transfer Order Shipment';
        transferAccDebitDRCI.Line_Type__c = null;
        transferAccDebitDRCI.Rule_Type__c = 'CR';
        transferAccDebitDRCI.Default_GL_Account__c = true;
        transferAccDebitDRCI.Amount_Reference__c = 'To_Standard_Cost__c';
        transferAccDebitDRCI.GL_Account__c = fuel.expenseGL.id;
        transferAccDebitDRCI.Effective_Start_Date__c= fuel.effStartDate;
        transferAccDebitDRCI.Accounting_Standard__c = fuel.accountingStandard.Id;
        addedRules.add(transferAccDebitDRCI);

        insert addedRules;
        
        List<Item_Cost__c> itemCostsLst = fuel.costList;
        work_order__c wo = fuel.workorder;
        List<Period__c> periodList = fuel.periodList;
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Lot_Number__c = false);
        update new Component__c(Id = fuel.components[1].Id,Type__c = ComponentService.TYPE_BYPRODUCT,Component_Sequence__c = null);
       
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<SKID__c> skids = fuel.skids;
        
         List<Inventory_Change__c> invChangeList = new List<Inventory_Change__c>();
         List<Inventory_Transaction__c> invtransList = new List<Inventory_Transaction__c>();
         Inventory_Change__c invchange1;
         Inventory_Transaction__c invtrans1;
         Inventory_Change__c invchange2;
         Inventory_Transaction__c invtrans2; 
         
         List<Item_Cost__c> itemCostList = new List<Item_Cost__c>(); 
        	invChangeList = new List<Inventory_Change__c>();
    	        invchange1 = new Inventory_Change__c();
    	        invchange1.Company__c = fuel.company.Id; 
    	        invchange1.Transaction_Date__c = system.now();
    	        invchange1.Type__c = 'Adjustment';
    	        invchange1.Item__c = fuel.itemList[0].id;
    	        invchange1.Reason_Code__c = null;
    	        invchange1.count_quantity__c = 3;
    	        invchange1.computer_Quantity__c = 3;
    	        invchange1.historical__c = false;
    	        
    	        invchange2 = new Inventory_Change__c();
    	        invchange2.Company__c = fuel.company.Id; 
    	        invchange2.Transaction_Date__c = system.now();
    	        invchange2.Type__c = 'Transfer Order Shipment';
    	        invchange2.Item__c = fuel.itemList[0].id;
    	        invchange2.Reason_Code__c = null;
    	        invchange2.count_quantity__c = 1;
    	        invchange2.computer_Quantity__c = 1;
    	        invchange2.historical__c = false;
    	         
    	        
	        invChangeList.add(invchange1);
	        invChangeList.add(invchange2);
	        
	        insert invChangeList;   
	        
	        
	        
	        Inventory_Change__c tmpIC = [SELECT Id, finalized__c  FROM Inventory_Change__c WHERE Id = :invchange1.Id];
	        system.assertNotEquals(true, tmpIC.finalized__c, tmpIC);   
                                                         
			invtransList = new List<Inventory_Transaction__c>();
			invtrans1 = new Inventory_Transaction__c();	
		
			    invtrans1.Inventory_Change__c = invChangeList[0].id;
    			invtrans1.Item__c = fuel.itemList[0].id;			
    			invtrans1.Extended_Cost__c = null;
    			invtrans1.Type__c = 'Cycle Count';
    			invtrans1.Subtransaction_Type__c = 'Cycle Count';
    			invtrans1.Line_Type__c = 'Increase';
    			invtrans1.Standard_Cost__c = 3;
    			invtrans1.To_Standard_Cost__c = 3;
    			invtrans1.Quantity__c = 10;
    			invtrans1.quantity_Stocking_UOM__c =1;
                invtrans1.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                invtrans1.Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c;
    			invtrans1.Company__c = fuel.company.Id;
			
			
			invtrans2 = new Inventory_Transaction__c();	
			
    			invtrans2.Inventory_Change__c = invChangeList[1].id;
    			invtrans2.Item__c = fuel.itemList[0].id;				 
    			invtrans2.Type__c = 'Transfer Order Shipment';
    			invtrans2.Subtransaction_Type__c = 'Transfer Order Shipment';
    			invtrans2.Line_Type__c = null;
    			invtrans2.Standard_Cost__c = 3; 
    			invtrans1.To_Standard_Cost__c = 3;
    			//invtrans2.Quantity__c = 1;
    			invtrans2.Extended_Cost__c = null;
    			invtrans2.quantity_Stocking_UOM__c =1;
                invtrans2.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                invtrans2.Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c;
    			invtrans2.Company__c = fuel.company.Id;
     		 	
     			invtrans2.From_Location__c  = fuel.location.id;//29.7
     			invtrans2.From_Facility__c  = fuel.location.facility__c;
     			
     			invtrans2.To_Location__c    = fuel.location2.id; 
     			invtrans2.To_Facility__c    = fuel.location2.facility__c;
     			
     
			invtransList.add(invtrans1); 
			invtransList.add(invtrans2); 
			insert invtransList;
			
			for(Inventory_Change__c ic : invChangeList){
				ic.finalized__c = true;
			}
			
			update invChangeList;
        
        
	}
	  
	//----KNDY-17222 --Accounting for Transfer Order Shipments should be looking to FROM FACILITY ( Instead of TO FACILITY)---//
	static testmethod void testTransferAccounting(){ 
	     Test.startTest();  
	      Inventory_Change__c invchange2 = [SELECT id, Name, Finalized__c, Finalized_hidden__c,Transaction_Date__c
                                                FROM Inventory_Change__c 
                                                WHERE Type__c = 'Transfer Order Shipment'];
         
         System.debug(logginglevel.error,'current IC'+ invchange2);
         
         List<Inventory_Transaction__c> newITs = [ SELECT id,Transaction_Date__c,quantity_Stocking_UOM__c,Company__c,
                                                            item__r.name,Item__c,
                                                            From_Facility__c,From_Facility__r.name,
                                                            From_Location__r.Facility__c,
                                                            To_Facility__c ,To_Facility__r.name,
                                                            From_Location__c,To_Location__c , 
                                                            Inventory_Change__r.Currency__c, isfinalized__c, 
                                                         	Standard_Cost__c, to_standard_cost__c, Quantity__c, 
                                                         	Inventory_Change__c, Finalized__c, Historical__c 
                                                 	FROM Inventory_Transaction__c 
            										WHERE Type__c = 'Transfer Order Shipment' 
            										limit 1]; 
        Id fromFacId = newITs[0].From_Location__r.Facility__c;
        
        Decimal stockQty = newITs[0].quantity_Stocking_UOM__c;
        
        System.debug(logginglevel.error,+'Item selected is  '+newITs[0].item__r.name +
                                         'From_Location__r.Facility__c id '+fromFacId+
                                         'stockQty is '+stockQty);
        
        List<Item_Cost__c> fromCost = [SELECT id,name ,Standard_Cost__c,
                                              Facility__c,Date_Approved__c,Status__c 
                                            FROM Item_Cost__c 
                                            WHERE Status__c ='Approved' 
                                            AND Facility__c =:fromFacId 
                                            AND item__r.name = 'Kenandy-Main Company Item-10' 
                                            LIMIT 1 ];
                                           // LIMIT 1]; 
                                            //   Name=Kenandy-Main Company Item-10, 
                                            //   Standard_Cost__c=29.700000, 
                                            //   Facility__c=a186A0000006ZrnQAE, 
                                            //   Date_Approved__c=2017-06-29 00:27:18,   
        
        List<Item_Cost__c> ToCost = [SELECT id,name ,Standard_Cost__c ,
                                            Facility__c,Date_Approved__c,Status__c 
                                        FROM Item_Cost__c 
                                        WHERE Status__c ='Approved' 
                                        AND Facility__c =:newITs[0].to_Facility__c 
                                        AND item__r.name = 'Kenandy-Main Company Item-10'  
                                        LIMIT 1];   
                                           
                                            
        System.debug(logginglevel.error,'From FAC Item Cost'+fromCost+ 'To FAC Item Cost' + ToCost);
         
         List<Accounting_Rule__c> acccRuleList = [SELECT id,Accounting_Standard__c,name 
                                                     FROM Accounting_Rule__c 
                                                     WHERE  Transaction__c ='Transfer Order Shipment'];
        system.debug(logginglevel.error,'acccRuleList'+acccRuleList);                                         
         
        InventoryChangeAccounting ica = new InventoryChangeAccounting();
	    ica.execute(newITs);		
            
	    Set<Id> icIds = new Set<Id>();
	    for(Inventory_Transaction__c it: newITs){
	        icIds.add(it.Inventory_Change__c);
	    }
     
        List<Accounting_Entry__c> accountingEntryListIT = [SELECT id, Name, Inventory_Change__c,has_exceptions__c,
                                                                      COMP_Total_Credit__c,COMP_Total_Debit__c
                                                            FROM Accounting_Entry__c
                                                            WHERE Inventory_Change__c in :icIds];
                                                                    
        //  Name=AE-0000000179, Inventory_Change__c=a1M6A000000RgsNUAS,Has_Exceptions__c=false, 
        //  COMP_Total_Credit__c=29.700000, COMP_Total_Debit__c=29.700000})
         
        System.debug(logginglevel.error,'accountingEntryListIT'+accountingEntryListIT);
        
        for(Accounting_Entry__c ae : accountingEntryListIT){
            system.assertEquals(false, ae.has_exceptions__c);
        }
        
        system.assertNotEquals(null, accountingEntryListIT);
        system.assertEquals(1, accountingEntryListIT.size()); 
        System.assertEquals(fromCost[0].Standard_Cost__c*stockQty,accountingEntryListIT[0].COMP_Total_Credit__c); 
        
        // #####################  CHECK FOR EXCEPTIONS #################
            //   List<task> tks = [ select id, whatid,Exception_Code__c,
            //                                     Type,subject,
            //                                      description from Task  ]; 
              
            //   system.debug(logginglevel.error,'tks all'+tks);  
         
	   Test.stopTest();   
	     
	} 
	
	static testmethod void testInvChangeAccounting(){
        
        
        Test.startTest();   
         
        Inventory_Change__c invchange1 = [Select id, Name, Finalized__c, Finalized_hidden__c,Transaction_Date__c
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
            
        system.assertEquals(true, invchange1.Finalized__c);
        system.assertEquals(true, invchange1.Finalized_hidden__c);
            
        boolean sawException = false;
        try{
            invchange1.Finalized__c = false;
            update invchange1;
        }catch(Exception e){
            sawException = true;
        }
            
		system.assertEquals(true, sawException);
        
		invchange1 = [Select id, Name, Finalized__c, Finalized_hidden__c, Historical__c, Company__c, Currency__c
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
        list<Inventory_Change__c>invChangeList = [Select id, Name, Finalized__c, Finalized_hidden__c, Historical__c, Company__c, Currency__c
                                from Inventory_Change__c];
        
        system.assertEquals(true, invchange1.finalized__c, invChange1);
        
		List<Inventory_Transaction__c> newITs = [ select id, Inventory_Change__r.Currency__c, isfinalized__c, 
                                                 	Standard_Cost__c, to_standard_cost__c, Quantity__c, Transaction_Date__c, Inventory_Change__c, Finalized__c, Historical__c 
                                                 	from Inventory_Transaction__c 
            										where Inventory_Change__r.Type__c = 'Adjustment' ];
        system.assertNotEquals(0, newITs.size(), newITs);
        
	    InventoryChangeAccounting ica = new InventoryChangeAccounting();
	    ica.execute(newITs);		
            
	    Set<Id> icIds = new Set<Id>();
	    for(Inventory_Change__c ic: invChangeList){
	        icIds.add(ic.id);
	    }
        //system.debug('invChangeList: '+ invChangeList);      
        List<Accounting_Entry__c> accountingEntryListIT = [Select id, Name, Inventory_Change__c
                                                                    from Accounting_Entry__c
                                                                    where Inventory_Change__c in :icIds];
                                                                    
                                                                
        system.assertNotEquals(null, accountingEntryListIT);
        system.assertEquals(1, accountingEntryListIT.size());
	}	
	
	public static testMethod void testFinalizeHeaderValidation(){
        
        
        Test.startTest();   
         
        Inventory_Change__c tmpIC = [Select id, Name, Finalized__c, Finalized_hidden__c,Transaction_Date__c
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
            
        system.assertEquals(true, tmpIC.Finalized__c);
        system.assertEquals(true, tmpIC.Finalized_hidden__c);
        
        Datetime trxnDate = tmpIC.Transaction_Date__c;
        boolean sawException = false;
        string exMsg;
        try{
            tmpIC.Transaction_Date__c = null;
            update tmpIC;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit a finalized doc ' + exMsg );
        
        sawException = false;
        exMsg = null;
        tmpIC.Transaction_Date__c = trxnDate;
        try{
            delete tmpIC;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete a finalized doc ' + exMsg );
        
        test.stopTest();
    }
    
    public static testMethod void testFinalizeLineEditValidation(){
    	
        
        Test.startTest();   
         
        Inventory_Change__c tmpIC = [Select id, Name, Finalized__c, Finalized_hidden__c,(select id ,Inventory_Change__c,
			Item__c, Extended_Cost__c,Type__c ,Subtransaction_Type__c,Line_Type__c,Standard_Cost__c,
			To_Standard_Cost__c,Quantity__c ,quantity_Stocking_UOM__c ,Packaging_UOM__c,Stocking_UOM__c, 
			Company__c from Inventory_Transactions__r )from Inventory_Change__c 
            where Type__c = 'Adjustment'];
            
        system.assertEquals(true, tmpIC.Finalized__c);
        system.assertEquals(true, tmpIC.Finalized_hidden__c);
        
        for(Inventory_Transaction__c it : tmpIC.Inventory_Transactions__r){
		    it.Subtransaction_type__c = 'Change';
		}
		
		boolean sawException = false;
        string exMsg = null;
        try{
        	update tmpIC.Inventory_Transactions__r;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit finalized doc lines ' + exMsg );
    }
    
        
    public static testMethod void testFinalizeLineDeleteValidation(){
    	
        
        Test.startTest();   
         
        Inventory_Change__c tmpIC = [Select id, Name, Finalized__c, Finalized_hidden__c,(select id ,Subtransaction_type__c from Inventory_Transactions__r )
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
            
        system.assertEquals(true, tmpIC.Finalized__c);
        system.assertEquals(true, tmpIC.Finalized_hidden__c);
        
    	    
        boolean sawException = false;
        string exMsg = null;
        try{
        	delete tmpIC.Inventory_Transactions__r;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete finalized doc lines ' + exMsg );
    }
 	
 	public static testMethod void testFinalizeLineAddValidation(){
    	
        
        Test.startTest();   
         
        Inventory_Change__c tmpIC = [Select id, Name, Finalized__c, Finalized_hidden__c,(select id ,Subtransaction_type__c from Inventory_Transactions__r )
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
            
        system.assertEquals(true, tmpIC.Finalized__c);
        system.assertEquals(true, tmpIC.Finalized_hidden__c);
        
 	
        boolean sawException = false;
        string exMsg = null;
        try{
        	List<Inventory_Transaction__c> newITs = new List<Inventory_Transaction__c>();
        	for(Inventory_Transaction__c it : tmpIC.Inventory_Transactions__r){
			    newITs.add(it.clone(false, true));
			}
        	insert newITs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
     	
     	test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to add lines to a finalized doc ' + exMsg );
 	}
 	
 	public static testMethod void testFinalizeLineUndeleteValidation(){
    	
        
        Test.startTest();   
        Inventory_Change__c tmpIC = [Select id, Name, Finalized__c, Finalized_hidden__c,Historical__c,Finalized_Date__c,Posting_Date__c,(select id ,Company__c,Subtransaction_type__c from Inventory_Transactions__r ),Transaction_Date__c
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
        
        Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{tmpIC});
        system.assertEquals(true, mResponses.get(tmpIC.Id).Success, 'We need to unfinalize this doc to add and remove lines for undelete');
        
        List<Inventory_Transaction__c> newITs = new List<Inventory_Transaction__c>();
    	for(Inventory_Transaction__c it : tmpIC.Inventory_Transactions__r){
		    newITs.add(it.clone(false, true));
		}
    	insert newITs;
    	
    	delete newITs;
    	
    	tmpIC.finalized__c = true;
    	update tmpIC;
    	
         tmpIC = [Select id, Name, Finalized__c, Finalized_hidden__c
                                from Inventory_Change__c 
                                where Type__c = 'Adjustment'];
            
        system.assertEquals(true, tmpIC.Finalized__c);
        system.assertEquals(true, tmpIC.Finalized_hidden__c);
    	
		boolean sawException = false;
        string exMsg = null;
		
		try{
			undelete newITs;
     	}catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
     	test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to undelete lines on a finalized doc ' + exMsg );
 	}
	
    public static testMethod void testICAccoutingMissingRule_CompositeCost() {
        TestFuelQuery fuel = new TestFuelQuery();
        
        delete [SELECT Id FROM Routing__c];

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });
        
        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 9;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Item__r = wo.Item__r;

        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, op.Id, true).records;
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, backflushRows, null, true) });
        
        List<Inventory_Change__c> inv = [SELECT Id,Type__c,Work_Order__c,Transaction_Date__c,Finalized__c,company__c,
                                                (SELECT Id,Name,Inventory_Change__c,Item__c,Subtransaction_Type__c,Line_Type__c,To_Location__r.Facility__c,From_Location__r.Facility__c
                                                FROM Inventory_Transactions__r WHERE Subtransaction_Type__c = 'Work Order Assembly Completion')
                                        FROM Inventory_Change__c WHERE Work_Order__c = :wo.id and Type__c = 'Work Order Complete'];

        System.assert(inv.size() == 1,ApexPages.getMessages());
        System.assert(inv[0].Finalized__c == true);
        System.assert(inv[0].Transaction_Date__c != null,inv[0]);
        System.assert(inv[0].Inventory_Transactions__r.size() == 1,inv[0].Inventory_Transactions__r);
                
         
        List<Item_Cost__c> itemCostList = new List<Item_Cost__c>();
        
        Item_Cost__c ItemCostObj2 = new Item_Cost__c();
        ItemCostObj2.Item__c = inv[0].Inventory_Transactions__r[0].item__c;
        ItemCostObj2.Status__c = 'Proposed';
        ItemCostObj2.Material_Cost__c = 550;
        ItemCostObj2.Labor_Cost__c = 10;
        ItemCostObj2.Outside_Processing_Cost__c = 20;
        ItemCostObj2.Overhead_Cost__c = 5;
        ItemCostObj2.Start_date__c = DateTime.now().addHours(-1);
        ItemCostObj2.Company__c = inv[0].company__c;
        itemcostList.add(ItemCostObj2);
        
        insert itemcostList;
        
        for(Item_Cost__c ic : itemcostList){
            ic.Status__c = 'Approved';
            ic.Date_Approved__c = DateTime.now();
        }
        ItemService.allowItemCostUpdate = true;
        update itemcostList;
        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        ica.execute(inv[0].Inventory_Transactions__r);
        system.assert(inv[0].Inventory_Transactions__r.size() == 1,'ITs:'+inv[0].Inventory_Transactions__r.size()+inv[0].Inventory_Transactions__r);
        
       
        List<Accounting_Entry__c> aeList = [Select id, Name, Transaction_Type__c, transaction_date__c,
                                            ( Select id,  Name, Subtransaction_type__c, line_type__c, error_message__c, amount_cr__c, amount_dr__c, Inventory_Transaction__c, item_cost_missing__c
                                            from Accounting_Entry_Lines__r where inventory_transaction__c = :inv[0].Inventory_Transactions__r[0].id) 
                                            from Accounting_Entry__c where Inventory_Change__c = :inv[0].id];
        
        Decimal debitAmt, creditAmt;
        debitAmt = 0; 
        creditAmt = 0;
        system.assert(aeList[0].accounting_entry_lines__r.size() != 0,'aeList'+aeList+'******************aels:'+aeList[0].accounting_entry_lines__r+ '******************itemCostList:' +ItemCostObj2);
        for(Accounting_Entry_Line__c ael: aeList[0].accounting_entry_lines__r){
        	system.assertEquals(ael.item_cost_missing__c, false);
        	system.assert(ael.error_message__c.contains('Missing accounting rule'));
        	if(ael.line_type__c == null){
        		debitAmt = ael.amount_dr__c;
        	}else{
        		creditAmt = creditAmt + ael.amount_cr__c;
        	}

        }
        system.assert(debitAmt!= 0,'Not expected to see the debit amount 0');
        system.assert(creditAmt!= 0,'Not expected to see the credit amount 0');
        system.assertEquals(debitAmt, creditAmt);
        Test.stopTest();
  }
}