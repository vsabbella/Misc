public with sharing class AgreementConsoleExt {

	public Agreement__c agreement{get; set;}
    public Company__c company{get; set;}

    public AgreementConsoleExt(ApexPages.StandardController stdController) {
        this.agreement = (Agreement__c)stdController.getRecord();
        Id companyId = agreement.Company__c;
        if(companyId == null) {
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Default_Company__c'
			});
			Id uId = UserInfo.getUserId();
			soql.setWhereClause('User__c =: uId');
			List<User_Preference__c> userPreferences = Database.query(soql.getQuery());

            companyId = userPreferences[0].Default_Company__c;
        }
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('Id =: companyId');
		company = Database.query(soql.getQuery());
    }
}