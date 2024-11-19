/* 
* Description: This class is called from DriveGeneratorService to create Fixed Site Drives on Calender records with opeartion type Integrated/Non Integrated APH
** NOTE: Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification on DOC

/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 05/09/2023				  Priti Jana			 Logic for HRP-10012
 * 10/09/2023                 Krapy Tuli             Logic for HRP-9943, HRP-9944
 * 05/11/2023                 Krapy Tuli             Logic for HRP-9966
 * 06/12/2023                 Priti Jana             Logic for HRP-9901
 * 06/22/2023                 Priti Jana             Logic for HRP-9965
 * 06/22/2023                 Krapy Tuli             Logic for HRP-9966
 * 08/03/2023                 Priti Jana             Logic for HRP-10456
 * 08/09/2023                 Priti Jana             Logic for HRP-10450
 * 08/11/2023                 Priti Jana             Logic for HRP-10626
 * 10/05/2023                 Priti Jana             Logic for HRP-11027
 * 10/25/2023                 Krapy Tuli             Logic for HRP-11226
 * 11/15/2023                 Priti Jana             Logic for HRP-11046
 * 11/15/2023                 Priti Jana             Logic for HRP-11295
 * 11/20/2023                 Krapy Tuli             Logic for HRP-11419
 * 12/20/2023                 Krapy Tuli             Logic for HRP-11513
 * 12/22/2023                 Priti Jana             Logic for HRP-10915
 * 01/15/2024                 Priti Jana             Logic for HRP-11418
 * 02/05/2024                 Priti Jana             Logic for HRP-11547
 * 02/12/2024                 Priti Jana             Logic for HRP-11443
 * 02/22/2024                 Priti Jana             Logic for HRP-12144
 * 02/26/2024                 Krapy Tuli             Logic for HRP-12019
 * 03/11/2024				  Fitsum Worku			 Logic for HRP-12218
 * 05/02/2024                 Priti Jana             Logic for HRP-12480
 * 06/05/2024                 Priti Jana             Logic for HRP-11908
 * 06/06/2024                 Priti Jana             Logic for HRP-12011
 * 06/17/2024                 Barnojit Sharma        Logic for HRP-12738
 * 10/15/2024                 Priti Jana             Logic for HRP-13198
 *****************************************************************************
*/

public class CreateSkedDrive
{
    static map<String, Decimal> mapResourceQuantity = new map<String, Decimal>();
    static String oppId ;
    static DateTime equipmentJobFinishTime; // HRP-11295
    static DateTime equipmentJobStartTime; // HRP-11295
    
    public static void createDrives(list<Opportunity> oppList) {
       try {
            set<Id> oppIds = new set<Id>();
            for(opportunity opp: oppList){
                oppIds.add(opp.Id);
            }            
            FetchRelatedDriveData.DMLData allData = FetchRelatedDriveData.getDriveGenerationData(oppIds);
            for (FetchRelatedDriveData.DMLDrive drive : allData.drives) {
                String customMsg = customMessage(allData,drive);
                if(customMsg == 'No Error' || Test.isRunningTest()){
                    generateDrive(allData,drive);
                } else {
                    // HRP-11027 --> starts Here
                    //CustomNotification.notifyUsers(new Set <String>{userInfo.getUserId()} , drive.opportunityId , 'Error!' , customMsg );
                    String targetId = String.valueOf(drive.opportunityId);
                    DriveGenerationErrorHandler.notifyUsersUponFailureAndLogErrors(NULL, targetId, customMsg, Constants.DATA_ISSSUE, Constants.FIXED_SITE_DRIVE_GENEERRATOR, Constants.FIXED_SITE_DRIVE_GEN_METHOD); 
                    // HRP-11027 --> Ends Here
                }
            }
            List<FetchRelatedDriveData.DMLDrive> drivesToSave = new List<FetchRelatedDriveData.DMLDrive>();
            for(FetchRelatedDriveData.DMLDrive dmlDrive : allData.drives) {
                oppId = dmlDrive.Id;
                if(!dmlDrive.hasError)
                {                    
                    drivesToSave.add(dmlDrive);
                }
            }
            if(drivesToSave.size() > 0) {
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418
                FetchRelatedDriveData.saveDrives(drivesToSave);
            }
           
        } catch(Exception ex){
            // HRP-11027
            oppId = String.valueOf(oppList[0].Id);
            DriveGenerationErrorHandler.notifyUsersUponFailureAndLogErrors(ex, oppId, NULL, Constants.TECHNICAL_ISSSUE, Constants.FIXED_SITE_DRIVE_GENEERRATOR, Constants.FIXED_SITE_DRIVE_GEN_METHOD);
        }
    }
    
    private static string customMessage(FetchRelatedDriveData.DMLData data,FetchRelatedDriveData.DMLDrive drive) {
        Boolean isError = false;
        String errorMessage='';
        FetchRelatedDriveData.DMLLocation driveSite = data.mapLocation.get(drive.driveSiteId);
        FetchRelatedDriveData.DMLAccount account = data.mapAccount.get(drive.accountId);
        if(driveSite == null) {  
            errorMessage += 'Site not found\n';
            isError = true;
        }
        if(driveSite.timezoneSidId == null) {  
            errorMessage += 'Site does not have Time Zone\n';
            isError = true;
        }
       
        if (driveSite.siteCollectionOperations == NULL) {
            errorMessage += 'No Site Collection Operations found\n';
            isError = true;
        } else {
            for (FetchRelatedDriveData.DMLSiteCollectionOperation siteCollectionOperation : driveSite.siteCollectionOperations) {
                if(siteCollectionOperation.collectionOperationId == NULL){
                    errorMessage += 'Site Collection Operation : Collection Operation is null\n';
                    isError = true;
                }
                if(siteCollectionOperation.startDate == NULL){
                    errorMessage += 'Site Collection Operation : Start Date is null\n';
                    isError = true;
                }
                if(siteCollectionOperation.endDate == NULL){
                    errorMessage += 'Site Collection Operation : End Date is null\n';
                    isError = true;
                }
                if (siteCollectionOperation.startDate <= drive.driveDate && drive.driveDate <= siteCollectionOperation.endDate) {
                    drive.collectionOperationId = siteCollectionOperation.collectionOperationId;
                    drive.collectionOperation = data.mapCollectionOperation.get(drive.collectionOperationId);
                    break;
                }
            }
        }
    

        if (drive.collectionOperationId == null) {
            errorMessage += 'No collection operation\n';
            isError = true;
        }else{
            if(drive.collectionOperation.lunchBreakDurationFixedSite == null) {
                errorMessage += 'Collection Operation : lunch Break Duration for Fixed Site is null\n';
                isError = true;
            } if (drive.collectionOperation.breakdownTimeThreshold == null) {
                errorMessage += 'Collection Operation : Breakdown Time Threshold is null\n';
                isError = true;
            } if(drive.collectionOperation.setupTimeThreshold == null) {
                errorMessage += 'Collection Operation : Setup Time Threshold is null\n';
                isError = true;
            }if(drive.collectionOperation.unpaidLunchBreakDuration == null) {
                errorMessage += 'Collection Operation : Unpaid Lunch Break Duration is null\n';
                isError = true;
            }
        }

        FetchRelatedDriveData.DMLStaffingDecisionMatrix matrix = getStaffingDecisionMatrix(data, drive);
        if (matrix == null) {
            errorMessage += 'No Staffing Matrix found\n';
            isError = true;
        }else{
            if(matrix.nrVolunteerFixedSiteBandLower == null) {
                errorMessage += 'Matrix : Fixed Site Band Lower is null\n';
                isError = true;
            }
            if(matrix.nrVolunteerFixedSiteBandUpper == null) {
                errorMessage += 'Matrix : Fixed Site Band Upper is null\n';
                isError = true;
            }
            if(matrix.plateletRoundCapacity == null) {	// HRP-11547
                errorMessage += 'Matrix : Platelet Round Capacity is null\n';	
                isError = true;	
            }	
            if(matrix.plasmaHourlyCapacity == null) {	
                errorMessage += 'Matrix : Plasma Hourly Capacity is null\n';	
                isError = true;	
            }	
            if(matrix.wbHourlyCapacity == null) {	
                errorMessage += 'Matrix : WB Hourly Capacity is null\n';	
                isError = true;	
            }	
            if(matrix.x2rbcHourlyCapacity == null) {	
                errorMessage += 'Matrix : x2rbc Hourly Capacity is null\n';	
                isError = true;	
            }
        }

        if(account.fixedSiteProcedureProjections == null || account.fixedSiteProcedureProjections.isEmpty()) {
            errorMessage += 'Account : Fixed Site Procedure Projections not found\n';  
            isError = true;
        } else {
            for(FetchRelatedDriveData.DMLFixedSiteProcedureProjection fsProjection : account.fixedSiteProcedureProjections) {
                if(fsProjection.deferral == null) {
                    errorMessage += 'Fixed Site Projection deferral is null\n';  
                    isError = true;
                }
                if(fsProjection.qns == null) {
                    errorMessage += 'Fixed Site Projection qns is null\n';  
                    isError = true;
                }
            }
        }
        if(isError) {
            drive.hasError = true;
            return errorMessage;
        }
        else {
            drive.hasError = false;
            return 'No Error';  
        }
    }
    
    static void generateDrive(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        prepareDriveData(data, drive);		// preparing account, site, collection operationfor creating drives
        calculateTotalProceduresProjected(drive);	    /****** point no 1 ******/ 
        calculatePlateletRounds(drive);         /****** point no 2 ******/
        proposeDriveShifts(data, drive);	    /****** point no 6d ******/
        calculateDriveProductivityPlanned(drive);	// Calculate drive productivity planned - HRP-10456
        if (drive.driveShifts != NULL) {
            populateDriveShiftTags(drive);
            populateJobTags(drive);
            updateDriveTotalSlots(drive);
        }
    }

    static void prepareDriveData(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        FetchRelatedDriveData.DMLAccount account = data.mapAccount.get(drive.accountId);
        drive.account = account;    
        
        FetchRelatedDriveData.DMLLocation driveSite = data.mapLocation.get(drive.driveSiteId);
        drive.driveSite = driveSite;
        
        if (driveSite.siteCollectionOperations != NULL) {
            
            for (FetchRelatedDriveData.DMLSiteCollectionOperation siteCollectionOperation : driveSite.siteCollectionOperations) {
                if (siteCollectionOperation.startDate <= drive.driveDate && drive.driveDate <= siteCollectionOperation.endDate) {
                    drive.collectionOperationId = siteCollectionOperation.collectionOperationId;
                    drive.siteCollectionOperationId = siteCollectionOperation.Id;
                    drive.collectionOperation = data.mapCollectionOperation.get(drive.collectionOperationId);
                    break;
                }
            }
        }

        // HRP-11653 --> Starts Here
        if (drive.collectionOperationId != null && data.mapCoIdVsStagingLocations.containsKey(drive.collectionOperationId)) {
            for (sked_Collection_Op_Staging_Location__c sloc : data.mapCoIdVsStagingLocations.get(drive.collectionOperationId)) {
                if (sloc.sked_Start_Date__c <= drive.driveDate && drive.driveDate <= sloc.sked_End_Date__c) {
                    drive.coStagingLocation = sloc; //HRP-11650
                    drive.stagingLocation = sloc.sked_Staging_Location__c; //NEW
                    break;
                }
            }
        }
        // HRP-11653 --> Ends Here
        drive.maximumLunchBreakDuration = drive.collectionOperation.lunchBreakDurationFixedSite;
        drive.drawStart = DateTime.newInstanceGmt(drive.driveDate, drive.startTime);
        drive.drawEnd = DateTime.newInstanceGmt(drive.driveDate, drive.endTime);
        drive.drawDuration = skedDateTimeUtils.getDifferentMinutes(drive.drawStart, drive.drawEnd);
        drive.drawHours = drive.drawDuration / 60;         
    }
    
    /****** point no 1 ******/
    static void calculateTotalProceduresProjected(FetchRelatedDriveData.DMLDrive drive) {        
        decimal x2rbcProjectedProcedures = drive.x2rbcProjectedProcedures != NULL ? drive.x2rbcProjectedProcedures : 0;
        decimal wbProjectedProcedures = drive.wbProjectedProcedures != NULL ? drive.wbProjectedProcedures : 0;
        decimal plasmaProjectedProcedures = drive.plasmaProjectedProcedures != NULL ? drive.plasmaProjectedProcedures : 0;
        decimal plateletProjectedProcedures = drive.plateletProjectedProcedures != NULL ? drive.plateletProjectedProcedures : 0;
        /****** 1a ******/
        drive.totalProceduresProjected = x2rbcProjectedProcedures + wbProjectedProcedures + 
            plasmaProjectedProcedures + plateletProjectedProcedures;	
        /****** 1b *****/
        drive.totalProductsProjected = x2rbcProjectedProcedures * 2 + wbProjectedProcedures + 
            plasmaProjectedProcedures + plateletProjectedProcedures;	
    }
    
    /****** point no 2 ******/
        static void calculatePlateletRounds(FetchRelatedDriveData.DMLDrive drive) {
        Integer totalRounds = 0;

        // HRP - 9901 - siteOperationType is used to calculate total number of rounds

        // HRP - 10450 --> Starts Here
        // @Logic - two different operation type are not considered anymore to calculate platelet rounds
       
        if(drive.drawHours <= 3)
        {
            totalRounds = 1;
        }else if(drive.drawHours > 3 && drive.drawHours <= 6)
        {
            totalRounds = 2;
        }else if (drive.drawHours > 6 && drive.drawHours <= 9)
        {
            totalRounds = 3;
        }else if(drive.drawHours > 9 && drive.drawHours <= 12)
        {
            totalRounds = 4;
        }
        else {
            totalRounds = 5;
        }
        drive.plateletRounds = totalRounds;

        // HRP - 10450 --> Ends Here
    }
    
