@isTest 
public with sharing class UOMConversionDetailsExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.itemList != null);
        System.assert(f.location3 != null);
        System.assert(f.location5 != null);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void deleteUomFail() {
        try {
            delete fuel.uomList;
            System.assert(false, 'UOM delete should fail');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.UOM_Cannot_be_Deleted), e.getMessage());
        } 
        
        delete fuel.uomcList;

        try {
            delete fuel.uomList;
        } catch (Exception e) {
            System.assert(false, 'UOM delete should succeed');
        }
    }

    private static testMethod void conversionInsert() {
        List<UOM__c> uoms = fuel.uomList;

        ManageUOMConversionsExt ext = new ManageUOMConversionsExt(new ApexPages.StandardController(uoms[0]));
        ext = new ManageUOMConversionsExt(new ApexPages.StandardSetController(uoms));
        System.assert(ext.NamespaceUU != null);
        ext.getUomConversionLinesConfigJson();
        ext.getUomConversionLinesFieldList();

        List<ManageUOMConversionsExt.UomConversionWrapper> wrappers = (List<ManageUOMConversionsExt.UomConversionWrapper>)ManageUOMConversionsExt.getUOMWrappers(fuel.uomcList).records;
        List<ManageUOMConversionsExt.UomConversionWrapper> newConversions = new List<ManageUOMConversionsExt.UomConversionWrapper>{ wrappers[0].clone() };
        
        newConversions[0].uom1Id = null;
        JsonResult result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom1Id = wrappers[0].uom1Id;
        newConversions[0].uom2Id = null;
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom2Id = wrappers[0].uom2Id;
        newConversions[0].uom1Quantity = null;
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom1Quantity = wrappers[0].uom1Quantity;
        newConversions[0].uom2Quantity = null;
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom2Quantity = wrappers[0].uom2Quantity;
        newConversions[0].uom2Id = newConversions[0].uom1Id;
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom2Id = wrappers[0].uom2Id;
        newConversions.add(newConversions[0].clone());
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions.remove(1);
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom1Id = uoms[11].Id;
        newConversions[0].uom2Id = uoms[13].Id;
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        newConversions[0].uom2Id = uoms[0].Id;
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == true, result);
    }

    private static testMethod void conversionUpdate() {
        fuel.setupInventory(true, false, true);

        List<ManageUOMConversionsExt.UomConversionWrapper> wrappers = (List<ManageUOMConversionsExt.UomConversionWrapper>)ManageUOMConversionsExt.getUOMWrappers(fuel.uomcList).records;
        List<ManageUOMConversionsExt.UomConversionWrapper> updatedConversions = new List<ManageUOMConversionsExt.UomConversionWrapper>{ wrappers[wrappers.size() - 1].clone() };

        updatedConversions[0].uom1Quantity += 1;
        JsonResult result = ManageUOMConversionsExt.saveUomConversionLines(updatedConversions, new List<ManageUOMConversionsExt.UomConversionWrapper>(), new List<ManageUOMConversionsExt.UomConversionWrapper>());
        System.assert(result.success == false, result);

        updatedConversions[0].uom1Quantity = wrappers[wrappers.size() - 1].uom1Quantity;
        List<ManageUOMConversionsExt.UomConversionWrapper> newConversions = updatedConversions;
        List<ManageUOMConversionsExt.UomConversionWrapper> deletedConversions = new List<ManageUOMConversionsExt.UomConversionWrapper>{ wrappers[wrappers.size() - 1].clone() };
        result = ManageUOMConversionsExt.saveUomConversionLines(new List<ManageUOMConversionsExt.UomConversionWrapper>(), newConversions, deletedConversions);
        System.assert(result.success == true, result);
    }
    
    private static testMethod void test_PackageClass() {
    	
    	
    	Package_Class__c PTCls = new Package_Class__c(Name = 'PT');
    	insert PTCls;
    	
    	Package_Class__c CaseCls = new Package_Class__c(Name = 'CS', Parent_Package_Class__c = PTCls.Id);
    	try{
    	    insert CaseCls;
    	}
    	catch(Exception ex){
            System.assert(ex.getMessage().contains('Please choose a default container item on the parent package class'), ex.getMessage());
        }
        //Creating Default Container
        Item__c container = fuel.itemList[0];
    	container.Container__c = true;
    	container.Container_Package_Class__c = PTCls.Id;
    	update container;
    	
    	//Updating Default Container on Pallet Package Class
    	PTCls.Default_Container_Item__c = container.Id;
    	update PTCls;
    	
    	insert CaseCls;
    	
    	//Creating Default Container
        Item__c CScontainer = fuel.itemList[1];
    	CScontainer.Container__c = true;
    	CScontainer.Container_Package_Class__c = CaseCls.Id;
    	update CScontainer;
    	
    	//Updating Default Container on Case Package Class
    	CaseCls.Default_Container_Item__c = CScontainer.Id;
    	update CaseCls;
    	
    	Package_Class__c pkgCls = new Package_Class__c(Name = 'EA', Parent_Package_Class__c = CaseCls.Id);
    	insert pkgCls;
    	
    	List<Package_Class__c> pkgClassList = [Select Id,Level__c from Package_Class__c];
    	for(Package_Class__c pkg:pkgClassList){
    		if(pkg.Id == PTCls.Id){
    			system.assert(pkg.Level__c == 3,pkg);
    		}
    		else if(pkg.Id == CaseCls.Id){
    			system.assert(pkg.Level__c == 2,pkg);
    		}
    		else if(pkg.Id == pkgCls.Id){
    			system.assert(pkg.Level__c == 1,pkg);
    		}
    		
    	}
    	
    	delete pkgCls;
    }
}