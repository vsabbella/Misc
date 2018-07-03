@IsTest
public with sharing class CreateRepairDocumentsExtTest {

    static testMethod void testGenerateSalesOrder() {
        TestFuel fuel = new TestFuel();
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility1 = fuel.facility2;

        //Adding User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);

        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[0];

        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[5];


        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;

        //Update Sales Order Type as RMA
        so.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        so.Status__c = 'Open';
        update so;

        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;


        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'RMA Receipt For Repair',
                Transaction_Type__c = 'RMA Receipt For Repair',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
        );
        insert rd;
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>();
        Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Sales_Order__c = so.Id;
        receiptline1.Sales_Order_Line__c = soline.Id;
        receiptline1.Item__c = fuel.itemList[1].ID;
        receiptline1.Quantity_Received__c = 10;
        receiptline1.Quantity_Still_Due_For_Putaway__c = 10;
        //receiptline1.Expiration_Date__c = System.today()+5;
        receiptline1.Facility__c = facility1.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Closed';
        receiptline1.Sales_Order__c = so.id;
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);

        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Sales_Order__c = so.Id;
        receiptline2.Sales_Order_Line__c = soline1.Id;
        receiptline2.Item__c = fuel.itemList[4].Id;
        receiptline2.Facility__c = facility1.Id;
        receiptline2.Location__c = fuel.location2.Id;

        receiptline2.Quantity_Received__c = 15;
        receiptline2.Quantity_Still_Due_For_Putaway__c = 15;
        receiptline2.Status__c = 'Closed';
        receiptline2.Sales_Order__c = so.id;
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);

        insert receiptlineslist;
        //new SalesOrderService().plan(so.Id);

        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');

        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID

        Receiving_Document__c queriedrd = [Select Id, Name, Currency__c  from Receiving_Document__c where Id =:rd.Id];
        String docnum = rd.Name;
        ID currencyfilter = queriedrd.Currency__c;

        List<Receipt_Line__c> newreceiptlinelist = [Select Id from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);

        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }

        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();

        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');

        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );

        for(ReceivingWrapper rw: rwrapperlist){

            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[1].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                }
            }
        }

        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];

        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);

        test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(queriedrd);
        CreateRepairDocumentsExt ext = new CreateRepairDocumentsExt(standardController);

        test.stopTest();

        system.assertEquals(TRUE, ext.wrapperList != null);
        system.assertEquals(2, ext.wrapperList.size());
        for(RepairGridCon.WarrantyWrapper r : ext.wrapperList) {
            system.assertEquals(FALSE, r.sol.Non_Shippable__c);
            system.assertEquals(FALSE, r.sol.Invoiceable__c);
        }
    }
}