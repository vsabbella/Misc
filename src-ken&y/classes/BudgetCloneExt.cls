public with sharing class BudgetCloneExt {

    	public ApexPages.StandardController con;
    	public BudgetCloneExt(ApexPages.StandardController controller) {
    	this.con = controller;
    }

    public void errMsg() {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, Label.Button_Not_Available);
        ApexPages.addMessage(myMsg);
    }
    
    public PageReference overrideTask()
    {
    	PageReference page = con.cancel();
    	Task t = (Task)con.getRecord();
    	t.Status = TaskType.EXCEPTION_STATUS_OVERRIDDEN;
    	
    	try
    	{
    		DML.updateAsUser(t);
    		return page;
    	}
    	catch(System.DmlException ex)
    	{
    		for(Integer i = 0; i < ex.getNumDml(); i++) {
				Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getDmlMessage(i))));
				System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getDmlMessage(i));
			}

    		if(!Test.isRunningTest()){
    			con.reset(); //AR-68 rest the view if there is error.
    		} 
    		return null;
    	}
    	
    	catch(Exception ex)
    	{
    		Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getMessage());
    		return null;
    	}
    }
}