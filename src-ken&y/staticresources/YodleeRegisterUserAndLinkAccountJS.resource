var cobrandsession;
var usersession;                     //used to keep usersession value
//var mapSiteIdAndAccount = {};
var arraymapSiteIdAndAccount = [];
var arrayAccountsForSite = [];
var resultOfSummarySite = [];
var countOfgetSummaryForSite = 0;
var resultOfUnlinkedAccountCall = [];
var arraySiteId = [];
var arrayAccountId = [];
var arrayAccountName = [];
var arrDelinkBankIds = [];
var startRegistration = function(){
    if($("#login").val() != '' && $("#password").val() != '' && $("#email").val() != '' && $("#fName").val() != '' && $("#lName").val() != ''){
	    var promise = cobrandlogin();
	    promise.done(function(){
	        var registerpromise = registerUser();
	        registerpromise.done(function(result,event){
	        	if(result != undefined && result.success){
	         	insertUser();
	         	}
	        });
		});
	}
} 
        
var cobrandlogin = function(resolve,reject){
    console.log('in  cobrandlogin ');
	KenandyErp.ClearMessage(messageElement);
	KenandyErp.BlockUI();
	var deferred = $.Deferred();
	Visualforce.remoting.Manager.invokeAction(
		(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.cobrandlogin',
		function (result, event) {
			if (event.type == 'exception') {
				console.log('Error in cobrandlogin',result,event);
				KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
				KenandyErp.UnBlockUI();
			}else {	    
				if(result.success == true){
					cobrandsession = result.records[0];
					deferred.resolve(result, event);	 
					KenandyErp.UnBlockUI();
				}else{	
					console.log('Error in cobrandlogin',result,event);
					KenandyErp.Messages(result.messages, messageElement);	
					KenandyErp.UnBlockUI();
				}
			}
		}
	);  
	return deferred.promise();
}

var registerUser = function(resolve,reject){
    console.log('in  registerUser ');
	KenandyErp.ClearMessage(messageElement);
	KenandyErp.BlockUI();
	var deferred = $.Deferred();
	Visualforce.remoting.Manager.invokeAction(
		(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.registerUser',
		$("#login").val(),
		$("#password").val(),
		$("#email").val(),
		null,
		null,
		$("#fName").val(),
		$("#lName").val(),
		null,
		null,
		null,
		null,
		null,
		cobrandsession,
		function (result, event) {
			if (event.type == 'exception') {
				console.log('Error in registerUser',result,event);
				KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
				KenandyErp.UnBlockUI();
			}else {	    
				if(result.success == true){
					usersession = result.records[0];
					deferred.resolve(result, event);	 
					KenandyErp.UnBlockUI();
				}else{	
					console.log('Error in registerUser',result,event);
					KenandyErp.Messages(result.messages, messageElement);	
					KenandyErp.UnBlockUI();
				}
			}
		}
	);  
	return deferred.promise();
}
		
var insertUser = function(){
    console.log('in  insertUser ');
	KenandyErp.ClearMessage(messageElement);
	KenandyErp.BlockUI();
	Visualforce.remoting.Manager.invokeAction(
		(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.insertUser',
		cobrandsession,
		$("#login").val(),
		$("#password").val(),
		usersession,
		function (result, event) {
		    if (event.type == 'exception') {
		    	console.log('Error in insertUser',result,event);
				KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
				KenandyErp.UnBlockUI();
			}else {	    
				if(result.success == true){	
					$("#divUserRegistration").hide();
                    $("#divAccountSetup").show();
					startSiteLinkage();
				}else{
					console.log('Error in insertUser',result,event);
					KenandyErp.Messages(result.messages, messageElement);
				}
				KenandyErp.UnBlockUI();
			}
		}
	);  
}

var startSiteLinkage = function(){
    console.log('in startSiteLinkage');
	resultOfSummarySite = [];
	countOfgetSummaryForSite = 0;
	arraymapSiteIdAndAccount = [];
	var promise = cobrandAndUserlogin();
    promise.done(function(result, event){
    	if(result != undefined && result.success){
    	//KNDY-13289 - Fetch linked site data from yodlee
        var sitePromise = getSiteLinksYodleeAccount();
	        sitePromise.done(function(siteresult, siteevent){
	        	if(siteresult != undefined && siteresult.success){
		        	var promiseBA = getLinkedBankAccount();
		        	promiseBA.done(function(resultBA, eventBA){
		        		if(resultBA != undefined && resultBA.success){
        					if($("#linkAccount") != undefined){
								$("#linkAccount").addClass('custom-remove-button-opacity');
							}
							console.log('startSiteLinkage',arraymapSiteIdAndAccount);
         					if(arraymapSiteIdAndAccount != '' && arraymapSiteIdAndAccount.length>0){
         	
								var summarypromise = getSummaryForSite(arraymapSiteIdAndAccount[countOfgetSummaryForSite].siteId,arraymapSiteIdAndAccount[countOfgetSummaryForSite].AccountName);
								$('#mIframe').attr('src','about:blank');
            				}else if(arraymapSiteIdAndAccount){ //kndy-13289 reset kendo dropdowns in case no accounts to link found
                				console.log(resultOfUnlinkedAccountCall);
                				console.log(arrayAccountsForSite);
                				createKendoDropDownList(null, null);
         					}
				         	
				         }
			        });
				}
         	});
     	}
	});
}
var BeforeEditOverride= function(e) { //we use this function to ensure that status field is not editable.                    
    e.preventDefault();
}	
var getSiteAccounts = function(){
   	console.log('in  getSiteAccounts ');
    KenandyErp.BlockUI();
    KenandyErp.ClearMessage(messageElement);
    var deferred = $.Deferred();
    Visualforce.remoting.Manager.invokeAction(
		(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.getSiteAccounts',
		args.cobrandsession,
		args.usersession,
		function (result, event) {
		    if (event.type == 'exception') {
		    	console.log('Error in getSiteAccounts',result,event);
				KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
				KenandyErp.UnBlockUI();
			}else {	    
				if(result.success == true){	 
					if(result.records.length > 0){
						$.each(result.records, function(index, element){
							var mapSiteIdAndAccount = {};
    						mapSiteIdAndAccount.siteId = element.siteId;
    						mapSiteIdAndAccount.AccountName = element.AccountName;
    						mapSiteIdAndAccount.status = element.status;
    						arraymapSiteIdAndAccount.push(mapSiteIdAndAccount);
    					});
					}
					deferred.resolve(result, event);
					KenandyErp.UnBlockUI();
				}else{		
					KenandyErp.Messages(result.messages, messageElement);	
                    console.log('Error in getSiteAccounts',result,event);
                    deferred.resolve(result, event);	
					KenandyErp.UnBlockUI();
				}
			}
		}
	);  
	return deferred.promise();     
}
    
var getSummaryForSite = function(siteId,siteAccountName){
    console.log('in  getSummaryForSite ');
    if(siteId != '' && siteAccountName != ''){
    	KenandyErp.ClearMessage(messageElement);
	    KenandyErp.BlockUI();
	    var deferred = $.Deferred();
	    Visualforce.remoting.Manager.invokeAction(
			(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite',
			siteId,
			siteAccountName,
			args.cobrandsession,
			args.usersession,
			function (result, event) {
				if (event.type == 'exception') {
					console.log('Error in getSummaryForSite',result,event);
				    KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
					KenandyErp.UnBlockUI();
				}else {	    
					if(result.success == true){	 
						if(result.records.length >= 0){
							$.each(result.records, function(index, element){
	    						resultOfSummarySite.push(element);
	    					});
	    					console.log('resultOfSummarySite',resultOfSummarySite);
									getUnlinkedAccount(resultOfSummarySite);
									deferred.resolve(result, event);
									KenandyErp.UnBlockUI();
								}
					}else{
						console.log('Error in getSummaryForSite',result);						
						KenandyErp.Messages(result.messages, messageElement);
						//deferred.resolve(result, event);
								KenandyErp.UnBlockUI();
							}
						}
			}
		);   
	}else{

	}
	return deferred.promise();    
}
    
var getUnlinkedAccount = function(resultOfSummarySite){
    console.log('in  getUnlinkedAccount ');
    KenandyErp.BlockUI();
    KenandyErp.ClearMessage(messageElement);
    resultOfUnlinkedAccountCall=[];
    if(resultOfSummarySite.length > 0){
	    Visualforce.remoting.Manager.invokeAction(
			(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.getUnlinkedAccount',
			resultOfSummarySite,
			function (result, event) {
				if (event.type == 'exception') {
					console.log('Error in getUnlinkedAccount',result,event);	
					KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
					KenandyErp.UnBlockUI();
				}else {	    
					if(result.success == true){	 
						if(result.records.length > 0){
							$.each(result.records, function(index, element){
		    					resultOfUnlinkedAccountCall.push(element);
		    					if(index == 0){
		    						arrayAccountsForSite = element.lstAccountsForSite;
		    					}
		    				});
		    				createKendoDropDownList(resultOfUnlinkedAccountCall, arrayAccountsForSite);
		    				if(arrayAccountsForSite.length == 0){
			    				
								if($("#linkAccount") != undefined){
									$("#linkAccount").addClass('custom-remove-button-opacity');
								}
							}else{
								if($("#linkAccount") != undefined){
                                    $("#linkAccount").removeClass('custom-remove-button-opacity');
								}
							}
						}
						KenandyErp.UnBlockUI();
					}else{	
						console.log('Error in getUnlinkedAccount',result,event);	
						KenandyErp.Messages(result.messages, messageElement);
						resultOfUnlinkedAccountCall = [];
						arrayAccountsForSite = [];
						createKendoDropDownList(resultOfUnlinkedAccountCall, arrayAccountsForSite);
						if($("#linkAccount") != undefined){
							$("#linkAccount").addClass('custom-remove-button-opacity');
						}
						KenandyErp.UnBlockUI();
					}
				}
			}
		);  
	}else{
		resultOfUnlinkedAccountCall = [];
		arrayAccountsForSite = [];
		createKendoDropDownList(resultOfUnlinkedAccountCall, arrayAccountsForSite);
		
		if($("#linkAccount") != undefined){
			$("#linkAccount").addClass('custom-remove-button-opacity');
		}
		KenandyErp.UnBlockUI();
	}    
}

var createKendoDropDownList = function(varResultOfUnlinkedAccountCall, varArrayAccountsForSite){
	$("#accounts").width(250).kendoDropDownList({
		dataTextField: "siteAccountName",
		dataValueField: "recordId",
		dataSource: {
			data: varResultOfUnlinkedAccountCall
		},
		animation: false
	});
								
	$("#siteAccounts").width(300).kendoDropDownList({
		dataTextField: "AccountName",
		dataValueField: "strSiteAccountId",
		dataSource: {
			data: varArrayAccountsForSite
		},
		animation: false
	});
}

var startlinkingBankAccountWithSite = function(){
    arraySiteId = [];
    arrayAccountId = [];
    arrayAccountName = [];
	var linkpromise = linkBankAccountWithSite();
    linkpromise.done(function(result,event){
    	if(result != undefined && result.success){ 
        	startSiteLinkage();
        }
	});
}
	
var linkBankAccountWithSite = function(){
    console.log('in  linkBankAccountWithSite ');
    console.log($("#siteAccounts").val());
    console.log($("#accounts").val());
    KenandyErp.BlockUI();
    arraySiteId.push($("#siteAccounts").val());
    arrayAccountId.push($("#accounts").val());    
    if($("#siteAccounts").val() != '' && $("#accounts").val() != ''){
    	arrayAccountName.push($("#siteAccounts").data("kendoDropDownList").text());
    }
    var deferred = $.Deferred();
	if(arrayAccountId != '' && arraySiteId != '' && arrayAccountName != ''){
		KenandyErp.ClearMessage(messageElement);
	    Visualforce.remoting.Manager.invokeAction(
			(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.linkBankAccountWithSite',
			arrayAccountId,
			arraySiteId,
			arrayAccountName,
			function (result, event) {
				if (event.type == 'exception') {
					console.log('Error in linkBankAccountWithSite',result,event);
					KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);
					KenandyErp.UnBlockUI();
				}else {	    
					if(result.success == true){
						deferred.resolve(result, event);
					}else{	
						console.log('Error in linkBankAccountWithSite',result,event);
						KenandyErp.Messages(result.messages, messageElement);	
						KenandyErp.UnBlockUI();
					}
				}
			}
		);  
	}else{
		
		KenandyErp.UnBlockUI();
	}    
	return deferred.promise(); 
}
    
var getLinkedBankAccount = function(){
    console.log('in  getLinkedBankAccount ');
    KenandyErp.BlockUI();
	KenandyErp.ClearMessage(messageElement);
	var deferred = $.Deferred();
	gridConfig = JSON.parse(gridConfig);
    gridConfig['renderCheckboxes'] = false;
    gridConfig.actionColumnWidth = 180;
    gridConfig = JSON.stringify(gridConfig);
    
    $('#'+gridConfigId).empty();
	var lgrid = $('#'+gridConfigId).width(global_grid_width).kendoGridActionList({
        namespace: nspaceForYodlee, 
		config: gridConfig, 
		fieldList: GetFieldList(fieldList),//JSON.stringify(fieldList),
		lookupSearchAction: [], 
        showIconButtons: true,
        getActionListFunction: function(){
        	var pp = getAccounts();
            pp.done(function(result,event){
            	deferred.resolve(result,event);
            });
            return deferred.promise(); 
        },
		filterable: false,
		actionColumnButtons: [
        	{ name: "custom-delink-command", text:"", template: "<input type='button' value='"+ delink + "' class='btn grid-custom-delink-command' />" }
        ]
	}).data('kendoGridActionList');
	
	lgrid.table.on("click", ".grid-custom-delink-command", $.proxy(delinkBankAccounts, { grid: lgrid, options: {} }));
	return deferred.promise();	   
}
//KNDY-13289 get sites linked to yodlee from yodlee with callout
var getSiteLinksYodleeAccount = function(){
    console.log('in  getSiteLinksYodleeAccount ');
    KenandyErp.BlockUI();
	KenandyErp.ClearMessage(messageElement);
	var deferred = $.Deferred();
	gridSiteConfig = JSON.parse(gridSiteConfig);
    gridSiteConfig['renderCheckboxes'] = false;
    //gridSiteConfig.actionColumnWidth = 300;
    gridSiteConfig = JSON.stringify(gridSiteConfig);
       $('#'+gridSiteConfigId).empty();
       
    var yodleeSitesGridWidth = $('#'+gridSiteConfigId).width();   
	var lgrid = $('#'+gridSiteConfigId).width(yodleeSitesGridWidth).kendoGridActionList({
        namespace: nspaceForYodlee, 
		config: gridSiteConfig, 
		fieldList: GetFieldList(fieldListSite),//JSON.stringify(fieldListSite),
		lookupSearchAction: [], 
        showIconButtons: true,
        beforeEdit: function(e) {
		    BeforeEditOverride.call(this, e);
		  },
		getActionListFunction: function(){
       
        	var pp = getSiteAccounts();
        	
            pp.done(function(result,event){
            	
           		console.log(result);
            	deferred.resolve(result,event);
            });
            return deferred.promise(); 
        },
		filterable: false,
       
		actionColumnButtons: [
			{ name: "custom-remove-command", text:"", template: "<input type='button' id='removeButtonId' value=" + removeLabel +  " class='btn grid-custom-remove-command' />" },		
        	{ name: "custom-editsitecredential-command", text:"", template: "<input type='button' id='editsitebtn' value='"+ editSiteCredLabel +"' class='btn grid-custom-editsitecredential-command' />" },
			{ name: "custom-refresh-command", text:"", template: "<input type='button' id='refreshButtonId' value='"+ RefreshLabel +"' class='btn grid-custom-refresh-command' />" }            
        ]
	}).data('kendoGridActionList');
	lgrid.table.on("click", ".grid-custom-editsitecredential-command", $.proxy(editSiteCredentials, { grid: lgrid, options: {} }));
	lgrid.table.on("click", ".grid-custom-remove-command", $.proxy(removeSites, { grid: lgrid, options: {} }));
    lgrid.table.on("click", ".grid-custom-refresh-command", $.proxy(refreshSites, { grid: lgrid, options: {} }));
    lgrid.bind("dataBound", function(e) {
        console.log('databound',e);
    
        disableRemoveBtn();
		lgrid.table.kendoTooltip({
		    autoHide: true,
		    showOn: "mouseenter",
		    filter: "td:nth-child(3)",
		    position: "bottom",
		    content: function(e) {
			    var self = this;
			    var grid = self.grid;		    
				var row = $(e.target).closest("tr"); //get the row for deletion
			    var dataItem = grid.dataItem(row); // get the row data
			    if (dataItem != null) {			    	
                    var convertedLastRefreshDt = dataItem.lastRefreshed != null ? new Date(dataItem.lastRefreshed).toUTCString().substring(5) : dataItem.get('lastRefreshed') == undefined ? '-' : dataItem.get('lastRefreshed');	
                    var convertedLastRefreshAttemptDt = dataItem.lastRefreshAttempt != null ? new Date(dataItem.lastRefreshAttempt).toUTCString().substring(5) : dataItem.get('lastRefreshAttempt') == undefined ? '-' : dataItem.get('lastRefreshAttempt');	
			    	var convertedNextRefreshDt = dataItem.nextRefreshScheduled != null ? new Date(dataItem.nextRefreshScheduled).toUTCString().substring(5) : dataItem.nextRefreshScheduled == undefined ? '-' : dataItem.get('nextRefreshScheduled');
			    	
				    var tooltiptext = lastRefreshed + convertedLastRefreshDt + '<br/>' + lastRefreshAttempt + convertedLastRefreshAttemptDt + '<br/>'  + nextRefresh + convertedNextRefreshDt;
				    var content = tooltiptext;
				    return content	       
			    }
			}
		}).data("kendoTooltip");   
    });
    
	return deferred.promise();	   
}
var GetFieldList = function(fieldList) {
    
    $.each(fieldList, function() { 

        if (this.field == 'AccountName' || this.field =='YodleeAccountName' || this.field == 'SiteName' || this.field == 'Name') {
			
            this.width = '250px';
        }
        if(this.field == 'siteId' || this.field == 'status' ){
        	
        	this.width= '80px';
        }      
        if (this.field == 'YodleeAccountNumber'){
        	this.width= '120px';
        }
    });
    return fieldList;
}
var startAddAccount = function(){
	var loginpromise = cobrandAndUserlogin();
    loginpromise.done(function(result,event){
    	if(result != undefined && result.success){
        	var getTokenPromise = getToken();
	        getTokenPromise.done(function(result,event){
	        	if(result != undefined && result.success){
         			ywindow.center().open();
         			window.history.pushState('dummyPageState', null);
         			$("#Submit").click();
         			$("input[id=rsession]").val('');
					$("input[id=token]").val('');
					$("input[id=extraParams]").val('');
				}
        	});
	    }
	});
}

var getAccounts = function(){
    console.log('in getAccounts');            
	var deferred1 = $.Deferred();
    Visualforce.remoting.Manager.invokeAction(
    	(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.getLinkedBankAccount',
         function (result, event) {
         	KenandyErp.UnBlockUI();
         	if (event.type == 'exception') {
         		console.log('Error in getAccounts',result,event);
            	KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	         
            }else {
            	if(result.success == true){	 	                                                  
                	deferred1.resolve(result, event);
            }else {	   
					console.log('Error in getAccounts',result,event);
					deferred1.resolve(result, event);
                KenandyErp.Messages(result.messages, messageElement);	
			}	 	
		}
        {escape: false}
    });
    return deferred1.promise();        
}

var getToken = function(){
    console.log('in  getToken ');
    KenandyErp.BlockUI();
    KenandyErp.ClearMessage(messageElement);
    var deferred = $.Deferred();
    Visualforce.remoting.Manager.invokeAction(
		(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.getToken',
		args.cobrandsession,
		args.usersession,
		function (result, event) {
			if (event.type == 'exception') {
				console.log('Error in getToken',result,event);
				KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);		
				KenandyErp.UnBlockUI();
			}else {	    
				if(result.success == true){	 
					if(result.records.length > 0){
						$("input[id=rsession]").val(result.records[0]);
						$("input[id=token]").val(result.records[1]);
						deferred.resolve(result, event);
					}
					KenandyErp.UnBlockUI();
				}else{		
					console.log('Error in getToken',result,event);
					KenandyErp.Messages(result.messages, messageElement);	
					KenandyErp.UnBlockUI();
				}
			}
		}
	);  
	return deferred.promise();     
}
//KNDY-13289 - disable remove button in case yodlee account is linked with kenandy
var disableRemoveBtn = function(){
	var self = this;
    console.log('disableRemoveBtn');
    var options = self.options; 
    
    grid = $('#'+gridSiteConfigId).data("kendoGridActionList");

    if (grid) {
            var gridData = grid.dataSource.data();
            $.each( gridData, function(indx,valu) { 
                var rowUid =  valu.uid ;
                
                if(rowUid){
                     if (valu.disableRemove == 'false') {
                       $('tr[data-uid='+ rowUid +']').find('td input[id="removeButtonId"]').removeClass('custom-remove-button-opacity');    
                    }else{
                       $('tr[data-uid='+ rowUid +']').find('td input[id="removeButtonId"]').addClass('custom-remove-button-opacity'); 
                    }
                    if (valu.status == 'IN_PROGRESS'){
                    	$('tr[data-uid='+ rowUid +']').find('td input[id="refreshButtonId"]')[0].value = getRefreshStatusLabel;
                    }
                   
                }
            });
      }  
	}
//KNDY-15857
var refreshSites = function (e){
	var self = this;
    var grid = self.grid;
    var options = self.options; 
    var messageElement = grid.element.closest("div.grid-container").find("div.grid-message:first");
	var row = $(e.target).closest("tr"); //get the row for deletion
	var dataItem= this.grid.dataItem(row);
	KenandyErp.BlockUI();	
    if (dataItem != null) {
	    var accountId = dataItem.get('siteId');
	    var promisesession = cobrandAndUserlogin();		 
		promisesession.done(function(result,event){
		    if(result != undefined && result.success){  
		    	if (dataItem.get('status') == 'IN_PROGRESS'){       
		    		var promiseGrid = refreshSitesGrid(accountId,dataItem);
		    		promiseGrid.done(function(result,event){
		    			KenandyErp.UnBlockUI();
		    		});		    		
		    	}else{         
		    		var promisitecall = refreshSitesCall(accountId);
		    		promisitecall.done(function(result,event){
		    			var promiseGrid = refreshSitesGrid(accountId,dataItem); 
		    			promiseGrid.done(function(result,event){
		    				KenandyErp.UnBlockUI();
		    			});
		    		});			   	
		    	}	
		    }
		});
	}
	
}
var refreshSitesGrid = function(accountId,dataitem){
    console.log('refreshSitesGrid',accountId);
    var deferred = $.Deferred();	 
    Visualforce.remoting.Manager.invokeAction(
    (nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.getSiteAccountsWithProviders',
    args.cobrandsession,
    args.usersession,
    accountId,
    function (result, event) {
    	
        if (event.type == 'exception') {
            console.log('Error in refreshSitesGrid',result,event);
            KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
            KenandyErp.UnBlockUI();
        }else {	    
            if(result.success == true){	 
                if(result.records.length > 0){
                    $.each(result.records, function(index, element){ 
                    	console.log('refresh result',element);     
                    	if (dataitem != null) {                               	                      
                            dataitem.set('status',element.status );
                            dataitem.set('lastRefreshAttempt',element.lastRefreshAttempt);
                            dataitem.set('nextRefreshScheduled',element.nextRefreshScheduled);
                            dataitem.set('lastRefreshed',element.lastRefreshed);                            
                         } 
				         deferred.resolve(result, event);                                                                          
                    });
                }
            }else{	
                KenandyErp.Messages(result.messages, messageElement);
                console.log('Error in refreshSitesGrid',result,event);									         
                KenandyErp.UnBlockUI();								         
                
            }
        }
        {escape: false}
    });    
    return deferred.promise();                                                
}
//KNDY-15857 - call to refresh Sites
var refreshSitesCall = function (arrSiteId){
	console.log('in refreshSitesCall'); 
	var deferred = $.Deferred();
    KenandyErp.ClearMessage(messageElement);
    Visualforce.remoting.Manager.invokeAction(
    	(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.refreshSiteAccounts',
    	args.cobrandsession,
		args.usersession,
    	 arrSiteId, 
         function (result, event) {
         	if (event.type == 'exception') {
         		console.log('Error in refreshSitesCall',result,event);
            	KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
            	KenandyErp.UnBlockUI();
            }else {	   
            	if(result.success){                    
                	deferred.resolve(result, event);
            	}else{
            		console.log('Error in refreshSitesCall',result,event);
	                KenandyErp.Messages(result.messages, messageElement);	
					KenandyErp.UnBlockUI();
	            }
			}	 	
            {escape: false}
    	}
    );
    return deferred.promise();
}
//KNDY-13289 - remove site linkages from yodlee
var removeSites = function (element){
	var self = this;
    var grid = self.grid;
    var options = self.options; 
    var messageElement = grid.element.closest("div.grid-container").find("div.grid-message:first");
	var row = $(element.target).closest("tr"); //get the row for deletion
    var dataItem = grid.dataItem(row); // get the row data
    if (dataItem != null) {
	    var accountId = dataItem.get('siteId');
		var promise = removeSitesCall(accountId);  
		promise.done(function(result,event){
			if(result != undefined && result.success){  
		    	startSiteLinkage();
		    }
		});
	}
}
//KNDY-13289 - calls remote function to remove yodlee site linkages
var removeSitesCall = function (arrSiteId){
	console.log('in removeSitesCall'); 
	var deferred = $.Deferred();
    KenandyErp.BlockUI();
    KenandyErp.ClearMessage(messageElement);
    Visualforce.remoting.Manager.invokeAction(
    	(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.removeSiteAccounts',
    	args.cobrandsession,
		args.usersession,
    	 arrSiteId, 
         function (result, event) {
         	if (event.type == 'exception') {
         		console.log('Error in removeSitesCall',result,event);
            	KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
                KenandyErp.UnBlockUI();
            }else {	   
            	if(result.success){
                	deferred.resolve(result, event);
            	}else{
            		console.log('Error in removeSitesCall',result,event);
	                KenandyErp.Messages(result.messages, messageElement);	
	            }
	            KenandyErp.UnBlockUI();
			}	 	
            {escape: false}
    	}
    );
    return deferred.promise();
}
//KNDY-13289 - edit site credential which is already linked
var editSiteCredentials = function(element){
	        
	var self = this;
    var grid = self.grid;
    var options = self.options; 
    var messageElement = grid.element.closest("div.grid-container").find("div.grid-message:first");
	var row = $(element.target).closest("tr"); //get the row for deletion
    var dataItem = grid.dataItem(row); // get the row data
    var accountId = dataItem.get('siteId');
    console.log('accountId');
    console.log(accountId);
    var arrBankIds = [];
    arrBankIds.push(accountId);   
    $("input[id=extraParams]").val('siteAccountId='+accountId+'&flow=edit');
	 startAddAccount();  
	
}
//KNDY-13289 - on confirmation of delink it will start delinking kenandy account with yodlee
var okToDelink = function(){
	delinkWindow.close();
	$('#yDelinkMsgDiv').data('kendoWindow').close();
	
	console.log(arrDelinkBankIds); 
	var promise = delinkBA(arrDelinkBankIds);  
	promise.done(function(result,event){
		if(result != undefined && result.success){  
			startSiteLinkage();
		}

	}); 
}
//delink bank accounts  - opens up confirmation dialog before delinking
var delinkBankAccounts = function(element){
	console.log('in delinkBankAccounts'); 

		var self = this;
	    var grid = self.grid;
	    var options = self.options; 
	    var messageElement = grid.element.closest("div.grid-container").find("div.grid-message:first");
		var row = $(element.target).closest("tr"); //get the row for deletion
	    var dataItem = grid.dataItem(row); // get the row data
	    var accountId = dataItem.get('Id');
	    arrDelinkBankIds = [];
	    arrDelinkBankIds.push(accountId); 
	    console.log(arrDelinkBankIds); 
    	$("#yDelinkMsgDiv").removeClass("NoShow");
	    $("#yDelinkMsgDiv").show(); 
	    delinkWindow.center().open();
	    
	
}
//delink remote call to controller
var delinkBA = function(arrBankIds){
	console.log('in delink'); 

	KenandyErp.BlockUI();
    KenandyErp.ClearMessage(messageElement);
	var deferred = $.Deferred();
    Visualforce.remoting.Manager.invokeAction(
    	(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeUserRegistrationAndAccountLinkExt.delinkBankAccount',
    	 arrBankIds, 
         function (result, event) {
         	if (event.type == 'exception') {
         		console.log('Error in delinkBA',result,event);
            	KenandyErp.Message(event.message,KenandyErp.MessageType.Error,messageElement);	
                KenandyErp.UnBlockUI();
            }else {	   
            	if(result.success){
                	deferred.resolve(result, event);
            	}else{
            		console.log('Error in delinkBA',result,event);
	                KenandyErp.Messages(result.messages, messageElement);	
	            }
	            KenandyErp.UnBlockUI();
			}	 	
            {escape: false}
    	}
    );
    return deferred.promise();
}