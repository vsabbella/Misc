// returns the search box value
function getSearchVal () {
    return $(vfPageData.gridContainerSelector).find('.grid-search-command').val();
} 

/*
    returns kendo date picker value bound by a given selector
*/
function datePickerValue(dpSelector) {
    var dp = $(dpSelector);
    
    if (dp.data('kendoDatePicker')) {
        return dp.data('kendoDatePicker').value();
    } else {
        return dp.data('kendoKndyDatePicker').value();
    }
}

// returns the search box value
function getSearchVal () {
    return $(vfPageData.gridContainerSelector).find('.grid-search-command').val();
}   

// Gives handle to the grid object
function getKendoGridObject() {
    return $(vfPageData.gridContainerSelector).data("kendoGrid");
}

function getCurrentGridData(pbGrid) {
    var searchVal = getSearchVal();
    var currentData; // searched data or whole grid data 
    if (searchVal) {
        currentData = pbGrid.dataSource.view();
    } else {                    
        currentData = pbGrid.dataSource.data();
    }   
    return currentData;
}

function onActivateAll(elem) {
    var gridKendo = getKendoGridObject();
    var currentData = getCurrentGridData(gridKendo);                        
    var state = $(elem).is(':checked');
    $.each(currentData, function () {
        if (this.sobj.Active__c != state) 
            this.dirty=true;
        this.sobj.Active__c = state;
    });
    gridKendo.refresh();
}

function toTimeInMillis(mydate) {
    if (!mydate)
        return 0;
    return mydate.getTime();
}

function createFilterInfo() {

    var fromDate =KenandyErp.ParseSFDCDate(datePickerValue('#fromDateFilter')).getTime() ;
    var toDate = KenandyErp.ParseSFDCDate(datePickerValue('#toDateFilter')).getTime();
    var histFromDate = KenandyErp.ParseSFDCDate(datePickerValue('#histFromDateFilter')).getTime();
    var histToDate = KenandyErp.ParseSFDCDate(datePickerValue('#histToDateFilter')).getTime();
    var productId = $('#productFilter').val();
    if (!productId) {
        productId = $('#productDescFilter').val();
    }
    productId = productId && productId.length > 0 ? productId : null;

    var ruleTypeVal = $("input[type='radio'][name='ruleType']:checked").val();

    var quantityToAllocate = $('#qtyToAllocate').val();
    return {
        productId : productId,
        companyId : vfPageData.currentCompanyId,
        ruleType : ruleTypeVal,
        suggestedName : $('#nameSuggestion').val(),
        fromDateMillis : fromDate,
        toDateMillis : toDate,
        histFromDateMillis : histFromDate,
		histToDateMillis : histToDate,
        quantityToAllocate : quantityToAllocate,
        showWarningsForExistingRules :  vfPageData.showWarningsForExistingRules
    };
}

function onGridAddRule() {

    var grid = this.grid;
    var filterInfo = createFilterInfo();
    
    Visualforce.remoting.Manager.invokeAction(vfPageData.remoteActionNewRule, filterInfo, function(result, event) {
    
        //result.fromDateTime = new Date(result.fromDateTime);
        //result.toDateTime = new Date(result.toDateTime);
       // result.histToDateTime = new Date(result.histToDateTime);
       // result.histFromDateTime = new Date(result.histFromDateTime);
        
        result.fromDateTime = tzFix(result.fromDateTime);
        result.toDateTime = tzFix(result.toDateTime);
        result.histToDateTime = tzFix(result.histToDateTime);
        result.histFromDateTime =  tzFix(result.histFromDateTime);    
        
        grid.dataSource.insert(0, result);
        grid.editRow(grid.tbody.children().first());
    });
}

function tzFix(input) {
	return moment(input).add('minutes', moment(input).tz(KenandyErp.TimeZone).zone()).toDate();
	//return new Date(input).toUTCString();
}

(function($) {
    // Small extension of Kendo Date Picker to use Culture transparently, plus additional attribute to adjust dates
    var kndyDatePicker = kendo.ui.DatePicker.extend({

        init: function(element, options) {
            options = options || {};
            
            var offsetInDays = $(element).data('dayoffset');
            if (offsetInDays) {
                var currentDate = new Date();
                var millisecondOffset = offsetInDays * 24 * 60 * 60 * 1000;
                currentDate.setTime(currentDate.getTime() + millisecondOffset); 
                options.value = currentDate;
            }
            
            options.culture = KenandyErp.Culture;
            options.format = KenandyErp.DateFormat;
            
            kendo.ui.DatePicker.fn.init.call(this, element, options);
            
        },

        options: {    
            name: "KndyDatePicker",
            dayoffset : 0
        }

    });

    kendo.ui.plugin(kndyDatePicker);

})(jQuery);

