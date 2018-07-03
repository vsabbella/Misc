public with sharing class BankReconciliationService {
		
		public static SchemaUtil util = SchemaUtil.getInstance();
		public class BankReconciliationServiceException extends Exception{}
       
       /*----------QUERIES FOR RECONCILIATION SUMMARY REPORT!!-------------*/
       /*
       this will return all bank transactions tied to a bank account and TD less than/equal to specified time. 
       */
       public static string getBankTransactionsWhereClause(DateTime endDateTime, Id bankAccountId, Id companyId,Datetime opBalDateTime) {
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
            String sopBalDateTime =util.formatDateTimeForSOQL(opBalDateTime);
       		String sBankAccountId = '\''+bankAccountId+'\'';
       		whereClause = 'Bank_Account__c = '+sBankAccountId+'  and Reconciled_As_Of_Date__c = null and Finalized__c = true and Bank_Transaction_Group__r.Void__c = false and Transaction_Date__c > '+sopBalDateTime +'and Transaction_Date__c < '+sEndDatetime; //sEndDatetime is date+ day at 12:am
       		return whereClause;
       }
       
       public static list<String> getBankTransactionsFields() {
       		return new list<String>{'Id','Name','Bank_Transaction_Group__c','Transaction_Date__c','Match_Approved__c','Finalized__c','Amount__c','Bank_Account__c','Bank_Account__r.GL_Account__c','Reference_Number__c','Transacted_With__c','Transacted_With_Description__c','Transaction_Type__c'};
       }
       
       /*
       This where clause is to query all bank transactions that are not finalized (which implies invalid or incomplete matching) and is not reconciled (implies empty reconciliation date) for a specific bank account and up to a specific dateTime. 
       */
       public static string getReconciledTransactionsWhereClause(DateTime endDateTime, Id bankAccountId, Id companyId,DateTime opBalDateTime) {
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
           String sopBalDateTime = util.formatDateTimeForSOQL(opBalDateTime);
           
       		String sBankAccountId = '\''+bankAccountId+'\'';
       		whereClause = 'Bank_Account__c = '+sBankAccountId+' and Finalized__c = true and Match_Approved__c = true and Bank_Transaction_Group__r.Void__c = false and Reconciled_As_Of_Date__c != null and Transaction_Date__c > '+sopBalDateTime +'  and Transaction_Date__c < '+sEndDatetime;//sEndDatetime is date+ day at 12:am
       		return whereClause;
       }
       
       /*
       This where clause is to query all bank transactions up to a specific dateTime. 
       */
       public static string getAllBankTransactionsWhereClause(DateTime endDateTime, Id bankAccountId, Id companyId,Datetime opbalDatetime) {
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
           String sopbalDatetime = util.formatDateTimeForSOQL(opbalDatetime);
           
       		String sBankAccountId = '\''+bankAccountId+'\'';
       		whereClause = 'Bank_Account__c = '+sBankAccountId+' and Finalized__c = true and Bank_Transaction_Group__r.Void__c = false and Transaction_Date__c  > ' + sopbalDatetime +' and Transaction_Date__c < '+sEndDatetime;//sEndDatetime is date+ day at 12:am
       		return whereClause;
       }
       
       public static list<String> getReconciledTransactionsFields() {
       		return new list<String>{'Id','Name','Bank_Transaction_Group__c','Transaction_Date__c','Match_Approved__c','Finalized__c','Amount__c','Bank_Account__c','Bank_Account__r.GL_Account__c'};
       }
       
       /*
       CR in transit 
       This query will give us All CR that are finalized, has  active accounting entry and no relationship to BTM
       */
       public static string getCustomerReceiptsInTransitWhereClause(DateTime endDateTime, Id bankAccountId, Id companyId,DateTime ReconStartDate) {
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
           String sReconStartDate =  util.formatDateTimeForSOQL(ReconStartDate); 
       		String sBankAccountId = '\''+bankAccountId+'\'';
       		whereClause = 'Bank_Account_2__c = '+sBankAccountId+' and Finalized__c = true and Void__c = false and Amount_Received__c != 0 and Has_Exceptions__c = false and Transaction_Date__c < '+sEndDatetime+ //CR that are finalized, //sEndDatetime is date+ day at 12:am
       					  ' and  Transaction_date__c > '+ sReconStartDate +' and Id in (Select Customer_Receipt__c from Accounting_Entry__c where Status__c=\'Active\' and Has_Exceptions__c = false) '+ //active accounting
       					  ' and Id not in (Select Customer_Receipt__c from Bank_Transaction_Match__c where Bank_Transaction__r.Match_Approved__c = true  and Bank_Transaction__r.Transaction_Date__c < '+sEndDatetime+')'; //no relationship to BTM
       		return whereClause;
       		
       }
       public static list<String> getCustomerReceiptsInTransitFields() {
       		return new list<String>{'Id','Name','Transaction_Date__c','Finalized__c','Amount_Received__c','Bank_Account_2__c','Bank_Account_2__r.GL_Account__c','Customer__c','Customer__r.Name','Reference_Number__c', 'Currency__c','Currency__r.ISO_Code__c','Payment_Method_G__c'};
       }
       
       /*
       SP in transit 
       This query will give us All CR that are finalized, has  active accounting entry and no relationship to BTM
       */
       public static string getSupplierPaymentsInTransitWhereClause(DateTime endDateTime, Id bankAccountId, Id companyId, DateTime ReconStartDate) {
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
            String sReconStartDate =  util.formatDateTimeForSOQL(ReconStartDate); 
       		String sBankAccountId = '\''+bankAccountId+'\'';
       		whereClause = 'Bank_Account__c = '+sBankAccountId+' and Finalized__c = true and Payment_Amount__c > 0 and  Void__c = false and Transaction_Date__c < '+sEndDatetime+ //SP that are finalized, //sEndDatetime is date+ day at 12:am
       					  ' and  Transaction_date__c > '+ sReconStartDate +' and Id in (Select Supplier_Payment__c from Accounting_Entry__c where Status__c=\'Active\' and Has_Exceptions__c = false) '+ //active accounting
       					  ' and Id not in (Select Supplier_Payment__c from Bank_Transaction_Match__c where Bank_Transaction__r.Match_Approved__c = true and Bank_Transaction__r.Transaction_Date__c < '+sEndDatetime+')'; //no relationship to BTM
       		return whereClause;
       }
       
       public static list<String> getSupplierPaymentsInTransitFields() {
		   return new list<String>{'Id','Name','Transaction_Date__c','Finalized__c','Payment_Amount__c','Bank_Account__c','Bank_Account__r.GL_Account__c','Supplier__c','Supplier__r.Name','Reference__c', 'Currency__c','Currency__r.ISO_Code__c','Payment_Method_G__c'};
       }
       
       /*
       JELs in transit
       
       */
        public static string getJournalEntryLinesInTransitWhereClause(DateTime endDateTime, Id bankAccountId, Id companyId,Datetime ReconStartDate) {
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
            String sReconStartDate =  util.formatDateTimeForSOQL(ReconStartDate); 
       		String sBankAccountId = '\''+bankAccountId+'\'';
			String sCompanyId = '\''+companyId+'\'';
       		whereClause = 'Bank_Account__c = '+sBankAccountId+' and Journal_Entry__r.Company__c = '+sCompanyId+' and Journal_Entry__r.Transaction_Date__c < '+sEndDatetime+
                		  ' and Journal_Entry__r.Transaction_Date__c > '+sReconStartDate +' and Finalized__c = true and Journal_Entry__r.Void__c = false and Journal_Entry__r.Has_Exceptions__c = false '+//sEndDatetime is date+ day at 12:am
       					  ' AND ID in (Select Journal_Entry_Line__c from Accounting_Entry_Line__c where  Accounting_Entry__r.Status__c=\'Active\' and Accounting_Entry__r.Has_Exceptions__c = false) '+
       					  ' AND ID not in (Select Journal_Entry_Line__c from Bank_Transaction_Match__c where Bank_Transaction__r.Match_Approved__c = true and Bank_Transaction__r.Transaction_Date__c < '+sEndDatetime+')';
       		return whereClause;
       }
       
       public static list<String> getJournalEntryLinesInTransitFields() {
       		return new list<String> {'Id','Name','Journal_Entry__r.Transaction_Date__c','Journal_Entry__r.Finalized__c','Amount_CR__c','Amount_DR__c','GL_Account__c','GL_Account__r.Name','Description__c','Journal_Entry__r.Auto_Reverse__c', 'Journal_Entry__r.Currency__c','Journal_Entry__r.Currency__r.ISO_Code__c'};
       }

	/*
	* INTERCO in Transit*/
	public static string getIntercoReceiptsInTransit(DateTime endDateTime, Id bankAccountId, Id companyId, DateTime ReconStartDate) {
		String whereClause = '';
		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
		String sReconStartDate =  util.formatDateTimeForSOQL(ReconStartDate);
		String sBankAccountId = '\''+bankAccountId+'\'';
		String sCompanyId = '\''+companyId+'\'';

		whereClause = 'To_Bank_Account__c = '+sBankAccountId+' and To_Company__c = '+sCompanyId+' and Finalized__c = true and Payment_amount__c > 0  and Transaction_Date__c < '+sEndDatetime+ //SP that are finalized, //sEndDatetime is date+ day at 12:am
				' and  Transaction_date__c > '+ sReconStartDate +' and Id in (Select Payment__c from Accounting_Entry__c where Status__c=\'Active\' and Has_Exceptions__c = false and Company__c = '+sCompanyId+') '+ //active accounting
				' and Id not in (Select Payment__c from Bank_Transaction_Match__c where Bank_Transaction__r.Match_Approved__c = true and Bank_Transaction__r.Transaction_Date__c < '+sEndDatetime+')'; //no relationship to BTM

		return whereClause;

	}  //

	public static string getIntercoPaymentsInTransit(DateTime endDateTime, Id bankAccountId, Id companyId, DateTime ReconStartDate) {
		String whereClause = '';
		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
		String sReconStartDate =  util.formatDateTimeForSOQL(ReconStartDate);
		String sBankAccountId = '\''+bankAccountId+'\'';
		String sCompanyId = '\''+companyId+'\'';

		whereClause = 'From_Bank_Account__c = '+sBankAccountId+' and From_Company__c = '+sCompanyId+' and Finalized__c = true and Payment_amount__c > 0  and Transaction_Date__c < '+sEndDatetime+ //SP that are finalized, //sEndDatetime is date+ day at 12:am
				' and  Transaction_date__c > '+ sReconStartDate +' and Id in (Select Payment__c from Accounting_Entry__c where Status__c=\'Active\' and Has_Exceptions__c = false and Company__c = '+sCompanyId+') '+ //active accounting
				' and Id not in (Select Payment__c from Bank_Transaction_Match__c where Bank_Transaction__r.Match_Approved__c = true and Bank_Transaction__r.Transaction_Date__c < '+sEndDatetime+')'; //no relationship to BTM

		return whereClause;

	}

	public static list<String> getIntercoInTransitFields() {

		return new list<String>{'Id','Name','Transaction_Date__c','Finalized__c','Payment_Amount__c','From_Bank_Account__c','To_Bank_Account__c','From_Company__r.Name','To_Company__r.Name','Reference_Number__c', 'Currency__c','Currency__r.ISO_Code__c'};
	}
       
       /*
       Current GL balance
       consider all AEL that are active and have no exceptions whose transaction date is less than specified arg.
       */
       public static string getCurrentGLBalanceWhereClause(DateTime endDateTime, ID glAccountId, Id companyID) { //TODO send Company ID as well and filter on it.
       		String whereClause = '';
       		String sEndDatetime = util.formatDateTimeForSOQL(endDateTime);
       		String sGLAccountId = '\''+glAccountId+'\'';
       		String sCompanyId = '\''+companyID+'\'';
       		whereClause = ' GL_Account__c ='+sGLAccountId+' and Accounting_Entry__r.Company__c = '+sCompanyId+' and Accounting_Entry__r.Transaction_Date__c < '+sEndDatetime+' and Accounting_Entry__r.Status__c=\'Active\' and Has_Exceptions__c = false';//sEndDatetime is date+ day at 12:am
       		return whereClause;
       }
       
       public static list<String> getCurrentGLBalanceFields() {
       		return new list<String>{'Id','Name','Amount_CR__c','Amount_DR__c','GL_Account__c','GL_Account__r.Name','Source_ID__c','Source_Name__c','Accounting_Entry__r.Transaction_Date__c','SubTransaction_Type__c'};
       }
       
       /*----------UPDATING BANK TRANSACTIONS WITH RECONCILIATION DATE!!!!-------------*/
       public  static string getReconcileWhereClause(DateTime endDate, Id bankAccountId)  {
       	 	return 'Finalized__c = true and Reconciled_As_Of_Date__c = null and Transaction_Date__c < :endDate and Bank_Account__c = :bankAccountId';//sEndDatetime is date+ day at 12:am
       }
       
       public static Bank_Transaction__c setForReconciliation(Id bankTransactionId, dateTime reconcileDate) {
       		return new Bank_Transaction__c(Id = bankTransactionId, Reconciled_As_Of_Date__c = reconcileDate, Reconciled_Hidden__c = true);
       }
       
       public static void updateBankTransactionsAsReconciled(list<String>  lBTs, DateTime endDate, Id bankAccountId) {
       		list<Bank_Transaction__c> lBT2Update = new list<Bank_Transaction__c>();
       		/*if(lBTs == null || lBTs.isEmpty()) {
       			lBTs = Database.query('Select Id from bank_Transaction__c where '+ getReconcileWhereClause(endDate, bankAccountId) + ' FOR UPDATE');
       			}*/
       			
       			try {
       			//	String query = util.generateQueryFromFieldSet('Bank_Transaction__c', new set<String>{}, new set<String>{'Id'}, getReconcileWhereClause(endDate, bankAccountId)+' FOR UPDATE');
       				for(String btiD : lBTs) {
       				lBT2Update.add(setForReconciliation(btiD, endDate));
	       			}
       			if(!lBT2Update.isEmpty()) 
       				update lBT2Update;
       			}catch(exception ex) {
       				system.debug(logginglevel.error, 'bank rec  service real time reconcile '+ ex.getMessage() + ' ' +  ex.getStackTraceString());
       				throw new BankReconciliationServiceException(ex);
       			}
       }
       
       /*----------UN-RECONCILE BANK TRANSACTIONS!!!!-------------*/
       public static DateTime getLastReconciledDate(Id bankAccountId) {
       		try {
       			Bank_Transaction__c bt = [Select Reconciled_As_Of_Date__c from Bank_Transaction__c where Finalized__c = true and Reconciled_As_Of_Date__c != null and Bank_Account__c = :bankAccountId Order BY Reconciled_As_Of_Date__c desc limit 1];
       			return bt.Reconciled_As_Of_Date__c;
       		}catch(Exception ex) {
       			system.debug('LastReconciledDate ex: '+ ex.getMessage() + ' ' +  ex.getStackTraceString()+' so return null');
       			//throw new BankReconciliationServiceException(ex);
       			return null;
       		}
       }
       
       public static void unReconcileBankTransactions(list<Bank_Transaction__c> lBTs, Date reconciledDate, Id bankAccountId) {
       		DateTime startRange = dateTime.newInstance(reconciledDate, Time.newInstance(0,0,0,0));
       		DateTime endRange = startRange.addDays(1);
       		list<Bank_Transaction__c> lBT2Update = new list<Bank_Transaction__c>();
       		list<Bank_Transaction_Match__c> lstBankTransactionMatch = new list<Bank_Transaction_Match__c>();
       		if(lBTs == null || lBTs.isEmpty()) {
       			lBTs = [Select Id, Match_Approved__c from Bank_Transaction__c  where Match_Approved__c = true and Finalized__c = true and Reconciled_As_Of_Date__c >= :startRange and Reconciled_As_Of_Date__c < :endRange and Bank_Account__c = :bankAccountId FOR UPDATE];
       			}
       			try {
   				for(Bank_Transaction__c bt : lBTs) {
       				lBT2Update.add(new Bank_Transaction__c(Id = bt.Id, Reconciled_As_Of_Date__c = null, Reconciled_Hidden__c = false));
	       			}
       			if(!lBT2Update.isEmpty()) 				 			      
       				DML.updateAsUser(lBT2Update);
       			}catch(exception ex) {
       				system.debug(logginglevel.error, 'bank rec  service real time un-reconcile '+ ex.getMessage() + ' ' +  ex.getStackTraceString());
       				throw new BankReconciliationServiceException(ex);
       			}
       		}	
       		
       
         
}