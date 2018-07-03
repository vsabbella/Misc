public with sharing class YearEndCloseExt extends BaseController {
	
    public Id fiscalYearId {get; set;}
    public string NamespaceUU { get { return KSE.NamespaceUU; }}

    public Apexpages.Standardcontroller con {get;set;}
    //public ApexPages.StandardSetController mycon{get;set;}
    public Fiscal_Year__c fiscalYear {get; set;}    
    //public boolean isGenerateDone {get; set;}
    //public List<Period__c> unClosedPeriods{get; set;}
    public Id companyId { get; set; }
    public Id glAccountId { get; set; }
    public Id rId { get; set; }
    public list<Period__c> zeroPeriod { get; set; } 
    public Period__c per { get; set; } 
    //public class TestException extends Exception{}  
    public static Boolean  YECFlag { get; set; } 
    public ID journalEntryID {get; set;}
    public ID zeroPeriodID {get; set;}
    public ID retainedEarningsGLID {get; set;}
    public Boolean createJEFlag {get; set;}
    
    public boolean existingYEJournal {get;set;}

    // public class JELConfig {
    //     public Decimal fcDR { get; set; }
    //     public Decimal fcCR { get; set; }
    //     public string jeID { get; set; }
    //     public string accountingCodeId { get; set; }
    // }
    
     public class JELConfig2 {
        public Decimal balance { get; set; }
        public string accountingCodeId { get; set; }
    }
    
    //-------------- CHUNKING REWORK SIMI-----
    public String scoaQuery { get; set; } { scoaQuery = 'SELECT Id, Accounting_Code__c, COMP_Functional_Currency_Amount_DR__c,COMP_Functional_Currency_Amount_CR__c FROM Accounting_Entry_Line__c '; }
    // public String scoaWhereClause  { get; set; } {scoaWhereClause = 'Accounting_Entry__r.Status__c = \'Active\' ' +
    //                                                                 'AND Accounting_Entry__r.Has_Exceptions__c = false ' + 
    //                                                                 ' AND (GL_Account__r.Statement_Type__c = \'Income Statement\' OR GL_Account__r.GL_Type__r.Statement_Type__c  = \'Income Statement\')' + 
    //                                                                 ' AND accounting_entry__r.period__r.fiscalyear__c = :fyId ' + 
    //                                                                 ' AND COMP_Functional_Currency_Amount_DR__c != null'+
    //                                                                 ' AND COMP_Functional_Currency_Amount_CR__c != null';}
                                     
    
    public YearEndCloseExt(Apexpages.Standardcontroller controller){
    	
        this.con = controller;
        createJEFlag = true;
        
        fiscalYearId = con.getId();
        
        initialValidations();
        
    }
    
     @RemoteAction
    public static JsonResult createJournalEntryData2(List<JELConfig2> JELConfigs,Id jeId) { 
        
        JsonResult result = new JsonResult();
                   result.success    = true;
        
    	system.debug('JELConfigs: ' + JELConfigs); 
    	
    	boolean isSuccess = true;
    	
		set<Id> accountingCodeIds = new set<Id>();
		for(JELConfig2 config : JELConfigs){
			Id iACID;
			try{
				iACID = (ID)config.accountingCodeId;
			}catch(Exception ex){
				//Do nothing
			}
			accountingCodeIDs.add(iACID);
		}
		
		//string segFields = '';
		Set<String> segFlds = new Set<String> { 'id' ,'name' }  ;
    	for(Segment_Definition__c sd : Segment_Definition__c.getAll().values()){
	        //segFields += ', ' + sd.accounting_entry_field__c ;
	        segFlds.add (sd.accounting_entry_field__c);
	    }
	    // KNDY-10473 FLS Security Fixes for SOQL queries
	    //string accountingCodeQuery = 'SELECT id, name ' + segFields + ' FROM Accounting_Code__c WHERE Id IN :accountingCodeIDs ';
	    SOQLUtil soql = new SOQLUtil ('Accounting_Code__c') ;
	    soql.addFields ( segFlds ) ;
	    soql.setWhereClause('Id IN :accountingCodeIDs');
	    Map<Id, Accounting_Code__c> mAccountingCodes = new Map<Id, Accounting_Code__c>((List<Accounting_Code__c>)Database.query(soql.getQuery()));
		//Map<Id, Accounting_Code__c> mAccountingCodes = new Map<Id, Accounting_Code__c>((List<Accounting_Code__c>)Database.query(accountingCodeQuery));
		
		List<Journal_Entry_Line__c> insertJELs = new List<Journal_Entry_Line__c>();
		for(JELConfig2 config : JELConfigs){
			Id iACID;
			try{
				iACID = (ID)config.accountingCodeId;
			}catch(Exception ex){
				//Do nothing
			}
			Accounting_Code__c iAC = mAccountingCodes.get(iACID);
			system.debug('iAC: ' + iAC+'mAccountingCodes'+mAccountingCodes);
			if(iAC != null){
				
				Journal_Entry_Line__c iJEL = new Journal_Entry_Line__c();
				iJEL.Journal_Entry__c = jeId;
			
				for(Segment_Definition__c sd : Segment_Definition__c.getAll().values()){
	                if(sd.Accounting_Entry_Field__c != null){
	                    iJEL.put(sd.Accounting_Entry_Field__c,iAC.get(sd.Accounting_Entry_Field__c));
	                }
	            }
	            system.debug('config2'+config);
	            Decimal JELAmount = 0;
	             if (config.balance != null  )
	            	JELAmount =  config.balance ;
	            
	            if(JELAmount>0){
	                iJEL.Amount_CR__c = Math.Abs(JELAmount);
	                iJEL.Amount_DR__c = 0;
	            }else if(JELAmount<0){
	                iJEL.Amount_CR__c = 0;
	                iJEL.Amount_DR__c = Math.Abs(JELAmount);
	            }else{
	                continue;
	            }
	            
	            insertJELs.add(iJEL);
			}
		}
		
		system.debug('YEAR END JE lines based on SCOAs'+ insertJELs);
	    /// for testing
	    //throw new TestException('Remoting request invalid for your session');
		
		Savepoint sp = Database.setSavepoint();
		try{
			DML.insertAsUser(insertJELs); 
			//for testing
			//throw new TestException('Problem while inserting data');
		}catch(Exception ex){
			result.success = false;
			result.addMessage(ex.getMessage() , ApexPages.Severity.ERROR);    
			System.debug(logginglevel.error,
			                        'An error occured while creating Journal Entry Data line for year end, REASON: ' +
			                        ex.getMessage()+ex.getLineNumber());
			Database.rollback(sp); 
			
		}
		system.debug(logginglevel.error,'result.success'+result.success);
		return result;
		
    }
    
    
    
    public void initialValidations(){
    	YECFlag = true;
    	//Check if there is already a journal entry to close this fiscal year
    	
        // KNDY-10473 FLS Security Fixes for SOQL queries
        SOQLUtil jeSoql = new SOQLUtil ( 'Journal_Entry__c' ) ;
        jeSoql.addFields ( new Set<String> { 'Id','Name','Period__c', 'Period__r.Name' } ) ;
        jeSoql.setWhereClause ( 'Type__c = \'Year End Adjustment\' AND Period__r.FiscalYear__c = \''+con.getId()+'\' AND Finalized__c = true AND Void__c = false AND Id NOT IN '
    								+	'(SELECT Journal_Entry__c FROM Accounting_Entry__c  where has_exceptions__c = false  AND status__c = \'Active\' AND Journal_Entry__c != null) and Period__r.Type__c = \'Period 13\'' ) ;
        jeSoql.setLimit (1);
        
        List<Journal_Entry__c> yearEndAdjustmentJournals = Database.query ( jeSoql.getQuery () ) ;

		if(yearEndAdjustmentJournals.size() > 0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You cannot perform the transfer to retained earnings because there are unaccounted journal entries in ' + yearEndAdjustmentJournals[0].Period__r.Name));
            YECFlag = false;

		}
		
        jeSoql = new SOQLUtil ( 'Journal_Entry__c' ) ;
        jeSoql.addFields ( new Set<String> { 'Id','Name' } ) ;
        jeSoql.setWhereClause ( 'Type__c = \'Year End\' AND Period__r.FiscalYear__c = \''+con.getId()+'\' AND Finalized__c = true AND Void__c = false' ) ;
        jeSoql.setLimit (1);
        
        List<Journal_Entry__c> yearEndJournals = Database.query ( jeSoql.getQuery () ) ;
        
		if(yearEndJournals.size() > 0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The retained earnings for this fiscal year have already been calculated. Please review Journal Entry: ' + yearEndJournals[0].name));
            YECFlag = false;
            existingYEJournal = true;		
		}else{
			existingYEJournal = false;
		}
		
		//Ensure there is an open zero period for this fiscal year
		if (!string.isBlank(fiscalYearId)) {
		    // KNDY-10473 FLS Security Fixes for SOQL queries
		    
		    SOQLUtil periodSoql = new SOQLUtil ( 'Period__c' ) ;
		    periodSoql.addFields ( new Set<String> { 'Id', 'Name', 'Type__c','Open__c','Period_Start__c' } ) ;
		    periodSoql.setWhereClause ( 'FiscalYear__c = :fiscalYearId AND (Type__c = \'Zero\' OR Type__c = \'Period 13\')' ) ;
		    zeroPeriod = Database.query ( periodSoql.getQuery() ) ;
	        if(zeroPeriod.size()>0){
	            if(zeroPeriod.size()==1){
	                if(zeroPeriod[0].Open__c == true){
	                     zeroPeriodID = zeroPeriod[0].Id;
	                }else{
	                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Period 13 period associated with this fiscal year is not Open.'));
	                	YECFlag= false;
	                }
	               
	            }
	        }else{
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'There are no Period 13 periods to this fiscal year.'));
	        }
		}
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Fiscal_Year__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','GL_Account__c','Company__c'
		});
		soql.setWhereClause('Id = \''+con.getId()+'\'' );
		Fiscal_Year__c fy = Database.query(soql.getQuery());
		
		if(fy.gl_account__c == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Please specify a Retained Earnings GL Account on the Fiscal Year'));
            YECFlag = false;
		}
        //Page error for fiscal year that does not have a company specified
        if(fy.Company__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, System.Label.Please_specify_a_company_for_this_Fiscal_Year));
            YECFlag = false;   
        }        
        //Make sure there is at least 1 AE for this FY

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Accounting_Entry__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('Period__r.FiscalYear__c = \''+fy.Id+'\' AND Status__c = \'Active\'');
		soql.setLimit(1);
		List<Accounting_Entry__c> aes = Database.query(soql.getQuery());

        if(aes.size() == 0){
            YECFlag = false;
        }
       
    }
    
    public void cancelExistingYearEndJournal(){
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name'
		});
		soql.setWhereClause('Type__c = \'Year End\' AND Period__r.FiscalYear__c =\''+con.getId()+'\' AND Finalized__c = true AND Void__c = false');
		soql.setLimit(1);
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
		childRel.addFields(new set<string>{
			'Id','Status__c'
		});
		childRel.setWhereClause('Status__c = \'Active\' AND Related_Accounting_Entry__c = null');
		
		soql.addChildRelationship(childRel);
		List<Journal_Entry__c> yearEndJournals = Database.query(soql.getQuery());

        if(yearEndJournals.size() > 0){
        	
        	Savepoint sp = Database.setSavepoint();
        	try{
        		if(yearEndJournals[0].Accounting_Entries__r.size() > 0){
		        	yearEndJournals[0].Accounting_Entries__r[0].Status__c = 'Obsolete';
		        	DML.updateAsUser(yearEndJournals[0].Accounting_Entries__r[0]);
        		}
        		
        		//RS: TODO This is a temp hack - need to use unfinalizeservice
	        	yearEndJournals[0].Status__c = 'Cancelled';
	        	yearEndJournals[0].Finalized__c = false;
	        	yearEndJournals[0].Finalized_Hidden__c = false;
	        	DML.updateAsUser(yearEndJournals[0]);
	        	
	        	initialValidations();
	        	
        	}catch(Exception ex){
        		Database.rollback(sp);
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Unable to cancel the existing Year End Journal Entry. ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        	}
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'There are no Year End Journal Entries to cancel.'));
        }       									
		
    }
    
    
    public list<period__c> getPeriods(){
    
	    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	
		SOQLUtil soql = new SOQLUtil('period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Period_Closed__c','Closed__c','Permanently_Closed__c','Open__c','Type__c'
		});
		soql.setWhereClause('FiscalYear__c = \''+con.getid() +'\' and (type__c = \'Fiscal\' or type__c = \'Adjustment\' OR type__c = \'Period 13\')');
		soql.setOrderByClause('Period_Start__c');
		
		list<period__c> periodlist = Database.query(soql.getQuery());
		list<period__c> periodlistnew = new list<period__c>(); 
	    for(period__c p :periodlist){
            if(p.Open__c == true && p.type__c != 'Period 13'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'There are open periods associated with this fiscal year. Please close all open periods.'));
                YECFlag = false;
            }
            if(p.type__c != 'Period 13'){
            	periodlistnew.add(p);
            }
        }
        return periodlistnew;
        
    }
    
     
    //public Integer getParallelRequests() {
       // Integer batchSize = 100; //default to 100. 
            //Use Custom Setting for Config?
    //    return batchSize;               
    //}

    // @ReadOnly        
    // @RemoteAction
    // public static List<AggregateResult> getRecentDataSOQL(Map<String, String> idRange, Id fyId) {   
    //     // TODO Check FLS for aggregate query fields
    //   /*  String aggQuery =
    //     'SELECT Accounting_Code__c, ' +
    //     'SUM(COMP_Functional_Currency_Amount_DR__c) debitsFC, ' +
    //     'SUM(COMP_Functional_Currency_Amount_CR__c) creditsFC ' +
    //     'FROM Accounting_Entry_Line__c  ' +
    //     'WHERE Accounting_Entry__r.Status__c = \'Active\' ' +
    //     'AND Accounting_Entry__r.Has_Exceptions__c = false ' + 
    //     ' AND (GL_Account__r.Statement_Type__c = \'Income Statement\' OR GL_Account__r.GL_Type__r.Statement_Type__c  = \'Income Statement\')' + 
    //     ' AND Id >= \''+ idRange.get('first') +'\'  ' +
    //     ' AND Id <= \''+ idRange.get('last') +'\'  ' +      
    //     ' AND accounting_entry__r.period__r.fiscalyear__c = :fyId ' + 
    //     ' AND COMP_Functional_Currency_Amount_DR__c != null'+
    //     ' AND COMP_Functional_Currency_Amount_CR__c != null'+
    //     ' GROUP BY Accounting_Code__c';   
    //     system.debug('aggQuery' + aggQuery);        
    //     List<AggregateResult> arList = database.query(aggQuery);     */
        
    //     // KNDY-10473 FLS Security Fixes for SOQL queries
    //     String whereClause = 'Accounting_Entry__r.Status__c = \'Active\' ' +
    //     'AND Accounting_Entry__r.Has_Exceptions__c = false ' + 
    //     ' AND (GL_Account__r.Statement_Type__c = \'Income Statement\' OR GL_Account__r.GL_Type__r.Statement_Type__c  = \'Income Statement\')' + 
    //     ' AND Id >= \''+ idRange.get('first') +'\'  ' +
    //     ' AND Id <= \''+ idRange.get('last') +'\'  ' +      
    //     ' AND accounting_entry__r.period__r.fiscalyear__c = :fyId ' + 
    //     ' AND COMP_Functional_Currency_Amount_DR__c != null'+
    //     ' AND COMP_Functional_Currency_Amount_CR__c != null'+
    //     ' GROUP BY Accounting_Code__c';   
    //     SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c',true,true);
    //     soql.addFields(new Set<String>{'Accounting_Code__c', 'SUM(COMP_Functional_Currency_Amount_DR__c) debitsFC', 'SUM(COMP_Functional_Currency_Amount_CR__c) creditsFC'});
    //     soql.setWhereClause(whereClause);
    //     List<AggregateResult> arList = database.query(soql.getQuery());
    //     system.debug('arList' + arList); 
    //     return arList;	
    // }   
    
    

     
