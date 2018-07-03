@isTest
public with sharing class PeriodServiceTest {
 //Get the periodstartDates, Company Ids and Check if it falls in the open Period
    @testSetup
    static void testDataSetUp() {
        Test.StartTest();
        PeriodData Pdata = new PeriodData();
        Test.stopTest();
    } 
    public class AEReadyData{
        public AEReadyData(){
            Company__c comp = [Select Id from Company__c where Name = '400' limit 1];
        Currency__c usdCurr = [Select Id from Currency__c where ISO_Code__c = 'USD'];
        
        List<Segment_Definition__c> customsegList = new List<Segment_Definition__c>();
        Segment_Definition__c custom_seg1 = new Segment_Definition__c();
        custom_seg1.Name = 'Company__c';
        custom_seg1.Accounting_Entry_Field__c = 'Company__c'; // just need a field to stuff into
        custom_seg1.Object_API_Name__c = 'Company__c';
        custom_seg1.Segment_Number__c = 1;
        customsegList.add(custom_seg1);
        
        Segment_Definition__c custom_seg2 = new Segment_Definition__c();
        custom_seg2.Name = 'GL_Account__c';
        custom_seg2.Accounting_Entry_Field__c = 'GL_Account__c'; // just need a field to stuff into
        custom_seg2.Object_API_Name__c = 'GL_Account__c';
        custom_seg2.Accounting_Rule_Segment__c = 'GL_Account__c';
        custom_seg2.Accounting_Rule_Reference_Value__c = 'GL_Account_Reference_Value__c';
        custom_seg2.Accounting_Rule_Default__c = 'Default_GL_Account__c';
        custom_seg2.Segment_Number__c = 2;
        customsegList.add(custom_seg2);
        
        insert customsegList;  
        Account address = new Account();{
            address.Name = 'Test Facility';
            address.BillingStreet = '123 Main St.';
            address.BillingCity = 'Redwood City';
            address.BillingState = 'CA';
            insert address;
        }

         Facility__c facility = new Facility__c();{
             facility.Company__c = comp.id;
            facility.Name = 'Test Facility';
            facility.Address__c = address.Id;
            insert facility;
        }
         Location__c location = new Location__c();{
            location = new Location__c();
            location.Facility__c = facility.id;
            location.name = 'Test Location';
            insert location; 
        }

        Bank_Account__c bankAccount = new Bank_Account__c();{
            bankAccount.Name = 'Test BOFA';
            bankAccount.account_type__c = 'Checking';
            //bankAccount.GL_Account__c = [Select Id from GL_Account__c limit 1].Id;
            bankAccount.active__c = true;
            bankAccount.Currency__c = usdCurr.id;
            insert bankAccount;
        }

        Payment_Term__c terms = new Payment_Term__c(); {
            terms.name = 'Test Terms'; 
            terms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS;
            terms.Due_Days__c =0; 
            insert terms; 
        }
         List<UOM__c> uomList = new List<UOM__c>(); 
          List<String> uoms = new List<String>{'LB', 'TN', 'DZ', 'OZ', 'MI', 'YD', 'IN', 'FT', 'FT3','EA'};
          List<String> uomdescs = new List<String>{'Pound', 'Ton', 'Dozen', 'Ounce', 'Mile', 'Yard', 'Inch', 'Foot', 'Cubic','Each'};
        
        {       
            for (Integer i = 0; i < uoms.size(); ++i) {
                UOM__c Obj = new UOM__c();
                Obj.Name = uoms[i];
                Obj.Description__c = uomdescs[i];
                uomList.add(Obj);
            }
            insert uomList;
        } 
         Class__c itemClass, itemClass1, itemClass2, itemClass3; 
         List<Class__c> classList = new List<Class__c>();{
           itemClass1 = new Class__c();
            itemClass1.Type__c = 'Goods';
            itemClass1.Name = 'Goods';
            classList.add(itemClass1); 
            
            itemClass2 = new Class__c();
            itemClass2.Type__c = 'Miscellaneous';
            itemClass2.Name = 'Miscellaneous';
            classList.add(itemClass2); 
            
            itemClass3 = new Class__c();
            itemClass3.Type__c = 'Expense';
            itemClass3.Name = 'Expense';
            classList.add(itemClass3); 
            
            insert classList;
            
            itemClass = classList[0];
        
        }

         List<Item__c> itemList = new List<Item__c>();{
             
            Item__c ItemObj2=new Item__c();
            ItemObj2.name='HP Printer';
            ItemObj2.Description__c='It is a Test item';
            ItemObj2.Source__c=Label.Source_field_of_ItemP;
            ItemObj2.Company__c = comp.id;
            ItemObj2.Class__c = itemClass1.id;
            ItemObj2.Stocking_UOM__c = uomList[0].ID;
            ItemObj2.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[0].Id});
            
            itemList.add(ItemObj2);
            
            Item__c ItemObj3=new Item__c();
            ItemObj3.name='HP Printer 3';
            ItemObj3.Description__c='It is a Test item';
            ItemObj3.Source__c='Manufactured';
            ItemObj3.Company__c = comp.id;
            ItemObj3.Class__c = itemClass2.id;
            ItemObj3.Stocking_UOM__c = uomList[0].ID;
            ItemObj3.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[0].Id});
            
            itemList.add(ItemObj3);
            
            Item__c ItemObj4=new Item__c();
            ItemObj4.name='HP Printer 4';
            ItemObj4.Description__c='It is a Test item';
            ItemObj4.Source__c='Expense';
            itemObj4.Non_Inventory__c = true; 
            ItemObj4.Company__c = comp.id;
            ItemObj4.Class__c = itemClass3.id;
            ItemObj4.Stocking_UOM__c = uomList[0].ID;
            ItemObj4.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[0].Id});
            
            itemList.add(ItemObj4);
            insert itemList;
        }

             map <string,string> SupplierRecordTypes = KSE.RecordTypeDevNameMap('Supplier__c');
             Supplier__c remittosupplier = new Supplier__c();
            remittosupplier = new Supplier__c();
            remittosupplier.Status__c = 'Active';
            remittosupplier.Name = 'Test Remit To Supplier';
            remittosupplier.Type__c = 'Remit-To';
            remitToSupplier.RecordTypeId = SupplierRecordTypes.get('Remit_To');
            remitToSupplier.company__c = comp.id;
            insert remittosupplier; 

            Supplier__c supplier = new Supplier__c();
            supplier = new Supplier__c();
            supplier.status__C = 'Active';
            supplier.Name = 'Test Supplier';
            supplier.Type__c = 'Purchasing';
            supplier.RecordTypeId = SupplierRecordTypes.get('Purchase_From');
            supplier.Remit_To__c =  remittosupplier.id;
            supplier.company__c = comp.id;
            insert supplier; 

            Purchase_Order__c purchaseOrder1 = new Purchase_Order__c();
            Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();
            Purchase_Order__c purchaseOrder3 = new Purchase_Order__c();
            Purchase_Order__c purchaseOrder4 = new Purchase_Order__c();

            purchaseOrder1.Order_Date__c = system.today();
            purchaseOrder1.status__c = 'Open';
            purchaseOrder1.Supplier__c = supplier.id; 
            purchaseOrder1.Remit_To_Supplier__c = remittosupplier.id; 
            purchaseOrder1.Company__c = comp.id;
            purchaseOrder1.Payment_Term__c = terms.id;
            purchaseOrder1.Memo__c = 'PurchaseOrder1';
            purchaseOrder1.Currency__c = usdCurr.id;

            purchaseOrder2.Order_Date__c = system.today();
            purchaseOrder2.status__c = 'Open';
            purchaseOrder2.Supplier__c = supplier.id;
            purchaseOrder2.Remit_To_Supplier__c = remittosupplier.id; 
            purchaseOrder2.Company__c = comp.id;
            purchaseOrder2.Payment_Term__c = terms.id;
            purchaseOrder2.Memo__c = 'PurchaseOrder2';
            purchaseOrder2.Currency__c = usdCurr.id;
       
            purchaseOrder3.Order_Date__c = system.today();
            purchaseOrder3.Supplier__c = supplier.id; 
            purchaseOrder3.Remit_To_Supplier__c = remittosupplier.id;
            purchaseOrder3.Company__c = comp.id;
            purchaseOrder3.Payment_Term__c = terms.id;
            purchaseOrder3.status__c = 'Open';
            purchaseOrder3.Memo__c = 'PurchaseOrder3';
            purchaseOrder3.Currency__c = usdCurr.id;                
       
            purchaseOrder4.Order_Date__c = system.today();
            purchaseOrder4.Supplier__c = supplier.id;
            purchaseOrder4.Remit_To_Supplier__c = remittosupplier.id; 
            purchaseOrder4.Company__c = comp.id;
            purchaseOrder4.Payment_Term__c = terms.id;
            purchaseOrder4.status__c = 'Open';
            purchaseOrder4.Memo__c = 'PurchaseOrder4';
            purchaseOrder4.Currency__c = usdCurr.id;
            insert new List<sobject>{ purchaseOrder1, purchaseOrder2, purchaseOrder3, purchaseOrder4};
            List<Purchase_Order_Line__c> objPODetailList = new List<Purchase_Order_Line__c>();

            Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
            objPODetail.Purchase_Order__c = purchaseOrder1.Id;
            objPODetail.Order_Quantity__c = 10;        
            objPODetail.Unit_Price__c = 12;
            objPODetail.Item__c = itemList[0].Id;
            objPODetail.Purchase_UOM__c = uomList[0].Id;
            objPODetail.Status__c = Label.Open;    
            objPODetail.Need_Date__c = System.today();
            objPODetail.Company__c = comp.id;
            objPODetail.Delivery_Location__c = location.ID;
            objPODetail.Delivery_facility__c = location.facility__c;
            objPODetail.Supplier__c = supplier.Id;
             System.debug(LoggingLevel.ERROR,'___itemList[0].Id__'+itemList[0].Id);
            objPODetailList.add( objPODetail );                   

            Purchase_Order_Line__c objPODetail1 = new Purchase_Order_Line__c();
                objPODetail1.Purchase_Order__c = purchaseOrder2.Id;
                objPODetail1.Order_Quantity__c = 10;        
                objPODetail1.Unit_Price__c = 25;
                objPODetail1.Item__c = itemList[0].Id;
                objPODetail1.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail1.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail1.Status__c = Label.Open;    
                objPODetail1.Need_Date__c = System.today();
                objPODetail1.Company__c = comp.id;
                objPODetail1.Delivery_Location__c = location.ID;
                objPODetail1.Delivery_facility__c = location.facility__c;
                objPODetail1.Supplier__c = supplier.Id;
                objPODetail1.Invoice_Matching__c = 'Two Way';
               
                objPODetailList.add(objPODetail1);                    
                
                Purchase_Order_Line__c objPODetail2 = new Purchase_Order_Line__c();
                objPODetail2.Purchase_Order__c = purchaseOrder2.Id;
                objPODetail2.Order_Quantity__c = 5;        
                objPODetail2.Unit_Price__c = 15;
                objPODetail2.Item__c = itemList[0].Id;
                objPODetail2.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail2.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail2.Status__c = Label.Open;    
                objPODetail2.Need_Date__c = System.today();
                objPODetail2.Company__c = comp.id;
                objPODetail2.Delivery_Location__c = location.ID;
                objPODetail2.Delivery_facility__c = location.facility__c;
                objPODetail2.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail2);  
                
                
                Purchase_Order_Line__c objPODetail4 = new Purchase_Order_Line__c();
                objPODetail4.Purchase_Order__c = purchaseOrder3.Id;
                objPODetail4.Order_Quantity__c = 10;        
                objPODetail4.Unit_Price__c = 25;
                objPODetail4.Item__c = itemList[0].Id;
                objPODetail4.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail4.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail4.Status__c = Label.Open;    
                objPODetail4.Need_Date__c = System.today();
                objPODetail4.Company__c = comp.id;
                objPODetail4.Delivery_Location__c = location.ID;
                objPODetail4.Delivery_facility__c = location.facility__c;
                objPODetail4.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail4);                     // line trigger sets the Line__c sequence
                
                Purchase_Order_Line__c objPODetail5 = new Purchase_Order_Line__c();
                objPODetail5.Purchase_Order__c = purchaseOrder3.Id;
                objPODetail5.Order_Quantity__c = 5;        
                objPODetail5.Unit_Price__c = 15;
                objPODetail5.Item__c = itemList[0].Id;
                objPODetail5.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail5.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail5.Status__c = Label.Open;    
                objPODetail5.Need_Date__c = System.today();
                objPODetail5.Company__c = comp.id;
                objPODetail5.Delivery_Location__c = location.ID;
                objPODetail5.Delivery_facility__c = location.facility__c;
                objPODetail5.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail5);  
                
      
                Purchase_Order_Line__c objPODetail6 = new Purchase_Order_Line__c();
                objPODetail6.Purchase_Order__c = purchaseOrder4.Id;
                objPODetail6.Order_Quantity__c = 1;        
                objPODetail6.Unit_Price__c = 25;
                objPODetail6.Item__c = itemList[1].Id;
                objPODetail6.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail6.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail6.Status__c = Label.Open;    
                objPODetail6.Need_Date__c = System.today();
                objPODetail6.Company__c = comp.id;
                objPODetail6.Delivery_Location__c = location.ID;
                objPODetail6.Delivery_facility__c = location.facility__c;
                objPODetail6.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail6);                     // line trigger sets the Line__c sequence
                
                Purchase_Order_Line__c objPODetail7 = new Purchase_Order_Line__c();
                objPODetail7.Purchase_Order__c = purchaseOrder4.Id;
                objPODetail7.Order_Quantity__c = 2;        
                objPODetail7.Unit_Price__c = 20;
                objPODetail7.Item__c = itemList[0].Id;
                objPODetail7.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail7.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail7.Status__c = Label.Open;    
                objPODetail7.Need_Date__c = System.today();
                objPODetail7.Company__c = comp.id;
                objPODetail7.Delivery_Location__c = location.ID;
                objPODetail7.Delivery_facility__c = location.facility__c;
                objPODetail7.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail7); 
                
                Purchase_Order_Line__c objPODetail3 = new Purchase_Order_Line__c();
                objPODetail3.Purchase_Order__c = purchaseOrder4.Id;
                objPODetail3.Order_Quantity__c = 2;        
                objPODetail3.Unit_Price__c = 10;
                objPODetail3.Item__c = itemList[0].Id;
               
                objPODetail3.Purchase_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail3.Stocking_UOM__c = [Select Stocking_UOM__c from Item__c where Id =: itemList[0].Id].Stocking_UOM__c;
                objPODetail3.Status__c = Label.Open;    
                objPODetail3.Need_Date__c = System.today();
                objPODetail3.Company__c = comp.id;
                objPODetail3.Delivery_Location__c = location.ID;
                objPODetail3.Delivery_facility__c = location.facility__c;
                //objPODetail3.Line_Type__c = 'Standard';
                objPODetail3.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail3); 
                 System.debug(LoggingLevel.ERROR,'___objPODetailList__'+objPODetailList.size());
                insert objPODetailList;   

                    Receiving_Document__c receivingDocument1 = new Receiving_Document__c();
                receivingDocument1 = new Receiving_Document__c();
                receivingDocument1.Company__c = comp.id;
                receivingDocument1.Supplier__c = supplier.Id;
                receivingDocument1.Status__c = 'Open';
                receivingDocument1.Date_Created__c = system.today();
                receivingDocument1.Type__c = 'Purchase Order Receipt';
                insert receivingDocument1;
              
            
                Receipt_Line__c receiptLine1 = new Receipt_Line__c();
                receiptLine1.Purchase_Order__c = purchaseOrder2.Id;
                receiptLine1.Purchase_Order_Line__c = objPODetail2.Id;
                receiptLine1.Item__c = itemList[0].Id;
                receiptLine1.Company__c = comp.id;
                receiptLine1.Supplier__c = supplier.Id;
                receiptLine1.Quantity_Received__c = 4;
                receiptLine1.Uninvoiced_Quantity__c = 4;
                receiptLine1.Facility__c = facility.Id;
                receiptLine1.Location__c = location.Id;
                receiptLine1.Receiving_Document__c = receivingDocument1.Id;
                insert receiptLine1;
            
                // Receive POL order quantity in full
                objPODetail2.Quantity_Received__c = 4; 
                update objPODetail2;
                periodListForCompany(comp.Id);
        }
    }
    public class PeriodData{   
        public Set<Id> companyIds = new Set<Id>();
        Datetime currentDate = system.now();
        Integer year = currentDate.year();
        public String periodName1;
        public Company__c company4 = new Company__c();
        public List<Company__c> mycompanies = new List<Company__c>(); {
            Company__c company1 = new Company__c();
            company1.name = '100';
            company1.A_Days__c = 6;
            company1.B_Days__c = 20;
            company1.C_Days__c = 90;
            company1.Default_Transaction_Currency__c = TestFuel.currencySGD.id;
            company1.Consol_Currency__c = TestFuel.currencyEUR.id;
            company1.Stat_Currency__c = TestFuel.currencyGBP.id;
            company1.Subs_Currency__c = TestFuel.currencyUSD.id;
            company1.Comp_Currency__c = TestFuel.currencyUSD.id;
            
            mycompanies.add(company1);
            
            Company__c company2 = new Company__c();
            company2.name = '200';
            company2.A_Days__c = 8;
            company2.B_Days__c = 2;
            company2.C_Days__c = 9;
            company2.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
            company2.Consol_Currency__c = TestFuel.currencyEUR.id;
            company2.Stat_Currency__c = TestFuel.currencyGBP.id;
            company2.Subs_Currency__c = TestFuel.currencyUSD.id;
            company2.Comp_Currency__c = TestFuel.currencyUSD.id;
            
            mycompanies.add(company2);

            Company__c company3 = new Company__c();
            company3.name = '300';
            company3.A_Days__c = 8;
            company3.B_Days__c = 2;
            company3.C_Days__c = 9;
            company3.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
            company3.Consol_Currency__c = TestFuel.currencyEUR.id;
            company3.Stat_Currency__c = TestFuel.currencyGBP.id;
            company3.Subs_Currency__c = TestFuel.currencyUSD.id;
            company3.Comp_Currency__c = TestFuel.currencyUSD.id;
            
            mycompanies.add(company3);
            
            company4.name = '400';
            company4.A_Days__c = 8;
            company4.B_Days__c = 2;
            company4.C_Days__c = 9;
            company4.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
            company4.Consol_Currency__c = TestFuel.currencyEUR.id;
            company4.Stat_Currency__c = TestFuel.currencyGBP.id;
            company4.Subs_Currency__c = TestFuel.currencyUSD.id;
            company4.Comp_Currency__c = TestFuel.currencyUSD.id;
            
            mycompanies.add(company4);

            insert mycompanies;
            companyIds.add(company1.id);
            companyIds.add(company2.id);
            //companyIds.add(company3.id);
        }
        public String periodName(Datetime myDT){
            String myDate = myDT.format('MMM-yyyy');
            // .debug( myDate.toUpperCase() );
            system.assertNotEquals(myDate,null);
            return myDate.toUpperCase();
        }
        
        public Period__c period1 = new Period__c();{
            
            Datetime currTime = system.now();
            
            Date currDate = currTime.date();
            Date begOfMonthDate = currDate.toStartOfMonth();
            Date endOfMonthDate = begOfMonthDate.addMonths(1).addDays(-1);              
            
            Date begOfYearDate = Date.newInstance(currDate.year(), 1, 1);
            Date endOfYearDate = Date.newInstance(currDate.year(), 12, 31);
            
            Datetime begOfMonthDatetime = DateTime.newInstance(currDate.year(), currDate.month(), 1);
            Datetime endOfMonthDatetime = DateTime.newInstance(endOfMonthDate.year(), endOfMonthDate.month(), endOfMonthDate.day(), 23, 59, 00);            
            
            
            String periodName1 = periodName(Datetime.now());
            // .debug(periodName1);   
            period1.Name = periodName1;
            period1.Period_Number__c = 12;
            period1.Quarter_Number__c = 4;
            period1.Adjustment_Period__c = false;
            period1.Closed__c = false;
            period1.Open__c = true;
            period1.Fiscal__c = true;
            period1.Corporate__c = false;
            period1.Tax__c = false;
            period1.Permanently_Closed__c = false;
            period1.Year_Start_Date__c = begOfYearDate;
            period1.Year_End_Date__c = endOfYearDate;
            period1.Company__c = mycompanies[0].Id;
            period1.Fiscal_Year__c = String.valueOf(currDate.year());
            //period1.Period_Start__c = DateTime.newInstance(system.today().year(),system.today().month(),1,00,00,00);
            period1.Period_Start__c = begOfMonthDatetime;
            period1.Period_End__c = endOfMonthDatetime; 
            period1.AP_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.AR_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.Shipment_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.Receiving_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.FA_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.Inventory_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.JE_Cutoff__c = endOfMonthDatetime;
            

            Fiscal_Year__c fy = new Fiscal_Year__c();

            fy.company__c = mycompanies[0].Id;
            fy.fiscal_year_start_date__c = period1.period_start__c;
            fy.fiscal_year_end_date__c = period1.period_end__c.addMonths(3);
            
            insert fy;
        
            period1.fiscalyear__c = fy.Id;
            insert period1;
        }   

    }

    public static List<Period__c> periodListForCompany(Id companyId) {
        List<Period__c> periodList = null;
        if (periodList == null) {
            integer year = system.now().year();
            periodList = new List<Period__c>();
            //insert current year
            for(integer i=1; i<=12; i++){
                Period__c iPeriod = new Period__c();
                iPeriod.Name = string.valueOf(i)+ '-' + String.ValueOf((Integer) (Math.random () * 999) + system.now().getTime());
                iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
                iPeriod.Period_Number__c = i;
                if(i>=1 && i <= 3){
                    iPeriod.Quarter_Number__c = 1;
                }else if(i>=4 && i <= 6){
                    iPeriod.Quarter_Number__c = 2;
                }else if(i>=7 && i <= 9){
                    iPeriod.Quarter_Number__c = 3;
                }else if(i>=10 && i <= 12){
                    iPeriod.Quarter_Number__c = 4;
                }   
                
                iPeriod.Fiscal_Year__c = String.valueOf(year);
                iPeriod.Company__c = companyId;
                iPeriod.Adjustment_Period__c = false;
                iPeriod.Closed__c = false;
                iPeriod.Open__c = i >= system.now().month();
                iPeriod.Fiscal__c = true;
                iPeriod.Corporate__c = false;
                iPeriod.Tax__c = false;
                iPeriod.Permanently_Closed__c = false;
                iPeriod.Adjustment_Period__c = false;
                
                iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.JE_Cutoff__c = iPeriod.Period_End__c;
                
                periodList.add(iPeriod);
            }
            //insert next year
            year++;
            for(integer i=1; i<=12; i++){
                Period__c iPeriod = new Period__c();
                iPeriod.Name = string.valueOf(i)+ '-' + String.ValueOf((Integer) (Math.random () * 999) + system.now().getTime());
                iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
                iPeriod.Period_Number__c = i;
                if(i>=1 && i <= 3){
                    iPeriod.Quarter_Number__c = 1;
                }else if(i>=4 && i <= 6){
                    iPeriod.Quarter_Number__c = 2;
                }else if(i>=7 && i <= 9){
                    iPeriod.Quarter_Number__c = 3;
                }else if(i>=10 && i <= 12){
                    iPeriod.Quarter_Number__c = 4;
                }   
                
                iPeriod.Fiscal_Year__c = String.valueOf(year);
                iPeriod.Company__c = companyId;
                iPeriod.Adjustment_Period__c = false;
                iPeriod.Closed__c = false;
                iPeriod.Open__c = i >= system.now().month();
                iPeriod.Fiscal__c = true;
                iPeriod.Corporate__c = false;
                iPeriod.Tax__c = false;
                iPeriod.Permanently_Closed__c = false;
                iPeriod.Adjustment_Period__c = false;
                
                iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
                iPeriod.JE_Cutoff__c = iPeriod.Period_End__c;
                
                periodList.add(iPeriod);
            }
            
            Fiscal_Year__c fy = new Fiscal_Year__c();
            fy.company__c = companyId;
            fy.fiscal_year_start_date__c = periodList[0].period_start__c;
            fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
            
            insert fy;
            for(Period__c p : periodList){
                p.fiscalyear__c = fy.Id;
            }
            
            insert periodList;
        } 
        return periodList;
    }

    public static testMethod void myUnitTest1() {
        /*TODO: RS
        PeriodData Pdata = new PeriodData();
        // Create Accounting Entry with GL Date populated and check if the period is defaulted.
        //Date nextPeriodGLDate = Date.newInstance(system.today().year(), system.today().addMonths(1).month(), 1);
        Accounting_Entry__c acctEntry1 = new Accounting_Entry__c();
        acctEntry1.Company__c = Pdata.mycompanies[0].Id;
        acctEntry1.Transaction_Date__c = system.now();
        acctEntry1.Finalized_Date__c = system.now();
        //acctEntry1.GL_Date__c = system.today();
        //acctEntry1.GL_Date__c = nextPeriodGLDate;
        acctEntry1.Currency__c = TestFuel.currencyUSD.id;
        acctEntry1.Transaction_Type__c = 'Manual';
        acctEntry1.Source_Document_Object_Name__c = 'Manual';
        
        insert acctEntry1;
        
        acctEntry1 = [Select id, Name, GL_Date_Time__c, Period__c from Accounting_Entry__c where id = :acctEntry1.id limit 1]; 
        system.assertNotEquals(null ,acctEntry1.GL_Date_Time__c );
        system.assertNotEquals(null ,acctEntry1.Period__c );
        system.assertEquals(Pdata.period1.id ,acctEntry1.Period__c );
        PeriodService ps=new PeriodService();
        
        List<Period__c> lstPeriods =new List<Period__c>();
        if(ps.openPeriods!=null)
            lstPeriods = ps.openPeriods;
        List<Accounting_Entry__c> lstAE = new List<Accounting_Entry__c>();
        lstAE.add(acctEntry1);
        
        ps.setPeriodOnAccountingEntries(lstAE);
        
        */
        /* SK - with new design to populate the GL Date Time and Period the below test doesn't make sense ( KNDY - 3368 )
        acctEntry1.Transaction_Date__c = null;
        acctEntry1.Finalized_Date__c = null;
        acctEntry1.GL_Date_Time__c = null;
        update acctEntry1;
        acctEntry1 = [Select id, Name, GL_Date_Time__c, Period__c from Accounting_Entry__c where id = :acctEntry1.id limit 1];
        system.assertEquals(null ,acctEntry1.GL_Date_Time__c );
        system.assertEquals(null ,acctEntry1.Period__c );
        */
   
        
    }

     // Test the validation rules on the Period Object
    public static testMethod void myUnitTest2() {
        Period__c period1 = [Select Id,Period_Start__c,Period_End__c,Year_Start_Date__c,Year_End_Date__c,Period_Number__c, Quarter_Number__c from period__c limit 1];
        Currency__c USDcurr = [Select Id from Currency__c where ISO_Code__c = 'USD' limit 1];
        // Create Accounting Entry with GL Date populated and check if the period is defaulted.
        Accounting_Entry__c acctEntry1 = new Accounting_Entry__c();
        acctEntry1.Company__c = [select id from company__c where name = '100' limit 1].Id;
        acctEntry1.Transaction_Date__c = system.now();
        acctEntry1.Finalized_Date__c = system.now();
        acctEntry1.Currency__c = USDcurr.id;
        acctEntry1.Transaction_Type__c = 'Manual';
        acctEntry1.Source_Document_Object_Name__c = 'Manual';
        
        insert acctEntry1;
        
        acctEntry1 = [Select id, Name, GL_Date_Time__c, Period__c from Accounting_Entry__c where id = :acctEntry1.id limit 1]; 
        system.assertNotEquals(null ,acctEntry1.GL_Date_Time__c );
        system.assertNotEquals(null ,acctEntry1.Period__c );
        system.assertEquals(period1.id ,acctEntry1.Period__c );
        
        period1.Period_Start__c = System.now() - 2;
        Boolean Excp = false;
        
        try{
            update period1;
        }catch(Exception e){
            Excp = true;
        }
        
        period1.Period_End__c = System.now() - 1;
        Excp = false;
        
        try{
            update period1;
        }catch(Exception e){
            Excp = true;
        }
        
        period1.Year_Start_Date__c = System.today() - 5;
        Excp = false;
        
        try{
            update period1;
        }catch(Exception e){
            Excp = true;
        }
        
        period1.Year_End_Date__c = System.today() +5;
        Excp = false;
        
        try{
            update period1;
        }catch(Exception e){
            Excp = true;
        }
        
        period1.Period_Number__c = 1;
        Excp = false;
        
        try{
            update period1;
        }catch(Exception e){
            Excp = true;
        }
        
        period1.Quarter_Number__c = 1;
        Excp = false;
        
        try{
            update period1;
        }catch(Exception e){
            Excp = true;
        }
        
        system.assertEquals(true, Excp);
        
    }
     
    public static testMethod void testPeriodDateValidationMultiCompany(){
        Period__c period1 = [select id,Fiscalyear__c,JE_Cutoff__c,Inventory_Subledger_Cutoff__c,FA_Subledger_Cutoff__c,Receiving_Subledger_Cutoff__c,Shipment_Subledger_Cutoff__c,AR_Subledger_Cutoff__c,
                                AP_Subledger_Cutoff__c,Fiscal_Year__c,Year_Start_Date__c,Year_End_Date__c,Company__c,Permanently_Closed__c,Tax__c,Corporate__c,
                                Fiscal__c,Open__c,Closed__c,Adjustment_Period__c,Name,Quarter_Number__c,Period_Number__c, Period_Start__c, Period_End__c 
                            from Period__c 
                            where Period_Number__c = 12 and Quarter_Number__c = 4 and Adjustment_Period__c = false and Closed__c = false and Open__c = true limit 1];
        Company__c comp200 = [select Id from Company__c where Name = '200'];
        Period__c newPeriod = period1.clone(false, true, false, false);
        newPeriod.company__c = comp200.Id;
            Fiscal_Year__c fy = new Fiscal_Year__c();
            fy.company__c = comp200.Id;
            fy.fiscal_year_start_date__c = period1.period_start__c;
            fy.fiscal_year_end_date__c = period1.period_end__c.addMonths(3);
            insert fy;
        newPeriod.fiscalyear__c = fy.Id;
        insert newPeriod;
        system.assert(newPeriod.Id != null);
    }

    public static testMethod void testOpenPeriodValidation(){ // check for the source doc jes
        string glTypeBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLType' LIMIT 1].body.toString();
        List<GL_Type__c> GLTypeTestData = (List<GL_Type__c>)CSVParser.parseRecords(GL_Type__c.sObjectType, glTypeBody);
        system.debug('GLTypeTestData:'+GLTypeTestData);
        insert GLTypeTestData;
        
        string glAccountBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLAccount' LIMIT 1].body.toString();
        List<GL_Account__c> GLAccountTestData = (List<GL_Account__c>)CSVParser.parseRecords(GL_Account__c.sObjectType, glAccountBody);
        system.debug(logginglevel.info,'GLAccountTestData:'+GLAccountTestData);
        insert GLAccountTestData;
        Journal_Entry__c je1 = new Journal_Entry__c();
        je1.name = 'JE001';
        je1.Company__c = [Select Id from Company__c limit 1].id;   
        je1.type__c = 'Manual';   
        je1.Transaction_Type__c = 'Manual';
        je1.Transaction_Date__c = System.now();  
        je1.Currency__c = [Select Id from Currency__c limit 1].id;   
        insert je1;
        
        List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
            
        Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
        jeLine1.Journal_Entry__c = je1.id;
        jeLine1.Amount_CR__c = 5;
        jeLine1.Amount_DR__c = 0;
        jeLine1.GL_Account__c = [Select Id from GL_Account__c where GL_Account_Number__c = '12000'].id;
        jeLine1.Subtransaction_Type__c = 'Write Off';
        jeLineList.add(jeLine1); 
        
        Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
        jeLine2.Journal_Entry__c = je1.id;
        jeLine2.Amount_CR__c = 0;
        jeLine2.Amount_DR__c = 5;
        jeLine2.GL_Account__c = [Select Id from GL_Account__c where GL_Account_Number__c = '11000'].id;
        jeLine2.Subtransaction_Type__c = 'Write Off';
        jeLineList.add(jeLine2); 
            
        insert jeLineList;
         
        je1.finalized__c = true;
        update je1;
         
        je1 = [Select id, Name, Period__c, Period__r.Open__c, Period__r.Closed__c, Period__r.permanently_closed__c
                from Journal_Entry__c 
                where id = :je1.id];
         
        system.assertEquals(true, je1.period__r.Open__c);
        system.assertEquals(false, je1.period__r.Closed__c);
        system.assertEquals(false, je1.period__r.permanently_closed__c);
         
        Period__c p = new Period__c(id = je1.period__c);
        Boolean sawException = false;
        String exMsg;
        try{
            p.put('Open__c', false);
            update p;
        }catch (Exception ex){
            sawException = true;
            exMsg = ex.getMessage();
        }
        system.assert(sawException == true,'Expected to see an exception while updating a period open when a JE exists');
    }


    public static testMethod void testPeriodDateValidationBulk(){
        List<Period__c> periodList = periodListForCompany([Select Id from Company__c where Name = '300'].Id);
        for(Period__c p : periodList){
            //Assert all of the records were created
            system.assert(p.Id != null);
        }
    }

    public static testMethod void testPriorPeriodValidation(){ 
        Test.startTest();
        List<Period__c> periodList = periodListForCompany([Select Id from Company__c where Name = '300'].Id);
        Period__c lastPeriod = periodList[periodList.size()-1];
        lastPeriod = [Select id, Name, Company__c, fiscal__c, fiscal_year__c, period_start__c, period_end__c, prior_period__c, prior_period__r.period_end__c, year_start_date__c, year_end_date__c
                        from Period__c
                        where id = :lastPeriod.id];
        system.assert(lastPeriod.prior_period__c != null,'Expected to see the prior period'+lastPeriod);
        system.assert(lastPeriod.prior_period__r.period_end__c == lastPeriod.period_start__c,'prior period end date should be equal to current period period start.'+lastPeriod);
        Period__c newPeriod = lastPeriod.clone(false,true);
        
        boolean sawException = false;
        String exMsg;
        try{
            newPeriod.Period_Start__c = lastPeriod.Period_End__c.addDays(1); // break the periods by introducing a gap
            newPeriod.Period_End__c = lastPeriod.Period_End__c.addDays(31);
            newPeriod.Name = 'XYZ';
            insert newPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.assert(sawException == true, 'Expected to see the exception while inserting a new cloned period with prior period from lastPeriod:'+exMsg);
        system.assert(exMsg.contains('Each period must end at the next period start'),' saw message:'+exMsg);
        Test.stopTest();
    }
      
    public static testMethod void testPriorPeriodNextPeriodAssignment(){ // check for the source doc jes
        List<Period__c> periodList = periodListForCompany([Select Id from Company__c where Name = '300'].Id);
        
        Period__c lastPeriod = periodList[periodList.size()-1];
        Period__c newPeriod = lastPeriod.clone(false,true);
        boolean sawException = false;
        String exMsg;
        
        try{
            newPeriod.Period_Start__c = lastPeriod.Period_End__c;
            newPeriod.Period_End__c = lastPeriod.Period_End__c.addDays(31);
            newPeriod.prior_period__c = lastPeriod.id;
            newPeriod.Name = 'NewPeriod';
            insert newPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false, 'Expected to insert a new period'+exMsg);
        
        newPeriod = [Select id, Name, Company__c, prior_period__c, prior_period__r.period_end__c, period_start__c from Period__c where id = :newPeriod.id];
        system.assert(newPeriod.prior_period__c != null, 'Expected to see the prior period populated');
        system.assertEquals(newPeriod.prior_period__r.period_end__c,newPeriod.period_start__c);
        
        update lastPeriod;
        lastPeriod = [Select id, Name, Company__c, prior_period__c, next_period__c, next_period__r.period_start__c, period_end__c from period__c where id = :lastPeriod.id];
        system.assert(lastPeriod.next_Period__c != null,'Expected to see the next period populated');
        system.assertEquals(lastPeriod.next_period__r.period_start__c,lastPeriod.period_end__c);
    }
    
    public static testMethod void testSLCDatesMovementBackinTime(){ 
        Test.startTest();
        //Enabling cutoffs so that values can be backdated and asserted.
        Configuration__c config = new Configuration__c();
        config.name = 'EnableCutoffs';
        config.Value__c = 'Yes';
        insert config; 
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1]; 
        List<Period__c> periodList = new List<Period__c>(); 
        Integer year = system.now().year();
        Datetime ps = system.now().addDays(-2);
        Datetime pe = system.now().addDays(-1);
        Datetime currentDatetime = system.now();
        system.debug(logginglevel.info, 'ps:'+ps+'----pe:'+pe+'----currentDatetime:'+currentDatetime);
        Period__c testPeriod = new Period__c();
        testPeriod.Name = 'P1';
        testPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
        testPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
        testPeriod.Period_Start__c = ps;
        testPeriod.Period_End__c = pe;
        testPeriod.Period_Number__c = 1;
        testPeriod.Quarter_Number__c = 1;
        
        testPeriod.Fiscal_Year__c = String.valueOf(year);
        testPeriod.Company__c = comp.Id;
        testPeriod.Adjustment_Period__c = false;
        testPeriod.Closed__c = false;
        testPeriod.Open__c = true;
        testPeriod.Fiscal__c = true;
        testPeriod.Corporate__c = false;
        testPeriod.Tax__c = false;
        testPeriod.Permanently_Closed__c = false;
        testPeriod.Adjustment_Period__c = false;
        
        testPeriod.AP_Subledger_Cutoff__c = pe;
        testPeriod.AR_Subledger_Cutoff__c = pe;
        testPeriod.Shipment_Subledger_Cutoff__c = pe;
        testPeriod.Receiving_Subledger_Cutoff__c = pe;
        testPeriod.FA_Subledger_Cutoff__c = pe;
        testPeriod.Inventory_Subledger_Cutoff__c = pe;
        testPeriod.JE_Cutoff__c = currentDatetime;
        
        periodList.add(testPeriod);
        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.company__c = comp.Id;
        fy.fiscal_year_start_date__c = periodList[0].period_start__c;
        fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
        
        insert fy;

        for(Period__c p : periodList){
            p.fiscalyear__c = fy.Id;
        }
        insert periodList;
        
        system.assert(testPeriod != null,'last period is not expected to be null'+testPeriod);
        testPeriod = [Select id, Name, Company__c, fiscal__c, fiscal_year__c, period_start__c, period_end__c, prior_period__c, 
                        prior_period__r.period_end__c, year_start_date__c, year_end_date__c, ar_subledger_cutoff__c, ap_subledger_cutoff__c, fa_subledger_cutoff__c, inventory_subledger_cutoff__c,
                        shipment_subledger_cutoff__c, receiving_subledger_cutoff__c, JE_Cutoff__c
                        from Period__c
                        where id = :testPeriod.id];
        system.debug(logginglevel.info,'testPeriod:'+testPeriod);                       
        
        boolean sawException = false;
        String exMsg;
        
        try{
            testPeriod.JE_Cutoff__c = currentDatetime.addSeconds(-1);
            update testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.debug(logginglevel.info,'testPeriod first:'+testPeriod);
        system.assert(sawException == true, 'Expected to see the exception while updating the period cut off back in time:'+exMsg+'---testPeriod:'+testPeriod);
        
        testPeriod = [Select id, Name, Company__c, fiscal__c, fiscal_year__c, period_start__c, period_end__c, prior_period__c, 
                        prior_period__r.period_end__c, year_start_date__c, year_end_date__c, ar_subledger_cutoff__c, ap_subledger_cutoff__c, fa_subledger_cutoff__c, inventory_subledger_cutoff__c,
                        shipment_subledger_cutoff__c, receiving_subledger_cutoff__c, JE_Cutoff__c
                        from Period__c
                        where id = :testPeriod.id];
        system.assertEquals(currentDatetime,testPeriod.JE_Cutoff__c,'testPeriod.JE_Cutoff__c:'+testPeriod.JE_Cutoff__c
                                +'      ----    currentDatetime:'+currentDatetime); 
        system.assert(exMsg.contains('cannot be moved back in time'),' saw message:'+exMsg);
        
        system.debug(logginglevel.info,'testPeriod second:'+testPeriod);    
        KSE.dateTimeCloseResult result = KSE.areDateTimesClose(testPeriod.JE_Cutoff__c,currentDatetime);    
        system.debug(logginglevel.info,'result:'+result);
        
        sawException = false;
        exMsg = '';
        try{
            testPeriod.AR_Subledger_cutoff__c = currentDatetime.addSeconds(1);
            update testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.assert(sawException == true, 'Expected to see the exception while updating the subledger cut off after the je cutoff:'+exMsg+'---testPeriod:'+testPeriod);
        system.assert(exMsg.containsignorecase('cannot be after JE CutOff'),' saw message:'+exMsg);
        Test.stopTest();
    }
   
    public static testMethod void testPeriodStartAndPeriodEnd(){ 
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1]; 
        List<Period__c> periodList = new List<Period__c>(); 
        Integer year = system.now().year();
        Datetime currentDatetime = system.now();
        Datetime ps = currentDatetime;
        Datetime pe = ps.addDays(1);
        
        system.debug(logginglevel.info, 'ps:'+ps+'----pe:'+pe+'----currentDatetime:'+currentDatetime);
        Period__c testPeriod = new Period__c();
        testPeriod.Name = 'P1';
        testPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
        testPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
        testPeriod.Type__c = 'Fiscal';
        testPeriod.Period_Number__c = 1;
        testPeriod.Quarter_Number__c = 1;
        testPeriod.Fiscal_Year__c = String.valueOf(year);
        testPeriod.Company__c = comp.Id;
        
        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.company__c = comp.Id;
        fy.fiscal_year_start_date__c = date.newInstance(year, 1, 1);
        fy.fiscal_year_end_date__c = date.newInstance(year + 1, 1, 1);
        
        insert fy;

        testPeriod.fiscalyear__c = fy.Id;
        periodList.add(testPeriod);
        boolean sawException = false;
        String exMsg;
        try{
            insert periodList;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.assert(sawException == true,'Expected to see exception while inserting a fiscal period with no period start and period end '+exMsg);
        
        sawException = false;
        exMsg= null;
        
        try{
            testPeriod.Type__c = 'Period 13';
            insert periodList;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.assert(sawException == false,'Not expected to see exception while inserting a Period 13 period with no period start and period end '+exMsg);
        
        
        testPeriod.Type__c = 'Fiscal';
        testPeriod.fiscalyear__c = fy.id;
        testPeriod.Period_Start__c = ps;
        testPeriod.Period_End__c = pe;
        
        update testPeriod;
        
        sawException = false;
        exMsg= null;
        //below is to test validation rule to include the period within the fiscal year 
        try{
            testPeriod.Period_Start__c = currentDatetime.addyears(-1);
            update testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.assert(sawException == true,'Expected to see exception while updating a fiscal period with period start prior to the associated fiscal year '+exMsg);
    }

    public static testMethod void testPeriodDeleteAndChangeFiscalYear(){ 
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1]; 
        Accounting_Standard__c accountingStandard = new Accounting_Standard__c();
                accountingStandard.name = 'US GAAP';
                insert accountingStandard;
                DateTime effStartDate = datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);
        string glTypeBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLType' LIMIT 1].body.toString();
        List<GL_Type__c> GLTypeTestData = (List<GL_Type__c>)CSVParser.parseRecords(GL_Type__c.sObjectType, glTypeBody);
        system.debug('GLTypeTestData:'+GLTypeTestData);
        insert GLTypeTestData;
        
        string glAccountBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLAccount' LIMIT 1].body.toString();
        List<GL_Account__c> GLAccountTestData = (List<GL_Account__c>)CSVParser.parseRecords(GL_Account__c.sObjectType, glAccountBody);
        system.debug(logginglevel.info,'GLAccountTestData:'+GLAccountTestData);
        insert GLAccountTestData;

        List<Period__c> periodList = new List<Period__c>(); 
        Integer year = system.now().year();
        Datetime currentDatetime = system.now();
        Datetime ps = currentDatetime;
        Datetime pe = ps.addDays(1);
        
        List<Fiscal_Year__c> fylist = new list<Fiscal_Year__c>();
        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.name = 'Year2015';
        fy.company__c = comp.id;
        fy.fiscal_year_start_date__c = currentDatetime.addDays(-10);
        fy.fiscal_year_end_date__c = currentDatetime.addDays(10);
        fylist.add(fy);
        
        Fiscal_Year__c fyNew = new Fiscal_Year__c();
        fyNew.name = 'Year2016';
        fyNew.company__c = comp.id;
        fyNew.fiscal_year_start_date__c = currentDatetime.addDays(11);
        fyNew.fiscal_year_end_date__c = currentDatetime.addDays(20);
        fylist.add(fyNew);
        
        insert fylist;
        
        system.debug(logginglevel.info, 'ps:'+ps+'----pe:'+pe+'----currentDatetime:'+currentDatetime);
        Period__c testPeriod = new Period__c();
        testPeriod.Name = 'P1';
        testPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
        testPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
        testPeriod.Type__c = 'Fiscal';
        testPeriod.Open__c = true;
        testPeriod.Period_Start__c = ps;
        testPeriod.Period_End__c = pe;
        testPeriod.Period_Number__c = 1;
        testPeriod.Quarter_Number__c = 1;
        testPeriod.Company__c = comp.Id;
        testPeriod.fiscalyear__c = fylist[0].id;
        periodList.add(testPeriod);
        
        insert periodList;
        
        Segment_Validation__c sv1 = new Segment_Validation__c();
        sv1.segment_1__c = '*';
        sv1.segment_2__c = '*';
        sv1.active__c = true;
        
        insert sv1;
        
        List<Accounting_Rule__c> JEAccountingRules = new List<Accounting_Rule__c> ();{
            Accounting_Rule__c jeRule1 = new Accounting_Rule__c();
            jeRule1.Object_Name__c = 'Journal_Entry__c';
            jeRule1.Accounting_Standard__c = accountingStandard.id;
            jeRule1.Transaction__c = 'Manual';
            jeRule1.SubTransaction_Type__c = 'Write Off';
            jeRule1.Line_Type__c = null;
            jeRule1.Rule_Type__c = 'CR';
            jeRule1.Default_GL_Account__c = false;
            jeRule1.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule1.GL_Account__c = null;
            jeRule1.Amount_Reference__c = null; 
            jeRule1.Company_Ledger__c = true;   
            jeRule1.Effective_Start_Date__c = effStartDate;                    
            jeRule1.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule1.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule1);
            
            Accounting_Rule__c jeRule2 = new Accounting_Rule__c();
            jeRule2.Object_Name__c = 'Journal_Entry__c';
            jeRule2.Accounting_Standard__c = accountingStandard.id;
            jeRule2.Transaction__c = 'Manual';
            jeRule2.SubTransaction_Type__c = 'Write Off';
            jeRule2.Line_Type__c = null;
            jeRule2.Rule_Type__c = 'DR';
            jeRule2.Default_GL_Account__c = false;
            jeRule2.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule2.GL_Account__c = null;
            jeRule2.Amount_Reference__c = null; 
            jeRule2.Company_Ledger__c = true;  
            jeRule2.Effective_Start_Date__c = effStartDate;                                            
            jeRule2.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule2.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule2);            
        
        
            insert JEAccountingRules;   
        }
        
        Journal_Entry__c je1 = new Journal_Entry__c();
        je1.name = 'JE001';
        je1.Company__c = comp.id;   
        je1.type__c = 'Manual';   
        je1.Transaction_Type__c = 'Manual';
        je1.Transaction_Date__c = System.now();  
        je1.Currency__c = [Select Id from Currency__c where ISO_Code__c = 'USD' limit 1].id;
        insert je1;
        
        List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
            
        Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
        jeLine1.Journal_Entry__c = je1.id;
        jeLine1.Amount_CR__c = 5;
        jeLine1.Amount_DR__c = 0;
        jeLine1.GL_Account__c = [Select Id from GL_Account__c where GL_Account_Number__c = '12000'].id;
        jeLine1.Subtransaction_Type__c = 'Write Off';
        jeLineList.add(jeLine1); 
        
        Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
        jeLine2.Journal_Entry__c = je1.id;
        jeLine2.Amount_CR__c = 0;
        jeLine2.Amount_DR__c = 5;
        jeLine2.GL_Account__c = [Select Id from GL_Account__c where GL_Account_Number__c = '11000'].id;
        jeLine2.Subtransaction_Type__c = 'Write Off';
        jeLineList.add(jeLine2); 
    
        insert jeLineList;
        
        je1.finalized__c = true;
        update je1;
        
        je1 = [Select id, Name, period__c, finalized__c from journal_entry__c where id = :je1.id];
        system.assert(je1.period__c == testPeriod.id,'JE period is not the same period as expected:' + je1);
        
        boolean sawException = false;
        String exMsg;
        try{
            testPeriod.fiscalyear__c = fy.id;
            update testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        
        system.assert(sawException == false,'Not expected to see exception while updating the fiscal year from null to some value'+exMsg);
        testPeriod = [Select id, Name, fiscalyear__c, (select id, Name from Journal_Entries__r) from Period__c where id = :testPeriod.id];
        system.assert(testPeriod.fiscalyear__c == fy.id,'Not the expected fiscal year');
        
        system.assert(testPeriod.Journal_Entries__r.size() > 0,'testPeriod is expected to have Journal Entry associated with it');
        
        sawException = false;
        exMsg = null;
        try{
            testPeriod.fiscalyear__c = fyNew.id;
            update testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == true,'Expected to see exception while updating the fiscal year from some value to other fiscal year when it has transactions associated'+exMsg);       
        testPeriod = [Select id, Name, fiscalyear__c, (select id, Name from Journal_Entries__r) from Period__c where id = :testPeriod.id];
        try{
            delete testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }        
        system.assert(sawException == true,'Expected to see exception while deleting a period while the transactions are recorded in the period'+exMsg);
    }

    public static testMethod void testZeroPeriodValidation(){ 
        Test.startTest();
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1]; 
        Accounting_Standard__c accountingStandard = new Accounting_Standard__c();
        accountingStandard.name = 'US GAAP';
        insert accountingStandard;
        DateTime effStartDate = datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);
         string glTypeBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLType' LIMIT 1].body.toString();
        List<GL_Type__c> GLTypeTestData = (List<GL_Type__c>)CSVParser.parseRecords(GL_Type__c.sObjectType, glTypeBody);
        system.debug('GLTypeTestData:'+GLTypeTestData);
        insert GLTypeTestData;
        
        string glAccountBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLAccount' LIMIT 1].body.toString();
        List<GL_Account__c> GLAccountTestData = (List<GL_Account__c>)CSVParser.parseRecords(GL_Account__c.sObjectType, glAccountBody);
        system.debug(logginglevel.info,'GLAccountTestData:'+GLAccountTestData);
        insert GLAccountTestData;

        Period__c period1 = [select id,Fiscalyear__c,JE_Cutoff__c,Inventory_Subledger_Cutoff__c,FA_Subledger_Cutoff__c,Receiving_Subledger_Cutoff__c,Shipment_Subledger_Cutoff__c,AR_Subledger_Cutoff__c,
                                AP_Subledger_Cutoff__c,Fiscal_Year__c,Year_Start_Date__c,Year_End_Date__c,Company__c,Permanently_Closed__c,Tax__c,Corporate__c,
                                Fiscal__c,Open__c,Closed__c,Adjustment_Period__c,Name,Quarter_Number__c,Period_Number__c, Period_Start__c, Period_End__c 
                            from Period__c 
                            where Period_Number__c = 12 and Quarter_Number__c = 4 and Adjustment_Period__c = false and Closed__c = false and Open__c = true limit 1];


        List<Period__c> periodList = new List<Period__c>(); 
        Integer year = system.now().year();
        Datetime currentDatetime = system.now();
        Datetime ps = currentDatetime;
        Datetime pe = ps.addDays(1);

        Datetime begOfYearDatetime = DateTime.newInstance(system.now().year(), 1, 1);
        Datetime endOfYearDatetime = DateTime.newInstance(system.now().year(), 12, 31, 23, 59, 00);     

        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.Name = 'My Year';
        fy.company__c = comp.Id;
        fy.fiscal_year_start_date__c = begOfYearDatetime;
        fy.fiscal_year_end_date__c = endOfYearDatetime;
        
        insert fy;
        
        system.debug(logginglevel.info, 'ps:'+ps+'----pe:'+pe+'----currentDatetime:'+currentDatetime);
        Period__c testPeriod = period1;
        testPeriod.Company__c = comp.Id;
        Period__c zeroPeriod = new Period__c();
        zeroPeriod.Name = 'P1';
        zeroPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
        zeroPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
        zeroPeriod.Type__c = 'Period 13';
        zeroPeriod.Period_Number__c = 2;
        zeroPeriod.Quarter_Number__c = 1;
        zeroPeriod.Company__c = comp.Id;
        zeroPeriod.fiscalYear__c = fy.Id;

        Boolean sawException = false;
        String exMsg = '';
        try{ 
            insert zeroPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false,'The zero period must be inserted succesfully true : '+exMsg+zeroPeriod);
        system.assert(testPeriod!=null,'The test period should not be null : '+testPeriod);

        testPeriod.Type__c = 'Fiscal';
        system.assert(fy.id != null,'fy shpuld not be null '+fy);
        testPeriod.fiscalyear__c = fy.id;
        sawException = false;
        try{ 
            update testPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false,'update test period: '+exMsg+testPeriod);
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
        journalEntry.name = 'JE001';
        journalEntry.Company__c = comp.Id;   
        journalEntry.type__c = 'Manual';   
        journalEntry.Transaction_Type__c = 'Manual';
        journalEntry.Transaction_Date__c = system.now();  
        journalEntry.Currency__c = [Select Id from Currency__c where ISO_Code__c = 'USD' limit 1].id;
        insert journalEntry;
        
        List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
            
        Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
        jeLine1.Journal_Entry__c = journalEntry.id;
        jeLine1.Amount_CR__c = 5;
        jeLine1.Amount_DR__c = 0;
        jeLine1.GL_Account__c = [Select Id from GL_Account__c where GL_Account_Number__c = '12000'].id;
        jeLine1.Subtransaction_Type__c = 'Write Off';
        jeLineList.add(jeLine1); 
        
        Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
        jeLine2.Journal_Entry__c = journalEntry.id;
        jeLine2.Amount_CR__c = 0;
        jeLine2.Amount_DR__c = 5;
        jeLine2.GL_Account__c = [Select Id from GL_Account__c where GL_Account_Number__c = '11000'].id;
        jeLine2.Subtransaction_Type__c = 'Write Off';
        jeLineList.add(jeLine2); 
        
        insert  jeLineList;
        
        try{
            journalEntry.finalized__c = true;
            update journalEntry;
        }catch(Exception ex){
            Period__c p = [Select Id, open__c,Period_Start__c,Period_End__c,JE_Cutoff__c From Period__c Where Id=:testPeriod.Id];
            Journal_Entry__c j = [Select Id, Transaction_Date__c, Posting_Date__c, Finalized_Date__c, Period__c From Journal_Entry__c Where Id=:journalEntry.Id ];
            system.assert(false, 'JE Date: '+ j.Transaction_Date__c  + '\tPostingDate: '+ j.Posting_Date__c + '\tFinalized Date: ' + j.Finalized_Date__c + '\tAssigned Period: ' + j.Period__c + '\tPeriod Id: ' + p.Id + 
                                '\tPS: ' + p.Period_Start__c + '\tPE: ' + p.Period_End__c + '\tIs open: ' + p.Open__c + '\tJE Cut off: ' + p.JE_Cutoff__c +
                                '\tCurrent DT: ' + currentDatetime + '\terr: ' + ex.getMessage());
        }
    
        
        journalEntry = [Select id, Name, Period__r.Name, Period__c,Period__r.Open__c from Journal_Entry__c where id = :journalEntry.id];
        system.assert(journalEntry.Period__c != null);
        
        Period__c testPeriod01 = new Period__c(id = journalEntry.Period__c);

        testPeriod01.AR_Subledger_Closed__c =  System.now().addseconds(1);
        testPeriod01.AP_Subledger_Closed__c = System.now().addseconds(1);
        testPeriod01.FA_Subledger_Closed__c = System.now().addseconds(1);
        testPeriod01.Inventory_Subledger_Closed__c = System.now().addseconds(1);
        testPeriod01.Receiving_Subledger_Closed__c = System.now().addseconds(1);
        testPeriod01.Shipment_Subledger_Closed__c = System.now().addseconds(1);
        testPeriod01.GL_Close__c = system.now().addseconds(2);
        testPeriod01.Open__c = false;
        testPeriod01.Closed__c = true;
        
        PeriodService.systemEditable.add(testPeriod01.Id);
        
        sawException = false;
        try{ 
            update testPeriod01;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false,'Test period should be updated to closed'+exMsg+testPeriod01);

        zeroPeriod.Open__c = false;
        zeroPeriod.Closed__c = true;
        try{ 
            update zeroPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false,'Zero period should be updated to closed '+exMsg+zeroPeriod);

        sawException = false;
        try{ 
            delete zeroPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == true,'Period 13 period should not be deleted if it is closed'+exMsg+zeroPeriod);

        sawException = false;
        try{ 
            testPeriod01.Open__c = true;
            testPeriod01.Closed__c = false;
            update testPeriod01;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == true,'Test period should not be updated to open'+exMsg+testPeriod01);

        zeroPeriod.Open__c = true;
        zeroPeriod.Closed__c = false;

        sawException = false;
        try{ 
            update zeroPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false,'zeroPeriod period should be updated to open'+exMsg+zeroPeriod);

        sawException = false;
        try{ 
            testPeriod01.Open__c = true;
            testPeriod01.Closed__c = false;
            update testPeriod01;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == false,'Test period should be updated to open'+exMsg+testPeriod01);

        zeroPeriod.Open__c = false;
        zeroPeriod.Closed__c = true;

        sawException = false;
        try{ 
            update zeroPeriod;
        }catch(Exception e){
            sawException = true;
            exMsg = e.getMessage();
        }
        system.assert(sawException == true,'zeroPeriod period should not be updated to closed'+exMsg+zeroPeriod);
        test.stopTest();
    }

    //FIN-610 Cannot have more than one historical or adjustment periods for the company.
    public static  testmethod void testPeriodTypeValidation()
    {
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1]; 
        list<period__c> testHistPeriods = new list<period__c>();
        Boolean sawInsertException = false;
        Boolean sawUpdateException = false;
        Integer failureCount =0;
        
        DateTime startDate = DateTime.newInstance(2015, 06, 11, 00, 00, 00);    
        DateTime EndDate =startDate.addhours(24);   
        Period__c per1 = new period__c();
        Period__c per2 = new period__c();
        Period__c per3 = new period__c();
        Period__c per4 = new period__c();
            
        per1.name='Test1';
        per1.company__c=comp.id;
        per1.open__c=true;
        per1.type__c='Historical';
        per1.Period_Start__c=startDate;
        per1.period_end__c=EndDate;
        testHistPeriods.add(per1);

        per2.name='Test2';
        per2.company__c=comp.id;
        per2.open__c=true;
        per2.type__c='Historical';
        per2.Period_Start__c=EndDate;
        per2.period_end__c=EndDate.addhours(24);
        testHistPeriods.add(per2);
        
        per3.name='Test3';
        per3.company__c=comp.id;
        per3.open__c=true;
        per3.type__c='Historical';
        per3.Period_Start__c=per2.Period_Start__c;
        per3.period_end__c=per3.Period_Start__c.addhours(24);
        testHistPeriods.add(per3);      
        
        per4.name='Test4';
        per4.company__c=comp.id;
        per4.open__c=true;
        per4.type__c='Fiscal';
        per4.Period_Start__c=per3.Period_Start__c;
        per4.period_end__c=per4.Period_Start__c.addhours(24);
        testHistPeriods.add(per4);      
                  
          //Check if insert event fires the validation.
        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.company__c = comp.Id;
        fy.fiscal_year_start_date__c = testHistPeriods[0].period_start__c;
        fy.fiscal_year_end_date__c = testHistPeriods[testHistPeriods.size()-1].period_end__c.addMonths(3);
        
        insert fy;

        for(Period__c p : testHistPeriods){
            p.fiscalyear__c = fy.Id;
        }
          Database.SaveResult[] srList = Database.insert(testHistPeriods, false);
          system.assertEquals(srList.size(),4,'Expecting 4 save results');  
          
          for(Database.SaveResult sr : srList)
          {
              if(!sr.issuccess())
              {
                  failureCount=failureCount+1;
                  system.assertEquals(sr.getErrors().size(),1,'Expecting only one error due to multiple historical periods');                 
                  system.assert(sr.getErrors().get(0).getmessage().contains('more than one Historical Period'),'Expecting multiple historical validation error');   
                
              }
          }
        system.assertEquals(failureCount,3,'Expecting Three Historical periods insert failures.');
        per1.fiscalyear__c = fy.Id;
        insert per1;//Should insert successfully as above would have caused rollback on all three records.
         
        //Check if update event fires the validation.       
        try
        {
            per4.type__c='Historical';
            update per4;
        }
        catch(Exception e)
        {
            sawUpdateException= true;
            system.assertEquals(e.getNumDML(),1,'Expecting 1 failed records. ');
            for(integer i=0;i<e.getNumDml();i++)
            {
              system.assert(e.getDMLMessage(i).contains('more than one Historical Period'),'Expecting error message to be associated to ALL the records.'); 
              //system.assertEquals(e.getDMLMessage(i),null,'debugging error message  associated to  the records.');            
                    
            }
        }   
        system.assertEquals(sawUpdateException,true,'Expecting error - You cannot have more than one Historical periods for the same company.');        
    }

    public static testMethod void testValidAfterDefaults(){ 
        //Enabling cutoffs so that values can be backdated and asserted.
        Configuration__c config = new Configuration__c();
        config.name = 'EnableCutoffs';
        config.Value__c = 'Yes';
        insert config;
        
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1];  
        Integer year = system.now().year();
        Datetime currentDatetime = system.now();
        Datetime ps = currentDatetime;
        Datetime pe = ps.addDays(1);
        
        List<Fiscal_Year__c> fylist = new list<Fiscal_Year__c>();
        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.name = 'Year'+year;
        fy.company__c = comp.id;
        fy.fiscal_year_start_date__c = currentDatetime.addDays(-10);
        fy.fiscal_year_end_date__c = currentDatetime.addDays(10);
        fylist.add(fy);
        
        insert fylist;
        
        system.debug(logginglevel.info, 'ps:'+ps+'----pe:'+pe+'----currentDatetime:'+currentDatetime);
        
        Period__c testPeriod = new Period__c();
        testPeriod.Name = 'P1';
        testPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
        testPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
        testPeriod.Type__c = 'Fiscal';
        testPeriod.Open__c = true;
        testPeriod.Period_Start__c = ps;
        testPeriod.Period_End__c = pe;
        testPeriod.Period_Number__c = 1;
        testPeriod.Quarter_Number__c = 1;
        testPeriod.Company__c = comp.Id;
        testPeriod.ap_subledger_cutoff__c = pe.addSeconds(-5);
        testPeriod.fa_valid_after__c = pe.addSeconds(-10);
        testPeriod.receiving_valid_after__c = pe.addSeconds(20);
        testPeriod.inventory_subledger_cutoff__c = pe.addSeconds(-10);
        
        testPeriod.fiscalyear__c = fylist[0].id;
        insert testPeriod;
        
        testPeriod = [Select id, Name, period_start__c, period_end__c, ap_valid_after__c, ar_valid_after__c, fa_valid_after__c, inventory_valid_after__c, 
                        receiving_valid_after__c, shipment_valid_after__c, je_valid_after__c, ar_subledger_cutoff__c, ap_subledger_cutoff__c, fa_subledger_cutoff__c,
                        inventory_subledger_cutoff__c, shipment_subledger_cutoff__c, Receiving_Subledger_Cutoff__c, JE_Cutoff__c
                        from Period__c where id = :testPeriod.id];
                        
        system.assert(testPeriod.ar_subledger_cutoff__c == testPeriod.Period_End__c);
        system.assert(testPeriod.ap_subledger_cutoff__c == testPeriod.Period_End__c.addSeconds(-5));
        system.assert(testPeriod.fa_subledger_cutoff__c == testPeriod.Period_End__c);
        system.assert(testPeriod.inventory_subledger_cutoff__c == testPeriod.Period_End__c.addSeconds(-10));
        system.assert(testPeriod.shipment_subledger_cutoff__c == testPeriod.Period_End__c);
        system.assert(testPeriod.receiving_subledger_cutoff__c == testPeriod.Period_End__c);
        system.assert(testPeriod.JE_Cutoff__c == testPeriod.Period_End__c);
        
        system.assert(testPeriod.ar_valid_after__c == testPeriod.Period_End__c,'Expected to see the AR Valid after set to Period end as default value '+testPeriod.ar_valid_after__c+ '---pe--'+testPeriod.Period_End__c);
        system.assert(testPeriod.ap_valid_after__c == testPeriod.Period_End__c,'Expected to see the AP Valid after set to Period end as default value');
        system.assert(testPeriod.fa_valid_after__c != testPeriod.Period_End__c.addSeconds(-10),'Expected to see the FA Valid after set to Period end plus 1 day as provided and should be overriden to pe or subledger cutoff which ever is greater');
        system.assert(testPeriod.fa_valid_after__c == (testPeriod.fa_subledger_cutoff__c > testPeriod.Period_End__c ? testPeriod.fa_subledger_cutoff__c : testPeriod.Period_End__c) ,'Expected to see the FA Valid after set to Period end plus 1 day as provided and should be overriden to pe or subledger cutoff which ever is greater');
        system.assert(testPeriod.inventory_valid_after__c == testPeriod.Period_End__c,'Expected to see the Inventory Valid after set to Period end as default value');
        system.assert(testPeriod.receiving_valid_after__c != testPeriod.Period_End__c.addSeconds(20),'Expected to see the Receiving Valid after set to Period end plus 20 seconds as provided and should be overriden to pe or subledger cutoff which ever is greater');
        system.assert(testPeriod.receiving_valid_after__c == (testPeriod.receiving_subledger_cutoff__c > testPeriod.Period_End__c ? testPeriod.receiving_subledger_cutoff__c : testPeriod.Period_End__c) ,'Expected to see the Receiving Valid after set to Period end plus 20 seconds as provided and should be overriden to pe or subledger cutoff which ever is greater');
        system.assert(testPeriod.shipment_valid_after__c == testPeriod.Period_End__c,'Expected to see the Shipment Valid after set to Period end as default value');
        system.assert(testPeriod.je_valid_after__c == testPeriod.Period_End__c,'Expected to see the JE Valid after set to Period end as default value');
        
        
        Datetime newValidAfter = testPeriod.ar_valid_after__c.addDays(-1);
        testPeriod.ar_valid_after__c = newValidAfter;
        update testPeriod;
        
        testPeriod = [Select id, Name, period_start__c, period_end__c, ap_valid_after__c, ar_valid_after__c, fa_valid_after__c, inventory_valid_after__c, 
                        receiving_valid_after__c, shipment_valid_after__c, je_valid_after__c, ar_subledger_cutoff__c, ap_subledger_cutoff__c, fa_subledger_cutoff__c,
                        inventory_subledger_cutoff__c, shipment_subledger_cutoff__c, Receiving_Subledger_Cutoff__c, JE_Cutoff__c
                        from Period__c where id = :testPeriod.id];
        
        System.assert(testPeriod.AR_Valid_After__c == newValidAfter);
    }

    
    
     //---------------KNDY-10520------------------
     // Change the period with  Accounting Entries in Draft or Obsolete status-- Should not throw Exceptions
    public static testMethod void testEnablePeriodEditWithInvalidAEs(){ 
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1];
        Currency__c usdCurr = [Select Id from Currency__c where ISO_Code__c = 'USD'];
        AEReadyData aer = new AEReadyData();
        Supplier_Invoice__c  suppInv           = new Supplier_Invoice__c();
        Supplier_Invoice_Line__c suppInvLine   = new Supplier_Invoice_Line__c(); 
        
        //Create Supplier Invoice  
        suppInv.Company__c                  = comp.id;
        suppInv.Invoice_Type__c             = 'Invoice';
        suppInv.Date_Invoiced__c            =  System.now();
        suppInv.Currency__c                 = [Select Id from Currency__c where ISO_Code__c = 'USD' limit 1].id;
        suppInv.Transaction_Date__c         = system.now();
        suppInv.Supplier__c                 = [Select Id from Supplier__c where Name = 'Test Remit To Supplier' limit 1].id;
        suppInv.Amount_Due__c               = [Select Id,Purchase_Order_Value__c from Purchase_Order__c where Memo__c = 'PurchaseOrder1' limit 1].Purchase_Order_Value__c;
        suppInv.Invoice_Amount__c           = 60;
        suppInv.historical__c = false;
        suppInv.Supplier_Invoice__c             = String.valueOfGmt(system.today());
        List<Purchase_Order_Line__c> poLineList = [Select id, Name , Currency__c 
                                                   from Purchase_Order_Line__c 
                                                   where  item__r.Name = 'HP Printer'
                                                   limit 2]; 
       
        
        insert suppInv; 
        suppInvLine                                 = new Supplier_Invoice_Line__c(); 
        suppInvLine.Supplier_Invoice__c             = suppInv.id;       
        suppInvLine.Invoice_Quantity__c             = 3;
        suppInvLine.Unit_Price__c                   = 20;//KNDY-14371        
        suppInvLine.Invoice_Quantity_to_Stock__c    = 8;
        suppInvLine.Item__c                         = [Select Id From Item__c where name='HP Printer' limit 1].id;
        suppInvLine.Purchase_Order__c               = [Select Id,Purchase_Order_Value__c from Purchase_Order__c where Memo__c = 'PurchaseOrder2' limit 1].id;
        suppInvLine.Purchase_Order_Line__c          = poLineList[0].id;
        suppInvLine.Quantity_Received__c            = 4;     
        suppInvLine.Line_Type__c                    = 'Item'; 
        
        insert suppInvLine; 
        
        suppInv.Status__c                           = 'Approved';
        suppInv.finalized__c                        = true;
        
        update suppInv;
          Test.startTest();   
        SupplierInvoiceAccounting sia              = new SupplierInvoiceAccounting();
        list<supplier_invoice_line__c> silList     = new list<supplier_invoice_line__c>();
        silList.add(suppInvLine);
        sia.execute(silList); 
       
        Accounting_Entry__c acctEntry              = [SELECT id, Name, Status__c,Supplier_Invoice__c, 
                                                                 Supplier__c,Period__c ,
                                                       (SELECT id, Name,Status__c, 
                                                        Amount_CR__c, Amount_DR__c, 
                                                        SubTransaction_Type__c, 
                                                        Line_Type__c 
                                                        FROM Accounting_Entry_Lines__r)
                                                       FROM Accounting_Entry__c 
                                                       WHERE Supplier_Invoice__c = :suppInv.id]; 

       acctEntry.status__C                         = 'Obsolete';
       update acctEntry;
         
       //Try updating the Period with In inactive Accouting entries    
       Period__c currentPeriod                   =  [SELECT id ,Type__c,Open__c 
                                                       FROM Period__c 
                                                       WHERE id  = :acctEntry.Period__c]; 
       currentPeriod.Type__c                     = 'General';
       Boolean sawException                      =  false;
       String expMsg ;
        try{
            update currentPeriod;     
        }
        catch(Exception cannotUpdateExp){
            sawException = true;
            expMsg = cannotUpdateExp.getMessage();  
        }
       
       //Expected behaviour : Should not throw exceptions 
       System.assertEquals(false, sawException) ;
       System.assertEquals(null,expMsg);  
        
       Test.stopTest();    
    } 

      //---------------KNDY-10520------------------
        // Change the period with Active Accounting Entries -- Should throw Exceptions
    public static testMethod void testDisablePeriodEditWithValidAEs(){ 
        Company__c comp = [Select Id from Company__c where Name = '400' limit 1];
        Currency__c usdCurr = [Select Id from Currency__c where ISO_Code__c = 'USD'];
        AEReadyData aer = new AEReadyData();
        Supplier_Invoice__c  suppInv           = new Supplier_Invoice__c();
        Supplier_Invoice_Line__c suppInvLine   = new Supplier_Invoice_Line__c(); 
        
        //Create Supplier Invoice  
        suppInv.Company__c                  = comp.id;
        suppInv.Invoice_Type__c             = 'Invoice';
        suppInv.Date_Invoiced__c            =  System.now();
        suppInv.Currency__c                 = [Select Id from Currency__c where ISO_Code__c = 'USD' limit 1].id;
        suppInv.Transaction_Date__c         = system.now();
        suppInv.Supplier__c                 = [Select Id from Supplier__c where Name = 'Test Remit To Supplier' limit 1].id;
        suppInv.Amount_Due__c               = [Select Id,Purchase_Order_Value__c from Purchase_Order__c where Memo__c = 'PurchaseOrder1' limit 1].Purchase_Order_Value__c;
        suppInv.Invoice_Amount__c           = 60;
        suppInv.historical__c = false;
        suppInv.Supplier_Invoice__c             = String.valueOfGmt(system.today());
        List<Purchase_Order_Line__c> poLineList = [Select id, Name , Currency__c 
                                                   from Purchase_Order_Line__c 
                                                   where  item__r.Name = 'HP Printer'
                                                   limit 2]; 
       
        
        insert suppInv; 
        System.debug('____suppInvsuppInv id___'+suppInv.Id);
        suppInvLine                                 = new Supplier_Invoice_Line__c(); 
        suppInvLine.Supplier_Invoice__c             = suppInv.id;       
        suppInvLine.Invoice_Quantity__c             = 3;
        suppInvLine.Unit_Price__c                   = 20;//KNDY-14371        
        suppInvLine.Invoice_Quantity_to_Stock__c    = 8;
        suppInvLine.Item__c                         = [Select Id From Item__c where name='HP Printer' limit 1].id;
        suppInvLine.Purchase_Order__c               = [Select Id,Purchase_Order_Value__c from Purchase_Order__c where Memo__c = 'PurchaseOrder2' limit 1].id;
        suppInvLine.Quantity_Received__c            = 4;     
        suppInvLine.Line_Type__c                    = 'Item'; 
        
        insert suppInvLine; 
        
        suppInv.Status__c                           = 'Approved';
        suppInv.finalized__c                        = true;
        
        update suppInv;
         Test.startTest();
        SupplierInvoiceAccounting sia               = new SupplierInvoiceAccounting();
        list<supplier_invoice_line__c> silList      = new list<supplier_invoice_line__c>();
        silList.add(suppInvLine);
        sia.execute(silList); 
       
        Accounting_Entry__c acctEntry               = [SELECT id, Name, Supplier_Invoice__c, Supplier__c,Period__c ,
                                                       (SELECT id, Name,Status__c, 
                                                        Amount_CR__c, Amount_DR__c, 
                                                        SubTransaction_Type__c, 
                                                        Line_Type__c 
                                                        FROM Accounting_Entry_Lines__r)
                                                       FROM Accounting_Entry__c 
                                                       WHERE Supplier_Invoice__c = :suppInv.id];   
      
       //Try updating the Period with Active Accouting entries- should throw exceptions 
       Period__c currentPeriod                    = [SELECT id ,Type__c,Open__c 
                                                       FROM Period__c 
                                                       WHERE id  = :acctEntry.Period__c]; 
       currentPeriod.Type__c                      = 'General';
       Boolean sawException                       =  false;
       String expMsg ;
        try{
            update currentPeriod;     
        }
        catch(Exception cannotUpdateExp){
            sawException = true;
            expMsg = cannotUpdateExp.getMessage();  
        }
       System.assertEquals(true, sawException) ;
       System.assert( expMsg.contains('Cannot change type for a period which has transactions recorded'));
       Test.stopTest();  
        
        } 
     
}