public with sharing class NewReconTopicExt 
{/*
	 public list<selectoption> SDlist{set;}
	 public list<accounting_rule__c>  ARList{get;set;}

     public list<selectoption> Txnlist{set;}
	 public string selectedTT{get;SET;} 
     public list<selectoption> SubTxnlist{set;}
	 public string selectedSTT{get;set;}    
	 public list<selectoption> RuleTypelist{set;}
	 public string selectedRT{get;set;}

	 public list<RuleWrapper> RuleWrapperlist {get;set;}

	 public list<accounting_rule__c> rulesList{get;set;}
	 public boolean hasNext{get;set;}
	 public boolean hasPrevious{get;set;} 

	 public ApexPages.StandardSetController ssc;
	 public Apexpages.standardController controller;
	 public reconciliation_topic__C topic{get;set;}


	 public set<id> AllIds {get;set;}
	 public set<id> ExcludeIds ;
	 public set<id> selectedIds;
	 public id UserSelectedIdP;
	 public boolean UserSelectedP;

	 public id ReconId;
	 public id accountingStandardId;
	 public reconciliation__c reconRec;
	 public list<GL_account__c> GLFamily=new list<GL_account__c>();
	 public id  GLAccountId;
	 public string SDAPIName;
	 public boolean isbulkSelect{get;set;}
	 
	 public enum FieldChanged {SourceDocType,TransactionType,NoCascadeParent}
	 
	 public class RuleWrapper
	 {
	 	public boolean isSelected{get;set;}
	 	public accounting_rule__c Accrule{get;set;}
	 }
	 public void setUserSelectedId(id val)
	 {
	 	UserSelectedIdP=val;
	 	system.debug('id'+userSelectedIdp);

	 }
	 public void setUserSelected(boolean bool)
	 {
	 	UserSelectedP=bool;
	 	system.debug('bool'+UserSelectedp);

	 }

	 /*public list<selectoption> getSDList()
	 {
	 	set<selectoption> options = new set<selectoption>();

	    options.add(new selectoption('All','All'));
	 	for(accounting_rule__c rule:ARList)
	 	{
	 		options.add(new selectoption(rule.Object_Name__c,rule.Object_Name__c));
	 	}
	    list<selectoption> sortOptions= new list<selectoption>(options);
	    selectedSD='All';
	    sortOptions.sort();
	 	return sortOptions;
	 }*//*
	 
	 public list<selectoption> getTxnlist()
	 {
	 	set<selectoption> options = new set<selectoption>();
	 	list<accounting_rule__c> ARListTxn = new list<accounting_rule__c>();
	 	reconciliation_topic__C rt = (reconciliation_topic__C)controller.getrecord();
	 	system.debug('rt'+rt);
	 	if(rt.type__c!=null)
	 	{
		    SDAPIName = ReconRemoteService.getAPINameForSDType(rt.type__c);
		 	if(SDAPIName==null || SDAPIName=='Not Found')
		 	{
		 		 //We cannot error out in getters as they get called to previous value on applyFilter() ajax call		 		
		 	     // Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Recon Type TT'));
		 			
			} 
			else
			{
		    	
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                *//*
                SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','name','Object_Name__c','transaction__c','SubTransaction_Type__c','Rule_Type__c'
                });
                soql.setWhereClause('Object_Name__c=:SDAPIName and accounting_standard__c=:accountingStandardId');
                ARListTxn= Database.query(soql.getQuery());



		    } 		
	 	}
	

	    options.add(new selectoption('All','All'));
	 	for(accounting_rule__c rule:ARListTxn)
	 	{
	 		if(rule.Transaction__c!=null)
	 		{
	 	    	options.add(new selectoption(rule.Transaction__c,rule.Transaction__c));
	 		}
	 	}
	    list<selectoption> sortOptions= new list<selectoption>(options);
	    selectedTT='All';
	    sortOptions.sort();
	 	return sortOptions;
	 }
	 public list<selectoption> getSubTxnlist()
	 {
	 	set<selectoption> options = new set<selectoption>();
	 	system.debug('selectedTT'+selectedTT);
	 	
	 	list<accounting_rule__c> ARListSTxn = new list<accounting_rule__c>();
	 	
	 	reconciliation_topic__C rt = (reconciliation_topic__C)controller.getrecord();
	 	if(rt.type__c!=null)
	 	{
			SDAPIName = ReconRemoteService.getAPINameForSDType(rt.type__c);
		 	if(SDAPIName==null || SDAPIName=='Not Found') 
		 	{
		 		 //We cannot error out in getters as they get called to previous value on applyFilter() ajax call
		 	     // Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Recon Type STT'));
		 			
			} 
			else
			{
			 	if(selectedTT  !='All')
			 	{
		
			 		

                    /*
                    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                    *//*
                    SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
                    soql.addFields(new set<string>{
                        'id','name','Object_Name__c','transaction__c','SubTransaction_Type__c','Rule_Type__c'
                    });
                    soql.setWhereClause('Object_Name__c=:SDAPIName and Transaction__c=:selectedTT and accounting_standard__c=:accountingStandardId');
                    ARListSTxn= Database.query(soql.getQuery());



			 	}
			 	else
			 	{
			 		


                    /*
                    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                    *//*
                    SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
                    soql.addFields(new set<string>{
                        'id','name','Object_Name__c','transaction__c','SubTransaction_Type__c','Rule_Type__c'
                    });
                    soql.setWhereClause('Object_Name__c=:SDAPIName and accounting_standard__c=:accountingStandardId');
                    ARListSTxn= Database.query(soql.getQuery());



			 	}		 	
	    }		 		
	 	}
 	
	 		 	
	    options.add(new selectoption('All','All'));
	 	for(accounting_rule__c rule:ARListSTxn)
	 	{
	 		if(rule.SubTransaction_Type__c!=null)
	 		{
	 		 options.add(new selectoption(rule.SubTransaction_Type__c,rule.SubTransaction_Type__c));
	 		}
	 	}
         list<selectoption> sortOptions= new list<selectoption>(options);
         selectedSTT='All';
         sortOptions.sort();
         system.debug('sortOptions'+sortOptions);
	 	 return sortOptions;
	 }
	  public list<selectoption> getRuleTypelist()
	 {
	 	list<selectoption> options = new list<selectoption>(); 	
	    options.add(new selectoption('All','All'));
        options.add(new selectoption('DR','DR'));
        options.add(new selectoption('CR','CR'));
	 	
	 	return options;
	 }


	 public NewReconTopicExt(Apexpages.StandardController sc)
	 {
	    this.controller= sc;
	    if(!Test.isRunningTest())
	    {
	    controller.addFields(new list<string>{'type__c','name','Reconciliation__c'});
	    }
        topic=(reconciliation_topic__C)controller.getrecord();
	 	ReconId=topic.reconciliation__c;
	 	


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        *//*
        SOQLUtil soql = new SOQLUtil('reconciliation__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','period__C','company__c', 'company__r.accounting_standard__c', 'GL_Account__c'
        });
        soql.setWhereClause('id=:ReconId');
        reconRec = Database.query(soql.getQuery());



	 	accountingStandardId=reconRec.company__r.accounting_standard__c;

	 	selectedTT='All';
	 	selectedSTT='All';

 		GLAccountId=reconRec.GL_Account__c;
 		

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        *//*
         soql = new SOQLUtil('GL_Account__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'ID','Name','SubAccount_of__c'
        });
        soql.setWhereClause('ID = :GLAccountId OR SubAccount_of__c = :GLAccountId OR SubAccount_of__r.SubAccount_of__c = :GLAccountId OR SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccountId OR SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccountId OR SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__r.SubAccount_of__c = :GLAccountId');
        GLFamily = Database.query(soql.getQuery());



    													
	 	ExcludeIds = new set<id>();
	 	selectedIds = new set<id>();
	    

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        *//*
        soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','Object_Name__c','transaction__c','SubTransaction_Type__c','Rule_Type__c','GL_Account__c','GL_Account_Reference_Value__c'
        });
        soql.setWhereClause('accounting_standard__c=:accountingStandardId and (GL_Account__c in :GLFamily or GL_Account_Reference_Value__c!=null)');
        soql.setOrderByClause('GL_Account_Reference_Value__c nulls last');
        ARList= Database.query(soql.getQuery());



	 	//Txnlist=getTxnlist('All');	
		//SubTxnlist=getSubTxnlist('All','All');

		ssc = new ApexPages.StandardSetController(ARList);

		if(ssc.getRecords().size()>10)
		{
			ssc.setPageSize(10);
			hasPrevious=false;
			hasNext=true;

		}
		rulesList = ssc.getRecords();
		RuleWrapperlist = new list<RuleWrapper>();
		populateWrapper(rulesList);
		//getUnSelectedRules();

	     
	 }

	 public void populateWrapper(list<accounting_rule__c> ruleList)
	 {
	 	RuleWrapperlist= new list<RuleWrapper>();
	    for(accounting_rule__c rule : ruleList)
		{
			RuleWrapper rulewrap = new RuleWrapper();
			rulewrap.Accrule=rule;
			if(excludeIds.contains(rule.id)) //user has navigated back to the pageset
			{
				rulewrap.isSelected=false;
			
			}
			else
			{
				rulewrap.isSelected=true;

			}			
			RuleWrapperlist.add(rulewrap);
		}	
	 }
	 public void next()
	 {
	 	//getUnSelectedRules();
	 	ssc.next();
	 	populateWrapper(ssc.getRecords());
	 	if(ssc.getHasNext())
	 	{
	 		hasNext = true;
	 	}
	 	else
	 	{
		 	hasNext = false;
 		
	 	}
	 	if(ssc.getHasPrevious())
	 	{
	 		hasPrevious = true;
	 	}
	 	else
	 	{
		 	hasPrevious= false;
 		
	 	}
	 }
	 public void previous()
	 {
	 	//getUnSelectedRules();
	 	ssc.Previous();
	 	populateWrapper(ssc.getRecords());
	 	if(ssc.getHasPrevious())
	 	{
	 		hasPrevious = true;
	 	}
	 	else
	 	{
		 	hasPrevious= false;
 		
	 	}
	 	if(ssc.getHasNext())
	 	{
	 		hasNext = true;
	 	}
	 	else
	 	{
		 	hasNext = false;
 		
	 	}
	 }
	 //AJAX methos
	 public void getSelected()
	 {
	 	 string UserSelectedP = System.currentPageReference().getParameters().get('UserSelected');
	 	 id UserSelectedIdp =(id)System.currentPageReference().getParameters().get('UserSelectedId');

	 	if(UserSelectedP=='true') //Means it has toggled from true to false.Param gets the old value
	 	{
	 		excludeIds.add(UserSelectedIdp);
	 		selectedIds.remove(UserSelectedIdp);


	 	}
	 	else
	 	{
	 		selectedIds.add(UserSelectedIdp);
	 		excludeIds.remove(UserSelectedIdp);
	 	}
	 	system.debug('UserSelectedId in action'+UserSelectedIdp);
	 	system.debug('UserSelected in action'+UserSelectedp);
	 }

	 public void bulkSelectUpdate()
	 {
	 	string bulkIsSelect =System.currentPageReference().getParameters().get('bulkSelect');
	 	map<id,sobject> mRulesinPageSet = new map<id,sobject>(ssc.getRecords());
	 	set<id> ruleIds = new set<id>(mRulesinPageSet.keyset());
	 	system.debug('bulkSelect'+bulkIsSelect+'ids'+ruleIds+'isbulkSelect'+isbulkSelect);
	 	if(bulkIsSelect=='false')
	 	{
	 		excludeIds.addall(ruleIds);
	 		selectedIds.removeall(ruleIds);


	 	}
	 	else
	 	{
	 		selectedIds.addall(ruleIds);
	 		excludeIds.removeall(ruleIds);
	 	}
	 	

	 }

	 //Save methods
	 public void createTopics()
	 {
	 	//getUnSelectedRules();
	 	try
	 	{
		 	reconciliation_topic__c saveRT = (reconciliation_topic__c)controller.getrecord();
		 	system.debug('saveRT'+saveRT);
		 	if(saveRT.Type__c==null ||  saveRT.Type__c=='' )
		 	{
		 	    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter Source Doc Type'));

		 	}
		 	else
		 	{
		 		SDAPIName = ReconRemoteService.getAPINameForSDType(saveRT.type__c);
		 		if(SDAPIName==null || SDAPIName=='Not Found')
		 		{
		 	       Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Recon Topic Type'));
		 			
		 		}
		 		else
		 		{
			 	


                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                *//*
                SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','name'
                });
                soql.setWhereClause('Object_Name__c=:SDAPIName and accounting_standard__c=:accountingStandardId and (GL_Account__c in :GLFamily or GL_Account_Reference_Value__c!=null)');
                list<accounting_rule__c> accRules = Database.query(soql.getQuery());



                    if(accRules.size()>0)
                    {
                        map<id,accounting_rule__c> mAccrules = new map<id,accounting_rule__c>(accRules);
                        set<id> AllIds = new set<id>();
        
                        if(selectedIds.size()>0)//If user had made some selection
                        {
                            AllIds.addAll(selectedIds);			 			
        
                            if(excludeIds.size()>0)
                            {
                                excludeIds.removeAll(selectedIds);//TODO:Verify if this is needed.In case user had transitioned selection                               
                                AllIds.removeAll(excludeIds);
                            }		
        
                        }//If User had made no selection
                        else if(excludeIds.size()>0)
                        {
                            excludeIds.removeAll(selectedIds);//TODO:Verify if this is needed.In case user had transitioned selection                               
                            AllIds.removeAll(excludeIds);
   
                        }
                        else //User had not applied the filters
                        {
        
                                AllIds = mAccrules.keyset();
                        }
                        list<reconciliation_topic__c> RTListToInsert = new list<reconciliation_topic__c>();
                        for(id ruleId:AllIds)
                        {
                            reconciliation_topic__c rt = new reconciliation_topic__C();
                            rt.name=reconRec.name+'|'+mAccrules.get(ruleiD).name;
                            rt.accounting_rule__c= ruleId;
                            rt.Reconciliation__c= ReconId;
                            rt.ReconTopic_Unique_Key__c=ruleId+'|'+ReconId;
                            rt.type__c= saveRT.type__c;
                            RTListToInsert.add(rt);
                        }
                        system.debug('RTListToInsert'+RTListToInsert);
                        system.debug('excludeIds'+excludeIds);
                        system.debug('AllIds'+AllIds);
                        system.debug('selectedIds'+selectedIds);
        				
        				DML.checkUpsertAsUser(RTListToInsert); upsert RTListToInsert ReconTopic_Unique_Key__c;
                        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, RTListToInsert.size()+' Recon topics succesfully created for '+ saveRT.Type__c +'. Click Go Back to exit.'));
                    }
                    else
                    {
 		 	            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No Records match your criteria'));
                       
                    }
		 			
		 		} 			 		


		 	}

	 	}

	 	
	 	catch(exception ex)
	 	{
		 	    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()+ ' Line Number '+ex.getLinenumber()));

	 	}



	 }

	 public void applyFilter()
	 {
	 	reconciliation_topic__c rt=(reconciliation_topic__C)controller.getRecord();
	 	system.debug('rt in filter'+rt);
	 	SDAPIName = ReconRemoteService.getAPINameForSDType(rt.type__c);
	 	if(SDAPIName==null || SDAPIName=='Not Found')
	 	{
	 	       Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Source Doc Type'));	 			
	 	}
	 	else
	 	{
		 	/*string query='';
		 	string base='select id,name,Object_Name__c,transaction__c,SubTransaction_Type__c,Rule_Type__c,GL_Account__c,GL_Account_Reference_Value__c from accounting_rule__c '
		 			    +' where accounting_standard__c=:accountingStandardId';*//*
		 			    
		 	string filter=' ';
		 	excludeIds = new set<id>();
		 	selectedids = new set<id>();
	
		 	string eventtypett = System.currentPageReference().getParameters().get('EventTypett');
		 	string eventtypesd = System.currentPageReference().getParameters().get('EventTypesd');
		 	FieldChanged Field ;
		 	
		 	if(eventtypesd!=null)
		 	{
		 		 Field = FieldChanged.SourceDocType;
		 	}
		 	else if(eventtypett!=null)
		 	{
		 		 Field = FieldChanged.TransactionType;
		 		
		 	}
		 	else
		 	{
	 			Field = FieldChanged.NoCascadeParent;
		 	}
		 	system.debug('events'+EventTypett+EventTypesd);
	
		 	if(rt.type__c !=null || rt.type__c!='' )
		 	{	
	            filter= filter +' and Object_Name__c=:SDAPIName';	    		
	        
	          if(selectedTT!=null && selectedTT!='All' && Field==FieldChanged.TransactionType)
		        {
	
	
		              filter= filter +' and transaction__c=:selectedTT';
	
	
		        }
		      if(selectedSTT!=null && selectedSTT!='All'  && Field==FieldChanged.NoCascadeParent)//Exlude STT filter which saved with previous val and not yet rerendered based on user's selection
			      {
	
		              filter= filter +' and SubTransaction_Type__c=:selectedSTT';
	
	
			      }
		      if(selectedRT!=null && selectedRT!='All')
			      {
	
		              filter= filter +' and Rule_Type__c=:selectedRT';
	
			      }
			   filter = filter+' and (GL_Account__c in :GLFamily or GL_Account_Reference_Value__c!=null) order by GL_Account_Reference_Value__c nulls last';
		    		
	
			   /*query=base+filter;
			   system.debug('query'+query);*//*
	
			   list<accounting_rule__c> filterRules = new list<accounting_rule__c>();
				
				String whereClause = 'accounting_standard__c=:accountingStandardId ' + filter;
        
			    SOQLUtil soql = new SOQLUtil('Accounting_Rule__c');
			    soql.addFields(new Set<String>{'id', 'name', 'Object_Name__c', 'transaction__c', 'SubTransaction_Type__c', 'Rule_Type__c', 'GL_Account__c', 'GL_Account_Reference_Value__c'});
			    soql.setWhereClause(whereClause);
			    
			   filterRules= Database.query(soql.getQuery());
			   
			   map<id,accounting_rule__c> mFilterRules = new map<id,accounting_rule__c>(filterRules);
			   selectedIds.addall(mFilterRules.keyset());
			   
			   if(filterRules.size()>0)
			   {
			 	ssc = new apexpages.StandardSetController(filterRules);
			 	if(filterRules.size()>10)
			 	{
			 		ssc.setPageSize(10);
			 		hasPrevious=false;
				    hasNext=true;
			 	}
			 	else
			 	{
			 		hasPrevious=false;
				    hasNext=false;
			 	}
			 	 populateWrapper(ssc.getRecords());
			 	 //getUnSelectedRules();
	
			   }
			   else
			   {
		 	    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No Records match your criteria'));
	 
			   }
		
			}
		 	else
		 	{
		 	   Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select topic type'));
	
		 	}
	 	}

	 }
	
    public pageReference cancel(){ 
		return new pageReference('/' + reconId);
    }
    public pagereference save()
    {
    	createTopics();
    	return null;
    }
    public pagereference SaveAndReturn()
    {
    	createTopics();
    	if(Apexpages.hasMessages()){return null;}
    	else{     	return new pageReference('/' + reconId);
		}

    }

		
*/}