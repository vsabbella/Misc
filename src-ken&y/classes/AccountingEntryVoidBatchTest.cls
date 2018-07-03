@isTest
private class AccountingEntryVoidBatchTest {
	@testSetup static void TestData() {
         Testfuel data = new Testfuel();
         Accounting_Entry_Line__c acctEntryLineCR, acctEntryLineDR, acctEntryLineCR1, acctEntryLineDR1;
         system.assert(data.periodList.size() >0);
      	 GL_Account__c cashGL = data.cashGL;
        Period__c refPeriod = [SELECT Id, period_start__c, period_end__c FROM Period__c WHERE company__c = :data.company.Id AND period_start__c <= :system.now() AND period_end__c > :system.now()];
         
         List<Journal_Entry_Line__c> jeLineList;
		 List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();{
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = data.company.id;	
		    je1.type__c = 'Manual';   
		    je1.Transaction_Type__c = 'Manual';
		    je1.Transaction_Date__c = System.now();  
		    //je1.GL_Date__c = System.today();  
			je1.Currency__c = TestFuel.currencyUSD.id;
			//je1.Finalized__c = true;		
		    JEList.add(je1);
		    
		    Journal_Entry__c je2 = new Journal_Entry__c();
			je2.name = 'JE002';
		    je2.Company__c = data.company.id;	
		    je2.type__c = 'Accrual - Manual';   
		    je2.Transaction_Type__c = 'Manual';
		    je2.Transaction_Date__c = System.now();  
		    //je2.GL_Date__c = System.today();  
			je2.Currency__c = TestFuel.currencyUSD.id;
			//je2.Finalized__c = true;		
		    JEList.add(je2);
		    
		    insert JEList;    
		 }
		 jeLineList = new List<Journal_Entry_Line__c>();{
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = cashGL.id;
			jeLine1.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = cashGL.id;
			jeLine2.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine2); 
		    
		    
		    Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
		    jeLine3.Journal_Entry__c = JEList[1].id;
			jeLine3.Amount_CR__c = 5;
			jeLine3.Amount_DR__c = 0;
			jeLine3.GL_Account__c = cashGL.id;
			jeLine3.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine3); 
		    
