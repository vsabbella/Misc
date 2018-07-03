/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class GLAccountServiceTest {

    static testMethod void testGLType_AccountRange() {
        // create GL Type assign the account range
        List<GL_Type__c> glTypeList = new List<GL_Type__c>();
        GL_Type__c glType1 = new GL_Type__c();
        glType1.name = 'Other Revenue';
        glType1.normal_balance__c = 'Credit';
        glType1.accounting_type__c = 'Revenue';
        glType1.statement_type__c = 'Income Statement';
        glType1.account_range_from__c = '40000';
        glType1.account_range_to__c = '48999';
        glTypeList.add(glType1);
        
        GL_Type__c glType2 = new GL_Type__c();
        glType2.name = 'Misc Revenue';
        glType2.normal_balance__c = 'Credit';
        glType2.accounting_type__c = 'Revenue';
        glType2.statement_type__c = 'Income Statement';
        glType2.account_range_from__c = '49000';
        glType2.account_range_to__c = '49999';
        
        glTypeList.add(glType2);
        
        insert glTypeList;
        
         // create a GL Account put the GL Account number out of the range
        List<GL_Account__c> glList = new List<GL_Account__c>();
        GL_Account__c revenueGL = new GL_Account__c();
		revenueGL.GL_Account_Number__c = '52000';
		revenueGL.GL_Account_Name__c = 'Revenue';
		revenueGL.active__c = true;
		revenueGL.Normal_Balance__c = 'Credit';
		revenueGL.Statement_Type__c = 'Income Statement';
		revenueGL.non_cash__c = true;
		revenueGL.gl_type__c = glType1.id;
		
		boolean sawException = false;
		String errMsg = '';
		try{
			insert revenueGL;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		// assert the exception during insert
		system.assert(sawException == true,'Expected to encounter exception while inserting GL off the range'+errMsg);
        
        // change the number to fit in the range and assert no exception
        revenueGL.GL_Account_Number__c = '42000';
        sawException = false;
		errMsg = '';
		
        try{
			insert revenueGL;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		system.assert(sawException == false,'Not expected to encounter exception while inserting GL'+errMsg);
        
        // create a GL Account dont associate the GL Type 
		GL_Account__c revenueGLA = new GL_Account__c();
		revenueGLA.GL_Account_Number__c = '52000';
		revenueGLA.GL_Account_Name__c = 'Revenue';
		revenueGLA.active__c = true;
		revenueGLA.Normal_Balance__c = 'Credit';
		revenueGLA.Statement_Type__c = 'Income Statement';
		revenueGLA.non_cash__c = true;
        
        sawException = false;
		errMsg = '';
		
        try{
			revenueGLA.GL_Account_Number__c = null;			
			insert revenueGLA;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		system.assert(sawException == true,'Expected to encounter exception while inserting GL without GL Type'+errMsg);
		
		sawException = false;
		errMsg = '';
		try{
			revenueGLA.GL_Type__c = glType2.id;
			revenueGLA.GL_Account_Number__c = null;			
			update revenueGLA;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		system.assert(sawException == true,'Expected to encounter exception while updating GL with the GL Type missing account number on GL Account'+errMsg);
		
		// Update GL Account - have the GL Account number not in the range of associated GL Type
		sawException = false;
		errMsg = '';
		try{
			revenueGLA.GL_Type__c = glType1.id;
			update revenueGLA;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		system.assert(sawException == true,'Expected to encounter exception while updating GL with the GL Type for not matching the account number range'+errMsg);
		
		
		}
        
    // With the latest changes to make GL Type as required field on GL Account this use case is not valid anymore
    /*static testMethod void validateGLAccountNumberTest() {
        GL_Account__c revenueGL = new GL_Account__c();
		revenueGL.GL_Account_Name__c = 'Revenue';
		revenueGL.active__c = true;
		revenueGL.Normal_Balance__c = 'Credit';
		revenueGL.Statement_Type__c = 'Income Statement';
		revenueGL.non_cash__c = true;
		insert revenueGL;
		
		test.StartTest();
			try{revenueGL.GL_Account_Number__c = '52000';
				update revenueGL;
			}
			catch(exception e){
	    
	    	system.assert(e.getmessage().contains('This GL Account cannot have GL Account Number filled when there is no GL Type associated with it.'));
	    
	    }										    	
        
    }*/
    
    static testMethod void TestChildParentAccountNumberAssignment() {
        // create GL Type assign the account range
        List<GL_Type__c> glTypeList = new List<GL_Type__c>();
        GL_Type__c glType1 = new GL_Type__c();
        glType1.name = 'Revenue';
        glType1.normal_balance__c = 'Credit';
        glType1.accounting_type__c = 'Revenue';
        glType1.statement_type__c = 'Income Statement';
        glType1.account_range_from__c = '40000';
        glType1.account_range_to__c = '48999';
        glTypeList.add(glType1);
        
        insert glTypeList;
        
         // create a GL Account put the GL Account number out of the range
        List<GL_Account__c> glList = new List<GL_Account__c>();
        GL_Account__c revenueGL1 = new GL_Account__c();
		revenueGL1.GL_Account_Number__c = '41000';
		revenueGL1.GL_Account_Name__c = 'Revenue-A';
		revenueGL1.active__c = true;
		revenueGL1.Normal_Balance__c = 'Credit';
		revenueGL1.Statement_Type__c = 'Income Statement';
		revenueGL1.non_cash__c = true;
		revenueGL1.gl_type__c = glType1.id;
		
		insert revenueGL1;
		
		GL_Account__c revenueGL2 = new GL_Account__c();
		revenueGL2.GL_Account_Number__c = '40001';
		revenueGL2.GL_Account_Name__c = 'Revenue-B';
		revenueGL2.SubAccount_of__c = revenueGL1.id;
		revenueGL2.active__c = true;
		revenueGL2.Normal_Balance__c = 'Credit';
		revenueGL2.Statement_Type__c = 'Income Statement';
		revenueGL2.non_cash__c = true;
		revenueGL2.gl_type__c = glType1.id;
		
		Boolean sawException = false;
		String errMsg = '';
		try{
			insert revenueGL2;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		
		//system.assert(sawException == true,'Child Account can not have Account Number prior than the Parent Account Number');
		system.assert(sawException == false,'Child Account can have Account Number prior than the Parent Account Number');
		
		revenueGL2 = new GL_Account__c();
		revenueGL2.GL_Account_Number__c = '41001';
		revenueGL2.GL_Account_Name__c = 'Revenue-B';
		revenueGL2.SubAccount_of__c = revenueGL1.id;
		revenueGL2.active__c = true;
		revenueGL2.Normal_Balance__c = 'Credit';
		revenueGL2.Statement_Type__c = 'Income Statement';
		revenueGL2.non_cash__c = true;
		revenueGL2.gl_type__c = glType1.id;
		
		sawException = false;
		errMsg = '';
		try{
			insert revenueGL2;
		}catch(Exception e){
			sawException = true;
			errMsg = e.getMessage();
		}
		
		system.assert(sawException == false,'Success');
    }

    public static testMethod void testvalidateGLAccountTypeONGL(){



        TestFuel fuel = new TestFuel();    	
		
		Company__c testComp = fuel.Company; 
		Account testAccount = fuel.account; 
		GL_Type__c testExpenseGLType = fuel.expense; 
		Supplier__c testSupplier = fuel.supplier; 
		Supplier__c testSupplierRemitTo = fuel.supplier; 
		testSupplierRemitTo.Type__c = 'Remit To';
		List<Accounting_Rule__c> testAccRule = fuel.SuppInvAcctRulesList;
		update testSupplierRemitTo;

		Bank_Account__c bankAccount = new Bank_Account__c();
        bankAccount.Name = 'TESTBNK';
        bankAccount.Company__c = testComp.Id;
        insert bankAccount;



        // create GL Type assign the account range
        List<GL_Type__c> glTypeList = new List<GL_Type__c>();
        GL_Type__c glType1 = fuel.otherIncome_expense;


        GL_Type__c glType2 = fuel.costOfGoodsSold;
    
        
         // create a GL Account put the GL Account number out of the range
        List<GL_Account__c> glList = new List<GL_Account__c>();
        GL_Account__c glAccountRevenueA = new GL_Account__c();
		glAccountRevenueA.GL_Account_Number__c = '80003';
		glAccountRevenueA.GL_Account_Name__c = 'Revenue-A';
		glAccountRevenueA.active__c = true;
		glAccountRevenueA.Normal_Balance__c = 'Credit';
		glAccountRevenueA.Statement_Type__c = 'Income Statement';
		glAccountRevenueA.non_cash__c = false;
		glAccountRevenueA.gl_type__c = glType1.id;
		
		insert glAccountRevenueA;


        GL_Account__c glAccountRevenueB = new GL_Account__c();
		glAccountRevenueB.GL_Account_Number__c = '80002';
		glAccountRevenueB.GL_Account_Name__c = 'Revenue-A';
		glAccountRevenueB.active__c = true;
		glAccountRevenueB.Normal_Balance__c = 'Credit';
		glAccountRevenueB.Statement_Type__c = 'Income Statement';
		glAccountRevenueB.non_cash__c = false;
		glAccountRevenueB.gl_type__c = glType1.id;
		
		insert glAccountRevenueB;

		glList.add(glAccountRevenueA);
		glList.add(glAccountRevenueB);



		Supplier_Invoice__c testSI = new Supplier_Invoice__c();
		testSI.Company__c = testComp.id;
		testSI.Supplier__c = testSupplierRemitTo.id;
		testSI.Invoice_Amount__c = 500;
		testSI.Currency__c = TestFuel.currencyUSD.id;
		testSI.Invoice_Type__c = 'Invoice';
		testSI.Supplier_Invoice__c = system.today() + ': 123';


		insert testSI;

		Accounting_Default__c testAccountingDefault = new Accounting_Default__c();
		testAccountingDefault.GL_Account__c = glAccountRevenueA.Id;
		insert testAccountingDefault;

		Supplier_Invoice_Line__c testSILine = new Supplier_Invoice_Line__c();
		testSILine.Supplier_Invoice__c = testSI.id;
		testSILine.Invoice_Quantity__c = 1;
		testSILine.Unit_Price__c = 500;//KNDY-14371
		testSILine.Accounting_Segment__c = testAccountingDefault.id;
		testSILine.Item__c = fuel.itemList[1].id; 
		insert testSILine;

		List<Supplier_Invoice_Line__c> siLineList = new List<Supplier_Invoice_Line__c>();
		siLineList.add(testSILine);

		List<Supplier_Invoice__c> siList = new List<Supplier_Invoice__c>();
		siList.add(testSI);

		testSI.Finalized__c = true;
		testSI.Transaction_Date__c = system.today();
		testSI.Finalized_Date__c = system.today();
		update TestSi;

		for(Accounting_Rule__c arNOW : testAccRule){
				
							arNOW.GL_Account__c = glAccountRevenueA.id;
		
			update arNOW;
		}


		Test.startTest();

    	String eMsgUpdate;
    	Boolean sawExceptionUpdate = false;
    	Integer errorSizeUpdate;
    	String eMsgDelete;
    	Boolean sawExceptionDelete = false;
    	Integer errorSizeDelete;


		SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
		sia.execute(siLineList);

		List<Accounting_Entry__c> aeList = [SELECT Id, Total_Amount_CR__c, Total_Amount_DR__c , Transaction_Type__c ,(Select Id ,GL_Account__c, SubTransaction_Type__c FROM Accounting_Entry_lines__r) 
											FROM Accounting_Entry__c 
											WHERE   status__c = 'Active' AND Supplier_Invoice__c =: TestSi.id ];

		List<Accounting_Entry_Line__c> aeLineList = [SELECT ID, GL_Account__c, GL_Account__r.GL_Account_Number__c, Accounting_Entry__r.id, Accounting_Entry__r.Transaction_Type__c, SubTransaction_Type__c
											FROM Accounting_Entry_Line__c 
											WHERE Accounting_Entry__r.status__c = 'Active' AND Accounting_Entry__r.Supplier_Invoice__c =: TestSi.id ];										
		

		
		
		//update GL
		try{
			glAccountRevenueA.GL_Type__c = glType2.id;
			glAccountRevenueA.GL_Account_Number__c = '50001';
			update glAccountRevenueA;
		} catch (Exception exUpdate){
			eMsgUpdate = exUpdate.getMessage();
			sawExceptionUpdate = true; 
		}
		


		//Delete gl
		try{
			delete glAccountRevenueA;
		} catch (Exception exDelete){
			sawExceptionDelete = true;
			eMsgDelete = exDelete.getMessage();
		}

		//Verify Accounting Entries were created
		system.assert(aeList != NULL);
		system.assert(sawExceptionUpdate == true, eMsgUpdate);
		//Verify update validation
		system.assert(eMsgUpdate.Contains(System.Label.Once_a_General_Ledger_Account_has_transactions_associated_to_it_the_account_upd));				
		//Verify Delete validation 
		system.assert(sawExceptionDelete == true, eMsgDelete);
		system.assert(eMsgDelete.contains(System.Label.GLAccount_Delete_Restriction_With_Transactions));	

			

		Test.stopTest();
	}    
    public static testMethod void testRFXGLAccountInsertORUpdate(){



        TestFuel fuel = new TestFuel();    	
		GL_Type__c glType1 = fuel.expense; 
		GL_Account__c AccountB;
		GL_Account__c AccountA;		
		GL_Type__c testExpenseGLType = fuel.expense; 
        GL_Account__c glAccountRevenueA = new GL_Account__c();
		glAccountRevenueA.GL_Account_Number__c = '55001';
		glAccountRevenueA.GL_Account_Name__c = 'Revenue-A';
		glAccountRevenueA.active__c = true;
		glAccountRevenueA.Normal_Balance__c = 'Credit';
		glAccountRevenueA.Statement_Type__c = 'Income Statement';
		glAccountRevenueA.non_cash__c = false;
		glAccountRevenueA.gl_type__c = glType1.id;
		glAccountRevenueA.FX_Type__c = 'RFX';

		insert glAccountRevenueA;

        GL_Account__c glAccountRevenueB = new GL_Account__c();
		glAccountRevenueB.GL_Account_Number__c = '55002';
		glAccountRevenueB.GL_Account_Name__c = 'Revenue-B';
		glAccountRevenueB.active__c = true;
		glAccountRevenueB.Normal_Balance__c = 'Credit';
		glAccountRevenueB.Statement_Type__c = 'Income Statement';
		glAccountRevenueB.non_cash__c = false;
		glAccountRevenueB.gl_type__c = glType1.id;
		
		insert glAccountRevenueB;

		Test.startTest();


		boolean sawException = false;
		try{
	        GL_Account__c glAccountRevenueC = new GL_Account__c();
			glAccountRevenueC.GL_Account_Number__c = '55004';
			glAccountRevenueC.GL_Account_Name__c = 'Revenue-A';
			glAccountRevenueC.active__c = true;
			glAccountRevenueC.Normal_Balance__c = 'Credit';
			glAccountRevenueC.Statement_Type__c = 'Income Statement';
			glAccountRevenueC.non_cash__c = false;
			glAccountRevenueC.gl_type__c = glType1.id;
			glAccountRevenueC.FX_Type__c = 'RFX';
			
			insert glAccountRevenueC;
		
		}catch(exception e ){
			sawException = true;
				
		}
		system.assert(sawException == true);

		sawException = false;
		try{
			AccountB = [SELECT Id, name, Active__c 
												FROM GL_Account__c 
												WHERE   id =: glAccountRevenueB.id limit 1 ];
			AccountB.FX_Type__c = 'RFX';
			update AccountB;
		}catch(exception e){
			sawException = true;
		
		}						

		system.assert(sawException == true);
		
		sawException = false;
		try{
			AccountA = [SELECT Id, name, Active__c 
												FROM GL_Account__c 
												WHERE   id =: glAccountRevenueA.id limit 1 ];
			AccountA.FX_Type__c = '';
			update AccountA;
			update AccountB;
		}catch(exception e){
			sawException = true;
		
		}						

		system.assert(sawException != true);
		Test.stopTest();
	}    
	 //------------KNDY-15219----------//
    static testmethod void testGLAcctValidationOnDeleteNdInactive(){
         
        Boolean sawError                 = false;
        String errorMessage              = '';
        TestFuel fuel                    = new TestFuel();
        Period__c currPeriod             = new Period__c();
        Accounting_Rule__c  accRuleCR    = fuel.AccountingRuleList[0];
        Accounting_Rule__c  accRuleDR    = fuel.AccountingRuleList[1];
        GL_Account__c cashGl             = fuel.GLAccountTestData[0];//Cash,GL_Account_Number__c=12000,
        GL_Account__c unapplCashGl       = fuel.GLAccountTestData[1];//Unapplied Cash,GL_Account_Number__c=12100
        
        
        for(Period__C cPeriod : fuel.periodList){
            if(cPeriod.Period_Start__c < system.now() &&   system.now() <= cPeriod.Period_end__c ){
                currPeriod = cPeriod;
            }
        } 
         
        // Try to delete active GL Account without transactions
        try{
            delete cashGl;
        }
        catch(Exception cannotDeleteExp){
            sawError = true;
            errorMessage = cannotDeleteExp.getMessage();
        } 
        system.assertEquals(true, sawError);
        system.assert(errorMessage.contains('You cannot delete an active GL account.')); 
        
        //------------Reset values-------------
        cashGl             = fuel.GLAccountTestData[0];
        sawError           = false;
        errorMessage       = '' ;
        
        test.startTest();
            //---- Create a JE with cashGL and unapplCashGl-------//
                
    		Journal_Entry__c je1 = new Journal_Entry__c();
        		je1.name = 'JE001';
        	    je1.Company__c = fuel.company.id;	
        	    je1.type__c = 'Manual';   
        	    je1.Transaction_Type__c = 'Manual';
        	    je1.Transaction_Date__c = System.now();  
        		je1.Currency__c = TestFuel.currencyUSD.id; 
    		    
    		insert je1;      
    		    
    		Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
    		    jeLine1.Journal_Entry__c = je1.id;
    			jeLine1.Amount_CR__c = 5;
    			jeLine1.Amount_DR__c = 0;
    			jeLine1.GL_Account__c = cashGL.id;
    			jeLine1.Subtransaction_Type__c = 'Write Off';
    		    
    		Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
    		    jeLine2.Journal_Entry__c = je1.id;
    			jeLine2.Amount_CR__c = 0;
    			jeLine2.Amount_DR__c = 5;
    			jeLine2.GL_Account__c = unapplCashGl.id;
    			jeLine2.Subtransaction_Type__c = 'Write Off';
    			
    	    List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
    		    jeLineList.add(jeLine1); 
    		    jeLineList.add(jeLine2); 
    		insert jeLineList;
    		    je1.finalized__c = true;
    		update je1;
            
            //--------Try to delete GL account in use by JE---------------//
            try{
                delete cashGl;
            }
            catch(Exception cannotDeleteExp){
                sawError = true;
                errorMessage = cannotDeleteExp.getMessage();
            }
            
            system.assertEquals(true, sawError);
            system.assert(errorMessage.contains(Label.GLAccount_Delete_Restriction_With_Transactions)); 
             
            //------------Reset values-------------
            cashGl             = fuel.GLAccountTestData[0];
            sawError           = false;
            errorMessage       = '' ;
        
        
             ///----------Create AE with cash Gl account---------------//
        
            accRuleCR.GL_Account__c = cashGl.Id;
            accRuleCR.Default_GL_Account__c = true;
            accRuleDR.GL_Account__c = unapplCashGl.Id;
            accRuleDR.Default_GL_Account__c = true;
            
            List<Accounting_Rule__c> accRules = new List<Accounting_Rule__c>();
            accRules.add(accRuleCR); accRules.add(accRuleDR);
            update accRules;
              
            //-------generate accounting from JE page----------//
            
            List<Journal_Entry__c> jelist = new List<Journal_Entry__c>{je1};
            Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(jelist);
            setcon.setSelected(jelist);
            new JournalEntryAccountingExt(setcon).GenerateJournalEntryAccounting(); 
        test.stopTest();
        
            List<Accounting_Entry_Line__c> aels = [SELECT id , status__C, GL_Account__c ,
                                                               Has_Exceptions__c 
                                                     FROM Accounting_Entry_Line__c ];
            
        
        //------Try making GL Account inactive -----------//
        
        //------------Reset values-------------
        sawError           = false;
        errorMessage       = '' ;
        try{
            cashGl.Active__c = false;
            update cashGl;
        }
        catch(Exception cannotMakeIncativeExp){
            sawError = true;
            errorMessage = cannotMakeIncativeExp.getMessage();
        }
         
        system.assertEquals(true, sawError);
        //system.assert(errorMessage.contains(Label.Cannot_make_GL_Account_Inactive_for_an_open_period)); 
        system.assert(errorMessage.contains(System.Label.Cannot_make_GL_Account_Inactive_for_an_open_period));  
 		                              
         
        //---------Try delete cashGl which is in use by this AEL------------
        try{
            delete cashGl;
        }
        catch(Exception cannotDeleteExp){
            sawError = true;
            errorMessage = cannotDeleteExp.getMessage();
        }
        system.assertEquals(true, sawError);
        system.assert(errorMessage.contains(Label.GLAccount_Delete_Restriction_With_Transactions)); 
        
    }
	

}