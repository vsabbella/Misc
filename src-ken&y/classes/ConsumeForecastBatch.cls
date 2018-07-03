public with sharing class ConsumeForecastBatch implements Database.batchable<sObject>,Database.stateful, Process.Runnable2 {
  
    public string query;
    public Id companyId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public Map<string,list<Order_Forecast__c>> custIdToOf = new Map<string,list<Order_Forecast__c>>();
    public Map<Id,Order_Forecast__c > ofIdToOf = new Map<Id,Order_Forecast__c>();
    public set<id> itemSet = new set<id>();
    public List<String> statusList = new List<String>{'Standard','Drop Ship'};
    public void runBatch( Process_Job__c job ) {      // Process.Runnable implementation 
//KNDY-7274 need to pass in CompanyID
        ConsumeForecastBatch obj = new ConsumeForecastBatch(job.Company__c);
        
        integer defaultBatchSize = 1;
          if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 10 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
               defaultBatchSize = integer.valueOf(job.Batch_Size__c);
          }
          
        Id jobId=Database.executebatch(obj, defaultBatchSize);
    }

    public ConsumeForecastBatch() {}
    
    public ConsumeForecastBatch(ID cid) {
    //KNDY-7274 need to pass in CompanyID        
        CompanyID = cid;
        
        
        query= 'select ID, Name, Product__r.Item__c, Quantity_Ordered__c, Required_Date__c,Sales_Order__r.Customer__c ,Ship_From_Location__r.facility__c  ' +
                                            'from Sales_Order_Line__c '+
                                            'where Company__c =: companyID and '+
                                            'Quantity_Ordered__c > 0 and '+
                                            'Sales_Order__r.Status__c != \'Draft\' and '+
            								'Sales_Order__r.Type__c IN :statusList and '+
                                            'Required_Date__c != null  ' ;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        date min_start = null;
        date max_end = null;
        ID BlankCustId;
        BlankCustId = 'cust000000000BLANK';
        ID BlankFacId = 'facl000000000BLANK';
        string key;
        string bcustkey;
        string bfackey;
        string bcustfackey;
        SOQLUtil soql = new SOQLUtil('Order_Forecast__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Consumed_Quantity__c','Consumption_End_Date__c','Consumption_Start_Date__c','Facility__c', 
                                            'Forecast_Quantity__c','Item__c','Customer__c'
		});
		soql.setWhereClause('Consumption_End_Date__c != null and Consumption_Start_Date__c != null and Forecast_Quantity__c > 0');
		
       for (Order_Forecast__c ofObj :Database.query(soql.getQuery())) {
             itemSet.add(ofObj.Item__c);                                  
             if (ofObj.Consumption_Start_Date__c < min_start || min_start == null) {
                 min_start = ofObj.Consumption_Start_Date__c;
             }
             // PTM-767 max_end should be > not <
             if (ofObj.Consumption_End_Date__c > max_end || max_end == null) {
                 max_end = ofObj.Consumption_End_Date__c;
             }                                   
           
             ofObj.Consumed_Quantity__c = 0;
             if( ofObj.customer__c != null && ofObj.Facility__c != null){
                
                 
                 id cust = ofObj.Customer__c;
                 id item = ofObj.Item__c;
                 key = ofObj.Customer__c +'-'+ofObj.Item__c+'-'+ofObj.Facility__c;
                 
                 if(!custIdToOf.containsKey(key)){
                     custIdToOf.put(key, new list<Order_Forecast__c>());
                 }
                 
                custIdToOf.get(key).add(ofObj) ; 
                
             }else if(ofObj.customer__c != null && ofObj.Facility__c == null){
                 
                bfackey = ofObj.Customer__c +'-'+ofObj.Item__c+'-'+BlankFacId; 
                 
                 if(!custIdToOf.containsKey(bfackey)){
                     custIdToOf.put(bfackey, new list<Order_Forecast__c>());
                 }
                 
                custIdToOf.get(bfackey).add(ofObj) ;  
             } else if(ofObj.customer__c == null && ofObj.Facility__c != null){
                  bcustkey = BlankCustId +'-'+ofObj.Item__c+'-'+ofObj.Facility__c;
                  if(! custIdToOf.containsKey(bcustkey)){
                     custIdToOf.put(bcustkey, new list<Order_Forecast__c>());
                  }
                 
                custIdToOf.get(bcustkey).add(ofObj) ;
             }else if(ofObj.customer__c == null && ofObj.Facility__c == null){
                 
                 
                 bcustfackey = BlankCustId +'-'+ofObj.Item__c+'-'+BlankFacId;
                 
                 if(! custIdToOf.containsKey(bcustfackey)){
                     custIdToOf.put(bcustfackey, new list<Order_Forecast__c>());
                 }
                 
                custIdToOf.get(bcustfackey).add(ofObj) ; 
                
             }                                 
          }
        
        query += 'and  Required_Date__c >=: min_start and Required_Date__c <=: max_end and Product__r.Item__c in : itemSet' ;
        system.debug('query'+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Sales_Order_Line__c> scope){
        
        
        for(Sales_Order_Line__c solObj : scope){
            
            ID BlankCustId;
            BlankCustId = 'cust000000000BLANK';
            ID BlankFacId = 'facl000000000BLANK';
            string bcustkey;
          	string bfackey;
         	string bcustfackey;
            string key;
            bcustkey = BlankCustId +'-'+solObj.Product__r.Item__c+'-'+solObj.Ship_From_Location__r.facility__c;
            bcustfackey = BlankCustId +'-'+solObj.Product__r.Item__c+'-'+BlankFacId;
            bfackey =  solObj.Sales_Order__r.Customer__c +'-'+solObj.Product__r.Item__c+'-'+BlankFacId;
            if(solObj.Sales_Order__r.Customer__c != null && solObj.Product__r.Item__c != null && solObj.Ship_From_Location__r.facility__c != null){
               key = solObj.Sales_Order__r.Customer__c +'-'+solObj.Product__r.Item__c+'-'+solObj.Ship_From_Location__r.facility__c; 
               
            }
              
            
            if(custIdToOf.containsKey(key)){
                
                for(order_forecast__c o: custIdToOf.get(key)){
                 
                    if(ofIdToOf.containsKey(o.id)){
                        o.Consumed_Quantity__c = ofIdToOf.get(o.id).Consumed_Quantity__c;
                    }   
                    
                 if (solObj.Product__r.Item__c != o.Item__c ||
                     solObj.Required_Date__c < o.Consumption_Start_Date__c ||
                     solObj.Required_Date__c > o.Consumption_End_Date__c) continue;  
                   
                 o.Consumed_Quantity__c =   KSE.addQuantityToField(o.Consumed_Quantity__c, solObj.Quantity_Ordered__c);
                 ofIdToOf.put(o.id, o) ;
                    
                }
            
            } else if(custIdToOf.containsKey(bcustkey) && !custIdToOf.containsKey(Key)   )
            {
                for(order_forecast__c off: custIdToOf.get(bcustkey)){
                    if(ofIdToOf.containsKey(off.id)){
                        off.Consumed_Quantity__c = ofIdToOf.get(off.id).Consumed_Quantity__c;
                    } 
                 if (solObj.Product__r.Item__c != off.Item__c ||
                     solObj.Required_Date__c < off.Consumption_Start_Date__c ||
                     solObj.Required_Date__c > off.Consumption_End_Date__c) continue;  
                    
                 off.Consumed_Quantity__c = KSE.addQuantityToField(off.Consumed_Quantity__c, solObj.Quantity_Ordered__c);  
                 ofIdToOf.put(off.id, off) ;  
                  
                }
            } else if(custIdToOf.containsKey(bfackey) && !custIdToOf.containsKey(Key) )
            {
                for(order_forecast__c off: custIdToOf.get(bfackey)){
                    if(ofIdToOf.containsKey(off.id)){
                        off.Consumed_Quantity__c = ofIdToOf.get(off.id).Consumed_Quantity__c;
                    } 
                 if (solObj.Product__r.Item__c != off.Item__c ||
                     solObj.Required_Date__c < off.Consumption_Start_Date__c ||
                     solObj.Required_Date__c > off.Consumption_End_Date__c) continue;  
                    
                 off.Consumed_Quantity__c = KSE.addQuantityToField(off.Consumed_Quantity__c, solObj.Quantity_Ordered__c);  
                 ofIdToOf.put(off.id, off) ;  
                  
                }
            } else if(custIdToOf.containsKey(bcustfackey) && !custIdToOf.containsKey(Key) )
            {
                for(order_forecast__c off: custIdToOf.get(bcustfackey)){
                    if(ofIdToOf.containsKey(off.id)){
                        off.Consumed_Quantity__c = ofIdToOf.get(off.id).Consumed_Quantity__c;
                    } 
                 if (solObj.Product__r.Item__c != off.Item__c ||
                     solObj.Required_Date__c < off.Consumption_Start_Date__c ||
                     solObj.Required_Date__c > off.Consumption_End_Date__c) continue;  
                    
                 off.Consumed_Quantity__c = KSE.addQuantityToField(off.Consumed_Quantity__c, solObj.Quantity_Ordered__c);  
                 ofIdToOf.put(off.id, off) ;  
                  
                }
            }
        }
       
    }
      
    
    public void finish(Database.BatchableContext info ){
        try {
    			DML.updateAsSystem(ofIdToOf.values());  
    		}catch(Exception ex) {
    			messages.add(Notify.getErrorMessage(ofIdToOf.values(), ex.getMessage(), ex.getStackTraceString()));
    		}
        if (!Test.isRunningTest()) {
               BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
               Notify.sendEmailBatchFinish( null, messages, info);        
               MasterControlProgram.finishedBatch( this );   
        }
    }
}