public with sharing class ReconRemoteExt{/*
	
	Apexpages.Standardcontroller con {get;set;}
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	public Reconciliation__c recon {get;set;}

	public static List<Accounting_Entry_line__c> currentAccountingEntryLines = new List<Accounting_Entry_line__c>();
	public static List<Accounting_Entry_line__c> previousAccountingEntryLines = new List<Accounting_Entry_line__c>();
	public static List<Accounting_Entry_line__c> allAccountingEntryLines = new List<Accounting_Entry_line__c>();
	//public static Decimal currentPeriodAELTotalAmount {get;set;}
	//public static Decimal previousPeriodAELTotalAmount{get;set;}	
	public static Decimal beginningBalance{get;set;}
	public static Decimal endingBalance{get;set;}
	//public static Decimal allPeriodAELTotalAmount {get;set;}
	//public String currentReportID = '';
	public static ID asyncReportID ;
	public static String glAccountIDs = '';
	public static String asyncReportStatus {get;set;}
	public static BegEndBalResult BegEndBalobj ;
	public static Reconciliation__c currentRecon ;
	public static boolean runningForBeginningBalance;
	public static boolean runningForEndingBalance;
	public static Boolean endingRunFlag = false ;
	public static String standardReportId = '';
	public static  map<string,map<string,list<string>>> mSubledgerToSDRules = new map<string,map<string,list<string>>> ();
	

    public static SchemaUtil util = SchemaUtil.getInstance();

	//FIN-499 Help Page for Recons
    public string HelpURL{get;set;}
    public string SFDCBaseURL{get;set;}
    public boolean disableRunRecon{get;set;}
    

    public map<string,ReportSummaryView> mRptSDsec = new map<string,ReportSummaryView>();
    public string mSDRptSectionSer{get;set;}


    /*Vars to cleanup ReconTopics when user refreshes the report*//*
    public list<Reconciliation_Topic__c> updateTopics;
    public list<Reconciliation_Topic__c> deleteTopics ;
    public boolean isInitSuccess{get;set;}

    //Input vars to Threads
     public id period{get;set;}
     public id ReconId{get;set;}
     public id CompanyId{get;set;}

     public set<string> sourceDocAPINames=new set<string>();
     public string sourceDocAPINamesSer{get;set;}
     public integer NumberOfRetries{get;set;}

     public set<id> inputRuleIds;
     public string ARSpecsSer{get;set;}

     public id GLAccount;
     public list<GL_account__c> associatedGLAccounts ;
     public string associatedGLAccountsSer{get;set;} 
     public string asofdate{get;set;}
     
	public  string ReconciledTitle
	{
		set;
		get
		{
			return ReconRemoteService.ReconciledTitle;
		}
	}
	public  string UnreconciledAmountTitle
	{
		set;
		get
		{
			return ReconRemoteService.UnreconciledAmountTitle;
		}
	}
	public  string UnreconciledRulesTitle
	{
		set;
		get
		{
			return ReconRemoteService.UnreconciledRulesTitle;
		}
	}
	public  string UnmatchedTitle
	{
		set;
		get
		{
			return ReconRemoteService.UnmatchedTitle;
		}
	}
	public  string ExceptionsTitle
	{
		set;
		get
		{
			return ReconRemoteService.UnreconciledExceptionsTitle;
		}
	}
	public  string otherSDTitle
	{
		set;
		get
		{
			return ReconRemoteService.otherSDTitle;
		}
	}
	public  string AccrualCandidatesTitle
	{
		set;
		get
		{
			return ReconRemoteService.AccrualCandidatesTitle;
		}
	}
	public  string ManualTitle
	{
		set;
		get
		{
			return ReconRemoteService.ManualTitle;
		}
	}


    /*Result Class for chunkbyRules Thread from page*//*

    public class ChunkResultAggregateTotalsByRule
    {
        public string SDName;
        public id  ARuleId;
        public string message;
     	public decimal AELAmount=0;
    	public decimal SDLAmount=0;
    	public boolean isIncorrectRule=false;
    	public boolean isIncorrectAmt=false;
    	public boolean hasExceptions=false;    	
    	public boolean isValid=true;
    	public boolean isOtherSD = false;

    }

    /*Result Class for chunkForAccruals/getManualEntries/getUnmatchedAEL Thread calls from page*//*

    public class chunkResultAggregateTotalsBySD
    {
        public string SDName;
     	public decimal AELAmount=0;
    	public decimal SDLAmount=0;
    	public string message;
    	public boolean isValid=true;
    	public boolean isRowsPresent=true;
    	public reconciliation_topic__c rt ;
    	public list<reconciliation_topic__c> rtList = new list<reconciliation_topic__c>();//KNDY-9325 Used to populate RT for each Accounting rule in getUnmatchedAEL.
    	public boolean isOtherSD = false;

    }
    

    
    /*Report view on Constructor load*//*

    public class ReportSummaryView
    {
    	decimal AELAmount;
    	decimal SDLAmount;
    }

    /*Result Class for getBalances Thread from page*//*
    public class BegEndBalResult
    {
    	public string message;
    	public boolean isValid=true;
    	public decimal begBalance=0.0;
    	public decimal endBalance=0.0;
    }
    /*Result Class for DB updation calls from page*//*
    public class updateResult
    {
    	public string message;
    	public boolean isSuccess=true;
    }
    /*Result Class to get the Std report URL for reconciled entries detail view*//*
    public class ReportURLResult
    {
    	public string SDName;
    	public string ReportURL;
    	public boolean isSuccess;
    	public string message;
    }
    
	
	public ReconRemoteExt(Apexpages.Standardcontroller controller){
		this.con = controller;
    	this.reconId = con.getId() ;
    	recon = new Reconciliation__c();
    	currentRecon = new Reconciliation__c();
    	NumberOfRetries = getRetries();
        sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        disableRunRecon=false;
        //FIN-499 Help Page for Recon
        HelpURL=sfdcBaseURL+'/apex/'+'HelpReconpage';   	

        // FIN-1050 Replacing the std controller reference with view state var as it causes namespace issues in customer org 

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Reconciliation__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','gl_account__c','period__c','as_of__c','Company__c','Company__r.Comp_Currency__c','Beginning_Balance__c','Ending_Balance__c'
		});
		soql.setWhereClause('id=:reconId');

		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Reconciliation_Topics__r');
		childRel.addFields(new set<string>{
			'id','name','type__c','accounting_rule__c','Reconciliation_Section__c','gl_amount__c','source_amount__c'
		});
		soql.addChildRelationship(childRel);

		recon = Database.query(soql.getQuery());

 		asofdate=string.valueof(recon.as_of__c);
    	if(recon.Reconciliation_Topics__r.size()==0)
        {
           ApexPages.Message NORT = new ApexPages.Message(ApexPages.Severity.FATAL, 'Please add Recon topics') ;
           disableRunRecon=true;
           Apexpages.addMessage(NORT);

        }
        else
        {
        	        
        for(Reconciliation_Topic__c rt:recon.Reconciliation_Topics__r)
        {
        	string mkey='';
        	string TopicTypeAPIName = ReconRemoteService.getAPINameForSDType(rt.Type__c);
        	if((TopicTypeAPIName==null || TopicTypeAPIName=='Not Found') && rt.Type__c!='System Generated' )
        	{
				ApexPages.Message InvalidRT = new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Recon topic '+rt.Type__c) ;
				disableRunRecon=true;
			    Apexpages.addMessage(InvalidRT);		
        	}
        	else
        	{
        		//For system generated report section type grab the SD from topic Name
        		//For others grab SD name from respective topic rec.
        		//populateSummaryObj Method grabs the latest totals for the given SD|RptSection key and updates it.
        		
	        	if(rt.Reconciliation_Section__c=='Unmatched' )
	        	{
	        		list<string> keys=rt.name.split('\\|');
	        		mkey=keys[0]+'|'+'Unmatched';
	
	        		mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	         	}
	
	        	else if(rt.Reconciliation_Section__c=='Accrual')
	        	{
	        		list<string> keys=rt.name.split('\\|');
	        		mkey=keys[0]+'|'+'AccrualCandidates';
	        		mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	        		system.debug('keys'+keys);
	
	        	}

	        	else if (rt.Reconciliation_Section__c=='Exceptions')
	        	{
	        		list<string> keys=rt.name.split('\\|');
	        		mkey=keys[0]+'|'+'Exceptions';
	        	    mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	
	        	}
	        	else if (rt.Reconciliation_Section__c=='UnreconciledAmount')
	        	{
	        		mkey=TopicTypeAPIName+'|'+'UnreconciledAmount';
	        	    mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	
	        	}
	        	else if (rt.Reconciliation_Section__c=='UnreconciledRules')
	        	{
	        		mkey=TopicTypeAPIName+'|'+'UnreconciledRules';
	        	    mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	
	        	}
	        	else if (rt.Reconciliation_Section__c=='otherSD' && rt.type__c=='System Generated')
	        	{
	        		list<string> keys=rt.name.split('\\|');
	        		mkey=keys[0]+'|'+'otherSD';
	        	    mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	
	        	}
	        	else if (rt.Reconciliation_Section__c=='otherSD' && rt.type__c!='System Generated')
	        	{
	        		list<string> keys=rt.name.split('\\|');
	        		mkey=TopicTypeAPIName+'|'+'otherSD';
	        	    mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	
	        	}
	        	else if(rt.Reconciliation_Section__c=='Manual')
	        	{
	        		mkey='Journal_Entry__c'+'|'+'Manual';
	        		mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	
	        	}
	        	else if(rt.Reconciliation_Section__c=='Reconciled')
	        	{
	        		mkey=TopicTypeAPIName+'|'+'Reconciled';
	          		
	        		mRptSDsec.put(mkey,populateSummaryObj(rt,mkey));
	     
	        	}        		
        	}

        }
         mSDRptSectionSer= JSON.serialize(mRptSDsec);

    }


	}
	
	// Called from the page Button Click
    public void invokeRemoteCall(){ 

    	try
    	{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Reconciliation__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','gl_account__c','period__c','company__c'
			});
			soql.setWhereClause('id=:reconId');
			
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Reconciliation_Topics__r');
			childRel.addFields(new set<string>{
				'id','type__c','accounting_rule__c','Reconciliation_Section__c','gl_amount__c','source_amount__c'
			});
			soql.addChildRelationship(childRel);

			Reconciliation__c recon = Database.query(soql.getQuery());

	        //FIN-611 -Add recon topics to initiate batch
	    	if(recon.Reconciliation_Topics__r.size()==0)
	        {
	           Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please add Recon topics') );

	        }
	        else
	        {
				system.debug('Reconciliation_Topics__r'+recon.Reconciliation_Topics__r);
	
		 		GLAccount=recon.GL_Account__c;
		 		
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('GL_Account__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'ID','Name','SubAccount_of__c'
				});
				soql.setWhereClause('ID = :GLAccount OR SubAccount_of__c = :GLAccount OR SubAccount_of__r.SubAccount_of__c = :GLAccount OR '
									+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccount OR SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccount OR '
									+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccount');
	
				list<GL_account__c> associatedGLAccounts = Database.query(soql.getQuery());
	
		    	map<id,GL_account__c> mAssociatedGLAccounts = new map<id,gl_account__c>(associatedGLAccounts);		
		    	associatedGLAccountsSer = JSON.serialize(mAssociatedGLAccounts.keyset()); //Serialized List of GL ids used by Page
	
		 		Period=recon.period__c;
		 		ReconId=recon.Id;
		 		CompanyId= recon.Company__c;
		 		inputRuleIds = new set<id>();
		 		updateTopics = new list<Reconciliation_Topic__c>();
		 		deleteTopics = new list<Reconciliation_Topic__c>();
	
		 		cleanupTopics(recon.Reconciliation_Topics__r);
	
		        sourceDocAPINamesSer= JSON.serialize(sourceDocAPINames);//Used in page
		       	ARSpecsSer = JSON.serialize(inputRuleIds); //Serialized List of Rule ids used by Page
		        isInitSuccess=true;
	
		       	system.debug('sourceDocAPINames'+sourceDocAPINamesSer);
		       	system.debug('ARSpecsSer'+ARSpecsSer);
		       	system.debug('isInitSuccess'+isInitSuccess);
	        }
        }
        catch(Exception ex)
        {
        	system.debug('inside init exception'+ex.getMessage());
	        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()) );
	        isInitSuccess=false;

        }
    }

    public void cleanupTopics(list<Reconciliation_Topic__c> rtlist)
    {
    	system.debug('Reconciliation_Topics__r'+rtlist);
        for(Reconciliation_Topic__c rt:rtlist)
        {

        	if(rt.accounting_rule__c!=null)//User given RT
        	{
        		system.debug('type'+rt.type__c);
        		 string SDAPIName=ReconRemoteService.getAPINameForSDType(rt.type__c);
        		    if(SDAPIName!='Not Found' && SDAPIName!=null)
        		    {
	 					sourceDocAPINames.add(SDAPIName) ;    
						inputRuleIds.add(rt.accounting_rule__c);           		    	
        		    }
        		    else
        		    {
				    	Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Recon Topic'+rt.type__c) );
				        isInitSuccess=false;
        		    }
         			
        		 		
        	}
        	if(rt.type__c=='System Generated')//Accrual and Manual and Autpo generated Entries with Exceptions
        	{
        		    deleteTopics.add(rt);
        	}

        	else
        	{
        		rt.Reconciliation_Section__c='';
        		rt.Source_Amount__c=0.0;
        		rt.GL_Amount__c=0.0;
        		updateTopics.add(rt);
        	} 

        }   
        if(deleteTopics.size()>0)
    	{
    		DML.deleteAsUser(deleteTopics);
    	}      
    	if(updateTopics.size()>0)
    	{
    		DML.updateAsUser(updateTopics);

    	}	

    }
    
    public ReportSummaryView populateSummaryObj(Reconciliation_Topic__c rt,string SDName)
    {
    	  ReportSummaryView summobj = new ReportSummaryView();
    	 system.debug('rt'+rt);
    	 if(mRptSDsec.containskey(SDName))
    	 {
    	 	summobj=mRptSDsec.get(SDName);
    	 	//KNDY-10048 Adding null check.
			summobj.AELAmount=(rt.gl_amount__c== null?0:rt.gl_amount__c)+summobj.AELAmount;
			summobj.SDLAmount=(rt.source_amount__c== null?0:rt.source_amount__c)+summobj.SDLAmount;
    	 }
    	 else
    	 {
			 summobj.AELAmount=rt.gl_amount__c== null?0:rt.gl_amount__c;
			 summobj.SDLAmount=rt.source_amount__c== null?0:rt.source_amount__c;  	 	
    	 }

		 return summobj;  	
    }
    //Get number of retries for parallel chunks from custom setting
    public static Integer getRetries() {
        Integer batchSize = 4; 

        Integer minValue = 1;   
        Integer maxValue = 100; 
        
        Configuration__c c = Configuration__c.getValues('reconReportRetries');
        //attempt to parse the string config value into an integer and make sure it is between min/max
        //if not we are just going to use the default
        if (c != null) {
            Integer configBatch;
            try {configBatch = Integer.valueOf(c.Value__c);} catch (Exception e) {}
            if (configBatch != null) {
                if ( (configBatch >= minValue) && (configBatch <= maxValue) ) {
                    batchSize = configBatch;
                }
            }
        }
        return batchSize;               
    } 
    
    @readonly
    @remoteaction
    public static list<ChunkResultAggregateTotalsByRule> aggregateSDAELTotals(id ARId,id Period,list<id> GLIds)
    {
        list<chunkResultAggregateTotalsByRule>  chunkAggrResultList = new list<chunkResultAggregateTotalsByRule>();
    	chunkResultAggregateTotalsByRule chunkAggrResultGlobal = new chunkResultAggregateTotalsByRule();					    		
        
        set<id> GLFamily = new set<id>(GLIds);
    	try
    	{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','object_name__c','Amount_Reference__c'
			});
			soql.setWhereClause('id=:ARId');

			accounting_rule__c CurrAR= Database.query(soql.getQuery());

	    	string costfield='';
	    	string costoverride='';
	    	string sourceDocLineRef='';
	    	string sourceDocRef='';
	    	id currARiD=CurrAR.Id;
           
            //KNDY-9639 Moving the OtherSD Exception UP to error out for both rules with amout override and no override.	    	
	    	string costFieldFromService=ReconRemoteService.getDefaultLineCostFieldForSD(CurrAR.Object_Name__c);
			if(costFieldFromService!=null && costFieldFromService!='Not Found'){
				if(CurrAR.Amount_Reference__c!=null)
		    	{
		    		costoverride=CurrAR.Amount_Reference__c;
		    	}
		    	else
		    	{
					costoverride=costFieldFromService;
		    	}
			}  
			else{

	        	chunkResultAggregateTotalsByRule chunkAggrResult = new chunkResultAggregateTotalsByRule();					
		    	chunkAggrResult.AELAmount=0;
		        chunkAggrResult.SDLAmount=0;	
		        chunkAggrResult.isIncorrectAmt=false;
		        chunkAggrResult.isIncorrectRule=false;
		        
		        if(costFieldFromService=='Not Found')
		        { //This flow happens if user had added any new picklist vales to type in Recon topics.
			      chunkAggrResult.isOtherSD=true;	
			      chunkAggrResult.SDName =CurrAR.Object_Name__c;  
			      chunkAggrResult.ARuleId=currARiD;     
			      				      		          		        	
	              chunkAggrResult.message=ReconRemoteService.ReconInfoMessage; 
	              
	              //Summarize the GL Amount booked by rule belonging to other SDs.

					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					
					soql = new SOQLUtil('accounting_entry_line__c', true, true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'sum(balance_f__c) aelamt','accounting_rule__c Arule'
					});
					soql.setWhereClause('accounting_entry__r.period__c=:Period and accounting_rule__c=:currARiD and GL_Account__c = :GLFamily and status__c=\'Active\' group by accounting_rule__c');

					list<aggregateresult> arForOtherSD = Database.query(soql.getQuery());

	         	     decimal AELAmount ;                                   
	         	     if(arForOtherSD.size()>0)
	         	     {
	         	       AELAmount=(decimal)arForOtherSD[0].get('aelamt');		            
		               AELAmount=(AELAmount==null)?0:AELAmount;	
	         	     }
	         	     else
	         	     {
	         	     	AELAmount=0;
	         	     }
	         	     		            
			        chunkAggrResult.AELAmount=AELAmount; 
		                	                                                      	        	
		        }
		        else
		        {
		          chunkAggrResult.isValid=false;			          
			      chunkAggrResult.message='Error getting default cost for the SD '+CurrAR.Object_Name__c+costFieldFromService;					
		        	
		        }
		        chunkAggrResultList.add(chunkAggrResult);
		        return chunkAggrResultList;
			}
								  	

	        sourceDocLineRef=ReconRemoteService.getSDLRefWithDotForSD(CurrAR.Object_Name__c);
		    sourceDocRef=ReconRemoteService.getSourceDocRefWithDot(CurrAR.Object_Name__c);
		    
    	   /* boolean hasVoid = util.fieldExists(CurrAR.Object_Name__c,'void__c');
    	    string voidField = (hasVoid==true)?' and '+sourceDocLineRef+sourceDocRef+'void__c=false':'';*//*
	    	costfield= 'SUM( '+sourceDocLineRef+costoverride+' ) sdlamt';
	    	
	        set<id> VoidAELIdsToExclude = new set<Id>();
	        VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),period,false);
			
			String withoutExceptionsClause = 'accounting_entry__r.period__c=:Period '  
			                                 +' and accounting_rule__c=:currARiD'  
			                                 +' and status__c=\'Active\''  
			                                 +' and id not in :VoidAELIdsToExclude '			                                             
			                                 +' and accounting_entry__r.Has_Exceptions__c=false' // Has_exceptions__c = false               	                             
			                                 +' group by accounting_rule__c,GL_Account__c';
			
			String withExceptionsClause = 'accounting_entry__r.period__c=:Period '  
			                                 +' and accounting_rule__c=:currARiD'  
			                                 +' and status__c=\'Active\''  
			                                 +' and id not in :VoidAELIdsToExclude '			                                             
			                                 +' and accounting_entry__r.Has_Exceptions__c=true'  // Has_exceptions__c = true                	                             
			                                 +' group by accounting_rule__c,GL_Account__c';                                  
        	
        	Set<String> aelFields = new Set<String>{'sum(Amount_CR__c) aelamtCR', costfield, 'sum(Amount_DR__c) aelamtDR',
			        	        					'sum(balance_f__c) aelamt', 'accounting_rule__c Arule', 'GL_Account__c GLId'};
		    
		    soql = new SOQLUtil('accounting_entry_line__c', true, true);
		    soql.addFields(aelFields);

		    soql.setWhereClause(withoutExceptionsClause);
	        list<AggregateResult> aggrAELWithoutExceptionByRuleGL = Database.query(soql.getQuery());
	        
	        soql.setWhereClause(withExceptionsClause);
	        list<AggregateResult> aggrAELWithExceptionByRuleGL = database.query(soql.getQuery());

	        //Aggregate Amounts by Rule across the GL Family.

	        if(aggrAELWithoutExceptionByRuleGL.size()>0)
	        {
	        	chunkResultAggregateTotalsByRule chunkAggrResult = new chunkResultAggregateTotalsByRule();	        	
		        chunkAggrResult.ARuleId=currARiD;     
		        chunkAggrResult.SDName =CurrAR.Object_Name__c;  
		        chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  
		        for(AggregateResult ar:aggrAELWithoutExceptionByRuleGL)
		        {
		        	ID GLId = (ID)ar.get('GLId');
		         	ID RuleId = (ID)ar.get('Arule');
		         	//Validate the GL corresponding to rule
		         	if(GLFamily.contains(GLId))
		         	{
		         		chunkAggrResult.isIncorrectRule=false;
		         	}
		         	else
		         	{
		         		//Incorrect Rule - could be due to incorrect reference value for GL
		         		//Added to unreconciled section.
		         		chunkAggrResult.isIncorrectRule=true; 

		         	}
		            decimal AELAmount=(decimal)ar.get('aelamt');
		            decimal SDLAmount=(decimal)ar.get('sdlamt');
		            
		            AELAmount=(AELAmount==null)?0:AELAmount;
		            SDLAmount=(SDLAmount==null)?0:SDLAmount;
		            
			        chunkAggrResult.AELAmount=chunkAggrResult.AELAmount+ AELAmount;
			        chunkAggrResult.SDLAmount=chunkAggrResult.SDLAmount+ SDLAmount;    	

		        }
		        // Validate if source and AEL totals match for the rule.
		        //TODO:Add expected sign logic.
				//FIN-1165 Fix Payments and receipts result in negative balance but the source is positive.
		         if(math.abs(chunkAggrResult.AELAmount)!=math.abs(chunkAggrResult.SDLAmount))
		     //	 if(chunkAggrResult.AELAmount!=chunkAggrResult.SDLAmount)
		         {
	                //Added to unreconciled section.	         	
		         	chunkAggrResult.isIncorrectAmt=true;
		         }
		         else
		         {
		          	chunkAggrResult.isIncorrectAmt=false;
		        	
		         }////There is possibility of both incorrect rule and incorrect amount when user gives the wrong rule type (CR Vs DR).Page takes precedence of incorrect Rule
		         chunkAggrResult.isValid=true;
		         
		         //For incorrect rules ,Wipe off GL Amount in chunkresult  as they are booking to some other GL and don't contribute to current GL being reconciled.		
		         if(chunkAggrResult.isIncorrectRule)
		         {
		         	chunkAggrResult.AELAmount=0;
		         }         
		         chunkAggrResultList.add(chunkAggrResult);
		         
		     }
		      if(aggrAELWithExceptionByRuleGL.size()>0)
		     {
	        	chunkResultAggregateTotalsByRule chunkAggrResult = new chunkResultAggregateTotalsByRule();	        	
		        chunkAggrResult.ARuleId=currARiD;     
		        chunkAggrResult.SDName =CurrAR.Object_Name__c;  
		        chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  
	         	chunkAggrResult.hasExceptions=true;		     	
		        for(AggregateResult ar:aggrAELWithExceptionByRuleGL)
		        {
		            decimal AELAmount=(decimal)ar.get('aelamt');
		            decimal SDLAmount=(decimal)ar.get('sdlamt');
			        ID GLId = (ID)ar.get('GLId');
		         	if(GLFamily.contains(GLId))
		         	{
		                AELAmount=(AELAmount==null)?0:AELAmount;
		                
		         	}
		         	else
		         	{ //Exception is due to missing GL  and/or incorrect GL.Do not consider the Line or source amounts for aggregation.
		  		        AELAmount=0;
		         	}	            
		            SDLAmount=(SDLAmount==null)?0:SDLAmount;//In case the CR/DR counterpart rule is also included in topics  ,the source amount will be doubled.Common for all sections.
		            
			        chunkAggrResult.AELAmount=chunkAggrResult.AELAmount+ AELAmount;
			        chunkAggrResult.SDLAmount=chunkAggrResult.SDLAmount+ SDLAmount;    	

		        }	
		         chunkAggrResult.isValid=true;		         
		         chunkAggrResultList.add(chunkAggrResult);	     	
		     }
		     if(chunkAggrResultList.size()==0)
		     {
	        	chunkResultAggregateTotalsByRule chunkAggrResult = new chunkResultAggregateTotalsByRule();	      
		        chunkAggrResult.ARuleId=currARiD;     
		        chunkAggrResult.SDName =CurrAR.Object_Name__c;  
		        chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  	        	  			     	
		    	chunkAggrResult.AELAmount=0;
		        chunkAggrResult.SDLAmount=0;	
		        chunkAggrResult.isIncorrectAmt=false;
		        chunkAggrResult.isIncorrectRule=false;
		        chunkAggrResult.hasExceptions=false;
		        chunkAggrResult.isValid=true;		         
		        chunkAggrResultList.add(chunkAggrResult);	 	           
		     }  
  		
    	 
    	}
    	catch(Exception ex)
    	{
		    	chunkAggrResultGlobal.AELAmount=0;
		        chunkAggrResultGlobal.SDLAmount=0;	
		        chunkAggrResultGlobal.isIncorrectAmt=false;
		        chunkAggrResultGlobal.isIncorrectRule=false;
		        chunkAggrResultGlobal.hasExceptions=false;		        
		        chunkAggrResultGlobal.isValid=false;
	            chunkAggrResultGlobal.message='Error during Reconciliation Process '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
				chunkAggrResultList.add(chunkAggrResultGlobal);
				system.debug(LoggingLevel.ERROR, ex);
    	}


        return chunkAggrResultList;

    }
    @readonly
    @remoteaction
    public static chunkResultAggregateTotalsBySD getAccrualCandidates(id ReconId,string SD)
    {
        chunkResultAggregateTotalsBySD  chunkAggrResult = new chunkResultAggregateTotalsBySD();

    	try
    	{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Reconciliation__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','company__c','Period__c','Period__r.Period_Start__c','Period__r.Period_End__c'
			});
			soql.setWhereClause('id=:ReconId');

			Reconciliation__c recon = Database.query(soql.getQuery());
			string costfield;
	    	string costFieldFromService;
	    	string soqlQueryObject; 
			//TODO:Change variable name from  costs to Amount.
			if(SD == 'Bank_Transaction_Group__c'){
			costFieldFromService = 'amount__c';
			soqlQueryObject = 'Bank_Transaction__c';
			//SD = 'Bank_Transaction__c';
			}else{
		     costFieldFromService = ReconRemoteService.getDefaultCostFieldForSD(SD);
		     soqlQueryObject = SD;
			}
	    	
			//TODO:Change variable name from  costs to Amount.
		    //string costFieldFromService=ReconRemoteService.getDefaultCostFieldForSD(SD);
			if(costFieldFromService==null ||  costFieldFromService=='Not Found')
			{
		    	chunkAggrResult.AELAmount=0;
		        chunkAggrResult.SDLAmount=0;
		        chunkAggrResult.SDName=SD;	
		        if(costFieldFromService=='Not Found')
		        {
				  //This flow happens if user had added any new picklist vales to type in Recon topics and it had bypassed the newRecontopicext validation Somehow.
			      chunkAggrResult.isOtherSD=true;	
			      chunkAggrResult.SDName =SD;  
		          chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  
				  chunkAggrResult.RT = new Reconciliation_Topic__c();
			      chunkAggrResult.RT.name=SD+'|'+'otherSD';
			      chunkAggrResult.RT.ReconTopic_Unique_Key__c=recon.id+SD+'|'+'otherSD';
			      chunkAggrResult.RT.source_amount__c=chunkAggrResult.SDLAmount;
			      chunkAggrResult.RT.gl_amount__c=chunkAggrResult.AELAmount;
				  chunkAggrResult.RT.Type__c='System Generated';
			      chunkAggrResult.RT.Reconciliation_Section__c='otherSD';
			      chunkAggrResult.RT.Reconciliation__c=recon.id;
		        }
		        else
		        {
		          chunkAggrResult.isValid=false;
			      chunkAggrResult.message='Error  getting default cost for the SD in Accruals '+SD+costFieldFromService;					
		        	
		        }
		        return chunkAggrResult;
			}
			
			Datetime ps = recon.Period__r.Period_Start__c;
			Datetime pe = recon.Period__r.Period_End__c;
			Id ReconPeriod = recon.period__c;
			Id ReconCompany = recon.company__c;
			
			costfield = 'SUM('+ costFieldFromService + ') sdlamt';
		    
            String whereClause;
            if(SD != 'Bank_Transaction_Group__c'){
			whereClause = 'Company__c =:ReconCompany'+ ' AND status__c != '
			 						+ '\''+String.escapeSingleQuotes('Cancelled')+'\''
			 						 +' AND Historical__c = false'							
			 						+ ' AND Transaction_Date__c >=:ps  AND Transaction_Date__c < :pe' 
			 						+ ' AND Id NOT IN (SELECT ' + String.escapeSingleQuotes(SD) + ' FROM Accounting_Entry__c  WHERE status__c=\'Active\'  and period__c =:ReconPeriod  ' +')' 
			 						+ ' AND Id NOT IN (SELECT ' + String.escapeSingleQuotes(SD) + ' FROM Journal_Entry__c  WHERE Finalized__c=true AND GL_Date_Time__c >= :ps ' 
		 												  + ' AND GL_Date_Time__c < :pe' + ')';
            }else{
			whereClause = 'Company__c =:ReconCompany'+ ' AND status__c != '
			 						+ '\''+String.escapeSingleQuotes('Cancelled')+'\''
			 						+ ' AND Transaction_Date__c >=:ps  AND Transaction_Date__c < :pe' 
			 						+ ' AND Id NOT IN (SELECT ' + String.escapeSingleQuotes(soqlQueryObject) + ' FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.status__c=\'Active\'  and Accounting_Entry__r.period__c =:ReconPeriod  ' +')' 
			 						+ ' AND Id NOT IN (SELECT ' + String.escapeSingleQuotes(soqlQueryObject) + ' FROM Journal_Entry_Line__c  WHERE Journal_Entry__r.Finalized__c=true AND Journal_Entry__r.GL_Date_Time__c >= :ps ' 
		 												  + ' AND Journal_Entry__r.GL_Date_Time__c < :pe' + ')';                

            }
        
		    soql = new SOQLUtil(soqlQueryObject, true, true);
		    soql.addFields(new Set<String>{costfield});
		    soql.setWhereClause(whereClause);

		  	list<AggregateResult> SDsWithoutAE = database.query(soql.getQuery());

          	decimal sdlAmount =(Decimal)SDsWithoutAE[0].get('sdlamt');
          	sdlAmount=(sdlAmount==null)?0:sdlAmount;

		  	if(sdlAmount!=0)
		  	{
				  chunkAggrResult.AELAmount=0;
				  chunkAggrResult.SDLAmount=sdlAmount;
				  chunkAggrResult.SDName=SD;	
				  chunkAggrResult.isValid=true;
				  chunkAggrResult.isRowsPresent=true;		      
				  chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  
				  chunkAggrResult.RT = new Reconciliation_Topic__c();
				  chunkAggrResult.RT.name=SD+'|'+'Accrual';
				  chunkAggrResult.RT.ReconTopic_Unique_Key__c=recon.id+SD+'|'+'Accrual';
				  chunkAggrResult.RT.source_amount__c=chunkAggrResult.SDLAmount;
				  chunkAggrResult.RT.gl_amount__c=chunkAggrResult.AELAmount;
				  chunkAggrResult.RT.Type__c='System Generated';
				  chunkAggrResult.RT.Reconciliation_Section__c='Accrual';
				  chunkAggrResult.RT.Reconciliation__c=recon.id;
		  	}
		  	else
		  	{
				  chunkAggrResult.AELAmount=0;
				  chunkAggrResult.SDLAmount=0;
				  chunkAggrResult.SDName=SD;	
			      chunkAggrResult.isValid=true;
			      chunkAggrResult.isRowsPresent=false;
	
			      chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  		  	
		  	}
	    }
	    catch(Exception ex)
    	{
		    	chunkAggrResult.AELAmount=0;
		        chunkAggrResult.SDLAmount=0;
		        chunkAggrResult.SDName=SD;	
	            chunkAggrResult.message='Error during Reconciliation Process '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
	            chunkAggrResult.isValid=false;

    	}
    	return chunkAggrResult;

    }
    @readonly
    @remoteaction
    public static list<chunkResultAggregateTotalsBySD> getUnmatchedAELTotals(list<id> ruleset ,list<id> GLFamily,id period,id reconid)
    {
    	list<chunkResultAggregateTotalsBySD>  chunkAggrResultList = new list<chunkResultAggregateTotalsBySD>();
									    	 
    	try
    	{
	        set<id> VoidAELIdsToExclude = new set<Id>();
	        VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),period,false);
		
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true, true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Accounting_Entry__r.Source_Document_Object_Name__c SDName','accounting_rule__c rule','sum(balance_f__c) aelamt','sum(amount_dr__c) aelamtDR',
				'sum(amount_cr__c) aelamtCR'
			});
			soql.setWhereClause('accounting_entry__r.period__c=:period and gl_account__c in :GLFamily and accounting_rule__c not in :ruleset and status__c=\'Active\' '
								+' and id not in :VoidAELIdsToExclude and Accounting_Entry__r.Source_Document_Object_Name__c!=\'Journal_Entry__c\' '
								+' group by Accounting_Entry__r.Source_Document_Object_Name__c,accounting_rule__c');
								
			list<aggregateresult> AELfromRulesOutsideScope = Database.query(soql.getQuery());

		  list<Reconciliation_Topic__c> RTList = new list<Reconciliation_Topic__c>();
	      decimal AELAmountTotalbySD = 0;
	      decimal SDLAmountTotalbySD = 0;		  
		  
		  if(AELfromRulesOutsideScope.size()>0)
		  {
		  	  string currSDName ;
		  	  string prevSDName ;
		  	  chunkResultAggregateTotalsBySD chunkAggrResult;
		  	  map<string,chunkResultAggregateTotalsBySD> mOtherSDNametoChunkResult = new  map<string,chunkResultAggregateTotalsBySD>();
		  	  
			  for(aggregateresult ar : AELfromRulesOutsideScope)
			  {

			        
				   string SDName = (string)ar.get('SDName');
		           Id ruleId     = (Id)ar.get('rule');
		           currSDName = SDName;
		           
                   //Build a recon Topic for the unmatched rule
	               Reconciliation_Topic__c RT = new Reconciliation_Topic__c();		                   
				   RT.accounting_rule__c = (Id)ar.get('rule');
			       RT.Reconciliation__c=reconId;
			       
			       
	       		   decimal AELAmount=(decimal)ar.get('aelamt');
			  	   AELAmount=(AELAmount==null)?0:AELAmount;
				   RT.GL_amount__c=AELAmount;
                   //KNDY-10048
					/*Get Costfield for the SD for which we are aggregating amounts*//*
				   string costFieldFromService=ReconRemoteService.getDefaultLineCostFieldForSD(SDName);
					if(costFieldFromService==null ||  costFieldFromService=='Not Found')
					{

				        if(costFieldFromService=='Not Found')//This flow happens if the unmatched rule belongs to someotheR SD not in Recon supported scope.				        
				        {
				          //KNDY-10048 Handle multiple Accounting Rules belonging to OtherSD section.
				          chunkResultAggregateTotalsBySD otherSDNameChunkResult;
						  RT.name=SDName+'|'+RT.accounting_rule__c+'otherSD';
					      RT.ReconTopic_Unique_Key__c=reconId+'|'+SDName+'|'+RT.accounting_rule__c+'|'+'otherSD';
					      RT.Type__c='System Generated';
					      RT.Reconciliation_Section__c='otherSD';
					      RT.source_amount__c=0;				          
				          //Group the rule level chunkResults by SD.
						  if( mOtherSDNametoChunkResult.containsKey(currSDName))
						  {						  	
						  	  otherSDNameChunkResult = mOtherSDNametoChunkResult.get(currSDName);	
						  	  otherSDNameChunkResult.rtlist.add(RT);					
							  otherSDNameChunkResult.AELAmount=OtherSDNameChunkResult.AELAmount+AELAmount;						  	
						  }
						  else
						  {					  	 
							  otherSDNameChunkResult = new chunkResultAggregateTotalsBySD();						
						      otherSDNameChunkResult.AELAmount=AELAmount;
						      otherSDNameChunkResult.SDLAmount=0;
						      otherSDNameChunkResult.SDName=currSDName;	
						      otherSDNameChunkResult.isOtherSD=true;	
				              otherSDNameChunkResult.message=ReconRemoteService.ReconInfoMessage;  
							  otherSDNameChunkResult.rtlist.add(RT); 
							  mOtherSDNametoChunkResult.put(currSDName,otherSDNameChunkResult);  
							  chunkAggrResultList.add(otherSDNameChunkResult);
							  
						  }
				        	
				        }
				        else
				        {
				          chunkResultAggregateTotalsBySD chunkAggrResultException = new chunkResultAggregateTotalsBySD();						
						  chunkAggrResultException.AELAmount=0;
						  chunkAggrResultException.SDLAmount=0;					  
						  chunkAggrResultException.SDName=currSDName;							  
				          chunkAggrResultException.isValid=false;				          
					      chunkAggrResultException.message='Error  getting default cost for the SD in unmatched report section '+SDName+costFieldFromService;					
				          chunkAggrResultList.add(chunkAggrResultException);
				        	
				        }
					}
					else
					{
						//Populate source amount for each unmatched rule for topic
						//Accumulate source amount at SD Level for chunkresult object
						
						list<AggregateResult> SDCosts= new list<AggregateResult>();
						RT.name=SDName+'|'+RT.accounting_rule__c+'Unmatched';
				        RT.ReconTopic_Unique_Key__c=reconId+'|'+SDName+'|'+RT.accounting_rule__c+'|'+'Unmatched';
				        RT.Type__c='System Generated';
				        RT.Reconciliation_Section__c='Unmatched';
				        
	                    if(currSDName!= prevSDName )
	                    {
			                chunkAggrResult = new chunkResultAggregateTotalsBySD();
					  	    
					        chunkAggrResult.SDName=(string)ar.get('SDName');
    
					        string costfield =ReconRemoteService.getSDLRefWithDotForSD(SDName)+costFieldFromService;
					        /*string query = 'select Accounting_Entry__r.Source_Document_Object_Name__c SDName,accounting_rule__c rule,'
		    	 			  +' sum('+costfield+') sdlamt'
		    	 			  +' from accounting_entry_line__c'
		    	 			  +' where accounting_entry__r.period__c=:period '
							  +' and gl_account__c in :GLFamily '
							  +' and status__c=\'Active\''
							  +' and Accounting_Entry__r.Source_Document_Object_Name__c= :SDName'
							  +' group by Accounting_Entry__r.Source_Document_Object_Name__c,accounting_rule__c';*//*
							  
							Set<String> aelFields = new Set<String>{'Accounting_Entry__r.Source_Document_Object_Name__c SDName',
								'accounting_rule__c rule', 'sum('+costfield+') sdlamt'};
							
							String whereClause = 'accounting_entry__r.period__c=:period '
												  +' and gl_account__c in :GLFamily '
												  +' and status__c=\'Active\''
												  +' and Accounting_Entry__r.Source_Document_Object_Name__c= :SDName'
												  +' group by Accounting_Entry__r.Source_Document_Object_Name__c,accounting_rule__c';
        
						    soql = new SOQLUtil('accounting_entry_line__c', true, true);
						    soql.addFields(aelFields);
						    soql.setWhereClause(whereClause);
	      
							SDCosts = database.query(soql.getQuery());
							if(SDCosts.size()>0)
							{
							   for(AggregateResult costsSDRule : SDCosts)
							   {
								   decimal sdlamt=(decimal)costsSDRule.get('sdlamt');
								   sdlamt=(sdlamt==null)?0:sdlamt;						
						           chunkAggrResult.SDLAmount=chunkAggrResult.SDLAmount+sdlamt;
						           if((id)costsSDRule.get('rule')==ruleId)
						           {
						           	 RT.source_amount__c=sdlamt;
						           }
								   	
							   }
							   

							}
							else
							{
					           chunkAggrResult.SDLAmount=0;
		
							}	
							chunkAggrResult.AELAmount=AELAmount	;
							chunkAggrResult.rtlist.add(RT);                  	
					        chunkAggrResultList.add(chunkAggrResult);
											
							prevSDName = currSDName;	                    	
	                    }
	                    else//No need to requery for source amount as we have the above aggregate result for source amount .Need to accumulate GL Amount by SD .Also, get source amount by rule for topic.
	                    {
							if(SDCosts.size()>0)
							{
							   for(AggregateResult costsSDRule : SDCosts)
							   {
						           if((Id)costsSDRule.get('rule')==ruleId) 
						           {
						           	 RT.source_amount__c=(decimal)costsSDRule.get('sdlamt');
						           }
								   	
							   }   

							}
							else
							{
								RT.source_amount__c=0;
							}  
							chunkAggrResult.AELAmount=chunkAggrResult.AELAmount+AELAmount;
							chunkAggrResult.rtlist.add(RT);   
							//chunkAggrResultList.add(chunkAggrResult);
							               	
	                    } 
				

					   //chunkAggrResultList.add(chunkAggrResult);
	
					}
			  }	

		  }

 

    	}
    	catch(Exception ex)
    	{
    		    chunkResultAggregateTotalsBySD chunkAggrResult = new chunkResultAggregateTotalsBySD();
		    	chunkAggrResult.AELAmount=0;
		        chunkAggrResult.SDLAmount=0;
		        chunkAggrResult.SDName='';	
	            chunkAggrResult.message='Error during Reconciliation Process '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
	            chunkAggrResult.isValid=false;
	            chunkAggrResultList.add(chunkAggrResult);


    	}
    	return chunkAggrResultList;


    }
    /*Get the std Report URL appended with reconciled rules filter and current recon period*//*
    @readonly
    @remoteaction      
    public static list<ReportURLResult> getReportURL(id reconId)
    {
        updateResult result = new updateResult();
        list<reconciliation_topic__c> reconciledTopics = new list<reconciliation_topic__c>();
        
                        
        Boolean ARReport = false;
        Boolean APReport = false;
        set<string> ARSDsList = new set<string>{'Bank File','Customer Invoice','Customer Receipt'};
        set<string> APSDsList = new set<string>{'Supplier Invoice','Supplier Payment'};
	    list<ReportURLResult> ReportURLResultList = new list<ReportURLResult>();
        
        string URLString;
        
        Report standardReconReport;
        Id standardReconReportId;
        Reports.ReportMetaData metaData;
        list<Reports.ReportFilter> reportFilters = new list<Reports.ReportFilter>() ;
	    list<string> pvstringlist = new list<string>();
	    
	    set<String> RuleNames = new set<string>();
 	    String periodName;
        
        try
        {

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('reconciliation__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','period__c','period__r.name','GL_Account__c','gl_Account__r.name'
			});
			soql.setWhereClause('id =:reconId');
			
			reconciliation__c recon = Database.query(soql.getQuery());

			soql = new SOQLUtil('Reconciliation_topic__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','accounting_rule__c','accounting_rule__r.name','type__c'
			});
			soql.setWhereClause('reconciliation_section__c=\'Reconciled\' and Reconciliation__c=:reconId');

			reconciledTopics = Database.query(soql.getQuery());
			 					   
		//Get the list of SDs reconciled with respective rules from Topics
		for(reconciliation_topic__c rt:reconciledTopics)
		{
			string SDName=rt.type__c;
			string subledgertype='';
			if(ARSDsList.contains(SDName))
			{
				subledgertype='AR';
			}
			else
			{
				subledgertype='AP';				
			}
		     populateAggregates(sdname,rt.accounting_rule__r.name,subledgertype);

		}
		
		    	
		periodName = Recon.period__r.name;	
		
		for(string subLedgerType : mSubledgerToSDRules.keyset())
		{
			list<Report> standardReconReports = new list<Report>();
			if(subLedgerType=='AR')
			{
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Report', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name'
				});
				soql.setWhereClause('DeveloperName = \'Reconciled_Accounting_Entries_for_AR\'');
				soql.setLimit(1);

				standardReconReports = Database.query(soql.getQuery());

			}
			else if(subLedgerType=='AP')
			{
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Report', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name'
				});
				soql.setWhereClause('DeveloperName = \'Reconciled_Accounting_Entries_for_AP\'');
				soql.setLimit(1);

				standardReconReports = Database.query(soql.getQuery());

			}

			for(string SDName:mSubledgerToSDRules.get(subLedgerType).keyset())
			{
				ReportURLResult rptResult = new ReportURLResult();
				pvstringlist = new list<string>();
				rptResult.SDName = SDName;
			    if(standardReconReports.size()>0)
			    {
			    	standardReconReport=standardReconReports[0];
			    }
			    if(standardReconReport!=null)
			    {
			  	    standardReconReportId = standardReconReport.Id ;			
					metaData = Reports.ReportManager.describeReport(standardReconReportId).getReportMetaData();
					
					if(metaData != null){
						
						//Get current report filters columns
						reportFilters = metaData.getReportFilters() ;
					    RuleNames=new set<string>(mSubledgerToSDRules.get(subLedgerType).get(SDName));
					    list<string> RuleNamesList = new list<string>(RuleNames);
					    list<string> rulesNamesFirst = new list<string>();
					    list<string> ruleNamesSecond  = new list<string>();
					    
						//If Only one rule ,add it to both lists.					    
						if(RuleNamesList.size()==1)
						{
							rulesNamesFirst.add(RuleNamesList[0]);
							ruleNamesSecond.add(RuleNamesList[0]);
						}
						//Split the rules set into two Lists based on index even/odd						
						for(integer i=0;i<RuleNamesList.size();i++)
						{
							if((math.mod(i,2))==0)
							{
								rulesNamesFirst.add(RuleNamesList[i]);

							}
							else
							{
								ruleNamesSecond.add(RuleNamesList[i]);					
								
							}
						}
						//Append the accounting rule and Period Filters to retrieved report.
						for(integer i=0;i< reportFilters.size();i++){
							string pvstring;
							 if(reportFilters[i].getColumn().contains('Accounting_Rule__c') && reportFilters[i].getOperator().contains('equals'))
							 {

								    if(ruleNamesSecond.size()>0 && i==2)
								    {
									pvstring = 'pv' + i +'=' + string.join(rulesNamesFirst,',');
								    	
								    }
								    if(ruleNamesSecond.size()>0 && i==3)
								    {
									pvstring = 'pv' + i +'=' + string.join(ruleNamesSecond,',');
								    	
								    }
							}	
							else if(reportFilters[i].getColumn().contains('Period') && reportFilters[i].getOperator().contains('equals')){
								   pvstring = 'pv' + i +'=' + Recon.period__r.name;
							}
							else if(reportFilters[i].getColumn().contains('GL_Account__c') && reportFilters[i].getOperator().contains('equals')){
								   pvstring = 'pv' + i +'=' + Recon.gl_Account__r.name;
							}				
							if(pvstring != null){
								pvstringlist.add(pvstring);
							}				
								
						}
				        if(pvstringlist.size() == 0){
				  			URLstring = '/'+standardReconReportId;
				        }
				  		else{  
				  			URLstring = '/'+standardReconReportId + '?' + string.join(pvstringlist,'&');
				    	} 	
				        rptResult.ReportURL=URLString;
				        rptResult.message='Successful Report retrieval';
				        rptResult.issuccess=true;
				    	
					}
					else
					{
				    	string message='Error has occured in Reconciled Entries Detail View - '+'Reconciled Accounting Entries Standard Report Metadata Not Found. ';
				        rptResult.ReportURL='';
				        rptResult.message=message;
				        rptResult.issuccess=false;						
					}
			     	system.debug('MetaData'+metaData); 
			     	system.debug('standardReportId'+standardReconReportId);   	     	  	
			    	system.debug('URLString'+URLString);
			    	system.debug('reportFilters'+reportFilters);
			    	system.debug('pvstringlist'+pvstringlist);	    	
				}
			    else
			    {
			    	string message='Error has occured in Reconciled Entries Detail View - '+' Reconciled Accounting Entries Standard Report Not Found or setup in this organization. ';
			        rptResult.ReportURL='';
			        rptResult.message=message;
			        rptResult.issuccess=false;				        	
			    	
			    }
			ReportURLResultList.add(rptResult);
	    				
			}
			
		}
		
    	       	
        }
        catch(Exception ex)
        {
        	ReportURLResult rptResult = new ReportURLResult();
        	rptResult.SDName=null;
        	string logs ='standardReportId :'+standardReportId+'MetaData :'+MetaData+' reportFilters : '+reportFilters+'Filter values :'+pvstringlist;
        	string message='Exception has occured in Reconciled Entries Detail View. '+ex.getmessage()+' at Line Number '+ex.getLineNumber() +' Logs :'+Logs;
        	result.issuccess=false;
	        rptResult.ReportURL='';
	        rptResult.message=message;
	        rptResult.issuccess=false;	
	        ReportURLResultList.add(rptResult);     	
        }
		        	
		return ReportURLResultList;  

    }
    public static void populateAggregates(string SDname,string ruleName,string subledgerType)
    {
    	system.debug('inside aggregates for report URL'+SDname+ruleName+subledgerType);
		if(mSubledgerToSDRules.containskey(subledgerType))
		{   //Aggregate rules at SubledgerLevel
			if (mSubledgerToSDRules.get(subledgerType).containskey(SDName))
			{
				//Aggregate rules at SDLevel
				mSubledgerToSDRules.get(subledgerType).get(SDName).add(ruleName);
			}
			else
			{
				mSubledgerToSDRules.get(subledgerType).put(SDName,new list<string>{ruleName});
			}
			
		}
		else
		{
		   map<string,list<string>> mSDToRules = new map<string,list<string>>();
		   mSDToRules.put(SDName,new list<string>{ruleName});
		   mSubledgerToSDRules.put(subledgerType,mSDToRules);	
		}	
    }
    @readonly
    @remoteaction
    public static chunkResultAggregateTotalsBySD getManualEntries(list<id> GLFamily,id period,id reconId)
    {
        chunkResultAggregateTotalsBySD chunkAggrResult = new chunkResultAggregateTotalsBySD();
    	try
    	{
	        set<id> VoidAELIdsToExclude = new set<Id>();
	        VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),period,true);        
    	 	
    	 	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true, true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Accounting_Entry__r.Source_Document_Object_Name__c SDName','sum(amount_dr__c) aelamtDR','sum(amount_cr__c) aelamtCR','sum(balance_f__c) aelamt'
			});
			soql.setWhereClause('accounting_entry__r.period__c=:period and gl_account__c in :GLFamily and status__c=\'Active\' '
								+' and Accounting_Entry__r.Source_Document_Object_Name__c=\'Journal_Entry__c\' and id not in :VoidAELIdsToExclude '
								+' group by Accounting_Entry__r.Source_Document_Object_Name__c');
			
			list<aggregateresult> AELfromManualEntries= Database.query(soql.getQuery());


			 if(AELfromManualEntries.size()>0)
			 {
			 	    decimal AELAmount = (decimal)AELfromManualEntries[0].get('aelamt');
			 	    chunkAggrResult.AELAmount=(AELAmount==null)?0:AELAmount;
			        chunkAggrResult.SDLAmount= chunkAggrResult.AELAmount;
			        chunkAggrResult.SDName='Journal_Entry__c';	
		            chunkAggrResult.isValid=true;
		            chunkAggrResult.isRowsPresent=true;
	
			 }

			 else
			 {
			    	chunkAggrResult.AELAmount=0;
			        chunkAggrResult.SDLAmount=0;
			        chunkAggrResult.SDName='Journal_Entry__c';	
		            chunkAggrResult.isValid=true;
		            chunkAggrResult.isRowsPresent=false;
	
		      }
		       chunkAggrResult.RT = new Reconciliation_Topic__c();
		       chunkAggrResult.RT.name='Journal_Entry__c'+'|'+'Manual';
		       chunkAggrResult.RT.ReconTopic_Unique_Key__c=reconId+'Journal_Entry__c'+'|'+'Manual';
		       chunkAggrResult.RT.source_amount__c=chunkAggrResult.SDLAmount;
		       chunkAggrResult.RT.gl_amount__c=chunkAggrResult.AELAmount;
		       chunkAggrResult.RT.Reconciliation_Section__c='Manual';
		       chunkAggrResult.RT.Reconciliation__c=reconId;
			   chunkAggrResult.RT.Type__c='System Generated';
			   chunkAggrResult.message=ReconRemoteService.ReconInfoMessage;  		  	
    	}
    	catch(Exception ex)
    	{
		    	chunkAggrResult.AELAmount=0;
		        chunkAggrResult.SDLAmount=0;
		        chunkAggrResult.SDName='Journal_Entry__c';	
	            chunkAggrResult.message='Error during Reconciliation Process '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
	            chunkAggrResult.isValid=false;

    	}
    	return chunkAggrResult;

    }
    @remoteaction
    public static updateResult updateAsOfNowDT(id reconid)
    {
    	updateResult updateResObj = new updateResult();
    	try
    	{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Reconciliation__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','as_of__c'
			});
			soql.setWhereClause('id = :reconid');

			Reconciliation__c recon = Database.query(soql.getQuery());

	         recon.as_of__c = system.now();
	         DML.updateAsUser(recon);
		     updateResObj.message= string.valueof(system.now());		  	
	         updateResObj.isSuccess=true;	
    	}
    	catch(exception ex)
    	
    	{
	            updateResObj.message='Error during Reconciliation aggregate update '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
	            updateResObj.isSuccess=false;
    	}
    	return updateResObj;


    }
    @remoteaction
    public static updateResult updateAggregates(id rule,id reconid,decimal SDLAmt,decimal GLAmt,string rptSection,string SDName)
    {
    	updateResult updateResObj = new updateResult();
    	try
    	{
    		if(rptSection=='Exceptions')
    		{
			   Reconciliation_Topic__c RT = new Reconciliation_Topic__c();
		       RT.name=SDName+'|'+reconId+'|'+rule+'|'+'Exceptions';
		       RT.ReconTopic_Unique_Key__c=reconId+'|'+rule+'|'+'Exceptions';
		       RT.source_amount__c=SDLAmt;
		       RT.gl_amount__c=GLAmt;		   
		       RT.Accounting_rule__c= rule;   
		       RT.Type__c='System Generated';
		       RT.Reconciliation_Section__c='Exceptions';
		       RT.Reconciliation__c=reconId;
		       DML.checkUpsertAsUser(RT); upsert RT ReconTopic_Unique_Key__c;			
    		}
    		else//Reconciled/UnreconcileAmount/UnreconciledRules report sections
    		{
	 	        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Reconciliation_Topic__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name','Reconciliation_Section__c'
				});
				soql.setWhereClause('Reconciliation__c=:reconid and accounting_rule__c=:rule');

				list<Reconciliation_Topic__c> RTAggregate= Database.query(soql.getQuery());

		    	 RTAggregate[0].source_amount__c=SDLAmt;
		    	 RTAggregate[0].gl_amount__c=GLAmt;
		    	 RTAggregate[0].Reconciliation_Section__c=rptSection;   
		    	 DML.updateAsUser(RTAggregate);  
		    	 			
    		}


		     updateResObj.message='Reconciliation process is being done .Please do not refresh the page'; 		  	
	         updateResObj.isSuccess=true;	    	 		
    	}
    	 catch(Exception ex)
    	{
	            updateResObj.message='Error during Reconciliation aggregate update '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
	            updateResObj.isSuccess=false;


    	}
    	return updateResObj;

    }
     @remoteaction
    public static updateResult updateSystemGenReconTopics(list<reconciliation_topic__c> rtList)
    {
    	updateResult updateResObj = new updateResult();
    	
    	try
    	{
        	DML.checkUpsertAsUser(rtList); upsert rtList ReconTopic_Unique_Key__c;
        	updateResObj.message='Reconciliation process is being done .Please do not refresh the page'; 		  	
	        updateResObj.isSuccess=true;  		
    	}
    	catch(Exception ex)
    	{
   	            updateResObj.message='Error during Reconciliation aggregate update '+ex.getMessage() +' At lineNumber '+ ex.getLineNumber(); 
	            updateResObj.isSuccess=false; 		
    	}
    	    	return updateResObj;
    	
    }
    
    
    
    public void donothing()
    {
    	system.debug('button clicked');
    }



    // Called from the page  
    public pageReference cancel(){ 
		return new pageReference('/' + reconId);
    }

    


	@remoteaction
	public static BegEndBalResult runBegBalReports(id ReconId,Boolean runningForBeginningBal,Boolean runningForEndingBal){
		set<string> relatedGLAccountIDs = new set<string>(); 
    	List<GL_Account__c> associatedGLAccounts = new List<GL_Account__c> ();
        BegEndBalobj = new BegEndBalResult();
        runningForBeginningBalance=runningForBeginningBal;
        runningForEndingBalance=runningForEndingBal;
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Reconciliation__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Company__c','Period__c','Period__r.Period_Start__c','Period__r.Period_End__c','Beginning_Balance__c','Ending_Balance__c',
			'Period__r.Name','GL_Account__c','GL_Account__r.Id','GL_Account__r.name'
		});
		soql.setWhereClause('id = :ReconId');
		soql.setLimit(1);

		currentRecon = Database.query(soql.getQuery());

	    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Report', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name'
		});
		soql.setWhereClause('DeveloperName = \'Reconciliation_Balance\'');
		soql.setLimit(1);

		Report standardReport = Database.query(soql.getQuery());

	    if(standardReport.Id != null ){
			standardReportId = standardReport.Id;
	    }
    	if(currentRecon.GL_Account__c != null){
    		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id glAccountId = currentRecon.GL_Account__c;
			
			soql = new SOQLUtil('GL_Account__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Name','SubAccount_of__c'
			});
			soql.setWhereClause('ID = :glAccountId OR SubAccount_of__c = :glAccountId OR '
								+' SubAccount_of__r.SubAccount_of__c = :glAccountId OR '
								+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :glAccountId OR '
								+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :glAccountId OR '
								+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :glAccountId');

			associatedGLAccounts = Database.query(soql.getQuery());

    	}
    	if(associatedGLAccounts.size() > 0){
    		for(GL_Account__c localGLAccount : associatedGLAccounts){ 
	    		relatedGLAccountIDs.add(localGLAccount.name );  
	    	}
    	} 
    	
    	List<String> glAccountIDList  = new List<String>();
    	for(string relatedGLAccountID :relatedGLAccountIDs){
    		glAccountIDList.add( relatedGLAccountID);
    	}
    	
        glAccountIDs = string.join(glAccountIDList, ','); 
		
		Reports.ReportMetaData metaData;
		Boolean foundReport = true;
		if(standardReportId != null){
			//try {
				metaData = Reports.ReportManager.describeReport(standardReportId).getReportMetaData();
			//} catch(Exception e) {
			//	foundReport = false;
			//	BegEndBalobj.isValid=false;
			//}
		}
		List<Reports.ReportFilter> reportFilters = new List<Reports.ReportFilter>() ;
		if(metaData != null){
			reportFilters = metaData.getReportFilters() ;
		}
		String GLAccountID = currentRecon.GL_Account__c;
		String GLAccountName = currentRecon.GL_Account__r.Name;
		String PeriodID = currentRecon.Period__c;
		String periodStart = String.ValueOf(currentRecon.Period__r.Period_Start__c);
		String periodEnd = String.ValueOf(currentRecon.Period__r.Period_End__c);
		string NamespaceUU=	KSE.NamespaceUU; 

		if(currentRecon.GL_Account__c != null){
            Reports.ReportFilter reportFilter = new Reports.ReportFilter(NamespaceUU+'Accounting_Entry_Line__c.'+NamespaceUU+'GL_Account__c.'+'Name', 'equals',glAccountIDs);
            reportFilters.add(reportFilter);
        }
        if(periodStart != null && periodEnd != null){
        	if(runningForEndingBalance == false && runningForBeginningBalance == true){
				Reports.ReportFilter reportFilter1 = new Reports.ReportFilter(NamespaceUU+'Accounting_Entry__c.'+NamespaceUU+'GL_Date_Time__c', 'lessThan',currentRecon.Period__r.Period_Start__c.formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') );
				Reports.ReportFilter reportFilter2 = new Reports.ReportFilter(NamespaceUU+'Accounting_Entry__c.'+NamespaceUU+'Status__c', 'equals','Active' );
            	reportFilters.add(reportFilter1);
            	reportFilters.add(reportFilter2);

			}else if(runningForEndingBalance == true && runningForBeginningBalance == false){
				Reports.ReportFilter reportFilter1 = new Reports.ReportFilter(NamespaceUU+'Accounting_Entry__c.'+NamespaceUU+'GL_Date_Time__c', 'lessThan',currentRecon.Period__r.Period_End__c.formatGmt('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') );
				Reports.ReportFilter reportFilter2 = new Reports.ReportFilter(NamespaceUU+'Accounting_Entry__c.'+NamespaceUU+'Status__c', 'equals','Active' );
            	reportFilters.add(reportFilter1);
            	reportFilters.add(reportFilter2);

			}
        }
        if(reportFilters != null && metaData != null){
            System.Debug('reportFilters:' + reportFilters );            
        	metaData.setReportFilters(reportFilters) ;
        }
        System.Debug('metaData:' + metaData );
        if(Test.isRunningTest())
        {
		    Reports.ReportResults runReportResults;
		    if(test.isRunningTest()){
		    	runReportResults = Reports.ReportManager.runReport(standardReportId);
		    }else{
		    	runReportResults = Reports.ReportManager.runReport(standardReportId,metaData);
		    }
	        if(runReportResults!= null){
	        	parseRows(runReportResults); 
	        }
	        else
	        {
				BegEndBalobj.message = 'Error retrieving AELs_Grouped_By_GL_w_Balance standard report ';
				BegEndBalobj.isValid =false;
				BegEndBalobj.begBalance=0.0;
				BegEndBalobj.endBalance=0.0;	        	
	        }
	        if(runningForEndingBalance == true && runningForBeginningBalance == false && endingRunFlag == false){
				endingRunFlag = true;
				runBegBalReports(currentRecon.id, runningForBeginningBalance, runningForEndingBalance);
				
			}	
        }
        else
        {
			Reports.ReportInstance instance = Reports.ReportManager.runAsyncReport(standardReportId,metaData); 
			Id asyncReportInstanceId = instance.getId();
			
			asyncReportID = asyncReportInstanceId;
			
			asyncReportStatus = instance.getStatus() ;
			Datetime asyncReportCompletionDate = instance.getCompletionDate() ;
			if(asyncReportInstanceId != null){
				getBeginningBalance();
		}        	
        }




		return BegEndBalobj;
	}
	
	public static void getBeginningBalance(){
		Reports.ReportResults runReportResults;
		boolean reportStatus=true;
		
		while(Reports.ReportManager.getReportInstance(asyncReportID).getStatus() != 'Success')
		{
			if(Reports.ReportManager.getReportInstance(asyncReportID).getStatus()=='Error')
			{
				BegEndBalobj.message = 'Error retrieving AELs_Grouped_By_GL_w_Balance standard report ';
				BegEndBalobj.isValid =false;
				BegEndBalobj.begBalance=0.0;
				BegEndBalobj.endBalance=0.0;
				break;
			}

		}
		if(reportStatus)
		{
			runReportResults= Reports.ReportManager.getReportInstance(asyncReportID).getReportResults() ; 
	        
	        if(runReportResults!= null){
	        	parseRows(runReportResults); 
	        }
	        if(runningForEndingBalance == true && runningForBeginningBalance == false && endingRunFlag == false){
				endingRunFlag = true;
				runBegBalReports(currentRecon.id, runningForBeginningBalance, runningForEndingBalance);
				
			}			
		}

	}

	
	public static void parseRows(Reports.ReportResults runReportResults){
		Map<String, Reports.ReportFact> factMap = runReportResults.getFactMap();
		Reports.ReportFormat format = runReportResults.getReportMetaData().getReportFormat();
		if (format == Reports.ReportFormat.SUMMARY) {
            getSummaryReportRowDetails(runReportResults.getGroupingsDown(), factMap);
        // Handle Tabular Report format.
        }
	}
	
	public static void getSummaryReportRowDetails(Reports.Dimension dimension, Map<String, Reports.ReportFact> factMap){
        Map<String,Map<String,Object>> resultMapWithValues = new Map<String,Map<String,Object>> ();
        // Top level grouping.
        if(dimension.getGroupings().size() == 0){
        	runningForEndingBalance = true ; 
			runningForBeginningBalance = false;
        }
        for (Reports.GroupingValue g : dimension.getGroupings()) {
            // If there are 1st-level nested groupings, make new rows for them.
            if (g.getGroupings().size() > 0) {
                // 1st-level nested grouping. 
                for (Reports.GroupingValue g1 : g.getGroupings()) {
                    if (g1.getGroupings().size() > 0) {
                        // 2nd-level nested grouping. The is the max amount of nesting allowed.
                        for (Reports.GroupingValue g2 : g1.getGroupings()) {
                            // Add a new row for 2nd-level nested grouping.
                        }
                    // Otherwise, add details for 1st-level nested grouping.
                    } else {
                        //result = getRowDetailsForGrouping(factMap, g1.getKey() + '!T', new List<String>{g.getLabel(), g1.getLabel()},reportKey);
                        getRowDetailsForGrouping(factMap, g.getKey() + '!T',g1.getLabel());
                    }
                }
            // Otherwise, add details for top level grouping.
            } else {
                getRowDetailsForGrouping(factMap, g.getKey() + '!T',g.getLabel());

            }
        }
	}
	
	public static void getRowDetailsForGrouping(Map<String, Reports.ReportFact> factMap,
                                                            String key,
                                                            String prefix){
        Map<String,Object> result = new Map<String,Object>();
		Reports.ReportFact fact = factMap.get(key); 
		System.Debug('fact:' + fact); 
		Set <String> reportGLKeyMapGenerateKeySetg = new Set<String>();
        List <Reports.ReportFact> reportGLKeyMapGenerateValuesg = new List <Reports.ReportFact>();
        reportGLKeyMapGenerateKeySetg = factMap.keySet() ;
        reportGLKeyMapGenerateValuesg = factMap.values();
        system.debug('reportGLKeyMapGenerateKeySetg'+reportGLKeyMapGenerateKeySetg);
        system.debug('reportGLKeyMapGenerateValuesg'+reportGLKeyMapGenerateValuesg);
   
        for(String reportGLKeyMapGenerateKeySetgvaluekey:reportGLKeyMapGenerateKeySetg){
            if(reportGLKeyMapGenerateKeySetgvaluekey.contains('T!T')){
                Reports.ReportFact fact01 = factMap.get(reportGLKeyMapGenerateKeySetgvaluekey); 
                system.debug('fact01'+fact01);

                for (Reports.SummaryValue row : fact01.getAggregates()) { 
                	  system.debug('row'+row);
                	  system.debug('result'+result);
                    if(!(result.containsKey(prefix))){
                        if(String.ValueOf(row.getValue()).contains('.')){
                        	system.debug('inside inner for');
                        	system.debug('runningForEndingBalance'+runningForEndingBalance);
                        	system.debug('runningForBeginningBalance'+runningForBeginningBalance);

                            if(runningForEndingBalance == false && runningForBeginningBalance == true){
                            	currentRecon.Beginning_Balance__c = (decimal)row.getValue();
								beginningBalance = (Decimal)(row.getValue());
								system.debug('beginningBalance-INSIDE innermost'+beginningBalance);

							}else if(runningForEndingBalance == true && runningForBeginningBalance == false){
								currentRecon.Ending_Balance__c = (decimal)row.getValue();
								endingBalance = (Decimal)(row.getValue());
							}
                        }
                    }
                } 
            }
        }
        system.debug('beginningBalance'+beginningBalance);
        system.debug('endingBalance'+endingBalance);
        system.debug('currentRecon.Beginning_Balance__c'+currentRecon.Beginning_Balance__c);
        system.debug('currentRecon.Ending_Balance__c'+currentRecon.Ending_Balance__c);

        runningForEndingBalance = true ;
		runningForBeginningBalance = false;
		
        if(currentRecon.Beginning_Balance__c == null ){
        	currentRecon.Beginning_Balance__c = 0.00;
        }
        if(currentRecon.Ending_Balance__c == null ){
        	currentRecon.Ending_Balance__c = 0.00;
        }
        DML.updateAsUser(currentRecon);
		BegEndBalobj.begBalance=currentRecon.Beginning_Balance__c;
		BegEndBalobj.endBalance=currentRecon.Ending_Balance__c;	
		BegEndBalobj.isValid=true;	
	}
	
	
	/*public pageReference showUnReconciledDetail(){
		pageReference detailPage = Page.ReconRemoteDetail;
		detailPage.getParameters().put('Id', con.getId());					
		detailPage.getParameters().put('RptSection', 'Unmatched');
		detailPage.getParameters().put('SDType', 'Supplier_Invoice__c');


		return detailPage;
	}*/
	
}