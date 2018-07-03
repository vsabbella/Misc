public with sharing class PeriodCloseExt extends BaseController {
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    public Apexpages.Standardcontroller con {get;set;}
    public List<sObject> ARdocs {get;set;}
    public class exceptionWrapper{
        public String sourceDocumentType{get;set;}
        public Id sourceDocument{get;set;}
        public String exceptionType{get;set;}
        public String sourceDocumentName{get;set;}
        public String sourceDocumentNameLabel{get;set;}
        public String sourceDocumentLink{get;set;}
    }
    
    public Period__c period { get; set; }
    public boolean isJECloseDisabled{get; set;}
    public Boolean IsValidateOnly{get; set;}
    public String IsValidateOnlyString{get; set;}
    public String subledgerType{get; set;}
    public integer excpCount{get; set;}     
    public decimal ARprogress{get; set;}     
    public decimal APprogress{get; set;}     
    public decimal FAprogress{get; set;}     
    public decimal JEprogress{get; set;}     
    public decimal INprogress{get; set;}     
    public decimal RCprogress{get; set;}     
    public decimal SHprogress{get; set;}     
    public decimal ICprogress{get; set;}     
    public list<exceptionWrapper> exceptionWrapperList{get;set;}
    public GridRelatedListController.GridRelatedListConfig exceptionLinesConfig {get; set;}
    @TestVisible
    private Datetime currDate = system.now();
    
    public PeriodCloseExt(Apexpages.Standardcontroller controller){
        /*if(!test.isRunningTest()){
            controller.addfields(new list<string>{'Open__c', 'AR_Subledger_Job__c', 'AP_Subledger_Job__c', 'InterCompany_Subledger_Job__c', 'Shipment_Subledger_Job__c', 'Receiving_Subledger_Job__c', 'Inventory_Subledger_Job__c', 'FA_Subledger_Job__c', 'JE_Subledger_Job__c','Period_Start__c','prior_period__r.ar_subledger_cutoff__c', 'prior_period__r.InterCompany_subledger_cutoff__c','prior_period__r.ap_subledger_cutoff__c','prior_period__r.receiving_subledger_cutoff__c','Type__c',
                                            'AR_Subledger_Cutoff__c', 'InterCompany_Subledger_Cutoff__c', 'AP_Subledger_Cutoff__c', 'Shipment_Subledger_Cutoff__c', 'Receiving_Subledger_Cutoff__c', 'Inventory_Subledger_Cutoff__c', 'FA_Subledger_Cutoff__c','Company__c','Prior_Period__c','Period_End__c','prior_period__r.ar_subledger_cutoff__c','prior_period__r.inventory_subledger_cutoff__c','prior_period__r.Closed__c',
                                            'AR_Subledger_Closed__c', 'InterCompany_Subledger_Closed__c', 'AP_Subledger_Closed__c', 'Shipment_Subledger_Closed__c', 'Receiving_Subledger_Closed__c', 'Inventory_Subledger_Closed__c', 'FA_Subledger_Closed__c', 'GL_Close__c','Period_End__c','prior_period__r.fa_subledger_cutoff__c','Period_End__c','prior_period__r.shipment_subledger_cutoff__c','prior_period__r.ap_subledger_cutoff__c',
                                            'AR_Subledger_Last_Run__c','InterCompany_Subledger_Last_Run__c','AP_Subledger_Last_Run__c','JE_Subledger_Last_Run__c','FA_Subledger_Last_Run__c','Inventory_Subledger_Last_Run__c','Receiving_Subledger_Last_Run__c','Shipment_Subledger_Last_Run__c',
                							'AR_Subledger_Batch_Size__c', 'InterCompany_Subledger_Batch_Size__c', 'AP_Subledger_Batch_Size__c', 'FA_Subledger_Batch_Size__c', 'JE_Subledger_Batch_Size__c', 'Shipment_Subledger_Batch_Size__c', 'Receiving_Subledger_Batch_Size__c', 'Inventory_Subledger_Batch_Size__c'});
        }*/
        this.con = controller;
        period = (Period__c)con.getRecord();
        period = [Select id, Name, Open__c, AR_Subledger_Job__c, AP_Subledger_Job__c, Shipment_Subledger_Job__c, Receiving_Subledger_Job__c, Inventory_Subledger_Job__c, FA_Subledger_Job__c, JE_Subledger_Job__c, 
					Period_Start__c,prior_period__r.receiving_subledger_cutoff__c,Type__c,InterCompany_Subledger_Job__c,prior_period__r.InterCompany_subledger_cutoff__c,InterCompany_Subledger_Cutoff__c,InterCompany_Subledger_Closed__c,
	                AR_Subledger_Cutoff__c, AP_Subledger_Cutoff__c, Shipment_Subledger_Cutoff__c, Receiving_Subledger_Cutoff__c, Inventory_Subledger_Cutoff__c, FA_Subledger_Cutoff__c, InterCompany_Subledger_Last_Run__c,je_cutoff__c,prior_period__r.je_cutoff__c,
	                Company__c,Prior_Period__c,prior_period__r.ar_subledger_cutoff__c,prior_period__r.inventory_subledger_cutoff__c, prior_period__r.Closed__c, 
	                AR_Subledger_Closed__c, AP_Subledger_Closed__c, Shipment_Subledger_Closed__c, Receiving_Subledger_Closed__c, Inventory_Subledger_Closed__c, FA_Subledger_Closed__c, GL_Close__c,
	                Period_End__c,prior_period__r.fa_subledger_cutoff__c,prior_period__r.shipment_subledger_cutoff__c,prior_period__r.ap_subledger_cutoff__c,
	                AR_Subledger_Last_Run__c,AP_Subledger_Last_Run__c,JE_Subledger_Last_Run__c,FA_Subledger_Last_Run__c,Inventory_Subledger_Last_Run__c,Receiving_Subledger_Last_Run__c,Shipment_Subledger_Last_Run__c,
					AR_Valid_After__c, AP_Valid_After__c, FA_Valid_After__c, Shipment_Valid_After__c, Receiving_Valid_After__c, Inventory_Valid_After__c, JE_Valid_After__c,
					prior_period__r.ap_subledger_closed__c,prior_period__r.ar_subledger_closed__c,prior_period__r.shipment_subledger_closed__c,prior_period__r.receiving_subledger_closed__c,
					prior_period__r.fa_subledger_closed__c,prior_period__r.InterCompany_subledger_closed__c,prior_period__r.inventory_subledger_closed__c,prior_period__r.gl_close__c
        			from Period__c
        			Where id = :period.id];
        			
        if(!period.Open__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'This period is not open.'));
        }
        
         
        if(period.Type__c == 'Historical' && period.Open__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'This period is a Historical Period. No Validation is required .Please go back and check closed.'));
        }
        if(period.AR_Subledger_Closed__c == null || period.AP_Subledger_Closed__c == null || period.FA_Subledger_Closed__c == null || period.InterCompany_Subledger_Closed__c == null
          || period.Shipment_Subledger_Closed__c == null || period.Receiving_Subledger_Closed__c == null || period.Inventory_Subledger_Closed__c == null)
        {
          isJECloseDisabled = true;
        }else{
          isJECloseDisabled = false;
        }
        excpCount = 0;
        ARprogress = 0;
        APprogress = 0;
        FAprogress = 0;
        JEprogress = 0;
        INprogress = 0;
        RCprogress = 0;
        SHprogress = 0;
        ICprogress = 0;
        subledgerType = ApexPages.currentPage().getParameters().get('SubledgerType');
        
        exceptionLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        exceptionLinesConfig.uniqueId = 'GridPerioCloseExceptionList';
        exceptionLinesConfig.buttons = 'search';
    }
    
    public pageReference closeSubledger(){
    	
    	
    	subledgerType = ApexPages.currentPage().getParameters().get('SubledgerType');
    	if(subledgerType == null || subledgerType == ''){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'None has been specified'));
    		reset(); 
    		return null;
    	}
    	//FIN-1155 Add exclusion for the first period of the company which will have no prior period.
      	boolean noPriorPeriod  = period.prior_period__c==null?true:false;  	
    	
    	/** Rework  as a part of KNDY-18323 
    	 * Ability to close subledgers independently, if prior subledgers are closed
    	 */
    	//boolean isPriorPeriodClosed = period.prior_period__r.Closed__c && !noPriorPeriod;
    	
    	boolean isPriorSubledgerClosed =  false;
    	
    	if(subledgerType == 'AP'){
    	    isPriorSubledgerClosed = period.prior_period__r.ap_subledger_closed__c !=null && !noPriorPeriod;
    	}else if(subledgerType == 'AR'){
    	    isPriorSubledgerClosed = period.prior_period__r.AR_Subledger_Closed__c !=null && !noPriorPeriod;
    	}else if(subledgerType == 'SH'){
    	    isPriorSubledgerClosed = period.prior_period__r.shipment_subledger_closed__c !=null && !noPriorPeriod;    
    	}else if(subledgerType == 'RC'){
    	    isPriorSubledgerClosed = period.prior_period__r.receiving_subledger_closed__c !=null && !noPriorPeriod;    
    	}else if(subledgerType == 'FA'){
    	    isPriorSubledgerClosed = period.prior_period__r.fa_subledger_closed__c !=null && !noPriorPeriod;    
    	}else if(subledgerType == 'IC'){
    	    isPriorSubledgerClosed = period.prior_period__r.InterCompany_subledger_closed__c !=null && !noPriorPeriod;    
    	}else if(subledgerType == 'IN'){
    	    isPriorSubledgerClosed = period.prior_period__r.inventory_subledger_closed__c !=null && !noPriorPeriod;    
    	}else if(subledgerType == 'JE'){
    	    isPriorSubledgerClosed = period.prior_period__r.gl_close__c !=null && !noPriorPeriod;     
    	} 
    	
    	boolean isSubledgerCutoffElapsed = false;
    	boolean hasOpenDocs = false;
    	boolean hasExceptionAEs = false;
    	boolean hasValidations = false;
    	boolean isClosed = false;
    	boolean isAllSubledgersClosed = false;
    	
    	if(subledgerType == 'AR'){
    		isSubledgerCutoffElapsed = period.ar_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.ar_subledger_cutoff__c < system.now();
    		isClosed = period.ar_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.AR, period);
    		//or Bank_File__c!= null condition commented for KNDY-10268 removal of bank file object reference
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Customer_Invoice__c != null OR Customer_Receipt__c != null OR Bank_Transaction_Group__c != null) LIMIT 1];
    		hasExceptionAEs = exceptionAEs.size() > 0;
    		
    		DateTime validAfter = period.AR_Valid_After__c == null ? period.AR_Subledger_Cutoff__c : period.AR_Valid_After__c;
		 	system.debug('validAfter: ' + validAfter);
		 	//or Bank_File__c!= null condition commented for KNDY-10268 removal of bank file object reference
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null
 													AND (Customer_Invoice__c != null OR Customer_Receipt__c != null OR Bank_Transaction_Group__c != null)
		 											AND isValidated__c = false
		 											LIMIT 1];
		 	system.debug('agedAEs: ' + agedAEs);
		 	hasValidations = agedAEs.size() > 0;
		 	/*
		 	List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Customer_Invoice__c != null OR Customer_Receipt__c != null OR Bank_File__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    		
    	}else if(subledgerType == 'AP'){
    		isSubledgerCutoffElapsed = period.ap_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.ap_subledger_cutoff__c < system.now();
    		isClosed = period.ap_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.AP, period);
    		//FIN-1094 Remove tracking POs in financial close process.
    		//List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Purchase_Order__c != null OR Supplier_Invoice__c != null OR Supplier_Payment__c != null) LIMIT 1];
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Supplier_Invoice__c != null OR Supplier_Payment__c != null) LIMIT 1];    		
    		hasExceptionAEs = exceptionAEs.size() > 0;
    		DateTime validAfter = period.AP_Valid_After__c == null ? period.AP_Subledger_Cutoff__c : period.AP_Valid_After__c;
    	    //FIN-1094 Remove tracking POs in financial close process.
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null
 													//AND (Supplier_Invoice__c != null OR Supplier_Payment__c != null OR Purchase_Order__c != null)
  													AND (Supplier_Invoice__c != null OR Supplier_Payment__c != null )													
		 											AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;
    		/*
		 	List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Purchase_Order__c != null OR Supplier_Invoice__c != null OR Supplier_Payment__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}else if(subledgerType == 'SH'){
    		isSubledgerCutoffElapsed = period.shipment_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.shipment_subledger_cutoff__c < system.now();
    		isClosed = period.shipment_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.SHIPMENT, period);
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Shipment__c != null) LIMIT 1];
    		hasExceptionAEs = exceptionAEs.size() > 0;
    		
    		DateTime validAfter = period.Shipment_Valid_After__c == null ? period.Shipment_Subledger_Cutoff__c : period.Shipment_Valid_After__c;
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null
 													AND Shipment__c != null
 													AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;

    		
		 	/*List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Shipment__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}else if(subledgerType == 'RC'){
    		isSubledgerCutoffElapsed = period.receiving_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.receiving_subledger_cutoff__c < system.now();
    		isClosed = period.receiving_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.RECEIVING, period);
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Receiving_Document__c != null) LIMIT 1];
    		hasExceptionAEs = exceptionAEs.size() > 0;
    		
    		DateTime validAfter = period.Receiving_Valid_After__c == null ? period.Receiving_Subledger_Cutoff__c : period.Receiving_Valid_After__c;
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null
 													AND Receiving_Document__c != null
 													AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;

    		
		 	/*List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Receiving_Document__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}else if(subledgerType == 'FA'){
    		isSubledgerCutoffElapsed = period.fa_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.fa_subledger_cutoff__c < system.now();
    		isClosed = period.fa_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.FA, period);
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Fixed_Asset_Depreciation__c != null OR Fixed_Asset_Adjustment__c != null) LIMIT 1];
    		hasExceptionAEs = exceptionAEs.size() > 0;
    		
    		DateTime validAfter = period.FA_Valid_After__c == null ? period.FA_Subledger_Cutoff__c : period.FA_Valid_After__c;
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null
 													AND (Fixed_Asset_Adjustment__c != null OR Fixed_Asset_Depreciation__c != null)
		 											AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;

    		
		 	/*List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Fixed_Asset_Depreciation__c != null OR Fixed_Asset_Adjustment__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}else if(subledgerType == 'IC'){
    		isSubledgerCutoffElapsed = period.InterCompany_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.InterCompany_subledger_cutoff__c < system.now();
    		isClosed = period.InterCompany_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.INTERCOMPANY, period);
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and company__c = :period.company__c and Period__c = :period.Id AND Status__c = 'Active' AND (Invoice__c != null OR Payment__c != null) LIMIT 1];
    		system.debug('exceptionAEs: ' + exceptionAEs);
    		hasExceptionAEs = exceptionAEs.size() > 0;

    		
    		DateTime validAfter = period.InterCompany_Valid_After__c == null ? period.InterCompany_Subledger_Cutoff__c : period.InterCompany_Valid_After__c;
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null 
 													AND (Invoice__c != null OR Payment__c != null)
 													AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;
    		
		 	/*List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Work_Order__c != null OR Inventory_Change__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}else if(subledgerType == 'IN'){
    		isSubledgerCutoffElapsed = period.inventory_subledger_cutoff__c == null ? period.period_end__c < system.now() : period.inventory_subledger_cutoff__c < system.now();
    		isClosed = period.inventory_subledger_closed__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.INVENTORY, period);
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Work_Order__c != null OR Inventory_Change__c != null) LIMIT 1];
    		system.debug('exceptionAEs: ' + exceptionAEs);
    		hasExceptionAEs = exceptionAEs.size() > 0;

    		
    		DateTime validAfter = period.Inventory_Valid_After__c == null ? period.Inventory_Subledger_Cutoff__c : period.Inventory_Valid_After__c;
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null 
 													AND (Inventory_Change__c != null OR Work_Order__c != null)
 													AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;
    		
		 	/*List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Work_Order__c != null OR Inventory_Change__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}else if(subledgerType == 'JE'){
    		isSubledgerCutoffElapsed = period.JE_Cutoff__c == null ? period.period_end__c < system.now() : period.JE_Cutoff__c < system.now();
    		isAllSubledgersClosed = period.ar_subledger_closed__c != null && period.ap_subledger_closed__c != null && period.fa_subledger_closed__c != null && period.inventory_subledger_closed__c != null && period.shipment_subledger_closed__c != null && period.receiving_subledger_closed__c != null;
    		isClosed = period.gl_close__c != null;
    		hasOpenDocs = SubledgerService.checkOpenSourceDocs(SubledgerService.Subledger.PERIOD, period);
    		List<Accounting_Entry__c> exceptionAEs = [SELECT Id, has_exceptions__c FROM Accounting_Entry__c WHERE has_exceptions__c = true and Period__c = :period.Id AND Status__c = 'Active' AND (Journal_Entry__c != null) LIMIT 1];
    		hasExceptionAEs = exceptionAEs.size() > 0;
    		DateTime validAfter = period.JE_Valid_After__c == null ? period.JE_Cutoff__c : period.JE_Valid_After__c;
		 	List<Accounting_Entry__c> agedAEs = [SELECT Id 
		 											FROM Accounting_Entry__c
		 											WHERE Period__c = :period.Id 
		 											AND Status__c = 'Active' 
 													AND has_exceptions__c = false 
 													AND related_accounting_entry__c = null 
 													AND Journal_Entry__c != null
		 											AND isValidated__c = false
		 											LIMIT 1];
		 	hasValidations = agedAEs.size() > 0;
    		/*
		 	List<task> validationTasks = [SELECT Id 
		 									FROM Task 
		 									WHERE Subject = 'Accounting Entry Validation' 
		 									AND WhatId IN (SELECT Id FROM Accounting_Entry__c 
		 													WHERE Period__c = :period.Id AND Status__c = 'Active' 
		 													AND has_exceptions__c = false 
		 													AND (Journal_Entry__c != null)) limit 1];
    		hasValidations = validationTasks.size() > 0;
    		*/
    	}
    	
    	if(isClosed){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'This is already closed.'));
    		reset(); 
    		return null;
    	}
    	//FIN-1062 Add the period close validations
    	else if(!isSubledgerCutoffElapsed){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close this before the cut off.'));
    		reset(); 
    		return null;
    	}//FIN-1155 Exclude this validation for first period of the company.
    	else if( !noPriorPeriod && !isPriorSubledgerClosed ){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You cannot close this subledger because prior period subledger is open.'));
    		reset(); 
    		return null; 
    	}else if(hasOpenDocs){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Unable to close.There are finalized source documents without accounting.'));
    		reset(); 
    		return null;
    	}else if(hasExceptionAEs){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Unable to close. There are accounting entries in this period with exceptions.'));
    		reset(); 
    		return null;
    	}else if(hasValidations){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Unable to close. There are accounting entries that have not been validated.'));
    		reset(); 
    		return null;
    	}else{
    		//All clear - let's close the subledger
    		Period__c up = [SELECT Id, ar_subledger_closed__c, ap_subledger_closed__c, fa_subledger_closed__c, inventory_subledger_closed__c, shipment_subledger_closed__c, receiving_subledger_closed__c FROM Period__c WHERE Id = :period.Id FOR UPDATE ];
    		PeriodService.systemEditable.add(up.Id);
    		if(subledgerType == 'AR'){
    			up.ar_subledger_closed__c = system.now();
	    	}else if(subledgerType == 'AP'){
	    		up.ap_subledger_closed__c = system.now(); 
	    	}else if(subledgerType == 'SH'){
	    		up.shipment_subledger_closed__c = system.now();
	    	}else if(subledgerType == 'RC'){
	    		up.receiving_subledger_closed__c = system.now();
	    	}else if(subledgerType == 'FA'){
	    		up.fa_subledger_closed__c = system.now();
	    	}else if(subledgerType == 'IC'){
	    		up.intercompany_subledger_closed__c = system.now();
	    	}else if(subledgerType == 'IN'){
	    		up.inventory_subledger_closed__c = system.now();
	    	}else if(subledgerType == 'JE'){
	    		if(isAllSubledgersClosed){
	    			up.gl_close__c = system.now();
	    		}else{
	    			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Unable to close period as one or more areas are open.'));
	    			reset(); 
	    			return null;
	    		}
	    	}
	    	
	    	DML.updateAsUser(up);
	    	PageReference periodPage = Page.PeriodClose;
	    	periodPage.getParameters().put('Id', period.Id);
	    	return periodPage;
    	}
    	
    }
    
    public string getPeriodJson() {
        return JSON.serialize(period);
    }
    
    public string getExceptionLinesConfigJson() {
        return JSON.serialize(exceptionLinesConfig);
    }
    
    public string getLastValidated() {
        //Period__c p = (Period__c)con.getRecord();
        Period__c p = this.period;

        datetime LastValidated;
        if( subledgerType == 'AR' ) {
            LastValidated = p.AR_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'AP' ) {
            LastValidated = p.AP_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'FA' ) {
           LastValidated = p.FA_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'JE' ) {
            LastValidated = p.JE_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'IC' ) {
            LastValidated = p.InterCompany_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'IN' ) {
            LastValidated = p.Inventory_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'RC' ) {
            LastValidated = p.Receiving_Subledger_Last_Run__c;
        }
        else if( subledgerType == 'SH' ) {
            LastValidated = p.Shipment_Subledger_Last_Run__c;
        }
        If(LastValidated != null){
        	string formattedTS = LastValidated.format();
        	return formattedTS;
        }
        else
        	return null;
    }
    
    public string getExceptionLinesFieldList() {
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            
        if (exceptionLinesConfig != null) {
            FieldInfo fieldInfoItem;
                
            // source document field
            fieldInfoItem = new FieldInfo('sourceDocumentType', 'Source Document Type', 'string');
            fieldInfoItem.editable = false;
            fieldInfoList.add(fieldInfoItem);
            
            // exception type field
            fieldInfoItem = new FieldInfo('exceptionType', 'Exception Type', 'string');
            fieldInfoItem.editable = false;
            fieldInfoList.add(fieldInfoItem);
            
            // source document link field
            fieldInfoItem = new FieldInfo('sourceDocumentLink', 'Link To Source Document', 'string');
            fieldInfoItem.editable = false;
            fieldInfoList.add(fieldInfoItem);
        }
        
        return JSON.serialize(fieldInfoList);
    }
    
    public pageReference refresh(){
        ARprogress = 0;
        APprogress = 0;
        FAprogress = 0;
        JEprogress = 0;
        INprogress = 0;
        RCprogress = 0;
        SHprogress = 0;
        ICprogress = 0;
        if (IsValidateOnly == true) 
            IsValidateOnlyString =  'True'; 
        if(IsValidateOnly == false)
            IsValidateOnlyString =  'False'; 
        
        if(period.AR_Subledger_Closed__c == null || period.AP_Subledger_Closed__c == null || period.FA_Subledger_Closed__c == null || period.InterCompany_Subledger_Closed__c == null
            || period.Shipment_Subledger_Closed__c == null || period.Receiving_Subledger_Closed__c == null || period.Inventory_Subledger_Closed__c == null)
        {
            isJECloseDisabled = true;
        }else{
            isJECloseDisabled = false;
        }
        
        set<Id> jobIds = new set<Id>();
        jobIds.add(period.AR_Subledger_Job__c);
        jobIds.add(period.AP_Subledger_Job__c);
        jobIds.add(period.Shipment_Subledger_Job__c);
        jobIds.add(period.Receiving_Subledger_Job__c);
        jobIds.add(period.InterCompany_Subledger_Job__c);
        jobIds.add(period.Inventory_Subledger_Job__c);
        jobIds.add(period.FA_Subledger_Job__c);
        jobIds.add(period.JE_Subledger_Job__c);
        jobIds.remove(null);
        
        Map<Id,AsyncApexJob> mJobs = new Map<Id, AsyncApexJob>([SELECT Id, TotalJobItems ,status,JobItemsProcessed
                                    FROM AsyncApexJob 
                                    WHERE Id IN :jobIds
                                    AND Status IN ('Aborted', 'Completed', 'Failed','Processing')]);
                                    
        
        for(AsyncApexJob mJob:mJobs.values()){
        	if (mJob.Status == 'Processing' && mJob.id == period.AR_Subledger_Job__c){        		
        		ARprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        
        	if (mJob.Status == 'Processing' && mJob.id == period.AP_Subledger_Job__c){        		
        		APprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        	if (mJob.Status == 'Processing' && mJob.id == period.FA_Subledger_Job__c){        		
        		FAprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        	if (mJob.Status == 'Processing' && mJob.id == period.JE_Subledger_Job__c){        		
        		JEprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        	if (mJob.Status == 'Processing' && mJob.id == period.Inventory_Subledger_Job__c){        		
        		INprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        	if (mJob.Status == 'Processing' && mJob.id == period.Shipment_Subledger_Job__c){        		
        		SHprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        	if (mJob.Status == 'Processing' && mJob.id == period.Receiving_Subledger_Job__c){        		
        		RCprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        	if (mJob.Status == 'Processing' && mJob.id == period.InterCompany_Subledger_Job__c){        		
        		ICprogress = decimal.valueof(mJob.JobItemsProcessed).divide(mJob.TotalJobItems, 3) * 100;
        	}
        }
        
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(); 
        if(period.AR_Subledger_Job__c != null && mJobs.containsKey(period.AR_Subledger_Job__c) && mJobs.get(period.AR_Subledger_Job__c).status != 'Processing')
        	p.AR_Subledger_Job__c =  null;    
        else 
        	p.AR_Subledger_Job__c = period.AR_Subledger_Job__c;
        if( period.AP_Subledger_Job__c != null && mJobs.containsKey(period.AP_Subledger_Job__c) && mJobs.get(period.AP_Subledger_Job__c).status != 'Processing')
        	p.AP_Subledger_Job__c =  null;
        else 
        	p.AP_Subledger_Job__c = period.AP_Subledger_Job__c;
        if(period.Shipment_Subledger_Job__c != null && mJobs.containsKey(period.Shipment_Subledger_Job__c) && mJobs.get(period.Shipment_Subledger_Job__c).status != 'Processing')
        	p.Shipment_Subledger_Job__c =  null;
        else 
        	p.Shipment_Subledger_Job__c = period.Shipment_Subledger_Job__c;
        if(period.Receiving_Subledger_Job__c != null && mJobs.containsKey(period.Receiving_Subledger_Job__c) && mJobs.get(period.Receiving_Subledger_Job__c).status != 'Processing')
        	p.Receiving_Subledger_Job__c =  null;
        else 
        	p.Receiving_Subledger_Job__c = period.Receiving_Subledger_Job__c;
        if(period.InterCompany_Subledger_Job__c != null && mJobs.containsKey(period.InterCompany_Subledger_Job__c) && mJobs.get(period.InterCompany_Subledger_Job__c).status != 'Processing')
        	p.InterCompany_Subledger_Job__c =  null;
        else 
        	p.InterCompany_Subledger_Job__c = period.InterCompany_Subledger_Job__c;
        if(period.Inventory_Subledger_Job__c != null && mJobs.containsKey(period.Inventory_Subledger_Job__c) && mJobs.get(period.Inventory_Subledger_Job__c).status != 'Processing')
        	p.Inventory_Subledger_Job__c =  null;
        else 
        	p.Inventory_Subledger_Job__c = period.Inventory_Subledger_Job__c;
        if(period.FA_Subledger_Job__c != null && mJobs.containsKey(period.FA_Subledger_Job__c) && mJobs.get(period.FA_Subledger_Job__c).status != 'Processing')
        	p.FA_Subledger_Job__c =  null;
        else 
        	p.FA_Subledger_Job__c = period.FA_Subledger_Job__c;
        if(period.JE_Subledger_Job__c != null && mJobs.containsKey(period.JE_Subledger_Job__c) && mJobs.get(period.JE_Subledger_Job__c).status != 'Processing')
        	p.JE_Subledger_Job__c =  null;
        else 
        	p.JE_Subledger_Job__c = period.JE_Subledger_Job__c;
            		
        if(period.Open__c && (p.AR_Subledger_Job__c != period.AR_Subledger_Job__c || p.AP_Subledger_Job__c != period.AP_Subledger_Job__c || p.Shipment_Subledger_Job__c != period.Shipment_Subledger_Job__c || p.Receiving_Subledger_Job__c != period.Receiving_Subledger_Job__c || p.Inventory_Subledger_Job__c != period.Inventory_Subledger_Job__c || p.FA_Subledger_Job__c != period.FA_Subledger_Job__c || p.JE_Subledger_Job__c != period.JE_Subledger_Job__c )){
			
	        Period__c pr = [Select Id, AR_Subledger_Job__c,AP_Subledger_Job__c,Shipment_Subledger_Job__c,Receiving_Subledger_Job__c,FA_Subledger_Job__c,Inventory_Subledger_Job__c,JE_Subledger_Job__c
	        			   FROM Period__c
	        			   WHERE Id =: period.Id
	        			   FOR UPDATE];
	            
	        try{
	        	if((pr.AR_Subledger_Job__c != null && p.AR_Subledger_Job__c == null) || (pr.AP_Subledger_Job__c != null && p.AP_Subledger_Job__c == null) || (pr.Shipment_Subledger_Job__c != null && p.Shipment_Subledger_Job__c == null) || (pr.Receiving_Subledger_Job__c != null && p.Receiving_Subledger_Job__c == null ) || (pr.FA_Subledger_Job__c != null && p.FA_Subledger_Job__c == null) || (pr.InterCompany_Subledger_Job__c != null && p.InterCompany_Subledger_Job__c == null) || (pr.Inventory_Subledger_Job__c != null && p.Inventory_Subledger_Job__c == null) || (pr.JE_Subledger_Job__c != null && p.JE_Subledger_Job__c == null)){	            	
	            	pr.AR_Subledger_Job__c = p.AR_Subledger_Job__c;
	            	pr.AP_Subledger_Job__c = p.AP_Subledger_Job__c;
	            	pr.Shipment_Subledger_Job__c = p.Shipment_Subledger_Job__c;
	            	pr.Receiving_Subledger_Job__c = p.Receiving_Subledger_Job__c;
	            	pr.FA_Subledger_Job__c = p.FA_Subledger_Job__c;
	            	pr.Inventory_Subledger_Job__c = p.Inventory_Subledger_Job__c;
	            	pr.InterCompany_Subledger_Job__c = p.InterCompany_Subledger_Job__c;
	            	pr.JE_Subledger_Job__c = p.JE_Subledger_Job__c;
	            	DML.updateAsUser(pr);
	        	}
	
	        }
	        catch(exception e){
	        	return null;
	        }
        }
        
        reset(); 
        if ((period.AR_Subledger_Closed__c != null && subledgerType == 'AR') || (period.AP_Subledger_Closed__c != null && subledgerType == 'AP') || (period.Shipment_Subledger_Closed__c != null && subledgerType == 'SH') || (period.Receiving_Subledger_Closed__c != null && subledgerType == 'RC') || (period.Inventory_Subledger_Closed__c != null && subledgerType == 'IN') || (period.InterCompany_Subledger_Closed__c != null && subledgerType == 'IC') || (period.FA_Subledger_Closed__c != null && subledgerType == 'FA') || (period.GL_Close__c != null && subledgerType == 'JE')){
            Id pId = period.Id; 
            PageReference pg = Page.PeriodClose;
            pg.getParameters().put('id', pId);
            pg.setRedirect(true);
            return pg;      
        }
        else
        return null;

        
    }

    public pageReference goBack(){
        Id pId = period.Id; 
        PageReference p = Page.PeriodClose;
        p.getParameters().put('id', pId);
        p.setRedirect(true);
        return p;       
    }
    
    /*public void incrementalValidation(){
    	Period__c p = [SELECT Id, ar_subledger_job__c, ap_subledger_job__c, InterCompany_Subledger_Job__c,inventory_subledger_job__c, receiving_subledger_job__c, fa_subledger_job__c, shipment_subledger_job__c, je_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
    	IsValidateOnly = Boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
		if(subledgerType == 'AR'){
	        if(string.isEmpty(p.ar_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.AR_Subledger_Batch_Size__c == null ? 200 : period.AR_Subledger_Batch_Size__c);
		        ARSubledgerCloseBatch batch = new ARSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.AR_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The AR is currently validating'));
	        }
		}else if(subledgerType == 'AP'){
	        if(string.isEmpty(p.ar_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.AP_Subledger_Batch_Size__c == null ? 200 : period.AP_Subledger_Batch_Size__c);
		        APSubledgerCloseBatch batch = new APSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.AP_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The AP is currently validating'));
	        }
		}else if(subledgerType == 'SH'){
	        if(string.isEmpty(p.shipment_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.shipment_Subledger_Batch_Size__c == null ? 200 : period.Shipment_Subledger_Batch_Size__c);
		        ShipmentSubledgerCloseBatch batch = new ShipmentSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.Shipment_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Shipment is currently validating'));
	        }
		}else if(subledgerType == 'RC'){
	        if(string.isEmpty(p.receiving_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.receiving_Subledger_Batch_Size__c == null ? 200 : period.receiving_Subledger_Batch_Size__c);
		        ReceivingSubledgerCloseBatch batch = new ReceivingSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.Receiving_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Receiving is currently validating'));
	        }
		}else if(subledgerType == 'IN'){
	        if(string.isEmpty(p.inventory_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.inventory_Subledger_Batch_Size__c == null ? 200 : period.inventory_Subledger_Batch_Size__c);
		        InventorySubledgerCloseBatch batch = new InventorySubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.Inventory_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Inventory is currently validating')); 
	        }
		}else if(subledgerType == 'FA'){
	        if(string.isEmpty(p.fa_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.fa_Subledger_Batch_Size__c == null ? 200 : period.fa_Subledger_Batch_Size__c);
		        FASubledgerCloseBatch batch = new FASubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.FA_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Fixed Asset is currently validating'));
	        }
		}else if(subledgerType == 'IC'){
	        if(string.isEmpty(p.InterCompany_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.InterCompany_Subledger_Batch_Size__c == null ? 200 : period.InterCompany_Subledger_Batch_Size__c);
//TODO
//		        InterCompanySubledgerCloseBatch batch = new InterCompanySubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
//		        batch.isIncremental = true;
//	        	Id jobId = Database.Executebatch(batch, batchSize);
//		        p.InterCompany_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        update p;
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The InterCompany is currently validating'));
	        }
		}else if(subledgerType == 'JE'){
	        if(string.isEmpty(p.je_subledger_job__c)){
	        	integer batchSize = integer.valueOf(period.je_Subledger_Batch_Size__c == null ? 200 : period.je_Subledger_Batch_Size__c);
		        JESubledgerCloseBatch batch = new JESubledgerCloseBatch(period.company__c,period.Id,isValidateOnly);
		        batch.isIncremental = true;
	        	Id jobId = Database.Executebatch(batch, batchSize);
		        p.JE_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Journal Entry is currently validating'));
	        }
		}
        reset();           
    }*/
        
    public PageReference runAR(){
        String tId = 'AR'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true); 
    }  
    
/*    public void validateAR(){

        IsValidateOnly = Boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
        integer batchSize = integer.valueOf(period.AR_Subledger_Batch_Size__c == null ? 200 : period.AR_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new ARSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, ar_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.ar_subledger_job__c)){
	        p.AR_Subledger_Job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The AR is currently validating'));
        }
        reset();            
    }   
    
    public void closeAR(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the AR. Prior Period is open.'));
        }
        else if(period.AR_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the AR before the AR cut off'));
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.AR_Subledger_Batch_Size__c == null ? 200 : period.AR_Subledger_Batch_Size__c);
        	Id jobId = Database.Executebatch(new ARSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
            Period__c p = [SELECT Id, ar_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
	        if(string.isEmpty(p.ar_subledger_job__c)){
		        p.AR_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The AR is currently validating'));
	        }
            reset();

        }    
    } */  

    public void reopenAR(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the AR after the GL Close.Reopen the JE to continue'));
        }else{
            PeriodService.systemEditable.add(period.Id);
            Period__c p = new Period__c(Id = period.Id);
            p.AR_Subledger_Closed__c = null;
            DML.updateAsUser(p);
            reset();
        }
    }
    
    public PageReference runAP(){
        String tId = 'AP'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
    /*public void validateAP(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.AP_Subledger_Batch_Size__c == null ? 200 : period.AP_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new APSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, ap_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.ap_subledger_job__c)){
	        p.ap_subledger_job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The AP is currently validating'));
        }
        reset();            
    }   

    public void closeAP(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the AP. Prior Period is open.'));
        }
        else if(period.AP_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the AP before the AP cut off'));
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.AP_Subledger_Batch_Size__c == null ? 200 : period.AP_Subledger_Batch_Size__c);
        	Id jobId = Database.Executebatch(new APSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
            Period__c p = [SELECT Id, ap_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
	        if(string.isEmpty(p.ap_subledger_job__c)){
		        p.ap_subledger_job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The AP is currently validating'));
	        }
            reset();

        }     
    
    }  */ 

    public void reopenAP(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the AP after the GL Close.Reopen the JE to continue'));
        }else{
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.AP_Subledger_Closed__c = null;
        DML.updateAsUser(p);
        reset();
        }
    }
       
    public PageReference runIC(){
        String tId = 'IC'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
    /*public void validateIC(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.InterCompany_Subledger_Batch_Size__c == null ? 200 : period.InterCompany_Subledger_Batch_Size__c);
//        Id jobId = Database.Executebatch(new InterCompanySubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
//        Period__c p = [SELECT Id, InterCompany_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
//        if(string.isEmpty(p.InterCompany_subledger_job__c)){
//	        p.InterCompany_subledger_job__c = jobId;
//	        PeriodService.systemEditable.add(p.Id);
//	        update p;
//        }else{
//        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The InterCompany subledger is currently validating'));
//        }
        reset();            
    }   

    public void closeIC(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close Inter Company. Prior Period is open.'));
        }
        else if(period.InterCompany_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Inter Company before the AP cut off')); 
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.InterCompany_Subledger_Batch_Size__c == null ? 200 : period.InterCompany_Subledger_Batch_Size__c);
//        	Id jobId = Database.Executebatch(new InterCompanySubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
//            Period__c p = [SELECT Id, InterCompany_subledger_job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
//	        if(string.isEmpty(p.InterCompany_subledger_job__c)){
//		        p.InterCompany_subledger_job__c = jobId;
//		        PeriodService.systemEditable.add(p.Id);
//		        update p;
//	        }else{
//	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Inter Company subledger is currently validating'));
//	        }
            reset();

        }     
    
    } */  

    public void reopenIC(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the Inter Company after the GL Close. Reopen the JE to continue'));
        }else{
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.InterCompany_Subledger_Closed__c = null;
        update p;
        reset();
        }
    }
       
    public PageReference runShipment(){
        String tId = 'SH'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
     /*public void validateShipment(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.Shipment_Subledger_Batch_Size__c == null ? 10 : period.Shipment_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new ShipmentSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, Shipment_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.Shipment_Subledger_Job__c)){
	        p.Shipment_Subledger_Job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Shipment is currently validating'));
        }
        reset();            
    }   

    public void closeShipment(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Shipment. Prior Period is open.'));
        }
        else if(period.Shipment_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Shipment before the Shipment cut off'));
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.Shipment_Subledger_Batch_Size__c == null ? 10 : period.Shipment_Subledger_Batch_Size__c);
        	Id jobId = Database.Executebatch(new ShipmentSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
            Period__c p = [SELECT Id, Shipment_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
	        if(string.isEmpty(p.Shipment_Subledger_Job__c)){
		        p.Shipment_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Shipment is currently validating'));
	        }
            reset();

        }
    
    } */  
    
    public void reopenShipment(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the Shipment after the GL Close.Reopen the JE to continue'));
        }else{
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.Shipment_Subledger_Closed__c = null;
        DML.updateAsUser(p);
        reset();
    }
    }
    
    public PageReference runReceiving(){
        String tId = 'RC'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
    /*public void validateReceiving(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.Receiving_Subledger_Batch_Size__c == null ? 10 : period.Receiving_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new ReceivingSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, Receiving_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.Receiving_Subledger_Job__c)){
	        p.Receiving_Subledger_Job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Receiving is currently validating'));
        }
        reset();            
    }   

    public void closeReceiving(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Receiving,Prior Period is open.'));
        }
        else if(period.Receiving_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Receiving before the Receiving cut off'));
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.Receiving_Subledger_Batch_Size__c == null ? 10 : period.Receiving_Subledger_Batch_Size__c);
        	Id jobId = Database.Executebatch(new ReceivingSubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
            Period__c p = [SELECT Id, Receiving_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
	        if(string.isEmpty(p.Receiving_Subledger_Job__c)){
		        p.Receiving_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Receiving is currently validating'));
	        }
            reset();

        }     
    } */  
    
    public void reopenReceiving(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the Receiving after the GL Close.Reopen the JE to continue'));
        }else{
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.Receiving_Subledger_Closed__c = null;
        DML.updateAsUser(p);
        reset();
    }
    }
    
    public PageReference runInventory(){
        String tId = 'IN'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
    /*public void validateInventory(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.Inventory_Subledger_Batch_Size__c == null ? 10 : period.Inventory_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new InventorySubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, Inventory_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.Inventory_Subledger_Job__c)){
	        p.Inventory_Subledger_Job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Inventory is currently validating'));
        }
        reset();            
    }   

    public void closeInventory(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Inventory.Prior Period is open.'));
        }
        else if(period.Inventory_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the Inventory before the Inventory cut off'));
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.Inventory_Subledger_Batch_Size__c == null ? 10 : period.Inventory_Subledger_Batch_Size__c);
        	Id jobId = Database.Executebatch(new InventorySubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
            Period__c p = [SELECT Id, Inventory_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
	        if(string.isEmpty(p.Inventory_Subledger_Job__c)){
		        p.Inventory_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Inventory is currently validating'));
	        }
            reset();

        }     
    } */  
    
    public void reopenInventory(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the Inventory after the GL Close.Reopen the JE to continue'));
        }else{
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.Inventory_Subledger_Closed__c = null;
        DML.updateAsUser(p);
        reset();
    }
    }
    
    public PageReference runFA(){
        String tId = 'FA'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
    /*public void validateFA(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.FA_Subledger_Batch_Size__c == null ? 10 : period.FA_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new FASubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, FA_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.FA_Subledger_Job__c)){
	        p.FA_Subledger_Job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Fixed Asset is currently validating'));
        }
        reset();            
    }   

    public void closeFA(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the FA.Prior Period is open.'));
        }
        else if(period.FA_Subledger_CutOff__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the FA before the AP cut off'));
        }else{
            IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
            integer batchSize = integer.valueOf(period.FA_Subledger_Batch_Size__c == null ? 10 : period.FA_Subledger_Batch_Size__c);
        	Id jobId = Database.Executebatch(new FASubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
            Period__c p = [SELECT Id, FA_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
	        if(string.isEmpty(p.FA_Subledger_Job__c)){
		        p.FA_Subledger_Job__c = jobId;
		        PeriodService.systemEditable.add(p.Id);
		        DML.updateAsUser(p);
	        }else{
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Fixed Asset is currently validating'));
	        }
            reset();

        }     
    
    } */  
    
    public void reopenFA(){
        if(period.GL_Close__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not reopen the FA after the GL Close.Reopen the JE to continue'));
        }else{
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.FA_Subledger_Closed__c = null;
        DML.updateAsUser(p);
        reset();
        
    }
    }
    
    public PageReference runJE(){
        String tId = 'JE'; 
        Id pId = period.Id; 
        PageReference p = Page.PeriodCloseExceptions;
        p.getParameters().put('SubledgerType', tId);
        p.getParameters().put('id', pId);
        return p.setRedirect(true);  
    } 
    
    /*public void validateJE(){

        IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));         
        integer batchSize = integer.valueOf(period.JE_Subledger_Batch_Size__c == null ? 200 : period.JE_Subledger_Batch_Size__c);
        Id jobId = Database.Executebatch(new JESubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
        Period__c p = [SELECT Id, JE_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
        if(string.isEmpty(p.JE_Subledger_Job__c)){
	        p.JE_Subledger_Job__c = jobId;
	        PeriodService.systemEditable.add(p.Id);
	        DML.updateAsUser(p);
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Journal Entry is currently validating'));
        }
        reset();            
    }   

    public void closeJE(){
        if(period.prior_period__r.Closed__c != true && period.prior_period__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the JE.Prior Period is open.'));
        }
        else if(period.Period_Cut_Off__c > currDate){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You can not close the JE before the Period cut off'));
        }else{
            {
                IsValidateOnly = boolean.valueOf(ApexPages.currentPage().getParameters().get('IsValidateOnly'));
                integer batchSize = integer.valueOf(period.JE_Subledger_Batch_Size__c == null ? 200 : period.JE_Subledger_Batch_Size__c);
        		Id jobId = Database.Executebatch(new JESubledgerCloseBatch(period.company__c,period.Id,isValidateOnly),batchSize);
                Period__c p = [SELECT Id, JE_Subledger_Job__c FROM Period__c WHERE Id = :period.Id FOR UPDATE];
		        if(string.isEmpty(p.JE_Subledger_Job__c)){
			        p.JE_Subledger_Job__c = jobId;
			        PeriodService.systemEditable.add(p.Id);
			        DML.updateAsUser(p);
		        }else{
		        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Journal Entry is currently validating'));
		        }
                reset();
            }

        }     
    
    } */  
    
    public void reopenJE(){
        PeriodService.systemEditable.add(period.Id);
        Period__c p = new Period__c(Id = period.Id);
        p.GL_Close__c = null;
        DML.updateAsUser(p);
        reset();
    }
    
    public void reset(){
        if(!test.isRunningTest()){
            con.reset();
            //period = (Period__c)con.getRecord();
            //period = this.period;
        }
        period = [Select id, Name, Open__c, AR_Subledger_Job__c, InterCompany_Subledger_Job__c, AP_Subledger_Job__c, Shipment_Subledger_Job__c, Receiving_Subledger_Job__c, Inventory_Subledger_Job__c, FA_Subledger_Job__c, JE_Subledger_Job__c, 
					Period_Start__c,prior_period__r.receiving_subledger_cutoff__c,Type__c,prior_period__r.InterCompany_subledger_cutoff__c,
	                AR_Subledger_Cutoff__c, InterCompany_Subledger_Cutoff__c, AP_Subledger_Cutoff__c, Shipment_Subledger_Cutoff__c, Receiving_Subledger_Cutoff__c, Inventory_Subledger_Cutoff__c, FA_Subledger_Cutoff__c, je_cutoff__c,prior_period__r.je_cutoff__c,
	                Company__c,Prior_Period__c,prior_period__r.ar_subledger_cutoff__c,prior_period__r.inventory_subledger_cutoff__c, prior_period__r.Closed__c, 
	                AR_Subledger_Closed__c, InterCompany_Subledger_Closed__c, AP_Subledger_Closed__c, Shipment_Subledger_Closed__c, Receiving_Subledger_Closed__c, Inventory_Subledger_Closed__c, FA_Subledger_Closed__c, GL_Close__c,
	                Period_End__c,prior_period__r.fa_subledger_cutoff__c,prior_period__r.shipment_subledger_cutoff__c,prior_period__r.ap_subledger_cutoff__c,
	                AR_Subledger_Last_Run__c,AP_Subledger_Last_Run__c,JE_Subledger_Last_Run__c,InterCompany_Subledger_Last_Run__c,FA_Subledger_Last_Run__c,Inventory_Subledger_Last_Run__c,Receiving_Subledger_Last_Run__c,Shipment_Subledger_Last_Run__c,
        			AR_Valid_After__c, InterCompany_Valid_After__c, AP_Valid_After__c, FA_Valid_After__c, Shipment_Valid_After__c, Receiving_Valid_After__c, Inventory_Valid_After__c, JE_Valid_After__c,
        			prior_period__r.ar_subledger_closed__c,prior_period__r.ap_subledger_closed__c,prior_period__r.shipment_subledger_closed__c,prior_period__r.receiving_subledger_closed__c,
					prior_period__r.fa_subledger_closed__c,prior_period__r.InterCompany_subledger_closed__c,prior_period__r.inventory_subledger_closed__c,prior_period__r.gl_close__c
        			from Period__c
        			Where id = :this.period.id];
    }
    @RemoteAction
    public static JsonResult getExceptions(string subledgerType, string periodJson, string isValidateOnlyString){
        JsonResult result = new JsonResult();       
        List<exceptionWrapper> exceptionWrapperList = new List<exceptionWrapper>();
        string subledgerTypeString;
            Period__c periodDS = (Period__c)JSON.deserialize(periodJson, Period__c.class);
            list<string> Excpt = new list<string>();
            List<sObject> sourceDocs  = new List<sObject>(); 
            List<Accounting_Entry__c> exceptionAEs = new List<Accounting_Entry__c>();
            list<Id> whatIds = new list<Id>();
            
            Period__c period = [select Open__c, AR_Subledger_Job__c, InterCompany_Subledger_Job__c, AP_Subledger_Job__c, Shipment_Subledger_Job__c, Receiving_Subledger_Job__c, Inventory_Subledger_Job__c, FA_Subledger_Job__c, JE_Subledger_Job__c,Period_Start__c,prior_period__r.receiving_subledger_cutoff__c,Type__c,prior_period__r.InterCompany_subledger_cutoff__c,
                                AR_Subledger_Cutoff__c, AP_Subledger_Cutoff__c, InterCompany_subledger_cutoff__c, Shipment_Subledger_Cutoff__c, Receiving_Subledger_Cutoff__c, Inventory_Subledger_Cutoff__c, FA_Subledger_Cutoff__c,JE_Cutoff__c,Company__c,Prior_Period__c,Period_End__c,prior_period__r.ar_subledger_cutoff__c,prior_period__r.inventory_subledger_cutoff__c,prior_period__r.Closed__c,
                                AR_Subledger_Closed__c, AP_Subledger_Closed__c, InterCompany_Subledger_Closed__c, Shipment_Subledger_Closed__c, Receiving_Subledger_Closed__c, Inventory_Subledger_Closed__c, FA_Subledger_Closed__c, GL_Close__c,prior_period__r.fa_subledger_cutoff__c,prior_period__r.shipment_subledger_cutoff__c,prior_period__r.ap_subledger_cutoff__c,
                                AR_Subledger_Job_Exception__c, InterCompany_Subledger_Job_Exception__c, AP_Subledger_Job_Exception__c,FA_Subledger_Job_Exception__c,JE_Subledger_Job_Exception__c,Inventory_Subledger_Job_Exception__c,Receiving_Subledger_Job_Exception__c,Shipment_Subledger_Job_Exception__c
                                FROM Period__c
                                WHERE id =:periodDS.id];
                                
            if(subledgerType == 'AR'){
  				subledgerTypeString = 'AR';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.AR, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.ar_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.ar_subledger_cutoff__c;
            	//or Bank_File__c!= null condition commented for KNDY-10268 removal of bank file object reference
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Customer_Invoice__c != null OR Customer_Receipt__c != null ) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field commented for KNDY-10268 removal of bank file object reference
				//Bank_File__c != null AND line 1273
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Customer_Invoice__r.Name, Customer_Receipt__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c //,Bank_File__r.Name
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true 
                                AND Status__c != 'Obsolete'
//                                AND period__c  = :period.id
                                AND ((Customer_Invoice__c != null AND ((Customer_Invoice__r.posting_date__c > :priorPeriodSLC OR Customer_Invoice__r.Finalized_Date__c > :priorPeriodSLC) AND (Customer_Invoice__r.posting_date__c <= :currentPeriodSLC OR Customer_Invoice__r.Finalized_Date__c <= :currentPeriodSLC)))
                                OR (Customer_Receipt__c != null AND ((Customer_Receipt__r.posting_date__c > :priorPeriodSLC OR Customer_Receipt__r.Finalized_Date__c > :priorPeriodSLC) AND (Customer_Receipt__r.posting_date__c <= :currentPeriodSLC OR Customer_Receipt__r.Finalized_Date__c <= :currentPeriodSLC)))
                                //OR ( ((Bank_File__r.posting_date__c > :priorPeriodSLC OR Bank_File__r.Finalized_Date__c > :priorPeriodSLC) AND (Bank_File__r.posting_date__c <= :currentPeriodSLC OR Bank_File__r.Finalized_Date__c <= :currentPeriodSLC)))
                                OR (Bank_Transaction_Group__c != null AND ((Bank_Transaction_Group__r.posting_date__c > :priorPeriodSLC OR Bank_Transaction_Group__r.Finalized_Date__c > :priorPeriodSLC) AND (Bank_Transaction_Group__r.posting_date__c <= :currentPeriodSLC OR Bank_Transaction_Group__r.Finalized_Date__c <= :currentPeriodSLC)))
                                )) LIMIT 20];
//                                AND (Customer_Invoice__c != null OR Customer_Receipt__c != null OR Bank_File__c != null)) OR Id in:whatIds OR id='a03j0000002rjEj'
                                           
            }
            
            else if(subledgerType == 'AP'){
  				subledgerTypeString = 'AP';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.AP, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.ap_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.ap_subledger_cutoff__c;
				//for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Supplier_Invoice__c != null OR Supplier_Payment__c != null OR Purchase_Order__c != null) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Supplier_Invoice__c != null OR Supplier_Payment__c != null ) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){					
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
	          //FIN-1094 Remove tracking POs in financial close process.				
	          // Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Supplier_Invoice__r.Name, Supplier_Payment__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true  
                                AND Status__c != 'Obsolete'
 //                               AND period__c  = :period.id
                                 AND ((Supplier_Invoice__c != null AND ((Supplier_Invoice__r.posting_date__c > :priorPeriodSLC OR Supplier_Invoice__r.Finalized_Date__c > :priorPeriodSLC) AND (Supplier_Invoice__r.posting_date__c <= :currentPeriodSLC OR Supplier_Invoice__r.Finalized_Date__c <= :currentPeriodSLC)))
                                OR (Supplier_Payment__c != null AND ((Supplier_Payment__r.posting_date__c > :priorPeriodSLC OR Supplier_Payment__r.Finalized_Date__c > :priorPeriodSLC) AND (Supplier_Payment__r.posting_date__c <= :currentPeriodSLC OR Supplier_Payment__r.Finalized_Date__c <= :currentPeriodSLC))))) LIMIT 20];                                                           
  //                              OR (Purchase_Order__c != null AND ((Purchase_Order__r.posting_date__c > :priorPeriodSLC OR Purchase_Order__r.Finalized_Date__c > :priorPeriodSLC) AND (Purchase_Order__r.posting_date__c <= :currentPeriodSLC OR Purchase_Order__r.Finalized_Date__c <= :currentPeriodSLC))))) LIMIT 20];
 //                               AND (Supplier_Invoice__c != null OR Supplier_Payment__c != null OR Purchase_Order__c != null)) OR Id in:whatIds LIMIT 1000];
            }
            else if(subledgerType == 'SH'){
  				subledgerTypeString = 'Shipment';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.SHIPMENT, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.shipment_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.shipment_subledger_cutoff__c;
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND Shipment__c != null AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Shipment__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true  
                                AND Status__c != 'Obsolete'
//                                AND period__c  = :period.id
                                AND (Shipment__c != null AND ((Shipment__r.posting_date__c > :priorPeriodSLC OR Shipment__r.Finalized_Date__c > :priorPeriodSLC) AND (Shipment__r.posting_date__c <= :currentPeriodSLC OR Shipment__r.Finalized_Date__c <= :currentPeriodSLC)))) LIMIT 20];
//                                AND (Shipment__c != null)) OR Id in:whatIds LIMIT 1000];
            }
            else if(subledgerType == 'RC'){
  				subledgerTypeString = 'Receiving';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.RECEIVING, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.receiving_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.receiving_subledger_cutoff__c;
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Receiving_Document__c != null) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Receiving_Document__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true  
                                AND Status__c != 'Obsolete'
       //                         AND period__c  = :period.id
                                AND (Receiving_Document__c != null AND ((Receiving_Document__r.posting_date__c > :priorPeriodSLC OR Receiving_Document__r.Finalized_Date__c > :priorPeriodSLC) AND (Receiving_Document__r.posting_date__c <= :currentPeriodSLC OR Receiving_Document__r.Finalized_Date__c <= :currentPeriodSLC)))) LIMIT 20];
       //                         AND (Receiving_Document__c != null)) OR Id in:whatIds LIMIT 1000];
            }
            else if(subledgerType == 'IN'){
  				subledgerTypeString = 'Inventory';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.INVENTORY, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.inventory_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.inventory_subledger_cutoff__c;
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Work_Order__c != null OR Inventory_Change__c != null) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Work_Order__r.Name,Inventory_Change__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true 
                                AND Status__c != 'Obsolete' 
