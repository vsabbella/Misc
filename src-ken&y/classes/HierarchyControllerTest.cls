@isTest
public with sharing class HierarchyControllerTest {
    
    static Hierarchy__c h(string code,string parent) {
        return new Hierarchy__c( name = code+'_'+parent,
                             //   Primary_Key__c = code+string.valueof(system.today()), 
                                Code__c = code, 
                                Parent_Code__c = parent,
                                Type__c = 'Product Hierarchy');
    }
    static Hierarchy__c h(string code,string parent, date start, date endd) {
        return new Hierarchy__c( name = code+'_'+parent,
                                Primary_Key__c = code+string.valueof(start), 
                                Code__c = code, 
                                Parent_Code__c = parent,
                                start_date__c = start, 
                                end_date__c = endd,
                                Type__c = 'Product Hierarchy');
    }

    public static testmethod void test_invalidData_codes() { 
        // if the parent code == code, we want to block that data at load time, AND we want to 
        // detect it if possible in the overview page
        Hierarchy__c root = h('root',null);
        boolean didexcept = false;
        try {
            insert new list<Hierarchy__c>{root,
                h('L2','root'),
                h('Same','L2'),
                h('Same', 'Same'),
                h('100230','Same')
                };
        } catch( Exception ex ) {
            didexcept = true;
        }
        system.assert(didexcept, ' expected Exception');
        
       	/* not testable since we added a validation rule to prevent the insert
		boolean didexcept = false;
        try { 
            List<HierarchyController.Node> tree = HierarchyController.getHierarchy( root.id );
        } catch( HierarchyController.HierarchyException he ) {
            didexcept = true;
        }
        system.assert(didexcept, ' expected HierarchyException');
		*/
    }
         
    
    public static testmethod void test_duplicate_codes() { 
    	// some Hierarchies are cyclical, test that
    	Hierarchy__c root = h('root',null);
        insert new list<Hierarchy__c>{root,
            h('L2','root'),
            h('PromoGroup','L2'),
            h('ProdGroup', 'L2'),
            h('100230','PromoGroup'),
            h('100230','ProdGroup'),
            h('584230C','100230')           
            };
        
       	List<HierarchyController.Node> tree = HierarchyController.getHierarchy( root.id );
		//system.debug( LoggingLevel.INFO, tree);
    }
    
    
    public static testmethod void test_eff_date() { 
        Hierarchy__c root = h('DLM Ops_L8',null);
        insert new list<Hierarchy__c>{root,
            h('DMPP_L7','DLM Ops_L8'),
            h('Pet Fd_L6','DMPP_L7'),
            h('NB_L5', 'Pet Fd_L6'),
            h('some_L4', 'NB_L5'),
            h('some_L3', 'some_L4'),
            h('some_L2', 'some_L3'),
            h('product_grp', 'some_L2'),
            h('promo group', 'some_L2'),
            h('caseupc', 'promo group'),
            h('2323','caseupc',system.today(),              system.today().addDays(2)), // expires soon
            h('2323_new','caseupc',system.today().addDays(2),   null)                       // effective soon
            };
        
        Process_Job__c job = new Process_Job__c(name= 'Hierarchy Path',apex_class__c = 'HierarchyPathBatch',Batch_Size__c=17,   
                                               Description__c = 'Generates proper Path values from the Hierarchy relationships',Interval__c = 1.0,Frequency__c = 'Days' , Active__c = true);
        insert job;
                
        Test.setCurrentPage( Page.HierarchyView );
        
        Test.startTest();
        Hierarchy__c L5 = [select id from Hierarchy__c where code__c = 'NB_L5' limit 1 ];
        Hierarchy__c n2223 =  [select id from Hierarchy__c where code__c = '2323' limit 1 ];
        Hierarchy__c n2323_new =  [select id from Hierarchy__c where code__c = '2323_new' limit 1 ];
        
        string futureDateString = system.now().addDays(10).format('yyyy-MM-dd');
        
        ApexPages.currentPage().getParameters().put('id',L5.id);
        ApexPages.currentPage().getParameters().put('date', futureDateString );
        Apexpages.standardController c = new Apexpages.standardController(L5);
        HierarchyController hc = new HierarchyController( c);
        //system.debug(LoggingLevel.INFO, hc.eff_date );
        system.assertEquals( Date.valueof(futureDateString ), hc.eff_date,'date value of mis-match' );
        
        // check that 2323-new is not in the tree today, but is in the tree in 3 days from now
        system.assert( isIdInHierarchy(system.today(), root.id, L5.Id), ' L5 should be in hierarchy');
        
        system.assert( isIdInHierarchy(system.today(), root.id, n2223.Id), ' n2223 should be in hierarchy today');
        system.assert( false == isIdInHierarchy(system.today().addDays(5), root.id, n2223.Id), ' n2223 should NOT be in hierarchy next week');
        system.assert( isIdInHierarchy(system.today().addDays(5), root.id, n2323_new.Id), ' n2223_new should  be in hierarchy next week');
        
        // test the batch 
        new HierarchyPathBatch( ).runBatch(job);
        Test.stopTest();
        
        // see if path is set
        system.assert( [ select path__c,id from Hierarchy__c where code__c = 'NB_L5' limit 1 ].Path__c != null ,' expected a path');
    }
    
    // check that a given id is in the hierarchy on a given date
    static boolean isIdInHierarchy(date dd, id top, id mustbe) {
        boolean ret = false; 
        string yr = string.valueof(dd.year());
        string month = string.valueof(dd.month());
        string day = string.valueof(dd.day());
        HierarchyController.Node tmp = HierarchyController.getHierarchyWithDate(top, yr+'-'+month+'-'+day)[0];
        for (id nod: HierarchyController.children(tmp) ) {
            if ( nod == mustbe) {
                ret = true;
            }
        }
        return ret;
    }
    
    public static  testmethod  void test_hier_tall() {
        Hierarchy__c root = h('DLM Ops_L8',null);
        insert new list<Hierarchy__c>{root,
            h('DMPP_L7','DLM Ops_L8'),
            h('Pet Fd_L6','DMPP_L7'),
            h('NB_L5', 'Pet Fd_L6'),
            h('some_L4', 'NB_L5'),
            h('some_L3', 'some_L4'),
            h('some_L2', 'some_L3'),
            h('product_grp', 'some_L2'),
            h('promo group', 'some_L2'),
            h('caseupc', 'promo group')
            };
                
       	// test children()
        Hierarchy__c L5 = [select id from Hierarchy__c where code__c = 'NB_L5' limit 1 ];
        system.assert( L5.Id != null ,' expected L5 ');
        List<HierarchyController.Node> top = HierarchyController.getHierarchy(L5.Id); 
        
        //system.debug(LoggingLevel.INFO, tmp);
        system.assertEquals(true, top[0].expanded, 'expected root to be expanded');
        HierarchyController.Node node = HierarchyController.getNodeById( top[0], L5.Id );
        system.assertNotEquals(null, node,' expected to have the L5 node ');
        system.assertEquals( true, node.selected, ' epxected L5 node to be selected');
        
        system.assertEquals(null, HierarchyController.getNodeById( node, root.id) ,' expected null since L5 is below root');
        
        // test children()
        system.assertEquals( 10, HierarchyController.children( top[0] ).size(), 'epxected 10 ids to be listed');
        
        // move the effective date back and test that none of the rows are returned
        string farPastDateString = system.now().addDays(-1000).format('yyyy-MM-dd');
        List<HierarchyController.Node> eff_minus_two = HierarchyController.getHierarchyWithDate(L5.Id, farPastDateString ); 
        //system.debug(LoggingLevel.INFO, eff_minus_two);
        //system.debug(LoggingLevel.INFO, HierarchyController.children( eff_minus_two[0] ).size() );
        system.assertEquals( 1, HierarchyController.children( eff_minus_two[0] ).size() ); // 1 (top) since start date is before today
        
    }
    
    
    public static  testmethod  void test_hier() {
        
        Hierarchy__c root = h('DLM Ops_L8',null);
        insert new list< Hierarchy__c>{ root,  h('DMPP_L7','DLM Ops_L8')    };
            
            List<HierarchyController.Node> tmp = HierarchyController.getHierarchy( root.id );
        
        system.assert( tmp[0].selected, 'expected the first node to be selected');
        string ret = Json.serialize( tmp  ) ;
        //system.debug( LoggingLevel.INFO, ret );
        system.assert( ret != null );
        system.assert( ret.contains( 'DMPP_L7' ) );
        system.assert( ret.contains( 'DLM Ops_L8' ) );
        
    } 
    
    public static testmethod void test_missingtop() {
        
        Hierarchy__c root = h('DLM Ops_L8','null'); insert root;
        
        // test that we can provide a proper exception when the top does not exist
        // that is, the top has a parent code which is not empty.
        HierarchyController con = new HierarchyController( new Apexpages.standardController( root ) ); 
        boolean saw = false; 
        try { 
            con.setHierarchyPath();
        }
        catch( Exception e) {
            saw = true;
        }
       	system.assert( saw, ' expected an exception msg');
        
    }
 
    /* tests for HierarchyManageExt */
    public static testmethod void test_manage() {
        Hierarchy__c root = h('DLM Ops_L8',null);
        insert new list<Hierarchy__c>{root,
            h('DMPP_L7','DLM Ops_L8'),
            h('Pet Fd_L6','DMPP_L7'),
            h('NB_L5', 'Pet Fd_L6'),
            h('some_L4', 'NB_L5'),
            h('some_L3', 'some_L4'),
            h('some_L2', 'some_L3'),
            h('product_grp', 'some_L2'),
            h('promo group', 'some_L2'),
            h('caseupc', 'promo group')
            };
        
        Hierarchy__c L5 = [select id from Hierarchy__c where code__c = 'NB_L5' limit 1 ];
    	
        Test.setCurrentPage( Page.HierarchyManage );        
        Test.startTest();
        
        HierarchyManageExt con = new HierarchyManageExt( new Apexpages.standardController( L5 ) ); 
        system.assertEquals('NB_L5', con.originalNode.Code__c , ' miss match Code__c');
        system.assertEquals('NB_L5', con.newNode.Code__c , ' miss match Code__c');    
        
        // make some change here
        con.newNode.Parent__c = root.id;
        
        // perform the move
    	PageReference p = con.moveNode();
    	system.assert( p != null , ' expected to go to the new record');
        // validate moved node 
        string newid = p.getUrl().replace('/','') ;
        system.debug( LoggingLevel.info, newid );
        Hierarchy__c tmp = [ select id, name, parent_code__c from 
                                         Hierarchy__c where id =:newid limit 1];
        system.debug( LoggingLevel.info,tmp);
        system.assertequals( root.Code__c, tmp.parent_code__c ,' expected parent code set');
        
        // TODO test the error conditions
        // invalid date error
        con = new HierarchyManageExt( new Apexpages.standardController( L5 ) ); 
        con.newNode.Parent__c = root.id;
        con.newNode.start_date__c = con.newNode.start_date__c.addDays(-10);
        p = con.moveNode();
        system.assertequals( null, p, 'expected an error msg');
        
        // null parent error
        con = new HierarchyManageExt( new Apexpages.standardController( L5 ) ); 
        con.newNode.Parent__c = null;
        p = con.moveNode();
        system.assertequals( null, p, 'expected an error msg');
    }
}