@isTest
private class PurchaseAgreementCloneExtTest {

    class PurchaseAgreementTestData{
		public TestFuel fuel = new TestFuel();
		
		//Create a GL Type
        public GL_Type__c testGLT = new GL_Type__c();{
	    	testGLT.Name  = 'Current Assets';
			testGLT.Normal_Balance__c  = 'Debit';
			testGLT.Accounting_Type__c  = 'Assets';
			testGLT.Statement_Type__c  = 'Balance Sheet';
			testGLT.Account_Range_From__c = '10000';
			testGLT.Account_Range_To__c ='14999';
			insert testGLT;
        }
        
    	//Create a GL Account
        public GL_Account__c glaccount = new GL_Account__c();{
            
            glaccount.Name = 'testglaccount';
            glaccount.GL_Account_Number__c = '10000';
            glaccount.GL_Account_Name__c = 'Current Assets';
            glaccount.GL_Type__c = testGLT.id;
            glaccount.Active__c = true;
            insert glaccount;
        }
        
        public segment_validation__c segval = new segment_validation__c();{
            segval.segment_1__c = '*';
            segval.segment_2__c = '*';
            segval.active__c = true;
            insert segval;
        }
        
        //Create payment terms info
        public Payment_Term__c paymentTermInfo = new Payment_Term__c();{
        	paymentTermInfo.Name = '2/10 Net 30';
        	paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
        	paymentTermInfo.Discount_Days__c = 10;
        	paymentTermInfo.Discount_Percent__c = 2.0;
        	paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        
        public FOB_Terms__c fobTerms = new FOB_Terms__c();{
        	fobTerms.name = 'FOB Term 1';
        	insert fobTerms;
        }
        User_Preference__c up = new User_Preference__c();{
			up.Default_Company__c = fuel.company.id;
			up.ownerID = userinfo.getUserID();
			up.Default_Facility__c = fuel.facility.Id;
        	insert up;
        }
        public map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        //Create Supplier, assign remit and payment terms info
        public Supplier__c remittosupplier = new Supplier__c();{
            remittosupplier.Name = 'Test Remit To';
            remittosupplier.Payment_Term__c = paymentTermInfo.Id;
            remittosupplier.Status__c = 'Active';
        	remittosupplier.Type__c = 'Remit-To';
        	remittosupplier.RecordTypeId = rtMap.get('Remit_To');
            insert remittosupplier;
        }
        
        public Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = paymentTermInfo.Id;
            supplier.Status__c = 'Active';
        	supplier.Type__c = 'Purchasing';
        	supplier.RecordTypeId = rtMap.get('Purchase_From');
        	supplier.Remit_To__c =  remittosupplier.id;
            insert supplier;
        }
        
        public Class__c miscClass = new Class__c();{
            
            miscClass.Name = 'Class Misc';
            miscClass.Type__c = 'Miscellaneous';
            insert miscClass;
        }
        
        public Class__c regClass = new Class__c();{
            
            regClass.Name = 'Class Reg';
            regClass.Type__c = 'Services';
            insert regClass;
        }
        
        //Create an item
        
            Item__c item = new Item__c();{
            item.Name = 'testitem';
            item.Active__c = true;
            item.Class__c = regClass.id;
            item.Source__c = 'Services';
            item.Company__c = fuel.company.Id;
            insert item;    
            }
            
            Item__c item2 = new Item__c();{
            item2.Name = 'testitemmisc';
            item2.Active__c = true;
            item.Class__c = miscClass.id;
            item2.Company__c = fuel.company.Id;
            item2.Source__c = 'Miscellaneous';
            item2.Non_Inventory__c = true;
            insert item2;
            }
        
       //Contract
        Contract__c contract = new Contract__c();{
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Supplier__c = supplier.id;
        contract.Company__c = fuel.company.Id;
        contract.Amount_Tolerance__c = 100;
        contract.Quantity_Tolerance_Over__c = 20;
        //contract.Quantity_Tolerance_Under__c = 5;
        contract.Unit_Price_Tolerance_Over__c = 20;
        //contract.Unit_Price_Tolerance_Under__c = 5;
        insert contract;
        }
        
