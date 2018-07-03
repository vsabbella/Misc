global with sharing class SupplierPaymentGlobalService {

    global static SupplierPaymentGlobalService getInstance(List<Supplier_Invoice__c> invoicesToPay) {
        return null;
    }

    private SupplierPaymentGlobalService(List<Supplier_Invoice__c> invoicesToPay) {

    }

    global void save() {

    }

    global boolean hasUncaughtException() {
        return false;
    }

    global boolean hasPermissionError() {
        return false;
    }

    global Supplier_Payment__c getPayment() {
        return null;
    }

    global String getSupplierPaymentKey(Supplier_Invoice__c invoice) {
        return null;
    }

    global Map<String, List<Supplier_Invoice__c>> getInvoicesBySupplier() {

        return null;
    }

    global Map<String, List<Supplier_Invoice__c>> getCreditMemosBySupplier() {

        return null;
    }

    global Map<String, List<Supplier_Invoice__c>> getInputInvoicesBySupplier() {

        return null;
    }

    global Map<String, List<Supplier_Invoice__c>> getInputCreditMemosBySupplier() {

        return null;
    }
}