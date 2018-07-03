/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 */
@isTest
private class PriceBookTest {
     /*
        KNDY-3687 Test new validations
    */
    testMethod static void testPricebookLineExpiryValidationsWithEndDateAndPrice() {
        // stop unnecessary creation of SO data
        TestFuel fuel = new TestFuel();
        
        Pricebook__c pricebook = fuel.newPricebook();
        insert pricebook;
         
        //Pricebook__c pricebook = new Pricebook__c(); 
        //pricebook.name = fuel.company.Name +  ' Orange Pricebook';
        //pricebook.company__c = fuel.company.id; 
        //pricebook.Primary_Key__c = 'NATBOOK';
        //insert pricebook; 
        
        Date pblEndDate = System.today().addDays(100);
        
        Pricebook_Line__c pl1 = new Pricebook_Line__c(
            product__c = fuel.product2.id,
            pricebook__c = pricebook.id,
            price__c = 200,
            Use_Fixed_Pricing__c = true,
            Start_date__c = system.today(),
            End_Date__c = pblEndDate
        );
        
        insert pl1;
        
        System.assert(fuel.salesOrder != null);

        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Product__c = fuel.product2.id;
        soLine.Quantity_Ordered__c = 2;
        soLine.Company__c = fuel.salesOrder.Company__c;
        soLine.Sales_Order__c = fuel.salesOrder.Id;
        insert soLine; 

        pl1 = [SELECT Id, Start_Date__c, End_Date__c, Price__c FROM Pricebook_Line__c LIMIT 1];

        pl1.Price__c = 300;
        pl1.End_Date__c = System.today().addDays(2);
        
        test.startTest();
        
        try {
            update pl1;
            
            Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>(
                                                        [Select Id, Price__c, Start_date__c, End_Date__c from Pricebook_Line__c Where Pricebook__c =:pricebook.id]);
            
            System.assertEquals(2, pbLinesById.size(), 'After expiry one more line should be created');
            Pricebook_Line__c pl1Exp  = pbLinesById.get(pl1.Id);
            pbLinesById.remove(pl1.Id);
            Pricebook_Line__c pl1New = pbLinesById.values()[0];
            
            System.assertEquals(pl1.Start_Date__c, pl1Exp.Start_Date__c);
            System.assertEquals(pl1.End_Date__c, pl1Exp.End_Date__c);
            System.assertEquals(200, pl1Exp.Price__c,' Old price should be retained as its expired ');
            
            System.assertEquals(pl1.End_Date__c.addDays(1), pl1New.Start_Date__c, 'Should start after 1 day from expired line');
            System.assertEquals(pblEndDate, pl1New.End_Date__c, 'New line should carry original end date');
            System.assertEquals(300, pl1New.Price__c,' Old price should be retained as its expired ');
            
        } catch (System.DMLException dmle)  {
            System.assert(false, dmle.getMessage());
        }
        
        
        // KNDY-6022 test that we cannot delete an active PB line 
        boolean diddelete = true;
        system.assert( pl1.Start_Date__c <= system.today() );
        system.assert( pl1.End_Date__c > system.today() );
        try { 
            delete pl1; 
        } catch( System.DMLException dmle) {
            diddelete = false; 
        }
        system.assert( diddelete == false, ' expected that delete on an active PBLine is not allowed ');        

        // KNDY-6022 make an inactive line and verify we can delete        
        Pricebook_Line__c pl_future = new Pricebook_Line__c(
            product__c = fuel.product.id,
            pricebook__c = pricebook.id,
            price__c = 200,
            Use_Fixed_Pricing__c = true,
            Start_date__c = system.today().addDays(1000),
            End_Date__c = system.today().addDays(1002)
        );        
        insert pl_future;       
        delete pl_future; // so this delete should work
    }
    
    testMethod static void testPricebookLineExpiryNoAttachedSOL() {
        // Test for OTC-805:Don't expire PBL with no attached SOL
        TestFuel fuel = new TestFuel();
        
        Pricebook__c pricebook = fuel.pricebook;
        
        //insert pl1;
        Pricebook_Line__c pl1 = [SELECT Id FROM Pricebook_Line__c LIMIT 1];

        pl1.Price__c = 300;
        pl1.End_Date__c = System.today().addDays(2);
        
        Test.startTest();
        
        update pl1;
        
        Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>(
                                                    [SELECT Id, Price__c, Start_date__c, End_Date__c
                                                       FROM Pricebook_Line__c 
                                                      WHERE Pricebook__c = :pricebook.Id]);
        
        System.assertEquals(3, pbLinesById.size(), 'After expiry one more line should be created');


    }

