public with sharing class ASNService{

	public static string ASN_STATUS_CONFIRMED = 'Confirmed';
	public static string ASN_STATUS_UNCONFIRMED = 'Unconfirmed';
	public static string ASN_STATUS_DRAFT = 'Draft';
	public static string ASN_STATUS_CANCELLED = 'Cancelled';
	public static string ASN_LINE_STATUS_CANCELLED = 'Cancelled';
	public static string ASN_LINE_STATUS_CLOSED = 'Closed';
	public static string ASN_LINE_STATUS_NEW = 'New';
	public static string ASN_LINE_STATUS_OPEN = 'Open';
	public static string ASN_FOB_ORIGIN = 'Origin';
	public static string RD_TYPE_INTRANSIT = 'In-Transit';
	public static string RECEIVING_SUBTYPE_RECEIPT = 'Receipt';
	public static string RECEIVING_SUBTYPE_RETURN = 'Return';
	private static SchemaUtil util = SchemaUtil.getInstance();
	
	public class ASNServiceException extends Exception{
    }
    
    public static List<ASNAddManageExt.ASNLineWrapper> getASNLineWrappers(set<Id> asnIds, String whereClause){
        
        Set<Id> asnLineIds = new Set<Id>();
        List<SKID__c> allskidlist = new List<SKID__c>();
        Map<Id,List<SKID__c>> asnLineToSkidMap = new Map<Id,List<SKID__c>>();
        List<ASN_Line__c> asnLines = new List<ASN_Line__c>();
        Set<String> addlFields = new Set<String>{'Name', 'Item__r.Name', 'Item__r.Item_Attribute__c', 'Item__r.Non_Inventory__c','Item__r.Source__c','Item__r.Stocking_UOM__c','Item__r.Stocking_UOM__r.Package_Class__c', 'Purchase_Order_Line__r.Company__c','Facility__c',
            'Company__c', 'Company__r.Serial_Control__c','Supplier__c', 'Purchase_Order__r.Type__c', 'Purchase_Order_Line__r.Item__r.Item_Attribute__c','Purchase_Order_Line__r.Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Company__r.Serial_Control__c', 'Purchase_Order_Line__r.Item__c','Purchase_Order_Line__r.Item__r.Packaging_UOM__c',
            'Purchase_Order_Line__r.Purchase_UOM__c','Purchase_Order_Line__r.Quantity_Shipped__c','Purchase_Order_Line__r.Status__c','Purchase_Order_Line__r.Purchase_UOM__r.Name','Purchase_Order_Line__r.Sales_Order_Line__c','ASN__c', 'ASN__r.Company__c', 'ASN__r.Supplier__c', 'ASN__r.Facility__c', 'ASN__r.Status__c', 'ASN__r.Currency__c', 'ASN__r.Currency__r.ISO_Code__c',
            'Purchase_Order_Line__r.Item_Specification__r.Item__r.Container__c','Purchase_Order_Line__r.Item_Specification__r.Item__r.Container_Item__c','Purchase_Order_Line__r.Item_Specification__r.Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Item__r.source__c','Purchase_Order_Line__r.Stocking_UOM__c','Purchase_Order_Line__r.Work_Order__c','Location__r.Facility__c','Purchase_Order_Line__r.Delivery_Facility__c','Purchase_Order_Line__r.Packaging_UOM__r.Name','Purchase_Order_Line__r.Packaging_UOM__c',
            'Purchase_Order_Line__r.Item__r.Container_Item__r.Item_Attribute__c','Purchase_Order_Line__r.Purchase_UOM__r.Name','Purchase_Order_Line__r.Purchase_UOM__r.Package_Class__c','Purchase_Order_Line__r.Purchase_UOM__r.Package_Class__r.Default_Container_Item__c','Purchase_Order_Line__r.Purchase_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Purchase_Order_Line__r.Purchase_UOM__r.Package_Class__r.Level__c','Item__r.Container_Item__c','Item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c' ,
            'Item__r.Container__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c', 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c',
            'Purchase_Order_Line__r.Item__r.Packaging_UOM__c', 'Item__r.Packaging_UOM__c', 'Purchase_order_line__r.purchase_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Purchase_order_line__r.purchase_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'};
        addlFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Purchase_Order_Line__r.Item__r.item_attribute__r.','item_attribute__c') );
        addlFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );
        addlFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Purchase_Order_Line__r.Work_Order__r.Assembly_Item_Specification__r.Item__r.item_attribute__r.','item_attribute__c') );
        SOQLUtil asnLineQuery = new SOQLUtil('ASN_Line__c', TRUE);
        asnLineQuery.addFields('ASN_Line');
        asnLineQuery.addFields(addlFields);
        asnLineQuery.setWhereClause(' ASN__c IN:asnIds ' +whereClause);
        
        asnLines = database.query(asnLineQuery.getQuery());

        Boolean serialTrackedflg = false;
        for (ASN_Line__c a : asnLines){
            asnLineIds.add(a.id);
           if(a.Company__r.Serial_Control__c == 'At receipt and all processes'){
                        	
               serialTrackedflg = true;
           }
        }
        
        Set<String> skidFields = new Set<String>{ 'Location__r.Facility__c','Packaging_UOM__r.Name','Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
        											'Item__r.Container_Item__r.Item_Attribute__c','Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__r.Name','Item__r.Item_Attribute__c','Item__r.Stocking_UOM__r.Package_Class__c','Item__r.Stocking_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__c','Item__r.Stocking_UOM__c','Item__r.Stocking_UOM__r.Package_Class__r.Level__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Item__r.Stocking_UOM__r.Package_Class__r.Level__c','Item__r.Container_Item__c','Item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container_Item__r.Item_Attribute__c','Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
        											'Item__r.Item_Attribute__r.License_Plate_Number__c','Item__r.Container__c', 'Facility2__r.Facility_Identifier__c' };
        Set<Id> skidIds = new Set<Id> ();
        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
        
        skidFields.addAll(util.getAllCustomFieldsFromObject('', 'SKID__c'));
        skidFields.addAll( util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );

        SOQLUtil skidQuery = new SOQLUtil('SKID__c', TRUE);
        skidQuery.addFields(skidFields);
        skidQuery.setWhereClause('ASN_Line__c IN :asnLineIds AND (Type__c = \'Draft In-Transit\' OR Type__c = \'In-Transit\')');
		
		allskidlist = Database.query(skidQuery.getQuery());
		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
        for (SKID__c s : allskidlist){
        	skidIds.add(s.Id);
            List<SKID__c> skids = new List<SKID__c>();
            if (!asnLineToSkidMap.containsKey(s.ASN_Line__c)){
                skids.add(s);
                asnLineToSkidMap.put(s.ASN_Line__c, skids.clone());
            }
            else{
                skids = asnLineToSkidMap.get(s.ASN_Line__c);
                skids.add(s);
                asnLineToSkidMap.put(s.ASN_Line__c, skids.clone());
            }
            if(!itemsWithPackagingUOM.containskey(s.Item__r)){
				itemsWithPackagingUOM.put(s.Item__r,new Set<UOM__c>{});	
		   }
		   itemsWithPackagingUOM.get(s.Item__r).add(s.Packaging_UOM__r);
        }     
		map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
		
		if(serialTrackedflg){
			 SOQLUtil serialQuery = new SOQLUtil('Serial__c');
	    	 serialQuery.addAllCustomFields();
	    	 serialQuery.setWhereClause('Skid__c in : skidIds');
	    	 
	    	 for (Serial__c serial:Database.query(serialQuery.getQuery())) {
	    	 	if (!serialMap.containsKey(serial.SKID__c)) {
	    	 		serialMap.put(serial.SKID__c,new List<Serial__c>());
	    	 	}
	    	 	serialMap.get(serial.SKID__c).add(serial);
	    	 }
	    }
		
        List<ASNAddManageExt.ASNLineWrapper> asnlineswrapper = new List<ASNAddManageExt.ASNLineWrapper>();

        for (ASN_Line__c asnl : asnLines){
            if(asnl.Purchase_Order_Line__r.Item__r.source__c == 'Outside Processing' && asnl.Purchase_Order_Line__r.Work_Order__c != null){
                 asnl.Item__r.Item_Attribute__c =  asnl.Purchase_Order_Line__r.Work_Order__r.Assembly_Item_Specification__r.Item__r.item_attribute__c;
                 asnl.Item__r.Item_Attribute__r =  asnl.Purchase_Order_Line__r.Work_Order__r.Assembly_Item_Specification__r.Item__r.item_attribute__r;  
                }else {
                 asnl.Item__r.Item_Attribute__c = asnl.Purchase_Order_Line__r.Item__r.Item_Attribute__c; 
                 asnl.Item__r.Item_Attribute__r = asnl.Purchase_Order_Line__r.Item__r.Item_Attribute__r;
            }
            ASNAddManageExt.ASNLineWrapper asnlWrapper;
            List<SkidService3.SerialWrapper> serialwrapperlist = new List<SkidService3.SerialWrapper>();
           // asnlWrapper.asnl = asnl;
            //asnlWrapper.asnl.Item__r = asnl.Item__r;

            //asnlWrapper.trackedAttributes = SKIDService3.trackedAttributes(null, null, asnl.Item__r);

            if (asnLineToSkidMap.containsKey(asnl.id)){
               //asnlWrapper.skidList = asnLineToSkidMap.get(asnl.id);
                for(SKID__c skid: asnLineToSkidMap.get(asnl.id)){
                	
                	List<Serial__c> seriallist = new List<Serial__c>();
                	if(asnl.Item__r.Item_Attribute__c != null && asnl.Item__r.Item_Attribute__r.Serial_Number__c == true){
                    	Serial__c ser = new Serial__c();
	                    if( serialMap.containsKey(skid.Id) ){
	                    	serialList = serialMap.get(skid.Id);
	                    }
	                    else{
	                    	serialList.add(ser);
	                    }
                    
                	}
                	
            		SKIDService3.SerialWrapper serialwrapper = new SKIDService3.SerialWrapper(skid, serialList);
            		serialwrapperlist.add(serialwrapper);
                	asnlWrapper = new ASNAddManageExt.ASNLineWrapper(asnl,serialwrapperlist);
                	
                	asnlWrapper.asnl.Item__r = asnl.Item__r;
                	//**Need to add LPN TRACKED
                	
                	Item__c containerItem = new Item__c();
		            if(containersByItem.containskey(asnl.item__c))
		            	containerItem = containersByItem.get(asnl.item__c).get(skid.Packaging_UOM__c);
		            
            		asnlWrapper.trackedAttributes = SKIDService3.trackedAttributes(null, null, asnl.Item__r,containerItem);
            		//if(asnlWrapper.serialWrapperList.size() > 0)
                 		//asnlWrapper.serialWrapperList[0].skid.Input_Quantity__c = asnlWrapper.conversionFactor;
            
                }
            }
            else{
                SKID__c skid = new SKID__c();
                skid.ASN_Line__c = asnl.id;
                skid.Type__c = 'In-Transit';
                skid.Item__c = asnl.Item__c;
                skid.Company__c = asnl.Purchase_Order_Line__r.Company__c;
                skid.Packaging_UOM__c = asnl.Purchase_Order_Line__r.Purchase_UOM__c;
                skid.Packaging_UOM__r = asnl.Purchase_Order_Line__r.Purchase_UOM__r;
                //asnlWrapper.skidList = new List<SKID__c>{skid};
                List<Serial__c> seriallist = new List<Serial__c>();
                Serial__c ser = new Serial__c();
                serialList.add(ser);
                SKIDService3.SerialWrapper serialwrapper = new SKIDService3.SerialWrapper(skid, serialList);
                asnlWrapper = new ASNAddManageExt.ASNLineWrapper(asnl,serialwrapperlist);
            }
            asnlineswrapper.add(asnlWrapper);
        }
        
        return ASNlineswrapper;
    }
    
	public static JsonResult CancelCloseASNLines( List<ASNAddManageExt.ASNLineWrapper> asnLines, String status, Boolean shortClose){

        JsonResult result = new JsonResult();
        result.success = true;
        List<ASN_Line__c> asnLinestoUpdate = new List<ASN_Line__c>();
        List<SKID__c> skidstoDelete = new List<SKID__c>();
        List<Serial__c> serialsToUpdate = new list<Serial__c>();
        Map<Id,Inventory_Transaction__c> inTransitITmap = new Map<Id,Inventory_Transaction__c>();
        List<String> attributes = SKIDService3.attributesForPutaway();
        attributes.add('ASN_Line__c');
        set<Id> asnLineIds = new set<Id>();
        List<Purchase_Order_Line__c> polinestoUpdate = new List<Purchase_Order_Line__c>();
        if(asnLines.size() == 0){
            return result;
        }
        
        for (ASNAddManageExt.ASNLineWrapper asnWrapper : asnLines){

        	if ((asnWrapper.asnl.Quantity_Received__c == 0 && status == ASN_LINE_STATUS_CANCELLED)
        	    || (asnWrapper.asnl.Status__c == ASN_LINE_STATUS_OPEN && asnWrapper.asnl.Quantity_Received__c > 0 && status == ASN_LINE_STATUS_CLOSED)){
                
                if(asnWrapper.asnl.Status__c == ASN_LINE_STATUS_OPEN){
                    asnWrapper.asnl.Status__c = status;
                    asnWrapper.asnl.Is_Changed__c = true;
                    asnLinestoUpdate.add(asnWrapper.asnl);
                    asnLineIds.add(asnWrapper.asnl.Id);    
                } else if(asnWrapper.asnl.Status__c == ASN_LINE_STATUS_NEW){
                    asnWrapper.asnl.Status__c = status;
                    asnLinestoUpdate.add(asnWrapper.asnl);
                }
        		
        		if( asnWrapper.asnl.Status__c == ASN_LINE_STATUS_CANCELLED &&  asnWrapper.asnl.Purchase_Order_Line__r.Quantity_Shipped__c != null && asnWrapper.asnl.Quantity_Shipped__c != null ){
        		   	if(asnWrapper.asnl.Quantity_Received__c > 0){
        			        asnWrapper.asnl.Purchase_Order_Line__r.Quantity_Shipped__c = KSE.subtractDecimals(asnWrapper.asnl.Purchase_Order_Line__r.Quantity_Shipped__c , asnWrapper.asnl.Quantity_Shipped__c);
        		    }
        		   	if(asnWrapper.asnl.Purchase_Order_Line__r.Status__c != 'Cancelled' ){  
        				polinestoUpdate.add(asnWrapper.asnl.Purchase_Order_Line__r);
        		   	}
        		}
        	
        		if(asnWrapper.serialWrapperList != null){
        			for (SkidService3.SerialWrapper sw : asnWrapper.serialWrapperList){
	        			if (sw.skid.id != null){
	        				skidstoDelete.add(sw.skid);
	        				
	        				for( Serial__c ser : sw.serialList){
	        				    ser.allow_reentry__c = true;
                                ser.Status__c = SkidService3.SERIAL_STATUS_VOIDED;
	        				    serialsToUpdate.add(ser);
	        				}
	        			}
        			}
        		}
        	}
        	else{
        		if( status == ASN_LINE_STATUS_CANCELLED)
        		    result.addMessage(asnWrapper.asnl.Name+' : '+Label.Only_open_ASN_lines_with_no_receipt_can_be_cancelled, ApexPages.Severity.ERROR);
        		else{
        		    result.addMessage(asnWrapper.asnl.Name+' : '+Label.Only_open_ASN_lines_with_partial_receipt_can_be_closed, ApexPages.Severity.ERROR);
        		}    
        		result.success = false;
        		break;
        	}
        }

        if (result.success == false){
            return result;
        }

        Savepoint sp = Database.setSavepoint();
        
        try{
        	if(asnLineIds.size()>0){
        		inTransitITmap = queryinTransitITs(asnLineIds);
        		if(inTransitITmap.size() >0){
			    	if(status == ASN_LINE_STATUS_CLOSED && shortClose == true)
			        	voidASN(inTransitITmap,attributes,false,true);//passing UndoConfirm false so no Draft In-Transit Skids are created
			        else
			        	voidASN(inTransitITmap,attributes,false,false);
		  	    }
        	}
	        if(poLinesToUpdate.size() >0){
	          DML.updateAsUser(poLinesToUpdate);    
	        } 	
            if (asnLinestoUpdate.size() >0 ) {
                DML.updateAsUser(asnLinestoUpdate);
                DML.updateAsSystem(serialsToUpdate);
                
                result.records = asnLinestoUpdate;
            }
        }
        catch(Exception e){
            Database.rollback( sp );
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result; 
    }

    //Create Lots and map those lots to SKIDs
    public static map< List<String>, Lot__c > createLotstoLinktoSKID (List<ASNAddManageExt.ASNLineWrapper> asnlWrapper, ID supplierID, ID companyID){

        List<Lot__c> lots = new List<Lot__c>();
        Map<List<String>, Lot__c> inputLotMap = new Map<List<String>, Lot__c>();

    	for (ASNAddManageExt.ASNLineWrapper asnw : asnlWrapper){
    		system.debug('asnw--'+asnw);
    		for (SkidService3.serialWrapper sw : asnw.serialWrapperList){
    			Lot__c lot = populateLotNames(sw.skid, supplierId, companyID);
                if( lot != null) 
                    lots.add(lot);
            }

        }
        inputLotMap = SkidService3.createLots(lots);
        
        return inputLotMap; 

    } 

    //Similar function as in SKIDService3. 
    //NOTE: Item__r and Item_Attribute__r related checks are removed as those are handled as part of UI validation, and since the grid is DML grid, all the __r fields are removed during save
    public static Lot__c populateLotNames( SKID__c skid , ID supplierID, ID companyID ){
        
        Lot__c lot = null;
        
        if(skid.Lot_Number__c != null ) {
            skid.Lot_Number__c = (skid.Lot_Number__c).toUpperCase(); 
        	lot = new Lot__c( Name = skid.Lot_Number__c , Item__c = skid.Item__c, Supplier__c =  supplierId, Company__c = companyID, Expiration_Date__c = skid.Expiration_Date__c );
        	lot.Item__r = new Item__c(id = skid.Item__c);
    	}

        return lot;
    }

    public static List<String> lotUniqueKey( SObject lotInfo){
        
        String lotName;
        if( lotInfo.getSObjectType() == Lot__c.sObjectType ) lotName = (String)lotInfo.get('Name');
        else
            lotName = (String)lotInfo.get('Lot_Number__c');

        return new List<String>{lotName+'' , lotInfo.get('Item__c')+'' , lotInfo.get('Company__c')+'' , lotInfo.get('Expiration_Date__c')+''};
    }
	//Called from ASN Line Trigger. Checks if any field other than fields in 'Line_Edit_on_Confirm' fieldset is changed, if so throw an error
	//Also if the line is cancelled or closed and if ASN is confirmed, this function unconfirms the ASN
	public static void checkIfASNConfirmed(){

		if ((Trigger.isUpdate || Trigger.isInsert) && Trigger.isBefore){
			Set<ASN__c> asntoUpdate = new Set<ASN__c>();
			List<ASN__c> asntoUpdateList = new List<ASN__c>();
			List<ASN_Line__c> asnlines = Trigger.New;
			Set<id> asnIDs = new Set<id>();

			for (ASN_Line__c a : asnlines){
				asnIDs.add(a.ASN__c);
			}

			Map<id, ASN__c> asnMap = new Map<id, ASN__c>([select id, Name, Status__c from ASN__c where id in :asnIDs]);

			if (Trigger.isUpdate) {
				//Get all fields from ASN line
				Set<String> allFieldsInASNL = Schemautil.getInstance().getAllCustomFieldsFromObject(null, 'ASN_Line__c');	

				//Get all fields from the field set (has namespace in it)
				List<String> fieldSetStr = Schemautil.getInstance().getFieldsFromFieldSetString(ASN_Line__c.sObjectType , 'Line_Edit_on_Confirm');
				Set<String> allFieldsInConfirmedFieldSet = new Set<String>();

				//remove name namespace and convert to lower case
				for (String str : fieldSetStr){
					String s = str.replace( KSE.namespaceUU, '').toLowerCase();
					allFieldsInConfirmedFieldSet.add(s);
				}

				for (ASN_Line__c asnl : asnlines){
					Boolean showError = false;
					if (asnMap.containsKey(asnl.ASN__c)){
						if (asnMap.get(asnl.ASN__c).Status__c == ASN_STATUS_CONFIRMED) {
							for (String str : allFieldsInASNL){
								if (KSE.isFieldChanging(str, asnl, Trigger.oldMap)){
									system.debug('str--'+str);
									if (!allFieldsInConfirmedFieldSet.contains(str)){
										showError = true;
										break;
									}
								}
							}
							if (showError)
								asnl.addError(Label.Cannot_update_ASN_Line_if_the_ASN_is_confirmed);
						}
					}
				}
			}
			else if (Trigger.isInsert){
				for (ASN_Line__c asnl : asnlines){
					if (asnMap.containsKey(asnl.ASN__c)){
						if (asnMap.get(asnl.ASN__c).Status__c == ASN_STATUS_CONFIRMED && asnl.Status__c == ASN_LINE_STATUS_NEW) {
							asnMap.get(asnl.ASN__c).Status__c = ASN_STATUS_UNCONFIRMED;
							asntoUpdate.add(asnMap.get(asnl.ASN__c));
						}
					}
					asnl.Is_Changed__c = true;
				}
			}

			//Collect the asns to update for both inserts and updates, do an update on ASN
			if (asntoUpdate.size() > 0){
				asntoUpdateList.addAll(asntoUpdate);
				DML.updateAsUser(asntoUpdateList);
			}
		}
	}
	
	public static void undoConfirmASN( set<Id> asnIds ){
	 
        Set<String> addlFields = new Set<String>{'Id','Name','Status__c','Company__c','Facility__c','Supplier__c','FOB__r.FOB_Point__c',
                'Transaction_Currency__c','Packing_Slip_Number__c','Number_of_Boxes__c','Tracking_Number__c','Carrier__c'};

        SOQLUtil asnQuery = new SOQLUtil('ASN__c', TRUE);
        asnQuery.addFields(addlFields);
        asnQuery.setWhereClause(' Id IN:asnIds ');
        

        set<String> asnLineFields = new set<String>{ 'Id','Name','Company__c','Purchase_Order__c','Purchase_Order__r.Type__c','Purchase_Order_Line__c', 'Item__r.Packaging_UOM__c',
	                    'Item__r.Container__c','Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Purchase_UOM__c','Purchase_Order_Line__r.Sales_Order_Line__c', 'Purchase_Order_Line__r.Sales_Order_Line__c','Location__c','Quantity_Shipped__c','Quantity_Received__c','Status__c','Quantity_Shipped__c','Purchase_Order_Line__r.Quantity_Shipped__c',
	                    'Purchase_Order_Line__r.Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Is_Changed__c','Item__c','Unit_Price__c', 'ASN__r.Company__c','ASN__r.Supplier__c','ASN__r.Facility__c', 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c',
            			'Purchase_Order_Line__r.Item__r.Packaging_UOM__c','Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__c','Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c'
            		};

        
        SOQLUtil.ChildRelationship asnLines = new SOQLUtil.ChildRelationship(asnQuery, 'ASN_Lines__r');
	    asnLines.addFields(asnLineFields);
	    asnLines.setWhereClause('Status__c !=:ASN_LINE_STATUS_CANCELLED');
	    asnQuery.addChildRelationship(asnLines);
        
        List<ASN__c> ASNList = database.query(asnQuery.getQuery());                  
	   
	    Map<Id,ASN__c> ASNMap = new Map<Id,ASN__c>();
        Map<Id,ASN_Line__c> ASNLinesMap = new Map<Id,ASN_Line__c>();
        set<Id> asnLineIds = new set<Id>();
        set<Receiving_Document__c> rdsToVoid = new set<Receiving_Document__c>();
        set<Receiving_Document__c> rdsToCancel = new set<Receiving_Document__c>();
	    List<Purchase_Order_Line__c> polinestoUpdate = new List<Purchase_Order_Line__c>();
	    for( ASN__c asn : ASNList ){
	       
            if(asn.Status__c == ASN_STATUS_CONFIRMED) {
    			asn.Status__c = ASN_STATUS_DRAFT;
            } else {
    			throw new ASNServiceException('Only ASN in confirmed status can be unconfirmed');
    		}
    		
    		for (ASN_Line__c asnLine:asn.ASN_Lines__r) {
    		    
    		    if( asnLine.Purchase_Order__r.Type__c == PurchaseOrderService.PO_TYPE_DROP_SHIP && 
    		        asnLine.Purchase_Order_Line__r.Sales_Order_Line__c != null ){
    		        asnLine.Quantity_Received__c = 0;
    		        asnLine.Purchase_Order_Line__r.Quantity_Shipped__c = KSE.subtractDecimals(asnLine.Purchase_Order_Line__r.Quantity_Shipped__c,asnLine.Quantity_Shipped__c);
    		    }
    		    else{
                    if(asnLine.Purchase_Order_Line__r.Quantity_Shipped__c == asnLine.Quantity_Shipped__c){
                       asnLine.Purchase_Order_Line__r.Quantity_Shipped__c = 0; 
                    }else  {
                      asnLine.Purchase_Order_Line__r.Quantity_Shipped__c = asnLine.Purchase_Order_Line__r.Quantity_Shipped__c - asnLine.Quantity_Shipped__c;   
                    }
        		    if( asnLine.Quantity_Received__c > 0 ){
        		        throw new ASNServiceException(asnLine.Name+ ' : '+'Please void/cancel the receipts before unconfirming the ASN');        
        		    }
    		    }
    		    asnLineIds.add(asnLine.Id);
    		    asnLine.status__c = ASN_LINE_STATUS_NEW;
    		    asnLine.is_Changed__c = true;
    		    ASNLinesMap.put(asnLine.Id, asnLine);
                polinestoUpdate.add(asnLine.Purchase_Order_Line__r);
    		}
    		ASNMap.put( asn.id, asn);
        }
        
        
         
        
        //Querying In-Transit ITs and creating Void In-Transit ITs:
        
        //Include ASN Line as an attribute to create unique SKID per ASN Line - to prevent updating of SKIDs when skids come from multiple ASN Lines
    	List<String> attributes = SKIDService3.attributesForPutaway();
        attributes.add('ASN_Line__c');
        Map<List<String>,SkidService3.SerialWrapper> toSkids = new Map<List<String>,SkidService3.SerialWrapper>();
        List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> dataforvoid = new Map<Id,SkidService3.ParameterData>();
        List<Inventory_Transaction__c> itsToUpdate = new List<Inventory_Transaction__c>();
        map<Id, List<Serial__c>> serialsByITransMap = new map<Id, List<Serial__c>>();
        Set<Id> itransIds = new Set<Id>();
        map<String,String> voidconfigMap =  new map<String,String>{'adjustFromSkidQuantity'=>'none','putawayDirection'=>'from','serialTransactionType'=>'Void In-Transit'};
        
        
        Map<Id,Inventory_Transaction__c> inTransitITmap = queryinTransitITs(asnLineIds);
         
	     if(inTransitITmap.size() >0){
	        voidASN(inTransitITmap,attributes,true,false);//undoConfirm is passed true if passed from Undo Confirm Header Action.
  	     }
        
        
        Set<String> addlRlFields = new Set<String>{'Id','Name','Status__c', 'Receiving_Document__c'};
        Set<String> addlAelFields = new Set<String>{'Id','Name'};

        SOQLUtil receiptLineQuery = new SOQLUtil('Receipt_Line__c', TRUE);
        receiptLineQuery.addFields(addlRlFields);
        receiptLineQuery.addAllCustomFields(Receiving_Document__c.sObjectType,'Receiving_Document__r');
        receiptLineQuery.setWhereClause(' ASN_Line__c IN:asnLineIds and Status__c != \'Void\' and Status__c != \'Cancelled\' ');
        
        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(receiptLineQuery,'Inventory_Transactions__r');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(Shipment_Line__c.sObjectType,'Shipment_Line__r');
        itQuery.addAllCustomFields(Shipment__c.sObjectType,'Shipment_Line__r.Shipment__r');
        itQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        itQuery.addAllCustomFields(Item__c.sObjectType,'Shipment_Line__r.Product__r.Item__r');
        itQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Shipment_Line__r.Product__r.Item__r.Item_Attribute__r');
        itQuery.addAllCustomFields(Sales_Order_Line__c.sObjectType,'Shipment_Line__r.Sales_Order_Line__r');
        itQuery.addAllCustomFields(Sales_Order__c.sObjectType,'Shipment_Line__r.Sales_Order__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Location__c.sObjectType,'To_SKID__r.Location__r');
        itQuery.addAllCustomFields(Location__c.sObjectType,'From_Location__r');
        itQuery.addAllCustomFields(Bin__c.sObjectType,'From_Bin__r');
        itQuery.addAllCustomFields(Lot__c.sObjectType,'From_Lot__r');
        itQuery.addFields(new Set<String>{ 'Item__r.Packaging_UOM__c','Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c','Stocking_UOM__c','Quantity_Stocking_UOM__c','Shipment_Line__r.Shipment__r.Company__r.Serial_Control__c', 'Shipment_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c', 'Shipment_Line__r.Location__r.Facility__c', 'Receipt_Line__r.ASN_Line__c', 'Receipt_Line__r.ASN_Line__r.Location__c', 'Lot__r.Name','Receipt_Line__r.ASN_Line__r.Location__r.Facility__c', 'Lot__r.Name','Shipment_Line__r.Item__c','Shipment_Line__r.Item__r.Stocking_UOM__c','Shipment_Line__r.Item__r.Non_Inventory__c','Shipment_Line__r.Item__r.Track_Install_Base__c','Shipment_Line__r.Sales_Order_Line__r.Selling_UOM__c', 'Shipment_Line__r.Item__r.Packaging_UOM__c', 'To_Facility__r.Facility_Identifier__c', 'From_Facility__r.Facility_Identifier__c', 'Shipment_Line__r.Facility__r.Facility_Identifier__c'});
        itQuery.setWhereClause('Type__c = \'Logical Sales Order Shipment\' AND Reversed__c = false');
        receiptLineQuery.addChildRelationship(itQuery);
        
	    map<Id, Inventory_Transaction__c> dropShipShipmentItMap = new map<Id, Inventory_Transaction__c>();
	    set<Id> rds = new set<Id>();
        
        for( Receipt_Line__c rl : (List<Receipt_Line__c>)database.query(receiptLineQuery.getQuery()) ){
            
            rds.add(rl.Receiving_Document__c);
            
            for( Inventory_Transaction__c it : rl.Inventory_Transactions__r ){ 
                //if the rl has inventory transactions then it will be for drop ship rl's only as we have stopped rl's with receipts above
                dropShipShipmentItMap.put(it.Id, it);
            }
        }
        
        Set<String> addlAeFields = new Set<String>{'Id','Name','Status__c'};

        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c', TRUE);
        rdQuery.addAllCustomFields();
        rdQuery.setWhereClause(' Id IN:rds ');
        
        SOQLUtil.ChildRelationship aeQuery = new SOQLUtil.ChildRelationship(rdQuery,'Accounting_Entries__r');
        aeQuery.addFields(addlAeFields);
        aeQuery.setWhereClause(' Status__c = \'Active\' ');
        rdQuery.addChildRelationship(aeQuery);
        
        
        for( Receiving_Document__c rd : (List<Receiving_Document__c>)database.query(rdQuery.getQuery())){
            rdsToVoid.add(rd);
            if( rd.Accounting_Entries__r.size() > 0){
                rdsToVoid.add(rd);
            }
            else{
                rdsToCancel.add(rd);
            }
        }
        
        set<Id> dropShipShipmentItIds = dropShipShipmentItMap.keySet();
        
        SOQLUtil stQuery = new SOQLUtil('Serial_Transaction__c',true);
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.setWhereClause('Inventory_Transaction__c IN :dropShipShipmentItIds');
        
        map<Id, List<Serial__c>> serialsByITMap = new map<Id, List<Serial__c>>();
        map<Id, SkidService3.SerialWrapper> intransitSkidsByITMap = new map<Id, SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> inDraftTransitSkids = new list<SkidService3.SerialWrapper>();
        
        for( Serial_Transaction__c st : (List<Serial_Transaction__c>)database.query(stQuery.getQuery()) ){
            
            if(!serialsByITMap.containsKey(st.Inventory_Transaction__c)){
                serialsByITMap.put(st.Inventory_Transaction__c, new list<Serial__c>());
            }
            serialsByITMap.get(st.Inventory_Transaction__c).add(st.Serial__r);
        }
        
        Map<Id,LineWrapper> shlWrappers = new Map<Id,LineWrapper>();
        for( Inventory_Transaction__c it : dropShipShipmentItMap.values()){
        	List<Serial__c> serialList = new list<Serial__c>();
            if(serialsByITMap.containsKey(it.Id)){
                serialList = serialsByITMap.get(it.Id);
            }

        	if(it.Type__c == 'Logical Sales Order Shipment'){
        		if (!shlWrappers.containsKey(it.Shipment_Line__c)) {
	                shlWrappers.put(it.Shipment_Line__c,new LineWrapper(it.Shipment_Line__r.Shipment__r,it.Shipment_Line__r,new List<SkidService3.SerialWrapper>()));
	                shlWrappers.get(it.Shipment_Line__c).logical = true;
	            }
	            
	            SKID__c skid = new SKID__c(
	                Company__c = it.Shipment_Line__r.Shipment__r.Company__c,
	                Type__c = SkidService3.SKID_TYPE_LOCATION,
	                Quantity__c = it.Quantity__c
	            );
	            SkidService3.copyITAttributesToSkid(skid,it,null);
	            skid.Item__r = it.Shipment_Line__r.Product__r.Item__r;
	            skid.Facility2__c = it.From_Facility__c;
	            skid.Facility2__r = it.From_Facility__r;
	            skid.Location__c = it.From_Location__c;
	            skid.Location__r = it.From_Location__r;
	            skid.Bin__r = it.From_Bin__r;
	            skid.Lot__r = it.From_Lot__r;
	            skid.Shipment_Line__c = it.Shipment_Line__c;
				skid.Shipment_Line__r = it.Shipment_Line__r;
				
	            
	            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid, serialList);
             	sw.temporaryValueHolder = JSON.serialize(new List<Inventory_Transaction__c>{ new Inventory_Transaction__c(Id = it.Id, Transaction_Date__c = it.Transaction_Date__c, Quantity__c = it.Quantity__c, Receipt_Line__c = it.Receipt_Line__c) });
             	shlWrappers.get(it.Shipment_Line__c).serialWrappers.add(sw);
             	
	            SKID__c inTransitSkid = new SKID__c();
	            inTransitSkid.ASN_Line__c = it.Receipt_Line__r.ASN_Line__c;
	            inTransitSkid.Type__c = SkidService3.SKID_TYPE_DRAFTINTRANSIT;
	            inTransitSkid.Item__c = it.Item__c;
	            inTransitSkid.Item__r = it.Item__r;
	            inTransitSkid.Company__c = it.Shipment_Line__r.Shipment__r.Company__c;
	            
	            SkidService3.copyITAttributesToSkid(inTransitSkid, it, null);
	            inTransitSkid.Facility2__c = it.Receipt_Line__r.ASN_Line__r.Location__r.Facility__c;
	            inTransitSkid.Location__c = it.Receipt_Line__r.ASN_Line__r.Location__c;
	            inTransitSkid.Bin__c = it.From_Bin__c;
	            inTransitSkid.Lot_Number__c = it.Lot__r.Name;
	            inTransitSkid.Quantity__c = it.Quantity__c;
	            intransitSkidsByITMap.put( it.Id, new SkidService3.SerialWrapper( inTransitSkid, serialList ));
        	}
        	

        }
        
        if (shlWrappers.size() > 0) {
            ShipmentInventoryService.undoShip(shlWrappers.values());
        }
        //Upgrade scneario for non drop ship ASN with no In-Transit IT.Updating the skid type to Draft In-Transit
        if(skidsForPutaway.size() == 0 && intransitSkidsByITMap.size()==0){
        	Set<String> skidFields = new Set<String>{'Id','Type__c','Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c'};
	        Set<Id> skidIds = new Set<Id> ();
	        List<SKID__c> updateskidlist = new List<SKID__c>();
	        List<Serial__c> updateSRlist = new List<Serial__c>();
	        SOQLUtil skidQuery = new SOQLUtil('SKID__c', TRUE);
	        skidQuery.addFields(skidFields);
	        skidQuery.setWhereClause('ASN_Line__c IN :asnLineIds AND Type__c = \'In-Transit\'');
			
			SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
		    serialQuery.addAllCustomFields();
		    skidQuery.addChildRelationship(serialQuery);
		    
			List<SKID__c> allskidlist = Database.query(skidQuery.getQuery());
			if(allskidlist.size()>0){
				for(SKID__c sk:allskidlist){
					sk.Type__c = SkidService3.SKID_TYPE_DRAFTINTRANSIT;
					updateskidlist.add(sk);
					for(Serial__c sr:sk.Serials__r){
						sr.Status__c = SkidService3.SERIAL_STATUS_DRAFTINTRANSIT;
						updateSRlist.add(sr);
					}
				}
			}
			if(updateskidlist.size()>0){
				DML.updateAsUser(updateskidlist);
			}
			if(updateSRlist.size()>0){
        		DML.updateAsUser(updateSRlist);
			}
        }
        
        //ReceivingDocumentServiceV2 rds = ReceivingDocumentServiceV2.getInstance();
        //rds.voidOrderReceipts( rdsToVoid, ReceivingDocumentServiceV2.RD_STATUS_VOID );
        Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
        if( rdsToVoid.size() > 0 ){
            VoidCancelService voidCancelSvc = new ReceivingDocumentVoidCancelService(new list<Receiving_Document__c>(rdsToVoid), true);
            VoidCancelResponses = voidCancelSvc.voidSourceDocuments(new list<Receiving_Document__c>(rdsToVoid));
        }
        if( rdsToCancel.size() > 0 ){
            VoidCancelService voidCancelSvc1 = new ReceivingDocumentVoidCancelService(new list<Receiving_Document__c>(rdsToCancel), true);
            VoidCancelResponses.putAll(voidCancelSvc1.cancelSourceDocuments(new list<Receiving_Document__c>(rdsToCancel)));
        }
        
        set<Receiving_Document__c> allRds = new set<Receiving_Document__c>();
        allRds.addAll(rdsToVoid);
        allRds.addAll(rdsToCancel);
            
        String message;
    	for(Receiving_Document__c rd : allRds ){
        	if( VoidCancelResponses.containsKey(rd.Id) && VoidCancelResponses.get(rd.Id).Success == false && VoidCancelResponses.get(rd.Id).messages.size() > 0  ){
        		for(String m :  VoidCancelResponses.get(rd.Id).messages) {
        		    if( message == null ) message = '';
        			message += VoidCancelResponses.get(rd.Id).recordName + ': '+m;
        		}
    	    }
    	}
        
    	
    	if( message != null ){
    	    throw new ASNServiceException(message);
    	}
        
        DML.updateAsUser(ASNMap.values());
        DML.updateAsUser(ASNLinesMap.values());
        DML.updateAsUser(poLinesToUpdate);
        map<String,Boolean> configMap = new map<String,Boolean>{'createSerial'=>false, 'updateSkidQuantity'=>true};
        

        if (intransitSkidsByITMap.values().size() > 0)
            SkidService3.putAwayService(intransitSkidsByITMap.values(), attributes, configMap);
        
	}
	
	
	public static void voidASN(Map<Id,Inventory_Transaction__c> inTransitITmap,List<String> attributes,boolean undoConfirm,boolean shortclose){
		 //Creating Void In-Transit ITs:
        
		Map<List<String>,SkidService3.SerialWrapper> toSkids = new Map<List<String>,SkidService3.SerialWrapper>();
        List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> dataforvoid = new Map<Id,SkidService3.ParameterData>();
        List<Inventory_Transaction__c> itsToUpdate = new List<Inventory_Transaction__c>();
        map<Id, List<Serial__c>> serialsByITransMap = new map<Id, List<Serial__c>>();
        Set<Id> itransIds = new Set<Id>();
        map<String,String> voidconfigMap =  new map<String,String>{'adjustFromSkidQuantity'=>'none','putawayDirection'=>'from','serialTransactionType'=>'Void In-Transit'};
        
        itransIds = inTransitITmap.keyset();
        SOQLUtil serialtransQuery = new SOQLUtil('Serial_Transaction__c',true);
        serialtransQuery.addAllCustomFields();
        serialtransQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        serialtransQuery.setWhereClause('Inventory_Transaction__c IN :itransIds');
        
        List<SKID__c> skids = new List<SKID__c>();
        for (Inventory_Transaction__c it:inTransitITmap.values()) {
                SKID__c skid = new SKID__c(Type__c = SkidService3.SKID_TYPE_INTRANSIT);
                SkidService3.copyItAttributesToSkid(skid, it, null);

                skid.ASN_Line__c = it.ASN_Line__c;
               
                skids.add(skid);
        }
        
        Map<List<String>,SKID__c> existingSkids = SkidService3.generateExistingSkidMap(attributes,skids,false,null);
        for( Serial_Transaction__c st : (List<Serial_Transaction__c>)database.query(serialtransQuery.getQuery()) ){
            
            if(!serialsByITransMap.containsKey(st.Inventory_Transaction__c)){
                serialsByITransMap.put(st.Inventory_Transaction__c, new list<Serial__c>());
            }
            serialsByITransMap.get(st.Inventory_Transaction__c).add(st.Serial__r);
        }
        
        for(Inventory_Transaction__c itrans:inTransitITmap.values()){
        	SKID__c transitSkid;
        	List<Serial__c> serialList = new list<Serial__c>();
            if(serialsByITransMap.containsKey(itrans.Id)){
                serialList = serialsByITransMap.get(itrans.Id);
            }
            List<String> key = SkidService3.generateKey(itrans, attributes);
        	
        	SKID__c existingSkid;
        	
        	if (!existingSkids.containsKey(key) && itrans.Non_Inventory__c == false) {
                throw new ASNServiceException('No In-Transit Skid found  for ' + itrans.ASN_Line__r.Name);
            }
        	if (existingSkids.containsKey(key)){
        		existingSkid = existingSkids.get(key).clone(true, true);
        	}
        	if(existingSkid !=null){
        		transitSkid = existingSkid.clone(true, true);
        		
        		if(shortclose){
        			itrans.Quantity__c = transitSkid.Quantity__c;
        		}
        		transitSkid.Quantity__c -= itrans.Quantity__c;
        	}
        	
        	
        	Inventory_Transaction__c voidIT;
            if(itrans.Non_Inventory__c == true){
                Item__c item = itrans.Item__r;
                list<id>lstPkgUom = (List<Id>) JSON.deserialize(item.Packaging_UOM__c, List<Id>.class);
                voidIT = SkidService3.createInventoryTransaction(itrans.ASN_Line__r, 'Void - In-Transit', itrans.Quantity__c, null, null, attributes);
            	voidIT.Non_Inventory__c = itrans.Non_Inventory__c;
            	voidIt.Item__c = itrans.Item__c;
            	voidIt.Item__r = itrans.Item__r;
            	voidIt.Packaging_UOM__c = itrans.Packaging_UOM__c;
            	voidIt.Stocking_UOM__c = itrans.Stocking_UOM__c;
            	if(itrans.Container_Item__r !=null){
            	    voidIt.Container_Item__r = itrans.Container_Item__r;
            	    voidIt.Container_Item__c = itrans.Container_Item__c;
            	}
            	voidIt.Quantity_Stocking_UOM__c = itrans.Quantity__c * KSE.getConversionFactor(itrans.Item__c, iTrans.To_Facility__r.Facility_Identifier__c, voidIt.Packaging_UOM__c, voidIt.Stocking_UOM__c, lstPkgUom);
            	
            }
            else{
            	voidIT = SkidService3.createInventoryTransaction(itrans.ASN_Line__r, 'Void - In-Transit', itrans.Quantity__c, null, transitSkid, attributes);
            }
            	
            voidIT.From_Bin__c = voidIT.Bin__c;
            voidIt.To_SKID__c = null;
            voidIt.To_SKID__r = null;
            
            if(itrans.Non_Inventory__c == false)
            	toSkids.put(SkidService3.generateKey(voidIt,attributes), new SkidService3.SerialWrapper(transitSkid, serialList));
            
            if(undoConfirm){
            	Skid__c inDraftSkid;
            
	            if(itrans.Non_Inventory__c == true){
	            	inDraftSkid = new SKID__c(Facility2__c=itrans.From_Facility__c,Location__c = itrans.From_Location__c);
	            	
	            	inDraftSkid.ASN_Line__c = itrans.ASN_Line__c;
		            inDraftSkid.Item__c = itrans.Item__c;
		            inDraftSkid.Item__r = itrans.Item__r;
		            
		            if(itrans.Item__r.Item_Attribute__c !=null){
		            	inDraftSkid.Item__r.Item_Attribute__c = itrans.Item__r.Item_Attribute__c;
		            	inDraftSkid.Item__r.Item_Attribute__r = itrans.Item__r.Item_Attribute__r;
		            }
		            	
					inDraftSkid.Company__c = itrans.ASN_Line__r.Company__c;
					inDraftSkid.Packaging_UOM__c = itrans.Packaging_UOM__c;
					inDraftSkid.Stocking_UOM__c = itrans.Stocking_UOM__c;
					if(itrans.Container_Item__r !=null){
                	    inDraftSkid.Container_Item__r = itrans.Container_Item__r;
                	    inDraftSkid.Container_Item__c = itrans.Container_Item__c;
                	}
	            }
	            else
	            	inDraftSkid = transitSkid.clone(false, true);
	            
	            inDraftSkid.Type__c = SkidService3.SKID_TYPE_DRAFTINTRANSIT;
	            inDraftSkid.Quantity__c = itrans.Quantity__c;
	            skidsForPutaway.add(new SkidService3.SerialWrapper(inDraftSkid,serialList));
            
            }
            
            
            Id companyId = itrans.ASN_Line__r.Company__c;
            Id sourceDocId = itrans.ASN_Line__c;
            Id currencyId = itrans.ASN_Line__r.ASN__r.Currency__c;
            
            SkidService3.ParameterData d = dataforvoid.get(sourceDocId);
            if (d == null) {
                d = new SkidService3.ParameterData();
                d.sourceDoc = new Receiving_Document__c(Company__c = companyId);
               
                d.sourceDoc.put('Currency__c', currencyId);
                
                dataforvoid.put(sourceDocId,d);
            }
            d.itList.add(voidIt);
            itsToUpdate.add( new Inventory_Transaction__c(Id = itrans.id, Reversed__c = true));
        }
        
       if(skidsForPutaway.size()>0){
    		SkidService3.putAwayService( skidsForPutaway, attributes , new Map<String,Boolean>{ SkidService3.MIXED_SERIAL => true });
    	}
    	SkidService3.inventoryTransactionsForPutAway( dataforvoid, attributes, toSkids, voidconfigMap);
    	DML.updateAsUser(itsToUpdate);
	}

	//called from UI during confirm of ASN 
	public static JsonResult confirmASN(ASN__c asn) {
        JsonResult result = new JsonResult();
        
        if (asn.Status__c != ASN_STATUS_CONFIRMED) {
			asn.Status__c = ASN_STATUS_CONFIRMED;
		} else {
			result.success = false;
			result.addMessage(Label.Only_Unconfirmed_ASNs_can_be_confirmed,ApexPages.Severity.ERROR);
			result.records = new List<ASN__c>{asn}; 
			return result;
		}


		Id asnId = asn.Id;
        Set<String> addlFields = new Set<String>{'Id','Name','Transaction_Date__c','Date_Shipped__c','Status__c','Company__r.Comp_Currency__c','Currency__c','Company__c','Facility__c','Supplier__c','FOB__r.FOB_Point__c',
                'Transaction_Currency__c','Packing_Slip_Number__c','Number_of_Boxes__c','Tracking_Number__c','Carrier__c'};

        SOQLUtil asnQuery = new SOQLUtil('ASN__c', TRUE);
        asnQuery.addFields(addlFields);
        asnQuery.setWhereClause(' Id = :asnId ');
        
        set<String> asnLineFields = new set<String>{ 'Id','Facility__c','supplier__c','company__c','Name','Purchase_Order__c','Purchase_Order__r.Type__c','Purchase_Order_Line__c', 'Purchase_Order_Line__r.Quantity_Shipped__c',
		                    'Purchase_Order_Line__r.Sales_Order_Line__c', 'Location__c','Quantity_Shipped__c','Quantity_Received__c','Status__c','Is_Changed__c','Item__c','Unit_Price__c',
		                    'Purchase_Order_Line__r.Item__r.Packaging_UOM__c', 'ASN__r.Company__c','ASN__r.Supplier__c','ASN__r.Facility__c', 'ASN__r.Currency__c', 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c'};

        
        SOQLUtil.ChildRelationship asnLines = new SOQLUtil.ChildRelationship(asnQuery, 'ASN_Lines__r');
	    asnLines.addFields(asnLineFields);
	    asnLines.setWhereClause('Status__c !=:ASN_LINE_STATUS_CANCELLED and Status__c !=: ASN_LINE_STATUS_CLOSED');
	    asnQuery.addChildRelationship(asnLines);
        ASN__c asnTemp = database.query(asnQuery.getQuery());  

        
        Set<Id>asnLineIds = new Set<Id>();
        List<ASN_Line__c> changedASNLines = new List<ASN_Line__c>();
        List<ASN_Line__c> asnLinesToUpdate = new List<ASN_Line__c>();
                
        List<Purchase_Order_Line__c> polinestoUpdate = new List<Purchase_Order_Line__c>();
                
        Set<Id> dropShipLineIds = new Set<Id>();
        Map<Id,Receiving_Document__c> rdMap = new Map<Id,Receiving_Document__c>();
        if (asnTemp.ASN_Lines__r.size() > 0) {
            for (ASN_Line__c asnLine:asnTemp.ASN_Lines__r) {
                if (asnLine.Is_Changed__c) {
                    asnLine.Status__c = asnLine.Status__c == ASN_LINE_STATUS_NEW ? ASN_LINE_STATUS_OPEN : asnLine.Status__c;
                    asnLine.Is_Changed__c = false;
                    asnLine.Purchase_Order_Line__r.Quantity_Shipped__c = KSE.addQuantityToField(asnLine.Purchase_Order_Line__r.Quantity_Shipped__c,asnLine.Quantity_Shipped__c);
                    polinestoUpdate.add(asnLine.Purchase_Order_Line__r);
                                        
                    asnLinesToUpdate.add(asnLine);
                    if (asnLine.Purchase_Order__r.Type__c != 'Drop Ship' || ( asnLine.Purchase_Order__r.Type__c == 'Drop Ship' && 
                            asnLine.Purchase_Order_Line__r.Sales_Order_Line__c == null ))
                        changedASNLines.add(asnLine);
                    asnLineIds.add(asnLine.Id);
                }
                if (asnLine.Purchase_Order__r.Type__c == 'Drop Ship' && asnLine.Purchase_Order_Line__r.Sales_Order_Line__c != null ) {
                    dropShipLineIds.add(asnLine.Id);

                    if (asnTemp.Transaction_Date__c == null && asnTemp.Date_Shipped__c == null) {
                        asn.Transaction_Date__c = System.now();
                        asn.Date_Shipped__c = System.now();
                    } else if (asnTemp.Transaction_Date__c != null && asnTemp.Date_Shipped__c == null) {
                        asn.Transaction_Date__c = asnTemp.Transaction_Date__c;
                        asn.Date_Shipped__c = asnTemp.Transaction_Date__c;
                    } else {
                        asn.Transaction_Date__c = asnTemp.Date_Shipped__c;
                        asn.Date_Shipped__c = asnTemp.Date_Shipped__c;
                    }
                    
                    if (!rdMap.containsKey(asnLine.Purchase_Order__c))
                        rdMap.put(asnLine.Purchase_Order__c,new Receiving_Document__c(
                            Company__c = asnTemp.Company__c,
                            Supplier__c = asnTemp.Supplier__c,
                            Date_Created__c = System.today(),
                            Date_Received__c = asn.Date_Shipped__c,
                            Transaction_Date__c = asn.Date_Shipped__c,
                            Type__c = 'Purchase Order Receipt',
                            Transaction_Type__c = ReceivingDocumentService.RD_TRANSACTION_TYPE_LOGICAL,
                            Currency__c = asnTemp.Currency__c,
                            Finalized__c = false,
                            Status__c = 'Closed',
                            Packing_Slip_Number__c = asnTemp.Packing_Slip_Number__c,
                            Number_of_Boxes__c = asnTemp.Number_of_Boxes__c,
                            Tracking_Number__c = asnTemp.Tracking_Number__c,
                            Carrier__c = asnTemp.Carrier__c
                        ));
                }
            }
        }
        else{
            result.success = false;
            result.addMessage(Label.No_lines_available_to_confirm,ApexPages.Severity.ERROR);
            return result;
        }
        
        
        Savepoint sp = Database.setSavepoint();
        try {
        	DML.updateAsUser(asn);
        	DML.updateAsUser(asnLinesToUpdate);
        	        	
        	DML.updateAsUser(poLinesToUpdate);
        	
        	createICandITsforASN(changedASNLines,asnLineIds,asnTemp);
        	if (dropShipLineIds.size() > 0) {
        		List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,dropShipLineIds,new Set<String>{'asn_line__c'});
                rWrappers = ReceivingDocumentServiceV2.checkUserErrors(rWrappers);
                //Inserting RDs before calling receive
                if(rdMap.values().size() > 0){
                   DML.insertAsUser(rdMap.values());
                }
                ReceivingDocumentServiceV2.receive(rWrappers,rdMap);
            }
            
            result.success = true;
            result.records = new List<ASN__c>{asn};
            result.addMessage(Label.ASN_is_confirmed,ApexPages.Severity.CONFIRM);
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured: ' + e.getMessage() + 'Stack Trace: ' + e.getStackTraceString(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    public static void createICandITsforASN(List<ASN_Line__c>changedASNLines,Set<Id>asnLineIds,ASN__c asnTemp){
            //Query the skids
            set<String> skidFields = new set<String>{'Location__r.Facility__c','Item__r.Non_Inventory__c','Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__c','Container_Item__r.Name','Container_Item__c', 'Facility2__r.Facility_Identifier__c','Sales_Order_Line__c'};
            List<SKID__c> allskidlist = new List<SKID__c>();
            Set<Id> skidIds = new Set<Id> ();
            Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
            
            skidFields.addAll(util.getAllCustomFieldsFromObject('', 'SKID__c'));
            skidFields.addAll( util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );
    		SOQLUtil skidQuery = new SOQLUtil('SKID__c', TRUE);
            skidQuery.addFields(skidFields);
            skidQuery.setWhereClause('ASN_Line__c IN :asnLineIds AND Type__c = \'Draft In-Transit\'');
    		
    		SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
    	    serialQuery.addAllCustomFields();
    	    skidQuery.addChildRelationship(serialQuery);
    	    
    		allskidlist = Database.query(skidQuery.getQuery());
            Map<Id,List<SKID__c>> skidmap = new Map<Id,List<SKID__c>>();
            for(SKID__c sk:allskidlist){
            	if (!skidmap.containsKey(sk.ASN_Line__c)) {
            		skidmap.put(sk.ASN_Line__c,new List<SKID__c>());
            	}
            	skidmap.get(sk.ASN_Line__c).add(sk);
            }
            
            //IT creation
        	List<String> attributes = SkidService3.attributesForPutaway();
        	attributes.add('ASN_Line__c');
        	list<String> attributesForService = SkidService3.attributesForPutaway(new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c')));
        	Map<Id,SkidService3.ParameterData> itData = new Map<Id,SkidService3.ParameterData>();
        	List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        	map<String,String> configMap =  new map<String,String>{'putawayDirection'=>'to'};
        	Map<List<String>,SkidService3.SerialWrapper> toSkids = new Map<List<String>,SkidService3.SerialWrapper>();
        	
        	if(changedASNLines.size()>0){
        		
	        		for(ASN_Line__c asnline:changedASNLines){
		        		//Creating IC
		        		SkidService3.ParameterData itInfo = itData.get(asnline.ASN__c);
			            if (itInfo == null) {
			                itInfo = new SkidService3.ParameterData();
			                itInfo.sourceDoc = new ASN__c(Company__c = asnline.Company__c);
			                itInfo.icType = SkidService3.SKID_TYPE_INTRANSIT;
			            }
			            if(skidmap.containsKey(asnline.Id)){
			            	
			            	for(SKID__c skid:skidmap.get(asnline.Id)){
		        			
			        			SKID__c fromSkid;
				        		String type;
				        		
				                Skid__c transitSkid = skid.clone(false, true);
				                transitSkid.Type__c = SkidService3.SKID_TYPE_INTRANSIT;
				    			type = 'In-Transit';
				    			if(skid.Item__r.Non_Inventory__c == false)
				    				skidsForPutaway.add(new SkidService3.SerialWrapper(transitSkid,transitSkid.Serials__r));
				    			fromSkid = skid;//Draft In-Transit
				    			//Creating ITs
				    			Inventory_Transaction__c it;
				    			if(skid.Item__r.Non_Inventory__c == true){
				    				it = SkidService3.createInventoryTransaction(asnline, type, skid.Quantity__c, fromSkid, null, attributes);
				    				it.Non_Inventory__c = skid.Item__r.Non_Inventory__c;
				    				it.Item__c = skid.Item__c;
				    				it.Item__r = skid.Item__r;
				    				if(skid.Container_Item__r !=null){
				    				    it.Container_Item__c = skid.Container_Item__c;
				    				    it.Container_Item__r =skid.Container_Item__r;
				    				}
				    				
				    			}
				                else
				                	it = SkidService3.createInventoryTransaction(asnline, type, transitSkid.Quantity__c, fromSkid, transitSkid, attributes);
				                
				                it.ASN_Line__r = asnline; 
				                it.ASN_Line__c = asnline.Id;
				            	
				                it.Transaction_Date__c =  System.now();
				                itInfo.itList.add(it);
			        		}
			        		if (itInfo.itList.size() > 0) {
				                itData.put(asnTemp.Id,itInfo);
				        	}
			            }
	        		
	        		   
	        	}
	        	if (skidsForPutaway.size() > 0) {
	        		toSkids = SkidService3.putAwayService(skidsForPutaway,attributes,new Map<String,Boolean>{ SkidService3.MIXED_SERIAL => true });
	        	}
	        	SkidService3.inventoryTransactionsForPutaway(itData,attributes,toSkids,configmap);
        	}
    	
    }
    
    public static Map<Id,Inventory_Transaction__c> queryinTransitITs(Set<Id> asnLineIds){
    	
	        SOQLUtil invQuery = new SOQLUtil('Inventory_Transaction__c',TRUE);
	        invQuery.addAllCustomFields();
	        invQuery.addAllCustomFields(ASN_Line__c.sObjectType,'ASN_Line__r');
	        invQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
	        invQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
	        invQuery.addAllCustomFields(Location__c.sObjectType,'To_SKID__r.Location__r');
	        invQuery.addAllCustomFields(Location__c.sObjectType,'From_Location__r');
	        invQuery.addAllCustomFields(Bin__c.sObjectType,'From_Bin__r');
	        invQuery.addAllCustomFields(Lot__c.sObjectType,'From_Lot__r');
	        invQuery.addFields(new Set<String>{ 'Id','ASN_Line__r.ASN__r.Currency__c','ASN_Line__r.ASN__r.Company__r.Serial_Control__c','ASN_Line__r.Location__r.Facility__c', 'ASN_Line__c', 'ASN_Line__r.Location__c', 'Lot__r.Name','Item__r.Packaging_UOM__c', 'To_Facility__r.Facility_Identifier__c','From_Facility__r.Facility_Identifier__c','Shipment_Line__r.Facility__r.Facility_Identifier__c'});
	        invQuery.setWhereClause('Type__c = \'In-Transit\' and Reversed__c = false and ASN_Line__c = :asnLineIds  ');
	        
	        Map<Id,Inventory_Transaction__c> inTransitITmap = new Map<Id,Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query(invQuery.getQuery()));
	        return inTransitITmap;
    }
     

   //Check the ASN Lines if the qty is fully received and close the line. 
    public static void checkASNLinesReceivedQty(){
       	List<ASNAddManageExt.ASNLineWrapper> asnlinewrapperlist = new List<ASNAddManageExt.ASNLineWrapper>();
       	List<ASN_Line__c> asnlines = Trigger.New;
		for(ASN_Line__c asnline: asnlines){
			if(KSE.isFieldChanging('Quantity_Received__c', asnline, trigger.oldMap)) {
    			if(asnline.Quantity_Received__c == asnline.Quantity_Shipped__c){
    				
    				ASNAddManageExt.ASNLineWrapper asnlinewrapper = new ASNAddManageExt.ASNLineWrapper();
    				asnlinewrapper.asnl = asnline;
    				asnlinewrapperlist.add(asnlinewrapper);
    				
    			}
    		}
		}
		if(asnlinewrapperlist.size() >0)
			CancelCloseASNLines(asnlinewrapperlist, ASN_LINE_STATUS_CLOSED, false);		
	
    }

}