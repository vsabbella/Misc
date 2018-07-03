@isTest
public class InventoryChangeAccountingBatchTest {
	@testSetup static void InventoryChangeTestData(){
	//static TestWork work = TestWork.getInstance();
 	Testfuel fuel = new Testfuel();
 	List<Period__c> periodList = fuel.periodList;
		List<Inventory_Change__c> invChanges = new List<Inventory_Change__c>();
 		for(integer i=0; i<100; i++) {
 			Inventory_Change__c ic = new Inventory_Change__c();
 			ic.company__c = fuel.company.id;
	 		ic.item__c = fuel.itemList[0].id;
	 		ic.type__c = 'Adjustment';
	 		ic.count_quantity__c = i;
	 		ic.transaction_date__c = system.now();
	 		invChanges.add(ic);
 		}
 		insert invChanges;
 		
 		List<Inventory_Transaction__c> invTrxns = new List<Inventory_Transaction__c>();
 		for(Inventory_Change__c ic : invChanges){
 			Inventory_Transaction__c it = new Inventory_Transaction__c();
	       	it.item__c = fuel.itemList[0].Id;
	       	//it.work_order__c = work.workorder.Id;
	       	it.quantity__c = 1;
	       	it.Quantity_Stocking_UOM__c = 1;
	       	it.Packaging_UOM__c = fuel.uomList[8].Id;
	       	it.Stocking_UOM__c = fuel.uomList[8].Id;
	       	it.standard_cost__c = 1;
	       	it.transaction_date__c = system.now();
	       	it.type__c = 'Adjustment Increase';
	       	it.to_location__c = fuel.location.Id;
	       	it.inventory_change__c = ic.Id;
			it.Subtransaction_Type__c = 'Adjustment Increase';
			it.Company__c = fuel.company.Id;
			//it.Line_Type__c = 'Increase';	       	
	       	invTrxns.add(it);
 		}
 		insert invTrxns;
	}

	 public static testMethod void testBatch() {
	 	//InventoryChangeTestData();
	 	Test.startTest();
	 	List<Inventory_Change__c> invChanges = [SELECT ID, company__c, Item__c, Type__c, count_quantity__c, transaction_date__c, Currency__c, Transaction_Currency__c FROM Inventory_Change__c limit 10];
	 	List<Inventory_Transaction__c> invTrxns = [SELECT ID, Item__c, quantity__c,Quantity_Stocking_UOM__c, standard_cost__c, transaction_date__c, type__c, to_location__c, inventory_change__c, Subtransaction_Type__c, company__c FROM Inventory_Transaction__c];

		//system.assert(1==2, invChanges.size()); 		
 		for(Inventory_Change__c ic : invChanges){
 			ic.finalized__c = true;
 		}
 		update invChanges;
 		Company__c thisCompany = [SELECT ID, Name FROM Company__c LIMIT 1];
 		Database.executeBatch(new InventoryChangeAccountingBatch(new Set<Id>{thisCompany.Id}));
 		
 		test.stopTest();
 		
 		//Assert the accounting entries were generated
 		List<Accounting_Entry__c> aes = [SELECT Id FROM Accounting_Entry__c WHERE Inventory_Change__c IN :invChanges];
		system.assert(aes.size() == 10,'aes size:'+aes.size()); 
		
		list<Inventory_Change__c> icList = [Select id, Name, (Select id, Name from Accounting_entries__r where void__c = false) from Inventory_Change__c where id in :invChanges];
		Integer icListsize = icList.size();
		for(Integer i = 0; i< icListsize; i++){
		    system.assertNotEquals(0,icList[i].accounting_entries__r.size());
		}
		
	 }
	 	
