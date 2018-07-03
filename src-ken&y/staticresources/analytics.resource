(function($) {
	$.analytics = ($.analytics == null) ? {} : $.analytics; 

	$.fn.analytics = function(options) {
    	// Establish our default settings
        var settings = $.extend({
        				sessionid : null,				// required
        				itemid : null,
        				reportkey : null,
        				async : false,
        				reportid : null,				// required
        				reportItemName : null,
                        displayReportItemName : true, 
        				includeDetails : false,
        				companyValue : null,
        				companyColumn : 'Company Name', 
                        periodValue : null,
                        periodColumn : 'Period Name',
                        dateField : null,
                        startDate : null,
                        endDate : null,  
                        operator : 'equals',
                        numericScale : '2',				// decimals to show in format 
                        symbol : '$',                   // default currency symbol
                        showsymbol : true,              // draw the symbol
                        symbolfirstlast : true,         // show the symbol on first and last row of a report only 
                        showColumnLabels : true, 
                        showtotal: true, 
                        totalontop: false,        		// KNDY-2518: show the total on top?
                        totallabel: 'Total',
                        showTotalRow: true, 			// for matrix reports only 
                     	totalRowLabel: 'Total',			// for matrix reports only
                        httpMethod: 'GET',              // use POST when applying filters
                        treetable: true,                // add collapse sections                                
                        expandall: true,                // show them as expanded by default
                        filters: null                                
		}, options);

		var client = new forcetk.Client();	// init the client for AJAX calls from the Visualforce page
        client.proxyUrl = null;
        client.apiVersion = 'v29.0';
        client.setSessionToken(settings.sessionid);
        client.instanceUrl = location.protocol + '//' + location.hostname; 
        client.reportUrl =  '/v29.0/analytics/reports/' + settings.reportid;
        
        // validations  
        if (settings.reportid == null)	throw 'expected valid report id ';
        if (settings.sessionid == null)	throw 'expected valid session id ';

		return this.each(function() { 
        	var table = $(this).eq(0), scale = settings.numericScale, payload = null;
        	
        	/* filter support : we can add company, period or both
             *  but to preserve existing filters, we must fetch them first and merge our values
             */
            if (isNonEmptyString(settings.periodValue) || isNonEmptyString(settings.companyValue) || isNonEmptyString(settings.dateField) || settings.filters != null) { 
            	client.asyncAjax = false;	// simplifies the logic below
            	var jqXHR = client.ajax(client.reportUrl + '/describe');
            	if (jqXHR.status != "200") {
            		failedAjax(table,jqXHR);
            		return;
            	}
            	payload = reportMetadata(settings,JSON.parse(jqXHR.responseText));
            	settings.httpMethod = 'POST';	// use post since we will pass a filter
            	client.asyncAjax = true;	// reset to Async, best for most calls to server
			}

			if (settings.async)	client.reportUrl += '/instances';
			if (settings.includeDetails)	client.reportUrl += '?includeDetails=true'; 
			if (settings.async) {
				client.ajax(client.reportUrl, function(data) {	// execute ASYNC
					client.reportUrl = '/v29.0/analytics/reports/' + settings.reportid + '/instances/' + data.id;
                    client.ajax(client.reportUrl,function(data) { 
                    	processDataResponse(table, data, settings)
                    }, function(event) { 
                    	failedAjax(table,event); 
                    }, 'GET', null, false);        
                }, failedAjax, 'POST', payload, false);	// async must use POST
            } else { 
            	client.ajax(client.reportUrl, function(data) { 
            		processDataResponse(table, data, settings)
            	}, function(event) {
            		failedAjax(table,event); 
            	}, settings.httpMethod, payload, false);
            }
        });
	};

    function buildReport(table, data, settings) {
        var reportType = data.reportMetadata.reportFormat;
        var scale = settings.numericScale;
        
        if (reportType == 'MATRIX') {
        	var tableid = '#table_'+settings.reportkey;
        	var columns;
        	
        	buildMatrixTable(table,data,settings);
        	populateTableValues(table,data,settings);
        	
        	columns = $(tableid+' tr.headRow').children().length;
        	$(tableid+' tr').each(function(ind,tr) {
				tr = $(tr);
				if (tr.children().length != columns)
					for (var i=0; i < (columns-tr.children().length+1); i++)
						tr.append(blankDataCell(settings.numericScale));
			});
        } else {
        	var header = $('<tr class="headRow"></tr>');
        	if (settings.displayReportItemName && (!settings.showtotal || (settings.showtotal && !settings.totalontop))) 
        		header.append($('<th style="text-align:left; padding-left:1em;" id="reportName">'+settings.reportItemName+'</th>'));
        	else
        		header.append($('<th style="text-align:left; padding-left:1em;" id="reportName"></th>'));
        	if (settings.showColumnLabels) {
        		if (reportType == 'SUMMARY') {
        			$.each(data.reportMetadata.aggregates, function() {
	        			if (this != 'RowCount') {
	        				var colLabel = data.reportExtendedMetadata.aggregateColumnInfo[this].label;
	        				header.append(headCell(colLabel.replace(/Sum of/,''))); 
	                    }
	                });
        		} else if (reportType == 'TABULAR') {
        			$.each(data.reportMetadata.aggregates, function() {
	        			var that = this.substr(2);
	        			$.each(data.reportMetadata.detailColumns, function(di) {
	        				if (this == that)
	        					header.append(headCell(data.reportExtendedMetadata.detailColumnInfo[this].label,settings.reportid));
	        			});
	        		});
        		}
        	}	
        	table.append(header);
       
        	//KNDY-2518: put total at top
            if (settings.showtotal && settings.totalontop)
            	addTotal(table,data,settings);
            	
            if (reportType == 'SUMMARY') {
            	$.each(data.groupingsDown.groupings, function (rowInd, down) {
            		addSummaryRow(table, data, settings, down);
                	$.each(down.groupings, function(s2, subgroup) {
                		addSummaryRow(table, data, settings, subgroup);
                        $.each(subgroup.groupings, function(s3, subsubgroup) { 
                        	addSummaryRow(table, data, settings, subsubgroup);
                        });        
                    });                                                                                 
                });
            }
            	
            if (reportType == 'TABULAR'  && settings.includeDetails) { 
            	$.each(data.factMap['T!T'].rows, function(rowInd) {
                	var	tr = $('<tr></tr>').append(labelCell(this.dataCells[0].label));
                    var row = this;
                    $.each(data.reportMetadata.aggregates, function() {
                    	var that = this.substr(2);
                    	$.each(data.reportMetadata.detailColumns, function(di) {
                    		if (this == that)
                    			tr.append(dataCellVal(row.dataCells[di].value,scale));
                    	});
                    });
                    table.append(tr);
                });
            }
            
            if (settings.showtotal && !settings.totalontop)
            	addTotal(table,data,settings); 
        }
    }
    
    /*
     * Function: buildMatrixTable(table,data,settings)
     * JIRA: KNDY-2540
     *
     * This function builds the table that will hold the data for a matrix report.
     * It also handles appending any additional reports (the same standard report
     * with different filters). The table will assign all cells an id, so that populating
     * the values in the table will simply be finding the cell, and populating it.
     */
    function buildMatrixTable(table, data, settings) {
		var tableid = '#table_'+settings.reportkey;
		var tableExists = $(tableid).eq(0).children().length > 0? true:false;
		var existingCols;
		var reportItemId = settings.itemid;
		var totalLabel = settings.totallabel;
		
		var header;
		if (!tableExists) {
			if (settings.displayReportItemName)
				header = $('<tr class="headRow"></tr>').append($('<th class="reportNameCell"><a class="reportName" target="_blank" href="/'+settings.reportid+'">'+settings.reportItemName+'</a></th><td width="99%"></td>'));
			else
				header = $('<tr class="headRow"></tr>').append($('<th class="reportNameCell"></th><td width="99%"></td>'));
		} else {
			header = $(tableid+' tr.headRow');
			var reportNameTh = $(tableid+' tr.headRow th#reportName');
			if (reportNameTh.text() == '' && settings.displayReportItemName)
				reportNameTh.html('<a class="reportName" target="_blank" href="/'+settings.reportid+'">'+settings.reportItemName+'</a>');
		}	

		existingCols = header.children().length-2;
		if (settings.showColumnLabels)
			$.each(data.groupingsAcross.groupings, function(colInd,across) {
				header.append(headCell(across.label,reportItemId));
			});
		if (settings.showtotal)
			header.append(headCell(totalLabel,reportItemId));
		if (!tableExists)
			table.append(header);
			
		$.each(data.groupingsDown.groupings,function(rowInd,down) {
			var tr;
			var trExists = $(tableid+" tr[id='"+down.label+"']").length > 0? true:false;
			if (!trExists) {
	        	tr = ($('<tr id="'+down.label+'"></tr>').append(labelCell(down.label))).append($('<td width="99%"></td>'));
	        	for (var i=0;i<existingCols;i++)
	        		tr.append(blankDataCell(settings.numericScale));
	        } else
	        	tr = $(tableid+" tr[id='"+down.label+"']"); 
	        if (settings.showColumnLabels)
	       		for (var colInd = 0; colInd < data.groupingsAcross.groupings.length; colInd++) {
                	var acrosslabel = data.groupingsAcross.groupings[colInd].label;
                	tr.append(dataCell(reportItemId+down.label+acrosslabel));
           		}
           	if (settings.showtotal)
            	tr.append(dataCell(reportItemId+down.label+settings.totallabel));
            if (!trExists)
                table.append(tr);
		});
		
		if (settings.showTotalRow) {
			var totalRow;
			if ($(tableid+' tr.totalRow').length > 0)
				totalRow = $(tableid+' tr.totalRow');
			else {
				totalRow = ($('<tr class="totalRow"></tr>').append(labelCell(settings.totalRowLabel))).append($('<td width="99%"></td>'));
				for (var i=0;i<existingCols;i++)
	       			totalRow.append(blankDataCell(settings.numericScale));
	       	}
			if (settings.showColumnLabels) {
			    for (var colInd = 0; colInd < data.groupingsAcross.groupings.length; colInd++) {
		        	var acrosslabel = data.groupingsAcross.groupings[colInd].label;
		            totalRow.append(dataCell(reportItemId+settings.totalRowLabel+acrosslabel));
		        }
		    }
	        if (settings.showtotal)
	        	totalRow.append(dataCell(reportItemId+settings.totalRowLabel+settings.totallabel));
			table.append(totalRow);
		}
	}
	
	/*
	 * Function: pouplateTableValues(table,data,settings)
	 * JIRA: KNDY-2540
	 *
	 * This function will populate all of the values in the matrix table.
	 * The precondition is that the table is built and all cells contain
	 * ids that consist of the report item name, the row label and the column label.
	 */
	function populateTableValues(table,data,settings) {
		var scale = settings.numericScale;
		var tableid = '#table_'+settings.reportkey;
		var reportItemId = settings.itemid;
		var totalLabel = settings.totallabel;
	
		$.each(data.groupingsDown.groupings,function(rowIndx,down) {
			for (var colInd = 0; colInd < data.groupingsAcross.groupings.length; colInd++) {
				var acrosskey = data.groupingsAcross.groupings[colInd].key;
				var acrosslabel = data.groupingsAcross.groupings[colInd].label;
				var valContainer = $(tableid+" td[id='"+reportItemId+down.label+acrosslabel+"'] span.val");
				valContainer.text($.analytics.formatCurrency(data.factMap[down.key+'!'+acrosskey].aggregates[0].value, scale));
			}
			var totalContainer = $(tableid+" td[id='"+reportItemId+down.label+settings.totallabel+"'] span.val");
			totalContainer.text($.analytics.formatCurrency(data.factMap[down.key+'!T'].aggregates[0].value, scale));
		});
		
		$.each(data.groupingsAcross.groupings,function(colInd,across) {
			var valContainer = $(tableid+" td[id='"+reportItemId+settings.totalRowLabel+across.label+"'] span.val");
			valContainer.text($.analytics.formatCurrency(data.factMap['T!'+across.key].aggregates[0].value, scale));
		});
		var grandTotalCont = $(tableid+" td[id='"+reportItemId+settings.totalRowLabel+settings.totallabel+"'] span.val");
		grandTotalCont.text($.analytics.formatCurrency(data.factMap['T!T'].aggregates[0].value, scale));
	}
	
	/*
	 * Function:addTotal(table,data,settings)
	 * JIRA: KNDY-2518
	 *
     * This function will display the total. The presentation
     * and placement will depend on flags set by the user.
     */
	function addTotal(table,data,settings) {
		var totals;
		if (settings.totalontop && settings.displayReportItemName)
        	totals = $('<tr></tr>').append($('<th style="text-align:left; padding-left:1em;" id="reportName"><a style="text-decoration:none;" target="_blank" href="/'+settings.reportid+'">'+settings.reportItemName+'</a></th>'));
        else
        	totals = $('<tr></tr>').append(labelCell(settings.totallabel));
        $.each(data.reportMetadata.aggregates, function(i) {
        	if (this + '' != 'RowCount')
        		totals.append(dataCellVal(data.factMap['T!T'].aggregates[i].value,settings.numericScale));
        });
        table.append(totals);
    }  
    function addSummaryRow(table, data, settings, grouping) {
    	var tr = $('<tr></tr>').append(labelCell(grouping.label));
        for (var i = 0; i < data.reportMetadata.aggregates.length; i++) { 
        	if (data.reportMetadata.aggregates[i] != 'RowCount') {  
        		tr.attr('data-tt-id', grouping.key)
            		.attr('data-tt-parent-id', parentKey(grouping.key))
                	.append(dataCellVal(data.factMap[grouping.key+'!T'].aggregates[i].value,settings.numericScale));
        	}
        }
        table.append(tr);
    }
    
    // generate a filter object based on the settings and the existing filters on this report
    function reportMetadata(settings, meta) {
    	// preserve existing filters, add one or two more filters... based on settings
        var reportFilters = meta.reportMetadata.reportFilters? meta.reportMetadata.reportFilters:[];
        
        //Add company filter 
        if (isNonEmptyString(settings.companyValue)) {
        	// we need to find the company name and period name from the describe
            settings.companyColumn = findColumnNameFromLabel(settings.companyColumn, meta);
            var existingFilter = $.grep(reportFilters, function(that) { 
            						return (that.column == settings.companyColumn);        
                        		 });
            if (existingFilter.length == 0)
            	reportFilters.push({
            		column : settings.companyColumn,
            		operator : settings.operator,
            		value : settings.companyValue
            	});
            else
            	existingFilter.value = settings.companyValue;
        } 
        
        //Add period filter                       
        if(isNonEmptyString(settings.periodValue)) {
        	settings.periodColumn = findColumnNameFromLabel(settings.periodColumn, meta);
            var existingFilter = $.grep(reportFilters, function(that) { 
                                	return (that.column==settings.periodColumn );        
                        		 });
            if (existingFilter.length == 0)
            	reportFilters.push({
            		column : settings.periodColumn,
					operator : settings.operator,
					value : settings.periodValue
				});
			else
				existingFilter.value = settings.periodValue;
		}
		
		
		for (var i=0;i<settings.filters.length;i++) {
			var filter = settings.filters[i];
			var existingFilter = $.grep(reportFilters, function(that) { 
                                	return (that.column==filter['name'] );        
                        		 });
            if (existingFilter.length == 0)
            	reportFilters.push({
            		column : findColumnName(filter['name'],meta),
					operator : settings.operator,
					value : filter['value']
				});
			else
				existingFilter.value = filter['value'];  		 
		}
		
		
		
		//Add date range filter        
        if(isNonEmptyString(settings.dateField)) {
            reportFilters = $.grep(reportFilters, function(that) {
            					return (that.column != settings.dateField);
            				});
            reportFilters.push({
            	column : settings.dateField, 
            	operator :'greaterOrEqual',
            	value : apexDateToReportDateFormat(settings.startDate)
            });
            reportFilters.push({
            	column : settings.dateField, 
            	operator : 'lessOrEqual',
            	value : apexDateToReportDateFormat(settings.endDate)
            });
        }
        var boolFilter = [];
        for (var i = 0; i < reportFilters.length; i++)
        	boolFilter.push(i+1);
        boolFilter = boolFilter.join(' AND ');
        var ret  = { "reportMetadata" : { "reportFilters" : reportFilters, "reportBooleanFilter" : boolFilter } };
        return JSON.stringify(ret);
    }
    function processDataResponse(table, data, settings) {
		if (!longRunningReportReady(table, data, settings)) return; 
        
        buildReport(table, data, settings); 
        
        //Add symbols                   
        if (settings.showsymbol) { 
        	if (settings.symbolfirstlast)
            	$('tr>td:nth-child(2):first .sym, tr>td:nth-child(2):last .sym', table).text(settings.symbol);
            else
            	$('tr>td:nth-child(2) .sym', table).text(settings.symbol);
        }             
        
        if (settings.treetable && data.reportMetadata.reportFormat == 'SUMMARY') {
        	table.treetable({ expandable: true, expanded: true })
        	if (settings.expandall)
        		table.treetable("expandAll");
        }
    } 
    function failedAjax(table, event) {
    	event  = JSON.parse(event.responseText);
    	msgUser(table, event[0].message);
    }
    function longRunningReportReady(table, data, settings) {
    	var da = data.attributes, ready = (settings.async == false || da.completionDate != null);
    	if (!ready)
    		msgUser(table, 'Asynchronous Report Request at ' + da.requestDate + ' status : ' + da.status);
        return ready;
    }
	    

	/* 
	 * utility functions 
	 */
	function isNonEmptyString(val) {
		return (typeof val == 'string' && val != '');
	}
	function findColumnNameFromLabel(label , meta) {
		var comparelabel = cleanlabel(label), ret = null;
		$.each(meta.reportTypeMetadata.categories,function() {
			$.each(this.columns, function(fieldName) {
				if (comparelabel == cleanlabel(this.label))
					ret = fieldName;
			});
		});
		if (ret == null) 
			throw 'could not find column by label ' + label;
		return ret;
	}
	function findColumnName(field,meta) {
		var ret;
		$.each(meta.reportTypeMetadata.categories,function() {
			$.each(this.columns, function(fieldName) {
				if (fieldName.search(field) != -1)
					ret = fieldName;
			});
		});
		if (ret == null) 
			throw 'could not find column ' + field;
		return ret;
	}
	function cleanlabel(label) {
		return label.trim().replace(/[ ]/g,'').toLowerCase();
	}
	$.analytics.formatCurrency = function(val, scale) {
		val = val? val : 0.0;
    	var isNeg = (val < 0);
        val = val.toFixed(parseInt(scale));
        val = val + "";
        var len = val.length, 
        sfxlen = val.lastIndexOf('.');
        if ( sfxlen == -1 ) // zero scale
        	sfxlen=len;
        var fp = val.substring(0, sfxlen), 
        lp = val.substring(sfxlen,len), 
        arr = fp.match(/\d/g).reverse(),
        arr2 = [];
        for (var i = 0; i < arr.length; i++) {
            if (i > 0 && i % 3 == 0) {
                arr2.push(",");
            }
            arr2.push(arr[i]);
        }
        arr2 = arr2.reverse();
        fp = arr2.join("");
        if (isNeg) return '('+fp + lp+')';
        else return fp + lp;
    }    
	function headCell(val, reportid) { 
    	return $('<th class="headCell" id="'+reportid+val+'">'+val+'</th>');
    } 
    function labelCell(val) {
    	return $('<td class="labelCell">'+val+'</td>');
    }
    function dataCell(id) {
    	return $('<td class="dataCell" id="'+id+'"><span class="sym"></span><span class="val"></span></td>');
    }
    function dataCellVal(val,scale) {
    	val = $.analytics.formatCurrency(val,scale);
    	return $('<td class="dataCell"><span class="sym"></span><span class="val">'+val+'</span></td>');
    }
    function blankDataCell(scale) {
    	var val = $.analytics.formatCurrency(0,scale);
    	return $('<td class="dataCell"><span class="sym"></span><span class="val">'+val+'</span></td>');
    }
    function apexDateToReportDateFormat(dt) { 
		var d = new Date(dt), c = convertDateToUTC(d);
        return dateToDateString( c);
    }
    function convertDateToUTC(date) {
    	return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    }
    function dateToDateString(dt) { 
    	var months = { "Jan" : "01", "Feb" : "02", "Mar" : "03", "Apr" : "04", "May" : "05", "Jun" : "06", "Jul" : "07", "Aug" : "08", "Sep" : "09", "Oct" : "10", "Nov" : "11", "Dec" : "12" };
        var dateString = dt.toString();
        dateString = dateString.substring(4,dateString.lastIndexOf(':'));
        var dateParts = dateString.split(" ");
        return dateParts[2]+"-"+months[dateParts[0]]+"-"+dateParts[1];
    }
    function msgUser(table, msg) { 
    	labelCell(msg).appendTo($('<tr></tr>').appendTo(table));
    }
    function parentKey(k) { 
    	if (typeof k === "undefined") return '';
        return (k.lastIndexOf('_') > -1)? k.substr(0,k.lastIndexOf('_')) : ''; 
    } 
}(jQuery));