        //Contract Item that is active
        Contract_Line__c contractLine1 = new Contract_Line__c();{
        contractLine1.Contract__c = contract.Id;
        contractLine1.Company__c = fuel.company.Id;
        contractLine1.Item__c = item.id;
        contractLine1.Purchase_UOM__c = fuel.uomInch.id;
        contractLine1.Name = 'Test CTL 1';
        contractLine1.Contract_Start__c = Date.today().addDays(-1);
        contractLine1.Contract_End__c = Date.today().addDays(4);
        contractLine1.Status__c = 'Active';
        contractLine1.Negotiated_Price__c = 10;
        contractLine1.Contract_Quantity__c = 100;
        contractLine1.Type__c = 'Fixed';
        contractLine1.Line__c =1;
        insert contractLine1;
        }
        //Contract Item that is active
        Contract_Line__c contractLine2 = new Contract_Line__c();{
        contractLine2.Contract__c = contract.Id;
        contractLine2.Company__c = fuel.company.Id;
        contractLine2.Item__c = item2.id;
        contractLine2.Purchase_UOM__c = fuel.uomInch.id;
        contractLine2.Name = 'Test CTL 2';
        contractLine2.Contract_Start__c = Date.today().addDays(-1);
        contractLine2.Contract_End__c = Date.today().addDays(4);
        contractLine2.Status__c = 'Active';
        contractLine2.Negotiated_Price__c = 10;
        contractLine2.Contract_Quantity__c = 100;
        contractLine2.Type__c = 'Fixed';
        contractLine2.Line__c =2;
        insert contractLine2;
        }
        List< Contract_Line__c > clList = new List< Contract_Line__c >();
    	{ 
    		clList.add( contractLine1 );
    		clList.add( contractLine2 );
    		
    	}
    }
    
    // Simply clone an existing purchase agreement which should result in 2 agreements in the system
    public static testMethod void happyPathScenario() {
    	PurchaseAgreementTestData paTestData = new PurchaseAgreementTestData();
    	Test.startTest();
    	system.assert( [select id from Contract__c].size() == 1 );
        PurchaseAgreementCloneExt poc = new PurchaseAgreementCloneExt(new Apexpages.Standardcontroller(paTestData.contract) );
        Pagereference p0 = poc.Save();
        system.assert(p0!=null,apexpages.getmessages());
        String url = p0.getUrl();
        
        url = url.replaceAll('/','');
        system.assert( [select id from Contract__c where id = :url limit 1].size() == 1 ); 
        system.assert( [select id from Contract__c].size() == 2 ); 
        
     	
    }
    
    //PTP-306 Clone a PA and then run through ASL Validations. No ASL reqd so PA moves to Open status
    public static testMethod void cloneRunASLValidationsPass() { 
    	PurchaseAgreementTestData paTestData = new PurchaseAgreementTestData();
    	Test.startTest();
    	system.assert( [select id from Contract__c].size() == 1 );
        system.debug('Original PA record: ' + paTestData.contract);
        PurchaseAgreementCloneExt poc = new PurchaseAgreementCloneExt(new Apexpages.Standardcontroller(paTestData.contract) );
        Pagereference p0 = poc.Save();
        system.assert(p0!=null,apexpages.getmessages());
        String url = p0.getUrl();
        
        url = url.replaceAll('/','');
        system.assert( [select id from Contract__c where id = :url limit 1].size() == 1 ); 
        system.assert( [select id from Contract__c].size() == 2 ); 
        
     	Contract__c clonedPA = [select id, Name, Status__c from Contract__c where Id != :paTestData.contract.id];
     	system.assert(clonedPA.Status__c == 'Draft', 'Cloned PA status not Draft, rather is: ' + clonedPA.Status__c);
     	system.debug('Cloned PA record: ' + clonedPA);
     	List<Contract_Line__c> clonedPALines = [Select id, Name, Status__c, Line__c, ASL_Override__c, CPC_Code__c from Contract_Line__c where Contract__c = :clonedPA.id];
     	for (Contract_Line__c clonedPALine: clonedPALines){
     		system.assert(clonedPALine.Status__c == 'Draft', ' Cloned PA line status: ' + clonedPALine.Status__c);
     		system.assert(clonedPALine.ASL_Override__c == false, ' Cloned PA line ASL_Override__c: ' + clonedPALine.ASL_Override__c);
     		system.assert(clonedPALine.CPC_Code__c == null, ' Cloned PA line CPC_Code__c: ' + clonedPALine.CPC_Code__c);
     		system.debug('ClonedPA Line: ' + clonedPALine.Line__c);	
     	}
     	clonedPA.Status__c = 'Open';
     	update clonedPA;
     	
     	clonedPA = [select id, Name, Status__c from Contract__c where Id != :paTestData.contract.id];
     	system.assert(clonedPA.Status__c == 'Open', 'Cloned PA status not Open, rather is: ' + clonedPA.Status__c);
     	system.debug('Cloned PA record: ' + clonedPA);
     	clonedPALines = [Select id, Name, Status__c from Contract_Line__c where Contract__c = :clonedPA.id];
     	for (Contract_Line__c clonedPALine: clonedPALines){
     		system.assert(clonedPALine.Status__c == 'Open', ' Cloned PA line status: ' + clonedPALine.Status__c);	
     	}
     	
    }
    