//     @ReadOnly
//     @RemoteAction
//     public static string findMin(Id fiscalYearId){
//     	string min;
//     	// KNDY-10473 FLS Security Fixes for SOQL queries
//     	//String AEqueryMin = 'SELECT CreatedDate FROM Accounting_Entry__c WHERE Period__r.FiscalYear__c = :fiscalYearId AND Total_Lines__c > 0 AND Status__c = \'Active\' ORDER BY CreatedDate ASC LIMIT 1';
// 		SOQLUtil aeminSoql = new SOQLUtil ( 'Accounting_Entry__c' ) ;
// 		aeminSoql.addField ( 'CreatedDate' ) ;
// 		aeminSoql.setWhereClause ( 'Period__r.FiscalYear__c = :fiscalYearId AND Total_Lines__c > 0 AND Status__c = \'Active\'' ) ;
// 		aeminSoql.setOrderbyClause ( 'CreatedDate ASC' ) ;
// 		aeminSoql.setLimit (1);
		
// 		//List<Accounting_Entry__c> minAEList = database.query(AEqueryMin);	
// 		List<Accounting_Entry__c> minAEList = database.query(aeminSoql.getQuery());	
		
// 		if (!minAEList.isEmpty()) {
// 			Datetime minAEdateTime = minAEList[0].CreatedDate;
// 			//String queryMin = 'SELECT Id, Autonumber__c, CreatedDate FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.CreatedDate =: minAEdateTime ORDER BY Id ASC LIMIT 1';
// 	       	SOQLUtil aelminSoql = new SOQLUtil ( 'Accounting_Entry_Line__c' ) ;
//     		aelminSoql.addFields ( new Set<String> { 'Id', 'Autonumber__c', 'CreatedDate' } ) ;
//     		//aelminSoql.setWhereClause ( 'Accounting_Entry__r.CreatedDate =: minAEdateTime' ) ;
//     		aelminSoql.setWhereClause ( 'Accounting_Entry__r.Period__r.FiscalYear__c = :fiscalYearId AND Accounting_Entry__r.Total_Lines__c > 0 AND Status__c = \'Active\'' ) ;
//     		aelminSoql.setOrderbyClause ( 'Id ASC' ) ;
//     		aelminSoql.setLimit (1);
// 	       	//List<Accounting_Entry_Line__c> minList = database.query(queryMin);
// 	       	List<Accounting_Entry_Line__c> minList = database.query( aelminSoql.getQuery() );
// 	        if (!minList.isEmpty()) {
// 	            //reportItemMinMaxMap.put(firstLast, (minList[0].Autonumber__c));
// 	            min = minList[0].Id;
// 	        }  					   
// 		}
// 		return min;
//     } 
    // @ReadOnly
    // @RemoteAction
    // public static string findMax(Id fiscalYearId){
    // 	string max;
    // 	// KNDY-10473 FLS Security Fixes for SOQL queries
    // 	SOQLUtil soql = new SOQLUtil ( 'Accounting_Entry_Line__c' ) ;
    // 	soql.addFields ( new Set<String> {'Id','Autonumber__c'} ) ;
    // 	soql.setWhereClause ( 'Accounting_Entry__r.Period__r.FiscalYear__c = :fiscalYearId' ) ;
    // 	soql.setOrderbyClause ('Id DESC') ;
    // 	soql.setLimit (1) ;
    // 	List<Accounting_Entry_Line__c> maxList = database.query(soql.getQuery());
    	
    // 	//String queryMax = 'SELECT ID, Autonumber__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Period__r.FiscalYear__c = :fiscalYearId ORDER BY Id DESC LIMIT 1';	
    //   	//List<Accounting_Entry_Line__c> maxList = database.query(queryMax);
  
    //     if (!maxList.isEmpty()) {
    //         //reportItemMinMaxMap.put(firstLast, (maxList[0].Autonumber__c));
    //         max = maxList[0].Id;
    //     }  
    //     return max; 
    // } 
    // @ReadOnly
    // @RemoteAction
    // public static List<Map<String, String>> chunkPeriodRange(string minVal, string maxVal){
    //     if(minVal == null || maxVal == null){ 
    //         return new List<Map<String, String>>();
    //     }else{
    //         //return chunkRange(min, max, 10, 70000); //1000 (smaller value in 4th param means more chunks, more time)
    //         return KSE.chunkIdRange(    minVal, maxVal, getYearEndRowsPerRequest());

    //     }
    // }
    
    @RemoteAction
    public static Id createYearEndJournalEntry(Id fiscalYearId) {   
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Fiscal_Year__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','company__c','GL_Account__c','company__r.comp_currency__c','fiscal_year_start_date__c','fiscal_year_end_date__c'
		});
		soql.setWhereClause('Id = :fiscalYearId');
		
		Fiscal_Year__c fiscalYear = Database.query(soql.getQuery());
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('FiscalYear__c = \''+fiscalYear.Id +'\' AND (Type__c = \'Zero\' OR Type__c = \'Period 13\')');
		soql.setLimit(1);

		Period__c zeroPeriod = Database.query(soql.getQuery());
		
        Journal_Entry__c je = new Journal_Entry__c();
        je.status__c = 'Open'; 
        je.Company__c = fiscalYear.company__c;
        je.Type__c = 'Year End';
        je.Currency__c = fiscalYear.company__r.Comp_Currency__c;
        je.Transaction_Date__c = fiscalYear.fiscal_year_end_date__c.addSeconds(-1);
        je.period__c = zeroPeriod.Id;

        DML.insertAsUser(je);
     	
     	return je.Id;   
    }
    
