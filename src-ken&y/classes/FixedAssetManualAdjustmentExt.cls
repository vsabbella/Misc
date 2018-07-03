public with sharing class FixedAssetManualAdjustmentExt {
    public Id fixedAssetId {get;set;}

    //public Fixed_Asset_Adjustment__c faa {get;set;} {faa = new Fixed_Asset_Adjustment__c();}
    public String assetName {get;set;}
    public List<Fixed_Asset_Adjustment__c> faAdjustmentsList{get;set;}
    public Apexpages.Standardcontroller con {get;set;}
    public string HelpURL{get;set;}
    public string ReturnUrl{set;} 
    public Fixed_Asset__c currentAssetRecord ;
    public Boolean notRetiredAsset {get;set{
        notRetiredAsset = true;
    }}
    
    public FixedAssetManualAdjustmentExt(ApexPages.StandardController controller) {
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpFixedAssets';
        this.con     = controller; 
        
        if(this.con == null){

            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No Fixed Asset is specified.'));
        }else{
            if(!test.isRunningTest()){
                this.con.addFields(new list<String>{'Id','Name','Company__c','Date_Last_Depreciated__c','Status__c', 
                                                    'Company__r.Default_Transaction_Currency__c','Company__r.Comp_Currency__c'  }); 
            } 
            currentAssetRecord = (Fixed_Asset__c) con.getRecord();
            fixedAssetId                      = currentAssetRecord.Id;
            assetName                         = currentAssetRecord.name;
            
            if(currentAssetRecord.Status__c=='Retired'){
                notRetiredAsset = false;
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'A retired asset cannot be adjusted.'));
            }
             
            faAdjustmentsList  = new List<Fixed_Asset_Adjustment__c> ();
            faAdjustmentsList.add(new Fixed_Asset_Adjustment__c(Fixed_Asset__c = currentAssetRecord.Id,
                                                                Company__c = currentAssetRecord.Company__c,
                                                                Currency__c = currentAssetRecord.Company__r.Comp_Currency__c));
        
        }
    } 
    public String getReturnUrl(){
        PageReference faDetailPage = new PageReference('/'+fixedAssetId);
        return faDetailPage.getUrl();
    } 
     
    public PageReference saveAdjustment(){
    
        Savepoint sp = Database.setSavepoint();
        for(Fixed_Asset_Adjustment__c faa : faAdjustmentsList){
            if(currentAssetRecord.Date_Last_Depreciated__c!=null && currentAssetRecord.Date_Last_Depreciated__c > = faa.Adjustment_Date__c){
    	        Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, 
    	                                'The '+faa.Adjustment_Date__c+' date is invalid for the fixed asset adjustment because it is in a period that has depreciation.' ));
    	        return null;
            } 
         } 
         for(Fixed_Asset_Adjustment__c faa : faAdjustmentsList){
            faa.subtransaction_type__c = faa.type__c;
            faa.transaction_date__c = datetime.newInstance(faa.adjustment_Date__c.year(), 
                                                           faa.adjustment_Date__c.month(),
                                                           faa.adjustment_Date__c.day());  
                                                   
         }
               
        try{
            DML.insertAsUser(faAdjustmentsList);
            for(Fixed_Asset_Adjustment__c faa : faAdjustmentsList){
                 faa.finalized__c = true;
            }
            DML.updateAsUser(faAdjustmentsList);
            Map<Id, Fixed_Asset_Adjustment__c> mFAAs = new Map<Id, Fixed_Asset_Adjustment__c>(faAdjustmentsList);
            //FixedAssetService.updateFixedAssetAcquisitionCost(mFAAs.keySet());
            PageReference faDetailPage = new PageReference('/'+fixedAssetId);
            return faDetailPage.setRedirect(true); 
         }
        catch(Exception cannotCreateAdjustment){
             Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(cannotCreateAdjustment.getMessage())));
             system.debug(LoggingLevel.Error, 'EXCEPTION: ' + cannotCreateAdjustment.getMessage() + ' ' + cannotCreateAdjustment.getStackTraceString());
             Database.rollback(sp);
             return null; 
         }  
             
     }
    public PageReference saveAndNew(){
      try{
          saveAdjustment();
          if(!ApexPages.hasMessages(ApexPages.Severity.ERROR)){
             PageReference faManualAdjustmentPage = new PageReference('/apex/FixedAssetManualAdjustment?id='+fixedAssetId);
   	         return faManualAdjustmentPage.setRedirect(true);     
          }else{return null;}
   	     
      }
      catch(Exception cannotCreateAdjustment){
          Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(cannotCreateAdjustment.getMessage())));
          system.debug(LoggingLevel.Error, 'EXCEPTION: ' + cannotCreateAdjustment.getMessage() + ' ' + cannotCreateAdjustment.getStackTraceString());
          return null;
      } 

    }
    
    public PageReference CancelGoBack(){
        PageReference faDetailPage = new PageReference('/'+fixedAssetId);
        return faDetailPage.setRedirect(true);
    }


}