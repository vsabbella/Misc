@isTest
private class ManageItemSpecWorkOrderTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        system.assert( f.supplier != null  );
        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void wrongId() {
        Test.setCurrentPage(Page.ManageItemSpecWorkOrder);
        ApexPages.currentPage().getParameters().put('id','' + fuel.company.Id);
        
        try {
            ManageItemSpecWorkOrderExt ext = new ManageItemSpecWorkOrderExt();
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    private static testMethod void successItemSpec() {
        Test.setCurrentPage(Page.ManageItemSpecWorkOrder);
        ApexPages.currentPage().getParameters().put('id','' + fuel.itemSpec.Id);

        ManageItemSpecWorkOrderExt ext = new ManageItemSpecWorkOrderExt();
        String str = ext.stdOperationFieldListJson;
        str = ext.stdComponentFieldListJson;
        ext.cancel();

        JsonResult result = ManageItemSpecWorkOrderExt.getRecords(fuel.itemSpec.Id,'Item Specification','Operation');
        System.assert(result.records.size() == fuel.routings.size(),result);
        List<Routing__c> routings = (List<Routing__c>)result.records;
        
        Id wcId = routings[0].Work_Center__c;
        Id wcrId = routings[0].Work_Center_Resource__c;

        ManageItemSpecWorkOrderExt.deleteRecords(routings);
        routings.clear();

        result = ManageItemSpecWorkOrderExt.addRecord(fuel.itemSpec,'Item Specification','Operation');
        System.assert(result.records.size() == 1,result);
        Routing__c routing = (Routing__c)result.records[0];
        routing.Resource_Sequence__c = 10;
        routing.Work_Center__c = wcId;
        routing.Work_Center_Resource__c = wcrId;
        routing.Resource_Quantity__c = 1;
        routing.Standard_Hours__c = 1;
        routings.add(routing);

        result = ManageItemSpecWorkOrderExt.getRecords(fuel.itemSpec.Id,'Item Specification','Component');
        System.assert(result.records.size() == fuel.components.size(),result);
        List<Component__c> components = (List<Component__c>)result.records;

        result = ManageItemSpecWorkOrderExt.addRecord(fuel.itemSpec,'Item Specification','Component');
        System.assert(result.records.size() == 1,result);
        Component__c component = (Component__c)result.records[0];
        component.Quantity_Per_Assembly__c = 1;
        component.Component_Item__c = fuel.itemList[1].Id;
        component.Type__c = 'Backflush';
        components.add(component);
        for (Component__c component2:components) {
            component2.Component_Item__r = null;
        }

        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.itemSpec.Id,'Item Specification','Operation',routings,new List<String>());
        System.assert(result.success,result);

        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.itemSpec.Id,'Item Specification','Component',components,new List<String>());
        System.assert(result.success,result);

        routings = [SELECT Id FROM Routing__c WHERE Assembly_Item_Specification__c = :fuel.itemSpec.Id];
        components = [SELECT Id FROM Component__c WHERE Assembly_Item_Specification__c = :fuel.itemSpec.Id];
        System.assert(routings.size() == 1,routings);
        System.assert(components.size() == fuel.components.size() + 1,components);
    }
    
    //adding by-product component into item spec.
    
    private static testMethod void successItemSpecwithByProduct() {
        Test.setCurrentPage(Page.ManageItemSpecWorkOrder);
        ApexPages.currentPage().getParameters().put('id','' + fuel.itemSpec.Id);

        ManageItemSpecWorkOrderExt ext = new ManageItemSpecWorkOrderExt();
        String str = ext.stdOperationFieldListJson;
        str = ext.stdComponentFieldListJson;
        ext.cancel();

        JsonResult result = ManageItemSpecWorkOrderExt.getRecords(fuel.itemSpec.Id,'Item Specification','Component');
        System.assert(result.records.size() == fuel.components.size(),result);
        List<Component__c> components = (List<Component__c>)result.records;

        result = ManageItemSpecWorkOrderExt.addRecord(fuel.itemSpec,'Item Specification','Component');
        System.assert(result.records.size() == 1,result);
        Component__c component = (Component__c)result.records[0];
        component.Quantity_Per_Assembly__c = 1;
        component.Component_Item__c = fuel.itemList[1].Id;
        component.Type__c = 'By-product';
        components.add(component);
        for (Component__c component2:components) {
            component2.Component_Item__r = null;
        }

        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.itemSpec.Id,'Item Specification','Component',components,new List<String>());
        System.assert(result.success,result);

        components = [SELECT Id FROM Component__c WHERE Assembly_Item_Specification__c = :fuel.itemSpec.Id];
        
        System.assert(components.size() == fuel.components.size() + 1,components);
    }
    
    
    private static testMethod void successWorkOrder() {
        Test.setCurrentPage(Page.ManageItemSpecWorkOrder);
        ApexPages.currentPage().getParameters().put('id','' + fuel.workOrder.Id);

        ManageItemSpecWorkOrderExt ext = new ManageItemSpecWorkOrderExt();

        JsonResult result = ManageItemSpecWorkOrderExt.getRecords(fuel.workOrder.Id,'Work Order','Operation');
        System.assert(result.records.size() == fuel.routings.size(),result);
        List<Operation_Tracking__c> ops = (List<Operation_Tracking__c>)result.records;
        
        Id wcId = ops[0].Work_Center__c;
        Id wcrId = ops[0].Work_Center_Resource__c;

        result = ManageItemSpecWorkOrderExt.addRecord(fuel.workOrder,'Work Order','Operation');
        System.assert(result.records.size() == 1,result);
        Operation_Tracking__c op = (Operation_Tracking__c)result.records[0];
        op.Sequence__c = 10;
        op.Work_Center__c = wcId;
        op.Work_Center_Resource__c = wcrId;
        op.Resource_Quantity__c = 1;
        op.Standard_Hours__c = 1;
        ops.add(op);

        result = ManageItemSpecWorkOrderExt.getRecords(fuel.workOrder.Id,'Work Order','Component');
        System.assert(result.records.size() == fuel.components.size(),result);
        List<Material_Tracking__c> mts = (List<Material_Tracking__c>)result.records;

        result = ManageItemSpecWorkOrderExt.addRecord(fuel.workOrder,'Work Order','Component');
        System.assert(result.records.size() == 1,result);
        Material_Tracking__c mt = (Material_Tracking__c)result.records[0];
        mt.Quantity_Required__c = 10;
        mt.Item__c = fuel.itemList[1].Id;
        mt.Type__c = 'Backflush';
        mts.add(mt);

        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.workOrder.Id,'Work Order','Operation',ops,new List<String>());
        System.assert(result.success,result);

        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.workOrder.Id,'Work Order','Component',mts,new List<String>());
        System.assert(result.success,result);

        ops = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id];
        mts = [SELECT Id FROM Material_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id];
        System.assert(ops.size() == fuel.routings.size() + 1,ops);
        System.assert(mts.size() == fuel.components.size() + 1,mts);
    }

    private static testMethod void successTemplate() {
        Id wcId = fuel.routings[0].Work_Center__c;
        Id wcrId = fuel.routings[0].Work_Center_Resource__c;

        Item_Specification__c templateItemSpec = new Item_Specification__c(
            Name = 'TEMPLATE',
            Company__c = fuel.company.Id,
            Facility__c = fuel.facility2.Id,
            Start_Date2__c = System.now(),
            Revision__c = 'R1',
            Type__c = 'Template',
            Production__c = false,
            Costing__c = false
        );
        insert templateItemSpec;

        insert new Component__c(
            Assembly_Item_Specification__c = templateItemSpec.Id,
            Quantity_Per_Assembly__c = 1,
            Component_Item__c = fuel.itemList[1].Id,
            Company__c = fuel.company.Id,
            Yield__c = 100.00,
            Type__c = 'Backflush'
        );

        insert new Routing__c(
            Assembly_Item_Specification__c = templateItemSpec.Id,
            Company__c = fuel.company.Id,
            Facility__c = fuel.facility2.Id,
            Work_Center_Resource__c = wcrId,
            Work_Center__c = wcId,
            Resource_Sequence__c = 10,
            Resource_Quantity__c = 2,
            Standard_Hours__c = 1,
            Fixed_Hours__c = false,
            Backflush_Resource__c = false
        );

        Test.setCurrentPage(Page.ManageItemSpecWorkOrder);
        ApexPages.currentPage().getParameters().put('id','' + fuel.itemSpec.Id);

        ManageItemSpecWorkOrderExt ext = new ManageItemSpecWorkOrderExt();

        JsonResult result = ManageItemSpecWorkOrderExt.getStdRecords('Operation',templateItemSpec.Id,fuel.itemSpec);
        System.assert(result.records.size() == 1);

        result = ManageItemSpecWorkOrderExt.getStdRecords('Component',templateItemSpec.Id,fuel.itemSpec);
        System.assert(result.records.size() == 1);
    }
    
    
    // Test case : Adding new op(s) as 1st op
    // Test case : Adding new op in the middle
    // Test case : Adding new op as last op
    
    // Test case : Deleting 1st op
    // Test case : Deleting last op
    // Test case : Deleting ops from middle
    private static testMethod void testManageOperations ( ) {
        Test.setCurrentPage(Page.ManageItemSpecWorkOrder);
        ApexPages.currentPage().getParameters().put('id','' + fuel.workOrder.Id);
        
        ManageItemSpecWorkOrderExt ext = new ManageItemSpecWorkOrderExt();

        JsonResult result = ManageItemSpecWorkOrderExt.getRecords(fuel.workOrder.Id,'Work Order','Operation');
        System.assert(result.records.size() == fuel.routings.size(),result);
        List<Operation_Tracking__c> ops = (List<Operation_Tracking__c>)result.records;
        
        Integer seq = 10;
        
        for ( Operation_Tracking__c op : ops ) {
            op.Sequence__c = seq;
            
            seq += 5;
        }
        
        Id wcId = ops[0].Work_Center__c;
        Id wcrId = ops[0].Work_Center_Resource__c;

        result = ManageItemSpecWorkOrderExt.addRecord(fuel.workOrder,'Work Order','Operation');
        System.assert(result.records.size() == 1,result);
        
        List<Operation_Tracking__c> newOps = new List<Operation_Tracking__c>( );
        
        // Add Operations
        Operation_Tracking__c op0 = (Operation_Tracking__c)result.records[0];
        op0.Sequence__c = 0;
        op0.Description__c = 'Test0';
        op0.Work_Center__c = wcId;
        op0.Work_Center_Resource__c = wcrId;
        op0.Resource_Quantity__c = 1;
        op0.Standard_Hours__c = 1;
        newOps.add(op0);
        
        Operation_Tracking__c op1 = new Operation_Tracking__c(
                    Hours_Consumed__c = 0,
                    Quantity_Available__c = 0,
                    Quantity_Completed__c = 0,
                    Quantity_Scrapped__c = 0, 
                    Work_Order__c = fuel.workOrder.Id
                );
        op1.Sequence__c = 7;
        op1.Description__c = 'Test1';
        op1.Work_Center__c = wcId;
        op1.Work_Center_Resource__c = wcrId;
        op1.Resource_Quantity__c = 1;
        op1.Standard_Hours__c = 1;
        newOps.add(op1);
        
        Operation_Tracking__c op2 = new Operation_Tracking__c(
                    Hours_Consumed__c = 0,
                    Quantity_Available__c = 0,
                    Quantity_Completed__c = 0,
                    Quantity_Scrapped__c = 0, 
                    Work_Order__c = fuel.workOrder.Id
                );
        op2.Sequence__c = 11;
        op2.Description__c = 'Test2';
        op2.Work_Center__c = wcId;
        op2.Work_Center_Resource__c = wcrId;
        op2.Resource_Quantity__c = 1;
        op2.Standard_Hours__c = 1;
        newOps.add(op2);
        
        Operation_Tracking__c op3 = new Operation_Tracking__c(
                    Hours_Consumed__c = 0,
                    Quantity_Available__c = 0,
                    Quantity_Completed__c = 0,
                    Quantity_Scrapped__c = 0, 
                    Work_Order__c = fuel.workOrder.Id
                );
        op3.Description__c = 'Test3';
        op3.Sequence__c = 12;
        op3.Work_Center__c = wcId;
        op3.Work_Center_Resource__c = wcrId;
        op3.Resource_Quantity__c = 1;
        op3.Standard_Hours__c = 1;
        newOps.add(op3);
        
        Operation_Tracking__c op4 = new Operation_Tracking__c(
                    Hours_Consumed__c = 0,
                    Quantity_Available__c = 0,
                    Quantity_Completed__c = 0,
                    Quantity_Scrapped__c = 0, 
                    Work_Order__c = fuel.workOrder.Id
                );
        op4.Sequence__c = 29;
        op4.Description__c = 'Test4';
        op4.Work_Center__c = wcId;
        op4.Work_Center_Resource__c = wcrId;
        op4.Resource_Quantity__c = 1;
        op4.Standard_Hours__c = 1;
        newOps.add(op4);
        
        Operation_Tracking__c op5 = new Operation_Tracking__c(
                    Hours_Consumed__c = 0,
                    Quantity_Available__c = 0,
                    Quantity_Completed__c = 0,
                    Quantity_Scrapped__c = 0, 
                    Work_Order__c = fuel.workOrder.Id
                );
        op5.Sequence__c = 31;
        op5.Description__c = 'Test5';
        op5.Work_Center__c = wcId;
        op5.Work_Center_Resource__c = wcrId;
        op5.Resource_Quantity__c = 1;
        op5.Standard_Hours__c = 1;
        newOps.add(op5);
        
        ops.addAll(newOps);
        
        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.workOrder.Id,'Work Order','Operation',ops,new List<String>());
        System.assert(result.success,fuel.routings.size() + '-' +result);
        
        result = ManageItemSpecWorkOrderExt.getRecords(fuel.workOrder.Id,'Work Order','Operation');
        System.assert(result.records.size() == fuel.routings.size() + newOps.size(),result);
        ops = (List<Operation_Tracking__c>)result.records;
        // Delete records 
        List<Operation_Tracking__c> opsToDelete = new List<Operation_Tracking__c> ();
        
        
        for ( Operation_Tracking__c op : ops ) {
            
            if ( op.Sequence__c == 0 || op.Sequence__c == 11 || op.Sequence__c == 31 ) {
                opsToDelete.add(op);        
            }
            
            if ( op.Sequence__c == 0 ) {
                system.assert( op.Quantity_Available__c == fuel.workOrder.Order_Quantity__c);    
            } else {
                system.assert( op.Quantity_Available__c == 0);
            }
        }       
        
        ManageItemSpecWorkOrderExt.deleteRecords(opsToDelete);
        
        result = ManageItemSpecWorkOrderExt.getRecords(fuel.workOrder.Id,'Work Order','Operation');
        System.assert(result.records.size() == fuel.routings.size() + newOps.size() - opsToDelete.size(),result);
        ops = (List<Operation_Tracking__c>)result.records;
        
        system.assert( ops[0].Quantity_Available__c == fuel.workOrder.Order_Quantity__c);
        
        fuel.itemList[1].Source__c = 'Outside Processing';
        update fuel.itemList[1];
        
        ops = (List<Operation_Tracking__c>)result.records;
        
        // test case : can't delete op if new last op has op components
        result = ManageItemSpecWorkOrderExt.addRecord(fuel.workOrder,'Work Order','Component');
        System.assert(result.records.size() == 1,result);
        Material_Tracking__c mt = (Material_Tracking__c)result.records[0];
        mt.Quantity_Per_Assembly__c = 1;
        mt.Item__c = fuel.itemList[1].Id;
        mt.Type__c = 'Backflush';
        mt.Supplier__c = fuel.supplier.Id;
        mt.Operation_Tracking__c = ops[ops.size()-2].Id; // adding outside processing component to second last op
        insert mt;
        
        result = ManageItemSpecWorkOrderExt.deleteRecords( new List<Operation_Tracking__c> {ops[ops.size()-1]} );
        system.assert ( result.success == false, result );
        
        // test case : can't add outside processing component to last op
        mt.Operation_Tracking__c = ops[ops.size()-1].Id;
        result = ManageItemSpecWorkOrderExt.saveRecords(fuel.workOrder.Id,'Work Order','Component', new List<Material_Tracking__c> {mt}, new List<String>());
        system.assert ( result.success == false, result );
        
        result = ManageItemSpecWorkOrderExt.deleteRecords( ops );
        system.assert ( result.success == false, result );
        
    }
}