/** 
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ShipmentAccountingExtTest {
/*	static TestDataForFinance data = new TestDataForFinance();
 	//static TestFuel data = new Testfuel();	 
    //test data 
	public class shipData { 
		
		public List<Shipment__c> shipmentList = new List<Shipment__c>();
		{
			Shipment__c shipment1 = new Shipment__c();
			shipment1.Company__c = data.company.id;
			shipment1.Date_Shipped__c = system.now();
			shipment1.transaction_date__c = system.now();
			shipment1.Currency__c = TestFuel.currencyUSD.id;
			shipment1.Status__c = 'Confirmed';
			shipmentList.add(shipment1);
			
			Shipment__c shipment2 = new Shipment__c();
			shipment2.Company__c = data.company.id;
			shipment2.Date_Shipped__c = system.now();
			shipment2.transaction_date__c = system.now();
			shipment2.Currency__c = TestFuel.currencyUSD.id;
			shipment2.Status__c = 'Confirmed';
			shipmentList.add(shipment2);
			
			insert  shipmentList;
		} 
		public List<Shipment_Line__c> shipLineList1 = new List<Shipment_Line__c>();
		public List<Shipment_Line__c> shipLineList2 = new List<Shipment_Line__c>();
		public Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    	public Shipment_Line__c shipLine2 = new Shipment_Line__c();
	    	public Shipment_Line__c shipLine3 = new Shipment_Line__c();
	    	public Shipment_Line__c shipLine4 = new Shipment_Line__c();
	    	{
		    shipLine1.Extended_Cost__c = 5;
		    shipLine1.Quantity_Shipped__c = 5;
		    shipLine1.Sales_Order__c = data.salesOrder1.id;
		    shipLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
		    shipLine1.Unit_Price__c = 25;
		    shipLine1.Company__c = data.company.id;
		    shipLine1.Product__c = data.product.id;
		    shipLine1.Location__c = data.location.id;
		    shipLine1.Shipment__c = shipmentList[0].id;
		    shipLineList1.add(shipLine1);
		
		    shipLine2.Extended_Cost__c = 5;
		    shipLine2.Quantity_Shipped__c = 5;
		    shipLine2.Sales_Order__c = data.salesOrder1.id;
		    shipLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
		    shipLine2.Unit_Price__c = 25;
		    shipLine2.Company__c = data.company.id;
		    shipLine2.Product__c = data.product.id;
		    shipLine2.Location__c = data.location.id;
		    shipLine2.Shipment__c = shipmentList[0].id;
		    shipLineList1.add(shipLine2);
		    insert shipLineList1;

		    shipLine3.Extended_Cost__c = 5;
		    shipLine3.Quantity_Shipped__c = 5;
		    shipLine3.Sales_Order__c = data.salesOrder2.id;
		    shipLine3.Sales_Order_Line__c = data.SalesOrderLineList[2].id;
		    shipLine3.Unit_Price__c = 25;
		    shipLine3.Company__c = data.company.id;
		    shipLine3.Product__c = data.product.id;
		    shipLine3.Location__c = data.location.id;
		    shipLine3.Shipment__c = shipmentList[1].id;
		    shipLineList2.add(shipLine3);
		    
		    shipLine4.Extended_Cost__c = 5;
		    shipLine4.Quantity_Shipped__c = 5;
		    shipLine4.Sales_Order__c = data.salesOrder2.id;
		    shipLine4.Sales_Order_Line__c = data.SalesOrderLineList[3].id;
		    shipLine4.Unit_Price__c = 25;
		    shipLine4.Company__c = data.company.id;
		    shipLine4.Product__c = data.product.id;
		    shipLine4.Location__c = data.location.id;
		    shipLine4.Shipment__c = shipmentList[1].id;
		    shipLineList2.add(shipLine4);
		    insert shipLineList2;
		    
		    shipmentList[0].Finalized__c = true;
		    shipmentList[1].Finalized__c = true;
		    
		    update shipmentList;
		    
   		} 
    
     
    	Set<Id> shipmentIds = new Set<Id>();
    	{
	    	for(Shipment__c shipment: shipmentList){
	    		shipmentIds.add(shipment.id);
	    	}
		}
	}
    
    // Test for scenario of shipment finalized, shipment accounting entries not done
    static testMethod void myUnitTest1() {
        Test.startTest();
        
        ShipmentAccountingExt GAEC;
        shipData shipmentData = new shipData();
       	Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(shipmentData.shipmentList);
        
        setcon.setSelected(shipmentData.shipmentList);
        GAEC = new ShipmentAccountingExt(setcon);
       
        GAEC.GenerateShipmentAccounting();
        Test.stopTest();      
        List<Accounting_Entry__c> acctEntryList = [Select id, Name, Shipment__c
                                                    from Accounting_Entry__c
                                                    where Shipment__c in :shipmentData.shipmentIds ]; 
        system.assertNotEquals(null,acctEntryList);
		List<Shipment__c> ShipmentAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where related_accounting_entry__c = null) from Shipment__c where id in :shipmentData.shipmentIds];
	    for(integer i=0;i<ShipmentAfter.size(); i++){
	        system.assertNotEquals(0,ShipmentAfter[i].Accounting_Entries__r.size(),'acctEntryList :  '+acctEntryList);
	    }
   
    }
 
    static testMethod void myUnitTest3() {
        Test.startTest();
       	
       	ShipmentAccountingExt GAEC;
        shipData shipmentData = new shipData();
		
		shipmentData.shipmentList[0].Company__c = null;
		boolean sawException = false;
		try{
       	update shipmentData.shipmentList[0];
		}catch(Exception e){
			sawException = true;
		}
		system.assert(sawException == true, 'Expected to see the exception if the company is missing!');
		
    }
    
    static testMethod void myUnitTest4() {
        Test.startTest();
       	ShipmentAccountingExt GAEC;
        shipData shipmentData = new shipData();
        
        shipmentData.shipmentList[0].Currency__c = null;
        boolean sawException = false;
       	try{
       	update shipmentData.shipmentList[0];
		}catch(Exception e){
			sawException = true;
		}
		system.assert(sawException == true, 'Expected to see the exception if transaction currency is missing!');
		
    }
*/
}