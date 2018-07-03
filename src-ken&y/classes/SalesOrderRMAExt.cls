public with sharing class SalesOrderRMAExt extends GridRelatedListController {
	
	public string NamespaceUU { get { return KSE.NamespaceUU; }}	
	 
	public Customer_Invoice__c customerinvoice { get; set; } 
	public Sales_Order__c salesorder { get; set; } 
    public Sales_Order__c oldSalesOrder {get; set; }
    
    public boolean hasRelatedSO {get; set;}
	public static List<Sales_Order_Line__c> solList;
    
	
	public static Id salesOrderId {get; set;}
	public static SchemaUtil util = SchemaUtil.getInstance();	


    public static Map<Id, List<String>> errorMsgs;

    public Boolean failedValidation {get; set;} // disables Create RMA button

    public class SalesOrderRMAExtException extends Exception{

    }

    public SalesOrderRMAExt(ApexPages.StandardSetController con) { 

        try{
             Id sid = (Id) ApexPages.currentPage().getParameters().get('id');
             if (sid != null) {
              con.setSelected([
                  select Id,name
                  from Sales_Order__c
                  where Id = :sid
                  ]);
            }
            hasRelatedSO = false;

            Set<Id> soid = new Set<Id>();
            for (Sales_Order__c so : (List<Sales_Order__c>) con.getSelected()){
                soid.add(so.id);
            }

            if (soId.size() > 1){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'RMA for multiple Sales Orders not yet supported.'));
                failedValidation = true;
                return;
            }

            if (!soId.isEmpty()){
                oldSalesOrder = [select Id, Credit_Hold__c, Company__c,Company__r.Use_Warranty_Repairs__c, Customer__c, Customer__r.Top_Parent_Customer__r.Minimum_Shelf_Life_In_Days__c, Override_Credit_Hold__c, Name,
                     Customer__r.Top_Parent_Customer__r.Status__c, Ship_Complete__c, Status__c, Ship_To__c, Currency__c, Hold__c, Released_to_3PL__c, Related_Sales_Order__c, 
                     Customer__r.Top_Parent_Customer__r.Credit_Hold__c, type__c,
                     (select id, name, product__c, Product__r.name from Sales_Order_Lines__r)
                     from Sales_Order__c 
                     where Id IN :soid limit 1];
                
                validate(oldSalesOrder);
                getSalesOrderLines(oldSalesOrder.Id);
            } else {
                oldSalesOrder = new Sales_order__c();
                oldSalesOrder.Name = 'New RMA Order';
            }
            
        } catch( Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())) );
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    public void validate(Sales_Order__c oldSalesOrder ){
        
        if (!SalesOrderService.STANDARD_ORDER_TYPES.contains(oldSalesOrder.type__c) ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Not a valid Sales Order type: ' + oldSalesOrder.Type__c));
            failedValidation = true;
            return;
        }

        hasRelatedSO = true; // allows pageblock for Lines to be shown. Actual value gets populated on the remote action for the kendoDetailList
        salesOrderId = oldSalesOrder.id; // allows header and lines grid to be populated

    }
	public String getSalesOrderLinesGridConfig(){
		GridRelatedListController.GridRelatedListConfig salesOrderLinesGridConfig = new GridRelatedListController.GridRelatedListConfig();
        salesOrderLinesGridConfig.uniqueId = 'SOLGrid';
        salesOrderLinesGridConfig.title = 'Sales Order Lines';
        salesOrderLinesGridConfig.objectName = 'Sales_Order_Line__c';
        salesOrderLinesGridConfig.parentRecord = salesorder;
        salesOrderLinesGridConfig.parentField ='Sales_Order__c';
        salesOrderLinesGridConfig.fieldset = 'RMALine';
        salesOrderLinesGridConfig.buttons = 'search';
        salesOrderLinesGridConfig.alwaysUseFullDateTimeFormat = false;

        return JSON.serialize(salesOrderLinesGridConfig);
	}

	public String getSalesOrderLineFieldList(){
        // get SHL fields into a List
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();

        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', 'RMALine'));

        FieldInfo rmaQuantityField = new FieldInfo();
        rmaQuantityField.field = 'rmaQuantity';
        rmaQuantityField.fieldType = 'double';
        rmaQuantityField.precision = 18;
        rmaQuantityField.scale = 6;
        rmaQuantityField.title = 'Quantity for RMA';
        rmaQuantityField.editable = true;
        fieldInfoList.add(rmaQuantityField);

        Set<String> hiddenFields = new Set<String>{ 'ID' };
        
        // set all the fields as readonly
        for(FieldInfo field: fieldInfoList){

            String fieldName = field.field;
            if (field.field != 'rmaQuantity'){
                field.editable = !hasRelatedSO;    // if SO has a related SO, disable editing on SO line.
            }

            if(field.title.toLowerCase() == 'need date' || field.title.toLowerCase() =='item specification'){
                field.editable = true;
            }

            if(field.title.toLowerCase() == 'ship from location'){
                field.title = 'Receiving Location';
                field.editable = true;
            }
            if(field.title.toLowerCase() == 'Fulfillment Source' || field.title.toLowerCase() == 'Returned To Vendor'){
            	field.editable = true;
            }
            field.field = 'soLine.' + fieldName;
        }

        String salesOrderLineFieldList = JSON.serialize(fieldInfoList);
        
        return salesOrderLineFieldList;
    }

    public String getHeaderFieldList(){
        List <FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Sales_Order__c', 'RMA');
        //Set<String> ignored = new Set <String>{'Id', 'ID'};
		FieldInfo fieldInfoItem1 = new FieldInfo('Type__c', 'Type', 'picklist');

        SelectListItem slist1 = new SelectListItem(SalesOrderService.SO_TYPE_RMA, 'Credit');
        slist1.selected = true;
        SelectListItem slist2 = new SelectListItem(SalesOrderService.SO_TYPE_RMA_REPLACEMENT, 'Replacement');
        
        SelectListItem slist3 = new SelectListItem(SalesOrderService.SO_TYPE_RMA_REPAIR, 'Customer Repair');
        
        List<SelectListItem> selectlist = new List<SelectListItem>{slist1,slist2,slist3};
        fieldInfoItem1.selectList = selectlist;
        fieldInfoItem1.editable = true;
        fieldInfoList.add(fieldInfoItem1);
        fieldInfoList.remove(0); // Remove Id field from the list
        for (FieldInfo field : fieldInfoList){
            //field.hidden = ignored.contains(field.field);
            field.editable = true;

            if(field.title.toLowerCase() == 'ship from location'){
                field.title = 'Receiving Location';
            }
        }

         return JSON.serialize(fieldInfoList);
    }

    @RemoteAction 
    public static JsonResult getSalesOrderLines(String soId){
        
        JsonResult  jsResult = new JsonResult();
         try{

            List <SalesOrderLineWrapper> result = new List <SalesOrderLineWrapper>();

            if (String.isBlank(soId)){
                jsResult.addMessage('No referenced Sales Order provided.', ApexPages.Severity.Info);
                jsResult.records = result;
                return jsResult;
            }

            salesOrderId = (Id) soId;    

            errorMsgs = new Map<Id, List<String>>(); 

            getSolForRMA(salesOrderId);
            if (solList.size() == 0 ){
                return new JsonResult();
            }

            for( Sales_Order_Line__c soLine : solList ){
            	if(soLine.Fulfillment_Source__c == 'Drop Ship' && soLine.Sales_Order__r.Type__c != SalesOrderService.SO_TYPE_RMA_REPAIR){
            		soline.Returned_To_Vendor__c = true;
            	}
                soLine.Related_Sales_Order_Line__c = soLine.id;
                result.add( new SalesOrderLineWrapper(soLine, errorMsgs.get(soLine.id)) );
            }

            jsResult.records = result;
            jsResult.total = result.size();

        } catch (Exception e){

            System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());

            jsResult.success = false;
            jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR );

        }
        return jsResult;
    }

    public static Sales_order__c createNewSalesOrder(){
        Sales_order__c returnSO = new Sales_Order__c();

        returnSO.Company__c = CompanyService.getDefaultCompanyId(); 
        if (returnSO.Company__c == null){
            throw new SalesOrderRMAExtException('Please select defualt company on User Preference.');
            return null;
        }
        Company__c companyInfo = [SELECT Id, Name, Default_Transaction_Currency__c,Use_Warranty_Repairs__c FROM Company__c WHERE Id =:returnSO.Company__c LIMIT 1];

        if (companyInfo != null){
            returnSO.Currency__c = companyInfo.Default_Transaction_Currency__c; 
        }       

        returnSO.Company__r = companyInfo;
        return returnSO;
    }

    public PageReference cancel(){

        Schema.DescribeSObjectResult dssResult = Sales_Order__c.SObjectType.getDescribe();
        PageReference pageRef = new PageReference('/' + dssResult.getKeyPrefix());

        return pageRef;
    }

    @RemoteAction
    public static JsonResult getSODetails(String soId){
        JsonResult  jsResult = new JsonResult();

        try {
            Sales_Order__c soHeader;

            if (String.isNotBlank(soId)){

                String objectName = 'Sales_Order__c';
                String headerFieldset = 'RMA';  
                Set<String> addlFields = new Set<String> {'Company__c', 'Company__r.Use_Warranty_Repairs__c','Related_Sales_Order__c','Type__c','Billing_UOM__c','Recurrence_Start_Date__c'};      

                string whereClause = 'Id  = :soId LIMIT 1';
                
                String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset }, addlFields, whereClause);

                soHeader = database.query(queryString);

                soHeader.Required_Date__c = null;
                soHeader.Related_Sales_Order__c = soHeader.id;
                //soHeader.Related_Sales_Order__r = soHeader;

            } else {
                soHeader = createNewSalesOrder();
            }

            soHeader.Type__c = SalesOrderService.SO_TYPE_RMA;
            soHeader.Status__c = 'Draft';

            return new JsonResult(new List<Sales_Order__c>{soHeader.clone(false, true)}, 1);

        } catch (Exception e){

            System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());
            
            jsResult.success = false;
            jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR );
            //jsResult.addMessage(e.getMessage()+ ' - ' +  e.getStackTraceString(), ApexPages.Severity.ERROR);

        }
        return jsResult;
    }

    /*  Called from SalesOrderRMAExt to create RMA lines and called from ManageLines.
    *   During replacement:
    *           For SalesOrderRMA it's create two lines where one is replacement and the other is return.
    *           For SalesOrderMangeLines it'll clone one more line which will be either the replacement or return automatically.
    */
    public static List<Sales_Order_Line__c> processRMALines(List<Sales_Order_Line__c> solsForClone, Sales_Order__c soRMA, Boolean manual) {

        List<Sales_Order_Line__c> soRetList = new List<Sales_Order_Line__c>();

        for (Sales_Order_Line__c soLine : solsForClone) {

            if (soLine.Quantity_Ordered__c == 0 || soLine.Quantity_Ordered__c == null) {
                continue;
            } else if (math.abs(soLine.Quantity_Ordered__c) > soLine.Quantity_Fulfilled__c) {
                throw new SalesOrderRMAExtException('Qty Ordered: ' + soLine.Quantity_Ordered__c + '. Quantity for RMA cannot be greater than Quantity Fulfilled.' + soLine.Quantity_Fulfilled__c);
            }

			if(soLine.Required_Date__c == null && soRMA.Required_Date__c != null){
				soLine.Required_Date__c = soRMA.Required_Date__c;
			} else if(soLine.Required_Date__c == null && soRMA.Required_Date__c == null){
				soLine.Required_Date__c = null;
			}

            // return SOL
            Sales_Order_Line__c solClone = soLine.clone(false, true);

            if (solClone.Quantity_Ordered__c > 0) {
                solClone.Quantity_Ordered__c = -solClone.Quantity_Ordered__c;
            }

            solClone.Status__c = 'Draft';

            if (solClone.Related_Sales_Order_Line__c != null) {
                solClone.Related_Sales_Order_Line__c = soLine.Id;
            }

            solClone.Quantity_Fulfilled__c = 0;
            solClone.Quantity_Shipped__c = 0;
            solClone.Sales_Order__c = soRMA.Id;
            solClone.Line__c = null; // reset line number
            Id itemspecId;
            if(solClone.Item_Specification__c !=null && soRMA.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR && soRMA.Company__r.Use_Warranty_Repairs__c == false){
			    itemspecId = solClone.Item_Specification__c;
			    solClone.Item_Specification__c = null;
			}
            if (!manual) {
                soRetList.add(solClone);
            }
            
			if (soRMA.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT || (soRMA.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR && soRMA.Company__r.Use_Warranty_Repairs__c == false && solClone.Related_Sales_Order_Line__c !=null)) {

                Sales_Order_Line__c solReplacement = solClone.clone(false, true);
                solReplacement.Status__c = 'Draft';
                //String key = solClone.Name +'-' + solClone.Line__c;
                //solClone1.Related_Sales_Order_Line__r = new Sales_Order_Line__c(Primary_Key__c = key);

                solReplacement.Quantity_Fulfilled__c = 0;
                solReplacement.Quantity_Shipped__c = 0;
                solReplacement.Sales_Order__c = soRMA.id;
                solReplacement.Quantity_Ordered__c = soLine.Quantity_Ordered__c * -1;
                solReplacement.Name = null;
                solReplacement.Returned_To_Vendor__c = false;
				solReplacement.Required_Date__c = System.today();
				if(soRMA.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR){
					solReplacement.Type__c = 'Repair';
					if(itemspecId !=null){
					    solReplacement.Item_Specification__c =itemspecId;
					}
				}
				System.debug(Logginglevel.Info,'solReplacement:'+solReplacement);
                // depending on entry point (mangeLines vs CreateRMA pages), set these values
//                if (!manual) {
//                    solReplacement.Required_Date__c = System.today();
//                }

                soRetList.add(solReplacement);
            }
            
        }
        //dont copy RTV flag
        //solClone1.Line__c = soLine.Line__c + solForRMA.size();
        System.debug(loggingLevel.Error, '*** soRetList: ' + soRetList);
        return soRetList;
    }

    @RemoteAction
    public static JsonResult createRMA(List<Sales_Order_Line__c> solForRMA, Sales_Order__c so, List<String> dateFields) {

        JsonResult  jsResult = new JsonResult();
        Savepoint sp = Database.setSavepoint();

        try {

            if (so.Type__c == null || so.Type__c == '') {
                throw new SalesOrderRMAExtException('Please select type on Sales Order.');
            }

            if (so.Customer__c == null || so.Bill_To__c == null || so.Ship_To__c == null){
                throw new SalesOrderRMAExtException('Missing customer on Sales Order.');
            }
            for(Sales_Order_Line__c soline:solForRMA){
            	
            	if(soline.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT && soline.Returned_To_Vendor__c == true && soline.Fulfillment_Source__c == 'Inventory'){
            		 throw new SalesOrderRMAExtException(Label.UncheckRTV_For_Inventory);
            	}
            	if(soline.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT && soline.Returned_To_Vendor__c == false && soline.Fulfillment_Source__c == 'Drop Ship'){
            		 throw new SalesOrderRMAExtException(Label.Check_RTV_For_DropShip);
            	}
            	
            	if(soline.Item_Specification__c !=null && so.Type__c != SalesOrderService.SO_TYPE_RMA_REPAIR){
            		soline.Item_Specification__c = null;
            	}
            }
            

            Customer__c soldToCust = [select Id, Name, Street__c, City__c, State__c, Zip_Code__c, Country__c, Parent_Customer__c,
                                          Parent_Customer__r.Payment_Term__c, Parent_Customer__r.Payment_Term__r.Name, 
                                          Price_Determination_Date__c, Currency__c from Customer__c where ID =: so.Customer__c LIMIT 1];
            
            if (soldToCust.Currency__c != null){
                so.Currency__c = soldToCust.Currency__c;
            }

            if (so.Price_Determination_Date__c == null && soldToCust.Price_Determination_Date__c != null){
                so.Price_Determination_Date__c = soldToCust.Price_Determination_Date__c;
            }

            so.Street__c = soldToCust.Street__c != null ? soldToCust.Street__c.replace('<br>', '\n') : soldToCust.Street__c;
            so.City__c = soldToCust.City__c;
            so.State__c = soldToCust.State__c;
            so.Zip_Code__c = soldToCust.Zip_Code__c;
            so.Country__c = soldToCust.Country__c;
            so.Bill_to__c = soldToCust.Parent_Customer__c;

            if ( so.Ship_to__c == null ) {
                List<Customer__c> stList = [select ID, name
                                       from Customer__c
                                       where Parent_customer__c =: so.Customer__c];
                if ( stList.size() == 1 ) {
                    so.Ship_to__c = stList[0].id;
                } 
            } 
            
            Customer__c shipTo = [select ID, Street__c, City__c, State__c, Zip_Code__c, Country__c
                                       from Customer__c
                                       where ID =: so.Ship_to__c LIMIT 1];
            if (shipTo != null) {
                so.Ship_to_Street__c = shipTo.Street__c != null ? shipTo.Street__c.replace('<br>', '\n') : shipTo.Street__c;
                so.Ship_to_City__c = shipTo.City__c;
                so.Ship_to_State__c = shipTo.State__c;
                so.Ship_to_Zip_Code__c = shipTo.Zip_Code__c;
                so.Ship_to_Country__c = shipTo.Country__c;
            }
            
            Customer__c billTo = [select ID, Street__c, City__c, State__c, Zip_Code__c, Country__c
                                       from Customer__c
                                       where ID =: so.Bill_to__c LIMIT 1];
            if (billTo != null) {
                so.Bill_to_Street__c = billTo.Street__c != null ? billTo.Street__c.replace('<br>', '\n') : billTo.Street__c;
                so.Bill_to_City__c = billTo.City__c;
                so.Bill_to_State__c = billTo.State__c;
                so.Bill_to_Zip_Code__c = billTo.Zip_Code__c;
                so.Bill_to_Country__c = billTo.Country__c;
            }
            
            if (so.Payment_Term__c == null  && soldToCust != null && soldToCust.Parent_Customer__r != null && soldToCust.Parent_Customer__r.Payment_Term__c != null) {
               so.Payment_Term__c = soldToCust.Parent_Customer__r.Payment_Term__c; //KNDY-1149 Pulling payment terms from Bill-to customer who is the parent of a Sold-to customer
                
            }

            DML.insertAsUser(so);
            List <Sales_Order_Line__c> soList = processRMALines(solForRMA, so, false);

			//Adding Cloned SOLines in case of Replacement:
//
//			List<Sales_Order_Line__c> updatesolLineNum = new List<Sales_Order_Line__c>();
////			Map <Decimal,Sales_Order_Line__c>relatedSOMap = new Map <Decimal,Sales_Order_Line__c>();
//            for (Sales_Order_Line__c soLine : solForRMA){
//                if (soLine.Quantity_Ordered__c == 0 || soLine.Quantity_Ordered__c == null){
//                    continue;
//                }
//                else if(math.abs(soLine.Quantity_Ordered__c) > soLine.Quantity_Fulfilled__c){
//                	throw new SalesOrderRMAExtException('Qty Ordered: '+soLine.Quantity_Ordered__c +'. Quantity for RMA cannot be greater than Quantity Fulfilled.' + soLine.Quantity_Fulfilled__c);
//                }
//
//                if(soLine.Required_Date__c == null && so.Required_Date__c != null){
//                    soLine.Required_Date__c = so.Required_Date__c;
//                } else if(soLine.Required_Date__c == null && so.Required_Date__c == null){
//                    soLine.Required_Date__c = null;
//                }
//
//                Sales_Order_Line__c solClone = soLine.clone(false, true);
//				solClone.Line__c = null;
//                Sales_Order_Line__c solClone1;
//
//                if(so.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT){// && so.Returned_To_Vendor__c != true
//
//				 	solClone1 = soLine.clone(false, true);
//					System.debug( logginglevel.error, '~*~ solClone1 :' + solClone1 );
//				 	solClone1.Status__c = 'Draft';
////				 	String key = solClone.Name +'-' + solClone.Line__c;
//				    //solClone1.Related_Sales_Order_Line__r = new Sales_Order_Line__c(Primary_Key__c = key);
//
//				 	solClone1.Quantity_Fulfilled__c = 0;
//				    solClone1.Quantity_Shipped__c = 0;
//				    solClone1.Sales_Order__c = so.id;
//				    solClone1.Quantity_Ordered__c = soLine.Quantity_Ordered__c * -1;
//				    solClone1.Name = null;
//				    solClone1.Required_Date__c = System.today();
//				    solClone1.Returned_To_Vendor__c = false; //dont copy RTV flag
////				    solClone1.Line__c = soLine.Line__c + solForRMA.size();
////	               	relatedSOMap.put(solClone1.Line__c,solClone);
////	                updatesolLineNum.add(solClone1);
//	                System.debug(Logginglevel.info,'updatesolLineNum first:'+updatesolLineNum);
//				}
//
//                if (solClone.Quantity_Ordered__c > 0){
//                    solClone.Quantity_Ordered__c = -solClone.Quantity_Ordered__c;
//                }
//
//                solClone.Status__c = 'Draft';
//                if (solClone.Related_Sales_Order_Line__c != null){
//                    solClone.Related_Sales_Order_Line__c = soLine.Id;
//                }
//
//                solClone.Quantity_Fulfilled__c = 0;
//                solClone.Quantity_Shipped__c = 0;
//                solClone.Sales_Order__c = so.id;
//
////				System.debug( logginglevel.error, '~*~ solClone :' + solClone );
//                soList.add(solClone);
//
//            }
//
//			KSE.setLineNumbers(updatesolLineNum);

			if (!soList.isEmpty()){
				System.debug( logginglevel.error, '~*~ soList :' + soList );
                DML.insertAsUser(soList);
            }


            Map<id,id> fromToMap = new Map<id,id>{so.Related_Sales_Order__c => so.id};
            for (Sales_Order_Line__c sol : soList){
                if (sol.Related_Sales_Order_Line__c != null && sol.Id != null){
                    fromToMap.put(sol.Related_Sales_Order_Line__c, sol.Id);
                }
            }

            AllowanceService.copyAllowancesFromDocument(fromToMap);

            jsResult.records = new List<Sales_Order__c>{so};
            jsResult.total = 1;

        } catch (Exception e){
            System.debug(loggingLevel.Error, e.getMessage() + ' ' + e.getStackTraceString());
            Database.rollback(sp);
            jsResult.success = false;
            jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR );
           
        }

        return jsResult;
	}

	public static void getSolForRMA(Id soId){
		
		Set<String> solFieldStrings = new set<string>{  'id', 'Name', 'Returned_To_Vendor__c', 'Status__c', 'Sales_order__r.Type__c', 'Sales_order__r.Reason_Code__c','Sales_Order__r.Company__r.Use_Warranty_Repairs__c', 'Company__c', 'Sales_Order__r.Company__c',
                                                        'Description__c', 'Discount_Percent__c', 'Currency__c','Item_Specification__c','Company__r.Use_Warranty_Repairs__c',
                                                        'Line__c', 'Product__c', 'Quantity_Backordered__c', 'Quantity_Ordered__c', 'Quantity_Shipped__c', 'Ship_From_Location__c',
                                                        'Required_Date__c', 'Sales_Order__c', 'Selling_UOM__c', 'Unit_Price__c', 'Memo__c', 'Weight_UOM__c', 'Dimension_UOM__c',
                                                        'Line_Type__c', 'Fulfillment_Source__c','Related_Sales_Order_Line__c','Product__r.Item_Specification__r.Type__c','Product__r.Item_Specification__r.Name','Product__r.Item_Specification__c'
         };

        solFieldStrings.addAll( util.getAllCustomFieldsFromObject( 'Sales_Order__r.', 'Sales_Order__c'));

		String whereClause = ' Sales_Order__c = :soId and Product__r.Product_Type__c != \'Warranty\' and Price_Type__c != \'Recurring\'';
        String queryString = util.generateQueryFromFieldSet( 'Sales_Order_Line__c', new set<string>{'RMALine'}, 
                    solFieldStrings,
                     whereClause + 
                     ' order by Sales_Order_Line__c.Name, Name ASC');
        
        solList =  (List<Sales_Order_Line__c>) Database.query( queryString );

        for (Sales_Order_Line__c sol : solList) {
            sol.Required_Date__c = null;
        }
	}

    public class SalesOrderLineWrapper {
        
        public Sales_Order_Line__c soLine { get; set; }
        public List<String> errMsgs {get; set; }

        public SalesOrderLineWrapper(Sales_Order_Line__c soLine, List<String> errMsgs){
            this.soLine = soLine;
            this.errMsgs = errMsgs;
        }
    }
}