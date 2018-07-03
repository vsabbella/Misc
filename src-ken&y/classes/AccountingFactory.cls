public with sharing class AccountingFactory {
	
	public static AccountingService createAccountingService(string className){
		Type t = Type.forName(className);
		AccountingService acctSvc = (AccountingService)t.newInstance();
		return acctSvc;
	}
}