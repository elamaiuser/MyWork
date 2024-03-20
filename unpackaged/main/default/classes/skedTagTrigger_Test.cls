@isTest
private class skedTagTrigger_Test {

    static testmethod void testValidateInsert() {
        Test.startTest();
        
        skedTriggerHub_Cache.setIsAdminUser(false);
        
        sked__Tag__c testTag1 = new sked__Tag__c(
        	Name = 'Test Tag 1'
        );
        
        string errorMsg1 = '';
        try {
        	insert testTag1;
        }
        catch (Exception ex) {
            errorMsg1 = ex.getMessage();
        }
        
        Test.stopTest();
    }

    static testmethod void testValidateUpdate() {
        Test.startTest();
        
        sked__Tag__c testTag1 = new sked__Tag__c(
        	Name = 'Test Tag 1'
        );
        insert testTag1;
        
        skedTriggerHub_Cache.setIsAdminUser(false);
        
        testTag1.Name = 'Test Tag 1 Updated';
        string errorMsg2 = '';
        try {
        	update testTag1;
        }
        catch (Exception ex) {
            errorMsg2 = ex.getMessage();
        }
        
        Test.stopTest();
    }

    static testmethod void testValidateDelete() {
        Test.startTest();
        
        sked__Tag__c testTag1 = new sked__Tag__c(
        	Name = 'Test Tag 1'
        );
        insert testTag1;
        
        skedTriggerHub_Cache.setIsAdminUser(false);
               
        string errorMsg3 = ''; 
        try {
        	delete testTag1;
        }
        catch (Exception ex) {
            errorMsg3 = ex.getMessage();
        }
        
        Test.stopTest();
    }
    
}