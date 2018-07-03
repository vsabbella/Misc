/*
 *   Copyright Kenandy Inc.
 * @Author : MG
 * @Description : This class is initiated from GenerateMRPTempData to process all MRP temps and create final demands
 *  Criteria : Items that have a demand in the MRP temp.
 */
public with sharing class GenerateMRPPlanData implements Database.Batchable<sObject>, Database.Stateful{

    public string query;
    public integer nextLevel;
    public Date todaysDate;
    public Id companyId;
    public ID facilityID;
    public ID mrpRunID, PcalID, RcalID;
    String strDateTime, SmrpRunID;
    Date MRP_Planning_Time_Fence_in_Days;
    List<MRP_Run__c> mrprun = new List<MRP_Run__c>();
    public String errMsg;
    private Date futureNeedDate = date.newinstance(2099,12,31);
    
    MRPSettingsService MRPService = new MRPSettingsService();
//  PTM-153 combine Facility and Company ID to allow simultaneous Facility MRPs to run
    String cfID;    

    public GenerateMRPPlanData(integer level, Id mrpRID, ID PclID, ID RclID ) {
        nextLevel=level;
        this.mrpRunID = mrpRID;
        SmrpRunID = string.valueOf(mrpRunID);
        this.PcalID = PclID;
        this.RcalID = RclID;
        
        errMsg = '';
        
        todaysDate=KSE.calculateStartDate(Date.today(),0,PcalID);   
        strDateTime = system.now().format();
        
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('MRP_Run__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'ID','Name','Company__c','Facility__c','MRP_Planning_Time_Fence_in_Days__c'
});
soql.setWhereClause('ID =: mrpRunID');
mrpRun = Database.query(soql.getQuery());


        this.companyID = mrpRun[0].Company__c;
        this.facilityID = mrpRun[0].Facility__c;
        
        if (mrpRun[0].MRP_Planning_Time_Fence_in_Days__c == null || mrpRun[0].MRP_Planning_Time_Fence_in_Days__c <= 0)
            MRP_Planning_Time_Fence_in_Days = null;   
        else MRP_Planning_Time_Fence_in_Days = KSE.calculateEndDate(todaysDate, (integer)mrpRun[0].MRP_Planning_Time_Fence_in_Days__c, PcalID);
        
        // PTM-737  change query locator     
        if (facilityID == null) cfID = companyID;  // by company
        else cfID = companyID +'-' +facilityID;  // by facility
        query = 'select Id from Item__c where Id in '+
                '(select Item__c from MRP__c where MRP_Run__c = :mrpRunID and Level__c=:nextLevel and Is_Demand__c=true) ';
    }
   
    public Database.QueryLocator start(Database.BatchableContext BC){
       system.assert( this.companyId != null, 'GenerateMRPPlanData expected companyID to be set' );
       return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext info, List<Item__c> itemList) {
        execute( itemList );
    }

    public void execute(List<Item__c> itemList){
        string localquery;
        set<Id> mrpSupplySet=new set<Id>();
        Set<Id> itemSet=new Set<Id>();
        Set<Id> itemUsedSet=new Set<Id>();
        Set<Id> assemblySet=new Set<Id>();
        
        list<MRP__c> mrpUpdateList=new list<MRP__c>();
        list<MRP__c> mrpTempList=new list<MRP__c>();
        list<MRP__c> planList=new list<MRP__c>();
        List<MRP__c> sList = new List<MRP__c>();
        
        Map<Id,list<Component__c>> itemComponentMap=new Map<Id,list<Component__c>>();
        Map<ID, List<Item_Specification__c>> assemblyMap = new Map<ID, List<Item_Specification__c>>();
        Map<Id,list<MRP__c>> supplyMap=new Map<Id,list<MRP__c>>();
        Map<ID, Facility_Item__c> facilityItemMap = new Map<ID, Facility_Item__c>();
        
        Double remainingSupply=0;
        Double remainingDemand=0;
        Double balance = 0;
        boolean noMoreSupply=false;
        integer i=1, at;
        ID assyID, facilityItemID;
        String isName, Source, mrpUnique;
        Boolean hasFacility, UseLotSizing;
        Integer LeadTime, Aggregation;
        Double EOQ, OrderingMultiple, Shrinkage;
        
        try {
            SOQLUtil soql = new SOQLUtil('Item__c', TRUE);
            if (this.facilityID == null) { // by company
                string queryFieldString = 'Id,Name,Aggregation_Days__c,Use_Lot_Sizing__c,Safety_Stock__c,Shrinkage__c,EOQ__c,Ordering_Multiple__c,Lead_Time__c,Source__c';
                
                Set<String> queryFieldPaths = new Set<String>(queryFieldString.split(','));
                
                soql.addFields(queryFieldPaths);
                soql.setWhereClause('Id in :itemList');
                
                SOQLUtil.ChildRelationship subQuery1 = new SOQLUtil.ChildRelationship(soql, 'Item_Specifications__r');
                subQuery1.addFields(new Set<String>{'Id', 'Start_Date2__c'});
                subQuery1.setWhereClause('Facility__c = null and Production__c = true');
                subQuery1.setOrderByClause('Start_Date2__c desc');
                
                SOQLUtil.ChildRelationship subQuery2 = new SOQLUtil.ChildRelationship(soql,'MRPs__r');
                subQuery2.addFields(new Set<String>{'Id','Item__c','Demand__c','Quantity__c','Modified_Quantity__c','Order_Forecast__c','Required_Date__c','Start_Date__c','Is_Demand__c','Level__c','Where_Required__c','Company__c', 'Next_Level_Item_Specification__c'});
                subQuery2.setWhereClause('MRP_Run__c = :mrpRunID AND Is_Demand__c=true');
                subQuery2.setOrderByClause('Required_Date__c asc');
                soql.addChildRelationship(subQuery1);
                soql.addChildRelationship(subQuery2);
            }
            else { // by facility
                string queryFieldsString = 'Id,Name,Aggregation_Days__c,Use_Lot_Sizing__c,Safety_Stock__c,Shrinkage__c,EOQ__c,Ordering_Multiple__c,Lead_Time__c,Source__c'; 
                Set<String> queryFieldsPaths = new Set<String>(queryFieldsString.split(','));
                
                soql.addFields(queryFieldsPaths);
                soql.setWhereClause('Id in :itemList');
                
                SOQLUtil.ChildRelationship subQuery3 = new SOQLUtil.ChildRelationship(soql, 'Item_Specifications__r');
                subQuery3.addFields(new Set<String>{'Id','Name','Start_Date2__c','Facility__c'});
                subQuery3.setWhereClause('(Facility__c = null or Facility__c =: facilityID) and Production__c = true');
                subQuery3.setOrderByClause('Name, Facility__c nulls last, Start_Date2__c desc');
                
                SOQLUtil.ChildRelationship subQuery4 = new SOQLUtil.ChildRelationship(soql,'MRPs__r');
                subQuery4.addFields(new Set<String>{'Id','Item__c','Demand__c','Quantity__c','Modified_Quantity__c','Order_Forecast__c','Required_Date__c','Start_Date__c','Is_Demand__c','Level__c','Where_Required__c','Company__c', 'Next_Level_Item_Specification__c'});
                subQuery4.setWhereClause('MRP_Run__c = :mrpRunID AND Is_Demand__c=true and Facility__c =: facilityID ');
                subQuery4.setOrderByClause('Required_Date__c asc');
                soql.addChildRelationship(subQuery3);
                soql.addChildRelationship(subQuery4);
            }   
            
            
        
            system.debug('itemList query: '+soql.getQuery());
            //itemList = Database.query( localquery );  // PTM-152  re-query inside this execute() block so that all our query locators are fresh 
            itemList = Database.query(soql.getQuery());
            
        
            for(Item__c itemSetObj:itemList){
            
                if(!itemSet.contains(itemSetObj.Id)) itemSet.add(itemSetObj.Id);
                    
                isName = null;
                for(Item_Specification__c itemSpec:itemSetObj.Item_Specifications__r){
            
                    if (facilityID != null) {  // check for facility boms if they exist skip non-facility boms
                        if (isName == null || isName != itemSpec.Name) {
                            isName = itemSpec.Name;
                            if (itemSpec.Facility__c != null) hasFacility = true;
                            else hasFacility = false;
                        }
                        if (hasFacility == true && itemSpec.Facility__c == null) continue;
                    } 
                
                    assemblySet.add(itemSpec.Id);
                
                    if(assemblyMap.get(itemSetObj.Id) == null)
                        assemblyMap.put(itemSetObj.Id, new list<Item_Specification__c>());
                 
                    assemblyMap.get(itemSetObj.Id).add(itemSpec);                
                }
            }

            //create a map of list of BOMs for all items
            if(assemblySet.size()>0) { 
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	            soql = new SOQLUtil('Component__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Quantity_per_Assembly__c','Component_Item__c','Assembly_Item_Specification__c','Yield__c','Component_Item__r.Lead_Time__c',
					'Component_Item__r.Source__c'
				});
				soql.setWhereClause('Component_Item__r.Active__c=true and Component_Item__r.Non_Inventory__c <> true and Assembly_Item_Specification__c in:assemblySet');
            	for(Component__c componentObj:Database.query(soql.getQuery())){

	                if(itemComponentMap.get(componentObj.Assembly_Item_Specification__c)==null)
	                    itemComponentMap.put(componentObj.Assembly_Item_Specification__c,new list<Component__c>());
	                 
	                itemComponentMap.get(componentObj.Assembly_Item_Specification__c).add(componentObj);
            	}
            }
        
        //create a map of all the supplies

            if (facilityID == null) { // by company


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
         soql = new SOQLUtil('MRP__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','Company__c','Demand__c','Quantity__c','Modified_Quantity__c','Required_Date__c','Start_Date__c','Is_Demand__c','Where_Required__c',
	'Item__c'
});
        string mId =   this.mrpRunID;              
        soql.setWhereClause('mrp_Run__c = :mId AND Facility__c = null AND Item__c in:itemSet AND Is_Demand__c=false');
soql.setOrderByClause('Required_Date__c asc');
sList = Database.query(soql.getQuery());


                }
            else {  // by facility


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            soql = new SOQLUtil('MRP__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','Company__c','Demand__c','Quantity__c','Modified_Quantity__c','Required_Date__c','Start_Date__c','Is_Demand__c','Where_Required__c',
	'Item__c'
});
            string mrpId = this.mrpRunID;
            soql.setWhereClause('mrp_Run__c = :mrpId AND Facility__c =: facilityID AND Item__c in:itemSet AND Is_Demand__c=false');
