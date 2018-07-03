public with sharing class FixedAssetUndoSplitCon {
    
    public Boolean requestFromFAADetail = false;
    public Boolean  manualAdjustment {get;set;}  
    public Id faaId	= null;
    public Boolean  performUndo {get;set;}  
    public List<Fixed_Asset_Adjustment__c> manualAdjustments {get;set;}
    public  ApexPages.StandardController stdcon; 
    public List<RILWrapper> RILWrappers {get;set;}
    public Fixed_Asset_Adjustment__c currentFAA;
    public class CannotUndoException extends Exception{}
    
    public FixedAssetUndoSplitCon(){
      RILWrappers 	 = new List<RILWrapper>();
      System.debug(logginglevel.error,'Entered the constructor');
      
      
      System.debug(logginglevel.error,'requestFromFAADetail--'+requestFromFAADetail);
      System.debug(logginglevel.error,'manualAdjustment--'+manualAdjustment);
      System.debug(logginglevel.error,'performUndo--' +performUndo);
      System.debug(logginglevel.error,'ApexPages.currentPage().getParameters()'+ApexPages.currentPage().getParameters());
      System.debug(logginglevel.error,'ApexPages.currentPage().getParameters().containsKey--->'+ApexPages.currentPage().getParameters().containsKey('faaId'));
      //System.debug(logginglevel.error, 'rilId-->'+rilId);
      
      
      //---------Request from FAA Detail Page-------------------
      if(ApexPages.currentPage().getParameters().containsKey('faaId') ) {  
            System.debug(logginglevel.error,'Inside the if loop of constructor');
           	List<Accounting_Entry__c>  validEntriesInOpen   = new List<Accounting_Entry__c>();
            List<Accounting_Entry__c>  validEntriesInClosed = new List<Accounting_Entry__c>();
           	requestFromFAADetail = true; 
          	faaId		     = ApexPages.currentPage().getParameters().get('faaId'); 
            
            // ---Fetch the FAA record for which the SIl needs to be restored ---
            SOQLUtil soql    = new SOQLUtil('Fixed_Asset_Adjustment__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{'Id','createddate','Name','Supplier_Invoice_line__c',
                                            'Fixed_Asset__c','Amount__c','Adjustment_Date__c','Type__c','Finalized__c',
                                            'Fixed_Asset__r.Id','historical__c','transaction_date__c','posting_date__c',
                                            'finalized_date__c'
            }); 
            
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
            childRel.addFields(new set<string>{'Id','Has_Exceptions__c','Status__c','Period__r.FA_Subledger_Closed__c'});
            soql.addChildRelationship(childRel);
            soql.setWhereClause('id=:faaId');
            soql.setLimit(1); 
            currentFAA = Database.query(soql.getQuery());  
            System.debug(logginglevel.error,'currentFAA--->'+currentFAA);
            //---The Id of the SIL to be restored----
            ID rilId 					  = currentFAA.Supplier_Invoice_line__c; 
            //-------If the SIL is null its a manual adjustment---------/
            manualAdjustment              = (rilId == null) ? true : false; 
            
          //------Check if the adjustments has Accounting Entries in Open/Closed Areas----  
            for(Accounting_Entry__c eachFAAAccountingEntry :currentFAA.Accounting_Entries__r ){
                if(eachFAAAccountingEntry.Has_Exceptions__c == false 
                            && eachFAAAccountingEntry.Status__c == 'Active' 
                            && eachFAAAccountingEntry.Period__r.FA_Subledger_Closed__c!=null){
                                
                    validEntriesInClosed.add(eachFAAAccountingEntry);
                }else if(eachFAAAccountingEntry.Has_Exceptions__c == false 
                            && eachFAAAccountingEntry.Status__c == 'Active' 
                            && eachFAAAccountingEntry.Period__r.FA_Subledger_Closed__c==null){
                    validEntriesInOpen.add(eachFAAAccountingEntry);
                }
            }
            
            System.debug(logginglevel.error,'validEntriesInOpen--->'+validEntriesInOpen); 
            System.debug(logginglevel.error,'validEntriesInClosed--->'+validEntriesInClosed); 
            
            if(validEntriesInOpen.size()>0){
              Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.WARNING,
                                                'This adjustment has accounting entries in open area. '+
                                                'These entries will be deleted if you undo the adjustment')); 
            }
            if(validEntriesInClosed.size()>0){
              Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.ERROR,
                                                'You cannot undo an adjustment after it has been accounted '+
                                                'and Fixed Assets area is closed'));  
              performUndo = false;
            } else{
              performUndo= true;
            }        
            System.debug(logginglevel.error,'performUndo--->'+performUndo);        
      }
      
      //------Undo Invoice-matched Adjustment from FAA Detail Page  ------------ 
      if(requestFromFAADetail && manualAdjustment == false && performUndo == true){ 
            SOQLUtil soql 			 = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                    'id','name','purchase_order__c','purchase_order_line__c','item__c','description__c',
                    'item__r.name','unit_price__c','Quantity_Received__c','invoice_quantity__c',
                    'track_as_asset__c','Supplier_Invoice__c','supplier_invoice__r.supplier__c','extended_cost__c',
                    'Total_Fixed_Asset_Adjustments__c' 
            });
            soql.setWhereClause('Id=:rilId'); 
            
            //---Retrieve all the FAAs
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
            childRel.addFields(new set<string>{
                'Id','name','type__c','CreatedDate','amount__c','Fixed_Asset__c','Fixed_Asset__r.Id','Fixed_Asset__r.Supplier_Invoice_Line__c',
                'Adjustment_Date__c','supplier_invoice_line__r.name',
                'historical__c','transaction_date__c','posting_date__c','finalized_date__c'
            });
            soql.addChildRelationship(childRel);
           
            Supplier_Invoice_Line__c ril  = Database.query(soql.getQuery());
            RILWrappers.add(new RILWrapper(true, ril));
            
       }
        //------Undo Invoice-matched Adjustments from  Fixed Asset Undo Asset Adjustments list page---------//
       else if(requestFromFAADetail==false){
           performUndo = true;
           updateReceiptInvoiceLines();  
       } 
        //------Undo Manual Adjustmentfrom FAA Detail Page    ------------ 
       else if(manualAdjustment && performUndo == true){
            manualAdjustments = new List<Fixed_Asset_Adjustment__c>();
            RILWrappers.clear();
            if(currentFAA!=null){
                manualAdjustments.add(currentFAA);    
            }
       }
      
    }
    public FixedAssetUndoSplitCon(ApexPages.StandardController controller){
        this.stdcon = controller;
    }  
    public pageReference  undo_adjustment(){
        PageReference p = Page.FixedAssetUndoSplit;
        p.getParameters().put('faaId', ApexPages.currentPage().getParameters().get('id'));    
        return p.setRedirect(false);
    } 
    
    public void updateReceiptInvoiceLines(){
       
        RILWrappers = new List<RILWrapper>();

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Fixed_Asset_Adjustment__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Supplier_Invoice_line__c','Fixed_Asset__r.Supplier_Invoice_Line__c'
        });
        soql.setWhereClause('id not in (Select Fixed_Asset_Adjustment__c'+
                                        ' from Accounting_Entry__c '+
                                        'where Period__r.FA_Subledger_Closed__c !=null AND Status__c=\'Active\') '+
                                    'AND Supplier_Invoice_line__r.track_as_asset__c = \'Closed\'');
        //soql.setWhereClause('id not in (Select Fixed_Asset_Adjustment__c from Accounting_Entry__c where Period__r.FA_Subledger_Closed__c !=null) '+
                                        	//'AND Supplier_Invoice_line__r.track_as_asset__c = \'Closed\'');
        List<Fixed_Asset_Adjustment__c> faas = Database.query(soql.getQuery());
 
        Set<Id> rilIds = new Set<Id>();
        for(Fixed_Asset_Adjustment__c faa : faas){
            rilIds.add(faa.Supplier_Invoice_line__c);
        }                   
        //FIN-783 Adding posting date to query as unfinalize service looks for the date.
        //TODO:Check with SK if we would need to re-query in unfinalize service to ensure we have those fields.             
        soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','purchase_order__c','purchase_order_line__c','item__c','description__c',
            'item__r.name','unit_price__c','Quantity_Received__c',
            'invoice_quantity__c','track_as_asset__c','Supplier_Invoice__c','supplier_invoice__r.supplier__c',
            'extended_cost__c','Total_Fixed_Asset_Adjustments__c'
        });
        soql.setWhereClause('Id IN :rilIds AND Track_as_Asset__c = \'Closed\'');
        soql.setOrderByClause('supplier_invoice__r.name');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
        childRel.addFields(new set<string>{
            'Id','name','type__c','CreatedDate','amount__c','Fixed_Asset__c','Fixed_Asset__r.Id',
            ' Fixed_Asset__r.Supplier_Invoice_Line__c','Adjustment_Date__c','supplier_invoice_line__r.name',
            'historical__c','transaction_date__c','posting_date__c','finalized_date__c'
        });
        soql.addChildRelationship(childRel);
        List<Supplier_Invoice_Line__c> rils = Database.query(soql.getQuery());
 
        if(rils.size()>0){  
            for(Supplier_Invoice_Line__c ril : rils){
                RILWrappers.add(new RILWrapper(false, ril));
            }
        }
        
    }
    //-----------Undo Adjustment button for all types--------------
    public PageReference undoSplit(){ 
        //---------------Manual Undo Adjustment-------------
        if(manualAdjustment==true && performUndo == true){
            Savepoint sp = Database.setSavepoint(); 
            boolean unfinalizeSuccess = true;
        try{  
                /* List<Fixed_Asset__c> currentFixedAsset  =  [select id,Total_Depreciated_Value__c,Acquisition_Cost__c,Date_Last_Depreciated__c,
                                                                    (select id ,CreatedDate from Fixed_Asset_Depreciations__r order by name desc) 
                                                                    from Fixed_Asset__c where id=:currentFAA.Fixed_Asset__c]; 
                 List<Fixed_Asset_Depreciation__c>  fads = currentFixedAsset[0].Fixed_Asset_Depreciations__r;
                 
                 
                 system.debug('SQL query-->'+currentFixedAsset);
                 system.debug('fads1'+fads);*/
                 Id currentFAAId = currentFAA.Fixed_Asset__c;
                 
                 SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
                 soql.addFields(new set<string>{ 
                     'id','Total_Depreciated_Value__c','Acquisition_Cost__c','Date_Last_Depreciated__c'
	             });
	             soql.setWhereClause('id=:currentFAAId');
                 
                 SOQLUtil.ChildRelationship childRelDeps = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Depreciations__r');
                 childRelDeps.addFields(new Set<String>{
                    'id' ,'CreatedDate' 
                 });
                 childRelDeps.setOrderByClause('name desc');
                 soql.addChildRelationship(childRelDeps); 
                 
                 List<Fixed_Asset__c> currentFixedAsset  = Database.query(soql.getQuery());
                 
                 system.debug('soql query2-->'+currentFixedAsset);
                 List<Fixed_Asset_Depreciation__c>  fads = currentFixedAsset[0].Fixed_Asset_Depreciations__r;
                  system.debug('fads1'+fads);
              
                 if(fads.size()>0){
                     DateTime lastDepRecordDate              = fads[0].createddate;
                     //# If the fixed asset has depreciation records generated after the adjustment date,
                     //---raise the error 
                     if(currentFixedAsset[0].Total_Depreciated_Value__c>0 
                                            &&  currentFAA.createddate <=  lastDepRecordDate && fads.size()>0){
                        throw new CannotUndoException( 'You cannot undo an adjustment after it has been depreciated.'+ 
                                                                'You must first rollback the depreciation records');
                        performUndo = false;
                     }else{ performUndo = true;}
                 } 
                 if(performUndo==true)
                 {
                 	//KNDY-13139 We are not updating aquistion cost on adding /undoing/unfinalizing/finalizing adjustments.
                    /*currentFixedAsset[0].Acquisition_Cost__c  -= currentFAA.Amount__c ;
                    //---Allowing only system to change acquisition cost in FA------/
                    FixedAssetService.systemEditable.add(currentFixedAsset[0].Id);*/
                    Map<Id, Fixed_Asset_Adjustment__c> mAdjustments        = new Map<Id, Fixed_Asset_Adjustment__c>(manualAdjustments);
                    Map<Id, UnfinalizeService.UnfinalizeResponse> mResults = UnfinalizeService.unfinalizeSourcedocs(manualAdjustments);
                    
                    //--------First Unfinalize the doc to make changes-------/     
                    for(Fixed_Asset_Adjustment__c faa : manualAdjustments){
                        if(!mResults.get(faa.Id).Success){
                            unfinalizeSuccess = false;
                            throw new CannotUndoException( 'Cannot Unfinalize the adjustment record'+faa.Name);
                        }
                    }
                    if(unfinalizeSuccess==true){        
                        //DML.updateAsUser(currentFixedAsset); 
                        DML.deleteAsUser(manualAdjustments);
                        Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.INFO,
                                            'Successfully undone the adjustment'));
                        PageReference faaDetailPage = new PageReference('/'+currentFAA.Fixed_Asset__c);  
     					faaDetailPage.setRedirect(true);
     					return faaDetailPage;
                    } 
                 }
           }
           catch(Exception exp){
                database.rollBack(sp);
                Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(exp.getMessage())));
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + exp.getMessage());
                system.debug('Cannot Undo Adjustment Reason: '+exp.getStackTraceString());
           }
              
          return null;
              
        }//----------Undo adjustment from list  page-------
        else{ 
            String warningMsg;
            String silsNotRestored    = '';
            Boolean undoFAA           = true ; 
            Set<Id> fixedAssetIds     = new Set<Id>();
            Set<Id> allFas            = new Set<Id>();
            String reasonCannotUndo   = '' ;
            Map<Id, decimal> mFixedAssetAdjustments = new Map<Id, decimal>();
            List<Fixed_Asset_Adjustment__c> deleteAdjustments;//       = new List<Fixed_Asset_Adjustment__c>();
            Set<Supplier_Invoice_Line__c>  updateRils = new Set<Supplier_Invoice_Line__c>();
            List<Fixed_Asset_Adjustment__c> allFAAsSelected ;// = new List<Fixed_Asset_Adjustment__c>();
            List<Fixed_Asset_Adjustment__c> blockUndoFAAList ;// = new List<Fixed_Asset_Adjustment__c>(); 
            Set<Fixed_Asset_Adjustment__c> allFAAsSelectedSet = new Set<Fixed_Asset_Adjustment__c>();
          
            for(RILWrapper rw : RILWrappers){
                if(rw.selected){
                	allFAAsSelectedSet.addAll(rw.ril.Fixed_Asset_Adjustments__r);
                }
            }
            allFAAsSelected =  new List<Fixed_Asset_Adjustment__c>(allFAAsSelectedSet); 
            
           // Retrieving all the FA ids of the selected FAAs to see if any  depreciations exists
           for(Fixed_Asset_Adjustment__c faa:allFAAsSelected){ 
              allFas.add(faa.Fixed_Asset__r.Id);
           } 
           // Query all the FAs of all the selected FAAs  
           SOQLUtil soql                             
           				= new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode 
           soql.addFields(new set<string>{ 'id','Fixed_Asset__c','Total_Depreciated_Value__c' }); 
           soql.setWhereClause('Id IN :allFas');      
           
           SOQLUtil.ChildRelationship childRel1      
           				= new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Depreciations__r');
           childRel1.addFields(new set<string>{'Id','CreatedDate' });
           childRel1.setOrderByClause('name DESC');
           soql.addChildRelationship(childRel1);
       
           SOQLUtil.ChildRelationship childRel2     
    				    = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
           childRel2.addFields(new set<string>{
                			'id','name','Supplier_Invoice_Line__r.Name', 'Transaction_Date__c', 
                			'Supplier_Invoice_Line__c','CreatedDate',
                			'Fixed_Asset__r.Supplier_Invoice_Line__c','Finalized_Date__c',
                			'Posting_Date__c','Historical__c','Fixed_Asset__c','Amount__c' 
           }); 
           soql.addChildRelationship(childRel2);
            
           // List of all the fixed assests of the selected FAAs
           List<Fixed_Asset__c> allFAsSelected = Database.query(soql.getQuery()); 
           
           //------Retrieve accounting entries of all the selected FAAs if any --------//
          /* Map<Id,Accounting_Entry__c> faaAccEntriesMap =    new Map<Id,Accounting_Entry__c>();
           
           for(Accounting_Entry__c accEntry : [select id, Fixed_Asset_Adjustment__r.Id,Has_Exceptions__c,Status__c,
           															  Period__r.FA_Subledger_Closed__c 
                                                                      from Accounting_Entry__c 
                                                                      where Fixed_Asset_Adjustment__c in :allFAAsSelected 
                                                                      AND Has_Exceptions__c = false 
                                                                      AND  Status__c = 'Active'
                                                                      AND  Period__r.FA_Subledger_Closed__c!=null]){
               if(accEntry == null) {
                        faaAccEntriesMap.put(accEntry.Fixed_Asset_Adjustment__r.Id,null);
                }
                else{
                        faaAccEntriesMap.put(accEntry.Fixed_Asset_Adjustment__r.Id,accEntry); 
                }
                                     
           } */
           Set<Fixed_Asset_Adjustment__c> faasToUndo  = new  Set<Fixed_Asset_Adjustment__c>();
           Set<Fixed_Asset_Adjustment__c> faasToBlock = new  Set<Fixed_Asset_Adjustment__c>();
               
           for(Fixed_Asset__c selectedFA:allFAsSelected) 
           { 
             Map<Id,Fixed_Asset_Adjustment__c> AllFAAsinFA 
             								= new Map<Id,Fixed_Asset_Adjustment__c>(selectedFA.Fixed_Asset_Adjustments__r);
             Map<Id,Fixed_Asset_Adjustment__c> faasSelected 
             								= new Map<Id,Fixed_Asset_Adjustment__c>(allFAAsSelected);
             // Check if FA depreciations exists  and already included the FAA ,
             // ----dont allow SIL restore 
             List<Fixed_Asset_Depreciation__c> allDeps = selectedFA.Fixed_Asset_Depreciations__r;
             //-------Check if depreciation exists-------//
            // if(allDeps.size()>0 && selectedFA.Total_Depreciated_Value__c>0)
             //{      
                
            for(Id selectedFaaId:faasSelected.keySet())
            {
               if(AllFAAsinFA.keySet().contains(selectedFaaId)==true)
               {     
               	 if(allDeps.size()>0 && selectedFA.Total_Depreciated_Value__c>0){
                     //----Check if  the adjustments are added before depreciation is run - Then block-----// 
                       if( faasSelected.get(selectedFaaId).CreatedDate <= allDeps[0].CreatedDate){
                            reasonCannotUndo += 'Depreciations Exists  ';
                            undoFAA = false;
                            faasToBlock.add(faasSelected.get(selectedFaaId));
                       }  else{ faasToUndo.add(faasSelected.get(selectedFaaId));}
                   }
                   else{
                    faasToUndo.add(faasSelected.get(selectedFaaId));
                    //undoFAA = true;
                   }
                  /* if(faaAccEntriesMap.containsKey(selectedFaaId) && faaAccEntriesMap.get(selectedFaaId)!=null){
                       reasonCannotUndo += ' Accounting Entries Exists in closed Area';
                       faasToBlock.add(faasSelected.get(selectedFaaId));
                   } */ 
               } 
             } 
            }   
            
            blockUndoFAAList = new List<Fixed_Asset_Adjustment__c>(faasToBlock) ;
            //blockUndoFAAList.addAll(faasToBlock) ;
            deleteAdjustments = new List<Fixed_Asset_Adjustment__c>(faasToUndo) ;
            //deleteAdjustments.addAll(faasToUndo); 
    		if(blockUndoFAAList.size()>0){
    		  /*  for(Fixed_Asset_Adjustment__c faa:blockUndoFAAList){ 
    		    	silsNotRestored += ' '+faa.Supplier_Invoice_Line__r.Name;
    		    } */
    		     undoFAA = false; 
    		     if(blockUndoFAAList.size()==1){
    		         warningMsg =  'You cannot undo an adjustment after it has been depreciated.'+
    		                        ' You must first rollback the depreciation records' ;
    		     }else if(blockUndoFAAList.size()>1){
    		 	    warningMsg =  'Some Invoices cannot be restored as depreciations records were created after'+
    		 	 				    ' adding adjustments,Please rollback the depreciation records' ;}
    		} 
    		 
    		for(Fixed_Asset_Adjustment__c faa : deleteAdjustments){
                //-----Resetting the SILs to track as Asset------
    		  faa.Supplier_Invoice_Line__r.track_as_asset__c ='Yes';
     		  updateRils.add(faa.Supplier_Invoice_Line__r); 
                // --- If the FA is a New FA from the SILs , then that shud be deleted after the adjustmnets are undo
     	 	  if(faa.Supplier_Invoice_Line__c == faa.Fixed_Asset__r.Supplier_Invoice_Line__c){
     	 	    fixedAssetIds.add(faa.fixed_asset__c); 
     	 	  }
              if(mFixedAssetAdjustments.containsKey(faa.fixed_asset__c)){
                decimal amt = mFixedAssetAdjustments.get(faa.fixed_asset__c);
                amt += faa.amount__c == null ? 0 : faa.amount__c;
                mFixedAssetAdjustments.put(faa.fixed_asset__c, amt);
              }
              else
              {
               mFixedAssetAdjustments.put(faa.fixed_asset__c, faa.amount__c == null ? 0 : faa.amount__c);
              }
            }
                 
            
            //KNDY-13139 We are not updating aquistion cost on adding /undoing/unfinalizing/finalizing adjustments.
            /*KNDY-10473: Adding CRUD/FLS checks with SOQLUtil           
            soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','acquisition_cost__c'
            });
            set<id> mFAASet = mFixedAssetAdjustments.keySet();
            soql.setWhereClause('Id IN :mFAASet');
            List<Fixed_Asset__c> updateFixedAssets = Database.query(soql.getQuery());
          
            for(Fixed_Asset__c fa : updateFixedAssets){
                if(mFixedAssetAdjustments.containsKey(fa.Id)){
                    fa.acquisition_cost__c -= mFixedAssetAdjustments.get(fa.Id);
                    fixedAssetService.systemEditable.add(fa.Id);
                }
            }*/
            
            if(deleteAdjustments.size() > 0){
                undoFAA = true;
                Savepoint sp = Database.setSavepoint();
                try{
                    boolean unfinalizeSuccess = true;
                    set<string> silNames = new set<string>();
                    if(deleteAdjustments.size() > 0){
                        Map<Id, Fixed_Asset_Adjustment__c> mAdjustments = new Map<Id, Fixed_Asset_Adjustment__c>(deleteAdjustments);
                        Map<Id, UnfinalizeService.UnfinalizeResponse> mResults = UnfinalizeService.unfinalizeSourcedocs(deleteAdjustments);
                        for(Fixed_Asset_Adjustment__c faa : deleteAdjustments){
                            if(!mResults.get(faa.Id).Success){
                                unfinalizeSuccess = false;
                                silNames.add(faa.supplier_invoice_line__r.name);
                            }
                        }
                        
                        if(unfinalizeSuccess){
                        	// SILs restored   
    						String sils = '';
     						for(Supplier_Invoice_Line__C sil:updateRils)
     						{
     							sils+= sil.Name+' ';					
     						}
                            DML.deleteAsUser(deleteAdjustments);
                            
                            if(updateRils.size() > 0){
                                
                                DML.updateAsUser(new List<Supplier_Invoice_Line__c>(updateRILs));
                            }
                            
                            /*if(updateFixedassets.size() > 0){
                                DML.updateAsUser(updateFixedAssets);
                            }*/
                            updateReceiptInvoiceLines();
                            
                            if(fixedAssetIds.size() > 0){
                                //V2
                                soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
                                soql.addFields(new set<string>{
                                    'Id'
                                });
                                soql.setWhereClause('Id IN :fixedAssetIds');
                                SOQLUtil.ChildRelationship childRel3 = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
                                childRel1.addFields(new set<string>{
                                    'Id'
                                });
                                soql.addChildRelationship(childRel1);
                                SOQLUtil.ChildRelationship childRel4 = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Depreciations__r');
                                childRel2.addFields(new set<string>{
                                    'Id'
                                });
                                soql.addChildRelationship(childRel2);
                                List<Fixed_Asset__c> fixedAssets = Database.query(soql.getQuery());
    
                                List<Fixed_Asset__c> deleteFixedAssets = new List<Fixed_Asset__c>();
                                for(Fixed_Asset__c fa : fixedAssets){
                                    if(fa.Fixed_Asset_Adjustments__r.size() == 0 && fa.Fixed_Asset_Depreciations__r.size() == 0){
                                        deleteFixedassets.add(fa);
                                     }
                                }
                                
                                if(deleteFixedAssets.size() > 0){
                                    DML.deleteAsUser(deleteFixedAssets);
                                }
                            } 
                            Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.CONFIRM, 
     						 															 'Restored '+sils)); 
     						
     						if(warningMsg!=null){
     						  	 Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.ERROR, warningMsg));   
     						} 
     						// if the Undo adjustment request is coming from the FAA detail page
     						//and the restore is successful, redirect to faa detail page
     						if(requestFromFAADetail && warningMsg==null){ 
     							PageReference faaDetailPage = new PageReference('/'+currentFAA.Fixed_Asset__c);  
     							faaDetailPage.setRedirect(true);
     							 return faaDetailPage;
     						}  
                        }
                        else{
                            database.rollBack(sp);
                            Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.ERROR, 
                            		Label.Unable_to_undo_the_split_for_SupplierInvoiceLines  + string.join(new List<string>(silNames), ', ')));
                        }
                    }
                    
                    
                }catch(Exception ex){
                    database.rollBack(sp);
                    Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
                    system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                }
            }else{
                if(undoFAA){
     				Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.WARNING, Label.No_records_selected));
     		}
     			else{
     				if(warningMsg!=null){
     					Apexpages.addMessage(new ApexPages.Message(Apexpages.severity.WARNING, warningMsg)); 
     				}
     			} 
            }
            return null;  
        }//----------Invoice based Undo Adjustment-------------
        
       
    }
     
    public pageReference workbench(){
        return Page.FixedAssetWorkbench;
    }
    
    public class RILWrapper{
        public boolean selected {get;set;}
        public Supplier_Invoice_Line__c ril {get;set;}
        public RILWrapper(boolean inSelected, Supplier_Invoice_Line__c inRIL){
            selected = inSelected;
            ril = inRIL;
        }
    }
    
}