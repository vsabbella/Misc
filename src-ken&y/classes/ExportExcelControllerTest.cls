@isTest
private class ExportExcelControllerTest {

    static testMethod void testExportExcel() {
        // Arrange
        ExportExcelController con = new ExportExcelController();
        
        // Assert
        System.assertNotEquals(null, con);
    }
}