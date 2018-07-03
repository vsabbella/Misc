// Custom Kendo Lookup widget for Salesforce objects
(function () {
	kendo.ui.plugin(kendo.ui.AutoComplete.extend({
		_criteria: null,
		
	    init: function (element, options) {
	    	var that = this;
	    	var placeHolderTitle = that.options.title ? that.options.title : '';
	    	
	    	that._initDefaults(options);
	    	
	        var defaultOptions = {
	            highlightFirst: options.highlightFirst,
	        	minLength: that.options.minLength,
        		dataValueField: 'value',
        		dataTextField: 'text',
        		suggest: false,
	        	filter: "contains",
	        	placeholder: ($.support.placeholder) ? "Type to search " + placeHolderTitle + "..." : "",
	        	select: function(e) {
					var dataItem;
            		var fieldName = $(this.wrapper.context).attr('data-id-field');
            		var referenceFieldName = fieldName;

					if (e.item && e.item.index() != -1){
            			dataItem = this.dataItem(e.item.index());
            		}
            		else {
            			dataItem = { value: null, text: this.value()};
            		}

	           		if (referenceFieldName.endsWith('__c')) {
	            	    referenceFieldName = referenceFieldName.replace(/__c/, '__r');
	            	} else if (referenceFieldName.toLowerCase().endsWith('id')) {
	            	    referenceFieldName = referenceFieldName.substring(referenceFieldName, referenceFieldName.length - 2);
	            	}

            		// update current model
            		if (fieldName && dataItem) {
	                    $('input[name="' + fieldName + '"]').val(dataItem.value);
	                    $('input[name="' + referenceFieldName + '.Id"]').val(dataItem.value);
	                }
            	},
                  filtering: function(e) {
                      var filter = e.filter;

                      if (!filter.value && this.options.highlightFirst) {
                        //prevent filtering if the filter does not value
                        e.preventDefault();
                      }
                  },
            	change: function(e) {
            		var dataItem;
            		var fieldName = $(this.wrapper.context).attr('data-id-field');
            		var referenceFieldName = fieldName;

	           		if (referenceFieldName.endsWith('__c')) {
	            	    referenceFieldName = referenceFieldName.replace(/__c/, '__r');
	            	} else if (referenceFieldName.toLowerCase().endsWith('id')) {
	            	    referenceFieldName = referenceFieldName.substring(referenceFieldName, referenceFieldName.length - 2);
	            	}

	            	var testCondition = this.options.highlightFirst ? (this.current() && this.value().length > 1) : (this.current() && this.current().index() != -1)

	            	if(testCondition){
	            	     dataItem = this.dataItem(this.current().index());
	            	}
	            	else{
            			dataItem = { value: null, text: this.value() };

            			if(this.dataItems() != null){
            				var availableVals = this.dataItems();

	            			for(var i=0; i<availableVals.length; i++){
	            				if(availableVals[i].text == this.value()){
	            					dataItem = { value: availableVals[i].value, text: availableVals[i].text };
	            					break;
	            				}
	            			}
            			}
	            	}

            		if (fieldName && dataItem) {
            			$('input[name="' + fieldName + '"]').val(dataItem.value);
            			$('input[name="' + fieldName + '"]').trigger("change");

	                    $('input[name="' + referenceFieldName + '.Id"]').val(dataItem.value);
	                    $('input[name="' + referenceFieldName + '.Id"]').trigger("change");
					}
            	},
	        	dataSource: {
	        		transport: {
	        			read: function(readOptions) {
	        				var searchTerm = '';

	        				if (readOptions.data.filter && readOptions.data.filter.filters.length > 0) {
	        					var filter = _.where(readOptions.data.filter.filters, { field: 'text' });

	        					if (filter && filter.length > 0) {
	        						searchTerm = (filter[0] && filter[0].value) ? filter[0].value : '';
	        					}
	        				}

			            	Visualforce.remoting.Manager.invokeAction(
	    						that.options.action,
			                	searchTerm,
			                	that.options.referenceTo,
			                	that.options.criteria,
			                	function (result, event) {
				                    if (event.type == 'exception') {
				                        KenandyErp.Alert(event.message);
				                    } else {
				                        readOptions.success(result);
				                    }
			                	},
			                	{escape: false}
			                );
			            }
	        		},
	        		serverFiltering: true
	        	}
	        };
	        options = $.extend({}, defaultOptions, options);

	        //base call to widget initialization
	        kendo.ui.AutoComplete.fn.init.call(this, element, options);
	    },

	    options: {
	        name: 'Lookup',
	        minLength: 2,
	        title: '',
	        action: null,
	        referenceTo: null,
	        criteria: null,
	        idField: null
	    },

		_initDefaults: function(options) {
			var that = this;
			_criteria = options.criteria;
	    }
	}));
})();