//                                AND period__c  = :period.id
                                AND ((Work_Order__c != null AND ((Work_Order__r.posting_date__c > :priorPeriodSLC OR Work_Order__r.Finalized_Date__c > :priorPeriodSLC) AND (Work_Order__r.posting_date__c <= :currentPeriodSLC OR Work_Order__r.Finalized_Date__c <= :currentPeriodSLC)))
                                OR (Inventory_Change__c != null AND ((Inventory_Change__r.posting_date__c > :priorPeriodSLC OR Inventory_Change__r.Finalized_Date__c > :priorPeriodSLC) AND (Inventory_Change__r.posting_date__c <= :currentPeriodSLC OR Inventory_Change__r.Finalized_Date__c <= :currentPeriodSLC))))) LIMIT 20];
//                                AND (Work_Order__c != null OR Inventory_Change__c != null)) OR Id in:whatIds LIMIT 1000];
            }
            else if(subledgerType == 'IC'){
  				subledgerTypeString = 'InterCompany';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.INTERCOMPANY, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.InterCompany_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.inventory_subledger_cutoff__c;
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Invoice__c != null OR payment__c != null) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Work_Order__r.Name,Inventory_Change__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Payment__c , Invoice__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true 
                                AND Status__c != 'Obsolete' 
//                                AND period__c  = :period.id
                                AND ((Payment__c != null AND ((Payment__r.posting_date__c > :priorPeriodSLC OR Payment__r.Finalized_Date__c > :priorPeriodSLC) AND (Payment__r.posting_date__c <= :currentPeriodSLC OR Payment__r.Finalized_Date__c <= :currentPeriodSLC)))
                                OR (Invoice__c != null AND ((Invoice__r.posting_date__c > :priorPeriodSLC OR Invoice__r.Finalized_Date__c > :priorPeriodSLC) AND (Invoice__r.posting_date__c <= :currentPeriodSLC OR Invoice__r.Finalized_Date__c <= :currentPeriodSLC))))) LIMIT 20];
