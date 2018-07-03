@isTest
public with sharing class Supplier1099PaymentsExtTest {
    @testSetup static void ts() { 
        TestFuel data = new TestFuel();    
        // these asserts cause TestFuelQuery to insert data
        system.assert(        
            data.company != null &&
            data.supplier != null &&
            data.remittosupplier != null &&
            data.cashGL != null &&
            data.bankAccount != null &&
            data.itemList != null &&
            data.periodList != null
        );
    }
    
    private static Supplier_Invoice__c createSI(String invType, Decimal invAmount){
       TestFuelQuery data = new TestFuelQuery();
       Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
       suppInv1.Company__c = data.company.id;
       suppInv1.Invoice_Type__c = invType;
       suppInv1.Date_Invoiced__c = System.now();
       suppInv1.transaction_date__c = system.now();
       suppInv1.Currency__c = data.company.Default_Transaction_Currency__c;
       suppInv1.Supplier__c = data.remittosupplier.id;
       suppInv1.Invoice_Amount__c = invAmount;
       suppInv1.Supplier_Invoice__c = invAmount + invType;
       suppInv1.Finalized__c = false;
       suppInv1.Void__c = false;
       suppInv1.historical__c = false;
       return suppInv1;
    }
    
    private static Supplier_Invoice_Line__c createSILine(Decimal invQty, Decimal invUnitPrice, 
                                        Supplier_Invoice__c si, Purchase_Order_Line__c pol){
       TestFuelQuery data = new TestFuelQuery();
       Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c();
       suppInvLine1.Supplier_Invoice__c = si.id;
       suppInvLine1.Extended_Cost__c = 50;
       suppInvLine1.Invoice_Quantity__c = invQty;
       suppInvLine1.Item__c = data.itemList[0].id;
       if(pol != null){
           suppInvLine1.Purchase_Order__c = pol.Purchase_Order__c;
           suppInvLine1.Purchase_Order_Line__c = pol.id;
       }
       suppInvLine1.Unit_Price__c = invUnitPrice; 
       suppInvLine1.Line_Type__c = 'Item';
       return suppInvLine1;
    }
    
    private static Supplier_Payment__c createSP(Decimal paymentAmount){
        TestFuelQuery data = new TestFuelQuery();
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = paymentAmount;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.transaction_date__c = system.now();
        suppPay1.Payment_Method_G__c = 'Check';
        suppPay1.Bank_Account__c = data.bankAccount.id ;
        suppPay1.Company__c = data.company.Id;
        suppPay1.Supplier__c = data.remittosupplier.id;
        suppPay1.Currency__c = data.company.Default_Transaction_Currency__c;
        suppPay1.historical__c = false;
        suppPay1.Void__c = false;
        suppPay1.Status__c = 'Applied';
        return suppPay1;
    }
    
    private static  Supplier_Payment_Line__c createSPL(Supplier_payment__c sp, Supplier_Invoice__c si){
       Supplier_Payment_Line__c payment1 = new Supplier_Payment_Line__c();
       payment1.type__c = 'Payment';
       payment1.SubTransaction_Type__c = 'Payment';
       if (si != null){
          payment1.Supplier_Invoice__c = si.id;
       }
       payment1.Supplier_Payment__c = sp.id;
       payment1.Amount__c = sp.Payment_Amount__c;
       return payment1;
    }
    
    static testMethod void testDefaultsOnPageLoad() {
        TestFuelQuery fuel = new TestFuelQuery();
        
        User_Preference__c up = new User_Preference__c();
        up.Default_Company__c = fuel.company.id;
        up.ownerID = UserInfo.getUserID();
        insert up;
        
        test.startTest();
        Supplier_Payment__c sp = new Supplier_Payment__c();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
        system.assertEquals(ext.defaultCompanyId,fuel.company.Id, 'default company is not the same');
        GridRelatedListController.GridRelatedListConfig spLinesConfig = ext.spLinesConfig;
        system.assert(spLinesConfig != null, 'spLinesConfig should not be null');
        system.assertEquals(spLinesConfig.uniqueId ,'GridSPLs', spLinesConfig);
        system.assertEquals(spLinesConfig.title ,Label.supplier_1099_payments, spLinesConfig);
        String linesConfigJson = ext.getSPLinesConfigJson();
        system.assert(linesConfigJson != null);
        test.stopTest();
    }
    
    static testmethod void testReturnURL(){
        TestFuelQuery fuel = new TestFuelQuery();
        
            User_Preference__c up = new User_Preference__c();
        up.Default_Company__c = fuel.company.id;
        up.ownerID = UserInfo.getUserID();
        insert up;
        
        test.startTest();
        Supplier_Payment__c sp = new Supplier_Payment__c();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);

        PageReference pageRef;
        Schema.DescribeSObjectResult result = Supplier_Payment__c.SObjectType.getDescribe();
        pageRef = new PageReference('/' + result.getKeyPrefix());    
        string expectedReturnUrl = pageRef.getUrl();
        
        system.assertEquals(ext.getReturnUrl(), expectedReturnUrl);
        Test.stopTest();
    }

    static testmethod void testGetSPLinesFieldList(){
        test.startTest();
        Supplier_Payment__c sp = new Supplier_Payment__c();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
        
        // no default company set up
        system.assertEquals(ext.defaultCompanyId,null);
        GridRelatedListController.GridRelatedListConfig spLinesConfig = ext.spLinesConfig;
        system.assert(spLinesConfig != null, 'spLinesConfig should not be null');
        
        // fieldinfo tests
        String fieldListStr = ext.getSPLinesFieldList();
        List<FieldInfo> fieldInfos =  (List<FieldInfo>) JSON.deserialize(fieldListStr, List<FieldInfo>.class);
        for (FieldInfo fi : FieldInfos){
           if (fi.field == 'Name'){
               system.assertEquals(fi.Title, 'Payment Line', 'fi: '+ fi);
           }
           else if (fi.field == 'Supplier_Invoice__r.Memo__c'){
               system.assertEquals(fi.Title, 'Invoice Memo', 'fi: '+ fi);
           }
           else if (fi.field =='X1099_Box_G__c'){
               List<SelectListItem> selectOptions = fi.selectList;
               for (SelectListItem sli: selectOptions){
                   system.assertNotEquals( sli.text, 'None', selectOptions);
                   system.assertNotEquals( sli.value, 'None', selectOptions);
               }
           }
           
           if (fi.field =='X1099_Box_G__c' || fi.field == 'Exclude_From_1099__c'){
               system.assertEquals(fi.editable, true, fi);
           }
           else{
               system.assertEquals(fi.editable, false, fi);
           }
        }
        test.stopTest();
     }
     
     static testmethod void testGetSPLs_1099ReportableFinalizedSPLs(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        Supplier__c supp = fuel.remittosupplier;
        supp.x1099_Box_G__c = '1 Rents';
        supp.x1099_Supplier__c = true;
        update supp;
       
        Supplier_Invoice__c si = createSI('Invoice', 80); 
        insert si;
        Supplier_Invoice_Line__c siLine = createSILine(4, 20, si, null);
        insert siLine;
        si.Status__c = 'Approved';
        si.Finalized__c = true;
        update si;
        Supplier_Payment__c sp = createSP(80); //Applied sp
        insert sp;
        Supplier_Payment_Line__c spLine = createSPL(sp,si);
        spLine.x1099_Box_G__c = '1 Rents';
        insert spLine;
        
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
        GridRelatedListController.GridRelatedListConfig spLinesConfig = ext.spLinesConfig;
        string companyIdStr = String.ValueOf (fuel.company.Id);
        String yearStr = String.ValueOf(Date.today().year());
        
        // SP not finalized
        JsonResult result = Supplier1099PaymentsExt.getSPLines(spLinesConfig, companyIdStr, yearStr);
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.total, 0, result);
        
        // SP finalized and SPL is 1099 reportable
        sp.Finalized__c = true;
        update sp;
        result = Supplier1099PaymentsExt.getSPLines(spLinesConfig, companyIdStr, yearStr);
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.total, 1, result);
            
        test.stopTest();
     }
     
     static testmethod void testGetSPLs_Not1099ReportableFinalizedSPLs(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        // supplier is not 1099 supplier
        Supplier_Invoice__c si = createSI('Invoice', 80); 
        insert si;
        Supplier_Invoice_Line__c siLine = createSILine(4, 20, si, null);
        insert siLine;
        si.Status__c = 'Approved';
        si.Finalized__c = true;
        update si;
        Supplier_Payment__c sp = createSP(80); //Applied sp
        insert sp;
        Supplier_Payment_Line__c spLine = createSPL(sp,si);
        insert spLine;
        
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
        GridRelatedListController.GridRelatedListConfig spLinesConfig = ext.spLinesConfig;
        string companyIdStr = String.ValueOf (fuel.company.Id);
        String yearStr = String.ValueOf(Date.today().year());
        // SP finalized and SPL is not 1099 reportable
        sp.Finalized__c = true;
        update sp;
        JsonResult result = Supplier1099PaymentsExt.getSPLines(spLinesConfig, companyIdStr, yearStr);
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.total, 0, result);
        test.stopTest();
     }
     
     static testmethod void testSavePaymentSPLs(){
        TestFuelQuery fuel = new TestFuelQuery();
         
        Supplier__c supp = fuel.remittosupplier;
        supp.x1099_Supplier__c = true;
        supp.x1099_Box_G__c = '1 Rents';
        update supp;
       
        Supplier_Invoice__c si = createSI('Invoice', 80); 
        insert si;
        Supplier_Invoice_Line__c siLine = createSILine(4, 20, si, null);
        insert siLine;
        si.Status__c = 'Approved';
        si.Finalized__c = true;
        update si;
        Supplier_Payment__c sp = createSP(80); //Applied sp
        insert sp;
        Supplier_Payment_Line__c spLine = createSPL(sp,si);
        insert spLine; // insert should not fail as spl gets 1099 box from supplier
        
        Supplier_Payment_Line__c spLineNew = [Select Id, x1099_Box_G__c, x1099_Relevant__c from Supplier_Payment_Line__c where Id =:spLine.Id];
        system.assertEquals(spLineNew.x1099_Box_G__c, supp.x1099_Box_G__c, spLineNew);
        system.assertEquals(spLineNew.x1099_Relevant__c, supp.x1099_Supplier__c, spLineNew);
        
        // blank out 1099 box on spl
        Boolean hasException = false;
        try{
            spLine.x1099_Box_G__c =  null;
            update spLine;
        }catch(Exception ex){
            hasException = true;
            String error = ex.getMessage();
            system.assert(error.contains(' You must select a 1099 Box value for a 1099 reportable payment line.'), ex);
        }
        system.assertEquals(hasException, true);

        sp.Finalized__c = true;
        update sp;
        
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
           
        List<Supplier_Payment_Line__c> spls = [Select Id, Exclude_From_1099__c, x1099_Box_G__c from
                       Supplier_Payment_Line__c where Id = : spLine.Id];
        Boolean newExcludeFrom1099 = false;
        if(spls[0].Exclude_From_1099__c == false){
            newExcludeFrom1099= true;
        }else{
            newExcludeFrom1099= false;
        }
        
        spls[0].Exclude_From_1099__c = newExcludeFrom1099;
        JsonResult result = Supplier1099PaymentsExt.saveSPLs(spls);
        system.assertEquals(result.success, true, result);
        
        test.stopTest();
     }
     
     static testmethod void testSaveEarnedTermsDiscountSPLs(){
        TestFuelQuery fuel = new TestFuelQuery();
         
        Supplier__c supp = fuel.remittosupplier;
        supp.x1099_Supplier__c = true;
        supp.x1099_Box_G__c = '1 Rents';
        update supp;
       
        Supplier_Invoice__c si = createSI('Invoice', 80); 
        insert si;
        Supplier_Invoice_Line__c siLine = createSILine(4, 20, si, null);
        insert siLine;
        si.Status__c = 'Approved';
        si.Finalized__c = true;
        update si;
        Supplier_Payment__c sp = createSP(80); //Applied sp
        insert sp;
        Supplier_Payment_Line__c spLine = createSPL(sp,si);
        spLine.Type__c = 'Earned Terms Discount';
        insert spLine; // insert should not fail as spl gets 1099 box from supplier
        
        Supplier_Payment_Line__c spLineNew = [Select Id, x1099_Box_G__c, x1099_Relevant__c from Supplier_Payment_Line__c where Id =:spLine.Id];
        system.assertEquals(spLineNew.x1099_Box_G__c, supp.x1099_Box_G__c, spLineNew);
        system.assertEquals(spLineNew.x1099_Relevant__c, supp.x1099_Supplier__c, spLineNew);
        
        test.startTest();
        // blank out 1099 box on spl
        Boolean hasException = false;
        try{
            spLine.x1099_Box_G__c =  null;
            update spLine;
        }catch(Exception ex){
            hasException = true;
            String error = ex.getMessage();
            system.assert(error.contains(' You must select a 1099 Box value for a 1099 reportable payment line.'), ex);
        }
        system.assertEquals(hasException, false);
        test.stopTest();
     }
     
     static testMethod void testVoidGetSPLs() {
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice_Line__c-'+Supplier_Invoice_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Company__c-'+ Company__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Period__c-'+Period__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;

        TestFuelQuery fuel = new TestFuelQuery();
        Supplier__c supp = fuel.remittosupplier;
        supp.x1099_Box_G__c = '1 Rents';
        supp.x1099_Supplier__c = true;
        update supp;

        Supplier_Payment__c sp = createSP(80); //Applied sp
        sp.Finalized__c = true;
        insert sp;
        sp.Void__c = true;
        sp.Status__c = 'Void';
        update sp;

        test.startTest();
        sp = [Select Id, Status__c, Void__c from Supplier_Payment__c where Id = :sp.Id];
        system.assertEquals(sp.Status__c, 'Void', sp);
        system.assertEquals(sp.Void__c, true,sp);
        test.stopTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
        GridRelatedListController.GridRelatedListConfig spLinesConfig = ext.spLinesConfig;
        string companyIdStr = String.ValueOf (fuel.company.Id);
        String yearStr = String.ValueOf(Date.today().year());

        JsonResult result = Supplier1099PaymentsExt.getSPLines(spLinesConfig, companyIdStr, yearStr);
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.total, 0, result);
    }
 
     static testMethod void testDatePaid_GetSPLs() {
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice_Line__c-'+Supplier_Invoice_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Company__c-'+ Company__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Period__c-'+Period__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;

        TestFuelQuery fuel = new TestFuelQuery();
        Supplier__c supp = fuel.remittosupplier;
        supp.x1099_Box_G__c = '1 Rents';
        supp.x1099_Supplier__c = true;
        update supp;

        Supplier_Invoice__c si = createSI('Invoice', 80); 
        insert si;
        Supplier_Invoice_Line__c siLine = createSILine(4, 20, si, null);
        insert siLine;
        si.Status__c = 'Approved';
        si.Finalized__c = true;
        update si;
        
        Integer year = Date.today().year();
        Supplier_Payment__c sp = createSP(80); //Applied sp
        sp.Date_Paid__c =   DateTime.newInstance(year,1,1,0,0,0);
        sp.Finalized__c = true;
        
        Supplier_Payment__c sp1 = createSP(80); //Applied sp
        sp1.Date_Paid__c =   DateTime.newInstance(year,1,1,5,0,0);
        sp1.Finalized__c = true;
        
        Supplier_Payment__c sp2 = createSP(80); //Applied sp
        sp2.Date_Paid__c =   DateTime.newInstance(year,12,31,11,59,59);
        sp2.Finalized__c = true;
        
        Supplier_Payment__c sp3= createSP(80); //Applied sp
        sp3.Date_Paid__c =   DateTime.newInstance(year+1,1,1,0,0,0); // should not show up in grid
        sp3.Finalized__c = true;
        
        List<Supplier_Payment__c> sps = new List<Supplier_Payment__c> { sp, sp1, sp2, sp3};
        insert sps;
        
        Supplier_Payment_Line__c spLine = createSPL(sp,si);
        Supplier_Payment_Line__c spLine1 = createSPL(sp1,si);
        Supplier_Payment_Line__c spLine2 = createSPL(sp2,si);
        Supplier_Payment_Line__c spLine3 = createSPL(sp3,si);
        List<Supplier_Payment_Line__c> spls = new List<Supplier_Payment_Line__c> { spLine, spLine1, spLine2, spLine3};
        
        // set 1099 box
        for (Supplier_Payment_Line__c spl:spls){
            spl.x1099_Box_G__c = '1 Rents';
        }
        insert spls;
        spls = [Select id, Name, X1099_Relevant__c from Supplier_Payment_Line__c where id in :spls];
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sp);
        Supplier1099PaymentsExt ext = new Supplier1099PaymentsExt(con);
        GridRelatedListController.GridRelatedListConfig spLinesConfig = ext.spLinesConfig;
        string companyIdStr = String.ValueOf (fuel.company.Id);
        String yearStr = String.ValueOf(year);

        JsonResult result = Supplier1099PaymentsExt.getSPLines(spLinesConfig, companyIdStr, yearStr);
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.total, 3, '>>> result: ' + result + '>>> sps: ' + sps);
        Test.stopTest();
    }
}