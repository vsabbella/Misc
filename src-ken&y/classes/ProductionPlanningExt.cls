public with sharing class ProductionPlanningExt extends BaseController {

    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public Id defaultCompany { get; set; }
    public Id defaultFacility { get; set; }
    public Id defaultWorkCenter { get; set; }
    public Id defaultResource { get; set; }
    public Id defaultWorkCenterResource { get; set; }
    public String defaultStartDate { get; set; }
    public Integer defaultDays { get; set; } { defaultDays = 0; }
    
    private static final Set<String> excludedStatuses = new Set<String>{ WorkOrderService.WO_STATUS_DRAFT,WorkOrderService.WO_STATUS_COMPLETE,WorkOrderService.WO_STATUS_CLOSED,WorkOrderService.WO_STATUS_CANCELLED };

    @RemoteAction
    public static JsonResult levelLoad(List<Id> woIds,Date startDate) {
        JsonResult result = new JsonResult();
        try {
            Set<Id> woIdSet = new Set<Id>(woIds);
            
            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addAllCustomFields();
            opQuery.addAllCustomFields(Work_Center_Resource__c.sObjectType,'Work_Center_Resource__r');
            opQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
            opQuery.addFields(new Set<String>{ 'Work_Center_Resource__r.Manufacturing_Calendar__c','Work_Center__r.Manufacturing_Calendar__c',
                'Work_Order__r.Facility__r.Manufacturing_Calendar__c','Work_Order__r.Company__r.Manufacturing_Calendar__c',
                'Work_Order__r.Shipment_Line__r.Sales_Order_Line__c','Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Id',
                'Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Name' });
            opQuery.setWhereClause('Work_Order__r.Status__c NOT IN :excludedStatuses AND Work_Center_Resource__c != null AND Work_Order__c IN :woIdSet');
            opQuery.setOrderByClause('Work_Order__c,Sequence__c ASC');

            List<Operation_Tracking__c> operations = new List<Operation_Tracking__c>();
            for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
                operations.add(op);
            }

            WorkOrderPlanningService.levelLoad(operations,DateTime.newInstance(startDate,Time.newInstance(0,0,0,0)));

            Map<Id,DataWrapper> wrappers = new Map<Id,DataWrapper>();
            for (Operation_Tracking__c op:operations) {
                wrappers.put(op.Id,new DataWrapper(op,op.Work_Center_Resource__c,op.Start_Date__c,op.End_Date__c));

                if (!wrappers.containsKey(op.Work_Center_Resource__c)) {
                    wrappers.put(op.Work_Center_Resource__c,new DataWrapper(op.Work_Center_Resource__r,null,op.Start_Date__c,op.End_Date__c));
                } else {
                    DataWrapper wrapper = wrappers.get(op.Work_Center_Resource__c);
                    if (op.Start_Date__c < wrapper.startDate) {
                        wrapper.updateStart(op.Start_Date__c);
                    }
                    if (op.End_Date__c > wrapper.endDate) {
                        wrapper.updateEnd(op.End_Date__c);
                    }
                }
            }

            result.records = wrappers.values();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult updateDates(DataWrapper wrapper) {
        JsonResult result = new JsonResult();
        try {
            Operation_Tracking__c op = (Operation_Tracking__c)wrapper.record;
            
            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addAllCustomFields();
            opQuery.addAllCustomFields(Work_Center_Resource__c.sObjectType,'Work_Center_Resource__r');
            opQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
            opQuery.addFields(new Set<String>{ 'Work_Center_Resource__r.Manufacturing_Calendar__c','Work_Center__r.Manufacturing_Calendar__c',
                'Work_Order__r.Facility__r.Manufacturing_Calendar__c','Work_Order__r.Company__r.Manufacturing_Calendar__c',
                'Work_Order__r.Shipment_Line__r.Sales_Order_Line__c','Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Id',
                'Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Name' });
            opQuery.setWhereClause('Work_Center_Resource__c != null AND Work_Order__c = \'' + op.Work_Order__c + '\'');
            
            Map<Id,DateTime> lastDates = new Map<Id,DateTime>();
            Boolean backwards = false;
            DateTime dateForCalendar;
            if (wrapper.startDT > wrapper.startDate) {
                opQuery.setOrderByClause('Sequence__c ASC');
                lastDates.put(op.Work_Order__c,wrapper.startDT);
                dateForCalendar = wrapper.startDT;
            } else {
                opQuery.setOrderByClause('Sequence__c DESC');
                lastDates.put(op.Work_Order__c,wrapper.endDT);
                backwards = true;
                dateForCalendar = wrapper.endDT;
            }
            
            List<Operation_Tracking__c> operations = Database.query(opQuery.getQuery());
            Map<Id,Map<Date,Working_Day__c>> calendars = WorkOrderPlanningService.getCalendars(dateForCalendar,backwards);
            
            List<DataWrapper> wrappers = new List<DataWrapper>();
            for (Operation_Tracking__c operation:operations) {
                if ((!backwards && operation.Sequence__c >= op.Sequence__c) || (backwards && operation.Sequence__c <= op.Sequence__c)) {
                    Id calendarId = WorkOrderPlanningService.getCalendarId(operation);
                    Map<Date,Working_Day__c> calendar = calendars.get(calendarId);

                    if (calendar == null) {
                        throw new ProductionPlanningException(op.Name + ': Cannot find manufacturing calendar');
                    }

                    Decimal hoursToConsume = operation.Standard_Hours__c * 60.0 * 60.0 * 1000.0;
                    if (!op.Fixed_Hours__c) {
                        hoursToConsume = hoursToConsume * operation.Work_Order__r.Order_Quantity__c;
                    }
                    Long msecsToConsume = Long.valueOf(String.valueOf(hoursToConsume));
                    
                    if (!backwards && operation.Sequence__c >= op.Sequence__c) {
                        if (operation.Id != op.Id && operation.Start_Date__c > lastDates.get(operation.Work_Order__c)) {
                            break;
                        }
                    
                        operation.Start_Date__c = lastDates.get(op.Work_Order__c);
                    
                        lastDates.putAll(WorkOrderPlanningService.setOperationStartAndEnd(operation,calendar,msecsToConsume));
                    } else {
                        if (operation.Id != op.Id && operation.End_Date__c < lastDates.get(operation.Work_Order__c)) {
                            break;
                        }
                    
                        operation.End_Date__c = lastDates.get(op.Work_Order__c);
                    
                        lastDates.putAll(WorkOrderPlanningService.setOperationStartAndEndBackwards(operation,calendar,msecsToConsume));
                    }
                    
                    wrappers.add(new DataWrapper(operation,operation.Work_Center_Resource__c,operation.Start_Date__c,operation.End_Date__c));
                }
            }

            result.records = wrappers;
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getWCRData(Id facilityId,Id wcId,Id resourceId,Id wcrId,String workOrders,String salesOrders,DateTime startDateFilter,Integer days) {
        JsonResult result = new JsonResult();
        try {
            SOQLUtil wcrQuery = new SOQLUtil('Work_Center_Resource__c');
            wcrQuery.addAllCustomFields();
            wcrQuery.setOrderByClause('Work_Center__c,Facility__c');

            Set<String> whereClause = new Set<String>{ 'Facility__c = :facilityId' };
            if (wcId != null) {
                whereClause.add('Work_Center__c = :wcId');
            }
            if (resourceId != null) {
                whereClause.add('Resource__c = :resourceId');
            }
            if (wcrId != null) {
                whereClause.add('Id = :wcrId');
            }
            wcrQuery.setWhereClause(String.join(new List<String>(whereClause),' AND '));

            DateTime endDateFilter = startDateFilter.addDays(days);
            DateTime startDateForQuery = DateTime.newInstance(startDateFilter.year(),startDateFilter.month(),startDateFilter.day());
            DateTime endDateForQuery = DateTime.newInstance(endDateFilter.year(),endDateFilter.month(),endDateFilter.day());

            SOQLUtil.ChildRelationship opQuery = new SOQLUtil.ChildRelationship(wcrQuery,'Operation_Trackings__r');
            opQuery.addAllCustomFields();
            opQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
            opQuery.addAllCustomFields(Sales_Order_Line__c.sObjectType,'Work_Order__r.Shipment_Line__r.Sales_Order_Line__r');
            opQuery.addField('Work_Order__r.Shipment_Line__r.Sales_Order_Line__c');
            opQuery.setOrderByClause('Start_Date__c ASC');

            Set<String> opWhereClause = new Set<String>{ 'Start_Date__c <= :endDateForQuery','End_Date__c >= :startDateForQuery','Work_Order__r.Status__c NOT IN :excludedStatuses' };
            
            Set<Id> woIds;
            if (workOrders != null) {
                woIds = (Set<Id>)JSON.deserialize(workorders,Set<Id>.Class);
                opWhereClause.add('Work_Order__c IN :woIds');
            }

            Set<Id> soIds;
            if (salesOrders != null) {
                soIds = (Set<Id>)JSON.deserialize(salesorders,Set<Id>.Class);
                opWhereClause.add('Work_Order__r.Shipment_Line__r.Sales_Order__c IN :soIds');
            }

            opQuery.setWhereClause(String.join(new List<String>(opWhereClause),' AND '));
            wcrQuery.addChildRelationship(opQuery);

            List<DataWrapper> wrappers = new List<DataWrapper>();
            for (Work_Center_Resource__c wcr:Database.query(wcrQuery.getQuery())) {
                DateTime firstStartDate;
                DateTime lastEndDate;
                
                for (Integer i=0;i<wcr.Operation_Trackings__r.size();i++) {
                    Operation_Tracking__c op1 = wcr.Operation_Trackings__r[i];
                    if (firstStartDate == null || (op1.Start_Date__c < firstStartDate)) {
                        firstStartDate = op1.Start_Date__c;
                    }
                    if (lastEndDate == null || (op1.End_Date__c > lastEndDate)) {
                        lastEndDate = op1.End_Date__c;
                    }
                    wrappers.add(new DataWrapper(op1,wcr.Id,op1.Start_Date__c,op1.End_Date__c));
                }
                
                wrappers.add(new DataWrapper(wcr,null,firstStartDate,lastEndDate));
            }
            
            result.records = wrappers;
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult save(List<DataWrapper> wrappers) {
        Savepoint sp = Database.setSavepoint();
        JsonResult result = new JsonResult();
        try {
            Set<Id> woIds = new Set<Id>();
            List<Operation_Tracking__c> opsToUpdate = new List<Operation_Tracking__c>();
            for (DataWrapper wrapper:wrappers) {
                woIds.add((Id)wrapper.record.get('Work_Order__c'));
                opsToUpdate.add(new Operation_Tracking__c(Id = wrapper.record.Id, Start_Date__c = wrapper.startDate, End_Date__c = wrapper.endDate, Work_Center_Resource__c = wrapper.parentId));
            }
            DML.updateAsUser(opsToUpdate);
            
            SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
            woQuery.addField('Id');
            woQuery.setWhereClause('Id IN :woIds');
            
            SOQLUtil.ChildRelationship opQuery = new SOQLUtil.ChildRelationship(woQuery,'Operation_Trackings__r');
            opQuery.addFields(new Set<String>{ 'Start_Date__c','End_Date__c' });
            opQuery.setOrderByClause('Sequence__c ASC');
            woQuery.addChildRelationship(opQuery);
            
            List<Work_Order__c> workOrders = new List<Work_Order__c>();
            for (Work_Order__c wo:Database.query(woQuery.getQuery())) {
                workOrders.add(new Work_Order__c(Id = wo.Id, Start_Date2__c = wo.Operation_Trackings__r[0].Start_Date__c, Earliest_Completion_Date2__c = wo.Operation_Trackings__r[wo.Operation_Trackings__r.size() - 1].End_Date__c));
            }
            
            WorkOrderService.allowWorkOrderUpdate = true;
            DML.updateAsUser(workOrders);
            WorkOrderService.allowWorkOrderUpdate = false;
        } catch(Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    public ProductionPlanningExt() {
        User_Preference__c up = UserPreference.getInstance().preference;
        Map<String,String> pageParameters = ApexPages.currentPage().getParameters();
        
        if (pageParameters.containsKey('company')) {
            defaultCompany = (Id)pageParameters.get('company');
        } else if (up != null && up.Default_Company__c != null) {
            defaultCompany = up.Default_Company__c;
        }
        if (pageParameters.containsKey('facility')) {
            defaultFacility = (Id)pageParameters.get('facility');
        } else if (up != null && up.Default_Facility__c != null) {
            defaultFacility = up.Default_Facility__c;
        }
        if (pageParameters.containsKey('workCenter')) {
            defaultWorkCenter = (Id)pageParameters.get('workCenter');
        }
        if (pageParameters.containsKey('resource')) {
            defaultResource = (Id)pageParameters.get('resource');
        }
        if (pageParameters.containsKey('workCenterResource')) {
            defaultWorkCenterResource = (Id)pageParameters.get('workCenterResource');
        }
        if (pageParameters.containsKey('startDate')) {
            defaultStartDate = pageParameters.get('startDate');
        }
        if (pageParameters.containsKey('days')) {
            defaultDays = Integer.valueOf(pageParameters.get('days'));
        }
    }

    public List<FieldInfo> calendarFields {
        get {
            if (calendarFields == null) {
                calendarFields = new List<FieldInfo>();

                FieldInfo fi = new FieldInfo('title','Name','string');
                fi.width = 126;
                calendarFields.add(fi);

                fi = new FieldInfo('record.Work_Order__c','Work Order','string');
                fi.width = 107;
                calendarFields.add(fi);

                fi = new FieldInfo('record.Work_Order__r.Shipment_Line__r.Sales_Order_Line__c','Sales Order Line','string');
                fi.width = 106;
                calendarFields.add(fi);
            }
            return calendarFields;
        } set;
    }

    public String calendarFieldsJson {
        get {
            if (calendarFieldsJson == null) {
                calendarFieldsJson = JSON.serialize(calendarFields);
            }
            return calendarFieldsJson;
        } set;
    }

    public String allFieldsJson {
        get {
            if (allFieldsJson == null) {
                List<FieldInfo> allFields = new List<FieldInfo>(calendarFields);
                allFields.add(new FieldInfo('startDate','Start Date','datetime'));
                allFields.add(new FieldInfo('startDT','Start Date','datetime'));
                allFields.add(new FieldInfo('endDate','End Date','datetime'));
                allFields.add(new FieldInfo('endDT','End Date','datetime'));
                allFieldsJson = JSON.serialize(allFields);
            }
            return allFieldsJson;
        } set;
    }

    public class DataWrapper {
        public sObject record { get; set; }
        public Id parentId { get; set; }
        public DateTime startDate { get; set; }
        public DateTime startDT { get; set; }
        public DateTime endDate { get; set; }
        public DateTime endDT { get; set; }
        public Work_Order__c workOrder { get; set; }
        public Decimal percentComplete { get; set; } { percentComplete = 0; }
        public Boolean summary { get; set; } { summary = false; }

        public DataWrapper(sObject record,Id parentId,DateTime startDate,DateTime endDate) {
            this.record = record;
            this.startDate = startDate;
            this.startDT = startDate;
            this.endDate = endDate;
            this.endDT = endDate;

            if (record.getSObjectType() == Operation_Tracking__c.sObjectType || record.getSObjectType() == Work_Order__c.sObjectType) {
                percentComplete = (Decimal)record.get('Percent_Complete__c') / 100.0;

                if (record.getSObjectType() == Operation_Tracking__c.sObjectType) {
                    this.parentId = parentId;
                }
            }

            if (record.getSObjectType() == Work_Center_Resource__c.sObjectType || record.getSObjectType() == Work_Order__c.sObjectType) {
                summary = true;
            }
        }

        public void updateStart(DateTime s) {
            startDate = s;
            startDT = s;
        }

        public void updateEnd(DateTime e) {
            endDate = e;
            endDT = e;
        }
    }

    public class ProductionPlanningException extends Exception { }
}