public with sharing class PaymentProfileManagerExt {
	
	public Id customerId {get;set;}
	public Payment_Profile__c pp {get;set;}
	public PaymentHandler.PaymentProfileDetail ppd {get;set;}
	public string selectedPaymentMethodId {get;set;}
	public string paymentCCV {get;set;}
	public boolean showAddPaymentMethod {get;set;}
	public boolean disableCreatePaymentButton {get;private set;}//KNDY-11812 KNDY-12027
	public boolean paymentCreated {get;set;}
	public boolean isValidCustomer {get;set;}
	public Id paymentId {get;set;}
	
	public Customer_Receipt_Line__c crl {get;set;}
	
	public PaymentProfileManagerExt(){
		this(new Apexpages.StandardController(new Customer__c()));
	}
	
	public PaymentProfileManagerExt(Apexpages.Standardcontroller con){
		if(Apexpages.CurrentPage().getParameters().get('customerId') != null 
				&& Apexpages.CurrentPage().getParameters().get('customerId') != ''){
			con = new Apexpages.StandardController(new Customer__c(Id = Apexpages.CurrentPage().getParameters().get('customerId')));
		}
		system.debug('std con: ' + con.getId());
		this.customerId = con.getId();
		system.debug('customerId: ' + this.customerId);
		Customer__c customer = getCustomer(con.getId());
		isValidCustomer = true;
		showAddPaymentMethod = false;
		disableCreatePaymentButton = false; //KNDY-11812 KNDY-12027
		paymentCreated = false;
		setFormFieldsFromCustomer(customer);//KNDY-12198
		updatePaymentProfile();
		
		defaultCustomerReceiptLine();
		if(customer.RecordType.DeveloperName != 'Corporate_Parent' && customer.RecordType.DeveloperName != 'Bill_To'){
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Payment Profiles may only be created for Corporate Parent or Bill To Customers'));
			isValidCustomer = false;
			system.debug(logginglevel.error, 'isValidCustomer '+isValidCustomer);
			return;
		}
		
		
		
	}
	
	private void setFormFieldsFromCustomer(Customer__c customer){//KNDY-12198
		system.debug(LoggingLevel.Error, '>>> pre setFormFieldsFromCustomer: ' + ppd);
		if(ppd == null){
			ppd = new PaymentHandler.PaymentProfileDetail();
		}
		if (ppd.creditCard == null){
			ppd.creditCard = new PaymentHandler.CreditCardDetail();
		}
		if (ppd.formFields == null){
			ppd.formFields = new PaymentHandler.PaymentFormFields();
		}
		// Do not override user entered customer values in UI
		if (String.isBlank(ppd.creditCard.firstName)){
			ppd.creditCard.firstName = customer.First_Name__c;
		}
		if (String.isBlank(ppd.creditCard.lastName)){
			ppd.creditCard.lastName = customer.Last_Name__c;
		}
		ppd.creditCard.company = customer.name;
		if (String.isBlank(ppd.creditCard.address)){
			ppd.creditCard.address = customer.street__c;
		}
		if (String.isBlank(ppd.creditCard.city)){
			ppd.creditCard.city = customer.city__c;
		}
		if(String.isBlank(ppd.creditCard.state)){
			ppd.creditCard.state = customer.state__c;
		}
		if(String.isBlank(ppd.creditCard.zip)){
			ppd.creditCard.zip = customer.zip_code__c;
		}
		if(String.isBlank(ppd.creditCard.country)){
			ppd.creditCard.country = customer.country__c;
		}
		ppd.formFields.billingFirstName = ppd.creditCard.firstName;
		ppd.formFields.billingLastName = ppd.creditCard.lastName;
		system.debug(LoggingLevel.Error, '>>> post setFormFieldsFromCustomer: ' + ppd);
	}
	
	// Assumption ppd and ppd.formFields are not null
	private void setFormFieldsFromSO(Sales_Order__c so){ //KNDY-12198 
		ppd.formFields.invoiceNumber = so != null ? so.Name : 'N/A';
		if (so == null) return;
		ppd.formFields.shippingFirstName = so.Ship_To__r.First_Name__c;
		ppd.formFields.shippingLastName = so.Ship_To__r.Last_Name__c;
		ppd.formFields.shippingCompany = so.Company__r.Name;
		ppd.formFields.shippingAddress = so.Ship_to_Street__c;
		ppd.formFields.shippingCity = so.Ship_to_City__c;
		ppd.formFields.shippingState = so.Ship_to_State__c;
		ppd.formFields.shippingZipCode = so.Ship_to_Zip_Code__c;
		ppd.formFields.shippingCountry = so.Ship_to_Country__c;
		Decimal tax =  (KSE.addQuantityToField(so.VAT_Amount__c,0) +
						KSE.addQuantityToField(so.Sales_Tax__c,0)).setScale(2,RoundingMode.HALF_EVEN);//
		
		ppd.formFields.tax = String.ValueOf(tax);
		//KNDY-15863
		ppd.creditCard.ccv = paymentCCV;
	}
	
	// Assumption ppd and ppd.formFields are not null
	private void setFormFieldsFromCI(Customer_Invoice__c ci){ //KNDY-12198 
		ppd.formFields.invoiceNumber = ci != null ? ci.Name : 'N/A';
		if (ci == null) return;
		ppd.formFields.shippingFirstName = ci.Ship_To__r.First_Name__c;
		ppd.formFields.shippingLastName = ci.Ship_To__r.Last_Name__c;
		ppd.formFields.shippingCompany = ci.Company__r.Name;
		ppd.formFields.shippingAddress = ci.Ship_to_Street__c;
		ppd.formFields.shippingCity = ci.Ship_to_City__c;
		ppd.formFields.shippingState = ci.Ship_to_State__c;
		ppd.formFields.shippingZipCode = ci.Ship_to_Zip_Code__c;
		ppd.formFields.shippingCountry = ci.Ship_to_Country__c;
		Decimal tax =  KSE.addQuantityToField(ci.Total_Value_Added_Tax__c,0) + 
						KSE.addQuantityToField(ci.Total_Sales_Tax__c,0);
		ppd.formFields.tax = String.ValueOf(tax);
		//KNDY-15863
		ppd.creditCard.ccv = paymentCCV;
	}
			
	private Customer__c getCustomer(Id custId){ //KNDY-12198
		SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','First_Name__c', 'Last_Name__c','street__c','city__c',
			'state__c','zip_code__c','country__c','RecordType.DeveloperName',
			'Company__r.Default_Transaction_Currency__c'
		});
		soql.setWhereClause('Id = :custId');
		List<Customer__c> custs = Database.query(soql.getQuery());
		system.assert(custs.size() == 1, '>>> custs: ' +custs);
		return custs[0];
	}
	
	public void updateCustomer(){
		if(pp.Customer__c != null){
			this.customerId = pp.Customer__c;
			updatePaymentProfile();
		}
	}
	
	public void defaultCustomerReceiptLine(){
		
		crl = new Customer_Receipt_Line__c();
		
		string ciId = Apexpages.currentPage().getParameters().get('customerInvoiceId');
		if(ciId instanceOf Id){
			
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id', 'Company__r.Default_Transaction_Currency__c'
            });
            soql.setWhereClause('Id = :ciId');
            List<Customer_Invoice__c> cis = Database.query(soql.getQuery());

            if(cis.size() > 0){
                crl.Customer_Invoice__c = cis[0].Id;
            }
        }
        
        string soId = Apexpages.currentPage().getParameters().get('salesOrderId');
        if(soId instanceOf Id && crl.Customer_Invoice__c == null){
            
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id', 'Company__r.Default_Transaction_Currency__c'
            });
            soql.setWhereClause('Id = :soId');
            List<Sales_Order__c> sos = Database.query(soql.getQuery());



            if(sos.size() > 0){
                crl.Sales_Order__c = sos[0].Id;
            }
        }
        
        
        
        defaultAmount();
    }
    
    public void updatePaymentProfile(){
        
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','First_Name__c', 'Last_Name__c','name','street__c','city__c','state__c','zip_code__c','country__c', 'Company__r.Default_Transaction_Currency__c'
        });
        soql.setWhereClause('Id = :customerId');
        List<Customer__c> custs = Database.query(soql.getQuery());

		Customer__c c;
		if(custs.size() > 0){
			c = custs[0];
		}else{
			c = new Customer__c(); // Will this ever be executed?
		}


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        soql = new SOQLUtil('Payment_Profile__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','name','gateway__c','customer__c','payment_profile_ID__c'
        });
        string cusId = this.customerId;
        soql.setWhereClause('Customer__c = :cusId AND Gateway__c = \'Authorize.net\'');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Payment_Methods__r');
        childRel.addFields(new set<string>{
            'Id','name','Payment_Method_ID__c'
        });
        soql.addChildRelationship(childRel);
        List<Payment_Profile__c> profiles = Database.query(soql.getQuery());
									
		if(profiles.size() > 0){
			pp = profiles[0];
			if(pp.Payment_Methods__r.size() == 1){
				selectedPaymentMethodId = pp.Payment_Methods__r[0].Id;
			}
		}else{
			pp = new Payment_Profile__c(Customer__c = this.customerId);
			ppd = new PaymentHandler.PaymentProfileDetail();
			ppd.customerId = c.Id;
			ppd.shipToCustomerId = c.Id;
			ppd.creditCard = new PaymentHandler.CreditCardDetail();
			if (c.Id != null){ //KNDY-12198
				//system.assert( 1 != 1, '>>> updatePaymentProfile customer c: ' + c);
				setFormFieldsFromCustomer(c);
			}
			
		}
									
	}
	
	public List<SelectOption> getPaymentMethodOptions(){
		List<SelectOption> options = new List<SelectOption>{new SelectOption('', '- Select One -')};
		if(pp.Payment_Methods__r.size() > 0){
			for(Payment_Method__c pm : pp.Payment_Methods__r){
				options.add(new SelectOption(pm.Id, pm.Name));
			}
		}
		return options;
	}
	
	public void togglePmtMethod(){
		showAddPaymentMethod = !showAddPaymentMethod;
		if(showAddPaymentMethod){
			Customer__c c = getCustomer(customerId); //KNDY-12198
			if (ppd.creditCard == null){
				ppd.creditCard = new PaymentHandler.CreditCardDetail();
				setFormFieldsFromCustomer(c);
			}
		}
	}
	
	
	public void createPaymentProfile(){
		system.debug(LoggingLevel.Error, '>>>>In createPaymentProfile');
		try{
			system.debug(LoggingLevel.Error, '>>>>creating new PH');
			
			// Form Fields Object is populated
			PaymentHandler ph = new PaymentHandler();
			
			if (String.isBlank(ppd.creditCard.cardNumber) ||
				String.isBlank(ppd.creditCard.expirationDate) ||
				String.isBlank(ppd.creditCard.CCV)){ //KNDY-12730 KNDY-12198
					String message = 'Credit card number, expiration date and CCV are required';
					Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, message));
					return ;
			}
			
			ph.setBillToFormFields(ppd); //KNDY-12198
			//system.assert(1 != 1, '>>> ppd: ' + ppd);
			Payment_Profile__c tmpPP = ph.createPaymentProfile(ppd);
			if(tmpPP.Id != null){
				updatePaymentProfile();
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM, 'Payment Profile successfully created'));
			}else{
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Unable to create Payment Profile'));
			}
		}catch(Exception ex){
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Unable to create Payment Profile: ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		
		
	}
	
	public void createPaymentMethod(){
		PaymentHandler ph = new PaymentHandler();
		try{
			PaymentHandler.CreditCardDetail ccd = ppd.creditCard;
			system.debug('ppd.creditCard='+ppd.creditCard);
			if (String.isBlank(ppd.creditCard.cardNumber) ||
				String.isBlank(ppd.creditCard.expirationDate) ||
				String.isBlank(ppd.creditCard.CCV)){ //KNDY-12730 KNDY-12198 KNDY-10317
					String message = 'Credit card number, expiration date and CCV are required';
					Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, message));
					return ;
			}
			Payment_Method__c tmpPM = ph.createPaymentMethod(pp.Id, ccd);
			if(tmpPM.Id != null){
				updatePaymentProfile();
				selectedPaymentMethodId = tmpPM.Id;
				togglePmtMethod();
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM, 'Payment Method successfully created'));
			}else{
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Unable to create Payment Method'));
			}
		}catch(Exception ex){
			system.debug('EXCEPTION: ' + ex.getMessage() + ' - ' +  ex.getStackTraceString());
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Unable to create Payment Method: ' + ex.getMessage()));
		}
	}
	
	// This method is called when ci or so lookup changes, and from constructor
	// If amount is specified in url parameters
	// then the crl amount should be set to url amount, and
	// should not be reset to ci`s balance or so`s order total
	public void defaultAmount(){
		Decimal urlAmount = null;
		disableCreatePaymentButton = false;//KNDY-11812 KNDY-12027
		if(crl.Customer_Invoice__c != null && crl.Sales_Order__c != null){//KNDY-11812 KNDY-12027
			disableCreatePaymentButton = true;
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, Label.Please_select_either_a_customer_invoice_or_sales_order_to_create_payment));
			return;
		}
		
		string urlAmountStr = Apexpages.currentPage().getParameters().get('amount');
		if(urlAmountStr != null ){
			try{
				urlAmount = Decimal.ValueOf(urlAmountStr.trim());
			}
			catch (TypeException ex){
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, Label.Amount_in_url_must_be_a_decimal_or_integer));
				return;
			}
		}
		//if url has an amount parameter, set it as amount to charge
		if (urlAmount != null){
			crl.Amount__c = urlAmount;
		}
		
		if(crl.Customer_Invoice__c != null){
			Customer_Invoice__c ci = fetchCustomerInvoice(crl.Customer_Invoice__c);
			// reset amount iff url has no amount parameter
			if (urlAmount == null){
				crl.Amount__c = ci.Balance__c;
			}
			validateCreatePaymentForCI(ci);
			setFormFieldsFromCI(ci);
		}else if(crl.Sales_Order__c != null){
			Sales_Order__c so = fetchSalesOrder(crl.Sales_Order__c);
			// reset amount iff url has no amount parameter
			if (urlAmount == null){
				crl.Amount__c = so.Order_Total__c;
			}
			validateCreatePaymentForSO(so);
			setFormFieldsFromSO(so);
		}
		
	}

	// This method is called when Amount changes
	public void validateAmount(){
		if(crl.Customer_Invoice__c != null){
			Customer_Invoice__c ci = fetchCustomerInvoice(crl.Customer_Invoice__c);
			validateCreatePaymentForCI(ci);
			setFormFieldsFromCI(ci);
		}else if(crl.Sales_Order__c != null){
			Sales_Order__c so = fetchSalesOrder(crl.Sales_Order__c);
			validateCreatePaymentForSO(so);
			setFormFieldsFromSO(so);
		}
	}
	

	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	private Customer_Invoice__c fetchCustomerInvoice(Id ciId){
		Customer_Invoice__c ci = new Customer_Invoice__c();
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Balance__c','Bill_To_Customer__c','Customer__c', 
			'Name','Company__r.Credit_Card_Bank_Account__c', 'Company__r.Default_Transaction_Currency__c',
			'Ship_To__r.First_Name__c','Ship_To__r.Last_Name__c', 'Company__r.Name',
			'Ship_to_Street__c','Ship_to_City__c','Ship_to_State__c',
			'Ship_to_Zip_Code__c','Ship_to_Country__c',
			'Total_Sales_Tax__c', 'Total_Value_Added_Tax__c'
		});
		soql.setWhereClause('ID = :ciId');
		ci = Database.query(soql.getQuery());
		return ci;
	}
	
	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	private Sales_Order__c fetchSalesOrder(Id soId){
		Sales_Order__c so = new Sales_Order__c();
		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c','Order_Total__c', 'Bill_To__c', 'Customer__r.Top_Parent_Customer__c',
			'Name','Company__r.Credit_Card_Bank_Account__c', 'Company__r.Default_Transaction_Currency__c',
			'Ship_To__r.First_Name__c','Ship_To__r.Last_Name__c', 'Company__r.Name',
			'Ship_to_Street__c','Ship_to_City__c','Ship_to_State__c',
			'Ship_to_Zip_Code__c','Ship_to_Country__c',
            'VAT_Amount__c','Sales_Tax__c'
		});
		soql.setWhereClause('Id = :soId');
		so = Database.query(soql.getQuery());
		return so;
	}
	
	// Cannot create payment if crl amount is greater than ci`s balance, or
	// pp customer check fails
	private void validateCreatePaymentForCI(Customer_Invoice__c ci){
		if (crl.Amount__c > ci.Balance__c){
			disableCreatePaymentButton = true;
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, Label.Cannot_charge_an_amount_greater_than_Customer_Invoice_Balance + ': ' + ci.Balance__c));
			return;
		}
		validatePPCustomer(ci.Bill_To_Customer__c, ci.Customer__c);
	}
	
	// Cannot create payment, if crl amount is greater than  so`s order total, or
	// if pp customer check fails
	private void validateCreatePaymentForSO(Sales_Order__c so){
        if (so.Status__c == 'Closed'){ //KNDY-10289
            disableCreatePaymentButton = true;
            Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, Label.Unable_to_create_credit_card_payment_as_the_sales_order_is_closed));
            return;
        }
		if (crl.Amount__c > so.Order_Total__c){
			//KNDY-15928
			//disableCreatePaymentButton = true; 
			string warningMsg = Label.Cannot_charge_an_amount_greater_than_Sales_Order_Order_Total.replace('<x>',so.Order_Total__c != null ? String.ValueOf(so.Order_Total__c) : '');
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, warningMsg) );
			return;
		}
		validatePPCustomer(so.Bill_To__c, so.Customer__r.Top_Parent_Customer__c);
	}
	
	//KNDY-11812 KNDY-12027 PP Customer can be charged for a CI or SO
	// if PP customer is bill to or Top Parent on CI or SO
	private void validatePPCustomer(Id billToCustomerId, Id topParentCustomerId){
		if ( pp.Customer__c == billToCustomerId||
			pp.Customer__c == topParentCustomerId){
			disableCreatePaymentButton = false;
		}
		else{
			disableCreatePaymentButton = true;
		}
	}
	
	public void createPayment(){
		
		if(selectedPaymentMethodId == '' || selectedPaymentMethodId == null){
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, 'Please select a Payment Method'));
			return;
		}
		if (crl.Customer_Invoice__c == null && crl.Sales_Order__c == null){ //KNDY-12198
            Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, 'Please enter customer invoice or sales order.'));
            return;
		}
		try{
			PaymentHandler ph = new PaymentHandler();
			Id referenceId = crl.Customer_Invoice__c != null ? crl.Customer_Invoice__c : crl.Sales_Order__c;
			string refName = '';
			if(crl.Customer_Invoice__c != null) {
				Customer_Invoice__c ci = fetchCustomerInvoice(referenceId);
				validateCreatePaymentForCI(ci);
				if(disableCreatePaymentButton)
					return;
				if(ci != null  && ci.Company__r.Credit_Card_Bank_Account__c == null){
					Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Please populate the Credit Card Bank Account lookup on the company.'));
					return;
				}
				setFormFieldsFromCI(ci);
			}
			else {
				Sales_Order__c so = fetchSalesOrder(referenceId);
				if(so != null&& so.Company__r.Credit_Card_Bank_Account__c == null){
					Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Please populate the Credit Card Bank Account lookup on the company.'));
					return;
				}
				setFormFieldsFromSO(so);
			}
			
			PaymentHandler.PaymentResponse pResponse = ph.chargePaymentMethod(selectedPaymentMethodId, referenceId, ppd, crl.Amount__c);
			if(pResponse.isSuccess){
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                Id customerReceiptId = pResponse.customerReceiptId;
                SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id','name', 'Company__r.Default_Transaction_Currency__c'
                });
                soql.setWhereClause('Id = :customerReceiptId');
                Customer_Receipt__c cr = Database.query(soql.getQuery());

				paymentCreated = true;
				paymentId = cr.Id;
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM, pResponse.response));
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM, cr.Name + ' successfully created'));
			}else{
				Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, pResponse.response));
			}
		}catch(Exception ex){
			Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Unable to create Payment: ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		
	}
	
	public pageReference viewPayment(){
		PageReference pageRef = new PageReference('/' + paymentId);
		return pageRef;
	}
	
}
