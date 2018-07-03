public with sharing class CapacityPlanningExt extends GridRelatedListController {

    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public Id defaultCompany { get; set; }
    public Id defaultFacility { get; set; }
    public string HelpURL{get;set;}
    private static final Set<String> excludedStatuses = new Set<String>{ WorkOrderService.WO_STATUS_DRAFT,WorkOrderService.WO_STATUS_COMPLETE,WorkOrderService.WO_STATUS_CLOSED,WorkOrderService.WO_STATUS_CANCELLED };

    public CapacityPlanningExt() {
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpCapacityPlanning';
        User_Preference__c up = UserPreference.getInstance().preference;
        if (up != null) { 
            if (up.Default_Company__c != null) {
                defaultCompany = up.Default_Company__c;
            }
            if (up.Default_Facility__c != null) {
                defaultFacility = up.Default_Facility__c;
            }
        }
    }

    @RemoteAction
    public static JsonResult getWCRData(Id facilityId,Id wcId,Id resourceId,Id wcrId,DateTime startDt,Integer days) {
        JsonResult result = new JsonResult();

        try {
            SOQLUtil wcrQuery = new SOQLUtil('Work_Center_Resource__c');
            wcrQuery.addAllCustomFields();
            wcrQuery.addAllCustomFields(Work_Center__c.sObjectType,'Work_Center__r');
            wcrQuery.addAllCustomFields(Calendar__c.sObjectType,'Manufacturing_Calendar__r');
            wcrQuery.addAllCustomFields(Calendar__c.sObjectType,'Work_Center__r.Manufacturing_Calendar__r');
            wcrQuery.addAllCustomFields(Calendar__c.sObjectType,'Facility__r.Manufacturing_Calendar__r');
            wcrQuery.addAllCustomFields(Calendar__c.sObjectType,'Company__r.Manufacturing_Calendar__r');
            wcrQuery.setOrderByClause('Work_Center__c,Facility__c');
            wcrQuery.addFields('CapacityPlanning');

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
            if (whereClause.size() > 0) {
                wcrQuery.setWhereClause(String.join(new List<String>(whereClause),' AND '));
            }
            
            List<Work_Center_Resource__c> wcrList = Database.query(wcrQuery.getQuery());

            Date startDate = startDt.date();
            Time startTime = startDt.time();
            
            DateTime endDt = startDt.addDays(days);
            Date endDate = endDt.date();
        
            Map<Id,Calendar__c> calendarMap = new Map<Id,Calendar__c>();
            Set<Id> calendarIds = new Set<Id>();
            for (Work_Center_Resource__c wcr:wcrList) {
                if (wcr.Manufacturing_Calendar__c != null) {
                    calendarMap.put(wcr.Id,wcr.Manufacturing_Calendar__r);
                    calendarIds.add(wcr.Manufacturing_Calendar__c);
                } else if (wcr.Work_Center__r.Manufacturing_Calendar__c != null) {
                    calendarMap.put(wcr.Id,wcr.Work_Center__r.Manufacturing_Calendar__r);
                    calendarIds.add(wcr.Work_Center__r.Manufacturing_Calendar__c);
                } else if (wcr.Facility__r.Manufacturing_Calendar__c != null) {
                    calendarMap.put(wcr.Id,wcr.Facility__r.Manufacturing_Calendar__r);
                    calendarIds.add(wcr.Facility__r.Manufacturing_Calendar__c);
                } else if (wcr.Company__r.Manufacturing_Calendar__c != null) {
                    calendarMap.put(wcr.Id,wcr.Company__r.Manufacturing_Calendar__r);
                    calendarIds.add(wcr.Company__r.Manufacturing_Calendar__c);
                }
            }
            
            DateTime startDateForQuery = DateTime.newInstance(startDt.year(),startDt.month(),startDt.day());
            DateTime endDateForQuery = DateTime.newInstance(endDt.year(),endDt.month(),endDt.day());
            SOQLUtil workingDayQuery = new SOQLUtil('Working_Day__c');
            workingDayQuery.addAllCustomFields();
            workingDayQuery.setWhereClause('Start__c >= :startDateForQuery AND Start__c < :endDateForQuery AND Calendar__c IN :calendarIds');
            workingDayQuery.setOrderByClause('Start__c ASC');
            Map<Id,List<Working_Day__c>> workingDayMap = new Map<Id,List<Working_Day__c>>();
            for (Working_Day__c workDay:Database.query(workingDayQuery.getQuery())) {
                if (!workingDayMap.containsKey(workDay.Calendar__c))
                    workingDayMap.put(workDay.Calendar__c,new List<Working_Day__c>());
                workingDayMap.get(workDay.Calendar__c).add(workDay);
            }

            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addAllCustomFields();
            opQuery.setWhereClause('Work_Center_Resource__c IN :wcrList AND Start_Date__c <= :endDateForQuery AND End_Date__c >= :startDateForQuery AND Work_Order__r.Status__c NOT IN :excludedStatuses');
            opQuery.setOrderByClause('Start_Date__c ASC');
            Map<Id,List<Operation_Tracking__c>> opTrackings = new Map<Id,List<Operation_Tracking__c>>();
            for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
                if (!opTrackings.containsKey(op.Work_Center_Resource__c))
                    opTrackings.put(op.Work_Center_Resource__c,new List<Operation_Tracking__c>());
                opTrackings.get(op.Work_Center_Resource__c).add(op);
            }

            List<WCRWrapper> wcrWrappers = new List<WCRWrapper>();
            Map<Id,Set<Id>> woIds = new Map<Id,Set<Id>>();
            Map<Id,Set<Id>> opIds = new Map<Id,Set<Id>>();
            for (Work_Center_Resource__c wcr:wcrList) {
                if (!calendarMap.containsKey(wcr.Id)) {
                    throw new CapacityPlanningException(wcr.Name + ' Cannot find a manufacturing calendar');
                }

                if (!woIds.containsKey(wcr.Id)) {
                    woIds.put(wcr.Id,new Set<Id>());
                }
                if (!opIds.containsKey(wcr.Id)) {
                    opIds.put(wcr.Id,new Set<Id>());
                }

                List<Working_Day__c> workingDays = workingDayMap.containsKey(calendarMap.get(wcr.Id).Id) ? workingDayMap.get(calendarMap.get(wcr.Id).Id) : new List<Working_Day__c>();
                List<Operation_Tracking__c> operations = opTrackings.containsKey(wcr.Id) ? opTrackings.get(wcr.Id) : new List<Operation_Tracking__c>();
                
                Decimal capacity = 0;
                Decimal capacityUsed = 0;
                
                for (Working_Day__c workDay:workingDays) {
                    Time lowerTimeBound = startDate == workDay.Start__c.date() && startTime > workDay.Start__c.time() ? startTime : workDay.Start__c.time(); 
                    Time upperTimeBound = endDate == workDay.Start__c.date() && startTime < workDay.End__c.time() ? startTime : workDay.End__c.time();
                    DateTime lowerDT = DateTime.newInstance(workDay.Start__c.date(),lowerTimeBound);
                    DateTime upperDT = DateTime.newInstance(workDay.Start__c.date(),upperTimeBound);
                    
                    capacity += (upperDT.getTime() - lowerDT.getTime()) / (1000.0 * 60.0 * 60.0);
                    
                    for (Operation_Tracking__c op:operations) {
                        if (op.Start_Date__c <= upperDt && op.End_Date__c >= lowerDt) {
                            DateTime lowerDT2 = op.Start_Date__c > lowerDT ? op.Start_Date__c : lowerDT;
                            DateTime upperDT2 = op.End_Date__c < upperDt ? op.End_Date__c : upperDT;

                            capacityUsed += (upperDT2.getTime() - lowerDT2.getTime()) / (1000.0 * 60.0 * 60.0);

                            woIds.get(wcr.Id).add(op.Work_Order__c);
                            opIds.get(wcr.Id).add(op.Id);
                        }
                    }
                }

                wcrWrappers.add(new WCRWrapper(wcr,capacity,capacity - capacityUsed));
            }

            result.records = wcrWrappers;
            result.additionalInfo = JSON.serialize(new Map<String,Map<Id,Set<Id>>>{ 'wos' => woIds, 'ops' => opIds });
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getWOData(List<Id> woIds) {
        JsonResult result = new JsonResult();

        try {
            SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
            woQuery.addAllCustomFields();
            woQuery.addFields('CapacityPlanning');
            woQuery.setWhereClause('Id IN :woIds');
            woQuery.setOrderByClause('Start_Date2__c ASC');
            result.records = Database.query(woQuery.getQuery());
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getOPData(List<Id> opIds) {
        JsonResult result = new JsonResult();

        try {
            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addAllCustomFields();
            opQuery.addFields('CapacityPlanning');
            opQuery.setWhereClause('Id IN :opIds');
            opQuery.setOrderByClause('Work_Order__c, Start_Date__c ASC');
            result.records = Database.query(opQuery.getQuery());
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    public String wcrFieldsJson {
        get {
            if (wcrFieldsJson == null) {
                List<FieldInfo> wcrFields = FieldInfo.fetchJsonFieldInfos('Work_Center_Resource__c','CapacityPlanning');
                wcrFields.remove(0);
                for (FieldInfo fi:wcrFields) {
                    if (fi.field.toLowerCase() == 'name') {
                        fi.field = 'WCRRec';
                        fi.fieldType = 'reference';
                        fi.referenceTo = 'Work_Center_Resource__c';
                    }

                    fi.field = 'wcr.' + fi.field;
                }

                wcrFields.add(new FieldInfo('capacity','Capacity','double'));
                wcrFields.add(new FieldInfo('availableCapacity','Available Capacity','double'));
                wcrFields.add(new FieldInfo('percentAvailable','% Available','double'));

                wcrFieldsJson = JSON.serialize(wcrFields);
            }
            return wcrFieldsJson;
        } set;
    }
    
    public String woFieldsJson {
        get {
            if (woFieldsJson == null) {
                List<FieldInfo> woFields = FieldInfo.fetchJsonFieldInfos('Work_Order__c','CapacityPlanning');
                woFields.remove(0);
                for (FieldInfo fi:woFields) {
                    if (fi.field.toLowerCase() == 'name') {
                        fi.field = 'WORec__c';
                        fi.fieldType = 'reference';
                        fi.referenceTo = 'Work_Order__c';
                        break;
                    }
                }

                woFieldsJson = JSON.serialize(woFields);
            }
            return woFieldsJson;
        } set;
    }
    
    public String opFieldsJson {
        get {
            if (opFieldsJson == null) {
                List<FieldInfo> opFields = FieldInfo.fetchJsonFieldInfos('Operation_Tracking__c','CapacityPlanning');
                opFields.remove(0);
                for (FieldInfo fi:opFields) {
                    if (fi.field.toLowerCase() == 'name') {
                        fi.field = 'OPRec__c';
                        fi.fieldType = 'reference';
                        fi.referenceTo = 'Operation_Tracking__c';
                    }

                    fi.required = false;
                }

                opFieldsJson = JSON.serialize(opFields);
            }
            return opFieldsJson;
        } set;
    }
    
    public class WCRWrapper {
        public Work_Center_Resource__c wcr { get; set; }
        public Decimal capacity { get; set; }
        public Decimal availableCapacity { get; set; }
        public Decimal percentAvailable { get; set; }
        public WCRWrapper(Work_Center_Resource__c wcr,Decimal capacity,Decimal availableCapacity) {
            this.wcr = wcr;
            this.capacity = KSE.addQuantityToField(capacity,0);
            this.availableCapacity = KSE.addQuantityToField(availableCapacity,0);
            this.percentAvailable = (this.capacity == 0 || this.availableCapacity == 0) ? 0 : (this.availableCapacity / this.capacity) * 100;
        }
    }

    public class CapacityPlanningException extends Exception { }
}