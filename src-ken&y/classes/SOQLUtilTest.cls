@isTest
private class SOQLUtilTest {
	
	static testMethod void testPostiveQuery(){
		
		TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        Facility__c fac = fuel.facility;
        Location__c loc = fuel.location;
        
        
        SOQLUtil soql = new SOQLUtil('Facility__c');
        soql.addFields(new set<string>{'Company__c'});
        soql.addFields('MRPRun_RO');
        soql.addField('Company__r.Name');
        soql.addAllFields();    
        soql.setWhereClause('Company__c = \'' + company.Id + '\'');
        soql.setOrderByClause('Company__c DESC'); 	
        system.assert(soql.getWhereClause() == 'Company__c = \'' + company.Id + '\'');
       
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Locations__r');
		childRel.addField('Id');
		childRel.addFields(new set<string>{'Id', 'Name'});
		childRel.addAllFields();
		childRel.setWhereClause('Facility__c = \'' + fac.Id + '\'');   	
        childRel.setOrderByClause('Name DESC');     
    	childRel.getWhereClause();
    	childRel.setLimit(1);
    	system.assert(childRel.getLimit() == 1);
    	
    	soql.addChildRelationship(childRel);
    	soql.getChildRelationship('Locations__r');
    	system.assert(soql.getChildRelationships().size() == 1);
    	
    	soql.removeChildRelationship('Locations__r');
    	system.assert(soql.getChildRelationships().size() == 0);
    	
    	soql.addChildRelationship(childRel);
    	system.assert(soql.getChildRelationships().size() == 1);
    	
    	soql.setLimit(1);
    	system.assert(soql.getLimit() == 1);
    	
    	soql.setSearchRecycle(false);
    	system.assert(!soql.getSearchRecycle());
    	
    	List<Facility__c> facilities = soql.returnQueryResult();
    	system.assert(facilities.size() == 1, 'Record needs to be found');
    	system.assert(facilities[0].Id == fac.Id, 'Find the right record');
    	system.assert(facilities[0].Company__r != null, 'The parent object/relationship needs to be there');
    	system.assert(facilities[0].Locations__r.size() > 0, 'The subquery should yield results');
	}
	static testMethod void testQueryFromFieldSet(){
		

        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c');
        soql.addFields('preview');
        system.assert(soql.getQuery().contains('__r.name'),'Expecting name field corresponding to the reference fields to be added.');    
       
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
		childRel.addFields('preview');
		soql.addChildRelationship(childRel);
		
        system.assert(soql.getQuery().substringafterlast('SELECT').contains('__r.name'),'Expecting name field corresponding to the ref fields to be added in the inner select');    

	}
	
	static testMethod void testQueryAllFieldsWithExcludes(){
		

        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c');
        Set<String> excludeFields = new Set<String> { 'Id' , 'Name', 'Company__c' } ;
        soql.addAllFields( excludeFields );
        system.debug ( soql.getQuery() ) ;
        system.assert(soql.getQuery().contains('Company__c')==false,'Expecting the Company field to be excluded');    
       
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
		childRel.addAllFields(excludeFields);
		soql.addChildRelationship(childRel);
		
        system.assert(soql.getQuery().substringafterlast('SELECT').contains('Company__c')==false,'Expecting the Company field to be excluded');    

	}
	