    /****** point no 6d ******/
    static void proposeDriveShifts(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {               
        /***** 3a ******/
        
        Decimal noOfDriveShift = drive.plateletRounds > 3 ? Math.ceil(drive.plateletRounds / 3) : 1;

        Map<String, Decimal> fsppTypeAndValuesMap = getFSPPTypeAndDeferalQnsValue(drive); //HRP-11547

        Map<String, Decimal> mapResourceQuantity = CalculateResourceQuantity(data, drive);	// 5

        calculateDriveProcedureCapacity(data, drive, mapResourceQuantity,fsppTypeAndValuesMap); // HRP-11547

        FetchRelatedDriveData.DMLDriveShift suggestedDriveShift = initiateDriveShift(data, drive);   
        
        /**** POint no 4 ***/
        // splitProjectedProcedure(noOfDriveShift, drive, suggestedDriveShift); -> This logic has been shifted to buildMultiDriveShifts method

        //populateTravelTime(data, drive, suggestedDriveShift);

        
        
        /******* 3b *******/
        List<FetchRelatedDriveData.DMLDriveShift> driveShifts = buildMultiDriveShifts(data, drive, suggestedDriveShift,noOfDriveShift);
        drive.driveShifts = driveShifts;
        
        calculateDriveShiftProcedureCapacityValue(drive,drive.driveShifts); // HRP - 10456
    }
    
    static driveStaffingComplementModel calculateDriveStaffingComplement(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive,Decimal noOfDriveShift) {
        driveStaffingComplementModel staffingComplement = new driveStaffingComplementModel();
        staffingComplement.opportunityId = drive.opportunityId;
        
        FetchRelatedDriveData.DMLStaffingDecisionMatrix matrix = getStaffingDecisionMatrix(data, drive);
        //calculateVolunteerDonorAmbassadors(matrix, drive, staffingComplement,noOfDriveShift);
        return staffingComplement;
    }
    
    
    // HRP - 10456 --> Starts here
    static driveStaffingComplementModel calculateVolunteerDonorAmbassadorValue(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, 
    List<FetchRelatedDriveData.DMLDriveShift> driveShifts)
    {
        driveStaffingComplementModel staffingComplement = new driveStaffingComplementModel();
        staffingComplement.opportunityId = drive.opportunityId;
        
        FetchRelatedDriveData.DMLStaffingDecisionMatrix matrix = getStaffingDecisionMatrix(data, drive);

        Decimal drivePlateLetProcedureProjected = drive.plateletProjectedProcedures;
        Decimal drivePlasmaProcedureProjected = drive.plasmaProjectedProcedures;
        Decimal driveWBProcedureProjected = drive.wbProjectedProcedures;
        Decimal drive2RBCProcedureProjected = drive.x2rbcProjectedProcedures;
        Decimal drivePlateletRounds = drive.plateletRounds;
        Decimal driveTotal = drive.totalProceduresProjected;
        Decimal driveDrawHours = drive.drawHours;
        decimal nrVolunteerFixedSiteBandLower = 0;
        decimal nrVolunteerFixedSiteBandUpper = 0;

        if (drive.typeOfDrive == 'Fixed Site' && matrix != null)
        {
            nrVolunteerFixedSiteBandLower = matrix.nrVolunteerFixedSiteBandLower != null ? matrix.nrVolunteerFixedSiteBandLower : 0;
            nrVolunteerFixedSiteBandUpper = matrix.nrVolunteerFixedSiteBandUpper != null ? matrix.nrVolunteerFixedSiteBandUpper : 0; 
        }
        Decimal remaining = 0;
        Integer shiftCount = 0;
        for(FetchRelatedDriveData.DMLDriveShift driveShift : driveShifts)
        {
            Decimal totalProcedureProjectedForDriveShift = 0;
            Decimal plateletProcProjForDriveShift = 0;
            Decimal plasmaProcProjForDriveShift = 0;
            Decimal wbProcProjForDriveShift = 0;
            Decimal x2rbcProcProjForDriveShift = 0;
            Decimal numberOfVolunteerDonorAmbassadors = 0;
            Decimal driveShiftPlateletRounds = driveShift.plateletRounds;               
            Decimal driveShiftDrawHours = (skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd)) / 60;
            

            plateletProcProjForDriveShift = ((drivePlateLetProcedureProjected/drivePlateletRounds)*driveShiftPlateletRounds).setScale(2, RoundingMode.HALF_DOWN);
            plasmaProcProjForDriveShift = ((drivePlasmaProcedureProjected/drivePlateletRounds)*driveShiftPlateletRounds).setScale(2, RoundingMode.HALF_DOWN);
            wbProcProjForDriveShift = ((driveWBProcedureProjected/driveDrawHours)*driveShiftDrawHours).setScale(2, RoundingMode.HALF_DOWN);
            x2rbcProcProjForDriveShift = ((drive2RBCProcedureProjected/driveDrawHours)*driveShiftDrawHours).setScale(2, RoundingMode.HALF_DOWN);

            totalProcedureProjectedForDriveShift = Math.ceil(plateletProcProjForDriveShift+plasmaProcProjForDriveShift+wbProcProjForDriveShift+x2rbcProcProjForDriveShift);
        
            if(shiftCount == 1 && remaining+totalProcedureProjectedForDriveShift > driveTotal)
            {
                totalProcedureProjectedForDriveShift = driveTotal - remaining;
            }
            
            remaining= shiftCount==0 ? totalProcedureProjectedForDriveShift :0;
            
            if (totalProcedureProjectedForDriveShift < nrVolunteerFixedSiteBandLower)
            {
                numberOfVolunteerDonorAmbassadors = 0;
            }else if (totalProcedureProjectedForDriveShift <= nrVolunteerFixedSiteBandUpper && totalProcedureProjectedForDriveShift >= nrVolunteerFixedSiteBandLower)
            {
                numberOfVolunteerDonorAmbassadors = 1;
            }else if (totalProcedureProjectedForDriveShift > nrVolunteerFixedSiteBandUpper)
            {
                numberOfVolunteerDonorAmbassadors = 2;
            }

            driveShift.volunteerSetup = numberOfVolunteerDonorAmbassadors;
            staffingComplement.numberOfVolunteerDonorAmbassadors = driveShift.volunteerSetup;
            if(shiftCount==0)
            {
                mapResourceQuantity.put('Donor Ambassador 1' , driveShift.volunteerSetup);
            }
            else{
                mapResourceQuantity.put('Donor Ambassador 2' , driveShift.volunteerSetup);
            }
            
            mapResourceQuantity.put('volunteerSetup' , driveShift.volunteerSetup);
            shiftCount++;
        }

            return staffingComplement;
        
        }
        // HRP-10456 --> Ends here

    /******** Point no 5 **********/
    static map<String, Decimal> CalculateResourceQuantity(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive)
    {
        map<String, Decimal> mapResourceQuantity = new map<String, Decimal>(); 

        calculateFixedSiteStaffQuantity(data, drive);		// 5a
        mapResourceQuantity = calculateTotalStaffQuantity(data, drive);		// HRP-11547

        return mapResourceQuantity;
    }

    /*** Point no 5a ***/
    static void calculateFixedSiteStaffQuantity(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive){
        decimal totalDriveProcedureCapacity = 0;
        if(drive.account.fixedSiteProcedureProjections != null){
        	for (FetchRelatedDriveData.DMLFixedSiteProcedureProjection setting : drive.account.fixedSiteProcedureProjections) {
                decimal donorsPerHoursCapacity = getFixedSiteDonorsCapacity(data, drive, setting.procedureType);           
                decimal projectedTypeHours = getDrawHoursAdjusted(data, drive, setting.procedureType);            
                decimal requiredStaff = 0;
                decimal driveProcedureCapacity = 0;
                
                // Platelet staff calculation logic has been changed as part of HRP-11547

                /*if (setting.procedureType == Constants.PROCEDURE_TYPE_PLATELET) {
                    driveProcedureCapacity = calculateStaff(setting, drive.plateletProjectedProcedures != null ? drive.plateletProjectedProcedures : 0, projectedTypeHours,donorsPerHoursCapacity);
                    requiredStaff = Math.ceil(driveProcedureCapacity);
                    totalDriveProcedureCapacity += driveProcedureCapacity;
                    
                    drive.projectedPlateletDonors = Math.ceil(requiredStaff * projectedTypeHours);
                    
                }*/

                if (setting.procedureType == Constants.PROCEDURE_TYPE_PLASMA) {
                    driveProcedureCapacity = calculateStaff(setting, drive.plasmaProjectedProcedures,projectedTypeHours,donorsPerHoursCapacity);
                    requiredStaff = driveProcedureCapacity; //HRP-11547
                    totalDriveProcedureCapacity += driveProcedureCapacity;
                    
                    drive.projectedPlasmaDonors = Math.ceil(requiredStaff * projectedTypeHours);

                    mapResourceQuantity.put(setting.procedureType+'Staff' ,requiredStaff); //HRP-11547
                    
                }
                else if (setting.procedureType == Constants.PROCEDURE_TYPE_WB) {
                    driveProcedureCapacity = calculateStaff(setting, drive.wbProjectedProcedures,projectedTypeHours,donorsPerHoursCapacity);
                    requiredStaff = driveProcedureCapacity; // HRP-11547
                    //mapResourceQuantity.put('noOfWBResources', requiredStaff);
                    totalDriveProcedureCapacity += driveProcedureCapacity;
                    
                    drive.projectedWbDonors = Math.ceil(requiredStaff * projectedTypeHours); 
                    
                    mapResourceQuantity.put(setting.procedureType+'Staff' ,requiredStaff); //HRP-11547
                }
                else if (setting.procedureType == Constants.PROCEDURE_TYPE_2RBC) {
                    driveProcedureCapacity= calculateStaff(setting, drive.x2rbcProjectedProcedures,projectedTypeHours,donorsPerHoursCapacity);
                    requiredStaff = driveProcedureCapacity; // HRP-11547
                    totalDriveProcedureCapacity += driveProcedureCapacity;
                    drive.projected2rbcDonors = Math.ceil(requiredStaff * projectedTypeHours);  
                    
                    mapResourceQuantity.put(setting.procedureType+'Staff' ,requiredStaff); //HRP-11547
                }      

                /*mapResourceQuantity.put(setting.procedureType + '- Capacity ', driveProcedureCapacity);
                mapResourceQuantity.put(setting.resourceRole + '-' +setting.procedureType , requiredStaff);*/
        	}

            // HRP-11547 --> Starts Here (1)
            if(drive.plateletProjectedProcedures > 0)
            {
                Decimal donorsPerRoundCapacity = getFixedSiteDonorsCapacity(data, drive, Constants.PROCEDURE_TYPE_PLATELET);
                Decimal projectedTypeHours = getDrawHoursAdjusted(data, drive, Constants.PROCEDURE_TYPE_PLATELET);  

                Decimal plateletStaff = (drive.plateletProjectedProcedures / drive.plateletRounds / donorsPerRoundCapacity); //HRP-11547

                drive.projectedPlateletDonors = Math.ceil(plateletStaff * projectedTypeHours);

                mapResourceQuantity.put(Constants.PROCEDURE_TYPE_PLATELET+'Staff',plateletStaff);

            }
            // HRP-11547 --> Ends Here (1)
            mapResourceQuantity.put('Equipment - 2RBC Asset', drive.numberOf2rbcAssets);
        }

        // drive.driveProcedureCapacity = Math.ceil(totalDriveProcedureCapacity); Prodcedure capacity calculation logic has been changed as part of HRP-11547
    }   
    
