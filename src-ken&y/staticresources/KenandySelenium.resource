var SeleniumUtils = function () {
   
   return {
       
       Init: function (args) {
           
      	}
	};
}();

// Kendo Grid utility functions for Selenium automation testing
SeleniumUtils.KendoGridUtils = function() {
	var specialKeys = [kendo.keys.UP, kendo.keys.DOWN];
	
	var getCellCoordinates = function(gridId) {
		var grid = kendo.widgetInstance($('#' + gridId));
       	var cell = grid.editable.element;
       	var row = $(cell).closest('tr');
       		
       	var rowIndex = $('tr', grid.tbody).index(row);
       	var colIndex = $('td:visible', row).index(cell);
       	
       	return { RowIndex: rowIndex, ColumnIndex: colIndex };
	};
	
	var getVisibleColumns = function(columns) {
		return $.map(columns, function(item, index) {
			if (!item.hidden) {
				return item;
			}
		});
	};
	
	var getColumnIndex = function(columns, colName) {
		var colIndex = 0;
		
		$.each(columns, function(index, item) {
			if (item.field == colName) {
				colIndex = index;
				return false;
			}
		});
		
		return colIndex;
	};
	
	return {
       
       	// Sets the focus to a specific cell on a Kendo Grid
       	EditCell: function (gridId, rowIndex, colIndex) {
			var grid = kendo.widgetInstance($('#' + gridId));
    		grid.closeCell();

    		setTimeout(function() {
        		//var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:eq('+colIndex+')');
        		var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:visible').filter('td:eq('+colIndex+')');
        		var input = cell.find('input');
        		
        		try {
        			grid.editCell(cell);
        		}
        		catch(e) {
        		}

        		if (cell.find('.k-numerictextbox').length > 0) {
					input.addClass("kndy-text-right");
					input.on('focus', function() {
						var that = $(this);
						setTimeout(function() {
							that.select();
						});
					});
				}
				else if (cell.find('.k-dropdown').length > 0) {
					input = cell.find('.k-dropdown').focus();
							
					input.keydown(function(e) {
						if ($.inArray(e.keyCode, specialKeys) >= 0) {
							e.stopImmediatePropagation();
						}
					});
				} else {
					input.select();
				}
    		}, 10); 
		},
		
		// Navigates focus to the next cell on a Kendo Grid
		NavigateRight: function (gridId) {
			var grid = kendo.widgetInstance($('#' + gridId));
       		var cell = grid.editable.element;
       		
       		if (cell) {
       			grid.closeCell();
            	grid.editCell(cell.next());
       		}
		},
		
		// Navigates focus to the previous cell on a Kendo Grid
		NavigateLeft: function (gridId) {
			var grid = kendo.widgetInstance($('#' + gridId));
       		var cell = grid.editable.element;
       		
       		if (cell) {
       			grid.closeCell();
            	grid.editCell(cell.prev());
       		}
		},
		
		// Navigates focus to the top cell on a Kendo Grid
		NavigateUp: function (gridId) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var cellCoordinates = getCellCoordinates(gridId);
       		var rowIndex = cellCoordinates.RowIndex;
       		var colIndex = cellCoordinates.ColumnIndex;
       		
			this.EditCell(gridId, rowIndex - 1, colIndex);
		},
		
		// Navigates focus to the bottom cell on a Kendo Grid
		NavigateDown: function (gridId) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var cellCoordinates = getCellCoordinates(gridId);
       		var rowIndex = cellCoordinates.RowIndex;
       		var colIndex = cellCoordinates.ColumnIndex;
       		
			this.EditCell(gridId, rowIndex + 1, colIndex);
		},
		
		// Deletes a row on a Kendo Grid
		DeleteRow: function (gridId, rowIndex) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var dataItem = grid.dataItem($(row));
			
			grid.dataSource.remove(dataItem);
		},
		
		// Gets the active/editable cell coordinates on a Kendo Grid
		GetActiveCellCoordinates: function (gridId) {
			var cellCoordinates = getCellCoordinates(gridId);
       		
       		return JSON.stringify(cellCoordinates);
		},
		
		// Gets the total row count on a Kendo Grid
       	GetRowCount: function (gridId) {
       		var grid = kendo.widgetInstance($('#' + gridId));
       		
       		return grid.dataSource.total();
       	},
       	
       	// Gets the total column count on a Kendo Grid (excluding hidden columns)
       	GetColumnCount: function (gridId) {
       		var grid = kendo.widgetInstance($('#' + gridId));
       		var columns = getVisibleColumns(grid.columns);
       		
       		return columns.length;
       	},
       	
       	// Gets the value for a given column index on a Kendo Grid
		GetValueByColumnIndex: function (gridId, rowIndex, colIndex) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var columns = getVisibleColumns(grid.columns);
			var dataItem = grid.dataItem(row);
			var fieldName = columns[colIndex].field;
			
			return (dataItem && fieldName) ? dataItem.get(fieldName) : null;
       	},
       	
       	// Gets the value for a given column name on a Kendo Grid
		GetValueByColumnName: function (gridId, rowIndex, colName) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var dataItem = grid.dataItem(row);
			
			return (dataItem && colName) ? dataItem.get(colName) : null;
       	},
       	
       	// Sets the value for a given column index on a Kendo Grid
		SetValueByColumnIndex: function (value, gridId, rowIndex, colIndex, type) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var columns = getVisibleColumns(grid.columns);
			var fields = grid.dataSource.options.schema.model.fields;
			var dataItem = grid.dataItem(row);
			var fieldName = columns[colIndex].field;
			var activeCell = grid.editable;
			var editcellIndex = grid.element.find("th[data-field = '" + fieldName + "']").index();
			
			if (activeCell) {
				grid.closeCell();
			}
			
			if (dataItem && fieldName) {
				if (type == 'reference') {
					grid.editCell($('#' + gridId + ' td:eq('+editcellIndex+')'));
					dataItem.set(fieldName, value.Id);
					dataItem.set(fieldName.replace('__c', '__r'), value);
					$('input[name="'+fieldName+'"]').trigger('blur'); 
				}
				else if (type == 'date' || type == 'datetime') {
					dataItem.set(fieldName, new Date(value));
				}
				else {
					dataItem.set(fieldName, value);
				}
			}
			
			if (activeCell) {
				try {
        			grid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
       	},
       	
       	// Sets the value for a given column name on a Kendo Grid
		SetValueByColumnName: function (value, gridId, rowIndex, colName, type) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var fields = grid.dataSource.options.schema.model.fields;
			var dataItem = grid.dataItem(row);
			var activeCell = grid.editable;
			
			if (activeCell) {
				grid.closeCell();
			}
			
			if (dataItem && colName) {
				if (type == 'reference') {
					dataItem.set(colName, value.Id);
					dataItem.set(colName.replace('__c', '__r'), value);
				}
				else if (type == 'date' || type == 'datetime') {
					dataItem.set(colName, new Date(value));
				}
				else {
					dataItem.set(colName, value);
				}
			}
			
			if (activeCell) {
				try {
        			grid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
       	},
       	
       	// Gets the display text for a given column index on a Kendo Grid
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.GetTextByColumnIndex('GridAddManageContractLines', 0, 1)
       	***/
		GetTextByColumnIndex: function (gridId, rowIndex, colIndex) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var activeCell = grid.editable;
			
			if (activeCell) {
				grid.closeCell();
			}
			
			var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:not(.k-hierarchy-cell):visible').filter('td:eq('+colIndex+')');
			
			returnValue = (cell) ? cell.text() : null;
			
			if (activeCell) {
				try {
        			grid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
			
			return returnValue;
       	},
       	
       	// Gets the display text for a given column name on a Kendo Grid
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.GetTextByColumnName('GridAddManageContractLines', 0, 'Line__c')
       	***/
		GetTextByColumnName: function (gridId, rowIndex, colName) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var activeCell = grid.editable;
			
			if (activeCell) {
				grid.closeCell();
			}
			
			var columns = getVisibleColumns(grid.columns);
			var colIndex = getColumnIndex(columns, colName);
			var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:not(.k-hierarchy-cell):visible').filter('td:eq('+colIndex+')');
			
			returnValue = (cell) ? cell.text() : null;
			
			if (activeCell) {
				try {
        			grid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
			
			return returnValue;
       	},
       	
       	// Sets the value for a given column index on a Kendo Detail Grid
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.SetDetailValueByColumnIndex(51, 'GridAddManageContractLines', 0, 'grid-tier-pricing', 0, 0)
       	***/
		SetDetailValueByColumnIndex: function (value, masterGridId, masterRowIndex, detailGridId, detailRowIndex, detailColIndex, type) {
			var masterGrid = kendo.widgetInstance($('#' + masterGridId));
			var masterRow = $('#' + masterGridId).find('tbody tr:eq(' + masterRowIndex + ')');
			
			masterGrid.expandRow(masterRow);
			
			var detailGrid = kendo.widgetInstance(masterRow.next('tr.k-detail-row').find('.' + detailGridId)); 
			var detailRow = detailGrid.table.find('tbody tr:eq(' + detailRowIndex + ')');
			
			var columns = getVisibleColumns(detailGrid.columns);
			var fields = detailGrid.dataSource.options.schema.model.fields;
			var dataItem = detailGrid.dataItem(detailRow);
			var fieldName = columns[detailColIndex].field;
			var activeCell = detailGrid.editable;
			
			if (activeCell) {
				detailGrid.closeCell();
			}
			
			if (dataItem && fieldName) {
				if (type == 'reference') {
					dataItem.set(fieldName, value.Id);
					dataItem.set(fieldName.replace('__c', '__r'), value);
				}
				else if (type == 'date' || type == 'datetime') {
					dataItem.set(fieldName, new Date(value));
				}
				else {
					dataItem.set(fieldName, value);
				}
			}
			
			if (activeCell) {
				try {
        			detailGrid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
       	},
       	
       	// Sets the value for a given column name on a Kendo Detail Grid
       	/***
       	*** SeleniumUtils.KendoGridUtils.SetDetailValueByColumnName(51, 'GridAddManageContractLines', 0, 'grid-tier-pricing', 0, 'Tier_1_Max__c')
       	***/
		SetDetailValueByColumnName: function (value, masterGridId, masterRowIndex, detailGridId, detailRowIndex, detailColName, type) {
			var masterGrid = kendo.widgetInstance($('#' + masterGridId));
			var masterRow = $('#' + masterGridId).find('tbody tr:eq(' + masterRowIndex + ')');
			
			masterGrid.expandRow(masterRow);
			
			var detailGrid = kendo.widgetInstance(masterRow.next('tr.k-detail-row').find('.' + detailGridId)); 
			var detailRow = detailGrid.table.find('tbody tr:eq(' + detailRowIndex + ')');
			
			var columns = getVisibleColumns(detailGrid.columns);
			var fields = detailGrid.dataSource.options.schema.model.fields;
			var dataItem = detailGrid.dataItem(detailRow);
			var activeCell = detailGrid.editable;
			
			if (activeCell) {
				detailGrid.closeCell();
			}
			
			if (dataItem && detailColName) {
				if (type == 'reference') {
					dataItem.set(detailColName, value.Id);
					dataItem.set(detailColName.replace('__c', '__r'), value);
				}
				else if (type == 'date' || type == 'datetime') {
					dataItem.set(detailColName, new Date(value));
				}
				else {
					dataItem.set(detailColName, value);
				}
			}
			
			if (activeCell) {
				try {
        			detailGrid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
       	},
       	
       	// Gets the display text for a given column index on a Kendo Detail Grid
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.GetDetailTextByColumnIndex('GridAddManageContractLines', 0, 'grid-tier-pricing', 0, 0)
       	***/
		GetDetailTextByColumnIndex: function (masterGridId, masterRowIndex, detailGridId, detailRowIndex, detailColIndex) {
			var masterGrid = kendo.widgetInstance($('#' + masterGridId));
			var masterRow = $('#' + masterGridId).find('tbody tr:eq(' + masterRowIndex + ')');
			
			masterGrid.expandRow(masterRow);
			
			var detailGrid = kendo.widgetInstance(masterRow.next('tr.k-detail-row').find('.' + detailGridId)); 
			var detailRow = detailGrid.table.find('tbody tr:eq(' + detailRowIndex + ')');
			var activeCell = detailGrid.editable;
			
			if (activeCell) {
				detailGrid.closeCell();
			}
			
			var cell = detailRow.find('td:not(.k-hierarchy-cell):visible').filter('td:eq('+detailColIndex+')');			
			var returnValue = (cell) ? cell.text() : null;
			
			if (activeCell) {
				try {
        			detailGrid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
			
			return returnValue;
       	},
       	
       	// Gets the display text for a given column name on a Kendo Detail Grid
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.GetDetailTextByColumnName('GridAddManageContractLines', 0, 'grid-tier-pricing', 0, 'Tier_1_Max__c')
       	***/
		GetDetailTextByColumnName: function (masterGridId, masterRowIndex, detailGridId, detailRowIndex, detailColName) {
			var masterGrid = kendo.widgetInstance($('#' + masterGridId));
			var masterRow = $('#' + masterGridId).find('tbody tr:eq(' + masterRowIndex + ')');
			
			masterGrid.expandRow(masterRow);
			
			var detailGrid = kendo.widgetInstance(masterRow.next('tr.k-detail-row').find('.' + detailGridId)); 
			var detailRow = detailGrid.table.find('tbody tr:eq(' + detailRowIndex + ')');
			var columns = getVisibleColumns(detailGrid.columns);
			var detailColIndex = getColumnIndex(columns, detailColName);
			var activeCell = detailGrid.editable;
			
			if (activeCell) {
				detailGrid.closeCell();
			}
			
			var cell = detailRow.find('td:not(.k-hierarchy-cell):visible').filter('td:eq('+detailColIndex+')');			
			var returnValue = (cell) ? cell.text() : null;
			
			if (activeCell) {
				try {
        			detailGrid.editCell(activeCell);
        		}
        		catch(e) {
        		}
			}
			
			return returnValue;
       	},
       	
       	// Expands a grid row for a given row index
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.ExpandRow('GridPurchaseOrderReceive', 0)
       	***/
       	ExpandRow: function (gridId, rowIndex) {
       		var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			
			grid.expandRow(row);
       	},
       	
       	// Collapses a grid row for a given row index
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.CollapseRow('GridPurchaseOrderReceive', 0)
       	***/
       	CollapseRow: function (gridId, rowIndex) {
       		var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			
			grid.collapseRow(row);
       	},
       	
       	// Search lookup based on a given search term
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.SearchLookup('po', 'InvoiceLinesGrid', 0, 'invoiceLine.Purchase_Order__c')
       	***/
       	SearchLookup: function (value, gridId, rowIndex, colName) {
			var grid = kendo.widgetInstance($('#' + gridId));
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var columns = getVisibleColumns(grid.columns);
			var colIndex = getColumnIndex(columns, colName);
			var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:not(.k-hierarchy-cell):visible').filter('td:eq('+colIndex+')');
			
			try {
    			grid.editCell(cell);
    		}
    		catch(e) {
    		}
    		
			var input = cell.find('input[name="' + colName + '"]');
			
			if (input && input.length > 0) {
				var lookup = kendo.widgetInstance(input);
				
				input.val(value);
				lookup.search();
				
				lookup.bind('dataBound', function (e) {
					this.select(this.ul.children().eq(0));
					this.close();
					input.trigger('change');
				});
			}
		},
       	
       	// Search current date from a datepicker
       	/***
       	*** Usage: SeleniumUtils.KendoGridUtils.SelectDate('InvoiceLinesGrid', 0, 'invoiceLine.Purchase_Order__c')
       	***/
       	SelectDate: function (gridId, rowIndex, colName) {
       		var grid = kendo.widgetInstance($('#' + gridId));			
			var row = $('#' + gridId).find('tbody tr:eq(' + rowIndex + ')');
			var columns = getVisibleColumns(grid.columns);
			var colIndex = getColumnIndex(columns, colName);
			var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:not(.k-hierarchy-cell):visible').filter('td:eq('+colIndex+')');
			var dataItem = grid.dataItem(row);
			
			try {
    			grid.editCell(cell);
    		}
    			catch(e) {
    		}
    		
			var input = cell.find('input[name="' + colName + '"]');
			
			if (input && input.length > 0) {
				var datePicker = kendo.widgetInstance(input);
				
				datePicker.open();
				dataItem.set(colName, datePicker.dateView.calendar.current());
				datePicker.close();
			}
       	}
       	
       	/*
       	Set: function (gridId, rowIndex, colIndex) {
       		setTimeout(function(){
				
    		}, 10); 
       	},
       
       	SetFocus: function (gridId, rowIndex, colIndex) {
       		var grid = kendo.widgetInstance($('#' + gridId));
    		grid.closeCell();

    		setTimeout(function() {
        		var cell = $('#' + gridId).find('tbody tr:eq('+rowIndex+') td:eq('+colIndex+')');
        		var input = cell.find('input');
        		grid.editCell(cell);
        		
        		if (cell.find('.k-numerictextbox').length > 0) {
					input.addClass("kndy-text-right");
					input.on('focus', function() {
						var that = $(this);
						setTimeout(function() {
							that.select();
						});
					});
					input.focus();
				}
				else if (cell.find('.k-dropdown').length > 0) {
					input = cell.find('.k-dropdown').focus();
							
					input.keydown(function(e) {
						if ($.inArray(e.keyCode, specialKeys) >= 0) {
							e.stopImmediatePropagation();
						}
					});
				} else {
					input.select();
				}
    		}, 10);
       	}*/
    };
}();

// Kendo DetailList utility functions for Selenium automation testing
SeleniumUtils.KendoDetailListUtils = function() {
	var specialKeys = [kendo.keys.UP, kendo.keys.DOWN];
	
	return {
       
       	// Sets the focus to a specific cell on a Kendo DetailList
       	/***
       	*** Usage: SeleniumUtils.KendoDetailListUtils.SetFocus('InvoiceHeaderDetailList', 'Invoice_Amount__c')
       	***/
       	SetFocus: function (detailListId, fieldName) {
			var detailList = $('#' + detailListId).data('kendoDetailList');

    		setTimeout(function() {
        		var input = detailList.element.find('input[name="' + fieldName + '"], select[name="' + fieldName + '"], textarea[name="' + fieldName + '"]');
        		
        		if (input.is('select')) {
					input.focus();
        		}
        		else {
	        		input.on('focus', function() {
						var that = $(this);
						setTimeout(function() {
							that.select();
						});
					});
					
					input.focus();
				}
    		}, 10); 
		},
		
       	// Gets the value for a given field name
       	/***
       	*** Usage: SeleniumUtils.KendoDetailListUtils.GetValueByFieldName('InvoiceHeaderDetailList', 'Invoice_Amount__c')
       	***/
		GetValueByFieldName: function (detailListId, fieldName) {
			var detailList = $('#' + detailListId).data('kendoDetailList');
			var value = (detailList && detailList.data) ? detailList.data.get(fieldName) : null;
			
			if (value && (value instanceof Date)) {
				return $('#' + fieldName).val();
			}
			else {
				return value;
			}
       	},
       	
       	// Sets the value for a given field name
       	/***
       	*** Usage: SeleniumUtils.KendoDetailListUtils.SetValueByFieldName('InvoiceHeaderDetailList', 'Invoice_Amount__c', '55.45')
       	***/
		SetValueByFieldName: function (detailListId, fieldName, value, type) {
			var detailList = $('#' + detailListId).data('kendoDetailList');
			
			if (detailList && fieldName) {
				if (type == 'reference') {
					detailList.data.set(fieldName, value.Id);
					detailList.data.set(fieldName.replace('__c', '__r'), value);
				}
				else if (type == 'date' || type == 'datetime') {
					detailList.data.set(fieldName, new Date(value));
				}
				else {
					detailList.data.set(fieldName, value);
				}
			}
       	},
       	
       	// Search lookup based on a given search term
       	/***
       	*** Usage: SeleniumUtils.KendoDetailListUtils.SearchLookup('po', 'InvoiceHeaderDetailList', 'Purchase_Order__c')
       	***/
       	SearchLookup: function (value, detailListId, fieldName) {
       		var referenceFieldName = fieldName.replace('__c', '__r') + '.Name';
			var detailList = $('#' + detailListId).data('kendoDetailList');
			var input = detailList.element.find('input[name="' + referenceFieldName + '"]');
			
			if (input) {
				var lookup = kendo.widgetInstance(input);
				
				input.val(value);
				lookup.search();
				
				lookup.bind('dataBound', function (e) {
					var dataItem = (this.dataSource.total() > 0) ? this.dataSource.data()[0] : null;
					
					if (dataItem) {
						detailList.data.set(fieldName, dataItem.value);
						detailList.data.set(fieldName.replace('__c', '__r'), { Id: dataItem.value, Name: dataItem.text });
					}
					
					this.close();
				});
			}
		},
		
       	// Search current date from a datepicker
       	/***
       	*** Usage: SeleniumUtils.KendoDetailListUtils.SelectDate('InvoiceHeaderDetailList', 'Date_Invoiced__c')
       	***/
       	SelectDate: function (detailListId, fieldName) {
       		var detailList = $('#' + detailListId).data('kendoDetailList');
			var input = detailList.element.find('input[name="' + fieldName + '"]');
			
			if (input && input.length > 0) {
				var datePicker = kendo.widgetInstance(input);
				
				datePicker.open();
				detailList.data.set(fieldName, datePicker.dateView.calendar.current());
				datePicker.close();
			}
       	}
    };
}();

// Kendo utility functions for Selenium automation testing
SeleniumUtils.KendoUtils = function() {
	var specialKeys = [kendo.keys.UP, kendo.keys.DOWN];
	
	return {
	
       	// Gets the value from KendoDatePicker for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetDatePickerValue($('#FromTransDate'))
       	***/
		GetDatePickerValue: function (selector) {
			var datePicker = $(selector).data('kendoDatePicker');
			
			return $(selector).val();
       	},
       	
       	// Sets the value to KendoDatePicker for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.SetDatePickerValue($('#FromTransDate'), '1/1/2015')
       	***/
		SetDatePickerValue: function (selector, value) {
			var datePicker = $(selector).data('kendoDatePicker');

			datePicker.value(value);
       	},
       	
       	// Gets the value from KendoDateTimePicker for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetDateTimePickerValue($('#FromTransDate'))
       	***/
		GetDateTimePickerValue: function (selector) {
			var dateTimePicker = $(selector).data('kendoDateTimePicker');
			
			return $(selector).val();
       	},
       	
       	// Sets the value to KendoDateTimePicker for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.SetDateTimePickerValue($('#FromTransDate'), '1/1/2015 12:00 AM')
       	***/
		SetDateTimePickerValue: function (selector, value) {
			var dateTimePicker = $(selector).data('kendoDateTimePicker');

			dateTimePicker.value(value);
       	},
       	
       	// Gets the value from KendoDropDownList for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetDropDownListValue($('#TransDateFilterOperator'))
       	***/
		GetDropDownListValue: function (selector) {
			var dropDownList = $(selector).data('kendoDropDownList');
			
			return (dropDownList) ? dropDownList.value() : null;
       	},
       	
       	// Sets the value to KendoDropDownList for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.SetDropDownListValue($('#TransDateFilterOperator'), 'ytd')
       	***/
		SetDropDownListValue: function (selector, value) {
			var dropDownList = $(selector).data('kendoDropDownList');

			dropDownList.value(value);
       	},
       	
       	// Gets the value from KendoComboBox for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetComboBoxValue($('#itemFilter'))
       	***/
		GetComboBoxValue: function (selector) {
			var comboBox = $(selector).data('kendoComboBox');
			
			return (comboBox) ? comboBox.value() : null;
       	},
       	
       	// Gets the text from KendoComboBox for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetComboBoxText($('#itemFilter'))
       	***/
		GetComboBoxText: function (selector) {
			var comboBox = $(selector).data('kendoComboBox');
			
			return (comboBox) ? comboBox.text() : null;
       	},
       	
       	// Sets the value/text to KendoComboBox for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.SetComboBoxValue($('#itemFilter'), { Id: 'a0zo0000000erQFAAY', Name: 'Item-3' })
       	***/
		SetComboBoxValue: function (selector, value) {
			var comboBox = $(selector).data('kendoComboBox');

			comboBox.value(value.Id);
			comboBox.text(value.Name);
       	},
       	
       	// Gets the value from KendoMultiSelect for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetMultiSelectValue($('#itemFilter'))
       	***/
		GetMultiSelectValue: function (selector) {
			var multiSelect = $(selector).data('kendoMultiSelect');
			
			return (multiSelect) ? multiSelect.value() : null;
       	},
       	
       	// Gets the text from KendoMultiSelect for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetMultiSelectText($('#itemFilter'))
       	***/
		GetMultiSelectText: function (selector) {
			var multiSelect = $(selector).data('kendoMultiSelect');
			
			return (multiSelect && multiSelect.dataItems()) ? _.pluck(multiSelect.dataItems(), 'text') : null;
       	},
       	
       	// Sets the value/text to KendoMultiSelect for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.SetMultiSelectValue($('#itemFilter'), ["a0zo0000000erQDAAY", "a0zo0000000erQEAAY", "a0zo0000000erQFAAY"])
       	***/
		SetMultiSelectValue: function (selector, value) {
			var multiSelect = $(selector).data('kendoMultiSelect');

			multiSelect.value(value);
       	},
       	
       	// Gets the value from KendoAutoComplete for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetAutoCompleteValue($('#Company__c'))
       	***/
		GetAutoCompleteValue: function (selector) {
			var autoComplete = $(selector).data('kendoAutoComplete');
			var dataItem = (autoComplete.dataSource.total() > 0) ? _.where(autoComplete.dataSource.data(), { text: autoComplete.value() }) : null;
			
			return (dataItem && dataItem.length > 0) ? dataItem[0].value : null;
       	},
       	
       	// Gets the text from KendoAutoComplete for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.GetAutoCompleteText($('#Company__c'))
       	***/
		GetAutoCompleteText: function (selector) {
			var autoComplete = $(selector).data('kendoAutoComplete');
			
			return (autoComplete) ? autoComplete.value() : null;
       	},
       	
       	// Sets the value/text to KendoAutoComplete for a given element
       	/***
       	*** Usage: SeleniumUtils.KendoUtils.SetAutoCompleteValue($('#Company__c'), { Id: 'a0So0000001bxfyEAA', Name: 'Kenandy_PTP' })
       	***/
		SetAutoCompleteValue: function (selector, value) {
			var autoComplete = $(selector).data('kendoAutoComplete');

			autoComplete.dataSource.add({ "value": value.Id, "text": value.Name });
			autoComplete.value(value.Name);
       	}
	};
}();
