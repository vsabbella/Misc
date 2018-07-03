public with sharing class MassInventoryService {
    public static void checkChangeErrors(List<InventoryChangeWrapper> wrappers) {
        if (wrappers == null || wrappers.size() == 0) {
            return;
        }

        Map<Id,Decimal> skidMap = new Map<Id,Decimal>();
        Map<List<String>,Decimal> allocatedMap = new Map<List<String>,Decimal>();
        for (InventoryChangeWrapper wrapper:wrappers) {
            for (SKID__c skid:wrapper.skidsList) {
                if (skid.Input_Quantity__c != null && skid.Input_Quantity__c != 0) {
                    List<String> allocatedKey = skid.Temporary_Value_Holder__c != null ? (List<String>)JSON.deserialize(skid.Temporary_Value_Holder__c,List<String>.Class) : null;
                    Decimal skidQty = skidMap.get(skid.Id);
                    Decimal allocatedQty = allocatedMap.get(allocatedKey);
                    Decimal qtyAvailable;

                    if (allocatedQty != null && skidQty == null) qtyAvailable = allocatedQty;
                    else if (allocatedQty == null && skidQty != null) qtyAvailable = skidQty;
                    else if (allocatedQty != null && skidQty != null) qtyAvailable = Math.min(allocatedQty,skidQty);
                    if (qtyAvailable == null || skid.Quantity_Available__c < qtyAvailable) qtyAvailable = skid.Quantity_Available__c;

                    if (skid.Input_Quantity__c > qtyAvailable) {
                        throw new MassInventoryException('Change quantity (' + skid.Input_Quantity__c + ') cannot be greater than quantity available (' + qtyAvailable + ')');
                    }

                    if (allocatedKey != null) {
                        if (allocatedQty != null) allocatedMap.put(allocatedKey,allocatedQty - skid.Input_Quantity__c);
                        else allocatedMap.put(allocatedKey,skid.Quantity_Allocated__c - skid.Input_Quantity__c);
                    }

                    if (skidQty != null) skidMap.put(skid.Id,skidQty - skid.Input_Quantity__c);
                    else skidMap.put(skid.Id,skid.Quantity__c - skid.Input_Quantity__c);
                }
            }
        }
    }
    
    public static Map<String,MassInventoryService.InventoryStatus> massInventoryChange(List<InventoryChangeWrapper> icWrapperList) {
        checkChangeErrors(icWrapperList);
        
        Map<String,InventoryStatus> result = new Map<String,InventoryStatus> () ;
        List<SKID__c> allocatedSkids = new List<SKID__c>();
        List<Inventory_Change__c> icList = new List<Inventory_Change__c> ( ) ;
        List<sobject> skidList = new List<Sobject>();
        List<String> attributesForDisplay = new List<String>();
        Map<String, Decimal> allocatedQty = new Map<String, Decimal>(); 
        Map<Id, List<SKID__c>> quantitySkidsByHeader = new Map<Id, List<SKID__c>>();
        Boolean isErroneous = false ;
        list<SObject> headerList = new list<SObject>();
        
        Map<String,Inventory_Change__c> icMap = new Map<String,Inventory_Change__c>(); //<CompanyId,Inventory Change>
        Map<String,Decimal> skidQtyMap = new Map<String,Decimal>();
        Map<String,String> skidLineMap = new Map<String,String>();
        
        Set<String> itemLocationSet = new Set<String>();
        Inventory_Change__c icObj; 
        Savepoint sp = Database.setSavepoint() ;
        
        Integer zeroChangeQtySKIDCount = 0;
        
        try{
            for(InventoryChangeWrapper icwrapper: icWrapperList){
                InventoryStatus lineErrorStatus = new InventoryStatus();
                
                if(!icMap.containsKey(icwrapper.ic.Company__c))
                    icMap.put(icwrapper.ic.Company__c,icwrapper.ic);
                
                for(SKID__c skid:icwrapper.skidsList){
                    skidLineMap.put(skid.Id,icwrapper.lineId);
                    if(skid.Input_Quantity__c==null || skid.Input_Quantity__c == 0){
                        zeroChangeQtySKIDCount++;
                        continue;
                    }else{
                        skidQtyMap.put(skid.Id,skid.Input_Quantity__c);
                        skidList.add(skid);
                    }
                }
                if(String.IsEmpty(icwrapper.ic.Item__c) || String.isEmpty(icwrapper.ic.Location__c)){
                    addError(lineErrorStatus, Label.Item_and_Location_Required);
                    isErroneous = true ;
                    result.put(icwrapper.lineId , lineErrorStatus);
                }
                
                if(icwrapper.skidsList == null || icwrapper.skidsList.size() == 0){
                    addError(lineErrorStatus, Label.No_SKIDs_fetched);
                    isErroneous = true ;
                    result.put(icwrapper.lineId , lineErrorStatus);
                }
                if(itemLocationSet.contains(icwrapper.ic.Item__c+''+icwrapper.ic.Location__c)){
                        addError(lineErrorStatus, Label.Duplicate_Line_Created);
                        isErroneous = true ;
                        result.put(icwrapper.lineId , lineErrorStatus);
                }
                if(icwrapper.skidsList.size() == zeroChangeQtySKIDCount && icwrapper.skidsList.size()>0){
                        addError(lineErrorStatus, Label.No_SKID_Quantity_Updated);
                        isErroneous = true ;
                        result.put(icwrapper.lineId , lineErrorStatus);
                }
                
                itemLocationSet.add(icwrapper.ic.Item__c+''+icwrapper.ic.Location__c);
                zeroChangeQtySKIDCount = 0;
            }
            
            if (isErroneous) {
                return result ;
            }
            
            for(String key: icMap.keySet()){
                icObj = icMap.get(key);
                icObj.Item__c = null;
                icObj.Location__c = null;
                icObj.Type__c = 'Adjustment';
                icList.add (icObj);
            }
            
            attributesForDisplay.addAll( SkidService2.attributesForPutaway(SkidService3.getAttributeFields()));
            
            try{
                DML.insertAsUser((List<sobject>) icList);
            }
            catch (Exception e ) {  
                isErroneous = true;   
                InventoryStatus status = new InventoryStatus () ;
                addError ( status, e.getMessage() ) ;
                result.put (null, status);
            }
            
            Map<String, list<SKID__c>> itemLocationKeyList = SkidService2.pullSortedSkids(skidList, null, null, ' and Consigned_Owner__c = null ', 'Item',allocatedSkids, null);// and Quantity__c >=0 PTM-514
            SkidService2.queryAllocatedSkids(allocatedQty, allocatedSkids);
            
            List<SKID__c> skidObjList = new List<SKID__c>();
            
            for(String key: itemLocationKeyList.keySet()){
                List<Skid__c> objList = itemLocationKeyList.get(key);
                for(SKID__c skid:objList){
                    skid.Count_Quantity__c = skid.Quantity__c;
                    skid.Input_Quantity__c = null;
                }
                skidObjList.addAll(objList);
            }
            
            //@TODO: After implementation of multi-company, group skids by company and populate quantitySkidsByHeader per company;
            quantitySkidsByHeader.put (icList[0].Id,skidObjList);
            headerList.add(icList[0]);
            
            SkidService2.distribute( headerList, quantitySkidsByHeader, null,null, null, false, 'Count_Quantity__c', 'Input_Quantity__c',
                                 'InventoryChange', allocatedQty, false);
            
            SkidService2.reFetchSkidsForUpdate(quantitySkidsByHeader, headerList);
            
            for(Id key: quantitySkidsByHeader.keySet()){
                for(SKID__c skid: quantitySkidsByHeader.get(key)){
                    
                    if(skidQtyMap.containsKey(skid.Id)){
                        skid.Count_Quantity__c = skid.Quantity__c;
                        skid.Input_Quantity__c = skidQtyMap.get(skid.Id);
                        skidQtyMap.remove(skid.Id);
                    }
                }
            }
            
            if(skidQtyMap.size()>0){ // a skid was deleted by another process and quantitySkidsByHeader contains less SKIDs than skidQtyMap
                isErroneous = true;
                for(String key: skidQtyMap.keySet()){
                    if(result.get(skidLineMap.get(key))==null){
                        InventoryStatus status = new InventoryStatus () ;
                        addError ( status, 'The inventory for this line was deleted by another process. Please refresh this line and update the quantities again');
                        result.put (skidLineMap.get(key), status);
                    }
                }
            }
            
            if ( isErroneous == true ) {
                Database.rollback(sp ) ;
                return result ;
            }
            
            try{
                SkidService2.checkIssueError(icList, quantitySkidsByHeader, null, null, 'Input_Quantity__c', 'Count_Quantity__c','Error','InventoryChange', allocatedQty, false);
            }
            catch (Exception e ) {  
                isErroneous = true;
                Database.rollback(sp ) ;
                InventoryStatus status = new InventoryStatus () ;
                addError ( status, e.getMessage() ) ;
                result.put (null, status);
                return result ;
            }
            
            //SkidService2.checkIssueError(headerList, quantitySkidsByHeader, null, null, 'Input_Quantity__c', 'Count_Quantity__c','Error','InventoryChange', allocatedQty, false);
            map< String, SKID__c> fromToSkidMap = SkidService2.createToSkidsOnPull((List<sobject>) icList, quantitySkidsByHeader, 'Input_Quantity__c', 'InventoryChange', attributesForDisplay, false, null);
            SkidService2.inventoryTransactionForPullFrom((List<sobject>) icList, quantitySkidsByHeader, 'Adjustment', attributesForDisplay, null, 'Input_Quantity__c', fromToSkidMap, false, null);
            
            for(Inventory_Change__c ic: icList){
                ic.Finalized__c = true;
            }
            
            try{
                DML.updateAsUser((List<sobject>) icList);
            }
            catch (Exception e ) {  
                isErroneous = true;
                Database.rollback(sp );
                InventoryStatus status = new InventoryStatus () ;
                addError ( status, e.getMessage() ) ;
                result.put (null, status);
                return result ;
            }
            
            InventoryStatus status = new InventoryStatus () ;
            status.recordId = icList.get(0).id ;
            status.success = true ;
            result.put (null, status ) ;
        }catch(Exception e){
            Database.rollback(sp ) ;
        }
        
        return result;
    }
    
    private static void addError(InventoryStatus lineErrorStatus, String message){
        lineErrorStatus.errorMessage.add(message);
        lineErrorStatus.success = false;
    }
    
   public static Inventory_Change__c massInventoryTransfer(Id companyId,Id facilityId,Id reasonCodeId,List<SkidService3.SerialWrapper> invData) {
      
        List<SkidService3.SerialWrapper> wrappersForPutaway = new List<SkidService3.SerialWrapper>();
        SkidService3.ParameterData itInfo = new SkidService3.ParameterData();
        
        Inventory_Change__c ic = new Inventory_Change__c(Company__c = companyId,Type__c = 'Transfer',Reason_Code__c = reasonCodeId,Facility__c = facilityId);
        DML.insertAsUser(ic);
        
        SOQLUtil icQuery = new SOQLUtil ( 'Inventory_Change__c', true);
        icQuery.addFields ( new Set<String> {'Id','Name'});
        icQuery.setWhereClause ( 'Id = \'' + ic.Id +'\'');
        List<Inventory_Change__c> lstInvChange = Database.query ( icQuery.getQuery () );
        ic.Name = lstInvChange[0].Name;
        ic.Finalized__c = true;
        ic.Finalized_Date__c = System.now();
        
        
        Set<Id> locationIds = new Set<Id>();
        
        
        for (SkidService3.SerialWrapper row:invData) {
            
            
            locationIds.add(row.skid.Location__c);
            
        }
        
        SOQLUtil locationQuery = new SOQLUtil ('Location__c', true);
        locationQuery.addFields ( new Set<String> {'Id','Name','Bin_Tracked__c', 'Facility__c'});
        locationQuery.setWhereClause ( 'Id in :locationIds' );
        Map<Id,Location__c> locations = new Map<Id,Location__c>( (List<Location__c>)Database.query(locationQuery.getQuery())  );
        set<id> fromSkidId = new set<id>();
        Set<String> serialKeys = new Set<String>();
        for (SkidService3.SerialWrapper row:invData) {
            
            SKID__c fromSkid = row.skid;
            fromSkidId.add(row.skid.id) ;
            SKID__c toSkid = row.skid.clone(false,true);
            toSkid.bin__c = null;
            toSkid.Location__c = null;
            toSkid.Quantity__c = row.skid.Input_Quantity__c;
            List<String> locAndBinId = row.skid.Temporary_Value_Holder1__c.split(',');
            toSkid.Location__c = locAndBinId[0];
            if (locAndBinId.size() > 1  ) 
            {
                toSkid.Bin__c = locAndBinId[1];
                
            }
            
            fromSkid.Company__c = companyId;
            toSkid.Company__c = companyId;
            
            fromSkid.Location__r = locations.get(row.skid.Location__c);
            
            Boolean serialTracked = false;
            
            if( fromSkid.Input_Quantity__c != null ){
                if(fromSkid.getSObject('Item__r') != null && fromSkid.getSObject('Item__r').get('Item_Attribute__c')!= null && 
                    fromSkid.getSObject('Item__r').getSObject('Item_Attribute__r') != null &&
                    (Boolean)fromSkid.getSObject('Item__r').getSObject('Item_Attribute__r').get('Serial_Number__c')
                    && fromSkid.getSObject('Item__r').getSObject('Company__r').get('Serial_Control__c') == 'At receipt and all processes'){
                    
                    serialTracked = true;
                }
                
                if( serialTracked && fromSkid.Input_Quantity__c != row.serialList.size() ){
                    throw new MassInventoryException(Label.Number_Of_Serials_Not_Matching_Quantity+ ' Transfer Quantity : ' + fromSkid.Input_Quantity__c
                    +' Number of Serials : '+row.serialList.size() + ' for ' + row.skid.Item__r.Name);
                }
                
               
                
                 for (Serial__c serial:row.serialList) {
                    
                        String serialKey = companyId + '-' + row.skid.Item__c + '-' + serial.Name;
                        if (serialKeys.contains(serialKey)) {
                            throw new MassInventoryException(Label.Serial + ' ' + serial.Name + ' specified more than once');
                        } else {
                            serialKeys.add(serialKey);
                        }
                   
                 }        
                
               
                List<Serial__c> serialList = row.serialList;
                wrappersForPutaway.add(new SkidService3.SerialWrapper(toSkid, serialList));
                
                itInfo.itList.add(SkidService3.createInventoryTransaction(ic, 'Transfer', toSkid.Quantity__c, fromSkid, toSkid, null));  
                
            }
            
        }
        
        Map<List<String>,SkidService3.SerialWrapper> toSkids = SkidService3.putAwayService(wrappersForPutaway,null,null);
        
        SOQLUtil skidQuery = new SOQLUtil ('Skid__c', true);
        skidQuery.addFields ( new Set<String> {'Id','Name','Quantity__c'});
        skidQuery.setWhereClause ( 'Id in :fromSkidId' );
        Map<Id,skid__c> skids = new Map<Id,skid__c>((List<skid__c>)Database.query(skidQuery.getQuery()));
        
         
        
        for(Inventory_Transaction__c it:itInfo.itList){
            if(!skids.isEmpty() && skids.containsKey(it.From_SKID__c)  ){
               it.From_SKID__r.Quantity__c = skids.get(it.From_SKID__c).Quantity__c; 
            }
        }
        
        
        SkidService3.inventoryTransactionsForPutaway(new Map<Id,SkidService3.ParameterData>{ ic.Id => itInfo },null,toSkids,new map<String,String>{'serialTransactionType'=>'Transfer'});
    
        DML.updateAsUser(ic);
        return ic;
    }
    
    public static void checkTransferErrors(List<SkidService3.SerialWrapper> invData) {
       
        
        Set<Id> itemIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        Set<Id> skidIds = new Set<Id> ();
        
        for (SkidService3.SerialWrapper row:invData) {
            itemIds.add(row.skid.Item__c);
            locationIds.add(row.skid.Location__c);
            
            List<String> locAndBinId = row.skid.Temporary_Value_Holder1__c.split(',');
            SKID__c toSkid = row.skid.clone(false,true);
            toSkid.Location__c = locAndBinId[0];
            
            locationIds.add(toSkid.Location__c);
            skidIds.add ( row.skid.Id );
        }
        
        SOQLUtil itemQuery = new SOQLUtil('Item__c');
        itemQuery.addAllCustomFields();
        itemQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item_Attribute__r');
        itemQuery.addField('Company__r.Serial_Control__c');
        itemQuery.setWhereClause('Id IN :itemIds');
        
        SOQLUtil locationQuery = new SOQLUtil ('Location__c', true);
        locationQuery.addFields ( new Set<String> {'Id','Name','Bin_Tracked__c', 'Facility__c'});
        locationQuery.setWhereClause ( 'Id in :locationIds' );
        
        SOQLUtil skidQuery = new SOQLUtil ('Skid__c', true);
        skidQuery.addFields ( new Set<String> {'Id','Name','Quantity__c'});
        skidQuery.setWhereClause ( 'Id in :skidIds' );
        
        Map<Id,Item__c> items = new Map<Id,Item__c>((List<Item__c>)Database.query(itemQuery.getQuery()));
        Map<Id,Location__c> locations = new Map<Id,Location__c>( (List<Location__c>)Database.query(locationQuery.getQuery())  );
       
        Map<List<String>,Decimal> allocatedSkidMap = new Map<List<String>,Decimal>();
        Map<id,decimal> skidIdQtyAvail = new Map<id,decimal>();
        for (SkidService3.SerialWrapper row:invData) {
            
            SKID__c fromSkid = row.skid;
            fromSkid.Item__r = items.get(row.skid.Item__c);
            fromSkid.Location__r = locations.get(row.skid.Location__c);  
            fromSkid.Type__c = 'Location';
            
            if(row.skid.Input_Quantity__c != null && row.skid.Input_Quantity__c <= 0){
              throw new MassInventoryException(Label.Transfer_quantity_must_be_positive);  
            }
            
            List<String> allocatedKey;
           
            Decimal qtyAvailable;
            Decimal allocatedSkidMapQty;
            
            if (row.skid.Temporary_Value_Holder__c != null) {
                allocatedKey = (List<String>)JSON.deserialize(row.skid.Temporary_Value_Holder__c,List<String>.Class);
                
                if (allocatedSkidMap.containsKey(allocatedKey)) {
                  allocatedSkidMapQty = allocatedSkidMap.get(allocatedKey); 
                }
                
            }
            
            Decimal skidMapQty;
            if (skidIdQtyAvail.containsKey(row.skid.Id)) {
                skidMapQty = skidIdQtyAvail.get(row.skid.Id);
            }
            if (allocatedSkidMapQty != null && skidMapQty == null) {
                qtyAvailable = allocatedSkidMapQty;
            } else if (allocatedSkidMapQty == null && skidMapQty != null) {
                qtyAvailable = skidMapQty;
            } else if (allocatedSkidMapQty != null && skidMapQty != null) {
                qtyAvailable = Math.min(allocatedSkidMapQty,skidMapQty);
            }
            
            if (qtyAvailable == null || row.skid.Quantity_Available__c < qtyAvailable) qtyAvailable = row.skid.Quantity_Available__c;

            if (row.skid.Input_Quantity__c > qtyAvailable) {
                throw new MassInventoryException('Transfer quantity (' + row.skid.Input_Quantity__c + ') cannot be greater than quantity available (' + qtyAvailable + ') for item: (' + row.skid.Item__r.name + ')');
            }
            

            if (allocatedKey != null) {
                if (allocatedSkidMap.containsKey(allocatedKey)){
                   allocatedSkidMap.put(allocatedKey,allocatedSkidMap.get(allocatedKey) - row.skid.Input_Quantity__c); 
                } 
                else {
                  allocatedSkidMap.put(allocatedKey, KSE.subtractDecimals(row.skid.Quantity_Allocated__c, row.skid.Input_Quantity__c) );  
                }
            }
            
            if(skidIdQtyAvail.containsKey(row.skid.id)){
                skidIdQtyAvail.put(row.skid.id,skidIdQtyAvail.get(row.skid.id) - row.skid.Input_Quantity__c);
            }else {
              skidIdQtyAvail.put(row.skid.id,KSE.subtractDecimals(row.skid.Quantity__c,row.skid.Input_Quantity__c));  
            }
            
            
            fromSkid.Bin__r = null;
          
            SKID__c toSkid = fromSkid.clone(false,true);
            toSkid.Bin__c = null;
            toSkid.Location__c = null;
            List<String> locAndBinId = row.skid.Temporary_Value_Holder1__c.split(',');
          
            toSkid.Location__c = locAndBinId[0];
             if (locAndBinId.size() > 1  ) 
            {
                toSkid.Bin__c = locAndBinId[1];
                
            }
         
            toSkid.Item__r = items.get(toSkid.Item__c);
            toSkid.Location__r = locations.get(toSkid.Location__c);
            

            if (toSkid.Location__r.Bin_Tracked__c && toSkid.Bin__c == null) {
                throw new MassInventoryException(Label.To_Bin_Required);
               
            }
            
            if (fromSkid.Location__c == toSkid.Location__c && fromSkid.Bin__c == toSkid.Bin__c && row.skid.Input_Quantity__c > 0  ) {
                throw new MassInventoryException(Label.From_and_to_location_and_bin_cannot_be_the_same);
               
            }
          
        }
       
    }
    
    

    
    public class InventoryStatus {
        public Id recordId { get; set; }
        public Boolean success { get; set; }
        public List<String> errorMessage { get; set; }
        
        public InventoryStatus () {
            errorMessage = new List<String> () ;
            success = true ;
        }
    }
    
    public class InventoryData {
        public String lineId { get; set; }
        public SKID__c fromSKID { get; set; } { fromSKID = new SKID__c(); }
        public SKID__c toSKID { get; set; } { toSKID = new SKID__c(); }
        public List<String> trackedAttributes { get; set; } /*{ trackedAttributes = null; }*/
        public Boolean isSerialTracked {get;set;} {isSerialTracked = false;}
        public list<Serial__c> serialList { get;set;} /*{ serialList = new List<Serial__c> (); }*/
    }
    
    public class InventoryChangeWrapper{
        public String lineId { get;set; } 
        public Inventory_Change__c ic { get;set; }
        
        public List<SKID__c> skidsList { get; set; }
        
        public InventoryChangeWrapper(){
            this.lineId = null;
            this.ic = new Inventory_Change__c();
            this.skidsList = new List<SKID__c>();
        }
    }

    public class MassInventoryException extends Exception { }
}