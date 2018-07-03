/**
 * @Author : MG
 * @Description : This class is initiated from erase MRP process and create a snapshot from the SKID object
 * Criteria : Items that are active, not non-inventory, order date ,Quantity not zero and MRP Nettable=true
 */
public with sharing class GenerateMRPTempData implements Database.batchable<sObject>,Database.Stateful{

    Date todaysDate;
    public String query;
    public Id companyId;
    public ID facilityID;
    public ID mrpRunID, PcalID, RcalID;
    List<MRP_Run__c> mrpRun = new List<MRP_Run__c>();
    public String errMsg;
    
    final String WOM_DEMAND = 'WOM Demand' ;
    final String SO_DEMAND  = 'SO Demand' ;
    final String PO_SUPPLY  = 'PO Supply' ;
    final String WO_SUPPLY  = 'WO Supply' ;
    
    MRPSettingsService MRPService = new MRPSettingsService();
//  PTM-153 combine Facility and Company ID to allow simultaneous Facility MRPs to run
    String cfID;
    
    Boolean Use_Order_Forecast_as_Demand_in_MRP, Use_Sales_Orders_as_Demand_in_MRP, 
            Use_Work_Orders_as_Demand_in_MRP, Use_Purchase_Orders_as_Supply_in_MRP,
            Use_Work_Orders_as_Supply_in_MRP;
    Date MRP_Backward_Horizon_Date, MRP_Demand_Time_Fence_in_Days, MRP_Forward_Horizon_Date;
        
    Set <ID> itemSet = new Set <ID>();
    List<MRP__c> insertList=new list<MRP__c>();
    
    public GenerateMRPTempData(Id mrpRID, ID PclID, ID RclID) {    
        this.mrpRunID = mrpRID;
        this.PcalID = PclID;
        this.RcalID = RclID;
        
        errMsg = '';
        
        todaysDate=KSE.calculateStartDate(Date.today(),0, PcalID);
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('MRP_Run__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'ID','Name','Company__c','Facility__c','MRP_Backward_Horizon_in_Days__c','MRP_Demand_Time_Fence_in_Days__c','MRP_Forward_Horizon_in_Days__c',
	'Order_Forecast_as_Demand__c','Purchase_Orders_as_Supply__c','Sales_Orders_as_Demand__c','Work_Orders_as_Demand__c','Work_Orders_as_Supply__c'
});
soql.setWhereClause('ID =: mrpRunID');
mrpRun = Database.query(soql.getQuery());


        this.companyID = mrpRun[0].Company__c;
        this.facilityID = mrpRun[0].Facility__c;
        
        if (facilityID == null) cfID = companyID;
        else cfID = companyID +'-' +facilityID;
        
        if (mrpRun[0].MRP_Backward_Horizon_in_Days__c == null || mrpRun[0].MRP_Backward_Horizon_in_Days__c <= 0)
            MRP_Backward_Horizon_Date = date.newInstance(1700, 1, 1);   
        else MRP_Backward_Horizon_Date = todaysDate - (integer)mrpRun[0].MRP_Backward_Horizon_in_Days__c;
            
        if (mrpRun[0].MRP_Demand_Time_Fence_in_Days__c == null || mrpRun[0].MRP_Demand_Time_Fence_in_Days__c <= 0)
            MRP_Demand_Time_Fence_in_Days = MRP_Backward_Horizon_Date;   
        else MRP_Demand_Time_Fence_in_Days = todaysDate + (integer)mrpRun[0].MRP_Demand_Time_Fence_in_Days__c;
            
        if (mrpRun[0].MRP_Forward_Horizon_in_Days__c == null || mrpRun[0].MRP_Forward_Horizon_in_Days__c <= 0)
            MRP_Forward_Horizon_Date = date.newInstance(4000, 12, 31);   
        else MRP_Forward_Horizon_Date = todaysDate + (integer)mrpRun[0].MRP_Forward_Horizon_in_Days__c;
            
        Use_Order_Forecast_as_Demand_in_MRP = mrpRun[0].Order_Forecast_as_Demand__c;
        Use_Purchase_Orders_as_Supply_in_MRP = mrpRun[0].Purchase_Orders_as_Supply__c;
        Use_Sales_Orders_as_Demand_in_MRP = mrpRun[0].Sales_Orders_as_Demand__c;
        Use_Work_Orders_as_Demand_in_MRP = mrpRun[0].Work_Orders_as_Demand__c;
        Use_Work_Orders_as_Supply_in_MRP = mrpRun[0].Work_Orders_as_Supply__c;
        
        query = 'select ID from Item__c where Company__c =: companyId and Active__c = true and Non_Inventory__c <> true';       
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        System.assert( this.companyId != null, 'GenerateMRPTempData expected companyId to be set');
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Item__c> itemObjList){
        execute( itemObjList );
    }
    
    public void execute(List<Item__c> itemObjList){    
        
        try {
            
            // create item set
            itemSet.clear();
            for (Item__c itemObj:itemObjList){
                itemSet.add(itemObj.ID);
            }
        
            insertList = new List<MRP__C>();
        
            if (Use_Order_Forecast_as_Demand_in_MRP) {
              /*  query = 'select ID, Name, Plan_Date__c, Item__c, Remaining_Quantity__c '+
                        'from Order_Forecast__c '+
                        'where Plan_Date__c >=: MRP_Demand_Time_Fence_in_Days and '+
                        'Plan_Date__c <=: MRP_Forward_Horizon_Date and '+
                        'Remaining_Quantity__c > 0 and '+
                        'Item__c in: itemSet';            
                if (facilityID == null) query = query + ' and Facility__c = null';
                else query = query + ' and Facility__c =: facilityID';*/
                

                
                String whereClause = 'Plan_Date__c >=: MRP_Demand_Time_Fence_in_Days and '+
                        'Plan_Date__c <=: MRP_Forward_Horizon_Date and '+
                        'Remaining_Quantity__c > 0 and '+
                        'Item__c in: itemSet';//KNDY-8796
                if (facilityID == null) {whereClause = whereClause + ' and Facility__c = null';}
                else {whereClause = whereClause + ' and Facility__c =: facilityID';}
                
                SOQLUtil soql = new SOQLUtil('Order_Forecast__c',true);
                soql.addFields(new Set<String>{'ID','Name','Plan_Date__c','Item__c','Remaining_Quantity__c'});
                soql.setWhereClause(whereClause);
                
                
            
                //for (Order_Forecast__c ofObj : Database.Query(query)){
                for (Order_Forecast__c ofObj : Database.Query(soql.getQuery())){
                    MRP__c mrpObj = new MRP__c();
                    mrpObj.Company__c = companyId; 
                    mrpObj.Facility__c = facilityId;
// KNDY-6125 lookup to MRP_Run                  
                    mrpObj.MRP_Run__c = mrpRunID;
                    mrpObj.Item__c = ofObj.Item__c;
                    mrpObj.Quantity__c = ofObj.Remaining_Quantity__c;
                    mrpObj.Modified_Quantity__c = ofObj.Remaining_Quantity__c;
                    if(!KSE.isFieldEmpty('Plan_Date__c',ofObj)) {                 
                        mrpObj.Required_Date__c = ofObj.Plan_Date__c;
                    }
                    else {
                        mrpObj.Required_Date__c = todaysDate;
                    }
                    mrpObj.Is_Demand__c = true;
                    mrpObj.Where_Required__c = null;
// PTM-213 lookup to order forecast                
                    mrpObj.Demand__c = 'Order Forecast';
                    mrpObj.Order_Forecast__c = ofObj.ID;
                    mrpObj.Planned__c = false;
                    insertList.add(mrpObj);
                }
            }
        	
        	//KNDY-10924
            // Generating SO Demands
            if (Use_Sales_Orders_as_Demand_in_MRP) generate_so_demand();
        	
        	// Generating WOM Demands
        	if (Use_Work_Orders_as_Demand_in_MRP) generate_wom_demand();
        	
        	// Generating PO Supply
            if (Use_Purchase_Orders_as_Supply_in_MRP) generate_po_supply();
            
            // Generating WO Supply
        	if (Use_Work_Orders_as_Supply_in_MRP) generate_wo_supply();
        	
        	/*if (Use_Sales_Orders_as_Demand_in_MRP) generate_temp('SO Demand');
        
            if (Use_Work_Orders_as_Demand_in_MRP) generate_temp('WOM Demand');
                 
            if (Use_Purchase_Orders_as_Supply_in_MRP) generate_temp('PO Supply');
        
            if (Use_Work_Orders_as_Supply_in_MRP) generate_temp('WO Supply');*/
        }
        catch (Exception e) {
            errMsg = errMsg +e.getMessage()+','+e.getStackTraceString();
            throw e;
        }
              
        DML.insertAsUser(insertList);  //KNDY-3586
    }
    
    //KNDY-10924  
    /*public void generate_temp(String dstype) {
        
// PTM-519 remove use of Is_Demand        
       // query = 'select ID, Item__c, Order_Date__c, Quantity__c, Type__c, Work_Order__r.Start_Date2__c '+
       //         'from SKID__c '+
       //         'where Order_Date__c >=: MRP_Backward_Horizon_Date and '+
       //         'Order_Date__c <=: MRP_Forward_Horizon_Date and '+
       //         'Quantity__c > 0 and '+
       //         'Type__c = \'';
       //         query = query + dstype;
       //         query = query + '\' and Item__c in: itemSet';
       // if (facilityID != null) query = query + ' and Location__r.Facility__c =: facilityID';
                  // KNDY-3535 Check to make sure the order is open
       // if (dstype == 'SO Demand') query = query +' and Sales_Order_Line__r.Sales_Order__r.Status__c = \'Open\'';
       // else if (dstype == 'PO Supply') query = query +' and Purchase_Order_Line__r.Purchase_Order__r.Status__c = \'Open\'';
       // else if (dstype == 'WOM Demand' || dstype == 'WO Supply') 
       //          query = query +' and Work_Order__r.Status__c in (\'Scheduled\', \'Released\', \'In Process\')';
        
         String whereClause = 'Order_Date__c >=: MRP_Backward_Horizon_Date and '+
                                'Order_Date__c <=: MRP_Forward_Horizon_Date and '+
                                'Quantity__c > 0 and '+
                                'Type__c = \'';//KNDY-8796
        whereClause = whereClause + dstype;
                whereClause = whereClause + '\' and Item__c in: itemSet';
        if (facilityID != null) whereClause = whereClause + ' and Location__r.Facility__c =: facilityID';
                  // KNDY-3535 Check to make sure the order is open
        if (dstype == 'SO Demand') whereClause = whereClause +' and Sales_Order_Line__r.Sales_Order__r.Status__c = \'Open\'';
        else if (dstype == 'PO Supply') whereClause = whereClause +' and Purchase_Order_Line__r.Purchase_Order__r.Status__c = \'Open\'';
        else if (dstype == 'WOM Demand' || dstype == 'WO Supply') 
                 whereClause = whereClause +' and Work_Order__r.Status__c in (\'Scheduled\', \'Released\', \'In Process\')';

         SOQLUtil soql = new SOQLUtil('SKID__c',true);
         soql.addFields(new Set<String>{'ID','Item__c','Order_Date__c','Quantity__c','Type__c','Work_Order__r.Start_Date2__c'});
         soql.setWhereClause(whereClause);
        
        
        //for (SKID__c skidObj : Database.Query(query)) {
        for (SKID__c skidObj : Database.Query(soql.getQuery())) {    
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=companyId;
            mrpObj.Facility__c = facilityID;
// KNDY-6125 lookup to MRP_Run  
            mrpObj.MRP_Run__c = mrpRunID;
            mrpObj.Item__c=skidObj.Item__c;
            mrpObj.Quantity__c=skidObj.Quantity__c;
            mrpObj.Modified_Quantity__c=skidObj.Quantity__c;
            if(!KSE.isFieldEmpty('Order_Date__c',skidObj)) {
                mrpObj.Required_Date__c = skidObj.Order_Date__c;
            }
            else {
                mrpObj.Required_Date__c = todaysDate;
            }            
// PTM-519 remove use of Is_Demand
            if (skidObj.Type__c == 'WOM Demand' && skidObj.Work_Order__r.Start_Date2__c != null) {
                mrpObj.Start_Date__c = skidObj.Work_Order__r.Start_Date2__c.date();
            }
            else {            
                mrpObj.Start_Date__c = null;
            }
// PTM-519 remove use of Is_Demand            
            if (skidObj.Type__c == 'SO Demand' || skidObj.Type__c == 'WOM Demand') mrpObj.Is_Demand__c = true;
            else mrpObj.Is_Demand__c = false;
            mrpObj.Where_Required__c=skidObj.Id;
            mrpObj.Demand__c=skidobj.Type__c;
            mrpObj.Order_Forecast__c = null;
            mrpObj.Planned__c = false;
            insertList.add(mrpObj);
        }
    }*/
    
    //KNDY-10924
    // Generating WOM Demand from Material Tracking records
    private void generate_wom_demand () {
    	Decimal leadTime = 0 ;
    	Map<Id,Decimal> facilityItemLeadTimes = new Map<Id,Decimal> () ;
    	
    	String sobjectType = 'Material_Tracking__c';
        Set<String> sobjFields = new Set<String> {'Id','Item__c','Item__r.Lead_Time__c','Required_Date__c','Quantity_Short__c',
            									   'Type__c', 'Work_Order__c' , 'Work_Order__r.Need_Date2__c'} ;
        
        //KNDY-12053
        String whereClause = ' Work_Order__r.Need_Date2__c >= :MRP_Backward_Horizon_Date and ' +
								'Work_Order__r.Need_Date2__c <= : MRP_Forward_Horizon_Date and '+
								'Quantity_Required__c > 0 and '+
								'Work_Order__r.Status__c in (\'Scheduled\', \'Released\', \'Picklist\', \'Kitted\', \'In Process\') and '+
								'Item__r.Active__c = true and '+ 
								'Item__r.Non_Inventory__c <> true and '+
								'Work_Order__r.Company__c = :companyId ' ;
		whereClause = whereClause + ' and Item__c in: itemSet';
		if (facilityID != null ) {
			whereClause += ' and Work_Order__r.Facility__c = :facilityID';
			
			
			SOQLUtil fiSoql = new SOQLUtil('Facility_Item__c', true); 
            fiSoql.addFields(new set<string>{'ID','Item__c','Lead_Time__c'});
            fiSoql.setWhereClause('Active__c = true and Facility__c =: facilityID and Item__c =:itemSet AND Company__c =:companyId'); 
            
            for (Facility_Item__c fi : Database.query(fiSoql.getQuery())){
                if(!KSE.isFieldEmpty('Lead_Time__c',fi )) {
                    facilityItemLeadTimes.put ( fi.Item__c , fi.Lead_Time__c ) ;
                }
                else {
                    facilityItemLeadTimes.put ( fi.Item__c , 0 ) ;
                }
            }
		} 
					
		SOQLUtil soql = new SOQLUtil(sobjectType,true);
        soql.addFields(sobjFields);
        soql.setWhereClause(whereClause);
        List<Material_Tracking__c> lstMaterialTracking = Database.Query(soql.getQuery()) ;
         
        if ( lstMaterialTracking != null && lstMaterialTracking.size() > 0 )  {
            // KNDY-12053 Calculate the lead time for facility items
            for (Material_Tracking__c matlTracking :lstMaterialTracking ) {    
                MRP__c mrpObj=new MRP__c();
                mrpObj.Company__c=companyId;
                mrpObj.Facility__c = facilityID;
    			mrpObj.MRP_Run__c = mrpRunID;
                mrpObj.Item__c=matlTracking.Item__c;
                mrpObj.Quantity__c=matlTracking.Quantity_Short__c;
                mrpObj.Modified_Quantity__c=matlTracking.Quantity_Short__c;
                
                // KNDY-12053
                //KNDY-12109 - Use required date from material tracking
                if(!KSE.isFieldEmpty('Required_Date__c',matlTracking)) {
                    mrpObj.Required_Date__c = matlTracking.Required_Date__c.date();
                }
                else {
                    mrpObj.Required_Date__c = todaysDate;
                }   
                
                // KNDY-12053
                //KNDY-12109 - Use required date from material tracking
                if ( matlTracking.Required_Date__c != null ) {
                    if ( facilityID != null && facilityItemLeadTimes.containsKey( matlTracking.Item__c) ) {
                        // when lead time is coming from the facility item
                        leadTime = facilityItemLeadTimes.get( matlTracking.Item__c) ;
                    }
                    else if(!KSE.isFieldEmpty('Lead_Time__c',matlTracking.Item__r )) {
                        // when the lead time is company wide
                        // also when there is no lead time on facility item; fallback
                        leadTime = matlTracking.Item__r.Lead_Time__c;
                    }
                    else {
                        // No lead time 
                        leadTime = 0;
                    }
                    
                    // calculating start date based on the lead times 
                    // assuming that lead time is always a rounded value
    				mrpObj.Start_Date__c = KSE.calculateStartDate ( mrpObj.Required_Date__c , leadTime.intValue() , this.PcalID  ) ;
                }
                mrpObj.Is_Demand__c = true;
                mrpObj.Material_Tracking__c=matlTracking.Id;
                mrpObj.Sales_Order_Line__c=null;
                mrpObj.Purchase_Order_Line__c=null;
                mrpObj.Work_Order__c=null;
                mrpObj.Demand__c= WOM_DEMAND;  
                mrpObj.Order_Forecast__c = null;
                mrpObj.Planned__c = false;
                insertList.add(mrpObj);
            }
        }
    } 
    
    // Generating SO Demand for Open sales order lines
    private void generate_so_demand () {
    	String sobjectType = 'Sales_Order_Line__c';
        Set<String> sobjFields = new Set<String> {'Id','Product__r.Item__c','Product__r.Item__r.Stocking_UOM__c',
        										'Quantity_Backordered__c','Required_Date__c','Selling_UOM__c', 
        										'Product__r.Item__r.Packaging_UOM__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c' } ;
        String whereClause = ' Required_Date__c >= :MRP_Backward_Horizon_Date and ' +
								'Required_Date__c <= : MRP_Forward_Horizon_Date and '+
								'Quantity_Backordered__c > 0.0 and '+
								'Status__c = \'Open\' and '+
								'Sales_Order__r.Status__c = \'Open\' and '+
								'Product__r.Item__r.Active__c = true and '+ 
								'Product__r.Item__r.Non_Inventory__c <> true and '+
								'Company__c = :companyId ' ;
		whereClause = whereClause + ' and Product__r.Item__c in: itemSet';
		if (facilityID != null ) {
			whereClause += ' and Ship_From_Location__r.Facility__c = :facilityID ';
		}
		SOQLUtil soql = new SOQLUtil(sobjectType,true);
        soql.addFields(sobjFields);
        soql.setWhereClause(whereClause);
        
        for (Sales_Order_Line__c soLine : Database.Query(soql.getQuery())) {
			// Getting the conversion factor for pol
			Decimal conversionFactor = KSE.getConversionFactor(soLine) ;
			    
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=companyId;
            mrpObj.Facility__c = facilityID;
			mrpObj.MRP_Run__c = mrpRunID;
            mrpObj.Item__c=soLine.Product__r.Item__c;
            mrpObj.Quantity__c=soLine.Quantity_Backordered__c * conversionFactor ;
            mrpObj.Modified_Quantity__c=soLine.Quantity_Backordered__c * conversionFactor ;
            if(!KSE.isFieldEmpty('Required_Date__c',soLine)) {
                mrpObj.Required_Date__c = soLine.Required_Date__c;
            }
            else {
                mrpObj.Required_Date__c = todaysDate;
            }            
			mrpObj.Start_Date__c = null ;
            mrpObj.Is_Demand__c = true;
            mrpObj.Material_Tracking__c=null;
            mrpObj.Sales_Order_Line__c = soLine.Id ;
            mrpObj.Purchase_Order_Line__c=null;
            mrpObj.Work_OrdeR__c=null;
            mrpObj.Demand__c= SO_DEMAND;
            mrpObj.Order_Forecast__c = null;
            mrpObj.Planned__c = false;
            insertList.add(mrpObj);
        }
    } 
    
    // Generating PO Supply for Open Purchase Order Lines
    private void generate_po_supply () {
    	String sobjectType = 'Purchase_Order_Line__c';
        Set<String> sobjFields = new Set<String> {'Id','Item__c','Item__r.Stocking_UOM__c','Quantity_Still_Due__c',
                                            'Need_Date__c','Purchase_UOM__c', 'Item__r.Packaging_UOM__c', 'Delivery_Facility__r.Facility_Identifier__c' } ;
        String whereClause = ' Need_Date__c >= :MRP_Backward_Horizon_Date and ' +
								'Need_Date__c <= : MRP_Forward_Horizon_Date and '+
								'Quantity_Still_Due__c > 0.0 and '+
								'Status__c = \'Open\' and '+
								'Purchase_Order__r.Status__c = \'Open\' and '+
								'Item__r.Active__c = true and '+ 
								'Item__r.Non_Inventory__c <> true and '+
								'Company__c = :companyId ' ;
		whereClause = whereClause + ' and Item__c in: itemSet';
		if (facilityID != null ) {
			whereClause += ' and Delivery_Location__r.Facility__c = :facilityID ';
		}
			
		SOQLUtil soql = new SOQLUtil(sobjectType,true);
        soql.addFields(sobjFields);
        soql.setWhereClause(whereClause);
        
        for (Purchase_Order_Line__c pol : Database.Query(soql.getQuery())) {
			// Getting the conversion factor for pol
			Decimal conversionFactor = KSE.getConversionFactor(pol) ;
			    
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=companyId;
            mrpObj.Facility__c = facilityID;
			mrpObj.MRP_Run__c = mrpRunID;
            mrpObj.Item__c=pol.Item__c;
            mrpObj.Quantity__c=pol.Quantity_Still_Due__c * conversionFactor ;
            mrpObj.Modified_Quantity__c=pol.Quantity_Still_Due__c * conversionFactor ;
            if(!KSE.isFieldEmpty('Need_Date__c',pol)) {
                mrpObj.Required_Date__c = pol.Need_Date__c;
            }
            else {
                mrpObj.Required_Date__c = todaysDate;
            }            
			mrpObj.Start_Date__c = null ;
            mrpObj.Is_Demand__c = false;
            mrpObj.Material_Tracking__c=null;
            mrpObj.Sales_Order_Line__c = null ;
            mrpObj.Purchase_Order_Line__c=pol.Id;
            mrpObj.Work_Order__c=null;
            mrpObj.Demand__c= PO_SUPPLY ;
            mrpObj.Order_Forecast__c = null;
            mrpObj.Planned__c = false;
            insertList.add(mrpObj);
        }
    } 
    
    // Generating WO Supply for Work Orders that are still to be completed
    private void generate_wo_supply () {
    	String sobjectType = 'Work_Order__c';
        Set<String> sobjFields = new Set<String> {'Id','Assembly_Item_Specification__r.Item__c','Quantity_to_Complete__c','Need_Date2__c','Start_Date2__c'} ;
        String whereClause = ' Need_Date2__c >= :MRP_Backward_Horizon_Date and ' +
								'Need_Date2__c <= : MRP_Forward_Horizon_Date and '+
								'Status__c in (\'Scheduled\', \'Released\', \'Picklist\', \'Kitted\', \'In Process\') and '+
								'Quantity_to_Complete__c > 0.0 and '+
								'Assembly_Item_Specification__r.Item__r.Active__c = true and '+ 
								'Assembly_Item_Specification__r.Item__r.Non_Inventory__c <> true and '+
								'Company__c = :companyId ' ;
		whereClause = whereClause + ' and Assembly_Item_Specification__r.Item__c in: itemSet';
		if (facilityID != null ) {
			whereClause += ' and Complete_to_Location__r.Facility__c = :facilityID ';
		} 
				
		SOQLUtil soql = new SOQLUtil(sobjectType,true);
        soql.addFields(sobjFields);
        soql.setWhereClause(whereClause);
        
        
		for (Work_Order__c wo : Database.Query(soql.getQuery())) {    
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=companyId;
            mrpObj.Facility__c = facilityID;
			mrpObj.MRP_Run__c = mrpRunID;
            mrpObj.Item__c=wo.Assembly_Item_Specification__r.Item__c;
            mrpObj.Quantity__c=wo.Quantity_to_Complete__c;
            mrpObj.Modified_Quantity__c=wo.Quantity_to_Complete__c;
            if(!KSE.isFieldEmpty('Need_Date2__c',wo)) {
                mrpObj.Required_Date__c = wo.Need_Date2__c.date();
            }
            else {
                mrpObj.Required_Date__c = todaysDate;
            }            
			mrpObj.Start_Date__c = null ;
            mrpObj.Is_Demand__c = false;
            mrpObj.Material_Tracking__c=null;
            mrpObj.Sales_Order_Line__c = null ;
            mrpObj.Purchase_Order_Line__c=null;
            mrpObj.Work_Order__c=wo.Id;
            mrpObj.Demand__c=WO_SUPPLY;
            mrpObj.Order_Forecast__c = null;
            mrpObj.Planned__c = false;
            insertList.add(mrpObj);
        }
    }
    
    public void finish(Database.BatchableContext info){ 
        
        String msg;
        integer maxLevel=0;
        
        if (errmsg.length() > 0) {
            //show MRP completed
            MRPService.mrp_complete(cfID);
            
            msg = 'MRPTemData for run: ' +mrpRun[0].Name +' Failed with error: ' +errMsg;
			Notify.sendEmailBatchFinish( null, msg, info);        

            // PTM-377 MRP_Run status
            mrpRun[0].Completion_Status__c = 'Failure';
            mrpRun[0].Failure_Message__c = errMsg;
            DML.updateAsUser(mrpRun);
        }
        else {
            MRPService.mrp_temped(cfID);
         
            //find the max level from the MRPTemp and start with the demands from the top



/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('MRP__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Level__c'
});
soql.setWhereClause('MRP_Run__c =: mrpRunID');
soql.setOrderByClause('Level__c desc');
soql.setLimit(1);
List<MRP__c> m = Database.query(soql.getQuery());


            if (m.size() != 0) maxLevel = integer.valueof(m[0].Level__c);
            else maxLevel = 0;

            if ( maxLevel>=0 ) {
                if ( ! Test.isRunningTest() ) {  // cannot chain our batches if we are in a test 
                    // PTM-765 user defined batch size
                    integer defaultBatchSize = 1;
                    MRP_Batch_Sizes__c mrpbs = MRP_Batch_Sizes__c.getInstance('GenerateMRPPlanData');
                    if (mrpbs != null) defaultBatchSize = integer.valueOf(mrpbs.Batch_Size__c);
                    
                    GenerateMRPPlanData obj=new GenerateMRPPlanData(maxLevel, this.mrpRunID, this.PcalID, this.RcalID);
                    Id jobId=Database.executeBatch(obj, defaultBatchSize);
                } 
            }
        }
    }
}