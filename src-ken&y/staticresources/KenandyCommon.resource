var KenandyErp = function() {
   
   	return {
    	Culture: 'en-US',
    	TimeZone: 'America/Los_Angeles',
    	DateFormat: 'M/d/yyyy',
    	DateTimeFormat: 'M/d/yyyy h:mm tt',
    	ExportPdfUrl: new String(),
    	ExportExcelUrl: new String(),
        NamespacePrefix : '',
    	    
    	Init: function(args) {
           // initialize defaults
           this.Culture = args.Culture;
           this.TimeZone = args.TimeZone;
           this.DateFormat = args.DateFormat;
           this.DateTimeFormat = args.DateTimeFormat;
           this.ExportPdfUrl = args.ExportPdfUrl;
           this.ExportExcelUrl = args.ExportExcelUrl;
           this.NamespacePrefix = args.NamespacePrefix ? args.NamespacePrefix : '';
       	},

       	//part of the sanitization processs
		decodeHtml: function(html) {
    		var txt = document.createElement("textarea");
    		txt.innerHTML = html;
    		return txt.value;
		},		       	
		FormatNumbersToCommas: function(tmp){
            if(tmp && !isNaN(tmp)){
                var ret = tmp +"";
                ret = ret.split(".");
                //If ret[0] is -0, -ve sign will be lost while typecasting into Number
                ret[0] = Number(ret[0]).toLocaleString();
                if(ret[1] && ret[1].length === 1) ret[1] = ret[1]+"0";
                ret = ret.length>1 ? ret.join(".") : ret[0] + ".00";
                //add the -ve sign back if tmp was negative 0
                tmp = tmp + "";
                tmp = tmp.split(".");
                if (tmp[0] == "-0"){ret = "-"+ret;}
                return ret;
            }
            console.log("Encountered an error in addCommas: "+tmp);
            return "0.00";
        },
        MessageType: {
            Success: 'CONFIRM',
            Info: 'INFO',
            Warning: 'WARNING',
            Error: 'ERROR',
            Fatal: 'FATAL'
        },
        
        Alert: function(message) {
        	// displays an alert box with a specified message and an OK button
        	
            $.fn.KendoAlert({ title: 'Notification', html: message }, null);
        },
        
        Confirmation: function(message, yesCallback, noCallback, closeCallback) {
        	// displays a dialog box with a specified message, along with an Yes and a No button
        	
            $.fn.KendoConfirmation({ title: 'Confirmation', html: message }, yesCallback, noCallback, closeCallback);
        },
        ParseMessage: function(message) {

            var messageTemplates = [];
            var outputMessage = message;
            messageTemplates.push({input: "Error parsing json response:  'Unexpected token <'.  Logged in?", output: "Your session has expired. You need to refresh the page and log in to Kenandy again."});
            message = message.replace(/\n/g, '');
            messageTemplates.forEach(function(template){
                if(message.includes(template.input))
                    outputMessage = template.output;
            });
            return outputMessage;

        },

        Message: function (messageVal, type, selector) {
            var severityVal ;
            if (type == this.MessageType.Error) {
                severityVal = 'ERROR';
            } else if (type == this.MessageType.Info) {
                severityVal = 'INFO';
            } else if (type == this.MessageType.Warning) {
                severityVal = 'WARNING';
            } else if (type == this.MessageType.Success) {
                severityVal = 'CONFIRM';
            }

            this.Messages([{message: messageVal, severity: severityVal}], selector);
        },
        
		Messages: function (messages, selector) {
			if (!messages || messages.length == 0) { 
				return;
			}
			
            // display multiple custom message using the Salesforce formatting
            this.ClearMessage(selector);
            selector = (selector) ? $(selector) : $(".page-message");

            var messageContainer = $('<span />');
			var messageType = "Error";
			var messageHeading = '';
			var messageText = '';
			var messageSeverity = '';
            var className = "message errorM3";			
			
			if (messages.length > 1) {
				var msgArr = _.pluck(messages, 'message');
				messageText = '<ul>';
                for (var i=0; i<msgArr.length; i++) {
                	//html decoding, then sanitizing.  This is because of the special case of DML errors bubbled up from salesforce.  they will already be html encoded, so we end up double sanitizing.
					messageText += ('<li>' + sanitize(this.decodeHtml(this.ParseMessage(msgArr[i]))) + '</li>');
                }
				messageText += '</ul>';				
				messageSeverity = messages[0].severity;
			} else {
               	//html decoding, then sanitizing.  This is because of the special case of DML errors bubbled up from salesforce.  they will already be html encoded, so we end up double sanitizing.
				messageText = sanitize(this.decodeHtml(this.ParseMessage(messages[0].message)));
				messageSeverity = messages[0].severity;
			}
			if (messages.length > 1) {
			    
			    var msgSeverityErrorArr = _.pluck(messages, 'severity');
			    for(var i=0;i<msgSeverityErrorArr.length;i++)
		     	{
		     	    if(msgSeverityErrorArr[i] == 'FATAL' || msgSeverityErrorArr[i] == 'ERROR' || msgSeverityErrorArr[i] == 'WARNING' || msgSeverityErrorArr[i] == 'INFO')
		     		{
		     		
		     			if(msgSeverityErrorArr[i] == 'FATAL')
							messageSeverity = msgSeverityErrorArr[i];
						
						if(msgSeverityErrorArr[i] == 'ERROR' && messageSeverity != 'FATAL')
							messageSeverity = msgSeverityErrorArr[i];
							
						if(msgSeverityErrorArr[i] == 'WARNING' && ((messageSeverity != 'FATAL')||(messageSeverity != 'ERROR')))
							messageSeverity = msgSeverityErrorArr[i];
						
						if(msgSeverityErrorArr[i] == 'INFO' && ((messageSeverity != 'FATAL')||(messageSeverity != 'ERROR')||(messageSeverity != 'WARNING')))
							messageSeverity = msgSeverityErrorArr[i];
						
		     		}
		     		
		     	}
			   
			     	
			}
			
			switch(messageSeverity)
			{
				case 'CONFIRM':
					className = "message confirmM3";
                    messageType = 'Success';
                    messageHeading = '<span><h4>' + messageType + ':</h4></span>';
			   		break;
			   	case 'INFO':
			   		className = "message infoM3";
                    messageType = 'Info';
                    messageHeading = '<span><h4></h4></span>';
			   		break;
			   	case 'WARNING':
			   		className = "message warningM3";
                    messageType = 'Warning';
                    messageHeading = '<span><h4>' + messageType + ':</h4></span>';
			   		break;
			   	case 'ERROR':
			   	case 'FATAL':
			   	default: 
			   		className = "message errorM3";
                    messageType = 'Error';
                    messageHeading = '<span style="color:#cc0000"><h4>' + messageType + ':</h4></span>';
			    	break;
			}
			
			messageContainer.append(
	            '<div class="' + className + '" role="alert">' +
	                '<table border="0" cellpadding="0" cellspacing="0" class="messageTable" style="padding:0px;margin:0px;width:100%;">' +
	                    '<tr valign="top">' +
	                        '<td style="width:10px;">' +
	                            '<img alt="' + messageType + '" class="msgIcon" src="/s.gif" title="' + messageType + '">' +
	                        '</td>' +
	                        '<td class="messageCell"><div class="messageText">' + messageHeading + messageText + '</div></td>' +
	                        '<td align="right" style="vertical-top;width:10px;"><a href="javascript:void(0);" onclick="KenandyErp.HideMessage(this);" class="message-close-btn k-button"><span class="k-icon k-i-close"></span></a></td>' +
	                    '</tr>' +
	                '</table>' +
	            '</div>' 
            );
            
            $(selector).append(messageContainer);
    
    		// Comments By LK On 2/19/2014
    		// Disable the fadeOut of success and info messages
    		/*
            window.setTimeout(function() {
                $(selector).find("div.infoM3, div.confirmM3").fadeOut(1000);
            }, 3000);*/
        
        },

        ClearMessage: function(selector) {
        	// clears a custom page message
        	selector = (selector) ? $(selector) : $(".page-message");
        	
            $(selector).empty();
        },
        
        HideMessage: function(selector) {
        	$(selector).closest('div.message').fadeOut(1000);
        },
        
        BlockUI: function (selector) {
        	this.DisableButtons();
        	            
        	// show loading overlay
        	
        	selector = (selector) ? $(selector) : $(".page-container");
            kendo.ui.progress(selector, true);
        },

        UnBlockUI: function (selector) {
        	this.EnableButtons();
        	
        	// hide loading overlay
        	
        	selector = (selector) ? $(selector) : $(".page-container");
            kendo.ui.progress(selector, false);
        },
                        	
		EnableButtons: function() {
			$('.btn, .kndy-btn').each(function() {
			    if ($(this).prop('default_value')) {
			    	$(this).val($(this).prop('default_value'))
			    }
			    
				if ($(this).hasClass('kndy-loading')) {
					$(this).removeClass('kndy-loading').removeClass('btnDisabled').removeProp('disabled');
				}
			});
		},
		
		DisableButtons: function() {
			$('.btn, .kndy-btn').each(function() {
			    if ($(this).hasClass('kndy-loading')) {
			        return;
			    }
			    
			    $(this).prop('default_value', $(this).prop('defaultValue')).val('Processing...')
			    
				if (!$(this).prop('disabled')) {
					$(this).addClass('kndy-loading').addClass('btnDisabled').prop('disabled', true);
				}
			});
		},
        		            	
        Today: function() {
        	return new Date(moment().tz(KenandyErp.TimeZone).format('M/D/YYYY'));
        },

        Now: function() {
        	return new Date(moment().tz(KenandyErp.TimeZone).format('M/D/YYYY h:mm A'));
        },
                        	
       	ParseSFDCDate: function(value) {
    		if (value) {
    			if (!(value instanceof Date)) {
    				var date = moment(value).tz(KenandyErp.TimeZone).utc().format('M/D/YYYY');
                    value = new Date(date);
				}

				return value;               
			}
			
			return null;
		},
		                	
       	ParseSFDCDateTime: function(value) {
    		if (value) {
    			if (!(value instanceof Date)) {
	            	var date = moment(value).tz(KenandyErp.TimeZone).format('M/D/YYYY h:mm:ss A');
                    value = new Date(date);
				}
				
				return value;               
			}
			
			return null;
		},
		
		IsValidDate: function(value) {
    		if (value) {
    			var date = kendo.parseDate(value, KenandyErp.DateFormat)
    			
    			return (date instanceof Date);               
			}
			
			return false;
		},
		

		IsValidDateTime: function(value) {
         try {
            var isValidDate = false;
            var arr1 = value.split('/');
            var year=0; var month=0; var day=0; var hour=0; var minute=0; var sec=0; var meridian;
            if(arr1.length == 3)
            {
                var arr2 = arr1[2].split(' ');
                if(arr2.length == 3)
                {
                    var arr3 = arr2[1].split(':');
                    try{
                        year = parseInt(arr2[0],10);
                        month = parseInt(arr1[0],10);
                        day = parseInt(arr1[1],10);  
                        hour = parseInt(arr3[0],10);
                        minute = parseInt(arr3[1],10);
                        //sec = parseInt(arr3[0],10);
                        sec = 0; // Since we are not validating seconds on the DatePicker
                        meridian = String(arr2[2]);
                        
                        var isValidTime=false;
                        if(hour >=0 && hour <=23 && minute >=0 && minute<=59 && sec >=0 && sec<=59 && (meridian == 'AM' || meridian == 'PM') )
                            isValidTime=true;
                        else if(hour ==24 && minute ==0 && sec==0 && (meridian == 'AM' || meridian == 'PM'))
                            isValidTime=true;

                        if(isValidTime)
                        {
                            var isLeapYear = false;
                            var isValidYear = false;
                            
                            if(year != null && (year >= 1700 && year <= 4000)) // Salesforce allowed Year Range
                                isValidYear = true;
                            
                            if(year % 4 == 0)
                                 isLeapYear = true;

                            if(isValidYear){   
                            if((month==4 || month==6|| month==9|| month==11) && (day>=0 && day <= 30))
                                    isValidDate=true;
                                else if((month!=2) && !(month < 1 || month > 12) && (day>=0 && day <= 31))
                                    isValidDate=true;
                            }

                            if(!isValidDate && isValidYear){
                                if(isLeapYear)
                                {
                                    if(month==2 && (day>=0 && day <= 29))
                                        isValidDate=true;
                                }
                                else
                                {
                                    if(month==2 && (day>=0 && day <= 28))
                                        isValidDate=true;
                                }
                            }
                        }
                    }
                    catch(er){isValidDate = false;}
                }
            }
            return isValidDate;
          }
          catch (err) { KenandyErp.Alert('ValidateDate: ' + err); }
        },
		
		LookupDetail: function (id, name, escape){
				if(id && name){
					var nameEsc = '#=Name#';
	                //KNDY4-8465 prevent XSS
	                if (escape) {
		                nameEsc = '#=sanitize(Name)#';
	                }
	                var templateString =
	   				'<a id="lookup#=Id#" target="_new" href="/#=Id#" ' +
	                   '>' +
	                   nameEsc +
	                   '</a>';
	                var lookupTemplate = kendo.template(templateString);    
					var lookupData = { Id: id, Name: name };
					return lookupTemplate(lookupData);	 			                
					
				}
				return name;
			} ,		
		
		LookupHoverDetail: function(id, name, escape) {
			if (id && name) {

                var nameEsc = '#=Name#';

                //KNDY4-8465 prevent XSS
                if (escape) {
	                nameEsc = '#=sanitize(Name)#';
                }
                
                var templateString =
				'<a id="lookup#=Id#" target="_new" href="/#=Id#" ' +
                'onblur="LookupHoverDetail.getHover(\'lookup#=Id#\').hide();" ' +
                'onfocus="LookupHoverDetail.getHover(\'lookup#=Id#\', \'/#=Id#/m?retURL=%2F#=Id#&isAjaxRequest=1\').show();" ' +
                'onmouseout="LookupHoverDetail.getHover(\'lookup#=Id#\').hide();" ' +
                'onmouseover="LookupHoverDetail.getHover(\'lookup#=Id#\', \'/#=Id#/m?retURL=%2F#=Id#&isAjaxRequest=1\').show();">' +
                nameEsc +
                '</a>';

                var lookupTemplate = kendo.template(templateString);    
				var lookupData = { Id: id, Name: name };
					
				return lookupTemplate(lookupData);
			}
			
			return name;
		},

        CleanNamespace: function(data, namespace) { this.CleanObject(data, namespace, false); },
        CleanObject: function(obj, namespace, deleteAttrs) {
            if (obj == null) return;

            if (deleteAttrs !== false) delete obj.attributes;

            var keys = Object.keys(obj);
            for (var i = 0; i < keys.length; i++) {
                var key = keys[i];

                if (deleteAttrs !== false && key.endsWith("__r") === true && obj[key].hasOwnProperty("records") && _.isArray(obj[key].records) === true) {
                    delete obj[key];
                    continue;
                }

                var newKey = key;
                if (typeof namespace === 'string') {
                    newKey = key.replace(namespace, '');
                    obj[newKey] = obj[key];
                    if (newKey !== key) delete obj[key];
                }

                if (typeof obj[newKey] === "object") {
                    this.CleanObject(obj[newKey], namespace, deleteAttrs);
                } else if (obj[newKey] != null && obj[newKey].constructor === Array) {
                    for (var j = 0; j < obj[newKey].length; j++) {
                        if (typeof obj[newKey][j] === "object") this.CleanObject(obj[newKey][j], namespace, deleteAttrs);
                    }
                }
            }
        },

		NavigateToURL: function(url, isRedirect) {
			if(typeof sforce !== "undefined" && typeof sforce.one !== "undefined") {
				sforce.one.navigateToURL(url, isRedirect);
			} else {
                window.location.href = url;
			}
		},

		NavigateToSObject: function(recordId, view) {
            if(typeof sforce !== "undefined" && typeof sforce.one !== "undefined") {
				sforce.one.navigateToSObject(recordId, view);
            } else {
            	window.location.href = "/" + recordId;
			}
		},

		back: function(refresh, url) {
            if(typeof sforce !== "undefined" && typeof sforce.one !== "undefined") {
                sforce.one.back(refresh);
            } else {
            	if(refresh) {
                    window.location.href = url;
				} else {
            		window.history.back();
				}

            }
		},

		RefreshSerialAttributes: function(e) {
			var self = this;
			var grid = this.grid;
			var serialFieldList = this.serialFieldList;
			var refreshAction = this.refreshAction;
			var messageElement = grid.element.closest("div.grid-container").find("div.grid-message");
			var fields = KenandyErp.KendoGridOptions.GetFields(JSON.parse(serialFieldList));
			var cell = grid.editable.element;
			var row = $(e.target).closest("tr"); //get the row
			var dataItem = grid.dataItem(row); // get the row data
			var consignedFlag = false;
			var namespace = this.namespace;
			
			if(dataItem.get('SerialName.Id')){
				KenandyErp.BlockUI(grid.element);
				
				Visualforce.remoting.Manager.invokeAction(
					refreshAction,
					dataItem.get('SerialName.Id'),
					function (result, event) {
						KenandyErp.UnBlockUI(grid.element);
						
						if (event.type == 'exception') {
							KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
						} else {
							if(result != null){
							    KenandyErp.CleanNamespace(result, namespace);
								dataItem.Id = result.Id;
								dataItem.Name = result.Name;
								dataItem.SerialName.Id = result.Id;
								dataItem.SerialName.Name = result.Name;
								for( var i in fields){
									if(i && (result[i])){
										dataItem.set(i, result[i]);
									}
									if(i && (!result[i]) && i!='SerialNameId' && i!=""){
										dataItem.set(i, undefined);
									}
								}
							}
						}
					},
					{escape: false}
				);
			}
			else{
				for( var i in fields){
					if(i && i!='SerialNameId' && i!=""){
						dataItem.set(i, undefined);
					}
				}
			}
		}
	};       
}();

