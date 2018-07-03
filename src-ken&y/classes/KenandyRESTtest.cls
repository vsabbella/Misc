@isTest
public class KenandyRESTtest {
	

	/*
	* utility method to buid the endpoint for testing
	*/ 	
	public static String getEndpoint() {
		//get the namespace, if any, and replace the trailing __ with a /
		String nsSlash = KSE.NamespaceUU.replace('__', '/');
		
		//build relative endpoint which may or may not have namespace subdirectory in the URI
		String endpoint = '/services/apexrest/'+nsSlash+'KenandyREST';
		
		return endpoint;
	}
	
	
	
	//QA-12 - Add web services capability and global methods exposure to Purchase Order and Receiving Document objects
	public static testMethod void PurchaseOrderReceive_test() {
		
		//create the test data
		Testfuel t = new TestFuel();
		List<Period__c> periodList = t.periodList;

		Item__c item = new Item__c(
			Name = 'item',
			Description__c = 'item',
			Source__c = 'Purchased',
			Lead_Time__c = 5,
			company__c = t.company.Id,
			Active__c = true,
			Purchasing_UOM__c = t.uomList[0].Id ,
			Packaging_UOM__c = JSON.serialize(new List<Id>{ t.uomList[0].Id }),
			Stocking_UOM__c = t.uomList[0].Id
		);
		insert item;

		Purchase_Order__c po = new Purchase_Order__c(
			Company__c = t.company.Id,
			Supplier__c = t.supplier.Id,
			Remit_To_Supplier__c =  t.remittosupplier.Id,    		
			Type__c = 'Standard',
			Approval_Status__c = 'Approved',
			Currency__c = TestFuel.currencyUSD.Id
			
		);
		insert po;

		Purchase_Order_Line__c pol = new Purchase_Order_Line__c(
			Company__c = t.company.id,
			Purchase_Order__c = po.id,
			Item__c = item.id,
			Order_Quantity__c = 500,
			Unit_Price__c = 2,
			Type__c = 'Goods',
			Date_Added__c = system.today(),
			Need_Date__c = system.today(),
			Line__c = 1,
			Purchase_UOM__c = t.uomList[0].Id,
			Supplier__c = t.supplier.id,
			Delivery_Facility__c = t.facility.id,
			Delivery_Location__c = t.location.id		
		);
		insert pol;
		
		po.Approval_Status__c = 'Approved';
		update po;		

		
		//create the mock web service request data
		List<KenandyREST.poLineReceiveObj> poLineRecList = new List<KenandyREST.poLineReceiveObj>();
		KenandyREST.poLineReceiveObj polro = new KenandyREST.poLineReceiveObj();
		polro.polId = pol.Id;
		polro.receiveQuantity = 100;
		polro.putAwayLocationId = t.location.id;
		poLineRecList.add(polro);
		
		Map<String, Object> bodyMap = new Map<String, Object>();
		bodyMap.put('poId', po.Id);
		bodyMap.put('poLineRecList', poLineRecList);
		
		Map<String, Object> requestMap = new Map<String, Object>();
		requestMap.put('method', 'PurchaseOrderReceive');
		requestMap.put('body', bodyMap);

		//serialize the whole object that contains the method we are calling
		//and all the paramaeters we are passing
		String sRequest = JSON.serialize(requestMap);

		
		//test the rest service
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
		req.requestURI = getEndpoint();
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueof(sRequest);
		RestContext.request = req;
		RestContext.response = res;
	
		String sResponse = KenandyREST.doPost();
		
		//system.debug('***sResponse: ' + sResponse);
		
		system.assertEquals('success', sResponse);
		
		//requery the POL and make sure the quantity was received
		pol = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id=:pol.Id];
		system.assertEquals(100, pol.Quantity_Received__c, 'Expected Quantity Received to be 100');
		
	 }
	
	
	public static testMethod void testMRPPlan(){
		
		TestData data=new TestData();
        
        Id calID = [select Id from BusinessHours where isDefault = true limit 1].Id;
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
        
        List<Id> itemIdList = new List<Id>();
        for(Item__c item : [SELECT Id FROM Item__c]){
        	itemIdList.add(item.Id);
        }
        system.assert(itemIdList.size() > 0);
        string itemIds = string.join(itemIdList, ',');
        
        Map<String, Object> bodyMap = new Map<String, Object>();
		bodyMap.put('level', 1);
		bodyMap.put('itemIds', itemIds);
		bodyMap.put('mrpRunId', mrpRun.Id);
		bodyMap.put('receivingCalendarId', calId);
		bodyMap.put('planningCalendarId', calId);
		
		Map<String, Object> requestMap = new Map<String, Object>();
		requestMap.put('method', 'MRPPlanData');
		requestMap.put('body', bodyMap);

		//serialize the whole object that contains the method we are calling
		//and all the paramaeters we are passing
		String sRequest = JSON.serialize(requestMap);

		
		//test the rest service
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
		req.requestURI = getEndpoint();
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueof(sRequest);
		RestContext.request = req;
		RestContext.response = res;
	
		String sResponse = KenandyREST.doPost();
		
		//system.debug('***sResponse: ' + sResponse);
		
		system.assertEquals('success', sResponse);
        
        test.stopTest();
        
		
	
	}
	
	public static testMethod void testMRPPlanFacility(){
	 	
	 	TestData data=new TestData();
        
        Id calID = [select Id from BusinessHours where isDefault = true limit 1].Id;
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
        
        List<Id> itemIdList = new List<Id>();
        for(Item__c item : [SELECT Id FROM Item__c]){
        	itemIdList.add(item.Id);
        }
        system.assert(itemIdList.size() > 0);
        string itemIds = string.join(itemIdList, ',');
        
        Map<String, Object> bodyMap = new Map<String, Object>();
		bodyMap.put('level', 1);
		bodyMap.put('itemIds', itemIds);
		bodyMap.put('mrpRunId', mrpRun.Id);
		bodyMap.put('receivingCalendarId', calId);
		bodyMap.put('planningCalendarId', calId);
		
		Map<String, Object> requestMap = new Map<String, Object>();
		requestMap.put('method', 'MRPPlanData');
		requestMap.put('body', bodyMap);

		//serialize the whole object that contains the method we are calling
		//and all the paramaeters we are passing
		String sRequest = JSON.serialize(requestMap);

		
		//test the rest service
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
		req.requestURI = getEndpoint();
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueof(sRequest);
		RestContext.request = req;
		RestContext.response = res;
	
		String sResponse = KenandyREST.doPost();
		
		//system.debug('***sResponse: ' + sResponse);
		
		system.assertEquals('success', sResponse);
        
        test.stopTest();
	}
}