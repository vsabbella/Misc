@isTest
public with sharing class ItemTest {
    
    public static testMethod void test_Insert_Item_trigger() {
        TestFuel data = new TestFuel();
        system.assert( data.company !=null,'co');
        system.assert( data.clsObj !=null,'class');
        // get a class, then insert an item to see it joined to the class
        Class__c cl = [select Class_Unique__c from Class__c 
                       where id = :data.clsObj.id limit 1];
        
        system.assert( cl.class_unique__c != null ,'expected uniq');
        Item__c itm = new Item__c();
        itm.Class_Identifier__c = cl.Class_Unique__c;
        itm.Company__c = data.company.id;
        insert itm;
        itm = [ select class__c, company__c from Item__c where id = :itm.id limit 1];
        system.assert( itm.Class__c != null ,'expected class to be set');
    }
    
    public static testMethod void test_ItemSpec_Insert_trigger() 
    {
        TestFuel data = new TestFuel();
        
        system.assert( data.itemList.size() > 0, 'expected items');
        string  itmNam = data.company.Name + ' Item-10' ; 
        system.assert( data.itemList[0].Name == itmNam );
        
        // test two lookups are populated, company and item
        Item_Specification__c assembly = new Item_Specification__c();
        assembly.Start_Date2__c = System.now().addDays(-39);
        assembly.Revision__c = 'A';
        assembly.Production__c = true;
        assembly.Costing__c = true;
        
        assembly.Item_Name__c  = itmNam;
        assembly.Company_Identifier__c = data.Company.Company_Identifier__c;
        assembly.Facility_Identifier__c = data.facility.Primary_Key__c;
        insert assembly;
        assembly = [select Item__c, Company__c , Facility__c
                    from Item_Specification__c 
                    where id = :assembly.id limit 1];
        
        system.assert( assembly.Item__c != null, ' epxected item lookup to be filled in' );
        system.assert( assembly.Company__c != null, ' epxected Company__c lookup to be filled in' );
        system.assert( assembly.Facility__c != null, ' epxected Facility__c lookup to be filled in' );
        
    }

    public static testMethod void test_ItemSpec_Update_trigger() 
    {
        TestFuel data = new TestFuel();
        
        Work_Order__c wo = data.workorder;
        
        Item_Specification__c assembly = data.itemSpec;       
       
      
        assembly.Production__c = false;
        assembly.Costing__c = false;
        assembly.Start_Date2__c = System.now().addDays(-5);
        boolean saw_exception = false;
        try{
            update assembly;
        }
        catch(Dmlexception dmle){
            if (dmle.getMessage().contains(Label.Cannot_edit_Item_Specification)){
                 saw_exception = true;
            }
            
        }
       system.assert(saw_exception == true);
                                          
    }
    
    public static testMethod void test_ClosedWO_ItemSpec_Update_trigger() 
    {
        TestFuel data = new TestFuel();
        
        Work_Order__c wo = data.workorder;
        wo.Status__c = 'Closed';
        update wo;
        
        Item_Specification__c assembly = data.itemSpec;       
       
      
        assembly.Production__c = false;
        assembly.Costing__c = false;
        assembly.Start_Date2__c = System.now().addDays(-5);
        boolean saw_exception = false;
        try{
            update assembly;
        }
        catch(Dmlexception dmle){
            if (dmle.getMessage().contains(Label.Cannot_edit_Item_Specification)){
                 saw_exception = true;
            }
            
        }
       system.assert(saw_exception == false);//KNDY-8432
                                          
    }
    
    public static testMethod void test_CancelledWO_ItemSpec_Update_trigger() 
    {
        TestFuel data = new TestFuel();
        
        Work_Order__c wo = data.workorder;
        wo.Status__c = 'Cancelled';
        update wo;
        
        Item_Specification__c assembly = data.itemSpec;       
       
      
        assembly.Production__c = false;
        assembly.Costing__c = false;
        assembly.Start_Date2__c = System.now().addDays(-5);
        boolean saw_exception = false;
        try{
            update assembly;
        }
        catch(Dmlexception dmle){
            if (dmle.getMessage().contains(Label.Cannot_edit_Item_Specification)){
                 saw_exception = true;
            }
            
        }
       system.assert(saw_exception == false);//KNDY-8432
                                          
    }
    
    public static testMethod void test_ItemSpec_Update_trigger_positive() 
    {
        TestFuel data = new TestFuel();        
                
        Item_Specification__c assembly = data.itemSpec;      
       
      
        assembly.Production__c = false;
        assembly.Costing__c = false;
        assembly.Start_Date2__c = System.now().addDays(-5);
        boolean saw_exception = false;
        try{
            update assembly;
        }
        catch(Dmlexception dmle){
            if (dmle.getMessage().contains(Label.Cannot_edit_Item_Specification)){
                 saw_exception = true;
            }
            
        }
       system.assert(saw_exception == false);
                                          
    }
    
    
    public static testMethod void test_CompanyCost() {
        TestFuel data = new TestFuel();
        
        List<Item_Cost__c> itemCosts = new List<Item_Cost__c>();
        Item__c item1 = data.itemList[0];
        Item__c item2 = data.itemList[1];
        Item__c item3 = data.itemList[2];

        
        //Test For Single Company Cost
        Double companyActiveCost = ItemService.getActiveStandardCost(item1.Id,data.company.Id,null,system.today());
        System.AssertEquals(0,companyActiveCost); //as there are no company level costs for item1
        
        //Test For Single Facility Cost
        Double facilityActiveCost = ItemService.getActiveStandardCost(item1.Id,data.company.Id,data.facility.Id,system.today());
        System.AssertEquals(29.70,facilityActiveCost);
    
        //Test For Multiple Facility Item/Cost
        Double retrievedFacilityActiveCost = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now()).get(item1.Id);
        System.AssertEquals(29.7,retrievedFacilityActiveCost);
        
        //Test For Multiple Company Item/Cost
        Double retrievedCompanyActiveCost = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,null,system.now()).get(item2.Id);
        System.AssertEquals(2.00,retrievedCompanyActiveCost);
        
        //Test For Multiple Company Item/Cost
        Double retrievedFacilityActiveCost2 = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now()).get(item2.Id);
        System.AssertEquals(2.00,retrievedFacilityActiveCost2);
    }
    
    public static testMethod void testCostsByStartDate(){
        
        TestFuel data = new TestFuel();
        
        Test.startTest();
        
        List<Item_Cost__c> costList = data.costList;
        List<Item_Cost__c> costListForUpdate = new List<Item_Cost__c>();
        List<Item_Cost__c> costListForInsert = new List<Item_Cost__c>();
        
        Item__c item1 = data.itemList[0];
        Item__c item2 = data.itemList[1];
        Item__c item3 = data.itemList[2];
        
        for(Item_Cost__c cost : costList ){
            
            if( cost.Status__c == 'Proposed' ){
                cost.start_Date__c = system.now().addDays(-3);
                cost.Status__c = 'Approved';
                cost.date_Approved__c = system.now();
                costListForUpdate.add(cost);
            }
            else{
                Item_Cost__c costClone = cost.clone(false,true);
                costClone.start_Date__c = system.now().addDays(-5);
                costClone.status__c = 'Proposed';
                costListForInsert.add(costClone);
            }
        }
        ItemService.allowItemCostUpdate = true;
        update costListForUpdate;
        insert costListForInsert;
        
        for( Item_Cost__c cost :costListForInsert){
            cost.status__c = 'Approved';
            cost.date_Approved__c = system.now().addDays(-3);
        }
        
        update costListForInsert;
        
        Integer queries = Limits.getQueries();
        
        Double facilityActiveCost = ItemService.getActiveStandardCost(item1.Id,data.company.Id,data.facility.Id,system.today());
        System.AssertEquals(29.70,facilityActiveCost);
        
        //Test For Multiple Company Item/Cost
        Double retrievedCompanyActiveCost = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,null,system.now()).get(item2.Id);
        System.AssertEquals(2.00,retrievedCompanyActiveCost);
        
        //Test For Multiple Facility Item/Cost
        Double retrievedFacilityActiveCost = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now()).get(item1.Id);
        System.AssertEquals(29.7,retrievedFacilityActiveCost);
        
        Double retrievedFacilityActiveCost2 = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now()).get(item2.Id);
        System.AssertEquals(2.00,retrievedFacilityActiveCost2);
        
        //Test For Multiple Facility Item/Cost with older date
        Double retrievedFacilityActiveCost3 = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-2)).get(item1.Id);
        System.AssertEquals(33,retrievedFacilityActiveCost3);
        
        //Test For Multiple Company Item/Cost with older date
        Double retrievedFacilityActiveCost4 = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-2)).get(item2.Id);
        System.AssertEquals(1.25,retrievedFacilityActiveCost4);
        
        //Test For Multiple Facility Item/Cost with older date
        Double retrievedFacilityActiveCost5 = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-4)).get(item1.Id);
        System.AssertEquals(29.7,retrievedFacilityActiveCost5);
        
        //Test For Multiple Company Item/Cost with older date
        Double retrievedFacilityActiveCost6 = ItemService.getActiveStandardCost(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-4)).get(item2.Id);
        System.AssertEquals(2.00,retrievedFacilityActiveCost6);
        
        Integer updatedQueries = Limits.getQueries();
        
        system.assertEquals(updatedQueries-queries, 2, updatedQueries);
        
        Test.stopTest();
    }
    
    public static testMethod void testCostsDecimalByStartDate(){
        
        TestFuel data = new TestFuel();
        
        Test.startTest();
        
        List<Item_Cost__c> costList = data.costList;
        List<Item_Cost__c> costListForUpdate = new List<Item_Cost__c>();
        List<Item_Cost__c> costListForInsert = new List<Item_Cost__c>();
        
        Item__c item1 = data.itemList[0];
        Item__c item2 = data.itemList[1];
        Item__c item3 = data.itemList[2];
        
        for(Item_Cost__c cost : costList ){
            
            if( cost.Status__c == 'Proposed' ){
                cost.start_Date__c = system.now().addDays(-3);
                cost.Status__c = 'Approved';
                cost.date_Approved__c = system.now();
                costListForUpdate.add(cost);
            }
            else{
                Item_Cost__c costClone = cost.clone(false,true);
                costClone.start_Date__c = system.now().addDays(-5);
                costClone.status__c = 'Proposed';
                costListForInsert.add(costClone);
            }
        }
        update costListForUpdate;
        insert costListForInsert;
        
        for( Item_Cost__c cost :costListForInsert){
            cost.status__c = 'Approved';
            cost.date_Approved__c = system.now().addDays(-3);
        }
        
        update costListForInsert;
        
        Integer queries = Limits.getQueries();
        
        Double facilityActiveCost = ItemService.getActiveStandardCostDecimal(new set<Id>{item1.Id}, new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now(), item1.id);
        System.AssertEquals(29.70,facilityActiveCost);
        
        //Test For Multiple Company Item/Cost
        Double retrievedCompanyActiveCost = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,null,system.now(), item2.Id);
        System.AssertEquals(2.00,retrievedCompanyActiveCost);
    
        //Test For Multiple Facility Item/Cost
        Double retrievedFacilityActiveCost = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now(), item1.Id);
        System.AssertEquals(29.7,retrievedFacilityActiveCost);
        
        Double retrievedFacilityActiveCost2 = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now(), item2.Id);
        System.AssertEquals(2.00,retrievedFacilityActiveCost2);
        
        ItemService.itemCostDecMap = null;//as decimalmap methods should be used with the same date/time in the transactions's context
        
        //Test For Multiple Facility Item/Cost with older date
        Double retrievedFacilityActiveCost3 = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-2), item1.Id);
        System.AssertEquals(33,retrievedFacilityActiveCost3);
        
        //Test For Multiple Company Item/Cost with older date
        Double retrievedFacilityActiveCost4 = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-2), item2.Id);
        System.AssertEquals(1.25,retrievedFacilityActiveCost4);
        
        ItemService.itemCostDecMap = null;
        
        //Test For Multiple Facility Item/Cost with older date
        Double retrievedFacilityActiveCost5 = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-4), item1.Id);
        System.AssertEquals(29.7,retrievedFacilityActiveCost5);
        
        //Test For Multiple Company Item/Cost with older date
        Double retrievedFacilityActiveCost6 = ItemService.getActiveStandardCostDecimal(new Set<Id>{item1.Id,item2.Id,item3.Id},new set<Id>{data.facility.id},data.company.Id,data.facility.Id,system.now().addDays(-4), item2.Id);
        System.AssertEquals(2.00,retrievedFacilityActiveCost6);
        
        Integer updatedQueries = Limits.getQueries();
        
        system.assertEquals(updatedQueries-queries, 4, updatedQueries);
        
        Test.stopTest();
    }
    
 public static testMethod void test_Company_SameItemNameAndCost() {
        //PTM # 102 --This test is covering the scenario where two different companies adding Item cost for Item with same name and cost.
        TestFuel data = new TestFuel(); 
        
        Company__c Testcompany = new Company__c();
        
        Testcompany.name = '100';
        Testcompany.A_Days__c = 6;
        Testcompany.B_Days__c = 20;
        Testcompany.C_Days__c = 90;
        Testcompany.Company_Identifier__c = 'TESTKEN';  
        Testcompany.Comp_Currency__c = TestFuel.currencySGD.id;
        Testcompany.Consol_Currency__c = TestFuel.currencyEUR.id;
        Testcompany.Stat_Currency__c = TestFuel.currencyGBP.id;
        Testcompany.Subs_Currency__c = TestFuel.currencyUSD.id;
        Testcompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert Testcompany;
        
        Item__c ItemObj1=new Item__c();
        ItemObj1.name= 'KNDY Item 22';
        ItemObj1.Description__c='It is a Test item';
        ItemObj1.Source__c= 'Purchased';
        ItemObj1.Company__c = data.company.id;
        
        insert ItemObj1;
        
        Item__c ItemObj2=new Item__c();
        ItemObj2.name= 'KNDY Item 22';
        ItemObj2.Description__c='It is a Test item';
        ItemObj2.Source__c= 'Purchased';
        ItemObj2.Company__c = Testcompany.id;
        
        insert ItemObj2;
        
        Item_Cost__c cost1 = new Item_Cost__c();
        cost1.Name = ItemObj1.Name;
        cost1.Item__c = ItemObj1.Id;
        cost1.Material_Cost__c = 1000;
        cost1.Status__c = 'Proposed';
        cost1.Start_Date__c = DateTime.now();
        cost1.Company__c = data.company.Id;
        insert cost1;
        
        cost1.Status__c = 'Approved';
        cost1.Date_Activated__c = system.today();
        update cost1;
        
        
        Item_Cost__c cost2 = new Item_Cost__c();
        cost2.Name = ItemObj2.Name;
        cost2.Item__c = ItemObj2.Id;
        cost2.Material_Cost__c = 1000;
        cost2.Status__c = 'Proposed';
        cost2.Start_Date__c = DateTime.now();
        cost2.Company__c = Testcompany.id;
        insert cost2; 
        
        cost2.Status__c = 'Approved';
        cost2.Date_Activated__c = system.today();
        update cost2;
        
        //Test For Different Company having Item with same Item name and cost.
                
        List<Item_Cost__c>  itemcostrecs = [Select Id, Name, Item__c,Standard_Cost__c from Item_Cost__c where id = :cost1.id or id = :cost2.id];
        
        system.assert(itemcostrecs.size() == 2, itemcostrecs);
        system.assert(itemcostrecs[0].Standard_Cost__c == itemcostrecs[1].Standard_Cost__c, itemcostrecs);
        system.assert(itemcostrecs[0].Standard_Cost__c == 1000, itemcostrecs[0].Standard_Cost__c);
        system.assert(itemcostrecs[0].Name == itemcostrecs[1].Name);
        
    }
    
    public static testMethod void test_ItemCostChangeStatus(){
        //PTM-580,PTM-582 - Test the edit and delete item cost records and the also the status changes. 
        
        TestFuel data = new TestFuel(); 
        
         Test.startTest(); 
        
        Company__c Testcompany = new Company__c();
        
        Testcompany.name = 'KNDY Test Company';
        Testcompany.A_Days__c = 6;
        Testcompany.B_Days__c = 20;
        Testcompany.C_Days__c = 90;
        Testcompany.Company_Identifier__c = 'TESTKEN';  
        Testcompany.Comp_Currency__c = TestFuel.currencySGD.id;
        Testcompany.Consol_Currency__c = TestFuel.currencyEUR.id;
        Testcompany.Stat_Currency__c = TestFuel.currencyGBP.id;
        Testcompany.Subs_Currency__c = TestFuel.currencyUSD.id;
        Testcompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert Testcompany; 
        
        Item__c ItemObj1 = new Item__c();
        ItemObj1.name= 'KNDY Item 12';
        ItemObj1.Description__c='It is a Test item - 1';
        ItemObj1.Source__c= 'Purchased';
        ItemObj1.Company__c = data.company.id;
        insert ItemObj1;
        
        Item__c ItemObj2 = new Item__c();
        ItemObj2.name= 'KNDY Item 12';
        ItemObj2.Description__c='It is a Test item - 2';
        ItemObj2.Source__c= 'Purchased';
        ItemObj2.Company__c = Testcompany.id;
        insert ItemObj2;
        
        Item_Cost__c cost1 = new Item_Cost__c();
        cost1.Name = ItemObj1.Name;
        cost1.Item__c = ItemObj1.Id;
        cost1.Material_Cost__c = 1000;
        cost1.Status__c = 'Planning - 1';
        cost1.start_date__c = DateTime.now() - 10;
        cost1.Company__c = data.company.Id;
        insert cost1;
        
        Item_Cost__c cost2 = new Item_Cost__c();
        cost2.Name = ItemObj2.Name;
        cost2.Item__c = ItemObj2.Id;
        cost2.Material_Cost__c = 1200;
        cost2.Status__c = 'Planning - 1';
        cost2.start_date__c = DateTime.now() - 8;
        cost2.Company__c = Testcompany.id;
        insert cost2;
        
        try{
            cost1.Status__c = 'Approved';
            cost1.start_date__c = DateTime.now();
            update cost1;
            system.assert(false);
        }catch(DMLException e){
            system.assert(e.getMessage().contains(Label.Can_only_update_Item_cost_records_from_proposed_to_Approved_status));
        }
        
    /*   try{
            cost1.Status__c = 'History-'+system.today();
            update cost1;
            system.assert(false);
        }catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Cannot_edit_item_cost_in_active_status).toLowerCase()));
        } */
        
        try{
            cost1.Status__c = 'Proposed';
            update cost1;
            system.assert(true);
            
            cost1.Status__c = 'Approved';
            cost1.Date_Activated__c = system.today();
            update cost1;
            system.assert(true);
            
        }catch(DMLException e){ // happy path should not have any exceptions
            system.assert(false);
        }
        
        try{
            delete cost1;
            system.assert(false);
        }catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Cannot_delete_item_cost_in_active_status).toLowerCase()));
        }
        
        try{
            cost2.Status__c = 'Proposed';
            update cost2;
            system.assert(true);
            
            cost2.Status__c = 'Approved';
            cost2.Date_Activated__c = system.today();
            update cost2;
            system.assert(true);
            
       /*   cost1.Status__c = 'History-'+System.today();
            update cost1;
            system.assert(true); */
            
        }catch(DMLException e){ //no exceptions
            system.assert(false);
        }
        
        try{
            delete cost1;
            system.assert(false);
        }catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Cannot_delete_item_cost_in_active_status).toLowerCase()));
        }
        
        try{
            cost1.Status__c = 'Planning - 1';
            update cost1;
            system.assert(false);
        }catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Cannot_edit_item_cost_in_active_status).toLowerCase()));
        } 
        
        Item_Cost__c cost3 = new Item_Cost__c();
        cost3.Name = ItemObj1.Name;
        cost3.Item__c = ItemObj1.Id;
        cost3.Material_Cost__c = 1200;
        cost3.Status__c = 'Approved';
        cost3.Company__c = data.company.Id;
        
        try{
            insert cost3;
            system.assert(false);
        }catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Cannot_insert_item_cost_in_active_status).toLowerCase()));
        }  
        
        Test.stopTest();
        
    }
      
    public static testMethod void test_ItemAttributeChangeWithInventory() 
    {
        TestFuel data = new TestFuel();
        system.assertEquals(data.itemList[0].Item_Attribute__c, data.itemAttrObj.id ); //item has item attribute
        
        List<SKID__c> skids = data.skids; // creating inventory for all items
        
        Test.startTest();
        
        data.itemList[0].Item_Attribute__c = null;
        try{
            update data.itemList[0];
            system.assert(false);
        }
        catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Item_Attributes_Cannot_be_changed).toLowerCase()));
        }
        
        data.itemAttrObj.Expiration_Date__c = false;
        
        try{
            update data.itemAttrObj;
            system.assert(false);
        }
        catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Item_Attributes_Cannot_be_changed).toLowerCase()));
        }
        
        try{
            delete data.itemAttrObj;
            system.assert(false);
        }
        catch(DMLException e){
            system.assert(e.getMessage().toLowerCase().contains((Label.Item_Attributes_Cannot_be_changed).toLowerCase()));
        }
        
        Test.stopTest();
        
        
    }
    
    public static testMethod void test_ItemAttributeChangeWithoutInventory() 
    {
        TestFuel data = new TestFuel();
        system.assertEquals(data.itemList[0].Item_Attribute__c, data.itemAttrObj.id ); //item has item attribute
        //no inventory has ben created
        Test.startTest();
        
        data.itemList[0].Item_Attribute__c = null;
        try{
            update data.itemList[0];
            system.assert(true);
        }
        catch(DMLException e){
            system.assert(false);//expecting no exceptions
        }
        
        system.assertEquals(data.itemAttrObj.Expiration_Date__c , true );
        
        data.itemAttrObj.Expiration_Date__c = false;
        
        try{
            update data.itemAttrObj;
            system.assert(true);
        }
        catch(DMLException e){
            system.assert(false);
        }
        
        Item_Attribute__c itemAttr = [ select id, expiration_Date__c from Item_Attribute__c where Id =: data.itemAttrObj.id];
        system.assertNotEquals( itemAttr, null);
        system.assertEquals( itemAttr.Expiration_Date__c , false );
        
        Test.stopTest();
        
        
    }
    
    public static testMethod void testPopulateItemIdentifier(){
    	TestFuel fuel = new TestFuel();
    	
    	Item__c item = [SELECT Id, Item_Identifier__c FROM Item__c WHERE Id = :fuel.itemList[0].Id];
    	system.assertEquals(String.valueOf(fuel.itemList[0].Id).substring(3, 15), item.Item_Identifier__c, item); //item has item attribute
        
        try{
        	item.Item_Identifier__c = '1234567890098';
        	update item;
        	system.assert(false, 'Update should have failed');
        }catch(Exception ex){
        	system.assert(ex.getMessage().contains('Item Identifier value cannot be modified'));
        }
    }

    private static testmethod void testAddingUom() {
        TestFuel fuel = new TestFuel();
        System.assert(fuel.itemList != null);
        System.assert(fuel.location3 != null);
        System.assert(fuel.location5 != null);

        Item__c item = fuel.itemList[0];

        update new Item__c(Id = item.Id, Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[11].Id }));

        (new TestFuelQuery()).setupInventory();
        
        String oldUoms = item.Packaging_UOM__c;
        update new Item__c(Id = item.Id, Packaging_UOM__c = fuel.itemList[14].Packaging_UOM__c);
        try {
            update new Item__c(Id = item.Id, Packaging_UOM__c = oldUoms);
            System.assert(false);
        } catch (Exception e) { }
    }
}