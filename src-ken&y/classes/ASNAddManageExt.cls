public with sharing class ASNAddManageExt extends BaseController {
    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string pageTitle { get; set; }
    public ASN__c asn { get; set; }
    public static Integer lineNo {get; set;}


    public GridRelatedListController.GridRelatedListConfig asnLinesConfig {get; set;}      
    public String asnLinesFieldList = null;
    public String detailFieldList = null;
    public String skidFieldList = null;
    public String serialFieldList = null;
    public GridRelatedListController.GridRelatedListConfig purchaseOrderLinesConfig {get; set;}      
    public String purchaseOrderLinesFieldList = null;
    public static string serialAttributes { get;set;}
    public static Integer gridSize {get;set;}


    public String poID { get; private set; }
        
    public ASNAddManageExt(ApexPages.StandardController controller) {
        con = controller;
 
        poID = ApexPages.currentPage().getParameters().get('poID');
     
        try{
        if( controller.getRecord().id != null ){
     
            asn = (ASN__c) controller.getRecord();
            ID asnID = asn.ID;
            set<String> fieldStrings = new set<string>{'Id','Name'};
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','ASN__c') );
            String whereClause = 'Id =:asnID LIMIT 1';

		    SOQLUtil soql = new SOQLUtil('ASN__c', true, true);
		    soql.addFields(fieldStrings);
		    soql.setWhereClause(whereClause);
		    ASN__c tempASN = Database.query(soql.getQuery());
		    asn = tempASN;
            pageTitle = 'Advance Shipping Notice ' + asn.Name;
        }
        else if(poID == null || poID == '') {

            asn = new ASN__c();
            pageTitle = 'Advance Shipping Notice '; 
            CompanyService compServ = new CompanyService(controller);

            asn.Status__c = 'Draft';
            asn.Transaction_Date__c = system.now();
            asn.Company__c = CompanyService.getDefaultCompanyId();
            asn.Company__r = compServ.Company;
            asn.Currency__r = CompanyService.defaultTransactionCurrencyRec(asn.Company__c);
            if(asn.Currency__r != null){
               asn.Currency__c = CompanyService.defaultTransactionCurrencyRec(asn.Company__c).id;
            }
            asn.Transaction_Type__c = 'Purchase Order ASN';
            }   
        else {
                asn = new ASN__c();
                pageTitle = 'Advance Shipping Notice '; 
                asn.Status__c = 'Draft';
                asn.Transaction_Date__c = system.now();
                asn.Transaction_Type__c = 'Purchase Order ASN';
                
                set<String> fieldStrings = new set<string>{'Id','Name','FOB_term__r.FOB_Point__c', 'Company__r.Name', 'Supplier__r.Name', 'FOB_Term__r.Name', 'Currency__r.Id', 'Currency__r.Name'};
                fieldStrings.addAll( util.getAllCustomFieldsFromObject('','Purchase_Order__c' ));
                ID purchaseOrderID = ID.valueOf(poID);
                String whereClause = 'Id =:purchaseOrderID LIMIT 1';

                SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true, true);
                soql.addFields(fieldStrings);
                soql.setWhereClause(whereClause);
                Purchase_Order__c PO = Database.query(soql.getQuery());
            	if((PO.FOB_term__c == null ||(PO.FOB_term__c != null && PO.FOB_term__r.FOB_Point__c != 'Origin') )&& PO.status__c == 'Open'){
                  throw new ASNService.ASNServiceException(Label.FOB_term_is_required_to_create_ASN);
                } else {
                asn.Company__c = PO.Company__c;
                asn.Company__r = PO.Company__r;
                asn.Supplier__c = PO.Supplier__c;
                asn.Supplier__r = PO.Supplier__r;
                if(PO.FOB_Term__c != null) {
                    asn.FOB__c = PO.FOB_Term__c;
                    asn.FOB__r= PO.FOB_Term__r;
                }
                asn.Currency__c = PO.Currency__c;
                asn.Currency__r = PO.Currency__r;
//Populate facility from first PO Line.  

                set<String> poLinefieldStrings = new set<string>{'Id','Name', 'Delivery_Facility__r.Name', 'Delivery_Facility__r.Facility_Identifier__C'};
                poLinefieldStrings.addAll(util.getAllCustomFieldsFromObject('','Purchase_Order_Line__c'));
                String linewhereClause = 'Purchase_Order__c = :purchaseOrderID LIMIT 1';
                SOQLUtil linesoql = new SOQLUtil('Purchase_Order_Line__c', true, true);
		        linesoql.addFields(poLinefieldStrings);
		        linesoql.setWhereClause(linewhereClause);
		        Purchase_Order_Line__c poLine = Database.query(linesoql.getQuery());
                if(poLine != null) {
                    asn.Facility__c = poLine.Delivery_Facility__c;
                    asn.Facility__r = poLine.Delivery_Facility__r;
                }
            }

        } 
        
        Set<String> asnLinesAdditionalFields = new Set<String>();

        asnLinesAdditionalFields.addAll(new set<string>{'Id','Name'});
        
        // asn Lines Grid config
        asnLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        asnLinesConfig.uniqueId = 'ASNLinesGrid';
        asnLinesConfig.title = 'ASN Lines';
        asnLinesConfig.parentRecord = asn;
        asnLinesConfig.objectName = 'ASN_Line__c';  
        asnLinesConfig.parentField = 'ASN__c';
        asnLinesConfig.fieldset = 'ASN_Line';
        asnLinesConfig.buttons = 'delete, cancel, columnmenu, search';
        asnLinesConfig.additionalFields = String.join(new List<String>(asnLinesAdditionalFields), ',');  

        // Purchase Order Lines Grid config
        purchaseOrderLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        purchaseOrderLinesConfig.uniqueId = 'POLinesGrid';
        purchaseOrderLinesConfig.title = 'Purchase Order Lines';
        purchaseOrderLinesConfig.objectName = 'Purchase_Order_Line__c';  
        purchaseOrderLinesConfig.fieldset = 'ASN_New';
        purchaseOrderLinesConfig.buttons = 'columnmenu, search';

        //set the line no
        Integer maxLineNumber = 0;
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('ASN_Line__c', true, true); //enforceFLS=true, running in user mode.  aggregate query = true
        soql.addFields(new set<string>{
            'MAX(Line__c) maxLineNum'
        });
        Id asnId = asn.ID;
        soql.setWhereClause('ASN__c = :asnId');
        AggregateResult[] aggrResult = Database.query(soql.getQuery());


        maxLineNumber = Integer.valueOf( aggrResult[0].get('maxLineNum'));
        
        if (maxLineNumber == null) {
            lineNo = 1;
        }
        else{
            lineNo = maxLineNumber + 1;
        }
        getserialFieldList();
        } catch(Exception e){
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            System.debug(LoggingLevel.ERROR, e.getStackTraceString() + ' ' + e.getMessage());
        }    
    
    }
    
    public string getasnJson() {
        return JSON.serialize(asn);  
    }
    
    public string getasnHeaderFieldList() {
        String asnHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> readOnlyFields = new Set<String>();
        
        // get the asn header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('asn__c', 'asn_Header');
        //PTP-577 Have fields read only on the asn Header
        List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('asn__c', 'asn_Header_RO');
        for (Integer i = 0; i<fieldInfoListRO.size(); i++){
            readOnlyFields.add(fieldInfoListRO[i].field);
        }
        
        fieldInfoList.remove(0); // Remove Id field from the list
        
        for(Integer i = 0; i < fieldInfoList.size(); i++) {
            if (readOnlyFields.contains(fieldInfoList[i].field)){
                fieldInfoList[i].editable = false;
            }
        }
            
        asnHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return asnHeaderFieldList;
    }
    
    public string getasnAddlHeaderFieldList() {
        String asnAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getasnHeaderFieldList(), List<FieldInfo>.class);
        Set<String> readOnlyFields = new Set<String>();
        
        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }
        
        try {
            // get the asn addl header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('ASN__c', 'ASN_Additional_Info_Header');
            
            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('ASN__c', 'ASN_Header_RO');
            for (Integer i = 0; i<fieldInfoListRO.size(); i++){
                readOnlyFields.add(fieldInfoListRO[i].field);
            }
            
            fieldInfoList.remove(0);    // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                    if (fieldInfoList[i].field == 'Status__c') {  
                        fieldInfoList[i].editable = false;
                    }
                    else if (readOnlyFields.contains(fieldInfoList[i].field)){
                        fieldInfoList[i].editable = false;
                    }
                    
                    result.add(fieldInfoList[i]);
                }
            }
            
            asnAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            asnAddlHeaderFieldList = '';
        }
        
        return asnAddlHeaderFieldList;
    }
    
    public string getasnLinesConfigJson() {
        String configStr = JSON.serialize(this.asnLinesConfig);
          
        return configStr;
    }
    
    public string getasnLinesFieldList() {
        if (asnLinesFieldList == null && asnLinesConfig != null) {
            // get the asn lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(asnLinesConfig.objectName, asnLinesConfig.fieldset);

            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('ASN_Line__c', 'ASN_Line_RO');

            Set<String> readOnlyFields = new Set<String>();
            
            for (Integer i = 0; i<fieldInfoListRO.size(); i++){
                String fieldName = fieldInfoListRO[i].field;
                fieldInfoListRO[i].field = 'asnl.' + fieldName;
                readOnlyFields.add(fieldInfoListRO[i].field);
            }
            //PTP-577 Have fields read only in the asn lines grid
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = 'asnl.' + fieldName;
                if (readOnlyFields.contains(fieldInfoList[i].field)){
                    fieldInfoList[i].editable = false;
                }
            }
            asnLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return asnLinesFieldList;
    }

    public string getdetailFieldList() {

        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', 'Receipt_Info');
        FieldInfo fieldInfoItem = FieldInfo.fetchJsonFieldInfos('SKID__c', new String[] { 'Temporary_Value_Holder__c' })[0];
        fieldInfoItem.hidden = true;
            
        fieldInfoList.add(fieldInfoItem);
        for(Integer i = 0; i < fieldInfoList.size(); i++){
        	if(fieldInfoList[i].field.toLowerCase() == 'license_plate_number__c'){
        		fieldInfoList[i].validateLookupOnBlur = true;
        	}
            fieldInfoList[i].field = 'skid.' + fieldInfoList[i].field;
        }
        detailFieldList = JSON.serialize(fieldInfoList);
        
        return detailFieldList;
    }

    public string getskidFieldList() {

        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c');
        for(Integer i = 0; i < fieldInfoList.size(); i++){
        	if(fieldInfoList[i].field.toLowerCase() == 'license_plate_number__c'){
        		fieldInfoList[i].validateLookupOnBlur = true;
        	}
            fieldInfoList[i].field = 'skid.' + fieldInfoList[i].field;
        }
        
        skidFieldList = JSON.serialize(fieldInfoList);
        
        return skidFieldList;
    }
    
    public string getserialFieldList() {


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
                fi.fieldType = 'reference';
                fi.referenceTo = 'Serial__c';
            }
            else if( field.toLowerCase() == 'fixed_asset__c' ){
                fi.editable = false;
            }
        }


        serialFieldList = JSON.serialize(fiList);
        gridSize = fiList.size() * 150; 
        

        return serialFieldList;
    }
    
    public String getReturnUrl(){
        PageReference pageRef;
        
        if (asn != null && asn.Id != null ){
            pageRef =  new PageReference('/' + asn.Id);
        }
        else if(poID!= null){
            pageRef =  new PageReference('/' + poID); 
        }
        else {
            Schema.DescribeSObjectResult dsr = asn__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();
    }
    
    public string getPurchaseOrderLinesConfigJson() {
        String configStr = JSON.serialize(this.purchaseOrderLinesConfig);
          
        return configStr;
    }
    
    public string getPurchaseOrderLinesFieldList() {
        if (purchaseOrderLinesFieldList == null && purchaseOrderLinesConfig != null) {
            
            // get the purchase order lines field info list driven by a fieldset
            List<FieldInfo> poLineFieldInfoList = FieldInfo.fetchJsonFieldInfos(purchaseOrderLinesConfig.objectName, purchaseOrderLinesConfig.fieldset);
            
            // set the wrapper class prefix
            for(Integer i = 0; i < poLineFieldInfoList.size(); i++){
                if (poLineFieldInfoList[i].field == 'Name') {
                    poLineFieldInfoList[i].field = 'Purchase_Order_Line__c';
                    poLineFieldInfoList[i].fieldtype = 'reference';
                }
                else if (poLineFieldInfoList[i].field == 'Order_Quantity__c') {
                    poLineFieldInfoList[i].field = 'Quantity_Shipped__c';
                }
                else if (poLineFieldInfoList[i].field == 'Delivery_Location__c') {
                    poLineFieldInfoList[i].field = 'Location__c';
                }
                else if (poLineFieldInfoList[i].field == 'Purchase_UOM__c') {
                    poLineFieldInfoList[i].field = 'UOM__c';
                }
                else if (poLineFieldInfoList[i].field == 'Quantity_Still_Due__c') {
                    poLineFieldInfoList[i].field = 'Purchase_Order_Line__r.Quantity_Still_Due__c';
                }
                poLineFieldInfoList[i].field = 'asnl.' + poLineFieldInfoList[i].field;
                poLineFieldInfoList[i].editable = false; 
                
            }
            
            purchaseOrderLinesFieldList = String.escapeSingleQuotes(JSON.serialize(poLineFieldInfoList));
        }
        
        return purchaseOrderLinesFieldList;
    }
    
    @RemoteAction
    public static JsonResult getasnLinesByPurchaseOrderId(Id poId, Id facilityId, integer asnlineno) {   
        List<ASN_Line__c> result = new List<ASN_Line__c>(); 
        List<Purchase_Order_Line__c> polList = new List< Purchase_Order_Line__c >();
        List<ASNLineWrapper> asnlineswrapper = new List<ASNLineWrapper>();
        Set<String> addlFields = new Set<String>{'Item__c','Item__r.Source__c', 'Work_Order__c','Delivery_Facility__c', 'Name', 'Quantity_Still_Due__c', 'Item__r.Name', 'Item__r.Item_attribute__c', 'Item__r.Non_Inventory__c', 'Item__r.Source__c', 'Item__r.Stocking_UOM__c', 'Company__c', 'Company__r.Serial_Control__c', 'Sales_Order_Line__c','Purchase_UOM__c','Item__r.Stocking_UOM__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
            									'Item__r.Container__c','purchase_uom__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','purchase_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','purchase_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            									'Item_Specification__r.Item__r.Item_Attribute__c','Item_Specification__r.Item__r.Container__c','Item_Specification__r.Item__r.Container_Item__r.Container_Package_Class__c','Item_Specification__r.Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Item_Specification__r.Item__r.Container_Item__c','Item_Specification__r.Item__r.Packaging_UOM__c','Item_Specification__r.Item__r.Stocking_UOM__c','Purchase_UOM__c','Purchase_UOM__r.Name','Packaging_UOM__c','Packaging_UOM__r.Name','Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__r.Name','Item__r.Stocking_UOM__r.Package_Class__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            									'Item__r.Stocking_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Item__r.Stocking_UOM__r.Package_Class__r.Level__c','Purchase_UOM__r.Name','Purchase_UOM__r.Package_Class__c','Purchase_UOM__r.Package_Class__r.Default_Container_Item__c','Purchase_UOM__r.Package_Class__r.Level__c','Purchase_UOM__r.Name','Item__r.Container_Item__c','Item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
            									'Delivery_Facility__r.Facility_Identifier__c', 'Purchase_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Rental__c' };

        addlFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
        addlFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Item_Specification__r.item__r.item_attribute__r.','item_attribute__c') );
        addlFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Work_Order__r.Assembly_Item_Specification__r.Item__r.item_attribute__r.','item_attribute__c') );
        SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', TRUE);
        soql.addFields('ASN_New');
        soql.addFields(addlFields);
        if (facilityId == null)
            soql.setWhereClause('Purchase_Order__c = :poId AND Approved__c = true AND Quantity_Still_Due__c > 0 AND Consigned__c = false AND Status__c = \'Open\'' );
        else
            soql.setWhereClause('Purchase_Order__c = :poId AND Approved__c = true AND Quantity_Still_Due__c > 0 AND Delivery_Facility__c = :facilityID AND Consigned__c = false AND Status__c = \'Open\'' );
        Boolean serialTrackedflg = false;
        if( poId != null ){  
            polList = (database.query(soql.getQuery()));
            
        }
        integer l = asnlineno;
        if (polList.size() > 0) {
            
            for (Purchase_Order_Line__c poLine: polList) {
                ASN_Line__c asnl = new ASN_Line__c();
                asnl.Purchase_Order__c = poLine.Purchase_Order__c;
                asnl.Purchase_Order__r = poLine.Purchase_Order__r;
                asnl.Purchase_Order__r.Type__c = poLine.Purchase_Order__r.Type__c;
                asnl.Purchase_Order_Line__c = poLine.id;
                asnl.Purchase_Order_Line__r = poLine;
                asnl.Item__c = poLine.Item__c;
                asnl.Item__r = poLine.Item__r;
                if(poLine.Item__r.source__c == 'Outside Processing' && poline.Work_Order__c != null){
                 asnl.Item__r.Item_Attribute__c =  poline.Work_Order__r.Assembly_Item_Specification__r.Item__r.item_attribute__c;
                 asnl.Item__r.Item_Attribute__r =  poline.Work_Order__r.Assembly_Item_Specification__r.Item__r.item_attribute__r;  
                }else {
                asnl.Item__r.Item_Attribute__c = poLine.Item__r.Item_Attribute__c;
                asnl.Item__r.Item_Attribute__r = poLine.Item__r.Item_Attribute__r;
                }
                
                asnl.Unit_Price__c = poLine.Unit_Price__c;
                asnl.Quantity_Shipped__c = poLine.Quantity_Still_Due__c;
                asnl.Quantity_Received__c = 0;
                asnl.UOM__c = poLine.Purchase_UOM__c;
                asnl.UOM__r = poLine.Purchase_UOM__r;
                asnl.Facility__c = poLine.Delivery_Facility__c;
                asnl.Facility__r = poLine.Delivery_Facility__r;
                asnl.Location__c = poLine.Delivery_Location__c;
                asnl.Location__r = poLine.Delivery_Location__r;
                asnl.Status__c = 'New';
                asnl.Line__c = l;
                l++;

                result.add(asnl);
                
                if(poLine.Company__r != null && poLine.Company__r.Serial_Control__c == 'At receipt and all processes'){
                            
                    serialTrackedflg = true;
                } 
            }    
        }
		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
		for (ASN_Line__c asnl : result){
			Set<Id> pkgUOMIds = new Set<Id>();
			UOM__c uomObj;
			Purchase_Order_Line__c pol = asnl.Purchase_Order_Line__r;
			Item__c itemObj;
			itemObj = asnl.Item__r;
			Boolean subcontractASN = false;
			if(pol.Purchase_Order__r.Type__c == 'SubContract'){
        		itemObj = (Item__c)pol.getSObject('Item_Specification__r').getSObject('Item__r');
        		subcontractASN = true;
        		
			}
			if(!itemsWithPackagingUOM.containskey(itemObj)){
				itemsWithPackagingUOM.put(itemObj,new Set<UOM__c>{});	
			}
			
			pkgUOMIds = (set<Id>)JSON.deserialize(String.valueOf(itemObj.Packaging_UOM__c), set<Id>.Class);
                 
			if(!pkgUOMIds.contains(asnl.Purchase_Order_Line__r.Purchase_UOM__c)){
				uomObj = asnl.Item__r.Stocking_UOM__r;
				if(subcontractASN ==true){//In case of ASN based on Subcontract PO we only pass Id in UOMObj so all the required fields can be queried as part of getContainerforItems call..
					uomObj = new UOM__c(Id = asnl.Item__r.Stocking_UOM__c);
				}
				
			}
			else if(pkgUOMIds.contains(asnl.Purchase_Order_Line__r.Purchase_UOM__c)){
				uomObj = asnl.Purchase_Order_Line__r.Purchase_UOM__r;
				if(subcontractASN ==true){
					uomObj = new UOM__c(Id = asnl.Purchase_Order_Line__r.Purchase_UOM__c);
				}
			}
			itemsWithPackagingUOM.get(itemObj).add(uomObj);
		}
		
		map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
            
        for (ASN_Line__c asnl : result){
            Set<Id> pkgUOMSetIds = new Set<Id>();
            List<SkidService3.SerialWrapper> serialwrapperlist = new List<SkidService3.SerialWrapper>();
            List<Serial__c> serialList = new List<Serial__c>();
            SkidService3.SerialWrapper serialwrapper;
            Item__c itemObj;
            itemObj = asnl.Item__r;
            SKID__c skid = new SKID__c();
            skid.ASN_Line__c = asnl.id;
            skid.Type__c = SkidService3.SKID_TYPE_DRAFTINTRANSIT;
            skid.Item__c = asnl.Item__c;
            skid.Item__r = asnl.Item__r;
            skid.Item__r= asnl.Item__r;
            skid.Item__r.Item_Attribute__c = asnl.Item__r.Item_Attribute__c;
            skid.Item__r.Item_Attribute__r = asnl.Item__r.Item_Attribute__r;
			skid.Company__c = asnl.Purchase_Order_Line__r.Company__c;
            skid.Rental__c = asnl.Purchase_Order_Line__r.Rental__c;
			//skid.Packaging_UOM__c = asnl.Purchase_Order_Line__r.Purchase_UOM__c;
			//skid.Packaging_UOM__r = asnl.Purchase_Order_Line__r.Purchase_UOM__r;
			
			
			if(asnl.Purchase_Order_Line__r.Purchase_Order__r.Type__c == 'SubContract'){
        		itemObj = asnl.Purchase_Order_Line__r.Item_Specification__r.Item__r;
        	}
            pkgUOMSetIds = (set<Id>)JSON.deserialize(String.valueOf(itemObj.Packaging_UOM__c), set<Id>.Class);
              
			if(!pkgUOMSetIds.contains(asnl.Purchase_Order_Line__r.Purchase_UOM__c)){
				skid.Packaging_UOM__c = itemObj.Stocking_UOM__c;
				if(itemObj.Stocking_UOM__r !=null)
					skid.Packaging_UOM__r = itemObj.Stocking_UOM__r;
			}
			else if(pkgUOMSetIds.contains(asnl.Purchase_Order_Line__r.Purchase_UOM__c)){
				skid.Packaging_UOM__c = asnl.Purchase_Order_Line__r.Purchase_UOM__c;
				if(asnl.Purchase_Order_Line__r.Purchase_UOM__r !=null)
					skid.Packaging_UOM__r = asnl.Purchase_Order_Line__r.Purchase_UOM__r;
			}
			
            Serial__c ser = new Serial__c();
                
            serialList.add(ser);
               
            serialwrapper = new SKIDService3.SerialWrapper(skid, serialList);
                
            serialwrapperlist.add(serialwrapper);
            ASNLineWrapper asnlWrapper = new ASNLineWrapper(asnl,serialwrapperlist);
            Item__c containerItem = new Item__c();
            
            if(containersByItem.containskey(itemObj.Id))
            	containerItem = containersByItem.get(itemObj.Id).get(skid.Packaging_UOM__c);
            
            if(containerItem !=null){
            	skid.Container_Item__r = containerItem;
            	skid.Container_Item__c = containerItem.Id;
            }
            
            asnlWrapper.trackedAttributes = SKIDService3.trackedAttributes(null, null, itemObj,containerItem);
            if(asnlWrapper.serialWrapperList.size() > 0){
            	SKID__c sk = asnlWrapper.serialWrapperList[0].skid;
            	if(sk.Packaging_UOM__c != sk.Item__r.Stocking_UOM__c){
                	sk.Input_Quantity__c = asnlWrapper.conversionFactor;
                }
            }
                 
            asnlineswrapper.add(asnlWrapper);
        }
        
        JSONResult polineresult = new JSONResult();
        polineresult.records = asnlineswrapper;
        polineresult.total = asnlineswrapper.size();
        if (asnlineswrapper.size() == 0) {
            polineresult.addMessage(Label.No_PO_Lines_for_the_facility, ApexPages.Severity.ERROR);
            polineresult.success = false;
        }
        else{
            polineresult.success = true;
            if(serialTrackedflg){
                polineresult.additionalInfo = 'true';
            }
        }
        
        return polineresult;
     }
    
    @RemoteAction

        public static JsonResult getasnDetails(Id asnId) { 
        JsonResult result = new JsonResult();
        
        String objectName = 'asn__c';
        String headerFieldset = 'asn_Header';  
        String addlHeaderFieldset = 'asn_Additional_Info_Header';
        Set<String> addlFields = new Set<String> { 'Company__c','Total_Number_of_Lines__c' };  //KNDY-8765 Added the Total Number of Lines    

        SOQLUtil soql = new SOQLUtil(objectName);
        soql.addFields(headerFieldset);
        soql.addFields(addlHeaderFieldset);
        soql.addFields(addlFields);
        soql.setWhereClause('Id  = :asnId LIMIT 1');

        List<asn__c> asn = database.query(soql.getQuery());
        if( asn.size() == 1 && asn[0].Transaction_Date__c == null){
            asn[0].Transaction_Date__c = system.now();
        }
 
        result = new JsonResult(asn, asn.size());
        if( asn.size() > 0 && asn[0].Status__c == ASNService.ASN_STATUS_CANCELLED){
            result.addMessage('ASN is Cancelled. Please create a new ASN',ApexPages.Severity.INFO);
        }
           
        return result;
    }
    
    @RemoteAction 
    public static JsonResult getasnLines(GridRelatedListController.GridRelatedListConfig config) {


        Set<Id> asnLineIds = new Set<Id>();
        List<SKID__c> allskidlist = new List<SKID__c>();
        Map<Id,List<SKID__c>> asnLineToSkidMap = new Map<Id,List<SKID__c>>();
        JSONResult result = new JSONResult();

        List<ASN_Line__c> asnLines = new List<ASN_Line__c>();

        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        string whereClause = '';
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        

        List<ASNLineWrapper> asnlineswrapper = ASNService.getASNLineWrappers(new set<Id>{parentId}, whereClause);
        Boolean serialTrackedflg = false;
        for (ASNLineWrapper awrapper : asnlineswrapper){
           
           ASN_Line__c a = awrapper.asnl;
           asnLineIds.add(a.id);
           
           if(a.Company__r != null && a.Company__r.Serial_Control__c == 'At receipt and all processes'){
                            
               serialTrackedflg = true;
           }  
        }

        if(asnlineswrapper.size() >0){
            
            result.records = asnlineswrapper; 
            result.total = asnlineswrapper.size();
        }
        
        if(serialTrackedflg){
            result.additionalInfo = 'true';
        }
        
        return result;

        
    }
    
    @RemoteAction
    public static JsonResult cancelLines(List<ASNLineWrapper> asnLines) { 
        
        JsonResult result = new JsonResult();
        result =  ASNService.CancelCloseASNLines(asnLines, ASNService.ASN_LINE_STATUS_CANCELLED, false);
        return result;
    }
    
    @RemoteAction
    public static JsonResult closeLines(List<ASNLineWrapper> asnLines) { 
        
        JsonResult result = new JsonResult();
        result = ASNService.CancelCloseASNLines(asnLines, ASNService.ASN_LINE_STATUS_CLOSED, true);
        return result;
    }
    
   
    @RemoteAction
    public static Id queueSave(ASN__c asn, String action, List<String> headerDateFields) {
        return System.enqueueJob(new ConfirmJob( asn,  action,  headerDateFields));
    }

    @RemoteAction
    public static AsyncApexJob getJobStatus(Id jobId) {
        SOQLUtil jobQuery = new SOQLUtil('AsyncApexJob');
        jobQuery.addFields(new Set<String>{ 'Id', 'Status', 'ExtendedStatus' });
        jobQuery.setWhereClause('Id = :jobId');
        AsyncApexJob job = Database.query(jobQuery.getQuery());
        return job;
    }

    private class ConfirmJob implements Queueable {
        private ASN__c asn;
        private String action;
        private List<String> headerDateFields;
        

        public ConfirmJob(ASN__c asn, String action, List<String> headerDateFields) {
            this.asn = asn;
            this.action = action;
            this.headerDateFields = headerDateFields;
            
        }

        public void execute(QueueableContext qc) {
            JsonResult result = ASNAddManageExt.HeaderActions( asn,  action,  headerDateFields);
            if (!result.success) throw new ASNService.ASNServiceException(result.messages[0].get('message'));
        }
    }
  
    //Confirm, Undo Confirm, Cancel ASN
    @RemoteAction
    public static JsonResult HeaderActions(ASN__c asn, String action, List<String> headerDateFields) {
        
        KendoUtils.UpdateDateFields(asn, headerDateFields);
        Id asnId = asn.Id;
        
        JsonResult result = new JsonResult();
        Savepoint sp1 = Database.setSavepoint();
        try{    
            if( action == 'confirm' ){
                result = ASNService.ConfirmASN(asn);
            }
            else if(action == 'undoconfirm'){
                ASNService.undoConfirmASN(new set<Id>{asn.Id});
                result.addMessage('ASN is unconfirmed successfully.',ApexPages.Severity.CONFIRM);
            }
            else{
                string whereClause = ' and status__c != \'Cancelled\' ';
                result = ASNService.CancelCloseASNLines(ASNService.getASNLineWrappers(new set<Id>{asnId}, whereClause), ASNService.ASN_LINE_STATUS_CANCELLED, false);
                
                if( result.success ){
                    asn.Status__c = ASNService.ASN_STATUS_CANCELLED;
                    DML.updateAsUser(asn);
                    result.addMessage('ASN has been cancelled successfully.',ApexPages.Severity.CONFIRM);
                }
            }
        }
        catch(Exception e){
            Database.rollback( sp1 );
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result;
    }

    


    @RemoteAction
    public static JsonResult saveAction(ASN__c asn, List<String> headerDateFields, List<ASNLineWrapper> updatedList, List<ASNLineWrapper> newList, List<ASNLineWrapper> deletedList,List<SkidService3.SerialWrapper> deletedSerialWrappers, List<String> dateFields, List<String> detaildateFields) {

        KendoUtils.UpdateDateFields(asn, headerDateFields);
        List<ASNLineWrapper> newupdateLines = new List<ASNLineWrapper>(); //used to collect all SKIDs and save as one list
        List<SKIDService3.SerialWrapper> slWrapper = new List<SKIDService3.SerialWrapper>(); //create list of serial wrapper and pass it to skid service to create in-transit SKIDs
        JsonResult result = new JsonResult();
        List<ASN_Line__c> asnlinetoDelete = new List<ASN_Line__c>();
        List<SKID__c> skidstoDelete = new List<SKID__c>();
        Set<Id> skidIds = new Set<Id> ();
        map<String,LPN__c> lpnMap = new map<String,LPN__c>();
        
        Savepoint sp = Database.setSavepoint();
        if (updatedList.size() > 0) {
            String errorNewRecs = '';
            for (ASNLineWrapper line : updatedList) {
                KendoUtils.UpdateDateFields(line.asnl, dateFields);
                for(SkidService3.serialWrapper sw : line.serialWrapperList){
                    skidIds.add ( sw.skid.id);
                    if(sw.skid.Quantity__c > 0){
                        KendoUtils.UpdateDateFields(sw.skid, detaildateFields);
                        if(sw.skid.License_Plate_Number__c == null && sw.skid.Temporary_LPN_Holder__c != null) lpnMap.put(sw.skid.Temporary_LPN_Holder__c, new LPN__c(Name = sw.skid.Temporary_LPN_Holder__c));
                    }
                    else{
                        //If any of the new ASN lines do not have SKIDs, then throw an error during save
                        errorNewRecs = errorNewRecs + line.asnl.Line__c + ' ,';
                    }
                    
                }
                
                newupdateLines.add(line);
            }

        }
        
        // KNDY-14414
        SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        serialQuery.addAllCustomFields();
        serialQuery.setWhereClause('Skid__c IN :skidIds ');
        
        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
        
        for (Serial__c serial:Database.query(serialQuery.getQuery())) {
        	if (!serialMap.containsKey(serial.SKID__c)) {
        		serialMap.put(serial.SKID__c,new List<Serial__c>());
        	}
        	serialMap.get(serial.SKID__c).add(serial);
        }
        
        if (newList.size() > 0) {
            String errorNewRecs = '';
            for (ASNLineWrapper line : newList) {
                KendoUtils.UpdateDateFields(line.asnl, dateFields);
                
                for(SkidService3.serialWrapper sw : line.serialWrapperList){
                    
                    if(sw.skid.Quantity__c > 0){
                        KendoUtils.UpdateDateFields(sw.skid, detaildateFields);
                         if(sw.skid.License_Plate_Number__c == null && sw.skid.Temporary_LPN_Holder__c != null) lpnMap.put(sw.skid.Temporary_LPN_Holder__c, new LPN__c(Name = sw.skid.Temporary_LPN_Holder__c));
                    }
                     else{
                         //If any of the new ASN lines do not have SKIDs, then throw an error during save
                        errorNewRecs = errorNewRecs + line.asnl.Line__c + ' ,';
                    }
                    
                }
                newupdateLines.add(line);
            }
            if (errorNewRecs.length() > 0){
                errorNewRecs = errorNewRecs.subString(0,errorNewRecs.length()-1);
                result.success = false;
                result.addMessage(Label.ASN_Quantity_does_not_match_the_Quantity_Shipped+ errorNewRecs,ApexPages.Severity.ERROR);
            }

        }
        lpnMap = lpnMap.size() > 0 ? SkidService3.createLPNs(lpnMap) : new Map<String, LPN__c>();
        if (deletedList.size() > 0){
            String errorDelRecs = '';
            for (ASNLineWrapper line : deletedList) {
                if (line.asnl.id != null){
                    if (line.asnl.Status__c == 'New'){
                        asnlinetoDelete.add(line.asnl);
                        for(SkidService3.serialWrapper sw : line.serialWrapperList){
                            deletedSerialWrappers.add(sw);
                        }
                        
                    }
                    else{
                        errorDelRecs = errorDelRecs + line.asnl.Line__c + ' ,';
                    }

                }
            }
            if (errorDelRecs.length() > 0){
                //errorDelRecs = errorDelRecs.subString(0,errorDelRecs.length()-1);
                result.success = false;
                result.addMessage(Label.Only_new_ASN_lines_can_be_deleted,ApexPages.Severity.ERROR);
            } 
        }
        
        //Validate the required attributes, if missing then throw an error and skip 
        String missingAttr = '';
        String qtymismatch = ''; 
        String serialNomatch = '';
        String serialDuplicate = '';
        Map<Id,List<SKID__c>> SKIDsByASNL = new Map<Id,List<SKID__c>>();
        Map<String,Schema.SObjectField> skidFields = util.getFieldsMap('SKID__c');
        if (result.success == true){
            for (ASNLineWrapper tmp : newupdateLines){
                String missingAttrList = '';
                SKIDsByASNL.put(tmp.asnl.Id,new List<SKID__c>{});
                Boolean receiveInStockingUOM = false;
                double qty = 0;
                for(SkidService3.serialWrapper sw : tmp.serialWrapperList){
                	SKID__c skid = sw.skid;

                    String LPNNumber = skid.Temporary_LPN_Holder__c!=null?skid.Temporary_LPN_Holder__c: skid.License_Plate_Number__r.name;
                    if(LPNNumber!=null){
                            SKIDsByASNL.get(tmp.asnl.Id).add(skid);
                        }
                		Decimal conversionFactor = tmp.conversionFactor;
                		if(conversionFactor == null || skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c){
                			conversionFactor =1;
                			receiveInStockingUOM = true;
                		}
	                	if (skid.License_Plate_Number__c == null && skid.Temporary_LPN_Holder__c != null && lpnMap.containsKey(skid.Temporary_LPN_Holder__c)) {
	                        skid.License_Plate_Number__c = lpnMap.get(skid.Temporary_LPN_Holder__c).Id; 
	                    }
	                    map<String,Serial__c> userSpecifiedSerials = new map<String,Serial__c>();
                        if( tmp.asnl.Item__r.Non_Inventory__c == false || tmp.asnl.Item__r.Source__c =='Outside Processing'  ){
                            for( String attr : tmp.trackedAttributes ){
                                if(!SkidService3.attributesToExclude.contains(attr)){
                                    if(skidFields.get(attr).getDescribe().getType() != Schema.DisplayType.Boolean && ! String.isNotBlank( String.valueOf( sw.skid.get(attr)))){
                                        missingAttrList = missingAttrList + attr +' ,';
                                    }
                                }
                            }
                        }
                        
                        if(tmp.asnl.item__r.item_attribute__r != null && tmp.asnl.item__r.item_attribute__r.Serial_Number__c == true
                                    && tmp.asnl.Purchase_Order_Line__r.Company__r.Serial_Control__c == 'At receipt and all processes' && (( sw.skid.Quantity__c * conversionFactor) != sw.serialList.size())){
                                        
                             if(serialNomatch != '')
                                serialNomatch = serialNomatch + ', Line '+ tmp.asnl.line__c ;
                             else
                                serialNomatch = ' Line ' + tmp.asnl.line__c;
                        }
                        
                        
                       for( Serial__c ser : sw.serialList ){
                            
                                Id companyId = (Id)sw.skid.Company__c;
                                Id itemId = (Id)sw.skid.get('Item__c');
                                String uniqueKey = companyId+'-'+itemId+'-'+ser.Name;
                                
                                if(!userSpecifiedSerials.containsKey( uniqueKey )){
                                    userSpecifiedSerials.put(uniqueKey, ser);
                                }
                                else{
                                        if(serialDuplicate != '')
                                            serialDuplicate = serialDuplicate + ', '+ser.Name;
                                        else
                                            serialDuplicate = ser.Name;
                                    
                                }
                                    
                       } 
                        
                       qty = qty + KSE.addQuantityToField(sw.skid.Quantity__c,0);


                }


                Decimal convertFactor = 1;
                //Convert Qty Shipped to Stocking UOM if receiving in stocking..
                if(receiveInStockingUOM){
                	convertFactor = tmp.conversionFactor;
                }
                if (missingAttrList.length() > 0){
                    missingAttr = missingAttr + tmp.asnl.Line__c +' ,';
                }
                else if(tmp.asnl.Quantity_Shipped__c*convertFactor != qty) {//need to convert to line uom 2 cs to 4 ea allowed
                    qtymismatch = qtymismatch + tmp.asnl.Line__c +' ,';
                }
            }
            List<SKID__c> swSKIDs = new List<SKID__c>();
            if(SKIDsByASNL.values().size()>0){
                for(List<SKID__c> skidlist: SKIDsByASNL.values()){
                    swSKIDs.addAll(skidlist);
                }
            }
            validateLPNUniqueness(swSKIDs);


        }
        
        if (missingAttr.length() > 0){
            missingAttr = missingAttr.subString(0,missingAttr.length()-1);
            result.addMessage(Label.Required_attributes_are_missing_for_some_of_the_ASN_Lines+ missingAttr,ApexPages.Severity.ERROR);
            result.success = false;
        }
        if (qtymismatch.length() > 0){
            qtymismatch = qtymismatch.subString(0,qtymismatch.length()-1);
            result.addMessage(Label.ASN_Quantity_does_not_match_the_Quantity_Shipped+ qtymismatch,ApexPages.Severity.ERROR);
            result.success = false;
        }
        if (serialNomatch.length() > 0){
            result.addMessage(Label.ASN_Quantity_Not_Matching_Number_Of_Serials +serialNomatch,ApexPages.Severity.ERROR);
            result.success = false;
        }
        if (serialDuplicate.length() > 0){
            result.addMessage(serialDuplicate+': '+Label.Serial_Number_Specified_More_than_Once,ApexPages.Severity.ERROR);
            result.success = false;
        }
        
        
        Map<List<String>, Lot__c> createdLotMap = new Map<List<String>, Lot__c>();
        createdLotMap = ASNService.createLotstoLinktoSKID(newupdateLines, asn.Supplier__c, asn.Company__c); 

        if (result.success == true){
            
            list<asn__c> records = new list<asn__c>();        
       
            try {
                DML.checkUpsertAsUser(asn); upsert asn;
                List<ASN_Line__c> asnLines = new List<ASN_Line__c>();

                //Collect all ASN Lines
                for (ASNLineWrapper line : newList) {
                    ASN_Line__c asnl = line.asnl;
                    asnl.asn__c = asn.id;
                    asnl.Company__c = asn.Company__c;
                    asnl.Supplier__c = asn.Supplier__c;
                    asnl.Facility__c = asn.Facility__c;
                    asnLines.add(asnl);
                }
                
                for (ASNLineWrapper line : updatedList) {
                    asnLines.add(line.asnl);
                }

                DML.checkUpsertAsUser(asnLines); upsert asnLines;

                Boolean skipSave = false;
                list<SkidService3.SerialWrapper> serialWrappers = new list<SkidService3.SerialWrapper>();
                for (ASNLineWrapper tmp : newupdateLines){
                    for (SkidService3.serialWrapper sw : tmp.serialWrapperList){
                        List<Serial__c> serialList = new List<Serial__c>();
                        sw.skid.ASN_Line__c = sw.skid.ASN_Line__c == null ? tmp.asnl.id : sw.skid.ASN_Line__c;
                        sw.skid.Company__c = sw.skid.Company__c == null ? asn.Company__c : sw.skid.Company__c;
                        sw.skid.Item__r = tmp.asnl.Item__r;
                        sw.skid.Item__c = tmp.asnl.Item__c;
                        
                        if (sw.skid.Location__c == null) {
                            sw.skid.Facility2__c = tmp.asnl.Facility__c;
                            sw.skid.Facility2__r = tmp.asnl.Facility__r;
                            sw.skid.Location__c = tmp.asnl.Location__c;
                        } else {
                            sw.skid.Facility2__c = sw.skid.Location__r.Facility__c;
                            sw.skid.Facility2__r = sw.skid.Location__r.Facility__r;
                        }
                        
                        if (sw.skid.Lot_Number__c != null){
                            List<String> uniqueString = ASNService.lotUniqueKey(sw.skid); 
                            sw.skid.Lot__c = createdLotMap.get( uniqueString ).id;// this map should always contain the unique string and the created lot as we have already created the ones that didnt exist.   
                            sw.skid.Lot_Number__c = createdLotMap.get( uniqueString ).Name;
                        }
                        if(tmp.asnl.Item__r.Item_Attribute__c != null && tmp.asnl.Item__r.Item_Attribute__r.Serial_Number__c == true){
                            Serial__c ser = new Serial__c();
                            if( serialMap.containsKey ( sw.skid.id) ){
                            	serialList = serialMap.get(sw.skid.id);
                            }
                            else{
                                serialList.add(ser);
                            }
                    
                        }
                        serialWrappers.add(sw);
                    }
                }
                
                for( SkidService3.SerialWrapper sw : deletedSerialWrappers ){
                    sw.skid.Quantity__c = 0;
                    serialWrappers.add(sw);
                }
                
                //Invoke skid service to create In-Transit SKIDs
                Map<String,Boolean> configMap = new Map<String,Boolean>{
                    SkidService3.CREATE_SERIAL => true,
                    SkidService3.UPDATE_SKID_QUANTITY => true,
                    SkidService3.DELETE_SKIDS => true,
                    SkidService3.ALLOW_SERIAL_REENTRY => false,
                    SkidService3.VOID_SERIALS => true
                };
                //Include ASN Line as an attribute to create unique SKID per ASN Line - to prevent updating of SKIDs when skids come from multiple ASN Lines
                List<String> attributes = new List<String>();
                attributes = SKIDService3.attributesForPutaway();
                attributes.add('ASN_Line__c');
                //KNDY-12869 when attributes changes this will delete extra in transit skid .
                 set<Id> asnLineIds = new set<Id>();
                 set<Id> inTransitSkidIds = new set<Id>();
                
                if (serialWrappers.size() > 0){
                
                    map< list<String>, SkidService3.SerialWrapper > toSkids = SkidService3.putAwayService(serialWrappers, attributes, configMap);
                
                    for( SkidService3.SerialWrapper sw : toSkids.values()){
                        asnLineIds.add(sw.skid.ASN_Line__c);
                        inTransitSkidIds.add(sw.skid.Id);
                    }
                
                    String whereClause = ' ASN_Line__c IN:asnLineIds and Id NOT IN:inTransitSkidIds ';
                
                    SOQLUtil skidQuery = new SOQLUtil('SKID__c');
                
                    skidQuery.addAllCustomFields();
                
                    skidQuery.setWhereClause(whereClause);
                
                    List<SKID__c> inTransitSkidsToDelete = (list<SKID__c>) Database.query(skidQuery.getQuery());
                
                    if(inTransitSkidsToDelete.size() > 0){
                
                        DML.deleteAsSystem(inTransitSkidsToDelete);
                
                    }
                
                }

                //Delete ASN Lines based on lines selected in UI if the validation passes
                if (deletedList.size() > 0) {
                    DML.deleteAsUser(asnlinetoDelete);
                }
                records.add(asn);
                result.records = records;
                result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
            }
            catch (Exception e) {
            	system.debug(LoggingLevel.ERROR, e.getStackTraceString());
                Database.rollback(sp);
                result.success = false;
                
                result.addMessage('An error occured: ' + e.getMessage(),ApexPages.Severity.ERROR);
                
            }
        }
        return result;
    }

    public static void validateLPNUniqueness(List<SKID__c> SKIDs){


        List<String> Attributes = new List<String>{'Temporary_LPN_Holder__c', 'License_Plate_Number__c'};
        Map<String,SKID__c> skidsByKey = new Map<String,SKID__c>();
        Set<String> swKeySet = new Set<String>();
        Set<String> LPNNumbers = new Set<String>();

        for(SKID__c skid:SKIDs ){
            string lpnNumber = skid.Temporary_LPN_Holder__c!=null?skid.Temporary_LPN_Holder__c: skid.License_Plate_Number__r.Name;
            if(swKeySet.contains(lpnNumber)){
                // validate duplicate lpns on the same asn page.
                Throw new CustomException('LPN Number Exists');
            }
            else{
                // to validate across the system
                swKeySet.add(lpnNumber);
            }
            LPNNumbers.add(lpnNumber);
        }

        List<String> skidtypes = new List<String>{SkidService3.SKID_TYPE_INTRANSIT, SKIDService3.SKID_TYPE_LOCATION};
        for(SKID__c skid :[select id,name,License_Plate_Number__r.name,Temporary_LPN_Holder__c from SKID__c where License_Plate_Number__r.Name In: LPNNumbers and Id Not In:SKIDs and Type__c IN :skidtypes ]){
            string lpnNumber = skid.Temporary_LPN_Holder__c!=null?skid.Temporary_LPN_Holder__c: skid.License_Plate_Number__r.Name;
            skidsByKey.put(lpnNumber, skid);
        }


        swKeySet.retainAll(skidsByKey.keyset());
        if(swKeySet.size()>0){
            Throw New CustomException('LPN Already Exists');
        }
        return;
    }

    public class ASNLineWrapper{
        
        public list<SkidService3.SerialWrapper> serialWrapperList { get; set; }
        public ASN_Line__c asnl {get; set;}
        public list<String> trackedAttributes { get; set; }
        public Decimal conversionFactor{get;set;} { conversionFactor = 1; }

        public ASNLineWrapper(){
            this.asnl = asnl;
        }
        
         public ASNLineWrapper(ASN_Line__c asnline, list<SkidService3.SerialWrapper> swlist ){ 
        
            this.asnl = asnline;
            
            if(asnline.Purchase_Order_Line__r != null)
                conversionFactor = KSE.getConversionFactor(asnline.Purchase_Order_Line__r);
            
            if(serialWrapperList == null ) serialWrapperList = new List<SkidService3.SerialWrapper>();
            
            serialWrapperList.addAll(swlist);
            
        }

    }
        
}