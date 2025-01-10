/*
* Description: This class is called from DriveGeneratorService to create Drives on Calender records and captures the entire algorithm
** NOTE : Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification on DOC (11418)
* */

/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
  **************************************************************************
 * 06/12/2023                 Priti Jana             Logic for HRP-9901
 * 07/26/2023                 Krapy Tuli             Logic for HRP-10358
 * 07/26/2023                 Krapy Tuli             Logic for HRP-10474
 * 08/03/2023                 Priti Jana             Logic for HRP-10478
 * 08/09/2023                 Priti Jana             Logic for HRP-10667
 * 08/09/2023                 Krapy Tuli             Logic for HRP-10495
 * 29/09/2023                 Krapy Tuli             Logic for HRP-10846
 * 10/5/2023                  Priti Jana             Logic for HRP-11027
 * 10/20/2023                 Krapy Tuli             Logic for HRP-11226
 * 10/31/2023                 Priti Jana             Logic for HRP-11173
 * 11/15/2023                 Priti Jana             Logic for HRP-11046
 * 11/15/2023                 Priti Jana             Logic for HRP-11295
 * 11/20/2023                 Krapy Tuli             Logic for HRP-11419
 * 11/28/2023                 Krapy Tuli             Logic for HRP-11207
 * 12/11/2023                 Priti Jana             Logic for HRP-11653
 * 12/20/2023                 Krapy Tuli             Logic for HRP-11513
 * 1/15/2024                  Priti Jana             Logic for HRP-11418
 * 01/04/2024                 Krapy Tuli             Logic for HRP-11749
 * 02/12/2024                 Priti Jana             Logic for HRP-11443
 * 02/26/2024                 Krapy Tuli             Logic for HRP-12019
 * 06/05/2024                 Priti Jana             Logic for HRP-12597
 * 06/05/2024                 Priti Jana             Logic for HRP-11908
 * 06/06/2024                 Priti Jana             Logic for HRP-12011
 * 17/06/2024                 Barnojit Sharma        Logic for HRP-12738
 * 08/01/2024                 Priti Jana             Logic for HRP-10994
 * 08/09/2024                 Priti Jana             Logic for HRP-11634
 *******************************************************************************
