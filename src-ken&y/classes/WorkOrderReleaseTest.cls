@isTest
public with sharing class WorkOrderReleaseTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.assembly2 != null && f.workOrder != null && f.phantomWorkOrder != null);
        System.assert(f.smrsList != null && f.stockMovementRuleList != null && f.periodList != null);
		system.assert(f.remitToSupplier !=null && f.supplier !=null && f.wcResources !=null);
        f.facility2.Default_Purchasing_Delivery_Location__c = f.location2.Id;
        update f.facility2;
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void releaseInactiveItemSpecWO() {
        Item_Specification__c is = [SELECT id, name, Active__c from Item_Specification__c WHERE id =:fuel.workOrder.Assembly_Item_Specification__c];
        System.assert(is.Active__c );

        is = new Item_Specification__c(Id=fuel.workOrder.Assembly_Item_Specification__c, Active__c = false);
        update is;

        is = [SELECT id, name, Active__c from Item_Specification__c WHERE id =:is.id];
        System.assert(is.Active__c== false );

        JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        WorkOrderReleaseExt.getRecords(fuel.workorder.Id);
        result = WorkOrderReleaseExt.releaseWO(fuel.workorder.Id);
        System.assert(result.success == false);

        ext.getReturnUrl();
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_DRAFT,'Expected WO status: Draft // WO status: ' + wo.Status__c);
    }
    
    private static testMethod void releaseWO() {
        JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        WorkOrderReleaseExt.getRecords(fuel.workorder.Id);
        result = WorkOrderReleaseExt.releaseWO(fuel.workorder.Id);
        System.assert(result.success == true);
        
        ext.getReturnUrl();
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo.Status__c);
    }
   
    private static testMethod void closed() {
        fuel.workOrder.Status__c = WorkOrderService.WO_STATUS_CLOSED;
        update fuel.workOrder;

        JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        WorkOrderReleaseExt.getRecords(fuel.workorder.Id);
        result = WorkOrderReleaseExt.releaseWO(fuel.workorder.Id);
		System.assert(result.success == false);
		system.assert(result.messages.size()>0);
    }

    private static testMethod void inactiveItem() {
        update new Item__c(Id = fuel.workOrder.Item__c, Active__c = false);

		JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        result = WorkOrderReleaseExt.releaseWO(fuel.workorder.Id);
		System.assert(result.success == false);
		system.assert(result.messages.size()>0);

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,null)[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_DRAFT,'Expected WO status: Draft // WO status: ' + wo.Status__c);
    }

    private static testMethod void noRoutings() {
        delete fuel.routings;

		JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        result = WorkOrderReleaseExt.releaseWO(fuel.workorder.Id);
		System.assert(result.success == true);
		system.assert(result.messages.size()==0);

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo.Status__c);
        System.assert(wo.Release_Date__c != null,'Expected WO release date: "not null" // WO release date: ' + wo.Release_Date__c);
        System.assert(wo.Material_Trackings__r.size() == 2,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 1,'Expected operations: 1 // Operations: ' + wo.Operation_Trackings__r.size());
    }

    private static testMethod void rerelease() {
        JSONResult result= new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        WorkOrderReleaseExt.getRecords(fuel.workorder.Id);
        result = WorkOrderReleaseExt.releaseWO(fuel.workorder.Id);
		System.assert(result.success == true);
		system.assert(result.messages.size()==0);

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo.Status__c);
        System.assert(wo.Release_Date__c != null,'Expected WO release date: "not null" // WO release date: ' + wo.Release_Date__c);
        System.assert(wo.Material_Trackings__r.size() == 2,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Start_Date__c != null,'Expected operation start date: "not null" // operation start date: ' + op.Start_Date__c);
            System.assert(op.End_Date__c != null,'Expected operation end date: "not null" // operation end date: ' + op.End_Date__c);
        }

        wo.Order_Quantity__c = 2;
        update wo;

        result = WorkOrderReleaseExt.releaseWO(wo.Id);
        ext = new WorkOrderReleaseExt(new ApexPages.StandardController(wo));
        System.assert(result.success == true);
		system.assert(result.messages.size()==0);

        Work_Order__c wo2 = WorkOrderService.getWorkOrders(new Set<Id>{ wo.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo2.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo2.Status__c);
        System.assert(wo2.Release_Date__c != null,'Expected WO release date: "not null" // WO release date: ' + wo2.Release_Date__c);
        System.assert(wo2.Material_Trackings__r.size() == 2,'Expected materials: 2 // Materials: ' + wo2.Material_Trackings__r.size());
        System.assert(wo2.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo2.Operation_Trackings__r.size());

        Map<Id,Material_Tracking__c> oldMaterials = new Map<Id,Material_Tracking__c>(wo.Material_Trackings__r);
        Map<Id,Operation_Tracking__c> oldOperations = new Map<Id,Operation_Tracking__c>(wo.Operation_Trackings__r);

        for (Material_Tracking__c mt:wo2.Material_Trackings__r) {
            Material_Tracking__c oldMT = oldMaterials.get(mt.Id);
            System.assert(oldMT != null,'Old material not found');
            System.assert(mt.Quantity_Required__c != oldMT.Quantity_Required__c,'Material quantity was not changed');
        }

        for (Operation_Tracking__c op:wo2.Operation_Trackings__r) {
            Operation_Tracking__c oldOp = oldOperations.get(op.Id);
            System.assert(oldOp != null,'Old operation not found');
            System.assert(op.Start_Date__c != null,'Expected operation start date: "not null" // operation start date: ' + op.Start_Date__c);
            System.assert(op.End_Date__c != null,'Expected operation end date: "not null" // operation end date: ' + op.End_Date__c);
            System.assert(op.End_Date__c != oldOp.End_Date__c,'Operaiont end date was not changed');
        }
    }
    
    private static testMethod void noneSelected() {
        List<Work_Order__c> workOrders  = new List<Work_Order__c>{ fuel.workOrder }; 
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(workOrders);
        WOReleaseExtension ext = new WOReleaseExtension(sc);
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),ApexPages.getMessages());
    }

    private static testMethod void inactiveItem2() {
        update new Item__c(Id = fuel.workOrder.Item__c, Active__c = false);
        
        List<Work_Order__c> workOrders  = new List<Work_Order__c>{ fuel.workOrder }; 
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(workOrders);
        sc.setSelected(workOrders);
        WOReleaseExtension ext = new WOReleaseExtension(sc);
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),ApexPages.getMessages());
    }

    private static testMethod void releaseMultiple() {
        List<Work_Order__c> workOrders  = new List<Work_Order__c>{ fuel.workOrder }; 
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(workOrders);
        sc.setSelected(workOrders);
        WOReleaseExtension ext = new WOReleaseExtension(sc);

        JsonResult result = WOReleaseExtension.release(new List<Id>{ fuel.workOrder.Id });
        System.assert(result.success == true, result);

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo.Status__c);
        System.assert(wo.Release_Date__c != null,'Expected WO release date: "not null" // WO release date: ' + wo.Release_Date__c);
        System.assert(wo.Material_Trackings__r.size() == 2,'Expected materials: 9 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 6 // Operations: ' + wo.Operation_Trackings__r.size());


        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Start_Date__c != null,'Expected operation start date: "not null" // operation start date: ' + op.Start_Date__c);
            System.assert(op.End_Date__c != null,'Expected operation end date: "not null" // operation end date: ' + op.End_Date__c);
        }
    }
    
    private static testMethod void testWorkOrderUOMNotItemUOM () {
        try{
        fuel.workOrder.Packaging_UOM__c = fuel.uomList[0].ID;
        update fuel.workOrder;
        	system.assert(false, 'Invalid from or to UOM for Item Packaging UOM');
        }catch(Exception ex){
        	system.assert(ex.getMessage().contains('Invalid from or to UOM for Item Packaging UOM'));
        }
    } 

    private static testMethod void phantomRoutingsNoCopy() {
        
        JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.phantomWorkOrder));
        
        result = WorkOrderReleaseExt.releaseWO(fuel.phantomWorkOrder.Id);
        
        System.assert(result.success == true);
        
		system.assert(result.messages.size()==0);
        

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.phantomWorkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo.Status__c);
        System.assert(wo.Release_Date__c != null,'Expected WO release date: "not null" // WO release date: ' + wo.Release_Date__c);
        System.assert(wo.Material_Trackings__r.size() == 9,'Expected materials: 9 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Start_Date__c != null,'Expected operation start date: "not null" // operation start date: ' + op.Start_Date__c);
            System.assert(op.End_Date__c != null,'Expected operation end date: "not null" // operation end date: ' + op.End_Date__c);
        }
    }

    private static testMethod void phantomRoutingsCopy() {
        update new Item_Specification__c(Id = fuel.assembly.Id, Copy_Phantom_Routings__c = true);

        
        JSONResult result = new JSONResult();
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.phantomWorkOrder));
        
        result = WorkOrderReleaseExt.releaseWO(fuel.phantomWorkOrder.Id);
        
        System.assert(result.success == true);
        
		system.assert(result.messages.size()==0);
		

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.phantomWorkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r', 'Operation_Trackings__r' })[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: Released // WO status: ' + wo.Status__c);
        System.assert(wo.Release_Date__c != null,'Expected WO release date: "not null" // WO release date: ' + wo.Release_Date__c);
        System.assert(wo.Material_Trackings__r.size() == 9,'Expected materials: 9 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 6,'Expected operations: 6 // Operations: ' + wo.Operation_Trackings__r.size());

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Start_Date__c != null,'Expected operation start date: "not null" // operation start date: ' + op.Start_Date__c);
            System.assert(op.End_Date__c != null,'Expected operation end date: "not null" // operation end date: ' + op.End_Date__c);
        }
    }
	
    
    private static testMethod void testSpiltSubcontractWOonRelease(){
    	
    	
    	DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Operation_Transaction__c.sObjectType,Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,Work_Center__c.sObjectType,
        	                                  Work_Center_Resource__c.sObjectType,Company__c.sObjectType,Component__c.sObjectType,
        	                                  Item_Specification__c.sObjectType,Operation_Tracking__c.sObjectType,Material_Tracking__c.sObjectType,
        	                                  Supplier__c.sObjectType,Routing__c.sObjectType,Item_Attribute__c.sObjectType,Work_Order__c.sObjectType,Item_Cost__c.sObjectType,Item_Cross_Reference__c.sObjectType,
        	                                  Supplier_Invoice__c.sObjectType, Customer__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        
        FOB_Terms__c fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
        insert fobTerm;
        
    	Supplier__c supplier2 = new Supplier__c(); 
        supplier2.Name = fuel.company.Name + ' Supplier-2';
        supplier2.Company__c = fuel.company.ID;
        supplier2.Tax_ID__c = 'tax ID 2';
        supplier2.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
        supplier2.Status__c = 'Active';
        supplier2.FOB_Term__c = fobTerm.id;
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
        supplier2.Remit_To__c =  fuel.remittosupplier.id;
        supplier2.Default_Receiving_Tolerance__c = 3;
        supplier2.Create_RTV_Credit_Memo__c = true;
        supplier2.Create_RTV_PO__c = true; 
        supplier2.Alternate_Name__c = 'Test Supplier 2';
        insert supplier2;
        
        
        Item_Specification__c itemspec1 = new Item_Specification__c(
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Item__c = fuel.itemList[5].Id,
	        Revision__c = 'R1',
            Start_Date2__c = System.now().addDays(-2),
	        Costing__c = true,
	        Production__c = true,
	        Copy_Phantom_Routings__c = false
        );
        insert itemSpec1;
        
        List<Routing__c> routings = new List<Routing__c>();
        for (Integer i=0;i<3;i++) {
            routings.add(new Routing__c(
                Assembly_Item_Specification__c = itemspec1.Id,
                Company__c = fuel.company.Id,
                Facility__c = fuel.facility2.Id,
                Operation_Sequence__c = 1,
                Work_Center_Resource__c = fuel.wcResources[i].Id,
                Work_Center__c = fuel.wcResources[i].Work_Center__c,
                Resource_Sequence__c = i + 1,
                Resource_Quantity__c = 1,
                Standard_Hours__c = 1,
                Fixed_Hours__c = false,
                Backflush_Resource__c = false
            ));
        }
        insert routings;   
        
    	fuel.components[0].Supplier__c = fuel.supplier.Id;
    	
    	update fuel.components[0];
    	
    	Item__c ospItem = fuel.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = false;
        ospItem.Item_Attribute__c = null;
        ospItem.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem;
        
        fuel.components[1].Supplier__c = fuel.supplier.Id;
        fuel.components[1].Routing__c = fuel.routings[1].Id;
    	update fuel.components[1];
    	
        Item__c ospItem2 = fuel.itemList[0].clone(true,true);
        ospItem2.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem2.Non_Inventory__c = false;
        ospItem2.Item_Attribute__c = null;
        ospItem2.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem2;
        
        
                 
        List<Component__c> complist = new List<Component__c>();
        
        fuel.itemList[4].Source__c = 'Manufactured';
        update  fuel.itemList[4];
        
        Component__c nonOSPcomp1 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[4].Id,
            Component_Item__r = fuel.itemList[4],
            Component_Sequence__c = 1,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[2].Id
         );  
         insert nonOSPcomp1;
         
         
         Component__c comp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 2,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         );  
         
         //insert comp2;
         complist.add(comp2);
         
         Component__c clonedComp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 3,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         ); 
         //insert clonedComp2;
        
        complist.add(clonedComp2);
        
        Component__c ospComp = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem2.Id,
            Component_Item__r = ospItem2,
            Component_Sequence__c = 4,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[1].Id
         ); 
         
        //insert ospComp;
        
        complist.add(ospComp);
        
        Component__c ospCompClone = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem2.Id,
            Component_Item__r = ospItem2,
            Component_Sequence__c = 5,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[1].Id
         ); 
         
        //insert ospCompClone;
        
        complist.add(ospCompClone);
        
        insert complist;
        
        Work_Order__c subworkOrder = new Work_Order__c(
		
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Assembly_Item_Specification__c = itemspec1.Id,
	        Item__c = itemspec1.Item__c,
	        Need_Date2__c = System.today() + 30,
	        Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
	        Order_Quantity__c = 25,
	        Status__c = 'Draft',
	        Type__c = 'Regular',
	        Complete_To_Location__c = fuel.location6.Id,
	        MRB_Location__c = fuel.location2.Id,
	        Default_WIP_Location__c = fuel.location7.Id,
	        Notes__c = 'subworkorder',
	        Currency__c = fuel.currencyUSD.ID,
	        Packaging_UOM__c = fuel.uomList[8].Id
	    );
	    insert subworkOrder;
	    
	    Id itemspecId = itemspec1.Id;
	    List<Component__c> phantomcomplist = new List<Component__c>();
    	SOQLUtil soql = new SOQLUtil('Component__c');
	    soql.addFields(new Set<String>{'Id'});
	    soql.setWhereClause('Assembly_Item_Specification__c != :itemspecId');
	    
    	phantomcomplist = Database.query(soql.getQuery());
    	
    	delete phantomcomplist;
    	
		JSONResult result = new JSONResult();
		JSONResult resultPOs = new JSONResult();
		JSONResult resultRelease = new JSONResult();
        
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        
        result = WorkOrderReleaseExt.getRecords(subworkOrder.Id);
        
        resultPOs = WorkOrderReleaseExt.getPOList(fuel.supplier.Id);
        
        List<WorkOrderReleaseExt.worderWrapper> worderwrappers = new List<WorkOrderReleaseExt.worderWrapper>();
        
        worderwrappers = (List<WorkOrderReleaseExt.worderWrapper>)result.records;
        
        for(WorkOrderReleaseExt.worderWrapper wrap:worderwrappers){
			SObject obj = wrap.rec;
			Id itemId = (Id)obj.get('Item__c');
			Id supplierId = (Id)obj.get('Supplier__c');
		    wrap.tempvalMap.put('Selected','true');
		    if(itemId == ospItem2.Id){
		        wrap.inputMap.put('Routing__c',routings[1]);
		    }
		    else if(itemId == ospItem.Id){
		        wrap.inputMap.put('Routing__c',routings[0]);
		    }
		    if(itemId == ospItem.Id && supplierId == supplier2.Id){
		    	obj.put('Quantity_Required__c',10);
		    }
		    else if(itemId == ospItem.Id && supplierId == fuel.supplier.Id){
		    	obj.put('Quantity_Required__c',15);
		    }
		    else if(itemId == ospItem2.Id && supplierId == supplier2.Id){
		    	obj.put('Quantity_Required__c',7);
		    }
		    else if(itemId == ospItem2.Id && supplierId == fuel.supplier.Id){
		    	obj.put('Quantity_Required__c',18);
		    }
		    
			
		}
        
        resultRelease = WorkOrderReleaseExt.release(worderwrappers,new List<String>{},subworkOrder,true);
        system.assert(resultRelease.success ==true,resultRelease);
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
		
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: ' + WorkOrderService.WO_STATUS_RELEASED + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 5,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        Set<Id> subcontractOpIds = new Set<Id>();
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id) {
                subcontractOpIds.add(m.Operation_Tracking__c);
            }
            else if(m.Item__c == ospItem2.Id){
            	subcontractOpIds.add(m.Operation_Tracking__c);
            }
        }
        System.assert(subcontractOpIds.size()>0,'Subcontract operation Id is null');
        
        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
        polQuery.setWhereClause('Operation_Tracking__c IN :subcontractOpIds');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());

        System.assert(poLines.size() == 4,'Expected PO lines: 4 // PO lines: ' + poLines.size());
		Purchase_Order__c po;
		Purchase_Order__c po1;
		Set<Id> polineIds = new Set<Id>();
		Set<Id> poIds = new Set<Id>();
		Map<Id,Set<Id>> polinemap = new Map<Id,Set<Id>>();
		
        for(Purchase_Order_Line__c pol:poLines){
        	polineIds.add(pol.Id);
        	poIds.add(pol.Purchase_Order__c);
        	
        	if(!polinemap.containskey(pol.Purchase_Order__c))
        		polinemap.put(pol.Purchase_Order__c,new Set<Id>{pol.Id});
        	else
        		polinemap.get(pol.Purchase_Order__c).add(pol.Id);
        		
        	System.assert(pol.Item_Specification__c == wo.Assembly_Item_Specification__c,'Expected POL spec: ' + wo.Assembly_Item_Specification__c + ' // POL spec: ' + pol.Item_Specification__c);
        	if(pol.Supplier__c == supplier2.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == supplier2.Id,'Expected PO supplier: ' + supplier2.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 10,'Expected POL quantity: 8' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == fuel.supplier.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == fuel.supplier.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 15,'Expected POL quantity: 10' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po1 = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == supplier2.Id && pol.Item__c == ospItem2.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == supplier2.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 7,'Expected POL quantity: 4' + ' // POL quantity: ' + pol.Order_Quantity__c);
        	}
        	else if(pol.Supplier__c == fuel.supplier.Id && pol.Item__c == ospItem2.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == fuel.supplier.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 18,'Expected POL quantity: 3' + ' // POL quantity: ' + pol.Order_Quantity__c);
        	}
        	system.assert(pol.Material_Tracking__c !=null);
        	system.assert(pol.Status__c =='Open');
        	
	        System.assert(pol.Purchase_Order__r.Delivery_Facility__c == wo.Facility__c,'Expected PO delivery facility: ' + wo.Facility__c + ' // PO delivery facility: ' + pol.Purchase_Order__r.Delivery_Facility__c);
	        System.assert(pol.Purchase_Order__r.Delivery_Location__c == fuel.location2.Id,'Expected PO delivery location: ' + fuel.location2.Id + ' // PO delivery location: ' + pol.Purchase_Order__r.Delivery_Location__c);
        	
        	
        }
        
        system.assert(poIds.size() == 2,poIds.size());//Only two PO's should be created one for each supplier.
        po.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po;
        
        po1.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po1;
       
        //Receive all PO's
        Set<Id> lineIds = new Set<Id>();
        Set<Id> lineIds1 = new Set<Id>();
        lineIds.addAll(polinemap.get(po.Id));
        lineIds1.addAll(polinemap.get(po1.Id));
        List<ReceivingWrapper> rWrappers = getReceivingWrappers(lineIds);
        Receiving_Document__c rd = getRD(lineIds);

        for(ReceivingWrapper rw: rWrappers){
	        
	        for( SkidService3.serialWrapper sw : rw.serialWrapperList){
	            SKID__c skid = sw.skid;
	            skid.Expiration_Date__c = system.today() + 5;
	            skid.Lot_Number__c = 'LOT 1' ;
	            if(skid.Item__c == ospItem.Id){
	                skid.Quantity__c = 10;
	            }
	            else if(skid.Item__c == ospItem2.Id){
	            	skid.Quantity__c = 7;
	            }
	            
	            List<Serial__c> serialList = new List<Serial__c>();
	            for (Integer i=0;i<skid.Quantity__c;i++) {
	                Serial__c ser = new Serial__c(
	                    Name = 'Serial ' + i,
	                    Item__c = skid.Item__c,
	                    Company__c = fuel.company.Id
	                );
	                ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
	                serialList.Add(ser);
	            }
	            sw.serialList = serialList;             
	        }
	    }

		Test.startTest();
        receive(rWrappers,rd);
        
        List<ReceivingWrapper> rWrappers1 = getReceivingWrappers(lineIds1);
        Receiving_Document__c rd1 = getRD(lineIds1);
		
        for(ReceivingWrapper rw: rWrappers1){
	        
	        for( SkidService3.serialWrapper sw : rw.serialWrapperList){
	            SKID__c skid = sw.skid;
	            skid.Expiration_Date__c = system.today() + 20;
	            skid.Lot_Number__c = 'LOT 1' ;
	            if(skid.Item__c == ospItem.Id){
	            	skid.Quantity__c = 15;
	            }
	            else if(skid.Item__c == ospItem2.Id){
	            	skid.Quantity__c = 18;
	            }
	            
	            List<Serial__c> serialList = new List<Serial__c>();
	            for (Integer i=0;i<skid.Quantity__c;i++) {
	                Serial__c ser = new Serial__c(
	                    Name = 'Serial X ' + i,
	                    Item__c = skid.Item__c,
	                    Company__c = fuel.company.Id
	                );
	                ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
	                serialList.Add(ser);
	            }
	            sw.serialList = serialList;             
	        }
	    }
		
		
        receive(rWrappers1,rd1);
        
        delete configList;
        wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
        
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: ' + WorkOrderService.WO_STATUS_IN_PROCESS + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 5,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id && m.Supplier__c == supplier2.Id) {
                system.assert(m.Quantity_Issued__c == 10,wo.Material_Trackings__r);
            }
            if (m.Item__c == ospItem.Id && m.Supplier__c == fuel.supplier.Id) {
               system.assert(m.Quantity_Issued__c == 15,m.Quantity_Issued__c);
            }
            if (m.Item__c == ospItem2.Id && m.Supplier__c == supplier2.Id) {
                system.assert(m.Quantity_Issued__c == 7,m.Quantity_Issued__c);
            }
            if (m.Item__c == ospItem2.Id && m.Supplier__c == fuel.supplier.Id) {
                system.assert(m.Quantity_Issued__c == 18,m.Quantity_Issued__c);
            }
            
        }

        
        Operation_Tracking__c subcontractOperation1;
        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if (op.Routing__c == routings[0].Id) {
                system.assert(op.Quantity_Completed__c == 25);
            }
            else if(op.Routing__c == routings[1].Id){
            	system.assert(op.Quantity_Completed__c == 25);
            }
        }
        
       Test.stopTest();
    
    }
    
    private static testMethod void testMixedSpiltSubcontractWOonRelease_OnlySave(){
    	
    	
    	DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Operation_Transaction__c.sObjectType,Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,Work_Center__c.sObjectType,
        	                                  Work_Center_Resource__c.sObjectType,Company__c.sObjectType,Component__c.sObjectType,
        	                                  Item_Specification__c.sObjectType,Operation_Tracking__c.sObjectType,Material_Tracking__c.sObjectType,
        	                                  Supplier__c.sObjectType,Routing__c.sObjectType,Item_Attribute__c.sObjectType,Work_Order__c.sObjectType,Item_Cost__c.sObjectType,Item_Cross_Reference__c.sObjectType,
        	                                  Supplier_Invoice__c.sObjectType, Customer__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        
        FOB_Terms__c fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
        insert fobTerm;
        
    	Supplier__c supplier2 = new Supplier__c(); 
        supplier2.Name = fuel.company.Name + ' Supplier-2';
        supplier2.Company__c = fuel.company.ID;
        supplier2.Tax_ID__c = 'tax ID 2';
        supplier2.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
        supplier2.Status__c = 'Active';
        supplier2.FOB_Term__c = fobTerm.id;
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
        supplier2.Remit_To__c =  fuel.remittosupplier.id;
        supplier2.Default_Receiving_Tolerance__c = 3;
        supplier2.Create_RTV_Credit_Memo__c = true;
        supplier2.Create_RTV_PO__c = true; 
        supplier2.Alternate_Name__c = 'Test Supplier 2';
        insert supplier2;
        
        
        Item_Specification__c itemspec1 = new Item_Specification__c(
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Item__c = fuel.itemList[5].Id,
	        Revision__c = 'R1',
            Start_Date2__c = System.now().addDays(-2),
	        Costing__c = true,
	        Production__c = true,
	        Copy_Phantom_Routings__c = false
        );
        insert itemSpec1;
        
        List<Routing__c> routings = new List<Routing__c>();
        for (Integer i=0;i<3;i++) {
            routings.add(new Routing__c(
                Assembly_Item_Specification__c = itemspec1.Id,
                Company__c = fuel.company.Id,
                Facility__c = fuel.facility2.Id,
                Operation_Sequence__c = 1,
                Work_Center_Resource__c = fuel.wcResources[i].Id,
                Work_Center__c = fuel.wcResources[i].Work_Center__c,
                Resource_Sequence__c = i + 1,
                Resource_Quantity__c = 1,
                Standard_Hours__c = 1,
                Fixed_Hours__c = false,
                Backflush_Resource__c = false
            ));
        }
        insert routings;   
        
    	fuel.components[0].Supplier__c = fuel.supplier.Id;
    	
    	update fuel.components[0];
    	
    	Item__c ospItem = fuel.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = false;
        ospItem.Item_Attribute__c = null;
        ospItem.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem;
        
        fuel.components[1].Supplier__c = fuel.supplier.Id;
        fuel.components[1].Routing__c = fuel.routings[1].Id;
    	update fuel.components[1];
    	
        Item__c ospItem2 = fuel.itemList[0].clone(true,true);
        ospItem2.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem2.Non_Inventory__c = false;
        ospItem2.Item_Attribute__c = null;
        ospItem2.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem2;
        
        
                 
        List<Component__c> complist = new List<Component__c>();
        
        fuel.itemList[4].Source__c = 'Manufactured';
        update  fuel.itemList[4];
        
        Component__c nonOSPcomp1 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[4].Id,
            Component_Item__r = fuel.itemList[4],
            Component_Sequence__c = 1,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[2].Id
         );  
         insert nonOSPcomp1;
         
         
         Component__c comp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 2,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         );  
         
         //insert comp2;
         complist.add(comp2);
         
         Component__c clonedComp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 3,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         ); 
         //insert clonedComp2;
        
        complist.add(clonedComp2);
        
        
        Component__c ospCompClone = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem2.Id,
            Component_Item__r = ospItem2,
            Component_Sequence__c = 5,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[1].Id
         ); 
         
        //insert ospCompClone;
        
        complist.add(ospCompClone);
        
        insert complist;
        
        Work_Order__c subworkOrder = new Work_Order__c(
		
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Assembly_Item_Specification__c = itemspec1.Id,
	        Item__c = itemspec1.Item__c,
	        Need_Date2__c = System.today() + 30,
	        Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
	        Order_Quantity__c = 5,
	        Status__c = 'Draft',
	        Type__c = 'Regular',
	        Complete_To_Location__c = fuel.location6.Id,
	        MRB_Location__c = fuel.location2.Id,
	        Default_WIP_Location__c = fuel.location7.Id,
	        Notes__c = 'subworkorder',
	        Currency__c = fuel.currencyUSD.ID,
	        Packaging_UOM__c = fuel.uomList[8].Id
	    );
	    insert subworkOrder;
	    
	    Id itemspecId = itemspec1.Id;
	    List<Component__c> phantomcomplist = new List<Component__c>();
    	SOQLUtil soql = new SOQLUtil('Component__c');
	    soql.addFields(new Set<String>{'Id'});
	    soql.setWhereClause('Assembly_Item_Specification__c != :itemspecId');
	    
    	phantomcomplist = Database.query(soql.getQuery());
    	
    	delete phantomcomplist;
    	
		JSONResult result = new JSONResult();
		JSONResult resultPOs = new JSONResult();
		JSONResult resultRelease = new JSONResult();
        
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        
        result = WorkOrderReleaseExt.getRecords(subworkOrder.Id);
        
        resultPOs = WorkOrderReleaseExt.getPOList(fuel.supplier.Id);
        
        List<WorkOrderReleaseExt.worderWrapper> worderwrappers = new List<WorkOrderReleaseExt.worderWrapper>();
        
        worderwrappers = (List<WorkOrderReleaseExt.worderWrapper>)result.records;
        
        for(WorkOrderReleaseExt.worderWrapper wrap:worderwrappers){
			SObject obj = wrap.rec;
			Id itemId = (Id)obj.get('Item__c');
			Id supplierId = (Id)obj.get('Supplier__c');
		    
		    if(itemId == ospItem2.Id){
		        wrap.inputMap.put('Routing__c',routings[1]);
		    }
		    else if(itemId == ospItem.Id){
		        wrap.inputMap.put('Routing__c',routings[0]);
		    }
		    if(itemId == ospItem.Id && supplierId == supplier2.Id){
		    	obj.put('Quantity_Required__c',3);
		    }
		    else if(itemId == ospItem.Id && supplierId == fuel.supplier.Id){
		    	obj.put('Quantity_Required__c',2);
		    }
		}
        
        resultRelease = WorkOrderReleaseExt.release(worderwrappers,new List<String>{},subworkOrder,true);
        system.assert(resultRelease.success ==true,resultRelease);
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
		
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: ' + WorkOrderService.WO_STATUS_RELEASED + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 4,'Expected materials: 4 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        Set<Id> subcontractOpIds = new Set<Id>();
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id) {
                subcontractOpIds.add(m.Operation_Tracking__c);
            }
            else if(m.Item__c == ospItem2.Id){
            	subcontractOpIds.add(m.Operation_Tracking__c);
            }
        }
        System.assert(subcontractOpIds.size()>0,'Subcontract operation Id is null');
        
        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
        polQuery.setWhereClause('Operation_Tracking__c IN :subcontractOpIds');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());

        System.assert(poLines.size() == 3,'Expected PO lines: 3 // PO lines: ' + poLines.size());
		Purchase_Order__c po;
		Purchase_Order__c po1;
		Purchase_Order__c po2;
		Set<Id> polineIds = new Set<Id>();
		Set<Id> poIds = new Set<Id>();
		Map<Id,Set<Id>> polinemap = new Map<Id,Set<Id>>();
		
        for(Purchase_Order_Line__c pol:poLines){
        	polineIds.add(pol.Id);
        	poIds.add(pol.Purchase_Order__c);
        	
        	if(!polinemap.containskey(pol.Purchase_Order__c))
        		polinemap.put(pol.Purchase_Order__c,new Set<Id>{pol.Id});
        	else
        		polinemap.get(pol.Purchase_Order__c).add(pol.Id);
        		
        	System.assert(pol.Item_Specification__c == wo.Assembly_Item_Specification__c,'Expected POL spec: ' + wo.Assembly_Item_Specification__c + ' // POL spec: ' + pol.Item_Specification__c);
        	if(pol.Supplier__c == supplier2.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == supplier2.Id,'Expected PO supplier: ' + supplier2.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 3,'Expected POL quantity: 3' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == fuel.supplier.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == fuel.supplier.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 2,'Expected POL quantity: 2' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po1 = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == fuel.supplier.Id && pol.Item__c == ospItem2.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == fuel.supplier.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 5,'Expected POL quantity: 5' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po2 = pol.Purchase_Order__r;
        	}
        	
        	system.assert(pol.Material_Tracking__c !=null);
        	system.assert(pol.Status__c =='Open');
        	
	        System.assert(pol.Purchase_Order__r.Delivery_Facility__c == wo.Facility__c,'Expected PO delivery facility: ' + wo.Facility__c + ' // PO delivery facility: ' + pol.Purchase_Order__r.Delivery_Facility__c);
	        System.assert(pol.Purchase_Order__r.Delivery_Location__c == fuel.location2.Id,'Expected PO delivery location: ' + fuel.location2.Id + ' // PO delivery location: ' + pol.Purchase_Order__r.Delivery_Location__c);
        	
        	
        }
        
        system.assert(poIds.size() == 3,poIds.size());//SAVE --3 PO's should be created one for each routing/supplier.
        po.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po;
        
        po1.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po1;
        
        po2.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po2;
       
        //Receive all PO's
        Set<Id> lineIds = new Set<Id>();
        Set<Id> lineIds1 = new Set<Id>();
        Set<Id> lineIds2 = new Set<Id>();
        lineIds.addAll(polinemap.get(po.Id));
        lineIds1.addAll(polinemap.get(po1.Id));
        lineIds.addAll(polinemap.get(po2.Id));
        List<ReceivingWrapper> rWrappers = getReceivingWrappers(lineIds);
        Receiving_Document__c rd = getRD(lineIds);

        for(ReceivingWrapper rw: rWrappers){
	        
	        for( SkidService3.serialWrapper sw : rw.serialWrapperList){
	            SKID__c skid = sw.skid;
	            skid.Expiration_Date__c = system.today() + 5;
	            skid.Lot_Number__c = 'LOT 1' ;
	            if(skid.Item__c == ospItem.Id){
	                skid.Quantity__c = 3;
	            }
	            if(skid.Item__c == ospItem2.Id){
	                skid.Quantity__c = 5;
	            }
	            
	            List<Serial__c> serialList = new List<Serial__c>();
	            for (Integer i=0;i<skid.Quantity__c;i++) {
	                Serial__c ser = new Serial__c(
	                    Name = 'Serial ' + i,
	                    Item__c = skid.Item__c,
	                    Company__c = fuel.company.Id
	                );
	                ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
	                serialList.Add(ser);
	            }
	            sw.serialList = serialList;             
	        }
	    }

		Test.startTest();
        receive(rWrappers,rd);
        
        List<ReceivingWrapper> rWrappers1 = getReceivingWrappers(lineIds1);
        Receiving_Document__c rd1 = getRD(lineIds1);
		
        for(ReceivingWrapper rw: rWrappers1){
	        
	        for( SkidService3.serialWrapper sw : rw.serialWrapperList){
	            SKID__c skid = sw.skid;
	            skid.Expiration_Date__c = system.today() + 20;
	            skid.Lot_Number__c = 'LOT 1' ;
	            if(skid.Item__c == ospItem.Id){
	            	skid.Quantity__c = 2;
	            }
	            
	            List<Serial__c> serialList = new List<Serial__c>();
	            for (Integer i=0;i<skid.Quantity__c;i++) {
	                Serial__c ser = new Serial__c(
	                    Name = 'Serial X ' + i,
	                    Item__c = skid.Item__c,
	                    Company__c = fuel.company.Id
	                );
	                ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
	                serialList.Add(ser);
	            }
	            sw.serialList = serialList;             
	        }
	    }
		
		
        receive(rWrappers1,rd1);
        
        
        delete configList;
        wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
        
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: ' + WorkOrderService.WO_STATUS_IN_PROCESS + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 4,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id && m.Supplier__c == supplier2.Id) {
                system.assert(m.Quantity_Issued__c == 3,wo.Material_Trackings__r);
            }
            if (m.Item__c == ospItem.Id && m.Supplier__c == fuel.supplier.Id) {
               system.assert(m.Quantity_Issued__c == 2,m.Quantity_Issued__c);
            }
            if (m.Item__c == ospItem2.Id && m.Supplier__c == supplier2.Id) {
                system.assert(m.Quantity_Issued__c == 5,m.Quantity_Issued__c);
            }
        }

        Operation_Tracking__c subcontractOperation1;
        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if (op.Routing__c == routings[0].Id) {
                system.assert(op.Quantity_Completed__c == 5);
            }
            else if(op.Routing__c == routings[1].Id){
            	system.assert(op.Quantity_Completed__c == 5);
            }
        }
        
       Test.stopTest();
    
    }
    
    private static testMethod void testMixedSpiltSubcontractWOonRelease_with_ExistingPO(){
    	
    	
    	DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Operation_Transaction__c.sObjectType,Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,Work_Center__c.sObjectType,
        	                                  Work_Center_Resource__c.sObjectType,Company__c.sObjectType,Component__c.sObjectType,
        	                                  Item_Specification__c.sObjectType,Operation_Tracking__c.sObjectType,Material_Tracking__c.sObjectType,
        	                                  Supplier__c.sObjectType,Routing__c.sObjectType,Item_Attribute__c.sObjectType,Work_Order__c.sObjectType,Item_Cost__c.sObjectType,Item_Cross_Reference__c.sObjectType,
        	                                  Supplier_Invoice__c.sObjectType, Customer__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        
        FOB_Terms__c fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
        insert fobTerm;
        
    	Supplier__c supplier2 = new Supplier__c(); 
        supplier2.Name = fuel.company.Name + ' Supplier-2';
        supplier2.Company__c = fuel.company.ID;
        supplier2.Tax_ID__c = 'tax ID 2';
        supplier2.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
        supplier2.Status__c = 'Active';
        supplier2.FOB_Term__c = fobTerm.id;
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
        supplier2.Remit_To__c =  fuel.remittosupplier.id;
        supplier2.Default_Receiving_Tolerance__c = 3;
        supplier2.Create_RTV_Credit_Memo__c = true;
        supplier2.Create_RTV_PO__c = true; 
        supplier2.Alternate_Name__c = 'Test Supplier 2';
        insert supplier2;
        
        
        Item_Specification__c itemspec1 = new Item_Specification__c(
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Item__c = fuel.itemList[5].Id,
	        Revision__c = 'R1',
            Start_Date2__c = System.now().addDays(-2),
	        Costing__c = true,
	        Production__c = true,
	        Copy_Phantom_Routings__c = false
        );
        insert itemSpec1;
        
        List<Routing__c> routings = new List<Routing__c>();
        for (Integer i=0;i<3;i++) {
            routings.add(new Routing__c(
                Assembly_Item_Specification__c = itemspec1.Id,
                Company__c = fuel.company.Id,
                Facility__c = fuel.facility2.Id,
                Operation_Sequence__c = 1,
                Work_Center_Resource__c = fuel.wcResources[i].Id,
                Work_Center__c = fuel.wcResources[i].Work_Center__c,
                Resource_Sequence__c = i + 1,
                Resource_Quantity__c = 1,
                Standard_Hours__c = 1,
                Fixed_Hours__c = false,
                Backflush_Resource__c = false
            ));
        }
        insert routings;   
        
    	fuel.components[0].Supplier__c = fuel.supplier.Id;
    	
    	update fuel.components[0];
    	
    	Item__c ospItem = fuel.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = false;
        ospItem.Item_Attribute__c = null;
        ospItem.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem;
        
        fuel.components[1].Supplier__c = fuel.supplier.Id;
        fuel.components[1].Routing__c = fuel.routings[1].Id;
    	update fuel.components[1];
    	
        Item__c ospItem2 = fuel.itemList[0].clone(true,true);
        ospItem2.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem2.Non_Inventory__c = false;
        ospItem2.Item_Attribute__c = null;
        ospItem2.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem2;
        
        
                 
        List<Component__c> complist = new List<Component__c>();
        
        fuel.itemList[4].Source__c = 'Manufactured';
        update  fuel.itemList[4];
        
        Component__c nonOSPcomp1 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[4].Id,
            Component_Item__r = fuel.itemList[4],
            Component_Sequence__c = 1,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[2].Id
         );  
         insert nonOSPcomp1;
         
         
         Component__c comp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 2,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         );  
         
         //insert comp2;
         complist.add(comp2);
         
         Component__c clonedComp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 3,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         ); 
         //insert clonedComp2;
        
        complist.add(clonedComp2);
        
        
        Component__c ospCompClone = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem2.Id,
            Component_Item__r = ospItem2,
            Component_Sequence__c = 5,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[1].Id
         ); 
         
        //insert ospCompClone;
        
        complist.add(ospCompClone);
        
        insert complist;
        
        //Inserting PO manually..
        
        
        Purchase_Order__c porder = new Purchase_Order__c();
        porder.Supplier__c = fuel.supplier.id;
        porder.Company__c = fuel.company.id;
    	porder.Payment_Term__c = fuel.terms.id;
    	porder.Delivery_Facility__c = fuel.facility2.id;
    	porder.Delivery_Location__c = fuel.location2.ID;
    	porder.Remit_To_Supplier__c = fuel.remitToSupplier.id;
    	porder.Approval_Status__c = 'Approved';
    	porder.Status__c = 'Open';
    	porder.Memo__c = 'purchaseOrder1';
    	porder.Currency__c = fuel.currencyUSD.id;
    	insert porder;
    	
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = porder.Id;
        poLine.Order_Quantity__c = 10;     
        poLine.Unit_Price__c = 12;
        poLine.Item__c = ospItem2.Id;
        poLine.Description__c = ospItem2.Description__c;
        poLine.Purchase_UOM__c = ospItem2.Purchasing_UOM__c;
        poLine.Company__c = fuel.company.id;
        poLine.Need_Date__c = system.today() + 7;
        poLine.Delivery_Facility__c = fuel.facility2.id;
        poLine.Delivery_Location__c = fuel.location2.ID;
        poLine.Supplier__c = fuel.supplier.Id;
        poLine.Line__c = 1;
        insert poLine;
        
        Work_Order__c subworkOrder = new Work_Order__c(
		
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Assembly_Item_Specification__c = itemspec1.Id,
	        Item__c = itemspec1.Item__c,
	        Need_Date2__c = System.today() + 30,
	        Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
	        Order_Quantity__c = 5,
	        Status__c = 'Draft',
	        Type__c = 'Regular',
	        Complete_To_Location__c = fuel.location6.Id,
	        MRB_Location__c = fuel.location2.Id,
	        Default_WIP_Location__c = fuel.location7.Id,
	        Notes__c = 'subworkorder',
	        Currency__c = fuel.currencyUSD.ID,
	        Packaging_UOM__c = fuel.uomList[8].Id
	    );
	    insert subworkOrder;
	    
	    Id itemspecId = itemspec1.Id;
	    List<Component__c> phantomcomplist = new List<Component__c>();
    	SOQLUtil soql = new SOQLUtil('Component__c');
	    soql.addFields(new Set<String>{'Id'});
	    soql.setWhereClause('Assembly_Item_Specification__c != :itemspecId');
	    
    	phantomcomplist = Database.query(soql.getQuery());
    	
    	delete phantomcomplist;
    	
		JSONResult result = new JSONResult();
		JSONResult resultPOs = new JSONResult();
		JSONResult resultRelease = new JSONResult();
        
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        
        result = WorkOrderReleaseExt.getRecords(subworkOrder.Id);
        
        resultPOs = WorkOrderReleaseExt.getPOList(fuel.supplier.Id);
        
        List<WorkOrderReleaseExt.worderWrapper> worderwrappers = new List<WorkOrderReleaseExt.worderWrapper>();
        
        worderwrappers = (List<WorkOrderReleaseExt.worderWrapper>)result.records;
        
        for(WorkOrderReleaseExt.worderWrapper wrap:worderwrappers){
			SObject obj = wrap.rec;
			Id itemId = (Id)obj.get('Item__c');
			Id supplierId = (Id)obj.get('Supplier__c');
		    
		    if(itemId == ospItem2.Id){
		        wrap.inputMap.put('Routing__c',routings[1]);
		        wrap.poRec = porder;//Associating existing PO
		    }
		    else if(itemId == ospItem.Id){
		        wrap.inputMap.put('Routing__c',routings[0]);
		    }
		    if(itemId == ospItem.Id && supplierId == supplier2.Id){
		    	obj.put('Quantity_Required__c',3);
		    }
		    else if(itemId == ospItem.Id && supplierId == fuel.supplier.Id){
		    	obj.put('Quantity_Required__c',2);
		    }
		}
		delete configList;
        Test.startTest();
        resultRelease = WorkOrderReleaseExt.release(worderwrappers,new List<String>{},subworkOrder,false);
        system.assert(resultRelease.success ==true,resultRelease);
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
		
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: ' + WorkOrderService.WO_STATUS_RELEASED + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 4,'Expected materials: 4 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        Set<Id> subcontractOpIds = new Set<Id>();
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id) {
                subcontractOpIds.add(m.Operation_Tracking__c);
            }
            else if(m.Item__c == ospItem2.Id){
            	subcontractOpIds.add(m.Operation_Tracking__c);
            }
        }
        System.assert(subcontractOpIds.size()>0,'Subcontract operation Id is null');
        
        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
        polQuery.setWhereClause('Operation_Tracking__c IN :subcontractOpIds');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());

        System.assert(poLines.size() == 3,'Expected PO lines: 4 // PO lines: ' + poLines.size());
		Purchase_Order__c po;
		Purchase_Order__c po1;
		Purchase_Order__c po2;
		Set<Id> polineIds = new Set<Id>();
		Set<Id> poIds = new Set<Id>();
		Map<Id,Set<Id>> polinemap = new Map<Id,Set<Id>>();
		
        for(Purchase_Order_Line__c pol:poLines){
        	polineIds.add(pol.Id);
        	poIds.add(pol.Purchase_Order__c);
        	
        	if(!polinemap.containskey(pol.Purchase_Order__c))
        		polinemap.put(pol.Purchase_Order__c,new Set<Id>{pol.Id});
        	else
        		polinemap.get(pol.Purchase_Order__c).add(pol.Id);
        		
        	System.assert(pol.Item_Specification__c == wo.Assembly_Item_Specification__c,'Expected POL spec: ' + wo.Assembly_Item_Specification__c + ' // POL spec: ' + pol.Item_Specification__c);
        	if(pol.Supplier__c == supplier2.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == supplier2.Id,'Expected PO supplier: ' + supplier2.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 3,'Expected POL quantity: 8' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == fuel.supplier.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == fuel.supplier.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 2,'Expected POL quantity: 10' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po1 = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == supplier2.Id && pol.Item__c == ospItem2.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == supplier2.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 5,'Expected POL quantity: 4' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po2 = pol.Purchase_Order__r;
        		System.assert(po2.Open_Purchase_Order_Lines__c ==2,po2);
        	}
        	
        	system.assert(pol.Material_Tracking__c !=null);
        	system.assert(pol.Status__c =='Open');
        	
	        System.assert(pol.Purchase_Order__r.Delivery_Facility__c == wo.Facility__c,'Expected PO delivery facility: ' + wo.Facility__c + ' // PO delivery facility: ' + pol.Purchase_Order__r.Delivery_Facility__c);
	        System.assert(pol.Purchase_Order__r.Delivery_Location__c == fuel.location2.Id,'Expected PO delivery location: ' + fuel.location2.Id + ' // PO delivery location: ' + pol.Purchase_Order__r.Delivery_Location__c);
        	
        	
        }
        
        system.assert(poIds.size() == 3,poIds.size());//SAVE --3 PO's should be created one for each routing/supplier.
        
        
       Test.stopTest();
    
    }
    
    
    private static testMethod void testSpiltSubcontractWOonRelease_Errors(){
    	
    	
    	DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Operation_Transaction__c.sObjectType,Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,Work_Center__c.sObjectType,
        	                                  Work_Center_Resource__c.sObjectType,Company__c.sObjectType,Component__c.sObjectType,
        	                                  Item_Specification__c.sObjectType,Operation_Tracking__c.sObjectType,Material_Tracking__c.sObjectType,
        	                                  Supplier__c.sObjectType,Routing__c.sObjectType,Item_Attribute__c.sObjectType,Work_Order__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        
        FOB_Terms__c fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
        insert fobTerm;
        
    	Supplier__c supplier2 = new Supplier__c(); 
        supplier2.Name = fuel.company.Name + ' Supplier-2';
        supplier2.Company__c = fuel.company.ID;
        supplier2.Tax_ID__c = 'tax ID 2';
        supplier2.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
        supplier2.Status__c = 'Active';
        supplier2.FOB_Term__c = fobTerm.id;
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
        supplier2.Remit_To__c =  fuel.remittosupplier.id;
        supplier2.Default_Receiving_Tolerance__c = 3;
        supplier2.Create_RTV_Credit_Memo__c = true;
        supplier2.Create_RTV_PO__c = true; 
        supplier2.Alternate_Name__c = 'Test Supplier 2';
        insert supplier2;
        
        Item_Specification__c itemspec1 = new Item_Specification__c(
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Item__c = fuel.itemList[5].Id,
	        Revision__c = 'R1',
            Start_Date2__c = System.now().addDays(-2),
	        Costing__c = true,
	        Production__c = true,
	        Copy_Phantom_Routings__c = false
        );
        insert itemSpec1;
        
        List<Routing__c> routings = new List<Routing__c>();
        for (Integer i=0;i<3;i++) {
            routings.add(new Routing__c(
                Assembly_Item_Specification__c = itemspec1.Id,
                Company__c = fuel.company.Id,
                Facility__c = fuel.facility2.Id,
                Operation_Sequence__c = 1,
                Work_Center_Resource__c = fuel.wcResources[i].Id,
                Work_Center__c = fuel.wcResources[i].Work_Center__c,
                Resource_Sequence__c = i + 1,
                Resource_Quantity__c = 1,
                Standard_Hours__c = 1,
                Fixed_Hours__c = false,
                Backflush_Resource__c = false
            ));
        }
        insert routings;   
        
    	fuel.components[0].Supplier__c = fuel.supplier.Id;
    	
    	update fuel.components[0];
    	Item__c ospItem = fuel.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = false;
        ospItem.Item_Attribute__c = null;
        ospItem.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem;
        
        fuel.components[1].Supplier__c = fuel.supplier.Id;
        fuel.components[1].Routing__c = fuel.routings[1].Id;
    	update fuel.components[1];
    	
        Item__c ospItem2 = fuel.itemList[0].clone(true,true);
        ospItem2.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem2.Non_Inventory__c = false;
        ospItem2.Item_Attribute__c = null;
        ospItem2.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem2;
        
        
                 
        List<Component__c> complist = new List<Component__c>();
        
        Component__c nonOSPcomp1 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[4].Id,
            Component_Item__r = fuel.itemList[4],
            Component_Sequence__c = 1,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[2].Id
         );  
         insert nonOSPcomp1;
         
         
         Component__c comp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 2,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         );  
         
         //insert comp2;
         complist.add(comp2);
         
         Component__c clonedComp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 3,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         ); 
         //insert clonedComp2;
        
        complist.add(clonedComp2);
        

        insert complist;
        
        
        Item_Attribute__c itemAttributes = new Item_Attribute__c(Expiration_Date__c = false, Lot_Number__c = false, Serial_Number__c = true);
        insert itemAttributes;
        
        delete configList;
        Test.starttest();
        fuel.itemList[4].Item_Attribute__c = itemAttributes.Id;
        update  fuel.itemList[4];
        
        Work_Order__c subworkOrder = new Work_Order__c(
		
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Assembly_Item_Specification__c = itemspec1.Id,
	        Item__c = itemspec1.Item__c,
	        Need_Date2__c = System.today() + 30,
	        Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
	        Order_Quantity__c = 25,
	        Status__c = 'Draft',
	        Type__c = 'Regular',
	        Complete_To_Location__c = fuel.location6.Id,
	        MRB_Location__c = fuel.location2.Id,
	        Default_WIP_Location__c = fuel.location7.Id,
	        Notes__c = 'subworkorder',
	        Currency__c = fuel.currencyUSD.ID
	    );
	    insert subworkOrder;
        
        
        try{
        	clonedComp2.Supplier__c = supplier2.Id;
        	update clonedComp2;
        	System.assert(false,'You can’t choose same supplier on a outside processing component associated to same routing/operation.');
        }catch (Exception e) {
            System.assert(true);
        } 
        
        clonedComp2.Supplier__c = fuel.supplier.Id;
        update clonedComp2;
        
        
        Test.stopTest();
    }
    
    private static testMethod void testSpiltSubcontractWOonRelease_OverQty_Errors(){
    	
    	DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Operation_Transaction__c.sObjectType,Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,Work_Center__c.sObjectType,
        	                                  Work_Center_Resource__c.sObjectType,Company__c.sObjectType,Component__c.sObjectType,
        	                                  Item_Specification__c.sObjectType,Operation_Tracking__c.sObjectType,Material_Tracking__c.sObjectType,
        	                                  Supplier__c.sObjectType,Routing__c.sObjectType,Item_Attribute__c.sObjectType,Work_Order__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        
        FOB_Terms__c fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
        insert fobTerm;
        
    	Supplier__c supplier2 = new Supplier__c(); 
        supplier2.Name = fuel.company.Name + ' Supplier-2';
        supplier2.Company__c = fuel.company.ID;
        supplier2.Tax_ID__c = 'tax ID 2';
        supplier2.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
        supplier2.Status__c = 'Active';
        supplier2.FOB_Term__c = fobTerm.id;
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
        supplier2.Remit_To__c =  fuel.remittosupplier.id;
        supplier2.Default_Receiving_Tolerance__c = 3;
        supplier2.Create_RTV_Credit_Memo__c = true;
        supplier2.Create_RTV_PO__c = true; 
        supplier2.Alternate_Name__c = 'Test Supplier 2';
        insert supplier2;
        
        Item_Specification__c itemspec1 = new Item_Specification__c(
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Item__c = fuel.itemList[5].Id,
	        Revision__c = 'R1',
            Start_Date2__c = System.now().addDays(-2),
	        Costing__c = true,
	        Production__c = true,
	        Copy_Phantom_Routings__c = false
        );
        insert itemSpec1;
        
        List<Routing__c> routings = new List<Routing__c>();
        for (Integer i=0;i<3;i++) {
            routings.add(new Routing__c(
                Assembly_Item_Specification__c = itemspec1.Id,
                Company__c = fuel.company.Id,
                Facility__c = fuel.facility2.Id,
                Operation_Sequence__c = 1,
                Work_Center_Resource__c = fuel.wcResources[i].Id,
                Work_Center__c = fuel.wcResources[i].Work_Center__c,
                Resource_Sequence__c = i + 1,
                Resource_Quantity__c = 1,
                Standard_Hours__c = 1,
                Fixed_Hours__c = false,
                Backflush_Resource__c = false
            ));
        }
        insert routings;   
        
    	fuel.components[0].Supplier__c = fuel.supplier.Id;
    	
    	update fuel.components[0];
    	Item__c ospItem = fuel.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = false;
        ospItem.Item_Attribute__c = null;
        ospItem.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem;
        
        fuel.components[1].Supplier__c = fuel.supplier.Id;
        fuel.components[1].Routing__c = fuel.routings[1].Id;
    	update fuel.components[1];
    	
        Item__c ospItem2 = fuel.itemList[0].clone(true,true);
        ospItem2.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem2.Non_Inventory__c = false;
        ospItem2.Item_Attribute__c = null;
        ospItem2.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem2;
        
        
                 
        List<Component__c> complist = new List<Component__c>();
        
        Component__c nonOSPcomp1 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[4].Id,
            Component_Item__r = fuel.itemList[4],
            Component_Sequence__c = 1,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[2].Id
         );  
         insert nonOSPcomp1;
         
         
         Component__c comp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 2,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         );  
         
         //insert comp2;
         complist.add(comp2);
         
         Component__c clonedComp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 3,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = fuel.supplier.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         ); 
         //insert clonedComp2;
        
        complist.add(clonedComp2);
        

        insert complist;
        
        
        Item_Attribute__c itemAttributes = new Item_Attribute__c(Expiration_Date__c = false, Lot_Number__c = false, Serial_Number__c = true);
        insert itemAttributes;
        
        
        fuel.itemList[4].Item_Attribute__c = itemAttributes.Id;
        update  fuel.itemList[4];
        
        Work_Order__c subworkOrder = new Work_Order__c(
		
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Assembly_Item_Specification__c = itemspec1.Id,
	        Item__c = itemspec1.Item__c,
	        Need_Date2__c = System.today() + 30,
	        Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
	        Order_Quantity__c = 25,
	        Status__c = 'Draft',
	        Type__c = 'Regular',
	        Complete_To_Location__c = fuel.location6.Id,
	        MRB_Location__c = fuel.location2.Id,
	        Default_WIP_Location__c = fuel.location7.Id,
	        Notes__c = 'subworkorder',
	        Currency__c = fuel.currencyUSD.ID
	    );
	    insert subworkOrder;
        delete configList;
        try{
        	clonedComp2.Supplier__c = supplier2.Id;
        	update clonedComp2;
        	System.assert(false,'You can’t choose same supplier on a outside processing component associated to same routing/operation.');
        }catch (Exception e) {
            System.assert(true);
        } 
        
        clonedComp2.Supplier__c = fuel.supplier.Id;
        update clonedComp2;
        
        Test.starttest();
		
		JSONResult result = new JSONResult();
        
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        
        result = WorkOrderReleaseExt.getRecords(subworkOrder.Id);
        
        List<WorkOrderReleaseExt.worderWrapper> worderwrappers = new List<WorkOrderReleaseExt.worderWrapper>();
        
        worderwrappers = (List<WorkOrderReleaseExt.worderWrapper>)result.records;
        
        
        for(WorkOrderReleaseExt.worderWrapper wrap:worderwrappers){
			SObject obj = wrap.rec;
			wrap.inputMap.put('Routing__c',routings[0]);
		    if(obj.get('Item__c') == ospItem.Id && obj.get('Supplier__c') == supplier2.Id){
		    	obj.put('Quantity_Required__c',18);
		    }
		    else if(obj.get('Item__c') == ospItem.Id && obj.get('Supplier__c') == fuel.supplier.Id){
		    	obj.put('Quantity_Required__c',15);
		    }
		    
		}
		JSONResult relresult1 = new JSONResult();
		relresult1 = WorkOrderReleaseExt.release(worderwrappers,new List<String>{},subworkOrder,false);
		system.assert(relresult1.success == false,relresult1);
		system.assert(relresult1.messages.size() == 1);
        Test.stopTest();
    }
    
    private static testMethod void testSpiltSubcontractWOon_ReRelease(){
    	
    	DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Operation_Transaction__c.sObjectType,Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,Work_Center__c.sObjectType,
        	                                  Work_Center_Resource__c.sObjectType,Company__c.sObjectType,Component__c.sObjectType,
        	                                  Item_Specification__c.sObjectType,Operation_Tracking__c.sObjectType,Material_Tracking__c.sObjectType,
        	                                  Supplier__c.sObjectType,Routing__c.sObjectType,Item_Attribute__c.sObjectType,Work_Order__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        
        
        FOB_Terms__c fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
        insert fobTerm;
        
    	Supplier__c supplier2 = new Supplier__c(); 
        supplier2.Name = fuel.company.Name + ' Supplier-2';
        supplier2.Company__c = fuel.company.ID;
        supplier2.Tax_ID__c = 'tax ID 2';
        supplier2.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
        supplier2.Status__c = 'Active';
        supplier2.FOB_Term__c = fobTerm.id;
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
        supplier2.Remit_To__c =  fuel.remittosupplier.id;
        supplier2.Default_Receiving_Tolerance__c = 3;
        supplier2.Create_RTV_Credit_Memo__c = true;
        supplier2.Create_RTV_PO__c = true; 
        supplier2.Alternate_Name__c = 'Test Supplier 2';
        insert supplier2;
        
        Item_Specification__c itemspec1 = new Item_Specification__c(
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Item__c = fuel.itemList[5].Id,
	        Revision__c = 'R1',
            Start_Date2__c = System.now().addDays(-2),
	        Costing__c = true,
	        Production__c = true,
	        Copy_Phantom_Routings__c = false
        );
        insert itemSpec1;
        
        List<Routing__c> routings = new List<Routing__c>();
        for (Integer i=0;i<2;i++) {
            routings.add(new Routing__c(
                Assembly_Item_Specification__c = itemspec1.Id,
                Company__c = fuel.company.Id,
                Facility__c = fuel.facility2.Id,
                Operation_Sequence__c = 1,
                Work_Center_Resource__c = fuel.wcResources[i].Id,
                Work_Center__c = fuel.wcResources[i].Work_Center__c,
                Resource_Sequence__c = i + 1,
                Resource_Quantity__c = 1,
                Standard_Hours__c = 1,
                Fixed_Hours__c = false,
                Backflush_Resource__c = false
            ));
        }
        insert routings;   
        
    	fuel.components[0].Supplier__c = fuel.supplier.Id;
    	
    	update fuel.components[0];
    	Item__c ospItem = fuel.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = false;
        ospItem.Item_Attribute__c = null;
        ospItem.Purchasing_UOM__c = fuel.uomList[8].Id;
        update ospItem;
        
        fuel.components[1].Supplier__c = fuel.supplier.Id;
        fuel.components[1].Routing__c = fuel.routings[1].Id;
    	update fuel.components[1];
    	
                 
        List<Component__c> complist = new List<Component__c>();
        
        Item_Attribute__c itemAttributes = new Item_Attribute__c(Expiration_Date__c = false, Lot_Number__c = false, Serial_Number__c = true);
        insert itemAttributes;
        
        
        fuel.itemList[4].Item_Attribute__c = itemAttributes.Id;
        fuel.itemList[4].Source__c = 'Manufactured';
        update  fuel.itemList[4];
        
        Component__c nonOSPcomp1 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[4].Id,
            Component_Item__r = fuel.itemList[4],
            Component_Sequence__c = 1,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[1].Id
         );  
         insert nonOSPcomp1;
         
         
         Component__c comp2 = new Component__c(
            Assembly_Item_Specification__c = itemspec1.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = ospItem.Id,
            Component_Item__r = ospItem,
            Component_Sequence__c = 2,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Supplier__c = supplier2.Id,
            Type__c = ComponentService.TYPE_BACKFLUSH,
            Routing__c = routings[0].Id
         );  
         
        //insert comp2;
        complist.add(comp2);
         
        insert complist;
        
        String itemspecId = itemspec1.Id;
        
        Work_Order__c subworkOrder = new Work_Order__c(
		
	        Company__c = fuel.company.Id,
	        Facility__c = fuel.facility2.Id,
	        Assembly_Item_Specification__c = itemspec1.Id,
	        Item__c = itemspec1.Item__c,
	        Need_Date2__c = System.today() + 30,
	        Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
	        Order_Quantity__c = 25,
	        Status__c = 'Draft',
	        Type__c = 'Regular',
	        Complete_To_Location__c = fuel.location6.Id,
	        MRB_Location__c = fuel.location2.Id,
	        Default_WIP_Location__c = fuel.location7.Id,
	        Notes__c = 'subworkorder',
	        Currency__c = fuel.currencyUSD.ID,
	        Packaging_UOM__c = fuel.uomList[8].Id
	    );
	    insert subworkOrder;
	    
	    List<Component__c> phantomcomplist = new List<Component__c>();
    	SOQLUtil soql = new SOQLUtil('Component__c');
	    soql.addFields(new Set<String>{'Id'});
	    soql.setWhereClause('Assembly_Item_Specification__c != :itemspecId');
	    
    	phantomcomplist = Database.query(soql.getQuery());
    	
    	delete phantomcomplist;
        
        //Release first time only one OSP
       
        JSONResult resultWO = new JSONResult();
        JSONResult resultWO1 = new JSONResult();
        List<WorkOrderReleaseExt.worderWrapper> woWrappers = new List<WorkOrderReleaseExt.worderWrapper>();
        resultWO = WorkOrderReleaseExt.getRecords(subworkOrder.Id);
        
        woWrappers = (List<WorkOrderReleaseExt.worderWrapper>)resultWO.records;
        
        for(WorkOrderReleaseExt.worderWrapper wrap:woWrappers){
			SObject obj = wrap.rec;
			Id itemId = (Id)obj.get('Item__c');
			Id supplierId = (Id)obj.get('Supplier__c');
		    if(itemId == ospItem.Id){
		        wrap.inputMap.put('Routing__c',routings[0]);
		    }
		}
        WorkOrderReleaseExt ext = new WorkOrderReleaseExt(new ApexPages.StandardController(subworkOrder));
        
        resultWO1 = WorkOrderReleaseExt.release(woWrappers,new List<String>{},subworkOrder,false);
        system.assert(resultWO1.success ==true,resultWO1);
        
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
		
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: ' + WorkOrderService.WO_STATUS_RELEASED + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 2,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 2,'Expected operations: 2 // Operations: ' + wo.Operation_Trackings__r.size());

        Id subcontractOpId;
        
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id) {
                subcontractOpId = m.Operation_Tracking__c;
            }
            
        }
        System.assert(subcontractOpId != null,'Subcontract operation Id is null');
        
        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
        polQuery.setWhereClause('Operation_Tracking__c  =:subcontractOpId');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());

        System.assert(poLines.size() == 1,'Expected PO lines: 1 // PO lines: ' + poLines.size());
        
        //Insert one OSP Material Tracking
        
        Material_Tracking__c materialtobeadded = new Material_Tracking__c(Item__c = ospItem.Id, Item__r = ospItem, Quantity_Issued__c = 0, Quantity_Per_Assembly__c = 1,
	        								   Type__c = 'Outside Processing', Supplier__c = fuel.supplier.Id, Supplier__r = fuel.supplier, Work_Order__c = wo.Id, Work_Order__r = wo, 
	        								   Operation_Tracking__c = subcontractOpId);
	    
	    insert materialtobeadded;
	    //Rerelease WO
	    wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
	    
	    JSONResult result = new JSONResult();
	    JSONResult resultRelease = new JSONResult();
        
        
        result = WorkOrderReleaseExt.getRecords(wo.Id);
        
       
        List<WorkOrderReleaseExt.worderWrapper> worderwrappers = new List<WorkOrderReleaseExt.worderWrapper>();
        
        worderwrappers = (List<WorkOrderReleaseExt.worderWrapper>)result.records;
        
        
        for(WorkOrderReleaseExt.worderWrapper wrap:worderwrappers){
			SObject obj = wrap.rec;
		    if(obj.get('Item__c') == ospItem.Id && obj.get('Supplier__c') == supplier2.Id){
		    	obj.put('Quantity_Required__c',10);
		    }
		    else if(obj.get('Item__c') == ospItem.Id && obj.get('Supplier__c') == fuel.supplier.Id){
		    	obj.put('Quantity_Required__c',15);
		    }
		 }
		 
	    resultRelease = WorkOrderReleaseExt.release(worderwrappers,new List<String>{},wo,false);
        system.assert(resultRelease.success ==true,resultRelease);
        
         
        SOQLUtil polQuery1 = new SOQLUtil('Purchase_Order_Line__c');
        polQuery1.addAllCustomFields();
        polQuery1.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
        polQuery1.setWhereClause('Operation_Tracking__c  =:subcontractOpId');
        List<Purchase_Order_Line__c> poLines1 = Database.query(polQuery.getQuery());

        System.assert(poLines1.size() == 2,'Expected PO lines: 2 // PO lines: ' + poLines.size());
		Purchase_Order__c po;
		Purchase_Order__c po1;
		Set<Id> polineIds = new Set<Id>();
		Set<Id> poIds = new Set<Id>();
		Map<Id,Set<Id>> polinemap = new Map<Id,Set<Id>>();
		
        for(Purchase_Order_Line__c pol:poLines1){
        	polineIds.add(pol.Id);
        	poIds.add(pol.Purchase_Order__c);
        	
        	if(!polinemap.containskey(pol.Purchase_Order__c))
        		polinemap.put(pol.Purchase_Order__c,new Set<Id>{pol.Id});
        	else
        		polinemap.get(pol.Purchase_Order__c).add(pol.Id);
        		
        	System.assert(pol.Item_Specification__c == wo.Assembly_Item_Specification__c,'Expected POL spec: ' + wo.Assembly_Item_Specification__c + ' // POL spec: ' + pol.Item_Specification__c);
        	if(pol.Supplier__c == supplier2.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == supplier2.Id,'Expected PO supplier: ' + supplier2.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 10,'Expected POL quantity: 8' + ' // POL quantity: ' + pol);
        		po = pol.Purchase_Order__r;
        	}
        	else if(pol.Supplier__c == fuel.supplier.Id && pol.Item__c == ospItem.Id){
        		System.assert(pol.Purchase_Order__r.Supplier__c == fuel.supplier.Id,'Expected PO supplier: ' + fuel.supplier.Id + ' // PO supplier: ' + pol.Purchase_Order__r.Supplier__c);
        		System.assert(pol.Order_Quantity__c == 15,'Expected POL quantity: 10' + ' // POL quantity: ' + pol.Order_Quantity__c);
        		po1 = pol.Purchase_Order__r;
        	}
        	
        	system.assert(pol.Material_Tracking__c !=null);
        	system.assert(pol.Status__c =='Open');
        	
	        System.assert(pol.Purchase_Order__r.Delivery_Facility__c == wo.Facility__c,'Expected PO delivery facility: ' + wo.Facility__c + ' // PO delivery facility: ' + pol.Purchase_Order__r.Delivery_Facility__c);
	        System.assert(pol.Purchase_Order__r.Delivery_Location__c == fuel.location2.Id,'Expected PO delivery location: ' + fuel.location2.Id + ' // PO delivery location: ' + pol.Purchase_Order__r.Delivery_Location__c);
        	
        }
        
        
        system.assert(poIds.size() == 2);//Only two PO's should be created one for each supplier.
        po.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po;
        
        po1.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po1;
       
        //Receive all PO's
        Set<Id> lineIds = new Set<Id>();
        Set<Id> lineIds1 = new Set<Id>();
        lineIds.addAll(polinemap.get(po.Id));
        lineIds1.addAll(polinemap.get(po1.Id));
        Test.startTest();
        List<ReceivingWrapper> rWrappers = getReceivingWrappers(lineIds);
        
        Receiving_Document__c rd = getRD(lineIds);

        for(ReceivingWrapper rw: rWrappers){
	        
	        for( SkidService3.serialWrapper sw : rw.serialWrapperList){
	            SKID__c skid = sw.skid;
	            skid.Expiration_Date__c = system.today() + 5;
	            skid.Lot_Number__c = 'LOT 1' ;
	            if(skid.Item__c == ospItem.Id){
	                skid.Quantity__c = 10;
	            }
	            
	            List<Serial__c> serialList = new List<Serial__c>();
	            for (Integer i=0;i<skid.Quantity__c;i++) {
	                Serial__c ser = new Serial__c(
	                    Name = 'Serial ' + i,
	                    Item__c = skid.Item__c,
	                    Company__c = fuel.company.Id
	                );
	                ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
	                serialList.Add(ser);
	            }
	            sw.serialList = serialList;             
	        }
	    }
		delete configList;
		
		
		
        receive(rWrappers,rd);
        
       
        wo = WorkOrderService.getWorkOrders(new Set<Id>{ subworkOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];
        
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: ' + WorkOrderService.WO_STATUS_IN_PROCESS + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 3,'Expected materials: 3 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 2,'Expected operations: 2 // Operations: ' + wo.Operation_Trackings__r.size());

        
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id && m.Supplier__c == supplier2.Id) {
                system.assert(m.Quantity_Issued__c == 10,wo.Material_Trackings__r);
            }
        }

        Operation_Tracking__c subcontractOperation1;
        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if (op.Routing__c == routings[0].Id) {
                system.assert(op.Quantity_Completed__c == 10);
            }
            
        }
        
       Test.stopTest();
	
    
    }
    
    private static Set<Id> getPOLIds() {
        JsonResult result = ReceivingWorkBenchExt.getLinesToReceive(ReceivingWorkBenchExt.getGridConfig('Purchase Order').get('config'),fuel.workOrder.Facility__c,null,null,null,null,null,null,null,null);
        System.assert(result.success,'ReceivingWorkBenchExt.getLinesToReceive fail: ' + result);
        System.assert(result.records.size() == 1,'Expected PO lines: 1 // PO lines: ' + result.records.size());

        Set<Id> polIds = new Set<Id>();
        for (Purchase_Order_Line__c pol:(List<Purchase_Order_Line__c>)result.records) {
            polIds.add(pol.Id);
        }

        return polIds;
    }

    private static List<ReceivingWrapper> getReceivingWrappers(Set<Id> polIds) {
        JsonResult result = ReceivingWorkBenchExt.getList(new List<Id>(polIds),'Purchase Order');
        System.assert(result.success,'ReceivingWorkBenchExt.getList fail: ' + result);
        
        System.assert(result.records.size() == polIds.size() ,'result.records.size(): '+ result.records.size());

        return (List<ReceivingWrapper>)result.records;
    }

    private static Receiving_Document__c getRD(Set<Id> polIds) {
        JsonResult result = ReceivingWorkBenchExt.getrdDetails(new List<Id>(polIds),'Purchase Order',fuel.workOrder.Currency__c);
        System.assert(result.success,'ReceivingWorkBenchExt.getrdDetails fail: ' + result);
        System.assert(result.records.size() == 1,'Expected RDs: 1 // RDs: ' + result.records.size());

        return (Receiving_Document__c)result.records[0];
    }

    private static void receive(List<ReceivingWrapper> rWrappers,Receiving_Document__c rd) {
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,new List<String>(),new List<String>(),rd,new List<String>());
        System.assert(result.success,'ReceivingWorkBenchExt.receive fail: ' + result);
    }
}