// Custom Kendo OutputText widget for read-only display of a value for a field on a Salesforce object
(function ($) {
    var kendo = window.kendo,
        ui = kendo.ui,
        Widget = ui.Widget,
        CHANGE = "change";

	var OutputText = Widget.extend({

        // method called when a new widget is created
        init: function (element, options) {
            var that = this;
            Widget.fn.init.call(this, element, options);

            // set the value from the options.value setting
            if (options.value) {
                that.value(options.value);
            }
        },

        // options that are available to the user when initializing the widget
        options: {
            name: "OutputText",
            value: null,
            type: null,
            scale: 0
        },

        // MVVM framework calls 'value' when the viewmodel 'value' binding changes
        value: function(value) {
            var that = this;

            if (value === undefined) {
                return that._value;
            }

            that._update(value);
            that._old = that._value;
        },

		destroy: function () {
            var that = this;

            that.element.off();

			Widget.fn.destroy.call(that);
        },

        // events the control can fire
		events: [CHANGE],

        // update the internals of 'value'
        _update: function (value) {
            var that = this;

            switch(that.options.type)
			{
				case KenandyErp.KendoGridOptions.ColumnType.Reference:
					if (value) {
			   			value = KenandyErp.LookupHoverDetail(value.Id, value.Name, true);
			   		}
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.Date:
			   		value = (value && (value instanceof Date)) ? kendo.toString(value, KenandyErp.DateFormat) : '';
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.DateTime:
			   		value = (value && (value instanceof Date)) ? kendo.toString(value, KenandyErp.DateTimeFormat) : '';
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.Integer:
			   	case KenandyErp.KendoGridOptions.ColumnType.Double:
			   	case KenandyErp.KendoGridOptions.ColumnType.Percent:
			   		var scale = (that.options && that.options.scale) ? that.options.scale : 0;
			   		value = (value && !isNaN(value)) ? kendo.toString(value, 'n' + scale) : '';
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.Boolean:
			   		value = (value) ? '<img src="/img/checkbox_checked.gif" alt="Checked" width="21" height="16" class="checkImg" title="Checked">' : '';
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.MultiPicklist:
			   		value = value ? value.map(function(v) {
							    return v;
							}).toString() : '';
			   	break;
			   	default:
			    	break;
			}

            that._value = value;
            that.element.html(value);
        },

        _change: function (value) {
            var that = this;

            // determine if the value is different
            if (that._old != value) {
                // update the value if it is different
                that._update(value);
                // capture the new value for future change detection
                that._old = value;
                // trigger the external change
                that.trigger(CHANGE);
            }
        }
	});

	ui.plugin(OutputText);
})(jQuery);

