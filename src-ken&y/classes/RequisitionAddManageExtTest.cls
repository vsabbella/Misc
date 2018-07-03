@isTest
public class RequisitionAddManageExtTest {

		public class ReqData{

		TestFuel Fuel = new TestFuel();

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
            contract.Currency__c = TestFuel.currencyUSD.id;
	        insert contract;
        }
        
        Contract_Line__c contractLine1 = new Contract_Line__c();{
	        contractLine1.Contract__c = contract.Id;
	        contractLine1.Company__c = fuel.company.Id;
	        // Contract line`s Purchase UOM will be populated from item`s uom
	        contractLine1.Item__c = fuel.itemlist[1].id; // item has uom
	        contractLine1.Name = 'Test CTL 1';
	        contractLine1.Contract_Start__c = Date.today().addDays(-1);
	        contractLine1.Contract_End__c = Date.today().addDays(4);
	        contractLine1.Status__c = 'Open';
	        contractLine1.Negotiated_Price__c = 10;
	        contractLine1.Contract_Quantity__c = 1000;
	        contractLine1.Type__c = 'Fixed';
	        contractLine1.Consigned__c = true;
	        contractLine1.Purchased_Quantity__c = 0;
	        contractLine1.Quantity_Received__c = 0;
	        contractLine1.Quantity_Still_Due__c = 0;
	        contractLine1.Quantity_Returned__c = 0;
	        insert contractLine1;
        }
        