	static testMethod void testQueryFieldWhiteSpaces(){
		
        Boolean sawException = false;
        try
        {
 	        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c');
	        soql.addFields(new set<string>{'id',' name '});       	
        }
        catch(Exception ex)
        {
        	system.debug('Exception message'+ex.getMessage());
        	sawException = true;
        }
		
        system.assert(!sawException,'Expecting no exception due to white spaces');    

	}
	static testMethod void testPositiveOrderByClause(){
		
        Boolean sawException = false;
        try
        {
 	        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c');
	        soql.addFields(new set<string>{'id','name','period__c'});   
	        soql.setOrderBy(new map<string,soqlutil.sortOrder>{ 'CreatedDate'=>soqlutil.sortOrder.SORTASC,'Period__c' =>soqlutil.sortOrder.SORTDESC });
	        system.assert(soql.getQuery().contains('ORDER BY CreatedDate ASC,Period__c DESC') );
	        soql.removeOrderBy('CreatedDate');
	        system.assert(soql.getQuery().contains('ORDER BY Period__c DESC') );
	        
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
			childRel.addFields(new set<string>{'id','name'});
			childRel.setOrderBy(new map<string,soqlutil.sortOrder>{ 'CreatedDate'=>soqlutil.sortOrder.SORTASC,'Period_Name__c' =>soqlutil.sortOrder.SORTDESC });
	        system.assert(childRel.getSubQuery().contains('ORDER BY CreatedDate ASC,Period_Name__c DESC') );
	        childRel.removeOrderBy('CreatedDate');	
	        system.assert(childRel.getSubQuery().contains('ORDER BY Period_Name__c DESC') );
	        
	        soql.addChildRelationship(childRel);
	        //Check if Duplicates are ignored .
	        soql.setOrderBy(new map<string,soqlutil.sortOrder>{ 'CreatedDate'=>soqlutil.sortOrder.SORTASC,'Period__c' =>soqlutil.sortOrder.SORTDESC },true);
	        system.assert(soql.getQuery().contains('ORDER BY Period__c DESC,CreatedDate ASC NULLS LAST') );//Created Date gets appended as it was removed previously.And Period  gets overwritten
	        
	        		        	
	        list<sobject> sobj = database.query(soql.getQuery());
        }
        catch(Exception ex)
        {
        	system.debug('Exception message'+ex.getMessage());
        	sawException = true;
        }
		
        system.assert(!sawException,'Expecting no exception');    

	}
	static testMethod void testNegativeOrderByClause(){
		
        Boolean sawInvalidFieldException = false;
        Boolean sawInvalidFieldRemovalException = false;
        Boolean sawInvalidChildFieldException = false;
        Boolean sawInvalidChildFieldRemovalException = false;
        Boolean sawException = false;
        
        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c');
	    soql.addFields(new set<string>{'id','name','period__c'});   
        try
        {
	        soql.setOrderBy(new map<string,soqlutil.sortOrder>{ 'CreatedDate1'=>soqlutil.sortOrder.SORTASC,'Period__c' =>soqlutil.sortOrder.SORTDESC });
        }
        catch(Exception ex)
        {
        	system.debug('Exception message - Invalid Field'+ex.getMessage());
        	sawInvalidFieldException = true;
        }
        system.assert(sawInvalidFieldException,'Expecting Invalid field Exception');	        

 
         try
        {
	        soql.removeOrderBy('CreatedDate');//Created Date was never inserted succesfully in prev calls 
        }
        catch(Exception ex)
        {
        	system.debug('Exception message - Invalid Field Removal'+ex.getMessage());
        	sawInvalidFieldRemovalException = true;
        }  
        system.assert(sawInvalidFieldRemovalException,'Expecting Invalid Field Removal Exception');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
 		childRel.addFields(new set<string>{'id','name'});
        
        try
        {
			childRel.setOrderBy(new map<string,soqlutil.sortOrder>{ 'CreatedDate1'=>soqlutil.sortOrder.SORTASC,'Period_Name__c' =>soqlutil.sortOrder.SORTDESC });
        }	
        catch(Exception ex)
        {
        	system.debug('Exception message - Invalid Child Field '+ex.getMessage());        	
        	sawInvalidChildFieldException=true;
        }   
         system.assert(sawInvalidChildFieldException,'Expecting Invalid Child Field  Exception');
              
        try
        {
   	        childRel.removeOrderBy('CreatedDate');	
   	
        }   
        catch(Exception ex)
        {
        	system.debug('Exception message - Invalid Child Field Removal'+ex.getMessage());
        	sawInvalidChildFieldRemovalException = true;
        } 
        system.assert(sawInvalidChildFieldRemovalException,'Expecting Invalid Child Field Removal Exception');
        
        try
        {
        list<sobject> sobj = database.query(soql.getQuery());
        }
        catch(Exception ex){
          	system.debug('Exception message - Invalid Field Removal'+ex.getMessage());
        	sawException = true;      	
        }		
        system.assert(!sawException,'Expecting no other exception');    

	}
	static testMethod void testLimitedAccessibility(){
		
		Map<String,ID> profiles = new Map<String,ID>();
        List<Profile> ps = [select id, name from Profile where name =  'Standard User' or name = 'System Administrator'];
	    for(Profile p : ps){
	    	profiles.put(p.name, p.id);
	    }
		
		// Create the user to be used in this test. 
        // First make a new user. 
        User standard = new User(alias = 'standt',
        email='standarduser@testorg.com',
        emailencodingkey='UTF-8',
        lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US',
        profileid = profiles.get('Standard User'),
        timezonesidkey='America/Los_Angeles',
        username='standarduser@testorg.com'+System.currentTimeMillis());
        insert standard;
        
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        Facility__c fac = fuel.facility;
        Location__c loc = fuel.location;
        
        system.runas(standard){
        	SOQLUtil.overrideFLS = null;
        	
	        SOQLUtil soql = new SOQLUtil('Facility__c', true);
	        soql.addFields(new set<string>{'Company__c'});
	        soql.addFields('MRPRun_RO');
	        soql.addField('Company__r.Name');
	        soql.addAllFields();    
	        soql.setWhereClause('Company__c = \'' + company.Id + '\'');
	        system.assert(soql.getWhereClause() == 'Company__c = \'' + company.Id + '\'');
	       
	    	
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Locations__r');
			childRel.addField('Id');
			childRel.addFields(new set<string>{'Id', 'Name'});
			childRel.addAllFields();
			childRel.setWhereClause('Facility__c = \'' + fac.Id + '\'');   	
	    	childRel.getWhereClause();
	    	childRel.setLimit(1);
	    	system.assert(childRel.getLimit() == 1);
	    	
	    	boolean accessibleFields = true;
	    	try{
	    		Database.query(soql.getQuery());
	    	}catch(Exception ex){
	    		accessibleFields = false;
	    	}

			system.assert(!accessibleFields); 
        }
	}
	
