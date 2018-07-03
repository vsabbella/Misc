@isTest
public with sharing class ModifyTransitRouteTest {
	
	static TestFuel globalTestData = new TestFuel();

    /* KNDY-10333
	static testMethod void testSetDeliveryMethod(){
    	    	
    	Test.startTest();
	
        // Create a location w/ a facility that has no Address. So when the SOL is inserted, the SO will have a NULL Means of Transport
		Facility__c facility1 = new Facility__c(
                    Name = globalTestData.company.Name + ' Facility-Test',
                    Company__c = globalTestData.company.Id,
                    Address__c = null,
                    Primary_Key__c = 'FA01-Test',
                    Description__c = 'Facility-Test',
                    Shipping_Calendar__c = [select Id from BusinessHours where isDefault = true limit 1].Id
                );
        insert facility1;

        Location__c location1 = new Location__c(
                    Facility__c = facility1.id,
                    name = 'Delivery/Shipping Location'  );
        insert location1;  


    	Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Company__c = globalTestData.company.id;
        salesOrderLine.Sales_Order__c = globalTestData.salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 4;
        salesOrderLine.Ship_From_Location__c = location1.id;
        insert salesOrderLine;
    	
    	Sales_Order__c salesOrder = [select required_date__c, Ship_To__r.Lead_time__c, Id, Means_of_Transport__c, Delivery_Method__c, 
                                        (select id, required_date__c, Estimated_Ship_Date__c, Ship_From_Location__r.Facility__r.Lead_time__c 
                                            from Sales_Order_Lines__r
                                            where id = :salesOrderLine.id)
    								   from Sales_Order__c 
    								  where Id = :globalTestData.salesOrder.Id];
    	// SO MoT should be null			
        system.assertEquals(0, salesOrder.Ship_To__r.Lead_time__c);	
        system.assertEquals(0, salesOrder.Sales_order_lines__r[0].Ship_From_Location__r.Facility__r.Lead_time__c); 
		//system.assertEquals(null, salesOrder.required_date__c);
        system.assertEquals(System.today()+4, salesOrder.Sales_order_lines__r[0].required_date__c);
        system.assertEquals(null, salesOrder.Means_of_Transport__c);
        system.assertEquals(System.today()+4, salesOrder.Sales_order_lines__r[0].Estimated_Ship_Date__c);
		
        // Create data for a matching Transit Route associated to the SOL when we updated it
    	Account account = globalTestData.newAccount();
                account.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
                account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
                account.billingcity = 'Redwood City';
                account.billingstate = 'CA';
                account.billingpostalcode = '94065';
                account.billingcountry = 'USA';
                account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
                account.shippingcity = 'Redwood City';
                account.shippingstate = 'CA';
                account.shippingpostalcode = '94065';
                account.shippingcountry = 'USA';
                account.phone = '650-468-2000';
                account.fax = '650-468-2010';
                account.website = 'kenandy.com';
        insert account;

		Facility__c facility3 = new Facility__c(
                    Name = globalTestData.company.Name + ' Facility-3',
                    Company__c = globalTestData.company.Id,
                    Address__c = account.Id,
                    Primary_Key__c = 'FA03',
                    Description__c = 'Facility-3',
                    Enable_Transit_Route_Optimization__c = true
                    //Shipping_Calendar__c = [select Id from BusinessHours where isDefault = true limit 1].Id
                );
        insert facility3;

        Location__c location = new Location__c(
					Facility__c = facility3.id,
					name = 'Delivery/Shipping Location'  );
		insert location;    

        Means_of_Transport__c newMot = globalTestData.newMeansOfTransport('AIR', 'Air');
        insert newMot;

		Transit_Route__c thirdTransitRoute = new Transit_Route__c();
    	thirdTransitRoute.Destination__c = globalTestData.customerShipTo.Address__c;
		thirdTransitRoute.Origin__c = facility3.Address__c;
		thirdTransitRoute.Means_of_Transport__c = newMot.Id;
		thirdTransitRoute.Transit_Time__c = 4;
		thirdTransitRoute.Delivery_Method__c = 'Delivery';
		thirdTransitRoute.Primary__c = true;
		insert thirdTransitRoute;

		salesOrderLine.Ship_From_Location__c = location.id;
		update salesOrderLine;



		salesOrder = [select Id, Means_of_Transport__c, Delivery_Method__c, 
                            (select id, Estimated_Ship_Date__c 
                                from Sales_Order_Lines__r 
                                where id =: salesOrderLine.id )
    					from Sales_Order__c 
    				    where Id = :globalTestData.salesOrder.Id];

        system.assertEquals(salesOrder.Means_of_Transport__c, newMot.Id);
    	Test.stopTest();
        // it should be 4 days before the required date. The req date is 4 days from now.
        system.assertEquals(system.today(), salesOrder.Sales_Order_lines__r[0].Estimated_Ship_Date__c);

    }
    */
}