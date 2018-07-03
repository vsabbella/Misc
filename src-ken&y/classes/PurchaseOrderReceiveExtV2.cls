public with sharing class PurchaseOrderReceiveExtV2 extends BaseController {
    
    private Apexpages.Standardcontroller con;
    
    public string NamespaceUU { get { return KSE.NamespaceUU; }} 
    public string masterFieldList { get; set; }
    public string detailFieldList { get; set; }
    public string skidFieldList { get; set; }
    public string serialFieldList { get; set; }
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    public static final String POSUPPLY_TYPE = 'PO Supply'; 
    public static final String PO_STATUS_OPEN = 'Open' ;
    public static final String PO_APPROVAL_STATUS_APPROVED = 'Approved' ;
    public Boolean hideReceiveButton { get; set; } { hideReceiveButton = false; }
    public Boolean isPageError { get; set; } { isPageError = false; }
    public static Boolean serialTracked {get;set;}
    public Integer gridSize {get;set;}
    
    static {
        FieldInfo.AlwaysUseFullDateTimeFormat = false;
    }
    
    public PurchaseOrderReceiveExtV2(Apexpages.StandardController controller){
        
        con = controller;
        //PTP-89 Ablility to edit the Putaway location on the receipt UI
        //Commenting out the below line and adding custom logic to have the namespace trimmed for comparison to make putaway location editable 
        //Set<String> editableFields = new Set<String>(util.getFieldsFromFieldSetString(Purchase_Order_Line__c.sObjectType , 'Receiving_RO_EditableFields'));
        Set<String> editableFields = new Set<String>();
        List<FieldInfo> editablefieldsdefined = FieldInfo.fetchJsonFieldInfos('Purchase_Order_Line__c', 'Receiving_RO_EditableFields');
        for (Integer i = 0; i<editablefieldsdefined.size(); i++){
            editableFields.add(editablefieldsdefined[i].field);
        }
       
        // get the master field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Purchase_Order_Line__c', 'Receiving_RO');
        
        // set all the fields as readonly
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].editable = editableFields.contains(fieldInfoList[i].field) ? true : false;
            fieldInfoList[i].field = 'rl.' + fieldInfoList[i].field;
        }
        
        masterFieldList = JSON.serialize(fieldInfoList);
        
        // get the detail field info list
        fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', 'Receipt_Info');
        FieldInfo fieldInfoItem = FieldInfo.fetchJsonFieldInfos('SKID__c', new String[] { 'Temporary_Value_Holder__c' })[0];
        fieldInfoItem.hidden = true;
        fieldInfoList.add(fieldInfoItem);
        
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].field = 'skid.' + fieldInfoList[i].field;
        }
        detailFieldList = JSON.serialize(fieldInfoList);
        
        // get the skid field info list
        fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c');
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].field = 'skid.' + fieldInfoList[i].field;
        }
        skidFieldList = JSON.serialize(fieldInfoList);
        
        FieldInfo fi = new FieldInfo('','','integer');
        fi.editable = false;
        fieldInfoList = new list<FieldInfo>{fi};
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial'));
        serialFieldList = JSON.serialize(fieldInfoList);
        gridSize = fieldInfoList.size() * 150;
    }
    
    @RemoteAction 
    public static JsonResult getList(Id poId) {
        JsonResult result = new JsonResult();
        list<ReceivingWrapper> records = new list<ReceivingWrapper>();
        try{  
            records = ReceivingDocumentServiceV2.getReceivingLines( new set<Id>{poId},null, new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
            if(ExceptionService.messages.size()>0)
            {
                for (Map<String, String> msg : ExceptionService.messages) {
                    result.addMessage(msg.get('message'), ApexPages.Severity.WARNING); //service would throw exceptions for errors
                    result.reason = 'WARNING';
                }     
            }
            result.records = records;
            result.total = records.size();
            
            if(records.size() > 0){
                if(records[0].rl.getSObject('Company__r').get('Serial_Control__c') != null && 
                        records[0].rl.getSObject('Company__r').get('Serial_Control__c') == 'At receipt and all processes'){
                    result.additionalInfo = 'true'; // passing along the info of whether the page needs serial control at the company level
                }
                else{
                    result.additionalInfo = 'false';
                }
            }
        }
        catch (Exception e) {
            result.success = false;
            result.reason = 'FATAL_ERROR';
            result.addMessage(e.getMessage()+','+e.getStackTraceString(), ApexPages.Severity.ERROR);
        }
        
        return result;
    }
    
    @RemoteAction 
    public static List<FieldInfo> getDetailFieldInfoList(String[] trackedAttributes) {
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', trackedAttributes);
        
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].editable = (fieldInfoList[i].field != 'Consigned_Owner__c') ? true : false;
        }
        
        return fieldInfoList;
    }
    
    public PageReference Cancel(){ // cancels the receiving process.
        Purchase_Order__c po = ( Purchase_Order__c )con.getRecord();
        Id poId = po.Id;
        
        PageReference pg = new pageReference('/'+poId);
        return pg;
    }
    
    @RemoteAction
    public static JsonResult receive(List<ReceivingWrapper> rlWrapperList, List<String> polDateFields, List<String> skidDateFields){
        JsonResult result = new JsonResult();
        
        try{
            for( ReceivingWrapper rw : rlWrapperList ){
                KendoUtils.UpdateDateFields(rw.rl, polDateFields);
                
                for(Integer i = 0; i < rw.serialWrapperList.size(); i++){
                    KendoUtils.UpdateDateFields(rw.serialWrapperList[i].skid, skidDateFields);
                }
            }
        }
        catch (Exception e) {
            result.success = false;
            result.reason = 'FATAL_ERROR';
            result.addMessage(e.getMessage() + '  ' + e.getStackTraceString(), ApexPages.Severity.ERROR);
        }
        
        result = receivePurchaseOrders(rlWrapperList);
        return result;    
    }
    
    @RemoteAction
    public static list<String> refreshTrackedAttr( Location__c putAwayLocation , Item__c item, Boolean ConsignedFlag){
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        Id locationId = putAwayLocation.id;
        
        SOQLUtil soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name','Bin_Tracked__c'
        });
        soql.setWhereClause('Id =:locationId');
        soql.setLimit(1);
        
        Location__c pal = Database.query(soql.getQuery());

        list<String> attributesList = SkidService3.trackedAttributes(null, pal, item); 
        if(ConsignedFlag){
            attributesList.add('Consigned_Owner__c');
        }
        return attributesList;
        
    }
        
    public static JsonResult receivePurchaseOrders(List<ReceivingWrapper> rlWrapperList){
        JsonResult result = new JsonResult();
        Savepoint sp1 = Database.setSavepoint();
        try{
           
            List<ReceivingWrapper> refreshedList;
            try{
                refreshedList = ReceivingDocumentServiceV2.checkUserErrors(rlWrapperList);
            }
            catch(Exception e){
                system.debug('Fail Reason: ' + e.getStackTraceString());
                result.reason = 'ERROR';
                throw e;
            }
            
            ReceivingDocumentServiceV2.receive(refreshedList,null);
            
        }
        catch (Exception e) {
            Database.rollback(sp1);
            system.debug('Fail Reason: ' + e.getStackTraceString());
            result.success = false;
            
            if(e.getMessage().contains(Label.Serial_Number_Exists)){
                            system.debug('Fail Reason: ' + e.getStackTraceString());
                result.reason = 'ERROR';
            }
            
            if( result.reason != 'ERROR') result.reason = 'FATAL_ERROR';
                    system.debug('Fail Reason: ' + e.getStackTraceString());    
            result.addMessage(e.getMessage() + 'Stack Trace: '+ e.getStackTraceString(), ApexPages.Severity.ERROR);
        }
        
        return result;
    }

}