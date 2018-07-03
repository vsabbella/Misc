public with sharing class ConcurrencyService {
	/*
		Description: This utility method is used to manage user concurrency for various visualforce pages throughout the system
	*/
	public static ConcurrencyDetail checkConcurrency(string pageName, Id recordId){
		
		ConcurrencyDetail cd = new ConcurrencyDetail();
		cd.concurrencyConflict = false;
		
		if(Concurrency_Configuration__c.getAll().containsKey(pageName)){
			try{
				Concurrency_Configuration__c cc = Concurrency_Configuration__c.getAll().get(pageName);
				SOQLUtil soql = new SOQLUtil(cc.Object__c, TRUE);
				soql.addFields(new Set<String>{'Id', cc.User_Field__c, cc.Timestamp_Field__c});
				soql.setWhereClause('Id = :recordId');
				
				sObject sObj = Database.Query(soql.getQuery());
				
				DateTime dt = (DateTime)sObj.get(cc.timestamp_field__c);
				Id userId = (Id)sObj.get(cc.user_field__c);
				integer seconds = (integer)cc.time__c;
				
				if(dt != null && userId != null){
					if(dt > system.now().addSeconds((-1)*seconds) && userId != userinfo.getUserId()){
						cd.concurrencyConflict = true;
						cd.releaseDateTime = dt.addSeconds(seconds);
					}else{
						sObj.put(cc.timestamp_field__c, system.now());
						sObj.put(cc.user_field__c, userInfo.getUserId());
						cd.releaseDateTime = dt.addSeconds(seconds);
						DML.updateAsSystem(sObj);
					}
					
					User u = returnUser(userId);
					cd.processOwner = u;
				}else{
					sObj.put(cc.timestamp_field__c, system.now());
					sObj.put(cc.user_field__c, userInfo.getUserId());
					DML.updateAsSystem(sObj);
					
					User u = returnUser(userInfo.getUserId());
					cd.processOwner = u;
					cd.releaseDateTime = system.now().addSeconds(seconds);
				}
			}catch(Exception ex){
				//There was a problem with the concurrency configuration or queries - treat it as if there is no concurrency issue, and the process lease time has no duration
				cd.concurrencyConflict = false;
				cd.processOwner = returnUser(userInfo.getUserId());
				cd.releaseDateTime = system.now();
			}
		}
		return cd;
	}
	
	public static void releaseConcurrency(string pageName, Id recordId){
		
		if(Concurrency_Configuration__c.getAll().containsKey(pageName)){
			try{
				Concurrency_Configuration__c cc = Concurrency_Configuration__c.getAll().get(pageName);
				SOQLUtil soql = new SOQLUtil(cc.Object__c, TRUE);
				soql.addFields(new Set<String>{'Id', cc.User_Field__c, cc.Timestamp_Field__c});
				soql.setWhereClause('Id = :recordId');
				
				sObject sObj = Database.Query(soql.getQuery());
				
				sObj.put(cc.timestamp_field__c, null);
				sObj.put(cc.user_field__c, null);
					
				DML.updateAsSystem(sObj);
			}catch(Exception ex){
				//Do nothing - cannot manage concurrency with improper configuration
			}
				
		}
	}
	
	
	public class ConcurrencyDetail{
		public boolean concurrencyConflict;
		public DateTime releaseDateTime;
		public User processOwner;
	}
	
	private static User returnUser(Id userId){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('User', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','email'
		});
		soql.setWhereClause('Id = :userId');
		return ((List<User>)Database.query(soql.getQuery()))[0];
	}
}