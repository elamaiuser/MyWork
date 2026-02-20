@IsTest
global class BSF_TemplateCDA_FutOppBatch_Test {

    @testSetup
    static void setupData() {

        // Create base test data
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, sObject> mapTestData = testDataSetup.createAndInsertCommonObjects();

        // Mobile Account
        Account testMobileAccount = (Account) mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'TEST ACCOUNT 1';
        insert testMobileAccount;

        // Mobile Site
        sked__Location__c testMobileSite =
            (sked__Location__c) mapTestData.get('MOBILE_SITE');
        insert testMobileSite;

        // Template Opportunity
        Opportunity templateOpp =
            (Opportunity) mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.Id;
        templateOpp.Drive_Site__c = testMobileSite.Id;
        templateOpp.Is_Template__c = true;
        templateOpp.Anticipated_Registered_Donors__c = 35;
        templateOpp.X2RBC_Projected_Procedures__c = 10;
        templateOpp.WB_Projected_Procedures__c = 3;
        insert templateOpp;


        Opportunity mobileOpp =
            (Opportunity) mapTestData.get('MOBILE_OPP');
        mobileOpp.AccountId = testMobileAccount.Id;
        mobileOpp.Drive_Site__c = testMobileSite.Id;
        mobileOpp.Parent_Template_Id__c = templateOpp.Id;
        mobileOpp.Type_of_Drive__c = 'Mobile';
        mobileOpp.Drive_Date__c = Date.today().addDays(10);

        mobileOpp.Anticipated_Registered_Donors_Template__c = 1;
        mobileOpp.WholeBloodProceduresProjectedTemplate__c = 1;
        mobileOpp.Double_Red_Procedures_Projected_Template__c = 1;

        insert mobileOpp;
    }

    @IsTest
    static void testBatchWithChangedTodayFilter() {

        Opportunity templateOpp = [
            SELECT Id,
                   WB_Projected_Procedures__c,
                   X2RBC_Projected_Procedures__c,
                   Anticipated_Registered_Donors__c
            FROM Opportunity
            WHERE Is_Template__c = true
            LIMIT 1
        ];

        Opportunity mobileOpp = [
            SELECT Id, Parent_Template_Id__c
            FROM Opportunity
            WHERE Parent_Template_Id__c = :templateOpp.Id
            LIMIT 1
        ];

        templateOpp.WB_Projected_Procedures__c = 10;
        templateOpp.X2RBC_Projected_Procedures__c = 5;
        templateOpp.Anticipated_Registered_Donors__c = 45;

        TriggerHandler.bypass('OpportunityTriggerHandler');
        update templateOpp;

        Test.startTest();
        Database.executeBatch(
            new BSF_TemplateCDA_FutureOpportunity_Batch(true),
            50
        );
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Anticipated_Registered_Donors_Template__c,
                   WholeBloodProceduresProjectedTemplate__c,
                   Double_Red_Procedures_Projected_Template__c
            FROM Opportunity
            WHERE Id = :mobileOpp.Id
        ];

        System.assertEquals(
            45,
            updatedOpp.Anticipated_Registered_Donors_Template__c,
            'Anticipated Registered Donors should sync from template'
        );

        System.assertEquals(
            10,
            updatedOpp.WholeBloodProceduresProjectedTemplate__c,
            'WB Projected Procedures should sync from template'
        );

        System.assertEquals(
            5,
            updatedOpp.Double_Red_Procedures_Projected_Template__c,
            'X2RBC Projected Procedures should sync from template'
        );
    }

    @IsTest
    static void testBatchWithoutChangedTodayFilter() {

        Test.startTest();
        Database.executeBatch(
            new BSF_TemplateCDA_FutureOpportunity_Batch(false),
            50
        );
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Anticipated_Registered_Donors_Template__c,
                   WholeBloodProceduresProjectedTemplate__c,
                   Double_Red_Procedures_Projected_Template__c,
                   Parent_Template_Id__r.Anticipated_Registered_Donors__c,
                   Parent_Template_Id__r.WB_Projected_Procedures__c,
                   Parent_Template_Id__r.X2RBC_Projected_Procedures__c
            FROM Opportunity
            WHERE Parent_Template_Id__c != NULL
            LIMIT 1
        ];

        System.assertEquals(
            updatedOpp.Parent_Template_Id__r.Anticipated_Registered_Donors__c,
            updatedOpp.Anticipated_Registered_Donors_Template__c
        );

        System.assertEquals(
            updatedOpp.Parent_Template_Id__r.WB_Projected_Procedures__c,
            updatedOpp.WholeBloodProceduresProjectedTemplate__c
        );

        System.assertEquals(
            updatedOpp.Parent_Template_Id__r.X2RBC_Projected_Procedures__c,
            updatedOpp.Double_Red_Procedures_Projected_Template__c
        );
    }
    
    @IsTest
    static void testSchedulableExecutionAndConstructor() {
    
        Test.startTest();
    
        BSF_TemplateCDA_FutureOpportunity_Batch schedulableBatch =
            new BSF_TemplateCDA_FutureOpportunity_Batch(
                'Future Opportunity CDA Values Batch',
                true
            );
    
        String cronExp = '0 0 0 15 3 ? 2099';
    
        System.schedule(
            'Future Opportunity CDA Schedule Test',
            cronExp,
            schedulableBatch
        );
    
        Test.stopTest();
    
        CronTrigger ct = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Future Opportunity CDA Schedule Test'
            LIMIT 1
        ];
    
        Assert.areEqual(
            'WAITING',
            ct.State
        );
    }
}