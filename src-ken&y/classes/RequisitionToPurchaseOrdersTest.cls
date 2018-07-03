@isTest
public class RequisitionToPurchaseOrdersTest{

	public class ReqToPOData{

		TestFuel Fuel = new TestFuel();

		Map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');

		Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = fuel.terms.Id;
            supplier.Status__c = 'Active';
        	supplier.Type__c = 'Purchasing';
        	supplier.RecordTypeId = rtMap.get('Purchase_From');
        	supplier.Remit_To__c =  fuel.remittosupplier.id;
            supplier.Currency__c = TestFuel.currencyUSD.ID;
            insert supplier;
        }

		Contract__c contract = new Contract__c();{
	        contract.Name = 'TestContract';
	        contract.Contract_Start__c = Date.today().addDays(-1);
	        contract.Contract_End__c = Date.today().addDays(4);
	        contract.OwnerID = System.Userinfo.getUserId();
	        contract.Status__c = 'Open';
	        contract.Supplier__c = fuel.supplier.id;
	        contract.Company__c = fuel.company.Id;
	        contract.FOB_Term__c = fuel.fobTerm.id;
	        contract.Payment_Term__c = fuel.terms.id;
	        contract.Ship_to_Facility__c = fuel.facility.Id;
	        contract.Transportation_Mode__c = 'RAIL';
            contract.Currency__c = TestFuel.currencyUSD.ID;
	        insert contract;
        }
        
        Contract_Line__c contractLine1 = new Contract_Line__c();{
	        contractLine1.Contract__c = contract.Id;
	        contractLine1.Contract__r = contract;
	        contractLine1.Company__c = fuel.company.Id;
	        contractLine1.Item__c = fuel.itemlist[0].id;
	        contractLine1.Purchase_UOM__c = fuel.uomList[8].Id; //KNDY-10904
	        contractLine1.Name = 'Test CTL 1';
	        contractLine1.Contract_Start__c = Date.today().addDays(-1);
	        contractLine1.Contract_End__c = Date.today().addDays(4);
	        contractLine1.Status__c = 'Open';
            contractLine1.Approved__c = true;
	        contractLine1.Negotiated_Price__c = 10;
	        contractLine1.Contract_Quantity__c = 1000;
	        contractLine1.Type__c = 'Fixed';
	        contractLine1.Consigned__c = false;
	        contractLine1.Purchased_Quantity__c = 0;
	        contractLine1.Quantity_Received__c = 0;
	        contractLine1.Quantity_Still_Due__c = 0;
	        contractLine1.Quantity_Returned__c = 0;
	        insert contractLine1;
        }
        
        Requisition__c req = new Requisition__c();{
        	req.Company__c = fuel.company.id;
        	req.Source__c = 'Drop Ship';
        	req.Type__c = 'Purchase Requisition';
        	req.Status__c = 'Open';
        	req.Approval_Status__c = 'Approved';
            req.Sales_Order__c = Fuel.salesOrder.id;
            req.Currency__c = TestFuel.currencyUSD.ID;
        }
        List<Requisition__c> reqList = new List<Requisition__c>();{
        	reqList.add(req);
        	insert reqList;
        }
        