	public static testMethod void testBatchWithDifferentCostDates() {
 		Company__c thisCompany = [SELECT ID, Name FROM Company__c LIMIT 1];
        item__c item1 = [SELECT ID, Name FROM item__c LIMIT 1];
        location__c loc = [SELECT ID, Name FROM location__c LIMIT 1];
        gl_account__c GRNIGL = [SELECT ID, Name FROM gl_account__c LIMIT 1];
        Accounting_Standard__c acctStd = [SELECT ID, Name FROM Accounting_Standard__c LIMIT 1];
        
        List<Period__c> periodList = [SELECT ID, Name, open__c FROM Period__c];
        item_cost__C itemcostTemp = [SELECT ID, Name,start_Date__c FROM item_cost__C LIMIT 1];
        item_cost__C itemcost1 = itemcostTemp.clone(false,true,false,false);
        itemcost1.status__c = 'Proposed' ; 
        itemcost1.Item__c = item1.id;
        itemcost1.Company__c = thisCompany.id;
        itemcost1.start_Date__c = system.now().addDays(-1);
        insert itemcost1;
         
        ItemService.allowItemCostUpdate = true;
        itemcost1.status__c = 'Approved' ; 
        itemcost1.Date_Approved__c = DateTime.now();
        itemcost1.On_hand_Revaluation__c = true; 
        update itemcost1;
                
		List<Inventory_Change__c> invChanges = new List<Inventory_Change__c>();
 		List<Inventory_Transaction__c> invTrxns = new List<Inventory_Transaction__c>();
        Inventory_Change__c ic = new Inventory_Change__c();
        ic.company__c = thisCompany.id;
        ic.item__c = item1.id;
        ic.type__c = 'Purchase Order Receipt';
        ic.count_quantity__c = 1;
        ic.transaction_date__c = system.now().addDays(-2);
        invChanges.add(ic); 
         
        Inventory_Change__c ic1 = new Inventory_Change__c();
        ic1.company__c = thisCompany.id;
        ic1.item__c = item1.id;
        ic1.type__c = 'Purchase Order Receipt';
        ic1.count_quantity__c = 1;
        ic1.transaction_date__c = system.now();
        invChanges.add(ic1);
         
        insert invChanges;
        
        Inventory_Transaction__c it = new Inventory_Transaction__c();
        it.item__c = item1.Id;
        it.quantity__c = 1;
        it.Quantity_Stocking_UOM__c = 1;
        it.standard_cost__c = 0;
        it.transaction_date__c = system.now().addDays(-2);
        it.type__c = 'Purchase Order Receipt';
        it.to_location__c = loc.Id;
        it.inventory_change__c = ic.Id;
        it.Subtransaction_Type__c = 'Purchase Order Receipt';
        it.Company__c = thisCompany.Id;
        invTrxns.add(it); 
         
        Inventory_Transaction__c it1 = new Inventory_Transaction__c();
        it1.item__c = item1.Id;
        it1.quantity__c = 1;
        it1.Quantity_Stocking_UOM__c = 1;
        it1.standard_cost__c = 0;
        it1.transaction_date__c = system.now();
        it1.type__c = 'Purchase Order Receipt';
        it1.to_location__c = loc.Id;
        it1.inventory_change__c = ic1.Id;
        it1.Subtransaction_Type__c = 'Purchase Order Receipt';
        it1.Company__c = thisCompany.Id;
        invTrxns.add(it1); 

        insert invTrxns;
        
        ic.finalized__c = true;
        ic1.finalized__c = true; 
        update invChanges;
	 	Test.startTest();

        list<Accounting_Rule__c> icnvacctRuleList = new list<Accounting_Rule__c>();
        Accounting_Rule__c icnvacctRuleDR = new Accounting_Rule__c();
        icnvacctRuleDR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleDR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleDR.Line_Type__c  = null;
        icnvacctRuleDR.Rule_Type__c = 'DR';
        icnvacctRuleDR.Default_GL_Account__c = true;
        icnvacctRuleDR.GL_Account_Reference_Value__c = null;
        icnvacctRuleDR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDR.Company_Ledger__c = true;           
        icnvacctRuleDR.Effective_Start_Date__c= system.now().addDays(-3);
       	icnvacctRuleDR.Accounting_Standard__c = acctStd.Id;
       	icnvacctRuleDR.Raise_Exceptions_for_Blank_Amounts__c = true;
        icnvacctRuleList.add(icnvacctRuleDR);
        
        Accounting_Rule__c icnvacctRuleCR = new Accounting_Rule__c();
        icnvacctRuleCR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleCR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleCR.Line_Type__c  = null;
        icnvacctRuleCR.Rule_Type__c = 'CR';
        icnvacctRuleCR.Default_GL_Account__c = true;
        icnvacctRuleCR.GL_Account_Reference_Value__c = null;
        icnvacctRuleCR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCR.Company_Ledger__c = true;           
        icnvacctRuleCR.Effective_Start_Date__c= system.now().addDays(-3);
       	icnvacctRuleCR.Accounting_Standard__c = acctStd.Id;
       	icnvacctRuleCR.Raise_Exceptions_for_Blank_Amounts__c = true;
        icnvacctRuleList.add(icnvacctRuleCR);
        
        insert icnvacctRuleList;
 		Database.executeBatch(new InventoryChangeAccountingBatch(new Set<Id>{thisCompany.Id}));
 		test.stopTest();
        List<Accounting_Entry__c> aes = [SELECT Id,has_exceptions__c,(select id from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic.id];
		system.assert(aes.size() == 1,'aes :'+aes); 
        //asserting exception on Accounting Entry for IC when Item cost was not active.
		system.assert(aes[0].has_exceptions__c == true,'aes :'+aes); 
 		list<task> tasklist = [Select subject,description from task where whatid in: aes[0].accounting_entry_lines__r and subject = 'Missing Item Cost']; 
        system.assert(tasklist[0].subject.contains('Missing Item Cost'),'tasklist : '+tasklist );
        
        List<Accounting_Entry__c> aes1 = [SELECT Id,has_exceptions__c FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic1.id];
		system.assert(aes1.size() == 1,'aes1 :'+aes1); 
        //asserting no exception on Accounting Entry for IC when Item cost was active.
		system.assert(aes1[0].has_exceptions__c == false,'aes1 :'+aes1); 
         
     }
 public static testMethod void testBatch_MultiCurrCostAccounting() {
 		Company__c thisCompany = [SELECT ID, Name FROM Company__c LIMIT 1];
        item__c item1 = [SELECT ID, Name FROM item__c LIMIT 1];
        location__c loc = [SELECT ID, Name FROM location__c LIMIT 1];
        gl_account__c GRNIGL = [SELECT ID, Name FROM gl_account__c LIMIT 1];
        Accounting_Standard__c acctStd = [SELECT ID, Name FROM Accounting_Standard__c LIMIT 1];
        Currency__c c = [Select id, Name, ISO_Code__c from Currency__c where ISO_Code__c = 'USD'];
        Datetime currentDatetime = system.now();
        Datetime futureDatetime_2 = currentDatetime.addDays(2);
        Datetime pastDatetime_3 = currentDatetime.addDays(-3);
        Datetime pastDatetime_2 = currentDatetime.addDays(-2);
        Datetime pastDatetime_1 = currentDatetime.addDays(-1);
        Datetime pastDatetime_lastmonth = currentDatetime.addmonths(-1);
        
        //Map<String,Currency__c> mCurr = new map<String,Currency__c>([Select ISO_Code__c, id from Currency__c]) ; 
		//system.debug(logginglevel.info,'mCurr'+mCurr);
		
		//system.assert(mCurr.size() == 4,'mCurr :'+mCurr);
		list<Exchange_Rate__c> ExchangeRateList = new list<Exchange_Rate__c>();
        Exchange_Rate__c exchangeRate1= new Exchange_Rate__c();
        exchangeRate1.Active__c = true;
        exchangeRate1.From_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate1.To_Currency__c = c.id;
        exchangeRate1.Daily_Monthly__c = 'Daily';
        exchangeRate1.Multiplier_Exchange_Rate__c = 1.250000;
        exchangeRate1.rate_start_datetime__c = pastDatetime_2;
        exchangeRate1.rate_end_datetime__c = currentDatetime.addMinutes(60);
        ExchangeRateList.add(exchangeRate1);
        
        Exchange_Rate__c exchangeRate4= new Exchange_Rate__c();
        exchangeRate4.Active__c = true;
        exchangeRate4.From_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate4.To_Currency__c = c.id;
        exchangeRate4.Daily_Monthly__c = 'Daily';
        exchangeRate4.Multiplier_Exchange_Rate__c = 1.250000;
        exchangeRate4.rate_start_datetime__c = pastDatetime_3;
        exchangeRate4.rate_end_datetime__c = pastDatetime_2;
        ExchangeRateList.add(exchangeRate4);
        
        Exchange_Rate__c exchangeRate5= new Exchange_Rate__c();
        exchangeRate5.Active__c = true;
        exchangeRate5.From_Currency__c = c.id;
        exchangeRate5.To_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate5.Daily_Monthly__c = 'Daily';
        exchangeRate5.Multiplier_Exchange_Rate__c = 1.250000;
        exchangeRate5.rate_start_datetime__c = pastDatetime_2;
        exchangeRate5.rate_end_datetime__c = currentDatetime.addMinutes(60);
        ExchangeRateList.add(exchangeRate5);
        
        Exchange_Rate__c exchangeRate6= new Exchange_Rate__c();
        exchangeRate6.Active__c = true;
        exchangeRate6.From_Currency__c = c.id;
        exchangeRate6.To_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate6.Daily_Monthly__c = 'Daily';
        exchangeRate6.Multiplier_Exchange_Rate__c = 1.250000;
        exchangeRate6.rate_start_datetime__c = pastDatetime_3;
        exchangeRate6.rate_end_datetime__c = pastDatetime_2;
        ExchangeRateList.add(exchangeRate6);

        Exchange_Rate__c exchangeRate2= new Exchange_Rate__c();
        exchangeRate2.Active__c = true;
        exchangeRate2.From_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate2.To_Currency__c = c.id;
        exchangeRate2.Daily_Monthly__c = 'Daily';
        exchangeRate2.Multiplier_Exchange_Rate__c = 100;
        exchangeRate2.rate_start_datetime__c = pastDatetime_2;
        exchangeRate2.rate_end_datetime__c = currentDatetime.addMinutes(60);
        ExchangeRateList.add(exchangeRate2);
        
        Exchange_Rate__c exchangeRate3= new Exchange_Rate__c();
        exchangeRate3.Active__c = true;
        exchangeRate3.From_Currency__c = c.id;
        exchangeRate3.To_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate3.Daily_Monthly__c = 'Daily';
        exchangeRate3.Multiplier_Exchange_Rate__c = 10;
        exchangeRate3.rate_start_datetime__c = pastDatetime_3;
        exchangeRate3.rate_end_datetime__c = pastDatetime_2;
        ExchangeRateList.add(exchangeRate3);
               
        Exchange_Rate__c exchangeRate2A= new Exchange_Rate__c();
        exchangeRate2A.Active__c = true;
        exchangeRate2A.From_Currency__c = c.id;
        exchangeRate2A.To_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate2A.Daily_Monthly__c = 'Daily';
        exchangeRate2A.Multiplier_Exchange_Rate__c = 100;
        exchangeRate2A.rate_start_datetime__c = pastDatetime_2;
        exchangeRate2A.rate_end_datetime__c = currentDatetime.addMinutes(60);
        ExchangeRateList.add(exchangeRate2A);
        
        Exchange_Rate__c exchangeRate3A= new Exchange_Rate__c();
        exchangeRate3A.Active__c = true;
        exchangeRate3A.From_Currency__c = Testfuel.currencyEUR.id;
        exchangeRate3A.To_Currency__c = c.id;
        exchangeRate3A.Daily_Monthly__c = 'Daily';
        exchangeRate3A.Multiplier_Exchange_Rate__c = 10;
        exchangeRate3A.rate_start_datetime__c = pastDatetime_3;
        exchangeRate3A.rate_end_datetime__c = pastDatetime_2;
        ExchangeRateList.add(exchangeRate3A);
        
     	insert ExchangeRateList;
     
        List<Period__c> periodList = [SELECT ID, Name, open__c FROM Period__c];
        item_cost__C itemcostTemp = [SELECT ID, Name,start_Date__c FROM item_cost__C LIMIT 1];
        item_cost__C itemcost1 = itemcostTemp.clone(false,true,false,false);
        itemcost1.status__c = 'Proposed' ; 
        itemcost1.Item__c = item1.id;
        itemcost1.Company__c = thisCompany.id;
        itemcost1.start_Date__c = pastDatetime_2;
        insert itemcost1;
         
        ItemService.allowItemCostUpdate = true;
        itemcost1.status__c = 'Approved' ; 
        itemcost1.Date_Approved__c = pastDatetime_lastmonth;
        itemcost1.On_hand_Revaluation__c = true; 
        update itemcost1;
                
		List<Inventory_Change__c> invChanges = new List<Inventory_Change__c>();
 		List<Inventory_Transaction__c> invTrxns = new List<Inventory_Transaction__c>();
        Inventory_Change__c ic = new Inventory_Change__c();
        ic.company__c = thisCompany.id;
        ic.item__c = item1.id;
        ic.currency__c = Testfuel.currencyEUR.id;
        ic.type__c = 'Purchase Order Receipt';
        ic.count_quantity__c = 1;
        ic.transaction_date__c = currentDatetime.addminutes(-30);
        invChanges.add(ic); 
         
        Inventory_Change__c ic1 = new Inventory_Change__c();
        ic1.company__c = thisCompany.id;
        ic1.item__c = item1.id;
        ic1.currency__c = Testfuel.currencyEUR.id;
        ic1.type__c = 'Purchase Order Receipt';
        ic1.count_quantity__c = 1;
        ic1.transaction_date__c = pastDatetime_2;
        invChanges.add(ic1);
       
        Inventory_Change__c ic2 = new Inventory_Change__c();
        ic2.company__c = thisCompany.id;
        ic2.item__c = item1.id;
        ic2.currency__c = Testfuel.currencyEUR.id;
        ic2.type__c = 'Purchase Order Receipt';
        ic2.count_quantity__c = 1;
        ic2.transaction_date__c = futureDatetime_2;
        invChanges.add(ic2);
         
        Inventory_Change__c ic3 = new Inventory_Change__c();
        ic3.company__c = thisCompany.id;
        ic3.item__c = item1.id;
        ic3.currency__c = Testfuel.currencyEUR.id;
        ic3.type__c = 'Purchase Order Receipt';
        ic3.count_quantity__c = 1;
        ic3.transaction_date__c = pastDatetime_3;
        invChanges.add(ic3);
  
        Inventory_Change__c ic4 = new Inventory_Change__c();
        ic4.company__c = thisCompany.id;
        ic4.item__c = item1.id;
        ic4.currency__c = Testfuel.currencyEUR.id;
        ic4.type__c = 'Work Order Complete';
        ic4.count_quantity__c = 1;
        ic4.transaction_date__c = currentDatetime.addminutes(-30);
        invChanges.add(ic4); 

        Inventory_Change__c ic5 = new Inventory_Change__c();
        ic5.company__c = thisCompany.id;
        ic5.item__c = item1.id;
        ic5.currency__c = c.id;
        ic5.type__c = 'Purchase Order Receipt';
        ic5.count_quantity__c = 1;
        ic5.transaction_date__c = currentDatetime.addminutes(-30);
        invChanges.add(ic5); 

        Inventory_Change__c ic6 = new Inventory_Change__c();
        ic6.company__c = thisCompany.id;
        ic6.item__c = item1.id;
        ic6.currency__c = Testfuel.currencyEUR.id;
        ic6.type__c = 'Purchase Order Receipt';
        ic6.count_quantity__c = 1;
        ic6.transaction_date__c = currentDatetime.adddays(-5);
        invChanges.add(ic6); 

        insert invChanges;
        
        Inventory_Transaction__c it = new Inventory_Transaction__c();
        it.item__c = item1.Id;
        it.quantity__c = 1;
        it.Quantity_Stocking_UOM__c = 1;
        it.standard_cost__c = 0;
        it.transaction_date__c = pastDatetime_3;
        it.type__c = 'Purchase Order Receipt';
        it.to_location__c = loc.Id;
        it.inventory_change__c = ic.Id;
        it.Subtransaction_Type__c = 'Purchase Order Receipt';
        it.Company__c = thisCompany.Id;
        invTrxns.add(it); 
         
        Inventory_Transaction__c it1 = new Inventory_Transaction__c();
        it1.item__c = item1.Id;
        it1.quantity__c = 1;
        it1.Quantity_Stocking_UOM__c = 1;
        it1.standard_cost__c = 0;
        it1.transaction_date__c = currentDatetime.addminutes(-30);
        it1.type__c = 'Purchase Order Receipt';
        it1.to_location__c = loc.Id;
        it1.inventory_change__c = ic1.Id;
        it1.Subtransaction_Type__c = 'Purchase Order Receipt';
        it1.Company__c = thisCompany.Id;
        invTrxns.add(it1); 

        Inventory_Transaction__c it2 = new Inventory_Transaction__c();
        it2.item__c = item1.Id;
        it2.quantity__c = 1;
        it2.Quantity_Stocking_UOM__c = 1;
        it2.standard_cost__c = 0;
        it2.transaction_date__c = futureDatetime_2;
        it2.type__c = 'Purchase Order Receipt';
        it2.to_location__c = loc.Id;
        it2.inventory_change__c = ic2.Id;
        it2.Subtransaction_Type__c = 'Purchase Order Receipt';
        it2.Company__c = thisCompany.Id;
        invTrxns.add(it2); 

        Inventory_Transaction__c it3 = new Inventory_Transaction__c();
        it3.item__c = item1.Id;
        it3.quantity__c = 1;
        it3.Quantity_Stocking_UOM__c = 1;
        it3.standard_cost__c = 0;
        it3.transaction_date__c = pastDatetime_3;
        it3.type__c = 'Purchase Order Receipt';
        it3.to_location__c = loc.Id;
        it3.inventory_change__c = ic3.Id;
        it3.Subtransaction_Type__c = 'Purchase Order Receipt';
        it3.Company__c = thisCompany.Id;
        invTrxns.add(it3); 
 
        Inventory_Transaction__c it4 = new Inventory_Transaction__c();
        it4.item__c = item1.Id;
        it4.quantity__c = 1;
        it4.Quantity_Stocking_UOM__c = 1;
        it4.standard_cost__c = 0;
        it4.transaction_date__c = currentDatetime.addminutes(-30);
        it4.type__c = 'Work Order Assembly Completion';
        it4.to_location__c = loc.Id;
        it4.inventory_change__c = ic4.Id;
        it4.Subtransaction_Type__c = 'Work Order Assembly Completion';
        it4.Company__c = thisCompany.Id;
        invTrxns.add(it4); 
         
        Inventory_Transaction__c it5 = new Inventory_Transaction__c();
        it5.item__c = item1.Id;
        it5.quantity__c = 1;
        it5.Quantity_Stocking_UOM__c = 1;
        it5.standard_cost__c = 0;
        it5.transaction_date__c = currentDatetime.addminutes(-30);
        it5.type__c = 'Purchase Order Receipt';
        it5.to_location__c = loc.Id;
        it5.inventory_change__c = ic5.Id;
        it5.Subtransaction_Type__c = 'Purchase Order Receipt';
        it5.Company__c = thisCompany.Id;
        invTrxns.add(it5); 
         
        Inventory_Transaction__c it6 = new Inventory_Transaction__c();
        it6.item__c = item1.Id;
        it6.quantity__c = 1;
        it6.Quantity_Stocking_UOM__c = 1;
        it6.standard_cost__c = 0;
        it6.transaction_date__c = currentDatetime.adddays(-5);
        it6.type__c = 'Purchase Order Receipt';
        it6.to_location__c = loc.Id;
        it6.inventory_change__c = ic6.Id;
        it6.Subtransaction_Type__c = 'Purchase Order Receipt';
        it6.Company__c = thisCompany.Id;
        invTrxns.add(it6); 

        insert invTrxns;
        
        ic.finalized__c = true;
        ic1.finalized__c = true; 
        ic2.finalized__c = true; 
        ic3.finalized__c = true; 
        ic4.finalized__c = true; 
        ic5.finalized__c = true; 
        ic6.finalized__c = true; 

        update invChanges;
	 	Test.startTest();

        list<Accounting_Rule__c> icnvacctRuleList = new list<Accounting_Rule__c>();
        Accounting_Rule__c icnvacctRuleDR = new Accounting_Rule__c();
        icnvacctRuleDR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleDR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleDR.Line_Type__c  = null;
        icnvacctRuleDR.Rule_Type__c = 'DR';
        icnvacctRuleDR.Default_GL_Account__c = true;
        icnvacctRuleDR.GL_Account_Reference_Value__c = null;
        icnvacctRuleDR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDR.Company_Ledger__c = true;           
        icnvacctRuleDR.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDR.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDR);
        
        Accounting_Rule__c icnvacctRuleCR = new Accounting_Rule__c();
        icnvacctRuleCR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleCR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleCR.Line_Type__c  = null;
        icnvacctRuleCR.Rule_Type__c = 'CR';
        icnvacctRuleCR.Default_GL_Account__c = true;
        icnvacctRuleCR.GL_Account_Reference_Value__c = null;
        icnvacctRuleCR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCR.Company_Ledger__c = true;           
        icnvacctRuleCR.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCR.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCR);
        
