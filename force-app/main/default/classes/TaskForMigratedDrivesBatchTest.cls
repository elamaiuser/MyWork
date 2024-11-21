@isTest
public class TaskForMigratedDrivesBatchTest {
	
    @isTest
    Public static void TaskForMigratedDrivesBatch(){
    	List<Opportunity> OppList=new List<Opportunity>();
        
        Account a=new Account();
        a.name='account TEST21';
        insert a;
        
        list<account> acclist=[select id,name from account where name='account TEST21']; 
        system.debug('acclist '+acclist);
        
        contact c=new contact();
        c.AccountId=a.Id;
        c.FirstName='contact122';
        c.Email='abcd32@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact322';
        c.Phone='7474749';
        insert c;
        
        list<contact> conlist=[select id,FirstName,LastName,Email from contact where FirstName='contact122'];
        system.debug('conlist '+conlist);
        
        User u=new User();
        u.LastName='user17223';
        u.FirstName='user23722';
        u.Username='john@acmeyer.com';
        u.Email='abdc@gmail3724.com';
        u.Alias='alia6s';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId='00eo0000000rmqFAAQ';
        u.LanguageLocaleKey ='en_US';
        insert u;
        
        list<user> userList=[select id, FirstName,LastName,Email from user where LastName='user1223'];
        system.debug('userList '+userList);
        
       
        sked__Location__c lc=new sked__Location__c();
        lc.sked_National_Name__c='national';
        lc.sked_Physical_Location_Type__c='inside';
        lc.sked_Site_Contact__c=c.Id;
        lc.sked_Site_Main_Phone__c='838-438-4367';
        lc.sked_Start_Date__c=system.today();
        lc.sked_End_Date__c=system.today()+1;
        lc.sked_Address_1__c='kolkata';
        lc.sked_City__c='kolkata';
        lc.sked_County__c='India';
        lc.sked_Zip_Code__c='70456';
        lc.sked_State__c='WB';
        lc.sked_Site_Inspection_Completed_By__c=u.Id;
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
            Name = 'Test Opportunity1',
        	StageName = 'Committed',
            Drive_Status__c='Tentative',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today()+120,
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
            Migration_ID__c='6436483',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp.AccountId = a.Id;
            mobileOpp.Drive_Site__c = lc.id;
			//insert mobileOpp; 
			OppList.add(mobileOpp); 
        
        
        Opportunity mobileOpp1 = new Opportunity(
            Name = 'Test Opportunity2',
        	StageName = 'Closed',
            Drive_Status__c='Confirmed',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today()+120,
        	CloseDate = System.today(),
            Migration_ID__c='865385',
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp1.AccountId = a.Id;
            mobileOpp1.Drive_Site__c = lc.id;
			//insert mobileOpp; 
			OppList.add(mobileOpp1); 
        
        
        Opportunity mobileOpp2 = new Opportunity(
            Name = 'Test Opportunity3',
        	StageName = 'Closed',
            Drive_Status__c='Confirmed',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today()+50,
        	CloseDate = System.today(),
            Migration_ID__c='8438473',
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp2.AccountId = a.Id;
            mobileOpp2.Drive_Site__c = lc.id;
			//insert mobileOpp; 
			OppList.add(mobileOpp2); 
       		 insert OppList;
        			
        			List<task> taskListInsert = new List<task>();
        			Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('72 Hour Check In').getRecordTypeId();
       				Task newTask = new task();
                    newTask.RecordTypeId = recTypeId;
                    newTask.subject ='72 Hour Check in - System Generated';
                    newTask.ActivityDate = Helper.AddBusinessDays(OppList[0].Drive_Date__c,-3);
                    newTask.WhatId = OppList[2].id;
                    //newTask.OwnerId = opp.Account_Manager__c != NULL ? opp.Account_Manager__c : opp.OwnerId;
                    taskListInsert.add(newTask);
        
      			   
       				Task newTask1 = new task();
                    newTask1.subject ='Sponsor Planning Meeting - System Generated';
                    newTask1.ActivityDate = Helper.AddBusinessDays(OppList[0].Drive_Date__c,-3);
                    newTask1.WhatId = OppList[0].id;
        			newTask1.Status = 'Not Started';
                    newTask1.Priority = 'Normal';
        			taskListInsert.add(newTask1);
        
        			 task recruitmentTask = new task();
                    recruitmentTask.RecordTypeId = recTypeId;
                    recruitmentTask.ActivityDate = Helper.AddBusinessDays(OppList[0].Drive_Date__c, -50);
                    recruitmentTask.subject = 'Recruitment Task - System Generated';
                    recruitmentTask.WhatId = OppList[1].id;
        			taskListInsert.add(recruitmentTask);
        			insert taskListInsert;
        
        list<opportunity> oppList1=[select id,Name, StageName from opportunity where Name='Test Opportunity3'];
        system.debug('oppList1 '+oppList1);
        
        
         List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        //atm.AccountAccessLevel = 'Read/Write';
        //atm.CaseAccessLevel = 'Read/Write';
        //atm.OpportunityAccessLevel = 'Read/Write';
        atm.userId = u.Id ;
        atm.AccountId = OppList[0].AccountId ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today().addDays(-10);
        atm.End_Date__c = System.today().addDays(6);
        atm.Is_Covering_Recruiter__c = true;
        atm.Coverage_Reason__c = 'Leave of Absence (LOA)';
        atmList.add(atm);
        
        try {
            system.debug('atmList done '+atmList);
            BSF_Constants.isTeamMemberCreatedFromBackend = false;
            insert atmList;
            system.debug('atmList done2 '+atmList);
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
       
        
        
         Test.startTest();
         TaskForMigratedDrivesBatch ba= new TaskForMigratedDrivesBatch();
         Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }     
}