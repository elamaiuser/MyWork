@isTest
private class BSF_BatchUpdateOpportunityForZipCodeTest {
    
    @isTest
    Public static void Test_Schedule_Class()
    {
        Test.StartTest();
		BSF_BatchUpdateOpportunitySchedule testsche = new BSF_BatchUpdateOpportunitySchedule(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    
    static testMethod void test(){
        Account a=new Account();
        a.name='account';
        insert a;
        
        contact c=new contact();
        c.AccountId=a.Id;
        c.FirstName='contact1';
        c.Email='abcd@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact2';
        c.Phone='7474749';
        insert c;
        
        User u=new User();
        u.LastName='user123';
        u.FirstName='user222';
        u.Username='john@acme5.com';
        u.Email='abc@gmail34.com';
        u.Alias='alias';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId='00eo0000000rmqFAAQ';
        u.LanguageLocaleKey ='en_US';
        insert u;
            
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
        
        Biomed_Collection_Op_Center__c collectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            sked_Maximum_Shift_Length_Threshold__c = 480
        );
        	insert collectionOperation;
        
        
         sked__Region__c region = new sked__Region__c(Name = 'Region 1',sked__Timezone__c = U.Id);
      
            region.sked_Biomed_Collection_Op_Center__c = collectionOperation.Id;
			insert region;	
        
       Collections_Region__c donorServicesRegion = new Collections_Region__c(name = 'Test Donor Services Region' );
       
            insert donorServicesRegion;
        
        Collections_Territory__c regionTerritory = new Collections_Territory__c(Name = 'Test Territory',Zip__c = '27560',BDM__c = u.id);
       
            regionTerritory.Region__c = donorServicesRegion.Id;
            insert regionTerritory;
        
        sked_Site_Collection_Operation__c sc=new sked_Site_Collection_Operation__c();
        //sc.name='new site';
        sc.sked_Collections_Zip_Code__c=regionTerritory.Id;
        sc.sked_Start_Date__c=system.today();
        sc.sked_End_Date__c=system.today()+1;
        sc.sked_Site__c=lc.Id;
        insert sc;
        
       
        
        Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp.AccountId = a.Id;
            mobileOpp.Drive_Site__c = lc.id;
			insert mobileOpp;  
        
        
         OpportunityContactRole ocr=new OpportunityContactRole();
         ocr.OpportunityId=mobileOpp.Id;
         ocr.ContactId=c.id;
         ocr.Role='Primary Contact';
         insert ocr;
        
        
        
         Test.startTest();
        system.debug('hhhhhh');
        List<Opportunity> OpList=[SELECT Id, Name,StageName,(SELECT Contact.Name,OpportunityId,Contact.Email,Role,Contact.Id,ContactId FROM OpportunityContactRoles) FROM Opportunity where Id =:mobileOpp.Id];
        system.debug('OpList*'+OpList);
       
        BSF_BatchUpdateOpportunityForZipCode ba= new BSF_BatchUpdateOpportunityForZipCode();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
        
        
        
    }
}