KenandyErp.KendoGridOptions = function() {
   
   	return {
    	DefaultPageSize: 25,
    	PageSizes: [10, 25, 50, 100, 200],
    	
    	Init: function(args) {
           // initialize defaults
       	},
       	
        ColumnType: {
        	Boolean: 'boolean',
        	Date: 'date',
        	DateTime: 'datetime',
        	Double: 'double',
        	Id: 'id',
        	Integer: 'integer',
            Picklist: 'picklist',
            MultiPicklist: 'multipicklist',
            Percent: 'percent',
            Reference: 'reference',
            String: 'string',
            Name: 'Name',
            RowInfo: 'rowinfo'
        },
        
        FieldInfo: {
        	Field: 'field',
        	Title: 'title',
        	FieldType: 'fieldtype',
        	Editable: 'editable',
        	Sortable: 'sortable',
            Filterable: 'filterable',
            Nullable: 'nullable',
            Hidden: 'hidden',
            Required: 'required',
            SelectList: 'selectList',
            ReferenceTo: 'referenceTo',
            Precision: 'precision',
            Scale: 'scale',
            Format: 'format',
            Min: 'min',
            Max: 'max',
			Width: 'width',
			ValidateLookupOnBlur: 'validateLookupOnBlur',
			Aggregate: 'aggregate',
			Reorderable:'reorderable', //KNDY-18070 reorder columns
            Locked   : 'locked'
        },
        
        CommandType: {
        	Create: 'create',
        	Save: 'save',
        	Cancel: 'cancel',
        	Delete: 'delete',
        	Clone: 'clone',
        	Search: 'search',
        	AddRow: 'add',
        	ColumnMenu: 'columnmenu',
        	Print: 'print',
        	ExportExcel: 'excel',
        	ExportPdf: 'pdf'
        },
        
        AggregateType: {
        	Average: 'average',
        	Count: 'count',
        	Max: 'max',
        	Min: 'min',
        	Sum: 'sum'
        },
        
        FilterOperatorType: {
        	Equals: 'eq',
        	NotEquals: 'neq',
        	GreaterThan: 'gt',
        	GreaterThanOrEquals: 'gte',
        	LessThan: 'lt',
        	LessThanOrEquals: 'lte',
        	Contains: 'contains',
        	DoesNotContain: 'doesnotcontain',
        	Between: 'between'
        },
        
        ExportFormat: {
        	PrintableView: 'print',
        	Excel: 'excel',
            Pdf: 'pdf'
        },
        
        /*
        	Returns the list of all reference fields for a given fieldList
        */
		GetReferenceFields: function(fieldList) {
			var referenceFields = [];
			
			$.map(fieldList, function(item, index) {	 
				if (item[KenandyErp.KendoGridOptions.FieldInfo.FieldType] == KenandyErp.KendoGridOptions.ColumnType.Reference) {	 
					referenceFields.push(item[KenandyErp.KendoGridOptions.FieldInfo.Field]);
				} 
			});
			
			return referenceFields;
		},
		
        /*
        	Returns the list of all date fields for a given fieldList
        */
		GetDateFields: function(fieldList) {
			var dateFields = [];
			
			$.map(fieldList, function(item, index) {	 
				if (item[KenandyErp.KendoGridOptions.FieldInfo.FieldType] == KenandyErp.KendoGridOptions.ColumnType.Date
					|| item[KenandyErp.KendoGridOptions.FieldInfo.FieldType] == KenandyErp.KendoGridOptions.ColumnType.DateTime) {	 
					dateFields.push({ field: item[KenandyErp.KendoGridOptions.FieldInfo.Field], fieldtype: item[KenandyErp.KendoGridOptions.FieldInfo.FieldType] });
				} 
			});
			
			return dateFields;
		},
		
        /*
			Returns all multipicklist fields for a given fieldlist
		*/
		getMultiPicklistFields: function(fieldList) {
			var multiPicklistFields = [];
			
			$.map(fieldList, function(item, index) {	 
				if (item[KenandyErp.KendoGridOptions.FieldInfo.FieldType] == KenandyErp.KendoGridOptions.ColumnType.MultiPicklist) {	 
					multiPicklistFields.push({ field: item[KenandyErp.KendoGridOptions.FieldInfo.Field], fieldtype: item[KenandyErp.KendoGridOptions.FieldInfo.FieldType] });
				} 
			});
			
			return multiPicklistFields;
		},
		
        /*
        	Returns the list of all nested fields for a given fieldList
        */
		GetNestedFields: function(fieldList) {
			var nestedFields = [];
			
			$.map(fieldList, function(item, index) {	 
				if (item[KenandyErp.KendoGridOptions.FieldInfo.Field].indexOf('.') != -1) {	 
					nestedFields.push(item[KenandyErp.KendoGridOptions.FieldInfo.Field]);
				} 
			});
			
			return nestedFields;
		},
		 
        GetFields: function(fieldList, options) {
        	// returns the list of fields for a given field list
        	var fields = {};
        	
        	for (var i = 0; i < fieldList.length; i++) {
        		var defaultValue = null;
        		var field = { type: fieldList[i].fieldtype, editable: fieldList[i].editable };
        		
        		// add validations
        		if (fieldList[i].validation) {
        			field.validation = fieldList[i].validation;
        		}
        		
        		// add required field validation
        		if (fieldList[i].required) {
        			field.validation = $.extend({}, { required: { message: fieldList[i].title + " is required" } }, field.validation);
        		}
        		
                if (fieldList[i].fieldtype == this.ColumnType.Date) { 
                    field.type = "date";
                    field.format = KenandyErp.DateFormat;
                    if (!field.validation) field.validation = {};
                	field.validation.invaliddate = function(input) {
                    	if (input.is("[name='" + input.attr('name') + "']") && input.val() != "") {
                        	input.attr("data-invaliddate-msg", input.attr('data-title') + " is invalid");
                            var value = kendo.parseDate(input.val(), KenandyErp.DateFormat);

							if (!(value instanceof Date)) {
								input.on('focus', function() {
							      	var that = $(this);
							      	setTimeout(function() {
							      		if (!kendo.support.browser.safari) {
							        		that.select();
							        	}
							      	});
								});
								
								input.focus();
								return false;
							}
                        }
						
                        return true;
					};
                }
                else if (fieldList[i].fieldtype == this.ColumnType.DateTime) { 
                    field.type = "date";
                    field.format = KenandyErp.DateTimeFormat;
                    if (!field.validation) field.validation = {};
                	field.validation.invaliddate = function(input) {
                    	if (input.is("[name='" + input.attr('name') + "']") && input.val() != "") {
                        	input.attr("data-invaliddate-msg", input.attr('data-title') + " is invalid");
                            var value = kendo.parseDate(input.val(), KenandyErp.DateTimeFormat);

							if (!(value instanceof Date)) {
								input.on('focus', function() {
							      	var that = $(this);
							      	setTimeout(function() {
							      		if (!kendo.support.browser.safari) {
							        		that.select();
							        	}
							      	});
								});
								
								input.focus();
								return false;
							}
                        }
						
                        return true;
					};
                }
				else if (fieldList[i].fieldtype == this.ColumnType.Picklist) {
					var selectedItem = _.where(fieldList[i].selectList, {selected: true});
					defaultValue = (selectedItem.length > 0) ? selectedItem[0].value : '';
					
                	field.type = "string";
                	field.defaultValue = defaultValue;
				}
				else if (fieldList[i].fieldtype == this.ColumnType.Reference) {
                	field.type = "string";
                	field.defaultValue = null;
                	if (!field.validation) field.validation = {};
                	field.validation.lookupvalidation = function(input) {
                    	if (input.is("[name='" + input.attr('name') + "']") && input.val() != "") {
                        	input.attr("data-lookupvalidation-msg", input.attr('data-title') + " is invalid");
                            
							if (input.prop("valid") == false) {
								input.on('focus', function() {
							      	var that = $(this);
							      	setTimeout(function() {
							      		if (!kendo.support.browser.safari) {
							        		that.select();
							        	}
							      	});
								});
								
								input.focus();
								return false;
							}
                        }
						
						input.removeProp("valid");
                        return true;
					};
				}
                else if (fieldList[i].fieldtype == this.ColumnType.Name) {
                    field.type = "string";
                }
                else if (fieldList[i].fieldtype == this.ColumnType.RowInfo) {
                    field.type = "string";
                }
				else if (fieldList[i].fieldtype == this.ColumnType.Integer || fieldList[i].fieldtype == this.ColumnType.Double) {
                	field.type = "number";
                	field.format = "n" + fieldList[i].scale;
				}
				else if (fieldList[i].fieldtype == this.ColumnType.Percent) {
                	field.type = "number";
                	field.format = "n" + fieldList[i].scale;
                	field.validation = { min: 0, max: 100 };
				}
				else if (fieldList[i].fieldtype == this.ColumnType.Boolean) {
					field.type = "boolean";
				}
				else {
					field.type = "string";
				}
				
            	fields[fieldList[i].field] = field;

            	// Define schema for the parent fields, to provide defaults for nested objects (required for grid.addRow)
            	if (fieldList[i].field.indexOf('.') != -1) {
            		var parentKey = fieldList[i].field.split('.')[0];
            		var path = fieldList[i].field.split('.').slice(1).join('.');					
					
					if (!fields[parentKey]) {
            			fields[parentKey] = { type: undefined, defaultValue: { } };
            		}
            		
            		JSONUtils.SetObject(path, defaultValue, fields[parentKey].defaultValue);
            	}
        	}

        	return fields;
        },
        
       	GetColumns: function(fieldList, config) {
       		// returns the list of columns for a given field list
       		//KNDY-18070 added feature for reorderable
            var columnKeys = [this.FieldInfo.Field, this.FieldInfo.Title, this.FieldInfo.FieldType, this.FieldInfo.Sortable, this.FieldInfo.Filterable, this.FieldInfo.Editable, this.FieldInfo.Hidden, this.FieldInfo.Locked, this.FieldInfo.Required, this.FieldInfo.SelectList, this.FieldInfo.ReferenceTo, this.FieldInfo.Scale, this.FieldInfo.Format, this.FieldInfo.Min, this.FieldInfo.Max, this.FieldInfo.Width, this.FieldInfo.ValidateLookupOnBlur, this.FieldInfo.Aggregate,this.FieldInfo.Reorderable, 'editor', 'template', 'headerTemplate', 'footerTemplate', 'nonhoverable', 'wrapHeader', 'unwrapBody'];
			var columns = _.map(fieldList, function(obj) { return _.pick(obj, columnKeys); });

            for (var i = 0; i < columns.length; i++) {
                //columns[i].width = columns[i].width ? columns[i].width : "100px"; //To add a scroll bar by default, set the width of each column in pixels - KNDY-10623

            	if (columns[i].fieldtype == this.ColumnType.Integer || columns[i].fieldtype == this.ColumnType.Double || columns[i].fieldtype == this.ColumnType.Percent) {
					//columns[i].width = 80;
            		columns[i].format = "{0:n" + columns[i].scale + "}";
            		columns[i].headerAttributes = { "class": "kndy-text-right" };
            		columns[i].footerAttributes = { "class": "kndy-text-right" };
    				columns[i].attributes = { "class": "kndy-text-right" };
    				columns[i].editor = (columns[i].editor) ? columns[i].editor : function(container, options) {
            			var column = _.where(columns, {field: options.field})[0];
    					var required = column.required ? " required='required' data-required-msg='" + column.title + " is required'" : "";
    					
            			$('<input ' + required + ' name="' + options.field + '" data-bind="value:' + options.field + '" />')
					    .appendTo(container)
					    .kendoNumericTextBox({
					    	format: "{0:n" + column.scale + "}",
					      	decimals: column.scale,
					      	min: (column.min != null) ? column.min : undefined,
					      	max: (column.max != null) ? column.max : undefined
					    });
                        
                        $('<span class="k-invalid-msg" data-for="' + options.field + '"></span><span data-valmsg-for="' + options.field + '"></span>').appendTo(container);
            		}
            	}
            	else if (columns[i].fieldtype == this.ColumnType.Date) {
            		//columns[i].width = 100;
            		columns[i].format = "{0:" + KenandyErp.DateFormat + "}";
            		columns[i].editor = function(container, options) {
            			var field = options.field;
            			var column = _.where(columns, {field: field})[0];
    					var required = column.required ? " required='required' data-required-msg='" + column.title + " is required'" : "";
						var minDate = KenandyErp.ParseSFDCDate(column.min);
                        var maxDate = KenandyErp.ParseSFDCDate(column.max);
						
                    	$('<input ' + required + ' name="' + field + '" data-title="' + column.title + '" data-bind="value:' + field + '" />')
						    .appendTo(container)
						    .kendoDatePicker({
						    	culture: KenandyErp.Culture,
						    	format: KenandyErp.DateFormat,
						    	min: minDate ? minDate : undefined,
						    	max: maxDate ? maxDate : undefined
						    });
                        
                        $('<span class="k-invalid-msg" data-for="' + field + '"></span>').appendTo(container);
            		}
            	}
            	else if (columns[i].fieldtype == this.ColumnType.DateTime) {
            		//columns[i].width = 100;
            		columns[i].format =columns[i].format ? "{0:" + columns[i].format + "}" : "{0:" + KenandyErp.DateTimeFormat + "}";
            		columns[i].editor = function(container, options) {
            			var field = options.field;
            			var column = _.where(columns, {field: field})[0];
    					var required = column.required ? " required='required' data-required-msg='" + column.title + " is required'" : "";
						var minDate = KenandyErp.ParseSFDCDateTime(column.min);
                        var maxDate = KenandyErp.ParseSFDCDateTime(column.max);
						
                    	$('<input ' + required + ' name="' + field + '" data-title="' + column.title + '" data-bind="value:' + field + '" />')
						    .appendTo(container)
						    .kendoDateTimePicker({
						    	culture: KenandyErp.Culture,
						    	format: KenandyErp.DateTimeFormat,
						    	min: minDate ? minDate : undefined,
						    	max: maxDate ? maxDate : undefined
						    });
                        
                        $('<span class="k-invalid-msg" data-for="' + field + '"></span>').appendTo(container);
            		}
            	}
            	else if (columns[i].fieldtype == this.ColumnType.Boolean) {
            		columns[i].width = columns[i].width?columns[i].width:60;
            		columns[i].headerAttributes = { "class": "kndy-text-center" };
    				columns[i].attributes = { "class": "kndy-text-center" };
                    columns[i].template = (columns[i].template) ? columns[i].template : $.proxy(this.ResolveBoolean, { field: columns[i].field });
                }
            	else if (columns[i].fieldtype == this.ColumnType.Picklist) {
            		//columns[i].width = 120;
            		columns[i].template = (columns[i].template) ? columns[i].template : $.proxy(this.ResolvePicklist, { field: columns[i].field, selectList: columns[i].selectList });
            		columns[i].editor = function(container, options) {
            			var column = _.where(columns, {field: options.field})[0];
            			var list = column.selectList;
    					var required = column.required ? " required='required' data-required-msg='" + column.title + " is required'" : "";
    					
            			$('<input ' + required + ' name="' + options.field + '" data-bind="value:' + options.field + '" />')
                        .appendTo(container)
                        .kendoDropDownList({
                        	valuePrimitive: true,
                        	dataValueField: 'value',
                        	dataTextField: 'text',
                            dataSource: list
                        });
                        
                        $('<span class="k-invalid-msg" data-for="' + options.field + '"></span>').appendTo(container);
            		}
            	}
            	else if (columns[i].fieldtype == this.ColumnType.Reference) {
            		var lookupSearchAction = (config) ? config.lookupSearchAction : '';
	                
            		//columns[i].width = 160;
            		
            		var field = columns[i].field;
                    
                    // Fetching and registering sortable for all lookup columns
                    var getRefField = function(fieldPath){
                        return function(){
                            return fieldPath;    
                        };
                    }(columns[i].field);
                    
    				columns[i].sortable = {
        										compare: (function(refField) {
                                                    		return function(a, b, descending){
                                                                if(refField){
                                                                    if (refField.endsWith('__c')) {
                                                                        refField = refField.replace(/__c/, '__r');
                                                                    } else if (refField.toLowerCase().endsWith('id')) {
                                                                        refField = refField.substring(refField, refField.length - 2);
                                                                    }
                                                                      
                                                                    var aValue='', bValue='';
                                                                      
                                                                    if(a[refField] != null){
                                                                        aValue = a[refField].Name;
                                                                    }
                                                                      
                                                                    if(b[refField] != null){
                                                                        bValue = b[refField].Name;
                                                                    }
                                                                    
                                                                    if(aValue == null){
                                                                        return -1;
                                                                    }
                                                                    else 
                                                                    if(bValue == null){
                                                                        return 1;
                                                                    }
                                                                    else{
                                                                        return aValue.localeCompare(bValue);
                                                                    }
                                                                    
                                                                }else{
                                                                    return 0;
                                                                }
                                                       		};
                                                        })(columns[i].field)
                                        }
							              
            		columns[i].template = (columns[i].template) ? columns[i].template : $.proxy(this.ResolveLookup, { field: columns[i].field });
            		columns[i].editor =  (columns[i].editor) ? columns[i].editor : function(container, options) {
            			// get the current model
    					var model = options.model;
    					var field = options.field;
    					var column = _.where(columns, {field: options.field})[0];
    					var required = column.required ? " required='required' data-required-msg='" + column.title + " is required'" : "";
    					var refField = field;
    					var validateLookupOnBlur = (column.validateLookupOnBlur)?column.validateLookupOnBlur:(config && config.validateLookupOnBlur) ? config.validateLookupOnBlur : false;
    					
                   		if (refField.endsWith('__c')) {
                    	    refField = refField.replace(/__c/, '__r');
                    	} else if (refField.toLowerCase().endsWith('id')) {
                    	    refField = refField.substring(refField, refField.length - 2);
                    	}
        	
    					var autoComplete = $('<input ' + required + ' name="' + options.field + '" data-title="' + column.title + '" data-bind="value:' + refField + '.Name" />')
					    .appendTo(container)
					    .kendoLookup({
                        	minLength: 2, 
                        	dataValueField: 'value',
                        	dataTextField: 'text',
                        	value: (options.model.get(refField) && options.model.get(refField + '.Name')) ? options.model.get(refField + '.Name') : null,
                        	criteria: config.lookupSearchFilters,
                        	dataSource: {
                        		transport: {
                        			read: function(options) {
                        				if (!autoComplete.data('kendoLookup')) {
                        					return;
                        				}
       				
				    					var filterCriteria = '';
				    					var lookupSearchFilters = (autoComplete.data('kendoLookup').options.criteria) ? autoComplete.data('kendoLookup').options.criteria : config.lookupSearchFilters;
					            		
					            		// apply additional filter criteria
					            		if (lookupSearchFilters) {
					            			filterCriteria = _.where(lookupSearchFilters, { field: field });
					            			filterCriteria = (filterCriteria.length > 0) ? filterCriteria[0].filter : '';
					            		}
					            		
				    					// set additional filter criteria
				    					if (filterCriteria) {
				    						var filterCriteriaTemplate = kendo.template(filterCriteria);
				    						
											filterCriteria = filterCriteriaTemplate(model);
				    					}

						            	Visualforce.remoting.Manager.invokeAction(
		            						lookupSearchAction,
						                	autoComplete.val(),
						                	column.referenceTo,
						                	filterCriteria,
						                	function (result, event) {
							                    if (event.type == 'exception') {
							                        KenandyErp.Alert(event.message);
							                    } else {
							                        options.success(result);
							                    }
						                	},
						                	{escape: false}
						                );
						            }
                        		},
                        		serverFiltering: true
                        	},
                        	suggest: false,
                        	highlightFirst: config.highlightFirst || false,
                        	filter: "contains",
                        	placeholder: ($.support.placeholder) ? "Type to search " + column.title + "..." : "",
                        	select: function(e) {
                        		var dataItem;
                        		
                        		if (e.item && e.item.index() != -1) {
                        			dataItem = this.dataItem(e.item.index());
                        			
                        			if (!validateLookupOnBlur) {
                        				autoComplete.removeProp('valid');
                        			}
                        		}
                        		else {
                        			dataItem = { value: null, text: sanitize(autoComplete.val()) };
                        			
                        			if (!validateLookupOnBlur) {
                        				autoComplete.prop('valid', false);
                        			}
                        		}
                        		
                        		// update current model
                        		if (dataItem) {
				                    KenandyErp.KendoGridOptions.SetLookupModel(model, dataItem, field, refField);
				                }
                        	},
                              filtering: function(e) {
                                  var filter = e.filter;

                                  if (!filter.value && config.highlightFirst) {
                                    //prevent filtering if the filter does not value
                                    e.preventDefault();
                                  }
                              },
                        	change: function(e) {
                        		var dataItem;
                        		var testCondition = config.highlightFirst ? (this.current() && this.value().length > 1) : (this.current() && this.current().index() != -1);
                                if(testCondition){
				                    dataItem = this.dataItem(this.current().index());
				                    
				                    if (!validateLookupOnBlur) {
                        				autoComplete.removeProp('valid');
                        			}
                        		}
                        		else {
                        			dataItem = { value: null, text: autoComplete.val() };                   		
                        			
                        			if (!validateLookupOnBlur) {                  		
                        				autoComplete.prop('valid', false);
                        			}
                        		}
                        		
                        		if (dataItem) {                        		
                        			KenandyErp.KendoGridOptions.SetLookupModel(model, dataItem, field, refField);
								}
                        	}
                        });
                        
                        if (validateLookupOnBlur) {
	                        autoComplete.bind('blur', function(e) {
	                        	if (model.get(field) || autoComplete.val().trim() == '' || !autoComplete.data('kendoLookup')) {
	            					return;
	            				}
	            				
		    					var filterCriteria = '';
		    					var lookupSearchFilters = (autoComplete.data('kendoLookup').options.criteria) ? autoComplete.data('kendoLookup').options.criteria : config.lookupSearchFilters;
			            		
			            		// apply additional filter criteria
			            		if (lookupSearchFilters) {
			            			filterCriteria = _.where(lookupSearchFilters, { field: field });
			            			filterCriteria = (filterCriteria.length > 0) ? filterCriteria[0].filter : '';
			            		}
			            		
		    					// set additional filter criteria
		    					if (filterCriteria) {
		    						var filterCriteriaTemplate = kendo.template(filterCriteria);
		    						
									filterCriteria = filterCriteriaTemplate(model);
		    					}

		    					var isLookupSet = false;

		    					if(validateLookupOnBlur === 'Promise') {
                                    KenandyErp.lookupPromise = new Promise(function(resolve, reject) {
                                        Visualforce.remoting.Manager.invokeAction(
                                            lookupSearchAction,
                                            autoComplete.val(),
                                            column.referenceTo,
                                            filterCriteria,
                                            function (result, event) {
                                                if (event.type == 'exception') {
                                                    KenandyErp.Alert(event.message);
                                                } else {
                                                    for (var iLookup = 0; iLookup < result.length; iLookup++) {
                                                        if (autoComplete.val().toLowerCase() === result[iLookup].text.toLowerCase()) {
                                                            var dataItem = { value: result[iLookup].value, text: result[iLookup].text };
                                                            KenandyErp.KendoGridOptions.SetLookupModel(model, dataItem, field, refField);
                                                            isLookupSet = true;
                                                            resolve();
                                                            break;
                                                        }
                                                        if(!isLookupSet && result.length > 0) {
                                                            var dataItem = { value: result[0].value, text: result[0].text };
                                                            KenandyErp.KendoGridOptions.SetLookupModel(model, dataItem, field, refField);
                                                            isLookupSet = true;
                                                            resolve();
														}
                                                    }
                                                }
                                            },
                                            {escape: false}
                                        );
									})
								} else {
                                    Visualforce.remoting.Manager.invokeAction(
                                        lookupSearchAction,
                                        autoComplete.val(),
                                        column.referenceTo,
                                        filterCriteria,
                                        function (result, event) {
                                            if (event.type == 'exception') {
                                                KenandyErp.Alert(event.message);
                                            } else {
                                                for (var iLookup = 0; iLookup < result.length; iLookup++) {
                                                    if (autoComplete.val().toLowerCase() === result[iLookup].text.toLowerCase()) {
                                                        var dataItem = { value: result[iLookup].value, text: result[iLookup].text };
                                                        KenandyErp.KendoGridOptions.SetLookupModel(model, dataItem, field, refField);
                                                        isLookupSet = true;
                                                        break;
                                                    }
                                                    if(!isLookupSet && result.length > 0) {
                                                        var dataItem = { value: result[0].value, text: result[0].text };
                                                        KenandyErp.KendoGridOptions.SetLookupModel(model, dataItem, field, refField);
                                                        isLookupSet = true;
                                                    }
                                                }
                                            }
                                        },
                                        {escape: false}
                                    );
								}
	                        });
	                    }
                        
                        $('<span class="k-invalid-msg" data-for="' + options.field + '"></span><span data-valmsg-for="' + options.field + '"></span>').appendTo(container);
            		}
            	}
        
                else if (columns[i].fieldtype == this.ColumnType.Name && columns[i].editable==false) {
                       
                    var nameEsc = '#='+sanitize(columns[i].field)+'#';
                    var idEsc = "#="+sanitize(columns[i].referenceTo)+"#";
                    //columns[i].template  = KenandyErp.getLookupHoverDetailTemplate(id,name );
                    if(columns[i].nonhoverable){
                    	columns[i].template = KenandyErp.LookupDetail(idEsc, nameEsc);

                    } else{
                    columns[i].template = KenandyErp.LookupHoverDetail(idEsc,nameEsc);
                    }
                    
                    
                    
                        
                    
                }
                //END new code
            	else if (columns[i].fieldtype == this.ColumnType.Id) {
            		//columns[i].width = 80;
            	}
            	else if (columns[i].fieldtype == this.ColumnType.String) {
            		//columns[i].width = 100;
            		columns[i].encoded = false;
            		columns[i].editor = function(container, options) {
            			var column = _.where(columns, {field: options.field})[0];
    					var required = column.required ? " required='required' data-required-msg='" + column.title + " is required'" : "";
    					
            			$('<input ' + required + ' class="k-textbox" name="' + options.field + '" data-title="' + column.title + '" data-bind="value:' + options.field + '" />')
                        .appendTo(container);
                        
                        $('<span class="k-invalid-msg" data-for="' + options.field + '"></span><span data-valmsg-for="' + options.field + '"></span>').appendTo(container);
            		}
            		
            		//KNDY4-8465 prevent XSS
					columns[i].template = '#= ('+columns[i].field+' == null) ? "" : sanitize('+columns[i].field+') #';        		
            	}
            	
            	if (columns[i].required && columns[i].editable) {
					columns[i].headerTemplate =  (columns[i].headerTemplate) ? columns[i].headerTemplate : '<img width="12" height="12" title="Required" src="/img/ple/required12.gif" class="Requiredtrue">' + columns[i].title;
					
				} 
            	
            	// add footer template for aggregates
            	if (columns[i].aggregate) {
            		columns[i].footerTemplate = (columns[i].footerTemplate) ? columns[i].footerTemplate : $.proxy(this.RenderFooterColumn, { field: columns[i].field, aggregate: columns[i].aggregate, format: columns[i].format });
            	}  
            	
            	
            	//If wrapHeader of the columns fieldlist is set to true, set the header-attribute style to wrap KNDY-10623
            	if(columns[i].wrapHeader){            		
            		columns[i].headerAttributes = columns[i].headerAttributes || {};
            		columns[i].headerAttributes.style='white-space: normal;height: auto';
            	}
            	//If unwrapBody of the columns fieldlist is set to true, set the cell-attribute style to be cut-off with an ellipse to show more data KNDY-10623
            	if(columns[i].unwrapBody){
            		columns[i].attributes = columns[i].attributes || {};
            		columns[i].attributes.style='white-space: nowrap;text-overflow: ellipsis';
            	}
            }  
            
            columnKeys = [this.FieldInfo.FieldType, this.FieldInfo.Editable, this.FieldInfo.Required, this.FieldInfo.SelectList, this.FieldInfo.ReferenceTo, this.FieldInfo.Scale, this.FieldInfo.Aggregate]

			var allowMassDelete = (config && config.allowMassDelete) ? config.allowMassDelete : false;
			var commands = [];
			var actionColumnButtons = (config && config.actionColumnButtons) ? config.actionColumnButtons : [];
            var actionColumnWidth = (config && config.actionColumnWidth) ? config.actionColumnWidth : null;
			
            // add delete command button
            var buttons = (config) ? config.buttons : [];
            if ((!allowMassDelete) && _.contains(buttons, this.CommandType.Delete)) {
				
				commands.push({ name: "delete-command", text: "", template: "<input type='button' value='Delete' class='btn grid-delete-command' />" });
			}
			
			for (var i = 0; i < actionColumnButtons.length; i++) {
				var actionColumnButton = actionColumnButtons[i];
				if (actionColumnButton != null) {
					var template = '';
				
					if (typeof actionColumnButton === "object") {
						commands.push(actionColumnButton);
					} else if (actionColumnButton.indexOf('|') != -1) {
		    				var buttonConfig = actionColumnButton.split('|');
		    				var name = buttonConfig[0].toLowerCase().replace(/\s+/g, '-');
		    				var title = buttonConfig[0];
		    				
		    				commands.push({ name: name + "-custom-command", text:"", template: "<input type='button' value='" + title + "' class='btn grid-" + name + "-custom-command' />" });
		    			} else if (actionColumnButton.trim() != '') {
		    				var name = actionColumnButton.toLowerCase().replace(/\s+/g, '-');
		    				var title = actionColumnButton;
		    				
		    				commands.push({ name: name + "-custom-command", text:"", template: "<input type='button' value='" + title + "' class='btn grid-" + name + "-custom-command' />" });
		    			}
		    		}
			}
			//KNDY-13289 - Made change if more than one button in action column title would be Actions
			if(commands.length > 1){
                var index = (config.actionColumnPos !== undefined && (config.actionColumnPos <= columns.length || config.actionColumnPos >= 0)) ? config.actionColumnPos : columns.length;
				columns.splice(index, 0, { command: commands, title: "Actions", width: actionColumnWidth != null ? actionColumnWidth : commands.length * 60, locked: config.locked ? true : false });
            }
			else if(commands.length > 0){
				//Insert it first, last or enter the column number
				var index = (config.actionColumnPos !== undefined && (config.actionColumnPos <= columns.length || config.actionColumnPos >= 0)) ? config.actionColumnPos : columns.length;
				columns.splice(index, 0, { command: commands, title: "Action", width: actionColumnWidth != null ? actionColumnWidth : commands.length * 60, locked: config.locked ? true : false });
				}
			return _.map(columns, function(obj) { return _.omit(obj, columnKeys); });
       	},
       	
        ResolveBoolean: function(model) {            
            var value = model.get(this.field);     
            return value ? '<div class="kndy-text-center">&#10004;</div>' : '';  
        }, 

       	ResolvePicklist: function(model) {
       		// resolves the picklist value

       		// KNDY-18217 for picklist fields, display picklist label and not api name
       		var selectList = this.selectList;
       		var picklistLabel = '';
       		var picklistfieldVal = model.get(this.field);
       		selectList.map(function(val,index){
       			if(!picklistLabel && val.value == picklistfieldVal){
       				picklistLabel = val.text;
       			}
       		});

       		//KNDY4-8465 prevent XSS
       		var value = sanitize(picklistLabel);
       		return (value) ? value : '';
       	},
       	
       	ResolveLookup: function(model) {
       		// resolves the lookup field name
       		var refField = this.field;

       		if (refField.endsWith('__c')) {
        	    refField = refField.replace(/__c/, '__r');
        	} else if (refField.toLowerCase().endsWith('id')) {
        	    refField = refField.substring(refField, refField.length - 2);
        	}
       		
       		var id = model.get(refField + '.Id');
       		var name = model.get(refField + '.Name');
       		
       		id = (id) ? id : '';
       		name = (name) ? name : '';

			//KNDY4-8465 prevent XSS
       		id = sanitize(id);
       		name = sanitize(name);
       		
       		if (id != '' && name != '') {
				name = KenandyErp.LookupHoverDetail(id, name);
       		}
       		
			return name;
       	},
       	
       	SetLookupModel: function(model, item, field, refField) {
       		// update the current model for the lookup field
       		var value = (item.value) ? item.value : null;
       		var text = (item.text) ? item.text : null;
       		
			if (!model.get(refField)) { 
				model.set(refField, {}); 
			}

			if (item.sobjectMap != null){
			    delete item.sobjectMap['attributes'];
                model.set(refField, item.sobjectMap);
            } else {
                model.set(refField, { Id: value, Name: text });
            }
//			model.set(refField, { Id: value, Name: text });
			model.set(field, value);
       	},
       	
       	RenderFooterColumn: function(model) {
       		var field = this.field;
       		var aggregate = this.aggregate;
       		var format = this.format;
       		var result = '';
       		
       		switch(aggregate)
			{
			   case KenandyErp.KendoGridOptions.AggregateType.Average:
			   		result = 'Average: ' + model[field].average;
			   		break;
			   case KenandyErp.KendoGridOptions.AggregateType.Count:
			   		result = 'Count: ' + model[field].count;
			   		break;
			   case KenandyErp.KendoGridOptions.AggregateType.Max:
			   		result = 'Max: ' + model[field].max;
			   		break;
				case KenandyErp.KendoGridOptions.AggregateType.Min:
			   		result = 'Min: ' + model[field].min;
			   		break;
			   	case KenandyErp.KendoGridOptions.AggregateType.Sum:
			   		result = 'Total: ' + kendo.format(this.format, model[field].sum);
			   		break;
			   		
			   	default: 
			    	break;
			}
			
			return result;
       	},
       	
       	GetToolbarButtons: function(buttons, options) {
       		var toolbarButtons = [];
			var showIconButtons = (options && options.showIconButtons) ? options.showIconButtons : false;
			var allowMassDelete = (options && options.allowMassDelete) ? options.allowMassDelete : false;
			var hasColumnMenu = false;
			
			if (!buttons) return toolbarButtons;
			
			for (var i = 0; i < buttons.length; i++) {
				var button = buttons[i];
				var template = '';
				
				if ((!allowMassDelete) && button == this.CommandType.Delete) continue;
				
				if (button == this.CommandType.Create) {
					//template = (showIconButtons) ? "<a class='k-button' title='Add New'><span class='k-icon k-i-plus grid-create-command'></span></a>" : "<input type='button' value='Add New' class='btn grid-create-command' />";
					template = (showIconButtons) ? "<a class='k-button' title='Add New'><span class='fa fa-plus-circle fa-lg kndy-green grid-create-command'></span></a>" : "<input type='button' value='Add New' class='btn grid-create-command' />";
					toolbarButtons.push({ name: "create-command", text:"", template: template });
				} 
				else if (button == this.CommandType.Save) {
					template = (showIconButtons) ? "<a class='k-button' title='Save Changes'><span class='fa fa-floppy-o fa-lg kndy-green grid-save-command'></span></a>" : "<input type='button' value='Save Changes' class='btn grid-save-command' />";
					toolbarButtons.push({ name: "save-command", text:"", template: template });
				} 
				else if (button == this.CommandType.Cancel) {
					template = (showIconButtons) ? "<a class='k-button' title='Cancel Changes'><span class='fa fa-ban fa-lg kndy-red grid-cancel-command'></span></a>" : "<input type='button' value='Cancel Changes' class='btn grid-cancel-command' />";
					toolbarButtons.push({ name: "cancel-command", text:"", template: template });
				} 
				else if (button == this.CommandType.Delete) {
					template = (showIconButtons) ? "<a class='k-button' title='Delete'><span class='fa fa-trash fa-lg kndy-red grid-mass-delete-command'></span></a>" : "<input type='button' value='Delete' class='btn grid-mass-delete-command' />";
					toolbarButtons.push({ name: "mass-delete-command", text:"", template: template });
				}
				else if (button == this.CommandType.Clone) {
					template = (showIconButtons) ? "<a class='k-button' title='Clone'><span class='fa fa-files-o fa-lg kndy-blue grid-clone-command'></span></a>" : "<input type='button' value='Clone' class='btn grid-clone-command' />";
					toolbarButtons.push({ name: "clone-command", text:"", template: template });
				} 
				else if (button == this.CommandType.Search) {
					var placeholder = ($.support.placeholder) ? "Type to search..." : "";
					
					template = (showIconButtons) ? '<span class="toolbar-filter k-textbox k-space-left"><input type="text" class="k-textbox grid-search-command" placeholder="' + placeholder + '" /><i class="k-icon k-i-search">&nbsp;</i></span>' : '<span class="toolbar-filter">Search: <input type="text" class="k-textbox grid-search-command" placeholder="' + placeholder + '" /></span>';
					toolbarButtons.push({ template: template });
				}
				else if (button == this.CommandType.AddRow) {
					toolbarButtons.push({ name: "add-row-command", text:"", template: "<input type='button' value='Add New' class='btn grid-add-row-command' />" });
				}
				else if (button == this.CommandType.ColumnMenu) {
					hasColumnMenu = true;
				}
				else if (button == this.CommandType.Print) {
					template = (showIconButtons) ? "<a class='k-button' title='Print'><span class='fa fa-print fa-lg kndy-blue grid-print-command'></span></a>" : "<input type='button' value='Print' class='btn grid-print-command' />";
					toolbarButtons.push({ name: "print-command", text:"", template: template });
				}
				else if (button == this.CommandType.ExportExcel) {
					template = (showIconButtons) ? "<a class='k-button' title='Export Excel'><span class='fa fa-file-excel-o fa-lg kndy-green grid-export-excel-command'></span></a>" : "<input type='button' value='Export Excel' class='btn grid-export-excel-command' />";
					toolbarButtons.push({ name: "export-excel-command", text:"", template: template });
				}
				else if (button == this.CommandType.ExportPdf) {
					template = (showIconButtons) ? "<a class='k-button' title='Export PDF'><span class='fa fa-file-pdf-o fa-lg kndy-brown grid-export-pdf-command'></span></a>" : "<input type='button' value='Export PDF' class='btn grid-export-pdf-command' />";
					toolbarButtons.push({ name: "export-pdf-command", text:"", template: template });
				}
				else {
					if (button.indexOf('|') != -1) {
						var buttonConfig = button.split('|');
						var name = buttonConfig[0].toLowerCase().replace(/\s+/g, '-');
						var title = buttonConfig[0];
						
						toolbarButtons.push({ name: name + "-custom-command", text:"", template: "<input type='button' value='" + title + "' class='btn grid-" + name + "-custom-command' />" });
					}
					else if (button.trim() != '') {
						var name = button.toLowerCase().replace(/\s+/g, '-');
						var title = button;
						
						toolbarButtons.push({ name: name + "-custom-command", text:"", template: "<input type='button' value='" + title + "' class='btn grid-" + name + "-custom-command' />" });
					}
				}
			}
						
			if (hasColumnMenu) {
				var template = "&nbsp;<a title='Show/Hide Columns'><ul class='grid-column-menu-command'><li class='grid-column-menu-list'><span class='k-icon k-i-columns'></span></li></ul></a>&nbsp;";
				
				toolbarButtons.push({ name: "column-menu-command", text:"", template: template });
			}
						
			return toolbarButtons;
       	},
		
		BindEvents: function(grid, buttons, options) {
			if (!buttons) return;
			
			for (var i = 0; i < buttons.length; i++) {
				var button = buttons[i];
				
				if (options.ignoreBindings && _.contains(options.ignoreBindings, button)) continue;
				
				//Bind to a table or to the lockedTable
 				var gridToBind = grid.lockedTable || grid.wrapper;
 
				if (button == this.CommandType.Create) {	
					grid.wrapper.on("click", ".grid-create-command", $.proxy(KenandyErp.KendoGridActions.Create, { grid: grid }));
				}
				else if (button == this.CommandType.Save) {
					grid.wrapper.on("click", ".grid-save-command", $.proxy(KenandyErp.KendoGridActions.Save, { grid: grid, options: options }));
				}
				else if (button == this.CommandType.Cancel) {
					grid.wrapper.on("click", ".grid-cancel-command", $.proxy(KenandyErp.KendoGridActions.Cancel, { grid: grid }));
				}
				else if (button == this.CommandType.Delete) {
					if (grid.wrapper.find('.grid-mass-delete-command').length > 0) {
						grid.wrapper.on("click", ".grid-mass-delete-command", $.proxy(KenandyErp.KendoGridActions.MassDelete, { grid: grid }));
					}
					else {
						grid.table.on("click", ".grid-delete-command", $.proxy(KenandyErp.KendoGridActions.Delete, { grid: grid }));
					}
				}
				else if (button == this.CommandType.Clone) {
					grid.wrapper.on("click", ".grid-clone-command", $.proxy(KenandyErp.KendoGridActions.Clone, { grid: grid }));
				}
				else if (button == this.CommandType.Search) {
					grid.wrapper.on("keyup", ".grid-search-command", $.proxy(KenandyErp.KendoGridActions.Search, { grid: grid, options: options }));
				}
				else if (button == this.CommandType.AddRow) {
					grid.wrapper.on("click", ".grid-add-row-command", $.proxy(KenandyErp.KendoGridActions.AddRow, { grid: grid, options: options }));
				}
				else if (button == this.CommandType.ColumnMenu) {
					var columnsList = $('<ul />');	                
		           	var listItem;
				    
				    for (var j = 0, max = grid.columns.length; j < max; j++) {
				    	if (grid.columns[j].title && !grid.columns[j].hidden) {
				    		listItem = $('<li/>');
				            listItem.html("<label><input type='checkbox' checked='checked' " +
						              " class='check' data-field='" + sanitize(grid.columns[j].field) + 
						              "'/>" + sanitize(grid.columns[j].title) + "</label>");							
							columnsList.append(listItem);
				        }
				    }
		            
		            columnsList.appendTo(grid.wrapper.find('.grid-column-menu-list'));
		            
					grid.wrapper.find('.grid-column-menu-command').kendoMenu({
					    openOnClick: true,
					    closeOnClick: false,
					    open: function (e) {
					        var selector;
					        $.each(grid.columns, function () {
					            selector = "input[data-field='" + this.field + "']";
				                $(selector).prop("checked", !this.hidden);
					        });
					    	
					        if ($(e.item).parent().find("input:checked").length > 1) {
								$(e.item).parent().find("input:disabled").prop("disabled", false);
					    	}
					    },
					    select: function (e) {
					        var input = $(e.item).find("input.check");
					        
					        if (input.length == 1) {
						        var field = $(input).data("field");
					        
						        if ($(input).is(":checked")) {
						            grid.showColumn(field);
						        } else {
						            grid.hideColumn(field);
						        }
							}
							
							if ($(e.item).parent().find("input:checked").length == 1) {
					    		$(e.item).parent().find("input:checked").prop("disabled", true);
					    	} else {
					    		$(e.item).parent().find("input:disabled").prop("disabled", false);
					    	}
					    }
					});
				}
				else if (button == this.CommandType.Print) {
					grid.wrapper.on("click", ".grid-print-command", $.proxy(KenandyErp.KendoGridActions.Export, { grid: grid, format: KenandyErp.KendoGridOptions.ExportFormat.PrintableView, options: options }));
				}
				else if (button == this.CommandType.ExportExcel) {
					grid.wrapper.on("click", ".grid-export-excel-command", $.proxy(KenandyErp.KendoGridActions.Export, { grid: grid, format: KenandyErp.KendoGridOptions.ExportFormat.Excel, options: options }));
				}
				else if (button == this.CommandType.ExportPdf) {
					grid.wrapper.on("click", ".grid-export-pdf-command", $.proxy(KenandyErp.KendoGridActions.Export, { grid: grid, format: KenandyErp.KendoGridOptions.ExportFormat.Pdf, options: options }));
				}
				else {
					if (button.indexOf('|') != -1) {
						var buttonConfig = button.split('|');
						var name = buttonConfig[0].toLowerCase().replace(/\s+/g, '-');
						var action = buttonConfig[1];
                        var functionAction = window[action];
                        grid.wrapper.on("click", ".grid-" + name + "-custom-command", $.proxy(functionAction, { grid: grid, options: options }));
					}
				}
			}
		},
		
		ShowValidationError: function(cell, field, message) {
			var validationErrorTemplate = kendo.template(
											'<div class="k-widget k-tooltip k-tooltip-validation k-invalid-msg field-validation-error" style="margin: 0.5em; display: block; " data-for="#=field#" data-valmsg-for="#=field#" id="#=field#_validationError">' +
            									'<span class="k-icon k-warning"> </span>#=message#<div class="k-callout k-callout-n"></div>' +
        								  	'</div>');
        	
        	cell.find("[data-valmsg-for=" + field + "],[data-val-msg-for=" + field + "]")
				                        .replaceWith(validationErrorTemplate({ field: field, message: message }));						  
		}
	};       
}();