   // HRP - 10456 --> Starts Here
    /**** Point no 11 - Calculate Drive Shift Procedure Capacity ****/
    static void calculateDriveShiftProcedureCapacityValue(FetchRelatedDriveData.DMLDrive drive, List<FetchRelatedDriveData.DMLDriveShift> driveShifts)
    {
        Decimal driveProcedureCapacity = drive.driveProcedureCapacity;
        Decimal drivePlateletRounds = drive.plateletRounds;
        Decimal driveDrawHours = drive.drawHours;
        Decimal remainingCapacityValue = 0;      

        if(driveShifts.size() > 1)
        {
            for(FetchRelatedDriveData.DMLDriveShift driveShift : driveShifts)
            {             
                Decimal driveShiftProcedureCapacity = 0;  
                Decimal totalDriveShiftProcedureCapacity = 0;
                Decimal driveShiftPlateletRounds = driveShift.plateletRounds;               
                Decimal driveShiftDrawHours = (skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd)) / 60;

                if(mapResourceQuantity.keySet() != null)
                {
                    for(String capacity : mapResourceQuantity.keySet())
                    {
                        if(capacity.contains('Capacity') && (capacity.contains('Plasma') || capacity.contains('Platelet')))
                        {       
                            driveShiftProcedureCapacity =  ((mapResourceQuantity.get(capacity)/drivePlateletRounds)*driveShiftPlateletRounds).setScale(2, RoundingMode.HALF_DOWN);
                            
                            totalDriveShiftProcedureCapacity+= driveShiftProcedureCapacity;
                                         
                        }
                        if(capacity.contains('Capacity') && (capacity.contains('2RBC') || capacity.contains('WB')))
                        {
                            driveShiftProcedureCapacity =  ((mapResourceQuantity.get(capacity)/driveDrawHours)*driveShiftDrawHours).setScale(2, RoundingMode.HALF_DOWN);
                            
                            totalDriveShiftProcedureCapacity += driveShiftProcedureCapacity;
                            
                        }
                    }
                }
                
                driveShift.procedureCapacity = totalDriveShiftProcedureCapacity.round(System.RoundingMode.HALF_UP);
                
                if(remainingCapacityValue < driveShift.procedureCapacity && remainingCapacityValue!= 0)
                {
                    driveShift.procedureCapacity = remainingCapacityValue;
                    
                } 
                remainingCapacityValue = driveProcedureCapacity - driveShift.procedureCapacity;
                
                
            }
        }else{
            driveShifts[0].procedureCapacity = driveProcedureCapacity;
        }
    }
    // HRP - 10456 --> Ends Here

    static decimal getFixedSiteDonorsCapacity(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, String staffType) {
        FetchRelatedDriveData.DMLStaffingDecisionMatrix matrix = getStaffingDecisionMatrix(data, drive);
        Decimal donorsPerHourCapacicy = 0;		//  Procedure Type Capacity 
        if (matrix != null) {
            if (staffType.contains(Constants.PROCEDURE_TYPE_PLATELET)) {
                donorsPerHourCapacicy = matrix.plateletRoundCapacity; //HRP-11547
            }
            else if (staffType.contains(Constants.PROCEDURE_TYPE_PLASMA)) {
                donorsPerHourCapacicy = matrix.plasmaHourlyCapacity;
            }
            else if (staffType.contains(Constants.PROCEDURE_TYPE_WB)) {
                donorsPerHourCapacicy = matrix.wbHourlyCapacity;
            }
            else if (staffType.contains(Constants.PROCEDURE_TYPE_2RBC)) {
                donorsPerHourCapacicy = matrix.x2rbcHourlyCapacity;
            }
        }        
        return donorsPerHourCapacicy;
    }
    
    static decimal getDrawHoursAdjusted(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, String staffType) {
        DateTime driveStart = DateTime.newInstance(drive.driveDate, drive.startTime);
        DateTime driveEnd = DateTime.newInstance(drive.driveDate, drive.endTime);       
        
        if (staffType.contains(Constants.PROCEDURE_TYPE_PLATELET)) {
            driveStart = driveStart;
            driveEnd = driveEnd;
        }
        else if (staffType.contains(Constants.PROCEDURE_TYPE_PLASMA)) {
            driveStart = driveStart.addMinutes(60);
            driveEnd = driveEnd.addMinutes(-50);
        }
        else if (staffType.contains(Constants.PROCEDURE_TYPE_WB)) {
            driveStart = driveStart.addMinutes(60);
            FetchRelatedDriveData.DMLCollectionOperation coRec = data.mapCollectionOperation.get(drive.collectionOperationId);
            if(!string.isBlank(coRec.skipLastAppointmentFor) && coRec.skipLastAppointmentFor.contains(drive.typeOfDrive)){
                driveEnd = driveEnd.addMinutes(-15);
            }else{
                driveEnd = driveEnd;
            }
        }
        else if (staffType.contains(Constants.PROCEDURE_TYPE_2RBC)) {
            driveStart = driveStart.addMinutes(60);
            driveEnd = driveEnd.addMinutes(-30);
        }
        
        Decimal driveDuration = skedDateTimeUtils.getDifferentMinutes(driveStart, driveEnd); // HRP -10456
        driveDuration = driveDuration < 0 ? 0 : driveDuration / 60;
        return driveDuration;
    }
    static decimal calculateStaff(
        FetchRelatedDriveData.DMLFixedSiteProcedureProjection setting,
        decimal projectedProcedure,
        decimal projectedTypeHours,
        decimal donorsPerHoursCapacity
    ) {
        
        decimal requiredStaff = projectedProcedure / (1 - setting.qns / 100) / (1 - setting.deferral / 100) / projectedTypeHours / donorsPerHoursCapacity;
        return requiredStaff;
    }

    /*** Point no 5b ***/
    static map<String, Decimal> calculateTotalStaffQuantity (FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive)
    {
        if(drive.totalProceduresProjected != NULL)
        {          
            Decimal totalStaff = 0;

            for(String role: mapResourceQuantity.keySet())
            {
                if(role.contains('Staff')) // HRP-11547
                {
                    totalStaff += mapResourceQuantity.get(role);
                }
            }
           
            Decimal numberOfApheresisCharge = 1;  
            totalStaff = Math.round(totalStaff); // HRP-11547
            mapResourceQuantity.put(Constants.APHERESIS , totalStaff);
            mapResourceQuantity.put(Constants.APHERESIS_CHARGE , numberOfApheresisCharge);         
            mapResourceQuantity.put('staffSetup' , totalStaff+numberOfApheresisCharge);
        }

        return mapResourceQuantity;
    }
    
    // HRP-11547 --> Starts Here (2)

    static Map<String, Decimal> getFSPPTypeAndDeferalQnsValue(FetchRelatedDriveData.DMLDrive drive) {
        Map<String, Decimal> fsppTypeVsValuesMap = new Map<String,Decimal>();
        if(drive.account.fixedSiteProcedureProjections != NULL) {
        	for (FetchRelatedDriveData.DMLFixedSiteProcedureProjection setting : drive.account.fixedSiteProcedureProjections) {
                if(setting.procedureType != Constants.PROCEDURE_TYPE_PLATELET) {
                    if((setting.effectiveStartDate == NULL || setting.effectiveStartDate <= drive.driveDate) 
                        && (setting.effectiveEndDate == NULL || setting.effectiveEndDate >= drive.driveDate)) {
                        fsppTypeVsValuesMap.put('Deferral_'+setting.procedureType+'Staff', setting.deferral / 100);
                        fsppTypeVsValuesMap.put('QNS_'+setting.procedureType+'Staff', setting.qns / 100);
                    }
                }
            }
        }
        return fsppTypeVsValuesMap;
    }

    public static void calculateDriveProcedureCapacity(FetchRelatedDriveData.DMLData data, 
                                                       FetchRelatedDriveData.DMLDrive drive,
                                                       Map<String, Decimal> mapResourceQuantity,
                                                       Map<String, Decimal> fsppTypeAndValuesMap)
    {
        
        Decimal individualProcedureCapacity = 0;

        for(String staff : mapResourceQuantity.keySet())
        {
            if(staff.contains('Staff'))
            {
                Decimal donorsPerHoursCapacity = getFixedSiteDonorsCapacity(data, drive, staff);

                Decimal projectedTypeHours = getDrawHoursAdjusted(data, drive, staff);
                        
                individualProcedureCapacity += getIndividualProcedureCapacity(drive.plateletRounds, staff, mapResourceQuantity.get(staff),fsppTypeAndValuesMap, projectedTypeHours, donorsPerHoursCapacity);
            
            }
        }
                  
        drive.driveProcedureCapacity = individualProcedureCapacity.round(System.RoundingMode.HALF_UP);
       
    }

    static Decimal getIndividualProcedureCapacity(Decimal plateletRounds, String staff, Decimal noOfStaff, Map<String,Decimal> fsppTypeAndValuesMap, Decimal projectedTypeHours, Decimal donorsPerHoursCapacity)
    {
        Decimal deferralValue = 0;
        Decimal qnsValue = 0; 
        Decimal procedureCapacity = 0;
        
        for(String fspp : fsppTypeAndValuesMap.keySet())
        {             
            if(fspp.contains(staff) && fspp.contains('Deferral'))
            {
                deferralValue = fsppTypeAndValuesMap.get(fspp);
            }
            else if(fspp.contains(staff) && fspp.contains('QNS'))
            {
                qnsValue = fsppTypeAndValuesMap.get(fspp);
            }
        }

        if(!staff.contains(Constants.PROCEDURE_TYPE_PLATELET))  
        {
            procedureCapacity = (noOfStaff * (1 - deferralValue) * (1 - qnsValue) * projectedTypeHours * donorsPerHoursCapacity).setScale(2);
        }
        else{
            procedureCapacity = (noOfStaff * plateletRounds * donorsPerHoursCapacity).setScale(2);
        }

        mapResourceQuantity.put(staff+'Capacity',procedureCapacity);


        return procedureCapacity;

    }

    //HRP-11547 --> Ends here (2)
    
    
    /*********************************************************** Staffing Decision Matrix ***********************************************************/
    static FetchRelatedDriveData.DMLStaffingDecisionMatrix getStaffingDecisionMatrix(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        FetchRelatedDriveData.DMLStaffingDecisionMatrix matrix;
        for (FetchRelatedDriveData.DMLCollectionOperationSdm collectionOperationSdm : data.collectionOperationSdms) {
            if (collectionOperationSdm.collectionOperationId == drive.collectionOperationId
                &&  collectionOperationSdm.staffingDecisionMatrix.driveType == drive.typeOfDrive
                && collectionOperationSdm.effectiveStartDate <= drive.driveDate 
                && (collectionOperationSdm.effectiveEndDate == null || drive.driveDate <= collectionOperationSdm.effectiveEndDate)) {
                    matrix = collectionOperationSdm.staffingDecisionMatrix;
                }
        }
        
        return matrix;    
    }
    /***********************************************************************/
    
    static FetchRelatedDriveData.DMLDriveShift initiateDriveShift(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        FetchRelatedDriveData.DMLDriveShift driveShift = new FetchRelatedDriveData.DMLDriveShift();
        driveShift.drive = drive;
        driveShift.driveDate = drive.driveDate;
        driveShift.endTime = drive.endTime;
        driveShift.startTime = drive.startTime;
        
        driveShift.drawDuration = drive.drawDuration;
        driveShift.drawHours = drive.drawHours;
        driveShift.drawStart = drive.drawStart;
        driveShift.drawEnd = drive.drawEnd;
        return driveShift;
    }
    
    /********* Point no 6c *********/
    // HRP-11295(Changed method return type)
    static List<FetchRelatedDriveData.DMLJob> populateDriveShiftJobs(FetchRelatedDriveData.DMLData data, 
                                                                    FetchRelatedDriveData.DMLDriveShift driveShift, 
                                                                    driveStaffingComplementModel staffingComplement, 
                                                                    Integer shiftNo) 
    {        
        driveShift.jobs = new List<FetchRelatedDriveData.DMLJob>();

        if (mapResourceQuantity.get('Equipment - 2RBC Asset') > 0 && shiftNo==0) {
            FetchRelatedDriveData.DMLJob job = new FetchRelatedDriveData.DMLJob();
            job.driveSiteId = driveShift.drive.driveSiteId;
            job.assetType = Constants.EQUIPMENT;
            job.type = Constants.EQUIPMENT;
            job.quantity = mapResourceQuantity.get('Equipment - 2RBC Asset');
            job.equipmentSubtype = '2RBC Asset'; // HRP- 10456
            driveShift.jobs.add(job);
        }       
        if (mapResourceQuantity.get(Constants.APHERESIS) > 0) {
            FetchRelatedDriveData.DMLJob job = new FetchRelatedDriveData.DMLJob();
            job.driveSiteId = driveShift.drive.driveSiteId;
            job.resourceRole = Constants.APHERESIS;
            job.quantity = mapResourceQuantity.get(Constants.APHERESIS);
            driveShift.jobs.add(job);
        }
        if (mapResourceQuantity.get(Constants.APHERESIS_CHARGE) > 0) {
            FetchRelatedDriveData.DMLJob job = new FetchRelatedDriveData.DMLJob();
            job.driveSiteId = driveShift.drive.driveSiteId;
            job.resourceRole = Constants.APHERESIS_CHARGE;
            job.type = Constants.APHERESIS_CHARGE;
            job.quantity = mapResourceQuantity.get(Constants.APHERESIS_CHARGE);
            driveShift.jobs.add(job);
        }
        if((mapResourceQuantity.get(Constants.DONOR_AMBASSADOR+' 1') > 0 && shiftNo == 0) ||
        (mapResourceQuantity.get(Constants.DONOR_AMBASSADOR+' 2') > 0 && shiftNo == 1)) {
            FetchRelatedDriveData.DMLJob job = new FetchRelatedDriveData.DMLJob();
            job.driveSiteId = driveShift.drive.driveSiteId;
            job.volunteerRole = Constants.DONOR_AMBASSADOR;
            job.type = Constants.DONOR_AMBASSADOR;
            job.redcrossVolunteerQuantity = driveShift.volunteerSetup;
            job.sponsorVolunteerQuantity = 0;
            job.quantity = job.redcrossVolunteerQuantity + job.sponsorVolunteerQuantity;
            driveShift.jobs.add(job);
        }
        driveShift.vehiclesNeeded = 0;
        return driveShift.jobs; // HRP-11295
    }
      
   static void updateShiftFixedSiteSetup(FetchRelatedDriveData.DMLDriveShift driveShift, Integer shiftNo) {
        driveShift.staffSetup  = mapResourceQuantity.get('staffSetup');
        driveShift.equipment = shiftNo == 0 ? mapResourceQuantity.get('Equipment - 2RBC Asset'): 0;
        driveShift.volunteerSetup = mapResourceQuantity.get('volunteerSetup'); // HRP - 10456
    }
    
    
    static List<FetchRelatedDriveData.DMLDriveShift> buildMultiDriveShifts(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive,FetchRelatedDriveData.DMLDriveShift inputDriveShift, decimal noOfDriveShift)
    {
        /****Point No 9d****/        
        Decimal wbProjectedProcedure = 0;
        Decimal xrbcProjectedProcedure = 0;
        Decimal plateletProjectedProcedure = 0;
        Decimal plasmaProjectedProcedure = 0;
        Decimal totalProcedureProjected;
        Decimal totalProductsProjected;
        
        Decimal wbProjectedProcedurePerShift = Math.ceil(drive.wbProjectedProcedures/drive.plateletRounds*noOfDriveShift);
        Decimal xrbcProjectedProcedurePerShift = Math.ceil(drive.x2rbcProjectedProcedures/drive.plateletRounds*noOfDriveShift);
    	Decimal plateletProjectedProcedurePerShift = drive.plateletProjectedProcedures != null ? Math.ceil(drive.plateletProjectedProcedures/drive.plateletRounds*noOfDriveShift) : 0;
    	Decimal plasmaProjectedProcedurePerShift = Math.ceil(drive.plasmaProjectedProcedures/drive.plateletRounds*noOfDriveShift);
        
        List<FetchRelatedDriveData.DMLDriveShift> driveShifts = new List<FetchRelatedDriveData.DMLDriveShift>();
        
        if(true) { 
            integer firstShiftRounds = integer.valueOf(Math.ceil(drive.plateletRounds / noOfDriveShift));
            integer remainingRounds = integer.valueOf(Math.ceil(drive.plateletRounds));
            integer hourPerRound = 3;
            
            for (integer i = 0; i < noOfDriveShift; i++) {      
                FetchRelatedDriveData.DMLDriveShift driveShift= new FetchRelatedDriveData.DMLDriveShift(inputDriveShift, i+1);
                
                // HRP - 10012 ---> Start
                
                driveShift.wbProjectedProcedure = (i == noOfDriveShift - 1 ) ? drive.wbProjectedProcedures - wbProjectedProcedure : wbProjectedProcedurePerShift;
                driveShift.xrbcProjectedProcedure = (i == noOfDriveShift - 1) ? drive.x2rbcProjectedProcedures - xrbcProjectedProcedure : xrbcProjectedProcedurePerShift;
        		driveShift.plateletProjectedProcedure = (i == noOfDriveShift - 1) ? drive.plateletProjectedProcedures - plateletProjectedProcedure : plateletProjectedProcedurePerShift;
        		driveShift.plasmaProjectedProcedure = (i == noOfDriveShift - 1) ? drive.plasmaProjectedProcedures - plasmaProjectedProcedure : plasmaProjectedProcedurePerShift;
        
        		driveShift.totalProjectedProcedure = driveShift.xrbcProjectedProcedure + driveShift.wbProjectedProcedure + 
            		driveShift.plasmaProjectedProcedure + driveShift.plateletProjectedProcedure;		
        		driveShift.totalProductsProjected = driveShift.xrbcProjectedProcedure * 2 + driveShift.wbProjectedProcedure + 
            		driveShift.plasmaProjectedProcedure + driveShift.plateletProjectedProcedure;	
      
                wbProjectedProcedure += driveShift.wbProjectedProcedure;
                xrbcProjectedProcedure += driveShift.xrbcProjectedProcedure;
                plateletProjectedProcedure += driveShift.plateletProjectedProcedure;
                plasmaProjectedProcedure +=driveShift.plasmaProjectedProcedure; 
				
                // HRP - 10012 ---> End

                DateTime drawHoursStart, drawHoursEnd;
                decimal plateletRounds;
                
                if (noOfDriveShift == 1) { //first & only drive shift
                    plateletRounds = firstShiftRounds;
                    drawHoursStart = drive.drawStart;
                    drawHoursEnd = drive.drawEnd;
                }else{
                    plateletRounds = (i != noOfDriveShift-1) ? firstShiftRounds : remainingRounds;
                    drawHoursStart = (i == 0) ? drive.drawStart : driveShifts[i-1].drawEnd;
                    drawHoursEnd = (i != noOfDriveShift-1) ? drawHoursStart.addHours(firstShiftRounds * hourPerRound) : drive.drawEnd;
                }
                remainingRounds = remainingRounds - Integer.valueOf(plateletRounds);
                
                driveShift.plateletRounds = plateletRounds;
                driveShift.drawStart = drawHoursStart;
                driveShift.startTime = drawHoursStart.timeGmt();
                driveShift.drawEnd = drawHoursEnd;
                driveShift.endTime = drawHoursEnd.timeGmt(); 
				updateShiftFixedSiteSetup(driveShift, i);
                driveShifts.add(driveShift);
            }

            /********* POint no 6e *********/
            // HRP-10456 --> Starts Here
            driveStaffingComplementModel staffingComplement = calculateVolunteerDonorAmbassadorValue(data,drive,driveShifts); 
            DriveGenerationUtil.TravelTimeSettingModel travelTimeModel = getTravelTimeSpecificInfo(data,drive); //HRP-11908
            Integer shiftCount = 0;
            List<FetchRelatedDriveData.DMLJob> jobList = new List<FetchRelatedDriveData.DMLJob>(); // HRP-11295

            for (FetchRelatedDriveData.DMLDriveShift driveShift : driveShifts) {
                Map<String, DriveGenerationUtil.TimeConfigurationModel> timeConfig = prepareTimeConfigurationModel(data, drive, shiftCount, noOfDriveShift); //HRP-11908
                jobList.addAll(populateDriveShiftJobs(data, driveShift,staffingComplement,shiftCount)); // HRP-11295
                updateShiftFixedSiteSetup(driveShift, shiftCount);
                populateTravelTimeOnJobs(data, drive, driveShift, travelTimeModel, timeConfig); //HRP-11908
                applyRoleTimeForMultiDriveShift(data, driveShift, timeConfig); // HRP-11908
                populateShiftTime(data, driveShift, drive, shiftCount, noOfDriveShift); // HRP-11295
                shiftCount++;
                // HRP-10456 --> Ends Here

                // HRP-11295 --> Starts Here
                if(shiftCount == noOfDriveShift) {
                    updateEquipmentJobFinishTime(jobList); 
                }
                // HRP-11295 --> Ends Here

                populateLunchBreakTime(data, drive, driveShift);
                generateShiftSlots(data, drive, driveShift, noOfDriveShift);
            }
        }
        return driveShifts;
    }
    
    /*********************************************************** Role Time Data ***********************************************************/

    // HRP-11908 --> Starts Here 
    private static String getResourceRoleGroupUponResourceRole(FetchRelatedDriveData.DMLData data, String resourceRole) {
        return data.map_resourceRole_resourceRoleGroup.get(resourceRole);
    }

    private static Map<String, DriveGenerationUtil.TimeConfigurationModel> prepareTimeConfigurationModel(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive,
        Integer shiftCount,
        Decimal noOfDriveShift
    ) {
        Map<string, FetchRelatedDriveData.DMLRoleTimeDetail> map_resourceRoleGroup_roleTimeDetail = reduceMapRoleTimeDetailByDrive(data, drive);
        Map<string, List<FetchRelatedDriveData.DMLRoleTimeVariance>> map_resourceRoleGroup_roleTimeVariance = reduceMapRoleTimeVarianceByDrive(data, drive);
        Map<String, DriveGenerationUtil.TimeConfigurationModel> map_resourceRoleGroup_timeConfig = generateTimeConfiguration(data, drive, shiftCount, noOfDriveShift, map_resourceRoleGroup_roleTimeDetail, map_resourceRoleGroup_roleTimeVariance);
        return map_resourceRoleGroup_timeConfig;
    }

    private static Map<String, DriveGenerationUtil.TimeConfigurationModel> generateTimeConfiguration(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive,
        Integer shiftCount,
        Decimal noOfDriveShift,
        Map<string, FetchRelatedDriveData.DMLRoleTimeDetail> map_resourceRoleGroup_roleTimeDetail,
        Map<string, List<FetchRelatedDriveData.DMLRoleTimeVariance>> map_resourceRoleGroup_roleTimeVariance
    ) {

        Decimal breakdownTimeThreshold = drive.collectionOperation.breakdownTimeThreshold;
        Decimal setupTimeThreshold = drive.collectionOperation.setupTimeThreshold;
        Map<String, DriveGenerationUtil.TimeConfigurationModel> map_resourceRoleGroup_timeConfig = new Map<String, DriveGenerationUtil.TimeConfigurationModel>();
        for(String resourceRoleGroup : data.resourceRoleGroups) {
            DriveGenerationUtil.TimeConfigurationModel config = new DriveGenerationUtil.TimeConfigurationModel();
            config.resourceRoleGroup = resourceRoleGroup;
            if(map_resourceRoleGroup_roleTimeDetail.containsKey(resourceRoleGroup)) {
                config.leadTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).leadTime != NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).leadTime : 0;
                config.setupTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).setupTime!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).setupTime : 0;
                config.breakDownTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).breakdownTime!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).breakdownTime : 0;
                config.wrapUpTime = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).wrapUpTime!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).wrapUpTime : 0;
                config.siteLogisticsTo = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsTo!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsTo : 0; //HRP-11226
                config.siteLogisticsBack = map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsBack!= NULL ? map_resourceRoleGroup_roleTimeDetail.get(resourceRoleGroup).siteLogisticsBack : 0; //HRP-11226
            }

            if(map_resourceRoleGroup_roleTimeVariance.containsKey(resourceRoleGroup)) {
                List<FetchRelatedDriveData.DMLRoleTimeVariance> roleTimeVariances = map_resourceRoleGroup_roleTimeVariance.get(resourceRoleGroup);
                for (FetchRelatedDriveData.DMLRoleTimeVariance roleTimeVariance : roleTimeVariances) {
                    Decimal amount = roleTimeVariance.varianceAmount;
                    Set<string> appliesTo = new Set<string>();
                    appliesTo.addAll(roleTimeVariance.varianceAppliesTo.split(';'));
                    if (roleTimeVariance.bufferType == 'Subtract') {
                        amount = -1 * amount;
                    }

                    if (appliesTo.contains('Lead Time')) {
                        config.leadTime += amount;
                    }
                    if (appliesTo.contains('Setup Time')) {
                        config.setupTime += amount;
                    }
                    if (appliesTo.contains('Breakdown Time')) {
                        config.breakdownTime += amount;
                    }
                    if (appliesTo.contains('Wrap-up Time')) {
                        config.wrapUpTime += amount;
                    }
                    if ((appliesTo.contains('Travel Time To'))) { 
                        config.travelTime += amount;
                    }
                    if ((appliesTo.contains('Travel Time From'))) {
                        config.travelTime2 += amount;
                    }
                    if (appliesTo.contains('Site Logistics To')) { //HRP-11226 start
                        config.siteLogisticsTo += amount;
                    }
                    if (appliesTo.contains('Site Logistics Back')) {
                        config.siteLogisticsBack += amount;
                    } //HRP-11226 end 
                }
            }
            if(shiftCount > 0) {
                if(config.setupTime > setupTimeThreshold) {
                    config.setupTime = setupTimeThreshold;
                }
            }
            if(shiftCount < noOfDriveShift - 1) {
                if(config.breakdownTime > breakdownTimeThreshold) {
                    config.breakdownTime = breakdownTimeThreshold;
                }
            }
            config = compareAndAdjustTimeConfiguration(config);
            map_resourceRoleGroup_timeConfig.put(config.resourceRoleGroup, config); 
        }
        return map_resourceRoleGroup_timeConfig;
    }
    
    // HRP-11046 (Changed the method parameters to incorporate changes for 11046)
    static void applyRoleTimeForMultiDriveShift(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDriveShift driveShift, 
        Map<String, DriveGenerationUtil.TimeConfigurationModel> timeConfig
    ) {
        if (driveShift.jobs != NULL && !driveShift.jobs.isEmpty()) {
            applyRoleTimeForSingleDriveShift(data, driveShift, timeConfig);
        }
    }
    
    static void applyRoleTimeForSingleDriveShift(
        FetchRelatedDriveData.DMLData data,
        FetchRelatedDriveData.DMLDriveShift driveShift, 
        Map<String, DriveGenerationUtil.TimeConfigurationModel> timeConfig
    ) {
        for (FetchRelatedDriveData.DMLJob job : driveShift.jobs) {
            if (!string.isBlank(job.resourceRole)) {
                job.leadTime = 0;
                job.setupTime = 0;
                job.breakdownTime = 0;
                job.wrapUpTime = 0;
                job.siteLogisticsTo = 0; //HRP-11226
                job.siteLogisticsBack = 0; //HRP-11226
                if (!string.isBlank(job.resourceRole) && timeConfig.containsKey(getResourceRoleGroupUponResourceRole(data, job.resourceRole))) {
                    DriveGenerationUtil.TimeConfigurationModel config = timeConfig.get(getResourceRoleGroupUponResourceRole(data, job.resourceRole)); //HRP-11908
                    job.leadTime = config.leadTime != NULL ? config.leadTime : 0;
                    job.setupTime = config.setupTime != NULL ? config.setupTime : 0;
                    job.breakdownTime = config.breakdownTime != NULL ? config.breakdownTime : 0;
                    job.wrapUpTime = config.wrapUpTime != NULL ? config.wrapUpTime : 0;
                    job.siteLogisticsTo = config.siteLogisticsTo != NULL ? config.siteLogisticsTo : 0; //HRP-11226
                    job.siteLogisticsBack = config.siteLogisticsBack != NULL ? config.siteLogisticsBack : 0; //HRP-11226
                }
            }
        }          
    }

    static DriveGenerationUtil.TimeConfigurationModel compareAndAdjustTimeConfiguration(DriveGenerationUtil.TimeConfigurationModel timeConfig) {
        if(timeConfig != NULL) {
            timeConfig.leadTime = Math.max(0, timeConfig.leadTime);
            timeConfig.setupTime = Math.max(0, timeConfig.setupTime);
            timeConfig.breakdownTime = Math.max(0, timeConfig.breakdownTime);
            timeConfig.wrapUpTime = Math.max(0, timeConfig.wrapUpTime);
            timeConfig.travelTime = Math.max(0, timeConfig.travelTime);
            timeConfig.travelTime2 = Math.max(0, timeConfig.travelTime2);
            timeConfig.siteLogisticsTo = Math.max(0, timeConfig.siteLogisticsTo);
            timeConfig.siteLogisticsBack = Math.max(0, timeConfig.siteLogisticsBack);
        }
        return timeConfig;
    }
    // HRP-11908 --> Ends Here

    static Map<string, List<FetchRelatedDriveData.DMLRoleTimeVariance>> reduceMapRoleTimeVarianceByDrive(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        Map<string, List<FetchRelatedDriveData.DMLRoleTimeVariance>> map_resourceRoleGroup_roleTimeVariance = new Map<string, List<FetchRelatedDriveData.DMLRoleTimeVariance>>();
        for (FetchRelatedDriveData.DMLRoleTimeVariance roleTimeVariance : data.roleTimeVariances) {
            for (string varianceResourceRoleGroup : roleTimeVariance.resourceRoleGroups) {
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
                    List<FetchRelatedDriveData.DMLRoleTimeVariance> variances;
                    if (map_resourceRoleGroup_roleTimeVariance.containsKey(varianceResourceRoleGroup)) { // HRP-11226 start
                        if(!map_resourceRoleGroup_roleTimeVariance.get(varianceResourceRoleGroup).isEmpty()){
                            variances = map_resourceRoleGroup_roleTimeVariance.get(varianceResourceRoleGroup);
                            variances.add(roleTimeVariance);
                            map_resourceRoleGroup_roleTimeVariance.put(varianceResourceRoleGroup, variances);
                        } else{
                            variances = new List<FetchRelatedDriveData.DMLRoleTimeVariance>();
                            variances.add(roleTimeVariance);
                            map_resourceRoleGroup_roleTimeVariance.put(varianceResourceRoleGroup, variances);
                        }
                    } else {
                        variances = new List<FetchRelatedDriveData.DMLRoleTimeVariance>();
                        variances.add(roleTimeVariance);
                        map_resourceRoleGroup_roleTimeVariance.put(varianceResourceRoleGroup, variances);
                    }
                }   
            }
        }
        return map_resourceRoleGroup_roleTimeVariance;
    }
    
    static Map<string, FetchRelatedDriveData.DMLRoleTimeDetail> reduceMapRoleTimeDetailByDrive(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        Map<string, FetchRelatedDriveData.DMLRoleTimeDetail> map_resourceRoleGroup_roleTimeDetail = new Map<string, FetchRelatedDriveData.DMLRoleTimeDetail>();
        for (FetchRelatedDriveData.DMLRoleTimeDetail roleTimeDetail : data.roleTimeDetails) {
            boolean isValid = roleTimeDetail.driveType == drive.typeOfDrive
                && roleTimeDetail.mobileType == drive.driveSite.physicalLocationType
                && roleTimeDetail.effectiveStartDate <= drive.driveDate
                && ((roleTimeDetail.effectiveEndDate == NULL) || (roleTimeDetail.effectiveEndDate >= drive.driveDate)) // HRP - 10626
                && (!roleTimeDetail.daysOfWeek.isEmpty() && roleTimeDetail.daysOfWeek.contains(drive.driveDay)) //HRP-9943
                && (drive.typeOfDrive != 'Fixed Site' || roleTimeDetail.fixedSiteOperationType == drive.driveSite.siteOperationType); // HRP - 9901
            if (isValid) {
                for (string detailResourceRoleGroup : roleTimeDetail.resourceRoleGroups) {
                    for (string resourceRoleGroup : roleTimeDetail.resourceRoleGroups) {
                        if ((roleTimeDetail.type == 'Collection Operation' && roleTimeDetail.collectionOperationId == drive.collectionOperationId) 
                            || (roleTimeDetail.type == 'Global' && !map_resourceRoleGroup_roleTimeDetail.containsKey(resourceRoleGroup))) {
                                map_resourceRoleGroup_roleTimeDetail.put(resourceRoleGroup, roleTimeDetail);
                            }
                    }
                }
            }
        }
        return map_resourceRoleGroup_roleTimeDetail;
    }
    
    /************ Lunch Break Calculations ************/
    // HRP - 10456 --> Starts Here

    static boolean isLunchBreakApplicable(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, FetchRelatedDriveData.DMLDriveShift driveShift)
    {
        Boolean isDriveShiftLengthmore = false;
        Decimal maxDurationBefore = 0;
        Decimal maxDurationAfter = 0;

        decimal driveShiftDurationV1 = skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd);

        for (FetchRelatedDriveData.DMLJob job : driveShift.jobs)
        {
            if (!string.isBlank(job.resourceRole) && !job.resourcerole.contains('Driving Roles'))
            {
                Decimal leadTime = job.leadTime != NULL ? job.leadTime : 0;
                Decimal setupTime = job.setupTime != NULL ? job.setupTime : 0;
                Decimal breakdownTime = job.breakdownTime != NULL ? job.breakdownTime : 0;
                Decimal wrapUpTime = job.wrapUpTime != NULL ? job.wrapUpTime : 0;
                Decimal travelTime = job.travelTime != NULL ? job.travelTime : 0;
                Decimal travelTime2 = job.travelTime2 != NULL ? job.travelTime2 : 0;
                Decimal siteLogisticsTo = job.siteLogisticsTo != NULL ? job.siteLogisticsTo : 0; //HRP-11226
                Decimal siteLogisticsBack = job.siteLogisticsBack != NULL ? job.siteLogisticsBack : 0; //HRP-11226
                
                Decimal durationBeforeDrawHours = leadTime + setupTime + travelTime + siteLogisticsTo; //HRP-11226 // Logic : Duration Before Draw Hours = Lead Time + SetUp Time + Travel Time
                
                if (drive.collectionOperation.lunchBreak && drive.collectionOperation.lunchBreakBeforeDrawHours)
                {
                    durationBeforeDrawHours += drive.collectionOperation.lunchBreakDurationFixedSite;
                }
                
                maxDurationBefore = maxDurationBefore < durationBeforeDrawHours ? durationBeforeDrawHours : maxDurationBefore;
                
                Decimal durationAfterDrawHours = breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack; //HRP-11226 // Logic : Duration After Draw Hours = Breakdown Time + Wrap up Time + Travel Time2
                
                maxDurationAfter = maxDurationAfter < durationAfterDrawHours ? durationAfterDrawHours : maxDurationAfter;
                
                Decimal driveShiftlength = driveShiftDurationV1 + maxDurationBefore + maxDurationAfter ;
                
                if(driveShiftlength >= 360 && drive.collectionOperation.lunchBreak)
                {
                    isDriveShiftLengthmore = true;
                }
            }
        }
        
        return isDriveShiftLengthmore;
    }

    // HRP - 10456 --> Ends Here

    /***** Populate lunch break timings per shift *******/
    static void populateLunchBreakTime(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, FetchRelatedDriveData.DMLDriveShift driveShift)
    {
        // HRP - 10456 --> Starts Here
        Boolean isLunchBreakNeeded = isLunchBreakApplicable(data,drive,driveShift);
        if(isLunchBreakNeeded)
        {
            driveShift.lunchBreak = TRUE;
        }
        else{
            driveShift.lunchBreak = FALSE;
        }
        // HRP - 10456 --> Ends Here
              
        decimal coMaxLunchBreakDuration = drive.maximumLunchBreakDuration != NULL ? drive.maximumLunchBreakDuration : 30;            
        FetchRelatedDriveData.DMLLunchBreakDefinition lunchBreakDefinition = findLunchBreakDefinition(data, coMaxLunchBreakDuration, driveShift.staffSetup);
        driveShift.signUpReduction = lunchBreakDefinition.slotReduction;
        
        driveShift.lunchBreakBeforeDrawHours = drive.collectionOperation.lunchBreakBeforeDrawHours;
            
        if (driveShift.lunchBreak == TRUE) { //HRP-9944
            
            DateTime lunchBreakStart, lunchBreakEnd;
            
            if (driveShift.lunchBreakBeforeDrawHours == TRUE) {
                driveShift.lunchBreakDuration = drive.collectionOperation.unpaidLunchBreakDuration;
                lunchBreakEnd = driveShift.drawStart;
                lunchBreakStart = lunchBreakEnd.addMinutes(integer.valueOf(-driveShift.lunchBreakDuration));
            }
            else {
                driveShift.lunchBreakDuration = lunchBreakDefinition.lunchBreakDuration;
                decimal driveShiftDuration = skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd);
                
                decimal drawDurationBeforeLunch = Math.floor((driveShiftDuration - driveShift.lunchBreakDuration) / 2);
                
                if (Math.mod(integer.valueOf(drawDurationBeforeLunch), 15) != 0) {
                    drawDurationBeforeLunch = Math.floor(drawDurationBeforeLunch / 15) * 15;                    
                }
                lunchBreakStart = driveShift.drawStart.addMinutes(integer.valueOf(drawDurationBeforeLunch));
                
                lunchBreakEnd = lunchBreakStart.addMinutes(integer.valueOf(driveShift.lunchBreakDuration));                
            }
            driveShift.lunchBreakStartTime = lunchBreakStart.timeGMT();
            driveShift.lunchBreakEndTime = lunchBreakEnd.timeGMT();
        }
    }
    
    static FetchRelatedDriveData.DMLLunchBreakDefinition findLunchBreakDefinition(FetchRelatedDriveData.DMLData data, decimal lunchBreakDuration, decimal staffSetup) {
        FetchRelatedDriveData.DMLLunchBreakSetting lunchBreakSetting;
        for (FetchRelatedDriveData.DMLLunchBreakSetting setting : data.lunchBreakSettings) {
            if (setting.maximumLunchBreakDuration == lunchBreakDuration) {
                lunchBreakSetting = setting;
                break;
            }
        }
        FetchRelatedDriveData.DMLLunchBreakDefinition lunchBreakDefinition;
        for (FetchRelatedDriveData.DMLLunchBreakDefinition definition : lunchBreakSetting.lunchBreakDefinitions) {
            if (definition.minNumberOfStaff <= staffSetup && staffSetup <= definition.maxNumberOfStaff) {
                lunchBreakDefinition = definition;
            }
        }
        return lunchBreakDefinition;
    }
    
    /*********************************************************** Shift Time Helper ***********************************************************/
    // HRP-11295 --> Restructed the method to incorprate new changes

    static void populateShiftTime(FetchRelatedDriveData.DMLData data, 
                                    FetchRelatedDriveData.DMLDriveShift driveShift,
                                    FetchRelatedDriveData.DMLDrive drive,
                                    Integer shiftCount,
                                    Decimal noOfDriveShift)
    {
        
        driveShift.drawDuration = skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd);
        driveShift.drawHours = driveShift.drawDuration / 60;
        
        DateTime minStart = driveShift.drawStart;
        DateTime maxEnd = driveShift.drawEnd;
        
        for (FetchRelatedDriveData.DMLJob job : driveShift.jobs)
        {
            if (!string.isBlank(job.resourceRole))
            {
                decimal leadTime = job.leadTime != NULL ? job.leadTime : 0;
                decimal setupTime = job.setupTime != NULL ? job.setupTime : 0;
                decimal breakdownTime = job.breakdownTime != NULL ? job.breakdownTime : 0;
                decimal wrapUpTime = job.wrapUpTime != NULL ? job.wrapUpTime : 0;
                decimal travelTime = job.travelTime != NULL ? job.travelTime : 0;
                decimal travelTime2 = job.travelTime2 != NULL ? job.travelTime2 : 0;
                decimal siteLogisticsBack = job.siteLogisticsBack != NULL ? job.siteLogisticsBack : 0; //HRP-11226
                decimal siteLogisticsTo = job.siteLogisticsTo != NULL ? job.siteLogisticsTo : 0; //HRP-11226
                
                decimal durationBeforeDrawHours = leadTime + setupTime + travelTime + siteLogisticsTo;
                if (driveShift.lunchBreak == TRUE && driveShift.lunchBreakBeforeDrawHours) {
                    durationBeforeDrawHours += driveShift.lunchBreakDuration;
                }
                decimal durationAfterDrawHours = breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack;
                
                job.start = driveShift.drawStart.addMinutes(integer.valueOf(-durationBeforeDrawHours));
                                
                job.finish = driveShift.drawEnd.addMinutes(integer.valueOf(durationAfterDrawHours));
                                
                job.duration = durationBeforeDrawHours + driveShift.drawDuration + durationAfterDrawHours;
                            
                minStart = minStart > job.start ? job.start : minStart;
                maxEnd = maxEnd < job.finish ? job.finish : maxEnd;
               
                job.start = skedDateTimeUtils.switchTimezone(job.start,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
            
                job.finish = skedDateTimeUtils.switchTimezone(job.finish,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);

                                   
            }
        }
        
        for (FetchRelatedDriveData.DMLJob job : driveShift.jobs)
        {
            if (string.isBlank(job.resourceRole) && job.assetType != Constants.JOB_TYPE_EQUIPMENT)
            {                    
                job.start =  skedDateTimeUtils.switchTimezone(minStart,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
                job.finish = skedDateTimeUtils.switchTimezone(maxEnd,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
                job.duration = skedDateTimeUtils.getDifferentMinutes(minStart, maxEnd);
            }
        }
        
        driveShift.start = skedDateTimeUtils.switchTimezone(minStart,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        driveShift.finish = skedDateTimeUtils.switchTimezone(maxEnd,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId); 

        if(shiftCount == noOfDriveShift - 1 && noOfDriveShift > 1)
        {
            equipmentJobFinishTime = driveShift.finish;
        }
        // for single shift
        else if (shiftCount == 0 && noOfDriveShift == 1)
        {
            equipmentJobStartTime = driveShift.start;
            equipmentJobFinishTime = driveShift.finish;
        }
        else if (shiftCount == 0 && noOfDriveShift > 1)
        {
            equipmentJobStartTime = driveShift.start;
        }          
    }

    static void updateEquipmentJobFinishTime (List<FetchRelatedDriveData.DMLJob> jobList)
    {
        for (FetchRelatedDriveData.DMLJob job : jobList)
        {
            if(job.assetType == Constants.JOB_TYPE_EQUIPMENT)
            {
                job.start = equipmentJobStartTime;
                job.finish = equipmentJobFinishTime;
                job.duration = skedDateTimeUtils.getDifferentMinutes(job.start, job.finish);
            }
            break;
        }
    }
    // HRP-11295 --> Ends Here
    
    /******** Point no 6b ***********/		
    static void populateDriveShiftTags(FetchRelatedDriveData.DMLDrive drive) {
        
        for (FetchRelatedDriveData.DMLDriveShift driveShift : drive.driveShifts) {
            Map<String,FetchRelatedDriveData.DMLDriveShiftTag> tagNameVsIDQuantitityMap = new Map<String,FetchRelatedDriveData.DMLDriveShiftTag>(); //HRP-11513
            Map<String,Id> tagNameRequired = new Map<String,Id>(); //HRP-11513
            List<FetchRelatedDriveData.DMLDriveShiftTag> driveShiftTags = new List<FetchRelatedDriveData.DMLDriveShiftTag>();
            if (drive.account.accountTags != NULL && !drive.account.accountTags.isEmpty()) {
                for (FetchRelatedDriveData.DMLAccountTag accountTag : drive.account.accountTags) {
                    if ((!tagNameRequired.containsKey(accountTag.tagName)) && accountTag.required == True) { //HRP-11513 start
                        tagNameRequired.put(accountTag.tagName,accountTag.tagId);
                    }
                    if ((accountTag.required == FALSE) && (!tagNameRequired.containsKey(accountTag.tagName))) {		
                        FetchRelatedDriveData.DMLDriveShiftTag driveShiftTag = new FetchRelatedDriveData.DMLDriveShiftTag();
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
                for (FetchRelatedDriveData.DMLLocationTag locationTag : drive.driveSite.locationTags) {
                    if ((!tagNameRequired.containsKey(locationTag.tagName)) && locationTag.required == True) { //HRP-11513 start
                        tagNameRequired.put(locationTag.tagName,locationTag.tagId);
                    }
                    if ((locationTag.required == FALSE) && (!tagNameRequired.containsKey(locationTag.tagName))) {
                        FetchRelatedDriveData.DMLDriveShiftTag driveShiftTag = new FetchRelatedDriveData.DMLDriveShiftTag();
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
                driveShift.driveShiftTags = tagNameVsIDQuantitityMap.values();  //HRP-11513 end
            }
        }
    }
    static void populateJobTags(FetchRelatedDriveData.DMLDrive drive)
    {
        Map<Id, FetchRelatedDriveData.DMLJobTag> mapSourceJobTag = new Map<Id, FetchRelatedDriveData.DMLJobTag>();
        Map<String,Id> uniqueTagName = new Map<String,Id>(); //HRP-12019
        if (drive.account != NULL && drive.account.accountTags != NULL) {
            for (FetchRelatedDriveData.DMLAccountTag accountTag : drive.account.accountTags) {
                if (accountTag.required == TRUE && (!uniqueTagName.containsKey(accountTag.tagName))) { //HRP-12019
                    FetchRelatedDriveData.DMLJobTag jobTag = new FetchRelatedDriveData.DMLJobTag();
                    jobTag.tagId = accountTag.tagId;
                    jobTag.tagType = accountTag.tagType; // HRP-10169
                    jobTag.resourceType = accountTag.resourceType;
                    mapSourceJobTag.put(jobTag.tagId, jobTag);
                    uniqueTagName.put(accountTag.tagName,accountTag.tagId); //HRP-12019
                }
            }
        }
        if (drive.driveSite != NULL && drive.driveSite.locationTags != NULL) {
            for (FetchRelatedDriveData.DMLLocationTag locationTag : drive.driveSite.locationTags) {
                if (locationTag.required == TRUE && (!uniqueTagName.containsKey(locationTag.tagName))) { //HRP-12019
                    //if (!(drive.typeOfDrive == 'Fixed Site' && locationTag.tagType == 'Physical Location Type')) { HRP-10456
                        FetchRelatedDriveData.DMLJobTag jobTag = new FetchRelatedDriveData.DMLJobTag();
                        jobTag.tagId = locationTag.tagId;
                        jobTag.tagType = locationTag.tagType; // HRP-10169
                        jobTag.resourceType = locationTag.resourceType;
                        mapSourceJobTag.put(jobTag.tagId, jobTag);
                        uniqueTagName.put(locationTag.tagName,locationTag.tagId); //HRP-12019
                    //}
                }
            }
        }
       
        if (!mapSourceJobTag.isEmpty()) {
            for (FetchRelatedDriveData.DMLDriveShift driveShift : drive.driveShifts) {
                for (FetchRelatedDriveData.DMLJob job : driveShift.jobs)
                {
                    Set<Id> tagIds = new Set<Id>();
                    List<FetchRelatedDriveData.DMLJobTag> jobTags = new List<FetchRelatedDriveData.DMLJobTag>();
                    for (FetchRelatedDriveData.DMLJobTag sourceJobTag : mapSourceJobTag.values())
                    {
                        boolean isValidTag = true;
                        if (!string.isBlank(sourceJobTag.resourceType)) { //job.volunteerRole = Constants.DONOR_AMBASSADOR

                            //HRP-11295 --> Restructured the valid tag formula

                            isValidTag = (!string.isBlank(job.ResourceRole) 
                                            && sourceJobTag.resourceType.contains(Constants.JOB_TAG_RESOURCETYPE_PERSON)
                                            && !(sourceJobTag.resourceType.contains(Constants.JOB_TYPE_VEHICLE))
                                            && !(sourceJobTag.resourceType.contains(Constants.JOB_TYPE_EQUIPMENT)))
                                        || (job.assetType == Constants.JOB_TYPE_VEHICLE && sourceJobTag.resourceType.contains(Constants.JOB_TYPE_VEHICLE))
                                        || (!string.isBlank(job.volunteerRole) && !string.isBlank(sourceJobTag.tagType) 
                                                    && sourceJobTag.tagType.contains(Constants.TAG_TYPE_CERTIFICATION) // HRP-10169
                                                    && !(sourceJobTag.resourceType.contains(Constants.JOB_TYPE_VEHICLE))
                                                    && !(sourceJobTag.resourceType.contains(Constants.JOB_TYPE_EQUIPMENT)))
                                            || (string.isBlank(job.resourcerole) && job.assetType == Constants.JOB_TYPE_EQUIPMENT && sourceJobTag.resourceType.contains(Constants.JOB_TYPE_EQUIPMENT));

                    }
                        if (isValidTag)
                        {
                            FetchRelatedDriveData.DMLJobTag jobTag = new FetchRelatedDriveData.DMLJobTag();
                            
                            if(!tagIds.contains(sourceJobTag.tagId))
                            {
                                tagIds.add(sourceJobTag.tagId);
                                jobTag.tagId = sourceJobTag.tagId;                                
                                jobTags.add(jobTag);
                            }
                    }
                    if (!jobTags.isEmpty())
                    {
                        job.jobTags = jobTags;
                        
                    }
                }
                }
            }
        }
    }

    /***************************************************************** Travel Time Calculation *************************************************************************/

    /* HRP - 11908 --> Starts Here
    @Description : Following methods will help in determining the following: 
                    1. is travel time needed?
                    2. If yes, for which resource roles?
            and get the travel time (if needed) from TTI
    */

    private static DriveGenerationUtil.TravelTimeSettingModel getTravelTimeSpecificInfo(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive) {
        DriveGenerationUtil.TravelTimeSettingModel travelTimeModel = new DriveGenerationUtil.TravelTimeSettingModel();
        Set<String> resourceRoles = new Set<String>();
        
        travelTimeModel.isNoTravelTimeChecked = drive.collectionOperation.noTravelTime;
        if(!travelTimeModel.travelTimeIncludedForFixedSite.equalsIgnorecase(drive.collectionOperation.travelTimeIncludedFixed)) {
            travelTimeModel.travelTimeIncludedForFixedSite = drive.collectionOperation.travelTimeIncludedFixed;
        }
        if(!travelTimeModel.isNoTravelTimeChecked) {
            if(!String.isBlank(travelTimeModel.travelTimeIncludedForFixedSite)) {
                travelTimeModel.resourceRoleGroupsNeededTravelTime = data.resourceRoleGroups;
                if(travelTimeModel.travelTimeIncludedForFixedSite.equalsIgnorecase(Constants.TRAVEL_TIME_INCLUDED_FIXED_SITE_DRIVERS_ONLY)) {
                    travelTimeModel.resourceRoleGroupsNeededTravelTime = new List<string>{'Driving roles'};
                }
            }
        }
        return travelTimeModel;
    }

    public static DriveGenerationUtil.TravelTimeSettingModel getTravelTimeFromTravelTimeIndex(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive, 
        FetchRelatedDriveData.DMLDriveShift driveShift,
        DriveGenerationUtil.TravelTimeSettingModel travelTimeModel,
        DriveGenerationUtil.TimeConfigurationModel config
    ) {
        Decimal travelTimeSiteToCO = 0;
        Decimal travelTimeCOToSite = 0;
        Time startTime = driveShift.startTime.addMinutes(- (Integer.valueOf(config.setupTime + config.siteLogisticsTo)));
        Time endTime = driveShift.endTime.addMinutes(Integer.valueOf(config.breakdownTime + config.siteLogisticsBack));
        if (drive.siteCollectionOperationId != '') {
            FetchRelatedDriveData.DMLTravelTimeBreakdown travelTimeBreakdown;
            Location coStagingLocation = drive.coStagingLocation.sked_Staging_Location__r.sked_GeoLocation__c;
            Location siteLocation = drive.driveSite.geoLocation;
            String driveDateWeekday = drive.driveDay;
            if (data.travelTimeIndexes != null) {
                for (FetchRelatedDriveData.TravelTimeIndex tti : data.travelTimeIndexes) {
                    if (tti.fromGeo.latitude == coStagingLocation.latitude
                            && tti.fromGeo.longitude == coStagingLocation.longitude  
                            && tti.toGeo.latitude == siteLocation.latitude
                            && tti.toGeo.longitude == siteLocation.longitude
                            && !tti.travelTimeBreakdown.isEmpty()) {     
                        for (FetchRelatedDriveData.DMLTravelTimeBreakdown item : tti.travelTimeBreakdown) {  
                            if (item.weekday == driveDateWeekday && item.startOfWindow <= startTime && startTime <= item.endOfWindow) {
                                travelTimeBreakdown = item;
                                break;
                            }
                        }
                        if (travelTimeBreakdown != NULL && travelTimeBreakdown.travelTime != NULL) {
                            travelTimeCOToSite = Math.ceil(travelTimeBreakdown.travelTime); 
                            drive.travelTimeCOtoSite =  tti.id; 
                        }
                    }
                    if (tti.toGeo.latitude == coStagingLocation.latitude 
                            && tti.toGeo.longitude == coStagingLocation.longitude 
                            && tti.fromGeo.latitude == siteLocation.latitude 
                            && tti.fromGeo.longitude == siteLocation.longitude 
                            && !tti.travelTimeBreakdown.isEmpty()) {
                        for (FetchRelatedDriveData.DMLTravelTimeBreakdown item : tti.travelTimeBreakdown) {
                            if (item.weekday == driveDateWeekday && item.startOfWindow <= endTime && endTime <= item.endOfWindow) {
                                travelTimeBreakdown = item;
                                break;
                            }
                        }
                        if (travelTimeBreakdown != NULL && travelTimeBreakdown.travelTime != NULL) {
                            travelTimeSiteToCO = Math.ceil(travelTimeBreakdown.travelTime); 
                            drive.travelTimeSitetoCO =  tti.id; 
                        }
                    }
                }
            }
        }
        travelTimeModel.travelTimeCOToSite = travelTimeCOToSite;
        travelTimeModel.travelTimeSiteToCO = travelTimeSiteToCO; 
        return travelTimeModel;
    }

    static void populateTravelTimeOnJobs(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive, 
        FetchRelatedDriveData.DMLDriveShift driveShift,
        DriveGenerationUtil.TravelTimeSettingModel travelTimeModel,
        Map<String, DriveGenerationUtil.TimeConfigurationModel> timeConfig
    ) {
            
        for (FetchRelatedDriveData.DMLJob job : driveShift.jobs) {
            if (!string.isBlank(job.resourceRole) && timeConfig.containsKey(getResourceRoleGroupUponResourceRole(data, job.resourceRole))) {
                String currentResourceRoleGroup = getResourceRoleGroupUponResourceRole(data, job.resourceRole);
                DriveGenerationUtil.TimeConfigurationModel config = timeConfig.get(currentResourceRoleGroup);
                travelTimeModel = getTravelTimeFromTravelTimeIndex(data, drive, driveShift, travelTimeModel, config);
                Boolean isTTmandatory = !travelTimeModel.isNoTravelTimeChecked || currentResourceRoleGroup.equalsIgnorecase('Driving roles');
                job.travelTime = isTTmandatory ? (travelTimeModel.resourceRoleGroupsNeededTravelTime.contains(getResourceRoleGroupUponResourceRole(data, job.resourceRole)) ? 
                                    travelTimeModel.travelTimeCOToSite + config.travelTime : 
                                    config.travelTime) : 0;
                job.travelTime2 = isTTmandatory ? (travelTimeModel.resourceRoleGroupsNeededTravelTime.contains(getResourceRoleGroupUponResourceRole(data, job.resourceRole)) ? 
                                    travelTimeModel.travelTimeSiteToCO + config.travelTime2 : 
                                    config.travelTime2) : 0;
            }
        }
    }

    // HRP - 11908 --> Ends Here
    
    /*********************************************************** Generate slot ***********************************************************/
    static void generateShiftSlots(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, FetchRelatedDriveData.DMLDriveShift driveShift, Decimal noOfDriveShift) {
        string timezoneSidId = driveShift.drive.timezoneSidId;
        
        List<FetchRelatedDriveData.DMLSlot> x2rbcSlots;
        List<FetchRelatedDriveData.DMLSlot> wbSlots;
        List<FetchRelatedDriveData.DMLSlot> plateletSlots;
        List<FetchRelatedDriveData.DMLSlot> plasmaSlots;

        // HRP - 9901 - siteOperationType is used to decide which type of slots will be generated
        
        boolean hasPlateletPlasma = drive.driveSite.siteOperationType == Constants.INTEGRATED_OPERATION_TYPE || 
            drive.driveSite.siteOperationType == Constants.NON_INTEGRATED_APH_OPERATION_TYPE;
        boolean has2rbcWb = drive.driveSite.siteOperationType == Constants.INTEGRATED_OPERATION_TYPE;
        
        if (hasPlateletPlasma) {
            plateletSlots = generatePlateletSlots(data, drive, driveShift);   
            driveShift.defaultPlateletSlots = plateletSlots != NULL ? plateletSlots.size() : 0;  

            plasmaSlots = generatePlasmaSlots(data, drive, driveShift);
            driveShift.defaultPlasmaSlots = plasmaSlots != NULL ? plasmaSlots.size() : 0; 
        }
        
        if (has2rbcWb) {
            x2rbcSlots = generate2rbcSlots(data, drive, driveShift);
            driveShift.default2rbcSlots = x2rbcSlots != NULL ? x2rbcSlots.size() : 0;

            wbSlots = generateWbSlots(data,drive,driveShift, noOfDriveShift);
            driveShift.defaultWbSlots = wbslots != NULL ? wbslots.size() : 0;  
        }
        
        driveShift.slots = new List<FetchRelatedDriveData.DMLSlot>();
        if (hasPlateletPlasma) {
            driveShift.slots.addAll(plateletSlots);
            driveShift.slots.addAll(plasmaSlots);
        }
        if (has2rbcWb) {
            driveShift.slots.addAll(x2rbcSlots);
            driveShift.slots.addAll(wbSlots);
        }
    }
    // ***********************************************************Generate Platelet Slots********************************************************************

    static List<FetchRelatedDriveData.DMLSlot> generatePlateletSlots(FetchRelatedDriveData.DMLData data, FetchRelatedDriveData.DMLDrive drive, FetchRelatedDriveData.DMLDriveShift driveShift)
    {
        
        List<FetchRelatedDriveData.DMLSlot> plateletSlots = new List<FetchRelatedDriveData.DMLSlot>();
        
        string fixedSiteAppointmentPattern = drive.driveSite.fixedSiteAppointmentPattern;
        decimal numberOfPlateletAssets = drive.numberOfPlateletAssets;
        
        slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
        configuration.interval = 60;
        configuration.rounds = new List<integer>();
        for (integer roundIndex = 0; roundIndex < drive.plateletRounds; roundIndex++)
        {
            integer minutesToStart = roundIndex * 180;
            configuration.rounds.add(minutesToStart);
        }

        if (fixedSiteAppointmentPattern == Constants.GROUPED_PATTERN){
            if (numberOfPlateletAssets <= 2) {
                configuration.numberOfGroups = 1;
            } 
            else {
                configuration.numberOfGroups = 2;
            }
            configuration.groupInterval = 30;
        } 
        else if(fixedSiteAppointmentPattern == Constants.EVEN_PATTERN)
        {
            configuration.numberOfGroups = 3;
            configuration.groupInterval = 15;
        }

        // HRP - 10456 (1st Change) --> Starts Here
        else{
            if (numberOfPlateletAssets < 4) {
                configuration.numberOfGroups = Integer.valueOf(numberOfPlateletAssets);
            }else{
                configuration.numberOfGroups = 4;
            }
            configuration.groupInterval = 15;
        }

        // HRP - 10456 (1st Change) --> Ends Here

        configuration.slotDuration = 180;
        configuration.slotType = Constants.PROCEDURE_TYPE_PLATELET;
        configuration.startTime = driveShift.drawStart;
        
        integer currentRoundIndex = 0;
        Integer groupQuantityAfterFirstIteration = 0; // HRP - 9965
        Integer groupQuantity = 0;
       

        while (currentRoundIndex < driveShift.plateletRounds)
        {  
                          
            DateTime tempStart = configuration.startTime.addMinutes(configuration.rounds.get(currentRoundIndex));
            
            // HRP - 10456 (2nd Change) --> Starts Here

            Integer groupNumberCount = 1; 

            Map<Integer,DateTime> nextGroupStartForEven4IntervalMap = new Map<Integer,DateTime>();
            nextGroupStartForEven4IntervalMap.put(1,tempStart.addMinutes(0));
            nextGroupStartForEven4IntervalMap.put(2,tempStart.addMinutes(30));
            nextGroupStartForEven4IntervalMap.put(3,tempStart.addMinutes(15));
            nextGroupStartForEven4IntervalMap.put(4,tempStart.addMinutes(45));

            // HRP - 10456 (2nd Change) --> Ends Here

            Decimal remainingNumberOfAssets = numberOfPlateletAssets;
            
            for (integer i = 0; i < configuration.numberOfGroups; i++)
            {
                //  HRP-9965 ---> (2nd Change) Start 

                Boolean isLargerRemainingAsset =  remainingNumberOfAssets >= configuration.numberOfGroups - i;

                if(i != 0)
                {
                    if(isLargerRemainingAsset && i != configuration.numberOfGroups - 1)
                    {
                        groupQuantityAfterFirstIteration = integer.valueOf(Math.ceil(remainingNumberOfAssets / (configuration.numberOfGroups - i)));
                    }
                    else {
                        groupQuantityAfterFirstIteration = Integer.valueOf(remainingNumberOfAssets);
                    }           
                }
                groupQuantity = i==0 ? integer.valueOf(Math.ceil(numberOfPlateletAssets / configuration.numberOfGroups)) : groupQuantityAfterFirstIteration ;
                
                
                while(groupQuantity > remainingNumberOfAssets)
                {
                    groupQuantity = groupQuantity - 1;
                }
                // HRP-9965 ---> (2nd Change) End
                
                // HRP - 10456 (3rd Change) --> Starts Here

                if(fixedSiteAppointmentPattern != Constants.EVEN_4_PATTERN)
                {
                    tempStart = i == 0 ? tempStart : tempStart.addMinutes(configuration.groupInterval);
                }else {
                    tempStart = nextGroupStartForEven4IntervalMap.get(groupNumberCount); 
                }
                
                // HRP - 10456 (3rd Change) --> Ends Here

                for(integer j = 0 ; j < groupQuantity; j++)
                {
                    FetchRelatedDriveData.DMLSlot slot = new FetchRelatedDriveData.DMLSlot();
                    slot.name = configuration.slotType;
                    slot.label = '';
                    slot.startTime = tempStart;
                    slot.endTime = tempStart.addMinutes(configuration.slotDuration);
                    Slot.startTime = skedDateTimeUtils.switchTimezone(slot.startTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
                    slot.endTime = skedDateTimeUtils.switchTimezone(slot.endTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);                   
                    slot.locked = false;
                    slot.slotType = configuration.slotType;
                    slot.status = 'Open';                   
                    plateletSlots.add(slot);
                    
                }
                groupNumberCount++; // HRP - 10456

                remainingNumberOfAssets = remainingNumberOfAssets - groupQuantity;


                // HRP - 10456 (4th Change) --> Starts Here
                if(groupNumberCount == configuration.numberOfGroups+1)
                {
                    break;
                }
                // HRP - 10456 (4th Change) --> Ends Here

            }
            currentRoundIndex++;
            
        } 
        return plateletSlots;
    }
    
    static List<FetchRelatedDriveData.DMLSlot> generatePlasmaSlots(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive, 
        FetchRelatedDriveData.DMLDriveShift driveShift
    )
    {
        Set<DateTime> excludedSlotss = new set<DateTime>();
        DateTime plasmaSlotExcludeTimes = driveShift.drawStart;
        excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId));
        
        while( plasmaSlotExcludeTimes < driveShift.drawEnd){
            plasmaSlotExcludeTimes = plasmaSlotExcludeTimes.addMinutes(180);
            excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId));
        }

        /* HRP-10915 --> Starts Here
        if (startMinutes >= 30) { // HRP-12218
            driveShiftStart = DateTime.newInstance(driveShiftStart.getTime() - (startMinutes - 30) * 60000);
        } else if(startMinutes > 0) {
            driveShiftStart = DateTime.newInstance(driveShiftStart.getTime() - startMinutes * 60000);
        }
        // HRP-10915 --> Ends Here*/

        //HRP-13198 --> Starts Here
        DateTime firstPlasmaSlotStart;
        DateTime firstPlateletRoundEnd = driveShift.drawStart.addMinutes(60); // end after an hour
        Long startMinutes = firstPlateletRoundEnd.minute();
        if(startMinutes > 40) {
            firstPlasmaSlotStart = DateTime.newInstance(firstPlateletRoundEnd.getTime() - (startMinutes - 40) * 60000).addMinutes(30);
        } else if(startMinutes > 10) {
            firstPlasmaSlotStart = DateTime.newInstance(firstPlateletRoundEnd.getTime() - (startMinutes - 10) * 60000).addMinutes(30);
        } else if(startMinutes >= 0) {
            firstPlasmaSlotStart = DateTime.newInstance(firstPlateletRoundEnd.getTime() - startMinutes * 60000).addMinutes(10);
        }
        //HRP-13198 --> Ends Here
        
        slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
        configuration.endTime = driveShift.drawEnd;
        configuration.excludedSlots = excludedSlotss;
        configuration.roundInterval = 90;
        configuration.numberOfGroups = 2;
        configuration.groupInterval = 30;
        configuration.slotType = Constants.PROCEDURE_TYPE_PLASMA;
        configuration.slotDuration = 90;
        configuration.startTime = firstPlasmaSlotStart; //HRP-13198
        
        configuration.startTime = skedDateTimeUtils.switchTimezone(configuration.startTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        configuration.endTime = skedDateTimeUtils.switchTimezone(configuration.endTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        return generatePlasmaSlotsByNumberOfAssets(configuration, drive);
        
    }
    
    static List<FetchRelatedDriveData.DMLSlot> generatePlasmaSlotsByNumberOfAssets(slotGeneratorConfigModel configuration, FetchRelatedDriveData.DMLDrive drive) {
        List<FetchRelatedDriveData.DMLSlot> allSlots = new List<FetchRelatedDriveData.DMLSlot>();
        List<FetchRelatedDriveData.DMLSlot> slots = new List<FetchRelatedDriveData.DMLSlot>();
        
        Datetime tempStart = configuration.startTime;
        while (tempStart < configuration.endTime) {
            decimal remainingNumberOfAssets = drive.numberOfPlasmaAssets;
            for (integer i = 0; i < configuration.numberOfGroups; i++) {
                Integer groupQuantity = integer.valueOf(Math.Ceil(drive.numberOfPlasmaAssets / configuration.numberOfGroups));
                if (groupQuantity > remainingNumberOfAssets) {
                    groupQuantity = groupQuantity - 1;
                }                
                DateTime slotStart = tempStart.addMinutes(i * configuration.groupInterval);              
                DateTime slotEnd = slotStart.addMinutes(configuration.slotDuration);
                if (slotStart <= configuration.endTime.addMinutes(-50) ) {
                    Boolean isSlotTimeRemoval = isPlasmaSlotTimeRemoval(configuration, slotStart);
                    if(!isSlotTimeRemoval){
                        for (integer groupIndex = 0; groupIndex < groupQuantity; groupIndex++) {
                            FetchRelatedDriveData.DMLSlot slot = new FetchRelatedDriveData.DMLSlot();
                            slot.name = configuration.slotType;
                            slot.label = '';
                            slot.startTime = slotStart;
                            slot.endTime = slotEnd;
                            slot.locked = false;
                            slot.slotType = configuration.slotType;
                            slot.status = 'Open';
                            allSlots.add(slot);
                        }
                    }
                }
                remainingNumberOfAssets = remainingNumberOfAssets - groupQuantity;
            }
            tempStart = tempStart.addMinutes(configuration.roundInterval); //next round	after 90 mins
        }        
        return allSlots;
    }
    
    static Boolean isPlasmaSlotTimeRemoval(slotGeneratorConfigModel configuration, DateTime slotStartTime){
        Boolean fallsUnderPlateletStartTime;
        for(DateTime dt : configuration.excludedSlots){
            DateTime excludeTimeStart = dt;
            DateTime excludeTimeEnd = dt.addMinutes(60);                
            if( slotStartTime >= excludeTimeStart && slotStartTime <= excludeTimeEnd){
                fallsUnderPlateletStartTime = true;
                break;
            }else{
                fallsUnderPlateletStartTime = false;
            }
        }            
        return fallsUnderPlateletStartTime;
    }

    // **********************************************************************Generate Whole Blood Appointments***************************************************************
    
    static List<FetchRelatedDriveData.DMLSlot> generateWbSlots(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive, 
        FetchRelatedDriveData.DMLDriveShift driveShift,
        Decimal noOfDriveShift
    ) {  
        Decimal estimatedWbslots;
        List<FetchRelatedDriveData.DMLSlot> wholeBloodSlots = new List<FetchRelatedDriveData.DMLSlot>();
        // HRP-12144 --> Starts Here (Added new configuration for FS drives where slot multiplier remains 140%)
        
        slwcSetting.adminSetting skedAdminSetting = new slwcSetting.adminSetting();
        Decimal paddingPercentage = drive.slotGenerator != NULL ? drive.slotGenerator / 100 : skedAdminSetting.callListRecipientNoneFixedSite / 100; //HRP-12011
        Map<String, Decimal> fsppTypeAndValuesMap = getFSPPTypeAndDeferalQnsValue(drive);

        // HRP-12480 --> Starts Here (Check if FSPP exist with Deferral and QNS value)
        Boolean isValidFSPPExist = fsppTypeAndValuesMap != NULL 
                                && fsppTypeAndValuesMap.containsKey('QNS_'+Constants.PROCEDURE_TYPE_WB+'Staff')
                                && fsppTypeAndValuesMap.containsKey('Deferral_'+Constants.PROCEDURE_TYPE_WB+'Staff');
    
        estimatedWbslots = isValidFSPPExist ? Math.ceil(Math.ceil((drive.wbProjectedProcedures / (1 - fsppTypeAndValuesMap.get('QNS_'+Constants.PROCEDURE_TYPE_WB+'Staff')) / (1 - fsppTypeAndValuesMap.get('Deferral_'+Constants.PROCEDURE_TYPE_WB+'Staff')))) * paddingPercentage) : 0;
        system.debug('estimatedWbslots '+estimatedWbslots);
        
        // HRP-12144 --> Ends Here
        
        integer totalSlots = estimatedWbslots > 0 ? integer.valueOf(estimatedWbslots) : 0;

        // HRP-12480 --> Ends Here
        
        // new - 10456
        if(totalSlots > 0) { // HRP-1280
            Set<DateTime> excludedSlotss = new set<DateTime>();      
            DateTime plateletSlotExcludeTimes = driveShift.drawStart;
            excludedSlotss.add(skedDateTimeUtils.switchTimezone(plateletSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId));
            
            while(plateletSlotExcludeTimes < driveShift.drawEnd ) {    
                plateletSlotExcludeTimes = plateletSlotExcludeTimes.addMinutes(180);
                if(plateletSlotExcludeTimes == driveShift.drawEnd) {
                    break;
                }     
                excludedSlotss.add(skedDateTimeUtils.switchTimezone(plateletSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId));   
            }
            integer wbSlotDuration = 15;
            slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
            configuration.excludedSlots = excludedSlotss;
            configuration.interval = 60;
            configuration.lastSlotStart = driveShift.drawEnd;
            configuration.rounds = new List<integer>();
            configuration.rounds.add(0);
            configuration.rounds.add(15);
            configuration.rounds.add(30);
            configuration.rounds.add(45);
            configuration.slotDuration = wbSlotDuration;
            configuration.slotType = Constants.APPOINTMENT_TYPE_WB;
            configuration.startTime = driveShift.drawStart;
            configuration.totalSlots = totalSlots;
            FetchRelatedDriveData.DMLCollectionOperation coRec = data.mapCollectionOperation.get(drive.collectionOperationId);
            Boolean skipLastAppointment = !string.isBlank(coRec.skipLastAppointmentFor) && coRec.skipLastAppointmentFor.contains(drive.typeOfDrive);
            if (skipLastAppointment) {
                configuration.lastSlotStart = configuration.lastSlotStart.addMinutes(-wbSlotDuration);
            }
            wholeBloodSlots = generateWbSlots(configuration, drive, driveShift, noOfDriveShift,skipLastAppointment);
            
            // Lunch break slot reduction
            if(driveShift.lunchBreak) {            
                applyLunchBreakSlotReductionForWbSlots(wholeBloodSlots, drive, data, driveShift);
            }
        }
        return wholeBloodSlots;
    }
    
    static List<FetchRelatedDriveData.DMLSlot> generateWbSlots(
        slotGeneratorConfigModel configuration,
        FetchRelatedDriveData.DMLDrive drive, 
        FetchRelatedDriveData.DMLDriveShift driveShift, 
        Decimal noOfDriveShift,
        Boolean skipLastAppointment
    ) {
        List<FetchRelatedDriveData.DMLSlot> slots = new List<FetchRelatedDriveData.DMLSlot>();
        integer roundCount = 1;
        integer slotCount = 0;
        integer numberOfRounds = configuration.rounds.size();
        
        while (slotCount < configuration.totalSlots)
        {
            integer roundIndex = integer.valueOf(Math.mod(roundCount, numberOfRounds));
            roundIndex = (roundIndex == 0 ? configuration.rounds.size() : roundIndex) - 1;
            DateTime firstSlotStart = configuration.startTime.addMinutes(configuration.rounds.get(roundIndex));
            DateTime tempDt = firstSlotStart;
            while (tempDt <= configuration.lastSlotStart)
            { 
                DateTime tempDtTimeZone = skedDateTimeUtils.switchTimezone(tempDt,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);

                Boolean isSlotTimeRemoval = isWbSlotTimeRemoval(configuration, tempDtTimeZone);
                if(!isSlotTimeRemoval)
                {
                    FetchRelatedDriveData.DMLSlot slot = new FetchRelatedDriveData.DMLSlot();
                    slot.name = configuration.slotType;
                    slot.label = '';
                    slot.startTime = tempDt;
                    slot.endTime = tempDt.addMinutes(configuration.slotDuration);
                    slot.locked = false;
                    slot.slotType = configuration.slotType;
                    slot.status = 'Open';                 
                    slot.startTime = skedDateTimeUtils.switchTimezone(slot.startTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
                    slot.endTime = skedDateTimeUtils.switchTimezone(slot.endTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
                    
                    slots.add(slot);
                    slotCount++;
                    if (slotCount == configuration.totalSlots) {
                        break;
                    }
                }
                tempDt = tempDt.addMinutes(configuration.interval);
                if(tempDt > configuration.lastSlotStart || (tempDt == configuration.lastSlotStart && configuration.lastSlotStart != drive.drawEnd && skipLastAppointment==false))
                {
                    break;
                }
            }
            roundCount++;
        }
        return slots;
    }
    
    static Boolean isWbSlotTimeRemoval(slotGeneratorConfigModel configuration, DateTime slotStartTime){
        Boolean fallsUnderPlateletStartTime;
        for(DateTime dt : configuration.excludedSlots){
            DateTime excludeTimeStart = dt;
            DateTime excludeTimeEnd = dt.addMinutes(60);                
            if( slotStartTime >= excludeTimeStart && slotStartTime < excludeTimeEnd){
                fallsUnderPlateletStartTime = true;
                break;
            }else{
                fallsUnderPlateletStartTime = false;
            }
        }            
        return fallsUnderPlateletStartTime;
    }
    
    static void applyLunchBreakSlotReductionForWbSlots(
        List<FetchRelatedDriveData.DMLSlot> wbSlots,
        FetchRelatedDriveData.DMLDrive drive,
        FetchRelatedDriveData.DMLData data,
        FetchRelatedDriveData.DMLDriveShift driveShift
    )
    {
        
        Decimal totalSlots = 0;
        slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
        configuration.rounds = new List<integer>();
        configuration.rounds.add(0);
        configuration.rounds.add(30);
        configuration.rounds.add(15);
        configuration.rounds.add(45);
        configuration.interval = 60;
        
        DateTime lunchBreakEndTime = DateTime.newInstanceGMT(driveShift.driveDate, driveShift.lunchBreakEndTime);
        lunchBreakEndTime = skedDateTimeUtils.switchTimezone(lunchBreakEndTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        
                    
        DateTime lunchBreakStartTime = DateTime.newInstanceGMT(driveShift.driveDate, driveShift.lunchBreakStartTime);
        lunchBreakStartTime = skedDateTimeUtils.switchTimezone(lunchBreakStartTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        
        for (FetchRelatedDriveData.DMLSlot slot : wbSlots)
        {	
            if (lunchBreakStartTime <= slot.startTime && slot.endTime <= lunchBreakEndTime) 
            {
                totalSlots++;	
            }	
        }
            system.debug('Total slots to be within range '+totalSlots);	
            Decimal numberOfWbReduced = Math.ceil((totalSlots * driveShift.signUpReduction)/100);
            system.debug('numberOfReducedSlots '+numberOfWbReduced);	

                Decimal reduceSlotCount = 0;
                integer roundCount = 1;
                integer numberOfRounds = configuration.rounds.size();
                while (reduceSlotCount < numberOfWbReduced)
                {
                    integer roundIndex = integer.valueOf(Math.mod(roundCount, numberOfRounds));
                    roundIndex = (roundIndex == 0 ? configuration.rounds.size() : roundIndex) - 1;
                    DateTime firstSlotStart = lunchBreakStartTime.addMinutes(configuration.rounds.get(roundIndex));
                    DateTime tempDt = firstSlotStart;
                    while (tempDt < lunchBreakEndTime)
                    {
                        Integer index = -1;
                        for (integer i = 0; i < wbSlots.size(); i++)
                        {
                            FetchRelatedDriveData.DMLSlot slot = wbSlots.get(i);	
                            if (slot.startTime == tempDt)
                            {	
                                index = i;	
                                break;	
                            }   
                        }
                        if (index > -1)
                        {	
                            wbSlots.remove(index);
                            reduceSlotCount++;
                        }	
                        if (reduceSlotCount == numberOfWbReduced)
                        {	
                            break;	
                        }
                        tempDt = tempDt.addMinutes(configuration.interval);
                    }
                    roundCount++;
                }
    }

    static List<FetchRelatedDriveData.DMLSlot> generate2rbcSlots(
        FetchRelatedDriveData.DMLData data, 
        FetchRelatedDriveData.DMLDrive drive, 
        FetchRelatedDriveData.DMLDriveShift driveShift
    ) {
        
        Set<DateTime> excludedSlotss = new set<DateTime>();
        DateTime plasmaSlotExcludeTimes = driveShift.drawStart;
        excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId));
        
        while( plasmaSlotExcludeTimes < driveShift.drawEnd){
            plasmaSlotExcludeTimes = plasmaSlotExcludeTimes.addMinutes(180);
            excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId));
        }
        
        slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
        configuration.endTime = driveShift.drawEnd;
        configuration.excludedSlots = excludedSlotss;
        configuration.roundInterval = 60;
        configuration.numberOfGroups = 2;
        configuration.groupInterval = 30;
        configuration.slotType = Constants.PROCEDURE_TYPE_2RBC;
        configuration.slotDuration = 60;
        configuration.startTime = driveShift.drawStart.addMinutes(60);
        
        configuration.startTime = skedDateTimeUtils.switchTimezone(configuration.startTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        configuration.endTime = skedDateTimeUtils.switchTimezone(configuration.endTime,TimeZone.getTimeZone('GMT').getId(),drive.driveSite.timezoneSidId);
        
        return generateSlotsByNumberOfAssets(configuration, drive);
    }
    
    static List<FetchRelatedDriveData.DMLSlot> generateSlotsByNumberOfAssets(slotGeneratorConfigModel configuration,FetchRelatedDriveData.DMLDrive drive) {
        List<FetchRelatedDriveData.DMLSlot> slots = new List<FetchRelatedDriveData.DMLSlot>();
        
        Datetime tempStart = configuration.startTime;
        while (tempStart < configuration.endTime) {
            decimal remainingNumberOfAssets = drive.numberOf2rbcAssets;
            for (integer i = 0; i < configuration.numberOfGroups; i++) {
                decimal groupQuantity = Math.ceil(drive.numberOf2rbcAssets / configuration.numberOfGroups);
                if (groupQuantity > remainingNumberOfAssets) {
                    groupQuantity = groupQuantity - 1;
                }
                
                DateTime slotStart = tempStart.addMinutes(i * configuration.groupInterval);
                DateTime slotEnd = slotStart.addMinutes(configuration.slotDuration);
                Boolean isSlotTimeRemoval = isRbcSlotTimeRemoval(configuration, slotStart);
                if(!isSlotTimeRemoval){
                    
                    if (slotStart <= configuration.endTime.addMinutes(-30)) {
                        for (integer groupIndex = 0; groupIndex < groupQuantity; groupIndex++) {
                            FetchRelatedDriveData.DMLSlot slot = new FetchRelatedDriveData.DMLSlot();
                            slot.name = configuration.slotType;
                            slot.label = '';
                            slot.startTime = slotStart;
                            slot.endTime = slotEnd;
                            slot.locked = false;
                            slot.slotType = configuration.slotType;
                            slot.status = 'Open';
                            slots.add(slot);
                        }
                    }
                }
                
                remainingNumberOfAssets = remainingNumberOfAssets - groupQuantity;
            }
            
            tempStart = tempStart.addMinutes(configuration.roundInterval); //next round
        }
        return slots;
    }        
    
    static Boolean isRbcSlotTimeRemoval(slotGeneratorConfigModel configuration, DateTime slotStartTime){
        Boolean fallsUnderPlateletStartTime;
        for(DateTime dt : configuration.excludedSlots){
            DateTime excludeTimeStart = dt;
            DateTime excludeTimeEnd = dt.addMinutes(60);                
            if( slotStartTime >= excludeTimeStart && slotStartTime < excludeTimeEnd){
                fallsUnderPlateletStartTime = true;
                break;
            }else{
                fallsUnderPlateletStartTime = false;
            }
        }            
        return fallsUnderPlateletStartTime;
    }

    // HRP - 10456 --> Starts Here
    /**** Point no 12 - Planned Drive Productivity Calculation ****/

    static void calculateDriveProductivityPlanned(FetchRelatedDriveData.DMLDrive drive)
    {
        Decimal durationPerStaff = 0;
        Decimal lunchBreakDuration = 0;
        Decimal totalDurationForStaffJobs = 0;

        if(drive.driveShifts!= NULL)
        {
            for(FetchRelatedDriveData.DMLDriveShift driveShift : drive.driveShifts)
            {
                decimal driveShiftDuration = skedDateTimeUtils.getDifferentMinutes(driveShift.drawStart, driveShift.drawEnd);
                if(driveShift.lunchBreak == TRUE && driveShift.lunchBreakBeforeDrawHours == FALSE)
                {
                    lunchBreakDuration = drive.collectionOperation.lunchBreakDurationFixedSite;
                }
                else{
                    lunchBreakDuration = 0;
                }
                for(FetchRelatedDriveData.DMLJob driveShiftJob : driveShift.jobs)
                {
                    if (!string.isBlank(driveShiftJob.resourceRole)) // Apheresis, Apheresis Charge
                    {
                        Decimal travelTime1 = driveShiftJob.travelTime != NULL ? driveShiftJob.travelTime : 0;
                        Decimal leadTime = driveShiftJob.leadTime != NULL ? driveShiftJob.leadTime : 0;
                        Decimal setupTime = driveShiftJob.setupTime != NULL ? driveShiftJob.setupTime : 0;
                        Decimal breakdownTime = driveShiftJob.breakdownTime != NULL ? driveShiftJob.breakdownTime  : 0;
                        Decimal wrapUpTime = driveShiftJob.wrapUpTime != NULL ? driveShiftJob.wrapUpTime : 0;
                        Decimal travelTime2 = driveShiftJob.travelTime2 != NULL ? driveShiftJob.travelTime2 : 0;
                        decimal siteLogisticsBack = driveShiftJob.siteLogisticsBack != NULL ? driveShiftJob.siteLogisticsBack : 0; //HRP-11226
                        decimal siteLogisticsTo = driveShiftJob.siteLogisticsTo != NULL ? driveShiftJob.siteLogisticsTo : 0; //HRP-11226
                        
                        durationPerStaff = (driveShiftDuration + travelTime1 + leadTime + setupTime + breakdownTime + wrapUpTime + travelTime2 + siteLogisticsBack + siteLogisticsTo) - lunchBreakDuration; //HRP-11226
                        
                        totalDurationForStaffJobs += driveShiftJob.quantity * durationPerStaff;
                       
                    }
                    
                }
            }
        }
        
        drive.driveProductivityPlanned = totalDurationForStaffJobs > 0 ? (drive.totalProductsProjected / (totalDurationForStaffJobs / 60)).setScale(2, RoundingMode.HALF_DOWN) : 0;
        
    }
    
    // HRP - 10456 --> Ends Here

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
    }
    
    static void updateDriveTotalSlots(FetchRelatedDriveData.DMLDrive drive) {
        decimal totalSlots = 0;
        for (FetchRelatedDriveData.DMLDriveShift driveShift : drive.driveShifts) {
            if (driveShift.slots != NULL) {
                totalSlots += driveShift.slots.size();
            }
        }
        drive.totalSlots = totalSlots;
    }
     public class driveStaffingComplementModel {
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
            
            //Fixed Site
            public decimal numberOf2rbcAssets;
            public decimal numberOfPlasmaAssets;
            public decimal numberOfPlateletAssets;
            public Map<string, procedureTypeStaffingModel> mapProcedureStaffing;
            public decimal numberOfWholeBloodResources;
            public decimal numberOf2rbcResources;
            public decimal numberOfApheresisCharge;
        }
        
        public class procedureTypeStaffingModel {
            public string resourceRole;
            public string procedureType;
            public decimal noOfStaff;
            public decimal donorsPerHoursCapacity;
        }
}