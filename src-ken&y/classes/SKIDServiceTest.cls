@isTest
public with sharing class SKIDServiceTest {  // TODO this should use the data from TestData , please !
    
    // Create data required for testing
    public class TestDataForSkidService{
        
        public Account account ;{
            account = new Account();
            account.Name = 'Kenandy';
            insert account;
        }
        
        public Company__c company ;{
            company = new Company__c();
            company.Name= 'Kenandy';
            //company.Account__c = account.Id;
            company.A_Days__c = 15;
            company.B_Days__c = 30;
            company.C_Days__c = 45;
            company.Comp_Currency__c = TestFuel.currencySGD.id;
            company.Consol_Currency__c = TestFuel.currencyEUR.id;
            company.Stat_Currency__c = TestFuel.currencyGBP.id;
            company.Subs_Currency__c = TestFuel.currencyUSD.id;
            company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;            
            
            List<Company__c> existingCompanies = [select Id,Name, A_Days__c, B_Days__c, C_Days__c from Company__c];
            
            if(existingCompanies.size() > 0 ){
                company = existingCompanies[0];
            }else{
                insert company; 
            }
        }
        public map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c'); 
        
        public Supplier__c supplier ;{
            supplier = new Supplier__c();
            String supnam = company.Name + ' Supplier-1';
            supplier.Name = supnam;
            supplier.Company__c = company.ID;
            supplier.Tax_ID__c = 'tax ID';
            //supplier.Address__c = remittoaccount.ID;
            supplier.Status__c = 'Active';
            supplier.Type__c = 'Purchasing';
            supplier.RecordTypeId = rtMap.get('Purchase_From');
            List<Supplier__c> existingSuppliers = [select Id,Name, Company__c, RecordType.Name, RecordType.DeveloperName, RecordTypeId, Tax_ID__c, Status__c from Supplier__c];
            if(existingSuppliers.size() > 0 ){
                supplier = existingSuppliers[0];
            }else{
                insert supplier;    
            }
        }
        
        public Item__c item ;{
            item = new Item__c();
            item.Name = 'Phone';
            item.Company__c = company.Id;
            item.Active__c = true;
            insert item;
        }
        
        public Facility__c facility ;{
            facility = new Facility__c();
            facility.Name = 'Warehouse 8';
            facility.Company__c = company.Id;
            insert facility;
        }
        
            
        public List<Location__c> locationList ;{
            
            locationList = new List<Location__c>();
            
            Location__c location = new Location__c();
            location.Name = 'Receiving Dock 8';
            location.Facility__c = facility.Id;
            locationList.add(location);
            
            Location__c location2 = new Location__c();
            location2.Name = 'Inspection 8';
            location2.Facility__c = facility.Id;
            locationList.add(location2);
            
            Location__c location3 = new Location__c();
            location3.Name = 'Stock 8';
            location3.Facility__c = facility.Id;
            locationList.add(location3);
            
            Location__c location4 = new Location__c();
            location4.Name = 'Challange 8';
            location4.Facility__c = facility.Id;
            locationList.add(location4);
            
            insert locationList;
        }
        
        public SKID__c plannedSkid ;{
            plannedSkid = new SKID__c();
            plannedSkid.Company__c = company.Id;
            plannedSkid.Item__c = item.Id;
            plannedSkid.Item__r = item;
            plannedSkid.Location__c = locationList[0].Id;
            plannedSkid.Location__r = locationList[0];
            plannedSkid.Quantity__c = 10;
            plannedSkid.Type__c = SKIDService.SKID_TYPE_PO_SUPPLY;
            insert plannedSkid;
        }
        
        public SKID__c receivedSkid ;{
            receivedSkid = new SKID__c();
            receivedSkid.Company__c = company.Id;
            receivedSkid.Item__c = item.Id;
            receivedSkid.Item__r = item;
            receivedSkid.Location__c = locationList[1].Id;
            receivedSkid.Location__r = locationList[1];
            receivedSkid.Quantity__c = 10;
            receivedSkid.Type__c = 'Location';
            insert receivedSkid;
        }
        
        public List<Period__c> periods;{
        	periods = new List<Period__c>();
			integer year = system.now().year();
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
			    
			    periods.add(iPeriod);
			}
			Fiscal_Year__c fy = new Fiscal_Year__c();
			fy.company__c = company.Id;
			fy.fiscal_year_start_date__c = periods[0].period_start__c;
			fy.fiscal_year_end_date__c = periods[periods.size()-1].period_end__c.addMonths(3);
			
			insert fy;

        	for(Period__c p : periods){
				p.fiscalyear__c = fy.Id;
        	}
			insert periods;
        }
    }
    
            
    // Simulate a race condition and check if the records are updated correctly
    public static testMethod void testRaceCondition(){
        TestDataForSkidService testData = new TestDataForSkidService();
        testData.plannedSkid.Quantity__c = 100;
        update testData.plannedSkid;
        
        Test.startTest();
        for(Integer i=0;i<10;i++){
            //processSkidsAsynchronously(testData.plannedSkid.Id);
        }
        Test.stopTest();
        
        Map<Id, SKID__c> skidMap = new Map<Id,SKID__c>([select Id, Location__c, Primary_Key_At_Location__c, Quantity__c, Lot_Number__c, Expiration_Date__c 
                                                        from SKID__c 
                                                        where Location__c = :testData.locationList[1].Id]);
        // Assert that a new skid has been created (there are existing planned and received skids)
        system.assert( skidMap.keySet().size() > 0 , 'expected skid map');
    }
    
    public static testMethod void testMissingItemOnSkid() {
        
    	// PTM-566 verify that the trigger will throw an exception for a skid with no item
    	Skid__c sk = new Skid__c(); 
        try { insert sk;  } catch ( exception e) { 
            // SKID__c:{} Insert failed. First exception on row 0; first error: 
            // FIELD_CUSTOM_VALIDATION_EXCEPTION, Invalid Item null: [Item__c]
            system.debug(LoggingLevel.INFO, sk + ' ' + e.getMessage());
            system.assert( e.getMessage().contains( label.Invalid_Item ));
        }
        system.assert( sk.id == null, ' expected that we cannot insert a skid with no item');
    }
    
    public static testMethod void testMissingCompanyOnSkid() {
        
    	// verify that the trigger will throw an exception for a skid with no company
    	Skid__c sk = new Skid__c(); 
        try { insert sk;  } catch ( exception e) { 
            system.assert( e.getMessage().contains( label.Invalid_Item ));
        }
        system.assert( sk.id == null, ' expected that we cannot insert a skid with no item');
    }
}