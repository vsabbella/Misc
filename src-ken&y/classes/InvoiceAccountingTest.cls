@isTest
private class InvoiceAccountingTest {

    public class SampleData{
        
        public testFuel data = new testFuel();
        public SampleData(){
            updateData();
        }
        
        
	    public List<Invoice_Line__c> InvLineList1 = new List<Invoice_Line__c>();
	    public List<Invoice_Line__c> InvLineList2 = new List<Invoice_Line__c>();
	    public List<Invoice__c> InvAEList = new List<Invoice__c>();
	    public Invoice__c Inv1, Inv2, Inv3;
        public Invoice_Line__c InvLine1, InvLine2, InvLine3, InvLine4, rilt1;
        
        private void updateData(){
            
           	Inv1 = new Invoice__c();
            Inv1.From_Company__c = data.company.id;
            Inv1.To_Company__c = data.altCompany.id;
            Inv1.Type__c = 'Intercompany Investment';
            Inv1.Currency__c = TestFuel.currencyUSD.id;
            Inv1.Transaction_Date__c = system.now();
            
            
           	Inv2 = new Invoice__c();
            Inv2.From_Company__c = data.company.id;
            Inv2.To_Company__c = data.altCompany.id;
            Inv2.Type__c = 'Intercompany Cross Charge';
            Inv2.Currency__c = TestFuel.currencyUSD.id;
            Inv2.Transaction_Date__c = system.now();
            
            
            InvAEList.add(Inv1);
            InvAEList.add(Inv2);
            
            insert InvAEList;
            
            Invoice_Line__c InvLine1 = new Invoice_Line__c(); 
            InvLine1.Invoice__c = Inv1.id;
            InvLine1.Extended_Amount__c = 5000;
            InvLineList1.add(InvLine1);
            
            Invoice_Line__c InvLine2 = new Invoice_Line__c(); 
            InvLine2.Invoice__c = Inv1.id;
            InvLine2.Extended_Amount__c = 10000;
            InvLineList1.add(InvLine2);
            
            Invoice_Line__c InvLine3 = new Invoice_Line__c(); 
            InvLine3.Invoice__c = Inv2.id;
            InvLine3.Extended_Amount__c = 5000;
            InvLineList1.add(InvLine3);
            
            Invoice_Line__c InvLine4 = new Invoice_Line__c(); 
            InvLine4.Invoice__c = Inv2.id;
            InvLine4.Extended_Amount__c = 10000;
            InvLineList1.add(InvLine4);
            insert InvLineList1;
            
            system.assert(data.periodList.size() >0);
            system.assert(data.altCompanyPeriodList.size() >0);
            system.assert(data.invoiceRuleList.size() >0);
            
            Inv1.finalized__c = true;
			Inv2.finalized__c = true;            
             
            update InvAEList;
        }
        
        
	    
    }   
    static testMethod void InvoiceAccountingTest() {
        SampleData sd = new SampleData();
        
 	    Test.startTest();
	    
	    sd.Inv1 = [Select id, Name, Finalized__c
	                                    from Invoice__c 
	                                    where id = :sd.Inv1.id];
	    system.assertEquals(true, sd.Inv1.Finalized__c);
	    	            
	    InvoiceAccounting ia = new InvoiceAccounting();
        list<invoice_line__c> silList = new list<invoice_line__c>();
        silList.addall(sd.InvLineList1);

	    ia.execute(silList);
	    
	    Set<Id> InvIds = new Set<Id>();
	    for(Invoice__c Inv: sd.InvAEList){
	        InvIds.add(Inv.id);
	    }
	    List<Accounting_Entry__c> acctEntry = [Select id, Name, Invoice__c,status__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Invoice__c in :InvIds) order by id];
	        
	    system.debug('acctEntry:'+acctEntry);
	    system.assertnotEquals(null,acctEntry);
	    system.assertEquals(4,acctEntry.size());
	    Integer listSize = acctEntry.size();
    }
}