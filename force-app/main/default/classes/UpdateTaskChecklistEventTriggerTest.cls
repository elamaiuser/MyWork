@IsTest
public class UpdateTaskChecklistEventTriggerTest {

    @IsTest
    static void testUpdateTaskChecklistEventTrigger() {

        Update_Task_Checklist__e eventRecord = new Update_Task_Checklist__e(
            CheckList_Name__c = 'Sample Checklist',
            Field_Api_Name__c = 'Status__c',
            Task_Id__c = '00Txx00005xxxXXXX', 
            Value__c = 'Completed'
        );

        Test.startTest();

        Database.SaveResult sr = EventBus.publish(eventRecord);

        Test.stopTest();

        System.assert(sr.isSuccess(), 'Platform Event publish should succeed');
    }
}
