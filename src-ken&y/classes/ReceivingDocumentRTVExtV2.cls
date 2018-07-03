public with sharing class ReceivingDocumentRTVExtV2 extends BaseController {

    public String namespaceUU { get; set; } { namespaceUU = KSE.namespaceUU; }
    public String receivingDocumentJSON { get; set; }
    public Boolean serialTracked { get; set; } { serialTracked = false; }
    public String serialFieldListJSON { get; set; }
    public Integer gridSize { get; set; }
    final String TYPE_REFERENCE = 'reference' ;
    public static string serialAttributes { get;set;}
    
    @RemoteAction
    public static JsonResult getRTVData(String rdId) {
        JsonResult result = new JsonResult();
        try {  
            result.records = ReceivingDocumentServiceV2.getRTVData(new Set<Id>{(Id)rdId});
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction
    public static JsonResult save(List<LineWrapper> rlWrappers,List<String> rlDateFields,List<String> skidDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            for (LineWrapper rlWrapper:rlWrappers) {
                KendoUtils.UpdateDateFields(rlWrapper.line,rlDateFields);
                
                for (SkidService3.SerialWrapper sw:rlWrapper.serialWrappers) {
                    KendoUtils.UpdateDateFields(sw.skid,skidDateFields);
                }
            }
            
            ReceivingDocumentServiceV2.checkRTVErrors(rlWrappers);
            ReceivingDocumentServiceV2.returnToVendor(rlWrappers);                            
        } catch(Exception e) {
            Database.rollback(sp);          
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    public ReceivingDocumentRTVExtV2(ApexPages.StandardController con) {
        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
        rdQuery.addAllCustomFields();
        rdQuery.addField('Company__r.Serial_Control__c');
        rdQuery.setWhereClause('Id = \'' + con.getId() + '\'');
        Receiving_Document__c rd = (Receiving_Document__c)(Database.query(rdQuery.getQuery())[0]);
        receivingDocumentJSON = JSON.serialize(rd);
        
        if (rd.Company__r.Serial_Control__c == 'At receipt and all processes') {
            serialTracked = true;
        }
        
        FieldInfo fii = new FieldInfo('','','integer');
        fii.editable = false;
        List<FieldInfo> fiList = new List<FieldInfo>{fii};
        List<String> serialAttributesList = new list<String>();
        for( String serAttr : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes') ){
   	        serialAttributesList.add(serAttr.replace( KSE.namespaceUU, '').toLowerCase().trim()); 
   	    }
   	    serialAttributes = JSON.serialize(serialAttributesList);
        fiList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial',serialAttributesList.size() > 0 ? String.join(serialAttributesList, ',') : null, false));
        
        for(FieldInfo fi : fiList){
            
            String field = fi.field.replace(KSE.NamespaceUU, '');
            if(field.toLowerCase() == 'name'){
                fi.field='SerialNameId';
                fi.fieldType = TYPE_REFERENCE;
                fi.referenceTo = 'Serial__c';
            }
            else if( field.toLowerCase() == 'fixed_asset__c' ){
                fi.editable = false;
            }
        }
        serialFieldListJSON = JSON.serialize(fiList);
        gridSize = fiList.size() * 150;
    }
    
    public String rtvGridConfigJson {
        get {
            if (rtvGridConfigJson == null) {
                GridRelatedListController.GridRelatedListConfig rtvGridConfig = new GridRelatedListController.GridRelatedListConfig();
                rtvGridConfig.uniqueId = 'rtvGrid';
                rtvGridConfig.title = 'Select Inventory';
                rtvGridConfig.objectName = 'Receipt_Line__c';
                rtvGridConfig.fieldSet = 'Return_To_Vendor';
                rtvGridConfig.buttons = 'Expand All,Collapse All,Populate Quantities';
                rtvGridConfig.alwaysUseFullDateTimeFormat = false;
                rtvGridConfig.namespace = namespaceUU;
                rtvGridConfigJSON = JSON.serialize(rtvGridConfig);
            }
            return rtvGridConfigJson;
        } set;
    }
    
    public String receiptLineFieldListJSON {
        get {
            if (receiptLineFieldListJSON == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Receipt_Line__c','Return_To_Vendor',null,true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) {
                    fi.field = 'line.' + fi.field;
                }
                receiptLineFieldListJSON = JSON.serialize(fiList);
            }
            return receiptLineFieldListJSON;
        } set;
    }
    
    public String skidFieldListJSON {
        get {
            if (skidFieldListJSON == null) {
                List<String> flds = new List<String>{ 'Item__c','Packaging_UOM__c','License_Plate_Number__c' };
                flds.addAll(SkidService3.attributesForDisplay(new Set<String>{ 'lot_number__c' },new List<String>{ 'Lot_Number__c','Quantity_Available__c','Quantity_To_Return__c' },false));
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c',flds);
                for (FieldInfo fi:fiList) {
                    if (fi.field != 'Quantity_To_Return__c')
                        fi.editable = false;
                    fi.field = 'skid.' + fi.field;
                }
                return JSON.serialize(fiList);
            }
            return skidFieldListJSON;
        } set;
    }
    
    public class ReceivingDocumentRTVExtV2Exception extends Exception { }
}