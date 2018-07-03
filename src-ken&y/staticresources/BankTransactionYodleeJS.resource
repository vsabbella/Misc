	var args = {};                       //used to keep all the criterias which is passed to yodlee for pulling transactions
	var cobrandsession;                  //used to keep cobrandsession value
	var usersession;                     //used to keep usersession value
	var bankTransaction=[];				 //used to keep all the bank transactions pulled from yodlee for all accounts
	var transactionCount;				 //used to keep transaction count for an account
	var NoOfTransactionBatches;          //used to keep count of transaction batches for an account
	var lstBankAccount = [];             //used to keep list of all bank account for which the transactions will be pulled from yodlee
	var lengthOflstBankAccount;          //used to keep the count of number of accounts for which the transactions will be pulled from yodlee
	var currentIndexOfBankAccount = 0;   //used to store the current index of the bank account which is under processing
	var loginApiCallCount = 0;           //used to store the count of login api call in case of login failure     
	var savebatchCount = 0;				 //used to store the count of number of batches holding bank transactions to be saved
	var arrayBT = [];					 //used to store the arrays of spliced bank transactions to be saved
	var isErrorOnSave = false;			 //used to validate whether any batch got failed while saving bank transactions
	var isFetchAllTransactions = false;	 //used to indicate whether the current context is Fetch All Transactions or Fetch Transactions from Manage Bank Transaction page
    var tempBatchCount = 0;
	$(document).ready(function() {
        args = {cobrandsession:cobrandsession, 
        		usersession:usersession, 
        		container:'', /*bank/creditCard/investment/insurance/loan*/
        		baseType:'', /*CREDIT/DEBIT*/
        		keyword:'',/*Transaction search text*/
        		bankAccountId:'',
        		fromDate:'',
        		toDate:'',
        		categoryId:'', /*Comma separated categoryIds*/
        		highLevelCategoryId:'',/*Comma separated highLevelCategoryIds*/
        		type:'', /*Transaction Type(SELL,SWEEP, etc.) for bank/creditCard/investment*/
        		categoryType:'', /*Transaction Category Type(UNCATEGORIZE, INCOME, TRANSFER, EXPENSE or DEFERRED_COMPENSATION)*/
        		//KNDY-18903- record was missing while fetching it from yodlee so kept index always start with 0 and in multiplication of 500 
        		skip:'0', /*skip (Min 1)*/
        		top:'500'  /*top (Max 500)*/        		        
        		};													                 
    });	
 
	//this method is used to call login, search and save method for one bank account
    var cobrandloginAndSearch = function(bankAccount){
        tempBatchCount = 1;
    	args.accountId = bankAccount;
    	var promise = cobrandAndUserlogin();
    	var searchpromise;
    	promise.done(function(){
            console.log('in  promise cobrandloginAndSearch');
            var getTransCountPromise = getTransactionsCount(args.cobrandsession,
                args.usersession,bankAccount,args.fromDate,args.toDate);
            getTransCountPromise.done(function(){
    		var searchpromise = searchBankTransaction(args);
			searchpromise.done(function(){
				searchHelper();
			});
        });   
        });   
    }

    //this method is used to call login, search and save method for multiple bank accounts
    var cobrandloginAndSearchForMultipleAccount = function(lstAccount,fromDate,toDate){
    	console.log('in cobrandloginAndSearchForMultipleAccount');
    	//resetting global variables for each click of search
    	KenandyErp.BlockUI();
    	lstBankAccount.length = 0;
    	currentIndexOfBankAccount = 0;
    	loginApiCallCount = 0;
    	savebatchCount = 0;
    	bankTransaction.length = 0;
    	arrayBT.length = 0;
    	args.top = '500';
    	//KNDY-18903- record was missing while fetching it from yodlee so kept index always start with 0 and in multiplication of 500
    	args.skip = '0';
    	NoOfTransactionBatches = undefined;
    	$.each(lstAccount, function(index, element){
    		lstBankAccount.push(element);
    	});
    	lengthOflstBankAccount = lstBankAccount.length;
    	args.fromDate = fromDate;
    	args.toDate = toDate;
    	console.log('lengthOflstBankAccount',lengthOflstBankAccount,lstBankAccount);
    	cobrandloginAndSearch(lstBankAccount[currentIndexOfBankAccount]);
    }
    
    var getTransactionsCount = function(cobrandsession,
        usersession,bankAccountId,fromDate,toDate){
       console.log('in  getTransactionsCount ');
        KenandyErp.BlockUI();
        var deferred = $.Deferred();
        Visualforce.remoting.Manager.invokeAction(
            (nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeTransactionSearchExt.getTransactionsCount',
            cobrandsession,
            usersession,
            bankAccountId,
            fromDate,
            toDate,
            function (result, event) {
                if (event.type == 'exception') {
                    console.log('Error in cobrandAndUserlogin',result,event);
                    KenandyErp.Message(event.message);
                    KenandyErp.UnBlockUI();
                    console.log('event.message - '+event.message);
                }else{     
                    if(result.success == true && typeof result.records != 'undefined'){ 
                        console.log('Transaction Count Result - '+result.records[0]);
                        transactionCount = result.records[0]; //transactions count
                        //NoOfTransactionBatches = Math.ceil(transactionCount/500);
                        deferred.resolve(result, event);
                    }else{      
                        console.log('Error in cobrandAndUserlogin',result,event); 
                        //KNDY-18903  fixed error message the way of showing on pop up                       
						userMessages(result.messages[0].message, KenandyErp.MessageType.ERROR);
                        KenandyErp.UnBlockUI();
                    }
                }
            }
        );
        return deferred.promise();      
    } 
    
    //this method is used to get cobrand and user session
    var cobrandAndUserlogin = function(){
    	console.log('in  cobrandAndUserlogin ');
    	KenandyErp.BlockUI();
    	var deferred = $.Deferred();
    	Visualforce.remoting.Manager.invokeAction(
			(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeTransactionSearchExt.cobrandAndUserlogin',
			function (result, event) {
			    if (event.type == 'exception') {
                    console.log('Error in cobrandAndUserlogin',result,event);
					KenandyErp.Message(event.message);
					KenandyErp.UnBlockUI();
					console.log('event.message - '+event.message);
				}else {	    
					if(result.success == true){	
						console.log('Cobrand session - '+result.records[0]);
						console.log('User session - '+result.records[1]);  
						args.cobrandsession = result.records[0]; 
						args.usersession = result.records[1];
						deferred.resolve(result, event);
					}else{		
                        console.log('Error in cobrandAndUserlogin',result,event);
                        var messageElement = document.getElementById("message");
						if(messageElement != undefined){
							KenandyErp.ClearMessage(messageElement);
						}
						KenandyErp.Messages(result.messages, messageElement);
					    KenandyErp.UnBlockUI();
					}
				}
			}
		);  
		return deferred.promise();     
    }
    
    //this method is used to search bank transactions associated with a bank account passing cobrand and user session as additional filters
    var searchBankTransaction = function(args) {
	    console.log('in  searchBankTransaction ');
	    console.log('usersession - '+args.usersession);
	    console.log('args.cobrandsession - '+args.cobrandsession);
	    console.log('fromDate - '+args.fromDate);
	    console.log('toDate - '+args.toDate);
    	console.log('bankAccountId - '+args.accountId);
    	var Memo = (nspaceForYodlee?nspaceForYodlee+'__Memo__c':'Memo__c');
    	var Source = (nspaceForYodlee?nspaceForYodlee+'__Source__c':'Source__c');
    	var Payment_Method = (nspaceForYodlee?nspaceForYodlee+'__Payment_Method__c':'Payment_Method__c');
    	var Transaction_Type = (nspaceForYodlee?nspaceForYodlee+'__Transaction_Type__c':'Transaction_Type__c');
    	var Amount = (nspaceForYodlee?nspaceForYodlee+'__Amount__c':'Amount__c');
    	var Category = (nspaceForYodlee?nspaceForYodlee+'__Category__c':'Category__c');
    	var Account = (nspaceForYodlee?nspaceForYodlee+'__Account__c':'Account__c');
    	var Account_Number = (nspaceForYodlee?nspaceForYodlee+'__Account_Number__c':'Account_Number__c');
    	var Reference_Number = (nspaceForYodlee?nspaceForYodlee+'__Reference_Number__c':'Reference_Number__c');
    	var Description = (nspaceForYodlee?nspaceForYodlee+'__Description__c':'Description__c');
    	var Transacted_With = (nspaceForYodlee?nspaceForYodlee+'__Transacted_With__c':'Transacted_With__c');
    	var Transaction_Id = (nspaceForYodlee?nspaceForYodlee+'__Transaction_Id__c':'Transaction_Id__c');
    	var Transaction_Date = (nspaceForYodlee?nspaceForYodlee+'__Transaction_Date__c':'Transaction_Date__c');
    	var SubTransaction_Type = (nspaceForYodlee?nspaceForYodlee+'__SubTransaction_Type__c':'SubTransaction_Type__c');
    	KenandyErp.BlockUI();
    	var deferred = $.Deferred();
    	if(args.cobrandsession != undefined && args.usersession != undefined){
	    	Visualforce.remoting.Manager.invokeAction(
					(nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeTransactionSearchExt.searchBankTransactions',
					args.cobrandsession,
					args.usersession,
					args.container,
					args.baseType,
					args.keyword,
					args.accountId,
					args.fromDate,
					args.toDate,
					args.categoryId,
					args.highLevelCategoryId,
					args.type,
					args.categoryType,
					args.skip,
					args.top,
					function (result, event) {
						if (event.type == 'exception') {
                            console.log('Error in searchBankTransaction',result,event);
							KenandyErp.Message(event.message);
							KenandyErp.UnBlockUI();
						}else{
							//console.log('result - '+result.records);
                            if(result.success == true){	
								var bT = jQuery.parseJSON(result.records); 
                                console.log('bt transaction- '+bT.transaction);
                                //console.log('bt - ',bT);
							 	//if no error occured
                                if(bT.transaction != undefined && bT.transaction.length >0){  //if the search returns more than zero records
                                    $.each(bT.transaction, function(index, element){
                                        //console.log('element - ',element);
										var btjson = jQuery.parseJSON('{"attributes":{"type":"Bank_Transaction__c"}}');
	         							delete btjson['attributes'];
                                        if (element['description'] != undefined){
                                            btjson[Memo]=element['description']['original'];
                                            btjson[Description]=element['description']['original']; 
                                        }
										btjson[Source] = 'Yodlee';
                                        btjson[Payment_Method]=element['type']; //populating type
                                        btjson[Transaction_Type] = element['baseType'];     //populating entry type										
                                        if(element['baseType'].toLowerCase() == 'debit' ){
											btjson[Amount]=-1*element['amount']['amount'];
										}else{
											btjson[Amount]=element['amount']['amount'];
										}
                                        btjson[Category]=element['category'];
                                        //btjson[Account]=element['account']['accountName'];
                                        btjson[Account_Number]=String(element['accountId']);
                                        btjson[Reference_Number]=element['checkNumber']; 
                                        
                                        btjson[Transacted_With]=element['merchant'] != undefined ? element['merchant']['name'] : ''; 
                                        btjson[Transaction_Id]=String(element['id']);
										//btjson.Post_Date__c=new Date(element.postDate).getTime();
                                        btjson[Transaction_Date] = new Date(element['postDate']).getTime();
                                        /* if (transactionCount == undefined) 
                                            transactionCount = 1;
                                        else
                                            transactionCount ++; */ //= element['viewKey']['transactionCount'];
										bankTransaction.push(btjson);
									});	
									console.log('bankTransaction size - '+bankTransaction.length);
									if(NoOfTransactionBatches == undefined){  //for getting number of batches for individual bank accounts
										NoOfTransactionBatches = Math.ceil(transactionCount/500);
										console.log('NoOfTransactionBatches - '+NoOfTransactionBatches);
                                        NoOfTransactionBatches--;
									}
                                    if(NoOfTransactionBatches >= 1){  //keep looping to get all the batches for individual bank accounts
										console.log('in >1 - '+NoOfTransactionBatches);
                                        //args.top = 500*NoOfTransactionBatches;
                                        args.top = 500;
                                        //if(NoOfTransactionBatches != tempBatchCount){   
                                        //KNDY-18903- record was missing while fetching it from yodlee so kept index always start with 0 and in multiplication of 500 
                                        args.skip = ((tempBatchCount)*500);
                                        console.log('no of records fetched per transaction - '+args.top);
                                        console.log('lowerFetchLimit - '+args.skip);
										NoOfTransactionBatches--;
                                            tempBatchCount++;
										var searchpromise = searchBankTransaction(args);
								    	searchpromise.done(function(){
								    		KenandyErp.UnBlockUI();
                                                //tempBatchCount ++;
								    		searchHelper();
								    	});
                                         //}  
									}else{
                                        if(NoOfTransactionBatches == 0){ 
										//if this is the last batch then transfer the control 
								        //to save the record or to fetch the transactions for next account
											deferred.resolve(result, event);
										}
									}
                                    console.log('lstbT - ',bankTransaction);
								}else{ //if the returned transactions is blank for current account
									if(currentIndexOfBankAccount==lengthOflstBankAccount-1){
										deferred.resolve(result, event);
									}else{
										searchHelper();	
									}	
								}
							}else{ // if an error occured during a call for a batch of transactions, say session expired
								if(loginApiCallCount<10){
									loginApiCallCount++;
									var loginpromise = cobrandAndUserlogin();
							    	loginpromise.done(function(){
                                        var accountId = lstBankAccount.join(',');
                                        args.accountId = accountId;//lstBankAccount[currentIndexOfBankAccount];
							    		var searchpromise = searchBankTransaction(args);
							    		searchpromise.done(function(){
											searchHelper();		
							    		});
							    	});
							    }else{
                                    console.log('Error in searchBankTransaction',result,event);
                                    var messageElement = document.getElementById("message");
                                    if(messageElement != undefined){
                                        KenandyErp.ClearMessage(messageElement);
                                    }
                                    KenandyErp.Messages(result.messages, messageElement);
					    			KenandyErp.UnBlockUI();
							    }
							}
						}
					},
				    {escape: false}
			);
		}else{ // if the cobrand and user session is unavailable
			if(loginApiCallCount<10){
				loginApiCallCount++;
				var loginpromise = cobrandAndUserlogin();
				loginpromise.done(function(){
					var accountId = lstBankAccount.join(',');
					args.accountId = lstBankAccount[currentIndexOfBankAccount];
					var searchpromise = searchBankTransaction(args);
					searchpromise.done(function(){
						searchHelper();
					});
				});
			}else{
				userMessages('Login Attempt Failed. Please try after some time.',KenandyErp.MessageType.Error);
				KenandyErp.UnBlockUI();
			}
		}
		return deferred.promise();
    }
    
    //this method is used to call save bank transaction method multiple times to save multiple batches of records parallely
     var sliceBankTransaction = function(){
     	console.log('in sliceBankTransaction');
     	console.log('bankTransaction length'+bankTransaction.length);
     	KenandyErp.BlockUI();
     	if(bankTransaction != undefined && bankTransaction.length>200){ 
     		console.log('in if');
     		while(bankTransaction.length>0){
     			arrayBT.push(bankTransaction.splice(0,200));
     			console.log('arrayBT'+arrayBT);
     		}
     		savebatchCount = arrayBT.length;
     		console.log('savebatchCount in slice'+savebatchCount);
            saveBankTransaction(arrayBT[savebatchCount-1]);
 
		}else{
			console.log('in else');
			if(bankTransaction != undefined && bankTransaction.length<=200 && bankTransaction.length>0){
				saveBankTransaction(bankTransaction);
			}
		}
     }
     
     //this is a helper method which decides whether the search method is called multiple times of the save method is called as 
     //pulling of all batches are complete
     var searchHelper = function(){
        tempBatchCount = 1;
     	console.log('in searchHelper');
     	KenandyErp.BlockUI();
     	if(currentIndexOfBankAccount<lengthOflstBankAccount-1){
     		currentIndexOfBankAccount++;
     		args.top = '500';
     		//KNDY-18903- record was missing while fetching it from yodlee so kept index always start with 0 and in multiplication of 500
    		args.skip = '0';
    		var accountId = lstBankAccount.join(',');
    		args.accountId = lstBankAccount[currentIndexOfBankAccount];
			NoOfTransactionBatches = undefined;
			var searchpromise = searchBankTransaction(args);
			searchpromise.done(function(){
				searchHelper();
			});
		}else{
			if(bankTransaction != undefined && bankTransaction.length > 0){
				sliceBankTransaction();
			}else{
				var messageElement = document.getElementById("message");
				if(messageElement != undefined){
					KenandyErp.ClearMessage(messageElement);
				}
				userMessages('Records are successfully imported.',KenandyErp.MessageType.Info);
				KenandyErp.UnBlockUI();
			}
			
		}
     }

     //this method is used to save bank transaction records in bank transaction object
     var saveBankTransaction = function(bTtoSave){
     	KenandyErp.BlockUI();
     	console.log('in  saveBankTransaction ');
     	Visualforce.remoting.Manager.invokeAction(
		    (nspaceForYodlee?nspaceForYodlee +'.':'') + 'YodleeTransactionSearchExt.saveBTs',
		    bTtoSave,
			function (result, event) {
            	if (event.type == 'exception') {
            		isErrorOnSave = true;
			    } 
			    console.log('savebatchCount in save'+savebatchCount);
			    if(savebatchCount>1){
			    	savebatchCount--;
			    	saveBankTransaction(arrayBT[savebatchCount-1]);
			    }else{
			    	var messageElement = document.getElementById("message");
					if(messageElement != undefined){
						KenandyErp.ClearMessage(messageElement);
					}
				    if(isErrorOnSave==true){
				   		userMessages('Records may be partially imported. There are some errors occured while processing. Please retry by changing your search date range.', KenandyErp.MessageType.Warning);
				   	}else{
				   		userMessages('Records are successfully imported.', KenandyErp.MessageType.Info);
				   	}
			    	KenandyErp.UnBlockUI();
			    }

             },
		     {escape: false}
		  );
	 }

	//this method will return the javascript date into yodlee accepted format. 
	var yyyymmdd = function(datef) {
        d= new Date(datef);
        var yyyy = d.getFullYear().toString();
        var mm = (d.getMonth()+1).toString(); // getMonth() is zero-based
        var dd  = d.getDate().toString();  
        return   yyyy +'-' + (mm[1]?mm:"0"+mm[0])+ '-' +(dd[1]?dd:"0"+dd[0]) ;
     }
     
     //this method is used to display error on screen
     var userMessages = function(displayMessage,severity){
    	var message;
		var messageElement = document.getElementById("user-message");
		if(isFetchAllTransactions){
			var pageMessageElement = document.getElementById("page-message");
			if(pageMessageElement != undefined){
				message = pageMessageElement;
			}
		}
		else if(messageElement != undefined){
			message = messageElement;
		}else{
			/*var frameMessageElement = $("#yodleePopUp").children(".k-content-frame").contents().find("#user-message");
			if(frameMessageElement != undefined){
			    message = frameMessageElement;
			}*/
			var frameMessageElement = $("#yodleePopUp").children(".k-content-frame").contents().find("#message");
			if(frameMessageElement != undefined){
			    message = frameMessageElement;
			}
			var importAllButton = $("#yodleePopUp").children(".k-content-frame").contents().find("#allTransaction");
			if(importAllButton != undefined){
				importAllButton.show();
			}
			var importButton = $("#yodleePopUp").children(".k-content-frame").contents().find("#searchFilter");
			if(importButton != undefined){
				importButton.show();
			}
		}
		if(message != undefined){
			KenandyErp.ClearMessage(message); 
			KenandyErp.Message(displayMessage, severity, message);
		}

    }
	
