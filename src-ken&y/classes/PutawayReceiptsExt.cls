public with sharing class PutawayReceiptsExt extends BaseController{
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	private static SchemaUtil util = SchemaUtil.getInstance();	
	public GridRelatedListController.GridRelatedListConfig ReceiptLinesConfig {get; set;}
	public static String fieldsetName; 
	public static String RMAType { get; set; } 
	public String ReceiptLinesFieldList = null;
	public Id defaultFacility{ get; set;}
	public static String LinesFieldList = null;	
    public static list<SObject> rlineslist;
    public Boolean tabView { get; set;} { tabView = true; }
    public Boolean errorOnPageLoad {get;set;}{errorOnPageLoad = false;}
    public static string masterFieldList { get; set; }
    public static string detailFieldList { get; set; }
    public static string skidFieldList { get; set; }
    public static string serialFieldList { get; set; }
    public static string serialAttributes { get;set;}
    public Boolean hideReceiveButton { get; set; } { hideReceiveButton = false; }          
    public static Integer gridSize {get;set;}
    public static Boolean serialTracked {get;set;}
    final String TYPE_REFERENCE = 'reference' ;
    public string HelpURL{get;set;}
     
    public PutawayReceiptsExt(){
        
        ReceiptLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        ReceiptLinesConfig.uniqueId = 'ReceiptLinesGrid';
        ReceiptLinesConfig.title = 'Receipt Lines';
        ReceiptLinesConfig.objectName = 'Receipt_Line__c';
        ReceiptLinesConfig.fieldset = 'PutawayReceipts_Receiving';
        ReceiptLinesConfig.buttons = 'columnmenu, search';   
        ReceiptLinesConfig.alwaysUseFullDateTimeFormat = false;
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        Id userId = UserInfo.getUserID();
        
        SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Default_Company__c','Default_Facility__c'
        });
        soql.setWhereClause('ownerId = :userId');
        soql.setLimit(1);

        List<User_Preference__c> u = Database.query(soql.getQuery());

        if (u.size() > 0){
            if (u[0].Default_Facility__c != null)
                defaultFacility = u[0].Default_Facility__c;
        }
        gridSize = 600;
    }
    
    @RemoteAction 
    public static JsonResult getLinesToReceive(String FacilityId, String ItemId, String SupplierId, String customerFilter, String docnumfilter, String doctype) {
                
        JsonResult result = new JsonResult();
        String whereClause = '';
		whereClause = 'Status__c = \'Closed\' and Status__c != \'Cancelled\' and Status__c != \'Void\'';

        fieldSetName = 'PutawayReceipts_Receiving';

        String filterType;
        Set<String> rmareceiptTypes = new Set<String>{'RMA Receipt', 'RMA Receipt For Repair','Logical RMA Receipt'};
        
        if (doctype == 'RMA') {
            whereClause += ' and Receiving_Document__r.Type__c IN :rmareceiptTypes and Item__r.Non_Inventory__c = false and Quantity_Still_Due_For_Putaway__c > 0';

	    }
	    else if( docType == 'Receiving Document'){
	        whereClause = 'Status__c != \'Closed\' and Status__c != \'Cancelled\' and Status__c != \'Void\' and Receiving_Document__r.Type__c !=\'RMA Receipt\' and Receiving_Document__r.Type__c !=\'RMA Receipt For Repair\' and Quantity_Still_Due_For_Putaway__c > 0 '; 
	    }
    		
    	if(!String.isBlank(docnumfilter)){        		
    		whereClause += '  and Receiving_Document__c = :docnumfilter';
    	}

        if (!String.isBlank(FacilityId)){
            whereClause += ' and Facility__c = :FacilityId';                
        }
        
        if (!String.isBlank(ItemId)){           
            whereClause += ' and Item__c = :ItemId';            
        }
        
        if(!String.isBlank(customerFilter)){
            whereClause += ' and Sales_Order__r.Customer__c = :customerFilter';
        }
                   
        
        
        Set<String> additionalFields = new set<string>{'Id','Company__r.Serial_Control__c','Sales_Order__r.Customer__r.Name','Receiving_Document__r.Type__c','Sales_Order__r.Type__c', 'Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c'};
        additionalFields.addAll(util.getAllCustomFieldsFromObject('','Receipt_Line__c'));
        String query = util.generateQueryFromFieldSet('Receipt_Line__c', new Set<string>{ fieldsetName },additionalFields, whereClause);
        rlineslist = Database.query( query );
        result.records = rlineslist; 
        result.total = rlineslist.size();

        Receipt_Line__c rl = result.total> 0 ? (Receipt_Line__c)rlineslist[0]:null;
        if( rl!=null && rl.Company__r.Serial_Control__c != null && rl.Company__r.Serial_Control__c == 'At receipt and all processes'){
            result.additionalInfo = 'true';
        }
        if(rl !=null && rl.Sales_Order__r != null){
        	RMAType = rl.Sales_Order__r.Type__c;
        }
    	return result;
    }
    
    @RemoteAction 
    public static JsonResult getList(List<Id> lineIds, String docType) {
        JsonResult result = new JsonResult();
        list<ReceivingWrapper> records = new list<ReceivingWrapper>();

        try{
            if(docType == 'RMA'){
                records = ReceivingDocumentServiceV2.getReceivingLines(null, new Set<Id>(lineIds), new set<String>{
                        'Receipt_Line__c'.toLowerCase()});
            }
             else if( docType == 'Receiving Document'){
                records = ReceivingDocumentServiceV2.getReceivingLines(null, new Set<Id>(lineIds), new set<String>{
                        'Receipt_Line__c'.toLowerCase(), 'Receiving Document'.toLowerCase()
                });
            }
            if(ExceptionService.messages.size()>0)
            {
                for (Map<String, String> msg : ExceptionService.messages) {
                    result.addMessage(msg.get('message'), ApexPages.Severity.WARNING); //service would throw exceptions for errors
                    result.reason = 'WARNING';
                }     
            }            
            
            result.records = records;
            result.total = records.size();
        }
        catch (Exception e) {
            result.success = false;
            result.reason = 'FATAL_ERROR';
            result.addMessage('' + e.getMessage(), ApexPages.Severity.ERROR);
        }
        
        return result;
    }
    
    public String getreceiptLinesConfigJson() {
        String configStr = JSON.serialize(this.ReceiptLinesConfig);
          
        return configStr; 
    }
    
    @RemoteAction 
    public static string setFieldConfig(String docType) {
    		List<FieldInfo> fieldInfoList = new List<FieldInfo>();
    		/*
        	if(docType == 'PO'){
        		fieldInfoList = FieldInfo.fetchJsonFieldInfos('Receipt_Line__c', 'Receiving_Line');
        	}*/
        if (docType == 'RMA' || docType == 'Receiving Document') {
        		fieldInfoList = FieldInfo.fetchJsonFieldInfos('Receipt_Line__c', 'PutawayReceipts_Receiving');
        	}

            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            LinesFieldList = JSON.serialize(fieldInfoList);
            
            return LinesFieldList;
        
    }
    
    @RemoteAction 
    public static Map<String, String> setGridConfig(String docType){
        Map<String, String> gridconfigMap = new Map<String, String>();
        String docObjName='Receipt_Line__c';
        String rlinesfieldset='';

        /*
        if(docType == 'Purchase Order'){
            rlinesfieldset = 'PO_Receiving';
        }*/

        if (docType == 'RMA' || docType == 'Receiving Document') {

            rlinesfieldset = 'PutawayReceipts';
        }

        //Initialize Receiving Grid:

        Set<String> editableFields = new Set<String>();

        List<FieldInfo> editablefieldsdefined = FieldInfo.fetchJsonFieldInfos(docObjName, 'PutawayReceipts_Editable_Fields');
        for (Integer i = 0; i<editablefieldsdefined.size(); i++){
            editableFields.add(editablefieldsdefined[i].field);
        }


        FieldInfo fieldInfoItem, fieldInfoItem1, fieldInfoItem2;

        // get the master field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(docObjName, rlinesfieldset);

        fieldInfoItem1 = new FieldInfo('putawayType', 'Putaway Type', 'picklist');

        SelectListItem slist1 = new SelectListItem('Inventory', 'Inventory');
        slist1.selected = true;
        SelectListItem slist2 = new SelectListItem('Scrap', 'Scrap');
        SelectListItem slist3 = new SelectListItem('Inspection', 'Inspection');
        List<SelectListItem> selectlist = new List<SelectListItem>{slist1};
        
        if(docType != 'Receiving Document'){//KNDY-12791
            selectlist.add(slist2);
        }
        else{
            selectlist.add(slist3);
        }
        
        
        fieldInfoItem1.selectList = selectlist;
        fieldInfoItem1.editable = true;
        fieldInfoList.add(fieldInfoItem1);
        editableFields.add(fieldInfoItem1.field);

        // set all the fields as readonly
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            
            fieldInfoList[i].editable = editableFields.contains(fieldInfoList[i].field) ? true : false;
            fieldInfoList[i].field = 'rl.' + fieldInfoList[i].field;
        }

        masterFieldList = JSON.serialize(fieldInfoList);

        // get the detail field info list
        fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', 'Receipt_Info');
        fieldInfoItem = FieldInfo.fetchJsonFieldInfos('SKID__c', new String[] { 'Temporary_Value_Holder__c' })[0];
        fieldInfoItem.hidden = true;
        fieldInfoList.add(fieldInfoItem);

        fieldInfoItem2 = new FieldInfo('transactionUnitCost', 'Transaction Unit Cost', 'double');
        fieldInfoItem2.editable = true;
        fieldInfoItem2.scale = 6;
        fieldInfoList.add(fieldInfoItem2);

        for(Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].field = 'skid.' + fieldInfoList[i].field;
        }

        detailFieldList = JSON.serialize(fieldInfoList);


        // get the skid field info list
        fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c');
         for(Integer i = 0; i < fieldInfoList.size(); i++){
         	if(fieldInfoList[i].field.toLowerCase() == 'License_Plate_Number__c'){
        		fieldInfoList[i].validateLookupOnBlur = true;
        	}
            fieldInfoList[i].field = 'skid.' + fieldInfoList[i].field;
        }

        skidFieldList = JSON.serialize(fieldInfoList);

        /*
        if(docType == 'Purchase Order'){
            rlinesfieldset = 'PO_Receiving';
        }*/

        FieldInfo fiInt = new FieldInfo('','','integer');
        fiInt.editable = false;
        fieldInfoList = new list<FieldInfo>{fiInt};
        List<String> serialAttributesList = new list<String>();
        for( String serAttr : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes') ){
       	    serialAttributesList.add(serAttr.replace( KSE.namespaceUU, '').toLowerCase().trim()); 
       	}
       	serialAttributes = JSON.serialize(serialAttributesList);
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial',serialAttributesList.size() > 0 ? String.join(serialAttributesList, ',') : null, false));
        
        for(FieldInfo finfo : fieldInfoList){
        
            String field = finfo.field.replace(KSE.NamespaceUU, '');
            if(field.toLowerCase() == 'name'){
                finfo.field='SerialNameId';
                finfo.fieldType = 'reference';
                finfo.referenceTo = 'Serial__c';
            }
            else if( field.toLowerCase() == 'fixed_asset__c' ){
                fInfo.editable = false;
            }
            
        }
        serialFieldList = JSON.serialize(fieldInfoList);
		
		gridconfigMap.put('masterFieldList', masterFieldList);
		gridconfigMap.put('detailFieldList', detailFieldList);
		gridconfigMap.put('skidFieldList', skidFieldList);
		gridconfigMap.put('serialFieldList', serialFieldList);
		gridconfigMap.put('serialAttributes', serialAttributes);
		return gridconfigMap;
		
	}
  
    @RemoteAction
    public static string getrdHeaderFieldList(String dType) {
        
        String rdHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> editableFields = new Set<String>();
        
        // get the asn header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Receiving_Document__c', 'Putaway_Receiving');
        //PTP-577 Have fields read only on the asn Header
        List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Receiving_Document__c', 'Putaway_Receiving_Editable');
        for (Integer i = 0; i<fieldInfoListRO.size(); i++){
            if ((dType == 'RMA' && fieldInfoListRO[i].field.toLowerCase() != 'transaction_date__c') || dType == 'Receiving Document') {
        		editableFields.add(fieldInfoListRO[i].field);
        	}
        }
        
        fieldInfoList.remove(0); // Remove Id field from the list
        
        for(Integer i = 0; i < fieldInfoList.size(); i++) {
            if (editableFields.contains(fieldInfoList[i].field)){
                fieldInfoList[i].editable = true;
            }
            else{
                fieldInfoList[i].editable = false;
            }
        }
            
        rdHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return rdHeaderFieldList;           
        
    }
    
    @RemoteAction
    public static JsonResult getrdDetails(List<Id> lineIds, String dType) { 
        JsonResult result = new JsonResult();
        Set<Id> rdLineIds = new Set<Id>(lineIds);
        Set<Id> headerlineIds = new Set<Id>();
        List<Receiving_Document__c> rdlist = new list<Receiving_Document__c>();
        Receiving_Document__c rd;

        if (dType == 'RMA' || dType == 'Receiving Document') {
        	
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Receipt_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Receiving_Document__c','Receiving_Document__r.Name', 'Receiving_Document__r.Currency__r.Currency__c', 'Receiving_Document__r.Currency__r.Name', 'Receiving_Document__r.Company__r.Comp_Currency__c','Receiving_Document__r.Company__r.Name','Receiving_Document__r.Company__c',
                'Receiving_Document__r.Customer__r.Name','Receiving_Document__r.Customer__c','Receiving_Document__r.Currency__c', 'Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c',
                'Receiving_Document__r.Transaction_Type__c','Receiving_Document__r.Type__c','Receiving_Document__r.Transaction_Date__c'
            });
			soql.setWhereClause('Id =: rdLineIds');
			soql.setLimit(1);

			Receipt_Line__c receiptline = Database.query(soql.getQuery());
    		
    		rd = receiptline.Receiving_Document__r;
    		
	    	rd.Company__c = receiptline.Receiving_Document__r.Company__c;  
	    	rd.Company__r = receiptline.Receiving_Document__r.Company__r;
	    	rd.Customer__c = receiptline.Receiving_Document__r.Customer__c;
	    	rd.Customer__r = receiptline.Receiving_Document__r.Customer__r;
	    	rd.Currency__c = receiptline.Receiving_Document__r.Currency__c; 
	    	rd.Currency__r = receiptline.Receiving_Document__r.Currency__r; 	    	
	    	rd.Transaction_Type__c = receiptline.Receiving_Document__r.Transaction_Type__c; 
	    	rd.Type__c  = receiptline.Receiving_Document__r.Type__c;
	    	rd.Transaction_Date__c = receiptline.Receiving_Document__r.Transaction_Date__c;

        }
        
        rdlist.add(rd);
        result.records = rdlist; 
        return result;
    }
    
    @RemoteAction
    public static JsonResult putaway(List<ReceivingWrapper> rlWrapperList, List<String> polDateFields, List<String> skidDateFields, Receiving_Document__c rdoc, List<String> headerdatefields, String dType, Boolean UpdatedTransDate){
        
        Map<Id, Receiving_Document__c> headerToRDMap = new Map<Id, Receiving_Document__c>();
        JsonResult result = new JsonResult();
        Savepoint sp1 = Database.setSavepoint();
        Set<Id> rlinesSet = new Set<Id>();
        Set<Receiving_Document__c> rdlist = new Set<Receiving_Document__c>();
        List<Receiving_Document__c> rdlisttoupdate = new List<Receiving_Document__c>();
        try{
            String errorlines = '';
            
            for( ReceivingWrapper rw : rlWrapperList ){
                rlinesSet.add(rw.rl.Id);
                rdlist.add((Receiving_Document__c)rw.headerRecord);
                if(dType == 'Receiving Document' && UpdatedTransDate == true){
                	rdoc.Date_Received__c = rdoc.Transaction_Date__c;
                	rdlisttoupdate.add(rdoc);
                }
                
                for(SkidService3.serialWrapper sw : rw.serialWrapperList){
                    if(sw.skid.Quantity__c > 0){
                        KendoUtils.UpdateDateFields(rw.rl, polDateFields);
                    }
                    else{
                        errorlines = errorlines + rw.rl.get('Name') + ' ,';
                    }
                }
                
                if(!headerToRDMap.containskey(rw.headerRecord.id)){
                    
                    headerToRDMap.put(rw.headerRecord.id, rdoc); 
                }
            }
                       
            if (errorlines.length() > 0){
                errorlines = errorlines.subString(0,errorlines.length()-1);
                result.success = false;
                result.reason = 'ERROR';
                result.addMessage(Label.No_Quantities_Entered_To_Receive + ': ' + errorlines,ApexPages.Severity.ERROR);             
            }
            else{
            
                KendoUtils.UpdateDateFields(rdoc, headerdatefields);
                List<ReceivingWrapper> refreshedList;
                try{   
                	//Update RD for the transaction Date
	                if(rdlisttoupdate.size() > 0)
	                	DML.updateAsUser(rdlisttoupdate);    
	                	         
                    refreshedList = ReceivingDocumentServiceV2.checkUserErrors(rlWrapperList);
                    
                    // Display RD Headers as hyperlinks
	                List<String> rdHeaderLinks = new List<String>(); 
	                
	                for(Receiving_Document__c rd:rdlist){
	                    
	                    rdHeaderLinks.add('<a href="/' + rd.Id + '">' + rd.Name + '</a>');
	                }
	                
	                ReceivingDocumentServiceV2.receive(refreshedList, headerToRDMap);  
	                result.addMessage(Label.Changes_Saved_Inventory_Change_created  + rdHeaderLinks, ApexPages.Severity.CONFIRM);  
                 
                }
                catch(Exception e){
                    result.reason = 'ERROR';
                    throw e;
                }
            
                
            }
        }
        catch (Exception e) {
            Database.rollback(sp1);
            result.success = false;
            if( result.reason != 'ERROR') result.reason = 'FATAL_ERROR';
                result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
    
       
        return result;    
    }
    
    
    @RemoteAction
    public static list<String> refreshTrackedAttr( Location__c putAwayLocation , Item__c item){
                
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        Id locationId = putAwayLocation.id;
        
        SOQLUtil soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name','Bin_Tracked__c'
        });
        soql.setWhereClause('Id =:locationId');

        Location__c pal = Database.query(soql.getQuery());

        return SkidService3.trackedAttributes(null, pal, item); 
       
    }
    
    @RemoteAction
    public static JSONResult refreshLPNAttr(Item__c item, Decimal facilityId, String PkgUOMId){
       
        JsonResult result = new JsonResult();
        Item__c containerItem = new Item__c();
        Id pkgUOM,stockUOM;
        
        if(PkgUOMId !=null){
        	pkgUOM = (Id)PkgUOMId;
	    	stockUOM = (Id)item.Stocking_UOM__c;
	    	SOQLUtil soql = new SOQLUtil('UOM__c');
	        soql.addFields(new set<String>{'Package_Class__c','Package_Class__r.Default_Container_Item__c','Package_Class__r.Level__c',
	        'Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'});
	        soql.setWhereClause('Id =:pkgUOM');
	        
	        UOM__c pkgUOMRec = Database.Query(soql.getQuery());
	        map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
	       	itemsWithPackagingUOM.put(item , new Set<UOM__c>{pkgUOMRec});
	        map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
	           
	        containerItem = containersByItem.get(item.Id).get(pkgUOM);
        }
        
        List<String> addlFields = SkidService3.trackedAttributes(null, null, item, containerItem);
        
        List<object> records = (List<object>) addlFields;
        result.records = records;//JSON.serialize
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( item.Packaging_UOM__c, List<Id>.class );
        Decimal conversionFactor = KSE.getConversionFactor(item.Id,facilityId, pkgUOM,stockUOM,lstPkgUom);
        result.additionalInfo = String.valueOf(conversionFactor);
        
        return result; 
    }
}