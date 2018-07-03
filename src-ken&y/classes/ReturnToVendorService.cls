public with sharing class ReturnToVendorService {

    public static Boolean subcontractPOsExist {get;private set;} { subcontractPOsExist = false;}
    public static Boolean dropShipPOsExist {get;private set;} { dropShipPOsExist = false;}
    public static String Supplier { get; set; }
    public static String Company { get; set; }
    public static String SupplierId;
    public static String CompanyId;
    public static map<Id, String> poStatusMap = new map<Id, String>();
    public static List< POLineWrapper > POLineWrapperlist { get ; set ; } { POLineWrapperlist = new List< POLineWrapper >(); } 
    public class ReturnToVendorServiceException extends Exception{
    }
    
    public static List<POLineWrapper> getreturningLines(set<Id> headerIds, set<Id> lineIds, set<String> docTypes){
        
        List<SObject> sobjRecs = new List<SObject>();
        
        sobjRecs = queryPOlines(headerIds, lineIds, docTypes, false);
       
        POLineWrapperlist = createPOLineWrapper( sobjRecs, docTypes);
        
        checkUserErrors(POLineWrapperlist);
        
        
        return POLineWrapperlist;
    }
    
    public static List<SObject> queryPOlines(set<id> headerIds, set<Id> lineIds, set<String> docTypes, Boolean includeSkids){
        
        List<SObject> sobjectRecs = new List<SObject>();
        String inClause;
        if(headerIds.size() > 0 || lineIds.size() > 0){

            Set<String> polFields = new Set<String>{ 'Id', 'Item__c','Purchase_Order__c', 'Purchase_UOM__c', 'Quantity_to_Stock__c','Sales_Order__c', 'Sales_Order_Line__c', 'Description__c','Sales_Order_Line__r.Name','Sales_Order_Line__r.Sales_Order__r.Type__c', 'Sales_Order_Line__r.Related_Sales_Order_Line__r.Returned_To_Vendor__c', 'Supplier__c', 'Delivery_Facility__c', 'Delivery_location__c', 'Contract_Line__c', 'Name', 'Purchase_Order__r.Company__c',
                                             'Purchase_UOM__c', 'Sales_Order_Line__r.Returned_To_Vendor__c', 'Company__c' , 'Company__r.name', 'Company__r.Default_Transaction_Currency__c', 'Purchase_Order__r.Supplier__c' , 'Line__c' , 'Order_Quantity__c' , 'Quantity_Returned_To_Supplier__c' ,'Quantity_Received__c' ,
                                             'Purchase_Order__r.Status__c', 'Purchase_Order__r.Currency__c', 'Unit_Price__c' , 'Quantity_Returned_To_Supplier_For_Credit__c' , 
                                             'Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__c', 'Consigned__c', 'Purchase_Order__r.Supplier__r.Name', 'Purchase_Order__r.Supplier__r.Create_RTV_Credit_Memo__c', 'Purchase_Order__r.Supplier__r.Create_RTV_PO__c', 
                                             'Purchase_Order__r.Company__r.Name', ' Purchase_Order__r.Remit_To_Supplier__c', 'Purchase_Order__r.FOB_Term__c', 'Purchase_Order__r.Transportation_Mode__c',
                                             'Purchase_Order__r.Quantity_Tolerance_Over__c', 'Company__r.Default_Transaction_Currency__c',
                                             'Purchase_Order__r.Unit_Price_Tolerance_Over__c','Purchase_Order__r.Amount_Tolerance__c', 'Purchase_Order__r.Purchase_Agreement__c',
                                             'Purchase_Order__r.Payment_Term__c', 'Purchase_Order__r.Remit_To_Supplier__r.Payment_Term__c', 'Purchase_Order__r.Supplier__r.Remit_To__c', 'Purchase_Order__r.Supplier__r.Remit_To__r.Payment_Term__c',
                                             'Purchase_Order__r.Delivery_Facility__c', 'Purchase_Order__r.Delivery_Location__c', 'Purchase_Order__r.Need_Date__c', 'Purchase_Order__r.Type__c','Sales_Order_Line__c', 'Sales_Order__r.Currency__c', 'purchase_order__r.currency__c', 'Company__r.Default_Transaction_Currency__c'
                            };
    
            if( docTypes.contains('Purchase_Order_Line__c'.toLowerCase()) && headerIds.size() >0){
                    
                inClause = 'Purchase_Order__c IN :headerIds';
            }
            else if(docTypes.contains('Sales_Order_Line__c'.toLowerCase()) && headerIds.size() >0){
                
                inClause = 'Sales_Order_Line__c IN :headerIds';
            }
            else if(lineIds.size() > 0){
                inClause = 'Id IN:lineIds';
            }
                                    
            SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c');
            soql.addFields('Return_To_Vendor');
            soql.addFields(polFields);
            soql.setWhereClause(inClause); 
            
            
            sobjectRecs = Database.query(soql.getQuery());
            
            
        }
        return sobjectRecs;
    }
    
    public static List<POLineWrapper> createPOLineWrapper(List< SObject > SObjlines, set<String> docTypes){
        
        Integer count = 0;
        List<POLineWrapper> lineWrapperlist = new List<POLineWrapper>();
        for( SObject sobj : SObjlines){
            if (sobj.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract' &&  subcontractPOsExist == false){
                subcontractPOsExist = true;
            }
            if (sobj.getSObject('Purchase_Order__r').get('Type__c') == 'Drop Ship' &&  dropShipPOsExist == false){
                dropShipPOsExist = true;
            }
            
            if(!poStatusMap.containsKey((Id)sobj.get('Purchase_Order__c')))
                poStatusMap.put( (Id)sobj.get('Purchase_Order__c'), (String)sobj.getSObject('Purchase_Order__r').get('Status__c') );       
            
            if( sobj.get('Order_Quantity__c') == null) sobj.put('Order_Quantity__c',0);
            if( sobj.get('Quantity_Received__c') == null) sobj.put('Quantity_Received__c',0);
            if( sobj.get('Quantity_Returned_to_Supplier__c') == null) sobj.put('Quantity_Returned_to_Supplier__c',0);
            if( sobj.get('Quantity_Returned_to_Supplier_for_Credit__c') == null) sobj.put('Quantity_Returned_to_Supplier_for_Credit__c',0);
            
            if( ( (Decimal)sobj.get('Quantity_Received__c') - (Decimal)sobj.get('Quantity_Returned_to_Supplier__c') - (Decimal)sobj.get('Quantity_Returned_to_Supplier_for_Credit__c') ) > 0 ){
                if(docTypes.contains('Sales_Order_Line__c'.toLowerCase())){
                    lineWrapperlist.add( new POLineWrapper((Purchase_Order_Line__c) sobj, (Sales_Order_Line__c) sobj.getSObject('Sales_Order_Line__r'),count ) );
                }
                else
                    lineWrapperlist.add( new POLineWrapper((Purchase_Order_Line__c) sobj, count ) );
            }
            count++;
        }
        
        return lineWrapperlist;
        
    }
    public static Boolean checkUserErrors(List<POLineWrapper> wrapperlist){
        if (subcontractPOsExist == true){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error , Label.Subcontracted_POs_cannot_be_returned_to_vendor));
            return true;
        }

        if( wrapperlist.size() > 0 ){
            Supplier = String.ValueOf( wrapperlist[0].polRecord.Purchase_Order__r.Supplier__r.Name );
            Company = String.ValueOf( wrapperlist[0].polRecord.Purchase_Order__r.Company__r.Name );
            
            SupplierId = String.ValueOf( wrapperlist[0].polRecord.Purchase_Order__r.Supplier__c );
            CompanyId = String.ValueOf( wrapperlist[0].polRecord.Purchase_Order__r.Company__c );
            
        }
        else{
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error , Label.Selected_PurchaseOrders_have_no_lines_with_quantity_available_to_return));
                return true;
        }
        
        for( POLineWrapper polw : wrapperlist ){
            
            if( polw.polRecord.Purchase_Order__r.Supplier__c != SupplierId || polw.polRecord.Purchase_Order__r.Company__c != CompanyId ){
                
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error , Label.Selected_PurchaseOrders_must_have_same_supplier_and_company));
                return true;
            }
            
            
            if( polw.newPolRecord.Quantity_Returned_To_Supplier__c == null ) polw.newPolRecord.Quantity_Returned_To_Supplier__c = 0;
            if( polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c == null ) polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 0;
            
            if( ( polw.polRecord.Quantity_Returned_To_Supplier__c + polw.newPolRecord.Quantity_Returned_To_Supplier__c +
                polw.polRecord.Quantity_Returned_To_Supplier_For_Credit__c + polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c < 0 )
                || ( polw.polRecord.Quantity_Returned_To_Supplier__c + polw.newPolRecord.Quantity_Returned_To_Supplier__c +
                polw.polRecord.Quantity_Returned_To_Supplier_For_Credit__c + polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c > polw.polRecord.Quantity_Received__c ) ){
            
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error , Label.Total_quantity_returned_cannot_be_less_than_zero));
                return true;    
            }
            
            if( polw.newPolRecord.Quantity_Returned_To_Supplier__c > 0 && polw.newPolRecord.Need_Date__c == null ){
                
                ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error , Label.Enter_need_date_for_quantities_returned));
                return true;
            }
            
        }
        
        return false;
    }
    //public static Map<String, List<SObject>> returnToVendor(List< POLineWrapper > polinewrappers, Map<Id,Sales_Order_Line__c> solinemap){
    public static Map<String, List<SObject>> returnToVendor(List< POLineWrapper > polinewrappers, Map<Id,Receipt_Line__c> receiptpolinemap, Map<Id,Sales_Order_Line__c> solinemap){
        
        Boolean newPOHeaderCreated = false;
        Boolean newRDHeaderCreated = false;
        Receiving_Document__c newRD;
        Decimal line = 0;
        
        List< Purchase_Order_Line__c > newPOLines = new List< Purchase_Order_Line__c >();
        List< Purchase_Order_Line__c > oldPOLines = new List< Purchase_Order_Line__c >();
        List< Receipt_Line__c > newRLines = new List< Receipt_Line__c >(); 
        Purchase_Order__c newPOHeader;
        List<Purchase_Order__c> newPOHeaderList = new List<Purchase_Order__c>();
        List< Purchase_Order_Line__c > newPOLinesForDisplay = new List< Purchase_Order_Line__c >();
        List< Supplier_Invoice__c > creditMemos = new List<Supplier_Invoice__c>();
        List< Supplier_Invoice_Line__c > creditMemoLines = new List<Supplier_Invoice_Line__c>(); 
        List<Receiving_Document__c> rdoclist = new List<Receiving_Document__c>();
        Map<String,List<SObject>> resultmap = new Map<String,List<SObject>>();
    
    
        Set<Id> ItemIds = new Set<Id>(); //PTP-283 Collecting ItemIds to retrieve the Active Std cost for the items to set to Extended cost on Receipt lines.
        Set<Id> FacilityIds = new Set<Id>();
        Integer i = 0;
        
        for( POLineWrapper polw : polinewrappers ){ //KNDY-6973
            ItemIds.add(polw.polRecord.Item__c);
            FacilityIds.add(polw.polRecord.Delivery_Facility__c);
        }
        for( POLineWrapper polw : polinewrappers ){
    
            polw.polRecord.Quantity_Returned_To_Supplier__c += polw.newPolRecord.Quantity_Returned_To_Supplier__c;
            polw.polRecord.Quantity_Returned_To_Supplier_For_Credit__c += polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c;
            
            if(polw.polRecord.Purchase_Order__r.Supplier__r.Create_RTV_Credit_Memo__c) {
                polw.polRecord.Quantity_Credited__c = (polw.polRecord.Quantity_Credited__c == null ? 0 : polw.polRecord.Quantity_Credited__c);
                polw.polRecord.Amount_Credited__c = (polw.polRecord.Amount_Credited__c == null ? 0 : polw.polRecord.Amount_Credited__c);
            
                if(polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c > 0) {
                    polw.polRecord.Quantity_Credited__c += -polw.polRecord.Quantity_Returned_To_Supplier_For_Credit__c;
                    polw.polRecord.Amount_Credited__c += polw.polRecord.Unit_Price__c * -polw.polRecord.Quantity_Returned_To_Supplier_For_Credit__c;
                }
            }
    
            if( polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c > 0 || polw.newPolRecord.Quantity_Returned_To_Supplier__c > 0 ){
                
                if( !newRDHeaderCreated ){
                    newRD = createRD(polw);
                    newRDHeaderCreated = true;
                }
                
                oldPOLines.add( polw.polRecord );
            }
            
            if( polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c > 0 ){
                
                newRLines.add( createReceiptLine( 0, polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c, polw.polRecord, newRD, ItemIds, FacilityIds ) );
                if( polw.polRecord.Consigned__c == false && polw.polRecord.Purchase_Order__r.Supplier__r.Create_RTV_Credit_Memo__c)
                    creditMemos.add( createCM( polw, polw.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c, i ));
            }
            
            
            if( polw.newPolRecord.Quantity_Returned_To_Supplier__c > 0 ){
                
                newRLines.add( createReceiptLine( polw.newPolRecord.Quantity_Returned_To_Supplier__c, 0 , polw.polRecord, newRD, ItemIds, FacilityIds ) );
                
                if(poStatusMap.get(polw.polRecord.Purchase_Order__c) != 'Cancelled' && polw.polRecord.Purchase_Order__r.Supplier__r.Create_RTV_PO__c && 
                    (polw.polRecord.Sales_Order_Line__c == null || ( polw.polRecord.Sales_Order_Line__r != null &&((solinemap.containskey(polw.polRecord.Sales_Order_Line__c) && solinemap.get(polw.polRecord.Sales_Order_Line__c).Returned_To_Vendor__c != true) || solinemap.keyset().size() == 0)))){
                    
                    if( !newPOHeaderCreated ){
                        
                        newPOHeader = createPOHeader(polw,polinewrappers);
                        newPOHeaderList.add(newPOHeader);
                        newPOHeaderCreated = true;
                    }           
                    newPOLines.add( createPl( polw, line , newPOHeader) );
                    line++;
                }
            }
            i++;
            
        }
       
         map<id,Receipt_Line__c> rdToRclMap = new map<id,Receipt_Line__c>();
        //Updated Related Receipt Line
        for(Receipt_Line__c rcl:newRLines){
            if(receiptpolinemap.values().size() > 0 && receiptpolinemap.containskey(rcl.Purchase_Order_Line__c)){
                rcl.Related_Receipt_Line__c = receiptpolinemap.get(rcl.Purchase_Order_Line__c).id;
                rcl.Related_Receipt_Line__r = receiptpolinemap.get(rcl.Purchase_Order_Line__c);
                rcl.Facility__c = receiptpolinemap.get(rcl.Purchase_Order_Line__c).Facility__c;  
                rcl.Location__c = receiptpolinemap.get(rcl.Purchase_Order_Line__c).Location__c;
                if(!rdToRclMap.containskey(rcl.Related_Receipt_Line__c)){
                     rdToRclMap.put(rcl.Receiving_Document__c,rcl.Related_Receipt_Line__r);
                }
                
            }
        }
        try{
        DML.updateAsUser(oldPOLines);
        DML.insertAsUser(newPOLines);
        DML.insertAsUser(newRLines);
        DML.insertAsUser(creditMemos);
        }catch(DmlException e){
            system.debug('Error: ' + e.getstacktracestring());
        }
        Set<Id> newPOLIds = new Set<Id>();
        Set<Id> newCMIds = new Set<Id>();
        
        for( Purchase_Order_Line__c newPol : newPOLines )
            newPOLIds.add( newPol.id );
        
        
        for( Supplier_Invoice__c si : creditMemos ){
            
            Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
            Integer index = Integer.valueOf(si.return_to_vendor__c);
            cml.Item__c = polinewrappers[ index ].polRecord.Item__c;
            cml.Purchase_Order__c = polinewrappers[index].polRecord.Purchase_Order__c;      
            cml.Purchase_Order_Line__c = polinewrappers[index].polRecord.Id;
            cml.Purchase_UOM__c = polinewrappers[index].polRecord.Purchase_UOM__c; //KNDY-11234
            cml.Unit_Price__c = polinewrappers[index].polRecord.unit_Price__c ;            
            cml.Invoice_Quantity__c = si.Credit_Memo_Amount__c / polinewrappers[index].polRecord.unit_Price__c; // to get the quantity returned
            cml.Supplier_Invoice__c = si.id;
            si.Supplier_Invoice__c = si.id; //KNDY-3491
            
            if(polinewrappers[index].polRecord.Company__r.Default_Transaction_Currency__c == null) {      //KNDY-4732
                si.Currency__c = polinewrappers[index].polRecord.Purchase_Order__r.Currency__c;
            }
            else {
                si.Currency__c = polinewrappers[index].polRecord.Company__r.Default_Transaction_Currency__c;
            }
            creditMemoLines.add( cml );
            newCMIds.add( si.id );
        }
        
        DML.updateAsUser(creditMemos);//KNDY-3491
        DML.insertAsUser(creditMemoLines);
        
        if(newPOLIds.size()>0)
            newPOLinesForDisplay = ( List<Purchase_Order_Line__c> ) queryPOlines(new Set<Id>(), newPOLIds, new Set<String>{'Purchase_Order_Line__c'.toLowerCase()},false);
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name','Invoice_Type__c','Currency__c','Credit_Memo_Amount__c','Status__c'
        });
        soql.setWhereClause('Id IN :newCMIds');

        creditMemos = Database.query(soql.getQuery());
            
        if(newRD != null) { //PTP-298
            newRD.finalized__c = true;
            if(!rdToRclMap.isempty() && newRD.Transaction_Type__c == 'Logical Purchase Order Return' && rdToRclMap.get(newRD.id).Receiving_Document__r.Transaction_Date__c != null){
                newRD.Transaction_Date__c = rdToRclMap.get(newRD.id).Receiving_Document__r.Transaction_Date__c;
            }else {
            newRD.Transaction_Date__c = system.now();
            }
            
            DML.updateAsUser(newRd);
        }
        for(Receipt_Line__c rcl: newRLines){
            Receiving_Document__c rdoc = new Receiving_Document__c(Id = rcl.Receiving_Document__c);
            rdoclist.add(rdoc);
        }
        
        resultmap.put('oldPOLines',oldPOLines);
        resultmap.put('newPOLinesForDisplay',newPOLinesForDisplay);
        resultmap.put('creditMemos',creditMemos);
        resultmap.put('creditMemoLines',creditMemoLines);
        resultmap.put('rdoclist',rdoclist);
        resultmap.put('newRLines',newRLines);
        resultmap.put('newPLines',newPOLines);
        resultmap.put('newPOHeader',newPOHeaderList);
        
        return resultmap;
    }
    
    public static Purchase_Order__c createPOHeader(POLineWrapper polw, List<POLineWrapper> polineslist){
        
        Purchase_Order__c newPO = new Purchase_Order__c();
                newPO.Company__c = polineslist[0].polRecord.Company__c;
                newPO.Supplier__c = polineslist[0].polRecord.Purchase_Order__r.Supplier__c;
                newPO.Remit_To_Supplier__c = polineslist[0].polRecord.Purchase_Order__r.Remit_To_Supplier__c;
                newPO.FOB_Term__c = polineslist[0].polRecord.Purchase_Order__r.FOB_Term__c;
                newPO.Transportation_Mode__c = polineslist[0].polRecord.Purchase_Order__r.Transportation_Mode__c;
                newPO.Amount_Tolerance__c = polineslist[0].polRecord.Purchase_Order__r.Amount_Tolerance__c;
                newPO.Quantity_Tolerance_Over__c = polineslist[0].polRecord.Purchase_Order__r.Quantity_Tolerance_Over__c;
                //newPO.Quantity_Tolerance_Under__c = polineslist[0].polRecord.Purchase_Order__r.Quantity_Tolerance_Under__c;
                newPO.Unit_Price_Tolerance_Over__c = polineslist[0].polRecord.Purchase_Order__r.Unit_Price_Tolerance_Over__c;
                //newPO.Unit_Price_Tolerance_Under__c = polineslist[0].polRecord.Purchase_Order__r.Unit_Price_Tolerance_Under__c;
                newPO.Purchase_Agreement__c =  polineslist[0].polRecord.Purchase_Order__r.Purchase_Agreement__c;
                newPO.Payment_Term__c =  polineslist[0].polRecord.Purchase_Order__r.Payment_Term__c;
                newPO.Delivery_Facility__c =  polineslist[0].polRecord.Purchase_Order__r.Delivery_Facility__c;
                newPO.Delivery_Location__c = polineslist[0].polRecord.Purchase_Order__r.Delivery_Location__c;
                newPO.Amount_Tolerance__c = polineslist[0].polRecord.Purchase_Order__r.Amount_Tolerance__c;
                newPO.Currency__c = polineslist[0].polRecord.Purchase_Order__r.Currency__c;

                newPO.Need_Date__c = polw.newPolRecord.Need_Date__c;
                newPO.Status__c = 'Open';

        //KNDY-1916
        try{
        DML.insertAsUser(newPO);
        
        
        }catch(DmlException e){
            system.debug(e.getstacktracestring() );
        }
        return newPO;
    }

    public static Purchase_Order_Line__c createPl( POLineWrapper polw, Decimal line, Purchase_Order__c newPOHeader){
        
        Purchase_Order_Line__c newPOLine = new Purchase_Order_Line__c();
                newPOLine.Order_Quantity__c = polw.newPolRecord.Quantity_Returned_To_Supplier__c;
                newPOLine.Description__c = polw.newPolRecord.Description__c;
                newPOLine.Quantity_Returned_to_Supplier_for_Credit__c =0;
                newPOLine.Quantity_Returned_to_Supplier__c =0;
                newPOLine.Quantity_Received__c =0;
                newPOLine.Purchase_Order__c = newPOHeader.Id;
                newPOLine.Company__c = newPOHeader.Company__c;
                newPOLine.Need_Date__c = polw.newPolRecord.Need_Date__c;
                newPOLine.Item__c = polw.polRecord.Item__c;
                newPOLine.Purchase_UOM__c = polw.polRecord.Purchase_UOM__c; //KNDY-11328
                newPOLine.Unit_Price__c = polw.polRecord.Unit_Price__c;
                newPOLine.overage_percentage__c = polw.polRecord.overage_percentage__c;
                newPOLine.promise_date__c = polw.polRecord.promise_date__c;
                newPOLine.Date_Last_Changed__c = null;
                newPOLine.Supplier__c = polw.polRecord.Supplier__c;
                newPOLine.Delivery_Facility__c = polw.polRecord.Delivery_Facility__c;
                newPOLine.Delivery_Location__c = polw.polRecord.Delivery_location__c;
                newPOLine.Line__c = line;
                newPOLine.Contract_Line__c = polw.polRecord.Contract_Line__c;
				newPOLine.Quantity_Matched__c = polw.newPolRecord.Quantity_Returned_To_Supplier__c; //KNDY-14213
        return newPOLine;       
        
    }
    
    public static Supplier_Invoice__c createCM( POLineWrapper polw, Decimal quantityReturned, Integer poWrapperIndex ){
        
        Supplier_Invoice__c cm = new Supplier_Invoice__c();
                cm.Company__c = CompanyId;
                cm.Purchase_Order__c = polw.polRecord.Purchase_Order__c;
                cm.Currency__c = polw.polRecord.Currency__c;
                //KNDY-4036 : The supplier on the RTV Credit Memo should be the remit to supplier of PO
                cm.Supplier__c = (polw.polRecord.Purchase_Order__r.Remit_to_Supplier__c!=null?polw.polRecord.Purchase_Order__r.Remit_to_Supplier__c:polw.polRecord.Purchase_Order__r.Supplier__r.Remit_To__c);
                cm.Invoice_Amount__c = polw.polRecord.unit_Price__c * -quantityReturned;
                cm.Invoice_Type__c = 'Credit Memo';
                cm.Payment_Term__c = (polw.polRecord.Purchase_Order__r.Payment_Term__c != null ? polw.polRecord.Purchase_Order__r.Payment_Term__c : polw.polRecord.Purchase_Order__r.Supplier__r.Remit_To__r.Payment_Term__c);
                cm.Status__c = 'Incomplete'; //KNDY-2843 Setting to Incomplete instead of Approved
                cm.Supplier_Invoice__c = KSE.getUniqueNumberString(); //KNDY-3491
                cm.Credit_Memo_Amount__c = polw.polRecord.unit_Price__c * -quantityReturned;
                cm.Credit_Memo_Balance__c = polw.polRecord.unit_Price__c * -quantityReturned;
                cm.Date_Invoiced__c = system.now();
                cm.return_to_vendor__c = poWrapperIndex; //stores the powrapper index in this scrap field to grab the item from the poline when creating credit memo lines
                
        return cm;
    }
    
    public static Receiving_Document__c createRD(POLineWrapper polinewrap){
        
        String rdType;
        
        if(polinewrap.logical == true)
            rdType = 'Logical Purchase Order Return';
        else
            rdType = 'Purchase Order Return';
        
        Receiving_Document__c RD = new Receiving_Document__c();
                RD.Company__c = polinewrap.polRecord.Company__c;
                RD.Supplier__c = polinewrap.polRecord.Purchase_Order__r.Supplier__c;
                RD.Currency__c = polinewrap.polRecord.Company__r.Default_Transaction_Currency__c;
                RD.Date_Created__c = system.today();
                RD.Type__c = rdType;
                RD.Transaction_Type__c = rdType;
                RD.Status__c = 'Closed';
                DML.insertAsUser(RD);
        
        return RD;
    }
    
    //PTP-283 Retreiving the Item's Active Std Cost while setting the Extended cost
    public static Receipt_Line__c createReceiptLine( Decimal QtyRTS, Decimal QtyRTSFC, Purchase_Order_Line__c poLine, Receiving_Document__c RD, Set<Id> ItemIds, Set<Id> FacilityIds ){
        
        Receipt_Line__c rl = new Receipt_Line__c( Company__c = poLine.purchase_order__r.company__c, Supplier__c = poLine.purchase_order__r.supplier__c,
            Purchase_Order__c = poLine.purchase_order__c, Purchase_Order_Line__c = poLine.id, item__c = poLine.item__c, 
            Quantity_Returned_To_Supplier__c = QtyRTS, Quantity_Returned_To_Supplier_For_Credit__c = QtyRTSFC, Receiving_Document__c = RD.id, Status__c = 'Closed',
            Unit_Price__c = poLine.Unit_Price__c, 
            Extended_Cost__c = ( QtyRTS + QtyRTSFC ) * (ItemService.getActiveStandardCostDecimal(ItemIds,FacilityIds,poLine.purchase_order__r.company__c,poLine.Delivery_Facility__c,System.Now(), poLine.Item__c)), 
            Location__c = poLine.Delivery_Location__c, Facility__c = poLine.Delivery_Facility__c );
        if( poLine.Consigned__c == true )
            rl.line_type__c = 'Consigned';
        return rl;
    }
    
    public class POLineWrapper{
        
        public Purchase_Order_Line__c polRecord { get; set; }
        public Purchase_Order_Line__c newPolRecord { get; set; }
        public Sales_Order_Line__c solRecord { get; set; }
        //public Boolean dateDisabled { get; set; } { dateDisabled = true;}
        public Integer rowIndex { get; set; }
        public Decimal QuantityAvailable { get; set;}
        public boolean logical { get; set; }
    
        public POLineWrapper( Purchase_Order_Line__c pol , Integer num ){
            
            newPolRecord = pol.clone( false, true ); 
            newPolRecord.Quantity_Returned_To_Supplier__c = 0 ; newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 0;
            newPolRecord.Date_Added__c = system.today();
            newPolRecord.Date_Closed__c = null;
            newPolRecord.Date_Last_Changed__c = system.today();  
            newPolRecord.MRP_Plan__c = null;           
            newPolRecord.Status__c = 'Open';  
            
            polRecord = pol;
            
            QuantityAvailable = pol.Quantity_Received__c - pol.Quantity_Returned_to_Supplier__c - pol.Quantity_Returned_to_Supplier_for_Credit__c;
            
            rowIndex = num;
            this.logical = false;
            
            
        }
        public POLineWrapper( Purchase_Order_Line__c pol , Sales_Order_Line__c sol, Integer num ){
            
            newPolRecord = pol.clone( false, true ); 
            newPolRecord.Quantity_Returned_To_Supplier__c = 0 ; newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 0;
            newPolRecord.Date_Added__c = system.today();
            newPolRecord.Date_Closed__c = null;
            newPolRecord.Date_Last_Changed__c = system.today();  
            newPolRecord.MRP_Plan__c = null;           
            newPolRecord.Status__c = 'Open';  
            
            polRecord = pol;
            solRecord = sol;
            
            QuantityAvailable = pol.Quantity_Received__c - pol.Quantity_Returned_to_Supplier__c - pol.Quantity_Returned_to_Supplier_for_Credit__c;
            
            rowIndex = num;
            this.logical = false;
            
            
        }
   
    }
}