    //PTP-306 Clone a PA and then run through ASL Validations. ASL fails and PA remains at Draft status
    public static testMethod void cloneRunASLValidationsFail() { 
    	PurchaseAgreementTestData paTestData = new PurchaseAgreementTestData();
    	
    	//setting up data needed
        paTestData.item.Approved_Supplier_Required__c = true;
        update paTestData.item;
        paTestData.item2.Approved_Supplier_Required__c = true;
        update paTestData.item2;
        
        Item_Cross_Reference__c itemCrossRef = new Item_Cross_Reference__c();{
        	itemCrossRef.Name = 'Test';
        	itemCrossRef.Active__c = true;
        	itemCrossRef.Approval_Status__c = 'Approved';
        	itemCrossRef.Consigned__c = true;
        	itemCrossRef.Item__c = paTestData.item.id;
        	itemCrossRef.Supplier__c = paTestData.supplier.id;
        	itemCrossRef.Cross_Reference_Type__c = 'Supplier';
        	itemCrossRef.Cross_Reference_Value__c = 'SI12345';
        	insert itemCrossRef;
        }
        Test.startTest();
    	system.assert( [select id from Contract__c].size() == 1 );
        system.debug('Original PA record: ' + paTestData.contract);
        PurchaseAgreementCloneExt poc = new PurchaseAgreementCloneExt(new Apexpages.Standardcontroller(paTestData.contract) );
        Pagereference p0 = poc.Save();
        system.assert(p0!=null,apexpages.getmessages());
        String url = p0.getUrl();
        
        url = url.replaceAll('/','');
        system.assert( [select id from Contract__c where id = :url limit 1].size() == 1 ); 
        system.assert( [select id from Contract__c].size() == 2 ); 
        
     	Contract__c clonedPA = [select id, Name, Status__c from Contract__c where Id != :paTestData.contract.id];
     	system.assert(clonedPA.Status__c == 'Draft', 'Cloned PA status not Draft, rather is: ' + clonedPA.Status__c);
     	List<Contract_Line__c> clonedPALines = [Select id, Name, Status__c, Line__c from Contract_Line__c where Contract__c = :clonedPA.id];
     	for (Contract_Line__c clonedPALine: clonedPALines){
     		system.assert(clonedPALine.Status__c == 'Draft', ' Cloned PA line status: ' + clonedPALine.Status__c);
     		system.debug('ClonedPA Line: ' + clonedPALine.Line__c);	
     	}
     	clonedPA.Status__c = 'Open';
     	update clonedPA;
     	
     	clonedPA = [select id, Name, Status__c from Contract__c where Id != :paTestData.contract.id];
     	system.assert(clonedPA.Status__c == 'Draft', 'Cloned PA status not Open, rather is: ' + clonedPA.Status__c);
     	clonedPALines = [Select id, Name, Status__c, Line__c, Item__c from Contract_Line__c where Contract__c = :clonedPA.id];
     	for (Contract_Line__c clonedPALine: clonedPALines){
     		if (clonedPALine.Item__c == paTestData.item.id)
     			system.assert(clonedPALine.Status__c == 'Open', ' Cloned PA line status: ' + clonedPALine.Status__c);	
     			
     		if (clonedPALine.Item__c == paTestData.item2.id)
     			system.assert(clonedPALine.Status__c == 'Draft', ' Cloned PA line status: ' + clonedPALine.Status__c);		
     	}
     	
    }
    
    //ToDo PTP-306 Need to test for mixed bag PA lines where ASL is reqd, not reqd and have ICRs set up or not

   //PTP-537 Test for the approved flag on PA lines when we clone a PA which is in Approved status.	
	public static testMethod void setApprovedflagPAclone() {
    	PurchaseAgreementTestData paTestData = new PurchaseAgreementTestData();
    	paTestData.contract.Approval_Status__c = 'Approved';
    	update paTestData.Contract;
    	List<Contract_Line__c> ctls = [select id, Name, Approved__c from Contract_Line__c where Contract__c = :paTestData.contract.id Limit 2];
    	for(Contract_Line__c ctl : ctls) {
    		system.assertEquals(ctl.Approved__c, true); 
    	} 
       	PurchaseAgreementCloneExt poc = new PurchaseAgreementCloneExt(new Apexpages.Standardcontroller(paTestData.contract) );
        Pagereference p0 = poc.Save();
        String url = p0.getUrl();
        url = url.replaceAll('/','');
        Contract__c clonedPA = [select id, Name, Status__c,Approval_Status__c from Contract__c where Id = :url];
        system.assert(clonedPA.Status__c == 'Draft', 'Cloned PA status not Draft, rather is: ' + clonedPA.Status__c);
        system.assert(clonedPA.Approval_Status__c == 'Pending Authorization', 'Cloned PA has Approval status:' + clonedPA.Approval_Status__c);
     	List<Contract_Line__c> clonedPALines = [Select id, Name, Status__c, Approved__c, Line__c from Contract_Line__c where Contract__c = :clonedPA.id];
     	for (Contract_Line__c clonedPALine: clonedPALines){
     		system.assert(clonedPALine.Status__c == 'Draft', ' Cloned PA line status: ' + clonedPALine.Status__c);
     		system.assert(clonedPALine.Approved__c == false);
     	}
        
    	
	}


}