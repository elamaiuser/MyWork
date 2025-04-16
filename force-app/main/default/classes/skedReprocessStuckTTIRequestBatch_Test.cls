/* This test class covers skedReprocessStuckTTIRequestBatch
 * Current Coverage: 97%
 * Modification Log:
   ******************
	Date					Developer				Comments
	*******************************************************************
	4/16/2025				Priti Jana			Created for HRP-14097
	*******************************************************************
 */ 

@isTest(SeeAllData = false)
private class skedReprocessStuckTTIRequestBatch_Test {
    @testSetup
    static void prepareTestData() {
        sked_Travel_Time_Index_Refresh_Request__c testTTIRR = new sked_Travel_Time_Index_Refresh_Request__c(
        	sked_Status__c = 'In Progress',
        	sked_Priority__c = 1000,
        	sked_Request_Type__c = 'Travel Time',
        	sked_Stuck_Retry_Count__c = 0,
        	sked_Origins__c = '44.5029725 -87.9686246',
        	sked_Destinations__c = '43.7778872 -88.419561'
        );
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        
        insert testTTIRR;
        
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        
        sked_TTIRR_Stuck_Job_Config_Setting__c testCustomSetting = new sked_TTIRR_Stuck_Job_Config_Setting__c(
        	sked_Enable_Auto_Reschedule__c = true,
        	sked_Is_Active__c = true,
        	sked_Maximum_Retries__c = 3,
        	sked_Reschedule_Interval_Minutes__c = 5,
        	sked_Stuck_Threshold_Minutes__c = 0
        );
        insert testCustomSetting;
    }
    
    static testMethod void test_maxRetryNotReached() {
        Test.startTest();
        Database.executeBatch(new skedReprocessStuckTTIRequestBatch()); 
        Test.stopTest();
    }
    
    static testMethod void test_maxRetryReached() {
        Test.startTest();
        sked_Travel_Time_Index_Refresh_Request__c testTTIRR = [SELECT Id, 
                                                               sked_Stuck_Retry_Count__c, sked_Status__c, 
                                                               sked_Error_Message__c 
                                                               FROM sked_Travel_Time_Index_Refresh_Request__c 
                                                               LIMIT 1];
        testTTIRR.sked_Stuck_Retry_Count__c = 3;
        update testTTIRR;
        
        Database.executeBatch(new skedReprocessStuckTTIRequestBatch()); 
        Test.stopTest();
    }
    
    static testMethod void test_scheduleBatch() {
        Test.startTest();
        skedReprocessStuckTTIRequestBatch test_batchInstance = new skedReprocessStuckTTIRequestBatch();
        SchedulableContext scon;
        test_batchInstance.execute(scon);
        Test.stopTest();
    }
}