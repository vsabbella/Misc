/**
 * @description This test class constructs data used by other test classes to construct a simple sales order and lines
 * nothing else is created 
 */
@isTest
public class SalesOrderTestData {
    // if set to false by test case, SO Data like SO or SOLine will not be created.
    public static Boolean CreateSOData = true;

    public Customer__c customerParent = new Customer__c(); 
    public Customer__c customerBillTo = new Customer__c(); 
    public Customer__c customer = new Customer__c();  // this will be a sold to 
    public Customer__c customerSoldTo = new Customer__c(); 
    public Customer__c customerShipTo = new Customer__c(); 
    
    //TestData data = new TestData(); 
    public Account account = new Account();
        
    { 
        account.name = 'KenandySalesOrderTestData'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
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
    }
    
    public Company__c company = new Company__c();
    {
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.A_Days__c = 30;
        company.B_Days__c = 60;
        company.C_Days__c = 180;
        company.Company_Identifier__c = 'SOL';  // don't change this CompanyServiceTest check for it to be SOL
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert company;
    }
    
    public List<Period__c> periodList {
        get {
            if (periodList == null) {
                integer year = system.now().year();
                periodList = new List<Period__c>();
                for(integer i=1; i<=12; i++){
                    Period__c iPeriod = new Period__c();
                    iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
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
                    iPeriod.Company__c = company.Id;
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
                fy.company__c = company.Id;
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
        set;
    }    
    
    public Class__c clsObj= new Class__c();
    {
        clsObj.Name = 'Class-1';
        clsObj.Description__c = 'Item Class One';
        insert clsObj;
    }
    
    /*public UOM__c uomObj = new UOM__c(); 
    {
        uomObj.Name = 'EA';
        uomObj.Description__c = 'Each';
        insert uomObj;
    }*/
    
    
    public List<UOM__c> uomList = new List<UOM__c>();
    public List<String> uoms = new List<String>{'LB', 'TN', 'DZ', 'OZ', 'MI', 'YD', 'IN', 'FT', 'FT3','EA'};
    public List<String> uomdescs = new List<String>{'Pound', 'Ton', 'Dozen', 'Ounce', 'Mile', 'Yard', 'Inch', 'Foot', 'Cubic','Each'};
        
    {       
        for (Integer i = 0; i < uoms.size(); ++i) {
            UOM__c Obj = new UOM__c();
            Obj.Name = uoms[i];
            Obj.Description__c = uomdescs[i];
            uomList.add(Obj);
    }
        insert uomList;
    }    
    
    public Facility__c facility2 = new Facility__c();
    public Location__c location1 = new Location__c();  
    public Location__c location2 = new Location__c(); 
    public Location__c location3 = new Location__c();
    public Location__c location4 = new Location__c(); 
    public Location__c location5 = new Location__c();     
    public Location__c location6 = new Location__c();   
    public Location__c location7 = new Location__c(); 
    public Location__c location8 = new Location__c(); 
    public Location__c location9 = new Location__c(); 
    public Location__c location10 = new Location__c(); 
    
    {
        facility2.Name = company.Name + ' Facility-2';
        facility2.Company__c = company.Id;
        facility2.Description__c = 'Facility-2';
        insert facility2;
    
        location4.Facility__c = facility2.ID;
        location4.Name = 'Challenge';
        location4.Nettable__c = false;
        
        
        location5.Facility__c = facility2.ID;
        location5.Name = 'Finished Goods';
        location5.Nettable__c = true;
        
        
        location6.Facility__c = facility2.ID;
        location6.Name = 'MRB';
        // location6.Nettable__c = false;
        
        
        location7.Facility__c = facility2.ID;
        location7.Name = 'Putaway';
        location7.Nettable__c = true;
        
        
        location8.Facility__c = facility2.ID;
        location8.Name = 'Scrap';
        location8.Nettable__c = false;
        
        
        location9.Facility__c = facility2.ID;
        location9.Name = 'WIP';
        location9.Nettable__c = true;
        
        
        location10.Facility__c = facility2.ID;
        location10.Name = 'Shipping Dock';
        location10.Nettable__c = true;
        
        
        insert new List<Location__c> {location4, Location5, location6, location7, Location8, location9, location10};
            
    }
   
    {         
        facility2.Default_Purchasing_Delivery_Location__c = location1.Id;
        facility2.Default_Sales_Order_Ship_From_Location__c = location10.Id;
        facility2.Default_Work_Order_Complete_to_Location__c = location5.Id;
        facility2.Default_Work_Order_MRB_Location__c = location8.Id;
        facility2.Default_Work_Order_WIP_Location__c = location9.Id;
        update facility2;
    }
        
    public List<Item__c> itemList=new List<Item__c>();
    {
        string cn = company.Name + ' Item-10' ; 
        for(integer i=10;i<21;i++){
            Item__c item = new Item__c();
            item.name= company.Name + ' Item-'+i;
            item.Description__c='Item-'+i;
            if (i == 10 || i == 15) {
                item.Source__c = 'Manufactured';
                item.Class__c = clsobj.ID;
                item.Lead_Time__c = i/2;
                if (i == 10) item.ABC_Code__c = 'A';
                else item.ABC_Code__c = 'B';
            } 
            else {
                item.Source__c = 'Purchased';
                //  item.Supplier__c = supplier.ID;
                item.Purchasing_UOM__c = uomList[9].id;
                item.Lead_Time__c = i/5;
            }
            item.company__c = company.id;
            item.Active__c = true;
            item.Stocking_UOM__c = uomList[9].ID;
            item.Packaging_UOM__c = JSON.serialize( new List<Id> {uomList[9].ID});
            itemList.add(item);
        }
        insert itemList;
    }
        
        
   
    public List<UOM_Conversion_Details__c> uomcList = new List<UOM_Conversion_Details__c>(); 
    {       
        
       UOM_Conversion_Details__c Obj = new UOM_Conversion_Details__c();
                //DZ-EA
                Obj.Name = ((String)uomList[2].Id).substring(3, 15) + ((String)uomList[9].Id).substring(3, 15);
                Obj.uom_1__c = uomList[2].Id;
                Obj.uom_1_Quantity__c =1;
                Obj.uom_2__c = uomList[9].Id;
                Obj.uom_2_Quantity__c = 12.0;
                Obj.Key_1__c = string.valueof(uomList[2].Id)+string.valueof(uomList[9].Id); 
                Obj.Key_2__c = string.valueof(uomList[9].Id)+string.valueof(uomList[2].Id);
            uomcList.add(Obj);
                
                UOM_Conversion_Details__c Obj1 = new UOM_Conversion_Details__c();
                //FT-IN
                Obj1.Name = ((String)uomList[7].Id).substring(3, 15) + ((String)uomList[6].Id).substring(3, 15);
                Obj1.uom_1__c = uomList[7].Id;
                Obj1.uom_1_Quantity__c =1;
                Obj1.uom_2__c = uomList[6].Id;
                Obj1.uom_2_Quantity__c = 12.0;
                Obj1.Key_1__c = string.valueof(uomList[7].Id)+string.valueof(uomList[6].Id);
                Obj1.Key_2__c = string.valueof(uomList[6].Id)+string.valueof(uomList[7].Id);
                uomcList.add(Obj1);
                
                UOM_Conversion_Details__c Obj2 = new UOM_Conversion_Details__c();
                //LB-OZ
                Obj2.Name = ((String)uomList[0].Id).substring(3, 15) + ((String)uomList[3].Id).substring(3, 15);
                Obj2.uom_1__c = uomList[0].Id;
                Obj2.uom_1_Quantity__c =1;
                Obj2.uom_2__c = uomList[3].Id;
                Obj2.uom_2_Quantity__c = 16.0;
                Obj2.Key_1__c = string.valueof(uomList[0].Id)+string.valueof(uomList[3].Id);//string.valueof(itemList[0].Id) + 
                Obj2.Key_2__c = string.valueof(uomList[3].Id)+string.valueof(uomList[0].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj2);
                
                
                UOM_Conversion_Details__c Obj3 = new UOM_Conversion_Details__c();
                //MI-FT
                Obj3.Name = ((String)uomList[4].Id).substring(3, 15) + ((String)uomList[7].Id).substring(3, 15);
                Obj3.uom_1__c = uomList[4].Id;
                Obj3.uom_1_Quantity__c =1;
                Obj3.uom_2__c = uomList[7].Id;
                Obj3.uom_2_Quantity__c = 5280.0;
                Obj3.Key_1__c = string.valueof(uomList[4].Id)+string.valueof(uomList[7].Id);//string.valueof(itemList[0].Id) + 
                Obj3.Key_2__c = string.valueof(uomList[7].Id)+string.valueof(uomList[4].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj3);
                
                UOM_Conversion_Details__c Obj4 = new UOM_Conversion_Details__c();
                //MI-YD
                Obj4.Name = ((String)uomList[4].Id).substring(3, 15) + ((String)uomList[5].Id).substring(3, 15);
                Obj4.uom_1__c = uomList[4].Id;
                Obj4.uom_1_Quantity__c =1;
                Obj4.uom_2__c = uomList[5].Id;
                Obj4.uom_2_Quantity__c = 1760.0;
                Obj4.Key_1__c = string.valueof(uomList[4].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
                Obj4.Key_2__c = string.valueof(uomList[5].Id)+string.valueof(uomList[4].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj4);
                
                
                UOM_Conversion_Details__c Obj5 = new UOM_Conversion_Details__c();
                //TN-LB
                Obj5.Name = ((String)uomList[1].Id).substring(3, 15) + ((String)uomList[0].Id).substring(3, 15);
                Obj5.uom_1__c = uomList[1].Id;
                Obj5.uom_1_Quantity__c =1;
                Obj5.uom_2__c = uomList[0].Id;
                Obj5.uom_2_Quantity__c = 2000.0;
                Obj5.Key_1__c = string.valueof(uomList[1].Id)+string.valueof(uomList[0].Id);//string.valueof(itemList[0].Id) + 
                Obj5.Key_2__c = string.valueof(uomList[0].Id)+string.valueof(uomList[1].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj5);
                
                UOM_Conversion_Details__c Obj6 = new UOM_Conversion_Details__c();
                //YD-FT
                Obj6.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[7].Id).substring(3, 15);
                Obj6.uom_1__c = uomList[5].Id;
                Obj6.uom_1_Quantity__c =1;
                Obj6.uom_2__c = uomList[7].Id;
                Obj6.uom_2_Quantity__c = 3.0;
                Obj6.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[7].Id);//string.valueof(itemList[0].Id) + 
                Obj6.Key_2__c = string.valueof(uomList[7].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj6);
                
                
                UOM_Conversion_Details__c Obj7 = new UOM_Conversion_Details__c();
                //YD-FT
                Obj7.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[8].Id).substring(3, 15);
                Obj7.uom_1__c = uomList[5].Id;
                Obj7.uom_1_Quantity__c =1;
                Obj7.uom_2__c = uomList[8].Id;
                Obj7.uom_2_Quantity__c = 0.037040;
                Obj7.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[8].Id);//string.valueof(itemList[0].Id) + 
                Obj7.Key_2__c = string.valueof(uomList[8].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj7);
        insert uomcList;
    }
    
