@isTest
public class TestData_Extension {
    public static String uniqueString () { return String.valueOf(System.currentTimeMillis()); }
    public testdata td = new testdata();
    
    public Exchange_Rate__c CADUSDExchangeRate = new Exchange_Rate__c(); {
    	
    	CADUSDExchangeRate.From_Currency__c = TestFuel.currencyCAD.id;
    	CADUSDExchangeRate.To_Currency__c = TestFuel.currencyUSD.id;
    	CADUSDExchangeRate.Daily_Monthly__c = 'Daily';
    	CADUSDExchangeRate.Exchange_Rate_Type__c = 'Corporate';
    	CADUSDExchangeRate.Multiplier_Exchange_Rate__c = 1;
    	CADUSDExchangeRate.Active__c = true;
    	CADUSDExchangeRate.Rate_Start_DateTime__c = system.now() - 1 ;
    	CADUSDExchangeRate.Rate_End_DateTime__c = system.now() + 1;
    	
    	insert CADUSDExchangeRate;
    	
    }
    
    public Exchange_Rate__c CADEURExchangeRate = new Exchange_Rate__c(); {
    	
    	CADEURExchangeRate.From_Currency__c = TestFuel.currencyCAD.id;
    	CADEURExchangeRate.To_Currency__c = TestFuel.currencyEUR.id;
    	CADEURExchangeRate.Daily_Monthly__c = 'Daily';
    	CADEURExchangeRate.Exchange_Rate_Type__c = 'Corporate';
    	CADEURExchangeRate.Multiplier_Exchange_Rate__c = 1;
    	CADEURExchangeRate.Active__c = true;
    	CADEURExchangeRate.Rate_Start_DateTime__c = system.now() - 1;
    	CADEURExchangeRate.Rate_End_DateTime__c = system.now() + 1;
    	
    	insert CADEURExchangeRate;
    	
    }
       
    public Exchange_Rate__c ExchangeRate = new Exchange_Rate__c(); {
    	
    	ExchangeRate.From_Currency__c = TestFuel.currencyUSD.id;
    	ExchangeRate.To_Currency__c = TestFuel.currencyUSD.id;
    	ExchangeRate.Daily_Monthly__c = 'Daily';
    	ExchangeRate.Exchange_Rate_Type__c = 'Corporate';
    	ExchangeRate.Multiplier_Exchange_Rate__c = 1;
    	ExchangeRate.Active__c = true;
    	ExchangeRate.Rate_Start_DateTime__c = system.now() - 1;
    	ExchangeRate.Rate_End_DateTime__c = system.now() + 1;
    	
    	insert ExchangeRate;
    	
    }
    
    public Exchange_Rate__c ExchangeRate1 = new Exchange_Rate__c(); {
    	
    	ExchangeRate1.From_Currency__c = TestFuel.currencyUSD.id;
    	ExchangeRate1.To_Currency__c = TestFuel.currencyEUR.id;
    	ExchangeRate1.Daily_Monthly__c = 'Daily';
    	ExchangeRate1.Exchange_Rate_Type__c = 'Corporate';
    	ExchangeRate1.Multiplier_Exchange_Rate__c = 1;
    	ExchangeRate1.Active__c = true;
    	ExchangeRate1.Rate_Start_DateTime__c = system.now() - 1;
    	ExchangeRate1.Rate_End_DateTime__c = system.now() + 1;
    	
    	insert ExchangeRate1;
    	
    }
       
    public Company__c company = new Company__c();{
        company = td.company;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;        
    }
    
    public Accounting_Default__c accDef = new Accounting_Default__c();{
        accDef.Company__c = td.company.id;
        accDef.GL_Account__c = td.AcctData.CashGL.id;
        insert accDef;
    }
    
    public User_Preference__c userinfo = new User_Preference__c();{
        // Company
        userinfo.Default_Company__c = td.company.id;
        userinfo.Accounting_Default__c = accDef.id;
        userinfo.Default_Facility__c = td.facility.id;
        insert userinfo;
    }
    
    public UOM__c uom = new UOM__c();{
        uom.name = 'EA' + uniquestring();
        insert uom;
    }
    
    public Item__c Item = new Item__c(); {
        Item.name = 'Catalog Item '+ uniquestring();
        Item.description__c = 'test catalog item';
        Item.source__c = 'Miscellaneous';
        Item.Non_Inventory__c = true;
        Item.Purchasing_UOM__c = UOM.id;
        insert Item;     
    }
    
    // Test to see all above elements can be inserted correctly
    public static testMethod void t1() {
        testdata_extension td_ext = new testdata_extension();
        system.assert( td_ext != null ); 
    }
    
    public static testMethod void checkBinUniqueness(){
        TestData globalTestData = new TestData();
        update new Location__c(id = globalTestData.location.Id ,Bin_Tracked__c = true );
        Bin__c originalBin = new Bin__c(
                            Name = 'Bin 1',
                            Location__c = globalTestData.location.Id);
        insert originalBin;
        
        Bin__c duplicateBin = new Bin__c(
                            Name = 'Bin 1',
                            Location__c = globalTestData.location.Id);
        try{
            insert duplicateBin;
            system.assert(false, 'Duplicate bin creation did not fail.');
        }catch(Exception e){
            system.assert(duplicateBin.Id == null);
        }
    }
    
    public static testMethod void checkPricebookUniqueness(){
        TestData globalTestData = new TestData();
        
        Pricebook__c originalPricebook = new Pricebook__c(
                            Name = 'Pricebook 1',
                            Company__c = globalTestData.company.Id);
        insert originalPricebook;
        
        Pricebook__c duplicatePricebook = new Pricebook__c(
                            Name = 'Pricebook 1',
                            Company__c = globalTestData.company.Id);
        try{
            insert duplicatePricebook;
            system.assert(false, 'Duplicate Pricebook creation did not fail.');
        }catch(Exception e){
            system.assert(duplicatePricebook.Id == null);
        }
    }
    
    public static testMethod void gridTileCon_test() { 
        gridTileCon con = new gridTileCon(); 
        con.token = 'Account';
        con.titleSTR = 'address';
        system.assertEquals( '/001', con.hrefURL);
        system.assertNotEquals( null, con.labelPlural);
        system.assertEquals( 'Account', con.className);
    }
    
}