//     @RemoteAction
//     public static boolean createJournalEntryData(List<JELConfig> JELConfigs) { 
    	
//     	system.debug('JELConfigs: ' + JELConfigs);
//     	//List<JELConfig> JELConfigs = (List<JELConfig>)JELConfigObjs;
    	
//     	boolean isSuccess = true;
    	
// 		set<Id> accountingCodeIds = new set<Id>();
// 		for(JELConfig config : JELConfigs){
// 			Id iACID;
// 			try{
// 				iACID = (ID)config.accountingCodeId;
// 			}catch(Exception ex){
// 				//Do nothing
// 			}
// 			accountingCodeIDs.add(iACID);
// 		}
		
// 		//string segFields = '';
// 		Set<String> segFlds = new Set<String> { 'id' ,'name' }  ;
//     	for(Segment_Definition__c sd : Segment_Definition__c.getAll().values()){
// 	        //segFields += ', ' + sd.accounting_entry_field__c ;
// 	        segFlds.add (sd.accounting_entry_field__c);
// 	    }
// 	    // KNDY-10473 FLS Security Fixes for SOQL queries
// 	    //string accountingCodeQuery = 'SELECT id, name ' + segFields + ' FROM Accounting_Code__c WHERE Id IN :accountingCodeIDs ';
// 	    SOQLUtil soql = new SOQLUtil ('Accounting_Code__c') ;
// 	    soql.addFields ( segFlds ) ;
// 	    soql.setWhereClause('Id IN :accountingCodeIDs');
// 	    Map<Id, Accounting_Code__c> mAccountingCodes = new Map<Id, Accounting_Code__c>((List<Accounting_Code__c>)Database.query(soql.getQuery()));
// 		//Map<Id, Accounting_Code__c> mAccountingCodes = new Map<Id, Accounting_Code__c>((List<Accounting_Code__c>)Database.query(accountingCodeQuery));
		
