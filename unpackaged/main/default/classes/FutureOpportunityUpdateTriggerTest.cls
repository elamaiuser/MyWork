/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 *  10/02/2024				 Kishore Das		        Test class for the class FutureOpportunityUpdateTrigger

 *************************************************************************************************************************************************************************************
*/

@isTest
private class FutureOpportunityUpdateTriggerTest {
    
    @isTest
    static void testFutureOpportunityUpdateTrigger() {
        
        Account testAccount = new Account(Name = 'Test Account', Sponsor_Keyword__c = 'Test Keyword');
        insert testAccount;
        
        Opportunity templateOpportunity = new Opportunity(
            Name = 'Template Opportunity',
            AccountId = testAccount.Id,
            Template_Status__c = 'Active',
            Is_Template__C = true,
            Drive_Keyword__c = 'Test Keyword',
            StageName='Draft',
            CloseDate=system.today()
        );
        insert templateOpportunity;
        
        contact c=new contact();
        c.AccountId=testAccount.Id;
        c.FirstName='contact12';
        c.Email='abcde@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact22';
        c.Phone='74747492';
        insert c;
        
        sked__Location__c lc=new sked__Location__c();
        lc.sked_National_Name__c='national';
        lc.sked_Physical_Location_Type__c='inside';
        lc.sked_Site_Contact__c=c.Id;
        lc.sked_Site_Main_Phone__c='838-438-4367';
        lc.sked_Start_Date__c=system.today();
        lc.sked_End_Date__c=system.today()+8;
        lc.sked_Address_1__c='kolkata';
        lc.sked_City__c='kolkata';
        lc.sked_County__c='India';
        lc.sked_Zip_Code__c='70456';
        lc.sked_State__c='WB';
        //lc.sked_Site_Inspection_Completed_By__c=u.Id;
        lc.sked_Site_Building_Name__c='new site building';
        lc.sked_Floor_Description__c='desc';
        lc.sked_Room_Name__c='room name';
        lc.sked_Room_Size__c='Bus';
        lc.sked_Automation_Suitability__c='Suitable';
        lc.sked_Wireless_Policy__c='Accepted';
        lc.sked_Outside_stairs__c=3;
        lc.sked_Base_Description__c='base desc';
        lc.sked_Directions_From_CollectionOperation__c='sked_Directions_From_CollectionOperation__c';
        lc.sked_ARC_Vehicle_Parking_Directions__c='sked_ARC_Vehicle_Parking_Directions__c';
        lc.sked_Staff_Personal_Parking_Directions__c='sked_Staff_Personal_Parking_Directions__c';
        lc.Source__c = 'Custom New Form';
        lc.Name='site name';
        insert lc;
        
        Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Withdrawn',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today()+5,
        	CloseDate = System.today()+8,
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
            Drive_Keyword__c='Initial Keyword',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
            Parent_Template_Id__c=templateOpportunity.id,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp.AccountId = testAccount.Id;
            mobileOpp.Drive_Site__c = lc.id;
			insert mobileOpp;
        
        Test.startTest();
        FutureOpportunityUpdate__e event = new FutureOpportunityUpdate__e(
            TemplateIds__c = String.valueOf(templateOpportunity.Id)
        );
        Database.SaveResult eventResult = EventBus.publish(event);
        Test.stopTest();
        
        List<Opportunity> opp=[SELECT Drive_Keyword__c FROM Opportunity WHERE Parent_Template_Id__c = :templateOpportunity.Id];
        assert.areequal(templateOpportunity.Drive_Keyword__c, opp[0].Drive_Keyword__c, 'The Drive_Keyword__c should be updated to match the template');
        
    }
}