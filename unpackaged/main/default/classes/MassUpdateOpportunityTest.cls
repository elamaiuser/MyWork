@isTest
public class MassUpdateOpportunityTest {
    @istest
    public static void updateOpps(){  
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
        opp1.Calendar_Description__c = 'Push -35';
        opp1.Online_Donor_Message__c = 'demo';
        opp1.Platelet_Pheresis_Procedures__c = 10;
        opp1.Plasma_Pheresis_Procedures__c = 10;
        opp1.WB_Projected_Procedures__c = 10;
        opp1.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp1.X2RBC_Projected_Procedures__c = 10;
        opp1.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        opp1.Processing_Status__c = 'Mass Update Not Processed';
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
        opp2.Calendar_Description__c = 'Push -35';
        opp2.Online_Donor_Message__c = 'demo';
        opp2.Platelet_Pheresis_Procedures__c = 40;
        opp2.Plasma_Pheresis_Procedures__c = 40;
        opp2.WB_Projected_Procedures__c = 40;
        opp2.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp2.X2RBC_Projected_Procedures__c = 40;
        opp2.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        opp2.sked_Cancellation_Reason__c = 'Staff Shortage';
        opp2.Initiated_By__c = 'ARC_Initiated_Mobile';
        opp2.Processing_Status__c = 'Mass Update Not Processed';     
        opplist.add(opp2); 
        
        insert opplist; 
        
        List<MassUpdateOpportunity.oppVariable> oppWrapper = new List<MassUpdateOpportunity.oppVariable>();
        MassUpdateOpportunity.oppVariable opWrap = new MassUpdateOpportunity.oppVariable();
        opWrap.oppToUpdate = opplist;
        opWrap.updatedPlateletAsset = 20;
        opWrap.updatedPlasmaAsset = 20;
        opWrap.updated2rbcAsset = 20;       
        opWrap.updatedCalendarDesc = 'Push +35';
        opWrap.updatedOnlineDonor = 'test';
        opWrap.updatedOpenToPublic = 'Yes';
        opWrap.updatedStage = 'Cancelled';
        opWrap.updatedPlateletPP = 20;
        opWrap.updatedPlasmaPheresisPP = 20;
        opWrap.updatedWBProjectedProc = 20;
        opWrap.updatedDRReason = 'test';
        opWrap.updatedWBProcReason = 'test';
        opWrap.updated2RBCProjProcedure = 20;
        opWrap.updatedStartTime = '0300';
        opWrap.updatedEndTime = '0830';
        opWrap.updatedCancelledStage = 'Cancelled';
        opWrap.updatedCancellationReason ='Staff Call-Out';
        opWrap.updatedProcessingStatus = 'Mass Update Processed';
        oppWrapper.add(opWrap);    
        
        List<MassUpdateOpportunity.oppVariable> oppWrapper1 = new List<MassUpdateOpportunity.oppVariable>();
        MassUpdateOpportunity.oppVariable opWrap1 = new MassUpdateOpportunity.oppVariable();
        
        opWrap1.oppToUpdate = opplist;
        opWrap1.updatedPlateletAsset = 20;
        opWrap1.updatedPlasmaAsset = 20;
        opWrap1.updated2rbcAsset = 20;       
        opWrap1.updatedCalendarDesc = 'Push +35';
        opWrap1.updatedOnlineDonor = 'test';
        opWrap1.updatedOpenToPublic = 'Yes';
        opWrap1.updatedStage = 'Committed';
        opWrap1.updatedPlateletPP = 20;
        opWrap1.updatedPlasmaPheresisPP = 20;
        opWrap1.updatedWBProjectedProc = 20;
        opWrap1.updatedAnticipatedRegisteredDonors= 20;
        opWrap1.updatedDRReason = 'test';
        opWrap1.updatedWBProcReason = 'test';
        opWrap1.updated2RBCProjProcedure = 20;
        opWrap1.updatedStartTime = '0300';
        opWrap1.updatedEndTime = '0830';
        opWrap1.updatedCancelledStage = 'Cancelled';
        opWrap1.updatedProcessingStatus = 'Mass Update Processed';
        oppWrapper1.add(opWrap1);  
        Test.startTest();
        MassUpdateOpportunity.updateSelectedRecords(oppWrapper);
        MassUpdateOpportunity.updateSelectedRecords(oppWrapper1);
        //List<String> driveStatusList = new List
        Map<String, Object> filterWrapper = new Map<String, Object> {
            'accountId' => accobj.Id,
            'driveName' => 'Test Drive',
            'sortBy' => 'Drive_Date__c',
            'sortDirection' => 'DESC',
            'recordLimit' => 1,
            'rowOffset' => 0,
            'driveStatus' => new List<String>{'Draft'},
            'dayOfDrive' => new List<String>{'SUN'},
            'siteOperationType' => new List<String>{'Integrated'},
            'driveDateStart' => String.valueOf(System.today()),
            'driveDateEnd' => String.valueOf(System.today())  
        };
        List<Opportunity> oppListToFilter = MassUpdateOpportunity.getFilteredOpportunities(filterWrapper);
        Assert.areEqual(0, oppListToFilter.size());
        Test.stopTest();
    }
}