    public Product__c product = new Product__c();    
    public Product__c product2 = new Product__c();
    public Product__c product3 = new Product__c();
    {
        product.company__c = company.id;
        product.Name = 'Product 1' ;
        product.Item__c  = itemList[0].ID;
        product.Description__c = 'Product-10';
        product.Selling_UOM__c = uomList[9].ID;
        product.Weight__c = 13;
        product.Weight_UOM__c = uomList[3].ID;
        product.Dimension_UOM__c = uomList[5].ID;
        product.UPC_Code__c = '123456789123';  
        product.Length__c = 1.25;
        product.Height__c = 1;
        product.Width__c = 0.5;
        insert product;
        
        product2.company__c = company.id;
        product2.Name =  ' Product-15';
        product2.Item__c  = itemList[5].ID;
        product2.Description__c = 'Product-15';
        product2.Selling_UOM__c = uomList[9].ID;
        product2.Weight__c = 5;
        product2.Weight_UOM__c = uomList[1].ID;
        product2.Dimension_UOM__c = uomList[5].ID;
        product2.UPC_code__c = '234567891234'; 
        product2.Length__c = 1;
        product2.Height__c = 1;
        product2.Width__c = 1;
        insert product2;    
        
        product3.company__c = company.id;
        product3.Name =  ' Product-25';
        product3.Item__c  = itemList[5].ID;
        product3.Description__c = 'Product-15';
        product3.Selling_UOM__c = uomList[9].ID;
        product3.Weight__c = 5;
        product3.Weight_UOM__c = uomList[0].ID;
        product3.Dimension_UOM__c = uomList[5].ID;
        product3.UPC_code__c = '234567891235'; 
        product3.Length__c = 1;
        product3.Height__c = 1;
        product3.Width__c = 1;
        insert product3;    
    }
    
