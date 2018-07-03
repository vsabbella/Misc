@isTest
private class TestExtensions {
    
    static TestData data = new TestData(); 

    // TODO add test methods here ...
    public static testMethod void FacilityViewExt_test() {
        FacilityViewExt con = new FacilityViewExt( new Apexpages.Standardcontroller( data.facility ) );
        FacilityViewExt.Node s = FacilityViewExt.getHierarchy( data.facility.id );
        system.assert( s != null );
        
    }  
    public class foo extends PageExtension {    }
    public static testMethod void test_pageExtension() {  
            foo bar = new foo();  
        system.assert( bar != null ); 
    }
    
    
    /** 
     * tests for WLIQ Extension.cls
     */
    public static testMethod void test_wliq() {
        Apexpages.StandardController sc = new Apexpages.StandardController( new Item__c() );
        WLIQExtension ext = new WLIQExtension( sc );
        
        Lot__c lot = new Lot__c();
        lot.Name = '1234';
        lot.Lot_Hold__c = true;
        lot.Item__c = data.itemList[0].Id;
        insert lot;
        
        Lot__c lot1 = new Lot__c();
        lot1.Name = '12345';
        lot1.Lot_Hold__c = false;
        lot1.Item__c = data.itemList[0].Id;
        insert lot1;
        
        SKID__c objSKID = new SKID__c();
        objSKID.Location__c = data.location3.id;  
        objSKID.Quantity__c = 5;
        objSKID.quantity_Stocking_UOM__c = 5;
        objSKID.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID.Item__c = data.itemList[0].Id;
        objSKID.Type__c = 'Location';
        objSKID.Lot__c = lot1.id;
        objSKID.Company__c = data.company.Id;
        objSKID.Facility2__c = data.facility2.Id;
        insert objSKID;
        
        SKID__c objSKID1 = new SKID__c();
        objSKID1.Location__c = data.location3.id;  
        objSKID1.Quantity__c = 7;
        objSKID1.quantity_Stocking_UOM__c = 7;
        objSKID1.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID1.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID1.Item__c = data.itemList[0].Id;
        objSKID1.Type__c = 'Location';
        objSKID1.Lot__c = lot.id;
        objSKID1.Company__c = data.company.Id;
        objSKID1.Facility2__c = data.facility2.Id;
        insert objSKID1;

        SKID__c objSKID2 = new SKID__c();
        objSKID2.Location__c = data.location2.id;  
        objSKID2.Quantity__c = 2;
        objSKID2.quantity_Stocking_UOM__c = 2;
        objSKID2.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID2.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID2.Item__c = data.itemList[0].Id;
        objSKID2.Type__c = 'Allocated';
        objSKID2.Company__c = data.company.Id;
        objSKID2.Facility2__c = data.facility2.Id;
        insert objSKID2;
        
        SKID__c objSKID3 = new SKID__c();
        objSKID3.Location__c = data.location2.id;  
        objSKID3.Quantity__c = 9;
        objSKID3.quantity_Stocking_UOM__c = 9;
        objSKID3.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID3.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID3.Item__c = data.itemList[0].Id;
        objSKID3.Type__c = 'In-Transit';
        objSKID3.Company__c = data.company.Id;
        objSKID3.Facility2__c = data.facility2.Id;
        insert objSKID3;
        
        SKID__c objSKID4 = new SKID__c();//WIP
        objSKID4.Location__c = data.location2.id;  
        objSKID4.Quantity__c = 12;
        objSKID4.quantity_Stocking_UOM__c = 12;
        objSKID4.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID4.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID4.Item__c = data.itemList[0].Id;
        objSKID4.Type__c = 'WIP';
        objSKID4.Company__c = data.company.Id;
        objSKID4.Facility2__c = data.facility2.Id;
        insert objSKID4;
        
        SKID__c objSKID5 = new SKID__c();//WIP
        objSKID5.Location__c = null;  
        objSKID5.Quantity__c = 20;
        objSKID5.quantity_Stocking_UOM__c = 20;
        objSKID5.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID5.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
        objSKID5.Item__c = data.itemList[0].Id;
        objSKID5.Type__c = 'Allocated';//soft
        objSKID5.Company__c = data.company.Id;
        objSKID5.Facility2__c = data.facility2.Id;
        insert objSKID5;

        sc = new Apexpages.StandardController( data.itemList[0] );
        
        ext = new WLIQExtension( sc );
        
        GridRelatedListController con = new GridRelatedListController();
        con.config = ext.invgridConfig;
        string result = ext.getinvGridConfigJson();
        
        system.assert(ext.skidFieldsJson!=null);
        system.assert(ext.skiddetailFieldsJson!=null);
        
        JSONResult locresult = new JSONResult();
        JSONResult skidbyFacilityresult = new JSONResult();
        JSONResult skidbyLocresult = new JSONResult();
        locresult = WLIQExtension.getLocandFacilityIds(data.itemList[0].Id);
        system.assert(locresult.records.size()>0,locresult);
        system.assert(locresult.additionalInfo !=null,locresult);
        
        String facilityIds;
        List<Id> locationIDs = new List<Id>();
        
        List<Object> recs= locresult.records;
        locationIDs =(List<Id>) recs;
       	facilityIds = (String)locresult.additionalInfo;
        
        JsonResult jsonresult = new JsonResult();
        jsonresult = WLIQExtension.getSkidsbyFacility(new List<ID>{data.facility2.Id},(String)data.itemList[0].Id);
        system.assert(jsonresult.records.size()==1,jsonresult);
        List<SKID__c> skidlist = (List<SKID__c>)jsonresult.records;
        Boolean NonNettableQty,AllocatedQty,NettableQty,InTransitQty,WIPQty;
        for(SKID__c skid:skidlist){
        	if(skid.Quantity_Used__c ==5){
        		NettableQty = true;
        	}
        	if(skid.Quantity_Available__c == 7){
        		NonNettableQty = true;
        	}
        	if(skid.Quantity_Allocated__c ==22){//2 Allocated and 20 Soft Allocated
        		AllocatedQty = true;
        	}
        	if(skid.Input_Quantity__c == 12){
        		WIPQty = true;
        	}
        	if(skid.Quantity_to_Issue__c ==9){
        		InTransitQty = true;
        	}
        	
        }
        
        system.assert(NettableQty==true);
        system.assert(AllocatedQty==true);
        system.assert(NonNettableQty==true);
        system.assert(WIPQty==true && InTransitQty==true);
        
		skidbyLocresult = WLIQExtension.getSkidsbyLoc(locationIDs,data.facility2.Id,(String)data.itemList[0].Id);
        system.assert(skidbyLocresult.records.size()==2,skidbyLocresult);
        
        
    }

