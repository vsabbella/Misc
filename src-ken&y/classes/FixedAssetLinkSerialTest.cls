@isTest
private class FixedAssetLinkSerialTest {

    static testMethod void testLinkSerialsToAsset() {
        FixedAssetData fad = new FixedAssetData();
        Company__c company = fad.td.company;
        
        Test.startTest();
        Facility__c facility = new Facility__c(
                                     Name = 'Facility',
                                     Company__c = company.Id,
                                     Primary_Key__c = 'FA001',
                                     Description__c = 'Facility.');
          insert facility;   
          Location__c   location = new Location__c(
                                     Facility__c = facility.id,
                                     Description__c = 'location',
                                     name = 'Location1'  );
          insert location;
          
          Item_Attribute__c itemAttr = new Item_Attribute__c();
                itemAttr.Name = 'Attribute-1';
                itemAttr.Expiration_Date__c = true;
                itemAttr.Lot_Number__c = false; 
                itemAttr.Minimum_Shelf_Life_In_Days__c = false;
                itemAttr.Serial_Number__c = true;
                itemAttr.Fixed_Asset__c = true; 
          insert itemAttr;
                
          Item__c item = new Item__c();
                item.name = 'Item-';
                item.Description__c='Items';
                item.Source__c = 'Manufactured';
                item.company__c = company.Id;
                item.item_attribute__c = itemAttr.Id;
                item.Active__c = true;   
          insert item;
           
          SKID__c skid = new SKID__c();
                skid.location__c = location.id;
                skid.Quantity__c = 200.0;
                skid.Item__c = item.Id;
                skid.company__c = company.Id; 
                skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
                skid.Expiration_Date__c = System.today() + 365;   
          insert  skid;
           
          Serial__c assetSerial = new Serial__c(
                Name = 'Asset Serial',
                Item__c = skid.Item__c,
                Company__c = company.Id,
                Allow_Reentry__c = false,
                Status__c  ='Inventory',
                SKID__c    = skid.Id
          );
          assetSerial.Unique_Key2__c = company.Id + '-' + skid.Item__c + '-' + assetSerial.Name;
          insert assetSerial;
          List<Serial__c> selectedSerialsList = new List<Serial__c>();
          selectedSerialsList.add(assetSerial);
          system.debug('selectedSerialsList---'+selectedSerialsList);
          
          Apexpages.Standardcontroller Con = new Apexpages.Standardcontroller(fad.slfa);
          test.setCurrentPage(page.FixedAssetLinkToSerial);
          FixedAssetLinkToSerialExt ext = new FixedAssetLinkToSerialExt(Con);
            
          system.debug(' ext.faLinesConfig '+ ext.faLinesConfig );
          ext.getFaLinesFieldList();
          ext.getFaLinesConfigJson();
          String returnUrl = ext.getReturnUrl();
          system.assert(returnUrl.contains(''+fad.slfa.Id+''));
          //AttachSerialsToFAExt.getFALines(ext.faLinesConfig,company.Id);
          //FixedAssetLinkToSerialExt.attachSerialsTOFA(slfa.Id,null);
          
          //system.assert( Apexpages.hasMessages() == true, ' Expected error msg');   
          
          FixedAssetLinkToSerialExt.attachSerialsTOFA(fad.slfa.Id,selectedSerialsList);
           
             
        Test.stopTest();
        
        Serial__c serialAfterLinking = [SELECT id,name,Fixed_Asset__c 
                                            FROM Serial__c 
                                            WHERE id = :assetSerial.Id limit 1];
        
        system.debug('serialAfterLinking--'+serialAfterLinking);
        system.assertNotEquals(serialAfterLinking.Fixed_Asset__c,null);
        system.assertEquals(serialAfterLinking.Fixed_Asset__c,fad.slfa.Id);
        
    }
}