    public Payment_Term__c terms = new Payment_Term__c(); 
    {
        terms.name = '2/10 Net 30'; 
        terms.Description__c = '2% discount in 10 days, due 30 days';
        terms.Discount_Days__c = 10;
        terms.Discount_Percent__c = 2;
        terms.Due_Days__c = 30;
        insert terms; 
    }
    public Pricebook__c pricebook = new Pricebook__c(); 
    {
        pricebook.name = company.Name +  ' Orange Pricebook';
        pricebook.company__c = company.id; 
        pricebook.Currency__c = TestFuel.currencyUSD.id;
        insert pricebook; 
    }
    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    
    {
        system.assert( CustomerRecordTypes.get('Corporate_Parent') != null, 'expected valid id for corp to record type on customer');
        customerParent.name = company.Name + ' Customer Corp Parent 1';
        customerParent.recordTypeId = CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = company.id;
        customerParent.Payment_Term__c = terms.ID;
        customerParent.Address__c = account.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTEST123'; 
        customerParent.Status__c = 'Approved';
        customerParent.Currency__c = TestFuel.currencyUSD.ID;
        insert customerParent;
    
        
        system.assert( CustomerRecordTypes.get('Bill_To') != null, 'expected valid id for bill to record type on customer');
        customerBillTo.name = 'Customer Bill To 1';
        customerBillTo.recordTypeId = CustomerRecordTypes.get('Bill_To');
        customerBillTo.Company__c = company.id;
        customerBillTo.Payment_Term__c = terms.ID;
        customerBillTo.Address__c = account.ID;
        customerBillTo.Credit_Limit__c = 100000.0;
        customerBillTo.Parent_Customer__c = customerParent.id; 
        customerBillTo.Customer_Identifier__c = 'BDTEST123';
        customerBillTo.Status__c = 'Approved'; 
        customerBillTo.Currency__c = TestFuel.currencyUSD.ID;
        insert customerBillTo;
   
        
        system.assert( CustomerRecordTypes.get('Sold_To') != null, 'expected valid id for sold to record type on customer');
        customerSoldTo.name = 'Customer Sold To 1';
        customerSoldTo.recordTypeId = CustomerRecordTypes.get('Sold_To');
        customerSoldTo.Company__c = company.id;
        customerSoldTo.Payment_Term__c = terms.ID;
        customerSoldTo.Address__c = account.ID;
        customerSoldTo.Credit_Limit__c = 100000.0;
        customerSoldTo.Parent_Customer__c = customerBillTo.id; 
        customerSoldTo.Customer_Identifier__c = 'SDTEST123'; 
        customerSoldTo.pricebook__c = pricebook.id;
        customerSoldTo.Top_Parent_Customer__c = customerParent.Id;
        customerSoldTo.Status__c = 'Approved';
        customerSoldTo.Currency__c = TestFuel.currencyUSD.ID;
        insert customerSoldTo;
        customer = customerSoldTo; 

        system.assert( CustomerRecordTypes.get('Ship_To') != null, 'expected valid id for ship to record type on customer');
        customerShipTo.name = 'Customer Ship To 1';
        customerShipTo.recordTypeId = CustomerRecordTypes.get('Ship_To');
        customerShipTo.Company__c = company.id;
        customerShipTo.Payment_Term__c = terms.ID;
        customerShipTo.Address__c = account.ID;
        customerShipTo.Credit_Limit__c = 100000.0;
        customerShipTo.Parent_Customer__c = customerSoldTo.id;
        customerShipTo.Customer_Identifier__c = 'SHTEST123'; 
        customerShipTo.Status__c = 'Approved'; 
        customerShipTo.Currency__c = TestFuel.currencyUSD.ID;
        insert customerShipTo;
  
    }
    {
        Pricebook_Line__c pl =new Pricebook_Line__c();
        pl.product__c = product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 11.12;
        pl.Start_date__c = system.today(); 
        Pricebook_Line__c pl2 =new Pricebook_Line__c();
        pl2.product__c = product2.id;
        pl2.pricebook__c = pricebook.id;
        pl2.price__c = 12.11;
        pl2.Start_date__c = system.today();
        
        // note product3 is not in any pricebook        
        insert new List<Pricebook_Line__c>{pl,pl2};
    }
                    