KenandyErp.KendoGridActions = function() {

   	return {
   		Create: function(e) {
   			var self = this;
   			var grid = self.grid;
   			
   			// clear filters
			grid.wrapper.find(".search-filter").val('');
			
			if (grid.dataSource.total() > 0) {
				grid.dataSource.filter({});
    			grid.dataSource.sort({});
    		}
    		
			grid.addRow();
   		},
   		
   		AddRow: function(e) {
   			var self = this;
   			var grid = self.grid;
   			var namespace = self.options.config.namespace; 
   			var messageElement = grid.element.closest("div.grid-container").find("div.grid-message");
   			
   			// clear filters
			grid.wrapper.find(".search-filter").val('');
			
			if (grid.dataSource.total() > 0) {
				grid.dataSource.filter({});
    			grid.dataSource.sort({});
    		}
								
			KenandyErp.BlockUI(grid.element);
								
			Visualforce.remoting.Manager.invokeAction(
			    self.options.addRowAction,			     	        
				self.options.config.addRow,
				self.options.config.addReference,
				function (result, event) {
					KenandyErp.UnBlockUI(grid.element);
							    	
					if (event.type == 'exception') {
						KenandyErp.Message(event.message, KenandyErp.MessageType.Error, messageElement);
					} else {
						if (result.success) {
							KenandyErp.CleanNamespace(result.records, namespace);
							var newRow = (result.records.length > 0) ? result.records[0] : null;
							
							// check if the grid is of type action list
							if (newRow && _.where(grid.columns, {field: "IsSelected__custom"}).length > 0) {
								newRow.IsSelected__custom = null;
							}
							
							grid.dataSource.insert(0, newRow);
							grid.editRow(grid.tbody.children().first());
						}
						else {
							KenandyErp.Messages(result.messages, messageElement);
						}
					}
				},
				{escape: false}
			);
   		},
   		
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
        				
			KenandyErp.BlockUI(grid.element);
							
			var dateFields = self.options.dateFields ? _.pluck(self.options.dateFields, KenandyErp.KendoGridOptions.FieldInfo.Field) : null;
			Visualforce.remoting.Manager.invokeAction(
		    	self.options.saveAction,			     	        
				gridUtils.UpdatedRows(), 
				gridUtils.NewRows(), 
				gridUtils.DeletedRows(), 
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
										
							// trigger onsavesuccess
							grid.element.trigger("OnSaveSuccess");
										
							KenandyErp.Messages(result.messages, messageElement);
						}
						else {
							KenandyErp.Messages(result.messages, messageElement);
							// Abhinav:change
							grid.element.trigger({
								type: "OnSaveFailure",
								result: result,
								event: event
							});
						}
					}
				},
				{escape: false}
			);
   		},
   		
   		Cancel: function(e) {
   			var self = this;
   			var grid = self.grid;
   			
   			grid.cancelChanges();
   			e.stopPropagation();
   		},
   		
   		Delete: function(e) {
   			var self = this;
   			var grid = self.grid;
   			
   			var row = $(e.target).closest("tr"); //get the row for deletion
           	var dataItem = grid.dataItem(row); // get the row data
           	
           	grid.dataSource.remove(dataItem);
   		},
   		
   		Clone: function(e) {
   			var self = this;
   			var grid = self.grid;
   			var selectedRows = [];
   			var gridDataSource = grid.dataSource;
   			var modelIdField = grid.dataSource.options.schema.model.idField;
   			var fields = (grid.dataSource.options.schema && grid.dataSource.options.schema.model) ? grid.dataSource.options.schema.model.fields : {};
			var dateFields = [];
			
			$.map(Object.keys(fields), function(key) {	 
				var item = fields[key];
				
				if (item['type'] == KenandyErp.KendoGridOptions.ColumnType.Date
					|| item['type'] == KenandyErp.KendoGridOptions.ColumnType.DateTime) {	 
					dateFields.push({ field: key, fieldtype: item['type'] });
				} 
			});
			
			selectedRows = $.map(grid.dataSource.data(), function(item, index) {
				if (item.IsSelected__custom) {
					return item;
				}
			});
			
			if (selectedRows.length > 0) {
		        $.each(selectedRows, function (idx, elem) {
		        	var item = JSON.parse(JSON.stringify(elem));
		        	
		        	Serializer.ConvertFromSFDCDate(item, { dateFields: dateFields });
		        	item['IsSelected__custom'] = false;
		        	JSONUtils.Set(item, modelIdField, null);
		        	
		            grid.dataSource.insert(0, item);
		        });
		    }
   		},
   		
   		MassDelete: function(e) {
   			var self = this;
   			var grid = self.grid;
   			var selectedRows = [];
   			var gridDataSource = grid.dataSource;
								
			selectedRows = $.map(grid.dataSource.data(), function(item, index) {
				if (item.IsSelected__custom) {
					return item;
				}
			});
			
	        $.each(selectedRows, function (idx, elem) {
	            gridDataSource.remove(elem);
	        });
   		},
   		
   		ColumnMenu: function() {
   			var self = this;
   			var grid = self.grid;
   			
   			var ds = [];
					
			for (var i = 0, max = grid.columns.length; i < max; i++) {
				if (grid.columns[i].title && !grid.columns[i].hidden) {
				    ds.push({
				        encoded: false,
				        text: "<label><input type='checkbox' checked='checked' " +
				              " class='check' data-field='" + grid.columns[i].field + 
				              "'/>" + grid.columns[i].title + "</label>"
				    });
			    }
			}
			
			$('<div class="grid-column-menu" />').appendTo(grid.wrapper.find('.grid-column-menu-command')).kendoMenu({
				dataSource: ds,
			    openOnClick: true,
			    closeOnClick: false,
			    open: function () {
			        var selector;
			        $.each(grid.columns, function () {
			            if (this.hidden) {
			                selector = "input[data-field='" + this.field + "']";
			                $(selector).prop("checked", false);
			            }
			        });
			    },
			    select: function (e) {
			        // don't show/hide for menu button
			        if ($(e.item).parent().filter("div").length) return;
			
			        var input = $(e.item).find("input.check");
			        var field = $(input).data("field");
			        if ($(input).is(":checked")) {
			            grid.showColumn(field);
			        } else {
			            grid.hideColumn(field);
			        }
			    }
			});
   		},
   		
   		Select: function(e) {
   			var self = this;
   			var grid = self.grid;
   			var referenceFields = self.referenceFields;
   			var sortOrder = grid.dataSource.sort();
   			var row = $(e.target).closest("tr");
		  	var item = grid.dataItem(row);
		  	var isSelected = $(e.target).is(":checked");
		  	var isDirty = item.dirty;
		  
		  	if (!isSelected) {
		  		grid.thead.find('.grid-select-all').prop('checked', false);
		  	} else {
                grid.thead.find('.grid-select-all').prop('checked',grid.tbody.find('.grid-select-one').length > 0 && !grid.tbody.find('.grid-select-one').is(':not(:checked)'));
            }
		  
		  	item.IsSelected__custom = isSelected;
		  	
			if (!isDirty) {
				item.set('dirty', isDirty);
			}
			
			if (sortOrder) {
				if (!referenceFields) {
					referenceFields = [ ];
				}
			
				var newSortOrder = [ ];
				$.each(sortOrder, function(i,elem) {
					if (referenceFields.indexOf(elem.field) > -1) {
						var newField = elem.field.substring(0,elem.field.length - 1) + "r.Name";
					
						newSortOrder.push({ "field": newField, "dir": elem.dir });
					} else {
						newSortOrder.push(elem);
					}
				});
				
				grid.dataSource.sort(newSortOrder);
			}
   		},
   		
        SelectAll: function(e) {
            var self = this;
            var grid = this.grid;
            var state = $(e.target).is(":checked");

            $.each(grid.dataSource.view(), function() {
                var isDirty = this['dirty'];

                this['IsSelected__custom'] = state;

                if (!isDirty) {
                    this['dirty'] = isDirty;
                }
            });

            grid.refresh();
        },
       	
       	Edit: function(e) {
       		var self = this;
       		var specialKeys = [kendo.keys.UP, kendo.keys.DOWN];
		    var input = e.container.find('input');
		    
		    // Create dummy model for the reference fields
		    var referenceFields = self.referenceFields;

		    for (var i = 0; i < referenceFields.length; i++) {
            	var refField = referenceFields[i];
            	
            	if (refField.endsWith('__c')) {
            	    refField = refField.replace(/__c/, '__r');
            	} else if (refField.toLowerCase().endsWith('id')) {
            	    refField = refField.substring(refField, refField.length - 2);
            	}
				            
				// avoid setting non-existant fields. True for refField: 'Name' (custom set referenceField)
				if (!e.model.get(refField) && e.model.get(refField + '.Id') != null && e.model.get(refField + '.Name') != null) {
					var isDirty = e.model.dirty;
					
					e.model.set(refField, {});
					e.model.set(refField + '.Id', null);
					e.model.set(refField + '.Name', null);
					
					if (!isDirty) {
						e.model.set('dirty', isDirty);
					}
				}
			}
			 
			if (e.container.find('.k-numerictextbox').length > 0) {
				input.addClass("kndy-text-right");
				input.on('focus', function() {
					var that = $(this);
					setTimeout(function() {
						if (!kendo.support.browser.safari) {
							that.select();
						}
					});
				});
				input.focus();
			}
			else if (e.container.find('.k-dropdown').length > 0) {
				input = e.container.find('.k-dropdown').focus();
						
				input.keydown(function(e) {
					if ($.inArray(e.keyCode, specialKeys) >= 0) {
						e.stopImmediatePropagation();
					}
				});
			} else {
				if (!kendo.support.browser.safari) {
					input.select();
				}
			}
       	},
       	
       	DataBound: function(e) {
		    if (e.sender.dataSource.total() == 0) {
		        var colCount = e.sender.columns.length;
		        
		        $(e.sender.wrapper)
		            .find('.k-grid-content tbody')
		            .append('<tr class="kndy-grid-empty"><td colspan="' + colCount + '" class="kndy-grid-empty-message">No records to display</td></tr>');
		    }
		},
		
		Search: function(e) {
			var self = this;
			var grid = self.grid;
			var referenceFields = self.options.referenceFields.join(',');
			var filter = { logic: "or", filters: [] };
			var searchValue = $(e.target).val().trim().toLowerCase();
			var fields = grid.dataSource.options.schema.model.fields;
			
	        if (searchValue) {
	            $.each(grid.columns, function(key, column) {
	            	// ignore hidden, command and custom columns (ending with __custom) from search
	                if ((!column.field) || column.hidden || column.command || (/__custom$/i.test(column.field))) { 
	                	return;
	                }
	                	
	                if (fields[column.field].type == "string" && referenceFields.indexOf(column.field) != -1) {
	                	var field = column.field;
            	
		            	if (field.endsWith('__c')) {
		            	    field = field.replace(/__c/, '__r');
		            	} else if (field.toLowerCase().endsWith('id')) {
		            	    field = field.substring(field, field.length - 2);
		            	}
		            	
	                    filter.filters.push({ field: field, 
					            operator: function(item) {
									var status = false;
									            
									if (item && item.Name && item.Name.toLowerCase().indexOf(searchValue) != -1) {
										status = true;
									}
									            
									return status;
								}				
							});
					}
	                else if (fields[column.field].type == "date" || fields[column.field].type == "number") {
	                	var format = fields[column.field].format;
	                    	
	                    filter.filters.push({ field: column.field, 
				        		operator: function(item) {
							    	var status = false;
							            
							        if (item && kendo.toString(item, format).toLowerCase().indexOf(searchValue) != -1) {
							        	status = true;
									}
							            
							        return status;
								}				
							});
					}
	                else if (fields[column.field].type == "boolean") {
	                	filter.filters.push({ field: column.field, 
				        		operator: function(item) {
							    	var status = false;
							            
							        if (item && item.toString().toLowerCase().indexOf(searchValue) != -1) {
							        	status = true;
									}
							            
							        return status;
								}				
						});
					}
	                else {
	                	filter.filters.push({ field: column.field, operator: "contains", value: searchValue });
					}
	            });
	        }
	        
	        grid.dataSource.filter(filter);
		},
		
		Export: function(e) {
			var self = this;
			var grid = self.grid;
			var options = self.options;
			var referenceFields = options.referenceFields.join(',');
			var format = self.format;
			var exportUrl = (format == KenandyErp.KendoGridOptions.ExportFormat.Excel) ? KenandyErp.ExportExcelUrl : KenandyErp.ExportPdfUrl;
     		var fields = grid.dataSource.options.schema.model.fields;
     		var currentPage = grid.dataSource.page();
			var columns = [];
     		var rows = [];
     		
     		// overrides the url with the custom report url
     		if (options && options.reportUrl) {
     			exportUrl = options.reportUrl;
     		}
     		//KNDY-17782 - change filename of excel with title of grid
     		if (options && options.config && options.config.title) {
     			exportUrl = exportUrl + '?filename=' + options.config.title;
     		}
     		// Get all columns
     		for (var i = 0; i < grid.columns.length; i++) {
	            var column = grid.columns[i];
	            
	            // ignore hidden, command and custom columns (ending with __custom) from search
	            if ((!column.field) || column.hidden || column.command || (/__custom$/i.test(column.field))) { 
	            	continue;
	            }
	            
	            columns.push({ field: column.field, title: column.title, fieldtype: fields[column.field].type });
	        }
	        //KNDY-17782 - get all selected rows if found any then use those set of rows.. if nothing selected then use full data. 
	        //				if all selected	then it will return all data
	        var selectedRows =[];
     		selectedRows = $.map(grid.dataSource.data(), function(item, index) {
				if (item.IsSelected__custom) {
					return item;
				}
			});
			
			if (selectedRows.length > 0) {
				
			}else if (selectedRows.length == 0){ // export full data so existing functionality won't break
				selectedRows = grid.dataSource.data()
			}
			//KNDY-17782 - end of change
     		// Get all rows  
		    $.each(selectedRows, function(index, item) {
		    	var row = {}; 			    	 
		       	for (var i = 0; i < columns.length; i++) {  
			        var column = columns[i];
			        
					if (fields[column.field].type == "string" && referenceFields.indexOf(column.field) != -1) {
	                	var field = column.field;
				
		           		if (field.endsWith('__c')) {
		            	    field = field.replace(/__c/, '__r');
		            	} else if (field.toLowerCase().endsWith('id')) {
		            	    field = field.substring(field, field.length - 2);
		            	}
            	
	                    row[column.field] = (item.get(field) && item.get(field).Name) ? item.get(field).Name : '';
					}
	                else if (fields[column.field].type == "date" || fields[column.field].type == "number") {
	                	var format = fields[column.field].format;
	                    
	                    row[column.field] = (item.get(column.field)) ? kendo.toString(item.get(column.field), format) : '';
					}
	                else if (fields[column.field].type == "boolean") {
	                    row[column.field] = (item.get(column.field)) ? item.get(column.field) : '';
					}
	                else {
	                	// Strip HTML characters
	                	var value = (item.get(column.field)) ? item.get(column.field) : '';
		                
		                //var html = $('<div />').append(value); //KNDY-9694: BAD!  This inserts into the DOM and causes XSS vulnerability.
		                //value = html.text().trim();

	                    row[column.field] = value;
					}
		       	}
		       	rows.push(row);
		       	
		    }); 

			// Get aggregates row
			if (grid.dataSource.total() > 0) {
				var aggregates = grid.dataSource.aggregates();
				
				if (!$.isEmptyObject(aggregates)) {
					var row = {};
					
					for (var i = 0; i < columns.length; i++) {  
			        	var column = columns[i];
			        	var field = column.field;
			        	var aggregateField = _.where(grid.dataSource.aggregate(), {field: field});
			       		var aggregate = (aggregateField.length > 0) ? aggregateField[0].aggregate : null;
			       		var result = '';
			       		
			       		switch(aggregate)
						{
						   case KenandyErp.KendoGridOptions.AggregateType.Average:
						   		result = 'Average: ';
						   		break;
						   case KenandyErp.KendoGridOptions.AggregateType.Count:
						   		result = 'Count: ';
						   		break;
						   case KenandyErp.KendoGridOptions.AggregateType.Max:
						   		result = 'Max: ';
						   		break;
							case KenandyErp.KendoGridOptions.AggregateType.Min:
						   		result = 'Min: ';
						   		break;
						   	case KenandyErp.KendoGridOptions.AggregateType.Sum:
						   		result = 'Total: ';
						   		break;
						   		
						   	default: 
						    	break;
						}
						
                        if (fields[field].format) {
                            row[column.field] = (result) ? kendo.format('{0:' + fields[field].format + '}', aggregates[field][aggregate]) : '';       
                        }
                        else {
                            row[column.field] = (result) ? aggregates[field][aggregate] : '';
                        }						
			        }
			        
			        rows.push(row);
				}
			}
			//KNDY-17782 - check for rows to be exported. if array contains 0 data then return else continue export 		 
			if (rows.length == 0) {
				KenandyErp.Alert('Records must be displayed before you can export to Excel.');
				return;
			}
		    grid.dataSource.page(currentPage);
		    
			$("#gridExportFrame").remove();
			$("#gridExportForm").remove();
			
    		$('body').append('<iframe id="gridExportFrame" style="display: none;" width="0px;" height="0px;" />');
    
			var gridExportForm = $('<form />').appendTo('body');
			
			var gridHeader = [];
			if ("exportHeader" in grid) {
				gridHeader =  grid.exportHeader;
			}
			
			$(gridExportForm).attr({
				'id': 'gridExportForm',
		        'action': exportUrl,
		        'method': 'post',
		        'target': 'gridExportFrame'
		    }).append($('<input />').attr({
		        'name': 'print',
		        'value': (format == KenandyErp.KendoGridOptions.ExportFormat.PrintableView) ? '1' : '0',
		        'type': 'hidden'
		    })).append($('<input />').attr({
		        'name': 'gridHeader',
		        'value': JSON.stringify(gridHeader),
		        'type': 'hidden'		    
		    })).append($('<input />').attr({
		        'name': 'gridColumns',
		        'value': JSON.stringify(columns),
		        'type': 'hidden'
		    })).append($('<input />').attr({
		        'name': 'gridRows',
		        'value': JSON.stringify(rows),
		        'type': 'hidden'
		    })).submit();
		},
        /**
          UpdateSelectOne is a function to set the IsSelected__custom of a row its checkbox is clicked and set to true.
        **/
        UpdateSelectOne: function(e){
                var self = this;
                //Get the grid object of the index selected
                var index      = e.target.parentElement.parentElement.rowIndex,
                    item       = self.grid.dataSource.data()[index],
                    isSelected = $(e.target).is(":checked"),
                    isDirty    = item.dirty,
                    theadCheckbox = $(self.grid.wrapper.find('table')[0]).find('thead tr th input.grid-select-all'),
                    tbodyCheckbox = $(self.grid.wrapper.find('table')[2]).find('tbody tr td input.grid-select-one');
                    if (!isSelected) {
                        //If even one checkbox is unselected, uncheck the thead checkbox
                        theadCheckbox.prop('checked', false);
                    }
                    else{
                        //set the thead checkbox if all the rows of the table are checked else uncheck it
                        theadCheckbox.prop('checked', tbodyCheckbox.length > 0 && !tbodyCheckbox.is(':not(:checked)'));
                    }
                    item.IsSelected__custom = isSelected;
                    if (!isDirty) {
                        item.set('dirty', isDirty);
                    }
        },
        /**
            UpdateSelectAll is a function to set the IsSelected__custom of all rows of the table when its clicked and set to true.
        **/
        UpdateSelectAll: function(e){
                var self = this,
                    grid = self.grid,
                    state = $(e.target).is(":checked");
                $.each(grid.dataSource.view(), function(){
                    var isDirty = this['dirty'];
                    this['IsSelected__custom'] = state;
                        if (!isDirty) {
                            this['dirty'] = isDirty;
                        }
                });
                grid.refresh();
        },
        /**
            Gets the width of the column based on the title text length
        **/
        GetWidth: function(len) {
            if(len < 12){return '120px';}
            else{ return (len*10)+'px';}
        },
		
   	};       
}();

