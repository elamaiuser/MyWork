@isTest
public class skedDriveCOChangedBatch_Test {
    
    @isTest
    static void skedDriveCoChangedBatch_Test() {
        skedTestDataFactory tdf = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = tdf.setupCommonTestData();
        mapTestData = tdf.setupDriveData();

        sked__Location__c testSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        Biomed_Collection_Op_Center__c testCo = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCo2 = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation2');

        Test.startTest();
            sked_Site_Collection_Operation__c testSCO = new sked_Site_Collection_Operation__c(
                sked_Site__c = testSite.Id,
                sked_Collection_Operation__c = testCo2.Id,
                sked_Start_Date__c = System.today().addDays(-100),
                sked_End_Date__c = System.today().addDays(100)
            );
            insert testSCO;

           Database.executeBatch(new skedDriveCOChangedBatch(new Set<Id>{testSCO.Id}));
        
         Database.executeBatch(new skedDriveCOChangedBatch('',new Set<Id>{testSCO.Id}));
          Database.executeBatch(new skedDriveCOChangedBatch(null,286));
        Test.stopTest();
    }
}