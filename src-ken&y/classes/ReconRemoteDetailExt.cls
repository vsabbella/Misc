public with sharing class ReconRemoteDetailExt{/* extends GridRelatedListController{
    private id recordid ;
    public ApexPages.Standardcontroller controller;

    public String URLParameterRptSection = '';
    public String URLParameterSDName = '';//API Name of SD.
    public String URLReconId;
    public string URLParameterSourceTot;
    public string URLParameterGLTot;
    public string Title{get;set;}

    public id reconId{get;set;}
    public id reconPeriod{get;set;}
    public id reconCompany;
    public datetime ps;
    public datetime pe;    
    public set<id> GLFamily=new set<id>();
    public list<GL_account__c> GLAccts;
    public string GLFamilySer{get;set;}
    public map<id,GL_Account__c> mAssociatedGLAccounts;
    public boolean isBTGDisable {get;set;}

    public list<Reconciliation_topic__c> topicsWithDiscrepancy;

    //Common Vars
    public string autonumchunks{get;set;}
    public boolean valid{get;set;}

    public Reconciliation__c recon {get; set;} //controller record
    public list<Reconciliation_Item__c> reconItems {get;set;}// {reconItems = new List<Reconciliation_Item__c>();}
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    //Used in Page
    public list<sobject> sobjects{get;set;}
    public list<string> fieldlist{get;set;}
    public Decimal GLTotal{get;set;}
    public Decimal sourceTotal{get;set;}


    public string queryString;
    public string costFieldQueryStr;


   //Vars used to get details from rules
    public set<id> ruleIds;
    public set<id> ruleIdsWithoutOverrides;
    public set<id> ruleIdsWithOverrides;
    public map<id,string> mRuleCostfield = new map<id,string>();

    //StandardSetComtroller Vars
    public boolean hasNext{get;set;}
    public boolean hasPrevious{get;set;}
    public apexpages.standardsetcontroller ssc;

    //Booleans which control the detail block template  in page
    public boolean isAccrual{get;set;}
    public boolean isUnreconciledRules{get;set;}
    public boolean isUnmatchedRules{get;set;}  
    public boolean isExceptions{get;set;}
    public boolean isOtherSD{get;set;}
    public boolean isManual{get;set;}
    
    public integer totalRecs{get;set;}
    
    //sobject detail related  vars
    public string sourceDocRefName='';
    public string sourceDocLineRefName='';
    public string SourceDocLineRefWithDot='';
    public string SourceDocLineRefWithoutDot='';
 	public string SDLDefaultCostField='';
 	public string SDCostField='';
 	public string SDAPIName='';
 	public string SDTypeName='';
 	public string SDLAPIName='';
 	public string SDRef='';
 	
 	public boolean isValid=true;

    public list<accounting_entry_line__c> Voidaels = new list<accounting_entry_line__c>();
    public set<id> VoidAELIdsToExclude = new set<Id>();
    


    public list<DetailAELWrapper> detWrapList{get;set;}
    
    public list<string> AELFieldsInQuery = new list<string>{ 'id','name','accounting_rule__c','accounting_rule__r.name','accounting_rule__r.Amount_Reference__c',
    	                                                     'accounting_entry__r.name' , 'Balance_f__c',
    	                                                     'gl_account__c','gl_account__r.name','accounting_entry__r.has_exceptions__c','has_exceptions__c'};
		                                          
    public list<string> AccrualFieldsInQuery = new list<string>{ 'id','name'}; 
    public list<string> ManualFieldsInQuery = new list<string>{'id','name','accounting_rule__c','accounting_rule__r.name','accounting_rule__r.Amount_Reference__c',
					                                           'Journal_Entry_Line__c','journal_entry_line__r.name','accounting_entry__r.name',
					                                            'accounting_entry__r.journal_entry__r.name' , 'accounting_entry__r.Journal_Entry__r.name',                                   
					                                            'Journal_Entry_Line__r.Amount_DR__c','Journal_Entry_Line__r.Amount_CR__c','Balance_f__c'   };

    public string WhereClause= '';
    
    
    
    public class DetailAELWrapper
    {
        public String AEName{get;set;}//KNDY-8682 Add AE column to detail page
        public Id AEId{get;set;}
        
        public String AELName{get;set;}
        public Id AELId{get;set;}

        public String RuleName {get;set;}
        public Id RuleId{get;set;}

        public String SDName{get;set;}
        public Id SDId{get;set;}

        public String SDLName{get;set;}
        public Id SDLId{get;set;}

        public Decimal SourceAmount{get;set;}
        public Decimal GLAmount{get;set;}
        public Decimal Difference{get;set;} 
        
        public boolean HeaderhasExceptions{get;set;}//KNDY-9391
        public boolean LinehasExceptions{get;set;}//KNDY-9391
        
        public id GLId{get;set;}//KNDY-9391
        public string GLName{get;set;}//KNDY-9391
        
        public DetailAELWrapper()
        {
            SourceAmount=0;
            GLAmount=0;
            Difference=0;
        }


    }


    public ReconRemoteDetailExt(ApexPages.Standardcontroller con) 
    {
            try
            {
                controller = con; 

                topicsWithDiscrepancy = new list<Reconciliation_topic__c>();
                ruleIdsWithoutOverrides = new set<id>();
                ruleIdsWithOverrides = new set<id>();
                ruleIds = new set<id>();

                mRuleCostfield = new map<id,string>();
                sobjects = new list<sobject>();
                //totalsList= new list<TotalValue>();



                // get URL Parameters
                URLReconId=ApexPages.currentPage().getParameters().get('Id');
                URLParameterRptSection = ApexPages.currentPage().getParameters().get('RptSection');
                URLParameterSDName     = ApexPages.currentPage().getParameters().get('SDType');

                
				



                system.debug('constructor'+URLReconId+URLParameterRptSection+URLParameterSDName);

                //sobjects = database.query(queryString);

                if(URLParameterRptSection != null && URLParameterRptSection != ''
                     && URLParameterSDName!=null && URLParameterSDName!=''
                     && URLReconId!='' && URLReconId!=null )
                {
                    isAccrual=false;
                    isExceptions=false;
                    isUnreconciledRules=false;
                    isUnmatchedRules=false;
                    isManual=false;
                    isOtherSD=false;
                    isBTGDisable = false;
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					
					SOQLUtil soql = new SOQLUtil('Reconciliation__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'id','name','period__c','GL_Account__c','company__c','Period__r.Period_Start__c','Period__r.Period_End__c'
					});
					soql.setWhereClause('id = :URLReconId');

					recon= Database.query(soql.getQuery());
	
	                getReconDetails();
	                getDetailsFromParameters();
	                if(isValid)
	                {

	                    system.debug('GLAccts'+GLAccts+'period'+reconPeriod+'SDAPIName'+SDAPIName+'SDLAPIName'+SDLAPIName+'costFieldQueryStr'+costFieldQueryStr+'SDLDefaultCostField'+SDLDefaultCostField);
	                    
	                    if(URLParameterRptSection=='Unmatched')
	                    {
	                    	 isUnmatchedRules = true;
	                         Title = ReconRemoteService.UnmatchedTitle;
		                     
							//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
							
							soql = new SOQLUtil('Reconciliation_topic__c', true); //enforceFLS=true, running in user mode
							soql.addFields(new set<string>{
								'id','name','accounting_rule__c'
							});
							soql.setWhereClause('reconciliation_section__c=\'Unmatched\' and Reconciliation__c=:URLReconId');

							topicsWithDiscrepancy= Database.query(soql.getQuery());
	
	                         for(Reconciliation_topic__c rt:topicsWithDiscrepancy)
	                         {
	                            ruleIds.add(rt.accounting_rule__c);
	                         }
	                         
	                         getDetailsFromRules(ruleIds);
	                         
	   						//Migrating to SOQLUtil model.Do not cleanup.
	                        /* string baseQuery='select id,name,accounting_rule__c,accounting_rule__r.name,accounting_rule__r.Amount_Reference__c, '
		                                          +SDLAPIName+','+SourceDocLineRefName+
		                                          +',accounting_entry__r.name'+',accounting_entry__r.'+SourceDocRefName                                     
		                                          + ',Balance_f__c,'+ SourceDocLineRefWithDot+SDLDefaultCostField+costFieldQueryStr
		                                          +' from accounting_entry_line__c '
		                                          +' where gl_account__c in :GLFamily'
		                                          +' and accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                        //  +' and accounting_entry__r.related_accounting_entry__c=null'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c=\'Active\''
			                                      +' and accounting_entry__r.has_exceptions__c=false'    
		                                          +' and accounting_rule__c in :ruleIds';     *//*
		                      
							 WhereClause= 'gl_account__c in :GLFamily'
		                                          +' and accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                        //  +' and accounting_entry__r.related_accounting_entry__c=null'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c='+'\''+String.escapeSingleQuotes('Active')+'\''
			                                      +' and accounting_entry__r.has_exceptions__c=false'    
		                                          +' and accounting_rule__c in :ruleIds';
				             string baseQuery=callSOQLUtil();
	                		

	                        sobjects.addAll(initializeSetController(baseQuery));
	                        populateDetailAELWrapper();
	
	                    }
	                    else if(URLParameterRptSection=='UnreconciledAmount' ||URLParameterRptSection=='UnreconciledRules' )
	                    {
	                    	if(URLParameterRptSection=='UnreconciledRules')
	                    	{
	                         isUnreconciledRules = true;
	                    	 Title = ReconRemoteService.UnreconciledRulesTitle;	                    		
	                    	}
	                    	else
	                    	{
	                    	 Title = ReconRemoteService.UnreconciledAmountTitle;	                    		
	                    		
	                    	}
	                    	
	                        list<sobject> Allsobjects = new list<sobject>();
	                        
	                        system.debug('GLAccts'+GLAccts+'period'+reconPeriod+'SDAPIName'+SDAPIName+'SDLAPIName'+SDLAPIName+'costFieldQueryStr'+costFieldQueryStr+'SDLDefaultCostField'+SDLDefaultCostField);
	
	                        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
							
							soql = new SOQLUtil('Reconciliation_topic__c', true); //enforceFLS=true, running in user mode
							soql.addFields(new set<string>{
								'id','name','accounting_rule__c'
							});
							soql.setWhereClause('reconciliation_section__c=:URLParameterRptSection and Reconciliation__c=:URLReconId and type__c = :SDTypename');

							topicsWithDiscrepancy= Database.query(soql.getQuery());
	
	                         for(Reconciliation_topic__c rt:topicsWithDiscrepancy)
	                         {
	                            ruleIds.add(rt.accounting_rule__c);
	                         }
	                         
	
	                         getDetailsFromRules(ruleIds);
	                         //Migrating to SOQLUtil model.Do not cleanup.
	                         
	                         /*string baseQuery='select id,name,accounting_rule__c,accounting_rule__r.name,accounting_rule__r.Amount_Reference__c,gl_account__c,gl_account__r.name,'
		                                          +SDLAPIName+','+SourceDocLineRefName+
		                                          +',accounting_entry__r.name'+',accounting_entry__r.'+SourceDocRefName                                     
		                                          + ',Balance_f__c,'+ SourceDocLineRefWithDot+SDLDefaultCostField+costFieldQueryStr
		                                          +' from accounting_entry_line__c '
		                                          +' where accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                        //  +' and accounting_entry__r.related_accounting_entry__c=null'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c=\'Active\''
			                                      +' and accounting_entry__r.has_exceptions__c=false'
		                                          +' and accounting_rule__c in :ruleIds'  ;*//*
		                     
		                     whereClause=        'accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c='+'\''+String.escapeSingleQuotes('Active')+'\''
			                                      +' and accounting_entry__r.has_exceptions__c=false'
		                                          +' and accounting_rule__c in :ruleIds'  ;
		                    string baseQuery=callSOQLUtil();
		                                          
	                        
	
	                        Allsobjects.addAll(initializeSetController(baseQuery));
	
		                    extractUnmatchedLines(Allsobjects);

	                      
	                        system.debug('Allsobjects'+Allsobjects+'ruleIds'+ruleIds+'ruleIdsWithoutOverrides'+ruleIdsWithoutOverrides+'ruleIdsWithOverrides'+ruleIdsWithOverrides);
	
	                        populateDetailAELWrapper();
	                    }
	                    else if(URLParameterRptSection=='Exceptions')
	                    {
	                    	isExceptions=true;
	                    	 
	                    	Title = ReconRemoteService.UnreconciledExceptionsTitle;	                    		
	                    	
	                    	list<sobject> Allsobjects = new list<sobject>();
	                        
	                        system.debug('GLAccts'+GLAccts+'period'+reconPeriod+'SDAPIName'+SDAPIName+'SDLAPIName'+SDLAPIName+'costFieldQueryStr'+costFieldQueryStr+'SDLDefaultCostField'+SDLDefaultCostField);
	
							//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
							
							soql = new SOQLUtil('Reconciliation_topic__c', true); //enforceFLS=true, running in user mode
							soql.addFields(new set<string>{
								'id','name','accounting_rule__c'
							});
							soql.setWhereClause('reconciliation_section__c=\'Exceptions\' and Reconciliation__c=:URLReconId');

							topicsWithDiscrepancy= Database.query(soql.getQuery());
	
	                         for(Reconciliation_topic__c rt:topicsWithDiscrepancy)
	                         {
	                            ruleIds.add(rt.accounting_rule__c);
	                         }
	
	                         getDetailsFromRules(ruleIds);
	                        //Migrating to SOQLUtil model.Do not cleanup.	                         
	                         /*string baseQuery='select id,name,accounting_rule__c,accounting_rule__r.name,accounting_rule__r.Amount_Reference__c,accounting_entry__r.has_exceptions__c,has_exceptions__c,gl_account__c,'
		                                          +SDLAPIName+','+SourceDocLineRefName+
		                                          +',accounting_entry__r.name'+',accounting_entry__r.'+SourceDocRefName                                     
		                                          + ',Balance_f__c,'+ SourceDocLineRefWithDot+SDLDefaultCostField+costFieldQueryStr
		                                          +' from accounting_entry_line__c '
		                                          +' where accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                        //  +' and accounting_entry__r.related_accounting_entry__c=null'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c=\'Active\''  
		                                          +' and accounting_entry__r.has_exceptions__c=true'   
	                                              +' and accounting_rule__c in :ruleIds';*//*

 	                         whereclause =        'accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c='+'\''+String.escapeSingleQuotes('Active')+'\'' 
		                                          +' and accounting_entry__r.has_exceptions__c=true'   
	                                              +' and accounting_rule__c in :ruleIds';
 
 				             string baseQuery=callSOQLUtil();
               
	                        
	                       //  extractUnmatchedLines(Allsobjects);
	                        sobjects.addAll(initializeSetController(baseQuery));
	                        
	                        system.debug('Allsobjects'+Allsobjects+'ruleIds'+ruleIds);
	
	                        populateDetailAELWrapper();
	                    }
	                    else if(URLParameterRptSection=='otherSD')
	                    {
	                    	isOtherSD=true;
	                    	 
	                    	Title = ReconRemoteService.OtherSDTitle;	                    		
	                    	
	                    	list<sobject> Allsobjects = new list<sobject>();
	                        
	                        system.debug('GLAccts'+GLAccts+'period'+reconPeriod+'SDAPIName'+SDAPIName+'SDLAPIName'+SDLAPIName+'costFieldQueryStr'+costFieldQueryStr+'SDLDefaultCostField'+SDLDefaultCostField);
	
							//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
							
							soql = new SOQLUtil('Reconciliation_topic__c', true); //enforceFLS=true, running in user mode
							soql.addFields(new set<string>{
								'id','name'
							});
							soql.setWhereClause('reconciliation_section__c=\'otherSD\' and Reconciliation__c=:URLReconId');

							topicsWithDiscrepancy= Database.query(soql.getQuery());

	                        //Migrating to SOQLUtil model.Do not cleanup.	                         
 	                         whereclause =        'accounting_entry__r.Period__c=:reconPeriod'
		                                          +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
		                                          +' and id not in :VoidAELIdsToExclude'
		                                          +' and status__c='+'\''+String.escapeSingleQuotes('Active')+'\'' 
		                                          +' and accounting_entry__r.has_exceptions__c=false' 
		                                          +' and GL_Account__c in :GLFamily';  
 
 				             string baseQuery=callSOQLUtil();
	                       //  extractUnmatchedLines(Allsobjects);
	                        sobjects.addAll(initializeSetController(baseQuery));
	                        
	                        system.debug('Allsobjects'+Allsobjects+'ruleIds'+ruleIds);
	
	                        populateDetailAELWrapper();
	                    }
	                    else if(URLParameterRptSection=='AccrualCandidates')
	                    {
	                    	Title = ReconRemoteService.AccrualCandidatesTitle;	                    		
	                    	
	                        isAccrual=true;
       
                            //Migrating to SOQLUtil model.Do not cleanup.                        
	                        /*queryString='SELECT id,name,' + SDCostField +' FROM ' +
	                                      SDAPIName + ' WHERE Company__c = :recon.company__c ' +  ' AND status__c != \'Cancelled\''
                                        +'AND Transaction_Date__c >=:ps  AND Transaction_Date__c < :pe' +
                                        ' AND Id NOT IN (SELECT ' + SDAPIName+ ' FROM Accounting_Entry__c  WHERE status__c=\'Active\'  and period__c =:ReconPeriod ' +')' +' AND Id NOT IN (SELECT ' + SDAPIName + ' FROM Journal_Entry__c  WHERE Finalized__c=true AND GL_Date_Time__c >= :ps '  + ' AND GL_Date_Time__c < :pe' + ')';*//*
                         if(URLParameterSDName.equalsIgnoreCase('Bank_Transaction_Group__c')){
                         	                        whereclause= ' Company__c = :ReconCompany'   
							            +' AND status__c != '+'\''+String.escapeSingleQuotes('Cancelled')+'\''
                                        +' AND Transaction_Date__c >=:ps  AND Transaction_Date__c < :pe' 
                                        +' AND Id NOT IN (SELECT ' + 'Bank_Transaction__c'+ ' FROM Accounting_Entry_Line__c  WHERE accounting_entry__r.status__c=\'Active\'  and accounting_entry__r.period__c =:ReconPeriod ' +')'
                                        +' AND Id NOT IN (SELECT ' + 'Bank_Transaction__c' + ' FROM Journal_Entry_Line__c  WHERE Journal_Entry__r.Finalized__c=true AND Journal_Entry__r.GL_Date_Time__c >= :ps '  + ' AND Journal_Entry__r.GL_Date_Time__c < :pe' + ')';							    
						}else{                                        
							whereclause= ' Company__c = :ReconCompany'   
							            +' AND status__c != '+'\''+String.escapeSingleQuotes('Cancelled')+'\''
							            +' AND Historical__c = false'
                                        +' AND Transaction_Date__c >=:ps  AND Transaction_Date__c < :pe' 
                                        +' AND Id NOT IN (SELECT ' + string.EscapeSingleQuotes(SDAPIName)+ ' FROM Accounting_Entry__c  WHERE status__c=\'Active\'  and period__c =:ReconPeriod ' +')'
                                        +' AND Id NOT IN (SELECT ' + string.EscapeSingleQuotes(SDAPIName) + ' FROM Journal_Entry__c  WHERE Finalized__c=true AND GL_Date_Time__c >= :ps '  + ' AND GL_Date_Time__c < :pe' + ')';
                        }
	                        string queryString=callSOQLUtil();
	                        
	                        sobjects.addAll(initializeSetController(queryString));
	                        populateDetailAELWrapper();
	                    }
	                    else if(URLParameterRptSection=='Manual')
	                    {
	                    	 isManual=true;
	                         Title = ReconRemoteService.ManualTitle;	                    		
	                    	
	                         system.debug('GLAccts'+GLAccts+'period'+reconPeriod+'SDAPIName'+SDAPIName+'SDLAPIName'+SDLAPIName+'costFieldQueryStr'+costFieldQueryStr+'SDLDefaultCostField'+SDLDefaultCostField);
                             //Migrating to SOQLUtil model.Do not cleanup.
	                         /*queryString='select id,name,accounting_rule__c,accounting_rule__r.name,accounting_rule__r.Amount_Reference__c, '
	                                      + ' Journal_Entry_Line__c,accounting_entry__r.Journal_Entry__c,accounting_entry__r.name,'
	                                      + ' accounting_entry__r.Journal_Entry__r.name , Journal_Entry_Line__r.name, '                                    
	                                      + ' Journal_Entry_Line__r.Amount_DR__c,Journal_Entry_Line__r.Amount_CR__c,Balance_f__c'
	                                      +' from accounting_entry_line__c '
	                                      +' where gl_account__c=:GLAccts'
	                                      +' and accounting_entry__r.Period__c=:reconPeriod'
	                                      +' and accounting_entry__r.Source_Document_Object_Name__c=\'Journal_Entry__c\''
	                                      +' and status__c=\'Active\''
	                                      +' and id not in :VoidAELIdsToExclude';	 *//*                                     
                                        //  +' and (accounting_entry__r.related_accounting_entry__c=null or journal_entry_line__r.journal_entry__r.type__c=\'Accrual - Manual\')';
						    whereclause=   '  gl_account__c=:GLAccts'
	                                      +' and accounting_entry__r.Period__c=:reconPeriod'
	                                      +' and accounting_entry__r.Source_Document_Object_Name__c='+'\''+String.escapeSingleQuotes('Journal_Entry__c')+'\''
	                                      +' and status__c='+'\''+String.escapeSingleQuotes('Active')+'\''
	                                      +' and id not in :VoidAELIdsToExclude';	
	                        string queryString=callSOQLUtil();
	
	                        sobjects.addAll(initializeSetController(queryString));
	                        populateDetailAELWrapper();
	                    }
			            else
			            {
			                totalRecs=0;
			                valid=false;
			                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid report section') );
			            }
			           // totalRecs=sobjects.size();	                 	
	                }
	                else
	                {
	                    totalRecs=0;
                        valid=false;
                        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid SourceDoc Type') );                	
	                }


                }
                else
                    {
                        totalRecs=0;
                        valid=false;
                        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Page parameters ') );
                    }
                    
            }
            catch(exception ex)
            {
                    totalRecs=0;
                    valid=false;
                    system.debug('ex'+ex);
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()+ ' At Line Number ' +ex.getLineNumber()));
            }
    
    }
     
    public list<sobject> initializeSetController(string querystring)
    {
                system.debug('queryString'+queryString);
                
                //KNDY-8789 Pagination Error Fix                
                list<sobject> allrecs = database.query(queryString);

                //soql.SOQLWhereCondition('Gl_account__c',SOQLOperator.EQ,)
               /* list<sobject> allrecs = SOQLUtil.;
                where gl_account__c in :GLFamily'
                  +' and accounting_entry__r.Period__c=:reconPeriod'
                  +' and accounting_entry__r.Source_Document_Object_Name__c=:SDAPIName'
                //  +' and accounting_entry__r.related_accounting_entry__c=null'
                  +' and id not in :VoidAELIdsToExclude'
                  +' and status__c=\'Active\''
                  +' and accounting_entry__r.has_exceptions__c=false'    
                  +' and accounting_rule__c in :ruleIds'; *//*
                ssc = new apexpages.standardsetcontroller(allrecs);
                totalrecs = allrecs.size();
                ssc.setpagesize(25);
                //Also change totalrecs count.
                list<sobject> sobjs=ssc.getRecords();
                if(totalrecs>25)
                {
                    hasNext=true;
                    hasPrevious=false;

                }
                else
                {
                    hasNext=false;
                    hasPrevious=false;
                }
                system.debug('sobjects'+sobjs+'fieldList'+fieldList);
        return sobjs;

    }
    
    //This method populates the wrapper vars used for page display
    public void populateDetailAELWrapper()
    {
        detWrapList = new list<DetailAELWrapper>();
        if(sobjects.size()>0)
        {
            for(sobject sObj:sobjects)
            {
                DetailAELWrapper detWrap = new DetailAELWrapper();
                
                if(URLParameterRptSection=='AccrualCandidates')
                {
		            detWrap.SDName=(string)sObj.get('name');
		            detWrap.SDId=(Id)sObj.get('Id');
		            if(SDAPIName!='Journal_Entry__c')
		            {
		                if(SDAPIName.equalsIgnoreCase('bank_transaction_group__c')){
		                    detWrap.SDName= 'Bank Transaction';
		                    detWrap.SourceAmount=  (decimal)sObj.get('amount__c');
		                }else{
		               detWrap.SourceAmount= (decimal)sObj.get(SDCostField);
		                }
		
		            }
		            detWrap.GLAmount= 0;
		            detWrapList.add(detWrap);
                }
                else if(URLParameterRptSection=='otherSD')
                {
	                accounting_entry_line__c ael = (accounting_entry_line__c)sObj;
	                string costField='';
					
	                sobject sobjAE = ael.getSobject('accounting_entry__r');
	                sobject sobjRule = ael.getSobject('accounting_rule__r');
	                sobject sobjSDL = ael.getSobject(sourceDocLineRefWithoutDot);
	                sobject sobjSD = sobjAE.getSobject(SDRef);
	                
	                detWrap.SDName=(string)sobjSD.get('name');	                
	                detWrap.SDLName=(string)sobjSDL.get('name');	                	                	
	                detWrap.GLAmount=(decimal)ael.get('Balance_f__c'); 
	                detWrap.GLAmount  =detWrap.GLAmount==null ? 0:detWrap.GLAmount;               
	                
	                detWrap.AELName=(string)ael.get('name');
	                detWrap.AEName=(string)sobjAE.get('name');
	                detWrap.RuleName=(string)sobjRule.get('name');
	                
	                
	                detWrap.AELId=(Id)ael.get('Id');
	                detWrap.AEId=(Id)sobjAE.get('Id');                
	                detWrap.RuleId=(Id)sobjRule.get('Id'); 
	                detWrap.SDId=(Id)sobjSD.get('Id');
	                detWrap.SDLId=(Id)sobjSDL.get('Id');	                
	                detWrapList.add(detWrap);
	                   	
                }
                else
                {
	                accounting_entry_line__c ael = (accounting_entry_line__c)sObj;
	                string costField='';
					
	    
	                system.debug('querybefore'+Limits.getQueries());
	                //TODO:Use accounting rule service getvalue method.
	                sobject sobjSDL = ael.getSobject(sourceDocLineRefWithoutDot);
	                sobject sobjAE = ael.getSobject('accounting_entry__r');
	                sobject sobjSD = sobjAE.getSobject(SDRef);
	                sobject sobjRule = ael.getSobject('accounting_rule__r');
	                
	                system.debug('queryAfter'+Limits.getQueries());
	    
	                system.debug('sobjSDL'+sobjSDL+'sobjAE'+sobjAE+'sobjSD'+sobjSD+'sobjRule'+sobjRule+'AEL'+ael);
	    
	                if(ael.Accounting_Rule__r.Amount_Reference__c!='' && ael.Accounting_Rule__r.Amount_Reference__c!=null)
	                {
	                     costField =(String) sobjRule.get('Amount_Reference__c');
	    
	                }
	                else
	                {
	                      costField = SDLDefaultCostField;
	                }
	                if(SDAPIName!='Journal_Entry__c')
	                {
	                    system.debug('costfield'+costfield);
	                    detWrap.SourceAmount=(decimal)sobjSDL.get(costfield);
	                }
	                else
	                {
	                 detWrap.SourceAmount=(((decimal)sobjSDL.get('Amount_CR__c')!=0 ) && ((decimal)sobjSDL.get('Amount_CR__c')!=null))?(decimal)sobjSDL.get('Amount_CR__c'):(decimal)sobjSDL.get('Amount_DR__c');
	    
	                }
	                detWrap.SourceAmount=detWrap.SourceAmount==null? 0:detWrap.SourceAmount;
	
	                detWrap.GLAmount=(decimal)ael.get('Balance_f__c'); 
	                detWrap.GLAmount  =detWrap.GLAmount==null ? 0:detWrap.GLAmount;               
	                detwrap.Difference=detWrap.SourceAmount-math.abs(detWrap.GLAmount) ;
	                
	                detWrap.SDName=(string)sobjSD.get('name');
	                detWrap.AELName=(string)ael.get('name');
	                detWrap.AEName=(string)sobjAE.get('name');
	                
	                detWrap.SDLName=(string)sobjSDL.get('name');
	                detWrap.RuleName=(string)sobjRule.get('name');
	                
	                detWrap.SDId=(Id)sobjSD.get('Id');
	                detWrap.AELId=(Id)ael.get('Id');
	                detWrap.AEId=(Id)sobjAE.get('Id');                
	                detWrap.SDLId=(Id)sobjSDL.get('Id');
	                detWrap.RuleId=(Id)sobjRule.get('Id');
	    			
	    			
	                if(URLParameterRptSection=='Exceptions')
	                {
	                	detwrap.HeaderhasExceptions= (Boolean)sobjAE.get('has_exceptions__c');
	                	detwrap.LinehasExceptions= (Boolean)ael.get('has_exceptions__c');
	                	
	                }
	                if(URLParameterRptSection=='UnreconciledRules')
	                {
	                	sobject sobjGL = ael.getSobject('GL_Account__r');	                	
	           	        detwrap.GLId= (Id)ael.get('GL_Account__c');	           	        
	                	detwrap.GLName= (string)sobjGL.get('name');     	
	                }
	                detWrapList.add(detWrap);             	
	                
	              }
                
            }           
        }
        else
        {
           Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No Records found. Please run the Recon report again to get updated list of discrepancies,if any.') );
          
        }
 
    }

    public void donothing()
    {

    }

    public void getReconDetails()
    {
            id GLAccount=recon.GL_Account__c;
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('GL_Account__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Name','SubAccount_of__c'
			});
			soql.setWhereClause('ID = :GLAccount OR SubAccount_of__c = :GLAccount OR SubAccount_of__r.SubAccount_of__c = :GLAccount OR '
								+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccount OR '
								+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccount OR '
								+' SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccount');
			
			GLAccts = Database.query(soql.getQuery());

            mAssociatedGLAccounts = new map<id,gl_account__c>(GLAccts);     
            GLFamily= mAssociatedGLAccounts.keyset();
            GLFamilySer = JSON.serialize(mAssociatedGLAccounts.keyset()); //Serialized List of GL ids used by Page

   			ps = recon.Period__r.Period_Start__c;
        	pe = recon.Period__r.Period_End__c;  
        	ReconPeriod =   recon.period__c;     
        	ReconCompany =  recon.company__c; 
            
            ReconId=recon.Id;
    }
    
     public void getDetailsFromParameters()
 	{
 		SDAPIName=URLParameterSDName.toLowerCase();
 		SDAPIName =ReconRemoteService.sanitizeInptStr(SDAPIName);		
 		SDRef=SDAPIName.replace('__c','__r');
 		
 		if(SDAPIName!=null && SDAPIName!='Not Found' )
 		{
 
 			sourceDocRefName=ReconRemoteService.getSDRefNameForSD(SDAPIName);
 			sourceDocLineRefName=ReconRemoteService.getSDLRefNameForSD(SDAPIName);
 			SDLAPIName=ReconRemoteService.getSDLAPINameForSD(SDAPIName);
 			SDLDefaultCostField=ReconRemoteService.getDefaultLineCostFieldForSD(SDAPIName);
 			SDCostField=ReconRemoteService.getDefaultCostFieldForSD(SDAPIName);
 			sourceDocLineRefWithDot=ReconRemoteService.getSDLRefWithDotForSD(SDAPIName);
 			sourceDocLineRefWithoutDot=ReconRemoteService.getSourceDocLineRefWithoutDot(SDAPIName);
 			if(SDAPIName=='Journal_Entry__c')
 			{
 				VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),reconperiod,true);  
 			}   
 			else
 			{
  				VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),reconperiod,false);  
 				
 			}
 			if(SDAPIName.equalsIgnoreCase('Bank_Transaction_Group__c')){
 				isBTGDisable = TRUE;
 			}   			   
 			SDTypeName = ReconRemoteService.getSDTypefromAPIName(SDAPIName); 
 				 
 		}//If Sanitize map lookup doesnt have the SD then check otherSDSet .
 		else if(SDAPIName=='Not Found' && ReconRemoteService.otherSDSet.contains(URLParameterSDName.toLowerCase()))
 		{
 	 		SDAPIName=URLParameterSDName.toLowerCase();		
 		    SDAPIName =ReconRemoteService.sanitizeOtherInptStr(SDAPIName); 
  		    SDRef=SDAPIName.replace('__c','__r');
 		    
 			sourceDocRefName=ReconRemoteService.mOtherSDtoSDNameRefs.get(SDAPIName);
 			sourceDocLineRefName=ReconRemoteService.mOtherSDtoSDLNameRefs.get(SDAPIName);
 			SDLAPIName=ReconRemoteService.mOtherSDtoLine.get(SDAPIName);
 			sourceDocLineRefWithDot=ReconRemoteService.mOtherSourceDocLineRefsWithDot.get(SDAPIName);
 			sourceDocLineRefWithoutDot=ReconRemoteService.mOtherSourceDocLineRefsWithoutDot.get(SDAPIName); 			
 			if(SDAPIName=='Journal_Entry__c')
 			{
 				VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),reconperiod,true);  
 			}   
 			else
 			{
  				VoidAELIdsToExclude=ReconRemoteService.getVoidAELIds(new set<id>(GLFamily),reconperiod,false);  
 				
 			}   
 			SDTypeName = ReconRemoteService.getSDTypefromAPIName(SDAPIName);  			
 		}
 		else//Invalid SD
 		{
 			isValid=false;
 			
 		}
 	}
    
    //Populate the rule to Cost field map - mRuleCostfield and build costfield query string .
    public void getDetailsFromRules(set<id> rulesInScope)
    {
            list<accounting_rule__c> rulesWithoutAmtOverride = new list<accounting_rule__c>();
            list<accounting_rule__c> rulesWithAmtOverride    = new list<accounting_rule__c>();

            if(rulesInScope.size()==0)
            {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name'
				});
				soql.setWhereClause('Object_Name__c=:SDAPIName and Amount_Reference__c=null');

				rulesWithoutAmtOverride = Database.query(soql.getQuery());

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name','Amount_Reference__c'
				});
				soql.setWhereClause('Object_Name__c=:SDAPIName and Amount_Reference__c!=null');

				rulesWithAmtOverride = Database.query(soql.getQuery());

            }
            else
            {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name'
				});
				soql.setWhereClause('id = :rulesInScope and Amount_Reference__c = null');
				
				rulesWithoutAmtOverride = Database.query(soql.getQuery());

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name','Amount_Reference__c'
				});
				soql.setWhereClause('id = :rulesInScope and Amount_Reference__c!=null');

				rulesWithAmtOverride = Database.query(soql.getQuery());

            }


            costFieldQueryStr ='';
            mRuleCostfield = new map<id,string>();

                         
            if(rulesWithAmtOverride.size()>0)
             {
                 mRuleCostfield= new map<id,string>();
                 string linerefPrefix = SourceDocLineRefWithDot;
                 for(accounting_rule__c rule:rulesWithAmtOverride)
                 {
                        mRuleCostfield.put(rule.id,linerefPrefix+rule.Amount_Reference__c);
                 }

               set<string> costfieldset = new set<string>(mRuleCostfield.values());
               list<string> costfieldList = new list<string>(costfieldset);
               costFieldQueryStr  = string.join(costfieldList,',');  
               costFieldQueryStr = ','+costFieldQueryStr;  
               ruleIdsWithOverrides= mRuleCostfield.keyset();

             }
             if(rulesWithoutAmtOverride.size()>0)
             {
               map<id,accounting_rule__c> mRulesWithoutOverride = new map<id,accounting_rule__c>(rulesWithoutAmtOverride); 
               ruleIdsWithoutOverrides = mRulesWithoutOverride.keyset();
             }

             
    }
    public void extractUnmatchedLines(list<sobject> Allsobjects)
    {
        list<sobject> sobjUnMatched = new list<sobject>();
        for(sobject sobj:Allsobjects)
        {
            accounting_entry_line__c ael =(accounting_entry_line__c)sobj;
            if(ruleIdswithOverrides.contains(ael.Accounting_Rule__c))
            {
                string costfieldWithLineRef = mRuleCostfield.get(ael.Accounting_Rule__c);
                SYSTEM.debug(costfieldWithLineRef);
                list<string> keysSplit = costfieldWithLineRef.split('\\.');
                system.debug('keysSplit'+keysSplit);
                string lineRef = keysSplit[0];
                string costfield = keysSplit[1];

                sobject sobjSDL = sobj.getsobject(lineRef);
                decimal cost=(decimal)sobjSDL.get(costfield);

                if(ael.Balance_f__c !=cost)//Handles UnreconciledRules
                {
                    sobjects.add(ael);
                }
                else if(!mAssociatedGLAccounts.containsKey(ael.GL_Account__c))//Handles UnreconciledAmount
                {
                    sobjects.add(ael);

                }
            }
            if(ruleIdswithoutOverrides.contains(ael.Accounting_Rule__c))
            {
                sobject sobjSDL = sobj.getsobject(SourceDocLineRefWithoutDot);    
                decimal cost=(decimal)sobjSDL.get(SDLDefaultCostField);
                if(ael.Balance_f__c !=cost)
                {
                    sobjects.add(ael);
                }
                else if(!mAssociatedGLAccounts.containsKey(ael.GL_Account__c))
                {
                    sobjects.add(ael);

                }
            }

        }
    }
    public string callSOQLUtil()
    {
    	string queryStringFromUtil;
    	if(isAccrual)
    	{
	        AccrualFieldsInQuery.add(SDCostField)  ;
	        if(URLParameterSDName.equalsIgnoreCase('Bank_Transaction_Group__c')){
	          	SOQLUtil soql = new SOQLUtil('Bank_Transaction__c',false);  
		        soql.addFields(new set<string>{'amount__c','name'});
		        soql.setWhereclause(whereClause);   
		        system.debug('soql: '+soql);
		        queryStringFromUtil=soql.getQuery();	          
	        }else{
		        SOQLUtil soql = new SOQLUtil(SDAPIName,false);
		        soql.addFields(new set<string>(AccrualFieldsInQuery));
		        soql.setWhereclause(whereClause);   
		        system.debug('soql: '+soql);
		        queryStringFromUtil=soql.getQuery();	        
	        }

	        	
    	}
    	else if(isManual)
    	{
	        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c',false);
	        soql.addFields(new set<string>(ManualFieldsInQuery));
	        soql.setWhereclause(whereClause);   
	        queryStringFromUtil=soql.getQuery();
	        		
    	}
    	else if(isOtherSD)
    	{
	        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c',false);
	        AELFieldsInQuery.add(SourceDocLineRefName)  ;
	        AELFieldsInQuery.add('accounting_entry__r.'+SourceDocRefName)  ;	        
	        soql.addFields(new set<string>(AELFieldsinQuery));
	        soql.setWhereclause(whereClause);   
	        queryStringFromUtil=soql.getQuery();
	        		
    	}
    	else
    	{
   	        AELFieldsInQuery.add(SDLAPIName)  ;
	        AELFieldsInQuery.add(SourceDocLineRefName)  ;
	        AELFieldsInQuery.add('accounting_entry__r.'+SourceDocRefName)  ;
	        AELFieldsInQuery.add(SourceDocLineRefWithDot+SDLDefaultCostField);
	        AELFieldsInQuery.addAll(mRuleCostfield.values());          
	        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c',false);
	        soql.addFields(new set<string>(AELFieldsinQuery));    	
	        soql.setWhereclause(whereClause);
	        queryStringFromUtil=soql.getQuery();
	         		
    	}

        
        return queryStringFromUtil;
    }
    
    // Navigation Buttons Logic
    public void next()
    {
        ssc.next();
        setNextPrevDetWrapper();


    }
    public void prev()
    {
        ssc.previous();
        setNextPrevDetWrapper();
    }
    public void setNextPrevDetWrapper()
    {
        hasNext=true;
        hasPrevious=true;
        sobjects=ssc.getRecords();
        if(!ssc.getHasNext())
        {
            hasNext=false;
        }
        if(!ssc.getHasPrevious())
        {
            hasPrevious=false;
        }

        populateDetailAELWrapper();

        
    }

    public pageReference review(){
        Pagereference reviewRecon = Page.ReconRemote;
        reviewRecon.getParameters().put('Id', controller.getId());
        reviewRecon.getParameters().put('redirect', 'true');
        return reviewRecon;
    } 
    



*/}