        Requisition__c req = new Requisition__c();{
        	req.Company__c = fuel.company.id;
            req.Supplier__c = fuel.supplier.id;
        	req.Source__c = 'Online';
        	req.Type__c = 'Purchase Requisition';
        	req.Status__c = 'Open';
        	req.Approval_Status__c = 'Pending Authorization';
            req.Currency__c = TestFuel.currencyUSD.id;
        	insert req;
        }
        Requisition__c dropshipReq = new Requisition__c();{
        	dropshipReq.Company__c = fuel.company.id;
        	dropshipReq.Source__c = 'Drop Ship';
        	dropshipReq.Type__c = 'Purchase Requisition';
        	dropshipReq.Status__c = 'Closed';
        	dropshipReq.Approval_Status__c = 'Approved';
            dropshipReq.Currency__c = TestFuel.currencyUSD.id;
        	insert dropshipReq;
        }
        Requisition_Line__c dropshipReqLine = new Requisition_Line__c();{
        	dropshipReqLine.Item__c = fuel.itemlist[0].id;
        	dropshipReqLine.Facility__c = fuel.facility.id;
        	dropshipReqLine.Quantity_Ordered__c = 100;
        	dropshipReqLine.Unit_Price__c = 1;
        	dropshipReqLine.Need_Date__c = system.today();
        	dropshipReqLine.Requisition__c = dropshipReq.id;
        	dropshipReqLine.Status__c = 'Closed';	
            dropshipReqLine.Quantity_Released__c = 100;
            dropshipReqLine.Approved__c = true;	
        	insert dropshipReqLine;
        }
        Requisition_Line__c reqLine = new Requisition_Line__c();{
        	reqLine.Item__c = fuel.itemlist[1].id;
        	reqLine.Purchasing_UOM__c = fuel.uomList[8].id;//KNDY-10903
        	reqLine.Facility__c = fuel.facility.id;
        	reqLine.Quantity_Ordered__c = 100;
        	reqLine.Unit_Price__c = 1;
        	reqLine.Need_Date__c = system.today();
        	reqLine.Requisition__c = req.id;
        	reqLine.Status__c = 'Open';	
            reqLine.Quantity_Released__c = 0;
            reqLine.Approved__c = false;	
        	insert reqLine;
        }
        Requisition_Line__c rline = new Requisition_Line__c();{
         	rline.Item__c = fuel.itemlist[0].id;
         	rline.Facility__c = fuel.facility.id;
       	    rline.Quantity_Ordered__c = 10;
         	rline.Unit_Price__c = 1;
         	rline.Need_Date__c = system.today();
         	rline.Requisition__c = req.id;
         	rline.Status__c = 'Open';	
            rline.Quantity_Released__c = 0;
            rline.Approved__c = false;	
         	insert rline;
        }

        
        GridRelatedListController.GridRelatedListConfig requisitionLinesConfig = new GridRelatedListController.GridRelatedListConfig();{
	        requisitionLinesConfig.uniqueId = 'RequisitionLinesGrid';
	        requisitionLinesConfig.title = 'Requisition Lines';
	        requisitionLinesConfig.parentRecord = req;
	        requisitionLinesConfig.objectName = 'Requisition_Line__c';  
	        requisitionLinesConfig.parentField = 'Requisition__c';
	        requisitionLinesConfig.fieldset = 'Requisition_Line';
	        requisitionLinesConfig.buttons = 'create, delete, clone, columnmenu, search';
    	}

	}

	static testMethod void dummyTestForCoverage(){

		ReqData data = new ReqData();
		ApexPages.StandardController setCon = new Apexpages.StandardController(data.req); 
		RequisitionAddManageExt req2po = new RequisitionAddManageExt(setCon);
		req2po.getCustomViews();
		req2po.getCustomViewFields();
		req2po.getRequisitionHeaderFieldList();
		req2po.getRequisitionAddlHeaderFieldList();
		req2po.getRequisitionLinesFieldList();
		req2po.getReturnUrl();
		req2po.getRequisitionJson();
        req2po.getDeleteURL();
		req2po.getRequisitionLinesConfigJson();
		RequisitionAddManageExt.getRequisitionDetails(data.req.id);
		RequisitionAddManageExt.getRequisitionLines (data.requisitionLinesConfig, (List<String>) JSON.deserialize(req2po.getAllFields(), List<String>.class));

        List< Requisition_Line__c > reqList = new List< Requisition_Line__c >();
        List<String> dateFields = new List<String>();
        {
			dateFields.add('Need_Date__c');
        }
        List<String> parentRecord = new List<String>();
        {
			parentRecord.add(JSON.serialize(data.req));
        }
        RequisitionAddManageExt.saveAction(data.req, parentRecord, reqList, reqList, reqList, dateFields);
	}

	static testMethod void addReqLines(){

		ReqData data = new ReqData();
		ApexPages.StandardController setCon = new Apexpages.StandardController(data.req); 
		RequisitionAddManageExt req = new RequisitionAddManageExt(setCon);
 		JSONResult result = new JSONResult();

        List< Requisition_Line__c > addreqList = new List< Requisition_Line__c >();
        List< Requisition_Line__c > updreqList = new List< Requisition_Line__c >();
        List< Requisition_Line__c > delreqList = new List< Requisition_Line__c >();

        Requisition_Line__c reqLine1 = new Requisition_Line__c();{
        	reqLine1.Item__c = data.fuel.itemlist[0].id;
        	reqLine1.Facility__c = data.fuel.facility.id;
        	reqLine1.Quantity_Ordered__c = 100;
        	reqLine1.Unit_Price__c = 1;
        	reqLine1.Purchasing_UOM__c = data.fuel.uomList[8].id; //KNDY-10903
        	reqLine1.Need_Date__c = system.today();
        	reqLine1.Status__c = 'Open';	
        }
        addreqList.add(reqLine1);

        Requisition_Line__c reqLine2 = new Requisition_Line__c();{
        	reqLine2.Item__c = null;
            reqLine2.Requester_Notes__c = 'Mac Book Pro';
        	reqLine2.Facility__c = data.fuel.facility.id;
        	reqLine2.Quantity_Ordered__c = 10;
        	reqLine2.Unit_Price__c = 1000;
        	reqLine2.Purchasing_UOM__c = data.fuel.uomList[8].id; //KNDY-10903
        	reqLine2.Need_Date__c = system.today() + 15;
        	reqLine2.Status__c = 'Open';	
        }
        addreqList.add(reqLine2);

        data.reqLine.Quantity_Ordered__c = 200;
        update data.reqLine;
        updreqList.add(data.reqLine);

        List<String> dateFields = new List<String>();
        {
			dateFields.add('Need_Date__c');
        }
        List<String> parentRecord = new List<String>();
        {
			parentRecord.add(JSON.serialize(data.req));
        }
        result = RequisitionAddManageExt.saveAction(data.req, parentRecord, updreqList, addreqList, delreqList, dateFields);
        system.assertEquals(result.success, true);

        //Verify that the line is inserted along with the existing line
        List<Requisition_Line__c> reqLines = [select id, name, Approved__c, Supplier__c, Status__c from Requisition_Line__c where Requisition__c = :data.req.id];
        system.assertEquals(reqLines.size(), 4); 
        for(Requisition_Line__c rl : reqLines){
            if (rl.id == reqLine1.id){
                system.assertEquals(rl.Supplier__c, data.req.Supplier__c); 
            }
        }   

        //verify if the Approved is false for both the lines as the requisition is yet to be approved
        system.assertEquals(data.req.Approval_Status__c, 'Pending Authorization');
        for (Requisition_Line__c reqLine : reqLines){
        	system.assertEquals(reqLine.Approved__c, false);
        }

        //Update the approval status to Approved and check if all lines are now approved
        data.req.Approval_Status__c = 'Approved';
        update data.req;
        reqLines = [select id, name, Approved__c, Status__c from Requisition_Line__c where Requisition__c = :data.req.id];
        for (Requisition_Line__c reqLine : reqLines){
        	system.assertEquals(reqLine.Approved__c, true);
        }

	}

    //PTP-689 Test Requisition status on Approval
    static testMethod void testReqStatusonApproval(){

        ReqData data = new ReqData();
        Requisition__c req = new Requisition__c();{
            req.Company__c = data.fuel.company.id;
            req.Source__c = 'Online';
            req.Type__c = 'Purchase Requisition';
            req.Status__c = 'Draft';
            req.Approval_Status__c = 'Pending Authorization';
            req.Currency__c = TestFuel.currencyUSD.id;
            insert req;
        }

        req.Approval_Status__c = 'Approved';
        update req;

        req = [select id, name, Status__c, Approval_Status__c from Requisition__c where id = :req.id];
        system.assertEquals(req.Status__c, 'Open');
    }

    //PTP-690 Flip header approval status
    static testMethod void testFlipApprovalStatus_headerchange(){

        ReqData data = new ReqData();
        data.req.Approval_Status__c = 'Approved';
        update data.req;

        data.req.FOB_Term__c = data.fuel.fobTerm.id;
        update data.req;

        Requisition__c req = [select id, name, Status__c, Approval_Status__c from Requisition__c where id = :data.req.id];
        system.assertEquals(req.Approval_Status__c, 'Pending Authorization');

    }

    //PTP-690 Flip Line approval status
    static testMethod void testFlipApprovalStatus_linechange(){

        ReqData data = new ReqData();
        data.req.Approval_Status__c = 'Approved';
        update data.req;

        //Check header approval status on req line updates
        data.reqLine.Quantity_Ordered__c = 110;
        update data.reqLine;

        Requisition__c req = [select id, name, Status__c, Approval_Status__c from Requisition__c where id = :data.req.id];
        system.assertEquals(req.Approval_Status__c, 'Pending Authorization');

        //check line approval status on req line inserts
        data.req.Approval_Status__c = 'Approved';
        update data.req;

        Requisition_Line__c reqLine1 = new Requisition_Line__c();{
            reqLine1.Item__c = data.fuel.itemlist[0].id;
            reqLine1.Facility__c = data.fuel.facility.id;
            reqLine1.Quantity_Ordered__c = 100;
            reqLine1.Unit_Price__c = 1;
            reqLine1.Need_Date__c = system.today();
            reqLine1.Requisition__c = data.req.id;
            reqLine1.Purchasing_UOM__c = data.fuel.uomList[8].id;//KNDY-10903
            reqLine1.Status__c = 'Open'; 
            insert reqLine1;
        }

        req = [select id, name, Status__c, Approval_Status__c from Requisition__c where id = :data.req.id];
        system.assertEquals(req.Approval_Status__c, 'Pending Authorization');

    }

    //KNDY-7602 Actions Drop down - Cancel Lines
    static testMethod void testReqLinesCancel(){

        ReqData data = new ReqData();
        data.req.Approval_Status__c = 'Approved';
        update data.req;

        Requisition_Line__c rl = [select id, name, Status__c, Quantity_Released__c, Requisition__r.Id, Requisition__r.Source__c, Approved__c from Requisition_Line__c where id = :data.reqLine.id];
        system.assertEquals(rl.Status__c, 'Open');
        system.assertEquals(rl.Approved__c, true);
        system.assertEquals(rl.Quantity_Released__c, 0);

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.cancelLines(new List<Requisition_Line__c>{rl});
        system.assertEquals(result.success, true);

        rl = [select id, name, Status__c, Quantity_Released__c, Approved__c from Requisition_Line__c where id = :data.reqLine.id];
        system.assertEquals(rl.Status__c, 'Cancelled');
        Test.stopTest();

    }

    //KNDY-7602 Actions Drop down - Close Lines
    static testMethod void testReqLinesClose(){

        ReqData data = new ReqData();
        data.req.Approval_Status__c = 'Approved';
        update data.req;

        Requisition_Line__c rl = [select id, name, Status__c, Quantity_Released__c, Approved__c from Requisition_Line__c where id = :data.reqLine.id];
        system.assertEquals(rl.Status__c, 'Open');
        system.assertEquals(rl.Approved__c, true);
        system.assertEquals(rl.Quantity_Released__c, 0);

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.closeLines(new List<Requisition_Line__c>{rl});
        system.assertEquals(result.success, true);

        rl = [select id, name, Status__c, Quantity_Released__c, Approved__c from Requisition_Line__c where id = :data.reqLine.id];
        system.assertEquals(rl.Status__c, 'Closed');
        Test.stopTest();

    }

    //KNDY-7602 Actions Drop down - Close Lines
    static testMethod void testReqLinesCloseCancelFailure(){

        ReqData data = new ReqData();

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.cancelLines(new List<Requisition_Line__c>{data.reqLine});
        system.assertEquals(result.success, false);

        result = RequisitionAddManageExt.closeLines(new List<Requisition_Line__c>{data.reqLine});
        system.assertEquals(result.success, false);

        Test.stopTest();

    }

    //KNDY-7602 Actions Drop down - Header cancel
    static testMethod void testReqHeaderCancel(){

        ReqData data = new ReqData();

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.approve(data.req.id);
        system.assertEquals(result.success, true);

        result = RequisitionAddManageExt.cancel(data.req.id);
        system.assertEquals(result.success, true);
        Requisition_Line__c rline = [select id, status__c, Requisition__c from Requisition_Line__c where Requisition__c =:data.req.id LIMIT 1];
        system.assertEquals(rline.Status__c, 'Cancelled');

        Test.stopTest();

    }

    //KNDY-7602 Actions Drop down - Header close
    static testMethod void testReqHeaderClose(){

        ReqData data = new ReqData();

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.approve(data.req.id);
        system.assertEquals(result.success, true);

        result = RequisitionAddManageExt.close(data.req.id);
        system.assertEquals(result.success, true);

        Test.stopTest();

    }
    
    //KNDY-7604 Actions Drop down - Delete
    static testMethod void testReqDelete(){

        ReqData data = new ReqData();

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.deletereq(data.req.id);
        system.assertEquals(result.success, true);

        Test.stopTest();

    }

    //KNDY-7603 Actions Drop down - Clone
    static testMethod void testReqClone(){

        ReqData data = new ReqData();

        Test.startTest();
        JSONResult result = RequisitionAddManageExt.clone(data.req.id);
        system.assertEquals(result.success, true);

        Test.stopTest();

    }
    
     //KNDY-10873 Do not allow cloning of Drop ship Requisition
     static testMethod void testDropShipReqClone(){
     	ReqData data = new ReqData();
     	Test.startTest();
     	try{
     		JSONResult result = RequisitionAddManageExt.clone(data.dropshipReq.id);	
     		system.assertEquals(result.success, false);
     	}catch(Exception e){
     		system.assertEquals(e.getMessage().contains(label.Cannot_clone_a_Drop_Ship_Requisition), true);
     	}
     }
     
     //KNDY-10515 Flip Requisiton status to cancelled with all cancelled lines
    static testMethod void testReqStatusCancelwithLinesCancelled(){
    	
    	ReqData data = new ReqData();
        data.req.Approval_Status__c = 'Approved';
        update data.req; 
        
        List<Requisition_Line__c> rl = [select id, name, Status__c, Approved__c, Quantity_Released__c, Requisition__r.Id, Requisition__r.Source__c from Requisition_Line__c where Requisition__c = :data.req.id LIMIT 2]; 
        system.assertEquals(rl[0].Status__c, 'Open');
        system.assertEquals(rl[0].Approved__c, true);
        
        Test.startTest();
        
        JSONResult result = RequisitionAddManageExt.cancelLines(new List<Requisition_Line__c>{rl[0]});
        JSONResult result1 = RequisitionAddManageExt.cancelLines(new List<Requisition_Line__c>{rl[1]});
        
        List<Requisition_Line__c>reqLines = [select id, name, Status__c, Approved__c from Requisition_Line__c where Requisition__c = :data.req.id ];
        system.assertEquals(reqLines[0].Status__c, 'Cancelled');
        system.assertEquals(reqLines[1].Status__c, 'Cancelled');
        
        Requisition__c requisition =[select id, name, status__c from Requisition__c where id = :data.req.id Limit 1];
        system.assertEquals(requisition.Status__c, 'Cancelled'); 
        Test.stopTest();
      
    }
    //KNDY-10640 Flip Requisition status to closed with combination of closed cancelled lines
    static testMethod void testReqStatusClosewithClosedCancelledLines(){
    	
    	ReqData data = new ReqData();
    	data.req.Approval_Status__c = 'Approved';
    	update data.req;
    
        List<Requisition_Line__c> rl = [select id, name, Status__c, Approved__c, Quantity_Released__c, Requisition__c, Requisition__r.Id, Requisition__r.Source__c from Requisition_Line__c where Requisition__c = :data.req.id LIMIT 2]; 
        
        Test.startTest();
        
        JSONResult result = RequisitionAddManageExt.closeLines(new List<Requisition_Line__c>{rl[0]});
        JSONResult result1 = RequisitionAddManageExt.cancelLines(new List<Requisition_Line__c>{rl[1]});
        
        Requisition__c requisition =[select id, name, status__c from Requisition__c where id = :data.req.id Limit 1];
        system.assertEquals(requisition.Status__c, 'Closed');
        
        Test.stopTest();
        
    }

}