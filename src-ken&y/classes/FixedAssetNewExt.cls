public with sharing class FixedAssetNewExt {
        
        private Apexpages.Standardcontroller faController;
        public List<Fixed_Asset__c> otherFixedAssets {get;set;}
        public List<RILWrapper> rilWrappers {get;set;} {rilWrappers = new List<RILWrapper>();}
        public List<Fixed_Asset__c> addFixedAssets {get;set;} {addFixedAssets = new List<Fixed_Asset__c>();}
        public Map<Id, RILWrapper> mRilWrappers; {mRilWrappers = new Map<Id, RILWrapper>();}
        public string selectedEntryType {get;set;}
        public string assetTagNo {get;set;}
        public boolean renderRLPanel {get;private set;}
        public boolean renderNewAsset {get;private set;}
        public boolean renderNewTaxBook {get;private set;}
        public boolean assetExists {get;private set;}
        public boolean displayPopUp {get;private set;}
        public string selectedRILID {get;set;}
        public string selectedRILName {get;set;}
        public string assetTag {get;set;}
        public Id fixedAssetAccountingId {get;set;}
        public List<SelectOption> fixedAssetOptions {get; private set;}
        public boolean isCustom {get;set;}
        
        public FixedAssetNewExt(Apexpages.Standardsetcontroller ssController){
        	
        }
        
        public pageReference newTaxBook(){
        	pageReference newFixedAsset = Page.FixedAssetNew;
        	string tmpFixedAssetId = Apexpages.currentPage().getParameters().get('Id');
        	newFixedAsset.getParameters().put('retURL', '/'+tmpFixedAssetId);
        	if(tmpFixedAssetId != null && tmpFixedAssetId != ''){


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','asset_tag_number__c'
});
soql.setWhereClause('Id = :tmpFixedAssetId');
soql.setLimit(1);
Fixed_Asset__c tmpFA = Database.query(soql.getQuery());


        		newFixedAsset.getParameters().put('assetTag', tmpFA.asset_tag_number__c);
        	}
        	
        	return newFixedAsset;
        }
        
        public FixedAssetNewExt(Apexpages.Standardcontroller controller){
                faController = controller;
                Fixed_Asset__c tmpFixedAsset = (Fixed_Asset__c)faController.getRecord();
                updateSelectOptions();
                if(Apexpages.currentPage().getParameters().get('isSplit') == '1'){
                	selectedEntryType = 'SI';
                }else{
                	selectedEntryType = 'SINGLE';
                }
                displayPopUp = false;
                isCustom = false;
                fixedAssetAccountingId = tmpFixedAsset.Fixed_Asset__c;
                tmpFixedAsset.Asset_Tag_Number__c = Apexpages.currentPage().getParameters().get('assetTag');
                if((tmpFixedAsset.Asset_Tag_Number__c != null && tmpFixedAsset.Asset_Tag_Number__c != '') || (fixedAssetAccountingId != null)){
                        checkExistingAssets();
                }
                checkRenderPanels();
        }
        
        
        public void checkExistingAssets(){
                Fixed_Asset__c tmpFixedAsset = (Fixed_Asset__c)faController.getRecord();
                
                string assetTag;
                if(tmpFixedAsset.Asset_Tag_Number__c != null && tmpFixedAsset.Asset_Tag_Number__c != ''){
                        assetTag = tmpFixedAsset.Asset_Tag_Number__c;
                }else{ 
                        assetTag = Apexpages.currentPage().getParameters().get('assetTag');
                }
                
                if((assetTag != null && assetTag != '') || (fixedAssetAccountingId != null)){


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','name','company__c','asset_class__c','asset_tag_number__c','location__c','gl_account__c','status__c','supplier__c','purchase_order__c',
	'supplier_invoice__c','date_purchased__c','warranty_expiration_date__c','depreciation_method__c','declining_balance__c','depreciation_period__c',
	'depreciation_convention__c','in_service_date__c','depreciation_life__c','estimated_end_of_life__c','final_depreciation_date__c',
	'acquisition_cost__c','residual_value__c','next_depreciation_date__c','disposition_date__c','retirement_date__c'
});
            string assetAcc =  FixedAssetService.ASSET_ACCOUNTING;                   
            soql.setWhereClause('(asset_tag_number__c = :assetTag OR Id = :fixedAssetAccountingId) AND fixed_asset_type__c = :assetAcc');