soql.setOrderByClause('Required_Date__c asc');
sList = Database.query(soql.getQuery());


            }
            
            for(MRP__c supplyList : sList) {
                                                    
                if(supplyMap.get(supplyList.Item__c)==null)
                    supplyMap.put(supplyList.Item__c,new list<MRP__c>());
                
                supplyMap.get(supplyList.Item__c).add(supplyList);
            
            }
        
            // if by facility get FacilityItem info
            if (facilityID != null) { // by facility


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
             soql = new SOQLUtil('Facility_Item__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'ID','Aggregation_Days__c','EOQ__c','Item__c','Lead_Time__c','Ordering_Multiple__c','Shrinkage__c','Source__c','Use_Lot_Sizing__c'
});
soql.setWhereClause('Active__c = true and Facility__c =: facilityID');
            for (Facility_Item__c fi : Database.query(soql.getQuery())){



                    facilityItemMap.put(fi.Item__c, fi);
                }
            }
        
            //iterate through the list of demands for this item
            for(Item__c itemSetObj:itemList){
                if(!itemUsedSet.contains(itemSetObj.Id)){
                    i=1;
                    at = 0;
                    mrpSupplySet=new set<Id>();
                    remainingSupply=0;
                    remainingDemand=0;
                    balance = 0;
                    noMoreSupply=false;
                    itemUsedSet.add(itemSetObj.Id);
                    // if by facility use FacilityItem fields
                    if (itemSetObj.EOQ__c > 0.0) EOQ = itemSetObj.EOQ__c;
                    else EOQ = 0.0;
                    LeadTime = integer.valueof(itemSetObj.Lead_Time__c);
                    if (itemSetObj.Ordering_Multiple__c > 0.0) OrderingMultiple = itemSetObj.Ordering_Multiple__c;
                    else OrderingMultiple = 0.0;
                    if (itemSetObj.Shrinkage__c > 0.0) Shrinkage = itemSetObj.Shrinkage__c;
                    else Shrinkage = 0.0;
                    // KNDY-6256 check for null source
                    if (String.valueOf(itemSetObj.get('Source__c')) != null) Source = String.valueOf(itemSetObj.get('Source__c'));
                    else Source = 'Purchased';
                    UseLotSizing = itemSetObj.Use_Lot_Sizing__c;
                    if (itemSetObj.Aggregation_Days__c != null && itemSetObj.Aggregation_Days__c >= 0) Aggregation = integer.valueof(itemSetObj.Aggregation_Days__c);
                    else Aggregation = null;
                    facilityItemID = null;
                    if (facilityID != null) { // by facility
                        if (facilityItemMap.containsKey(itemSetObj.ID)) {
                            Facility_Item__c fi = facilityItemMap.get(itemSetObj.ID);
                            if (fi.EOQ__c > 0.0) EOQ = fi.EOQ__c;
                            else EOQ = 0.0;
                            LeadTime = integer.valueof(fi.Lead_Time__c);
                            if (fi.Ordering_Multiple__c > 0.0)OrderingMultiple = fi.Ordering_Multiple__c;
                            else OrderingMultiple = 0.0;
                            if (fi.Shrinkage__c > 0.0) Shrinkage = fi.Shrinkage__c;
                            else Shrinkage = 0.0;
                            // KNDY-6256 check for null source
                            if (String.valueOf(fi.get('Source__c')) != null) Source = String.valueOf(fi.get('Source__c'));
                            else Source = 'Purchased';
                            UseLotSizing = fi.Use_Lot_Sizing__c;
                            if (fi.Aggregation_Days__c != null && fi.Aggregation_Days__c >= 0) Aggregation = integer.valueof(fi.Aggregation_Days__c);
                            else Aggregation = null;
                            // PTM-373 added MRP lookup to Facility_Item__c
                            facilityItemID = fi.ID;
                        }
                    }
                }
            
                // PTM-151  First error: Aggregate query has too many rows for direct assignment, use FOR loop
                list<MRP__c> mrpDemandList= new list<MRP__c>(); 
                for(list<MRP__c> demandList: itemSetobj.getSObjects('MRPs__r') ) {  
                    mrpDemandList.addAll(demandList);
                }
            
                for(MRP__c demandList:mrpDemandList){  
                
                    at = at + 1;  // keep track of where you are at in the demand list for aggregation
                
                    if(demandList.Modified_Quantity__c!=null)
                        remainingDemand=demandList.Modified_Quantity__c;
                
                    MRP__c seqDemandObj=new MRP__c(Id=demandList.Id);
                    // Demand MRP - unique
                    String dmdMRPUnique = SmrpRunID + demandList.Item__c + strDateTime + string.valueOf(i);
                    seqDemandObj.Sequence__c=i++;                    
                    balance = balance - remainingDemand;
                    seqDemandObj.Balance__c = balance;
                    seqDemandObj.MRP_Unique__c = dmdMRPUnique ;
                    mrpUpdateList.add(seqDemandObj);
                
                    if(noMoreSupply==true){
                        if(remainingDemand>0&&remainingSupply>0){   
                            remainingDemand=remainingDemand-remainingSupply;
                            remainingSupply=-remainingDemand;                  
                        }  
                    } 
                    else {
                        if(supplyMap.get(demandList.Item__c)!=null){
                      
                            for(MRP__c supplyList:supplyMap.get(demandList.Item__c)){ //iterate through the list of supplies available for this item
                            
                                if(!mrpSupplySet.contains(supplyList.Id)){
                              
                                    mrpSupplySet.add(supplyList.Id);
                                    MRP__c seqSupplyObj=new MRP__c(Id=supplyList.Id);
                                    seqSupplyObj.Sequence__c=i++;
                                    if(demandList.Required_Date__c != null) {
                                        seqSupplyObj.MRP_Need_Date__c = demandList.Required_Date__c;
                                    }
                                    if(demandList.Where_Required__c!=null)
                                        seqSupplyObj.Where_Required__c=demandList.Where_Required__c;
                                    if(supplyList.Modified_Quantity__c!=null)
                                        remainingSupply=supplyList.Modified_Quantity__c+remainingSupply;
                                    
                                    balance = balance + remainingSupply;
                                    seqSupplyObj.Balance__c = balance;
                                    mrpUpdateList.add(seqSupplyObj);                              
                                }
                            
                                remainingDemand=remainingDemand-remainingSupply;
                                if(remainingDemand>0) remainingSupply=0;
                                if(remainingDemand<0){
                                    remainingSupply=-remainingDemand;
                                    remainingDemand=0;
                                    break;
                                }
                                else if(remainingDemand==0){
                                    remainingSupply=0; 
                                    break;
                                }                       
                            }
                        }
                    }
                                                 
                    if(remainingDemand>0){
                        remainingSupply=0;
                        noMoreSupply=true;
                    
                        Double MRPQty, multRem;                                             
                    
                        MRPQty = remainingDemand;
                                              
                        if (UseLotSizing == true) {  //if use lot sizing then apply shrinkage, EOQ,  ordering multiple and aggregation
                            // Aggregation
                            if (Aggregation != null) {
                                for (Integer j = at; j < mrpDemandList.size(); ++j) {
                                    if (demandList.Required_Date__c.daysbetween(mrpDemandList[j].Required_Date__c) > Aggregation) break;
                                    if (mrpDemandList[j].Modified_Quantity__c != null) 
                                        MRPQty = MRPQty + mrpDemandList[j].Modified_Quantity__c;
                                }
                            }
                            // Apply Shrinkage 
                            if (Shrinkage > 0.0) MRPQty = (double)math.round((MRPQty / (100.0 - Shrinkage)) * 100.0);
                            // Apply EOQ            
                            if (MRPQty < EOQ) MRPQty = EOQ;
                            //Apply Order Multiple 
                            if (OrderingMultiple > 0.0) {
                            // KNDY-3020 round up if fractional quantity less than .5
                                Decimal MRPQtyRound = math.round(MRPQty);
                                if (MRPQty > MRPQtyRound ) MRPQty = MRPQtyRound + 1.0;
                                else MRPQty = MRPQtyRound;
                            
                                multRem = (double)math.mod((long)MRPQty, (long)OrderingMultiple);
                                if (multRem > 0.0) MRPQty = MRPQty + (OrderingMultiple - multRem);
                            }  
                        }
                                            
                        //if order multiple or aggragation adds to the supply
                        if(MRPQty - remainingDemand>0) remainingSupply=MRPQty - remainingDemand;
                                                         
                        MRP__c planObj=new MRP__c();
                        planObj.Company__c=demandList.Company__c;
                        planObj.Facility__c = facilityID;
                        // PTM-373 added MRP lookup to Facility_Item__c
                        planObj.Facility_Item__c = facilityItemID;
// KNDY-6125 lookup to MRP_Run  
                        planObj.MRP_Run__c = mrpRunID;                    
                        planObj.Item__c=demandList.Item__c;
                        planObj.Demand__c=demandList.Demand__c;
                        planObj.Quantity__c=MRPQty;
                        planObj.Modified_Quantity__c=MRPQty;
// PTM-213 next level where required
// KNDY-6607 add MRPRunID to unique key
                        mrpUnique = SmrpRunID + demandList.Item__c + strDateTime + string.valueOf(i);
                        planObj.MRP_Unique__c = mrpUnique;
                        planObj.Where_Required__c=demandList.Where_Required__c;
                        
                        // Planned MRP's Next Level MRP field points to the corresponding Demand MRP record
                        MRP__c planObjUniqueTmp = new MRP__c (MRP_Unique__c = mrpUnique ) ;
                        MRP__c tmpMRP = new MRP__c (MRP_Unique__c=dmdMRPUnique) ;
                        planObjUniqueTmp.Next_Level_MRP__r = tmpMRP ;
                        planObj.Next_Level_MRP__r = tmpMRP ;
                        
                        
                        if (Source == 'Purchased') {
                            // PTM-378 PO Required date needs to use receiving date
                            planObj.Required_Date__c = KSE.calculateStartDate(demandList.Required_Date__c, 0, RcalID);
                            planObj.Start_Date__c = KSE.calculateStartDate(planObj.Required_Date__c, LeadTime, RcalID);
                        }
                        else {
                            planObj.Required_Date__c = demandList.Required_Date__c;
                            planObj.Start_Date__c = KSE.calculateStartDate(planObj.Required_Date__c, LeadTime, PcalID); 
//  PTM-83 Need to move the start and end date if the start is inside the planning time fence                    
                            if (MRP_Planning_Time_Fence_in_Days != null && planObj.Start_Date__c < MRP_Planning_Time_Fence_in_Days) {
                                planObj.Start_Date__c = MRP_Planning_Time_Fence_in_Days;
                                planObj.Required_Date__c = KSE.calculateEndDate(MRP_Planning_Time_Fence_in_Days, LeadTime, PcalID);
                            }
                        }
                    
                        planObj.Sequence__c=i++;      //sequence in which the MRP plans are created for each item
// PTM-213 Order Forecast lookup                    
                        planObj.Order_Forecast__c = demandList.Order_Forecast__c;
                        planObj.Planned__c=true;
                        balance = balance + MRPQty;
                        planObj.Balance__c = balance;
/* PTM-213 next level where required requires a planned record for Phantoms                    
                        if (Source != 'Phantom') planList.add(planObj);  // KNDY-3297 don't create planned orders for Phantoms */
                        
                        if (demandList.Next_Level_Item_Specification__c != null)
                            planObj.Next_Level_Item_Specification__c = demandList.Next_Level_Item_Specification__c;  // KNDY-10646
                        planList.add(planObj);
                    
                        //explode the assembly only if it has level > 0 and source is not purchased
                        if(demandList.Level__c > 0 && Source !='Purchased' && assemblyMap.get(demandList.Item__c) != null){
                       
                            // find the correct assembly by Start date
                            assyID = null;
                            for (Item_Specification__c itemSpec : assemblyMap.get(demandList.Item__c)) {
                                if (itemSpec.Start_Date2__c.date() > planObj.Start_Date__c) continue;
                                assyID = itemSpec.ID;
                                break;
                            }
                            // KNDY-6256 Item Spec with no valid components
                            if (assyID != null && itemComponentMap.get(assyID) != null) {
                                integer lt;
                                for(Component__c componentObj:itemComponentMap.get(assyID)){                        
                                    MRP__c mrpTempComponentDemand=new MRP__c();
                                    mrpTempComponentDemand.Company__c=demandList.Company__c;
                                    mrpTempComponentDemand.Facility__c = facilityID;
// KNDY-6125 lookup to MRP_Run  
                                    mrpTempComponentDemand.MRP_Run__c = mrpRunID;                                
                                    mrpTempComponentDemand.Item__c=componentObj.Component_Item__c;
                                    mrpTempComponentDemand.Demand__c=demandList.Demand__c;
                                    mrpTempComponentDemand.Quantity__c=MRPQty*componentObj.Quantity_Per_Assembly__c;
                                    if(componentObj.Yield__c!=null) {
                                        mrpTempComponentDemand.Modified_Quantity__c=((mrpTempComponentDemand.Quantity__c)*100)/componentObj.Yield__c;
                                        mrpTempComponentDemand.Quantity__c = mrpTempComponentDemand.Modified_Quantity__c;
                                    }
                                    else
                                        mrpTempComponentDemand.Modified_Quantity__c=mrpTempComponentDemand.Quantity__c;
                         /* KNDY-3008 use planned record dates */                            
                                    mrpTempComponentDemand.Required_Date__c = planObj.Start_Date__c;
                                
                                    lt = integer.valueof(componentObj.Component_Item__r.Lead_Time__c);
                                    if (facilityID != null) { // by facility
                                        if (facilityItemMap.containsKey(componentObj.Component_Item__c)) {
                                            Facility_Item__c fi = facilityItemMap.get(componentObj.Component_Item__c);
                                            lt = integer.valueof(fi.Lead_Time__c);
                                        }
                                    }
                                    if (componentObj.Component_Item__r.Source__c == 'Purchased')
                                        mrpTempComponentDemand.Start_Date__c = KSE.calculateStartDate(planObj.Start_Date__c, lt,RcalID);
                                    else mrpTempComponentDemand.Start_Date__c = KSE.calculateStartDate(planObj.Start_Date__c, lt,PcalID);
// PTM-213 next level where required
                                    MRP__c uID = new MRP__c(MRP_Unique__c = mrpUnique);
                                    mrpTempComponentDemand.Next_Level_MRP__r = uID;
// KNDY-6539 pass the Order Forecast to component records                                
                                    mrpTempComponentDemand.Order_Forecast__c = demandList.Order_Forecast__c;
                                    mrpTempComponentDemand.Where_Required__c=demandList.Where_Required__c;
                                    mrpTempComponentDemand.Is_Demand__c=true;                                                                                  
                                    mrpTempComponentDemand.Next_Level_Item_Specification__c = assyID;  // KNDY-10646
                                    mrpTempList.add(mrpTempComponentDemand);
                                }
                            }
                        }   
                    }          
                }
// sequence remaining supply              
                if(supplyMap.get(itemSetObj.Id)!=null){

                    for(MRP__c supplyList:supplyMap.get(itemSetObj.Id)){ //iterate through the list of supplies available for this item
                        if(!mrpSupplySet.contains(supplyList.Id)){                                
                            mrpSupplySet.add(supplyList.Id);
                            MRP__c seqSupplyObj=new MRP__c(Id=supplyList.Id);
                            seqSupplyObj.Sequence__c=i++;
                            seqSupplyObj.MRP_Need_Date__c = futureNeedDate;
                            balance = balance + SupplyList.Modified_Quantity__c;
                            seqSupplyObj.Balance__c = balance;
                            mrpUpdateList.add(seqSupplyObj);
                        }
                    }
                } 
            }
        }
        catch (Exception e) {
            errMsg = errMsg +e.getMessage()+','+e.getStackTraceString();
            throw e;
        }
        
        DML.updateAsUser(mrpUpdateList);
        DML.insertAsUser(planList);//insert 
        DML.insertAsUser(mrpTempList);// insert all components
        
        }    


    public void finish(Database.BatchableContext info){ 
        
        String msg;
        
        if (errmsg.length() > 0) {
            //show MRP completed
            MRPService.mrp_complete(cfID);
            
            msg = 'MRPPlanData for run: ' +mrpRun[0].Name +' Failed with error: ' +errMsg;
            Notify.sendEmailBatchFinish( null, msg, info);        
            // PTM-377 MRP_Run status
            mrpRun[0].Completion_Status__c = 'Failure';
            mrpRun[0].Failure_Message__c = errMsg;
            DML.updateAsUser(mrpRun);
            
        }
        
        //initiate the next job to initiate demand processing for next level down
        
        else if(nextLevel-1>=0){
                // PTM-765 user defined batch size
                integer defaultBatchSize = 1;
                MRP_Batch_Sizes__c mrpbs = MRP_Batch_Sizes__c.getInstance('GenerateMRPPlanData');
                if (mrpbs != null) defaultBatchSize = integer.valueOf(mrpbs.Batch_Size__c);
                
                GenerateMRPPlanData obj=new GenerateMRPPlanData(nextLevel-1, this.mrpRunID, this.PcalID, this.RcalID);
                Id jobId=Database.executeBatch(obj, defaultBatchSize); 
            }else{
            //send completion email
                MRPService.mrp_complete(cfID);
                msg = 'MRP Run: ' +mrpRun[0].Name + ' Generation Completed';
                Notify.sendEmailBatchFinish( null, msg, info); 
                // PTM-377 MRP_Run status
                mrpRun[0].Completion_Status__c = 'Complete';
                DML.updateAsUser(mrpRun);
           
                MasterControlProgram.finishedBatch( this );
            
        }
    }
}