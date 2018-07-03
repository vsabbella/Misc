var GridActionListActions = function() {
	
	return {
	
		Save: function(e) {
   			var self = this;
   			var grid = self.grid;
   			var messageElement = grid.element.closest("div.grid-container").find("div.grid-message");
   			
			var gridUtils = new KendoGridUtils(grid, self.options);
							
			if (!gridUtils.IsValid()) {
                e.preventDefault();
                return;
            }
		 		
        	if (!gridUtils.HasChanges()) {
        		KenandyErp.Message("No records changed.", KenandyErp.MessageType.Info, messageElement);
        		return;
        	}
        	
        	var updatedRows = gridUtils.UpdatedRows();
        	var newRows = gridUtils.NewRows();
        	var deletedRows = gridUtils.DeletedRows();
        	var changeListIds = _.union(_.pluck(updatedRows, 'Id'), _.pluck(deletedRows, 'Id'));
        	
			KenandyErp.BlockUI(grid.element);
							
			Visualforce.remoting.Manager.invokeAction(
		    	self.options.saveAction,
		    	self.options.config,			     	        
				updatedRows, 
				newRows, 
				deletedRows, 
				function (result, event) {
					KenandyErp.UnBlockUI(grid.element);
						    	
					if (event.type == 'exception') {
						KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
					} else {
						if (result.success) {
							var newIds = _.difference(_.pluck(result.records, 'Id'), changeListIds);
							
							//refresh the grid
	                		grid.dataSource._destroyed = [];
	                		grid.dataSource.read({ newIds: newIds });
										
							// trigger onsavesuccess
							grid.element.trigger("OnSaveSuccess");
										
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
	};
}();
(function ($) {
    var kendo = window.kendo,
        ui = kendo.ui,
        Widget = ui.Widget,
        CHANGE = "change";
        ONREADFAILURE = "OnReadFailure";
        ONREADSUCCESS = "OnReadSuccess";

	var GridActionList = ui.Grid.extend({
		_config: null,
		_fieldList: null,
		_standardButtons: null,
		_namespace: null,
		_referenceFields: null,
		_dateFields: null,
		_nestedFields: null,
		_lookupSearchFilters: null,
		_modelIdField: null,
		_getActionListFunction: null,
		_allowMassDelete: null,
		_showIconButtons: null,
		
        // method called when a new widget is created
        init: function (element, options) {
            var that = this;
            
            //$(element).width($(element).width()); //To add a scroll bar by default, set the width of the grid to 99% - KNDY-10623
            
            
			that._initDefaults(options);
			
            var getModel = function() {
	            var fields = KenandyErp.KendoGridOptions.GetFields(_fieldList);	
	
	            // Add schema for checkbox column
				fields.IsSelected__custom = { type: "boolean" };
								
				var model = kendo.data.Model.define({ id: _modelIdField, fields: fields });
						
				return model;
			};
					
			var getColumns = function() {
	            var columns = KenandyErp.KendoGridOptions.GetColumns(_fieldList, { locked: (options.showLocked || false), highlightFirst: options.highlightFirst || false, lookupSearchAction: options.lookupSearchAction, buttons: _standardButtons, actionColumnButtons: _actionColumnButtons, lookupSearchFilters: _lookupSearchFilters, allowMassDelete: _allowMassDelete, validateLookupOnBlur: options.validateLookupOnBlur, actionColumnPos : _config.actionColumnPos, actionColumnWidth: _config.actionColumnWidth });
	            // Add checkbox column
				if(_config.renderCheckboxes=== undefined || _config.renderCheckboxes === true){
					columns.unshift({ field: 'IsSelected__custom', filterable: false, sortable: false, template: "<input type='checkbox' data-bind='IsSelected__custom' #= IsSelected__custom ? checked='checked': '' # class='grid-select-one' />", headerTemplate: "<input type='checkbox' class='grid-select-all' />", width: 30, attributes: { class: 'kndy-text-left' }, headerAttributes: { class: 'kndy-text-left' } });
				}	

				if (options.showLocked == true){
	            	columns[0].locked = true;
	            	columns[0].lockable = false;
	            	if (columns[0].field == 'IsSelected__custom'){
		            	columns[0].width = 45;
	            	}
	            }            
					
				return columns;
			};
			
			var getToolbarButtons = function() {
				var buttons = KenandyErp.KendoGridOptions.GetToolbarButtons(_standardButtons, { showIconButtons: _showIconButtons, allowMassDelete: _allowMassDelete });
				
				buttons = _.union(buttons, options.toolbarButtons);
				return buttons;
			};
			
			var getDataSource = function(actionListFunction) {
				var dataSource = new kendo.data.DataSource({
					transport: {
						read: function (options) {
							KenandyErp.BlockUI(element);
							
							var promise = actionListFunction(options.data.readOptions);
							promise.done(function(result, event){
					            	KenandyErp.UnBlockUI(element);
					            	
						        	if (event.type == 'exception') {
						        		KenandyErp.Alert("An error occurred while processing your request. Please contact support"); 
							        		
						        		// trigger onreadfailure
									    $(element).trigger({
									        type: ONREADFAILURE,
									        result: result, 
									        event: event 
									    });
									    options.error(event, event.statusCode, event.message);
									} else {
										KenandyErp.CleanNamespace(result.records, _namespace);
						            	options.success(result.records);
						            	
						            	// trigger onreadsuccess
									    $(element).trigger({
									        type: ONREADSUCCESS,
									        result: result, 
									        event: event 
									    });
									}
					            });
						}
					},
					batch: true,
					pageSize: (_config.pageSize) ? _config.pageSize : KenandyErp.KendoGridOptions.DefaultPageSize,
					schema: {
						model: getModel(),
						parse:function (response) {
			                $.each(response, function (idx, item) {
			                	item = Serializer.IncludeNulls(item, { fields: _nestedFields });
	                    		item = Serializer.ConvertFromSFDCDate(item, { dateFields: that._dateFields });
						    });
						    
			                return response;
						}         	
					},
					aggregate: options.aggregates ? options.aggregates : null,    
                    error: function(e) {
                    	console.log("DataSource error:");
                        console.log(e); 
                    }								
				});
	
				return dataSource;
			};
				
            var defaultOptions = {
	        	dataSource: getDataSource(options.getActionListFunction), 
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
				editable: true,
				scrollable: _config.scrollable ? _config.scrollable : true
	        };
	        
	        options = $.extend({}, defaultOptions, options);
	        
            ui.Grid.fn.init.call(that, element, options);
			
			that._initEvents();
        },
        
        // widget options
        options: {
            name: "GridActionList",
            config: null,
            fieldList: null,
            namespace: null,
            lookupSearchAction: null,
            getActionListFunction: null,
            saveActionListAction: null,
            addRowAction: null,
            lookupSearchFilters: [],
            modelIdField: 'Id',
            allowMassDelete: true,
            showIconButtons: false,
            toolbarButtons: [],
            actionColumnButtons: [],
            validateLookupOnBlur: false
        },
        
        // events the control can fire
		events: [CHANGE],
		
		_initDefaults: function(options) {
			var that = this;
			
			_config = (options.config) ? JSONUtils.Parse(options.config) : {};
			_fieldList = JSONUtils.Parse(options.fieldList);
			_standardButtons = (_config.buttons) ? $.map(_config.buttons.split(','), $.trim) : [];
			
			//var actionColumnButtons = _config.actionColumnButtons ? $.map(_config.actionColumnButtons.split(','), $.trim) : [];
			var x = _config.actionColumnButtons;
			var actionColumnButtons  = x ? ( Array.isArray(x) ? x : $.map(x.split ? x.split(',') :console.log("Sorry cannot recongnize this type"), $.trim) ): []
			_actionColumnButtons = actionColumnButtons.concat(options.actionColumnButtons);
			_namespace = _config.namespace ? _config.namespace : options.namespace;
			_referenceFields = KenandyErp.KendoGridOptions.GetReferenceFields(_fieldList); // get the list of reference fields
			that._dateFields = _config.dateFields ? _config.dateFields : KenandyErp.KendoGridOptions.GetDateFields(_fieldList); // get the list of date fields
			_lookupSearchFilters = (options.lookupSearchFilters) ? options.lookupSearchFilters : [];
			_nestedFields = KenandyErp.KendoGridOptions.GetNestedFields(_fieldList); // get the list of nested fields
			_modelIdField = options.modelIdField ? options.modelIdField : 'Id';
			_getActionListFunction = options.getActionListFunction;
			_showIconButtons = (options.showIconButtons) ? options.showIconButtons : that.options.showIconButtons;
			_allowMassDelete = (options.allowMassDelete) ? options.allowMassDelete : that.options.allowMassDelete;
		},
		
		_initEvents: function() {
			var that = this;
			var grid = that;
			
			// bind grid edit event
			grid.bind('edit', $.proxy(KenandyErp.KendoGridActions.Edit, { referenceFields: _referenceFields }));
				
			// bind grid dataBound event
			grid.bind('dataBound', KenandyErp.KendoGridActions.DataBound);
				
			// bind click events to the custom buttons
			KenandyErp.KendoGridOptions.BindEvents(grid, _standardButtons, { saveAction: that.options.saveActionListAction, addRowAction: that.options.addRowAction, referenceFields: _referenceFields, config: _config, dateFields : that._dateFields, ignoreBindings: [ KenandyErp.KendoGridOptions.CommandType.Save ] });

			// set the grid height
			if (that.options.height) {
				grid.wrapper.height(that.options.height);
			}
			
			grid.wrapper.on("click", ".grid-save-command", $.proxy(GridActionListActions.Save, { grid: grid, options: { saveAction: that.options.saveActionListAction, config: _config } }));
			
			if(_config.renderCheckboxes=== undefined || _config.renderCheckboxes === true){
			grid.thead.on("click", ".grid-select-all", $.proxy(KenandyErp.KendoGridActions.SelectAll, { grid: grid }));
			grid.tbody.on("change", ".grid-select-one", $.proxy(KenandyErp.KendoGridActions.Select, { grid: grid, referenceFields: _referenceFields }));
			
			grid.bind('dataBound', function () {
				var isSelected = (grid.tbody.find('.grid-select-one').length > 0 && !grid.tbody.find('.grid-select-one').is(':not(:checked)')) ? true : false;
				grid.thead.find('.grid-select-all').prop('checked', isSelected);
			});
			}

		},
		
        destroy: function() {
          var that = this;
    
    	  that.element.off();
          kendo.ui.Grid.fn.destroy.call(that);
		}
	});

	ui.plugin(GridActionList);
})(jQuery);