    testMethod static void testPricebookLineExpiryWithAttachedSOL() {
        // Test for OTC-805:Don't expire PBL with no attached SOL
        TestFuel fuel = new TestFuel();
        Pricebook__c pricebook = fuel.pricebook;
        
        System.assert(fuel.salesOrder != null);
        System.assert(fuel.salesOrderLines != null);


        Pricebook_Line__c pl1 = [SELECT Id FROM Pricebook_Line__c LIMIT 1];
        pl1.Price__c = 300;
        pl1.End_Date__c = System.today().addDays(2);
        
        Test.startTest();
        
        update pl1;
        
        Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>(
                                                    [SELECT Id, Price__c, Start_date__c, End_Date__c
                                                       FROM Pricebook_Line__c 
                                                      WHERE Pricebook__c = :pricebook.Id]);
        
        System.assertEquals(4, pbLinesById.size(), 'After expiry no more lines should be created');

    }
     /*
        KNDY-3687 Test new validations
    */
    testMethod static void testPricebookLineExpiryValidations() {
        // stop unnecessary creation of SO data
        TestFuel data = new TestFuel();
        
         
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.name = data.company.Name +  ' Orange Pricebook';
        pricebook.company__c = data.company.id; 
        pricebook.Primary_Key__c = 'NATBOOK';
        insert pricebook; 
        
        
        // Should not change as its in future
        Pricebook_Line__c pl1 = new Pricebook_Line__c(
            product__c = data.product.id,
            pricebook__c = pricebook.id,
            price__c = 100,
            Use_Fixed_Pricing__c = false,
            Start_date__c = system.today().addDays(-10), 
            End_Date__c = System.today().addDays(20)
        );
        
        
        /*
        //DP: changing this for diagnostics KNDY-4989
        try {
            insert pl1;
            System.assert(false, 'should fail as historical date rule is no more permitted');
        } catch (System.DMLException dmle)  {}
        */
        
        String eMsg;
        try {
            insert pl1;
        } catch (Exception e){
            eMsg = e.getMessage();
        }
        System.assertNotEquals(null, eMsg, 'should fail as historical date rule is no more permitted + ('+eMsg+') pl1: '+ pl1);
                
        
        
        
        
        Pricebook_Line__c pl2 = new Pricebook_Line__c(
            product__c = data.product2.id,
            pricebook__c = pricebook.id,
            price__c = 200,
            Use_Fixed_Pricing__c = true,
            Start_date__c = system.today(),
            End_Date__c = System.today()
        );
        
        insert pl2;
        
        pl2.Price__c = 300;
        
        try {
            update pl2;
            System.assert(false, 'should fail as start date cannot be bigger then end date');
        } catch (System.DMLException dmle)  {}
        
        
        
    }
    
    
     /*
        KNDY-3687 Test Expiry
    */
    testMethod static void testPricebookLineExpiry() {
        // stop unnecessary creation of SO data
        TestFuel data = new TestFuel();
        
        Pricebook__c pricebook = data.newPricebook();
        insert pricebook; 
        
        
        // Should not change as its in future
        Pricebook_Line__c pl1 = new Pricebook_Line__c(
            product__c = data.product.id,
            pricebook__c = pricebook.id,
            price__c = 100,
            Use_Fixed_Pricing__c = false,
            Start_date__c = system.today().addDays(1), 
            End_Date__c = System.today().addDays(20)
        );
        
        Pricebook_Line__c pl2 = new Pricebook_Line__c(
            product__c = data.product2.id,
            pricebook__c = pricebook.id,
            price__c = 200,
            Use_Fixed_Pricing__c = true,
            Start_date__c = system.today(),
            End_Date__c = System.today().addDays(20)
        );
        
        Pricebook_Line__c pl3 = new Pricebook_Line__c(
            product__c = data.product3.id,
            pricebook__c = pricebook.id,
            price__c = 300,
            Use_Fixed_Pricing__c = false,
            Start_date__c = system.today(),
            End_Date__c = System.today().addDays(20)
        );
        
        insert new Pricebook_Line__c[]{pl1, pl2, pl3};
        
        //data.pricebook = pricebook;
        System.assert(data.salesOrder != null);
        data.salesOrder.Pricing_Date__c = System.today();
        update data.salesOrder;

        data.salesOrderLines[0].Pricebook__c = pricebook.Id;
        data.salesOrderLines[1].Pricebook__c = pricebook.Id;
        update data.salesOrderLines;
        
        Sales_Order_Line__c salesOrderLine3 = new Sales_Order_Line__c();
        salesOrderLine3.Company__c = data.company.id;
        salesOrderLine3.Description__c = data.product3.Description__c;
        salesOrderLine3.Discount_Percent__c = 2;
        salesOrderLine3.Pricebook__c = pricebook.Id;
        salesOrderLine3.Product__c = data.product3.Id;
        salesOrderLine3.Quantity_Ordered__c = 15;
        salesOrderLine3.Required_Date__c = System.today()+15;
        salesOrderLine3.Sales_Order__c = data.salesOrder.Id;
        salesOrderLine3.Ship_From_Location__c = data.location2.Id;
        salesOrderLine3.Unit_Price__c = 12.11;
        salesOrderLine3.Memo__c = 'salesOrderLine3';
        insert salesOrderLine3;
        Test.startTest();
        
        //      
        // Create Brackets
        //
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(data.company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 100;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 1000;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 2000;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 3000;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
       
        Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>([
                                                        select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c 
                                                        from Pricebook_Line__c 
                                                        where Pricebook__c =:pricebook.Id
                                                    ]);
        Pricebook_Line__c pl1Rel = pbLinesById.get(pl1.Id);
        pl1Rel.Price__c = 200; // change pricing
            
        Pricebook_Line__c pl2Rel = pbLinesById.get(pl2.Id);
        pl2Rel.Use_Fixed_Pricing__c = false; // change from true to false
        
        Pricebook_Line__c pl3Rel = pbLinesById.get(pl3.Id);
        pl3Rel.Price__c = 400;// change price
        update new Pricebook_Line__c[] {pl1Rel, pl2Rel, pl3Rel};
        
        // Reload lines to check expiry and splits
        
        pbLinesById = new Map<Id, Pricebook_Line__c>([
                                                        select Use_Fixed_Pricing__c, Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c, End_Date__c, Start_date__c
                                                        from Pricebook_Line__c 
                                                        where Pricebook__c =:pricebook.Id
                                                    ]);
        
        System.assertEquals(5, pbLinesById.size());
        
        
        pl1Rel = pbLinesById.get(pl1.Id);
        System.assertEquals( 200, pl1Rel.Price__c, 'Price change should persist as its in future dates'); 
            
        pl2Rel = pbLinesById.get(pl2.Id);
        System.assertEquals(true, pl2Rel.Use_Fixed_Pricing__c,'Should be reverted back to true from false, as its a line in current date and line should be expired' );
        System.assertEquals(System.today(), pl2Rel.End_Date__c,'Expired line should end on TODAY' );
        
        pl3Rel = pbLinesById.get(pl3.Id);
        System.assertEquals(pl3.Price__c, pl3Rel.Price__c, 'Line should be expired and price change shouldnot be considered');
        System.assertEquals(System.today(), pl3Rel.End_Date__c,'Expired line should end on TODAY' );
        
        Test.stopTest();
    } 
    
    // OTC-484
    testMethod static void testPricebookLineChangeDate() {
        // stop unnecessary creation of SO data
        TestFuel data = new TestFuel();
        
         
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.Name = data.company.Name +  ' Orange Pricebook';
        pricebook.Company__c = data.company.id; 
        pricebook.Primary_Key__c = 'NATBOOK';
        insert pricebook; 
        
        // Both lines are considered active, because the start date is today.
        Pricebook_Line__c pl1 = new Pricebook_Line__c(
            Product__c = data.product.id,
            Pricebook__c = pricebook.id,
            Price__c = 100,
            Use_Fixed_Pricing__c = true,
            Start_date__c = System.today(), 
            End_Date__c = System.today().addDays(20)
        );
        
        Pricebook_Line__c pl2 = new Pricebook_Line__c(
            Product__c = data.product2.id,
            Pricebook__c = pricebook.id,
            Price__c = 100,
            Use_Fixed_Pricing__c = true,
            Start_date__c = System.today(),
            End_Date__c = System.today().addDays(20)
        );
        
        Pricebook_Line__c pl3 = new Pricebook_Line__c(
            product__c = data.product3.id,
            pricebook__c = pricebook.id,
            price__c = 300,
            Use_Fixed_Pricing__c = false,
            Start_date__c = system.today(),
            End_Date__c = System.today().addDays(20)
        );
        insert new Pricebook_Line__c[]{pl1, pl2, pl3};
        data.pricebook = pricebook;
        
        System.assert(data.salesOrder != null);

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = data.company.Id;
        salesOrderLine.Description__c = data.product.Description__c;
        salesOrderLine.Discount_Percent__c = 2;
        salesOrderLine.Product__c = data.product.Id;
        salesOrderLine.Quantity_Ordered__c = 100;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = data.salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = data.location2.Id;
        //salesOrderLine.Unit_Price__c = 11.12;
        salesOrderLine.Memo__c = 'salesOrderLine';

        Sales_Order_Line__c salesOrderLine2 = new Sales_Order_Line__c();
        salesOrderLine2.Company__c = data.company.id;
        salesOrderLine2.Description__c = data.product2.Description__c;
        salesOrderLine2.Discount_Percent__c = 2;
        salesOrderLine2.Product__c = data.product2.Id;
        salesOrderLine2.Quantity_Ordered__c = 15;
        salesOrderLine2.Required_Date__c = System.today()+15;
        salesOrderLine2.Sales_Order__c = data.salesOrder.Id;
        salesOrderLine2.Ship_From_Location__c = data.location2.Id;
        //salesOrderLine2.Unit_Price__c = 12.11;
        salesOrderLine2.Memo__c = 'salesOrderLine2';

        Sales_Order_Line__c salesOrderLine3 = new Sales_Order_Line__c();
        salesOrderLine3.Company__c = data.company.id;
        salesOrderLine3.Description__c = data.product3.Description__c;
        salesOrderLine3.Discount_Percent__c = 2;
        salesOrderLine3.Product__c = data.product3.Id;
        salesOrderLine3.Quantity_Ordered__c = 15;
        salesOrderLine3.Required_Date__c = System.today()+15;
        salesOrderLine3.Sales_Order__c = data.salesOrder.Id;
        salesOrderLine3.Ship_From_Location__c = data.location2.Id;
        //salesOrderLine3.Unit_Price__c = 12.11;
        salesOrderLine3.Memo__c = 'salesOrderLine3';
        insert new Sales_Order_Line__c[]{salesOrderLine, salesOrderLine2, salesOrderLine3};
        
        Test.startTest();
        
        // Create Brackets
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(data.company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 100;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 1000;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 2000;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 3000;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
       
        Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>([
                                                        SELECT Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c, End_Date__c
                                                        FROM Pricebook_Line__c 
                                                        WHERE Pricebook__c =:pricebook.Id
                                                    ]);
        Pricebook_Line__c pl1Rel = pbLinesById.get(pl1.Id);
        pl1Rel.Price__c = 200;                              // Change Price and End Date
        pl1Rel.End_Date__c = System.today().addDays(10);    // from 20 to 10
            
        Pricebook_Line__c pl2Rel = pbLinesById.get(pl2.Id); // Change End Date
        pl2Rel.End_Date__c = System.today().addDays(10);    // from 20 to 10
        
        Pricebook_Line__c pl3Rel = pbLinesById.get(pl3.Id); // Change End Date
        pl3Rel.Price__c = 200;                              // from 300 to 200
        pl3Rel.End_Date__c = System.today().addDays(10);    // from 20 to 10
        
        update new Pricebook_Line__c[] {pl1Rel, pl2Rel, pl3Rel};
        
        // Reload lines to check expiry and splits
        pbLinesById = new Map<Id, Pricebook_Line__c>([
                                                        SELECT Use_Fixed_Pricing__c, Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c, End_Date__c, Start_date__c
                                                        FROM Pricebook_Line__c 
                                                        WHERE Pricebook__c =:pricebook.Id AND Product__c <> :data.product3.Id
                                                    ]);
        // 1,2
        System.assertEquals(3, pbLinesById.size()); // 1 cloned line + the 2 original
        
        pl1Rel = pbLinesById.get(pl1.Id);
        System.assertEquals(100, pl1Rel.Price__c, 'Starting price of 100 expected. The cloned line will have a price of 200. '); 
        System.assertEquals(System.today(), pl1Rel.Start_Date__c, 'Start date should remain the same.');
        System.assertEquals(System.today().addDays(10), pl1Rel.End_Date__c, 'Old line should end on TODAY + 10' );
            
        pl2Rel = pbLinesById.get(pl2.Id);
        System.assertEquals(System.today(), pl2Rel.Start_Date__c, 'Line should still start today' );
        System.assertEquals(System.today().addDays(10), pl2Rel.End_Date__c, 'Line should end on TODAY+10' );

        //Find the cloned line
        pbLinesById.keySet().removeAll(new set<Id>{pl1.Id, pl2.Id});
        Pricebook_Line__c pl1Clone = pbLinesById.get(new list<Id>(pbLinesById.keySet())[0]);
        System.assertEquals(200, pl1Clone.Price__c, 'Starting price of 100 expected. The cloned line will have a price of 200. '); 
        System.assertEquals(System.today().addDays(11), pl1Clone.Start_Date__c, 'Start date should be 10 + 1');
        System.assertEquals(System.today().addDays(20), pl1Clone.End_Date__c, 'New end date should be TODAY + 20' );
        Test.stopTest();

        // 3
        Map<Id, Pricebook_Line__c> pbLinesFromPbl3 = new Map<Id, Pricebook_Line__c> ([SELECT Use_Fixed_Pricing__c, Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c, End_Date__c, Start_date__c
                                                                                      FROM Pricebook_Line__c 
                                                                                      WHERE Product__c = :data.product3.Id]);
        System.assertEquals(2, pbLinesFromPbl3.size());  
        pl3Rel = pbLinesFromPbl3.get(pl3.Id);
        System.assertEquals(System.today(), pl3Rel.Start_Date__c, 'Line should still start today' );
        System.assertEquals(System.today().addDays(10), pl3Rel.End_Date__c, 'Line should end on TODAY+10' );
        pbLinesFromPbl3.keySet().removeAll(new set<Id>{pl3.Id});
        Pricebook_Line__c pbl3Clone = pbLinesFromPbl3.values()[0];
        System.assertEquals(200, pbl3Clone.Price__c, 'Starting price of 300 expected. The cloned line will have a price of 200. '); 
        System.assertEquals(System.today().addDays(11), pbl3Clone.Start_Date__c, 'Start date should be 10 + 1');
        System.assertEquals(System.today().addDays(20), pbl3Clone.End_Date__c, 'New end date should be TODAY + 20' );

        

    } 

    public static testMethod void testKndy3608(){
        TestFuel fuel = new TestFuel();
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 100;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 150;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 200;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
                
        
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.name = fuel.company.Name +  ' Orange Pricebook';
        pricebook.company__c = fuel.company.id; 
        pricebook.Primary_Key__c = 'NATBOOK';
        insert pricebook; 
        
        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 10;
        pl.Use_Fixed_Pricing__c = false;
        pl.Start_date__c = system.today().addDays(1); 
        pl.End_date__c = pl.Start_date__c.addDays(3);
        
        insert pl;
        
        Pricebook_Line__c plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(10.1, plReloaded.Price_2__c);
        System.assertEquals(10.2, plReloaded.Price_3__c);
        System.assertEquals(10.3, plReloaded.Price_4__c);
        System.assertEquals(10.4, plReloaded.Price_5__c);
        
        
        // change the price__c field to see if everything is recalculated
        plReloaded.Price__c = 20;
        update plReloaded;
        
        plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(20.2, plReloaded.Price_2__c);
        System.assertEquals(20.4, plReloaded.Price_3__c);
        System.assertEquals(20.6, plReloaded.Price_4__c);
        System.assertEquals(20.8, plReloaded.Price_5__c);
        
        // This should clear all other price fields
        plReloaded.Use_Fixed_Pricing__c = true;
        update plReloaded;
        
        plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(null, plReloaded.Price_2__c);
        System.assertEquals(null, plReloaded.Price_3__c);
        System.assertEquals(null, plReloaded.Price_4__c);
        System.assertEquals(null, plReloaded.Price_5__c);
    }
    

    /* 
        Test case to reproduce KNDY-3296.
        This test case checks Pricebook Line's Use_Fixed_Pricing__c field to clear 
        Bracket pricing field i.e. Price_2__c - Price_N__c field.
    */
    testmethod static void testKndy3296() {
        TestFuel fuel = new TestFuel();
        
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.name = fuel.company.Name +  ' Orange Pricebook';
        pricebook.company__c = fuel.company.id; 
        insert pricebook; 
        
        // This Line has Fixed pricing enabled so it should clear all the other fields
        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.Use_Fixed_Pricing__c = true;
        pl.price__c = 11.12;
        pl.Price_2__c = 12;
        pl.Price_3__c = 13;
        pl.Price_4__c = 14;
        pl.Price_5__c = 15;
        pl.Start_date__c = system.today(); 
        
        Pricebook_Line__c pl2 = new Pricebook_Line__c();
        pl2.product__c = fuel.product2.id;
        pl2.pricebook__c = pricebook.id;
        pl2.Use_Fixed_Pricing__c = false;
        pl2.price__c = 12.11;
        pl2.Price_2__c = 12.12;
        pl2.Price_3__c = 13.12;
        pl2.Price_4__c = 14.12;
        pl2.Price_5__c = 15.12;
        pl2.Start_date__c = system.today();
        
        // note product3 is not in any pricebook        
        insert new List<Pricebook_Line__c>{pl,pl2};
        
        Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>([Select Price_2__c, Price_3__c, Price_4__c, Price_5__c 
                                                                                 from Pricebook_Line__c Where
                                                                                 Id IN :new Set<Id>{pl.Id, pl2.Id}]);
        Pricebook_Line__c plReload = pbLinesById.get(pl.Id);
        Pricebook_Line__c pl2Reload = pbLinesById.get(pl2.Id);
        
        // As fixed pricing in enabled on this line, all the values should get cleared
        System.assertEquals(null, plReload.Price_2__c);
        System.assertEquals(null, plReload.Price_3__c);
        System.assertEquals(null, plReload.Price_4__c);
        System.assertEquals(null, plReload.Price_5__c);
        
        // This line is flexible so should NOT sustain prices
        System.assertEquals(null, pl2Reload.Price_2__c);
        System.assertEquals(null, pl2Reload.Price_3__c);
        System.assertEquals(null, pl2Reload.Price_4__c);
        System.assertEquals(null, pl2Reload.Price_5__c);
    }
    
    public static testMethod void testValidLines(){
        
        Company__c testCompany = new Company__c( Name = 'Test Company');
        Testcompany.Comp_Currency__c = TestFuel.currencySGD.id;
        Testcompany.Consol_Currency__c = TestFuel.currencyEUR.id;
        Testcompany.Stat_Currency__c = TestFuel.currencyGBP.id;
        Testcompany.Subs_Currency__c = TestFuel.currencyUSD.id;
        Testcompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;     
        insert testCompany;
        
        Item__c testItem = new Item__c( Name = 'Test Item', Company__c = testCompany.id, Active__c = true, Source__c = 'Purchased');
        insert testItem;
        
        Product__c testProduct = new Product__c( Name = 'Test Product', Company__c = testCompany.id, Item__c = testItem.id );
        insert testProduct;
        
        Pricebook__c testPriceBook = new Pricebook__c( Name = 'Test Price Book', Currency__c = TestFuel.currencyUSD.id);
        insert testPriceBook;
        
        Pricebook_Line__c testPriceLine1 = new Pricebook_Line__c( pricebook__c = testPriceBook.id, product__c = testProduct.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today(),End_Date__c = Date.today()+10);
        insert testPriceLine1;
        
        Pricebook_Line__c testPriceLine2 = new Pricebook_Line__c( pricebook__c = testPriceBook.id, product__c = testProduct.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today()+15, End_Date__c = Date.today()+20);
        insert testPriceLine2;
        
        Pricebook_Line__c testPriceLine3 = new Pricebook_Line__c( pricebook__c = testPriceBook.id, product__c = testProduct.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today()+25, End_Date__c = Date.today()+30);
        insert testPriceLine3;  
        
        try{
            
            Pricebook_Line__c testPriceLine4 = new Pricebook_Line__c( pricebook__c = testPriceBook.id, product__c = testProduct.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today()+9, End_Date__c = Date.today()+14);
            insert testPriceLine4;  
            system.assert(false);
        }
        catch( Exception e ){
            
            system.assert( e.getMessage().contains( PriceBookService.DATE_OVERLAP_PRICE_TYPE ) == true, e.getMessage() );
        }
        
        try{
            
            Pricebook_Line__c testPriceLine5 = new Pricebook_Line__c( pricebook__c = testPriceBook.id, product__c = testProduct.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today()+45, End_Date__c = Date.today()+44);
            insert testPriceLine5;  
            system.assert(false);
        }
        catch( Exception e ){
            
            system.assert( e.getMessage().contains( PriceBookService.END_LESSER_THAN_START ) == true );
        }
        
        try{
            
            Pricebook_Line__c testPriceLine6 = new Pricebook_Line__c( pricebook__c = testPriceBook.id, product__c = testProduct.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today()+49, End_Date__c = null );
            insert testPriceLine6;  
            system.assert(false);
        }
        catch( Exception e ){
            
            system.assert( e.getMessage().contains( PriceBookService.START_END_BLANK ) == true );
        }       
        
        try{
            testPriceLine3.Start_Date__c = date.today()+1;
            update testPriceLine3;
                
            system.assert(false);
        } catch ( Exception e ) {
            system.assert( e.getMessage().contains( PriceBookService.DATE_OVERLAP_PRICE_TYPE ) == true );
        }
    }

    // JIRA - 2635 Pricebook with Product Groups
    public static testMethod void testPricebookLinesWithGroups(){
        TestData data = new TestData();
        // Create a few Product Group and 
        Product_Group__c pGroup1 = new Product_Group__c(Name = 'Prod Grp 1', Company__c= data.company.Id);
        Product_Group__c pGroup2 = new Product_Group__c(Name = 'Prod Grp 2', Company__c= data.company.Id);

        insert new Product_Group__c[]{pGroup1, pGroup2};

        Test.startTest();

        //
        // Case #1 Test a line creation with both Product and group on it. This should fail because of a custom validation rule.
        //
        try {       
            Pricebook_Line__c pbLineWithBothProductNGroup = new Pricebook_Line__c( pricebook__c = data.pricebook.id, product__c = data.product.id, 
                                            Product_Group__c = pGroup1.Id, Price__c = 5.000000, 
                                           Start_date__c = Date.today(), End_Date__c = Date.today()+10);
            insert pbLineWithBothProductNGroup;
            System.assert(false, 'Both product and product group cannot be present on same pricebook line');
        } catch(DmlException dmle) {            
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, dmle.getDmlType(0), 'Should fail for custom validation exception');
        }       


        // 
        // Case 2: Test with product groups for various pricebook lines
        //  

        Pricebook_Line__c testPriceLine1 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today(), End_Date__c = Date.today()+10);
        
        
        Pricebook_Line__c testPriceLine2 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today()+15, End_Date__c = Date.today()+20);
        
        
        Pricebook_Line__c testPriceLine3 = new Pricebook_Line__c( Pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today()+25, End_Date__c = Date.today()+30);
        
