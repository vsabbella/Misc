@isTest
public with sharing class PricingServiceTest {

	static Decimal dayPrice = 70.000000;
	static Decimal weekPrice = 400.000000;
	static Decimal monthPrice = 1350.000000;

	/*
		Basic Flow testing
	*/

	testMethod static void test_DynamicMonth_InvoiceThenReturn_MonthWeekDay_CustomMonthlyPricingUom(){


		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0);

		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0);

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct1;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		tdw.agreementPrice = 1337;

		dates.returnDate = system.now();//
		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');


		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing( new List<Fulfillment__c>{fulfillment}, dates);
		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, agreement, dates));


		Integer monthbtw = dates.shippedDate.date().monthsBetween(dates.returnDate.date());

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 0, // 1, this is 0 because CIL doesn't split
				'WEEKLY' => 0, // 2, see above why this is 0
				'MONTHLY2' => monthbtw
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		Decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Decimal prorateDays = lastRecDate.date().daysBetween(system.today()) / Decimal.valueOf(Date.daysInMonth(system.today().year(), system.today().Month()));
		Decimal expectedProrateValue = prorateDays * tdw.agreementPrice * 100;
		Decimal initalIntervalBestPrice = (2*400 + 1*70) * 100;

		Integer invoiceSumMod = Math.mod( Integer.valueOf( (invoiceSum ).setScale(2, RoundingMode.HALF_UP) - initalIntervalBestPrice),1337);
		system.assertEquals(0, invoiceSumMod);
		system.assertEquals(expectedProrateValue.setScale(2, RoundingMode.HALF_UP), fulfillSum.setScale(2, RoundingMode.HALF_UP));
	}

	// Test bypassing Pricebook with configuration and AGL custom price
	testMethod static void test_DynamicMonth_MonthOnlyProrate_InvoiceThenReturn_InvoiceAhead_NoPricebookWithCS_CustomPrice(){

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2018,1,1,0,0,0);


		dates.startDate = system.now();
		dates.shippedDate = dates.startDate;
		dates.returnDate = DateTime.newInstance(dates.shippedDate.date().addMonths(1).toStartOfMonth(), Time.newInstance(0,0,0,0)); // beginning of next month on the recurring start date
		system.assertEquals(1,dates.returnDate.day(), dates.shippedDate + ' ' + dates.returnDate);

		Integer totalRentalDays = dates.shippedDate.date().daysBetween(dates.returnDate.date());
		Integer monthDays = Date.daysInMonth(dates.shippedDate.date().year(), dates.shippedDate.date().month());

		System.debug( logginglevel.error, '~*~ dates :' + dates );
		System.debug( logginglevel.error, '~*~ totalRentalDays :' + totalRentalDays );

		Test.startTest();

		List<Configuration__c> pblConfigList = new List<Configuration__c>();
		pblConfigList.add(new Configuration__c(
				Name = Pricebook_Line__c.getSObjectType().getDescribe().getLocalName() + '-' + Pricebook_Line__c.getSObjectType().getDescribe().getKeyPrefix(),
				Value__c = UserInfo.getUserId()
		));
		pblConfigList.add(new Configuration__c(
				Name = 'Best_Price_Pricebook_Required',
				Value__c = 'fAlSe'
		));

		insert pblConfigList;


		List<Pricebook_line__c> pblList = [select id from pricebook_line__c where product__c = :fuel.StdProduct4.Id];
		delete pblList;

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct4;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		tdw.agreementPrice = 300;



		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates, True, new Set<Id>());
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal expectedInvoiceAmt = tdw.agreementPrice/monthDays*totalRentalDays*100;
		system.assertEquals(expectedInvoiceAmt.setScale(2, RoundingMode.HALF_UP), invoiceSum, tdw.agreementPrice + ' / ' + monthDays + ' * ' + totalRentalDays);

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		System.debug( logginglevel.error, '~*~ returnData :' + returnData );
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		system.assertEquals(0, fulfillSum);

	}

	// Test error message if not using Custom Setting to bypass PB required for Rental Agreements. Since we don't capture anything on the
	testMethod static void test_DynamicMonth_MonthOnlyProrate_InvoiceThenReturn_InvoiceAhead_NoPricebookNoCS_CustomPrice(){

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2018,1,1,0,0,0);


		dates.startDate = system.now();
		dates.shippedDate = dates.startDate;
		dates.returnDate = DateTime.newInstance(dates.shippedDate.date().addMonths(1).toStartOfMonth(), Time.newInstance(0,0,0,0)); // beginning of next month on the recurring start date
		system.assertEquals(1,dates.returnDate.day(), dates.shippedDate + ' ' + dates.returnDate);

		Integer totalRentalDays = dates.shippedDate.date().daysBetween(dates.returnDate.date());
		Integer monthDays = Date.daysInMonth(dates.shippedDate.date().year(), dates.shippedDate.date().month());

		System.debug( logginglevel.error, '~*~ dates :' + dates );
		System.debug( logginglevel.error, '~*~ totalRentalDays :' + totalRentalDays );

		Test.startTest();

		List<Configuration__c> pblConfigList = new List<Configuration__c>();
		pblConfigList.add(new Configuration__c(
				Name = Pricebook_Line__c.getSObjectType().getDescribe().getLocalName() + '-' + Pricebook_Line__c.getSObjectType().getDescribe().getKeyPrefix(),
				Value__c = UserInfo.getUserId()
		));
