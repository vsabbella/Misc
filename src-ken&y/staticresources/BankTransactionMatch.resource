
var AutoMatchUtil = function () {
    return{
        excludeFromPoolBTsSet :new Set(),
        
        excludeFromPoolSDsSet :new Set(),
        
        suggestedMatches :[],
        
        potentialMatches :[],
        
        approveBTsList:[],
        
        inputBTList:[],
        
        dateFrom: null,
        
        dateTo: null,
        
        bankid : null,
        
        glAccId :null,
        
        NameSpaceUU: null,
        
        namespace:null,
        
        btmChunkSize: 200,
        btmSaveException: false,
        
        sourceDocslst: {records:[],success:false},
        
        Init: function(){
        AutoMatchUtil.excludeFromPoolBTsSet =new Set();
        AutoMatchUtil.excludeFromPoolSDsSet =new Set();
        AutoMatchUtil.suggestedMatches =[];
        AutoMatchUtil.potentialMatches =[];
        AutoMatchUtil.approveBTsList=[];
        AutoMatchUtil.inputBTList=[];
        //initialize variables from page 
            //AutoMatchUtil.dateFrom= $("#datepickerfrom").val();
		    //AutoMatchUtil.dateTo =$("#datepickerto").val();   
        AutoMatchUtil.bankid =bankid; 
        AutoMatchUtil.glAccId =glAccId; 
        AutoMatchUtil.NameSpaceUU =NameSpaceUU;
        AutoMatchUtil.namespace=namespace;
        AutoMatchUtil.sourceDocslst={records:[],success:false};
        },
        
        findMatch: function(rulesList,Transactions,sourcedocs){
            KenandyErp.CleanNamespace(rulesList, AutoMatchUtil.NameSpaceUU);
            KenandyErp.CleanNamespace(sourcedocs, AutoMatchUtil.NameSpaceUU);
            //
            AutoMatchUtil.inputBTList.forEach(function(btr){
                KenandyErp.CleanNamespace(btr.bankTransaction,AutoMatchUtil.NameSpaceUU);
            });
			selector =  $(".page-message");
			//KNDY-15787
			KenandyErp.ClearMessage(selector);
            if(rulesList == "undefined"  || (rulesList != undefined && rulesList.length == 0)) {
                
                KenandyErp.Message('There are no active rules for this bank account and/or company',KenandyErp.MessageType.ERROR,selector);
                console.log('no valid rules');
                return false;
            }else if(Transactions == undefined || (Transactions != undefined && Transactions.length==0)) {
                KenandyErp.Message('There are no valid bank transactions for this bank account',KenandyErp.MessageType.ERROR,selector);
                console.log('no valid rules');
                return false;
            }else if(sourcedocs == undefined ||(sourcedocs != undefined && sourcedocs.length==0 )) {
                KenandyErp.Message('There are no source documents to match against for this bank account',KenandyErp.MessageType.ERROR,selector);
                console.log('no valid rules');
                return false;
            }else if(rulesList==null || rulesList=="undefined" || !sourcedocs || !Transactions || Transactions.length==0 || sourcedocs.length==0 )   {
            	KenandyErp.Message(nomatchfound,KenandyErp.MessageType.INFO,selector);
                console.log('Some thing is missing rulesList,Transactions,sourcedocs.' +rulesList.length + '-'+Transactions.length+'-'+sourcedocs.length );
                return false;  
            }  
            
            Transactions.forEach(function(bt) {
                if(!AutoMatchUtil.excludeFromPoolBTsSet.has(bt.bankTransaction.Id)){//if BT is already confirm Matched then it should not be considered any further for matches
                    rulesList.forEach(function(rule) {
                        AutoMatchUtil.matchperRule(rule,bt,sourcedocs)  ;  
                    });
                }
            });
            return true;
        },
        
        matchperRule:function (rule,bt,sourcedocs){
            console.log('bt');
            console.log(bt);
            // iterate on source docs apply and apply rule
            var SDList=[];
            sourcedocs.forEach(function(Sdentry) {
                if(!AutoMatchUtil.excludeFromPoolSDsSet.has(Sdentry.recordId)){
                      if(AutoMatchUtil.matchAmount(rule,bt,Sdentry) && AutoMatchUtil.matchDate(rule,bt,Sdentry) && AutoMatchUtil.matchDocument(rule,bt,Sdentry) && AutoMatchUtil.matchCheck(rule,bt,Sdentry) && AutoMatchUtil.matchTransactedWith(rule,bt,Sdentry)){
                           console.log('FOUND A PERFECT MATCH !!!');
                           SDList.push(Sdentry);
                      }
                }
             });
            
            if(SDList.length>0){
                console.log(SDList[0]);
                var matchObj ={SDList : SDList , bt: bt, ruleId : rule['Id']};
                if(SDList.length==1 &&  rule['Keep_In_Match_Pool__c']==false){// "rule['Keep_In_Match_Pool__c']==false"  indicates 'Suggested' match
                    AutoMatchUtil.suggestedMatches.push(matchObj);
                    AutoMatchUtil.excludeFromPoolBTsSet.add(bt.bankTransaction.Id);
                    AutoMatchUtil.excludeFromPoolSDsSet.add(SDList[0].recordId); // confirmed records will have only one SD in SDList
                    if(rule['Auto_Approve__c']){
                    AutoMatchUtil.approveBTsList.push(bt['bankTransaction']['Id']);  
                    }
                    
                }else if(SDList.length>1 ||  rule['Keep_In_Match_Pool__c']  ){  //rule['Match_Type__c']=='Potential'
                    AutoMatchUtil.potentialMatches.push(matchObj);
                }
                SDList =[];
            }
            
        },
        
        matchAmount :function(rule,bt,Sdentry){
            if(rule['Amount__c']){
                amtThreshold= rule['Amount_Threshold__c'] ? rule['Amount_Threshold__c'] :0 ;
                amtbt =bt['bankTransaction']['Amount__c'];
                if(Sdentry['amountMatched']!='undefined' &&(Sdentry['amountMatched']<= amtThreshold +amtbt) && (Sdentry['amountMatched']>=amtbt - amtThreshold)){
                    console.log('amount matched !!!');
                    return true;
                }else{
                    return false;  
                }
            }else{
                // ignore if rule is not active for amount match 
                console.log('amount rule not active!!!');
                return true;
            }    
        },
        
        matchDate :function(rule,bt,Sdentry){
            if(rule['Transaction_Date__c']){
                dateThreshold= rule['Date_Threshold__c']  ? rule['Date_Threshold__c'] :0 ;
                tranDt =bt['bankTransaction']['Transaction_Date__c'];
                console.log('Compare Dates::');
                if(!(tranDt instanceof Date)){
                    tranDt= moment(tranDt);
                }
                sdTransactionDate = moment(Sdentry['transactionDate']).toDate().getTime();
                if(!(sdTransactionDate instanceof Date)) {
                    sdTransactionDate= moment(sdTransactionDate);
                }
                
                var tranDtzero = tranDt.startOf('day'); //equivalent of setHours(0,0,0,0);
                var sdTranDtZero = sdTransactionDate.startOf('day');//equivalent of setHours(0,0,0,0);
                
                var transDtZero_higher = moment(tranDtzero); //moment methods are mutable, so we need to clone/copy them
                transDtZero_higher = transDtZero_higher.add('days',dateThreshold);
                var transDtZero_lower = moment(tranDtzero)//moment methods are mutable, so we need to clone/copy them
                transDtZero_lower = transDtZero_lower.add('days',-1*dateThreshold);
                
                //moment 2.10+ supports isSameOrBefore and isSameOrAfter, but not this version.
                if((sdTranDtZero.isSame( transDtZero_higher) || sdTranDtZero.isBefore( transDtZero_higher)) && (sdTranDtZero.isSame(transDtZero_lower) || sdTranDtZero.isAfter(transDtZero_lower))){
                    console.log('Dates matched!!!');
                    return true;
                }else{
                    return false;
                }
            }else{
                // ignore if rule is not active for date match 
                return true;
            }
            
        },
        
        matchCheck :function(rule,bt,Sdentry){
            if(rule['Reference__c']){
                if(bt['bankTransaction']['Reference_Number__c'] && Sdentry['referenceNumber']){
                    if(AutoMatchUtil.crossMatchStrings(bt['bankTransaction']['Reference_Number__c'],Sdentry['referenceNumber'])){
                        return true;
                    }else{// if check numbers dont match then return false
                        return false;
                    }
                }else{// if bt reference number is null or Source doc does not have ref/Check number then return false
                    return false;
                }
                
            }else{// if rule not applicable then return true
              return true;   
            }
        },
        
        crossMatchStrings:function(string1,string2){ // remove special charactes and common words from string and match for each word in string
         listOfCommonWordsToReplace = ['check','chk','ach','atm'];
            
         string1=   string1.replace(/[^a-zA-Z0-9- ]/g, " ").toLowerCase();
         string2=   string2.replace(/[^a-zA-Z0-9- ]/g, " ").toLowerCase();
            listOfCommonWordsToReplace.forEach(function(commonStr){
               string1= string1.replace(commonStr,' ');
               string2= string2.replace(commonStr,' ');
            });
            
               console.log('string1,string2::::  ' + string1+ ' - '+ string2);
				var splited1 = string1.split(" ");
                var splited2 = string2.split(" ");
            matchSuccess=false;
            splited1.forEach(function(str1){
                splited2.forEach(function(str2){
                    if( str1 == str2 && str2.length>0 && str1.length>0){
               				 matchSuccess=true;
           			 }
                })
            });
            return matchSuccess;   
            
        },
        
        matchTransactedWith:function(rule,bt,Sdentry){
            var  success= false;
            var btTransactedWith = bt['bankTransaction']['Transacted_With__c'];
             if(rule['Transacted_With__c']){
                 console.log('matchTransactedWith:::' +btTransactedWith  + '--'+Sdentry['aliases']);
                 if((Sdentry['aliases'] && !btTransactedWith) ||(!Sdentry['aliases'] && btTransactedWith) || (!Sdentry['aliases'] && !btTransactedWith)  ){
                     success=false; // false if any of the transacted with or Alias is false
                 }else{// validate if the transacted with name is available in the list
                     SDaliasesList =[];
                     SDaliasesList =Sdentry['aliases'].split('~');
                     SDaliasesList.forEach(function(alias){
                       if(alias.toLowerCase()==btTransactedWith.toLowerCase()){
                       success=true;
                     }
                     });
                     console.log('matchTransactedWith :::'+success);
                 return success;
                 }
             }else{
                 return true;
             }
            
                        
        },
        
        matchDocument:function(rule,bt,sdentry){
            console.log('matchDocument rule'+ rule);
            console.log(rule);
           var  success= false;
             if(rule['Documents__c']){
                documents =(rule['Documents__c']).split(';');
                 documents.forEach(function(doc){
                     console.log('matchDocument document'+ doc);
                     if(doc=='All'){
                         success= true;
                     }
                     if( (doc=='Customer Receipts' && sdentry['objectType']=='Customer_Receipt__c') || (doc=='Supplier Payments' && sdentry['objectType']=='Supplier_Payment__c')|| (doc=='Payments' && sdentry['objectType']=='Payment__c')|| (doc=='Journal Entry Lines' && sdentry['objectType']=='Journal_Entry_Line__c')){
                             success= true;
                       }
                 });
                 // if there document is not matching return false
                 return success;   
             }
            else{
               return true;         
             }
             
        },
        
        saveAutoMatches:  function(resolve,reject){
            AutoMatchUtil.btmSaveException= false;
            var BTMListToSave=[];
            var uniqueKeys= [];
            var field_Bank_Transaction__c=  AutoMatchUtil.NameSpaceUU+'Bank_Transaction__c';
            var field_Bank_Transaction_Date__c=  AutoMatchUtil.NameSpaceUU+'Bank_Transaction_Date__c';
            var field_Matched_To_Transaction_Date__c = AutoMatchUtil.NameSpaceUU+'Matched_To_Transaction_Date__c';
            var field_Amount__c =AutoMatchUtil.NameSpaceUU+'Amount__c';
            var field_Is_potential_Match= AutoMatchUtil.NameSpaceUU+'Is_Potential_Match__c';
           //fields for settting BTM fields for deletion process
            var field_Customer_Receipt__c = AutoMatchUtil.NameSpaceUU+'Customer_Receipt__c';
            var field_Supplier_Payment__c = AutoMatchUtil.NameSpaceUU+'Supplier_Payment__c';
            var field_Payment__c = AutoMatchUtil.NameSpaceUU+'Payment__c';
            var field_Journal_Entry_Line__c = AutoMatchUtil.NameSpaceUU+'Journal_Entry_Line__c';
            var field_Transaction_Mathching_Rule__c = AutoMatchUtil.NameSpaceUU+ 'Transaction_Mathching_Rule__c' ;
            var field_Unique_Key__c = AutoMatchUtil.NameSpaceUU+ 'Unique_Key__c' ;
            AutoMatchUtil.suggestedMatches.forEach(function(confirmedMatchObj) {
                confirmedMatchObj.SDList.forEach(function(SDEntry) {
                console.log('SDEntry for confirmed Match:');
                console.log(SDEntry);
                var objTypeField= AutoMatchUtil.NameSpaceUU+SDEntry['objectType'];
                var Bank_Transaction_Match = {};
                Bank_Transaction_Match[field_Bank_Transaction_Date__c]=moment(confirmedMatchObj.bt['bankTransaction']['Transaction_Date__c']).toDate().getTime(),
                Bank_Transaction_Match[field_Matched_To_Transaction_Date__c]=SDEntry['transactionDate'],
                Bank_Transaction_Match[field_Amount__c]=SDEntry['amountMatched'],
                Bank_Transaction_Match[objTypeField]=SDEntry['recordId'],  
                Bank_Transaction_Match[field_Is_potential_Match]= false,
                Bank_Transaction_Match[field_Bank_Transaction__c] =confirmedMatchObj.bt['bankTransaction']['Id'];
                Bank_Transaction_Match[field_Transaction_Mathching_Rule__c] = confirmedMatchObj.ruleId;
                var uniqueKey = Bank_Transaction_Match[field_Bank_Transaction__c] + Bank_Transaction_Match[objTypeField] + "";
                Bank_Transaction_Match[field_Unique_Key__c] = uniqueKey;
                if($.inArray(uniqueKey, uniqueKeys) === -1) {
                    uniqueKeys.push(uniqueKey);
                    console.log('confirmedMatchObj.ruleId: ' +confirmedMatchObj.ruleId);
                    BTMListToSave.push(Bank_Transaction_Match);
                }
                })
            });
            
           AutoMatchUtil.potentialMatches.forEach(function(potentialMatchObj) {
                potentialMatchObj.SDList.forEach(function(SDEntry) {
                    console.log('SDEntry for potential Match:');
                    console.log(SDEntry);
                    var objTypeField= AutoMatchUtil.NameSpaceUU+SDEntry['objectType'];
                    var Bank_Transaction_Match = {};
                    Bank_Transaction_Match[field_Bank_Transaction_Date__c]=moment(potentialMatchObj.bt['bankTransaction']['Transaction_Date__c']).toDate().getTime(),
                    Bank_Transaction_Match[field_Matched_To_Transaction_Date__c]=SDEntry['transactionDate'],
                    Bank_Transaction_Match[field_Amount__c]=SDEntry['amountMatched'],
                    Bank_Transaction_Match[objTypeField]=SDEntry['recordId'],  
                    Bank_Transaction_Match[field_Is_potential_Match]= true,
                    Bank_Transaction_Match[field_Bank_Transaction__c] =potentialMatchObj.bt['bankTransaction']['Id'];
                    Bank_Transaction_Match[field_Transaction_Mathching_Rule__c] = potentialMatchObj.ruleId;
                    var uniqueKey = Bank_Transaction_Match[field_Bank_Transaction__c] + Bank_Transaction_Match[objTypeField] + "";
                    Bank_Transaction_Match[field_Unique_Key__c] = uniqueKey;
                    if($.inArray(uniqueKey, uniqueKeys) === -1) {
                        uniqueKeys.push(uniqueKey);
                        console.log('potentialMatchObj.ruleId: ' +potentialMatchObj.ruleId);
                        BTMListToSave.push(Bank_Transaction_Match);
                    }
                    })
            });
           console.log('BTMListToSave');
           console.log(BTMListToSave);
           console.log('BTMListToSave.length');
           console.log(BTMListToSave.length);
           lstbtids =[];
           lstCRids =[];
           lstPMTids=[];
           lstSPids =[];
           lstJELids =[];
            //BTMIDs for autoLearn
           BTMIDs=[]; 
           console.log ('saveAutoMatches - calling SaveBTMChunks...');
           var resultpromise =  new Promise((resolve,reject) => {
                AutoMatchUtil.SaveBTMChunks(BTMListToSave,resolve,reject);
           });
               
           resultpromise.then(function(result){
               console.log(result);
               if (result && !result.success){
                    console.log('saveAutoMatches - Error while saving ::'+result.messages);
                    KenandyErp.Message(result.messages === null ? "There was an error while saving the matches. Please contact support." : result.messages, KenandyErp.MessageType.Error);
                   reject (result);
               }
               else if (result && result.success){
                                console.log('there is no exception , now delete other potential matches.');
                               btms= result.records;
                                var hasRecords=false;
                                if(btms)
                                btms.forEach(function(btm){
                                    BTMIDs.push(btm['Id']);
                                    if(btm['Id'] && !btm[field_Is_potential_Match]) {//  Saved confirmed match
                                      lstbtids.push(btm[field_Bank_Transaction__c]); 
                                      lstCRids.push(btm[field_Customer_Receipt__c]);
                                      lstSPids.push(btm[field_Supplier_Payment__c]); 
                                      lstPMTids.push(btm[field_Payment__c]); 
                                      lstJELids.push(btm[field_Journal_Entry_Line__c]); 
                                      hasRecords=true;
                                    }
                                })
                                console.log('lstbtids');
                                console.log(lstbtids);
                                if(hasRecords){
                                var rp =  new Promise((resolve,reject) => {
                                     AutoMatchUtil.MatchesforDeletionProcess(lstbtids,lstCRids,lstSPids,lstPMTids,lstJELids,resolve)
                                });   
                                rp.then(function(result){
                                    resolve();
								var arrBTMchunk = [];
								while (BTMIDs.length > 0) {
  									arrBTMchunk.push(BTMIDs.splice(0,500));       
								}
								if(arrBTMchunk.length>0){
									AutoMatchUtil.RememberAliasHelper(arrBTMchunk, 0);
								}
                                 });
                                    // rememberAlias can be optimized by cheking before hand that if the match was created
                                    // by a rule which was created by a rule having 'Transacted_with__c' as criteria then ignore to remember.
                                }else{
                                    resolve();
                                }
                                if (result.success) {
                                    
                                    console.log('Matches Saved Successfully');
                                    console.log(result.records);
                                }else {
                                    console.log(result.messages[0].message);
                                }
              }
          }).catch(function(e){
                console.log('saveAutoMatches promise catch exception')
                console.log(e);
               reject(e);
          });         
       },

        SaveBTMChunks: function(ListBTMs,resolve,reject){
           console.log ('inside SaveBTMChunks...');
           var BTMsSaved = [];
           var BTMchunk;
           var result;
           
           if(ListBTMs.length > 0){
                    while (ListBTMs.length > 0) {
                        BTMchunk = ListBTMs.splice(0,AutoMatchUtil.btmChunkSize);
                        console.log(' ListBTMs : ' + ListBTMs);
                        console.log(' BTMchunk to save: ' + BTMchunk);
                        var innerpromise = new Promise(function(resolve,reject){
                            result = AutoMatchUtil.SaveBTMs(BTMchunk,resolve, reject);
                        })
                        
                        innerpromise.then(function(data){
                                if ( data && data.success){
                                    BTMsSaved =  BTMsSaved.concat(data.records);
                                    console.log('BTMsSaved: ');
                                    console.log(BTMsSaved);
                                    
                                    if(ListBTMs.length <= 0){
                                        if (!AutoMatchUtil.btmSaveException){
                                            //resolving parent promise
                                            console.log('SaveBTMChunks - All BT Matches Saved Successfully');
                                            data.records = BTMsSaved;
                                            console.log (data.records);
                                            resolve(data);
                                        }
                                        else{ // some BTM chunks did not save successfully
                                           console.log('SaveBTMChunks - Error while saving some BTM Chunks::')
                                           console.log(data.messages);
                                           data.success = false;
                                           reject(data);
                                        }
                                    }
                                }
                                else{
                                    console.log('SaveBTMChunks - Error while saving BTM Chunks::')
                                    console.log(data.messages);
                                    reject(data);
                                }
                        }).catch(function(e){
                             console.log('SaveBTMChunks promise catch exception')
                             console.log(e);
                              reject(e);                             
                         });
                     }
                }
         },
        
        SaveBTMs: function (ListBTMs,resolve,reject){
           console.log ('inside SaveBTMs...');
           Visualforce.remoting.Manager.invokeAction(
                         (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.saveAutoMatches',
                        ListBTMs,
                        function (result, event) {
                            console.log('SaveBTMs - saved BTMs:');
                            console.log( result);
                            if(event.type==='exception'){
                                AutoMatchUtil.btmSaveException = true;
                                console.log('SaveBTMs - Error while saving ::'+event.message)
                                KenandyErp.Message(event.message === null ? "There was an error while saving the matches. Please contact support." : event.message, KenandyErp.MessageType.Error);
                                reject(event);
                            }
                            else{
                                if (result.success) {
                                    console.log('SaveBTMs - BTMs Saved Successfully');
                                    console.log(result.records);
                                    resolve(result);
                                }else {
                                    console.log('SaveBTMs - Unable to save BTM: ');
                                    console.log(result.messages);
                                    KenandyErp.Message(result.messages === null ? "There was an error while saving the matches. Please contact support." : result.messages[0].message, KenandyErp.MessageType.Error);
                                    AutoMatchUtil.btmSaveException = true;
                                    reject(result);
                                }
                            }
                        },
                        {escape: false, timeout: 120000}
           );  
        },
        
        RememberAliasHelper:function(lstBTM,currentBatch){  
        	var promise = AutoMatchUtil.rememberAlias(lstBTM[currentBatch]);
			currentBatch = currentBatch+1;
			promise.done(function(){
                if(currentBatch<lstBTM.length){
					AutoMatchUtil.RememberAliasHelper(lstBTM,currentBatch);
                }
			});
        },
        
        MatchesforDeletionProcess:function(ListBts,lstCRids,lstSPids,lstPMTids,lstJELids,resolve){
          Visualforce.remoting.Manager.invokeAction(
                         (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.getDeletionList',
                        ListBts,lstCRids,lstSPids,lstPMTids,lstJELids,
                        function (result, event) {
                            console.log('getDeletionList:' + result)
                            if(event.type==='exception'){
                                console.log('Error while getDeletionList for potential matches ::'+event.message)
                            }
                            else{ 
                                console.log('Delete matches' + result.records);
                                var BTMchunk;
                                if(result.records){
                                    if(result.records.length == 0){AutoMatchUtil.AutoApproveBankTransactions(AutoMatchUtil.approveBTsList,resolve);}
                                  while (result.records.length > 0) {
  										BTMchunk = result.records.splice(0,5000)
 										 console.log(BTMchunk)
                                         AutoMatchUtil.deletepotentialMatches(BTMchunk,resolve);
									}
                                }else{
                                //AutoApprove Bank Transactions . This is not related to Deletion but auto approval should be fired after deletion or if no records are available for deletion
                                AutoMatchUtil.AutoApproveBankTransactions(AutoMatchUtil.approveBTsList,resolve);
                                }
                               
                            }
                           
                        }
          )},
        
        deletepotentialMatches: function(btmListToDelete,resolve){
             Visualforce.remoting.Manager.invokeAction(
                         (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.deletepotentialMatches',
                       btmListToDelete,
                        function (result, event) {
                            console.log('getDeletionList:' + result)
                            if(event.type==='exception'){
                                resolve();
                                console.log('Error while getDeletionList for potential matches ::'+event.message)
                            }
                            else{ 
                                console.log('Delete matches' + result.records);
                                //AutoApprove Bank Transactions . This is not related to Deletion but auto approval should be fired after deletion
                                AutoMatchUtil.AutoApproveBankTransactions(AutoMatchUtil.approveBTsList,resolve);
                            }
                            return result.records;
                        }
          )},
        
        AutoApproveBankTransactions: function(approveBTsList,resolve){
          Visualforce.remoting.Manager.invokeAction(
                         (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.approvedMatchedBankTransaction',
                approveBTsList,
                function (result, event) {
                    resolve("autoapproved");
                	if(event.type === 'exception'){
                		  KenandyErp.Message(event.message === null ? "There was an error. Please contact support." : event.message, KenandyErp.MessageType.Error);
                	}
                	else{
                        console.log('Approved BT List' +approveBTsList );
                        console.log(result.records);
                        console.log(result.messages);
                    }
                })
        },
        
        // create and update test classes
        SourceDocsList : function(bankAccountId,GLAccountId,type,resolve){
        console.log(type);
        Visualforce.remoting.Manager.invokeAction(
             (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.getMatchingTransactionsforAutoMatch',
			bankAccountId, 
			type,
            function(result, event){
                if (event.type == 'exception') {
                    console.log('Exception!!!');
                    console.log(event.message);
                }else{
                Array.prototype.push.apply(AutoMatchUtil.sourceDocslst.records, result.records);
                resolve();
                }
            },
            {escape: false}
        );
    },
   
        getBankTransactionsForMatching :function(bankAccountId){
        var deferred = $.Deferred();
	              var messageElement = document.getElementById("date-message");
	       //Make AJAX Call to get the Bank transaction records 
	       Visualforce.remoting.Manager.invokeAction(
	            (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.getAllBankTransactions',
	           bankAccountId,
	           function(result, event){           
	              deferred.resolve(result, event);
	              if (event.type == 'exception') {
                       console.log('Exception!!!');
                      console.log(event.message);
                  }else{
                  		if (result.success) {
                            AutoMatchUtil.inputBTList= result.records;
                            console.log(result.records);
                        }
                  }
	           },
	           {escape: false}     
	       );  
		
	       return deferred.promise();	   
   },
        
        rememberAlias: function(btmIdList){
        	AutoMatchUtil.Init();//KNDY-15576
        	var deferred = $.Deferred();
               Visualforce.remoting.Manager.invokeAction(
	            (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.learnAlias',
	           btmIdList,
	           function(result, event){           
	              if (event.type == 'exception') {
                       console.log('Exception!!!');
                       console.log(event.message);
                  }else{
                  		if (result.success) {
                            console.log(result.records);
                        }else{
                            var MessageElement = $(".grid-message");
                            if(MessageElement != undefined){
                        		KenandyErp.Messages(result.messages, MessageElement);
                        	}
                        }
                  }
                  deferred.resolve(result, event);
	           },
	           {escape: false}     
	       ); 
	       return deferred.promise(); 
        },
        
     /*   unLearnAlias: function(btmIdList){
        	var deferred = $.Deferred();
               Visualforce.remoting.Manager.invokeAction(
                    (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.unlearnAlias',
	           btmIdList,
	           function(result, event){           
	              //deferred.resolve(result, event);
	              if (event.type == 'exception') {
                       console.log('Exception!!!');
                       console.log(event.message);
                       KenandyErp.Message(event.message === null ? "There was an error. Please contact support." : event.message, KenandyErp.MessageType.Error);
                       deferred.reject(result, event);
                  }else{
                  		if (result.success) {
                            console.log(result.records);
                            deferred.resolve(result, event);
                        }else{
                        	deferred.reject(result, event);
                        	console.log(result.messages);
                        }
                  }
	           },
	           {escape: false}     
	       ); 
	       return deferred.promise();  
        },*/
        
        confirmMatch: function(btmId,resolve){
            AutoMatchUtil.Init();
            var listbtmIDs = [];
            listbtmIDs.push(btmId);
               Visualforce.remoting.Manager.invokeAction(
                         (AutoMatchUtil.namespace? AutoMatchUtil.namespace+'.':'')+ 'BankTransactionMatchExt.ConfirmMatchAndDeleteOthers',
                listbtmIDs,
                function (result, event) {
                    resolve();
                	if(event.type === 'exception'){
                		  KenandyErp.Message(event.message === null ? "There was an error. Please contact support." : event.message, KenandyErp.MessageType.Error);
                	}
                	else{
                        console.log(' deleted records as part of confirmation ' +result.records );
                        console.log(result.records);
                        console.log(result.messages);
                        
                    }
                })
        },
        
        execute: function(){
           KenandyErp.BlockUI();

           AutoMatchUtil.Init();
           $.when(AutoMatchUtil.getBankTransactionsForMatching(AutoMatchUtil.bankid)).done(function(result0){
           console.log('result:' +result0);// check if result0 then dont call find sourcedocs\
           var types = ['Customer_Receipt__c','Supplier_Payment__c','Payment__c','Journal_Entry_Line__c'];
           var requests = types.map((type) => {
   			 return new Promise((resolve) => {
     	       AutoMatchUtil.SourceDocsList(AutoMatchUtil.bankid,AutoMatchUtil.glAccId, type,resolve);
    		});
			})
			selector =  $(".page-message");//KNDY-15787
			KenandyErp.ClearMessage(selector);//KNDY-15787
           Promise.all(requests).then(function (){
                console.log('****************completed PaymentsReceiptsList'  + '-'+ result0.records);
                if(AutoMatchUtil.sourceDocslst.records && result0.records){
                	//KNDY-15787 - fetch rules before automatch starts
                	var rulePromise =  ReconcileUtils.MatchingRules();					
					rulePromise.done(function(){
                    AutoMatchUtil.findMatch(rulesList,AutoMatchUtil.inputBTList,AutoMatchUtil.sourceDocslst.records);
                    if(AutoMatchUtil.suggestedMatches.length>0  || AutoMatchUtil.potentialMatches.length>0  ){
                        var p1 = new Promise(function(resolve, reject) { 
                            AutoMatchUtil.saveAutoMatches(resolve,reject);
							});
                       Promise.all([p1]).then(function(){
                           console.log('Promise resolving after saving !!!!!!!!!!!!!!');
                           KenandyErp.UnBlockUI();
                           $.when($(document).trigger("RefreshGridReady")).done(function(){
                                  KenandyErp.UnBlockUI();
                                  });
                    }).catch(function(e){
                        console.log('saveAutoMatches Promise.All()');
                        console.log(e);
  						KenandyErp.UnBlockUI();
                    }); 
	                    }else{ 
	                    	//KNDY-15787 -added msg in case no match found.
	                    	KenandyErp.Message(nomatchfound,KenandyErp.MessageType.INFO,selector);
	                    	KenandyErp.UnBlockUI();
                    	}
                    });
                }
                else{
                     KenandyErp.UnBlockUI();
                    console.log('No Source Doc Records to Match!!!!!! Try changing the Date Range')
                }
              });
		  });
        },
    }
    //SourceDocs
    //amountMatched 11
    //objectType "Customer_Receipt__c"
    //recordId  "a0s36000000RBUIAA4"
    //recordName "CR-0000000013"
    //transactedWithName "Customer Bill To"
    //transactionDate 1451635200000
    //// rule
    //"a3A36000000HdKOEA0"
    //  MunishNS__Amount_Threshold__c   1
    // MunishNS__Applicable_To__c  "All"
    // MunishNS__Match_By_Amount__c true
    //  MunishNS__Match_By_Bank_Account__c false
    // MunishNS__Match_By_Check_Ref_Number__c  false
    // MunishNS__Match_By_Transacted_With__c false
    // MunishNS__Match_By_Transaction_Date__c true
    //  MunishNS__Match_Type__c  "potential"
    //  MunishNS__Rank__c 3
    //   MunishNS__Transaction_Days_Threshold__c 5
    //  
     /* sObject record = util.getGlobalDescribe('Bank_Transaction_Match__c').newSObject() ;
        record.put('Bank_Transaction__c',bankTransaction.Id);
        record.put('Bank_Transaction_Date__c',bankTransactionDate);
        record.put('Matched_To_Transaction_Date__c',matchedToTransactionDate);
        record.put(fieldToPopulate,CRSPJEBTId);
        record.put('Amount__c',amountMatched);
        return record;    */                         
    /*  bt
               *    Amount__c:68
                    Bank_Transaction_Group__c:"a0O36000001NmikEAC"
                    Id:"a0Q36000001KOZZEA4"
                    Match_Approved__c:false
                    Name:"BT-0000000108"
                    Transaction_Date__c:Thu Mar 03 2016 10:49:00 GMT-0800 (PST)
                    __proto__:Object
                    bankTransaction.Amount__c:68
                    bankTransaction.Id:"a0Q36000001KOZZEA4"
                    bankTransaction.Match_Approved__c:false
                    bankTransaction.Name:"BT-0000000108"
                    bankTransaction.Payment_Method__c:undefined
                    bankTransaction.Reconciled_As_Of_Date__c:null
                    bankTransaction.Reference_Number__c:undefined
                    bankTransaction.Transacted_With__c:undefined
                    bankTransaction.Transaction_Date__c:Thu Mar 03 2016 10:49:00 GMT-0800 (PS

               * 
               */
    
}();