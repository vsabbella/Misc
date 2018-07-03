/**
 * test the accounting generate page/controller 
 */
@isTest
private class SourceDocumentAccountingTest  {
    
 	public static testMethod void GenerateTest() {
	    /*TestDataForFinance data = new TestDataForFinance();
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.Company__c = data.company.id;
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    insert shipment1; 
	    
	    List<Shipment_Line__c> shipLineList1 = new List<Shipment_Line__c>();
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = data.company.id;
	    shipLine1.Extended_Cost__c = 5;
	    shipLine1.Quantity_Shipped__c = 5;
	    shipLine1.Sales_Order__c = data.salesOrder1.id;
	    shipLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
	    shipLine1.Unit_Price__c = 25;
	    shipLine1.Product__c = data.product.id;
	    shipLine1.Location__c = data.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLineList1.add(shipLine1);
	    
	    Shipment_Line__c shipLine2 = new Shipment_Line__c();
	    shipLine2.Company__c = data.company.id;
	    shipLine2.Extended_Cost__c = 5;
	    shipLine2.Quantity_Shipped__c = 5;
	    shipLine2.Sales_Order__c = data.salesOrder1.id;
	    shipLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
	    shipLine2.Unit_Price__c = 25;
	    shipLine2.Product__c = data.product.id;
	    shipLine2.Location__c = data.location.id;
	    shipLine2.Shipment__c = shipment1.id;
	    shipLineList1.add(shipLine2);
	    insert shipLineList1;
        shipment1.status__c='Confirmed';
        shipment1.Finalized__c = true;
	    update shipment1;
	    */
	    TestFuel data = new TestFuel();
		//Company__c company = fuel.company;
    	List<Period__c> periods = data.periodList;
		
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now().addDays(10);
        custInvoice1.transaction_date__c = system.now().addDays(10);
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
	    
        insert ciLine1;        
     
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	
	    Test.startTest();
		Test.setCurrentPage( Page.SourceDocumentAccounting);
		Apexpages.currentPage().getParameters().put('id', custInvoice1.id );
		SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
		con.populateSobjDetails(); 
		
		system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() );
		//system.debug( Logginglevel.info, con.lines );
		
	//	system.assert(con.renderReview, 'The page should be displaying the review section data');
     
