@isTest
public with sharing class SkidService2Test {
    
    public static testmethod void testSkid(){
        
        TestData data  = new TestData();
        
        Test.startTest();
        
        
        
        Company__c comp = data.company;
        Item__c item = data.itemList[0];
        
        Lot__c lot1 = new Lot__c();
        lot1.Company__c = data.company.id;
        lot1.Item__c = item.Id;
        lot1.Name = '5876';
        insert lot1;
        
        SKID__c skid = new SKID__c();
        skid.location__c = data.location3.id;  // this is STOCK
        skid.Company__c= data.company.id;
        skid.Quantity__c = 200.0;
        skid.Item__c= item.Id;
        skid.Type__c = 'Location';
        skid.Expiration_Date__c = System.today() + 20;
        skid.Lot__c = lot1.id;
        skid.Lot_Number__c = '5876';
        insert skid;
        
        SKID__c recLineSkid1 = new SKID__c();
        recLineSkid1.location__c = data.location3.id;  
        recLineSkid1.Company__c= data.company.id;
        recLineSkid1.Lot__c = lot1.id;
        recLineSkid1.Lot_Number__c = '5876';
        recLineSkid1.Expiration_Date__c = System.today() + 20;
        recLineSkid1.Quantity__c = 10.0;
        recLineSkid1.Item__c= item.Id;
        
        SKID__c recLineSkid2 = new SKID__c();
        recLineSkid2.location__c = data.location3.id;  
        recLineSkid2.Company__c= data.company.id;
        recLineSkid2.Expiration_Date__c = System.today() + 20;
        recLineSkid2.Quantity__c = 10.0;
        recLineSkid2.Item__c= item.Id;
        
        map< Id, Id > uniqueLocations = new map< Id, Id >();
        
        List<SKID__c> skidList = new List<SKID__c>();
        skidList.add( recLineSkid1 );
        uniqueLocations.put( recLineSkid1.Location__c , recLineSkid1.Location__c );
        skidList.add( recLineSkid2 );
        uniqueLocations.put( recLineSkid2.Location__c , recLineSkid2.Location__c );
        
        List< String > attr = new List< String >();
        attr.add( 'Lot__c');
        attr.add('Expiration_Date__c');
        
        List< Id > uniqueLocationIds = new List<Id>( uniqueLocations.keySet() );
        
        SkidService2.putAwayService(skidList, attr, uniqueLocations.keySet(), 'Location', false );
        
        SKID__c sk = [ select id, Quantity__c, Lot_Number__c from SKID__c where id =:skid.id  ];
        system.assert( sk.Quantity__c == 210.0, sk.Quantity__c );
        
        List<SKID__c> skList = [ select id,Quantity__c, Lot_Number__c from SKID__c where Expiration_Date__c = :System.today() + 20 ];
        system.assert( skList.size() == 2 , skList );
        
        for( SKID__c skids : skList ){
            
            if( skids.Lot_Number__c == null ){
                
                system.assert( skids.Quantity__c == 10.0 );
            }
            else
                system.assert( skids.Quantity__c == 210.0, skList );
        }
        
        Test.stopTest();
    }
    
    public static testMethod void testMovementRulesAndSortCriteria(){
        
        ApexPages.Standardcontroller con;
        TestData globalTestData  = new TestData();
        
        SKID__c skid = new SKID__c();
        skid.location__c = globalTestData.location3.id;  // this is STOCK
        skid.Company__c= globalTestData.company.id;
        skid.Quantity__c = 200.0;
        skid.Item__c= globalTestData.ItemList[0].Id;
        skid.Type__c = 'Location';
        skid.Expiration_Date__c = System.today() + 20;
        insert skid;
        
        SKID__c skid1 = new SKID__c();
        skid1.location__c = globalTestData.location3.id;  // this is STOCK
        skid1.Company__c= globalTestData.company.id;
        skid1.Quantity__c = 200.0;
        skid1.Item__c= globalTestData.ItemList[0].Id;
        skid1.Type__c = 'Location';
        skid1.Consigned_Owner__c = globalTestData.supplier.id;
        skid1.Expiration_Date__c = System.today() + 10;
        insert skid1;
        
        Test.startTest();
        
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        System.assertEquals(false, SOPExt.hasErrors);
        
        globalTestData.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :globalTestData.salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            if( sw.sol.Product__r.Item__c == globalTestData.ItemList[0].Id ){
        //        system.assert( sw.skidList.size() == 2, ApexPages.getMessages()); // number of available location skids
                system.assert( SOAExt.matchedRules.get( sw.sol.id ).id ==globalTestData.stockMovementRuleList[2].id, 'Stock Movement Rule matched!' );
                sw.skidList[0].Quantity_Allocated__c  = 15;
                
                //the skids should be sorted in the right order according to pick sort criteria
                system.assert( sw.skidList[0].id == skid.id ); 
        //        system.assert( sw.skidList[1].id == skid1.id ); // consigned owner nulls first sort rule
            }
            else{
                system.assert( sw.sol.Product__r.Item__c == globalTestData.ItemList[5].Id );
                system.assert( sw.skidList.size() == 0); 
                system.assert( SOAExt.matchedRules.get( sw.sol.id ).id ==globalTestData.stockMovementRuleList[3].id, 'Stock Movement Rule matched!' );
            }
        }
        
        Test.stopTest();
    }
    
    public static testMethod void testStockMovementRulesSetup(){
    	
        TestFuel fuel = new TestFuel();
        
        Sales_Order__c salesOrder = fuel.salesOrder;
        
        List<SKID__c> skids = fuel.skids;            
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<Stock_Movement_Rule_Settings__c>  deleteSettingsList = new list<Stock_Movement_Rule_Settings__c>();   
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors);
        
        salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :salesOrder.Id limit 1];
        
        Test.startTest();
        
        for( Stock_Movement_Rule_Settings__c smrs : smrsList ){
        	
        	if( smrs.Stock_Movement_Rule_Field__c == 'Facility__c'){//delete all the settings for facility
        		deleteSettingsList.add( smrs );
        	}
        }
        
        delete deleteSettingsList;
        
        smrsList = [ select Source_Document_Path__c, Stock_Movement_Rule_Field__c from Stock_Movement_Rule_Settings__c where Source_Document__c ='Sales Order' ];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        
        Test.stopTest();
        
        system.assert( ApexPages.hasMessages(ApexPages.Severity.WARNING) == true ); //as facility and company are required custom settings
    }
}