//		pblConfigList.add(new Configuration__c(
//				Name = 'Best_Price_Pricebook_Required',
//				Value__c = 'fAlSe'
//		));

		insert pblConfigList;


		List<Pricebook_line__c> pblList = [select id from pricebook_line__c where product__c = :fuel.StdProduct4.Id];
		delete pblList;

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct4;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		tdw.agreementPrice = 300;



		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates, True, new Set<Id>());

		ReturnResult returnData = processReturn( new ProcessReturnWrapper( 100, ( Agreement__c ) dataResult.get( 'agreement' ), dates ), True );
		JsonResult js = returnData.AgReturnJSON;
		system.assertEquals(false, js.success, js);


	}

	// Test bypassing Pricebook with configuration and AGL custom price
	testMethod static void test_DynamicMonth_MonthOnlyProrate_InvoiceThenReturn_InvoiceAhead_NoPricebookWithCS_NoCustomPrice(){

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2018,1,1,0,0,0);


		dates.startDate = system.now();
		dates.shippedDate = dates.startDate;
		dates.returnDate = DateTime.newInstance(dates.shippedDate.date().addMonths(1).toStartOfMonth(), Time.newInstance(0,0,0,0)); // beginning of next month on the recurring start date
		system.assertEquals(1,dates.returnDate.day(), dates.shippedDate + ' ' + dates.returnDate);

		Integer totalRentalDays = dates.shippedDate.date().daysBetween(dates.returnDate.date());
		Integer monthDays = Date.daysInMonth(dates.shippedDate.date().year(), dates.shippedDate.date().month());

		System.debug( logginglevel.error, '~*~ dates :' + dates );
		System.debug( logginglevel.error, '~*~ totalRentalDays :' + totalRentalDays );

		Test.startTest();

		List<Configuration__c> pblConfigList = new List<Configuration__c>();
		pblConfigList.add(new Configuration__c(
				Name = Pricebook_Line__c.getSObjectType().getDescribe().getLocalName() + '-' + Pricebook_Line__c.getSObjectType().getDescribe().getKeyPrefix(),
				Value__c = UserInfo.getUserId()
		));
				pblConfigList.add(new Configuration__c(
						Name = 'Best_Price_Pricebook_Required',
						Value__c = 'fAlSe'
				));

		insert pblConfigList;


		List<Pricebook_line__c> pblList = [select id from pricebook_line__c where product__c = :fuel.StdProduct4.Id];
		delete pblList;

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct4;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
//		tdw.agreementPrice = 300;



		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates, True, new Set<Id>());
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal expectedInvoiceAmt = tdw.agreementPrice/monthDays*totalRentalDays*100;
		system.assertEquals(expectedInvoiceAmt.setScale(2, RoundingMode.HALF_UP), invoiceSum, tdw.agreementPrice + ' / ' + monthDays + ' * ' + totalRentalDays);

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		System.debug( logginglevel.error, '~*~ returnData :' + returnData );
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		system.assertEquals(0, fulfillSum);

	}

	testMethod static void test_DynamicMonth_MonthOnlyProrate_InvoiceThenReturn_InvoiceAhead(){

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2018,1,1,0,0,0);


		dates.startDate = system.now();
		dates.shippedDate = dates.startDate;
		dates.returnDate = DateTime.newInstance(dates.shippedDate.date().addMonths(1).toStartOfMonth(), Time.newInstance(0,0,0,0)); // beginning of next month on the recurring start date

		decimal totalRentalDays = (decimal) dates.shippedDate.date().daysBetween(dates.returnDate.date());
		decimal monthDays =  Decimal.valueOf(Date.daysInMonth(dates.shippedDate.date().year(), dates.shippedDate.date().month()));

		System.debug( logginglevel.error, '~*~ dates :' + dates );
		System.debug( logginglevel.error, '~*~ totalRentalDays :' + totalRentalDays );

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct4;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		tdw.agreementPrice = 300;



		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates, True, new Set<Id>());
		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		decimal expectedSum = 300/monthDays*totalRentalDays*100;

		system.assertEquals(expectedSum.setScale(2, RoundingMode.HALF_UP), invoiceSum, '300' + ' / ' + monthDays + ' * ' + totalRentalDays);

	}

	testMethod static void test_DynamicMonth_Month_InvoiceThenReturn(){

		/*
			Start Date	End Date	Mo Days		Range	Unit Price
			8/17/2017	9/1/2017		31		15		653.23
			9/1/2017	10/1/2017		30		30		1350.00
			....		....			...		...		...
			??????		???????			??		??		1350
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0);

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct4;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;

		dates.returnDate = system.now();//
		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates);
		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));

		Integer monthbtw = dates.shippedDate.date().monthsBetween(dates.returnDate.date());
		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY2' => monthbtw
		};
		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		Decimal prorateDays = lastRecDate.date().daysBetween(system.today()) / Decimal.valueOf(Date.daysInMonth(system.today().year(), system.today().Month()));
		Decimal expectedProrateValue = prorateDays * 1350 * 100;
		Decimal initalIntervalBestPrice = 65322.58;

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));

		Integer invoiceSumMod = Math.mod( Integer.valueOf( (invoiceSum ).setScale(2, RoundingMode.HALF_UP) - initalIntervalBestPrice),1350);
		system.assertEquals(0, invoiceSumMod);
		system.assertEquals(expectedProrateValue.setScale(2, RoundingMode.HALF_UP), fulfillSum.setScale(2, RoundingMode.HALF_UP));

	}

	testMethod static void test_FreeMonth_DynamicMonth_Month_InvoiceThenReturn(){

		/*
			Start Date	End Date	Mo Days		Range	Unit Price
			8/17/2017	9/1/2017		31		15		653.23
			9/1/2017	10/1/2017		30		30		1350.00
			....		....			...		...		...
			??????		???????			??		??		1350
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,12,1,0,0,0);
		dates.startDate = DateTime.newInstance(2017,12,1,0,0,0);
		dates.shippedDate = DateTime.newInstance(2017,12,10,0,0,0);
		dates.returnDate = DateTime.newInstance(2018,2,1,0,0,0);

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct5;
		tdw.discountProduct = fuel.DiscountProduct;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;


		// get closest recurrence date before today
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, List<Sobject>> dataResult = new CreateData(tdw, dates).resultListMap;

		Test.stopTest();

		Configuration__c conf = new Configuration__c(
				Name = 'Best_Price_Pricebook_Required',
				Value__c = 'fAlSe'
		);

		insert conf;

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement')[0], dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

//		Integer monthbtw = dates.shippedDate.date().monthsBetween(dates.returnDate.date());
		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY2' => 4
		};
		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

//		Decimal prorateDays = lastRecDate.date().daysBetween(system.today()) / Decimal.valueOf(Date.daysInMonth(system.today().year(), system.today().Month()));
//		Decimal expectedProrateValue = prorateDays * 1350 * 100;
//		Decimal initalIntervalBestPrice = 65322.58;

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
//		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));

//		Integer invoiceSumMod = Math.mod( Integer.valueOf( (invoiceSum ).setScale(2, RoundingMode.HALF_UP) - initalIntervalBestPrice),1350);
		system.assertEquals(0, invoiceSum);
//		system.assertEquals(expectedProrateValue.setScale(2, RoundingMode.HALF_UP), fulfillSum.setScale(2, RoundingMode.HALF_UP));

	}

	/* current special */
	testMethod static void test_DynamicMonth_MonthWeekDay_InvoiceThenReturn_Sameday(){

		/*
			Start Date	End Date	Range	Unit Price
			8/17/2017	9/1/2017	15		$870
			9/1/2017	10/1/2017	30		1350
			....		....		...		...		...
			??????		???????		??		??		1350
		*/


		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();

		// get closest recurrence date before today
		dates.returnDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;


		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates);
		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));

		Integer monthbtw = dates.shippedDate.date().monthsBetween(dates.returnDate.date());
		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY2' => monthbtw
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		Decimal initalIntervalBestPrice = 87000;

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));

		Integer invoiceSumMod = Math.mod( Integer.valueOf( (invoiceSum ).setScale(2, RoundingMode.HALF_UP) - initalIntervalBestPrice),1350);
		system.assertEquals(0, invoiceSumMod);
		system.assertEquals(0, fulfillSum.setScale(2, RoundingMode.HALF_UP));


	}

	testMethod static void test_DynamicMonth_MonthWeekDay_InvoiceThenReturn(){

		/*
			Start Date	End Date	Range	Unit Price
			8/17/2017	9/1/2017	15		$870
			9/1/2017	10/1/2017	30		1350
			....		....		...		...		...
			??????		???????		??		??		1350
		*/
		

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();

		// get closest recurrence date before today
		dates.returnDate = system.now();//
		DateTime lastRecDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);

		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		
		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates);
		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));

		Integer monthbtw = dates.shippedDate.date().monthsBetween(dates.returnDate.date());
		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY2' => monthbtw
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);


		Decimal prorateDays = lastRecDate.date().daysBetween(system.today()) / Decimal.valueOf(Date.daysInMonth(system.today().year(), system.today().Month()));
		Decimal expectedProrateValue = prorateDays * 1350 * 100;
		Decimal initalIntervalBestPrice = 87000;

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));

		Integer invoiceSumMod = Math.mod( Integer.valueOf( (invoiceSum ).setScale(2, RoundingMode.HALF_UP) - initalIntervalBestPrice),1350);
		system.assertEquals(0, invoiceSumMod);
		system.assertEquals(expectedProrateValue.setScale(2, RoundingMode.HALF_UP), fulfillSum.setScale(2, RoundingMode.HALF_UP));


	}

	testMethod static void test_FixedMonth_MonthWeekDay_InvoiceThenReturn(){
		/*
			Start Date	End Date	Range	Unit Price
			8/17/2017	8/29/2017	12		750.00
			8/29/2017	9/26/2017	28		1350.00
			9/26/2017	10/24/2017	28		1350.00
			....		....		...		...
			??????		???????		??		??

		*/
		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.SPSProduct;
		tdw.billingUOM = fuel.SPSmonth;
		tdw.pricingUOM = fuel.SPSmonth;

		// Invoicing before return means that we're invoicing up until today's date. Since the recurrence is 8/1 and in conjucture with out billing cycle (monthly 28 days or 1 month) we'll find the previous recurrence date from today and return on that date.
		dates.returnDate = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate);
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> invoiceData = runInvoicing(new List<Fulfillment__c>{(Fulfillment__c) dataResult.get('fulfillment')}, dates);
		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates)); // returnDate, 100, );

		// Since we're looking into the future, depending on the date this is run, we need to find the months in between 8/17 and the return date (most recent previous recurrence date)
		Decimal dayBetween = Decimal.valueOf(dates.shippedDate.date().daysBetween(dates.returnDate.date()));
		Integer intervalBetween = Integer.valueOf(Math.ceil(dayBetween/28.00));
		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY' => intervalBetween
		};
		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));

		Integer invoiceSumMod = Math.mod( Integer.valueOf(invoiceSum.setScale(2, RoundingMode.HALF_UP) - 75000),1350);
		system.assertEquals(0, invoiceSumMod);
		system.assertEquals(0, fulfillSum.setScale(2, RoundingMode.HALF_UP));

	}

	// different return dates
	testMethod static void test_DynamicMonth_ReturnThenInvoice_TwoShippedDates_MonthWeek(){
		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0);

		dates.shippedDate = DateTime.newInstance(2017,8,9,0,0,0);
		dates.returnDate = DateTime.newInstance(2017,9,24,0,0,0);

		dates.shippedDate2 = DateTime.newInstance(2017,8,1,0,0,0);
		dates.returnDate2 = DateTime.newInstance(2017,9,24,0,0,0);

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct1;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(null, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'WEEKLY' => 6,
				'DAILY' => 4,
				'MONTHLY2' => 2
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);
	}

	// partials
	testMethod static void test_DynamicMonth_ReturnThenInvoice_PartialAmt_MonthWeekDay(){

		/*
			25 QTY returned. 75 still invoiced.

		(Fulfillments split)
			Start Date	End Date	Days	Range	QTY		Unit Price
			8/17/2017	-			-		-		75		1350		M-(F-On-going) original fulfillment with rental qty to be invoiced
			8/17/2017	8/24/2017	31		7		25		400			M-(F-return)
			8/24/2017	8/31/2017	31		7		25		400			M-(F-return)
			8/31/2017	9/1/2017	31		1		25		70			M-(F-return)
			9/1/2017	10/1/2017	30		30		25		1350		M-(F-return)
			10/1/2017	11/1/2017	31		31		25		1350		M-(F-return)
			11/1/2017	11/6/2017	30		30		25		225			M-(F-return)

							Fulfillment Total Unit Price: 	3795.00
						Fulfillment Total Extended Price: 	379500.00

		(Invoice on Existing rental Qty & reutrn qty because it's group by agreement)
			Start Date	End Date	Days	Range	QTY		Unit Price
			8/17/2017	9/1/2017	31		15		75		870			M-(CIL-existing) 				* Note: This should split but we don't have yet.
			9/1/2017	10/1/2017	30		30		100		1350		M-(CIL-existing + F-return)
			10/1/2017	11/1/2017	31		31		100		1350		M-(CIL-existing + F-return)
			11/1/2017	12/1/2017	30		30		75		1350		M-(CIL-existing)
			...			...			...		...		75		1350		M-(CIL-existing) 				* On-going invoicing

			8/17/2017	8/24/2017	31		7		25		400			W-(F-return)
			8/24/2017	8/31/2017	31		7		25		400			W-(F-return)
			8/31/2017	9/1/2017	31		1		25		70			D-(F-return)
			11/1/2017	11/6/2017	30		30		25		225			M-(F-return)
		*/
		

		DateWrapper dates = new DateWrapper();
		// local time, not GMT
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,6,0,0,0); // 11/1

		System.debug( logginglevel.error, '~*~  (dtTest) All Dates:' + dates);

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();


		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(25, agreement, dates));

		Map<String,Integer> correctFulPricingUomMap = new Map<String,Integer>{
				'MONTHLY2' => 7 // 3 are Best Price disguised as months - 2 weeks, 1 day. 1 is a prorate. 2 are full term. 1 is the non-returned fulfillment. (see above in the comment)
		};
		validatePricingUOMs( returnData.get('fulfillments'), correctFulPricingUomMap);
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		system.assertEquals(514500.00, fulfillSum.setScale(2, RoundingMode.HALF_UP));


		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		Date lastReccurenceDateFromToday = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate).date();
		Integer cilMonthsAfterReturn = dates.shippedDate.date().monthsBetween(lastReccurenceDateFromToday);
		System.debug( logginglevel.error, '~*~ cilMonthsAfterReturn :' + cilMonthsAfterReturn );

		// add the months from the return fulfillment. 2 months + 1 month prorate.
		cilMonthsAfterReturn += 3;

		// subtract the full billing cycle months that overlap with the return. In this case, it's 2. 9/1-10/1 and 10/1-11/1. These get grouped because of IGR settings By Agreement
		cilMonthsAfterReturn -= 2;

		Map<String,Integer> correctCilPricingUomMap = new Map<String,Integer>{
				'DAILY' => 1,
				'WEEKLY' => 2,
				'MONTHLY2' => cilMonthsAfterReturn // 2 months overlap, 1 month prorate (f), 1 month bp (cil), months between (
		};
		validatePricingUOMs( invoiceData.get('cilList'), correctCilPricingUomMap);

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal returnFulfillmentSum = (70 + (400*2) + (1350*2) + 225) * 25;
		decimal cilInitialDecimal = 870 * 75;
		System.debug( logginglevel.error, '~*~ invoiceSum :' + invoiceSum );
		System.debug( logginglevel.error, '~*~ returnFulfillmentSum :' + returnFulfillmentSum );
		System.debug( logginglevel.error, '~*~ cilInitialDecimal :' + cilInitialDecimal );
		// subtract the Fulfillment values months initial month's Best Price and the last month's prorate from the return qty from the invoice sum, and then it should be divisible by 1350 with no remainders
		Integer invoiceSumMod = Math.mod( Integer.valueOf( invoiceSum - returnFulfillmentSum - cilInitialDecimal ), 75 * 1350);
		system.assertEquals(0, invoiceSumMod);

	}

	testMethod static void test_FixedMonth_ReturnThenInvoice_PartialAmt_MonthWeekDay(){

		/*
			25 QTY returned. 75 still invoiced.

		(Fulfillments split)
			Start Date	End Date	Days	Range	QTY		Unit Price
			8/17/2017	-			-		-		75		1350		M-(F-On-going) original fulfillment with rental qty to be invoiced
			8/17/2017	8/24/2017	31		7		25		400			M-(F-return)
			8/24/2017	8/25/2017	31		1		25		70			M-(F-return)
			8/25/2017	8/26/2017	31		1		25		70			M-(F-return)
			8/26/2017	8/27/2017	31		1		25		70			M-(F-return)
			8/27/2017	8/28/2017	31		1		25		70			M-(F-return)
			8/28/2017	8/29/2017	31		1		25		70			M-(F-return)
			8/29/2017	9/26/2017	31		28		25		1350.00		M-(F-return)
			9/26/2017	10/24/2017	30		28		25		1350.00		M-(F-return)
			10/24/2017	11/6/2017	31		6		25		626.79		M-(F-return)

										Total Unit Price: 	5426.79
									Total Extended Price: 	542678.57
								Return fulfillment Price:	407678.57

		(Invoice on Existing rental Qty & reutrn qty because it's group by agreement)
			Start Date	End Date	Days	Range	QTY		Unit Price
			8/17/2017	8/29/2017	31		12		75		750			M-(CIL-existing) * Best Price on CIL isn't getting split currently. This is 1 week, 5 days.
			8/29/2017	9/26/2017	31		28		100		1350		M-(CIL-existing + F-return)
			9/26/2017	10/24/2017	30		28		100		1350		M-(CIL-existing + F-return)
			10/24/2017	11/21/2017	31		28		75		1350		M-(CIL-existing)
			...			...			...		...		75		1350		M-(CIL-existing) * FUTURE (on-going)			* On-going invoicing

			8/17/2017	8/24/2017	31		7		25		400			W-(F-return)
			8/24/2017	8/25/2017	31		1		25		70			D-(F-return)
			8/25/2017	8/26/2017	31		1		25		70			D-(F-return)
			8/26/2017	8/27/2017	31		1		25		70			D-(F-return)
			8/27/2017	8/28/2017	31		1		25		70			D-(F-return)
			8/28/2017	8/29/2017	31		1		25		70			D-(F-return)
			10/24/2017	11/6/2017	31		13		25		626.79		M-(F-return)
		*/
		

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,6,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.SPSProduct;
		tdw.billingUOM = fuel.SPSmonth;
		tdw.pricingUOM = fuel.SPSmonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(25, agreement, dates));


		Map<String,Integer> fulFillmentPricingUomMap = new Map<String,Integer>{
				'MONTHLY' => 10
		};
		validatePricingUOMs( returnData.get('fulfillments'), fulFillmentPricingUomMap);
		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		system.assertEquals(542678.57,returnSum.setScale(2, RoundingMode.HALF_UP));

		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		Date lastReccurenceDateFromToday = getLastRecurrenceDate(tdw.billingUOM, dates.recurrenceDate).date();
		Decimal cilDaysBetweenLastRecurrence = Decimal.valueOf(dates.shippedDate.date().daysBetween(lastReccurenceDateFromToday));
		Integer cilInterval = Integer.valueOf(Math.ceil(cilDaysBetweenLastRecurrence/28.00));
		System.debug( logginglevel.error, '~*~ cilDaysBetweenLastRecurrence :' + cilDaysBetweenLastRecurrence );

		// add the months from the return fulfillment. 2 months + 1 month prorate.
		cilInterval += 3;

		// subtract the full billing cycle months that overlap with the return. In this case, it's 2. 9/1-10/1 and 10/1-11/1. These get grouped because of IGR settings By Agreement
		cilInterval -= 2;


		System.debug( logginglevel.error, '~*~ intervalBetween :' + cilInterval );
		Map<String,Integer> correctCilPricingUomMap = new Map<String,Integer>{
				'DAILY' => 5,
				'WEEKLY' => 1,
				'MONTHLY' => cilInterval
		};
		validatePricingUOMs( invoiceData.get('cilList'), correctCilPricingUomMap);

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal returnFulfillmentSum = 101919.64;
		decimal cilInitialDecimal = 750 * 75;
		System.debug( logginglevel.error, '~*~ invoiceSum :' + invoiceSum );
		System.debug( logginglevel.error, '~*~ returnFulfillmentSum :' + returnFulfillmentSum );
		System.debug( logginglevel.error, '~*~ cilInitialDecimal :' + cilInitialDecimal );
		// subtract the Fulfillment values months initial month's Best Price and the last month's prorate from the return qty from the invoice sum, and then it should be divisible by 1350 with no remainders
		Integer invoiceSumMod = Math.mod( Integer.valueOf( invoiceSum.setScale(2, RoundingMode.HALF_UP) - returnFulfillmentSum - cilInitialDecimal), 75 * 1350);

		system.assertEquals(0, invoiceSumMod);

	}


	// Normal flow
	testMethod static void test_DynamicMonth_ReturnThenInvoice_MonthWeekDay(){

		/*
			Start Date	End Date	Days	Range	Unit Price
			8/17/2017	8/24/2017	31		7		400
			8/24/2017	8/31/2017	31		7		400
			8/31/2017	9/1/2017	31		1		70
			9/1/2017	10/1/2017	30		30		1350
			10/1/2017	11/1/2017	31		31		1350
			11/1/2017	11/6/2017	30		30

							Total Unit Price
						Total Extended Price
		*/
		

		DateWrapper dates = new DateWrapper();
		// local time, not GMT
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,6,0,0,0); // 11/1

		System.debug( logginglevel.error, '~*~  (dtTest) All Dates:' + dates);

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();


		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, agreement, dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 1,
				'WEEKLY' => 2,
				'MONTHLY2' => 3
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		system.assertEquals(invoiceSum.setScale(2, RoundingMode.HALF_UP), fulfillSum.setScale(2, RoundingMode.HALF_UP));

	}
	
	testMethod static void test_DynamicMonth_ReturnThenInvoice_Month(){

		/*
		Start Date	End Date	Days	Range	Unit Price
		8/17/2017	9/1/2017	31		15		653.23
		9/1/2017	10/1/2017	30		30		1350.00
		10/1/2017	11/1/2017	31		31		1350.00
		11/1/2017	11/6/2017	30		5

						Total Unit Price
					Total Extended Price
		 */
		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,6,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct4;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 1,
				'WEEKLY' => 2,
				'MONTHLY2' => 4
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));
		decimal fulfillSum = getSumTotal(returnData.get('fulfillments'));
		system.assertEquals(invoiceSum.setScale(2, RoundingMode.HALF_UP), fulfillSum.setScale(2, RoundingMode.HALF_UP));

	}

	testMethod static void test_FixedMonth_ReturnThenInvoice_MonthWeekDay(){

		/*
			Start Date	End Date	Days	Range	Unit Price
			8/17/2017	8/24/2017	31		7		400.00 	(week @ $400)
			8/24/2017	8/29/2017	31		5		350		(days @ $70)
			8/29/2017	9/26/2017	31		28		1350.00
			9/26/2017	10/24/2017	30		28		1350.00
			10/24/2017	11/6/2017	31		6

								Total Unit Price
							Total Extended Price
		*/
		

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,6,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.SPSProduct;
		tdw.billingUOM = fuel.SPSmonth;
		tdw.pricingUOM = fuel.SPSmonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, agreement, dates));

		Map<String,Integer> fulFillmentPricingUomMap = new Map<String,Integer>{
				'MONTHLY' => 9
		};
		validatePricingUOMs( returnData.get('fulfillments'), fulFillmentPricingUomMap);

		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		Decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));


		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 5,
				'WEEKLY' => 1,
				'MONTHLY' => 3
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		system.assertEquals(407678.57,returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(407678.57,invoiceSum.setScale(2, RoundingMode.HALF_UP));

	}


	// breaking point test for month and week.
	testMethod static void test_DynamicMonth_ReturnThenInvoice_firstLastBreakingPoint_WeekToMonth(){

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,8,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,9,25,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct1;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		system.assertEquals(270000, returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(270000, invoiceSum.setScale(2, RoundingMode.HALF_UP));

	}

	testMethod static void test_DynamicMonth_ReturnThenInvoice_firstLastBreakingPoint_DayToWeek(){
		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,26,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,9,7,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct1;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'WEEKLY' => 2
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		system.assertEquals(80000, returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(80000, invoiceSum.setScale(2, RoundingMode.HALF_UP));

	}

	testMethod static void test_DynamicMonth_ReturnThenInvoice_firstLastPreBreakingPoint_MonthWeek(){
		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,9,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,9,24,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct1;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'WEEKLY' => 6,
				'DAILY' => 4
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		system.assertEquals(268000, returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(268000, invoiceSum.setScale(2, RoundingMode.HALF_UP));

	}

	testMethod static void test_DynamicMonth_ReturnThenInvoice_firstLastPreBreakingPoint_MonthWeek_Custom(){

		System.debug( logginglevel.error, '~*~ dayPrice :' + dayPrice );
		System.debug( logginglevel.error, '~*~ weekPrice :' + weekPrice );
		System.debug( logginglevel.error, '~*~ MonthPrice :' + MonthPrice );
		Map<Decimal, Decimal> newPriceMap = new Map<Decimal, Decimal>{
				dayPrice => 5.000000,
				weekPrice => 20.000000,
				MonthPrice => 60.000000
		};

		for (Pricebook_Line__c pbl : fuel.rentalPricebookLines){
			pbl.Price__c = newPriceMap.get(pbl.Price__c);
		}

		update fuel.rentalPricebookLines;

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,9,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,9,1,0,0,0); // 8/1

		dates.shippedDate = DateTime.newInstance(2017,9,10,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,10,20,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.StdProduct1;
		tdw.billingUOM = fuel.StdMonth;
		tdw.pricingUOM = fuel.StdMonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'WEEKLY' => 6
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		system.assertEquals(12000, returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(12000, invoiceSum.setScale(2, RoundingMode.HALF_UP));

	}


	// Weekly billing uom test with custom pricing on AGL
	testMethod static void test_FixedMonth_ReturnThenInvoice_MonthWeekDay_WeeklyBillingUom_CustomWeeklyPricingUom(){

		/*
			Reccurring SD	Start_Date	End_Date	Range	Total Price
			8/15/2017	8/17/2017	8/22/2017		5		350
			8/22/2017	8/22/2017	8/29/2017		7		380
			8/29/2017	8/29/2017	9/5/2017		7		380
			9/5/2017	9/5/2017	9/12/2017		7		380
			9/12/2017	9/12/2017	9/19/2017		7		380
			9/19/2017	9/19/2017	9/26/2017		7		380
			9/26/2017	9/26/2017	10/3/2017		7		380
			10/3/2017	10/3/2017	10/10/2017		7		380
			10/10/2017	10/10/2017	10/17/2017		7		380
			10/17/2017	10/17/2017	10/24/2017		7		380
			10/24/2017	10/24/2017	10/31/2017		7		380
			10/31/2017	10/31/2017	11/7/2017		7		380
			11/7/2017	11/7/2017	11/14/2017		7		380
			11/14/2017	11/14/2017	11/21/2017		7		380
			11/21/2017	11/21/2017	11/23/2017		2		108.57

															5398.57
															539857.14
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,23,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.SPSProduct;
		tdw.billingUOM = fuel.week;
		tdw.pricingUOM = fuel.week;
		tdw.agreementPrice = 380;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, agreement, dates));
		Map<String,List<SObject>> invoiceData = runInvoicing( (List<Fulfillment__c> ) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		Decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 5,
				'WEEKLY' => 14
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal expectedFulfillmentSum = 539857.14;
		decimal expectedInvoiceSum = 539857.14;
		system.assertEquals(expectedFulfillmentSum,returnSum.setScale(2, RoundingMode.HALF_UP), 'Unit Price difference: ' + (returnSum.setScale(2, RoundingMode.HALF_UP) - expectedFulfillmentSum)/100);
		system.assertEquals(expectedInvoiceSum,invoiceSum.setScale(2, RoundingMode.HALF_UP),  'Unit Price difference: ' + (invoiceSum.setScale(2, RoundingMode.HALF_UP) - expectedInvoiceSum)/100);

	}

	testMethod static void test_FixedMonth_ReturnThenInvoice_MonthWeekDay_WeeklyBillingUom_CustomDailyPricingUom(){

		/*
			Reccurring SD	Start Date	End Date	Range	Total Price
			8/15/2017		8/17/2017	8/22/2017	5		325
			8/22/2017		8/22/2017	8/29/2017	7		400
			8/29/2017		8/29/2017	9/5/2017	7		400
			9/5/2017		9/5/2017	9/12/2017	7		400
			9/12/2017		9/12/2017	9/19/2017	7		400
			9/19/2017		9/19/2017	9/26/2017	7		400
			9/26/2017		9/26/2017	10/3/2017	7		400
			10/3/2017		10/3/2017	10/10/2017	7		400
			10/10/2017		10/10/2017	10/17/2017	7		400
			10/17/2017		10/17/2017	10/24/2017	7		400
			10/24/2017		10/24/2017	10/31/2017	7		400
			10/31/2017		10/31/2017	11/7/2017	7		400
			11/7/2017		11/7/2017	11/14/2017	7		400
			11/14/2017		11/14/2017	11/21/2017	7		400
			11/21/2017		11/21/2017	11/23/2017	2		114.2857143

															5639.285714
															563928.57
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,23,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.SPSProduct;
		tdw.billingUOM = fuel.week;
		tdw.pricingUOM = fuel.day;
		tdw.agreementPrice = 65;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, agreement, dates));
		Map<String,List<SObject>> invoiceData = runInvoicing( (List<Fulfillment__c> ) returnData.get('fulfillments'), dates);

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 5,
				'WEEKLY' => 14
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		Decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		system.assertEquals(563928.57,returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(563928.57,invoiceSum.setScale(2, RoundingMode.HALF_UP));
	}

	testMethod static void test_FixedMonth_ReturnThenInvoice_MonthWeekDay_WeeklyBillingUom(){

		/*
			Reccurring SD	Start Date	End Date	Range	Total Price
			8/15/2017	8/17/2017	8/22/2017		5		350
			8/22/2017	8/22/2017	8/29/2017		7		400
			8/29/2017	8/29/2017	9/5/2017		7		400
			9/5/2017	9/5/2017	9/12/2017		7		400
			9/12/2017	9/12/2017	9/19/2017		7		400
			9/19/2017	9/19/2017	9/26/2017		7		400
			9/26/2017	9/26/2017	10/3/2017		7		400
			10/3/2017	10/3/2017	10/10/2017		7		400
			10/10/2017	10/10/2017	10/17/2017		7		400
			10/17/2017	10/17/2017	10/24/2017		7		400
			10/24/2017	10/24/2017	10/31/2017		7		400
			10/31/2017	10/31/2017	11/7/2017		7		400
			11/7/2017	11/7/2017	11/14/2017		7		400
			11/14/2017	11/14/2017	11/21/2017		7		400
			11/21/2017	11/21/2017	11/23/2017		2		114.28

															5664.28
															566428.57
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.startDate = DateTime.newInstance(2017,8,1,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,17,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,11,23,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.SPSProduct;
		tdw.billingUOM = fuel.week;
		tdw.pricingUOM = fuel.week;
		tdw.agreementPrice = weekPrice;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;
		Fulfillment__c fulfillment = (Fulfillment__c) dataResult.get('fulfillment');
		Agreement__c agreement = (Agreement__c) dataResult.get('agreement');
		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, agreement, dates));
		Map<String,List<SObject>> invoiceData = runInvoicing( (List<Fulfillment__c> ) returnData.get('fulfillments'), dates);


		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'DAILY' => 5,
				'WEEKLY' => 14
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		Decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		decimal expectedFulfillmentSum = 566428.57;
		decimal expectedInvoiceSum = 566428.57;
		system.assertEquals(expectedFulfillmentSum,returnSum.setScale(2, RoundingMode.HALF_UP), 'Unit Price difference: ' + (returnSum.setScale(2, RoundingMode.HALF_UP) - expectedFulfillmentSum)/100);
		system.assertEquals(expectedInvoiceSum,invoiceSum.setScale(2, RoundingMode.HALF_UP),  'Unit Price difference: ' + (invoiceSum.setScale(2, RoundingMode.HALF_UP) - expectedInvoiceSum)/100);

	}


	// No recurrence Date test
	testMethod static void test_FixedMonth_ReturnThenInvoice_MonthWeekDay_NoRecDate(){

		/*
			Start Date	End Date	Range		Unit Price
			8/9/2017	9/6/2017	28			1350.00
			9/6/2017	10/4/2017	28			1350.00
			10/4/2017	10/24/2017	20			964.29

												3664.29
												366428.57
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = null;
		dates.startDate = DateTime.newInstance(2017,8,9,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,9,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,10,24,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.spsProduct;
		tdw.billingUOM = fuel.SPSmonth;
		tdw.pricingUOM = fuel.SPSmonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY' => 3
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		system.assertEquals(366428.57, returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(366428.57, invoiceSum.setScale(2, RoundingMode.HALF_UP));
	}
	
	testMethod static void test_DynamicMonth_ReturnThenInvoice_MonthWeekDay_NoRecDate(){

		/*
			Start Date	End Date	Days	Range	Unit Price
			8/9/2017	9/9/2017	31		31		1350
			9/9/2017	10/9/2017	30		30		1350
			10/9/2017	10/24/2017	31		15		653.23

													3353.23
													335322.58
		 */

		DateWrapper dates = new DateWrapper();
		dates.recurrenceDate = null;
		dates.startDate = DateTime.newInstance(2017,8,9,0,0,0); // 8/1
		dates.shippedDate = DateTime.newInstance(2017,8,9,0,0,0); //8/17
		dates.returnDate = DateTime.newInstance(2017,10,24,0,0,0); // 11/1

		Test.startTest();

		TestDataWrapper tdw = new TestDataWrapper();
		tdw.product = fuel.STDProduct1;
		tdw.billingUOM = fuel.STDmonth;
		tdw.pricingUOM = fuel.STDmonth;
		Map<String, Sobject> dataResult = new CreateData(tdw, dates).resultMap;

		Test.stopTest();

		Map<String,List<SObject>> returnData = processReturn(new ProcessReturnWrapper(100, (Agreement__c) dataResult.get('agreement'), dates));
		Map<String,List<SObject>> invoiceData = runInvoicing((List<Fulfillment__c>) returnData.get('fulfillments'), dates);

		decimal returnSum = getSumTotal(returnData.get('fulfillments'));
		decimal invoiceSum = getSumTotal(invoiceData.get('cilList'));

		Map<String,Integer> correctPricingUomMap = new Map<String,Integer>{
				'MONTHLY2' => 3
		};

		validatePricingUOMs( invoiceData.get('cilList'), correctPricingUomMap);

		system.assertEquals(335322.58, returnSum.setScale(2, RoundingMode.HALF_UP));
		system.assertEquals(335322.58, invoiceSum.setScale(2, RoundingMode.HALF_UP));

	}


	/*
		Unit Testing
	*/

	// Standard
	testMethod static void unitTest_DynamicMonth_CIL_MutipleRanges_Month(){

		map<String, Decimal> correctPrices= new map<String, Decimal>{
				'8/17-9/15'	=> 1283.23,
				'8/23-9/21'	=> 1291.94,
				'8/17-2/23'	=> 8463.94,
				'8/17-9/9'	=> 1013.23,
				'8/16-9/9'	=> 1056.77,
				'8/15-8/15'	=> 43.55,
				'8/1-8/24'	=> 1001.61,
				'8/1-1/24'	=> 7751.61,
				'8/1-10/24'	=> 3701.61,
				'8/15-9/11'	=> 1190.32,
				'8/15-8/16'	=> 43.55,
				'8/1-8/29'	=> 1219.35,
				'8/1-8/23'	=> 958.06,
				'8/1-8/1'	=> 43.55,
				'12/1-12/7' => 261.29
		};

		List<DateWrapper> datesWrapperList = getPrepopulatedDates();


		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for (DateWrapper dates : datesWrapperList){
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.StdProduct4.Id;
			fulfillment.Billing_UOM__r = fuel.StdMonth;
			fulfillment.Billing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = dates.shippedDate;
			fulfillment.End_Date__c = dates.returnDate;
			fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;

			system.assert(fulfillment.Start_Date__c <= fulfillment.End_Date__c, 'Invalid fulfillment dates' + fulfillment);
			fulfillments.add(fulfillment);
		}

		insert fulfillments;

		Customer_Invoice__c ci = new Customer_Invoice__c(
				Source_Key__c = fuel.company.Id + '' + system.now(),
				Company__c = fuel.company.Id,
				Status__c = 'Open',
				Invoice_Type__c = 'Standard',
				Currency__c = fuel.currencyUSD.Id,
				Payment_Term__c = fuel.paymentTerm.Id,
				Bill_To_Customer__c = fuel.customerBillTo.Id,
				Planned_Invoice_Date__c = system.now(),
				Date_Invoiced__c = system.now()
		);
		insert ci;

		List<Customer_Invoice_Line__c> cilList = new List<Customer_Invoice_Line__c>();
		for(Fulfillment__c f : fulfillments) {
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(
					Product__c = f.Product__c,
					Quantity_Shipped__c = f.Quantity__c,
					Company__c = f.company__c,
					Price_Type__c = f.Price_Type__c,
					Pricing_UOM__c = f.Pricing_UOM__c,
					Pricing_UOM__r = f.Pricing_UOM__r,
					Recurrence_Start_Date__c = f.Recurrence_Start_Date__c,
					Customer_Invoice__c = ci.Id,
					Start_Date__c = f.Start_Date__c,
					End_Date__c = f.End_Date__c
			);
			cilList.add(cil);
		}
		insert cilList;


		Integer cilListSize = cilList.size();

		map<String, Decimal> systemPrices = new map<String, Decimal>();

		for(integer i = 0; i < cilListSize; i++) {

			Customer_invoice_line__c cil = cilList[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Customer_Invoice_line__c>{cil}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(cilList[i])) {

				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(cilList[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(cilList[i]);
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				String startDate = fulfillments[i].Start_Date__c.month() + '/' + fulfillments[i].Start_Date__c.day();
				String endDate = fulfillments[i].End_Date__c.month() + '/' + fulfillments[i].End_Date__c.day();
				Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());
				String key = startDate + '-' + endDate;

				systemPrices.put(key, bestPrice.setScale(2, RoundingMode.HALF_UP));

				System.debug( logginglevel.error,PricingService.debugBestPriceString(fulfillments[i], bestPrices) );

//				system.assertEquals(correctPrices.get(key), systemPrices.get(key), 'Off by ' + (systemPrices.get(key) - correctPrices.get(key)) + ' - bestPrice failure (major) - ' + key + ' (' + dayRange + ')');
//				system.assertEquals(correctUnitPrices.get(key), systemUnitPrices.get(key), 'unit price failure (minor) - '  + key + ' (' + dayRange + ')');

			}
		}

		validatePriceMaps(correctPrices, systemPrices);

	}
	testMethod static void unitTest_DynamicMonth_CIL_MutipleRanges_MonthWeekDay(){

		map<String, Decimal> correctUnitPrices = new map<String, Decimal>{
				'8/17-9/15'	=> 	870,
				'8/23-9/21'	=> 	870,
				'8/17-2/23'	=> 	2880.71,
				'8/17-9/9'	=> 	940,
				'8/16-9/9'	=> 	940,
				'8/15-8/15'	=> 	70,
				'8/1-8/24'	=> 	470,
				'8/1-1/24'	=> 	2351.61,
				'8/1-10/24'	=> 	2351.61,
				'8/15-9/11'	=> 	940,
				'8/15-8/16'	=> 	70,
				'8/1-8/29'	=> 	1350,
				'8/1-8/23'	=> 	470,
				'8/1-8/1'	=> 	70,
				'12/1-12/7'	=> 	400
		};

		map<String, Decimal> correctPrices= new map<String, Decimal>{
				'8/17-9/15'	=> 	1670.00,
				'8/23-9/21'	=> 	1740.00,
				'8/17-2/23'	=> 	8680.71,
				'8/17-9/9'	=> 	1340.00,
				'8/16-9/9'	=> 	1410.00,
				'8/15-8/15'	=> 	70.00,
				'8/1-8/24'	=> 	1340.00,
				'8/1-1/24'	=> 	7751.61,
				'8/1-10/24'	=> 	3701.61,
				'8/15-9/11'	=> 	1620.00,
				'8/15-8/16'	=> 	70.00,
				'8/1-8/29'	=> 	1350.00,
				'8/1-8/23'	=> 	1270.00,
				'8/1-8/1'	=> 	70.00,
				'12/1-12/7'	=> 	400.00
		};

		List<DateWrapper> datesWrapperList = getPrepopulatedDates();


		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for (DateWrapper dates : datesWrapperList){
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.StdProduct1.Id;
			fulfillment.Billing_UOM__r = fuel.StdMonth;
			fulfillment.Billing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = dates.shippedDate;
			fulfillment.End_Date__c = dates.returnDate;
			fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;

			system.assert(fulfillment.Start_Date__c <= fulfillment.End_Date__c, 'Invalid fulfillment dates' + fulfillment);
			fulfillments.add(fulfillment);
		}

		insert fulfillments;

		Customer_Invoice__c ci = new Customer_Invoice__c(
				Source_Key__c = fuel.company.Id + '' + system.now(),
				Company__c = fuel.company.Id,
				Status__c = 'Open',
				Invoice_Type__c = 'Standard',
				Currency__c = fuel.currencyUSD.Id,
				Payment_Term__c = fuel.paymentTerm.Id,
				Bill_To_Customer__c = fuel.customerBillTo.Id,
				Planned_Invoice_Date__c = system.now(),
				Date_Invoiced__c = system.now()
		);
		insert ci;

		List<Customer_Invoice_Line__c> cilList = new List<Customer_Invoice_Line__c>();
		for(Fulfillment__c f : fulfillments) {
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(
					Product__c = f.Product__c,
					Quantity_Shipped__c = f.Quantity__c,
					Company__c = f.company__c,
					Price_Type__c = f.Price_Type__c,
					Pricing_UOM__c = f.Pricing_UOM__c,
					Pricing_UOM__r = f.Pricing_UOM__r,
					Recurrence_Start_Date__c = f.Recurrence_Start_Date__c,
					Customer_Invoice__c = ci.Id,
					Start_Date__c = f.Start_Date__c,
					End_Date__c = f.End_Date__c
			);
			cilList.add(cil);
		}
		insert cilList;

		Integer cilListSize = cilList.size();

		map<String, Decimal> systemUnitPrices = new map<String, Decimal>();
		map<String, Decimal> systemPrices = new map<String, Decimal>();

		for(integer i = 0; i < cilListSize; i++) {

			Customer_invoice_line__c cil = cilList[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Customer_Invoice_line__c>{cil}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(cilList[i])) {

				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(cilList[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(cilList[i]);
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				String startDate = fulfillments[i].Start_Date__c.month() + '/' + fulfillments[i].Start_Date__c.day();
				String endDate = fulfillments[i].End_Date__c.month() + '/' + fulfillments[i].End_Date__c.day();
				Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());
				String key = startDate + '-' + endDate;


				systemUnitPrices.put(key, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(key, bestPrice.setScale(2, RoundingMode.HALF_UP));

				System.debug( logginglevel.error, '\n\n\n~*~ (' + dayRange + ') ' + key + ' - ' + ' bestUnitPrice :' + bestUnitPrice + ', bestPrice: ' + bestPrice.setScale(2, RoundingMode.HALF_UP));
				System.debug( logginglevel.error,PricingService.debugBestPriceString(fulfillments[i], bestPrices) );

//				system.assertEquals(correctPrices.get(key), systemPrices.get(key), 'Off by ' + (systemPrices.get(key) - correctPrices.get(key)) + ' - bestPrice failure (major) - ' + key + ' (' + dayRange + ') days, iteration: ' + i);
//				system.assertEquals(correctUnitPrices.get(key), systemUnitPrices.get(key), 'unit price failure (minor) - '  + key + ' (' + dayRange + ') days, iteration: ' + i);

			}
		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);

	}
	testMethod static void unitTest_DynamicMonth_CIL_MonthWeekDay(){

		map<Integer, Decimal> correctUnitPrices = new map<Integer, Decimal>{
				1 => dayPrice,
				2 => dayPrice,
				3 => dayPrice,
				4 => dayPrice,
				5 => dayPrice,
				6 => weekPrice,
				7 => weekPrice,
				8 => weekPrice + dayPrice,
				9 => weekPrice + dayPrice,
				10 => weekPrice + dayPrice,
				11 => weekPrice + dayPrice,
				12 => weekPrice + dayPrice,
				13 => weekPrice,
				14 => weekPrice,
				15 => weekPrice + dayPrice,
				16 => weekPrice + dayPrice,
				17 => weekPrice + dayPrice,
				18 => weekPrice + dayPrice,
				19 => weekPrice + dayPrice,
				20 => weekPrice,
				21 => weekPrice,
				22 => weekPrice + dayPrice,
				23 => weekPrice + dayPrice,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => monthPrice,
				30 => monthPrice,
				31 => monthPrice,
				32 => monthPrice + (monthPrice / 30 * 1).setScale(2, RoundingMode.HALF_UP),
				33 => monthPrice + (monthPrice / 30 * 2).setScale(2, RoundingMode.HALF_UP),
				34 => monthPrice + (monthPrice / 30 * 3).setScale(2, RoundingMode.HALF_UP)
		};

		map<Integer, Decimal> correctPrices= new map<Integer, Decimal>{
				1  => dayPrice * 1,
				2  => dayPrice * 2,
				3  => dayPrice * 3,
				4  => dayPrice * 4,
				5  => dayPrice * 5,
				6  => weekPrice,
				7  => weekPrice,
				8  => weekprice + dayPrice * 1,
				9  => weekprice + dayPrice * 2,
				10 => weekprice + dayPrice * 3,
				11 => weekprice + dayPrice * 4,
				12 => weekprice + dayPrice * 5,
				13 => weekprice * 2,
				14 => weekprice * 2,
				15 => weekprice * 2 + dayPrice * 1,
				16 => weekprice * 2 + dayPrice * 2,
				17 => weekprice * 2 + dayPrice * 3,
				18 => weekprice * 2 + dayPrice * 4,
				19 => weekprice * 2 + dayPrice * 5,
				20 => weekprice * 3,
				21 => weekprice * 3,
				22 => weekprice * 3 + dayPrice * 1,
				23 => weekprice * 3 + dayPrice * 2,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => monthPrice,
				30 => monthPrice,
				31 => monthPrice,
				32 => (monthPrice + (monthPrice / 30 * 1)).setScale(2, RoundingMode.HALF_UP), // prorate 1 day
				33 => (monthPrice + (monthPrice / 30 * 2)).setScale(2, RoundingMode.HALF_UP), // prorate 2 day
				34 => (monthPrice + (monthPrice / 30 * 3)).setScale(2, RoundingMode.HALF_UP)  // prorate 3 day

		};

		DateTime startDate = DateTime.newInstance(2017,8,1,0,0,0);
		DateTime recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0);

		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for(Integer i = 1; i <= 34; i++) {
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.STDProduct1.Id;
			fulfillment.Billing_UOM__c = fuel.STDmonth.Id;
			fulfillment.Billing_UOM__r = fuel.STDmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Recurrence_Start_Date__c = recurrenceDate;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = startDate;
			fulfillment.End_Date__c = startDate.addDays(i);
			fulfillments.add(fulfillment);
		}
		insert fulfillments;

		Customer_Invoice__c ci = new Customer_Invoice__c(
				Source_Key__c = fuel.company.Id + '' + system.now(),
				Company__c = fuel.company.Id,
				Status__c = 'Open',
				Invoice_Type__c = 'Standard',
				Currency__c = fuel.currencyUSD.Id,
				Payment_Term__c = fuel.paymentTerm.Id,
				Bill_To_Customer__c = fuel.customerBillTo.Id,
				Planned_Invoice_Date__c = system.now(),
				//				Sales_Order__c = container.salesOrderId,
				//				Agreement__c = container.agreementId
				Date_Invoiced__c = system.now()
		);
		insert ci;

		List<Customer_Invoice_Line__c> cilList = new List<Customer_Invoice_Line__c>();
		for(Fulfillment__c f : fulfillments) {
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(
					Product__c = f.Product__c,
					Quantity_Shipped__c = f.Quantity__c,
					Company__c = f.company__c,
					Price_Type__c = f.Price_Type__c,
					Pricing_UOM__c = f.Pricing_UOM__c,
					Pricing_UOM__r = f.Pricing_Uom__r,
					Recurrence_Start_Date__c = f.Recurrence_Start_Date__c,
					Customer_Invoice__c = ci.Id,
					//				Agreement_Line__c = container.agreementId != null ? f.Agreement_Line__c : null,
					//				Agreement_Line__r = f.Agreement_Line__c != null ? f.Agreement_Line__r : null, // KNDY-19504
					//				Agreement__c = container.agreementId != null ? container.agreementId : null,
					//				Sales_Order__c = f.Sales_Order_Line__r.Sales_Order__c,
					//				Sales_Order_Line__c = f.Sales_Order_Line__c,
					//				Sales_Order_Line__r = f.Sales_Order_Line__r,
					Start_Date__c = f.Start_Date__c,
					End_Date__c = f.End_Date__c
			);
			cilList.add(cil);
		}
		insert cilList;

		Integer cilListSize = cilList.size();
		System.debug( logginglevel.error, '~*~ cilListSize :' + cilListSize );

		map<Integer, Decimal> systemUnitPrices = new map<Integer, Decimal>();
		map<Integer, Decimal> systemPrices = new map<Integer, Decimal>();

		for(integer i = 0; i < cilListSize; i++) {

			Customer_Invoice_Line__c cil = cilList[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Customer_invoice_line__c>{cil}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(cilList[i])) {
				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(cilList[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(cilList[i]);
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				Integer dayIndex = i+1;

				systemUnitPrices.put(dayIndex, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(dayIndex, bestPrice.setScale(2, RoundingMode.HALF_UP));


				System.debug( logginglevel.error, '~*~ bestUnitPrice :' + dayIndex + '-  ' + bestUnitPrice );
				System.debug( logginglevel.error, '~*~ bestPrice :' + dayIndex + '-  ' + bestPrice.setScale(2, RoundingMode.HALF_UP) + '\n');

//				system.assertEquals(correctUnitPrices.get(dayIndex), systemUnitPrices.get(dayIndex), dayIndex);
//				system.assertEquals(correctPrices.get(dayIndex), systemPrices.get(dayIndex), dayIndex);
			} else {
				system.assert(false, 'indexing error: ' + i + ' ' + cilListSize);
			}
		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);

	}

	// SPS
	testMethod static void unitTest_FixedMonth_CIL_MutipleRanges_MonthWeekDay(){


		map<String, Decimal> correctUnitPrices = new map<String, Decimal>{
				'8/17-9/15' => 940, // even though there is no month value, we store the priceresult with 0 bestPrice and 0 unitprice to capture the proratevalue. Diff is 29, Fd is 12, md is 0, ld is 17
				'8/23-9/21' => 870,
				'8/17-2/23' => 2302.14, // Diff is 190, Fd-Md-Ld is 12-168-10     (first day, mid day, last day segments)
				'8/17-9/9' => 940, // special case. bestprice run twice on first cycle and then  2nd because total range is less than interval range, but it crosses over the recurrence date
				'8/16-9/9' => 870,
				'8/15-8/15' => 70,
				'8/1-8/24' => 470,
				'8/1-1/24' => 1735.71,
				'8/1-10/24' => 1350,
				'8/15-9/11' => 800,
				'8/15-8/16' => 70,
				'8/1-8/29' => 1350,
				'8/1-8/23' => 470,
				'8/1-8/1' => 70,
				'12/1-12/7' => 400
		};

		map<String, Decimal> correctPrices= new map<String, Decimal>{
				'8/17-9/15' => 1760,
				'8/23-9/21' => 1740,
				'8/17-2/23' => 9332.14,
				'8/17-9/9' => 1430,
				'8/16-9/9' => 1480,
				'8/15-8/15' => 70,
				'8/1-8/24' => 1340,
				'8/1-1/24' => 8485.71,
				'8/1-10/24' => 4050,
				'8/15-9/11' => 1600,
				'8/15-8/16' => 70,
				'8/1-8/29' => 1350,
				'8/1-8/23' => 1270,
				'8/1-8/1' => 70,
				'12/1-12/7' => 400
		};

		List<DateWrapper> datesWrapperList = getPrepopulatedDates();


		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for (DateWrapper dates : datesWrapperList){
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.SPSProduct.Id;
			fulfillment.Billing_UOM__r = fuel.SPSMonth;
			fulfillment.Billing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = dates.shippedDate;
			fulfillment.End_Date__c = dates.returnDate;
			fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;

			system.assert(fulfillment.Start_Date__c <= fulfillment.End_Date__c, 'Invalid fulfillment dates' + fulfillment);
			fulfillments.add(fulfillment);
		}

		insert fulfillments;

		Customer_Invoice__c ci = new Customer_Invoice__c(
				Source_Key__c = fuel.company.Id + '' + system.now(),
				Company__c = fuel.company.Id,
				Status__c = 'Open',
				Invoice_Type__c = 'Standard',
				Currency__c = fuel.currencyUSD.Id,
				Payment_Term__c = fuel.paymentTerm.Id,
				Bill_To_Customer__c = fuel.customerBillTo.Id,
				Planned_Invoice_Date__c = system.now(),
				Date_Invoiced__c = system.now()
		);
		insert ci;

		List<Customer_Invoice_Line__c> cilList = new List<Customer_Invoice_Line__c>();
		for(Fulfillment__c f : fulfillments) {
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(
					Product__c = f.Product__c,
					Quantity_Shipped__c = f.Quantity__c,
					Company__c = f.company__c,
					Price_Type__c = f.Price_Type__c,
					Pricing_UOM__c = f.Pricing_UOM__c,
					Pricing_UOM__r = f.Pricing_UOM__r,
					Recurrence_Start_Date__c = f.Recurrence_Start_Date__c,
					Customer_Invoice__c = ci.Id,
					Start_Date__c = f.Start_Date__c,
					End_Date__c = f.End_Date__c
			);
			cilList.add(cil);
		}
		insert cilList;


		Integer cilListSize = cilList.size();

		map<String, Decimal> systemUnitPrices = new map<String, Decimal>();
		map<String, Decimal> systemPrices = new map<String, Decimal>();

		for(integer i = 0; i < cilListSize; i++) {

			Customer_invoice_line__c cil = cilList[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Customer_Invoice_line__c>{cil}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(cilList[i])) {

				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(cilList[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(cilList[i]);
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				String startDate = fulfillments[i].Start_Date__c.month() + '/' + fulfillments[i].Start_Date__c.day();
				String endDate = fulfillments[i].End_Date__c.month() + '/' + fulfillments[i].End_Date__c.day();
				Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());
				String key = startDate + '-' + endDate;


				systemUnitPrices.put(key, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(key, bestPrice.setScale(2, RoundingMode.HALF_UP));

				System.debug( logginglevel.error, '\n\n\n~*~ (' + dayRange + ') ' + key + ' - ' + ' bestUnitPrice :' + bestUnitPrice + ', bestPrice: ' + bestPrice.setScale(2, RoundingMode.HALF_UP));
				system.debug( logginglevel.error,PricingService.debugBestPriceString(fulfillments[i], bestPrices) );

//				system.assertEquals(correctPrices.get(key), systemPrices.get(key), 'Off by ' + (systemPrices.get(key) - correctPrices.get(key)) + ' - bestPrice failure (major) - ' + key + ' (' + dayRange + ') days, iteration: ' + i);
//				system.assertEquals(correctUnitPrices.get(key), systemUnitPrices.get(key), 'unit price failure (minor) - '  + key + ' (' + dayRange + ') days, iteration: ' + i);

			}
		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);
	}
	testMethod static void unitTest_FixedMonth_CIL_MonthWeekDay(){

		map<Integer, Decimal> correctUnitPrices = new map<Integer, Decimal>{
				1 => dayPrice,
				2 => dayPrice,
				3 => dayPrice,
				4 => dayPrice,
				5 => dayPrice,
				6 => weekPrice,
				7 => weekPrice,
				8 => weekPrice + dayPrice,
				9 => weekPrice + dayPrice,
				10 => weekPrice + dayPrice,
				11 => weekPrice + dayPrice,
				12 => weekPrice + dayPrice,
				13 => weekPrice,
				14 => weekPrice,
				15 => weekPrice + dayPrice,
				16 => weekPrice + dayPrice,
				17 => weekPrice + dayPrice,
				18 => weekPrice + dayPrice,
				19 => weekPrice + dayPrice,
				20 => weekPrice,
				21 => weekPrice,
				22 => weekPrice + dayPrice,
				23 => weekPrice + dayPrice,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => monthPrice + (monthPrice / 28 * 1).setScale(2, RoundingMode.HALF_UP),
				30 => monthPrice + (monthPrice / 28 * 2).setScale(2, RoundingMode.HALF_UP),
				31 => monthPrice + (monthPrice / 28 * 3).setScale(2, RoundingMode.HALF_UP)
		};

		map<Integer, Decimal> correctPrices= new map<Integer, Decimal>{
				1  => dayPrice * 1,
				2  => dayPrice * 2,
				3  => dayPrice * 3,
				4  => dayPrice * 4,
				5  => dayPrice * 5,
				6  => weekPrice,
				7  => weekPrice,
				8  => weekprice + dayPrice * 1,
				9  => weekprice + dayPrice * 2,
				10 => weekprice + dayPrice * 3,
				11 => weekprice + dayPrice * 4,
				12 => weekprice + dayPrice * 5,
				13 => weekprice * 2,
				14 => weekprice * 2,
				15 => weekprice * 2 + dayPrice * 1,
				16 => weekprice * 2 + dayPrice * 2,
				17 => weekprice * 2 + dayPrice * 3,
				18 => weekprice * 2 + dayPrice * 4,
				19 => weekprice * 2 + dayPrice * 5,
				20 => weekprice * 3,
				21 => weekprice * 3,
				22 => weekprice * 3 + dayPrice * 1,
				23 => weekprice * 3 + dayPrice * 2,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => (monthPrice + (monthPrice / 28 * 1)).setScale(2, RoundingMode.HALF_UP), // prorate 1 day
				30 => (monthPrice + (monthPrice / 28 * 2)).setScale(2, RoundingMode.HALF_UP), // prorate 2 day
				31 => (monthPrice + (monthPrice / 28 * 3)).setScale(2, RoundingMode.HALF_UP)  // prorate 3 day
		};


		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();

		for(Integer i = 1; i <= 31; i++) {
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.SPSProduct.Id;
			fulfillment.Billing_UOM__c = fuel.SPSmonth.Id;
			fulfillment.Billing_UOM__r = fuel.SPSmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = System.now();
			fulfillment.End_Date__c = system.now().addDays(i);
			fulfillments.add(fulfillment);
		}
		insert fulfillments;

		Customer_Invoice__c ci = new Customer_Invoice__c(
				Source_Key__c = fuel.company.Id + '' + system.now(),
				Company__c = fuel.company.Id,
				Status__c = 'Open',
				Invoice_Type__c = 'Standard',
				Currency__c = fuel.currencyUSD.Id,
				Payment_Term__c = fuel.paymentTerm.Id,
				Bill_To_Customer__c = fuel.customerBillTo.Id,
				Planned_Invoice_Date__c = system.now(),
				//				Sales_Order__c = container.salesOrderId,
				//				Agreement__c = container.agreementId
				Date_Invoiced__c = system.now()
		);
		insert ci;

		List<Customer_Invoice_Line__c> cilList = new List<Customer_Invoice_Line__c>();
		for(Fulfillment__c f : fulfillments) {
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(
					Product__c = f.Product__c,
					Quantity_Shipped__c = f.Quantity__c,
					Company__c = f.company__c,
					Price_Type__c = f.Price_Type__c,
					Pricing_UOM__c = f.Pricing_UOM__c,
					Pricing_UOM__r = f.Pricing_Uom__r,
					Recurrence_Start_Date__c = f.Recurrence_Start_Date__c,
					Customer_Invoice__c = ci.Id,
					//				Agreement_Line__c = container.agreementId != null ? f.Agreement_Line__c : null,
					//				Agreement_Line__r = f.Agreement_Line__c != null ? f.Agreement_Line__r : null, // KNDY-19504
					//				Agreement__c = container.agreementId != null ? container.agreementId : null,
					//				Sales_Order__c = f.Sales_Order_Line__r.Sales_Order__c,
					//				Sales_Order_Line__c = f.Sales_Order_Line__c,
					//				Sales_Order_Line__r = f.Sales_Order_Line__r,
					Start_Date__c = f.Start_Date__c,
					End_Date__c = f.End_Date__c
			);
			cilList.add(cil);
		}
		insert cilList;


		Integer cilListSize = cilList.size();
		System.debug( logginglevel.error, '~*~ cilListSize :' + cilListSize );

		map<Integer, Decimal> systemUnitPrices = new map<Integer, Decimal>();
		map<Integer, Decimal> systemPrices = new map<Integer, Decimal>();

		for(integer i = 0; i < cilListSize; i++) {

			Customer_Invoice_Line__c cil = cilList[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Customer_invoice_line__c>{cil}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(cilList[i])) {
				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(cilList[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(cilList[i]);
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				Integer dayIndex = i+1;

				systemUnitPrices.put(dayIndex, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(dayIndex, bestPrice.setScale(2, RoundingMode.HALF_UP));


				System.debug( logginglevel.error, '~*~ bestUnitPrice :' + dayIndex + '-  ' + bestUnitPrice );
				System.debug( logginglevel.error, '~*~ bestPrice :' + dayIndex + '-  ' + bestPrice.setScale(2, RoundingMode.HALF_UP) + '\n');

//				system.assertEquals(correctUnitPrices.get(dayIndex), systemUnitPrices.get(dayIndex), dayIndex);
//				system.assertEquals(correctPrices.get(dayIndex), systemPrices.get(dayIndex), dayIndex);
			} else {
				system.assert(false, 'indexing error: ' + i + ' ' + cilListSize);
			}
		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);

	}

	/*
		Fulfillment Best Price
	 */
	// Standard
	testMethod static void unitTest_DynamicMonth_Fulfillment_BestPrice_MutipleRanges_Month(){

		map<String, Decimal> correctPrices= new map<String, Decimal>{
			'8/17-9/15'	=> 1283.23,
			'8/23-9/21'	=> 1291.94,
			'8/17-2/23'	=> 8463.94,
			'8/17-9/9'	=> 1013.23,
			'8/16-9/9'	=> 1056.77,
			'8/15-8/15'	=> 43.55,
			'8/1-8/24'	=> 1001.61,
			'8/1-1/24'	=> 7751.61,
			'8/1-10/24'	=> 3701.61,
			'8/15-9/11'	=> 1190.32,
			'8/15-8/16'	=> 43.55,
			'8/1-8/29'	=> 1219.35,
			'8/1-8/23'	=> 958.06,
			'8/1-8/1'	=> 43.55,
			'12/1-12/7' => 261.29
		};


		List<DateWrapper> datesWrapperList = getPrepopulatedDates();

		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for (DateWrapper dates : datesWrapperList){
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.StdProduct4.Id;
			fulfillment.Billing_UOM__c = fuel.StdMonth.Id;
			fulfillment.Billing_UOM__r = fuel.StdMonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = dates.shippedDate;
			fulfillment.End_Date__c = dates.returnDate;
			fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;

			system.assert(fulfillment.Start_Date__c <= fulfillment.End_Date__c, 'Invalid fulfillment dates' + fulfillment);
			fulfillments.add(fulfillment);

		}

		insert fulfillments;

		SOQLUtil query = new SOQLUtil('Fulfillment__c', true);
		query.addFields(Fulfillment__c.getSobjectType().getDescribe().fields.getMap().keySet());
		query.addFields(new Set<String>{'Sales_Order_Line__r.Pricebook__c', 'Sales_Order_Line__r.Customer_ID__c'});
		fulfillments = Database.query(query.getQuery());

		Integer fulfillmentsSize = fulfillments.size();

		map<String, Decimal> systemPrices = new map<String, Decimal>();

		System.debug( logginglevel.error, '\n\n');
		System.debug( logginglevel.error, '~*~ Start Processing Prices \n\n');

		for(integer i = 0; i < fulfillmentsSize; i++) {
			Fulfillment__c ful = fulfillments[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Fulfillment__c>{ful}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);
			List<PricingService.PricingResult> bestPrices = mBestPrices.get(ful);

			decimal bestPrice = 0;
			decimal bestUnitPrice = 0;

			for(PricingService.PricingResult d : bestPrices) {
				if(bestUnitPrice == null && bestPrice == null) {
					bestPrice = d.bestPrice;
					bestUnitPrice = d.unitPrice;
				} else {
					bestPrice += d.bestPrice;
					bestUnitPrice += d.unitPrice;
				}
			}

			String startDate = fulfillments[i].Start_Date__c.month() + '/' + fulfillments[i].Start_Date__c.day();
			String endDate = fulfillments[i].End_Date__c.month() + '/' + fulfillments[i].End_Date__c.day();
			Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());
			String key = startDate + '-' + endDate;

			systemPrices.put(key, bestPrice.setScale(2, RoundingMode.HALF_UP));

			System.debug( logginglevel.error, '\n\n\n~*~ (' + dayRange + ') ' + key + ' - ' + ' bestUnitPrice :' + bestUnitPrice + ', bestPrice: ' + bestPrice.setScale(2, RoundingMode.HALF_UP));
			system.debug( logginglevel.error, PricingService.debugBestPriceString(fulfillments[i], bestPrices) );

//			system.assertEquals(correctPrices.get(key), systemPrices.get(key), 'Off by ' + (systemPrices.get(key) - correctPrices.get(key)) + ' - bestPrice failure (major) - ' + key + ' (' + dayRange + ')');

		}

		validatePriceMaps(correctPrices, systemPrices);
	}
	testMethod static void unitTest_DynamicMonth_Fulfillment_BestPrice_MutipleRanges_MonthWeekDay() {

		map<String, Decimal> correctUnitPrices = new map<String, Decimal>{
				'8/17-9/15' => 940, // even though there is no month value, we store the priceresult with 0 bestPrice and 0 unitprice to capture the proratevalue. Diff is 29, Fd is 12, md is 0, ld is 17
				'8/23-9/21' => 870,
				'8/17-2/23' => 2302.14, // Diff is 190, Fd-Md-Ld is 12-168-10     (first day, mid day, last day segments)
				'8/17-9/9' => 940, // special case. bestprice run twice on first cycle and then  2nd because total range is less than interval range, but it crosses over the recurrence date
				'8/16-9/9' => 870,
				'8/15-8/15' => 70,
				'8/1-8/24' => 470,
				'8/1-1/24' => 1735.71,
				'8/1-10/24' => 1350,
				'8/15-9/11' => 800,
				'8/15-8/16' => 70,
				'8/1-8/29' => 1350,
				'8/1-8/23' => 470,
				'8/1-8/1' => 70,
				'12/1-12/7' => 400
		};

		map<String, Decimal> correctPrices= new map<String, Decimal>{
				'8/17-9/15' => 1760,
				'8/23-9/21' => 1740,
				'8/17-2/23' => 9332.14,
				'8/17-9/9' => 1430,
				'8/16-9/9' => 1480,
				'8/15-8/15' => 70,
				'8/1-8/24' => 1340,
				'8/1-1/24' => 8485.71,
				'8/1-10/24' => 4050,
				'8/15-9/11' => 1600,
				'8/15-8/16' => 70,
				'8/1-8/29' => 1350,
				'8/1-8/23' => 1270,
				'8/1-8/1' => 70,
				'12/1-12/7' => 400
		};

		List<DateWrapper> datesWrapperList = getPrepopulatedDates();

		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for (DateWrapper dates : datesWrapperList){
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.SPSProduct.Id;
			fulfillment.Billing_UOM__c = fuel.SPSmonth.Id;
			fulfillment.Billing_UOM__r = fuel.SPSmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = dates.shippedDate;
			fulfillment.End_Date__c = dates.returnDate;
			fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;

			system.assert(fulfillment.Start_Date__c <= fulfillment.End_Date__c, 'Invalid fulfillment dates' + fulfillment);
			fulfillments.add(fulfillment);

		}

		insert fulfillments;

		SOQLUtil query = new SOQLUtil('Fulfillment__c', true);
		query.addFields(Fulfillment__c.getSobjectType().getDescribe().fields.getMap().keySet());
		query.addFields(new Set<String>{'Sales_Order_Line__r.Pricebook__c', 'Sales_Order_Line__r.Customer_ID__c'});
		fulfillments = Database.query(query.getQuery());

		Integer fulfillmentsSize = fulfillments.size();

		map<String, Decimal> systemUnitPrices = new map<String, Decimal>();
		map<String, Decimal> systemPrices = new map<String, Decimal>();

		System.debug( logginglevel.error, '\n\n');
		System.debug( logginglevel.error, '~*~ Start Processing Prices \n\n');

		for(integer i = 0; i < fulfillmentsSize; i++) {
			Fulfillment__c ful = fulfillments[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Fulfillment__c>{ful}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);
			List<PricingService.PricingResult> bestPrices = mBestPrices.get(ful);

			decimal bestPrice = 0;
			decimal bestUnitPrice = 0;

			for(PricingService.PricingResult d : bestPrices) {
				if(bestUnitPrice == null && bestPrice == null) {
					bestPrice = d.bestPrice;
					bestUnitPrice = d.unitPrice;
				} else {
					bestPrice += d.bestPrice;
					bestUnitPrice += d.unitPrice;
				}
			}

			String startDate = fulfillments[i].Start_Date__c.month() + '/' + fulfillments[i].Start_Date__c.day();
			String endDate = fulfillments[i].End_Date__c.month() + '/' + fulfillments[i].End_Date__c.day();
			Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());
			String key = startDate + '-' + endDate;


			systemUnitPrices.put(key, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
			systemPrices.put(key, bestPrice.setScale(2, RoundingMode.HALF_UP));

			System.debug( logginglevel.error, '\n\n\n~*~ (' + dayRange + ') ' + key + ' - ' + ' bestUnitPrice :' + bestUnitPrice + ', bestPrice: ' + bestPrice.setScale(2, RoundingMode.HALF_UP));
			system.debug( logginglevel.error,PricingService.debugBestPriceString(fulfillments[i], bestPrices) );

//			system.assertEquals(correctPrices.get(key), systemPrices.get(key), 'Off by ' + (systemPrices.get(key) - correctPrices.get(key)) + ' - bestPrice failure (major) - ' + key + ' (' + dayRange + ')');
//			system.assertEquals(correctUnitPrices.get(key), systemUnitPrices.get(key), 'unit price failure (minor) - '  + key + ' (' + dayRange + ')');

		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);

	}

	testMethod static void unitTest_DynamicMonth_Fulfillment_BestPrice_Month_InvoiceAhead() {

		DateTime startDate = DateTime.newInstance(2018,1,1,0,0,0);
		DateTime endDate = DateTime.newInstance(2018,2,1,0,0,0);
		DateTime reccurrenceDate = DateTime.newInstance(2018,1,1,0,0,0);

		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();

		Product__c prod = fuel.STDProduct4;

		List<Pricebook_Line__c> pblList = [select id, price__c from Pricebook_line__c where product__c =: prod.Id];
		for (Pricebook_line__c pbl : pblList){
			pbl.Price__c = 300;
		}
		update pblList;

		for(Integer i = 1; i <= 34; i++) {
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Invoice_Ahead__c = True;
			fulfillment.Product__c = prod.Id;
			fulfillment.Billing_UOM__c = fuel.STDmonth.Id;
			fulfillment.Billing_UOM__r = fuel.STDmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = endDate.addDays(-i);
			fulfillment.End_Date__c = endDate;
			fulfillment.Recurrence_Start_Date__c = reccurrenceDate;
			fulfillments.add(fulfillment);
		}

		insert fulfillments;

		SOQLUtil query = new SOQLUtil('Fulfillment__c', true);
		query.addFields(Fulfillment__c.getSobjectType().getDescribe().fields.getMap().keySet());
		query.addFields(new Set<String>{'Sales_Order_Line__r.Pricebook__c', 'Sales_Order_Line__r.Customer_ID__c'});
		fulfillments = Database.query(query.getQuery());

		Integer fulfillmentsSize = fulfillments.size();
		System.debug( logginglevel.error, '~*~ fulfillmentsSize :' + fulfillmentsSize );

		map<Integer, Decimal> systemUnitPrices = new map<Integer, Decimal>();
		map<Integer, Decimal> systemPrices = new map<Integer, Decimal>();

		for(integer i = 0; i < fulfillmentsSize; i++) {
			Fulfillment__c fulfillment = fulfillments[i];
			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Fulfillment__c>{fulfillment}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(fulfillments[i])) {
				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(fulfillments[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(fulfillments[i]);
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '\n' + '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());


				systemUnitPrices.put(dayRange, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(dayRange, bestPrice.setScale(2, RoundingMode.HALF_UP));

				System.debug( logginglevel.error, '~*~  Dates: ' + fulfillments[i].Start_Date__c.date() + ' to ' + fulfillments[i].End_Date__c.date() );
				System.debug( logginglevel.error, '~*~ bestUnitPrice :' + (i+1) + ' ' + dayRange + '-  ' + bestUnitPrice );
				System.debug( logginglevel.error, '~*~ bestPrice :' + (i+1) + ' ' + dayRange + '-  ' + bestPrice.setScale(2, RoundingMode.HALF_UP) + '\n');

			}
		}

//		validatePriceMaps(correctPrices, systemPrices);
//		validatePriceMaps(correctUnitPrices, systemUnitPrices);
	}
	testMethod static void unitTest_DynamicMonth_Fulfillment_BestPrice_MonthWeekDay() {

		map<Integer, Decimal> correctUnitPrices = new map<Integer, Decimal>{
				1 => dayPrice,
				2 => dayPrice,
				3 => dayPrice,
				4 => dayPrice,
				5 => dayPrice,
				6 => weekPrice,
				7 => weekPrice,
				8 => weekPrice + dayPrice,
				9 => weekPrice + dayPrice,
				10 => weekPrice + dayPrice,
				11 => weekPrice + dayPrice,
				12 => weekPrice + dayPrice,
				13 => weekPrice,
				14 => weekPrice,
				15 => weekPrice + dayPrice,
				16 => weekPrice + dayPrice,
				17 => weekPrice + dayPrice,
				18 => weekPrice + dayPrice,
				19 => weekPrice + dayPrice,
				20 => weekPrice,
				21 => weekPrice,
				22 => weekPrice + dayPrice,
				23 => weekPrice + dayPrice,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => monthPrice,
				30 => monthPrice,
				31 => monthPrice,
				32 => (monthPrice + (monthPrice / 30 * 1)).setScale(2, RoundingMode.HALF_UP), // prorate 1 day
				33 => (monthPrice + (monthPrice / 30 * 2)).setScale(2, RoundingMode.HALF_UP), // prorate 1 day
				34 => (monthPrice + (monthPrice / 30 * 3)).setScale(2, RoundingMode.HALF_UP) // prorate 1 day
		};

		map<Integer, Decimal> correctPrices= new map<Integer, Decimal>{
				1  => dayPrice * 1,
				2  => dayPrice * 2,
				3  => dayPrice * 3,
				4  => dayPrice * 4,
				5  => dayPrice * 5,
				6  => weekPrice,
				7  => weekPrice,
				8  => weekprice + dayPrice * 1,
				9  => weekprice + dayPrice * 2,
				10 => weekprice + dayPrice * 3,
				11 => weekprice + dayPrice * 4,
				12 => weekprice + dayPrice * 5,
				13 => weekprice * 2,
				14 => weekprice * 2,
				15 => weekprice * 2 + dayPrice * 1,
				16 => weekprice * 2 + dayPrice * 2,
				17 => weekprice * 2 + dayPrice * 3,
				18 => weekprice * 2 + dayPrice * 4,
				19 => weekprice * 2 + dayPrice * 5,
				20 => weekprice * 3,
				21 => weekprice * 3,
				22 => weekprice * 3 + dayPrice * 1,
				23 => weekprice * 3 + dayPrice * 2,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => monthPrice,
				30 => monthPrice,
				31 => monthPrice,
				32 => (monthPrice + (monthPrice / 30 * 1)).setScale(2, RoundingMode.HALF_UP), // prorate 1 day
				33 => (monthPrice + (monthPrice / 30 * 2)).setScale(2, RoundingMode.HALF_UP), // prorate 2 day
				34 => (monthPrice + (monthPrice / 30 * 3)).setScale(2, RoundingMode.HALF_UP)  // prorate 3 day
		};

		DateTime startDate = DateTime.newInstance(2017,8,1,0,0,0);
		DateTime reccurrenceDate = DateTime.newInstance(2017,8,1,0,0,0);

		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();

		for(Integer i = 1; i <= 34; i++) {
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.STDProduct1.Id;
			fulfillment.Billing_UOM__c = fuel.STDmonth.Id;
			fulfillment.Billing_UOM__r = fuel.STDmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = startDate;
			fulfillment.End_Date__c = startDate.addDays(i);
			fulfillment.Recurrence_Start_Date__c = reccurrenceDate;
			fulfillments.add(fulfillment);
		}

		insert fulfillments;

		SOQLUtil query = new SOQLUtil('Fulfillment__c', true);
		query.addFields(Fulfillment__c.getSobjectType().getDescribe().fields.getMap().keySet());
		query.addFields(new Set<String>{'Sales_Order_Line__r.Pricebook__c', 'Sales_Order_Line__r.Customer_ID__c'});
		fulfillments = Database.query(query.getQuery());

		Integer fulfillmentsSize = fulfillments.size();
		System.debug( logginglevel.error, '~*~ fulfillmentsSize :' + fulfillmentsSize );

		map<Integer, Decimal> systemUnitPrices = new map<Integer, Decimal>();
		map<Integer, Decimal> systemPrices = new map<Integer, Decimal>();

		for(integer i = 0; i < fulfillmentsSize; i++) {
			Fulfillment__c fulfillment = fulfillments[i];
			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Fulfillment__c>{fulfillment}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(fulfillments[i])) {
				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(fulfillments[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(fulfillments[i]);
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '\n' + '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());


				systemUnitPrices.put(dayRange, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(dayRange, bestPrice.setScale(2, RoundingMode.HALF_UP));

				System.debug( logginglevel.error, '~*~  Dates: ' + fulfillments[i].Start_Date__c.date() + ' to ' + fulfillments[i].End_Date__c.date() );
				System.debug( logginglevel.error, '~*~ bestUnitPrice :' + (i+1) + ' ' + dayRange + '-  ' + bestUnitPrice );
				System.debug( logginglevel.error, '~*~ bestPrice :' + (i+1) + ' ' + dayRange + '-  ' + bestPrice.setScale(2, RoundingMode.HALF_UP) + '\n');

//				system.assertEquals(correctUnitPrices.get(dayRange), systemUnitPrices.get(dayRange), dayRange);
//				system.assertEquals(correctPrices.get(dayRange), systemPrices.get(dayRange), dayRange);
			}
		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);
	}

	
	// SPS
	testMethod static void unitTest_FixedMonth_Fulfillment_BestPrice_MutipleRanges_MonthWeekDay() {

		map<String, Decimal> correctUnitPrices = new map<String, Decimal>{
				'8/17-9/15' => 940, // even though there is no month value, we store the priceresult with 0 bestPrice and 0 unitprice to capture the proratevalue. Diff is 29, Fd is 12, md is 0, ld is 17
				'8/23-9/21' => 870,
				'8/17-2/23' => 2302.14, // Diff is 190, Fd-Md-Ld is 12-168-10     (first day, mid day, last day segments)
				'8/17-9/9' => 940, // special case. bestprice run twice on first cycle and then  2nd because total range is less than interval range, but it crosses over the recurrence date
				'8/16-9/9' => 870,
				'8/15-8/15' => 70,
				'8/1-8/24' => 470,
				'8/1-1/24' => 1735.71,
				'8/1-10/24' => 1350,
				'8/15-9/11' => 800,
				'8/15-8/16' => 70,
				'8/1-8/29' => 1350,
				'8/1-8/23' => 470,
				'8/1-8/1' => 70,
				'12/1-12/7' => 400
		};

		map<String, Decimal> correctPrices= new map<String, Decimal>{
				'8/17-9/15' => 1760,
				'8/23-9/21' => 1740,
				'8/17-2/23' => 9332.14,
				'8/17-9/9' => 1430,
				'8/16-9/9' => 1480,
				'8/15-8/15' => 70,
				'8/1-8/24' => 1340,
				'8/1-1/24' => 8485.71,
				'8/1-10/24' => 4050,
				'8/15-9/11' => 1600,
				'8/15-8/16' => 70,
				'8/1-8/29' => 1350,
				'8/1-8/23' => 1270,
				'8/1-8/1' => 70,
				'12/1-12/7' => 400
		};

		List<DateWrapper> datesWrapperList = getPrepopulatedDates();

		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
		for (DateWrapper dates : datesWrapperList){
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.SPSProduct.Id;
			fulfillment.Billing_UOM__c = fuel.SPSmonth.Id;
			fulfillment.Billing_UOM__r = fuel.SPSmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = dates.shippedDate;
			fulfillment.End_Date__c = dates.returnDate;
			fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;

			system.assert(fulfillment.Start_Date__c <= fulfillment.End_Date__c, 'Invalid fulfillment dates' + fulfillment);
			fulfillments.add(fulfillment);

		}

		insert fulfillments;

		SOQLUtil query = new SOQLUtil('Fulfillment__c', true);
		query.addFields(Fulfillment__c.getSobjectType().getDescribe().fields.getMap().keySet());
		query.addFields(new Set<String>{'Sales_Order_Line__r.Pricebook__c', 'Sales_Order_Line__r.Customer_ID__c'});
		fulfillments = Database.query(query.getQuery());

		Integer fulfillmentsSize = fulfillments.size();

		map<String, Decimal> systemUnitPrices = new map<String, Decimal>();
		map<String, Decimal> systemPrices = new map<String, Decimal>();

		System.debug( logginglevel.error, '\n\n');
		System.debug( logginglevel.error, '~*~ Start Processing Prices \n\n');

		for(integer i = 0; i < fulfillmentsSize; i++) {
			Fulfillment__c ful = fulfillments[i];

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Fulfillment__c>{ful}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);
			List<PricingService.PricingResult> bestPrices = mBestPrices.get(ful);

			decimal bestPrice = 0;
			decimal bestUnitPrice = 0;

			for(PricingService.PricingResult d : bestPrices) {
				if(bestUnitPrice == null && bestPrice == null) {
					bestPrice = d.bestPrice;
					bestUnitPrice = d.unitPrice;
				} else {
					bestPrice += d.bestPrice;
					bestUnitPrice += d.unitPrice;
				}
			}

			String startDate = fulfillments[i].Start_Date__c.month() + '/' + fulfillments[i].Start_Date__c.day();
			String endDate = fulfillments[i].End_Date__c.month() + '/' + fulfillments[i].End_Date__c.day();
			Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());
			String key = startDate + '-' + endDate;


			systemUnitPrices.put(key, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
			systemPrices.put(key, bestPrice.setScale(2, RoundingMode.HALF_UP));

			System.debug( logginglevel.error, '\n\n\n~*~ (' + dayRange + ') ' + key + ' - ' + ' bestUnitPrice :' + bestUnitPrice + ', bestPrice: ' + bestPrice.setScale(2, RoundingMode.HALF_UP));
			system.debug( logginglevel.error,PricingService.debugBestPriceString(fulfillments[i], bestPrices) );

//			system.assertEquals(correctPrices.get(key), systemPrices.get(key), 'Off by ' + (systemPrices.get(key) - correctPrices.get(key)) + ' - bestPrice failure (major) - ' + key + ' (' + dayRange + ')');
//			system.assertEquals(correctUnitPrices.get(key), systemUnitPrices.get(key), 'unit price failure (minor) - '  + key + ' (' + dayRange + ')');

		}


		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);


	}


	/*
			HELPER METHODS & TEST DATA SETUP
	 */
	testMethod static void unitTest_FixedMonth_Fulfillment_BestPrice_MonthWeekDay() {

		map<Integer, Decimal> correctUnitPrices = new map<Integer, Decimal>{
				1 => dayPrice,
				2 => dayPrice,
				3 => dayPrice,
				4 => dayPrice,
				5 => dayPrice,
				6 => weekPrice,
				7 => weekPrice,
				8 => weekPrice + dayPrice,
				9 => weekPrice + dayPrice,
				10 => weekPrice + dayPrice,
				11 => weekPrice + dayPrice,
				12 => weekPrice + dayPrice,
				13 => weekPrice,
				14 => weekPrice,
				15 => weekPrice + dayPrice,
				16 => weekPrice + dayPrice,
				17 => weekPrice + dayPrice,
				18 => weekPrice + dayPrice,
				19 => weekPrice + dayPrice,
				20 => weekPrice,
				21 => weekPrice,
				22 => weekPrice + dayPrice,
				23 => weekPrice + dayPrice,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => monthPrice + (monthPrice / 28 * 1).setScale(2, RoundingMode.HALF_UP), // prorate 1 day,
				30 => monthPrice + (monthPrice / 28 * 2).setScale(2, RoundingMode.HALF_UP), // prorate 2 day,
				31 => monthPrice + (monthPrice / 28 * 3).setScale(2, RoundingMode.HALF_UP) // prorate 3 day
		};

		map<Integer, Decimal> correctPrices= new map<Integer, Decimal>{
				1  => dayPrice * 1,
				2  => dayPrice * 2,
				3  => dayPrice * 3,
				4  => dayPrice * 4,
				5  => dayPrice * 5,
				6  => weekPrice,
				7  => weekPrice,
				8  => weekprice + dayPrice * 1,
				9  => weekprice + dayPrice * 2,
				10 => weekprice + dayPrice * 3,
				11 => weekprice + dayPrice * 4,
				12 => weekprice + dayPrice * 5,
				13 => weekprice * 2,
				14 => weekprice * 2,
				15 => weekprice * 2 + dayPrice * 1,
				16 => weekprice * 2 + dayPrice * 2,
				17 => weekprice * 2 + dayPrice * 3,
				18 => weekprice * 2 + dayPrice * 4,
				19 => weekprice * 2 + dayPrice * 5,
				20 => weekprice * 3,
				21 => weekprice * 3,
				22 => weekprice * 3 + dayPrice * 1,
				23 => weekprice * 3 + dayPrice * 2,
				24 => monthPrice,
				25 => monthPrice,
				26 => monthPrice,
				27 => monthPrice,
				28 => monthPrice,
				29 => (monthPrice + (monthPrice / 28 * 1)).setScale(2, RoundingMode.HALF_UP), // prorate 1 day
				30 => (monthPrice + (monthPrice / 28 * 2)).setScale(2, RoundingMode.HALF_UP), // prorate 2 day
				31 => (monthPrice + (monthPrice / 28 * 3)).setScale(2, RoundingMode.HALF_UP)  // prorate 3 day
		};


		List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();

		for(Integer i = 1; i <= 31; i++) {
			Fulfillment__c fulfillment = new Fulfillment__c();
			fulfillment.Name = 'Test Fulfillment';
			fulfillment.Company__c = fuel.company.Id;
			fulfillment.Type__c = 'Recurring';
			fulfillment.Product__c = fuel.SPSProduct.Id;
			fulfillment.Billing_UOM__c = fuel.SPSmonth.Id;
			fulfillment.Billing_UOM__r = fuel.SPSmonth;
			fulfillment.Pricing_UOM__c = fulfillment.Billing_UOM__c;
			fulfillment.Pricing_UOM__r = fulfillment.Billing_UOM__r;
			fulfillment.Status__c = 'Completed';
			fulfillment.Start_Date__c = System.now();
			fulfillment.End_Date__c = system.now().addDays(i);
			fulfillments.add(fulfillment);
		}

		insert fulfillments;

		SOQLUtil query = new SOQLUtil('Fulfillment__c', true);
		query.addFields(Fulfillment__c.getSobjectType().getDescribe().fields.getMap().keySet());
		query.addFields(new Set<String>{'Sales_Order_Line__r.Pricebook__c', 'Sales_Order_Line__r.Customer_ID__c'});
		fulfillments = Database.query(query.getQuery());

		Integer fulfillmentsSize = fulfillments.size();
		System.debug( logginglevel.error, '~*~ fulfillmentsSize :' + fulfillmentsSize );

		map<Integer, Decimal> systemUnitPrices = new map<Integer, Decimal>();
		map<Integer, Decimal> systemPrices = new map<Integer, Decimal>();

		for(integer i = 0; i < fulfillmentsSize; i++) {
			Fulfillment__c fulfillment = fulfillments[i];
			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(new List<Fulfillment__c>{fulfillment}, PricingService.PriceType.RECURRING);
			Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			if(mBestPrices.containsKey(fulfillments[i])) {
				system.debug(LoggingLevel.Error, i + ' - ' + mBestPrices.get(fulfillments[i]));
				List<PricingService.PricingResult> bestPrices = mBestPrices.get(fulfillments[i]);
				decimal bestPrice = 0;
				decimal bestUnitPrice = 0;
				System.debug( logginglevel.error, '\n' + '~*~ bestPrices :' + bestPrices );
				for(PricingService.PricingResult d : bestPrices) {
					if(bestUnitPrice == null && bestPrice == null) {
						bestPrice = d.bestPrice;
						bestUnitPrice = d.unitPrice;
					} else {
						bestPrice += d.bestPrice;
						bestUnitPrice += d.unitPrice;
					}
				}

				Integer dayRange = fulfillments[i].Start_Date__c.date().daysBetween(fulfillments[i].End_Date__c.date());


				systemUnitPrices.put(dayRange, bestUnitPrice.setScale(2, RoundingMode.HALF_UP));
				systemPrices.put(dayRange, bestPrice.setScale(2, RoundingMode.HALF_UP));

				System.debug( logginglevel.error, '~*~  Dates: ' + fulfillments[i].Start_Date__c.date() + ' to ' + fulfillments[i].End_Date__c.date() );
				System.debug( logginglevel.error, '~*~ bestUnitPrice :' + (i+1) + ' ' + dayRange + '-  ' + bestUnitPrice );
				System.debug( logginglevel.error, '~*~ bestPrice :' + (i+1) + ' ' + dayRange + '-  ' + bestPrice.setScale(2, RoundingMode.HALF_UP) + '\n');

//				system.assertEquals(correctUnitPrices.get(dayRange), systemUnitPrices.get(dayRange), dayRange);
//				system.assertEquals(correctPrices.get(dayRange), systemPrices.get(dayRange), dayRange);
			}
		}

		validatePriceMaps(correctPrices, systemPrices);
		validatePriceMaps(correctUnitPrices, systemUnitPrices);
	}

	static DateTime getLastRecurrenceDate(Uom__c billingUom, DateTime recurrenceDate){
		// get closest recurrence date before today
		Date lastRecurrenceDate;
		if (billingUOM == fuel.StdMonth) {
			lastRecurrenceDate = Date.newInstance( system.today().year(), system.today().Month(), recurrenceDate.Day() );
			lastRecurrenceDate = lastRecurrenceDate > system.today() ? lastRecurrenceDate.addMonths(-1) : lastRecurrenceDate;
		} else if (billingUOM == fuel.SPSMonth){
			Decimal decimalTerm = fuel.SPSMonth.Every__c;
			Integer period = Integer.valueOf(Math.floor(recurrenceDate.date().daysBetween(system.today())/decimalTerm) * decimalTerm);
			lastRecurrenceDate = recurrenceDate.date().addDays(period);
		}

		System.debug( logginglevel.error, '~*~ (data setup) lastRecurrenceDate before today:' + lastRecurrenceDate );
		return DateTime.newInstance(lastRecurrenceDate.year(),lastRecurrenceDate.month(),lastRecurrenceDate.day(),0,0,0);

	}

	@testSetup
	static void data(){

		TestFuel fuel = new TestFuel();

		Location__c location = fuel.location;

		customer__c parent = fuel.customerParent;
		Customer__c billTo = fuel.customerBillTo;
		Customer__c soldTo = fuel.customerSoldTo;
		customer__c shipTo = fuel.customerShipTo;

		Pricebook__c pricebook = new Pricebook__c();
		pricebook.name = 'Test Rental Pricebook';
		pricebook.company__c = fuel.company.Id;
		pricebook.Currency__c = TestFuel.currencyUSD.ID;
		pricebook.Primary_Key__c = 'RENTBOOK';
		pricebook.Default__c = true;
		insert pricebook;

		List<UOM__c> uomList = new List<UOM__c>();

		UOM__c dailyUom = new UOM__c();
		dailyUom.Name = 'DAILY';
		dailyUom.Type__c = 'Time';
		dailyUom.Description__c = 'Every1Day(s)';
		dailyUom.Every__c = 1;
		dailyUom.Recurrence__c = 'Day(s)';
		uomList.add(dailyUom);

		UOM__c weeklyUom = new UOM__c();
		weeklyUom.Name = 'WEEKLY';
		weeklyUom.Type__c = 'Time';
		weeklyUom.Description__c = 'Every1Week(s)';
		weeklyUom.Every__c = 1;
		weeklyUom.Recurrence__c = 'Week(s)';
		uomList.add(weeklyUom);

		// SPS treats months as 28 days
		UOM__c SpsMonthlyUOM = new UOM__c();
		SpsMonthlyUOM.Name = 'MONTHLY';
		SpsMonthlyUOM.Type__c = 'Time';
		SpsMonthlyUOM.Description__c = 'Every28Day(s)';
		SpsMonthlyUOM.Every__c = 28;
		SpsMonthlyUOM.Recurrence__c = 'Day(s)';
		uomList.add(SpsMonthlyUOM);

		// Bevi might treat months as 1 month
		UOM__c StdMonthlyUOM = new UOM__c();
		StdMonthlyUOM.Name = 'MONTHLY2';
		StdMonthlyUOM.Type__c = 'Time';
		StdMonthlyUOM.Description__c = 'Every1Month(s)';
		StdMonthlyUOM.Every__c = 1;
		StdMonthlyUOM.Recurrence__c = 'Month(s)';
		uomList.add(StdMonthlyUOM);

		insert uomList;

		List<Product__c> prodList = new List<Product__c>();

		Product__c discountProduct = createProduct(fuel, '5433', 'Discounted Product');
		prodList.add(discountProduct);

		Product__c SPSProduct = createProduct(fuel, '1', 'D-W-M28');
		prodList.add(SPSProduct);

		Product__c StdProduct1 = createProduct(fuel, '01', 'D-W-M');
		prodList.add(StdProduct1);

		Product__c StdProduct2 = createProduct(fuel, '02', 'W-M');
		prodList.add(StdProduct2);

		Product__c StdProduct3 = createProduct(fuel, '03', 'D-M');
		prodList.add(StdProduct3);

		Product__c StdProduct4 = createProduct(fuel, '04', 'M');
		prodList.add(StdProduct4);

		Product__c StdProduct5 = createProduct(fuel, '05', 'No Pricebook');
		prodList.add(StdProduct5);

		//		System.debug( logginglevel.error, '~*~ prodList :' + prodList );
		insert prodList;


		PBLHelper pblh = new PBLHelper(pricebook);

		pblh.addPricebookLine(SPSProduct, dailyUom);
		pblh.addPricebookLine(SPSProduct, weeklyUom);
		pblh.addPricebookLine(SPSProduct, SpsMonthlyUOM);

		pblh.addPricebookLine(StdProduct1, dailyUom);
		pblh.addPricebookLine(StdProduct1, weeklyUom);
		pblh.addPricebookLine(StdProduct1, StdMonthlyUOM);

		pblh.addPricebookLine(StdProduct2, weeklyUom);
		pblh.addPricebookLine(StdProduct2, StdMonthlyUOM);

		pblh.addPricebookLine(StdProduct3, dailyUom);
		pblh.addPricebookLine(StdProduct3, StdMonthlyUOM);

		pblh.addPricebookLine(StdProduct4, StdMonthlyUOM);

		//		System.debug( logginglevel.error, '~*~ pblh.pblList :' + pblh.pblList );
		insert pblh.pblList;

		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Start_Date__c =system.today()-360,
				Group_By_Agreements__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);
		insert igr;

	}

	Class PBLHelper {

		Map<String,Decimal> priceMap = new Map<String, Decimal>{
				'1Month(s)' => monthPrice,
				'28Day(s)' => monthPrice,
				'1Week(s)' => WeekPrice,
				'1Day(s)' => DayPrice
		};

		Pricebook__c pricebook;
		public List<Pricebook_Line__c> pblList = new List<Pricebook_Line__c>();

		public PBLHelper (Pricebook__c pricebook){
			this.pricebook = pricebook;
		}

		public void addPricebookLine(Product__c prod, UOM__c pricingUOM){
			Pricebook_Line__c pbl = new Pricebook_Line__c(
					Product__c = prod.Id,
					Pricebook__c = pricebook.Id,
					Pricing_UOM__c = pricingUOM.id,
					price__c = priceMap.get(pricingUOM.Every__c + '' + pricingUOM.Recurrence__c),
					Start_Date__c = system.today().addDays(-1365),
					End_Date__c = system.today().addDays(1365),
					Price_Type__c = 'Recurring',
					Data_Load__c = true

			);
			//			System.debug( logginglevel.error, '~*~ pbl :' + prod.description__c + ' - ' + pricingUOM.Recurrence__c + ' - ' + pbl.Price__c );
			pblList.add(pbl);
		}
	}

	static Product__c createProduct(TestFuel fuel, String index, String description){
		Product__c prod = fuel.newProduct();
		prod.Name = 'product-' + index;
		prod.Description__c = description;
		prod.UPC_Code__c = '1234'+index;
		prod.Primary_Key__c = '1234'+index;

		return prod;
	}

	static RentalTestDataQuery fuel = new RentalTestDataQuery();

	public class RentalTestDataQuery {
		TestFuelQuery fuelQuery = new TestFuelQuery();
		Map<String, List<sObject>> sObjListMap = new Map<String, List<sObject>>();

		public Currency__c currencyUSD {
			get {return (Currency__c)TestQueryService.getSobjFromVal(sObjListMap, currencyUSD, 'currencyList', 'ISO_Code__c', TestQueryService.matchMethod.EQ, 'USD');}
			set;
		}

		public Company__c company {
			get {return fuelQuery.company;}
			set;
		}

		public Item__c item1 {
			get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item1, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-10');}
			set;
		}

		public Pricebook__c rentalPricebook {
			get {return (Pricebook__c)TestQueryService.getSobjFromVal(sObjListMap, rentalPricebook, 'pricebookList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'RENTBOOK');}
			set;
		}

		public List<Pricebook_Line__c> rentalPricebookLines {
			get {return (List<Pricebook_Line__c>)TestQueryService.getSobjListFromVal(sObjListMap, 'pricebookLineList', 'Price_Type__c', TestQueryService.matchMethod.EQ, 'Recurring');}
			set;
		}

		public List<UOM__c> rentalUomList {
			get {return (List<UOM__c>)TestQueryService.getSobjList(sObjListMap, 'uomList');}
			set;
		}

		public UOM__c day {
			get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, day, 'uomList', 'Description__c', TestQueryService.matchMethod.EQ, 'Every1Day(s)');}
			set;
		}
		public UOM__c week {
			get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, week, 'uomList', 'Description__c', TestQueryService.matchMethod.EQ, 'Every1Week(s)');}
			set;
		}
		public UOM__c SPSmonth {
			get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, SPSmonth, 'uomList', 'Description__c', TestQueryService.matchMethod.EQ, 'Every28Day(s)');}
			set;
		}
		public UOM__c StdMonth {
			get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, StdMonth, 'uomList', 'Description__c', TestQueryService.matchMethod.EQ, 'Every1Month(s)');}
			set;
		}

		public Customer__c customerParent {
			get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerParent, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'CPTEST123');}
			set;
		}
		public Customer__c customerBillTo {
			get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerBillTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'BDTEST123');}
			set;
		}
		public Customer__c customerSoldTo {
			get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerSoldTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'SDTEST123');}
			set;
		}
		public Customer__c customerShipTo {
			get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerShipTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'SHTEST123');}
			set;
		}

		public Product__c SPSProduct {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, SPSProduct, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '12341');}
			set;
		}
		public Product__c StdProduct1 {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, StdProduct1, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '123401');}
			set;
		}
		public Product__c StdProduct2 {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, StdProduct2, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '123402');}
			set;
		}
		public Product__c StdProduct3 {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, StdProduct3, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '123403');}
			set;
		}
		public Product__c StdProduct4 {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, StdProduct4, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '123404');}
			set;
		}
		public Product__c DiscountProduct {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, DiscountProduct, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '12345433');}
			set;
		}
		public Product__c StdProduct5 {
			get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, StdProduct5, 'productList', 'UPC_Code__c', TestQueryService.matchMethod.EQ, '123405');}
			set;
		}

		public Payment_Term__c paymentTerm {
			get {return fuelQuery.terms;}
			set;
		}
	}

	// used for managing fields we want to alter in the createData method
	Class TestDataWrapper {
		Product__c product {get; set;}
		UOM__c billingUOM {get; set;}
		UOM__c pricingUOM {get; set;}
		Decimal agreementPrice {get; set;}

		Product__c discountProduct;

		public TestDataWrapper(){
			// init defaults
			product = fuel.StdProduct1;
			billingUOM = fuel.StdMonth;
			pricingUOM = fuel.StdMonth;
			agreementPrice = monthPrice;
		}
	}

	Class CreateData{
		private TestDataWrapper tdw;
		private DateWrapper dates;

		private Company__c company;
		String orderStatus = 'Closed';

		public Map<String,SObject> resultMap = new Map<String,SObject>();
		public Map<String,List<SObject>> resultListMap = new Map<String,List<SObject>>();

		private Agreement__c agreement{
			get{
				if (agreement == null) {
					agreement = new Agreement__c();
					agreement.Name = 'Sample Agreement';
					agreement.Company__c = company.Id;
					agreement.Currency__c = fuel.currencyUSD.Id;
					agreement.Customer__c = fuel.customerParent.Id;
					agreement.Start_Date__c = dates.startDate;
					agreement.Activation_Date__c = system.today(); // acceptance date
					agreement.Recurrence_Start_Date__c = dates.recurrenceDate;
					agreement.Status__c = 'Open';
					agreement.Billing_UOM__c = tdw.billingUOM.Id;
					agreement.Billing_UOM__r = tdw.billingUOM;
					agreement.Payment_Terms__c = fuel.paymentTerm.id;
					insert agreement; // 5 queries
					resultListMap.put( 'agreement', new List<Agreement__c>{ agreement } );
					resultMap.put( 'agreement', agreement );
				}
				return agreement;
			}
			set;
		}

		private List<Agreement_Line__c> aglList {
			get {
				if ( aglList == null ) {
					aglList = new List<Agreement_Line__c>();

					System.debug( logginglevel.error, '~*~ tdw.discountProduct :' + tdw.discountProduct );
					if ( tdw.discountProduct != null ) {
						Agreement_Line__c discountAGL = new Agreement_Line__c();
						discountAGL.Agreement__c = agreement.Id;
						discountAGL.Start_Date__c = agreement.Start_Date__c;
						discountAGL.Occurrence__c = 'Immediate';
						discountAGL.Rate_Basis__c = 'Quantity';
						discountAGL.Product__c = tdw.discountProduct.Id;
						discountAGL.Product_Type__c = 'Product';
						discountAGL.Sales_Agreement_Quantity__c = 100;
						discountAGL.Revision_Status__c = null;
						discountAGL.Agreement_Price__c = -tdw.agreementPrice; // discount price is negative
						discountAGL.Pricing_UOM__c = tdw.pricingUOM.Id;
						discountAGL.Price_Type__c = 'Recurring';
						System.debug( logginglevel.error, '~*~ discountAGL :' + discountAGL );
						aglList.add( discountAGL );
						resultMap.put( 'discountAGL', discountAGL );
					}

					Agreement_Line__c agreementLine = new Agreement_Line__c();
					agreementLine.Agreement__c = agreement.Id;
					agreementLine.Start_Date__c = agreement.Start_Date__c;
					agreementLine.Occurrence__c = 'Immediate';
					agreementLine.Rate_Basis__c = 'Quantity';
					agreementLine.Product__c = tdw.product.Id;
					agreementLine.Product_Type__c = 'Product';
					agreementLine.Sales_Agreement_Quantity__c = 100;
					//		agreementLine.List_Price__c = monthPrice; // auto fetched from the AGL trigger pricing call
					agreementLine.Revision_Status__c = null;
					agreementLine.Agreement_Price__c = tdw.agreementPrice;
					agreementLine.Pricing_UOM__c = tdw.pricingUOM.Id;
					agreementLine.Price_Type__c = 'Recurring';
					aglList.add( agreementline );
					insert aglList; // 28 queries
					resultMap.put( 'agreementLine', agreementLine );
					resultListMap.put( 'aglList', aglList );
				}
				return aglList;
			}
			set;
		}

		private Sales_Order__c sorder{
			get {
				if (this.sorder == null){
					sorder = new Sales_Order__c();
					sorder.Ship_to__c = fuel.customerShipTo.Id;
					sorder.Agreement__c = agreement.Id;
					sorder.Bill_To__c = fuel.customerBillTo.Id;
					sorder.Customer__c = fuel.customerSoldTo.Id;
					sorder.Currency__c = fuel.currencyUSD.id;
					sorder.Company__c = company.id;
					sorder.Status__c = orderStatus;
					sorder.Payment_Term__c = fuel.paymentTerm.id;
					sorder.Billing_UOM__c = agreement.Billing_UOM__c;
					sorder.Pricebook__c = fuel.rentalPricebook.Id;
					sorder.Recurrence_Start_Date__c = dates.recurrenceDate;
					insert sorder; // 2 queries
					resultMap.put('sorder', sorder);
					resultListMap.put('sorder', new List<Sales_Order__c>{sorder});
				}
				return sorder;
			}
			set;
		}

		private List<Sales_Order_Line__c> solList{
			get {
				if ( this.solList == null ) {
					Location__c location = [SELECT Id FROM Location__c WHERE Name = 'Delivery/Shipping Location'];
					system.assert( location != null );

					solList = new List<Sales_Order_Line__c>();
					for ( Agreement_Line__c agl : aglList ) {
						Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
						salesOrderLine.Agreement__c = agreement.id;
						salesOrderLine.Agreement_Line__c = agl.Id;
						salesOrderLine.Company__c = company.Id;
						salesOrderLine.Sales_Order__c = sorder.Id;
						salesOrderLine.Ship_From_Location__c = location.Id;
						salesOrderLine.Status__c = orderStatus;
						salesOrderLine.Required_Date__c = System.today() + 5;
						salesOrderLine.Description__c = agl.product__r.Description__c;
						salesOrderLine.Quantity_Ordered__c = agl.Sales_Agreement_Quantity__c;
						salesOrderLine.Product__c = agl.Product__c;
						salesOrderLine.Unit_Price__c = agl.Agreement_Price__c;
						salesOrderLine.Pricing_UOM__c = agl.Pricing_UOM__c;
						salesOrderLine.Occurrence__c = agl.Occurrence__c;
						salesOrderLine.Start_Date__c = agl.Start_Date__c;
						salesOrderLine.Pricebook__c = fuel.rentalPricebook.Id;
						//		salesOrderLine.End_Date__c = agreementLine.End_Date__c;
						salesOrderLine.Price_Type__c = agl.Price_Type__c;
						salesOrderLine.List_Price__c = agl.List_Price__c;
						salesOrderLine.Rental__c = true;
						salesOrderLine.status__c = 'Closed';
						solList.add( salesOrderLine );

						resultMap.put( 'salesOrderLine', salesOrderLine );
					}
					resultListMap.put( 'solList', solList );

					insert solList; // 14 queries
				}
				return solList;
			}
			set;
		}

		private List<Fulfillment__c> fulList{
			get {
				if ( this.fulList == null ) {
					fulList = new List<Fulfillment__c>();
					for ( Sales_Order_Line__c sol : solList ) {
						Fulfillment__c fulfillment = new Fulfillment__c();
						fulfillment.Name = 'Test Fulfillment';
						fulfillment.Last_Bill_Date__c = null;
						fulfillment.Company__c = company.Id;
						fulfillment.Sales_Order_Line__c = sol.id;
						fulfillment.Sales_Order__c = sorder.Id;
						fulfillment.Agreement__c = Agreement.Id;
						fulfillment.Agreement_Line__c = sol.Agreement_Line__c;
						fulfillment.Currency__c = fuel.currencyUSD.id;
						fulfillment.Occurrence__c = 'Immediate';
						fulfillment.Price_Type__c = 'Recurring';
						fulfillment.Type__c = 'Rental'; // used by AgreementReturn
						fulfillment.Product__c = sol.Product__c;
						fulfillment.Billing_UOM__c = agreement.Billing_UOM__c;
						fulfillment.Pricing_UOM__c = sol.Pricing_UOM__c;
						fulfillment.Unit_Price__c = sol.Unit_Price__c;
						fulfillment.Recurrence_Start_Date__c = dates.recurrenceDate;
						fulfillment.Payment_Term__c = sorder.Payment_Term__c;
						fulfillment.Invoice_Ready__c = true;
						fulfillment.Quantity__c = sol.Quantity_Ordered__c;
						fulfillment.Start_Date__c = dates.shippedDate;
						fulfillment.Status__c = 'Complete';

						fulList.add( fulfillment );

						if ( dates.shippedDate2 != null ) {

							Decimal partialQty = 10;

							fulfillment.Quantity__c -= partialQty;

							Fulfillment__c fulfillment2 = new Fulfillment__c();
							fulfillment2.Name = 'Test Fulfillment2';
							fulfillment2.Last_Bill_Date__c = null;
							fulfillment2.Company__c = company.Id;
							fulfillment2.Sales_Order_Line__c = sol.id;
							fulfillment2.Sales_Order__c = sorder.Id;
							fulfillment2.Agreement__c = Agreement.Id;
							fulfillment2.Agreement_Line__c = sol.Agreement_Line__c;
							fulfillment2.Currency__c = fuel.currencyUSD.id;
							fulfillment2.Occurrence__c = 'Immediate';
							fulfillment2.Price_Type__c = 'Recurring';
							fulfillment2.Type__c = 'Rental'; // used by AgreementReturn
							fulfillment2.Product__c = sol.Product__c;
							fulfillment2.Billing_UOM__c = agreement.Billing_UOM__c;
							fulfillment2.Pricing_UOM__c = sol.Pricing_UOM__c;
							fulfillment2.Unit_Price__c = sol.Unit_Price__c;
							fulfillment2.Recurrence_Start_Date__c = dates.recurrenceDate;
							fulfillment2.Payment_Term__c = sorder.Payment_Term__c;
							fulfillment2.Invoice_Ready__c = true;
							fulfillment2.Quantity__c = partialQty;
							fulfillment2.Start_Date__c = dates.shippedDate2;
							fulfillment2.Status__c = 'Complete';
							fulList.add( fulfillment2 );
							resultMap.put( 'fulfillment2', fulfillment2 );
						}

						resultMap.put( 'fulfillment', fulfillment );
					}

					insert fulList;
					resultListMap.put( 'fulList', fulList );

				}
				return fulList;
			}
			set;
		}

		public CreateData(TestDataWrapper tdw, DateWrapper dates){
			this.tdw = tdw;
			this.dates = dates;

			List<UOM__c> uomList = fuel.rentalUomList;
			Map<String, UOM__c> mUOM = new Map<String, UOM__c>();
			for(UOM__c u : uomList) {
				mUOM.put(u.Name, u);
			}

			this.company = fuel.company;

//			System.assert(this.agreement != null);
//			System.assert(this.aglList != null);
//			System.assert(this.sorder != null);
//			System.assert(this.solList != null);
			System.assert(this.fulList != null);

		}

	}


	public static List<Fulfillment__c> getFulfillmentsForInvoicing(List<Fulfillment__c> fulfillmentList){
		Set<Id> fIds = KSE.grepRelatedIdSetFromList( fulfillmentList , 'Id', true);
		InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance();
		return igrUtil.getFulfillments('Fulfillment__c',fIds).values();
	}

	static List<DateWrapper> getPrepopulatedDates(){

		List<DateWrapper> datesWrapperList = new List<DateWrapper>();

		DateWrapper dates1 = new DateWrapper();
		dates1.shippedDate = DateTime.newInstance(2017,8,17,0,0,0);
		dates1.returnDate = DateTime.newInstance(2017,9,15,0,0,0);
		datesWrapperList.add(dates1);

		DateWrapper dates2 = new DateWrapper();
		dates2.shippedDate = DateTime.newInstance(2017,8,23,0,0,0);
		dates2.returnDate = DateTime.newInstance(2017,9,21,0,0,0);
		datesWrapperList.add(dates2);

		DateWrapper dates3 = new DateWrapper();
		dates3.shippedDate = DateTime.newInstance(2017,8,17,0,0,0);
		dates3.returnDate = DateTime.newInstance(2018,2,23,0,0,0);
		datesWrapperList.add(dates3);

		DateWrapper dates4 = new DateWrapper();
		dates4.shippedDate = DateTime.newInstance(2017,8,17,0,0,0);
		dates4.returnDate = DateTime.newInstance(2017,9,9,0,0,0);
		datesWrapperList.add(dates4);

		DateWrapper dates5 = new DateWrapper();
		dates5.shippedDate = DateTime.newInstance(2017,8,16,0,0,0);
		dates5.returnDate = DateTime.newInstance(2017,9,9,0,0,0);
		datesWrapperList.add(dates5);

		DateWrapper dates6 = new DateWrapper();
		dates6.shippedDate = DateTime.newInstance(2017,8,15,0,0,0);
		dates6.returnDate = DateTime.newInstance(2017,8,15,0,0,0);
		datesWrapperList.add(dates6);

		DateWrapper dates7 = new DateWrapper();
		dates7.shippedDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates7.returnDate = DateTime.newInstance(2017,8,24,0,0,0);
		datesWrapperList.add(dates7);

		DateWrapper dates8 = new DateWrapper();
		dates8.shippedDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates8.returnDate = DateTime.newInstance(2018,1,24,0,0,0);
		datesWrapperList.add(dates8);

		DateWrapper dates9 = new DateWrapper();
		dates9.shippedDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates9.returnDate = DateTime.newInstance(2017,10,24,0,0,0);
		datesWrapperList.add(dates9);

		DateWrapper dates10 = new DateWrapper(); // last uses month best price where breaking point is broken
		dates10.shippedDate = DateTime.newInstance(2017,8,15,0,0,0);
		dates10.returnDate = DateTime.newInstance(2017,9,11,0,0,0);
		datesWrapperList.add(dates10);

		DateWrapper dates11 = new DateWrapper();
		dates11.shippedDate = DateTime.newInstance(2017,8,15,0,0,0);
		dates11.returnDate = DateTime.newInstance(2017,8,16,0,0,0);
		datesWrapperList.add(dates11);

		DateWrapper dates12 = new DateWrapper();
		dates12.shippedDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates12.returnDate = DateTime.newInstance(2017,8,29,0,0,0);
		datesWrapperList.add(dates12);

		DateWrapper dates13 = new DateWrapper();
		dates13.shippedDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates13.returnDate = DateTime.newInstance(2017,8,23,0,0,0);
		datesWrapperList.add(dates13);

		DateWrapper dates14 = new DateWrapper();
		dates14.shippedDate = DateTime.newInstance(2017,8,1,0,0,0);
		dates14.returnDate = DateTime.newInstance(2017,8,1,0,0,0);
		datesWrapperList.add(dates14);

		DateWrapper dates15 = new DateWrapper();
		dates15.shippedDate = DateTime.newInstance(2017,12,1,0,0,0);
		dates15.returnDate = DateTime.newInstance(2017,12,7,0,0,0);
		datesWrapperList.add(dates15);

		return datesWrapperList;

	}

	static void validatePricingUOMs(List<sObject> records, Map<String,Integer> correctPricingUomMap){
		Map<String,Integer> PricingUomMap = new Map<String,Integer>();
		Map<String,List<sObject>> recordByPricingUom = new Map<String,List<sObject>>();

		for (sObject obj : records){

			string sObjectName = obj.getSObjectType().getDescribe().getName();
			if (new SchemaUtil().fieldExists(sObjectName, 'Invoice_Ready__c') && (Boolean) obj.get('Invoice_Ready__c') == False) {
				// skip fulfillments that aren't invoice ready
				continue;
			}

			Uom__c pricingUom = (Uom__c) obj.getSObject('Pricing_Uom__r');
			if (!PricingUomMap.containsKey(pricingUom.Name)){
				PricingUomMap.put(pricingUom.Name, 0);
			}
			PricingUomMap.put(pricingUom.Name, PricingUomMap.get(pricingUom.Name) + 1);

			if (!recordByPricingUom.containsKey(pricingUom.Name)){
				recordByPricingUom.put(pricingUom.Name, new List<sObject>());
			}
			recordByPricingUom.get(pricingUom.Name).add(obj);
		}

		System.debug( logginglevel.error, '~*~ PricingUomMap :' + PricingUomMap );

		for (String key : PricingUomMap.keySet()){
			if (correctPricingUomMap.containsKey(key)){
				system.assertEquals(correctPricingUomMap.get(key), PricingUomMap.get(key), key + ' - \nActual:  ' + PricingUomMap + '\nCorrect: ' + correctPricingUomMap + '\n');
			} else {
				system.assert(false, 'Unexpected UOM: ' + key + ' - \nActual:  ' + PricingUomMap + '\nCorrect: ' + correctPricingUomMap + '\n');
			}
		}
	}

	static void validatePriceMaps(Map<String,Decimal> systemPriceMap, Map<String,Decimal> correctPriceMap){

		system.assert(systemPriceMap.keySet().isEmpty() == false);

		System.debug( logginglevel.error, '~*~ \nsystemUnitPrices');
		for(String key : systemPriceMap.keySet()) {
			System.debug( logginglevel.error, '~*~ ' + key + ' => ' + systemPriceMap.get( key ) + ' - ' + correctPriceMap.get(key) + ' ~ ' + (systemPriceMap.get(key) == correctPriceMap.get(key)) );
		}

		for(String key : systemPriceMap.keySet()) {
			system.assertEquals(systemPriceMap.get(key), correctPriceMap.get(key), key);
		}
	}

	static void validatePriceMaps(Map<Integer,Decimal> systemPriceMap, Map<Integer,Decimal> correctPriceMap){

		system.assert(systemPriceMap.keySet().isEmpty() == false);

		System.debug( logginglevel.error, '~*~ \nsystemUnitPrices');
		for(Integer key : systemPriceMap.keySet()) {
			System.debug( logginglevel.error, '~*~ ' + key + ' => ' + systemPriceMap.get( key ) + ' - ' + correctPriceMap.get(key) + ' ~ ' + (systemPriceMap.get(key) == correctPriceMap.get(key)) );
		}

		for(Integer key : systemPriceMap.keySet()) {
			system.assertEquals(systemPriceMap.get(key), correctPriceMap.get(key), key);
		}
	}

	static Map<String,List<SObject>> runInvoicing (List<Fulfillment__c> lFs, DateWrapper dates){
		return runInvoicing (lFs, dates, false, new Set<Id>());
	}

	static Map<String,List<SObject>> runInvoicing (List<Fulfillment__c> lFs, DateWrapper dates, Boolean invoiceAhead, Set<Id> oldCilIds){
		
		DateTime recurrenceDate = dates.recurrenceDate;
		DateTime shippedDate = dates.shippedDate;
		System.debug( logginglevel.error, '\n\n ~*~ Invoices Generated \n');
		Map<String,List<SObject>> returnResult = new Map<String,List<SObject>>();

		ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
		GenerateInvoiceExt ext = new GenerateInvoiceExt(con);

		Set<Id> fIds = KSE.grepRelatedIdSetFromList( lFs , 'Id', true);
		InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance();
		lFs = igrUtil.getFulfillments('Fulfillment__c',fIds).values();

		
		if (invoiceAhead){
			for (Fulfillment__c ful : lfs){
				ful.Invoice_Ahead__c = true;
			}

			update lfs;
		}

		System.debug( logginglevel.error, '~*~ lFs :' + lFs );
		JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(true,lFs, null);

		system.assert(jr.success, jr);
		system.assertNotEquals(null, jr.records);
		system.assertEquals(1, jr.records.size());


		
		jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));

		

		List<Customer_Invoice_Line__c> cilList = [select id, Start_Date__c, End_Date__c, Recurrence_Start_Date__c, Pricing_UOM__c, Pricing_UOM__r.Name, Quantity_Shipped__c,
				Pricing_UOM__r.Recurrence__c, Pricing_UOM_Recurrence__c, Pricing_UOM_Every__c, Unit_Price__c, Extended_Price__c, List_Price__c, Product__c from Customer_Invoice_Line__c where Id Not in :oldCilIds];
		returnResult.put('cilList', cilList);

		for (Customer_Invoice_Line__c cil : cilList){
			System.debug(logginglevel.error, '~*~ comp cil ' + PricingService.debugCIL(cil));
		}

		
		//		validateInvoiceLines(cilList, dates);


		
		return returnResult;

	}

	Class DateWrapper {
		DateTime recurrenceDate {get; set;}
		DateTime startDate {get; set;}
		DateTime shippedDate {get; set;}
		DateTime shippedDate2 {get; set;} // created for a specific test with multiple shipments
		DateTime returnDate {get; set;}
		DateTime returnDate2 {get; set;}
		public DateWrapper(){
			recurrenceDate = DateTime.newInstance(2017,8,1,0,0,0);
		}
	}

	Class ProcessReturnWrapper {

		Decimal returnQty;
		Agreement__c agreement;
		DateWrapper dates;

		public processReturnWrapper(Decimal retQty, Agreement__c agreement, DateWrapper dates){
			this.returnQty = retQty;
			this.agreement = agreement;
			this.dates = dates;
		}
	}

	class ReturnResult {

		List<Fulfillment__c> ReturnFulfillments {get; set;}
		JsonResult AgReturnJSON {get; set;}

		public returnResult(){}
	}

	static Map<String,List<SObject>> processReturn(ProcessReturnWrapper prw){

		ReturnResult processReturn = processReturn(prw, false);
		Map<String,List<SObject>> returnResult = new Map<String,List<SObject>>();

		returnResult.put('fulfillments', processReturn.ReturnFulfillments);
		return returnResult;
	}

	static ReturnResult processReturn(ProcessReturnWrapper prw, Boolean bypassAsserts){

		Agreement__c agreement = prw.agreement;

		ReturnResult ret = new ReturnResult();

		// Test Return for invoicing
		agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
				Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name,
				Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name,
				Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:agreement.id limit 1];

		AgreementReturnExt arExt = new AgreementReturnExt(new Apexpages.Standardcontroller(agreement));
		arExt.getfulfillmentLinesConfigJson();
		arExt.getfulfillmentLinesFieldList();

		
		JsonResult result = AgreementReturnExt.getFulfillments(agreement.id);
		

