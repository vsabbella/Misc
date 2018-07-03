/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UtilityTests {

    /* 
    * tests for ArrayUtils.cls 
    */
    static testMethod void test_getIntegerList(){
       
        List<integer> tmp = ArrayUtils.getIntegerList('1,2,22.0,3,twelve');
        
        System.assertEquals( new List<Integer>{22,3,2,1}, tmp);
        System.assertEquals( new List<Integer>{1,2,3,22}, ArrayUtils.reverse(tmp) );
        System.assertEquals( null, ArrayUtils.reverse(null) );

    }
    
    static testMethod void test_sortList(){
        insert New Account(Name='foo');
        insert new Account(Name='bar');
        List<Account> accList = [select Name,AccountNumber from Account limit 100];
        ArrayUtils.sortList(accList,'Name', 'ASC');
        String lastValue = '';
        String currentValue = '';      
        
        for (Account acc : accList) {
               currentValue = acc.Name;
               System.assertEquals( currentValue.compareTo(lastValue) >= 0, true);
               lastValue = currentValue;
        }
    }
    
    static testMethod void test_sortList_desc(){
        Account foo =  New Account(Name='foo');
        Account bar = new  Account(Name='bar');
        insert foo; insert bar; 
        Contact a = new Contact(Accountid=foo.id, lastname='gack');
        Contact b = new Contact(Accountid=bar.id, lastname='zack');
        insert a; 
        insert b;
        List<Contact> accList = [select lastname, account.Name  from contact limit 100];
        ArrayUtils.sortList(accList,'Account.Name', 'ASC');
        String lastValue = 'aaaa';
        String currentValue = '';      
        
        for (Contact acc : accList) {
               currentValue = acc.account.name;
               
               System.assertEquals( currentValue.compareTo(lastValue) >= 0, true);
               lastValue = currentValue;
        }
        
        ArrayUtils.sortList(accList,'Account.Name', 'desc');
        lastValue = 'zzzz'; 
        for (Contact acc : accList) {
               currentValue = acc.account.name;
               
               System.assertEquals( currentValue.compareTo(lastValue) < 0, true);
               lastValue = currentValue;
        }
    }
    
    // Nettable.cls 
    static testmethod void test_Nettable() { 
        TestData data = new TestData();
        SKID__c skid = new SKID__c(
            location__c = data.location.id, 
            Quantity__c = 101.0,
            Item__c= data.itemList[0].id,
            Type__c = 'Location',
            Company__c = data.company.Id
            );
        insert skid;
        
        Location__c location3 = new Location__c(); 
        location3.facility__c = data.facility.id; 
        location3.name = 'mrb';
        location3.Nettable__c = true;
        insert location3;    
        
        skid = new SKID__c(
            location__c = location3.id, 
            Quantity__c = 99.0,
            Item__c= data.itemList[0].id,
            Type__c = 'Location',
            Company__c = data.company.Id
            );
        insert skid;
        
        Map < Id, Nettable.NETcount > tmpMap = Nettable.getNettable(data.itemList);
        
        system.assertEquals(101.0, tmpMap.get( data.itemList[0].id).nonnettable );
        system.assertEquals(99.0, tmpMap.get( data.itemList[0].id).nettable );
    }
    
    
    /**
     * tests MiniDetail.cls
     */
    public static testmethod void test_MiniDetail() {
        MiniDetail m = new MiniDetail(); 
        TestData d = new TestData(); 
        m.field_set_name = 'Overview';
        m.subjectId = d.customer.id;
        system.assert(m.getFields().size() > 0);        
        system.assert(m.getSubjectRecord() !=null);
        system.assert(m.viewDetail() !=null);
    }    
}