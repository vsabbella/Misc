@isTest
private class MRPPlannedPOAgainstAgreementExtTest {
    private static SchemaUtil queryutil = SchemaUtil.getInstance();
    
    class MRPAgreementReleaseTestData{
        public TestFuel fuel = new TestFuel();
        public MRP__c mrp1 = new MRP__c();
        {   
            mrp1.Company__c = fuel.company.id; mrp1.Required_Date__c = system.today(); 
            mrp1.Item__c = fuel.itemList[1].id; 
            mrp1.Item__r = fuel.itemList[1];
            mrp1.Start_Date__c = system.today();  
            mrp1.Planned__c = true;
            mrp1.Modified_Quantity__c = 12.0; mrp1.Facility__c = fuel.facility.id; 
        }
        
        public MRP__c mrp2 = new MRP__c();
        {   
            mrp2.Company__c = fuel.company.id; mrp2.Required_Date__c = system.today(); 
            mrp2.Item__c = fuel.itemList[2].id; mrp2.Start_Date__c = system.today();  mrp2.Planned__c = true;
            mrp2.Item__r = fuel.itemList[2];
            mrp2.Modified_Quantity__c = 12.0; mrp2.Facility__c = fuel.facility.id; 
        }
        public List<MRP__c> mrpList = new List<MRP__c>();{
            mrpList.add( mrp1 );
            mrpList.add( mrp2 );
        } 
        
        User_Preference__c up = new User_Preference__c();{
            up.Default_Company__c = fuel.company.id;
            up.ownerID = userinfo.getUserID();
            up.Default_Facility__c = fuel.facility.Id;
            insert up;
        }
        
        //Contract
        Contract__c contract = new Contract__c();{
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Supplier__c = fuel.supplier.id;
        contract.Company__c = fuel.company.Id;
        contract.FOB_Term__c = fuel.fobTerm.id;
        contract.Payment_Term__c = fuel.terms.id;
        contract.Ship_to_Facility__c = fuel.facility.Id;
        contract.Transportation_Mode__c = 'RAIL';
        contract.Currency__c = TestFuel.currencyUSD.id;
        insert contract;
        }
        
