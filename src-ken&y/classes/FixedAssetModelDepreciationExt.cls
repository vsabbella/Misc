public with sharing class FixedAssetModelDepreciationExt {
	
	public Apexpages.Standardcontroller con {get;set;}
	public List<Fixed_Asset_Depreciation__c> existingFads {get;set;}
	public List<Fixed_Asset_Depreciation__c> modeledFads {get;set;}
	public List<AssetValue> existingDepreciation {get;set;}
	public List<AssetValue> modeledDepreciation {get;set;}
	public List<AssetValue> depreciableBasis {get;set;}
	public integer edMin {get;set;}
	public integer edMax {get;set;}
	
	public FixedAssetModelDepreciationExt(Apexpages.Standardcontroller controller){
		con = controller;
		updateAssetValues();
		updateModeledFads();
	}
	
	public void updateExistingFads(){ 
		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		    */
		SOQLUtil soql = new SOQLUtil('Fixed_Asset_Depreciation__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Depreciation_Amount__c','Depreciation_Date__c','Value_upon_Depreciation__c'
		});
	    string fId = con.getId(); 
	    string tDepr =  FixedAssetService.TYPE_DEPRECIATION;       
	    soql.setWhereClause('Fixed_Asset__c = :fId AND Subtransaction_Type__c = :tDepr');
		soql.setOrderByClause('Depreciation_Date__c');
		existingFads = Database.query(soql.getQuery()); 
	}
	 
	public void updateModeledFads(){
		modeledFads = new List<Fixed_Asset_Depreciation__c>();
		modeledDepreciation = new List<AssetValue>();
		Map<Date, AssetValue> mAssetValues = new Map<Date, AssetValue>();
		List<Decimal> amts = new List<Decimal>();
		try{
			Fixed_Asset__c fa = (Fixed_Asset__c)con.getRecord();
			Id fixedAssetId = fa.Id;
			//string query = SchemaUtil.getInstance().getFieldsforQuery('Fixed_Asset__c');
			//query.replace('Date_Last_Depreciated__c,','');
	        string cusFields = SchemaUtil.getInstance().getFieldsforQuery('Fixed_Asset__c');
	        cusFields.replace('Date_Last_Depreciated__c,','');
	        set<string> cFields = new Set<String>(cusFields.split(','));
	        cFields.add('Company__r.Default_Transaction_Currency__c'); 
	        cFields.add('Company__r.Comp_Currency__c'); 
			String whereClause = 'ID = :fixedAssetId';//KNDY-8796
	        SOQLUtil soql = new SOQLUtil('Fixed_Asset__c',true);
	        soql.addFields(cFields);
	        soql.setWhereClause(whereClause);
			//fa = Database.query('SELECT ' + query + ',Company__r.Default_Transaction_Currency__c FROM Fixed_Asset__c WHERE ID = :fixedAssetId');
			fa = Database.query(soql.getQuery()); 
			
			for(string depType : FixedAssetService.interfaceProcessorMap.keySet()){  
			        
			        //---Skip any depreciation modelling  if depreciation period is Annually and depreciation_life__c < 1 year---//
    				if(  depType.contains('Sum of Years') && (fa.depreciation_life__c < 12) ||
    				     fa.Depreciation_Period__c.contains('Annually') && (fa.depreciation_life__c < 12) ) {
    				   continue;
    			    }
    				
    				system.debug('depType : '+depType);
				    FixedAssetService.IDepreciation depreciation 
				        = FixedAssetService.returnDepreciationProcessor(FixedAssetService.interfaceProcessorMap.get(depType));
    				system.debug('depreciation: ' + depreciation);
    				modeledFads = depreciation.execute(new List<Fixed_Asset__c>{fa}, fa.Estimated_End_of_Life__c, false); 
				    for(Fixed_Asset_Depreciation__c fad : modeledFads){
				
    					AssetValue iAV;
    					if(mAssetValues.containsKey(fad.Depreciation_Date__c)){
    						iAV = mAssetValues.get(fad.Depreciation_Date__c);
    					}else{
    						iAV = new AssetValue(fad.Depreciation_Date__c);
    					}
    					
    					if(depType == 'Straight Line'){
    						//iAV.sl = fad.Depreciation_Amount__c;
    						iAV.sl = fad.Value_upon_Depreciation__c;
    					}else if(depType == 'Declining Balance'){
    						//iAV.db = fad.Depreciation_Amount__c;
    						iAV.db = fad.Value_upon_Depreciation__c;
    					}else if(depType == 'MACRS'){
    						//iAV.ma = fad.Depreciation_Amount__c;
    						iAV.ma = fad.Value_upon_Depreciation__c;
    					}else if(depType == 'Sum of Years'){
    						//iAV.sy = fad.Depreciation_Amount__c;
    						amts.add(fad.Depreciation_Amount__c);
    						iAV.sy = fad.Value_upon_Depreciation__c;
    					}
    					
    					mAssetValues.put(fad.Depreciation_Date__c, iAV);
			        }  
			}
			
			//amts.sort();
			//syMin = integer.valueOf(amts[0]);
			//syMax = integer.valueOf(amts[amts.size() - 1]);
			modeledDepreciation.addAll(mAssetValues.values());
			modeledDepreciation.sort();
			
			decimal slVal = fa.Book_Value__c;
			decimal dbVal = fa.Book_Value__c;
			decimal maVal = fa.Book_Value__c;			
			decimal syVal = fa.Book_Value__c;
			for(AssetValue av : modeledDepreciation){
				
				if(av.sl == 0){
					av.sl = slVal;
				}else{
					slVal = av.sl;
				}
				
				if(av.db == 0){
					av.db = dbVal;
				}else{
					dbVal = av.db;
				}
				
				if(av.ma == 0){
					av.ma = maVal;
				}else{
					maVal = av.ma;
				}
				
				if(av.sy == 0){
					av.sy = syVal;
				}else{
					syVal = av.sy;
				}
			}
			system.debug('modeledDepreciation: ' + modeledDepreciation);
		}catch(Exception ex){
			system.debug('Depreciation Model failed due to reason : ' + ex.getMessage());
			system.debug('Depreciation Model failed due to reason : getCause ' + ex.getStackTraceString());
			
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR,
			                        'Depreciation Model failed due to reason : '+ MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
	}	
	 
	
	public void updateAssetValues(){
		
		Fixed_Asset__c fa = (Fixed_Asset__c)con.getRecord();
		existingDepreciation = new List<AssetValue>();
		List<Decimal> amts = new List<Decimal>();
		
		updateExistingFads();
		
		decimal acqCost = fa.Acquisition_Cost__c == null ? 0 : fa.Acquisition_Cost__c;
		//existingDepreciation.add(new AssetValue(fa.In_Service_Date__c, 0, acqCost));
		
		for(Fixed_Asset_Depreciation__c fad : existingFads){
			acqCost -= fad.Depreciation_Amount__c;
			//system.debug(acqCost);
			amts.add(fad.Depreciation_Amount__c);
			existingDepreciation.add(new AssetValue(fad.Depreciation_Date__c, fad.Depreciation_Amount__c, fad.Value_upon_Depreciation__c));
		}
		
		
		existingDepreciation.sort();
		system.debug(existingDepreciation);

		if(amts.size() > 0){		
			amts.sort();
			edMin = integer.valueOf(amts[0]*.9);
			edMax = integer.valueOf(amts[0]*1.1);
		}
		

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
        SOQLUtil soql = new SOQLUtil('Fixed_Asset_Adjustment__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
        	'Id','Amount__c','Adjustment_Date__c'
        });
            string cId =  con.getId();       
            soql.setWhereClause('Fixed_Asset__c = :cId');
        List<Fixed_Asset_Adjustment__c> faas = Database.query(soql.getQuery());
     
    	for(Fixed_Asset_Adjustment__c faa : faas){
    		acqCost += faa.Amount__c;
    		//existingDepreciation.add(new AssetValue(faa.Adjustment_Date__c, 0, acqCost));
    	}
		 
	}
	
	public class AssetValue implements Comparable{
		public date dt {get;set;}
		public string d {get;set;}
		public Decimal ba {get;set;}
		public Decimal ed {get;set;}
		public Decimal sl {get;set;}
		public Decimal db {get;set;}
		public Decimal ma {get;set;}
		public Decimal sy {get;set;}
		
		public AssetValue(Date dt){
			this.dt = dt;
			this.d = dt.format();
			this.ed = 0;
			this.ba = 0;
			this.sl = 0;
			this.db = 0;
			this.ma = 0;
			this.sy = 0;
		}
		
		public AssetValue(Date dt, Decimal ed, decimal ba){
			this.dt = dt;
			this.d = dt.format();
			this.ed = ed;
			this.ba = ba;
			this.sl = sl;
			this.db = db;
			this.ma = ma;
			this.sy = sy;
		}
		
		public integer compareTo(object compare){
			AssetValue compareTo = (AssetValue)compare;
			if(dt == compareTo.dt){
				return 0;
			}else if(dt > compareTo.dt){
				return 1;
			}else {
				return -1;
			}
		}
	}
	
}