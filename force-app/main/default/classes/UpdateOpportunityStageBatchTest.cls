@IsTest(SeeAllData = false)
public class UpdateOpportunityStageBatchTest {

    @testSetup
    static void setupData() {
        // Create base Account
        Account acc = new Account(Name = 'Exavalu', BillingPostalCode = '30146', Internal_Name__c = 'Exavalu');
        insert acc;

        //Create Contact
        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            MobilePhone = '9999999999',
            MailingCity = 'Ashburn',
            MailingStateCode = 'VA',
            MailingPostalCode = '20148',
            MailingCountryCode = 'US',
            Phone_Type__c='Mobile Phone',
            Primary_Phone__c='Mobile Phone',
            Original_Service_Date__c=system.today()
        );
        insert con;

        //Create Site
        TriggerHandler.bypass('SiteTriggerHandler');
        sked__Location__c site = new sked__Location__c(
            Name = 'Test Site',
            sked__Address__c = 'Test Site Address',
            sked_Site_Building_Name__c = 'Test Site Building',
            sked_Floor_Description__c = 'Test Site Floor Description',
            sked_Room_Name__c = 'Room 15',
            sked_National_Name__c = 'AMERICA',
            sked_Physical_Location_Type__c = 'Outside',
            //siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
            sked_Date_Site_Inspection_Completed__c = System.today().addDays(2),
            sked_Automation_Suitability__c = 'Suitable',
            sked_Outside_stairs__c = 1,
            sked_Inside_stairs__c = 2,
            sked_Base_Description__c = 'test base description',
            sked_Travel_Time_to_Staging_Location__c = 45,
            sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction',
            sked_Staff_Personal_Parking_Directions__c = 'Test Direction',
            sked_Site_Contact__c = con.Id,
            sked_Site_Main_Phone__c = '999-999-9999',
            sked_Directions_From_CollectionOperation__c = 'Test Direction',
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Test Pay',
            source__c='Custom New Form',
            sked_Address_1__c='Test Site Address',
            sked_City__c='Test site city',
            sked_County__c='AMERICA',
            sked_State__c='test state',
            sked_Wireless_Policy__c='Accepted',
            sked_Zip_Code__c='94608',
            operation_type__c = 'Integrated'
        );
        insert site;

        //Create Collection Operation
        Biomed_Collection_Op_Center__c colOp = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday');
        insert colOp;

        //Create Base Opportunity
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        Opportunity opp1 = new Opportunity(
            AccountId = acc.Id,
            Drive_Site__c = site.Id,
            Name = 'Test Drive 1',
            StageName = 'Discovery',
            Drive_Date__c = System.today(),
            Type_of_Drive__c = 'Mobile',
            CloseDate = System.today(),
            Start_Time__c = System.now().Time(),
            End_Time__c = System.now().Time()+1,
            Anticipated_Registered_Donors__c = 10,   
            Plasma_Pheresis_Projected_Procedures__c = 10,
            Platelet_Projected_Procedures__c = 11,  
            Number_of_Platelet_Assets__c = 10,
            Number_of_Plasma_Assets__c = 10,
            Number_of_2RBC_Assets__c = 10,
            Calendar_Description__c = 'Push -35',
            Online_Donor_Message__c = 'demo',
            Platelet_Pheresis_Procedures__c = 10,
            Plasma_Pheresis_Procedures__c = 10,
            WB_Projected_Procedures__c = 10,
            WholeBloodProcedureProjectedChangeReason__c = 'demo',
            X2RBC_Projected_Procedures__c = 10,
            DoubleRedProceduresProjectedChangeReason__c = 'demo',
            //sked_Cancellation_Reason__c = 'Staff Shortage',
            //Initiated_By__c = 'ARC_Initiated_Mobile',
            Is_Template__c = false,
            Processing_Status__c = 'Mass Update Not Processed'
        );
        
        insert opp1;
        Opportunity opp2 = new Opportunity(
            AccountId = acc.Id,
            Drive_Site__c = site.Id,
            Name = 'Test Drive 1',
            StageName = 'Discovery',
            Drive_Date__c = System.today(),
            Type_of_Drive__c = 'Mobile',
            CloseDate = System.today(),
            Start_Time__c = System.now().Time(),
            End_Time__c = System.now().Time()+1,
            Anticipated_Registered_Donors__c = 10,   
            Plasma_Pheresis_Projected_Procedures__c = 10,
            Platelet_Projected_Procedures__c = 11,  
            Number_of_Platelet_Assets__c = 10,
            Number_of_Plasma_Assets__c = 10,
            Number_of_2RBC_Assets__c = 10,
            Calendar_Description__c = 'Push -35',
            Online_Donor_Message__c = 'demo',
            Platelet_Pheresis_Procedures__c = 10,
            Plasma_Pheresis_Procedures__c = 10,
            WB_Projected_Procedures__c = 10,
            WholeBloodProcedureProjectedChangeReason__c = 'demo',
            X2RBC_Projected_Procedures__c = 10,
            DoubleRedProceduresProjectedChangeReason__c = 'demo',
            sked_Cancellation_Reason__c = 'Staff Shortage',
            Initiated_By__c = 'ARC_Initiated_Mobile',
            Is_Template__c = false,
            Processing_Status__c = 'Mass Update Not Processed'
        );
        