		    Journal_Entry_Line__c jeLine4 = new Journal_Entry_Line__c(); 
		    jeLine4.Journal_Entry__c = JEList[1].id;
			jeLine4.Amount_CR__c = 0;
			jeLine4.Amount_DR__c = 5;
			jeLine4.GL_Account__c = cashGL.id;
			jeLine4.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine4); 
		    
		    insert jeLineList;
		 }   
        Accounting_Entry__c acctEntry = new Accounting_Entry__c();{
            acctEntry.company__c = data.company.id; 
            acctEntry.Transaction_Type__c = 'Manual';
            acctEntry.Source_Document_Object_Name__c = 'Manual';
            acctEntry.Transaction_Date__c = refPeriod.period_start__c.addDays(1);
            acctEntry.Finalized_Date__c = refPeriod.period_start__c.addDays(1);
            acctEntry.status__c = 'Active';
            acctEntry.Currency__c = TestFuel.currencyUSD.id;
       
        }   
       	Accounting_Entry__c acctEntry1 = new Accounting_Entry__c();{
            acctEntry1.company__c = data.company.id; 
            acctEntry1.Transaction_Type__c = 'Manual';
            acctEntry1.Source_Document_Object_Name__c = 'Manual';
            acctEntry1.Transaction_Date__c = refPeriod.period_start__c.addDays(1);
            acctEntry1.Finalized_Date__c = refPeriod.period_start__c.addDays(1);
            acctEntry.status__c = 'Active';
            acctEntry1.Currency__c = TestFuel.currencyUSD.id;
            
            insert acctEntry;
            insert acctEntry1; 
                  
            boolean sawexception = false; 
            String errorMsg = '';           
           
                        
            System.assertEquals(false, acctEntry.Void__c);
            System.assertEquals(false, acctEntry.Has_Exceptions__c);
            System.assertEquals(null, acctEntry.Related_Accounting_Entry__c );
            
            System.assertEquals(false, acctEntry1.Void__c);
            System.assertEquals(false, acctEntry1.Has_Exceptions__c);
            System.assertEquals(null, acctEntry1.Related_Accounting_Entry__c );
        
        }       
        List<Accounting_Entry_Line__c> acctEntryLineList = new List<Accounting_Entry_Line__c>();{ 
        	List<Accounting_Entry__c> aeList = new List<Accounting_Entry__c>();
        	aeList.add(acctEntry);
        	aeList.add(acctEntry1);
        	
        	update aeList;
        	        	
            acctEntryLineCR = new Accounting_Entry_Line__c();
            acctEntryLineCR.Amount_CR__c = 125;
            acctEntryLineCR.GL_Account__c = data.cashGL.id; 
            acctEntryLineCR.Transaction_Date__c = system.today();
            acctEntryLineCR.Accounting_Entry__c = acctEntry.id;
            acctEntryLineList.add(acctEntryLineCR);
            acctEntryLineDR = new Accounting_Entry_Line__c();
            acctEntryLineDR.Amount_DR__c = 125;
            acctEntryLineDR.GL_Account__c = data.cashGL.id;
            acctEntryLineDR.Transaction_Date__c = system.today();
            acctEntryLineDR.Accounting_Entry__c = acctEntry.id;   
            acctEntryLineList.add(acctEntryLineDR);
            
            
            acctEntryLineCR1 = new Accounting_Entry_Line__c();
            acctEntryLineCR1.Amount_CR__c = 125;
            acctEntryLineCR1.GL_Account__c = data.cashGL.id; 
            acctEntryLineCR1.Transaction_Date__c = system.today();
            acctEntryLineCR1.Accounting_Entry__c = acctEntry1.id;
            acctEntryLineList.add(acctEntryLineCR1);
            acctEntryLineDR1 = new Accounting_Entry_Line__c();
            acctEntryLineDR1.Amount_DR__c = 125;
            acctEntryLineDR1.GL_Account__c = data.cashGL.id;
            acctEntryLineDR1.Transaction_Date__c = system.today();
            acctEntryLineDR1.Accounting_Entry__c = acctEntry1.id;   
            acctEntryLineList.add(acctEntryLineDR1);
            
            
            System.assert(!acctEntryLineList.isEmpty());
        
            insert acctEntryLineList;
            
            update aeList;
 			test.startTest();
			    Customer_Invoice__c custInv1 = new Customer_Invoice__c();
			    custInv1.Company__c = data.company.id;
			    custInv1.Invoice_Type__c = 'Ship Invoice';
			    custInv1.Date_Invoiced__c = System.today();
			    custInv1.Sold_To_Customer__c = data.customerSoldTo.id;
			    custInv1.Bill_To_Customer__c = data.customerbillto.id;
			    custInv1.Subtotal__c = 0;
			    custInv1.Sales_Order__c = data.salesOrder.id;
			    custInv1.transaction_date__c = system.now();
			    custInv1.Currency__c = TestFuel.currencyUSD.id;
				    
				insert custInv1;    
			    Customer_Invoice_Line__c custInvLine11 = new Customer_Invoice_Line__c();
			    custInvLine11.Company__c = data.company.id;
			    custInvLine11.Quantity_Shipped__c = 2;
			    custInvLine11.Unit_Price__c = 7;
			    custInvLine11.SubTransaction_Type__c = 'Goods';
			    custInvLine11.Product__c = data.product.id ; 
			    custInvLine11.Discount_Percent__c = 0.2;
			    custInvLine11.Customer_Invoice__c = custInv1.id;
			    custInvLine11.Extended_Price__c = custInvLine11.Quantity_Shipped__c * custInvLine11.Unit_Price__c;
				insert custInvLine11;
				custInv1.finalized__c = true;
				update custInv1; 
				system.assert(data.ciAccountingRuleList != null);
			    CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
			    cia.execute(new list<Customer_Invoice_Line__c>{custInvLine11});
			    List<Accounting_Entry__c> acctEntries = [SELECT id, Name, Customer_Invoice__c, COMP_Total_Credit__c, COMP_Total_Debit__c, Transaction_Type__c, Customer__c,has_exceptions__c,
			    										(SELECT id, Name, accounting_rule__c, Subtransaction_Type__c, Line_Type__c FROM Accounting_Entry_Lines__r)
			                                            FROM Accounting_Entry__c 
			                                            WHERE (Customer_Invoice__c = :custInv1.id)];
				system.assert(acctEntries[0].has_exceptions__c != true,'No Exceptions should be found - ' + acctEntries[0]);		          
 			test.stopTest();
         }
          
	}
    static testMethod void AccountingEntryVoidBatchValidate() {
        //TestDataForFinance data = new TestDataForFinance();
        List<Journal_Entry__c> JEList = [select name,Company__c,type__c,Transaction_Date__c,Transaction_Type__c from Journal_Entry__c where type__c = 'Accrual - Manual' OR type__c = 'Manual'];
        List<Accounting_Entry__c> AElist = [select name,Company__c,Source_Document_Object_Name__c,Transaction_Type__c,Finalized_Date__c,status__c,currency__c from Accounting_Entry__c where Transaction_Type__c = 'Manual'];
        test.startTest();
         /*new GL_Account__c();{
         	GL_Type__c currentAssets = new GL_Type__c();
			currentAssets.Name  = 'Current Assets';
    		currentAssets.Normal_Balance__c  = 'Debit';
    		currentAssets.Accounting_Type__c  = 'Assets';
    		currentAssets.Statement_Type__c  = 'Balance Sheet';
    		currentAssets.Account_Range_From__c = '10000';
    		currentAssets.Account_Range_To__c ='19999';
			insert  currentAssets;
			   		
            cashGL.Name = '12345 - Cash';
            cashGL.GL_Account_Number__c = '12345';
            cashGL.GL_Account_Name__c = 'Cash';
            cashGL.active__c = true;
            cashGL.Report_Section__c = 'Current Assets';  
            cashGL.Normal_Balance__c = 'Debit';
            cashGL.Statement_Type__c = 'Balance Sheet';
            cashGL.Report_Section_Grouping__c = 'Assets';
            cashGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
            cashGL.non_cash__c = true;
            cashGL.GL_type__c = currentAssets.id;
            
            insert cashGL;
         }*/
 
            
            JEList[0].void__c = true;
            JEList[1].auto_reverse__c = true;
            update JEList;
            AElist[0].Journal_Entry__c = JEList[0].id;
            List<Accounting_Entry__c> aeLst = new List<Accounting_Entry__c>();
        	aeLst.add(AElist[0]);
        	aeLst.add(AElist[1]);
            update aeLst;

        	set<id> aeidList = new set<id>();
        	aeidList.add(aeLst[0].id);
        	aeidList.add(aeLst[1].id);
        	
            AccountingEntryVoidBatch batch = new AccountingEntryVoidBatch(aeidList);
            database.executebatch(batch);
         test.stoptest();  

                        
                           
    }
    static testMethod void AccountingEntryVoidBatchValidateCI() {
        //TestDataForFinance data = new TestDataForFinance();
        List<Customer_Invoice__c> CIList = [select name,Company__c,Invoice_Type__c,Date_Invoiced__c,Sold_To_Customer__c,Bill_To_Customer__c,Subtotal__c,transaction_date__c,Sales_Order__c,Currency__c from Customer_Invoice__c where Invoice_Type__c = 'Ship Invoice'];
        List<Accounting_Entry__c> AElist = [select name,Company__c,Source_Document_Object_Name__c,Transaction_Type__c,Finalized_Date__c,status__c,currency__c from Accounting_Entry__c where Customer_Invoice__c =: CIList[0].id];
        test.startTest();            
            CIList[0].void__c = true;
  			FinalizeService.voidIds.add(CIList[0].id);        
            update CIList[0];

        	set<id> aeidList = new set<id>();
        	aeidList.add(AElist[0].id);
        	
            AccountingEntryVoidBatch batch = new AccountingEntryVoidBatch(aeidList);
            database.executebatch(batch);
         test.stoptest();  

                        
                           
    }

        

}