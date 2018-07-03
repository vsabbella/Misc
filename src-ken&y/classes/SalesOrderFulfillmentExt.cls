public with sharing class SalesOrderFulfillmentExt extends GridRelatedListController{

    public class SalesOrderFulfillmentExtException extends Exception{

    }

    public static Id soId {get; set;}
    public static Sales_Order__c so {get; set;}
    public static Sales_Order_Line__c sorderLine { get; set; }
    public static List<Sales_Order_Line__c> solList;

    public GridRelatedListController.GridRelatedListConfig solGridConfig {get; set;}
    public String solFieldList {get; set;}

    public static Map<Id, List<String>> errorMsgs;

    private static SchemaUtil util = SchemaUtil.getInstance();

    public static Boolean serialTracked {get;set;}
    public string serialFieldList { get; set; }
    public Integer gridSize {get;set;}

    public SalesOrderFulfillmentExt(ApexPages.StandardController con) {
    	soId = con.getId();

    	try {

            if (!useIGRs){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'System is not configured to use fufillments.'));
                return;
            }
	    	solList = getLinesForFulfillment();

	    	if (solList.size() == 0 ){
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'NO Sales Order Lines available to be fufilled.'));
	            return;
	        }
	        so = solList[0].Sales_Order__r;
			//KNDY-16550 - Fulfill SO only if approved
            if (SalesOrderService.checkifApprovalProcessDefined()){
                if (so.Approval_Status__c != 'Approved'){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You cant fulfill an unapproved sales order')); 
                    return;
                }
            }
            
	        initializeGrid();

	    } catch( Exception e){

            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    public static boolean useIGRs { 
        get 
        {
            boolean useIGR = true;  //KNDY-8708
            Map<string,Configuration__C> mapConfig = Configuration__C.getAll();  
            if(mapConfig.containsKey('Use Invoice Grouping Rules')){
                if(!mapConfig.get('Use Invoice Grouping Rules').value__c.equalsIgnoreCase('true')){
                         useIGR=false;                                                                
                 }
            } 
            return useIGR;
        }
    }

    public void initializeGrid(){
    	solGridConfig = new GridRelatedListController.GridRelatedListConfig();
        solGridConfig.uniqueId = 'SOLGrid';
        solGridConfig.title = 'Sales Order Lines';
        solGridConfig.objectName = 'Sales_Order_Line__c';
        solGridConfig.parentRecord = so;
        solGridConfig.parentField ='Sales_Order__c';
        solGridConfig.fieldset = 'SOLFulfillment_RO';
        solGridConfig.buttons = 'Fulfill, search ,Populate Quantities ';
        solGridConfig.alwaysUseFullDateTimeFormat = false;

        setSalesOrderLinesFieldList();
    }

    public String getSolGridConfigJSON(){
        String configStr = JSON.serialize(this.solGridConfig);
        return configStr;
    }    

    public void setSalesOrderLinesFieldList() {
    	 if (String.isBlank(solFieldList) && solGridConfig != null){
            // get SHL fields into a List
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            List<FieldInfo> soFieldInfoList = FieldInfo.fetchJsonFieldInfos(solGridConfig.objectName, solGridConfig.fieldset);
            List<FieldInfo> fulFieldInfoList = FieldInfo.fetchJsonFieldInfos('Fulfillment__c', 'SalesOrderFulfillment');

            FieldInfo fulfillmentQty = new FieldInfo();
            fulfillmentQty.field = 'qtyToFulfill';
            fulfillmentQty.fieldType = 'double';
            fulfillmentQty.precision = 18;
            fulfillmentQty.scale = 6;
            fulfillmentQty.title = 'Quantity To Fulfill';
            fulfillmentQty.editable = true;

            Set<String> hiddenFields = new Set<String> { 'Id'};

            for(Integer i = 1; i < soFieldInfoList.size(); i++){
            
                String fieldName = soFieldInfoList[i].field;
            
            	soFieldInfoList[i].editable = false;
            	soFieldInfoList[i].field = 'soLine.' + fieldName;
            }
            fieldInfoList.addAll(soFieldInfoList);

            //for(Integer i = 1; i < fulFieldInfoList.size(); i++){
            for (FieldInfo fi : fulFieldInfoList){
                String fieldName = fi.field;
                fi.field = 'fulfillment.' + fieldName;
                fi.hidden = hiddenFields.contains(fieldName);
            }
            fieldInfoList.addAll(fulFieldInfoList);

            fieldInfoList.add(fulfillmentQty);

            solFieldList = JSON.serialize(fieldInfoList);

            // fi is used to index the serial grid values on the ui
            FieldInfo fi = new FieldInfo('','','integer');
	        fi.editable = false;
            
            fieldInfoList = new list<FieldInfo>{fi};
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial'));
	        
	        serialFieldList = JSON.serialize(fieldInfoList);
            
            gridSize = fieldInfoList.size() * 150;
        }
    }

    @RemoteAction 
    public static JsonResult createFulfillments (List<SOLWrapper> solWrapperList, List<String> dateFields){
    	JsonResult  jsResult = new JsonResult();
        List <SOLWrapper> result = new List <SOLWrapper>();

        List<String> cleanDateFields = cleanWrapperDateFields( dateFields );
        
        Savepoint sp = Database.setSavepoint();
        
        try {

        	Map<Id,Fulfillment__c> solFulfillMap = new Map<Id,Fulfillment__c>();
            //List<Skid__c> skidList = new List<Skid__c>();
            Map<ID, List<Serial__c>> serialMap = new Map<ID, List<Serial__c>>();
            Map<Id, Sales_Order_Line__c> solMap = new Map<Id, Sales_Order_Line__c>();

            Map<Id, Decimal> solToSkidQty = new Map<Id, Decimal> ();
            Map<String, Skid__c> skidMap = new Map<String, Skid__c>();

            Set<Id> parentSols = new Set<Id>();
            List<String> attributes = SkidService3.attributesForPutaway();
            attributes.add('Sales_Order_Line__c');
            list<SkidService3.SerialWrapper> serialWrapperList = new list<Skidservice3.SerialWrapper>();
            List<Serial_Transaction__c> stList = new List<Serial_Transaction__c>();
            Set<String> processedSerials = new set<String>(); //to avoid duplicating serial transactions when skids merge.
            map<string,id> uniqueToSol = new map<string,id>();

        	for (SOLWrapper solw : solWrapperList){
        		KendoUtils.UpdateDateFields(solw.soLine, cleanDateFields);
                
                if (solw.qtyToFulfill < 0){
                    throw new SalesOrderFulfillmentExtException(Label.Cannot_fulfill_negative_quantity);
                }
                // prevent adding too much qty
                Decimal diff;
                
                if(solw.soLine.Quantity_Ordered__c <0)
                	diff = KSE.addQuantityToField(solw.soLine.Quantity_Ordered__c,0)*-1 - KSE.addQuantityToField(solw.soLine.Quantity_Fulfilled__c,0)*-1;
                else
                	diff = KSE.addQuantityToField(solw.soLine.Quantity_Ordered__c,0) - KSE.addQuantityToField(solw.soLine.Quantity_Fulfilled__c,0);
                	
                if (solw.qtyToFulfill > diff){
                    throw new SalesOrderFulfillmentExtException(Label.Quantity_to_fulfill_is_greater_than_available_quantity_to_fulfill+'  '+ solw.soLine.Name);
                }

                // update fulfillment with default information.
               
               
                
                if(solw.soLine.Quantity_Ordered__c < 0) 
                {
                    if(solw.soLine.sales_order__r.Type__c == 'RMA-Credit' || solw.soLine.sales_order__r.Type__c == 'RMA-Replacement')
                    {
                	    solw.fulfillment.Quantity__c = -(solw.qtyToFulfill);
                	   solw.fulfillment.Type__c = Label.RMA_Without_Receipt;
                    }
                    else
                    {
                        solw.fulfillment.Quantity__c = -(solw.qtyToFulfill);
                	    solw.fulfillment.Type__c = 'RMA';
                    }
                }
                else{
                solw.fulfillment.Quantity__c = solw.qtyToFulfill;
                solw.fulfillment.Type__c = 'Install Base';
                }
                
                
        		solFulfillMap.put(solw.soLine.id, solw.fulfillment);
                solMap.put(solw.soLine.id, solw.soline);

                if (solw.soLine.Parent_Sales_Order_Line__c != null){
                    parentSols.add(solw.soLine.Parent_Sales_Order_Line__c);
                }
                
                if (solw.trackSerial){
                    decimal count = 0;
                    for (skidService3.SerialWrapper sw : solw.serialWrapperList){
                        if(sw.skid != null){
                        sw.skid.Quantity__c = 0; //solw.qtyToFulfill; // B.A setting this to 0 so FulfillmentService doesn't double the skid qty when creating the install base fulfillment
                        }
                        
                        if(solw.soLine.Product__r.Item__r.Track_Install_Base__c != true || solw.soLine.sales_order__r.Ship_to__r.Track_Install_Base__c != true){
                            
                            inventory_transaction__c it = new inventory_transaction__c(item__c = solw.soLine.Product__r.Item__c,company__c = solw.soLine.sales_order__r.company__c);
                            sw.it = it;
                            sw.skid = null; 
                            
                          
                        }
                        for (Serial__c sr : sw.serialList){
                        	String uniqueKey ;
                            if(sw.skid != null){
                                sr.company__c = sw.skid.Company__c;
                                sr.item__c = sw.skid.Item__c;
                               uniqueKey = sw.skid.Company__c+'-'+sw.skid.Item__c+'-'+sr.Name; 
                            }else{
                               
                               sr.company__c = sw.it.Company__c;
                               sr.item__c = sw.it.Item__c; 
                               sr.allow_reentry__c = true; 
                               uniqueKey = sw.it.Company__c+'-'+sw.it.Item__c+'-'+sr.Name; 
                            }
                            
                            
                            if( count < solw.qtyToFulfill){
                            	if (sr.Name == null){
                                	throw new SalesOrderFulfillmentExtException(Label.Number_of_serials_specified_does_not_match_the_quantity_to_fulfill +' '+ solw.qtyToFulfill +' for Sales Order Line: '+ solw.soLine.Name);
                            	} else if (processedSerials.contains(uniqueKey)){
                                	throw new SalesOrderFulfillmentExtException(Label.Duplicate_serial_name_found +' '+ sr.Name + '\' on line: ' + solw.soLine.Name);
                            	}
                                
                                Serial_Transaction__c st = new Serial_Transaction__c(
                                	Item__c = sr.Item__c, 
                                    Fulfillment__c = solw.fulfillment.id,
                                	Serial__r = new Serial__c(unique_Key2__c = uniqueKey),
                                	Type__c = 'Install Base',
                                	Company__c = sr.Company__c
                            	);
      
                            	if (solw.soLine.sales_order__r.Type__c == 'RMA-Credit' || solw.soLine.sales_order__r.Type__c == 'RMA-Replacement')
                            	    	st.Type__c = Label.RMA_Without_Receipt;
                                uniqueToSol.put(uniqueKey, solw.soLine.id);
                            	count++;
                            	processedSerials.add(uniqueKey); //the same serial cannot be issued or received more than once in the same transaction.
                            	stList.add(st);
                            }
                        }
                        
                        
                        serialWrapperList.add(sw);
                        //skidList.add(sw.skid);
                        String key = sw.skid.Customer__c + '|' + sw.skid.Product__c + '|' + sw.skid.Sales_Order_Line__c;
                        if(sw.skid != null){
                          skidMap.put(key, sw.skid);  
                        }
                        
                        if (sw.serialList.size() != solw.qtyToFulfill*sw.conversionFactor){
                            throw new SalesOrderFulfillmentExtException( solw.soLine.Name+': '+Label.Number_Of_Serials_Not_Matching_Quantity);
                        }
                        serialMap.put(solw.soLine.id, sw.serialList); // this is fine since we're expecting 1 serialwrapper
                        solToSkidQty.put(solw.soLine.id, solw.qtyToFulfill);
                    }
                }
                   
        	}
            
            map< list<String>, SkidService3.SerialWrapper > toSkids =   SkidService3.putAwayService(serialWrapperList,attributes,new Map<String,Boolean>{ SkidService3.MIXED_SERIAL => true });
           
            
            
            Map<Id,Sales_Order_Line__c> parentLineMap;
            if (!parentSols.isEmpty()){
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Product__r.Item__r.Track_Install_Base__c'
				});
				soql.setWhereClause('Id IN :parentSols');

				parentLineMap = new Map<Id,Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));

            }
			

            Map<Id, Skid__c> solToSkid = new Map<Id, Skid__c>();
            for (skid__c skid : skidMap.values()){
                solToSkid.put(skid.Sales_order_Line__c, skid);
            }
            // iterate through the fulfillment map and populate skids on the child fulfillments if the parents are tracking IBS
            for (id solId : solFulfillMap.keySet()){
                Sales_order_Line__c sol = solMap.get(solId);


                // if parent are tracking IBS, add the skid to the child fulfillments
                if (sol.Parent_Sales_Order_Line__c != null
                    && parentLineMap != null
                    && parentLineMap.containskey(sol.Parent_Sales_Order_Line__c)
                    && parentLineMap.get(sol.Parent_Sales_Order_Line__c).Product__r.Item__r.Track_Install_Base__c
                    && solToSkid.containsKey(sol.Parent_Sales_Order_Line__c)
                    && solToSkid.get(sol.Parent_Sales_Order_Line__c) != null){

                    //solFulfillMap.get(solId).Skid__c = solToSkid.get(sol.Parent_Sales_Order_Line__c).id;
                    list<string> key = SkidService3.generateKey( solToSkid.get(sol.Parent_Sales_Order_Line__c),attributes );
                    solFulfillMap.get(solId).Skid__c = toSkids.get(key).skid.id;    
                }
            }

             

        	if (solFulfillMap.keySet().size() > 0 ){
        		FulfillmentService.fulfillSalesOrders(solFulfillMap.keySet(), solFulfillMap);
        	}
            
            list<Serial_Transaction__c> updateSerialTransactionList = new list<Serial_Transaction__c>();
            for(Serial_Transaction__c st :stList){
                st.Fulfillment__c = solFulfillMap.get(uniqueToSol.get(st.serial__r.unique_Key2__c)).id;
                updateSerialTransactionList.add(st);
            }
            if (!stList.isEmpty()){
                DML.insertAsUser(stList);
            }
           
            jsResult.records = solWrapperList;
            jsResult.total = solWrapperList.size();

		} catch (Exception e) {
            
            Database.rollback(sp);
            System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());
                  
            jsResult.success = false;
            jsResult.hasExceptions=true;
            jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
         }
        
        return jsResult;
    }


    public static list<String> cleanWrapperDateFields( list<String> dateFields ){
        
        list<String> cleanDateFields = new list<String>();
        
        for( String dateField : dateFields ){
           
           if( dateField != null && dateField.length() > 0 ){ 
                List<String> splitResults = dateField.split('\\.');
                cleanDateFields.add(splitResults[splitResults.size()-1]);
           }
        }
            
        return cleanDateFields;
    }

    public static List<SOLWrapper> getSolWrapper(){
    	List<SOLWrapper> solwList = new List<SOLWrapper>();

    	List<String> attributes = new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'));
        Map<Id, List<SKID__c>> inTransitSKidmap = new Map<Id, List<SKID__c>>();

        for (Sales_Order_Line__c sol : solList){
        	// create skids? populate map? 

        	// retrieve tracked Attributes from what location? set to null for now. ship from location? no?
        	List<String> trackedAttributes = new list<String>( SkidService3.trackedAttributes(attributes, null, sol.Product__r.Item__r ));
                         
            //Pass Map of ASNLine and List of SKIDs	
            List<SkidService3.serialWrapper> swlist = createSerialWrapper(sol, trackedAttributes, inTransitSKidmap);

            SOLWrapper solw = new SOLWrapper(sol, swlist);
            solwList.add(solw);

        }

        return solwList;

    }


    // the SKIDS created here will need to match the install base skids created in the fulfillment trigger.
    public static List<SkidService3.SerialWrapper> createSerialWrapper(Sales_Order_Line__c sol, List<String> attributes, Map<Id, List<SKID__c>> inTransitSKidmap){

    	List<SkidService3.SerialWrapper> serialwrapperlist = new List<SkidService3.SerialWrapper>();
		SkidService3.SerialWrapper serialwrapper;
		List<Serial__c> serialList = new List<Serial__c>();
		List<SKID__c> skidlist = new List<SKID__c>();   
		Decimal conversionFactor = KSE.getConversionFactor(sol);
		if(conversionFactor == null){
			conversionFactor = 1;
		}
    	SKID__c skid = new SKID__c();
        skid.Company__c = sol.Company__c;

        skid.Type__c = 'Install Base';

        // used for Install Base trigger key.
        skid.Customer__c = sol.Customer_Site__c != null ? sol.Customer_Site__c : sol.Sales_Order__r.Ship_To__c;
        //skid.Customer__c = sol.Sales_Order__r.Ship_To__c;
        
        if(sol.Parent_Sales_Order_Line__r.Product__c != null && sol.Parent_Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c){
            skid.Product__c = sol.Parent_Sales_Order_Line__r.Product__c;
            skid.Item__c = sol.Parent_Sales_Order_Line__r.product__r.Item__c;
            skid.Item__r = sol.Parent_Sales_Order_Line__r.Product__r.Item__r;
            skid.Sales_Order_Line__c = sol.Parent_Sales_Order_Line__c;
            //skid.Sales_Order_Line__r = sol.Parent_Sales_Order_Line__r;
        } else {
            skid.Product__c = sol.Product__c;
            skid.Item__c = sol.product__r.Item__c;
            skid.Item__r = sol.Product__r.Item__r;
            skid.Sales_Order_Line__c = sol.Id;
            //skid.Sales_Order_Line__r = sol;
        }

        if(sol.product__r.Item__r.Item_Attribute__c!= null && sol.product__r.Item__r.Item_Attribute__r.Serial_Number__c){
           
            Serial__c ser = new Serial__c(Company__c = sol.sales_order__r.company__c,Item__c = sol.product__r.item__c);
        	serialList.add(ser);
    	}
        if(sol.Product__r.Item__r.track_install_base__c == true && sol.sales_order__r.Ship_to__r.Track_install_base__c == true){
         serialwrapper = new SkidService3.SerialWrapper(skid, serialList);   
        }else{
         serialwrapper = new SkidService3.SerialWrapper(new inventory_transaction__c(item__c = sol.Product__r.Item__c,company__c = sol.sales_order__r.company__c), serialList);   
        }
    	serialwrapper.conversionFactor = conversionFactor;
    	serialwrapperlist.add(serialwrapper);

    	return serialwrapperlist;
    }

    @RemoteAction 
    public static JsonResult getSOLines(String salesOrderId){
    	JsonResult  jsResult = new JsonResult();

        List <SOLWrapper> result = new List <SOLWrapper>();

        soId = (Id) salesOrderId;

        errorMsgs = new Map<Id, List<String>>(); 

        try{
            
            solList = getLinesForFulfillment();
            if (solList.size() == 0 ){
                return new JsonResult();
            }
            List<SOLWrapper> solWrapperList = getSolWrapper();

            result.addAll(solWrapperList);

            if(result.size() > 0){
                if(result[0].soLine.getSObject('Company__r').get('Serial_Control__c') != null && 
                    result[0].soLine.getSObject('Company__r').get('Serial_Control__c') == 'At receipt and all processes'){
                
                    jsResult.additionalInfo = 'true'; // passing along the info of whether the page needs serial control at the company level
                }
                else{
                    jsResult.additionalInfo = 'false';
                }
            }

            jsResult.records = result;
            jsResult.total = result.size();

        } catch (Exception e){

            System.debug(logginglevel.error, 'Exception: ' + e.getMessage() );
            
            jsResult.success = false;
            jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        
        return jsResult;
    }

    public static List<Sales_Order_Line__c> getLinesForFulfillment(){

    	Set<String> solFieldStrings = new set<string>{ 'id', 'Customer_Site__c', 'Has_Exceptions__c', 'Status__c', 'Name', 'Sales_Order__c','Product__r.Item__r.Packaging_UOM__c','Parent_Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c',
        'Product__r.Item__r.Stocking_UOM__c','Product__r.Item__r.Non_Inventory__c', 'Product__r.Item__r.Source__c', 'Quantity_Ordered__c', 'Quantity_Fulfilled__c', 'Product__r.Item__r.Non_Shippable__c',
        'Parent_Sales_Order_Line__c', 'Parent_Sales_Order_Line__r.Product__c', 'Parent_Sales_Order_Line__r.Product__r.Item__c', 'Parent_Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c',
        'Sales_Order__r.Status__c', 'Sales_Order__r.Approval_Status__c', 'Sales_Order__r.Name', 'Sales_Order__r.Type__c', 'Company__c', 'Non_Shippable__c','Product__r.item__c','Product__r.Item__r.Track_Install_Base__c','sales_order__r.Ship_to__r.Track_install_base__c',
        'Company__r.Serial_Control__c', 'Sales_Order__r.Ship_to__c','Sales_Order__r.Company__c','product__r.item__c', 'Product__r.Item__r.Container__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'};

    	
        
        Set<String> fieldList = new set<String>{'Item__r.Container__c','Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__c'};
        fieldList.addAll(util.getAllCustomFieldsFromObject(null, 'Skid__c'));            
		fieldList.addAll( util.getAllCustomFieldsFromObject('Item__r.item_attribute__r.','item_attribute__c') );
        /*String subquery = util.generateQueryFromFieldSet( 'Skid__c', new set<string>{''}, 
                   			fieldList, 'Quantity__c>0'); 
        subquery = '('+subquery.replace('FROM Skid__c','FROM SKIDs__r')+')';*/

        solFieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('product__r.item__r.item_attribute__r.','item_attribute__c') );
		
		String whereClause =  ' Sales_Order__c = :soId ' +
			                    ' and (Non_Shippable__c = true or Quantity_Ordered__c < 0) ' +
			                    ' and (product__r.item__r.Source__c != \'Kit\') ' +
			                    //' and Status__c != \'Closed\' ' +
			                    ' and Has_Exceptions__c = false ' + 
			                    ' order by Sales_Order_Line__c.Name, Name ASC ';
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
        soql.addFields('SOLFulfillment_RO');
        soql.addFields(solFieldStrings);
        soql.setWhereClause(whereClause);
		
        List<Sales_Order_Line__c> solQryList =  (List<Sales_Order_Line__c>) Database.query(soql.getQuery());

        return solQryList;
    }

    //-----Undo Fulfillment
      
   @RemoteAction
    public static JsonResult getFulfillments(String solId){
        
        
       JsonResult result = new JsonResult();
        list<Fulfillment__c> fmts = new list<Fulfillment__c>();
        try{ 
          
            result.records = getWrapper((id)solId,null);
            
           
        } catch (Exception e){
            JsonResult  jsResult = new JsonResult();
            jsResult.success = false;
            jsResult.addMessage(e.getMessage() + ' - ' +  e.getStackTraceString(), ApexPages.Severity.ERROR);
            return jsResult;
        }
        return result;
    }
    public static list<SOLWrapper> getWrapper( id solId, list<id> fmtIds){
   		
			
			String whereClause = 'Id not in (Select Fulfillment__c from Customer_Invoice_Sub_Line__c where (Customer_Invoice_Line__r.Customer_Invoice__r.Status__c in(\'Open\',\'Closed\') or Customer_Invoice_Line__r.Has_Exceptions__c = true '+
            'or Customer_Invoice_Line__r.Customer_Invoice__r.Has_Exceptions__c = true)   ) '+
            ' AND Id NOT IN (Select Fulfillment__c from Customer_Invoice_Sub_Line__c where  '+
            ' (Fulfillment__r.Fulfillment_Fully_Invoiced_2__c = true) ) '+
            ' and  Invoice_Ready__c = true and Invoice_Hold__c = false and Status__c = \'Complete\' and (type__c = \'Install Base\' or type__c = \'RMA Without Receipt\')'; 
            
            
            if(solId != null){
              whereClause += ' AND Sales_Order_Line__c =: solId ';  
            }else{
               whereClause += ' AND ID IN: fmtIds ';   
            }
            SOQLUtil soql = new SOQLUtil('fulfillment__c', true); 
			soql.addFields(new set<string>{
				'Company__c','Product__r.item__c'
			});
            soql.addFields('UndoFulfillment');
            soql.addallcustomfields(skid__c.sobjecttype,'skid__r');//to get all fields of skid related to fulfillment
            soql.addFields(new set<String>{'skid__r.item__r.Stocking_UOM__c','skid__r.Item__r.Packaging_UOM__c'});
			soql.setWhereClause(whereClause );
			list<fulfillment__c >fmts = Database.query(soql.getQuery());
          	if (fmts.size() == 0 ){
	            throw new SalesOrderFulfillmentExtException('No fulfillments available  for undo fulfillments');  
            }
            
            set<id> fid = new set<id>();
            for(fulfillment__c f:fmts){
              fid.add(f.id) ; 
            }
            Set<String> serialTransactionFields = new Set<String>(); 
            serialTransactionFields.addAll(SchemaUtil.getInstance().getAllCustomFieldsFromObject(null,'Serial_Transaction__c'));
            soql = new SOQLUtil('Serial_Transaction__c', true);
            soql.addFields(serialTransactionFields);
            soql.addallcustomfields(serial__c.sobjecttype,'serial__r');//to get all fields of skid related to fulfillment
            soql.setWhereClause('fulfillment__c IN :fid ');
            soql.setOrderByClause('createddate asc');
            list<Serial_Transaction__c> serialTranList = Database.query(soql.getQuery());
            map<id,list<Serial_Transaction__c>> fIdToSerTrancMap = new map<id,list<Serial_Transaction__c>>();
            for(Serial_Transaction__c st:serialTranList){
                if(!fIdToSerTrancMap.containsKey(st.Fulfillment__c)){
                    fIdToSerTrancMap.put(st.Fulfillment__c, new list<Serial_Transaction__c>());  
                }                         
                    fIdToSerTrancMap.get(st.Fulfillment__c).add(st); 
            }
            
               
            List<SOLWrapper> wrapList = new List<SOLWrapper>();
            
            for(Fulfillment__c f : fmts){
                
                list<Serial_Transaction__c> serTranList = new  list<Serial_Transaction__c>();
                if(fIdToSerTrancMap.containsKey(f.id)){
                    serTranList = fIdToSerTrancMap.get(f.id);
                }
                set<serial__c > serSet = new set<serial__c>();
                for(Serial_Transaction__c st:serTranList){
    
                   if(st.Type__c == 'Install Base' || st.Type__c == Label.RMA_Without_Receipt){
                        serSet.add(st.serial__r);
                    }else{
                        if(st.Type__c == 'Undo Install Base'){
                          serSet.remove(st.serial__r);  
                        }
                    }
                }
                SOLWrapper solw ;
                if(f.skid__r != null){
                 solw = new SOLWrapper(f, new list<SkidService3.SerialWrapper>{new SkidService3.SerialWrapper(f.skid__r,new list<serial__c>(serSet))});
                }else{
                 solw = new SOLWrapper(f, new list<SkidService3.SerialWrapper>{new SkidService3.SerialWrapper(new inventory_transaction__c(item__c = f.product__r.item__c,company__c = f.company__c),new list<serial__c>(serSet))});    
                }
                wrapList.add(solw);
            }
        return wrapList;
            
    }
      @RemoteAction
     public static JsonResult cancelFulfillments(list<id> fmtIds){
       
          JsonResult result = new JsonResult();
          Savepoint sp = Database.setSavepoint();
         
          try{
              List<String> attributes = SkidService3.attributesForPutaway();
              attributes.add('Sales_Order_Line__c');
             
              list<SkidService3.SerialWrapper> serialWrapperList = new list<Skidservice3.SerialWrapper>();
              list<fulfillment__c> flist = new list<fulfillment__c>();
              list<Serial_Transaction__c> stList = new list<Serial_Transaction__c>();
              List<SOLWrapper> wrapList = getWrapper( null,  fmtIds);
              for(SOLWrapper sw:wrapList){
                  if(sw.serialWrapperList[0].skid != null){
                  sw.serialWrapperList[0].skid.quantity__c = sw.serialWrapperList[0].skid.quantity__c - sw.fulfillment.quantity__c;
              		}
                  serialWrapperList.add(sw.serialWrapperList[0]);
                  sw.fulfillment.status__c = 'Cancelled'; 
                  flist.add(sw.fulfillment);
                  
                  for(serial__c serial:sw.serialWrapperList[0].serialList){
                     Serial_Transaction__c st = new Serial_Transaction__c(
                                    Serial__c = serial.id,
                                    Type__c = 'Undo Install Base',
                                    Item__c = serial.Item__c,
                         			fulfillment__c = sw.fulfillment.id,
                                    Company__c = serial.Company__c
                                ); 
                      stList.add(st);
                  }
                  
              }
            SkidService3.putAwayService(serialWrapperList,attributes,new Map<String,Boolean>{ SkidService3.Undo_Serial => true, SkidService3.UPDATE_SKID_QUANTITY => true });//SkidService3.DELETE_SKIDS => true,
            
            if (!stList.isEmpty()){
                DML.insertAsUser(stList);
            }
            DML.updateAsSystem(flist);
           
        } catch (Exception e){
            Database.rollback(sp);          
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
     public String getFulConfigJson() {
        GridRelatedListController.GridRelatedListConfig fulConfig = new GridRelatedListController.GridRelatedListConfig();
        fulConfig.uniqueId = 'fulGrid';
        fulConfig.title = 'Undo Fulfillment';
        fulConfig.objectName = 'Fulfillment__c';
        fulConfig.fieldset = 'UndoFulfillment';
        fulConfig.buttons = 'Expand All,Collapse All,Undo Fulfillment';
        fulConfig.alwaysUseFullDateTimeFormat = false;
        return JSON.serialize(fulConfig);
    }
     
    public String getFulFieldList() {
        List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Fulfillment__c','UndoFulfillment',null,true);
        for (FieldInfo fi:fiList) {
            fi.field = 'fulfillment.' + fi.field;
        }
        fiList.remove(0); // Remove Id field from the list
        return JSON.serialize(fiList);
    }
    
    public String getSerialFieldList() {
        List<String> flds = new List<String>{ 'Name' };
        List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Serial__c',flds);
        return JSON.serialize(fiList);
    }
    
    
    
    public class SOLWrapper {

        public Sales_Order_Line__c soLine { get; set; }
        public Decimal qtyToFulfill {get; set; }
        public Fulfillment__c fulfillment {get; set; }
        public list<SkidService3.SerialWrapper> serialWrapperList { get; set; } //currently, only one value will be in this list. This would change if we expands attributes for this
        public List<String> errMsgs {get; set; }
        public Boolean trackSerial;

        // is this created correctly, where am do I init?
        public SOLWrapper(Sales_Order_Line__c soLine, list<SkidService3.SerialWrapper> swList){
			this.soLine = soLine;

            this.fulfillment = new Fulfillment__c();
            this.qtyToFulfill = 0;
            //populate button is used to populate qty to fulfill
            /*if(soLine.Quantity_Ordered__c <0){
            	
            	this.qtyToFulfill = KSE.addQuantityToField(soLine.Quantity_Ordered__c,0)*-1 - KSE.addQuantityToField(soLine.Quantity_Fulfilled__c,0) *-1;
            }
            else{
              this.qtyToFulfill = KSE.addQuantityToField(soLine.Quantity_Ordered__c,0) - KSE.addQuantityToField(soLine.Quantity_Fulfilled__c,0);  
            }*/
            
			this.trackSerial = (soLine.product__r.Item__r.Item_Attribute__c!= null && soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c);
			this.serialWrapperList = swList;
		}
        public SOLWrapper(Fulfillment__c ff, list<SkidService3.SerialWrapper> swList){
            this.fulfillment = ff;
			this.serialWrapperList = swList;
		}
    }
    
}