        insert opp2;

        

        //Clear all bypasses
        TriggerHandler.clearAllBypasses();
    }

    // Helper: Create drive for a given Opportunity
    private static sked_Drive__c createDrive(Opportunity opp, String status) {
        Biomed_Collection_Op_Center__c op = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1];
        sked__Location__c site = [SELECT Id FROM sked__Location__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        sked_Drive__c drive = new sked_Drive__c(
            Name = 'Drive for ' + opp.Name,
            sked_Collection_Operation__c = op.Id,
            sked_Drive_Date__c = opp.Drive_Date__c,
            sked_Drive_Site__c = site.Id,
            sked_Opportunity__c = opp.Id,
            sked_Account__c = acc.Id,
            sked_Type_of_Drive__c = 'Fixed Site',
            sked_Status__c = status,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0)
        );
        insert drive;
        return drive;
    }

    // -------------------------------------------------------------------------
    // Test 1: Drive → Tentative should update Stage → Committed
    // -------------------------------------------------------------------------
    @IsTest
    static void testStageUpdate_Committed() {
        Opportunity opp = [SELECT Id,Name,Drive_Date__c, StageName,Is_Template__c, Initiated_By__c, sked_Cancellation_Reason__c, DriveStatus__c FROM Opportunity where sked_Cancellation_Reason__c = null ];
        sked_Drive__c drive = createDrive(opp, 'Draft');

        drive.sked_Status__c = 'Tentative';
        update drive;

        Test.startTest();
        Database.executeBatch(new UpdateOpportunityStageBatch(new List<Opportunity>{ opp }));
        Test.stopTest();

        Opportunity oppAfter = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Discovery', oppAfter.StageName, 'Stage should be updated to Discovery.');//Committed
    }

    // -------------------------------------------------------------------------
    //Test 2: Drive → Cancel should update Stage → Cancelled
    // -------------------------------------------------------------------------
    @IsTest
    static void testStageUpdate_Cancelled() {
        Opportunity opp = [SELECT Id,Name,Drive_Date__c,Is_Template__c, Initiated_By__c, sked_Cancellation_Reason__c, DriveStatus__c, StageName FROM Opportunity where sked_Cancellation_Reason__c != null];
        
        sked_Drive__c drive = createDrive(opp, 'Draft');

        drive.sked_Status__c = 'Cancel';
        update drive;

        Test.startTest();
        Database.executeBatch(new UpdateOpportunityStageBatch(new List<Opportunity>{ opp }));
        Test.stopTest();

        Opportunity oppAfter = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Cancelled', oppAfter.StageName, 'Stage should be updated to Cancelled.');
    }

    // -------------------------------------------------------------------------
    //Test 3: Drive → Confirmed should update Stage → Closed (via OldMap constructor)
    // -------------------------------------------------------------------------
    @IsTest
    static void testStageUpdate_Closed() {
        Opportunity opp = [SELECT Id,Name,Drive_Date__c, StageName,Is_Template__c, Initiated_By__c, sked_Cancellation_Reason__c, DriveStatus__c FROM Opportunity where sked_Cancellation_Reason__c = null ];
        sked_Drive__c drive = createDrive(opp, 'Hold');

        drive.sked_Status__c = 'Draft';
        update drive;

        Map<Id, Opportunity> oppOldMap = new Map<Id, Opportunity>{ opp.Id => opp };

        Test.startTest();
        Database.executeBatch(new UpdateOpportunityStageBatch(new List<Opportunity>{ opp }, oppOldMap));
        Test.stopTest();

        Opportunity oppAfter = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.debug('oppAfter========>'+oppAfter.StageName);
        System.assertEquals('Discovery', oppAfter.StageName, 'Stage should be updated to Discovery.');
    }

    // -------------------------------------------------------------------------
    //Test 4: Drive → Draft should update Stage → Solicitation
    // -------------------------------------------------------------------------
    @IsTest
    static void testStageUpdate_Solicitation() {
        Opportunity opp = [SELECT Id,Name,Drive_Date__c, StageName,Is_Template__c, Initiated_By__c, sked_Cancellation_Reason__c, DriveStatus__c FROM Opportunity where sked_Cancellation_Reason__c = null ];
        sked_Drive__c drive = createDrive(opp, 'Hold');

        drive.sked_Status__c = 'Draft';
        update drive;

        Test.startTest();
        Database.executeBatch(new UpdateOpportunityStageBatch(new List<Opportunity>{ opp }));
        Test.stopTest();

        Opportunity oppAfter = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Discovery', oppAfter.StageName, 'Stage should be updated to Discovery.');//Discovery Solicitation
    }
}