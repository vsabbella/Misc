public with sharing class FixedAssetRetireExt {
	
	public Apexpages.Standardcontroller faCon {get;set;}
	public string selectedRetirement {get;set;}
	public Fixed_Asset__c tmpFixedAsset {get;set;} {tmpFixedAsset = new Fixed_Asset__c();}
	public Fixed_Asset_Depreciation__c fad {get;set;} {fad = new Fixed_Asset_Depreciation__c();}
	public boolean isError {get;set;} { isError = false ;}
	public boolean isActive;
	public Fixed_Asset__c fa ;
	public Boolean disp_flag {get;set;} 
    public List<Serial__c> serialsLinkedToAsset ;
    public Boolean allowRetire = true;
    public List<Fixed_Asset_Depreciation__c> fadsForCurrentFA ; 
    public String reasonToBlock='';
	public List<Period__c> allPeriods;
    public Map<Id, List<Period__c>> companyPeriodMap ; 
    public Period__c current_Period = null;
    public Integer count = 0;
    public Boolean hasDepInCurrentPeriod = true;
		       
    
	public FixedAssetRetireExt(Apexpages.Standardcontroller controller){
		faCon = controller;
		fa = (Fixed_Asset__c)faCon.getRecord();
		fad.Fixed_Asset__c = fa.Id;
		String FAssetID    = fa.Id ;
		tmpFixedAsset.GL_Account__c = fa.Asset_Class__r.Depreciated_GL_Account__c;
		companyPeriodMap = PeriodService.getAllPeriodsMap(new Set<ID>{fa.company__c});
        
        //-------Check if the current Asset is depreciated---------------//
		SOQLUtil fadSOQL = new SOQLUtil('Fixed_Asset_Depreciation__c', true); //enforceFLS=true, running in user mode
        fadSOQL.addFields(new set<string>{
        	'id','Depreciation_Date__c'
        });
        fadSOQL.setWhereClause('Fixed_Asset__c =:FAssetID');
        fadSOQL.setOrderByClause('name ASC'); 
        fadsForCurrentFA = Database.query(fadSOQL.getQuery());
		
		//-------Check if the current Asset is linked to a Serial Number---------------//
	    SOQLUtil serialSOQL = new SOQLUtil('Serial__c', true); //enforceFLS=true, running in user mode
        serialSOQL.addFields(new set<string>{
        	'id','Name','SKID__c'
        });
        serialSOQL.setWhereClause('Fixed_Asset__c =:FAssetID');
        serialsLinkedToAsset = Database.query(serialSOQL.getQuery());
 
	    validateFixedAsset();
	}
	
	public List<SelectOption> retirementOptions{
		get{
			return new List<SelectOption>{new SelectOption('', '-Select One-'),
			new SelectOption('Sold', Label.Sold), new SelectOption('Abandoned', Label.Abandoned)};
		}
		private set;
	}
	 
	
	public void validateFixedAsset(){
	    disp_flag = false;
	    reasonToBlock='';  
	    allowRetire = true;
	    Fixed_Asset_Depreciation__c lastDepRec ; 
	    
	    if(fa.Retirement_Type__c=='Return to Inventory'){
	           isError = false;
	           fa.Disposition_Action__c = 'Sold';
	   
	           if(fa.Disposition_Action__c == 'Sold'){
	             disp_flag = true;
	           } 
	           //-----Check if   Asset is   Serial Tracked------------//
	           if(serialsLinkedToAsset == null || serialsLinkedToAsset.size() == 0){
	             allowRetire = false ;
	             reasonToBlock += 'This Asset is not Serial Tracked. ';
	           }
	           //-----Check if the Asset is depreciated-----------//
        	   if(fadsForCurrentFA.size()==0){
                 allowRetire = false;
                 reasonToBlock+= 'This  asset has no depreciations. ';
                    
        	   }
        	   if(fadsForCurrentFA.size()>0){
                    lastDepRec = fadsForCurrentFA[fadsForCurrentFA.size()-1];
        	        if(fa.disposition_date__c <lastDepRec.Depreciation_Date__c.toStartOfMonth()){
        	             allowRetire = false ;
        	             reasonToBlock  =   'You cannot retire an asset in a period prior to the most recent depreciation. ';
        	        } 
        	     }
        	    allPeriods = companyPeriodMap.get(fa.company__c);
        	   
        		if(allPeriods!=null){
        		   for(Period__c eachPeriod:allPeriods){ 
        			if(eachPeriod.Period_Start__c < = fa.disposition_date__c && fa.disposition_date__c < eachPeriod.Period_End__c  ){
        				current_Period = eachPeriod;
        			}
        		   }  
        		}
        	 	
        		if(current_Period==null){
        		     allowRetire = false ;
        		     reasonToBlock+=   'Period not defined for the date specified for disposition date. ';
        		    
        	    } 
        	    //------Make sure FAD exists and it is not a Capitalized record-------/
        	    if(fadsForCurrentFA.size()>0 && fa.Total_Depreciated_Value__c>0 && current_Period!=null){
        	        for(Fixed_Asset_Depreciation__c eachFAD:fadsForCurrentFA){
        	            
        	            if(current_Period.Period_Start__c <=  eachFAD.depreciation_date__c && 
        	                             eachFAD.depreciation_date__c  < current_Period.Period_End__c){
        	                count = count+1; 
        	            }
        	        }
        	    } 
        	    if(fadsForCurrentFA.size()>0 
        	                        && count==0 
        	                        &&  fa.disposition_date__c >=  lastDepRec.Depreciation_Date__c.toStartOfMonth() ){
        	         allowRetire = false ;
        	         reasonToBlock+= 'An asset cannot be returned to inventory if the '+
        	                        'Disposition Date is in a period that has not been depreciated. ';
        	         
        	    }  
	          
	    } 
		if(fa.status__c == FixedAssetService.STATUS_RETIRED ){
			isError = true;
			isActive = false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, 
			                Label.This_asset_has_already_been_retired));
		}
		else if(fa.Status__c != FixedAssetService.STATUS_DEPRECIATED 
		                && fa.Status__c != FixedAssetService.STATUS_RETIRED && fa.Retirement_Type__c=='Retire'){
			isError = true;
			isActive = true;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR,
			                    Label.This_asset_has_not_been_depreciated_check_the_asset_status+
			                       'The assets book value is not equal to its residual value'));
	    //FIN-1125 Security Scanner Bulkify apex methods			
		}else if( FixedAssetService.checkUnretiredChildren( new list<Fixed_Asset__c>{fa} ) && fa.Retirement_Type__c=='Retire' ){
			isError = true;
			isActive = true; 
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, 
			                                    Label.This_asset_has_children_that_have_not_been_retired_yet));
		}
		else{
			isActive = false;
		}
	}
	//FIN-1125 Security Scanner Bulkify apex methods
	public boolean retireAsset(list<Fixed_Asset__c> faList){
		boolean isSuccess = true;
		try{
	 		FixedAssetService.retireFixedAssets(new Map<Id, List<Fixed_Asset__c>>{ tmpFixedAsset.GL_Account__c => faList});
		}
		catch(Exception ex){
			isSuccess = false;
			isError = true;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
		return isSuccess;
	}
	
	public pageReference btn_Retire(){
		boolean isSuccess = false;
		pageReference newPage = null;
		validateFixedAsset();
		
		if(tmpFixedAsset.GL_Account__c != null 
		                    && fa.Disposition_Action__c != null 
		                    && fa.disposition_date__c   != null
		                    && fa.Retirement_Type__c    != null){
		                        
		    if(fa.Retirement_Type__c=='Retire'){ 
		        isSuccess = retireAsset(new list<fixed_Asset__c>{fa});
		         newPage = faCon.view();     
		    }
		    else if(fa.Retirement_Type__c=='Return to Inventory'){
		         
		       Savepoint sp     = Database.setSavepoint() ;    
		       if(allowRetire == false){
		           
	               Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR,
	                        'Cannot allow retire for one or more, REASON/s: '+reasonToBlock));
            } else {
                try {
                    if (serialsLinkedToAsset.size() > 0) {
                        SOQLUtil skidQuery = new SOQLUtil('SKID__c',true);
                        skidQuery.addAllCustomFields();
						skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
                        skidQuery.addFields(new set<String>{'Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__c', 'Facility2__r.Facility_Identifier__c'});
                        skidQuery.setWhereClause('Id = \'' + serialsLinkedToAsset[0].SKID__c + '\'');
                        SKID__c currentSKID = Database.query(skidQuery.getQuery());

        				   	 //--------Update the SKID---------//
        				   	 assetToInventory(currentSKID,serialsLinkedToAsset);
        				   	 //------Retire Asset----------------------//
            			     retireAsset(new list<fixed_Asset__c>{fa}); 
            			     //------Update Book value on Asset--------//
    	                     serialsLinkedToAsset[0].Book_Value__c = fa.Book_Value__c;
    	                     Dml.updateAsUser(serialsLinkedToAsset);
            			     newPage = faCon.view();        
		                }
		                
			        }
			        catch(Exception cannotRetireAsset){
			           
			            Database.rollback(sp);
			            newPage = null;
			           	Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR,
            	      	        'CannotRetireAsset  REASON: '+ MessageUtil.toFriendlyErrorMessage(cannotRetireAsset.getMessage())));
            	      	system.debug('CannotRetireAsset, REASON: '+ 
            	      	                cannotRetireAsset.getMessage() +' '+cannotRetireAsset.getStackTraceString()); 
			        }
                } 
                	 
		  }//-------Return to Inventory
		}else{
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, 
			            'You must select a GL Account, Disposition Date, Disposition Action and Retirement Type to retire an asset. '));

		}
		return newPage;
	}
	
	private void assetToInventory(SKID__c currentSKID,List<Serial__c> currentSerialList){
	   List<SkidService3.SerialWrapper> serialWrapperList = new List<SkidService3.SerialWrapper>();
	   currentSKID.Rental__c         = false;
       currentSKID.Used__c           = true;
       currentSKID.Quantity__c       = currentSerialList.size();
       SKidService3.serialwrapper sw = new SkidService3.SerialWrapper(currentSKID,currentSerialList);
       sw.assetBookValue             = fa.Book_Value__c;
       serialWrapperList.add(sw);
       Map<String,String> config = new Map<String,String>{
                'ICType' => 'Fixed Asset to Inventory',
                'ITType' => 'Fixed Asset to Inventory',
                'STType' => 'Fixed Asset to Inventory'
                }; 
       InventoryChangeService.transfer(serialWrapperList,null,config);
	}
 
}