        Accounting_Rule__c icnvacctRuleDRA = new Accounting_Rule__c();
        icnvacctRuleDRA.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDRA.Transaction__c = 'Work Order Complete';
        icnvacctRuleDRA.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleDRA.Rule_Type__c = 'DR';
        icnvacctRuleDRA.Default_GL_Account__c = true;
        icnvacctRuleDRA.GL_Account_Reference_Value__c = null;
        icnvacctRuleDRA.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDRA.Company_Ledger__c = true;           
        icnvacctRuleDRA.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDRA.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDRA);
        
        Accounting_Rule__c icnvacctRuleCRA = new Accounting_Rule__c();
        icnvacctRuleCRA.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCRA.Transaction__c = 'Work Order Complete';
        icnvacctRuleCRA.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleCRA.Rule_Type__c = 'CR';
        icnvacctRuleCRA.Default_GL_Account__c = true;
        icnvacctRuleCRA.GL_Account_Reference_Value__c = null;
        icnvacctRuleCRA.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCRA.Company_Ledger__c = true;           
        icnvacctRuleCRA.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCRA.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCRA);
        
        Accounting_Rule__c icnvacctRuleDRB = new Accounting_Rule__c();
        icnvacctRuleDRB.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDRB.Transaction__c = 'Work Order Complete';
        icnvacctRuleDRB.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleDRB.Line_Type__c  = 'Material Cost';
        icnvacctRuleDRB.Rule_Type__c = 'DR';
        icnvacctRuleDRB.Default_GL_Account__c = true;
        icnvacctRuleDRB.GL_Account_Reference_Value__c = null;
        icnvacctRuleDRB.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDRB.Company_Ledger__c = true;           
        icnvacctRuleDRB.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDRB.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDRB);
        
        Accounting_Rule__c icnvacctRuleCRB = new Accounting_Rule__c();
        icnvacctRuleCRB.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCRB.Transaction__c = 'Work Order Complete';
        icnvacctRuleCRB.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleCRB.Line_Type__c  = 'Material Cost';
        icnvacctRuleCRB.Rule_Type__c = 'CR';
        icnvacctRuleCRB.Default_GL_Account__c = true;
        icnvacctRuleCRB.GL_Account_Reference_Value__c = null;
        icnvacctRuleCRB.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCRB.Company_Ledger__c = true;           
        icnvacctRuleCRB.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCRB.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCRB);
        
        Accounting_Rule__c icnvacctRuleDRC = new Accounting_Rule__c();
        icnvacctRuleDRC.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDRC.Transaction__c = 'Work Order Complete';
        icnvacctRuleDRC.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleDRC.Line_Type__c  = 'Labor Cost';
        icnvacctRuleDRC.Rule_Type__c = 'DR';
        icnvacctRuleDRC.Default_GL_Account__c = true;
        icnvacctRuleDRC.GL_Account_Reference_Value__c = null;
        icnvacctRuleDRC.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDRC.Company_Ledger__c = true;           
        icnvacctRuleDRC.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDRC.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDRC);
        
        Accounting_Rule__c icnvacctRuleCRC = new Accounting_Rule__c();
        icnvacctRuleCRC.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCRC.Transaction__c = 'Work Order Complete';
        icnvacctRuleCRC.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleCRC.Line_Type__c  = 'Labor Cost';
        icnvacctRuleCRC.Rule_Type__c = 'CR';
        icnvacctRuleCRC.Default_GL_Account__c = true;
        icnvacctRuleCRC.GL_Account_Reference_Value__c = null;
        icnvacctRuleCRC.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCRC.Company_Ledger__c = true;           
        icnvacctRuleCRC.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCRC.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCRC);
        
        Accounting_Rule__c icnvacctRuleDRD = new Accounting_Rule__c();
        icnvacctRuleDRD.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDRD.Transaction__c = 'Work Order Complete';
        icnvacctRuleDRD.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleDRD.Line_Type__c  = 'Outside Processing Cost';
        icnvacctRuleDRD.Rule_Type__c = 'DR';
        icnvacctRuleDRD.Default_GL_Account__c = true;
        icnvacctRuleDRD.GL_Account_Reference_Value__c = null;
        icnvacctRuleDRD.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDRD.Company_Ledger__c = true;           
        icnvacctRuleDRD.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDRD.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDRD);
        
        Accounting_Rule__c icnvacctRuleCRD = new Accounting_Rule__c();
        icnvacctRuleCRD.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCRD.Transaction__c = 'Work Order Complete';
        icnvacctRuleCRD.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleCRD.Line_Type__c  = 'Outside Processing Cost';
        icnvacctRuleCRD.Rule_Type__c = 'CR';
        icnvacctRuleCRD.Default_GL_Account__c = true;
        icnvacctRuleCRD.GL_Account_Reference_Value__c = null;
        icnvacctRuleCRD.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCRD.Company_Ledger__c = true;           
        icnvacctRuleCRD.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCRD.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCRD);
        
         Accounting_Rule__c icnvacctRuleDRE = new Accounting_Rule__c();
        icnvacctRuleDRE.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDRE.Transaction__c = 'Work Order Complete';
        icnvacctRuleDRE.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleDRE.Line_Type__c  = 'Manufacturing Overhead Cost';
        icnvacctRuleDRE.Rule_Type__c = 'DR';
        icnvacctRuleDRE.Default_GL_Account__c = true;
        icnvacctRuleDRE.GL_Account_Reference_Value__c = null;
        icnvacctRuleDRE.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDRE.Company_Ledger__c = true;           
        icnvacctRuleDRE.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDRE.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDRE);
        
        Accounting_Rule__c icnvacctRuleCRE = new Accounting_Rule__c();
        icnvacctRuleCRE.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCRE.Transaction__c = 'Work Order Complete';
        icnvacctRuleCRE.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleCRE.Line_Type__c  = 'Manufacturing Overhead Cost';
        icnvacctRuleCRE.Rule_Type__c = 'CR';
        icnvacctRuleCRE.Default_GL_Account__c = true;
        icnvacctRuleCRE.GL_Account_Reference_Value__c = null;
        icnvacctRuleCRE.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCRE.Company_Ledger__c = true;           
        icnvacctRuleCRE.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCRE.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCRE);
        
        Accounting_Rule__c icnvacctRuleDRF = new Accounting_Rule__c();
        icnvacctRuleDRF.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDRF.Transaction__c = 'Work Order Complete';
        icnvacctRuleDRF.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleDRF.Line_Type__c  = 'Increase';
        icnvacctRuleDRF.Rule_Type__c = 'DR';
        icnvacctRuleDRF.Default_GL_Account__c = true;
        icnvacctRuleDRF.GL_Account_Reference_Value__c = null;
        icnvacctRuleDRF.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDRF.Company_Ledger__c = true;           
        icnvacctRuleDRF.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleDRF.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDRF);
        
        Accounting_Rule__c icnvacctRuleCRF = new Accounting_Rule__c();
        icnvacctRuleCRF.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCRF.Transaction__c = 'Work Order Complete';
        icnvacctRuleCRF.SubTransaction_Type__c = 'Work Order Assembly Completion';
        icnvacctRuleCRF.Line_Type__c  = 'Increase';
        icnvacctRuleCRF.Rule_Type__c = 'CR';
        icnvacctRuleCRF.Default_GL_Account__c = true;
        icnvacctRuleCRF.GL_Account_Reference_Value__c = null;
        icnvacctRuleCRF.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCRF.Company_Ledger__c = true;           
        icnvacctRuleCRF.Effective_Start_Date__c= pastDatetime_lastmonth;
       	icnvacctRuleCRF.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleCRF);
        
        insert icnvacctRuleList;
 		Database.executeBatch(new InventoryChangeAccountingBatch(new Set<Id>{thisCompany.Id}));
 		test.stopTest();
        
        //Asserting when transaction dates fall in different exchange rate start date and end date ic and ic1
        List<Accounting_Entry__c> aes = [SELECT Id,has_exceptions__c, transaction_type__c,(select id,item_cost_missing__c, subtransaction_type__c, line_type__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic.id];
		system.assert(aes.size() == 1,'aes :'+aes); 
		list<task> tasks= [select subject,description from task where whatid in :aes[0].accounting_entry_lines__r];
        system.assert(aes[0].has_exceptions__c == false,'aes :'+aes + ' Tasks : ' +tasks + '  aesLines :  ' + aes[0].accounting_entry_lines__r + ' Item cost : ' + itemcost1 + ' it : ' + it); 
        
        List<Accounting_Entry__c> aes1 = [SELECT Id,has_exceptions__c,(select id,item_cost_missing__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic1.id];
		system.assert(aes1.size() == 1,'aes1 :'+aes1); 
		system.assert(aes[0].has_exceptions__c == false,'aes :'+aes); 
         
         //Asserting when transaction dates fall when no exchange rate is available
        List<Accounting_Entry__c> aes2 = [SELECT Id,has_exceptions__c,(select id,item_cost_missing__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic2.id];
		system.assert(aes2.size() == 1,'aes2 :'+aes2); 
		list<task> tasks1= [select subject,description from task where whatid in :aes2[0].accounting_entry_lines__r];
		system.assert(aes2[0].has_exceptions__c == true,'aes2 : ' + aes2); 
		system.assert(tasks1[0].subject == 'Missing Functional Conversion Rate' , 'tasks1: ' + tasks1); 
		system.assert(tasks1[1].subject == 'Exchange Service Error' ); 

         //Asserting when transaction dates fall when no item cost is available
        List<Accounting_Entry__c> aes3 = [SELECT Id,has_exceptions__c,(select id,item_cost_missing__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic3.id];
		system.assert(aes2.size() == 1,'aes3 :'+aes3); 
		list<task> tasks2= [select subject,description from task where whatid in :aes3[0].accounting_entry_lines__r];
		system.assert(aes3[0].has_exceptions__c == true,'tasks2 : ' + tasks2); 
		system.assert(tasks2[0].subject == 'Missing Item Cost' , 'tasks2: ' + tasks2); 

         //Asserting when transaction type is Work Order Complete 
        List<Accounting_Entry__c> aes4 = [SELECT Id,has_exceptions__c, transaction_type__c,(select id,item_cost_missing__c, subtransaction_type__c, line_type__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic4.id];
		system.assert(aes4.size() == 1,'aes4 :'+aes4); 
        system.assert(aes4[0].has_exceptions__c == false,'aes4 :'+aes4 ); 
        
         //Asserting currency is same as company currency 
        List<Accounting_Entry__c> aes5 = [SELECT Id,has_exceptions__c, transaction_type__c,(select id,item_cost_missing__c, subtransaction_type__c, line_type__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic5.id];
		system.assert(aes5.size() == 1,'aes5 :'+aes5); 
        system.assert(aes5[0].has_exceptions__c == false,'aes5 :'+aes5); 
       
        List<Accounting_Entry__c> aes6 = [SELECT Id,has_exceptions__c, transaction_type__c,(select id,item_cost_missing__c, subtransaction_type__c, line_type__c, error_message__c from accounting_entry_lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c =:ic6.id];
		system.assert(aes6.size() == 1,'aes6 :'+aes6); 
        system.assert(aes6[0].has_exceptions__c == true,'aes6 :'+aes6); 
     }
}