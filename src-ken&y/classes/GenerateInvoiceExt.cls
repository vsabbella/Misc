public with sharing class GenerateInvoiceExt {
	
    public id recId{get;set;}
	private static InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance(); 
	private static SchemaUtil util = SchemaUtil.getInstance();
	public static string objectName{get;set;}
	public string nspace { get { return KSE.Namespace; }}
	
	public GenerateInvoiceExt(ApexPages.StandardSetController setController) {
        System.debug(logginglevel.error,'Inside the Set Constructor----->');
         
    }
	
	public GenerateInvoiceExt(ApexPages.standardController controller) {
	    System.debug(logginglevel.error,'Inside the Constructor');
		if(controller == null) {
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'Controller not set'));
		}else { 
			recId = controller.getRecord().Id;
			objectName = util.getObjectNameFromId(recId);
		}
	}
	public class InvoiceException extends Exception {}
	
	private static map<id,Fulfillment__c> getFulfillments(Id soId) {
		return igrUtil.getFulfillments(util.getObjectNameFromId(soId), new set<Id>{soId});
	}
	
	private static set<InvoiceGroupingRuleDefinition> getIGR(Id companyId){
        set<InvoiceGroupingRuleDefinition> sGroupingRules = new set<InvoiceGroupingRuleDefinition>();
        SOQLUtil soql;
        soql = new SOQLUtil('Invoice_Grouping_Rule__c', TRUE);
        soql.addAllFields();
        soql.addFields(new set<String>{'Billing_UOM__c','Billing_UOM__r.Every__c','Billing_UOM__r.Recurrence__c'});
        soql.setWhereClause('Company__c =:companyId and Rank__c != null and Is_Valid__c = true and Is_Active__c = true');
        for(Invoice_Grouping_Rule__c igr : Database.query(soql.getQuery())){
			sGroupingRules.add(new InvoiceGroupingRuleDefinition(igr));
		}
        return sGroupingRules;
    }
    
    @remoteAction
    public static JsonResult validate(Id recordId, string objName) {
		JsonResult result = new JsonResult();
		map<id,Fulfillment__c> mFulfillments  = new map<id,Fulfillment__c>();
		map<String, set<String>> objectToField = new map<String, set<String>>{
			'Agreement__c' => new set<String>{'Company__c', 'Activation_Date__c','Customer__c'},
			'Sales_Order__c' => new set<String>{'Company__c', 'Has_Exceptions__c','Customer__c'},
			'Shipment__c' => new set<String>{'Company__c', 'Has_Exceptions__c','Customer__c'}
		};
        mFulfillments  = getFulfillments(recordId);
        String whereClause = 'Id = :recordId';
        SOQLUtil soql = new SOQLUtil(objName);
        set<string> objFields =  objectToField.get(objName);   
        soql.addFields(objFields);
        soql.setWhereClause(whereClause);
        sObject rec = DataBase.query(soql.getQuery());
		system.debug('mFulfillments '+mFulfillments);
		Savepoint sp = Database.setSavepoint();
		try {
			if(objName == 'Agreement__c') {
				system.debug('(Date)record.get(Activation_Date__c) '+(Date)rec.get('Activation_Date__c')); 
				if((Date)rec.get('Activation_Date__c') == null) { 
					string error = Label.Acceptance_Date_Unspecified;
					string msg;
					if(!mFulfillments.isEmpty()){
						msg = '<br/>Fulfillment :';
						for(Fulfillment__c fl: mFulfillments.values()){
							msg = msg + '<a href="/'+fl.Id+'">' + fl.Name + '</a>'+', ';
						}
						msg = msg.removeEnd(',');
					}else{
						 msg =  Label.No_Fulfillments_To_Invoice;
					}
					result.addMessage(error+msg, ApexPages.severity.ERROR);
					result.success = false;
					return result;
				}else if((Date)rec.get('Activation_Date__c') > system.now()){
					string error = Label.Acceptance_Date_in_future;
					string msg;
					if(!mFulfillments.isEmpty()){
						msg = '<br/>Fulfillment :';
						for(Fulfillment__c fl: mFulfillments.values()){
							msg = msg + '<a href="/'+fl.Id+'">' + fl.Name + '</a>'+', ';
						}
						msg = msg.removeEnd(',');
					}else{
						 msg =  Label.No_Fulfillments_To_Invoice;
					}
					result.addMessage(error+msg, ApexPages.severity.ERROR);
					result.success = false;
					return result;
				}
			}else if(objectName == 'Sales_Order__c' || objectName == 'Shipment__c') {
				if((Boolean)rec.get('Has_Exceptions__c')== true) {
					string error = 'We did not invoice the following fulfillments as the related '+ (objectName == 'Sales_Order__c' ? 'sales order ': 'shipment ') + 'has an exception:';
					string msg;
					if(!mFulfillments.isEmpty()){
						msg = '<br/>Fulfillment :';
						for(Fulfillment__c fl: mFulfillments.values()){
							msg = msg + '<a href="/'+fl.Id+'">' + fl.Name + '</a>'+', ';
						}
						msg = msg.removeEnd(',');
					}else{
						 msg =  Label.No_Fulfillments_To_Invoice;
					}
					result.addMessage(error+msg, ApexPages.severity.ERROR);
					result.success = false;
					return result;
				}
			}
			if(mFulfillments.isEmpty()) {
				result.addMessage(Label.No_Fulfillments_To_Invoice, ApexPages.severity.ERROR);
				result.success = false;
				return result;
				
			} else {
				result.addMessage(Label.Create_Ad_hoc_Invoice_for_fulfillment, ApexPages.severity.INFO);
                result.success = true;
				result.records = new list<object>{rec};
                return result;
            }
        }catch(Exception ex) {
            Database.rollback(sp);
            result.addMessage(ex.getMessage() +' '+ex.getStackTraceString(), ApexPages.severity.ERROR);
            system.debug('validate*'+ex.getMessage()+' '+ex.getStackTraceString());
			result.success = false;
            return result;
        }
    }
    
    //This wrapper is used to create a key and value of container and list of fulfillment
    public class InnerFulfillmentWrapper{
    	public InvoiceGroupingRuleContainer igrc;
    	public dateTime recurrenceStartDateTime;     // introduced due to issue with deserializing 'on the fly' recurrenceStartDate field in igrc variable
    	public list<Fulfillment__c> lstFl = new list<Fulfillment__c>();
    	InnerFulfillmentWrapper(){
    	}
    	InnerFulfillmentWrapper(InvoiceGroupingRuleContainer igrc, list<Fulfillment__c> lstFl){
    		this.igrc = igrc;
    		this.lstFl = lstFl;
    	}
    	InnerFulfillmentWrapper(InvoiceGroupingRuleContainer igrc, list<Fulfillment__c> lstFl, dateTime recurrenceStartDateTime){
    		this.igrc = igrc;
    		this.lstFl = lstFl;
    		this.recurrenceStartDateTime = recurrenceStartDateTime;
    	}
    }
    
    //This wrapper is used to create a key and value of fulfillment type i.e. AGGREGATE, RECURRING and inner wrapper
    public class OuterFulfillmentWrapper{
    	public InvoiceGroupingRuleService.FulfillmentType ftype;
    	public list<innerFulfillmentWrapper> igrFl = new list<innerFulfillmentWrapper>();
    	OuterFulfillmentWrapper(){
    	}
    	OuterFulfillmentWrapper(InvoiceGroupingRuleService.FulfillmentType ftype, list<innerFulfillmentWrapper> igrFl){
    		this.ftype = ftype;
    		this.igrFl = igrFl;
    	}
    }
    
    @remoteAction
    public static JsonResult nextOnProcessFulfillment(boolean useIGR, list<Fulfillment__c> fRows, list<Invoice_Grouping_Rule__c> lstIgr){  
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try{
             
	        set<Id> fulfillmentIds = KSE.grepIdSetFromList(fRows);
	        map<id,Fulfillment__c> mFulfillments = igrUtil.getFulfillments('Fulfillment__c',fulfillmentIds);
	        
	        system.debug(logginglevel.error,'fRows '+fRows);
	        system.debug(logginglevel.error,'mFulfillments '+mFulfillments);
	        
	        set<InvoiceGroupingRuleDefinition> setRuleDef = new set<InvoiceGroupingRuleDefinition>();
	        
	        system.debug(KSE.grepRelatedIdSetFromList( fRows , 'Company__c', true));
	        set<Id> companyIdset = KSE.grepRelatedIdSetFromList( fRows , 'Company__c', true);
	        Id companyId = (new list<Id>(companyIdset))[0]; // selected fulfillments belong to same company and would be 1 Id in the set.
	        
            if(useIGR){ // IGR defined on the company is selected
                setRuleDef = getIGR(companyId);
                if(setRuleDef.isEmpty()){
                   result.addMessage(Label.Check_IGR_radiobutton, ApexPages.severity.ERROR); 
                    result.success = false;
                    return result;
                }
                system.debug(logginglevel.error,'setRuleDef--1->'+setRuleDef);
            }else if(lstIgr == null){ //One fulfillment is selected to invoice, then the IGR created in memory will be used
                setRuleDef.add(InvoiceGroupingRuleDefinition.createRuleForSObject(companyId,'')); 
                system.debug(logginglevel.error,'setRuleDef--2->'+setRuleDef);
            }else{  // Dynamic IGR defined by the user
                lstIgr[0].Rank__c = 1;
                lstIgr[0].Company__c = companyId;
                if(!lstIgr[0].Group_By_Sales_Orders__c){
                    lstIgr[0].Group_By_Sales_Order_Types__c = true;
                }
                setRuleDef.add(new InvoiceGroupingRuleDefinition(lstIgr[0]));
                system.debug(logginglevel.error,'setRuleDef--3->'+setRuleDef);
            }

		    list<InvoiceGroupingRuleDefinition> sortedRules  =  new list<InvoiceGroupingRuleDefinition>(setRuleDef);
			sortedRules.sort();
           
            result = groupingInvoices( mFulfillments, sortedRules);
            system.debug(logginglevel.error,'result---->'+result);
            
            if(result != null && result.success == null){
                String messageText = result.message;
                messageText = messageText.replace(' for this replaceObjectName.','.');
                result.addMessage(messageText, ApexPages.severity.WARNING);
            }
            system.debug(logginglevel.error,'result---->'+result);
            System.debug(logginglevel.error,InvoiceGroupingRuleService.mapFlErrorMsgWrapper);
            if(!InvoiceGroupingRuleService.mapFlErrorMsgWrapper.isEmpty()){
                for(InvoiceGroupingRuleService.FlErrMsgWrapper FlWrapper: InvoiceGroupingRuleService.mapFlErrorMsgWrapper.values()){
                    string errorMsg = '<a href="/'+FlWrapper.FlId+'">' + FlWrapper.FlName + '</a>' + ' is a related fulfillment which is not invoiced because ';
                    if(!FlWrapper.lstErrorMsg.isEmpty()){
                        errorMsg = errorMsg + string.join(FlWrapper.lstErrorMsg,',');
                        result.addMessage(errorMsg, ApexPages.severity.ERROR);
                    }else{
                        if(!(FlWrapper.lstErrorMsg != null && FlWrapper.lstErrorMsg.size() == 0)){
                            errorMsg = errorMsg + 'an error has occured. Please contact your administrator';
                            result.addMessage(errorMsg, ApexPages.severity.ERROR);
                        }
                    }
                }
            }
          
          return result;  
        }catch(Exception ex) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(ex.getMessage() +' '+ex.getStackTraceString(), ApexPages.severity.ERROR);
            system.debug(logginglevel.error,'next - '+ex.getMessage()+' \n'+ex.getStackTraceString());
            return result;
        } 
        return result;
    }
    
    public static JsonResult groupingInvoices( map<id,Fulfillment__c> mFulfillments, list<InvoiceGroupingRuleDefinition> sortedRules){
        
        JsonResult result = new JsonResult();
        list<InnerFulfillmentWrapper> lstInnerWrapper = new list<InnerFulfillmentWrapper>();
        list<OuterFulfillmentWrapper> lstOuterWrapper = new list<OuterFulfillmentWrapper>();
			set<InvoiceGroupingRuleContainer> containers = new set<InvoiceGroupingRuleContainer>();
			map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments = new map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>>();
			typeToFulfillments = igrUtil.buildTypeToFulfillments(mFulfillments, sortedRules);
        system.debug(logginglevel.error,'typeToFulfillments '+typeToFulfillments);
			
			for(InvoiceGroupingRuleService.FulfillmentType fulfillmentType: typeToFulfillments.keyset()) {
				if(!typeToFulfillments.get(fulfillmentType).isEmpty()){ 
					lstInnerWrapper = new list<InnerFulfillmentWrapper>();
					for(InvoiceGroupingRuleContainer igrc: typeToFulfillments.get(fulfillmentType).keyset()) {
						containers.add(igrc);
						if(!typeToFulfillments.get(fulfillmentType).get(igrc).isEmpty()){
							DateTime dt = igrc.recurrenceStartDateTime;
							if(!Test.isRunningTest() && igrc.recurrenceStartDate != null){
								igrc.recurrenceStartDate = null;
								igrc.recurrenceStartDateTime = null;
							}
							lstInnerWrapper.add(new InnerFulfillmentWrapper(igrc,typeToFulfillments.get(fulfillmentType).get(igrc),dt)); 
						}
					}
				}
				lstOuterWrapper.add(new OuterFulfillmentWrapper(fulfillmentType,lstInnerWrapper));
			}
			
        system.debug(logginglevel.error,'containers size--> '+containers.size());
        system.debug(logginglevel.error,'containers '+containers); 
			if(containers.isEmpty()) {
				result.success = false;
			}else if(containers.size() > 1) {
                result.message = Label.Customer_Invoice_Confirm_Message_Start+' '+ containers.size() +' '+ Label.Customer_Invoice_Confirm_Message_Middle +' '+ 'replaceObjectName' + '. ' + Label.Click_Confirm_to_continue;
				result.success = null;
				result.records = lstOuterWrapper;  
			}else {
				result.success = true;
				result.records = lstOuterWrapper;
				system.debug('result.records '+result.records);	
			}
        
      return result;
    }
    
    @remoteAction
    public static JsonResult next(boolean useIGR, Id recordId, sObject rec){
        JsonResult result = new JsonResult();
        map<id,Fulfillment__c> mFulfillments = new map<id,Fulfillment__c>();
        mFulfillments  = getFulfillments(recordId);
        set<InvoiceGroupingRuleDefinition> setRuleDef = new set<InvoiceGroupingRuleDefinition>();
        Savepoint sp = Database.setSavepoint();
        try{
            if(useIGR){
                setRuleDef = getIGR((Id)rec.get('Company__c'));
                if(setRuleDef.isEmpty()){
                    result.addMessage(Label.Check_IGR_checkbox, ApexPages.severity.ERROR);
                    result.success = false;
                    return result;
                }
            }else{
                setRuleDef.add(InvoiceGroupingRuleDefinition.createRuleForSObject((Id)rec.get('Company__c'),util.getObjectNameFromId(recordId))); 
                system.debug('rule--->'+setRuleDef);
            }

		    list<InvoiceGroupingRuleDefinition> sortedRules  =  new list<InvoiceGroupingRuleDefinition>(setRuleDef);
			sortedRules.sort();
			
			result = groupingInvoices( mFulfillments, sortedRules);
			
			if(result != null && result.success == null){
			    objectName = util.getObjectNameFromId(recordId);
			    String messageText = result.message;
			    messageText = messageText.replace('replaceObjectName', (objectName == 'Sales_Order__c' ? 'sales order': (objectName == 'Shipment__c'?'shipment':'agreement')));
                result.addMessage(messageText, ApexPages.severity.WARNING);
			}
			
			if(!InvoiceGroupingRuleService.mapFlErrorMsgWrapper.isEmpty()){
				for(InvoiceGroupingRuleService.FlErrMsgWrapper FlWrapper: InvoiceGroupingRuleService.mapFlErrorMsgWrapper.values()){
				    string errorMsg = '<a href="/'+FlWrapper.FlId+'">' + FlWrapper.FlName + '</a>' + ' is a related fulfillment which is not invoiced because ';
				  	if(!FlWrapper.lstErrorMsg.isEmpty()){
				  	    errorMsg = errorMsg + string.join(FlWrapper.lstErrorMsg,',');
				  	    result.addMessage(errorMsg, ApexPages.severity.ERROR);
				  	}else{
				  		if(!(FlWrapper.lstErrorMsg != null && FlWrapper.lstErrorMsg.size() == 0)){
						  	errorMsg = errorMsg + 'an error has occured. Please contact your administrator';
						  	result.addMessage(errorMsg, ApexPages.severity.ERROR);
				  		}
					}
				}
			}
			return result;	
		}catch(Exception ex) {
			Database.rollback(sp);
			result.success = false;
			result.addMessage(ex.getMessage() +' '+ex.getStackTraceString(), ApexPages.severity.ERROR);
			system.debug(logginglevel.error,'next'+ex.getMessage()+' '+ex.getStackTraceString());
			return result;
		} 
		return result;
	}
	
	@remoteAction
	public static JSONResult createInvoice(string strTypeToFulfillments){
		System.debug(logginglevel.error,'strTypeToFulfillments--->'+strTypeToFulfillments);
		JsonResult result = new JsonResult();
		try{
			list<OuterFulfillmentWrapper> lstOuterWrapper = new list<OuterFulfillmentWrapper>();
			lstOuterWrapper = (list<OuterFulfillmentWrapper>)JSON.deserialize(strTypeToFulfillments, list<OuterFulfillmentWrapper>.class);
			System.debug(logginglevel.error,lstOuterWrapper);
			map<String,Customer_Invoice__c> mCIs = new map<String,Customer_Invoice__c>();
			map<String,Customer_Invoice_Line__c> mCILs = new map<String,Customer_Invoice_Line__c>();
			map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap = new map<String,Customer_Invoice_Sub_Line__c>();
			map<Id, Fulfillment__c> mFulfillmentsToUpdate = new  map<Id, Fulfillment__c>();
			map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments = new map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>>();
			if(!lstOuterWrapper.isEmpty()){
				for(OuterFulfillmentWrapper outWrap: lstOuterWrapper){
					map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> tempMap = new map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>();
					if(!outWrap.igrFl.isEmpty()){
						for(InnerFulfillmentWrapper inWrap: outWrap.igrFl){
							system.debug(logginglevel.error,'###'+inWrap.igrc);
							if(inWrap.recurrenceStartDateTime != null){
								system.debug(logginglevel.error,'###'+inWrap.recurrenceStartDateTime);
								inWrap.igrc.recurrenceStartDate = inWrap.recurrenceStartDateTime.date();
							}
							tempMap.put(inWrap.igrc,inWrap.lstFl);
						}
					}
					typeToFulfillments.put(outWrap.ftype,tempMap);
				}
			}
			System.debug(logginglevel.error,'typeToFulfillments--->'+typeToFulfillments);
			igrUtil.createInvoices(typeToFulfillments, null, mCIs, mCILs, mFulfillmentMap, mFulfillmentsToUpdate);

			igrUtil.calculateBestPrice(mCILs, mFulfillmentMap.values(), typeToFulfillments.values() );

			igrUtil.finishConsolidate(mCIs, mCILs, mFulfillmentMap, mFulfillmentsToUpdate);

			igrUtil.allowancesOperations(mCILs.values(),'Sales_Order__c',true, mFulfillmentMap.values());
	
			SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Name', 'Company__c','Invoice_Type__c'
			});
	        Set<Customer_Invoice__c> mCId  =  new Set<Customer_Invoice__c>(mCIs.values());
	        soql.setWhereClause('Id in :mCId');
			List<Customer_Invoice__c> invoices = Database.query(soql.getQuery());
			map<Id,Customer_Invoice__c> createdInvoices = new map<Id,Customer_Invoice__c>();
			for(Customer_Invoice__c ci : invoices){
				createdInvoices.put(ci.Id, ci);
			}
			system.debug(logginglevel.error,'in create invoice'+createdInvoices);
			system.debug(logginglevel.error,'in create invoice'+InvoiceGroupingRuleService.mapFlErrorMsgWrapper);
	        if(createdInvoices.isEmpty()){
	            result.success = false;
	        }else{
	        	result.success = true;
	        	result.records = invoices;
	        }
	        if(!InvoiceGroupingRuleService.mapFlErrorMsgWrapper.isEmpty()){
	        	for(InvoiceGroupingRuleService.FlErrMsgWrapper FlWrapper: InvoiceGroupingRuleService.mapFlErrorMsgWrapper.values()){
	            	string errorMsg = '<a href="/'+FlWrapper.FlId+'">' + FlWrapper.FlName + '</a>' + ' is a related fulfillment which is not invoiced because ';
	                if(!FlWrapper.lstErrorMsg.isEmpty()){
	                    errorMsg = errorMsg + string.join(FlWrapper.lstErrorMsg,',');
	                    result.addMessage(errorMsg, ApexPages.Severity.ERROR);
	                }else{
	                     if(!(FlWrapper.lstErrorMsg != null && FlWrapper.lstErrorMsg.size() == 0)){
						 	errorMsg = errorMsg + 'an error has occured. Please contact your administrator';
						  	result.addMessage(errorMsg, ApexPages.severity.ERROR);
				  		 }
	                 }
	             }
	        }
	        system.debug(logginglevel.error,'in create invoice'+InvoiceGroupingRuleService.mapFlErrorMsgWrapper);
	        system.debug(logginglevel.error,'in create invoice'+result);
	        return result;
		}catch(exception ex){
			result.success = false;
			result.addMessage(ex,ApexPages.Severity.ERROR);
			system.debug(logginglevel.error,'createInvoice*'+ex.getMessage()+' \n'+ex.getStackTraceString());
			return result;
		}  
		return result;
	}
	
	@remoteAction
	public static JSONResult prefinalizeActions(list<Customer_Invoice__c> lstCI){
		JsonResult result = new JsonResult();
		try{

			map<Id, map<id, Customer_Invoice__c>>createdInvoicesByCompany = new map<Id,map<Id,Customer_Invoice__c>>();
			if(!lstCI.isEmpty()){
				for(Customer_Invoice__c ci: lstCI){
					if(createdInvoicesByCompany.containsKey(ci.Company__c) == false){
						createdInvoicesByCompany.put(ci.Company__c, new map<Id, Customer_Invoice__c>());
					}
					createdInvoicesByCompany.get(ci.Company__c).put(ci.Id, ci);
				}
			}
			TaxService service = TaxService.getInstance();
			if(!service.HasTaxService){
				result.success = null;
				result.records = lstCI;
				system.debug(logginglevel.error,'**Tax service not implemented**');
				return result;
			}

			list<Customer_Invoice__c> lstCreatedInvoices = new list<Customer_Invoice__c>();
			result.success = null;
			
			Map<Id,Customer_Invoice__c> createdInvoices  = new map<Id,Customer_Invoice__c>();
			
			for(Customer_Invoice__c eachCI: lstCI ){
			    if(service.taxServiceConfigured(eachCI) == false){
			        //--Create a list of CIs where tax is not applicable
			        lstCreatedInvoices.add(eachCI);
			    }else{
			        createdInvoices.put(eachCI.Id,eachCI);
			    }
			}		
			
			if(createdInvoices.size()>0){
			   list<TaxService.TaxResult> taxResults = service.getTax(new List<Id>(createdInvoices.keySet())); 
			   system.debug('**taxResults**'+taxResults);
			   if(!taxResults.isEmpty()){
        				set<Customer_Invoice__c> setCreatedInvoices = new set<Customer_Invoice__c>();
        				for(TaxService.TaxResult tr: taxResults){
        					if(tr.obj.Id != null){
        						if(tr.isSuccess){
        							setCreatedInvoices.add(createdInvoices.get(tr.obj.Id));
        						}else{
        							string message = '<a href="/'+tr.obj.Id+'">' + createdInvoices.get(tr.obj.Id).Name + '</a>'+ tr.message;
        							result.addMessage(message,ApexPages.Severity.ERROR);
        						}
        					}
        				}
        				if(!setCreatedInvoices.isEmpty()){
        					result.success = true;
        					lstCreatedInvoices.addAll(setCreatedInvoices);
        				}else{
        					result.success = false;
        				}
        	    }
			}
			/*
			
			for(Id company : createdInvoicesByCompany.keySet()){
				if(service.taxServiceConfigured(company) == false){
					//tax service not configured for this company
					lstCreatedInvoices.addAll( createdInvoicesByCompany.get(company).values() );
				}else{
					map<Id,Customer_Invoice__c> createdInvoices = createdInvoicesByCompany.get(company);
					list<TaxService.TaxResult> taxResults = service.getTax(new List<Id>(createdInvoicesByCompany.get(company).keySet()));
					system.debug('**taxResults**'+taxResults);
        			if(!taxResults.isEmpty()){
        				set<Customer_Invoice__c> setCreatedInvoices = new set<Customer_Invoice__c>();
        				for(TaxService.TaxResult tr: taxResults){
        					if(tr.obj.Id != null){
        						if(tr.isSuccess){
        							setCreatedInvoices.add(createdInvoices.get(tr.obj.Id));
        						}else{
        							string message = '<a href="/'+tr.obj.Id+'">' + createdInvoices.get(tr.obj.Id).Name + '</a>'+ tr.message;
        							result.addMessage(message,ApexPages.Severity.ERROR);
        						}
        					}
        				}
        				if(!setCreatedInvoices.isEmpty()){
        					result.success = true;
        					lstCreatedInvoices.addAll(setCreatedInvoices);
        				}else{
        					result.success = false;
        				}
        			}
				}
			}*/

			System.debug(LoggingLevel.ERROR, '#### Results: ' + result);

				result.records = lstCreatedInvoices;

			return result;
		}catch(exception ex){
			result.success = false;
			result.addMessage(ex,ApexPages.Severity.ERROR);
			system.debug(logginglevel.error,'prefinalizeActions*'+ex.getMessage()+' '+ex.getStackTraceString());
			return result;
		}
	}
	
	@remoteAction
	public static JSONResult finalizeInvoices(Id recordId, boolean fromProcessFulFilment, list<Customer_Invoice__c> lstCI, string objName){
		JsonResult result = new JsonResult();
		
		if(!fromProcessFulFilment){ //bypassing this as the CI already has the SO/AGR/SH populated.
		for(Customer_Invoice__c ci : lstCI) {
			ci.Finalized__c = true;
			if(objName == 'Agreement__c') {
  				ci.Agreement__c = recordId;
  			}else if(objName == 'Shipment__c'){
  				ci.Shipment__c = recordId;
  			}else{
  				ci.Sales_Order__c = recordId;
  			}
	  	}
		}else{
		    for(Customer_Invoice__c ci : lstCI) {
                ci.Finalized__c = true;
		    }
		}  

	  	if(!lstCI.isEmpty()) {
	  		try{
	  			result.success = true;
            	DML.updateAsUser(lstCI);
				result.records = lstCI;
        	}catch(DMLexception dmlex){
        		for (Integer idx = 0; idx < dmlex.getNumDml() ; idx++) {
                    result.addMessage(dmlex.getDmlMessage(idx), ApexPages.Severity.ERROR);
                }
                result.success = false;
        	}
	  	}
	  	system.debug(logginglevel.error,'mInvoices '+lstCI);
	  	return result;
	}
	
	@remoteAction
	public static JSONResult autoApplyPrepayments(list<Customer_Invoice__c> lstCI){
		JsonResult result = new JsonResult();
		try{
			map<Id,Customer_Invoice__c> createdInvoices = new map<Id,Customer_Invoice__c>();
			if(!lstCI.isEmpty()){
				for(Customer_Invoice__c ci: lstCI){
					createdInvoices.put(ci.Id, ci);
				}
			}
			AutoApplyInvoiceService.autoApplyPrepayments(createdInvoices);
			for(Customer_Invoice__c ci : createdInvoices.values()) {
	  			String hyperlink = '<a href="/'+ci.Id+'">' + ci.Name + '</a>';
	  			result.addMessage(hyperlink +': '+ Label.has_been_created_and_finalized, ApexPages.Severity.CONFIRM);
	  			System.debug(logginglevel.error,hyperlink +':has been created and finalized.' );
	  		}
	        result.success = true;
		}catch(exception ex){
			result.success = false;
			result.addMessage(ex,ApexPages.Severity.ERROR);
			system.debug('autoApplyPrepayments*'+ex.getMessage()+' '+ex.getStackTraceString());
		}
		return result;
	}
	
	@remoteAction
	public static JSONResult callUserDefinedMethod(Process__c pRecord, List<SObject> scope){
		JsonResult result = new JsonResult(); 
		try{
			result.success = true;
			result.records = userDefinedMethod(pRecord, scope);
			if(!result.records.isEmpty()){
				result.success = true;
			}else{
				result.success = false;
			}
		}catch(exception ex){
			result.success = false;
			result.addMessage(ex, ApexPages.Severity.ERROR);
			system.debug('callUserDefinedMethods*'+ex.getMessage()+' '+ex.getStackTraceString());
		}
		return result;
	}
	
	public static list<object> userDefinedMethod(Process__c pRecord, List<SObject> scope){
		system.debug('userDefinedMethod*'+pRecord.Namespace__c);
		system.debug('userDefinedMethod*'+pRecord.Object_Step__c);
		list<object> lstCustomerInvoice = new list<object>();
		if(pRecord != null && pRecord.Active__c == true){
			Type t = Type.forName(pRecord.Namespace__c, pRecord.Object_Step__c);
			if(t != null){
				ICustomAction iCA= (ICustomAction)t.newInstance();
				lstCustomerInvoice = iCA.executeAction(scope);
			}else{
				throw new InvoiceException(Label.Class_not_found+ ' ' +pRecord.Object_Step__c);
			}
		}
		return lstCustomerInvoice;
	}
	
	@remoteAction
	public static JSONResult getValues(){
		JsonResult result = new JsonResult(); 
		try{
			list<Process__c> lstObjectStep = new list<Process__c>();
			lstObjectStep = getValuesFromProcessCustomSetting();
			result.records = lstObjectStep;
			system.debug(logginglevel.error,'getValues--->'+lstObjectStep+' '+result.records);
			if(!lstObjectStep.isEmpty()){
				result.success = true;
			}else{
				result.success = null;
			}
		}catch(exception ex){
			result.success = false;
			result.addMessage(ex, ApexPages.Severity.ERROR);
			system.debug(logginglevel.error,'getValues--->'+ex.getMessage()+' '+ex.getStackTraceString());
		}
		return result;
	}
	
	public static list<Process__c> getValuesFromProcessCustomSetting(){
		list<Process__c> lstObjectStep = new list<Process__c>();
		lstObjectStep = KSE.grep(Process__c.getAll().values(), 'Object__c',Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName());
		lstObjectStep = KSE.grep(lstObjectStep, 'Bulk__c',true);
		lstObjectStep = KSE.grep(lstObjectStep, 'Active__c',true);
		KSE.sortList(lstObjectStep, 'Sequence__c', 'asc' );		
		System.debug(logginglevel.error,'lstObjectStep--->'+lstObjectStep);
		return lstObjectStep;
	}
}