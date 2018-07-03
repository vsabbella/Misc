var SupplierInvoiceUtility = function() {
    return {
        
        <!----Functions related to Supplier Invoice header starts ----->
        
        //Changing the company on the supplier invoice header the below method is called 
        OnCompanyChange: function(e) {
        SupplierInvoiceManageUtil.ActivateMatchToPOButton();
        var self = this;
        var companyId = $(e.target).val();
        console.log(companyId);
        if (!companyId) {
        	//KNDY-18171
            SupplierInvoiceManageUtil.SetBilltoFields(true);
        	return;
        }
    
	    var poFilterCriteria = "Company__c = \'"+ companyId +"\' and Remit_To_Supplier__r.Status__c = \'Active\'";
	    var supplierFilterCriteria = "( Company__c = \'"+ companyId  +"\' or Company__c = null ) and Type__c = \'Remit-To\' and Status__c = \'Active\'";
	    $('input[name="Purchase_Order__r.Name"]').data('kendoLookup').options.criteria = poFilterCriteria;
	    $('input[name="Supplier__r.Name"]').data('kendoLookup').options.criteria = supplierFilterCriteria;
    
	    KenandyErp.BlockUI();
	    
	    Visualforce.remoting.Manager.invokeAction(
	        (nspace?nspace +'.':'') +className+'.getCompanyDetails',
	        companyId,
	        function (result, event) {
	            KenandyErp.UnBlockUI();
	            
	            if (event.type == 'exception') {
	                KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
	            } else {
	                KenandyErp.CleanNamespace(result.records, NamespaceUU);
	                
	                if (result.success) {
	                    if (result.records && result.records.length > 0) {
	                        var company = result.records[0];   
	                        
	                        var transactionCurrencyDefault = (company.Default_Transaction_Currency__c) ? company.Default_Transaction_Currency__c : null;
	                        var transactionCurrencyRef = (company.Default_Transaction_Currency__r) ? company.Default_Transaction_Currency__r : { Id: null, Name: null };
	                        
	                        SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Date_Invoiced__c','');
	                        SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Due_Date__c','');
	                        SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Discount_Date__c','');
	                        
	                        //KNDY-18171
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Company__r', company);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Company__c', company.Id);
                                
	                        if(transactionCurrencyRef != null && transactionCurrencyRef.Id != null){ //Company has currency
	                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__r', transactionCurrencyRef);
	                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__c', transactionCurrencyDefault);
	                            currency = transactionCurrencyDefault;
	                            currencyRef = transactionCurrencyRef;
	                        }else{
	                            // do nothing - as on a Company Currency is Mandatory
	                        }
	                        
	                        var supplierId = SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Supplier__c');
	                        if(supplierId != ""){
	                            Visualforce.remoting.Manager.invokeAction(
	                                (nspace?nspace +'.':'') +className+'.getPaymentDefaults',
	                                null,
	                                companyId,
	                                function (result, event) {
	                                    if (event.type == 'exception') {
	                                        KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
	                                    } else {
	                                        KenandyErp.CleanNamespace(result.records, NamespaceUU);
	                                        if (result.success) {
	                                            
	                                            var supplierIds = [];
	                                            if (result.records && result.records.length > 0) {
	                                                for(var i=0; i < result.records.length;i++){
	                                                    var supplier = result.records[i];  
	                                                    supplierIds.push(supplier.Id);
	                                                }
	                                            }
	                                            
	                                            var containsSupplierId = false;
	                                            for(var j=0; j < supplierIds.length; j++ ){
	                                                if(supplierIds[j] === SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Supplier__c')){
	                                                    containsSupplierId = true;
	                                                }   
	                                            }
	                                            
	                                            if(!containsSupplierId){
	                                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Supplier__r', { Id: null, Name: null });
	                                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Supplier__c', null);
	                                            }
	                                            
	                                            var supplierCurrencyRef;
	                                            var supplierCurrency;
	                                            
	                                            if (result.records && result.records.length > 0) {
	                                                for(var i=0; i < result.records.length;i++){
	                                                    if(supplierId === result.records[i].Id){
	                                                        var supplierRecordData = result.records[i];
	                                                        supplierCurrencyRef = (supplierRecordData.Currency__r) ? supplierRecordData.Currency__r : { Id: null, Name: null };
	                                                        supplierCurrency = (supplierRecordData.Currency__c) ? supplierRecordData.Currency__c : null;
	                                                    }    
	                                                }
	                                            }
	                                            
	                                            if(supplierCurrencyRef != null && supplierCurrencyRef.Id != null){ // supplier has currency
	                                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__r', supplierCurrencyRef);
	                                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__c', supplierCurrency);
	                                                currency = supplierCurrency; //currency holds the  default company currency 
	                                            }else{
	                                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__r', transactionCurrencyRef);
	                                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__c', transactionCurrencyDefault);
	                                            }
	                                            //KNDY-18171
							            		SupplierInvoiceManageUtil.SetBilltoFields(true);
							            		SupplierInvoiceManageUtil.SetBillFromFields();  
	                                        }
	                                    }
	                                }, 
	                                {escape: false}
	                            );
							
                          }else{
                          	//KNDY-18171
		            		SupplierInvoiceManageUtil.SetBilltoFields(true);
		            		SupplierInvoiceManageUtil.SetBillFromFields();
                          } 
                    }
                }
             }
          },
        {escape: false}
      );
    },
    
    //Changing the purchase order on the supplier invoice header the below method is called 
    OnPurchaseOrderHeaderChange: function(e) {
        isPOChanged = true;
        var self = this;
        var purchaseOrderId = $(e.target).val();
        
        if (!purchaseOrderId) {
            if(purchaseOrderId == "")
            {  
                $('input[name="Currency__r.Name"]').prop('disabled',false);
                $('input[name="Company__r.Name"]').prop('disabled',false);  
                $('input[name="Supplier__r.Name"]').prop('disabled',false);
            }   
            //KNDY-18171
            SupplierInvoiceManageUtil.SetBillFromFields();
            return;
        }
        
        KenandyErp.ClearMessage();
        KenandyErp.BlockUI();
        
        Visualforce.remoting.Manager.invokeAction(
            (nspace?nspace +'.':'') +className+'.getPurchaseOrderDetails',
            purchaseOrderId,
            function (result, event) {
                KenandyErp.UnBlockUI();
                
                if (event.type == 'exception') {
                    KenandyErp.Message(event.message, KenandyErp.MessageType.Error);
                } else {
                    KenandyErp.CleanNamespace(result.records, NamespaceUU);
                    
                    if (result.success) {
                        if (result.records && result.records.length > 0) { 
                            var purchaseOrder = result.records[0];   
                            var supplier = (purchaseOrder.Remit_To_Supplier__c) ? purchaseOrder.Remit_To_Supplier__c : null;
                            var supplierRef = (purchaseOrder.Remit_To_Supplier__r) ? purchaseOrder.Remit_To_Supplier__r : { Id: null, Name: null };
                            var company = (purchaseOrder.Company__c) ? purchaseOrder.Company__c : null;
                            var companyRef = (purchaseOrder.Company__r) ? purchaseOrder.Company__r : { Id: null, Name: null };
                            var paymentTermRef = (purchaseOrder.Payment_Term__r) ? purchaseOrder.Payment_Term__r : { Id: null, Name: null };                                        
                            var paymentTerm = (purchaseOrder.Payment_Term__c) ? purchaseOrder.Payment_Term__c : null;
                            var paymentMethod = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.Payment_Method_G__c) ? purchaseOrder.Remit_To_Supplier__r.Payment_Method_G__c : null;                                     
                            var address = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.Address__c) ? purchaseOrder.Remit_To_Supplier__r.Address__c : null;
                            var street = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.Street__c) ? purchaseOrder.Remit_To_Supplier__r.Street__c : null;
                            var city = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.City__c) ? purchaseOrder.Remit_To_Supplier__r.City__c : null;
                            var state = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.State__c) ? purchaseOrder.Remit_To_Supplier__r.State__c : null;
                            var country = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.Country__c) ? purchaseOrder.Remit_To_Supplier__r.Country__c : null;
                            var alwaysTakeDiscount = (purchaseOrder.Remit_To_Supplier__r && purchaseOrder.Remit_To_Supplier__r.Always_Take_Discount__c) ? purchaseOrder.Remit_To_Supplier__r.Always_Take_Discount__c : false;
                            var purchaseOrderCurrency = (purchaseOrder.Currency__c) ? purchaseOrder.Currency__c : null;
                            var purchaseOrderCurrencyRef = (purchaseOrder.Currency__r) ? purchaseOrder.Currency__r : { Id: null, Name: null };
                            
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Supplier__r', supplierRef);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Supplier__c', supplier);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Company__r', companyRef);                                         
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Company__c', company);         
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Term__r', paymentTermRef);                                                                        
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Term__c', paymentTerm);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Method_G__c', paymentMethod);                                       
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remittance_Address__c', address);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_Street__c', street);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_City__c', city);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_State__c', state);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_Country__c', country);
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Always_Take_Discount__c', alwaysTakeDiscount);  
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Date_Invoiced__c','');
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Due_Date__c','');
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Discount_Date__c','');
                            var purchaseOrder = $('#Purchase_Order__c').val();
                            
                            if(purchaseOrder != null || purchaseOrder != ""){  
                                if(purchaseOrderCurrencyRef != null && purchaseOrderCurrencyRef.Id != null){ // po has currency
                                    SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__r', purchaseOrderCurrencyRef);
                                    SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__c', purchaseOrderCurrency);
                                    currency = purchaseOrderCurrency; 
                                } 
                                if(purchaseOrderCurrencyRef != null && purchaseOrderCurrencyRef.Id != null
                                   && supplierRef != null && supplierRef.Id != null){
                                    $('input[name="Company__r.Name"]').prop('disabled',true);
                                    $('input[name="Supplier__r.Name"]').prop('disabled',true);
                                    $('input[name="Currency__r.Name"]').prop('disabled',true);  
                                } 
                            }
                        }
                        
                        var yesCallback = function() {
                            // Reload invoice lines grid
                            SupplierInvoiceManageUtil.RenderInvoiceLinesGrid();                         
                            // set the defaults
                            $('input[name="Purchase_Order__r.Name"]').prop('default_po_name', SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Purchase_Order__r.Name'));
                            $('input[name="Purchase_Order__r.Name"]').prop('default_po_id', SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Purchase_Order__c'));
                        };
                        
                        var noCallback = function() {
                            // Reset the purchase order
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Purchase_Order__r.Name', $('input[name="Purchase_Order__r.Name"]').prop('default_po_name'));
                            SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Purchase_Order__c', $('input[name="Purchase_Order__r.Name"]').prop('default_po_id'));
                        };
                        
                        if (SupplierInvoiceManageUtil.InvoiceLinesGrid && SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource && SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource.total() > 0) {
                            KenandyErp.Confirmation(label_changing_purchase_order_resets_invoice_lines, yesCallback, noCallback, noCallback);
                        }
                        else {
                            yesCallback();
                        }
                    }
                    //KNDY-18171
                    SupplierInvoiceManageUtil.SetBillFromFields();
                }
            },
            {escape: false}
        );
    },
        
        //Changing the supplier on the supplier invoice header the below method is called 
        OnSupplierChange: function(e) {
            SupplierInvoiceManageUtil.ActivateMatchToPOButton();
            var self = this;
            var supplierId = $(e.target).val();
            
            if (!supplierId) {
            	//KNDY-18171
            	SupplierInvoiceManageUtil.SetBillFromFields();
                return;
            }
            
            KenandyErp.BlockUI();
            console.log((nspace?nspace +'.':'') +className);
            Visualforce.remoting.Manager.invokeAction(
                (nspace?nspace +'.':'') +className+'.getPaymentDefaults',
                supplierId,
                null,
                function (result, event) {
                    KenandyErp.UnBlockUI();
                    
                    if (event.type == 'exception') {
                        KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
                    } else {
                        KenandyErp.CleanNamespace(result.records, NamespaceUU);
                        
                        if (result.success) {
                            if (result.records && result.records.length > 0) {
                                var supplier = result.records[0];   
                                var paymentTermRef = (supplier.Payment_Term__r) ? supplier.Payment_Term__r : { Id: null, Name: null };                                      
                                var paymentTerm = (supplier.Payment_Term__c) ? supplier.Payment_Term__c : null;
                                var paymentMethod = (supplier.Payment_Method_G__c) ? supplier.Payment_Method_G__c : null;                                                                               
                                var address = (supplier.Address__c) ? supplier.Address__c : null;
                                var street = (supplier.Street__c) ? supplier.Street__c : null;
                                var city = (supplier.City__c) ? supplier.City__c : null;
                                var state = (supplier.State__c) ? supplier.State__c : null;
                                var country = (supplier.Country__c) ? supplier.Country__c : null;
                                var alwaysTakeDiscount = (supplier.Always_Take_Discount__c) ? supplier.Always_Take_Discount__c : false;
                                var supplierCurrencyRef = (supplier.Currency__r) ? supplier.Currency__r : currencyRef;
                                var supplierCurrency = (supplier.Currency__c) ? supplier.Currency__c : currency;
                                var purchaseOrder = $('#Purchase_Order__c').val();
                                
                                //KNDY-18171
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Supplier__r', supplier);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Supplier__c', supplier.Id);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Term__r', paymentTermRef);                                        
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Term__c', paymentTerm);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Payment_Method_G__c', paymentMethod);                                       
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remittance_Address__c', address);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_Street__c', street);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_City__c', city);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_State__c', state);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Remit_to_Country__c', country);
                                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Always_Take_Discount__c', alwaysTakeDiscount);
                                
                                if((SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Payment_Term__c') != null || SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Payment_Term__c') != '') 
                                        && SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Date_Invoiced__c') != null){
                                    SupplierInvoiceManageUtil.OnPaymentTermChange(e);  
                                }
                                
                                
                                if(purchaseOrder == null || purchaseOrder == ""){  
                                    if(supplierCurrencyRef != null && supplierCurrencyRef.Id != null){ // supplier has currency
                                        SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__r', supplierCurrencyRef);
                                        SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Currency__c', supplierCurrency);
                                        currency = supplierCurrency; //currency holds the  default company currency
                                        //currencyRef =  supplierCurrencyRef;
                                    }  
                                }else{ //PO entered on the SI header
                                    //do nothing
                                }
                            }
                            
                            var loadInvoiceLinesGridCallback = function() {
                                // Reload invoice lines grid
                                SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource.read({
                                    readOptions: {
                                        loadFromPO: false
                                    }
                                });
                            };
                            
                            if (SupplierInvoiceManageUtil.InvoiceLinesGrid && SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource && SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource.total() > 0) {
                                KenandyErp.Confirmation(label_Changing_remit_to_supplier_resets_invoicelines, loadInvoiceLinesGridCallback);
                            }
                        }
                        //KNDY-18171
                        SupplierInvoiceManageUtil.SetBillFromFields();
                    }
                },
                {escape: false}
            );
        },
            
        // This function enables and disables the Match to PO button
        OnInvoiceTypeChange: function(e){
            SupplierInvoiceManageUtil.ActivateMatchToPOButton();
            SupplierInvoiceUtility.ChangePoPolField();
        },
            
            
        ChangePoPolField: function(e){
            if($('#Invoice_Type__c').val() == 'Prepayment' || SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Invoice_Type__c') == 'Prepayment'){
                isInvTypeChanged = true;
                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Purchase_Order__r.Name','');
                SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.set('Purchase_Order__c','');
                SupplierInvoiceManageUtil.RenderInvoiceLinesGrid();
            }
        },
                    
       /* Save Action function of the Supplier Invoice on the header.  
	    Any Save Action performed on the SI this function would be called */              
        Save: function(e) {
            var self = this;
            var actionType = self.actionType;
            var grid = self.grid;
            var detailList = SupplierInvoiceManageUtil.InvoiceHeaderDetailList;
            var options = self.options;
            var modelIdField = grid.dataSource.options.schema.model.idField;
            
            var messageElement = grid.element.closest("div.grid-container").find("div.grid-message:first");
            var isNewSupplierInvoice = (!detailList.data.get('Id')) ? true : false;
            var hasHeaderPOChanged = ($('#defaultPurchaseOrderId').val() != '' && $('#defaultPurchaseOrderId').val() != detailList.data.get('Purchase_Order__c')) ? true : false;
            //var returnUrl = '{!ReturnUrl}';
            
            KenandyErp.ClearMessage();
            
            if (!detailList.validate()) {
                KenandyErp.Message(label_Please_fix_the_following_errors);
                e.preventDefault();
                return false;
            }
            
            var linesAmount = SupplierInvoiceUtility.GetLineTotal();
            var invAmount = SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Invoice_Amount__c');
            SupplierInvoiceManageUtil.InvoiceType = SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Invoice_Type__c');
            
            if ((SupplierInvoiceManageUtil.InvoiceType == SupplierInvoiceManageUtil.InvoiceTypeEnum.Prepayment 
                        || SupplierInvoiceManageUtil.InvoiceType == SupplierInvoiceManageUtil.InvoiceTypeEnum.CreditMemo)) {
                    if(invAmount != null && invAmount == 0){
                        KenandyErp.Message(label_CM_or_Prepayment_on_SI_cannot_be_zero);
                        return;
                    }
            }
            
            
            if (SupplierInvoiceManageUtil.InvoiceType == SupplierInvoiceManageUtil.InvoiceTypeEnum.Invoice) {
                if(invAmount == null || invAmount < 0){
                    KenandyErp.Message(label_Invoice_amount_cannot_be_negative_for_an_invoice);
                    return;
                }
                
                if (linesAmount < 0) {
                    KenandyErp.Message(label_Total_line_amount_cannot_be_negative_for_an_invoice);
                    return;
                }
            }
            else if (SupplierInvoiceManageUtil.InvoiceType == SupplierInvoiceManageUtil.InvoiceTypeEnum.CreditMemo) {
                if(invAmount == null || invAmount > 0){
                    KenandyErp.Message(label_Invoice_amount_cannot_be_positive_for_a_credit_memo);
                    return;
                }
                
                if (linesAmount > 0) {
                    KenandyErp.Message(label_Total_line_amount_cannot_be_positive_for_a_credit_memo);
                    return;
                }
            }
            else if (SupplierInvoiceManageUtil.InvoiceType == SupplierInvoiceManageUtil.InvoiceTypeEnum.Prepayment) {
                    if(invAmount == null || invAmount < 0){
                        KenandyErp.Message(label_Invoice_amount_cannot_be_negative_for_a_prepayment);
                        return;
                    }
                    
                    if (linesAmount < 0) {
                        KenandyErp.Message(label_Total_line_amount_cannot_be_negative_for_a_prepayment);
                        return;
                    }
            } 
            if (!SupplierInvoiceUtility.IsValidSegments(grid)) {
                return false;
            }
            
            var headerDateFields = detailList.getDateFields();
            var headerRowsList = [];
            var headerRows = [];
            
            headerRowsList.push(detailList.data);
            
            headerRows = $.map(headerRowsList, function(item, index) {
                item = item.toJSON();
                item = Serializer.ConvertToSFDCDate(item, { dateFields: headerDateFields });
                
                return item;
            });
            
            if (headerRows.length > 0) {
                headerRows = Serializer.ParameterMap(headerRows);
            }
            
            var gridUtils = new KendoGridUtils(grid, { dateFields: options.dateFields, isDml: false });
            var updatedRows = [];
            var newRows = [];
            var deletedRows = [];
            
            newRows = gridUtils.NewRows();
            updatedRows = gridUtils.UpdatedRows();
            deletedRows = gridUtils.DeletedRows(); 
            
            // defaulting the fields of data type - checkbox, to value false.
             var booleanFields = [];
             var fieldNames = [];
             var grid = SupplierInvoiceManageUtil.InvoiceLinesGrid;
             
             $.each(grid.columns, function (idx, item) {
                   if(item.field.startsWith('invoiceLine') && item.field.endsWith('__c')){
                      fieldNames.push(item.field);
                   }
             });
                 
             var loopLength = (newRows.length > 0)? 1:0;
             for (var i = 0; i < loopLength; i++) {
                for(var j = 0; j < fieldNames.length; j++){
                  if(typeof grid.dataSource.data()[i].fields[fieldNames[j]] != 'undefined'){
                     if(grid.dataSource.data()[i].fields[fieldNames[j]].type === 'boolean'){
                        if(fieldNames[j].startsWith('invoiceLine') && fieldNames[j].endsWith('__c')){
                              booleanFields.push(fieldNames[j].split('.')[1]);
                        }   
                     }
                  }      
                }  
              }
              
              for(var k = 0; k < newRows.length; k++){
                for(var l = 0; l < booleanFields.length; l++){
                  if(newRows[k].invoiceLine[booleanFields[l]] == null){
                     newRows[k].invoiceLine[booleanFields[l]] = false;
                  }
                }
              }
              
            var proceedWithSave = SupplierInvoiceManageUtil.ValidateDuplicatePOLines(newRows); //KNDY-11841 KNDY-11877
            if (!proceedWithSave){
                return;
            }
            
            KenandyErp.BlockUI();
            
            headerDateFields = headerDateFields ? _.pluck(headerDateFields, KenandyErp.KendoGridOptions.FieldInfo.Field) : null;
            var dateFields = self.options.dateFields ? _.pluck(self.options.dateFields, KenandyErp.KendoGridOptions.FieldInfo.Field) : null;          
            Visualforce.remoting.Manager.invokeAction(
                SupplierInvoiceManageUtil.HeaderSaveActions[actionType],
                headerRows[0], 
                headerDateFields,           
                updatedRows,
                newRows,
                deletedRows,
                dateFields,
                hasHeaderPOChanged,
                function (result, event) {
                    KenandyErp.UnBlockUI();
                    
                    if (event.type == 'exception') {
                        KenandyErp.Message(event.message);
                    } else {
                    KenandyErp.CleanNamespace(result.records, NamespaceUU);
                        
                        if (result.success) {
                            if ($(e.target.parentElement).hasClass('save-return-command')) {
                                KenandyErp.back(true, '/'+result.records[0].Id);
                            }
                            else if ($(e.target.parentElement).hasClass('save-new-command')) {
                           KenandyErp.NavigateToURL(pageURI,true);
                            }
                            else if (isNewSupplierInvoice && $(e.target).hasClass('save-command')){
                                //var uri = URI('{!$CurrentPage.URL}');
                                var uri = URI(window.location.href);
                                    if (uri.hasQuery("clone", "1") === false){ // not creating a clone
                                        if (window.location.href.indexOf('?') != -1) {
                                            KenandyErp.NavigateToURL(pageURI+'?id=' + result.records[0].Id + '&',true);

                                        }
                                        else {
                                            KenandyErp.NavigateToURL(pageURI+'?id=' + result.records[0].Id + '&',true);

                                        }
                                    }
                                    else{ // created a clone
                                    KenandyErp.NavigateToURL(pageURI+'?id=' + result.records[0].Id + '&',true);
                                    }
                                }
                            // Full page refresh 
                            else if ($(e.target.parentElement).hasClass('save-inspect-command')){
                                console.log(hasTax);
                                if(hasTax == 'true'){ //KNDY-18475
                                    if(isNewSupplierInvoice){
                                        SupplierInvoiceManageUtil.ExecuteAction('Tax',result.records[0].Id);
                                    }else{
                                        SupplierInvoiceManageUtil.ExecuteAction('Tax');
                                    }
                                }else{
                                    KenandyErp.NavigateToURL(pageURI+'?id=' + result.records[0].Id + '&',true);
                                }
                            }
                            else {
                                // refresh widgets
                                var id = (result.records && result.records[0].Id) ? result.records[0].Id : null;
                                var invoiceType = (result.records && result.records[0].Invoice_Type__c) ? result.records[0].Invoice_Type__c : null;
                                            
                                // update defaultPurchaseOrderId
                                $('#defaultPurchaseOrderId').val(SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Purchase_Order__c'));
                                SupplierInvoiceManageUtil.SupplierInvoiceId = id;
                                SupplierInvoiceManageUtil.InvoiceType = invoiceType;
                                SupplierInvoiceUtility.ResetDirtyFlags();// KNDY-7636
                                SupplierInvoiceManageUtil.RenderWidgets();
                                KenandyErp.Messages(result.messages);
                            }
                        }
                        else {
                            // hilite rows with invalid segment validations
                            var invalidRowGuids = result.records;
                            
                            if (invalidRowGuids) {
                                grid.tbody.find("tr").removeClass("kndy-error");
                                
                                for (var guid in invalidRowGuids) {
                                    grid.tbody.find("tr[data-uid='" + invalidRowGuids[guid] + "']").addClass("kndy-error");
                                }
                            }
                            
                            KenandyErp.Messages(result.messages);
                        }
                    }
                },
                {escape: false}
            );
        },
            
        <!----Functions related to Supplier Invoice header Ends ----->
                
        <!---- Supplier Invoice Lines grid related functions starts here ---->
        
        // On Change of item on the SIL grid, the basic SI line info populates.
        OnItemChange: function(e) {
            
            var self = this;
            var grid = this.grid;
            var messageElement = grid.element.closest("div.grid-container").find("div.grid-message");
            var cell = grid.editable.element;
            var row = $(e.target).closest("tr"); //get the row
            var dataItem = grid.dataItem(row); // get the row data
            var itemName= dataItem.get('invoiceLine.Item__r.Name');
            var itemId = dataItem.get('invoiceLine.Item__c');
            // var itemSource = dataItem.get('invoiceLine.Item__r.Source__c');
            var companyId = SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Company__c'); 
            
            if (!itemId) {
                return;
            }
            
            KenandyErp.BlockUI(grid.element);
            Visualforce.remoting.Manager.invokeAction(
                (nspace?nspace +'.':'') +'KSE.getItemJSONRecord',
                itemName, companyId, null, null,
                function (result, event) {
                    KenandyErp.UnBlockUI(grid.element);
                    
                    if (event.type == 'exception') {
                        KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
                    } else {
                        KenandyErp.CleanNamespace(result, NamespaceUU); 
                        if (result) {
                            var item = result;   
                            dataItem.set('invoiceLine.Description__c', item.Description__c);
                            dataItem.set('invoiceLine.Item__r', item); 
                            dataItem.set('invoiceLine.Item__r.Source__c', item.Source__c); 
                            grid.refresh();
                        }
                    }
                },
                {escape: false}  
            ); 
        },     
            
            // This method validates the segments on the Supplier Invoice Lines grid.
            IsValidSegments: function(grid) {
                var fieldList = SupplierInvoiceManageUtil.SupplierInvoiceLinesFieldList;
                var referenceFields = KenandyErp.KendoGridOptions.GetReferenceFields(fieldList); // get the list of reference fields
                var currentData = grid.dataSource.data();
                var messages = [];
                
                grid.tbody.find("tr").removeClass("kndy-error");
                
                $.each(currentData, function(index, item) {
                    var invalidFields = [];
                    
                    for (var i = 0; i < referenceFields.length; i++) {
                        var fieldName = referenceFields[i];
                        var referenceFieldName = fieldName;
                        
                        if (referenceFieldName.endsWith('__c')) {
                            referenceFieldName = referenceFieldName.replace(/__c/, '__r');
                        } else if (referenceFieldName.toLowerCase().endsWith('id')) {
                            referenceFieldName = referenceFieldName.substring(referenceFieldName, referenceFieldName.length - 2);
                        }
                        
                        if (!item.get(fieldName) && item.get(referenceFieldName + '.Name')) {
                            var fieldInfo = _.where(fieldList, { field: fieldName });
                            var fieldTitle = (fieldInfo.length > 0) ? fieldInfo[0].title : '';
                            
                            invalidFields.push(fieldTitle);
                        }
                    }
                    
                    if (invalidFields.length > 0) {
                        grid.tbody.find("tr[data-uid='" + item.uid + "']").addClass("kndy-error");
                        messages.push({ message: 'Invalid ' + invalidFields.join(', ') + '. Please correct the highlighted line(s).', severity: KenandyErp.MessageType.Error });
                    }
                });
                
                if (messages.length > 0) {
                    KenandyErp.Messages(messages);
                    return false;
                }
                
                return true;
            },
                
                
                GetLineTotal: function() {
                    return (SupplierInvoiceManageUtil.InvoiceLinesGrid && SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource.total() > 0) ? SupplierInvoiceManageUtil.InvoiceLinesGrid.dataSource.aggregates().invoicedAmount.sum : 0;
                },
                    
                SetLineTotal: function() {
                        var headerAmount = (SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data && SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Invoice_Amount__c')) ? SupplierInvoiceManageUtil.InvoiceHeaderDetailList.data.get('Invoice_Amount__c') : 0;
                        var linesAmount = SupplierInvoiceUtility.GetLineTotal();                    
                        
                        if (headerAmount.round(2) == linesAmount.round(2)) {
                            $('.line-total').removeClass('text-red');
                            $('.line-total').addClass('text-green');
                        }
                        else {
                            $('.line-total').removeClass('text-green');
                            $('.line-total').addClass('text-red');
                        }
                        
                        $('.line-total').val(kendo.toString(linesAmount, 'n2'));
                },
                        
                <!---  Common methods used across methods --->
                // checks if the page is dirty or any chnages being made on the page.
                IsPageDirty: function(){// KNDY-7636
                    var gridUtils_InvLines = new KendoGridUtils(SupplierInvoiceManageUtil.InvoiceLinesGrid);                    
                    if (SupplierInvoiceManageUtil.isDirtyInvoiceHeaderData || gridUtils_InvLines.HasChanges() ){
                        return true;
                    }
                    else{
                        return false;
                    }
                },
                // Reset the dirty flag
                ResetDirtyFlags: function() { // KNDY-7636
                    SupplierInvoiceManageUtil.isDirtyInvoiceHeaderData = false;
                }
		};
}();