    static testMethod void testNegativeQuery() {
        
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        Facility__c fac = fuel.facility;
        Location__c loc = fuel.location;
        
        boolean badObject = false;
        SOQLUtil soql;
        try{
        	soql = new SOQLUtil('BadObject');
        }catch(Exception ex){
        	badObject = true;
        }
        system.assert(badObject);
        
        soql = new SOQLUtil('Facility__c');
        
        boolean badField = false;
        try{
        	soql.addField('BadField');
        }catch(Exception ex){
        	badField = true;
        }
        system.assert(badField);
        
        boolean badFieldSet = false;
        try{
        	soql.addFields('BadFieldSet');
        }catch(Exception ex){
        	badFieldSet = true;
        }
        
        soql.setWhereClause('BadWhereClause');
        boolean badQueryResult = false;
        try{
        	List<Facility__c> facs = soql.returnQueryResult();
        }catch(Exception ex){
        	badQueryResult = true;
        }
        system.assert(badQueryResult);
        
        soql.addField('Id');
        soql.setWhereClause(null);
        badQueryResult = false;
        string exceptionMsg;
        try{
        	List<Facility__c> facs = soql.returnQueryResult();
        }catch(Exception ex){
        	exceptionMsg = ex.getMessage();
        	badQueryResult = true;
        }
        system.assert(!badQueryResult, exceptionMsg);
        
    }
    
    static testMethod void testParseSubquery(){
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        Facility__c fac = fuel.facility;
        Location__c loc = fuel.location;
        
        SOQLUtil soql = new SOQLUtil('Facility__c');
        soql.addFields(new set<string>{'Company__c'});
        soql.addFields('MRPRun_RO');
        soql.addField('Company__r.Name');
        soql.addAllFields();    
        soql.setWhereClause('Company__c = \'' + company.Id + '\'');
        soql.setOrderByClause('Company__c DESC');   
        system.assert(soql.getWhereClause() == 'Company__c = \'' + company.Id + '\'');
        
        String subquery = '(SELECT ID, nAme, Facility__c from Locations__r where Facility__c = ' + '\'' + fac.Id + '\'' + ' order by Name DESC limit 1)';
        SOQLUtil.ChildRelationship childRel = soql.createChildRelationship(subquery);
        soql.addChildRelationship(childRel);
        system.assertEquals(false, KSE.isEmpty(childRel));
        system.assertEquals(childRel.getWhereClause(), 'Facility__c = '+ '\'' + fac.Id + '\'');
        system.assertEquals(childRel.getOrderByClause(), 'Name DESC');
        system.assertEquals(childRel.getLimit(), 1);

    }
    
    
    static testMethod void testAggregate(){
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
		
        SOQLUtil soql = new SOQLUtil('Company__c', true, true);
        soql.addFields(new set<string>{'COUNT(Id) idCount'});
		soql.setWhereClause('Id = \'' + company.Id + '\'');
		
		list<AggregateResult> arList = database.query(soql.getQuery()); 
		system.assertEquals(1, arList.size(), 'Expected 1 Aggregate Result');
		system.assertEquals(1, arList[0].get('idCount'), 'Expected idCount to be 1.  Only 1 company in system');
            	
    }    
    
    static testMethod void testCount(){
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
		
        SOQLUtil soql = new SOQLUtil('Company__c', true, true);
        soql.addFields(new set<string>{'COUNT()'});
		soql.setWhereClause('Id = \'' + company.Id + '\'');
		Integer intCompanyCount = database.countQuery(soql.getQuery()); 
		system.assertEquals(1, intCompanyCount, 'Expected intCompanyCount to be 1.  Only 1 company in system');
            	
    }
    
    static testMethod void testForUpdate () {
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        
        SOQLUtil util = new SOQLUtil ('Company__c');
        util.addAllCustomFields();
        util.setLimit(1);
        util.setForUpdate ();
        system.assertEquals(true, util.getQuery().toLowerCase().contains('for update') );
        
        util.setOrderByClause('Name DESC'); 	
        List<Company__c> companies;
        
        try {
            companies = Database.query (util.getQuery());
            System.assert(false, 'Expected QueryException error with both for update and order by clause');
        } catch ( QueryException e) {
            system.assert(true); // Expected query exception to be thrown by the SOQL parse on executing query with for update and order by clause
        }
        
        util.unsetForUpdate ();
        system.assertEquals(false, util.getQuery().toLowerCase().contains('for update') );
        
        companies = Database.query (util.getQuery());
        system.assertEquals( 1, companies.size(), 'Expected 1 company record to be queried - queried count = ' + companies.size());
        
    }
}