public with sharing class FulfillmentDisableButtonExt {


	public ApexPages.StandardController con;
	public FulfillmentDisableButtonExt(ApexPages.StandardController controller) {
		this.con = controller;
	}

	public void errMsg() {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, Label.Button_Not_Available);
        ApexPages.addMessage(myMsg);
    }
}