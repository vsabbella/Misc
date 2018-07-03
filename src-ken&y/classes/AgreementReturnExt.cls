global with sharing class AgreementReturnExt extends BaseController {
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string NamespaceUU { get { return KSE.NamespaceUU; } }
    public GridRelatedListController.GridRelatedListConfig FulfillmentConfig {get; set;}
    public String fulfillmentLinesFieldList = null;
    public Apexpages.Standardcontroller con {get;set;}
    public id agreementId {get;set;}
    
    public String getfulfillmentLinesConfigJson() {
        String configStr = JSON.serialize(this.FulfillmentConfig);
        
        return configStr;
    }
    public string getfulfillmentLinesFieldList() {
        if (fulfillmentLinesFieldList == null && FulfillmentConfig != null) {
            
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(FulfillmentConfig.objectName, FulfillmentConfig.fieldset);
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = 'flmt.'+fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                
                //Rename the start and end date on fulfillments
                if (fieldName == 'flmt.end_date__c'){
                    fieldInfoList[i].title = 'Fulfillment End Date';
                    fieldInfoList[i].editable = true;
                }else if (fieldName == 'flmt.start_date__c'){
                    fieldInfoList[i].title = 'Fulfillment Start Date';
                    fieldInfoList[i].editable = false;
                }else{
                    fieldInfoList[i].editable = false;
                }
            }
            
            FieldInfo fieldInfoItem = new FieldInfo('returnQty', 'Return Quantity', 'double', false);
            FieldInfo fieldInfoItem_Serial = new FieldInfo('serial', 'Serial', 'string', false);
            fieldInfoItem.editable = true;
            fieldInfoList.add(fieldInfoItem_Serial);
            fieldInfoList.add(fieldInfoItem);
            fulfillmentLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return fulfillmentLinesFieldList;
    }
    
    public AgreementReturnExt(ApexPages.StandardController controller) {
        
        this.con = controller;
        
        if(this.con == null){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
        }else{
            if(!test.isRunningTest()){
                this.con.addFields(new list<String>{'Customer__c', 'Customer__r.RecordType.DeveloperName', 'Status__c', 'Currency__c',//Ship To
                        'Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Name', //Sold To
                        'Customer__r.Parent_Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Parent_Customer__r.Name', //Bill To
                        'Payment_Terms__c', 'Bill_To__c', 'Sold_To__c', 'Ship_To__c',
                        'Company__c', 'Company__r.Serial_Control__c', //company's serial attribute
                        'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Name'});
            }
            Agreement__c a  = (Agreement__c) con.getRecord();
            
            agreementId = a.id;
        
        }
        
        //Fulfillment Grid config
        FulfillmentConfig = new GridRelatedListController.GridRelatedListConfig();
        FulfillmentConfig.uniqueId = 'FulfillmentGrid';
        FulfillmentConfig.title = 'Fulfillments';
        FulfillmentConfig.objectName = 'Fulfillment__c';
        FulfillmentConfig.fieldset = 'Return';
        FulfillmentConfig.buttons = 'columnmenu, search';
        FulfillmentConfig.alwaysUseFullDateTimeFormat = false;
    
    }
    
    
    
    @RemoteAction
    global static JsonResult getFulfillments(String id) {
        
        JsonResult result = new JsonResult();
        
        List<Fulfillment__c> Fulfillments = new List<Fulfillment__c>();
        
        List<String> filterCriteria = new List<String>();
        filterCriteria.add('End_Date__c = null');
        filterCriteria.add('Sales_Order_Line__r.Agreement__c = :id');
        filterCriteria.add('Type__c = \'Rental\'');
        //filterCriteria.add('Type__c = \'Sales Order Shipment\'');
        filterCriteria.add('Price_Type__c = \'Recurring\'');
        filterCriteria.add('Invoice_Ready__c = true'); //KNDY-12781 Based on changes made in KNDY-11724
        
        String whereClause = '';
        
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }
        
        List<String> fieldstoQuery = util.getFieldsFromFieldSetString('Fulfillment__c', 'Return');
        Set<String> fieldSettouseinQuery = new Set<String>(fieldstoQuery);
        datetime oDate = system.now();
        SOQLUtil soql = new SOQLUtil('Fulfillment__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'Name', 'Company__c', 'SKID__c', 'Product__r.Item__c',
                'Product__r.Item__r.Item_Attribute__c',
                'Product__r.Item__r.Item_Attribute__r.Serial_Number__c', 'Rate_Basis__c',
				'Pricing_UOM__r.Recurrence__c', 'Pricing_UOM__r.Every__c'
		});
        soql.addFields(util.getAllCustomFieldsFromObject('', 'Fulfillment__c'));
        soql.addFields(fieldSettouseinQuery);
        soql.addFields(util.getAllCustomFieldsFromObject('Sales_Order_Line__r.','Sales_Order_Line__c'));
        soql.addFields(util.getAllCustomFieldsFromObject('Agreement_Line__r.','Agreement_Line__c'));
        soql.setWhereClause(whereClause);
        soql.setOrderByClause('LastModifiedDate');
        
        Fulfillments = database.query(soql.getQuery());
        If (Fulfillments.size() == 0){ //KNDY-12781
            result.success = false;
            result.total = 0;
        }else{
            //get the serials for each line
            //1. get the sales order line ids
            Set<id> solIDS = new Set<id>();
            Map<id, string> solIDtoSerial = new Map<id, string>();
            for (Fulfillment__c f : Fulfillments){
                solIDS.add(f.Sales_Order_Line__c);
            }
            /*
            //2. From the sales order line ids, get all the Inventory Transactions of type 'Sales Order Shipment'
            soql = new SOQLUtil('Inventory_Transaction__c', TRUE);
            soql.addFields(new Set<String>{'Id', 'Name', 'Sales_Order_Line__c'});
            soql.setWhereClause('Type__c = \'Sales Order Shipment\' AND Sales_Order_Line__c in :solIDS');
            soql.setOrderByClause('LastModifiedDate');
            
            List<Inventory_Transaction__c> invtranList = database.query(soql.getQuery());
            
            //3. From the ITs get the serial Transactions which will have the serial reference
            Set<id> invtranIDs = new Set<id>();
            Map<id, id> invTrantoSOL = new Map<id, id>();
            
            for (Inventory_Transaction__c t : invtranList){
                invtranIDs.add(t.id);
                invTrantoSOL.put(t.id, t.Sales_Order_Line__c);
            }
            
            soql = new SOQLUtil('Serial_Transaction__c', TRUE);
            soql.addFields(new Set<String>{'Id', 'Name', 'Inventory_Transaction__c', 'Serial__c', 'Serial__r.Name'});
            soql.setWhereClause('Inventory_Transaction__c in :invtranIDs');
            
            List<Serial_Transaction__c> sltranList = database.query(soql.getQuery());
            Map<id,Serial_Transaction__c> itTOst = new Map<id,Serial_Transaction__c>();
            
            for (Serial_Transaction__c st : sltranList){
                itTOst.put(st.Inventory_Transaction__c, st);
            }
            
            for (id itid : invTrantoSOL.keySet()){
                if (itTOst.containsKey(itid)){
                    solIDtoSerial.put(invTrantoSOL.get(itid), itTOst.get(itid).Serial__r.Name);
                }
            }
            */
            //2. Get all serials and its corresponding SKID from the sales order line IDs
            soql = new SOQLUtil('Serial__c', TRUE);
            soql.addFields(new Set<String>{'Id', 'Name'});
            soql.addFields(util.getAllCustomFieldsFromObject('', 'Serial__c'));
            soql.addFields(util.getAllCustomFieldsFromObject('SKID__r.','SKID__c'));
            soql.setWhereClause('SKID__r.Sales_Order_Line__c in : solIDS');
            
            List<Serial__c> serialListSOL = database.query(soql.getQuery());

            Map<id, Serial__c> soltoSerial = new Map<id, Serial__c>();
            for (Serial__c serial : serialListSOL){
                soltoSerial.put(serial.SKID__r.Sales_Order_Line__c, serial);
            }

            List<fulfillmentWrapper> flmtWrapper = new List<fulfillmentWrapper>();
            for (Fulfillment__c f : Fulfillments){
                fulfillmentWrapper fw = new fulfillmentWrapper();
                fw.sol = f.Sales_Order_Line__r;
				fw.agl = f.Agreement_Line__r;
                fw.flmt = f;
                fw.itemID = f.Product__r.Item__c;
				fw.pricingUom = f.Pricing_UOM__r;
                if (f.Product__r.Item__r.Item_Attribute__c != null && f.Product__r.Item__r.Item_Attribute__r.Serial_Number__c == true){
                    fw.isSerialLine = true;
                    fw.returnQty = 1;
                }
                
                if (soltoSerial.containsKey(f.Sales_Order_Line__c))
                    fw.serial = soltoSerial.get(f.Sales_Order_Line__c).Name;
                
                flmtWrapper.add(fw);
            }
            
            result.records = flmtWrapper;
            result.total = flmtWrapper.size();
        }
        return result;
    }
    
    @RemoteAction
    global static JsonResult createReceiptandUpdateFulfillments(List<fulfillmentWrapper> flmtwrappers) {

        JsonResult result = new JsonResult();

		// use List to support SOL to Many fulfillment (in case of returns on partial shipment)
        Map<id, List<fulfillmentWrapper>> solsToCreateRLs = new Map<id, List<fulfillmentWrapper>>();
        Map<id, id> soltoItemID = new Map<id, id>();
        
        for (fulfillmentWrapper fwrp : flmtwrappers){

			if (!solsToCreateRLs.containsKey(fwrp.sol.id)){
				solsToCreateRLs.put(fwrp.sol.id, new List<fulfillmentWrapper>());
			}
			solsToCreateRLs.get(fwrp.sol.id).add(fwrp);

            soltoItemID.put(fwrp.sol.id, fwrp.itemID);

			fwrp.flmt.Sales_Order_Line__r = fwrp.sol;
			fwrp.flmt.Agreement_Line__r = fwrp.agl;
			fwrp.flmt.Pricing_UOM__r = fwrp.pricingUom;

            if ((fwrp.returnQty > fwrp.flmt.Quantity__c) || (fwrp.returnQty == 0) || (fwrp.returnQty == null)){
                result.success = false;
                result.addMessage('Return quantity should be non-zero and cannot be more than the fulfillment quantity ' , ApexPages.Severity.ERROR);
            }
        }
        
        if (!result.success){
            return result;
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try{
            set<id> rdIDs = new set<id>();
            Receiving_Document__c rd = new Receiving_Document__c();
			rd.Company__c = solsToCreateRLs.get(flmtwrappers[0].sol.id)[0].sol.Company__c;
            rd.Type__c = 'Return Receipt';
            rd.Transaction_Date__c = System.now();
            rd.Currency__c = flmtwrappers[0].flmt.Currency__c;
            DML.insertAsUser(rd);
            rdIDs.add(rd.id);
            
            Location__c l = new Location__c();
            
            List<Receipt_Line__c> rlsToCreate = new List<Receipt_Line__c>();
            List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
			Map<Id,Decimal> returnQtyMap = new Map<Id,Decimal>();
            for(id solID : solsToCreateRLs.keySet()) {

				for (fulfillmentWrapper fwrap : solsToCreateRLs.get(solid)) {
					Receipt_Line__c rl = new Receipt_Line__c();
					Sales_Order_Line__c sol = fwrap.sol;

					rl.Sales_Order__c = sol.Sales_Order__c;
					rl.Sales_Order_Line__c = sol.id;
					rl.Quantity_Declared__c = fwrap.returnQty;
					rl.Item__c = soltoItemID.get( solID );
					rl.Receiving_Document__c = rd.id;
					rl.Location__c = sol.Ship_From_Location__c;
					rl.Company__c = sol.Company__c;

					if ( l.Facility__c == null ) {
						id locid = sol.Ship_From_Location__c;
						SOQLUtil soql = new SOQLUtil( 'Location__c', true ); //enforceFLS=true, running in user mode
						soql.addFields( new set<string>{ 'Id', 'name', 'Facility__c' } );
						soql.setWhereClause( 'Id = :locid' );
						List<Location__c> locList = Database.query( soql.getQuery() );
						l = locList[ 0 ];
						rl.Facility__c = l.Facility__c;
					}
					else {
						rl.Facility__c = l.Facility__c;
					}

					rlsToCreate.add( rl );

					Fulfillment__c fulfillment = fwrap.flmt;
					fulfillments.add( fulfillment );
					returnQtyMap.put(fulfillment.id, fwrap.returnQty);
				}
            }
            DML.insertAsUser(rlsToCreate);

			System.debug( '~*~ fulfillments.size() :' + fulfillments.size() );

			Map<SObject, List<Pricebook_Line__c>> mFulfillments = PricingService.getPriceBookLines(fulfillments, PricingService.PriceType.RECURRING);
            Map<SObject, List<PricingService.PricingResult>> mBestPrices = PricingService.calculateBestPrice(mFulfillments);

			System.debug( '~*~ Final mBestPrice (Agreement):' + PricingService.debugBestPricesString(mBestPrices) );

            List<Fulfillment__c> updatedFulfillments = new List<Fulfillment__c>();

            for(Fulfillment__c f : fulfillments) {
                List<PricingService.PricingResult> mPriceResultList = new List<PricingService.PricingResult>();

				Sales_Order_Line__c iSOL = solsToCreateRLs.get(f.Sales_Order_Line__c)[0].sol;
                PricingService.RateBasis rb = PricingService.getRateBasis(f.Rate_Basis__c);
                decimal qtyMult = rb == PricingService.RateBasis.FLAT ? 1 : f.Quantity__c;
                
                if(mBestPrices.containsKey(f)) {
					mPriceResultList = mBestPrices.get(f);
                }
                
                double returnQty = returnQtyMap.get(f.id);

				// split fulfillments will be created by cloning the returnFulfillment
				Fulfillment__c returnFulfillment;

                if (returnQty != f.Quantity__c) {
					/* First we split the original fulfillment in twain. One is the return fulfillment that gets the best price calc.
                     The other is the remaining fulfillment that will continue to be rented. */

					returnFulfillment = f.clone( false, true );
					returnFulfillment.Quantity__c = returnQty;
					returnFulfillment.Parent_Fulfillment__c = f.Id;

					Fulfillment__c remainingFulfillment;
					remainingFulfillment = f.clone( false, true );
					remainingFulfillment.Quantity__c = f.Quantity__c == null ? 0 : f.Quantity__c - returnQty;
					remainingFulfillment.Parent_Fulfillment__c = f.Id;
					remainingFulfillment.End_Date__c = null;

					updatedFulfillments.add(remainingFulfillment);
				} else {
					returnFulfillment = f;
				}

				Fulfillment__c mutatableFulfillment = f;


				if(!mPriceResultList.isEmpty()) {
					for(PricingService.PricingResult mResult : mPriceResultList) {

						Uom__c uom = mResult.pricingUOM;

						Date startDate = mResult.startDate;
						Date endDate = mResult.endDate;

						PricingService.Occurrence occurrence = PricingService.getOccurrence(uom.Recurrence__c);
						decimal multiplier = PricingService.getMultiplier(occurrence); // used
						Integer every = PricingService.getEvery(uom.Every__c); // used

						Boolean useNonFixedMonthlyIntervals = uom.Recurrence__c == 'Month(s)';

						Datetime cursorDate = DateTime.newInstance(mResult.startDate, Time.newInstance(0,0,0,0));
						Datetime intervalEndDate = DateTime.newInstance(mResult.endDate, Time.newInstance(0,0,0,0));

						System.debug( '~*~'
								+ '\ncursorDate :' + cursorDate
								+ '\nintervalEndDate :' + intervalEndDate
								+ '\nstartDate :' + startDate
								+ '\nendDate :' + endDate
								+ '\noccurrence :' + occurrence
								+ '\nmultiplier :' + multiplier
								+ '\nevery :' + every
								+ '\nuseNonFixedMonthlyIntervals' + useNonFixedMonthlyIntervals
								+ '\nuom.Recurrence__c' + uom.Recurrence__c
						);

						for(Integer i = 0; i < mResult.intervals; i++) {

							System.debug( '~*~ cursorDate (' + i + '): ' + cursorDate);

							Fulfillment__c fulfillment = returnFulfillment.clone(false, true);

							// use billing UOM so lower uom fulfillment date ranges don't get split apart in Invoicing.
							// ie: 8/17 to 9/1 with a rec of 8/1.
							// 		fulfillment Dates: 8/17 to 8/24 (week), 8/24 to 8/31 (week), 8/31 to 9/1 (day)
							// 		During invoicing those dates will be broken up.
							// 		Invoicing dates: 8/17 to 8/22 (5 days), 8/22 to 8/24 (2 days), 8/24 to 8/29 (5 days), 8/29 to 8/31 (2 days) 8/31 to 9/1 (day).
							//		This is because invoicing splits up the CIL by pricing UOM and recurrence date. So those 8/22, 8/29 are weekly recurrences
							fulfillment.Pricing_UOM__c = f.Billing_UOM__c; // uom.Id;
							fulfillment.Unit_Price__c = mResult.unitPrice;
							fulfillment.Extended_Price__c = PricingService.returnPrice(qtyMult, fulfillment.Unit_Price__c, iSOL.Off_Invoice_Rate__c, iSOL.Allowances__c, iSOL.Freight_Allowance__c, iSOL.Discount_Percent__c);
							fulfillment.Parent_Fulfillment__c = f.Id;
							fulfillment.Start_Date__c = cursorDate;

							// Switching to date and then reinstancing to dateTime to capture correct GMT for that Day / Month.
							// Note* some days are -8 hrs and others are -7 hrs in GMT.
							// Simplying adding 1 month to a DateTime wont do so must do it to a Date and then convert to DateTime
							Date tmpDate = useNonFixedMonthlyIntervals ? cursorDate.date().addMonths(1) : cursorDate.date().addDays( Integer.valueOf(every * multiplier));
							// this is done for the purpose of breaking points, prorate months, and such.
							// Best Price has calculated the correct Start Date and End Date in the PricingResult.
							if (tmpDate > intervalEndDate.date()){
								tmpDate = intervalEndDate.date();
							}
							fulfillment.End_Date__c = DateTime.newInstance(tmpDate, Time.newInstance(0,0,0,0));

							cursorDate = fulfillment.End_Date__c;

							System.debug( '~*~ cursorDate (' + i + '): ' + fulfillment.Start_Date__c + ' - ' + fulfillment.End_date__c);
							System.debug( '~*~ Fulfillment (' + i + '): ' + PricingService.debugFulfillment(fulfillment) );
							updatedFulfillments.add(fulfillment);
						}
					}
				}

				f.Invoice_Ready__c = false;
				f.End_Date__c = f.Last_Bill_Date__c != null ? f.Last_Bill_Date__c : f.End_Date__c;
				f.Extended_Price__c = PricingService.returnPrice(qtyMult, f.Unit_Price__c, iSOL.Off_Invoice_Rate__c, iSOL.Allowances__c, iSOL.Freight_Allowance__c, iSOL.Discount_Percent__c);

				updatedFulfillments.add(f);
			}

            DML.checkUpsertAsUser(updatedFulfillments); upsert updatedFulfillments;
            
            ReceivingDocumentService.release(rdIDs);
            
            SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                    'Id','name'
            });
            soql.setWhereClause('Id IN :rdIDs');
            List<Receiving_Document__c> rds = Database.query(soql.getQuery());
            
            result.addMessage('Receiving Document ' + '<a href="/'+ rds[0].Id+'">' + rds[0].Name + '</a>' + ' was created successfully', ApexPages.Severity.CONFIRM);
            result.success = true;
        }catch(Exception e){
            Database.rollback(sp);
            result.success = false;
            result.addMessage('Receiving document creation failed: ' + e.getMessage() , ApexPages.Severity.ERROR);
            system.debug(LoggingLevel.ERROR, '~*\n' + e.getStackTraceString());
        }
        
        return result;
    }


    global class fulfillmentWrapper {
        
        public Sales_Order_Line__c sol {get;set;}
		public Agreement_Line__c agl {get;set;}
        public Fulfillment__c flmt {get;set;}
		public Uom__c pricingUom {get; set;}
        public ID itemID {get;set;}
        public boolean isSerialLine {get;set;}
        public double returnQty {get;set;}
        public string serial {get;set;}
        
        global fulfillmentWrapper() {
        
        }
    }
}