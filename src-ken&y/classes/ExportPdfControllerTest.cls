@isTest
private class ExportPdfControllerTest {

    static testMethod void testExportPdf() {
        // Arrange
        ExportPdfController con = new ExportPdfController();
        
        // Assert
        System.assertNotEquals(null, con);
    }
}