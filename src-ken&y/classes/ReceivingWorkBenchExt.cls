public with sharing class ReceivingWorkBenchExt extends BaseController{
    
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();  
    public Boolean isHideResultsOnPageLoad {get; set;}  
    public static list<SObject> rlineslist;
    public Id defaultFacility{ get; set;}
    public Id currencyFilterID{ get; set;}    
    public Boolean tabView { get; set;} { tabView = true; }
    public Boolean errorOnPageLoad {get;set;}{errorOnPageLoad = false;}
    public static string masterFieldList { get; set; }
    public static string detailFieldList { get; set; }
    public static string skidFieldList { get; set; }
    public static string serialFieldList { get; set; }
    public static string serialAttributes { get;set;}
    public Boolean hideReceiveButton { get; set; } { hideReceiveButton = false; }          
    public static Integer gridSize {get;set;}
    public string HelpURL{get;set;}
    public static Set<String> rmaTypes = new Set<String>{SalesOrderService.SO_TYPE_RMA, SalesOrderService.SO_TYPE_RMA_REPLACEMENT, SalesOrderService.SO_TYPE_RMA_REPAIR};

    public ReceivingWorkBenchExt() {
       
        isHideResultsOnPageLoad = true;
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpReceivingWorkbench';
        
        List<User_Preference__c> u = [select id, Default_Company__c, Default_Facility__c from User_Preference__c where ownerId = :UserInfo.getUserID() limit 1];    
        if (u.size() > 0){
            if (u[0].Default_Facility__c != null)
                defaultFacility = u[0].Default_Facility__c;
        }   
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        FieldInfo fi = new FieldInfo('','','integer');
        fi.editable = false;
        fieldInfoList = new list<FieldInfo>{fi};
        
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
        gridSize = fieldInfoList.size() * 150; 

    }
    
    @RemoteAction 
    public static string getrdHeaderFieldList(String doctype) {
        
        String rdHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> editableFields = new Set<String>();
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        List<FieldInfo> fieldInfoListRO = new List<FieldInfo>();
        
        if (doctype == 'RMA') {
            fieldInfoList = FieldInfo.fetchJsonFieldInfos('Receiving_Document__c', 'Putaway_Receiving');
        
            fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Receiving_Document__c', 'Putaway_Receiving_Editable');
        }
        else{
            fieldInfoList = FieldInfo.fetchJsonFieldInfos('Receiving_Document__c', 'RD_Receiving');
        
            fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Receiving_Document__c', 'RD_Receiving_Editable');
        }
       
        
        for (Integer i = 0; i<fieldInfoListRO.size(); i++){
            editableFields.add(fieldInfoListRO[i].field);
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
    public static JsonResult getrdDetails(List<Id> lineIds, String dType, String transcurrency) { 
        JsonResult result = new JsonResult();
        Set<Id> rdLineIds = new Set<Id>(lineIds);
        Set<Id> headerlineIds = new Set<Id>();
        List<Receiving_Document__c> rdlist = new list<Receiving_Document__c>();
        Receiving_Document__c rd = new Receiving_Document__c();
        
        //Get Currency Details:
        
        SOQLUtil soql = new SOQLUtil('Currency__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{'Id','Name','Currency__c'});
		soql.setWhereClause('Id = :transcurrency');
		soql.setLimit(1);

		Currency__c currencycode = Database.query(soql.getQuery());
        
        rd.Transaction_Date__c = system.now();
        rd.Currency__c = currencycode.Id;
        rd.Currency__r = currencycode;
        
        if(dType == 'Purchase Order'){
            
            Purchase_Order_Line__c poline = [select Id, Purchase_Order__c,Supplier__c,Supplier__r.Name, Company__c, Company__r.Name,
                                              Purchase_Order__r.Currency__c, Company__r.Comp_Currency__c,Purchase_Order__r.Currency__r.ISO_Code__c,Purchase_Order__r.Type__c from Purchase_Order_Line__c where Id =: rdLineIds limit 1];
            
            rd.Currency__c = poline.Purchase_Order__r.Currency__c;
            rd.Company__c = poline.Company__c;  
            rd.Company__r = poline.Company__r;
            rd.Supplier__c = poline.Supplier__c;
            rd.Supplier__r = poline.Supplier__r;    
        
            rd.Transaction_Type__c = 'Purchase Order Receipt'; 
            rd.Type__c  = 'Purchase Order Receipt';
                        
        }
        else if(dType == 'ASN'){
            
        ASN_Line__c asnline = [select Id, ASN__c,Supplier__c,Supplier__r.Name, Company__c, Company__r.Name, Company__r.Comp_Currency__c, ASN__r.Carrier__c,
                                ASN__r.Packing_Slip_Number__c, ASN__r.Number_of_Boxes__c, ASN__r.Tracking_Number__c, ASN__r.Currency__c,
                                ASN__r.FOB__c, ASN__r.FOB__r.FOB_Point__c, Purchase_Order__r.Currency__c, Purchase_Order__r.Currency__r.ISO_Code__c
                                from ASN_Line__c where Id =: rdLineIds limit 1];
        rd.Currency__c = asnline.Purchase_Order__r.Currency__c;    
        rd.Company__c = asnline.Company__c;  
        rd.Company__r = asnline.Company__r;
        rd.Supplier__c = asnline.Supplier__c;
        rd.Supplier__r = asnline.Supplier__r;           
            
        
        rd.Packing_Slip_Number__c = asnline.ASN__r.Packing_Slip_Number__c;  
        rd.Number_of_Boxes__c = asnline.ASN__r.Number_of_Boxes__c;
        rd.Tracking_Number__c = asnline.ASN__r.Tracking_Number__c;  
        rd.Carrier__c = asnline.ASN__r.Carrier__c;
        rd.Type__c  = 'Purchase Order Receipt';
        
        if(asnline.ASN__r.FOB__r.FOB_Point__c == 'Origin'){
            rd.Transaction_Type__c = 'In-Transit Purchase Order Receipt';           
        }
        else{
            rd.Transaction_Type__c = 'Purchase Order Receipt'; 
        }

        } else if (dType == 'RMA') {
            
            Sales_Order_Line__c soline = [select Id, Sales_Order__c, Sales_Order__r.Type__c, Company__r.Comp_Currency__c,Fulfillment_Source__c, Returned_To_Vendor__c, Sales_Order__r.Customer__c,Sales_Order__r.Customer__r.Name, Company__c, Company__r.Name, Currency__c, Sales_Order__r.Currency__c from Sales_Order_Line__c where Id =: rdLineIds limit 1];
            
            rd.Currency__c = soline.Sales_Order__r.Currency__c; 
            rd.Company__c = soline.Company__c;  
            rd.Company__r = soline.Company__r;
            rd.Customer__c = soline.Sales_Order__r.Customer__c;
            rd.Customer__r = soline.Sales_Order__r.Customer__r;
            
            String sordertype = soline.Sales_Order__r.Type__c;
            if (sordertype == SalesOrderService.SO_TYPE_RMA || sordertype == SalesOrderService.SO_TYPE_RMA_REPLACEMENT) {
                if(soline.Fulfillment_Source__c == 'Drop Ship' && soline.Returned_To_Vendor__c == true){
                    rd.Transaction_Type__c = InventoryTransactionService.LOGICAL_RMA_RECEIPT;
                    rd.Type__c = InventoryTransactionService.LOGICAL_RMA_RECEIPT;
                }
                else{
                    rd.Transaction_Type__c = 'RMA Receipt';
                    rd.Type__c = 'RMA Receipt';
                }
                
            } else if (sordertype == SalesOrderService.SO_TYPE_RMA_REPAIR) {
                rd.Transaction_Type__c = 'RMA Receipt For Repair';
                rd.Type__c = 'RMA Receipt For Repair';
            }

        }
        else if(dType == 'Transfer Order'){
        	set<String> fieldStrings = new set<string>{ 'ID','Name','Shipping_Item__c','Shipping_Item__r.Name','Shipping_Item__r.Class__c','Shipping_Company__c','Shipping_Company__r.Name','Shipping_Company__r.Comp_Currency__c',
                              'Quantity_Backordered__c','Shipping_Company__c', 'Quantity_Ordered__c','Quantity_Shipped__c','Ship_From_Location__c', 'Shipping_Item__r.Stocking_UOM__r.Name',
                              'Required_Date__c','Status__c','Receiving_Item__r.Name','Receiving_Item__c', 'Order__r.Currency__c'};
            
            
            String whereClause = 'Order__c =:OrderId  and Status__c=\'Open\' and Order__r.Status__c =\'Open\' and Quantity_To_Ship__c > 0';
        
		    SOQLUtil tordersoql = new SOQLUtil('Order_Line__c');
		    tordersoql.addFields(fieldStrings);
		    tordersoql.setWhereClause('Id =: rdLineIds Limit 1');
        	
        	Order_Line__c toline = (Order_Line__c)Database.query(tordersoql.getQuery());
        	
        	rd.Currency__c = toline.Order__r.Currency__c;
            rd.Company__c = toline.Shipping_Company__c;  
            rd.Company__r = toline.Shipping_Company__r;
            
            rd.Transaction_Type__c = 'Transfer Order Receipt'; 
            rd.Type__c  = 'Transfer Order Receipt';
        }
        
        rdlist.add(rd);
        result.records = rdlist; 
        return result;
    }   
        
    @RemoteAction 
    public static JsonResult getLinesToReceive(String config, String FacilityId, String ItemId, String SupplierId, String FOBId, String docnumfilter, String customerFilter, String currencyFilter, List<KendoUtils.FilterDescriptor> filters, String ponumberfilter) {
                
        GridRelatedListController.GridRelatedListConfig receivingLinesConfig = (GridRelatedListController.GridRelatedListConfig)JSON.deserialize(config, GridRelatedListController.GridRelatedListConfig.class);
        
        JsonResult result = new JsonResult();
        String sobjectName, sourceName, fieldsetName;
        Date dateField; 
                
        fieldsetName = receivingLinesConfig.fieldset;
        sourceName = receivingLinesConfig.objectName;
        String uniqueId = receivingLinesConfig.uniqueId;
		
		Set<String> additionalFields;
        
        if(sourceName == 'Order_Line__c'){
        	additionalFields = new set<string>{'Id','Name', 'Receiving_Company__r.Serial_Control__c','Deliver_To_Facility__r.Name','Deliver_To_Facility__c', 'Deliver_To_Facility__r.Facility_Identifier__c'};
        }
        else{
        	additionalFields = new set<string>{'Id','Name', 'Company__r.Serial_Control__c'};
        }
        
        additionalFields.addAll(util.getAllCustomFieldsFromObject('',sourceName));
        
        List<String> filterCriteria = new List<String>();
        
        if(sourceName != 'Sales_Order_Line__c' && filters != null)
            filterCriteria = KendoUtils.getFilterCriteria(filters);
        
        
        //If any of the filter is filled in, frame the query accordingly       
       
        String whereClause = '';
        String sortbyClause = '';
        FieldInfo fieldInfoItem;
        
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }
        
        if(sourceName == 'Purchase_Order_Line__c'){
        	additionalFields.addAll(new set<String>{'Item__r.Stocking_UOM__c','Purchase_UOM__c','Purchase_UOM__r.Name','Work_Order__r.Type__c','Purchase_Order__r.FOB_Term__r.Id','Purchase_Order__r.Type__c ','Purchase_Order__r.Approval_Status__c', 'Purchase_Order__r.FOB_Term__r.FOB_Point__c', 'Purchase_Order__r.Status__c','Status__c','Quantity_Still_Due__c', 'Delivery_Facility__r.Facility_Identifier__c'});
        	
            if(!String.isBlank(whereClause))        
                whereClause += '  and Status__c = \'Open\' ';        
            else                    
                whereClause = 'Status__c = \'Open\'';   
                
            if(!String.isBlank(docnumfilter)){              
                whereClause += ' and Purchase_Order__c = :docnumfilter';
            }
            
            if (!String.isBlank(FacilityId)){
                whereClause += ' and Delivery_Facility__c = :FacilityId';               
            }

            if(!String.isBlank(SupplierId)){
                whereClause += ' and Supplier__c = :SupplierId';
            }
                
            if (!String.isBlank(FOBId)){
                whereClause += ' and Purchase_Order__r.FOB_Term__c = :FOBId';               
            }
            
            if (!String.isBlank(ItemId)){           
                whereClause += ' and Item__c = :ItemId';            
            }
            
            if(!String.isBlank(currencyFilter)){
                whereClause += ' and Purchase_Order__r.Currency__c = :currencyFilter';
            }
            
        }else if(sourceName == 'ASN_Line__c'){          
            sortbyClause = 'ASN__c'; 
            additionalFields.addAll(new set<String>{'Purchase_Order_Line__r.Operation_Tracking__c','Status__c','Purchase_Order__r.Approval_Status__c','ASN__r.Status__c','Purchase_Order_Line__r.Work_Order__r.Type__c', 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c'}); 
            
            if(!String.isBlank(whereClause))
                whereClause += '  and Status__c = \'Open\' and Quantity_Shipped__c >0';          
            else
                whereClause = 'Status__c = \'Open\' and Quantity_Shipped__c >0'; 
            
            
            if(!String.isBlank(docnumfilter)){
            	whereClause += ' and ASN__c = :docnumfilter';
            }
        
            if (!String.isBlank(FacilityId)){
                whereClause += ' and Facility__c = :FacilityId';                
            }

            if(!String.isBlank(SupplierId)){
                whereClause += ' and Supplier__c = :SupplierId';
            }
              
            if (!String.isBlank(FOBId)){
                whereClause += ' and ASN__r.FOB__c = :FOBId';               
            }
          
            if (!String.isBlank(ItemId)){           
                whereClause += ' and Item__c = :ItemId';            
            }
            
            if(!String.isBlank(currencyFilter)){
                whereClause += ' and ASN__r.Currency__c = :currencyFilter';
            }
            
            if(!String.isBlank(ponumberfilter)){                
                whereClause += ' and Purchase_Order__c =:ponumberfilter';           
            } 
          
        }
        else if(sourceName == 'Sales_Order_Line__c'){
            sortbyClause = 'Sales_Order__c';
            String filterType;
            additionalFields.addAll(new set<String>{'Status__c','Sales_Order__r.Type__c','Quantity_Ordered__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'});
            
            whereClause = 'Status__c = \'Open\' and Quantity_Ordered__c < 0 and Sales_Order__r.Type__c IN :rmaTypes';
                
            if(!String.isBlank(docnumfilter)){              
                whereClause += '  and Sales_Order__c = :docnumfilter';
            }
            
            if (!String.isBlank(FacilityId)){
                whereClause += ' and Ship_From_Location__r.Facility__c = :FacilityId';              
            }
            
            if (!String.isBlank(ItemId)){           
                whereClause += ' and Product__r.Item__c = :ItemId';         
            }
            
            if(!String.isBlank(customerFilter)){
                whereClause += ' and Sales_Order__r.Customer__c = :customerFilter';
            }
            
            if(!String.isBlank(currencyFilter)){
                whereClause += ' and Sales_Order__r.Currency__c = :currencyFilter';
            }
        }
        if(sourceName == 'Order_Line__c'){
        	sortbyClause = 'Order__c';
            additionalFields.addAll(new set<String>{'Receiving_Item__r.Stocking_UOM__c','Packaging_UOM__c','Packaging_UOM__r.Name','Order__r.Status__c ','Status__c','Quantity_Still_Due__c','Receiving_Company__r.Name','Receiving_Company__r.Serial_Control__c', 'Shipping_Item__r.Packaging_UOM__c', 'Ship_From_Facility__r.Facility_Identifier__c'});
        	
            if(!String.isBlank(whereClause))        
                whereClause += '  and Status__c = \'Open\'';        
            else                    
                whereClause = 'Status__c = \'Open\'';   
                
            if(!String.isBlank(docnumfilter)){              
                whereClause += ' and Order__c = :docnumfilter';
            }
            
            if (!String.isBlank(FacilityId)){
                whereClause += ' and Deliver_To_Facility__c = :FacilityId';               
            }
             
            if (!String.isBlank(ItemId)){           
                whereClause += ' and Receiving_Item__c = :ItemId';            
            }
            
            if(!String.isBlank(currencyFilter)){
                whereClause += ' and Order__r.Currency__c = :currencyFilter';
            }
            
        }
         
          
        if(sourceName == 'Purchase_Order_Line__c'){
            whereClause += ' ORDER BY Company__c, Purchase_Order__c , Purchase_Order__r.Delivery_Facility__c , Supplier__c , Purchase_Order__r.FOB_Term__c , Need_Date__c DESC';
        }
        else{
            whereClause += ' ORDER BY '+sortbyClause +' DESC';
        }
        
        
        additionalFields.addAll(util.getAllCustomFieldsFromObject('',sourceName));
        
        SOQLUtil soql = new SOQLUtil(sourceName);
        soql.addFields(fieldsetName);
        soql.addFields(additionalFields);
        soql.setWhereClause(whereClause);

        rlineslist = Database.query(soql.getQuery());
        result.success = true;
        
        //checkSearchErrors
        
        List<Purchase_Order_Line__c>POlineslist = new List<Purchase_Order_Line__c>();
    	List<ASN_Line__c>asnlineslist = new List<ASN_Line__c>();
    	List<Sales_Order_Line__c>openSOlineslist = new List<Sales_Order_Line__c>();
    	List<Order_Line__c>openTOlineslist = new List<Order_Line__c>();
    	
    	
    	Boolean asnNotConfirmed = false;
    	Boolean fobOriginPO = false;
    	Company__c companyObj;
    	if(!String.isBlank(docnumfilter)){
    		for(SObject obj:rlineslist){
    			if(obj.getSObjectType() == Purchase_Order_Line__c.sObjectType){
	    			
	    			if(obj.getSObject('Purchase_Order__r').get('Type__c') == 'Drop Ship'){
	    				result.addMessage(Label.Cannot_Receive_DropShip_PO,ApexPages.Severity.ERROR);
	            		result.success = false;
	    			}
	    			if(obj.getSObject('Purchase_Order__r').getSObject('FOB_Term__r') != null && obj.getSObject('Purchase_Order__r').getSObject('FOB_Term__r').get('FOB_Point__c') == 'Origin' && fobOriginPO!=true){
	    				fobOriginPO = true;
	    			}
	    			
	    			if(obj.get('Status__c') == 'Open'){
	    				POlineslist.add((Purchase_Order_Line__c)obj);
	    			}
	    			
	    			
	    		}
	    		else if(obj.getSObjectType() == ASN_Line__c.sObjectType){
	    			
	    			if(obj.get('Status__c') == 'Open'){
	    				asnlineslist.add((ASN_Line__c)obj);
	    			}
	    			
	    			
	    		}
	    		else if(obj.getSObjectType() == Sales_Order_Line__c.sObjectType){
	    			
	    			if(!rmaTypes.contains((String)obj.getSObject('Sales_Order__r').get('Type__c'))){
	    				result.addMessage(Label.Cannot_Receive_SO_Type,ApexPages.Severity.ERROR);
	    				result.success = false;
	    			}
	    			if(obj.get('Status__c') == 'Open'){
	    				openSOlineslist.add((Sales_Order_Line__c)obj);
	    			}
	    			
	    		}
	    		else if(obj.getSObjectType() == Order_Line__c.sObjectType){
	    			
	    			if(obj.get('Status__c') == 'Open'){
	    				openTOlineslist.add((Order_Line__c)obj);
	    			}
	    			
	    		}
	    	}
    			
	    	if(POlineslist.size() == 0 && sourceName =='Purchase_Order_Line__c'){
		    	result.addMessage(Label.Purchase_order_line_is_not_open,ApexPages.Severity.ERROR);
		    	result.success = false;
		    }
	    			
	    	
	    	if(fobOriginPO == true){
	    		result.addMessage(Label.Cannot_Receive_FOB_Origin,ApexPages.Severity.ERROR);
	    		result.success = false;
	    	}
            
            if(rlineslist.size()>0){
            	
            	if(sourceName == 'Order_Line__c'){
            		companyObj = (Company__c)rlineslist[0].getSObject('Receiving_Company__r');
            	}
            	else
            		companyObj = (Company__c)rlineslist[0].getSObject('Company__r');
            }
            
            
	    	if(asnlineslist.size() == 0 && sourceName =='ASN_Line__c'){
	    		result.addMessage(Label.ASN_line_not_open,ApexPages.Severity.ERROR);
	    		result.success = false;
	    	}
	    	if(openSOlineslist.size() == 0 && sourceName == 'Sales_Order_Line__c'){
	    		result.addMessage(Label.RMA_No_Open_Lines,ApexPages.Severity.ERROR);
	    		result.success = false;
	    	}
	    	
	    	if(openTOlineslist.size() == 0 && sourceName == 'Order_Line__c'){
	    		result.addMessage(Label.Transfer_Order_has_no_open_lines,ApexPages.Severity.ERROR);
	    		result.success = false;
	    	}
    	}
    	else if(rlineslist.size() == 0){
    		result.addMessage(Label.No_Receivable_Records_Found,ApexPages.Severity.ERROR);
    		result.success = false;
    	}
        
        if(result.success){
        	result.records = rlineslist; 
        	result.total = rlineslist.size();  
        
            if(rlineslist.size() > 0 && companyObj == null){
            	
	            if(sourceName == 'Order_Line__c'){
	            	companyObj = (Company__c)rlineslist[0].getSObject('Receiving_Company__r');
	            }
	            else{
	            	companyObj = (Company__c)rlineslist[0].getSObject('Company__r');
	            }	
            }
	        if( rlineslist.size() > 0 && companyObj !=null && companyObj.get('Serial_Control__c') != null && companyObj.get('Serial_Control__c') == 'At receipt and all processes'){
	            result.additionalInfo = 'true';
	        }    
        }
        else{
        	result.reason = 'FATAL_ERROR';
        	result.total = 0; 
        }
        
        return result;
    }
    
     
     @RemoteAction
    public static Map<String, String> getGridConfig(String docType){
        Map<String, String> configMap = new Map<String, String>();
        GridRelatedListController.GridRelatedListConfig receivingLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        String receivingLinesConfigJson = '';
        String receivingLinesFieldListJson = '';
        
        if(docType == 'Purchase Order'){            
            //PO Lines Grid config          
            receivingLinesConfig.uniqueId = 'receivingLinesGrid';
            receivingLinesConfig.title = 'Purchase Order Lines';
            receivingLinesConfig.objectName = 'Purchase_Order_Line__c';
            receivingLinesConfig.fieldset = 'Receiving_RO';
            receivingLinesConfig.buttons = 'search, columnmenu';           
            ReceivingLinesConfig.parentField = 'Purchase_Order__c';       
           
        }
        else if(docType == 'ASN'){
            //ASN Lines Grid config         
            receivingLinesConfig.uniqueId = 'asnLinesGrid';
            receivingLinesConfig.title = 'ASN Lines';
            receivingLinesConfig.objectName = 'ASN_Line__c';
            receivingLinesConfig.fieldset = 'ASN_Line_Receiving';
            receivingLinesConfig.buttons = 'search, columnmenu';
            ReceivingLinesConfig.parentField = 'ASN__c';
            
        }
        else if(docType == 'RMA'){
            //RMA Lines Grid config         
            receivingLinesConfig.uniqueId = 'rmaLinesGrid';
            receivingLinesConfig.title = 'RMA Lines';
            receivingLinesConfig.objectName = 'Sales_Order_Line__c';
            receivingLinesConfig.fieldset = 'RMA_Receiving';
            receivingLinesConfig.buttons = 'search, columnmenu';
            ReceivingLinesConfig.parentField = 'Sales_Order__c';

        }
        else if(docType == 'Transfer Order'){
            //RMA Lines Grid config         
            receivingLinesConfig.uniqueId = 'orderLinesGrid';
            receivingLinesConfig.title = 'Order Lines';
            receivingLinesConfig.objectName = 'Order_Line__c';
            receivingLinesConfig.fieldset = 'Order_Receive';
            receivingLinesConfig.buttons = 'search, columnmenu';
            ReceivingLinesConfig.parentField = 'Order__c';

        }
        
        if (receivingLinesConfig != null) {
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(receivingLinesConfig.objectName, receivingLinesConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
                
                if (fieldInfoList[i].field == 'Delivery_Location__c' || fieldInfoList[i].field == 'Ship_From_Location__c') {  
                    fieldInfoList[i].title = 'Receiving Location';
                }
            }
            
            receivingLinesConfigJson = JSON.serialize(receivingLinesConfig);
            
            receivingLinesFieldListJson = JSON.serialize(fieldInfoList);
            
        }
        
        configMap.put('config', receivingLinesConfigJson);
        configMap.put('fieldList', receivingLinesFieldListJson);
        
        return configMap;
    }   
        
    
    @RemoteAction 
    public static Map<String, String> setGridConfig(String docType, String facilityId){
            Map<String, String> gridconfigMap = new Map<String, String>();  
            String docObjName='';
            String docObjName1='';
            String fieldSetName='';
            String readOnlyRCLFieldSetName='';
            String editablefieldSetName='';
            String editableRCLFieldSetName='';
            String RMARoutingType = '';
            if(docType == 'Purchase Order'){
                docObjName = 'Purchase_Order_Line__c';
                fieldSetName = 'Receiving_RO';
                editablefieldSetName = 'Receiving_RO_EditableFields';
                
            }
            else if(docType == 'ASN'){
                
                docObjName = 'ASN_Line__c';
                fieldSetName = 'ASN_Receiving_RO';
                editablefieldSetName = 'ASN_Receiving_RO_Editable_Fields';

            } else if (docType == 'RMA') {
                
                docObjName = 'Sales_Order_Line__c';
                fieldSetName = 'RMA_Receiving';
            }
            else if (docType == 'Transfer Order') {
                
                docObjName = 'Order_Line__c';
                fieldSetName = 'Order_Receive';
            }
            
            //Populate for Receipt Line fieldset
            docObjName1 = 'Receipt_Line__c';
            readOnlyRCLFieldSetName = 'Receiving_RCL_RO';
            editableRCLFieldSetName = 'Receiving_RCL_EditableFields';
             
            //Initialize Receiving Grid:          
                       
            Set<String> editableFields = new Set<String>();
            if(!String.isBlank(editablefieldSetName)){
                List<FieldInfo> editablefieldsdefined = FieldInfo.fetchJsonFieldInfos(docObjName, editablefieldSetName);
                for (Integer i = 0; i<editablefieldsdefined.size(); i++){
                    editableFields.add(editablefieldsdefined[i].field);
                }
            }
            Set<String> readOnlyRCLFields = new Set<String>();
            if(!String.isBlank(readOnlyRCLFieldSetName)){
                List<FieldInfo> readOnlyfieldsRCLdefined = FieldInfo.fetchJsonFieldInfos(docObjName1, readOnlyRCLFieldSetName);
                for (Integer i = 0; i<readOnlyfieldsRCLdefined.size(); i++){
                    readOnlyRCLFields.add(readOnlyfieldsRCLdefined[i].field);
                }
            }

            FieldInfo fieldInfoItem, fieldInfoItem1,fieldInfoItem2,fieldInfoItem3;
   
            
            // get the master field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(docObjName, fieldSetName);
            List<FieldInfo> fieldInfoList1 = FieldInfo.fetchJsonFieldInfos(docObjName1, editableRCLFieldSetName);
            fieldInfoList1.addAll(FieldInfo.fetchJsonFieldInfos(docObjName1, readOnlyRCLFieldSetName));
            if (docType == 'RMA'){
                    if(facilityId != null && facilityId != ''){
                            List<Facility__c> facilitylist = [ select id, RMA_Receipt_Routing__c from Facility__c where Id =:facilityId ];
                                if(facilitylist.size() > 0){
                                      RMARoutingType = facilitylist[0].RMA_Receipt_Routing__c;
                                      if(RMARoutingType != 'Inspect')  {
                                            fieldInfoItem3 = FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', new String[] { 'Putaway_Location__c' })[0];
                                            fieldInfoItem3.editable = true;
                                            fieldInfoList.add(fieldInfoItem3);
                                            editableFields.add(fieldInfoItem3.field);
                                            
                                      }
                               }
                }
            }
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                if (fieldInfoList[i].field == 'Delivery_Location__c' || fieldInfoList[i].field == 'Ship_From_Location__c') {  
                    fieldInfoList[i].title = 'Receiving Location';
                }
                fieldInfoList[i].editable = editableFields.contains(fieldInfoList[i].field) ? true : false;
                fieldInfoList[i].field = 'rl.' + fieldInfoList[i].field;
            }
            Set<String> fieldNames = new Set<String>();
            for(Integer i = 0; i < fieldInfoList1.size(); i++){
            	
            	if(!fieldNames.contains(fieldInfoList1[i].field)){
            		fieldNames.add(fieldInfoList1[i].field);
            	}
            	else
            		continue;
                
                fieldInfoList1[i].editable = readOnlyRCLFields.contains(fieldInfoList1[i].field) ? false : true;
                fieldInfoList1[i].field = 'rcl.' + fieldInfoList1[i].field;
                fieldInfoList.add(fieldInfoList1[i]);
            }
            
             if(RMARoutingType != 'Inspect' && (docType == 'RMA For Repair' || docType == 'RMA'))
             {
                fieldInfoItem2 = new FieldInfo('putawayType', 'Putaway Type', 'picklist');
                SelectListItem slist1 = new SelectListItem('Inventory', 'Inventory');
                slist1.selected = true;
                SelectListItem slist2 = new SelectListItem('Scrap', 'Scrap');
                List<SelectListItem> selectlist = new List<SelectListItem>{slist1,slist2};
                fieldInfoItem2.selectList = selectlist;
                fieldInfoItem2.editable = true;
                fieldInfoList.add(fieldInfoItem2);
                editableFields.add(fieldInfoItem2.field);
            }
                                      
            masterFieldList = JSON.serialize(fieldInfoList);
            
            // get the detail field info list
            fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', 'Receipt_Info');
            fieldInfoItem = FieldInfo.fetchJsonFieldInfos('SKID__c', new String[] { 'Temporary_Value_Holder__c' })[0];
            fieldInfoItem.hidden = true;
            fieldInfoItem1 = FieldInfo.fetchJsonFieldInfos('SKID__c', new String[] { 'Quantity_To_Issue__c' })[0];
            fieldInfoItem1.hidden = true;
            fieldInfoList.add(fieldInfoItem);
            fieldInfoList.add(fieldInfoItem1);
            
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
            
            FieldInfo fi = new FieldInfo('','','integer');
            fi.editable = false;
            fieldInfoList = new list<FieldInfo>{fi};
            
            List<String> serialAttributesList = new list<String>();
            for( String serAttr : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes') ){
                serialAttributesList.add(serAttr.replace( KSE.namespaceUU, '').toLowerCase().trim()); 
            }
            serialAttributes = JSON.serialize(serialAttributesList);
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial', String.join(serialAttributesList, ','), false));
            
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
            gridSize = fieldInfoList.size() * 150; 

        gridconfigMap.put('masterFieldList', masterFieldList);
        gridconfigMap.put('detailFieldList', detailFieldList);
        gridconfigMap.put('skidFieldList', skidFieldList);
        gridconfigMap.put('serialFieldList', serialFieldList);
        
        return gridconfigMap;
        
    }       
        
    
    @RemoteAction 
    public static JsonResult getList(List<Id> lineIds, String docType) {
        JsonResult result = new JsonResult();
        list<ReceivingWrapper> records = new list<ReceivingWrapper>();
        system.debug('lineIds: ' + lineIds);
        system.debug('docType: ' + docType);
        
        try{
            if(docType == 'Purchase Order'){                    
                records = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(lineIds), new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
            }
            else if(docType == 'ASN'){
                records = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(lineIds), new set<String>{'ASN_Line__c'.toLowerCase()} );
            }
            else if(docType == 'RMA'){
                records = ReceivingDocumentServiceV2.getReceivingLines(null, new Set<Id>(lineIds), new set<String>{
                        'Sales_Order_Line__c'.toLowerCase() });
            }
            else if(docType == 'Transfer Order'){
                records = ReceivingDocumentServiceV2.getReceivingLines(null, new Set<Id>(lineIds), new set<String>{
                        'Order_Line__c'.toLowerCase() });
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
    
    @RemoteAction
    public static JsonResult receive(List<ReceivingWrapper> rlWrapperList, List<String> polDateFields, List<String> skidDateFields, Receiving_Document__c rdoc, List<String> headerdatefields){
        Map<Id, Receiving_Document__c> headerToRDMap = new Map<Id, Receiving_Document__c>();
        JsonResult result = new JsonResult();
        Savepoint sp1 = Database.setSavepoint();
        List<Receiving_Document__c> rdoclist = new List<Receiving_Document__c>();
        
        try{
            String errorlines = '';
            
            for( ReceivingWrapper rw : rlWrapperList ){
                
                Decimal totalQuantity = 0;
                List<SkidService3.serialWrapper> swList = new List<SkidService3.serialWrapper>();
                               
                for(SkidService3.serialWrapper sw : rw.serialWrapperList){
                    
                    if(sw.skid.Quantity__c > 0){
                        totalQuantity += sw.skid.Quantity__c;
                        swList.add(sw);
                    }
                }
                
                if(totalQuantity == 0){
                    errorlines = errorlines + rw.rl.get('Name') + ' ,';
                }else{
                    KendoUtils.UpdateDateFields(rw.rl, polDateFields);
                    rw.serialWrapperList = swList;
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
                //Inserting RD's
                List<ReceivingWrapper> refreshedList;
                if(rdoc.Transaction_Date__c != null){
                	rdoc.Date_Received__c = rdoc.Transaction_Date__c;
                }
                else{
                	rdoc.Transaction_Date__c = system.now();
                	rdoc.Date_Received__c = system.now();
                }
                
                rdoc.Status__c = 'Closed';
                rdoclist.add(rdoc);         
                DML.insertAsUser(rdoclist);
                
                try{
                    refreshedList = ReceivingDocumentServiceV2.checkUserErrors(rlWrapperList);
                    ReceivingDocumentServiceV2.receive(refreshedList, headerToRDMap);  
                    
                    // Display RD Headers as hyperlinks
                    List<String> rdHeaderLinks = new List<String>();            
                    
                    Receiving_Document__c rd = [Select Id, Name from Receiving_Document__c where Id =: rdoc.Id];
                    
                    result.records = refreshedList;
                    rdHeaderLinks.add('<a href="/' + rd.Id + '">' + rd.Name + '</a>');
                    result.addMessage(Label.Changes_saved_Receiving_Document_headers_created  + rdHeaderLinks, ApexPages.Severity.CONFIRM);             
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
    public static list<String> refreshTrackedAttr( Location__c putAwayLocation , Item__c item , Boolean ConsignedFlag){
                
        Location__c pal = [ select id, Name, Bin_Tracked__c from Location__c where Id =:putAwayLocation.id ];
        list<String> attributesList = SkidService3.trackedAttributes(null, pal, item); 
        if(ConsignedFlag){
            attributesList.add('Consigned_Owner__c');
        }
        return attributesList;
       
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
        
        System.debug(Logginglevel.Info,'addlFields'+addlFields);
        List<object> records = (List<object>) addlFields;
        result.records = records;//JSON.serialize
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( item.Packaging_UOM__c, List<Id>.class );
        Decimal conversionFactor = KSE.getConversionFactor(item.Id,facilityId, pkgUOM,stockUOM,lstPkgUom);
        result.additionalInfo = String.valueOf(conversionFactor);
         
        return result; 
    }
    
    @RemoteAction
    public static Currency__c getCurrencyCode( String supplierId, String facilityId, String docnumber, String doctype){
        Currency__c transcurrency;
        if(docnumber != null && docnumber != ''){
            if(doctype == 'ASN'){
                List<ASN_Line__c> asnlinelist = [ select id, ASN__r.Currency__r.id,ASN__r.Currency__r.Name  from ASN_Line__c where ASN__r.Name =:docnumber limit 1];
                
                if(asnlinelist.size()>0)
                    transcurrency = asnlinelist[0].ASN__r.Currency__r;
            }
            else if(doctype == 'Purchase Order'){
                List<Purchase_Order_Line__c> polinelist = [select Id, Purchase_Order__r.Currency__r.id,Purchase_Order__r.Currency__r.Name from Purchase_Order_Line__c where Purchase_Order__r.Name =: docnumber limit 1];
            
                if(polinelist.size() >0)
                    transcurrency = polinelist[0].Purchase_Order__r.Currency__r;
            }
            else if(doctype == 'RMA'){
                List<Sales_Order_Line__c> solinelist = [select Id, Sales_Order__r.Currency__r.id,Sales_Order__r.Currency__r.Name, Company__r.Default_Transaction_Currency__r.id,Company__r.Default_Transaction_Currency__r.Name from Sales_Order_Line__c where Sales_Order__r.Name =: docnumber limit 1];
            
                if(solinelist.size() > 0)
                    transcurrency = solinelist[0].Sales_Order__r.Currency__r;
            }
            
            
        }
        
        if(transcurrency == null){
            
            if(supplierId != null){
                List<Supplier__c> supplierlist = [ select id, Currency__r.id,Currency__r.Name, Company__r.Default_Transaction_Currency__r.id from Supplier__c where Id =:supplierId limit 1];
                if(supplierlist.size() >0){
                    transcurrency = supplierlist[0].Currency__r;
                }
                
            }      
            if(transcurrency == null){
                    
                    if(facilityId != null){
                        List<Facility__c> facilitylist = [ select id, Company__r.Default_Transaction_Currency__r.id,Company__r.Default_Transaction_Currency__r.Name  from Facility__c where Id =:facilityId ];
                        if(facilitylist.size() > 0){
                            if(facilitylist[0].Company__r.Default_Transaction_Currency__r.id != null){
                                transcurrency = facilitylist[0].Company__r.Default_Transaction_Currency__r; 
                            }
                            
                        }
                        
                    }
                     
            }
        }
        
        
        return transcurrency; 
       
    }
    
    @RemoteAction
    public static JSONResult getDocumentInfo( String sourceName, String docId){
      	
        JSONResult result = new JSONResult();
        String whereClause;
        SOQLUtil soql = new SOQLUtil(sourceName);
        
        
        if(sourceName == 'Purchase_Order_Line__c'){
		    soql.addFields(new Set<String>{'Name','Delivery_Facility__c', 'Delivery_Facility__r.Id','Delivery_Facility__r.Name', 'Purchase_Order__r.Status__c','Purchase_Order__r.Id','Purchase_Order__r.Name','Purchase_Order__r.Supplier__r.Id','Purchase_Order__r.Supplier__r.Name', 
		    								'Purchase_Order__r.FOB_Term__c','Purchase_Order__r.FOB_Term__r.Name','Purchase_Order__r.Approval_Status__c','Purchase_Order__r.FOB_Term__r.Id','Purchase_Order__r.Currency__c','Purchase_Order__r.Currency__r.Name'});
		    
		    whereClause =  'Purchase_Order__c = :docId LIMIT 1';	
        }
        else if(sourceName == 'ASN_Line__c'){
        	soql.addFields(new Set<String>{'Id','ASN__r.Id','ASN__r.Name','Purchase_Order__r.Approval_Status__c','Purchase_Order__r.Name','Purchase_Order__r.Id', 'Facility__r.Id','Facility__r.Name', 'Supplier__r.Name','Supplier__r.Id','ASN__r.Status__c','ASN__r.FOB__r.Id', 'ASN__r.Currency__r.Id','ASN__r.Currency__r.Name','ASN__r.FOB__r.Name'});
        	
        	whereClause =  'ASN__c = :docId LIMIT 1';
        }
        else if(sourceName == 'Sales_Order_Line__c'){
        	soql.addFields(new Set<String>{'Sales_Order__r.Id','Sales_Order__r.Name','Ship_From_Location__r.Facility__r.Id', 'Sales_Order__r.Customer__r.Id', 'Sales_Order__r.Currency__r.Id','Ship_From_Location__r.Facility__r.Name', 'Sales_Order__r.Customer__r.Name', 'Sales_Order__r.Currency__r.Name'});
        	whereClause =  'Sales_Order__r.Type__c In:rmaTypes and Sales_Order__c = :docId LIMIT 1';
        }
        else if(sourceName == 'Order_Line__c'){
        	soql.addFields(new Set<String>{'Order__r.Status__c','Order__r.Id','Order__r.Name','Ship_From_Location__r.Name','Ship_From_Facility__c', 'Order__r.Currency__r.Id','Order__r.Currency__r.Name','Deliver_To_Facility__r.Name','Deliver_To_Facility__c','Deliver_To_Facility__r.Name'});
        	whereClause =  'Order__c = :docId LIMIT 1';
        }
       
       soql.setWhereClause(whereClause); 
       result.records = Database.query(soql.getQuery());
	   result.total = result.records.size();
	   
	   if(result.records.size() == 0 && sourceName == 'Sales_Order_Line__c'){
	   	  result.success = false;
	   	  result.addMessage(Label.Cannot_Receive_SO_Type,ApexPages.Severity.ERROR);
       }
       
       if(sourceName == 'Purchase_Order_Line__c' && result.records.size() >0){
       	    Purchase_Order_Line__c poline = (Purchase_Order_Line__c)result.records[0];
       	    
       	    if(poline.Purchase_Order__r.Status__c !='Open'){
       	    	if(poline.Purchase_Order__r.Status__c =='Closed'){
	       			result.success = false;
		   	  		result.addMessage(Label.Purchase_Order_has_been_Closed,ApexPages.Severity.ERROR);
	       		}
	       		else if(poline.Purchase_Order__r.Status__c =='Cancelled'){
	       			result.success = false;
		   	  		result.addMessage(Label.Purchase_Order_already_been_Cancelled,ApexPages.Severity.ERROR);
	       		}
	       		
       	    }
       	    else if(poline.Purchase_Order__r.Approval_Status__c != 'Approved'){
       				result.success = false;
    				result.addMessage(Label.Purchase_order_is_not_approved, ApexPages.Severity.ERROR);
            }
       	    
       }
       
       if(sourceName == 'ASN_Line__c' && result.records.size() >0){
       	
	       	ASN_Line__c asnlineObj = (ASN_Line__c)result.records[0];
	       	
	       	if(asnlineObj.ASN__r.Status__c != 'Confirmed'){
		    	result.addMessage(Label.Cannot_Receive_Unconfirmed_ASN,ApexPages.Severity.ERROR);
		    	result.success = false;
		    }
		    
			if(asnlineObj.Purchase_Order__r.Approval_Status__c != 'Approved'){
				result.addMessage(Label.Purchase_order_is_not_approved,ApexPages.Severity.ERROR);
        		result.success = false;
			}
	    
       }
       if(sourceName == 'Order_Line__c' && result.records.size() >0){
       	
	       	Order_Line__c orderlineObj = (Order_Line__c)result.records[0];
	       	
	       	if(orderlineObj.Order__r !=null && (orderlineObj.Order__r.Status__c == 'Closed' || orderlineObj.Order__r.Status__c == 'Cancelled')){
		    	result.addMessage(Label.Transfer_Order_cancelled_closed,ApexPages.Severity.ERROR);
		    	result.success = false;
		    }
       }
	   
	   return result;      
       
    }
    
    
    
}