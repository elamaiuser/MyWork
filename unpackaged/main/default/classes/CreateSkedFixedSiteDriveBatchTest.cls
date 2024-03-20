@isTest public class CreateSkedFixedSiteDriveBatchTest {
    @istest
    public static void testSkedFixedSiteBatch(){
        test.startTest();
        List<Opportunity> incomingOpportunities = new List<Opportunity>();
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        // Mobile Account
        Id MobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        Account mobileAcc = new Account(
            name = 'Test Account 1',
            RecordTypeId = MobileRecTypeId,
            District_Manager__c = UserInfo.getUserId(),
            BillingStreet = '2204 Westcrt ln, Apt 213', 
            BillingCity = 'Herndon',
            BillingStateCode = 'MI',
            BillingPostalCode = '48420'
        );
        insert mobileAcc;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',			
            sked_Maximum_Shift_Length_Threshold__c = 300,
            sked_Skip_Last_Appointment_For__c = 'Fixed Site',
            sked_Breakdown_Time_Threshold__c = 15,
            sked_Setup_Time_Threshold__c = 15,
            sked_Lunch_Break_Before_Draw_Hours__c = false,
            sked_Unpaid_Lunch_Break_Duration__c = 30,
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        // Mobile site
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId(),
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(1),
            sked_Floor_Description__c = 'Floor Description',
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
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
            sked_Timezone__c = 'America/New_York'
            ,Source__c = 'Custom New Form'
            ,sked_Address_1__c = 'ABC STREET'
            , sked_City__c = 'Test City'
            , sked_County__c = 'Test'
            , sked_State__c = 'PA'
            , sked_Zip_Code__c = '18411'
        );
        insert testLocation1;
        
        // template opp
        Opportunity templateOppNew = new Opportunity(
            Name='Test Parent opp',
            //RecordTypeId = MobileRecTypeId,
            AccountId = mobileAcc.Id, 
            is_template__c = true, 
            StageName = 'Discovery', 
            CloseDate = Date.today().addDays(6), 
            Procedure_Projections_Template__c = 25, 
            Projected_Registered_Donors_Template__c = 35,
            Staffing_Template__c = 45, 
            Volunteers_Template__c = 15, 
            WholeBloodProceduresProjectedTemplate__c = 55, 
            Double_Red_Procedures_Projected_Template__c = 35, 
            Anticipated_Registered_Donors_Template__c = 25, 
            Drive_Site__c = testLocation1.Id
        ); 
        incomingOpportunities.add(templateOppNew);
        insert incomingOpportunities;
           
        Id batchJobId = Database.executeBatch(new CreateSkedFixedSiteDriveBatch(incomingOpportunities),200);
        test.stopTest();
        
    }
    
}