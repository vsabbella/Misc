@isTest
public with sharing class TestInvoice {
    
	public Pricebook__c pricebook = new Pricebook__c(); 
	public Pricebook_Line__c pl =new Pricebook_Line__c();
    public product__c product = new product__c();
    public List<Sales_Order__c> soList = new List<Sales_Order__c>();
    public List<Shipment_Line__c> shipLineList = new List<Shipment_Line__c>();
    public List<Sales_Order_Line__c> soLineList = new List<Sales_Order_Line__c>();
    public List<Shipment__c> shipmentList = new List<Shipment__c>();
    public Account account ;
    public Company__c company ;
    public Payment_Term__c terms = new Payment_Term__c(); 
    
    public Customer__c customerParent = new Customer__c(); 
    public Customer__c customerBillTo = new Customer__c(); 
    public Customer__c customer = new Customer__c();  // this will be a sold to 
    public Customer__c customerSoldTo = new Customer__c(); 
    public Customer__c customerShipTo = new Customer__c(); 
    
    public Location__c location = new Location__c(); 
    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    
    private Set<id> soIdSet = new Set<id>();
                
    public static TestInvoice getInstance(){
        if ( instance == null ) instance = new TestInvoice();
        return instance;
    } 
    private static TestInvoice instance = null;

    //public TestData data = TestData.getInstance();
    
    
    private TestInvoice() { 
		TestFuel globalTestData = new TestFuel();
		company = globalTestData.company;
		List <Period__c> periodList = globalTestData.periodList;
     
        account = new Account();
        account.Name = 'Kenandy';
        insert account;
    
        /*company = new Company__c();
        company.Name= 'Kenandy';
        //company.Account__c = account.Id;
        company.A_Days__c = 15;
        company.B_Days__c = 30;
        company.C_Days__c = 45;
        insert company; */
  
        terms.name = '2/10 Net 30'; 
        terms.Description__c = '2% discount in 10 days, due 30 days';
        terms.Discount_Days__c = 10;
        terms.Discount_Percent__c = 2;
        terms.Due_Days__c = 30;
        insert terms; 
  
        SetupCustomer();
        
        
            
        Facility__c facility = new Facility__c();
        
        facility.Name = 'foo';
        facility.Company__c = company.Id;
        facility.Description__c = 'Facility-1';
        insert facility;
        
        location.Facility__c = facility.id;
        location.name = 'Receiving Dock';
        location.Nettable__c = false;
        insert location;
        
        GL_Account__c inventoryGL = globalTestData.FGInventoryGL;
        /*GL_Account__c inventoryGL = new GL_Account__c();
        inventoryGL = new GL_Account__c();
        inventoryGL.Name = '42000 - Revenue';
        inventoryGL.Report_Section__c = 'Revenue';
        inventoryGL.Normal_Balance__c = 'Credit';
        inventoryGL.active__c = true;
        inventoryGL.Statement_Type__c = 'Income Statement';  
        insert inventoryGL;*/
        
        Class__c clsObj=new Class__c();
        clsObj.name = 'Class-1';
        clsObj.Inventory_GL_Account__c = inventoryGL.id;
        clsObj.Type__c= 'Goods';
        
        Item__c item = new Item__c(); 
        integer i = 1;
        item.company__c = company.id;
        item.name= company.Name + ' Item-'+i;
        item.Description__c='Item-'+i;
        item.Source__c = 'Manufactured';
        item.Class__c = clsobj.ID;
        item.Lead_Time__c = i/2;
        item.ABC_Code__c = 'A';
        item.Stocking_UOM__c = globalTestData.uomList[8].Id;
        item.Packaging_UOM__c = JSON.serialize(new List<Id>{ globalTestData.uomList[8].Id });
        insert item;  
                    
        product = new Product__c();  
        product.company__c = company.id;
        product.Name = 'product name ' ;
        product.Item__c  = item.ID;
        product.Description__c = 'Product-10';
       // product.Selling_UOM__c = uomObj.ID;
        product.Weight__c = 13;
      //  product.Weight_UOM__c = uomList[0].ID;
        product.UPC_Code__c = '123456789123';  
        product.units_per_layer__c = 1;
        product.layers_per_pallet__c = 1; 
        insert product;    
        
        
        pricebook = new Pricebook__c(); 
  		pricebook.name = company.Name +  ' Orange Pricebook';
  		pricebook.company__c = company.id; 
		pricebook.Primary_Key__c = 'NATBOOK-TRADE';
		pricebook.Trade_Promotion__c = true;
  		insert pricebook;  
        
    	pl = new Pricebook_Line__c();
  		pl.product__c = product.Id;
  		pl.pricebook__c = pricebook.id;
  		pl.price__c = 1;
        pl.Start_date__c = system.today(); 
        pl.End_Date__c = System.today().addDays(20);
        insert pl;
            
        for(integer j=0; j<6; j++){
            Sales_Order__c so = new Sales_Order__c();
            so.Customer__c = customer.id; 
            so.Ship_Complete__c = true;
            so.Currency__c = TestFuel.currencyUSD.id;
            so.Company__c = company.id;
            so.Pricebook__c = pricebook.Id;
            soList.add(so);
        }
        insert soList;    
         
        for(Sales_Order__c so: soList){
            soidSet.add(so.id);
            
            Sales_Order_Line__c soLine1 = new Sales_Order_Line__c();
            soLine1.Company__c = so.Company__c;
            soLine1.Sales_Order__c = so.Id;
            soLine1.Quantity_Ordered__c = 3;
            soLine1.Quantity_Shipped__c = 3; // have to show shipped or we never get a closed line
            //soLine1.Unit_Price__c = 10;
            soLine1.Required_Date__c = System.today()+5;
            soLine1.Status__c='Closed';
            soLine1.Ship_From_Location__c = location.id;
            soLine1.Product__c = product.Id;
            soLine1.Product__r = product;
            soLine1.Discount_Percent__c = 1;
			soLine1.Off_Invoice_Rate__c = 0.5;
			soLine1.BillBack_Rate__c = 1;            
            soLine1.List_Price__c = 1; //KNDY-4509
            soLine1.Line_Type__c = 'Standard';
            soLineList.add(soLine1);
            
            Sales_Order_Line__c soLine2 = new Sales_Order_Line__c();
            soLine2.Company__c = so.Company__c;
            soLine2.Sales_Order__c = so.Id;
            soLine2.Quantity_Ordered__c = 4;
            soLine2.Quantity_Shipped__c = 4;
            //soLine2.Unit_Price__c = 20;
            soLine2.Required_Date__c = System.today()+5;
            soLine2.Status__c='Closed';
            soLine2.Ship_From_Location__c = location.id;
            soLine2.Product__c = product.Id;
            soLine2.Product__r = product;
            soLine2.Discount_Percent__c = 1;
			soLine2.Off_Invoice_Rate__c = 0.5;
			soLine2.BillBack_Rate__c = 1;   
			soLine2.List_Price__c = 1;   //KNDY-4509            
            soLine2.Line_Type__c = 'Standard';
            soLineList.add(soLine2);
        }
        
        insert soLineList;
         
        for(Sales_Order__c so : soList){
            so.Status__c = 'Closed';
        }
        update soList;
        
        //reQuerySalesOrder();
        
        Datetime myDate = datetime.newInstance(System.today().year(), system.today().month(), system.today().day()-1, 00, 00, 00);
        for(Integer ii =0;ii<6;ii++){
            Shipment__c shipment = new Shipment__c();
            shipment.Customer__c = customerShipTo.id;
            shipment.Date_Shipped__c = system.now(); 
            shipment.Currency__c = TestFuel.currencyUSD.id;
            shipment.status__c = 'Confirmed';
            //KNDY-3369 shipment.Accounted__c = false;
            shipment.Company__c = company.id; 
            shipmentList.add(shipment);
        }
        insert shipmentList;
        
        Integer k = 0;
        
        for(Integer ii = 0; ii< soLineList.size()-1; ii+=2){
        //for(Integer ii = 0; ii< soList.size()-1; ii++){
            Shipment_Line__c shipLine1 = new Shipment_Line__c();
            shipLine1.Company__c = company.id;
            shipLine1.Extended_Cost__c = 5;
            shipLine1.Quantity_Planned__c = soLineList[ii].Quantity_Ordered__c;
            shipLine1.Quantity_Allocated__c = 0;
            shipLine1.Quantity_To_Pick__c = 0;
            shipLine1.Quantity_Picked__c = 0;
            shipLine1.Quantity_Shipped__c = soLineList[ii].Quantity_Ordered__c;
            shipLine1.Sales_Order__c = soLineList[ii].Sales_Order__c;
            shipLine1.Sales_Order_Line__c = soLineList[ii].ID;
            shipLine1.Unit_Price__c = soLineList[ii].Unit_Price__c;
            shipLine1.Item__c = soLineList[ii].Product__r.Item__c;
            shipLine1.Product__c = soLineList[ii].Product__c;
            shipLine1.Location__c = soLineList[ii].Ship_From_Location__c;
            shipLine1.Shipment__c = shipmentList[k].id;
            shipLineList.add(shipLine1);
            
            Shipment_Line__c shipLine2 = new Shipment_Line__c();
            shipLine2.Company__c = company.id;
            shipLine2.Extended_Cost__c = 5;
            shipLine2.Quantity_Planned__c = soLineList[ii+1].Quantity_Ordered__c;
            shipLine2.Quantity_Allocated__c = 0;
            shipLine2.Quantity_To_Pick__c = 0;
            shipLine2.Quantity_Picked__c = 0;
            shipLine2.Quantity_Shipped__c = soLineList[ii+1].Quantity_Ordered__c;
            shipLine2.Sales_Order__c = soLineList[ii+1].Sales_Order__c;
            shipLine2.Sales_Order_Line__c = soLineList[ii+1].ID;
            shipLine2.Unit_Price__c = soLineList[ii+1].Unit_Price__c;
            shipLine2.Item__c = soLineList[ii+1].Product__r.Item__c;
            shipLine2.Product__c = soLineList[ii+1].Product__c;
            shipLine2.Location__c = soLineList[ii+1].Ship_From_Location__c;
            shipLine2.Shipment__c = shipmentList[k].id;
            shipLineList.add(shipLine2);
            if(k<5){
            	k++;
            }
            i++;
        }
        insert shipLineList;
        
        shipLineList[0].Shipment__c = shipmentList[0].id;
        shipLineList[1].Shipment__c = shipmentList[0].id;
        shipLineList[2].Shipment__c = shipmentList[1].id;
        shipLineList[3].Shipment__c = shipmentList[1].id;
        shipLineList[4].Shipment__c = shipmentList[2].id;
        shipLineList[5].Shipment__c = shipmentList[2].id;
        shipLineList[6].Shipment__c = shipmentList[3].id;
        shipLineList[7].Shipment__c = shipmentList[3].id;
        shipLineList[8].Shipment__c = shipmentList[4].id;
        shipLineList[9].Shipment__c = shipmentList[4].id;
        shipLineList[10].Shipment__c = shipmentList[5].id;
        shipLineList[11].Shipment__c = shipmentList[5].id;
        
        update shipLineList;
        
        for(Shipment__c thisShipment: shipmentList){
        	thisShipment.Finalized__c = true;
        }
        update shipmentList;
        
    }
    
    public void reQuerySalesOrder() {
        soList = [Select s.Status__c, s.Customer__c, s.Company__c,  Total_Weight__c,
                                (Select Id, Name, Has_Exceptions__c,  Sales_Order__c,
                                Backorder_Value__c, Company__c, Description__c, Discount_Percent__c, 
                                Extended_Price__c, Product__r.Item__c, Line__c, Quantity_Backordered__c, 
                                Quantity_Ordered__c, Quantity_Shipped__c, Required_Date__c, Status__c, Product__r.Item__r.Class__c,
                                Unit_Price__c From Sales_Order_Lines__r ) 
                    From Sales_Order__c s where id in :soidset ];
        // The sales order's status must not be affected by the status of the lines.
        //for ( Sales_Order__c so: soList ) {
        //  system.assertEquals( 'Draft', so.Status__c );
        //}
    }
    
    
    private void SetupCustomer() { 
        customerParent.name = company.Name + ' Customer Corp Parent 1';
        customerParent.recordTypeId = CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = company.id;
        customerParent.Payment_Term__c = terms.ID;
        //customerParent.Address__c = soldtoaccount.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTEST123'; 
        insert customerParent;
    
        system.assert( CustomerRecordTypes.get('Bill_To') != null, 'expected valid id for bill to record type on customer');
        customerBillTo.name = 'Customer Bill To 1';
        customerBillTo.recordTypeId = CustomerRecordTypes.get('Bill_To');
        customerBillTo.Company__c = company.id;
        customerBillTo.Payment_Term__c = terms.ID;
        //customerBillTo.Address__c = billtoaccount.ID;
        customerBillTo.Credit_Limit__c = 100000.0;
        customerBillTo.Parent_Customer__c = customerParent.id; 
        customerBillTo.Customer_Identifier__c = 'BDTEST123'; 
        insert customerBillTo;
   
        system.assert( CustomerRecordTypes.get('Sold_To') != null, 'expected valid id for sold to record type on customer');
        customerSoldTo.name = 'Customer Sold To 1';
        customerSoldTo.recordTypeId = CustomerRecordTypes.get('Sold_To');
        customerSoldTo.Company__c = company.id;
        customerSoldTo.Payment_Term__c = terms.ID;
        //customerSoldTo.Address__c = soldtoaccount.ID;
        customerSoldTo.Credit_Limit__c = 100000.0;
        customerSoldTo.Parent_Customer__c = customerBillTo.id; 
        customerSoldTo.Customer_Identifier__c = 'SDTEST123'; 
        //customerSoldTo.Pricebook__c = pricebook.id;
        insert customerSoldTo;
        
        customer = customerSoldTo; 

        system.assert( CustomerRecordTypes.get('Ship_To') != null, 'expected valid id for ship to record type on customer');
        customerShipTo.name = 'Customer Ship To 1';
        customerShipTo.recordTypeId = CustomerRecordTypes.get('Ship_To');
        customerShipTo.Company__c = company.id;
        customerShipTo.Payment_Term__c = terms.ID;
        //customerShipTo.Address__c = shiptoaccount.ID;
        customerShipTo.Credit_Limit__c = 100000.0;
        customerShipTo.Parent_Customer__c = customerSoldTo.id;
        customerShipTo.Customer_Identifier__c = 'SHTEST123';  
        insert customerShipTo;
    }
    
    
    /*static testmethod void t1() { 
        TestInvoice data = TestInvoice.getInstance();
        Test.startTest();
        system.assert( data.shipLineList.size() > 0 );
    }*/
}