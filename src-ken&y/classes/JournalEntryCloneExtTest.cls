@isTest
private class JournalEntryCloneExtTest {

    public class SampleData{
        public TestFuel fuel = new TestFuel();
    	public Journal_Entry__c je1;
    	public Journal_Entry__c je2;
    	public Journal_Entry__c je3;
		public List<Journal_Entry_Line__c> jeLineList;
		public List<Journal_Entry_Line__c> jeLineList1;
        public SampleData(){
            InsertJE();
        }
        public void InsertJE(){ 
		    je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = fuel.company.id;	
		    je1.type__c = 'Manual';   
		    je1.Transaction_Type__c = 'Manual';
		    je1.Transaction_Date__c = System.now();  
			je1.Currency__c = TestFuel.currencyUSD.id;
		 	insert je1;
		 	
			jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = je1.id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = je1.id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		 	insert jeLineList; 
		
		    je2 = new Journal_Entry__c();
			je2.name = 'JE001';
		    je2.Company__c = fuel.company.id;	
		    je2.type__c = 'Manual';   
		    je2.Transaction_Type__c = 'Manual';
		    je2.Transaction_Date__c = System.now();  
			je2.Currency__c = TestFuel.currencyUSD.id;
		 	insert je2;
		 	
			jeLineList1 = new List<Journal_Entry_Line__c>();
			for(integer i=1; i<10; i++){
			    Journal_Entry_Line__c jeLine = new Journal_Entry_Line__c(); 
			    jeLine.Journal_Entry__c = je2.id;
				jeLine.Amount_CR__c = 5;
				jeLine.Amount_DR__c = 0;
				jeLine.GL_Account__c = fuel.cashGL.id;
			    jeLineList1.add(jeLine); 
			
			
			}
			For(integer i=1; i<10; i++){
			    Journal_Entry_Line__c jeLine = new Journal_Entry_Line__c(); 
			    jeLine.Journal_Entry__c = je2.id;
				jeLine.Amount_CR__c = 0;
				jeLine.Amount_DR__c = 5;
				jeLine.GL_Account__c = fuel.cashGL.id;
			    jeLineList1.add(jeLine); 
			
			
			}
			insert jeLineList1;
		    je3 = new Journal_Entry__c();
			je3.name = 'JE001';
		    je3.Company__c = fuel.company.id;	
		    je3.type__c = 'Manual';   
		    je3.Transaction_Type__c = 'Manual';
		    je3.Transaction_Date__c = System.now();  
			je3.Currency__c = TestFuel.currencyUSD.id;
		 	insert je3;
        }
    }
    
    
    static testMethod void navigateToCloneTest() {
        SampleData sd = new SampleData();    	
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.je1);
        pageReference pr = page.JournalEntryCloneWithLines;
        Test.setCurrentPage(pr);
        JournalEntryCloneExt ext = new JournalEntryCloneExt(con);
        pr.getParameters().put('id',sd.je1.id);
        ext.navigateToClone();
       
        list<journal_Entry__c> JEList = [SELECT id, name from journal_Entry__c where company__c =: sd.fuel.company.id ];
        system.assert(JEList.size() == 4, JEList);
		
    }
    static testMethod void CloneChunkingTest() {
        SampleData sd = new SampleData();    	
        Apexpages.standardcontroller con2 = new Apexpages.Standardcontroller(sd.je2);
        pageReference pr = page.JournalEntryCloneWithLines;
        Test.setCurrentPage(pr);
        pr.getParameters().put('id',sd.je2.id);
        JournalEntryCloneExt ext2 = new JournalEntryCloneExt(con2);
		ext2.prepareJEClone();
		
		list<Journal_Entry_Line__c> jelist = [select id, name from Journal_Entry_Line__c where id in : sd.jeLineList1];
		system.debug('jelist ****' + jelist + '    ' +sd.je2.id);
		
	    list<Journal_Entry_Line__c> sobjMin=[select id,autonumber__c from Journal_Entry_Line__c where Journal_Entry__c =: sd.je2.id  ORDER BY autonumber__c ASC limit 1];
	    list<Journal_Entry_Line__c> sobjMax=[select id,autonumber__c from Journal_Entry_Line__c where Journal_Entry__c =: sd.je2.id ORDER BY autonumber__c DESC limit 1];
        integer minRev=(integer)integer.valueOf(sobjMin[0].get('autonumber__c'));
        integer maxRev=(integer)integer.valueOf(sobjMax[0].get('autonumber__c'));
		string min  = JournalEntryCloneExt.prefixIntWithZeros(minRev, 10);
		string max  = JournalEntryCloneExt.prefixIntWithZeros(maxRev,10);
		JournalEntryCloneExt.cloneJE(sd.je2.id,sd.je3.id,1,2,min,max);
	    Configuration__c aeconfig = new Configuration__c(name = 'cloneChunksize', value__c = '1');
	    insert aeconfig; 
		JournalEntryCloneExt.cloneJE(sd.je2.id,sd.je3.id,1,2,min,max);
        list<journal_Entry__c> JEList1 = [SELECT id, name from journal_Entry__c where company__c =: sd.fuel.company.id ];
        system.assert(JEList1.size() == 4, JEList);
    
    
    
    }
}