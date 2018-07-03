public with sharing class ItemSpecificationCostRollupExt {
    public Boolean showFacilityScope { get; set; } { showFacilityScope = false; }
    public String selectedScopeRange { get; set; } { selectedScopeRange = 'SINGLE'; }
    private String cachedScope;

    public Boolean rollupRouting { get; set; } { rollupRouting = false; }
    private Boolean cachedRollupRouting;

    public Boolean calcMfgOverhead { get; set; } { calcMfgOverhead = false; }
    private Boolean cachedCalcMfgOverhead;

    public Item_Cost__c inputHolder { get; set; } { inputHolder = new Item_Cost__c(); }
    private Id cachedCompanyId;
    private Id cachedFacilityId;
    private Id cachedItemSpecId;

    private Facility__c cachedFacility;

    public String selectedComponentItemCostStatus { get; set; }
    private String cachedComponentCostStatus;

    public String selectedAssemblyItemCostStatus { get; set; }

    public String selectedExplosionBasis { get; set; }
    private String cachedExplosionBasis;
    
    public String rollupBasis { get; set; }

    public Boolean showWipeoutCosts { get; set; } { showWipeoutCosts = false; }
    public Boolean isWipeoutCostsOn { get; set; } { isWipeoutCostsOn = false; }
    private Boolean cachedWipeoutCosts;

    public Boolean explodePurchased { get; set; } { explodePurchased = true; }
    private Boolean cachedExplodePurchased;

    public Item_Specification__c startDate { get; set; } { startDate = new Item_Specification__c(); }
    private DateTime cachedStartDate;

    private Boolean bypassPhantoms = false;
    private Item_Specification__c retrievedItemSpecObj = new Item_Specification__c();

    public Boolean showReport { get; set; } { showReport = false; }
    public transient List<List<IndentedBomWrapper>> thisBom { get; set; } { thisBom = new List<List<IndentedBomWrapper>>(); }
    public Integer bomSize { get; set; } { bomSize = 0; }
    public Id jobId { get; set; }
    public Document reportDoc { get; set; }
    public Id reportDocId { get; set; }
    public String reportDocName { get; set; }

    private static SchemaUtil util = SchemaUtil.getInstance();

    @TestVisible transient ItemService itemServ;
    private Id recordId { get; set; }
    public Boolean readReport { get; set; } { readReport = false; }
    public String pageTitle { get; set; } { pageTitle = Label.Assembly_Cost_Rollup; }


    public Boolean hasYield { get; set; } {
        hasYield = false;
        for (String str:util.getFieldsFromFieldSetString(Component__c.sObjectType, 'Component_BOM_FieldSet')) {
            if (str == 'Yield__c') hasYield = true;
        }
    }

    public void refreshCriteria() {
        if (inputHolder.Company__c == null) inputHolder.Company__c = UserPreference.getInstance().preference.Default_Company__c;
        
        if (selectedScopeRange == 'COMPANY') {
            recordId = null;
            inputHolder.Facility__c = null;
        } else if (selectedScopeRange == 'FACILITY' || selectedScopeRange == 'SINGLE') {
            if (selectedScopeRange == 'FACILITY') 
                recordId = null;
            if (selectedScopeRange == 'SINGLE' && inputHolder.Item_Specification__c != null) 
                recordId = inputHolder.Item_Specification__c;
            if (inputHolder.Facility__c == null)
                inputHolder.Facility__c = UserPreference.getInstance().preference.Default_Facility__c;
        } else {
            inputHolder.Facility__c = null;
        }

        if (inputHolder.Company__c != null) {
            SOQLUtil companyQuery = new SOQLUtil('Company__c');
            companyQuery.addFields(new Set<String>{ 'Id', 'Name', 'Default_Rollup_Basis__c', 'Use_Facility_Costs_in_Assembly_Rollup__c' });
            companyQuery.setWhereClause('Id = \'' + inputHolder.Company__c + '\'');

            Company__c company = Database.query(companyQuery.getQuery());
            showWipeoutCosts = company.Default_Rollup_Basis__c == 'Linear';
            showFacilityScope = company.Use_Facility_Costs_in_Assembly_Rollup__c == true;
        }
        if (inputHolder.Item_Specification__c != null) {
            SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
            itemSpecQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Costing__c', 'Facility__c', 'Production__c', 'Start_Date2__c', 'Active__c' });
            itemSpecQuery.setWhereClause('Id = \'' + inputHolder.Item_Specification__c + '\'');

            Item_Specification__c itemSpec = Database.query(itemSpecQuery.getQuery());
            if (itemSpec.Company__c != inputHolder.Company__c || itemSpec.Facility__c != inputHolder.Facility__c) {
                inputHolder.Item_Specification__c = null;
                retrievedItemSpecObj = null;
            }
            if (ApexPages.currentPage() != null && ApexPages.currentPage().getUrl() != null && recordId != null && !ApexPages.currentPage().getURL().toLowerCase().contains('bomdisplay')) {
                inputHolder.Company__c = itemSpec.Company__c;
                inputHolder.Facility__c = itemSpec.Facility__c;
                selectedComponentItemCostStatus = 'Approved';
                inputHolder.Item_Specification__c = recordId;
                selectedScopeRange = 'SINGLE';
                if (startDate == null || startDate.Start_Date2__c == null)
                    startDate = new Item_Specification__c(Start_Date2__c = itemSpec.Start_Date2__c);
                if (itemSpec.Costing__c)
                    selectedExplosionBasis = 'Costing';
                else if (itemSpec.Production__c)
                    selectedExplosionBasis = 'Production';
            }
        }
    }

    public PageReference redirect() { 
        PageReference p = Page.ItemSpecificationCostRollup;
        p.getParameters().put('readReport','true');
        return p;
    }

    public ItemSpecificationCostRollupExt() { }
    public ItemSpecificationCostRollupExt(ApexPages.StandardController con) {
        recordId = con.getId();
        
        if (ApexPages.currentPage() != null && ApexPages.currentPage().getUrl() != null && recordId != null && ApexPages.currentPage().getURL().toLowerCase().contains('bomdisplay')) {
            expandedBOM(true);
        } else {
            inputHolder.Item_Specification__c = recordId;
        }

        if (ApexPages.currentPage() != null && ApexPages.currentPage().getParameters().containsKey('readReport') && ApexPages.currentPage().getParameters().get('readReport') == 'true') {
            readReport = true;
            pageTitle = Label.Costed_BOM_Report;
        }
        
        refreshCriteria();
    }
    
    public void expandedBOM(Boolean resetStartDate) {
        selectedScopeRange = 'SINGLE FOR EXPANDED BOM';

        SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
        itemSpecQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Costing__c', 'Facility__c', 'Facility__r.Facility_Identifier__c', 'Production__c', 'Start_Date2__c', 'Type__c', 'Active__c' });
        itemSpecQuery.setWhereClause('Id = :recordId');
        retrievedItemSpecObj = Database.query(itemSpecQuery.getQuery());

        if (retrievedItemSpecObj.Type__c == 'Template') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Expanded_BOM_not_available));
            return;
        }
        
        if (resetStartDate) startDate = new Item_Specification__c(Start_Date2__c = retrievedItemSpecObj.Start_Date2__c);
        inputHolder.Company__c = retrievedItemSpecObj.Company__c;
        inputHolder.Facility__c = retrievedItemSpecObj.Facility__c;
        inputHolder.Facility__r = retrievedItemSpecObj.Facility__r;
        selectedComponentItemCostStatus = 'Approved';
        inputHolder.Item_Specification__c = retrievedItemSpecObj.Id;
        if (retrievedItemSpecObj.Costing__c)
            selectedExplosionBasis = 'Costing';
        else if (retrievedItemSpecObj.Production__c)
            selectedExplosionBasis = 'Production';

        showReport();
    }

    public static Set<String> csvScopeRanges {
        get {
            return new Set<String>{'FACILITY','COMPANY','ALL'};
        }
    }
    
    public List<SelectOption> getScopeRange() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('SINGLE',readReport ? 'View a specific item specification cost' : Label.Update_ItemSpecification_cost));
        if (showFacilityScope == true) options.add(new SelectOption('FACILITY',readReport ? 'View facility specific costs' : Label.Update_Facility_costs));
        else options.add(new SelectOption('COMPANY',readReport ? 'View company specific costs' : Label.Update_Company_costs));
        return options; 
    }
    
    // Get the types of cost rollup models that can be performed.
    public List<SelectOption> getCostRollupModels() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('ALL', Label.Update_costs_for_assemblies_and_subassemblies)); 
        options.add(new SelectOption('SINGLE',Label.Update_cost_for_assembly_without_updating_subassemblies)); 
        return options; 
    }
    
    //Get applicable Item Cost Status options for the updated/selected Item Cost associated with the selected Item Specification
    public List<SelectOption> getAssemblyItemCostStatusOptions() {
        List<SelectOption> options = new List<SelectOption>();  
        for (Schema.Picklistentry picklistEntry:Item_Cost__c.fields.Status__c.getDescribe().getpicklistvalues())
            options.add(new SelectOption(picklistEntry.getValue(),picklistEntry.getLabel()));            
        return options; 
    }
    
    //Get applicable Item Cost Status options to filter Item Cost Rollup Report
    public List<SelectOption> getComponentItemCostStatusOptions() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Approved', Label.Approved));
        
        for(Schema.Picklistentry picklistEntry : Item_Cost__c.fields.Status__c.getDescribe().getpicklistvalues()){
            options.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
        } 
        return options; 
    }

    public void refresh() {
        expandedBOM(false);
    }
    
    public void getItemSpecInfo() {
        try {
            if (inputHolder.Item_Specification__c != null) {
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Company__c','Company__r.Name','Start_Date2__c','Costing__c','Production__c', 'Active__c'
            });
            string ihAItemSpecCostId = inputHolder.Item_Specification__c;    
            soql.setWhereClause('Id = :ihAItemSpecCostId');
            soql.setLimit(1);
            Item_Specification__c is = Database.query(soql.getQuery());
                
                if (is != null) {
                    if (is.Start_Date2__c != null)
                        startDate.Start_Date2__c = is.Start_Date2__c;
                    if (is.Costing__c)
                        selectedExplosionBasis = 'Costing'; else if (is.Production__c)
                        selectedExplosionBasis = 'Production';
                }
            }
        } catch(Exception e) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())+', ' + inputHolder.Item_Specification__c));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
	
    /*
     * This method is called when user clicks "Show Report" button on the page
     * and populates the report shown on the visualforce.
     */
    public void showReport() {
        try {
            showReport = false;
            thisBom = new List<List<IndentedBomWrapper>>();
            bomSize = 0;
            jobId = null;
            reportDoc = new Document();
            reportDocId = null;
            reportDocName = '';
            retrievedItemSpecObj = new Item_Specification__c();

            if (String.isBlank(selectedScopeRange)) {
                throw new ItemSpecificationCostRollupExtException(Label.Select_item_cost_rollup_model);
            }
            cachedScope = selectedScopeRange;

            cachedRollupRouting = rollupRouting;

            cachedCalcMfgOverhead = calcMfgOverhead;

            if (inputHolder.Company__c != null) {
                SOQLUtil companyQuery = new SOQLUtil('Company__c');
                companyQuery.addFields(new Set<String>{ 'Id', 'Default_Rollup_Basis__c', 'Use_Item_Types_For_Costing__c' });
                companyQuery.setWhereClause('Id = \'' + inputHolder.Company__c + '\'');

                Company__c company = Database.query(companyQuery.getQuery());
                rollupBasis = company.Default_Rollup_Basis__c == null ? 'Standard' : company.Default_Rollup_Basis__c;
                bypassPhantoms = company.Use_Item_Types_For_Costing__c;

                cachedCompanyId = company.Id;
            } else {
                inputHolder.Company__c.addError(Label.Select_a_company);
                return;
            }

            if (inputHolder.Facility__c != null) {
                SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                facilityQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Facility_Identifier__c' });
                facilityQuery.setWhereClause('Id = \'' + inputHolder.Facility__c + '\'');

                Facility__c facility = Database.query(facilityQuery.getQuery());

                if (facility.Company__c != inputHolder.Company__c) {
                    throw new ItemSpecificationCostRollupExtException(Label.Select_a_valid_Facility);
                }

                cachedFacilityId = facility.Id;
                cachedFacility = facility;
            }

            if (inputHolder.Item_Specification__c != null) {
                SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
                itemSpecQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Costing__c', 'Facility__c', 'Item__c', 'Production__c', 'Start_Date2__c', 'Type__c', 'Active__c' });
                itemSpecQuery.setWhereClause('Id = \'' + inputHolder.Item_Specification__c + '\'');
                retrievedItemSpecObj = Database.query(itemSpecQuery.getQuery());

                cachedItemSpecId = retrievedItemSpecObj.Id;
            }

            if (String.isBlank(selectedComponentItemCostStatus)) {
                throw new ItemSpecificationCostRollupExtException(Label.Select_an_item_cost_status);
            }
            cachedComponentCostStatus = selectedComponentItemCostStatus;

            cachedExplosionBasis = selectedExplosionBasis;

            cachedWipeoutCosts = rollupBasis == 'Linear' ? isWipeoutCostsOn : false;

            cachedExplodePurchased = explodePurchased;

            if (startDate == null || startDate.Start_Date2__c == null) {
                DateTime startDt = retrievedItemSpecObj.Start_Date2__c != null ? retrievedItemSpecObj.Start_Date2__c : System.now();
                startDate = new Item_Specification__c(Start_Date2__c = startDt);
            }
            cachedStartDate = startDate.Start_Date2__c;

            if (selectedScopeRange == 'SINGLE' || selectedScopeRange == 'SINGLE FOR EXPANDED BOM') {
                if (inputHolder.Item_Specification__c == null) {
                    inputHolder.Item_Specification__c.addError(Label.Select_an_item_specification);
                    return;
                }

                if (retrievedItemSpecObj.Start_Date2__c > startDate.Start_Date2__c) {
                    startDate.Start_Date2__c.addError('The selected item specification is not effective until ' + retrievedItemSpecObj.Start_Date2__c);
                    return;
                }

                if (inputHolder.Company__c != retrievedItemSpecObj.Company__c || inputHolder.Facility__c != retrievedItemSpecObj.Facility__c) {
                    inputHolder.Item_Specification__c.addError(Label.ItemSpecifications_company_facility_doesnot_match_filter_criteria);
                    return;
                }

                if (selectedExplosionBasis == 'Costing' && !retrievedItemSpecObj.Costing__c) {
                    inputHolder.Item_Specification__c.addError('Selected item specification is not a costing BOM');
                    return;
                }

                 if (selectedExplosionBasis == 'Production' &&  !retrievedItemSpecObj.Production__c ) {
                    inputHolder.Item_Specification__c.addError('Selected item specification is not a production BOM');
                    return;
                }

                if (retrievedItemSpecObj.Type__c == 'Template') {
                    inputHolder.Item_Specification__c.addError('Selected item specification cannot be a template');
                    return;
                }
            }

            getReport(false);

            reportDoc = new Document();
        } catch (Exception e) {
            CustomException.addError(e);
        }
    }
    
    public void fetchDocument() {
        if (jobId != null) {
            SOQLUtil docQuery = new SOQLUtil('Document');
            docQuery.addFields(new Set<String>{ 'Id', 'Name', 'Keywords' });
            docQuery.setWhereClause('Keywords = :jobId');

            for (Document doc:Database.query(docQuery.getQuery())) {
                reportDocId = doc.Id;
                reportDocName = doc.Name;
            }
        }
    }
    
    public void saveReport() {
        try {
            if (selectedAssemblyItemCostStatus.equalsIgnoreCase('Approved')) {
                throw new ItemSpecificationCostRollupExtException(Label.Active_item_cost_cannot_be_updated);
            }

            getReport(true);
        } catch (Exception e) {
            CustomException.addError(e);
        }
    }
    
    public List<SelectOption> getExplosionBasis() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Costing','Costing')); 
        options.add(new SelectOption('Production','Production')); 
        return options; 
    }

    private void getReport(Boolean save) {
        String scope = save ? cachedScope : selectedScopeRange;

        if (scope == 'SINGLE' || scope == 'SINGLE FOR EXPANDED BOM') {
            itemServ = new ItemService();
            itemServ.scope = scope;
            itemServ.rollupRouting = save ? cachedRollupRouting : rollupRouting;
            itemServ.calcMfgOverhead = save ? cachedCalcMfgOverhead : calcMfgOverhead;
            itemServ.companyId = save ? cachedCompanyId : inputHolder.Company__c;
            itemServ.facilityId = save ? cachedFacilityId : inputHolder.Facility__c;
            itemServ.facility = save ? cachedFacility : inputHolder.Facility__r;
            itemServ.itemSpecId = save ? cachedItemSpecId : inputHolder.Item_Specification__c;
            itemServ.costing = retrievedItemSpecObj.Costing__c;
            itemServ.production = retrievedItemSpecObj.Production__c;
            itemServ.componentCostStatus = save ? cachedComponentCostStatus : selectedComponentItemCostStatus;
            itemServ.assemblyCostStatus = selectedAssemblyItemCostStatus;
            itemServ.explosionBasis = save ? cachedExplosionBasis : selectedExplosionBasis;
            itemServ.rollupBasis = rollupBasis;
            itemServ.wipeoutCosts = rollupBasis == 'Linear' ? (save == true ? cachedWipeoutCosts : isWipeoutCostsOn) : false;
            itemServ.explodePurchased = save ? cachedExplodePurchased : explodePurchased;
            itemServ.startDate = save ? cachedStartDate : startDate.Start_Date2__c;
            itemServ.bypassPhantoms = byPassPhantoms;
            itemServ.isRepair = retrievedItemSpecObj.Type__c == 'Repair';

            Id itemId = retrievedItemSpecObj.Item__c;
            itemServ.getItemSpecs(new Set<Id>{ itemId }, true);
            Item_Specification__c itemSpec = itemServ.itemSpecs.get(itemId);
            if (save && !retrievedItemSpecObj.Active__c) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot update item cost for inactive item specification.'));
                return;
            }

            if (scope == 'SINGLE') itemServ.getExistingItemCosts(new Map<Id, Item__c>{ itemId => itemSpec.Item__r });

            List<IndentedBomWrapper> wrappers = itemServ.getBoms(new Map<Id, Item__c>{ itemId => itemSpec.Item__r }, null, 0, null, 1.0, !save ? 'READ' : '');
    
            if (save) {
                itemServ.updateCosts(new Set<Id>{ itemId });

                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Item_cost_updated_successfully + itemSpec.Name));
            } else {
                bomSize = wrappers.size();
                for (IndentedBomWrapper wrapper:wrappers) {
                    if (thisBom.size() == 0 || (thisBom[thisBom.size() - 1].size() == 1000)) thisBom.add(new List<IndentedBomWrapper>{ wrapper });
                    else thisBom[thisBom.size() - 1].add(wrapper);
                }

                if (readReport) {
                    SOQLUtil folderQuery = new SOQLUtil('Folder');
                    folderQuery.addField('Id');
                    folderQuery.setWhereClause('Name = \'Cost BOM\'');
                    Folder f = Database.query(folderQuery.getQuery());

                    Document doc = new Document(
                        AuthorId = UserInfo.getUserId(),
                        FolderId = f.Id,
                        Name = itemSpec.Name + ' Cost Report - ' + System.now() + '.csv',
                        Type = 'csv',
                        Description = itemSpec.Name + ' Cost Report',
                        Body = Blob.valueOf(generateExpandedBOMReport())
                    );
                    DML.insertAsUser(doc);

                    reportDocId = doc.Id;
                    reportDocName = doc.Name;
                }
            }
        } else {
            ItemSpecificationCostRollupBatch batchInstance = new ItemSpecificationCostRollupBatch(save ? cachedCompanyId : inputHolder.Company__c, save ? cachedFacilityId : inputHolder.Facility__c, readReport);
            batchInstance.scope = scope;
            batchInstance.rollupRouting = save ? cachedRollupRouting : rollupRouting;
            batchInstance.calcMfgOverhead = save ? cachedCalcMfgOverhead : calcMfgOverhead;
            batchInstance.componentCostStatus = save ? cachedComponentCostStatus : selectedComponentItemCostStatus;
            batchInstance.assemblyCostStatus = selectedAssemblyItemCostStatus;
            batchInstance.explosionBasis = save ? cachedExplosionBasis : selectedExplosionBasis;
            batchInstance.rollupBasis = rollupBasis;
            batchInstance.wipeoutCosts = rollupBasis == 'Linear' ? (save == true ? cachedWipeoutCosts : isWipeoutCostsOn) : false;
            batchInstance.explodePurchased = save ? cachedExplodePurchased : explodePurchased;
            batchInstance.startDate = save ? cachedStartDate : startDate.Start_Date2__c;
            batchInstance.bypassPhantoms = byPassPhantoms;
            batchInstance.performDML = save;

            Integer batchSize = KSE.getBatchSize('ItemSpecificationCostRollupBatch');
            jobId = Database.executebatch(batchInstance, batchSize);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Item_cost_Rollup_batch_scheduled_to_run));  
        }

        showReport = true;
    }

    public String generateExpandedBOMReport() {
        String csvString = ItemService.generateExpandedBOMHeader(itemServ.maxLevel);
        for (List<IndentedBomWrapper> wrappers:thisBom) {
            for (IndentedBomWrapper wrapper:wrappers) {
                Item__c item = new Item__c(Name = wrapper.componentName, Description__c = wrapper.componentDescription, Source__c = wrapper.componentSource);
                Component__c component = wrapper.quantityPerAssembly != null ? new Component__c(Quantity_per_Assembly__c = wrapper.quantityPerAssembly, Yield__c = wrapper.yield) : null;
                Decimal parentQty = component != null ? (wrapper.totalQuantityPerAssembly / wrapper.quantityPerAssembly) : 1;
                csvString += itemServ.generateExpandedBOMLine(item, component, wrapper.compCost, wrapper.levelCounter, parentQty);
            }
        }
        return csvString;
    }
    
    public class IndentedBomWrapper {
        public Component__c compObj { get; set; }
        public Integer levelCounter { get; set; }
        public String componentName { get; set; }
        public String href { get; set; }
        public String href1 { get; set; }
        public String componentDescription { get; set; }
        public Decimal quantityPerAssembly { get; set; }
        public Decimal totalQuantityPerAssembly { get; set;}
        public Decimal yield { get; set; }
        public String componentSource { get; set; }
        public String componentUom { get; set; }
        public String itemSpecName { get; set; }
        public Item_Cost__c compCost { get; set; }
        public Decimal componentTotalCost { get; set; }

        public String csvLine { get; set; } { csvLine = ''; }
    }

    public class ItemSpecificationCostRollupExtException extends Exception { }
}