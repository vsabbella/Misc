public with sharing class CreditProfile implements Process.Automate {
	public 	void processRecordsDML( Process_Automation__c config, 	List<sobject> records ) {
		processRecords( config,records);
		DML.updateAsUser(records); 
	}
	public 	void processRecords( Process_Automation__c config, 	
												List<sobject> records ) {
		
		notify.chatterOnMe(this, new List<Notify.Message> {new Notify.Message('CustomerCreditCheck', 'Customer Credit check routine running')});												
		/*  inputs : customer records, Risk category, Outstanding_Balance2__c 
		 *  credit profile params / tolerances are located in custom setting
		 Credit_Profile_Rules__c.AR_Percent_Past_Due__c
		 Days_Past_Due__c
		 Percent_Over_Credit__c
		 */
		if ( config.Object_name__c == 'Customer__c' ) {
			
			// TODO should we query the records to get the fields we need ?
			Map<String, Credit_Profile_Rules__c> rules = Credit_Profile_Rules__c.getAll();
			List<Customer__c> toupdate = new List<Customer__c>();
			
			for ( sobject so : fetch(records) ) {
				Customer__c cust = (Customer__c) so; 
				//system.debug(LoggingLevel.INFO,cust);
				if ( cust.Outstanding_Balance2__c == 0 ) continue;
				//if ( cust.Top_Parent_Customer__c != null  ) continue;
				if ( cust.Risk_Class__c == null || cust.Risk_Class__c == ''  ) continue;
				Credit_Profile_Rules__c rule = rules.get( cust.Risk_Class__c );
				//system.debug(LoggingLevel.INFO, rule);
				if ( rule == null  ) continue;
				
			/* 
				For A&B risk profiles: Allow up to 5% past due on all AR based on terms, OR 
				up to 20% over line of credit, OR up to 5 days past due. Hence if the Customer is >5% past due on 
				AR, OR >20% over line of credit, OR >5 days past due, then the customer will be put on Credit Hold.
				For C,R, and E risk profiles: One day past due or one dollar over the credit amount will put them on credit hold.
				*/
				Boolean hold1 = false;
				Boolean hold2 = false;
				Boolean hold3 = false;
				
				if ( cust.Outstanding_Balance2__c > cust.Credit_Limit__c ) { //percent over credit criterion
					// we have an credit limit issue, see if it's out of bounds
					Double over = cust.Outstanding_Balance2__c-cust.Credit_Limit__c 	;
					Double pover = cust.Credit_Limit__c == 0 ? -1 : ( over / cust.Credit_Limit__c )*100 ;
					if (rule.Percent_Over_Credit__c != null){ // if null then don't evaluate hold status as its unlimited credit
						//system.debug(LoggingLevel.INFO, 'hold1: ' + hold1 + ', pover: ' + pover + ', tolerance: ' + rule.Percent_Over_Credit__c);
						if (rule.Percent_Over_Credit__c == 0){
							hold1= true; //since outstanding balance is over the credit limit and tolerance is 0 which means anything over credit limit goes to hold
						}else{
							hold1 = pover == -1 ? true :pover > KSE.addQuantityToField(rule.Percent_Over_Credit__c,0);
						}
					} 
					//system.debug(LoggingLevel.INFO, 'hold1: ' + hold1 + ', pover: ' + pover + ', tolerance: ' + rule.Percent_Over_Credit__c);
				}
				
				{ // AR past due criterion
					Double over = KSE.addQuantityToField(cust.Open_Past_Due__c, 0) / KSE.addQuantityToField(cust.Outstanding_Balance2__c,0);
					Double pover = over *100;
					if (rule.AR_Percent_Past_Due__c != null){ // if null then don't evaluate hold status as its unlimited credit
						//system.debug(LoggingLevel.INFO, 'hold2: ' + hold2 + ', pover: ' + pover + ', tolerance: ' + rule.AR_Percent_Past_Due__c);
						if (rule.AR_Percent_Past_Due__c == 0  && (KSE.addQuantityToField(cust.Open_Past_Due__c, 0) > 0)){
							hold2= true; //since outstanding balance is over the credit limit and tolerance is 0 which means stick to credit limit
						}else{
							hold2 = pover > KSE.addQuantityToField(rule.AR_Percent_Past_Due__c,0);
						}
						//system.debug(LoggingLevel.INFO,'hold2: ' + hold2 + ', pover: ' + pover + ', tolerance: ' + rule.AR_Percent_Past_Due__c);
					}
				}
				
				{//Days past due criterion
					if (rule.Days_Past_Due__c != null){ // if null then don't evaluate hold status as its unlimited credit
						//system.debug(LoggingLevel.INFO, 'hold3: ' + hold3 + ', Days_Past_Due_Max: ' + KSE.addQuantityToField(cust.Days_Past_Due_Max__c, 0) + ', tolerance: ' + rule.Days_Past_Due__c);
						if (rule.Days_Past_Due__c == 0 && (KSE.addQuantityToField(cust.Days_Past_Due_Max__c, 0) > 0)){
							hold3= true; 
						}else{
							hold3 = KSE.addQuantityToField(cust.Days_Past_Due_Max__c, 0) > KSE.addQuantityToField(rule.Days_Past_Due__c, 0);
						}
						//system.debug(LoggingLevel.INFO,'hold 3 is valid: '+ hold3); 
					} 
					
				}
				
				if (hold1 || hold2 || hold3){
					cust.Credit_Hold__c = true;
					toupdate.add(cust);
				}  else { 
					cust.Credit_Hold__c = false;
				}
			}
			DML.updateAsUser(  toupdate );
		}
 
	}
	
	list<sobject> fetch( list<sobject> inp) {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Outstanding_Balance2__c','Risk_Class__c','Credit_Hold__c','Credit_Limit__c','Open_Past_Due__c','Days_Past_Due_Max__c','Top_Parent_Customer__c'
		});
		soql.setWhereClause('id in :inp');
		return Database.query(soql.getQuery());
	}
	
	// KNDY-2846    measure this order and see if it will fit under the limit for the top customer
	public boolean willOrderExceedCreditLimits( id salesOrderId ) { 
		// fetch the order total, fetch the top customer
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Order_Total__c','Exception_Reason__c','Company__c','Customer__r.Top_Parent_Customer__c','Customer__c'
		});
		soql.setWhereClause('id = :salesOrderId');
		soql.setLimit(1);
		Sales_Order__c so = Database.query(soql.getQuery());

		return willOrderExceedCreditLimits(so);
	}
	
	public boolean willOrderExceedCreditLimits( Sales_Order__c so ) {
		Boolean order_exceeds_credit = false;
		
		Map<Id, Customer__c> customersMap = new Map<Id, Customer__c>(SalesOrderFlowCache.cachedCustomersForIds(new Set<Id>{so.Customer__r.Top_Parent_Customer__c}));
		
		//list<sobject> customers = fetch( new list<sobject>{ top } );
		
		Customer__c cust = (Customer__c) customersMap.get(so.Customer__r.Top_Parent_Customer__c); 
		
		if ( cust.Credit_Limit__c == null ) return false;  // not using credit limit feature
		if ( cust.Risk_Class__c == null || cust.Risk_Class__c == ''  ) return false;
		
		// pull the credit profile rules
		Map<String, Credit_Profile_Rules__c> rules = Credit_Profile_Rules__c.getAll();
		Credit_Profile_Rules__c rule = rules.get( cust.Risk_Class__c );
		
		//system.debug(LoggingLevel.INFO, rule);
		if ( rule == null  ) return false;
		
		
		// build the new ballance we will have if the oder is planned
		Decimal new_ballance =  KSE.addQuantityToField(cust.Outstanding_Balance2__c, so.Order_Total__c );
			
		// we have an credit limit issue, see if it's out of bounds
		if ( new_ballance > cust.Credit_Limit__c ) { 
			Double over = new_ballance - cust.Credit_Limit__c;
			Double pover = cust.Credit_Limit__c  == 0 ? -1 : ( over / cust.Credit_Limit__c )*100;
			if (rule.Percent_Over_Credit__c != null) { 
				// if null then don't evaluate hold status as its unlimited credit
				if (rule.Percent_Over_Credit__c == 0) {
					order_exceeds_credit= true; 
				} else {
					order_exceeds_credit = pover == -1 ? true : pover > KSE.addQuantityToField(rule.Percent_Over_Credit__c,0);
				}
			} 
		}

		// return true (hold) if we discover this order will excede the customer limit
		return order_exceeds_credit;
	} 
	 
}