(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global $ */
var loadGrid = require( "./src/views/AgreementGrid" );
var loadDetailGrid = require( "./src/views/AgreementLineGrid" );
var drawTreeList = require( "./src/views/AgreementLineTreeList" );
var utility = require( "./src/utils/AgreementViewHelper" );

$( document ).on( "AgreementViewReady", function( e ) {
     //setting width of grids as per the parent container outerWidth
     var sidebarWidth = $( "#sidebarCell" ).outerWidth() ? $( "#sidebarCell" ).outerWidth() : 0;
     var tabBarWidth = $( "#tabBar" ).outerWidth();
     var windowWidth = $( window ).outerWidth();
     var margins = ( ( windowWidth - tabBarWidth ) / 2 );
     
     if ( tabBarWidth ) {
         $( ".bodyDiv" ).outerWidth( tabBarWidth - sidebarWidth - margins  );
         $( "#mainpage" ).outerWidth( tabBarWidth - sidebarWidth - margins );
     }

	 loadGrid();
	 utility.loadpanelBar();

        var grid = $( "#promotions" ).data( "kendoGridActionList" );
     $('#promotions').width($('.grid-container').width());

} );

$( document ).on( "redrawTreeList", function( e ) {
	var grid = $( "#promotions" ).data( "kendoGridActionList" );
	var treeList = $( "#pprod" ).data( "kendoTreeList" );
	
	treeList.destroy();
	$( "#pprod" ).empty();
	drawTreeList( grid.dataSource._data[0] );
} );

},{"./src/utils/AgreementViewHelper":7,"./src/views/AgreementGrid":10,"./src/views/AgreementLineGrid":11,"./src/views/AgreementLineTreeList":12}],2:[function(require,module,exports){
/* global $ */
module.exports = function( ele, grid, page ) {
    
    var messageElement = grid.element
        .closest( "div.grid-container" )
        .find( "div.grid-message:first" );
        
	var actionDropdownVal = $( "#" + ele + "ActionDropdown" ).val(),
        actionConfig = ele + "ActionConfig";

    var selectedActionConfig = page[actionConfig][actionDropdownVal];

    var messageCreateSalesOrder = 'This action can not be performed on Draft agreement status';
    var pgrid = $('#promotions').data('kendoGridActionList');
    var statusvalue = pgrid.dataItem(pgrid.select()) ? pgrid.dataItem(pgrid.select()).Status__c : null;

	if ( typeof selectedActionConfig != "undefined" ) {
		var divId = selectedActionConfig.div;
        var awindow = $( "#" + divId );

		awindow.empty();
		awindow.append( "<div id='" + divId + "window'></div>" );

        var actionWindow = $( "#" + divId + "window" );
        var onActionWindowClose = function() {
            $( this.element ).empty();
            if ( grid ) {
                grid.dataSource._destroyed = [];
                grid.dataSource.read();
            }
        };
        if( selectedActionConfig.content.indexOf( "id=" ) == -1 ) {
            if( ele == "promo" ) {
                KenandyErp.Message( "Please Select an Agreement", messageElement );
            }
            if( ele == "promoProd" ) {
                KenandyErp.Message( "Please Select an Agreement Line", messageElement );
            }
        }

        //KNDY-16165 - Skip 'promoProdActionConfig' - Actions from line grid and this validation applies only on agreement header grid
        else if(statusvalue.toLowerCase() != 'approved' && statusvalue != null && actionDropdownVal.toLowerCase() != 'cloneagreement' && actionConfig != 'promoProdActionConfig'){
             KenandyErp.Message( messageCreateSalesOrder, messageElement );
        }
        
        else {
            actionWindow.kendoWindow( {
                width: selectedActionConfig.width, height: selectedActionConfig.height,
                iframe: true, modal: true,
                title: selectedActionConfig.title,
                content: selectedActionConfig.content,
                close: onActionWindowClose,
                deactivate: function() {
                        this.destroy();
                }
            } );
            actionWindow.data( "kendoWindow" ).center().open();  
        }
        
    }
};

},{}],3:[function(require,module,exports){
/* global _ */
/* global $ */
/* global Visualforce */
/* global KenandyErp */
/* global Serializer */

module.exports = function( e ) {
    
    var self = this;
    var grid = self.grid;
    var options = self.options;

    var messageElement = grid.element
        .closest( "div.grid-container" )
        .find( "div.grid-message:first" );

    if ( grid.editable && !grid.editable.validatable.validate() ) {
        e.preventDefault();
        return false;
    }

    var currentData = grid.dataSource.data();
    var updatedRows = [];
    var newRows = [];
          
    $.each( currentData, function( index, item ) {

        if ( item.id === "" || item.dirty ) {
            var isNewRow = ( item.id === "" );
            item = item.toJSON();
            item = Serializer.ConvertToSFDCDate( item, { dateFields: options.dateFields } );
            if ( isNewRow ) {
                delete item.Id;     
                newRows.push( item );
            } else {
                updatedRows.push( item );
            }
        }
    } );

    var deletedRows = $.map( grid.dataSource._destroyed, function( item, index ) {
        item = item.toJSON();
        item = Serializer.ConvertToSFDCDate( item, { dateFields: options.dateFields } );
        return item;
    } );

    if ( newRows.length === 0 && updatedRows.length === 0 && deletedRows.length === 0 ) {
        KenandyErp.Message( "No Records Changed", KenandyErp.MessageType.Info, messageElement );
        return;
    }

    if ( updatedRows.length > 0 ) {
        updatedRows = Serializer.ParameterMap( updatedRows );
    }

    if ( newRows.length > 0 ) {
        newRows = Serializer.ParameterMap( newRows );
    }

    if ( deletedRows.length > 0 ) {
        deletedRows = Serializer.ParameterMap( deletedRows );
    }

    var changeListIds = _.union( _.pluck( updatedRows, "Id" ), _.pluck( deletedRows, "Id" ) );

    KenandyErp.BlockUI( grid.element );

    var dateFields = self.options.dateFields ? 
        _.pluck( self.options.dateFields, KenandyErp.KendoGridOptions.FieldInfo.Field ) : 
        null;
     
    Visualforce.remoting.Manager.invokeAction(
        options.saveAction,   
        updatedRows,
        newRows,
        deletedRows,
        dateFields,
        function( result, event ) {
            KenandyErp.UnBlockUI( grid.element );    
            if ( event.type == 'exception' ) {
                KenandyErp.Message( event.message, KenandyErp.MessageType.Error, messageElement );
            } else {
                if ( result.success ) {
                    var newIds = _.difference( _.pluck( result.records, "Id" ), changeListIds );

                    // refresh the grid
                    grid.dataSource._destroyed = [];
                    grid.dataSource.read( { newIds: newIds } );
                    $( document ).trigger( "redrawTreeList" );
                    KenandyErp.Messages( result.messages, messageElement );
                } else {
                    KenandyErp.Messages( result.messages, messageElement );
                }
            }
        },
        { escape: false }
    );
};

},{}],4:[function(require,module,exports){
/* global $ */
/* global _ */
/* global AgreementViewComponent */
/* global Visualforce */
/* global KenandyErp */
/* global Serializer */
var utility = require( "../utils/AgreementViewHelper" );

module.exports = function( options, dateFields, context ) {

	var treeList = $( "#pprod" ).data( "kendoTreeList" );

    var columns = treeList.columns;

    var messageElement = treeList.element
        .closest( "div.grid-container" )
        .find( "div.grid-message:first" );

    var item = options.data.models[0];
    delete item.hasChildren;
    delete item.expanded;

    if ( context == "create" ) {
        delete item.agl.Id;
    }

    if ( context == "delete") {
        if (item.agl.Id == null || item.agl.Id.length == 0){
            return;
        }
    }
    item = Serializer.ConvertToSFDCDate( item, { dateFields: dateFields } );
    
    //Remove the extra attributes Kendo Grid creates for supporting wrapper classes
    for (var i = 0; i < columns.length; i++) {
        var name = columns[i].field;
		if (name && name.indexOf('.') != -1) {
		    delete item.agl[name];
		}
    }
    
    item.agl = utility.convert(item.agl);
    item.segments = utility.convert(item.segments);
    
    var hasNoSegments = $.isEmptyObject(item.segments)
    KenandyErp.BlockUI( treeList.element );

    dateFields = dateFields ?
         _.pluck( dateFields, KenandyErp.KendoGridOptions.FieldInfo.Field ) : 
         null;
         
    AgreementViewComponent.expandedRows = $.map($('[aria-expanded="true"]'), 
        function (row) {
            return $(row).data("uid");
    });
    
    item = _.pick(item, 'agl', 'segments');
    
    Visualforce.remoting.Manager.invokeAction(
        AgreementViewComponent.saveAgreementLinesAction,
        item,
        dateFields,
        context,
        function( result, event ) {
            KenandyErp.UnBlockUI( treeList.element );  
            if ( event.type == "exception" ) {
                KenandyErp.Message( event.message, KenandyErp.MessageType.Error, messageElement );
            } else {
                if ( result.success ) {
                    
                    treeList.one("dataBound", function () {
                    var rows = treeList.tbody.children().filter(function (idx, row) {
                            return $.inArray($(row).data("uid"), AgreementViewComponent.expandedRows) >= 0;
                        });
                    
                    for(var i = 0; i < rows.length; i++) {
                        treeList.expand(rows[i]);
                    }
                    });
                    treeList.dataSource._destroyed = [];
                    treeList.dataSource.read();
                    KenandyErp.Messages( result.messages, messageElement );
                } else {
                    KenandyErp.Messages( result.messages, messageElement  );
                }
            }
        },
        { escape: false }
    );
};

},{"../utils/AgreementViewHelper":7}],5:[function(require,module,exports){
/* global $ */
/* global AgreementViewComponent */
var dropDownAction = require( "../actions/DropdownActions" );
var AgreementLineSave = require( "../actions/GridSaveAction" );

module.exports = function( grid, isRefresh ) {
    $( grid.element ).find( ".grid-add-line-command" ).bind( "click", function( e ) {
        grid.addRow();
    } );

    // unbind grid save command
    grid.wrapper.off( "click", ".grid-save-line-command" );   

    // bind grid save command
    grid.wrapper.on( "click", ".grid-save-line-command", $.proxy( AgreementLineSave, {
        grid: grid,
        options: {
            saveAction: AgreementViewComponent.saveAgreementLinesAction,
            config: AgreementViewComponent.agreementLinesGridConfig,
            dateFields: AgreementViewComponent.agreementLineDateFields
        }
    } ) );

    $( grid.element ).find( ".grid-cancel-line-command" ).bind( "click", function( e ) {
        grid.cancelChanges();       // do the cancel work
        e.preventDefault();
    } );
       
    $( "#promoProdActionDropdown" ).kendoDropDownList( {
         optionLabel: "",
         dataTextField: "text",
         dataValueField: "value",
         dataSource: AgreementViewComponent.promodProdActionDatasource
     } );
    
    $( ".grid-view-options" ).kendoDropDownList( {
         dataTextField: "text",
         dataValueField: "value",
         dataSource: AgreementViewComponent.pprodGridViews,
         dataBound: function(e){
            //Show default grid view
            fieldNames = _.values(_.pick(AgreementViewComponent.pprodGridViewFields, this.dataSource._data[0].value))[0];

            DisplayViewFields(fieldNames);
           
        },
        change: function(e) {  

            var fieldNames = AgreementViewComponent.agreementLineFieldNames;

            for (var fld in fieldNames) {
                grid.hideColumn(fieldNames[fld]);
            }

            fieldNames = _.values(_.pick(AgreementViewComponent.pprodGridViewFields, this.value()))[0];

            DisplayViewFields(fieldNames);
         
        }
     } );
    
    function DisplayViewFields(fieldNames) {
        var segmentPrefix = 'agl.Accounting_Segment__r.';
        var i = -1;//Starting index of View columns(After checkbox, errors and id)
        for (fld = 0; fld < fieldNames.length; fld++) { 
            i = i + 1;
            //Get column index for field name
            var colIndex = GetColumnIndexFromName(grid, fieldNames[fld]);
            
            if(fieldNames[fld].length >= segmentPrefix.length && fieldNames[fld].indexOf(segmentPrefix) > -1){

                //Change the AGL fields to segments fields
                var segmentFieldName = 'segments.' + fieldNames[fld].substring(fieldNames[fld].indexOf(segmentPrefix) + segmentPrefix.length);

                //Get the column index for segment fields
                colIndex = GetColumnIndexFromName(grid, segmentFieldName);
            } 

            //Show columns
            if(fieldNames[fld] != 'agl.Id'){
                //Re-order columns based on the field set order
                grid.reorderColumn(i, grid.columns[colIndex]);
                grid.showColumn(i);
            }
        }
      
    }

    function GetColumnIndexFromName(grid, fieldName) {
        var index = -1;
        var columns = grid.columns;
        if (columns.length > 0) {
            for (var i = 0; i < columns.length; i++) {
                if (columns[i].field == fieldName) { // columns[i].title -- You can also use title property here but for this you have to assign title for all columns
                    index = i;
                }
            }
        }
        return index;
    }


    $( grid.element ).find( ".k-grid-promoProdActionGo" ).bind( "click", function( e ) {
        if ( !isRefresh ) {
            dropDownAction( "promoProd", grid, AgreementViewComponent );
        }
         e.stopImmediatePropagation()
    } );
};

},{"../actions/DropdownActions":2,"../actions/GridSaveAction":3}],6:[function(require,module,exports){
/* global $ */
/* global AgreementViewComponent */
var dropDownAction = require( "../actions/DropdownActions" );
var AgreementSave = require( "../actions/GridSaveAction" );

module.exports = function( grid, isRefresh ) {

    $( grid.element ).find( ".grid-add-agreement-command" ).bind( "click", function( e ) {
        grid.addRow();       // do the cancel work
        e.preventDefault();
    } );

     // unbind grid save command
    grid.wrapper.off( "click", ".grid-save-agreement-command" );

    // bind grid save command
    grid.wrapper.on( "click", ".grid-save-agreement-command", $.proxy( AgreementSave, {
        grid: grid,
        options: {
            saveAction: AgreementViewComponent.saveAgreementAction,
            config: AgreementViewComponent.agreementGridConfig,
            dateFields: AgreementViewComponent.agreementDateFields()
        }
    } ) );

    $( grid.element ).find( ".grid-cancel-agreement-command" ).bind( "click", function( e ) {
        grid.cancelChanges();       // do the cancel work
        e.preventDefault();
    } );
    
    $( "#promoActionDropdown" ).kendoDropDownList( {
         optionLabel: "",
         dataTextField: "text",
         dataValueField: "value",
         dataSource: AgreementViewComponent.promotionActionDatasource
     } );   
     
    $( grid.element ).find( ".k-grid-promoActionGo" ).bind( "click", function( e ) {
        if ( !isRefresh ) {
            dropDownAction( "promo", grid, AgreementViewComponent );
        }
        e.stopImmediatePropagation()
    } );
};

},{"../actions/DropdownActions":2,"../actions/GridSaveAction":3}],7:[function(require,module,exports){
/* global Serializer */
/* global AgreementViewComponent */
/* global $ */
var AgreementToolbar = require( "../toolbars/AgreementToolbar" );
var AgreementLineToolbar = require( "../toolbars/AgreementLineToolbar" );

module.exports = ( function() {

	function isEditable( fieldName, model ) {

		// KNDY-4651 no change to type field once the record is saved
	    if ( fieldName == "Type__c" && model.isNew() !== true ) {
			return false;
		} 
	    return true;
	}

	return {
		loadpanelBar: function() {
			$( "#panelBar" ).kendoPanelBar( {
		        expandMode: "multiple"
		    } );
		},

		checkBeforeEdit: function( e ) {
			var columnIndex = this.cellIndex( e.container );
		    var fieldName = this.thead.find( "th" ).eq( columnIndex ).data( "field" );      
		    if ( !isEditable( fieldName, e.model ) ) {
		        e.preventDefault();
		    }
		},

		elementInit: function( ele, isRefresh ) {
			if ( ele.element.context.id == "promotions" ) {               

		        //var row = grid.body.firstChild; // default to first row
		        //console.log(row);
		        //console.log(grid);
		        //grid.select(row);
		        AgreementToolbar( ele, false );
		    } else if ( ele.element.context.id == "pprod" ) {
		        AgreementLineToolbar( ele, false );
		    }
		},

		getAgreementButtons: function() {
			var button = {};

			if ( AgreementViewComponent.planId ) {
				button = { 
					name: "addAgreement", 
					text:"", 
					template: "<input type='button' value='Add New' class='btn grid-add-agreement-command' />" 
				};
			} else {
				button = { 
					name: "addAgreement", 
					text:"", 
					template: "<input type='hidden' value='Add New' class='btn grid-add-agreement-command' />" 
				};
			}
			return button;
		},
		
		reapplyNamespace: function(data, namespace) { 
			// reapply the namespace from json object, recursive
			
			for (var key in data) {
		    	if (typeof key === "string") {
					
					if(key !== "Id" && key !== "Name") {
						var newKey = key.replace(/^/, namespace);
			           	if (newKey !== key) {
			            	data[newKey] = data[key];
			               	delete(data[key]);
			           	}
			           
			           	if (typeof data[newKey] === "object") {
			           		this.reapplyNamespace(data[newKey], namespace);
			           	}
					}
		        }
		    }
		},
		
		convert: function(values) {
	    	for (var key in values) {
	    		// Removes all __r and __custom properties from the record getting saved, as we can't use them in DML
				if (((/__r/i.test(key))) || (/__custom$/i.test(key))) {
	            	delete values[key];
				}
				else if ((/__r/i.test(key))) {	// Remove all __r if the Id is null
					if (values[key] && $.isPlainObject(values[key]) && !values[key].Id) {
						delete values[key];
					}
				}
				
	        	var value = values[key];
	
	            if (value instanceof Date) {
	            	values[key] = (value) ? Date.parse(value) : null;
				}
			}
	        
			return values;
		},
        
        getFieldList: function(fields) {
            var fieldList = JSON.parse(fields);
            $.each(fieldList, function() {
                this.width = this.width ? this.width : '100px';
                //To add a scroll bar, set the width of each column in pixels - KNDY-10623	
            });
            return fieldList;
        },

        GetAGLineDetailsFromProductRef: function(e) {
            debugger;
			var self = this;
            var grid = this.grid;
            var options = self.grid.options;
            var cell = grid.element;
            var row = $(e.target).closest("tr");
            var dataItem = grid.dataItem(row);

            console.log('Entered into my function', e );

            var productReferenceId = dataItem.get('agl.Product_Reference__r.Id') ? dataItem.get('agl.Product_Reference__r.Id') : null;
                    console.log('productReferenceId', productReferenceId);

            var dateFields = $.extend(true, [], options.dateFields);
        
            var agreementId = self.options.parentGrid.Id;
            var agreement = self.options.parentGrid;
            var agmtLines = {};
            var agmtLinesList = [];
            agmtLinesList.push(dataItem.get('agl')); 
            agmtLines = $.map(agmtLinesList, function(item, index) {
                item = item.toJSON();
                item = Serializer.ConvertToSFDCDate(item, { dateFields: dateFields });
                return item;
            });
            if (agmtLines.length > 0) {
            	agmtLines = Serializer.ParameterMap(agmtLines);
            }
            /***
            ** Need to revisit this when needed, for now have used JS object to store the values (omitted null values )that are used in the remote action 
            ****/
            var tmpAgl = {};
            tmpAgl['Agreement__c'] = agmtLines[0]['Agreement__c'];
            tmpAgl['Price_Type__c'] = agmtLines[0]['Price_Type__c'];
            tmpAgl['Product_Type__c'] = agmtLines[0]['Product_Type__c'];
            tmpAgl['Product_Reference__c'] = agmtLines[0]['Product_Reference__c'];
            if(productReferenceId != null)  {
            	debugger;
            	console.log(productReferenceId, agmtLines[0], agreementId);
            	Visualforce.remoting.Manager.invokeAction (
            		AgreementViewComponent.getAglDetailsFromCrossRef,
            		productReferenceId,
            			tmpAgl, 
            			agreementId,
            			function (result, event) {
            				KenandyErp.UnBlockUI();
                                if (event.type == 'exception') {
                                        KenandyErp.Alert("An error occurred while processing your request. Please contact support"); 
                                } else {
                                        KenandyErp.CleanNamespace(result.records, AgreementViewComponent.namespaceUU);
            				
                    					if(result.success) {
                    						if(result.records && result.records.length > 0) {
                    							var agmtLine = result.records[0].agl;   
                                                var productReference = (agmtLine.Product_Reference__c) ? agmtLine.Product_Reference__c : null;
                                                var productReferenceRef = (agmtLine.Product_Reference__r) ? agmtLine.Product_Reference__r : { Id: null, Name: null };
                                                var product = (agmtLine.Product__c) ? agmtLine.Product__c : null;

                                                var productRef = (agmtLine.Product__r) ? agmtLine.Product__r :  { Id: null, Name: null };
                                                var itemRef = (productRef.Item__r) ? productRef.Item__r 
                                                    : { Id: null, Name: null, Fulfillment_Source__c: null};
                                                var itemSpec = (productRef.Item_Specification__c) ? productRef.Item_Specification__c : null;
                                                var itemSpecRef = (productRef.Item_Specification__r) ? productRef.Item_Specification__r : {id: null, name: null};
                                                var priceBook = (agmtLine.Pricebook__c) ? agmtLine.Pricebook__c : null;
                                                var priceBookRef = (agmtLine.Pricebook__r) ? agmtLine.Pricebook__r :  { Id: null, Name: null };
                                                var listPrice = (typeof agmtLine.List_Price__c != 'undefined') ? agmtLine.List_Price__c : null;
                                                
                                                if(priceBook == null) {
                                                    dataItem.agl.set('Pricebook__c', priceBook);
                                                    dataItem.agl.set('Pricebook__r', priceBookRef);

                                                    
                                                }else {
                                                    dataItem.agl.set('List_Price__c', listPrice);
                                                    dataItem.agl.set('Pricebook__c', priceBook);
                                                    dataItem.agl.set('Pricebook__r', priceBookRef);
                                                    dataItem.agl.set('Agreement_Price__c', listPrice);
                                                }
                                                dataItem.agl.set('Product__c', product);
                                                dataItem.agl.set('Product__r', productRef);
                                                dataItem.agl.set('Item_Specification__c', itemSpec);
                                                dataItem.agl.set('Item_Specification__r', itemSpecRef);

                    						}
                    					}
            				    }

            			},
            			{escape: false}
            	);	
            }  
        },
        
        GetAGLineDetailsFromProduct: function(e){
        	debugger;
            var self = this;
            var grid = this.grid;
            var options = self.grid.options;
           // var messageElement = grid.element.closest("div.grid-container").find("div.grid-error-message");
            var cell = grid.element;
            var row = $(e.target).closest("tr");
            var dataItem = grid.dataItem(row);

            console.log('Entered into my function', e );

            var productId = dataItem.get('agl.Product__r.Id') ? dataItem.get('agl.Product__r.Id') : null;
                    console.log('productId', productId);

            var dateFields = $.extend(true, [], options.dateFields);
        
            var agreementId = self.options.parentGrid.Id;
            var agreement = self.options.parentGrid;
            var agmtLines = {};
            var agmtLinesList = [];
            agmtLinesList.push(dataItem.get('agl')); 
            agmtLines = $.map(agmtLinesList, function(item, index) {
                item = item.toJSON();
                item = Serializer.ConvertToSFDCDate(item, { dateFields: dateFields });
                return item;
            });
            if (agmtLines.length > 0) {
            	agmtLines = Serializer.ParameterMap(agmtLines);
            }
            var tmpAgl = {};
            tmpAgl['Agreement__c'] = agmtLines[0]['Agreement__c'];
            tmpAgl['Price_Type__c'] = agmtLines[0]['Price_Type__c'];
            tmpAgl['Product_Type__c'] = agmtLines[0]['Product_Type__c'];
            tmpAgl['Product__c'] = agmtLines[0]['Product__c'];
          
            if(productId != null)  {
            	Visualforce.remoting.Manager.invokeAction (
            		AgreementViewComponent.getAglDetailsFromProduct,
            		productId,
            			tmpAgl, 
            			agreementId,
                        function (result, event) {
            				KenandyErp.UnBlockUI();
                            
                                   if (event.type == 'exception') {
                                        KenandyErp.Alert("An error occurred while processing your request. Please contact support"); 
            				       } else {
                                        KenandyErp.CleanNamespace(result.records, AgreementViewComponent.namespaceUU);
                                   
                    					if(result.success) {
                    						if(result.records && result.records.length > 0) {
                    							var agmtLine = result.records[0].agl;   
                                                var product = (agmtLine.Product__c) ? agmtLine.Product__c : null;
                                                var productRef = (agmtLine.Product__r) ? agmtLine.Product__r : { Id: null, Name: null };
                                                var productReference = (agmtLine.Product_Reference__c) ? agmtLine.Product_Reference__c : null;
                                                var productReferenceRef = (agmtLine.Product_Reference__r) ? agmtLine.Product_Reference__r :  { Id: null, Name: null };
                                                var itemSpec = (productRef.Item_Specification__c) ? productRef.Item_Specification__c : null;
                                                var itemSpecRef = (productRef.Item_Specification__r) ? productRef.Item_Specification__r : {id: null, name: null};
                                                var priceBook = (agmtLine.Pricebook__c) ? agmtLine.Pricebook__c : null;
                                                var priceBookRef = (agmtLine.Pricebook__r) ? agmtLine.Pricebook__r :  { Id: null, Name: null };
                                                var listPrice = (typeof agmtLine.List_Price__c != 'undefined') ? agmtLine.List_Price__c : null;
                                                
                                                if(priceBook == null) {
                                                    dataItem.agl.set('Pricebook__c', priceBook);
                                                    dataItem.agl.set('Pricebook__r', priceBookRef);

                                                    
                                                }else {
                                                    dataItem.agl.set('List_Price__c', listPrice);
                                                    dataItem.agl.set('Pricebook__c', priceBook);
                                                    dataItem.agl.set('Pricebook__r', priceBookRef);
                                                    dataItem.agl.set('Agreement_Price__c', listPrice);
                                                }
                                                 dataItem.agl.set('Item_Specification__c', itemSpec);
                                                 dataItem.agl.set('Item_Specification__r', itemSpecRef);
                                             	 dataItem.agl.set('Product_Reference__c', productReference);
                                             	 dataItem.agl.set('Product_Reference__r', productReferenceRef);
                                                
                    						}
                    					}
            				        }

            			},
            			{escape: false}
            	);	
            }  
        }                 

	};
} )();

},{"../toolbars/AgreementLineToolbar":5,"../toolbars/AgreementToolbar":6}],8:[function(require,module,exports){
/* global Visualforce */
/* global _ */
/* global KenandyErp */
/* global KendoGridUtils */
var GridActionListActions = ( function() {
	return {

		Save: function( e ) {
			var self = this;
			var grid = self.grid;
			var messageElement = grid.element
				.closest( "div.grid-container" )
				.find( "div.grid-message" );
			var gridUtils = new KendoGridUtils( grid, self.options );
			if ( !gridUtils.IsValid() ) {
                e.preventDefault();
                return;
            }

			if ( !gridUtils.HasChanges() ) {
				KenandyErp.Message( "No records changed.", 
					KenandyErp.MessageType.Info, 
					messageElement );
				return;
			}

			var updatedRows = gridUtils.UpdatedRows();
			var newRows = gridUtils.NewRows();
			var deletedRows = gridUtils.DeletedRows();
			var changeListIds = _.union( _.pluck( updatedRows, "Id" ), 
				_.pluck( deletedRows, "Id" ) );

			KenandyErp.BlockUI( grid.element );		
			Visualforce.remoting.Manager.invokeAction(
				self.options.saveAction,
				self.options.config,        
				updatedRows,
				newRows,
				deletedRows,
				function( result, event ) {
					KenandyErp.UnBlockUI( grid.element );	    	
					if ( event.type == "exception" ) {
						KenandyErp.Message( event.message, 
							KenandyErp.MessageType.Error, 
							messageElement );
					} else {
						if ( result.success ) {
							var newIds = _.difference( 
								_.pluck( result.records, "Id" ), 
								changeListIds );

							//refresh the grid
							grid.dataSource._destroyed = [];
							grid.dataSource.read( { newIds: newIds } );		

							// trigger onsavesuccess
							grid.element.trigger( "OnSaveSuccess" );		
							KenandyErp.Messages( result.messages, messageElement );
						} else {
							KenandyErp.Messages( result.messages, messageElement );
						}
					}
				},
				{ escape: false }
			);
		}
	};
} )();

module.GridActionList = ( function( $ ) {
    var kendo = window.kendo,
        ui = kendo.ui,
        Widget = ui.Widget,
        CHANGE = "change";
        ONREADFAILURE = "OnReadFailure";
        ONREADSUCCESS = "OnReadSuccess";

	var GridActionList = ui.Grid.extend( {
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
        init: function( element, options ) {
            var that = this;

			that._initDefaults( options );

            var getModel = function() {
	            var fields = KenandyErp.KendoGridOptions.GetFields( _fieldList );
				
	            // Add schema for checkbox column
				fields.isSelected__custom = { type: "boolean" };

				var model = kendo.data.Model.define( { id: _modelIdField, fields: fields } );

				return model;
			};
					
			var getColumns = function() {
	            var columns = KenandyErp.KendoGridOptions.GetColumns(
					_fieldList,
					{ lookupSearchAction: options.lookupSearchAction,
						buttons: _standardButtons,
						lookupSearchFilters: _lookupSearchFilters,
						allowMassDelete: _allowMassDelete,
						validateLookupOnBlur: options.validateLookupOnBlur
				} );
	            
	            $.each(_.where(columns, {field: "Name"}), function(index, item) {
					item.template = kendo.template('<a target="_top" href="/#=Id#" />#= Name #</a>');
				});
				
				$.each(columns, function(index, item) {
					if ( item.format == "{0:M/d/yyyy h:mm tt}") {
						item.format = "{0:M/d/yyyy}"
					}
				});
				
				columns.unshift(
					{ field: "",
						filterable: false,
						sortable: false,
						width: 30,
						attributes: { class: "kndy-text-left" },
						headerAttributes: { class: "kndy-text-left" }
				} );

				return columns;
			};

			var getToolbarButtons = function() {
				var buttons = KenandyErp.KendoGridOptions.GetToolbarButtons( 
					_standardButtons,
					{ showIconButtons: _showIconButtons,
						allowMassDelete: _allowMassDelete
				} );
				
				buttons = _.union( buttons, options.toolbarButtons );
				return buttons;
			};

			var getDataSource = function() {
				var dataSource = new kendo.data.DataSource( {
					transport: {
						read: function( options ) {
							KenandyErp.BlockUI( element );

							var promise = _getActionListFunction( options.data.readOptions );
							promise.done( function( result, event ) {
								KenandyErp.UnBlockUI( element );

						        	if ( event.type == "exception" ) {
										KenandyErp.Alert( "An error occurred while processing your request." +
											 "Please contact support" );

										// trigger onreadfailure
									    $( element ).trigger( {
									        type: ONREADFAILURE,
									        result: result, 
									        event: event 
									    } );
									} else {
										KenandyErp.CleanNamespace( result.records, _namespace );
						            	options.success( result.records );
						            	
						            	// trigger onreadsuccess
									    $( element ).trigger( {
									        type: ONREADSUCCESS,
									        result: result, 
									        event: event 
									    } );
									}
					            } );
						}
					},
					batch: true,
					pageSize: ( _config.pageSize ) ? _config.pageSize : KenandyErp.KendoGridOptions.DefaultPageSize,
					schema: {
						model: getModel(),
						parse:function( response ) {
			                $.each( response, function( idx, item ) {
			                	item = Serializer.IncludeNulls( item, { fields: _nestedFields } );
	                    		item = Serializer.ConvertFromSFDCDate( item, { dateFields: _dateFields } );
						    } );
						    
			                return response;
						}         	
					},
					aggregate: options.aggregates ? options.aggregates : null    	
				} );
	
				return dataSource;
			};
				
            var defaultOptions = {
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
		        sortable: true,
				filterable: true,
				resizable: true,
				editable: true,
                scrollable: _config.scrollable ? _config.scrollable : true
	        };
	        
	        options = $.extend( {}, defaultOptions, options );
	        
            if ( $( element ).data( 'kendoGrid' ) !== null && $( element ).data( 'kendoGrid' ) !== undefined ) { 
                $( element ).data( 'kendoGrid' ).destroy(); 
            }
            
            ui.Grid.fn.init.call( that, element, options );
			
			$( element ).data( "kendoGrid", that );
			
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
            validateLookupOnBlur: false
        },
        
        // events the control can fire
		events: [ CHANGE ],
		
		_initDefaults: function( options ) {
			var that = this;
			
			_config = JSONUtils.Parse( options.config );
			_fieldList = JSONUtils.Parse( options.fieldList );
			_standardButtons = $.map( _config.buttons.split( ',' ), $.trim );
			_namespace = _config.namespace ? _config.namespace : options.namespace;
			_referenceFields = KenandyErp.KendoGridOptions.GetReferenceFields( _fieldList ); // get the list of reference fields
			_dateFields = KenandyErp.KendoGridOptions.GetDateFields( _fieldList ); // get the list of date fields
			_lookupSearchFilters = ( options.lookupSearchFilters ) ? options.lookupSearchFilters : [];
			_nestedFields = KenandyErp.KendoGridOptions.GetNestedFields( _fieldList ); // get the list of nested fields
			_modelIdField = options.modelIdField ? options.modelIdField : 'Id';
			_getActionListFunction = options.getActionListFunction;
			_showIconButtons = ( options.showIconButtons ) ? options.showIconButtons : that.options.showIconButtons;
			_allowMassDelete = ( options.allowMassDelete ) ? options.allowMassDelete : that.options.allowMassDelete;
		},
		
		_initEvents: function() {
			var that = this;
			var grid = that;
			
			// bind grid edit event
			grid.bind( 'edit', $.proxy( KenandyErp.KendoGridActions.Edit, { referenceFields: _referenceFields } ) );
				
			// bind grid dataBound event
			grid.bind( 'dataBound', KenandyErp.KendoGridActions.DataBound );
				
			// bind click events to the custom buttons
			KenandyErp.KendoGridOptions.BindEvents( grid, _standardButtons, { saveAction: that.options.saveActionListAction, addRowAction: that.options.addRowAction, referenceFields: _referenceFields, config: _config, dateFields: _dateFields, ignoreBindings: [ KenandyErp.KendoGridOptions.CommandType.Save ] } );

			// set the grid height
			if ( that.options.height ) {
				grid.wrapper.height( that.options.height );
			}
			
			grid.wrapper.on( "click", ".grid-save-command", $.proxy( GridActionListActions.Save, { grid: grid, options: { saveAction: that.options.saveActionListAction, config: _config } } ) );
			grid.thead.on( "click", ".grid-select-all", $.proxy( KenandyErp.KendoGridActions.SelectAll, { grid: grid } ) );
			grid.tbody.on( "change", ".grid-select-one", $.proxy( KenandyErp.KendoGridActions.Select, { grid: grid } ) );
			
			grid.bind( 'dataBound', function() {
				var isSelected = ( grid.tbody.find( '.grid-select-one' ).length > 0 && !grid.tbody.find( '.grid-select-one' ).is( ':not(:checked)' ) ) ? true : false;
				grid.thead.find( '.grid-select-all' ).prop( 'checked', isSelected );
			} );
		}
	} );

	ui.plugin( GridActionList );
} )( jQuery );

},{}],9:[function(require,module,exports){
var GridDetailListActions = function() {
	
	return {
	
		Save: function( e ) {
   			var self = this;
   			var grid = self.grid;
   			var messageElement = grid.element.closest( "div.grid-container" ).find( "div.grid-message" );
   			
			var gridUtils = new KendoGridUtils( grid, self.options );
							
			if ( !gridUtils.IsValid() ) {
                e.preventDefault();
                return;
            }
		 		
        	if ( !gridUtils.HasChanges() ) {
        		KenandyErp.Message( "No records changed.", KenandyErp.MessageType.Info, messageElement );
        		return;
        	}
        	
        	var updatedRows = gridUtils.UpdatedRows();
        	var newRows = gridUtils.NewRows();
        	var deletedRows = gridUtils.DeletedRows();
        	var changeListIds = _.union( _.pluck( updatedRows, 'Id' ), _.pluck( deletedRows, 'Id' ) );
        	
			KenandyErp.BlockUI( grid.element );
							
			Visualforce.remoting.Manager.invokeAction(
		    	self.options.saveAction,
		    	self.options.detailConfig,			     	        
				updatedRows, 
				newRows, 
				deletedRows, 
				function( result, event ) {
					KenandyErp.UnBlockUI( grid.element );
						    	
					if ( event.type == 'exception' ) {
						KenandyErp.Message( event.message, KenandyErp.MessageType.Error, messageElement );
					} else {
						if ( result.success ) {
							var newIds = _.difference( _.pluck( result.records, 'Id' ), changeListIds );
							
							//refresh the grid
	                		grid.dataSource._destroyed = [];
	                		grid.dataSource.read( { newIds: newIds } );
										
							// trigger onsavesuccess
							grid.element.trigger( "OnSaveSuccess" );
										
							KenandyErp.Messages( result.messages, messageElement );
						} else {
							KenandyErp.Messages( result.messages, messageElement );
						}
					}
				},
				{ escape: false }
			);
   		}
	};
}();
module.GridActionList = ( function( $ ) {
    var kendo = window.kendo,
        ui = kendo.ui,
        Widget = ui.Widget,
        CHANGE = "change";
        ONREADFAILURE = "OnReadFailure";
        ONREADSUCCESS = "OnReadSuccess";

	var GridDetailList = ui.Grid.extend( {
		_detailConfig: null,
		_detailFieldList: null,
		_standardButtons: null,
		_detailNamespace: null,
		_detailReferenceFields: null,
		_detailDateFields: null,
		_detailNestedFields: null,
		_lookupSearchFilters: null,
		_detailModelIdField: null,
		_getDetailListFunction: null,
		_detailAllowMassDelete: null,
		_detailShowIconButtons: null,
		
        // method called when a new widget is created
        init: function( element, options ) {
            var that = this;
            
			that._initDefaults( options );
			
            var getDetailModel = function() {
	            var fields = KenandyErp.KendoGridOptions.GetFields( _detailFieldList );	
	
	            // Add schema for checkbox column
				fields.IsSelected__custom = { type: "boolean" };
								
				var model = kendo.data.Model.define( { id: _detailModelIdField, fields: fields } );
						
				return model;
			};
					
			var getDetailColumns = function() {
	            var columns = KenandyErp.KendoGridOptions.GetColumns( _detailFieldList, { lookupSearchAction: options.lookupSearchAction, buttons: _standardButtons, lookupSearchFilters: _lookupSearchFilters, detailAllowMassDelete: _detailAllowMassDelete, detailValidateOnBlur: options.detailValidateOnBlur } );
	            
	            // Add checkbox column
				columns.unshift( { field: 'IsSelected__custom', filterable: false, sortable: false,  width: 30, attributes: { class: 'kndy-text-left' }, headerAttributes: { class: 'kndy-text-left' } } ); //template: "<input type='checkbox' data-bind='IsSelected__custom' #= IsSelected__custom ? checked='checked': '' # class='grid-select-one' />", headerTemplate: "<input type='checkbox' class='grid-select-all' />",
					
				return columns;
			};
			
			var getDetailToolbarButtons = function() {
				var buttons = KenandyErp.KendoGridOptions.GetToolbarButtons( _standardButtons, { detailShowIconButtons: _detailShowIconButtons, detailAllowMassDelete: _detailAllowMassDelete } );
				
				buttons = _.union( buttons, options.detailToolbarButtons );
				return buttons;
			};
			
			var getDetailDataSource = function() {
				var dataSource = new kendo.data.DataSource( {
					transport: {
						read: function( options ) {
							KenandyErp.BlockUI( element );
							
							var promise = _getDetailListFunction( options.data.readOptions );
							promise.done( function( result, event ) {
					            	KenandyErp.UnBlockUI( element );
					            	
						        	if ( event.type == 'exception' ) {
						        		KenandyErp.Alert( "An error occurred while processing your request. Please contact support" ); 
							        		
						        		// trigger onreadfailure
									    $( element ).trigger( {
									        type: ONREADFAILURE,
									        result: result, 
									        event: event 
									    } );
									} else {
										KenandyErp.CleanNamespace( result.records, _detailNamespace );
						            	options.success( result.records );
						            	
						            	// trigger onreadsuccess
									    $( element ).trigger( {
									        type: ONREADSUCCESS,
									        result: result, 
									        event: event 
									    } );
									}
					            } );
						}
					},
					batch: true,
					pageSize: ( _detailConfig.pageSize ) ? _detailConfig.pageSize : KenandyErp.KendoGridOptions.DefaultPageSize,
					schema: {
						model: getDetailModel(),
						parse:function( response ) {
			                $.each( response, function( idx, item ) {
			                	item = Serializer.IncludeNulls( item, { fields: _detailNestedFields } );
	                    		item = Serializer.ConvertFromSFDCDate( item, { dateFields: _detailDateFields } );
						    } );
						    
			                return response;
						}         	
					},
					aggregate: options.aggregates ? options.aggregates : null    	
				} );
	
				return dataSource;
			};
				
            var defaultOptions = {
	        	dataSource: getDetailDataSource(), 
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
		        toolbar: getDetailToolbarButtons(),
		        columns: getDetailColumns(),
		        sortable: true,
				filterable: true,
				resizable: true,
				editable: true
	        };
	        
	        options = $.extend( {}, defaultOptions, options );
	        
            if ( $( element ).data( 'kendoGrid' ) !== null ) { 
                $( element ).data( 'kendoGrid' ).destroy(); 
            }
            
            ui.Grid.fn.init.call( that, element, options );
			
			$( element ).data( "kendoGrid", that );
			
			that._initEvents();
        },
        
        // widget options
        options: {
            name: "GridDetailList",
            detailConfig: null,
            detailFieldList: null,
            detailNamespace: null,
            lookupSearchAction: null,
            getDetailListFunction: null,
            saveDetailListAction: null,
            detailAddRowAction: null,
            lookupSearchFilters: [],
            detailModeIdField: 'Id',
            detailAllowMassDelete: true,
            detailShowIconButtons: false,
            detailToolbarButtons: [],
            detailValidateOnBlur: false
        },
        
        // events the control can fire
		events: [ CHANGE ],
		
		_initDefaults: function( options ) {
			var that = this;
			
			_detailConfig = JSONUtils.Parse( options.detailConfig );
			_detailFieldList = JSONUtils.Parse( options.detailFieldList );
			_standardButtons = $.map( _detailConfig.buttons.split( ',' ), $.trim );
			_detailNamespace = _detailConfig.detailNamespace ? _detailConfig.detailNamespace : options.detailNamespace;
			_detailReferenceFields = KenandyErp.KendoGridOptions.GetReferenceFields( _detailFieldList ); // get the list of reference fields
			_detailDateFields = KenandyErp.KendoGridOptions.GetDateFields( _detailFieldList ); // get the list of date fields
			_lookupSearchFilters = ( options.lookupSearchFilters ) ? options.lookupSearchFilters : [];
			_detailNestedFields = KenandyErp.KendoGridOptions.GetNestedFields( _detailFieldList ); // get the list of nested fields
			_detailModelIdField = options.detailModeIdField ? options.detailModeIdField : 'Id';
			_getDetailListFunction = options.getDetailListFunction;
			_detailShowIconButtons = ( options.detailShowIconButtons ) ? options.detailShowIconButtons : that.options.detailShowIconButtons;
			_detailAllowMassDelete = ( options.detailAllowMassDelete ) ? options.detailAllowMassDelete : that.options.detailAllowMassDelete;
		},
		
		_initEvents: function() {
			var that = this;
			var grid = that;
			
			// bind grid edit event
			grid.bind( 'edit', $.proxy( KenandyErp.KendoGridActions.Edit, { referenceFields: _detailReferenceFields } ) );
				
			// bind grid dataBound event
			grid.bind( 'dataBound', KenandyErp.KendoGridActions.DataBound );
				
			// bind click events to the custom buttons
			KenandyErp.KendoGridOptions.BindEvents( grid, _standardButtons, { saveAction: that.options.saveDetailListAction, detailAddRowAction: that.options.detailAddRowAction, referenceFields: _detailReferenceFields, detailConfig: _detailConfig, dateFields: _detailDateFields, ignoreBindings: [ KenandyErp.KendoGridOptions.CommandType.Save ] } );

			// set the grid height
			if ( that.options.height ) {
				grid.wrapper.height( that.options.height );
			}
			
			grid.wrapper.on( "click", ".grid-save-command", $.proxy( GridDetailListActions.Save, { grid: grid, options: { saveAction: that.options.saveDetailListAction, detailConfig: _detailConfig } } ) );
			grid.thead.on( "click", ".grid-select-all", $.proxy( KenandyErp.KendoGridActions.SelectAll, { grid: grid } ) );
			grid.tbody.on( "change", ".grid-select-one", $.proxy( KenandyErp.KendoGridActions.Select, { grid: grid } ) );
			
			grid.bind( 'dataBound', function() {
				var isSelected = ( grid.tbody.find( '.grid-select-one' ).length > 0 && !grid.tbody.find( '.grid-select-one' ).is( ':not(:checked)' ) ) ? true : false;
				grid.thead.find( '.grid-select-all' ).prop( 'checked', isSelected );
			} );
		}
	} );

	ui.plugin( GridDetailList );
} )( jQuery );

},{}],10:[function(require,module,exports){
/* global PlanView */
/* global $ */
/* global AgreementViewComponent */
var utility = require( "../utils/AgreementViewHelper" );
var drawSecondGrid = require( "./AgreementLineGrid" );
var drawTreeList = require( "./AgreementLineTreeList" );
require( "../utils/GridActionList" );

module.exports = function() {

	var agreementData = function() {
        var deferred = $.Deferred();

        Visualforce.remoting.Manager.invokeAction(
            AgreementViewComponent.getAgreementData,
            AgreementViewComponent.agreementId,
            AgreementViewComponent.planId,
            function( result, event ) {
                deferred.resolve( result, event );
            },
            { escape: false }
        );

        return deferred.promise();
    };
    
    var grid = $( '#promotions' ).width( $( '#mainpage' ).width()).kendoGridActionList( {
        selectable: true,
        config: AgreementViewComponent.agreementGridConfig,
        namespace: AgreementViewComponent.namespaceUU, 
        fieldList: utility.getFieldList(AgreementViewComponent.agreementFieldList),
        getActionListFunction: agreementData,
        allowMassDelete: false,
        lookupSearchAction: AgreementViewComponent.lookupSearchAction,
        lookupSearchFilters: AgreementViewComponent.agreementLookupSearchFilters,
        toolbarButtons: [
                utility.getAgreementButtons(),
                { name: "grid-save-agreement-command",
                    text:"",
                    template: "<input type='button' value='Save Changes' class='btn grid-save-agreement-command' />" },
                { name: "grid-cancel-agreement-command",
                    text:"",
                    template: "<input type='button' value='Cancel Changes' class='btn grid-cancel-agreement-command' />" },
                { name:"formatLabel",
                    template: "<label style='padding-left: 50px; padding-right: 5px;'>" +
                        AgreementViewComponent.actionLabel +
                        ":</label>" },
                { name:"promoActionDropdown",
                    template: "<input id='promoActionDropdown' style='width: 225px;' />",
                    overflow: "never" },
            	{ name:"promoActionGo",
                    text: AgreementViewComponent.goLabel }           	   
        ],
        beforeEdit: utility.checkBeforeEdit

    } ).data( "kendoGridActionList" );

	grid.bind( "dataBound", function( e ) {
        if ( !$( "#pprod" ).data( "kendoTreeList" ) ) {
            drawTreeList( grid.dataSource._data[ 0 ] );
        }      
	} );

    //agreementData.done(function(result, event){
    utility.elementInit( grid, false );

    grid.bind( "edit", function( e ) {
        if ( e.model.isNew() ) {                     // if row is new, then set defaults
            e.model.set( "Plan__c", AgreementViewComponent.planId );
            e.model.set( "Start_Date__c", KenandyErp.ParseSFDCDate( PlanView.planStart ) );
            e.model.set( "End_Date__c", KenandyErp.ParseSFDCDate( PlanView.planEnd ) );
            e.model.set( "Approval_Date__c", null );
            e.model.set( "Activation_Date__c", null );
        }
        if( $( e.container ).find('input[name="Bill_To__c"]').length > 0 ) {
            var lookupSearchFilters = [];
            var customer = AgreementViewComponent.theAgreement.Customer__c; 
            lookupSearchFilters.push( {field: "Bill_To__c", filter: "RecordType.DeveloperName  = \'Bill_To\' AND Top_Parent_Customer__c = '" + customer + "' " });
            $(e.container).find('input[name="Bill_To__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
        }
        if( $( e.container ).find('input[name="Sold_To__c"]').length > 0 ) {
            var lookupSearchFilters = [];
            var customer = AgreementViewComponent.theAgreement.Customer__c; 
            lookupSearchFilters.push( {field: "Sold_To__c", filter: "RecordType.DeveloperName  = \'Sold_To\' AND Top_Parent_Customer__c = '" + customer + "' " });
            $(e.container).find('input[name="Sold_To__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
        }
        if( $( e.container ).find('input[name="Ship_To__c"]').length > 0 ) {
            var lookupSearchFilters = [];
            var customer = AgreementViewComponent.theAgreement.Customer__c; 
            lookupSearchFilters.push( {field: "Ship_To__c", filter: "RecordType.DeveloperName  = \'Ship_To\' AND Top_Parent_Customer__c = '" + customer + "' " });
            $(e.container).find('input[name="Ship_To__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
        }
        if( $( e.container ).find('input[name="Site__c"]').length > 0 ) {
            var lookupSearchFilters = [];
            var customer = AgreementViewComponent.theAgreement.Customer__c; 
            lookupSearchFilters.push( {field: "Site__c", filter: "RecordType.DeveloperName  = \'Site\' AND Top_Parent_Customer__c = '" + customer + "' " });
            $(e.container).find('input[name="Site__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
        }
        
        if( $( e.container ).find('input[name="Customer__c"]').length > 0 ) {
            var lookupSearchFilters = [];
            
            if ( e.model.get( "Customer_Type__c" ) == "Bill To" || e.model.get( "Customer_Type__c" ) == "Sold To" ) {
                if ( e.model.get( "Customer_Type__c" ) == "Bill To" ) {
                    lookupSearchFilters.push( {field: "Customer__c", filter: "RecordType.DeveloperName  = \'Bill_To\'" });
                }
                
                if ( e.model.get( "Customer_Type__c" ) == "Sold To") {
                    lookupSearchFilters.push( {field: "Customer__c", filter: "RecordType.DeveloperName  = \'Sold_To\'" });
                }
                
                $(e.container).find('input[name="Customer__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
            }
        }
        //Commenting out following code since it doesnt allow to navigate to any other control.  
        /*if( $( e.container ).find('input[data-role="datetimepicker"]').length > 0 ) {
           var dateTimePicker =  $( e.container ).find('input[data-role="datetimepicker"]').data("kendoDateTimePicker");
           dateTimePicker.setOptions({ format: "M/d/yyyy", parseFormats: "M/d/yyyy hh:mm"});
        }*/
        
    } );

    grid.bind( "change", function( e ) {
                
        var item = { Id: AgreementViewComponent.promotionPrefix };

        var selectedItem = this.dataItem( this.select() );

        if ( typeof selectedItem !== "undefined" ) {
            if ( selectedItem !== null ) {
                item = selectedItem;
            }
        }

        //   first time                   OR   changing
        if ( AgreementViewComponent.theAgreement.Id != item.Id ) {

            $.each( AgreementViewComponent.promoActionConfig, function() {

                var regex = /\?[a-zA-Z0-9=]*/;
              
                this.content = this.content && this.content.replace( regex, "?id=" + item.id );

            } );

            AgreementViewComponent.theAgreement = item;

            $( "#pprod" ).data( "kendoTreeList" ).dataSource.read();
            $( "#pprod" ).data( "kendoTreeList" ).refresh();
        } else {
            e.preventDefault();
        } 
    } );

    //});
};

},{"../utils/AgreementViewHelper":7,"../utils/GridActionList":8,"./AgreementLineGrid":11,"./AgreementLineTreeList":12}],11:[function(require,module,exports){
/* global KenandyErp */
/* global AgreementViewComponent */
/* global Visualforce */
var utility = require( '../utils/AgreementViewHelper' );
require( '../utils/GridDetailList' );

module.exports = function( agreement ) {

    var agreementLineData = function() {

        if ( AgreementViewComponent.theAgreement.Id !== '') {
            agreement = AgreementViewComponent.theAgreement;
        }

        var deferred = $.Deferred();
        
        Visualforce.remoting.Manager.invokeAction(
            AgreementViewComponent.getAgreementLineData,
            agreement.Id, 
            AgreementViewComponent.allFields,
            function( result, event ) {
                deferred.resolve( result, event );
            },
            { escape: false }
        );

        return deferred.promise();
    };

    var grid = $( '#pprod' ).kendoGridDetailList( {
        selectable: true,
        detailConfig: AgreementViewComponent.agreementLinesGridConfig,
        detailNamespace: AgreementViewComponent.namespaceUU, 
        detailFieldList: AgreementViewComponent.agreementLineFieldList,
        getDetailListFunction: agreementLineData,
        scrollable: true,
        lookupSearchAction: AgreementViewComponent.lookupSearchAction,
        lookupSearchFilters: AgreementViewComponent.agreementLineLookupSearchFilters,
        detailToolbarButtons: [
                    { name: "grid-add-line-command", text:"", template: "<input type='button' value='Add New' class='btn grid-add-line-command' />" },
                    { name: "grid-save-line-command", text:"", template: "<input type='button' value='Save Changes' class='btn grid-save-line-command' />" },
                    { name: "grid-cancel-line-command", text:"", template: "<input type='button' value='Cancel Changes' class='btn grid-cancel-line-command' />" },
                    { name:"formatLabel", template: "<label style='padding-left: 50px; padding-right: 5px;'>" + AgreementViewComponent.actionLabel + ":</label>" },
                    { name:"promoProdActionDropdown", template: "<input id='promoProdActionDropdown' style='width: 225px;' />", overflow: "never" },
                    { name:"promoProdActionGo", text:AgreementViewComponent.goLabel }                                             
                 ],                        
        change: function( e ) {
            var item = { Id: AgreementViewComponent.promoProdPrefix };
            
            var selectedItem = this.dataItem( this.select() );  
            
            if ( typeof selectedItem !== "undefined" ) {
                if ( selectedItem !== null ) {
						item = selectedItem; 	                            
                }
            }     
            
            if ( AgreementViewComponent.promotedProd != item ) {           //  see if this really changed ?
                AgreementViewComponent.promotedProd = item;
                
                $.each( AgreementViewComponent.promoProdActionConfig, function() {

                    var regex = /=[a-zA-Z0-9]*/;
                    this.content = this.content && this.content.replace( regex, '=' + item.id );
                    
                } );
            }
        }
    } ).data( 'kendoGridDetailList' );
    
    //agreementLineData.done(function(result, event){
    utility.elementInit( grid, false );
    grid.bind( 'edit', function( e ) {
        if ( e.model.isNew() ) {                     // if row is new, then set defaults

            e.model.set( 'Agreement__c', agreement.Id );
            e.model.set( 'Start_Date__c', KenandyErp.ParseSFDCDate( agreement.Start_Date__c ) );
            e.model.set( 'End_Date__c', KenandyErp.ParseSFDCDate( agreement.End_Date__c ) );

            // no edit on thias lookup
            // $.proxy(KenandyErp.KendoGridActions.Edit, { referenceFields: ['Product_Hierarchy__c'] })
        }
    } );

    //});   
};

},{"../utils/AgreementViewHelper":7,"../utils/GridDetailList":9}],12:[function(require,module,exports){
/* global Visualforce */
/* global expandedRows */
/* global ONREADSUCCESS */
/* global ONREADFAILURE */
/* global AgreementViewComponent */
/* global JSONUtils */
/* global KenandyErp */
/* global Serializer */
/// <reference path="../../typings/tsd.d.ts" />
var utility = require( "../utils/AgreementViewHelper" );
var save = require( "../actions/TreeListSaveAction" );

module.exports = function( agreement ) {
    var agreementLineFieldListParsed = utility.getFieldList(AgreementViewComponent.agreementLineFieldList);

    var agreementLineDateFieldsParsed = JSONUtils.Parse(
        AgreementViewComponent.agreementLineDateFields() );

    var _nestedFields = KenandyErp.KendoGridOptions.GetNestedFields(
        agreementLineFieldListParsed ); // get the list of nested fields

    var agreementLineData = function() {

        if ( AgreementViewComponent.theAgreement.Id !== "" )  {
            agreement = AgreementViewComponent.theAgreement;
        }

        var deferred = $.Deferred();

        Visualforce.remoting.Manager.invokeAction(
            AgreementViewComponent.getAgreementLineData,
            agreement.Id,
            AgreementViewComponent.allFields,
            function( result, event ) {
                deferred.resolve( result, event );
            },
            { escape: false }
        );

        return deferred.promise();
    };

    var columns = KenandyErp.KendoGridOptions.GetColumns(
        agreementLineFieldListParsed,
        { lookupSearchAction: AgreementViewComponent.lookupSearchAction,
            buttons: null,
            lookupSearchFilters: AgreementViewComponent.agreementLineLookupSearchFilters,
            allowMassDelete: null,
            validateOnBlur: null
        } );
        
    columns.shift( 0 );
    
    if(agreement.Status__c == "Approved") {
        columns.unshift( { command: [ "edit" ],
                    attributes: {
                        style: "text-align: center;",
                    },
                    width: "100px",
                } );
        columns.push( { command: [ "edit" ],
                    attributes: {
                        style: "text-align: center;",
                    },
                    width: "100px"
                } );
    }
    else {
        columns.unshift( { command: [ "edit", "destroy" ],
                    attributes: {
                        style: "text-align: center;",
                    },
                    width: "100px"
                } );
         columns.push( { command: [ "edit", "destroy" ],
                    attributes: {
                        style: "text-align: center;",
                    },
                    width: "100px"
                } );
    }
    
    columns[1].expandable = true;
    
   //Hack for header formatting on columns missing it
   $.each( columns, function( index, item ) {
       if ( item.headerAttributes ) {
           item.headerAttributes.class = item.headerAttributes.class + " k-header";
       }
       if ( item.field !== "" ) {
           item.filterable = true;
       }
       if ( item.field == 'agl.Name') {
           item.template = kendo.template('<a target="_top" href="/#=agl.Id#" />#= agl.Name #</a>');
       }
       if ( item.field == "agl.Total_Value_FC__c" ) {
           item.template = "#= (agl.Total_Value_FC__c === null) ? ' ' : agl.Total_Value_FC__c #";
       }
       if ( item.field == "agl.Margin__c" ) {
           item.template = "#= (agl.Margin__c === null) ? ' ' : agl.Margin__c #";
       }
       if ( item.field == "agl.Group_Number__c" ) {
           item.template = "#= (agl.Group_Number__c === null) ? ' ' : agl.Group_Number__c #";
       }
       if ( item.field == "agl.Margin_Cost__c" ) {
           item.template = "#= (agl.Margin_Cost__c === null) ? ' ' : agl.Margin_Cost__c #";
       }
       if ( item.field == "agl.Occurence_Count__c" ) {
           item.template = "#= (agl.Occurence_Count__c=== null) ? ' ' : agl.Occurence_Count__c #";
       }
       if ( item.field == "agl.Product__c" ) {
           item.headerAttributes = {
               style: "min-width: 150px"
           }
       }
       if ( item.field == 'agl.Variation_Percentage__c'){
           item.template   = "#if(agl.Agreement_Price__c >= agl.List_Price__c){# <span class='agreementlinevariationpercentageless'>#=kendo.toString(agl.Variation_Percentage__c, '0.00')#</span> #} else if (agl.Variation_Percentage__c <= AgreementViewComponent.thresholdpercentagevalue){#  <span class='agreementlinevariationpercentagemoderate'>#=kendo.toString(agl.Variation_Percentage__c, '0.00') # </span>#} else {# <span class='agreementlinevariationpercentagemore'>#=kendo.toString(agl.Variation_Percentage__c, '0.00') # </span>#}# ";
       }       
       if ( item.format == "{0:M/d/yyyy h:mm tt}") {
           item.format = "{0:M/d/yyyy}"
       }
       
   } );
    
   
    var fields = KenandyErp.KendoGridOptions.GetFields( agreementLineFieldListParsed );
    $.each( fields, function( i, v ) {
        delete v.validation;
    } );
    fields.parentId = { "field": "agl.Parent_Agreement_Line__c", "nullable": true };

    var model = {};
    model.id = "agl.Id";
    model.fields = fields;
    model.expanded = false;

    var dataSource = new kendo.data.TreeListDataSource( {
        transport: {
            read: function( options ) {
                KenandyErp.BlockUI( "#pprod" );

                var promise = agreementLineData( options.data.readOptions );
                promise.done( function( result, event ) {
                        KenandyErp.UnBlockUI( "#pprod" );
                        //setting agreementlines grid width as per parent cotainer outerWidth
                        $('#pprod').width($('.grid-container').width());

                        if ( event.type == "exception" ) {
                            KenandyErp.Alert( "An error occurred while processing your request. " +
                                "Please contact support" );

                            // trigger onreadfailure
                            $( "#pprod" ).trigger( {
                                type: ONREADFAILURE,
                                result: result,
                                event: event
                            } );
                        } else {
                            KenandyErp.CleanNamespace( result.records,
                                AgreementViewComponent.namespaceUU );

                            options.success( result.records );

                            // trigger onreadsuccess
                            $( "#pprod" ).trigger( {
                                type: ONREADSUCCESS,
                                result: result,
                                event: event
                            } );
                        }
                    } );
            },

            update: function( options ) {
                save( options, agreementLineDateFieldsParsed, "update" );
            },

            create: function( options ) {
                save( options, agreementLineDateFieldsParsed, "create" );
            },

            destroy: function( options ) {
                save( options, agreementLineDateFieldsParsed, "delete" );
            }
        },
        batch: true,
        schema: {
            model: model,
            parse:function( response ) {
                $.each( response, function( idx, item ) {
                    if ( item.agl.Parent_Agreement_Line__c === undefined ) {

//                        item.parentId = null;
                        item.agl.Parent_Agreement_Line__c = null;
                    }

                    item.id = item.agl.Id;
                    item = Serializer.IncludeNulls( item, { fields: _nestedFields } );
                    item = Serializer.ConvertFromSFDCDate( item, { dateFields: agreementLineDateFieldsParsed } );
                } );

                return response;
            }
        },
        filter: [
            { field: "agl.Revision_Status__c", operator: "neq", value: "Rejected"},
            { field: "agl.Revision_Status__c", operator: "neq", value: "Revised"}
        ]
    } );

    var toolBarButtons = "<button data-command=\"create\" class=\"k-button k-button-icontext k-grid-add\"><span class=\"k-icon k-add\"></span>Add new record</button>" +
    "<label style='padding-left: 50px; padding-right: 5px;'>" + AgreementViewComponent.actionLabel + ":</label>" +
    "<input id='promoProdActionDropdown' style='width: 225px;' />" +
    "<a class=\"k-button k-button-icontext k-grid-promoProdActionGo\" href=\"\\#\">Go</a>" + 
    "<label style='padding-left: 50px; padding-right: 5px;'>Views:</label>" + 
    "<input class='grid-view-options' />"
    ;

    var treeList = $( "#pprod" ).width( $( '#mainpage').width()).kendoTreeList( {
        dataSource: dataSource,
        toolbar: toolBarButtons,
        editable: true,
        selectable: true,
        resizable: true,
        scrollable: true,
        filterable: true,
        columnMenu: true,
        reorderable: true,
        columns: columns,
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
        edit: function( e ) {

            var self = this;
            var data = this.dataSource;
            var options = this.dataSource.options;

            if ( e.model.isNew() || e.model.get("id") == null ) {                     // if row is new, then set defaults
                e.model.agl.set( "Agreement__c", agreement.Id );
                e.model.agl.set( "Start_Date__c", KenandyErp.ParseSFDCDate( agreement.Start_Date__c ) );
                e.model.agl.set( "End_Date__c", KenandyErp.ParseSFDCDate( agreement.End_Date__c ) );
                e.model.agl.set( "List_Price__c", null );
                e.model.agl.set( "Agreement_Price__c", null );
                //KNDY-13886 Unable to add agreement line - Due to date field being passed as null
                //e.model.agl.set( "Revision_Approval_date__c", null ); commenting this out to prevent UI error
                e.model.agl.set( "Revised__c", false );
                e.model.agl.set( "Customer_PO__c", agreement.Customer_PO__c);
                e.model.agl.set( "Product_Type__c", 'Product');
                if(agreement.Agreement_Type__c == 'Sales Agreement'){
                    e.model.agl.set( "Price_Type__c", 'Sales');
                }else if(agreement.Agreement_Type__c == 'Rental'){
                    e.model.agl.set( "Price_Type__c", 'Recurring');
                }
            }
            $.each(data.options.schema.model.fields, function(index, item) {
                if(item && item.type == 'boolean'){
                    e.model.get(index) ? e.model.get(index) : e.model.set(index, false);
                }
            });

            $(e.container).find('input[name="agl.Product_Reference__c"]').bind('blur',

            $.proxy(utility.GetAGLineDetailsFromProductRef, { grid: treeList,

                options: { 
                    parentGrid: $('#promotions').data('kendoGridActionList').dataSource.data()[0]

                },

                trigger: 'blur',

             })
            );
            $(e.container).find('input[name="agl.Product__c"]').bind('blur',

            $.proxy(utility.GetAGLineDetailsFromProduct, { grid: treeList,

                options: { 
                    parentGrid: $('#promotions').data('kendoGridActionList').dataSource.data()[0]

                },

                trigger: 'blur',

             })
            );


            if( $( e.container ).find('input[name="agl.Product__c"]').length > 0 ) {
                var lookupSearchFilters = [];
                lookupSearchFilters.push( {field: "agl.Product__c", filter: " Company__c = \'" + agreement.Company__c + "\'"});
                $(e.container).find('input[name="agl.Product__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
            }
            if( $( e.container ).find('input[name="agl.Ship_To__c"]').length > 0 ) {
                var lookupSearchFilters = [];
                lookupSearchFilters.push( {field: "agl.Ship_To__c", filter: "RecordType.DeveloperName  = \'Ship_To\'" });
                $(e.container).find('input[name="agl.Ship_To__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
            }
            if( $( e.container ).find('input[name="agl.Product_Reference__c"]').length > 0 ) {
                var lookupSearchFilters = [];
                lookupSearchFilters.push( {field: "agl.Product_Reference__c", filter: " Customer__c = \'" + agreement.Customer__c + "\'  AND Active__c = true "});
                $(e.container).find('input[name="agl.Product_Reference__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
            }
            
            if( $( e.container ).find('input[name="agl.Billing_Category__c"]').length > 0 ) {
                var lookupSearchFilters = [];
                lookupSearchFilters.push( {field: "agl.Billing_Category__c", filter: "Type__c  = \'Billing\'" });
                $(e.container).find('input[name="agl.Billing_Category__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
            }
            if( $( e.container ).find('input[name="agl.Fulfillment_Category__c"]').length > 0 ) {
                var lookupSearchFilters = [];
                lookupSearchFilters.push( {field: "agl.Fulfillment_Category__c", filter: "Type__c  = \'Fulfillment\'" });
                $(e.container).find('input[name="agl.Fulfillment_Category__c"]').data('kendoLookup').options.criteria = lookupSearchFilters;
            }
            if( $( e.container ).find('input[data-role="datetimepicker"]').length > 0 ) {
                var dateTimePickers =  $('input[data-role="datetimepicker"]');
                $.each( dateTimePickers, function( idx, item) {
                    item = $(item).data("kendoDateTimePicker");
                    item.setOptions({ format: "M/d/yyyy", parseFormats: "M/d/yyyy hh:mm"});
                } );
            }
        },
        change: function( e ) {
            var item = { Id: AgreementViewComponent.promoProdPrefix };

            var selectedItem = this.dataItem( this.select() );

            if ( typeof selectedItem !== "undefined" ) {
                if ( selectedItem !== null ) {
						item = selectedItem;
                }
            }

            //  see if this really changed ?
            if ( AgreementViewComponent.promotedProd != item ) {
                AgreementViewComponent.promotedProd = item;

                $.each( AgreementViewComponent.promoProdActionConfig, function() {

                    var regex = /\?[a-zA-Z0-9=]*/;
                    this.content = this.content && this.content.replace( regex, "?id=" + item.id );

                } );
            }
        }
    } ).data( "kendoTreeList" );
    
    utility.elementInit( treeList, false );
    treeList.bind("dataBound", dataBound);
};

function dataBound(e){

        $(".k-grid-edit").each(function () {
                    

            var currentDataItem =  $("#pprod").data("kendoTreeList").dataItem($(this).closest("tr")).agl;
            console.log(currentDataItem);

            if (currentDataItem.Agreement__r && (currentDataItem.Agreement__r.Status__c == 'Approved' && (currentDataItem.Revision_Status__c == 'Approved' || currentDataItem.Revision_Status__c == null))) {
                $(this).addClass('k-state-disabled').attr("disabled",true);
            } else {
                $(this).removeClass('k-state-disabled').attr("disabled",false);
            }
        });
        
        $(".k-grid-delete").each(function () {
                    
            var currentDataItem =  $("#pprod").data("kendoTreeList").dataItem($(this).closest("tr")).agl;

            if (currentDataItem.Agreement__r && (currentDataItem.Agreement__r.Status__c == 'Approved' && (currentDataItem.Revision_Status__c == 'Approved' || currentDataItem.Revision_Status__c == null))) {
                $(this).addClass('k-state-disabled').attr("disabled",true);
            } else {
                $(this).removeClass('k-state-disabled').attr("disabled",false);
            }   
        });
}

},{"../actions/TreeListSaveAction":4,"../utils/AgreementViewHelper":7}]},{},[1])
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJtYWluLmpzIiwic3JjL2FjdGlvbnMvRHJvcGRvd25BY3Rpb25zLmpzIiwic3JjL2FjdGlvbnMvR3JpZFNhdmVBY3Rpb24uanMiLCJzcmMvYWN0aW9ucy9UcmVlTGlzdFNhdmVBY3Rpb24uanMiLCJzcmMvdG9vbGJhcnMvQWdyZWVtZW50TGluZVRvb2xiYXIuanMiLCJzcmMvdG9vbGJhcnMvQWdyZWVtZW50VG9vbGJhci5qcyIsInNyYy91dGlscy9BZ3JlZW1lbnRWaWV3SGVscGVyLmpzIiwic3JjL3V0aWxzL0dyaWRBY3Rpb25MaXN0LmpzIiwic3JjL3V0aWxzL0dyaWREZXRhaWxMaXN0LmpzIiwic3JjL3ZpZXdzL0FncmVlbWVudEdyaWQuanMiLCJzcmMvdmlld3MvQWdyZWVtZW50TGluZUdyaWQuanMiLCJzcmMvdmlld3MvQWdyZWVtZW50TGluZVRyZWVMaXN0LmpzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBO0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNsQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM3REE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2xHQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUMxRkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM3R0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzVDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzdTQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDcFRBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDL1FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzVKQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDdEZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSIsImZpbGUiOiJnZW5lcmF0ZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlc0NvbnRlbnQiOlsiKGZ1bmN0aW9uIGUodCxuLHIpe2Z1bmN0aW9uIHMobyx1KXtpZighbltvXSl7aWYoIXRbb10pe3ZhciBhPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7aWYoIXUmJmEpcmV0dXJuIGEobywhMCk7aWYoaSlyZXR1cm4gaShvLCEwKTt2YXIgZj1uZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK28rXCInXCIpO3Rocm93IGYuY29kZT1cIk1PRFVMRV9OT1RfRk9VTkRcIixmfXZhciBsPW5bb109e2V4cG9ydHM6e319O3Rbb11bMF0uY2FsbChsLmV4cG9ydHMsZnVuY3Rpb24oZSl7dmFyIG49dFtvXVsxXVtlXTtyZXR1cm4gcyhuP246ZSl9LGwsbC5leHBvcnRzLGUsdCxuLHIpfXJldHVybiBuW29dLmV4cG9ydHN9dmFyIGk9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtmb3IodmFyIG89MDtvPHIubGVuZ3RoO28rKylzKHJbb10pO3JldHVybiBzfSkiLCIvKiBnbG9iYWwgJCAqL1xudmFyIGxvYWRHcmlkID0gcmVxdWlyZSggXCIuL3NyYy92aWV3cy9BZ3JlZW1lbnRHcmlkXCIgKTtcbnZhciBsb2FkRGV0YWlsR3JpZCA9IHJlcXVpcmUoIFwiLi9zcmMvdmlld3MvQWdyZWVtZW50TGluZUdyaWRcIiApO1xudmFyIGRyYXdUcmVlTGlzdCA9IHJlcXVpcmUoIFwiLi9zcmMvdmlld3MvQWdyZWVtZW50TGluZVRyZWVMaXN0XCIgKTtcbnZhciB1dGlsaXR5ID0gcmVxdWlyZSggXCIuL3NyYy91dGlscy9BZ3JlZW1lbnRWaWV3SGVscGVyXCIgKTtcblxuJCggZG9jdW1lbnQgKS5vbiggXCJBZ3JlZW1lbnRWaWV3UmVhZHlcIiwgZnVuY3Rpb24oIGUgKSB7XG4gICAgIC8vc2V0dGluZyB3aWR0aCBvZiBncmlkcyBhcyBwZXIgdGhlIHBhcmVudCBjb250YWluZXIgb3V0ZXJXaWR0aFxuICAgICB2YXIgc2lkZWJhcldpZHRoID0gJCggXCIjc2lkZWJhckNlbGxcIiApLm91dGVyV2lkdGgoKSA/ICQoIFwiI3NpZGViYXJDZWxsXCIgKS5vdXRlcldpZHRoKCkgOiAwO1xuICAgICB2YXIgdGFiQmFyV2lkdGggPSAkKCBcIiN0YWJCYXJcIiApLm91dGVyV2lkdGgoKTtcbiAgICAgdmFyIHdpbmRvd1dpZHRoID0gJCggd2luZG93ICkub3V0ZXJXaWR0aCgpO1xuICAgICB2YXIgbWFyZ2lucyA9ICggKCB3aW5kb3dXaWR0aCAtIHRhYkJhcldpZHRoICkgLyAyICk7XG4gICAgIFxuICAgICBpZiAoIHRhYkJhcldpZHRoICkge1xuICAgICAgICAgJCggXCIuYm9keURpdlwiICkub3V0ZXJXaWR0aCggdGFiQmFyV2lkdGggLSBzaWRlYmFyV2lkdGggLSBtYXJnaW5zICApO1xuICAgICAgICAgJCggXCIjbWFpbnBhZ2VcIiApLm91dGVyV2lkdGgoIHRhYkJhcldpZHRoIC0gc2lkZWJhcldpZHRoIC0gbWFyZ2lucyApO1xuICAgICB9XG5cblx0IGxvYWRHcmlkKCk7XG5cdCB1dGlsaXR5LmxvYWRwYW5lbEJhcigpO1xuXG4gICAgICAgIHZhciBncmlkID0gJCggXCIjcHJvbW90aW9uc1wiICkuZGF0YSggXCJrZW5kb0dyaWRBY3Rpb25MaXN0XCIgKTtcbiAgICAgJCgnI3Byb21vdGlvbnMnKS53aWR0aCgkKCcuZ3JpZC1jb250YWluZXInKS53aWR0aCgpKTtcblxufSApO1xuXG4kKCBkb2N1bWVudCApLm9uKCBcInJlZHJhd1RyZWVMaXN0XCIsIGZ1bmN0aW9uKCBlICkge1xuXHR2YXIgZ3JpZCA9ICQoIFwiI3Byb21vdGlvbnNcIiApLmRhdGEoIFwia2VuZG9HcmlkQWN0aW9uTGlzdFwiICk7XG5cdHZhciB0cmVlTGlzdCA9ICQoIFwiI3Bwcm9kXCIgKS5kYXRhKCBcImtlbmRvVHJlZUxpc3RcIiApO1xuXHRcblx0dHJlZUxpc3QuZGVzdHJveSgpO1xuXHQkKCBcIiNwcHJvZFwiICkuZW1wdHkoKTtcblx0ZHJhd1RyZWVMaXN0KCBncmlkLmRhdGFTb3VyY2UuX2RhdGFbMF0gKTtcbn0gKTtcbiIsIi8qIGdsb2JhbCAkICovXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKCBlbGUsIGdyaWQsIHBhZ2UgKSB7XG4gICAgXG4gICAgdmFyIG1lc3NhZ2VFbGVtZW50ID0gZ3JpZC5lbGVtZW50XG4gICAgICAgIC5jbG9zZXN0KCBcImRpdi5ncmlkLWNvbnRhaW5lclwiIClcbiAgICAgICAgLmZpbmQoIFwiZGl2LmdyaWQtbWVzc2FnZTpmaXJzdFwiICk7XG4gICAgICAgIFxuXHR2YXIgYWN0aW9uRHJvcGRvd25WYWwgPSAkKCBcIiNcIiArIGVsZSArIFwiQWN0aW9uRHJvcGRvd25cIiApLnZhbCgpLFxuICAgICAgICBhY3Rpb25Db25maWcgPSBlbGUgKyBcIkFjdGlvbkNvbmZpZ1wiO1xuXG4gICAgdmFyIHNlbGVjdGVkQWN0aW9uQ29uZmlnID0gcGFnZVthY3Rpb25Db25maWddW2FjdGlvbkRyb3Bkb3duVmFsXTtcblxuICAgIHZhciBtZXNzYWdlQ3JlYXRlU2FsZXNPcmRlciA9ICdUaGlzIGFjdGlvbiBjYW4gbm90IGJlIHBlcmZvcm1lZCBvbiBEcmFmdCBhZ3JlZW1lbnQgc3RhdHVzJztcbiAgICB2YXIgcGdyaWQgPSAkKCcjcHJvbW90aW9ucycpLmRhdGEoJ2tlbmRvR3JpZEFjdGlvbkxpc3QnKTtcbiAgICB2YXIgc3RhdHVzdmFsdWUgPSBwZ3JpZC5kYXRhSXRlbShwZ3JpZC5zZWxlY3QoKSkgPyBwZ3JpZC5kYXRhSXRlbShwZ3JpZC5zZWxlY3QoKSkuU3RhdHVzX19jIDogbnVsbDtcblxuXHRpZiAoIHR5cGVvZiBzZWxlY3RlZEFjdGlvbkNvbmZpZyAhPSBcInVuZGVmaW5lZFwiICkge1xuXHRcdHZhciBkaXZJZCA9IHNlbGVjdGVkQWN0aW9uQ29uZmlnLmRpdjtcbiAgICAgICAgdmFyIGF3aW5kb3cgPSAkKCBcIiNcIiArIGRpdklkICk7XG5cblx0XHRhd2luZG93LmVtcHR5KCk7XG5cdFx0YXdpbmRvdy5hcHBlbmQoIFwiPGRpdiBpZD0nXCIgKyBkaXZJZCArIFwid2luZG93Jz48L2Rpdj5cIiApO1xuXG4gICAgICAgIHZhciBhY3Rpb25XaW5kb3cgPSAkKCBcIiNcIiArIGRpdklkICsgXCJ3aW5kb3dcIiApO1xuICAgICAgICB2YXIgb25BY3Rpb25XaW5kb3dDbG9zZSA9IGZ1bmN0aW9uKCkge1xuICAgICAgICAgICAgJCggdGhpcy5lbGVtZW50ICkuZW1wdHkoKTtcbiAgICAgICAgICAgIGlmICggZ3JpZCApIHtcbiAgICAgICAgICAgICAgICBncmlkLmRhdGFTb3VyY2UuX2Rlc3Ryb3llZCA9IFtdO1xuICAgICAgICAgICAgICAgIGdyaWQuZGF0YVNvdXJjZS5yZWFkKCk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH07XG4gICAgICAgIGlmKCBzZWxlY3RlZEFjdGlvbkNvbmZpZy5jb250ZW50LmluZGV4T2YoIFwiaWQ9XCIgKSA9PSAtMSApIHtcbiAgICAgICAgICAgIGlmKCBlbGUgPT0gXCJwcm9tb1wiICkge1xuICAgICAgICAgICAgICAgIEtlbmFuZHlFcnAuTWVzc2FnZSggXCJQbGVhc2UgU2VsZWN0IGFuIEFncmVlbWVudFwiLCBtZXNzYWdlRWxlbWVudCApO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYoIGVsZSA9PSBcInByb21vUHJvZFwiICkge1xuICAgICAgICAgICAgICAgIEtlbmFuZHlFcnAuTWVzc2FnZSggXCJQbGVhc2UgU2VsZWN0IGFuIEFncmVlbWVudCBMaW5lXCIsIG1lc3NhZ2VFbGVtZW50ICk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICAvL0tORFktMTYxNjUgLSBTa2lwICdwcm9tb1Byb2RBY3Rpb25Db25maWcnIC0gQWN0aW9ucyBmcm9tIGxpbmUgZ3JpZCBhbmQgdGhpcyB2YWxpZGF0aW9uIGFwcGxpZXMgb25seSBvbiBhZ3JlZW1lbnQgaGVhZGVyIGdyaWRcbiAgICAgICAgZWxzZSBpZihzdGF0dXN2YWx1ZS50b0xvd2VyQ2FzZSgpICE9ICdhcHByb3ZlZCcgJiYgc3RhdHVzdmFsdWUgIT0gbnVsbCAmJiBhY3Rpb25Ecm9wZG93blZhbC50b0xvd2VyQ2FzZSgpICE9ICdjbG9uZWFncmVlbWVudCcgJiYgYWN0aW9uQ29uZmlnICE9ICdwcm9tb1Byb2RBY3Rpb25Db25maWcnKXtcbiAgICAgICAgICAgICBLZW5hbmR5RXJwLk1lc3NhZ2UoIG1lc3NhZ2VDcmVhdGVTYWxlc09yZGVyLCBtZXNzYWdlRWxlbWVudCApO1xuICAgICAgICB9XG4gICAgICAgIFxuICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgIGFjdGlvbldpbmRvdy5rZW5kb1dpbmRvdygge1xuICAgICAgICAgICAgICAgIHdpZHRoOiBzZWxlY3RlZEFjdGlvbkNvbmZpZy53aWR0aCwgaGVpZ2h0OiBzZWxlY3RlZEFjdGlvbkNvbmZpZy5oZWlnaHQsXG4gICAgICAgICAgICAgICAgaWZyYW1lOiB0cnVlLCBtb2RhbDogdHJ1ZSxcbiAgICAgICAgICAgICAgICB0aXRsZTogc2VsZWN0ZWRBY3Rpb25Db25maWcudGl0bGUsXG4gICAgICAgICAgICAgICAgY29udGVudDogc2VsZWN0ZWRBY3Rpb25Db25maWcuY29udGVudCxcbiAgICAgICAgICAgICAgICBjbG9zZTogb25BY3Rpb25XaW5kb3dDbG9zZSxcbiAgICAgICAgICAgICAgICBkZWFjdGl2YXRlOiBmdW5jdGlvbigpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuZGVzdHJveSgpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0gKTtcbiAgICAgICAgICAgIGFjdGlvbldpbmRvdy5kYXRhKCBcImtlbmRvV2luZG93XCIgKS5jZW50ZXIoKS5vcGVuKCk7ICBcbiAgICAgICAgfVxuICAgICAgICBcbiAgICB9XG59O1xuIiwiLyogZ2xvYmFsIF8gKi9cbi8qIGdsb2JhbCAkICovXG4vKiBnbG9iYWwgVmlzdWFsZm9yY2UgKi9cbi8qIGdsb2JhbCBLZW5hbmR5RXJwICovXG4vKiBnbG9iYWwgU2VyaWFsaXplciAqL1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKCBlICkge1xuICAgIFxuICAgIHZhciBzZWxmID0gdGhpcztcbiAgICB2YXIgZ3JpZCA9IHNlbGYuZ3JpZDtcbiAgICB2YXIgb3B0aW9ucyA9IHNlbGYub3B0aW9ucztcblxuICAgIHZhciBtZXNzYWdlRWxlbWVudCA9IGdyaWQuZWxlbWVudFxuICAgICAgICAuY2xvc2VzdCggXCJkaXYuZ3JpZC1jb250YWluZXJcIiApXG4gICAgICAgIC5maW5kKCBcImRpdi5ncmlkLW1lc3NhZ2U6Zmlyc3RcIiApO1xuXG4gICAgaWYgKCBncmlkLmVkaXRhYmxlICYmICFncmlkLmVkaXRhYmxlLnZhbGlkYXRhYmxlLnZhbGlkYXRlKCkgKSB7XG4gICAgICAgIGUucHJldmVudERlZmF1bHQoKTtcbiAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cblxuICAgIHZhciBjdXJyZW50RGF0YSA9IGdyaWQuZGF0YVNvdXJjZS5kYXRhKCk7XG4gICAgdmFyIHVwZGF0ZWRSb3dzID0gW107XG4gICAgdmFyIG5ld1Jvd3MgPSBbXTtcbiAgICAgICAgICBcbiAgICAkLmVhY2goIGN1cnJlbnREYXRhLCBmdW5jdGlvbiggaW5kZXgsIGl0ZW0gKSB7XG5cbiAgICAgICAgaWYgKCBpdGVtLmlkID09PSBcIlwiIHx8IGl0ZW0uZGlydHkgKSB7XG4gICAgICAgICAgICB2YXIgaXNOZXdSb3cgPSAoIGl0ZW0uaWQgPT09IFwiXCIgKTtcbiAgICAgICAgICAgIGl0ZW0gPSBpdGVtLnRvSlNPTigpO1xuICAgICAgICAgICAgaXRlbSA9IFNlcmlhbGl6ZXIuQ29udmVydFRvU0ZEQ0RhdGUoIGl0ZW0sIHsgZGF0ZUZpZWxkczogb3B0aW9ucy5kYXRlRmllbGRzIH0gKTtcbiAgICAgICAgICAgIGlmICggaXNOZXdSb3cgKSB7XG4gICAgICAgICAgICAgICAgZGVsZXRlIGl0ZW0uSWQ7ICAgICBcbiAgICAgICAgICAgICAgICBuZXdSb3dzLnB1c2goIGl0ZW0gKTtcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgdXBkYXRlZFJvd3MucHVzaCggaXRlbSApO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfSApO1xuXG4gICAgdmFyIGRlbGV0ZWRSb3dzID0gJC5tYXAoIGdyaWQuZGF0YVNvdXJjZS5fZGVzdHJveWVkLCBmdW5jdGlvbiggaXRlbSwgaW5kZXggKSB7XG4gICAgICAgIGl0ZW0gPSBpdGVtLnRvSlNPTigpO1xuICAgICAgICBpdGVtID0gU2VyaWFsaXplci5Db252ZXJ0VG9TRkRDRGF0ZSggaXRlbSwgeyBkYXRlRmllbGRzOiBvcHRpb25zLmRhdGVGaWVsZHMgfSApO1xuICAgICAgICByZXR1cm4gaXRlbTtcbiAgICB9ICk7XG5cbiAgICBpZiAoIG5ld1Jvd3MubGVuZ3RoID09PSAwICYmIHVwZGF0ZWRSb3dzLmxlbmd0aCA9PT0gMCAmJiBkZWxldGVkUm93cy5sZW5ndGggPT09IDAgKSB7XG4gICAgICAgIEtlbmFuZHlFcnAuTWVzc2FnZSggXCJObyBSZWNvcmRzIENoYW5nZWRcIiwgS2VuYW5keUVycC5NZXNzYWdlVHlwZS5JbmZvLCBtZXNzYWdlRWxlbWVudCApO1xuICAgICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgaWYgKCB1cGRhdGVkUm93cy5sZW5ndGggPiAwICkge1xuICAgICAgICB1cGRhdGVkUm93cyA9IFNlcmlhbGl6ZXIuUGFyYW1ldGVyTWFwKCB1cGRhdGVkUm93cyApO1xuICAgIH1cblxuICAgIGlmICggbmV3Um93cy5sZW5ndGggPiAwICkge1xuICAgICAgICBuZXdSb3dzID0gU2VyaWFsaXplci5QYXJhbWV0ZXJNYXAoIG5ld1Jvd3MgKTtcbiAgICB9XG5cbiAgICBpZiAoIGRlbGV0ZWRSb3dzLmxlbmd0aCA+IDAgKSB7XG4gICAgICAgIGRlbGV0ZWRSb3dzID0gU2VyaWFsaXplci5QYXJhbWV0ZXJNYXAoIGRlbGV0ZWRSb3dzICk7XG4gICAgfVxuXG4gICAgdmFyIGNoYW5nZUxpc3RJZHMgPSBfLnVuaW9uKCBfLnBsdWNrKCB1cGRhdGVkUm93cywgXCJJZFwiICksIF8ucGx1Y2soIGRlbGV0ZWRSb3dzLCBcIklkXCIgKSApO1xuXG4gICAgS2VuYW5keUVycC5CbG9ja1VJKCBncmlkLmVsZW1lbnQgKTtcblxuICAgIHZhciBkYXRlRmllbGRzID0gc2VsZi5vcHRpb25zLmRhdGVGaWVsZHMgPyBcbiAgICAgICAgXy5wbHVjayggc2VsZi5vcHRpb25zLmRhdGVGaWVsZHMsIEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5GaWVsZEluZm8uRmllbGQgKSA6IFxuICAgICAgICBudWxsO1xuICAgICBcbiAgICBWaXN1YWxmb3JjZS5yZW1vdGluZy5NYW5hZ2VyLmludm9rZUFjdGlvbihcbiAgICAgICAgb3B0aW9ucy5zYXZlQWN0aW9uLCAgIFxuICAgICAgICB1cGRhdGVkUm93cyxcbiAgICAgICAgbmV3Um93cyxcbiAgICAgICAgZGVsZXRlZFJvd3MsXG4gICAgICAgIGRhdGVGaWVsZHMsXG4gICAgICAgIGZ1bmN0aW9uKCByZXN1bHQsIGV2ZW50ICkge1xuICAgICAgICAgICAgS2VuYW5keUVycC5VbkJsb2NrVUkoIGdyaWQuZWxlbWVudCApOyAgICBcbiAgICAgICAgICAgIGlmICggZXZlbnQudHlwZSA9PSAnZXhjZXB0aW9uJyApIHtcbiAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLk1lc3NhZ2UoIGV2ZW50Lm1lc3NhZ2UsIEtlbmFuZHlFcnAuTWVzc2FnZVR5cGUuRXJyb3IsIG1lc3NhZ2VFbGVtZW50ICk7XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIGlmICggcmVzdWx0LnN1Y2Nlc3MgKSB7XG4gICAgICAgICAgICAgICAgICAgIHZhciBuZXdJZHMgPSBfLmRpZmZlcmVuY2UoIF8ucGx1Y2soIHJlc3VsdC5yZWNvcmRzLCBcIklkXCIgKSwgY2hhbmdlTGlzdElkcyApO1xuXG4gICAgICAgICAgICAgICAgICAgIC8vIHJlZnJlc2ggdGhlIGdyaWRcbiAgICAgICAgICAgICAgICAgICAgZ3JpZC5kYXRhU291cmNlLl9kZXN0cm95ZWQgPSBbXTtcbiAgICAgICAgICAgICAgICAgICAgZ3JpZC5kYXRhU291cmNlLnJlYWQoIHsgbmV3SWRzOiBuZXdJZHMgfSApO1xuICAgICAgICAgICAgICAgICAgICAkKCBkb2N1bWVudCApLnRyaWdnZXIoIFwicmVkcmF3VHJlZUxpc3RcIiApO1xuICAgICAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLk1lc3NhZ2VzKCByZXN1bHQubWVzc2FnZXMsIG1lc3NhZ2VFbGVtZW50ICk7XG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgS2VuYW5keUVycC5NZXNzYWdlcyggcmVzdWx0Lm1lc3NhZ2VzLCBtZXNzYWdlRWxlbWVudCApO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICAgICAgeyBlc2NhcGU6IGZhbHNlIH1cbiAgICApO1xufTtcbiIsIi8qIGdsb2JhbCAkICovXG4vKiBnbG9iYWwgXyAqL1xuLyogZ2xvYmFsIEFncmVlbWVudFZpZXdDb21wb25lbnQgKi9cbi8qIGdsb2JhbCBWaXN1YWxmb3JjZSAqL1xuLyogZ2xvYmFsIEtlbmFuZHlFcnAgKi9cbi8qIGdsb2JhbCBTZXJpYWxpemVyICovXG52YXIgdXRpbGl0eSA9IHJlcXVpcmUoIFwiLi4vdXRpbHMvQWdyZWVtZW50Vmlld0hlbHBlclwiICk7XG5cbm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24oIG9wdGlvbnMsIGRhdGVGaWVsZHMsIGNvbnRleHQgKSB7XG5cblx0dmFyIHRyZWVMaXN0ID0gJCggXCIjcHByb2RcIiApLmRhdGEoIFwia2VuZG9UcmVlTGlzdFwiICk7XG5cbiAgICB2YXIgY29sdW1ucyA9IHRyZWVMaXN0LmNvbHVtbnM7XG5cbiAgICB2YXIgbWVzc2FnZUVsZW1lbnQgPSB0cmVlTGlzdC5lbGVtZW50XG4gICAgICAgIC5jbG9zZXN0KCBcImRpdi5ncmlkLWNvbnRhaW5lclwiIClcbiAgICAgICAgLmZpbmQoIFwiZGl2LmdyaWQtbWVzc2FnZTpmaXJzdFwiICk7XG5cbiAgICB2YXIgaXRlbSA9IG9wdGlvbnMuZGF0YS5tb2RlbHNbMF07XG4gICAgZGVsZXRlIGl0ZW0uaGFzQ2hpbGRyZW47XG4gICAgZGVsZXRlIGl0ZW0uZXhwYW5kZWQ7XG5cbiAgICBpZiAoIGNvbnRleHQgPT0gXCJjcmVhdGVcIiApIHtcbiAgICAgICAgZGVsZXRlIGl0ZW0uYWdsLklkO1xuICAgIH1cblxuICAgIGlmICggY29udGV4dCA9PSBcImRlbGV0ZVwiKSB7XG4gICAgICAgIGlmIChpdGVtLmFnbC5JZCA9PSBudWxsIHx8IGl0ZW0uYWdsLklkLmxlbmd0aCA9PSAwKXtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgIH1cbiAgICBpdGVtID0gU2VyaWFsaXplci5Db252ZXJ0VG9TRkRDRGF0ZSggaXRlbSwgeyBkYXRlRmllbGRzOiBkYXRlRmllbGRzIH0gKTtcbiAgICBcbiAgICAvL1JlbW92ZSB0aGUgZXh0cmEgYXR0cmlidXRlcyBLZW5kbyBHcmlkIGNyZWF0ZXMgZm9yIHN1cHBvcnRpbmcgd3JhcHBlciBjbGFzc2VzXG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBjb2x1bW5zLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgIHZhciBuYW1lID0gY29sdW1uc1tpXS5maWVsZDtcblx0XHRpZiAobmFtZSAmJiBuYW1lLmluZGV4T2YoJy4nKSAhPSAtMSkge1xuXHRcdCAgICBkZWxldGUgaXRlbS5hZ2xbbmFtZV07XG5cdFx0fVxuICAgIH1cbiAgICBcbiAgICBpdGVtLmFnbCA9IHV0aWxpdHkuY29udmVydChpdGVtLmFnbCk7XG4gICAgaXRlbS5zZWdtZW50cyA9IHV0aWxpdHkuY29udmVydChpdGVtLnNlZ21lbnRzKTtcbiAgICBcbiAgICB2YXIgaGFzTm9TZWdtZW50cyA9ICQuaXNFbXB0eU9iamVjdChpdGVtLnNlZ21lbnRzKVxuICAgIEtlbmFuZHlFcnAuQmxvY2tVSSggdHJlZUxpc3QuZWxlbWVudCApO1xuXG4gICAgZGF0ZUZpZWxkcyA9IGRhdGVGaWVsZHMgP1xuICAgICAgICAgXy5wbHVjayggZGF0ZUZpZWxkcywgS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkZpZWxkSW5mby5GaWVsZCApIDogXG4gICAgICAgICBudWxsO1xuICAgICAgICAgXG4gICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC5leHBhbmRlZFJvd3MgPSAkLm1hcCgkKCdbYXJpYS1leHBhbmRlZD1cInRydWVcIl0nKSwgXG4gICAgICAgIGZ1bmN0aW9uIChyb3cpIHtcbiAgICAgICAgICAgIHJldHVybiAkKHJvdykuZGF0YShcInVpZFwiKTtcbiAgICB9KTtcbiAgICBcbiAgICBpdGVtID0gXy5waWNrKGl0ZW0sICdhZ2wnLCAnc2VnbWVudHMnKTtcbiAgICBcbiAgICBWaXN1YWxmb3JjZS5yZW1vdGluZy5NYW5hZ2VyLmludm9rZUFjdGlvbihcbiAgICAgICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC5zYXZlQWdyZWVtZW50TGluZXNBY3Rpb24sXG4gICAgICAgIGl0ZW0sXG4gICAgICAgIGRhdGVGaWVsZHMsXG4gICAgICAgIGNvbnRleHQsXG4gICAgICAgIGZ1bmN0aW9uKCByZXN1bHQsIGV2ZW50ICkge1xuICAgICAgICAgICAgS2VuYW5keUVycC5VbkJsb2NrVUkoIHRyZWVMaXN0LmVsZW1lbnQgKTsgIFxuICAgICAgICAgICAgaWYgKCBldmVudC50eXBlID09IFwiZXhjZXB0aW9uXCIgKSB7XG4gICAgICAgICAgICAgICAgS2VuYW5keUVycC5NZXNzYWdlKCBldmVudC5tZXNzYWdlLCBLZW5hbmR5RXJwLk1lc3NhZ2VUeXBlLkVycm9yLCBtZXNzYWdlRWxlbWVudCApO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBpZiAoIHJlc3VsdC5zdWNjZXNzICkge1xuICAgICAgICAgICAgICAgICAgICBcbiAgICAgICAgICAgICAgICAgICAgdHJlZUxpc3Qub25lKFwiZGF0YUJvdW5kXCIsIGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICAgICAgdmFyIHJvd3MgPSB0cmVlTGlzdC50Ym9keS5jaGlsZHJlbigpLmZpbHRlcihmdW5jdGlvbiAoaWR4LCByb3cpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1cm4gJC5pbkFycmF5KCQocm93KS5kYXRhKFwidWlkXCIpLCBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmV4cGFuZGVkUm93cykgPj0gMDtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgICAgICBcbiAgICAgICAgICAgICAgICAgICAgZm9yKHZhciBpID0gMDsgaSA8IHJvd3MubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRyZWVMaXN0LmV4cGFuZChyb3dzW2ldKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgICAgICAgICAgdHJlZUxpc3QuZGF0YVNvdXJjZS5fZGVzdHJveWVkID0gW107XG4gICAgICAgICAgICAgICAgICAgIHRyZWVMaXN0LmRhdGFTb3VyY2UucmVhZCgpO1xuICAgICAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLk1lc3NhZ2VzKCByZXN1bHQubWVzc2FnZXMsIG1lc3NhZ2VFbGVtZW50ICk7XG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgS2VuYW5keUVycC5NZXNzYWdlcyggcmVzdWx0Lm1lc3NhZ2VzLCBtZXNzYWdlRWxlbWVudCAgKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIHsgZXNjYXBlOiBmYWxzZSB9XG4gICAgKTtcbn07XG4iLCIvKiBnbG9iYWwgJCAqL1xuLyogZ2xvYmFsIEFncmVlbWVudFZpZXdDb21wb25lbnQgKi9cbnZhciBkcm9wRG93bkFjdGlvbiA9IHJlcXVpcmUoIFwiLi4vYWN0aW9ucy9Ecm9wZG93bkFjdGlvbnNcIiApO1xudmFyIEFncmVlbWVudExpbmVTYXZlID0gcmVxdWlyZSggXCIuLi9hY3Rpb25zL0dyaWRTYXZlQWN0aW9uXCIgKTtcblxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiggZ3JpZCwgaXNSZWZyZXNoICkge1xuICAgICQoIGdyaWQuZWxlbWVudCApLmZpbmQoIFwiLmdyaWQtYWRkLWxpbmUtY29tbWFuZFwiICkuYmluZCggXCJjbGlja1wiLCBmdW5jdGlvbiggZSApIHtcbiAgICAgICAgZ3JpZC5hZGRSb3coKTtcbiAgICB9ICk7XG5cbiAgICAvLyB1bmJpbmQgZ3JpZCBzYXZlIGNvbW1hbmRcbiAgICBncmlkLndyYXBwZXIub2ZmKCBcImNsaWNrXCIsIFwiLmdyaWQtc2F2ZS1saW5lLWNvbW1hbmRcIiApOyAgIFxuXG4gICAgLy8gYmluZCBncmlkIHNhdmUgY29tbWFuZFxuICAgIGdyaWQud3JhcHBlci5vbiggXCJjbGlja1wiLCBcIi5ncmlkLXNhdmUtbGluZS1jb21tYW5kXCIsICQucHJveHkoIEFncmVlbWVudExpbmVTYXZlLCB7XG4gICAgICAgIGdyaWQ6IGdyaWQsXG4gICAgICAgIG9wdGlvbnM6IHtcbiAgICAgICAgICAgIHNhdmVBY3Rpb246IEFncmVlbWVudFZpZXdDb21wb25lbnQuc2F2ZUFncmVlbWVudExpbmVzQWN0aW9uLFxuICAgICAgICAgICAgY29uZmlnOiBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmFncmVlbWVudExpbmVzR3JpZENvbmZpZyxcbiAgICAgICAgICAgIGRhdGVGaWVsZHM6IEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50TGluZURhdGVGaWVsZHNcbiAgICAgICAgfVxuICAgIH0gKSApO1xuXG4gICAgJCggZ3JpZC5lbGVtZW50ICkuZmluZCggXCIuZ3JpZC1jYW5jZWwtbGluZS1jb21tYW5kXCIgKS5iaW5kKCBcImNsaWNrXCIsIGZ1bmN0aW9uKCBlICkge1xuICAgICAgICBncmlkLmNhbmNlbENoYW5nZXMoKTsgICAgICAgLy8gZG8gdGhlIGNhbmNlbCB3b3JrXG4gICAgICAgIGUucHJldmVudERlZmF1bHQoKTtcbiAgICB9ICk7XG4gICAgICAgXG4gICAgJCggXCIjcHJvbW9Qcm9kQWN0aW9uRHJvcGRvd25cIiApLmtlbmRvRHJvcERvd25MaXN0KCB7XG4gICAgICAgICBvcHRpb25MYWJlbDogXCJcIixcbiAgICAgICAgIGRhdGFUZXh0RmllbGQ6IFwidGV4dFwiLFxuICAgICAgICAgZGF0YVZhbHVlRmllbGQ6IFwidmFsdWVcIixcbiAgICAgICAgIGRhdGFTb3VyY2U6IEFncmVlbWVudFZpZXdDb21wb25lbnQucHJvbW9kUHJvZEFjdGlvbkRhdGFzb3VyY2VcbiAgICAgfSApO1xuICAgIFxuICAgICQoIFwiLmdyaWQtdmlldy1vcHRpb25zXCIgKS5rZW5kb0Ryb3BEb3duTGlzdCgge1xuICAgICAgICAgZGF0YVRleHRGaWVsZDogXCJ0ZXh0XCIsXG4gICAgICAgICBkYXRhVmFsdWVGaWVsZDogXCJ2YWx1ZVwiLFxuICAgICAgICAgZGF0YVNvdXJjZTogQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcHJvZEdyaWRWaWV3cyxcbiAgICAgICAgIGRhdGFCb3VuZDogZnVuY3Rpb24oZSl7XG4gICAgICAgICAgICAvL1Nob3cgZGVmYXVsdCBncmlkIHZpZXdcbiAgICAgICAgICAgIGZpZWxkTmFtZXMgPSBfLnZhbHVlcyhfLnBpY2soQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcHJvZEdyaWRWaWV3RmllbGRzLCB0aGlzLmRhdGFTb3VyY2UuX2RhdGFbMF0udmFsdWUpKVswXTtcblxuICAgICAgICAgICAgRGlzcGxheVZpZXdGaWVsZHMoZmllbGROYW1lcyk7XG4gICAgICAgICAgIFxuICAgICAgICB9LFxuICAgICAgICBjaGFuZ2U6IGZ1bmN0aW9uKGUpIHsgIFxuXG4gICAgICAgICAgICB2YXIgZmllbGROYW1lcyA9IEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50TGluZUZpZWxkTmFtZXM7XG5cbiAgICAgICAgICAgIGZvciAodmFyIGZsZCBpbiBmaWVsZE5hbWVzKSB7XG4gICAgICAgICAgICAgICAgZ3JpZC5oaWRlQ29sdW1uKGZpZWxkTmFtZXNbZmxkXSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIGZpZWxkTmFtZXMgPSBfLnZhbHVlcyhfLnBpY2soQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcHJvZEdyaWRWaWV3RmllbGRzLCB0aGlzLnZhbHVlKCkpKVswXTtcblxuICAgICAgICAgICAgRGlzcGxheVZpZXdGaWVsZHMoZmllbGROYW1lcyk7XG4gICAgICAgICBcbiAgICAgICAgfVxuICAgICB9ICk7XG4gICAgXG4gICAgZnVuY3Rpb24gRGlzcGxheVZpZXdGaWVsZHMoZmllbGROYW1lcykge1xuICAgICAgICB2YXIgc2VnbWVudFByZWZpeCA9ICdhZ2wuQWNjb3VudGluZ19TZWdtZW50X19yLic7XG4gICAgICAgIHZhciBpID0gLTE7Ly9TdGFydGluZyBpbmRleCBvZiBWaWV3IGNvbHVtbnMoQWZ0ZXIgY2hlY2tib3gsIGVycm9ycyBhbmQgaWQpXG4gICAgICAgIGZvciAoZmxkID0gMDsgZmxkIDwgZmllbGROYW1lcy5sZW5ndGg7IGZsZCsrKSB7IFxuICAgICAgICAgICAgaSA9IGkgKyAxO1xuICAgICAgICAgICAgLy9HZXQgY29sdW1uIGluZGV4IGZvciBmaWVsZCBuYW1lXG4gICAgICAgICAgICB2YXIgY29sSW5kZXggPSBHZXRDb2x1bW5JbmRleEZyb21OYW1lKGdyaWQsIGZpZWxkTmFtZXNbZmxkXSk7XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIGlmKGZpZWxkTmFtZXNbZmxkXS5sZW5ndGggPj0gc2VnbWVudFByZWZpeC5sZW5ndGggJiYgZmllbGROYW1lc1tmbGRdLmluZGV4T2Yoc2VnbWVudFByZWZpeCkgPiAtMSl7XG5cbiAgICAgICAgICAgICAgICAvL0NoYW5nZSB0aGUgQUdMIGZpZWxkcyB0byBzZWdtZW50cyBmaWVsZHNcbiAgICAgICAgICAgICAgICB2YXIgc2VnbWVudEZpZWxkTmFtZSA9ICdzZWdtZW50cy4nICsgZmllbGROYW1lc1tmbGRdLnN1YnN0cmluZyhmaWVsZE5hbWVzW2ZsZF0uaW5kZXhPZihzZWdtZW50UHJlZml4KSArIHNlZ21lbnRQcmVmaXgubGVuZ3RoKTtcblxuICAgICAgICAgICAgICAgIC8vR2V0IHRoZSBjb2x1bW4gaW5kZXggZm9yIHNlZ21lbnQgZmllbGRzXG4gICAgICAgICAgICAgICAgY29sSW5kZXggPSBHZXRDb2x1bW5JbmRleEZyb21OYW1lKGdyaWQsIHNlZ21lbnRGaWVsZE5hbWUpO1xuICAgICAgICAgICAgfSBcblxuICAgICAgICAgICAgLy9TaG93IGNvbHVtbnNcbiAgICAgICAgICAgIGlmKGZpZWxkTmFtZXNbZmxkXSAhPSAnYWdsLklkJyl7XG4gICAgICAgICAgICAgICAgLy9SZS1vcmRlciBjb2x1bW5zIGJhc2VkIG9uIHRoZSBmaWVsZCBzZXQgb3JkZXJcbiAgICAgICAgICAgICAgICBncmlkLnJlb3JkZXJDb2x1bW4oaSwgZ3JpZC5jb2x1bW5zW2NvbEluZGV4XSk7XG4gICAgICAgICAgICAgICAgZ3JpZC5zaG93Q29sdW1uKGkpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICBcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBHZXRDb2x1bW5JbmRleEZyb21OYW1lKGdyaWQsIGZpZWxkTmFtZSkge1xuICAgICAgICB2YXIgaW5kZXggPSAtMTtcbiAgICAgICAgdmFyIGNvbHVtbnMgPSBncmlkLmNvbHVtbnM7XG4gICAgICAgIGlmIChjb2x1bW5zLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgY29sdW1ucy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgICAgIGlmIChjb2x1bW5zW2ldLmZpZWxkID09IGZpZWxkTmFtZSkgeyAvLyBjb2x1bW5zW2ldLnRpdGxlIC0tIFlvdSBjYW4gYWxzbyB1c2UgdGl0bGUgcHJvcGVydHkgaGVyZSBidXQgZm9yIHRoaXMgeW91IGhhdmUgdG8gYXNzaWduIHRpdGxlIGZvciBhbGwgY29sdW1uc1xuICAgICAgICAgICAgICAgICAgICBpbmRleCA9IGk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHJldHVybiBpbmRleDtcbiAgICB9XG5cblxuICAgICQoIGdyaWQuZWxlbWVudCApLmZpbmQoIFwiLmstZ3JpZC1wcm9tb1Byb2RBY3Rpb25Hb1wiICkuYmluZCggXCJjbGlja1wiLCBmdW5jdGlvbiggZSApIHtcbiAgICAgICAgaWYgKCAhaXNSZWZyZXNoICkge1xuICAgICAgICAgICAgZHJvcERvd25BY3Rpb24oIFwicHJvbW9Qcm9kXCIsIGdyaWQsIEFncmVlbWVudFZpZXdDb21wb25lbnQgKTtcbiAgICAgICAgfVxuICAgICAgICAgZS5zdG9wSW1tZWRpYXRlUHJvcGFnYXRpb24oKVxuICAgIH0gKTtcbn07XG4iLCIvKiBnbG9iYWwgJCAqL1xuLyogZ2xvYmFsIEFncmVlbWVudFZpZXdDb21wb25lbnQgKi9cbnZhciBkcm9wRG93bkFjdGlvbiA9IHJlcXVpcmUoIFwiLi4vYWN0aW9ucy9Ecm9wZG93bkFjdGlvbnNcIiApO1xudmFyIEFncmVlbWVudFNhdmUgPSByZXF1aXJlKCBcIi4uL2FjdGlvbnMvR3JpZFNhdmVBY3Rpb25cIiApO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKCBncmlkLCBpc1JlZnJlc2ggKSB7XG5cbiAgICAkKCBncmlkLmVsZW1lbnQgKS5maW5kKCBcIi5ncmlkLWFkZC1hZ3JlZW1lbnQtY29tbWFuZFwiICkuYmluZCggXCJjbGlja1wiLCBmdW5jdGlvbiggZSApIHtcbiAgICAgICAgZ3JpZC5hZGRSb3coKTsgICAgICAgLy8gZG8gdGhlIGNhbmNlbCB3b3JrXG4gICAgICAgIGUucHJldmVudERlZmF1bHQoKTtcbiAgICB9ICk7XG5cbiAgICAgLy8gdW5iaW5kIGdyaWQgc2F2ZSBjb21tYW5kXG4gICAgZ3JpZC53cmFwcGVyLm9mZiggXCJjbGlja1wiLCBcIi5ncmlkLXNhdmUtYWdyZWVtZW50LWNvbW1hbmRcIiApO1xuXG4gICAgLy8gYmluZCBncmlkIHNhdmUgY29tbWFuZFxuICAgIGdyaWQud3JhcHBlci5vbiggXCJjbGlja1wiLCBcIi5ncmlkLXNhdmUtYWdyZWVtZW50LWNvbW1hbmRcIiwgJC5wcm94eSggQWdyZWVtZW50U2F2ZSwge1xuICAgICAgICBncmlkOiBncmlkLFxuICAgICAgICBvcHRpb25zOiB7XG4gICAgICAgICAgICBzYXZlQWN0aW9uOiBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnNhdmVBZ3JlZW1lbnRBY3Rpb24sXG4gICAgICAgICAgICBjb25maWc6IEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50R3JpZENvbmZpZyxcbiAgICAgICAgICAgIGRhdGVGaWVsZHM6IEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50RGF0ZUZpZWxkcygpXG4gICAgICAgIH1cbiAgICB9ICkgKTtcblxuICAgICQoIGdyaWQuZWxlbWVudCApLmZpbmQoIFwiLmdyaWQtY2FuY2VsLWFncmVlbWVudC1jb21tYW5kXCIgKS5iaW5kKCBcImNsaWNrXCIsIGZ1bmN0aW9uKCBlICkge1xuICAgICAgICBncmlkLmNhbmNlbENoYW5nZXMoKTsgICAgICAgLy8gZG8gdGhlIGNhbmNlbCB3b3JrXG4gICAgICAgIGUucHJldmVudERlZmF1bHQoKTtcbiAgICB9ICk7XG4gICAgXG4gICAgJCggXCIjcHJvbW9BY3Rpb25Ecm9wZG93blwiICkua2VuZG9Ecm9wRG93bkxpc3QoIHtcbiAgICAgICAgIG9wdGlvbkxhYmVsOiBcIlwiLFxuICAgICAgICAgZGF0YVRleHRGaWVsZDogXCJ0ZXh0XCIsXG4gICAgICAgICBkYXRhVmFsdWVGaWVsZDogXCJ2YWx1ZVwiLFxuICAgICAgICAgZGF0YVNvdXJjZTogQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcm9tb3Rpb25BY3Rpb25EYXRhc291cmNlXG4gICAgIH0gKTsgICBcbiAgICAgXG4gICAgJCggZ3JpZC5lbGVtZW50ICkuZmluZCggXCIuay1ncmlkLXByb21vQWN0aW9uR29cIiApLmJpbmQoIFwiY2xpY2tcIiwgZnVuY3Rpb24oIGUgKSB7XG4gICAgICAgIGlmICggIWlzUmVmcmVzaCApIHtcbiAgICAgICAgICAgIGRyb3BEb3duQWN0aW9uKCBcInByb21vXCIsIGdyaWQsIEFncmVlbWVudFZpZXdDb21wb25lbnQgKTtcbiAgICAgICAgfVxuICAgICAgICBlLnN0b3BJbW1lZGlhdGVQcm9wYWdhdGlvbigpXG4gICAgfSApO1xufTtcbiIsIi8qIGdsb2JhbCBTZXJpYWxpemVyICovXG4vKiBnbG9iYWwgQWdyZWVtZW50Vmlld0NvbXBvbmVudCAqL1xuLyogZ2xvYmFsICQgKi9cbnZhciBBZ3JlZW1lbnRUb29sYmFyID0gcmVxdWlyZSggXCIuLi90b29sYmFycy9BZ3JlZW1lbnRUb29sYmFyXCIgKTtcbnZhciBBZ3JlZW1lbnRMaW5lVG9vbGJhciA9IHJlcXVpcmUoIFwiLi4vdG9vbGJhcnMvQWdyZWVtZW50TGluZVRvb2xiYXJcIiApO1xuXG5tb2R1bGUuZXhwb3J0cyA9ICggZnVuY3Rpb24oKSB7XG5cblx0ZnVuY3Rpb24gaXNFZGl0YWJsZSggZmllbGROYW1lLCBtb2RlbCApIHtcblxuXHRcdC8vIEtORFktNDY1MSBubyBjaGFuZ2UgdG8gdHlwZSBmaWVsZCBvbmNlIHRoZSByZWNvcmQgaXMgc2F2ZWRcblx0ICAgIGlmICggZmllbGROYW1lID09IFwiVHlwZV9fY1wiICYmIG1vZGVsLmlzTmV3KCkgIT09IHRydWUgKSB7XG5cdFx0XHRyZXR1cm4gZmFsc2U7XG5cdFx0fSBcblx0ICAgIHJldHVybiB0cnVlO1xuXHR9XG5cblx0cmV0dXJuIHtcblx0XHRsb2FkcGFuZWxCYXI6IGZ1bmN0aW9uKCkge1xuXHRcdFx0JCggXCIjcGFuZWxCYXJcIiApLmtlbmRvUGFuZWxCYXIoIHtcblx0XHQgICAgICAgIGV4cGFuZE1vZGU6IFwibXVsdGlwbGVcIlxuXHRcdCAgICB9ICk7XG5cdFx0fSxcblxuXHRcdGNoZWNrQmVmb3JlRWRpdDogZnVuY3Rpb24oIGUgKSB7XG5cdFx0XHR2YXIgY29sdW1uSW5kZXggPSB0aGlzLmNlbGxJbmRleCggZS5jb250YWluZXIgKTtcblx0XHQgICAgdmFyIGZpZWxkTmFtZSA9IHRoaXMudGhlYWQuZmluZCggXCJ0aFwiICkuZXEoIGNvbHVtbkluZGV4ICkuZGF0YSggXCJmaWVsZFwiICk7ICAgICAgXG5cdFx0ICAgIGlmICggIWlzRWRpdGFibGUoIGZpZWxkTmFtZSwgZS5tb2RlbCApICkge1xuXHRcdCAgICAgICAgZS5wcmV2ZW50RGVmYXVsdCgpO1xuXHRcdCAgICB9XG5cdFx0fSxcblxuXHRcdGVsZW1lbnRJbml0OiBmdW5jdGlvbiggZWxlLCBpc1JlZnJlc2ggKSB7XG5cdFx0XHRpZiAoIGVsZS5lbGVtZW50LmNvbnRleHQuaWQgPT0gXCJwcm9tb3Rpb25zXCIgKSB7ICAgICAgICAgICAgICAgXG5cblx0XHQgICAgICAgIC8vdmFyIHJvdyA9IGdyaWQuYm9keS5maXJzdENoaWxkOyAvLyBkZWZhdWx0IHRvIGZpcnN0IHJvd1xuXHRcdCAgICAgICAgLy9jb25zb2xlLmxvZyhyb3cpO1xuXHRcdCAgICAgICAgLy9jb25zb2xlLmxvZyhncmlkKTtcblx0XHQgICAgICAgIC8vZ3JpZC5zZWxlY3Qocm93KTtcblx0XHQgICAgICAgIEFncmVlbWVudFRvb2xiYXIoIGVsZSwgZmFsc2UgKTtcblx0XHQgICAgfSBlbHNlIGlmICggZWxlLmVsZW1lbnQuY29udGV4dC5pZCA9PSBcInBwcm9kXCIgKSB7XG5cdFx0ICAgICAgICBBZ3JlZW1lbnRMaW5lVG9vbGJhciggZWxlLCBmYWxzZSApO1xuXHRcdCAgICB9XG5cdFx0fSxcblxuXHRcdGdldEFncmVlbWVudEJ1dHRvbnM6IGZ1bmN0aW9uKCkge1xuXHRcdFx0dmFyIGJ1dHRvbiA9IHt9O1xuXG5cdFx0XHRpZiAoIEFncmVlbWVudFZpZXdDb21wb25lbnQucGxhbklkICkge1xuXHRcdFx0XHRidXR0b24gPSB7IFxuXHRcdFx0XHRcdG5hbWU6IFwiYWRkQWdyZWVtZW50XCIsIFxuXHRcdFx0XHRcdHRleHQ6XCJcIiwgXG5cdFx0XHRcdFx0dGVtcGxhdGU6IFwiPGlucHV0IHR5cGU9J2J1dHRvbicgdmFsdWU9J0FkZCBOZXcnIGNsYXNzPSdidG4gZ3JpZC1hZGQtYWdyZWVtZW50LWNvbW1hbmQnIC8+XCIgXG5cdFx0XHRcdH07XG5cdFx0XHR9IGVsc2Uge1xuXHRcdFx0XHRidXR0b24gPSB7IFxuXHRcdFx0XHRcdG5hbWU6IFwiYWRkQWdyZWVtZW50XCIsIFxuXHRcdFx0XHRcdHRleHQ6XCJcIiwgXG5cdFx0XHRcdFx0dGVtcGxhdGU6IFwiPGlucHV0IHR5cGU9J2hpZGRlbicgdmFsdWU9J0FkZCBOZXcnIGNsYXNzPSdidG4gZ3JpZC1hZGQtYWdyZWVtZW50LWNvbW1hbmQnIC8+XCIgXG5cdFx0XHRcdH07XG5cdFx0XHR9XG5cdFx0XHRyZXR1cm4gYnV0dG9uO1xuXHRcdH0sXG5cdFx0XG5cdFx0cmVhcHBseU5hbWVzcGFjZTogZnVuY3Rpb24oZGF0YSwgbmFtZXNwYWNlKSB7IFxuXHRcdFx0Ly8gcmVhcHBseSB0aGUgbmFtZXNwYWNlIGZyb20ganNvbiBvYmplY3QsIHJlY3Vyc2l2ZVxuXHRcdFx0XG5cdFx0XHRmb3IgKHZhciBrZXkgaW4gZGF0YSkge1xuXHRcdCAgICBcdGlmICh0eXBlb2Yga2V5ID09PSBcInN0cmluZ1wiKSB7XG5cdFx0XHRcdFx0XG5cdFx0XHRcdFx0aWYoa2V5ICE9PSBcIklkXCIgJiYga2V5ICE9PSBcIk5hbWVcIikge1xuXHRcdFx0XHRcdFx0dmFyIG5ld0tleSA9IGtleS5yZXBsYWNlKC9eLywgbmFtZXNwYWNlKTtcblx0XHRcdCAgICAgICAgICAgXHRpZiAobmV3S2V5ICE9PSBrZXkpIHtcblx0XHRcdCAgICAgICAgICAgIFx0ZGF0YVtuZXdLZXldID0gZGF0YVtrZXldO1xuXHRcdFx0ICAgICAgICAgICAgICAgXHRkZWxldGUoZGF0YVtrZXldKTtcblx0XHRcdCAgICAgICAgICAgXHR9XG5cdFx0XHQgICAgICAgICAgIFxuXHRcdFx0ICAgICAgICAgICBcdGlmICh0eXBlb2YgZGF0YVtuZXdLZXldID09PSBcIm9iamVjdFwiKSB7XG5cdFx0XHQgICAgICAgICAgIFx0XHR0aGlzLnJlYXBwbHlOYW1lc3BhY2UoZGF0YVtuZXdLZXldLCBuYW1lc3BhY2UpO1xuXHRcdFx0ICAgICAgICAgICBcdH1cblx0XHRcdFx0XHR9XG5cdFx0ICAgICAgICB9XG5cdFx0ICAgIH1cblx0XHR9LFxuXHRcdFxuXHRcdGNvbnZlcnQ6IGZ1bmN0aW9uKHZhbHVlcykge1xuXHQgICAgXHRmb3IgKHZhciBrZXkgaW4gdmFsdWVzKSB7XG5cdCAgICBcdFx0Ly8gUmVtb3ZlcyBhbGwgX19yIGFuZCBfX2N1c3RvbSBwcm9wZXJ0aWVzIGZyb20gdGhlIHJlY29yZCBnZXR0aW5nIHNhdmVkLCBhcyB3ZSBjYW4ndCB1c2UgdGhlbSBpbiBETUxcblx0XHRcdFx0aWYgKCgoL19fci9pLnRlc3Qoa2V5KSkpIHx8ICgvX19jdXN0b20kL2kudGVzdChrZXkpKSkge1xuXHQgICAgICAgICAgICBcdGRlbGV0ZSB2YWx1ZXNba2V5XTtcblx0XHRcdFx0fVxuXHRcdFx0XHRlbHNlIGlmICgoL19fci9pLnRlc3Qoa2V5KSkpIHtcdC8vIFJlbW92ZSBhbGwgX19yIGlmIHRoZSBJZCBpcyBudWxsXG5cdFx0XHRcdFx0aWYgKHZhbHVlc1trZXldICYmICQuaXNQbGFpbk9iamVjdCh2YWx1ZXNba2V5XSkgJiYgIXZhbHVlc1trZXldLklkKSB7XG5cdFx0XHRcdFx0XHRkZWxldGUgdmFsdWVzW2tleV07XG5cdFx0XHRcdFx0fVxuXHRcdFx0XHR9XG5cdFx0XHRcdFxuXHQgICAgICAgIFx0dmFyIHZhbHVlID0gdmFsdWVzW2tleV07XG5cdFxuXHQgICAgICAgICAgICBpZiAodmFsdWUgaW5zdGFuY2VvZiBEYXRlKSB7XG5cdCAgICAgICAgICAgIFx0dmFsdWVzW2tleV0gPSAodmFsdWUpID8gRGF0ZS5wYXJzZSh2YWx1ZSkgOiBudWxsO1xuXHRcdFx0XHR9XG5cdFx0XHR9XG5cdCAgICAgICAgXG5cdFx0XHRyZXR1cm4gdmFsdWVzO1xuXHRcdH0sXG4gICAgICAgIFxuICAgICAgICBnZXRGaWVsZExpc3Q6IGZ1bmN0aW9uKGZpZWxkcykge1xuICAgICAgICAgICAgdmFyIGZpZWxkTGlzdCA9IEpTT04ucGFyc2UoZmllbGRzKTtcbiAgICAgICAgICAgICQuZWFjaChmaWVsZExpc3QsIGZ1bmN0aW9uKCkge1xuICAgICAgICAgICAgICAgIHRoaXMud2lkdGggPSB0aGlzLndpZHRoID8gdGhpcy53aWR0aCA6ICcxMDBweCc7XG4gICAgICAgICAgICAgICAgLy9UbyBhZGQgYSBzY3JvbGwgYmFyLCBzZXQgdGhlIHdpZHRoIG9mIGVhY2ggY29sdW1uIGluIHBpeGVscyAtIEtORFktMTA2MjNcdFxuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICByZXR1cm4gZmllbGRMaXN0O1xuICAgICAgICB9LFxuXG4gICAgICAgIEdldEFHTGluZURldGFpbHNGcm9tUHJvZHVjdFJlZjogZnVuY3Rpb24oZSkge1xuICAgICAgICAgICAgZGVidWdnZXI7XG5cdFx0XHR2YXIgc2VsZiA9IHRoaXM7XG4gICAgICAgICAgICB2YXIgZ3JpZCA9IHRoaXMuZ3JpZDtcbiAgICAgICAgICAgIHZhciBvcHRpb25zID0gc2VsZi5ncmlkLm9wdGlvbnM7XG4gICAgICAgICAgICB2YXIgY2VsbCA9IGdyaWQuZWxlbWVudDtcbiAgICAgICAgICAgIHZhciByb3cgPSAkKGUudGFyZ2V0KS5jbG9zZXN0KFwidHJcIik7XG4gICAgICAgICAgICB2YXIgZGF0YUl0ZW0gPSBncmlkLmRhdGFJdGVtKHJvdyk7XG5cbiAgICAgICAgICAgIGNvbnNvbGUubG9nKCdFbnRlcmVkIGludG8gbXkgZnVuY3Rpb24nLCBlICk7XG5cbiAgICAgICAgICAgIHZhciBwcm9kdWN0UmVmZXJlbmNlSWQgPSBkYXRhSXRlbS5nZXQoJ2FnbC5Qcm9kdWN0X1JlZmVyZW5jZV9fci5JZCcpID8gZGF0YUl0ZW0uZ2V0KCdhZ2wuUHJvZHVjdF9SZWZlcmVuY2VfX3IuSWQnKSA6IG51bGw7XG4gICAgICAgICAgICAgICAgICAgIGNvbnNvbGUubG9nKCdwcm9kdWN0UmVmZXJlbmNlSWQnLCBwcm9kdWN0UmVmZXJlbmNlSWQpO1xuXG4gICAgICAgICAgICB2YXIgZGF0ZUZpZWxkcyA9ICQuZXh0ZW5kKHRydWUsIFtdLCBvcHRpb25zLmRhdGVGaWVsZHMpO1xuICAgICAgICBcbiAgICAgICAgICAgIHZhciBhZ3JlZW1lbnRJZCA9IHNlbGYub3B0aW9ucy5wYXJlbnRHcmlkLklkO1xuICAgICAgICAgICAgdmFyIGFncmVlbWVudCA9IHNlbGYub3B0aW9ucy5wYXJlbnRHcmlkO1xuICAgICAgICAgICAgdmFyIGFnbXRMaW5lcyA9IHt9O1xuICAgICAgICAgICAgdmFyIGFnbXRMaW5lc0xpc3QgPSBbXTtcbiAgICAgICAgICAgIGFnbXRMaW5lc0xpc3QucHVzaChkYXRhSXRlbS5nZXQoJ2FnbCcpKTsgXG4gICAgICAgICAgICBhZ210TGluZXMgPSAkLm1hcChhZ210TGluZXNMaXN0LCBmdW5jdGlvbihpdGVtLCBpbmRleCkge1xuICAgICAgICAgICAgICAgIGl0ZW0gPSBpdGVtLnRvSlNPTigpO1xuICAgICAgICAgICAgICAgIGl0ZW0gPSBTZXJpYWxpemVyLkNvbnZlcnRUb1NGRENEYXRlKGl0ZW0sIHsgZGF0ZUZpZWxkczogZGF0ZUZpZWxkcyB9KTtcbiAgICAgICAgICAgICAgICByZXR1cm4gaXRlbTtcbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgaWYgKGFnbXRMaW5lcy5sZW5ndGggPiAwKSB7XG4gICAgICAgICAgICBcdGFnbXRMaW5lcyA9IFNlcmlhbGl6ZXIuUGFyYW1ldGVyTWFwKGFnbXRMaW5lcyk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICAvKioqXG4gICAgICAgICAgICAqKiBOZWVkIHRvIHJldmlzaXQgdGhpcyB3aGVuIG5lZWRlZCwgZm9yIG5vdyBoYXZlIHVzZWQgSlMgb2JqZWN0IHRvIHN0b3JlIHRoZSB2YWx1ZXMgKG9taXR0ZWQgbnVsbCB2YWx1ZXMgKXRoYXQgYXJlIHVzZWQgaW4gdGhlIHJlbW90ZSBhY3Rpb24gXG4gICAgICAgICAgICAqKioqL1xuICAgICAgICAgICAgdmFyIHRtcEFnbCA9IHt9O1xuICAgICAgICAgICAgdG1wQWdsWydBZ3JlZW1lbnRfX2MnXSA9IGFnbXRMaW5lc1swXVsnQWdyZWVtZW50X19jJ107XG4gICAgICAgICAgICB0bXBBZ2xbJ1ByaWNlX1R5cGVfX2MnXSA9IGFnbXRMaW5lc1swXVsnUHJpY2VfVHlwZV9fYyddO1xuICAgICAgICAgICAgdG1wQWdsWydQcm9kdWN0X1R5cGVfX2MnXSA9IGFnbXRMaW5lc1swXVsnUHJvZHVjdF9UeXBlX19jJ107XG4gICAgICAgICAgICB0bXBBZ2xbJ1Byb2R1Y3RfUmVmZXJlbmNlX19jJ10gPSBhZ210TGluZXNbMF1bJ1Byb2R1Y3RfUmVmZXJlbmNlX19jJ107XG4gICAgICAgICAgICBpZihwcm9kdWN0UmVmZXJlbmNlSWQgIT0gbnVsbCkgIHtcbiAgICAgICAgICAgIFx0ZGVidWdnZXI7XG4gICAgICAgICAgICBcdGNvbnNvbGUubG9nKHByb2R1Y3RSZWZlcmVuY2VJZCwgYWdtdExpbmVzWzBdLCBhZ3JlZW1lbnRJZCk7XG4gICAgICAgICAgICBcdFZpc3VhbGZvcmNlLnJlbW90aW5nLk1hbmFnZXIuaW52b2tlQWN0aW9uIChcbiAgICAgICAgICAgIFx0XHRBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmdldEFnbERldGFpbHNGcm9tQ3Jvc3NSZWYsXG4gICAgICAgICAgICBcdFx0cHJvZHVjdFJlZmVyZW5jZUlkLFxuICAgICAgICAgICAgXHRcdFx0dG1wQWdsLCBcbiAgICAgICAgICAgIFx0XHRcdGFncmVlbWVudElkLFxuICAgICAgICAgICAgXHRcdFx0ZnVuY3Rpb24gKHJlc3VsdCwgZXZlbnQpIHtcbiAgICAgICAgICAgIFx0XHRcdFx0S2VuYW5keUVycC5VbkJsb2NrVUkoKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGV2ZW50LnR5cGUgPT0gJ2V4Y2VwdGlvbicpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLkFsZXJ0KFwiQW4gZXJyb3Igb2NjdXJyZWQgd2hpbGUgcHJvY2Vzc2luZyB5b3VyIHJlcXVlc3QuIFBsZWFzZSBjb250YWN0IHN1cHBvcnRcIik7IFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEtlbmFuZHlFcnAuQ2xlYW5OYW1lc3BhY2UocmVzdWx0LnJlY29yZHMsIEFncmVlbWVudFZpZXdDb21wb25lbnQubmFtZXNwYWNlVVUpO1xuICAgICAgICAgICAgXHRcdFx0XHRcbiAgICAgICAgICAgICAgICAgICAgXHRcdFx0XHRcdGlmKHJlc3VsdC5zdWNjZXNzKSB7XG4gICAgICAgICAgICAgICAgICAgIFx0XHRcdFx0XHRcdGlmKHJlc3VsdC5yZWNvcmRzICYmIHJlc3VsdC5yZWNvcmRzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgICAgICAgICAgXHRcdFx0XHRcdFx0XHR2YXIgYWdtdExpbmUgPSByZXN1bHQucmVjb3Jkc1swXS5hZ2w7ICAgXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgcHJvZHVjdFJlZmVyZW5jZSA9IChhZ210TGluZS5Qcm9kdWN0X1JlZmVyZW5jZV9fYykgPyBhZ210TGluZS5Qcm9kdWN0X1JlZmVyZW5jZV9fYyA6IG51bGw7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgcHJvZHVjdFJlZmVyZW5jZVJlZiA9IChhZ210TGluZS5Qcm9kdWN0X1JlZmVyZW5jZV9fcikgPyBhZ210TGluZS5Qcm9kdWN0X1JlZmVyZW5jZV9fciA6IHsgSWQ6IG51bGwsIE5hbWU6IG51bGwgfTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcm9kdWN0ID0gKGFnbXRMaW5lLlByb2R1Y3RfX2MpID8gYWdtdExpbmUuUHJvZHVjdF9fYyA6IG51bGw7XG5cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcm9kdWN0UmVmID0gKGFnbXRMaW5lLlByb2R1Y3RfX3IpID8gYWdtdExpbmUuUHJvZHVjdF9fciA6ICB7IElkOiBudWxsLCBOYW1lOiBudWxsIH07XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgaXRlbVJlZiA9IChwcm9kdWN0UmVmLkl0ZW1fX3IpID8gcHJvZHVjdFJlZi5JdGVtX19yIFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDogeyBJZDogbnVsbCwgTmFtZTogbnVsbCwgRnVsZmlsbG1lbnRfU291cmNlX19jOiBudWxsfTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBpdGVtU3BlYyA9IChwcm9kdWN0UmVmLkl0ZW1fU3BlY2lmaWNhdGlvbl9fYykgPyBwcm9kdWN0UmVmLkl0ZW1fU3BlY2lmaWNhdGlvbl9fYyA6IG51bGw7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgaXRlbVNwZWNSZWYgPSAocHJvZHVjdFJlZi5JdGVtX1NwZWNpZmljYXRpb25fX3IpID8gcHJvZHVjdFJlZi5JdGVtX1NwZWNpZmljYXRpb25fX3IgOiB7aWQ6IG51bGwsIG5hbWU6IG51bGx9O1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyIHByaWNlQm9vayA9IChhZ210TGluZS5QcmljZWJvb2tfX2MpID8gYWdtdExpbmUuUHJpY2Vib29rX19jIDogbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcmljZUJvb2tSZWYgPSAoYWdtdExpbmUuUHJpY2Vib29rX19yKSA/IGFnbXRMaW5lLlByaWNlYm9va19fciA6ICB7IElkOiBudWxsLCBOYW1lOiBudWxsIH07XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgbGlzdFByaWNlID0gKHR5cGVvZiBhZ210TGluZS5MaXN0X1ByaWNlX19jICE9ICd1bmRlZmluZWQnKSA/IGFnbXRMaW5lLkxpc3RfUHJpY2VfX2MgOiBudWxsO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZihwcmljZUJvb2sgPT0gbnVsbCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ1ByaWNlYm9va19fYycsIHByaWNlQm9vayk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnUHJpY2Vib29rX19yJywgcHJpY2VCb29rUmVmKTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfWVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ0xpc3RfUHJpY2VfX2MnLCBsaXN0UHJpY2UpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ1ByaWNlYm9va19fYycsIHByaWNlQm9vayk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnUHJpY2Vib29rX19yJywgcHJpY2VCb29rUmVmKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhSXRlbS5hZ2wuc2V0KCdBZ3JlZW1lbnRfUHJpY2VfX2MnLCBsaXN0UHJpY2UpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnUHJvZHVjdF9fYycsIHByb2R1Y3QpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnUHJvZHVjdF9fcicsIHByb2R1Y3RSZWYpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnSXRlbV9TcGVjaWZpY2F0aW9uX19jJywgaXRlbVNwZWMpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnSXRlbV9TcGVjaWZpY2F0aW9uX19yJywgaXRlbVNwZWNSZWYpO1xuXG4gICAgICAgICAgICAgICAgICAgIFx0XHRcdFx0XHRcdH1cbiAgICAgICAgICAgICAgICAgICAgXHRcdFx0XHRcdH1cbiAgICAgICAgICAgIFx0XHRcdFx0ICAgIH1cblxuICAgICAgICAgICAgXHRcdFx0fSxcbiAgICAgICAgICAgIFx0XHRcdHtlc2NhcGU6IGZhbHNlfVxuICAgICAgICAgICAgXHQpO1x0XG4gICAgICAgICAgICB9ICBcbiAgICAgICAgfSxcbiAgICAgICAgXG4gICAgICAgIEdldEFHTGluZURldGFpbHNGcm9tUHJvZHVjdDogZnVuY3Rpb24oZSl7XG4gICAgICAgIFx0ZGVidWdnZXI7XG4gICAgICAgICAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgICAgICAgICB2YXIgZ3JpZCA9IHRoaXMuZ3JpZDtcbiAgICAgICAgICAgIHZhciBvcHRpb25zID0gc2VsZi5ncmlkLm9wdGlvbnM7XG4gICAgICAgICAgIC8vIHZhciBtZXNzYWdlRWxlbWVudCA9IGdyaWQuZWxlbWVudC5jbG9zZXN0KFwiZGl2LmdyaWQtY29udGFpbmVyXCIpLmZpbmQoXCJkaXYuZ3JpZC1lcnJvci1tZXNzYWdlXCIpO1xuICAgICAgICAgICAgdmFyIGNlbGwgPSBncmlkLmVsZW1lbnQ7XG4gICAgICAgICAgICB2YXIgcm93ID0gJChlLnRhcmdldCkuY2xvc2VzdChcInRyXCIpO1xuICAgICAgICAgICAgdmFyIGRhdGFJdGVtID0gZ3JpZC5kYXRhSXRlbShyb3cpO1xuXG4gICAgICAgICAgICBjb25zb2xlLmxvZygnRW50ZXJlZCBpbnRvIG15IGZ1bmN0aW9uJywgZSApO1xuXG4gICAgICAgICAgICB2YXIgcHJvZHVjdElkID0gZGF0YUl0ZW0uZ2V0KCdhZ2wuUHJvZHVjdF9fci5JZCcpID8gZGF0YUl0ZW0uZ2V0KCdhZ2wuUHJvZHVjdF9fci5JZCcpIDogbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgY29uc29sZS5sb2coJ3Byb2R1Y3RJZCcsIHByb2R1Y3RJZCk7XG5cbiAgICAgICAgICAgIHZhciBkYXRlRmllbGRzID0gJC5leHRlbmQodHJ1ZSwgW10sIG9wdGlvbnMuZGF0ZUZpZWxkcyk7XG4gICAgICAgIFxuICAgICAgICAgICAgdmFyIGFncmVlbWVudElkID0gc2VsZi5vcHRpb25zLnBhcmVudEdyaWQuSWQ7XG4gICAgICAgICAgICB2YXIgYWdyZWVtZW50ID0gc2VsZi5vcHRpb25zLnBhcmVudEdyaWQ7XG4gICAgICAgICAgICB2YXIgYWdtdExpbmVzID0ge307XG4gICAgICAgICAgICB2YXIgYWdtdExpbmVzTGlzdCA9IFtdO1xuICAgICAgICAgICAgYWdtdExpbmVzTGlzdC5wdXNoKGRhdGFJdGVtLmdldCgnYWdsJykpOyBcbiAgICAgICAgICAgIGFnbXRMaW5lcyA9ICQubWFwKGFnbXRMaW5lc0xpc3QsIGZ1bmN0aW9uKGl0ZW0sIGluZGV4KSB7XG4gICAgICAgICAgICAgICAgaXRlbSA9IGl0ZW0udG9KU09OKCk7XG4gICAgICAgICAgICAgICAgaXRlbSA9IFNlcmlhbGl6ZXIuQ29udmVydFRvU0ZEQ0RhdGUoaXRlbSwgeyBkYXRlRmllbGRzOiBkYXRlRmllbGRzIH0pO1xuICAgICAgICAgICAgICAgIHJldHVybiBpdGVtO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICBpZiAoYWdtdExpbmVzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgIFx0YWdtdExpbmVzID0gU2VyaWFsaXplci5QYXJhbWV0ZXJNYXAoYWdtdExpbmVzKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHZhciB0bXBBZ2wgPSB7fTtcbiAgICAgICAgICAgIHRtcEFnbFsnQWdyZWVtZW50X19jJ10gPSBhZ210TGluZXNbMF1bJ0FncmVlbWVudF9fYyddO1xuICAgICAgICAgICAgdG1wQWdsWydQcmljZV9UeXBlX19jJ10gPSBhZ210TGluZXNbMF1bJ1ByaWNlX1R5cGVfX2MnXTtcbiAgICAgICAgICAgIHRtcEFnbFsnUHJvZHVjdF9UeXBlX19jJ10gPSBhZ210TGluZXNbMF1bJ1Byb2R1Y3RfVHlwZV9fYyddO1xuICAgICAgICAgICAgdG1wQWdsWydQcm9kdWN0X19jJ10gPSBhZ210TGluZXNbMF1bJ1Byb2R1Y3RfX2MnXTtcbiAgICAgICAgICBcbiAgICAgICAgICAgIGlmKHByb2R1Y3RJZCAhPSBudWxsKSAge1xuICAgICAgICAgICAgXHRWaXN1YWxmb3JjZS5yZW1vdGluZy5NYW5hZ2VyLmludm9rZUFjdGlvbiAoXG4gICAgICAgICAgICBcdFx0QWdyZWVtZW50Vmlld0NvbXBvbmVudC5nZXRBZ2xEZXRhaWxzRnJvbVByb2R1Y3QsXG4gICAgICAgICAgICBcdFx0cHJvZHVjdElkLFxuICAgICAgICAgICAgXHRcdFx0dG1wQWdsLCBcbiAgICAgICAgICAgIFx0XHRcdGFncmVlbWVudElkLFxuICAgICAgICAgICAgICAgICAgICAgICAgZnVuY3Rpb24gKHJlc3VsdCwgZXZlbnQpIHtcbiAgICAgICAgICAgIFx0XHRcdFx0S2VuYW5keUVycC5VbkJsb2NrVUkoKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGV2ZW50LnR5cGUgPT0gJ2V4Y2VwdGlvbicpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLkFsZXJ0KFwiQW4gZXJyb3Igb2NjdXJyZWQgd2hpbGUgcHJvY2Vzc2luZyB5b3VyIHJlcXVlc3QuIFBsZWFzZSBjb250YWN0IHN1cHBvcnRcIik7IFxuICAgICAgICAgICAgXHRcdFx0XHQgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLkNsZWFuTmFtZXNwYWNlKHJlc3VsdC5yZWNvcmRzLCBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50Lm5hbWVzcGFjZVVVKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgICAgIFx0XHRcdFx0XHRpZihyZXN1bHQuc3VjY2Vzcykge1xuICAgICAgICAgICAgICAgICAgICBcdFx0XHRcdFx0XHRpZihyZXN1bHQucmVjb3JkcyAmJiByZXN1bHQucmVjb3Jkcy5sZW5ndGggPiAwKSB7XG4gICAgICAgICAgICAgICAgICAgIFx0XHRcdFx0XHRcdFx0dmFyIGFnbXRMaW5lID0gcmVzdWx0LnJlY29yZHNbMF0uYWdsOyAgIFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyIHByb2R1Y3QgPSAoYWdtdExpbmUuUHJvZHVjdF9fYykgPyBhZ210TGluZS5Qcm9kdWN0X19jIDogbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcm9kdWN0UmVmID0gKGFnbXRMaW5lLlByb2R1Y3RfX3IpID8gYWdtdExpbmUuUHJvZHVjdF9fciA6IHsgSWQ6IG51bGwsIE5hbWU6IG51bGwgfTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcm9kdWN0UmVmZXJlbmNlID0gKGFnbXRMaW5lLlByb2R1Y3RfUmVmZXJlbmNlX19jKSA/IGFnbXRMaW5lLlByb2R1Y3RfUmVmZXJlbmNlX19jIDogbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcm9kdWN0UmVmZXJlbmNlUmVmID0gKGFnbXRMaW5lLlByb2R1Y3RfUmVmZXJlbmNlX19yKSA/IGFnbXRMaW5lLlByb2R1Y3RfUmVmZXJlbmNlX19yIDogIHsgSWQ6IG51bGwsIE5hbWU6IG51bGwgfTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBpdGVtU3BlYyA9IChwcm9kdWN0UmVmLkl0ZW1fU3BlY2lmaWNhdGlvbl9fYykgPyBwcm9kdWN0UmVmLkl0ZW1fU3BlY2lmaWNhdGlvbl9fYyA6IG51bGw7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgaXRlbVNwZWNSZWYgPSAocHJvZHVjdFJlZi5JdGVtX1NwZWNpZmljYXRpb25fX3IpID8gcHJvZHVjdFJlZi5JdGVtX1NwZWNpZmljYXRpb25fX3IgOiB7aWQ6IG51bGwsIG5hbWU6IG51bGx9O1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyIHByaWNlQm9vayA9IChhZ210TGluZS5QcmljZWJvb2tfX2MpID8gYWdtdExpbmUuUHJpY2Vib29rX19jIDogbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhciBwcmljZUJvb2tSZWYgPSAoYWdtdExpbmUuUHJpY2Vib29rX19yKSA/IGFnbXRMaW5lLlByaWNlYm9va19fciA6ICB7IElkOiBudWxsLCBOYW1lOiBudWxsIH07XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YXIgbGlzdFByaWNlID0gKHR5cGVvZiBhZ210TGluZS5MaXN0X1ByaWNlX19jICE9ICd1bmRlZmluZWQnKSA/IGFnbXRMaW5lLkxpc3RfUHJpY2VfX2MgOiBudWxsO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZihwcmljZUJvb2sgPT0gbnVsbCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ1ByaWNlYm9va19fYycsIHByaWNlQm9vayk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnUHJpY2Vib29rX19yJywgcHJpY2VCb29rUmVmKTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfWVsc2Uge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ0xpc3RfUHJpY2VfX2MnLCBsaXN0UHJpY2UpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ1ByaWNlYm9va19fYycsIHByaWNlQm9vayk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YUl0ZW0uYWdsLnNldCgnUHJpY2Vib29rX19yJywgcHJpY2VCb29rUmVmKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhSXRlbS5hZ2wuc2V0KCdBZ3JlZW1lbnRfUHJpY2VfX2MnLCBsaXN0UHJpY2UpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGFJdGVtLmFnbC5zZXQoJ0l0ZW1fU3BlY2lmaWNhdGlvbl9fYycsIGl0ZW1TcGVjKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhSXRlbS5hZ2wuc2V0KCdJdGVtX1NwZWNpZmljYXRpb25fX3InLCBpdGVtU3BlY1JlZik7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcdCBkYXRhSXRlbS5hZ2wuc2V0KCdQcm9kdWN0X1JlZmVyZW5jZV9fYycsIHByb2R1Y3RSZWZlcmVuY2UpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXHQgZGF0YUl0ZW0uYWdsLnNldCgnUHJvZHVjdF9SZWZlcmVuY2VfX3InLCBwcm9kdWN0UmVmZXJlbmNlUmVmKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgICAgICAgICBcdFx0XHRcdFx0XHR9XG4gICAgICAgICAgICAgICAgICAgIFx0XHRcdFx0XHR9XG4gICAgICAgICAgICBcdFx0XHRcdCAgICAgICAgfVxuXG4gICAgICAgICAgICBcdFx0XHR9LFxuICAgICAgICAgICAgXHRcdFx0e2VzY2FwZTogZmFsc2V9XG4gICAgICAgICAgICBcdCk7XHRcbiAgICAgICAgICAgIH0gIFxuICAgICAgICB9ICAgICAgICAgICAgICAgICBcblxuXHR9O1xufSApKCk7XG4iLCIvKiBnbG9iYWwgVmlzdWFsZm9yY2UgKi9cbi8qIGdsb2JhbCBfICovXG4vKiBnbG9iYWwgS2VuYW5keUVycCAqL1xuLyogZ2xvYmFsIEtlbmRvR3JpZFV0aWxzICovXG52YXIgR3JpZEFjdGlvbkxpc3RBY3Rpb25zID0gKCBmdW5jdGlvbigpIHtcblx0cmV0dXJuIHtcblxuXHRcdFNhdmU6IGZ1bmN0aW9uKCBlICkge1xuXHRcdFx0dmFyIHNlbGYgPSB0aGlzO1xuXHRcdFx0dmFyIGdyaWQgPSBzZWxmLmdyaWQ7XG5cdFx0XHR2YXIgbWVzc2FnZUVsZW1lbnQgPSBncmlkLmVsZW1lbnRcblx0XHRcdFx0LmNsb3Nlc3QoIFwiZGl2LmdyaWQtY29udGFpbmVyXCIgKVxuXHRcdFx0XHQuZmluZCggXCJkaXYuZ3JpZC1tZXNzYWdlXCIgKTtcblx0XHRcdHZhciBncmlkVXRpbHMgPSBuZXcgS2VuZG9HcmlkVXRpbHMoIGdyaWQsIHNlbGYub3B0aW9ucyApO1xuXHRcdFx0aWYgKCAhZ3JpZFV0aWxzLklzVmFsaWQoKSApIHtcbiAgICAgICAgICAgICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgfVxuXG5cdFx0XHRpZiAoICFncmlkVXRpbHMuSGFzQ2hhbmdlcygpICkge1xuXHRcdFx0XHRLZW5hbmR5RXJwLk1lc3NhZ2UoIFwiTm8gcmVjb3JkcyBjaGFuZ2VkLlwiLCBcblx0XHRcdFx0XHRLZW5hbmR5RXJwLk1lc3NhZ2VUeXBlLkluZm8sIFxuXHRcdFx0XHRcdG1lc3NhZ2VFbGVtZW50ICk7XG5cdFx0XHRcdHJldHVybjtcblx0XHRcdH1cblxuXHRcdFx0dmFyIHVwZGF0ZWRSb3dzID0gZ3JpZFV0aWxzLlVwZGF0ZWRSb3dzKCk7XG5cdFx0XHR2YXIgbmV3Um93cyA9IGdyaWRVdGlscy5OZXdSb3dzKCk7XG5cdFx0XHR2YXIgZGVsZXRlZFJvd3MgPSBncmlkVXRpbHMuRGVsZXRlZFJvd3MoKTtcblx0XHRcdHZhciBjaGFuZ2VMaXN0SWRzID0gXy51bmlvbiggXy5wbHVjayggdXBkYXRlZFJvd3MsIFwiSWRcIiApLCBcblx0XHRcdFx0Xy5wbHVjayggZGVsZXRlZFJvd3MsIFwiSWRcIiApICk7XG5cblx0XHRcdEtlbmFuZHlFcnAuQmxvY2tVSSggZ3JpZC5lbGVtZW50ICk7XHRcdFxuXHRcdFx0VmlzdWFsZm9yY2UucmVtb3RpbmcuTWFuYWdlci5pbnZva2VBY3Rpb24oXG5cdFx0XHRcdHNlbGYub3B0aW9ucy5zYXZlQWN0aW9uLFxuXHRcdFx0XHRzZWxmLm9wdGlvbnMuY29uZmlnLCAgICAgICAgXG5cdFx0XHRcdHVwZGF0ZWRSb3dzLFxuXHRcdFx0XHRuZXdSb3dzLFxuXHRcdFx0XHRkZWxldGVkUm93cyxcblx0XHRcdFx0ZnVuY3Rpb24oIHJlc3VsdCwgZXZlbnQgKSB7XG5cdFx0XHRcdFx0S2VuYW5keUVycC5VbkJsb2NrVUkoIGdyaWQuZWxlbWVudCApO1x0ICAgIFx0XG5cdFx0XHRcdFx0aWYgKCBldmVudC50eXBlID09IFwiZXhjZXB0aW9uXCIgKSB7XG5cdFx0XHRcdFx0XHRLZW5hbmR5RXJwLk1lc3NhZ2UoIGV2ZW50Lm1lc3NhZ2UsIFxuXHRcdFx0XHRcdFx0XHRLZW5hbmR5RXJwLk1lc3NhZ2VUeXBlLkVycm9yLCBcblx0XHRcdFx0XHRcdFx0bWVzc2FnZUVsZW1lbnQgKTtcblx0XHRcdFx0XHR9IGVsc2Uge1xuXHRcdFx0XHRcdFx0aWYgKCByZXN1bHQuc3VjY2VzcyApIHtcblx0XHRcdFx0XHRcdFx0dmFyIG5ld0lkcyA9IF8uZGlmZmVyZW5jZSggXG5cdFx0XHRcdFx0XHRcdFx0Xy5wbHVjayggcmVzdWx0LnJlY29yZHMsIFwiSWRcIiApLCBcblx0XHRcdFx0XHRcdFx0XHRjaGFuZ2VMaXN0SWRzICk7XG5cblx0XHRcdFx0XHRcdFx0Ly9yZWZyZXNoIHRoZSBncmlkXG5cdFx0XHRcdFx0XHRcdGdyaWQuZGF0YVNvdXJjZS5fZGVzdHJveWVkID0gW107XG5cdFx0XHRcdFx0XHRcdGdyaWQuZGF0YVNvdXJjZS5yZWFkKCB7IG5ld0lkczogbmV3SWRzIH0gKTtcdFx0XG5cblx0XHRcdFx0XHRcdFx0Ly8gdHJpZ2dlciBvbnNhdmVzdWNjZXNzXG5cdFx0XHRcdFx0XHRcdGdyaWQuZWxlbWVudC50cmlnZ2VyKCBcIk9uU2F2ZVN1Y2Nlc3NcIiApO1x0XHRcblx0XHRcdFx0XHRcdFx0S2VuYW5keUVycC5NZXNzYWdlcyggcmVzdWx0Lm1lc3NhZ2VzLCBtZXNzYWdlRWxlbWVudCApO1xuXHRcdFx0XHRcdFx0fSBlbHNlIHtcblx0XHRcdFx0XHRcdFx0S2VuYW5keUVycC5NZXNzYWdlcyggcmVzdWx0Lm1lc3NhZ2VzLCBtZXNzYWdlRWxlbWVudCApO1xuXHRcdFx0XHRcdFx0fVxuXHRcdFx0XHRcdH1cblx0XHRcdFx0fSxcblx0XHRcdFx0eyBlc2NhcGU6IGZhbHNlIH1cblx0XHRcdCk7XG5cdFx0fVxuXHR9O1xufSApKCk7XG5cbm1vZHVsZS5HcmlkQWN0aW9uTGlzdCA9ICggZnVuY3Rpb24oICQgKSB7XG4gICAgdmFyIGtlbmRvID0gd2luZG93LmtlbmRvLFxuICAgICAgICB1aSA9IGtlbmRvLnVpLFxuICAgICAgICBXaWRnZXQgPSB1aS5XaWRnZXQsXG4gICAgICAgIENIQU5HRSA9IFwiY2hhbmdlXCI7XG4gICAgICAgIE9OUkVBREZBSUxVUkUgPSBcIk9uUmVhZEZhaWx1cmVcIjtcbiAgICAgICAgT05SRUFEU1VDQ0VTUyA9IFwiT25SZWFkU3VjY2Vzc1wiO1xuXG5cdHZhciBHcmlkQWN0aW9uTGlzdCA9IHVpLkdyaWQuZXh0ZW5kKCB7XG5cdFx0X2NvbmZpZzogbnVsbCxcblx0XHRfZmllbGRMaXN0OiBudWxsLFxuXHRcdF9zdGFuZGFyZEJ1dHRvbnM6IG51bGwsXG5cdFx0X25hbWVzcGFjZTogbnVsbCxcblx0XHRfcmVmZXJlbmNlRmllbGRzOiBudWxsLFxuXHRcdF9kYXRlRmllbGRzOiBudWxsLFxuXHRcdF9uZXN0ZWRGaWVsZHM6IG51bGwsXG5cdFx0X2xvb2t1cFNlYXJjaEZpbHRlcnM6IG51bGwsXG5cdFx0X21vZGVsSWRGaWVsZDogbnVsbCxcblx0XHRfZ2V0QWN0aW9uTGlzdEZ1bmN0aW9uOiBudWxsLFxuXHRcdF9hbGxvd01hc3NEZWxldGU6IG51bGwsXG5cdFx0X3Nob3dJY29uQnV0dG9uczogbnVsbCxcblxuICAgICAgICAvLyBtZXRob2QgY2FsbGVkIHdoZW4gYSBuZXcgd2lkZ2V0IGlzIGNyZWF0ZWRcbiAgICAgICAgaW5pdDogZnVuY3Rpb24oIGVsZW1lbnQsIG9wdGlvbnMgKSB7XG4gICAgICAgICAgICB2YXIgdGhhdCA9IHRoaXM7XG5cblx0XHRcdHRoYXQuX2luaXREZWZhdWx0cyggb3B0aW9ucyApO1xuXG4gICAgICAgICAgICB2YXIgZ2V0TW9kZWwgPSBmdW5jdGlvbigpIHtcblx0ICAgICAgICAgICAgdmFyIGZpZWxkcyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXRGaWVsZHMoIF9maWVsZExpc3QgKTtcblx0XHRcdFx0XG5cdCAgICAgICAgICAgIC8vIEFkZCBzY2hlbWEgZm9yIGNoZWNrYm94IGNvbHVtblxuXHRcdFx0XHRmaWVsZHMuaXNTZWxlY3RlZF9fY3VzdG9tID0geyB0eXBlOiBcImJvb2xlYW5cIiB9O1xuXG5cdFx0XHRcdHZhciBtb2RlbCA9IGtlbmRvLmRhdGEuTW9kZWwuZGVmaW5lKCB7IGlkOiBfbW9kZWxJZEZpZWxkLCBmaWVsZHM6IGZpZWxkcyB9ICk7XG5cblx0XHRcdFx0cmV0dXJuIG1vZGVsO1xuXHRcdFx0fTtcblx0XHRcdFx0XHRcblx0XHRcdHZhciBnZXRDb2x1bW5zID0gZnVuY3Rpb24oKSB7XG5cdCAgICAgICAgICAgIHZhciBjb2x1bW5zID0gS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkdldENvbHVtbnMoXG5cdFx0XHRcdFx0X2ZpZWxkTGlzdCxcblx0XHRcdFx0XHR7IGxvb2t1cFNlYXJjaEFjdGlvbjogb3B0aW9ucy5sb29rdXBTZWFyY2hBY3Rpb24sXG5cdFx0XHRcdFx0XHRidXR0b25zOiBfc3RhbmRhcmRCdXR0b25zLFxuXHRcdFx0XHRcdFx0bG9va3VwU2VhcmNoRmlsdGVyczogX2xvb2t1cFNlYXJjaEZpbHRlcnMsXG5cdFx0XHRcdFx0XHRhbGxvd01hc3NEZWxldGU6IF9hbGxvd01hc3NEZWxldGUsXG5cdFx0XHRcdFx0XHR2YWxpZGF0ZUxvb2t1cE9uQmx1cjogb3B0aW9ucy52YWxpZGF0ZUxvb2t1cE9uQmx1clxuXHRcdFx0XHR9ICk7XG5cdCAgICAgICAgICAgIFxuXHQgICAgICAgICAgICAkLmVhY2goXy53aGVyZShjb2x1bW5zLCB7ZmllbGQ6IFwiTmFtZVwifSksIGZ1bmN0aW9uKGluZGV4LCBpdGVtKSB7XG5cdFx0XHRcdFx0aXRlbS50ZW1wbGF0ZSA9IGtlbmRvLnRlbXBsYXRlKCc8YSB0YXJnZXQ9XCJfdG9wXCIgaHJlZj1cIi8jPUlkI1wiIC8+Iz0gTmFtZSAjPC9hPicpO1xuXHRcdFx0XHR9KTtcblx0XHRcdFx0XG5cdFx0XHRcdCQuZWFjaChjb2x1bW5zLCBmdW5jdGlvbihpbmRleCwgaXRlbSkge1xuXHRcdFx0XHRcdGlmICggaXRlbS5mb3JtYXQgPT0gXCJ7MDpNL2QveXl5eSBoOm1tIHR0fVwiKSB7XG5cdFx0XHRcdFx0XHRpdGVtLmZvcm1hdCA9IFwiezA6TS9kL3l5eXl9XCJcblx0XHRcdFx0XHR9XG5cdFx0XHRcdH0pO1xuXHRcdFx0XHRcblx0XHRcdFx0Y29sdW1ucy51bnNoaWZ0KFxuXHRcdFx0XHRcdHsgZmllbGQ6IFwiXCIsXG5cdFx0XHRcdFx0XHRmaWx0ZXJhYmxlOiBmYWxzZSxcblx0XHRcdFx0XHRcdHNvcnRhYmxlOiBmYWxzZSxcblx0XHRcdFx0XHRcdHdpZHRoOiAzMCxcblx0XHRcdFx0XHRcdGF0dHJpYnV0ZXM6IHsgY2xhc3M6IFwia25keS10ZXh0LWxlZnRcIiB9LFxuXHRcdFx0XHRcdFx0aGVhZGVyQXR0cmlidXRlczogeyBjbGFzczogXCJrbmR5LXRleHQtbGVmdFwiIH1cblx0XHRcdFx0fSApO1xuXG5cdFx0XHRcdHJldHVybiBjb2x1bW5zO1xuXHRcdFx0fTtcblxuXHRcdFx0dmFyIGdldFRvb2xiYXJCdXR0b25zID0gZnVuY3Rpb24oKSB7XG5cdFx0XHRcdHZhciBidXR0b25zID0gS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkdldFRvb2xiYXJCdXR0b25zKCBcblx0XHRcdFx0XHRfc3RhbmRhcmRCdXR0b25zLFxuXHRcdFx0XHRcdHsgc2hvd0ljb25CdXR0b25zOiBfc2hvd0ljb25CdXR0b25zLFxuXHRcdFx0XHRcdFx0YWxsb3dNYXNzRGVsZXRlOiBfYWxsb3dNYXNzRGVsZXRlXG5cdFx0XHRcdH0gKTtcblx0XHRcdFx0XG5cdFx0XHRcdGJ1dHRvbnMgPSBfLnVuaW9uKCBidXR0b25zLCBvcHRpb25zLnRvb2xiYXJCdXR0b25zICk7XG5cdFx0XHRcdHJldHVybiBidXR0b25zO1xuXHRcdFx0fTtcblxuXHRcdFx0dmFyIGdldERhdGFTb3VyY2UgPSBmdW5jdGlvbigpIHtcblx0XHRcdFx0dmFyIGRhdGFTb3VyY2UgPSBuZXcga2VuZG8uZGF0YS5EYXRhU291cmNlKCB7XG5cdFx0XHRcdFx0dHJhbnNwb3J0OiB7XG5cdFx0XHRcdFx0XHRyZWFkOiBmdW5jdGlvbiggb3B0aW9ucyApIHtcblx0XHRcdFx0XHRcdFx0S2VuYW5keUVycC5CbG9ja1VJKCBlbGVtZW50ICk7XG5cblx0XHRcdFx0XHRcdFx0dmFyIHByb21pc2UgPSBfZ2V0QWN0aW9uTGlzdEZ1bmN0aW9uKCBvcHRpb25zLmRhdGEucmVhZE9wdGlvbnMgKTtcblx0XHRcdFx0XHRcdFx0cHJvbWlzZS5kb25lKCBmdW5jdGlvbiggcmVzdWx0LCBldmVudCApIHtcblx0XHRcdFx0XHRcdFx0XHRLZW5hbmR5RXJwLlVuQmxvY2tVSSggZWxlbWVudCApO1xuXG5cdFx0XHRcdFx0XHQgICAgICAgIFx0aWYgKCBldmVudC50eXBlID09IFwiZXhjZXB0aW9uXCIgKSB7XG5cdFx0XHRcdFx0XHRcdFx0XHRcdEtlbmFuZHlFcnAuQWxlcnQoIFwiQW4gZXJyb3Igb2NjdXJyZWQgd2hpbGUgcHJvY2Vzc2luZyB5b3VyIHJlcXVlc3QuXCIgK1xuXHRcdFx0XHRcdFx0XHRcdFx0XHRcdCBcIlBsZWFzZSBjb250YWN0IHN1cHBvcnRcIiApO1xuXG5cdFx0XHRcdFx0XHRcdFx0XHRcdC8vIHRyaWdnZXIgb25yZWFkZmFpbHVyZVxuXHRcdFx0XHRcdFx0XHRcdFx0ICAgICQoIGVsZW1lbnQgKS50cmlnZ2VyKCB7XG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgICAgIHR5cGU6IE9OUkVBREZBSUxVUkUsXG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgICAgIHJlc3VsdDogcmVzdWx0LCBcblx0XHRcdFx0XHRcdFx0XHRcdCAgICAgICAgZXZlbnQ6IGV2ZW50IFxuXHRcdFx0XHRcdFx0XHRcdFx0ICAgIH0gKTtcblx0XHRcdFx0XHRcdFx0XHRcdH0gZWxzZSB7XG5cdFx0XHRcdFx0XHRcdFx0XHRcdEtlbmFuZHlFcnAuQ2xlYW5OYW1lc3BhY2UoIHJlc3VsdC5yZWNvcmRzLCBfbmFtZXNwYWNlICk7XG5cdFx0XHRcdFx0XHQgICAgICAgICAgICBcdG9wdGlvbnMuc3VjY2VzcyggcmVzdWx0LnJlY29yZHMgKTtcblx0XHRcdFx0XHRcdCAgICAgICAgICAgIFx0XG5cdFx0XHRcdFx0XHQgICAgICAgICAgICBcdC8vIHRyaWdnZXIgb25yZWFkc3VjY2Vzc1xuXHRcdFx0XHRcdFx0XHRcdFx0ICAgICQoIGVsZW1lbnQgKS50cmlnZ2VyKCB7XG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgICAgIHR5cGU6IE9OUkVBRFNVQ0NFU1MsXG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgICAgIHJlc3VsdDogcmVzdWx0LCBcblx0XHRcdFx0XHRcdFx0XHRcdCAgICAgICAgZXZlbnQ6IGV2ZW50IFxuXHRcdFx0XHRcdFx0XHRcdFx0ICAgIH0gKTtcblx0XHRcdFx0XHRcdFx0XHRcdH1cblx0XHRcdFx0XHQgICAgICAgICAgICB9ICk7XG5cdFx0XHRcdFx0XHR9XG5cdFx0XHRcdFx0fSxcblx0XHRcdFx0XHRiYXRjaDogdHJ1ZSxcblx0XHRcdFx0XHRwYWdlU2l6ZTogKCBfY29uZmlnLnBhZ2VTaXplICkgPyBfY29uZmlnLnBhZ2VTaXplIDogS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkRlZmF1bHRQYWdlU2l6ZSxcblx0XHRcdFx0XHRzY2hlbWE6IHtcblx0XHRcdFx0XHRcdG1vZGVsOiBnZXRNb2RlbCgpLFxuXHRcdFx0XHRcdFx0cGFyc2U6ZnVuY3Rpb24oIHJlc3BvbnNlICkge1xuXHRcdFx0ICAgICAgICAgICAgICAgICQuZWFjaCggcmVzcG9uc2UsIGZ1bmN0aW9uKCBpZHgsIGl0ZW0gKSB7XG5cdFx0XHQgICAgICAgICAgICAgICAgXHRpdGVtID0gU2VyaWFsaXplci5JbmNsdWRlTnVsbHMoIGl0ZW0sIHsgZmllbGRzOiBfbmVzdGVkRmllbGRzIH0gKTtcblx0ICAgICAgICAgICAgICAgICAgICBcdFx0aXRlbSA9IFNlcmlhbGl6ZXIuQ29udmVydEZyb21TRkRDRGF0ZSggaXRlbSwgeyBkYXRlRmllbGRzOiBfZGF0ZUZpZWxkcyB9ICk7XG5cdFx0XHRcdFx0XHQgICAgfSApO1xuXHRcdFx0XHRcdFx0ICAgIFxuXHRcdFx0ICAgICAgICAgICAgICAgIHJldHVybiByZXNwb25zZTtcblx0XHRcdFx0XHRcdH0gICAgICAgICBcdFxuXHRcdFx0XHRcdH0sXG5cdFx0XHRcdFx0YWdncmVnYXRlOiBvcHRpb25zLmFnZ3JlZ2F0ZXMgPyBvcHRpb25zLmFnZ3JlZ2F0ZXMgOiBudWxsICAgIFx0XG5cdFx0XHRcdH0gKTtcblx0XG5cdFx0XHRcdHJldHVybiBkYXRhU291cmNlO1xuXHRcdFx0fTtcblx0XHRcdFx0XG4gICAgICAgICAgICB2YXIgZGVmYXVsdE9wdGlvbnMgPSB7XG5cdCAgICAgICAgXHRkYXRhU291cmNlOiBnZXREYXRhU291cmNlKCksIFxuXHQgICAgICAgIFx0bmF2aWdhdGFibGU6IHRydWUsXG5cdCAgICAgICAgXHRwYWdlYWJsZTogeyBcblx0ICAgICAgICBcdFx0aW5wdXQ6IHRydWUsXG5cdCAgICAgICAgICAgICAgICBudW1lcmljOiBmYWxzZSxcblx0ICAgICAgICBcdFx0cGFnZVNpemVzOiBLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuUGFnZVNpemVzLFxuXHQgICAgICAgIFx0XHRtZXNzYWdlczoge1xuXHQgICAgICAgIFx0XHRcdGRpc3BsYXk6ICd7MH0gLSB7MX0gb2YgezJ9IHJlY29yZHMnLFxuXHQgICAgICAgIFx0XHRcdGVtcHR5OiAnJyxcblx0ICAgICAgICBcdFx0XHRpdGVtc1BlclBhZ2U6ICdyZWNvcmRzIHBlciBwYWdlJ1xuXHQgICAgICAgIFx0XHR9XG5cdFx0XHRcdH0sXHRcdFxuXHRcdCAgICAgICAgdG9vbGJhcjogZ2V0VG9vbGJhckJ1dHRvbnMoKSxcblx0XHQgICAgICAgIGNvbHVtbnM6IGdldENvbHVtbnMoKSxcblx0XHQgICAgICAgIHNvcnRhYmxlOiB0cnVlLFxuXHRcdFx0XHRmaWx0ZXJhYmxlOiB0cnVlLFxuXHRcdFx0XHRyZXNpemFibGU6IHRydWUsXG5cdFx0XHRcdGVkaXRhYmxlOiB0cnVlLFxuICAgICAgICAgICAgICAgIHNjcm9sbGFibGU6IF9jb25maWcuc2Nyb2xsYWJsZSA/IF9jb25maWcuc2Nyb2xsYWJsZSA6IHRydWVcblx0ICAgICAgICB9O1xuXHQgICAgICAgIFxuXHQgICAgICAgIG9wdGlvbnMgPSAkLmV4dGVuZCgge30sIGRlZmF1bHRPcHRpb25zLCBvcHRpb25zICk7XG5cdCAgICAgICAgXG4gICAgICAgICAgICBpZiAoICQoIGVsZW1lbnQgKS5kYXRhKCAna2VuZG9HcmlkJyApICE9PSBudWxsICYmICQoIGVsZW1lbnQgKS5kYXRhKCAna2VuZG9HcmlkJyApICE9PSB1bmRlZmluZWQgKSB7IFxuICAgICAgICAgICAgICAgICQoIGVsZW1lbnQgKS5kYXRhKCAna2VuZG9HcmlkJyApLmRlc3Ryb3koKTsgXG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIHVpLkdyaWQuZm4uaW5pdC5jYWxsKCB0aGF0LCBlbGVtZW50LCBvcHRpb25zICk7XG5cdFx0XHRcblx0XHRcdCQoIGVsZW1lbnQgKS5kYXRhKCBcImtlbmRvR3JpZFwiLCB0aGF0ICk7XG5cdFx0XHRcblx0XHRcdHRoYXQuX2luaXRFdmVudHMoKTtcbiAgICAgICAgfSxcbiAgICAgICAgXG4gICAgICAgIC8vIHdpZGdldCBvcHRpb25zXG4gICAgICAgIG9wdGlvbnM6IHtcbiAgICAgICAgICAgIG5hbWU6IFwiR3JpZEFjdGlvbkxpc3RcIixcbiAgICAgICAgICAgIGNvbmZpZzogbnVsbCxcbiAgICAgICAgICAgIGZpZWxkTGlzdDogbnVsbCxcbiAgICAgICAgICAgIG5hbWVzcGFjZTogbnVsbCxcbiAgICAgICAgICAgIGxvb2t1cFNlYXJjaEFjdGlvbjogbnVsbCxcbiAgICAgICAgICAgIGdldEFjdGlvbkxpc3RGdW5jdGlvbjogbnVsbCxcbiAgICAgICAgICAgIHNhdmVBY3Rpb25MaXN0QWN0aW9uOiBudWxsLFxuICAgICAgICAgICAgYWRkUm93QWN0aW9uOiBudWxsLFxuICAgICAgICAgICAgbG9va3VwU2VhcmNoRmlsdGVyczogW10sXG4gICAgICAgICAgICBtb2RlbElkRmllbGQ6ICdJZCcsXG4gICAgICAgICAgICBhbGxvd01hc3NEZWxldGU6IHRydWUsXG4gICAgICAgICAgICBzaG93SWNvbkJ1dHRvbnM6IGZhbHNlLFxuICAgICAgICAgICAgdG9vbGJhckJ1dHRvbnM6IFtdLFxuICAgICAgICAgICAgdmFsaWRhdGVMb29rdXBPbkJsdXI6IGZhbHNlXG4gICAgICAgIH0sXG4gICAgICAgIFxuICAgICAgICAvLyBldmVudHMgdGhlIGNvbnRyb2wgY2FuIGZpcmVcblx0XHRldmVudHM6IFsgQ0hBTkdFIF0sXG5cdFx0XG5cdFx0X2luaXREZWZhdWx0czogZnVuY3Rpb24oIG9wdGlvbnMgKSB7XG5cdFx0XHR2YXIgdGhhdCA9IHRoaXM7XG5cdFx0XHRcblx0XHRcdF9jb25maWcgPSBKU09OVXRpbHMuUGFyc2UoIG9wdGlvbnMuY29uZmlnICk7XG5cdFx0XHRfZmllbGRMaXN0ID0gSlNPTlV0aWxzLlBhcnNlKCBvcHRpb25zLmZpZWxkTGlzdCApO1xuXHRcdFx0X3N0YW5kYXJkQnV0dG9ucyA9ICQubWFwKCBfY29uZmlnLmJ1dHRvbnMuc3BsaXQoICcsJyApLCAkLnRyaW0gKTtcblx0XHRcdF9uYW1lc3BhY2UgPSBfY29uZmlnLm5hbWVzcGFjZSA/IF9jb25maWcubmFtZXNwYWNlIDogb3B0aW9ucy5uYW1lc3BhY2U7XG5cdFx0XHRfcmVmZXJlbmNlRmllbGRzID0gS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkdldFJlZmVyZW5jZUZpZWxkcyggX2ZpZWxkTGlzdCApOyAvLyBnZXQgdGhlIGxpc3Qgb2YgcmVmZXJlbmNlIGZpZWxkc1xuXHRcdFx0X2RhdGVGaWVsZHMgPSBLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuR2V0RGF0ZUZpZWxkcyggX2ZpZWxkTGlzdCApOyAvLyBnZXQgdGhlIGxpc3Qgb2YgZGF0ZSBmaWVsZHNcblx0XHRcdF9sb29rdXBTZWFyY2hGaWx0ZXJzID0gKCBvcHRpb25zLmxvb2t1cFNlYXJjaEZpbHRlcnMgKSA/IG9wdGlvbnMubG9va3VwU2VhcmNoRmlsdGVycyA6IFtdO1xuXHRcdFx0X25lc3RlZEZpZWxkcyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXROZXN0ZWRGaWVsZHMoIF9maWVsZExpc3QgKTsgLy8gZ2V0IHRoZSBsaXN0IG9mIG5lc3RlZCBmaWVsZHNcblx0XHRcdF9tb2RlbElkRmllbGQgPSBvcHRpb25zLm1vZGVsSWRGaWVsZCA/IG9wdGlvbnMubW9kZWxJZEZpZWxkIDogJ0lkJztcblx0XHRcdF9nZXRBY3Rpb25MaXN0RnVuY3Rpb24gPSBvcHRpb25zLmdldEFjdGlvbkxpc3RGdW5jdGlvbjtcblx0XHRcdF9zaG93SWNvbkJ1dHRvbnMgPSAoIG9wdGlvbnMuc2hvd0ljb25CdXR0b25zICkgPyBvcHRpb25zLnNob3dJY29uQnV0dG9ucyA6IHRoYXQub3B0aW9ucy5zaG93SWNvbkJ1dHRvbnM7XG5cdFx0XHRfYWxsb3dNYXNzRGVsZXRlID0gKCBvcHRpb25zLmFsbG93TWFzc0RlbGV0ZSApID8gb3B0aW9ucy5hbGxvd01hc3NEZWxldGUgOiB0aGF0Lm9wdGlvbnMuYWxsb3dNYXNzRGVsZXRlO1xuXHRcdH0sXG5cdFx0XG5cdFx0X2luaXRFdmVudHM6IGZ1bmN0aW9uKCkge1xuXHRcdFx0dmFyIHRoYXQgPSB0aGlzO1xuXHRcdFx0dmFyIGdyaWQgPSB0aGF0O1xuXHRcdFx0XG5cdFx0XHQvLyBiaW5kIGdyaWQgZWRpdCBldmVudFxuXHRcdFx0Z3JpZC5iaW5kKCAnZWRpdCcsICQucHJveHkoIEtlbmFuZHlFcnAuS2VuZG9HcmlkQWN0aW9ucy5FZGl0LCB7IHJlZmVyZW5jZUZpZWxkczogX3JlZmVyZW5jZUZpZWxkcyB9ICkgKTtcblx0XHRcdFx0XG5cdFx0XHQvLyBiaW5kIGdyaWQgZGF0YUJvdW5kIGV2ZW50XG5cdFx0XHRncmlkLmJpbmQoICdkYXRhQm91bmQnLCBLZW5hbmR5RXJwLktlbmRvR3JpZEFjdGlvbnMuRGF0YUJvdW5kICk7XG5cdFx0XHRcdFxuXHRcdFx0Ly8gYmluZCBjbGljayBldmVudHMgdG8gdGhlIGN1c3RvbSBidXR0b25zXG5cdFx0XHRLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuQmluZEV2ZW50cyggZ3JpZCwgX3N0YW5kYXJkQnV0dG9ucywgeyBzYXZlQWN0aW9uOiB0aGF0Lm9wdGlvbnMuc2F2ZUFjdGlvbkxpc3RBY3Rpb24sIGFkZFJvd0FjdGlvbjogdGhhdC5vcHRpb25zLmFkZFJvd0FjdGlvbiwgcmVmZXJlbmNlRmllbGRzOiBfcmVmZXJlbmNlRmllbGRzLCBjb25maWc6IF9jb25maWcsIGRhdGVGaWVsZHM6IF9kYXRlRmllbGRzLCBpZ25vcmVCaW5kaW5nczogWyBLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuQ29tbWFuZFR5cGUuU2F2ZSBdIH0gKTtcblxuXHRcdFx0Ly8gc2V0IHRoZSBncmlkIGhlaWdodFxuXHRcdFx0aWYgKCB0aGF0Lm9wdGlvbnMuaGVpZ2h0ICkge1xuXHRcdFx0XHRncmlkLndyYXBwZXIuaGVpZ2h0KCB0aGF0Lm9wdGlvbnMuaGVpZ2h0ICk7XG5cdFx0XHR9XG5cdFx0XHRcblx0XHRcdGdyaWQud3JhcHBlci5vbiggXCJjbGlja1wiLCBcIi5ncmlkLXNhdmUtY29tbWFuZFwiLCAkLnByb3h5KCBHcmlkQWN0aW9uTGlzdEFjdGlvbnMuU2F2ZSwgeyBncmlkOiBncmlkLCBvcHRpb25zOiB7IHNhdmVBY3Rpb246IHRoYXQub3B0aW9ucy5zYXZlQWN0aW9uTGlzdEFjdGlvbiwgY29uZmlnOiBfY29uZmlnIH0gfSApICk7XG5cdFx0XHRncmlkLnRoZWFkLm9uKCBcImNsaWNrXCIsIFwiLmdyaWQtc2VsZWN0LWFsbFwiLCAkLnByb3h5KCBLZW5hbmR5RXJwLktlbmRvR3JpZEFjdGlvbnMuU2VsZWN0QWxsLCB7IGdyaWQ6IGdyaWQgfSApICk7XG5cdFx0XHRncmlkLnRib2R5Lm9uKCBcImNoYW5nZVwiLCBcIi5ncmlkLXNlbGVjdC1vbmVcIiwgJC5wcm94eSggS2VuYW5keUVycC5LZW5kb0dyaWRBY3Rpb25zLlNlbGVjdCwgeyBncmlkOiBncmlkIH0gKSApO1xuXHRcdFx0XG5cdFx0XHRncmlkLmJpbmQoICdkYXRhQm91bmQnLCBmdW5jdGlvbigpIHtcblx0XHRcdFx0dmFyIGlzU2VsZWN0ZWQgPSAoIGdyaWQudGJvZHkuZmluZCggJy5ncmlkLXNlbGVjdC1vbmUnICkubGVuZ3RoID4gMCAmJiAhZ3JpZC50Ym9keS5maW5kKCAnLmdyaWQtc2VsZWN0LW9uZScgKS5pcyggJzpub3QoOmNoZWNrZWQpJyApICkgPyB0cnVlIDogZmFsc2U7XG5cdFx0XHRcdGdyaWQudGhlYWQuZmluZCggJy5ncmlkLXNlbGVjdC1hbGwnICkucHJvcCggJ2NoZWNrZWQnLCBpc1NlbGVjdGVkICk7XG5cdFx0XHR9ICk7XG5cdFx0fVxuXHR9ICk7XG5cblx0dWkucGx1Z2luKCBHcmlkQWN0aW9uTGlzdCApO1xufSApKCBqUXVlcnkgKTtcbiIsInZhciBHcmlkRGV0YWlsTGlzdEFjdGlvbnMgPSBmdW5jdGlvbigpIHtcblx0XG5cdHJldHVybiB7XG5cdFxuXHRcdFNhdmU6IGZ1bmN0aW9uKCBlICkge1xuICAgXHRcdFx0dmFyIHNlbGYgPSB0aGlzO1xuICAgXHRcdFx0dmFyIGdyaWQgPSBzZWxmLmdyaWQ7XG4gICBcdFx0XHR2YXIgbWVzc2FnZUVsZW1lbnQgPSBncmlkLmVsZW1lbnQuY2xvc2VzdCggXCJkaXYuZ3JpZC1jb250YWluZXJcIiApLmZpbmQoIFwiZGl2LmdyaWQtbWVzc2FnZVwiICk7XG4gICBcdFx0XHRcblx0XHRcdHZhciBncmlkVXRpbHMgPSBuZXcgS2VuZG9HcmlkVXRpbHMoIGdyaWQsIHNlbGYub3B0aW9ucyApO1xuXHRcdFx0XHRcdFx0XHRcblx0XHRcdGlmICggIWdyaWRVdGlscy5Jc1ZhbGlkKCkgKSB7XG4gICAgICAgICAgICAgICAgZS5wcmV2ZW50RGVmYXVsdCgpO1xuICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgIH1cblx0XHQgXHRcdFxuICAgICAgICBcdGlmICggIWdyaWRVdGlscy5IYXNDaGFuZ2VzKCkgKSB7XG4gICAgICAgIFx0XHRLZW5hbmR5RXJwLk1lc3NhZ2UoIFwiTm8gcmVjb3JkcyBjaGFuZ2VkLlwiLCBLZW5hbmR5RXJwLk1lc3NhZ2VUeXBlLkluZm8sIG1lc3NhZ2VFbGVtZW50ICk7XG4gICAgICAgIFx0XHRyZXR1cm47XG4gICAgICAgIFx0fVxuICAgICAgICBcdFxuICAgICAgICBcdHZhciB1cGRhdGVkUm93cyA9IGdyaWRVdGlscy5VcGRhdGVkUm93cygpO1xuICAgICAgICBcdHZhciBuZXdSb3dzID0gZ3JpZFV0aWxzLk5ld1Jvd3MoKTtcbiAgICAgICAgXHR2YXIgZGVsZXRlZFJvd3MgPSBncmlkVXRpbHMuRGVsZXRlZFJvd3MoKTtcbiAgICAgICAgXHR2YXIgY2hhbmdlTGlzdElkcyA9IF8udW5pb24oIF8ucGx1Y2soIHVwZGF0ZWRSb3dzLCAnSWQnICksIF8ucGx1Y2soIGRlbGV0ZWRSb3dzLCAnSWQnICkgKTtcbiAgICAgICAgXHRcblx0XHRcdEtlbmFuZHlFcnAuQmxvY2tVSSggZ3JpZC5lbGVtZW50ICk7XG5cdFx0XHRcdFx0XHRcdFxuXHRcdFx0VmlzdWFsZm9yY2UucmVtb3RpbmcuTWFuYWdlci5pbnZva2VBY3Rpb24oXG5cdFx0ICAgIFx0c2VsZi5vcHRpb25zLnNhdmVBY3Rpb24sXG5cdFx0ICAgIFx0c2VsZi5vcHRpb25zLmRldGFpbENvbmZpZyxcdFx0XHQgICAgIFx0ICAgICAgICBcblx0XHRcdFx0dXBkYXRlZFJvd3MsIFxuXHRcdFx0XHRuZXdSb3dzLCBcblx0XHRcdFx0ZGVsZXRlZFJvd3MsIFxuXHRcdFx0XHRmdW5jdGlvbiggcmVzdWx0LCBldmVudCApIHtcblx0XHRcdFx0XHRLZW5hbmR5RXJwLlVuQmxvY2tVSSggZ3JpZC5lbGVtZW50ICk7XG5cdFx0XHRcdFx0XHQgICAgXHRcblx0XHRcdFx0XHRpZiAoIGV2ZW50LnR5cGUgPT0gJ2V4Y2VwdGlvbicgKSB7XG5cdFx0XHRcdFx0XHRLZW5hbmR5RXJwLk1lc3NhZ2UoIGV2ZW50Lm1lc3NhZ2UsIEtlbmFuZHlFcnAuTWVzc2FnZVR5cGUuRXJyb3IsIG1lc3NhZ2VFbGVtZW50ICk7XG5cdFx0XHRcdFx0fSBlbHNlIHtcblx0XHRcdFx0XHRcdGlmICggcmVzdWx0LnN1Y2Nlc3MgKSB7XG5cdFx0XHRcdFx0XHRcdHZhciBuZXdJZHMgPSBfLmRpZmZlcmVuY2UoIF8ucGx1Y2soIHJlc3VsdC5yZWNvcmRzLCAnSWQnICksIGNoYW5nZUxpc3RJZHMgKTtcblx0XHRcdFx0XHRcdFx0XG5cdFx0XHRcdFx0XHRcdC8vcmVmcmVzaCB0aGUgZ3JpZFxuXHQgICAgICAgICAgICAgICAgXHRcdGdyaWQuZGF0YVNvdXJjZS5fZGVzdHJveWVkID0gW107XG5cdCAgICAgICAgICAgICAgICBcdFx0Z3JpZC5kYXRhU291cmNlLnJlYWQoIHsgbmV3SWRzOiBuZXdJZHMgfSApO1xuXHRcdFx0XHRcdFx0XHRcdFx0XHRcblx0XHRcdFx0XHRcdFx0Ly8gdHJpZ2dlciBvbnNhdmVzdWNjZXNzXG5cdFx0XHRcdFx0XHRcdGdyaWQuZWxlbWVudC50cmlnZ2VyKCBcIk9uU2F2ZVN1Y2Nlc3NcIiApO1xuXHRcdFx0XHRcdFx0XHRcdFx0XHRcblx0XHRcdFx0XHRcdFx0S2VuYW5keUVycC5NZXNzYWdlcyggcmVzdWx0Lm1lc3NhZ2VzLCBtZXNzYWdlRWxlbWVudCApO1xuXHRcdFx0XHRcdFx0fSBlbHNlIHtcblx0XHRcdFx0XHRcdFx0S2VuYW5keUVycC5NZXNzYWdlcyggcmVzdWx0Lm1lc3NhZ2VzLCBtZXNzYWdlRWxlbWVudCApO1xuXHRcdFx0XHRcdFx0fVxuXHRcdFx0XHRcdH1cblx0XHRcdFx0fSxcblx0XHRcdFx0eyBlc2NhcGU6IGZhbHNlIH1cblx0XHRcdCk7XG4gICBcdFx0fVxuXHR9O1xufSgpO1xubW9kdWxlLkdyaWRBY3Rpb25MaXN0ID0gKCBmdW5jdGlvbiggJCApIHtcbiAgICB2YXIga2VuZG8gPSB3aW5kb3cua2VuZG8sXG4gICAgICAgIHVpID0ga2VuZG8udWksXG4gICAgICAgIFdpZGdldCA9IHVpLldpZGdldCxcbiAgICAgICAgQ0hBTkdFID0gXCJjaGFuZ2VcIjtcbiAgICAgICAgT05SRUFERkFJTFVSRSA9IFwiT25SZWFkRmFpbHVyZVwiO1xuICAgICAgICBPTlJFQURTVUNDRVNTID0gXCJPblJlYWRTdWNjZXNzXCI7XG5cblx0dmFyIEdyaWREZXRhaWxMaXN0ID0gdWkuR3JpZC5leHRlbmQoIHtcblx0XHRfZGV0YWlsQ29uZmlnOiBudWxsLFxuXHRcdF9kZXRhaWxGaWVsZExpc3Q6IG51bGwsXG5cdFx0X3N0YW5kYXJkQnV0dG9uczogbnVsbCxcblx0XHRfZGV0YWlsTmFtZXNwYWNlOiBudWxsLFxuXHRcdF9kZXRhaWxSZWZlcmVuY2VGaWVsZHM6IG51bGwsXG5cdFx0X2RldGFpbERhdGVGaWVsZHM6IG51bGwsXG5cdFx0X2RldGFpbE5lc3RlZEZpZWxkczogbnVsbCxcblx0XHRfbG9va3VwU2VhcmNoRmlsdGVyczogbnVsbCxcblx0XHRfZGV0YWlsTW9kZWxJZEZpZWxkOiBudWxsLFxuXHRcdF9nZXREZXRhaWxMaXN0RnVuY3Rpb246IG51bGwsXG5cdFx0X2RldGFpbEFsbG93TWFzc0RlbGV0ZTogbnVsbCxcblx0XHRfZGV0YWlsU2hvd0ljb25CdXR0b25zOiBudWxsLFxuXHRcdFxuICAgICAgICAvLyBtZXRob2QgY2FsbGVkIHdoZW4gYSBuZXcgd2lkZ2V0IGlzIGNyZWF0ZWRcbiAgICAgICAgaW5pdDogZnVuY3Rpb24oIGVsZW1lbnQsIG9wdGlvbnMgKSB7XG4gICAgICAgICAgICB2YXIgdGhhdCA9IHRoaXM7XG4gICAgICAgICAgICBcblx0XHRcdHRoYXQuX2luaXREZWZhdWx0cyggb3B0aW9ucyApO1xuXHRcdFx0XG4gICAgICAgICAgICB2YXIgZ2V0RGV0YWlsTW9kZWwgPSBmdW5jdGlvbigpIHtcblx0ICAgICAgICAgICAgdmFyIGZpZWxkcyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXRGaWVsZHMoIF9kZXRhaWxGaWVsZExpc3QgKTtcdFxuXHRcblx0ICAgICAgICAgICAgLy8gQWRkIHNjaGVtYSBmb3IgY2hlY2tib3ggY29sdW1uXG5cdFx0XHRcdGZpZWxkcy5Jc1NlbGVjdGVkX19jdXN0b20gPSB7IHR5cGU6IFwiYm9vbGVhblwiIH07XG5cdFx0XHRcdFx0XHRcdFx0XG5cdFx0XHRcdHZhciBtb2RlbCA9IGtlbmRvLmRhdGEuTW9kZWwuZGVmaW5lKCB7IGlkOiBfZGV0YWlsTW9kZWxJZEZpZWxkLCBmaWVsZHM6IGZpZWxkcyB9ICk7XG5cdFx0XHRcdFx0XHRcblx0XHRcdFx0cmV0dXJuIG1vZGVsO1xuXHRcdFx0fTtcblx0XHRcdFx0XHRcblx0XHRcdHZhciBnZXREZXRhaWxDb2x1bW5zID0gZnVuY3Rpb24oKSB7XG5cdCAgICAgICAgICAgIHZhciBjb2x1bW5zID0gS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkdldENvbHVtbnMoIF9kZXRhaWxGaWVsZExpc3QsIHsgbG9va3VwU2VhcmNoQWN0aW9uOiBvcHRpb25zLmxvb2t1cFNlYXJjaEFjdGlvbiwgYnV0dG9uczogX3N0YW5kYXJkQnV0dG9ucywgbG9va3VwU2VhcmNoRmlsdGVyczogX2xvb2t1cFNlYXJjaEZpbHRlcnMsIGRldGFpbEFsbG93TWFzc0RlbGV0ZTogX2RldGFpbEFsbG93TWFzc0RlbGV0ZSwgZGV0YWlsVmFsaWRhdGVPbkJsdXI6IG9wdGlvbnMuZGV0YWlsVmFsaWRhdGVPbkJsdXIgfSApO1xuXHQgICAgICAgICAgICBcblx0ICAgICAgICAgICAgLy8gQWRkIGNoZWNrYm94IGNvbHVtblxuXHRcdFx0XHRjb2x1bW5zLnVuc2hpZnQoIHsgZmllbGQ6ICdJc1NlbGVjdGVkX19jdXN0b20nLCBmaWx0ZXJhYmxlOiBmYWxzZSwgc29ydGFibGU6IGZhbHNlLCAgd2lkdGg6IDMwLCBhdHRyaWJ1dGVzOiB7IGNsYXNzOiAna25keS10ZXh0LWxlZnQnIH0sIGhlYWRlckF0dHJpYnV0ZXM6IHsgY2xhc3M6ICdrbmR5LXRleHQtbGVmdCcgfSB9ICk7IC8vdGVtcGxhdGU6IFwiPGlucHV0IHR5cGU9J2NoZWNrYm94JyBkYXRhLWJpbmQ9J0lzU2VsZWN0ZWRfX2N1c3RvbScgIz0gSXNTZWxlY3RlZF9fY3VzdG9tID8gY2hlY2tlZD0nY2hlY2tlZCc6ICcnICMgY2xhc3M9J2dyaWQtc2VsZWN0LW9uZScgLz5cIiwgaGVhZGVyVGVtcGxhdGU6IFwiPGlucHV0IHR5cGU9J2NoZWNrYm94JyBjbGFzcz0nZ3JpZC1zZWxlY3QtYWxsJyAvPlwiLFxuXHRcdFx0XHRcdFxuXHRcdFx0XHRyZXR1cm4gY29sdW1ucztcblx0XHRcdH07XG5cdFx0XHRcblx0XHRcdHZhciBnZXREZXRhaWxUb29sYmFyQnV0dG9ucyA9IGZ1bmN0aW9uKCkge1xuXHRcdFx0XHR2YXIgYnV0dG9ucyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXRUb29sYmFyQnV0dG9ucyggX3N0YW5kYXJkQnV0dG9ucywgeyBkZXRhaWxTaG93SWNvbkJ1dHRvbnM6IF9kZXRhaWxTaG93SWNvbkJ1dHRvbnMsIGRldGFpbEFsbG93TWFzc0RlbGV0ZTogX2RldGFpbEFsbG93TWFzc0RlbGV0ZSB9ICk7XG5cdFx0XHRcdFxuXHRcdFx0XHRidXR0b25zID0gXy51bmlvbiggYnV0dG9ucywgb3B0aW9ucy5kZXRhaWxUb29sYmFyQnV0dG9ucyApO1xuXHRcdFx0XHRyZXR1cm4gYnV0dG9ucztcblx0XHRcdH07XG5cdFx0XHRcblx0XHRcdHZhciBnZXREZXRhaWxEYXRhU291cmNlID0gZnVuY3Rpb24oKSB7XG5cdFx0XHRcdHZhciBkYXRhU291cmNlID0gbmV3IGtlbmRvLmRhdGEuRGF0YVNvdXJjZSgge1xuXHRcdFx0XHRcdHRyYW5zcG9ydDoge1xuXHRcdFx0XHRcdFx0cmVhZDogZnVuY3Rpb24oIG9wdGlvbnMgKSB7XG5cdFx0XHRcdFx0XHRcdEtlbmFuZHlFcnAuQmxvY2tVSSggZWxlbWVudCApO1xuXHRcdFx0XHRcdFx0XHRcblx0XHRcdFx0XHRcdFx0dmFyIHByb21pc2UgPSBfZ2V0RGV0YWlsTGlzdEZ1bmN0aW9uKCBvcHRpb25zLmRhdGEucmVhZE9wdGlvbnMgKTtcblx0XHRcdFx0XHRcdFx0cHJvbWlzZS5kb25lKCBmdW5jdGlvbiggcmVzdWx0LCBldmVudCApIHtcblx0XHRcdFx0XHQgICAgICAgICAgICBcdEtlbmFuZHlFcnAuVW5CbG9ja1VJKCBlbGVtZW50ICk7XG5cdFx0XHRcdFx0ICAgICAgICAgICAgXHRcblx0XHRcdFx0XHRcdCAgICAgICAgXHRpZiAoIGV2ZW50LnR5cGUgPT0gJ2V4Y2VwdGlvbicgKSB7XG5cdFx0XHRcdFx0XHQgICAgICAgIFx0XHRLZW5hbmR5RXJwLkFsZXJ0KCBcIkFuIGVycm9yIG9jY3VycmVkIHdoaWxlIHByb2Nlc3NpbmcgeW91ciByZXF1ZXN0LiBQbGVhc2UgY29udGFjdCBzdXBwb3J0XCIgKTsgXG5cdFx0XHRcdFx0XHRcdCAgICAgICAgXHRcdFxuXHRcdFx0XHRcdFx0ICAgICAgICBcdFx0Ly8gdHJpZ2dlciBvbnJlYWRmYWlsdXJlXG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgJCggZWxlbWVudCApLnRyaWdnZXIoIHtcblx0XHRcdFx0XHRcdFx0XHRcdCAgICAgICAgdHlwZTogT05SRUFERkFJTFVSRSxcblx0XHRcdFx0XHRcdFx0XHRcdCAgICAgICAgcmVzdWx0OiByZXN1bHQsIFxuXHRcdFx0XHRcdFx0XHRcdFx0ICAgICAgICBldmVudDogZXZlbnQgXG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgfSApO1xuXHRcdFx0XHRcdFx0XHRcdFx0fSBlbHNlIHtcblx0XHRcdFx0XHRcdFx0XHRcdFx0S2VuYW5keUVycC5DbGVhbk5hbWVzcGFjZSggcmVzdWx0LnJlY29yZHMsIF9kZXRhaWxOYW1lc3BhY2UgKTtcblx0XHRcdFx0XHRcdCAgICAgICAgICAgIFx0b3B0aW9ucy5zdWNjZXNzKCByZXN1bHQucmVjb3JkcyApO1xuXHRcdFx0XHRcdFx0ICAgICAgICAgICAgXHRcblx0XHRcdFx0XHRcdCAgICAgICAgICAgIFx0Ly8gdHJpZ2dlciBvbnJlYWRzdWNjZXNzXG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgJCggZWxlbWVudCApLnRyaWdnZXIoIHtcblx0XHRcdFx0XHRcdFx0XHRcdCAgICAgICAgdHlwZTogT05SRUFEU1VDQ0VTUyxcblx0XHRcdFx0XHRcdFx0XHRcdCAgICAgICAgcmVzdWx0OiByZXN1bHQsIFxuXHRcdFx0XHRcdFx0XHRcdFx0ICAgICAgICBldmVudDogZXZlbnQgXG5cdFx0XHRcdFx0XHRcdFx0XHQgICAgfSApO1xuXHRcdFx0XHRcdFx0XHRcdFx0fVxuXHRcdFx0XHRcdCAgICAgICAgICAgIH0gKTtcblx0XHRcdFx0XHRcdH1cblx0XHRcdFx0XHR9LFxuXHRcdFx0XHRcdGJhdGNoOiB0cnVlLFxuXHRcdFx0XHRcdHBhZ2VTaXplOiAoIF9kZXRhaWxDb25maWcucGFnZVNpemUgKSA/IF9kZXRhaWxDb25maWcucGFnZVNpemUgOiBLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuRGVmYXVsdFBhZ2VTaXplLFxuXHRcdFx0XHRcdHNjaGVtYToge1xuXHRcdFx0XHRcdFx0bW9kZWw6IGdldERldGFpbE1vZGVsKCksXG5cdFx0XHRcdFx0XHRwYXJzZTpmdW5jdGlvbiggcmVzcG9uc2UgKSB7XG5cdFx0XHQgICAgICAgICAgICAgICAgJC5lYWNoKCByZXNwb25zZSwgZnVuY3Rpb24oIGlkeCwgaXRlbSApIHtcblx0XHRcdCAgICAgICAgICAgICAgICBcdGl0ZW0gPSBTZXJpYWxpemVyLkluY2x1ZGVOdWxscyggaXRlbSwgeyBmaWVsZHM6IF9kZXRhaWxOZXN0ZWRGaWVsZHMgfSApO1xuXHQgICAgICAgICAgICAgICAgICAgIFx0XHRpdGVtID0gU2VyaWFsaXplci5Db252ZXJ0RnJvbVNGRENEYXRlKCBpdGVtLCB7IGRhdGVGaWVsZHM6IF9kZXRhaWxEYXRlRmllbGRzIH0gKTtcblx0XHRcdFx0XHRcdCAgICB9ICk7XG5cdFx0XHRcdFx0XHQgICAgXG5cdFx0XHQgICAgICAgICAgICAgICAgcmV0dXJuIHJlc3BvbnNlO1xuXHRcdFx0XHRcdFx0fSAgICAgICAgIFx0XG5cdFx0XHRcdFx0fSxcblx0XHRcdFx0XHRhZ2dyZWdhdGU6IG9wdGlvbnMuYWdncmVnYXRlcyA/IG9wdGlvbnMuYWdncmVnYXRlcyA6IG51bGwgICAgXHRcblx0XHRcdFx0fSApO1xuXHRcblx0XHRcdFx0cmV0dXJuIGRhdGFTb3VyY2U7XG5cdFx0XHR9O1xuXHRcdFx0XHRcbiAgICAgICAgICAgIHZhciBkZWZhdWx0T3B0aW9ucyA9IHtcblx0ICAgICAgICBcdGRhdGFTb3VyY2U6IGdldERldGFpbERhdGFTb3VyY2UoKSwgXG5cdCAgICAgICAgXHRuYXZpZ2F0YWJsZTogdHJ1ZSxcblx0ICAgICAgICBcdHBhZ2VhYmxlOiB7IFxuXHQgICAgICAgIFx0XHRpbnB1dDogdHJ1ZSxcblx0ICAgICAgICAgICAgICAgIG51bWVyaWM6IGZhbHNlLFxuXHQgICAgICAgIFx0XHRwYWdlU2l6ZXM6IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5QYWdlU2l6ZXMsXG5cdCAgICAgICAgXHRcdG1lc3NhZ2VzOiB7XG5cdCAgICAgICAgXHRcdFx0ZGlzcGxheTogJ3swfSAtIHsxfSBvZiB7Mn0gcmVjb3JkcycsXG5cdCAgICAgICAgXHRcdFx0ZW1wdHk6ICcnLFxuXHQgICAgICAgIFx0XHRcdGl0ZW1zUGVyUGFnZTogJ3JlY29yZHMgcGVyIHBhZ2UnXG5cdCAgICAgICAgXHRcdH1cblx0XHRcdFx0fSxcdFx0XG5cdFx0ICAgICAgICB0b29sYmFyOiBnZXREZXRhaWxUb29sYmFyQnV0dG9ucygpLFxuXHRcdCAgICAgICAgY29sdW1uczogZ2V0RGV0YWlsQ29sdW1ucygpLFxuXHRcdCAgICAgICAgc29ydGFibGU6IHRydWUsXG5cdFx0XHRcdGZpbHRlcmFibGU6IHRydWUsXG5cdFx0XHRcdHJlc2l6YWJsZTogdHJ1ZSxcblx0XHRcdFx0ZWRpdGFibGU6IHRydWVcblx0ICAgICAgICB9O1xuXHQgICAgICAgIFxuXHQgICAgICAgIG9wdGlvbnMgPSAkLmV4dGVuZCgge30sIGRlZmF1bHRPcHRpb25zLCBvcHRpb25zICk7XG5cdCAgICAgICAgXG4gICAgICAgICAgICBpZiAoICQoIGVsZW1lbnQgKS5kYXRhKCAna2VuZG9HcmlkJyApICE9PSBudWxsICkgeyBcbiAgICAgICAgICAgICAgICAkKCBlbGVtZW50ICkuZGF0YSggJ2tlbmRvR3JpZCcgKS5kZXN0cm95KCk7IFxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgXG4gICAgICAgICAgICB1aS5HcmlkLmZuLmluaXQuY2FsbCggdGhhdCwgZWxlbWVudCwgb3B0aW9ucyApO1xuXHRcdFx0XG5cdFx0XHQkKCBlbGVtZW50ICkuZGF0YSggXCJrZW5kb0dyaWRcIiwgdGhhdCApO1xuXHRcdFx0XG5cdFx0XHR0aGF0Ll9pbml0RXZlbnRzKCk7XG4gICAgICAgIH0sXG4gICAgICAgIFxuICAgICAgICAvLyB3aWRnZXQgb3B0aW9uc1xuICAgICAgICBvcHRpb25zOiB7XG4gICAgICAgICAgICBuYW1lOiBcIkdyaWREZXRhaWxMaXN0XCIsXG4gICAgICAgICAgICBkZXRhaWxDb25maWc6IG51bGwsXG4gICAgICAgICAgICBkZXRhaWxGaWVsZExpc3Q6IG51bGwsXG4gICAgICAgICAgICBkZXRhaWxOYW1lc3BhY2U6IG51bGwsXG4gICAgICAgICAgICBsb29rdXBTZWFyY2hBY3Rpb246IG51bGwsXG4gICAgICAgICAgICBnZXREZXRhaWxMaXN0RnVuY3Rpb246IG51bGwsXG4gICAgICAgICAgICBzYXZlRGV0YWlsTGlzdEFjdGlvbjogbnVsbCxcbiAgICAgICAgICAgIGRldGFpbEFkZFJvd0FjdGlvbjogbnVsbCxcbiAgICAgICAgICAgIGxvb2t1cFNlYXJjaEZpbHRlcnM6IFtdLFxuICAgICAgICAgICAgZGV0YWlsTW9kZUlkRmllbGQ6ICdJZCcsXG4gICAgICAgICAgICBkZXRhaWxBbGxvd01hc3NEZWxldGU6IHRydWUsXG4gICAgICAgICAgICBkZXRhaWxTaG93SWNvbkJ1dHRvbnM6IGZhbHNlLFxuICAgICAgICAgICAgZGV0YWlsVG9vbGJhckJ1dHRvbnM6IFtdLFxuICAgICAgICAgICAgZGV0YWlsVmFsaWRhdGVPbkJsdXI6IGZhbHNlXG4gICAgICAgIH0sXG4gICAgICAgIFxuICAgICAgICAvLyBldmVudHMgdGhlIGNvbnRyb2wgY2FuIGZpcmVcblx0XHRldmVudHM6IFsgQ0hBTkdFIF0sXG5cdFx0XG5cdFx0X2luaXREZWZhdWx0czogZnVuY3Rpb24oIG9wdGlvbnMgKSB7XG5cdFx0XHR2YXIgdGhhdCA9IHRoaXM7XG5cdFx0XHRcblx0XHRcdF9kZXRhaWxDb25maWcgPSBKU09OVXRpbHMuUGFyc2UoIG9wdGlvbnMuZGV0YWlsQ29uZmlnICk7XG5cdFx0XHRfZGV0YWlsRmllbGRMaXN0ID0gSlNPTlV0aWxzLlBhcnNlKCBvcHRpb25zLmRldGFpbEZpZWxkTGlzdCApO1xuXHRcdFx0X3N0YW5kYXJkQnV0dG9ucyA9ICQubWFwKCBfZGV0YWlsQ29uZmlnLmJ1dHRvbnMuc3BsaXQoICcsJyApLCAkLnRyaW0gKTtcblx0XHRcdF9kZXRhaWxOYW1lc3BhY2UgPSBfZGV0YWlsQ29uZmlnLmRldGFpbE5hbWVzcGFjZSA/IF9kZXRhaWxDb25maWcuZGV0YWlsTmFtZXNwYWNlIDogb3B0aW9ucy5kZXRhaWxOYW1lc3BhY2U7XG5cdFx0XHRfZGV0YWlsUmVmZXJlbmNlRmllbGRzID0gS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkdldFJlZmVyZW5jZUZpZWxkcyggX2RldGFpbEZpZWxkTGlzdCApOyAvLyBnZXQgdGhlIGxpc3Qgb2YgcmVmZXJlbmNlIGZpZWxkc1xuXHRcdFx0X2RldGFpbERhdGVGaWVsZHMgPSBLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuR2V0RGF0ZUZpZWxkcyggX2RldGFpbEZpZWxkTGlzdCApOyAvLyBnZXQgdGhlIGxpc3Qgb2YgZGF0ZSBmaWVsZHNcblx0XHRcdF9sb29rdXBTZWFyY2hGaWx0ZXJzID0gKCBvcHRpb25zLmxvb2t1cFNlYXJjaEZpbHRlcnMgKSA/IG9wdGlvbnMubG9va3VwU2VhcmNoRmlsdGVycyA6IFtdO1xuXHRcdFx0X2RldGFpbE5lc3RlZEZpZWxkcyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXROZXN0ZWRGaWVsZHMoIF9kZXRhaWxGaWVsZExpc3QgKTsgLy8gZ2V0IHRoZSBsaXN0IG9mIG5lc3RlZCBmaWVsZHNcblx0XHRcdF9kZXRhaWxNb2RlbElkRmllbGQgPSBvcHRpb25zLmRldGFpbE1vZGVJZEZpZWxkID8gb3B0aW9ucy5kZXRhaWxNb2RlSWRGaWVsZCA6ICdJZCc7XG5cdFx0XHRfZ2V0RGV0YWlsTGlzdEZ1bmN0aW9uID0gb3B0aW9ucy5nZXREZXRhaWxMaXN0RnVuY3Rpb247XG5cdFx0XHRfZGV0YWlsU2hvd0ljb25CdXR0b25zID0gKCBvcHRpb25zLmRldGFpbFNob3dJY29uQnV0dG9ucyApID8gb3B0aW9ucy5kZXRhaWxTaG93SWNvbkJ1dHRvbnMgOiB0aGF0Lm9wdGlvbnMuZGV0YWlsU2hvd0ljb25CdXR0b25zO1xuXHRcdFx0X2RldGFpbEFsbG93TWFzc0RlbGV0ZSA9ICggb3B0aW9ucy5kZXRhaWxBbGxvd01hc3NEZWxldGUgKSA/IG9wdGlvbnMuZGV0YWlsQWxsb3dNYXNzRGVsZXRlIDogdGhhdC5vcHRpb25zLmRldGFpbEFsbG93TWFzc0RlbGV0ZTtcblx0XHR9LFxuXHRcdFxuXHRcdF9pbml0RXZlbnRzOiBmdW5jdGlvbigpIHtcblx0XHRcdHZhciB0aGF0ID0gdGhpcztcblx0XHRcdHZhciBncmlkID0gdGhhdDtcblx0XHRcdFxuXHRcdFx0Ly8gYmluZCBncmlkIGVkaXQgZXZlbnRcblx0XHRcdGdyaWQuYmluZCggJ2VkaXQnLCAkLnByb3h5KCBLZW5hbmR5RXJwLktlbmRvR3JpZEFjdGlvbnMuRWRpdCwgeyByZWZlcmVuY2VGaWVsZHM6IF9kZXRhaWxSZWZlcmVuY2VGaWVsZHMgfSApICk7XG5cdFx0XHRcdFxuXHRcdFx0Ly8gYmluZCBncmlkIGRhdGFCb3VuZCBldmVudFxuXHRcdFx0Z3JpZC5iaW5kKCAnZGF0YUJvdW5kJywgS2VuYW5keUVycC5LZW5kb0dyaWRBY3Rpb25zLkRhdGFCb3VuZCApO1xuXHRcdFx0XHRcblx0XHRcdC8vIGJpbmQgY2xpY2sgZXZlbnRzIHRvIHRoZSBjdXN0b20gYnV0dG9uc1xuXHRcdFx0S2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkJpbmRFdmVudHMoIGdyaWQsIF9zdGFuZGFyZEJ1dHRvbnMsIHsgc2F2ZUFjdGlvbjogdGhhdC5vcHRpb25zLnNhdmVEZXRhaWxMaXN0QWN0aW9uLCBkZXRhaWxBZGRSb3dBY3Rpb246IHRoYXQub3B0aW9ucy5kZXRhaWxBZGRSb3dBY3Rpb24sIHJlZmVyZW5jZUZpZWxkczogX2RldGFpbFJlZmVyZW5jZUZpZWxkcywgZGV0YWlsQ29uZmlnOiBfZGV0YWlsQ29uZmlnLCBkYXRlRmllbGRzOiBfZGV0YWlsRGF0ZUZpZWxkcywgaWdub3JlQmluZGluZ3M6IFsgS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLkNvbW1hbmRUeXBlLlNhdmUgXSB9ICk7XG5cblx0XHRcdC8vIHNldCB0aGUgZ3JpZCBoZWlnaHRcblx0XHRcdGlmICggdGhhdC5vcHRpb25zLmhlaWdodCApIHtcblx0XHRcdFx0Z3JpZC53cmFwcGVyLmhlaWdodCggdGhhdC5vcHRpb25zLmhlaWdodCApO1xuXHRcdFx0fVxuXHRcdFx0XG5cdFx0XHRncmlkLndyYXBwZXIub24oIFwiY2xpY2tcIiwgXCIuZ3JpZC1zYXZlLWNvbW1hbmRcIiwgJC5wcm94eSggR3JpZERldGFpbExpc3RBY3Rpb25zLlNhdmUsIHsgZ3JpZDogZ3JpZCwgb3B0aW9uczogeyBzYXZlQWN0aW9uOiB0aGF0Lm9wdGlvbnMuc2F2ZURldGFpbExpc3RBY3Rpb24sIGRldGFpbENvbmZpZzogX2RldGFpbENvbmZpZyB9IH0gKSApO1xuXHRcdFx0Z3JpZC50aGVhZC5vbiggXCJjbGlja1wiLCBcIi5ncmlkLXNlbGVjdC1hbGxcIiwgJC5wcm94eSggS2VuYW5keUVycC5LZW5kb0dyaWRBY3Rpb25zLlNlbGVjdEFsbCwgeyBncmlkOiBncmlkIH0gKSApO1xuXHRcdFx0Z3JpZC50Ym9keS5vbiggXCJjaGFuZ2VcIiwgXCIuZ3JpZC1zZWxlY3Qtb25lXCIsICQucHJveHkoIEtlbmFuZHlFcnAuS2VuZG9HcmlkQWN0aW9ucy5TZWxlY3QsIHsgZ3JpZDogZ3JpZCB9ICkgKTtcblx0XHRcdFxuXHRcdFx0Z3JpZC5iaW5kKCAnZGF0YUJvdW5kJywgZnVuY3Rpb24oKSB7XG5cdFx0XHRcdHZhciBpc1NlbGVjdGVkID0gKCBncmlkLnRib2R5LmZpbmQoICcuZ3JpZC1zZWxlY3Qtb25lJyApLmxlbmd0aCA+IDAgJiYgIWdyaWQudGJvZHkuZmluZCggJy5ncmlkLXNlbGVjdC1vbmUnICkuaXMoICc6bm90KDpjaGVja2VkKScgKSApID8gdHJ1ZSA6IGZhbHNlO1xuXHRcdFx0XHRncmlkLnRoZWFkLmZpbmQoICcuZ3JpZC1zZWxlY3QtYWxsJyApLnByb3AoICdjaGVja2VkJywgaXNTZWxlY3RlZCApO1xuXHRcdFx0fSApO1xuXHRcdH1cblx0fSApO1xuXG5cdHVpLnBsdWdpbiggR3JpZERldGFpbExpc3QgKTtcbn0gKSggalF1ZXJ5ICk7XG4iLCIvKiBnbG9iYWwgUGxhblZpZXcgKi9cbi8qIGdsb2JhbCAkICovXG4vKiBnbG9iYWwgQWdyZWVtZW50Vmlld0NvbXBvbmVudCAqL1xudmFyIHV0aWxpdHkgPSByZXF1aXJlKCBcIi4uL3V0aWxzL0FncmVlbWVudFZpZXdIZWxwZXJcIiApO1xudmFyIGRyYXdTZWNvbmRHcmlkID0gcmVxdWlyZSggXCIuL0FncmVlbWVudExpbmVHcmlkXCIgKTtcbnZhciBkcmF3VHJlZUxpc3QgPSByZXF1aXJlKCBcIi4vQWdyZWVtZW50TGluZVRyZWVMaXN0XCIgKTtcbnJlcXVpcmUoIFwiLi4vdXRpbHMvR3JpZEFjdGlvbkxpc3RcIiApO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKCkge1xuXG5cdHZhciBhZ3JlZW1lbnREYXRhID0gZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBkZWZlcnJlZCA9ICQuRGVmZXJyZWQoKTtcblxuICAgICAgICBWaXN1YWxmb3JjZS5yZW1vdGluZy5NYW5hZ2VyLmludm9rZUFjdGlvbihcbiAgICAgICAgICAgIEFncmVlbWVudFZpZXdDb21wb25lbnQuZ2V0QWdyZWVtZW50RGF0YSxcbiAgICAgICAgICAgIEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50SWQsXG4gICAgICAgICAgICBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnBsYW5JZCxcbiAgICAgICAgICAgIGZ1bmN0aW9uKCByZXN1bHQsIGV2ZW50ICkge1xuICAgICAgICAgICAgICAgIGRlZmVycmVkLnJlc29sdmUoIHJlc3VsdCwgZXZlbnQgKTtcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICB7IGVzY2FwZTogZmFsc2UgfVxuICAgICAgICApO1xuXG4gICAgICAgIHJldHVybiBkZWZlcnJlZC5wcm9taXNlKCk7XG4gICAgfTtcbiAgICBcbiAgICB2YXIgZ3JpZCA9ICQoICcjcHJvbW90aW9ucycgKS53aWR0aCggJCggJyNtYWlucGFnZScgKS53aWR0aCgpKS5rZW5kb0dyaWRBY3Rpb25MaXN0KCB7XG4gICAgICAgIHNlbGVjdGFibGU6IHRydWUsXG4gICAgICAgIGNvbmZpZzogQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hZ3JlZW1lbnRHcmlkQ29uZmlnLFxuICAgICAgICBuYW1lc3BhY2U6IEFncmVlbWVudFZpZXdDb21wb25lbnQubmFtZXNwYWNlVVUsIFxuICAgICAgICBmaWVsZExpc3Q6IHV0aWxpdHkuZ2V0RmllbGRMaXN0KEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50RmllbGRMaXN0KSxcbiAgICAgICAgZ2V0QWN0aW9uTGlzdEZ1bmN0aW9uOiBhZ3JlZW1lbnREYXRhLFxuICAgICAgICBhbGxvd01hc3NEZWxldGU6IGZhbHNlLFxuICAgICAgICBsb29rdXBTZWFyY2hBY3Rpb246IEFncmVlbWVudFZpZXdDb21wb25lbnQubG9va3VwU2VhcmNoQWN0aW9uLFxuICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzOiBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmFncmVlbWVudExvb2t1cFNlYXJjaEZpbHRlcnMsXG4gICAgICAgIHRvb2xiYXJCdXR0b25zOiBbXG4gICAgICAgICAgICAgICAgdXRpbGl0eS5nZXRBZ3JlZW1lbnRCdXR0b25zKCksXG4gICAgICAgICAgICAgICAgeyBuYW1lOiBcImdyaWQtc2F2ZS1hZ3JlZW1lbnQtY29tbWFuZFwiLFxuICAgICAgICAgICAgICAgICAgICB0ZXh0OlwiXCIsXG4gICAgICAgICAgICAgICAgICAgIHRlbXBsYXRlOiBcIjxpbnB1dCB0eXBlPSdidXR0b24nIHZhbHVlPSdTYXZlIENoYW5nZXMnIGNsYXNzPSdidG4gZ3JpZC1zYXZlLWFncmVlbWVudC1jb21tYW5kJyAvPlwiIH0sXG4gICAgICAgICAgICAgICAgeyBuYW1lOiBcImdyaWQtY2FuY2VsLWFncmVlbWVudC1jb21tYW5kXCIsXG4gICAgICAgICAgICAgICAgICAgIHRleHQ6XCJcIixcbiAgICAgICAgICAgICAgICAgICAgdGVtcGxhdGU6IFwiPGlucHV0IHR5cGU9J2J1dHRvbicgdmFsdWU9J0NhbmNlbCBDaGFuZ2VzJyBjbGFzcz0nYnRuIGdyaWQtY2FuY2VsLWFncmVlbWVudC1jb21tYW5kJyAvPlwiIH0sXG4gICAgICAgICAgICAgICAgeyBuYW1lOlwiZm9ybWF0TGFiZWxcIixcbiAgICAgICAgICAgICAgICAgICAgdGVtcGxhdGU6IFwiPGxhYmVsIHN0eWxlPSdwYWRkaW5nLWxlZnQ6IDUwcHg7IHBhZGRpbmctcmlnaHQ6IDVweDsnPlwiICtcbiAgICAgICAgICAgICAgICAgICAgICAgIEFncmVlbWVudFZpZXdDb21wb25lbnQuYWN0aW9uTGFiZWwgK1xuICAgICAgICAgICAgICAgICAgICAgICAgXCI6PC9sYWJlbD5cIiB9LFxuICAgICAgICAgICAgICAgIHsgbmFtZTpcInByb21vQWN0aW9uRHJvcGRvd25cIixcbiAgICAgICAgICAgICAgICAgICAgdGVtcGxhdGU6IFwiPGlucHV0IGlkPSdwcm9tb0FjdGlvbkRyb3Bkb3duJyBzdHlsZT0nd2lkdGg6IDIyNXB4OycgLz5cIixcbiAgICAgICAgICAgICAgICAgICAgb3ZlcmZsb3c6IFwibmV2ZXJcIiB9LFxuICAgICAgICAgICAgXHR7IG5hbWU6XCJwcm9tb0FjdGlvbkdvXCIsXG4gICAgICAgICAgICAgICAgICAgIHRleHQ6IEFncmVlbWVudFZpZXdDb21wb25lbnQuZ29MYWJlbCB9ICAgICAgICAgICBcdCAgIFxuICAgICAgICBdLFxuICAgICAgICBiZWZvcmVFZGl0OiB1dGlsaXR5LmNoZWNrQmVmb3JlRWRpdFxuXG4gICAgfSApLmRhdGEoIFwia2VuZG9HcmlkQWN0aW9uTGlzdFwiICk7XG5cblx0Z3JpZC5iaW5kKCBcImRhdGFCb3VuZFwiLCBmdW5jdGlvbiggZSApIHtcbiAgICAgICAgaWYgKCAhJCggXCIjcHByb2RcIiApLmRhdGEoIFwia2VuZG9UcmVlTGlzdFwiICkgKSB7XG4gICAgICAgICAgICBkcmF3VHJlZUxpc3QoIGdyaWQuZGF0YVNvdXJjZS5fZGF0YVsgMCBdICk7XG4gICAgICAgIH0gICAgICBcblx0fSApO1xuXG4gICAgLy9hZ3JlZW1lbnREYXRhLmRvbmUoZnVuY3Rpb24ocmVzdWx0LCBldmVudCl7XG4gICAgdXRpbGl0eS5lbGVtZW50SW5pdCggZ3JpZCwgZmFsc2UgKTtcblxuICAgIGdyaWQuYmluZCggXCJlZGl0XCIsIGZ1bmN0aW9uKCBlICkge1xuICAgICAgICBpZiAoIGUubW9kZWwuaXNOZXcoKSApIHsgICAgICAgICAgICAgICAgICAgICAvLyBpZiByb3cgaXMgbmV3LCB0aGVuIHNldCBkZWZhdWx0c1xuICAgICAgICAgICAgZS5tb2RlbC5zZXQoIFwiUGxhbl9fY1wiLCBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnBsYW5JZCApO1xuICAgICAgICAgICAgZS5tb2RlbC5zZXQoIFwiU3RhcnRfRGF0ZV9fY1wiLCBLZW5hbmR5RXJwLlBhcnNlU0ZEQ0RhdGUoIFBsYW5WaWV3LnBsYW5TdGFydCApICk7XG4gICAgICAgICAgICBlLm1vZGVsLnNldCggXCJFbmRfRGF0ZV9fY1wiLCBLZW5hbmR5RXJwLlBhcnNlU0ZEQ0RhdGUoIFBsYW5WaWV3LnBsYW5FbmQgKSApO1xuICAgICAgICAgICAgZS5tb2RlbC5zZXQoIFwiQXBwcm92YWxfRGF0ZV9fY1wiLCBudWxsICk7XG4gICAgICAgICAgICBlLm1vZGVsLnNldCggXCJBY3RpdmF0aW9uX0RhdGVfX2NcIiwgbnVsbCApO1xuICAgICAgICB9XG4gICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJCaWxsX1RvX19jXCJdJykubGVuZ3RoID4gMCApIHtcbiAgICAgICAgICAgIHZhciBsb29rdXBTZWFyY2hGaWx0ZXJzID0gW107XG4gICAgICAgICAgICB2YXIgY3VzdG9tZXIgPSBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnRoZUFncmVlbWVudC5DdXN0b21lcl9fYzsgXG4gICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJCaWxsX1RvX19jXCIsIGZpbHRlcjogXCJSZWNvcmRUeXBlLkRldmVsb3Blck5hbWUgID0gXFwnQmlsbF9Ub1xcJyBBTkQgVG9wX1BhcmVudF9DdXN0b21lcl9fYyA9ICdcIiArIGN1c3RvbWVyICsgXCInIFwiIH0pO1xuICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cIkJpbGxfVG9fX2NcIl0nKS5kYXRhKCdrZW5kb0xvb2t1cCcpLm9wdGlvbnMuY3JpdGVyaWEgPSBsb29rdXBTZWFyY2hGaWx0ZXJzO1xuICAgICAgICB9XG4gICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJTb2xkX1RvX19jXCJdJykubGVuZ3RoID4gMCApIHtcbiAgICAgICAgICAgIHZhciBsb29rdXBTZWFyY2hGaWx0ZXJzID0gW107XG4gICAgICAgICAgICB2YXIgY3VzdG9tZXIgPSBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnRoZUFncmVlbWVudC5DdXN0b21lcl9fYzsgXG4gICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJTb2xkX1RvX19jXCIsIGZpbHRlcjogXCJSZWNvcmRUeXBlLkRldmVsb3Blck5hbWUgID0gXFwnU29sZF9Ub1xcJyBBTkQgVG9wX1BhcmVudF9DdXN0b21lcl9fYyA9ICdcIiArIGN1c3RvbWVyICsgXCInIFwiIH0pO1xuICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cIlNvbGRfVG9fX2NcIl0nKS5kYXRhKCdrZW5kb0xvb2t1cCcpLm9wdGlvbnMuY3JpdGVyaWEgPSBsb29rdXBTZWFyY2hGaWx0ZXJzO1xuICAgICAgICB9XG4gICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJTaGlwX1RvX19jXCJdJykubGVuZ3RoID4gMCApIHtcbiAgICAgICAgICAgIHZhciBsb29rdXBTZWFyY2hGaWx0ZXJzID0gW107XG4gICAgICAgICAgICB2YXIgY3VzdG9tZXIgPSBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnRoZUFncmVlbWVudC5DdXN0b21lcl9fYzsgXG4gICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJTaGlwX1RvX19jXCIsIGZpbHRlcjogXCJSZWNvcmRUeXBlLkRldmVsb3Blck5hbWUgID0gXFwnU2hpcF9Ub1xcJyBBTkQgVG9wX1BhcmVudF9DdXN0b21lcl9fYyA9ICdcIiArIGN1c3RvbWVyICsgXCInIFwiIH0pO1xuICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cIlNoaXBfVG9fX2NcIl0nKS5kYXRhKCdrZW5kb0xvb2t1cCcpLm9wdGlvbnMuY3JpdGVyaWEgPSBsb29rdXBTZWFyY2hGaWx0ZXJzO1xuICAgICAgICB9XG4gICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJTaXRlX19jXCJdJykubGVuZ3RoID4gMCApIHtcbiAgICAgICAgICAgIHZhciBsb29rdXBTZWFyY2hGaWx0ZXJzID0gW107XG4gICAgICAgICAgICB2YXIgY3VzdG9tZXIgPSBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnRoZUFncmVlbWVudC5DdXN0b21lcl9fYzsgXG4gICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJTaXRlX19jXCIsIGZpbHRlcjogXCJSZWNvcmRUeXBlLkRldmVsb3Blck5hbWUgID0gXFwnU2l0ZVxcJyBBTkQgVG9wX1BhcmVudF9DdXN0b21lcl9fYyA9ICdcIiArIGN1c3RvbWVyICsgXCInIFwiIH0pO1xuICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cIlNpdGVfX2NcIl0nKS5kYXRhKCdrZW5kb0xvb2t1cCcpLm9wdGlvbnMuY3JpdGVyaWEgPSBsb29rdXBTZWFyY2hGaWx0ZXJzO1xuICAgICAgICB9XG4gICAgICAgIFxuICAgICAgICBpZiggJCggZS5jb250YWluZXIgKS5maW5kKCdpbnB1dFtuYW1lPVwiQ3VzdG9tZXJfX2NcIl0nKS5sZW5ndGggPiAwICkge1xuICAgICAgICAgICAgdmFyIGxvb2t1cFNlYXJjaEZpbHRlcnMgPSBbXTtcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgaWYgKCBlLm1vZGVsLmdldCggXCJDdXN0b21lcl9UeXBlX19jXCIgKSA9PSBcIkJpbGwgVG9cIiB8fCBlLm1vZGVsLmdldCggXCJDdXN0b21lcl9UeXBlX19jXCIgKSA9PSBcIlNvbGQgVG9cIiApIHtcbiAgICAgICAgICAgICAgICBpZiAoIGUubW9kZWwuZ2V0KCBcIkN1c3RvbWVyX1R5cGVfX2NcIiApID09IFwiQmlsbCBUb1wiICkge1xuICAgICAgICAgICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJDdXN0b21lcl9fY1wiLCBmaWx0ZXI6IFwiUmVjb3JkVHlwZS5EZXZlbG9wZXJOYW1lICA9IFxcJ0JpbGxfVG9cXCdcIiB9KTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgaWYgKCBlLm1vZGVsLmdldCggXCJDdXN0b21lcl9UeXBlX19jXCIgKSA9PSBcIlNvbGQgVG9cIikge1xuICAgICAgICAgICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJDdXN0b21lcl9fY1wiLCBmaWx0ZXI6IFwiUmVjb3JkVHlwZS5EZXZlbG9wZXJOYW1lICA9IFxcJ1NvbGRfVG9cXCdcIiB9KTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cIkN1c3RvbWVyX19jXCJdJykuZGF0YSgna2VuZG9Mb29rdXAnKS5vcHRpb25zLmNyaXRlcmlhID0gbG9va3VwU2VhcmNoRmlsdGVycztcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICAvL0NvbW1lbnRpbmcgb3V0IGZvbGxvd2luZyBjb2RlIHNpbmNlIGl0IGRvZXNudCBhbGxvdyB0byBuYXZpZ2F0ZSB0byBhbnkgb3RoZXIgY29udHJvbC4gIFxuICAgICAgICAvKmlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W2RhdGEtcm9sZT1cImRhdGV0aW1lcGlja2VyXCJdJykubGVuZ3RoID4gMCApIHtcbiAgICAgICAgICAgdmFyIGRhdGVUaW1lUGlja2VyID0gICQoIGUuY29udGFpbmVyICkuZmluZCgnaW5wdXRbZGF0YS1yb2xlPVwiZGF0ZXRpbWVwaWNrZXJcIl0nKS5kYXRhKFwia2VuZG9EYXRlVGltZVBpY2tlclwiKTtcbiAgICAgICAgICAgZGF0ZVRpbWVQaWNrZXIuc2V0T3B0aW9ucyh7IGZvcm1hdDogXCJNL2QveXl5eVwiLCBwYXJzZUZvcm1hdHM6IFwiTS9kL3l5eXkgaGg6bW1cIn0pO1xuICAgICAgICB9Ki9cbiAgICAgICAgXG4gICAgfSApO1xuXG4gICAgZ3JpZC5iaW5kKCBcImNoYW5nZVwiLCBmdW5jdGlvbiggZSApIHtcbiAgICAgICAgICAgICAgICBcbiAgICAgICAgdmFyIGl0ZW0gPSB7IElkOiBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnByb21vdGlvblByZWZpeCB9O1xuXG4gICAgICAgIHZhciBzZWxlY3RlZEl0ZW0gPSB0aGlzLmRhdGFJdGVtKCB0aGlzLnNlbGVjdCgpICk7XG5cbiAgICAgICAgaWYgKCB0eXBlb2Ygc2VsZWN0ZWRJdGVtICE9PSBcInVuZGVmaW5lZFwiICkge1xuICAgICAgICAgICAgaWYgKCBzZWxlY3RlZEl0ZW0gIT09IG51bGwgKSB7XG4gICAgICAgICAgICAgICAgaXRlbSA9IHNlbGVjdGVkSXRlbTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIC8vICAgZmlyc3QgdGltZSAgICAgICAgICAgICAgICAgICBPUiAgIGNoYW5naW5nXG4gICAgICAgIGlmICggQWdyZWVtZW50Vmlld0NvbXBvbmVudC50aGVBZ3JlZW1lbnQuSWQgIT0gaXRlbS5JZCApIHtcblxuICAgICAgICAgICAgJC5lYWNoKCBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnByb21vQWN0aW9uQ29uZmlnLCBmdW5jdGlvbigpIHtcblxuICAgICAgICAgICAgICAgIHZhciByZWdleCA9IC9cXD9bYS16QS1aMC05PV0qLztcbiAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgdGhpcy5jb250ZW50ID0gdGhpcy5jb250ZW50ICYmIHRoaXMuY29udGVudC5yZXBsYWNlKCByZWdleCwgXCI/aWQ9XCIgKyBpdGVtLmlkICk7XG5cbiAgICAgICAgICAgIH0gKTtcblxuICAgICAgICAgICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC50aGVBZ3JlZW1lbnQgPSBpdGVtO1xuXG4gICAgICAgICAgICAkKCBcIiNwcHJvZFwiICkuZGF0YSggXCJrZW5kb1RyZWVMaXN0XCIgKS5kYXRhU291cmNlLnJlYWQoKTtcbiAgICAgICAgICAgICQoIFwiI3Bwcm9kXCIgKS5kYXRhKCBcImtlbmRvVHJlZUxpc3RcIiApLnJlZnJlc2goKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGUucHJldmVudERlZmF1bHQoKTtcbiAgICAgICAgfSBcbiAgICB9ICk7XG5cbiAgICAvL30pO1xufTtcbiIsIi8qIGdsb2JhbCBLZW5hbmR5RXJwICovXG4vKiBnbG9iYWwgQWdyZWVtZW50Vmlld0NvbXBvbmVudCAqL1xuLyogZ2xvYmFsIFZpc3VhbGZvcmNlICovXG52YXIgdXRpbGl0eSA9IHJlcXVpcmUoICcuLi91dGlscy9BZ3JlZW1lbnRWaWV3SGVscGVyJyApO1xucmVxdWlyZSggJy4uL3V0aWxzL0dyaWREZXRhaWxMaXN0JyApO1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKCBhZ3JlZW1lbnQgKSB7XG5cbiAgICB2YXIgYWdyZWVtZW50TGluZURhdGEgPSBmdW5jdGlvbigpIHtcblxuICAgICAgICBpZiAoIEFncmVlbWVudFZpZXdDb21wb25lbnQudGhlQWdyZWVtZW50LklkICE9PSAnJykge1xuICAgICAgICAgICAgYWdyZWVtZW50ID0gQWdyZWVtZW50Vmlld0NvbXBvbmVudC50aGVBZ3JlZW1lbnQ7XG4gICAgICAgIH1cblxuICAgICAgICB2YXIgZGVmZXJyZWQgPSAkLkRlZmVycmVkKCk7XG4gICAgICAgIFxuICAgICAgICBWaXN1YWxmb3JjZS5yZW1vdGluZy5NYW5hZ2VyLmludm9rZUFjdGlvbihcbiAgICAgICAgICAgIEFncmVlbWVudFZpZXdDb21wb25lbnQuZ2V0QWdyZWVtZW50TGluZURhdGEsXG4gICAgICAgICAgICBhZ3JlZW1lbnQuSWQsIFxuICAgICAgICAgICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hbGxGaWVsZHMsXG4gICAgICAgICAgICBmdW5jdGlvbiggcmVzdWx0LCBldmVudCApIHtcbiAgICAgICAgICAgICAgICBkZWZlcnJlZC5yZXNvbHZlKCByZXN1bHQsIGV2ZW50ICk7XG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgeyBlc2NhcGU6IGZhbHNlIH1cbiAgICAgICAgKTtcblxuICAgICAgICByZXR1cm4gZGVmZXJyZWQucHJvbWlzZSgpO1xuICAgIH07XG5cbiAgICB2YXIgZ3JpZCA9ICQoICcjcHByb2QnICkua2VuZG9HcmlkRGV0YWlsTGlzdCgge1xuICAgICAgICBzZWxlY3RhYmxlOiB0cnVlLFxuICAgICAgICBkZXRhaWxDb25maWc6IEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50TGluZXNHcmlkQ29uZmlnLFxuICAgICAgICBkZXRhaWxOYW1lc3BhY2U6IEFncmVlbWVudFZpZXdDb21wb25lbnQubmFtZXNwYWNlVVUsIFxuICAgICAgICBkZXRhaWxGaWVsZExpc3Q6IEFncmVlbWVudFZpZXdDb21wb25lbnQuYWdyZWVtZW50TGluZUZpZWxkTGlzdCxcbiAgICAgICAgZ2V0RGV0YWlsTGlzdEZ1bmN0aW9uOiBhZ3JlZW1lbnRMaW5lRGF0YSxcbiAgICAgICAgc2Nyb2xsYWJsZTogdHJ1ZSxcbiAgICAgICAgbG9va3VwU2VhcmNoQWN0aW9uOiBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50Lmxvb2t1cFNlYXJjaEFjdGlvbixcbiAgICAgICAgbG9va3VwU2VhcmNoRmlsdGVyczogQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hZ3JlZW1lbnRMaW5lTG9va3VwU2VhcmNoRmlsdGVycyxcbiAgICAgICAgZGV0YWlsVG9vbGJhckJ1dHRvbnM6IFtcbiAgICAgICAgICAgICAgICAgICAgeyBuYW1lOiBcImdyaWQtYWRkLWxpbmUtY29tbWFuZFwiLCB0ZXh0OlwiXCIsIHRlbXBsYXRlOiBcIjxpbnB1dCB0eXBlPSdidXR0b24nIHZhbHVlPSdBZGQgTmV3JyBjbGFzcz0nYnRuIGdyaWQtYWRkLWxpbmUtY29tbWFuZCcgLz5cIiB9LFxuICAgICAgICAgICAgICAgICAgICB7IG5hbWU6IFwiZ3JpZC1zYXZlLWxpbmUtY29tbWFuZFwiLCB0ZXh0OlwiXCIsIHRlbXBsYXRlOiBcIjxpbnB1dCB0eXBlPSdidXR0b24nIHZhbHVlPSdTYXZlIENoYW5nZXMnIGNsYXNzPSdidG4gZ3JpZC1zYXZlLWxpbmUtY29tbWFuZCcgLz5cIiB9LFxuICAgICAgICAgICAgICAgICAgICB7IG5hbWU6IFwiZ3JpZC1jYW5jZWwtbGluZS1jb21tYW5kXCIsIHRleHQ6XCJcIiwgdGVtcGxhdGU6IFwiPGlucHV0IHR5cGU9J2J1dHRvbicgdmFsdWU9J0NhbmNlbCBDaGFuZ2VzJyBjbGFzcz0nYnRuIGdyaWQtY2FuY2VsLWxpbmUtY29tbWFuZCcgLz5cIiB9LFxuICAgICAgICAgICAgICAgICAgICB7IG5hbWU6XCJmb3JtYXRMYWJlbFwiLCB0ZW1wbGF0ZTogXCI8bGFiZWwgc3R5bGU9J3BhZGRpbmctbGVmdDogNTBweDsgcGFkZGluZy1yaWdodDogNXB4Oyc+XCIgKyBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmFjdGlvbkxhYmVsICsgXCI6PC9sYWJlbD5cIiB9LFxuICAgICAgICAgICAgICAgICAgICB7IG5hbWU6XCJwcm9tb1Byb2RBY3Rpb25Ecm9wZG93blwiLCB0ZW1wbGF0ZTogXCI8aW5wdXQgaWQ9J3Byb21vUHJvZEFjdGlvbkRyb3Bkb3duJyBzdHlsZT0nd2lkdGg6IDIyNXB4OycgLz5cIiwgb3ZlcmZsb3c6IFwibmV2ZXJcIiB9LFxuICAgICAgICAgICAgICAgICAgICB7IG5hbWU6XCJwcm9tb1Byb2RBY3Rpb25Hb1wiLCB0ZXh0OkFncmVlbWVudFZpZXdDb21wb25lbnQuZ29MYWJlbCB9ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgIF0sICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgIGNoYW5nZTogZnVuY3Rpb24oIGUgKSB7XG4gICAgICAgICAgICB2YXIgaXRlbSA9IHsgSWQ6IEFncmVlbWVudFZpZXdDb21wb25lbnQucHJvbW9Qcm9kUHJlZml4IH07XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIHZhciBzZWxlY3RlZEl0ZW0gPSB0aGlzLmRhdGFJdGVtKCB0aGlzLnNlbGVjdCgpICk7ICBcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgaWYgKCB0eXBlb2Ygc2VsZWN0ZWRJdGVtICE9PSBcInVuZGVmaW5lZFwiICkge1xuICAgICAgICAgICAgICAgIGlmICggc2VsZWN0ZWRJdGVtICE9PSBudWxsICkge1xuXHRcdFx0XHRcdFx0aXRlbSA9IHNlbGVjdGVkSXRlbTsgXHQgICAgICAgICAgICAgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSAgICAgXG4gICAgICAgICAgICBcbiAgICAgICAgICAgIGlmICggQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcm9tb3RlZFByb2QgIT0gaXRlbSApIHsgICAgICAgICAgIC8vICBzZWUgaWYgdGhpcyByZWFsbHkgY2hhbmdlZCA/XG4gICAgICAgICAgICAgICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcm9tb3RlZFByb2QgPSBpdGVtO1xuICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgICAgICQuZWFjaCggQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcm9tb1Byb2RBY3Rpb25Db25maWcsIGZ1bmN0aW9uKCkge1xuXG4gICAgICAgICAgICAgICAgICAgIHZhciByZWdleCA9IC89W2EtekEtWjAtOV0qLztcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5jb250ZW50ID0gdGhpcy5jb250ZW50ICYmIHRoaXMuY29udGVudC5yZXBsYWNlKCByZWdleCwgJz0nICsgaXRlbS5pZCApO1xuICAgICAgICAgICAgICAgICAgICBcbiAgICAgICAgICAgICAgICB9ICk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9ICkuZGF0YSggJ2tlbmRvR3JpZERldGFpbExpc3QnICk7XG4gICAgXG4gICAgLy9hZ3JlZW1lbnRMaW5lRGF0YS5kb25lKGZ1bmN0aW9uKHJlc3VsdCwgZXZlbnQpe1xuICAgIHV0aWxpdHkuZWxlbWVudEluaXQoIGdyaWQsIGZhbHNlICk7XG4gICAgZ3JpZC5iaW5kKCAnZWRpdCcsIGZ1bmN0aW9uKCBlICkge1xuICAgICAgICBpZiAoIGUubW9kZWwuaXNOZXcoKSApIHsgICAgICAgICAgICAgICAgICAgICAvLyBpZiByb3cgaXMgbmV3LCB0aGVuIHNldCBkZWZhdWx0c1xuXG4gICAgICAgICAgICBlLm1vZGVsLnNldCggJ0FncmVlbWVudF9fYycsIGFncmVlbWVudC5JZCApO1xuICAgICAgICAgICAgZS5tb2RlbC5zZXQoICdTdGFydF9EYXRlX19jJywgS2VuYW5keUVycC5QYXJzZVNGRENEYXRlKCBhZ3JlZW1lbnQuU3RhcnRfRGF0ZV9fYyApICk7XG4gICAgICAgICAgICBlLm1vZGVsLnNldCggJ0VuZF9EYXRlX19jJywgS2VuYW5keUVycC5QYXJzZVNGRENEYXRlKCBhZ3JlZW1lbnQuRW5kX0RhdGVfX2MgKSApO1xuXG4gICAgICAgICAgICAvLyBubyBlZGl0IG9uIHRoaWFzIGxvb2t1cFxuICAgICAgICAgICAgLy8gJC5wcm94eShLZW5hbmR5RXJwLktlbmRvR3JpZEFjdGlvbnMuRWRpdCwgeyByZWZlcmVuY2VGaWVsZHM6IFsnUHJvZHVjdF9IaWVyYXJjaHlfX2MnXSB9KVxuICAgICAgICB9XG4gICAgfSApO1xuXG4gICAgLy99KTsgICBcbn07XG4iLCIvKiBnbG9iYWwgVmlzdWFsZm9yY2UgKi9cbi8qIGdsb2JhbCBleHBhbmRlZFJvd3MgKi9cbi8qIGdsb2JhbCBPTlJFQURTVUNDRVNTICovXG4vKiBnbG9iYWwgT05SRUFERkFJTFVSRSAqL1xuLyogZ2xvYmFsIEFncmVlbWVudFZpZXdDb21wb25lbnQgKi9cbi8qIGdsb2JhbCBKU09OVXRpbHMgKi9cbi8qIGdsb2JhbCBLZW5hbmR5RXJwICovXG4vKiBnbG9iYWwgU2VyaWFsaXplciAqL1xuLy8vIDxyZWZlcmVuY2UgcGF0aD1cIi4uLy4uL3R5cGluZ3MvdHNkLmQudHNcIiAvPlxudmFyIHV0aWxpdHkgPSByZXF1aXJlKCBcIi4uL3V0aWxzL0FncmVlbWVudFZpZXdIZWxwZXJcIiApO1xudmFyIHNhdmUgPSByZXF1aXJlKCBcIi4uL2FjdGlvbnMvVHJlZUxpc3RTYXZlQWN0aW9uXCIgKTtcblxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiggYWdyZWVtZW50ICkge1xuICAgIHZhciBhZ3JlZW1lbnRMaW5lRmllbGRMaXN0UGFyc2VkID0gdXRpbGl0eS5nZXRGaWVsZExpc3QoQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hZ3JlZW1lbnRMaW5lRmllbGRMaXN0KTtcblxuICAgIHZhciBhZ3JlZW1lbnRMaW5lRGF0ZUZpZWxkc1BhcnNlZCA9IEpTT05VdGlscy5QYXJzZShcbiAgICAgICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hZ3JlZW1lbnRMaW5lRGF0ZUZpZWxkcygpICk7XG5cbiAgICB2YXIgX25lc3RlZEZpZWxkcyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXROZXN0ZWRGaWVsZHMoXG4gICAgICAgIGFncmVlbWVudExpbmVGaWVsZExpc3RQYXJzZWQgKTsgLy8gZ2V0IHRoZSBsaXN0IG9mIG5lc3RlZCBmaWVsZHNcblxuICAgIHZhciBhZ3JlZW1lbnRMaW5lRGF0YSA9IGZ1bmN0aW9uKCkge1xuXG4gICAgICAgIGlmICggQWdyZWVtZW50Vmlld0NvbXBvbmVudC50aGVBZ3JlZW1lbnQuSWQgIT09IFwiXCIgKSAge1xuICAgICAgICAgICAgYWdyZWVtZW50ID0gQWdyZWVtZW50Vmlld0NvbXBvbmVudC50aGVBZ3JlZW1lbnQ7XG4gICAgICAgIH1cblxuICAgICAgICB2YXIgZGVmZXJyZWQgPSAkLkRlZmVycmVkKCk7XG5cbiAgICAgICAgVmlzdWFsZm9yY2UucmVtb3RpbmcuTWFuYWdlci5pbnZva2VBY3Rpb24oXG4gICAgICAgICAgICBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmdldEFncmVlbWVudExpbmVEYXRhLFxuICAgICAgICAgICAgYWdyZWVtZW50LklkLFxuICAgICAgICAgICAgQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hbGxGaWVsZHMsXG4gICAgICAgICAgICBmdW5jdGlvbiggcmVzdWx0LCBldmVudCApIHtcbiAgICAgICAgICAgICAgICBkZWZlcnJlZC5yZXNvbHZlKCByZXN1bHQsIGV2ZW50ICk7XG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgeyBlc2NhcGU6IGZhbHNlIH1cbiAgICAgICAgKTtcblxuICAgICAgICByZXR1cm4gZGVmZXJyZWQucHJvbWlzZSgpO1xuICAgIH07XG5cbiAgICB2YXIgY29sdW1ucyA9IEtlbmFuZHlFcnAuS2VuZG9HcmlkT3B0aW9ucy5HZXRDb2x1bW5zKFxuICAgICAgICBhZ3JlZW1lbnRMaW5lRmllbGRMaXN0UGFyc2VkLFxuICAgICAgICB7IGxvb2t1cFNlYXJjaEFjdGlvbjogQWdyZWVtZW50Vmlld0NvbXBvbmVudC5sb29rdXBTZWFyY2hBY3Rpb24sXG4gICAgICAgICAgICBidXR0b25zOiBudWxsLFxuICAgICAgICAgICAgbG9va3VwU2VhcmNoRmlsdGVyczogQWdyZWVtZW50Vmlld0NvbXBvbmVudC5hZ3JlZW1lbnRMaW5lTG9va3VwU2VhcmNoRmlsdGVycyxcbiAgICAgICAgICAgIGFsbG93TWFzc0RlbGV0ZTogbnVsbCxcbiAgICAgICAgICAgIHZhbGlkYXRlT25CbHVyOiBudWxsXG4gICAgICAgIH0gKTtcbiAgICAgICAgXG4gICAgY29sdW1ucy5zaGlmdCggMCApO1xuICAgIFxuICAgIGlmKGFncmVlbWVudC5TdGF0dXNfX2MgPT0gXCJBcHByb3ZlZFwiKSB7XG4gICAgICAgIGNvbHVtbnMudW5zaGlmdCggeyBjb21tYW5kOiBbIFwiZWRpdFwiIF0sXG4gICAgICAgICAgICAgICAgICAgIGF0dHJpYnV0ZXM6IHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBcInRleHQtYWxpZ246IGNlbnRlcjtcIixcbiAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgd2lkdGg6IFwiMTAwcHhcIixcbiAgICAgICAgICAgICAgICB9ICk7XG4gICAgICAgIGNvbHVtbnMucHVzaCggeyBjb21tYW5kOiBbIFwiZWRpdFwiIF0sXG4gICAgICAgICAgICAgICAgICAgIGF0dHJpYnV0ZXM6IHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHN0eWxlOiBcInRleHQtYWxpZ246IGNlbnRlcjtcIixcbiAgICAgICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICAgICAgd2lkdGg6IFwiMTAwcHhcIlxuICAgICAgICAgICAgICAgIH0gKTtcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICAgIGNvbHVtbnMudW5zaGlmdCggeyBjb21tYW5kOiBbIFwiZWRpdFwiLCBcImRlc3Ryb3lcIiBdLFxuICAgICAgICAgICAgICAgICAgICBhdHRyaWJ1dGVzOiB7XG4gICAgICAgICAgICAgICAgICAgICAgICBzdHlsZTogXCJ0ZXh0LWFsaWduOiBjZW50ZXI7XCIsXG4gICAgICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgICAgIHdpZHRoOiBcIjEwMHB4XCJcbiAgICAgICAgICAgICAgICB9ICk7XG4gICAgICAgICBjb2x1bW5zLnB1c2goIHsgY29tbWFuZDogWyBcImVkaXRcIiwgXCJkZXN0cm95XCIgXSxcbiAgICAgICAgICAgICAgICAgICAgYXR0cmlidXRlczoge1xuICAgICAgICAgICAgICAgICAgICAgICAgc3R5bGU6IFwidGV4dC1hbGlnbjogY2VudGVyO1wiLFxuICAgICAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgICAgICB3aWR0aDogXCIxMDBweFwiXG4gICAgICAgICAgICAgICAgfSApO1xuICAgIH1cbiAgICBcbiAgICBjb2x1bW5zWzFdLmV4cGFuZGFibGUgPSB0cnVlO1xuICAgIFxuICAgLy9IYWNrIGZvciBoZWFkZXIgZm9ybWF0dGluZyBvbiBjb2x1bW5zIG1pc3NpbmcgaXRcbiAgICQuZWFjaCggY29sdW1ucywgZnVuY3Rpb24oIGluZGV4LCBpdGVtICkge1xuICAgICAgIGlmICggaXRlbS5oZWFkZXJBdHRyaWJ1dGVzICkge1xuICAgICAgICAgICBpdGVtLmhlYWRlckF0dHJpYnV0ZXMuY2xhc3MgPSBpdGVtLmhlYWRlckF0dHJpYnV0ZXMuY2xhc3MgKyBcIiBrLWhlYWRlclwiO1xuICAgICAgIH1cbiAgICAgICBpZiAoIGl0ZW0uZmllbGQgIT09IFwiXCIgKSB7XG4gICAgICAgICAgIGl0ZW0uZmlsdGVyYWJsZSA9IHRydWU7XG4gICAgICAgfVxuICAgICAgIGlmICggaXRlbS5maWVsZCA9PSAnYWdsLk5hbWUnKSB7XG4gICAgICAgICAgIGl0ZW0udGVtcGxhdGUgPSBrZW5kby50ZW1wbGF0ZSgnPGEgdGFyZ2V0PVwiX3RvcFwiIGhyZWY9XCIvIz1hZ2wuSWQjXCIgLz4jPSBhZ2wuTmFtZSAjPC9hPicpO1xuICAgICAgIH1cbiAgICAgICBpZiAoIGl0ZW0uZmllbGQgPT0gXCJhZ2wuVG90YWxfVmFsdWVfRkNfX2NcIiApIHtcbiAgICAgICAgICAgaXRlbS50ZW1wbGF0ZSA9IFwiIz0gKGFnbC5Ub3RhbF9WYWx1ZV9GQ19fYyA9PT0gbnVsbCkgPyAnICcgOiBhZ2wuVG90YWxfVmFsdWVfRkNfX2MgI1wiO1xuICAgICAgIH1cbiAgICAgICBpZiAoIGl0ZW0uZmllbGQgPT0gXCJhZ2wuTWFyZ2luX19jXCIgKSB7XG4gICAgICAgICAgIGl0ZW0udGVtcGxhdGUgPSBcIiM9IChhZ2wuTWFyZ2luX19jID09PSBudWxsKSA/ICcgJyA6IGFnbC5NYXJnaW5fX2MgI1wiO1xuICAgICAgIH1cbiAgICAgICBpZiAoIGl0ZW0uZmllbGQgPT0gXCJhZ2wuR3JvdXBfTnVtYmVyX19jXCIgKSB7XG4gICAgICAgICAgIGl0ZW0udGVtcGxhdGUgPSBcIiM9IChhZ2wuR3JvdXBfTnVtYmVyX19jID09PSBudWxsKSA/ICcgJyA6IGFnbC5Hcm91cF9OdW1iZXJfX2MgI1wiO1xuICAgICAgIH1cbiAgICAgICBpZiAoIGl0ZW0uZmllbGQgPT0gXCJhZ2wuTWFyZ2luX0Nvc3RfX2NcIiApIHtcbiAgICAgICAgICAgaXRlbS50ZW1wbGF0ZSA9IFwiIz0gKGFnbC5NYXJnaW5fQ29zdF9fYyA9PT0gbnVsbCkgPyAnICcgOiBhZ2wuTWFyZ2luX0Nvc3RfX2MgI1wiO1xuICAgICAgIH1cbiAgICAgICBpZiAoIGl0ZW0uZmllbGQgPT0gXCJhZ2wuT2NjdXJlbmNlX0NvdW50X19jXCIgKSB7XG4gICAgICAgICAgIGl0ZW0udGVtcGxhdGUgPSBcIiM9IChhZ2wuT2NjdXJlbmNlX0NvdW50X19jPT09IG51bGwpID8gJyAnIDogYWdsLk9jY3VyZW5jZV9Db3VudF9fYyAjXCI7XG4gICAgICAgfVxuICAgICAgIGlmICggaXRlbS5maWVsZCA9PSBcImFnbC5Qcm9kdWN0X19jXCIgKSB7XG4gICAgICAgICAgIGl0ZW0uaGVhZGVyQXR0cmlidXRlcyA9IHtcbiAgICAgICAgICAgICAgIHN0eWxlOiBcIm1pbi13aWR0aDogMTUwcHhcIlxuICAgICAgICAgICB9XG4gICAgICAgfVxuICAgICAgIGlmICggaXRlbS5maWVsZCA9PSAnYWdsLlZhcmlhdGlvbl9QZXJjZW50YWdlX19jJyl7XG4gICAgICAgICAgIGl0ZW0udGVtcGxhdGUgICA9IFwiI2lmKGFnbC5BZ3JlZW1lbnRfUHJpY2VfX2MgPj0gYWdsLkxpc3RfUHJpY2VfX2MpeyMgPHNwYW4gY2xhc3M9J2FncmVlbWVudGxpbmV2YXJpYXRpb25wZXJjZW50YWdlbGVzcyc+Iz1rZW5kby50b1N0cmluZyhhZ2wuVmFyaWF0aW9uX1BlcmNlbnRhZ2VfX2MsICcwLjAwJykjPC9zcGFuPiAjfSBlbHNlIGlmIChhZ2wuVmFyaWF0aW9uX1BlcmNlbnRhZ2VfX2MgPD0gQWdyZWVtZW50Vmlld0NvbXBvbmVudC50aHJlc2hvbGRwZXJjZW50YWdldmFsdWUpeyMgIDxzcGFuIGNsYXNzPSdhZ3JlZW1lbnRsaW5ldmFyaWF0aW9ucGVyY2VudGFnZW1vZGVyYXRlJz4jPWtlbmRvLnRvU3RyaW5nKGFnbC5WYXJpYXRpb25fUGVyY2VudGFnZV9fYywgJzAuMDAnKSAjIDwvc3Bhbj4jfSBlbHNlIHsjIDxzcGFuIGNsYXNzPSdhZ3JlZW1lbnRsaW5ldmFyaWF0aW9ucGVyY2VudGFnZW1vcmUnPiM9a2VuZG8udG9TdHJpbmcoYWdsLlZhcmlhdGlvbl9QZXJjZW50YWdlX19jLCAnMC4wMCcpICMgPC9zcGFuPiN9IyBcIjtcbiAgICAgICB9ICAgICAgIFxuICAgICAgIGlmICggaXRlbS5mb3JtYXQgPT0gXCJ7MDpNL2QveXl5eSBoOm1tIHR0fVwiKSB7XG4gICAgICAgICAgIGl0ZW0uZm9ybWF0ID0gXCJ7MDpNL2QveXl5eX1cIlxuICAgICAgIH1cbiAgICAgICBcbiAgIH0gKTtcbiAgICBcbiAgIFxuICAgIHZhciBmaWVsZHMgPSBLZW5hbmR5RXJwLktlbmRvR3JpZE9wdGlvbnMuR2V0RmllbGRzKCBhZ3JlZW1lbnRMaW5lRmllbGRMaXN0UGFyc2VkICk7XG4gICAgJC5lYWNoKCBmaWVsZHMsIGZ1bmN0aW9uKCBpLCB2ICkge1xuICAgICAgICBkZWxldGUgdi52YWxpZGF0aW9uO1xuICAgIH0gKTtcbiAgICBmaWVsZHMucGFyZW50SWQgPSB7IFwiZmllbGRcIjogXCJhZ2wuUGFyZW50X0FncmVlbWVudF9MaW5lX19jXCIsIFwibnVsbGFibGVcIjogdHJ1ZSB9O1xuXG4gICAgdmFyIG1vZGVsID0ge307XG4gICAgbW9kZWwuaWQgPSBcImFnbC5JZFwiO1xuICAgIG1vZGVsLmZpZWxkcyA9IGZpZWxkcztcbiAgICBtb2RlbC5leHBhbmRlZCA9IGZhbHNlO1xuXG4gICAgdmFyIGRhdGFTb3VyY2UgPSBuZXcga2VuZG8uZGF0YS5UcmVlTGlzdERhdGFTb3VyY2UoIHtcbiAgICAgICAgdHJhbnNwb3J0OiB7XG4gICAgICAgICAgICByZWFkOiBmdW5jdGlvbiggb3B0aW9ucyApIHtcbiAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLkJsb2NrVUkoIFwiI3Bwcm9kXCIgKTtcblxuICAgICAgICAgICAgICAgIHZhciBwcm9taXNlID0gYWdyZWVtZW50TGluZURhdGEoIG9wdGlvbnMuZGF0YS5yZWFkT3B0aW9ucyApO1xuICAgICAgICAgICAgICAgIHByb21pc2UuZG9uZSggZnVuY3Rpb24oIHJlc3VsdCwgZXZlbnQgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBLZW5hbmR5RXJwLlVuQmxvY2tVSSggXCIjcHByb2RcIiApO1xuICAgICAgICAgICAgICAgICAgICAgICAgLy9zZXR0aW5nIGFncmVlbWVudGxpbmVzIGdyaWQgd2lkdGggYXMgcGVyIHBhcmVudCBjb3RhaW5lciBvdXRlcldpZHRoXG4gICAgICAgICAgICAgICAgICAgICAgICAkKCcjcHByb2QnKS53aWR0aCgkKCcuZ3JpZC1jb250YWluZXInKS53aWR0aCgpKTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKCBldmVudC50eXBlID09IFwiZXhjZXB0aW9uXCIgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgS2VuYW5keUVycC5BbGVydCggXCJBbiBlcnJvciBvY2N1cnJlZCB3aGlsZSBwcm9jZXNzaW5nIHlvdXIgcmVxdWVzdC4gXCIgK1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcIlBsZWFzZSBjb250YWN0IHN1cHBvcnRcIiApO1xuXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLy8gdHJpZ2dlciBvbnJlYWRmYWlsdXJlXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgJCggXCIjcHByb2RcIiApLnRyaWdnZXIoIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZTogT05SRUFERkFJTFVSRSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVzdWx0OiByZXN1bHQsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGV2ZW50OiBldmVudFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0gKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgS2VuYW5keUVycC5DbGVhbk5hbWVzcGFjZSggcmVzdWx0LnJlY29yZHMsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIEFncmVlbWVudFZpZXdDb21wb25lbnQubmFtZXNwYWNlVVUgKTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9wdGlvbnMuc3VjY2VzcyggcmVzdWx0LnJlY29yZHMgKTtcblxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIC8vIHRyaWdnZXIgb25yZWFkc3VjY2Vzc1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICQoIFwiI3Bwcm9kXCIgKS50cmlnZ2VyKCB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGU6IE9OUkVBRFNVQ0NFU1MsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlc3VsdDogcmVzdWx0LFxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBldmVudDogZXZlbnRcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9ICk7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH0gKTtcbiAgICAgICAgICAgIH0sXG5cbiAgICAgICAgICAgIHVwZGF0ZTogZnVuY3Rpb24oIG9wdGlvbnMgKSB7XG4gICAgICAgICAgICAgICAgc2F2ZSggb3B0aW9ucywgYWdyZWVtZW50TGluZURhdGVGaWVsZHNQYXJzZWQsIFwidXBkYXRlXCIgKTtcbiAgICAgICAgICAgIH0sXG5cbiAgICAgICAgICAgIGNyZWF0ZTogZnVuY3Rpb24oIG9wdGlvbnMgKSB7XG4gICAgICAgICAgICAgICAgc2F2ZSggb3B0aW9ucywgYWdyZWVtZW50TGluZURhdGVGaWVsZHNQYXJzZWQsIFwiY3JlYXRlXCIgKTtcbiAgICAgICAgICAgIH0sXG5cbiAgICAgICAgICAgIGRlc3Ryb3k6IGZ1bmN0aW9uKCBvcHRpb25zICkge1xuICAgICAgICAgICAgICAgIHNhdmUoIG9wdGlvbnMsIGFncmVlbWVudExpbmVEYXRlRmllbGRzUGFyc2VkLCBcImRlbGV0ZVwiICk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIGJhdGNoOiB0cnVlLFxuICAgICAgICBzY2hlbWE6IHtcbiAgICAgICAgICAgIG1vZGVsOiBtb2RlbCxcbiAgICAgICAgICAgIHBhcnNlOmZ1bmN0aW9uKCByZXNwb25zZSApIHtcbiAgICAgICAgICAgICAgICAkLmVhY2goIHJlc3BvbnNlLCBmdW5jdGlvbiggaWR4LCBpdGVtICkge1xuICAgICAgICAgICAgICAgICAgICBpZiAoIGl0ZW0uYWdsLlBhcmVudF9BZ3JlZW1lbnRfTGluZV9fYyA9PT0gdW5kZWZpbmVkICkge1xuXG4vLyAgICAgICAgICAgICAgICAgICAgICAgIGl0ZW0ucGFyZW50SWQgPSBudWxsO1xuICAgICAgICAgICAgICAgICAgICAgICAgaXRlbS5hZ2wuUGFyZW50X0FncmVlbWVudF9MaW5lX19jID0gbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgICAgICAgIGl0ZW0uaWQgPSBpdGVtLmFnbC5JZDtcbiAgICAgICAgICAgICAgICAgICAgaXRlbSA9IFNlcmlhbGl6ZXIuSW5jbHVkZU51bGxzKCBpdGVtLCB7IGZpZWxkczogX25lc3RlZEZpZWxkcyB9ICk7XG4gICAgICAgICAgICAgICAgICAgIGl0ZW0gPSBTZXJpYWxpemVyLkNvbnZlcnRGcm9tU0ZEQ0RhdGUoIGl0ZW0sIHsgZGF0ZUZpZWxkczogYWdyZWVtZW50TGluZURhdGVGaWVsZHNQYXJzZWQgfSApO1xuICAgICAgICAgICAgICAgIH0gKTtcblxuICAgICAgICAgICAgICAgIHJldHVybiByZXNwb25zZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICAgICAgZmlsdGVyOiBbXG4gICAgICAgICAgICB7IGZpZWxkOiBcImFnbC5SZXZpc2lvbl9TdGF0dXNfX2NcIiwgb3BlcmF0b3I6IFwibmVxXCIsIHZhbHVlOiBcIlJlamVjdGVkXCJ9LFxuICAgICAgICAgICAgeyBmaWVsZDogXCJhZ2wuUmV2aXNpb25fU3RhdHVzX19jXCIsIG9wZXJhdG9yOiBcIm5lcVwiLCB2YWx1ZTogXCJSZXZpc2VkXCJ9XG4gICAgICAgIF1cbiAgICB9ICk7XG5cbiAgICB2YXIgdG9vbEJhckJ1dHRvbnMgPSBcIjxidXR0b24gZGF0YS1jb21tYW5kPVxcXCJjcmVhdGVcXFwiIGNsYXNzPVxcXCJrLWJ1dHRvbiBrLWJ1dHRvbi1pY29udGV4dCBrLWdyaWQtYWRkXFxcIj48c3BhbiBjbGFzcz1cXFwiay1pY29uIGstYWRkXFxcIj48L3NwYW4+QWRkIG5ldyByZWNvcmQ8L2J1dHRvbj5cIiArXG4gICAgXCI8bGFiZWwgc3R5bGU9J3BhZGRpbmctbGVmdDogNTBweDsgcGFkZGluZy1yaWdodDogNXB4Oyc+XCIgKyBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LmFjdGlvbkxhYmVsICsgXCI6PC9sYWJlbD5cIiArXG4gICAgXCI8aW5wdXQgaWQ9J3Byb21vUHJvZEFjdGlvbkRyb3Bkb3duJyBzdHlsZT0nd2lkdGg6IDIyNXB4OycgLz5cIiArXG4gICAgXCI8YSBjbGFzcz1cXFwiay1idXR0b24gay1idXR0b24taWNvbnRleHQgay1ncmlkLXByb21vUHJvZEFjdGlvbkdvXFxcIiBocmVmPVxcXCJcXFxcI1xcXCI+R288L2E+XCIgKyBcbiAgICBcIjxsYWJlbCBzdHlsZT0ncGFkZGluZy1sZWZ0OiA1MHB4OyBwYWRkaW5nLXJpZ2h0OiA1cHg7Jz5WaWV3czo8L2xhYmVsPlwiICsgXG4gICAgXCI8aW5wdXQgY2xhc3M9J2dyaWQtdmlldy1vcHRpb25zJyAvPlwiXG4gICAgO1xuXG4gICAgdmFyIHRyZWVMaXN0ID0gJCggXCIjcHByb2RcIiApLndpZHRoKCAkKCAnI21haW5wYWdlJykud2lkdGgoKSkua2VuZG9UcmVlTGlzdCgge1xuICAgICAgICBkYXRhU291cmNlOiBkYXRhU291cmNlLFxuICAgICAgICB0b29sYmFyOiB0b29sQmFyQnV0dG9ucyxcbiAgICAgICAgZWRpdGFibGU6IHRydWUsXG4gICAgICAgIHNlbGVjdGFibGU6IHRydWUsXG4gICAgICAgIHJlc2l6YWJsZTogdHJ1ZSxcbiAgICAgICAgc2Nyb2xsYWJsZTogdHJ1ZSxcbiAgICAgICAgZmlsdGVyYWJsZTogdHJ1ZSxcbiAgICAgICAgY29sdW1uTWVudTogdHJ1ZSxcbiAgICAgICAgcmVvcmRlcmFibGU6IHRydWUsXG4gICAgICAgIGNvbHVtbnM6IGNvbHVtbnMsXG4gICAgICAgIG5hdmlnYXRhYmxlOiB0cnVlLFxuICAgIFx0cGFnZWFibGU6IHsgXG4gICAgXHRcdGlucHV0OiB0cnVlLFxuICAgICAgICAgICAgbnVtZXJpYzogZmFsc2UsXG4gICAgXHRcdHBhZ2VTaXplczogS2VuYW5keUVycC5LZW5kb0dyaWRPcHRpb25zLlBhZ2VTaXplcyxcbiAgICBcdFx0bWVzc2FnZXM6IHtcbiAgICBcdFx0XHRkaXNwbGF5OiAnezB9IC0gezF9IG9mIHsyfSByZWNvcmRzJyxcbiAgICBcdFx0XHRlbXB0eTogJycsXG4gICAgXHRcdFx0aXRlbXNQZXJQYWdlOiAncmVjb3JkcyBwZXIgcGFnZSdcbiAgICBcdFx0fVxuXHRcdH0sXG4gICAgICAgIGVkaXQ6IGZ1bmN0aW9uKCBlICkge1xuXG4gICAgICAgICAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgICAgICAgICB2YXIgZGF0YSA9IHRoaXMuZGF0YVNvdXJjZTtcbiAgICAgICAgICAgIHZhciBvcHRpb25zID0gdGhpcy5kYXRhU291cmNlLm9wdGlvbnM7XG5cbiAgICAgICAgICAgIGlmICggZS5tb2RlbC5pc05ldygpIHx8IGUubW9kZWwuZ2V0KFwiaWRcIikgPT0gbnVsbCApIHsgICAgICAgICAgICAgICAgICAgICAvLyBpZiByb3cgaXMgbmV3LCB0aGVuIHNldCBkZWZhdWx0c1xuICAgICAgICAgICAgICAgIGUubW9kZWwuYWdsLnNldCggXCJBZ3JlZW1lbnRfX2NcIiwgYWdyZWVtZW50LklkICk7XG4gICAgICAgICAgICAgICAgZS5tb2RlbC5hZ2wuc2V0KCBcIlN0YXJ0X0RhdGVfX2NcIiwgS2VuYW5keUVycC5QYXJzZVNGRENEYXRlKCBhZ3JlZW1lbnQuU3RhcnRfRGF0ZV9fYyApICk7XG4gICAgICAgICAgICAgICAgZS5tb2RlbC5hZ2wuc2V0KCBcIkVuZF9EYXRlX19jXCIsIEtlbmFuZHlFcnAuUGFyc2VTRkRDRGF0ZSggYWdyZWVtZW50LkVuZF9EYXRlX19jICkgKTtcbiAgICAgICAgICAgICAgICBlLm1vZGVsLmFnbC5zZXQoIFwiTGlzdF9QcmljZV9fY1wiLCBudWxsICk7XG4gICAgICAgICAgICAgICAgZS5tb2RlbC5hZ2wuc2V0KCBcIkFncmVlbWVudF9QcmljZV9fY1wiLCBudWxsICk7XG4gICAgICAgICAgICAgICAgLy9LTkRZLTEzODg2IFVuYWJsZSB0byBhZGQgYWdyZWVtZW50IGxpbmUgLSBEdWUgdG8gZGF0ZSBmaWVsZCBiZWluZyBwYXNzZWQgYXMgbnVsbFxuICAgICAgICAgICAgICAgIC8vZS5tb2RlbC5hZ2wuc2V0KCBcIlJldmlzaW9uX0FwcHJvdmFsX2RhdGVfX2NcIiwgbnVsbCApOyBjb21tZW50aW5nIHRoaXMgb3V0IHRvIHByZXZlbnQgVUkgZXJyb3JcbiAgICAgICAgICAgICAgICBlLm1vZGVsLmFnbC5zZXQoIFwiUmV2aXNlZF9fY1wiLCBmYWxzZSApO1xuICAgICAgICAgICAgICAgIGUubW9kZWwuYWdsLnNldCggXCJDdXN0b21lcl9QT19fY1wiLCBhZ3JlZW1lbnQuQ3VzdG9tZXJfUE9fX2MpO1xuICAgICAgICAgICAgICAgIGUubW9kZWwuYWdsLnNldCggXCJQcm9kdWN0X1R5cGVfX2NcIiwgJ1Byb2R1Y3QnKTtcbiAgICAgICAgICAgICAgICBpZihhZ3JlZW1lbnQuQWdyZWVtZW50X1R5cGVfX2MgPT0gJ1NhbGVzIEFncmVlbWVudCcpe1xuICAgICAgICAgICAgICAgICAgICBlLm1vZGVsLmFnbC5zZXQoIFwiUHJpY2VfVHlwZV9fY1wiLCAnU2FsZXMnKTtcbiAgICAgICAgICAgICAgICB9ZWxzZSBpZihhZ3JlZW1lbnQuQWdyZWVtZW50X1R5cGVfX2MgPT0gJ1JlbnRhbCcpe1xuICAgICAgICAgICAgICAgICAgICBlLm1vZGVsLmFnbC5zZXQoIFwiUHJpY2VfVHlwZV9fY1wiLCAnUmVjdXJyaW5nJyk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgJC5lYWNoKGRhdGEub3B0aW9ucy5zY2hlbWEubW9kZWwuZmllbGRzLCBmdW5jdGlvbihpbmRleCwgaXRlbSkge1xuICAgICAgICAgICAgICAgIGlmKGl0ZW0gJiYgaXRlbS50eXBlID09ICdib29sZWFuJyl7XG4gICAgICAgICAgICAgICAgICAgIGUubW9kZWwuZ2V0KGluZGV4KSA/IGUubW9kZWwuZ2V0KGluZGV4KSA6IGUubW9kZWwuc2V0KGluZGV4LCBmYWxzZSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgICQoZS5jb250YWluZXIpLmZpbmQoJ2lucHV0W25hbWU9XCJhZ2wuUHJvZHVjdF9SZWZlcmVuY2VfX2NcIl0nKS5iaW5kKCdibHVyJyxcblxuICAgICAgICAgICAgJC5wcm94eSh1dGlsaXR5LkdldEFHTGluZURldGFpbHNGcm9tUHJvZHVjdFJlZiwgeyBncmlkOiB0cmVlTGlzdCxcblxuICAgICAgICAgICAgICAgIG9wdGlvbnM6IHsgXG4gICAgICAgICAgICAgICAgICAgIHBhcmVudEdyaWQ6ICQoJyNwcm9tb3Rpb25zJykuZGF0YSgna2VuZG9HcmlkQWN0aW9uTGlzdCcpLmRhdGFTb3VyY2UuZGF0YSgpWzBdXG5cbiAgICAgICAgICAgICAgICB9LFxuXG4gICAgICAgICAgICAgICAgdHJpZ2dlcjogJ2JsdXInLFxuXG4gICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgICAkKGUuY29udGFpbmVyKS5maW5kKCdpbnB1dFtuYW1lPVwiYWdsLlByb2R1Y3RfX2NcIl0nKS5iaW5kKCdibHVyJyxcblxuICAgICAgICAgICAgJC5wcm94eSh1dGlsaXR5LkdldEFHTGluZURldGFpbHNGcm9tUHJvZHVjdCwgeyBncmlkOiB0cmVlTGlzdCxcblxuICAgICAgICAgICAgICAgIG9wdGlvbnM6IHsgXG4gICAgICAgICAgICAgICAgICAgIHBhcmVudEdyaWQ6ICQoJyNwcm9tb3Rpb25zJykuZGF0YSgna2VuZG9HcmlkQWN0aW9uTGlzdCcpLmRhdGFTb3VyY2UuZGF0YSgpWzBdXG5cbiAgICAgICAgICAgICAgICB9LFxuXG4gICAgICAgICAgICAgICAgdHJpZ2dlcjogJ2JsdXInLFxuXG4gICAgICAgICAgICAgfSlcbiAgICAgICAgICAgICk7XG5cblxuICAgICAgICAgICAgaWYoICQoIGUuY29udGFpbmVyICkuZmluZCgnaW5wdXRbbmFtZT1cImFnbC5Qcm9kdWN0X19jXCJdJykubGVuZ3RoID4gMCApIHtcbiAgICAgICAgICAgICAgICB2YXIgbG9va3VwU2VhcmNoRmlsdGVycyA9IFtdO1xuICAgICAgICAgICAgICAgIGxvb2t1cFNlYXJjaEZpbHRlcnMucHVzaCgge2ZpZWxkOiBcImFnbC5Qcm9kdWN0X19jXCIsIGZpbHRlcjogXCIgQ29tcGFueV9fYyA9IFxcJ1wiICsgYWdyZWVtZW50LkNvbXBhbnlfX2MgKyBcIlxcJ1wifSk7XG4gICAgICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cImFnbC5Qcm9kdWN0X19jXCJdJykuZGF0YSgna2VuZG9Mb29rdXAnKS5vcHRpb25zLmNyaXRlcmlhID0gbG9va3VwU2VhcmNoRmlsdGVycztcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJhZ2wuU2hpcF9Ub19fY1wiXScpLmxlbmd0aCA+IDAgKSB7XG4gICAgICAgICAgICAgICAgdmFyIGxvb2t1cFNlYXJjaEZpbHRlcnMgPSBbXTtcbiAgICAgICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJhZ2wuU2hpcF9Ub19fY1wiLCBmaWx0ZXI6IFwiUmVjb3JkVHlwZS5EZXZlbG9wZXJOYW1lICA9IFxcJ1NoaXBfVG9cXCdcIiB9KTtcbiAgICAgICAgICAgICAgICAkKGUuY29udGFpbmVyKS5maW5kKCdpbnB1dFtuYW1lPVwiYWdsLlNoaXBfVG9fX2NcIl0nKS5kYXRhKCdrZW5kb0xvb2t1cCcpLm9wdGlvbnMuY3JpdGVyaWEgPSBsb29rdXBTZWFyY2hGaWx0ZXJzO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYoICQoIGUuY29udGFpbmVyICkuZmluZCgnaW5wdXRbbmFtZT1cImFnbC5Qcm9kdWN0X1JlZmVyZW5jZV9fY1wiXScpLmxlbmd0aCA+IDAgKSB7XG4gICAgICAgICAgICAgICAgdmFyIGxvb2t1cFNlYXJjaEZpbHRlcnMgPSBbXTtcbiAgICAgICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJhZ2wuUHJvZHVjdF9SZWZlcmVuY2VfX2NcIiwgZmlsdGVyOiBcIiBDdXN0b21lcl9fYyA9IFxcJ1wiICsgYWdyZWVtZW50LkN1c3RvbWVyX19jICsgXCJcXCcgIEFORCBBY3RpdmVfX2MgPSB0cnVlIFwifSk7XG4gICAgICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cImFnbC5Qcm9kdWN0X1JlZmVyZW5jZV9fY1wiXScpLmRhdGEoJ2tlbmRvTG9va3VwJykub3B0aW9ucy5jcml0ZXJpYSA9IGxvb2t1cFNlYXJjaEZpbHRlcnM7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJhZ2wuQmlsbGluZ19DYXRlZ29yeV9fY1wiXScpLmxlbmd0aCA+IDAgKSB7XG4gICAgICAgICAgICAgICAgdmFyIGxvb2t1cFNlYXJjaEZpbHRlcnMgPSBbXTtcbiAgICAgICAgICAgICAgICBsb29rdXBTZWFyY2hGaWx0ZXJzLnB1c2goIHtmaWVsZDogXCJhZ2wuQmlsbGluZ19DYXRlZ29yeV9fY1wiLCBmaWx0ZXI6IFwiVHlwZV9fYyAgPSBcXCdCaWxsaW5nXFwnXCIgfSk7XG4gICAgICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cImFnbC5CaWxsaW5nX0NhdGVnb3J5X19jXCJdJykuZGF0YSgna2VuZG9Mb29rdXAnKS5vcHRpb25zLmNyaXRlcmlhID0gbG9va3VwU2VhcmNoRmlsdGVycztcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGlmKCAkKCBlLmNvbnRhaW5lciApLmZpbmQoJ2lucHV0W25hbWU9XCJhZ2wuRnVsZmlsbG1lbnRfQ2F0ZWdvcnlfX2NcIl0nKS5sZW5ndGggPiAwICkge1xuICAgICAgICAgICAgICAgIHZhciBsb29rdXBTZWFyY2hGaWx0ZXJzID0gW107XG4gICAgICAgICAgICAgICAgbG9va3VwU2VhcmNoRmlsdGVycy5wdXNoKCB7ZmllbGQ6IFwiYWdsLkZ1bGZpbGxtZW50X0NhdGVnb3J5X19jXCIsIGZpbHRlcjogXCJUeXBlX19jICA9IFxcJ0Z1bGZpbGxtZW50XFwnXCIgfSk7XG4gICAgICAgICAgICAgICAgJChlLmNvbnRhaW5lcikuZmluZCgnaW5wdXRbbmFtZT1cImFnbC5GdWxmaWxsbWVudF9DYXRlZ29yeV9fY1wiXScpLmRhdGEoJ2tlbmRvTG9va3VwJykub3B0aW9ucy5jcml0ZXJpYSA9IGxvb2t1cFNlYXJjaEZpbHRlcnM7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBpZiggJCggZS5jb250YWluZXIgKS5maW5kKCdpbnB1dFtkYXRhLXJvbGU9XCJkYXRldGltZXBpY2tlclwiXScpLmxlbmd0aCA+IDAgKSB7XG4gICAgICAgICAgICAgICAgdmFyIGRhdGVUaW1lUGlja2VycyA9ICAkKCdpbnB1dFtkYXRhLXJvbGU9XCJkYXRldGltZXBpY2tlclwiXScpO1xuICAgICAgICAgICAgICAgICQuZWFjaCggZGF0ZVRpbWVQaWNrZXJzLCBmdW5jdGlvbiggaWR4LCBpdGVtKSB7XG4gICAgICAgICAgICAgICAgICAgIGl0ZW0gPSAkKGl0ZW0pLmRhdGEoXCJrZW5kb0RhdGVUaW1lUGlja2VyXCIpO1xuICAgICAgICAgICAgICAgICAgICBpdGVtLnNldE9wdGlvbnMoeyBmb3JtYXQ6IFwiTS9kL3l5eXlcIiwgcGFyc2VGb3JtYXRzOiBcIk0vZC95eXl5IGhoOm1tXCJ9KTtcbiAgICAgICAgICAgICAgICB9ICk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIGNoYW5nZTogZnVuY3Rpb24oIGUgKSB7XG4gICAgICAgICAgICB2YXIgaXRlbSA9IHsgSWQ6IEFncmVlbWVudFZpZXdDb21wb25lbnQucHJvbW9Qcm9kUHJlZml4IH07XG5cbiAgICAgICAgICAgIHZhciBzZWxlY3RlZEl0ZW0gPSB0aGlzLmRhdGFJdGVtKCB0aGlzLnNlbGVjdCgpICk7XG5cbiAgICAgICAgICAgIGlmICggdHlwZW9mIHNlbGVjdGVkSXRlbSAhPT0gXCJ1bmRlZmluZWRcIiApIHtcbiAgICAgICAgICAgICAgICBpZiAoIHNlbGVjdGVkSXRlbSAhPT0gbnVsbCApIHtcblx0XHRcdFx0XHRcdGl0ZW0gPSBzZWxlY3RlZEl0ZW07XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAvLyAgc2VlIGlmIHRoaXMgcmVhbGx5IGNoYW5nZWQgP1xuICAgICAgICAgICAgaWYgKCBBZ3JlZW1lbnRWaWV3Q29tcG9uZW50LnByb21vdGVkUHJvZCAhPSBpdGVtICkge1xuICAgICAgICAgICAgICAgIEFncmVlbWVudFZpZXdDb21wb25lbnQucHJvbW90ZWRQcm9kID0gaXRlbTtcblxuICAgICAgICAgICAgICAgICQuZWFjaCggQWdyZWVtZW50Vmlld0NvbXBvbmVudC5wcm9tb1Byb2RBY3Rpb25Db25maWcsIGZ1bmN0aW9uKCkge1xuXG4gICAgICAgICAgICAgICAgICAgIHZhciByZWdleCA9IC9cXD9bYS16QS1aMC05PV0qLztcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5jb250ZW50ID0gdGhpcy5jb250ZW50ICYmIHRoaXMuY29udGVudC5yZXBsYWNlKCByZWdleCwgXCI/aWQ9XCIgKyBpdGVtLmlkICk7XG5cbiAgICAgICAgICAgICAgICB9ICk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9ICkuZGF0YSggXCJrZW5kb1RyZWVMaXN0XCIgKTtcbiAgICBcbiAgICB1dGlsaXR5LmVsZW1lbnRJbml0KCB0cmVlTGlzdCwgZmFsc2UgKTtcbiAgICB0cmVlTGlzdC5iaW5kKFwiZGF0YUJvdW5kXCIsIGRhdGFCb3VuZCk7XG59O1xuXG5mdW5jdGlvbiBkYXRhQm91bmQoZSl7XG5cbiAgICAgICAgJChcIi5rLWdyaWQtZWRpdFwiKS5lYWNoKGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgICAgICAgICAgXG5cbiAgICAgICAgICAgIHZhciBjdXJyZW50RGF0YUl0ZW0gPSAgJChcIiNwcHJvZFwiKS5kYXRhKFwia2VuZG9UcmVlTGlzdFwiKS5kYXRhSXRlbSgkKHRoaXMpLmNsb3Nlc3QoXCJ0clwiKSkuYWdsO1xuICAgICAgICAgICAgY29uc29sZS5sb2coY3VycmVudERhdGFJdGVtKTtcblxuICAgICAgICAgICAgaWYgKGN1cnJlbnREYXRhSXRlbS5BZ3JlZW1lbnRfX3IgJiYgKGN1cnJlbnREYXRhSXRlbS5BZ3JlZW1lbnRfX3IuU3RhdHVzX19jID09ICdBcHByb3ZlZCcgJiYgKGN1cnJlbnREYXRhSXRlbS5SZXZpc2lvbl9TdGF0dXNfX2MgPT0gJ0FwcHJvdmVkJyB8fCBjdXJyZW50RGF0YUl0ZW0uUmV2aXNpb25fU3RhdHVzX19jID09IG51bGwpKSkge1xuICAgICAgICAgICAgICAgICQodGhpcykuYWRkQ2xhc3MoJ2stc3RhdGUtZGlzYWJsZWQnKS5hdHRyKFwiZGlzYWJsZWRcIix0cnVlKTtcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgJCh0aGlzKS5yZW1vdmVDbGFzcygnay1zdGF0ZS1kaXNhYmxlZCcpLmF0dHIoXCJkaXNhYmxlZFwiLGZhbHNlKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICAgIFxuICAgICAgICAkKFwiLmstZ3JpZC1kZWxldGVcIikuZWFjaChmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgdmFyIGN1cnJlbnREYXRhSXRlbSA9ICAkKFwiI3Bwcm9kXCIpLmRhdGEoXCJrZW5kb1RyZWVMaXN0XCIpLmRhdGFJdGVtKCQodGhpcykuY2xvc2VzdChcInRyXCIpKS5hZ2w7XG5cbiAgICAgICAgICAgIGlmIChjdXJyZW50RGF0YUl0ZW0uQWdyZWVtZW50X19yICYmIChjdXJyZW50RGF0YUl0ZW0uQWdyZWVtZW50X19yLlN0YXR1c19fYyA9PSAnQXBwcm92ZWQnICYmIChjdXJyZW50RGF0YUl0ZW0uUmV2aXNpb25fU3RhdHVzX19jID09ICdBcHByb3ZlZCcgfHwgY3VycmVudERhdGFJdGVtLlJldmlzaW9uX1N0YXR1c19fYyA9PSBudWxsKSkpIHtcbiAgICAgICAgICAgICAgICAkKHRoaXMpLmFkZENsYXNzKCdrLXN0YXRlLWRpc2FibGVkJykuYXR0cihcImRpc2FibGVkXCIsdHJ1ZSk7XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICQodGhpcykucmVtb3ZlQ2xhc3MoJ2stc3RhdGUtZGlzYWJsZWQnKS5hdHRyKFwiZGlzYWJsZWRcIixmYWxzZSk7XG4gICAgICAgICAgICB9ICAgXG4gICAgICAgIH0pO1xufVxuIl19