(function($) {

    function allocationRuleGrid(selector, options) {
        var fieldList = options.fieldList;
        var buttons = $.map(options.buttons.split(','), $.trim);
        var namespace = options.namespacePrefix;
        var lookupSearchAction = options.lookupSearchAction;
        var dataSourceReadCallback = options.dataSourceReadCallback;
        var dataSourceSaveCallback = options.dataSourceSaveCallback;
        var aggregates = [{ field: "sobj.Allocation__c", aggregate: "sum" }];
        // get the list of reference fields
        var referenceFields = KenandyErp.KendoGridOptions.GetReferenceFields(fieldList);  
        var dateFields = KenandyErp.KendoGridOptions.GetDateFields(fieldList); 
        var lookupSearchFilters = (options.lookupSearchFilters) ? options.lookupSearchFilters : [];
        
        var getModel = function() {
            var fields = KenandyErp.KendoGridOptions.GetFields(fieldList);

            var model = kendo.data.Model.define({
                id : "sobj.Id",
                fields : fields
            });

            return model;
        };

        var getColumns = function() {
            var rowStatusColumnTemplate = kendo.template('<div style="background-color:#=sobj.Id ? \"inherit\" : \"blue\"#">&nbsp;</div>');
            var rowStatusColumn = {
                title : " ",
                width : 16,
                attributes : {
                    class : "rowStatusCol"
                },
                template : function(item) {
                    return rowStatusColumnTemplate(item);
                }
            };
          
            var cols = KenandyErp.KendoGridOptions.GetColumns(fieldList, {
                lookupSearchAction : vfPageData.remoteActionLookupSearchFilter,
                buttons : buttons,
                lookupSearchFilters : lookupSearchFilters
            });
            _.each(cols, function (fld, idx, lst) {
                if (fld.field == "sobj.Active__c") {
                    fld.headerTemplate = '<input type="checkbox" id="check-all" onclick="return onActivateAll(this);"/>';
                }
                
                if (fld.field == "sobj.Allocation__c") {
                    fld.aggregates = ["sum"];
                    fld.footerTemplate = function(data) {
                        var totalAllocations = 0;
                        if (data && data['sobj.Allocation__c']) {
                            totalAllocations = data["sobj.Allocation__c"].sum;

                        }

                        return '<div id="totalAllocations">Total: ' + Math.floor(totalAllocations) + '</div>';
                    };
                }
            });
            cols.unshift(rowStatusColumn);
            return cols;
        };

        var getToolbarButtons = function() {
            return KenandyErp.KendoGridOptions.GetToolbarButtons(buttons);
        };

        var getDataSource = function() {
            var dataSource = new kendo.data.DataSource({
                transport : {
                    read : function(options) {
                        KenandyErp.BlockUI(selector);

                        var promise = dataSourceReadCallback();
                        promise.done(function(result, event) { 
                            KenandyErp.UnBlockUI(selector);

                            if (event.type == 'exception') {
                                KenandyErp.Alert("An error occurred while processing your request. Please contact support");
                            } else {
                                KenandyErp.CleanNamespace(result, namespace);
                                if (result.messages) {
                                    KenandyErp.Messages (result.messages, '.grid-message');
                                }
                                options.success(result.records);
                            }
                        });
                    }
                },
                batch : true,
                pageSize : KenandyErp.KendoGridOptions.DefaultPageSize,
                schema: {
                    model: getModel(),
                    parse:function (response) {
                        $.each(response, function (idx, item) {
                        
                            item = Serializer.ConvertFromSFDCDate(item, { dateFields: dateFields });
                        });
                        
                        return response;
                    }
                },
                aggregate: aggregates 
            });

            return dataSource;
        };

        var grid = $(selector).kendoGrid({
            dataSource : getDataSource(),
            navigatable : true,
            pageable : {
                input : true,
                numeric : false,
                pageSizes : KenandyErp.KendoGridOptions.PageSizes
            },
            toolbar : getToolbarButtons(),
            columns : getColumns(),
            sortable : true,
            filterable : true,
            resizable : true,
            editable : true,
            edit :  function (e) {
                $.proxy(KenandyErp.KendoGridActions.Edit, {
                    referenceFields : referenceFields
                });
                
                if (e.model.readOnly) {
                    if ($(this.current().context).find('input[name$=Allocation__c]').length > 0) {
                        // skip allocation cell and keep it open for changes, rest of them will be readonly        
                    } else {
                        this.closeCell();
                    }
                } 
            }
        }).data('kendoGrid');

        // bind click events to the custom buttons
        KenandyErp.KendoGridOptions.BindEvents(grid, buttons, {
            referenceFields : referenceFields,
            hookPreSave : options.hookPreSave,
            config : {},
            dateFields: dateFields ,
            ignoreBindings: [ KenandyErp.KendoGridOptions.CommandType.Save ]
        });
        
        grid.wrapper.on("click", ".grid-save-command", $.proxy(saveAllocationRules, { grid: grid, options: { saveAction: dataSourceSaveCallback, dateFields: dateFields } }));
        
        grid.dataSource.bind('change', function() {
            var totalAllocations=0;
            $.each(this.data(), function(index, model) {
                if (model.get('sobj.Active__c')){
                    totalAllocations += Math.floor(model.get('sobj.Allocation__c'));
                }
        });
            //var totalAllocations = this.aggregates()['sobj.Allocation__c'].sum;
        
            $('#totalAllocations').html('Total: ' + totalAllocations)
        });
        
        return grid;
    }
    ; // allocationRuleGrid
    
    
    
    function onApplyFilterButtonClick(e) {
        // make sure this is enabled to get warning messages back
        vfPageData.showWarningsForExistingRules = true;
        
        // Clear existing messages
        $('grid-message').html('');
        // Validate current inputs
        var hasValidComboValue = function(comboSelector) {
            var combo = $(comboSelector).data('kendoComboBox');
            return combo.value() && combo.text() != combo.value();
        }

        var fromDate = KenandyErp.ParseSFDCDate(datePickerValue('#fromDateFilter'));
        var toDate = KenandyErp.ParseSFDCDate(datePickerValue('#toDateFilter'));
        var histFromDate = KenandyErp.ParseSFDCDate(datePickerValue('#histFromDateFilter'));
        var histToDate = KenandyErp.ParseSFDCDate(datePickerValue('#histToDateFilter'));

        if (fromDate > toDate) {
            alert('Rule from date is greater than to date');
            return false;
        }
        
        if (histFromDate > histToDate) {
            alert('History from date is greater than to date');
            return false;
        }
        
        if (histFromDate > fromDate) {
            alert('History from date is greater than rule from date');
            return false;
        }
        
        if (histToDate > fromDate) {
            alert('History to date is greater than rule from date');
            return false;
        }
        
        if ( (histFromDate == 0 && histToDate > 0) ||
             (histFromDate > 0 && histToDate == 0)){
            // both from and to dates are needed not one
            alert('Either both history from and to dates are needed, or none !');
            return false;
        }
        
        if (!hasValidComboValue('#productFilter') && !hasValidComboValue('#productDescFilter')) {
            alert('No valid product selected');
            return false;
        }
        
        var buttons = 'Add Rule|onGridAddRule,save,delete,cancel,search';
        var ruleTypeVal = $("input[type='radio'][name='ruleType']:checked").val();

        // delete the old grid for new start
        var gridRef = $(vfPageData.gridContainerSelector).data('kendoGrid');
        if (gridRef) {
            // clear memory to avoid leaks by handlers etc
            gridRef.destroy();
            // release all event handlers tied to parent div
            gridRef.wrapper.off();
            // remove the element from DOM as well
            gridRef.element.html('');
            gridRef.element.off();
        }
        
        var lookupSearchFilters = [];
        lookupSearchFilters.push({
            field : "sobj.Customer__c",
            filter : "Company__c = '" + vfPageData.currentCompanyId + "' AND RecordTypeId = '" + vfPageData.corpCustomerRecordTypeId + "'"
        });
        
       
        // render the grid
        gridRef = allocationRuleGrid($(vfPageData.gridContainerSelector), { 
            buttons : buttons,
            fieldList : vfPageData.currentFieldInfos,
            namespacePrefix : vfPageData.namespacePrefix,
            dataSourceReadCallback : loadAllocationRules,
            dataSourceSaveCallback : vfPageData.remoteActionSaveRules,
            lookupSearchFilters : lookupSearchFilters,
            hookPreSave : function(grid, options, rows) {
                // save reloads the data again, so dont show warnings
                vfPageData.showWarningsForExistingRules = false;
                for ( var rIdx in rows) {
                    var r = rows[rIdx];
                    // This is calculated field, not needed again
                    delete r['remainingAllocation'];
                    for ( var prop in r) {
                        if (prop.indexOf('sobj.') != -1) {
                            delete r[prop];
                        }
                    }
                }
            }
        });
        
       // gridRef.element.on('OnSaveSuccess', function(e){ OTC-346
            //Visualforce.remoting.Manager.invokeAction(vfPageData.remoteActionGetBiggestNextSequenceNumber, function(result, event) {
               // $('#sequenceNumber').val(result);
               // generateNameSuggestion();
          //  });
        //});
    }

    function bootKendo() {
        var productFilter = $('#productFilter').kndyRemoteComboBox({
            value : vfPageData.currentProductId,
            text : vfPageData.currentProductName,
            sobject : 'Product__c', // will be sobject to query
            placeholder : 'Type to search...',
            criterias : function() {
                return [ {
                    'field' : 'Company__c',
                    'operator' : '=',
                    'value' : vfPageData.currentCompanyId,
                    'wrapValueInQuotes' : true
                } ];
            }, // map structure with key value combinations
            orderByField : 'Name',
            sortOrder : 'asc',
            remoteActionLoadRecords	: vfPageData.remoteActionLoadRecords
        }).data('kendoComboBox');
        
        var productDescFilter = $('#productDescFilter').kndyRemoteComboBox({
            dataTextField : 'Description__c',
            value : vfPageData.currentProductId,
            text : vfPageData.currentProductDesc,
            sobject : 'Product__c', // will be sobject to query
            placeholder : 'Type to search...',
            criterias : function() {
                return [ {
                    'field' : 'Company__c',
                    'operator' : '=',
                    'value' : vfPageData.currentCompanyId,
                    'wrapValueInQuotes' : true
                } ];
            }, // map structure with key value combinations
            orderByField : 'Name',
            sortOrder : 'asc',
            remoteActionLoadRecords	: vfPageData.remoteActionLoadRecords
        }).data('kendoComboBox');
        
        productFilter.bind("change", function(e){
            productDescFilter.value('');
            productDescFilter.text('');
            
            var sobjInfo = {
                sobjectName : 'Product__c',
                valueFieldName : 'Id',
                textFieldName : 'Description__c',
                recordLimit : 1,
                criterias : [{
                    'field' : 'Id',
                    'operator' : '=',
                    'value' : this.value(),
                    'wrapValueInQuotes' : true
                }]
            };

            // remoteActionLoadRecords to come from caller
            Visualforce.remoting.Manager.invokeAction(vfPageData.remoteActionLoadRecords, sobjInfo, function(result, event) {
                if (event.type == 'exception') {
                    KenandyErp.Alert(event.message);
                } else {
                    if (result[0].Description__c) {
                        productDescFilter.text(result[0].Description__c);
                        productDescFilter.value(result[0].Id);
                    } else {
                        productDescFilter.value('');
                        productDescFilter.text('');
                    }
                }
            }, {
                escape : false
            });
            
        });
        
        productDescFilter.bind("change", function(e){
            productFilter.value('');
            productFilter.text('');
        });
        
        $('#qtyToAllocate').kendoNumericTextBox();
        
        $("#applyFiltersButton").kendoButton({
            click : onApplyFilterButtonClick
        });

        // Initalise any other Kendo widgets, like from and to dates
        kendo.init($('.kendoWidgetSelector'));

        $('input[name=ruleType]').change(function() {
            var radio = $(this);

            // Generate new name
            generateNameSuggestion();

            var ruleTypeVal = radio.val();

            if (ruleTypeVal != vfPageData.types.fb) {
                $('.showInFB').hide();
            } else {
                $('.showInFB').show();
            }
            
            var showQtyToAllocate = ruleTypeVal == vfPageData.types.hfs;
            if (showQtyToAllocate) {
                $('.showInHFS').show();
            } else {
                $('.showInHFS').hide();
            }
            
            // Load new field infos
            Visualforce.remoting.Manager.invokeAction(vfPageData.remoteActionGetFieldInfos, radio.val(), function(result, event) {
                vfPageData.currentFieldInfos = result;
            });
        });
    }

    function generateNameSuggestion() {
        var radio = $("input[type='radio'][name='ruleType']:checked");
        var namePrefix = radio.data('name-prefix');
        var seqNo = $('#sequenceNumber').val();
        $('#nameSuggestion').val(namePrefix ); //+ '-' + seqNo otc-346
    }

    function loadAllocationRules() {
        var deferred = $.Deferred();
        Visualforce.remoting.Manager.invokeAction(vfPageData.remoteActionLoadRules, createFilterInfo(), function(result, event) {
            // always restore the value back
            vfPageData.showWarningsForExistingRules = true;
            deferred.resolve(result, event);
        });

        return deferred.promise();

    }
    
    

    function saveAllocationRules(e) { 
    
        var self = this;
        var grid = self.grid;

        var messageElement = grid.element.closest("div.grid-container").find("div.grid-message");
        var filterInfo = createFilterInfo();
		//alert(self.options.dateFields);
        var gridUtils = new KendoGridUtils(grid, self.options);
   		
   		vfPageData.showWarningsForExistingRules = false;
						
		if (!gridUtils.IsValid()) {
            e.preventDefault();
            return;
        }
	 		
    	if (!gridUtils.HasChanges()) {
    		KenandyErp.Message("No records changed.", KenandyErp.MessageType.Info, messageElement);
    		return;
    	}
        
        //console.log('Allocation Sum: ' + grid.dataSource.aggregates()['sobj.Allocation__c'].sum);
        //console.log('Qty to Allocate: ' + filterInfo.quantityToAllocate);
        if (grid.dataSource.aggregates()['sobj.Allocation__c'] 
        	&& grid.dataSource.aggregates()['sobj.Allocation__c'].sum > filterInfo.quantityToAllocate 
        	&& filterInfo.ruleType == vfPageData.types.hfs
        ) {
            KenandyErp.Message("Too much quantity allocated.", KenandyErp.MessageType.Info, messageElement);
            return;
        }
        
        KenandyErp.BlockUI(grid.element);
                        
        var dateFields ;//= self.options.dateFields ? _.pluck(self.options.dateFields, KenandyErp.KendoGridOptions.FieldInfo.Field) : null;
		var gridForUpdate = gridUtils.UpdatedRows();
		var gridForNew = gridUtils.NewRows();
		var gridForDelete = gridUtils.DeletedRows();
       
        var updatedRows = [];
        var newRows = [];
        var deletedRows = [];
        var columns = grid.columns;
        var selectedSkidIds = [];
		
		//hardcoded.  but they are hardcoded in the wrapper class as well
       var dateFieldNames = ["histFromDateTime", "histToDateTime", "fromDateTime", "toDateTime"];
                    
       //UPDATED ROWS             
       for( var i =0 ; i< gridForUpdate.length; i++) {
       		for (var key in gridForUpdate[i]) {
       			if (dateFieldNames.indexOf(key) != -1) {
       				gridForUpdate[i][key] = new Date(gridForUpdate[i][key]).toUTCString();
       			}
       		}
			 updatedRows.push(gridForUpdate[i]);
       };
       
       //NEW ROWS
       for( var i =0 ; i< gridForNew.length; i++) {
       		for (var key in gridForNew[i]) {
       			if (dateFieldNames.indexOf(key) != -1) {
       				gridForNew[i][key] = new Date(gridForNew[i][key]).toUTCString();
       			}
       		}
			 newRows.push(gridForNew[i]);
       };
       
       //DELETED ROWS
       for( var i =0 ; i< gridForDelete.length; i++) {
       		for (var key in gridForDelete[i]) {
       			if (dateFieldNames.indexOf(key) != -1) {
       				gridForDelete[i][key] = new Date(gridForDelete[i][key]).toUTCString();
       			}
       		}
			 deletedRows.push(gridForDelete[i]);
       };

        //datefields was undefined, causing the remoteaction to fail
        //setting it to empty array as a workaround
        dateFields = [];
        
        Visualforce.remoting.Manager.invokeAction(
	    	self.options.saveAction,			     	        
			updatedRows, //gridUtils.UpdatedRows()
			newRows,
			deletedRows,
			dateFields,
			function (result, event) {
				KenandyErp.UnBlockUI(grid.element);
					    	
				if (event.type == 'exception') {
					KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
				} else {
					if (result.success) {
						//refresh the grid
                		grid.dataSource._destroyed = [];
                		grid.dataSource.read();
									
						KenandyErp.Messages(result.messages, messageElement);
					}
					else {
						KenandyErp.Messages(result.messages, messageElement);
					}
				}
			},
			{escape: false}
		);
   	}

    $(document).on('KenandyErpReady', function(e) {
        bootKendo();
        // Generate a name
        generateNameSuggestion();

        $('#productFilter').focus();
    });

})(jQuery);