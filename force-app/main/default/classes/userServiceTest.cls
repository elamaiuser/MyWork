/* Modification Log 
 * Date					     Developer Name			     Comments
 * *******************************************************************************************
 * 10/29/2024				  Priti Jana				Addded test method for HRP-9815
 *********************************************************************************************
*/

@isTest
public class userServiceTest {
    
    @testSetup static void testSetup(){  
		
        List<User> userList = new List<User>();
        
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Global Admin'];
        
        User user = new User(
            firstName = 'test1',
            lastName = 'test2',
            profileId = prof.id,
            Username  = 'test@CAt.com'+UserInfo.getOrganizationId(),
            email = 'test@CAt.com',
            MobilePhone = '125-(455)-7890',
            Workphone__c = '123-(456)-7899',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Alias = 'test'
        );
        userList.add(user);
        
        User user2 = new User(
            LastName = 'user2',
            FirstName = 'user3',
            Username = 'testUser@test.com'+String.valueOf(system.today()),
            Email = 'abc@gmail1.com',
            MobilePhone = '123-(456)-7890',
            Workphone__c = '123-(456)-7899',
            Phone = '74483939',
            Alias = 'alias2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = prof.id,
            LanguageLocaleKey ='en_US'
        );
        userList.add(user2);
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert userList; 
        }
          
        system.runAs(userList[0]) {  
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
            Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
            mapTestData = testDataFactory.setupDriveData();
            
            sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
            sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
            sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
            Account testAccount = (Account) mapTestData.get('testAccount1');
            sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
      
            sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
                sked_Donors_Scheduled__c = 1,
                sked_End_Time__c = Time.newInstance(20,0,0,0),
                sked_Start_Time__c = Time.newInstance(14,0,0,0),
                sked_Drive__c = testDrive.Id,
                sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
                sked_Equipment__c = 1,
                sked_Lunch_Break__c = FALSE,
                sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
                sked_Lunch_Break_Duration__c = 0,
                sked_Lunch_Break_End_Time__c = NULL,
                sked_Lunch_Break_Start_Time__c = NULL,
                sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
                sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
                sked_Order__c = 1,
                sked_Sign_Up_Reduction__c = 0,
                sked_Staff_Setup__c = 1,
                sked_Vehicles_Needed__c = 1,
                sked_Volunteer_Setup__c = 1
            );
            insert testDriveShift;
            
            sked__Job__c testJob = new sked__Job__c(
                sked__Region__c = testRegion.Id,
                sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
                sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
                sked__Duration__c = 60,
                sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
                sked_Drive__c = testDrive.Id,
                sked_Drive_Shift__c = testDriveShift.Id,
                sked_Resource_Role__c = '2RBC',
                sked_Volunteer_Role__c = 'Donor Ambassador'
            );
            insert testJob;
            
            sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
                sked__Job__c = testJob.Id,
                sked__Resource__c = testResource.Id,
                sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
            );
            insert testJobAllocation;
            
            List<sked_Operation_Record__c> opRecordList = skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});
            String drdRepInfo = userList[0].FirstName + ' ' + userList[0].LastName;
            for(sked_Operation_Record__c opRecord : opRecordList) {
                opRecord.sked_DRD_Rep__c = drdRepInfo;
                opRecord.sked_DRD_Rep_Contact__c = userList[0].WorkPhone__c;
            }
            update opRecordList;
        }
    }
    
    static testMethod void testMobilePhoneFormat(){
        List<User> userList = [Select Id, Name, Phone, MobilePhone FROM User];
        Test.startTest();
        userService.formatMobilePhone(UserList);
        Test.stopTest();
    }
    
    @isTest
    static void testPermissionSetAssignment() {
        
        User userRec = [Select Id, FirstName, CompanyName, Profile.Name From User Where FirstName = 'test1'][0];
        userRec.CompanyName = 'RC';
        update userRec;
       
        Test.startTest();
        	List<User> usersLst = [Select Id, FirstName, CompanyName, Profile.Name From User Where FirstName = 'test1'];
            List<AssignResourcesToUserEvent__e> asrEvents = new List<AssignResourcesToUserEvent__e>();
            For(User u : usersLst) {
                AssignResourcesToUserEvent__e asrEvent = new AssignResourcesToUserEvent__e();
                asrEvent.UserId__c = u.Id;
                asrEvents.add(asrEvent);
            }
            if(asrEvents != null && asrEvents.size() > 0) {
                EventBus.publish(asrEvents);
            }

        Test.stopTest();
        
        List<PermissionSetAssignment> psaLst = [Select Id, AssigneeId, PermissionSetId From PermissionSetAssignment Where AssigneeId = :userRec.Id];
        system.assertNotEquals(0, psaLst.size());
    }
    
    //HRP-9815 --> Starts Here
    static testMethod void testUpdateDrdRepContactOnOpRecordUponPhoneChange() {
        Test.startTest();
        User userRec = [Select Id, FirstName, LastName, WorkPhone__c From User Where FirstName = 'test1'][0];
        
        // User Update
        userRec.WorkPhone__c = '1234507890';
        update userRec;
        Test.stopTest();
    }
    //HRP-9815 --> Ends Here
    
    @isTest
    static void testSpecialPermissionSetAssignment() {
        Test.startTest();
        	List<User> usersLst = [Select Id, FirstName, CompanyName, Profile.Name From User Where FirstName = 'user3' LIMIT 1];
            List<AssignResourcesToUserEvent__e> asrEvents = new List<AssignResourcesToUserEvent__e>();
            For(User u : usersLst) {
                AssignResourcesToUserEvent__e asrEvent = new AssignResourcesToUserEvent__e();
                asrEvent.UserId__c = u.Id;
                asrEvents.add(asrEvent);
            }
            if(asrEvents != null && asrEvents.size() > 0) {
                EventBus.publish(asrEvents);
            }

        Test.stopTest();
        List<PermissionSetAssignment> psaLst = [Select Id, AssigneeId, PermissionSetId, PermissionSet.Name From PermissionSetAssignment Where AssigneeId = :usersLst[0].Id];
        Boolean hasSpecialPermission = false;
        for(PermissionSetAssignment psa : psaLst) {
            if(psa.PermissionSet.Name.equalsIgnoreCase('Lead_360_Visibility')) {
                hasSpecialPermission = true;
                break;
            }
        }
        Assert.isTrue(hasSpecialPermission == true);
    }
    
}