        insert new Pricebook_Line__c[] {testPriceLine1, testPriceLine2, testPriceLine3};

        try {           
            Pricebook_Line__c testPriceLine4 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today()+9, End_Date__c = Date.today()+14);
            insert testPriceLine4;  
            system.assert(false);
        } catch ( Exception e ) {
            system.assert( e.getMessage().contains( PriceBookService.DATE_OVERLAP_PRICE_TYPE ) == true, e.getMessage() );
        }
        
        try{
            
            Pricebook_Line__c testPriceLine5 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today()+45, End_Date__c = Date.today()+44);
            insert testPriceLine5;  
            system.assert(false);
        }
        catch( Exception e ){
            
            system.assert( e.getMessage().contains( PriceBookService.END_LESSER_THAN_START ) == true );
        }
        
        try{
            
            Pricebook_Line__c testPriceLine6 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                           Start_date__c = Date.today()+49, End_Date__c = null );
            insert testPriceLine6;  
            system.assert(false);
        }
        catch( Exception e ){
            
            system.assert( e.getMessage().contains( PriceBookService.START_END_BLANK ) == true );
        }       
        
        try{
            testPriceLine3.Start_Date__c = date.today()+1;
            update testPriceLine3;
                
            system.assert(false);
        }
        catch( Exception e ){
            
            system.assert( e.getMessage().contains( PriceBookService.DATE_OVERLAP_PRICE_TYPE ) == true );
        }       

        Test.stopTest();
                                        
    }

    
    testmethod static void testPriceBookLineFindsPricebookByUnique() {
        TestFuel data = new TestFuel();
        // given there is a pricebook with Pricebook_Unique__c =='NATBOOK';
        // insert a pricebook line that will 'find' that pricebook and link to it
        Pricebook__c p = data.pricebook;
        system.assertEquals( p.Primary_Key__c , 'NATBOOK', ' epxected unique to be set');
        
        Pricebook__c p2 = [ select id,Primary_Key__c from Pricebook__c where 
                                        Primary_Key__c in ('NATBOOK') ];
        system.assertEquals( p2.Primary_Key__c , 'NATBOOK', ' epxected unique to be set');
        
        // test that we can insert a pricebook line and it finds it's correct product !
        // and it's pricebook
        Product__c prod = data.product;
        Pricebook_Line__c pl =new Pricebook_Line__c();
        //pl.product__c = data.product3.id;
        pl.Product_Identifier__c =prod.Primary_Key__c;
        pl.price__c = 11.12;
        pl.Pricebook_Identifier__c = 'NATBOOK';
        pl.Start_date__c = system.today(); 
        insert pl;  // NOTE pricebook__c is NOT set in this insert
        
        pl = [ select pricebook__c , product__c from Pricebook_Line__c where id = :pl.id limit 1];
        system.assertEquals(pl.pricebook__c, p.id, ' epxected the pricebook to be set');
        system.assertEquals(pl.product__c, prod.id, ' epxected the product to be set');
        
        // test that a new price book is created with a company specified
        Company__c c = data.company;
        Pricebook__c p3 = new Pricebook__c(); 
        p3.name = data.company.Name +  ' Orange Pricebook2';
        p3.company_Identifier__c = c.Company_Identifier__c;
        p3.Primary_Key__c = 'NATBOOK2';
        insert p3; 
        p3 = [ select id, company__c from pricebook__c where id = :p3.id limit 1];
        system.assertEquals( c.id, p3.company__c, ' epxected pricebook company to be set by text field company_identifier__c ');
               
    }
        
   
        
        
    public static testMethod void testRoundingDefault(){
        TestFuel fuel = new TestFuel();
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = .999999;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50;
        brack2.percentUpcharge = 1.999999;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 100;
        brack3.percentUpcharge = 2.999999;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 150;
        brack4.percentUpcharge = 3.999999;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 200;
        brack5.percentUpcharge = 4.999999;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
                
        
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.name = fuel.company.Name +  ' Orange Pricebook';
        pricebook.company__c = fuel.company.id; 
        pricebook.Primary_Key__c = 'NATBOOK';
        insert pricebook; 
        
        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 9.999999;
        pl.Use_Fixed_Pricing__c = false;
        pl.Start_date__c = system.today().addDays(1); 
        pl.End_date__c = pl.Start_date__c.addDays(3);
        
        insert pl;
        
        Pricebook_Line__c plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(10.00, plReloaded.Price__c);
        System.assertEquals(10.20, plReloaded.Price_2__c);
        System.assertEquals(10.30, plReloaded.Price_3__c);
        System.assertEquals(10.40, plReloaded.Price_4__c);
        System.assertEquals(10.50, plReloaded.Price_5__c);
        
        
        // change the price__c field to see if everything is recalculated
        plReloaded.Price__c = 19.999999;
        update plReloaded;
        
        plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(20.00, plReloaded.Price__c);
        System.assertEquals(20.40, plReloaded.Price_2__c);
        System.assertEquals(20.60, plReloaded.Price_3__c);
        System.assertEquals(20.80, plReloaded.Price_4__c);
        System.assertEquals(21.00, plReloaded.Price_5__c);
        
        // This should clear all other price fields
        plReloaded.Use_Fixed_Pricing__c = true;
        update plReloaded;
        
        plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(null, plReloaded.Price_2__c);
        System.assertEquals(null, plReloaded.Price_3__c);
        System.assertEquals(null, plReloaded.Price_4__c);
        System.assertEquals(null, plReloaded.Price_5__c);
    }

    
    public static testMethod void testRoundingSixDigits(){
        TestFuel fuel = new TestFuel();
       
        //insert custom setting value to give us 6 decimal precision on PBLs
        insert new Configuration__c(Name='pricebooklinePrecision', Value__c='6');
       
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = .999999;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50;
        brack2.percentUpcharge = 1.999999;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 100;
        brack3.percentUpcharge = 2.999999;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 150;
        brack4.percentUpcharge = 3.999999;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 200;
        brack5.percentUpcharge = 4.999999;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
                
        
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.name = fuel.company.Name +  ' Orange Pricebook';
        pricebook.company__c = fuel.company.id; 
        pricebook.Primary_Key__c = 'NATBOOK';
        insert pricebook; 
        
        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 9.999999;
        pl.Use_Fixed_Pricing__c = false;
        pl.Start_date__c = system.today().addDays(1); 
        pl.End_date__c = pl.Start_date__c.addDays(3);
        
        insert pl;
        
        Pricebook_Line__c plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(9.999999, plReloaded.Price__c);
        System.assertEquals(10.199999, plReloaded.Price_2__c);
        System.assertEquals(10.299999, plReloaded.Price_3__c);
        System.assertEquals(10.399999, plReloaded.Price_4__c);
        System.assertEquals(10.499999, plReloaded.Price_5__c);
        
        
        // change the price__c field to see if everything is recalculated
        plReloaded.Price__c = 19.999999;
        update plReloaded;
        
        plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(19.999999, plReloaded.Price__c);
        System.assertEquals(20.399999, plReloaded.Price_2__c);
        System.assertEquals(20.599999, plReloaded.Price_3__c);
        System.assertEquals(20.799999, plReloaded.Price_4__c);
        System.assertEquals(20.999999, plReloaded.Price_5__c);
        
        // This should clear all other price fields
        plReloaded.Use_Fixed_Pricing__c = true;
        update plReloaded;
        
        plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        System.assertEquals(null, plReloaded.Price_2__c);
        System.assertEquals(null, plReloaded.Price_3__c);
        System.assertEquals(null, plReloaded.Price_4__c);
        System.assertEquals(null, plReloaded.Price_5__c);
    }    
    
    

    /* 
        Test case to reproduce KNDY-3296.
        This test case checks Pricebook Line's Use_Fixed_Pricing__c field to clear 
        Bracket pricing field i.e. Price_2__c - Price_N__c field.
    */        
        
        
        
   
}