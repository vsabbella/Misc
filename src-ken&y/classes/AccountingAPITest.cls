@isTest
public class AccountingAPITest {
	//This is a test comment
	
	public class ReportSampleData{
		
		//SampleData
		public ReportSampleData(){
			updateData();
		}
		
		public void updateData(){
		}
	}
	
	
    private static void mainTest(){

			List<Inventory_Change__c> invChangeList = new List<Inventory_Change__c>();
	        TestFuel fuel = new TestFuel();
	        Inventory_Change__c invchange1=new Inventory_Change__c();
	        invchange1.Company__c=fuel.company.Id; 
	        invchange1.Finalized__c = true;
	        invchange1.Transaction_Date__c = system.now();
	        invchange1.Finalized_Date__c = system.now();
	        invchange1.Type__c = 'Adjustment';
	        invchange1.Item__c = fuel.itemList[0].id;
	        invchange1.Reason_Code__c = null;
	        invchange1.count_quantity__c = 3;
	        invchange1.computer_Quantity__c = 3;
	        invChangeList.add(invchange1);
	        insert invChangeList;        
	                                                         
			List<Inventory_Transaction__c> invtransList = new List<Inventory_Transaction__c>();
			Inventory_Transaction__c invtrans1 = new Inventory_Transaction__c();	
			
			invtrans1.Inventory_Change__c = invChangeList[0].id;
			invtrans1.Item__c = fuel.itemList[0].id;			
			invtrans1.Extended_Cost__c = null;
			invtrans1.Type__c = 'Cycle Count';
			invtrans1.Subtransaction_Type__c = 'Cycle Count';
			invtrans1.Line_Type__c = 'Increase';
			invtrans1.Standard_Cost__c = 3;
			invtrans1.Quantity__c = 10;
			invtrans1.Company__c = fuel.company.Id;
			invtransList.add(invtrans1); 
			insert invtransList;
	        
	        invchange1 = [Select id, Name, Finalized__c, Finalized_hidden__c
	                                from Inventory_Change__c 
	                                where id = :invchange1.id];
	            
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
		    //InventoryChangeAccounting ica = new InventoryChangeAccounting();
		    //ica.execute(invChangeList);		

		

		 AccountingAPI accAPI = new AccountingAPI();
		    accAPI.generateAccounting((List<sObject>)invChangeList);	
	            
		    Set<Id> icIds = new Set<Id>();
		    for(Inventory_Change__c ic: invChangeList){
		        icIds.add(ic.id);
		    }
	        //system.debug('invChangeList: '+ invChangeList);      
	        List<Accounting_Entry__c> accountingEntryListIT = [Select id, Name, Inventory_Change__c
	                                                                    from Accounting_Entry__c
	                                                                    where Inventory_Change__c in :icIds];
	                                                                    
	                                                                
	      	//system.debug('accountingEntryListIT: '+ accountingEntryListIT);     
	        system.assertNotEquals(null, accountingEntryListIT);
	        system.assertEquals(1, accountingEntryListIT.size());
	}
         
}