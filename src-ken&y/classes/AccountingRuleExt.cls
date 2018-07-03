public with sharing class AccountingRuleExt {
	//class AccountingRuleException extends Exception {}
    public ApexPages.StandardSetController setcon{get; set;}
    //private map<string,string> otypemap = AccountingRuleService.getTranscationTypeToObjectMap(); //this is the line object, not header object
        
    public boolean hasErrors {get; set; } { hasErrors = false; } 
    public wrap thewrap {get; set; } 
    
    private wrap onewrap(Accounting_Rule__c ar) {
		wrap w = new wrap(ar); 
	  	Type t ; sobject ob; string q = '';  w.exceptionMsg = '';
	  	//KNDY-10268 - deprecating bank file and bank file line objects - removed references
	  	set<string> objSet = new set<string>{'Journal_Entry__c','Customer_Invoice__c','Supplier_Invoice__c','Inventory_Change__c','Shipment__c','Receiving_Document__c','Work_Order__c','Invoice__c','Payment__c'};		
		try { 
			// SK - KNDY-3369 Modified below line while testing this JIRA as the credit memo transaction appears on CI as well as SI
			
			// AR -Commenting this as we can not arrive at valid Object-TrxnType combo until all SDs are standardizes to use the new Transaction Type field .
			//w.objectname = (string)otypemap.get(ar.Object_Name__c+'--'+ar.Transaction__c); //get the name of the line object from the transaction name 
			if ( ar.Object_Name__c == null ) {
				w.exceptionMsg += Label.Missing_Object_Name;					
			}	
			else
			{
				//TODO:We need to make AccountingRuleService handle the below case-insensitive logic
			    //Sanitizing ar.objectname to make it case insensitive as it is  user input from text box not picklist.			
				String SDAPIName=AccountingRuleService.mSDLowerToSDAPICase.get(ar.Object_Name__c.toLowerCase());
				if(SDAPIName!='Fixed_Asset_Adjustment__c' && SDAPIName!='Fixed_Asset_Depreciation__c')
				{
					w.objectname   =(string)AccountingService.mHeaderToLines.get(SDAPIName);				
				}
				else
				{
					w.objectname   =SDAPIName;				
				}				
	  	    	t =  Type.forName(w.objectname);
			
			}

			/*
			//TOOD: DP - Uncomment this when we add company to the accounting rule test data
			if ( ar.Company__c == null ) { 
				w.exceptionMsg += 'Missing Company   ';
			}	
			*/		
			

			
	  		//system.debug('****type'+t);
			//if ( t==null) w.exceptionMsg += 'Invalid Transaction Type >'+ar.Transaction__c + '<  ';		
		  	
		  	
		  	//if ( w.objectname == null ) 
		  		 //w.exceptionMsg += Label.Invalid_Transaction_Type + ' >'+ar.Transaction__c + '<  ';	  		
	  		
	  		set<string> ruleTypes = new set<string>{'CR', 'DR', 'NA'};
	  		if (!ruleTypes.contains(ar.Rule_Type__c)) {
				w.exceptionMsg += Label.Invalid_Debit_Credit_Expected_CR_DR + ar.Rule_Type__c;			
	  		}	
		
			if ((ar.GL_Account__c == null) && (ar.GL_Account_Reference_Value__c == null)) {
				w.exceptionMsg += Label.Must_specify_GL_Account_Reference_Value_or_a_Default_GL_Account ;	
			}	
			
			if(ar.GL_Account__c != null && !ar.Default_GL_Account__c){
			    w.exceptionMsg += Label.Check_the_Default_GL_Account_checkbox ;	
			}
			
			//t = type.forName(ar.Segment_name__c); // validate the segment name
	 		//if ( t==null) w.exceptionMsg += 'Invalid Segment Name  >'+ar.Segment_name__c +'<  ';
	 			    		
		} catch ( Exception e ) { 
			//ApexPages.addMessages(e); 
			//w.exceptionMsg += e.getMessage();
			//FIN-1085 Catch invalid Object-TransactionType combinations
			//Commenting below as we are not validating TT till All SDs are standardized to use TT type field.
			/*if(t==null)
			{
				w.exceptionMsg += Label.Invalid_Transaction_Type + '>'+ar.Transaction__c + '<  ';
				ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR ,'') );				
			}
			else if(!objSet.contains(ar.Object_Name__c))*/
			if(t==null || !objSet.contains(ar.Object_Name__c))//As T==null also indicates invalid objectname			
			{
				w.exceptionMsg += Label.Invalid_Object_Name + '>'+ar.Object_Name__c + '<  ';
				ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR ,'') );				
			}
			/*
			if ( t==null && !objSet.contains(ar.Object_Name__c)){
				w.exceptionMsg += Label.Invalid_Transaction_Type + '>'+ar.Transaction__c + '<  ';
				ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR ,'') );	
			} */
			system.debug(LoggingLevel.INFO, w.exceptionMsg );
		}	
		
		
		try { 
			// if GL default is true, then we must find a valid lookup in the field named in GL Account
	    		
	    		if ( ar.Default_GL_Account__c == true ) {
	    			if ( ar.GL_Account__c == null ) 
	    				w.exceptionMsg += Label.Missing_GL_Account_when_Default_GL_Account_is_true +ar.GL_Account__c;
	    		}
	    		
		} catch ( Exception e ) { 
			ApexPages.addMessages(e); 
			w.exceptionMsg += e.getMessage();
		}	
		
	  	try { 
  			
  			//FIN-1085 skip check GL reference path if the line object retrieval had exception
  			if ( ar.GL_Account_Reference_Value__c != null && w.objectname!=null ) {		  			// checks for a valid GL reference value
    	  		SOQLUtil soql = new SOQLUtil(w.objectname, TRUE);
    	  		soql.addField(ar.GL_Account_Reference_Value__c);
    	  		soql.setLimit(1);
				ob = database.query(soql.getQuery());
  			}  			
			
		} catch ( exception e) {
			// GOOD: System.QueryException List has no rows for assignment to SObject
			// OR 
			// BAD: System.QueryException No such column
			if ( ! e.getMessage().contains('List has no rows') )  { 
  				w.exceptionMsg += Label.Invalid_field_path_for_GL_Account_Reference_Value  + e.getMessage();
			} 
  		}

	  	return w;
    }
    
    /* Standard Controller */
    public AccountingRuleExt(ApexPages.StandardController controller) { 
	    	if ( controller.getId() != null) {
	    		thewrap = onewrap( getAllRules( new List<sobject>{controller.getRecord()} )[0] );
	    		hasErrors = thewrap.exceptionMsg != '' ;
	    	} else { 
	    		hasErrors = true; // no rule passed in
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Controller_for_view_rules_only));
	    	} 
    }
    
	/* Standard SET Controller */
    public AccountingRuleExt(ApexPages.StandardSetController controller) { 
    	  setcon = controller; 
    	  
    	  for ( sobject r : getAllRules( setcon.getSelected() ) ) { 
    	  	therules.add( onewrap( (Accounting_Rule__c)r) );
    	  }
    	  // count the number of errors
    	  errcount= 0; 
    	  for ( wrap one:therules) {
    	  	if ( one.exceptionMsg != '' ) errcount++;
    	  }
    }    

	private	SchemaUtil util = SchemaUtil.getInstance();
    // we need to re-fetch the rules so we have all the custom fields (segments)
    List<Accounting_Rule__c> getAllRules( list<sobject> records ) {
    		set<id> ids = KSE.grepIdSetFromList( records);
    		SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', TRUE);
    		soql.addAllFields();
    		soql.setWhereClause('id in :ids');
    		return Database.query (soql.getQuery());
    }
    
    public integer selectedCount {get { return setcon.getSelected().size(); } } 

    public integer errcount {get; private set; } 
    public List<wrap> therules { get;set; } { theRules = new List<wrap>();}
	public class wrap { 
		public Accounting_Rule__c rule {get;set; } 
		public string valid {get; set; }
		public string exceptionMsg {get; set; }

		public string objectname {get; set; } //this is the line object, not header object
		//public wrap() { valid=''; }
		public wrap(sobject r) { rule=(Accounting_Rule__c)r; valid=''; }
	}
	
}