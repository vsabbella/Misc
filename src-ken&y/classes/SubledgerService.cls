public with sharing class SubledgerService {
    
    public enum Subledger { AR, AP, SHIPMENT, RECEIVING, FA, INVENTORY, PERIOD, INTERCOMPANY } 
    
/*    public static map<Subledger, string> mSubledgerCloseBatches = new Map<Subledger, string>{ 
        Subledger.AR => 'ARSubledgerCloseBatch',
        Subledger.AP => 'APSubledgerCloseBatch',
        Subledger.SHIPMENT => 'ShipmentSubledgerCloseBatch',
        Subledger.RECEIVING => 'ReceivingSubledgerCloseBatch',
        Subledger.INVENTORY => 'InventorySubledgerCloseBatch',
        Subledger.FA => 'FASubledgerCloseBatch',
        Subledger.PERIOD => 'JESubledgerCloseBatch'
    };
   /* 
    public static map<Subledger, List<String>> mSubledgerAccounting = new Map<Subledger, List<String>>{
        Subledger.AR => new List<String>{'CustomerInvoiceAccounting', 'CustomerReceiptAccounting', 'BankFileAccounting'},
        Subledger.AP =>  new List<String>{'SupplierInvoiceAccounting', 'SupplierPaymentAccounting', 'PurchaseOrderAccounting'},
        Subledger.SHIPMENT => new List<String>{'ShipmentAccounting'},
        Subledger.RECEIVING => new List<String>{'ReceivingDocumentAccounting'},
        Subledger.INVENTORY => new List<String>{'WorkOrderAccounting', 'InventoryChangeAccounting'},
        Subledger.FA => new List<String>{'AccountingProcessFixedAssetAdjustments', 'AccountingProcessFixedAssetDepreciation'}
    };
    */
    //KNDY-10268 - deprecating bank file and bank file line objects
    public static map<Subledger, List<String>> mSubledgerObjects = new Map<Subledger, List<String>>{
        Subledger.AR => new List<String>{'Customer_Invoice__c', 'Customer_Receipt__c'}, //, 'Bank_File__c'
        Subledger.AP =>  new List<String>{'Supplier_Invoice__c', 'Supplier_Payment__c', 'Purchase_Order__c'},
        Subledger.SHIPMENT => new List<String>{'Shipment__c'},
        Subledger.RECEIVING => new List<String>{'Receiving_Document__c'},
        Subledger.INVENTORY => new List<String>{'Work_Order__c', 'Inventory_Change__c'},
        Subledger.FA => new List<String>{'Fixed_Asset_Depreciation__c', 'Fixed_Asset_Adjustment__c'},
        Subledger.INTERCOMPANY => new List<String>{'payment__c', 'Invoice__c'},
        Subledger.PERIOD => new List<String>{'Journal_Entry__c'}
    };
    
    public static map<Subledger, String> mSubledgerJobs = new Map<Subledger, String>{
        Subledger.AR => 'AR_Subledger_Job__c',
        Subledger.AP => 'AP_Subledger_Job__c',
        Subledger.SHIPMENT => 'Shipment_Subledger_Job__c',
        Subledger.RECEIVING => 'Receiving_Subledger_Job__c',
        Subledger.INVENTORY => 'Inventory_Subledger_Job__c',
        Subledger.FA => 'FA_Subledger_Job__c',
        Subledger.PERIOD => 'JE_Subledger_Job__c'
    };
    
    public static boolean isOpenForValidation(Subledger requestedSubledger, Period__c period, Id jobId, boolean isValidateOnly){
        
        boolean isAbleToValidate = false;
        /*string subledgerJobName = mSubledgerCloseBatches.get(requestedSubledger);
        string subledgerJobId = (string)period.get(mSubledgerJobs.get(requestedSubledger));
        /*string jobQuery = 'SELECT Id, Status, ApexClassId, ApexClass.Name '
                            + 'FROM AsyncApexJob '
                            + 'WHERE ApexClass.Name = :subledgerJobName '
                            + 'AND Status IN (\'Queued\',\'Preparing\',\'Processing\',\'Holding\') '
                            + 'AND (Id != :jobId )'; //OR Id = :subledgerJobId)';
        *//*
        String whereClause = 'ApexClass.Name = :subledgerJobName '
                            	+ 'AND Status IN (\'Queued\',\'Preparing\',\'Processing\',\'Holding\') '
                            	+ 'AND (Id != :jobId )';
        
	    SOQLUtil soql = new SOQLUtil('AsyncApexJob');
	    soql.addFields(new Set<String>{'Id', 'Status', 'ApexClassId', 'ApexClass.Name'});
	    soql.setWhereClause(whereClause);
	                        
        List<AsyncApexJob> jobs = Database.query(soql.getQuery());
        if(jobs.size() > 0 ){
            system.debug(logginglevel.info,'jobs: ' + jobs);
            isAbleToValidate = false;
        }
        system.debug(logginglevel.info,'period: ' + period);
        if (isValidateOnly == false){
        	List<sObject> sObjRecs = returnOpenSourceDocs(requestedSubledger, period);
        	system.debug(logginglevel.info,'open sObjRecs: ' + sObjRecs);
        	if(sObjRecs.size() > 0){
            	isAbleToValidate = false;
        	}
        }
        
        system.debug(logginglevel.info,'isAbleToValidate: ' + isAbleToValidate);*/
        return isAbleToValidate;
    }
    
    public static List<sObject> returnOpenSourceDocs(Subledger requestedSubledger, Period__c period){
        if(requestedSubledger == Subledger.AR){
            return returnOpenARSourceDocs(period);
        }else if(requestedSubledger == Subledger.AP){
            return returnOpenAPSourceDocs(period);
        }else if(requestedSubledger == Subledger.SHIPMENT){
            return returnOpenShipmentSourceDocs(period);
        }else if(requestedSubledger == Subledger.RECEIVING){
            return returnOpenReceivingSourceDocs(period);
        }else if(requestedSubledger == Subledger.FA){
            return returnOpenFASourceDocs(period);
        }else if(requestedSubledger == Subledger.INVENTORY){
            return returnOpenInventorySourceDocs(period);
        }else if(requestedSubledger == Subledger.INTERCOMPANY){
            return returnOpenInterCompanySourceDocs(period);
        }else if(requestedSubledger == Subledger.PERIOD){
            return returnOpenPeriodSourceDocs(period);
        }else{
            return new List<sObject>();
        }
    }
    
    public static boolean checkOpenSourceDocs(Subledger requestedSubledger, Period__c period){
        if(requestedSubledger == Subledger.AR){
            return checkOpenARSourceDocs(period);
        }else if(requestedSubledger == Subledger.AP){
            return checkOpenAPSourceDocs(period);
        }else if(requestedSubledger == Subledger.SHIPMENT){
            return checkOpenShipmentSourceDocs(period);
        }else if(requestedSubledger == Subledger.RECEIVING){
            return checkOpenReceivingSourceDocs(period);
        }else if(requestedSubledger == Subledger.FA){
            return checkOpenFASourceDocs(period);
        }else if(requestedSubledger == Subledger.INVENTORY){
            return checkOpenInventorySourceDocs(period);
        }else if(requestedSubledger == Subledger.INTERCOMPANY){
            return checkOpenInterCompanySourceDocs(period);
        }else if(requestedSubledger == Subledger.PERIOD){
            return checkOpenPeriodSourceDocs(period);
        }else{
            return false;
        }
    }
    //TODO:This method is not used.Needs to be removed.
    private static List<sObject> returnOpenARSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.ar_subledger_cutoff__c;
        List<sObject> custInvs = [SELECT Id, name, finalized__c
                                                FROM Customer_Invoice__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Customer_Invoice__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(custInvs);
        
        List<sObject> custRcpts = [SELECT Id, name, finalized__c
                                                FROM Customer_Receipt__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Customer_Receipt__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(custRcpts);
        //KNDY-10268 - deprecating bank file and bank file line objects
        /*List<sObject> bankFiles = [SELECT Id, name, finalized__c
                                                FROM Bank_File__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Bank_File__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(bankFiles);*/
        return sObjRecs;
    }
    
    private static boolean checkOpenARSourceDocs(Period__c period){
    	
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.ar_subledger_cutoff__c;
        List<sObject> custInvs = [SELECT Id, name, finalized__c
                                                FROM Customer_Invoice__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Customer_Invoice__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(custInvs);
        
        List<sObject> custRcpts = [SELECT Id, name, finalized__c
                                                FROM Customer_Receipt__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Customer_Receipt__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(custRcpts);
        //KNDY-10268 - deprecating bank file and bank file line objects
        /*List<sObject> bankFiles = [SELECT Id, name, finalized__c
                                                FROM Bank_File__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Bank_File__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(bankFiles);*/
        List<sObject> BankTransactionGroups = [SELECT Id, name, finalized__c
                                                FROM Bank_Transaction_Group__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ar_subledger_cutoff__c OR Finalized_Date__c <= :period.ar_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Bank_Transaction_Group__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(BankTransactionGroups);
        return sObjRecs.size() > 0;
    }
    
    private static List<sObject> returnOpenAPSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.ap_subledger_cutoff__c;
        List<sObject> suppInvs = [SELECT Id, name, finalized__c
                                                FROM Supplier_Invoice__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ap_subledger_cutoff__c  OR Finalized_Date__c <= :period.ap_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Supplier_Invoice__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(suppInvs);
        
        List<sObject> suppPmts = [SELECT Id, name, finalized__c
                                                FROM Supplier_Payment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ap_subledger_cutoff__c  OR Finalized_Date__c <= :period.ap_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Supplier_Payment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(suppPmts);
        
/*        List<sObject> purchaseOrders = [SELECT Id, name, finalized__c
                                                FROM Purchase_Order__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ap_subledger_cutoff__c  OR Finalized_Date__c <= :period.ap_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Purchase_Order__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(purchaseOrders);
*/        return sObjRecs;
    }
    
    private static boolean checkOpenAPSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.ap_subledger_cutoff__c;
        List<sObject> suppInvs = [SELECT Id, name, finalized__c
                                                FROM Supplier_Invoice__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ap_subledger_cutoff__c  OR Finalized_Date__c <= :period.ap_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Supplier_Invoice__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(suppInvs);
        
        List<sObject> suppPmts = [SELECT Id, name, finalized__c
                                                FROM Supplier_Payment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ap_subledger_cutoff__c  OR Finalized_Date__c <= :period.ap_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Supplier_Payment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(suppPmts);
        //FIN-1094 Remove POs from financial close process.
        /*List<sObject> purchaseOrders = [SELECT Id, name, finalized__c
                                                FROM Purchase_Order__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                 AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.ap_subledger_cutoff__c  OR Finalized_Date__c <= :period.ap_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Purchase_Order__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(purchaseOrders);*/
        return sObjRecs.size() > 0;
    }
    
    private static List<sObject> returnOpenShipmentSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.shipment_subledger_cutoff__c;
        
        List<sObject> shipments = [SELECT Id, name, finalized__c
                                                FROM Shipment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.shipment_subledger_cutoff__c OR Finalized_Date__c <= :period.shipment_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Shipment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(shipments);
        return sObjRecs;
    }
    
    private static boolean checkOpenShipmentSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.shipment_subledger_cutoff__c;
        
        List<sObject> shipments = [SELECT Id, name, finalized__c
                                                FROM Shipment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.shipment_subledger_cutoff__c OR Finalized_Date__c <= :period.shipment_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Shipment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(shipments);
        return sObjRecs.size() > 0;
    }
    
    private static List<sObject> returnOpenReceivingSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.receiving_subledger_cutoff__c;
        List<sObject> recDocs = [SELECT Id, name, finalized__c
                                                FROM Receiving_Document__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.receiving_subledger_cutoff__c OR Finalized_Date__c <= :period.receiving_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(recDocs);
        return sObjRecs;
    }
    
    private static boolean checkOpenReceivingSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.receiving_subledger_cutoff__c;
        List<sObject> recDocs = [SELECT Id, name, finalized__c
                                                FROM Receiving_Document__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.receiving_subledger_cutoff__c OR Finalized_Date__c <= :period.receiving_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(recDocs);
        return sObjRecs.size() > 0;
    }
    
    private static List<sObject> returnOpenFASourceDocs(Period__c period){
    	//TODO: Apply filter for period start for FADs
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.fa_subledger_cutoff__c;
        List<sObject> faDeps = [SELECT Id, name, finalized__c
                                                FROM Fixed_Asset_Depreciation__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.fa_subledger_cutoff__c OR Finalized_Date__c <= :period.fa_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Fixed_Asset_Depreciation__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(faDeps);
        
        List<sObject> faAdjs = [SELECT Id, name, finalized__c
                                                FROM Fixed_Asset_Adjustment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.fa_subledger_cutoff__c OR Finalized_Date__c <= :period.fa_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Fixed_Asset_Adjustment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(faAdjs);
        return sObjRecs;
    }
    
    private static boolean checkOpenFASourceDocs(Period__c period){
    	//TODO: Apply filter for period start for FADs
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.fa_subledger_cutoff__c;
        List<sObject> faDeps = [SELECT Id, name, finalized__c
                                                FROM Fixed_Asset_Depreciation__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.fa_subledger_cutoff__c OR Finalized_Date__c <= :period.fa_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Fixed_Asset_Depreciation__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(faDeps);
        
        List<sObject> faAdjs = [SELECT Id, name, finalized__c
                                                FROM Fixed_Asset_Adjustment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.fa_subledger_cutoff__c OR Finalized_Date__c <= :period.fa_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Fixed_Asset_Adjustment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(faAdjs);
        return sObjRecs.size() > 0;
    }
    
    private static List<sObject> returnOpenInventorySourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.inventory_subledger_cutoff__c;
        List<sObject> workOrders = [SELECT Id, name, finalized__c
                                                FROM Work_Order__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.inventory_subledger_cutoff__c OR Finalized_Date__c <= :period.inventory_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Work_Order__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(workOrders);
        
        List<sObject> invChanges = [SELECT Id, name, finalized__c
                                                FROM Inventory_Change__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND  (Posting_Date__c <= :period.inventory_subledger_cutoff__c OR Finalized_Date__c <= :period.inventory_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(invChanges);
        return sObjRecs;
    }
    
    private static List<sObject> returnOpenInterCompanySourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.InterCompany_subledger_cutoff__c;
        List<sObject> Invoices = [SELECT Id, name, finalized__c
                                                FROM Invoice__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
 //                                               AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.InterCompany_subledger_cutoff__c OR Finalized_Date__c <= :period.InterCompany_subledger_cutoff__c)
                                                AND (from_Company__c = :period.Company__c OR to_Company__c = :period.Company__c)
                                                AND ID NOT IN (SELECT Invoice__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active' AND company__c =:period.Company__c)];
        sObjRecs.addAll(Invoices);
        
        List<sObject> Payments = [SELECT Id, name, finalized__c
                                                FROM Payment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
//                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND  (Posting_Date__c <= :period.InterCompany_subledger_cutoff__c OR Finalized_Date__c <= :period.InterCompany_subledger_cutoff__c)
                                                AND (from_Company__c = :period.Company__c OR to_Company__c = :period.Company__c)
                                                AND ID NOT IN (SELECT Payment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active' AND company__c =:period.Company__c)];
        sObjRecs.addAll(Payments);
        return sObjRecs;
    }
    
    private static boolean checkOpenInterCompanySourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.InterCompany_subledger_cutoff__c;
        List<sObject> Invoices = [SELECT Id, name, finalized__c
                                                FROM Invoice__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                //AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.InterCompany_subledger_cutoff__c OR Finalized_Date__c <= :period.InterCompany_subledger_cutoff__c)
                                                AND (from_Company__c = :period.Company__c OR to_Company__c = :period.Company__c)
                                                AND ID NOT IN (SELECT Invoice__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active' AND company__c =:period.Company__c)
                                                LIMIT 1];
        sObjRecs.addAll(Invoices);
        
        List<sObject> Payments = [SELECT Id, name, finalized__c
                                                FROM Payment__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                //AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND  (Posting_Date__c <= :period.inventory_subledger_cutoff__c OR Finalized_Date__c <= :period.inventory_subledger_cutoff__c)
                                                AND (from_Company__c = :period.Company__c OR to_Company__c = :period.Company__c)
                                                AND ID NOT IN (SELECT Payment__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active' AND company__c =:period.Company__c)
                                                LIMIT 1];
        sObjRecs.addAll(Payments);
        return sObjRecs.size() > 0;
    }
    
    private static boolean checkOpenInventorySourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.inventory_subledger_cutoff__c;
        List<sObject> workOrders = [SELECT Id, name, finalized__c
                                                FROM Work_Order__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND (Posting_Date__c <= :period.inventory_subledger_cutoff__c OR Finalized_Date__c <= :period.inventory_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Work_Order__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(workOrders);
        
        List<sObject> invChanges = [SELECT Id, name, finalized__c
                                                FROM Inventory_Change__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Historical__c != true
                                                //AND Transaction_Date__c >= :period.Period_Start__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND  (Posting_Date__c <= :period.inventory_subledger_cutoff__c OR Finalized_Date__c <= :period.inventory_subledger_cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(invChanges);
        return sObjRecs.size() > 0;
    }
    
    private static List<sObject> returnOpenPeriodSourceDocs(Period__c period){
        List<sObject> sObjRecs = new List<sObject>();
        
        List<sObject> journalEntries = [SELECT Id, name, finalized__c
                                                FROM Journal_Entry__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND Transaction_Date__c >= :period.Period_Start__c
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Journal_Entry__c FROM Accounting_Entry__c WHERE void__c = false AND Status__c = 'Active')];
        sObjRecs.addAll(journalEntries);
        system.debug(logginglevel.info,'sObjRecs:'+sObjRecs);
        /*List<sObject> manualAcctEntries = [SELECT Id, name
                                                FROM Accounting_Entry__c
                                                WHERE void__c = false 
                                                AND period__c = :period.Id
                                                AND has_exceptions__c = true
                                                AND Company__c = :period.Company__c
                                                AND source_document_object_name__c = 'Manual'];
        sObjRecs.addAll(manualAcctEntries);*/
        
        return sObjRecs;
    }
    
    private static boolean checkOpenPeriodSourceDocs(Period__c period){
        
        List<sObject> sObjRecs = new List<sObject>();
         Datetime priorPeriodSLC = period.prior_period__c == null ? period.period_start__c : period.prior_period__r.JE_Cutoff__c;
      
        List<sObject> journalEntries = [SELECT Id, name, finalized__c
                                                FROM Journal_Entry__c
                                                WHERE Finalized__c = true 
                                                AND Transaction_Date__c < :period.Period_End__c
                                                AND (Posting_Date__c > :priorPeriodSLC OR Finalized_Date__c > :priorPeriodSLC)
                                                AND  (Posting_Date__c <= :period.JE_Cutoff__c OR Finalized_Date__c <= :period.JE_Cutoff__c)
                                                AND Company__c = :period.Company__c
                                                AND ID NOT IN (SELECT Journal_Entry__c FROM Accounting_Entry__c WHERE void__c = false  AND Status__c = 'Active')
                                                LIMIT 1];
        sObjRecs.addAll(journalEntries);
        system.debug(logginglevel.info,'sObjRecs:'+sObjRecs);
        /*List<sObject> manualAcctEntries = [SELECT Id, name
                                                FROM Accounting_Entry__c
                                                WHERE void__c = false 
                                                AND period__c = :period.Id
                                                AND has_exceptions__c = true
                                                AND Company__c = :period.Company__c
                                                AND source_document_object_name__c = 'Manual'];
        sObjRecs.addAll(manualAcctEntries);*/
        
        return sObjRecs.size() > 0;
    }
}