@isTest
private class ASNAPITest {
    private class ASNAPITestData {
        public TestFuel fuel { get; set; } { fuel = new TestFuel(); }
        public FOB_Terms__c fobTerm { get; set; } {
            fobTerm = new FOB_Terms__c(
                Name = 'Origin',
                FOB_Point__c = 'Origin'
            );
            insert fobTerm;
        }
        public ASN__c asn { get; set; } {
            asn = new ASN__c(
                Company__c = fuel.company.Id,
                Supplier__c = fuel.supplier.Id,
                Facility__c = fuel.facility2.Id,
                FOB__c = fobTerm.Id
            );
        }
        public List<ASN_Line__c> asnLines { get; set; } {
            asnLines = new List<ASN_Line__c>();
            ASN_Line__c asnLine = new ASN_Line__c(
                Purchase_Order__c = fuel.purchaseOrder.Id,
                Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id,
                Quantity_Shipped__c = 10
            );
            asnLines.add(asnLine);
        }
        
        public ASNAPITestData() {
            List<Period__c> periods = fuel.periodList;
            update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Expiration_Date__c = false);
        }
    }
    
    private static testMethod void testCreate() {
        Map<String,ASNAPI.Status> result = ASNAPI.createASN(null,null);
        System.assert(result != null && result.size() == 0);
        
        ASNAPITestData tData = new ASNAPITestData();
        
        Map<String,ASN__c> asnHeaders = new Map<String,ASN__c>{ '1' => tData.asn };
        Map<String,Map<ASN_Line__c,List<SKID__c>>> asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>() };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>() } };
        Id companyId = tData.asn.Company__c;
        tData.asn.Company__c = null;
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        tData.asn.Company__c = companyId;
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        SKID__c skid1 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'A',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        SKID__c skid2 = new SKID__c(Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        Id poId = tData.asnLines[0].Purchase_Order__c;
        tData.asnLines[0].Purchase_Order__c = null;
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        tData.asnLines[0].Purchase_Order__c = poId;
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        skid2.Quantity__c = 1;
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        skid2.Quantity__c = 5;
        Id polId = tData.asnLines[0].Purchase_Order_Line__c;
        tData.asnLines[0].Purchase_Order_Line__c = tData.fuel.company.Id;
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        tData.asnLines[0].Purchase_Order_Line__c = polId;
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && !result.get('1').success);
        
        skid2.Lot_Number__c = 'B';
        asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        result = ASNAPI.createASN(asnHeaders,asnLines);
        System.assert(result != null && result.containsKey('1') && result.get('1').success);
        System.assert([SELECT Id FROM ASN__c WHERE Status__c = 'Draft'].size() == 1);
        System.assert([SELECT Id FROM ASN_Line__c WHERE Status__c = 'New'].size() == 1);
        System.assert([SELECT Id FROM SKID__c WHERE Type__c = 'Draft In-Transit'].size() == 2);
    }
    
    private static testMethod void testConfirm() {
        ASNAPITestData tData = new ASNAPITestData();
        SKID__c skid1 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'A',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        SKID__c skid2 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'B',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        
        Map<String,ASN__c> asnHeaders = new Map<String,ASN__c>{ '1' => tData.asn };
        Map<String,Map<ASN_Line__c,List<SKID__c>>> asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        ASNAPI.createASN(asnHeaders,asnLines);
        
        Map<Id,ASNAPI.Status> result = ASNAPI.confirm(null);
        System.assert(result != null && result.size() == 0);
        
        result = ASNAPI.confirm(new Set<Id>{ tData.fuel.company.Id });
        System.assert(result != null && result.containsKey(tData.fuel.company.Id) && !result.get(tData.fuel.company.Id).success);
        
        Id asnId = [SELECT Id FROM ASN__c LIMIT 1].Id;
        result = ASNAPI.confirm(new Set<Id>{ asnId });
        System.assert(result != null && result.containsKey(asnId) && result.get(asnId).success);
        System.assert([SELECT Id FROM ASN__c WHERE Status__c = 'Confirmed'].size() == 1);
        System.assert([SELECT Id FROM ASN_Line__c WHERE Status__c = 'Open'].size() == 1);
        System.assert([SELECT Id FROM SKID__c WHERE Type__c = 'In-Transit'].size() == 2);
        System.assert([SELECT Id FROM Receiving_Document__c WHERE Type__c = 'In-Transit'].size() == 0);
        System.assert([SELECT Id FROM Receipt_Line__c WHERE Receiving_Document__r.Type__c = 'In-Transit'].size() == 0);
    
        result = ASNAPI.confirm(new Set<Id>{ asnId });
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
        
        List<SKID__c> intransitskidList = [Select Id,Type__c,ASN_Line__c from SKID__c where ASN_Line__c =: tData.asnLines[0].Id and Type__c = 'In-Transit'];
        system.assert(intransitskidList.size()==2,intransitskidList);
        
        
        List<Inventory_Transaction__c> inTransitITs = [Select Id,Type__c,ASN_Line__c from Inventory_Transaction__c where ASN_Line__c = :tData.asnLines[0].Id and Type__c = 'In-Transit'];
        system.assert(inTransitITs.size()==2,inTransitITs);
    }
    
    private static testMethod void testReceive() {
        ASNAPITestData tData = new ASNAPITestData();
        SKID__c skid1 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'A',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        SKID__c skid2 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'B',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        Map<String,ASN__c> asnHeaders = new Map<String,ASN__c>{ '1' => tData.asn };
        Map<String,Map<ASN_Line__c,List<SKID__c>>> asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        ASNAPI.createASN(asnHeaders,asnLines);
        Id asnId = [SELECT Id FROM ASN__c LIMIT 1].Id;
        ASNAPI.confirm(new Set<Id>{ asnId });
        
        Map<Id,ASNAPI.Status> result = ASNAPI.receive(null);
        System.assert(result != null && result.size() == 0);
        
        Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>> asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ tData.fuel.company.Id => new Map<Id,List<ASNAPI.ReceivingLine>>() };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(tData.fuel.company.Id) && !result.get(tData.fuel.company.Id).success);
    
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>() };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
    
        Id asnLineId = [SELECT Id FROM ASN_Line__c LIMIT 1].Id;
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>() } };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
    
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>{ new ASNAPI.ReceivingLine() } } };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
        
        ASNAPI.ReceivingLine rLine1 = new ASNAPI.ReceivingLine();
        ASNAPI.ReceivingLine rLine2 = new ASNAPI.ReceivingLine();
        rLine1.skid = new SKID__c();
        rLine2.skid = new SKID__c();
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>{ rLine1, rLine2 } } };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
    
        rLine1.skid.Quantity__c = 5;
        rLine2.skid.Quantity__c = 6;
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>{ rLine1, rLine2 } } };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
    }
    
    private static testMethod void testReceive2() {
        ASNAPITestData tData = new ASNAPITestData();
        List<Stock_Movement_Rule_Settings__c> smrsList = tData.fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = tData.fuel.stockMovementRuleList;
        SKID__c skid1 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'A',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        SKID__c skid2 = new SKID__c(Quantity__c = 5,Lot_Number__c = 'B',Stocking_UOM__c = tData.fuel.uomObj.Id,Packaging_UOM__c = tData.fuel.uomObj.Id);
        Map<String,ASN__c> asnHeaders = new Map<String,ASN__c>{ '1' => tData.asn };
        Map<String,Map<ASN_Line__c,List<SKID__c>>> asnLines = new Map<String,Map<ASN_Line__c,List<SKID__c>>>{ '1' => new Map<ASN_Line__c,List<SKID__c>>{ tData.asnLines[0] => new List<SKID__c>{ skid1, skid2 } } };
        ASNAPI.createASN(asnHeaders,asnLines);
        Id asnId = [SELECT Id FROM ASN__c LIMIT 1].Id;
        ASNAPI.confirm(new Set<Id>{ asnId });
        
        Id asnLineId = [SELECT Id FROM ASN_Line__c LIMIT 1].Id;
        ASNAPI.ReceivingLine rLine1 = new ASNAPI.ReceivingLine();
        ASNAPI.ReceivingLine rLine2 = new ASNAPI.ReceivingLine();
        
        List<Lot__c> lots = [Select Id,Name from Lot__c where Name IN('A','B')];
        Id lotA;
        Id lotB;
        for(Lot__c lotObj:lots){
            if(lotObj.Name == 'A'){
                lotA = lotObj.Id;
            }
            if(lotObj.Name == 'B'){
                lotB = lotObj.Id;
            }
            
        }
        rLine1.skid = new SKID__c(Quantity__c = 5);
        rLine2.skid = new SKID__c(Quantity__c = 6);
        Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>> asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>{ rLine1, rLine2 } } };
        Map<Id,ASNAPI.Status> result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
        
        rLine1.skid.Lot_Number__c = 'A';
        rLine1.skid.Stocking_UOM__c = tData.fuel.uomObj.Id;
        rLine1.skid.Packaging_UOM__c = tData.fuel.uomObj.Id;
        rLine1.skid.Facility2__c = tData.asn.Facility__c;
        rLine1.skid.Lot__c = lotA;
        rLine2.skid.Lot_Number__c = 'B';
        rLine2.skid.Stocking_UOM__c = tData.fuel.uomObj.Id;
        rLine2.skid.Packaging_UOM__c = tData.fuel.uomObj.Id;
        rLine2.skid.Facility2__c = tData.asn.Facility__c;
        rLine2.skid.Lot__c = lotB;
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>{ rLine1, rLine2 } } };
        result = ASNAPI.receive(asnsToReceive);
        System.assert(result != null && result.containsKey(asnId) && !result.get(asnId).success);
        
        rLine2.skid.Quantity__c = 5;
        asnsToReceive = new Map<Id,Map<Id,List<ASNAPI.ReceivingLine>>>{ asnId => new Map<Id,List<ASNAPI.ReceivingLine>>{ asnLineId => new List<ASNAPI.ReceivingLine>{ rLine1, rLine2 } } };
        Test.startTest();
        result = ASNAPI.receive(asnsToReceive);
        Test.stopTest();
        
        System.assert(result != null && result.containsKey(asnId) && result.get(asnId).success);
        System.assert([SELECT Id FROM Purchase_Order__c WHERE Status__c = 'Closed'].size() == 1);
        System.assert([SELECT Id FROM Receiving_Document__c WHERE Type__c = 'Purchase Order Receipt' AND Transaction_Type__c = 'In-Transit Purchase Order Receipt'].size() == 1);
        System.assert([SELECT Id FROM ASN_Line__c WHERE Status__c = 'Closed'].size() == 1);
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Type__c = 'Purchase Order Receipt'].size() == 2);
    }
}