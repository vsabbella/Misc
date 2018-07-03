public with sharing class BankTransactionMatchService {

	public enum CRType {RECEIPT, REFUND, BOTH}

	public class BankTransactionMatchServiceException extends Exception {
	}
	public static SchemaUtil util = SchemaUtil.getInstance();
	public static void updateBTMatchApproveFlag() {
		if (Trigger.isBefore && Trigger.isDelete) {
			updateBTMatchApproveFlag(Trigger.old);
		}
	}
    /*
    If match is deleted and:
    1. BT is not finalized -- > delete the match record
    2. BT is finalized --> delete the match record and unfinalize the BT(implies delete the BTG)
    3. BT is reconciled --? delete the match record and unfinalize the BT and Remove Reconcile Date reference
    */
	public static void updateBTMatchApproveFlag(list<Bank_Transaction_Match__c> lstBankTransactionMatch) {
		if (!lstBankTransactionMatch.isEmpty()) {
			list<Bank_Transaction_Match__c> lstQueriedBankTransactionMatch = [
					Select Id, Bank_Transaction__c,
							Bank_Transaction__r.Bank_Transaction_Group__c,
							Bank_Transaction__r.Match_Approved__c,
							Bank_Transaction__r.Reconciled_As_Of_Date__c
					from Bank_Transaction_Match__c
					where id in:lstBankTransactionMatch
			];
			if (!lstQueriedBankTransactionMatch.isEmpty()) {
				map<Id, Bank_Transaction__c> mapRecApprovedBTs = new map<Id, Bank_Transaction__c>();
				for (Bank_Transaction_Match__c bankTransactionMatch: lstQueriedBankTransactionMatch) {
					if (bankTransactionMatch.Bank_Transaction__r.Reconciled_As_Of_Date__c != null
							|| bankTransactionMatch.Bank_Transaction__r.Match_Approved__c) //implies its reconciled
						mapRecApprovedBTs.put(bankTransactionMatch.Bank_Transaction__c, new Bank_Transaction__c(Id = bankTransactionMatch.Bank_Transaction__c, Reconciled_As_Of_Date__c = null, Reconciled_Hidden__c = false,
								Match_Approved__c = false));
				}
				if (!mapRecApprovedBTs.isEmpty()) {
					DML.updateAsUser(mapRecApprovedBTs.values());
				}
			}
		}
	}


	public static void updateUniqueKey() {
		if ((Trigger.isInsert || Trigger.isUpdate) && trigger.isBefore) {
			for (Bank_Transaction_Match__c btm :(List<Bank_Transaction_Match__c>) trigger.new) {
				btm.Unique_Key__c = KSE.ifNull(btm.Bank_Transaction__c, '') + KSE.ifNull(btm.Customer_Receipt__c, '') + KSE.ifNull(btm.Journal_Entry_Line__c, '') + KSE.ifNull(btm.Payment__c, '') + KSE.ifNull(btm.Supplier_Payment__c, '')+ KSE.ifNull(btm.Bank_Transfer_Transaction__c, '');
			}
		}
	}
    /*---------Impact on Unfinalizing, Void, cancle of Source Docs-------------*/

	public static list<Bank_Transaction_Match__c> getMatches(String sObjectType, Id objectId) {
		//string whereClause = '(Bank_Transaction__r.Finalized__c = true OR Bank_Transaction__r.Reconciled_As_Of_Date__c != null)';
		String query = '';
		set<String> additionalFields = new set<String>{
				'Id', 'Bank_Transaction__r.Name', 'Bank_Transaction__r.Match_Approved__c', 'Bank_Transaction__r.Reconciled_As_Of_Date__c'
		};
		if (sObjectType == 'Journal_Entry_Line__c') {
			query = util.generateQueryFromFieldSet('Bank_Transaction_Match__c', new set<String>{
			}, additionalFields, 'Journal_Entry_Line__r.Journal_Entry__c = :objectId limit 50000');
		} else if (sObjectType == 'Customer_Receipt__c') {
			query = util.generateQueryFromFieldSet('Bank_Transaction_Match__c', new set<String>{
			}, additionalFields, 'Customer_Receipt__c = :objectId limit 50000');
		} else if (sObjectType == 'Supplier_Payment__c') {
			query = util.generateQueryFromFieldSet('Bank_Transaction_Match__c', new set<String>{
			}, additionalFields, 'Supplier_Payment__c = :objectId limit 50000');
		} else if (sObjectType == 'Payment__c') {
			query = util.generateQueryFromFieldSet('Bank_Transaction_Match__c', new set<String>{
			}, additionalFields, 'Payment__c = :objectId limit 50000');
		} else {
			throw new BankTransactionMatchServiceException('This sObject type is not supported ' + sObjectType);
		}

		return Database.query(query);
	}

	public static list<String> getMatchesErrors(String sObjectType, Id objectId) {
		return getMatchesErrors(null, sObjectType, objectId);

	}

	public static list<String> getMatchesErrors(list<Bank_Transaction_Match__c> lBTMs, String sObjectType, Id objectId) {
		if (lBTMs == null || lBTMs.isEmpty()) {
			lBTMs = getMatches(sObjectType, objectId);
		}
		list<String> lWarnings = new list<String>();
		set<String> btNamesApproved = new set<String>();
		set<String> btNamesApprovedAndReconciled = new set<String>();
		set<String> btNamesMatched = new set<String>();
		for (Bank_Transaction_Match__c btm : lBTMs) {

			if (btm.Bank_Transaction__r.Reconciled_As_Of_Date__c != null)
				btNamesApprovedAndReconciled.add(btm.Bank_Transaction__r.Name); else if (btm.Bank_Transaction__r.Match_Approved__c)
				btNamesApproved.add(btm.Bank_Transaction__r.Name); else
					btNamesMatched.add(btm.Bank_Transaction__r.Name);
		}
		if (!btNamesApprovedAndReconciled.isEmpty()) {
			lWarnings.add(Label.transaction_has_been_reconciled + ' : ' + String.join(new list<String>(btNamesApprovedAndReconciled), ','));
		}
		if (!btNamesApproved.isEmpty()) {
			lWarnings.add(Label.Existing_approved_matches_will_be_deleted + ' : ' + String.join(new list<String>(btNamesApproved), ','));
		}
		if (!btNamesMatched.isEmpty()) {
			lWarnings.add(Label.Existing_matches_will_be_deleted + ' : ' + String.join(new list<String>(btNamesMatched), ','));
		}
		return lWarnings;
	}
   
	/*----------QUERIES FOR MATCHING!!-------------*/

	public static list<MatchingWrapper> filterSearchRecordForFindLookup(Id bankTransactionID, list<MatchingWrapper> lstSourceDocs) {
		set<id> setCRId = new set<id>();
		set<id> setSPId = new set<id>();
		set<id> setJELId = new set<id>();
		set<id> setPaymentsId = new set<id>();
		list<MatchingWrapper> lstSourceDocstoReturn = new list<MatchingWrapper>();
		if (!lstSourceDocs.isEmpty()) {
			list<Bank_Transaction_Match__c> lstBTM = new list<Bank_Transaction_Match__c>();
			for (MatchingWrapper record: lstSourceDocs) {
				if (record.objectType == 'Customer_Receipt__c') {
					setCRId.add(record.recordId);
				} else if (record.objectType == 'Payment__c') {
					setPaymentsId.add(record.recordId);
				} else if (record.objectType == 'Supplier_Payment__c') {
					setSPId.add(record.recordId);
				} else {
					if (record.objectType == 'Journal_Entry_Line__c') {
						setJELId.add(record.recordId);
					}
				}
			}
			SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c');
			soql.addFields(new set<string>{
					'Id', 'Customer_Receipt__c', 'Payment__c', 'Supplier_Payment__c', 'Journal_Entry_Line__c'
			});
			list<string> lstCondition = new list<string>();
			if (!setCRId.isEmpty()) {
				lstCondition.add('Customer_Receipt__c in :setCRId');
			}
			if (!setPaymentsId.isEmpty()) {
				lstCondition.add('Payment__c in :setPaymentsId');
			}
			if (!setSPId.isEmpty()) {
				lstCondition.add('Supplier_Payment__c in :setSPId');
			}
			if (!setJELId.isEmpty()) {
				lstCondition.add('Journal_Entry_Line__c in :setJELId');
			}
			if (!lstCondition.isEmpty()) {
				string clause = string.join(lstCondition, ' OR ');
				clause = clause == null || clause.trim() == '' ? '' : ' ( ' + clause + ' ) ';
				soql.setWhereClause(clause + ' AND Bank_Transaction__c = :bankTransactionID AND Is_Potential_Match__c = true');
				soql.setLimit(10000);
				lstBTM = Database.query(soql.getQuery());
			}
			if (!lstBTM.isEmpty()) {
				setCRId.clear();
				setPaymentsId.clear();
				setSPId.clear();
				setJELId.clear();
				for (Bank_Transaction_Match__c btm: lstBTM) {
					if (btm.Customer_Receipt__c != null) {
						setCRId.add(btm.Customer_Receipt__c);
					} else if (btm.Payment__c != null) {
						setPaymentsId.add(btm.Payment__c);
					} else if (btm.Supplier_Payment__c != null) {
						setSPId.add(btm.Supplier_Payment__c);
					} else {
						if (btm.Journal_Entry_Line__c != null) {
							setJELId.add(btm.Journal_Entry_Line__c);
						}
					}
				}

				for (MatchingWrapper record: lstSourceDocs) {
					if (!(setCRId.contains(record.recordId)
							|| setPaymentsId.contains(record.recordId)
							|| setSPId.contains(record.recordId)
							|| setJELId.contains(record.recordId))) {
						lstSourceDocstoReturn.add(record);
					}
				}
			} else {
				lstSourceDocstoReturn.addAll(lstSourceDocs);
			}
		}
		return lstSourceDocstoReturn;
	}


	public static list<MatchingWrapper> getMatchingTransactionsforAutoMatch(DateTime startDate, DateTime endDate, Id bankAccountId,
			String referenceNumber, Double startAmountMatched, Double EndAmountMatched, String transactedWithName,  String sObjectType, ID bankacct, boolean ignoreAmountandDateRange) {
		list<MatchingWrapper> results = new list<MatchingWrapper>();
		Bank_Account__c ba = PaymentService.getBankAccount(bankAccountId);
		if (sObjectType == 'Customer_Receipt__c') {
			results.addAll(getMatchingCustomerReceipts(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName, null, ignoreAmountandDateRange, CRType.BOTH));//
		} else if (sObjectType == 'Supplier_Payment__c') {
			results.addAll(getMatchingSupplierPayments(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName, ignoreAmountandDateRange));
		} else if (sObjectType == 'Journal_Entry_Line__c') {
			system.debug('fetching transactions for Journal_Entry_Line__c  ');
			results.addAll(getMatchingJournalEntryLines(startDate, endDate,  startAmountMatched, endAmountMatched, referenceNumber, ba.Id, ba.Currency__c, ignoreAmountandDateRange));
		} else if (sObjectType == 'Payment__c') {
			results.addAll(getMatchingIntercoReceipts(startDate, endDate, ba.Id, ba.Currency__c, startAmountMatched, endAmountMatched, referenceNumber, transactedWithName, ignoreAmountandDateRange));
			results.addAll(getMatchingIntercoPayments(startDate, endDate, ba.Id, ba.Currency__c, startAmountMatched, endAmountMatched, referenceNumber, transactedWithName, ignoreAmountandDateRange));
		}
		return results;
	}


	public static list<MatchingWrapper> getMatchingTransactions(DateTime startDate, DateTime endDate, Id bankAccountId,
			String referenceNumber, Double startAmountMatched, Double EndAmountMatched, String transactedWithName, String depositId, set<String> sObjectTypes, ID bankTransactionID, boolean ignoreAmountRange) {

		Bank_Account__c ba = PaymentService.getBankAccount(bankAccountId);
		system.debug('startDate==' + startDate + ' endDate=' + endDate);
		list<MatchingWrapper> results = new list<MatchingWrapper>();
		if (sObjectTypes.isEmpty()) { //if empty assume you want to match against all sObjects.
			results.addAll(getMatchingCustomerReceipts(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName, depositId, ignoreAmountRange, CrType.BOTH));//
			results.addAll(getMatchingSupplierPayments(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName, ignoreAmountRange));
			results.addAll(getMatchingJournalEntryLines(startDate, endDate, startAmountMatched, endAmountMatched, referenceNumber, ba.Id, ba.Currency__c, ignoreAmountRange));
			results.addAll(getMatchingIntercoReceipts(startDate, endDate, ba.Id, ba.Currency__c, startAmountMatched, endAmountMatched, referenceNumber, transactedWithName, ignoreAmountRange));
			results.addAll(getMatchingIntercoPayments(startDate, endDate, ba.Id, ba.Currency__c, startAmountMatched, endAmountMatched, referenceNumber, transactedWithName, ignoreAmountRange));
			return results;
		} else {
			for (String sObjectType : sObjectTypes) {
				System.debug('sObjectType###' + sObjectType);
				if (sObjectType == 'Receipts') {
					results.addAll(getMatchingCustomerReceipts(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName,depositId, ignoreAmountRange, CRType.RECEIPT));// depositId,
					results.addAll(getMatchingIntercoReceipts(startDate, endDate, ba.Id, ba.Currency__c, startAmountMatched, endAmountMatched, referenceNumber, transactedWithName, ignoreAmountRange));
				} else if (sObjectType == 'Payments') {
					results.addAll(getMatchingCustomerReceipts(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName, depositId, ignoreAmountRange, CRType.REFUND));//depositId,
					results.addAll(getMatchingSupplierPayments(startDate, endDate, ba.Id, ba.Currency__c, referenceNumber, startAmountMatched, EndAmountMatched, transactedWithName, ignoreAmountRange));
					results.addAll(getMatchingIntercoPayments(startDate, endDate, ba.Id, ba.Currency__c, startAmountMatched, endAmountMatched, referenceNumber, transactedWithName, ignoreAmountRange));
				} else if (sObjectType == 'Journal_Entry_Line__c') {
					results.addAll(getMatchingJournalEntryLines(startDate, endDate,  startAmountMatched, endAmountMatched, referenceNumber, ba.Id, ba.Currency__c, ignoreAmountRange));
				} else {
					throw new BankTransactionMatchServiceException('SObject Type ' + sObjectType + ' not supported to query matching bank transactions');
					return null;
				}
			}

			return results;
		}
	}

	public static list<MatchingWrapper> getMatchingCustomerReceipts(DateTime startDate, DateTime endDate, Id bankAccountId, ID bankAccountCurrencyId,
			String referenceNumber, Double startAmountMatched, Double EndAmountMatched, String transactedWithName, String depositId, boolean ignoreAmountRange, CRType type) {

		list<MatchingWrapper> results = new list<MatchingWrapper>();
		//if everything is null - can happen for refunds
		if(startDate == null && endDate == null && startAmountMatched == null && EndAmountMatched == null && String.isBlank(transactedWithName) && String.isBlank(referenceNumber) && String.isBlank(depositId)) {
			return results;
		}

		string query = 'select Id, Name, Reference_Number__c, Amount_Received__c, Transaction_Date__c, Customer__r.Name,Customer__r.Aliases__c, Deposit_Identifier__c from Customer_Receipt__c ' +
				'where ID in (Select Customer_Receipt__c from Accounting_Entry__c where Status__c = \'Active\' and ' +
				'Has_Exceptions__c = false) and Bank_Account_2__c = :bankAccountId and Currency__c = :bankAccountCurrencyId ' +
				'and ID NOT IN (Select Customer_Receipt__c from Bank_Transaction_Match__c where Is_Potential_Match__c=false ) ' + //dont want any CR that is linked to BTM period!!
				'and Finalized__c = true and Void__c = false and Has_Exceptions__c = false  ';

		if (!ignoreAmountRange) {
			if (startDate != null && endDate != null) {
				query = query + ' and Transaction_Date__c >= :startDate and Transaction_Date__c < :endDate  ';
			}

			if(type == CRType.RECEIPT) {
				if (startAmountMatched != null && EndAmountMatched != null) {
					query = query + ' and Amount_Received__c >=  :startAmountMatched and Amount_received__c <= :EndAmountMatched' ;
				} else {
					//if I am searching for receipts I should not get negative CR
					query = query + ' and Amount_Received__c >  0';
				}
			} else if(type == CRType.REFUND) {
				if (startAmountMatched != null && EndAmountMatched != null) {
					startAmountMatched = -1 * startAmountMatched;
					EndAmountMatched = -1 * EndAmountMatched;
					query = query + ' and Amount_Received__c <=  :startAmountMatched and Amount_received__c >= :EndAmountMatched' ;
				} else {
					//if I am searching for payments I should get only negative CR
					query = query + ' and Amount_Received__c <  0';
				}
			} else {
				query = query + ' and Amount_Received__c !=  0';
			}
		}

		if (string.isNotBlank(referenceNumber)) {
			referenceNumber = '%' + referenceNumber + '%';
			query = query + ' and Reference_Number__c like :referenceNumber';
		}
		if (string.isNotBlank(transactedWithName)) {
			transactedWithName = '%' + transactedWithName + '%';
			query = query + ' and Customer__r.Name like :transactedWithName';
		}
		if (string.isNotBlank(depositId)) {
			query = query + ' and Deposit_Identifier__c = :depositId';
		}
		system.debug(LoggingLevel.ERROR, ' query: ' + query);
		for (Customer_Receipt__c cr :Database.query(query)) {
			MatchingWrapper wrapper = new MatchingWrapper(cr.Id, cr.Name, cr.Transaction_Date__c, cr.Amount_Received__c, cr.Reference_Number__c, cr.Customer__r.Name, cr.Customer__c, cr.Customer__r.Aliases__c, null, 'Customer_Receipt__c', cr.Deposit_Identifier__c);
			results.add(wrapper);
		}
		return results;
	}

	public static list<MatchingWrapper> getMatchingIntercoReceipts(DateTime startDate, DateTime endDate, Id bankAccountId, Id bankAccountCurrencyId,
			Double startAmountMatched, Double EndAmountMatched, String referenceNumber, String transactedWithName, boolean ignoreAmountRange) {

		system.debug(LoggingLevel.Error,'startDate '+startDate);
		system.debug(LoggingLevel.Error,'endDate '+endDate);
		system.debug(LoggingLevel.Error,'startAmountMatched '+startAmountMatched);
		system.debug(LoggingLevel.Error,'EndAmountMatched '+EndAmountMatched);
		system.debug(LoggingLevel.Error,'transactedWithName '+transactedWithName);
		system.debug(LoggingLevel.Error,'referenceNumber '+referenceNumber);
		list<MatchingWrapper> results = new list<MatchingWrapper>();
		//if everything is null
		if(startDate == null && endDate == null && startAmountMatched == null && EndAmountMatched == null && String.isBlank(transactedWithName) && String.isBlank(referenceNumber)) {
			return results;
		}

		string query = 'select Id, Name, Payment_amount__c,Reference_Number__c, Transaction_Date__c, From_company__r.name,From_company__r.Aliases__c from Payment__c ' +
				'where Id in (Select Payment__c from Accounting_Entry__c where Status__c = \'Active\'   and ' +
				'Has_Exceptions__c = false) and To_Bank_Account__c = :bankAccountId and Currency__c = :bankAccountCurrencyId ' +
				' and Id NOT IN (Select Payment__C from Bank_Transaction_Match__c where Payment__r.To_Bank_Account__C=:bankAccountId and bank_transaction__r.Bank_account__c =:bankAccountId and Is_Potential_Match__c=false ) ' + //dont want any InterCo Receipts that is linked to BTM !!
				' and Finalized__c = true  and Has_Exceptions__c = false  ' +
				'and Payment_amount__c > 0  ';
		if (!ignoreAmountRange) {
			if (startDate != null && endDate != null) {
				query = query + ' and Transaction_Date__c >= :startDate and Transaction_Date__c < :endDate ';
			}
			if (startAmountMatched != null && EndAmountMatched != null) {
				query = query + ' and Payment_amount__c >=  :startAmountMatched and Payment_amount__c <= :EndAmountMatched ' ;
			}
		}


		if (string.isNotBlank(referenceNumber)) {
			system.debug('referenceNumber: ' + referenceNumber);
			referenceNumber = '%' + referenceNumber + '%';
			query = query + ' and Reference_Number__c like :referenceNumber';
		}
		if (string.isNotBlank(transactedWithName)) {
			system.debug('transactedWithName: ' + transactedWithName);
			transactedWithName = '%' + transactedWithName + '%';
			query = query + ' and From_company__r.Name like :transactedWithName';
		}
		system.debug('**** qry' + query);

		for (Payment__c pmt :Database.query(query)) {
			system.debug(pmt.Id + ' pmt.Name  ' + pmt.Name + 'pmt.Transaction_Date__c ' + pmt.Transaction_Date__c + 'pmt.Payment_amount__c ' + pmt.Payment_amount__c + 'pmt.Reference_Number__c ' + pmt.Reference_Number__c + 'From_Company__r.Name: ' + pmt.From_Company__r.Name + '-' + null + 'obj type:' + 'Payment__c');

			MatchingWrapper wrapper = new MatchingWrapper(pmt.Id, pmt.Name, pmt.Transaction_Date__c, pmt.Payment_amount__c, pmt.Reference_Number__c, pmt.From_Company__r.Name, pmt.From_Company__c, pmt.From_Company__r.Aliases__c, null, 'Payment__c');
			results.add(wrapper);
		}
		return results;
	}

	public static list<MatchingWrapper> getMatchingIntercoPayments(DateTime startDate, DateTime endDate, Id bankAccountId, Id bankAccountCurrencyId,
			Double startAmountMatched, Double EndAmountMatched, String referenceNumber, String transactedWithName, boolean ignoreAmountRange) {

		list<MatchingWrapper> results = new list<MatchingWrapper>();
		//if everything is null
		if(startDate == null && endDate == null &&  startAmountMatched == null && EndAmountMatched == null && String.isBlank(transactedWithName) && String.isBlank(referenceNumber)) {
			return results;
		}

		string query = 'select Id, Name, Payment_amount__c,Reference_Number__c, Transaction_Date__c, To_company__r.name, To_Company__r.Aliases__c from Payment__c ' +
				'where ID in (Select Payment__c from Accounting_Entry__c where Status__c = \'Active\'  and ' +
				'Has_Exceptions__c = false) and From_Bank_Account__c = :bankAccountId and Currency__c = :bankAccountCurrencyId ' +
				'and ID NOT IN (Select Payment__C from Bank_Transaction_Match__c where Payment__r.From_Bank_Account__C=:bankAccountId  and bank_transaction__r.Bank_account__c =:bankAccountId and Is_Potential_Match__c=false ) ' + //dont want any InterCo Payments that is linked to BTM !!
				'and Finalized__c = true and Has_Exceptions__c = false  ' +
				'and Payment_amount__c > 0  ';
		if (!ignoreAmountRange) {
			if (startDate != null && endDate != null) {
				query = query + ' and Transaction_Date__c >= :startDate and Transaction_Date__c < :endDate ';

			}
			if (startAmountMatched != null && EndAmountMatched != null) {
				query = query + ' and Payment_amount__c >=  :startAmountMatched and Payment_amount__c <= :EndAmountMatched' ;
			}
		}
		if (string.isNotBlank(referenceNumber)) {
			referenceNumber = '%' + referenceNumber + '%';
			query = query + ' and Reference_Number__c like :referenceNumber';
		}
		if (string.isNotBlank(transactedWithName)) {
			transactedWithName = '%' + transactedWithName + '%';
			query = query + ' and To_company__r.Name like :transactedWithName';
		}

		for (Payment__c pmt :Database.query(query)) {
			MatchingWrapper wrapper = new MatchingWrapper(pmt.Id, pmt.Name, pmt.Transaction_Date__c, (-1) * pmt.Payment_amount__c, pmt.Reference_Number__c, pmt.To_Company__r.Name, pmt.To_Company__c, pmt.To_Company__r.Aliases__c, null, 'Payment__c');
			results.add(wrapper);
		}
		return results;
	}


	public static list<MatchingWrapper> getMatchingSupplierPayments(DateTime startDate, DateTime endDate, Id bankAccountId, Id bankAccountCurrencyId,
			String referenceNumber, Double startAmountMatched, Double EndAmountMatched, String transactedWithName, boolean ignoreAmountRange) {

			list<MatchingWrapper> results = new list<MatchingWrapper>();
			//if everything is null
			if(startDate == null && endDate == null && startAmountMatched == null && EndAmountMatched == null && String.isBlank(transactedWithName) && String.isBlank(referenceNumber)) {
				return results;
			}
			//KNDY-17923 - deperecated Check_Sequence_Number__c
			string query = 'select Id, Name, Reference__c, Payment_Amount__c, Transaction_Date__c, Supplier__r.Name,Supplier__r.Aliases__c from Supplier_Payment__c '+ 
				'where ID in (Select Supplier_Payment__c from Accounting_Entry__c where Status__c = \'Active\' and ' +
				'Has_Exceptions__c = false) and Bank_Account__c = :bankAccountId  and Currency__c = :bankAccountCurrencyId ' +
				'and ID NOT IN (Select Supplier_Payment__c from Bank_Transaction_Match__c where Is_Potential_Match__c=false ) ' +
				'and Finalized__c = true and Void__c = false  ' +
				'and Payment_Amount__c > 0  ';
		if (!ignoreAmountRange) {
			if (startDate != null && endDate != null) {
				query = query + ' and Transaction_Date__c >= :startDate and Transaction_Date__c < :endDate ';
			}
			if (startAmountMatched != null && EndAmountMatched != null) {
				query = query + ' and Payment_Amount__c >=  :startAmountMatched and Payment_Amount__c <= :EndAmountMatched ' ;
			}
		}
		if (string.isNotBlank(transactedWithName)) {
			transactedWithName = '%' + transactedWithName + '%';
			query = query + ' and Supplier__r.Name like :transactedWithName';
		}
		if (string.isNotBlank(referenceNumber)) {
			referenceNumber = '%' + referenceNumber + '%';
				//KNDY-17923 - deperecated Check_Sequence_Number__c		
				//query = query + ' and Check_Sequence_Number__c like :referenceNumber';
				query = query + ' and Reference__c like :referenceNumber';
		}

		for (Supplier_Payment__c sp : Database.query(query)) {
			//KNDY-17923 - deperecated Check_Sequence_Number__c						
			MatchingWrapper wrapper = new MatchingWrapper(sp.Id, sp.Name, sp.Transaction_Date__c, (-1) * sp.Payment_Amount__c, sp.Reference__c, sp.Supplier__r.Name, sp.Supplier__c,sp.Supplier__r.Aliases__c, null,'Supplier_Payment__c');
			results.add(wrapper);
		}
		return results;
	}

	//WITH JOURNAL ENTRY LINES YOU COULD QUERY FOR BOTH POSITIVE AND NEGATIVE LINES
	//EX: YOU COULD HAVE A BT FOR -1000$ AND MATCH IT AGAINST A SP FOR 900 AND CR-JEL FOR 100 -- > BTM-1 = -900 + BTM-2 = -100
	//OR YOU COULD HAVE A BT FOR -1000$ AND MATCH IT AGAINST A SP FOR 1100 AND DR-JEL FOR 100 -- >BTM-1 = -1100 + BTM-2 = +100
	public static list<MatchingWrapper> getMatchingJournalEntryLines(DateTime startDate, DateTime endDate,  Double startAmountMatched, Double endAmountMatched, String referenceNumber,Id bankAccountId, Id bankAccountCurrencyId, boolean ignoreAmountRange) {
		list<MatchingWrapper> results = new list<MatchingWrapper>();
		//if everything is null
		if(startDate == null && endDate == null && String.isBlank(referenceNumber) && startAmountMatched == null && EndAmountMatched == null) {
			return results;
		}
		system.debug(LoggingLevel.Error,'startDate '+startDate);
		system.debug(LoggingLevel.Error,'endDate '+endDate);
		system.debug(LoggingLevel.Error,'referenceNumber '+referenceNumber);

		if (startAmountMatched == 0)
			startAmountMatched += 0.00001;
		if (endAmountMatched == 0)
			endAmountMatched += 0.00001;

		system.debug(LoggingLevel.Error,'startAmountMatched '+startAmountMatched);
		system.debug(LoggingLevel.Error,'EndAmountMatched '+EndAmountMatched);

		boolean isConditionsAdded = false; //flag to validate whether only search is invoked by putting only transacted with.
		//return null if thats the case.
		string query = 'Select Id, name, Journal_Entry__r.Transaction_Date__c, Amount_CR__c, Amount_DR__c, Description__c from Journal_Entry_Line__c ' +
				'where Id in (Select Journal_Entry_Line__c from Accounting_Entry_Line__c where Accounting_Entry__r.Status__c = \'Active\' and Accounting_Entry__r.Has_Exceptions__c = false)' +
				'and Finalized__c = true and Journal_Entry__r.Void__c = false and Journal_Entry__r.Has_Exceptions__c = false ' +
				'and ID NOT IN (Select Journal_Entry_Line__c from Bank_Transaction_Match__c where Is_Potential_Match__c=false ) and Bank_Account__c= :bankAccountId  and Journal_Entry__r.Currency__c = :bankAccountCurrencyId '; //KNDY-11127

		if (!ignoreAmountRange) {
			if (startDate != null && endDate != null) {
				isConditionsAdded = true;
				query = query + 'and Journal_Entry__r.Transaction_Date__c >= :startDate and Journal_Entry__r.Transaction_Date__c < :endDate ';
			}
			if (startAmountMatched != null && EndAmountMatched != null) {
				double negStartAmt = -1 * EndAmountMatched;
				double negEndAmt = -1 * startAmountMatched;
				isConditionsAdded = true;
				query = query + ' and ((Amount_CR__c >=  :startAmountMatched and Amount_CR__c <= :EndAmountMatched) OR (Amount_DR__c >=  :startAmountMatched and Amount_DR__c <= :EndAmountMatched) '
						      	+ ' OR (Amount_CR__c >=  :negStartAmt and Amount_CR__c <= :negEndAmt) OR (Amount_DR__c >=  :negStartAmt and Amount_DR__c <= :negEndAmt))';
			}
		}
		if (string.isNotBlank(referenceNumber)) {
			isConditionsAdded = true;
			referenceNumber = '%' + referenceNumber + '%';
			query = query + ' and Description__c like :referenceNumber';
		}
		system.debug('***jel query***' + query);
		if (isConditionsAdded || ignoreAmountRange) {
			for (Journal_Entry_Line__c jel : Database.query(query)) {
				MatchingWrapper wrapper = new MatchingWrapper(jel.Id, jel.Name, jel.Journal_Entry__r.Transaction_Date__c, jel.Amount_CR__c != 0 ? (jel.Amount_CR__c > 0 ? (-1) * jel.Amount_CR__c: jel.Amount_CR__c) : jel.Amount_DR__c, jel.Description__c, null, null, null, null, 'Journal_Entry_Line__c');
				results.add(wrapper);
			}
			
		}
		return results;
	}


	public class MatchingWrapper {
		public Id recordId;
		public string recordName;
		public dateTime transactionDate;
		public decimal amountMatched;
		public string referenceNumber;
		public string transactedWithName;
		public string depositId;
		public string transactedWithId;// for auto Match
		public string aliases;
		public string description;
		public string objectType;
		public id bankTransactionMatchId;
		public boolean IsPotentialMatch = false;
		public Id ruleRecordId;
		public string ruleRecordName;
		public boolean IsTransactedWith = false;

		public MatchingWrapper() {
		}

		public MatchingWrapper(Id recordId, String recordName, DateTime transactionDate, Decimal amountMatched, string referenceNumber, string transactedWithName, string transactedWithId, string aliases, string description, string objectType) {

			this.recordId = recordId;
			this.recordName = recordName;
			this.transactionDate = transactionDate;
			this.amountMatched = amountMatched;
			this.referenceNumber = referenceNumber;
			this.transactedWithName = transactedWithName;
			this.description = description;
			this.objectType = objectType;
			this.bankTransactionMatchId = null;
			this.transactedWithId = transactedWithId;
			this.aliases = aliases;
		}

		public MatchingWrapper(Id recordId, String recordName, DateTime transactionDate, Decimal amountMatched, string referenceNumber, string transactedWithName, string transactedWithId, string aliases, string description, string objectType, string depositId) {

			this.recordId = recordId;
			this.recordName = recordName;
			this.transactionDate = transactionDate;
			this.amountMatched = amountMatched;
			this.referenceNumber = referenceNumber;
			this.transactedWithName = transactedWithName;
			this.description = description;
			this.objectType = objectType;
			this.bankTransactionMatchId = null;
			this.transactedWithId = transactedWithId;
			this.aliases = aliases;
			this.depositId = depositId;
		}

		public MatchingWrapper(Id recordId, String recordName, DateTime transactionDate,
				Decimal amountMatched, string referenceNumber, string transactedWithName,//string transactedWithId,string aliases,
				string description, string objectType,
				Id bankTransactionMatchId, boolean ispotentialmatch,
				Id ruleRecordId, string ruleRecordName, boolean IsTransactedWith) {
			this.recordId = recordId;
			this.recordName = recordName;
			this.transactionDate = transactionDate;
			this.amountMatched = amountMatched;
			this.referenceNumber = referenceNumber;
			this.transactedWithName = transactedWithName;
			this.description = description;
			this.objectType = objectType;
			this.bankTransactionMatchId = bankTransactionMatchId;
			this.IsPotentialMatch = ispotentialmatch;
			this.ruleRecordId = ruleRecordId;
			this.ruleRecordName = ruleRecordName;
			this.IsTransactedWith = IsTransactedWith;
		}
	}

	public class transactionWithMatchesWrapper {
		public Bank_Transaction__c bankTransaction;
		public list<MatchingWrapper> lstMatches;
		public transactionWithMatchesWrapper() {
		}

		public transactionWithMatchesWrapper(Bank_Transaction__c bankTransaction, list<MatchingWrapper> lstMatches) {
			this.bankTransaction = bankTransaction;
			this.lstMatches = lstMatches;
		}
	}

	public static list<transactionWithMatchesWrapper> getAllBankTransactions(id bankAccountId, datetime opbaldate) {
		map<Id, Bank_Transaction__c> mapBankTransaction;
		list<transactionWithMatchesWrapper> lstTransactionWithMatchesWrapper = new list<transactionWithMatchesWrapper>();
		SchemaUtil shUtil = new SchemaUtil();
		string whereClause = ' bank_account__c = :bankAccountId' +
				' AND Finalized__c = true and Bank_Transaction_Group__r.Void__c = false and Match_Approved__c=false  and Transaction_Date__c > :opbaldate';
		string queryString = shUtil.generateQueryFromFieldSet('Bank_Transaction__c', new Set<String>{
				'Match_Bank_Transactions_Columns'
		}, null, whereClause);

		mapBankTransaction = new map<Id, Bank_Transaction__c>((list<Bank_Transaction__c>) Database.query(queryString));
		if (!mapBankTransaction.isEmpty()) {
			map<Id, list<MatchingWrapper>> mapTransactionIdAndMatchingWrapper = new map<Id, list<MatchingWrapper>>();
			for (Bank_Transaction__c bankTransaction :mapBankTransaction.values()) {
				lstTransactionWithMatchesWrapper.add(new transactionWithMatchesWrapper(bankTransaction, null));
			}
		}
		return lstTransactionWithMatchesWrapper;
	}


	public static list<transactionWithMatchesWrapper> getBankTransactionsAndMatches(dateTime startDate, dateTime endDate, id bankAccountId, Datetime OpBalDate) {
		map<Id, Bank_Transaction__c> mapBankTransaction;
		list<transactionWithMatchesWrapper> lstTransactionWithMatchesWrapper = new list<transactionWithMatchesWrapper>();
		SchemaUtil shUtil = new SchemaUtil();
		string whereClause = ' Transaction_Date__c >= :startDate' +
				' AND Transaction_Date__c < :endDate' +
				' AND  Transaction_Date__c > :OpBalDate ' +
				' AND bank_account__c = :bankAccountId' +
				' AND Finalized__c = true and Bank_Transaction_Group__r.Void__c = false ORDER BY Transaction_Date__c ASC limit 10000';
		string queryString = shUtil.generateQueryFromFieldSet('Bank_Transaction__c', new Set<String>{
				'Match_Bank_Transactions_Columns'
		}, null, whereClause);
		system.debug('bank tran params==' + startDate + '-' + endDate + '-OpBalDate' + OpBalDate + 'bankAccountId=' + bankAccountId);
		system.debug('queryString==' + queryString);
		mapBankTransaction = new map<Id, Bank_Transaction__c>((list<Bank_Transaction__c>) Database.query(queryString));
		if (!mapBankTransaction.isEmpty()) {
			map<Id, list<MatchingWrapper>> mapTransactionIdAndMatchingWrapper = new map<Id, list<MatchingWrapper>>();
			mapTransactionIdAndMatchingWrapper = getBankTransactionMatch(mapBankTransaction.keyset());
			if (!mapTransactionIdAndMatchingWrapper.isEmpty()) {
				for (Bank_Transaction__c bankTransaction :mapBankTransaction.values()) {
					transactionWithMatchesWrapper transactionWithMatchesWrapperRecord = new transactionWithMatchesWrapper();
					if (mapTransactionIdAndMatchingWrapper.containsKey(bankTransaction.Id)) {
						if (!mapTransactionIdAndMatchingWrapper.get(bankTransaction.Id).isEmpty()) {
							transactionWithMatchesWrapperRecord = new transactionWithMatchesWrapper(bankTransaction,
									mapTransactionIdAndMatchingWrapper.get(bankTransaction.Id));
						} else {
							transactionWithMatchesWrapperRecord = new transactionWithMatchesWrapper(bankTransaction, null);
						}
					} else {
						transactionWithMatchesWrapperRecord = new transactionWithMatchesWrapper(bankTransaction, null);
					}
					lstTransactionWithMatchesWrapper.add(transactionWithMatchesWrapperRecord);
				}
			} else {
				for (Bank_Transaction__c bankTransaction :mapBankTransaction.values()) {
					lstTransactionWithMatchesWrapper.add(new transactionWithMatchesWrapper(bankTransaction, null));
				}
			}
		}
		return lstTransactionWithMatchesWrapper;
	}
	public static map<Id, list<MatchingWrapper>> getBankTransactionMatch(set<Id> setBankTransactionId) {
		list<Bank_Transaction_Match__c> lstBankTransactionMatch = new list<Bank_Transaction_Match__c>();
		map<Id, list<MatchingWrapper>> mapTransactionIdAndMatchingWrapper = new map<Id, list<MatchingWrapper>>();
		set<String> additionalFields = new set<String>{
				'Id', 'Customer_Receipt__c', 'Journal_Entry_Line__c', 'Supplier_Payment__c', 'Bank_Transaction__c', 'Payment__c',
				'Customer_Receipt__r.Name', 'Customer_Receipt__r.Id',
				'Customer_Receipt__r.Reference_Number__c', 'Customer_Receipt__r.Customer__r.Name', 'Customer_Receipt__r.Customer__c',
				'Customer_Receipt__r.Transaction_Date__c', 'Supplier_Payment__r.Name',
				'Supplier_Payment__r.Id',
        		//KNDY-17923 - deperecated 'Check_Number__c' 
        		//'Supplier_Payment__r.Check_Sequence_Number__c',
        		'Supplier_Payment__r.Reference__c','Supplier_Payment__r.Supplier__r.Name','Supplier_Payment__r.Supplier__c',
				'Supplier_Payment__r.Transaction_Date__c', 'Journal_Entry_Line__r.Journal_Entry__r.Transaction_Date__c',
				'Journal_Entry_Line__r.Id', 'Journal_Entry_Line__r.Name',
				'Journal_Entry_Line__r.Description__c', 'Amount__c',
				'Bank_Transfer_Transaction__r.Id', 'Bank_Transfer_Transaction__r.Name',
				'Bank_Transfer_Transaction__r.Transaction_Date__c',
				'Bank_Transfer_Transaction__r.Reference_number__c',
				'Bank_Transfer_Transaction__r.Description__c',
				'Payment__r.Name',
				'Payment__r.Id',
				'Payment__r.Reference_Number__c', 'Payment__r.To_Company__r.Name', 'Payment__r.From_Company__r.Name', 'Payment__r.From_Company__c', 'Payment__r.From_Company__r.aliases__c',
				'Payment__r.From_Bank_Account__c', 'Payment__r.To_Bank_Account__c', 'Payment__r.To_Company__c', 'Payment__r.To_Company__r.aliases__c', 'Supplier_Payment__r.Supplier__r.aliases__c', 'Customer_Receipt__r.Customer__r.aliases__c',
				'Payment__r.Transaction_Date__c', 'Payment__r.Payment_Amount__c',
				'Bank_Transaction__r.Bank_account__c', 'Is_Potential_Match__c',
				'Transaction_Mathching_Rule__r.Id', 'Transaction_Mathching_Rule__r.Transacted_With__c',
				'Transaction_Mathching_Rule__r.Name'
		};
		string queryString = util.generateQueryFromFieldSet('Bank_Transaction_Match__c', new set<String>{
		}, additionalFields, 'Bank_Transaction__c = :setBankTransactionId limit 50000');
		lstBankTransactionMatch = Database.query(queryString);
		if (!lstBankTransactionMatch.isEmpty()) {
			for (Bank_Transaction_Match__c matchedRecord: lstBankTransactionMatch) {
				MatchingWrapper matchedWrapperRecord = new MatchingWrapper();
				if (mapTransactionIdAndMatchingWrapper.containsKey(matchedRecord.Bank_Transaction__c)) {
					matchedWrapperRecord = setMatchingWrapperValues(matchedRecord);
					mapTransactionIdAndMatchingWrapper.get(matchedRecord.Bank_Transaction__c).add(matchedWrapperRecord);
				} else {
					matchedWrapperRecord = setMatchingWrapperValues(matchedRecord);
					mapTransactionIdAndMatchingWrapper.put(matchedRecord.Bank_Transaction__c, new list<MatchingWrapper>());
					mapTransactionIdAndMatchingWrapper.get(matchedRecord.Bank_Transaction__c).add(matchedWrapperRecord);
				}
			}
		}
		return mapTransactionIdAndMatchingWrapper;
	}

	public static MatchingWrapper setMatchingWrapperValues(Bank_Transaction_Match__c matchedRecord) {
		MatchingWrapper matchedWrapperRecord = new MatchingWrapper();
		if (matchedRecord.Customer_Receipt__c != null) {
			matchedWrapperRecord = new MatchingWrapper(matchedRecord.Customer_Receipt__r.Id,
					matchedRecord.Customer_Receipt__r.Name,
					matchedRecord.Customer_Receipt__r.Transaction_Date__c,
					matchedRecord.Amount__c,
					matchedRecord.Customer_Receipt__r.Reference_Number__c,
					matchedRecord.Customer_Receipt__r.Customer__r.Name,
					null, 'Receipts',
					matchedRecord.Id, matchedRecord.Is_Potential_Match__c,
					matchedRecord.Transaction_Mathching_Rule__r.Id,
					matchedRecord.Transaction_Mathching_Rule__r.Name,
					matchedRecord.Transaction_Mathching_Rule__r.Transacted_With__c);

		} else if (matchedRecord.Supplier_Payment__c != null) {

			matchedWrapperRecord = new MatchingWrapper(matchedRecord.Supplier_Payment__r.Id,
					matchedRecord.Supplier_Payment__r.Name,
					matchedRecord.Supplier_Payment__r.Transaction_Date__c,
					matchedRecord.Amount__c,
	                //KNDY-17923 - deperecated 'Check_Sequence_Number__c' 	
	                //matchedRecord.Supplier_Payment__r.Check_Sequence_Number__c,
	                matchedRecord.Supplier_Payment__r.Reference__c,
					matchedRecord.Supplier_Payment__r.Supplier__r.Name,
					null, 'Payments',
					matchedRecord.Id, matchedRecord.Is_Potential_Match__c,
					matchedRecord.Transaction_Mathching_Rule__r.Id,
					matchedRecord.Transaction_Mathching_Rule__r.Name,
					matchedRecord.Transaction_Mathching_Rule__r.Transacted_With__c);

		} else if (matchedRecord.Payment__C != null) {
			if (matchedRecord.Payment__r.From_Bank_Account__c == matchedRecord.Bank_Transaction__r.Bank_Account__c) {
				matchedWrapperRecord = new MatchingWrapper(matchedRecord.Payment__r.Id,
						matchedRecord.Payment__r.Name,
						matchedRecord.Payment__r.Transaction_Date__c,
						matchedRecord.Amount__c,
						matchedRecord.Payment__r.Reference_number__c,
						matchedRecord.Payment__r.To_Company__r.Name,
						null, 'Payments',
						matchedRecord.Id, matchedRecord.Is_Potential_Match__c,
						matchedRecord.Transaction_Mathching_Rule__r.Id,
						matchedRecord.Transaction_Mathching_Rule__r.Name,
						matchedRecord.Transaction_Mathching_Rule__r.Transacted_With__c);
			} else {
				matchedWrapperRecord = new MatchingWrapper(matchedRecord.Payment__r.Id,
						matchedRecord.Payment__r.Name,
						matchedRecord.Payment__r.Transaction_Date__c,
						matchedRecord.Amount__c,
						matchedRecord.Payment__r.Reference_number__c,
						matchedRecord.Payment__r.From_Company__r.Name,
						null, 'Receipts',
						matchedRecord.Id, matchedRecord.Is_Potential_Match__c,
						matchedRecord.Transaction_Mathching_Rule__r.Id,
						matchedRecord.Transaction_Mathching_Rule__r.Name,
						matchedRecord.Transaction_Mathching_Rule__r.Transacted_With__c);
			}

		} else if (matchedRecord.Journal_Entry_Line__c != null) {
			matchedWrapperRecord = new MatchingWrapper(matchedRecord.Journal_Entry_Line__r.Id,
					matchedRecord.Journal_Entry_Line__r.Name,
					matchedRecord.Journal_Entry_Line__r.Journal_Entry__r.Transaction_Date__c,
					matchedRecord.Amount__c,
					matchedRecord.Journal_Entry_Line__r.Description__c,
					null,
					null,
					'Journal_Entry_Line__c',
					matchedRecord.Id, matchedRecord.Is_Potential_Match__c,
					matchedRecord.Transaction_Mathching_Rule__r.Id,
					matchedRecord.Transaction_Mathching_Rule__r.Name,
					matchedRecord.Transaction_Mathching_Rule__r.Transacted_With__c);

		} else if (matchedRecord.Bank_Transfer_Transaction__c != null) {
			matchedWrapperRecord = new MatchingWrapper(matchedRecord.Bank_Transfer_Transaction__r.Id,
					matchedRecord.Bank_Transfer_Transaction__r.Name,
					matchedRecord.Bank_Transfer_Transaction__r.Transaction_Date__c,
					matchedRecord.Amount__c,
					matchedRecord.Bank_Transfer_Transaction__r.Reference_number__c,
					null,
					matchedRecord.Bank_Transfer_Transaction__r.Description__c,
					'Bank_Transaction__c',
					matchedRecord.Id, matchedRecord.Is_Potential_Match__c,
					matchedRecord.Transaction_Mathching_Rule__r.Id,
					matchedRecord.Transaction_Mathching_Rule__r.Name,
					matchedRecord.Transaction_Mathching_Rule__r.Transacted_With__c);

		}
		return matchedWrapperRecord;
	}

	public static list<Bank_Transaction_Match__c> unMatchedBankTransaction(set<Id> setBankTransactionMatchId) {
		list<Bank_Transaction_Match__c> lstBankTransactionMatch = new list<Bank_Transaction_Match__c>();
		if (!setBankTransactionMatchId.isEmpty()) {
			for (Id btmId: setBankTransactionMatchId) {
				lstBankTransactionMatch.add(new Bank_Transaction_Match__c(Id = btmId));
			}
			DML.deleteAsUser(lstBankTransactionMatch);
		}
		return lstBankTransactionMatch;
	}

	public class messageWrapper {
		public string objectType;
		public string recordName;
		public Id recordId;
		public string errorCode;
		public messageWrapper(string objectType, string recordName, Id recordId, string errorCode) {
			this.objectType = objectType;
			this.recordName = recordName;
			this.recordId = recordId;
			this.errorCode = errorCode;
		}
	}
	public static list<messageWrapper> learnTransactedwith(List<String> listBTMs) {
		List<String> localbtmid = listBTMs;

		SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
				'id', 'bank_Transaction__r.Transacted_With__c', 'Customer_Receipt__c', 'Customer_Receipt__r.Customer__r.aliases__c', 'Customer_Receipt__r.Customer__c', 'Customer_Receipt__r.Customer__r.Name',
				'Supplier_Payment__c', 'Supplier_Payment__r.Supplier__r.aliases__c', 'Supplier_Payment__r.Supplier__r.Name', 'Supplier_Payment__r.Supplier__c', 'Payment__c', 'Payment__r.From_Company__r.aliases__c',
				'Payment__r.From_Company__r.Name', 'Payment__r.To_Company__r.Name', 'Payment__r.To_Company__r.aliases__c',
				'Amount__c', 'Payment__r.To_Company__c', 'Payment__r.From_Company__c'
		});
		soql.setWhereClause('id in :localbtmid and Is_Potential_Match__c=false ALL ROWS');
		List<Bank_Transaction_Match__c> btmList = Database.query(soql.getQuery());
		map<Id, Customer__c> mapCust = new map<Id, Customer__c>();
		map<Id, Supplier__c> mapSupp = new map<Id, Supplier__c>();
		map<Id, Company__c> mapComp = new map<Id, Company__c>();
		list<messageWrapper> lstMessageWrapper = new list<messageWrapper>();
		for (Bank_Transaction_Match__c btm:btmList) {
			String btTransactedWith = btm.bank_Transaction__r.Transacted_With__c;
			String SDTransactedWith ;
			boolean matched;
			if (!String.IsBlank(btm.Customer_Receipt__c)) {
				if (!mapCust.containsKey(btm.Customer_Receipt__r.Customer__c)) {
					mapCust.put(btm.Customer_Receipt__r.Customer__c, new Customer__c(id = btm.Customer_Receipt__r.Customer__c, aliases__c = btm.Customer_Receipt__r.Customer__r.aliases__c,
							Name = btm.Customer_Receipt__r.Customer__r.Name));
				}
				matched = false;
				SDTransactedWith = mapCust.get(btm.Customer_Receipt__r.Customer__c).aliases__c;
				if (!String.Isblank(SDTransactedWith)) {
					for (String strSdTw:SDTransactedWith.split('~')) {
						if (strSdTw.equalsignorecase(btTransactedWith)) {
							matched = true;break;
						}
					}
					if (!matched) {
						mapCust.get(btm.Customer_Receipt__r.Customer__c).aliases__c = mapCust.get(btm.Customer_Receipt__r.Customer__c).aliases__c + '~' + btTransactedWith;
					}

				} else {
					mapCust.get(btm.Customer_Receipt__r.Customer__c).aliases__c = btTransactedWith;
				}
			} else
					if (!String.IsBlank(btm.Supplier_Payment__c)) {
						matched = false;
						if (!mapSupp.containsKey(btm.Supplier_Payment__r.Supplier__c)) {
							mapSupp.put(btm.Supplier_Payment__r.Supplier__c, new Supplier__c(id = btm.Supplier_Payment__r.Supplier__c, aliases__c = btm.Supplier_Payment__r.Supplier__r.aliases__c,
									Name = btm.Supplier_Payment__r.Supplier__r.Name));
						}
						SDTransactedWith = mapSupp.get(btm.Supplier_Payment__r.Supplier__c).aliases__c;
						if (!String.Isblank(SDTransactedWith)) {
							for (String strSdTwsupp:SDTransactedWith.split('~')) {
								if (strSdTwsupp.equalsignorecase(btTransactedWith)) {
									matched = true;break;
								}
							}
							if (!matched) {
								mapSupp.get(btm.Supplier_Payment__r.Supplier__c).aliases__c = mapSupp.get(btm.Supplier_Payment__r.Supplier__c).aliases__c + '~' + btTransactedWith;
							}
						} else {
							mapSupp.get(btm.Supplier_Payment__r.Supplier__c).aliases__c = btTransactedWith;
						}
					} else
							if (!String.IsBlank(btm.Payment__c)) {
								matched = false;
								if (btm.Amount__c >= 0) {
									if (!mapComp.containsKey(btm.Payment__r.From_Company__c)) {
										mapComp.put(btm.Payment__r.From_Company__c, new Company__c(id = btm.Payment__r.From_Company__c, aliases__c = btm.Payment__r.From_Company__r.aliases__c,
												Name = btm.Payment__r.From_Company__r.Name));
									}
									SDTransactedWith = mapComp.get(btm.Payment__r.From_Company__c).aliases__c;
								} else {
									if (!mapComp.containsKey(btm.Payment__r.To_Company__c)) {
										mapComp.put(btm.Payment__r.To_Company__c, new Company__c(id = btm.Payment__r.To_Company__c, aliases__c = btm.Payment__r.To_Company__r.aliases__c,
												Name = btm.Payment__r.To_Company__r.Name));
									}
									SDTransactedWith = mapComp.get(btm.Payment__r.To_Company__c).aliases__c;
								}

								if (!String.Isblank(SDTransactedWith)) {
									for (String strSdTwcomp:SDTransactedWith.split('~')) {
										if (strSdTwcomp.equalsignorecase(btTransactedWith)) {
											matched = true;break;
										}
									}
									if (!matched) {
										if (btm.Amount__c >= 0) {
											mapComp.get(btm.Payment__r.From_Company__c).aliases__c = mapComp.get(btm.Payment__r.From_Company__c).aliases__c + '~' + btTransactedWith;
										} else {
											mapComp.get(btm.Payment__r.To_Company__c).aliases__c = mapComp.get(btm.Payment__r.To_Company__c).aliases__c + '~' + btTransactedWith;
										}
									}
								} else {
									if (btm.Amount__c >= 0) {
										mapComp.get(btm.Payment__r.From_Company__c).aliases__c = btTransactedWith;
									} else {
										mapComp.get(btm.Payment__r.To_Company__c).aliases__c = btTransactedWith;
									}
								}

							}

		}

		if (!mapComp.isEmpty()) {
			lstMessageWrapper.addAll(returnSaveResultMessage('Company', mapComp.values()));
		}
		if (!mapSupp.isEmpty()) {
			lstMessageWrapper.addAll(returnSaveResultMessage('Supplier', mapSupp.values()));
		}
		if (!mapCust.isEmpty()) {
			lstMessageWrapper.addAll(returnSaveResultMessage('Customer', mapCust.values()));
		}
		return lstMessageWrapper;
	}

	public static list<messageWrapper> returnSaveResultMessage(string objectName, list<sObject> lstSObject) {
		list<Database.SaveResult> tempList = new list<Database.SaveResult>();
		tempList = DML.updateAsSystem(lstSObject, false);
		list<messageWrapper> lstMessageWrapper = new list<messageWrapper>();
		for (integer i = 0; i < lstSObject.size(); i++) {
			if (!tempList.get(i).isSuccess()) {
				for (Database.Error err : tempList.get(i).getErrors()) {
					if (string.valueOf(err.getStatusCode()).contains('STRING_TOO_LONG') &&
							string.valueOf(err.getFields()).contains('Aliases__c')) {
						if (objectName.equalsIgnoreCase('Company'))
							lstMessageWrapper.add(new messageWrapper(objectName, ((list<Company__c>) lstSObject).get(i).Name, ((list<Company__c>) lstSObject).get(i).Id, 'STRING_TOO_LONG')); else if (objectName.equalsIgnoreCase('Supplier'))
							lstMessageWrapper.add(new messageWrapper(objectName, ((list<Supplier__c>) lstSObject).get(i).Name, ((list<Supplier__c>) lstSObject).get(i).Id, 'STRING_TOO_LONG')); else if (objectName.equalsIgnoreCase('Customer'))
							lstMessageWrapper.add(new messageWrapper(objectName, ((list<Customer__c>) lstSObject).get(i).Name, ((list<Customer__c>) lstSObject).get(i).Id, 'STRING_TOO_LONG'));
					} else {
						if (objectName.equalsIgnoreCase('Company'))
							lstMessageWrapper.add(new messageWrapper(objectName, ((list<Company__c>) lstSObject).get(i).Name, ((list<Company__c>) lstSObject).get(i).Id, err.getMessage())); else if (objectName.equalsIgnoreCase('Supplier'))
							lstMessageWrapper.add(new messageWrapper(objectName, ((list<Supplier__c>) lstSObject).get(i).Name, ((list<Supplier__c>) lstSObject).get(i).Id, err.getMessage())); else if (objectName.equalsIgnoreCase('Customer'))
							lstMessageWrapper.add(new messageWrapper(objectName, ((list<Customer__c>) lstSObject).get(i).Name, ((list<Customer__c>) lstSObject).get(i).Id, err.getMessage()));
					}
				}
			}
		}
		return lstMessageWrapper;
	}


	public static list<bank_Transaction_Match__c> confirmMatch(List<String> listBTMs) {
		List<Bank_Transaction_Match__c> btmListToupdate = new List<Bank_Transaction_Match__c>();
		for (String btmid: listBTMs) {
			btmListToupdate.add(new Bank_Transaction_Match__c(id = btmid, Is_Potential_Match__c = false));
		}
		List<Id> btmids = new List<Id>();
		List<Database.SaveResult> srList = DML.updateAsUserWorker(btmListToupdate, false);
		for (Database.SaveResult sr: srList) {
			if (sr.success) {
				btmids.add(sr.getId());
			}
		}
		SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
				'Id', 'Name', 'Customer_Receipt__c', 'Supplier_Payment__c', 'Journal_Entry_Line__c', 'Payment__c', 'Payment__r.From_Bank_Account__c',
				'Payment__r.To_Bank_Account__c', 'Bank_Transaction__c', 'Payment__r.To_Company__c', 'Payment__r.From_Company__c'
		});
		soql.setWhereClause('id in :btmids');
		return Database.query(soql.getQuery());
	}

}