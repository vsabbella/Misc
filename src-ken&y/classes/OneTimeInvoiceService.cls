public with sharing class OneTimeInvoiceService {
	


	public static final string ITEMSOURCE_FEE = 'One Time Charge';
    public static List<String> statusList = new List<String>{'Pending Approval','Rejected','Revised'};

	public class OneTimeInvoiceServiceException extends Exception{}
	public static list<Agreement__c> lAgreements;
	public static map<Id, CustomerInvoiceWrapper> mAgreement2Invoices = new map<Id, CustomerInvoiceWrapper>();
	public static map<Id,string> validateInvoiceCreate(set<id> sAgreementIDs) {
		map<Id,string> errorResponses = new map<Id,string>();
		
		getAgreementsForDownpayment(sAgreementIds); //loads lAgreements;
		
		list<Customer_Invoice__c> lCIs = new list<Customer_Invoice__c>();
		if(!lAgreements.isEmpty()) {
			//Check if Status is Approved
			//Check if Start Date is present/past date
			//Check if its not already invoiced. 
			system.debug('lAgreements '+lAgreements);
			for(Agreement__c ag : lAgreements) {
				if(ag.Status__c != 'Approved') {
					errorResponses.put(ag.Id, 'Cannot invoice if agreement is not approved');
				}else if(ag.Start_Date__c > system.now()) {
					errorResponses.put(ag.Id, 'Cannot invoice before agreement start date');
				}else if(ag.Agreement_Lines__r.size() == 0) {
					errorResponses.put(ag.Id, 'Cannot invoice as there is no agreement line tied to a fee item');
				}else if(ag.Customer_Invoices__r.size() > 0) {
					lCIs.addAll(ag.Customer_Invoices__r);
				}else
					continue;
			}
            //system.debug('sAgreementIDs'+sAgreementIDs);  
            Map<Id, Agreement_Line__c> mAgreementLines = new  Map<Id, Agreement_Line__c>();
            for(Agreement__c ag:lAgreements){
              for(Agreement_Line__c agl : ag.Agreement_Lines__r){
                  mAgreementLines.put(agl.id, agl) ; 
                }  
            }
            
           
         

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            //V1
            SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Agreement__c'
            });
            soql.setWhereClause('Product__r.Item__r.Source__c = :ITEMSOURCE_FEE AND Revision_Status__c NOT IN :statusList AND agreement__c in :sAgreementIDs AND Id in (Select agreement_Line__c from Customer_Invoice_Line__c where Customer_Invoice__r.Agreement__c in :sAgreementIds AND Customer_Invoice__r.Status__c in (\'Open\',\'Closed\'))');
            list<Agreement_Line__c> aglList2 = Database.query(soql.getQuery());





            set<id> aglSet2 = KSE.grepIdSetFromList( aglList2);  
            //system.debug('aglSet2'+aglSet2);
            if(mAgreementLines.keySet() == aglSet2){
                for(Agreement_Line__c al:mAgreementLines.values() ){
                     errorResponses.put(al.Agreement__c, 'All Agreement lines are  invoiced: ');   
                   
                }
            }
			
		}
		
	    
	    return errorResponses;
	    
	}
	
	public static void getAgreementsForDownpayment(set<id> sAgreementIDs) {
        
        if(lAgreements == null){
			

                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                //V2
                SOQLUtil soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id','Name','Status__c','Start_Date__c','Currency__c','Customer__c','Sold_To__c','Bill_To__c','Customer__r.Parent_Customer__c',
                    'Customer__r.Parent_Customer__r.Parent_Customer__c','Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c',
                    'Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c','Company__c','Customer__r.RecordType.DeveloperName',
                    'Customer__r.Top_Parent_Customer__c'
                });
                soql.setWhereClause('Id in :sAgreementIds');
                SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoices__r');
                childRel1.addFields(new set<string>{
                    'Id','Finalized__c','Status__c','Void__c'
                });
                childRel1.setWhereClause('Status__c = \'Open\' and Finalized__c = true');
                soql.addChildRelationship(childRel1);
                SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Agreement_Lines__r');
                childRel2.addFields(new set<string>{
                    'ID','Name','Product__c','Product__r.Item__r.Source__c','Agreement_Price__c','agreement__c','Sales_Agreement_Quantity__c'
                });
                childRel2.setWhereClause('Product__r.Item__r.Source__c = :ITEMSOURCE_FEE AND Revision_Status__c NOT IN :statusList');
                soql.addChildRelationship(childRel2);
                lAgreements = (Database.query(soql.getQuery()));
        }
	    
	}
	
	
	
	public static void createDownpaymentInvoices(set<id> sAgreementIDs) {
		map<id,Customer_Invoice__c> mAgreement2CI = new map<id,Customer_Invoice__c>();
		list<Customer_Invoice_Line__c>lCILs = new list<Customer_Invoice_Line__c>();
		list<Customer_Invoice__c> FinalizeCIs = new list<Customer_Invoice__c>();
		getAgreementsForDownpayment(sAgreementIds); //loads lAgreements;
		
		for(Agreement__c ag : lAgreements) {
			system.debug('ag.parentcustomer '+ag.Customer__r.Parent_Customer__c);
			system.debug('ag.parentcustomer '+ag.Customer__r.RecordType.DeveloperName);
			Customer_Invoice__c ci = new Customer_Invoice__c();
			ci.Status__c = 'Open';
			ci.Company__c = ag.Company__c;
			ci.Customer__c = ag.Customer__c;
			ci.Bill_to_Customer__c = ag.Bill_To__c;
			ci.Sold_to_Customer__c = ag.Sold_To__c;
            ci.Invoice_Type__c = 'Standard';
            ci.Currency__c = ag.Currency__c;
            ci.Date_Invoiced__c = system.now();
            ci.Transaction_Date__c = system.now();
            ci.Company__c = ag.Company__c;
            ci.Agreement__c = ag.Id;
			
			mAgreement2Invoices.put(ag.Id, new CustomerInvoiceWrapper(ci));
		}
		
		if(!mAgreement2Invoices.isEmpty()) {
			try {
				
				for(Agreement__c ag : lAgreements) {
					if(mAgreement2Invoices.containsKey(ag.Id)) {

                     
                        /*
                        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                        */
                        //V1
                        SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
                        soql.addFields(new set<string>{
                            'Id','Product__c','Agreement_Price__c','Sales_Agreement_Quantity__c'
                        });
                        soql.setWhereClause('Product__r.Item__r.Source__c = :ITEMSOURCE_FEE AND Revision_Status__c NOT IN :statusList AND agreement__c in :sAgreementIDs AND Id not in (Select agreement_Line__c from Customer_Invoice_Line__c where Customer_Invoice__r.Agreement__c in :sAgreementIDs and Customer_Invoice__r.Status__c in (\'Open\',\'Closed\'))');
                        for(Agreement_Line__c agl : Database.query(soql.getQuery())){
                            
						//for(Agreement_Line__c agl : ag.Agreement_Lines__r) {
							Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
							//cil.Customer_Invoice__c = mAgreement2Invoices.get(ag.Id).ciId;
							cil.Company__c = ag.Company__c;
							cil.Product__c = agl.Product__c;
							cil.Unit_Price__c = agl.Agreement_Price__c;
							cil.Quantity_Shipped__c = agl.Sales_Agreement_Quantity__c;
                            cil.agreement_line__c = agl.id;
							CustomerInvoiceWrapper wr = mAgreement2Invoices.get(ag.Id);
							wr.lCILs.add(new CustomerInvoiceLineWrapper(cil));
						}
						
					}
				}
				
				
					
				
			}catch(Exception ex) {
				//Database.rollback(sp);
				throw new OneTimeInvoiceServiceException(ex.getMessage());
				//return null;
			}
			
		}
	}
	
	public static list<Customer_Invoice__c> saveWrapper(list<CustomerInvoiceWrapper> wrappers) {
		
		list<Customer_Invoice__c> lCIs = new list<Customer_Invoice__c>();
		list<Customer_Invoice_Line__c> lCILines = new list<Customer_Invoice_Line__c>();
		list<Customer_Invoice__c> finalizeCIs = new list<Customer_Invoice__c>();
		if(!wrappers.isEmpty()) {
			for(CustomerInvoiceWrapper wrapper : wrappers) {
				lCIs.add(wrapper.ci);
			}
			
			if(!lCIs.isEmpty()) {
				Savepoint sp = Database.setSavepoint();
				try {
					DML.insertAsUser(lCIs);
					for(CustomerInvoiceWrapper wr : wrappers) {
						for(CustomerInvoiceLineWrapper cilW : wr.lCILs) {
                            if(cilW.selected){
                            cilW.cil.Customer_Invoice__c = wr.ci.Id; 
							lCILines.add(cilW.cil); 
                            }

						}
					}
					
					if(!lCILines.isEmpty()) {
						DML.insertAsUser(lCILines);
						for(Customer_Invoice__c ci : lCIs) {
							finalizeCIs.add(new Customer_Invoice__c(Id = ci.Id, Finalized__c = true));
						}
						if(!finalizeCIs.isEmpty())
							DML.updateAsUser(finalizeCIs);
					}
					
				}catch(Exception ex) {
					Database.rollback(sp);
					system.debug('ex '+ex.getMessage());
					system.debug('ex '+ex.getStackTraceString());
					throw new OneTimeInvoiceServiceException(ex.getMessage());
					return null;
				}
			}
			
		}
		
		return finalizeCIs;
	}
	
	
	public class CustomerInvoiceWrapper {
		
		public Customer_Invoice__c ci {get;set;}
		public list<CustomerInvoiceLineWrapper> lCILs{get;set;}
		public CustomerInvoiceWrapper(Customer_Invoice__c ci) {
			this.ci = ci;
			this.lCILs = new list<CustomerInvoiceLineWrapper>();
		}
        
		public CustomerInvoiceWrapper() {}
		
	}
    
    public class CustomerInvoiceLineWrapper {
		
		public Customer_Invoice_Line__c cil {get;set;}
		public boolean selected {get;set;}
		public CustomerInvoiceLineWrapper(Customer_Invoice_Line__c cil) {
			this.cil = cil;            
		}
        
		public CustomerInvoiceLineWrapper() {}
		
	}
    

}