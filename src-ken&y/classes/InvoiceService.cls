public with sharing class InvoiceService {
	public static ExceptionService exService = new ExceptionService();
	public static final String INTERCO_INVEST = 'Intercompany Investment';
	public static final String INTERCO_CROSS = 'Intercompany Cross Charge';

	public InvoiceService() {
		
	}

	public static boolean validateAndUpsert(List<Invoice__c>invoices, List<Invoice_Line__c>invoiceLines, JSONResult result, Boolean skipQuery){
		Set<Id>invoiceIds = new Set<Id>();

		for(Invoice__c inv : invoices){
			invoiceIds.add(inv.Id);

			if(INTERCO_INVEST.equalsIgnoreCase(inv.Type__c)){
				inspectIntercoInvestment(inv, invoiceLines, result);
			}else if(INTERCO_CROSS.equalsIgnoreCase(inv.Type__c)){
				inspectIntercoCross(inv, invoiceLines, result);
			}
		}

		exService.newExceptionsAlreadyOverridden(invoiceIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});

		exService.finishTasks(true);

		System.debug(LoggingLevel.INFO, '#### Num Messages: ' + result.messages.size() );

		if(result.messages.size() > 0){
			return false;
		}else{
			return true;
		}
	}

	/* This method blocks the Invoices edit on a closed/approved ones if any payment is available,
	 similar to the way it behaves on the UI */
    public static void restrictEditOnApprovedClosedInvoices(){
        
        // Add the Object and its Payment Issue related fieldset to enhance this method for other Invoices/sObjects        
        Map<String,List<String>> objectAndPaymentFieldsetMap = new Map<String,List<String>>{'Supplier_Invoice__c' => new List<String>{'Payment_Issued'}};
        
        List<sObject> sObjRecs = new List<sObject>();
        Schema.sObjectType iSObjType = null;
        String sObjectName = null;
        String sObjectLabel = null;
        
        if(trigger.isBefore && trigger.isUpdate){
            
            sObjRecs = trigger.new;
            iSObjType = sObjRecs[0].getSObjectType();
            sObjectName = iSObjType.getDescribe().getLocalName();
            System.debug(logginglevel.error,'sObjectName-->'+sObjectName);
            sObjectLabel = iSObjType.getDescribe().getLabel();
            
        }else if(trigger.isBefore && trigger.isDelete){
            
            sObjRecs = trigger.old;
            iSObjType = sObjRecs[0].getSObjectType();
            sObjectName = iSObjType.getDescribe().getLocalName();
            System.debug(logginglevel.error,'sObjectName-->'+sObjectName);
            sObjectLabel = iSObjType.getDescribe().getLabel();
        }
        
        if(trigger.isBefore){
            for(integer i = 0; i< sObjRecs.size(); i++){
                
                if(trigger.isBefore && trigger.isDelete){
                    trigger.old[i].addError(Label.You_cannot_delete_an_invoice);
                }
                
                sObject sObj = sObjRecs[i];
                
                Boolean isFinalized = false;
                Boolean isApproved = false;
                Boolean isClosed = false;
                isFinalized = ((Boolean)sObj.get('Finalized__c') && (Boolean)trigger.old[i].get('Finalized__c')) ? true : false;
                isApproved = ((String)sObj.get('Status__c') == SupplierInvoiceService.STATUS_APPROVED && (String)trigger.old[i].get('Status__c') == SupplierInvoiceService.STATUS_APPROVED) ? true : false;
                isClosed = ((String)sObj.get('Status__c') == SupplierInvoiceService.STATUS_CLOSED && (String)trigger.old[i].get('Status__c') == SupplierInvoiceService.STATUS_CLOSED) ? true : false;
                
                List<String> tobeComparedFieldsetList = new List<String>();
                Boolean paymentsPresent = false;
                
                if(isFinalized && isApproved){
                     if(((String)sObj.get('Invoice_Type__c') == SupplierInvoiceService.invTypeInvoice || (String)sObj.get('Invoice_Type__c') == SupplierInvoiceService.invTypePrepymt)
                        && ((double)sObj.get('Invoice_Amount__c') != (double)sObj.get('Balance_Due__c'))){
                          if(objectAndPaymentFieldsetMap.containsKey(sObjectName)){
                             tobeComparedFieldsetList.addAll(objectAndPaymentFieldsetMap.get(sObjectName)); //the fieldset for payment issued added
                          }
                          paymentsPresent = true;
                          System.debug(logginglevel.error,'Inside the payments present section of invoice/prepayment');
                     }else if((String)sObj.get('Invoice_Type__c') == SupplierInvoiceService.invTypeCM && ((double)sObj.get('Credit_Memo_Amount__c') != (double)sObj.get('Credit_Memo_Balance__c'))){
                          if(objectAndPaymentFieldsetMap.containsKey(sObjectName)){
                             tobeComparedFieldsetList.addAll(objectAndPaymentFieldsetMap.get(sObjectName)); //the fieldset for payment issued added
                          }
                          paymentsPresent = true;
                          System.debug(logginglevel.error,'Inside the payments present section of creditmemo');
                     }
                }
                if(isFinalized && isClosed){
                    if(objectAndPaymentFieldsetMap.containsKey(sObjectName)){
                         tobeComparedFieldsetList.addAll(objectAndPaymentFieldsetMap.get(sObjectName)); //the fieldset for payment issued added
                    } 
                    paymentsPresent = true;
                }
                
                if(tobeComparedFieldsetList != null){
                    map<string, string> validateFields = sObjectValidateFields(iSObjType, tobeComparedFieldsetList);  
                    if(trigger.isBefore && trigger.isUpdate){
                        //The record exists and is being updated - make sure the vital fields aren't changing
                        for(string field : validateFields.keySet()){
                             System.debug(logginglevel.error,'field-->'+field);
                             System.debug(logginglevel.error,'new value-->'+trigger.new[i].get(field));
                             System.debug(logginglevel.error,'old value-->'+trigger.old[i].get(field));
                             
                            if(trigger.new[i].get(field) != trigger.old[i].get(field)){
                                if(paymentsPresent){
                                    //String messageStr = Label.You_cannot_change +' '+ '{!field}' +' '+ Label.on_a +' '+ sObjectLabel +' '+ Label.when_payment_has_been_issues;
                                    //messageStr = messageStr.replace('{!field}',field);
                                    trigger.new[i].addError(Label.You_cannot_change +' '+ field +' '+ Label.on_a +' '+ sObjectLabel +' '+ Label.when_payment_has_been_issues);
                                }  
                            }
                        }
                    }
                }
            }
        }
    }
    
    private static map<Schema.sObjectType, map<string, string>> mValidateFields = new map<Schema.sObjectType, map<string, string>>();  
    public static map<string, string> sObjectValidateFields(Schema.sObjectType sObjectType, List<String> fieldSetNames){
        map<string, string> mFieldLabel = new map<string, string>();
        if(mValidateFields.containsKey(sObjectType)){
            mFieldLabel = mValidateFields.get(sObjectType);
        }else{
            System.debug(logginglevel.error,'fieldSetNames-->'+fieldSetNames);
            for(String fieldSetString : fieldSetNames){
                for( Schema.FieldSetMember fsm : SchemaUtil.getInstance().getFieldsFromFieldSet(sObjectType, fieldSetString) ){  
                    mFieldLabel.put(fsm.getFieldPath(), fsm.getLabel());
                }
                mValidateFields.put(sObjectType, mFieldLabel);
                System.debug(logginglevel.error,'mValidateFields-->'+mValidateFields);
            }
        }
        return mFieldLabel; 
    }

	public static void invoiceChangedTrigger(List<Invoice__c>newIn, map<Id, Invoice__c>oldIn){

		List<Invoice__c>toChange = new List<Invoice__c>();
		List<Invoice__c>fromChange = new List<Invoice__c>();
		Set<Id> companyId = new Set<Id>();

		for(Invoice__c i : newIn){
			if(i.Id == null || oldIn.containsKey(i.Id) == false || oldIn.get(i.Id).Type__c != i.Type__c ){
				i.Transaction_Type__c = i.Type__c;
			}

			if(i.Id == null || oldIn.containsKey(i.Id) == false || oldIn.get(i.Id).To_Company__c != i.To_Company__c){
				toChange.add(i);
				companyId.add(i.To_Company__c);
			}

			if(i.Id == null || oldIn.containsKey(i.Id) == false || oldIn.get(i.Id).From_Company__c != i.From_Company__c){
				fromChange.add(i);
				companyId.add(i.From_Company__c);
			}
		}

		map<Id, Company__c>companies = new map<Id, Company__c>([Select Id, Street__c, City__c, State__c, Zip_Code__c, Country__c From Company__c Where Id in:companyId]);

		for(Invoice__c i : toChange){
			i.To_Street__c = companies.get(i.To_Company__c).Street__c;
			i.To_City__c =  companies.get(i.To_Company__c).City__c;
			i.To_State__c =  companies.get(i.To_Company__c).State__c;
			i.To_Zip_Code__c =  companies.get(i.To_Company__c).Zip_Code__c;
			i.To_Country__c =  companies.get(i.To_Company__c).Country__c;
		}

		for(Invoice__c i : fromChange){
			i.From_Street__c = companies.get(i.From_Company__c).Street__c;
			i.From_City__c =  companies.get(i.From_Company__c).City__c;
			i.From_State__c =  companies.get(i.From_Company__c).State__c;
			i.From_Zip_Code__c =  companies.get(i.From_Company__c).Zip_Code__c;
			i.From_Country__c =  companies.get(i.From_Company__c).Country__c;
		}
	}

	private static void inspectIntercoInvestment(Invoice__c inv, List<Invoice_Line__c> lines, JSONResult result){

		validateIntercompany(inv, result);

		if(lines != null && lines.size() > 0){
			//validate lines and insert
			Set<Id> lIds = new Set<Id>();
			for(Invoice_Line__c il : lines){
				if(il.Extended_Amount__c == null || il.Extended_Amount__c <= 0){
					exService.setException(il, ExceptionUtil.IL_INVALID_AMOUNT);
					addResult(result, ExceptionUtil.IL_INVALID_AMOUNT);
				}else{
					exService.clearException(il, ExceptionUtil.IL_INVALID_AMOUNT);
				}
				if(il.Id != null){
					lIds.add(il.Id);
				}
			}

			System.debug(LoggingLevel.INFO, '#### Line Ids: ' + lIds);
			exService.newExceptionsAlreadyOverridden(lIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});
		}

	}

	private static void inspectIntercoCross(Invoice__c inv, List<Invoice_Line__c> lines, JSONResult result){
		System.debug(LoggingLevel.INFO, '### Validating Cross: Num Lines: ' + lines.size());
		validateIntercompany(inv, result);

		if(lines != null && lines.size() > 0){
			//validate lines and insert
			Set<Id> lIds = new Set<Id>();
			for(Invoice_Line__c il : lines){
				System.debug(LoggingLevel.INFO, '### Line Price: ' + il.Extended_Amount__c + '\tGL: ' );
				if(il.Extended_Amount__c <= 0){
					exService.setException(il, ExceptionUtil.IL_INVALID_AMOUNT);
					addResult(result, ExceptionUtil.IL_INVALID_AMOUNT);
				}else{
					exService.clearException(il, ExceptionUtil.IL_INVALID_AMOUNT);
				}


				if(il.Accounting_Default__c != null){
					//clear all deafult exceptions
					exService.clearException(il, ExceptionUtil.IL_Accounting_Default_Required);
					exService.clearException(il, ExceptionUtil.IL_Accounting_Default_GLAccount_Required);
					exService.clearException(il, ExceptionUtil.IL_Accounting_Default_Company_Required);
					exService.clearException(il, ExceptionUtil.IL_Accounting_Default_Intercompany_Required);
				}else{
					if(il.Accounting_Default__r == null){
						exService.setException(il, ExceptionUtil.IL_Accounting_Default_Required);
						addResult(result, ExceptionUtil.IL_Accounting_Default_Required);
					}else{
						//clear ad required excption
						exService.clearException(il, ExceptionUtil.IL_Accounting_Default_Required);
					}

					if(il.Accounting_Default__r.GL_Account__c == null){
						exService.setException(il, ExceptionUtil.IL_Accounting_Default_GLAccount_Required);
						addResult(result, ExceptionUtil.IL_Accounting_Default_GLAccount_Required);
					}else{
						//clear ad required excption
						exService.clearException(il, ExceptionUtil.IL_Accounting_Default_GLAccount_Required);
					}

					if(il.Accounting_Default__r.Company__c == null){
						//company required
						exService.setException(il, ExceptionUtil.IL_Accounting_Default_Company_Required);
						addResult(result, ExceptionUtil.IL_Accounting_Default_Company_Required);
					}else if(il.Accounting_Default__r.Company__c != inv.From_Company__c){
						//company doesn't match
						exService.setException(il, ExceptionUtil.IL_Accounting_Default_Company_Required);
						addResult(result, ExceptionUtil.IL_Accounting_Default_Company_Required);
					}else{
						//clear company exception
						exService.clearException(il, ExceptionUtil.IL_Accounting_Default_Company_Required);
					}

					if(il.Accounting_Default__r.Intercompany__c == null){
						//intercompany required
						exService.setException(il, ExceptionUtil.IL_Accounting_Default_Intercompany_Required);
						addResult(result, ExceptionUtil.IL_Accounting_Default_Intercompany_Required);
					}else if(il.Accounting_Default__r.Intercompany__c != inv.To_Company__c){
						//intercompany doesn't match
						exService.setException(il, ExceptionUtil.IL_Accounting_Default_Intercompany_Required);
						addResult(result, ExceptionUtil.IL_Accounting_Default_Intercompany_Required);
					}else{
						//clear company exception
						exService.clearException(il, ExceptionUtil.IL_Accounting_Default_Intercompany_Required);
					}

				}

				if(il.Id != null){
					lIds.add(il.Id);
				}
			}

			System.debug(LoggingLevel.INFO, '#### Line Ids: ' + lIds);
			exService.newExceptionsAlreadyOverridden(lIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});
		}
	}

	private static void validateIntercompany(Invoice__c inv, JSONResult result){

		if(inv.To_Company__c == null){
			exService.setException(inv, ExceptionUtil.I_MISSING_TO_COMPANY);
			addResult(result, ExceptionUtil.I_MISSING_TO_COMPANY);
		}else{
			exService.clearException(inv, ExceptionUtil.I_MISSING_TO_COMPANY);
		}

		if(inv.From_Company__c == null){
			exService.setException(inv, ExceptionUtil.I_MISSING_FROM_COMPANY);
			addResult(result, ExceptionUtil.I_MISSING_FROM_COMPANY);
		}else{
			exService.clearException(inv, ExceptionUtil.I_MISSING_FROM_COMPANY);
		}
	}


	private static void addResult(JSONResult result, TaskType tt){
		if(result != null){
			result.addMessage(tt.description, ApexPages.Severity.ERROR);
		}
	}
}