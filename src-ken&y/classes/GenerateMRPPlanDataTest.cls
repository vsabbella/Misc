/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class GenerateMRPPlanDataTest {

    static testMethod void batchTest() {
        ID calID;
        
        TestData data=new TestData();
        
        calID = [select Id from BusinessHours where isDefault = true limit 1].Id;
        Date todaysDate=KSE.calculateStartDate(Date.today(),0,calID); 
        integer nextLevel=0;
        Date dateFilter=date.newInstance(2011, 1, 1);
        Id companyId=data.company.Id;
        
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = null;
        insert mrpRun;
        
        list<MRP__c> insertList=new list<MRP__c>();
         
        for(integer i=1;i<11;i++){
            data.itemList[i-1].use_lot_sizing__c = true;
            data.itemList[i-1].safety_stock__c = 1000; 
            
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=companyId;
            mrpObj.Item__c=data.itemList[i-1].ID;
            mrpObj.Quantity__c=50;
            mrpObj.Modified_Quantity__c=50;
            mrpObj.Required_Date__c=system.today();
            if (i < 5) mrpObj.Is_Demand__c=true;
            else mrpObj.Is_Demand__c=false;
            mrpObj.MRP_Run__c = mrpRun.ID;
            insertList.add(mrpObj);
        }
        
        if(insertList.size()>0)
            insert insertList;
        
        nextLevel=integer.valueof([select Level__c from MRP__c order by Level__c desc limit 1].Level__c);
        
        test.startTest();
        
        GenerateMRPPlanData obj=new GenerateMRPPlanData(nextLevel, mrpRun.ID, calID, calID);
        obj.query='select Id,Name,Use_Lot_Sizing__c,Safety_Stock__c,Shrinkage__c,EOQ__c,Ordering_Multiple__c,Lead_Time__c,Source__c,'+
                '(select Id from Item_Specifications__r where Start_Date2__c<=:todaysDate order by Start_Date2__c desc limit 1),'+
                '(select Id,Item__c,Demand__c,Quantity__c,Modified_Quantity__c,Required_Date__c,Start_Date__c,Is_Demand__c,Level__c,Where_Required__c,Company__c '+
                'from MRPs__r where MRP_Run__c = :mrpRunID AND Is_Demand__c=true order by Required_Date__c asc) from Item__c where Id in '+
                '(select Item__c from MRP__c where Level__c=:nextLevel and Is_Demand__c=true)  limit 200'; //and Company__c=:companyId
                
        Id jobId=Database.executeBatch(obj);
        
        test.stopTest();
        
        system.assert(jobId!=null);
    }
    
    static testMethod void batchTestByFacility() {
        ID calID;
        
        TestData data=new TestData();
        
        calID = [select Id from BusinessHours where isDefault = true limit 1].Id;
        Date todaysDate=KSE.calculateStartDate(Date.today(),0,calID); 
        integer nextLevel=0;
        Date dateFilter=date.newInstance(2011, 1, 1);
        Id companyId=data.company.Id;
        
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = data.facility.id;
        insert mrpRun;
        
        list<MRP__c> insertList=new list<MRP__c>();
        list<Facility_Item__c> fiList =new list<Facility_Item__c>();
         
        for(integer i=1;i<11;i++){
            data.itemList[i-1].use_lot_sizing__c = true;
            data.itemList[i-1].safety_stock__c = 1000; 
            
            Facility_Item__c fi = new Facility_Item__c( Company__c = data.Company.id, item__c = data.itemList[i-1].id, Facility__c = data.facility.id);
            fiList.add(fi);
            
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=companyId;
            mrpObj.Item__c=data.itemList[i-1].ID;
            mrpObj.Quantity__c=50;
            mrpObj.Modified_Quantity__c=50;
            mrpObj.Required_Date__c=system.today();
            if (i < 5) mrpObj.Is_Demand__c=true;
            else mrpObj.Is_Demand__c=false;
            mrpObj.MRP_Run__c = mrpRun.ID;
            insertList.add(mrpObj);
        }
        
        insert fiList;
        update data.itemList;
        
        if(insertList.size()>0)
            insert insertList;
        
        nextLevel=integer.valueof([select Level__c from MRP__c order by Level__c desc limit 1].Level__c);
        
        test.startTest();
        
        GenerateMRPPlanData obj=new GenerateMRPPlanData(nextLevel, mrpRun.ID, calID, calID);
        obj.query='select Id,Name,Use_Lot_Sizing__c,Safety_Stock__c,Shrinkage__c,EOQ__c,Ordering_Multiple__c,Lead_Time__c,Source__c,'+
                '(select Id from Item_Specifications__r where Start_Date2__c<=:todaysDate order by Start_Date2__c desc limit 1),'+
                '(select Id,Item__c,Demand__c,Quantity__c,Modified_Quantity__c,Required_Date__c,Start_Date__c,Is_Demand__c,Level__c,Where_Required__c,Company__c '+
                'from MRPs__r where MRP_Run__c = :mrpRunID AND Is_Demand__c=true order by Required_Date__c asc) from Item__c where Id in '+
                '(select Item__c from MRP__c where Level__c=:nextLevel and Is_Demand__c=true)  limit 200'; //and Company__c=:companyId
                
        Id jobId=Database.executeBatch(obj);
        
        test.stopTest();
        
        system.assert(jobId!=null);
    }
}