    static testMethod void MRPPlannedMakeExtension_test() {
        Item__c itm = data.itemList[0];
        itm.Source__c = 'Not Purchased';
        update itm;

        List<MRP__c> mrpList = new List<MRP__c>();
        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Facility__c = data.facility2.Id, Required_Date__c = system.today(),
            Item__c = data.itemList[0].id, Start_Date__c = system.today(),  Planned__c = true,
            Modified_Quantity__c = 12.0 );
        insert tmp;

        mrpList.add( tmp );
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(mrpList);
        con.setSelected(mrpList);
        MRPPlannedMakeExtension ext =new MRPPlannedMakeExtension(con);
        system.assert( ! ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // clean thru all checks

        pageReference p0 = ext.generate();
        system.assert( p0 != null );

        //Plan Item has no effective Item Specification as of Plan Release Dat
        tmp.Start_Date__c = system.today().addDays(23);
        update tmp;
        con.setSelected( new List<MRP__c>{tmp});
        ext =new MRPPlannedMakeExtension(con);
        // TODO system.assert( ApexPages.hasMessages() );

      
        tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(),
            Item__c = data.itemList[0].id, Start_Date__c = system.today() , Planned__c = false);
        insert tmp;
        con.setSelected( new List<MRP__c>{tmp});
        ext =new MRPPlannedMakeExtension(con);
        system.assert( ApexPages.hasMessages() ); // bad type

        con.setSelected( new List<MRP__c>() );
        ext =new MRPPlannedMakeExtension(con);
        system.assert( ApexPages.hasMessages() ); // no plans selected
            
        tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(),
            Item__c = data.itemList[1].id, Start_Date__c = system.today() , Planned__c = true);
        insert tmp;
        con.setSelected( new List<MRP__c>{tmp});
        ext =new MRPPlannedMakeExtension(con);
        system.assert( ApexPages.hasMessages() );  // Items with Source Purchased cannot be Selected.

        tmp = new MRP__c( Company__c = data.Company.id , Facility__c = data.facility2.Id, Required_Date__c = system.today(),
                Item__c = data.itemList[0].id, Start_Date__c = system.today(),  Planned__c = true,
                Modified_Quantity__c = 12.0 );
        insert tmp;

        data.assembly.Active__c = false;
        update data.assembly;

        con.setSelected( new List<MRP__c>{tmp});
        ext =new MRPPlannedMakeExtension(con);
        system.assert( ApexPages.hasMessages() ); // can't create planned record with inactive item spec

        data.assembly.Active__c = true;
        data.assembly.Default_Work_Order_Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        update data.assembly;

        Test.startTest();
        tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today(),
                Item__c = data.itemList[0].id, Start_Date__c = system.today() , Planned__c = true,
                Modified_Quantity__c = -12.0);
        insert tmp;

        con.setSelected( new List<MRP__c>{tmp});
        ext =new MRPPlannedMakeExtension(con);
        system.assert( ApexPages.hasMessages() );

    }

    static testMethod void MRPPlannedMakeExtension_testSFailInactiveItemSpec() {
        Item__c itm = data.itemList[0];
        itm.Source__c = 'Not Purchased';
        update itm;

        List<MRP__c> mrpList = new List<MRP__c>();

        //data.assembly.Active__c = true;
        //data.assembly.Default_Work_Order_Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        //update data.assembly;

        Test.startTest();
        Test.setCurrentPageReference(Page.MRPPlannedMake);
        itm = data.itemList[0];
        itm.Source__c = 'Manufactured';
        update itm;

        delete [SELECT id from MRP__c];

        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today().addDays(1),
                Item__c = data.itemList[0].id, Start_Date__c = system.today().addDays(1), Planned__c = true,
                Modified_Quantity__c = 12.0);
        insert tmp;
		system.assert( !ApexPages.hasMessages(), ApexPages.getMessages() );
        mrpList = new List<MRP__c>{tmp};
        ApexPages.StandardSetController con1 = new ApexPages.StandardSetController(mrpList);
        con1.setSelected( mrpList);
        MRPPlannedMakeExtension ext =new MRPPlannedMakeExtension(con1);
        system.assert( !ApexPages.hasMessages(), ApexPages.getMessages() );

        Test.stopTest();

    }

    static testMethod void MRPPlannedMakeExtension_testSuccess1() {
        Item__c itm = data.itemList[0];
        itm.Source__c = 'Not Purchased';
        update itm;

        List<MRP__c> mrpList = new List<MRP__c>();

        data.assembly.Active__c = false;
        update data.assembly;

        data.assembly.Active__c = true;
        data.assembly.Default_Work_Order_Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        update data.assembly;

        Test.startTest();
        Test.setCurrentPageReference(Page.MRPPlannedMake);
        itm = data.itemList[0];
        itm.Source__c = 'Manufactured';
        update itm;

        delete [SELECT id from MRP__c];

        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today().addDays(1),
                Item__c = data.itemList[0].id, Start_Date__c = system.today().addDays(1), Planned__c = true,
                Modified_Quantity__c = 12.0);
        insert tmp;
		system.assert( !ApexPages.hasMessages(), ApexPages.getMessages() );
        mrpList = new List<MRP__c>{tmp};
        ApexPages.StandardSetController con1 = new ApexPages.StandardSetController(mrpList);
        con1.setSelected( mrpList);
        MRPPlannedMakeExtension ext =new MRPPlannedMakeExtension(con1);
        system.assert( !ApexPages.hasMessages(), ApexPages.getMessages() );

        Test.stopTest();

    }

    static testMethod void MRPPlannedMakeExtension_testSuccess() {
        Test.startTest();
        Item__c itm = data.itemList[0];
        itm.Source__c = 'Manufactured';
        update itm;

        MRP__c tmp = new MRP__c( Company__c = data.Company.id , Required_Date__c = system.today().addDays(1),
                Item__c = data.itemList[0].id, Start_Date__c = system.today().addDays(1), Planned__c = true,
                Modified_Quantity__c = 12.0);
        insert tmp;

        List<MRP__c> mrpList = new List<MRP__c>{tmp};
        ApexPages.StandardSetController con1 = new ApexPages.StandardSetController(mrpList);
        system.assert( !ApexPages.hasMessages(), ApexPages.getMessages() );
        con1.setSelected( mrpList);
        MRPPlannedMakeExtension ext = new MRPPlannedMakeExtension(con1);
        system.assert( !ApexPages.hasMessages(), ApexPages.getMessages() );
        Test.stopTest();

    }
 
 
    /** 
     *     InventoryChangeExt
     */
    public static testMethod void test_inventorychangeext() { 
        
        Inventory_Change__c ch = new Inventory_Change__c(); 
        ch.company__c = data.company.id;
        ch.item__c = data.itemList[0].id;
        ch.type__c = 'Inventory Change';
        ch.count_Quantity__c = 12.0;
        insert ch;
        
        system.assert( ch.id != null , ' expected inventory change');

        Inventory_Transaction__c it = new Inventory_Transaction__c(
            Type__c = 'Adjustment Increase'
        );
		it.Inventory_Change__c = ch.Id;
		it.Item__c = data.itemList[0].Id;
		it.quantity__c = 12;
		it.quantity_Stocking_UOM__c =12;
        it.Packaging_UOM__c = data.itemList[0].Stocking_UOM__c;
        it.Stocking_UOM__c = data.itemList[0].Stocking_UOM__c;
		it.Company__c = data.company.id;
		insert it;
		
		ch.finalized__c = true;
		update ch;
		Test.startTest();        
        ApexPages.StandardSetcontroller con  = new ApexPages.StandardSetcontroller(
                                                    new List<Inventory_change__c>{ch});
                                                    
        InventoryChangeExt ext =new InventoryChangeExt(con      );  
        con.setSelected( new List<Inventory_Change__c>{ch} );
        ext.lines();
        system.assert( ext.finalized.size() > 0  );
        system.assertEquals( null , ext.gsave() );
        
        con  = new ApexPages.StandardSetcontroller( new List<Inventory_change__c>());
        ext =new InventoryChangeExt( con );
        ext.lines();
        system.assert( ext.selecterror == true, ' expected an error');  
        Test.stopTest();
    }
        
    /** 
     * KSE tests
     */
    /* TODO this test is failing ??
    public static testMethod void test_updateTime() {
        Account a = new Account(Name='foo');
        insert a;
        List<sobject> aa = [select id,name, SystemModstamp from Account where id =:a.id ];
        List<sobject> ab = [select id,name, SystemModstamp from Account where id =:a.id ];
        
        // update aa
        aa[0].put('Name','bar');
        update aa;
        aa = [select id,name, SystemModstamp from Account where id =:a.id ];
        System.assert( aa[0].get('SystemModstamp') != ab[0].get('SystemModstamp'));
        
        // now update ab and expect an exception
        ab[0].put('Name', 'gack');
        Boolean sawexcept = false; 
        try {
                KSE.upsertWithTimeCheck(ab);
        } catch ( exception e) { sawexcept =  true; }
        System.assert( sawexcept == true, ' expected to catch an update Exception');
    }*/

    public static testMethod void test_clone() {
        Account a = new Account(Name='foo');
        insert a;
        System.assert( KSE.isFieldEmpty('Name', a) == false );
        System.assert( KSE.isFieldEmpty('Industry', a) == true );
        
        Map<id, Sobject> t1 = new Map<Id,sobject>([select id,name from Account where id=:a.id ]);
        System.assert( KSE.isFieldChanging('Name', a, t1) == false );
        
        Account b = a.clone();
        b.Name = 'bar';
        t1.put( a.id, b);
        System.assert( KSE.isFieldChanging('Name', a, t1) == true );  
    } 
    
    public static testMethod void test_KSE () { 
            System.assert( KSE.isEmpty( null ) ,' expected empty');
        System.assert( ! KSE.isEmpty( 'foo' ) ,' expected not empty');
        
        // interestingly, even in API 25 we can query the bussiness hours from the db, it's special
        
        Date d = KSE.calculateStartDate(System.Today(), 0, [select Id from BusinessHours where isDefault = true limit 1].Id);
        Date d2 = KSE.calculateStartDate(System.Today(), 1, [select Id from BusinessHours where isDefault = true limit 1].Id);
        System.assert( d.day() != d2.day() );
    
        system.assert(  KSE.getItemJSONRecord(data.itemList[0].Name,data.company.Id, null, system.today()).Name == data.itemList[0].Name );   
    	system.assert(  KSE.getItemJSON(data.itemList[0].Name).Name == data.itemList[0].Name );   
    
        system.assert( KSE.Namespace != null , ' expected empty or valid namespace ');
    
        Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
        system.assert( CustomerRecordTypes.keySet().size() > 0 ,' epxected record types');
    }
    
    public static testMethod void testdatatest() {
        System.debug( LoggingLevel.INFO, 'TestData uses queries : '+ Limits.getQueries() );  
        
        //73 to support putting all open periods in a map to access and derive the GL Date Time / Period on AEs - SK - 03/27/2014
        //75 for Product Group additions by Roger
        //77 TODO: Discrepancy between deployed org and null org test, need to resolve
        //78 TODO: lower asap
        system.assert(  Limits.getQueries() <= 78, ' expected TestData to use 78  queries or less. Actual: '+Limits.getQueries()); 
       
        system.assert( data.purchaseOrder != null );
        system.assert( data.purchaseOrder.company__c == data.company.id );
        
        system.assert( data.customerBillTo.Parent_customer__c != null, ' expected parent to be set');
        system.assert( data.customerSoldTo.Parent_customer__c != null, ' expected parent to be set');
        system.assert( data.customerShipTo.Parent_customer__c != null, ' expected parent to be set');
        
        system.assertEquals( null , data.customerParent.Parent_Customer__c );
        system.assertEquals( data.customerBillTo.Parent_Customer__c, data.customerParent.id );
        system.assertEquals( data.customerSoldTo.Parent_Customer__c, data.customerBillTo.id );
        system.assertEquals( data.customerShipTo.Parent_Customer__c, data.customerSoldTo.id );
        
        // check tops, these are set by a trigger, need to refetch the record
        data.customerParent = [ select id, top_parent_Customer__c from Customer__c where id = :data.customerParent.id limit 1];
        system.assertEquals( null, data.customerParent.Top_Parent_Customer__c );
        data.customerBillTo = [ select id, top_parent_Customer__c from Customer__c where id = :data.customerBillTo.id limit 1];
        system.assertNotEquals( null, data.customerBillTo.Top_Parent_Customer__c ); 
        
        data.customerSoldTo = [ select id, top_parent_Customer__c from Customer__c where id = :data.customerSoldTo.id limit 1];
        system.assertNotEquals( null, data.customerSoldTo.Top_Parent_Customer__c ); 
        
        data.customerShipTo = [ select id, top_parent_Customer__c from Customer__c where id = :data.customerShipTo.id limit 1];
        system.assertNotEquals( null, data.customerShipTo.Top_Parent_Customer__c ); 
 
        // verify that the getTranscationTypeToObjectMap contains all types we list here
        Map<string,string> trMap = AccountingRuleService.getTranscationTypeToObjectMap();
        for ( Accounting_Rule__c ar : [ select id , Transaction__c, Object_name__c from Accounting_rule__c ]) {
            if(ar.Object_name__c != 'Purchase_Order__c')
            System.assert( trMap.containsKey( ar.Object_Name__c+'--'+ar.Transaction__c ) ,
                 'Missing Transaction from getTranscationTypeToObjectMap '+ ar.Transaction__c+'  Key:'+ar.Object_Name__c+'--'+ar.Transaction__c+' trMap:'+trMap.keySet());
        }
    }

