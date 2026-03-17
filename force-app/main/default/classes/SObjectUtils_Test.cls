@isTest
private class SObjectUtils_Test {
    
    static testMethod void getSObjectPrefix_test() {
        
        Test.startTest();
        
        String objectName = 'Account';
		SObjectType sObjType = ((SObject)Type.forName(objectName).newInstance()).getSObjectType();
        String result = SObjectUtils.getSObjectPrefix(sObjType);
        
        Test.stopTest();
        
        Assert.isTrue(result == '001');
    }

}