        //Contract Item that is active
        Contract_Line__c contractLine1 = new Contract_Line__c();{
        contractLine1.Contract__c = contract.Id;
        contractLine1.Company__c = fuel.company.Id;
        contractLine1.Item__c = fuel.itemList[1].id;
        contractLine1.Item__r = fuel.itemList[1];
        contractLine1.Name = 'Test CTL 1';
        contractLine1.Contract_Start__c = Date.today().addDays(-1);
        contractLine1.Contract_End__c = Date.today().addDays(4);
        contractLine1.Status__c = 'Open';
        contractLine1.Negotiated_Price__c = 10;
        contractLine1.Contract_Quantity__c = 100;
        contractLine1.Type__c = 'Tiered';
        contractLine1.Tier_1_Max__c = 10;
        contractLine1.Tier_1_Price__c = 9.00;
        contractLine1.Tier_2_Max__c = 20;
        contractLine1.Tier_2_Price__c = 8.00;
        contractLine1.Tier_3_Max__c = 30;
        contractLine1.Tier_3_Price__c = 7;
        contractLine1.Tier_4_Max__c = 40;
        contractLine1.Tier_4_Price__c = 6;
        contractLine1.Tier_5_Max__c = 50;
        contractLine1.Tier_5_Price__c = 5;
        contractLine1.Tier_6_Max__c = 60;
        contractLine1.Tier_6_Price__c = 4;
        contractLine1.Tier_7_Max__c = 70;
        contractLine1.Tier_7_Price__c = 3;
        contractLine1.Tier_8_Max__c = 80;
        contractLine1.Tier_8_Price__c = 2;
        contractLine1.Tier_9_Max__c = 90;
        contractLine1.Tier_9_Price__c = 1;
        contractLine1.Tier_10_Max__c = 100;
        contractLine1.Tier_10_Price__c = 0.50;
        insert contractLine1;
        }
        List< Contract_Line__c > clList = new List< Contract_Line__c >();
        { 
            clList.add( contractLine1 );
            
        }
    	public Configuration__c rf = new Configuration__c();{
    		rf.name = 'Contract Release Field';
    		rf.Value__c = 'Remaining_Quantity__c';
    		insert rf;
    	}
                 
    }
    static testMethod void exerciseConstructorValidations() {
        
       MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();       
       Test.startTest();
       List<MRP__c> listMRP = new List<MRP__c>();
       
       ApexPages.StandardSetController con = new ApexPages.StandardSetController(listMRP);
       con.setSelected(listMRP);
       MRPPlannedPurchaseAgainstAgreementExt ext =new MRPPlannedPurchaseAgainstAgreementExt(con);
    
       system.assert(ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // No records selected
       
       tData.mrp2.Required_Date__c = system.today();
       tData.mrp2.Facility__c = tData.fuel.facility2.id;
       tData.mrp1.Planned__c = false;
       tData.mrp2.Planned__c = false;
       
       tData.mrp1.Modified_Quantity__c = 0;
       tData.mrp2.Modified_Quantity__c = 0;
       tData.fuel.itemList[1].Buyer_Planner__c = null;
       tData.fuel.itemList[1].Source__c = 'Manufactured';
       update tData.fuel.itemList[1]; 
       listMRP.add(tData.mrp1);
       listMRP.add(tData.mrp2);
       system.assert(listMRP.size() == 2, 'Nothing in list.');
       
       /*ItemService itemServ = new ItemService();
       String selectedItemCostStatus = 'Active';
       itemServ.calculateItemCosts(new List<Item__c>{tData.fuel.itemList[1]}, selectedItemCostStatus);*/
            
       con = new ApexPages.StandardSetController(listMRP);
       con.setSelected(listMRP);
       ext =new MRPPlannedPurchaseAgainstAgreementExt(con);
       
       system.assert( ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // Should log all warnings coming from validations
       
    }
    
    static testMethod void passAllConstructorValidations() {
        
       MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();       
       tData.fuel.itemList[1].Source__c = 'Purchased';
       tData.fuel.itemList[1].Buyer_Planner__c = UserInfo.getUserId();
       update tData.fuel.itemList[1];
       
       /*ItemService itemServ = new ItemService();
       String selectedItemCostStatus = 'Active';
       itemServ.calculateItemCosts(new List<Item__c>{tData.fuel.itemList[1]}, selectedItemCostStatus);*/
        Test.startTest();
            
       ApexPages.StandardSetController con = new ApexPages.StandardSetController(tData.mrpList);
       con.setSelected(tData.mrpList);
       MRPPlannedPurchaseAgainstAgreementExt ext =new MRPPlannedPurchaseAgainstAgreementExt(con);
    
       system.assert( !ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // all validations pass
       
       system.assert(ext.getContractLinesConfigJson() != null, 'Could not serialize contract lines grid config');
       system.assert(ext.getContractLinesFieldList() != null, 'Could not serialize contract lines grid config'); 
       
       system.assert(ext.getReleaseLinesConfigJson() != null, 'Could not serialize contract lines grid config');
       system.assert(ext.getReleaseLinesFieldList() != null, 'Could not serialize contract lines grid config'); 
       
       system.assert(ext.getMRPPlannedPurchaseConfigJson() != null, 'Could not serialize contract lines grid config');
       system.assert(ext.getMRPPlannedPurchaseFieldList() != null, 'Could not serialize contract lines grid config');
       
       List<ID> itemIds = new List<Id>();{
        itemIds.add(tData.fuel.itemList[1].id);
        itemIds.add(tData.fuel.itemList[2].id);
       } 
       List<String> itemUOMKeys = new List<String>();{
        itemUOMKeys.add(tData.fuel.itemList[1].id + '/' + tData.fuel.itemList[1].Purchasing_UOM__c);
        itemUOMKeys.add(tData.fuel.itemList[2].id+ '/' + tData.fuel.itemList[2].Purchasing_UOM__c);
       } 
       List<Id> mrpIds = new List<Id>();{
        mrpIds.add(tData.mrp1.id);
        mrpIds.add(tData.mrp2.id);
       }
       JsonResult resultCTLines = MRPPlannedPurchaseAgainstAgreementExt.getContractLines(tData.fuel.company.id, tData.fuel.facility.id, itemUOMKeys);
       JsonResult resultICRRecords = MRPPlannedPurchaseAgainstAgreementExt.getItemCrossReferenceRecords(tData.fuel.company.id, tData.fuel.facility.id, itemIds);
       JsonResult resultMRPRecords = MRPPlannedPurchaseAgainstAgreementExt.getMRPPlannedPurchaseRecords(mrpIds);
       
       
    }
    
     static testMethod void isQuantityToReleaseWithinMOQLimits() {//KNDY-10905
        MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();
        Contract_Line__c cLine = tData.ContractLine1;
        cLine.Minimum_Order_Quantity__c = 121;
        cLine.Type__c='Fixed';
        update cLine;
        
        JsonResult result = MRPPlannedPurchaseAgainstAgreementExt.isWithinMOQ(cLine, 120);
        system.assertEquals(result.message, Label.Quantity_entered_to_release_is_less_than_minimum_order_quantity+'121');
        system.assertEquals(result.success, false);
        result = MRPPlannedPurchaseAgainstAgreementExt.isWithinMOQ(cLine, 122);
        system.assertEquals(result.success, true);
     }
     
     static testMethod void isQuantityToReleaseWithinTierLimits() {
       MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();       
       tData.fuel.itemList[1].Source__c = 'Purchased';
       tData.fuel.itemList[1].Buyer_Planner__c = UserInfo.getUserId();
       update tData.fuel.itemList[1];
       
       /*ItemService itemServ = new ItemService();
       String selectedItemCostStatus = 'Active';
       itemServ.calculateItemCosts(new List<Item__c>{tData.fuel.itemList[1]}, selectedItemCostStatus);*/

        tData.fuel.itemList[1].Approved_Supplier_Required__c = true;
        update tData.fuel.itemList[1];

        Test.startTest();
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(tData.mrpList);
        con.setSelected(tData.mrpList);
        MRPPlannedPurchaseAgainstAgreementExt ext =new MRPPlannedPurchaseAgainstAgreementExt(con);
        Double quantity = 10;
        
        Contract_Line__c cLine = tData.ContractLine1; //has no MOQ
        JsonResult result = MRPPlannedPurchaseAgainstAgreementExt.isWithinMOQ(cLine, 121);
        system.assertEquals(result.message, Label.Qty_greater_than_Largest_Tier);
        system.assertEquals(result.success, false);
        
        //PTP-90 MOQ validation when the MOQ is not set
        ApexPages.StandardSetController setcon = new ApexPages.StandardSetController(tData.mrpList);
        setcon.setSelected(tData.mrpList);
        MRPPlannedPurchaseAgainstAgreementExt ext1 = new MRPPlannedPurchaseAgainstAgreementExt(setcon);
        
        Contract_Line__c cLine1 = tData.ContractLine1;
        cLine1.Type__c='Fixed';
        update cLine1;
        
        JsonResult result1 = MRPPlannedPurchaseAgainstAgreementExt.isWithinMOQ(cLine1, 120);
        system.assertEquals(result1.success, true);    
        Test.stopTest();
    }
    
    static testMethod void releaseAContractLineAndNetAgainstIt() {
        MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();       
       tData.fuel.itemList[1].Source__c = 'Purchased';
       tData.fuel.itemList[1].Buyer_Planner__c = UserInfo.getUserId();
       update tData.fuel.itemList[1];
       
       /*ItemService itemServ = new ItemService();
       String selectedItemCostStatus = 'Active';
       itemServ.calculateItemCosts(new List<Item__c>{tData.fuel.itemList[1]}, selectedItemCostStatus);*/
       
        Test.startTest();
        
        id cltid = tData.contractLine1.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);
        
        MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper ctlineWrapper2 = new MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Datetime.now().getTime();
            ctlineWrapper2.quantityToRelease = 10;
        }
        
        List<MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper> ctLineWrappers = new List<MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper>();{ 
            ctLineWrappers.add(ctlineWrapper2);
        }
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(tData.mrpList);
        con.setSelected(tData.mrpList);
        MRPPlannedPurchaseAgainstAgreementExt ext =new MRPPlannedPurchaseAgainstAgreementExt(con);
        system.assert( !ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // all validations pass
        
        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :tData.fuel.company.id];
        system.assertEquals(0, poList.size());
        JsonResult resultPO = MRPPlannedPurchaseAgainstAgreementExt.releaseContractLines(tData.fuel.company.id, tData.fuel.facility.Id, ctLineWrappers, tData.mrpList);
        List<Purchase_Order_Line__c> poLineList = [select id, name, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c, Overage_Percentage__c, supplier__r.Default_Receiving_Tolerance__c from Purchase_Order_Line__c where purchase_order__c IN :poList];
        for (Purchase_Order_Line__c poline : poLineList){ 
            system.assertEquals(poline.supplier__r.Default_Receiving_Tolerance__c,poline.Overage_Percentage__c);      
        }
        
    }
    
    private static Contract_Line__c fetchPurchaseAgreementLines( id paid )  {
		Contract_Line__c paLine =  database.query( 
        			queryutil.generateQueryFromFieldSet('Contract_Line__c', 
        				new set<string>{'Line_Release', 'Tiers', 'Extended_Tiers'},
        				new set<string>{'Id','Line__c','UOM__c','Contract__r.Company__c', 'Contract__r.Company__r.Default_Purchasing_Deliver_To_Facility__c', 'Contract_Quantity__c','Contract_Value__c', 'Location__c', 
        					'Purchased_Quantity__c', 'PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c','Remaining_Value__c','Remaining_Value_Percent__c','Status__c',
        					'ValueReceived__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 'Contract__r.FOB_Term__r.id', 'Item__c', 'Item__r.Description__c', 'Contract__r.Supplier__c', 'Contract__r.Currency__c',
        					'Item__r.Buyer_Planner__c','Item__r.Purchasing_UOM__c','Item__r.PAckaging_UOM__c', 'Item__r.Stocking_UOM__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c', 'Contract__r.Contract_Number__c', 'Status__c', 'Contract__c', 'Contract__r.Supplier__r.Remit_To__c',
        					'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c','Contract__r.Supplier__r.Default_Receiving_Tolerance__c'},
	    				'  id =:paid  order by Line__c asc limit 1' )) ;
        return paLine ;
    }
   //PTP-262 Check for need date error when the Contract Start and End date are today
   static testMethod void NeedDateValidate() {
       MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();       
       tData.fuel.itemList[1].Source__c = 'Purchased';
       tData.fuel.itemList[1].Buyer_Planner__c = UserInfo.getUserId();
       update tData.fuel.itemList[1];
 	
 		tdata.Contract.Contract_Start__c = Date.today();
 		tdata.Contract.Contract_End__c = Date.today();
 		update tdata.Contract;
 		
 		tdata.ContractLine1.Contract_Start__c = Date.today();
 		tdata.ContractLine1.Contract_End__c = Date.today();
 		update tdata.ContractLine1;
 		
       /*ItemService itemServ = new ItemService();
       String selectedItemCostStatus = 'Active';
       itemServ.calculateItemCosts(new List<Item__c>{tData.fuel.itemList[1]}, selectedItemCostStatus);*/
       
        Test.startTest();
        
        id cltid = tData.contractLine1.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);
        
        MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper ctlineWrapper2 = new MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Datetime.now().getTime();
            ctlineWrapper2.quantityToRelease = 10;
        }
        
