/**
 * Created by jeromeisrael on 6/23/17.
 */
@isTest
public with sharing class PriceInquiryExtTest {


	static testMethod void basicGetPriceTest(){
		TestFuel fuel = new TestFuel();

		UserPreference defaults = UserPreference.getInstance();
		defaults.preference.Default_Company__c = fuel.company.Id;

		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(fuel.salesOrder);
		PriceInquiryExt pie = new PriceInquiryExt(con);
		pie.salesOrder.Pricebook__c = fuel.pricebook.id;

		pie.soLines[0].Product__c = fuel.product.id;
		pie.getPrice();

		System.debug( logginglevel.error, '~*~ pie.soLines :' + pie.soLines );
		System.debug( logginglevel.error, '~*~ pie.salesOrder :' + pie.salesOrder );
		system.assertEquals(11.12, pie.soLines[0].Unit_Price__c);
	}

	static testMethod void getTieredPrice(){
		TestFuel fuel = new TestFuel();

		UserPreference defaults = UserPreference.getInstance();
		defaults.preference.Default_Company__c = fuel.company.Id;

		Pricebook__c tiered = new PriceBook__c(
				Name = 'Tiered Pricebook',
				Company__c = fuel.company.Id,
				Primary_Key__c = 'TIEREDPB',
				Currency__c = TestFuel.currencyUSD.ID
		);
		insert tiered;

		List<Pricebook_Line__c> pbls = new List<Pricebook_Line__c>();

		Pricebook_Line__c iPL =new Pricebook_Line__c(
				product__c = fuel.product.Id,
				pricebook__c = tiered.id,
				price__c = 100,
				Use_Fixed_Pricing__c = false,
				Min__c = 0,
				Max__c = 50,
				start_date__c = system.today().adddays(0),
				end_date__c = system.today().adddays(10)
		);
		pbls.add(iPL);

		Pricebook_Line__c iPL2 =new Pricebook_Line__c(
			product__c = fuel.product.Id,
			pricebook__c = tiered.id,
			price__c = 80,
			Use_Fixed_Pricing__c = false,
			Min__c = 51,
			Max__c = 100,
			start_date__c = system.today().adddays(0),
			end_date__c = system.today().adddays(10)
		);
		pbls.add(iPL2);

		Pricebook_Line__c iPL3 =new Pricebook_Line__c(
				product__c = fuel.product.Id,
				pricebook__c = tiered.id,
				price__c = 60,
				Use_Fixed_Pricing__c = false,
				Min__c = 101,
				Max__c = null,
				start_date__c = system.today().adddays(0),
				end_date__c = system.today().adddays(10)
		);
		pbls.add(iPL3);

		insert pbls;

		fuel.customerSoldTo.Pricebook__c = tiered.id;
		update fuel.customerSoldTo;


		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(fuel.salesOrder);
		PriceInquiryExt pie = new PriceInquiryExt(con);

		pie.salesOrder.Customer__c = fuel.customerSoldTo.id;
//		pie.salesOrder.Company__c = fuel.company.Id;

		pie.addNewSOLine();
		pie.addNewSOLine();

		pie.soLines[0].Product__c = fuel.product.id;
		pie.soLines[0].Quantity_Ordered__c = 1;

		pie.soLines[1].Product__c = fuel.product.id;
		pie.soLines[1].Quantity_Ordered__c = 55;

		pie.soLines[2].Product__c = fuel.product.id;
		pie.soLines[2].Quantity_Ordered__c = 115;


		pie.getPrice();

		for (Sales_Order_line__c sol : pie.solines){
			System.debug( logginglevel.error, '~*~ sol :' + sol.Quantity_Ordered__c + ' - ' + sol.Unit_Price__c  );
		}
		system.assertEquals(100, pie.soLines[0].Unit_Price__c);
		system.assertEquals(80, pie.soLines[1].Unit_Price__c);
		system.assertEquals(60, pie.soLines[2].Unit_Price__c);


	}
}