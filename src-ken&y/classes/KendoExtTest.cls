@isTest
private class KendoExtTest{
    
    public class TestRelatedFilterLimiter implements KendoExt.I_RelatedFilterLimiter {
        KendoExt.LoadRecordsRelatedFilterInfo filterInfo;
        
        public void setLoadRecordsRelatedFilterInfo(KendoExt.LoadRecordsRelatedFilterInfo filterInfo) {
            this.filterInfo = filterInfo;
        }
        
        public Boolean hasRelevantIds() {
            return filterInfo.relatedFilterValues.containsKey('id');
        }
        
        public Set<Id> getRelevantIds() {
            Id conId = (Id)filterInfo.relatedFilterValues.get('id');
            Set<Id> ids =  new Set<Id>();
            for (Contact con : [Select AccountId from Contact Where Id =:conId]) {
                ids.add(con.AccountId);
            }
            return ids;
        }
    }
    
	static Account account {
	    get {
	      if (account == null) {
            	account = new Account();
                account.name = 'Kenandy';
                account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
                account.billingcity = 'Redwood City';
                account.billingstate = 'CA';
                account.billingpostalcode = '94065';
                account.billingcountry = 'USA';
                account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
                account.shippingcity = 'Redwood City';
                account.shippingstate = 'CA';
                account.shippingpostalcode = '94065';
                account.shippingcountry = 'USA';
                account.phone = '650-468-2000';
                account.fax = '650-468-2010';
                account.website = 'kenandy.com';
                insert account;          
	      }  
	      return account;
	    } set;
	}
	
	// trivial dumb methods which are required to be covered and used by vf
	testMethod static void justForCoverage(){
	    ApexPages.StandardSetController cons;
	    System.assertEquals(KSE.NameSpace, new KendoExt(cons).getNameSpace());
	    ApexPages.StandardController con;
	    System.assertEquals(KSE.NameSpaceUU, new KendoExt(con).getNameSpacePrefix());
	}
    
    // TODO: doing positive test only, seeing the time crunch, but covers 100% code of KendoExt, more combinations of tests to add later
    testMethod static void testLoadRecords() {
        // Need to force getter
		Account testAcc = account;
        
        KendoExt.LoadRecordsContext ctx = new KendoExt.LoadRecordsContext();
        ctx.orderByField = 'Name';
        ctx.recordLimit = 1;
        ctx.textFieldName = 'Name';
        ctx.valueFieldName = 'Id';
        ctx.sortOrder = 'asc';
        ctx.sobjectName = 'Account';
        ctx.criterias = new List<Map<String, String>>{new Map<String, String>{
        					'field' => 'Name',
                            'operator' => 'like',
                            'value'	=> account.Name,
                            'wrapValueInQuotes' => 'true'
        				}}; 
        Object[] results = KendoExt.loadRecords(ctx);  
        System.assertEquals(1, results.size());
        
        Account accRes = (Account)results[0];
        System.assertEquals(account.Id, accRes.Id, 'Account should come back correctly');
        
    }
    
    
    testMethod static void testLoadRecordsWithRelatedFilterInfo() {
        Contact con = new Contact(FirstName = 'Abhinav', LastName = 'Gupta');
        insert con;
        
        KendoExt.LoadRecordsContext ctx = new KendoExt.LoadRecordsContext();
        ctx.orderByField = 'Name';
        ctx.recordLimit = 1;
        ctx.textFieldName = 'Name';
        ctx.valueFieldName = 'Id';
        ctx.sortOrder = 'asc';
        ctx.sobjectName = 'Account';
        ctx.criterias = new List<Map<String, String>>{new Map<String, String>{
        					'field' => 'Name',
                            'operator' => 'like',
                            'value'	=> account.Name,
                            'wrapValueInQuotes' => 'true'
        				}}; 
        ctx.filterInfo = new KendoExt.LoadRecordsRelatedFilterInfo();
        ctx.filterInfo.relatedFilterLimiter = String.isBlank(KSE.NameSpace) ? 'KendoExtTest.TestRelatedFilterLimiter' : Kse.NameSpace + '.KendoExtTest.TestRelatedFilterLimiter';
        ctx.filterInfo.relatedFilterValues = new Map<String, Object>{'id' => con.Id};
        
        Object[] results = KendoExt.loadRecords(ctx);  
        // No results as the associated contact is missing account id
        System.assertEquals(0, results.size());
        
        
        con.AccountId = account.id;
        update con;
        results = KendoExt.loadRecords(ctx);  
        // Results should come as we have contact associated with account id
        System.assertEquals(1, results.size());
        
    }
    
    
}