// 		List<Journal_Entry_Line__c> insertJELs = new List<Journal_Entry_Line__c>();
// 		for(JELConfig config : JELConfigs){
// 			Id iACID;
// 			try{
// 				iACID = (ID)config.accountingCodeId;
// 			}catch(Exception ex){
// 				//Do nothing
// 			}
// 			Accounting_Code__c iAC = mAccountingCodes.get(iACID);
// 			system.debug('iAC: ' + iAC);
// 			if(iAC != null){
				
// 				Journal_Entry_Line__c iJEL = new Journal_Entry_Line__c();
// 				iJEL.Journal_Entry__c = config.jeId;
			
// 				for(Segment_Definition__c sd : Segment_Definition__c.getAll().values()){
// 	                if(sd.Accounting_Entry_Field__c != null){
// 	                    iJEL.put(sd.Accounting_Entry_Field__c,iAC.get(sd.Accounting_Entry_Field__c));
// 	                }
// 	            }
// 	            Decimal JELAmount = 0;
// 	            if (config.fcDR != null && config.fcCR != null)
// 	            	JELAmount = config.fcDR - config.fcCR;
	            
// 	            if(JELAmount>0){
// 	                iJEL.Amount_CR__c = Math.Abs(JELAmount);
// 	                iJEL.Amount_DR__c = 0;
// 	            }else if(JELAmount<0){
// 	                iJEL.Amount_CR__c = 0;
// 	                iJEL.Amount_DR__c = Math.Abs(JELAmount);
// 	            }else{
// 	                continue;
// 	            }
	            
