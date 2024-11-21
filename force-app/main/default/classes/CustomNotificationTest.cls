@isTest public class CustomNotificationTest {
    @isTest static void notifyUsersTest(){
        
            Account acc = new Account(
                Name = 'Test Account',
                District_Manager__c = UserInfo.getUserId(),
                APT_Required__c = FALSE
            );
            insert acc;
            
            sked__Location__c site = new sked__Location__c(
                Name = 'Test Location 1',
                sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
                sked_Address_1__c = 'Inner Parkside', 
                sked_City__c = 'San Francisco', 
                sked_State__c = 'CA', 
                sked_Zip_Code__c = '94116', 
                sked_County__c = 'USA',
                sked__GeoLocation__Latitude__s = 37.7450046,
                sked__GeoLocation__Longitude__s = -122.4816244,
                sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
                sked_Automation_Suitability__c = 'Suitable',
                sked_Base_Description__c = 'Base Description',
                sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
                sked_Floor_Description__c = 'Floor Description',
                sked_National_Name__c = 'USA',
                sked_Outside_stairs__c = 3,
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
                Source__c = 'Custom New Form'
            );
            insert site;
            
            Opportunity opp = new Opportunity(
                Name = 'Test',
                AccountId = acc.Id,
                Drive_Date__c = Date.newInstance(2022, 10, 10),
                Drive_Site__c = site.Id,
                StageName = 'Solicitation',
                CloseDate = Date.newInstance(2022, 08, 10),
                Online_Scheduling_Enabled__c = 'No'
            );
            insert opp;

            Test.startTest();
            CustomNotification.notifyUsers(new Set <String>{userInfo.getUserId()} , opp.Id , 'Error!' , 'Error message' );
            Test.stopTest();       
    }
}