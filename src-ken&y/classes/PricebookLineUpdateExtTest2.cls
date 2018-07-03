/**
 * TestFuel based version for running tests at better speed
 */
@isTest
public class PricebookLineUpdateExtTest2 {
    testMethod static void testPricebookRelatedListExt() {
        TestFuel fuel = new TestFuel();
        PricebookRelatedListExt ext = new PricebookRelatedListExt(new ApexPages.StandardController(fuel.pricebook));
        System.assertEquals(fuel.pricebook, ext.config.parentRecord);
    }
    
    testMethod static void testRelatedFilters() {
        TestFuel fuel = new TestFuel();
        Pricebook__c pb = fuel.pricebook;
		Hierarchy__c hierarchy1 = fuel.hierarchy1;
		
        Pricebook_Line__c pl3 =new Pricebook_Line__c();
        pl3.product_group__c = fuel.productGroup.id;
        pl3.pricebook__c = fuel.pricebook.id;
        pl3.price__c = 12.11;
        pl3.start_date__c = system.today();
		insert pl3;
        
        
        KendoExt.LoadRecordsRelatedFilterInfo filterInfo = new KendoExt.LoadRecordsRelatedFilterInfo();
        filterInfo.relatedFilterValues = new Map<String, Object>{
                                                                'companyId' => fuel.company.id, 
                                                                'productId' => fuel.product.id
                                                                };
        
        PricebookLineUpdateExt.PricebookRelatedFilterLimiter pbLimiter = new PricebookLineUpdateExt.PricebookRelatedFilterLimiter();
        pbLimiter.setLoadRecordsRelatedFilterInfo(filterInfo);
        System.assertEquals(true, pbLimiter.hasRelevantIds());
        System.assert(pbLimiter.getRelevantIds().contains(pb.id));
        
        
        PricebookLineUpdateExt.ProductGroupRelatedFilterLimiter pgLimiter = new PricebookLineUpdateExt.ProductGroupRelatedFilterLimiter();
        pgLimiter.setLoadRecordsRelatedFilterInfo(filterInfo);
        System.assertEquals(true, pgLimiter.hasRelevantIds());
        System.assertEquals(0, pgLimiter.getRelevantIds().size());
        
        filterInfo.relatedFilterValues = new Map<String, Object>{
                                                                'companyId' => fuel.company.id, 
                                                                'productGroupId' => fuel.productGroup.id
                                                                };
        
        pgLimiter = new PricebookLineUpdateExt.ProductGroupRelatedFilterLimiter();
        pgLimiter.setLoadRecordsRelatedFilterInfo(filterInfo);
        System.assertEquals(false, pgLimiter.hasRelevantIds());
        System.assertEquals(1, pgLimiter.getRelevantIds().size());
        //System.debug(LoggingLevel.INFO, '*** pgLimiter: ' + pgLimiter);

        filterInfo.relatedFilterValues = new Map<String, Object>{
                                                                'companyId' => fuel.company.id, 
                                                                'pricebookId' => pb.id
                                                                };
        
        
        PricebookLineUpdateExt.ProductRelatedFilterLimiter pLimiter = new PricebookLineUpdateExt.ProductRelatedFilterLimiter();
        pLimiter.setLoadRecordsRelatedFilterInfo(filterInfo);
        System.assertEquals(true, pLimiter.hasRelevantIds());
        System.assertEquals(3, pLimiter.getRelevantIds().size());
        

        filterInfo.relatedFilterValues = new Map<String, Object>{
                                                                'companyId' => fuel.company.id, 
                                                                'productGroupId' => fuel.productGroup.id
                                                                };
        PricebookLineUpdateExt.HierarchyRelatedFilterLimiter hLimiter = new PricebookLineUpdateExt.HierarchyRelatedFilterLimiter();
        hLimiter.setLoadRecordsRelatedFilterInfo(filterInfo);
        System.assertEquals(true, hLimiter.hasRelevantIds());
        System.assertEquals(1, hLimiter.getRelevantIds().size());
        
    }
}