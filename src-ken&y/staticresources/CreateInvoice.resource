var lstTypeToFulfillments 				= [];                       // variable to store typeToFulfillments which is passed to createInvoice method to create invoices.
var lstProcess 							= [];					   // variable to store the record of process custom setting
var index 								= 0;					  // variable to store the current index's function executing which is mentioned in lstProcess.
var record;											 		     // variable to store current record in context.
var lstrecords                          = [];                   // variable to store the selected fulfillment records   
var lstIgr                              = [];                  // variable to store the IGR from the grouping criteria
var fromProcessFulFilment               = false;              // variable used to by pass the setting of source document on the FinalizedInvoices Method
			    
var GenerateInvoiceUtil = function () {
    return{
    	validate: function(){
    		console.log('validate');
    		console.log(recId);
    		console.log(objectName);
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		var deferred = $.Deferred();
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.validate',
			recId,
			objectName,
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
				}else{
					if(result.success == true){	
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.Messages(result.messages, messageElement);
						record = result.records[0];
						console.log(record);
						$("#confirm").hide();
						KenandyErp.UnBlockUI();
						deferred.resolve(result, event);
					}else{
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.Messages(result.messages, messageElement);
						$("#next").hide();
						$("#confirm").hide();
						KenandyErp.UnBlockUI();
					}
				}
			},
			{escape: false}
	    	);
			return deferred.promise();
    	},
    					
    	validateIGR: function(lstrecords,lstIgr,callback) {
                
             console.log('Inside the method validateIGR');  
             KenandyErp.BlockUI();
             $("#useIGR").prop("disabled", true);
             $("#specifyIGR").prop("disabled", true);  
             var deferred = $.Deferred();
             var detailList = $('#groupingRuleCheckbox').data('kendoDetailList');
             var grid = $('#invoiceHoldGrid').data('kendoGridActionList');
             var columns = grid.columns;
             var messageElementInfo = $("#warningMessagePopUp").data("kendoWindow").element.find(".grid-message-info");
             var gridUtils = new KendoGridUtils(grid);
             var igrList = [];
             var igr = [];
             var selectedRows = gridUtils.SelectedRows();
             var allRows;
             var updatedRows = [];
             var currentData = grid.dataSource.data();
             
             igrList.push(detailList.data);
                igr = $.map(igrList, function(item, index) {
                item = item.toJSON();
                return item;
             }); 
            
             if (igr.length > 0) {
                igr = Serializer.ParameterMap(igr);
             }
             
             if(JSON.stringify(detailList.data)=='{}'){                 
                KenandyErp.Message("Please select any value in Group By Customer Hierarchy", KenandyErp.MessageType.Error, messageElementInfo);
                return;
             }
             
             $.each(currentData, function(index, item) {
                if(item.IsSelected__custom == true) {
                    item = item.toJSON();
                    // Remove the extra attributes Kendo Grid creates for supporting wrapper classes  
                    for (var i = 0; i < columns.length; i++) {
                       var name = columns[i].field;
                       if (name && name.indexOf('.') != -1) {
                           delete item[name];
                       }
                   }
                   updatedRows.push(item);
                }
            });
               
            if (updatedRows.length > 0) {
               allRows = Serializer.ParameterMap(updatedRows);  
            }
            KenandyErp.BlockUI();
            Visualforce.remoting.Manager.invokeAction(
                 (nspace?nspace +'.':'') + 'OnDemandInvoiceGenerateExt.validateIGR',
                 igr[0],
                 function (result, event) {
                    if (event.type == 'exception') {
                        KenandyErp.UnBlockUI();
                        KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElementInfo);
                    } else {
                         if(result.success){
                            console.log('in the success of validateIGR');
                            lstrecords = allRows;
                            lstIgr = igr;
                            callback(null,lstrecords,lstIgr);
                        }else{
                            KenandyErp.UnBlockUI();
                            console.log('error-'+result.messages);
                            KenandyErp.Messages(result.messages, messageElementInfo);
                        }
                    }
                 },
            {escape: false}
           );
          return deferred.promise();
        },
        
        
         ConfirmGenerateInvoice: function(e) {
            var self = this;
            var grid = $('#invoiceHoldGrid').data('kendoGridActionList');
            var columns = grid.columns;
            var detailList = $('#groupingRuleCheckbox').data('kendoDetailList');
            var igrList = [];
            var igr = [];
            var messageElement = grid.element.closest("div.grid-container").find("div.grid-message:first");
            var gridUtils = new KendoGridUtils(grid);
            var selectedRows = gridUtils.SelectedRows();
            selectedRows = Serializer.ParameterMap(selectedRows);
            var updatedRows = [];
           
            var currentData = grid.dataSource.data();
            igrList.push(detailList.data);
            igr = $.map(igrList, function(item, index) {
                item = item.toJSON();
                return item;
            });
            
            if (igr.length > 0) {
                igr = Serializer.ParameterMap(igr);
            }
             $.each(currentData, function(index, item) {
                    if(item.IsSelected__custom == true) {
                        item = item.toJSON();
                        // Remove the extra attributes Kendo Grid creates for supporting wrapper classes
                        for (var i = 0; i < columns.length; i++) {
                            var name = columns[i].field;
                            if (name && name.indexOf('.') != -1) {
                                delete item[name];
                            }
                        }
                        updatedRows.push(item);
                    }
                     
            });
            updatedRows = Serializer.ParameterMap(updatedRows);
            KenandyErp.BlockUI(grid.element);
            var finalResult = GenerateInvoiceUtil.waterfall();
            console.log('finalResult--->'+finalResult);
        },
        
	    waterfall: function(){
			console.log('waterfall');
			if(lstTypeToFulfillments.length>0){
	    		var lstMethods = [];
	    		lstMethods.push(GenerateInvoiceUtil.CreateInvoice);
	    		lstMethods.push(GenerateInvoiceUtil.PreFinalizeActions);
	    		if(lstProcess.length>0){
	    			$.each(lstProcess, function(index, element){
						lstMethods.push(GenerateInvoiceUtil.CallUserDefinedMethod);
					});
				}
				lstMethods.push(GenerateInvoiceUtil.FinalizeInvoices);
				lstMethods.push(GenerateInvoiceUtil.AutoApplyPrepayments); 
				async.waterfall(lstMethods, function (err, result) {
					console.log(err);
                    console.log('wfresult---->'+result);
                    GenerateInvoiceUtil.processResult(fromProcessFulFilment, result);
                }); 
            }
        },
        
        processResult: function(flag,result,showmessageElement){
         if(flag){
            var grid = $('#invoiceHoldGrid').data('kendoGridActionList');
            var arrayResultsError=[];
            var arrayResultsSuccess=[];
            var messageElementError = grid.element.closest("div.grid-container").find("div.grid-message-error");
            var messageElement = $('.grid-message-Warning');
            if (result != null) {    
                $.each(result.messages, function(index,item) {
                    $.each(item, function(key,value){
                        if(key=='severity'){
                            if(value=='ERROR'){
                                arrayResultsError.push(item);
                            }else{
                                arrayResultsSuccess.push(item);
                            }
                         }
                     });
				 });	
             }   
            if(arrayResultsSuccess.length>0){ 
                KenandyErp.Messages(arrayResultsSuccess, messageElement);
            }
            
            if(arrayResultsError.length>0){
                KenandyErp.Messages(arrayResultsError, showmessageElement);
            }
            
            if(arrayResultsError.length <= 0){                              
                var window = $("#warningMessagePopUp").data("kendoWindow");
                window.close();
            }

            if(arrayResultsSuccess.length>0){
               $('#invoiceHoldGrid').data('kendoGridActionList').dataSource.read();
               $('#releaseHoldGrid').data('kendoGridActionList').dataSource.read();
            }
            KenandyErp.UnBlockUI(grid.element);
	      }
	    },
    					    
    	next: function(){
    		console.log('next');
    		console.log(recId);
    		console.log(record);
    		$("#useIGR").prop("disabled", true);
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		var deferred = $.Deferred();
    		Visualforce.remoting.Manager.invokeAction(
    		(nspace?nspace +'.':'') +className+'.next', 
			$("#useIGR").prop('checked'),
			recId,
			record,
			function (result, event) {
				if(event.type == 'exception') {
					KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
				}else{
					if(result.success == true){
						KenandyErp.ClearMessage(messageElement);
						KenandyErp.BlockUI();	
						lstTypeToFulfillments = result.records;
						console.log(lstTypeToFulfillments);
						deferred.resolve(result, event);
					}else if(result.success == null){
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.Messages(result.messages, messageElement);
						lstTypeToFulfillments = result.records; 
						//enable confirm button for user to create multiple invoices.
						$("#next").hide();
						$("#confirm").show();
						KenandyErp.UnBlockUI();
					}else{
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.Messages(result.messages, messageElement);
						KenandyErp.UnBlockUI();
					}
				}
			},
			{escape: false}
		   );
		   return deferred.promise();
    	},
    					
    	nextOnProcessFulfillment: function(lstrecords,lstIgr,callback){  
    	   
            console.log('nextOnProcessFulfillment');
            console.log(lstrecords);
            console.log(lstIgr);
            console.log($("#useIGR").prop('checked'));
            $("#useIGR").prop("disabled", true);
            $("#specifyIGR").prop("disabled", true);
            var messageElement = $('.grid-message-Warning'); 
            var popupmessageelement = $("#warningMessagePopUp").data("kendoWindow").element.find(".grid-message-info");
            KenandyErp.BlockUI();
            fromProcessFulFilment = true;
            var deferred = $.Deferred();
                Visualforce.remoting.Manager.invokeAction(
                (nspace?nspace +'.':'') +className+'.nextOnProcessFulfillment',   
                $("#useIGR").prop('checked'),
                lstrecords,
                lstIgr,
            function (result, event) {
                if(event.type == 'exception') {
                    KenandyErp.Message(event.message, messageElement);
                    KenandyErp.UnBlockUI();
                    $("#next").hide();
                }else{
                    if(result.success == true){
                        KenandyErp.ClearMessage(messageElement);
                        KenandyErp.BlockUI();   
                        lstTypeToFulfillments = result.records;
                        console.log(lstTypeToFulfillments);
                        callback(null,lstTypeToFulfillments);
                        deferred.resolve(result, event);
                        console.log('result--->'+result);
                        var finalResult = GenerateInvoiceUtil.waterfall();
                        console.log('finalResult--->'+finalResult);
                    }else if(result.success == null){
                        KenandyErp.ClearMessage(messageElement); 
                        KenandyErp.Messages(result.messages, messageElement);
                        lstTypeToFulfillments = result.records; 
                        var kwindow = $("#warningMessagePopUp").data("kendoWindow");
                        kwindow.center();
                        KenandyErp.Messages(result.messages, messageElement);
                        kwindow.open();
                        $("#confirmBlock").show();
                        $("#btnconfirm").show();
                        $("#cbBlock").hide();
                        KenandyErp.UnBlockUI();
                    }else{
                        KenandyErp.ClearMessage(messageElement); 
                         $("#useIGR").prop("disabled", false);
                         $("#specifyIGR").prop("disabled", false);   
                        GenerateInvoiceUtil.processResult(fromProcessFulFilment, result,popupmessageelement);
                        KenandyErp.UnBlockUI();
                    }
                }
            },
            {escape: false}
            );
            return deferred.promise();
        },
        
    	CreateInvoice: function(callback){
    		console.log('CreateInvoice');
    		console.log(lstTypeToFulfillments);
            $.each(lstTypeToFulfillments, function(index, item) { 
            	 $.each(item.igrFl, function(index1, item1){
            	 	console.log(item1.recurrenceStartDateTime);
            	 	if(item1.recurrenceStartDateTime){
	            	 	var value = moment.utc(item1.recurrenceStartDateTime).local();
	            	 	console.log(value);
	            	 	eval("item1.recurrenceStartDateTime" + " = value");
	            	}
            	 });
            });
    		var messageElement = document.getElementById("message");
    		var errElement = document.getElementById("err");
    		KenandyErp.BlockUI();
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.createInvoice',
			JSON.stringify(lstTypeToFulfillments),
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
					callback(event);
				}else{
					if(result.success == true){
						KenandyErp.BlockUI();
						if(className == 'AgreementGenerateInvoiceExt'){
							displayMsg(result.messages);              // to display the error message on agreement main page with fulfillments if any 
						}else{
							KenandyErp.ClearMessage(errElement);
							KenandyErp.Messages(result.messages, errElement);
							KenandyErp.ClearMessage(messageElement);	
						}
						console.log(result.records);
						callback(null, result.records);
					}else{
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.ClearMessage(errElement);
						KenandyErp.Messages(result.messages,messageElement);
						KenandyErp.UnBlockUI();
						$("#next").hide();
						$("#confirm").hide();
						callback(event);
					}
				}
			},
			{escape: false}
			);
    	},
    					
    	PreFinalizeActions: function(lstCustomerInvoice,callback){
    		console.log('PreFinalizeActions');
    		console.log(lstCustomerInvoice);
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.prefinalizeActions',
			lstCustomerInvoice,
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
					callback(event);
				}else{
					if(result.success == true){
						KenandyErp.BlockUI();
						if(result.messages != ''){
							if(className == 'AgreementGenerateInvoiceExt'){
								displayMsg(result.messages);              // to display the error message on agreement main page 
							}else{
								KenandyErp.Messages(result.messages,messageElement);
							}
						}	
						if(result.records != undefined){ 
							lstCustomerInvoice = result.records;
							console.log(lstCustomerInvoice);
							callback(null, lstCustomerInvoice);
						}else{
							callback(event);
						}
					}else if(result.success == null){
						lstCustomerInvoice = result.records;
						console.log(lstCustomerInvoice);
						callback(null, lstCustomerInvoice);
					}else{ 
						if(className == 'AgreementGenerateInvoiceExt'){
							displayMsg(result.messages);              // to display the error message on agreement main page
							var win = window.parent.$("#generateInvoicewindow").data("kendoWindow");
							closeAgreementWindow(win);
						}else{
							KenandyErp.Messages(result.messages,messageElement);
						}
						KenandyErp.UnBlockUI();
						$("#next").hide();
						$("#confirm").hide();
						callback(event);
					}
				}
			},
			{escape: false}
			);
    	},
    					
    	FinalizeInvoices: function(lstCustomerInvoice,callback){
    		console.log('FinalizeInvoices');
    		console.log(lstCustomerInvoice);
    		if(fromProcessFulFilment)
    		  recId = null;
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.finalizeInvoices',
			recId,
			fromProcessFulFilment,
			lstCustomerInvoice,
			objectName,
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
					callback(event);
				}else{
					if(result.success == true){
						KenandyErp.BlockUI();	 
						lstCustomerInvoice = result.records;
						console.log(lstCustomerInvoice);
						callback(null, lstCustomerInvoice);
					}else{
						KenandyErp.Messages(result.messages,messageElement);
						KenandyErp.UnBlockUI();
						$("#next").hide();
						$("#confirm").hide();
						callback(event);
					}	
				}
			},
			{escape: false}
			);
    	},
    					
    	AutoApplyPrepayments: function(lstCustomerInvoice,callback){
    		console.log('AutoApplyPrepayments');
    		console.log(lstCustomerInvoice);
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		var deferred = $.Deferred();
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.autoApplyPrepayments',
			lstCustomerInvoice,
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
					callback(event);
				}
				else{
					if(className == 'AgreementGenerateInvoiceExt'){
						displayMsg(result.messages);              // to display the success/error message on agreement main page with invoices 
						var win = window.parent.$("#generateInvoicewindow").data("kendoWindow");
						closeAgreementWindow(win);
					}else{
						KenandyErp.Messages(result.messages,messageElement);
					}
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
					callback(null,result);	
				}
			},
			{escape: false}
			);
    	},
    					
    	GetValues: function(callback){
    		console.log('GetValues');
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		var deferred = $.Deferred();
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.getValues',
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
				}else{
					if(result.success == true){
						KenandyErp.BlockUI();
						console.log(result.records);
						lstProcess = result.records;
					}else if(result.success == null){
						    		
					}else{
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.Messages(result.messages,messageElement);
						$("#next").hide();
						$("#confirm").hide();	
					}
					KenandyErp.UnBlockUI();	
					deferred.resolve(result, event);
				}
				callback(null,lstrecords,lstIgr);
			},
			{escape: false}
			);
			return deferred.promise();
    	},
    					
    	CallUserDefinedMethod: function(lstCustomerInvoice,callback){
    		console.log('CallUserDefinedMethod');
    		console.log(lstCustomerInvoice);
    		var messageElement = document.getElementById("message");
    		KenandyErp.BlockUI();
    		var process = lstProcess[index];
    		console.log(process);
    		Visualforce.remoting.Manager.invokeAction(
			(nspace?nspace +'.':'') +className+'.callUserDefinedMethod',
			process,
			lstCustomerInvoice,
			function (result, event) {
				if(event.type == 'exception') {
				    KenandyErp.Message(event.message, messageElement);
					KenandyErp.UnBlockUI();
					$("#next").hide();
					$("#confirm").hide();
					callback(event);
				}else{
					if(result.success == true){
						if(result.records != undefined){
							lstCustomerInvoice = result.records;
							console.log(lstCustomerInvoice);
							index = index + 1;
							console.log(index);
							callback(null, lstCustomerInvoice);
						}else{
							KenandyErp.ClearMessage(messageElement); 
							KenandyErp.Messages(result.messages,messageElement);
							KenandyErp.UnBlockUI();
							$("#next").hide();
							$("#confirm").hide();
							callback(event);
						}
					}else{
						KenandyErp.ClearMessage(messageElement); 
						KenandyErp.Messages(result.messages,messageElement);
						KenandyErp.UnBlockUI();
						$("#next").hide();
						$("#confirm").hide();
						callback(event);
					}
				}
			},
			{escape: false}
			);
    	}  						
    }
}();

function closeAgreementWindow(win){
	if(win){
		win.close();
	}
}

function displayMsg(Msg){
	KenandyErp.Messages(Msg, window.parent.$('.page-message')); 
}