/*
	Kendo Grid Utility functions
*/
var KendoGridUtils = function(grid, options) {
	var currentData = grid.dataSource.data();
	var modelIdField = grid.dataSource.options.schema.model.idField;
	var columns = grid.columns;
    var isDml = (options && options.hasOwnProperty('isDml')) ? options.isDml : true;
	
	var updatedRows = [];
    var newRows = [];
	
	// Abhinav:change
	if (options && options.hookPreSave) {
		options.hookPreSave(grid, options, rows);
		options.hookPreSave(grid, options, grid.dataSource._destroyed);
	}
	
	$.map(currentData, function(item, index) {
		if (!item.get(modelIdField) || item.dirty) {
			var isNewRow = (!item.get(modelIdField));
			 
			if (item.hasOwnProperty('rowGUID')) {
                item['rowGUID'] = item.uid;
            }
            
			item = item.toJSON();
			
			if (options) {
            	item = Serializer.ConvertToSFDCDate(item, { dateFields: options.dateFields });
			}
            
            // Remove the extra attributes Kendo Grid creates for supporting wrapper classes
            for (var i = 0; i < columns.length; i++) {
                var name = columns[i].field;
				if (name && name.indexOf('.') != -1) {
				    delete item[name];
				}
		    }
		    if (isNewRow) {
                if (modelIdField == 'Id') {
					delete item.Id;
					
					if (options && options.config && options.config.objectName) {
						item.sObjectType = options.config.objectName;
					}
				}
				
				if (options && options.config && options.config.parentField) {
					item[options.config.parentField] = options.config.parentRecord.Id;
				}
				                                
                newRows.push(item);
            }
            else {
                updatedRows.push(item);
            }
		}
	});
			
	var deletedRows = $.map(grid.dataSource._destroyed, function(item, index) {
		if (item.hasOwnProperty('rowGUID')) {
            item['rowGUID'] = item.uid;
        }
        
		item = item.toJSON();
			
		if (options) {
        	item = Serializer.ConvertToSFDCDate(item, { dateFields: options.dateFields });
		}
        
        // Remove the extra attributes Kendo Grid creates for supporting wrapper classes
        for (var i = 0; i < columns.length; i++) {
        	var name = columns[i].field;
                
			if (name && name.indexOf('.') != -1) {
				delete item[name];
			}
		}
		    
		return item;
	});
	
	return {
	
		/*
        	Check for any validation errors
        */
       	IsValid: function() {
       		if (grid.editable && !grid.editable.validatable.validate()) {
                return false;
            }
            
            return true;
       	},
       	
       	/*
       		Get all rows
       	*/
       	AllRows: function() {
			var allRows = {};
								
			allRows = $.map(currentData, function(item, index) {
				if (item.hasOwnProperty('rowGUID')) {
	                item['rowGUID'] = item.uid;
	            }
	            
                item = item.toJSON();
                
                if (options) {
                    item = Serializer.ConvertToSFDCDate(item, { dateFields: options.dateFields });
                }

                // Remove the extra attributes Kendo Grid creates for supporting wrapper classes
	            for (var i = 0; i < columns.length; i++) {
	                var name = columns[i].field;
	                
					if (name && name.indexOf('.') != -1) {
					    delete item[name];
					}
			    }

				return item;
			});
			
            if (allRows.length > 0) {
                allRows = Serializer.ParameterMap(allRows, { isDml: isDml });
            }
			
			return allRows;
		},
		
       	/*
       		Get selected rows
       	*/
       	SelectedRows: function() {
			var selectedRows = {};
								
			selectedRows = $.map(currentData, function(item, index) {
				if (item.IsSelected__custom) {
					if (item.hasOwnProperty('rowGUID')) {
		                item['rowGUID'] = item.uid;
		            }
		            
                	item = item.toJSON();
                
                    if (options) {
                        item = Serializer.ConvertToSFDCDate(item, { dateFields: options.dateFields });
                    }

                    // Remove the extra attributes Kendo Grid creates for supporting wrapper classes
		            for (var i = 0; i < columns.length; i++) {
		                var name = columns[i].field;
		                
						if (name && name.indexOf('.') != -1) {
						    delete item[name];
						}
				    }

					return item;
				}
			});
			
            if (selectedRows.length > 0) {
                selectedRows = Serializer.ParameterMap(selectedRows, { isDml: isDml });
            }
			
			return selectedRows;
		},
		
		/*
			Get updated rows
		*/
		UpdatedRows: function() {
			if (updatedRows.length > 0) {
                updatedRows = Serializer.ParameterMap(updatedRows, { isDml: isDml });
			}
			
			return updatedRows;
		},
		
		/*
			Get inserted rows
		*/
		NewRows: function() {
			if (newRows.length > 0) {
                newRows = Serializer.ParameterMap(newRows, { isDml: isDml });
			}

			return newRows;
		},
		
		/*
			Get deleted rows
		*/
		DeletedRows: function() {
        	if (deletedRows.length > 0) {
            	deletedRows = Serializer.ParameterMap(deletedRows, { isDml: isDml });
			}
			
			return deletedRows;
		},
		
		/*
			Check if the grid has any changes
		*/
		HasChanges: function() {
			if (newRows.length == 0 && updatedRows.length == 0 && deletedRows.length == 0) {
        		return false;
        	}
        	
        	return true;
		}
	};
};