//                                AND (Work_Order__c != null OR Inventory_Change__c != null)) OR Id in:whatIds LIMIT 1000];
            }
            else if(subledgerType == 'FA'){
  				subledgerTypeString = 'FA';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.FA, period);
            	Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.FA_subledger_cutoff__c;
            	Datetime currentPeriodSLC = period.FA_subledger_cutoff__c;
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Fixed_Asset_Depreciation__c != null OR Fixed_Asset_Adjustment__c != null) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Fixed_Asset_Depreciation__r.Name,Fixed_Asset_Adjustment__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true  
                                AND Status__c != 'Obsolete'
//                                AND period__c  = :period.id
                                AND ((Fixed_Asset_Depreciation__c != null AND ((Fixed_Asset_Depreciation__r.posting_date__c > :priorPeriodSLC OR Fixed_Asset_Depreciation__r.Finalized_Date__c > :priorPeriodSLC) AND (Fixed_Asset_Depreciation__r.posting_date__c <= :currentPeriodSLC OR Fixed_Asset_Depreciation__r.Finalized_Date__c <= :currentPeriodSLC)))
                                OR (Fixed_Asset_Adjustment__c != null AND ((Fixed_Asset_Adjustment__r.posting_date__c > :priorPeriodSLC OR Fixed_Asset_Adjustment__r.Finalized_Date__c > :priorPeriodSLC) AND (Fixed_Asset_Adjustment__r.posting_date__c <= :currentPeriodSLC OR Fixed_Asset_Adjustment__r.Finalized_Date__c <= :currentPeriodSLC))))) LIMIT 20];