/*
    public static testMethod void RecentOrderController_test() { 
        
        for ( integer i = 1; i < 4 ; i++ ) {
            insert new Shopping_Cart__c();
        }
        
        RecentOrderController roc = new RecentOrderController();
        System.assertEquals( roc.userid , UserInfo.getUserId());
        
        List<Shopping_Cart__c> tmp = roc.getrecentShoppingCarts();
        System.assertEquals( 0, tmp.size() ); // all carts are in shopping status
        
        for ( Shopping_Cart__c s: [select id, status__c from Shopping_Cart__c]) {
            EntitySubscription follow = new entitysubscription();
            follow.parentid = s.id;
            follow.SubscriberId = userinfo.getuserid();
            insert follow;
        }
        tmp = roc.getrecentShoppingCarts();
        System.assertEquals( 3, tmp.size() );
    }
 */


        static testMethod void test_chunkIdRange() {
        List<Map<String, String>> idChunkList = KSE.chunkIdRange('a2aj0000000WqC0', 'a2aj0000000WqS0', 400);

        system.debug(idChunkList);
        system.assertEquals(3, idChunkList.size());
        
        system.assertEquals('a2aj0000000WqC0', idChunkList[0].get('first'));
        system.assertEquals('a2aj0000000WqIR', idChunkList[0].get('last'));     
        
        system.assertEquals('a2aj0000000WqIS', idChunkList[1].get('first'));
        system.assertEquals('a2aj0000000WqOt', idChunkList[1].get('last'));             
        
        system.assertEquals('a2aj0000000WqOu', idChunkList[2].get('first'));        
        system.assertEquals('a2aj0000000WqS0', idChunkList[2].get('last'));
    }
    
    
    
    static testMethod void test_base62decode() {
                
                
        //TEST DECODES          
        System.assertEquals(0, KSE.base62decode('0'));
        System.assertEquals(1, KSE.base62decode('1'));
        System.assertEquals(2, KSE.base62decode('2'));
        System.assertEquals(3, KSE.base62decode('3'));
        System.assertEquals(4, KSE.base62decode('4'));
        System.assertEquals(5, KSE.base62decode('5'));
        System.assertEquals(6, KSE.base62decode('6'));
        System.assertEquals(7, KSE.base62decode('7'));
        System.assertEquals(8, KSE.base62decode('8'));
        System.assertEquals(9, KSE.base62decode('9'));
        System.assertEquals(10, KSE.base62decode('A'));
        System.assertEquals(11, KSE.base62decode('B'));
        System.assertEquals(12, KSE.base62decode('C'));
        System.assertEquals(13, KSE.base62decode('D'));
        System.assertEquals(14, KSE.base62decode('E'));
        System.assertEquals(15, KSE.base62decode('F'));
        System.assertEquals(16, KSE.base62decode('G'));
        System.assertEquals(17, KSE.base62decode('H'));
        System.assertEquals(18, KSE.base62decode('I'));
        System.assertEquals(19, KSE.base62decode('J'));
        System.assertEquals(20, KSE.base62decode('K'));
        System.assertEquals(21, KSE.base62decode('L'));
        System.assertEquals(22, KSE.base62decode('M'));
        System.assertEquals(23, KSE.base62decode('N'));
        System.assertEquals(24, KSE.base62decode('O'));
        System.assertEquals(25, KSE.base62decode('P'));
        System.assertEquals(26, KSE.base62decode('Q'));
        System.assertEquals(27, KSE.base62decode('R'));
        System.assertEquals(28, KSE.base62decode('S'));
        System.assertEquals(29, KSE.base62decode('T'));
        System.assertEquals(30, KSE.base62decode('U'));
        System.assertEquals(31, KSE.base62decode('V'));
        System.assertEquals(32, KSE.base62decode('W'));
        System.assertEquals(33, KSE.base62decode('X'));
        System.assertEquals(34, KSE.base62decode('Y'));
        System.assertEquals(35, KSE.base62decode('Z'));
        System.assertEquals(36, KSE.base62decode('a'));
        System.assertEquals(37, KSE.base62decode('b'));
        System.assertEquals(38, KSE.base62decode('c'));
        System.assertEquals(39, KSE.base62decode('d'));
        System.assertEquals(40, KSE.base62decode('e'));
        System.assertEquals(41, KSE.base62decode('f'));
        System.assertEquals(42, KSE.base62decode('g'));
        System.assertEquals(43, KSE.base62decode('h'));
        System.assertEquals(44, KSE.base62decode('i'));
        System.assertEquals(45, KSE.base62decode('j'));
        System.assertEquals(46, KSE.base62decode('k'));
        System.assertEquals(47, KSE.base62decode('l'));
        System.assertEquals(48, KSE.base62decode('m'));
        System.assertEquals(49, KSE.base62decode('n'));
        System.assertEquals(50, KSE.base62decode('o'));
        System.assertEquals(51, KSE.base62decode('p'));
        System.assertEquals(52, KSE.base62decode('q'));
        System.assertEquals(53, KSE.base62decode('r'));
        System.assertEquals(54, KSE.base62decode('s'));
        System.assertEquals(55, KSE.base62decode('t'));
        System.assertEquals(56, KSE.base62decode('u'));
        System.assertEquals(57, KSE.base62decode('v'));
        System.assertEquals(58, KSE.base62decode('w'));
        System.assertEquals(59, KSE.base62decode('x'));
        System.assertEquals(60, KSE.base62decode('y'));
        System.assertEquals(61, KSE.base62decode('z'));
        
        
        System.assertEquals(62, KSE.base62decode('10'));
        System.assertEquals(63, KSE.base62decode('11'));
        System.assertEquals(64, KSE.base62decode('12'));
        System.assertEquals(65, KSE.base62decode('13'));
        System.assertEquals(66, KSE.base62decode('14'));
        System.assertEquals(67, KSE.base62decode('15'));
        System.assertEquals(68, KSE.base62decode('16'));
        System.assertEquals(69, KSE.base62decode('17'));
        System.assertEquals(70, KSE.base62decode('18'));
        System.assertEquals(71, KSE.base62decode('19'));
        System.assertEquals(72, KSE.base62decode('1A'));
        System.assertEquals(73, KSE.base62decode('1B'));
        System.assertEquals(74, KSE.base62decode('1C'));
        System.assertEquals(75, KSE.base62decode('1D'));
        System.assertEquals(76, KSE.base62decode('1E'));
        System.assertEquals(77, KSE.base62decode('1F'));
        System.assertEquals(78, KSE.base62decode('1G'));
        System.assertEquals(79, KSE.base62decode('1H'));
        System.assertEquals(80, KSE.base62decode('1I'));
        System.assertEquals(81, KSE.base62decode('1J'));
        System.assertEquals(82, KSE.base62decode('1K'));
        System.assertEquals(83, KSE.base62decode('1L'));
        System.assertEquals(84, KSE.base62decode('1M'));
        System.assertEquals(85, KSE.base62decode('1N'));
        System.assertEquals(86, KSE.base62decode('1O'));
        System.assertEquals(87, KSE.base62decode('1P'));
        System.assertEquals(88, KSE.base62decode('1Q'));
        System.assertEquals(89, KSE.base62decode('1R'));
        System.assertEquals(90, KSE.base62decode('1S'));
        System.assertEquals(91, KSE.base62decode('1T'));
        System.assertEquals(92, KSE.base62decode('1U'));
        System.assertEquals(93, KSE.base62decode('1V'));
        System.assertEquals(94, KSE.base62decode('1W'));
        System.assertEquals(95, KSE.base62decode('1X'));
        System.assertEquals(96, KSE.base62decode('1Y'));
        System.assertEquals(97, KSE.base62decode('1Z'));
        System.assertEquals(98, KSE.base62decode('1a'));
        System.assertEquals(99, KSE.base62decode('1b'));
        System.assertEquals(100, KSE.base62decode('1c'));
        System.assertEquals(101, KSE.base62decode('1d'));
        System.assertEquals(102, KSE.base62decode('1e'));
        System.assertEquals(103, KSE.base62decode('1f'));
        System.assertEquals(104, KSE.base62decode('1g'));
        System.assertEquals(105, KSE.base62decode('1h'));
        System.assertEquals(106, KSE.base62decode('1i'));
        System.assertEquals(107, KSE.base62decode('1j'));
        System.assertEquals(108, KSE.base62decode('1k'));
        System.assertEquals(109, KSE.base62decode('1l'));
        System.assertEquals(110, KSE.base62decode('1m'));
        System.assertEquals(111, KSE.base62decode('1n'));
        System.assertEquals(112, KSE.base62decode('1o'));
        System.assertEquals(113, KSE.base62decode('1p'));
        System.assertEquals(114, KSE.base62decode('1q'));
        System.assertEquals(115, KSE.base62decode('1r'));
        System.assertEquals(116, KSE.base62decode('1s'));
        System.assertEquals(117, KSE.base62decode('1t'));
        System.assertEquals(118, KSE.base62decode('1u'));
        System.assertEquals(119, KSE.base62decode('1v'));
        System.assertEquals(120, KSE.base62decode('1w'));
        System.assertEquals(121, KSE.base62decode('1x'));
        System.assertEquals(122, KSE.base62decode('1y'));
        System.assertEquals(123, KSE.base62decode('1z'));
        
        
        //56,800,235,583
        System.assertEquals(Long.valueOf('56800235583'), KSE.base62decode('zzzzzz'));
        
        //3,521,614,606,207
        System.assertEquals(Long.valueOf('3521614606207'), KSE.base62decode('zzzzzzz'));
        
        //TEST ENCODES  
        System.assertEquals('0', KSE.base62encode(0));
        System.assertEquals('1', KSE.base62encode(1));
        System.assertEquals('2', KSE.base62encode(2));
        System.assertEquals('3', KSE.base62encode(3));
        System.assertEquals('4', KSE.base62encode(4));
        System.assertEquals('5', KSE.base62encode(5));
        System.assertEquals('6', KSE.base62encode(6));
        System.assertEquals('7', KSE.base62encode(7));
        System.assertEquals('8', KSE.base62encode(8));
        System.assertEquals('9', KSE.base62encode(9));
        System.assertEquals('A', KSE.base62encode(10));
        System.assertEquals('B', KSE.base62encode(11));
        System.assertEquals('C', KSE.base62encode(12));
        System.assertEquals('D', KSE.base62encode(13));
        System.assertEquals('E', KSE.base62encode(14));
        System.assertEquals('F', KSE.base62encode(15));
        System.assertEquals('G', KSE.base62encode(16));
        System.assertEquals('H', KSE.base62encode(17));
        System.assertEquals('I', KSE.base62encode(18));
        System.assertEquals('J', KSE.base62encode(19));
        System.assertEquals('K', KSE.base62encode(20));
        System.assertEquals('L', KSE.base62encode(21));
        System.assertEquals('M', KSE.base62encode(22));
        System.assertEquals('N', KSE.base62encode(23));
        System.assertEquals('O', KSE.base62encode(24));
        System.assertEquals('P', KSE.base62encode(25));
        System.assertEquals('Q', KSE.base62encode(26));
        System.assertEquals('R', KSE.base62encode(27));
        System.assertEquals('S', KSE.base62encode(28));
        System.assertEquals('T', KSE.base62encode(29));
        System.assertEquals('U', KSE.base62encode(30));
        System.assertEquals('V', KSE.base62encode(31));
        System.assertEquals('W', KSE.base62encode(32));
        System.assertEquals('X', KSE.base62encode(33));
        System.assertEquals('Y', KSE.base62encode(34));
        System.assertEquals('Z', KSE.base62encode(35));
        System.assertEquals('a', KSE.base62encode(36));
        System.assertEquals('b', KSE.base62encode(37));
        System.assertEquals('c', KSE.base62encode(38));
        System.assertEquals('d', KSE.base62encode(39));
        System.assertEquals('e', KSE.base62encode(40));
        System.assertEquals('f', KSE.base62encode(41));
        System.assertEquals('g', KSE.base62encode(42));
        System.assertEquals('h', KSE.base62encode(43));
        System.assertEquals('i', KSE.base62encode(44));
        System.assertEquals('j', KSE.base62encode(45));
        System.assertEquals('k', KSE.base62encode(46));
        System.assertEquals('l', KSE.base62encode(47));
        System.assertEquals('m', KSE.base62encode(48));
        System.assertEquals('n', KSE.base62encode(49));
        System.assertEquals('o', KSE.base62encode(50));
        System.assertEquals('p', KSE.base62encode(51));
        System.assertEquals('q', KSE.base62encode(52));
        System.assertEquals('r', KSE.base62encode(53));
        System.assertEquals('s', KSE.base62encode(54));
        System.assertEquals('t', KSE.base62encode(55));
        System.assertEquals('u', KSE.base62encode(56));
        System.assertEquals('v', KSE.base62encode(57));
        System.assertEquals('w', KSE.base62encode(58));
        System.assertEquals('x', KSE.base62encode(59));
        System.assertEquals('y', KSE.base62encode(60));
        System.assertEquals('z', KSE.base62encode(61));
        
        
        System.assertEquals('10', KSE.base62encode(62));
        System.assertEquals('11', KSE.base62encode(63));
        System.assertEquals('12', KSE.base62encode(64));
        System.assertEquals('13', KSE.base62encode(65));
        System.assertEquals('14', KSE.base62encode(66));
        System.assertEquals('15', KSE.base62encode(67));
        System.assertEquals('16', KSE.base62encode(68));
        System.assertEquals('17', KSE.base62encode(69));
        System.assertEquals('18', KSE.base62encode(70));
        System.assertEquals('19', KSE.base62encode(71));
        System.assertEquals('1A', KSE.base62encode(72));
        System.assertEquals('1B', KSE.base62encode(73));
        System.assertEquals('1C', KSE.base62encode(74));
        System.assertEquals('1D', KSE.base62encode(75));
        System.assertEquals('1E', KSE.base62encode(76));
        System.assertEquals('1F', KSE.base62encode(77));
        System.assertEquals('1G', KSE.base62encode(78));
        System.assertEquals('1H', KSE.base62encode(79));
        System.assertEquals('1I', KSE.base62encode(80));
        System.assertEquals('1J', KSE.base62encode(81));
        System.assertEquals('1K', KSE.base62encode(82));
        System.assertEquals('1L', KSE.base62encode(83));
        System.assertEquals('1M', KSE.base62encode(84));
        System.assertEquals('1N', KSE.base62encode(85));
        System.assertEquals('1O', KSE.base62encode(86));
        System.assertEquals('1P', KSE.base62encode(87));
        System.assertEquals('1Q', KSE.base62encode(88));
        System.assertEquals('1R', KSE.base62encode(89));
        System.assertEquals('1S', KSE.base62encode(90));
        System.assertEquals('1T', KSE.base62encode(91));
        System.assertEquals('1U', KSE.base62encode(92));
        System.assertEquals('1V', KSE.base62encode(93));
        System.assertEquals('1W', KSE.base62encode(94));
        System.assertEquals('1X', KSE.base62encode(95));
        System.assertEquals('1Y', KSE.base62encode(96));
        System.assertEquals('1Z', KSE.base62encode(97));
        System.assertEquals('1a', KSE.base62encode(98));
        System.assertEquals('1b', KSE.base62encode(99));
        System.assertEquals('1c', KSE.base62encode(100));
        System.assertEquals('1d', KSE.base62encode(101));
        System.assertEquals('1e', KSE.base62encode(102));
        System.assertEquals('1f', KSE.base62encode(103));
        System.assertEquals('1g', KSE.base62encode(104));
        System.assertEquals('1h', KSE.base62encode(105));
        System.assertEquals('1i', KSE.base62encode(106));
        System.assertEquals('1j', KSE.base62encode(107));
        System.assertEquals('1k', KSE.base62encode(108));
        System.assertEquals('1l', KSE.base62encode(109));
        System.assertEquals('1m', KSE.base62encode(110));
        System.assertEquals('1n', KSE.base62encode(111));
        System.assertEquals('1o', KSE.base62encode(112));
        System.assertEquals('1p', KSE.base62encode(113));
        System.assertEquals('1q', KSE.base62encode(114));
        System.assertEquals('1r', KSE.base62encode(115));
        System.assertEquals('1s', KSE.base62encode(116));
        System.assertEquals('1t', KSE.base62encode(117));
        System.assertEquals('1u', KSE.base62encode(118));
        System.assertEquals('1v', KSE.base62encode(119));
        System.assertEquals('1w', KSE.base62encode(120));
        System.assertEquals('1x', KSE.base62encode(121));
        System.assertEquals('1y', KSE.base62encode(122));
        System.assertEquals('1z', KSE.base62encode(123));


        //56,800,235,583
        System.assertEquals('zzzzzz', KSE.base62encode(Long.valueOf('56800235583')));       
        
        //3,521,614,606,207
        System.assertEquals('zzzzzzz', KSE.base62encode(Long.valueOf('3521614606207')));                

    }
    
    
    /*
    * FROM: https://www.interactiveties.com/blog/2011/apex-drop-leading-zeros.php#.VMv5Ml7F9sA
    */
    static testMethod void test_drop_leading_zeros() {
        System.assertEquals('11111',    KSE.drop_leading_zeros('11111'));
        System.assertEquals('11111',    KSE.drop_leading_zeros('00000011111'));
        System.assertEquals(null,       KSE.drop_leading_zeros('abc'));
        System.assertEquals('99999',    KSE.drop_leading_zeros(' 99999 '));
        System.assertEquals('999',      KSE.drop_leading_zeros(' 00999 '));
        System.assertEquals(null,       KSE.drop_leading_zeros('w'));
        System.assertEquals(null,       KSE.drop_leading_zeros('00'));
        System.assertEquals(null,       KSE.drop_leading_zeros('(303) 317-2235'));
        System.assertEquals(null,       KSE.drop_leading_zeros('111 091'));
        System.assertEquals(null,       KSE.drop_leading_zeros('  '));
        System.assertEquals(null,       KSE.drop_leading_zeros(''));
        System.assertEquals(null,       KSE.drop_leading_zeros(null));
    }
    
    
    
    static testMethod void chunkRange_test() {
        List<Map<String, String>> chunkList;
        
        chunkList = KSE.chunkRange(1, 10, 10, 10);
        system.assertEquals(1, chunkList.size(), 'Expected 1 chunk');
        system.assertEquals('0000000001', chunkList[0].get('first'), 'Expected first to be 1');
        system.assertEquals('0000000010', chunkList[0].get('last'), 'Expected last to be 10');      
        
        
        
        
        //-----------
        chunkList = KSE.chunkRange(1, 11, 10, 10);
        system.assertEquals(2, chunkList.size(), 'Expected 2 chunks');
        
        system.assertEquals('0000000001', chunkList[0].get('first'), 'Expected first to be 1');
        system.assertEquals('0000000010', chunkList[0].get('last'), 'Expected last to be 10');      
        
        system.assertEquals('0000000011', chunkList[1].get('first'), 'Expected first to be 11');
        system.assertEquals('0000000011', chunkList[1].get('last'), 'Expected last to be 11');
        
        
        
        
        
        //-----------
        chunkList = KSE.chunkRange(1, 1, 10, 10);
        system.assertEquals(1, chunkList.size(), 'Expected 1 chunk');
        
        system.assertEquals('0000000001', chunkList[0].get('first'), 'Expected first to be 1');
        system.assertEquals('0000000001', chunkList[0].get('last'), 'Expected last to be 1');       
                
        
        
        
        //-----------       
        chunkList = KSE.chunkRange(1, 5, 10, 10);
        system.assertEquals(1, chunkList.size(), 'Expected 1 chunk');
        
        system.assertEquals('0000000001', chunkList[0].get('first'), 'Expected first to be 1');
        system.assertEquals('0000000005', chunkList[0].get('last'), 'Expected last to be 5');       
            
            
        
        
        //-----------       
        chunkList = KSE.chunkRange(100, 200, 10, 10);
        system.debug(JSON.serialize(chunkList));        
        system.assertEquals(11, chunkList.size(), 'Expected 11 chunks');
        
        system.assertEquals('0000000100', chunkList[0].get('first'), 'Expected first to be 100');
        system.assertEquals('0000000109', chunkList[0].get('last'), 'Expected last to be 109');     
        
        system.assertEquals('0000000110', chunkList[1].get('first'), 'Expected first to be 110');
        system.assertEquals('0000000119', chunkList[1].get('last'), 'Expected last to be 119');     
        
        
        system.assertEquals('0000000120', chunkList[2].get('first'), 'Expected first to be 120');
        system.assertEquals('0000000129', chunkList[2].get('last'), 'Expected last to be 129');     
                
        
        system.assertEquals('0000000180', chunkList[8].get('first'), 'Expected first to be 180');
        system.assertEquals('0000000189', chunkList[8].get('last'), 'Expected last to be 189');                             
            
        system.assertEquals('0000000200', chunkList[10].get('first'), 'Expected first to be 200');
        system.assertEquals('0000000200', chunkList[10].get('last'), 'Expected last to be 200');                    
            
            
            
        //-----------       
        chunkList = KSE.chunkRange(1, 1, 10, 10000);
        system.debug(JSON.serialize(chunkList));        
        system.assertEquals(1, chunkList.size(), 'Expected 1 chunks');
        
        system.assertEquals('0000000001', chunkList[0].get('first'), 'Expected first to be 1');
        system.assertEquals('0000000001', chunkList[0].get('last'), 'Expected last to be 1');                                   
            
            
            
            
        //-----------       
        chunkList = KSE.chunkRange(1, 100, 10, 1);
        system.debug(JSON.serialize(chunkList));        
        system.assertEquals(100, chunkList.size(), 'Expected 100 chunks');
        
        system.assertEquals('0000000001', chunkList[0].get('first'), 'Expected first to be 1');
        system.assertEquals('0000000001', chunkList[0].get('last'), 'Expected last to be 1');       
        
        system.assertEquals('0000000100', chunkList[99].get('first'), 'Expected first to be 100');
        system.assertEquals('0000000100', chunkList[99].get('last'), 'Expected last to be 100');                                        
            
    }

    
    static testMethod void prefixIntWithZeros_test() {

        system.assertEquals('0000000001', KSE.prefixIntWithZeros(1, 10), 'Expected to see correct zero padding behavior');
        system.assertEquals('000000100', KSE.prefixIntWithZeros(100, 9), 'Expected to see correct zero padding behavior');
    }



 
 
   public static testmethod void ReceivingDocumentLinesAddManageExt_test() {
            
        data.receivingdocument.Status__c = 'Closed';
        update data.receivingdocument;
        ReceivingDocumentLinesAddManageExt con1 = new ReceivingDocumentLinesAddManageExt( new Apexpages.Standardcontroller( data.receivingdocument));
        system.assert(con1.selecterror == true, ' Status Closed error');
        
        data.receiptinvoiceline.Packaging_UOM__c = data.uomList[8].id;
        update data.receiptinvoiceline;
        data.receiptinvoiceline1.Packaging_UOM__c = data.uomList[8].id;
        update data.receiptinvoiceline1;
        
        data.receivingdocument.Status__c = 'Open';
        update data.receivingdocument;
        ReceivingDocumentLinesAddManageExt con = new ReceivingDocumentLinesAddManageExt( new Apexpages.Standardcontroller( data.receivingdocument ));
        system.assert(con.selecterror == false, ' Status Open error');
        
        con.addNewRow();
        
        con.objectList[2].Purchase_Order__c = con.objectList[1].Purchase_Order__c;
        con.objectList[2].Purchase_Order_Line__c = con.objectList[1].Purchase_Order_Line__c;
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        system.assert(con.cloneporline()==null, ' cloneporline error');
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        con.remove();
        
        system.assert(con.save()!=null, ' expected record id');
    
    }
}