//		System.debug( logginglevel.error, '~*~ result.records :' + result.records );
		List<AgreementReturnExt.fulfillmentWrapper> fmtwrapperList = new List<AgreementReturnExt.fulfillmentWrapper>();
		for (AgreementReturnExt.fulfillmentWrapper fmtWrp : (List<AgreementReturnExt.fulfillmentWrapper>) result.records){

			fmtWrp.returnQty = prw.returnQty != null ? prw.returnQty : fmtWrp.flmt.Quantity__c;

			if(prw.dates.shippedDate2 != null
					&& fmtWrp.flmt.Start_Date__c != null
					&& fmtWrp.flmt.Start_Date__c.date() == prw.dates.shippedDate2.date())
			{
				fmtWrp.flmt.End_Date__c = prw.dates.returnDate2 != null ? prw.dates.returnDate2 : null;
			}

			else if(prw.dates.shippedDate != null
					&& fmtWrp.flmt.Start_Date__c != null
					&& fmtWrp.flmt.Start_Date__c.date() == prw.dates.shippedDate.date())
			{
				fmtWrp.flmt.End_Date__c = prw.dates.returnDate != null ? prw.dates.returnDate : null;
			}

			else {
				system.assert(false, 'Unknown start date: ' + fmtWrp.flmt.Start_Date__c + ' ' + prw.dates);
			}

			system.assert(fmtWrp.sol != null, 'Expecting these values for best pricing calculation');
			fmtwrapperList.add(fmtWrp);
		}

		
		result = AgreementReturnExt.createReceiptandUpdateFulfillments(fmtwrapperList);
		ret.AgReturnJSON = result;

		

		system.debug(LoggingLevel.Error, result);

		if (!bypassAsserts)
			system.assertEquals(true, result.success, result);

		List<Fulfillment__c> fulfillmentList = [SELECT Id, Billing_UOM__r.Name, Start_Date__c, End_Date__c, Invoice_Ready__c, Last_Bill_Date__c, Unit_Price__c, Pricing_UOM_Every__c, Quantity__c,
				Parent_Fulfillment__c, Recurrence_Start_Date__c, Pricing_UOM_Recurrence__c, Pricing_UOM__r.Name, Extended_Price__c FROM Fulfillment__c];
