/* This test class covers the below mentioned test classes
 * BSF_BatchUpdateOpportunityForZipCode
 * UpdateAllOpportunityForCollectionZip
 */

@isTest
private class BSF_BatchUpdateOpportunityForZipCodeTest {
    
    @testSetup
    static void prepareTestData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert DRD User
        User testDrdUser = (User)mapTestData.get('DRD_USER');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        testMobileAccount.Phone = '1234567890' ;
        testMobileAccount.Type = 'Business';
        testMobileAccount.Account_Manager__c = testDrdUser.Id;
        insert testMobileAccount;
        
        //insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.Id ;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        //insert drive service roles
        OpportunityContactRole testOppContactRole = new OpportunityContactRole(
             OpportunityId = testMobileOpp.Id,
             ContactId = testContact.Id,
             Role = 'Primary Contact'
         );
         insert testOppContactRole;
        
        //insert CO
        Biomed_Collection_Op_Center__c testCO = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        insert testCO;
        
        sked__Region__c region = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = testDrdUser.Id,
            sked_Biomed_Collection_Op_Center__c = testCO.Id
        );
        insert region;	
        
       Collections_Region__c donorServicesRegion = new Collections_Region__c(name = 'Test Donor Services Region');
       insert donorServicesRegion;
        
        Collections_Territory__c regionTerritory = new Collections_Territory__c(
            Name = 'Test Territory',
            Zip__c = '27560',
            BDM__c = testDrdUser.id,
            Region__c = donorServicesRegion.Id
        );
        insert regionTerritory;
        
        sked_Site_Collection_Operation__c sc=new sked_Site_Collection_Operation__c(
            sked_Collections_Zip_Code__c = regionTerritory.Id,
        	sked_Start_Date__c = system.today(),
        	sked_End_Date__c = system.today() + 1,
            sked_Site__c= testMobileSite.Id
        );
        insert sc;
    }
    
    static testMethod void testScheduleClass() {
        Test.StartTest();
		BSF_BatchUpdateOpportunitySchedule testsche = new BSF_BatchUpdateOpportunitySchedule(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        Assert.isTrue(contrg != null);
    }
    
    static testMethod void test() {
        Test.startTest();

        BSF_BatchUpdateOpportunityForZipCode ba = new BSF_BatchUpdateOpportunityForZipCode();
        Id jobid = Database.executeBatch(ba, 5);
        
        Test.stopTest();
        Assert.isTrue(jobId != null);        
    }
    
    static testMethod void UpdateAllOpportunityForCollectionZip_test() {
        Test.startTest();

        UpdateAllOpportunityForCollectionZip batchInstance = new UpdateAllOpportunityForCollectionZip();
        Id jobid = Database.executeBatch(batchInstance, 5);
        
        Test.stopTest();
        Assert.isTrue(jobId != null); 
    }
}