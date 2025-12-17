/* Description : This test class covers UserCollOpQueAssngmentReportController 
 * Current Test Coverage : 85%
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *********************************************************************************************
 * 11/08/2024				  Priti Jana				Updated to increase code coverage
 ***********************************************************************************************
*/

@isTest
public class UserCollOpQueAssngmentReport_Test 
{
	@testSetup
    public static void testSetup()
    {
        
        Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+'District'+'_'+44+'_'+system.today();
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+'District'+'_'+44;
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
        
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c ='BSF_Co_005';
        co.Collection_Operation_ID__c='CoKey';
        co.Name='Columbus OH Franklin';
        co.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        co.sked_Territory__c=territory.id;
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
         insert co;
        
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
            isActive=true
             
        );
        
        insert AdminUser;
        
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'testingLastDRD',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
            sked_Collection_Operations__c='Columbus OH Franklin',
             //UserRoleId = urole.Id
             isActive=true
        );       
        
       System.runAs(AdminUser){
            insert DRDAMUser;
       }   
    }
    
    @isTest
    public static void testReportController() {
        Test.startTest();
        
        user u =[select id,Name,sked_Collection_Operations__c from user WHERE LastName = 'testingLastDRD' AND Profile.Name = 'DRD Profile' Limit 1];
        user AdminUser=[select id,Name,sked_Collection_Operations__c from user where LastName = 'last' AND profile.name='System Administrator' Limit 1];

        Group objGroup = new Group(Name = 'TestGroup1', Type='Queue',DeveloperName='Test_Group1');
        insert objGroup;
        
        QueueSObject q = new QueueSObject(SobjectType='Lead', QueueId=objGroup.Id);
		insert q;

        groupmember grpMem = new groupMember();
        grpMem.GroupId =objGroup.id;
        grpMem.userorGroupId=AdminUser.id;
        
        system.runAs(AdminUser) {
         	insert grpMem;
        }
        
        UserCollOpQueAssngmentReportController reportController = new UserCollOpQueAssngmentReportController();
        reportController.searchUser=AdminUser.Name;
        reportController.searchCollOpp=AdminUser.sked_Collection_Operations__c;
        
        reportController.search();
        reportController.clear();
        reportController.searchUser = u.Name;
        reportController.searchCollOpp = u.sked_Collection_Operations__c;
        
        reportController.search();
  
        UserCollOpQueAssngmentReportController.getRoleSubordinateUsers(u.Id);
        UserCollOpQueAssngmentReportController.UserCollOpQueWrapper wrapperData = new UserCollOpQueAssngmentReportController.UserCollOpQueWrapper(
        	u,
        	1,
        	1,
        	'Test'
        );
        wrapperData.isSelected = true;
        wrapperData.grpMembers = grpMem;

        reportController.UserCollOpQueWrapList = new List<UserCollOpQueAssngmentReportController.UserCollOpQueWrapper>{wrapperData};
        
        reportController.selectedRecords();
        reportController.ExportToExcel();
        
        Test.stopTest(); 	    
    }
}