@isTest
public class UpdateDriveShiftProjectedProcTest {

    @istest
    public static void updateDriveShiftForFixedSiteDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
     
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
                
        List<sked_Drive__c> fixedSiteDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:fixOpportunity.Id];
        Assert.areEqual(1, fixedSiteDriveCreated.size()); // NEW Assert Class
        
        Set<Id> docId = new Set<Id>();        
        for(sked_Drive__c doc : fixedSiteDriveCreated) {
            docId.add(doc.Id);
        } 
        
        List<sked_Drive__c> driveList = [SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c,
        sked_Platelet_Rounds__c, sked_WB_Projected_Procedures__c, 
        sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
        sked_2RBC_Projected_Procedures__c, sked_Drive_Shift_Count__c,
        sked_Start_Time__c, sked_End_Time__c,sked_Drive_Date__c,
        (
            SELECT Id, Name, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c
            FROM sked_Drive_Shifts__r ORDER BY Name
        ) 
        FROM sked_Drive__c
        WHERE Id IN: docId];
        
        
        
        List<sked_Drive_Shift__c> driveshiftList = [select Id, sked_Drive__c, Name, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c from sked_Drive_Shift__c where sked_Drive__c IN : docId];
        for(sked_Drive_Shift__c driveShift : driveshiftList){
            driveShift.sked_WB_Projected_Procedures__c = 2;
            driveShift.sked_2RBC_Projected_Procedures__c = 2;
            driveShift.sked_Total_Procedures_Projected__c = 2;
            driveShift.sked_Total_Products_Projected__c = 2;
            driveShift.sked_Platelet_Projected_Procedures__c = 2;
            driveShift.sked_Plasma_Projected_Procedures__c = 2;
        }
        update driveshiftList;
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        
        Date date1 = driveList[0].sked_Drive_Date__c;
        Date date2 = driveList[0].sked_Drive_Date__c;
        String typeOfDrive = 'Fixed Site';
        Boolean driveShiftUpdate = true;
        Boolean onlyTotalProcedureUpdate = false;

        UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
    
    @istest
    public static void updateDriveShiftForMobileDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        Test.startTest();
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        GenerateMobileDrive.generateDrives(config);
        
        List<sked_Drive__c> driveList = [SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c,
        sked_Platelet_Rounds__c, sked_WB_Projected_Procedures__c, 
        sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
        sked_2RBC_Projected_Procedures__c, sked_Drive_Shift_Count__c,
        sked_Start_Time__c, sked_End_Time__c,sked_Drive_Date__c,
        (
            SELECT Id, Name, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c
            FROM sked_Drive_Shifts__r ORDER BY Name
        ) 
        FROM sked_Drive__c
        WHERE sked_Opportunity__c IN: config.oppIds];
        
        
        
        List<sked_Drive_Shift__c> driveshiftList = [select Id, sked_Drive__c, Name, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c from sked_Drive_Shift__c where sked_Drive__r.sked_Opportunity__c IN : config.oppIds];
        for(sked_Drive_Shift__c driveShift : driveshiftList){
            driveShift.sked_WB_Projected_Procedures__c = 2;
            driveShift.sked_2RBC_Projected_Procedures__c = 2;
            driveShift.sked_Total_Procedures_Projected__c = 2;
            driveShift.sked_Total_Products_Projected__c = 2;
        }
        update driveshiftList;
        Date date1 = driveList[0].sked_Drive_Date__c;
        Date date2 = driveList[0].sked_Drive_Date__c;
        String typeOfDrive = 'Mobile';
        Boolean driveShiftUpdate = true;
        Boolean onlyTotalProcedureUpdate = false;

        UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
        Database.executeBatch(batchObject,100);
        
        Test.stopTest();
    }
    
    @istest
    public static void updateDriveShiftTotalProjectedAndTotalProductForFixedSiteDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
     
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
                
        List<sked_Drive__c> fixedSiteDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:fixOpportunity.Id];
        Assert.areEqual(1, fixedSiteDriveCreated.size()); // NEW Assert Class
        
        Set<Id> docId = new Set<Id>();        
        for(sked_Drive__c doc : fixedSiteDriveCreated) {
            docId.add(doc.Id);
        } 
        
        List<sked_Drive__c> driveList = [SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c,
        sked_Platelet_Rounds__c, sked_WB_Projected_Procedures__c, 
        sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
        sked_2RBC_Projected_Procedures__c, sked_Drive_Shift_Count__c,
        sked_Start_Time__c, sked_End_Time__c,sked_Drive_Date__c,
        (
            SELECT Id, Name, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c
            FROM sked_Drive_Shifts__r ORDER BY Name
        ) 
        FROM sked_Drive__c
        WHERE Id IN: docId];
        
        
        
        List<sked_Drive_Shift__c> driveshiftList = [select Id, sked_Drive__c, Name, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c from sked_Drive_Shift__c where sked_Drive__c IN : docId];
        for(sked_Drive_Shift__c driveShift : driveshiftList){
            driveShift.sked_WB_Projected_Procedures__c = 2;
            driveShift.sked_2RBC_Projected_Procedures__c = 2;
            driveShift.sked_Total_Procedures_Projected__c = 2;
            driveShift.sked_Total_Products_Projected__c = 2;
            driveShift.sked_Platelet_Projected_Procedures__c = 2;
            driveShift.sked_Plasma_Projected_Procedures__c = 2;
        }
        update driveshiftList;
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        
        Date date1 = driveList[0].sked_Drive_Date__c;
        Date date2 = driveList[0].sked_Drive_Date__c;
        String typeOfDrive = 'Fixed Site';
        Boolean driveShiftUpdate = false;
        Boolean onlyTotalProcedureUpdate = true;

        UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
    
    @istest
    public static void updateDriveTotalProjectedAndTotalProductForFixedSiteDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
     
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
                
        List<sked_Drive__c> fixedSiteDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:fixOpportunity.Id];
        Assert.areEqual(1, fixedSiteDriveCreated.size()); // NEW Assert Class
        
        Set<Id> docId = new Set<Id>();        
        for(sked_Drive__c doc : fixedSiteDriveCreated) {
            docId.add(doc.Id);
        } 
        
        List<sked_Drive__c> driveList = [SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c,
        sked_Platelet_Rounds__c, sked_WB_Projected_Procedures__c, 
        sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
        sked_2RBC_Projected_Procedures__c, sked_Drive_Shift_Count__c,
        sked_Start_Time__c, sked_End_Time__c,sked_Drive_Date__c, sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c
        FROM sked_Drive__c
        WHERE Id IN: docId];
        driveList[0].sked_Total_Procedures_Projected__c = 20;
        driveList[0].sked_Total_Products_Projected__c = 20;
        update driveList;
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        
        Date date1 = driveList[0].sked_Drive_Date__c;
        Date date2 = driveList[0].sked_Drive_Date__c;
        String typeOfDrive = 'Fixed Site';
        Boolean driveShiftUpdate = false;
        Boolean onlyTotalProcedureUpdate = false;
        Boolean onlyTotalProcedureUpdateForDrive = true;

        UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate, onlyTotalProcedureUpdateForDrive);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
}