        Requisition_Line__c reqLine = new Requisition_Line__c();{
        	reqLine.Item__c = fuel.itemlist[0].id;
        	reqLine.Purchasing_UOM__c = fuel.uomList[8].Id; //KNDY-10904
        	reqLine.Facility__c = fuel.facility.id;
        	reqLine.Quantity_Ordered__c = 100;
        	reqLine.Unit_Price__c = 1;
        	reqLine.Need_Date__c = system.today();
        	reqLine.Requisition__c = req.id;
        	reqLine.Status__c = 'Open';	
            reqLine.Approved__c = true;
            reqLine.Default_Purchase_Agreement_Line__c = contractLine1.id;
        }
        List<Requisition_Line__c> reqLineList = new List<Requisition_Line__c>();{
        	reqLineList.add(reqLine);
        	insert reqLineList;
        }

	}

	static testMethod void dummyTestForCoverage(){

		ReqToPOData data = new ReqToPOData();
		data.contract.Approval_Status__c = 'Approved';
		update data.contract;
		ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
		RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
		RequisitionToPurchaseOrdersExt.releaseReqLines(data.fuel.company.Id, data.fuel.facility.Id, data.reqLineList);
        req2po.getReqLinesFieldList();
        req2po.getReqLinesConfigJson();
        req2po.getPOLinesFieldList();
        req2po.getPOLinesConfigJson();

	}
    static testMethod void testCancelReqLine(){
        ReqToPOData data = new ReqToPOData();
        ApexPages.StandardController con = new Apexpages.StandardController(data.req);
        RequisitionAddManageExt reqManage = new RequisitionAddManageExt(con);
        JSONResult result = new JSONResult();
        result = RequisitionAddManageExt.cancel(data.req.Id);
        Boolean ErrorExists = false;
        for(Map<String,String> msg : result.messages){
            if(msg.get('message').contains('Cannot cancel a Drop Ship/Back to Back line'))
                ErrorExists = true;
        }
        system.assertEquals(true, ErrorExists, result.messages );
    }

	static testMethod void createPOfromReq(){

		ReqToPOData data = new ReqToPOData();
		data.contract.Approval_Status__c = 'Approved';
		update data.contract;
		JsonResult result = new JsonResult();
		ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
		RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
		Test.startTest();
		data.fuel.facility.Default_Purchasing_Delivery_Location__c = data.fuel.location.id;
        update data.fuel.facility;
        system.debug('data.fuel.facility.Default_Purchasing_Delivery_Location__c--->>'+data.fuel.facility.Default_Purchasing_Delivery_Location__c);
		RequisitionToPurchaseOrdersExt.releaseReqLines(data.fuel.company.Id, data.fuel.facility.Id, data.reqLineList);
		Purchase_Order_Line__c poLine = [select id, name, Order_Quantity__c, Purchase_Order__r.Type__c from Purchase_Order_Line__c where Contract_Line__c = :data.contractLine1.id];
		system.assertEquals(poLine.Order_Quantity__c, data.reqLine.Quantity_Ordered__c); //Check if a PO has been created
		result = RequisitionToPurchaseOrdersExt.getPOLines(data.reqLineList);
		system.assertEquals(result.success, true);
		system.assertEquals(result.total,1); //Verify if 1 po line rec is created
		Test.stopTest();
	}
	
    private static List<KendoUtils.FilterDescriptor> getReqFilterCriteria(String compId, String facId, String reqId, String soId){

        List<KendoUtils.FilterDescriptor> fCriteria = new List<KendoUtils.FilterDescriptor>();

        //KendoUtils.FilterDescriptor cFilter = new KendoUtils.FilterDescriptor();
        //cFilter.field = 'Requisition__r.Company__c';
        //cFilter.fieldType = 'string';
        //cFilter.operator = 'eq';
        //cFilter.value = compId;
        //fCriteria.add(cFilter);

        //KendoUtils.FilterDescriptor fFilter = new KendoUtils.FilterDescriptor();
        //fFilter.field = 'Facility__c';
        //fFilter.fieldType = 'string';
        //fFilter.operator = 'eq';
        //fFilter.value = facId;
        //fCriteria.add(fFilter);


        KendoUtils.FilterDescriptor reqSourceFilter = new KendoUtils.FilterDescriptor();
        reqSourceFilter.field = 'Requisition__r.Source__c';
        reqSourceFilter.fieldType = 'string';
        reqSourceFilter.operator = 'eq';
        reqSourceFilter.value = 'Drop Ship';
        fCriteria.add(reqSourceFilter);


        KendoUtils.FilterDescriptor reqTypeFilter = new KendoUtils.FilterDescriptor();
        reqTypeFilter.field = 'Requisition__r.Type__c';
        reqTypeFilter.fieldType = 'string';
        reqTypeFilter.operator = 'eq';
        reqTypeFilter.value = 'Purchase Requisition';
        fCriteria.add(reqTypeFilter);


        KendoUtils.FilterDescriptor reqFilter = new KendoUtils.FilterDescriptor();
        reqFilter.field = 'Requisition__c';
        reqFilter.fieldType = 'string';
        reqFilter.operator = 'eq';
        reqFilter.value = reqId;
        fCriteria.add(reqFilter);


        //KendoUtils.FilterDescriptor reqSoFilter = new KendoUtils.FilterDescriptor();
        //reqSoFilter.field = 'Requisition__r.Sales_Order__c';
        //reqSoFilter.fieldType = 'string';
        //reqSoFilter.operator = 'eq';
        //reqSoFilter.value = soId;
        //fCriteria.add(reqSoFilter);

        return fCriteria;
    }

    static testMethod void createPOfromReqOnSoCredHold(){

        ReqToPOData data = new ReqToPOData();
        data.contract.Approval_Status__c = 'Approved';

        //data.contractLine1.Approved__c = true;
        //update data.contractLine1;

        data.fuel.salesOrder.Credit_Hold__c = true;
        data.fuel.salesOrder.Override_Credit_Hold__c = false;
        update data.fuel.salesOrder;

        update data.contract;
        JsonResult result = new JsonResult();
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
        RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
        Test.startTest();
        data.fuel.facility.Default_Purchasing_Delivery_Location__c = data.fuel.location.id;
        update data.fuel.facility;
        system.debug(logginglevel.ERROR, 'data.fuel.facility.Default_Purchasing_Delivery_Location__c--->>'+data.fuel.facility.Default_Purchasing_Delivery_Location__c);

        List<KendoUtils.FilterDescriptor> reqFilterCriteria = getReqFilterCriteria(''+data.fuel.company.id, ''+data.fuel.facility.id, ''+data.req.id, ''+data.fuel.salesOrder.id);
        //RequisitionToPurchaseOrdersExt.releaseReqLines(data.fuel.company.Id, data.fuel.facility.Id, data.reqLineList);
        result = RequisitionToPurchaseOrdersExt.releaseReqLines_manual((List<RequisitionService.RequisitionLineWrapper>)RequisitionToPurchaseOrdersExt.getreqWrapperLines((List<Requisition_Line__c>)RequisitionToPurchaseOrdersExt.getreqLines(reqFilterCriteria, req2po.ReqLinesConfig, data.reqLine).records).records);

        List<Purchase_Order_Line__c> poLines = [select id, name, Order_Quantity__c, Purchase_Order__r.Type__c from Purchase_Order_Line__c where Contract_Line__c = :data.contractLine1.id];
        system.assertEquals(poLines.size(), 0, 'PO lines should not have been be generated');
        
        Test.stopTest();
    }

    static testMethod void createPOfromReqOnSoCredHoldOverride(){

        ReqToPOData data = new ReqToPOData();
        data.contract.Approval_Status__c = 'Approved';

        data.fuel.salesOrder.Credit_Hold__c = true;
        data.fuel.salesOrder.Override_Credit_Hold__c = true;
        update data.fuel.salesOrder;

        update data.contract;
        JsonResult result = new JsonResult();
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
        RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
        Test.startTest();
        data.fuel.facility.Default_Purchasing_Delivery_Location__c = data.fuel.location.id;
        update data.fuel.facility;
        system.debug(logginglevel.ERROR, 'data.fuel.facility.Default_Purchasing_Delivery_Location__c--->>'+data.fuel.facility.Default_Purchasing_Delivery_Location__c);

        List<KendoUtils.FilterDescriptor> reqFilterCriteria = getReqFilterCriteria(''+data.fuel.company.id, ''+data.fuel.facility.id, ''+data.req.id, ''+data.fuel.salesOrder.id);

        result = RequisitionToPurchaseOrdersExt.releaseReqLines_manual((List<RequisitionService.RequisitionLineWrapper>)RequisitionToPurchaseOrdersExt.getreqWrapperLines((List<Requisition_Line__c>)RequisitionToPurchaseOrdersExt.getreqLines(reqFilterCriteria, req2po.ReqLinesConfig, data.reqLine).records).records);

        List<Purchase_Order_Line__c> poLines = [select id, name, Order_Quantity__c, Purchase_Order__r.Type__c from Purchase_Order_Line__c where Contract_Line__c = :data.contractLine1.id];
        system.assertEquals(poLines.size(), 1, 'PO lines should have been be generated');
        Purchase_Order_Line__c poLine = poLines[0];
        system.assertEquals(poLine.Order_Quantity__c, data.reqLine.Quantity_Ordered__c); //Check if a PO has been created
        result = RequisitionToPurchaseOrdersExt.getPOLines(data.reqLineList);
        system.assertEquals(result.success, true);
        system.assertEquals(result.total,1); //Verify if 1 po line rec is created
        Test.stopTest();
    }

    public class ReqToPONoAGRData{

        TestFuel Fuel = new TestFuel();
        
        public void getDateFields(List<String> headerDateFields, List<String> lineDateFields){
            headerDateFields = new List<String>();
            lineDateFields = new List<String>{'Need_Date__c','Promised_Date__c','Latest_Promise_Date__c'};
        }

        Map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');

        Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = fuel.terms.Id;
            supplier.Status__c = 'Active';
            supplier.Type__c = 'Purchasing';
            supplier.RecordTypeId = rtMap.get('Purchase_From');
            supplier.Remit_To__c =  fuel.remittosupplier.id;
            supplier.Currency__c = TestFuel.currencyUSD.ID;
            insert supplier;
        }
        
        Requisition__c dsreq = new Requisition__c();{
            dsreq.Company__c = fuel.company.id;
            dsreq.Source__c = 'Drop Ship';
            dsreq.Type__c = 'Purchase Requisition';
            dsreq.Status__c = 'Open';
            dsreq.Approval_Status__c = 'Approved';
            dsreq.Currency__c = TestFuel.currencyUSD.ID;
        }
        
        Requisition__c req = new Requisition__c();{
            req.Company__c = fuel.company.id;
            req.Source__c = 'Online';
            req.Type__c = 'Purchase Requisition';
            req.Status__c = 'Open';
            req.Approval_Status__c = 'Approved';
            req.Currency__c = TestFuel.currencyUSD.ID;
        }
        
        List<Requisition__c> reqList = new List<Requisition__c>();{
            reqList.add(req);
            insert reqList;
        }
        
        List<Requisition__c> reqListwithDS = new List<Requisition__c>();{
			reqListwithDS.add(dsreq);
            insert reqListwithDS;
        }
        
        Requisition_Line__c reqLine = new Requisition_Line__c();{
            reqLine.Item__c = fuel.itemlist[0].id;
            reqLine.Purchasing_UOM__c = fuel.uomList[8].Id; 
            reqLine.Facility__c = fuel.facility.id;
            reqLine.Delivery_Location__c = fuel.location.id;
            reqLine.Quantity_Ordered__c = 100;
            reqLine.Unit_Price__c = 1;
            reqLine.Need_Date__c = system.today();
            reqLine.Requisition__c = req.id;
            reqLine.Status__c = 'Open'; 
        }
        
        Requisition_Line__c reqLinenoItem = new Requisition_Line__c();{
            reqLinenoItem.Item__c = null;
            reqLinenoItem.Requester_Notes__c = 'Apple Air2 Notebook with i9 Processor';
            //reqLine.Purchasing_UOM__c = fuel.uomList[8].Id; 
            reqLinenoItem.Facility__c = fuel.facility.id;
            reqLinenoItem.Delivery_Location__c = fuel.location.id;
            reqLinenoItem.Quantity_Ordered__c = 10;
            reqLinenoItem.Unit_Price__c = 1000;
            reqLinenoItem.Need_Date__c = system.today()+30;
            reqLinenoItem.Requisition__c = req.id;
            reqLinenoItem.Status__c = 'Open'; 
        }
        
        List<Requisition_Line__c> reqLineList = new List<Requisition_Line__c>();{
            reqLineList.add(reqLine);
            reqLineList.add(reqLinenoItem);
            insert reqLineList;
        }
        
        Requisition_Line__c dsreqLine = new Requisition_Line__c();{
            dsreqLine.Item__c = fuel.itemlist[0].id;
            dsreqLine.Purchasing_UOM__c = fuel.uomList[8].Id; 
            dsreqLine.Facility__c = fuel.facility.id;
            dsreqLine.Delivery_Location__c = fuel.location.id;
            dsreqLine.Quantity_Ordered__c = 100;
            dsreqLine.Unit_Price__c = 1;
            dsreqLine.Need_Date__c = system.today();
            dsreqLine.Requisition__c = dsreq.id;
            dsreqLine.Status__c = 'Open'; 
        }
        
        List<Requisition_Line__c> reqLineListwithDS = new List<Requisition_Line__c>();{
            reqLineListwithDS.add(dsreqLine);
            insert reqLineListwithDS;
        }

    }
	
	static testMethod void createPOfromReqWithoutPA(){

        ReqToPONoAGRData data = new ReqToPONoAGRData();
        
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = data.fuel.company.id;
        po.Supplier__c = data.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Currency__c = TestFuel.currencyUSD.ID;
        
        JsonResult result = new JsonResult();
        
        Test.startTest();
        String reqIds = null;
        List<String> reqIdsList = new  List<String>();
        
        for(Requisition_Line__c  rql : data.reqLineList){
            reqIdsList.add(rql.Id);
        }
        reqIds = JSON.serialize(reqIdsList);
      
        ApexPages.StandardController setConPO = new Apexpages.StandardController(po);
        PurchaseOrderManageExt ext = new PurchaseOrderManageExt(setConPO);
        result = PurchaseOrderManageExt.createPOLines(reqIds);
		system.assertEquals(result.success, true);
        system.assert(result.records.size() == 2); 
        
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        data.getDateFields(headerDateFields, dateFields);
        
        //empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
         
        List<PurchaseOrderManageExt.POLineWrapper> polWrapperList = (List<PurchaseOrderManageExt.POLineWrapper>)result.records;
        for(PurchaseOrderManageExt.POLineWrapper polWrapper : polWrapperList){
            if(polWrapper.poline.Item__c == null && polWrapper.poline.Requestor_Notes__c != null){
                polWrapper.poline.Item__c = data.fuel.itemList[1].Id;
            }
        }
        newList.addAll(polWrapperList);

        JsonResult result1 = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        System.debug(logginglevel.info,result1.messages); 
        system.assertEquals(result1.success,true);
        system.assert(result1.records.size() == 1); 
        
        Purchase_Order__c pOrder = [Select Id, Acknowledge_Via__c, Open_Purchase_Order_Lines__c, Currency__c from Purchase_Order__c
                                     where Id = :po.Id];
        System.debug(logginglevel.info,pOrder.Id);
        system.assert(pOrder.Id <> null); 
        system.assert(pOrder.Open_Purchase_Order_Lines__c == 2);

        List<Purchase_Order_Line__c> poLineList = [select id, name, Order_Quantity__c, Purchase_Order__r.Type__c from Purchase_Order_Line__c where Purchase_Order__c = :pOrder.Id];
        system.assertEquals(poLineList[0].Order_Quantity__c, data.reqLineList[0].Quantity_Ordered__c); //Check if POL has been created 
        system.assertEquals(poLineList[1].Order_Quantity__c, data.reqLineList[1].Quantity_Ordered__c);
 		Test.stopTest();
    }
    
    static testMethod void dropshipReqWithoutPA_failureTest(){

        ReqToPONoAGRData data = new ReqToPONoAGRData();
        
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = data.fuel.company.id;
        po.Supplier__c = data.fuel.supplier.id;
        po.Type__c  = 'Drop Ship';
        po.Currency__c = TestFuel.currencyUSD.ID;
        
        JsonResult result = new JsonResult();
        
        Test.startTest();
        String reqIds = null;
        List<String> reqIdsList = new  List<String>();
        
        for(Requisition_Line__c  rql : data.reqLineList){
            reqIdsList.add(rql.Id);
        }
        
        for(Requisition_Line__c  rql : data.reqLineListwithDS){
            reqIdsList.add(rql.Id);
        }
        reqIds = JSON.serialize(reqIdsList);
      
        ApexPages.StandardController setConPO = new Apexpages.StandardController(po);
        PurchaseOrderManageExt ext = new PurchaseOrderManageExt(setConPO);
        result = PurchaseOrderManageExt.createPOLines(reqIds);
        system.assertEquals(result.success, true);
        system.assertEquals(result.records.size(), 3); //We enabled the flow of Req to PO without PA for DS
        
        Test.stopTest();
    }
            
	//PTP-578 
	static testMethod void checkReqReleasewithnoAgreement(){

		ReqToPOData data = new ReqToPOData();
		JsonResult result = new JsonResult();
		data.fuel.facility.Default_Purchasing_Delivery_Location__c = data.fuel.location.id;
        update data.fuel.facility;
		ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
		RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
		Test.startTest();
		result = RequisitionToPurchaseOrdersExt.releaseReqLines(data.fuel.company.Id, data.fuel.facility.Id, data.reqLineList);
		system.assertEquals(result.success, false); //No approved agreements are available, so release should fail
		Test.stopTest();

	}
	
	static testMethod void checkReqReleasewithnoDefaultLocation(){

		ReqToPOData data = new ReqToPOData();
		JsonResult result = new JsonResult();
		ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
		RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
		Test.startTest();
		result = RequisitionToPurchaseOrdersExt.releaseReqLines(data.fuel.company.Id, data.fuel.facility.Id, data.reqLineList);
		system.assertEquals(result.success, false); //No default location specified on the Facility, so release should fail
		Test.stopTest();

	}
	

	//KNDY-8788: Manual Req Release
	static testMethod void checkReqRelease_manual(){

		ReqToPOData data = new ReqToPOData();
		data.contract.Approval_Status__c = 'Approved';
		update data.contract;
		
		data.fuel.facility.Default_Purchasing_Delivery_Location__c = data.fuel.location.id;
        update data.fuel.facility;
        

		JsonResult result = new JsonResult();
		ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(data.reqList); 
		RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);

		List<RequisitionService.RequisitionLineWrapper> reqWrapperList = new List<RequisitionService.RequisitionLineWrapper>();
		for (Requisition_Line__c rl : data.reqLineList){
			RequisitionService.RequisitionLineWrapper r = new RequisitionService.RequisitionLineWrapper();
			r.reqLine = rl;
			r.itemID = rl.Item__c;
			r.ctLine = data.contractLine1;
			reqWrapperList.add(r);			
         }
		Test.startTest();
		result = RequisitionToPurchaseOrdersExt.releaseReqLines_manual(reqWrapperList);
		system.assertEquals(result.success, true); //Result should be success

		Test.stopTest();

	}
	
	
}