/*
* without sharing is intentional.  1099 batches need to be run in system mode.
*/
public without sharing class Supplier1099Batch implements Database.Stateful, Database.Batchable<sObject>, Schedulable{//, KNDY3.Process.Runnable{

   	public string query;
   	public Id companyId;
   	public Integer year;
   	public Decimal amount;
   	public Set<Id> supplierIds;
   	private Set<String> validCurrency = Supplier1099Service.validCurrency;
   	private Integer supplier1099ct = 0; //KNDY-18742
	
    public List<Notify.Message> messages = new List<Notify.Message>();
   	
   	public void execute(SchedulableContext sc) {
   
   		Supplier1099Batch b = new Supplier1099Batch(); 
      	database.executebatch(b); 
   	}

   	public Supplier1099Batch(Id companyId, Integer year, Decimal amount){
   		this.companyId = companyId;
   		this.year = year;
   		this.amount = amount;
   		updateQuery();
   	}
   
   	public Supplier1099Batch(){
   		updateQuery();
   	} 

   	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(query);
   	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope){ 
       Savepoint sp = Database.setSavepoint();
       try{
          system.debug(LoggingLevel.Error , '>>> BC.getJobId():'+ BC.getJobId()) ;
          system.debug(LoggingLevel.Error , '>>> year:'+ year) ;
          system.debug(LoggingLevel.Error , '>>>amount :'+ amount) ;
          Integer recordCt = Supplier1099Service.generateSupplier1099s(scope,BC.getJobId(),year, amount, companyId);
          supplier1099ct += recordCt;
       }
       catch(Exception ex){
           supplier1099ct = 0;
           system.debug(logginglevel.error, 'supplier 1099 batch exception '+ ex.getMessage() + ' ' +  ex.getStackTraceString() + '>>>>' + ex.getTypeName() );
           Database.rollback(sp);
           String msg = ex.getMessage();
           if (!(ex.getTypeName().contains('Supplier1099Exception'))){
               msg += ' ' + ex.getStackTraceString() ;
           }
           messages.add(new Notify.Message('Failure message: ' + msg, ''));
       }
	}

   	public void finish(Database.BatchableContext info){
   		if (supplier1099ct > 0){
   		   string chatterMsg = supplier1099ct + ' ' + Label.Supplier_1099s_were_created;
   		   string emailMsg = Label.Supplier_1099_Batch + ' ' +Label.Chatter_Done + '<br/>' + chatterMsg;
   		   messages.add(new Notify.Message('',  chatterMsg));
   		   // success email
   		   Notify.sendEmailBatchFinish('', emailMsg, info);
   		}
   		// no valid suppliers or valid payments exist to process
   		else if (supplier1099ct == 0 && messages.size() == 0){
   		   string chatterMsg =  '0 ' + Label.Supplier_1099s_were_created;
           string emailMsg = Label.Supplier_1099_Batch + ' ' +Label.Chatter_Done + '<br/>' + chatterMsg;
   		   messages.add(new Notify.Message('',  chatterMsg));
   		   // success email
           Notify.sendEmailBatchFinish('', emailMsg, info);
   		}
   		else{ 
   		   //Failure email, will always have failure messages
   		   Notify.sendEmailBatchFinish(messages.size(), null, messages, info);
   		}
   		Notify.chatterOnMe(Label.Supplier_1099_Batch, messages); 
   		MasterControlProgram.finishedBatch( this ); 
   	}
   	
   	private void updateQuery(){
   		supplierIds = new Set<Id>();

   		String whereClause = ' X1099_Relevant__c = true and Exclude_from_1099__c = false AND Supplier_Payment__r.Company__c = :companyId';
   		whereClause +=  ' and Supplier_Payment__r.Finalized__c = true and Supplier_Payment__r.Void__c = false and Supplier_Payment__r.Status__c != \'Void\'';
        whereClause +=  ' and Supplier_Payment__r.Status__c != \'Cancelled\' and Supplier_Payment__r.Currency__r.Name in :validCurrency';
    	    
    	    if(year != null){
    	        SchemaUtil util = SchemaUtil.getInstance();
    	        DateTime startDateTime = DateTime.newInstance(year,1,1,0,0,0);
    	        DateTime endDateTime =  DateTime.newInstance(year+1,1,1,0,0,0);
    	        String startDateTimeStr = util.formatDateTimeForSOQL(startDateTime);
    	        String endDateTimeStr = util.formatDateTimeForSOQL(endDateTime);
            whereClause  += ' and Supplier_Payment__r.Date_Paid__c >= ' + startDateTimeStr + ' and Supplier_Payment__r.Date_Paid__c < ' + endDateTimeStr;
    	    }
    	    
    	    SOQLUtil soql = new SOQLUtil('Supplier_Payment_Line__c', true); //enforceFLS=true, running in user mode
    	    soql.addFields(new set<string>{
    	    	'Id','X1099_Relevant__c','X1099_Box_G__c', 'Exclude_from_1099__c', 'Supplier_Payment__r.Supplier__c'
    	    });
    	    soql.setWhereClause(whereClause);

    	    List<Supplier_Payment_Line__c> spLinesList = Database.query(soql.getQuery());
    	    for (Supplier_Payment_Line__c spl : spLinesList){
    	    		supplierIds.add(spl.Supplier_Payment__r.Supplier__c);
    	    }
    	    
    	    soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
    	    soql.addFields(new set<string>{
    	    	'Id',' Name'
    	    });
    	    soql.setWhereClause('Id in :supplierIds');

    	    query = soql.getQuery();
    	    
    	    //query='Select Id, Name from Supplier__c where Id in :supplierIds';
    	    system.debug('query in Supplier1099Batch--------------------------->'+query);
    	    
   	}
   
}