//                                AND (Fixed_Asset_Depreciation__c != null OR Fixed_Asset_Adjustment__c != null)) OR Id in:whatIds LIMIT 1000];
            }       
    
            else if(subledgerType == 'JE'){
  				subledgerTypeString = 'JE';
                sourceDocs = SubledgerService.returnOpenSourceDocs(SubledgerService.Subledger.PERIOD, period);
				for(task t:[SELECT Id, createdDate, what.Name, whatId, Subject FROM Task WHERE WhatId IN (SELECT Id FROM Accounting_Entry__c WHERE period__c  = :period.id AND (Journal_Entry__c != null) AND Status__c != 'Obsolete') AND Status != 'Closed' LIMIT 20]){
					if (t.subject.contains('Validation')){
						whatIds.add(t.WhatId);
					}
				}
				// Bank_File__c field removed for KNDY-10268 removal of bank file object reference
                exceptionAEs = [SELECT ID, name, source_document_object_name__c, Journal_Entry__r.Name,Supplier_Invoice__c,Supplier_Payment__c,Customer_Invoice__c,Customer_Receipt__c,Shipment__c,Receiving_Document__c,Work_Order__c , Inventory_Change__c,Fixed_Asset_Depreciation__c , Fixed_Asset_Adjustment__c,Journal_Entry__c,Has_Exceptions__c
                                FROM Accounting_Entry__c 
                                WHERE (has_exceptions__c = true  
                                AND Status__c != 'Obsolete'
                                AND period__c  = :period.id
                                AND Journal_Entry__c != null) OR Id in:whatIds LIMIT 20];
            }       
    
            for(sObject s:sourceDocs){
                Schema.DescribeSObjectResult desObj = s.getSObjectType().getDescribe(); 
                exceptionWrapper e = new exceptionWrapper();
                string e1 = desObj.getLabel();
                Excpt.add(e1);
                e.sourceDocumentType  = desObj.getLabel();
                e.sourceDocument = s.id;
                string sobjectname = desObj.getLocalName(); 
                e.exceptionType = 'Accounting Entry not Generated';
                Object o = s.get('Name');
                e.sourceDocumentName  = String.valueOf(o);
                
                if (e.sourceDocument != null && e.sourceDocumentName != null) {
                    e.sourceDocumentLink = string.format('<a href="/{0}" target="_blank">{1}</a>', new string[] { e.sourceDocument, e.sourceDocumentName });
                }
                
                exceptionWrapperList.add(e);
                
            }
            
            for(Accounting_Entry__c a:exceptionAEs){               
                exceptionWrapper e = new exceptionWrapper();
                if(a.source_document_object_name__c != '' && a.source_document_object_name__c != null && a.source_document_object_name__c != 'Manual'){
                    string sourceDocPath = AccountingEntryService.SourceDocPathMap.get(a.source_document_object_name__c);
                    if(schemautil.getInstance().objectExists(a.source_document_object_name__c)){
                        
                        e.sourceDocumentType = schemautil.getInstance().getGlobalDescribe(a.source_document_object_name__c).getDescribe().getLabel();
                        e.sourceDocument = (string)a.get(sourceDocPath);
                        e.sourceDocumentName = (string)a.getSobject(sourceDocPath.replace('__c', '__r')).get('name');
                        
                    }
                }
    
                if(a.has_exceptions__c == true)
					e.exceptionType = 'Accounting Entry Has Exceptions';
				else
					e.exceptionType = 'Accounting Entry Not Validated. Please regenerate Accounting Entry';
                
                if (e.sourceDocument != null && e.sourceDocumentName != null) {
                    e.sourceDocumentLink = string.format('<a href="/{0}" target="_blank">{1}</a>', new string[] { e.sourceDocument, e.sourceDocumentName });
                }
                
                exceptionWrapperList.add(e);
                
            }
        
            if(exceptionWrapperList.size() > 0 && isValidateOnlyString == 'False'){
                result.addMessage('You can not close the ' + subledgerTypeString + ',You have exceptions.', ApexPages.Severity.ERROR);
                
                }
                else if(exceptionWrapperList.size() == 0 && isValidateOnlyString == 'True'){
                    result.addMessage('This has no exceptions.', ApexPages.severity.INFO);
                }else if(exceptionWrapperList.size() == 0 && isValidateOnlyString != 'False'){
                	result.addMessage('This returned no exceptions from last validation process.', ApexPages.severity.INFO);
                }
                else if ((isValidateOnlyString == 'True' || isValidateOnlyString == 'False' ) && ((period.AR_Subledger_job_Exception__c == true && subledgerType == 'AR') || (period.AP_Subledger_job_Exception__c == true && subledgerType == 'AP') || (period.Shipment_Subledger_job_Exception__c == true && subledgerType == 'SH') || (period.Receiving_Subledger_job_Exception__c == true && subledgerType == 'RC') || (period.Inventory_Subledger_job_Exception__c == true && subledgerType == 'IN') || (period.FA_Subledger_job_Exception__c == true && subledgerType == 'FA') || (period.JE_Subledger_job_Exception__c == true && subledgerType == 'JE'))){
                    result.addMessage('This validation/close process ran into issues. Please check your chatter feed for more information.', ApexPages.severity.ERROR);
                }       
            result.records = exceptionWrapperList;
            result.total = exceptionWrapperList.size(); 
            return result;
        
    }


}