        List<MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper> ctLineWrappers = new List<MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper>();{ 
            ctLineWrappers.add(ctlineWrapper2);
        }
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(tData.mrpList);
        con.setSelected(tData.mrpList);
        MRPPlannedPurchaseAgainstAgreementExt ext =new MRPPlannedPurchaseAgainstAgreementExt(con);
        system.assert( !ApexPages.hasMessages() ,' oops '+ApexPages.getMessages() ); // all validations pass
        
        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :tData.fuel.company.id];
        system.assertEquals(0, poList.size());
        JsonResult resultPO = MRPPlannedPurchaseAgainstAgreementExt.releaseContractLines(tData.fuel.company.id, tData.fuel.facility.Id, ctLineWrappers, tData.mrpList);
        List<Purchase_Order_Line__c> poLineList = [select id, name, Company__c, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c, Overage_Percentage__c, supplier__r.Default_Receiving_Tolerance__c from Purchase_Order_Line__c where purchase_order__c IN :poList];
        for (Purchase_Order_Line__c poline : poLineList){ 
            system.assertEquals(poline.Need_Date__c, date.today());
            system.assertEquals(poline.Delivery_Facility__c, tData.fuel.facility.Id);
        }
        JsonResult resultPO1 = MRPPlannedPurchaseAgainstAgreementExt.releaseContractLines(tData.fuel.company.id, null, ctLineWrappers, tData.mrpList);
        List<Purchase_Order_Line__c> poLineList1 = [select id, name, Company__c, Company__r.Default_Purchasing_Deliver_To_Facility__c,  Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c, Overage_Percentage__c, supplier__r.Default_Receiving_Tolerance__c from Purchase_Order_Line__c where purchase_order__c IN :poList];
        for (Purchase_Order_Line__c poline : poLineList1){ 
            system.assertEquals(poline.Delivery_Facility__c, poline.Company__r.Default_Purchasing_Deliver_To_Facility__c);
        }
        
    }
    
    public static testmethod void test_getContractLines(){ //KNDY-11176
        MRPAgreementReleaseTestData tData = new MRPAgreementReleaseTestData();
        
        // Change uom on item2 so that MRP test data are for Items with different UOMs
        tData.fuel.itemList[2].Purchasing_UOM__c = tData.fuel.uomList[2].Id;
        List<Item__c> items = new List<Item__c>{tData.fuel.itemList[2]};
        update items;
        
        // Create new contract lines with different item/uom combination
        Contract_Line__c cl_Item1_UOM2 = tData.contractLine1.clone(false, true);
        cl_Item1_UOM2.Item__c = tData.fuel.itemList[1].Id;
        cl_Item1_UOM2.Purchase_UOM__c = tData.fuel.uomList[2].Id;
        Contract_Line__c cl_Item2_UOM8 = tData.contractLine1.clone(false, true);
        cl_Item2_UOM8.Item__c = tData.fuel.itemList[2].Id;
        cl_Item2_UOM8.Purchase_UOM__c = tData.fuel.uomList[8].Id;
        Contract_Line__c cl_Item2_UOM2 = tData.contractLine1.clone(false, true);
        cl_Item2_UOM2.Item__c = tData.fuel.itemList[2].Id;
        cl_Item2_UOM2.Purchase_UOM__c = tData.fuel.uomList[2].Id;
        List<Contract_Line__c> contractLines = new List<Contract_Line__c>();
        
                
        // Contract Line for item1 with UOMlist[8] exists
        contractLines.add(cl_Item1_UOM2);
        contractLines.add(cl_Item2_UOM8);
        contractLines.add(cl_Item2_UOM2);
        insert contractLines;
        
        tData.contract.Approval_Status__c = 'Approved';
        update tData.contract;
       
        // mrp1 in testdata is for itemList[1], 
        //  contract line in testdata is for itemList[1], uomList[8]
        // mrp2 in testdata is for itemList[2]
        // get item uom keys for mrp records
        List<String> itemUOMKeys = new List<String>();
        String item1_15dgtId = String.ValueOf (tData.fuel.itemList[1].id).substring(0,15);
        String item1UOM_15dgtId = String.ValueOf (tData.fuel.uomList[8].Id).substring(0,15);
        String item2_15dgtId = String.ValueOf (tData.fuel.itemList[2].id).substring(0,15);
        String item2UOM_15dgtId = String.ValueOf (tData.fuel.itemList[2].Purchasing_UOM__c).substring(0,15);
        itemUOMKeys.add(item1_15dgtId + '/' + item1UOM_15dgtId);
        itemUOMKeys.add(item2_15dgtId + '/' + item2UOM_15dgtId);
        

        JsonResult resultCTLines = MRPPlannedPurchaseAgainstAgreementExt.getContractLines(tData.fuel.company.id, tData.fuel.facility.id, itemUOMKeys);
        List<MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper> contractLineWrappers = (List<MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper>) resultCTLines.records;
        system.assertEquals(contractLineWrappers.size(), 2);
        for (MRPPlannedPurchaseAgainstAgreementExt.ContractLineWrapper wrapperRecord:
                                    contractLineWrappers){
            if (wrapperRecord.ctLine.Item__c == tData.fuel.itemList[1].id ){
                system.assert(wrapperRecord.ctLine.Purchase_UOM__c == tData.fuel.uomList[8].Id);
                system.assert(wrapperRecord.ctLine.Id == tData.contractLine1.Id);
            }
            else if (wrapperRecord.ctLine.Item__c == tData.fuel.itemList[2].id ){
                system.assert(wrapperRecord.ctLine.Purchase_UOM__c == tData.fuel.itemList[2].Purchasing_UOM__c);
                system.assert(wrapperRecord.ctLine.Id == cl_Item2_UOM2.Id);
            }
        }
    }
}