// Custom Kendo DetailList to mimic the standard Salesforce Detail List for a Salesforce object
(function() {
    var kendo = window.kendo,
        ui = kendo.ui,
        Widget = ui.Widget,
		CHANGE = "change";
        ONREADFAILURE = "OnReadFailure";
        ONREADSUCCESS = "OnReadSuccess";

    var DetailList = kendo.ui.Widget.extend({
		_namespace: null,
		_fieldList: [],
		_referenceFields: [],
		_dateFields: [],
		_multiPicklistFields: [],
		_nestedFields: [],
		_lookupSearchFilters: [],
		_modelIdField: null,
		_getDetailListFunction: null,
		_defaults: {},
		data: null,

        // method called when a new widget is created
        init: function (element, options) {
            var that = this;

            that._initDefaults(options);

            kendo.ui.Widget.fn.init.call(that, element, options);

            that._dataSource();
        },

        // options that are available to the user when initializing the widget
        options: {
            name: "DetailList",
            autoBind: true,
            sections: [],
            columns: 2,
            lookupSearchAction: null,
            lookupSearchFilters: null,
            modelIdField: 'Id',
            autoExpandSections: false,
            highlightFirst: false
        },

		destroy: function () {
            var that = this;

            that.element.off();

			Widget.fn.destroy.call(that);

            if (that.dataSource) {
                if (that._refresh) {
                    that.dataSource.unbind(CHANGE, that._refresh);
                }
            };
        },

        validate: function() {
        	var that = this;

        	var validator = $(that.element).kendoValidator({
		    	rules: {
		        	RequiredFieldRule: function(input) {
		          		if (input.attr('required')) {
		          			validator.options.messages['RequiredFieldRule'] = input.attr('data-required-msg');
		          			if(typeof input.val() == "object"){
                               return (input.val().length > 0) ;
                            }
		            		return $.trim(input.val()) !== "";
		          		}

		          		return true;
		        	},

		        	InvalidDateRule: function(input) {
				    	if ((input.attr('data-role') == 'datepicker' || input.attr('data-role') == 'datetimepicker') && input.val() != "") {
				    		var format = (input.attr('data-role') == 'datepicker') ? KenandyErp.DateFormat : KenandyErp.DateTimeFormat;
                            var value = kendo.parseDate(input.val(), format);

                            input.attr("data-invaliddate-msg", input.attr('data-title') + " is invalid");
		                    validator.options.messages['InvalidDateRule'] = input.attr('data-invaliddate-msg');

							if (!(value instanceof Date)) {
								return false;
							}
                        }

                        return true;
				    },

		        	InvalidLookupRule: function(input) {
				    	if (input.attr('data-role') == 'lookup' && input.val() != "" && input.attr('data-id-field')) {
				    		var referenceField = input.attr('data-id-field');

			           		if (referenceField.endsWith('__c')) {
			            	    referenceField = referenceField.replace(/__c/, '__r');
			            	} else if (referenceField.toLowerCase().endsWith('id')) {
			            	    referenceField = referenceField.substring(referenceField, referenceField.length - 2);
			            	}

				    		input.attr("data-invalidlookup-msg", input.attr('data-title') + " is invalid");
				    		validator.options.messages['InvalidLookupRule'] = input.attr('data-invalidlookup-msg');
		            		return $.trim($('input[name="' + referenceField + '.Id"]').val()) !== "";
                        }

                        return true;
				    }
		      	},

		      	messages: {
		        	RequiredFieldRule: "Invalid data",
		        	InvalidDateRule: "Invalid date",
		        	InvalidLookupRule: "Invalid data"
		      	}
			}).data("kendoValidator");

			return validator.validate();
        },

        enable: function (isEnabled, options) {
        	var that = this;
        	var fields = that._fieldList;
        	var disabledFields = (options.disabledFields) ? options.disabledFields : [];

        	if (disabledFields && disabledFields.length > 0) {
        		fields = $.map(fields, function(item, index) {
					if (_.contains(disabledFields, item.field)) {
						return item;
					}
				});
        	}

        	for (var i = 0; i < fields.length; i++) {
		    	var fieldInfo = fields[i];

            	switch(fieldInfo.fieldtype)
				{
					case KenandyErp.KendoGridOptions.ColumnType.Date:
						var datePicker = $("input[id='" + fieldInfo.field + "']").data('kendoDatePicker');
				   		if (datePicker) {
				   			datePicker.enable(isEnabled);
				   		}
				   		break;
					case KenandyErp.KendoGridOptions.ColumnType.DateTime:
				   		var dateTimePicker = $("input[id='" + fieldInfo.field + "']").data('kendoDateTimePicker');
				   		if (dateTimePicker) {
				   			dateTimePicker.enable(isEnabled);
				   		}
				   		break;
				   	case KenandyErp.KendoGridOptions.ColumnType.Picklist:
				   		var dropDownList = $("select[id='" + fieldInfo.field + "']").data('kendoDropDownList');
				   		if (dropDownList) {
				   			dropDownList.enable(isEnabled);
				   		}
				   		break;
				   	case KenandyErp.KendoGridOptions.ColumnType.MultiPicklist:
				   		var multiPicklist = $("select[id='" + fieldInfo.field + "']").data('kendoMultiSelect');
				   		if (multiPicklist) {
				   			multiPicklist.enable(isEnabled);
				   		}
				   	break;
					case KenandyErp.KendoGridOptions.ColumnType.Reference:
						var referenceField = fieldInfo.field;

		           		if (referenceField.endsWith('__c')) {
		            	    referenceField = referenceField.replace(/__c/, '__r');
		            	} else if (referenceField.toLowerCase().endsWith('id')) {
		            	    referenceField = referenceField.substring(referenceField, referenceField.length - 2);
		            	}

				   		var lookup = $("input[id='" + referenceField + ".Name']").data('kendoLookup');
				   		if (lookup) {
				   			lookup.enable(isEnabled);
				   		}
				   		break;
					case KenandyErp.KendoGridOptions.ColumnType.Integer:
				   	case KenandyErp.KendoGridOptions.ColumnType.Double:
				   	case KenandyErp.KendoGridOptions.ColumnType.Percent:
            			var numericTextbox = $("input[id='" + fieldInfo.field + "']").data('kendoNumericTextBox');
            			if (numericTextbox) {
				   			numericTextbox.enable(isEnabled);
				   		}
				   		break;
				   	case KenandyErp.KendoGridOptions.ColumnType.Boolean:
				   		var checkBox = $("input[id='" + fieldInfo.field + "']");
				   		if (checkBox) {
					   		if (isEnabled) {
					   			checkBox.removeAttr('disabled');
					   		}
					   		else {
					   			checkBox.attr('disabled', 'disabled');
					   		}
				   		}
				   		break;
				   	default:
				   		var textBox = $("input[id='" + fieldInfo.field + "']");
				   		if (textBox) {
					   		if (isEnabled) {
					   			textBox.removeAttr('disabled');
					   		}
					   		else {
					   			textBox.attr('disabled', 'disabled');
					   		}
					   	}
				   		break;
				}
			}
        },

        getFieldList: function() {
        	var that = this;

        	return that._fieldList;
        },

        getDateFields: function() {
        	var that = this;

        	return that._dateFields;
        },

        // events the control can fire
		events: [CHANGE],

		_initDefaults: function(options) {
			var that = this;

			$.each(options.sections, function(index) {
				if (options.sections[index].fields) {
					that._fieldList = that._fieldList.concat(options.sections[index].fields);
				}
			});
			that._namespace = options.namespace;
			that._referenceFields = KenandyErp.KendoGridOptions.GetReferenceFields(that._fieldList); // get the list of reference fields
			that._dateFields = KenandyErp.KendoGridOptions.GetDateFields(that._fieldList); // get the list of date fields
			that._multiPicklistFields = KenandyErp.KendoGridOptions.getMultiPicklistFields(that._fieldList);
			that._lookupSearchFilters = (options.lookupSearchFilters) ? options.lookupSearchFilters : [];
			that._modelIdField = options.modelIdField ? options.modelIdField : 'Id';
			that._getDetailListFunction = options.getDetailListFunction;

			$.each(that._referenceFields, function(index, item) {
				var referenceField = item;

           		if (referenceField.endsWith('__c')) {
            	    referenceField = referenceField.replace(/__c/, '__r');
            	} else if (referenceField.toLowerCase().endsWith('id')) {
            	    referenceField = referenceField.substring(referenceField, referenceField.length - 2);
            	}

				that._nestedFields.push(referenceField + '.Id');
				that._nestedFields.push(referenceField + '.Name');
			});
		},

        _dataSource: function () {
        	var that = this;

            var getDataSource = function() {
				var dataSource = new kendo.data.DataSource({
					transport: {
						read: function (options) {
							KenandyErp.BlockUI(that.element);

							var promise = that._getDetailListFunction(options.data.readOptions);
							promise.done(function(result, event){
					            	KenandyErp.UnBlockUI(that.element);

						        	if (event.type == 'exception') {
						        		KenandyErp.Alert("An error occurred while processing your request. Please contact support");

						        		// trigger onreadfailure
									    $(that.element).trigger({
									        type: ONREADFAILURE,
									        result: result,
									        event: event
									    });
									} else {
										KenandyErp.CleanNamespace(result.records, that._namespace);
										
										// KNDY-18217 for read only picklist fields, display picklist label and not api name
										for (var i = 0; i< that._fieldList.length ; i++){
										   if (!that._fieldList[i].editable && that._fieldList[i].fieldtype == "picklist"){
										      var record = result.records[0];
										      var selectList = that._fieldList[i].selectList;
										      var picklistLabel = '';
										      var picklistfieldVal = record[that._fieldList[i].field];
										      selectList.map(function(val,index){
										          if(!picklistLabel && val.value == picklistfieldVal){
										              picklistLabel = val.text;
										          }
										      });
										      record[that._fieldList[i].field] = picklistLabel
										   }
										}

						            	options.success(result.records);

						            	// trigger onreadsuccess
									    $(that.element).trigger({
									        type: ONREADSUCCESS,
									        result: result,
									        event: event
									    });
									}
					            });
						}
					}
				});

				return dataSource;
			};

            that.dataSource = getDataSource();

            // bind to the change event to refresh the widget
            that.dataSource.bind(CHANGE, function () {
                that._refresh();

				var viewModel = (this.view()[0]) ? JSON.parse(JSON.stringify(this.view()[0])) : {};

                $.each(that._fieldList, function(idx, item) {
                    if (item.selectList != null && !viewModel[item.field]){
                        $.each(item.selectList, function(idx, selectItem){
                            if (selectItem.selected){
                                viewModel[item.field] = selectItem.text;
                            }
                        });
                    }
                });

				if (JSONUtils.Get(viewModel, that._modelIdField)) {
					viewModel = $.extend({}, that._defaults, viewModel);
				}

				viewModel = Serializer.IncludeNulls(viewModel, { fields: that._nestedFields });
				viewModel = Serializer.ConvertFromSFDCDate(viewModel, { dateFields: that._dateFields });
				viewModel = Serializer.ConvertMultiPicklistvalues(viewModel, {multiPicklistFields: that._multiPicklistFields});
                that.data = kendo.observable(viewModel);

    			kendo.bind(that.element, that.data);

    			that.dataSource.unbind(CHANGE);
            });

            // trigger a read on the dataSource if one hasn't happened yet
            if (that.options.autoBind) {
                that.dataSource.fetch();
            }
        },

		_refresh: function () {
            var that = this;
            var sections = that.options.sections;
            var cols = that.options.columns - 1;
           	var sectionList = $('<ul class="kndy-detail-list" data-role="panelbar" />');

            for (var i = 0; i < sections.length; i++) {
		    	var section = sections[i];
		    	var name = (section.name) ? section.name : '';
		    	var title = (section.title) ? section.title : '';
		    	var fields = (section.fields) ? section.fields : [];
		    	var sectionItem = (name && title) ? $('<li name="' + name + '"><h3 class="kndy-section-title">' + title + '</h3></li>') : $('<li />');

		    	if (fields.length == 0) {
		    		if (section.content) {
						sectionItem.append($('<div />').append(section.content));
			    		sectionList.append(sectionItem);
		    		}

					continue;
		    	}

	            var counter = 0;
	            var resetCounter = 0;
	            var table = $('<table class="kndy-table" />');
	           	var row;

			    for (var j = 0; j < fields.length; j++) {
			    	var fieldInfo = fields[j];

			    	if (resetCounter == 0) {
			    		row = $('<tr/>');
			    	}

			        if (resetCounter <= cols) {
			            row.append($('<td class="kndy-label-column" />').html(that._getLabelColumn(fieldInfo)));
			            row.append($('<td class="kndy-data-column" />').html(that._getDataColumn(fieldInfo)));
			        }

			        if (fields.length == 1) {
			        	row.append($('<td class="kndy-label-column" />'));
			            row.append($('<td class="kndy-data-column" />'));
			        }

			        if (fields.length - 1 == counter || resetCounter == cols) {
			        	resetCounter = 0;
			        	table.append(row);
			        }
			        else {
			        	resetCounter++;
			        }

			        counter++;
			    }

			    if (i == 0 || that.options.autoExpandSections) {
			    	sectionItem.addClass('k-state-active');
			    }

			    sectionItem.append($('<div />').append(table));
			    sectionList.append(sectionItem);
            }

            that.element.append(sectionList);
        },

        _getLabelColumn: function (fieldInfo) {
        	var template = kendo.template('<label for="#=field#">#=title#</label>');

			return template(fieldInfo);
        },

        _getDataColumn: function (fieldInfo) {
        	var that = this;
        	var element = $('<span />');
			var required = fieldInfo.required ? ' required="required" data-required-msg="' + fieldInfo.title + ' is required"' : '';
			var highlightFirst = this.options.highlightFirst || false;

        	switch(fieldInfo.fieldtype)
			{
				case KenandyErp.KendoGridOptions.ColumnType.Date:
					if (!fieldInfo.editable) {
						$('<span data-bind="value: ' + fieldInfo.field + '" data-role="outputtext" data-type="' + fieldInfo.fieldtype + '"></span>')
							.appendTo(element);
					}
					else {
				   		$('<input ' + required + ' id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-role="datepicker" data-title="' + fieldInfo.title + '" data-format="' + KenandyErp.DateFormat + '" data-culture="' + KenandyErp.Culture + '" data-title="' + fieldInfo.title + '" data-bind="value:' + fieldInfo.field + '" />')
						    .appendTo(element);
					}
			   		break;
				case KenandyErp.KendoGridOptions.ColumnType.DateTime:
					if (!fieldInfo.editable) {
						$('<span data-bind="value: ' + fieldInfo.field + '" data-role="outputtext" data-type="' + fieldInfo.fieldtype + '"></span>')
							.appendTo(element);
					}
					else {
				   		$('<input ' + required + ' id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-role="datetimepicker" data-title="' + fieldInfo.title + '" data-format="' + KenandyErp.DateTimeFormat + '" data-culture="' + KenandyErp.Culture + '" data-title="' + fieldInfo.title + '" data-bind="value:' + fieldInfo.field + '" data-parse-formats="' + KenandyErp.DateFormat + '" />')
						    .appendTo(element);
					}
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.Picklist:
			   		if (!fieldInfo.editable) {
						$('<span data-bind="text: ' + fieldInfo.field + '"></span>')
							.appendTo(element);
					}
					else {
				   		var picklist = $('<select ' + required + ' id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-role="dropdownlist" data-value-field="value" data-text-field="text" data-value-primitive="true" data-bind="value:' + fieldInfo.field + '" />');

						$.each(fieldInfo.selectList, function(index, item) {
							var selected = item.selected ? ' selected="true"' : '';

							if (selected) {
								that._defaults[fieldInfo.field] = item.value;
							}

						    picklist.append(
						    	$('<option></option>').val(item.value).html(item.text)
					        );
						});
						picklist.appendTo(element);
					}
			   		break;
                case KenandyErp.KendoGridOptions.ColumnType.MultiPicklist:

                    if (!fieldInfo.editable) {
						$('<span data-bind="value: ' + fieldInfo.field + '" data-role="outputtext" data-type="' + fieldInfo.fieldtype + '"></span>')
							.appendTo(element);
					}
					else {
				   		var picklist = $('<select ' + required + ' id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-role="multiselect" data-value-field="value" data-text-field="text" data-value-primitive="true" data-bind="value:' + fieldInfo.field + '" />');

						$.each(fieldInfo.selectList, function(index, item) {
							var selected = item.selected ? ' selected="true"' : '';

							if (selected) {
								that._defaults[fieldInfo.field] = item.value;
							}

						    picklist.append(
						    	$('<option></option>').val(item.value).html(item.text)
					        );
						});
						picklist.appendTo(element);
					}
			   		break;
				case KenandyErp.KendoGridOptions.ColumnType.Reference:
					if (!fieldInfo.editable) {
						$('<span data-bind="value: ' + fieldInfo.field.replace('__c', '__r') + '" data-role="outputtext" data-type="' + fieldInfo.fieldtype + '"></span>')
							.appendTo(element);
					}
					else {
						var filterCriteria = '';
	            		var lookupSearchFilters = that.options.lookupSearchFilters;
	            		var referenceFieldName = fieldInfo.field;

		           		if (referenceFieldName.endsWith('__c')) {
		            	    referenceFieldName = referenceFieldName.replace(/__c/, '__r');
		            	} else if (referenceFieldName.toLowerCase().endsWith('id')) {
		            	    referenceFieldName = referenceFieldName.substring(referenceFieldName, referenceFieldName.length - 2);
		            	}

	            		// apply additional filter criteria
	            		if (lookupSearchFilters) {
	            			filterCriteria = _.where(lookupSearchFilters, { field: fieldInfo.field });
	            			filterCriteria = (filterCriteria.length > 0) ? filterCriteria[0].filter : '';
	            		}


	            		// set additional filter criteria
    					if (filterCriteria) {
    						var filterCriteriaTemplate = kendo.template(filterCriteria);
							filterCriteria = filterCriteriaTemplate(this.dataSource.data()[0]);
    					}

    					$('<input type="hidden" id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-bind="value:' + fieldInfo.field + '" />')
						    .appendTo(element);

    					$('<input type="hidden" id="' + referenceFieldName + '.Id" name="' + referenceFieldName + '.Id" data-bind="value:' + referenceFieldName + '.Id" />')
						    .appendTo(element);

						$('<input ' + required + ' id="' + referenceFieldName + '.Name" name="' + referenceFieldName + '.Name" data-id-field="' + fieldInfo.field + '" data-role="lookup" data-action="' + that.options.lookupSearchAction + '" data-title="' + fieldInfo.title + '" data-reference-to="' + fieldInfo.referenceTo + '" data-criteria="' + filterCriteria + '" data-title="' + fieldInfo.title + '" data-value-field="value" data-text-field="text" data-value-primitive="true" data-bind="value:' + referenceFieldName + '.Name" data-highlight-first="'+ highlightFirst +'" />')
						    .appendTo(element);
					}
			   		break;
				case KenandyErp.KendoGridOptions.ColumnType.Integer:
			   	case KenandyErp.KendoGridOptions.ColumnType.Double:
			   	case KenandyErp.KendoGridOptions.ColumnType.Percent:
			   		if (!fieldInfo.editable) {
						$('<span data-bind="value: ' + fieldInfo.field + '" data-role="outputtext" data-type="' + fieldInfo.fieldtype + '" data-scale="' + fieldInfo.scale + '"></span>')
							.appendTo(element);
					}
					else {
				   		$('<input ' + required + ' id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-role="numerictextbox" data-format="{0:n' + fieldInfo.scale + '}" data-decimals="' + fieldInfo.scale + '" data-bind="value:' + fieldInfo.field + '" class="kndy-text-right" data-min="' + fieldInfo.min + '" data-max="' + fieldInfo.max + '" />')
					    	.appendTo(element);
					}
			   		break;
			   	case KenandyErp.KendoGridOptions.ColumnType.Boolean:
			   		if (!fieldInfo.editable) {
						$('<span data-bind="value: ' + fieldInfo.field + '" data-role="outputtext" data-type="' + fieldInfo.fieldtype + '"></span>')
							.appendTo(element);
					}
					else {
				   		$('<input ' + required + ' type="checkbox" id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" data-bind="checked:' + fieldInfo.field + '" />')
						    .appendTo(element);
					}
			   		break;
			   	default: 
			   		if (!fieldInfo.editable) {
						$('<span data-bind="text: ' + fieldInfo.field + '"></span>')
							.appendTo(element);
					}
					else {
				   		$('<input ' + required + ' id="' + fieldInfo.field + '" name="' + fieldInfo.field + '" class="k-textbox" data-bind="value:' + fieldInfo.field + '" />')
						    .appendTo(element);
					}
			    	break;
			}
			
			var fieldName = (fieldInfo.fieldtype == KenandyErp.KendoGridOptions.ColumnType.Reference) ? fieldInfo.field.replace('__c', '__r.Name') : fieldInfo.field;
			$('<span class="k-invalid-msg" data-for="' + fieldName + '"></span>').appendTo(element);
			
			if (fieldInfo.required && fieldInfo.editable) {
				return '<div class="requiredInput"><div class="requiredBlock"></div>' + element.html() + '</div>';
			}
			else {
        		return '<span>' + element.html() + '</span>';
        	}
        }
    });

    ui.plugin(DetailList);
})(jQuery);

