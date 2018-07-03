@isTest
public with sharing class StaticResourcesTest {    
    static testMethod void testGLTypeLoad(){
        Testfuel fuel = new Testfuel();
        system.assert(fuel.GLTypeTestData.size() == 12, 'fuel.GLTypeTestData:'+fuel.GLTypeTestData);
    }
    
    static testMethod void testmGLTypes(){
        Testfuel fuel = new Testfuel();
        system.assert(fuel.mGLTypes.size() == 12, 'fuel.mGLTypes:'+fuel.mGLTypes);
    }
        
    static testMethod void GLAccountListTestData(){
        Testfuel fuel = new Testfuel();
        system.assertEquals(38,fuel.GLAccountList.size());//, 'fuel.GLAccountList:'+fuel.GLAccountList);
    }
    
    static testMethod void GLAccountTestData(){
        Testfuel fuel = new Testfuel();
        system.assertEquals(47,fuel.GLAccountTestData.size());//, 'fuel.GLAccountTestData:'+fuel.GLAccountTestData);
    }
    
    static testMethod void testmGLAccounts(){
        Testfuel fuel = new Testfuel();
        system.assertNotEquals(null, fuel.mGLAccounts.get('11000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('11000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('12000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('12000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('12100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('12100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('12500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('12500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('14000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('14000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('15000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('15000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('15100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('15100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('17000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('17000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('21000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('21000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('22000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('22000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('22500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('22500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('23000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('23000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('23100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('23100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('23500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('23500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('24000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('24000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('24100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('24100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('28000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('28000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('38000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('38000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('39000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('39000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('41000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('41000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('42000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('42000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('48000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('48000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('49000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('49000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('50000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('50000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('51000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('51000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('52000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('52000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('52100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('52100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('55100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('55100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('55000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('55000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('56000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('56000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('58500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('58500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('59000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('59000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('59100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('59100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('61000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('61000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('62000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('62000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('65000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('65000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('79000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('79000'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('89020'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('89020'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('79500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('79500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('99998'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('99998'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('12200'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('12200'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('12300'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('12300'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('12400'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('12400'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('14100'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('14100'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('21500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('21500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('11500'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('11500'));
        system.assertNotEquals(null, fuel.mGLAccounts.get('29000'), 'fuel.mGLAccounts:'+fuel.mGLAccounts.get('29000'));
        
        system.assertEquals(47, fuel.mGLAccounts.size());
        
    }
    
    static testMethod void testcurrentAssets(){
        Testfuel fuel = new Testfuel();
        system.assertEquals('10000',fuel.currentAssets.get('Account_Range_From__c'), 'fuel.currentAssets:'+fuel.currentAssets);
    }
  }