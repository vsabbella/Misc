@isTest
public class InvoiceGroupingRulesExtTest {

	@testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null && 
            data.altCompany != null && 
            data.salesOrder != null && 
            data.salesOrderLines != null &&
            data.terms != null &&
            data.customerBillTo != null &&
            data.agreement != null &&
            data.agreementLine != null &&
            data.customerParent != null &&
            data.CALENDAR_MONTH != null &&
            data.WEEK != null && 
            data.CALENDAR_QUARTER != null && 
            data.customerSoldTo != null &&
            data.product != null && 
            data.crossRef != null
        );
    }
    public void  InvoiceGroupingRulesExtTest(){}
    
    class IGRData{
        TestFuelQuery fuel = new TestFuelQuery();
        
        list<Invoice_grouping_rule__c> igrList {
            get{
                igrList= new list<Invoice_grouping_rule__c> ();
                Invoice_grouping_rule__c igr1= new Invoice_grouping_rule__c();
                igr1.Company__c =fuel.company.id;
                igr1.End_Date__c =system.today()+100;
                igr1.Start_Date__c =system.today()-100;
                igr1.Group_By_Agreements__c = true;
                igr1.Group_By_Sales_Orders__c = true;
                igr1.For_Customers__c  = JSON.serialize(new set<Id>{fuel.customerParent.id});
                igr1.Group_By_Sales_Orders__c = true;
                igrList.add(igr1);
                
                Invoice_grouping_rule__c igr2= new Invoice_grouping_rule__c();
                igr2.Company__c =fuel.company.id;
                igr2.End_Date__c =system.today()+100;
                igr2.Start_Date__c =system.today()-100;
                igr2.Group_By_Sales_Orders__c = true;
                igr2.Group_By_Category__c = true;
                igr2.For_Customers__c  = JSON.serialize(new set<Id>{fuel.customerParent.id});
                igr2.Group_By_Sales_Orders__c = true;
                igrList.add(igr2);
                
                Invoice_grouping_rule__c igr3= new Invoice_grouping_rule__c();
                igr3.Company__c =fuel.company.id;
                igr3.End_Date__c =system.today()+200;
                igr3.Start_Date__c =system.today()+100;
                igr3.Group_By_Agreements__c = true;
                igr3.Group_By_Category__c = true;
                igr3.For_Customers__c  = JSON.serialize(new set<Id>{fuel.customerParent.id});
                igr3.Group_By_Sales_Orders__c = true;
                igrList.add(igr3);   
                
                Invoice_grouping_rule__c igr4= new Invoice_grouping_rule__c();
                igr4.Company__c =fuel.company.id;
                igr4.End_Date__c =system.today()+100;
                igr4.Start_Date__c =system.today()-100;
                igr4.Group_By_Agreements__c = true;
                igr4.Group_By_Sales_Orders__c = true;
                igr4.For_Customers__c  = JSON.serialize(new set<Id>{fuel.customerParent.id, fuel.customerSoldTo.Id});
                igrList.add(igr4);
                
                insert igrlist;
                
                return igrList;
            }
            set{}
        }
        
        
    }
    
    static testMethod void TestgetIGRs(){
        TestFuelQuery fuel = new TestFuelQuery();
        IGRData i= new IGRData();
        integer countRecs=i.igrlist.size();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        system.assertequals( jr.records.size(),countRecs );
        // Test Rank Assignment minor change
        
        // check rank should not be assigned to inactive rule
        decimal rankassigned = 100;
        boolean flagInactiverecordavailable = false;
        for(InvoiceGroupingRulesExt.InvoiceGroupingRule   igr:(List<InvoiceGroupingRulesExt.InvoiceGroupingRule>)jr.records){
            if(igr.invoicegroupingrule.is_active__c ==false){
                rankassigned= igr.invoicegroupingrule.rank__c;
                flagInactiverecordavailable=true;
                break;
            }
        }
        system.assertequals(flagInactiverecordavailable,true);
        system.assertequals(rankassigned,null);
        
    }
    static testMethod void TestsaveIgrs(){
        TestFuelQuery fuel = new TestFuelQuery();
        IGRData i= new IGRData();
        integer countRecs=i.igrlist.size();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        decimal  count = 100;
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        for(InvoiceGroupingRulesExt.InvoiceGroupingRule   igr:(List<InvoiceGroupingRulesExt.InvoiceGroupingRule>)jr.records){
            igr.invoicegroupingrule.rank__c =count;
            count=count+1;       
            igrListtoIns.add(igr);
        }
        
        DataSourceResult result=  InvoiceGroupingRulesExt.saveIGRs(igrListtoIns, new list<String> {'Start_Date__c','End_Date__c'});
        system.assertEquals(true,result.success);
       
        // insert same rank for multiple rules - expected failure
  /*      igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        for(InvoiceGroupingRulesExt.InvoiceGroupingRule igr1:(List<InvoiceGroupingRulesExt.InvoiceGroupingRule>)jr.records){
            igr1.invoicegroupingrule.rank__c =100;
            igrListtoIns.add(igr1);
        }
        
        DataSourceResult result2=  InvoiceGroupingRulesExt.saveIGRs(igrListtoIns);
            system.assertEquals(false,result2.success);*/
        
    }


    //igr1 to change, so that it clashes with igr3
    static testMethod void TestUpdateDuplicateIgrs_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        Test.startTest();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        Invoice_Grouping_rule__c   igr1= ((InvoiceGroupingRulesExt.InvoiceGroupingRule) (jr.records[0])).invoicegroupingrule;
        system.debug(LoggingLevel.Error, '>> igr1: ' + igr1);

        // start date and end date is igr3 time interval
        igr1.Start_Date__c =igr3.Start_Date__c;
        igr1.End_Date__c = igr3.End_Date__c;
        igr1.group_by_category__c =true;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        InvoiceGroupingRuleService.requestFromUI = true;
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }

        // start date and end date within igr3 time interval
        igr1.Start_Date__c =igr3.Start_Date__c +1;
        igr1.End_Date__c =igr3.End_Date__c -1;      
        igr1.group_by_category__c =true;
        lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result1=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result1.success,false, result1.messages);
        system.assert(result1.messages.size() == 1);
        for (Map<String, String> error : result1.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        
        // start date within igr3 time interval
        // end date beyond igr3 time interval
        igr1.Start_Date__c =igr3.Start_Date__c +1;
        igr1.End_Date__c =igr3.End_Date__c +1;      
        igr1.group_by_category__c =true;
        lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result2=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result2.success,false, result2.messages);
        system.assert(result2.messages.size() == 1);
        for (Map<String, String> error : result2.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        // start date before igr1 time interval
        // end date beyond igr1 time interval
        igr1.Start_Date__c =igr3.Start_Date__c -1; 
        igr1.End_Date__c =igr3.End_Date__c +1;      
        igr1.group_by_category__c =true;
        lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result3=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result3.success,false, result3.messages);
        system.assert(result3.messages.size() == 1);
        for (Map<String, String> error : result3.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        // no end date
        igr1.Start_Date__c =igr3.Start_Date__c; 
        igr1.End_Date__c = null;      
        igr1.group_by_category__c =true;
        lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result4=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result4.success,false, result4.messages);
        system.assert(result4.messages.size() == 1);
        for (Map<String, String> error : result4.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        Test.stopTest();
    }

    static testMethod void TestUpdateDuplicateIgrs_NoEndDates_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        Test.startTest();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr1 = existingIGRList[0];
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.End_Date__c = null;
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);

        igr1.Start_Date__c =igr3.Start_Date__c;
        igr1.End_Date__c = null;
        igr1.group_by_category__c =true;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        Test.stopTest();
    }

    static testMethod void TestUpdateDuplicateIgrs_ForProducts_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr1 = existingIGRList[0];
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.End_Date__c = null;
        igr3.Group_By_Product__c = false;
        igr3.group_by_category__c = false;
        igr3.For_Products__c = JSON.serialize(new set<Id>{fuel.product.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        Test.startTest();
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);

        igr1.Start_Date__c =igr3.Start_Date__c;
        igr1.End_Date__c = null;
        igr1.group_by_category__c =false;
        igr1.Group_By_Product__c = false;
        igr1.For_Products__c =igr3.For_Products__c;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        Test.stopTest();
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
    }

    static testMethod void TestUpdateIgrs_ForProducts_Success(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        IGRData i= new IGRData();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr1 = existingIGRList[0];
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.Group_By_Product__c = false;
        igr3.group_by_category__c = false;
        igr3.For_Products__c = JSON.serialize(new set<Id>{fuel.product.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        Test.startTest();
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        
        // Same as igr3 except for dates which do not overlap
        igr1.Start_Date__c =igr3.End_Date__c+1;
        igr1.End_Date__c = null;
        igr1.group_by_category__c =false;
        igr1.Group_By_Product__c = false;
        igr1.For_Products__c =igr3.For_Products__c;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        Test.stopTest();
        system.assertEquals(result.success,true, result.messages);
    }
    
    static testMethod void TestUpdateIgrs_ForAgreements_Success(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        IGRData i= new IGRData();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr1 = existingIGRList[0];
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.Group_By_Agreements__c = false;
        igr3.For_Agreements__c = JSON.serialize(new set<Id>{fuel.agreement.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        Test.startTest();
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        
        // Same as igr3 except for dates which do not overlap
        igr1.Start_Date__c =igr3.End_Date__c+1;
        igr1.End_Date__c = null;
        igr1.group_by_category__c =true;
        igr1.Group_By_Agreements__c = false;
        igr1.For_Agreements__c =igr3.For_Agreements__c;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        Test.stopTest();
        system.assertEquals(result.success,true, result.messages);
    }
    
    static testMethod void TestUpdateDuplicateIgrs_ForAgreements_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr1 = existingIGRList[0];
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.End_Date__c = null;
        igr3.Group_By_Agreements__c = false;
        igr3.For_Agreements__c = JSON.serialize(new set<Id>{fuel.agreement.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        Test.startTest();
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);

        igr1.Start_Date__c =igr3.Start_Date__c;
        igr1.End_Date__c = null;
        igr1.group_by_category__c =true;
        igr1.Group_By_Agreements__c = false;
        igr1.For_Agreements__c =igr3.For_Agreements__c;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        Test.stopTest();
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
    }
    
    //KNDY-14588
    //covers validation rule- Cant_set_bill_on_fulfillments
    static testMethod void TestUpdateDuplicateIgrs_ForBillingFreq_Validation(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = 'Billing frequency on fulfillments is only supported for grouping by sales orders and agreements';
        IGRData i= new IGRData();
        Test.startTest();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_Rule__c igr1 = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, Use_Billing_Frequency_on_Fulfillment__c = true, 
                                                                     Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        InvoiceGroupingRuleService.requestFromUI = true;
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result.success,true, result.messages);
        
		//throw validation error for billing freq can be applied for group of sales order or agreements
        igr1.Group_By_Sales_Orders__c = false;
        igr1.Group_By_Agreements__c = false;     
        igr1.Use_Billing_Frequency_on_Fulfillment__c = true;
        igr1.For_Agreements__c = null;
        lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        //update agreement id and billing freq - it should not throw any error
        Invoice_Grouping_Rule__c igr2 = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, Use_Billing_Frequency_on_Fulfillment__c = true, 
                                                                     Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = false,For_Agreements__c =JSON.serialize(new set<Id>{fuel.agreement.id})
                                                                     , Group_By_Agreements__c = false, Company__c = fuel.company.Id);        
       
        lIGRs = (new list<Invoice_Grouping_Rule__c> {igr2});  
        result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result.success,true, result.messages);
        
        Test.stopTest();
    }
    static testMethod void TestUpdateDuplicateIgrs_ForCustomers_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        Test.startTest();
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        
        Invoice_Grouping_rule__c igr3 = existingIGRList[3];
        list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoIns = new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        Invoice_Grouping_rule__c   igr1= ((InvoiceGroupingRulesExt.InvoiceGroupingRule) (jr.records[0])).invoicegroupingrule;
        system.debug(LoggingLevel.Error, '>> igr1: ' + igr1);

        // start date and end date is igr3 time interval
        igr1.Start_Date__c =igr3.Start_Date__c;
        igr1.End_Date__c = igr3.End_Date__c;
        igr1.For_Customers__c  = igr3.For_Customers__c;
        
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        InvoiceGroupingRuleService.requestFromUI = true;
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        
        Test.stopTest();
        
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
    }

    static testMethod void TestUpdateDuplicateIgrs_DiffCompanies_Success(){//KNDY-16097 
        TestFuelQuery fuel = new TestFuelQuery();
        String expectedMessage = Label.Changes_saved;
        IGRData i= new IGRData();
        
        // insert igr test data
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        
        Invoice_Grouping_rule__c igr3 = existingIGRList[3];
        Invoice_Grouping_rule__c   igr1= igr3.clone();
        igr1.Company__c = fuel.altCompany.Id;
        system.debug(LoggingLevel.Error, '>> igr1: ' + igr1);

        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult result=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        system.assertEquals(result.success,true, result.messages);
        system.assertEquals(result.messages.size(), 1, result.messages);
        for (Map<String, String> error : result.messages) {
            system.assertEquals(error.get('message').contains(expectedMessage), true, error);
        }
    }
    
    static testMethod void TestUpsertIgr(){
        TestFuelQuery fuel = new TestFuelQuery();
          
        IGRData i= new IGRData();
        Test.startTest();
        integer countRecs=i.igrlist.size();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
        Invoice_Grouping_rule__C   igr1= ((InvoiceGroupingRulesExt.InvoiceGroupingRule) (jr.records[0])).invoicegroupingrule;
        igr1.group_by_category__C =true;
        list<Invoice_Grouping_Rule__c> lIGRs = (new list<Invoice_Grouping_Rule__c> {igr1});
        JSONResult upsertResult=  InvoiceGroupingRulesExt.upsertRule(lIGRs);
        Test.stopTest();
        system.assertEquals(upsertResult.success,true, upsertResult.messages);
      }
      

     static testMethod void TestDeleteIgr(){
        TestFuelQuery fuel = new TestFuelQuery();
        IGRData i= new IGRData();
        integer countRecs=i.igrlist.size();
        JsonResult jr=  InvoiceGroupingRulesExt.getIGRs(fuel.company.id);
          InvoiceGroupingRulesExt.InvoiceGroupingRule   igr1= ((InvoiceGroupingRulesExt.InvoiceGroupingRule) (jr.records[0]));
          

         list<InvoiceGroupingRulesExt.InvoiceGroupingRule> igrListtoDelete = (new list<InvoiceGroupingRulesExt.InvoiceGroupingRule>{igr1});
		 User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	     list<Configuration__c> lConfigs = new list<Configuration__c>();
	     lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	     insert lConfigs;
         DataSourceResult delResult=  InvoiceGroupingRulesExt.deleteIgrs(igrListtoDelete, new list<String> {'Start_Date__c','End_Date__c'});
         delete lConfigs;
          system.assert(delResult.success,true);


      }
     
    static testmethod void TestfetchHelpText(){
    	String fieldname= 'start_date__c';
    	
          JsonResult jr=  InvoiceGroupingRulesExt.fetchHelpText(fieldname);
                    Schema.SObjectType igrschema=       Invoice_Grouping_rule__C.sObjectType;
            Map<String, Schema.SObjectField> fieldMap = igrschema.getDescribe().fields.getMap();
            string verify= Invoice_Grouping_rule__C.start_date__c.getDescribe().getInlineHelpText();
        system.assertEquals(jr.message,verify);
    
    
    }
     
    /******  10/26/2016 *************/
    //************ All of the below test methods should be moved to InvoiceGroupingTest
    //************ once InvoiceGrouping_VoidCancel() method in InvoiceGroupingTest is retroffitted to use TestFuelQuery
    //***************************************************************
    static testMethod void TestInsertDuplicateIgrs_ForProducts_Error(){
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        TestFuelQuery fuel = new TestFuelQuery();
        
        IGRData i= new IGRData();
        Test.startTest();
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.End_Date__c = null;
        igr3.Group_By_Product__c = false;
        igr3.group_by_category__c = false;
        igr3.For_Products__c = JSON.serialize(new set<Id>{fuel.product.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        
        Invoice_Grouping_rule__c newigr = igr3.clone();
        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        Test.stopTest();
        system.assert(hasException);
    }

    static testMethod void TestInsertIgrs_ForProducts_Success(){
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        TestFuelQuery fuel = new TestFuelQuery();
        
        IGRData i= new IGRData();
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.Group_By_Product__c = false;
        igr3.group_by_category__c = false;
        igr3.For_Products__c = JSON.serialize(new set<Id>{fuel.product.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        Test.startTest();
        
        // Same as igr3 except for dates which do not overlap
        Invoice_Grouping_rule__c newigr = igr3.clone();
        newigr.Start_Date__c =igr3.End_Date__c+1;
        newigr.End_Date__c = null;

        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(!hasException);
    }

    static testMethod void TestInsertIgrs_ForAgreements_Success(){
        TestFuelQuery fuel = new TestFuelQuery();
        String expectedErrorMessage = Label.Change_dates_on_IGR;
                
        IGRData i= new IGRData();
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.Group_By_Agreements__c = false;
        igr3.For_Agreements__c = JSON.serialize(new set<Id>{fuel.agreement.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        
        Test.startTest();
        Invoice_Grouping_rule__c newigr = igr3.clone();
        newigr.Start_Date__c = igr3.End_Date__c + 1;
        newigr.End_Date__c = null;
        
        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.debug(LoggingLevel.Error, '>>> success has exception, ex.getMessage() ' + ex.getMessage());
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(!hasException);        // Same as igr3 except for dates which do not overlap
    }
    
    static testMethod void TestInsertDuplicateIgrs_ForAgreements_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr3 = existingIGRList[2];
        igr3.End_Date__c = null;
        igr3.Group_By_Agreements__c = false;
        igr3.For_Agreements__c = JSON.serialize(new set<Id>{fuel.agreement.id});
        InvoiceGroupingRuleService.requestFromUI = true;
        update igr3;
        
        Test.startTest();
        Invoice_Grouping_rule__c newigr = igr3.clone();
        newigr.End_Date__c = null;
        
        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.debug(LoggingLevel.Error, '>>> success has exception, ex.getMessage() ' + ex.getMessage());
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
    }
    
    static testMethod void TestInsertDuplicateIgrs_ForCustomers_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        IGRData i= new IGRData();
        List<Invoice_Grouping_rule__c>  existingIGRList = i.igrlist;
        Invoice_Grouping_rule__c igr3 = existingIGRList[3];
        Test.startTest();
        Invoice_Grouping_rule__c newigr= igr3.clone();
        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.debug(LoggingLevel.Error, '>>> success has exception, ex.getMessage() ' + ex.getMessage());
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
        Test.stopTest();
    }
  
    static testMethod void TestInsertDuplicateIgrs_NoEndDates_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        Invoice_Grouping_Rule__c igr1 = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = null, rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Shipments__c = true,Company__c =fuel.company.id);
        insert igr1;

        Invoice_Grouping_rule__c newigr = igr1.clone();
        newigr.Start_Date__c =igr1.Start_Date__c ;
        newigr.End_Date__c = null;

        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
    }
    
    static testMethod void TestInsertDuplicateIgrs_Error(){
        TestFuelQuery fuel = new TestFuelQuery();
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        
        Invoice_Grouping_Rule__c igr1 = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1), rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Shipments__c = true, Company__c =fuel.company.Id);
        insert igr1;
        
        Invoice_Grouping_rule__c newigr = igr1.clone();
        // start date within igr1 time interval
        newigr.Start_Date__c =igr1.Start_Date__c + 1;
        newigr.End_Date__c = igr1.End_Date__c;

        Boolean hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
        
        // start date and end date within igr1 time interval
        newigr.Start_Date__c =igr1.Start_Date__c +1;
        newigr.End_Date__c =igr1.End_Date__c -1;      
        hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
        // start date within igr1 time interval
        // end date beyond igr1 time interval
        newigr.Start_Date__c =igr1.Start_Date__c +1;
        newigr.End_Date__c =igr1.End_Date__c +1;      
        hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
        // start date before igr1 time interval
        // end date beyond igr1 time interval
        newigr.Start_Date__c =igr1.Start_Date__c -1; 
        newigr.End_Date__c =igr1.End_Date__c +1;      
        hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
        // no end date
        newigr.Start_Date__c =igr1.Start_Date__c; 
        newigr.End_Date__c = null;      
        hasException = false;
        try{
            insert newigr;
        }
        catch(Exception ex){
            hasException = true;
            system.assert(ex.getMessage().contains(expectedErrorMessage), ex.getMessage());
        }
        system.assert(hasException);
    }
    


    static testMethod void InvoiceGrouping_AggregateFail_HoldInvoicing() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Reason_Code__c holdCode = new Reason_Code__c();
        holdCode.Company__c = fuel.company.Id;
        holdCode.Type__c = 'Invoice Hold';
        holdCode.Code__c = 'D001';
        insert holdCode;
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, Use_Billing_Frequency_on_Fulfillment__c = true, 
                                                                     Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c, Is_Active__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        system.assertEquals(true, igr.Is_Active__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = true, Reason_Code__c = holdCode.id, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c));
        
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = true,Reason_Code__c = holdCode.id, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = true,Reason_Code__c = holdCode.id, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,8,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = true, Reason_Code__c = holdCode.id, Unit_Price__c = 120, Quantity__c = 6, Product__c = lSOLs[0].Product__c));
        insert lFs;
        
        
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,(Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(0,lCIs.size());
                        
    }


    static testMethod void InvoiceGrouping_RuleCreation_Success() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1), rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Shipments__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
                        
    }
    
    
   /* ///FOR NOW IT STAYS HERE. IN SUMMER IT WILL GO IN NEW CLASS
    static testMethod void testCustomerInvoiceLines_ImmediateIGR() {
        TestFuelQuery fuel = new TestFuelQuery();
        DateTime sd = DateTime.newInstance(2015,1,31,0,0,0);
        DateTime ed = DateTime.newInstance(2016,1,31,0,0,0);
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = sd,  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c, Next_Invoice_Date__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        //system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = sd;
            sol.End_Date__c = ed;
            sol.Rate_Basis__c = 'Flat';
            
        }
        update lSOLs;
        
        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c);
        insert f;
        
        
        test.startTest();
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, Matches_To_Grouping_Rule__c, (Select ID, Start_Date__c, End_Date__c, Extended_Price__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        system.assertEquals(1,lCIs.size(),lCIs);
        system.debug('Matches_To_Grouping_Rule__c '+lCIs[0].Matches_To_Grouping_Rule__c);
        system.assertEquals(12,lCIs[0].Customer_Invoice_Lines__r.size(),lCIs[0].Customer_Invoice_Lines__r);
        boolean extendPriceIsSame = true;
        Decimal extendedPrice = 98;
        for(Customer_Invoice_Line__c cil : lCIs[0].Customer_Invoice_Lines__r) {
            system.debug('cil '+cil);
            if(cil.Extended_Price__c != extendedPrice)
                extendPriceIsSame = false;
        }
        
        system.assertEquals(true, extendPriceIsSame, lCIs[0].Customer_Invoice_Lines__r);
        
    }
    
    static testMethod void testCustomerInvoiceLines_MonthlyIGR() {
        
        TestFuelQuery fuel = new TestFuelQuery();
        DateTime sd = DateTime.newInstance(2015,1,31,0,0,0);
        DateTime ed = DateTime.newInstance(2016,1,31,0,0,0);
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = sd, rank__c = 1,  
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c, Next_Invoice_Date__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        //system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = sd;
            sol.End_Date__c = ed;
            sol.Rate_Basis__c = 'Flat';
            
        }
        update lSOLs;
        
        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c);
        insert f;
        
        
        test.startTest();
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, (Select ID, End_Date__c, Extended_Price__c from Customer_Invoice_Lines__r order by ID) from Customer_Invoice__c];
        
        system.assertEquals(13,lCIs.size(),lCIs);
        //system.assertEquals(13,lCIs[0].Customer_Invoice_Lines__r.size(),lCIs[0].Customer_Invoice_Lines__r);
        boolean extendPriceIsSame = true;
        Decimal extendedPrice = 98;
        for(integer i= 0; i < lCIs.size(); ++i) {
            Customer_Invoice__c ci = lCIs[i];
            system.assertEquals(1, ci.Customer_Invoice_Lines__r.size(),ci.Customer_Invoice_Lines__r);
            if(i != 0 && i != (lCIs.size() - 1) &&  extendedPrice != ci.Customer_Invoice_Lines__r[0].Extended_Price__c)
                extendPriceIsSame = false;
        }
        
        system.assertEquals(true, extendPriceIsSame, lCIs);
        
    }
    
    static testMethod void testSOLExtendedPrice() {
        TestFuelQuery fuel = new TestFuelQuery();
        DateTime sd = DateTime.newInstance(2015,1,31,0,0,0);
        DateTime ed = DateTime.newInstance(2016,1,31,0,0,0);
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = sd;
            sol.End_Date__c = ed;
            sol.Rate_Basis__c = 'Flat';
            
            sol.Unit_Price__c = 100;
            sol.Off_Invoice_Rate__c = 0;
            sol.Allowances__c = 0;
            sol.Freight_Allowance__c = 0;
            sol.Discount_Percent__c = 0;
        }
         update lSOLs;
         boolean extendPriceIsSame = true;
         Decimal extendedPrice = 100 * 12 ;
         for(Sales_Order_Line__c sol :  [Select Id, Line_Total__c from Sales_Order_Line__c where id in :lSOLs]) {
            
            system.debug('sol '+sol);
            if(sol.Line_Total__c != extendedPrice)
                extendPriceIsSame = false;
        }
        
        system.assertEquals(true, extendPriceIsSame, lSOLs);
    }
    
    static testMethod void testAGLExtendedPrice() {
        TestFuelQuery fuel = new TestFuelQuery();
        DateTime sd = DateTime.newInstance(2015,1,31,0,0,0);
        DateTime ed = DateTime.newInstance(2016,1,31,0,0,0);
        
        system.assertNotEquals(null,fuel.agreement.Id);
        fuel.agreement.Start_Date__c = sd.addYears(-2);
        update fuel.agreement;
        list<Agreement_Line__c> lAGLs = [Select Id, Product__c from Agreement_Line__c where Agreement__c = :fuel.agreement.Id];
        
        system.assertEquals(1,lAGLs.size());
        for(Agreement_Line__c sol : lAGLs){
            sol.Start_Date__c = sd;
            sol.End_Date__c = ed;
            sol.Rate_Basis__c = 'Flat';
            
            sol.Agreement_Price__c = 100;
            
        }
         update lAGLs;
         boolean extendPriceIsSame = true;
         Decimal extendedPrice = 100 * 12 ;
         for(Agreement_Line__c sol :  [Select Id, Line_Total__c from Agreement_Line__c where id in :lAGLs]) {
            
            system.debug('sol '+sol);
            if(sol.Line_Total__c != extendedPrice)
                extendPriceIsSame = false;
        }
        
        system.assertEquals(true, extendPriceIsSame, lAGLs);
    }*/
 
    

     static testMethod void InvoiceGroupingRuleDeDuplication() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        String expectedErrorMessage = Label.Change_dates_on_IGR;
        Invoice_Grouping_Rule__c igr1 = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1), rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Shipments__c = true, Company__c = fuel.company.Id);
          Invoice_Grouping_Rule__c igr2 = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1), rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Shipments__c = true, Company__c = fuel.company.Id);
         
        
        insert igr1;
        
        igr1 = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr1.Id limit 1];
        system.assertEquals(true, igr1.is_Valid__c);
         boolean exceptionflag=false;
         try{   
        insert igr2;
             
         }catch(exception e){
             system.assert(e.getMessage().contains(expectedErrorMessage));
             exceptionflag=true;
         }
        //igr2 = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, exceptionflag);
         
           
         
    }
    
      
    
     static testMethod void startDateIsRequired() {//KNDY-9364 //DONE
         boolean exceptionflag=false;
        Invoice_Grouping_Rule__c igr1 = new Invoice_Grouping_Rule__c( End_Date__c = system.now().date().addYears(1), rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Shipments__c = true);
         
        try{
        insert igr1;
        }catch(exception e){
             system.assert(e.getMessage().contains('Start Date is required'));
             exceptionflag=true;
         }
        system.assertEquals(true, exceptionflag);
         
         
    }
     
    static testMethod void InvoiceGrouping_RuleCreation_Fail1() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        String customers = JSON.serialize(new Set<Id>{fuel.customerBillTo.id});
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(),End_Date__c = system.now().date().addYears(1),rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', For_Customers__c = customers);

        
        try {
            insert igr;
        }catch(Exception ex) {
            system.assert(ex.getMessage().contains('Cannot populate both group by and for customer fields for a given rule'));
        }
        
        
        list<Invoice_Grouping_Rule__c> lIgr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id];
        system.assertEquals(0, lIgr.size());
                        
    }
    
    static testMethod void InvoiceGrouping_RuleCreation_Fail2() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Plan__c p = new Plan__c(Parent_Customer__c = fuel.customerParent.Id, Status__c = 'Active', Start_Date__c = system.now());
        insert p;
        
        Agreement__c agreement = new Agreement__c();
        agreement.Name = 'Sample Agreement';
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Start_Date__c = system.today();
        agreement.Status__c = 'Approved';
        agreement.Customer_Type__c = 'Bill To';
        agreement.Currency__c = fuel.currencyGBP.id;
        agreement.Plan__c = p.Id;
        insert agreement;
        String agreements = JSON.serialize(new Set<Id>{agreement.id});
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1),rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', For_Agreements__c = agreements, Group_By_Agreements__c = true);

        
        try {
            insert igr;
        }catch(Exception ex) {
            system.assert(ex.getMessage().contains('Cannot set both group by agreements and for agreement fields for a given rule'));
        }
        
        
        list<Invoice_Grouping_Rule__c> lIgr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id];
        system.assertEquals(0, lIgr.size());
                        
    }
    
    static testMethod void InvoiceGrouping_RuleCreation_Fail3() {//DONE

        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1),rank__c = 1, 
                                                                  Group_By_Sales_Order_If__c = 'Order is closed',  Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Group_By_Sales_Order_Types__c = true);
        
        try {
            insert igr;
        }catch(Exception ex) {
            system.assert(ex.getMessage().contains('Cannot set both sales order groupings'));
        }
        
        
        list<Invoice_Grouping_Rule__c> lIgr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id];
        system.assertEquals(0, lIgr.size());
                        
    }
    
    static testMethod void InvoiceGrouping_RuleCreation_SuccessDefaultSOType() {//DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1),rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Product__c = true, Company__c = fuel.company.Id);
        
            insert igr;
        
        igr = [select Id, Group_By_Sales_Order_Types__c from Invoice_Grouping_Rule__c where Id  = :igr.Id limit 1];
        system.assertEquals(true, igr.Group_By_Sales_Order_Types__c);
        
        //KNDY-15790
        JsonResult result = new JsonResult();
        result = InvoiceGroupingRulesExt.IsIGRUsedForInvoicing(igr.Id);
        system.assertEquals(0,result.total);
        
        //KNDY-15790
        result = new JsonResult();
        result = InvoiceGroupingRulesExt.IsIGRUsedForInvoicing(null);
        system.assertEquals(false,result.success);
    }
    
    static testMethod void InvoiceGrouping_RuleCreation_Fail6() { //DONE
        
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = system.now(), End_Date__c = system.now().date().addYears(1),rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Product__c = true, Group_By_Category__c = true);
        
        try {
            insert igr;
        }catch(Exception ex) {
            system.assert(ex.getMessage().contains('Cannot select more than one criteria for Categories and Products'));
        }
        
        
        list<Invoice_Grouping_Rule__c> lIgr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id];
        system.assertEquals(0, lIgr.size());
                        
    }

    
    
    static testMethod void InvoiceGrouping_Recurring_LastBillDate() {//KNDY-9595 //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Date dtNow = system.now().date();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-2), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                     Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        //system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = DateTime.newInstance(Date.newInstance(2015,4,1), Time.newInstance(0,0,0,0));
            sol.End_Date__c = DateTime.newInstance(Date.newInstance(2015,6,1), Time.newInstance(0,0,0,0));
            sol.Rate_Basis__c = 'Quantity';
            
        }
        update lSOLs;
        

        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Start_Date__c = DateTime.newInstance(dtNow.addMonths(-2), Time.newInstance(0,0,0,0)), Last_Bill_Date__c =DateTime.newInstance(Date.newInstance(2015,5,1), Time.newInstance(0,0,0,0)), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Pricing_UOM__c = fuel.CalendarMonth.Id, Billing_UOM__c  = fuel.CalendarMonth.Id, Recurrence_Start_Date__c = DateTime.newInstance(Date.newInstance(2015,3,1), Time.newInstance(0,0,0,0)), Status__c = 'Complete');

        insert f;
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, (Select ID from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        system.assertEquals(1,lCIs.size());
        system.assertEquals(Date.newInstance(2015,6,1),lCIs[0].Planned_Invoice_Date__c.date(),lCIs);
        system.assertEquals(1,lCIs[0].Customer_Invoice_Lines__r.size(),lCIs[0].Customer_Invoice_Lines__r);
        
        //KNDY-15790
        JsonResult result = new JsonResult();
        result = InvoiceGroupingRulesExt.IsIGRUsedForInvoicing(igr.Id);
        system.assertEquals(1,result.total);
    }
    
    static testMethod void InvoiceGrouping_RecurringSucess() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Date dtNow = system.now().date();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id,  Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        //system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id order by Unit_Price__c];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = DateTime.newInstance(Date.newInstance(2015, 4, 24), Time.newInstance(0,0,0,0));
            sol.End_Date__c = DateTime.newInstance(Date.newInstance(2016, 4, 24), Time.newInstance(0,0,0,0));
            sol.Rate_Basis__c = 'Quantity';
            sol.Discount_Amount__c = 111.2;
        }
        update lSOLs;
        

        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Pricing_UOM__c = fuel.CalendarMonth.Id, Billing_UOM__c  = fuel.CalendarMonth.Id, Recurrence_Start_Date__c = DateTime.newInstance(Date.newInstance(2015,3,24), Time.newInstance(0,0,0,0)), Status__c = 'Complete');

        insert f;
        //Now the fulfillment has a start date of (today - 6 months), and  end date of (today - 2 months)
        //since the fulfillment is monthly, billing is quaterly and fulfillment is not invoice ahead. the fist invoice will be created on today- 3 months , irrespective of prorate. the lines will show the pro-rate accordingly. 
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        

        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, (Select ID, End_Date__c,Subtransaction_Type__c, Discount_Amount__c,Amount__c,Product_Reference__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        system.assertEquals(12,lCIs.size(),lCIs);
		
		system.assertNotEquals(null, fuel.customerProdRef.Id);
		Cross_Reference__c crossRef = [Select Id from Cross_Reference__c where Name = 'CR01' limit 1];
        
		for(Customer_Invoice__c ci:lCIs){
			system.assertEquals(1, ci.Customer_Invoice_Lines__r.size());
			system.assertEquals(10, ci.Customer_Invoice_Lines__r[0].Discount_Amount__c);
	        system.assertEquals(90, ci.Customer_Invoice_Lines__r[0].Amount__c);
            system.assertEquals(ci.Customer_Invoice_Lines__r[0].Subtransaction_Type__c, 'Goods'); //KNDY-14619
            system.assertEquals(crossRef.Id, ci.Customer_Invoice_Lines__r[0].Product_Reference__c);
		}
    }
   
    static testMethod void InvoiceGrouping_Recurring_immediateBilling_Future() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Date dtNow = system.now().date();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id,  Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        //system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = DateTime.newInstance(dtNow, Time.newInstance(0,0,0,0));
            sol.End_Date__c = DateTime.newInstance(dtNow.addDays(10), Time.newInstance(0,0,0,0));
            sol.Rate_Basis__c = 'Quantity';
            
        }
        update lSOLs;
        

        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Pricing_UOM__c = fuel.WEEK.Id,  Status__c = 'Complete');

        insert f;
        //Now the fulfillment has a start date of (today - 6 months), and  end date of (today - 2 months)
        //since the fulfillment is monthly, billing is quaterly and fulfillment is not invoice ahead. the fist invoice will be created on today- 3 months , irrespective of prorate. the lines will show the pro-rate accordingly. 
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, (Select ID, End_Date__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        system.assertEquals(0,lCIs.size(),lCIs);

        
       
    }
    
    static testMethod void InvoiceGrouping_RecurringSucess_InvoiceAhead() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Date dtNow = system.now().date();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        //system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = DateTime.newInstance(Date.newInstance(2015,4,1), Time.newInstance(0,0,0,0));
            sol.End_Date__c = DateTime.newInstance(Date.newInstance(2015,8,1), Time.newInstance(0,0,0,0));
            sol.Rate_Basis__c = 'Quantity';
            
        }
        update lSOLs;
        

        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Invoice_Ahead__c = true, Price_Type__c = 'Recurring', Pricing_UOM__c = fuel.CalendarMonth.Id, Billing_UOM__c  = fuel.CalendarQuarter.Id, Recurrence_Start_Date__c = DateTime.newInstance(Date.newInstance(2015,3,24), Time.newInstance(0,0,0,0)), Status__c = 'Complete');

        insert f;
        
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, (Select ID, Start_Date__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        system.assertEquals(2,lCIs.size(),lCIs[0].Customer_Invoice_Lines__r);

                        
    }
    
    static testMethod void InvoiceGrouping_ValidAcceptanceDateOnAgreement() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Date dToday = system.today();
        String customers = JSON.serialize(new set<Id>{fuel.customerBillTo.Id});
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dToday, Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                              For_Customers__c = customers, Group_By_Agreements__c = true, Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        test.startTest();
            system.assertNotEquals(null,fuel.agreementLine.Id);
            
            fuel.agreementLine.Occurrence__c = 'Immediate';
            update fuel.agreementLine;
            
        system.assertNotEquals(null,fuel.agreement.Id);
        
        fuel.agreement.Activation_Date__c = system.today().addDays(-30);
        update fuel.agreement;
        
        fuel.salesOrder.Agreement__c = fuel.agreement.ID;
        update fuel.salesOrder;
        
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = DateTime.newInstance(dToday, Time.newInstance(0,0,0,0));
            sol.Rate_Basis__c = 'Quantity';
            sol.Discount_Amount__c = 2;
                sol.Occurrence__c = 'Immediate';
        }
        update lSOLs;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Agreement_Line__c = fuel.agreementLine.Id,
                                   Sales_Order_Line__c = lSOLs[0].Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));

        
        insert lFs;
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        system.assertNotEquals(null, fuel.agreementLine.Id);
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Bill_To_Customer__c, Agreement__c, (Select id, Rate_Basis__c, Discount_Amount__c,Amount__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(1,lCIs.size());
        system.assertEquals(fuel.agreement.Id, lCIs[0].Agreement__c);//KNDY-8764
        system.assertEquals(1, lCIs[0].Customer_Invoice_Lines__r.size());
        system.assertEquals(fuel.agreementLine.Rate_Basis__c, lCIs[0].Customer_Invoice_Lines__r[0].Rate_Basis__c);
        system.assertEquals(0.54, lCIs[0].Customer_Invoice_Lines__r[0].Discount_Amount__c);
        system.assertEquals(299.46, lCIs[0].Customer_Invoice_Lines__r[0].Amount__c); //KNDY-15247
       
    }
    
    static testMethod void InvoiceGrouping_InValidAcceptanceDateOnAgreement() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        
        test.startTest();
        
        String customers = JSON.serialize(new Set<Id>{fuel.customerBillTo.Id});
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), rank__c = 1, 
                                           For_Customers__c = customers, Group_By_Agreements__c = true, Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        system.assertNotEquals(null,fuel.agreement.Id);
        
        fuel.agreement.Activation_Date__c = system.today().addDays(30);
        update fuel.agreement;
        
        fuel.salesOrder.Agreement__c = fuel.agreement.ID;
        update fuel.salesOrder;
        
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Agreement_Line__c = fuel.agreementLine.Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Bill_To_Customer__c, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(0,lCIs.size());
       
    }
    
    static testMethod void InvoiceGrouping_AggregateSucess() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                            Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Discount_Percent__c = 10;
        }
        update lSOLs;
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));
        
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,8,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 6, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c, Sales_Order__c, (Select id,Product_Reference__c, Source_Key__c,Discount_Amount__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(1,lCIs.size());
        system.assertEquals(1, lCIs[0].Customer_Invoice_Lines__r.size(),lCIs[0].Customer_Invoice_Lines__r);
        system.assertEquals(180, lCIs[0].Customer_Invoice_Lines__r[0].Discount_Amount__c,lCIs[0].Customer_Invoice_Lines__r[0].Discount_Amount__c);

        system.assertNotEquals(null, fuel.customerProdRef.Id);
		Cross_Reference__c crossRef = [Select Id from Cross_Reference__c where Name = 'CR01' limit 1];
        system.assertEquals(crossRef.Id, lCIs[0].Customer_Invoice_Lines__r[0].Product_Reference__c);
        
        
                        
    }

    // FulfilmentDate is same day one hour behind datetime set in InvoiceGroupingRuleService:  5/30/next year 10 AM 
    static testMethod void InvoiceGrouping_AggregateFutureFFDate_Success() { //KNDY-16724
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2014,5,30,0,0,0),  rank__c = 1, 
                                            Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance(); 
        DateTime testffEndDate = igrUtil.testFFEndDate;
        // FulfilmentDate 5/30/next year 9 AM  < 5/30/next year 10 AM  set in InvoiceGroupingRuleService
        DateTime ffDate = DateTime.newInstance(testffEndDate.year(),testffEndDate.month(),testffEndDate.day(),testffEndDate.hour()-1,0,0);
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, 
                Fulfillment_Date__c = ffDate, 
                Currency__c = fuel.company.Default_Transaction_Currency__c, 
                Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, 
                Quantity__c = 3, Product__c = lSOLs[0].Product__c,
                Price_Type__c ='Sales', Status__c = 'Complete'));
        insert lFs;
        
        Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c, Sales_Order__c, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(1,lCIs.size());
    }
    
            
    // FulfilmentDate is one day ahead of datetime set in InvoiceGroupingRuleService:  5/30/next year 10 AM 
    static testMethod void InvoiceGrouping_AggregateFutureFFDate_Error() { //KNDY-16724
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2014,5,30,0,0,0),  rank__c = 1, 
                                            Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance(); 
        DateTime testffEndDate = igrUtil.testFFEndDate;
        DateTime ffDate = testffEndDate.addDays(1);
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, 
                Fulfillment_Date__c = ffDate, 
                Currency__c = fuel.company.Default_Transaction_Currency__c, 
                Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, 
                Quantity__c = 3, Product__c = lSOLs[0].Product__c,
                Price_Type__c ='Sales', Status__c = 'Complete'));
        insert lFs;
        Sales_Order__c salesorder = fuel.salesOrder;
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success, jr);
        
        jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
        system.assert(!jr.success, jr);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('Fulfillment date is in future')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assertEquals(ErrorExists, true, jr.messages);
        Test.StopTest();
    }
    
    static testMethod void InvoiceGrouping_AggregateFail_SO_Has_Exceptions() { //DONE

        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                  Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Task t = new Task(WhatID = lSOLs[0].Id, Type = 'Exception', Subject='Some Exception', Status= 'Open', Exception_Code__c = 'TEST-001');
        insert t;
        
        fuel.salesOrder = [Select id, Has_Exceptions__c from Sales_Order__c where id = :fuel.salesOrder.ID limit 1];
        system.assertEquals(fuel.salesOrder.Has_Exceptions__c, true);
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,8,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 120, Quantity__c = 6, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,(Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(0,lCIs.size());
                        
    }
    
    static testMethod void InvoiceGrouping_BillToForSpecificCustomer() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        
        String customers = JSON.serialize(new set<ID> {fuel.customerSoldTo.ID});
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, For_Customers__c = customers, Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Billing_UOM__c = fuel.CalendarQuarter.Id, Recurrence_Start_Date__c = DateTime.newInstance(2015,5,20,0,0,0));
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,8,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 120, Quantity__c = 6, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        
        
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Bill_To_Customer__c, Balance__c, Planned_Invoice_Date__c, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(2,lCIs.size());
        map<Date,integer> mInvoicedDates = new map<Date,Integer>();
        for(Customer_Invoice__c ci : lCIs) {
            system.assertEquals(true, ci.Finalized__c, ci);
            system.assertEquals('Standard', ci.Invoice_Type__c);
            system.assertEquals(jobId, ci.Batch_Job_ID__c);
            system.assertEquals(fuel.customerBillTo.Id, ci.Bill_To_Customer__c); //KNDY-8689
            mInvoicedDates.put(ci.Date_Invoiced__c.date(), ci.Customer_Invoice_Lines__r.size());
        }

    }

    static testMethod void InvoiceGrouping_AggregateImmediateSucess() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
       

        insert lFs;
        
        
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,(Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(1,lCIs.size());
        map<Date,integer> mInvoicedDates = new map<Date,Integer>();
        for(Customer_Invoice__c ci : lCIs) {
            system.assertEquals(true, ci.Finalized__c);
        }
        list<Customer_Invoice_Sub_Line__c> subLines = [Select id from Customer_Invoice_Sub_Line__c where Fulfillment__c in :lFs];
        system.assertEquals(3,subLines.size());
        
                        

    }
    static testMethod void InvoiceGrouping_plannedInvoiceBlockFuture() {//KNDY-9322 //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        Date dtNow = system.now().date();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addDays(-2), Time.newInstance(0,0,0,0)),  rank__c = 1, Billing_UOM__c = fuel.WEEK.Id, Recurrence_Start_Date__c = DateTime.newInstance(dtNow.addDays(1), Time.newInstance(0,0,0,0)),
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c =DateTime.newInstance(dtNow, Time.newInstance(0,0,0,0)), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,(Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(0, lCIs.size());
    }
    

    
    
    static testMethod void InvoiceGrouping_blockReInvoiceifHasExceptions() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Customer_Invoice__c = CustomerInvoice.Id;
        cil.Quantity_Shipped__c = 1;
        cil.Unit_Price__c = 100;
        insert cil;
        
        Customer_Invoice_Sub_Line__c subl = new Customer_Invoice_Sub_Line__c(Customer_Invoice_Line__c = cil.ID, Fulfillment__c = lFs[0].Id);
        insert subl;
        
        
        Task t = new Task(WhatID = cil.Id, Type = 'Exception', Subject='Some Exception', Status= 'Open', Exception_Code__c = 'TEST-001');
        insert t;
        
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice_Sub_Line__c> lSubls = [Select Id from Customer_Invoice_Sub_Line__c where Fulfillment__c = :lFs[0].Id and Customer_Invoice_Line__r.Finalized__c = true];
        system.assertEquals(0,lSubls.size());
        
        
    }
    static testMethod void InvoiceGrouping_overrideBillTo() {// KNDY-9342 //DONE
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Corporate Parent', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);

        insert igr;
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        Customer__c customerBillTo = new Customer__c(); 
        customerBillTo.name = 'Customer Bill To 1 Cloned';
        customerBillTo.recordTypeId = Schema.SObjectType.Customer__c.getRecordTypeInfosByName().get('Bill To').getRecordTypeId();
        customerBillTo.Company__c = fuel.company.id;
        customerBillTo.Payment_Term__c = fuel.terms.ID;
        //customerBillTo.Address__c = fuel.account.ID;
        customerBillTo.Credit_Limit__c = 100000.0;
        customerBillTo.Parent_Customer__c = fuel.customerParent.id; 
        customerBillTo.Top_Parent_Customer__c = fuel.customerParent.id;
        customerBillTo.Customer_Identifier__c = 'BDTEST123-1';
        customerBillTo.Status__c = 'Approved';
        insert customerBillTo;
        
        fuel.customerParent.Default_Bill_To_Customer__c = customerBillTo.Id;
        update fuel.customerParent;
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice_Sub_Line__c> lSubls = [Select Id,Customer_Invoice_Line__r.Customer_Invoice__r.Bill_To_Customer__c from Customer_Invoice_Sub_Line__c where Fulfillment__c = :lFs[0].Id and Customer_Invoice_Line__r.Finalized__c = true];
        system.assertEquals(1,lSubls.size());
        system.assertEquals(customerBillTo.Id, lSubls[0].Customer_Invoice_Line__r.Customer_Invoice__r.Bill_To_Customer__c);
    }

    static testMethod void InvoiceGrouping_ReInvoiceIfCancelled() { //DONE
        TestFuelQuery fuel = new TestFuelQuery();
         test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Occurrence__c = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c,Price_Type__c ='Sales', Status__c = 'Complete'));

        insert lFs;
        
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Standard';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Customer_Invoice__c = CustomerInvoice.Id;
        cil.Quantity_Shipped__c = 1;
        cil.Unit_Price__c = 100;
        insert cil;
        
        Customer_Invoice_Sub_Line__c subl = new Customer_Invoice_Sub_Line__c(Customer_Invoice_Line__c = cil.ID, Fulfillment__c = lFs[0].Id);
        insert subl;
        
        CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
        CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
        system.assert(!ext.getDisableCancel() == true,ext.getVoidCancelDetails());
        try {
            ext.cancelDocs();
        }catch(Exception ex) {
            system.debug('ex '+ex);
        }
        
        
        system.debug('ci '+[Select Id, Has_Exceptions__c, Status__c from Customer_Invoice__c]);
        Fulfillment__c f = [select ID, Start_Date__c, Occurrence__c, (Select Id from Customer_Invoice_Sub_Lines__r) from Fulfillment__c limit 1];
        system.debug('f '+f.Customer_Invoice_Sub_Lines__r);
        
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice_Sub_Line__c> lSubls = [Select Id from Customer_Invoice_Sub_Line__c where Fulfillment__c = :lFs[0].Id and Customer_Invoice_Line__r.Finalized__c = true];
        system.assertEquals(1,lSubls.size());
     }

     static testMethod void InvoiceGrouping_RecurringSucess_ProRate() { //KNDY-9914, KNDY-10407 //NEEDS PRICING SERVICE TO BE UPDATED
        TestFuelQuery fuel = new TestFuelQuery();
        Date dtNow = system.now().date();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)), rank__c = 1, Billing_UOM__c = fuel.CalendarMonth.ID, Recurrence_Start_Date__c =  DateTime.newInstance(Date.newInstance(2014,5,10), Time.newInstance(0,0,0,0)),
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Start_Date__c = DateTime.newInstance(Date.newInstance(2014,4,24), Time.newInstance(0,0,0,0));
            sol.End_Date__c = DateTime.newInstance(Date.newInstance(2014,7,24), Time.newInstance(0,0,0,0));
            sol.Rate_Basis__c = 'Quantity';
            
        }
        update lSOLs;
        

        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c,Price_Type__c ='Recurring', Status__c = 'Complete', Pricing_UOM__c = fuel.CalendarMonth.ID);

        insert f;



		Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c,Transaction_Date__c, (Select ID, Start_Date__c, End_Date__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        system.assertEquals(4,lCIs.size(),lCIs[0].Customer_Invoice_Lines__r);
        list<Customer_Invoice_Line__c> lCILs = [Select Id, Extended_Price__c, Start_Date__c, End_Date__c from Customer_Invoice_Line__c order by Start_Date__c asc];
        system.assertEquals(4, lCILs.size(), lCILs);
        system.assert(lCILs[0].Extended_Price__c < 98.00, 'This is a pro rated line '+lCIls);
        system.assert(lCILs[1].Extended_Price__c == 98.00, 'This is not a pro rated line '+lCIls[1]);// tied to testFuel SOL[0];
        system.assert(lCILs[2].Extended_Price__c == 98.00, 'This is not a pro rated line '+lCIls[2]);// tied to testFuel SOL[0];
        system.assert(lCILs[3].Extended_Price__c < 98.00, 'This is a pro rated line '+lCIls[3]);
        

        
       
    }
    
    
    static testMethod void InvoiceGrouping_AllowanceAccrualCI_Success() { //KNDY-14713
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Date dtNow = system.now().date();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id,  Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        system.assertEquals(2,lSOLs.size());
        
        Allowance_Type__c at = new Allowance_type__c(
            Basis__c = AllowanceRuleService.BASIS_RATE_BY,
            Rate_Field__c = 'Quantity',
            Manual__c = true,
            Type__c = 'Accrual',
            amount__c = 1.5,
            name = 'Allowance Accrual$1.5'
        );
        insert at;
         
        Allowance_Applied__c aa1 = new Allowance_Applied__c();
        aa1.Allowance_Class__c = 'Standard';
        aa1.Allowance_Type__c = at.Id;
        aa1.BillBack_Commitment__c = 10;
        List<Allowance_Applied__c> lallwanceApplied = new List<Allowance_Applied__c>();
        lallwanceApplied.add(aa1);
        insert lallwanceApplied;
		
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Allowance_Applied__c = aa1.Id, Type__c = 'Sales Order Shipment', Status__c = 'Complete', Invoice_Ready__c = true, Invoice_Hold__c = false,Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Allowance_Applied__c = aa1.Id, Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Status__c = 'Complete',Invoice_Ready__c = true, Invoice_Hold__c = false,Unit_Price__c = 1, Quantity__c = 4, Product__c = lSOLs[0].Product__c));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Allowance_Applied__c = aa1.Id, Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Status__c = 'Complete', Invoice_Ready__c = true, Invoice_Hold__c = false, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
        insert lFs;
        
        Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Total_Amount__c,(Select id, Customer_Invoice__c, Product_Reference__c, Allowance_Applied__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(3,lCIs.size());
        
        system.assertNotEquals(null, fuel.customerProdRef.Id);
		Cross_Reference__c crossRef = [Select Id from Cross_Reference__c where Name = 'CR01' limit 1];
        
        List<Customer_Invoice__c> allowanceAccrualCIs = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> allowanceAccrualCILs = new List<Customer_Invoice_Line__c>();
        for (Customer_Invoice__c ci : lCIs){
            system.assertEquals(ci.Finalized__c, true, '>>> ci: ' + ci);
            if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){
                allowanceAccrualCIs.add(ci);
                allowanceAccrualCILs.add(ci.Customer_Invoice_Lines__r);
            }
        }
        system.assertEquals(allowanceAccrualCIs.size(), 2, '>>>allowanceAccrualCIs: ' +allowanceAccrualCIs);
        system.assertEquals(allowanceAccrualCILs.size(), 2, '>>>allowanceAccrualCILs: ' + allowanceAccrualCILs);
        for (Customer_Invoice_Line__c cil: allowanceAccrualCILs){
            system.assertEquals(cil.Allowance_Applied__c, aa1.Id);
            system.assertEquals(crossRef.Id, cil.Product_Reference__c);
        }
    }

    static testMethod void InvoiceGrouping_AllowanceAccrualCIOnly_Success() { //KNDY-14713
        TestFuelQuery fuel = new TestFuelQuery();
        test.startTest();
        Date dtNow = system.now().date();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id,  Use_Billing_Frequency_on_Fulfillment__c = true);
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Status__c = 'Complete',Invoice_Ready__c = true, Invoice_Hold__c = false,Unit_Price__c = 1, Quantity__c = 4, Product__c = lSOLs[0].Product__c));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Status__c = 'Complete', Invoice_Ready__c = true, Invoice_Hold__c = false, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
        insert lFs;
        
        Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,(Select id, Customer_Invoice__c, Allowance_Applied__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(2,lCIs.size());
        List<Customer_Invoice__c> allowanceAccrualCIs = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> allowanceAccrualCILs = new List<Customer_Invoice_Line__c>();
        for (Customer_Invoice__c ci : lCIs){
            if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){
                allowanceAccrualCIs.add(ci);
                allowanceAccrualCILs.add(ci.Customer_Invoice_Lines__r);
            }
        }
        system.assertEquals(allowanceAccrualCIs.size(), 2, '>>>allowanceAccrualCIs: ' +allowanceAccrualCIs);
        system.assertEquals(allowanceAccrualCILs.size(), 2, '>>>allowanceAccrualCILs: ' + allowanceAccrualCILs);
        List<Customer_Invoice_Sub_Line__c> ciSubLines = [Select Id, Customer_Invoice_Line__c,
             Fulfillment__c from Customer_Invoice_Sub_Line__c where
             Fulfillment__c in: lFs];
        system.assertEquals(ciSubLines.size(), 2, '>>>ciSubLines: ' + ciSubLines);
    }
    
    static testMethod void InvoiceGrouping_AllowanceAccrualFail_HoldInvoicing() { //KNDY-14713
        TestFuelQuery fuel = new TestFuelQuery();
        Reason_Code__c holdCode = new Reason_Code__c();
        holdCode.Company__c = fuel.company.Id;
        holdCode.Type__c = 'Invoice Hold';
        holdCode.Code__c = 'D001';
        insert holdCode;
        test.startTest();

        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Invoice_Ready__c = true, Invoice_Hold__c = true, Reason_Code__c = holdCode.id, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c));
        insert lFs;
        
        Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,(Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(0,lCIs.size());
    }
	
	static testMethod void UpdateDelIGR_Fail(){ //KNDY-15790
        Date dtNow = system.now().date();
        Company__c cmp = [Select Id from Company__c where Name like '%Main Company%'];
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = cmp.Id,  Use_Billing_Frequency_on_Fulfillment__c = true);
        insert igr;
        boolean error = false;
        Test.startTest();
        try{
        	igr.rank__c = 2;
        	update igr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_IGR)){
        		error = true;
        	}
        }
        system.assert(error);
        error = false;
        
        try{
        	delete igr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_IGR)){
        		error = true;
        	}
        }
        system.assert(error);
        Test.stopTest();
	}
	
	static testMethod void UpdateDelIGR_Success(){ //KNDY-15790
        Date dtNow = system.now().date();
        Company__c cmp = [Select Id from Company__c where Name like '%Main Company%'];
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = cmp.Id,  Use_Billing_Frequency_on_Fulfillment__c = true);
        insert igr;
        boolean error = false;
        Test.startTest();
        InvoiceGroupingRuleService.requestFromUI = true;	
        try{
        	igr.rank__c = 2;
        	update igr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_IGR)){
        		error = true;
        	}
        }
        system.assert(!error);
        error = false;
        
        try{
        	delete igr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_IGR)){
        		error = true;
        	}
        }
        system.assert(error);
        Test.stopTest();
	}
    //******  10/26/2016 *************/
    //************End of methods that should be moved to InvoiceGroupingTest cls
    /********* **********/
}