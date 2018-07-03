/**
 * This class contains unit tests for 
 */
@isTest
private class GenerateMRPTest {

     @isTest static void t1() {
        TestData data = new TestData();
        insert new MRP__c( company__c = data.company.id );
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = null;
        insert mrpRun;
        MRP__c mrp = new MRP__c();
        mrp.Company__c = data.company.id;
        mrp.Facility__c = null;
        mrp.MRP_Run__c = mrpRun.ID;
        insert mrp;
        
        Test.startTest();
        GenerateMRPEraseTemp obj = new GenerateMRPEraseTemp(mrpRun.ID);
        Id jobid = Database.executeBatch( obj );
        Test.stopTest();
        system.assertEquals(0,[select Id from MRP__c where MRP_Run__c = : mrpRun.id].size() );
    } 
    
    
    


    static testMethod void MRPPlannedPurchaseExtension_test() {
        TestData data = new TestData();
        Test.startTest();
 		System.assertEquals(0, Limits.getQueries(), 'Limits.getQueries()  : '+ Limits.getQueries()); 
        Item__c itm = data.itemList[0];
        itm.Supplier__c = data.supplier.id;
        itm.Source__c = 'Purchased';
        itm.Buyer_Planner__c = UserInfo.getUserId();
        itm.Purchasing_UOM__c = data.uomList[0].Id;
        itm.Stocking_UOM__c = data.uomList[0].Id;
        update itm;
        List<MRP__c> mrpList = new List<MRP__c>(); 
        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(), 
            Item__c = data.itemList[0].id, Start_Date__c = system.today(),  Planned__c = true,
            Modified_Quantity__c = 12.0 );
        insert tmp;

        mrpList.add( tmp );
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(mrpList);
        con.setSelected(mrpList);
        MRPPlannedPurchaseExtension ext =new MRPPlannedPurchaseExtension(con);
    
        system.assert( ! ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // clean thru all checks
        PageReference p0 = ext.generate(); 
        system.assert( p0 != null , ' expected not null ');
        Test.stopTest();
    }
    
    static testMethod void MRPPlannedPurchaseExtension_testErrorNoPurchasingUOM() {
        TestData data = new TestData();
        Test.startTest();
        System.assertEquals(0, Limits.getQueries(), 'Limits.getQueries()  : '+ Limits.getQueries()); 
        Item__c itm = data.itemList[0];
        itm.Supplier__c = data.supplier.id;
        itm.Source__c = 'Purchased';
        itm.Buyer_Planner__c = UserInfo.getUserId();
        itm.Purchasing_UOM__c = null;
        update itm;
        
        List<MRP__c> mrpList = new List<MRP__c>(); 
        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(), 
            Item__c = data.itemList[0].id, Start_Date__c = system.today(),  Planned__c = true,
            Modified_Quantity__c = 12.0 );
        insert tmp;
        
        mrpList.add( tmp );
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(mrpList);
        con.setSelected(mrpList);
        MRPPlannedPurchaseExtension ext =new MRPPlannedPurchaseExtension(con);
    
        system.assert( ApexPages.hasMessages());
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Item_has_no_Purchasing_UOM));
        Test.stopTest();
    }
    // TODO more tests for the error conditions
    
    static testMethod void testMatlTrackingPlannedPurchase(){
        TestData data = new TestData();
        Material_Tracking__c mtlTracking = new Material_Tracking__c ();
        mtlTracking.Item__c = data.itemList[2].Id;
        mtlTracking.Work_Order__c = data.workOrder.Id;
        mtlTracking.Allocation_Required__c = true;
        mtlTracking.Allocate_on_Receipt__c = true;
        insert mtlTracking;
        Test.startTest();
        List<MRP__c> mrpList = new List<MRP__c>(); 
        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(), 
            Item__c = data.itemList[2].id, Start_Date__c = system.today(),  Is_Demand__c = true,
            Modified_Quantity__c = 12.0, Material_Tracking__c=mtlTracking.Id );
        
        MRP__c tmp1 = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(), 
            Item__c = data.itemList[2].id, Start_Date__c = system.today(),  Planned__c = true,
            Modified_Quantity__c = 12.0 );
        mrpList.add(tmp);
        mrpList.add(tmp1);
        insert mrpList;
        
        mrpList[1].Next_Level_MRP__c = mrpList[0].Id;
        update mrpList;
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController( new List<MRP__c>{mrpList[1]});
        con.setSelected(mrpList);
        MRPPlannedPurchaseExtension ext =new MRPPlannedPurchaseExtension(con);
        PageReference p0 = ext.generate(); 
        system.assert( p0 != null , ' expected not null ');
        
        SOQLUtil util = new SOQLUtil('Purchase_Order_Line__c');
        util.addFields(new Set<String>{'Id','Name'});
        Id mtlTrackingid = mtlTracking.id;
        util.setWhereClause ('Material_Tracking__c = : mtlTrackingid' );
        List<Purchase_Order_Line__c> polines = Database.query(util.getQuery() );
        system.assert(polines != null && polines.size() > 0 );
        
        Test.stopTest();
    }
    
}