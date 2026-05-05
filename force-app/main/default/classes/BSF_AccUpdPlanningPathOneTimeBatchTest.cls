@isTest
public class BSF_AccUpdPlanningPathOneTimeBatchTest {

    @testSetup
    static void setup() {
        // 1. Setup Configuration Records for BSF_TaskPlanningService
        Task_Package__c pkg = new Task_Package__c(
            Name = 'Standard Package',
            Sort_Order__c = 1
        );
        insert pkg;

        Task_Definition__c td = new Task_Definition__c(
            Name = 'Test Task Definition'
        );
        insert td;

        Task_Package_Item__c item = new Task_Package_Item__c(
            Task_Package__c = pkg.Id,
            Task_Definition__c = td.Id
        );
        insert item;

        // 2. Get Mobile Account Record Type
        Id mobileRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Mobile Account' LIMIT 1].Id;

        // For the other record type, we'll just use a different one if available or a mock
        Id otherRtId;
        List<RecordType> otherRts = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name != 'Mobile Account' LIMIT 1];
        if(!otherRts.isEmpty()) {
            otherRtId = otherRts[0].Id;
        } else {
            // Fallback: just use mobileRtId for now if no others exist, but ideally different
            otherRtId = mobileRtId;
        }

        // 3. Create Account Scenarios
        List<Account> accs = new List<Account>();

        // Positive: Mobile, Active, Path is null
        accs.add(new Account(
            Name = 'Target Account',
            RecordTypeId = mobileRtId,
            Account_Status__c = 'Active',
            Planning_Path__c = null
        ));        

        insert accs;

        // 4. Setup Opportunity for Cascade Batch verification
        Account targetAcc = [SELECT Id FROM Account WHERE Name = 'Target Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Template Opp',
            AccountId = targetAcc.Id,
            Is_Template__c = true,
            Is_Path_Overridden__c = false,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    @isTest
    static void testPositiveFlow() {
        Test.startTest();
        BSF_AccountUpdPlanningPathOneTimeBatch batch = new BSF_AccountUpdPlanningPathOneTimeBatch('Active');
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify Account was updated
        Account acc = [SELECT Planning_Path__c FROM Account WHERE Name = 'Target Account' LIMIT 1];
        System.assertEquals('Standard', acc.Planning_Path__c, 'Target account should have Planning Path updated to Standard');

        // Verify Task Planning Defaults were created by the service
        Integer configCount = [SELECT count() FROM Task_Planning_Default__c WHERE Account__c = :acc.Id];
        System.assert(configCount > 0, 'Task Planning Default records should have been created for the target account');
    }    

    @isTest
    static void testChaining() {
        Test.startTest();
        BSF_AccountUpdPlanningPathOneTimeBatch batch = new BSF_AccountUpdPlanningPathOneTimeBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that BSF_AccountTaskPlanningCascadeBatch was queued
        Integer jobCount = [SELECT count() FROM AsyncApexJob WHERE ApexClass.Name = 'BSF_AccountTaskPlanningCascadeBatch'];
        System.assert(jobCount > 0, 'The cascade batch should have been queued in the finish method');
    }
}