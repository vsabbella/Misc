@isTest
private class SalesOrderLineExtTest {
    
    /*    
      Test SalesOrderLineExt.getSOLineInfo() method to fail when no product or pricebook is found for a call
      */
    public static testMethod void test_SalesOrderLineExt_getSOLineInfo_No_Product_Found_Case() {        
        TestFuel data = new TestFuel();  
        system.assert( data.company !=null && data.product != null);
        
        boolean didthrow = false;
        try {
            Sales_Order_Line__c soLine = SalesOrderLineExt.getSOLineInfo(
                data.company.Id, 
                null, 
                'Some really bad and very bad product name which couldnt ever exist in galaxy', 
                null, null, null);
            
        } catch( exception e) { didthrow = true;}
        system.assert( didthrow , 'expected to throw');        
        
        
        didthrow = false;
        try {
            Sales_Order_Line__c soLine = SalesOrderLineExt.getSOLineInfo(
                data.company.Id, null, 
                data.product.name, 
                null, 'some really awful name for pricebook', null);
        } catch( exception e) { didthrow = true;}
        system.assert( didthrow , 'expected to throw');    
    }
    
    // Test SalesOrderLineExt.getSOLineInfo() method when no PB Lines exists
    public static testMethod void test_SalesOrderLineExt_getSOLineInfo_No_PricebookLines() {
        TestFuel data = new TestFuel();
        system.assert( data.company !=null && data.product != null);
        
        // create a pricebook with no products
        data.pricebook = new Pricebook__c(); 
        data.pricebook.name = data.company.Name +  ' Orange Pricebook';
        data.pricebook.company__c = data.company.id; 
        data.pricebook.Primary_Key__c = 'NATBOOK';
        insert data.pricebook; 
        
        test.startTest();
        boolean didthrow = false;
        try {
            Sales_Order_Line__c soLine = SalesOrderLineExt.getSOLineInfo(data.company.Id, null, data.product.name, 
                                                                         data.pricebook.Id, null, null);
            System.assert(false, 'Should not match with any Pricebook line and fail here');
        } catch(SalesOrderLineExt.SOLException sole) { didthrow = true;}
        system.assert( didthrow , 'expected to throw'); 
        
        // cover empty constructor as well
        SalesOrderLineExt ext = new SalesOrderLineExt(new ApexPages.Standardcontroller(data.salesOrder));    
        system.assert( ext != null , ' could not create SalesOrderLineExt');
        
    }
    


    // SalesOrderLineExt.getSOLineInfo() method with PB Line matches with customer sold to pricebook parameter
    public static testMethod void test_SalesOrderLineExt_getSOLineInfo_Customer_SOLD_TO_PricebookLines_Match() {
        TestFuel data = new TestFuel();
        system.assert( data.company !=null && data.product != null);
        
        // create a pricebook with no products
        data.pricebook = new Pricebook__c(); 
        data.pricebook.name = data.company.Name +  ' Orange Pricebook';
        data.pricebook.company__c = data.company.id; 
        data.pricebook.Primary_Key__c = 'NATBOOK';
        insert data.pricebook; 
        
		test.startTest();
        // Create a few Product Group and 
        Product_Group__c pGroup1 = new Product_Group__c(Name = 'Prod Grp 1', Company__c= data.company.Id);
        insert pGroup1;

        // Associate Product with Product group
        data.product.Product_Group__c = pGroup1.Id;        
        update data.product;

        // Create a Pricebook line for Product Group 1
        Pricebook_Line__c pbLineGrp1 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today(), End_Date__c = Date.today()+10);                
        insert pbLineGrp1;

        
        Sales_Order_Line__c soLine = SalesOrderLineExt.getSOLineInfo(data.company.Id, null, data.product.name, null, null, data.pricebook.Id);
        
