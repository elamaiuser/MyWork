@isTest
private class BSF_Batch_CreateHandOffTasks_Test {
    
	@testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        
        List<Account> accList = new List<Account>();
        Account testMobileAccount;
        testMobileAccount = new Account(
            name = 'Test Account 1',
            Internal_Name__c = 'TEST ACCOUNT 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420',
            Account_Status__c='Active'
        );
        accList.add(testMobileAccount);
        
        testMobileAccount = new Account(
            name = 'Test Account 2',
            Internal_Name__c = 'TEST ACCOUNT 2',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = 'PO BOX 1', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421',
            Account_Status__c='Active'
        );
        accList.add(testMobileAccount);
        insert accList;
        
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
        Taxonomy__c taxo = new Taxonomy__c(
            Division_Code__c = 'Div1', 
            Division_Key__c = 42068, 
            Division_Name__c = 'Div_1', 
            DS_Region_Code__c = 'DSR1', 
            DS_Region_Key__c = 42069, 
            DS_Region_Name__c = 'Reg_1', 
            District_Code__c = 'Dist1',
            District_Key__c = 42070,
            District_Name__c = 'District_1',
            Collection_Operation_Name__c = 'CO_2',
            Collection_Operation_Code__c = 'C-OP2',
            Collection_Operation_Key__c = 1111,
            skedulo_region_cd__c = 'SkReg1',
            skedulo_region_name__c = 'SkReg_1',
            Time_Zone__c = 'GMT',
            Zip_Code__c = '48420',
            RecordTypeId = recordTypeId,
            start_Date__c=Date.newInstance(2022,1,1),
            End_date__c=Date.newInstance(4000,1,1)
        );
        insert taxo;
		
		List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = AccountTeamMemberService_Test.populateUserFields('DRD','User',drdProfile.Id, 60);
        List<User> dmUsers = AccountTeamMemberService_Test.populateUserFields('DM','User',drdManagerProfile.Id, 60);
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
     }
    
    @isTest static void batchTest() {
         Account testMobileAccount = [SELECT Id FROM Account WHERE Name ='Test Account 1' LIMIT 1];
         List<User> testDRDUsers = [SELECT Id FROM User WHERE Profile.Name = 'DRD Profile'];
         
        List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember testCoveringRecruiter;
        testCoveringRecruiter = new AccountTeamMember(
            AccountId = testMobileAccount.Id,
            Coverage_Reason__c = 'Leave of Absence (LOA)',
            TeamMemberRole = 'Account Manager',
            UserId = testDRDUsers[testDRDUsers.size()-1].Id,
            Is_Covering_Recruiter__c = true,
            Start_Date__c = System.today() - 2,
            End_Date__c = System.today() + 30
        );
        coveringRecruiterList.add(testCoveringRecruiter);
        
        testCoveringRecruiter = new AccountTeamMember(
            AccountId = testMobileAccount.Id,
            Coverage_Reason__c = 'Vacant Territory',
            TeamMemberRole = 'Area Booking Manager',
            UserId = testDRDUsers[testDRDUsers.size()-2].Id,
            Is_Covering_Recruiter__c = true,
            Start_Date__c = System.today() + 50,
            End_Date__c = System.today() + 100
        );
        coveringRecruiterList.add(testCoveringRecruiter);
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        insert coveringRecruiterList;
        
        Test.StartTest();
        BSF_Batch_CreateHandOffTasks batch = new BSF_Batch_CreateHandOffTasks();
        database.executeBatch(batch);
        Test.stopTest();
     } 
}