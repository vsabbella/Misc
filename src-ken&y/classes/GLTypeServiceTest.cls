@isTest
public with sharing class GLTypeServiceTest {

    public class SampleData{
         
        public GL_Type__c glt1, glt2, glt3;
        
        public list<GL_Type__c> glTypeList = new list<GL_Type__c>();{ 
        
        	glt1 = new gl_type__c();
        	glt1.Name  = 'Cost of Goods Sold';
        	glt1.Normal_Balance__c  = 'Debit';
        	glt1.Accounting_Type__c  = 'Cost of Goods Sold';
        	glt1.Statement_Type__c  = 'Income Statement';
        	glt1.Account_Range_From__c = '1';
        	glt1.Account_Range_To__c ='4';
        	glTypeList.add(glt1);
        
        	glt2  = new gl_type__c();
        	glt2.Name  = 'Other Expenses';
        	glt2.Normal_Balance__c  = 'Debit';
        	glt2.Accounting_Type__c  = 'Other Income (Expense)';
        	glt2.Statement_Type__c  = 'Income Statement';
        	glt2.Account_Range_From__c = '6';
        	glt2.Account_Range_To__c = '7';
         	glTypeList.add(glt2);
         	
        	glt3  = new gl_type__c();
        	glt3.Name  = 'Other Income';
        	glt3.Normal_Balance__c  = 'Credit';
        	glt3.Accounting_Type__c  = 'Other Income (Expense)';
        	glt3.Statement_Type__c  = 'Income Statement';
        	glt3.Account_Range_From__c = '8';
        	glt3.Account_Range_To__c = '9';
         	glTypeList.add(glt3);
         	
         	insert glTypeList;
         	
        }
        
        
	}

	public static testMethod void testvalidateGLTypeWithGLTypeRange(){
	    
	    sampleData sd = new SampleData();
	    List<gl_Type__c> glTypeList = sd.glTypeList;
	   	system.assert(sd.glt3 != null,sd.glt3);
	    Boolean sawException = false;
	    String eMsg;
	    try{
	    	sd.glt2.Account_Range_From__c = '2';
	    	update sd.glTypeList[1];
	    	
	    }catch(exception e){
	    
	    	sawException = true;
	    	eMsg = e.getMessage();
	    
	    }
	    system.assert(sawException == true, eMsg);
	    system.assert(eMsg.contains('This GL Type has  Account Range From, which falls in range that has been used earlier') , eMsg);
	    
	    
	}
	    
	public static testMethod void testvalidateGLTypeWithGLAccount(){
		
		sampleData sd = new SampleData();
		system.assert(sd.glt1 != null,sd.glt1);
		gl_Account__c glAccount = new GL_Account__c();
    	glAccount.Name  = '4 - Accounts Receivable';
    	glAccount.GL_Account_Number__c = '4';
    	glAccount.gl_type__c  = sd.glt1.id;
     	insert glAccount;
     	
	    Boolean sawException = false;
	    String eMsg;
	    try{
	    	sd.glt1.Account_Range_From__c = '1';
	    	sd.glt1.Account_Range_To__c = '5';
	    	update sd.glTypeList[0];
	    	
	    }catch(exception e){
	    	sawException = true;
	    	eMsg = e.getMessage();
	    }
	    system.assert(sawException != true,eMsg);
	    system.assert(eMsg == null , eMsg);
	    list<gl_type__c> gltypelist = [select id, Account_Range_To__c from gl_type__c where id= : sd.glt1.id];
	    system.assert(gltypelist[0].Account_Range_To__c == '5', 'Account Range to should be changed');
	    
	    try{
	    	sd.glt1.Account_Range_From__c = '1';
	    	sd.glt1.Account_Range_To__c = '3';
	    	update sd.glTypeList[0];
	    	
	    }catch(exception e){
	    	sawException = true;
	    	eMsg = e.getMessage();
	    }
	    system.assert(sawException = true,eMsg);
	    system.assert(eMsg != null , eMsg);
	}
	    
	public static testMethod void testvalidateGLTypeDeleteWithGLAccount(){
	
		sampleData sd = new SampleData();
		
		gl_Account__c glAccount = new GL_Account__c();
    	glAccount.Name  = '8A - Accounts Receivable';
    	glAccount.GL_Account_Number__c = '8A';
    	glAccount.gl_type__c  = sd.glt3.id;
     	insert glAccount;
     	
	    system.assert(sd.glt3 != null,sd.glt3);
	    
	    Boolean sawException = false;
	    String eMsg;
	    
	    try{
	    	delete sd.glt3;
	    	
	    }catch(exception e){
	   		sawException = true;
	    	eMsg = e.getMessage();
	    	
	    }
	    system.assert(sawException == true, eMsg);
	    system.assert(eMsg.contains('You Cannot Delete GL Type because one or more GL Accounts are associated with this GL type') , eMsg);
	}
	    
		    
		    
		    
	
}