// 	            insertJELs.add(iJEL);
// 			}
// 		}
		
// 		Savepoint sp = Database.setSavepoint();
// 		try{
// 			DML.insertAsUser(insertJELs);
// 		}catch(Exception ex){
// 			isSuccess = false;
// 			Database.rollback(sp);
// 		}
		
// 		return isSuccess;
		
//     }
    
    @RemoteAction
    public static String createRetainedEarnings(ID jeID, ID glID, Id fiscalYearId){
        // get the Journal Entry associated with the year end close
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Total_Credit__c','Transaction_Date__c','Total_Debit__c','Finalized__c','Period__c','Period__r.Period_Start__c'
		});
		soql.setWhereClause('ID = :jeID');
		
		Journal_Entry__c je = Database.query(soql.getQuery());

        system.debug('je before update top' + je);

        Journal_Entry_Line__c jel = new Journal_Entry_Line__c();
        jel.Journal_Entry__c =jeID;
        jel.GL_Account__c = glID;
        //jel.SubTransaction_Type__c ='Retained Earnings';
        // get the zero period to book the JE
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','FiscalYear__c'
		});
		soql.setWhereClause('FiscalYear__c = :fiscalYearId AND (Type__c = \'Zero\' OR Type__c = \'Period 13\')');
		
		Period__c p = Database.query(soql.getQuery());
       	
       	// get the fiscal year that we are closing
        

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Fiscal_Year__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','GL_Account__c'
		});
		soql.setWhereClause('ID = \''+p.FiscalYear__c+'\'');
		Fiscal_Year__c fy = Database.query(soql.getQuery());


	    Decimal JELAmount = 0;
	    if (je.Total_Credit__c != null && je.Total_Debit__c != null)
        	JELAmount = je.Total_Credit__c-je.Total_Debit__c;
        if(JELAmount > 0){
            jel.Amount_CR__c = 0;
            jel.Amount_DR__c = Math.Abs(JELAmount);
        }else if(JELAmount < 0){
            jel.Amount_CR__c = Math.Abs(JELAmount);
            jel.Amount_DR__c = 0;
            
        }else{
            jel.Amount_CR__c = 0;
            jel.Amount_DR__c = 0;
        }
        DML.insertAsUser(jel);
        je.period__c = p.ID;
        je.gl_date_time__c = je.transaction_date__c;
        je.finalized_date__c = system.now();
        je.Posting_date__c = je.transaction_date__c;
        je.Finalized__c = true;
        try{
            DML.updateAsUser(je);
        }catch(Exception ex){
            try{
                DML.deleteAsUser(je);
            }catch(Exception e){
                return e.getMessage();
            }
            return ex.getMessage();
        }
        YECFlag = false;
        return 'Success';
    }

    // public static Integer getYearEndRowsPerRequest() {
    //     Integer batchSize = 70000; 

    //     Integer minValue = 1;   
    //     Integer maxValue = 5000000; 
        
    //     Configuration__c c = Configuration__c.getValues('yearEndRowsPerRequest');
    //     //attempt to parse the string config value into an integer and make sure it is between min/max
    //     //if not we are just going to use the default
    //     if (c != null) {
    //         Integer configBatch;
    //         try {configBatch = Integer.valueOf(c.Value__c);} catch (Exception e) {}
    //         if (configBatch != null) {
    //             if ( (configBatch >= minValue) && (configBatch <= maxValue) ) {
    //                 batchSize = configBatch;
    //             }
    //         }
    //     }
    //     return batchSize;               
    // }           




    /*
    public static List<Map<String, String>> chunkRange(Integer firstAutoNum, Integer lastAutoNum, Integer totalLength, Integer chunkSize) {
        system.debug(firstAutoNum + ' ' + lastAutoNum);
        //get the range between the two numbers passed in. 
        Integer range = (lastAutoNum - firstAutoNum);   
        List<Map<String, Integer>> autoNumberChunkList = new List<Map<String, Integer>>();
        if (range < chunkSize) { //range is already smaller than chunk, just add them all
            autoNumberChunkList.add(new Map<String, Integer>{'first'=> firstAutoNum, 'last'=> lastAutoNum});    
        } else {
            //need to create multiple chunks
            //chunk the range up into chunks the size of chunkSize
            Decimal numChunks = (range / chunkSize);    //figure out how many whole and partial chunks we have
            numChunks = numChunks.round(System.RoundingMode.DOWN);      //discard the partial chunk remainder
            Integer numWholeChunks = numChunks.intValue();
            //add the first chunk
            Integer firstAutoNumChunk = firstAutoNum;
            Integer lastAutoNumChunk =  firstAutoNum + chunkSize - 1;
            autoNumberChunkList.add(new Map<String, Integer>{'first'=> firstAutoNumChunk, 'last'=> lastAutoNumChunk});          
            //add any remaining chunks
            for (Integer i=1; i<numWholeChunks; i++) {
                firstAutoNumChunk = (lastAutoNumChunk + 1);
                lastAutoNumChunk = (firstAutoNumChunk + chunkSize - 1);                     
                autoNumberChunkList.add(new Map<String, Integer>{'first'=> firstAutoNumChunk, 'last'=> lastAutoNumChunk});
            }
            //add in the any remaining chunk which is < chunkSize
            Integer lastLastAutoNumChunk = autoNumberChunkList[autoNumberChunkList.size()-1].get('last'); //get last autonumber from last row of the chunkList
            if (lastLastAutoNumChunk < lastAutoNum) {
                autoNumberChunkList.add(new Map<String, Integer>{'first'=> lastLastAutoNumChunk+1, 'last'=> lastAutoNum});  
            }
        }       
        //convert our integer map to a padded string map with 0's so it matches the autonumber format 
        List<Map<String, String>> autoNumberChunkListZeroPadded = new List<Map<String, String>>();
        for (Map<String, Integer> rangeMap: autoNumberChunkList) {
            autoNumberChunkListZeroPadded.add(new Map<String, String>{'first'=> prefixIntWithZeros(rangeMap.get('first'), totalLength), 
                                                                      'last' => prefixIntWithZeros(rangeMap.get('last'),  totalLength)  });     
        }
        system.debug('autoNumberChunkListZeroPadded: ' + autoNumberChunkListZeroPadded);
        return autoNumberChunkListZeroPadded;
    }
    

    public static string prefixIntWithZeros(Integer intInput, Integer totalLength) {
        String sOutput = '';
        if (intInput != null) {
            sOutput = intInput+'';
        }
        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = (totalLength - sOutput.length());
        if (zerosToAdd > 0) {
            for (Integer i=0; i<zerosToAdd; i++) {
                sOutput = '0'+sOutput;  
            }
        }
        return sOutput;
    }
    
    public static String drop_leading_zeros(String passedValue) {
        String return_string = null; //return string for passing back
        if (passedValue != null) { //if the passed value is not null
            return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
            Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
            Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
            if (check_chars.matches()) { //if we have a somewhat valid number
                if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with a 0 and the length is greater than 1
                    boolean keepChecking = true; //create a boolean variable
                    while (keepChecking) { //if boolean is true
                        if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with 0 and there is more than 1 character
                            return_string = return_string.substring(1); //drop the first character
                        } else { //either the string doesn't begin with 0 or the length is less than or equal to 1
                            keepChecking = false; //stop the loop
                        }
                    }
                }
                if (return_string == '0') { //if the resulting string is now a single '0'
                    return_string = null; //set the string to null
                }
            } else { //otherwise the value passed was not valid
                return_string = null; //set the string to null
            }
        }
        return return_string; //pass back a value
    }    
    */
}