public with sharing class ReconRemoteService 
{/*
    
    public static final string ReconciledTitle='Reconciled  Entries';
    public static final string UnreconciledAmountTitle='Unreconciled  Entries';
    public static final string UnreconciledRulesTitle='Entries with Incorrect Accounting Rules';
    public static final string UnmatchedTitle='Entries with Accounting Rules Not Defined in Recon Topics';
    public static final string AccrualCandidatesTitle='Source Documents To Accrue';
    public static final string ManualTitle='Manual Entries';
    public static final string UnreconciledExceptionsTitle='Entries with Exceptions';
    public static final string OtherSDTitle='Other Source Document Exceptions';
    
    public static final string ReconInfoMessage='Reconciliation in progress. Please do not refresh the page.';
    public static set<string> otherSDSet = new set<string>{'receiving_document__c','inventory_change__c','work_order__c','shipment__c'}; 
    

	public static string getSDRefNameForSD(string SDName)
	{
		return mSDtoSDNameRefs.get(SDName);
	}
    public static string getSDLRefNameForSD(string SDName)
	{
		return mSDtoSDLNameRefs.get(SDName);
	}
	
	public static string getSDLAPINameForSD(string SDName)
	{
		return mSDtoLine.get(SDName);
	}
	
	public static string getSourceDocRefWithDot(string SDName)
	{
		return mSourceDocRefsWithDot.get(SDName);
	}
	
	
	public static string getSourceDocLineRefWithoutDot(string SDName)
	{
		return mSourceDocLineRefsWithoutDot.get(SDName);
	}

	public static string getSDLRefWithDotForSD(string SDName)
	{
	    string SDLFieldRefWithDot='';
		
		try
		{
			string APIStr =sanitizeInptStr(SDName);
			if(APIStr=='Not Found')
			{
		    	 SDLFieldRefWithDot = 'Not Found' ;			
			}
			else if(APIStr==null)
			{
				SDLFieldRefWithDot = null;
			}
			else
			{
		    	 SDLFieldRefWithDot =  mSourceDocLineRefs.get(APIStr);			
				
			}			
		}
		catch(Exception Ex)
		{
			SDLFieldRefWithDot = ex.getMessage() +' At lineNumber '+ ex.getLineNumber();
		}

		return SDLFieldRefWithDot;
	}
	public static string  getAPINameForSDType(string SDName)
	{
		    string TopicTypeAPIName='';
		    try
		    {
			    if(SDName==null)
			    {
			    	return null;
			    }
			    if(mSDAPIName.containskey(SDName))
			    {
			    	TopicTypeAPIName=mSDAPIName.get(SDName);
			    }
			    else
			    {
			    	TopicTypeAPIName = 'Not Found' ;
			    }		    	
		    }
		    catch(Exception  ex)
		    {
			   TopicTypeAPIName = ex.getMessage() +' At lineNumber '+ ex.getLineNumber();
		    	
		    }


			return TopicTypeAPIName;
	}
    public static string  getSDTypefromAPIName(string SDAPIName)
	{
		    string TopicTypeName='';
		    try
		    {
			    if(SDAPIName==null)
			    {
			    	return null;
			    }
			    if(mSDAPIToSDName.containskey(SDAPIName))
			    {
			    	
			    	TopicTypeName=mSDAPIToSDName.get(SDAPIName);
			    	
			    }
			    else
			    {
			    	TopicTypeName = 'Not Found' ;
			    }		    	
		    }
		    catch(Exception  ex)
		    {
		    
			   TopicTypeName = ex.getMessage() +' At lineNumber '+ ex.getLineNumber();
		    	
		    }


			return TopicTypeName;
	}
	public static string getDefaultLineCostFieldForSD(string SDName)
	{
		string costfield='';
		
		try
		{
			string APIStr =sanitizeInptStr(SDName);
			if(APIStr=='Not Found')
			{
		    	 costfield = 'Not Found' ;			
			}
			else if(APIStr==null)
			{
				costfield = null;
			}
			else
			{
		    	 costfield =  mSDtodefaultLineCost.get(APIStr);			
				
			}			
		}
		catch(Exception Ex)
		{
			costfield = ex.getMessage() +' At lineNumber '+ ex.getLineNumber();
		}

		return costfield;
	}
	
	public static string getDefaultCostFieldForSD(string SDName)
	{
		string costfield='';
		
		try
		{
			string APIStr =sanitizeInptStr(SDName);
			if(APIStr=='Not Found')
			{
		    	 costfield = 'Not Found' ;			
			}
			else if(APIStr==null)
			{
				costfield = null;
			}
			else
			{
		    	 costfield =  mSDtodefaultCost.get(APIStr);			
				
			}			
		}
		catch(Exception Ex)
		{
			costfield = ex.getMessage() +' At lineNumber '+ ex.getLineNumber();
		}

		return costfield;
	}
	

	public static string sanitizeInptStr(string val)
	{
		val=val.toLowerCase();
		if(mStrToAPI.containskey(val))
		{
			return mStrToAPI.get(val);
		}
		else
		{
			return 'Not Found';
		}
		return null;
		
	}
	public static string sanitizeOtherInptStr(string val)
	{
		val=val.toLowerCase();
		if(mOtherStrToAPI.containskey(val))
		{
			return mOtherStrToAPI.get(val);
		}
		else
		{
			return 'Not Found';
		}
		return null;
		
	}
	
	
	
 	public static set<id> getVoidAELIds(set<id> GLFamily,id reconperiod,boolean isJournalEntry)
 	{
 		set<id> OrigVoidAELIds = new set<id>();//Just collecting the Ids seperately for future use.
 		set<id> reversalVoidAELIds = new set<id>();
 		set<id> VoidAELIdsToExclude = new set<id>();
 		list<accounting_entry_line__c> VoidAELsWithReversalInSamePeriod = new list<accounting_entry_line__c>();
 		if(isJournalEntry)
 		{
	 		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','related_accounting_entry_line__c'
			});
			soql.setWhereClause('related_accounting_entry_line__c!=null and status__c=\'Active\' and gl_account__c in :GLFamily and '
								+' accounting_entry__r.period__c=:reconperiod and related_accounting_entry_line__r.accounting_entry__r.period__c=:reconperiod '
								+' and journal_entry_line__r.journal_entry__r.type__c!=\'Accrual - Manual\' '
								+' and Accounting_Entry__r.Source_Document_Object_Name__c=\'Journal_Entry__c\'');
								
			VoidAELsWithReversalInSamePeriod = Database.query(soql.getQuery());

 		}
 		else
 		{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','related_accounting_entry_line__c'
			});
			soql.setWhereClause('related_accounting_entry_line__c!=null and status__c=\'Active\' and gl_account__c in :GLFamily and related_accounting_entry_line__r.accounting_entry__r.period__c=:reconperiod '
								+' and Accounting_Entry__r.Source_Document_Object_Name__c!=\'Journal_Entry__c\'');

			VoidAELsWithReversalInSamePeriod = Database.query(soql.getQuery());

 		}

		 if(VoidAELsWithReversalInSamePeriod.size()>0)
		 {
		 	for(accounting_entry_line__c voidAEL:VoidAELsWithReversalInSamePeriod)
		 	{
			 	OrigVoidAELIds.add(voidAEL.related_accounting_entry_line__c);
			 	reversalVoidAELIds.add(voidAEL.id);
		 		
		 	}
		 	VoidAELIdsToExclude.addall(OrigVoidAELIds);
		 	VoidAELIdsToExclude.addall(reversalVoidAELIds);
		 	
		 }

		 return VoidAELIdsToExclude;
 	}
 	
	//KNDY-10268 - deprecating bank file and bank file line objects
     public static final map<string, string> mSDtodefaultLineCost = new map<string, string>{
        'Customer_Invoice__c' 	=> 'extended_price__c',
    	'Customer_Receipt__c'	=> 'amount__c',
    	//'Bank_File__c'			=> 'Amount__c',
        'Supplier_Invoice__c' 	=> 'Extended_Price__c',
        'Supplier_Payment__c' 	=> 'amount__c',
        'Bank_Transaction_Group__c' => 'amount__c'
       // 'Shipment__c'			=> 'Extended_Cost__c'
       // 'Receiving_Document__c'	=> 'Receiving_Document__r',
       // 'Work_Order__c' 		=> 'Work_Order__r',
       // 'Inventory_Change__c'	=> 'Inventory_Change__r'	
		//more...
	}; 
	//KNDY-10268 - deprecating bank file and bank file line objects
	//This map is used in Accruals Section.
	 public static final map<string, string> mSDtodefaultCost = new map<string, string>{
        'Customer_Invoice__c' 	=> 'Total_Amount__c',
    	'Customer_Receipt__c'	=> 'Total_Payment__c',
    	//'Bank_File__c'			=> 'Total_Amount__c',
        'Supplier_Invoice__c' 	=> 'Total_Invoice__c',
        'Supplier_Payment__c' 	=> 'Payment_Amount__c'
        //TODO:What cost field to aggregate
        //'Shipment__c'			=> 'Extended_Cost__c'
       // 'Receiving_Document__c'	=> 'Receiving_Document__r',
       // 'Work_Order__c' 		=> 'Work_Order__r',
       // 'Inventory_Change__c'	=> 'Inventory_Change__r'	
		//more...
	};
	public static final map<string, string> mStrToAPI = new map<string, string>{
        'customer_invoice__c' 	=> 'Customer_Invoice__c',
    	'customer_receipt__c'	=> 'Customer_Receipt__c',
    	'bank_file__c'			=> 'Bank_File__c',
        'supplier_invoice__c' 	=> 'Supplier_Invoice__c',
        'supplier_payment__c' 	=> 'Supplier_Payment__c',
        'journal_entry__c'		=> 'Journal_Entry__c',
        'bank_transaction_group__c' => 'Bank_Transaction_Group__c'

       // 'Shipment__c'			=> 'Extended_Cost__c'
       // 'Receiving_Document__c'	=> 'Receiving_Document__r',
       // 'Work_Order__c' 		=> 'Work_Order__r',
       // 'Inventory_Change__c'	=> 'Inventory_Change__r'	
		//more...
	}; 
	//KNDY-10268 - deprecating bank file and bank file line objects
	public static final map<string, string> mSourceDocLineRefs = new map<string, string>{
        'Journal_Entry__c' 		=> 'Journal_Entry_Line__r.',
        'Customer_Invoice__c' 	=> 'Customer_Invoice_Line__r.',
    	'Customer_Receipt__c'	=> 'Customer_Receipt_Line__r.',
    	//'Bank_File__c'	        => 'Bank_File_Line__r.',    	
        'Supplier_Invoice__c' 	=> 'Supplier_Invoice_Line__r.',
        'Supplier_Payment__c' 	=> 'Supplier_Payment_Line__r.',
        'Bank_Transaction_Group__c' => 'Bank_Transaction__r.'

      /*  'Shipment__c'			=> 'Shipment_Line__r.',
        'Receiving_Document__c'	=> 'Receipt_Line__r.',
        'Work_Order__c' 		=> 'Inventory_Transaction__r.',
        'Inventory_Change__c'	=> 'Inventory_Transaction__r.'	 *//*
        //more...
    };
     //KNDY-10268 removal of bank file object reference
       private static final map<string, string> mSourceDocRefsWithDot = new map<string, string>{
        'Journal_Entry__c' 		=> 'Journal_Entry__r.',
        'Customer_Invoice__c' 	=> 'Customer_Invoice__r.',
    	'Customer_Receipt__c'	=> 'Customer_Receipt__r.',
        'Supplier_Invoice__c' 	=> 'Supplier_Invoice__r.',
        'Supplier_Payment__c' 	=> 'Supplier_Payment__r.',
    	//'Bank_File__c'	        => 'Bank_File__r.',
    	'Bank_Transaction_Group__c'	        => 'Bank_Transaction_Group__r.'

    };
    //KNDY-10268 - deprecating bank file and bank file line objects
	public static final map<string, string> mSDAPIName = new map<string, string>{
		//'Manual' => 'Journal_Entry__c',
	    'Journal Entry' => 'Journal_Entry__c',
		'Customer Invoice' => 'Customer_Invoice__c', 
		'Customer Receipt' => 'Customer_Receipt__c',
		//'Bank File' 		=> 'Bank_File__c',		
		'Supplier Invoice' 	=> 'Supplier_Invoice__c',
	    'Supplier Payment' 	=> 'Supplier_Payment__c',
	    'Bank Transaction Group' => 'Bank_Transaction_Group__c'
	    /*'Receiving Document'=> 'Receiving_Document__c' //KNDY-9639
	    
	     'Shipment'			=> 'Shipment__c',
	    'Receiving Document'=> 'Receipt_Line__c',
	    'Work Order' 		=> 'Work_Order__c',
	    'Inventory Change'	=> 'Inventory_Change__c'*//*
		//more...
	}; 
	//KNDY-10268 - deprecating bank file and bank file line objects
	public static final map<string, string> mSDAPIToSDName = new map<string, string>{
		//'Manual' => 'Journal_Entry__c',
	    'Journal_Entry__c' => 'Journal Entry',
		'Customer_Invoice__c' => 'Customer Invoice', 
		'Customer_Receipt__c' => 'Customer Receipt',
		//'Bank_File__c' 		=> 'Bank File',		
		'Supplier_Invoice__c' 	=> 'Supplier Invoice',
	    'Supplier_Payment__c' 	=> 'Supplier Payment',
	    'Bank_Transaction_Group__c' 	=> 'Bank Transaction Group'

	   /* 'Shipment'			=> 'Shipment__c',
	    'Receiving Document'=> 'Receipt_Line__c',
	    'Work Order' 		=> 'Work_Order__c',
	    'Inventory Change'	=> 'Inventory_Change__c'*//*
		//more...
	}; 
	//KNDY-10268 - deprecating bank file and bank file line objects
	private static final map<string, string> mSDtoSDNameRefs = new map<string, string>{
        'Journal_Entry__c'      => 'Journal_Entry__r.name',
        'Customer_Invoice__c'   => 'Customer_Invoice__r.name',
        'Customer_Receipt__c'   => 'Customer_Receipt__r.name',
        'Supplier_Invoice__c'   => 'Supplier_Invoice__r.name',
        'Supplier_Payment__c'   => 'Supplier_Payment__r.name',
        //'Bank_File__c'			=> 'Bank_File__r.name',
        'Bank_Transaction_Group__c' => 'Bank_Transaction_Group__r.name'
        /*'Shipment__c'           => 'Shipment__r.name',
        'Receiving_Document__c' => 'Receiving_Document__r.name',
        'Work_Order__c'         => 'Work_Order__r.name',
        'Inventory_Change__c'   => 'Inventory_Change__r.name'    *//*
        //more...
    };
    //KNDY-10268 - deprecating bank file and bank file line objects
    private static final map<string, string> mSDtoSDLNameRefs = new map<string, string>{
        'Journal_Entry__c'      => 'Journal_Entry_Line__r.name',
        'Customer_Invoice__c'   => 'Customer_Invoice_Line__r.name',
        'Customer_Receipt__c'   => 'Customer_Receipt_Line__r.name',
        'Supplier_Invoice__c'   => 'Supplier_Invoice_Line__r.name',
        'Supplier_Payment__c'   => 'Supplier_Payment_Line__r.name',
        //'Bank_File__c'			=> 'Bank_File_Line__r.name',
        'Bank_Transaction_Group__c' => 'Bank_Transaction__r.name'

		/*        
        'Shipment__c'           => 'Shipment_Line__r.name',
        'Receiving_Document__c' => 'Receipt_Line__r.name',
        'Work_Order__c'         => 'Inventory_Transaction__r.name',
        'Inventory_Change__c'   => 'Inventory_Transaction__r.name'    
        //more...*//*
    };
	//KNDY-10268 - deprecating bank file and bank file line objects
    private static final map<string, string> mSDtoLine = new map<string, string>{
        'Journal_Entry__c'      => 'Journal_Entry_Line__c',
        'Customer_Invoice__c'   => 'Customer_Invoice_Line__c',
        'Customer_Receipt__c'   => 'Customer_Receipt_Line__c',
        'Supplier_Invoice__c'   => 'Supplier_Invoice_Line__c',
        'Supplier_Payment__c'   => 'Supplier_Payment_Line__c',
        //'Bank_File__c'	        => 'Bank_File_Line__c', 
        'Bank_Transaction_Group__c' => 'Bank_Transaction__c'  	
        
   
        //more...
    };
    //KNDY-10268 - deprecating bank file and bank file line objects
    private static final map<string, string> mSourceDocLineRefsWithDot = new map<string, string>{
        'Journal_Entry__c'      => 'Journal_Entry_Line__r.',
        'Customer_Invoice__c'   => 'Customer_Invoice_Line__r.',
        'Customer_Receipt__c'   => 'Customer_Receipt_Line__r.',
        'Supplier_Invoice__c'   => 'Supplier_Invoice_Line__r.',
        'Supplier_Payment__c'   => 'Supplier_Payment_Line__r.',
    	//'Bank_File__c'	        => 'Bank_File_Line__r.',
        'Bank_Transaction_Group__c' => 'Bank_Transaction__r.'  	

 
    };
    //KNDY-10268 - deprecating bank file and bank file line objects
    private static final map<string, string> mSourceDocLineRefsWithoutDot = new map<string, string>{
        'Journal_Entry__c'      => 'Journal_Entry_Line__r',
        'Customer_Invoice__c'   => 'Customer_Invoice_Line__r',
        'Customer_Receipt__c'   => 'Customer_Receipt_Line__r',
        'Supplier_Invoice__c'   => 'Supplier_Invoice_Line__r',
        'Supplier_Payment__c'   => 'Supplier_Payment_Line__r',
    	//'Bank_File__c'	        => 'Bank_File_Line__r',   	
        'Bank_Transaction_Group__c' => 'Bank_Transaction__r'  	

 
    };
    //List of transition maps to handle Other SD.Once recons have been built for these SDs then these would collapse into the above counterparts.
    
     	public static final map<string, string> mOtherSDtoSDNameRefs = new map<string, string>{
        'Shipment__c'           => 'Shipment__r.name',
        'Receiving_Document__c' => 'Receiving_Document__r.name',
        'Work_Order__c'         => 'Work_Order__r.name',
        'Inventory_Change__c'   => 'Inventory_Change__r.name'    
    };
        public static final map<string, string> mOtherSDtoSDLNameRefs = new map<string, string>{
        'Shipment__c'           => 'Shipment_Line__r.name',
        'Receiving_Document__c' => 'Receipt_Line__r.name',
        'Work_Order__c'         => 'Inventory_Transaction__r.name',
        'Inventory_Change__c'   => 'Inventory_Transaction__r.name'    
    };   
        public static final map<string, string> mOtherSDtoLine = new map<string, string>{
        'Shipment__c'           => 'Shipment_Line__c',
        'Receiving_Document__c' => 'Receipt_Line__c',
        'Work_Order__c'         => 'Inventory_Transaction__c',
        'Inventory_Change__c'   => 'Inventory_Transaction__c'

    };
        public static final map<string, string> mOtherSourceDocLineRefsWithDot = new map<string, string>{
        'Shipment__c'           => 'Shipment_Line__r.',
        'Receiving_Document__c' => 'Receipt_Line__r.',
        'Work_Order__c'         => 'Inventory_Transaction__r.',
        'Inventory_Change__c'   => 'Inventory_Transaction__r.'
    };
        public static final map<string, string> mOtherSourceDocLineRefsWithoutDot = new map<string, string>{
        'Shipment__c'           => 'Shipment_Line__r',
        'Receiving_Document__c' => 'Receipt_Line__r',
        'Work_Order__c'         => 'Inventory_Transaction__r',
        'Inventory_Change__c'   => 'Inventory_Transaction__r'
    };
    	public static final map<string, string> mOtherStrToAPI = new map<string, string>{
         'shipment__c'			=> 'Shipment__c',
         'receiving_document__c'=> 'Receiving_Document__c',
         'work_order__c' 		=> 'Work_Order__c',
         'inventory_change__c'	=> 'Inventory_Change__c'	
	}; 
*/}