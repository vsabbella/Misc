@isTest
private with sharing class CustomerReceiptVoidCancelTest {
	
	public static TestFuel fuel = new TestFuel();
	//public static TestData.Accounting accting = new TestData.Accounting(fuel.company.Id);
	public static list<Accounting_Rule__c> lARs {
		
		get {
			if(lARs == null)
			{
				lARs = new list<Accounting_Rule__c>();
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				//KNDY-19379
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Writeoff Credit',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Writeoff Credit',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Writeoff',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Writeoff',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));

				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Overpayment', Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Overpayment', Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Earned Terms Discount', Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Earned Terms Discount', Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Invoice__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Chargeback', Subtransaction_Type__c = null,Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Invoice__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Chargeback', Subtransaction_Type__c = null,Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Invoice__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Overpayment', Subtransaction_Type__c = null,Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Invoice__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Overpayment', Subtransaction_Type__c = null,Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= fuel.effStartDate));
                
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Prepayment', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));

				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Overpayment', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Overpayment', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));

				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = 'Debit Applied - Claim',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = 'Debit Applied - Claim',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED,Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED,Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));

				//KNDY-16069
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = 'Prepayment Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = 'Prepayment Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = 'Overpayment Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Claim Settlement', Subtransaction_Type__c = 'Overpayment Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));

				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL, Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL, Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true, Effective_Start_Date__c= fuel.effStartDate));

				insert lARs;
			}
			
			return lARs;
		}
		
		set;
	}
	public static Customer_Receipt__c custReceipt {
		get{
			if(custReceipt == null){
				custReceipt = new Customer_Receipt__c();
				custReceipt.Company__c = fuel.company.Id;
				custReceipt.Customer__c = fuel.customerParent.Id;
				custReceipt.Date_Received__c = system.now();
				custReceipt.Type__c = 'Receipt';
				custReceipt.Currency__c = TestFuel.currencyUSD.id;
				insert custReceipt;
			}	
			return custReceipt;
		}
		set;
	}
	
	
	public static Customer_Invoice__c creditMemo {
	    get{
			if(creditMemo == null){
				creditMemo = new Customer_Invoice__c();
				creditMemo.Bill_To_Customer__c = fuel.customerBillTo.Id;
                creditMemo.Company__c = fuel.company.Id;
                creditMemo.Invoice_Type__c = 'Credit Memo';
                creditMemo.Status__c = CustomerInvoiceService.STATUS_OPEN;
                creditMemo.Date_Invoiced__c = system.now();
                creditMemo.Currency__c = custReceipt.Currency__c;
				creditMemo.Transaction_date__c = system.now();
				insert creditMemo;
				
				Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
				cil.Customer_Invoice__c = creditMemo.Id;
				cil.Quantity_Shipped__c = -1;
				cil.Unit_Price__c = 10;
				insert cil;
				
				creditMemo.Finalized__c = true;
				update creditMemo;
			
			}	
			return creditMemo;
		}
		set;
	}



    public static Customer_Receipt_Line__c writeOffCreditCRL{//KNDY-19379
        get{
            if(writeOffCreditCRL== null){
                writeOffCreditCRL = new Customer_Receipt_Line__c();
                writeOffCreditCRL.Amount__c = 10;
                writeOffCreditCRL.Customer_Receipt__c = custReceipt.Id;
                writeOffCreditCRL.Customer_Invoice__c = creditMemo.Id; 
                writeOffCreditCRL.Type__c = PaymentService.TYPE_WRITEOFF_CREDIT;
                
                insert writeOffCreditCRL;
            }   
            return writeOffCreditCRL;
        }
        set;
    }
    

    public static Customer_Receipt_Line__c writeOffCRL{//KNDY-19379
        get{
            if(writeOffCRL== null){
                writeOffCRL = new Customer_Receipt_Line__c();
                writeOffCRL.Amount__c = 10;
                writeOffCRL.Customer_Receipt__c = custReceipt.Id;
                writeOffCRL.Customer_Invoice__c = CustomerInvoice.Id; 
                writeOffCRL.Type__c = PaymentService.TYPE_WRITEOFF;
                writeOffCRL.Reason_Code__c = fuel.resolutionCode.Id;
                insert writeOffCRL;
            }   
            return writeOffCRL;
        }
        set;
    }
	public static Customer_Receipt_Line__c creditApplied {
	    get{
			if(creditApplied == null){
				creditApplied = new Customer_Receipt_Line__c();
				creditApplied.Amount__c = 10;
				creditApplied.Customer_Receipt__c = custReceipt.Id;
				creditApplied.Customer_Invoice__c = creditMemo.Id; //KNDY-13995
				creditApplied.Type__c = PaymentService.TYPE_CREDIT_MEMO;
				
				insert creditApplied;
			}	
			return creditApplied;
		}
		set;
	}
	
	public static Customer_Invoice__c CustomerInvoice {
	    get{
			if(CustomerInvoice == null){
				CustomerInvoice = new Customer_Invoice__c();
				CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
                CustomerInvoice.Company__c = fuel.company.Id;
                CustomerInvoice.Customer_Receipt__c = custReceipt.Id;
                CustomerInvoice.Invoice_Type__c = 'Manual';
                CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
                CustomerInvoice.Date_Invoiced__c = system.now();
                CustomerInvoice.Currency__c = custReceipt.Currency__c;
                CustomerInvoice.Transaction_Date__c = Date.today();
				insert CustomerInvoice;
				
				Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
				cil.Customer_Invoice__c = CustomerInvoice.Id;
				cil.Quantity_Shipped__c = 1;
				cil.Unit_Price__c = 100;
				insert cil;
				
				CustomerInvoice.Finalized__c = true;
				update CustomerInvoice;
			}	
			return CustomerInvoice;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c paymentLine {
	    get{
			if(paymentLine == null){
				paymentLine = new Customer_Receipt_Line__c();
				paymentLine.Amount__c = 100;
				paymentLine.Customer_Receipt__c = custReceipt.Id;
				paymentLine.Customer_Invoice__c = CustomerInvoice.Id;
				paymentLine.Type__c = PaymentService.TYPE_PAYMENT;
				
				insert paymentLine;
			}	
			return paymentLine;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c deductionLine {
	    get{
			if(deductionLine == null){
				deductionLine = new Customer_Receipt_Line__c();
				deductionLine.Amount__c = 100;
				deductionLine.Customer_Receipt__c = custReceipt.Id;
				deductionLine.Reason_Code__c = fuel.deductionCode.Id;
				deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
				deductionLine.Customer__c = fuel.customerBillTo.Id;
				deductionLine.Sold_To_Customer__c = fuel.customerSoldTo.Id;
				
				insert deductionLine;
			}	
			return deductionLine;
		}
		set;
	}
	
	public static Claim__c claim {
	    get{
			if(claim == null){
				claim = new Claim__c();
				claim.Company__c = fuel.company.Id;
				claim.Parent_Customer__c = fuel.customerParent.Id;
				claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
				claim.Currency__c = TestFuel.currencyUSD.id;
				claim.Amount__c = 100;
				claim.Type__c = PaymentService.TYPE_GEN_DED;
				claim.Status__c = 'Open';
				claim.Approval_Status__c = 'Approved';
				insert claim;
			}	
			return claim;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c claimPayment {
	    get{
			if(claimPayment == null){
				claimPayment = new Customer_Receipt_Line__c();
				claimPayment.Amount__c = 100;
				claimPayment.Customer_Receipt__c = custReceipt.Id;
				claimPayment.Claim__c = claim.Id;
				claimPayment.Type__c = PaymentService.TYPE_PAYMENT;
				
				insert claimPayment;
			}	
			return claimPayment;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c OverPaymentLine {
	    get{
			if(OverPaymentLine == null){
				OverPaymentLine = new Customer_Receipt_Line__c();
				OverPaymentLine.Amount__c =10;
				OverPaymentLine.Customer_Receipt__c = custReceipt.Id;
				OverPaymentLine.Type__c = PaymentService.TYPE_OVERPAYMENT;
				OverPaymentLine.Customer__c = fuel.customerBillTo.id;
				insert OverPaymentLine;
			}	
			return OverPaymentLine;
		}
		set;
	}
	
	static testMethod void notFinalized() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(CustomerInvoice.Id,null);
		system.assertNotEquals(paymentLine.Id,null);
		system.assertNotEquals(deductionLine.Id,null);
		system.assertNotEquals(claim.Id,null);
		system.assertNotEquals(claimPayment.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		
		test.StartTest();
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableVoid() == false,'Cannot void Unfinalized CRs');
			system.assert(!ext.getDisableCancel() == true,'Cannot cancel Unfinalized CRs'); //AR-143
		test.StopTest();
		
		
	}
	
	static testMethod void canCancel() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(CustomerInvoice.Id,null);
		system.assertNotEquals(paymentLine.Id,null);
		system.assertNotEquals(deductionLine.Id,null);
		system.assertNotEquals(claim.Id,null);
		system.assertNotEquals(claimPayment.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		test.StartTest();
			custReceipt.Amount_Received__c = 100;
			custReceipt.Finalized__c = true;
			update custReceipt;
			
			custReceipt = [Select id, Name, Company__c, Date_Received__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
			
			Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
        												   Bank_Account__c = fuel.bankAccount.Id);
	        insert bt;
	        
	        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
	        insert btm;
	        
	        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
	        dateTime reconciledDate = system.now();
	        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, fuel.bankAccount.id);

			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableVoid() == false,'Cannot void  CRs');
			system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
			ext.cancelDetails();
			boolean ErrorExists = false;
	        for( ApexPages.Message msg :ApexPages.GetMessages())
	        	if(msg.getDetail().contains(Label.transaction_has_been_reconciled))
	        	{
	        		ErrorExists = true;
	        		break;
	        	}
	        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		test.StopTest();
		
		
	}
	
	static testMethod void CRCancel_BTMatched() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(CustomerInvoice.Id,null);
		system.assertNotEquals(paymentLine.Id,null);
		system.assertNotEquals(deductionLine.Id,null);
		system.assertNotEquals(claim.Id,null);
		system.assertNotEquals(claimPayment.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		test.StartTest();
			custReceipt.Amount_Received__c = 100;
			custReceipt.Finalized__c = true;
			update custReceipt;
			
			custReceipt = [Select id, Name, Company__c, Date_Received__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
			
			Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
        												   Bank_Account__c = fuel.bankAccount.Id);
	        insert bt;
	        
	        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
	        insert btm;

			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableVoid() == false,'Cannot void  CRs');
			system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
			ext.cancelDetails();
			boolean ErrorExists = false;
	        for( ApexPages.Message msg :ApexPages.GetMessages())
	        	if(msg.getDetail().contains(Label.Existing_matches_will_be_deleted))
	        	{
	        		ErrorExists = true;
	        		break;
	        	}
	        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		test.StopTest();
		
		
	}
	
	static testMethod void Cancel_testAmountReceivedClaim() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(claim.Id,null);
		system.assertNotEquals(claimPayment.Id,null);
		
		test.StartTest();
			custReceipt.Amount_Received__c = 100;
			custReceipt.Finalized__c = true;
			custReceipt.Bank_Account_2__c =  fuel.bankAccount.Id;
			custReceipt.Payment_Method_G__c = 'Cash';
        	custReceipt.Reference_Number__c = '123';
			update custReceipt;
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
			
			ext.CancelDocs();
			
			custReceipt = [Select Id, Finalized__c, Status__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
			
			system.assertEquals(custReceipt.Finalized__c, false);
			system.assertEquals(custReceipt.Status__c, 'Cancelled');
			
			 claim = [Select Id, Status__c from Claim__c where Id = :claim.Id limit 1];
			system.assertEquals(claim.Status__c,'Open');
			
			PageReference pageRef = Page.CustomerReceiptCancel;
            pageRef.getParameters().put('Id', custReceipt.Id);
            Test.setCurrentPage(pageRef);
			
            ApexPages.StandardController crCancelledInst = new ApexPages.StandardController(custReceipt);
            CustomerReceiptVoidCancelExt crMngExt = new CustomerReceiptVoidCancelExt(crCancelledInst);
            system.assertEquals( Apexpages.hasMessages(), true );
            for(ApexPages.Message msg :  ApexPages.getMessages()) {
                System.assertEquals(Label.Customer_Receipt_Was_Cancelled, msg.getSummary());          
            }
		test.StopTest();
		
		
	}
	static testmethod void Cancel_testAccrualAppliedRefundCR(){
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Claim__c manualClaim = claim.clone();
		manualClaim.Source__c = 'Manual';
		manualClaim.Amount__c = 10;
		manualClaim.Type__c = '';
		insert manualClaim;
		
		//Allowance Accrual CI and CI lines
		Customer_Invoice__c aaCI = creditMemo.clone();
		aaCI.Invoice_Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		aaCI.Finalized__c = false;
		insert aaCI;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = aaCI.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -10;
    		insert cil;
    
    		aaCI.Finalized__c = true;
    		update aaCI;
    		
    		// create CR when AA CI is refunded 
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Refund';
		cr.Claim__c = manualClaim.Id;
		cr.Amount_Received__c = -10;
		insert cr;
		// create CR Lines
		Customer_Receipt_Line__c crl = creditApplied.clone();
		crl.Customer_Invoice__c = aaCI.Id; //KNDY-13995
		crl.Type__c = PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL;
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = -10;
		insert crl;

		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(aaCI.Id,null);
		system.assertNotEquals(crl.Id,null);

		test.StartTest();
		cr.Finalized__c = true;
		update cr;
			
		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c,Amount_To_Apply__c,  (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr);
			
		aacI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,0);
		system.assertEquals(aaCI.Status__c, 'Closed');
		
		manualClaim = [Select Id, Name, Status__c, Claim_Balance__c, 
				(Select Id, Name, Total_Amount__c, Customer_Invoice__c from Claim_Lines__r)
				from Claim__c where Id = :manualClaim.Id];
		system.assertEquals (manualClaim.Status__c, 'Closed', '>>> manualClaim: ' + manualClaim);
		system.assertEquals (manualClaim.Claim_Balance__c, 0, '>>> manualClaim: ' + manualClaim);
		system.assertNotEquals(manualClaim.Claim_Lines__r, null, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);
		system.assertNotEquals(manualClaim.Claim_Lines__r.size(), 0, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);

		
		// Cancel the CR
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
		ext.CancelDocs();
			
		cr = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, false);
		system.assertEquals(cr.Status__c, 'Cancelled');
		
		// Allowance Accrual CI asserts
		aaCI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,-10);
		system.assertEquals(aaCI.Status__c,'Open');
		
		manualClaim = [Select Id, Name, Status__c, Claim_Balance__c, 
				(Select Id, Name, Total_Amount__c, Customer_Invoice__c from Claim_Lines__r)
				from Claim__c where Id = :manualClaim.Id];
		system.assertEquals (manualClaim.Status__c, 'Open', '>>> manualClaim: ' + manualClaim);
		system.assertEquals (manualClaim.Claim_Balance__c, 10, '>>> manualClaim: ' + manualClaim);
		system.assertNotEquals(manualClaim.Claim_Lines__r, null, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);
		system.assertEquals(manualClaim.Claim_Lines__r.size(), 0, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);

		test.StopTest();
	}
	
	static testmethod void Cancel_testAccrualAppliedCR(){
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		
		//Allowance Accrual CI and CI lines
		Customer_Invoice__c aaCI = creditMemo.clone();
		aaCI.Invoice_Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		aaCI.Finalized__c = false;
		insert aaCI;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = aaCI.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -10;
    		insert cil;
    
    		aaCI.Finalized__c = true;
    		update aaCI;
    		
    		// create CR when AA CI is settled against claim
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Claim Settlement';
		insert cr;
		// create CR Lines
		Customer_Receipt_Line__c aaAppliedCRL = creditApplied.clone();
		aaAppliedCRL.Customer_Invoice__c = aaCI.Id; //KNDY-13995
		aaAppliedCRL.Type__c = PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED;
		aaAppliedCRL.Customer_Receipt__c = cr.Id;
		insert aaAppliedCRL;
		Customer_Receipt_Line__c debitAppliedLine = OverPaymentLine.clone();
		debitAppliedLine.Customer_Receipt__c = cr.Id;
		debitAppliedLine.Type__c = 'Debit Applied - Claim';
		insert debitAppliedLine;

		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(aaCI.Id,null);
		system.assertNotEquals(aaAppliedCRL.Id,null);
		system.assertNotEquals(debitAppliedLine.Id,null);

		test.StartTest();
		cr.Finalized__c = true;
		update cr;
			
		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
			
		aacI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,0);
		system.assertEquals(aaCI.Status__c, 'Closed');
		
		// Cancel the CR
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
		ext.CancelDocs();
			
		cr = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, false);
		system.assertEquals(cr.Status__c, 'Cancelled');
		
		// Allowance Accrual CI asserts
		aaCI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,-10);
		system.assertEquals(aaCI.Status__c,'Open');
		test.StopTest();
	}

	static testMethod void Cancel_testCreditApplied_AdditonalPayment() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		test.StartTest();
			custReceipt.Finalized__c = true;
			update custReceipt;
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
							(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r)
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			
			system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
			system.assertEquals(custReceipt.Customer_Invoices__r.size(),1);
			system.assertEquals(custReceipt.Customer_Invoices__r[0].Invoice_Type__c,PaymentService.TYPE_OVERPAYMENT);
			
			creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
			system.assertEquals(creditMemo.Balance__c,0);
			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
			
			ext.CancelDocs();
			
			custReceipt = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
			
			system.assertEquals(custReceipt.Finalized__c, false);
			system.assertEquals(custReceipt.Status__c, 'Cancelled');
			system.assertEquals(custReceipt.Customer_Invoices__r.size(),1);
			system.assertEquals(custReceipt.Customer_Invoices__r[0].Invoice_Type__c,PaymentService.TYPE_OVERPAYMENT);
			system.assertEquals(custReceipt.Customer_Invoices__r[0].Status__c,'Cancelled');
			
			creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
			system.assertEquals(creditMemo.Balance__c,-10);
			
			
		test.StopTest();
		
		
	}
	

    static testMethod void Cancel_testwriteOffCredit() //KNDY-19379
    {
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        system.assertNotEquals(custReceipt.Id,null);
        system.assertNotEquals(creditMemo.Id,null);
        system.assertNotEquals(writeOffCreditCRL.Id,null);
        test.StartTest();
            custReceipt.Finalized__c = true;
            update custReceipt;
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
                            (Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r)
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            
            system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
            
            creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
            system.assertEquals(creditMemo.Balance__c,0);
            CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
            system.assert(!ext.getDisableCancel() == true,'Cannot cancel CRs');
            
            ext.CancelDocs();
            
            custReceipt = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
            
            system.assertEquals(custReceipt.Finalized__c, false);
            system.assertEquals(custReceipt.Status__c, 'Cancelled');
            creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
            system.assertEquals(creditMemo.Balance__c,-10);
        test.StopTest();
    }


    static testMethod void Cancel_testWriteoff() //KNDY-19379
    {
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        system.assertNotEquals(custReceipt.Id,null);
        system.assertNotEquals(CustomerInvoice.Id,null);
        system.assertNotEquals(writeOffCRL.Id,null);
        test.StartTest();
            custReceipt.Finalized__c = true;
            update custReceipt;
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
                            (Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r)
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            
            system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
            
            CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
            system.assertEquals(CustomerInvoice.Balance__c,90);
            CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
            system.assert(!ext.getDisableCancel() == true,'Cannot cancel CRs');
            
            ext.CancelDocs();
            
            custReceipt = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
            
            system.assertEquals(custReceipt.Finalized__c, false);
            system.assertEquals(custReceipt.Status__c, 'Cancelled');
            CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
            system.assertEquals(CustomerInvoice.Balance__c,100);
        test.StopTest();
    }
    
	static testMethod void Cancel_testGenDed_payment() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(CustomerInvoice.Id,null);
		system.assertNotEquals(paymentLine.Id,null);
		system.assertNotEquals(deductionLine.Id,null);
		
		test.StartTest();
			custReceipt.Finalized__c = true;
			update custReceipt;
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r) , (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			
			system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
			
			CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
			system.assertEquals(CustomerInvoice.Balance__c,0);
			
			system.assertEquals(custReceipt.Claims__r.size(),1);
			system.assertEquals(custReceipt.Claims__r[0].Amount__c,100);
			
			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
			
			ext.CancelDocs();
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r) 
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			system.assertEquals(custReceipt.Finalized__c, false);
			system.assertEquals(custReceipt.Status__c, 'Cancelled');
			
			CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
			system.assertEquals(CustomerInvoice.Balance__c,100);
			
			system.assertEquals(custReceipt.Claims__r.size(),1);
			system.assertEquals(custReceipt.Claims__r[0].Status__c,'Cancelled');
			
		test.StopTest();
		
		
	}

	static testmethod void Void_testAccrualAppliedRefundCR(){
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assert(lARs.size() >0);
		
		Claim__c manualClaim = claim.clone();
		manualClaim.Source__c = 'Manual';
		manualClaim.Amount__c = 10;
		manualClaim.Type__c = '';
		insert manualClaim;
		
		//Create Allowance Accrual CI and CI lines
		Customer_Invoice__c aaCI = creditMemo.clone();
		aaCI.Invoice_Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		aaCI.Finalized__c = false;
		insert aaCI;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = aaCI.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -10;
    		insert cil;
    
    		aaCI.Finalized__c = true;
    		update aaCI;
    		
    		// create CR when AA CI is refunded 
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Refund';
		cr.Claim__c = manualClaim.Id;
		cr.Amount_Received__c = -10;
		insert cr;
		// create CR Lines
		Customer_Receipt_Line__c crl = creditApplied.clone();
		crl.Customer_Invoice__c = aaCI.Id; //KNDY-13995
		crl.Type__c = PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL;
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = -10;
		insert crl;

		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(aaCI.Id,null);
		system.assertNotEquals(crl.Id,null);
		
		cr.Finalized__c = true;
		cr.Transaction_Date__c = system.now();
		update cr;

		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
			
		aacI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,0);
		system.assertEquals(aaCI.Status__c, 'Closed');
		
		manualClaim = [Select Id, Name, Status__c, Claim_Balance__c, 
				(Select Id, Name, Total_Amount__c, Customer_Invoice__c from Claim_Lines__r)
				from Claim__c where Id = :manualClaim.Id];
		system.assertEquals (manualClaim.Status__c, 'Closed', '>>> manualClaim: ' + manualClaim);
		system.assertEquals (manualClaim.Claim_Balance__c, 0, '>>> manualClaim: ' + manualClaim);
		system.assertNotEquals(manualClaim.Claim_Lines__r, null, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);
		system.assertNotEquals(manualClaim.Claim_Lines__r.size(), 0, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);
		
		AccountingService cia = new CustomerReceiptAccounting();
		list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
		crlLines.add(crl);
		
		test.StartTest();
		cia.execute(crlLines);
			
		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
			
		system.debug(LoggingLevel.Error,'test: ae '+ cr.Accounting_Entries__r);
		system.debug([select id, subject from Task where whatId = :cr.Accounting_Entries__r.get(0).Id]);
		for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :cr.Accounting_Entries__r.get(0).Id])
		{
			system.debug(LoggingLevel.Error,'ael: '+ael);
			system.debug(LoggingLevel.Error,'ael with tasks: '+ael.Tasks);
		}
		
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
			
		ext.voidDocs();			
		cr = [Select Id, Finalized__c, Status__c, Void_Date__c from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, true);
		system.assertEquals(cr.Status__c, 'Void');
		system.assertEquals(cr.Void_Date__c.date(), System.today());
		
		// Allowance Accrual CI asserts
		aaCI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,-10);
		system.assertEquals(aaCI.Status__c,'Open');
		
		manualClaim = [Select Id, Name, Status__c, Claim_Balance__c, 
				(Select Id, Name, Total_Amount__c, Customer_Invoice__c from Claim_Lines__r)
				from Claim__c where Id = :manualClaim.Id];
		system.assertEquals(manualClaim.Status__c, 'Open', '>>> manualClaim: ' + manualClaim);
		system.assertEquals (manualClaim.Claim_Balance__c, 10, '>>> manualClaim: ' + manualClaim);
		system.assertNotEquals(manualClaim.Claim_Lines__r, null, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);
		system.assertEquals(manualClaim.Claim_Lines__r.size(), 0, '>>> manualClaim.Claim_Lines__r: ' + manualClaim.Claim_Lines__r);

		test.StopTest();
	}
	
	static testmethod void Void_testAccrualAppliedCR(){
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		system.assert(lARs.size() >0);
		
		//Create Allowance Accrual CI and CI lines
		Customer_Invoice__c aaCI = creditMemo.clone();
		aaCI.Invoice_Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		aaCI.Finalized__c = false;
		insert aaCI;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = aaCI.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -10;
    		insert cil;
    
    		aaCI.Finalized__c = true;
    		update aaCI;
    		
    		// create CR when AA CI is settled against claim
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Claim Settlement';
		insert cr;
		// create CR Lines
		Customer_Receipt_Line__c aaAppliedCRL = creditApplied.clone();
		aaAppliedCRL.Customer_Invoice__c = aaCI.Id; //KNDY-13995
		aaAppliedCRL.Type__c = PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED;
		aaAppliedCRL.Customer_Receipt__c = cr.Id;
		insert aaAppliedCRL;
		Customer_Receipt_Line__c debitAppliedLine = OverPaymentLine.clone();
		debitAppliedLine.Customer_Receipt__c = cr.Id;
		debitAppliedLine.Type__c = 'Debit Applied - Claim';
		insert debitAppliedLine;

		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(aaCI.Id,null);
		system.assertNotEquals(aaAppliedCRL.Id,null);
		system.assertNotEquals(debitAppliedLine.Id,null);
		
		cr.Finalized__c = true;
		cr.Transaction_Date__c = system.now();
		update cr;

		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
			
		aacI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,0);
		system.assertEquals(aaCI.Status__c, 'Closed');
		
		AccountingService cia = new CustomerReceiptAccounting();
		list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
		crlLines.add(aaAppliedCRL);
		crlLines.add(debitAppliedLine);
		
		test.StartTest();
		cia.execute(crlLines);
			
		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
			
		system.debug(LoggingLevel.Error,'test: ae '+ cr.Accounting_Entries__r);
		system.debug([select id, subject from Task where whatId = :cr.Accounting_Entries__r.get(0).Id]);
		for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :cr.Accounting_Entries__r.get(0).Id])
		{
			system.debug(LoggingLevel.Error,'ael: '+ael);
			system.debug(LoggingLevel.Error,'ael with tasks: '+ael.Tasks);
		}
		
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
			
		ext.voidDocs();			
		cr = [Select Id, Finalized__c, Status__c, Void_Date__c from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, true);
		system.assertEquals(cr.Status__c, 'Void');
		system.assertEquals(cr.Void_Date__c.date(), System.today());
		
		// Allowance Accrual CI asserts
		aaCI = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :aaCI.Id limit 1];
		system.assertEquals(aaCI.Balance__c,-10);
		system.assertEquals(aaCI.Status__c,'Open');
		test.StopTest();
	}
	
	static testMethod void Void_testGenDed_payment() 
	{
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(CustomerInvoice.Id,null);
		system.assertNotEquals(paymentLine.Id,null);
		system.assertNotEquals(deductionLine.Id,null);
		
			custReceipt.Finalized__c = true;
			update custReceipt;
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
			
			CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
			system.assertEquals(CustomerInvoice.Balance__c,0);
			
			system.assertEquals(custReceipt.Claims__r.size(),1);
			system.assertEquals(custReceipt.Claims__r[0].Amount__c,100);
			
			system.assert(lARs.size() >0);
			
			AccountingService cia = new CustomerReceiptAccounting();
	        list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
	        crlLines.add(paymentLine);
	        crlLines.add(deductionLine);
		test.StartTest();
	        cia.execute(crlLines);
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			
			
			system.debug('test: ae '+ custReceipt.Accounting_Entries__r);
			system.debug([select id, subject from Task where whatId = :custReceipt.Accounting_Entries__r.get(0).Id]);
			for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :custReceipt.Accounting_Entries__r.get(0).Id])
			{
				system.debug('ael: '+ael);
				system.debug('ael with tasks: '+ael.Tasks);
			}
			
			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableVoid() == true,'Can cancel CRs');
			
			ext.voidDocs();
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r) 
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			system.assertEquals(custReceipt.Finalized__c, true);
			system.assertEquals(custReceipt.Status__c, 'Void');
			
			CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
			system.assertEquals(CustomerInvoice.Balance__c,100);
			
			system.assertEquals(custReceipt.Claims__r.size(),1);
			system.assertEquals(custReceipt.Claims__r[0].Status__c,'Cancelled');
			
		test.StopTest();
		
		
	}


    static testMethod void Void_testwriteOffCredit() //KNDY-19379
    {
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        system.assertNotEquals(custReceipt.Id,null);
        system.assertNotEquals(creditMemo.Id,null);
        system.assertNotEquals(writeOffCreditCRL.Id,null);
            custReceipt.Finalized__c = true;
            update custReceipt;
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
                            (Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r)
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            
            system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
            
            creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
            system.assertEquals(creditMemo.Balance__c,0);
           
            system.assert(lARs.size() >0);
            
            AccountingService cia = new CustomerReceiptAccounting();
            list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
            crlLines.add(writeOffCreditCRL);

            test.StartTest();
            cia.execute(crlLines);
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
                            (Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            system.debug('test: ae '+ custReceipt.Accounting_Entries__r);
            system.debug([select id, subject from Task where whatId = :custReceipt.Accounting_Entries__r.get(0).Id]);
            for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :custReceipt.Accounting_Entries__r.get(0).Id])
            {
                system.debug('ael: '+ael);
                system.debug('ael with tasks: '+ael.Tasks);
            }
            
            CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
            system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
            
            ext.voidDocs();
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
                            (Select id, Status__c,Amount__c from Claims__r) 
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            system.assertEquals(custReceipt.Finalized__c, true);
            system.assertEquals(custReceipt.Status__c, 'Void');
            
            creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
            system.assertEquals(creditMemo.Balance__c,-10);
            
            test.StopTest();
    }

    static testMethod void Void_testwriteOff() //KNDY-19379
    {
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        system.assertNotEquals(custReceipt.Id,null);
        system.assertNotEquals(CustomerInvoice.Id,null);
        system.assertNotEquals(writeOffCRL.Id,null);
            custReceipt.Finalized__c = true;
            update custReceipt;
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
                            (Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r)
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            
            system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
            
            CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
            system.assertEquals(CustomerInvoice.Balance__c,90);
           
            system.assert(lARs.size() >0);
            
            AccountingService cia = new CustomerReceiptAccounting();
            list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
            crlLines.add(writeOffCRL);

            test.StartTest();
            cia.execute(crlLines);
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
                            (Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            system.debug('test: ae '+ custReceipt.Accounting_Entries__r);
            system.debug([select id, subject from Task where whatId = :custReceipt.Accounting_Entries__r.get(0).Id]);
            for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :custReceipt.Accounting_Entries__r.get(0).Id])
            {
                system.debug('ael: '+ael);
                system.debug('ael with tasks: '+ael.Tasks);
            }
            
            CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
            system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
            
            ext.voidDocs();
            
            custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
                            (Select id, Status__c,Amount__c from Claims__r) 
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
            
            system.assertEquals(custReceipt.Finalized__c, true);
            system.assertEquals(custReceipt.Status__c, 'Void');
            
            CustomerInvoice = [Select Id, Balance__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
            system.assertEquals(CustomerInvoice.Balance__c,100);
            
            test.StopTest();
    }
    
	static testmethod void Cancel_testOverpaymentAppliedonClaimSettlementCR(){ //KNDY-16069
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		
		//Overpayment CI and CI lines
		Customer_Invoice__c ci = creditMemo.clone();
		ci.Invoice_Type__c = PaymentService.TYPE_OVERPAYMENT;
		ci.Finalized__c = false;
		insert ci;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = ci.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -100;
    		insert cil;
    
    		ci.Finalized__c = true;
    		update ci;
    		
    		// create CR when CI is settled against claim
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Claim Settlement';
		insert cr;
		// create CR Lines
		List<Customer_Receipt_Line__c> crls = new List<Customer_Receipt_Line__c>();
		Customer_Receipt_Line__c opAppliedCRL = creditApplied.clone();
		opAppliedCRL.Customer_Invoice__c = ci.Id; //KNDY-13995
		opAppliedCRL.Type__c = PaymentService.TYPE_OVERPAYMENT_CREDIT;
		opAppliedCRL.Customer_Receipt__c = cr.Id;
		opAppliedCRL.Amount__c = 100;
		crls.add( opAppliedCRL);
		Customer_Receipt_Line__c debitAppliedLine = OverPaymentLine.clone();
		debitAppliedLine.Customer_Receipt__c = cr.Id;
		debitAppliedLine.Type__c = 'Debit Applied - Claim';
		debitAppliedLine.Customer_Invoice__c = null; //KNDY-13995
		debitAppliedLine.Claim__c = claim.Id;
		debitAppliedLine.Amount__c = 100;
		crls.add( debitAppliedLine);
		insert crls;

		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(ci.Id,null);
		system.assertNotEquals(opAppliedCRL.Id,null);
		system.assertNotEquals(debitAppliedLine.Id,null);

		test.StartTest();
		cr.Finalized__c = true;
		update cr;
			
		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
			
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,0);
		system.assertEquals(ci.Status__c, 'Closed');
		
		// Cancel the CR
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
		ext.CancelDocs();
			
		cr = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, false);
		system.assertEquals(cr.Status__c, 'Cancelled');
		
		// CI asserts
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,-100);
		system.assertEquals(ci.Status__c,'Open');
		test.StopTest();
	}

	static testmethod void Cancel_testPrepaymentAppliedOnClaimSettlementCR(){//KNDY-16069
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		
		//Prepayment CI and CI lines
		Customer_Invoice__c ci = creditMemo.clone();
		ci.Invoice_Type__c = PaymentService.TYPE_PREPAYMENT;
		ci.Finalized__c = false;
		insert ci;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = ci.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -100;
    		insert cil;
    
    		ci.Finalized__c = true;
    		update ci;
    		
    		// create CR when CI is settled against claim
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Claim Settlement';
		insert cr;
		// create CR Lines
		List<Customer_Receipt_Line__c> crls = new List<Customer_Receipt_Line__c>();
		Customer_Receipt_Line__c ppAppliedCRL = creditApplied.clone();
		ppAppliedCRL.Customer_Invoice__c = ci.Id; //KNDY-13995
		ppAppliedCRL.Type__c = PaymentService.TYPE_PREPAYMENT_CREDIT;
		ppAppliedCRL.Customer_Receipt__c = cr.Id;
		ppAppliedCRL.Amount__c = 100;
		crls.add( ppAppliedCRL);
		Customer_Receipt_Line__c debitAppliedLine = OverPaymentLine.clone();
		debitAppliedLine.Customer_Receipt__c = cr.Id;
		debitAppliedLine.Type__c = 'Debit Applied - Claim';
		debitAppliedLine.Customer_Invoice__c = null; //KNDY-13995
		debitAppliedLine.Claim__c = claim.Id;
		debitAppliedLine.Amount__c = 100;
		crls.add( debitAppliedLine);
		insert crls;
		
		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(ci.Id,null);
		system.assertNotEquals(ppAppliedCRL.Id,null);
		system.assertNotEquals(debitAppliedLine.Id,null);

		test.StartTest();
		cr.Finalized__c = true;
		update cr;
			
		cr = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
			
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,0);
		system.assertEquals(ci.Status__c, 'Closed');
		
		// Cancel the CR
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
		ext.CancelDocs();
			
		cr = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, false);
		system.assertEquals(cr.Status__c, 'Cancelled');
		
		// CI asserts
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,-100);
		system.assertEquals(ci.Status__c,'Open');
		test.StopTest();
	}
	
	static testmethod void Void_testOverpaymentAppliedonClaimSettlementCR(){ //KNDY-16069
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		system.assert(lARs.size() >0);
		
		//Overpayment CI and CI lines
		Customer_Invoice__c ci = creditMemo.clone();
		ci.Invoice_Type__c = PaymentService.TYPE_OVERPAYMENT;
		ci.Finalized__c = false;
		insert ci;
		
		List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = ci.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -100;
    		insert cil;
		
		cils.add(cil);
		
    		ci.Finalized__c = true;
    		update ci;
    		
    		// create CR when CI is settled against claim
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Claim Settlement';
		insert cr;
		// create CR Lines
		List<Customer_Receipt_Line__c> crls = new List<Customer_Receipt_Line__c>();
		Customer_Receipt_Line__c opAppliedCRL = creditApplied.clone();
		opAppliedCRL.Customer_Invoice__c = ci.Id; //KNDY-13995
		opAppliedCRL.Type__c = PaymentService.TYPE_OVERPAYMENT_CREDIT;
		opAppliedCRL.Customer_Receipt__c = cr.Id;
		opAppliedCRL.Amount__c = 100;
		crls.add( opAppliedCRL);
		Customer_Receipt_Line__c debitAppliedLine = OverPaymentLine.clone();
		debitAppliedLine.Customer_Receipt__c = cr.Id;
		debitAppliedLine.Type__c = 'Debit Applied - Claim';
		debitAppliedLine.Customer_Invoice__c = null; //KNDY-13995
		debitAppliedLine.Claim__c = claim.Id;
		debitAppliedLine.Amount__c = 100;
		crls.add( debitAppliedLine);
		insert crls;

		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(ci.Id,null);
		system.assertNotEquals(opAppliedCRL.Id,null);
		system.assertNotEquals(debitAppliedLine.Id,null);

		cr.Finalized__c = true;
		update cr;
			
		cr = [Select id, Name, Type__c, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
		system.assertEquals(cr.Status__c, 'Closed', cr);
		system.assertEquals(cr.Type__c, 'Claim Settlement', cr);
			
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,0);
		system.assertEquals(ci.Status__c, 'Closed');
		
		AccountingService cra = new CustomerReceiptAccounting();
		
		test.StartTest();

		cra.execute(crls);

		List<Accounting_Entry__c> acctEntry = [Select id, Name, Transaction_Type__c, Exceptions_Count__c, (Select id, Name, Customer_Receipt_Line__c,GL_Account__c, SubTransaction_Type__c from Accounting_Entry_Lines__r) 
										from Accounting_Entry__c where Customer_Receipt__c = :cr.id ];
		system.assertNotEquals(null, acctEntry);
		system.assertNotEquals(0, acctEntry.size());
		List<Accounting_Entry_Line__c> aeLines = new List<Accounting_Entry_Line__c>();
		for (Accounting_Entry__c ae: acctEntry){
			system.assertEquals(ae.Transaction_Type__c, 'Claim Settlement', ae);
			for (Accounting_Entry_Line__c ael: ae.Accounting_Entry_Lines__r){
				system.debug(LoggingLevel.Error,'ael: '+ael);
				aeLines.add(ael);
			}
		}
		List<Task> aeExceptions = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task
				where WhatId in:acctEntry or WhatId in: aeLines];
		system.debug(LoggingLevel.Error, '>>> aeExceptions: ' + aeExceptions);
		
		//cia.execute(cils);
		cr.Void_Date__c = System.now() + 10;
        update cr;
        
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
			
		ext.voidDocs();			
		cr = [Select Id, Finalized__c, Status__c from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, true);
		system.assertEquals(cr.Status__c, 'Void');
		
		// CI asserts
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,-100);
		system.assertEquals(ci.Status__c,'Open');
		
		PageReference pageRef = Page.CustomerReceiptVoid;
        pageRef.getParameters().put('Id', custReceipt.Id);
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController crInst = new ApexPages.StandardController(cr);
        CustomerReceiptVoidCancelExt crMngExt = new CustomerReceiptVoidCancelExt(crInst);
        system.assertEquals( Apexpages.hasMessages(), true );
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
          System.assertEquals(Label.Customer_Receipt_Was_Voided, msg.getSummary());          
        }
		test.StopTest();
	}

   	static testMethod void Void_CustomerReceipt_usingVoidDate() { 
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        system.assert(lARs.size() >0);
        system.assert(CustomerInvoice.id != null);
        
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
       
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(fuel.company.Id, fuel.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        List<CustomerReceiptManageExt.CustomerInvoiceWrapper> recs = (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records;
        recs[0].selected = true; 
        recs[0].customerInvoice.Amount_Applied__c = 20; 
        recs[0].customerInvoice.Memo__c = 'Test memo';
        Id customerInvoiceId = recs[0].customerInvoice.id;
        System.debug(logginglevel.error,'customerInvoiceId--->'+customerInvoiceId);
        system.assert(CustomerInvoice.Finalized__c == true, 'Customer Invoice is not finalized');
        
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        
        system.assert(OverPaymentLine.Id != null); // Makes sure that the additional payment line is created.
        JSONResult result5 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt.Id);
        system.assert(result5.total == 1, 'Additional payments count does not match: ' + result5.total);
        Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>> additionalPaymentChanges = new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>();
        additionalPaymentChanges.put('updatedRows', (List<CustomerReceiptManageExt.AdditionalPaymentWrapper>) result5.records);
        
        custReceipt.Amount_Received__c = 30;
        custReceipt.Bank_Account_2__c =  fuel.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        custReceipt.Date_Received__c = System.now() - 35;
        
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>(), 
                                    CIchanges, new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), additionalPaymentChanges);
        
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        
        list<Customer_Receipt_Line__c> crlSaved = [select id,Customer_Invoice__c,Memo__c,Type__c,Customer_Receipt__c,Finalized__c,Amount__c from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id];
        System.debug(logginglevel.error,'crlSaved-->'+crlSaved);
        system.assertEquals(3,crlSaved.size(),customerInvoiceId); // 3 CRLs created, with Type - Payment, Earned Terms Discount  and Overpayment respectively.
        
        custReceipt = [Select id, Name, Type__c, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c,Date_Received__c, Amount_UnApplied__c, Amount_Received__c, Amount_To_Apply__c, Balance__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
                             from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
        
        System.debug(logginglevel.error,custReceipt.Amount_Unapplied__c+' '+custReceipt.Amount_Received__c+' '+custReceipt.Amount_To_Apply__c+' '+custReceipt.Balance__c);
        system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
        system.assertEquals(custReceipt.Status__c, 'Closed', 'Customer Receipt is not closed'+' '+custReceipt.Amount_Unapplied__c+' '+custReceipt.Amount_Received__c+' '+custReceipt.Amount_To_Apply__c+' '+custReceipt.Balance__c);
        system.assertEquals(custReceipt.Type__c, 'Receipt', custReceipt);
        
        list<Customer_Receipt_Line__c> opCRLs = [select id,Customer_Invoice__c,Memo__c,Type__c,Customer_Receipt__c,Finalized__c,Amount__c from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id and Type__c = 'Overpayment'];
        System.debug(logginglevel.error,'opCRLs-->'+opCRLs);
        //system.assertEquals(3,crlSaved.size(),customerInvoiceId);
        
        list<Customer_Invoice__c> custInvoices = [Select Id, Balance__c,Status__c,Finalized__c,Invoice_Type__c from Customer_Invoice__c where id = :opCRLs[0].Customer_Invoice__c limit 1];
        System.debug(logginglevel.error,'custInvoices-->'+custInvoices);
        system.assertEquals(custInvoices[0].Finalized__c, true, custInvoices[0]);
        system.assertEquals(custInvoices[0].Status__c, 'Open', custInvoices[0]);
        system.assertEquals(custInvoices[0].Invoice_Type__c, 'Overpayment', custInvoices[0]);
        
        list<Customer_Invoice_Line__c> custInvoiceLines = [Select Id, Customer_Invoice__c from Customer_Invoice_Line__c where Customer_Invoice__c = :custInvoices[0].Id limit 1];
        System.debug(logginglevel.error,'custInvoiceLines-->'+custInvoiceLines);
        
        test.StartTest();
        
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Accounting_Entry_Line__c.sObjectType, Accounting_Entry__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        AccountingService cra = new CustomerReceiptAccounting(); 
        AccountingService cia = new CustomerInvoiceAccounting();    
        
        List<Accounting_Rule__c> ciAcctRules = [Select id, Name, Transaction__c, SubTransaction_Type__c, Effective_Start_Date__c, Effective_End_Date__c from Accounting_Rule__c 
                                                where Object_Name__c = 'Customer_Invoice__c' and (Transaction__c = 'Overpayment') ];
        system.debug(LoggingLevel.Error,'ciAcctRules: '+ciAcctRules);
        
        cra.execute(crlSaved);
        cia.execute(custInvoiceLines);
        
        List<Accounting_Rule__c> acctRules = [Select id, Name, Transaction__c, SubTransaction_Type__c, Effective_Start_Date__c, Effective_End_Date__c from Accounting_Rule__c 
                                                where Object_Name__c = 'Customer_Receipt__c' and (SubTransaction_Type__c = 'Payment' or SubTransaction_Type__c = 'Overpayment') ];
        system.debug(LoggingLevel.Error,'acctRules: '+acctRules);

        List<Accounting_Entry__c> acctEntry = [Select id, Name, Transaction_Type__c, Exceptions_Count__c, (Select id, Name, Customer_Receipt_Line__c,GL_Account__c, SubTransaction_Type__c, Transaction_Date__c, Has_Exceptions__c, Accounting_Code__c, Accounting_Rule__c from Accounting_Entry_Lines__r) 
                                        from Accounting_Entry__c where Customer_Receipt__c = :custReceipt.id ];
        system.assertNotEquals(null, acctEntry);
        system.assertNotEquals(0, acctEntry.size());
        
        List<Accounting_Entry_Line__c> aeLines = new List<Accounting_Entry_Line__c>();
        for (Accounting_Entry__c ae: acctEntry){
            system.assertEquals(ae.Transaction_Type__c, 'Receipt', ae);
            system.debug(LoggingLevel.Error,'ae: '+ae);
            for (Accounting_Entry_Line__c ael: ae.Accounting_Entry_Lines__r){
                system.debug(LoggingLevel.Error,'ael: '+ael);
                aeLines.add(ael);
            }
        }
        
        List<Task> aeExceptions = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task
                                          where WhatId in:acctEntry or WhatId in: aeLines];
        system.debug(LoggingLevel.Error, '>>> aeExceptions: ' + aeExceptions);
        
        custReceipt.Void_Date__c = System.now() - 10;
        update custReceipt;
        
        CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
        system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
            
        ext.voidDocs();  
               
        delete configList;
        
        //CR Asserts
        custReceipt = [Select Id, Finalized__c, Status__c, Void_Date__c, Date_Received__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
        system.assertEquals(custReceipt.Finalized__c, true);
        system.assertEquals(custReceipt.Status__c, 'Void');
        system.assertEquals(custReceipt.Void_Date__c.date(), System.today() - 10);
        
        // CI Asserts
        list<Customer_Invoice__c> custInvs = [Select Id, Balance__c,Status__c,Finalized__c,Invoice_Type__c,Void_Date__c from Customer_Invoice__c where id = :opCRLs[0].Customer_Invoice__c limit 1];
        System.debug(logginglevel.error,'custInvs-->'+custInvs);
        system.assertEquals(custInvs[0].Finalized__c, true, custInvs[0]);
        system.assertEquals(custInvs[0].Status__c, 'Void', custInvs[0]);
        system.assertEquals(custInvs[0].Void_Date__c.date(), System.today() - 10);
        
        test.StopTest();
    } 
    
	static testmethod void Void_testPrepaymentAppliedOnClaimSettlementCR(){//KNDY-16069
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		system.assertNotEquals(custReceipt.Id,null);
		system.assertNotEquals(creditMemo.Id,null);
		system.assertNotEquals(creditApplied.Id,null);
		system.assertNotEquals(OverPaymentLine.Id,null);
		system.assert(lARs.size() >0);
		
		//Prepayment CI and CI lines
		Customer_Invoice__c ci = creditMemo.clone();
		ci.Invoice_Type__c = PaymentService.TYPE_PREPAYMENT;
		ci.Finalized__c = false;
		insert ci;
    		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    		cil.Customer_Invoice__c = ci.Id;
    		cil.Quantity_Shipped__c = 1;
    		cil.Unit_Price__c = -100;
    		insert cil;
    
    		ci.Finalized__c = true;
    		update ci;
    		
    		// create CR when CI is settled against claim
		Customer_Receipt__c cr = custReceipt.clone();
		cr.Type__c = 'Claim Settlement';
		insert cr;
		// create CR Lines
		List<Customer_Receipt_Line__c> crls = new List<Customer_Receipt_Line__c>();
		Customer_Receipt_Line__c ppAppliedCRL = creditApplied.clone();
		ppAppliedCRL.Customer_Invoice__c = ci.Id; //KNDY-13995
		ppAppliedCRL.Type__c = PaymentService.TYPE_PREPAYMENT_CREDIT;
		ppAppliedCRL.Customer_Receipt__c = cr.Id;
		ppAppliedCRL.Amount__c = 100;
		crls.add( ppAppliedCRL);
		Customer_Receipt_Line__c debitAppliedLine = OverPaymentLine.clone();
		debitAppliedLine.Customer_Receipt__c = cr.Id;
		debitAppliedLine.Type__c = 'Debit Applied - Claim';
		debitAppliedLine.Customer_Invoice__c = null; //KNDY-13995
		debitAppliedLine.Claim__c = claim.Id;
		debitAppliedLine.Amount__c = 100;
		crls.add( debitAppliedLine);
		insert crls;
		
		system.assertNotEquals(cr.Id,null);
		system.assertNotEquals(ci.Id,null);
		system.assertNotEquals(ppAppliedCRL.Id,null);
		system.assertNotEquals(debitAppliedLine.Id,null);

		cr.Finalized__c = true;
		update cr;
			
		cr = [Select id, Name, Type__c,Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
							 from Customer_Receipt__c where id = :cr.Id limit 1 ];
		system.assertEquals(cr.Finalized__c, true, cr.Customer_Receipt_Lines__r + ' '+cr.Amount_unapplied__c);
		system.assertEquals(cr.Status__c, 'Closed', cr);
		system.assertEquals(cr.Type__c, 'Claim Settlement', cr);

		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,0);
		system.assertEquals(ci.Status__c, 'Closed');
		
		AccountingService cia = new CustomerReceiptAccounting();
		
		test.StartTest();
		cia.execute(crls);
		List<Accounting_Entry__c> acctEntry = [Select id, Name, Transaction_Type__c, Exceptions_Count__c, (Select id, Name, Customer_Receipt_Line__c,GL_Account__c, SubTransaction_Type__c from Accounting_Entry_Lines__r) 
										from Accounting_Entry__c where Customer_Receipt__c = :cr.id ];
		system.assertNotEquals(null, acctEntry);
		system.assertNotEquals(0, acctEntry.size());
		List<Accounting_Entry_Line__c> aeLines = new List<Accounting_Entry_Line__c>();
		for (Accounting_Entry__c ae: acctEntry){
			system.assertEquals(ae.Transaction_Type__c, 'Claim Settlement', ae);
			for (Accounting_Entry_Line__c ael: ae.Accounting_Entry_Lines__r){
				system.debug(LoggingLevel.Error,'ael: '+ael);
				aeLines.add(ael);
			}
		}
		List<Task> aeExceptions = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task
				where WhatId in:acctEntry or WhatId in: aeLines];
		system.debug(LoggingLevel.Error, '>>> aeExceptions: ' + aeExceptions);
		
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(cr));
		system.assert(!ext.getDisableVoid() == true,'Cannot void CRs');
			
		ext.voidDocs();			
		cr = [Select Id, Finalized__c, Status__c from Customer_Receipt__c where id = :cr.Id limit 1];
		system.assertEquals(cr.Finalized__c, true);
		system.assertEquals(cr.Status__c, 'Void');
		
		// Allowance Accrual CI asserts
		ci = [Select Id, Balance__c,Status__c from Customer_Invoice__c where id = :ci.Id limit 1];
		system.assertEquals(ci.Balance__c,-100);
		system.assertEquals(ci.Status__c,'Open');
		test.StopTest();
	}
}