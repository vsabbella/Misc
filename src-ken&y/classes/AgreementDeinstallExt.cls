public with sharing class AgreementDeinstallExt {
    
    public Apexpages.Standardcontroller con {get;set;}
    public List<InstallationDetail> installationDetails {get;set;}
    
    public AgreementDeinstallExt(Apexpages.Standardcontroller controller){
        this.con = controller;
        if(!test.isRunningTest()){
            con.addFields(new List<string>{'Customer__c'});
        }
        updateInstallationDetails();
    }
    
    
    public void updateInstallationDetails(){
        
        installationDetails = new List<InstallationDetail>();
        Agreement__c agreement = (Agreement__c)con.getRecord();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Top_Parent_Customer__c', 'Currency__c'
        });
        Id acId = agreement.Customer__c;
        soql.setWhereClause(
            'Id = :acId OR Top_Parent_Customer__c = :acId OR Parent_Customer__c = :acId ' +
            'OR Parent_Customer__r.Parent_Customer__c = :acId OR Parent_Customer__r.Parent_Customer__r.Parent_Customer__c = :acId'
        );
        List<Customer__c> customers = Database.query(soql.getQuery());

        set<Id> custIds = new set<Id>();
        for(Customer__c c : customers){
            custIds.add(c.Id);
            custIds.add(c.top_parent_customer__c);
        }
        system.debug('custIds: ' + custIds);

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','name','Street__c','City__c','State__c','Zip_Code__c','Country__c','Notes__c','RecordType.DeveloperName'
        });
        soql.setWhereClause('Id IN :custIds');
        soql.setOrderByClause('Name');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
        childRel.addFields(new set<string>{
            'Id','name','Item__c','Item_UOM__c','Quantity__c','Customer__c','Company__c','Company__r.Default_Transaction_Currency__c','Customer__r.Parent_Customer__c',
            'Customer__r.Parent_Customer__r.Parent_Customer__c','Product__c'
        });
        childRel.setWhereClause('Type__c = \'Install Base\'');
        soql.addChildRelationship(childRel);
        List<Customer__c> sites = Database.query(soql.getQuery());


        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Fulfillment__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Parent_Fulfillment__c'
        });
        Id aId = agreement.Id;
        soql.setWhereClause('Agreement__c = :aId AND Parent_Fulfillment__c != null AND Type__c = \'Deinstall\'');
        List<Fulfillment__c> deinstallFulfillments = Database.query(soql.getQuery());

        set<Id> deinstallIds = new set<Id>();
        for(Fulfillment__c f : deinstallFulfillments){
            deinstallIds.add(f.Id);
            deinstallIds.add(f.parent_fulfillment__c);
        }                   
        system.debug('deinstallIds: ' + deinstallIds);      

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Fulfillment__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','name','Quantity__c','UOM__c','SKID__c','Product__c','Currency__c','Agreement__c','Sales_Order_Line__r.Agreement_Line__c',
            'Sales_Order_Line__r.Agreement_Line__r.Agreement__c','Sales_Order_Line__r.Agreement_Line__r.Agreement_Price__c','Sales_Order_Line__r.Product__r.Selling_UOM__c'
        });
        aId = agreement.Id;
        soql.setWhereClause('SKID__r.Customer__c IN :custIds AND Agreement__c = :aId AND Type__c != \'Deinstall\' AND Id NOT IN :deinstallIds');
        List<Fulfillment__c> fulfillments = Database.query(soql.getQuery());

        Map<Id, List<Fulfillment__c>> mFulfillments = new Map<Id, List<Fulfillment__c>>();
        for(Fulfillment__c f : fulfillments){
            if(mFulfillments.containsKey(f.SKID__c)){
                mFulfillments.get(f.SKID__c).add(f);
            }else{
                mFulfillments.put(f.SKID__c, new List<Fulfillment__c>{f});
            }
        }
        for(Customer__c s : sites){
            system.debug('site skids: ' + s.SKIDs__r);
            if(!s.SKIDs__r.isEmpty() || s.RecordType.DeveloperName == 'Site'){
                installationDetails.add(new InstallationDetail(s, s.SKIDs__r, mFulfillments));
            }
        }                           
        
    }
    
    public void deinstall(){
        
        Agreement__c agreement = (Agreement__c)con.getRecord();
        //Site => SO
        map<Id, Sales_Order__c> mSOs = new map<Id, Sales_Order__c>();
        //Site => [Fulfillments]
        map<Id, set<Id>> mSiteFulfillments = new map<Id, set<Id>>();
        //Fulfillment => SOL
        map<Id, Sales_Order_Line__c> mSOLs = new map<Id, Sales_Order_Line__c>();
        //Fulfillment => Deinstall
        Map<Id, Fulfillment__c> mDeinstallFulfillments = new Map<Id, Fulfillment__c>();
        
        for(InstallationDetail i : installationDetails){
            boolean hasLines = false;
            for(SKIDDetail s : i.skids){
                if(s.selected && s.qty != 0 && s.qty != null){
                    if(s.qty > s.f.quantity__c){
                        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'Deinstall Quantity Cannot exceed Quantity.'));
                    }else{
                    if(!hasLines){
                        Sales_Order__c iSO = new Sales_Order__c();
                        iSO.Company__c = s.skid.Company__c;
                        iSO.Customer__c = s.skid.Customer__r.Parent_Customer__c;
                        iSO.Ship_To__c = s.skid.Customer__c;
                        iSO.Bill_To__c = s.skid.Customer__r.Parent_Customer__r.Parent_Customer__c;
                        iSO.Agreement__c = agreement.Id; //KNDY-7927 Adding Agreement to Adjustment SO. 
                        iSO.Type__c = 'Adjustment'; //We will get caught with errors from the ERP if we use 'Deinstall', need to add this is as a type in SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES //'Deinstall';
                        iSO.Status__c = 'Draft';
                        iSO.Currency__c = s.skid.Company__r.Default_Transaction_Currency__c;
                        mSOs.put(i.site.Id, iSO);
                    }
                    system.debug('s: ' + s);
                    Sales_Order_Line__c iSOL = new Sales_Order_Line__c();
                    iSOL.Company__c = s.skid.Company__c;
                    iSOL.Customer_Site__c = i.site.Id;
                    iSOL.Quantity_Ordered__c = (-1)*s.qty;
                    //This is to avoid the validation rule "Quantity_ordered_and_shipped_validation" on SOL
                    iSOL.Quantity_Allocated__c = iSOL.Quantity_Ordered__c;
                    //Tag the order line with the skid we're performing the deinstall on
                    iSOL.SKID__c = s.skid.Id;
                    iSOL.Agreement_Line__c = s.f.Sales_Order_Line__r.Agreement_Line__c;
                    iSOL.Unit_Price__c = s.f.Sales_Order_Line__r.Agreement_Line__r.Agreement_Price__c; //KNDY-7929
                    iSOL.Selling_UOM__c = s.f.Sales_Order_Line__r.Product__r.Selling_UOM__c;
                    if(s.f.product__c != null){
                        iSOL.Product__c = s.f.Product__c;
                    }else{
                        iSOL.Product__c = s.skid.Product__c;
                        //TODO: get angry
                    }
                    
                    mSOLs.put(s.f.Id, iSOL);
                    
                    Fulfillment__c iFulf = new Fulfillment__c();
                    //iFulf.Sales_Order_Line__c = sol.Id;
                    iFulf.Product__c = iSOL.Product__c;
                    iFulf.Quantity__c = iSOL.Quantity_Ordered__c;
                    iFulf.Type__c = 'Deinstall';
                    iFulf.Status__c = 'Pending';
                    iFulf.UOM__c = iSOL.Selling_UOM__c;
                    iFulf.Agreement__c = agreement.Id;
                    iFulf.Parent_Fulfillment__c = s.f.Id;
                    iFulf.SKID__c = iSOL.SKID__c;
                    iFulf.Currency__c = s.f.Currency__c;
                    
                    mDeinstallFulfillments.put(s.f.Id, iFulf);
                    
                    if(mSiteFulfillments.containsKey(i.site.Id)){
                        mSiteFulfillments.get(i.site.Id).add(s.f.Id);
                    }else{
                        mSiteFulfillments.put(i.site.Id, new set<Id>{s.f.Id});
                    }
                }
            }
        }
        }
        
        if(mSOs.keySet().size() > 0 && mSOLs.keySet().size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                system.debug(mSOs.values());
                DML.insertAsUser(mSOs.values());
                
                List<Sales_Order_Line__c> insertSOLs = new List<Sales_Order_Line__c>();
            
                for(Id siteId : mSiteFulfillments.keySet()){
                    if(mSiteFulfillments.containsKey(siteId)){
                        for(Id fulfillmentId : mSiteFulfillments.get(siteId)){
                            if(mSOLs.containsKey(fulfillmentId)){
                                if(mSOs.containsKey(siteId)){
                                    mSOLs.get(fulfillmentId).Sales_Order__c = mSOs.get(siteId).Id;
                                }
                            }
                        }
                    }
                }
                DML.insertAsUser(mSOLs.values());
                
                for(Id fulfillmentId : mSOLs.keySet()){
                    if(mDeinstallFulfillments.containsKey(fulfillmentId)){
                        mDeinstallFulfillments.get(fulfillmentId).Sales_Order_Line__c = mSOLs.get(fulfillmentId).Id;
                    }
                }
                DML.insertAsUser(mDeinstallFulfillments.values());
                
                list<string> soNames = new List<string>();

                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id','name', 'Currency__c'
                });
                List<Sales_Order__c> soList = mSOs.values();
                soql.setWhereClause('Id IN :soList');
                for(Sales_Order__c so : Database.query(soql.getQuery())) {
                    soNames.add(so.Name);
                }
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.CONFIRM, 'The following deinstallation orders have been created: ' + string.join(soNames, ', ')));
                updateInstallationDetails();
            }catch(Exception ex){
                database.rollback(sp);
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
                System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getMessage());
            }
            
        }
    }
    
    
    public class InstallationDetail{
        public Customer__c site {get;set;}
        public List<SKIDDetail> skids {get;set;}
        public InstallationDetail(Customer__c site, List<SKID__c> skids, Map<Id, List<Fulfillment__c>> mFulfillments){
            this.site = site;
            this.skids = new List<SKIDDetail>();
            for(SKID__c skid : skids){
                if(mFulfillments.containsKey(skid.Id)){
                    for(Fulfillment__c f : mFulfillments.get(skid.Id)){
                        this.skids.add(new SKIDDetail(false, skid.quantity__c, skid, f));
                    }
                }else{
                    system.debug('no fulfillments found for : ' + skid.Id);
                }   
                //this.skids.add(new SKIDDetail(false, skid.kndy4__quantity__c, skid, null));           
            }
        }
    }
    
    public class SKIDDetail{
        public boolean selected {get;set;}
        public decimal qty {get;set;}
        public SKID__c skid {get;set;}
        public Fulfillment__c f {get;set;}
        public SKIDDetail(boolean selected, decimal qty, SKID__c skid, Fulfillment__c f){
            this.selected = selected;
            this.qty = qty;
            this.skid = skid;
            this.f = f;
        }
    }
    
}