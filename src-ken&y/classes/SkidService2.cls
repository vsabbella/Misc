global with sharing class SkidService2 {
    
    public static final String SKID_TYPE_LOCATION = 'Location' ;
    public static final String SKID_TYPE_PO_SUPPLY = 'PO Supply' ;
    public static final String SKID_TYPE_TO_SUPPLY = 'TO Supply' ;
    public static final String SKID_TYPE_SO_DEMAND = 'SO Demand' ;
    public static final String SKID_TYPE_TO_DEMAND = 'TO Demand' ;
    public static final String SKID_TYPE_WO_SUPPLY = 'WO Supply' ;
    public static final String SKID_TYPE_ALLOCATED = 'Allocated' ;
    public static final string SKID_TYPE_BYPRODUCT = 'By-product';
    public static final String SKID_TYPE_DROP_SHIP = 'Drop Ship';
    public static final string SKID_TYPE_INTRANSIT = 'In-Transit';
    public static final string SKID_TYPE_WIP = 'WIP';
    public static final String SKID_LOT_EXCEPTION = 'Lot' ;
    public static final String SKID_QUANTITY_EXCEPTION = 'Quantity' ;
    public static set<String> attributesToExclude {
        get {
            if (attributesToExclude == null) {
               	attributesToExclude = new set<string>{ 'minimum_shelf_life_in_days__c','serial_number__c','extid__c' };
               	
               	for( String serialField : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes')){
                    attributesToExclude.add(serialField.replace( KSE.namespaceUU, '').toLowerCase().trim());
                }  
            }
            return attributesToExclude;
        }
        set;
    }
    public static set<String> doNotDeleteSkidTypes = new set<string>{ 'WOM Demand', 'By-product' };
    public static set<String> deleteSkidTypesIfNegative = new set<string>{ 'PO Supply', 'In-Transit' };
    public static Boolean fromVisualforce = ApexPages.currentPage() != null;
    public static Boolean abortflag = false;
    
    //IT types to not create ICs for
    public static Set<String> excludeITTypesForIC = new Set<String> { 'Activate Proposed Costs','Transfer','Adjustment Decrease','Adjustment Increase','Cycle Count','QA Sample','Sales Order Allocation Temp','Adjustment' };
    public static Map<SObjectType,String> itGroupingFields = new Map<SObjectType,String>{ 
        Sales_Order_Line__c.sObjectType => 'Sales_Order__c',
        Purchase_Order_Line__c.sObjectType => 'Purchase_Order__c',
        Order_Line__c.sObjectType => 'Order__c',
        Receipt_Line__c.sObjectType => 'Receiving_Document__c',
        Material_Tracking__c.sObjectType => 'Work_Order__c',
        SKID__c.sObjectType => 'Work_Order__c',
        Shipment_Line__c.sObjectType => 'Shipment__c'
    };
    
    public class SkidService2Exception extends Exception { }
    
    //takes two parameters as input
    // 1.  unique set of lot names to filter existing lots.
    // 2. a map with the lot attributes as key and a lot object with the attributes as value
    // the lot key is a combination of LotName, Item, Company, Supplier and Expiration Date of the lot in that order.
    // the method returns the input lot map with the committed lot objects ( newly created if it did not already exist ) 
    public static map< String, Lot__c > createLots( map<String, Lot__c> inputLotMap, Set<String> uniqueLotNames ){

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Lot__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Supplier__c','Name','Expiration_Date__c','Company__c','Item__c'
		});
		soql.setWhereClause('Name IN :uniqueLotNames');

		for( Lot__c existingLot : Database.query(soql.getQuery())){
            
            if(existingLot.Name != null )
                existingLot.Name = (existingLot.Name).toUpperCase();
			
            String lotKey = existingLot.Name + '-' + existingLot.Item__c + '-' + existingLot.Company__c + '-' + existingLot.Expiration_Date__c;

            if( inputLotMap.containsKey( lotKey )){
                
                inputLotMap.put( lotKey, existingLot );
            }
        }

        DML.upsertAsSystem(); upsert inputLotMap.values();
         
        return inputLotMap;
    }
    
    public static map<String, SKID__c> generateExistingSkidMap( list< String > attributes, set<Id> uniqueLocations, String skidType ){
        
        map< String, SKID__c > existingSkidKeysMap = new map< String, SKID__c >();
        SchemaUtil util = SchemaUtil.getInstance();
        
        String whereClause = 'type__c = \''+ skidType +'\' ';
        //Conditional needed for CHEP Pallet usecases
        if( uniqueLocations != null ){
        	whereClause += 'and Location__c IN:uniqueLocations ';
        }
        
        whereClause += ' FOR UPDATE';
        
        set<String> skidFields = new set<string>{ 'id', 'quantity__c', 'location__r.facility__c', 'bin__r.location__c', 'bin__r.location__r.name', 'quantity_allocated__c' , 'item__r.company__c' ,'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c'};
        skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'SKID__c'));
        
        SOQLUtil soql = new SOQLUtil('SKID__c');
	    soql.addFields(skidFields);
	    soql.setWhereClause(whereClause);
	                    
        List< SKID__c > existingSkids = (list<SKID__c>) Database.query(soql.getQuery());  
 
        for( SKID__c existingSkid : existingSkids ){
            
            String key = '';
            
            for( String attributeName : attributes ) {
            	
            	if(!attributesToExclude.contains(attributeName.toLowerCase()))
                 	key += existingSkid.get( attributeName );
            
            }
            
            existingSkidKeysMap.put( key, existingSkid );
        }
        
        return existingSkidKeysMap;
    }
    
    public static map<String, SKID__c> generateExistingSkidMap(list<String> attributeList, set<Id> uniqueLocations, List<SKID__c> skidList){
        
        map< String, SKID__c > existingSkidKeysMap = new map< String, SKID__c >();
        
        if ( skidList.size() == 0 ) 
        	return existingSkidKeysMap;     // OTC-548
        
        SchemaUtil util = SchemaUtil.getInstance();
        
        Set<String> attributeSet = new Set<String>();
        attributeSet.addAll(attributeList);
        attributeSet.add('Type__c');
        
        String whereClause = SchemaUtil.getQueryFilter(skidList, attributeSet);
		
		if( uniqueLocations != null && uniqueLocations.size() > 0){
	        
	        String values = '(';
	        		
			Iterator<Id> iStringValues = uniqueLocations.iterator();
		
	        while(iStringValues.hasNext()){
	            values += '\'' + iStringValues.next() + '\'';
	            
	            if(iStringValues.hasNext()){
	                values += ' , ';    
	            }
	        }
	        
	        values += ')';
	        
        	whereClause += ' and Location__c IN '+ values;
        }
        
        whereClause += ' FOR UPDATE';
        
        set<String> skidFields = new set<string>{ 'id', 'Company__c', 'quantity__c', 'location__r.facility__c','location__r.facility__r.company__c', 'bin__r.location__c', 'bin__r.location__r.name', 'quantity_allocated__c','Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c'};
        skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'SKID__c'));
        
        SOQLUtil soql = new SOQLUtil('SKID__c');
	    soql.addFields(skidFields);
	    soql.setWhereClause(whereClause);
	    
        for( SKID__c existingSkid : (list<SKID__c>) Database.query(soql.getQuery())){
            
            String key = '';
            
            for( String attributeName : attributeList ) {
            	if(!attributesToExclude.contains(attributeName.toLowerCase())){
                 	key += existingSkid.get( attributeName );
            	}
            }
            
            existingSkidKeysMap.put( key, existingSkid );
        }
        
        return existingSkidKeysMap;
    }
    
    
    
    
    //OTC-471 DP: Noticed that building this map with the string key was using 13.5MB heap, and generating with a collection key was only 1.2MB.
    //made another method that uses the key that takes up less memory.    
    public static List<String> generateKeyListForIT(Inventory_Transaction__c it, list<String> attributes){
    	List<String> keyList = new List<String>();

    	for( String attributeName : attributes ) {
            if (attributeName == 'Location__c') {
                attributeName = 'To_Location__c'; 
            } else if (attributeName == 'Facility2__c') {
                attributeName = 'To_Facility__c';
            }
             
            if (!attributesToExclude.contains(attributeName.toLowerCase())) {
            	keyList.add(it.get( attributeName)+'');	
            }	
        }
        return keyList;
    }    
        
    
    //OTC-471 DP: Noticed that building this map with the string key was using 13.5MB heap, and generating with a collection key was only 1.2MB.
    //made another method that uses the key that takes up less memory.
    public static map<List<String>, SKID__c> generateExistingSkidKeyListMap(list<String> attributeList, set<Id> uniqueLocations, List<SKID__c> skidList){
        
        map<List<String>, SKID__c> existingSkidKeysMap = new map<List<String>, SKID__c >();
        
        if ( skidList.size() == 0 ) 
        	return existingSkidKeysMap;     // OTC-548
        
        SchemaUtil util = SchemaUtil.getInstance();
        
        Set<String> attributeSet = new Set<String>();
        attributeSet.addAll(attributeList);
        attributeSet.add('Type__c');
        
        String whereClause = SchemaUtil.getQueryFilter(skidList, attributeSet);
		
		if( uniqueLocations != null && uniqueLocations.size() > 0){
	        
	        String values = '(';
	        		
			Iterator<Id> iStringValues = uniqueLocations.iterator();
		
	        while(iStringValues.hasNext()){
	            values += '\'' + iStringValues.next() + '\'';
	            
	            if(iStringValues.hasNext()){
	                values += ' , ';    
	            }
	        }
	        
	        values += ')';
	        
        	whereClause += ' and Location__c IN '+ values;
        }
        
        whereClause += ' FOR UPDATE';
         
        set<String> skidFields = new set<string>{ 'id', 'quantity__c', 'location__r.facility__c', 'item__r.Stocking_UOM__c','item__r.Packaging_UOM__c',
        						'bin__r.location__c', 'bin__r.location__r.name', 'quantity_allocated__c'};
        skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'SKID__c'));
        
        SOQLUtil soql = new SOQLUtil('SKID__c');
	    soql.addFields(skidFields);
	    soql.setWhereClause(whereClause);
	    
        for( SKID__c existingSkid : (list<SKID__c>) Database.query(soql.getQuery())){
            
            List<String> keyList = new List<String>();
            
            for( String attributeName : attributeList ) {
            	if(!attributesToExclude.contains(attributeName.toLowerCase())){
                 	keyList.add(existingSkid.get(attributeName)+'');
            	}
            }
            
            existingSkidKeysMap.put(keyList, existingSkid );
        }
        
        return existingSkidKeysMap;
    }    
    
    //pass in the list of skids, with a map of matching attributes and its values 
    //it returns the map of location skids with keys to be used for creating inventory transactions
    global static Map <String, SKID__c> putAwayService( List< SKID__c > skidList, list< String > attributes, set<Id> uniqueLocations, String skidType, Boolean consume ){
        Map<String,Schema.SObjectField> skidFields = SchemaUtil.getInstance().getFieldsMap('SKID__c');
        
        // location is being passed in //String Location = 'Stock'; //hardcoding location till the redesign of stockpointrules
        list< String > attributeList = new list< String > ();
        attributeList.addAll( attributes );
        
        String skidTypeForQuery = skidType;
        
        set<String> attributeSet = new set<String>();
        attributeSet.addAll( attributes );
        //attributeList.add('Location__c'); // location is an attribute too
        if( skidList.size() > 0 && skidType =='Allocated' && (!attributeSet.Contains('Sales_Order_Line__c')) && skidList[0].Sales_Order_Line__c != null ) {
            attributeList.add('Sales_Order_Line__c');
        }
        else if( skidList.size() > 0 && skidType =='Allocated' && (!attributeSet.Contains('Order_Line__c')) && skidList[0].Order_Line__c != null ) {
            attributeList.add('Order_Line__c');
        }
        
        map< String, SKID__c > existingSkidKeys = new map< String, SKID__c >();
 
        map< Id, SKID__c > skidsForUpdate = new map< id, SKID__c >();
        map< String, SKID__c > skidsForInsert = new map< String, SKID__c >();
        map< String, SKID__c > toSkids = new map< String, SKID__c >();
        
        if( skidList.size() > 0 ){
            existingSkidKeys = generateExistingSkidMap(attributeList, uniqueLocations, skidList);
        }
    
  		// existingSkidKeys is held FOR UPDATE by       generateExistingSkidMap
  		// however, skidList is NOT, and it has the incorrect quantities?!!
  		// so, we use the quantities from existingSkidKeys whenever we set skidsForUpdate 
        for (SKID__c skid:skidList) {
            String key = '';

            for (String attr:attributeList) {
                attr = attr.toLowerCase();

                if (!attributesToExclude.contains(attr)) {
                    if (skidFields.get(attr).getDescribe().getType() == Schema.DisplayType.Boolean && skid.get(attr) == null) {
                        skid.put(attr,false);
                    }
                    
                 	key += skid.get(attr);
                }
            }
            
            if( existingSkidKeys.containsKey( key ) ){
                
                SKID__c sk = existingSkidKeys.get( key );
                if(sk.Quantity__c == null )
                	sk.Quantity__c = 0;
                if( skid.Quantity__c == null )
                	skid.Quantity__c = 0;	
                
                if( skidsForUpdate.containsKey( sk.id ))
                    sk = skidsForUpdate.get( sk.id );
                
                if(skidType == SKID_TYPE_TO_DEMAND || skidType == SKID_TYPE_TO_SUPPLY || skidType == SKID_TYPE_DROP_SHIP)
                    sk.Quantity__c = skid.Quantity__c;
                else
                    sk.Quantity__c += skid.Quantity__c;
                    
            	sk.Quantity_to_Issue__c = skid.Quantity_to_Issue__c;            	            	
            	
            	if(sk.unique_key__c == null){ //to address old skids without unique keys
            		//use new key generation method to be used in generating unique keys for skids.
    	        	list<String> keyClone = SkidService3.generateKey(sk, attributeList);
	                keyClone.add(sk.Type__c);
	                
	                String Message= string.join(keyClone, ',');
                    sk.unique_Key__c = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-1', Blob.valueOf(Message)));
                }
                
                skidsForUpdate.put( sk.id , sk ); 
                toSkids.put( key, sk );
            }
            else if( skidsForInsert.containsKey( key )){
                
                skidsForInsert.get( key ).Quantity__c += skid.Quantity__c;
            }
            else{
                
                SKID__c newSkid = skid.clone(false, true);

                if(skid.Bin__c != null ){
                	newSkid.Bin__c = skid.Bin__c;
                	newSkid.Bin__r = skid.Bin__r;
                }
                newSkid.Location__c = skid.Location__c;
                newSkid.Quantity__c = skid.Quantity__c;
                newSkid.type__c = skidType;
                
                if( skidType == SKID_TYPE_LOCATION){
                    newSkid.Sales_Order_Line__c = null;
                    newSkid.Order_Line__c = null;
                    newSkid.Shipment_Line__c = null;    
                }
                if( consume ){
                    newSkid.Purchase_Order_Line__c = null;
                    newSkid.Consigned_Owner__c = null;
                }
                
                list<String> keyClone = SkidService3.generateKey(newSkid, attributeList);
                keyClone.add(newSkid.Type__c);
                
                String Message= string.join(keyClone, ',');                
                newSkid.unique_Key__c = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-1', Blob.valueOf(Message)));
                
                skidsForInsert.put( key, newSkid );
                toSkids.put( key, newSkid );
            }
        }
        
        if( toSkids.values().size() > 0 ){
            DML.upsertAsSystem(); upsert toSkids.values();
        }
        return toSkids;
    }
    
    public static String generateKeyForIT(Inventory_Transaction__c it,List<String> attributes) {
        String key = '';

        for (String attr:attributes) {
            attr = attr.toLowerCase();

            if (!attributesToExclude.contains(attr)) {
                if (attr == 'location__c') attr = 'to_location__c';
                else if (attr == 'facility2__c') attr = 'to_facility__c';

                key += it.get(attr);
            }
        }
        return key;
    }
    
    global static void inventoryTransactionsForPutAway(Map<Id,sObject> sourceDocs,Map<Id,List<Inventory_Transaction__c>> itMap,Map<Id,String> icTypes,Map<Id,Inventory_Change__c> existingICs,List<String> attributes,Map<String,SKID__c> toSkids,String adjustFromSkidQuantity,String putawayDirection) {
        Map<Id,Inventory_Change__c> icMap = generateICsForITs(sourceDocs,itMap,icTypes,existingICs);
        
        List<Inventory_Transaction__c> allITs = new List<Inventory_Transaction__c>();
        for (List<Inventory_Transaction__c> itList:itMap.values())
            allITs.addAll(itList);
        if (adjustFromSkidQuantity == null || putawayDirection == null)
            inventoryTransactionsForPutAway(allITs,attributes,toSkids);
        else
            inventoryTransactionsForPutAwayV2(allITs,attributes,toSkids,adjustFromSkidQuantity,putawayDirection);
        
        if (existingICs == null)
            DML.updateAsSystem(icMap.values());
        else
            existingICs.putAll(icMap);
    }
    
    global static void inventoryTransactionsForPutAway( list< Inventory_Transaction__c > itList, list< String > attributes,  map< String, SKID__c > toSkids  ){
        
        inventoryTransactionsForPutAwayV2( itList, attributes, toSkids, 'negative', 'to');
    }
    
    public static void inventoryTransactionsForPutAwayV2( list< Inventory_Transaction__c > itList, list< String > attributes,  map< String, SKID__c > toSkids, String adjustFromSkidQuantity, String putawayDirection  ){
        
        //valid  values for adjustfromskidquantity are 'positive' , 'negative' ,'none'
        //valid values for putawayDirection are 'from', 'to'
        
        // it list is prefilled with quantity , type, object reference and from skid info by the process controller ( e.g. receiving controller)
        // deduction from the from skid is done here with it quantity ( e.g. deducting the quantity on the PO Supply skids )
        // creates inventory trancations for putaway.
        
        map< Id, SKID__c> updateFromSkids = new map<Id, SKID__c>();
        map< Id, SKID__c> deleteFromSkids = new map<Id, SKID__c>();

        for( Inventory_Transaction__c it : itList ){
            
            String key = generateKeyForIT( it, attributes );
            
            if( toSkids.containsKey( key ) ){
            
                it.put(putawayDirection+'_SKID__c', toSkids.get( key ).id);
                it.put(putawayDirection+'_Location__c', toSkids.get( key ).Location__c);
                it.put(putawayDirection+'_Facility__c', toSkids.get( key ).Location__r.Facility__c);
                it.putSObject(putawayDirection+'_SKID__r', toSkids.get( key ));
            }
            
            if(it.from_lot__c == null){
            	it.from_lot__c = it.Lot__c ;//PTM-578
            }
            
            SKID__c fromSkid;
            if( updateFromSkids.containsKey( it.From_SKID__c ) ){
                fromSkid = updateFromSkids.get( it.From_SKID__c );      
            }
            else{
                fromSkid = it.From_SKID__r;
            }
            
           	if( fromSkid != null && fromSkid.Id != null && fromSkid.id != it.To_Skid__c && it.Quantity__c != null  ) { //Conditional needed for CHEP Pallet usecases and PTM-586
    	        if( adjustFromSkidQuantity == 'negative')     
    	            fromSkid.Quantity__c -= it.Quantity__c ;
    	        else if( adjustFromSkidQuantity == 'positive')
    	            fromSkid.Quantity__c += it.Quantity__c;
    	             
	            updateFromSkids.put( fromSkid.id, fromSkid );
           	}
           	
           	if( it.to_skid__c != null && ((it.to_skid__r.Quantity__c == 0 && (!doNotDeleteSkidTypes.contains( it.to_skid__r.Type__c ))) ||
                (it.to_skid__r.Quantity__c < 0 && (deleteSkidTypesIfNegative.contains( it.to_skid__r.Type__c )))) ){
                //add to skids to the update list if the to skid needs to be deleted as well because the skid quantity is <=0 
                updateFromSkids.put( it.to_skid__c, it.to_skid__r.clone(true,true) );
            }
            
            if(putawayDirection == 'from'){
                it.to_Location__c = null;
               	it.to_facility__c = null;
               	it.Bin__c = null;
            }
           	it.From_SKID__r = null;
           	it.To_SKID__r = null;
            
        }
        
        for( Id skidId : updateFromSkids.keySet() ){
           
            if( (updateFromSkids.get( skidId ).Quantity__c == 0 && (!doNotDeleteSkidTypes.contains( updateFromSkids.get( skidId ).Type__c )))
                || (updateFromSkids.get( skidId ).Quantity__c < 0 && (deleteSkidTypesIfNegative.contains( updateFromSkids.get( skidId ).Type__c )))){
                
                deleteFromSkids.put( skidId, updateFromSkids.get( skidId ) );
                updateFromSkids.remove( skidId );
            }
                
        }
    
        DML.insertAsSystem(itList);
        DML.updateAsSystem( updateFromSkids.values() );
        DML.deleteAsSystem( deleteFromSkids.values() );   
    }
    
    global static List<String> attributesForPutaway( list<String> attributes){
        
        list<String> attr = new list<String>();

        attr.add('Facility2__c');
        attr.add( 'Item__c');
        attr.add('Location__c');
        for( String att : attributes ){
            
            if(!attributesToExclude.contains(att.toLowerCase())){
	            if( att == 'Lot_Number__c')
	                attr.add('Lot__c');
	            else    
	                attr.add( att );
            }
        }

        attr.add( 'Bin__c');
        attr.add( 'Consigned_Owner__c');
        attr.add( 'Purchase_Order_Line__c');
        attr.add('Receipt_Line__c');
        
        return attr;
    }
    
    public static Boolean checkRequiredAttributes( SKID__c sk, list<String> attributes,  String recordMessage, JsonResult result ){
        
        try{
            SchemaUtil util = SchemaUtil.getInstance();
            Map<String, Schema.SObjectField> fieldMap = util.getFieldsMap( 'SKID__c' );
            
            for( String attr : attributes ){
    	            
                if(!attributesToExclude.contains(attr.toLowerCase())){
                    
    	            if(! String.isNotBlank( String.valueOf( sk.get(attr) ))   ){
    	                String msg = fieldMap.get(attr).getDescribe().getLabel()+' '+recordMessage;
    	                    
    	                if (result != null) {
    	                    result.addMessage(msg, ApexPages.Severity.ERROR);
    	                }
    	                else {
    	                    throw new SkidService2Exception( msg );
    	                }
    	
    	                return true;
    	            }
                }
            }
        }
        catch( Exception ex ){
            throw ex;
        }
        return false;
    }
    
    public static void populateLotNames( SKID__c skid , Id supplierId, map< String, Lot__c > lotMap, Set<String> lotNames ){
        
        if( skid.Item__r.Item_Attribute__r.Lot_Number__c == true && skid.Item__r != null && skid.Item__r.Item_Attribute__r != null ){
            if(skid.Lot_Number__c != null )
                skid.Lot_Number__c = (skid.Lot_Number__c).toUpperCase();

            String uniqueString = lotUniqueKey(skid, supplierId);
                                    
            Lot__c newLot = new Lot__c( Name = skid.Lot_Number__c , Item__c = skid.Item__c , Company__c = getCompanyFromSkid(skid), 
                            Supplier__c =  supplierId, Expiration_Date__c = skid.Expiration_Date__c    );
                            
            lotMap.put( uniqueString, newLot );
    
            lotNames.add( skid.Lot_Number__c );      
        }
    }
    
    /* in a world where skids do not have a lookup to company, we can find the company from 
     * Item or Location.Facility
     */
    public static Id getCompanyFromSkid( SKID__c skid ) {
      	
      	Id companyId = (skid.Company__c != null) ? skid.Company__c : AccountingRuleService.getValue('Location__r.Facility__r.Company__c', skid);	
    		if ( companyId == null ) companyId = AccountingRuleService.getValue('Item__r.Company__c', skid );	
    		
    		system.assertNotEquals(Null, companyId, ' expected not null company in skid :' + skid);		
		return companyId; 
	}
	
    public static String lotUniqueKey( SKID__c sk, Id supplierId ){
        String company = (sk.Company__c != null) ? sk.Company__c : getCompanyFromSkid(sk);
        System.debug(LoggingLevel.INFO, '*** company: ' + company);
        return sk.Lot_Number__c + '-' + sk.Item__c + '-' + company  + '-' + sk.Expiration_Date__c;
    }
    
    global static Inventory_Transaction__c createIT( SKID__c fromSkid, ID itemId, String type, ID purchaseOrderLineId, ID workOrderId, ID inventoryChangeId, Id toLocationId, SKID__c toSkid, list<String> attributeFields ){
        
        Inventory_Transaction__c it = new Inventory_Transaction__c();
        
        it.type__c = type;
        it.item__c = itemId;
        it.To_Location__c = toLocationId;
        it.Work_Order__c = workOrderId;
        it.Inventory_Change__c = inventoryChangeId;
        it.Transaction_Date__c = system.now();
        it.Finalized__c = true;
        it.Purchase_Order_Line__c = purchaseOrderLineId;
        
        if(fromSkid != null) { //Conditional needed for CHEP Pallet usecases
        	it.From_SKID__c = fromSkid.id;
	        it.From_SKID__r = fromSkid;
	        it.From_Location__c = fromSkid.Location__c;   
	        // KNDY 3420 : From Facility Id is new formula field coming from Location
	        //it.From_Facility__c = fromSkid.Location__r.Facility__c;
	        it.From_Bin__c = fromSkid.bin__c;
	        
	        //it.Standard_Cost__c = KSE.addQuantityToField(fromSkid.Item__r.Active_Standard_Cost__c, 0); //Needs to use the method in the ItemService class to get the active standard cost
	        it.from_lot__c = fromSkid.Lot__c ;
        }

       
        if( toSkid != null) {
            copyToSkidAttributesToIT( it, toSkid, attributeFields );
        }
        
        return it;
    }
    
    public static void copyToSkidAttributesToIT(Inventory_Transaction__c it,SKID__c toSkid,List<String> attributes) {
        Map<String,Schema.SObjectField> itFields = SchemaUtil.getInstance().getFieldsMap('Inventory_Transaction__c');

        it.To_Facility__c = toSkid.Facility2__c;
        it.To_Location__c = toSkid.Location__c;
        
        if (toSkid.Id != null) {    
            it.To_SKID__c = toSkid.Id;
            it.To_SKID__r = toSkid.clone(true,true);
        }

        if (attributes != null) {
            for (String attr:attributes) {
                attr = attr.toLowerCase();

                if (!attributesToExclude.contains(attr.toLowerCase()) && attr != 'facility2__c' && attr != 'location__c' && attr != 'purchase_order_line__c' && (attr != 'item__c' || it.Item__c == null)) {
                    if (itFields.get(attr.toLowerCase()).getDescribe().getType() == Schema.DisplayType.Boolean && toSkid.get(attr) == null) {
                        it.put(attr,false);
                    } else {
                        it.put(attr,toSkid.get(attr));
                    }
                }
            }
        }
    }
    
    public static void copyITAttributesToSkid(SKID__c skid,Inventory_Transaction__c it,List<String> attributes) {
        skid.Facility2__c = it.To_Facility__c;
        skid.Location__c = it.To_Location__c;
        skid.Location__r = it.To_Location__r;

        for (String attr:attributes) {
            if (attr != 'Location__c' && attr != 'Facility2__c') {
                skid.put(attr,it.get(attr));
            }
        }
    }
    
    public static list<String> trackedAttributes( list<String> attributeFields, Location__c putAwayLocation, SObject item ){
        
        list<String> trackedAttributesService = new list<String>();
        
        for( String attr : attributeFields ){

            if(!attributesToExclude.contains(attr.toLowerCase())){
	            if( item.get('Item_Attribute__c')!= null && 
	                item.getSObject('Item_Attribute__r').get(attr) == true && (item.get('Non_Inventory__c') !=true || item.get('Source__c') == 'Outside Processing' )){
	                    
	                    trackedAttributesService.add( attr );
	            }
            }
        }   
        
        if(putAwayLocation != null && putAwayLocation.get('Bin_Tracked__c') == true && (item.get('Non_Inventory__c') !=true || item.get('Source__c') == 'Outside Processing'))
            trackedAttributesService.add( 'Bin__c');
            
        return trackedAttributesService;
        
        
    }
    
    public static map<Id,SKID__c> locationSkidsForAllocatedSkids( list<SKID__c> skidList, list<String> attributes, String headerRelationshipName ){
        
        map<Id, SKID__c> locationSkidsPerAllocatedSkid = new map<Id,SKID__c>();
        map<String, list<SKID__c>> locationSkidsByKey = new map<String, list<SKID__c>>();
        set<Id> locationIdSet = new set<Id>();
        set<Id> itemIdSet = new set<Id>();
        
        for( SKID__c allocSkid : skidList ){
            
            locationIdSet.add( allocSkid.Location__c );
            itemIdSet.add( allocSkid.Item__c );
        }
        //( Expiration_Date__c = null or Expiration_Date__c >=:tod ) and  
        String additionalWhere = ' and (Lot__c = null OR Lot__r.Lot_Hold__c = false) and Location__r.Nettable__c = true ';
        list<SKID__c> locationSkids = pullQuery( null, locationIdSet, itemIdSet, additionalWhere , '\''+SkidService2.SKID_TYPE_LOCATION+'\'');
        
        for( SKID__c sk : locationSkids ){
            
            String key = generateKeyForSkid( sk, null, null, null );
            
            if( !locationSkidsByKey.containsKey(key) )
                locationSkidsByKey.put( key, new list<SKID__c>());
            locationSkidsByKey.get( key ).add( sk );    
        }
        
        for( SKID__c allocSkid : skidList ){
            
            String key = generateKeyForSkid( allocSkid, null, null, null );
            
            if( locationSkidsByKey.containsKey( key )  ){
                
                list<SKID__c> locationSkidsForKey = locationSkidsByKey.get(key);
                
                for( SKID__c sk : locationSkidsForKey ){
                    
                    if( sk.Quantity__c >= allocSkid.Quantity__c ){
                        
                        locationSkidsPerAllocatedSkid.put( allocSkid.id, sk );
                        break;
                    }
                }
            }
            
            if(! locationSkidsPerAllocatedSkid.containsKey( allocSkid.id )){
                
                throw new SkidService2Exception('Allocated quantity not available with all the matching attributes for :'+allocSkid.getSObject(headerRelationshipName).get('Name'));
            }
        }
        
        
        return locationSkidsPerAllocatedSkid;
    }
    
    public static list<SKID__c> pullQuery(list<String> sortFields, set<Id> locationIdSet, set<Id> itemIdSet, String additionalWhereClause, String skidType){
        
        String orderByClause = ' ORDER BY ';
        //String queryString = ' SELECT Id '; 
        String whereClause = 'Type__c = ' + skidType;
        
        Set<String> skidFields = new set<String>();
        
        skidFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( null, 'SKID__c'));
        skidFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );
        skidFields.addAll( new Set<String>{ 'Id', 'Location__r.Facility__c', 'Location__r.Facility__r.Company__c', 'Location__r.Facility__r.Name', 
        				  'Location__r.Nettable__c', 'Name', 'Sales_Order_Line__r.Ship_From_Location__c', 'CreatedDate', 'Item__r.Stocking_UOM__c',
        				  'LastModifiedDate', 'Location__r.Name', 'Lot__r.Name', 'Bin__r.Name', 'Item__r.Company__c','Company__c', // #JUSTDOIT Remove Item__r.Company__c when the related methods are deprecated.
        				  'Item__r.Name', 'Consigned_Owner__r.Name', 'Purchase_Order_Line__r.Name', 'Item__r.Packaging_UOM__c' });
        
        /*for( String s : skidFields ){
            queryString += ' , '+s;
        }*/
        
        if( sortFields != null ){
            for( Integer i = 0; i < sortFields.size() ; i++ ){
                
                orderByClause += sortFields[i];
                
                if( ( sortFields.size() - 1 ) != i )
                    orderByClause += ' , ';
            }
        }
        
        Date tod = system.today();
        //queryString += ' FROM SKID__c WHERE  type__c = '+type ;

        if( itemIdSet.size() > 0 )
            whereClause += ' and Item__c IN:itemIdSet ';
            //queryString += ' and Item__c IN:itemIdSet ';
        if( locationIdSet.size() > 0 )
            whereClause += ' and Location__c IN:locationIdSet ';
            //queryString += ' and Location__c IN:locationIdSet ';
        if( additionalWhereClause != null )
            whereClause += additionalWhereClause;
            //queryString += additionalWhereClause;       
        
        // TODO note we cannot lock the skids if we sort the query, fix this to sort
        // the records after we get them back from the database, so that we CAN lock...
        if( sortFields != null && sortFields.size() > 0 )
            whereClause += orderByClause;
            //queryString += orderByClause;					 
        else 
        	whereClause += ' FOR UPDATE'; 
        	//queryString += ' FOR UPDATE';
        
        SOQLUtil soql = new SOQLUtil('SKID__c');
	    soql.addFields(skidFields);
	    soql.setWhereClause(whereClause);
	    		
        return Database.query( soql.getQuery() );
        
    }
    
    public static list<SKID__c> pullFromList( map<String, list<SKID__c>> itemLocationKeyList, list<String> sortFields, set<Id> locationIdSet, set<Id> itemIdSet, 
                                    String additionalWhereClause, list<SKID__c> allocatedSkids, set<Id> allocatedLocationIdSet  ){
        
        Id nullId = null;
        list<SKID__c> orderedSkidList = pullQuery(sortFields, locationIdSet, itemIdSet, additionalWhereClause, '\'Location\'');
        if(allocatedSkids != null )
            allocatedSkids = pullQuery(sortFields, allocatedLocationIdSet, itemIdSet, additionalWhereClause, '\'Allocated\'');
        
        for( SKID__c sk : orderedSkidList ){
            
            String key = sk.Item__c +','+ sk.Location__c;
            if( locationIdSet.size() == 0 && itemIdSet.size() != 0 )
                key = sk.Item__c+','+nullId;
            else if( itemIdSet.size() == 0 && locationIdSet.size() != 0 )
                key = nullId+','+sk.Location__c;
            else if( locationIdSet.size() == 0 && itemIdSet.size() == 0)
                key = nullId+','+nullId;    
                
            if( itemLocationKeyList.containsKey( key ))
                itemLocationKeyList.get( Key ).add( sk );
            
        }
        return allocatedSkids;
        
    }
    
   //location index map is used to specify which location to pull from the list of locations in the locationsByHeaderMap.
   // a value of -1 would mean all locations in the list. 
   // if this map doesnt have a value for a line, it will take the first index from the list.
    public static map<String, list<SKID__c>> pullSortedSkids( list<SObject> sobjectList , list<String> sortFields, map<Id, list<Location__c> > locationsByHeader, String additionalWhereClause, 
                                                                String itemType, list<SKID__c> allocatedSkids, map<Id, Integer> locationIndexMap ){ 
        
        map<String, list<SKID__c>> itemLocationKeyList = new map<String, list<SKID__c>>();
        set<Id> locationIdSet = new set<Id>();
        set<Id> allocationLocIdSet = new set<Id>(); // using this set to hold all locations as we need allocated skids from all locations specified, not just the current index
        set<Id> itemIdSet = new set<Id>();
        
        for( SObject s : sobjectList ){
            
            Id itemId;
            set<Id> locIdSet = new set<Id>();
            
            if( itemType == 'Product') {
                itemId = (Id)s.getSObject('Product__r').get('Item__c');
            } else {
                List<String> itemFields = itemType.split('\\.',0);
                sObject curObj = s;
                for (String itemField:itemFields) {
                    if (itemField.contains('__r')) {
                        curObj = curObj.getSObject(itemField);
                    } else { 
                        if (!itemField.contains('__c'))
                            itemField += '__c';
                        itemId = (Id)curObj.get(itemField);
                        break;
                    }
                }  
            }
                
            Id locationId;
            Integer index = 0;
            if( locationIndexMap!= null && locationIndexMap.containsKey(s.id) && locationIndexMap.get(s.id) >=0 ){
                index = locationIndexMap.get(s.id);
            }
            else if(locationsByHeader != null && locationsByHeader.containsKey(s.Id) && locationIndexMap!= null && locationIndexMap.containsKey(s.id) && locationIndexMap.get(s.id) < 0){
                index = locationIndexMap.get(s.id);
                locIdSet.addAll(KSE.grepRelatedIdSetFromList( locationsByHeader.get( s.id ), 'Id', true));
            }
            
            if( s.id != null && locationsByHeader != null && locationsByHeader.containsKey( s.id ) && allocatedSkids != null ){
                
                allocationLocIdSet.addAll(KSE.grepRelatedIdSetFromList( locationsByHeader.get( s.id ), 'Id', true));
            }
            
            if( s.id != null && locationsByHeader != null && locationsByHeader.containsKey( s.id ) && locationsByHeader.get( s.id ).size() > index && index >= 0 )
                locationId = locationsByHeader.get( s.id )[index].id;
            else if(locationsByHeader != null && (!locationsByHeader.containsKey( s.id ) || locationsByHeader.get( s.id ).size() <= index  && index >= 0 ))
                continue;
            else if( locationsByHeader == null  && index >= 0){   
                String str = JSON.serialize(s);
                // Deserialize it back into a key/value map
                Map<String,Object> obj = (Map<String,Object>) JSON.deserializeUntyped(str);
                
                if( obj.containsKey(KSE.namespace+'__Location__c') || obj.containsKey('Location__c') )
                    locationId = (Id)s.get('Location__c');
                   
            }
            
            if( index >= 0 && locationId != null ) locIdSet.add(locationId);
            else if( index >= 0 && locationId == null ){
                String key = itemId +','+ locationId;
                itemLocationKeyList.put( key , new list<SKID__c>() );
            }
            
            if( itemId != null )
                itemIdSet.add( itemId );
            
            for( Id locId : locIdSet ){
                String key = itemId +','+ locId;
                itemLocationKeyList.put( key , new list<SKID__c>() );
                
                if( locId != null )    
                    locationIdSet.add( locId );    
            }
        }
        if( allocatedSkids != null )
            allocatedSkids.addAll(pullFromList( itemLocationKeyList, sortFields, locationIdSet, itemIdSet, additionalWhereClause, allocatedSkids, allocationLocIdSet ));
        else
            pullFromList( itemLocationKeyList, sortFields, locationIdSet, itemIdSet, additionalWhereClause, allocatedSkids, allocationLocIdSet );
        return itemLocationKeyList;
    }
    
    public static Boolean checkIssueError( list<SObject> headerList, Map<Id, List<SKID__c>> quantitySkidsByHeader, map< Id, decimal> quantityToDistributeByHeaderId, 
                                        map< Id, String> itemNameMap, String inputField, String availableField, String errorType, String ProcessName, Map<String, Decimal> allocatedQty, Boolean convertUOM ){
        //***TODO****
        //TODO : change all apexPages.addmessage to throw skidservice2 excpetions if the errorType is error. Instead of checking if the processName is transferorderallocate , we have to check for errorType is error.
        // When this is done , all the references in Work Orders and Sales Orders should handle this exception. This should be part of the effort to make sales orders friendly to EDI.
        
        map<Id, Decimal> quantityBySkid = new map<Id, Decimal>();
        Map<String, Decimal> allocatedQtyMap;
        //list<Id> hasQuantitiesEntered = new list<Id>(); PTM-281
        Boolean hasQuantitiesEntered = false;
        ApexPages.Severity sev;
        
        if( allocatedQty != null ){
            allocatedQtyMap = allocatedQty.clone();
        }
        
        if( errorType == 'Warning') 
            sev = ApexPages.Severity.Warning;
        else
            sev = ApexPages.Severity.Error; 
        
        for ( SObject header : headerList ) {
            
            Decimal totalQuantityIssued = 0;
            Decimal conversionFactor = 1.0;
            
            if( convertUOM )
            {
            	if(header.getSObjectType()==Sales_Order_Line__c.sObjectType)
            	    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_From_Stock__c'),(decimal)header.get('Quantity_Ordered__c'));//KSE.getConversionFactor(header);
            	else if(header.getSObjectType()==Purchase_Order_Line__c.sObjectType)
            	    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_To_Stock__c'),(decimal)header.get('order_quantity__c'));//KSE.getConversionFactor(header);
            	else if(header.getSObjectType()==Receipt_Line__c.sObjectType)
            		conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.getsObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)header.getsObject('Purchase_Order_Line__r').get('order_quantity__c'));//KSE.getConversionFactor(header);
            	

            }

            for( SKID__c qtySkid : quantitySkidsByHeader.get( header.id ) ){
            
            	String name = (String)qtySkid.get('Name');
                if( itemNameMap != null && itemNameMap.containsKey(header.id) ) name = itemNameMap.get(header.id);

                if( qtySkid.get(inputField) != null && qtySkid.get(inputField) != 0 && ( ((Decimal)qtySkid.get(inputField) > 0) || processName =='InventoryChange' ) ){                    
                    
                    totalQuantityIssued += (Decimal)qtySkid.get(inputField);
                    
                    if( processName != 'WOComponentScrap')
                        calculateQuantityAvailable( qtySkid, quantityBySkid, allocatedQtyMap, availableField, conversionFactor );
                    
                    Decimal diff = KSE.subtractDecimals((Decimal)qtySkid.get(availableField) , (Decimal)qtySkid.get(inputField));
                    
                    if( processName == 'InventoryChange' ) diff = KSE.addQuantityToField((Decimal)qtySkid.get(availableField) , (Decimal)qtySkid.get(inputField));
                    
                    if( diff < 0  && (processName != 'InventoryChange' || (processName == 'InventoryChange' && (Decimal)qtySkid.get(inputField) < 0))){//PTM-622

                        String message = 'Issuing more than available on hand ('+qtySkid.get(inputField)+') for : '+name;
                        
                        if( (processName == 'TransferOrderAllocate' || processName == 'Complete' || processName == 'Kit' || processName == 'InventoryTransfer' || processName == 'InventoryChange') && errorType != 'Warning')
                            throw new SkidService2Exception(message);
                        else    
                            ApexPages.addMessage( new ApexPages.Message( sev,message ) );  
                    }   
                    quantityBySkid.put( qtySkid.id, KSE.subtractDecimals((Decimal)qtySkid.get(availableField) , (Decimal)qtySkid.get(inputField)) );
                    hasQuantitiesEntered = true;  
                }
                else if( qtySkid.get(inputField) != null && qtySkid.get(inputField) !=0 ){
                	String message = 'Invalid Quantity Entered ('+qtySkid.get(inputField)+') for : '+name;
                	
                	if( (processName == 'TransferOrderAllocate'|| processName == 'Complete' || processName == 'Kit' || processName == 'InventoryTransfer') && errorType != 'Warning')
                            throw new SkidService2Exception(message);
                    else        
                	    ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.Error,message) );
                }
            }

			    //PTM-76 Rounding Error on WO
            if( quantityToDistributeByHeaderId != null && totalQuantityIssued > (quantityToDistributeByHeaderId.get( header.id ).setscale(6)) ){
                String message = 'Issuing more than Quantity Short (' + quantityToDistributeByHeaderId.get( header.id ).setscale(6)  +
                                     ') for Item';
                if( itemNameMap != null )  message+= ' :'+ itemNameMap.get(header.id);                                     
                
                if( processName == 'TransferOrderAllocate' || processName == 'InventoryTransfer')
                    throw new SkidService2Exception(message);
                else 
                ApexPages.addMessage(new ApexPages.Message(sev,message));
            }
            
            //if( totalQuantityIssued > 0 || ( totalQuantityIssued < 0 && processName == 'InventoryChange' ) ) Commenting as part of PTM-281
               // hasQuantitiesEntered.add( header.id );
                
            
        }
        
        if( hasQuantitiesEntered == false ){
                
            String message = Label.No_Quantities_Entered ;
                
            if( processName == 'TransferOrderAllocate'|| processName == 'Complete' || processName == 'Kit' || processName == 'InventoryTransfer')
                throw new SkidService2Exception(message);
            else     
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,message));
                return true;
        }   
        return false;
    }
    
    public static String generateKeyForSkid( SKID__c sk,  list<String> attributeFields, String processName, SObject sObj ){
        Map<String,Schema.SObjectField> fieldMap = SchemaUtil.getInstance().getFieldsMap('SKID__c');
        
        String key='';
        
        list<String> attrList;
        if( attributeFields == null )
            attrList = attributesForPutaway(new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c')));
        else
            attrList = attributeFields;
        
        for( String attr : attrList ){
            
            if(!attributesToExclude.contains(attr.toLowerCase())){
	            if( processName == 'Transfer Of Ownership' && ( attr == 'Consigned_Owner__c' || attr == 'Purchase_Order_Line__c'))
	                key += 'null';
	            else if( (processName == 'Transfer' || processName == 'Transfer Order Shipment') && sObj != null && ( attr == 'Location__c' || attr == 'Bin__c')){
	            	key += String.valueOf(sObj.get(attr));
	            }                
	            else {    
                    if (fieldMap.get(attr.toLowerCase()).getDescribe().getType() == Schema.DisplayType.Boolean && sk.get(attr) == null) {
                        key += String.valueOf(false);
                    } else {
                        key += String.valueOf(sk.get(attr));
                    }
                }
            }
        }
        
        return key;
    }
    
    public static void queryAllocatedSkids( Map<String, Decimal> allocatedQty, list<SKID__c> allocatedSkids ){
        
        for( SKID__c sk : allocatedSkids ){
            String key =  generateKeyForSkid(sk, null, null, null);
            
            if( !allocatedQty.containsKey( key )){
                
                allocatedQty.put( key, 0);
            }
            allocatedQty.put( key, allocatedQty.get( key ) + sk.Quantity__c );
        }
        
    }
    
    public static void calculateQuantityAvailable( SKID__c qtySkid, map<Id, Decimal> quantityBySkid, Map<String, Decimal> allocatedQty, String availableField, Decimal conversionFactor ){
        
        if( quantityBySkid.containsKey( qtySkid.id ))
            qtySkid.put( availableField, (quantityBySkid.get(qtySkid.id) / conversionFactor).setscale(6,System.RoundingMode.HALF_UP) );
        else    
            qtySkid.put( availableField, (qtySkid.Quantity__c/conversionFactor).setscale(6,System.RoundingMode.HALF_UP) );
            
        if( allocatedQty != null ){
            String skidKey = generateKeyForSkid(qtySkid, null, null, null);
             
            if( allocatedQty.containsKey(skidKey) ){
                Decimal quantityAllocated = Math.min((Decimal)qtySkid.get( availableField), allocatedQty.get(skidKey)/conversionFactor );
                allocatedQty.put( skidKey , (allocatedQty.get(skidKey)/conversionFactor) - quantityAllocated  );
                qtySkid.put( availableField, (Decimal)qtySkid.get(availableField) - quantityAllocated );
                 
                if( allocatedQty.get(skidKey) == 0 ) allocatedQty.remove(skidKey);
            } 
        }  
        quantityBySkid.put( qtySkid.id, (Decimal)qtySkid.get(availableField) );
    }

    public static void distributeV2(    List <Shipment_Line__c> headerList, 
                                        Map <Id, List<SKID__c>> quantitySkidsByHeader, 
                                        Map <Id, Decimal> quantityToDistributeByHeaderId,
                                        Map <Id, Decimal> quantityByHeaderId, 
                                        Map <Id, String> itemNameMap, 
                                        Boolean distribute, 
                                        String availableField, 
                                        String toIssueField,
                                        String processName, 
                                        Map <String, Decimal> allocatedQty, 
                                        Boolean convertUOM,
                                        Map<Id, List<String>> errorMsgs  ){
       
        Map<Id, Decimal> quantityBySkid = new map<Id, Decimal>();
        Map<String, Decimal> allocatedQtyMap;
        if( quantityByHeaderId == null ){ quantityByHeaderId = new map<Id, Decimal>(); }
        
        if( allocatedQty != null ){
            allocatedQtyMap = allocatedQty.clone();
        }
        
        for ( SObject header : headerList ) {
            
            Decimal quantityToDistribute;
            Decimal totalByItemLocation = 0;
            Decimal conversionFactor = 1.0;
            
            if( quantityToDistributeByHeaderId != null && quantityToDistributeByHeaderId.containsKey(header.id)){
                quantityToDistribute = quantityToDistributeByHeaderId.get( header.id );
            }
            
            if( convertUOM )
            {
                if(header.getSObjectType()==Sales_Order_Line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_From_Stock__c'),(decimal)header.get('Quantity_Ordered__c'));//KSE.getConversionFactor(header);
                else if(header.getSObjectType()==Purchase_Order_Line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_To_Stock__c'),(decimal)header.get('order_quantity__c'));//KSE.getConversionFactor(header);
                else if(header.getSObjectType()==Receipt_Line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.getsObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)header.getsObject('Purchase_Order_Line__r').get('order_quantity__c'));//KSE.getConversionFactor(header);
                else if (header.getSObjectType()==Shipment_line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactor(header);
                
            
            }
            
            for( SKID__c qtySkid : quantitySkidsByHeader.get( header.id ) ){

                calculateQuantityAvailable( qtySkid, quantityBySkid, allocatedQtyMap, availableField, conversionFactor );
                
                totalByItemLocation += (Decimal)qtySkid.get(availableField); // distributeV2 uses toIssueField and is in the below if loop
                
                qtySkid.put(toIssueField, 0); 

                if( quantityToDistribute > 0 ){
                    if( !distribute || Math.min( quantityBySkid.get(qtySkid.id) , quantityToDistribute) <= 0 )  
                        qtySkid.put(toIssueField, 0);
                    else
                        qtySkid.put(toIssueField, Math.min( quantityBySkid.get(qtySkid.id) , quantityToDistribute).setScale(6)); //PTM-423 Rounding issue on additional pages                 
                    
                    quantityToDistribute -= (Decimal)qtySkid.get( toIssueField );
                    
                    quantityBySkid.put( qtySkid.Id, quantityBySkid.get(qtySkid.id) - (Decimal)qtySkid.get( toIssueField )); //qtySkid.Quantity_to_Issue__c
                    
                } 
            }
                
                 
            quantityByHeaderId.put( header.id, totalByItemLocation );
            
            if( quantityToDistributeByHeaderId!= null && quantityByHeaderId.get( header.id ) < quantityToDistributeByHeaderId.get( header.id ).setscale(6)){
                
                if( processName != 'Allocate' && processName !='Complete' && processName != 'Kit' ){
                    ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error, 
                                                        'Not enough quantity for : '+itemNameMap.get(header.id) + ',' +quantityByHeaderId.get( header.id ) +','+ quantityToDistributeByHeaderId.get( header.id ).setscale(6)) );
                    return;
                }
                else if(fromVisualforce){
                    ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Warning, 
                                                        'Not enough quantity for : '+itemNameMap.get(header.id) + ',' +quantityByHeaderId.get( header.id ) +','+ quantityToDistributeByHeaderId.get( header.id ).setscale(6)) );
                }
                else if (errorMsgs != null){
                    System.debug(logginglevel.info, 'Not enough qty to distribute: ' );
                    if (!errorMsgs.containsKey(header.id)){
                        errorMsgs.put(header.id, new List<String>());
                    }
                    errorMsgs.get(header.id).add('Not enough quantity for ' + itemNameMap.get(header.id) + 
                                ': ' + quantityByHeaderId.get( header.id ) +
                                ' / ' + quantityToDistributeByHeaderId.get( header.id ).setscale(6) ) ;
                }
            }
        }
    }

    public static void distribute(  List <Sobject> headerList, 
                                    Map <Id, List<SKID__c>> quantitySkidsByHeader, 
                                    Map <Id, decimal> quantityToDistributeByHeaderId,
                                    Map <Id, Decimal> quantityByHeaderId, 
                                    Map <Id, String> itemNameMap, 
                                    Boolean distribute, 
                                    String availableField, 
                                    String toIssueField,                         
                                    String processName, 
                                    Map<String, Decimal> allocatedQty, 
                                    Boolean convertUOM  ){
       
        distributeV2(headerList, quantitySkidsByHeader, quantityToDistributeByHeaderId, quantityByHeaderId, itemNameMap, distribute, availableField, toIssueField, processName, allocatedQty, convertUOM, null);
    }

    public static void populateQuantitySkidsByHeader(   List<SObject> headers, 
                                                        Integer index, 
                                                        Map<Id, List<SKID__c>> quantitySkidsByHeader,
                                                        Map<Id, List<Location__c>> locationsByHeader, 
                                                        Map<Id, Integer> locationIndexByHeader, 
                                                        Map<Id, Boolean> locationButtonDisabled, 
                                                        Map<String,List<SKID__c>> quantitySkidsByItemLocation){
        
        for( SObject header: headers ){
            List<SKID__c> qtySKIDs = new list<SKID__c>();
            Id itemId;

            if (header.getSObjectType() == Sales_Order_Line__c.sObjectType || header.getSObjectType() == Shipment_Line__c.sObjectType)
                itemId = (Id)header.getSObject('Product__r').get('Item__c');
            else 
            	itemId = (Id)header.get('Item__c');

            if (locationIndexByHeader != null && locationButtonDisabled != null){
                
                locationButtonDisabled.put( header.id, true );
                                   
                if( locationsByHeader.containsKey( header.id) && locationsByHeader.get(header.id).size() > index ){
                    qtySKIDs = ( quantitySkidsByItemLocation.get( itemId+','+locationsByHeader.get( header.id )[index].id)) ;
                    locationIndexByHeader.put( header.id, index );
                    
                    if( locationsByHeader.get( header.id ).size() > index+1 )
                        locationButtonDisabled.put( header.id, false );
                    else
                        locationButtonDisabled.put( header.id, true );
                }
                
            } else if (locationsByHeader.get( (Id) header.get('Sales_order_line__c') ) != null && header.getSObjectType()==Shipment_Line__c.sObjectType) {
                
                List <Location__c> shlLocations = locationsByHeader.get( (Id) header.get('Sales_order_line__c') );
                                       
                Decimal qtyOrder = KSE.subtractDecimals( (Decimal) header.get('Quantity_planned__c'), KSE.addQuantityToField( (Decimal) header.get('Quantity_Allocated__c'), (Decimal) header.get('Quantity_Picked__c') ));
                //index = 0;
                
                //while (qtyOrder > 0 && index < shlLocations.size()){
                for (location__c loc : shlLocations){

                    //Id locId = shlLocations[index].id;
                    
                    String key = itemId + ',' + loc.id;        
                    
                    if (quantitySkidsByItemLocation.containsKey( key )){
                        System.debug(logginglevel.info, 'quantitySkidsByItemLocation.get( key ): ' + quantitySkidsByItemLocation.get( key ));
                        for (Skid__c skid : quantitySkidsByItemLocation.get( key )){
                            System.debug(logginglevel.info, 'skid: ' + skid);
                            qtyOrder -= skid.Quantity_Available__c;
                            qtySKIDs.add(skid);    
                            if (qtyOrder < 0) break;
                        }
                    }
                    if (qtyOrder < 0) break;
                    //index ++;        
                }
            }

            if(!quantitySkidsByHeader.containsKey(header.id) )
                quantitySkidsByHeader.put( header.Id, new list<SKID__c>());
            
            if( qtySkids != null )
                quantitySkidsByHeader.get( header.Id).addAll( qtySKIDs.deepClone( true, true, true ) );
            
        }
    }
    
    // 
    // KNDY-6735 the skid quantity may have changed since we pulled the original query
    // re-fetch these skids, lock them for update
    // and load the latest quantity into the skid map lists passed in
    // 
    public static void reFetchSkidsForUpdate( Map<Id, List<SKID__c>> quantitySkidsByHeader, list<SObject> headers ) {
        set<Id> skidIdSet=new Set<Id>();
        for ( id headerId : quantitySkidsByHeader.keySet() )   { 
            skidIdSet.addAll( KSE.grepIdSetFromList( quantitySkidsByHeader.get( headerId ) ));            
        }
        
        // query and hold FOR UPDATE, zero skids are deleted by now
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Skid__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Quantity__c', 'Item__r.Packaging_UOM__c'
		});
		soql.setWhereClause('id in :skidIdSet for update');
		
		Map<Id,Skid__c> nonZeroSkids=new Map<Id,Skid__c>((List<Skid__c>)Database.query(soql.getQuery()));
        
        for(Skid__c sk: nonZeroSkids.values() ) {            
            for(id headerId: quantitySkidsByHeader.keyset()) {
                for(skid__c skds: quantitySkidsByHeader.get(headerId)) {   
                    if(sk.Id==skds.Id) {
                        skds.Quantity__c = sk.Quantity__c; // put the actual DB quantity into the map list passed in
                        skidIdSet.remove(sk.Id);
                    }
                }
            }
        }
        
        // discover if we have a skid in our map list which was actually deleted since we fetched
        Set<Id> zeroSkids=new Set<Id>();
        if(skidIdSet.size() >0)
        	zeroSkids.addall(skidIdSet);   //PTM-573     

        if ( zeroSkids.size() == 0 ) return;
        
		// finaly throw if we have a deleted skid in memory
        for(sObject thisobj:headers) {
        	Id headerId = null;
        	String name = '';
        	
        	if(thisobj != null){
        		headerId = (Id)thisobj.get('Id');
        		if(thisobj.get('Name') != null){
        			name = (String)thisobj.get('Name') + ':';
        	    }
        		
        	}
            for(skid__c skds: quantitySkidsByHeader.get(headerId) ){
                if(zeroSkids.contains(skds.Id)) {
                    throw new SkidService2Exception(
                     (String.isBlank(name) == false?name:'')+Label.Skid_is_completedly_consumed);
                    //skds.Id=null;
                    //skds.Quantity__c = 0;
                }
            }
        }       
    }


    public static void inventoryTransactionForPullFrom( List<SObject> headers, 
                                                        Map<Id, List<SKID__c>> quantitySkidsByHeader, 
                                                        String type, 
                                                        List<String> attributeFields, 
                                                        String action,  
                                                        String inputField, 
                                                        Map< String, SKID__c> fromToSkidMap, 
                                                        Boolean convertUOM, 
                                                        Map<Id,SObject> sobjects)
    {
        inventoryTransactionForPullFrom(headers,quantitySkidsByHeader,type,attributeFields,action,inputField,fromToSkidMap,convertUOM,sobjects,null,null,null,null);

    }
    public static void inventoryTransactionForPullFrom( List<SObject> headers, 
                                                        Map<Id, List<SKID__c>> quantitySkidsByHeader, 
                                                        String type, 
                                                        List<String> attributeFields, 
                                                        String action,  
                                                        String inputField, 
                                                        Map< String, SKID__c> fromToSkidMap, 
                                                        Boolean convertUOM, 
                                                        Map<Id,SObject> sobjects,
                                                        Map<Id, List<sObject>> sObjectListMap )
    {
    	inventoryTransactionForPullFrom(headers,quantitySkidsByHeader,type,attributeFields,action,inputField,fromToSkidMap,convertUOM,sobjects,sObjectListMap,null,null,null);
    }
    public static void inventoryTransactionForPullFrom( List<SObject> headers, 
                                                        Map<Id, List<SKID__c>> quantitySkidsByHeader, 
                                                        String type, 
                                                        List<String> attributeFields, 
                                                        String action,  
                                                        String inputField, 
                                                        Map< String, SKID__c> fromToSkidMap, 
                                                        Boolean convertUOM, 
                                                        Map<Id,SObject> sobjects,
                                                		Map<Id,String> icTypes,
                                                		Map<Id,Inventory_Change__c> existingICs )
    {
    	inventoryTransactionForPullFrom(headers,quantitySkidsByHeader,type,attributeFields,action,inputField,fromToSkidMap,convertUOM,sobjects,null,icTypes,existingICs,null);
    }
    public static void inventoryTransactionForPullFrom( List<SObject> headers, 
                                                        Map<Id, List<SKID__c>> quantitySkidsByHeader, 
                                                        String type, 
                                                        List<String> attributeFields, 
                                                        String action,  
                                                        String inputField, 
                                                        Map< String, SKID__c> fromToSkidMap, 
                                                        Boolean convertUOM, 
                                                        Map<Id,SObject> sobjects,
                                                        Map<Id, List<sObject>> sObjectListMap,
                                                		Map<Id,String> icTypes,
                                                		Map<Id,Inventory_Change__c> existingICs )
    {  
    	inventoryTransactionForPullFrom(headers,quantitySkidsByHeader,type,attributeFields,action,inputField,fromToSkidMap,convertUOM,sobjects,sObjectListMap,icTypes,existingICs,null);
    }
    public static void inventoryTransactionForPullFrom( List<SObject> headers, 
                                                        Map<Id, List<SKID__c>> quantitySkidsByHeader, 
                                                        String type, 
                                                        List<String> attributeFields, 
                                                        String action,  
                                                        String inputField, 
                                                        Map< String, SKID__c> fromToSkidMap, 
                                                        Boolean convertUOM, 
                                                        Map<Id,SObject> sobjects,
                                                        Map<Id, List<sObject>> sObjectListMap,
                                                		Map<Id,String> icTypes,
                                                		Map<Id,Inventory_Change__c> existingICs,
                                                		Map<Id,Boolean> createICs )
    {              
        map<Id, SKID__c> skidsToDelete = new map<Id, SKID__c>();
        map<Id,SKID__c> skidsToUpdate = new map<Id, SKID__c>();     
        Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
        Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
        List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
        map<Id, Decimal> quantityConsumedPerPOLine = new map< Id, Decimal>(); 
        Map<Id, Sales_Order_Line__c> salesOrderLinesMap = new Map<Id, Sales_Order_Line__c>();
        
        //KNDY-6735
        reFetchSkidsForUpdate( quantitySkidsByHeader, headers );        
                                    
        Set<Id> parentSOLIds = new Set<Id>();

        for (sObject header:headers) {   // update records
            
            Decimal conversionFactor = 1.0;
            
            if( convertUOM )
            {
                if(header.getSObjectType()==Sales_Order_Line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_From_Stock__c'),(decimal)header.get('Quantity_Ordered__c'));//KSE.getConversionFactor(header);
                else if(header.getSObjectType()==Purchase_Order_Line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_To_Stock__c'),(decimal)header.get('order_quantity__c'));//KSE.getConversionFactor(header);
                else if(header.getSObjectType()==Receipt_Line__c.sObjectType)
                    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.getsObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)header.getsObject('Purchase_Order_Line__r').get('order_quantity__c'));//KSE.getConversionFactor(header);
                else if (header.getSObjectType()==Shipment_line__c.sObjectType)
                     conversionFactor = KSE.getConversionFactor(header);
                
            
            }

            if (header.getSObjectType() == Shipment_Line__c.sObjectType){

                if (!salesOrderLinesMap.containsKey( (Id) header.get('Sales_Order_Line__c') )) {
             		Sales_Order_Line__c soli=       new Sales_Order_Line__c(
                        Id = (Id) header.get('Sales_Order_Line__c'),
                        Quantity_Ordered__c = (Decimal) header.getsObject('Sales_Order_Line__r').get('Quantity_Ordered__c'),
                        Quantity_Allocated__c = (Decimal) header.getsObject('Sales_Order_Line__r').get('Quantity_Allocated__c'),
                        Quantity_Shipped__c = (Decimal) header.getsObject('Sales_Order_Line__r').get('Quantity_Shipped__c')
                    );
                    salesOrderLinesMap.put( (Id) header.get('Sales_Order_Line__c'), soli);
                } 

                if( type == 'Sales Order Pick' || type == 'Sales Order Allocation' ){
                    for (skid__c skid : (List<Skid__c>) sObjectListMap.get(header.id)){
                        skidsToUpdate.put(skid.id, skid);
                    }
                }
            } 

            if (quantitySkidsByHeader.containsKey(header.Id)) {
                for (SKID__c qtySkid:quantitySkidsByHeader.get(header.Id)) {
                   //Modified the condition to allow '0' as Count Qty on Cycle Count Page as per PTM#71 and also doesn't allow 0 Qty IT for  Inventory Change         
                    if (qtySkid.get(inputField) == null || ((Decimal)qtySkid.get(inputField) < 0) && (type != 'Adjustment') && (type != 'Cycle Count') || ((Decimal)qtySkid.get(inputField) == 0 && (type != 'Cycle Count')) ){
                        continue;
                    }
                    
                    String qtySkidKey;
                    
                    if (type == 'Work Order Component Issue') {
                        header.put('Quantity_Issued__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Issued__c'),qtySkid.Quantity_To_Issue__c));
                        if (action == 'Complete')
                            header.put('Quantity_Used__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Used__c'),qtySkid.Quantity_To_Issue__c));    
                    } else if (type == 'Work Order Component Scrap') {
                        header.put('Quantity_Scrapped__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Scrapped__c'),qtySkid.Quantity_To_Scrap__c));
                    } else if (type == 'Work Order Issue From WIP') {
                        header.put('Quantity_Used__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Used__c'),qtySkid.Quantity_To_Issue__c));
                    } else if (type == 'By-product Uncompletion') {
                        header.put('Quantity_Completed__c',KSE.subtractDecimals((Decimal)header.get('Quantity_Completed__c'),qtySkid.Quantity_To_Return__c));
                    }
                    
                    SKID__c fromSkid = qtySkid;
                    if (qtySkid.Quantity__c != null) {    
                        Inventory_Transaction__c invTrans;
                        if (type == 'Work Order Component Issue' && action != 'Complete') {
                            qtySkidKey = generateKeyForSkid(qtySkid,attributeFields,null,null) + ',' + header.Id;
                            List<String> tempAttributes = attributeFields.clone();
                            tempAttributes.add('Material_Tracking__c');
                            SKID__c toSkid = fromToSkidMap.get(qtySkidKey);
                            Decimal quantity = toSkid == null ? qtySkid.Quantity__c : toSkid.Quantity__c;
                            
                            //invTrans = createIT(qtySkid,qtySkid.Item__c,type,null,null,null,(Id)header.getSObject('Work_Order__r').get('Default_WIP_Location__c'),fromToSkidMap.get(qtySkidKey),tempAttributes);
                            invTrans = SkidService3.createInventoryTransaction(header, type, quantity, qtySkid, toSkid, tempAttributes);
                        } else if (type == 'Work Order Component Scrap') {
                            qtySkidKey = generateKeyForSkid(qtySkid,attributeFields,null,null) + ',' + header.Id;
                            SKID__c toSkid = fromToSkidMap.get(qtySkidKey);
                            Decimal quantity = toSkid == null ? qtySkid.Quantity__c : toSkid.Quantity__c;
                            
                            //invTrans = createIT(qtySkid,qtySkid.Item__c,type,null,null,null,(Id)header.getSObject('Work_Order__r').get('MRB_Location__c'),fromToSkidMap.get(qtySkidKey),attributeFields);
                            invTrans = SkidService3.createInventoryTransaction(header, type, quantity, qtySkid, toSkid, attributeFields);
                            //invTrans.Material_Tracking__c = header.Id;
                        } else if (type == 'Work Order Component Issue' && action == 'Complete') {
                            SKID__c toSkid = qtySkid.clone(false,true);
                            toSkid.Location__c = (Id)header.getSObject('Work_Order__r').get('Default_WIP_Location__c');
                            toSkid.Location__r = (Location__c)header.getSObject('Work_Order__r').getSObject('Default_WIP_Location__r');
                            toSkid.Bin__c = null;
                            Decimal quantity = toSkid == null ? qtySkid.Quantity__c : toSkid.Quantity__c;
                            
                            //invTrans = createIT(qtySkid,qtySkid.Item__c,type,null,null,null,(Id)header.getSObject('Work_Order__r').get('Default_WIP_Location__c'),toSkid,attributeFields);
                            invTrans = SkidService3.createInventoryTransaction(header, type, quantity, qtySkid, toSkid, attributeFields);
                        	invTrans.Material_Tracking__c = header.Id;
                        } else if (type == 'Work Order Issue From WIP') {
                            qtySkidKey = generateKeyForSkid(qtySkid,attributeFields,null,null);
                            SKID__c toSkid = fromToSkidMap.get(qtySkidKey);
                            Decimal quantity = toSkid == null ? qtySkid.Quantity__c : toSkid.Quantity__c;
                            
                            //invTrans = createIT(qtySkid,qtySkid.Item__c,type,null,null,null,(Id)fromToSkidMap.get(qtySkidKey).Location__c,fromToSkidMap.get(qtySkidKey),attributeFields);
                            invTrans = SkidService3.createInventoryTransaction(header, type, quantity, qtySkid, toSkid, attributeFields);
                            //invTrans.Material_Tracking__c = header.Id;
                        } else if (type == 'By-product Uncompletion') {
                        	Decimal quantity = qtySkid.Quantity__c;
                        	
                            //invTrans = createIT(qtySkid,qtySkid.Item__c,type,null,null,null,null,null,null); 
                            invTrans = SkidService3.createInventoryTransaction(header, type, quantity, qtySkid, null, null);
                            //invTrans.Material_Tracking__c = header.Id;
                        } else if( type == 'Sales Order Allocation Temp'){
                            list<SKID__c> demandSkid = (sobjects == null) ? (list<SKID__c>) header.getSObjects('SKIDs__r') : new list<SKID__c>{(SKID__c)sobjects.get(header.id)}; 
                            fromSkid = demandSkid[0];   
                            
                            SKID__c toSkid = (SKID__c)fromToSkidMap.get(qtySkidKey);
                            Decimal quantity = toSkid == null ? fromSkid.Quantity__c : toSkid.Quantity__c;
                            
                            qtySkidKey = generateKeyForSkid( qtySkid, attributeFields, null, null );
                            
                            if (header.getSObjectType()==Shipment_Line__c.sObjectType){
                                qtySkidKey += fromSkid.Sales_Order_Line__c;
                            } else {
                                qtySkidKey += header.id;
                            }
                            
                            //invTrans = createIT( demandSkid[0], qtySkid.Item__c , type , null , null, null, (Id)fromToSkidMap.get(qtySkidKey).get('Location__c'), (SKID__c)fromToSkidMap.get(qtySkidKey), AttributeFields );
                            invTrans = SkidService3.createInventoryTransaction( header, type, quantity, fromSkid, toSkid, attributeFields );
                                                        
                            if (header.getSObjectType()==Shipment_Line__c.sObjectType){
                                salesOrderLinesMap.get( (Id) header.get('Sales_Order_Line__c') ).Quantity_Allocated__c = KSE.addQuantityToField( salesOrderLinesMap.get( (Id) header.get('Sales_Order_Line__c') ).Quantity_Allocated__c, qtySkid.Quantity_Allocated__c);
                            } 
                            header.put('Quantity_Allocated__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Allocated__c'), (Decimal)qtySkid.get(inputField)));  
                                                     
                        }
                        else if( type == 'Transfer Of Ownership' || type == 'Transfer' || type == 'Adjustment' || type == 'Cycle Count'){
                            if( sobjects != null && sobjects.containsKey(header.id) && sobjects.get(header.id) != null ){
                                qtySkidKey = generateKeyForSkid( qtySkid, null, type, sobjects.get(header.id) );
                            }
                            else if ( sobjects == null && qtySkid.Temporary_Value_Holder__c != null ) {
                                String tmpToSkidAttr = qtySkid.Temporary_Value_Holder__c ;
                                String toLocation = tmpToSkidAttr.substring( 0 , tmpToSkidAttr.indexOf (',') ) ;
                                String toBin = tmpToSkidAttr.substring( tmpToSkidAttr.indexOf (',')+1 , tmpToSkidAttr.length()  ) ;
                                
                                SKID__c toSkid = qtySkid.clone( false, true );
                                toSkid.Primary_Key_At_Location__c = null; // nulling out any primary key that the old skid data has before using it in the putaway service.
                                toSkid.quantity__c = (Decimal)qtySkid.get( inputField ) * conversionFactor;
                                
                                toSkid.Location__c =( toLocation =='null' || toLocation == '' )?null:toLocation;
                                toSkid.Bin__c = (toBin =='null' || toBin == '')?null:toBin;
                                qtySkidKey = generateKeyForSkid( qtySkid, null, type, toSkid );
                            }
                            else{
                                qtySkidKey = generateKeyForSkid( qtySkid, null, type, null );   
                            }
                            //PTM-214 Cycle Count not creating Inventory Transactions.
                            if(type == 'Cycle Count' || type == 'Adjustment')   //PTM-465
                                qtySkid.Quantity__c = fromToSkidMap.get(qtySkidKey).Quantity__c;                            
                            
                            SKID__c toSkid = (SKID__c)fromToSkidMap.get(qtySkidKey);
                            Decimal quantity = toSkid == null ? qtySkid.Quantity__c : toSkid.Quantity__c;
                            
                            //invTrans = createIT( qtySkid, qtySkid.Item__c , type , null , null, header.id, (Id)fromToSkidMap.get(qtySkidKey).get('Location__c'), (SKID__c)fromToSkidMap.get(qtySkidKey), AttributeFields );
                            invTrans = SkidService3.createInventoryTransaction( header, type, quantity, qtySkid, toSkid, attributeFields );
                        }
                        else{
                            qtySkidKey = generateKeyForSkid( qtySkid, attributeFields, null, null );
                            
                            if( type == 'Transfer Order Shipment'){
                                SKID__c locSkid = new SKID__c( Location__c = (Id)header.get('Deliver_To_Location__c'), Bin__c = null );
                                qtySkidKey = generateKeyForSkid( qtySkid, attributeFields, type, locSkid ); 
                            }
                            
                            if( fromToSkidMap != null ){
                            	SKID__c toSkid = (SKID__c)fromToSkidMap.get(qtySkidKey);
                            	Decimal quantity = toSkid == null ? qtySkid.Quantity__c : toSkid.Quantity__c;
                            
	                        	//invTrans = createIT( qtySkid, qtySkid.Item__c , type , null , null, null, (Id)fromToSkidMap.get(qtySkidKey).get('Location__c'), (SKID__c)fromToSkidMap.get(qtySkidKey), AttributeFields );
	                        	invTrans = SkidService3.createInventoryTransaction( header, type, quantity, qtySkid, toSkid, attributeFields );
                            }
	                        else{
	                        	//invTrans = createIT( qtySkid, qtySkid.Item__c , type , null , null, null, null, null, AttributeFields );       
	                        	invTrans = SkidService3.createInventoryTransaction( header, type, qtySkid.Quantity__c, qtySkid, null, attributeFields );            
	                        }         
	                    }
	                    
	                    invTrans.Quantity__c = ((Decimal)qtySkid.get(inputField) * conversionFactor).setscale(6,System.RoundingMode.HALF_UP);

	                    if( type=='Sales Order Pick' || type == 'Sales Order Allocation' || type=='Transfer Order Allocation' || type == 'Transfer Order Pick'  ){
                            if (header.getSObjectType()==Shipment_Line__c.sObjectType){
                                invTrans.Sales_Order_Line__c = (Id) header.get('Sales_Order_Line__c');
                                invTrans.Shipment_Line__c = header.id;
 
                                header.put('Quantity_Picked__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Picked__c'), invTrans.Quantity__c));  
                                header.put('Quantity_Allocated__c',KSE.subtractDecimals((Decimal)header.get('Quantity_Allocated__c'), invTrans.Quantity__c));  
                            }
 
                            else {

                                list<SKID__c> allocatedSkid = (sobjects == null) ? (list<SKID__c>) header.getSObjects('SKIDs__r') : new list<SKID__c>{(SKID__c)sobjects.get(header.id)}; 
                                if( allocatedSkid[0].Sales_Order_Line__c != null )
                                   invTrans.Sales_Order_Line__c = allocatedSkid[0].Sales_Order_Line__c;
                                else
                                    invTrans.Order_Line__c = allocatedSkid[0].Order_Line__c;
                                invTrans.shipment_Line__c = allocatedSkid[0].shipment_Line__c;
                            }
                        } 
                        
                        if( type == 'Sales Order Shipment' || type == 'Transfer Order Shipment'){
                            
                            invTrans.Sales_Order_Line__c = qtySkid.Sales_Order_Line__c;
                            invTrans.Order_Line__c = qtySkid.Order_Line__c;
                            invTrans.shipment_Line__c = qtySkid.shipment_Line__c;
                            
                            if( type == 'Sales Order Shipment' ){
                                copyToSkidAttributesToIT( invTrans, qtySkid, AttributeFields );
                                invTrans.To_Facility__c = null;
                                invTrans.To_Location__c = null;
                                invTrans.To_SKID__c = null;
                                invTrans.To_Skid__r = null;
                            }
                            qtySkid.Sales_Order_Line__c = null;
                            qtySkid.Order_Line__c = null;
                            qtySkid.shipment_Line__c = null;

                            if (header.getSObjectType() == Shipment_Line__c.sObjectType){
 
                                header.put('Quantity_Picked__c',KSE.subtractDecimals((Decimal)header.get('Quantity_Picked__c'), (Decimal)qtySkid.get(inputField)) );  
                                    
                                salesOrderLinesMap.get( (Id)header.get('Sales_Order_Line__c') ).Quantity_Shipped__c = KSE.addQuantityToField( salesOrderLinesMap.get( (Id) header.get('Sales_Order_Line__c') ).Quantity_Shipped__c,  (Decimal)qtySkid.get(inputField) );
                                salesOrderLinesMap.get( (Id)header.get('Sales_Order_Line__c') ).Quantity_Allocated__c = KSE.subtractDecimals( salesOrderLinesMap.get( (Id) header.get('Sales_Order_Line__c') ).Quantity_Allocated__c,  (Decimal)qtySkid.get(inputField) );
                                
                            } else {
    	                        header.put('Quantity_Allocated__c',KSE.subtractDecimals((Decimal)header.get('Quantity_Allocated__c'), (Decimal)qtySkid.get(inputField)));
                            }

                            header.put('Quantity_Shipped__c',KSE.addQuantityToField((Decimal)header.get('Quantity_Shipped__c'), (Decimal)qtySkid.get(inputField))); 
                            
	                    }
	                    if( type =='Purchase Order Return'){
	                        invTrans.Purchase_Order_Line__c = (Id)header.get('Purchase_Order_Line__c');
	                        invTrans.Receipt_Line__c = header.id;
	                        invTrans.Item__c = (Id)header.get('Item__c');
	                        header.put( 'Quantity_Actually_Returned__c', ((KSE.addQuantityToField((((Decimal)header.get('Quantity_Actually_Returned__c')) * conversionFactor),invTrans.Quantity__c ))).setscale(6,System.RoundingMode.HALF_UP));
	                        header.put( 'Quantity_to_stock__c', ((Decimal)header.get('Quantity_Actually_Returned__c') / conversionfactor).setscale(6,System.RoundingMode.HALF_UP));
	                    }
	                    if( fromSkid.Id != invTrans.To_Skid__c && ( type != 'Adjustment' && type != 'Cycle Count')  ){
		                    if( skidsToUpdate.containsKey( fromSkid.id ))
		                        fromSkid.Quantity__c = skidsToUpdate.get( fromSkid.id ).Quantity__c;
		                        
		                    fromSkid.Quantity__c -= ((Decimal)qtySkid.get(inputField)* conversionFactor).setscale(6,System.RoundingMode.HALF_UP);
		                    
		                    
		                    skidsToUpdate.put( fromSkid.id, fromSkid.clone(true, true) ); // update the skids we have modified 
		                    //if( fromSkid.id != qtySkid.id )
		                     //   skidsToUpdate.put( qtySkid.id, qtySkid.clone(true, true) );
	                    }

	                    if( invTrans.From_Skid__c != null && invTrans.From_Skid__r.Quantity__c == 0 && (!skidsToUpdate.containsKey(invTrans.From_Skid__c)) && (!doNotDeleteSkidTypes.contains( invTrans.From_Skid__r.Type__c )) )
	                  	 	skidsToUpdate.put( invTrans.From_Skid__c, invTrans.From_Skid__r);
	                    if( invTrans.To_Skid__c != null && invTrans.To_Skid__r.Quantity__c == 0 && (!skidsToUpdate.containsKey(invTrans.To_Skid__c)) && (!doNotDeleteSkidTypes.contains( invTrans.To_Skid__r.Type__c )))
	                    	skidsToUpdate.put( invTrans.To_Skid__c, invTrans.To_Skid__r);
	                    
	                    if( type == 'Adjustment'){
	                    	
	                    	if( invTrans.Quantity__c > 0 )
	                    		invTrans.Type__c = 'Adjustment Increase';
	                    	else
	                    		invTrans.Type__c = 'Adjustment Decrease';	
	                    }
	                    List<Inventory_Transaction__c> newITs = new List<Inventory_Transaction__c>();
	                    if( invTrans.From_SKID__r.Consigned_Owner__c != null && type != 'Transfer' && type != 'Purchase Order Return' ){
	                       
	                        Inventory_Transaction__c itTransfer = invTrans.clone( false, true );
	                        itTransfer.Type__c = 'Transfer Of Ownership';
	                        itTransfer.Consigned_Owner__c = invTrans.From_SKID__r.Consigned_Owner__c;
	                        itTransfer.Purchase_Order_Line__c = invTrans.From_SKID__r.Purchase_Order_Line__c;
	                        itTransfer.From_SKID__r = null;
           					itTransfer.To_SKID__r = null;
	                        newITs.add( itTransfer );
	                        if( !quantityConsumedPerPOLine.containsKey(itTransfer.Purchase_Order_Line__c ))
	                            quantityConsumedPerPOLine.put( itTransfer.Purchase_Order_Line__c, itTransfer.Quantity__c );
	                        else
	                            quantityConsumedPerPOLine.put( itTransfer.Purchase_Order_Line__c, 
	                                                        quantityConsumedPerPOLine.get(itTransfer.Purchase_Order_Line__c) + itTransfer.Quantity__c );    
	                    }
	                    if(type != 'Transfer Of Ownership') {
                            invTrans.From_SKID__r = null;
                            invTrans.To_SKID__r = null;
                            newITs.add(invTrans);
                        }
                        if (type == InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT){
                            Inventory_Transaction__c itSO = invTrans.clone(true, true);
                            itSO.From_Facility__c = invTrans.To_Facility__c;
                            itSO.From_Location__c = invTrans.To_Location__c;
                            itSO.To_Facility__c = invTrans.From_Facility__c;
                            itSO.To_Location__c = invTrans.From_Location__c;
                            itSO.Type__c = InventoryTransactionService.LOGICAL_SALES_ORDER_SHIPMENT;
                            newITs.add(itSO);
                        }
                        itList.addAll(newITs);
                        
                        if (itGroupingFields.containsKey(header.getSObjectType())) {
                            Id sourceDocId = (Id)header.get(itGroupingFields.get(header.getSObjectType()));
                            
                            //sourceDoc is just a placeholder. The only time the type of object matters is if it's a work order
                            sObject sourceDoc;
                            if (header.getSObjectType() == Order_Line__c.sObjectType) {
                                sourceDoc = new Sales_Order__c(Company__c = (Id)header.get('Shipping_Company__c'), Currency__c = (Id)header.getSObject('Order__r').getSObject('Shipping_Company__r').get('Comp_Currency__c'));
                            } else if (header.getSObjectType() == Sales_Order_Line__c.sObjectType) {
                                sourceDoc = new Sales_Order__c(Company__c = (Id)header.get('Company__c'), Currency__c = (Id)header.getSObject('Sales_Order__r').getSObject('Company__r').get('Comp_Currency__c'));
                            } else if (header.getSObjectType() == Material_Tracking__c.sObjectType) {
                                sourceDoc = new Work_Order__c(Company__c = (Id)header.getSObject('Work_Order__r').get('Company__c'), Currency__c = (Id)header.getSObject('Work_Order__r').get('Currency__c'));
                            } else {
                                sourceDoc = new Sales_Order__c(Company__c = (Id)header.get('Company__c'), Currency__c = (Id)header.get('Currency__c'));
                            }
                            if (createICs == null || !createICs.containsKey(header.Id) || createICs.get(header.Id))
                            	sourceDocs.put(sourceDocId,sourceDoc);
                            if (!itMap.containsKey(sourceDocId))
                                itMap.put(sourceDocId,new List<Inventory_Transaction__c>());
                            itMap.get(sourceDocId).addAll(newITs);
                        }
                    }
                }
            }

            if ( header.getSObjectType() == Shipment_Line__c.getSObjectType() && type == 'Sales Order Shipment' ) {
                if (( (Shipment_line__c) header).Sales_Order_Line__r.Parent_Sales_Order_Line__c != null ) {
                    parentSOLIds.add( ( (Shipment_line__c) header).Sales_Order_Line__r.Parent_Sales_Order_Line__c);
                }
            }
        }
        if (type == 'Sales Order Shipment' ){
            if (!parentSOLIds.isEmpty()){
                SalesOrderLineService.createFulfillmentForParentSOLs(parentSOLIds, (List<Shipment_Line__c>) headers);
            }
        }

        for (Id skidId:skidsToUpdate.keySet()) {
            skidsToUpdate.get(skidId).put(inputField,0);
            if ((skidsToUpdate.get(skidId).Quantity__c == 0 && !doNotDeleteSkidTypes.contains(skidsToUpdate.get(skidId).Type__c)) || (skidsToUpdate.get(skidId).Quantity__c < 0 && deleteSkidTypesIfNegative.contains(skidsToUpdate.get(skidId).Type__c))) {    
                skidsToDelete.put(skidId,skidsToUpdate.get(skidId));
                skidsToUpdate.remove(skidId);
            } 
        }
        
        Map<Id,Inventory_Change__c> icMap = generateICsForITs(sourceDocs,itMap,icTypes,existingICs);
        if (type != 'Sales Order Allocation Temp') {
            updateReceiptLinesOnConsumption(quantityConsumedPerPOLine);
            DML.insertAsSystem(itList);
        }
        if (existingICs == null)
            DML.updateAsSystem(icMap.values());
        else
            existingICs.putAll(icMap);
            DML.updateAsSystem(skidsToUpdate.values());
        if (type != 'Transfer Of Ownership') {
            if (headers.size() > 0 && headers[0].getSObjectType() == Shipment_Line__c.sObjectType)
                DML.updateAsUser(salesOrderLinesMap.values());
            DML.updateAsUser(headers);
        }
        DML.deleteAsSystem(skidsToDelete.values());
    }
    
    public static Map<Id,Inventory_Change__c> generateICsForITs(Map<Id,sObject> sourceDocs,Map<Id,List<Inventory_Transaction__c>> itMap,Map<Id,String> icTypes,Map<Id,Inventory_Change__c> existingICs) {
        Map<Id,Inventory_Change__c> icMap = new Map<Id,Inventory_Change__c>();
        List<Inventory_Change__c> icsToInsert = new List<Inventory_Change__c>();
        
        if (sourceDocs == null || itMap == null)
            return icMap;
        
        for (Id sourceDocId:sourceDocs.keySet()) {
            sObject sourceDoc = sourceDocs.get(sourceDocId);
            List<Inventory_Transaction__c> itList = itMap.get(sourceDocId);
            
            if (sourceDoc == null || sourceDoc.get('Company__c') == null || itList == null || itList.size() == 0)
                continue;
                
            String type;
            if (icTypes != null && icTypes.containsKey(sourceDocId))
                type = icTypes.get(sourceDocId);
            else
                for (Inventory_Transaction__c it:itList)
                    if (it.Type__c != null && !excludeITTypesForIC.contains(it.Type__c) && (type == null || (type == 'Transfer Of Ownership' && it.Type__c != 'Transfer Of Ownership')))
                        type = it.Type__c;
            if (type == null)
                continue;
                
            Inventory_Change__c ic;
            if (existingICs != null && existingICs.containsKey(sourceDocId)) {
                ic = existingICs.get(sourceDocId);
            } else {
                ic = new Inventory_Change__c(
                    Company__c = (Id)sourceDoc.get('Company__c'),
                    Posting_Date__c = System.now(),
                    Transaction_Date__c = itList[0].Transaction_Date__c,
                    Type__c = type
                );
                if(sourceDoc.get('Currency__c') != null){
                	ic.Currency__c = (Id)sourceDoc.get('Currency__c');
                }
                if (Work_Order__c.sObjectType == sourceDoc.getSObjectType())
                    ic.Work_Order__c = sourceDocId;
                icsToInsert.add(ic);
            }
            icMap.put(sourceDocId,ic);
        }
        
        DML.insertAsSystem(icsToInsert);
        
        for (Id sourceDocId:icMap.keySet()) {
            Inventory_Change__c ic = icMap.get(sourceDocId);
            if (ic != null) {
                ic.Finalized__c = true;
                ic.Finalized_Date__c = System.now();
                for (Inventory_Transaction__c it:itMap.get(sourceDocId))
                    it.Inventory_Change__c = icMap.get(sourceDocId).Id;
            }
        }    
        return icMap;
    }
    
    public static void updateReceiptLinesOnConsumption( map<id, Decimal> quantityConsumedPerPOLine ){
        
        map<Id, list<Receipt_Line__c>> receiptLinesByPOLine = new map<Id, list<Receipt_Line__c>>();
        list<Receipt_Line__c> rlListForUpdate = new list<Receipt_Line__c>();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> quantityConsumedPerPOLineIds = quantityConsumedPerPOLine.keySet();
		
		SOQLUtil soql = new SOQLUtil('Receipt_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Quantity_Received__c','Quantity_Consumed__c','Quantity_To_Consume__c','Uninvoiced_Quantity__c','Purchase_Order_Line__c',
			'Purchase_Order_Line__r.Quantity_To_Stock__c','Purchase_Order_Line__r.Order_Quantity__c','Purchase_Order_Line__r.Purchase_UOM__c',
			'Purchase_Order_Line__r.Purchase_UOM__r.Name','Purchase_Order_Line__r.Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Item__r.Stocking_UOM__r.Name'
		});
		soql.setWhereClause('Purchase_Order_Line__c IN :quantityConsumedPerPOLineIds and Quantity_To_Consume__c > 0');
		soql.setOrderByClause('CreatedDate');
		
		list<Receipt_Line__c> receiptLines = Database.query(soql.getQuery());
                                        
        for( Receipt_Line__c rl : receiptLines ){
            
            if(! receiptLinesByPOLine.containsKey( rl.Purchase_Order_Line__c ) )
                receiptLinesByPOLine.put( rl.Purchase_Order_Line__c, new list<Receipt_Line__c>() );
            
            receiptLinesByPOLine.get( rl.Purchase_Order_Line__c ).add(rl);
        }
        
        for( Id polId : quantityConsumedPerPOLine.keySet() ){
            
            Decimal quantityToConsume = quantityConsumedPerPOLine.get( polId );
            
            if( receiptLinesByPOLine.containsKey( polId ) ){
                
                for( Receipt_Line__c rl : receiptLinesByPOLine.get( polId )){
                	
                	Decimal conversionFactor = KSE.getConversionFactorFromQuantity(rl.Purchase_Order_Line__r.Quantity_To_Stock__c,rl.Purchase_Order_Line__r.Order_Quantity__c);//KSE.getConversionFactor(rl.Purchase_Order_Line__r);
                    
                    if( quantityToConsume > 0 ){
                        
                        Decimal quantityToAssign = Math.min(rl.Quantity_To_Consume__c, quantityToConsume/conversionFactor );
                        
                        rl.quantity_Consumed__c = KSE.addQuantityToField(rl.quantity_Consumed__c, 
                                                    quantityToAssign);
                        rl.Uninvoiced_Quantity__c = KSE.addQuantityToField(rl.Uninvoiced_Quantity__c, quantityToAssign);                            
                        
                        quantityToConsume -= Math.min(rl.Quantity_To_Consume__c, quantityToConsume/conversionFactor )*conversionFactor;//KNDY-9445 Converting to Stocking UOM.
                       
                        rlListForUpdate.add( rl );
                    }                           
                }
            }
        }
        DML.allowUpdateFields( new list<string>{'quantity_Consumed__c','Uninvoiced_Quantity__c'}, Receipt_Line__c.SobjectType );
        DML.updateAsUser( rlListForUpdate);                                              
    } 


    public static map< String, SKID__c> createToSkidsOnPull(    List<SObject> headers, 
                                                                Map<Id, List<SKID__c>> quantitySkidsByHeader, 
                                                                String inputField, 
                                                                String processName, 
                                                                List<String> attributes, 
                                                                Boolean convertUOM, 
                                                                Map<Id,SObject> sobjects){
        
        map< String, SKID__c> fromToSkidMap = new map<String, SKID__c>();
        list<SKID__c> skidList = new list<SKID__c>();
        set<Id> uniqueLocations = new set<Id>();
        
        Decimal conversionFactor = 1.0;

        for ( SObject header : headers )   {  
        	
        	if( convertUOM )
            {
            	if(header.getSObjectType()==Sales_Order_Line__c.sObjectType)
            	    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_From_Stock__c'),(decimal)header.get('Quantity_Ordered__c'));//KSE.getConversionFactor(header);
            	else if(header.getSObjectType()==Purchase_Order_Line__c.sObjectType)
            	    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.get('Quantity_To_Stock__c'),(decimal)header.get('order_quantity__c'));//KSE.getConversionFactor(header);
            	else if(header.getSObjectType()==Receipt_Line__c.sObjectType)
            		conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.getsObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)header.getsObject('Purchase_Order_Line__r').get('order_quantity__c'));//KSE.getConversionFactor(header);
            	else if(header.getSObjectType()==Shipment_Line__c.sObjectType)
            	    conversionFactor = KSE.getConversionFactorFromQuantity((decimal)header.getsObject('Sales_Order_Line__r').get('Quantity_From_Stock__c'),(decimal)header.getsObject('Sales_Order_Line__r').get('Quantity_Ordered__c'));
            }
        	
        	if( quantitySkidsByHeader.containsKey( header.id )){
	            for(SKID__c qtySkid : quantitySkidsByHeader.get( header.id )){
	                //Modified the condition to allow SKID with Count Qty as 0 in case of CycleCount as per PTM#71                
	                if (qtySkid.get(inputField) == null || (((Decimal)qtySkid.get(inputField) < 0) && (processName != 'InventoryChange') && (processName != 'CycleCount')) || ((Decimal)qtySkid.get(inputField) == 0 && processName != 'InventoryChange' && processName != 'CycleCount'))   {                    
	                    continue;
	                }
	                
	                uniqueLocations.add(qtySkid.Location__c);
	                
	                SKID__c toSkid = qtySkid.clone( false, true );
	                toSkid.Primary_Key_At_Location__c = null; // nulling out any primary key that the old skid data has before using it in the putaway service.
	                toSkid.quantity__c = ((Decimal)qtySkid.get( inputField ) * conversionFactor).setscale(6,System.RoundingMode.HALF_UP);
	                toSkid.put( inputField, 0 );
	                
	                if( processName == 'InventoryTransfer' || processName =='InventoryChange')
	                	toSkid.put('Quantity_Allocated__c', 0);
	                 
	                if( processName == 'Allocate'){
	                    
	                    list<SKID__c> demandSkid = (sobjects == null) ? (list<SKID__c>) header.getSObjects('SKIDs__r') : new list<SKID__c>{(SKID__c)sobjects.get(header.id)}; 
	                    SKID__c ds = demandSkid[0];
	                    
	                    toSkid.type__c = 'Allocated';
	                    toSkid.Quantity_Available__c = 0;
                        if( sobjects == null ){    
	                    	toSkid.Sales_Order_Line__c = header.id;
                            toSkid.Shipment_Line__c = ds.Shipment_Line__c;
                        }
                        else if (header.getSObjectType() == Shipment_Line__c.getSObjectType()){
                            toSkid.Shipment_Line__c = header.id;
                            toSkid.Sales_Order_Line__c = (( Shipment_line__c) header).Sales_Order_Line__c; 
                        }
                        else{
                            toSkid.Order_Line__c = header.id;
                            toSkid.Shipment_Line__c = ds.Shipment_Line__c;
                        }
	                }
	                else if (processName == 'ShipmentAllocate'){
                        SKID__c ds = (Skid__c) sobjects.get(header.id); 
                        
                        toSkid.Type__c = 'Allocated';
                        toSkid.Quantity_Available__c = null; // changed to null for consistency
                        toSkid.Quantity_Allocated__c = null; // changed to null for consistency

                        toSkid.Shipment_Line__c = header.id;
                        toSkid.Sales_Order_Line__c = (( Shipment_line__c) header).Sales_Order_Line__c; 
                        
                    }
	                else if( processName == 'TransferConsignedOwnership'){
	                    toSkid.Purchase_Order_Line__c = null;
	                    toSkid.Consigned_Owner__c = null;
	                }
	                else if( processName == 'InventoryTransfer' && sobjects == null && qtySkid.Temporary_Value_Holder__c != null ){     //INT-272
	                    //  to skid information for the qty skid is held in the from skid temporary valu holder field
	                    String tmpToSkidAttr = qtySkid.Temporary_Value_Holder__c ;
                	    String toLocation = tmpToSkidAttr.substring( 0 , tmpToSkidAttr.indexOf (',') ) ;
                	    String toBin = tmpToSkidAttr.substring( tmpToSkidAttr.indexOf (',')+1 , tmpToSkidAttr.length()  ) ;
                        
                        toSkid.Location__c =( toLocation =='null' || toLocation == '' )?null:toLocation;
            	        uniqueLocations.add(toSkid.Location__c);
		               	toSkid.Bin__c = (toBin =='null' || toBin == '')?null:toBin;
	                }
	                else if( processName == 'InventoryTransfer' && sobjects.containsKey(header.id) && sobjects.get(header.id) != null ){
	                	
	                	toSkid.Location__c = (Id)sobjects.get(header.id).get('Location__c');
	                	uniqueLocations.add(toSkid.Location__c);
		               	toSkid.Bin__c = (Id)sobjects.get(header.id).get('Bin__c');
		            }
                    else if( processName == 'TransferOrderShipment'){
              
                        toSkid.Location__c = (Id)header.get('Deliver_To_Location__c');
                        toSkid.Bin__c = null;
                        toSkid.Type__c = SKID_TYPE_INTRANSIT;
                        uniqueLocations.add(toSkid.Location__c);
                    }
	               
	                skidList.add( toSkid );
	       
	            }
	        }
        }

        if( skidList.size() > 0 ){
        	if( processName == 'Allocate' || processName == 'ShipmentAllocate'){
            	fromToSkidMap = putAwayService( skidList, attributes, uniqueLocations, 'Allocated', false );
        	}
            else if( processName == 'TransferConsignedOwnership'){   
                fromToSkidMap = putAwayService( skidList, attributes, uniqueLocations, 'Location', true );            
            }
            else if( processName == 'TransferOrderShipment'){
                fromToSkidMap = putAwayService( skidList, attributes, uniqueLocations, SKID_TYPE_INTRANSIT, false );		     
	        }
            else {
	       		fromToSkidMap = putAwayService( skidList, attributes, uniqueLocations, 'Location', false );		     
            }
        }
        return fromToSkidMap;
    }
    
    public static list<String> populateSortCriteria( Id customerId, Id companyId ){
        
        list<String> sortFields = new list<String>();
        
        List<Pick_Sort_Criteria__c> mscList = new list<Pick_Sort_Criteria__c>();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
		SOQLUtil soql = new SOQLUtil('Pick_Sort_Criteria__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Name','Sort_Field__c','Sort_Order__c','Null_Values__c','Sort_Priority__c','Customer__c'
		});
		soql.setOrderByClause('Sort_Priority__c');
		
        if( customerId != null ){
        	soql.setWhereClause('Customer__c =:customerId and Active__c = true');
		}

        if( companyId != null && mscList.size() == 0 ){
            soql.setWhereClause('Company__c =:companyId and Active__c = true');
		}
        
        mscList = Database.query(soql.getQuery());
        
        for( Pick_Sort_Criteria__c msc : mscList ){
            if( msc.Sort_Field__c != null ){
                String criteria = msc.Sort_Field__c+' ';
                
                if( msc.Sort_Order__c != null )
                    criteria += msc.Sort_Order__c+' ';
                
                if( msc.Null_Values__c != null )
                    criteria += 'NULLS '+msc.Null_Values__c+' ';
                
                sortFields.add(criteria);    
            }
        }
        
        return sortFields;
    }
        
    public static Boolean checkRequiredStockMovementSettings( String sourceDocument ){
    	
    	
        Decimal numberOfRequiredSettings = 2;
        Decimal actualNumberOfRequiredSettings =0;
        Set<String> requiredSettings = new set<String>{ 'company__c', 'facility__c' }; 

    	
    	for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
        
            if( smrs.Source_Document__c == sourceDocument ){
            	
            	if( requiredSettings.contains(( smrs.Stock_Movement_Rule_Field__c).toLowerCase()) ){
            		actualNumberOfRequiredSettings++;
            	}
            }
    	}
    	
    	 if( actualNumberOfRequiredSettings != numberOfRequiredSettings ){
    	 	return false;
    	 }
    	 
    	 return true;
    }
    
    public static map<Id, list<Location__c>> locationsFromStockMovementRules( list<SObject> sobjectList, String ruleType, String sourceDocument, map<Id, Stock_Movement_Rule__c> matchedRules  ){
        
        SchemaUtil util = SchemaUtil.getInstance();
        map< Id, list<Location__c>> locationMap = new map<Id, list<Location__c>>();
        map< Id, list<Id>> locationIdMap = new map<Id, list<Id>>();
        set<Id> locationIdSet = new set<Id>();
        if( matchedRules == null ){
            matchedRules = new map<Id, Stock_Movement_Rule__c>();
        }
        
        set<String> smrFields = new set<string>{'id', 'name', 'rule_type__c', 'source_document__c', 'priority__c', 'location__c', 'location__r.name', 'company__c', 'class__c', 
                                                'item__c', 'facility__c', 'location__r.facility__c', 'location__r.bin_tracked__c', 'customer__c',
                                                'Location_List__c'};

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Stock_Movement_Rule_Settings__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Source_Document_Path__c','Source_Document_Path_Putaway__c','Stock_Movement_Rule_Field__c'
		});
		soql.setWhereClause('Source_Document__c = :sourceDocument');
		
		List<Stock_Movement_Rule_Settings__c> smrsList = Database.query(soql.getQuery());

        for( Stock_Movement_Rule_Settings__c sm : smrsList ){
            
            smrFields.add( (sm.Stock_Movement_Rule_Field__c).toLowerCase() );
        }
        
        if( !checkRequiredStockMovementSettings(sourceDocument) ){
            
            if( ApexPages.currentPage() != null )
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Stock Movement Rule settings has not been setup!'));
            return locationMap;    
        }
        
        String whereClause = 'Rule_Type__c=:ruleType and Source_Document__c=:sourceDocument and Active__c = true Order By Priority__c ASC';
        
	    soql = new SOQLUtil('Stock_Movement_Rule__c');
	    soql.addFields(smrFields);
	    soql.setWhereClause(whereClause);
	    
        list<Stock_Movement_Rule__c> smrList = (List<Stock_Movement_Rule__c>) Database.query(soql.getQuery());                        
                                         
        String sourceField;
        if( ruleType.toLowerCase() == 'putaway' ){
            sourceField = 'Source_Document_Path_Putaway__c';
        }
        else{
            sourceField = 'Source_Document_Path__c';
        }
        
        for( SObject s : sobjectList ){
            
            String key='';
                
            for( Stock_Movement_Rule_Settings__c smrs : smrsList ){
                
				string  keyComponent, fieldName = (String)smrs.get(sourceField);
                // special case, we no longer have company__c on skid, deal with it
  				if ( fieldName.toLowerCase() == 'company__c' && s.getSObjectType() == SKID__c.sobjectType ) {                 	
                	keyComponent = getCompanyFromSkid((SKID__C)s );
                } else { 
                    keyComponent = AccountingRuleService.getValue(fieldName, s);
                }
				key += keyComponent;
            } 
            
            for( Stock_Movement_Rule__c smr : smrList ){
                
                if( smr.Location_List__c != null ){
                    String smrKey = '';
                    Stock_Movement_Rule__c smrClone = smr.clone(true, true);
                    
                    for( Stock_Movement_Rule_Settings__c smrs : smrsList ){
                         
                         String smrKeyField = smrs.Stock_Movement_Rule_Field__c;
                         
                         if( smrClone.get(smrKeyField) == null ){
                            
                            smrClone.put( smrKeyField, AccountingRuleService.getValue((String)smrs.get(sourceField), s));
                         }
                         
                         smrKey+= smrClone.get(smrKeyField);  
                    }
                    
                    if( smrKey == key ){
                        list<Id> locationList = new list<Id>();
                        try{
                            locationList = (list<Id>)JSON.deserialize(String.valueOf(smr.get('Location_List__c')), list<Id>.Class);
                        }
                        catch(Exception e){
                            throw new SkidService2Exception('Invalid location specified on stock movement rule :'+smr.get('name'));
                        }
                        locationIdMap.put( s.id ,locationList );
                        locationIdSet.addAll(locationList);
                        //s.put('Matched_Rule__c',smr.id);
                        matchedRules.put( s.id, smr );
                        break;
                    }
                }
            }
            
        }
        
       	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Name','Bin_Tracked__c','Facility__c','Facility__r.Company__c'
		});
		soql.setWhereClause('Id IN:locationIdSet');
		
		map<Id, Location__c> locations = new map<Id, Location__c>((List<Location__c>)Database.query(soql.getQuery()));
        
        for( Id headerId : locationIdMap.keySet()) {
            
            for( Id locationId : locationIdMap.get(headerId) ){
                
                if(!locationMap.containsKey(headerId))
                    locationMap.put(headerId, new list<Location__c>());
                
                if( locations.containsKey(locationId))    
                    locationMap.get(headerId).add(locations.get(locationId));    
            }
        }
        
        return locationMap;
    }
}