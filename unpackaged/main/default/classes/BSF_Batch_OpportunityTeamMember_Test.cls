@isTest
public class BSF_Batch_OpportunityTeamMember_Test 
{
    @isTest
    public static void Test_Method()
    {
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' ,
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
            isActive = true
             
        );
        list<user> userList = new list<user>();
        Id PrflId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id;
        
        for(integer i=0;i<=5;i++)
        {
            User u = new User(
                ProfileId = PrflId ,
                LastName = 'last'+i,
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama'+i+'.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                isActive=true
                //userType='Salesforce'
            );
            userList.add(u);
        }
        System.runAs( AdminUser )
        {
            insert userList;
        }
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Map <String,Schema.RecordTypeInfo> recordTypesSite = sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id MobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        Account acc = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            District_Manager__c = UserInfo.getUserId(),
        	BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        
        insert acc;
        
         sked__Location__c mobSite = new sked__Location__c(
            Name = 'Test Mobile Location',
            RecordTypeId=  recordTypesSite.get('Mobile Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
        );
        
        insert mobSite;
        
        
        Opportunity opp = new Opportunity(
			Name = 'Test Fixed Opportunity',
        	StageName = 'Draft',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
        	End_Time__c=Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
            AccountID = acc.Id,
            Drive_Site__c = mobSite.id
		);
       insert opp;
        
        list<OpportunityTeamMember> otmList = new list<OpportunityTeamMember>();
        list<OpportunityTeamMember> otmList1 = new list<OpportunityTeamMember>();
        for(user u : [select id,isActive from user where ProfileId = :PrflId])
        {
            if(u.isActive)
            {
            OpportunityTeamMember otm= new OpportunityTeamMember(UserId=u.id,
                                                                 Start_Date__c=system.today(),
                                                                 OpportunityAccessLevel='Edit',
                                                                 OpportunityId=opp.id);
            if(otmList.size()<=3){otmList.add(otm);}
            else{otmList1.add(otm);}
            }
         }
        System.runAs( AdminUser )
        {
        insert otmList;
        }
        
        test.startTest();
        BSF_Batch_OpportunityTeamMember batch = new BSF_Batch_OpportunityTeamMember(otmList,otmList1,'Delete',false,0);
        Database.executeBatch(batch);
        test.stopTest();
    }
}