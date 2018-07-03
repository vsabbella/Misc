public with sharing class ItemSpecificationCostRollupBatch implements Database.Batchable<sObject>, Database.Stateful {
    public String scope { get; set; }
    public Boolean rollupRouting { get; set; } { rollupRouting = false; }
    public Boolean calcMfgOverhead { get; set; } { calcMfgOverhead = false; }
    public String componentCostStatus { get; set; }
    public String assemblyCostStatus { get; set; }
    public String explosionBasis { get; set; }
    public String rollupBasis { get; set; }
    public Boolean wipeoutCosts { get; set; } { wipeoutCosts = false; }
    public Boolean explodePurchased { get; set; } { explodePurchased = true; }
    public DateTime startDate { get; set; }
    public Boolean bypassPhantoms { get; set; } { bypassPhantoms = false; }
    public Boolean performDML { get; set; } { performDML = false; }

    private Company__c company;
    private Facility__c facility = new Facility__c();
    private Boolean readReport = false;
    private Integer maxLevel;
    private Document document;
    private List<Notify.Message> messages = new List<Notify.Message>();

    public ItemSpecificationCostRollupBatch(Id companyId, Id facilityId, Boolean readReport) {
        SOQLUtil companyQuery = new SOQLUtil('Company__c');
        companyQuery.addFields(new Set<String>{ 'Id', 'Name' });
        companyQuery.setWhereClause('Id = \'' + companyId + '\'');
        company = Database.query(companyQuery.getQuery());

        if (facilityId != null) {
            SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
            facilityQuery.addFields(new Set<String>{ 'Id', 'Name', 'Facility_Identifier__c' });
            facilityQuery.setWhereClause('Id = \'' + facilityId + '\'');
            facility = Database.query(facilityQuery.getQuery());
        }

        SOQLUtil folderQuery = new SOQLUtil('Folder');
        folderQuery.addField('Id');
        folderQuery.setWhereClause('Name = \'Cost BOM\'');

        document = new Document(
            AuthorId = UserInfo.getUserId(),
            FolderId = (Database.query(folderQuery.getQuery())[0]).Id,
            Type = 'csv'
        );

        if (readReport) {
            this.readReport = true;

            SOQLUtil levelQuery = new SOQLUtil('Item__c', true, true);
            levelQuery.addField('MAX(Level__c)maxLv');
            levelQuery.setWhereClause('Company__c = \'' + company.Id + '\'');
            AggregateResult ar = Database.query(levelQuery.getQuery());

            if (ar.get('maxLv') == null || ar.get('maxLv') == 0) {
                throw new ItemSpecificationCostRollupException('Item leveling must be run first');
            }

            maxLevel = Integer.valueOf(ar.get('maxLv'));

            document.Name = 'Cost Rollup Report - ' + System.now() + '.csv';
            document.Body = Blob.valueOf('');
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        document.Keywords = bc.getJobId();
        document.Description = scope + ' SPECIFIC - ' + (facility.Name != null ? facility.Name : company.Name);
        if (!readReport) {
            document.Name = 'Cost Rollup Report ' + (performDML ? '(Final)' : '(Draft)') + ' - ' + System.now() + '.csv';
        }
        
        Set<String> itemSources = new Set<String>{ 'Manufactured', 'Phantom', 'Kit', 'Build To Order' };
        if (explodePurchased) itemSources.add('Purchased');
        
        SOQLUtil itemQuery = new SOQLUtil('Item__c');
        itemQuery.addField('Name');
        itemQuery.addFields(ItemService.itemFields);
        itemQuery.setWhereClause('Source__c IN :itemSources AND Company__c = \'' + company.Id + '\'');
        itemQuery.setOrderByClause('Name ASC');
        return Database.getQueryLocator(itemQuery.getQuery());
    }

    public void execute(Database.BatchableContext bc, List<Item__c> items) {
        Savepoint sp = Database.setSavepoint();
        try {
            ItemService itemServ = new ItemService();
            itemServ.scope = scope;
            itemServ.rollupRouting = rollupRouting;
            itemServ.calcMfgOverhead = calcMfgOverhead;
            itemServ.companyId = company.Id;
            itemServ.facilityId = facility.Id;
            itemServ.facility = facility;
            itemServ.componentCostStatus = componentCostStatus;
            itemServ.assemblyCostStatus = assemblyCostStatus;
            itemServ.explosionBasis = explosionBasis;
            itemServ.rollupBasis = rollupBasis;
            itemServ.wipeoutCosts = wipeoutCosts;
            itemServ.explodePurchased = explodePurchased;
            itemServ.startDate = startDate;
            itemServ.bypassPhantoms = bypassPhantoms;
            itemServ.maxlevel = maxLevel;

            Map<Id, Item__c> itemMap = new Map<Id, Item__c>(items);

            itemServ.getItemSpecs(itemMap.keySet());
            itemServ.getExistingItemCosts(itemMap);

            List<ItemSpecificationCostRollupExt.IndentedBomWrapper> boms = itemServ.getBoms(itemMap, null, 0, null, 1.0, readReport ? 'READBATCH' : '');

            if (readReport) {
                if (document.Body != null) boms[0].csvLine = document.Body.toString() + boms[0].csvLine;
                document.Body = Blob.valueOf(boms[0].csvLine);
            } else {
                Set<Id> itemsWithSpec = new Set<Id>();
                for (Id itemId:itemMap.keySet()) {
                    if (itemServ.itemSpecs.containsKey(itemId)) itemsWithSpec.add(itemId);
                }

                if (itemsWithSpec.size() > 0 && performDML) {
                    itemServ.updateCosts(itemsWithSpec);
                }

                for (Id itemId:itemsWithSpec) {
                    Item__c item = itemMap.get(itemId);
                    Item_Cost__c itemCost = itemServ.itemCosts.get(itemId);

                    string itemDescription ;
                    if(item.Description__c != null) itemDescription = item.Description__c.escapeCsv();
                    string itemCostName;
                    if(itemCost.Name != null) itemCostName  = itemCost.Name.escapeCsv();
                    string itemName; 
                    if(item.Name != null) itemName = item.Name.escapeCsv();
                    string companyName ;
                    if(company.Name != null) companyName = company.Name.escapeCsv();
                    string facilityName ;
                    if(facility.Name != null) facilityName = facility.Name.escapeCsv();
                    if(componentCostStatus != null) componentCostStatus = componentCostStatus.escapeCsv();
                    if(assemblyCostStatus != null) assemblyCostStatus = assemblyCostStatus.escapeCsv();
                    string itemSource ;
                    if(item.Source__c != null) itemSource = item.Source__c.escapeCsv();
                    string itemStockingUOMName ;
                    if(item.Stocking_UOM__r.Name != null) itemStockingUOMName = item.Stocking_UOM__r.Name.escapeCsv();
                    
                   
                    
                    String csvLine = '\n';
                    csvLine += '' + (itemCost.Name != null ? itemCostName : '""') + '';
                    csvLine += ',' + (itemName != null ? itemName : '""') + '';
                    csvLine += ',' + (companyName != null ? companyName : '""') + '';
                    csvLine += ',' + (facility.Name != null ? facilityName : '""') + '';
                    csvLine += ',' + (componentCostStatus != null ? componentCostStatus : '""') + '';
                    csvLine += ',' + (assemblyCostStatus != null ? assemblyCostStatus : '""') + '';
                    csvLine += ',' + (itemDescription != null ? itemDescription : '""') + '';
                    csvLine += ',' + (itemSource != null ? itemSource : '""') + '';
                    csvLine += ',' + (item.Stocking_UOM__c != null ? itemStockingUOMName : '""') + '';
                    
                    for (Schema.FieldSetMember f:ItemService.costRollupFields) {
                        csvLine += ',"' + itemCost.get(f.fieldPath) + '"';
                    }
                    csvLine += ',"' + itemCost.Standard_Cost__c + '"';

                    if (document.Body != null) csvLine = document.Body.toString() + csvLine;
                    document.Body = Blob.valueOf(csvLine);
                }
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(items, ex.getMessage(), ex.getStackTraceString()));
        }
    }

    public void finish(Database.BatchableContext bc) {
        String headers;
        if (readReport) {
            headers = ItemService.generateExpandedBOMHeader(maxLevel);
        } else {
            headers = '"Item Cost","Item","Company","Facility","Component Cost Status","Assembly Cost Status","Item Description","Item Source","Item Stocking UOM"';
            for (Schema.FieldSetMember f:ItemService.costRollupFields) {
                headers += ',"' + f.getLabel() + '"';
            }
            headers += ',"Total Cost"';
        }

        if (document.Body != null) headers += document.Body.toString();
        document.Body = Blob.valueOf(headers);
        DML.insertAsUser(document);
        
         Map<Id, String> chatterMessages = BatchToChatter.processBatchInformation(BC.getJobId(), this, messages);
         if(chatterMessages.values().size() > 0) {
         	String emailMessage = chatterMessages.values()[0];
         	emailMessage += '<br />View Document:  <a href=' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + document.Id + '>' + document.Name + '</a>';
         	emailMessage += '<br />Download Document:  <a href=' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file='+document.Id + '>' + document.Name + '</a>';
            KSE.sendEmailBatchCompletion(emailMessage,'Batch Apex Job:  ' + string.valueOf(this).substringBefore(':') + ' Completed.');
        }
    }

    public class ItemSpecificationCostRollupException extends Exception { }
}