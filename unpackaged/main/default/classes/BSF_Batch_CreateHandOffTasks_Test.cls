@isTest
public class BSF_Batch_CreateHandOffTasks_Test 
{
	@testSetup
    public static void setup()
    {
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420',
            Account_Status__c='Active'
        );
        Account mobileAcc2 = new Account(
            name = 'Test Account 2',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = 'PO BOX 1', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421',
            Account_Status__c='Active'
        );
        accList.add(mobileAcc1);
        accList.add(mobileAcc2);
        insert accList;
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
        Taxonomy__c taxo = new Taxonomy__c(Division_Code__c='Div1', Division_Key__c=42068, Division_Name__c='Div_1', 
                                             DS_Region_Code__c='DSR1', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_1', 
                                             District_Code__c='Dist1',District_Key__c=42070,District_Name__c='District_1',
                                             Collection_Operation_Name__c='CO_2',Collection_Operation_Code__c='C-OP2',Collection_Operation_Key__c=1111,
                                             skedulo_region_cd__c='SkReg1',skedulo_region_name__c='SkReg_1',Time_Zone__c='GMT',Zip_Code__c='48420',RecordTypeId=recordTypeId);
        taxo.start_Date__c=Date.newInstance(2022,1,1);
        taxo.End_date__c=Date.newInstance(4000,1,1);
        
        insert taxo;
		
		List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = AccountTeamMemberService_Test.populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = AccountTeamMemberService_Test.populateUserFields('DM','User',drdManagerProfile.Id,60);
        Test.startTest();
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
     }
    
    @isTest static void batchTest()
     {
         Account testMobileAccount=[select id from account where name='Test Account 1' limit 1];
         List<User> users =[Select id from user where Profile.name='DRD Profile'];
         
         List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=users[users.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Area Booking Manager',UserId=users[users.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        
        insert coveringRecruiterList;
         Test.StartTest();
         BSF_Batch_CreateHandOffTasks batch = new BSF_Batch_CreateHandOffTasks();
         database.executeBatch(batch);
         Test.stopTest();
     }
    
    
}