/**
* @description: This class is the controller class for generateDriveWorksheetPdf visualforce page.
**   Modification Log  ****
*  Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 05/23/2023			Barnojit Sharma			Fixed Staff Start & End time on Drive Worksheet in sync with job allocation record (HRP-10127)
 * 06/09/2023			Barnojit Sharma			New Employee Table time calculation introduced in Drive Worksheet Report (Logic for HRP-10259)
 * 05/25/2023			Barnojit Sharma			Populate Site Smoking Policy Field in Drive Worksheet Report (Logic for HRP-10052)
 * 06/30/2023			Barnojit Sharma			Setup and Breakdown times will depend solely on shift start and end times in the employee table for a particular shift (Logic for HRP-10418)
 * 09/13/2023			Barnojit Sharma			Rectify incorrect Minutes values in operational information section (Logic for HRP-10893)
 * 09/14/2023			Barnojit Sharma			Add Dual and Additional Roles in Employee table on the Drive Worksheet(Logic for HRP-10711)
 * 10/26/2023			Barnojit Sharma			Add Military Fields & Additional Drive Logistics to the Drive Worksheet(Logic for HRP-9954)
 * 11/28/2023			Barnojit Sharma			Drive Worksheet has the Incorrect Account and Site ID populated(Logic for HRP-11561)
 * 01/02/2024			Barnojit Sharma			Drive Worksheet is not populating the Account Manager field(Logic for HRP-11777)
 * 14/03/2024			Kishore Das				Logic for HRP-12306 (Deleted Vehicle Jobs Reflecting on the Drive Worksheet)
 * 10/04/2024			Barnojit Sharma			New Lookup field on Site to Lookup to Chapter and limit the chapter name to 57 charecters.(Logic for HRP-12045)
 * 04/30/2024			Venkat					HRP-12505 - Pull account Manager from Opportunity
 * 07/16/2024			Apurba Bhattacharjee	HRP-12166 - Add Dropdown for EAP Map Available and AED Dropdown to Site/Details/Security and Drive Worksheet-Additional Site Information.
 *****************************************************************************************************************************************************************************
*/
public without sharing class GenerateDriveWorksheetPdfController {
    public List<ReportWrapper> shiftDataWrap {get; set;}
    public Boolean redirectToSearch {get; set;}

    public class ReportWrapper{
        public String driveName {get; set;}
        public Boolean isFixedSite { get; set; }
        public OprationalInformation oppInfo {get; set;}
        public List<DriveJobInformation> jobInfoList {get; set;}
        public DriveShiftInformation shiftInfo {get; set;}
        public SiteInformation siteInfo {get; set;}
        public List<EmployeeTableInformation> empInfoList {get; set;}
        public List<FutureDriveInformation> fdriveInfoList {get; set;}
        public OperationalNotes notes {get; set;}
    }
    public class OprationalInformation{
        public String accountName {get; set;}
        public String accountManager {get; set;}
        public String phone {get; set;}
        public String driveDate {get; set;}
        public String drawStart {get; set;}
        public String drawEnd {get; set;}
        public String driveId {get; set;}
        public String accId {get; set;}
        public String siteId {get; set;}
        public String opentoPublic {get; set;}
        public String wirelessPolicy {get; set;}
        public String setup {get; set;}
        public String breakDown {get; set;}
        public String minutes {get; set;}
        public String wBEligibility {get; set;}
        public String twoRBCEligibility {get; set;}
        public String volunteersReqAccount {get; set;}
        public String volunteersReqCenter {get; set;}
        public String vehicle {get; set;}
        public String report {get; set;}
        public String militaryAuName {get; set;}//added for HRP-9954
        public String militaryAuNo {get; set;}//added for HRP-9954
        public String AddiLogistics {get; set;}//added for HRP-9954
        public String AddiLogisticsOther {get; set;}//added for HRP-9954
    }
    public class DriveJobInformation{
        public String num {get; set;}
        public String jobType {get; set;}
        public String pickupTime {get; set;}
        public String deliveryID {get; set;}
        public String bagDetails {get; set;}
        public String driveComments {get; set;}
    }
    public class DriveShiftInformation{
        public String shift {get; set;}
        public String presentingDonorCapacity {get; set;}
        public String typeRBC {get; set;}
        public String typeWB {get; set;}
        public String procedureRBC {get; set;}
        public String procedureWB {get; set;}
        public String productRBC {get; set;}
        public String productWB {get; set;}
        public String totalProcedure {get; set;}
        public String totalProduct {get; set;}
        public String staffReq {get; set;}
        public String autoMac {get; set;}
        public String lunchBreakRed {get; set;}
    }
    public class SiteInformation{
        public String siteBuilding {get; set;}
        public String room {get; set;}
        public String floor {get; set;}
        public String siteAddress {get; set;}
        public String sitePhone {get; set;}
        public String meetWith {get; set;}
        public String siteContact {get; set;}
        public String priChair {get; set;}
        public String phone {get; set;}
        public String mobile {get; set;}
        public String insideStairs {get; set;}
        public String outsideStairs {get; set;}
        public String airCondition {get; set;}
        public String heated {get; set;}
        public String elevator {get; set;}
        public String chapter {get; set;}
        public String directions {get; set;}
        public String escortRequired {get; set;}
        public String escortName {get; set;}
        public String equipmentXRay {get; set;}
        public String noCellPhones {get; set;}
        public String canteenReq {get; set;}
        public String canteenCond {get; set;}
        public String securityDir {get; set;}
        public String sponsorSecReq {get; set;}
        public String safetyEmgActPlan {get; set;}
        public String securityInfNeeded {get; set;}
        public String staffListNeeded {get; set;}
        public String restroomLocation {get; set;}
        public String floorCoveringReq {get; set;}
        public String arcVehParkingDir {get; set;}
        public String staffPerParkingDir {get; set;}
        public String payforParking {get; set;}
        public String unloadingCond {get; set;}
        public String unloadingDir {get; set;}
        public String onSiteFoodReq {get; set;}
        public String siteSmkPolicy {get; set;}  
        public String siteEAPMapAvailable {get; set;}  //HRP-12166
        public String siteAEDAvailable {get; set;}  //HRP-12166
    }
    public class EmployeeTableInformation{
        public String num {get; set;}
        public String employeeName {get; set;}
        public String role {get; set;}
        public String eBDRID {get; set;}
        public String lead {get; set;}
        public String leave {get; set;}
        public String setup {get; set;}
        public String breakDown {get; set;}
        public String returnTime {get; set;}
        public String wrapup {get; set;}
    }
    public class FutureDriveInformation{
        public String num {get; set;}
        public String driveName {get; set;}
        public String driveDate {get; set;}
        public String driveAccount {get; set;}
    }
    public class OperationalNotes{
        public String opNotes {get; set;}
    }

    


    public GenerateDriveWorksheetPdfController(){
        redirectToSearch = true;
        String pageName = ApexPages.currentPage().getUrl().substringAfter('apex/').split('\\?')[0];
        System.debug('pageName : '+pageName);
        String driveId = Apexpages.currentPage().getParameters().get('id');
        String driveIds = Apexpages.currentPage().getParameters().get('ids');
        String dJobId = Apexpages.currentPage().getParameters().get('jobId');
        if(String.isNotBlank(driveId)){
            Set<String> shiftidSet = checkDriveId(driveId);
            System.debug('sIdList --> '+shiftidSet);
            if(shiftidSet.size() > 0){
                addWrapperData(shiftidSet);
                redirectToSearch = false;
            }
        }else if(String.isNotBlank(dJobId)){
            Set<String> shiftidSet = checkDriveId(dJobId);
            System.debug('sIdList --> '+shiftidSet);
            if(shiftidSet.size() > 0){
                addWrapperData(shiftidSet);
                redirectToSearch = false;
            }
        }else if(String.isNotBlank(driveIds)){
            System.debug('driveIds : '+driveIds);
            if(String.isNotBlank(driveIds) && String.isNotBlank(pageName)){
                String driveId_str = driveIds.Substring(1,driveIds.length()-1);
                List<String> shiftidList = driveId_str.split(',');
                System.debug('shiftidList --> '+shiftidList);
                Set<String> shiftidSet = new Set<String>(shiftidList);
                addWrapperData(shiftidSet);
                System.debug('shiftidList size --> '+shiftDataWrap.size());
                redirectToSearch = false;
            }
        }
    }
    public void addWrapperData(Set<String> shiftidList){
        shiftDataWrap = new List<ReportWrapper>();
        List<sked_Drive_Shift__c> shiftData = [SELECT Id,
                                                        Name,
                                                        sked_Max_Donor_Capacity__c,
                                                        sked_2RBC_Projected_Procedures__c,
                                                        sked_WB_Projected_Procedures__c,
                                                        sked_Staff_Setup__c,
                                                        sked_Equipment_Allocated__c,
                                                        sked_Lunch_Break_Start_Time__c,
                                                        sked_Lunch_Break_End_Time__c,
                                                        sked_Drive__c,
                                                        sked_Drive__r.sked_Drive_Site__c,
                                                        sked_Drive__r.sked_Account__c,
                                                        sked_Drive_Account__c,
                                                        sked_Drive_Shift_Name__c,
                                                        sked_Start_Time__c,
                                                        sked_End_Time__c,
                                                        sked_Lunch_Break_Before_Draw_Hours__c,
                                                        sked_Lunch_Break__c,
                                                        sked_Lunch_Break_Duration__c 
                                            FROM sked_Drive_Shift__c 
                                            WHERE Id IN: shiftidList
                                            AND sked_Drive__c != null
                                            ORDER BY sked_Drive__c DESC NULLS LAST];
        if(shiftData.size() > 0){
            Set<Id> driveIdSet = new Set<Id>();
            Set<Id> siteIdSet = new Set<Id>();
            Set<Id> accountIdSet = new Set<Id>();
            Map<Id,Integer> shiftNoMap = new Map<Id,Integer>();
            Map<Id,Integer> driveTotalMap = new Map<Id,Integer>();
            Integer count_i;
            for(sked_Drive_Shift__c shift : shiftData){
                if(driveIdSet.size() == 0 || !driveIdSet.contains(shift.sked_Drive__c)){
                    count_i = 1;
                    driveIdSet.add(shift.sked_Drive__c);
                }else{
                    count_i++;
                }
                if(shift.sked_Drive__r.sked_Drive_Site__c != null){
                    siteIdSet.add(shift.sked_Drive__r.sked_Drive_Site__c);
                }
                if(shift.sked_Drive__r.sked_Account__c != null){
                    accountIdSet.add(shift.sked_Drive__r.sked_Account__c);
                }
                shiftNoMap.put(shift.Id,count_i);
                driveTotalMap.put(shift.sked_Drive__c,count_i);
            }
            Map<String,String> extdriveIdMap = new Map<String,String>();
            Map<String,String> extSiteIdMap = new Map<String,String>();
            Map<String,String> extAccIdMap = new Map<String,String>();
            if(driveIdSet.size() > 0){
                try{
                    List<DriveBridgeAPI__x> extDriveList = [SELECT external_id__c, 
                                                                    account_external_id__c, // changes for HRP-11561
                                                                    location_external_id__c, // changes for HRP-11561
                                                                    guid__c 
                                                            FROM DriveBridgeAPI__x 
                                                            WHERE guid__c IN: driveIdSet];
                    for(DriveBridgeAPI__x extd : extDriveList){
                        /*
                        * HRP-11561 changes starts here
                        */
                        String extIdPrefix;
                        if(String.isNotBlank(extd.external_id__c)){
                            extdriveIdMap.put(extd.guid__c,extd.external_id__c);
                            extIdPrefix = extd.external_id__c.left(3);
                        }
                        if(String.isNotBlank(extIdPrefix) && String.isNotBlank(extd.location_external_id__c) 
                                && extd.location_external_id__c.left(3).equalsIgnoreCase(extIdPrefix)){
                                    extSiteIdMap.put(extd.guid__c,extd.location_external_id__c);
                        }
                        if(String.isNotBlank(extIdPrefix) && String.isNotBlank(extd.account_external_id__c) 
                                && extd.account_external_id__c.left(3).equalsIgnoreCase(extIdPrefix)){
                                    extAccIdMap.put(extd.guid__c,extd.account_external_id__c);
                        }
                        /*
                        * HRP-11561 changes ends here
                        */
                    }
                }catch(Exception exp){}
            }
            //commented for for HRP-11561
            /*Map<String,String> extSiteIdMap = new Map<String,String>();
            if(siteIdSet.size() > 0){
                try{
                    List<SiteBridgeAPI__x> extSiteList = [SELECT external_id__c, 
                                                                    guid__c 
                                                            FROM SiteBridgeAPI__x 
                                                            WHERE guid__c IN: siteIdSet];
                    for(SiteBridgeAPI__x exts : extSiteList){
                        extSiteIdMap.put(exts.guid__c,exts.external_id__c);
                    }
                }catch(Exception exp){}
            }
            Map<String,String> extAccIdMap = new Map<String,String>();
            if(accountIdSet.size() > 0){
                try{
                    List<AccountBridgeAPI__x> extAccList = [SELECT external_id__c, 
                                                                    guid__c 
                                                            FROM AccountBridgeAPI__x 
                                                            WHERE guid__c IN: accountIdSet];
                    for(AccountBridgeAPI__x exta : extAccList){
                        extAccIdMap.put(exta.guid__c,exta.external_id__c);
                    }
                }catch(Exception exp){}
            }*/
            Map<Id, List<sked__Job__c>> jobMap = new Map<Id, List<sked__Job__c>>();
            Set<Id> jobIdList = new Set<Id>();
            List<sked__Job__c> jobList = [SELECT Id,
                                                sked_Setup_Time__c,
                                                sked_Breakdown_Time__c,
                                                sked_Travel_Time__c,
                                                sked_Travel_Time2__c,
                                                sked_Sponsor_Volunteer_Quantity__c,
                                                sked_Redcross_Volunteer_Quantity__c,
                                                sked_Drive_Shift__c
                                            FROM sked__Job__c
                                            WHERE sked_Drive_Shift__c IN: shiftidList];
            for(sked__Job__c jb : jobList){
                jobIdList.add(jb.Id);
                if(jobMap.size() != 0 && jobMap.containsKey(jb.sked_Drive_Shift__c) && jobMap.get(jb.sked_Drive_Shift__c) != null){
                    List<sked__Job__c> jobListtemp = jobMap.get(jb.sked_Drive_Shift__c);
                    jobListtemp.add(jb);
                    jobMap.put(jb.sked_Drive_Shift__c,jobListtemp);
                }else{
                    jobMap.put(jb.sked_Drive_Shift__c,new List<sked__Job__c>{jb});
                }
            }
            Map<Id, List<sked__Job_Allocation__c>> jobAllMap = new Map<Id, List<sked__Job_Allocation__c>>();
            List<sked__Job_Allocation__c> jobAllocationList = [SELECT Id,
                                                                    sked__Resource__c,
                                                                    sked__Resource__r.Name,
                                                                    sked__Resource__r.sked_eBDR_ID__c,
                                                                    sked__Resource__r.sked_Asset_Type__c,
                                                                    sked__Job__c,
                                                                    sked__Status__c,
                                                                    sked__Job__r.sked_Resource_Role__c,
                                                                    sked__Job__r.sked_Lead_Time__c,
                                                                    sked__Job__r.sked_Travel_Time__c,
                                                                    sked__Job__r.sked_Setup_Time__c,
                                                                    sked__Job__r.sked_Breakdown_Time__c,
                                                                    sked__Job__r.sked_Travel_Time2__c,
                                                                    sked__Job__r.sked_Wrap_up_Time__c,
                                                                    sked__Job__r.sked_Dual_Role__c, //changes for HRP-10711
                                                                    sked_Start_Time__c,
                                                                    sked_Set_End_Time__c,
                                                                    sked_Additional_Roles__c  //changes for HRP-10711
                                                                FROM sked__Job_Allocation__c 
                                                                WHERE sked__Job__c IN: jobIdList]; 
            for(sked__Job_Allocation__c jjball: jobAllocationList){
                if(jobAllMap.size() != 0 && jobAllMap.containsKey(jjball.sked__Job__c) && jobAllMap.get(jjball.sked__Job__c) != null){
                    List<sked__Job_Allocation__c> jobListtemp = jobAllMap.get(jjball.sked__Job__c);
                    jobListtemp.add(jjball);
                    jobAllMap.put(jjball.sked__Job__c,jobListtemp);
                }else{
                    jobAllMap.put(jjball.sked__Job__c,new List<sked__Job_Allocation__c>{jjball});
                }
            }    
            Map<Id, List<sked_Drive_Delivery_Job__c>> deliveryJobMap = new Map<Id, List<sked_Drive_Delivery_Job__c>>();
            List<sked_Drive_Delivery_Job__c> driveDeliveryJobList = [SELECT Id,
                                                                            sked_Type__c,
                                                                            sked_Pick_Up__c,
                                                                            sked_Delivery_ID__c,
                                                                            sked_Comments__c,
                                                                            sked_Drive__c,
                                                                            (SELECT Id, 
                                                                                sked_Bag_Type__c 
                                                                            FROM sked_Drive_Bags__r)
                                                                        FROM sked_Drive_Delivery_Job__c
                                                                        WHERE sked_Drive__c IN: driveIdSet];
            for(sked_Drive_Delivery_Job__c driveJob : driveDeliveryJobList){
                if(deliveryJobMap.size() != 0 && deliveryJobMap.containsKey(driveJob.sked_Drive__c) && deliveryJobMap.get(driveJob.sked_Drive__c) != null){
                    List<sked_Drive_Delivery_Job__c> jobListtemp = deliveryJobMap.get(driveJob.sked_Drive__c);
                    jobListtemp.add(driveJob);
                    deliveryJobMap.put(driveJob.sked_Drive__c,jobListtemp);
                }else{
                    deliveryJobMap.put(driveJob.sked_Drive__c,new List<sked_Drive_Delivery_Job__c>{driveJob});
                }
            }
            Map<Id, List<sked_Drive__c>> futureDriveMap = new Map<Id, List<sked_Drive__c>>();
            List<sked_Drive__c> futureDriveList = [SELECT Id, 
                                                            Name, 
                                                            sked_Account__c,
                                                            sked_Account__r.Name,
                                                            sked_Drive_Date__c,
                                                            sked_Drive_Site__c
                                                    FROM sked_Drive__c
                                                    WHERE sked_Drive_Site__c IN 
                                                    (SELECT Id 
                                                    FROM sked__Location__c 
                                                    WHERE Id IN : siteIdSet) 
                                                    AND sked_Status__c != 'Cancel'
                                                    ORDER BY sked_Drive_Date__c ASC];
            for(sked_Drive__c fdrv : futureDriveList){
                if(futureDriveMap.size() != 0 && futureDriveMap.containsKey(fdrv.sked_Drive_Site__c) && futureDriveMap.get(fdrv.sked_Drive_Site__c) != null){
                    List<sked_Drive__c> drvListTemp = futureDriveMap.get(fdrv.sked_Drive_Site__c);
                    drvListTemp.add(fdrv);
                    futureDriveMap.put(fdrv.sked_Drive_Site__c,drvListTemp);
                }else{
                    futureDriveMap.put(fdrv.sked_Drive_Site__c,new List<sked_Drive__c>{fdrv});
                }
            }                        
            Map<Id,sked_Drive__c> driveMap = new Map<Id,sked_Drive__c>([SELECT Id, 
                                                                                sked_Account__c,
                                                                                sked_Account__r.Name,
                                                                                sked_Account__r.Military_Authority_Name__c,//added for HRP-9954
                                                                                sked_Account__r.Military_Authority_Phone__c,//added for HRP-9954
                                                                                sked_Account__r.Account_Manager__c,
                                                                                sked_Account__r.Account_Manager__r.Name,
                                                                                sked_Account__r.Account_Manager__r.Phone,
                                                                                sked_Opportunity__c,
                                                                                sked_Opportunity__r.Additional_Drive_Logistics__c,//added for HRP-9954
                                                                                sked_Opportunity__r.Drive_Logistics_Other__c,//added for HRP-9954
                                                                                Name,
                                                                                sked_Drive_Date__c,
                                                                                sked_Drive_External_Id__c,
                                                                                sked_Drive_Site__c,
                                                                                sked_Drive_Site__r.sked_Wireless_Policy__c,
                                                                                sked_Drive_Site__r.Site_External_ID__c,
                                                                                sked_Drive_Site__r.sked_Site_Building_Name__c,
                                                                                sked_Drive_Site__r.sked_Room_Name__c,
                                                                                sked_Drive_Site__r.sked_Floor_Description__c,
                                                                                sked_Drive_Site__r.sked_Site_Main_Phone__c,
                                                                                sked_Drive_Site__r.sked_Site_Contact__c,
                                                                                sked_Drive_Site__r.sked_Site_Contact__r.Name,
                                                                                sked_Drive_Site__r.sked_Inside_stairs__c,
                                                                                sked_Drive_Site__r.sked_Outside_stairs__c,
                                                                                sked_Drive_Site__r.sked_Air_conditioned__c,
                                                                                sked_Drive_Site__r.sked_Heat__c,
                                                                                sked_Drive_Site__r.sked_Elevator_Type__c,
                                                                                sked_Drive_Site__r.Chapter__c, //HRP-12045 Changes
                                                                                sked_Drive_Site__r.Chapter__r.Name, //HRP-12045 Changes
                                                                                sked_Drive_Site__r.sked__Address__c,
                                                                                sked_Drive_Site__r.sked_Directions_From_CollectionOperation__c,
                                                                                sked_Drive_Site__r.sked_Escort_Required__c,
                                                                                sked_Drive_Site__r.sked_Equipment_X_Ray_Required__c,
                                                                                sked_Drive_Site__r.sked_No_Cell_Phones__c,
                                                                                sked_Drive_Site__r.sked_Canteen_Requirements__c,
                                                                                sked_Drive_Site__r.sked_Security_Directions__c,
                                                                                sked_Drive_Site__r.Sponsor_Security_Form_Required__c,
                                                                                sked_Drive_Site__r.sked_Safety_Emergency_Action_Plan__c,
                                                                                sked_Drive_Site__r.sked_Security_Information_Needed__c,
                                                                                sked_Drive_Site__r.sked_Staff_List__c,
                                                                                sked_Drive_Site__r.sked_Restroom_Location__c,
                                                                                sked_Drive_Site__r.sked_Floor_Covering_Requirement__c,
                                                                                sked_Drive_Site__r.sked_On_Site_Food_Canteen_Requirements__c,
                                                                                sked_Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c,
                                                                                sked_Drive_Site__r.sked_Staff_Personal_Parking_Directions__c,
                                                                                sked_Drive_Site__r.sked_Pay_for_Parking_Details__c,
                                                                                sked_Drive_Site__r.sked_Unloading_Conditions__c,
                                                                                sked_Drive_Site__r.sked_Unloading_Directions_Details__c,
                                                                                sked_Drive_Site__r.sked_Canteen_Conditions__c,
                                                                        		sked_Drive_Site__r.Site_Smoking_Policy__c, // added for HRP-10052
                                                                        		sked_Drive_Site__r.EAP_Map_Available__c, // added for HRP-12166
                                                                        		sked_Drive_Site__r.AED_Available__c, // added for HRP-12166
                                                                                sked_Drive_Site__r.sked_Site_Contact_Phone__c, // added for HRP-16313
                                                                                sked_Opportunity__r.RecordType.DeveloperName, // added for HRP-16313
                                                                                sked_Status__c,
                                                                                sked_Open_to_Public__c,
                                                                                Operational_Notes__c,
                                                                                sked_Operation_Notes__c,
                                                                                sked_Whome_to_Meet__c,
                                                                                sked_Whome_to_Meet__r.Name,
                                                                                sked_Primary_Contact__c,
                                                                                sked_Primary_Contact__r.Name,
                                                                                sked_Primary_Contact__r.Primary_Phone__c,
                                                                                sked_Primary_Contact__r.MobilePhone,
                                                                                sked_Primary_Contact__r.OtherPhone,
                                                                                sked_Primary_Contact__r.HomePhone,
                                                                                sked_Security_Escort_Name__c,
                                                                                sked_Opportunity__r.Account_Manager__c,// added for HRP-11777
                                                                                sked_Opportunity__r.Account_Manager__r.Name,// added for HRP-11777
                                                                                sked_Opportunity__r.Account_Manager__r.WorkPhone__c// added for HRP-11777
                                                                        FROM sked_Drive__c 
                                                                        WHERE Id IN: driveIdSet]);
            for(sked_Drive_Shift__c shift : shiftData){
                ReportWrapper rw = new ReportWrapper();
                rw.oppInfo = new OprationalInformation();
                rw.siteInfo = new SiteInformation();
                rw.shiftInfo = new DriveShiftInformation();
                rw.notes = new OperationalNotes();
                if(driveMap.get(shift.sked_Drive__c) != null){
                    sked_Drive__c drive = driveMap.get(shift.sked_Drive__c);
                    rw.driveName = drive.Name;
                    rw.oppInfo.report = shiftNoMap.get(shift.id)+' of '+driveTotalMap.get(drive.Id);
                    rw.oppInfo.accountName = drive.sked_Account__c != null ? drive.sked_Account__r.Name : '';

                    if (drive.sked_Opportunity__c != null && drive.sked_Opportunity__r.RecordType != null
                                && drive.sked_Opportunity__r.RecordType.DeveloperName == 'Fixed_Site_Opp') {
                                rw.isFixedSite = true;
                    }else{
                        rw.isFixedSite = false;
                    }
                    
                    //HRP-12505 -start
                    if (drive.sked_Opportunity__c != null && drive.sked_Opportunity__r.RecordType != null
                                && drive.sked_Opportunity__r.RecordType.DeveloperName == 'Fixed_Site_Opp') {
                                rw.oppInfo.accountManager = (drive.sked_Drive_Site__c != null 
                                                            && drive.sked_Drive_Site__r.sked_Site_Contact__c != null)
                                                            ? drive.sked_Drive_Site__r.sked_Site_Contact__r.Name
                                                            : '';

                    }else if(drive.sked_Opportunity__c != null && drive.sked_Opportunity__r.Account_Manager__c != null && 
					   drive.sked_Opportunity__r.Account_Manager__r.Name != null){
					   rw.oppInfo.accountManager = drive.sked_Opportunity__r.Account_Manager__r.Name;   
					}else{
					   rw.oppInfo.accountManager  = '';  
					}

                    if (drive.sked_Opportunity__c != null && drive.sked_Opportunity__r.RecordType != null
                                && drive.sked_Opportunity__r.RecordType.DeveloperName == 'Fixed_Site_Opp') {
                                rw.oppInfo.phone = drive.sked_Drive_Site__c != null
                                                    ? drive.sked_Drive_Site__r.sked_Site_Contact_Phone__c
                                                    : '';

                    }else if(drive.sked_Opportunity__c != null && drive.sked_Opportunity__r.Account_Manager__c != null && 
					   drive.sked_Opportunity__r.Account_Manager__r.WorkPhone__c != null){
					   rw.oppInfo.phone = drive.sked_Opportunity__r.Account_Manager__r.WorkPhone__c;   
					}else{
					   rw.oppInfo.phone  = '';  
					}
					//HRP-12505 - end
                    /*
                    rw.oppInfo.accountManager = drive.Account_Manager__c == null ? '' : (drive.Account_Manager__r.Name != null ? drive.Account_Manager__r.Name : '');// changed for HRP-11777
                    rw.oppInfo.phone = drive.Account_Manager__c == null ? '' : (drive.Account_Manager__r.Phone != null ? drive.Account_Manager__r.Phone : '');// changed for HRP-11777
                    */
					if(drive.sked_Drive_Date__c != null){
                        DateTime dDate = DateTime.newInstance(drive.sked_Drive_Date__c.year(),drive.sked_Drive_Date__c.month(),drive.sked_Drive_Date__c.day());
                        rw.oppInfo.driveDate = dDate.format('EEE M/d/yyyy');
                    }
                    /*
                    * HRP-9954 changes ends here
                    */
                    rw.oppInfo.militaryAuName = drive.sked_Account__c == null ? '' : (drive.sked_Account__r.Military_Authority_Name__c != null ? drive.sked_Account__r.Military_Authority_Name__c : '');
                    rw.oppInfo.militaryAuNo = drive.sked_Account__c == null ? '' : (drive.sked_Account__r.Military_Authority_Phone__c != null ? drive.sked_Account__r.Military_Authority_Phone__c : '');
                    if(drive.sked_Opportunity__c != null && String.isNotBlank(drive.sked_Opportunity__r.Additional_Drive_Logistics__c)){
                        List<String> logisticsList = drive.sked_Opportunity__r.Additional_Drive_Logistics__c.split(';');
                        rw.oppInfo.AddiLogistics = String.join(logisticsList,', ');
                    }else{
                        rw.oppInfo.AddiLogistics = '';
                    }
                    rw.oppInfo.AddiLogisticsOther = drive.sked_Opportunity__r == null ? '' : (drive.sked_Opportunity__r.Drive_Logistics_Other__c != null ? drive.sked_Opportunity__r.Drive_Logistics_Other__c : '');
                    /*
                    * HRP-9954 changes ends here
                    */
                    rw.oppInfo.wBEligibility = drive.sked_Drive_Date__c != null ? dateFormat(drive.sked_Drive_Date__c.addDays(-56)) : '';
                    rw.oppInfo.twoRBCEligibility = drive.sked_Drive_Date__c != null ? dateFormat(drive.sked_Drive_Date__c.addDays(-112)) : '';
                    rw.oppInfo.opentoPublic = drive.sked_Open_to_Public__c;
                    rw.oppInfo.wirelessPolicy = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Wireless_Policy__c : '';
                    if(extdriveIdMap.size() > 0 && extdriveIdMap.containsKey(drive.id)){
                        rw.oppInfo.driveId = extdriveIdMap.get(drive.id);
                    }
                    if(extSiteIdMap.size() > 0 && extSiteIdMap.containsKey(drive.id)){
                        rw.oppInfo.siteId = extSiteIdMap.get(drive.id);
                    }
                    if(extAccIdMap.size() > 0 && extAccIdMap.containsKey(drive.id)){
                        rw.oppInfo.accId = extAccIdMap.get(drive.id);
                    }
                    rw.siteInfo.siteBuilding = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Site_Building_Name__c : '';
                    rw.siteInfo.room = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Room_Name__c : '';
                    rw.siteInfo.floor = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Floor_Description__c : '';
                    rw.siteInfo.siteAddress = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked__Address__c : '';
                    rw.siteInfo.sitePhone = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Site_Main_Phone__c : '';
                    rw.siteInfo.meetWith = drive.sked_Whome_to_Meet__c != null ? drive.sked_Whome_to_Meet__r.Name : '';
                    rw.siteInfo.siteContact = (drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.sked_Site_Contact__c != null)? drive.sked_Drive_Site__r.sked_Site_Contact__r.Name : '';
                    rw.siteInfo.priChair = drive.sked_Primary_Contact__c != null ? drive.sked_Primary_Contact__r.Name : '';
                    rw.siteInfo.phone = drive.sked_Primary_Contact__c != null ? drive.sked_Primary_Contact__r.Primary_Phone__c : '';
                    if(drive.sked_Primary_Contact__c != null) {
                        String primaryPhone = drive.sked_Primary_Contact__r.Primary_Phone__c;
                        if(primaryPhone == 'Work Phone') {
                            rw.siteInfo.mobile = drive.sked_Primary_Contact__r.OtherPhone != null ? drive.sked_Primary_Contact__r.OtherPhone : '';
                        } else if(primaryPhone == 'Home Phone') {
                            rw.siteInfo.mobile = drive.sked_Primary_Contact__r.HomePhone != null ? drive.sked_Primary_Contact__r.HomePhone : '';
                        } else {
                            rw.siteInfo.mobile = drive.sked_Primary_Contact__r.MobilePhone != null ? drive.sked_Primary_Contact__r.MobilePhone : '';
                        }
                    } else {
                        rw.siteInfo.mobile = '';
                    }
                    rw.siteInfo.insideStairs = drive.sked_Drive_Site__c != null ? String.valueOf(drive.sked_Drive_Site__r.sked_Inside_stairs__c) : '';
                    rw.siteInfo.outsideStairs = drive.sked_Drive_Site__c != null ? String.valueOf(drive.sked_Drive_Site__r.sked_Outside_stairs__c) : '';
                    if(drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.sked_Escort_Required__c != null){
                        rw.siteInfo.escortRequired = drive.sked_Drive_Site__r.sked_Escort_Required__c == true ? 'Yes' : 'No';
                    }
                    rw.siteInfo.escortName = String.isNotBlank(drive.sked_Security_Escort_Name__c) ? drive.sked_Security_Escort_Name__c : ''; 
                    if(drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.sked_Equipment_X_Ray_Required__c != null){
                        rw.siteInfo.equipmentXRay = drive.sked_Drive_Site__r.sked_Equipment_X_Ray_Required__c == true ? 'Yes' : 'No';
                    }
                    if(drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.sked_No_Cell_Phones__c != null){
                        rw.siteInfo.noCellPhones = drive.sked_Drive_Site__r.sked_No_Cell_Phones__c == true ? 'Yes' : 'No';
                    }
                    rw.siteInfo.canteenReq = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Canteen_Requirements__c : '';
                    rw.siteInfo.canteenCond = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Canteen_Conditions__c : '';
                    rw.siteInfo.onSiteFoodReq = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_On_Site_Food_Canteen_Requirements__c : '';
                    rw.siteInfo.securityDir = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Security_Directions__c : '';
                    rw.siteInfo.sponsorSecReq = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.Sponsor_Security_Form_Required__c : '';
                    rw.siteInfo.safetyEmgActPlan = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Safety_Emergency_Action_Plan__c : '';
                    rw.siteInfo.securityInfNeeded = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Security_Information_Needed__c : '';
                    if(drive.sked_Drive_Site__c != null && String.isNotBlank(drive.sked_Drive_Site__r.sked_Staff_List__c)){
                        rw.siteInfo.staffListNeeded = drive.sked_Drive_Site__r.sked_Staff_List__c.replace(';','\n');
                    }
                    rw.siteInfo.restroomLocation = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Restroom_Location__c : '';
                    rw.siteInfo.floorCoveringReq = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Floor_Covering_Requirement__c : '';
                    rw.siteInfo.arcVehParkingDir = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c : '';
                    rw.siteInfo.staffPerParkingDir = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Staff_Personal_Parking_Directions__c : '';
                    rw.siteInfo.payforParking = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Pay_for_Parking_Details__c : '';
                    rw.siteInfo.unloadingCond = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Unloading_Conditions__c : '';
                    rw.siteInfo.unloadingDir = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Unloading_Directions_Details__c : '';
                    rw.siteInfo.siteSmkPolicy = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.Site_Smoking_Policy__c : ''; // added for HRP-10052
                    rw.siteInfo.siteEAPMapAvailable = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.EAP_Map_Available__c : ''; //added for HRP-12166
                    rw.siteInfo.siteAEDAvailable = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.AED_Available__c : ''; //added for HRP-12166
                    if(drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.sked_Air_conditioned__c == true){
                        rw.siteInfo.airCondition = 'Yes';
                    }else if(drive.sked_Drive_Site__c != null){
                        rw.siteInfo.airCondition = 'No';
                    }
                    if(drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.sked_Heat__c == true){
                        rw.siteInfo.heated = 'Yes';
                    }else if(drive.sked_Drive_Site__c != null){
                        rw.siteInfo.heated = 'No';
                    }
                    rw.siteInfo.elevator = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Elevator_Type__c : '';
                    rw.siteInfo.chapter = (drive.sked_Drive_Site__c != null && drive.sked_Drive_Site__r.Chapter__c != null) ? drive.sked_Drive_Site__r.Chapter__r.Name : ''; //HRP-12045 Changes
                    rw.siteInfo.directions = drive.sked_Drive_Site__c != null ? drive.sked_Drive_Site__r.sked_Directions_From_CollectionOperation__c : '';
                    if(String.isNotBlank(drive.Operational_Notes__c) && String.isNotBlank(drive.sked_Operation_Notes__c)){
                        rw.notes.opNotes = '1. '+drive.Operational_Notes__c+'\n2. '+drive.sked_Operation_Notes__c;
                    }else if(String.isNotBlank(drive.Operational_Notes__c)){
                        rw.notes.opNotes = '1. '+drive.Operational_Notes__c;
                    }else if(String.isNotBlank(drive.sked_Operation_Notes__c)){
                        rw.notes.opNotes = '1. '+drive.sked_Operation_Notes__c;
                    }else{
                        rw.notes.opNotes = '* No Notes';
                    }
                    if(deliveryJobMap.containsKey(drive.id) && deliveryJobMap.get(drive.id) != null){
                        rw.jobInfoList = new List<DriveJobInformation>();
                        for(sked_Drive_Delivery_Job__c driveJob : deliveryJobMap.get(drive.id)){
                            DriveJobInformation dj = new DriveJobInformation();
                            dj.num = String.valueOf(rw.jobInfoList.size() + 1);
                            dj.jobType = driveJob.sked_Type__c;
                            dj.pickupTime = driveJob.sked_Pick_Up__c != null ? getFormattedTime(driveJob.sked_Pick_Up__c.hour(),driveJob.sked_Pick_Up__c.minute()) : '';
                            dj.deliveryID = driveJob.sked_Delivery_ID__c;
                            dj.driveComments = driveJob.sked_Comments__c;
                            List<String> bagList = new List<String>();
                            if(driveJob.sked_Drive_Bags__r != null){
                                for(sked_Drive_Bag__c dbag : driveJob.sked_Drive_Bags__r){
                                    if(String.isNotBlank(dbag.sked_Bag_Type__c)){
                                        bagList.add(dbag.sked_Bag_Type__c);
                                    }
                                }
                            }
                            if(bagList.size() > 0){
                                dj.bagDetails = String.join(bagList,' , ');
                            }
                            rw.jobInfoList.add(dj);
                        }
                    }
                    if(drive.sked_Drive_Site__c != null && futureDriveMap.size() > 0 
                            && futureDriveMap.containsKey(drive.sked_Drive_Site__c) && futureDriveMap.get(drive.sked_Drive_Site__c) != null){
                                rw.fdriveInfoList = new List<FutureDriveInformation>();
                                Integer counter = 0;
                                for(sked_Drive__c fdrive : futureDriveMap.get(drive.sked_Drive_Site__c)){
                                    if(fdrive.sked_Drive_Date__c != null && drive.sked_Drive_Date__c != null
                                            && fdrive.sked_Drive_Date__c >= drive.sked_Drive_Date__c
                                            && fdrive.sked_Drive_Date__c <= drive.sked_Drive_Date__c.addMonths(6)
                                            && fdrive.Id != drive.Id){
                                                FutureDriveInformation fuDrive = new FutureDriveInformation();
                                                fuDrive.num = String.valueOf(rw.fdriveInfoList.size() + 1);
                                                fuDrive.driveName = fdrive.Name;
                                                fuDrive.driveDate = dateFormat(fdrive.sked_Drive_Date__c);
                                                fuDrive.driveAccount = fdrive.sked_Account__c != null ? fdrive.sked_Account__r.Name : '';
                                                rw.fdriveInfoList.add(fuDrive);
                                                counter++;
                                                if(counter == 2){
                                                    break;
                                                }
                                    }
                                }
                    }
                }
                List<String> vehicleList = new List<String>();
                List<String> jobAllocStatusList = new List<String>{'Dispatched','Confirmed','En Route','Checked In','In Progress','Complete'};
                if(jobMap.containsKey(shift.Id) && jobMap.get(shift.Id) != null){
                    rw.empInfoList = new List<EmployeeTableInformation>();
                    Decimal max_setup = 0;
                    Decimal max_breakdown = 0;
                    Decimal max_traveltme = 0;
                    Decimal max_traveltme2 = 0;
                    Decimal max_spVolunteer = 0;
                    Decimal max_rdVolunteer = 0;
                    for(sked__Job__c jb : jobMap.get(shift.Id)){
                        if(jb.sked_Setup_Time__c != null && jb.sked_Setup_Time__c > max_setup){
                            max_setup = jb.sked_Setup_Time__c;
                        }
                        if(jb.sked_Breakdown_Time__c != null && jb.sked_Breakdown_Time__c > max_breakdown){
                            max_breakdown = jb.sked_Breakdown_Time__c;
                        }
                        if(jb.sked_Travel_Time__c != null && jb.sked_Travel_Time__c > max_traveltme){
                            max_traveltme = jb.sked_Travel_Time__c;
                        }
                        if(jb.sked_Travel_Time2__c != null && jb.sked_Travel_Time2__c > max_traveltme2){
                            max_traveltme2 = jb.sked_Travel_Time2__c;
                        }
                        if(jb.sked_Sponsor_Volunteer_Quantity__c != null && jb.sked_Sponsor_Volunteer_Quantity__c > max_spVolunteer){
                            max_spVolunteer = jb.sked_Sponsor_Volunteer_Quantity__c;
                        }
                        if(jb.sked_Redcross_Volunteer_Quantity__c != null && jb.sked_Redcross_Volunteer_Quantity__c > max_rdVolunteer){
                            max_rdVolunteer = jb.sked_Redcross_Volunteer_Quantity__c;
                        }
                    }
                    for(sked__Job__c jb : jobMap.get(shift.Id)){
                        if(jobAllMap.containsKey(jb.Id) && jobAllMap.get(jb.Id) != null){
                            for(sked__Job_Allocation__c jjball : jobAllMap.get(jb.Id)){
                                EmployeeTableInformation emp = new EmployeeTableInformation();
                                if(jjball.sked__Job__c != null && String.isNotBlank(jjball.sked__Job__r.sked_Resource_Role__c) 
                                        && String.isNotBlank(jjball.sked__Status__c) && jobAllocStatusList.contains(jjball.sked__Status__c)){
                                    emp.num =  String.valueOf(rw.empInfoList.size() + 1);
                                    /*
                                    * HRP-10711 changes starts here
                                    */
                                    List<String> roleList = new List<String>{jjball.sked__Job__r.sked_Resource_Role__c};
                                    if(String.isNotBlank(jjball.sked__Job__r.sked_Dual_Role__c)){
                                        roleList.add(jjball.sked__Job__r.sked_Dual_Role__c);
                                    }
                                    if(String.isNotBlank(jjball.sked_Additional_Roles__c)){
                                        roleList.addall(jjball.sked_Additional_Roles__c.split(';'));
                                    }
                                    if(roleList.size() > 0){
                                        List<String> roleListNoDupes = new List<String>(new Set<String>(roleList));
                                        emp.role = String.join(roleListNoDupes,', ');
                                    }
                                    /*
                                    * HRP-10711 changes ends here
                                    */
                                    if(jjball.sked__Resource__c != null){
                                        emp.employeeName = jjball.sked__Resource__r.Name;
                                        emp.eBDRID = jjball.sked__Resource__r.sked_eBDR_ID__c;
                                    }
                                    /*
                                    * HRP-10127 Changes starts here 
                                    *
                                    Integer startTimeConst = 0; 
                                    Integer endTimeConst = 0; 
                                    if(jjball.sked_Start_Time__c != null && shift.sked_Start_Time__c != null 
                                        && jjball.sked__Job__r.sked_Travel_Time__c != null && jjball.sked__Job__r.sked_Setup_Time__c != null 
                                        && jjball.sked__Job__r.sked_Lead_Time__c != null){
                                        Integer leadMinutes = Integer.valueOf(0 - jjball.sked__Job__r.sked_Travel_Time__c - jjball.sked__Job__r.sked_Setup_Time__c  - jjball.sked__Job__r.sked_Lead_Time__c);
                                        startTimeConst = getTimeDifferenceInMinutes(shift.sked_Start_Time__c.addMinutes(leadMinutes),jjball.sked_Start_Time__c);
                                    }
                                    if(jjball.sked_Set_End_Time__c != null && shift.sked_End_Time__c != null 
                                        && jjball.sked__Job__r.sked_Breakdown_Time__c != null && jjball.sked__Job__r.sked_Travel_Time2__c != null 
                                        && jjball.sked__Job__r.sked_Wrap_up_Time__c != null){
                                        Integer wrapupMinutes = Integer.valueOf(jjball.sked__Job__r.sked_Breakdown_Time__c + jjball.sked__Job__r.sked_Travel_Time2__c + jjball.sked__Job__r.sked_Wrap_up_Time__c);
                                        endTimeConst = getTimeDifferenceInMinutes(shift.sked_End_Time__c.addMinutes(wrapupMinutes),jjball.sked_Set_End_Time__c);
                                    }
                                    /*
                                    * HRP-10127 Changes ends here 
                                    */
                                    /*/Logic: Setup Time = Shift Start Time - Maximum (Job Setup Time)
                                    if(shift.sked_Start_Time__c != null && max_setup != null){
                                        //Integer ms = startTimeConst + Integer.valueOf(0 - jjball.sked__Job__r.sked_Setup_Time__c); // modified for HRP-10127
                                        Integer ms = Integer.valueOf(0 - max_setup); // modified for HRP-10418
                                        emp.setup = getFormattedTime(shift.sked_Start_Time__c.addMinutes(ms).hour(),shift.sked_Start_Time__c.addMinutes(ms).minute());
                                    }
                                    //Logic: Breakdown Time = Shift Start Time + Maximum (Job Breakdown Time)
                                    if(shift.sked_End_Time__c != null && max_breakdown != null){
                                        //Integer ms = endTimeConst + Integer.valueOf(jjball.sked__Job__r.sked_Breakdown_Time__c); // modified for HRP-10127
                                        Integer ms = Integer.valueOf(max_breakdown); // modified for HRP-10418
                                        emp.breakDown = getFormattedTime(shift.sked_End_Time__c.addMinutes(ms).hour(),shift.sked_End_Time__c.addMinutes(ms).minute());
                                    }
                                    /*if(shift.sked_Start_Time__c != null && jjball.sked__Job__r.sked_Travel_Time__c != null && jjball.sked__Job__r.sked_Setup_Time__c != null && jjball.sked__Job__r.sked_Lead_Time__c != null){
                                        Integer ms = startTimeConst + Integer.valueOf(0 - jjball.sked__Job__r.sked_Travel_Time__c - jjball.sked__Job__r.sked_Setup_Time__c  - jjball.sked__Job__r.sked_Lead_Time__c); // modified for HRP-10127
                                        emp.lead = getFormattedTime(shift.sked_Start_Time__c.addMinutes(ms).hour(),shift.sked_Start_Time__c.addMinutes(ms).minute());
                                    }
                                    if(shift.sked_Start_Time__c != null && jjball.sked__Job__r.sked_Travel_Time__c != null && jjball.sked__Job__r.sked_Setup_Time__c != null){
                                        Integer ms = startTimeConst + Integer.valueOf(0 - jjball.sked__Job__r.sked_Travel_Time__c - jjball.sked__Job__r.sked_Setup_Time__c); // modified for HRP-10127
                                        emp.leave = getFormattedTime(shift.sked_Start_Time__c.addMinutes(ms).hour(),shift.sked_Start_Time__c.addMinutes(ms).minute());
                                    }
                                    if(shift.sked_End_Time__c != null && jjball.sked__Job__r.sked_Breakdown_Time__c != null && jjball.sked__Job__r.sked_Travel_Time2__c != null){
                                        Integer ms = endTimeConst + Integer.valueOf(jjball.sked__Job__r.sked_Breakdown_Time__c + jjball.sked__Job__r.sked_Travel_Time2__c); // modified for HRP-10127
                                        emp.returnTime = getFormattedTime(shift.sked_End_Time__c.addMinutes(ms).hour(),shift.sked_End_Time__c.addMinutes(ms).minute());
                                    }
                                    if(shift.sked_End_Time__c != null && jjball.sked__Job__r.sked_Breakdown_Time__c != null && jjball.sked__Job__r.sked_Travel_Time2__c != null && jjball.sked__Job__r.sked_Wrap_up_Time__c != null){
                                        Integer ms = endTimeConst + Integer.valueOf(jjball.sked__Job__r.sked_Breakdown_Time__c + jjball.sked__Job__r.sked_Travel_Time2__c + jjball.sked__Job__r.sked_Wrap_up_Time__c); // modified for HRP-10127
                                        emp.wrapup = getFormattedTime(shift.sked_End_Time__c.addMinutes(ms).hour(),shift.sked_End_Time__c.addMinutes(ms).minute());
                                    }*/


                                    /*
                                    * HRP-10259 Changes starts here 
                                    */
                                    //NEW Logic: Lead = Job Allocation Start Time
                                    if(jjball.sked_Start_Time__c != null){
                                        emp.lead = getFormattedTime(jjball.sked_Start_Time__c.hour(),jjball.sked_Start_Time__c.minute());
                                    }
                                    //NEW Logic: Leave = Job Allocation Start Time + Job Lead Time
                                    if(jjball.sked_Start_Time__c != null && jjball.sked__Job__r.sked_Lead_Time__c != null){
                                        Integer ms = Integer.valueOf(jjball.sked__Job__r.sked_Lead_Time__c);
                                        emp.leave = getFormattedTime(jjball.sked_Start_Time__c.addMinutes(ms).hour(),jjball.sked_Start_Time__c.addMinutes(ms).minute());
                                    }
                                    //NEW Logic: Setup Time = Shift Start Time - Job Setup Time
                                    if(shift.sked_Start_Time__c != null && jjball.sked__Job__r.sked_Setup_Time__c != null){
                                        Integer lunchBreakDuration = 0;
                                        if(shift.sked_Lunch_Break__c && shift.sked_Lunch_Break_Before_Draw_Hours__c && shift.sked_Lunch_Break_Duration__c != null){
                                            lunchBreakDuration = Integer.valueOf(shift.sked_Lunch_Break_Duration__c);
                                        }
                                        Integer ms = 0 - Integer.valueOf(jjball.sked__Job__r.sked_Setup_Time__c) - lunchBreakDuration;
                                        emp.setup = getFormattedTime(shift.sked_Start_Time__c.addMinutes(ms).hour(),shift.sked_Start_Time__c.addMinutes(ms).minute());
                                    }
                                    //NEW Logic: Breakdown Time = Shift End Time + Job Breakdown Time
                                    if(shift.sked_End_Time__c != null && jjball.sked__Job__r.sked_Breakdown_Time__c != null){
                                        Integer ms = Integer.valueOf(jjball.sked__Job__r.sked_Breakdown_Time__c);
                                        emp.breakDown = getFormattedTime(shift.sked_End_Time__c.addMinutes(ms).hour(),shift.sked_End_Time__c.addMinutes(ms).minute());
                                    }
                                    //NEW Logic: Return = Job Allocation Set End Time - Job Wrap Up Time
                                    if(jjball.sked_Set_End_Time__c != null && jjball.sked__Job__r.sked_Wrap_up_Time__c != null){
                                        Integer ms = Integer.valueOf(0 - jjball.sked__Job__r.sked_Wrap_up_Time__c);
                                        emp.returnTime = getFormattedTime(jjball.sked_Set_End_Time__c.addMinutes(ms).hour(),jjball.sked_Set_End_Time__c.addMinutes(ms).minute());
                                    }
                                    //NEW Logic: Wrap up = Job Allocation Set End Time
                                    if(jjball.sked_Set_End_Time__c != null){
                                        emp.wrapup = getFormattedTime(jjball.sked_Set_End_Time__c.hour(),jjball.sked_Set_End_Time__c.minute());
                                    }
                                    /*
                                    * HRP-10259 Changes starts here 
                                    */

                                    rw.empInfoList.add(emp);
                                }else if(jjball.sked__Resource__c != null && String.isNotBlank(jjball.sked__Resource__r.Name) 
                                        && String.isNotBlank(jjball.sked__Resource__r.sked_Asset_Type__c) 
                                        && jjball.sked__Resource__r.sked_Asset_Type__c.equalsIgnoreCase('Vehicle') 
                                         && (jjball.sked__Status__c != 'Deleted')){ //HRP-12306
                                            vehicleList.add(jjball.sked__Resource__r.Name);
                                }
                            }
                        }
                    }
                    if(max_setup > 0 && shift.sked_Start_Time__c != null){
                        Integer lunchBreakDuration = 0;
                        if(shift.sked_Lunch_Break__c && shift.sked_Lunch_Break_Before_Draw_Hours__c && shift.sked_Lunch_Break_Duration__c != null){
                            lunchBreakDuration = Integer.valueOf(shift.sked_Lunch_Break_Duration__c);
                        }
                        Integer ms = Integer.valueOf(0 - max_setup - lunchBreakDuration);
                        rw.oppInfo.setup = getFormattedTime(shift.sked_Start_Time__c.addMinutes(ms).hour(),shift.sked_Start_Time__c.addMinutes(ms).minute());
                    }else if(shift.sked_Start_Time__c != null){
                        rw.oppInfo.setup = getFormattedTime(shift.sked_Start_Time__c.hour(),shift.sked_Start_Time__c.minute());
                    }
                    if(max_breakdown > 0 && shift.sked_End_Time__c != null){
                        Integer ms = Integer.valueOf(max_breakdown);
                        rw.oppInfo.breakDown = getFormattedTime(shift.sked_End_Time__c.addMinutes(ms).hour(),shift.sked_End_Time__c.addMinutes(ms).minute());
                    }else if(shift.sked_End_Time__c != null){
                        rw.oppInfo.breakDown = getFormattedTime(shift.sked_End_Time__c.hour(),shift.sked_End_Time__c.minute());
                    }
                    /*if(max_traveltme2 == 0 || max_traveltme == 0){
                        rw.oppInfo.minutes = '0';
                    }else{
                        rw.oppInfo.minutes = String.valueOf((max_traveltme/max_traveltme2).setScale(2));
                    }*/
                    rw.oppInfo.minutes = max_traveltme2 > max_traveltme ? String.valueOf(max_traveltme2) : String.valueOf(max_traveltme); // HRP-10893 Changes
                    rw.oppInfo.volunteersReqAccount =  String.valueOf(Integer.valueOf(max_spVolunteer));
                    rw.oppInfo.volunteersReqCenter =  String.valueOf(Integer.valueOf(max_rdVolunteer));
                }
                if(vehicleList.size() > 0){
                    rw.oppInfo.vehicle = String.join(vehicleList,' , ');
                }
                rw.oppInfo.drawStart = shift.sked_Start_Time__c != null ? getFormattedTime(shift.sked_Start_Time__c.hour(),shift.sked_Start_Time__c.minute()) : '';
                rw.oppInfo.drawEnd = shift.sked_End_Time__c != null ? getFormattedTime(shift.sked_End_Time__c.hour(),shift.sked_End_Time__c.minute()) : '';
                rw.shiftInfo.shift = shift.Name;
                rw.shiftInfo.presentingDonorCapacity = shift.sked_Max_Donor_Capacity__c != null ? String.valueOf(Math.floor(shift.sked_Max_Donor_Capacity__c)) : '';//HRP-12189
                rw.shiftInfo.typeRBC = '2RBC';
                rw.shiftInfo.typeWB = 'WB';
                rw.shiftInfo.staffReq = shift.sked_Staff_Setup__c != null ? String.valueOf(shift.sked_Staff_Setup__c) : '';
                rw.shiftInfo.autoMac = shift.sked_Equipment_Allocated__c != null ? String.valueOf(shift.sked_Equipment_Allocated__c) : '';
                if(shift.sked_2RBC_Projected_Procedures__c != null && shift.sked_WB_Projected_Procedures__c != null){
                    rw.shiftInfo.procedureRBC = String.valueOf( Integer.valueOf( Math.Round( shift.sked_2RBC_Projected_Procedures__c)));
                    rw.shiftInfo.procedureWB = String.valueOf( Integer.valueOf( Math.Round( shift.sked_WB_Projected_Procedures__c)));
                    rw.shiftInfo.productRBC = String.valueOf( Integer.valueOf( Math.Round( shift.sked_2RBC_Projected_Procedures__c*2)));
                    rw.shiftInfo.productWB = String.valueOf( Integer.valueOf( Math.Round( shift.sked_WB_Projected_Procedures__c)));
                    rw.shiftInfo.totalProcedure = String.valueOf( Integer.valueOf( Math.Round( shift.sked_2RBC_Projected_Procedures__c + shift.sked_WB_Projected_Procedures__c)));
                    rw.shiftInfo.totalProduct = String.valueOf( Integer.valueOf( Math.Round( (shift.sked_2RBC_Projected_Procedures__c*2) + shift.sked_WB_Projected_Procedures__c)));
                }
                if(shift.sked_Lunch_Break_Start_Time__c != null && shift.sked_Lunch_Break_End_Time__c != null){
                    rw.shiftInfo.lunchBreakRed = getFormattedTime(shift.sked_Lunch_Break_Start_Time__c.hour(),shift.sked_Lunch_Break_Start_Time__c.minute())+
                    ' - '+getFormattedTime(shift.sked_Lunch_Break_End_Time__c.hour(),shift.sked_Lunch_Break_End_Time__c.minute());
                }
                shiftDataWrap.add(rw);
            }
        }
        
    }
    @TestVisible
    private String getFormattedTime(Integer hour, Integer minutes){
        System.debug('inputs hour--> '+hour);
        System.debug('inputs minutes--> '+minutes);
        String st;
        if(hour == 0){
            hour = 12;
            st = 'AM';
        }else if(hour < 12){
            st = 'AM';
        }else if(hour == 12){
            st = 'PM';
        }else if(hour > 12){
            hour = hour - 12;
            st = 'PM';
        }
        if(minutes < 10){
            System.debug('final --> '+hour+':0'+minutes+st);
            return hour+':0'+minutes+st;
        }else{
            System.debug('final --> '+hour+':'+minutes+st);
            return hour+':'+minutes+st;
        }
    }
    @TestVisible
    private Set<String> checkDriveId(String driveId){
        Set<String> driveIdList = new Set<String>();
        Integer count_r = 0;
        String new_driveId = String.escapeSingleQuotes(driveId);
        if(String.isNotBlank(new_driveId) && (new_driveId.length() == 15 || new_driveId.length() == 18)){
            if(new_driveId.substring(0,3).equalsIgnoreCase(Schema.getGlobalDescribe().get('sked_Drive_Shift__c').getDescribe().getKeyPrefix())){
                count_r = [ SELECT COUNT() FROM sked_Drive_Shift__c WHERE Id =: new_driveId];
                if(count_r > 0){
                    driveIdList.add(new_driveId);
                }
            }else if(new_driveId.substring(0,3).equalsIgnoreCase(Schema.getGlobalDescribe().get('sked_Drive__c').getDescribe().getKeyPrefix())){
                count_r = [ SELECT COUNT() FROM sked_Drive__c WHERE Id =: new_driveId LIMIT 1];
                if(count_r > 0){
                    Map<String, sked_Drive_Shift__c> sList = new Map<String, sked_Drive_Shift__c>([ SELECT Id FROM sked_Drive_Shift__c WHERE sked_Drive__c =: new_driveId]);
                    if(sList.size() > 0){
                        driveIdList = sList.keySet();
                    }
                }
            }else if(new_driveId.substring(0,3).equalsIgnoreCase(Schema.getGlobalDescribe().get('sked__Job__c').getDescribe().getKeyPrefix())){
                count_r = [ SELECT COUNT() FROM sked__Job__c WHERE Id =: new_driveId LIMIT 1];
                if(count_r > 0){
                    List<sked__Job__c> sList = [SELECT sked_Drive_Shift__c FROM sked__Job__c WHERE Id =: new_driveId];
                    if(sList.size() > 0){
                        driveIdList.add(String.valueOf(sList.get(0).sked_Drive_Shift__c));
                    }
                }
            }
        }
        return driveIdList;
    }
    @TestVisible
    private String dateFormat(date preDate){
        String result = '';
        if(preDate != null){
            DateTime dDate = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day());
            result = dDate.format('M/d/yyyy');
        }
        return result;
    }
    public PageReference doRedirectToSearch(){
        if(redirectToSearch == true){
            PageReference pr = new PageReference('/apex/DriveWorksheetReportVf');
            pr.setRedirect(true);
            return pr;
        }else{
           return null;
        }
    }
    /*
    * HRP-10127 Changes starts here 
    *
    @TestVisible
    private static Integer getTimeDifferenceInMinutes(Time startTime, Time endTime) {
        DateTime startDateTime = DateTime.newInstance(Date.today(), startTime);
        DateTime endDateTime = DateTime.newInstance(Date.today(), endTime);
        
        Long minutesDifference = (endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60);
        
        return Integer.valueOf(minutesDifference);
    }
    /*
    * HRP-10127 Changes ends here 
    */
}