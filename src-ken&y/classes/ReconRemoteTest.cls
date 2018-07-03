@isTest
public class ReconRemoteTest
{/*
    public static boolean isSet=false;
    
    public class AmountAggregates
    {
        decimal AELamount;
        decimal SDLamount;
    }

            
    public class ReconSetup
    {
        public TestFuel fuel = new TestFuel();
        //public TestData.Accounting accting;

        
        //Reconcile AccountsReceivable
        public reconciliation__c Recon = new reconciliation__c();
        public list<reconciliation_topic__c> TopicsList= new list<reconciliation_topic__c>();

        public Period__c ReconPeriod;
        public GL_Account__c ReconGL;
        public company__c ReconCompany;
        
        
        List<Accounting_Rule__c> AccountingRuleList = fuel.AccountingRuleList;
        public list<accounting_rule__c> RulesBookingToAR = new list<accounting_rule__c>();
        List<Accounting_Rule__c> ciAccountingRuleList = fuel.ciAccountingRuleList;
        public map<id,accounting_rule__c> mRulesBookingToAR = new map<id,accounting_rule__c>();
        public list<accounting_rule__c> rulesforJEs = new list<accounting_rule__c>();
        public list<GL_Account__c> ARGLs = new list<GL_Account__c>();
        
        
        public list<customer_invoice__c> CIList = new list<customer_invoice__c>();
        public list<customer_invoice_line__c> CIlList = new list<customer_invoice_line__c>();
        public map<id,customer_invoice__c> mCI = new map<id,customer_invoice__c>();
        public list<accounting_entry__c> aeForCI = new list<accounting_entry__c>();             
        public id JEid;
        public list<journal_entry_line__c> jelList = new list<journal_entry_line__c>();


        public purchase_order__c purchaseOrder =  new purchase_order__c(); 
        public List<Purchase_Order_Line__c> poLineList = new list<Purchase_Order_Line__c>();     
        public List<Supplier_Invoice_Line__c> suppInvLineList1 = new List<Supplier_Invoice_Line__c>();
        public Supplier_Invoice__c suppInv1;
        public Customer_Invoice__c custInv1;
        public Customer_Invoice__c custMisc;
        
        public ReconSetup()
            {
                ReconPeriod=getOpenPeriod();              
                ReconGL= fuel.receivablesGL;
                ReconCompany = fuel.company;
                system.assertNotEquals(ReconCompany,null);
                
                //TestData.Accounting accting = new TestData.Accounting(ReconCompany.id);
                
                ARGLs=[select id,name from GL_Account__c where name ='11000 - Accounts Receivable'];
                Recon.name='AccountsReceivable -reconciliation';
               // Period=[select id,name from period__c where name=:data.periodName(system.now())];
               // Comp = data.company;
                system.assertNotEquals(null,ReconPeriod,'Expecting period from testdata for current datettime');
                Recon.Period__c=reconperiod.id;
                Recon.Company__c=ReconCompany.id;
                Recon.GL_Account__c=ReconGL.id;

                
                
                rulesBookingToAR=[select id,name,Transaction__c,Subtransaction_Type__c,line_type__c from accounting_rule__C where object_name__c='Customer_Invoice__c' 
                                 and rule_type__c='DR' and accounting_standard__c =:fuel.accountingStandard.id];
                            

                system.assertNotEquals(rulesBookingToAR.size(),0,'Expecting rules booking  AccountsReceivable');
                
                system.assert(fuel.AccountingRuleList != null);
                rulesforJEs=[select id,name from accounting_rule__c where object_name__c='Journal_entry__c'];
                system.assertNotEquals(rulesforJEs.size(),0,'Expecting rules booking  JEs');
                
                mRulesBookingToAR = new map<id,accounting_rule__c>(rulesBookingToAR);
				custinv1 = fuel.custinv1;
                CILList.addall(generateCustInvoiceLines(custinv1));
                insert CILList;

		        /* list<customer_invoice_line__c> miscLines=[select id,subtransaction_type__c from customer_invoice_line__c
		        										 where customer_invoice__c=:custMisc.id];
		        for(customer_invoice_line__c cimiscl:miscLines)
		        {
		         cimiscl.subtransaction_type__c='Miscellaneous';
		         update cimiscl; 	
		         system.assertequals(cimiscl.subtransaction_type__c,'Miscellaneous','Expecting Miscellaneous');
		        	
		        }        *//*      
		        
                custInv1.Transaction_Date__c=system.now();
                custInv1.Finalized__c=true;
                CIList.add(custInv1);
                update CIList;
                
                list<customer_invoice_line__c> ciInvLines=[select id,subtransaction_type__c from customer_invoice_line__c
                										 where customer_invoice__c=:custInv1.id];
                for(customer_invoice_line__c ciInvLine:ciInvLines)
                {
                 system.assertequals(ciInvLine.subtransaction_type__c,'Goods','Expecting Goods');
                	
                }
                
                purchaseOrder = [select id,name,purchase_order_value__c from purchase_order__c where id=:fuel.purchaseOrder.id];
                POLinelist.addAll(fuel.purchaseOrderLines);
                
            
                journal_entry__c je = new journal_entry__c();
                je.name = 'JE001';
                je.Company__c = reconcompany.id;    
                je.type__c = 'Manual';   
                je.Transaction_Type__c = 'Manual';
                je.Transaction_Date__c = System.now();  
                je.Currency__c = TestFuel.currencyUSD.id;
                insert je;
                
                jelList = new list<journal_entry_line__c>();
                journal_entry_line__c jel1= new journal_entry_line__c();
                jel1.Amount_CR__c=0;
                jel1.Amount_DR__c=10;
                jel1.GL_Account__c=fuel.revenueGL.id;
                jel1.Journal_Entry__c=je.id;
                jelList.add(jel1);
                journal_entry_line__c jel2= new journal_entry_line__c();
                jel2.Amount_CR__c=10;
                jel2.Amount_DR__c=0;
                jel2.GL_Account__c=ReconGL.id; 
                jel2.Journal_Entry__c=je.id;
                jelList.add(jel2);
                insert jelList;
                //je.GL_Date_Time__c=   System.today();  
                je.Finalized__c=true;
                update je;
                JEid =je.id;
                //system.assertEquals(null,je,'Check je');
                journal_entry__c jeRec = [select id,name,period__C from journal_entry__c where id=:jeid];
                system.assertEquals(jeRec.Period__c,reconperiod.id,'JE should be created in current period');

            system.assertEquals(jelList.size(),2,'Expecting journal Line  to be created');

            system.assertNotEquals(CIList.size(),0,'Expecting customer invoice to be created');
            mCI = new map<id,customer_invoice__c>(CIList);

           system.assertNotEquals(CILList.size(),0,'Expecting customer invoice lines to be created');


        }
        public void insertRecon()
        {
           //ReconPeriod=updatePeriod();              
           insert recon;
            for(accounting_rule__c rule:rulesBookingToAR)
            {
                reconciliation_topic__c rt = new reconciliation_topic__c();
                rt.name='AR'+rule.name;
                rt.accounting_rule__c=rule.id;
                rt.Type__c='Customer Invoice';
                rt.Reconciliation__c=recon.id;
                TopicsList.add(rt);
                
            }
            insert TopicsList;
        }
        public period__c updatePeriod()
        { 
            List<Period__c> periods = fuel.periodList;
            for(Period__c thisPeriod : periods)
            {
                if(thisPeriod.open__c)
                {
                    period__c p = thisPeriod;
                    p.Open__c=false;
                    p=closePeriod(p);
                    system.assertEquals(p.Closed__c, true);
                    return p;
                }
            } 
            return null;
        }
         public period__c getOpenPeriod()
        { 
            List<Period__c> periods = fuel.periodList;
            for(Period__c thisPeriod : periods)
            {
                if(thisPeriod.open__c)
                {
                    period__c p = thisPeriod;
                    return p;
                }
            } 
            return null;
        }       
        public  period__c closePeriod(period__c periodRec)
        {
            Period__c up = [SELECT Id, ar_subledger_closed__c, ap_subledger_closed__c, fa_subledger_closed__c, Closed__c ,inventory_subledger_closed__c, shipment_subledger_closed__c, receiving_subledger_closed__c 
                            FROM Period__c WHERE Id = :periodRec.Id FOR UPDATE ];
    		PeriodService.systemEditable.add(up.Id);

            up.ar_subledger_closed__c = system.now();
            up.ap_subledger_closed__c = system.now();
            up.shipment_subledger_closed__c = system.now();
            up.receiving_subledger_closed__c = system.now();
            up.fa_subledger_closed__c = system.now();
            up.inventory_subledger_closed__c = system.now();
            up.gl_close__c = system.now();
            up.Closed__c =true;
            up.Open__c=false;
	    	update up;
            return up;
            
            /*
            Test.setCurrentPage(PeriodCloseException);
            PageReference periodCloseException = Page.periodCloseException;
            test.setCurrentPage(reconDetailRef);
            ApexPages.currentPage().getParameters().put('Id', periodRec.Id);
            ApexPages.currentPage().getParameters().put('RptSection', 'Unmatched');
            ApexPages.currentPage().getParameters().put('SDType', 'Supplier_Invoice__c');*//*
            
        }
         public list<accounting_rule__c> genCustInvoiceRules(list<string> TTSTTLTCombination,id accountingStandardId,id GLDRId,id GLCRId)
         {
         	list<accounting_rule__c> ARRulesGenerated = new list<accounting_rule__c>();
         	for(string comb:TTSTTLTCombination)
         	{
         		accounting_rule__c arCR = new accounting_rule__c();
         		list<string> ruleKeys = comb.split('\\|');
         		system.debug('ruleKeys'+ruleKeys);
         		string TT = ruleKeys[0];
          		string STT = ruleKeys[1];
          		string LT = ruleKeys[2];
          		arCR.Transaction__c=TT;
          		arCR.subtransaction_type__c=STT;
          		arCR.line_type__c=LT;
          		//arCR.company__c=companyId;
          		arCR.Accounting_Standard__c = accountingStandardId;
          		arCR.Object_Name__c = 'Customer_Invoice__c'; 
	            arCR.Default_GL_Account__c = true;
	            arCR.GL_Account_Reference_Value__c = null;
	            arCR.GL_Account__c = GLCRId;
				arCR.rule_Type__c='CR'; 	
				arCR.Effective_Start_Date__c= datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);	        			             
	            accounting_rule__c arDR =  arCR.clone(false,true,false,false);     
				arDR.rule_Type__c='DR'; 
				arDR.GL_Account__c=GLDRId; 		        		
						        		
         		ARRulesGenerated.add(arCR);
          		ARRulesGenerated.add(arDR);
         		
         	}
         	//system.assertEquals(ARRulesGenerated,null,'dEBUGGING Rules');
         	insert ARRulesGenerated;
         	
         	return ARRulesGenerated;
         }
         public  customer_invoice__c  generateMiscCI()
        {
        	customer_invoice__c miscCI= new customer_invoice__c();
            miscCI.Company__c = fuel.company.id;
            miscCI.Invoice_Type__c = 'Manual';
            miscCI.Status__c = 'Open';
            miscCI.Bill_To_Customer__c = fuel.customerBillTo.id;
            miscCI.Sold_To_Customer__c = fuel.customerSoldTo.id;    
            insert  miscCI;	
            
            item__c item5 =fuel.itemList[5];
            item5.source__c='Miscellaneous';
            update item5;
			product__c miscproduct = fuel.product2;
			product__c p=[select id,name,item__r.source__c from product__c where id=:miscproduct.id ];
			system.assertequals(p.item__r.source__c,'Miscellaneous','Expecting Miscellaneous');
			
			//insert miscproduct;
            customer_invoice_line__c cilmISC = new customer_invoice_line__C();
            CILMisc.Customer_Invoice__c=miscCI.id;
            CILMisc.Subtransaction_Type__c='Miscellaneous';
            CILMisc.Quantity_Shipped__c=2;
            CILMisc.Unit_Price__c=50.00;
            CILMisc.line_type__c='standard';
            
           // CILMisc.allowances__c=1;
            CILMisc.product__c=miscproduct.id;            
            CIlList.add(CILMisc);
            
            //make CI as finalized.
            miscCI.Transaction_Date__c=system.now();
            miscCI.Finalized__c=true;  
            
         
            return miscCI;     
        } 
        public list<customer_invoice_line__c> generateCustInvoiceLines(customer_invoice__c custInv1)
        {
        	list<customer_invoice_line__c> CIlList = new list<customer_invoice_line__c>();
	        Customer_Invoice_Line__c custInvLine11 = new Customer_Invoice_Line__c();
	        custInvLine11.Company__c = fuel.company.id;
	        custInvLine11.Quantity_Shipped__c = 2;
	        custInvLine11.Unit_Price__c = 7;
	        custInvLine11.Product__c = fuel.product.id ; 
	        custInvLine11.Customer_Invoice__c = custInv1.id;
	        custInvLine11.Subtransaction_Type__c = 'Goods';  
	        custInvLine11.Extended_Price__c = custInvLine11.Quantity_Shipped__c * custInvLine11.Unit_Price__c;
	        CIlList.add(custInvLine11);
	                
	        Customer_Invoice_Line__c custInvLine12 = new Customer_Invoice_Line__c();
	        custInvLine12.Company__c =fuel.company.id;
	        custInvLine12.Quantity_Shipped__c = 3;
	        custInvLine12.Unit_Price__c = 9;
	        custInvLine12.Product__c = fuel.product.id ; 
	        custInvLine12.Customer_Invoice__c = custInv1.id;
	        custInvLine12.Subtransaction_Type__c = 'Goods';                
	        custInvLine12.Extended_Price__c = custInvLine12.Quantity_Shipped__c * custInvLine12.Unit_Price__c;
	        CIlList.add(custInvLine12);
	        return CIlList;
        }


    }

    
    @isTest
    public static void testForUnreconciledAndManualSect()
    {

            ReconSetup reconData = new ReconSetup();
            Test.startTest();
            CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
//            system.assertEquals(limits.getqueries(), 0);
            cia.execute(reconData.CILList);
            reconData.aeForCI =[select id,name,(select id,name,accounting_rule__c,amount_DR__c,amount_CR__c,BALANCE_F__C from accounting_entry_lines__r where has_exceptions__c=false) 
                                               from accounting_entry__c 
                                               where customer_invoice__c in :reconData.mCI.keyset() 
                                               and status__c='Active'
                                               and has_exceptions__c=false];

            system.assertNotEquals(reconData.aeForCI.size(),0,'Expecting accounting entries to be created for the invoices');
            system.assertNotEquals(reconData.aeForCI[0].accounting_entry_lines__r,NULL,'Expecting accounting entry lines to be created for the invoices');

            JournalEntryAccounting jea = new JournalEntryAccounting();
            jea.execute(reconData.jelList);
            list<accounting_entry__c> manualAE =[select id,name,(select id,name from accounting_entry_lines__r where has_exceptions__c=false) 
                                                 from accounting_entry__c 
                                                 where journal_entry__c=:reconData.JEid 
                                                 and status__c='Active' 
                                                 and has_Exceptions__c=false];

            system.assertNotEquals(manualAE.size(),0,'Expecting accounting entries without exception to be created for the journal');
            system.assertNotEquals(manualAE[0].accounting_entry_lines__r.size(),0,'Expecting accounting entry lines to be created for the jounral');            

            //Get expected sum by aggregating above ael by rules
            map<id,AmountAggregates> mAmtByRule = new map<id,AmountAggregates>();
            list<aggregateresult> sumAELByRule = [select accounting_rule__c rule,sum(balance_f__c) AELamt, 
                                                  sum(customer_invoice_line__r.Extended_Price__c) SDLamt
                                                  from accounting_entry_line__c 
                                                  where accounting_entry__r.period__c=:reconData.reconperiod.id
                                                  and accounting_entry__r.source_document_object_name__c!='Journal_Entry__c'
                                                  and GL_Account__c = :reconData.ReconGL.Id
                                                  and status__c='Active'
                                                  group by accounting_rule__c];
            for(aggregateresult agg:sumAELByRule)
            {
                AmountAggregates aggTestResult = new AmountAggregates();
                aggTestResult.AELAmount=(decimal)agg.get('AELamt');
                aggTestResult.SDLAmount=(decimal)agg.get('SDLamt');
                mAmtByRule.put((id)agg.get('rule'),aggTestResult);
            }
        	ReconData.insertRecon();        
            Reconciliation__c recon = [select id,name,period__c,GL_Account__c,company__c from Reconciliation__c
                                        where id=:reconData.recon.id];

            ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);
            ReconRemoteExt reconremote = new ReconRemoteExt(stdRecon);
            reconremote.invokeRemoteCall();
            list<ReconRemoteExt.chunkResultAggregateTotalsByRule>  ChunkAggByRuleList = new list<ReconRemoteExt.chunkResultAggregateTotalsByRule>();

            for(id rule:mAmtByRule.keySet())
            {
              list<ReconRemoteExt.chunkResultAggregateTotalsByRule>  ChunkAggByRule = new list<ReconRemoteExt.chunkResultAggregateTotalsByRule>();
              ChunkAggByRule.addall(ReconRemoteExt.aggregateSDAELTotals(rule,reconData.reconperiod.id,new list<id>{reconData.ReconGL.Id}));
              ChunkAggByRuleList.addAll(ChunkAggByRule);
              if(mAmtByRule.get(rule)!=null)
              {
              	 system.assertEquals(ChunkAggByRule[0].isValid,true,'Expecting Valid result');              	
              	 system.assertEquals(ChunkAggByRule[0].isIncorrectRule,false,'Expecting no Unreconciled rules');
                 system.assertEquals(ChunkAggByRule[0].AELAmount,mAmtByRule.get(rule).AELAmount,'Expecting GL amount booked to be same');
                 system.assertEquals(ChunkAggByRule[0].SDLAmount,mAmtByRule.get(rule).SDLAmount,'Expecting Source amount booked to be same');               
              }

            }

            list<ReconRemoteExt.chunkResultAggregateTotalsBySD>  chunkAggrResultUnMatched = new list<ReconRemoteExt.chunkResultAggregateTotalsBySD>();
            chunkAggrResultUnMatched=ReconRemoteExt.getUnmatchedAELTotals(new list<id>(recondata.mRulesBookingToAR.keyset()),new list<id>{reconData.ARGLs[0].id},reconData.reconperiod.id,recon.id);
            system.assertEquals(chunkAggrResultUnMatched.size(),0,'No unreconciled entries are expected');    

            ReconRemoteExt.chunkResultAggregateTotalsBySD  chunkAggrResultManual = new ReconRemoteExt.chunkResultAggregateTotalsBySD();
            chunkAggrResultManual=ReconRemoteExt.getManualEntries(new list<id>{reconData.ARGLs[0].id},reconData.reconperiod.id,recon.id);
            //system.assertEquals(chunkAggrResultManual.message,null,'Error message' );
            Test.stopTest();


            system.assertEquals(chunkAggrResultManual.isRowsPresent,true,'Expecting  manual entry');    
            system.assertEquals(chunkAggrResultManual.AELAmount,-10,'Expecting  JEL amount 10 ');    

    

    }
    @istest
    public static void testForAccrualsAndOtherThreads()
    {
       ReconSetup reconData = new ReconSetup();
       ReconData.insertRecon();        
       Test.startTest();
       Reconciliation__c recon = [select id,name,Period__r.Period_Start__c,Period__r.Period_End__c,period__C,GL_Account__c,company__c from Reconciliation__c
                                   where id=:reconData.recon.id];
        
       ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);
       ReconRemoteExt reconremote = new ReconRemoteExt(stdRecon);
       ReconRemoteExt.updateResult updtTotals=ReconRemoteExt.updateAggregates(recondata.RulesBookingToAR[0].id,recon.id,10,10,'Reconciled','Customer_Invoice__c');
       system.assertEquals(true, updtTotals.isSuccess);
       list<reconciliation_topic__c> rt =[select id,name,Reconciliation_Section__c 
                                           from reconciliation_topic__c 
                                           where accounting_rule__c=:recondata.RulesBookingToAR[0].id
                                           and reconciliation__c=:recon.id];
       system.assertNotEquals(0,rt.size(),'Expected RECON topic for the accounts receivable account');
       system.assertequals('Reconciled',rt[0].Reconciliation_Section__c,'Expected section update to be Reconciled');
       
       ReconRemoteExt.chunkResultAggregateTotalsBySD totalsBySD =ReconRemoteExt.getAccrualCandidates(recon.id,'Customer_Invoice__c');
       ReconRemoteExt.updateSystemGenReconTopics(new list<reconciliation_topic__c>{totalsBySD.RT});
       list<reconciliation_topic__c> rtAccruals =[select id,name,source_amount__c from reconciliation_topic__c
                                                  where reconciliation_section__c='Accrual'];
       
       system.assertNotEquals( 0,rtAccruals.size(),'Expecting RT for Accrual Section as CIs in datasetup are not accounted');
       system.assertEquals(41.00, rtAccruals[0].source_amount__c);
        
       ReconRemoteExt.updateResult updtTS=ReconRemoteExt.updateAsOfNowDT(RECON.ID);
       system.assertEquals(true, updtTS.isSuccess);
        
      // ReconRemoteExt.BegEndBalResult begEndBal = ReconRemoteExt.runBegBalReports(recon.id,true,false);
      // system.assertEquals(true, begEndBal.isValid,'Expecting succesful Call');
       reconciliation__c reconUpd = [select id,name ,as_of__c,period__c,company__c,gl_account__c,Beginning_Balance__c,Ending_Balance__c from reconciliation__c where id=:recon.id];
       system.assertEquals(system.now().date(),reconUpd.As_Of__c.date(),'Expecting current TS');
      // system.assertEquals(0,reconUpd.Beginning_Balance__c,'Expecting 0 init balance');
      // system.assertEquals(0,reconUpd.Ending_Balance__c,'Expecting 0 ending balance as no there are no bookings into AR ');

       ApexPages.StandardController stdReconUpd = new ApexPages.StandardController(reconupd);
      
       Test.stopTest();
      
    }
    
    @istest
    public static void testUnreconciledSections()
    {
    	//Create AE with exceptions Dont give CR side rule
    	//Update Rule to point to wrong amount 
    	//Update Rule to point to wrong GL 
    	ReconSetup reconData = new ReconSetup();
            //Get expected sum by aggregating above ael by rules
      	list<accounting_rule__c> CIRuleForGoodsUpdate = new list<accounting_rule__c>();
    	list<accounting_rule__c> CIRuleForMiscUpdate = new list<accounting_rule__c>();
    	
    	list<accounting_rule__c> rulesBookingToAR =reconData.genCustInvoiceRules(new list<string>{'Ship Invoice|Goods|Standard','Ship Invoice|Goods|Miscellaneous','Ship Invoice|Goods|Adjustment'},reconData.fuel.accountingStandard.id,reconData.fuel.receivablesGL.id,reconData.fuel.cashGL.id);
    	Integer Index=0;
    	Integer deliNDEX=0;
    	
    	for(accounting_rule__c rule:rulesBookingToAR)
    	{
    		if(rule.line_type__c=='Standard' && rule.rule_type__c=='CR' )
    		{
    			delete rule; //Induce AE exceptions
				deliNDEX=Index;
    		}
    		else if(rule.line_type__c=='Miscellaneous' && rule.rule_type__c=='DR' )
    		{
    			rule.Amount_Reference__c='Unit_Price__c';
    			CIRuleForMiscUpdate.add(rule);//Simulate Amount being changed after AE has been generated for Amount discrepancy;
    			
    		}
    		else if(rule.line_type__c=='Adjustment' && rule.rule_type__c=='DR')
    		{
    			rule.GL_Account__c=reconData.fuel.cashGL.Id;
    			CIRuleForMiscUpdate.add(rule);//Simulate wrong GL Booking discrepancy;
    			    			
    		}
    		    		index=index+1;
    		
    	}
    	rulesBookingToAR.remove(deliNDEX);

        system.assertNotEquals(0,rulesBookingToAR.size(),'Expecting custom generated rules');
        system.assertNotEquals(0,CIRuleForMiscUpdate.size(),'Expecting misc rule to be updated');
		
		list<customer_invoice__c> CIUnreconciledList = new list<customer_invoice__c>();
		customer_invoice__c GoodsCIUnreconciledException=recondata.fuel.custinv1.clone(false,true,false,false);
		GoodsCIUnreconciledException.finalized__c=false;
		customer_invoice__c MiscCIUnreconciledAmount=recondata.fuel.custinv1.clone(false,true,false,false);
		MiscCIUnreconciledAmount.finalized__c=false;		
		customer_invoice__c AdjCIUnreconciledRule=recondata.fuel.custinv1.clone(false,true,false,false);
		AdjCIUnreconciledRule.finalized__c=false;	
				
		CIUnreconciledList.add(GoodsCIUnreconciledException);
		CIUnreconciledList.add(MiscCIUnreconciledAmount);
	    CIUnreconciledList.add(AdjCIUnreconciledRule);
		
	    test.starttest();       
		
		insert 	CIUnreconciledList;
			
		list<customer_invoice_line__c> CILListGoods=recondata.generateCustInvoiceLines(GoodsCIUnreconciledException);
		list<customer_invoice_line__c> CILListMisc=recondata.generateCustInvoiceLines(MiscCIUnreconciledAmount);
		list<customer_invoice_line__c> CILListAdj=recondata.generateCustInvoiceLines(AdjCIUnreconciledRule);		
		list<customer_invoice_line__c> CILList = new list<customer_invoice_line__c>();
		
        //list<customer_invoice_line__c> CILList=[select id,name,line_type__c from customer_invoice_line__c where customer_invoice__c = :custInvUnreconciled.id];
		CILListGoods[0].line_type__C='Standard';
		CILListGoods[1].line_type__C='Standard';
		
		CILListMisc[0].line_type__C='Miscellaneous';		
		CILListMisc[1].line_type__C='Miscellaneous';

		CILListAdj[0].line_type__C='Adjustment';		
		CILListAdj[1].line_type__C='Adjustment';
		
		CILList.addAll(CILListGoods);
		CILList.addAll(CILListMisc);
		CILList.addAll(CILListAdj);
		insert CILList;
				
		for(customer_invoice__c ci:CIUnreconciledList)
		{
         ci.Transaction_Date__c=system.now();
         ci.Finalized__c=true;
   		}
  
        update CIUnreconciledList;
        

        
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();        
        cia.execute(CILList);
        //system.assertequals(reconData.CILList,null,'Debugging CILLIST'); 
        //system.assertequals(CIRuleForMisc,null,'Debugging ci rules');      
        //list<customer_invoice_line__c> cil =[select id,name ,subtransaction_type__c,line_type__c from customer_invoice_line__c where customer_invoice__c = :recondata.custMisc.id];
        //system.assertequals(cil,null,'Expecting lines');      
        
        reconData.aeForCI =[select id,name,transaction_type__c,(select id,name,subtransaction_type__c,line_type__c,gl_account__r.name,customer_invoice_line__r.subtransaction_type__c,customer_invoice_line__r.line_type__c,accounting_rule__c,amount_cr__c,amount_dr__c,has_exceptions__c from accounting_entry_lines__r) 
                                           from accounting_entry__c 
                                            where customer_invoice__c in :CIUnreconciledList
                                            and   status__c='Active'
                                            ]; 
                                         
         //Asserts to debug
        system.assertNotequals(reconData.aeForCI.size(),0,'Expecting Accounting Entries');      
        //  list<task> exceptionTasksCI =[select id,description from task where whatid IN :reconData.aeForCI[0].accounting_entry_lines__r  ];
        // system.assertequals(exceptionTasksCI,null,'Debugging eXCEPTIONS');      
        // system.assertequals(reconData.aeForCI[0],null,'Debugging AE');            
        //system.assertequals(reconData.aeForCI[0].accounting_entry_lines__r,null,'Debugging AE Lines');      
        // update rulesBookingToAR;	
        update CIRuleForMiscUpdate;
        
        //TODO:The above update doesnt work for assigning gl_account__c for adjustment rule.So doing update again.Explore more on why.
        list<accounting_entry_line__c> AdjDRAELsbeforeUpd =[select id,name,gl_account__c,accounting_rule__c from accounting_entry_line__c where customer_invoice_line__c in :CILListAdj and amount_dr__c!=0];
        //system.assertequals(AdjDRaelsbeforeUpd[0].gl_account__c,reconData.ReconGL.Id,'Above update has not worked');
        for(accounting_entry_line__c ael:AdjDRAELsbeforeUpd)
        {
         ael.gl_account__c=reconData.fuel.cashGL.Id;//Changing the rule to induce incorrect rule discrepancy
        	
        }
        update AdjDRAELsbeforeUpd;
        list<accounting_entry_line__c> AdjDRAELsAfterUpd =[select id,name,gl_account__c,accounting_rule__c from accounting_entry_line__c where customer_invoice_line__c in :CILListAdj and amount_dr__c!=0];
        
        system.assertNotequals(AdjDRAELsAfterUpd[0].gl_account__c,reconData.ReconGL.Id,'The second Update Has worked');
        
        //system.assertEquals(null,rulesBookingToAR,'debugging custom generated rules');		
        
    	ReconData.insertRecon();        
        Reconciliation__c recon = [select id,name,period__c,GL_Account__c,company__c from Reconciliation__c
                                   where id=:reconData.recon.id];

        ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);
        ReconRemoteExt reconremote = new ReconRemoteExt(stdRecon);
        list<accounting_rule__c> ARDRRules=[select id,name,gl_account__c,line_type__c from accounting_rule__c 
	        								 where transaction__c='Ship Invoice' 
	        								 and subTransaction_Type__c='Goods'
	        								 and line_type__c!=null 
	        								 and Rule_Type__c='DR'];
        //system.assertEquals(null,ARDRRules,'debugging custom generated rules');		
        
	    list<ReconRemoteExt.chunkResultAggregateTotalsByRule>  ChunkAggByRuleList = new list<ReconRemoteExt.chunkResultAggregateTotalsByRule>();
	    for(accounting_rule__c rule : ARDRRules)
	      {
	      	if(rule.line_type__c=='Adjustment' )
	      	{
	      		system.assertNotequals(rule.gl_account__c,reconData.ReconGL.Id,'Not equal');
	      	}
	       ChunkAggByRuleList.addall(ReconRemoteExt.aggregateSDAELTotals(rule.id,reconData.reconperiod.id,new list<id>{reconData.ReconGL.Id}));
	      	
	      }

        Boolean hasUnreconciledException=false;
        Boolean hasUnreconciledAmount=false;
        Boolean hasUnreconciledRules=false;
        
       //system.assertequals(ChunkAggByRuleList,null,'Debugging Remoting results');
        
        for(ReconRemoteExt.chunkResultAggregateTotalsByRule chunkRuleResult:ChunkAggByRuleList)
        {
            system.assertequals(chunkRuleResult.isValid,true,'Expecting no system exceptions');
          	
          	if(chunkRuleResult.hasExceptions)
          	{
          		hasUnreconciledException=true;
            }
            if(chunkRuleResult.isIncorrectAmt)
            {
            	hasUnreconciledAmount=true;
            }
            if(chunkRuleResult.isIncorrectRule)
            {
            	hasUnreconciledRules=true;
            }
          	
         }
         system.assertequals(hasUnreconciledException,true,'Expecting CI misc with Exceptions to be picked');
         system.assertequals(hasUnreconciledAmount,true,'Expecting amount diff between source and GL amount due to changed rule.');
         system.assertequals(hasUnreconciledRules,true,'Expecting rule discrepancy.');
         
        test.stoptest();
    	
    }
    /*Insert RD and make the rule to  book to AR GL being reconciled.
    The entry should be listed under Other SDs*//*
    @istest
    public static void testOtherSD()
    {
            Test.startTest();
             ReconSetup reconData = new ReconSetup();
        	Test.stoptest();
             system.assert(reconData.fuel.exchangeRateList.size()>0);
		     Receiving_Document__c rd = new Receiving_Document__c(
		        Company__c = reconData.fuel.company.id,
		        Supplier__c = reconData.fuel.supplier.id,
		        Date_Created__c = system.today(),
		        Status__c = 'Draft',
		        Type__c = 'Purchase Order Receipt',
		        Currency__c = TestFuel.currencyUSD.id,
		        Transaction_Date__C = system.now()
		    );	
		    insert rd;
 			Receipt_Line__c receivingDocumentLine = new Receipt_Line__c();
            receivingDocumentLine.Company__c = reconData.fuel.company.id;
            receivingDocumentLine.Purchase_Order__c = reconData.fuel.purchaseOrder.Id;
            receivingDocumentLine.Purchase_Order_Line__c = reconData.fuel.purchaseOrderLines[0].Id;
            receivingDocumentLine.Item__c = reconData.fuel.purchaseOrderLines[0].Item__c;
            receivingDocumentLine.Quantity_Declared__c = 5;
            receivingDocumentLine.Expiration_Date__c = System.today()+5;
            receivingDocumentLine.Lot_Number__c = '1234';
            receivingDocumentLine.Status__c = 'Draft';
            receivingDocumentLine.Supplier__c = reconData.fuel.supplier.id;
            receivingDocumentLine.Receiving_Document__c = rd.id;
            receivingDocumentLine.Quantity_Received__c = 10;
            receivingDocumentLine.unit_price__c = 3;
            receivingDocumentLine.Facility__c=reconData.fuel.facility2.id;//Item-2 in testfuel has item cost record for this facility.
            
            insert receivingDocumentLine;
            rd.finalized__c=true;
            update rd;
            system.assert(reconData.fuel.rdAccountingRuleList.size()>0);
            list<accounting_rule__c> RDRules = [select id,name,Default_GL_Account__c,GL_Account_Reference_Value__c,GL_Account__c from accounting_rule__c 
            									where Object_Name__c='Receiving_Document__c' and SubTransaction_Type__c=null];
            system.assert(RDRules.size()>0);
            //Update rule to point to GL being reconciled.
            for(Accounting_rule__C rule:RDRules)
            {
             rule.Default_GL_Account__c = true;
             rule.GL_Account_Reference_Value__c = null;
             if(rule.rule_type__c=='CR')
             {
             	             rule.GL_Account__c = reconData.fuel.Cashgl.Id;            
             	
             }
             else
             {
             	             rule.GL_Account__c = reconData.ReconGL.Id;            
             	
             }
            }
            update RDRules;
                      
                  
            
            ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
            rda.execute(new list<receipt_line__c>{receivingDocumentLine});
            list<accounting_entry__c> ae = [select id,name,(select id,name,accounting_rule__c,has_exceptions__C,amount_cr__c,amount_dr__c 
                                                            from accounting_entry_lines__r) from accounting_entry__c 
                                              where receiving_document__c=:rd.id and has_exceptions__c=false ];

            system.assertNotEquals(ae.size(),0,'Expecting accounting entry  to be created for the RD'+ae);             
             system.assertNotEquals(ae[0].accounting_entry_lines__r.size(),0,'Expecting accounting entry lines to be created for the AE as we Item cost for ReciptLine ');             
            
            //list<task> tasks = [select id,description from task where whatid=:ae[0].accounting_entry_lines__r[0].id];
            //system.assertEquals(tasks.size(),0,'the Exceptions');
            
	        ReconData.insertRecon();        
	        Reconciliation__c recon = [select id,name,period__c,GL_Account__c,company__c from Reconciliation__c
	                                   where id=:reconData.recon.id];
	
	        ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);
	        ReconRemoteExt reconremote = new ReconRemoteExt(stdRecon);

	        
		    list<ReconRemoteExt.chunkResultAggregateTotalsByRule>  ChunkAggByRuleList = new list<ReconRemoteExt.chunkResultAggregateTotalsByRule>();
		    //Simulating User has inserted the rule as part of recon topic overriding the validation.
		    for(accounting_rule__c rule : RDRules)
		      {

		       ChunkAggByRuleList.addall(ReconRemoteExt.aggregateSDAELTotals(rule.id,reconData.reconperiod.id,new list<id>{reconData.ReconGL.Id}));
		      	
		      }
	
	        Boolean hasOtherSD=false;
	  	        
	        for(ReconRemoteExt.chunkResultAggregateTotalsByRule chunkRuleResult:ChunkAggByRuleList)
	        {
	            system.assertequals(chunkRuleResult.isValid,true,'Expecting no system exceptions');
	          	
	          	if(chunkRuleResult.isOtherSD)
	          	{
	          		hasOtherSD=true;
	            }
	          	
	         }
	         
	         system.assertequals(hasOtherSD,true,'Expecting other SDs as RD belongs to Other SDs section.');
            
    }  
    
    @istest
    public static  void testDetailPageUnmatched()
    {
            ReconSetup reconData = new ReconSetup(); 

            Test.startTest();
            reconData.suppInv1 = new Supplier_Invoice__c();
            reconData.suppInv1.Company__c = reconData.fuel.company.id;
            reconData.suppInv1.Invoice_Type__c = 'Invoice';
            reconData.suppInv1.Date_Invoiced__c = System.now();
            reconData.suppInv1.Currency__c = TestFuel.currencyUSD.id;
            reconData.suppInv1.Transaction_Date__c = system.now();
            reconData.suppInv1.Supplier__c = reconData.fuel.remittosupplier.id;
            reconData.suppInv1.Amount_Due__c = reconData.purchaseOrder.Purchase_Order_Value__c;
            reconData.suppInv1.Invoice_Amount__c = reconData.purchaseOrder.Purchase_Order_Value__c;
            reconData.suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            reconData.suppInv1.historical__c = false;
            system.assertNotEquals(reconData.purchaseOrder.Purchase_Order_Value__c, null);
            insert reconData.suppInv1;
                
            Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
            suppInvLine1.Supplier_Invoice__c = reconData.suppInv1.id;
            suppInvLine1.Invoice_Quantity__c = 10;
            suppInvLine1.Invoice_Quantity_to_Stock__c = 10;
            suppInvLine1.Unit_Price__c = 12;//KNDY-14371
            suppInvLine1.Item__c = reconData.fuel.itemlist[2].id;
            suppInvLine1.Purchase_Order__c = reconData.purchaseOrder.id;
            suppInvLine1.Purchase_Order_Line__c = reconData.POLinelist[0].id;
            suppInvLine1.Quantity_Received__c = 10;
            suppInvLine1.Unit_Price__c = 12; 
            suppInvLine1.subtransaction_type__c=null;
            suppInvLine1.line_type__c = 'Miscellaneous';           
            reconData.suppInvLineList1.add(suppInvLine1);
        
            insert reconData.suppInvLineList1;
            
            //KNDY-12704 reset WFR/FU set fields to expected values
            suppInvLine1.SubTransaction_Type__c = 'Miscellaneous';
            suppInvLine1.line_type__c = null;
            update suppInvLine1;
            
            reconData.suppInv1.Status__c = 'Approved';
            reconData.suppInv1.finalized__c = true;
            
            update reconData.suppInv1;
            list<Gl_account__c> GLList=[select id,name from GL_Account__c where name in ('42000 - Revenue','12000 - Cash')];
 
            list<accounting_rule__c> SuppInvAcctRulesList = new list<accounting_rule__c>();           
            Accounting_Rule__c sinvacctRule9 = new Accounting_Rule__c();
            sinvacctRule9.Object_Name__c = 'Supplier_Invoice__c';
            //sinvacctRule9.company__c = reconData.fuel.company.id;
            sinvacctRule9.accounting_standard__c = reconData.fuel.accountingStandard.id;
            sinvacctRule9.Transaction__c = 'Invoice';
            sinvacctRule9.SubTransaction_Type__c = 'Miscellaneous';
            //sinvacctRule9.Segment_Name__c = 'GL_Account__c';
            sinvacctRule9.Rule_Type__c = 'CR';
            //sinvacctRule9.Criteria__c = 'Item Class';
            sinvacctRule9.Default_GL_Account__c = true;
            sinvacctRule9.GL_Account__c = GLList[0].id;
            sinvacctRule9.line_type__c = null;        
 		    sinvacctRule9.Effective_Start_Date__c = reconData.fuel.effStartDate;
               
            SuppInvAcctRulesList.add(sinvacctRule9);
            
            Accounting_Rule__c sinvacctRule10 = new Accounting_Rule__c();
            sinvacctRule10.Object_Name__c = 'Supplier_Invoice__c';
            //sinvacctRule10.company__c = reconData.fuel.company.id;
            sinvacctRule10.accounting_standard__c = reconData.fuel.accountingStandard.id;
            sinvacctRule10.Transaction__c = 'Invoice';
            sinvacctRule10.SubTransaction_Type__c = 'Miscellaneous';            
            sinvacctRule10.line_type__c = null;            
            //sinvacctRule10.Segment_Name__c = 'GL_Account__c';
            sinvacctRule10.Rule_Type__c = 'DR';
            //sinvacctRule10.Criteria__c = 'Accounting Default';
            sinvacctRule10.Default_GL_Account__c = true;
            sinvacctRule10.GL_Account_Reference_Value__c = null;
            sinvacctRule10.GL_Account__c = GLList[1].id;          
 		    sinvacctRule10.Effective_Start_Date__c = reconData.fuel.effStartDate;              
            SuppInvAcctRulesList.add(sinvacctRule10);
            
            insert SuppInvAcctRulesList;
            
        list<task> exceptionTasksSI =[select id,description from task where whatid = :reconData.suppInv1.id   ];
        system.assertEquals(0,exceptionTasksSI.size(),'log exception si');
                 
            list<accounting_rule__c> supplierInvRules=[select id,name 
                                                           from accounting_rule__C 
                                                           where object_name__c='Supplier_Invoice__c' 
                                                           and transaction__c='Invoice'
                                                           and line_type__c=null
                                                           and subtransaction_type__c='Miscellaneous'
                                                           and accounting_standard__c=:reconData.fuel.accountingStandard.id]; 
       system.assertNotEquals(supplierInvRules.size(),0,'Expecting rules booking  SI');
                    
        SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
        list<supplier_invoice_line__c> silList = new list<supplier_invoice_line__c>();
        silList.addall(reconData.suppInvLineList1);
        sia.execute(silList);
     
        List<Accounting_Entry__c> acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,transaction_type__c,
                                                (Select id, Name, Amount_CR__c, Amount_DR__c,gl_account__c,accounting_rule__c ,SubTransaction_Type__c, Line_Type__c
                                                from Accounting_Entry_Lines__r)
                                                from Accounting_Entry__c 
                                                where (Supplier_Invoice__c = :recondata.suppInv1.ID) and status__c='Active' 
                                                 order by id];
//       system.assertEquals(acctEntry[0],null);                                                 
 //      system.assertEquals(acctEntry[0].Accounting_Entry_Lines__r,null);
        list<task> exceptionTasks =[select id,description from task where whatid in :acctEntry[0].Accounting_Entry_Lines__r];
        system.assertEquals(0,exceptionTasks.size(),'Expecting no Exceptions');
        system.assertNotEquals(0,acctEntry.size(),'Expecting SI ae');
        system.assertNotEquals(0,acctEntry[0].Accounting_Entry_Lines__r.size(),'Expecting SI');
        //quick Hack to make the AEL point to AR account.
        for(accounting_entry_line__c ael :acctEntry[0].Accounting_Entry_Lines__r)
        {
          if(ael.amount_CR__c!=0)
          {
               ael.gl_account__c = reconData.ARGLs[0].id; 
         
          }
        }
        update acctEntry[0].Accounting_Entry_Lines__r;
        
        ReconData.insertRecon();
       
        List<Reconciliation_Topic__C> UnmatchedTopicsList = new list<reconciliation_topic__c>();
        for(accounting_rule__c rule:SuppInvAcctRulesList)
        {
        	reconciliation_topic__c rt = new reconciliation_topic__c();
	        rt.name='SI'+rule.name;
	        rt.accounting_rule__c=rule.id;
	        rt.reconciliation_section__c='unmatched';
	        rt.Reconciliation__c=reconData.recon.id;  
	        UnmatchedTopicsList.add(rt);
        }
        insert UnmatchedTopicsList;
        
        PageReference reconDetailRef = Page.ReconRemoteDetail;
        test.setCurrentPage(reconDetailRef);
        ApexPages.currentPage().getParameters().put('Id', reconData.recon.id);
        ApexPages.currentPage().getParameters().put('RptSection', 'Unmatched');
        ApexPages.currentPage().getParameters().put('SDType', 'Supplier_Invoice__c');
        Reconciliation__c recon = [select id,name,period__c,GL_Account__c,company__c from Reconciliation__c
                                   where id=:reconData.recon.id];
        
        ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);
        ReconRemoteDetailExt  detailClass1 = new ReconRemoteDetailExt (stdRecon);
        system.assertEquals(apexpages.getMessages().size(),0);      

        system.assertNotEquals(0, detailClass1.sobjects.size(),'Expecting Unmatched entries');
       
        
        Test.stopTest();



    }
  
    
    
    @istest
    public static void testDetailPageUnreconciled()
    {
        ReconSetup reconData = new ReconSetup();
        Test.startTest();
        
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();        
        cia.execute(reconData.CILList);
        reconData.aeForCI =[select id,name,(select id,name,amount_DR__c,amount_CR__c,accounting_rule__c,gl_account__c from accounting_entry_lines__r where has_exceptions__c=false ) 
                            from accounting_entry__c 
                            where customer_invoice__c in :reconData.mCI.keyset() 
                            and status__c='Active' and has_exceptions__c=false];
        
        system.assertNotEquals(reconData.aeForCI.size(),0,'Expecting accounting entries to be created for the invoices');
        system.assertNotEquals(reconData.aeForCI[0].accounting_entry_lines__r.size(),0,'Expecting accounting entry lines to be created for the invoices');
        
       //system.assertEquals(reconData.aeForCI[0].accounting_entry_lines__r[0].amount_DR__c, null);
      // system.assertEquals(reconData.ReconGL.id, reconData.aeForCI[0].accounting_entry_lines__r[1].gl_account__c);
       //system.assertEquals(reconData.aeForCI[0].accounting_entry_lines__r[1].amount_DR__c, null);


        list<task> exceptionTasks =[select id,description from task where whatid=:reconData.aeForCI[0].Accounting_Entry_Lines__r[1].id];
        system.assertEquals(0,exceptionTasks.size(),'Expecting no Exceptions');
    
         
        //quick Hack to make the AEL have wrong amount
        for(accounting_entry_line__c ael : reconData.aeForCI[0].Accounting_Entry_Lines__r)
        {
            //reconData.aeForCI[0].accounting_entry_lines__r[1].amount_DR__c=2;
			ael.amount_DR__c=ael.amount_DR__c!=0?2:0;
			ael.amount_CR__c=ael.amount_CR__c!=0?2:0;
			               
          
        }
        update reconData.aeForCI[0].Accounting_Entry_Lines__r;
        
        list<accounting_entry__c> ae=[select id,name from accounting_entry__c where has_exceptions__c=false and id=:reconData.aeForCI[0].id];
        system.assertNotEquals(ae.size(),0);
        
        //system.assertNotEquals(reconData.aeForCI[0].accounting_entry_lines__r[1].accounting_rule__c, null);
        //system.assertEquals(reconData.aeForCI[0].accounting_entry_lines__r[0].amount_DR__c, 2);
        ReconData.insertRecon();       
        For(reconciliation_topic__c rt:recondata.topicsList)
        {
        	rt.reconciliation_section__c ='UnreconciledAmount';
        }
        update recondata.topicsList;
        PageReference reconDetailRef = Page.ReconRemoteDetail;
        test.setCurrentPage(reconDetailRef);
        ApexPages.currentPage().getParameters().put('Id', reconData.recon.id);
        ApexPages.currentPage().getParameters().put('RptSection', 'UnreconciledAmount');
        ApexPages.currentPage().getParameters().put('SDType', 'Customer_Invoice__c');
        
        Reconciliation__c recon = [select id,name,period__c,GL_Account__c,company__c from Reconciliation__c
                                   where id=:reconData.recon.id];  
                             
        ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);    
  
        ReconRemoteDetailExt  detailClass2 = new ReconRemoteDetailExt (stdRecon);
		Test.stopTest();
        system.assertEquals(apexpages.getMessages().size(),0);      
        system.assertNotEquals(0, detailClass2.sobjects.size(),'Expecting Unreconciled entries');  

    }
    //TODO:Add test method for detail page exception.
    @istest
    public static void testDetailPageAccrualAndManual()
    {
        ReconSetup reconData = new ReconSetup();
        
        Test.startTest();
        JournalEntryAccounting jea = new JournalEntryAccounting();
        jea.execute(reconData.jelList);
        list<accounting_entry__c> manualAE =[select id,name,(select id,name from accounting_entry_lines__r) 
                                             from accounting_entry__c where journal_entry__c=:reconData.JEid and status__c='Active' and has_Exceptions__c=false];
        system.assertNotEquals(manualAE.size(),0,'Expecting accounting entries to be created for the journal');
        system.assertNotEquals(manualAE[0].accounting_entry_lines__r.size(),0,'Expecting accounting entry lines to be created for the jounral');    
            ReconData.insertRecon();
            PageReference reconDetailRef = Page.ReconRemoteDetail;
            test.setCurrentPage(reconDetailRef);
            ApexPages.currentPage().getParameters().put('Id', reconData.recon.id);
            ApexPages.currentPage().getParameters().put('RptSection', 'AccrualCandidates');
            ApexPages.currentPage().getParameters().put('SDType', 'Customer_Invoice__c');
            
            Reconciliation__c recon = [select id,name,period__c,GL_Account__c,company__c from Reconciliation__c
                                       where id=:reconData.recon.id];      
            ApexPages.StandardController stdRecon = new ApexPages.StandardController(recon);        
            ReconRemoteDetailExt  detailClass3 = new ReconRemoteDetailExt (stdRecon);
            system.assertNotEquals(0, detailClass3.sobjects.size(),'Expecting Accrual Candidates for invoices');
        
            ApexPages.currentPage().getParameters().put('Id', reconData.recon.id);
            ApexPages.currentPage().getParameters().put('RptSection', 'Manual');
            ApexPages.currentPage().getParameters().put('SDType', 'Journal_Entry__c');       
            ReconRemoteDetailExt  detailClass4 = new ReconRemoteDetailExt (stdRecon);
            system.assertNotEquals(0, detailClass4.sobjects.size(),'Expecting Manual entries');        
        Test.stopTest();
        
    }
   
    @istest
    public static void NewReconTopic()
    {
        ReconSetup reconData = new ReconSetup();
        ReconData.insertRecon();
        
        reconciliation_topic__c rt = new reconciliation_topic__c();
        rt.reconciliation__c=reconData.recon.id;
        rt.Type__c='Customer Invoice';
        insert RT;
        
        Test.startTest();
        reconciliation_topic__c RTrec = [select id,name,type__c,reconciliation__c from reconciliation_topic__c
                                       where id=:rt.id]; 
        ApexPages.StandardController stdRecon = new ApexPages.StandardController(RTrec);        
     
        NewReconTopicExt newRT = new NewReconTopicExt(stdrecon);
        system.assertNotEquals(0, newRT.Rulewrapperlist.size());
        newRT.next();
        system.assertNotEquals(0, newRT.Rulewrapperlist.size());
        newRT.previous();
        system.assertEquals(newRT.hasPrevious, false);
        newRT.selectedTT='Customer Invoice';
        newRT.selectedSTT='Sales Tax';
        newRT.applyFilter();
        system.assertNotEquals(0, newRT.Rulewrapperlist.size());
        newRT.save();
        list<reconciliation_topic__c> RTInserted = [select id,name from reconciliation_topic__c where reconciliation__c=:reconData.recon.id];
        system.assert(RTInserted.size()>1, 'More than 1 topic inserted for the rules.');
        newRT.SaveAndReturn();
        newRT.cancel();
        Test.stopTest();
        
        
        //nEXT 
        //prev--Check disable based on count
        //applyfilter
        //getSelected 
        //createTopics--check insertion count
        
    }
    @istest
    public static void cloneReconAndTopics(){
        ReconSetup reconData = new ReconSetup();
        ReconData.insertRecon();
        
        reconciliation_topic__c rt = new reconciliation_topic__c();
        rt.reconciliation__c=reconData.recon.id;
        rt.Type__c='Customer Invoice';
        insert RT;
        
        Test.startTest();
        reconciliation_topic__c RTrec = [select id,name,type__c,reconciliation__c from reconciliation_topic__c
                                       where id=:rt.id]; 
        ApexPages.StandardController cloneRecon = new ApexPages.StandardController(reconData.recon);        
     
        cloneReconciliationExt newRT = new cloneReconciliationExt(cloneRecon);
        newRT.cloneSingleReconHeaderandTopics();      
        string cloneReconName = reconData.recon.name + ' - Clone'; 

        List<reconciliation__c> newReconCreated = [SELECT ID, Name, (SELECT ID From reconciliation_topics__r) FROM reconciliation__c WHERE Name = : cloneReconName LIMIT 1];
        system.assert(newReconCreated.size() == 1);
        system.assert(newReconCreated[0].reconciliation_topics__r.size() > 0); 
        Test.stopTest();

        
    }      
*/}