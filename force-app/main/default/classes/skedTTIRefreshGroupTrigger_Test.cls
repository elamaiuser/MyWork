@isTest
private class skedTTIRefreshGroupTrigger_Test {
    
    static testMethod void beforeInsertValidations_Test() {
        List<sked_Travel_Time_Index_Refresh_Group__c> testTTIRefreshGroupList = new List<sked_Travel_Time_Index_Refresh_Group__c>();
        
        sked_Travel_Time_Index_Refresh_Group__c testTTIRefreshGroup;
        testTTIRefreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
        	sked_Collection_Operations_To_Refresh__c = 'Adrian MI;Anaheim CA;Baltimore MD'
        );
        testTTIRefreshGroupList.add(testTTIRefreshGroup);
        
        testTTIRefreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
        	sked_Collection_Operations_To_Refresh__c = 'Anaheim CA;Baltimore MD;Boise ID'
        );
        testTTIRefreshGroupList.add(testTTIRefreshGroup);
        
        Test.startTest();
        try{
        	insert testTTIRefreshGroupList;
        }catch(Exception ex) {
            Assert.isTrue(ex.getMessage().contains('The following collection operations are duplicated'));
        }
        Test.stopTest();
    }
    
    static testMethod void beforeInsertValidation_processedCO_Test() {
        
        sked_Travel_Time_Index_Refresh_Group__c testTTIRefreshGroup;
        testTTIRefreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
        	sked_Collection_Operations_To_Refresh__c = 'Adrian MI;Anaheim CA;Baltimore MD'
        );
        insert testTTIRefreshGroup;
        
        testTTIRefreshGroup = new sked_Travel_Time_Index_Refresh_Group__c(
        	sked_Collection_Operations_To_Refresh__c = 'Baltimore MD;Boise ID'
        );
        
        Test.startTest();
        try{
        	insert testTTIRefreshGroup;
        }catch(Exception ex) {
            Assert.isTrue(ex.getMessage().contains('The following collection operations are already being processed:'));
        }
        Test.stopTest();
    }

}