        System.assertNotEquals(null, soLine, 'Should get a valid SO Line in result');
        System.assertEquals(pbLineGrp1.Price__c, soLine.Unit_Price__c);
        System.assertEquals(data.product.Selling_UOM__c, soLine.Selling_UOM__r.Id);
        System.assertEquals(data.product.Description__c, soLine.Description__c);
        System.assertEquals(data.product.Id, soLine.Product__r.Id);
     }


    // SalesOrderLineExt.getSOLineInfo() method with PB Line matches for SO Pricebook
    public static testMethod void test_SalesOrderLineExt_getSOLineInfo_SO_Level_PricebookLines_Match() {
        TestFuel data = new TestFuel();
        system.assert( data.company !=null && data.product != null);
        
        // create a pricebook with no products
        data.pricebook = new Pricebook__c(); 
        data.pricebook.name = data.company.Name +  ' Orange Pricebook';
        data.pricebook.company__c = data.company.id; 
        data.pricebook.Primary_Key__c = 'NATBOOK';
        insert data.pricebook; 
        
        // Create a few Product Group and 
        Product_Group__c pGroup1 = new Product_Group__c(Name = 'Prod Grp 1', Company__c= data.company.Id);
        insert pGroup1;

        // Associate Product with Product group
        data.product.Product_Group__c = pGroup1.Id;        
        update data.product;

        // Create a Pricebook line for Product Group 1
        Pricebook_Line__c pbLineGrp1 = new Pricebook_Line__c( 
            pricebook__c = data.pricebook.id, 
            Product_Group__c = pGroup1.id, 
            Price__c = 5.000000, 
            Start_date__c = Date.today(), 
            End_Date__c = Date.today()+10);                
        insert pbLineGrp1;
		
        Test.startTest();

        Sales_Order_Line__c soLine = SalesOrderLineExt.getSOLineInfo(data.company.Id, null, data.product.name, null, data.pricebook.Name, null);
        
        System.assertNotEquals(null, soLine, 'Should get a valid SO Line in result');
        System.assertEquals(pbLineGrp1.Price__c, soLine.Unit_Price__c);
        System.assertEquals(data.product.Selling_UOM__c, soLine.Selling_UOM__r.Id);
        System.assertEquals(data.product.Description__c, soLine.Description__c);
        System.assertEquals(data.product.Id, soLine.Product__r.Id);
     }



      // SalesOrderLineExt.getSOLineInfo() method with PB Line matches for company level pricebook, as there was no match using SO's Pricebook record
    public static testMethod void test_SalesOrderLineExt_getSOLineInfo_PricebookLines_Company_Level_Match() {
        TestFuel data = new TestFuel();
        system.assert( data.company !=null && data.product != null);
        
        // create a pricebook with no products
        data.pricebook = new Pricebook__c(); 
        data.pricebook.name = data.company.Name +  ' Orange Pricebook';
        data.pricebook.company__c = data.company.id; 
        data.pricebook.Description__c = 'Covers high volume customers, and distributors';
        data.pricebook.default__c = true;
        data.pricebook.Primary_Key__c = 'NATBOOK';
        insert data.pricebook; 

        // Create a Pricebook line for Product Group 1
        Pricebook_Line__c pbLineGrp1 = new Pricebook_Line__c( 
            pricebook__c = data.pricebook.id, 
            Product__c = data.product.id, 
            Price__c = 5.000000, 
            Start_date__c = Date.today(), 
            End_Date__c = Date.today()+10);                
        insert pbLineGrp1;

        Sales_Order_Line__c soLine = SalesOrderLineExt.getSOLineInfo(data.company.Id, null, data.product.name, null, null, null);
        
        System.assertNotEquals(null, soLine, 'Should get a valid SO Line in result');
        System.assertEquals(pbLineGrp1.Price__c, soLine.Unit_Price__c);
        System.assertEquals(data.product.Selling_UOM__c, soLine.Selling_UOM__r.Id);
        System.assertEquals(data.product.Description__c, soLine.Description__c);
        System.assertEquals(data.product.Id, soLine.Product__r.Id);     
     }
	
     public static testMethod void test_SalesOrderLinesRequiredDate() { 
        TestFuel data = new TestFuel();
        Test.StartTest();
        Sales_Order__c soRD = data.salesOrder;
        soRD.Required_Date__c = NULL;
        update soRD;
        
        SalesOrderLinesAddManageExt solAM = new SalesOrderLinesAddManageExt(new apexpages.standardController(soRD));
        solAM.addNewRow();
        solAM.soLineList[2].soLine.Quantity_Ordered__c = 10;
        solAM.soLineList[2].soLine.Unit_Price__c = 1;
        solAM.soLineList[2].soLine.Discount_Percent__c = 1;
        solAM.soLineList[2].soLine.Product__c = data.product.id;
        solAM.save_lines();
        system.assertEquals(solAM.soLineList[2].soLine.Required_Date__c,soRD.Required_Date__c);
        system.assertEquals(null,solAM.soLineList[2].soLine.Required_Date__c);
        test.stopTest();
        
    }
    
}