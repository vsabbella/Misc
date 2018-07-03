@istest
public class SegmentHierarchyViewManageTest {
    
    //Move to @testdatasetup
    @testSetup static Void  SegHierDataSetup(){
        TestFuel fuel = new TestFuel();
		list<hierarchy__c> hierarchylist = new list<hierarchy__c>();        
		list<sObject> sObjects = new list<sObject>();        

            System.Assert(fuel.customsegList.size()>0,'Expecting custom setting to be created.');
            System.AssertNotEquals(fuel.company,null,'Expecting company to be created.');   
            System.AssertNotEquals(fuel.GLTypeTestData,null,'Expecting GL type to be created.');   
            System.AssertNotEquals(fuel.GLAccountTestData,null,'Expecting GL accounts to be created.');
			System.AssertNotEquals(fuel.periodList,null,'Expecting Period to be created.');
            hierarchy__c hrec1 = new hierarchy__c(Name = 'Test Hierarchy 1', Code__c = fuel.GLAccountTestData[0].id, Start_DateTime__c = system.now(), type__c = 'GL Account');
            hierarchylist.add(hrec1);
            sObjects.add(fuel.GLAccountTestData[0]);  
            hierarchy__c hrec2 = new hierarchy__c(Name = 'Test Hierarchy 1', Code__c = fuel.GLAccountTestData[1].id, Start_DateTime__c = system.now(), type__c = 'GL Account');
            hierarchylist.add(hrec2);  
            sObjects.add(fuel.GLAccountTestData[1]);  
            hierarchy__c hrec3 = new hierarchy__c(Name = 'Test Hierarchy 1', Code__c = fuel.GLAccountTestData[2].id, Start_DateTime__c = system.now(), type__c = 'GL Account');
            hierarchylist.add(hrec3);  
            sObjects.add(fuel.GLAccountTestData[2]);  
            hierarchy__c hrec4 = new hierarchy__c(Name = 'Test Hierarchy 1', Code__c = fuel.GLAccountTestData[3].id, Start_DateTime__c = system.now(), type__c = 'GL Account');
            hierarchylist.add(hrec4);  
            hierarchy__c hrec5 = new hierarchy__c(Name = 'Test Hierarchy 1', Code__c = fuel.GLAccountTestData[4].id, Start_DateTime__c = system.now(), type__c = 'GL Account');
            hierarchylist.add(hrec5);  
            hierarchy__c hrec6 = new hierarchy__c(Name = 'Test Hierarchy 1', Code__c = fuel.GLAccountTestData[5].id, Start_DateTime__c = system.now(), type__c = 'GL Account');
            hierarchylist.add(hrec6);  
            sObjects.add(fuel.GLAccountTestData[3]);  
            insert hierarchylist;
            //segIds.addAll(new list<Id>{fuel.GLAccountTestData[4].id,fuel.GLAccountTestData[5].id,fuel.GLAccountTestData[6].id,fuel.GLAccountTestData[7].id});
    }

    public static testmethod void testSegmentHierarchyViewManagePage(){
         Test.startTest();
         list<hierarchy__c> hierarchys =[Select Name,Code__c, Start_DateTime__c, type__c From hierarchy__c where Name= 'Test Hierarchy 1'];
		 list<Id> segIds = new list<Id>();
		 list<GL_Account__c> glAccountList = [Select Name,Id,GL_Account_Number__c,GL_Account_Name__c,GL_Type_Code__c,Active__c,FX_Type__c  From GL_Account__c];       
         segIds.addAll(new list<Id>{glAccountList[4].id,glAccountList[5].id,glAccountList[6].id,glAccountList[7].id});
         list<hierarchy__c> hierarchylist = new list<hierarchy__c>{hierarchys[0],hierarchys[1],hierarchys[2],hierarchys[3]};
         list<hierarchy__c> hierarchylistupdated = new list<hierarchy__c>{hierarchys[4],hierarchys[5]};
		 string asOfDateJSON = JSON.serialize(system.now().adddays(2));
		 string asOfDateNewJSON = JSON.serialize(system.now().adddays(4));
		 string SegRecsToBeInsertedJSON = JSON.serialize(segIds);
		 string SegRecsJSON = JSON.serialize(glAccountList);
		 string HierRecSer = JSON.serialize(hierarchylist[0]);
		 string HierRecDestinationSer = JSON.serialize(hierarchylist[1]);
		 string HirecsToBeInsertedJSON = JSON.serialize(hierarchylistupdated);
		 string HirecsToBeUpdatedJSON = JSON.serialize(hierarchylist);
		 SegmentHierarchyViewManageExt.checkHierarchyNameAvailability('Test Hierarchy 1','GL Account');
		 SegmentHierarchyViewManageExt.FetchHierarchy('Test Hierarchy 1','GL Account', asOfDateJSON,null);
		 SegmentHierarchyViewManageExt.FetchHierarchy('Test Hierarchy 1','GL Account', asOfDateJSON,asOfDateNewJSON);
		 SegmentHierarchyViewManageExt.FetchHierarchyList('GL Account');
		 SegmentHierarchyViewManageExt.getHierarchyTypeList();
		 SegmentHierarchyViewManageExt.addSegmentToTreelist(SegRecsToBeInsertedJSON,'Test Hierarchy 1',asOfDateJSON,'GL Account');
		 SegmentHierarchyViewManageExt.getFieldInfoList('GL_Account__c',null,null,'');
		 SegmentHierarchyViewManageExt.getSegmentValueList('GL Account');
		 SegmentHierarchyViewManageExt.FetchSegmentList(SegRecsJSON,'GL_Account__c');
		 SegmentHierarchyViewManageExt.treeListRead(asOfDateJSON,null,'','','',SegRecsJSON,'','GL Account','Test Hierarchy 1');
		 SegmentHierarchyViewManageExt.CheckHierarchyExists('Test Hierarchy 1','GL Account',asOfDateJSON);
		 SegmentHierarchyViewManageExt.EventDeleteRow(asOfDateJSON,HierRecSer,hierarchylist[0].id,'GL Account','Test Hierarchy 1',SegRecsJSON,segIds);
		 SegmentHierarchyViewManageExt.EventDragAndDrop(asOfDateJSON,HierRecSer,hierarchylist[0].id,HierRecDestinationSer,hierarchylist[1].id,'GL Account','Test Hierarchy 1');
		 SegmentHierarchyViewManageExt.SaveResult(HirecsToBeInsertedJSON,HirecsToBeUpdatedJSON);
		 SegmentHierarchyViewManageExt.DeleteHierarchy('Test Hierarchy 1','GL Account',asOfDateJSON);
		 Test.stopTest();
    }

}