otherFixedAssets = Database.query(soql.getQuery());


                        if(otherFixedAssets.size() == 0){
                                renderNewAsset = true;
                                renderNewTaxBook = false;
                                assetExists = false;
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.No_FixedAssets_with_this_tag_number_click_New_FixedAsset));
                        }else{
                                renderNewAsset = false;
                                renderNewTaxBook = true;
                                assetExists = true;
                                tmpFixedAsset.Asset_Tag_Number__c = otherFixedAssets[0].asset_tag_number__c;
                                tmpFixedAsset.asset_class__c = otherFixedAssets[0].asset_class__c;
                                tmpFixedAsset.fixed_asset__c = otherFixedAssets[0].Id;
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.There_is_an_existing_FixedAsset_with_this_tag_number + otherFixedAssets[0].asset_tag_number__c));
                        }
                }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Enter_an_asset_tag_number));
                }
        }
        
        public void checkRenderPanels(){
                if(selectedEntryType == 'SINGLE'){
                        renderRLPanel = false;
                }else{
                        renderRLPanel = true;
                }
        }
        
        public void openMultipleAssetPopUp(){
                if(mRilWrappers.containsKey(selectedRILID)){
                		isCustom = false;
                        RILWrapper rw = mRilWrappers.get(selectedRILID);
                        selectedRILName = rw.ril.name;
                        if(rw.fixedAssets != null && rw.assetEntry == 'MULTIPLE'){
                                addFixedAssets = rw.fixedAssets;
                        }
                        else{
                                rw.assetEntry = 'MULTIPLE';
                                addFixedAssets = new List<Fixed_Asset__c>();
                                decimal qty = rw.ril.quantity_received__c != null ? rw.ril.quantity_received__c : rw.ril.invoice_quantity__c; 
                                qty = qty > 1000 ? 1000 : qty;
                                for(integer i = 0; i<qty; i++){
                                        addFixedAssets.add(new Fixed_Asset__c(company__c = rw.ril.supplier_invoice__r.company__c, purchase_order__c = rw.ril.purchase_order__c, purchase_order_line__c = rw.ril.purchase_order_line__c, 
                                                                Supplier_Invoice_Line__c = rw.ril.Id, acquisition_cost__c = rw.ril.unit_price__c, name = rw.ril.item__r.name + '-' + string.valueOf(i+1),
                                                                asset_tag_number__c = rw.ril.name + '-' + string.valueOf(i+1), supplier_invoice__c = rw.ril.supplier_invoice__c, 
                                                                supplier__c = rw.ril.supplier_invoice__r.supplier__c, description__c = rw.ril.description__c, units__c = 1 ));
                                                                                                        
                                }
                        }
                        rw.fixedAssets = addFixedAssets;
                        mRilWrappers.put(selectedRILID, rw);
                }
                displayPopUp = true;
        }
        
        public void openSingleAssetPopUp(){
                if(mRilWrappers.containsKey(selectedRILID)){
                	isCustom = false;
                    RILWrapper rw = mRilWrappers.get(selectedRILID);
                    selectedRILName = rw.ril.name;
                    if(rw.fixedAssets != null && rw.assetEntry == 'SINGLE'){
                            addFixedAssets = rw.fixedAssets;
                    }
                    else{
                            rw.assetEntry = 'SINGLE';
                            addFixedAssets = new List<Fixed_Asset__c>();
                            addFixedAssets.add(new Fixed_Asset__c(company__c = rw.ril.Supplier_Invoice__r.company__c, purchase_order__c = rw.ril.purchase_order__c, purchase_order_line__c = rw.ril.purchase_order_line__c, 
                                                Supplier_Invoice_Line__c = rw.ril.Id, acquisition_cost__c = rw.ril.extended_cost__c, name = rw.ril.item__r.name,
                                                asset_tag_number__c = rw.ril.name, supplier_invoice__c = rw.ril.supplier_invoice__c, units__c = rw.ril.quantity_received__c,
                                                supplier__c = rw.ril.supplier_invoice__r.supplier__c, description__c = rw.ril.description__c ));
                                                                                                    
                    }
                    rw.fixedAssets = addFixedAssets;
                    mRilWrappers.put(selectedRILID, rw);
                }
                displayPopUp = true;
        }
        
        public void openCustomAssetPopUp(){
                if(mRilWrappers.containsKey(selectedRILID)){
                	isCustom = true;
                    RILWrapper rw = mRilWrappers.get(selectedRILID);
                    selectedRILName = rw.ril.name;
                    if(rw.fixedAssets != null && rw.assetEntry == 'SINGLE'){
                            addFixedAssets = rw.fixedAssets;
                    }
                    else{
                            rw.assetEntry = 'SINGLE';
                            addFixedAssets = new List<Fixed_Asset__c>();
                            addFixedAssets.add(new Fixed_Asset__c(company__c = rw.ril.supplier_invoice__r.company__c, purchase_order__c = rw.ril.purchase_order__c, purchase_order_line__c = rw.ril.purchase_order_line__c, 
                                                Supplier_Invoice_Line__c = rw.ril.Id, acquisition_cost__c = rw.ril.extended_cost__c, name = rw.ril.item__r.name,
                                                asset_tag_number__c = rw.ril.name, supplier_invoice__c = rw.ril.supplier_invoice__c,
                                                supplier__c = rw.ril.supplier_invoice__r.supplier__c, description__c = rw.ril.description__c ));
                                                                                                    
                    }
                    rw.fixedAssets = addFixedAssets;
                    mRilWrappers.put(selectedRILID, rw);
                }
                displayPopUp = true;
        }
        
        public void saveFixedAssets(){
                if(mRilWrappers.containsKey(selectedRILID)){
                        RILWrapper rw = mRilWrappers.get(selectedRILID);
                        rw.fixedAssets = addFixedAssets;
                        mRilWrappers.put(selectedRILID, rw);
                }
                closePopUp();
        }
        
        public void addAdditionalAsset(){
            if(mRilWrappers.containsKey(selectedRILID)){
            	RILWrapper rw = mRilWrappers.get(selectedRILID);
            	rw.fixedAssets.add(new Fixed_Asset__c(company__c = rw.ril.Supplier_Invoice__r.company__c, purchase_order__c = rw.ril.purchase_order__c, purchase_order_line__c = rw.ril.purchase_order_line__c, 
                                                Supplier_Invoice_Line__c = rw.ril.Id, acquisition_cost__c = rw.ril.extended_cost__c, name = rw.ril.item__r.name,
                                                asset_tag_number__c = rw.ril.name, supplier_invoice__c = rw.ril.supplier_invoice__c,
                                                supplier__c = rw.ril.supplier_invoice__r.supplier__c, description__c = rw.ril.description__c ));
            }
        }
        
        public void cancelPopUp(){
        		isCustom = false;
                addFixedAssets = new List<Fixed_Asset__c>();
                selectedRILID = null;
                selectedRILName = null;
                closePopUp();
        }
        
        public void closePopUp(){
        		isCustom = false;
                displayPopUp = false;
        }
        
        public void updateRILines(){
                Fixed_Asset__c fa = (Fixed_Asset__c)faController.getRecord();
                cancelPopUp();
                RILWrappers = new List<RILWrapper>();
                mRilWrappers = new Map<Id, RILWrapper>();


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'id','name','purchase_order__c','purchase_order_line__c','item__c','description__c','Supplier_Invoice__r.Company__c','item__r.name',
	'unit_price__c','Quantity_Received__c','invoice_quantity__c','Supplier_Invoice__c','supplier_invoice__r.supplier__c','extended_cost__c'
});
        string sI = fa.Supplier_Invoice__c;            
        soql.setWhereClause('Supplier_Invoice__c = :sI');
