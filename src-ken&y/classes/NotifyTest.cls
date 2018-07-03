/**
 * This class contains unit tests for validating the behavior of Apex classes
 */
@isTest
private class NotifyTest {

    static testMethod void chatterOnMe_test() {
		Notify.Message messages = new Notify.Message(' foo ', 'bar'); 
		Map<Id, String> ret = Notify.chatterOnMe(  new NotifyTest(), new List<Notify.Message> {messages} );
		system.assert( ret != null);
        system.assert( messages.getBody() != null );
        system.assert( messages.getTitle() != null );

        Notify.sendEmailBatchFinish( 'null', new list<Notify.Message>{messages}, null);    

    }
    
    // a few more from KSE.cls
        public static testMethod void test_KSE () { 
        System.assert( KSE.isEmpty( null ) ,' expected empty');
        System.assert( ! KSE.isEmpty( 'foo' ) ,' expected not empty');
        
        // interestingly, even in API 25 we can query the bussiness hours from the db, it's special
        
        Date d = KSE.calculateStartDate(System.Today(), 0, [select Id from BusinessHours where isDefault = true limit 1].Id);
        Date d2 = KSE.calculateStartDate(System.Today(), 1, [select Id from BusinessHours where isDefault = true limit 1].Id);
        System.assert( d.day() != d2.day() );
        
        TestFuel data = new TestFuel(); 
        system.assert( data.itemList != null);
        system.assert(  KSE.getItemJSONRecord(data.itemList[0].Name,data.company.Id, null, system.today()).Name == data.itemList[0].Name );   
        system.assert(  KSE.getItemJSON(data.itemList[0].Name).Name == data.itemList[0].Name );   
        
        system.assert( KSE.Namespace != null , ' expected empty or valid namespace ');
        
        Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
        system.assert( CustomerRecordTypes.keySet().size() > 0 ,' epxected record types');
    }
    
    public static testMethod void test_clone() {
        Account a = new Account(Name='foo');
        insert a;
        System.assert( KSE.isFieldEmpty('Name', a) == false );
        System.assert( KSE.isFieldEmpty('Industry', a) == true );
        
        Map<id, Sobject> t1 = new Map<Id,sobject>([select id,name from Account where id=:a.id ]);
        System.assert( KSE.isFieldChanging('Name', a, t1) == false );
        
        Account b = a.clone();
        b.Name = 'bar';
        t1.put( a.id, b);
        System.assert( KSE.isFieldChanging('Name', a, t1) == true );  
    } 
    
 	// simple cover KSE methods
    public static testmethod void kse_test() {
        system.assert( KSE.isEqualDecimal(10,10.000000001), 'expected to be equal' );
        
        
        KSE.areDateTimesClose( system.now(), system.now().addSeconds(9));
        system.assert(        kse.getUniqueNumberString() != null);
        
        INteger i = KSE.getTimeDifference();
        system.assert( i > -1);
        TestFuel data = new TestFuel(); 
        system.assert( data.itemList != null);
        
        KSE.Sortable s = new KSE.Sortable(data.itemList);
        s.addSortField( 'Id', 'ASC');
        system.assert( s.getSortedList() !=null );
        
        KSE k = new KSE( new ApexPages.StandardController(new Account()));
        system.assert(KSE.addQuantityToField(1.1, 1.3) < 99);
        system.assert(KSE.addQuantityToField(null, 1.3) < 99);
        system.assert(KSE.addQuantityToField(1.1, null) < 99);
        system.assert(KSE.subtractDecimals(1.1, 1.3) != 0 );
        system.assert(KSE.subtractDecimals(null, 1.3) != 0 );
        system.assert(KSE.subtractDecimals(1.1,null) != 0 );
        
         
        set<id> tmp = kse.grepIdSetFromList( data.itemList);
        system.assert( tmp.size()> 0 );
        
        tmp = kse.grepRelatedIdSetFromList(data.itemList, 'Company__c');
        system.assert( tmp.size()> 0 );
        
        list<sobject> tmpList = kse.grep(data.itemList, 'Company__c', 'null');
        system.assert( tmpList.size() == 0 );
        
        
       // tmpList = kse.grep(data.itemList, 'Company__c', 'null');
        //system.assert( tmpList.size() == 0 );
        
        
    }   
    
    public static testmethod void kse_test_email() {
        
        KSE.sendEmailBatchCompletion('msg');
        string nam = 'tst12345687909765431aa';
        EmailTemplate et = new EmailTemplate(
            FolderId = UserInfo.getUserId(),
            developername = nam, 
            name = nam,
            BODY = 'sdf',
            templateType = 'Text'
        );
        insert et;
        KSE.sendEmailAfterBatchCompletion( nam);
    }

}