//		returnResult.put('fulfillments', fulfillmentList);
		ret.ReturnFulfillments = fulfillmentList;

		if (!bypassAsserts)
			system.assert(fulfillmentList.size() > 0);

		for (Fulfillment__c ful : fulfillmentList){
			System.debug( logginglevel.error, '~*~ comp ful (' + ful.Invoice_Ready__c + '): '+ ful.Extended_Price__c + ' - (' + ful.Quantity__c + ' * ' + ful.Unit_Price__c.setScale( 2, RoundingMode.HALF_UP ) + ') - ' + ful.Start_Date__c + ' - ' + ful.End_Date__c + ' - ' + ful.Recurrence_Start_Date__c + ' - Billing: ' + ful.Billing_UOM__r.Name + ' - Pricing: ' + ful.Pricing_UOM__r.Name);
		}

		//		validateFulfilments(fulfillmentList, prw.dates);

		return ret;
	}


	public static void validateFulfilments(List<Fulfillment__c> fulfillmentList, DateWrapper dates){

		DateTime returnDate = dates.returnDate;
		DateTime startDate = dates.startDate;
		DateTime recurrenceDate = dates.recurrenceDate;
		DateTime shippedDate = dates.shippedDate;

		//		system.assertEquals(1, fulfillmentList.size(), fulfillmentList.size() + ' ' + fulfillmentList); // There should be additional fulfillments based on UOM
		// 2 fulfillments created. Old Fulfillment is retired. New One has the correct end date of 8/2/23
		//		if (fulfillmentList[0].Pricing_UOM__c = fuel.StdMonth.id) {
		system.assert( fulfillmentList.size() > 1, fulfillmentList ); // There should be additional fulfillments based on UOM
		//		}
		//		else if (fulfillmentList[0].Pricing_UOM__c = fuel.SPSmonth.id){
		//			system.assert( fulfillmentList.size() == 0, fulfillmentList );
		//		}


		Boolean originalLineRetired = false;
		Decimal extendedPrice = 0;
		System.debug( logginglevel.error, '~*~ fulfillmentList.size() :' + fulfillmentList.size() );
		for (Fulfillment__c ful : fulfillmentList) {

			System.debug( logginglevel.error, '~*~ ful :' + ful );

			if (ful.Pricing_UOM__c == fuel.day.id){

				Set<Integer> possibleStartDay = new Set<Integer>{ 31 };
				system.assert( possibleStartDay.contains( ful.Start_Date__c.day() ), ful.Start_Date__c + 'Incorrect Start Date day' + ful.Start_Date__c.day() + ' not in ' + possibleStartDay + '' + ful );

				Set<Integer> possibleEndDay = new Set<Integer>{ recurrenceDate.day() };
				system.assert( possibleEndDay.contains( ful.End_Date__c.day() ), ful.End_Date__c + 'Incorrect End Date day: ' + ful.End_Date__c.day() + ' not in ' + possibleEndDay + '' + ful );

				system.assertEquals(70, ful.Unit_price__c);

			}
			else if (ful.Pricing_UOM__c == fuel.week.id){

				Set<Integer> possibleStartDay = new Set<Integer>{ shippedDate.day(), shippedDate.day() + 7 };
				system.assert( possibleStartDay.contains( ful.Start_Date__c.day() ), ful.Start_Date__c + 'Incorrect Start Date day' + ful.Start_Date__c.day() + ' not in ' + possibleStartDay + '' + ful );

				Set<Integer> possibleEndDay = new Set<Integer>{ shippedDate.day() + 7 , shippedDate.day() + 14 };
				system.assert( possibleEndDay.contains( ful.End_Date__c.day() ), ful.End_Date__c + 'Incorrect End Date day: ' + ful.End_Date__c.day() + ' not in ' + possibleEndDay + '' + ful );

				system.assertEquals(400, ful.Unit_price__c);

			}
			else if ( ful.Pricing_UOM__c == fuel.StdMonth.Id ) {

				Map<String,Decimal> correctAmounts = new Map<String,Decimal>{
						'1 Month(s)' => monthPrice,
						'22 Month(s)' => monthPrice/28*22, // prorate
						'24 Month(s)' => weekPrice,
						'31 Month(s)' => weekPrice
				};

				Set<Integer> possibleStartDay = new Set<Integer>{ shippedDate.day(), recurrenceDate.day() };
				system.assert( possibleStartDay.contains( ful.Start_Date__c.day() ), ful.Start_Date__c + 'Incorrect Start Date day' + ful.Start_Date__c.day() + ' not in ' + possibleStartDay + '' + ful.Start_date__c + ' ? ' + recurrenceDate );

				Set<Integer> possibleEndDay = new Set<Integer>{ returnDate.day(), recurrenceDate.day() };
				system.assert( possibleEndDay.contains( ful.End_Date__c.day() ), ful.End_Date__c + 'Incorrect End Date day: ' + ful.End_Date__c.day() + ' not in ' + possibleEndDay + '' + ful );

				Decimal dayRange = ful.Pricing_UOM_Every__c;
				if ( ful.Start_Date__c.day() == shippedDate.day() || ful.End_Date__c.day() == returnDate.day() ) {
					dayRange = decimal.valueOf( ful.Start_Date__c.date().daysBetween( ful.End_Date__c.date() ) );
					//					System.debug( logginglevel.error, '~*~ ful.Start_date__c  :' + ful.Start_date__c + ' => ' + ful.Start_date__c.date() + ' or ' + Date.newInstance( ful.Start_date__c.year(), ful.Start_date__c.month(), ful.Start_date__c.day() ) );
					//					System.debug( logginglevel.error, '~*~ ful.End_Date__c  :' + ful.End_Date__c + ' => ' + ful.End_Date__c.date() + ' or ' + Date.newInstance( ful.End_Date__c.year(), ful.End_Date__c.month(), ful.End_Date__c.day() ) );
				}
				String key = dayRange + ' ' + ful.Pricing_UOM_Recurrence__c;

				if ( ful.Invoice_Ready__c ) {
					extendedPrice += ful.Extended_Price__c;
					if ( !correctAmounts.containsKey( key ) ) {
						system.assert( false, 'Price not in map: ' + key + ' -> ' + ful.Unit_Price__c + ' ? ' + correctAmounts + ' ~ ' + ful );
					}
					//ba-todo: had to comment out because put month uom on everything. So 1 Month(s) could equal 1350 or 70.
					//					system.assertEquals( correctAmounts.get( key ).setScale( 2, RoundingMode.HALF_UP ), ful.Unit_Price__c.setScale( 2, RoundingMode.HALF_UP ), 'Unexpected Price: ' + key + correctAmounts + ' ~ ' + ful );
				}
				else {
					// invoice - return - invoice
					system.assertEquals( monthPrice, ful.Unit_price__c );

					if ( originalLineRetired == false ) {
						originalLineRetired = true;
					}
					else {
						system.assert( false, 'too many retired' + fulfillmentList );
					}
				}
			}
			else if ( ful.Pricing_UOM__c == fuel.SPSmonth.Id ) {
				if (ful.Invoice_Ready__c) {
					Map<String, Decimal> correctAmounts = new Map<String, Decimal>{
							'17-29' => 750.00, // 10 days
							'29-26' => monthPrice,
							'26-21' => monthPrice,
							'24-21' => monthPrice,
							'21-19' => monthPrice,
							'19-16' => monthPrice,
							'16-13' => monthPrice,
							'13-23' => 482.14,
							'21-23' => 482.14	// invoice-return flow. last fulfillment
					};

					String key = ful.Start_Date__c.day() + '-' + ful.End_Date__c.day();

					system.assert( correctAmounts.containsKey( key ), key + 'Incorrect Start Date day' + ful.Start_Date__c.day() + ' not in ' + correctAmounts.keySet() + '' + ful );
					system.assert( correctAmounts.containsKey( key ), key + 'Incorrect End Date day: ' + ful.End_Date__c.day() + ' not in ' + correctAmounts.keySet() + '' + ful );


					if ( !correctAmounts.containsKey( key ) ) {
						system.assert( false, 'Price not in map: ' + key + correctAmounts + ' ~ ' + ful );
					}
					system.assertEquals( correctAmounts.get( key ).setScale( 2, RoundingMode.HALF_UP ), ful.Unit_Price__c.setScale( 2, RoundingMode.HALF_UP ), 'Unexpected Price: ' + key + correctAmounts + ' ~ ' + ful );
				} else {
					// check non invoice ready fulfillment?
				}
			}
			else {
				system.assert( false, 'test not setup' + ful);
			}

			// boundry check
			system.assert( ful.Start_Date__c >= shippedDate, ful.start_date__c + ' >= ' + shippedDate + '\n' + ful );
			system.assert( ful.End_Date__c <= returnDate, ful.End_Date__c + ' <= ' + returnDate + '\n' + ful  );
		}
	}
	public static void validateInvoiceLines(List<Customer_Invoice_Line__c> cilList, DateWrapper dates){
		system.assert(cilList.Size() > 0, cilList.Size() );

		DateTime returnDate = dates.returnDate;
		DateTime startDate = dates.startDate;
		DateTime recurrenceDate = dates.recurrenceDate;
		DateTime shippedDate = dates.shippedDate;

		Decimal daysUsed = decimal.valueOf(shippedDate.date().daysBetween( Date.newInstance(2017,9,1)));

		System.debug( logginglevel.error, '~*~ cilList.size() :' + cilList.size() );
		for (Customer_Invoice_Line__c cil : cilList) {

			if (cil.Product__c == fuel.StdProduct1.id) {
				if ( cil.Pricing_UOM__c == fuel.week.Id ){

				}
				else if (cil.Pricing_UOM__c == fuel.day.id){

				}
				else if ( cil.Pricing_UOM__c == fuel.StdMonth.Id ) {

					Map<String, Decimal> correctAmounts = new Map<String, Decimal>{
							'15 Month(s)' => weekprice * 2 + dayPrice * 1,
							'1 Month(s)' => monthPrice,
							'22 Month(s)' => monthPrice / 31 * 22
					};

					Set<Integer> possibleEndDay = new Set<Integer>{ returnDate.day(), recurrenceDate.day() };
					system.assert( possibleEndDay.contains( cil.End_Date__c.day() ), cil.End_Date__c + 'Incorrect End Date day' + possibleEndDay + '' + cil );

					Set<Integer> possibleStartDay = new Set<Integer>{ shippedDate.day(), recurrenceDate.day() };
					system.assert( possibleStartDay.contains( cil.Start_Date__c.day() ), cil.Start_Date__c + 'Incorrect Start Date day' + possibleStartDay + '' + cil );

					Decimal cilDayRange = cil.Pricing_UOM_Every__c;
					if ( cil.Start_Date__c.day() == shippedDate.day() || cil.End_Date__c.day() == returnDate.day() ) {
						cilDayRange = decimal.valueOf( cil.Start_Date__c.date().daysBetween( cil.End_Date__c.date() ) );
					}
					String key = cilDayRange + ' ' + cil.Pricing_UOM_Recurrence__c;
					if ( !correctAmounts.containsKey( key ) ) {
						system.assert( false, 'Price not in map: ' + key + correctAmounts + ' ~ ' + cil );
					}
					system.assertEquals( correctAmounts.get( key ).setScale( 2, RoundingMode.HALF_UP ), cil.Unit_Price__c.setScale( 2, RoundingMode.HALF_UP ), 'Unexpected Price: ' + key + correctAmounts + ' ~ ' + cil );
				} else {
					system.assert(false, 'unknown pricing uom ' + cil);
				}
			}

			// single Monthly UOM product
			else if ( cil.Pricing_UOM__c == fuel.StdMonth.Id && cil.Product__c == fuel.StdProduct4.Id){

				Map<String,Decimal> correctAmounts = new Map<String,Decimal>{
						'15 Month(s)' => monthPrice/31*15,
						'1 Month(s)' => monthPrice,
						'22 Month(s)' => monthPrice/31*22
				};

				Set<Integer> possibleEndDay = new Set<Integer>{returnDate.day(), recurrenceDate.day()};
				system.assert( possibleEndDay.contains(cil.End_Date__c.day()),  cil.End_Date__c + 'Incorrect End Date day' + possibleEndDay );

				Set<Integer> possibleStartDay = new Set<Integer>{shippedDate.day(), recurrenceDate.day()};
				system.assert( possibleStartDay.contains(cil.Start_Date__c.day()), cil.Start_Date__c + 'Incorrect Start Date day' + possibleStartDay );

				Decimal cilDayRange = cil.Pricing_UOM_Every__c;
				if ( cil.Start_Date__c.day() == shippedDate.day() || cil.End_Date__c.day() == returnDate.day()) {
					cilDayRange = decimal.valueOf( cil.Start_Date__c.date().daysBetween( cil.End_Date__c.date() ) );
				}
				String key = cilDayRange + ' ' + cil.Pricing_UOM_Recurrence__c;
				if ( !correctAmounts.containsKey( key ) ) {
					system.assert( false, 'Price not in map: ' + key + correctAmounts + ' ~ ' + cil );
				}
				system.assertEquals( correctAmounts.get( key ).setScale(2, RoundingMode.HALF_UP), cil.Unit_Price__c.setScale(2, RoundingMode.HALF_UP), 'Unexpected Price: ' + key + correctAmounts + ' ~ ' + cil );
			}
			else if (cil.Pricing_UOM__c == fuel.SPSMonth.Id){
				Decimal every = fuel.SPSmonth.Every__c;

			} else {
				system.assert(false, 'testing not setup yet' + cil);
			}
		}
	}

	public static decimal getSumTotal(List<sObject> records){

		Decimal sum = 0;
		for (sObject record : records){

			if (record.getSObjectType() == Customer_Invoice_Line__c.getSObjectType()) {
				//				System.debug( logginglevel.error, '~*~ record :' + record );
				sum += (Decimal) record.get('Extended_Price__c');
				System.debug( logginglevel.error, '~*~ sum :' + sum );
			}
			else if (record.getSObjectType() == Fulfillment__c.getSObjectType()) {
				if ( (Boolean) record.get('Invoice_Ready__c')) {
					//					System.debug( logginglevel.error, '~*~ record :' + record );
					sum += (Decimal) record.get('Extended_Price__c');
					System.debug( logginglevel.error, '~*~ sum :' + sum );
				}
			}
		}

		//		system.assertEquals(expectedAmt.setScale(2, RoundingMode.HALF_UP), sum.setScale(2, RoundingMode.HALF_UP), 'difference of: ' + Math.abs(expectedAmt - sum).setScale(2, RoundingMode.HALF_UP));
		return sum;
	}

}