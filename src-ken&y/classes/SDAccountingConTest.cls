@isTest
private class SDAccountingConTest {
    
    public static testMethod void GenerateTest() {
        testFuel data = new testFuel();
        List<Invoice_Line__c> InvLineList1 = new List<Invoice_Line__c>();
        Invoice__c Inv1;
        
        Inv1 = new Invoice__c();
        Inv1.From_Company__c = data.company.id;
        Inv1.To_Company__c = data.altCompany.id;
        Inv1.Type__c = 'Intercompany Investment';
        Inv1.Currency__c = TestFuel.currencyUSD.id;
        Inv1.Transaction_Date__c = system.now();
        
        
        insert inv1;
        
        Invoice_Line__c InvLine1 = new Invoice_Line__c(); 
        InvLine1.Invoice__c = Inv1.id;
        InvLine1.Extended_Amount__c = 5000;
        InvLineList1.add(InvLine1);
        
        Invoice_Line__c InvLine2 = new Invoice_Line__c(); 
        InvLine2.Invoice__c = Inv1.id;
        InvLine2.Extended_Amount__c = 10000;
        InvLineList1.add(InvLine2);
        
        Invoice_Line__c InvLine3 = new Invoice_Line__c(); 
        InvLine3.Invoice__c = Inv1.id;
        InvLine3.Extended_Amount__c = 5000;
        InvLineList1.add(InvLine3);
        
        Invoice_Line__c InvLine4 = new Invoice_Line__c(); 
        InvLine4.Invoice__c = Inv1.id;
        InvLine4.Extended_Amount__c = 10000;
        InvLineList1.add(InvLine4);
        insert InvLineList1;
        
        system.assert(data.periodList.size() >0);
        system.assert(data.altCompanyPeriodList.size() >0);
        system.assert(data.invoiceRuleList.size() >0);
        
        Inv1.finalized__c = true;
             
        update Inv1;
        
        Test.startTest();
        Test.setCurrentPage( Page.SDAccounting);
        Apexpages.currentPage().getParameters().put('id', Inv1.id );
        SDAccountingCon con = new SDAccountingCon();
        con.populateSobjDetails(); 
        
        system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() );
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        for(map<string,string> m:chunks)
        {
         SDAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }
        List<Accounting_Entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE invoice__c = :inv1.id];
        system.assertNotEquals(0, ae.size(), 'We are expecting an AE synchronously');
                
        system.assert( con.close() != null );
        
    }

    

    public static testMethod void PreviewTestFail() {
        JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
        UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
        Test.setCurrentPage( Page.SDAccounting);
        Apexpages.currentPage().getParameters().put('id', JE.JEList[0].id );
        Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});        
        SDAccountingCon con = new SDAccountingCon();
        con.populateSobjDetails();
        system.assert( Apexpages.hasMessages() == true, ' expected error msg');     
    }
    
     
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
        
        Test.setCurrentPage( Page.SDAccounting);
        Apexpages.currentPage().getParameters().put('id', JE.JEList[0].Id );
        SDAccountingCon con = new SDAccountingCon();
        datetime lddt = con.loadDt;
        con.populateSobjDetails();
        
        //We need to manually invoke the remoting methods as the Test class seems not to invoke the same.
        Test.startTest();    
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        for(map<string,string> m:chunks)
        {
         SDAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }
        Test.stopTest(); 
        List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c,batchjobid__c,total_lines__c FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id and status__c = 'Active'];
        system.assertEquals(ActiveAE[0].batchjobid__c,con.guid,'We are expecting a draft AE created for this guid');
        list<accounting_entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id  and status__c = 'Active' ORDER BY CreatedDate desc LIMIT 1];
        system.assertNotEquals(0, ae.size(), 'We are expecting an AE from the VF Remoting');
         
    }
    
