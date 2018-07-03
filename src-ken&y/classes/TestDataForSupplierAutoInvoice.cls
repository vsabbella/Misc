@isTest
public class TestDataForSupplierAutoInvoice {

	public final Integer INT_POS = 100; //POs to create
	public final Integer INT_POLINES_PER_PO = 2; //Lines per PO to create
	public final Integer INT_TOTAL = (INT_POS * INT_POLINES_PER_PO); //total expected invoices to be created	
		
	public Company__c co;
	public Location__c loc;
	public Payment_Term__c terms;
	public Item__c purchasedItem;
	public List<Purchase_Order__c> poList;
	public Map<Id, Purchase_Order__c> poIdtoPoMap;
	public List<Purchase_Order_Line__c> polList;
	public Map<Id, Receiving_Document__c> PoIdRdMap;
	public List<Receipt_Line__c> rlList;
	public Map<Id, Id> poLineIdToPoIdMap;
	public Set<Id> rlIdSet;
	
		
	public TestDataForSupplierAutoInvoice() {

		TestFuel fuel = new TestFuel();
        
       	co = fuel.company;
        loc = fuel.location;
        terms = fuel.terms;
        purchasedItem = fuel.itemList[1];        
        
        //create a supplier with 'Create invoice automatically on receipt'=true, 
		Supplier__c sup = fuel.supplier;
        sup.Create_Invoice_Automatically_on_Receipt__c = true;
        sup.Payment_Method_G__c = 'Check';
        update sup;
        
        //create purchase order(s)
		poList = new List<Purchase_Order__c>();
		for (Integer i=1; i<=INT_POS; i++){
			Purchase_Order__c po = new Purchase_Order__c();
			po.Supplier__c = sup.id;
			po.Remit_To_Supplier__c = fuel.remittosupplier.id;
        	po.Company__c = co.id;
        	po.Payment_Term__c = terms.id;
        	poList.add(po);			
		}
		insert poList;
		
		//requery to get the updated Name fields set by the workflow
		poList = [SELECT Id, Name, Supplier__c, Remit_To_Supplier__c, Company__c, Payment_Term__c FROM Purchase_Order__c];
		
		//create a map of PO ids to POs
		poIdtoPoMap = new Map<Id, Purchase_Order__c>();
		for (Purchase_Order__c po: poList) {
			poIdtoPoMap.put(po.Id, po);
		}        
        
        //create purchase order line(s)
		polList = new List<Purchase_Order_Line__c>();
		for (Purchase_Order__c po: poList) {
			for (Integer i=1; i<=INT_POLINES_PER_PO; i++){
		        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();
		        pol.Purchase_Order__c = po.Id;
		        pol.Order_Quantity__c = 10;        
		        pol.Unit_Price__c = 12;
		        pol.Item__c = purchasedItem.Id;
		        pol.Description__c = 'pol desc';
		        pol.Purchase_UOM__c = purchasedItem.Purchasing_UOM__c;
		        pol.Company__c = co.id;
		        pol.Need_Date__c = system.today() + 7;
		        pol.Delivery_Location__c = loc.Id;
		         pol.Delivery_facility__c = loc.facility__c;
		        polList.add(pol);       						
			}    			
		}
		insert polList;
		
		//requery to get the updated Name fields set by the workflow
		polList = [SELECT Id, Name, Purchase_Order__c, Order_Quantity__c, Unit_Price__c, Item__c, Description__c, 
					Purchase_UOM__c, Company__c, Need_Date__c, Delivery_Location__c ,Delivery_facility__c
					FROM Purchase_Order_Line__c]; 
		
		//create a map of PO line Ids to PO ids
		poLineIdToPoIdMap = new Map<Id, Id>();
		for (Purchase_Order_Line__c pol: polList) {
			poLineIdToPoIdMap.put(pol.Id, pol.Purchase_Order__c);	
		}

		//create Receving Documents to receive the POs.  Build a map of PO Id->RD so we have them linked together.
		PoIdRdMap = new Map<Id, Receiving_Document__c>();
		for (Purchase_Order__c po: poList) { //loop through and cretae one RD for each PO
            Receiving_Document__c rd = new Receiving_Document__c();            
            rd.Company__c = co.Id;
            rd.Supplier__c = sup.Id;
            rd.Date_Received__c = system.today();           
            PoIdRdMap.put(po.Id, rd);
		}
		insert(PoIdRdMap.values());			
		
		//create Receipt Lines for the Receving Documents that correspond to the PO lines
		rlList = new List<Receipt_Line__c>();
		for (Purchase_Order_Line__c pol: polList) {
			Receipt_Line__c rl = new Receipt_Line__c();
			rl.Company__c = co.Id;
			rl.Supplier__c = sup.Id;
			rl.Receiving_Document__c = PoIdRdMap.get(pol.Purchase_Order__c).Id;
			rl.Purchase_Order__c = pol.Purchase_Order__c;
			rl.Purchase_Order_Line__c = pol.Id;
			rl.Item__c = purchasedItem.Id;
			rl.Uninvoiced_Quantity__c = 10;
			rl.Unit_Price__c = 12;			
			rlList.add(rl);			
		}
   		insert rlList;
		rlIdSet = (new Map<Id,Receipt_Line__c>(rlList)).keySet();  //make a set of Ids from the list of SObjects	
	}


	public static List<Supplier_Invoice__c> querySupInvoices() {
		return		
		[SELECT
		Id, Invoice_Type__c, Company__c, Supplier__c, Date_Invoiced__c, Date_Received__c, Supplier_Invoice__c,
		Invoice_Amount__c, Status__c, Hold__c, Payment_Method_G__c, Payment_Term__c, Purchase_Order__c, Autonumber__c, 
			(SELECT
				Id, Supplier_Invoice__c, Purchase_Order_Line__c, Item__c, Description__c, Invoice_Quantity__c, 
				Unit_Price__c, Purchase_Order_Line__r.Name 
				FROM Supplier_Invoice_Lines__r) 
		FROM Supplier_Invoice__c];		
	}



}