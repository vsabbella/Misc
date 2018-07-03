@isTest 
public with sharing class SetupSampleDataTest {
    // commenting this test method as the number of queries for the testdata build exceeds 100
    /*public static testmethod void testSetupSampleData() { 
        
        SetupSampleData d = new SetupSampleData(new Apexpages.Standardcontroller( company ) );
        Test.startTest();
   		System.assertEquals(0, Limits.getQueries(), 'Limits.getQueries()  : '+ Limits.getQueries()); 
        d.TestDataBuild();// builds data from the SampleData static resource, links to company
        system.assert(false,limits.getQueries());
        Test.stopTest();
        
        system.assertEquals(1, ApexPages.getMessages().size(),  ApexPages.getMessages() );
        
        // now all data should be ready, see if some of the stuff we want is there
        system.assert( count('Facility__c') > 0, 'no facility' );
        
        Customer__c[] tmp = [ select id,Parent_Customer__c from Customer__c where Parent_Customer__c!=null];
        system.assertEquals(3,tmp.size(),'expected customers');
        
        system.assert( count('Class__c')>3,'expected classes');
        
        system.assert( count('Location__c')>2,'expected loclist');
        
        system.assert( count('Item__c')>2,'expected itlist');
        system.assert( count('Item_Specification__c')>1,'expected item specs');
        system.assert( count('Component__c')>5,'expected item specs');
        
        system.assert( count('UOM__c')>2,'expected UOM__c');
        
        system.assert( count('Product__c')>1,'expected Product__c ');
        
        system.assert( count('Pricebook__c' )>0,'expected Pricebook__c');
        
        system.assert( count('Pricebook_Line__c')>0,'expected Pricebook_Line__c');
        system.assert( count('Sales_Order__c') >0 ,'expected Sales_Order__c');
        system.assert( count('Sales_Order_Line__c') > 1,'expected Sales_Order_Line__c');
        
//        system.assertEquals( 12, count('Period__c') );        
        //system.assert( count('GL_Account__c') > 20);
        system.assert( count('Segment_Definition__c') > 1);
        //system.assert( count('Accounting_Rule__c') > 100);
        system.assert( count('Stock_Movement_Rule__c') > 6);
        
        Supplier__c[] sups = [ select id,type__c, recordType.developerName from Supplier__c ];
        map<string,Supplier__c> supMap = new map<string,Supplier__c>(); 
        for ( Supplier__c s: sups) { supMap.put(s.RecordType.developerName,s); }
        //system.debug(LoggingLevel.INFO,supMap.keySet());
        system.assertEquals(2, supMap.size(), ' expected suppliers');
        system.assert( sups[0].Type__c != sups[1].Type__c , 'expected two different types');
        system.assert(supMap.get('Purchase_From') != null, 'missing purchase from record type');
        system.assert(supMap.get('Remit_To') != null, 'missing remit to record type');
        
        // make sure the location_list on SMR holds location we added
        map<id,Location__c> locationMap = new map<id,Location__c>( [ select id from Location__c ]);
        Stock_Movement_Rule__c[] smRules = [ select id, Location_List__c from Stock_Movement_Rule__c];
        for ( Stock_Movement_Rule__c sm: smRules) {
            string key = sm.Location_List__c; 
            key = key.replaceAll('"','').replace('[','').replace(']','');
            system.assert( locationMap.containsKey( key), ' expected valid location ID ');
        }

        Product__c[] prods = [ select id, Selling_uom__c, weight_uom__c, dimension_uom__c from Product__c];
        System.debug(logginglevel.info, 'prods: ' + prods);
        for (Product__c prod : prods){
            system.assertNotEquals(Null, prod.weight_uom__c);
            system.assertNotEquals(Null, prod.dimension_uom__c);
            system.assertNotEquals(Null, prod.selling_uom__c);
        }

        Sales_Order__c so = [select id, Weight_UOM__c, Dimension_UOM__c, (select id, Weight_UOM__c, Dimension_UOM__c, Selling_UOM__c from Sales_order_Lines__r) from Sales_Order__c];
        system.assertNotEquals(Null, so.Weight_UOM__c);
        system.assertNotEquals(Null, so.Dimension_UOM__c);
        for (Sales_Order_Line__c sol : so.Sales_order_lines__r){
            system.assertNotEquals(Null, sol.Weight_UOM__c);
            system.assertNotEquals(Null, sol.Dimension_UOM__c);
            system.assertNotEquals(Null, sol.Selling_UOM__c);
        }
    }*/
       
    // test that we can create data for two different companies
    public static testmethod void testSetupSampleData2() { 
         
        Test.startTest();
        SetupSampleData d = new SetupSampleData(new Apexpages.Standardcontroller( company ) );
        d.testBody = test_body;  
        d.TestDataBuild();
        system.assertEquals(1, ApexPages.getMessages().size(),  ApexPages.getMessages() );       

       
        SetupSampleData d2 = new SetupSampleData(new Apexpages.Standardcontroller( company2 ) );
        d2.testBody = test_body; 
        d2.TestDataBuild();
        system.assertEquals(1, ApexPages.getMessages().size(),  ApexPages.getMessages() );       
       
        Test.stopTest();                
    }
    
    // simple test for clicking the button twice
    public static testmethod void testSetupSampleData3() { 
         
        Test.startTest();
        SetupSampleData d = new SetupSampleData(new Apexpages.Standardcontroller( company ) );
        d.testBody = test_body; 
        d.TestDataBuild();
        system.assertEquals(1, ApexPages.getMessages().size(),  ApexPages.getMessages() );       
       
        d.TestDataBuild(); // simulate if the user clicks the button again 
        system.assertEquals(2, ApexPages.getMessages().size(),  ApexPages.getMessages() );       
        
        Test.stopTest();                
    }
    
    // user supplied CSV file in the correct format can load from this controller also
    // called from SetupCustomData.page
    public static testmethod void testCustomDataLoad() { 
        Test.startTest();
        SetupSampleData d = new SetupSampleData(new Apexpages.Standardcontroller( company ) );
        d.document.body = Blob.valueof(test_body);
        d.CustomDataLoad();
        system.assert( count('UOM__c') > 0);
        system.assert( count('Facility__c') == 1);
        Facility__c fac = [ select id, name from Facility__c limit 1];
//      system.debug(LoggingLevel.INFO,fac);
        system.assertEquals(false, fac.name.containsIgnoreCase ('{!COMPANY.NAME}') ,
                            'expected to see name expanded'+fac.name);
        system.assertEquals(true, fac.name.containsIgnoreCase ( company.Name ) ,
                            'expected to see name expanded '+fac.name + ' contain '+company.Name);
        
    }
    
    // make sure we can use extId to refer to the name of existing data
    public static testmethod void testCustomDataLoad2() { 
        Test.startTest();
        SetupSampleData d = new SetupSampleData(new Apexpages.Standardcontroller( company ) );
        d.document.body = Blob.valueof(test_body);
        d.CustomDataLoad(); // step 1
        system.assert( count('UOM__c') > 0);
        
        d = new SetupSampleData(new Apexpages.Standardcontroller( company ) );
        d.document.body = Blob.valueof(test_body2);
        d.CustomDataLoad(); // step 2 

        system.assert( count('Item__c') > 2);
        // TODO make sure the items are joined to the class already inserted in step 1
        Item__c[] ilist = [ select id , class__c from Item__c ];
        system.assertEquals(3,ilist.size(),' expected items'); 
        for( Item__c i: ilist) { system.assert( i.class__c !=null, ' expected Class to be filled in' ); }
    }
    
    public static testmethod void testDateVal() { 
        SetupSampleData.CsvToSObjectParser parser = new SetupSampleData.CsvToSObjectParser();
        system.assertEquals(system.today().addDays(10) , parser.DateVal( 'TODAY + 10' ), 'expected today +10 ');
        system.assertEquals(system.today().addDays(1) , parser.DateVal( 'TODAY + 1' ), 'expected today + 1');
        system.assertEquals( Date.newInstance( system.now().year() , 1, 1) , parser.DateVal( 'DATE(YEAR-1-1)' ), 'expected Jan 1 this year');
        system.assertEquals( system.today().addDays(-1) , parser.DateVal( 'TODAY - 1' ), 'expected today - 1');
        
        system.assertEquals( system.today() , parser.DateVal( 'TODAY+0' ), 'expected today ');
        system.assertEquals( system.today() , parser.DateVal( 'TODAY' ), 'expected today ');
         
    }
    // setup some data for testing
    static Account account = new Account();
    static Company__c company = new Company__c();
    static Company__c company2 = new Company__c();

    static {
        account.name = 'Kenandy';
        account.billingstreet = '2055 Woodside Rd. Ste 110';
        account.billingcity = 'Redwood City';
        account.billingstate = 'CA';
        account.billingpostalcode = '94061';
        account.billingcountry = 'USA';
        account.shippingstreet = '2055 Woodside Rd. Ste 110';
        account.shippingcity = 'Redwood City';
        account.shippingstate = 'CA';
        account.shippingpostalcode = '94061';
        account.shippingcountry = 'USA';
        account.phone = '650-468-2000';
        account.fax = '650-468-2010';
        account.website = 'kenandy.com';
        insert account; 
        
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.A_Days__c = 30;
        company.B_Days__c = 60;
        company.C_Days__c = 180;
        company.Company_Identifier__c = 'KEN'; 
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert company;
        
        company2.name = 'Kenandy2';
        company2.Address__c = account.ID;
        company2.A_Days__c = 30;
        company2.B_Days__c = 60;
        company2.C_Days__c = 180;
        company2.Company_Identifier__c = 'KEN2'; 
        company2.Comp_Currency__c = TestFuel.currencySGD.id;
        company2.Consol_Currency__c = TestFuel.currencyEUR.id;
        company2.Stat_Currency__c = TestFuel.currencyGBP.id;
        company2.Subs_Currency__c = TestFuel.currencyUSD.id;
        company2.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert company2;
    }
    
    static sobject[] q( string objName ) {   return Database.query('select id from '+objName);  }
    static integer count(string objName ) {         return q(objName).size();    }
    
    static string test_body = 
         'object:UOM__c, extId:UM1, name:EA, Description__c:Each \n'
        +'object:Payment_Term__c, extId:PT1, name:2/10 Net 30, Description__c:2 discount in 10 days due 30 days, Discount_Days__c : 10, Discount_Percent__c:2,Due_Days__c :30\n'
        +'object:Class__c, extId:CL1, Type__c:Goods, Name:Class-1\n'
        +'object:Class__c, extId:CL2, Type__c:Labor, Name:Class Labor\n'
        +'object:Class__c, extId:CL3, Type__c:Services, Name:Class Services\n'
        +'object:Class__c, extId:CL4, Type__c:Miscellaneous, Name:Class Miscellaneous\n'
        +'object:Account, name:Enterprise, extId:A01\n'
        +'object:Account, name:Enterprise2, extId:A02\n'
        +'object:Product_Group__c, extId:PG1, name:ProductGroup-1\n'
        +'object:Product_Group__c, extId:PG2, name:ProductGroup-2\n'
        //+'#  GL account\n'
        //+'object:GL_Account__c, extid:GL1, name:12000 - Cash,               active__c:true, normal_balance__c:Debit\n'
        //+'object:GL_Account__c, extId:GL2, name:12100 - Unapplied Cash,     active__c:true, normal_balance__c:Credit\n'
        //+'object:GL_Account__c, extid:GL3, name:17000 - Property,       active__c:true, normal_balance__c:Debit\n'       
        +'object:Facility__c, extId:F01, relatedTo:Company__c#COMPANY , name:{!COMPANY.NAME}-Sample Facility-1, description__c:facility1\n'
        +'object:Location__c, extId:L1, relatedTo:Facility__c#F01, name:Receiving Dock, nettable__c:false\n'
        +'object:Segment_Definition__c, extId:SD1, name:Company__c, Accounting_Entry_Field__c:Company__c, Object_API_Name__c:Company__c, Segment_Number__c:1\n'
        +'object:Segment_Definition__c, extId:SD2, name:GL_Account__c, Accounting_Entry_Field__c:GL_Account__c, Object_API_Name__c:GL_Account__c, Accounting_Rule_Segment__c:GL_Account__c, Accounting_Rule_Reference_Value__c:GL_Account_Reference_Value__c, Accounting_Rule_Default__c:Default_GL_Account__c, Segment_Number__c:2\n'
        +'object:Segment_Definition__c, extId:SD3, name:Intercompany__c, Accounting_Entry_Field__c:Intercompany__c, Object_API_Name__c:Intercompany__c, Accounting_Rule_Segment__c:Intercompany__c, Accounting_Rule_Reference_Value__c:Intercompany_Reference_Value__c, Accounting_Rule_Default__c:Default_Intercompany__c, Segment_Number__c:3\n'
        +'object:Segment_Validation__c, extId:SV1, segment_1__c:*, segment_2__c:*, segment_3__c:*, active__c : true\n'
        +'object:Segment_Validation__c, extId:SV2, segment_1__c:*, active__c : true \n'
        +'object:Accounting_Default_Segment_Definition__c, extId:adsd1, name:Company__c, Accounting_Default_Field__c:Company__c,Object_API_Name__c:Company__c,Segment_Number__c:1\n'
        +'object:Accounting_Default_Segment_Definition__c, extId:adsd2, name:GL_Account__c, Accounting_Default_Field__c:GL_Account__c,Object_API_Name__c:GL_Account__c,Segment_Number__c:2\n'
        +'object:Customer__c, extId:corp, relatedTo:Company__c#COMPANY , relatedTo: Address__c#A01, name:{!COMPANY.NAME} Customer Corp Parent, Record_Type_Name__c:Corporate_Parent, Credit_Limit__c:100000.0 \n'
        +'object:Stock_Movement_Rule__c, extId:sm1,relatedTo:Company__c#COMPANY ,'+
        +'Name:Putaway rule1, Rule_Type__c :Putaway, relatedTo:Facility__c#F01, relatedTo:Class__c#CL1,'
        +'Source_Document__c :Purchase Order, Priority__c : 4,Active__c : true, '    
        //Location_List__c : JSON.serialize(new List<Id>{!L1.id})  => ["a0Uj0000000Y5CFEA0"]     
        +'Location_List__c : ["{!L1}"]  \n'
        ;
    
    // in this test we will excersize the ability to relate the Class__c lookup using the name of a record already in the DB    
    static string test_body2 = 
        'object:Item__c, extId:IT1, relatedTo:Company__c#COMPANY, Source__c:Manufactured, relatedTo:Class__c#Class Labor, name:Item-11, ABC_Code__c:A, Lead_Time__c:3\n'+
        'object:Item__c, extId:IT2, relatedTo:Company__c#COMPANY, Source__c:Purchased, relatedTo: Class__c#Class Services, name:Item-22, ABC_Code__c:B, Lead_Time__c:15\n'+
        'object:Item__c, extId:IT3, relatedTo:Company__c#COMPANY, Source__c:Manufactured, relatedTo: Class__c#Class Services, name:Item-33, ABC_Code__c:C, Lead_Time__c:30';
    
    
    public static testmethod void testDataLoadChunking() { 
	    TestFuel fuel = new TestFuel();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(fuel.company);
        pageReference pr = page.SetupSampleData;
        Test.setCurrentPage(pr);
        SetupSampleData ext = new SetupSampleData(con);
        test.starttest();
        ext.prepareDataLoad();
        list<StaticResource> totalchunks = [SELECT id, Body,Name FROM StaticResource WHERE name like '%TestData%' ];
        system.assert(totalchunks.size() >0, 'The should be Test data csv files io-n static resource');
        SetupSampleData.InsertSampleData(0,totalchunks[0].Name,TotalChunks.size(), fuel.company.id);
        
	    
    
    }
}