    public list<Sales_Order_Line__c> SalesOrderLines=new list<Sales_Order_Line__c>();      
    public Sales_Order__c salesOrder=new Sales_Order__c();
    
    public Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
    
    public SalesOrderTestData( ) { init(); }
    public SalesOrderTestData( boolean flg ) { CreateSOData=flg; init(); }
    
    private void init()
    {   
        if ( CreateSOData ) {
            salesOrder.Company__c = company.id;
            salesOrder.Bill_To__c = customerBillTo.Id;
            salesOrder.Customer__c = customerSoldTo.id;   
            salesOrder.Ship_To__c = customerShipTo.Id;
            salesOrder.Payment_Term__c = terms.id;
            salesOrder.Weight_UOM__c = uomList[0].ID; //KNDY 3621 Setting Weight and Dimension UOM on Sales Order.
            salesOrder.Dimension_UOM__c = uomList[8].ID;
            salesOrder.Currency__c = TestFuel.currencyUSD.id;
            
            insert salesOrder;
            
            salesOrderLine = new Sales_Order_Line__c();
            SalesOrderLine.Product__c = product.Id;
            SalesOrderLine.Description__c = product.Description__c;
            SalesOrderLine.Company__c = company.id;
            SalesOrderLine.Sales_Order__c = salesOrder.Id;
            SalesOrderLine.Quantity_Ordered__c = 100;
            SalesOrderLine.Required_Date__c = System.today()+5;
            SalesOrderLine.Unit_Price__c = 11.12;
            SalesOrderLine.Discount_Percent__c = 2;
            SalesOrderLine.Weight_UOM__c = uomList[0].ID; //KNDY 3621 Setting Weight and Dimension UOM on Sales Order.
            SalesOrderLine.Dimension_UOM__c = uomList[8].ID;
            SalesOrderLine.Ship_From_Location__c = location10.ID;
            SalesOrderLines.add(SalesOrderLine);
            
            SalesOrderLine = new Sales_Order_Line__c();
            SalesOrderLine.Product__c = product2.Id;
            SalesOrderLine.Description__c = product2.Description__c;
            SalesOrderLine.Company__c = company.id;
            SalesOrderLine.Sales_Order__c = salesOrder.Id;
            SalesOrderLine.Quantity_Ordered__c = 15;
            SalesOrderLine.Required_Date__c = System.today()+15;
            SalesOrderLine.Unit_Price__c = 12.11;
            SalesOrderLine.Weight_UOM__c = uomList[0].ID; //KNDY 3621 Setting Weight and Dimension UOM on Sales Order.
            SalesOrderLine.Dimension_UOM__c = uomList[8].ID;
            SalesOrderLine.Ship_From_Location__c = location10.ID;
            SalesOrderLines.add(SalesOrderLine);
            
            insert SalesOrderLines;
            
            salesOrder = [Select s.Status__c, s.Customer__c, s.Company__c, Currency__c,
                          (Select Id, IsDeleted, Name, CreatedDate, CreatedById, 
                           LastModifiedDate, LastModifiedById, SystemModstamp, Sales_Order__c, 
                           Backorder_Value__c, Company__c, Description__c, Discount_Percent__c, 
                           Extended_Price__c, Product__r.Item__c, Line__c, Quantity_Backordered__c, 
                           Quantity_Ordered__c, Quantity_Shipped__c, Required_Date__c, Status__c, Product__r.Item__r.Class__c,
                           Unit_Price__c From Sales_Order_Lines__r order by Line__c asc) 
                          From Sales_Order__c s where id=:salesOrder.id limit 1];
            
            SalesOrderLines = salesOrder.Sales_Order_Lines__r;
            
            system.assertEquals(1,SalesOrderLines[0].Line__c);
            system.assertEquals(2,SalesOrderLines[1].Line__c);
        }           
    }
    
}