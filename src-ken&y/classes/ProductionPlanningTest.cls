@isTest
private class ProductionPlanningTest {
    @testSetup
    private static void setupData() {
        TestFuel fuel = new TestFuel();
        insert new User_Preference__c(
            Default_Company__c = fuel.company.Id,
            Default_Facility__c = fuel.facility2.Id,
            OwnerID = UserInfo.getUserID()
        );
        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});
    }
    
    private static testMethod void testParameters() {
        List<Operation_Tracking__c> ops = [SELECT Id,Work_Order__c,Work_Order__r.Company__c,Work_Order__r.Facility__c,Work_Order__r.Start_Date2__c,Work_Center_Resource__c,Work_Center_Resource__r.Work_Center__c,Work_Center_Resource__r.Resource__c FROM Operation_Tracking__c];
        
        Test.setCurrentPage(Page.ProductionPlanning);
        ApexPages.currentPage().getParameters().put('company',ops[0].Work_Order__r.Company__c);
        ApexPages.currentPage().getParameters().put('facility',ops[0].Work_Order__r.Facility__c);
        ApexPages.currentPage().getParameters().put('workCenter',ops[0].Work_Center_Resource__r.Work_Center__c);
        ApexPages.currentPage().getParameters().put('resource',ops[0].Work_Center_Resource__r.Resource__c);
        ApexPages.currentPage().getParameters().put('workCenterResource',ops[0].Work_Center_Resource__c);
        ApexPages.currentPage().getParameters().put('startDate',String.valueOf(DateTime.newInstance(ops[0].Work_Order__r.Start_Date2__c.date(),Time.newInstance(0,0,0,0))));
        ApexPages.currentPage().getParameters().put('days','30');
        
        ProductionPlanningExt ext = new ProductionPlanningExt();
        System.assert(ext.defaultCompany != null,ext);
        System.assert(ext.defaultFacility != null,ext);
        System.assert(ext.defaultWorkCenter != null,ext);
        System.assert(ext.defaultResource != null,ext);
        System.assert(ext.defaultWorkCenterResource != null,ext);
        System.assert(ext.defaultStartDate != null,ext);
        System.assert(ext.defaultDays != null,ext);
        System.assert(ext.calendarFieldsJson != null,ext.calendarFieldsJson);
        System.assert(ext.allFieldsJson != null,ext.allFieldsJson);
        
        JsonResult result = ProductionPlanningExt.getWCRData(ops[0].Work_Order__r.Facility__c,ops[0].Work_Center_Resource__r.Work_Center__c,ops[0].Work_Center_Resource__r.Resource__c,ops[0].Work_Center_Resource__c,'["' + ops[0].Work_Order__c + '"]',null,DateTime.newInstance(ops[0].Work_Order__r.Start_Date2__c.date(),Time.newInstance(0,0,0,0)),30);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);
    }
    
    private static testMethod void testUpdateDates() {
        ProductionPlanningExt ext = new ProductionPlanningExt();
        System.assert(ext.defaultCompany != null,ext);
        System.assert(ext.defaultFacility != null,ext);
        
        Map<Id,Operation_Tracking__c> ops = new Map<Id,Operation_Tracking__c>([SELECT Id,Start_Date__c,End_Date__c,Work_Order__c,Work_Order__r.Facility__c,Work_Order__r.Start_Date2__c,Work_Order__r.Earliest_Completion_Date2__c FROM Operation_Tracking__c ORDER BY Sequence__c ASC]);
        
        JsonResult result = ProductionPlanningExt.getWCRData(ops.values()[0].Work_Order__r.Facility__c,null,null,null,null,null,DateTime.newInstance(ops.values()[0].Work_Order__r.Start_Date2__c.date(),Time.newInstance(0,0,0,0)),30);
        System.assert(result.success,result);
        System.assert(result.records.size() == 6,result.records);
        
        for (ProductionPlanningExt.DataWrapper wrapper:(List<ProductionPlanningExt.DataWrapper>)result.records) {
            if (wrapper.record.Id == ops.values()[0].Id) {
                wrapper.startDT = wrapper.startDT.addDays(1);
                result = ProductionPlanningExt.updateDates(wrapper);
                System.assert(result.success,result);
                System.assert(result.records.size() == 3,result.records);
                
                result = ProductionPlanningExt.save((List<ProductionPlanningExt.DataWrapper>)result.records);
                System.assert(result.success,result);
                
                break;
            }
        }
        
        for (Operation_Tracking__c op:[SELECT Id,Start_Date__c,End_Date__c,Work_Order__c,Work_Order__r.Start_Date2__c,Work_Order__r.Earliest_Completion_Date2__c FROM Operation_Tracking__c ORDER BY Sequence__c ASC]) {
            Operation_Tracking__c oldOp = ops.get(op.Id);
            System.assert(oldOp != null);
            System.assert(oldOp.Start_Date__c != op.Start_Date__c);
            System.assert(oldOp.End_Date__c != op.End_Date__c);
            System.assert(oldOp.Work_Order__r.Start_Date2__c != op.Work_Order__r.Start_Date2__c);
            System.assert(oldOp.Work_Order__r.Earliest_Completion_Date2__c != op.Work_Order__r.Earliest_Completion_Date2__c);
        }
    }
    
    private static testMethod void testUpdateDatesBackwards() {
        ProductionPlanningExt ext = new ProductionPlanningExt();
        System.assert(ext.defaultCompany != null,ext);
        System.assert(ext.defaultFacility != null,ext);
        
        Map<Id,Operation_Tracking__c> ops = new Map<Id,Operation_Tracking__c>([SELECT Id,Start_Date__c,End_Date__c,Work_Order__c,Work_Order__r.Facility__c,Work_Order__r.Start_Date2__c,Work_Order__r.Earliest_Completion_Date2__c FROM Operation_Tracking__c ORDER BY Sequence__c ASC]);
        
        JsonResult result = ProductionPlanningExt.getWCRData(ops.values()[0].Work_Order__r.Facility__c,null,null,null,null,null,DateTime.newInstance(ops.values()[0].Work_Order__r.Start_Date2__c.date(),Time.newInstance(0,0,0,0)),30);
        System.assert(result.success,result);
        System.assert(result.records.size() == 6,result.records);
        
        for (ProductionPlanningExt.DataWrapper wrapper:(List<ProductionPlanningExt.DataWrapper>)result.records) {
            if (wrapper.record.Id == ops.values()[0].Id) {
                wrapper.endDT = wrapper.endDT.addDays(-1);
                result = ProductionPlanningExt.updateDates(wrapper);
                System.assert(result.success,result);
                System.assert(result.records.size() == 1,result.records);
                
                result = ProductionPlanningExt.save((List<ProductionPlanningExt.DataWrapper>)result.records);
                System.assert(result.success,result);
                
                break;
            }
        }
        
        for (Operation_Tracking__c op:[SELECT Id,Start_Date__c,End_Date__c,Work_Order__c,Work_Order__r.Start_Date2__c,Work_Order__r.Earliest_Completion_Date2__c FROM Operation_Tracking__c ORDER BY Sequence__c ASC]) {
            if (op.Id == ops.values()[0].Id) {
                Operation_Tracking__c oldOp = ops.get(op.Id);
                System.assert(oldOp != null);
                System.assert(oldOp.Start_Date__c != op.Start_Date__c);
                System.assert(oldOp.End_Date__c != op.End_Date__c);
                System.assert(oldOp.Work_Order__r.Start_Date2__c != op.Work_Order__r.Start_Date2__c);
                System.assert(oldOp.Work_Order__r.Earliest_Completion_Date2__c == op.Work_Order__r.Earliest_Completion_Date2__c);
            }
        }
    }
    
    private static testMethod void testLevelLoad() {
        Work_Order__c wo = [SELECT Id,Name,Company__c,Facility__c,Assembly_Item_Specification__c,Item__c, Item__r.Stocking_UOM__c, Need_Date2__c,Start_Date2__c,Complete_To_Location__c,Default_WIP_Location__c,MRB_Location__c,Currency__c FROM Work_Order__c];
        
        Work_Order__c workOrder = new Work_Order__c(
            Company__c = wo.Company__c,
            Facility__c = wo.Facility__c,
            Assembly_Item_Specification__c = wo.Assembly_Item_Specification__c,
            Item__c = wo.Item__c,
            Need_Date2__c = wo.Need_Date2__c.addDays(2),
            Start_Date2__c = wo.Start_Date2__c,
            Order_Quantity__c = 10,
            Status__c = 'Draft',
            Type__c = 'Regular',
            Complete_To_Location__c = wo.Complete_To_Location__c,
            MRB_Location__c = wo.MRB_Location__c,
            Default_WIP_Location__c = wo.Default_WIP_Location__c,
            Currency__c = wo.Currency__c,
            Packaging_UOM__c = wo.Item__r.Stocking_UOM__c
        );
        insert workOrder;
        
        WorkOrderPlanningService.release(new Set<Id>{workOrder.Id});
        
        Map<Id,Operation_Tracking__c> ops = new Map<Id,Operation_Tracking__c>([SELECT Id,Start_Date__c,End_Date__c,Work_Order__r.Start_Date2__c,Work_Order__r.Earliest_Completion_Date2__c FROM Operation_Tracking__c]);
        
        ProductionPlanningExt ext = new ProductionPlanningExt();
        
        JsonResult result = ProductionPlanningExt.getWCRData(wo.Facility__c,null,null,null,null,null,DateTime.newInstance(wo.Start_Date2__c.date(),Time.newInstance(0,0,0,0)),30);
        System.assert(result.success,result);
        System.assert(result.records.size() == 9,result.records);
        
        result = ProductionPlanningExt.levelLoad(new List<Id>{ wo.Id, workOrder.Id },wo.Start_Date2__c.date());
        System.assert(result.success,result);
        System.assert(result.records.size() == 9,result.records);
        
        List<ProductionPlanningExt.DataWrapper> wrappers = new List<ProductionPlanningExt.DataWrapper>();
        for (ProductionPlanningExt.DataWrapper wrapper:(List<ProductionPlanningExt.DataWrapper>)result.records) {
            if (wrapper.parentId != null) {
                wrappers.add(wrapper);
            }
        }
        
        result = ProductionPlanningExt.save(wrappers);
        System.assert(result.success,result);
        
        for (Operation_Tracking__c op:[SELECT Id,Start_Date__c,End_Date__c,Work_Order__c,Work_Order__r.Start_Date2__c,Work_Order__r.Earliest_Completion_Date2__c FROM Operation_Tracking__c]) {
            Operation_Tracking__c oldOp = ops.get(op.Id);
            System.assert(oldOp != null);
            
            if (op.Work_Order__c == wo.Id) {
                System.assert(op.Start_Date__c == oldOp.Start_Date__c);
                System.assert(op.End_Date__c == oldOp.End_Date__c);
                System.assert(op.Work_Order__r.Start_Date2__c == oldOp.Work_Order__r.Start_Date2__c);
                System.assert(op.Work_Order__r.Earliest_Completion_Date2__c == oldOp.Work_Order__r.Earliest_Completion_Date2__c);
            } else if (op.Work_Order__c == workOrder.Id) {
                System.assert(op.Start_Date__c != oldOp.Start_Date__c);
                System.assert(op.End_Date__c != oldOp.End_Date__c);
                System.assert(op.Work_Order__r.Start_Date2__c != oldOp.Work_Order__r.Start_Date2__c);
                System.assert(op.Work_Order__r.Earliest_Completion_Date2__c != oldOp.Work_Order__r.Earliest_Completion_Date2__c);
            }
        }
    }
}