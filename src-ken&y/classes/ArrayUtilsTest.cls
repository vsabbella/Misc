@isTest
private class ArrayUtilsTest {
    static testMethod void testToCSV() {
        System.assertEquals('A,B,C', ArrayUtils.toCSV( new List<String>{'A', 'B', 'C'} ));
        System.assertEquals('1,2,3', ArrayUtils.toCSV( new List<Integer>{1, 2, 3} ));
    }
    
    static testMethod void testSplit() {
        System.assertEquals('A:B:C', ArrayUtils.split( new List<String>{'A', 'B', 'C'} , ':'));
        System.assertEquals('1:2:3', ArrayUtils.split( new List<Integer>{1, 2, 3} , ':'));
    }
}