// Kendo Confirmation/Alert Windows
(function ($) {

	// Kendo Window
    $.fn.KendoWindow = function(options) {
        var defaultOptions = $.extend({}, $.fn.KendoWindow.defaults, options);

        var kendoWindow = $('<div />').kendoWindow({
            title: defaultOptions.title,
            icon: defaultOptions.icon,
            modal: defaultOptions.modal,
            resizable: defaultOptions.resizable,
            draggable: defaultOptions.draggable,
            visible: defaultOptions.visible,
            width: defaultOptions.width,
            height: defaultOptions.height
        }).data('kendoWindow');

        return kendoWindow;
    };

	// Kendo Confirmation Window
    $.fn.KendoConfirmation = function(options, yesCallback, noCallback, closeCallback) {
        var $this = this;
        var kendoWindow = $.fn.KendoWindow(options);

        kendoWindow.content($.fn.KendoConfirmation.format(sanitize(options.html)));
        kendoWindow.center().open();

        // callback functions
        $('.kendo-confirmation-yes').click(function () {
            if (typeof yesCallback == 'function') {
                yesCallback();
            }
            
            kendoWindow.close();
        });

        $('.kendo-confirmation-no').click(function () {
            if (typeof noCallback == 'function') {
                noCallback();
            }
            
            kendoWindow.close();
        });

        kendoWindow.wrapper.find('.k-i-close').click(function () {
        	if (typeof closeCallback == 'function') {
                closeCallback();
            }
        });

        return $this;
    };

	// Kendo Alert Window
    $.fn.KendoAlert = function(options, okCallback) {
        var $this = this;
        var kendoWindow = $.fn.KendoWindow(options);

        kendoWindow.content($.fn.KendoAlert.format(options.html));
        kendoWindow.center().open();

        // callback functions
        $('.kendo-confirmation-ok').click(function () {
            if (typeof okCallback == 'function') {
                okCallback();
            }
            
            kendoWindow.close();
        });

        return $this;
    };

    // Kendo Window default options
    $.fn.KendoWindow.defaults = {
        title: 'Notification',
        html: '',
        icon: '',
        modal: true,
        resizable: false,
        draggable: false,
        visible: false,
        width: 350,
        height: 120
    };

    // Html for confirmation box
    $.fn.KendoConfirmation.format = function(message) {
        return '<div class= "kendo-confirmation">' +
                '<br/>' +
                '<p class="kendo-confirmation-message">' + message + '</p>' +
                '<br/>' +
                '<div class="kendo-confirmation-buttons">' +
                '<button class="kendo-confirmation-yes btn">Yes</button>' +
                '&nbsp;&nbsp;&nbsp;' +
                '<button class="kendo-confirmation-no btn">No</button>' +
                '</div>';
    };

    // Html for alert box
    $.fn.KendoAlert.format = function(message) {
        return '<div class= "kendo-confirmation">' +
                '<br/>' +
                '<p class="kendo-confirmation-message">' + sanitize(message) + '</p>' +
                '<br/>' +
                '<div class="kendo-confirmation-buttons">' +
                '<button class="kendo-confirmation-ok btn">OK</button>' +
                '</div>';
    };
    
    // Kendo AutoComplete
    $.fn.KendoAutoComplete = function(selector, options) {
    	var defaultOptions = $.extend({}, $.fn.KendoAutoComplete.defaults, options);
    	var filterCriteria = (defaultOptions.filterCriteria) ? (defaultOptions.filterCriteria) : '';
    	
		var autoComplete = $(selector)
	    .kendoAutoComplete({
        	minLength: defaultOptions.minLength,  
        	dataValueField: 'value',
        	dataTextField: 'text',
        	valuePrimitive: defaultOptions.valuePrimitive,
        	dataSource: {
        		transport: {
        			read: function(readOptions) {
		            	Visualforce.remoting.Manager.invokeAction(
    						options.lookupSearchAction,
		                	$(selector).val(),
		                	options.referenceTo,
		                	(filterCriteria) ? (filterCriteria) : '',
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
        	},
        	suggest: false,
        	highlightFirst: true,
        	filter: "contains",
        	placeholder: ($.support.placeholder) ? "Type to search " + defaultOptions.title + "..." : ""
        });
        
        return autoComplete;
	};
        
    // Kendo AutoComplete default options
    $.fn.KendoAutoComplete.defaults = {
        title: 'Type to search...',
        autoBind: false,
        minLength: 0,
        valuePrimitive: true
    }
     
    // Kendo ComboBox
    $.fn.KendoComboBox = function(selector, options) {
    	var defaultOptions = $.extend({}, $.fn.KendoComboBox.defaults, options);
    	var filterCriteria = (defaultOptions.filterCriteria) ? (defaultOptions.filterCriteria) : '';
    	
		var comboBox = $(selector)
	    .kendoComboBox({
	    	autoBind: defaultOptions.autoBind,
	    	cascadeFrom: (defaultOptions.cascadeFrom) ? defaultOptions.cascadeFrom : '',
        	filter: "contains",
			placeholder: ($.support.placeholder) ? "Type to search " + defaultOptions.title + "..." : "",       	
        	minLength: defaultOptions.minLength, 
        	dataValueField: 'value',
        	dataTextField: 'text',
        	dataSource: {
        		transport: {
        			read: function(readOptions) {
        				var searchTerm = '';
        				var criteria = '';
        				
        				if (readOptions.data.filter && readOptions.data.filter.filters.length > 0) {
        					var filter = _.where(readOptions.data.filter.filters, { field: 'text' });
        					
        					if (filter && filter.length > 0) {
        						searchTerm = (filter[0] && filter[0].value) ? filter[0].value : '';
        					}
        				}
        				
        				if (filterCriteria && defaultOptions.cascadeFrom) {
				    		var filterCriteriaTemplate = kendo.template(filterCriteria);
				    		var widget = kendo.widgetInstance($('#' + defaultOptions.cascadeFrom), kendo.ui);
	    				
	    					if (widget) {
				    			var value = '';
				    			
					    		switch(widget.options.name)
								{
									case 'MultiSelect':
										value = widget.value().join("','");
										break;
								   	default: 
					    				value = widget.value();
								    	break;
				    			}
								
								criteria = filterCriteriaTemplate({ Id: value });
				    		}
				    	}
				    	else if (filterCriteria) {
				    		criteria = filterCriteria;
				    	}
				    	
		            	Visualforce.remoting.Manager.invokeAction(
    						defaultOptions.lookupSearchAction,
		                	searchTerm,
		                	defaultOptions.referenceTo,
		                	criteria,
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
        }).data('kendoComboBox');
        
        // Set the default value
        comboBox.value(defaultOptions.value);
        
        return comboBox;
    };
    
    // Kendo ComboBox default options
    $.fn.KendoComboBox.defaults = {
        title: 'Type to search...',
        autoBind: false,
        minLength: 0
    }
    
    // Kendo MultiSelect
    $.fn.KendoMultiSelect = function(selector, options) {
    	var multiSelect;
    	var defaultOptions = $.extend({}, $.fn.KendoMultiSelect.defaults, options);
    	
    	if (options) {
	    	var filterCriteria = (defaultOptions.filterCriteria) ? (defaultOptions.filterCriteria) : '';
	    	
			multiSelect = $(selector)
		    .kendoMultiSelect({
		    	autoClose: defaultOptions.autoClose,
		    	autoBind: defaultOptions.autoBind,
		    	filter: "contains",
				//placeholder: ($.support.placeholder) ? "Type to search " + defaultOptions.title + "..." : "",       	
	        	minLength: defaultOptions.minLength, 
	        	dataValueField: 'value',
	        	dataTextField: 'text',
	        	dataSource: {
	        		transport: {
	        			read: function(readOptions) {
	        				var criteria = '';
	        				
	        				if (filterCriteria && defaultOptions.cascadeFrom) {
					    		var filterCriteriaTemplate = kendo.template(filterCriteria);
					    		var widget = kendo.widgetInstance($('#' + defaultOptions.cascadeFrom), kendo.ui);
					    						
					    		if (widget) {
					    			var value = '';
					    			
						    		switch(widget.options.name)
									{
										case 'MultiSelect':
											value = widget.value().join("','");
											break;
									   	default: 
						    				value = widget.value();
									    	break;
									}
									
									criteria = filterCriteriaTemplate({ Id: value });
					    		}
					    	}
					    	else if (filterCriteria) {
					    		criteria = filterCriteria;
					    	}
					    	/* for custom filtercriteria on the Multiselect lookup, KNDY-14016 */
					    	if(readOptions.data.hasOwnProperty('filterCriteria')){
					    	    criteria = readOptions.data.filterCriteria;
					    	}
					    	
					    	if(readOptions.data.hasOwnProperty('filterCriteria')){
					    	    criteria = readOptions.data.filterCriteria;
					    	}
					    	
			            	Visualforce.remoting.Manager.invokeAction(
	    						defaultOptions.lookupSearchAction,
			                	$(selector).data('kendoMultiSelect').input.val(),
			                	defaultOptions.referenceTo,
			                	criteria,
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
	        }).data('kendoMultiSelect');
	        
	        // Set the default value
	        multiSelect.value(defaultOptions.value);
        }
        else {
        	multiSelect = $(selector)
		    .kendoMultiSelect({
		    	autoClose: defaultOptions.autoClose,
		    	autoBind: defaultOptions.autoBind,
		    	filter: "contains",
				//placeholder: ($.support.placeholder) ? "Type to search " + defaultOptions.title + "..." : "",       	
	        	minLength: defaultOptions.minLength
	        }).data('kendoMultiSelect');
        }
        
        // set default width of the drop-down list
        //multiSelect.wrapper.width(150);
		//multiSelect.list.width(150);

        return multiSelect;
    };
    
    // Kendo MultiSelect default options
    $.fn.KendoMultiSelect.defaults = {
        title: 'Type to search...',
        autoClose: false,
        autoBind: false,
        minLength: 0
    }
        
    // Kendo DropDownList
    $.fn.KendoDropDownList = function(selector, options) {
		var dropDownList;
		
		if (options) {
			dropDownList = $(selector)
		    .kendoDropDownList({
	        	dataValueField: 'value',
	        	dataTextField: 'text',
	        	dataSource: {
	        		transport: {
	        			read: function(readOptions) {
					    	
			            	Visualforce.remoting.Manager.invokeAction(
	    						options.getPicklistValuesAction,
			                	options.objectName,
			                	options.fieldName,
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
	        		}
	        	}
	        }).data('kendoDropDownList');
	        
	        // Set the default value
	        dropDownList.value(options.value);
        }
        else {
        	dropDownList = $(selector)
        	.kendoDropDownList({
        	}).data('kendoDropDownList');
        }
        
        return dropDownList;
    };
    
    // Kendo DropDownList
    $.fn.KendoDropDownListCustom = function(selector, options) {
		var dropDownList;
		
		if (options) {
			dropDownList = $(selector)
		    .kendoDropDownList({
	        	dataValueField: 'value',
	        	dataTextField: 'text',
	        	dataSource: {
	        		transport: {
	        			read: function(readOptions) {
					    	
			            	Visualforce.remoting.Manager.invokeAction(
	    						options.getPicklistValuesAction,
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
	        		}
	        	}
	        }).data('kendoDropDownList');
	        
	        // Set the default value
	        dropDownList.value(options.value);
        }
        else {
        	dropDownList = $(selector)
        	.kendoDropDownList({
        	}).data('kendoDropDownList');
        }
        
        return dropDownList;
    };
    
    // Kendo DatePicker
    $.fn.KendoDatePicker = function(selector, options) {
    	var datePicker = $(selector)
    	.kendoDatePicker({
	    	culture: KenandyErp.Culture,
	    	format: KenandyErp.DateFormat
	    }).data('kendoDatePicker');
	    
	    // Set the default value
	    if (options) {
        	datePicker.value(options.value);
        }
        
        return datePicker;
    };
    
    // Kendo DateTimePicker
    $.fn.KendoDateTimePicker = function(selector, options) {
    	var dateTimePicker = $(selector)
    	.kendoDateTimePicker({
	    	culture: KenandyErp.Culture,
	    	format: KenandyErp.DateTimeFormat
	    }).data('kendoDateTimePicker');
	    
	    // Set the default value
	    if (options) {
        	dateTimePicker.value(options.value);
        }
        
        return dateTimePicker;
    };
    
})(jQuery);

//Serializer constructor for grid batch editing to save changes in one server request
var Serializer = function() {
	var convert = function(values, isDml) {
    	for (var key in values) {
    		// Removes all __r and __custom properties from the record getting saved, as we can't use them in DML
			if ((isDml && (/__r/i.test(key))) || (/__custom$/i.test(key))) {
            	delete values[key];
			}
			else if (!isDml && (/__r/i.test(key))) {	// Remove all __r if the Id is null
				if (values[key] && $.isPlainObject(values[key]) && !values[key].Id) {
					delete values[key];
				}
			}
			
        	var value = values[key];

            if (value instanceof Date) {
            	values[key] = (value) ? Date.parse(value) : null;
			}

            if ($.isPlainObject(value)) {
            	convert(value, isDml);
			}
			else if ($.isArray(value)) {
				for (var i = 0; i < value.length; i++) {
					if ($.isPlainObject(value[i])) {
						convert(value[i], isDml);
					}
				}
			}
		}
        
		return values;
	}
	
	var convertVal = function(values, isDml) {
    	for (var key in values) {
    		// Removes all __r and __custom properties from the record getting saved, as we can't use them in DML
			if ((isDml && (/__r/i.test(key))) || (/__custom$/i.test(key))) {
            	delete values[key];
			}
			
        	var value = values[key];

            if (value instanceof Date) {
            	values[key] = (value) ? Date.parse(value) : null;
			}

            if ($.isPlainObject(value)) {
            	convert(value, isDml);
			}
			else if ($.isArray(value)) {
				for (var i = 0; i < value.length; i++) {
					if ($.isPlainObject(value[i])) {
						convert(value[i], isDml);
					}
				}
			}
		}
        
		return values;
	}

	return {
	
        /**
            @param models : the mode to mapify
        */
        ParameterMap: function(models, config) {
            var result = [];
			if (models) {
				var isDml = (config && !config.isDml) ? false : true;
				
	        	for (var i = 0; i < models.length; i++) {
	        		//KNDY-19032 unshift will prepend array rows instead used push to keep same order
                   result.push(convert(models[i], isDml));
				}
			}
	
	        return result;
		},
		
		ParameterMapClone: function(models, config) {
            var result = [];
			if (models) {
				var isDml = (config && !config.isDml) ? false : true;
				
	        	for (var i = 0; i < models.length; i++) {
	        		//KNDY-19032 unshift will prepend array rows instead used push to keep same order
                   result.push(convertVal(models[i], isDml));
				}
			}
	
	        return result;
		},
		
		/*
			Utility function to parse JSON to convert SFDC to JavaScript date format
		*/
		ConvertFromSFDCDate: function(item, config) {
			if (config && config.dateFields) {
		    	for (var i = 0; i < config.dateFields.length; i++) {
		    		var field = config.dateFields[i].field;
		    		var fieldType = config.dateFields[i].fieldtype;
		    		var value = JSONUtils.Get(item, field);
		    		
		    		if (value) {
						JSONUtils.Set(item, field, (fieldType == KenandyErp.KendoGridOptions.ColumnType.Date) ? KenandyErp.ParseSFDCDate(value) : KenandyErp.ParseSFDCDateTime(value));
					}
				}
		    }
		    
		    return item;
		},
		
		/*
			Utility to convert multipicklist values from apex to array in javascript
		*/
		
		ConvertMultiPicklistvalues: function(item, config) {
			if(config && config.multiPicklistFields) {
				for (var i = 0; i < config.multiPicklistFields.length; i++) {
					var field = config.multiPicklistFields[i].field;
		    		var fieldType = config.multiPicklistFields[i].fieldtype;
		    		var value = JSONUtils.Get(item, field);
		    		
		    		if(value) {
		    			var valueList = value.split(";");
		    			JSONUtils.Set(item, field,valueList);
		    		}
					
				}
			}
			
			return item;
		
		},
		
		/*
			Utility function to parse JSON to convert JavaScript date to SFDC date format
		*/
		ConvertToSFDCDate: function(item, config) {
	    	// Comments By LK On 02/12/2014
	        // assign SFDC default date to all date/datetime fields to overcome the issue with setting a date/datetime field to null using Visualforce JavaScript Remoting
	        if (config && config.dateFields) {
	        	for (var i = 0; i < config.dateFields.length; i++) {
					var field = config.dateFields[i].field;
					var fieldType = config.dateFields[i].fieldtype;
		    		var value = JSONUtils.Get(item, field);
				    
				    if ((typeof value != 'undefined') && (typeof value != 'number') && (!(value instanceof Date))) {
				    	// Passing a zero results in the date being set to 12/31/1969 6:00 PM
						JSONUtils.Set(item, field, 0);
					}
					else {
						if (value) {
							if (fieldType == KenandyErp.KendoGridOptions.ColumnType.DateTime) {
			            		value = moment(value).add('minutes', moment(value).tz(KenandyErp.TimeZone).zone()).subtract('minutes', moment(value).zone()).toDate();
			            	}
			            	else {
			            		value = moment(value).subtract('minutes', moment(value).zone()).toDate();
			            	}
			            	
			            	JSONUtils.Set(item, field, value);
		                }
					}
				}
			}
		    
		    return item;
		},
		
		/*
			Utility function to parse JSON and include nulls for the missing key value pairs
		*/
		IncludeNulls: function(item, config) {
	        if (config && config.fields) {
	        	for (var i = 0; i < config.fields.length; i++) {
            		var path = config.fields[i];
            		var value = JSONUtils.Get(item, path);
            		
            		if (typeof value == 'undefined') {
            			JSONUtils.SetObject(path, null, item);
            		}
            	}
            }
            	    
		    return item;
		},
        /*
         Utility function to get dependent picklist values on selection of controlling picklist value
         decode sforce base 64 to binary
        */
        decodeSforceBase64Binary: function(input) {
            var keyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
            var output = [];
            var chr1, chr2, chr3 = "";
            var enc1, enc2, enc3, enc4 = "";
            var i = 0;
            var base64test = /[^A-Za-z0-9\+\/\=]/g;
            if (base64test.exec(input)) {
                alert("There were invalid base64 characters in the input text.\n" +
                      "Valid base64 characters are A-Z, a-z, 0-9, '+', '/', and '='\n" + "Expect errors in decoding.");
            }
            input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
            do {
                enc1 = keyStr.indexOf(input.charAt(i++));
                enc2 = keyStr.indexOf(input.charAt(i++));
                enc3 = keyStr.indexOf(input.charAt(i++));
                enc4 = keyStr.indexOf(input.charAt(i++));
                chr1 = (enc1 << 2) | (enc2 >> 4);
                chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
                chr3 = ((enc3 & 3) << 6) | enc4;
                output.push(String.fromCharCode(chr1));
                if (enc3 != 64) {
                    output.push(String.fromCharCode(chr2));
                }
                if (enc4 != 64) {
                    output.push(String.fromCharCode(chr3));
                }
                chr1 = chr2 = chr3 = "";
                enc1 = enc2 = enc3 = enc4 = "";
            } while (i < input.length);
            return output.join("");
        },
        /*
         * Each dependent picklist entry has a property called "validFor" which is a bitset where each bit indicates 
         * whether the value is valid for that bit's position in the controller field's options array
        */
        testBit: function(validFor, pos){
            var byteToCheck = Math.floor(pos/8),
                bit  = 7 - (pos % 8)
            return ((Math.pow(2, bit) & validFor.charCodeAt(byteToCheck)) >> bit) == 1
        },
        /*
         Get new picklist values for dependent picklist from controlling picklist value
         Params : 
         controllingFieldDescribe - get method from controller to get picklist values for controlling field
         dependentFieldDescribe  - get method from controller to get picklist values for dependent field
         controllingValueIndex - find index of selected controlling field picklist value
         requireNoneVal - it will add --none-- value on 0th index in case dependent picklist is not mandatory , values can be true/false
         call can be look like
         getNewPickListValues('{!TypeDescribe}','{!SubTypeDescribe}',controllingValueIndex,true)
         */
        getNewPickListValues: function(controllingFieldDescribe, dependentFieldDescribe,controllingValueIndex, requireNoneVal) {
	   			
            dependentFieldDescribe = JSON.parse(dependentFieldDescribe);
            
            controllingFieldDescribe = JSON.parse(controllingFieldDescribe);
            
            var cf = [];
            if (requireNoneVal == true){
            cf.push({value:null, text:'--None--', selected: true})
            }
            //GOING THROUGH EACH PICKLIST VALUE IN STT AND WANT TO GET SUBSET THAT IS DEPENDENT ON Type
            for(var i = 0; i < dependentFieldDescribe.picklistValues.length; i++){
                var picklistValue = dependentFieldDescribe.picklistValues[i]
                var iMenuItem = {value:picklistValue.value, text:picklistValue.label}
                iMenuItem.validFor = [];
                
                var validForDec = Serializer.decodeSforceBase64Binary(picklistValue.validFor)
                
                if (Serializer.testBit(validForDec, controllingValueIndex)) {
                    cf.push({value:picklistValue.value, text:picklistValue.label, selected: false})
                }
            }
            return cf;
		},

        /*
         * Salesforce passes dates and datetimes as a timestamp (number). Dates are at 12AM GMT
         *
         * Convert to date object
         * If date field, convert to 12AM local time
         */
        ConvertToDate: function(item, dateFields) {
            for (var i = 0; i < dateFields.length; i++) {
                var fieldType = dateFields[i].fieldtype;
                var field = dateFields[i].field;
                var fieldVal = JSONUtils.Get(item, field);

                if (fieldVal != null && fieldVal.constructor !== Date) {
                    fieldVal = new Date(fieldVal);

                    if (fieldType === KenandyErp.KendoGridOptions.ColumnType.Date) {
                        fieldVal = new Date(fieldVal.getTime() + fieldVal.getTimezoneOffset() * 60 * 1000);
                    }

                    JSONUtils.Set(item, field, fieldVal);
                }
            }
            return item;
        },

        /*
         * Date and datetime fields will either be a date object, string or timestamp (number)
         * If date object or string, field has been converted, and date will be at 12AM local time
         * If timestamp (number), field has not been converted, and date will be at 12AM GMT
         *
         * If not a date object, convert to date object
         * If field is a date field and has been converted (i.e. is a string or date object), convert to date at 12AM GMT
         * Convert field value to a timestamp
         */ 
        ConvertFromDate: function(item, dateFields) {
            for (var i = 0; i < dateFields.length; i++) {
                var fieldType = dateFields[i].fieldtype;
                var field = dateFields[i].field;
                var fieldVal = JSONUtils.Get(item, field);

                if (fieldVal != null && fieldVal != undefined) {
                    var convert = typeof fieldVal === 'string' || fieldVal instanceof Date;

                    if (!(fieldVal instanceof Date)) fieldVal = new Date(fieldVal);

                    if (fieldType === KenandyErp.KendoGridOptions.ColumnType.Date && convert) {
                        fieldVal = new Date(fieldVal.getTime() - fieldVal.getTimezoneOffset() * 60 * 1000);
                    }

                    JSONUtils.Set(item, field, fieldVal.getTime());
                } else {
                    var curObj = item;
                    var fieldParts = field.split(".");
                   
                    for (var j = 0; j < fieldParts.length; j++) {
                        if (j == fieldParts.length - 1) delete curObj[fieldParts[j]];
                        else curObj = curObj[fieldParts[j]];
                    }
                }
            }
            return item;
        },

        ConvertFromDate2: function(item, dateFields) {
            for (var i = 0; i < dateFields.length; i++) {
                var fieldType = dateFields[i].fieldtype;
                var field = dateFields[i].field;
                var fieldVal = item[field];

                if (fieldVal) {
                    var convert = typeof fieldVal === 'string' || fieldVal instanceof Date;

                    if (!(fieldVal instanceof Date)) fieldVal = new Date(fieldVal);

                    if (fieldType === KenandyErp.KendoGridOptions.ColumnType.Date && convert) {
                        fieldVal = new Date(fieldVal.getTime() - fieldVal.getTimezoneOffset() * 60 * 1000);
                    }

                    item[field] = fieldVal.getTime();
                } else {
                    delete item[field];
                }
            }
            return item;
        }
	};       
}();

// Utility functions to query and update JSON for a given key
var JSONUtils = function() {

	return {

		Get: function (model, key){
			var value = undefined;
		  
		  	if (key) {
		    	try {
		    		eval("value = model." + key);
		    	} 
		    	catch(e){
		    	}
		  	}
		  
		  	return value;
		},
	
		Set: function (model, key, value) {
  			if (key){
    			try {
      				eval("model." + key + " = value");
    			}
    			catch(e){
    			}
  			}	  
		},
		
		SetObject: function (path, value, model) {
		    var keys = path.split("."), 
		    key = keys.pop();
		    
		    for (var i=0, j; model && (j = keys[i]); i++) {
		        model = (j in model ? model[j] : model[j] = {});
		    }
		    
		    return model && key ? (model[key] = value) : undefined;
		},
		
		Parse: function(value) {
			if (typeof value === 'string') {
				try {
					value = JSON.parse(value);
				}
				catch (e) {
					value = null;
				}
			}
			
			return value;
		}
	};       
}();

// Utility to check if the browser supports the native placeholder attribute
(function($) {
      $.support.placeholder = ('placeholder' in document.createElement('input'));
}) (jQuery);

// Custom beforeEdit function to prevent editing a cell in a kendo grid based on some custom logic 
kendo.ui.Grid.fn.editCell = (function (editCell) {
    return function (cell) {
        cell = $(cell);

        var that = this,
            column = that.columns[that.cellIndex(cell)],
            model = that._modelForContainer(cell),
            event = {
                container: cell,
                model: model,
                preventDefault: function () {
                    this.isDefaultPrevented = true;
                }
            };

        if (model && typeof this.options.beforeEdit === "function") {
            this.options.beforeEdit.call(this, event);

            // don't edit if prevented in beforeEdit
            if (event.isDefaultPrevented) return;
        }

        editCell.call(this, cell);
    };
})(kendo.ui.Grid.fn.editCell);

Number.prototype.round = function(places) {
	return + (Math.round(this + "e+"+places)  + "e-"+places);
};

if (typeof String.prototype.startsWith != 'function') {
    String.prototype.startsWith = function(prefix) {
        return this.slice(0, prefix.length) == prefix;
    };
}
 
if (typeof String.prototype.endsWith != 'function') {
    String.prototype.endsWith = function(suffix) {
        return this.slice(-suffix.length) == suffix;
    };
}
