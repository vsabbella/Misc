public with sharing class SalesOrderAllocateExt {
    
    private Apexpages.Standardcontroller con;
    
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    
    SalesOrderService sos = new SalesOrderService();
    public list<solWrapper> solWrapperList { get; set; } { solWrapperList = new list<solWrapper>(); }
    public Map<String, List<SKID__c>> quantitySkidsByItemLocation {get;set;}{ quantitySkidsByItemLocation = new Map<String, List<SKID__c>>(); }
    public map<Id, List<Location__c> > locationsByHeader = new map<Id, List<Location__c>>();
    public Map<Id, List<SKID__c>> quantitySkidsByHeader {get;set;}{ quantitySkidsByHeader = new Map<Id, List<SKID__c>>(); }
    public String colSpanNum { get; set; }
    public list<Sales_Order_Line__c> solList = new list<Sales_Order_Line__c>();
    public list<String> sortFields = new list<String>();
    public map<Id, Decimal> quantityByHeaderId = new map<Id, Decimal>();
    public map< Id, decimal> quantityToDistributeByHeaderId = new map<Id, decimal>();
    list<Id> demandSkidIds = new list<Id>();
    public map< Id, String> itemNameMap = new map<Id, String>();
    list<String> attributeFields = new list<string>();
    public list<String> attributesForDisplay { get; set; } { attributesForDisplay = new list<String>();}
    //Location__c pullFromLocation;
    public Map<String, Decimal> allocatedQty  = new Map<String, Decimal>(); 
    public list<SKID__c> allocatedSkids  = new list<SKID__c>();
    public Boolean disableSave { get; set; } { disableSave = false; }
    public Boolean hideSave { get; set; } { hideSave = false; }
    private SchemaUtil util = SchemaUtil.getInstance();
    public map<Id,Shipment__c> shipmentMap = new map<Id, Shipment__c>();
    public map<Id, Stock_Movement_Rule__c> matchedRules = new map<Id, Stock_Movement_Rule__c>();
    public map<Id, Integer> locationIndexByHeader = new map<Id, Integer>();
    public map<Id,Boolean> locationButtonDisabled { get; set; } { locationButtonDisabled = new map<Id,Boolean>(); }
    map<Id, Sales_Order_Line__c> solMap = new map<Id, Sales_Order_Line__c>();
    
    public class SalesOrderAllocateExtException extends Exception { }
    
    public SalesOrderAllocateExt(Apexpages.StandardController controller){
        
        con = controller;
        
        Id salesOrderId = con.getId();
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Credit_Hold__c','Company__c','Customer__c','Customer__r.Top_Parent_Customer__r.Minimum_Shelf_Life_In_Days__c','Override_Credit_Hold__c',
			'Customer__r.Top_Parent_Customer__r.Status__c','Ship_Complete__c','Status__c','Ship_To__c','Currency__c','Hold__c',
			'Released_to_3PL__c','Customer__r.Top_Parent_Customer__r.Credit_Hold__c'
		});
		soql.setWhereClause('Id = :salesOrderId');
		soql.setLimit(1);

		Sales_Order__c salesOrder = Database.query(soql.getQuery());
        
        String otcCompanyId = salesOrder.Company__c;
        otcCompanyId = 'CompanyId=' + otcCompanyId.substring(0, otcCompanyId.length() - 3);
        OTC__c otc = OTC__c.getInstance(otcCompanyId);

        if (salesOrder.Hold__c == True) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_on_hold)); 
            hideSave = true;    
        }            
        else {             
            if (salesOrder.Status__c != 'Open') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_not_open));
                hideSave = true;
            }
            //KNDY-2114
            if (salesOrder.Override_Credit_Hold__c == false){
                if (salesOrder.Credit_Hold__c == true) {
                
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Sales_Order_on_Credit_Hold));
                    hideSave = true;
                }

                if (otc != null && otc.Customer_Credit_Hold_Check_At_Allocate__c != null){

                    if( otc.Customer_Credit_Hold_Check_At_Allocate__c && salesOrder.Customer__r.Top_Parent_Customer__r.Credit_Hold__c){

                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Top_Parent_Customer_on_Credit_Hold));
                        hideSave = true;    
                    }
                }
            }
            else if (salesOrder.Customer__r.Top_Parent_Customer__r.Status__c != 'Approved') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Top_Parent_Customer_not_status_Approved));
                hideSave = true;                
            } 
            // KNDY-4748
            if (salesOrder.Status__c == 'Open' && salesOrder.Released_to_3PL__c == true) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_released_to_3PL));
                hideSave = true;
            }    
            
            if( salesOrder.Customer__r.Top_Parent_Customer__r.Minimum_Shelf_Life_In_Days__c == null ) 
                salesOrder.Customer__r.Top_Parent_Customer__r.Minimum_Shelf_Life_In_Days__c = 0;
            
            attributeFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c') );
            attributesForDisplay.addAll( SkidService2.attributesForPutaway(attributeFields));
            colSpanNum = String.valueOf(SObjectType.Sales_Order_Line__c.FieldSets.Fulfillment_RO.getFields().size()+2+attributesForDisplay.size());
            
            Id companyId = salesOrder.Company__c;
            
            list<Id> salesOrderIdList = new list<Id>(); salesOrderIdList.add(con.getId());   
            solList = sos.getSalesOrderLinesToAllocate(salesOrderIdList);
            
            Integer i = 0;
            while (i < solList.size()){
                
                sales_Order_Line__c sol = solList[i];
                
                if( sol.SKIDs__r == null || sol.SKIDs__r.size() == 0 ){
                    
                    solList.remove(i);   
                    
                }
                else{
                    i++;
                }
                
                if( sol.SKIDs__r != null && sol.SKIDs__r.size() > 0 && sol.SKIDs__r[0].Shipment_Line__c != null ){
                    sol.SKIDs__r[0].Shipment_Line__r.Shipment__r.Status__c = 'Released';
                    shipmentMap.put(sol.SKIDs__r[0].Shipment_Line__r.Shipment__c, sol.SKIDs__r[0].Shipment_Line__r.Shipment__r);
                }
                else if( sol.SKIDs__r != null && sol.SKIDs__r.size() > 0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_Shipment_line +sol.Name));
                    hideSave = true;
                } 
                solMap.put( sol.id, sol);
            }
             
            if (solList.size() ==0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_SOL_available));
                hideSave = true;
                return;
            }
            
            locationsByHeader = SkidService2.locationsFromStockMovementRules( solList, 'Pick', 'Sales Order', matchedRules);

            // KNDY-5977 if there are no locations found by looking in the stock movement rules, we have a fatal error and 
            // the pullSortedSkids query will blow up > 50,000 rows
            if ( locationsByHeader.size() == 0 ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Stock_movement_rules_are_not_setup));
                hideSave = true;
                return;
            }
            
            sortFields.addAll( SkidService2.populateSortCriteria( salesOrder.Customer__c, salesOrder.Company__c ));
            
            Integer minShelfLife =  Integer.valueOf(salesOrder.Customer__r.Top_Parent_Customer__r.Minimum_Shelf_Life_In_Days__c);
            String minShelfString = String.valueOf(System.today().addDays(minShelfLife));
            
            String additionalWhere = ' and ( Expiration_Date__c = null or Expiration_Date__c >= '+minShelfString+' ) and  (Lot__c = null OR Lot__r.Lot_Hold__c = false) and Location__r.Nettable__c = true and Quantity__c >0 and Receipt_Line__c = null ';
            
            quantitySkidsByItemLocation = SkidService2.pullSortedSkids((list<Sobject>)solList, sortFields, locationsByHeader, additionalWhere, 'Product', allocatedSkids, null ); 
            
            SkidService2.populateQuantitySkidsByHeader( solList, 0,quantitySkidsByHeader, locationsByHeader, locationIndexByHeader, locationButtonDisabled, quantitySkidsByItemLocation);
            SkidService2.queryAllocatedSkids(allocatedQty, allocatedSkids);
            distribute( solList ); 
            
            // OTC-419 save some memory be removing extra fields in the skid lists
            // there can be many of these skids in a large order  100 * ~12
            for ( id key: quantitySkidsByHeader.keySet() ) {
                quantitySkidsByHeader.put(key, compressSkidList( quantitySkidsByHeader.get(key) ));
            }
            for ( string key: quantitySkidsByItemLocation.keySet() ) {
                quantitySkidsByItemLocation.put(key, compressSkidList( quantitySkidsByItemLocation.get(key) ));
            }
            // OTC-419 lowering the default page size from 10 to 5 saves ~ 15KB in viewstate
            // allow user to specify on the URL to support very large order sizes
            // exapmle: apex/SalesOrderAllocate?id=a1g17000000D8ZR&size=5
            if ( ApexPages.CurrentPage().getParameters().get('size') != null ) {
                size = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('size'));
            }
            
            // prepare the page we will show OTC-216
            setCon = new ApexPages.StandardSetController(solList);                
            setCon.setPageSize(size);
            first();            
        }
        
    }
    
    // OTC-419  reduce the total memory we keep in viewstate by putting this list on a diet
    private List<Skid__c> compressSkidList( list<Skid__c> uncompressed ) {
        list<skid__c>ret = new list<skid__c>();
        List<Schema.FieldSetMember> allocation_ro_fieldSet = util.getFieldsFromFieldSet( Skid__c.SObjectType, 'Allocation_RO' );

        // the visualforce page shows fields from attributesForDisplay, the allocation_ro field set and the qty allocated field
		// make sure our new skid has all of these populated and no other fields that would needesly consume viewstate
        for ( Skid__c sk : uncompressed ) {
            Skid__c snew = new Skid__c(id=sk.id);
            for( string fld : attributesForDisplay ) {
                snew.put(fld, sk.get( fld));
            }
            for ( Schema.FieldSetMember flm : allocation_ro_fieldSet) {
                string fp = flm.getFieldPath();
                if ( fp.containsIgnoreCase( 'Location__r') ) { // Location__r.Facility__c
                    snew.Location__r = sk.Location__r; 
                } else {
                    snew.put(fp, sk.get( fp)); 
                }
            }
            snew.Lot__r = sk.Lot__r;  // needed for OTC-457
            snew.Quantity_Allocated__c = sk.Quantity_Allocated__c;
            snew.Quantity__c = sk.Quantity__c; 	// not on page, but used to recalculate
            snew.Company__c = sk.Company__c; 
            ret.add(snew);
        }
        return ret;        
    }
    
    public PageReference showNextLocation(){
        
        Savepoint sp = Database.setSavepoint();
        try {
            Id headerId = ApexPages.CurrentPage().getParameters().get('headerLineId');
            Integer nextIndex = locationIndexByHeader.get(headerId)+1;
            String additionalWhere = ' and ( Expiration_Date__c = null or Expiration_Date__c >=:tod ) and  (Lot__c = null OR Lot__r.Lot_Hold__c = false) and Location__r.Nettable__c = true and Quantity__c >0 and Receipt_line__c = null ';
            
            List<Sales_Order_Line__c> solNextList = new list<Sales_Order_Line__c>{(Sales_Order_Line__c)solMap.get(headerId)};
            list<SKID__c> allocSkidList = new list<SKID__c>();
            quantitySkidsByItemLocation.putAll(SkidService2.pullSortedSkids(solNextList, sortFields, locationsByHeader, additionalWhere, 'Product', allocSkidList,new map<Id,Integer>{headerId => nextIndex} ));
            
            SkidService2.populateQuantitySkidsByHeader( solNextList, nextIndex,quantitySkidsByHeader, locationsByHeader, locationIndexByHeader, locationButtonDisabled, quantitySkidsByItemLocation);
            allocatedQty = new Map<String, Decimal>();
            // using allocSkidList to hold allocated skids from all the specified locations for this sales order line.
            SkidService2.queryAllocatedSkids(allocatedQty, allocSkidList);
            distribute(solNextList);
            
            for( solWrapper sw : solWrapperList ){
                if( sw.sol.id == headerId ){
                    sw.skidList = quantitySkidsByHeader.get( headerId );
                    break;
                }
            }
            
        } catch (Exception e) { 
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disableSave = true;   
        }
        return null;
    }
    
    // begin paging support OTC-216
    public Integer size {get; set;} { size = 10; }
    public Integer noOfRecords { get{ return setCon.getResultSize();} }
    
    @TestVisible
    ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new list<Sales_Order_Line__c>()); // OTC-330
    
    void populatePageWrapper ( list<Sales_Order_Line__c> solList ) {
        
        solWrapperList.clear();
        for( sales_Order_Line__c sol : solList ) {
            solWrapperList.add( new solWrapper( sol , quantitySkidsByHeader.get( sol.id ) ) );
        }
    }
    
    public PageReference refresh() {
        
        PageReference p = Page.SalesOrderAllocate;
        p.setRedirect(true);
        p.getParameters().put('id',con.getId());
        return p;  
    }
    
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
    
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
    
    public void first() {
        setCon.first();
        populatePageWrapper( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void last() {
        setCon.last();
        populatePageWrapper( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void previous() {
        setCon.previous();
        populatePageWrapper( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void next() {
        setCon.next();
        populatePageWrapper( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    // end paging support OTC-216

    public void recalculate(){
        
        List<Location__c> locList = new list<Location__c>();
        
        for( List<Location__c> locationList : locationsByHeader.values() ){
            for( Location__c loc : locationList )
                locList.add(loc);
        }
        
        set<Id> itemIdSet = KSE.grepRelatedIdSetFromList( solList, 'Product__r.Item__c', true);
        set<Id> locationIdSet = KSE.grepRelatedIdSetFromList( locList, 'Id', true);
        allocatedSkids = SkidService2.pullQuery(sortFields,locationIdSet , itemIdSet, null, '\'Allocated\'');
        allocatedQty = new Map<String, Decimal>();
        
        SkidService2.queryAllocatedSkids(allocatedQty, allocatedSkids);
        SkidService2.checkIssueError(solList, quantitySkidsByHeader, quantityToDistributeByHeaderId, itemNameMap, 'Quantity_Allocated__c', 'Quantity_Available__c', 'Error', 'Allocate', allocatedQty, true);
    }
    
    public PageReference allocate(){
        
        Savepoint sp = Database.setSavepoint(); 
        try{    
            recalculate();
            
            if( (ApexPages.hasMessages(ApexPages.Severity.Info) || ApexPages.hasMessages(ApexPages.Severity.Warning) || ApexPages.hasMessages(ApexPages.Severity.Error)) 
                && !Test.isRunningTest()) {
                return null;
            }

            List<sales_order_line__c> solQFSUpdatedList = new list<sales_order_line__c>();
            Map<Id, Shipment_Line__c> updatedSHLs = new Map<Id, Shipment_Line__c>();
            
            for(sales_order_line__c sol:solList)
            {	
            	
            	Decimal allocatedQuantity = 0;
            	
            	for(SKID__c allocatedSkid : quantitySkidsByHeader.get( sol.id )){
            		allocatedQuantity += allocatedSkid.Quantity_Allocated__c;
            	}
            	
            	if(sol.Shipment_Lines__r.size() > 0 && allocatedQuantity > 0){
	            	Shipment_Line__c shl = new Shipment_Line__c(Id = sol.Shipment_Lines__r[0].Id, Quantity_Allocated__c = sol.Shipment_Lines__r[0].Quantity_Allocated__c);
	            	shl.Quantity_Allocated__c = KSE.addQuantityToField(shl.Quantity_Allocated__c, allocatedQuantity);
	            	updatedSHLs.put(shl.Id, shl);
            	}
            	
            	decimal quantityFromStock = sol.Quantity_From_Stock__c;
	            if(sol.Quantity_From_Stock__c==null || sol.Quantity_From_Stock__c==0)
	            {   
	                 quantityFromStock =  ((decimal)sol.Quantity_Ordered__c * KSE.getConversionFactor(sol)).setscale(6,System.RoundingMode.HALF_UP);
	           	}
	           	
	            Sales_order_line__c tempSOL = sol.clone(true,true);
	            tempSOL.Quantity_From_Stock__c = quantityFromStock;
	            solQFSUpdatedList.Add(tempSOL);
            }
           	
           	 
            map< String, SKID__c> fromToSkidMap = SkidService2.createToSkidsOnPull((List<sobject>) solQFSUpdatedList, quantitySkidsByHeader, 'Quantity_Allocated__c', 'Allocate', attributesForDisplay, true, null);    
            
            SkidService2.inventoryTransactionForPullFrom((list<SObject>)solQFSUpdatedList, quantitySkidsByHeader, 'Sales Order Allocation Temp', attributesForDisplay, 'Allocate', 'Quantity_Allocated__c', fromToSkidMap, true, null); 
            DML.updateAsUser(shipmentMap.values());
            
            if(updatedSHLs.size() > 0){
            	DML.updateAsUser(updatedSHLs.values());
            }
            solQFSUpdatedList = null;        
        }
        catch( Exception e){
            Database.rollback(sp);     
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disableSave = true;   
            return null;  
        }
        
        return ( (hideSave || disableSave) ? null : con.cancel() ); 
    }
    
    public void distribute( list<Sales_Order_Line__c> solList ) {
        list<Sales_Order_Line__c> solUpdatedList = new list<Sales_Order_Line__c>();
        
        for( sales_Order_Line__c sol : solList ){
        	decimal quantityFromStock = sol.Quantity_From_Stock__c;
            if(sol.Quantity_From_Stock__c==null || sol.Quantity_From_Stock__c==0)
            {   
                 quantityFromStock =  (sol.Quantity_Ordered__c * KSE.getConversionFactor(sol)).setscale(6,System.RoundingMode.HALF_UP);
           	}
            quantityToDistributeByHeaderId.put( sol.id, (sol.skids__r[0].Quantity__c / (KSE.getConversionFactorFromQuantity(quantityFromStock,sol.Quantity_Ordered__c))).setscale(6,System.RoundingMode.HALF_UP));//KSE.getConversionFactor(sol));
            demandSkidIds.add( sol.id );
            itemNameMap.put( sol.id, sol.Name);
            Sales_order_line__c tempSOL = sol.clone(true,true);
            tempSOL.Quantity_From_Stock__c = quantityFromStock;
            solUpdatedList.Add(tempSOL);
        }
        
        
        
        SkidService2.distribute(solUpdatedList, quantitySkidsByHeader, quantityToDistributeByHeaderId, quantityByHeaderId, itemNameMap, true, 
                                    'Quantity_Available__c', 'Quantity_Allocated__c', 'Allocate', allocatedQty, true);
       
       solUpdatedList = null;     
    }
    
    //KNDY-1393 - Undo Release of Sales Order Lines
    public PageReference undoRelease(){
        
        try{
            SalesOrderService sos = new SalesOrderService();
            sos.undoPlan(new Set<Id>{con.getId()});
            
        }catch(Exception e){
            ApexPages.addMessages(e);
            disableSave = true; 
            
        }
        return (ApexPages.hasMessages() ? null : con.cancel() ); 
    }
    
    // OTC-457 allow user to specify by lot number ( lot__r.name) what other lots that 
    // are interesting to allocate for the line
    public PageReference findLot() { 
        for( sales_Order_Line__c sol : (list<Sales_Order_Line__c>)setCon.getRecords() ) {
            updateWrapperList( sol , quantitySkidsByHeader.get( sol.id ) );
        }
        return null;
    }
    
    private void updateWrapperList( Sales_Order_Line__c sol, list<SKID__c> skidsList ) {		
        for (solWrapper wrap : solWrapperList ) {            
            // add skids that have a name like solWrapper.lotSearch to the skidList we show
            if ( sol.id == wrap.sol.id && wrap.lotSearch1.Name != null ) {	// make sure we add specific skid to the correct wrapper
                string lotSearch = wrap.lotSearch1.Name.trim();				// pull of any leading or trailing spaces from lot search string
                for (SKID__c s :skidsList ) { 								// add any skids that match the search string				
                    if ( s.lot__r != null && string.valueOf(s.lot__r.name).equalsIgnoreCase(lotSearch) ) {  // ENHANCE: Begins with ?
                        wrap.addSkid(s);
                        wrap.lotSearch1.Name = '';
                        break;						// should only be one skid that matches the lot by name
                    }
                }
            }
        }
    }
    
    public class solWrapper{
        public integer maxEmptyRows = 1; // KNDY-5977
        public Sales_Order_Line__c sol {get;set;}
        
        //public string lotSearch {get; set;}
        public Lot__c lotSearch1 {get; set; } { lotSearch1 = new Lot__c(); }
        public string extraLots {get; set; } {extraLots = ''; }
        public void addSkid( skid__c sk ) {   // add a skid to the skidList if its not there
            if ( KSE.grep(skidList, 'Id', sk.id ).size() == 0 )
                skidList.add(sk);
        }
        
        public List<SKID__c> skidList {get;set;} {skidList = new List<SKID__c>();}
        
        public solWrapper( Sales_Order_Line__c soLine, list<SKID__c> skidsList ){
            
            integer emptyRowsFound = 0;
            for (SKID__c s :skidsList ) {
                // KNDY-5977  limit the list we show user so that we don't blow up the viewstate
                if ( s.Quantity_Allocated__c == null || s.Quantity_Allocated__c == 0.00 ) {
                    emptyRowsFound++;
                }
                if ( emptyRowsFound <= maxEmptyRows ) {
                    this.skidList.add(s);
                } else if ( s.Quantity_Allocated__c > 0.0 ) { // have allocated quantity, add this one
                    this.skidList.add(s);
                } else if ( s.lot__r!= null && s.lot__r.Name != null ) { 
                	this.extraLots += s.lot__r.Name + ', ';
                }
            }
            sol = soLine;
        }
        
    }
    
}