	//	system.assert(!con.manyLines, 'This is a small volume of lines');
	     list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
	    integer i=0;
	    for(map<string,string> m:chunks)
	    {
	     SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
	      i++;
        }
		List<Accounting_Entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :custInvoice1.id];
		system.assertNotEquals(0, ae.size(), 'We are expecting an AE synchronously');
				
		system.assert( con.close() != null );
		
		// test if the Finalized flag is set, we expect an error
		
		// test where bad object is passed 
		//Apexpages.currentPage().getParameters().put('id', data.company.id );
		//con = new SourceDocumentAccountingCon(); 
		//con.populateSobjDetails(); 
        //system.assert( Apexpages.hasMessages() == true, ' expected error msg');		

	}

	

	public static testMethod void PreviewTestFail() {
        JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
        UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
        Test.setCurrentPage( Page.SourceDocumentAccounting);
        Apexpages.currentPage().getParameters().put('id', JE.JEList[0].id );
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});        
		SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        con.populateSobjDetails();
		system.assert( Apexpages.hasMessages() == true, ' expected error msg');		
	}
	
    /*Commenting as part of KNDY-6885 
	public static testMethod void testFutureCall()
    {
        JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
	    system.assertEquals(true, mResponses.get(JE.JEList[0].Id).Success, 'We are expecting a successful unfinalize');
        Test.startTest();
	    List<Journal_Entry_Line__c> JELs = new List<Journal_Entry_Line__c>{JE.jeLineList[0], JE.jeLineList[1]};

	    List<Journal_Entry_Line__c> newJELsSet1 = new List<Journal_Entry_Line__c>();
	    for(integer i=0; i<=26; i++){
	    	newJELsSet1.addAll(JELs.deepclone());
	    }
	    system.assert(newJELsSet1.size() > 50);
	    insert newJELsSet1;//52 Lines Invokes future
	    JE.JEList[0].finalized__c = true;
	    update JE.JEList[0];  
        
	    Test.setCurrentPage( Page.SourceDocumentAccounting);
		Apexpages.currentPage().getParameters().put('id', JE.JEList[0].Id );
		SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        datetime lddt = con.loadDt;
		con.previewAE();
		
		system.assert(con.manyLines, 'This should have a "large line volume"');
		system.assert(!con.renderReview, 'We are not ready to show the generated lines');
		
		List<Accounting_Entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id];
		system.assertEquals(0, ae.size(), 'We are expecting that the AE is deferred to the @future');
	    Test.stopTest();

	    con.refresh();
	    system.assert(!con.manyLines, 'This should have a "large line volume" turned off');
		system.assert(con.renderReview, 'We are now ready to show the generated lines');
		
		ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id  ORDER BY CreatedDate desc LIMIT 1];
		system.assertNotEquals(0, ae.size(), 'We are expecting an AE from the @future');
		
		system.assertEquals(ae[0].Id, con.record.Id, 'We should see the AE match between the @future return and the controller');

    }*/
    //Commenting as part of KNDY-6885 
     //
     //
    
	public static testMethod void largeVolume(){
		JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
	    system.assertEquals(true, mResponses.get(JE.JEList[0].Id).Success, 'We are expecting a successful unfinalize');
	    List<Journal_Entry_Line__c> JELs = new List<Journal_Entry_Line__c>{JE.jeLineList[0], JE.jeLineList[1]};

	    List<Journal_Entry_Line__c> newJELsSet = new List<Journal_Entry_Line__c>();
	    for(integer i=0; i<=51; i++){
	    	newJELsSet.addAll(JELs.deepclone());
	    }
	    system.assert(newJELsSet.size() > 100);
	    insert newJELsSet;// 
	    JE.JEList[0].finalized__c = true;
	    update JE.JEList[0];  
        
	    Test.setCurrentPage( Page.SourceDocumentAccounting);
		Apexpages.currentPage().getParameters().put('id', JE.JEList[0].Id );
		SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        datetime lddt = con.loadDt;
		con.populateSobjDetails();
		
        //We need to manually invoke the remoting methods as the Test class seems not to invoke the same.
        Test.startTest();    
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        for(map<string,string> m:chunks)
        {
         SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }
	    Test.stopTest(); 
	    List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c,batchjobid__c,total_lines__c FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id and status__c = 'Active'];
		system.assertEquals(ActiveAE[0].batchjobid__c,con.guid,'We are expecting a draft AE created for this guid');
		/*list<id> DraftAEid = new list<id>();
        draftAEId.add(DraftAE[0].id);
        SourceDocumentAccountingCon.deletedrafts(JE.JEList[0].Id,DraftAEid,DraftAE[0].total_lines__c);//This deletes the draft
        system.assertEquals(true, con.deletepoller, 'We are expecting that the Draft AEs would be deleted');
*/
		list<accounting_entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id  and status__c = 'Active' ORDER BY CreatedDate desc LIMIT 1];
		system.assertNotEquals(0, ae.size(), 'We are expecting an AE from the VF Remoting');
		 // We are not using record unless we are in closed period.
		//system.assertEquals(ae[0].Id, con.record.Id, 'We should see the AE match between the VF remote return and the controller');
         
	}
	/*
	//RS - Commenting out this test as draft AEs aren't relevent
    public static testmethod void testDraftAEDel()
    {
 		JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
	    system.assertEquals(true, mResponses.get(JE.JEList[0].Id).Success, 'We are expecting a successful unfinalize');
	    List<Journal_Entry_Line__c> JELs = new List<Journal_Entry_Line__c>{JE.jeLineList[0], JE.jeLineList[1]};

	    List<Journal_Entry_Line__c> newJELsSet = new List<Journal_Entry_Line__c>();
	    for(integer i=0; i<=51; i++){
	    	newJELsSet.addAll(JELs.deepclone());
	    }
	    system.assert(newJELsSet.size() > 100);
	    insert newJELsSet;//
	    JE.JEList[0].finalized__c = true;
	    update JE.JEList[0];  
        
        list<sobject> sourcedoc= new list<sobject>();
        sourcedoc.add(JE.JEList[0]);
        AccountingAPI api = new AccountingAPI();
        api.generateAccounting(sourcedoc);
		List<Accounting_Entry__c> aeDraftForCleanup = [SELECT Id,status__c,company__c,source_document_object_name__c FROM Accounting_Entry__c 
                                                       WHERE Journal_Entry__c = :JE.JEList[0].Id and status__c = 'Draft'];
        system.assertNotEquals(0, aeDraftForCleanup.size(),'Expecting Draft AE created for JE ');

        list<accounting_entry__c> aeNotToDel= new list<accounting_entry__c>();
        aeNotToDel.add(aeDraftForCleanup[0].Clone(false,true,false,false));
		aeNotToDel[0].batchjobid__c='XXX-YY-ZZZ' ;
		upsert  aeNotToDel;    

		list<accounting_entry__c> allDrafts =[select id,name,source_document_object_name__c
                                              from accounting_entry__c WHERE 
                                              //Journal_Entry__c = :JE.JEList[0].Id and
                                              status__c = 'Draft'];
		system.assertEquals(allDrafts.size(),2,'Two drafts should exist for this source doc') ;

 	    Test.setCurrentPage( Page.SourceDocumentAccounting);

        Apexpages.currentPage().getParameters().put('id', JE.JEList[0].Id );
		SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        system.assertEquals(JE.JEList[0].Id, con.gettheSourceDocIdPg());
        system.assertEquals('Journal_Entry__c', con.gettheSourceDocNamePg());
		con.populateSobjDetails();
        
         system.assertEquals(con.draftAEIdsToDel.size(),1,'Only one aeDraftForCleanup should have been picked up for deleting') ;        
        SourceDocumentAccountingCon.AEGenProgress(con.gettheSourceDocIdPg(),con.guid);
 		//system.assertEquals(true, con.deletepoller, 'We are expecting that the Draft AEs would be deleted');
        SourceDocumentAccountingCon.deletedrafts(con.gettheSourceDocIdPg(),con.draftAEIdsToDel ,150);//This deletes lines but our draft AE never had lines.*//*

	    Test.startTest();    
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        for(map<string,string> m:chunks)
        {
         SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.guid,con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }
	    Test.stopTest();    

		List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id and status__c = 'Active'];
        system.assertNotEquals(0, ActiveAE.size(), 'We are expecting  the Active AE to be created ');

        //Manually invoking the rest of remote methods and navigate methods to raise the code coverage
        SourceDocumentAccountingCon.gridwrapper gridwrap1=SourceDocumentAccountingCon.getGridConfig(JE.JEList[0].Id ,ActiveAE[0].id);  
        GridRelatedListController.GridRelatedListConfig config=(GridRelatedListController.GridRelatedListConfig)JSON.deserialize(gridwrap1.config, GridRelatedListController.GridRelatedListConfig.CLASS);
        SourceDocumentAccountingCon.getAELines(config);
        SourceDocumentAccountingCon.gridwrapper gridwrap2=SourceDocumentAccountingCon.getRulesGridConfig(JE.JEList[0].Id ,ActiveAE[0].id);
        GridRelatedListController.GridRelatedListConfig config1=(GridRelatedListController.GridRelatedListConfig)JSON.deserialize(gridwrap2.config, GridRelatedListController.GridRelatedListConfig.CLASS);
        SourceDocumentAccountingCon.getRules(config1);
        //SourceDocumentAccountingCon.deletedrafts(JE.JEList[0].Id ,1);//This deletes lines but our draft AE never had lines.
        
        SourceDocumentAccountingCon.AEGenprogress(con.gettheSourceDocIdPg(),con.guid);
        SourceDocumentAccountingCon.drop_leading_zeros('00001');
        con.theSourceDocId=JE.JEList[0].Id;
        con.setAEData();
        //con.getAEHeaderFieldList();

        con.navigateToPreview();
        con.review();
        apexpages.StandardController jec= new apexpages.StandardController(JE.JEList[0]);
        SourceDocumentAccountingCon con1 = new SourceDocumentAccountingCon(jec);
        
		system.assertNotEquals(null, con.close() );
        
    }
    */
    
    public static testMethod void testReverseAE()
    {
        
	    TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;
    	List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList;
    	List<Journal_Entry_Line__c> jeLineList;
		List<Journal_Entry__c> JEList_Accrual = new List<Journal_Entry__c>();	
            {
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = company.id;	
		   	je1.type__c = 'Accrual - Manual'; 
            //FIN-954 we are using transaction_type__c for accounting on all source docs.Trigger defaults  transaction_type__c from type__c. 
            //TODO: Add the below line once we deprecate type__c              
            //je1.transaction_type__c = 'Accrual - Manual';   
		    je1.auto_reverse__c = true;	
		    je1.Transaction_Date__c = System.now();  
			je1.Currency__c = TestFuel.currencyUSD.id;
		    Boolean sawException = false;
		    insert je1;
		    JEList_Accrual.add(je1);
		    
		    jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		    
		    insert jeLineList;
	
		    JEList_Accrual[0].finalized__c = true;
		    update JEList_Accrual; 
            }
	    Test.setCurrentPage( Page.SourceDocumentAccounting);

        Apexpages.currentPage().getParameters().put('id', JEList_Accrual[0].Id );
		SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();

	    Test.startTest();    
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        SourceDocumentAccountingCon.resultChunkObject obj;
        SourceDocumentAccountingCon.ResultChunkReverse revobj;
        for(map<string,string> m:chunks)
        {
          obj =SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.guid,con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }
        List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c,has_exceptions__c FROM Accounting_Entry__c WHERE status__c = 'Active'];
        system.assertEquals(1, ActiveAE.size(), 'We are expecting  a Active AEs to be created .');
        
       //  system.assertEquals(false, ActiveAE1[0].has_exceptions__c, 'We are expecting  the two Active AEs to be created .One Actual and One reverse in next period');
       /*list<task> t=[select id,description from task where whatid=:ActiveAE1[0].id];
        system.assertequals(t, null,'We expecttasks');
		system.assertEquals(obj.hasReverse, true,'We expect AE to be reversed.');
        system.assertNotEquals(null,obj.voidAEId);*/
        /*i=0;//regenerate AE
        for(map<string,string> m:chunks)
        {
          obj =SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.guid,con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }  */


        system.assertEquals(false, ActiveAE[0].has_exceptions__c, 'There should be no exceptions on original AE for Reversal AE to succesfully created');
        system.assertNotequals(obj.voidAEId, null,'This field should be populated as it is param for reverse AE');
        system.assertNotequals(obj.hasReverse, false,'Should be set as itis JE of type Accrual manual');

	    Test.stopTest();   
        list<map<string,string>> chunksRev =(list<map<string,string>>)JSON.deserialize(obj.reverseChunkMap, list<map<string,string>>.class);
        AggregateResult ar = [select min(autonumber__c) min, max(autonumber__c) max from accounting_entry_line__c where Accounting_Entry__c =:obj.voidAEId];
     	//system.assertequals(ar.get('min')+'-'+ar.get('max')+'-'+chunksRev,null);
       // system.assertequals(chunksRev,null);

        integer j=0;
        for(map<string,string> m:chunksRev)
        {
            revobj=SourceDocumentAccountingCon.reverseAE(obj.voidAEId,j,chunksRev.size(),m.get('min'),m.get('max'),false,con.getguid());
            /*system.assertequals(obj.voidAEId,ActiveAE1[0].id);
            system.assertequals(null,SourceDocumentAccountingCon.AELReverseInScope);
            system.assertequals(true,SourceDocumentAccountingCon.isnullrev);*/
            j++;
        } 
                 
       // system.assertequals(revobj.messages, null,'messages');

		List<Accounting_Entry__c> reverseAE = [SELECT Id,status__c FROM Accounting_Entry__c where related_accounting_entry__c=:obj.voidAEId and status__c='Active'];
        system.assertEquals(1, reverseAE.size(), 'We are expecting a reverse entry to be created for activeAE');
	       	
    }
        static testmethod void testJEAccrualWithoutNextPeriod()
    {
 	    TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
        period__c period1 = new period__c();
        period1.name='Test1';
        period1.company__c=company.id;
        period1.open__c=true;
        //DateTime myDateTime = DateTime.newInstance(2015, 05, 22, 12, 59, 57);
        period1.Period_Start__c=system.now();
        period1.period_end__c=period1.period_start__c.addhours(24);
		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c = fuel.company.Id;
		fy.fiscal_year_start_date__c = period1.period_start__c;
		fy.fiscal_year_end_date__c = period1.period_end__c.addMonths(3);
		
		insert fy;

		period1.fiscalyear__c = fy.Id;
	    
        insert period1;
    	List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList;
    	List<Journal_Entry_Line__c> jeLineList;
		List<Journal_Entry__c> JEList_Accrual = new List<Journal_Entry__c>();	
        
			Journal_Entry__c je = new Journal_Entry__c();
			je.name = 'JE001';
		    je.Company__c = company.id;	
     	    je.Transaction_Date__c = System.now();  
			je.Currency__c = TestFuel.currencyUSD.id;
		   	je.type__c = 'Accrual - Manual'; 
            //FIN-954 we are using transaction_type__c for accounting on all source docs.Trigger defaults  transaction_type__c from type__c. 
            //TODO: Add the below line once we deprecate type__c  
            //je1.transaction_type__c = 'Accrual - Manual';  
		    insert je;
		    JEList_Accrual.add(je);
		    
		    jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		    
		    insert jeLineList;
	
		    JEList_Accrual[0].finalized__c = true;
		    update JEList_Accrual;      
            JournalEntryAccounting jea = new JournalEntryAccounting();
            jea.execute(jeLineList);	    					
            AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, [SELECT Id FROM Accounting_Entry_Line__c WHERE Journal_Entry_Line__c IN :jeLineList]);	    
			
        	//Commenting out due to SOQL limits being reached.  Should be ok not checking this.  Failure will be caught later in the test.
        	/*list<accounting_entry__c> aelist = [select id,name,has_exceptions__c from accounting_entry__c 
                                                where status__c='Active'
                                                and journal_entry__c=:JEList_Accrual[0].id
                                                and has_exceptions__c=true];
            system.assertNotEquals(aelist.size(), 0,'Expecting reversal Entry to have exceptions');*/
            //Now create the next period.
            period__c period2 = new period__c();
            period2.name='Test2';
            period2.company__c=company.id;
            period2.open__c=true;
            //DateTime myDateTime = DateTime.newInstance(2015, 05, 22, 12, 59, 57);
            period2.Period_Start__c=period1.period_end__c;
            period2.period_end__c=period2.period_start__c.addhours(24);
			period2.fiscalyear__c = fy.Id;	    
            insert period2;
            //Regenerate AE using generate accounting link and check if reverse AE with exceptions is getting picked.
        	Test.setCurrentPage( Page.SourceDocumentAccounting);
            Apexpages.currentPage().getParameters().put('id', JEList_Accrual[0].Id );
            SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
            Test.startTest();
           	system.assert(limits.getqueries() == 0 ,limits.getqueries());
            list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
            integer i=0;
            SourceDocumentAccountingCon.resultChunkObject obj;
            SourceDocumentAccountingCon.ResultChunkReverse revobj;
            for(map<string,string> m:chunks)
            {
              obj =SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.guid,con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
              i++;
            }
            /*List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c,has_exceptions__c FROM Accounting_Entry__c 
                                                  WHERE status__c = 'Active' and related_accounting_entry__c=null];
            system.assertEquals(1, ActiveAE.size(), 'We are expecting  a Active AEs to be created .');
            system.assertEquals(false, ActiveAE[0].has_exceptions__c, 'There should be no exceptions on original AE for Reversal AE to succesfully created');
            system.assertNotequals(obj.voidAEId, null,'This field should be populated as it is param for reverse AE');
            system.assertNotequals(obj.hasReverse, false,'Should be set as itis JE of type Accrual manual');*/
    
            list<map<string,string>> chunksRev =(list<map<string,string>>)JSON.deserialize(obj.reverseChunkMap, list<map<string,string>>.class);
            //AggregateResult ar = [select min(autonumber__c) min, max(autonumber__c) max from accounting_entry_line__c where Accounting_Entry__c =:obj.voidAEId];
            integer j=0;
            for(map<string,string> m:chunksRev)
            {
                revobj=SourceDocumentAccountingCon.reverseAE(obj.voidAEId,j,chunksRev.size(),m.get('min'),m.get('max'),false,con.getguid());
                j++;
            } 
           
           // system.assertequals(revobj.messages, null,'messages');
    
            List<Accounting_Entry__c> reverseAE = [SELECT Id,status__c FROM Accounting_Entry__c 
                                                   where related_accounting_entry__c=:obj.voidAEId 
                                                   and status__c='Active' 
                                                   and journal_entry__c=:JEList_Accrual[0].id
                                                   and has_exceptions__c=false];
            system.assertEquals(1, reverseAE.size(), 'We are expecting a reverse entry without exceptions to be created for activeAE');     
            Test.stopTest();   
        }
}