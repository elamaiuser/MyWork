@isTest
public class NewFixedSiteDriveTest {
    @istest
    public static void createOpps(){
        
         List<Opportunity> opplist = new List<Opportunity>();
        Account accobj;        
        accobj = new Account();
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';  
        insert accobj;
        
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Main_Phone__c = '999-999-9999';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        insert siteObj;
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = accobj.Id;
        opp1.Drive_Site__c = siteObj.Id;
        opp1.Name = 'Test Drive';
        opp1.StageName = 'Discovery';
        opp1.Drive_Status__c='Confirmed';
        opp1.Drive_Date__c = System.today();
        opp1.Type_of_Drive__c = 'Mobile';
        opp1.CloseDate = System.today();
        opp1.Start_Time__c = System.now().Time();
        opp1.End_Time__c = System.now().Time()+1;
        opp1.Anticipated_Registered_Donors__c = 10;   
        opp1.Plasma_Pheresis_Projected_Procedures__c = 10;
        opp1.Platelet_Projected_Procedures__c = 11;   
        opp1.Number_of_Platelet_Assets__c = 10;
        opp1.Number_of_Plasma_Assets__c = 10;
        opp1.Number_of_2RBC_Assets__c = 10;
        opp1.Online_Donor_Message__c = 'demo';
        opp1.Platelet_Pheresis_Procedures__c = 10;
        opp1.Plasma_Pheresis_Procedures__c = 10;
        opp1.WB_Projected_Procedures__c = 10;
        opp1.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp1.X2RBC_Projected_Procedures__c = 10;
        opp1.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        opplist.add(opp1);  
        
        Opportunity opp2 = new Opportunity();
        opp2.AccountId = accobj.Id;
        opp2.Drive_Site__c = siteObj.Id;
        opp2.Name = 'Test Drive';
        opp2.StageName = 'Cancelled';
        opp2.Drive_Status__c='Confirmed';
        opp2.Drive_Date__c = System.today();
        opp2.Type_of_Drive__c = 'Mobile';
        opp2.CloseDate = System.today();
        opp2.Start_Time__c = System.now().Time();
        opp2.End_Time__c = System.now().Time()+1;
        opp2.Anticipated_Registered_Donors__c = 10;   
        opp2.Plasma_Pheresis_Projected_Procedures__c = 40;
        opp2.Platelet_Projected_Procedures__c = 40;   
        opp2.Number_of_Platelet_Assets__c = 40;
        opp2.Number_of_Plasma_Assets__c = 40;
        opp2.Number_of_2RBC_Assets__c = 40;
        opp2.Online_Donor_Message__c = 'demo';
        opp2.Platelet_Pheresis_Procedures__c = 40;
        opp2.Plasma_Pheresis_Procedures__c = 40;
        opp2.WB_Projected_Procedures__c = 40;
        opp2.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp2.X2RBC_Projected_Procedures__c = 40;
        opp2.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        opp2.sked_Cancellation_Reason__c = 'Staff Shortage';
        opp2.Initiated_By__c = 'ARC_Initiated_Mobile';
        opplist.add(opp2);        
        insert opplist; 
        
         List<NewFixedSiteDrive.fixedOpps> oppWrapper = new List<NewFixedSiteDrive.fixedOpps>();
        NewFixedSiteDrive.fixedOpps opWrap1 = new NewFixedSiteDrive.fixedOpps();
        
        opWrap1.oppsToCreate = opplist;
        oppWrapper.add(opWrap1);  
        Test.startTest();
        NewFixedSiteDrive.createDrives(oppWrapper);
        Test.stopTest();
    }   
}