*/
public with sharing class GenerateMobileDrive {
    public static Decimal otherResourceQuantityOne;
    public static Map<string, MobileDriveGeneratorDMLService.DMLRoleTimeDetail> map_resourceRoleGroup_roleTimeDetail = new Map<string, MobileDriveGeneratorDMLService.DMLRoleTimeDetail>();
    public static Map<string, List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>> map_resourceRoleGroup_roleTimeVariance = new Map<string, List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>>();
    public static List<DriveGenerationUtil.TimeConfigurationModel> timeConfig = new List<DriveGenerationUtil.TimeConfigurationModel>();
    public static Map<Id, MobileDriveGeneratorDMLService.DMLJobTag> mapSourceJobTag = new Map<Id, MobileDriveGeneratorDMLService.DMLJobTag>();
    public static Map<String, String> resourceRoleVsGroup = new Map<String, String>{'2RBC' => 'Staff roles','VP/HH' => 'Staff roles','Driver' => 'Driving roles','Driver Support' => 'Driving roles','Drive Lead' => 'Supervisory roles','Team Supervisor' => 'Supervisory roles','Charge' => 'Supervisory roles'}; // HRP-11295 (Added Drive Lead as Supervisory Role)
    public static List<String> resourceRoleGroups = new List<String>{'Staff roles','Driving roles', 'Supervisory roles'};
    public static DateTime nonResourceRoleJobFinishTime; // HRP-11295
    public static DateTime nonResourceRoleJobStartTime; // HRP-11295

    public static void generateDrives(MobileDriveGeneratorDMLService.driveGeneratorConfig config)
    {
        MobileDriveGeneratorDMLService.DMLData data = MobileDriveGeneratorDMLService.getDriveGenerationData(config);
        
        Map<string, driveGeneratorBase> mapDriveGenerator = new Map<string, driveGeneratorBase>();
        mapDriveGenerator.put(Constants.MOBILE_SITE_OPP, new mobileDriveGenerator());
        mapDriveGenerator.put(Constants.FIX_SITE_OPP, new mobileDriveGenerator());
        
        for (MobileDriveGeneratorDMLService.DMLDrive drive : data.drives) {
            driveGeneratorBase generator = mapDriveGenerator.get(drive.typeOfDrive);
            String customMsg = customMessage(data,drive);
            if(customMsg == 'No Error' || Test.isRunningTest()) {
                generator.generateDrive(data, drive);
            } else if(!String.isBlank(customMsg)) {
                // HRP-11027 --> Starts Here

                //CustomNotification.notifyUsers(new Set <String>{userInfo.getUserId()} , drive.opportunityId , 'Error!' , customMsg ); --> Commented out
                String targetId = String.valueOf(drive.opportunityId);
                DriveGenerationErrorHandler.notifyUsersUponFailureAndLogErrors(NULL, targetId, customMsg, Constants.DATA_ISSSUE, Constants.MOBILE_DRIVE_GENEERRATOR,Constants.MOBILE_DRIVE_GEN_METHOD);
                // HRP-11027 --> Ends Here
            }             
        }
        List<MobileDriveGeneratorDMLService.DMLDrive> drivesToSave = new List<MobileDriveGeneratorDMLService.DMLDrive>();
        for(MobileDriveGeneratorDMLService.DMLDrive dmlDrive : data.drives){
            if(!dmlDrive.hasError){
                drivesToSave.add(dmlDrive);
            }
        }
        if(drivesToSave.size() > 0) {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418
            
            MobileDriveGeneratorDMLService.saveDrives(drivesToSave);
            MobileDriveGeneratorDMLService.updateDriveGenerationStatus(drivesToSave);
        }
    }
    
    /*********************************************************** Custom Notification ***********************************************************/
   
    private static string customMessage(MobileDriveGeneratorDMLService.DMLData data,MobileDriveGeneratorDMLService.DMLDrive drive){
        Boolean isError = false;
        String errorMessage='';
        MobileDriveGeneratorDMLService.DMLLocation driveSite = data.mapLocation.get(drive.driveSiteId);

        // HRP-11027 (Added a custom msg if site is not present)
        if(driveSite == null){
            errorMessage += 'Site Not Found\n';
            isError = true;
        }

        if(driveSite.timezoneSidId == null){
            errorMessage += 'Site does not have Time Zone\n';
            isError = true;
        }
        if (driveSite.siteCollectionOperations != NULL) {
            for (MobileDriveGeneratorDMLService.DMLSiteCollectionOperation siteCollectionOperation : driveSite.siteCollectionOperations) {
                if (siteCollectionOperation.startDate <= drive.driveDate && drive.driveDate <= siteCollectionOperation.endDate) {
                    drive.collectionOperationId = siteCollectionOperation.collectionOperationId;
                    drive.collectionOperation = data.mapCollectionOperation.get(drive.collectionOperationId);
                }
            }
        }
        if(drive.collectionOperationId == null){
            errorMessage += 'Site do not have collection operation\n';
            isError = true;
        }else{
            if(drive.collectionOperation.maximumShiftLengthThreshold == null){
                errorMessage += 'Collection Operation maximumShiftLengthThreshold is null\n';
                isError = true;
            } if (drive.collectionOperation.breakdownTimeThreshold == null){
                errorMessage += 'Collection Operation breakdownTimeThreshold is null\n';
                isError = true;
            } if(drive.collectionOperation.setupTimeThreshold == null){
                errorMessage += 'Collection Operation setupTimeThreshold is null\n';
                isError = true;
            }if(drive.collectionOperation.unpaidLunchBreakDuration == null){
                errorMessage += 'Collection Operation unpaidLunchBreakDuration is null\n';
                isError = true;
            }if(drive.collectionOperation.lunchBreakDurationMobile == null){     	
                errorMessage += 'Collection Operation lunchBreakDurationMobile is null\n';	
                isError = true;	
            }	
        }

        MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix;
        for (MobileDriveGeneratorDMLService.DMLCollectionOperationSdm collectionOperationSdm : data.collectionOperationSdms) {
            if (collectionOperationSdm.collectionOperationId == drive.collectionOperationId
                && collectionOperationSdm.staffingDecisionMatrix.driveType == 'Mobile'
                && (collectionOperationSdm.effectiveStartDate == null || collectionOperationSdm.effectiveStartDate <= drive.driveDate)
                && (collectionOperationSdm.effectiveEndDate == null || drive.driveDate <= collectionOperationSdm.effectiveEndDate)){
                    matrix = collectionOperationSdm.staffingDecisionMatrix;
                }
        }

        if (matrix == null) {
            errorMessage += 'Matrix not found\n';
            isError = true;
        }else{
            if(matrix.nrVolunteerFixedSiteBandLower == null){
                errorMessage += 'Matrix FixedSiteBandLower is null\n';
                isError = true;
            }
            if(matrix.nrVolunteerFixedSiteBandUpper == null){
                errorMessage += 'Matrix FixedSiteBandUpper is null\n';
                isError = true;
            }
            if(matrix.driverSupportCapacity == null && drive.typeOfDrive == 'Mobile'){
                errorMessage += 'Matrix driverSupportCapacity is null\n';
                isError = true;
            }
            if(matrix.driverCapacity == null && drive.typeOfDrive == 'Mobile'){	
                errorMessage += 'Matrix driverCapacity is null\n';	
                isError = true;	
            }	
            if(matrix.vpHhCapacity == null){	
                errorMessage += 'Matrix vpHhCapacity is null\n';	
                isError = true;	
            }	
            if(matrix.chargeCapacity == null){	
                errorMessage += 'Matrix chargeCapacity is null\n';	
                isError = true;	
            }	
            if(matrix.x2RbcStaffCapacity == null){	
                errorMessage += 'Matrix x2RbcStaffCapacity is null\n';	
                isError = true;	
            }	
            if(matrix.chargeThreshold == null){	
                errorMessage += 'Matrix chargeThreshold is null\n';	
                isError = true;	
            }	
            if(matrix.teamSupervisorThreshold == null){	
                errorMessage += 'Matrix teamSupervisorThreshold is null\n';	
                isError = true;	
            }	
        }
        
        MobileDriveGeneratorDMLService.DMLVehicleList vehicle = data.map_coId_VehicleList.get(drive.collectionOperationId);	
        	
        if(vehicle == null || vehicle.vehicles.isEmpty() || Test.isRunningTest()){	
            vehicle = new MobileDriveGeneratorDMLService.DMLVehicleList(drive.collectionOperationId);	
            List<sked_Resource_Biomed_Collection_Op__c> secondaryColOps = data.map_coIdSecondary_VehicleList.containsKey(drive.collectionOperationId) ? data.map_coIdSecondary_VehicleList.get(drive.collectionOperationId) : new List<sked_Resource_Biomed_Collection_Op__c>();	
            if (secondaryColOps.size() > 0) {	
                for (sked_Resource_Biomed_Collection_Op__c secondaryColOp : secondaryColOps) {	
                    if ((secondaryColOp.sked_Start_Date__c == null || secondaryColOp.sked_Start_Date__c <= drive.driveDate) && (secondaryColOp.sked_End_Date__c == null || secondaryColOp.sked_End_Date__c >= drive.driveDate)) {	
                                         	
                        vehicle.collectionOperationId = drive.collectionOperationId;	
                        vehicle.vehicles.add(new MobileDriveGeneratorDMLService.DMLVehicle(new sked__Resource__c(Id = secondaryColOp.sked_Resource__c, sked_Pres_Donor_Capacity__c = secondaryColOp.sked_Resource__r.sked_Pres_Donor_Capacity__c)));	
                    }	
                }	
            }	
            if ((vehicle == null || vehicle.vehicles.isEmpty()) && data.map_resourceOverrides.containsKey(drive.collectionOperationId)) {	
                List<sked__Resource_Override__c> resOverride = data.map_resourceOverrides.get(drive.collectionOperationId);	
                for (sked__Resource_Override__c resOr : resOverride) {	
                    if (resOr.sked_Start_Date__c <= drive.driveDate && resOr.sked_End_Date__c >= drive.driveDate) {	
                        vehicle.collectionOperationId = drive.collectionOperationId;	
                        vehicle.vehicles.add(new MobileDriveGeneratorDMLService.DMLVehicle(new sked__Resource__c(Id = resOr.sked__Resource__c, sked_Pres_Donor_Capacity__c = resOr.sked__Resource__r.sked_Pres_Donor_Capacity__c)));	
                    }	
                }	
            }	
        } 	
        	
        /* HRP-11749 start	
        if (vehicle == null || vehicle.vehicles == null || vehicle.vehicles.size() == 0) {	
            errorMessage += 'Vehicle type resource is not available\n';	
            isError = true;	
        } HRP-11749 end */
                	
        if(isError){	
            drive.hasError = true;	
            return errorMessage;	
        }	
        else {	
            drive.hasError = false;	
            return 'No Error';  	
        }	
    }
    /*********************************************************** Nested classes ***********************************************************/
    public virtual class mobileDriveGenerator extends driveGeneratorBase {

        // HRP-11295 (Changed Return type of the method)
        protected List<MobileDriveGeneratorDMLService.DMLJob> populateDriveShiftJobs(MobileDriveGeneratorDMLService.DMLDrive drive, 
                                                                                    MobileDriveGeneratorDMLService.DMLDriveShift driveShift, 
                                                                                    DriveStaffingComplementModel staffingComplement, 
                                                                                    String typeOfDrive, 
                                                                                    Integer shiftCount, 
                                                                                    Boolean impactCO) {
    
            driveShift.jobs = new List<MobileDriveGeneratorDMLService.DMLJob>();
            if (staffingComplement.numberOfVehicles > 0 && shiftCount == 0 && typeOfDrive != Constants.FIX_SITE_OPP) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.assetType = Constants.JOB_TYPE_VEHICLE;
                job.type = Constants.JOB_TYPE_VEHICLE;
                job.quantity = staffingComplement.numberOfVehicles;
                driveShift.jobs.add(job);
            }
            
            if (staffingComplement.numberOf2rbcEquipments > 0 && shiftCount == 0) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.assetType = Constants.JOB_TYPE_EQUIPMENT;
                job.type = Constants.JOB_TYPE_EQUIPMENT;
                job.equipmentSubtype = '2RBC Asset';
                job.quantity = staffingComplement.numberOf2rbcEquipments;
                driveShift.jobs.add(job);
            }
            if (staffingComplement.numberOfDrivers > 0 && typeOfDrive != Constants.FIX_SITE_OPP) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.resourceRole = Constants.JOB_TYPE_DRIVER;
                job.type = Constants.JOB_TYPE_DRIVER;
                job.quantity = staffingComplement.numberOfDrivers;
                driveShift.jobs.add(job);
            }
            if (staffingComplement.numberOfDriverSupports > 0 && typeOfDrive != Constants.FIX_SITE_OPP) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.resourceRole = Constants.JOB_TYPE_DRIVER_SUPPORT;
                job.type = Constants.JOB_TYPE_DRIVER_SUPPORT;
                job.quantity = staffingComplement.numberOfDriverSupports;
                driveShift.jobs.add(job);
            }
            if (staffingComplement.numberOf2rbc > 0) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.resourceRole = Constants.PROCEDURE_TYPE_2RBC;
                job.type = Constants.PROCEDURE_TYPE_2RBC;
                job.quantity = staffingComplement.numberOf2rbc;
                driveShift.jobs.add(job);
            }
            if (staffingComplement.numberOfTeamSupervisors > 0) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.resourceRole = impactCO ? 'Drive Lead' : 'Team Supervisor'; //HRP-9945
                job.type = impactCO ? 'Drive Lead' : 'Team Supervisor'; //HRP-9945
                job.quantity = staffingComplement.numberOfTeamSupervisors;
                driveShift.jobs.add(job);
            }            
            if (staffingComplement.numberOfVphh > 0 || (staffingComplement.numberOfApt > 0)) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.resourceRole = Constants.JOB_TYPE_VP_HH;
                job.type = Constants.JOB_TYPE_VP_HH;
                job.quantity = staffingComplement.numberOfVphh + staffingComplement.numberOfApt;
                job.aptQuantity = staffingComplement.numberOfApt;
                job.vphhQuantity = staffingComplement.numberOfVphh;
                driveShift.jobs.add(job);
            }
            if (staffingComplement.numberOfCharge > 0) {
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.resourceRole = Constants.JOB_TYPE_CHARGE;
                job.type = Constants.JOB_TYPE_CHARGE;
                job.quantity = staffingComplement.numberOfCharge;
                driveShift.jobs.add(job);
            }
            //HRP-10358 Commented as we donot need Volunteer Donors for either WB or Mobile
            /*if (staffingComplement.numberOfVolunteerDonorAmbassadors > 0 && shiftCount == 0) { // not calculated for WB Non Integrated Fixed Site and mobile site
                MobileDriveGeneratorDMLService.DMLJob job = new MobileDriveGeneratorDMLService.DMLJob();
                job.driveSiteId = drive.driveSiteId;
                job.volunteerRole = 'Donor Ambassador';
                job.type = 'Donor Ambassador';
                job.redcrossVolunteerQuantity = staffingComplement.numberOfVolunteerDonorAmbassadors;
                job.sponsorVolunteerQuantity = 0;
                job.quantity = job.redcrossVolunteerQuantity + job.sponsorVolunteerQuantity;
                driveShift.jobs.add(job);
            }*/

            return driveShift.jobs; // HRP-11295
        }

        protected MobileDriveGeneratorDMLService.DMLDriveShift updateShiftMobileSetup(MobileDriveGeneratorDMLService.DMLDriveShift driveShift) {
            driveShift.vehiclesNeeded = 0;
            driveShift.equipment = 0;
            driveShift.staffSetup = 0;
            driveShift.volunteerSetup = 0;
            driveShift.aPTSetup = 0;
            otherResourceQuantityOne = 0;
            for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs) {
                // test
                if(!string.isBlank(job.resourcerole) && !(job.resourcerole == 'Team Supervisor')){
                    otherResourceQuantityOne += job.quantity;
                }
                if (!string.isBlank(job.resourceRole)) {
                    driveShift.staffSetup += job.quantity;
                    if (job.resourceRole == 'VP/HH') {
                        driveShift.aPTSetup += job.aptQuantity;
                        otherResourceQuantityOne -= job.aptQuantity;
                    }
                }
                if (!string.isBlank(job.volunteerRole)) {
                    driveShift.volunteerSetup += job.quantity;
                }
                else if (job.assetType == 'Vehicle') {
                    driveShift.vehiclesNeeded += job.quantity;
                }
                else if (job.assetType == 'Equipment') {
                    driveShift.equipment += job.quantity;
                }
            }
            return driveShift;
        }

        //HRP-11908 --> Starts Here
        protected override void calculateStaffComplement(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            applyRoleTimeDetails (data, drive);
        }
        //HRP-11908 --> Ends Here

        // HRP - 10478(1st Change)--> Starts here
        protected virtual MobileDriveGeneratorDMLService.DMLDriveShift generateShiftSlots(MobileDriveGeneratorDMLService.DMLData data, 
        MobileDriveGeneratorDMLService.DMLDrive drive, 
        MobileDriveGeneratorDMLService.DMLDriveShift driveShift, 
        Boolean isLastShift,
        Decimal staffCapacityValue)// HRP-10667
        {
            
            String timezoneSidId = driveShift.drive.timezoneSidId;

            //HRP-12011 --> starts Here
            Decimal paddingPercentage; 

            if(drive.slotGenerator != NULL) {
                paddingPercentage = drive.slotGenerator / 100;
            } else {
                slwcSetting.adminSetting skedAdminSetting = new slwcSetting.adminSetting();  // HRP-11443 --> Starts Here - Slot multiplier percentages have been made configurable and are taken from skedulo admin settings   
                paddingPercentage = skedAdminSetting.callListRecipient / 100;
                if (!drive.isCallListRecipientExist)
                {
                    paddingPercentage = skedAdminSetting.callListRecipientNone / 100;
                }
            }  
            // HRP-11443,12011 --> Ends Here

            // Calculation of Total Appointments = staff Capacity * paddingPercentage

            Decimal totalDefaultSlots = Math.ceil(staffCapacityValue*paddingPercentage); // HRP-10667
            
            Boolean reduceLastAppointmentSlot = false;

            driveShift.slots = new List<MobileDriveGeneratorDMLService.DMLSlot>();
            
            if (driveShift.jobs != NULL && !driveShift.jobs.isEmpty()) {
                MobileDriveGeneratorDMLService.DMLJob x2rbcJob;
                for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs) {
                    if (job.type == '2RBC') {                        
                        x2rbcJob = job;
                        break;
                    }
                }
                Decimal x2rbcResourceQuantity = x2rbcJob != NULL ? x2rbcJob.quantity : 0;
                Decimal driveShiftDrawHr = drive.drawHours / drive.noOfDriveShifts;   

                Decimal total2rbcSlots = Math.ceil( driveShiftDrawHr * 1 * (driveShift.numberOf2rbcEquipments != null ? driveShift.numberOf2rbcEquipments : 0));
                 
                slotGeneratorConfigModel x2rbcConfig = new slotGeneratorConfigModel();
                x2rbcConfig.interval = 60;
                x2rbcConfig.lastSlotStart = driveShift.drawEnd.addMinutes(-30);
                x2rbcConfig.rounds = new List<integer>();

                // two groups 
                x2rbcConfig.rounds.add(0);
                x2rbcConfig.rounds.add(30);               
                x2rbcConfig.slotDuration = 60; 
                x2rbcConfig.slotType = '2RBC';
                x2rbcConfig.startTime = driveShift.drawStart;
                x2rbcConfig.totalSlots = integer.valueOf(total2rbcSlots);
                x2rbcConfig.timezoneSidId = drive.timezoneSidId;	
                x2rbcConfig.driveEndTime = drive.drawEnd;

                // generate 2RBC appointment
                List<MobileDriveGeneratorDMLService.DMLSlot> x2rbcSlots = generateSlots(x2rbcConfig,reduceLastAppointmentSlot,isLastShift);

                integer wbSlotDuration = 15;
                slotGeneratorConfigModel wbConfig = new slotGeneratorConfigModel();
                wbConfig.interval = 60;
                wbConfig.lastSlotStart = driveShift.drawEnd;
                wbConfig.rounds = new List<integer>();
                
                // four groups 
                wbConfig.rounds.add(0);
                wbConfig.rounds.add(30);
                wbConfig.rounds.add(15);
                wbConfig.rounds.add(45);
                wbConfig.slotDuration = wbSlotDuration;
                wbConfig.slotType = 'Whole Blood';
                wbConfig.startTime = driveShift.drawStart;
                wbConfig.totalSlots = integer.valueOf(totalDefaultSlots - total2rbcSlots);
                wbConfig.timezoneSidId = drive.timezoneSidId;	
                wbConfig.driveEndTime = drive.drawEnd;
                MobileDriveGeneratorDMLService.DMLCollectionOperation coRec = data.mapCollectionOperation.get(drive.collectionOperationId);
                Boolean skipLastAppointment = !string.isBlank(coRec.skipLastAppointmentFor) && coRec.skipLastAppointmentFor.contains(drive.typeOfDrive);
                
                if (isLastShift && skipLastAppointment){
                    reduceLastAppointmentSlot = true;
                }
                
                // generate wb appointment
                List<MobileDriveGeneratorDMLService.DMLSlot> wbSlots = generateSlots(wbConfig,reduceLastAppointmentSlot,isLastShift);

                // Slot reduction logic - set reduction % 
                DriveStaffingComplementModel staffingComplement = new DriveStaffingComplementModel();
                decimal otherResourceQuantity = 0;
                
                if (driveShift.lunchBreak && !driveShift.lunchBreakBeforeDrawHours){
                    decimal coMaxLunchBreakDuration = drive.maximumLunchBreakDuration != NULL ? drive.maximumLunchBreakDuration : 30;
                    if (wbSlots != NULL && !wbSlots.isEmpty()){
                        
                        MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition = findLunchBreakDefinition(data, coMaxLunchBreakDuration, otherResourceQuantityOne, driveShift );
                        driveShift.signUpReduction = lunchBreakDefinition.slotReduction;
                    }
                    
                    DateTime lunchBreakEndTime = DateTime.newInstanceGMT(driveShift.driveDate, driveShift.lunchBreakEndTime);
                    lunchBreakEndTime = skedDateTimeUtils.switchTimezone(lunchBreakEndTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId); 
                    
                    DateTime lunchBreakStartTime = DateTime.newInstanceGMT(driveShift.driveDate, driveShift.lunchBreakStartTime);
                   
                    lunchBreakStartTime = skedDateTimeUtils.switchTimezone(lunchBreakStartTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId); 
                    if (wbSlots != NULL && !wbSlots.isEmpty()) {
                       
                        MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition = findLunchBreakDefinition(data, coMaxLunchBreakDuration, otherResourceQuantityOne, driveShift );
                        slotGeneratorConfigModel slotReductionConfiguration = new slotGeneratorConfigModel();
                        slotReductionConfiguration.endTime = lunchBreakEndTime;
                        slotReductionConfiguration.interval = 60;
                        slotReductionConfiguration.rounds = new List<integer>();
                        slotReductionConfiguration.rounds.add(0);
                        slotReductionConfiguration.rounds.add(30);
                        slotReductionConfiguration.rounds.add(15);
                        slotReductionConfiguration.rounds.add(45);
                        slotReductionConfiguration.slotReduction = integer.valueOf(lunchBreakDefinition.slotReduction);
                        slotReductionConfiguration.startTime = lunchBreakStartTime;
                        slotReductionConfiguration.timezoneSidId = drive.timezoneSidId;	
                        slotReductionConfiguration.driveDate = drive.driveDate;
                        if (driveShift.lunchBreak) {
                            reduceSlots(wbSlots, slotReductionConfiguration);
                        }
                    }                       
                }
                
                driveShift.default2rbcSlots = x2rbcSlots != NULL ? x2rbcSlots.size() : 0;
                driveShift.slots.addAll(x2rbcSlots);
                
                driveShift.defaultWbSlots = wbSlots != NULL ? wbSlots.size() : 0;
                driveShift.slots.addAll(wbSlots);
            }
            return driveShift;
        }

        protected virtual List<MobileDriveGeneratorDMLService.DMLSlot> generateSlots(slotGeneratorConfigModel configuration, Boolean reduceLastAppointmentSlot, Boolean isLastShift) {
            List<MobileDriveGeneratorDMLService.DMLSlot> slots = new List<MobileDriveGeneratorDMLService.DMLSlot>();
            integer roundCount = 1;
            integer slotCount = 0;
            integer numberOfRounds = configuration.rounds.size();
            if(reduceLastAppointmentSlot){
                configuration.lastSlotStart = configuration.lastSlotStart.addMinutes(-15);
            }
            while (slotCount < configuration.totalSlots) { 
                integer roundIndex = integer.valueOf(Math.mod(roundCount, numberOfRounds));
                roundIndex = (roundIndex == 0 ? configuration.rounds.size() : roundIndex) - 1; // 4
                DateTime firstSlotStart = configuration.startTime.addMinutes(configuration.rounds.get(roundIndex)); // add 0 min
                DateTime tempDt = firstSlotStart;
                while ((tempDt <= configuration.lastSlotStart && configuration.lastSlotStart == configuration.driveEndTime && configuration.slotType == 'Whole Blood') || 	
                (tempDt <= configuration.lastSlotStart && configuration.slotType == 'Whole Blood' && configuration.lastSlotStart != configuration.driveEndTime) || (tempDt <= configuration.lastSlotStart && configuration.slotType == '2RBC') ||
                tempDt < configuration.lastSlotStart && configuration.slotType == 'Whole Blood' && !isLastShift && configuration.lastSlotStart == configuration.driveEndTime){	
                    
                	MobileDriveGeneratorDMLService.DMLSlot slot = new MobileDriveGeneratorDMLService.DMLSlot();	
                    DateTime tempDtTimeZone = skedDateTimeUtils.switchTimezone(tempDt,TimeZone.getTimeZone('GMT').getId(),configuration.timezoneSidId);	
                    
                    slot.name = configuration.slotType;	
                    slot.label = '';	
                    slot.startTime = tempDtTimeZone;	
                    slot.endTime = tempDtTimeZone.addMinutes(configuration.slotDuration);                	
                    slot.startDate = tempDtTimeZone.date();	
                    slot.startTimeOnly = tempDtTimeZone.time();	
                    slot.endDate = slot.endTime.date();	
                    slot.endTimeOnly = slot.endTime.time();	
                    slot.locked = false;	
                    slot.slotType = configuration.slotType;	
                    slot.status = 'Open';	
                    slots.add(slot);	
                    slotCount++;
                    
                    if (slotCount == configuration.totalSlots) {	
                        break;	
                    }
                    
                    tempDt = tempDt.addMinutes(configuration.interval);
                    if(tempDt == configuration.lastSlotStart && !isLastShift && configuration.slotType == 'Whole Blood'){
                        break;
                    }
                }	
                roundCount++;	
            }	
            return slots;	
        }
         // HRP - 10478(1st Change)--> Ends here

        protected virtual DriveStaffingComplementModel calculateDriverQuantity(String typeOfDrive, DriveStaffingComplementModel staffingComplement) {
            staffingComplement.numberOfDrivers = typeOfDrive ==  Constants.FIX_SITE_OPP ? 0 : staffingComplement.numberOfVehicles;
            staffingComplement.map_role_resourceQuantity.put(Constants.JOB_TYPE_DRIVER, staffingComplement.numberOfDrivers); // HRP-11634
            return staffingComplement;
        }

        protected virtual DriveStaffingComplementModel calculateDriverSupportQuantity(String typeOfDrive, MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix, DriveStaffingComplementModel staffingComplement) {
            staffingComplement.numberOfDriverSupports = 0;
            if (matrix.driverSupportCapacity != NULL && matrix.driverSupportCapacity > 0) {
                staffingComplement.numberOfDriverSupports = typeOfDrive ==  Constants.FIX_SITE_OPP ? 0 : staffingComplement.numberOfVehicles;
            }
            staffingComplement.map_role_resourceQuantity.put(Constants.JOB_TYPE_DRIVER_SUPPORT, staffingComplement.numberOfDriverSupports); // HRP-11634
            return staffingComplement;
        }

        protected virtual DriveStaffingComplementModel calculate2rbcEquipmentQuantity(MobileDriveGeneratorDMLService.DMLDriveShift driveShift, DriveStaffingComplementModel staffingComplement, MobileDriveGeneratorDMLService.DMLDrive drive) {
            staffingComplement.numberOf2rbcEquipments = 0;
            Decimal noOf2RBCAssests = 0;

            // HRP-11173 (Added NULL Checks)
            if(!(drive.x2rbcProjectedProcedures == 0 || drive.x2rbcProjectedProcedures == NULL)) {
                if (driveShift.drawHours > 1) {
            	    noOf2RBCAssests = Math.ceil( (Decimal)driveShift.x2rbcProjectedProcedures / (driveShift.drawHours));
                    if(noOf2RBCAssests < 1) {
                        noOf2RBCAssests = 1;
                    }
            	    staffingComplement.numberOf2rbcEquipments = noOf2RBCAssests;
                    driveShift.numberOf2rbcEquipments = staffingComplement.numberOf2rbcEquipments; 
                }
                staffingComplement.numberOf2rbc = Math.ceil(staffingComplement.numberOf2rbcEquipments / 2);
            } else {
                driveShift.numberOf2rbcEquipments = 0;
            }
           
            drive.numberOf2rbcEquipments = staffingComplement.numberOf2rbcEquipments; 
            staffingComplement.map_role_resourceQuantity.put(Constants.PROCEDURE_TYPE_2RBC, staffingComplement.numberOf2rbc);
            return staffingComplement;
        }

        protected virtual DriveStaffingComplementModel calculateTeamSupervisorQuantity(MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix, MobileDriveGeneratorDMLService.DMLDriveShift driveShift, MobileDriveGeneratorDMLService.DMLDrive drive, DriveStaffingComplementModel staffingComplement) {	
            staffingComplement.numberOfTeamSupervisors = 0;
            if (driveShift.totalProceduresProjected >= matrix.teamSupervisorThreshold) {
                if (drive.driveSite.physicalLocationType.contains(Constants.DRIVE_LOCATION_INSIDE)) {	
                    staffingComplement.numberOfTeamSupervisors = 1;	
                }	
            }
            return staffingComplement;
        }

        protected virtual DriveStaffingComplementModel calculateVpHhQuantity(
            MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix, 
            MobileDriveGeneratorDMLService.DMLDriveShift driveShift, 
            MobileDriveGeneratorDMLService.DMLDrive drive, 
            DriveStaffingComplementModel staffingComplement
        ) {	
            staffingComplement.numberOfVphh = 0;	
            staffingComplement.numberOfApt = 0;
            Decimal donorProcessingCapacityWithoutVpHhCharge = 0;	

            //HRP-10474 Start
            Decimal drawHours = driveShift.drawHours;
            if(driveShift.lunchBreak && (!drive.collectionOperation.lunchBreakBeforeDrawHours)) {
                drawHours = driveShift.drawHourswithLunchBreak != null ? driveShift.drawHourswithLunchBreak : drawHours;
            }
            Decimal staffCapacity = calculateStaffCapacity(
                new List<String>{'Driver', 'Driver Support', '2RBC', 'Charge'},
                staffingComplement,
                drive,
                driveShift,
                matrix,
                false 
            ); // HRP-11634
            if (driveShift.projectedRegisteredDonors > staffCapacity) {
                staffingComplement.numberOfVphh = Math.ceil((driveShift.projectedRegisteredDonors - staffCapacity) / (matrix.vpHhCapacity * drawHours));	
            }
            //staffingComplement.numberOfApt = drive.account.aptRequired ? 1 : staffingComplement.numberOfApt; //HRP-10474
            staffingComplement.numberOfApt = drive.aptRequired ? drive.aptQuantity : staffingComplement.numberOfApt; //HRP-13190
            return staffingComplement;
        }

        protected virtual DriveStaffingComplementModel calculateChargeQuantity(MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix, MobileDriveGeneratorDMLService.DMLDrive drive, MobileDriveGeneratorDMLService.DMLDriveShift driveShift, DriveStaffingComplementModel staffingComplement) {
            staffingComplement.numberOfCharge = 0;
            // HRP-11173 --> Added NULL Checks --> Starts Here
            Decimal noOfDrivers = staffingComplement.numberOfDrivers!= NULL ? staffingComplement.numberOfDrivers : 0;
            Decimal noOfDriverSupports = staffingComplement.numberOfDriverSupports != NULL ? staffingComplement.numberOfDriverSupports : 0;
            Decimal noOf2rbc = staffingComplement.numberOf2rbc != NULL ? staffingComplement.numberOf2rbc : 0;
            Decimal noOfVpHh = staffingComplement.numberOfVphh != NULL ? staffingComplement.numberOfVphh : 0;
            Decimal noOfTeamSup = staffingComplement.numberOfTeamSupervisors != NULL ? staffingComplement.numberOfTeamSupervisors : 0;

            decimal totalQtyWithoutCharge = noOfDrivers 
                        + noOfDriverSupports
                        + noOf2rbc
                        + noOfVpHh;
            
            decimal noOfLeaders = Math.ceil(totalQtyWithoutCharge / 11);  
            staffingComplement.numberOfCharge = noOfLeaders - noOfTeamSup;
            staffingComplement.map_role_resourceQuantity.put(Constants.JOB_TYPE_CHARGE, staffingComplement.numberOfCharge); // HRP-11634

            // HRP-11634 --> Starts Here
            if (staffingComplement.numberOfCharge > 0) {
                staffingComplement = calculateVpHhQuantity(matrix, driveShift, drive, staffingComplement);
            }
            staffingComplement.map_role_resourceQuantity.put(Constants.JOB_TYPE_VP_HH, staffingComplement.numberOfVphh);
            // HRP-11634 --> Ends Here

            return staffingComplement;
        }

        // HRP-11634 --> Starts Here (Changed input parameters and restructured following method)
        protected Decimal calculateStaffCapacity(
            List<String> capacityNeededFor,
            DriveStaffingComplementModel staffingComplement,
            MobileDriveGeneratorDMLService.DMLDrive drive, 
            MobileDriveGeneratorDMLService.DMLDriveShift driveShift, 
            MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix,
            Boolean isCalculatedForWBSlots // HRP-10667
       ) { 
            Decimal staffCapacity = 0;
            Map<string, decimal> donorCapacityMap = new Map<string, decimal>();
            donorCapacityMap.put(Constants.JOB_TYPE_DRIVER, matrix.driverCapacity != NULL ? matrix.driverCapacity : 0);
            donorCapacityMap.put(Constants.JOB_TYPE_DRIVER_SUPPORT, matrix.driverSupportCapacity != NULL ? matrix.driverSupportCapacity : 0);
            donorCapacityMap.put(Constants.PROCEDURE_TYPE_2RBC, matrix.x2RbcStaffCapacity != NULL ? matrix.x2RbcStaffCapacity : 0);
            donorCapacityMap.put(Constants.JOB_TYPE_VP_HH, matrix.vpHhCapacity != NULL ? matrix.vpHhCapacity : 0);
            donorCapacityMap.put(Constants.JOB_TYPE_CHARGE, matrix.chargeCapacity != NULL ? matrix.chargeCapacity : 0);
            
            //HRP-10474 Start
            decimal drawHours = driveShift.drawHours;
            if(driveShift.lunchBreak && (!drive.collectionOperation.lunchBreakBeforeDrawHours && isCalculatedForWBSlots == false)) // HRP-10667
            {
                drawHours = driveShift.drawHourswithLunchBreak != null ? driveShift.drawHourswithLunchBreak : drawHours;
            }
            //HRP-10474 End
            
            for (String role : capacityNeededFor) {
                Decimal sdmRoleCapacity = donorCapacityMap.containsKey(role) && donorCapacityMap.get(role) != NULL ? donorCapacityMap.get(role) : 0;
                Decimal resourceQuantity = staffingComplement.map_role_resourceQuantity.containsKey(role) && staffingComplement.map_role_resourceQuantity.get(role) != NULL ? staffingComplement.map_role_resourceQuantity.get(role) : 0;
                if (role.equalsIgnorecase(Constants.PROCEDURE_TYPE_2RBC)) {
                    Decimal noOf2RBCAssets = driveShift.numberOf2rbcEquipments;
                    Decimal noOfResourcesHaveEnough2RBCAssets = Math.min(resourceQuantity, Math.floor(noOf2RBCAssets / 2));
                    Decimal noOfResourcesNotHaveEnough2RBCAssets = Math.max(resourceQuantity - noOfResourcesHaveEnough2RBCAssets, 0);
                    Decimal capacity1 = noOfResourcesHaveEnough2RBCAssets * 2 * driveShift.drawHours;
                    Decimal capacity2 = noOfResourcesNotHaveEnough2RBCAssets * sdmRoleCapacity * driveShift.drawHours;
                    staffCapacity += capacity1 + capacity2;
                } else {
                    staffCapacity += resourceQuantity * sdmRoleCapacity *  drawHours;
                }                       
            }
            return staffCapacity;
        }
        // HRP-11634 --> Ends Here

        protected virtual void calculateDriveShifts(
            MobileDriveGeneratorDMLService.DMLData data, 
            MobileDriveGeneratorDMLService.DMLDrive drive, 
            List<DriveGenerationUtil.TimeConfigurationModel> timeConfig,
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel
        ) { 
            Decimal maxDurationBefore = 0;
            Decimal maxDurationAfter = 0;
            Decimal projectedRegDonors = drive.projectedRegisteredDonors != null ? drive.projectedRegisteredDonors : 0;
            Decimal wbPrjPrcOfDrive = drive.wbProjectedProcedures ;
            Decimal doublerbcPrjPrcOfDrive = drive.x2rbcProjectedProcedures != NULL ? drive.x2rbcProjectedProcedures : 0;
            Decimal maxProjectedRegisteredDonors = 0;
            for (DriveGenerationUtil.TimeConfigurationModel config : timeConfig) {
                Decimal durationBefore = config.leadTime + config.setupTime + config.siteLogisticsTo; //HRP-11226
                Decimal durationAfter = config.breakDownTime + config.wrapUpTime + config.siteLogisticsBack; //HRP-11226

                 // HRP-11908/12597 --> Starts Here (AC #6)
                 if(drive.typeOfDrive.equalsIgnorecase(Constants.MOBILE_SITE_OPP)) {
                    durationBefore += config.travelTime;
                    durationAfter += config.travelTime2;
                }
                //HRP-11908/12597 --> Ends Here

                maxDurationBefore = (durationBefore > maxDurationBefore ? durationBefore : maxDurationBefore);
                maxDurationAfter = (durationAfter > maxDurationAfter ? durationAfter : maxDurationAfter);
            }

            Decimal driveLength = (drive.drawHours*60) + maxDurationAfter + maxDurationBefore;
            Decimal noOfDriveShifts = Math.ceil(driveLength / drive.collectionOperation.maximumShiftLengthThreshold);
            decimal coMaxLunchBreakDuration = drive.maximumLunchBreakDuration != NULL ? drive.maximumLunchBreakDuration : 30;
            MobileDriveGeneratorDMLService.DMLLunchBreakSetting lunchBreakSetting;
            for (MobileDriveGeneratorDMLService.DMLLunchBreakSetting setting : data.lunchBreakSettings) {
                if (setting.maximumLunchBreakDuration == coMaxLunchBreakDuration) {
                    lunchBreakSetting = setting;
                    break;
                }
            }            
            Integer driveshiftlength = Integer.valueOf(noOfDriveShifts);
            decimal drawDurationPerShift = Math.ceil(drive.drawDuration / noOfDriveShifts);
            integer timeStep = 15;
            decimal redudantDuration = Math.mod(integer.valueOf(drawDurationPerShift), timeStep);
            if (redudantduration != 0) {
                drawDurationPerShift = (Math.floor(drawDurationPerShift / timeStep) + 1) * timeStep;
            }
            List<MobileDriveGeneratorDMLService.DMLDriveShift> driveShifts = new List<MobileDriveGeneratorDMLService.DMLDriveShift>();
            for (Integer i=0; i<noOfDriveShifts; i++) {
                MobileDriveGeneratorDMLService.DMLDriveShift driveShift = new MobileDriveGeneratorDMLService.DMLDriveShift();
                DateTime drawHoursStart, drawHoursEnd;
                if (i == 0) {
                    drawHoursStart = drive.drawStart;
                }else {
                    MobileDriveGeneratorDMLService.DMLDriveShift previousDriveShift = driveShifts.get(i - 1);
                    drawHoursStart = previousDriveShift.drawEnd;
                }
                if (i < noOfDriveShifts - 1) {
                    drawHoursEnd = drawHoursStart.addMinutes(integer.valueOf(drawDurationPerShift));
                }else {
                    decimal remainDuration = drive.drawDuration - drawDurationPerShift * (noOfDriveShifts - 1);
                    drawHoursEnd = drawHoursStart.addMinutes(integer.valueOf(remainDuration));
                }
                driveShift.drive = drive;
                driveShift.driveDate = drive.driveDate;
                driveShift.drawStart = drawHoursStart;
                driveShift.startTime = drawHoursStart.timeGMT();
                driveShift.drawEnd = drawHoursEnd;
                driveShift.endTime = drawHoursEnd.timeGMT();
                driveShift.lunchBreak = false;
                driveShift.drawDuration = skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd);
                driveShift.drawHours = driveShift.drawDuration / 60;
            
                // calculating projected registered donors for Drive shift
                Decimal divDec = projectedRegDonors.divide(driveshiftlength, 2, System.RoundingMode.UP);                    
                driveShift.projectedRegisteredDonors = Math.ceil(divDec) ;
                driveShift.donorsScheduled = Math.ceil(divDec) ;
                projectedRegDonors = projectedRegDonors - driveShift.projectedRegisteredDonors ;

                // populate WB,2RBC projected procedures
                Decimal wbdivDec = wbPrjPrcOfDrive.divide(driveshiftlength, 2, System.RoundingMode.UP);                    
                driveShift.wbProjectedProcedures = Math.ceil(wbdivDec) ;                    
                wbPrjPrcOfDrive = wbPrjPrcOfDrive - driveShift.wbProjectedProcedures ;
                Decimal doubleReddivDec = doublerbcPrjPrcOfDrive.divide(driveshiftlength, 2, System.RoundingMode.UP);                    
                driveShift.x2rbcProjectedProcedures = Math.ceil(doubleReddivDec) ;                    
                doublerbcPrjPrcOfDrive = doublerbcPrjPrcOfDrive - driveShift.x2rbcProjectedProcedures ;
                driveShift.totalProceduresProjected = driveShift.x2rbcProjectedProcedures + driveShift.wbProjectedProcedures;
                driveShift.totalProductsProjected = driveShift.x2rbcProjectedProcedures * 2 + driveShift.wbProjectedProcedures;
                maxProjectedRegisteredDonors = driveShift.projectedRegisteredDonors > maxProjectedRegisteredDonors ? driveShift.projectedRegisteredDonors : maxProjectedRegisteredDonors;
                driveShift = applyRoleTimeDetailOnDriveShift (data, drive, driveShift, i, Integer.valueOf(noOfDriveShifts), timeConfig, travelTimeModel);
                driveShift = calculateLunchBreak (driveShift, drive, lunchBreakSetting);
                driveShifts.add(driveShift);
                driveshiftlength = driveshiftlength-1;
            }
            
			drive.noOfDriveShifts = Integer.valueOf(noOfDriveShifts);
            List<MobileDriveGeneratorDMLService.DMLVehicle> suggestedVehicles = calculateGhostVehicles (data, drive, maxProjectedRegisteredDonors); 
            MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix = getStaffingDecisionMatrix(data, drive);
            filterJobTags (drive);

            Integer shiftCount = 0;
            Decimal staffCapacityForWBSlotsCalc = 0;

            // HRP-11295 --> Starts Here
            Integer noOfShifts = Integer.valueOf(noOfDriveShifts);
            List<MobileDriveGeneratorDMLService.DMLJob> jobList = new List<MobileDriveGeneratorDMLService.DMLJob>();
            // HRP-11295 --> Ends Here

            for (MobileDriveGeneratorDMLService.DMLDriveShift driveShift :  driveShifts) {
                DriveStaffingComplementModel staffingComplement = new DriveStaffingComplementModel();
                staffingComplement.numberOfVehicles = suggestedVehicles.size() > 0 ? suggestedVehicles.size() : 1; //HRP-11749
                staffingComplement.opportunityId = drive.opportunityId;
                staffingComplement.success = FALSE;
                staffingComplement = calculateJobQuantity (staffingComplement, driveShift, drive.typeOfDrive, matrix, drive);
                driveShift.jobs = populateDriveShiftJobs (drive, driveShift, staffingComplement, drive.typeOfDrive, shiftCount, drive.impactCO); // HRP-11295
                jobList.addAll(driveShift.jobs); // HRP-11295
                driveShift = updateShiftMobileSetup(driveShift);
                driveShift = populateDriveShiftTags (drive, driveShift);
                driveShift = populateJobTags (drive,driveShift); // HRP-11295 (Changed method parameters)
                driveShift.jobs = applyRoleTimeForDriveShiftJob(data, drive, driveShift, travelTimeModel); //HRP-11908
                driveShift = populateLunchBreakTime(data, drive, driveShift);

               // HRP-11295 --> Start
               driveShift = populateShiftTime (data, drive, driveShift, shiftCount,  drive.noOfDriveShifts);
               if(shiftCount ==  drive.noOfDriveShifts - 1) {
                   populateJobTimingsForEquipmentAndVehicle(drive,jobList);
               }
               // HRP-11295 --> End
               
               // HRP-11634 --> Starts Here (Changed input parameters)
			   driveShift.staffCapacity = Math.floor(calculateStaffCapacity (
                    new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'},
                    staffingComplement,
                    drive, 
                    driveShift, 
                    matrix,
                    false
                ));
                drive.staffCapacity = drive.staffCapacity != null ?  drive.staffCapacity : 0;
                drive.staffCapacity += driveShift.staffCapacity;
                drive.totalStaffRequested = drive.totalStaffRequested != NULL ? drive.totalStaffRequested + driveShift.staffSetup : driveShift.staffSetup; //HRP-10994

                // HRP-10667 --> Starts here
                staffCapacityForWBSlotsCalc = Math.floor(calculateStaffCapacity (
                    new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'},
                    staffingComplement,
                    drive, 
                    driveShift, 
                    matrix, 
                    true
                ));
                // HRP-11634 --> Ends Here (Changed input parameters)

                driveShift = generateShiftSlots (data, drive, driveShift, shiftCount == noOfDriveShifts - 1 ? true : false, staffCapacityForWBSlotsCalc);
                shiftCount++;
            }
            drive.driveShifts = driveShifts;
            drive = calculateAverageStaffCapacity(drive); //HRP-10994
            drive = calculateExcessStaffCapacity(drive); //HRP-10994
            drive = calculateDriveProductivityPlanned(drive);
        }
        
        // HRP-10994 --> Starts Here
        protected virtual MobileDriveGeneratorDMLService.DMLDrive calculateAverageStaffCapacity(MobileDriveGeneratorDMLService.DMLDrive drive) {
            drive.averageStaffCapacity = (drive.staffCapacity / drive.totalStaffRequested).setScale(1);
            return drive;
        }

        protected virtual MobileDriveGeneratorDMLService.DMLDrive calculateExcessStaffCapacity(MobileDriveGeneratorDMLService.DMLDrive drive) {
            drive.excessStaffCapacity = ((drive.staffCapacity - drive.projectedRegisteredDonors) / drive.averageStaffCapacity).setScale(1);
            return drive;
        }
        // HRP-10994 --> Ends Here

        protected virtual void generateTimeConfiguration(
            MobileDriveGeneratorDMLService.DMLData data, 
            MobileDriveGeneratorDMLService.DMLDrive drive, 
            Map<string, MobileDriveGeneratorDMLService.DMLRoleTimeDetail> map_resourceRoleGroup_roleTimeDetail, 
            Map<string, List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>> map_resourceRoleGroup_roleTimeVariance,
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel
        ) { 
            timeConfig = new List<DriveGenerationUtil.TimeConfigurationModel>();

            if(map_resourceRoleGroup_roleTimeDetail != NULL) { 
                for (String resourceRoleGroup : data.resourceRoleGroups) {
                    DriveGenerationUtil.TimeConfigurationModel config = new DriveGenerationUtil.TimeConfigurationModel();
                    config.resourceRoleGroup = resourceRoleGroup;
                    if (map_resourceRoleGroup_roleTimeDetail.containsKey(resourceRoleGroup)) {
                        config.leadTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).leadTime != NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).leadTime : 0;
                        config.setupTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).setupTime!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).setupTime : 0;
                        config.breakDownTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).breakdownTime!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).breakdownTime : 0;
                        config.wrapUpTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).wrapUpTime!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).wrapUpTime : 0;
                        config.siteLogisticsTo = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsTo!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsTo : 0; //HRP-11226
                        config.siteLogisticsBack = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsBack!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsBack : 0; //HRP-11226
                    }
        
                    // HRP-11027 --> Ends Here (First Change)
                    List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance> roleTimeVariances = new List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>();
                    if(!map_resourceRoleGroup_roleTimeVariance.isEmpty() && map_resourceRoleGroup_roleTimeVariance.get(resourceRoleGroup)!= NULL){
                        roleTimeVariances = map_resourceRoleGroup_roleTimeVariance.get(resourceRoleGroup);
                    }
                    if(roleTimeVariances.size() > 0) {
                        for (MobileDriveGeneratorDMLService.DMLRoleTimeVariance roleTimeVariance : roleTimeVariances) {
                            decimal amount = roleTimeVariance.varianceAmount;
                            Set<string> appliesTo = new Set<string>();
                            appliesTo.addAll(roleTimeVariance.varianceAppliesTo.split(';'));
                            if (roleTimeVariance.bufferType == 'Subtract') {
                                amount = -1 * amount;
                            }
                            // HRP-11027 --> Starts Here (2nd Change -> If leadTime/setuptime/breakdowntime/wrapuptime/traveltimes = 0, no need to add variance)
                            if (appliesTo.contains('Lead Time')) 
                            {
                                config.leadTime += amount;
                            }
                            if (appliesTo.contains('Setup Time'))
                            {
                                config.setupTime += amount;
                            }
                            if (appliesTo.contains('Breakdown Time'))
                            {
                                config.breakdownTime += amount;
                            }
                            if (appliesTo.contains('Wrap-up Time'))
                            {
                                config.wrapUpTime += amount;
                            }
                            if (appliesTo.contains('Travel Time To')  && (!travelTimeModel.isNoTravelTimeChecked || resourceRoleGroup.equalsIgnorecase('Driving roles'))) //HRP-11908
                            {
                                config.travelTimeCoToSiteVariance += amount;
                            }
                            if (appliesTo.contains('Travel Time From')  && (!travelTimeModel.isNoTravelTimeChecked || resourceRoleGroup.equalsIgnorecase('Driving roles'))) //HRP-11908
                            {
                                config.travelTimeSiteToCoVariance += amount;
                            }
                            if (appliesTo.contains('Site Logistics To')) //HRP-11226 start
                            {
                                config.siteLogisticsTo += amount;
                            }
                            if (appliesTo.contains('Site Logistics Back'))
                            {
                                config.siteLogisticsBack += amount;
                            } //HRP-11226 end
                        }
                            // HRP-11027 --> Ends Here (2nd Change)
                    }

                    //HRP-11908 --> Starts Here
                    getTravelTimeFromTravelTimeIndex(data, drive, new MobileDriveGeneratorDMLService.DMLDriveShift(), travelTimeModel, config, FALSE);
                    if(travelTimeModel.resourceRoleGroupsNeededTravelTime.contains(resourceRoleGroup)) {
                        config.travelTime = travelTimeModel.travelTimeCOToSite;
                        config.travelTime2 = travelTimeModel.travelTimeSiteToCO;
                    }
                    config.travelTime += config.travelTimeCoToSiteVariance;
                    config.travelTime2 += config.travelTimeSiteToCoVariance;
                    config = compareAndAdjustTimeConfiguration(config);
                    timeConfig.add(config);
                }
            }
            calculateDriveShifts (data, drive, timeConfig, travelTimeModel);
            //HRP-11908 --> Ends Here
        }

        protected virtual DriveStaffingComplementModel calculateJobQuantity (DriveStaffingComplementModel staffingComplement, MobileDriveGeneratorDMLService.DMLDriveShift driveShift, String typeOfDrive, MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix, MobileDriveGeneratorDMLService.DMLDrive drive) {
            staffingComplement = calculateDriverQuantity (typeOfDrive, staffingComplement);
            staffingComplement = calculateDriverSupportQuantity (typeOfDrive, matrix, staffingComplement);
            staffingComplement = calculate2rbcEquipmentQuantity (driveShift, staffingComplement, drive);
            staffingComplement = calculateTeamSupervisorQuantity (matrix, driveShift, drive, staffingComplement);
            staffingComplement = calculateVpHhQuantity (matrix, driveShift, drive, staffingComplement);
            staffingComplement = calculateChargeQuantity (matrix, drive, driveShift, staffingComplement);
            //staffingComplement = calculateVolunteerDonorAmbassdorQuantity (matrix, drive, driveShift, staffingComplement); //HRP-10358 Commented as we donot need Volunteer Donors for either WB or Mobile
            return staffingComplement;
        }

        protected virtual void applyRoleTimeDetails(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) { 
            map_resourceRoleGroup_roleTimeDetail = reduceMapRoleTimeDetailByDrive(data, drive);
            map_resourceRoleGroup_roleTimeVariance = reduceMapRoleTimeVarianceByDrive(data, drive);
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel = getTravelTimeSpecificInfo(data, drive); //HRP-11908
            generateTimeConfiguration (data, drive, map_resourceRoleGroup_roleTimeDetail, map_resourceRoleGroup_roleTimeVariance, travelTimeModel);
        }
    }

    public virtual class driveGeneratorBase {
        protected virtual void calculateStaffComplement(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) { }

        public void generateDrive(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            prepareDriveData(data, drive);
        }

        protected virtual void prepareDriveData(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            MobileDriveGeneratorDMLService.DMLAccount account = data.mapAccount.get(drive.accountId);
            drive.account = account;
            MobileDriveGeneratorDMLService.DMLLocation driveSite = data.mapLocation.get(drive.driveSiteId);
            drive.driveSite = driveSite;
            MobileDriveGeneratorDMLService.DMLCollectionOperation collectionOperation;
            if (driveSite.siteCollectionOperations != NULL) {
                for (MobileDriveGeneratorDMLService.DMLSiteCollectionOperation siteCollectionOperation : driveSite.siteCollectionOperations) {
                    if (siteCollectionOperation.startDate <= drive.driveDate && drive.driveDate <= siteCollectionOperation.endDate) {
                        drive.collectionOperationId = siteCollectionOperation.collectionOperationId;
                        drive.siteCollectionOperationId = siteCollectionOperation.Id;
                        drive.siteCollectionOperation = siteCollectionOperation;
                        drive.collectionOperation = data.mapCollectionOperation.get(drive.collectionOperationId);
                       
                        //HRP-9945 
                        drive.impactCO = drive.collectionOperation.impact && (drive.collectionOperation.impactStartDate == null || drive.driveDate >= drive.collectionOperation.impactStartDate) && (drive.collectionOperation.impactEndDate == null || drive.driveDate <= drive.collectionOperation.impactEndDate);
                        break;
                    }
                }
            }
            if( ( drive.driveSite.siteOperationType == 'Non Integrated WB' && drive.typeOfDrive == 'Fixed Site' ) || drive.typeOfDrive == 'Mobile' ) // HRP - 9901
            {       
                if(drive.collectionOperation != NULL){   
            	    drive.maximumLunchBreakDuration = drive.collectionOperation.lunchBreakDurationMobile;
                }
            }
            if (drive.collectionOperationId != null && data.mapCoIdVsStagingLocations.containsKey(drive.collectionOperationId))
            {
                for (sked_Collection_Op_Staging_Location__c sloc : data.mapCoIdVsStagingLocations.get(drive.collectionOperationId)) {
                    if (sloc.sked_Start_Date__c <= drive.driveDate && drive.driveDate <= sloc.sked_End_Date__c) {
                        drive.coStagingLocation = sloc;
                        drive.stagingLocation = sloc.sked_Staging_Location__c; //HRP-11653
                        break;
                    }
                }
            }
            drive.timezoneSidId = driveSite.timezoneSidId;
            drive.drawStart = DateTime.newInstanceGMT(drive.driveDate, drive.startTime);
            drive.drawEnd = DateTime.newInstanceGMT(drive.driveDate, drive.endTime);
            drive.drawDuration = skedDateTimeUtils.getDifferentMinutes(drive.drawStart, drive.drawEnd);
            drive.drawHours = drive.drawDuration / 60;
           calculateTotalProceduresAndProductProjected (data, drive);
           calculateStaffComplement(data, drive); //HRP-11908
        }

        protected virtual void calculateTotalProceduresAndProductProjected(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) { 
            decimal x2rbcProjectedProcedures = drive.x2rbcProjectedProcedures != NULL ? drive.x2rbcProjectedProcedures : 0;
            decimal wbProjectedProcedures = drive.wbProjectedProcedures != NULL ? drive.wbProjectedProcedures : 0;
            drive.totalProceduresProjected = x2rbcProjectedProcedures + wbProjectedProcedures;
            drive.totalProductsProjected = x2rbcProjectedProcedures * 2 + wbProjectedProcedures;
        }
        
        protected Map<string, MobileDriveGeneratorDMLService.DMLRoleTimeDetail> reduceMapRoleTimeDetailByDrive(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            Map<string, MobileDriveGeneratorDMLService.DMLRoleTimeDetail> roleTimeDetailMap = new Map<string, MobileDriveGeneratorDMLService.DMLRoleTimeDetail>();
            for (MobileDriveGeneratorDMLService.DMLRoleTimeDetail roleTimeDetail : data.roleTimeDetails)
            {
                // HRP-11295 - Restructered valid RTD formula to incorporate changes for this ticket
                boolean isValid = ((roleTimeDetail.driveType == Constants.MOBILE_SITE_OPP && drive.typeOfDrive == Constants.MOBILE_SITE_OPP) //HRP-10474
                    || (roleTimeDetail.driveType == Constants.FIX_SITE_OPP 
                        && roleTimeDetail.fixedSiteOperationType == Constants.NON_INTEGRATED_WB_OPERATION_TYPE
                        && drive.typeOfDrive == Constants.FIX_SITE_OPP
                        && drive.driveSite.siteOperationType == Constants.NON_INTEGRATED_WB_OPERATION_TYPE))
                    && (roleTimeDetail.effectiveStartDate <= drive.driveDate)
                    && ((roleTimeDetail.effectiveEndDate == null) ||(roleTimeDetail.effectiveEndDate >= drive.driveDate))
                    && (!roleTimeDetail.daysOfWeek.isEmpty() && roleTimeDetail.daysOfWeek.contains(drive.driveDay)) //HRP-9943
                    && roleTimeDetail.mobileType == drive.driveSite.physicalLocationType;

                if (isValid)
                {
                    for (string detailResourceRoleGroup : roleTimeDetail.resourceRoleGroups) {
                        if ((roleTimeDetail.type == 'Collection Operation' && roleTimeDetail.collectionOperationId == drive.collectionOperationId) 
                        || (roleTimeDetail.type == 'Global' && !roleTimeDetailMap.containsKey(detailResourceRoleGroup))) {
                            roleTimeDetailMap.put(detailResourceRoleGroup, roleTimeDetail);
                        }
                    }
                }
            }
            return roleTimeDetailMap;
        }

        protected Map<string, List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>> reduceMapRoleTimeVarianceByDrive(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            Map<string, List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>> roleTimeVarianceMap = new Map<string, List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>>();
            for (MobileDriveGeneratorDMLService.DMLRoleTimeVariance roleTimeVariance : data.roleTimeVariances) {
               
                for (string varianceResourceRoleGroup : roleTimeVariance.resourceRoleGroups) {
                    List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance> variances;

                    boolean isValid = roleTimeVariance.siteId == drive.driveSiteId
                                        && roleTimeVariance.effectiveStartDate <= drive.driveDate
                                        && roleTimeVariance.effectiveEndDate >= drive.driveDate;
					/*
                    * HRP-12738 changes stats here
                    */
                    if(isValid && (roleTimeVariance.daysOfWeek.isEmpty() || !roleTimeVariance.daysOfWeek.contains(drive.driveDay))){
                        isValid = false;
                    }
                    /*
                    * HRP-12738 changes ends here
                    */
                    if (isValid) {
                        if (roleTimeVarianceMap.containsKey(varianceResourceRoleGroup)) { // HRP-11226 start
                            //variances = new List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>();
                            if(!roleTimeVarianceMap.get(varianceResourceRoleGroup).isEmpty()){
                                variances = roleTimeVarianceMap.get(varianceResourceRoleGroup);
                                variances.add(roleTimeVariance);
                                roleTimeVarianceMap.put(varianceResourceRoleGroup, variances);
                            } else{
                                variances = new List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>();
                                variances.add(roleTimeVariance);
                                roleTimeVarianceMap.put(varianceResourceRoleGroup, variances);
                            }
                        }else {
                            variances = new List<MobileDriveGeneratorDMLService.DMLRoleTimeVariance>();
                            variances.add(roleTimeVariance);
                            roleTimeVarianceMap.put(varianceResourceRoleGroup, variances);
                        }
                        //variances.add(roleTimeVariance); // HRP-11226 end
                        
                    }
                }
            }
            return roleTimeVarianceMap;
        }

        /********************************************************************* Calculate Travel Time **********************************************************************/

        protected virtual DriveGenerationUtil.TravelTimeSettingModel getTravelTimeSpecificInfo(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel = new DriveGenerationUtil.TravelTimeSettingModel();

            travelTimeModel.isNoTravelTimeChecked = drive.collectionOperation.noTravelTime;
            travelTimeModel.map_driveType_travelTimeIncludedFor.put(Constants.MOBILE_SITE_OPP, drive.collectionOperation.travelTimeIncludedMobile);
            travelTimeModel.map_driveType_travelTimeIncludedFor.put(Constants.FIX_SITE_OPP, drive.collectionOperation.travelTimeIncludedFixed);
            if(!travelTimeModel.isNoTravelTimeChecked) {
                if(!String.isBlank(travelTimeModel.map_driveType_travelTimeIncludedFor.get(drive.typeOfDrive))) {
                    travelTimeModel.resourceRoleGroupsNeededTravelTime = data.resourceRoleGroups;
                    Boolean isTravelTimeNeededForDriversOnly = travelTimeModel.map_driveType_travelTimeIncludedFor.get(drive.typeOfDrive).equalsIgnorecase(Constants.TRAVEL_TIME_INCLUDED_FIXED_SITE_DRIVERS_ONLY);
                    if(isTravelTimeNeededForDriversOnly) {
                        travelTimeModel.resourceRoleGroupsNeededTravelTime = new List<string>{'Driving roles'};
                    }
                }
            } else {
                if(drive.typeOfDrive.equalsIgnorecase(Constants.MOBILE_SITE_OPP)) {
                    travelTimeModel.resourceRoleGroupsNeededTravelTime = new List<string>{'Driving roles'};
                }
            }
            return travelTimeModel;
        }

        protected virtual void getTravelTimeFromTravelTimeIndex(
            MobileDriveGeneratorDMLService.DMLData data, 
            MobileDriveGeneratorDMLService.DMLDrive drive,
            MobileDriveGeneratorDMLService.DMLDriveShift driveShift,
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel,
            DriveGenerationUtil.TimeConfigurationModel config,
            Boolean isCalculatedForStaffingComplement
        ) { 
            Decimal travelTimeCoToSite = 45; 
            Decimal travelTimeSiteToCo = 45;
            //HRP-11908 --> Starts Here
            Time startWindow = (isCalculatedForStaffingComplement ? driveShift.startTime : drive.startTime).addMinutes(- (Integer.valueOf(config.setupTime + config.siteLogisticsTo)));
            Time endWindow = (isCalculatedForStaffingComplement ? driveShift.endTime : drive.endTime).addMinutes(Integer.valueOf(config.breakdownTime + config.siteLogisticsBack));
            //HRP-11908 --> Ends Here
            String driveDateWeekday = drive.driveDay;

            //HRP-10846 Start
            if (drive.siteCollectionOperationId != '') {
                MobileDriveGeneratorDMLService.DMLTravelTimeBreakdown travelTimeBreakdown;
                Location coStagingLocation = drive.coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__c;
                Location siteLocation = drive.driveSite.geoLocation;
                if (data.travelTimeIndexes != null) {
                    for (MobileDriveGeneratorDMLService.TravelTimeIndex tti : data.travelTimeIndexes) {
                        if (tti.fromGeo.latitude == coStagingLocation.latitude && tti.fromGeo.longitude == coStagingLocation.longitude && 
                        tti.toGeo.latitude == siteLocation.latitude && tti.toGeo.longitude == siteLocation.longitude && !tti.travelTimeBreakdown.isEmpty()) {
                            for (MobileDriveGeneratorDMLService.DMLTravelTimeBreakdown item : tti.travelTimeBreakdown) {
                                if (item.weekday == driveDateWeekday && item.startOfWindow <= startWindow && startWindow <= item.endOfWindow) {
                                    travelTimeBreakdown = item;
                                    break;
                                }
                            }
                            if (travelTimeBreakdown != NULL && travelTimeBreakdown.travelTime != NULL) {
                                travelTimeCoToSite = Math.ceil(travelTimeBreakdown.travelTime);// modify Travel time of JOB
                                drive.travelTimeCOtoSite =  tti.id; //HRP-11650
                            }
                        }
                        if (tti.toGeo.latitude == coStagingLocation.latitude && tti.toGeo.longitude == coStagingLocation.longitude && 
                        tti.fromGeo.latitude == siteLocation.latitude && tti.fromGeo.longitude == siteLocation.longitude && !tti.travelTimeBreakdown.isEmpty()) {
                            for (MobileDriveGeneratorDMLService.DMLTravelTimeBreakdown item : tti.travelTimeBreakdown) {
                                if (item.weekday == driveDateWeekday && item.startOfWindow <= endWindow && endWindow <= item.endOfWindow) {
                                    travelTimeBreakdown = item;
                                    break;
                                }
                            }
                            if (travelTimeBreakdown != NULL && travelTimeBreakdown.travelTime != NULL) {
                                travelTimeSiteToCo = Math.ceil(travelTimeBreakdown.travelTime);// modify Travel time of JOB
                                drive.travelTimeSitetoCO =  tti.id; //HRP-11650
                            }
                        }
                    }
                }
            }
            travelTimeModel.travelTimeCOToSite = travelTimeCoToSite;
            travelTimeModel.travelTimeSiteToCO = travelTimeSiteToCo;
            //HRP-10846 End
        }

        

        protected virtual MobileDriveGeneratorDMLService.DMLDriveShift applyRoleTimeDetailOnDriveShift(
            MobileDriveGeneratorDMLService.DMLData data,
            MobileDriveGeneratorDMLService.DMLDrive drive, 
            MobileDriveGeneratorDMLService.DMLDriveShift driveShift, 
            Integer driveCount, 
            Integer noOfDriveShifts, 
            List<DriveGenerationUtil.TimeConfigurationModel> listOfTimeConfigurationGlobal,
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel
        ) { 
            List<DriveGenerationUtil.TimeConfigurationModel> listOfTimeConfiguration = new List<DriveGenerationUtil.TimeConfigurationModel>();
            decimal breakdownTimeThreshold = drive.collectionOperation.breakdownTimeThreshold;
            decimal setupTimeThreshold = drive.collectionOperation.setupTimeThreshold;

            for (DriveGenerationUtil.TimeConfigurationModel timeConfigurationIteration : listOfTimeConfigurationGlobal) {
                DriveGenerationUtil.TimeConfigurationModel config = new DriveGenerationUtil.TimeConfigurationModel();
                config.resourceRoleGroup = timeConfigurationIteration.resourceRoleGroup;

                // HRP-11027 (3rd Change) --> Starts Here
                config.breakDownTime = timeConfigurationIteration.breakDownTime != NULL ? timeConfigurationIteration.breakDownTime : 0;
                config.leadTime = timeConfigurationIteration.leadTime!= NULL ? timeConfigurationIteration.leadTime : 0;
                config.resourceRoleGroup = timeConfigurationIteration.resourceRoleGroup;
                config.setupTime = timeConfigurationIteration.setupTime!= NULL ? timeConfigurationIteration.setupTime : 0;
                config.travelTime2 = timeConfigurationIteration.travelTime2!= NULL ? timeConfigurationIteration.travelTime2 : 0;
                config.travelTime = timeConfigurationIteration.travelTime != NULL ? timeConfigurationIteration.travelTime : 0;
                config.wrapUpTime = timeConfigurationIteration.wrapUpTime!= NULL ? timeConfigurationIteration.wrapUpTime : 0;
                config.siteLogisticsBack = timeConfigurationIteration.siteLogisticsBack!= NULL ? timeConfigurationIteration.siteLogisticsBack : 0; //HRP-11226
                config.siteLogisticsTo = timeConfigurationIteration.siteLogisticsTo!= NULL ? timeConfigurationIteration.siteLogisticsTo : 0; //HRP-11226
                config.travelTimeCoToSiteVariance = timeConfigurationIteration.travelTimeCoToSiteVariance!= NULL ? timeConfigurationIteration.travelTimeCoToSiteVariance : 0; //HRP-11908
                config.travelTimeSiteToCoVariance = timeConfigurationIteration.travelTimeSiteToCoVariance!= NULL ? timeConfigurationIteration.travelTimeSiteToCoVariance : 0; //HRP-11908
                // HRP-11027 (3rd Change) --> Ends Here

                // HRP-11046 --> Starts Here

                if(noOfDriveShifts > 1)
                {
                    // except 1st shift, check for threshold time
                    if(driveCount!= 0 && config.setupTime > setupTimeThreshold)
                    {
                        config.setupTime = setupTimeThreshold;
                    }
                    if(driveCount != noOfDriveShifts -1 && config.breakdownTime > breakdownTimeThreshold)
                    {
                        config.breakdownTime = breakdownTimeThreshold;
                    }
                }

                // HRP-11046 --> Ends Here

                //HRP-11908 --> Starts Here
                getTravelTimeFromTravelTimeIndex(data, drive, driveShift, travelTimeModel, config, TRUE);
                if(travelTimeModel.resourceRoleGroupsNeededTravelTime.contains(config.resourceRoleGroup)) {
                    config.travelTime = travelTimeModel.travelTimeCOToSite;
                    config.travelTime2 = travelTimeModel.travelTimeSiteToCO;
                }
                config.travelTime += config.travelTimeCoToSiteVariance;
                config.travelTime2 += config.travelTimeSiteToCoVariance;
                compareAndAdjustTimeConfiguration(config);
                //HRP-11908 --> Ends Here
                listOfTimeConfiguration.add(config);
            }
            driveShift.timeConfigurations = listOfTimeConfiguration;
            return driveShift;
        }

        //HRP-11908 --> starts here
        protected virtual DriveGenerationUtil.TimeConfigurationModel compareAndAdjustTimeConfiguration(DriveGenerationUtil.TimeConfigurationModel timeConfig) {
            if(timeConfig != NULL) {
                timeConfig.leadTime = Math.max(0, timeConfig.leadTime);
                timeConfig.setupTime = Math.max(0, timeConfig.setupTime);
                timeConfig.breakdownTime = Math.max(0, timeConfig.breakdownTime);
                timeConfig.wrapUpTime = Math.max(0, timeConfig.wrapUpTime);
                timeConfig.travelTime = Math.max(0, timeConfig.travelTime);
                timeConfig.travelTime2 = Math.max(0, timeConfig.travelTime2);
                timeConfig.siteLogisticsTo = Math.max(0, timeConfig.siteLogisticsTo);
                timeConfig.siteLogisticsBack = Math.max(0, timeConfig.siteLogisticsBack);
                timeConfig.travelTimeCoToSiteVariance = timeConfig.travelTimeCoToSiteVariance;
                timeConfig.travelTimeSiteToCoVariance = timeConfig.travelTimeSiteToCoVariance;
            }
            return timeConfig;
        }
        //HRP-11908 --> Ends here

        protected virtual MobileDriveGeneratorDMLService.DMLDriveShift calculateLunchBreak(MobileDriveGeneratorDMLService.DMLDriveShift driveShift, MobileDriveGeneratorDMLService.DMLDrive drive, MobileDriveGeneratorDMLService.DMLLunchBreakSetting lunchBreakSetting) {
            if(drive.collectionOperation.lunchBreak){
                Decimal maxDurationBefore = 0;
                Decimal maxDurationAfter = 0;
                for(DriveGenerationUtil.TimeConfigurationModel timeConfigurationIteration : driveShift.timeConfigurations){
                    Boolean valid = drive.typeOfDrive != 'Fixed Site' ? true : timeConfigurationIteration.resourceRoleGroup != 'Driving roles' ? true : false;
                    if(valid){
                        Decimal durationBefore = timeConfigurationIteration.travelTime + timeConfigurationIteration.leadTime + timeConfigurationIteration.setupTime + timeConfigurationIteration.siteLogisticsTo; //HRP-11226
                        Decimal durationAfter = timeConfigurationIteration.breakDownTime + timeConfigurationIteration.wrapUpTime + timeConfigurationIteration.travelTime2 + timeConfigurationIteration.siteLogisticsBack; //HRP-11226
                        maxDurationBefore = (durationBefore > maxDurationBefore ? durationBefore : maxDurationBefore);
                        maxDurationAfter = (durationAfter > maxDurationAfter ? durationAfter : maxDurationAfter);
                    }
                }
                Decimal driveShiftlength = driveShift.drawDuration + maxDurationBefore + maxDurationAfter ;
                driveShift.lunchBreak = driveShiftlength >= 360 ? true : false; //HRP-10474
                if (driveShift.lunchBreak && !drive.collectionOperation.lunchBreakBeforeDrawHours) {
                    if (lunchBreakSetting != null && lunchBreakSetting.maximumLunchBreakDuration != null) {
                        Decimal driveshiftDrawhr = ( (Decimal)driveShift.drawHours * 60) - lunchBreakSetting.maximumLunchBreakDuration;
                        driveShift.drawHourswithLunchBreak = driveshiftDrawhr.divide(60, 2, System.RoundingMode.UP);
                    }
                }
            }
            return driveShift;
        }

        protected virtual List<MobileDriveGeneratorDMLService.DMLVehicle> calculateGhostVehicles(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive, Decimal maxProjectedRegisteredDonors) {	
            List<MobileDriveGeneratorDMLService.DMLVehicle> suggestedVehicles = new List<MobileDriveGeneratorDMLService.DMLVehicle>();	
            	
            MobileDriveGeneratorDMLService.DMLVehicleList vehicleList = data.map_coId_VehicleList.get(drive.collectionOperationId);	
            MobileDriveGeneratorDMLService.DMLVehicleList finalizedVehicles;	
            if(vehicleList == NULL || vehicleList.vehicles.isEmpty()) {	
                vehicleList = new MobileDriveGeneratorDMLService.DMLVehicleList(drive.collectionOperationId);	
                List<sked_Resource_Biomed_Collection_Op__c> secondaryColOps = data.map_coIdSecondary_VehicleList.containsKey(drive.collectionOperationId) ? data.map_coIdSecondary_VehicleList.get(drive.collectionOperationId) : new List<sked_Resource_Biomed_Collection_Op__c>();	
                if (secondaryColOps.size() > 0) {	
                    for (sked_Resource_Biomed_Collection_Op__c secondaryColOp : secondaryColOps) {	
                        if ((secondaryColOp.sked_Start_Date__c == null || secondaryColOp.sked_Start_Date__c <= drive.driveDate ) && (secondaryColOp.sked_End_Date__c == null || secondaryColOp.sked_End_Date__c >= drive.driveDate)) {	//HRP-11749
                            vehicleList.collectionOperationId = drive.collectionOperationId;	
                            vehicleList.vehicles.add(new MobileDriveGeneratorDMLService.DMLVehicle(new sked__Resource__c(Id = secondaryColOp.sked_Resource__c, sked_Pres_Donor_Capacity__c = secondaryColOp.sked_Resource__r.sked_Pres_Donor_Capacity__c)));	
                        }	
                    }	
                }
                if ((vehicleList == null || vehicleList.vehicles.isEmpty()) && data.map_resourceOverrides.containsKey(drive.collectionOperationId)) {	
                    List<sked__Resource_Override__c> resOverride = data.map_resourceOverrides.get(drive.collectionOperationId);	
                    for (sked__Resource_Override__c resOr : resOverride) {	
                        if (resOr.sked_Start_Date__c <= drive.driveDate && resOr.sked_End_Date__c >= drive.driveDate) {	
                            vehicleList.collectionOperationId = drive.collectionOperationId;	
                            vehicleList.vehicles.add(new MobileDriveGeneratorDMLService.DMLVehicle(new sked__Resource__c(Id = resOr.sked__Resource__c, sked_Pres_Donor_Capacity__c = resOr.sked__Resource__r.sked_Pres_Donor_Capacity__c)));	
                        }	
                    }	
                }	
            }	
            if (vehicleList != NULL && vehicleList.vehicles != NULL && !vehicleList.vehicles.isEmpty()) {	
                decimal accumulatedVehicleDonors = 0;	
                for (MobileDriveGeneratorDMLService.DMLVehicle vehicle : vehicleList.vehicles)
                {	
                    // HRP-11173 --> Starts Here
                    if (vehicle.presDonorCapacity > 0)
                    {
                        suggestedVehicles.add(vehicle);	
                        accumulatedVehicleDonors += vehicle.presDonorCapacity;
                        if(accumulatedVehicleDonors >= maxProjectedRegisteredDonors)
                        {
                            break;
                        }
                    }
                    // HRP-11173 --> Ends Here	
                }	
            }	
            return suggestedVehicles;	
        }

        protected virtual MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix getStaffingDecisionMatrix(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive) {
            MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix;
            for (MobileDriveGeneratorDMLService.DMLCollectionOperationSdm collectionOperationSdm : data.collectionOperationSdms) {
                if (collectionOperationSdm.collectionOperationId == drive.collectionOperationId
                    && collectionOperationSdm.staffingDecisionMatrix.driveType == 'Mobile'
                    && (collectionOperationSdm.effectiveStartDate == null || collectionOperationSdm.effectiveStartDate <= drive.driveDate)
                    && (collectionOperationSdm.effectiveEndDate == null || drive.driveDate <= collectionOperationSdm.effectiveEndDate)){
                        matrix = collectionOperationSdm.staffingDecisionMatrix;
                    }
            }
            return matrix;
        }

        //HRP-10358 Commented as we donot need Volunteer Donors for either WB or Mobile
        /*protected virtual DriveStaffingComplementModel calculateVolunteerDonorAmbassdorQuantity(MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix matrix, MobileDriveGeneratorDMLService.DMLDrive drive, MobileDriveGeneratorDMLService.DMLDriveShift driveShift, DriveStaffingComplementModel staffingComplement) {
            if((drive.driveSite.siteOperationType == Constants.NON_INTEGRATED_WB_OPERATION_TYPE && drive.typeOfDrive == 'Fixed Site')){ // HRP - 9901
                if (drive.driveSite.physicalLocationType.contains(Constants.DRIVE_LOCATION_INSIDE) && driveShift.projectedRegisteredDonors != null){
                    if (drive.accountType == 'Education' && drive.industryCode == 'High School') {
                        if (driveShift.projectedRegisteredDonors <= 70) {
                            staffingComplement.numberOfVolunteerDonorAmbassadors = 1;
                        }
                        else {
                            staffingComplement.numberOfVolunteerDonorAmbassadors = 1 + Math.floor((driveShift.projectedRegisteredDonors - 70) / 60);
                        }
                    }else {
                        staffingComplement.numberOfVolunteerDonorAmbassadors = Math.ceil((driveShift.projectedRegisteredDonors / driveShift.drawHours) / 8);
                    }
                }
                else {
                    staffingComplement.numberOfVolunteerDonorAmbassadors = 1;
                }
                if (driveShift.drawHours > 6.5) {
                    staffingComplement.numberOfVolunteerDonorAmbassadors = (Decimal)Math.ceil(staffingComplement.numberOfVolunteerDonorAmbassadors * 0.5);
                }
            }
            return staffingComplement;
        }*/

        protected virtual MobileDriveGeneratorDMLService.DMLDriveShift populateDriveShiftTags(MobileDriveGeneratorDMLService.DMLDrive drive, MobileDriveGeneratorDMLService.DMLDriveShift driveShift) {
            Map<String,MobileDriveGeneratorDMLService.DMLDriveShiftTag> tagNameVsIDQuantitityMap = new Map<String,MobileDriveGeneratorDMLService.DMLDriveShiftTag>(); //HRP-11513
            Map<String,Id> tagNameRequired = new Map<String,Id>(); //HRP-11513
            List<MobileDriveGeneratorDMLService.DMLDriveShiftTag> driveShiftTags = new List<MobileDriveGeneratorDMLService.DMLDriveShiftTag>();
            if (drive.account.accountTags != NULL && !drive.account.accountTags.isEmpty()) {
                for (MobileDriveGeneratorDMLService.DMLAccountTag accountTag : drive.account.accountTags) { //HRP-11513 start
                    if ((!tagNameRequired.containsKey(accountTag.tagName)) && accountTag.required == True) {
                        tagNameRequired.put(accountTag.tagName,accountTag.tagId);
                    }
                    if ((accountTag.required == FALSE) && (!tagNameRequired.containsKey(accountTag.tagName))) {
                        MobileDriveGeneratorDMLService.DMLDriveShiftTag driveShiftTag = new MobileDriveGeneratorDMLService.DMLDriveShiftTag();
                        if(tagNameVsIDQuantitityMap.containsKey(accountTag.tagName)){
                            if(tagNameVsIDQuantitityMap.get(accountTag.tagName).minimumQuantity <= accountTag.minimumQuantity){
                                tagNameVsIDQuantitityMap.get(accountTag.tagName).tagId = accountTag.tagId;
                                tagNameVsIDQuantitityMap.get(accountTag.tagName).minimumQuantity = accountTag.minimumQuantity;
                            }
                        } else if(!tagNameVsIDQuantitityMap.containsKey(accountTag.tagName)){
                            driveShiftTag.tagId = accountTag.tagId;
                            driveShiftTag.minimumQuantity = accountTag.minimumQuantity;
                            tagNameVsIDQuantitityMap.put(accountTag.tagName,driveShiftTag);
                        } //HRP-11513 end
                    }
                }
            }
            if (drive.driveSite.locationTags != NULL && !drive.driveSite.locationTags.isEmpty()) {
                for (MobileDriveGeneratorDMLService.DMLLocationTag locationTag : drive.driveSite.locationTags) {
                    if ((!tagNameRequired.containsKey(locationTag.tagName)) && locationTag.required == True) { //HRP-11513 start
                        tagNameRequired.put(locationTag.tagName,locationTag.tagId);
                    }
                    if((locationTag.required == FALSE) && (!tagNameRequired.containsKey(locationTag.tagName))){
                        MobileDriveGeneratorDMLService.DMLDriveShiftTag driveShiftTag = new MobileDriveGeneratorDMLService.DMLDriveShiftTag();
                        if(tagNameVsIDQuantitityMap.containsKey(locationTag.tagName)){
                            if(tagNameVsIDQuantitityMap.get(locationTag.tagName).minimumQuantity <= locationTag.minimumQuantity){
                                tagNameVsIDQuantitityMap.get(locationTag.tagName).tagId = locationTag.tagId;
                                tagNameVsIDQuantitityMap.get(locationTag.tagName).minimumQuantity = locationTag.minimumQuantity;
                            }
                        } else if (!tagNameVsIDQuantitityMap.containsKey(locationTag.tagName)){
                            driveShiftTag.tagId = locationTag.tagId;
                            driveShiftTag.minimumQuantity = locationTag.minimumQuantity;
                            tagNameVsIDQuantitityMap.put(locationTag.tagName,driveShiftTag);
                        }
                    }
                    if(tagNameRequired.containsKey(locationTag.tagName)){
                        tagNameVsIDQuantitityMap.remove(locationTag.tagName);
                    }
                }
            }
            if (!tagNameVsIDQuantitityMap.values().isEmpty()) {
                driveShift.driveShiftTags = tagNameVsIDQuantitityMap.values(); //HRP-11513 end
            }
            return driveShift;
        }

        protected virtual void filterJobTags(MobileDriveGeneratorDMLService.DMLDrive drive) {
            Map<Id, MobileDriveGeneratorDMLService.DMLJobTag> mapSourceJobTagTemp =  new Map<Id, MobileDriveGeneratorDMLService.DMLJobTag>();
            Map<String,Id> uniqueTagName = new Map<String,Id>(); //HRP-12019
            if (drive.account != NULL && drive.account.accountTags != NULL) {
                for (MobileDriveGeneratorDMLService.DMLAccountTag accountTag : drive.account.accountTags) {
                    if (accountTag.required == TRUE && (!uniqueTagName.containsKey(accountTag.tagName))) { //HRP-12019
                        MobileDriveGeneratorDMLService.DMLJobTag jobTag = new MobileDriveGeneratorDMLService.DMLJobTag();
                        jobTag.tagId = accountTag.tagId;
                        jobTag.tagType = accountTag.tagType; // HRP-10169
                        jobTag.resourceType = accountTag.resourceType;
                        mapSourceJobTagTemp.put(jobTag.tagId, jobTag);
                        uniqueTagName.put(accountTag.tagName,accountTag.tagId); //HRP-12019
                    }
                }
            }
            if (drive.driveSite != NULL && drive.driveSite.locationTags != NULL) {
                for (MobileDriveGeneratorDMLService.DMLLocationTag locationTag : drive.driveSite.locationTags) {
                    if (locationTag.required == TRUE && (!uniqueTagName.containsKey(locationTag.tagName))) { //HRP-12019
                        MobileDriveGeneratorDMLService.DMLJobTag jobTag = new MobileDriveGeneratorDMLService.DMLJobTag();
                        jobTag.tagId = locationTag.tagId;
                        jobTag.tagType = locationTag.tagType; // HRP-10169
                        jobTag.resourceType = locationTag.resourceType;
                        mapSourceJobTagTemp.put(jobTag.tagId, jobTag);
                        uniqueTagName.put(locationTag.tagName,locationTag.tagId); //HRP-12019
                    }
                }
            }
            mapSourceJobTag = mapSourceJobTagTemp;
        }

        protected virtual MobileDriveGeneratorDMLService.DMLDriveShift populateJobTags(MobileDriveGeneratorDMLService.DMLDrive drive,
                                                                                        MobileDriveGeneratorDMLService.DMLDriveShift driveShift) {
            if (!mapSourceJobTag.isEmpty()) {
                for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs) {
                    List<MobileDriveGeneratorDMLService.DMLJobTag> jobTags = new List<MobileDriveGeneratorDMLService.DMLJobTag>();
                    for (MobileDriveGeneratorDMLService.DMLJobTag sourceJobTag : mapSourceJobTag.values()) {
                        boolean isValidTag = true;
                        if (!string.isBlank(sourceJobTag.resourceType))
                        {
                            // HRP-11295 - Restructed valid tag formula to incorporate changes for this ticket
                            isValidTag = (!string.isBlank(job.volunteerRole) 
                                            && !string.isBlank(sourceJobTag.tagType) 
                                            && sourceJobTag.tagType.contains(Constants.TAG_TYPE_CERTIFICATION)) // HRP-10169
                                || (job.assetType == Constants.JOB_TYPE_VEHICLE 
                                            && sourceJobTag.resourceType.contains(Constants.JOB_TYPE_VEHICLE)
                                            && drive.typeOfDrive == Constants.MOBILE_SITE_OPP)
                                || (!string.isBlank(job.resourcerole) && sourceJobTag.resourceType.contains(Constants.JOB_TAG_RESOURCETYPE_PERSON))
                                || (string.isBlank(job.resourcerole) && job.assetType == Constants.EQUIPMENT && sourceJobTag.resourceType.contains( Constants.EQUIPMENT));
                        }
                        else {
                            isValidTag = sourceJobTag.tagType.contains(Constants.JOB_TAG_RESOURCETYPE_PLT) ? true : false;
                        }
                        if (isValidTag) {
                            MobileDriveGeneratorDMLService.DMLJobTag jobTag = new MobileDriveGeneratorDMLService.DMLJobTag();
                            jobTag.tagId = sourceJobTag.tagId;
                            jobTags.add(jobTag);
                        }
                    }
                    if (!jobTags.isEmpty()) {
                        job.jobTags = jobTags;
                    }
                }
            }
            return driveShift;
        }

        protected List<MobileDriveGeneratorDMLService.DMLJob> applyRoleTimeForDriveShiftJob(
            MobileDriveGeneratorDMLService.DMLData data,
            MobileDriveGeneratorDMLService.DMLDrive drive,
            MobileDriveGeneratorDMLService.DMLDriveShift driveShift,
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel
        ) {
            Map<string, DriveGenerationUtil.TimeConfigurationModel> map_resourceRoleGroup_timeConfig = new Map<string, DriveGenerationUtil.TimeConfigurationModel>();
            for (DriveGenerationUtil.TimeConfigurationModel timeConfigurationIteration : driveShift.timeConfigurations) {
                map_resourceRoleGroup_timeConfig.put(timeConfigurationIteration.resourceRoleGroup, timeConfigurationIteration);
            }
            List<MobileDriveGeneratorDMLService.DMLJob> driveShiftJobs = new List<MobileDriveGeneratorDMLService.DMLJob>();
            for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs) {
                job.leadTime = 0;
                job.setupTime = 0;
                job.breakdownTime = 0;
                job.wrapUpTime = 0;
                job.travelTime = 0;
                job.travelTime2 = 0;
                job.siteLogisticsTo = 0; //HRP-11226
                job.siteLogisticsBack = 0; //HRP-11226
                
                if (!String.isBlank(job.resourceRole)) {
                    String currentResourceRoleGroup = getResourceRoleGroupUponResourceRole(data, job.resourceRole);
                    if (map_resourceRoleGroup_timeConfig.containsKey(currentResourceRoleGroup)) {
                        DriveGenerationUtil.TimeConfigurationModel driveShiftJobRoleTimeDetail = map_resourceRoleGroup_timeConfig.get(currentResourceRoleGroup);
                        job.leadTime += driveShiftJobRoleTimeDetail.leadTime != NULL ? driveShiftJobRoleTimeDetail.leadTime : 0;
                        job.breakdownTime += driveShiftJobRoleTimeDetail.breakdownTime != NULL ? driveShiftJobRoleTimeDetail.breakdownTime : 0;
                        job.setupTime += driveShiftJobRoleTimeDetail.setupTime != NULL ? driveShiftJobRoleTimeDetail.setupTime : 0;
                        job.wrapUpTime += driveShiftJobRoleTimeDetail.wrapUpTime != NULL ? driveShiftJobRoleTimeDetail.wrapUpTime : 0;
                        job.siteLogisticsBack += driveShiftJobRoleTimeDetail.siteLogisticsBack != NULL ? driveShiftJobRoleTimeDetail.siteLogisticsBack : 0; // HRP-11226
                        job.siteLogisticsTo += driveShiftJobRoleTimeDetail.siteLogisticsTo != NULL ? driveShiftJobRoleTimeDetail.siteLogisticsTo : 0; //HRP-11226
                        job.travelTime += driveShiftJobRoleTimeDetail.travelTime != NULL ? driveShiftJobRoleTimeDetail.travelTime : 0;
                        job.travelTime2 += driveShiftJobRoleTimeDetail.travelTime2 != NULL ? driveShiftJobRoleTimeDetail.travelTime2 : 0;
                    }
                }
                driveShiftJobs.add(job);
            }
            return driveShiftJobs;
        }

        protected String getResourceRoleGroupUponResourceRole(MobileDriveGeneratorDMLService.DMLData data, String resourceRole) {
            return data.map_resourceRole_resourceRoleGroup.get(resourceRole);
        }

        protected MobileDriveGeneratorDMLService.DMLDriveShift populateLunchBreakTime(MobileDriveGeneratorDMLService.DMLData data, MobileDriveGeneratorDMLService.DMLDrive drive, MobileDriveGeneratorDMLService.DMLDriveShift driveShift) {
            if (driveShift.lunchBreak) {
                decimal coMaxLunchBreakDuration = drive.maximumLunchBreakDuration != NULL ? drive.maximumLunchBreakDuration : 30;
                MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition = findLunchBreakDefinition(data, coMaxLunchBreakDuration, otherResourceQuantityOne, driveShift);
                driveShift.lunchBreakBeforeDrawHours = drive.collectionOperation.lunchBreakBeforeDrawHours;
                DateTime lunchBreakStart, lunchBreakEnd;
                if (driveShift.lunchBreakBeforeDrawHours) {
                    driveShift.lunchBreakDuration = drive.collectionOperation.unpaidLunchBreakDuration;
                    lunchBreakEnd = driveShift.drawStart ; // drive.drawStart;
                    lunchBreakStart = lunchBreakEnd.addMinutes(integer.valueOf(-driveShift.lunchBreakDuration));
                }
                else {
                    driveShift.lunchBreakDuration = lunchBreakDefinition.lunchBreakDuration;
                    Decimal lunchHoursExcluded = driveShift.drawHours;
                    decimal drawDurationBeforeLunch = Math.floor(((lunchHoursExcluded*60) - driveShift.lunchBreakDuration) / 2);
                    if (Math.mod(integer.valueOf(drawDurationBeforeLunch), 15) != 0) {
                        drawDurationBeforeLunch = Math.floor(drawDurationBeforeLunch / 15) * 15;
                    }
                    lunchBreakStart = driveShift.drawStart.addMinutes(integer.valueOf(drawDurationBeforeLunch)); 
                    lunchBreakEnd = lunchBreakStart.addMinutes(integer.valueOf(driveShift.lunchBreakDuration));
                }
                driveShift.lunchBreakStartTime = lunchBreakStart.timeGMT();
                driveShift.lunchBreakEndTime = lunchBreakEnd.timeGMT();
            }
            return driveShift;
        }

        protected virtual MobileDriveGeneratorDMLService.DMLLunchBreakDefinition findLunchBreakDefinition(MobileDriveGeneratorDMLService.DMLData data, decimal lunchBreakDuration, decimal staffSetup, MobileDriveGeneratorDMLService.DMLDriveShift driveShift) {
            MobileDriveGeneratorDMLService.DMLLunchBreakSetting lunchBreakSetting;
            for (MobileDriveGeneratorDMLService.DMLLunchBreakSetting setting : data.lunchBreakSettings) {
                if (setting.maximumLunchBreakDuration == lunchBreakDuration) {
                    lunchBreakSetting = setting;
                    break;
                }
            }
            driveShift.lunchBreakPerperson = lunchBreakSetting.maximumLunchBreakDuration;
            MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition;
            for (MobileDriveGeneratorDMLService.DMLLunchBreakDefinition definition : lunchBreakSetting.lunchBreakDefinitions) {
                if (definition.minNumberOfStaff <= staffSetup && staffSetup <= definition.maxNumberOfStaff) {
                    lunchBreakDefinition = definition;
                }
            }
            return lunchBreakDefinition;
        }

        protected virtual void reduceSlots(List<MobileDriveGeneratorDMLService.DMLSlot> slots, slotGeneratorConfigModel configuration) {	
            integer totalSlots = 0;	
            DateTime lunchBrkStart = configuration.startTime;
            DateTime lunchBrkEnd = configuration.endTime;
            for (MobileDriveGeneratorDMLService.DMLSlot slot : slots) {	
                if (lunchBrkStart <= slot.startTime && slot.endTime <= lunchBrkEnd) {
                    totalSlots++;	
                }	
            }	
            Decimal numberOfReducedSlots = Math.ceil((totalSlots * (decimal)configuration.slotReduction)/100);
            integer reduceSlotCount = 0;	
            integer numberOfRounds = configuration.rounds.size();	
            integer roundCount = 1;	
            while (reduceSlotCount < numberOfReducedSlots) {	
                integer roundIndex = integer.valueOf(Math.mod(roundCount, numberOfRounds));	
                roundIndex = (roundIndex == 0 ? configuration.rounds.size() : roundIndex) - 1;	
                DateTime firstSlotStart = lunchBrkStart.addMinutes(configuration.rounds.get(roundIndex));	
                DateTime tempDt = firstSlotStart;	
                	
                while (tempDt < lunchBrkEnd) {	
                    integer index = -1;	
                    for (integer i = 0; i < slots.size(); i++) {	
                        MobileDriveGeneratorDMLService.DMLSlot slot = slots.get(i);	
                        if (slot.startTime == tempDt) {	
                            index = i;	
                            break;	
                        }   	
                    }	
                    if (index > -1) {	
                        slots.remove(index);	
                        reduceSlotCount++;	
                    }	
                    if (reduceSlotCount == numberOfReducedSlots) {	
                        break;	
                    }	
                    tempDt = tempDt.addMinutes(configuration.interval);	
                }	
                roundCount++;	
            }	
        }

        // Maximum Staff Shift length Calculation - HRP-11295 (Restructured the following method)
        protected MobileDriveGeneratorDMLService.DMLDriveShift populateShiftTime(MobileDriveGeneratorDMLService.DMLData data, 
                                                                            MobileDriveGeneratorDMLService.DMLDrive drive, 
                                                                            MobileDriveGeneratorDMLService.DMLDriveShift driveShift,
                                                                            Integer shiftCount,
                                                                            Integer noOfDriveShift)
        {
            DateTime minStart = driveShift.drawStart;          
            DateTime maxEnd = driveShift.drawEnd;  
            DateTime jobStart;
            DateTime jobFinish;         

            for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs)
            {
                // Except Vehicle & Equipment
                if(!String.isBlank(job.resourceRole))
                {
                    decimal leadTime = job.leadTime != NULL ? job.leadTime : 0;
                    decimal setupTime = job.setupTime != NULL ? job.setupTime : 0;
                    decimal breakdownTime = job.breakdownTime != NULL ? job.breakdownTime : 0;
                    decimal wrapUpTime = job.wrapUpTime != NULL ? job.wrapUpTime : 0;
                    decimal travelTime = job.travelTime != NULL ? job.travelTime : 0;
                    decimal travelTime2 = job.travelTime2 != NULL ? job.travelTime2 : 0;
                    decimal siteLogisticsBack = job.siteLogisticsBack != NULL ? job.siteLogisticsBack : 0; //HRP-11226
                    decimal siteLogisticsTo = job.siteLogisticsTo != NULL ? job.siteLogisticsTo : 0; //HRP-11226

                    // Duration before logic: Travel Time + Lead Time + Setup Time + site Logistics To
                    decimal durationBeforeDrawHours = travelTime + leadTime + setupTime + siteLogisticsTo; //HRP-11226 

                    if (driveShift.lunchBreak && driveShift.lunchBreakBeforeDrawHours)
                    {
                        durationBeforeDrawHours += driveShift.lunchBreakDuration;
                    }

                    // Duration After: Breakdown Time + Wrap Up Time + Travel Time 2 + site logistics Back
                    decimal durationAfterDrawHours = breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack; //HRP-11226 

                    jobStart = driveShift.drawStart.addMinutes(integer.valueOf(-durationBeforeDrawHours));
                    jobFinish = driveShift.drawEnd.addMinutes(integer.valueOf(durationAfterDrawHours));

                    minStart = minStart > jobStart ? jobStart : minStart; // Max Duration Before                    
                    maxEnd = maxEnd < jobFinish ? jobFinish : maxEnd; // Max Duration After   
                    
                    // Populate Job Timings
                    job.start = skedDateTimeUtils.switchTimezone(jobStart,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);                
                    job.finish = skedDateTimeUtils.switchTimezone(jobFinish,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
                    job.duration = skedDateTimeUtils.getDifferentMinutes(job.start, job.finish);
            }
            
            driveShift.start = skedDateTimeUtils.switchTimezone(minStart,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);           
            driveShift.finish = skedDateTimeUtils.switchTimezone(maxEnd,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
            decimal value = skedDateTimeUtils.getDifferentMinutes(driveShift.start, driveShift.finish);

            // Populating Global Variables to use them for Equipment and Vehicle Job Timings
            if(shiftCount == noOfDriveShift - 1 && noOfDriveShift > 1)
            {
                nonResourceRoleJobFinishTime = driveShift.finish;
            }
            // for single shift
            else if (shiftCount == 0 && noOfDriveShift == 1)
            {
                nonResourceRoleJobStartTime = driveShift.start;
                nonResourceRoleJobFinishTime = driveShift.finish;
            }
            else if (shiftCount == 0 && noOfDriveShift > 1)
            {
                nonResourceRoleJobStartTime = driveShift.start;
            } 
            
           // HRP-11295 -- End
        }
        return driveShift;
    }

        // Job Timings Calculation for Equipment and Vehicle - HRP-11295
        protected void populateJobTimingsForEquipmentAndVehicle (MobileDriveGeneratorDMLService.DMLDrive drive,List<MobileDriveGeneratorDMLService.DMLJob> jobList)
        {
            Integer repeatCount = 0;
            for(MobileDriveGeneratorDMLService.DMLJob job : jobList)
            {
                if(string.isBlank(job.resourceRole) && !string.isBlank(job.assetType) 
                            && (job.assetType.contains(Constants.EQUIPMENT)
                            || job.assetType.contains(Constants.JOB_TYPE_VEHICLE)))
                {
                    
                    repeatCount = repeatCount+1;
                    job.start = nonResourceRoleJobStartTime;
                    job.finish = nonResourceRoleJobFinishTime;
                    job.duration = skedDateTimeUtils.getDifferentMinutes(job.start, job.finish);
                    
                    boolean isRepeatationNotNeeded = ((repeatCount == 1 && drive.typeOfDrive == Constants.FIX_SITE_OPP)
                                                    || (repeatCount == 2 && drive.typeOfDrive == Constants.MOBILE_SITE_OPP));
                                                
                    if(isRepeatationNotNeeded)
                    {
                        break;
                    }
                }                
            }
        }

        
        // Calculation of planned drive productivity
        protected virtual MobileDriveGeneratorDMLService.DMLDrive calculateDriveProductivityPlanned(MobileDriveGeneratorDMLService.DMLDrive drive) {
            decimal sum = 0;
            
            if (drive.driveShifts != NULL) {
                for (MobileDriveGeneratorDMLService.DMLDriveShift driveShift : drive.driveShifts) {
                    for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs) {
                        //HRP-10474 Start
                        decimal drawHours = (driveShift.drawHours)*60;
                        if(driveShift.lunchBreak && (!drive.collectionOperation.lunchBreakBeforeDrawHours)){
                            drawHours = driveShift.drawHourswithLunchBreak != null ? driveShift.drawHourswithLunchBreak*60 : drawHours;
                        }//HRP-10474 End
                        if (!string.isBlank(job.resourceRole)) {
                            decimal leadTime = job.leadTime != NULL ? job.leadTime : 0;
                            decimal setupTime = job.setupTime != NULL ? job.setupTime : 0;
                            decimal breakdownTime = job.breakdownTime != NULL ? job.breakdownTime : 0;
                            decimal wrapUpTime = job.wrapUpTime != NULL ? job.wrapUpTime : 0;
                            decimal travelTime = job.travelTime != NULL ? job.travelTime : 0;
                            decimal travelTime2 = job.travelTime2 != NULL ? job.travelTime2 : 0;
                            decimal siteLogisticsBack = job.siteLogisticsBack != NULL ? job.siteLogisticsBack : 0; //HRP-11226
                            decimal siteLogisticsTo = job.siteLogisticsTo != NULL ? job.siteLogisticsTo : 0; //HRP-11226
                            sum += job.quantity * (drawHours + travelTime + leadTime + setupTime + breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack + siteLogisticsTo); //HRP-11226
                        }
                            
                    }
                }
            }
            drive.driveProductivityPlanned = sum > 0 ? drive.totalProductsProjected / (sum / 60) : 0;
            decimal totalSlots = 0;
            for (MobileDriveGeneratorDMLService.DMLDriveShift driveShift : drive.driveShifts) {
                if (driveShift.slots != NULL) {
                    totalSlots += driveShift.slots.size();
                }
            }
            drive.totalSlots = totalSlots;
            return drive;
        }
        
    }
    
    /************************************************************** Nested Classes ****************************************************************/
    
    public class DriveStaffingComplementModel {
        public boolean success;
        public string opportunityId;
        
        //Mobile
        public decimal numberOfVehicles;
        public decimal numberOf2rbcEquipments;
        public decimal numberOfDrivers;
        public decimal numberOfDriverSupports;
        public decimal numberOf2rbc;
        public decimal numberOfTeamSupervisors;
        public decimal numberOfVphh;
        public decimal numberOfApt;
        public decimal numberOfCharge;
        public decimal numberOfVolunteerDonorAmbassadors;
        public Map<String, Decimal> map_role_resourceQuantity; // HRP-11634
        
        //Fixed Site
        public decimal numberOf2rbcAssets;
        public decimal numberOfPlasmaAssets;
        public decimal numberOfPlateletAssets;
        public Map<string, procedureTypeStaffingModel> mapProcedureStaffing;
        public decimal numberOfWholeBloodResources;
        public decimal numberOf2rbcResources;
        public decimal numberOfApheresisCharge;
        
          public DriveStaffingComplementModel() {
            this.map_role_resourceQuantity = new Map<String, Decimal>(); // HRP-11634
        }
    }

    public class procedureTypeStaffingModel {
        public string resourceRole;
        public string procedureType;
        public decimal noOfStaff;
        public decimal donorsPerHoursCapacity;
    }
    
    public class slotGeneratorConfigModel {
        public DateTime endTime;
        public Set<DateTime> excludedSlots;
        public integer groupInterval;
        public integer interval;
        public DateTime lastSlotStart;
        public integer numberOfAssets;
        public integer numberOfGroups;
        public integer roundInterval;
        public List<integer> rounds;
        public integer slotDuration;
        public integer slotReduction;
        public string slotType;
        public DateTime startTime;
        public integer totalSlots;
        public String timezoneSidId;	
        public DateTime driveEndTime;	
        public Date driveDate;
    }
    
}