// Custom Kendo DropDown Button
(function() {
    var kendo = window.kendo,
        ui = kendo.ui,
        Widget = ui.Widget,
        wrapper = null;
        splitButton = null;
        popupMenu = null;
		CLICK = "click";
		HIDDEN = 'kndy-hidden';		
		DROPDOWN_BUTTON = 'kndy-dropdown-button';
		PRIMARY_BUTTON = 'kndy-primary-button';
		SPLIT_BUTTON = 'kndy-split-button';
		POPUP_MENU = 'kndy-popup-menu';
		BUTTON = 'k-button';

    var DropDownButton = kendo.ui.Button.extend({
		_itemTemplate: "# if (iconCss.length > 0) { #<span class=' #=iconCss # k-icon'></span># } # #= text #",		
		
        // method called when a new widget is created
        init: function (element, options) {
            var that = this;
            
            kendo.ui.Button.fn.init.call(that, element, options);
            
            that._create();
        },

        // options that are available to the user when initializing the widget
        options: {
            name: "DropDownButton",
            items: [],
            cssClass: null,
            type: 'button' // button/splitButton
        },
        
        _create: function () {
            var that = this;
            
            that.popupMenu = $('<ul/>');
            
            if (that.options.items) {
                var itemTemplate = kendo.template(that._itemTemplate);
                
                $.each(that.options.items, function (index, item) {
                    var listItem = $('<li/>');
                    
                    if (item.separator) {
                        listItem.addClass('kndy-separator');
                        listItem.append('<hr/>');
                    } else {
                        item = $.extend({ iconCss: "" }, item);
                        html = itemTemplate(item);
                        listItem.append(html);
                        
                        if (item.cssClass) {
                            listItem.addClass(item.cssClass);
                        }
                        
                        if (typeof item.click === "function") {
                            listItem.unbind('click');
                            listItem.bind('click', item.click);
                        }
                    }
                    
                    that.popupMenu.append(listItem);
                });
            }
            
            that.popupMenu.addClass(POPUP_MENU + ' ' + HIDDEN);
            
            if (that.popupMenu.data('kendoMenu')) {
                that.popupMenu.data('kendoMenu').destroy();
            }
            
            that.popupMenu.kendoMenu({
                orientation: "vertical",
                select: function (e) {
                    that.hide();
                }
            });
            
            that.wrapper = $('<div/>');
            that.wrapper.addClass(DROPDOWN_BUTTON);
            
            if (that.options.cssClass) {
                that.element.addClass(that.options.cssClass);
            }
            
            that.element.wrap(that.wrapper);
            
            if (that.options.type === 'splitButton') {
                that.splitButton = $('<button/>');
                that.splitButton.attr('type', 'button');
                that.splitButton.append('<span class="k-icon k-i-arrow-s"></span>');
                that.splitButton.addClass(BUTTON + ' ' + SPLIT_BUTTON);
                
                that.element.addClass(PRIMARY_BUTTON);
                that.element.after(that.splitButton);
                
                that.splitButton.off('click');
                that.splitButton.on('click', function (e) {
                    that.show();
                });
                
                that.splitButton.after(that.popupMenu);
            }
            else {
                that.element.append('<span class="k-icon k-i-arrow-s"></span>');
                
                that.element.off('click');
                that.element.on('click', function (e) {
                    that.show();
                });
                
                that.element.after(that.popupMenu);
            }
            
            $(document).click(function (e) {
                if ($(e.target).closest('.kndy-popup-menu').length == 0) {
                    if (!that.popupMenu.hasClass(HIDDEN)) {
                        that.hide();
                    }
                }
            });
        },
        
		destroy: function () {
            var that = this;
            
            that.element.off();
            
			Widget.fn.destroy.call(that);
        },
        
        show: function () {
            var that = this;

            that.popupMenu.slideToggle('fast', function () {
                that.popupMenu.removeClass(HIDDEN);
            });
        },

        hide: function () {
            var that = this;

            that.popupMenu.slideToggle('fast', function () {
                that.popupMenu.addClass(HIDDEN);
            });
        }
    });

    ui.plugin(DropDownButton);
})(jQuery);