/*    public static testMethod void testReverseAE()
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
        Test.setCurrentPage( Page.SDAccounting);

        Apexpages.currentPage().getParameters().put('id', JEList_Accrual[0].Id );
        SDAccountingCon con = new SDAccountingCon();

        Test.startTest();    
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        SDAccountingCon.resultChunkObject obj;
        SDAccountingCon.ResultChunkReverse revobj;
        for(map<string,string> m:chunks)
        {
          obj =SDAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.guid,con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
          i++;
        }
        List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c,has_exceptions__c FROM Accounting_Entry__c WHERE status__c = 'Active'];
        system.assertEquals(1, ActiveAE.size(), 'We are expecting  a Active AEs to be created .');
        
        system.assertEquals(false, ActiveAE[0].has_exceptions__c, 'There should be no exceptions on original AE for Reversal AE to succesfully created');
        system.assertNotequals(obj.voidAEId, null,'This field should be populated as it is param for reverse AE');
        system.assertNotequals(obj.hasReverse, false,'Should be set as itis JE of type Accrual manual');

        Test.stopTest();   
        list<map<string,string>> chunksRev =(list<map<string,string>>)JSON.deserialize(obj.reverseChunkMap, list<map<string,string>>.class);
        AggregateResult ar = [select min(autonumber__c) min, max(autonumber__c) max from accounting_entry_line__c where Accounting_Entry__c =:obj.voidAEId];
        integer j=0;
        for(map<string,string> m:chunksRev)
        {
            revobj=SDAccountingCon.reverseAE(obj.voidAEId,j,chunksRev.size(),m.get('min'),m.get('max'),false,con.getguid());
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
            list<accounting_entry__c> aelist = [select id,name,has_exceptions__c from accounting_entry__c 
                                                where status__c='Active'
                                                and journal_entry__c=:JEList_Accrual[0].id
                                                and has_exceptions__c=true];
            system.assertNotEquals(aelist.size(), 0,'Expecting reversal Entry to have exceptions');
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
            Test.setCurrentPage( Page.SDAccounting);
            Apexpages.currentPage().getParameters().put('id', JEList_Accrual[0].Id );
            SDAccountingCon con = new SDAccountingCon();
            Test.startTest();
            list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
            integer i=0;
            SDAccountingCon.resultChunkObject obj;
            SDAccountingCon.ResultChunkReverse revobj;
            for(map<string,string> m:chunks)
            {
              obj =SDAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.guid,con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
              i++;
            }
            List<Accounting_Entry__c> ActiveAE = [SELECT Id,status__c,has_exceptions__c FROM Accounting_Entry__c 
                                                  WHERE status__c = 'Active' and related_accounting_entry__c=null];
            system.assertEquals(1, ActiveAE.size(), 'We are expecting  a Active AEs to be created .');
            system.assertEquals(false, ActiveAE[0].has_exceptions__c, 'There should be no exceptions on original AE for Reversal AE to succesfully created');
            system.assertNotequals(obj.voidAEId, null,'This field should be populated as it is param for reverse AE');
            system.assertNotequals(obj.hasReverse, false,'Should be set as itis JE of type Accrual manual');
    
            list<map<string,string>> chunksRev =(list<map<string,string>>)JSON.deserialize(obj.reverseChunkMap, list<map<string,string>>.class);
            AggregateResult ar = [select min(autonumber__c) min, max(autonumber__c) max from accounting_entry_line__c where Accounting_Entry__c =:obj.voidAEId];
            integer j=0;
            for(map<string,string> m:chunksRev)
            {
                revobj=SDAccountingCon.reverseAE(obj.voidAEId,j,chunksRev.size(),m.get('min'),m.get('max'),false,con.getguid());
                j++;
            } 
            Test.stopTest();   
               
            List<Accounting_Entry__c> reverseAE = [SELECT Id,status__c FROM Accounting_Entry__c 
                                                   where related_accounting_entry__c=:obj.voidAEId 
                                                   and status__c='Active' 
                                                   and journal_entry__c=:JEList_Accrual[0].id
                                                   and has_exceptions__c=false];
            system.assertEquals(1, reverseAE.size(), 'We are expecting a reverse entry without exceptions to be created for activeAE');        
        }*/
}