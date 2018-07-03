
    //Plugin to handle the hierarchical grid
(function($){
     $.fn.GridHierarchicalA = function(selector, options){
        	//Color coding
               //Object to a custom field for the color-coded column
           	var colorCodeObj = function(editable, field, fieldtype, filterable, format, hidden, nullable, precision, referenceTo, required, scale, selectList, sortable, title, validation, width ){
           	this.editable =  editable;
           	this.field =  field;
           	this.fieldtype = fieldtype;
           	this.filterable = filterable;
           	this.format = format;
           	this.hidden = hidden;
           	this.nullable = nullable;
           	this.precision = precision;
           	this.referenceTo = referenceTo;
           	this.required = required;
           	this.scale = scale;
           	this.selectList = selectList;
           	this.sortable = sortable;
           	this.title = title;
           	this.validation = validation;
           	this.width = width;
           	this.template = "#if(MasterGridColor ==='R'){#<span title='Not Matched' class='fa fa-lg fa-circle kndy-red'></span>#} if(MasterGridColor ==='G'){#<span title='Fully Matched' class='fa fa-lg fa-check-circle kndy-green'></span>#} if(MasterGridColor ==='Y'){#<span title='Partially Matched' class='fa fa-lg fa-check-circle-o kndy-orange'></span>#}if(MasterGridColor ==='NC'){#<span title='Approved' class='fa fa-lg fa-check'></span>#}#";
            };  
            
            var ccCol = new colorCodeObj(false, "MasterGridColor", "string", true, null, false, true, 0, null, false, 0, null, true, "Status", null, 80 );
        	//End of code to add a custom color-coded column
            var config = JSON.parse(options.config);
            config.buttons = options.columnButtons;
          //TODO combine config buttons with the options.columnButtons
          //config.buttons = config.buttons === null && options.columnButtons ? '' : ()
            var masterFieldList = options.masterFieldList;
            //Add the status column as the first column
			masterFieldList.unshift(ccCol);
            var detailFieldList = options.detailFieldList;
            var buttons = $.map(config.buttons.split(','), $.trim);
            var namespace = options.namespace;
            var lookupSearchAction = options.lookupSearchAction;
            var getCustomAction = options.getCustomAction;
            var masterReferenceFields = KenandyErp.KendoGridOptions.GetReferenceFields(masterFieldList); // get the list of reference fields for the master grid        
            var dateFields = KenandyErp.KendoGridOptions.GetDateFields(masterFieldList); // get the list of date fields for the master grid
            var lookupSearchFilters = (options.lookupSearchFilters) ? options.lookupSearchFilters : [];
            var messageElement = options.messageElement;
            
            //Initialize the model
            var getMasterModel = function(){
                var fields = KenandyErp.KendoGridOptions.GetFields(masterFieldList);
                //a
	            // Add schema for checkbox column
				fields.IsSelected__custom = { type: "boolean" };                
                var model = kendo.data.Model.define({id: "Id", fields: fields});
                return model;
            }
            
            //Initialize the columns
            var getMasterColumns = function(){
            function statusFilter(t){
                   t.kendoDropDownList({
                         dataSource:{
						     data: [
						        { text: "Not Matched", value: "R" },
						        { text: "Fully Matched", value: "G" },
						        { text: "Partially Matched", value: "Y" },
						        { text: "Approved", value: "NC" } 
									]
						  },
                        dataTextField: "text",
                        dataValueField: "value",						  
                        optionLabel: "--Select Value--",
                        template: "#if(data.value ==='R'){#<span title='Not Matched' class='fa fa-circle kndy-red'></span>#} if(data.value ==='G'){#<span title='Fully Matched' class='fa fa-lg fa-check-circle kndy-green'></span>#} if(data.value ==='Y'){#<span title='Partially Matched' class='fa fa-lg fa-check-circle-o kndy-orange'></span>#}if(data.value==='NC'){#<span title='Approved' class='fa fa-lg fa-check'></span>#}#"
                         
                        
                    });            
            }
            
                var columns = KenandyErp.KendoGridOptions.GetColumns(masterFieldList);
				$.each(columns, function(index, element){
					if(element.field === "MasterGridColor"){
						element.template = ccCol.template;
						element.filterable = {ui: statusFilter,
		                        operators: {
		                            string: {
		                                eq: "Is equal to"
		                            }
		                        }, 								
								extra: false}
					}
					
					//Show the date as date only
					if(element.field === "bankTransaction.Transaction_Date__c" || element.field === "bankTransaction.Reconciled_As_Of_Date__c"){
						//KNDY-15576 dynamic format
						//element.format = "{0:MM/dd/yyyy}";
						element.format = "{0:" + KenandyErp.DateFormat  + "}";
					}
					if(element.field=="bankTransaction.Match_Approved__c"){
						element.hidden = true;
					}
				});
				//Add the custom 'Find' icon link here
				var cmdtmp = new Object();
				cmdtmp.name = "find-custom-command";
				cmdtmp.template = "<a class='grid-find-custom-command pointer' title='Find Matches'><span class='fa fa-search fa-lg'></span></a>";
				cmdtmp.text = "";
				var actionCol = new Object();
				actionCol.title = "Action";
				actionCol.width = 60;
				actionCol.command = [cmdtmp];
				columns.unshift(actionCol);
				//End of the add the custom 'Find' icon link
				//Add the select column as the first column
				columns.unshift({ field: 'IsSelected__custom', filterable: false, sortable: false, template: "<input type='checkbox' data-bind='IsSelected__custom' #= IsSelected__custom ? checked='checked': '' # class='grid-select-one' />", headerTemplate: "<input type='checkbox' class='grid-select-all' />", width: 30, attributes: { class: 'kndy-text-left' }, headerAttributes: { class: 'kndy-text-left' } });				
                return columns;
            }
			//Buttons for the top of the grid            
            var getMasterToolbarButtons = function() {
                return KenandyErp.KendoGridOptions.GetToolbarButtons(buttons);
            }; 
             
            var getMasterDataSource = function(){
                var dataSource = new kendo.data.DataSource({
                    transport: {
                        read: function(options){
                            KenandyErp.BlockUI(selector);
                            var promise = getCustomAction();
                            promise.done(function(result, event){

                                KenandyErp.UnBlockUI(selector);
                                if (event.type === 'exception') {
                                    //KenandyErp.Alert("{!$Label.Error_occurred_contact_support}");
			    					KenandyErp.Message(event.message === null ? "There was an error. Please contact support." : event.message, KenandyErp.MessageType.Error, messageElement? messageElement : "");
			    					options.error(event, "statuscode", event.message);
			    					
			    					//options.success([]);
                                } else {
			                            console.log("Table result");
			                            console.log(result);
                                    KenandyErp.CleanNamespace(result.records, namespace);
                                    options.success(result.records)
                                }                           
                            });
                            
                        }
                    },
                    batch: true,
                    pageSize: KenandyErp.KendoGridOptions.DefaultPageSize,
                    schema: {
                        model: getMasterModel(),
                        parse: function(response){
                            $.each(response, function (idx, item) {
                                item = Serializer.ConvertFromSFDCDate(item, { dateFields: dateFields });
                            });
                            return response;                        
                        }
                    },
                    error: function(e) {
                    	console.log("DataSource error:");
                        console.log(e); // displays "Invalid query"
                    }
                });
                
                
              /*dataSource.read().then(
              function(result){console.log("A-S");},
              function(error){console.log("A-F");});    */
                
                
                return dataSource;
            };
            
            var masterGrid = $(selector).kendoGrid({
                dataSource: getMasterDataSource(), 
                navigatable: true,
                pageable: { 
                    input: true,
                    numeric: false,
                    pageSizes: KenandyErp.KendoGridOptions.PageSizes 
                },  
               // toolbar: getMasterToolbarButtons(), 
                columns: getMasterColumns(),
                sortable: true,
                filterable: true,
                resizable: true,  
                detailTemplate: kendo.template($("#detailTemplate").html()),
                detailInit: $.proxy(BankTxnMatch.DetailInit, { detailFieldList: detailFieldList, lookupSearchAction: lookupSearchAction, selector: selector, namespace: namespace }),
                editable: false,
            }).data('kendoGrid');
                // bind grid detailExpand/detailCollapse events
                masterGrid.bind("detailExpand", $.proxy(BTMatchingUtils.DetailExpand, { grid: masterGrid }));
                masterGrid.bind("detailCollapse", $.proxy(BTMatchingUtils.DetailCollapse, { grid: masterGrid }));
                
                masterGrid.thead.on("click", ".grid-select-all", $.proxy(KenandyErp.KendoGridActions.SelectAll, { grid: masterGrid }));
                masterGrid.tbody.on("change", ".grid-select-one", $.proxy(KenandyErp.KendoGridActions.Select, { grid: masterGrid }));
    			
                masterGrid.bind('dataBound', function () {
    				var isSelected = (masterGrid.tbody.find('.grid-select-one').length > 0 && !masterGrid.tbody.find('.grid-select-one').is(':not(:checked)')) ? true : false;
    				masterGrid.thead.find('.grid-select-all').prop('checked', isSelected);
    			});                
                
                
                //bind refresh event
                masterGrid.dataSource.bind("change", $.proxy(BTMatchingUtils.refreshMasterGrid, { masterGrid: masterGrid, isMasterGrid: true }));
        return masterGrid;       
    };   
})(jQuery);