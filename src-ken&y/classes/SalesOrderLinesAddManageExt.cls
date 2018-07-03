public with sharing class SalesOrderLinesAddManageExt {
    public Boolean selectAllChecked { get; set; }
    Decimal hld_bk_val;
    ID def_loc;
    public Boolean selecterror {get; set;}
    private SegmentService SS = new SegmentService();
    public Integer rowNum;
    public Integer displaySave_Return = 0; // counter for messages
    
    public Boolean displayPopup {get;set;}
    public Integer totalNoLines;
    public Integer pageSize {get;set;} { pagesize = 10;}
    public Accounting_Default__c VFnewOverride {get; set ; }  { VFnewOverride = null; }  // for use in the popup
    public  apexpages.StandardController controller;
    public Integer pageNumber = 1;
    
    public Sales_Order__c theSalesOrder { get;  set;}			// the order we will operate on , used by the page
    // public List< Sales_Order_Line__c > allLines; 				// filled at constructor time, by query
    public List<SOLineWrapper> soLineList { get;set; }   	// one page worth of the sales order
    
    private Decimal max_line_number = 0; 
	public Boolean addNewClicked {get; private set;} { addNewClicked = false;}
    private ApexPages.StandardSetController setCon;
    
    public boolean concurrencyConflict {get;set;}
    
    private ConcurrencyService.ConcurrencyDetail concurrency;
    public String UPCField{get;set;}    
	
    public Boolean quantityChange {get; set;} {quantityChange = false;}
	
	public void checkConcurrency(){
        //This only support a single visualforce page - manually passing pageName for now
		//string currentURL = URL.getCurrentRequestUrl().toExternalForm();
        //string currentPage = currentURL.substringAfterLast('/').substringBefore('?');
        concurrency = ConcurrencyService.checkConcurrency('SalesOrderLinesAddManage', controller.getId());
        concurrencyConflict = concurrency.concurrencyConflict;
        if(concurrencyConflict){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_unavailable + concurrency.processOwner.name + ' / ' + concurrency.releaseDateTime.formatLong() ));
        }
	}
	
	public void releaseConcurrency(){
		ConcurrencyService.releaseConcurrency('SalesOrderLinesAddManage', controller.getId());
	}
                 
    public SalesOrderLinesAddManageExt(ApexPages.standardcontroller con) {      	
        controller = con;

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = con.getId();
		
		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c','Subtotal__c','Ship_From_Location__c','Pricing_Date__c','Date_Time_Ordered__c','Required_Date__c','Pricebook__c',
			'Type__c','Company__c','Customer__r.Pricebook__c','Customer__r.Order_Quantity_Factor_At__c','Pricebook__r.Name','Weight_UOM__c',
			'Weight_UOM__r.Name','Dimension_UOM__c','Dimension_UOM__r.Name'
		});
		soql.setWhereClause('Id = :conId');

		theSalesOrder = Database.query(soql.getQuery());

        /*
            This one is not good as VF runtime bug makes it tough to grab fields referenced on the page
            http://salesforce.stackexchange.com/questions/7973/i-am-getting-a-sobject-row-was-retrieved-via-soql-without-querying-the-requested        
         */
        //theSalesOrder=(Sales_Order__c)con.getRecord(); 
        selecterror = false;
        selectAllChecked = false;
        
        if ( theSalesOrder.Status__c == 'Closed' ) {  // KNDY-631
            Apexpages.addMessage( new Apexpages.Message( 
                ApexPages.Severity.ERROR, Label.SO_closed) );
            selecterror = true;
        }
        
        if (theSalesOrder.id == null) {
            hld_bk_val = 0.0;
        }
        else {
            hld_bk_val = theSalesOrder.Subtotal__c;
            def_loc = theSalesOrder.Ship_From_Location__c;
        }
       
        loadAllLinesFromDatabase();
        UPCField = KSE.NamespaceUU + 'UPC_Code__c'; 
    }
    
     public pageReference prod_Update(){
     	
     	 List<Product__c> ProdList = new List<Product__c>();            	 	        	
	     String upcCode = ApexPages.currentPage().getParameters().get('upcCode');
	     Integer LineIndex = Integer.valueof(ApexPages.currentPage().getParameters().get('index'));	    
	     
	     if(upcCode!=null){
		     	
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Name','UPC_Code__c','Item__r.Fulfillment_Source__c'
			});
			soql.setWhereClause('UPC_Code__c = :upcCode and Primary__c = :true');
			soql.setLimit(1);
			
			ProdList = Database.query(soql.getQuery());

        	if (ProdList.size() > 0) {
     			soLineList[LineIndex].soline.Product__c = ProdList[0].Id;      			
                
                String pricingDate = '';
                if (theSalesOrder.Pricing_date__c != null) {
                    pricingDate = theSalesOrder.Pricing_date__c.format();

                } else if (theSalesOrder.Date_Time_Ordered__c != null){
                    pricingDate = theSalesOrder.Date_Time_Ordered__c.date().format();

                }

	            Sales_Order_Line__c solineRet = SalesOrderLineExt.getSOLineInfo(theSalesOrder.Company__c, pricingDate, ProdList[0].Name, theSalesOrder.Pricebook__c, null, theSalesOrder.Customer__r.Pricebook__c);
		        soLineList[LineIndex].soline.Unit_Price__c = solineRet.Unit_Price__c;
		        soLineList[LineIndex].soline.Description__c = solineRet.Description__c;	        
		        soLineList[LineIndex].soline.Pricebook__c =  solineRet.Pricebook__r.Id;
		        soLineList[LineIndex].soline.Pricebook__r =  solineRet.Pricebook__r;	
		        soLineList[LineIndex].soline.Product__r =  solineRet.Product__r; // KNDY-4858	        
		        soLineList[LineIndex].soline.Selling_UOM__c = solineRet.Selling_UOM__r.Id;
		        soLineList[LineIndex].soline.Selling_UOM__r = solineRet.Selling_UOM__r; 
		        soLineList[LineIndex].soline.Fulfillment_Source__c = solineRet.Fulfillment_Source__c;
		        	        
        	}else{
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_primary_product_found + upcCode ));
        	}
	     		     	
         }
    
	     return null;
       
     }
    
    void loadAllLinesFromDatabase() {
   
		this.max_line_number = 0;
		this.soLineList = new List<SOLineWrapper>();
       
        
        List< Sales_Order_Line__c > allLines = getAllLinesForOrder( theSalesOrder.id );
        
        //totalNoLines = allLines.size();
        
        for( Sales_Order_Line__c sl : allLines )
   		{
   			if ( sl.Line__c > max_line_number ) max_line_number = sl.Line__c;
   		}
        
        setCon = new ApexPages.StandardSetController( allLines );
																	
		//if((ApexPages.hasMessages(ApexPages.Severity.FATAL) || ApexPages.hasMessages(ApexPages.Severity.ERROR)))
			//return;
 																	
		if( addNewClicked ){
        
			pageNumber = getNumberOfPages();
			addNewClicked = false;
		}
																	
		setCon.setPageSize(pageSize);
        setCon.setPageNumber( pageNumber );
            
		soLineList = wrapLines( (List<Sales_Order_Line__c>) setCon.getRecords() );
        
        loadSegments(soLineList); 
    }
    
	// add a wrapper to each record in the passed in list
    public  List<SalesOrderLinesAddManageExt.SOLineWrapper> wrapLines( list<Sales_Order_Line__c> lines) {
    	
		List<SalesOrderLinesAddManageExt.SOLineWrapper> ret = new  List<SalesOrderLinesAddManageExt.SOLineWrapper>();
		Integer count = 0;
    		
    	for(Sales_Order_Line__c sol: lines ) {
               
            SOLineWrapper soLineWrapper= new SOLineWrapper();
            soLineWrapper.soLine = sol;
            soLineWrapper.so = theSalesOrder;
            soLineWrapper.loc = def_loc;
            soLineWrapper.rowindex = count;
            soLineWrapper.soLine.available_Inventory__c = null;
            soLineWrapper.originalQuantity = sol.Quantity_Ordered__c;

            soLineWrapper.updateMinOrderQuantityException(theSalesOrder);
            ret.add(soLineWrapper);
            count++;            
        } 
        return ret;
    }
    
    	/* pagination controls and flags */
	public integer getPageNumber(){
		return setCon.getPageNumber();
	}
	
	public boolean getHasNext(){
		return setCon.getHasNext();
	}
	
	public boolean getHasPrevious(){
		return setCon.getHasPrevious();
	}
	
	public integer getNumberOfPages(){
		decimal noPages = (decimal)setCon.getResultSize();
		noPages = noPages.divide(pageSize,0, System.RoundingMode.UP);
		return (integer)noPages;
	}
	
	public void first(){
		//reCalculateAllocation();
		pageNumber = 1;
		checkConcurrency();
		if(!concurrency.concurrencyConflict){
			save_Lines();
			if(selecterror == false){
				//setCon.first();
			}
		}else{
			loadAllLinesFromDatabase();
		}
	}
	
	public void previous(){
		//reCalculateAllocation();
		pageNumber --;
		checkConcurrency();
		if(!concurrency.concurrencyConflict){
			//setCon.save();
			save_Lines();
		}else{
			loadAllLinesFromDatabase();
		}
	}
	
	public void next(){
		pageNumber ++;
		//setCon.save();
		//if(selecterror == false){
			
		checkConcurrency();
		if(!concurrency.concurrencyConflict){	
			
			save_Lines();
		}else{
			loadAllLinesFromDatabase();
		}
			//setCon.next();
		//}
	}
	
	public void last(){
		//reCalculateAllocation();
		pageNumber = getNumberOfPages();
		checkConcurrency();
		if(!concurrency.concurrencyConflict){
			save_Lines();
			if(selecterror == false){
			//	setCon.last();
			//	pageNumber = setCon.getPageNumber();
			}
		}else{
			loadAllLinesFromDatabase();
		}
	}
    
    public PageReference availableInventory(){
    	
    		Set<Id> itemsSet = new Set<Id>();
        map< String, Decimal > availableQuantity = new map< String, Decimal >();
        
        for(soLineWrapper solw: soLineList ) {	
        	
	        	if( solw.soLine.Status__c == 'Draft' )
	        		itemsSet.add( solw.soLine.Product__r.Item__c );
        }
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('SKID__C', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Type__c','Quantity__c','Item__c','Location__r.Facility__c'
		});
		soql.setWhereClause('Item__c IN :itemsSet and ( Type__c = \'SO Demand\' OR Type__c = \'Allocated\' OR ( Type__c = \'Location\' and Location__r.Nettable__c = true ) )');

		List<SKID__c> DemandAllocSkids = Database.query(soql.getQuery());
        
        for( SKID__c skid : DemandAllocSkids ){
        	
        	String key = String.valueOf( skid.Location__r.Facility__c ) + String.valueOf( skid.Item__c );
        	
        	if(! availableQuantity.containsKey( key ))
        		availableQuantity.put( key, 0.0 );
        	if( skid.Type__c != 'Location' )
        		availableQuantity.put( key, ( availableQuantity.get( key ) - skid.Quantity__c )  );
        	else
        		availableQuantity.put( key, ( availableQuantity.get( key ) + skid.Quantity__c )  );		
        }
        
        map< String, Sales_Order_Line__c> uniqueKeyMap = new map< String, Sales_Order_Line__c>();

		for(soLineWrapper solw: soLineList ) {
    		
    			Sales_Order_Line__c sol = solw.soLine;
    		    if(sol.Quantity_From_Stock__c==null || sol.Quantity_From_Stock__c==0)
                {   
                    sol.Quantity_From_Stock__c =  (sol.Quantity_Ordered__c * KSE.getConversionFactor(sol)).setscale(6,System.RoundingMode.HALF_UP);
                }
    			//Decimal conversionFactor = KSE.getConversionFactor(sol);
    		
                String key = String.valueOf( sol.Ship_From_Location__r.Facility__c ) + String.valueOf( sol.Product__r.Item__c );
            	system.debug( '***availableQuantity****'+availableQuantity+'*****'+DemandAllocSkids);
            	if( availableQuantity.ContainsKey( key ) && sol.Status__c == 'Draft'  ){
        			if(! uniqueKeyMap.containsKey( key ) ){
        				sol.available_Inventory__c = (availableQuantity.get( key ) / KSE.getConversionFactorFromQuantity(sol.Quantity_From_Stock__c,sol.Quantity_Ordered__c)).setscale(6,System.RoundingMode.HALF_UP); 
        				system.debug('***here1***'+availableQuantity.get( key ) +'*****'+sol.available_Inventory__c );
        			}
        			else{
        				sol.available_Inventory__c = availableQuantity.get( key );
        				system.debug('***here2***'+availableQuantity.get( key ) +'*****'+sol.available_Inventory__c );
        			}  
        			uniqueKeyMap.put( key, sol );
        			availableQuantity.put( key, sol.available_Inventory__c - sol.Quantity_Ordered__c  );
        		}
        		else{
        			if( sol.status__c != 'Draft' )	
        				sol.available_Inventory__c = null;
        			else
        				sol.available_Inventory__c = 0.0;	
        		}
        		
        		system.debug('****sol***'+sol);
    		}
    	
    		return null;
    }
    
    
    /** KNDY-1152
     * allow for customer adds their own fields to the org, then to the field set, this requires us to
     * read the list of fields in our query from the fields in the field set, should consider this in all VF pages
     * that implement FieldSets 
     */
    private List<Sales_Order_Line__c> getSalesOrderlinesToClone(Set<Id> salesOrderLineIdSet){
    	
    	String whereClause =  'Id IN :salesOrderLineIdSet';
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
        soql.addFields(getFieldsForSalesOrderLine());
        soql.setWhereClause(whereClause);
    	
        /*return Database.query(' select ' +String.join( getFieldsForSalesOrderLine(), ',') +     
            ' from Sales_Order_Line__c where Id IN :salesOrderLineIdSet');*/
        
        return Database.query(soql.getQuery());
    }
    private List<Sales_Order_Line__c> getAllLinesForOrder( id orderID ) {
        
        String whereClause = 'Sales_Order__c = :orderID Order by Line__c asc';
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
        soql.addFields(getFieldsForSalesOrderLine());
        soql.setWhereClause(whereClause);
        
        /*return Database.query(' select ' +String.join( getFieldsForSalesOrderLine(), ',') +     
            ' from Sales_Order_Line__c where Sales_Order__c = :orderID Order by Line__c asc');*/
        
        return Database.query(soql.getQuery());    
    }
    private Sales_Order_Line__c getOneLineFromOrder( id lineID ) {
        
        String whereClause = 'id = :lineID limit 1';
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
        soql.addFields(getFieldsForSalesOrderLine());
        soql.setWhereClause(whereClause);
        
        /*return Database.query(' select ' +String.join( getFieldsForSalesOrderLine(), ',') +     
            ' from Sales_Order_Line__c where id = :lineID limit 1');*/
            
        return Database.query(soql.getQuery());        
    }
    private Set<String> getFieldsForSalesOrderLine( ) {
        SchemaUtil util = SchemaUtil.getInstance();
        Schema.Sobjecttype solType = util.getGlobalDescribe('Sales_Order_Line__c');
        
        List<Schema.FieldSetMember> allFields = util.getFieldsFromFieldSet(solType,'Line_Edit_RO');
        allFields.addAll( util.getFieldsFromFieldSet(solType,'Line_Edit_A') );
        allFields.addAll( util.getFieldsFromFieldSet(solType,'Line_Edit_B') );
        allFields.addAll( util.getFieldsFromFieldSet(solType,'Line_Edit_C') ); 
        
        Set<string> fieldSet = new Set<String>{'Id', 'Name','Company__c','Line__c', 'Product__r.Item__r.Class__r.Type__c', 'Status__c','Product__r.Name', 'Estimated_ship_date__c',
            'Product__r.Item__r.Packaging_UOM__c','Product__r.Item__c', 'Product__r.Units_per_Pallet__c','Product__r.Units_per_Layer__c','Sales_Order__c','Unit_Price__c','Product__c','Required_Date__c', 'Selling_UOM__c',
    		'Selling_UOM__c', 'Product__r.Pricebook_Line_Required__c', 'Description__c','Quantity_Ordered__c','Ship_From_Location__c',
            'Accounting_Segment__r.id', 'Memo__c', 'Extended_Price__c', 'Discount_Percent__c','SystemModstamp', 'Line_Type__c'
            ,'Ship_From_Location__c', 'Ship_From_Location__r.Facility__c', 'Product__r.Item__r.Stocking_UOM__r.Name','Product__r.Item__r.Packaging_UOM__c',
            'Product__r.Item__r.Stocking_UOM__c', 'Selling_UOM__r.Name', 'Selling_UOM__c', 'Pricebook__r.Name', 'Fulfillment_Source__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        }; 
        
        for( Schema.FieldSetMember fld : allFields ) {          
            fieldSet.add( fld.getFieldPath().replace( KSE.NamespaceUU, '') );       
        }
        return fieldSet;  
    }
    
    public pageReference addNewRow() {
    	
    	checkConcurrency();
    	if(!concurrency.concurrencyConflict){
    		
	        last();
	        
	        // add new row needs to cause a save first, so we don't end up with an unstable visulaforce viewstate KNDY-1234
	        for (SOLineWrapper sol : soLineList ) {
	             if ( sol.soLine.id == null ) {             // if there are any new rows, save them now 
	                save_lines(); 
	                if ( (Apexpages.hasMessages(ApexPages.Severity.FATAL) || ApexPages.hasMessages(ApexPages.Severity.ERROR))) return null;
	             }
	        }
	        
	        //KNDY-1021
	        Date reqDate = (Date)this.theSalesOrder.Required_Date__c;
              //   KNDY-4268 Required date should be blank by default.
         //   if( reqDate == null ) reqDate = system.today();
	        
	        SOLineWrapper solWrapper = new SOLineWrapper();
	        solWrapper.soLine.Sales_Order__c = this.theSalesOrder.id;
	       // solWrapper.soLine.Required_Date__c = system.today();
	        solWrapper.soLine.Company__c = this.theSalesOrder.Company__c;
	        solWrapper.soLine.Ship_From_Location__c = this.def_loc;
	        solWrapper.soLine.Required_Date__c = reqDate;
	        
	        solWrapper.soLine.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
            //OTC-739 Default SOL Line Type as Replacement for Replacement SOs
            solWrapper.soLine.Line_Type__c = this.theSalesOrder.Type__c == 'Replacement' ? 'Replacement' : null;
	        // new rows need to show the line number they will have
	        //**
	        solWrapper.soLine.Line__c = ++max_line_number;
	        
	        solWrapper.rowindex = this.soLineList.size();
	        solWrapper.newOverride = null; 
	        this.soLineList.add(solWrapper);
	        
	        addNewClicked = true;
    	}
    	
        return null;
    }
    
    
    public Pagereference save_lines() { // quick save
    		
            List<Sales_Order_Line__c> soLinesToSave = new List<Sales_Order_Line__c>();
            List<Sales_Order_Line__c> soLinesAEDefaultToSave = new List<Sales_Order_Line__c>();
            Map<SOLineWrapper, Accounting_Default__c> soLinesAEDefaultMap = new Map<SOLineWrapper, Accounting_Default__c>();
            List<Accounting_Default__c> upsertNewOverride = new List<Accounting_Default__c>();
            Double totalExtendedPriceForSOLines = 0.0;
            
            Boolean configResult = false; // Process Configuration Result
        	List<String> SOLNamesWarning = new List<String>(); // List to store the lines which has the warning messages
        
            Savepoint sp = Database.setSavepoint();
            try  {  
                for (SOLineWrapper sw : soLineList ) {

                    if(sw.newOverride != null){
                        soLinesAEDefaultMap.put(sw, sw.newOverride);
                    }
                    //KNDY - 3621 UOM Conversion  
                    if(theSalesOrder.Weight_UOM__c !=null){           
                    	sw.soLine.Weight_UOM__c = theSalesOrder.Weight_UOM__c;
                    	sw.soLine.Weight_UOM__r = theSalesOrder.Weight_UOM__r;
                    }
                    if(theSalesOrder.Dimension_UOM__c != null){
                    	sw.soLine.Dimension_UOM__c = theSalesOrder.Dimension_UOM__c;
                    	sw.soLine.Dimension_UOM__r = theSalesOrder.Dimension_UOM__r;  
                    }
                                    
                    soLinesToSave.add(sw.soLine);
                    
                    //KNDY-1273 calculating extended price for all SOl lines, can't save a negative SO - moving to validation rule on sales order
                  /*  totalExtendedPriceForSOLines = totalExtendedPriceForSOLines +  
                    									(KSE.addQuantityToField(sol.soLine.Unit_Price__c,0) * 
                    									KSE.addQuantityToField(sol.soLine.Quantity_Ordered__c,0) * 
                    									(1- KSE.addQuantityToField(sol.soLine.Discount_Percent__c,0)/100));*/
                    
                } // end for each SOL
				
				//KNDY-1273 can't save a negative SO subtotal, only setting the flag when it is save and return - moving to validation rule on sales order
				/*if (totalExtendedPriceForSOLines < 0) {
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,'You cannot have a negative total from all the lines on a Sales Order.'));
	                return null;
	            }*/
	            
	            //KNDY-1431 - prevent accounting defaults from being created if not neccessary
	            List<Accounting_Default__c> upsertAccountingDefaults = new List<Accounting_Default__c>();
	            for(Accounting_Default__c ad : soLinesAEDefaultMap.values()){
	            	if(ad.gl_account__c != null){
	            		upsertAccountingDefaults.add(ad);
	            	}
	            }
				if(upsertAccountingDefaults.size() > 0){
					DML.checkUpsertAsUser(upsertAccountingDefaults); upsert upsertAccountingDefaults;
				}
				
				//Initilize a list of products
		        Set<Id> productIds = new Set<Id>();		
		        for (Sales_Order_Line__c sol : soLinesToSave ) {		        	
		        	productIds.add(sol.Product__c);		        	
		        }
	  			
	  			//Query the products

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Selling_UOM__c','Selling_UOM__r.Name','Item__r.Stocking_UOM__c','Item__r.Stocking_UOM__r.Name','Item__r.Packaging_UOM__c','Item__r.Class__r.Type__c'
				});
				soql.setWhereClause('Id IN :productIds');

				Map<Id,Product__c> productsMap = new Map<Id,Product__c>((List<Product__c>)Database.query(soql.getQuery()));
	  			
	  			//Update Quantity From Stock field
	  			for (SOLineWrapper sw : soLineList ) {
                    Sales_Order_Line__c sol = sw.soLine;
		        	// Abhinav: candidate for before update/insert trigger ? 
		        	if( sol.Quantity_Ordered__c != null ) {
		        	    if(sol.Product__r == null){
		        	        sol.Product__r = productsMap.get(sol.Product__c);
		        	    }
			        	sol.Quantity_From_Stock__c = (sol.Quantity_Ordered__c * KSE.getConversionFactor(sol)).setscale(6,System.RoundingMode.HALF_UP);
                    }
		        	
                    if(!soLinesAEDefaultMap.isEmpty()) {                        
                        if(soLinesAEDefaultMap.containsKey(sw)){
                            Accounting_Default__c AED = soLinesAEDefaultMap.get(sw);
                            sw.soLine.Accounting_Segment__c = AED.id;
                        }
                        
                    }
		        }

				DML.checkUpsertAsUser(soLinesToSave); upsert soLinesToSave;
                
                // Query SO Lines and check if any of the lines have the configResult true and the Accounting Segment is null
            	// Create the public variable displaysave_return initialize with 0 and increment when the message is displayed
            	//KNDY - 1127
                // Abhinav: This is fired twice in this flow, considering triggers getting fired should be worry about it ?
            	
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				ID soId = theSalesOrder.id;
				
				soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Name','Product__r.Item__c','Product__r.Item__r.Class__r.Type__c','line_type__c','Accounting_Segment__c','Line__c','Product__r.Item__r.Packaging_UOM__c','Product__r.Item__r.Stocking_UOM__c'
				});
				soql.setWhereClause('Sales_Order__c = :soId');

				for(Sales_Order_Line__c soline: Database.query(soql.getQuery())){
	            	configResult = processConfigService.configResult('Sales_Order_Line__c',soline.Product__r.Item__r.Class__r.Type__c , soLine.line_type__c, true);
	            	
	            	if(configResult && soline.Accounting_Segment__c == null ){
	            		String inputStr = String.valueof(soline.Line__c);
	            		SOLNamesWarning.add(inputStr); // if the config result is true and the segments are not entered populate the Line #s into the list
	            	}
	            }
	            
	            if(SOLNamesWarning.size() >0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Enter_accounting_segments + SOLNamesWarning)); // 
	        		displaySave_Return++ ;// counter to know whether the captured msg was displayed.
	         	}
                
                // OTC-5
            	if(ExceptionService.hasErrors){
                	// Database.rollback(sp);
	            	// Update Page messages for display on UI
					for (Map<String, String> msg : ExceptionService.messages) {
					    ApexPages.addMessage(MessageUtil.toApexPageMessage(msg));
					}	 
					//return null;
	            } 
	            
            	// Abhinav: looks like we could use it above and do the required stuff
            	// reload to pick up and workflow performed on the line
            	////OTC - 356
                loadAllLinesFromDatabase();
	            
	            
                
            } catch( Exception e) {     
                system.debug(LoggingLevel.ERROR, 'EXCEPTION: ' + e + ' ' + e.getStackTraceString());
                //KNDY-1257 Lock quantity and location editability of the SOLines once planned - via validation rule
                //NOTE: This solution is a little clunky, but reverts the location and quantity back to what is stored in the database
                //		We don't want to entirely reload the lines from the database, as the user may have changes in flight
                //		Additionally, we have limited ability to manipulate the inputfields generated by the field sets 
                // 		This solution was implemented as a minimally invasive approach but should be revisted once we have another header/lines strategy
                Set<Id> solIds = new Set<Id>();
                for (SOLineWrapper sol : soLineList ) {
                	solIds.add(sol.soLine.Id);
                }
                
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','name','quantity_ordered__c','ship_from_location__c'
				});
				soql.setWhereClause('Id IN :solIds');

				Map<Id, Sales_Order_Line__c> mSOLines = new Map<Id, Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));

				for (SOLineWrapper sol : soLineList ) {
					if(mSOLines.containsKey(sol.soLine.Id)){
						Sales_Order_Line__c iSOL = mSOLines.get(sol.soLine.Id);
						//sol.soLine.quantity_ordered__c = iSOL.quantity_ordered__c;
						sol.soLine.ship_from_location__c = iSOL.ship_from_location__c;
					}
				}
				// could be caused by validations
                //Database.rollback( sp );
                Apexpages.addMessages(e);
                
        	}
        	
        return null;
    }
    
    public void resetCounter(){ // method to reset the counter which is called in actionsupport - event= onclick (to check the changed line type)
    	displaySave_Return = 0;
    }

    public pageReference saveAndReturn(){
    	checkConcurrency();
		if(!concurrency.concurrencyConflict){
	        save_lines();
	        releaseConcurrency();
	        if(displaySave_Return == 1){ // If message exists stay on page for the 1st Save & Return and when clicked on Save & Return 2nd time it should return back to the header
	        	 return null; 
	        }
	        return ( (ApexPages.hasMessages(ApexPages.Severity.FATAL) || ApexPages.hasMessages(ApexPages.Severity.ERROR)) ? null : Controller.View() );   // return to the SO page only if the apex page has info / warning / confirm messages.           
		}else{
			return null;
		}
    }
    
    public pageReference cancel(){
    	checkConcurrency();
    	if(!concurrency.concurrencyConflict){
    		releaseConcurrency();
    	}
    	return controller.cancel();
    }
    
    
    public pageReference clonesoline() {
    	checkConcurrency();
		if(!concurrency.concurrencyConflict){
	    	try{
	    
            if( selected_indexes.size() == 0 ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Select_to_click_Clone));
                return null;
            }
                  
	        for ( Integer i :  selected_indexes  ) {
	            if (soLineList[i].soline.id == null) {
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_clone));
	                return null;
	            }
	        }
	
	        Set<ID> SOLList = new Set<Id> ();
            List <Sales_Order_Line__c> oldSOLObjectList = new  List <Sales_Order_Line__c> ();
	        for ( Integer i :  selected_indexes  ) { 
	            Sobject ob = soLineList[i].soLine;            
	            SOLList.add(ob.Id);
                 oldSOLObjectList.add(soLineList[i].soLine);
	        }
	       
	        //Clone more than 100 lines and cloned lines can can be cloned again without saving KNDY - 1190, 1237
	            
             
			if (oldSOLObjectList.size() > 0) {
				DML.checkUpsertAsUser(oldSOLObjectList); upsert oldSOLObjectList;
				oldSOLObjectList = getSalesOrderlinesToClone(SOLList);
			}
              
	        for(Sales_Order_Line__c oldSOLObject: oldSOLObjectList ){
	            if (oldSOLObject != null) {
	                SOLineWrapper solWrapper = new SOLineWrapper();
	                
	                Sales_Order_Line__c newSOLObject = new Sales_Order_Line__c(); 
	                newSOLObject = oldSOLObject.clone(false,true);
	                newSOLObject.Quantity_Shipped__c = 0;
	                newSOLObject.Status__c = 'Draft';
	                newSOLObject.Line__c = max_line_number+1;
	                max_line_number++;
	                newSOLObject.Accounting_Segment__c = null;  
	                solWrapper.soLine = newSOLObject;
	                
	                soLineList.add(solWrapper); 
	               
	            }
	        }
	        loadSegments(soLineList);     
	        
	        addNewClicked = true;
	          
	        save_lines();  
	        displaySave_Return = 0; // reset the counter after clone so when the save method is called the counter is recalculated        
	         
	    	}
	    	catch( Exception e){
	    		ApexPages.addMessage( new ApexPages.Message( apexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
	    	}
		}  
        return null;
    }
    
    public PageReference SelectAll(){
        for (SOLineWrapper sol : soLineList ) {
            sol.selected = selectAllChecked;
        }
  
        return null;
    }
    
    public class SOLineWrapper{
        public boolean selected {get; set;}
        public Accounting_Default__c newOverride {get; set ; } 
        public boolean showSegments {get; private set; } { showSegments = false; } 
        public Sales_Order_Line__c soLine { get; set; }

        public Sales_Order__c so { get; set;}
        public ID loc;
        public integer rowindex {get; set;}
        public Boolean hasMinOrderQuantityException {get; private set;}
		public decimal originalQuantity {get; set;}

        public SOLineWrapper(){
            this.soLine = new Sales_Order_Line__c();
            this.hasMinOrderQuantityException = false;
            this.selected = false;
        }

        // Uses the Standard Controller's record to set the state correct for the wrapper
        public void updateMinOrderQuantityException (Sales_Order__c so) {
            if (doesSoldToCustomerRequiresOrderQuantityFactor(so)) {
                // Any time we are setting SO Line, calculate if there are any exceptions to the order quantity
                hasMinOrderQuantityException = SalesOrderLineService.hasMinOrderQuantityException(soLine, soLine.Product__r, so.Customer__r.Order_Quantity_Factor_At__c);                    
            }
        }

        public String getExceptionIconStyles () {
            // moving it here as VF formula expressions are becoming messed up for this one
             return (this.hasMinOrderQuantityException) ? 'display:block;' : 'display:none;';
        }

        private Boolean doesSoldToCustomerRequiresOrderQuantityFactor(Sales_Order__c so) {
            return so.Id != null && !String.isBlank(so.Customer__r.Order_Quantity_Factor_At__c);
        }
        
    }
    // function to add segments to the so line  
    // This function is called whenever someone clicks on the small + button to add the segments on the line
    // 1. Whenever the button is clicked, it should check the class type from wrapper's item.
    // 2. If the Item Class Type is not null and found in process config then only call loadSegments ( loads the segments if exists or populate it as new record)
        
    public void addSegments() {                 // called from the popup button, show the existing segments 
        checkConcurrency();
		if(!concurrency.concurrencyConflict){
	        displayPopup = true;
	        String subType = null;
	        String lineType = null;
	        if( ApexPages.CurrentPage().getParameters().get('rowNum') != null ){
	            rowNum = Integer.valueOf( ApexPages.CurrentPage().getParameters().get('rowNum')); 
	        }
	        
	        SOLineWrapper solWrapper = soLineList[rowNum];
	        
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id productId = solWrapper.soLine.Product__c;
			
			SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Item__r.Class__r.type__c'
			});
			soql.setWhereClause('id = :productId');
			soql.setLimit(1);

			Product__c theProductSelected = Database.query(soql.getQuery());
	        
	        //system.assertNotEquals(null, theProductSelected.Item__c);
	        Item__c wrapperItem = theProductSelected.Item__r;
	        
	        if(wrapperItem.Class__c != null){
	            subType = String.valueOf(wrapperItem.Class__r.Type__c); 
	        }
	        
	        if(solWrapper.soLine.line_type__c != null){
	            lineType = solWrapper.soLine.line_type__c;
	        }
	        
	        
	        Boolean configResult = ProcessConfigService.configResult('Sales_Order_Line__c', subType, lineType, true);
	         
	        // If the config result is true it means ok the show / edit the segments
	        if(solWrapper.newOverride != null && configResult){
	            this.VFnewOverride = solWrapper.newOverride;  // set the VFnewOverride with the existing value 
	        } else {
	        	
	            if(configResult){
	                loadSegments(new List<SOLineWrapper>{solWrapper});  
	                this.VFnewOverride = solWrapper.newOverride;
	            } else { 
	                solWrapper.showSegments = false;
	                this.VFnewOverride = null;
	                //KNDY-1313 - show this message regardless if this is a new or existing line pulled from the database
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.No_segments) );
	            }
	        }
	        //system.debug(LoggingLevel.INFO, ' vf override '+VFnewOverride);
		}
    }
    
    private void loadSegments(List<SOLineWrapper> solWrappers) {
        Set<Id> accountingDefaultIds = new Set<Id>();
        for(SOLineWrapper solw : solWrappers){
        	
        	String subType = solw.soLine.Product__r.Item__r.Class__r.Type__c;
            String lineType = solw.soLine.Line_Type__c;
            Boolean configResult = ProcessConfigService.configResult('Sales_Order_Line__c', subType, lineType, true);
            
        	if(solw.soLine.Accounting_Segment__c != null && configResult == true ){
                accountingDefaultIds.add(solw.soLine.accounting_segment__c);
            }
        }
        
        String whereClause =  'Id IN :accountingDefaultIds';
        
        SOQLUtil soql = new SOQLUtil('Accounting_Default__c');
        soql.addFields(new Set<String>(SS.segmentNameList()));
        soql.setWhereClause(whereClause);
        String query = soql.getQuery();

        Map<Id, Accounting_Default__c> mAccountingDefaults = 
        		new Map<Id, Accounting_Default__c>((List<Accounting_Default__c>)Database.query(soql.getQuery()));
        		
        for(SOLineWrapper solw : solWrappers){		
        	
	        solw.showSegments = true;
	        
	        if ( solw.soLine.Accounting_Segment__c != null && mAccountingDefaults.containsKey(solw.soLine.Accounting_Segment__c)) {
	        	
	            solw.newOverride = mAccountingDefaults.get(solw.soLine.Accounting_Segment__c);
	            
	        } else {
	        	
	            solw.newOverride = new Accounting_Default__c( Company__c = solw.soLine.Company__c );
	        }
        }
    }
    
    // function to close the pop up window for segments
    public void closePopup() {
        displayPopup = false;
    }
    
    // save function to load segments on page to the wrapper
    public void saveSegmentsForWrapper () {
        SOLineWrapper solWrapper = soLineList[rownum];
        if(VFnewOverride!= null){
            solWrapper.newOverride = VFnewOverride;
        }
        displayPopup = false; 
        displaySave_Return = 0; // reset this counter to 0 whenever the sagments are saved. After adding segments whenever the quick save or save & return is clicked the counter is recalculated.
    }
    
    public pageReference remove() {   
    	checkConcurrency();
    	if(!concurrency.concurrencyConflict){  
	        try{
	            Map<Id, SObject> recordsToDelete = new Map<Id, SObject>();
	            for ( Integer i : selected_indexes ) {
	                SOLineWrapper ob = this.soLineList[i];
	                if ( ob.soLine.id !=null  ) {
	                    recordsToDelete.put(ob.soLine.Id, ob.soLine ); 
	                }  
	            }
	            
	            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				Set<Id> deletedIds = recordsToDelete.keySet();
				
				SOQLUtil soql = new SOQLUtil('Shipment_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','name','quantity_shipped__c','sales_order_line__c','sales_order_line__r.name','sales_order_line__r.quantity_shipped__c',
					'shipment__c','shipment__r.status__c'
				});
				soql.setWhereClause('sales_order_line__c IN :deletedIds');
				
				SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Inventory_Transactions__r');
				childRel.addFields(new set<string>{
					'id','name'
				});
				soql.addChildRelationship(childRel);

				List<Shipment_Line__c> shipLines = Database.query(soql.getQuery());

	            boolean isDeletable = true;
	            string solNames = '';
	            List<Shipment_Line__c> deleteShipmentLines = new List<Shipment_Line__c>();
	            
	            for(Shipment_Line__c sl : shipLines){
		            	if(sl.quantity_shipped__c > 0){
		            		isDeletable = false;
		            		solNames += ', ' + sl.sales_order_line__r.name;
		            	}else{
		            		deleteShipmentLines.add(sl);
		            	}
	            }
	            
	            
	            if(isDeletable){
		            	
		            	DML.deleteAsUser( deleteShipmentLines) ;
		            	DML.deleteAsUser( recordsToDelete.values() );
		            	 
		            	//Now remove the wrapper lines from soLineList
		            for ( Integer i : selected_indexes ) {
		            		SOLineWrapper ob = this.soLineList[i];
		               this.soLineList.remove(i);		              
		            }
	            } else{
	            		ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, Label.Records_not_deleted + solNames));
	            }
				
				save_lines();
	            
	        }catch(Exception e){
	            //ApexPages.addMessages(e);
	            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, Label.Deleting_selected_lines + MessageUtil.toFriendlyErrorMessage(e.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
	            // .debug(LoggingLevel.ERROR, e);
	        }
    	}
        return null;
    }
    
    public pageReference cancelLines() {   
    	
    	checkConcurrency();
    	
    	if(!concurrency.concurrencyConflict){  
	        try{
	        	Map<Id, Sales_Order_Line__c> cancelledLinesMap = new Map<Id, Sales_Order_Line__c>();
	            
	            for ( Integer i : selected_indexes ) {
	                SOLineWrapper soLineWrapper = this.soLineList[i];
	                if ( soLineWrapper.soLine.Id != null ) {
	                	cancelledLinesMap.put(soLineWrapper.soLine.Id, soLineWrapper.soLine ); 
	                }  
	            }
	            
	            Boolean isDeletable = true;
	            String solNames = '';
	            
	            List<Shipment_Line__c> deleteShipmentLines = new List<Shipment_Line__c>();
	            
	            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				Set<Id> cancelledIds = cancelledLinesMap.keySet();
				
				SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Name','Quantity_Allocated__c','Quantity_Shipped__c','Status__c'
				});
				soql.setWhereClause('Id IN :cancelledIds');
				
				String RQ_STATUS_CANCELLED = RequisitionService.RQ_STATUS_CANCELLED;
				SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Requisition_Lines__r');
				childRel1.addFields(new set<string>{
					'Id','Requisition__r.Name','Requisition__r.Status__c'
				});
				childRel1.setWhereClause('Requisition__r.Status__c <> :RQ_STATUS_CANCELLED');
				soql.addChildRelationship(childRel1);
				
				SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
				childRel2.addFields(new set<string>{
					'Id','Name','Quantity_Shipped__c','Shipment__c','Shipment__r.Status__c'
				});
				childRel2.setWhereClause('Shipment__r.Locked__c = false');
				soql.addChildRelationship(childRel2);
				
				for(Sales_Order_Line__c sol : Database.query(soql.getQuery())){
	            							  	
	            	if(sol.Quantity_Shipped__c > 0){
	            		ExceptionService.addMessage( MessageUtil.Severity.Error.name(), sol.Name + ': Quantity has already been shipped for this sales order line and hence cannot be cancelled.', '');
            			continue;
	            	}
	            	
	            	// TODO : Should we automatically unallocate too if a line is cancelled ??						  	
	            	if(sol.Quantity_Allocated__c > 0){
	            		ExceptionService.addMessage( MessageUtil.Severity.Error.name(), sol.Name + ': Quantity has already been allocated for this sales order line. Please unallocate the quantity in order to cancel the line.', '');
	            		continue;						  	
	            	}
	            	
	            	if (sol.Requisition_Lines__r.size() > 0){
                        ExceptionService.addMessage(MessageUtil.Severity.Error.name(), 
                                                        sol.Name + ': Please cancel the corresponing Requisition ('+ sol.Requisition_Lines__r[0].Requisition__r.Name +') before cancelling the line.', '');
                        continue;
                    }
                    
	            	cancelledLinesMap.get(sol.Id).Status__c = SalesOrderService.SO_STATUS_CANCEL;
	            	deleteShipmentLines.addAll(sol.Shipment_Lines__r);
		        }
	            				
	            if(ExceptionService.hasErrors == false){
		        	DML.deleteAsUser( deleteShipmentLines) ;
	            	DML.updateAsUser( cancelledLinesMap.values() );
		        } else{
            		for (Map<String, String> msg : ExceptionService.messages) {
					    ApexPages.addMessage(MessageUtil.toApexPageMessage(msg));
					}
	            }
				
				save_lines();
	            
	        }catch(Exception e){
	            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
	        }
    	}
        return null;
    }
    
    public List<Integer> selected_indexes { 
        get {
            String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
            // .debug('Selected Indexes: ' + selected_indexes);
            return ArrayUtils.getIntegerList( selected_indexes ); 
        }
    }

    public String getBadEvenOrderQtyMessage() {
      return 'Not an even order quantity';
    }
 
    public Boolean getHasBracketPricing() {
        Map<Id, BracketPricingService.BracketPrice[]> bracketPrices = BracketPricingService.loadBracketPrices(new Set<Id>{this.theSalesOrder.Company__c});
        return ! bracketPrices.isEmpty();
    }

	public void changeQuantity(){
		quantityChange = true;
	}
}