List<Supplier_Invoice_Line__c> rils = Database.query(soql.getQuery());


                for(Supplier_Invoice_Line__c ril : rils){
                        RILWrapper irw = new RILWrapper(ril, false);
                        mRilWrappers.put(irw.ril.Id, irw);
                        RILWrappers.add(irw);
                }
        }
        
        public void updateSelectOptions(){
                fixedAssetOptions = new List<SelectOption>{new SelectOption('SINGLE', Label.New_Single_Asset), new SelectOption('SI', Label.New_Assets_from_Supplier_Invoice)};
        }
        
        public pageReference createNewTaxBook(){
        	Savepoint sp = Database.setSavepoint();
    		try{
                Fixed_Asset__c fa = otherFixedAssets[0].clone(false, true, false, false);
                fa.name = fa.name + ' Tax';
                fa.Fixed_Asset_Type__c = 'Tax';
                fa.fixed_asset__c = otherFixedAssets[0].Id;
                Fixed_Asset__c tmpFixedAsset = (Fixed_Asset__c)faController.getRecord();
                fa.Fixed_Asset_Key__c = fa.Asset_Tag_Number__c + fa.Fixed_Asset_Type__c + tmpFixedAsset.Asset_Class__c;
                DML.checkUpsertAsUser(fa); upsert fa fixed_asset_key__c;
                Apexpages.Standardcontroller fasc = new Apexpages.StandardController(fa);
                pageReference newPage = fasc.edit();
                newPage.getParameters().put('retURL', '/'+fa.Id);
                return newPage;
            }catch(Exception ex){
            	Database.rollback(sp);
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            	return null;
            }
        }
        
        public pageReference createNewFixedAsset(){
        	Savepoint sp = Database.setSavepoint();
    		try{
    			checkExistingAssets();
    			if(!assetExists){
	                Fixed_Asset__c fa = (Fixed_Asset__c)faController.getRecord();
	                string tagNo = fa.asset_tag_number__c == null ? '' : fa.asset_tag_number__c;
	                fa.name = 'Asset ' + tagNo;
	                fa.Company__c = CompanyService.getDefaultCompanyId();
	                fa.fixed_Asset__c = null;
	                
	                DML.insertAsUser(fa);

	                Apexpages.Standardcontroller fasc = new Apexpages.StandardController(fa);
	                pageReference newPage = fasc.edit();
	                newPage.getParameters().put('retURL', '/'+fa.Id);
	                return newPage;
    			}else{
    				return null;
    			}
    		}catch(Exception ex){
            	Database.rollback(sp);
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            	return null;
            }
        }
        
        public pageReference generateRLFixedAssets(){
            PageReference newPage;
            List<Fixed_Asset__c> fixedAssets = new List<Fixed_Asset__c>();
            boolean isValid = true;
            for(Id rilId : mRilWrappers.keySet()){
                    List<Fixed_Asset__c> iFAs = mRilWrappers.get(rilId).fixedAssets;
                    if(iFAs != null){
                            for(Fixed_Asset__c fa : iFAs){
                                    if(validateFixedAsset(fa)){
                                            fixedAssets.add(fa);
                                    }
                            }
                    }
            }
            
            if(fixedAssets.size() > 0){
                    try{
                    	DML.insertAsUser(fixedAssets);

                        String ObjectPrefix = Fixed_Asset__c.sObjectType.getDescribe().getKeyPrefix();
	                    newPage = new PageReference('/'+ObjectPrefix);
	                    newPage.setRedirect(true);
                    }catch(DMLException ex){
                        string dmlErrors = '';
                        for(integer i=0; i<ex.getNumDML();i++){
                                dmlErrors += 'Error: ' + MessageUtil.toFriendlyErrorMessage(ex.getDMLMessage(i)) + '<br/>';
                                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, dmlErrors));
                    }
            }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.No_FixedAssets_configured_for_the_PurchaseOrderLines));
            }
                
    		return newPage; 
        }
        
        public boolean validateFixedAsset(Fixed_Asset__c fa){
                boolean isValid = true;
                //Original validation process removed for changed reqs
                if(fa.Asset_Class__c == null){
                        isValid = false;
                }       
                return isValid;
        }
        
        public class RILWrapper{
                
                public boolean selected {get;set;}
                public Supplier_Invoice_Line__c ril {get;set;}
                public List<Fixed_Asset__c> fixedAssets {get;set;}
                public string assetEntry {get;set;}
                
                public RILWrapper(Supplier_Invoice_Line__c inRIL, boolean inSelected){
                        ril = inRIL;
                        selected = inSelected;
                        //Do not generate unless we need to
                        /*
                        for(integer i = 0; i<pol.order_quantity__c; i++){
                                fixedAssets.add(new Fixed_Asset__c(purchase_order__c = pol.purchase_order__c, purchase_order_line__c = pol.Id, 
                                                                                                        acquisition_cost__c = pol.unit_price__c, name = pol.item__r.name));
                        }
                        */
                }
        }
}