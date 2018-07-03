(function ($) {
	$.fn.GridRelatedList = function(selector, options) {
		var config = JSONUtils.Parse(options.config);
        //var fieldList = sanitize(JSONUtils.Parse(options.fieldList)); //TODO: KNDY-9329
        var fieldList = JSONUtils.Parse(options.fieldList);
		var buttons = $.map(config.buttons.split(','), $.trim);
		var namespace = config.namespace ? config.namespace : options.namespace;
		var lookupSearchAction = options.lookupSearchAction;
		var getRelatedListFunction = options.getRelatedListFunction;
		var saveRelatedListAction = options.saveRelatedListAction;
		var referenceFields = KenandyErp.KendoGridOptions.GetReferenceFields(fieldList); // get the list of reference fields
		var dateFields = KenandyErp.KendoGridOptions.GetDateFields(fieldList); // get the list of date fields
		var lookupSearchFilters = (options.lookupSearchFilters) ? options.lookupSearchFilters : [];
		var nestedFields = KenandyErp.KendoGridOptions.GetNestedFields(fieldList); // get the list of nested fields
		var modelIdField = options.modelIdField ? options.modelIdField : 'Id';
		
		if (config.parentRecord) {
			// this will only be available in related lists
			config.parentRecord = { Id: config.parentRecord.Id };
		}
				    
		var getModel = function() {
            var fields = KenandyErp.KendoGridOptions.GetFields(fieldList);				
			var model = kendo.data.Model.define({ id: modelIdField, fields: fields });
					
			return model;
		};
				
		var getColumns = function() {
			//var columns = KenandyErp.KendoGridOptions.GetColumns(fieldList, { highlightFirst: options.highlightFirst||false, lookupSearchAction: lookupSearchAction, buttons: buttons, lookupSearchFilters: lookupSearchFilters });
			
            var columns = KenandyErp.KendoGridOptions.GetColumns(
                fieldList, { locked: (options.showLocked || false),
                    highlightFirst: options.highlightFirst||false,
                    lookupSearchAction: lookupSearchAction,
                    buttons: buttons,
                    lookupSearchFilters: lookupSearchFilters,
                    actionColumnPos : options.actionColumnPos,
                    actionColumnWidth: options.actionColumnWidth
                });
            return columns;
		};
		
		var getToolbarButtons = function() {
			return KenandyErp.KendoGridOptions.GetToolbarButtons(buttons);
		};
		
		var getDataSource = function() {
			var dataSource = new kendo.data.DataSource({
				transport: {
					read: function (options) {
						KenandyErp.BlockUI(selector);
						
						var promise = getRelatedListFunction();
						promise.done(function(result, event){
				            	KenandyErp.UnBlockUI(selector);
				            	
					        	if (event.type == 'exception') {
					        		KenandyErp.Alert("An error occurred while processing your request. Please contact support"); 
					        		
					        		// trigger onreadfailure
								    selector.trigger({
								        type: "OnReadFailure",
								        result: result, 
								        event: event 
								    });
								} else {
									KenandyErp.CleanNamespace(result.records, namespace);
					            	options.success(result.records);
					            	
					            	// trigger onreadsuccess
								    selector.trigger({
								        type: "OnReadSuccess",
								        result: result, 
								        event: event 
								    });
								}
				            });
					}
				},
				batch: true,
				pageSize: (config.pageSize) ? config.pageSize : KenandyErp.KendoGridOptions.DefaultPageSize,
				schema: {
					model: getModel(),
					parse:function (response) {
		                $.each(response, function (idx, item) {
		                	item = Serializer.IncludeNulls(item, { fields: nestedFields });
                    		item = Serializer.ConvertFromSFDCDate(item, { dateFields: dateFields });
					    });
					    
		                return response;
		            }
				},
				aggregate: options.aggregates ? options.aggregates : null    	
			});

			return dataSource;
		};
				
		var grid = $(selector).kendoGrid({
	        	dataSource: getDataSource(), 
	        	navigatable: true,
	        	pageable: { 
	        		input: true,
	                numeric: false,
	        		pageSizes: KenandyErp.KendoGridOptions.PageSizes,
	        		messages: {
	        			display: '{0} - {1} of {2} records',
	        			empty: '',
	        			itemsPerPage: 'records per page'
	        		}
				},		
		        toolbar: getToolbarButtons(),
		        columns: getColumns(),
                columnMenu: options.showLocked,
		        sortable: true,
				filterable: true,
				resizable: true,
				reorderable: (options.hasOwnProperty('reorderable'))? options.reorderable: false, //KNDY-17349 drag and drop columns to reorder them
				editable: (options.hasOwnProperty('editable')) ? options.editable : true, //AR-133
				edit: $.proxy(KenandyErp.KendoGridActions.Edit, { referenceFields: referenceFields }),
				dataBound: KenandyErp.KendoGridActions.DataBound,
				beforeEdit: (options.beforeEdit) ? options.beforeEdit : null,
                highlightFirst: options.highlightFirst || false
			}).data('kendoGrid'); 

				

		
		// bind click events to the custom buttons
		KenandyErp.KendoGridOptions.BindEvents(grid, buttons, { saveAction: saveRelatedListAction, referenceFields: referenceFields, config: config, dateFields : dateFields });

		// set the grid height
		if (config.height) {
			$(selector).height(config.height);
		}
		
		return grid;
	};
})(jQuery);