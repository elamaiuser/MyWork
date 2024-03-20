/**
* @description: This class is the Test class for PopulateResourceRegionBatch Scheduler Batch class.
**   Modification Log  ****
*  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 07/22/2023			Barnojit Sharma			Code coverage updated for Satellite Zip Code search and assigning default region scenario (Logic for HRP-10504)
********************************************************************************************************************************************************************************************
*/
@isTest
private class PopulateResourceRegionBatchTest {
    @TestSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Biomed_Collection_Op_Center__c testCo = [SELECT Id,Name FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        sked__Location__c testLocation1 = [Select Id from sked__Location__c Limit 1][0];
        sked__Region__c testRegion1 = [Select Id from sked__Region__c Limit 1][0];
        
        sked__Resource__c testResource = [SELECT Id, sked_Timezone__c, sked_Home_Zip_Code__c, sked_Work_Zip_Code__c, sked_Biomed_Collection_Op_Center_Name__c, sked__Primary_Region__c
                                          FROM sked__Resource__c WHERE sked__Is_Active__c = true AND sked__Resource_Type__c = 'Person' LIMIT 1][0];
        testResource.sked_Timezone__c ='America/Thunder_Bay';
        testResource.sked_Work_Zip_Code__c = '44568';
        testResource.sked_Collection_Operation_Name_Staging__c ='Danvers MA';
        testResource.sked__Primary_Region__c = testRegion1.Id;
        update testResource;
        System.assertNotEquals(null, testResource.sked_Work_Zip_Code__c, 'resource not updated' );
        
        testCo.Name = testResource.sked_Collection_Operation_Name_Staging__c;
        update testCo;
        System.assertNotEquals(null,  testCo.Name, 'collection opp not updated' );
        sked__Region__c testRegion = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = 'America/Thunder_Bay',
            sked_Biomed_Collection_Op_Center__c = testCo.Id
        );
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        System.assertNotEquals(null, taxonomies[0].Id, 'taxonomy not inserted' );
        taxonomies[0].Collection_Operation_Name__c = testResource.sked_Collection_Operation_Name_Staging__c;
        taxonomies[0].Zip_Code__c = testResource.sked_Work_Zip_Code__c;
        taxonomies[0].Start_Date__c = Date.today();
        taxonomies[0].End_Date__c = Date.today()+7;
        taxonomies[0].Type__c = 'Bio Collection BSF';
        update taxonomies;
        System.assertNotEquals(null, taxonomies[0].Type__c, 'taxonomy not updated' );
        sked__Region__c testRegion2 = testRegion1.clone(false ,false,false,false);
        testRegion2.Name = System.label.Default_Primary_Region_Name; //added default region name (HRP-10504)
        testRegion2.sked_Biomed_Collection_Op_Center__c = null;
        testRegion2.sked__Timezone__c = UserInfo.getTimezone().getID();
        insert testRegion2;
        System.assertNotEquals(null, testRegion2.Id, 'region not inserted' );
    }
    
    @isTest
    static void populateResourceRegionBatch_Test() {
        sked__Resource__c testResource = [SELECT Id,sked_Home_Zip_Code__c,sked_Work_Zip_Code__c,sked__Primary_Region__c,sked_Timezone__c
                                          FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCo = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        testResource.sked_Collection_Operation_Name_Staging__c = testCo.Name;
        update testResource;
        System.assertNotEquals(null, testResource.sked_Collection_Operation_Name_Staging__c, 'region not updated' );
        Test.startTest();
        Database.executeBatch(new PopulateResourceRegionBatch());
        Test.stopTest();
    }
    @isTest
    static void populateResourceRegionBatch2_Test() {
        sked__Resource__c testResource = [SELECT Id,sked_Home_Zip_Code__c,sked_Work_Zip_Code__c,sked__Primary_Region__c,sked_Timezone__c
                                          FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCo = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        sked__Region__c primaryRegion = [Select Id from sked__Region__c Limit 1][0];
        testResource.sked_Collection_Operation_Name_Staging__c = testCo.Name;
        testResource.sked_Home_Zip_Code__c ='887654';
        testResource.sked_Work_Zip_Code__c='';
        testResource.sked_Timezone__c = '';
        testResource.sked__Primary_Region__c = primaryRegion.id;
        update testResource;
        System.assertNotEquals(null, testResource.sked_Home_Zip_Code__c, 'region not updated' );
        sked__Region__c testRegion = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = 'America/Chicago',
            sked_Biomed_Collection_Op_Center__c = testCo.Id
        );
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        System.assertNotEquals(null, taxonomies[0].Id, 'taxonomy not inserted' );
        taxonomies[0].Collection_Operation_Name__c = testResource.sked_Collection_Operation_Name_Staging__c;
        taxonomies[0].Zip_Code__c = testResource.sked_Home_Zip_Code__c;
        taxonomies[0].Time_Zone__c = 'America/Thunder_Bay';
        update taxonomies;
        System.assertNotEquals(null, taxonomies[0].Time_Zone__c, 'taxonomy not updated' );
        Test.startTest();
        Database.executeBatch(new PopulateResourceRegionBatch());
        Test.stopTest();
    }
    @isTest
    static void populateResourceRegionBatch3_Test() {
        sked__Resource__c testResource = [SELECT Id,sked_Home_Zip_Code__c,sked_Work_Zip_Code__c,sked_Satellite_Zip_Code__c,sked__Primary_Region__c,sked_Timezone__c
                                          FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCo = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        testResource.sked_Collection_Operation_Name_Staging__c = testCo.Name;
        testResource.sked_Work_Zip_Code__c = null;
        testResource.sked_Satellite_Zip_Code__c = '0000'; //value added to Satellite Zip Code (HRP-10504)
        testResource.sked_Home_Zip_Code__c = null;
        update testResource;
        System.assertNotEquals(null, testResource.sked_Satellite_Zip_Code__c, 'resource not updated' );
        
        Test.startTest();
        Database.executeBatch(new PopulateResourceRegionBatch());
        Test.stopTest();
    }
    @isTest
    static void populateResourceRegionBatch4_Test() {
        sked__Resource__c testResource = [SELECT Id,sked_Home_Zip_Code__c,sked_Work_Zip_Code__c,sked__Primary_Region__c,sked_Timezone__c
                                          FROM sked__Resource__c LIMIT 1][0];
        Biomed_Collection_Op_Center__c testCo = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c LIMIT 1][0];
        
        testResource.sked__Primary_Region__c = null;
        update testResource;
		System.assertEquals(null, testResource.sked__Primary_Region__c, 'resource not updated' );        
        Test.startTest();
        //Testing of batch schedulling (HRP-10504)
        Datetime dt = Datetime.now().addHours(1);
        String jobID = System.schedule('PopulateResourceRegionBatch Job', '0 '+dt.minute() + ' '+dt.hour() + ' '+dt.day() + ' '+dt.month() + ' ? '+dt.year(), new PopulateResourceRegionBatch(new List<String>{testResource.Id},false));
        Test.stopTest();
    }
}