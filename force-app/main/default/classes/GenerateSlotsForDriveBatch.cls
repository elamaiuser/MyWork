global class GenerateSlotsForDriveBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    /*
    String cronExp = '0 0 1 * * ?';
    GenerateSlotsForDriveBatch schedulerJob = new GenerateSlotsForDriveBatch();
    System.schedule('GenerateSlotsForDriveBatch', cronExp, schedulerJob);

    1) To run batch for specific date:
    Date fromDate= Date.newInstance(2024,01,01);
    Date toDate= Date.newInstance(2024,09,23);
    
    GenerateSlotsForDriveBatch batchObject = new GenerateSlotsForDriveBatch(fromDate, toDate);
    Database.executeBatch(batchObject,200);
    
    2) To run batch for specific drive/drives:
    GenerateSlotsForDriveBatch batch = new GenerateSlotsForDriveBatch(new Set<Id>{'Id1','Id2',... so on more id if have any});
    Database.executeBatch(batch,200);
    
    3) To run for all the drive:
    GenerateSlotsForDriveBatch batch = new GenerateSlotsForDriveBatch();
    Database.executeBatch(batch,200);
    */
    String query;
    Set<Id> driveIdSet = new Set<Id>();
    Date toDate; 
    Date fromDate;
    Integer maxErrorMessageSize = 32000;
    
    public GenerateSlotsForDriveBatch(){
        this.query = 'SELECT Id, sked_Type_of_Drive__c, sked_Drive_Date__c, sked_account__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= Today AND sked_Status__c != \'Cancel\'';
    }

    public GenerateSlotsForDriveBatch(Set<Id> driveIdSet){
        this.driveIdSet = driveIdSet;
        this.query = 'SELECT Id, sked_Type_of_Drive__c, sked_Drive_Date__c, sked_account__c FROM sked_Drive__c WHERE Id In : driveIdSet';
    }

    public GenerateSlotsForDriveBatch(Date fromDate, Date toDate){
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.query = 'SELECT Id, sked_Type_of_Drive__c, sked_Drive_Date__c, sked_account__c FROM sked_Drive__c WHERE sked_Drive_Date__c >=: fromDate AND sked_Drive_Date__c <=: toDate AND sked_Status__c != \'Cancel\'';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(SchedulableContext cc) {
        Database.executeBatch(new GenerateSlotsForDriveBatch(),1);
    }

    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        try {
            Set<Id> driveIds = new Set<Id>();
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> driveIdsWhichDonotHaveSlots = new Set<Id>();
            Set<Id> collectionOperationId = new Set<Id>();
            Map<Id, List<sked_Fixed_Site_Procedure_Projection__c>> AccIdVsFSPPMap = new Map<Id, List<sked_Fixed_Site_Procedure_Projection__c>>();
            List<FetchRelatedDriveData.DMLSlot> slotsNeedToUpdateFixedSite = new List<FetchRelatedDriveData.DMLSlot>();
            List<MobileDriveGeneratorDMLService.DMLSlot> slotsNeedToUpdateMobile = new List<MobileDriveGeneratorDMLService.DMLSlot>();
        	for(sked_Drive__c drive : driveList){
                driveIds.add(drive.id);
                
            }
            
            List<sked_Drive__c> driveListWhichDonotHaveSlots = [SELECT Id, sked_account__c, sked_Type_of_Drive__c, sked_Drive_Date__c, sked_Number_of_Platelet_Assets__c, sked_Platelet_Rounds__c, sked_Number_of_Plasma_Assets__c, sked_Number_of_2RBC_Assets__c, sked_WB_Projected_Procedures__c, sked_Drive_Shift_Count__c, sked_2RBC_Projected_Procedures__c, sked_Maximum_Lunch_Break_Duration__c, sked_Start_Time__c, sked_End_Time__c, sked_Collection_Operation__c, sked_Opportunity__r.Slot_Generator__c, sked_Opportunity__r.Call_List_Recipient_Exist__c, sked_Opportunity__r.Drive_Date__c, sked_Opportunity__r.Start_Time__c , sked_Opportunity__r.End_Time__c , sked_Drive_Site__r.Operation_Type__c, sked_Drive_Site__r.sked_Fixed_Site_Appointment_Pattern__c, sked_Drive_Site__r.sked_Timezone__c, sked_Collection_Operation__r.sked_Skip_Last_Appointment__c, sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c FROM sked_Drive__c WHERE Id NOT IN (SELECT sked_Drive__c FROM sked__Slot__c where sked_Drive__c IN: driveIds) AND Id IN: driveIds];
            
            for(sked_Drive__c drive : driveListWhichDonotHaveSlots){
                driveIdsWhichDonotHaveSlots.add(drive.id);
                if(drive.sked_Type_of_Drive__c == 'Fixed Site'){
                    accountIdSet.add(drive.sked_Account__c); 
                }
                collectionOperationId.add(drive.sked_Collection_Operation__c); 
            }
            
            if(driveIdsWhichDonotHaveSlots.size() > 0){
                BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                debugLog.ApexClass__c = 'GenerateSlotsForDriveBatch';
                debugLog.Method__c = 'GenerateSlotsForDriveBatch';
                debugLog.Error_Description__c = string.valueOf(driveIdsWhichDonotHaveSlots.size()); //
                String driveIdOnWhichSlotAreNotThere = String.valueOf(driveIdsWhichDonotHaveSlots);
                if(driveIdOnWhichSlotAreNotThere.length() > maxErrorMessageSize ){
                    driveIdOnWhichSlotAreNotThere = driveIdOnWhichSlotAreNotThere.substring(0, maxErrorMessageSize);
                }
                debugLog.Error_Description_Long__c = driveIdOnWhichSlotAreNotThere;
                insert debugLog;
            }
            
            List<sked_Collection_Operation_SDM__c> collectionOperationSDMs = [SELECT Id, sked_Collection_Operation__c, sked_Staffing_Decision_Matrix__c,
            sked_Effective_End_Date__c, sked_Effective_Start_Date__c
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c IN :collectionOperationId
            AND sked_Staffing_Decision_Matrix__c != NULL];

            Set<Id> staffingDecisionMatrixIds = new Set<Id>();
            for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
                staffingDecisionMatrixIds.add(collectionOperationSdm.sked_Staffing_Decision_Matrix__c);
            }

            Map<Id,sked_Staffing_Decision_Matrix__c> staffingDecisionMatrices = new Map<Id,sked_Staffing_Decision_Matrix__c>([SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
            sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, 
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
            sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c, sked_2RBC_Hourly_Capacity__c,
            sked_WB_Hourly_Capacity__c, sked_Platelet_Hourly_Capacity__c, sked_Plasma_Hourly_Capacity__c,
            RecordType.Name
            FROM sked_Staffing_Decision_Matrix__c
            WHERE Id IN :staffingDecisionMatrixIds]);



            List<Account> allAccountRelatedToDrive = [SELECT Id, Name, Accepts_Automation2__c, APT_Required__c,
                                                        (SELECT Id, sked_Account__c, sked_Deferral__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c,
                                                        sked_Procedure_Type__c, sked_Productive_Procedure_Goal__c, sked_QNS__c
                                                        FROM sked_Fixed_Site_Procedure_Projections__r)
                                                        FROM Account
                                                        WHERE Id IN :accountIdSet];
            for(Account acc : allAccountRelatedToDrive){
                if(!AccIdVsFSPPMap.containsKey(acc.Id)){
                    if(acc.sked_Fixed_Site_Procedure_Projections__r != NULL && !acc.sked_Fixed_Site_Procedure_Projections__r.isEmpty()){
                        AccIdVsFSPPMap.put(acc.Id,new List<sked_Fixed_Site_Procedure_Projection__c>());
                    }
                    AccIdVsFSPPMap.put(acc.Id,acc.sked_Fixed_Site_Procedure_Projections__r);
                }
            }
            List<sked_Drive_Shift__c> driveShifts = [Select Id, Name, sked_Drive__c, sked_Platelet_Rounds__c, sked_Drive_Date__c, sked_Lunch_Break_End_Time__c, sked_Lunch_Break_Start_Time__c, sked_Sign_Up_Reduction__c, sked_Lunch_Break__c, sked_Timezone__c, sked_Start_Time__c, sked_End_Time__c, sked_Lunch_Break_Before_Draw_Hours__c, sked_2RBC_Projected_Procedures__c, sked_Staff_Setup__c, sked_Max_Donor_Capacity__c, sked_Drive__r.sked_Drive_Site__r.sked_Timezone__c, (SELECT Id, sked_Resource_Role__c, sked__Quantity__c, sked_VPHH_Quantity__c from sked_Jobs__r) from sked_Drive_Shift__c where sked_Drive__c IN: driveIdsWhichDonotHaveSlots];
            Map<Id,List<sked_Drive_Shift__c>> mapOfDriveIdVsDriveShift = new Map<Id,List<sked_Drive_Shift__c>>();
            for(sked_Drive_Shift__c driveShift : driveShifts){
                if(!mapOfDriveIdVsDriveShift.containsKey(driveShift.sked_Drive__c)){
                    mapOfDriveIdVsDriveShift.put(driveShift.sked_Drive__c, new List<sked_Drive_Shift__c>());
                }
                mapOfDriveIdVsDriveShift.get(driveShift.sked_Drive__c).add(driveShift);
            }
            for(sked_drive__c drive : driveListWhichDonotHaveSlots){
                
                //List<sked__Slot__c> slotsPerDriveShift = new List<sked__Slot__c>();
                if(( drive.sked_Drive_Site__r.Operation_Type__c == 'Non Integrated WB' && drive.sked_Type_of_Drive__c == 'Fixed Site' ) || (drive.sked_Type_of_Drive__c == 'Mobile')){
                    if(mapOfDriveIdVsDriveShift.get(drive.Id)!= Null){
                        driveModel driveModelMobile = new driveModel();
                        driveModelMobile.drawStart = DateTime.newInstanceGMT(drive.sked_Opportunity__r.Drive_Date__c, drive.sked_Start_Time__c);
                        driveModelMobile.drawEnd = DateTime.newInstanceGMT(drive.sked_Opportunity__r.Drive_Date__c, drive.sked_End_Time__c);
                        driveModelMobile.drawDuration = skedDateTimeUtils.getDifferentMinutes(driveModelMobile.drawStart, driveModelMobile.drawEnd);
                        driveModelMobile.drawHours = driveModelMobile.drawDuration / 60;
                        driveModelMobile.numberOf2rbcEquipments = 0;

                        //
                        // drive.drawStart = DateTime.newInstanceGMT(drive.sked_Opportunity__r.Drive_Date__c, drive.sked_Start_Time__c);
                        // drive.drawEnd = DateTime.newInstanceGMT(drive.sked_Opportunity__r.Drive_Date__c, drive.sked_End_Time__c);
                        // drive.drawDuration = skedDateTimeUtils.getDifferentMinutes(drive.drawStart, drive.drawEnd);
                        // drive.drawHours = drive.drawDuration / 60;

                        Integer numberOfDriveShift =  mapOfDriveIdVsDriveShift.get(drive.Id).size();
                        Boolean isLastShift = false;
                        for(sked_Drive_Shift__c driveShift : mapOfDriveIdVsDriveShift.get(drive.Id)){
                            isLastShift = driveShift.Name.contains(String.valueOf(numberOfDriveShift));
                            driveShiftModel driveShiftModelMobile = new driveShiftModel();
                            driveShiftModelMobile.drawStart =  (DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Start_Time__c));
                            driveShiftModelMobile.drawEnd = (DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_End_Time__c));
                            driveShiftModelMobile.drawDuration = skedDateTimeUtils.getDifferentMinutes(driveShiftModelMobile.drawStart, driveShiftModelMobile.drawEnd);
                            driveShiftModelMobile.drawHours = driveShiftModelMobile.drawDuration / 60;
                            driveShiftModelMobile.numberOf2rbcEquipments = 0;
                            DriveStaffingComplementModel staffingComplement ;
                            staffingComplement = calculate2rbcEquipmentQuantity (driveShift, staffingComplement, drive, driveModelMobile, driveShiftModelMobile );
                            //sked_Staff_Setup__c
                            Decimal staffCapacity = driveShift.sked_Max_Donor_Capacity__c;
                            if(driveShift.sked_Lunch_Break__c){
                                staffCapacity = Math.floor(calculateStaffCapacity(
                                    new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'},
                                    drive,
                                    driveShift,
                                    driveShiftModelMobile,
                                    collectionOperationSDMs,
                                    staffingDecisionMatrices 
                                ));
                            }
                            slotsNeedToUpdateMobile.addAll(generateShiftSlots(drive, driveShift, isLastShift, staffCapacity, driveModelMobile, driveShiftModelMobile));
                        }
                        
                    }
                } else if (drive.sked_Type_of_Drive__c == 'Fixed Site'){
                    
                    if(mapOfDriveIdVsDriveShift.get(drive.Id)!= Null){
                        
                        driveModel driveModelFixed = new driveModel();
                        driveModelFixed.drawStart = DateTime.newInstanceGMT(drive.sked_Opportunity__r.Drive_Date__c, drive.sked_Opportunity__r.Start_Time__c);
                        driveModelFixed.drawEnd = DateTime.newInstanceGMT(drive.sked_Opportunity__r.Drive_Date__c, drive.sked_Opportunity__r.End_Time__c);
                        driveModelFixed.drawDuration = skedDateTimeUtils.getDifferentMinutes(driveModelFixed.drawStart, driveModelFixed.drawEnd);
                        driveModelFixed.drawHours = driveModelFixed.drawDuration / 60;
                        driveModelFixed.numberOf2rbcEquipments = 0;

                        // Integer numberOfDriveShift =  mapOfDriveIdVsDriveShift.get(drive.Id).size();

                        // Integer numberOfDriveShift =  mapOfDriveIdVsDriveShift.get(drive.Id).size();
                        // Boolean isLastShift = false;

                        for(sked_Drive_Shift__c driveShift : mapOfDriveIdVsDriveShift.get(drive.Id)){
                            
                            // isLastShift = driveShift.Name.contains(numberOfDriveShift);

                            driveShiftModel driveShiftModelFixed = new driveShiftModel();
                            driveShiftModelFixed.drawStart =  skedDateTimeUtils.toTimezone((DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Start_Time__c)), driveShift.sked_Timezone__c);
                            driveShiftModelFixed.drawEnd = skedDateTimeUtils.toTimezone((DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_End_Time__c)), driveShift.sked_Timezone__c);
                            driveShiftModelFixed.drawDuration = skedDateTimeUtils.getDifferentMinutes(driveModelFixed.drawStart, driveModelFixed.drawEnd);
                            driveShiftModelFixed.drawHours = driveModelFixed.drawDuration / 60;
                            driveShiftModelFixed.numberOf2rbcEquipments = 0;
                            slotsNeedToUpdateFixedSite.addAll(generateShiftSlotsFixedSite(drive, driveShift, mapOfDriveIdVsDriveShift.get(driveShift.sked_Drive__c).size(), driveModelFixed, driveShiftModelFixed, AccIdVsFSPPMap));// 
                        }
                        
                    }
                    
                }
            }

            List<sked__Slot__c> skedSlots = new List<sked__Slot__c>();
            if(!slotsNeedToUpdateFixedSite.isEmpty()){
                for (FetchRelatedDriveData.DMLSlot slot : slotsNeedToUpdateFixedSite) {
                    sked__Slot__c skedSlot = (sked__Slot__c)slot.toSObject();
                    skedSlots.add(skedSlot);
                }
            }
            if(!slotsNeedToUpdateMobile.isEmpty()){
                for (MobileDriveGeneratorDMLService.DMLSlot slot : slotsNeedToUpdateMobile) {
                    sked__Slot__c skedSlot = (sked__Slot__c)slot.toSObject();
                    skedSlots.add(skedSlot);
                }
            }
            insert skedSlots;
        } catch (Exception expt) {
            BSF_Error_Log__c err = BSF_Utilities.getErrorLog('GenerateSlotsForDriveBatch','GenerateSlotsForDriveBatch','execute','Error',expt.getMessage(),expt.getStackTraceString());
            insert err;
        }
    }

    global void finish(Database.BatchableContext bc){
    
    }

    // Fixed site
    static List<FetchRelatedDriveData.DMLSlot> generateShiftSlotsFixedSite(sked_drive__c drive, sked_Drive_Shift__c driveShift, Decimal noOfDriveShift, driveModel driveModelFixed, driveShiftModel driveShiftModelFixed, Map<Id, List<sked_Fixed_Site_Procedure_Projection__c>> AccIdVsFSPPMap) {
        
        Id driveId = drive.Id;
        Id driveShiftId = driveShift.Id;
        List<FetchRelatedDriveData.DMLSlot> slotsNeedToUpdate = new List<FetchRelatedDriveData.DMLSlot>();
        List<FetchRelatedDriveData.DMLSlot> x2rbcSlots;
        List<FetchRelatedDriveData.DMLSlot> wbSlots;
        List<FetchRelatedDriveData.DMLSlot> plateletSlots;
        List<FetchRelatedDriveData.DMLSlot> plasmaSlots;

        // HRP - 9901 - siteOperationType is used to decide which type of slots will be generated
        
        boolean hasPlateletPlasma = drive.sked_Drive_Site__r.Operation_Type__c == Constants.INTEGRATED_OPERATION_TYPE || 
            drive.sked_Drive_Site__r.Operation_Type__c == Constants.NON_INTEGRATED_APH_OPERATION_TYPE;
        boolean has2rbcWb = drive.sked_Drive_Site__r.Operation_Type__c == Constants.INTEGRATED_OPERATION_TYPE;
        
        if (hasPlateletPlasma) {
            plateletSlots = generatePlateletSlotsFixedSite(drive, driveShift, driveShiftModelFixed);   
            
            slotsNeedToUpdate.addAll(plateletSlots);
            plasmaSlots = generatePlasmaSlotsFixedSite(drive, driveShift, driveShiftModelFixed);
            
            slotsNeedToUpdate.addAll(plasmaSlots);
            
        }
        
        if (has2rbcWb) {
            x2rbcSlots = generate2rbcSlotsFixedSite(drive, driveShift, driveShiftModelFixed);
            slotsNeedToUpdate.addAll(x2rbcSlots);
            wbSlots = generateWbSlots(drive, driveShift, noOfDriveShift, AccIdVsFSPPMap, driveModelFixed, driveShiftModelFixed);
            slotsNeedToUpdate.addAll(wbSlots);
        }

        for (FetchRelatedDriveData.DMLSlot slot : slotsNeedToUpdate) {
            slot.tempId = skedUtils.getKey();
            slot.driveId = driveId;
            slot.driveShiftId = driveShiftId;
        }
        return slotsNeedToUpdate;
    }

    static List<FetchRelatedDriveData.DMLSlot> generatePlateletSlotsFixedSite(sked_drive__c drive, sked_Drive_Shift__c driveShift, driveShiftModel driveShiftModelFixed)
    {
        
        List<FetchRelatedDriveData.DMLSlot> plateletSlots = new List<FetchRelatedDriveData.DMLSlot>();
        
        string fixedSiteAppointmentPattern = drive.sked_Drive_Site__r.sked_Fixed_Site_Appointment_Pattern__c;
        decimal numberOfPlateletAssets = drive.sked_Number_of_Platelet_Assets__c;
        
        slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
        configuration.interval = 60;
        configuration.rounds = new List<integer>();
        
        for (integer roundIndex = 0; roundIndex < driveShift.sked_Platelet_Rounds__c; roundIndex++)
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
        // 
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
        configuration.startTime = driveShiftModelFixed.drawStart;// need to check how to handle this
        integer currentRoundIndex = 0;
        Integer groupQuantityAfterFirstIteration = 0; // HRP - 9965
        Integer groupQuantity = 0;
        

        while (currentRoundIndex < driveShift.sked_Platelet_Rounds__c)
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
                    Slot.startTime = skedDateTimeUtils.switchTimezone(slot.startTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
                    slot.endTime = skedDateTimeUtils.switchTimezone(slot.endTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);                   
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

    static List<FetchRelatedDriveData.DMLSlot> generatePlasmaSlotsFixedSite(sked_drive__c drive, sked_Drive_Shift__c driveShift, driveShiftModel driveShiftModelFixed
    )
    {
        
        Set<DateTime> excludedSlotss = new set<DateTime>();
        DateTime plasmaSlotExcludeTimes = driveShiftModelFixed.drawStart;
        excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c));
        
        while( plasmaSlotExcludeTimes < driveShiftModelFixed.drawEnd){
            plasmaSlotExcludeTimes = plasmaSlotExcludeTimes.addMinutes(180);
            excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c));
        }

        

        //HRP-13198 --> Starts Here
        DateTime firstPlasmaSlotStart;
        DateTime firstPlateletRoundEnd = driveShiftModelFixed.drawStart.addMinutes(60);
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
        configuration.endTime = driveShiftModelFixed.drawEnd;
        configuration.excludedSlots = excludedSlotss;
        configuration.roundInterval = 90;
        configuration.numberOfGroups = 2;
        configuration.groupInterval = 30;
        configuration.slotType = Constants.PROCEDURE_TYPE_PLASMA;
        configuration.slotDuration = 90;
        configuration.startTime = firstPlasmaSlotStart; //HRP-13198
        
        configuration.startTime = skedDateTimeUtils.switchTimezone(configuration.startTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
        configuration.endTime = skedDateTimeUtils.switchTimezone(configuration.endTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
        return generatePlasmaSlotsByNumberOfAssets(configuration, drive);
        
    }

    static List<FetchRelatedDriveData.DMLSlot> generatePlasmaSlotsByNumberOfAssets(slotGeneratorConfigModel configuration, sked_drive__c drive) {
        List<FetchRelatedDriveData.DMLSlot> allSlots = new List<FetchRelatedDriveData.DMLSlot>();
        List<FetchRelatedDriveData.DMLSlot> slots = new List<FetchRelatedDriveData.DMLSlot>();
        
        Datetime tempStart = configuration.startTime;
        while (tempStart < configuration.endTime) {
            decimal remainingNumberOfAssets = drive.sked_Number_of_Plasma_Assets__c;
            for (integer i = 0; i < configuration.numberOfGroups; i++) {
                Integer groupQuantity = integer.valueOf(Math.Ceil(drive.sked_Number_of_Plasma_Assets__c / configuration.numberOfGroups));
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

    static List<FetchRelatedDriveData.DMLSlot> generate2rbcSlotsFixedSite(sked_drive__c drive, sked_Drive_Shift__c driveShift, driveShiftModel driveShiftModelFixed
    ) {
        
        Set<DateTime> excludedSlotss = new set<DateTime>();
        DateTime plasmaSlotExcludeTimes = driveShiftModelFixed.drawStart;
        excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c));
        
        while( plasmaSlotExcludeTimes < driveShiftModelFixed.drawEnd){
            plasmaSlotExcludeTimes = plasmaSlotExcludeTimes.addMinutes(180);
            excludedSlotss.add(skedDateTimeUtils.switchTimezone(plasmaSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c));
        }
        
        slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
        configuration.endTime = driveShiftModelFixed.drawEnd;
        configuration.excludedSlots = excludedSlotss;
        configuration.roundInterval = 60;
        configuration.numberOfGroups = 2;
        configuration.groupInterval = 30;
        configuration.slotType = Constants.PROCEDURE_TYPE_2RBC;
        configuration.slotDuration = 60;
        configuration.startTime = driveShiftModelFixed.drawStart.addMinutes(60);
        
        configuration.startTime = skedDateTimeUtils.switchTimezone(configuration.startTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
        configuration.endTime = skedDateTimeUtils.switchTimezone(configuration.endTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
        
        return generateSlotsByNumberOfAssets(configuration, drive);
    }

    static List<FetchRelatedDriveData.DMLSlot> generateSlotsByNumberOfAssets(slotGeneratorConfigModel configuration, sked_drive__c drive) {
        List<FetchRelatedDriveData.DMLSlot> slots = new List<FetchRelatedDriveData.DMLSlot>();
        
        Datetime tempStart = configuration.startTime;
        while (tempStart < configuration.endTime) {
            decimal remainingNumberOfAssets = drive.sked_Number_of_2RBC_Assets__c;
            for (integer i = 0; i < configuration.numberOfGroups; i++) {
                decimal groupQuantity = Math.ceil(drive.sked_Number_of_2RBC_Assets__c / configuration.numberOfGroups);
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

    static List<FetchRelatedDriveData.DMLSlot> generateWbSlots(
        sked_drive__c drive, sked_Drive_Shift__c driveShift,
        Decimal noOfDriveShift, Map<Id, List<sked_Fixed_Site_Procedure_Projection__c>> AccIdVsFSPPMap,  driveModel driveModelFixed, driveShiftModel driveShiftModelFixed 
    ) {  
        Decimal estimatedWbslots;
        List<FetchRelatedDriveData.DMLSlot> wholeBloodSlots = new List<FetchRelatedDriveData.DMLSlot>();
        // HRP-12144 --> Starts Here (Added new configuration for FS drives where slot multiplier remains 140%)
        
        slwcSetting.adminSetting skedAdminSetting = new slwcSetting.adminSetting();
        Decimal paddingPercentage = drive.sked_Opportunity__r.Slot_Generator__c != NULL ? drive.sked_Opportunity__r.Slot_Generator__c / 100 : skedAdminSetting.callListRecipientNoneFixedSite / 100; //HRP-12011
        Map<String, Decimal> fsppTypeAndValuesMap = getFSPPTypeAndDeferalQnsValue(drive, AccIdVsFSPPMap);// need to handle this as well

        // HRP-12480 --> Starts Here (Check if FSPP exist with Deferral and QNS value)
        Boolean isValidFSPPExist = fsppTypeAndValuesMap != NULL 
                                && fsppTypeAndValuesMap.containsKey('QNS_'+Constants.PROCEDURE_TYPE_WB+'Staff')
                                && fsppTypeAndValuesMap.containsKey('Deferral_'+Constants.PROCEDURE_TYPE_WB+'Staff');
    
        estimatedWbslots = isValidFSPPExist ? Math.ceil(Math.ceil((drive.sked_WB_Projected_Procedures__c / (1 - fsppTypeAndValuesMap.get('QNS_'+Constants.PROCEDURE_TYPE_WB+'Staff')) / (1 - fsppTypeAndValuesMap.get('Deferral_'+Constants.PROCEDURE_TYPE_WB+'Staff')))) * paddingPercentage) : 0;
        
        // HRP-12144 --> Ends Here
        
        integer totalSlots = estimatedWbslots > 0 ? integer.valueOf(estimatedWbslots) : 0;

        // HRP-12480 --> Ends Here
        
        // new - 10456
        if(totalSlots > 0) { // HRP-1280
            Set<DateTime> excludedSlotss = new set<DateTime>();      
            DateTime plateletSlotExcludeTimes = driveShiftModelFixed.drawStart;//need to check how to handle this
            excludedSlotss.add(skedDateTimeUtils.switchTimezone(plateletSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c));
            
            while(plateletSlotExcludeTimes < driveShiftModelFixed.drawEnd ) {//need to check how to handle this
                plateletSlotExcludeTimes = plateletSlotExcludeTimes.addMinutes(180);
                if(plateletSlotExcludeTimes == driveShiftModelFixed.drawEnd) {//need to check how to handle this
                    break;
                }     
                excludedSlotss.add(skedDateTimeUtils.switchTimezone(plateletSlotExcludeTimes,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c));   
            }
            integer wbSlotDuration = 15;
            slotGeneratorConfigModel configuration = new slotGeneratorConfigModel();
            configuration.excludedSlots = excludedSlotss;
            configuration.interval = 60;
            configuration.lastSlotStart = driveShiftModelFixed.drawEnd;//need to check how to handle this
            configuration.rounds = new List<integer>();
            configuration.rounds.add(0);
            configuration.rounds.add(15);
            configuration.rounds.add(30);
            configuration.rounds.add(45);
            configuration.slotDuration = wbSlotDuration;
            configuration.slotType = Constants.APPOINTMENT_TYPE_WB;
            configuration.startTime = driveShiftModelFixed.drawStart;//need to check how to handle this
            configuration.totalSlots = totalSlots;
            //FetchRelatedDriveData.DMLCollectionOperation coRec = data.mapCollectionOperation.get(drive.sked_Collection_Operation__c);
            //sked_Collection_Operation__r.sked_Skip_Last_Appointment__c, sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c
            Boolean skipLastAppointment = !string.isBlank(drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c) && drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c.contains(drive.sked_Type_of_Drive__c);//need to check how to handle this
            if (skipLastAppointment) {//bug
                configuration.lastSlotStart = configuration.lastSlotStart.addMinutes(-wbSlotDuration);
            }
            wholeBloodSlots = generateWbSlots(configuration, drive, driveShift, noOfDriveShift,skipLastAppointment, driveModelFixed);
            
            // Lunch break slot reduction
            if(driveShift.sked_Lunch_Break__c) {            
                applyLunchBreakSlotReductionForWbSlots(wholeBloodSlots, drive, driveShift);
            }
        }
        return wholeBloodSlots;
    }

    static void applyLunchBreakSlotReductionForWbSlots(
        List<FetchRelatedDriveData.DMLSlot> wbSlots,
        sked_drive__c drive, sked_Drive_Shift__c driveShift
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
        
        DateTime lunchBreakEndTime = DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Lunch_Break_End_Time__c);
        lunchBreakEndTime = skedDateTimeUtils.switchTimezone(lunchBreakEndTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
        
                    
        DateTime lunchBreakStartTime = DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Lunch_Break_Start_Time__c);
        lunchBreakStartTime = skedDateTimeUtils.switchTimezone(lunchBreakStartTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
        
        for (FetchRelatedDriveData.DMLSlot slot : wbSlots)
        {	
            if (lunchBreakStartTime <= slot.startTime && slot.endTime <= lunchBreakEndTime) 
            {
                totalSlots++;	
            }	
        }
            Decimal numberOfWbReduced = Math.ceil((totalSlots * driveShift.sked_Sign_Up_Reduction__c)/100);
            
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

    static List<FetchRelatedDriveData.DMLSlot> generateWbSlots(
        slotGeneratorConfigModel configuration,
        sked_drive__c drive, sked_Drive_Shift__c driveShift,
        Decimal noOfDriveShift,
        Boolean skipLastAppointment,
        driveModel driveModelFixed
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
                DateTime tempDtTimeZone = skedDateTimeUtils.switchTimezone(tempDt,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);

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
                    slot.startTime = skedDateTimeUtils.switchTimezone(slot.startTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
                    slot.endTime = skedDateTimeUtils.switchTimezone(slot.endTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c);
                    
                    slots.add(slot);
                    slotCount++;
                    if (slotCount == configuration.totalSlots) {
                        break;
                    }
                }
                tempDt = tempDt.addMinutes(configuration.interval);
                if(tempDt > configuration.lastSlotStart || (tempDt == configuration.lastSlotStart && configuration.lastSlotStart != driveModelFixed.drawEnd && skipLastAppointment==false))
                {//need to check how to handle this
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

    static Map<String, Decimal> getFSPPTypeAndDeferalQnsValue(sked_drive__c drive, Map<Id, List<sked_Fixed_Site_Procedure_Projection__c>> AccIdVsFSPPMap) {
        Map<String, Decimal> fsppTypeVsValuesMap = new Map<String,Decimal>();
        if(AccIdVsFSPPMap.get(drive.sked_Account__c) != NULL) {
        	for (sked_Fixed_Site_Procedure_Projection__c setting : AccIdVsFSPPMap.get(drive.sked_Account__c)) {
                if(setting.sked_Procedure_Type__c != Constants.PROCEDURE_TYPE_PLATELET) {
                    if((setting.sked_Effective_Start_Date__c == NULL || setting.sked_Effective_Start_Date__c <= drive.sked_Drive_Date__c) 
                        && (setting.sked_Effective_End_Date__c == NULL || setting.sked_Effective_End_Date__c >= drive.sked_Drive_Date__c)) {
                        fsppTypeVsValuesMap.put('Deferral_'+setting.sked_Procedure_Type__c+'Staff', setting.sked_Deferral__c / 100);
                        fsppTypeVsValuesMap.put('QNS_'+setting.sked_Procedure_Type__c+'Staff', setting.sked_QNS__c / 100);
                    }
                }
            }
        }
        return fsppTypeVsValuesMap;
    }

    // fixed site end here
    
    
    // Mobile Site

    public virtual List<MobileDriveGeneratorDMLService.DMLSlot> generateShiftSlots(sked_drive__c drive, sked_Drive_Shift__c driveShift, 
        Boolean isLastShift,
        Decimal staffCapacityValue, driveModel driveModelMobile, driveShiftModel driveShiftModelMobile)// HRP-10667
        {
               
            Id driveId = drive.Id;
            Id driveShiftId = driveShift.Id;
            String timezoneSidId = driveShift.sked_Drive__r.sked_Drive_Site__r.sked_Timezone__c;
            //HRP-12011 --> starts Here
            Decimal paddingPercentage; 
            
            if(drive.sked_Opportunity__r.Slot_Generator__c != NULL) {
                
                paddingPercentage = drive.sked_Opportunity__r.Slot_Generator__c / 100;
            } else {
                
                slwcSetting.adminSetting skedAdminSetting = new slwcSetting.adminSetting();  // HRP-11443 --> Starts Here - Slot multiplier percentages have been made configurable and are taken from skedulo admin settings   
                paddingPercentage = skedAdminSetting.callListRecipient / 100;
                if (!drive.sked_Opportunity__r.Call_List_Recipient_Exist__c)
                {
                    
                    paddingPercentage = skedAdminSetting.callListRecipientNone / 100;
                }
            }  
            // HRP-11443,12011 --> Ends Here

            // Calculation of Total Appointments = staff Capacity * paddingPercentage

            Decimal totalDefaultSlots = Math.ceil(staffCapacityValue*paddingPercentage); // HRP-10667
            
            Boolean reduceLastAppointmentSlot = false;
            
            //driveShift.slots = new List<MobileDriveGeneratorDMLService.DMLSlot>();// test
            
            //if (driveShift.jobs != NULL && !driveShift.jobs.isEmpty()) {
                // MobileDriveGeneratorDMLService.DMLJob x2rbcJob;
                // for (MobileDriveGeneratorDMLService.DMLJob job : driveShift.jobs) {
                //     if (job.type == '2RBC') {                        
                //         x2rbcJob = job;
                //         break;
                //     }
                // }
                // Decimal x2rbcResourceQuantity = x2rbcJob != NULL ? x2rbcJob.quantity : 0;
                Decimal driveShiftDrawHr = driveModelMobile.drawHours / drive.sked_Drive_Shift_Count__c;   
                Decimal total2rbcSlots = Math.ceil( driveShiftDrawHr * 1 * (driveShiftModelMobile.numberOf2rbcEquipments != null ? driveShiftModelMobile.numberOf2rbcEquipments : 0));
                slotGeneratorConfigModel x2rbcConfig = new slotGeneratorConfigModel();
                x2rbcConfig.interval = 60;
                x2rbcConfig.lastSlotStart = driveShiftModelMobile.drawEnd.addMinutes(-30);
                x2rbcConfig.rounds = new List<integer>();
                
                // two groups 
                x2rbcConfig.rounds.add(0);
                x2rbcConfig.rounds.add(30);               
                x2rbcConfig.slotDuration = 60; 
                x2rbcConfig.slotType = '2RBC';
                x2rbcConfig.startTime = driveShiftModelMobile.drawStart;
                x2rbcConfig.totalSlots = integer.valueOf(total2rbcSlots);
                x2rbcConfig.timezoneSidId = timezoneSidId;	
                x2rbcConfig.driveEndTime = driveModelMobile.drawEnd;
                
                // generate 2RBC appointment
                List<MobileDriveGeneratorDMLService.DMLSlot> x2rbcSlots = generateSlots(x2rbcConfig,reduceLastAppointmentSlot,isLastShift);
                
                integer wbSlotDuration = 15;
                slotGeneratorConfigModel wbConfig = new slotGeneratorConfigModel();
                wbConfig.interval = 60;
                wbConfig.lastSlotStart = driveShiftModelMobile.drawEnd;
                wbConfig.rounds = new List<integer>();
                
                // four groups 
                wbConfig.rounds.add(0);
                wbConfig.rounds.add(30);
                wbConfig.rounds.add(15);
                wbConfig.rounds.add(45);
                wbConfig.slotDuration = wbSlotDuration;
                wbConfig.slotType = 'Whole Blood';
                wbConfig.startTime = driveShiftModelMobile.drawStart;
                wbConfig.totalSlots = integer.valueOf(totalDefaultSlots - total2rbcSlots);
                wbConfig.timezoneSidId = timezoneSidId;	
                wbConfig.driveEndTime = driveModelMobile.drawEnd;
                // Boolean skipLastAppointment = drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment__c && !string.isBlank(drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c) && drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c.contains(drive.sked_Type_of_Drive__c);//need to check how to handle this
                // MobileDriveGeneratorDMLService.DMLCollectionOperation coRec = data.mapCollectionOperation.get(drive.collectionOperationId);
                Boolean skipLastAppointment = !string.isBlank(drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c) && drive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c.contains(drive.sked_Type_of_Drive__c);
                //bug
                if (isLastShift && skipLastAppointment){
                    
                    reduceLastAppointmentSlot = true;
                }
                
                // generate wb appointment
                List<MobileDriveGeneratorDMLService.DMLSlot> wbSlots = generateSlots(wbConfig,reduceLastAppointmentSlot,isLastShift);
                // Slot reduction logic - set reduction % 
                DriveStaffingComplementModel staffingComplement = new DriveStaffingComplementModel();
                decimal otherResourceQuantity = 0;
                
                if (driveShift.sked_Lunch_Break__c && !driveShift.sked_Lunch_Break_Before_Draw_Hours__c){
                    decimal coMaxLunchBreakDuration = drive.sked_Maximum_Lunch_Break_Duration__c != NULL ? Integer.valueOf(drive.sked_Maximum_Lunch_Break_Duration__c) : 30;
                    // if (wbSlots != NULL && !wbSlots.isEmpty()){
                        
                    //     MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition = findLunchBreakDefinition(data, coMaxLunchBreakDuration, otherResourceQuantityOne, driveShift );
                    //     driveShift.signUpReduction = lunchBreakDefinition.slotReduction;
                    // }
                    
                    DateTime lunchBreakEndTime = DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Lunch_Break_End_Time__c);
                    lunchBreakEndTime = skedDateTimeUtils.switchTimezone(lunchBreakEndTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c); 
                    
                    DateTime lunchBreakStartTime = DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Lunch_Break_Start_Time__c);
                    
                    lunchBreakStartTime = skedDateTimeUtils.switchTimezone(lunchBreakStartTime,TimeZone.getTimeZone('GMT').getId(),drive.sked_Drive_Site__r.sked_Timezone__c); 
                    if (wbSlots != NULL && !wbSlots.isEmpty()) {//sked_Sign_Up_Reduction__c
                        
                        // MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition = findLunchBreakDefinition(coMaxLunchBreakDuration, driveShift );
                        slotGeneratorConfigModel slotReductionConfiguration = new slotGeneratorConfigModel();
                        slotReductionConfiguration.endTime = lunchBreakEndTime;
                        slotReductionConfiguration.interval = 60;
                        slotReductionConfiguration.rounds = new List<integer>();
                        slotReductionConfiguration.rounds.add(0);
                        slotReductionConfiguration.rounds.add(30);
                        slotReductionConfiguration.rounds.add(15);
                        slotReductionConfiguration.rounds.add(45);
                        slotReductionConfiguration.slotReduction = integer.valueOf(driveShift.sked_Sign_Up_Reduction__c);
                        slotReductionConfiguration.startTime = lunchBreakStartTime;
                        slotReductionConfiguration.timezoneSidId = timezoneSidId;	
                        slotReductionConfiguration.driveDate = drive.sked_Drive_Date__c;
                        if (driveShift.sked_Lunch_Break__c) {
                            
                            reduceSlots(wbSlots, slotReductionConfiguration);
                        }
                    }                       
                }
                
                //driveShift.slots.addAll(x2rbcSlots);
                
                //driveShift.slots.addAll(wbSlots);
               
                List<MobileDriveGeneratorDMLService.DMLSlot> slotsNeedToUpdate = new List<MobileDriveGeneratorDMLService.DMLSlot>();
                slotsNeedToUpdate.addAll(x2rbcSlots);
                slotsNeedToUpdate.addAll(wbSlots);
                for (MobileDriveGeneratorDMLService.DMLSlot slot : slotsNeedToUpdate) {
                    slot.tempId = skedUtils.getKey();
                    slot.driveId = driveId;
                    slot.driveShiftId = driveShiftId;
                }
            //}
            return slotsNeedToUpdate;
        }
    
        public virtual List<MobileDriveGeneratorDMLService.DMLSlot> generateSlots(slotGeneratorConfigModel configuration, Boolean reduceLastAppointmentSlot, Boolean isLastShift) {
            
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

    // protected virtual MobileDriveGeneratorDMLService.DMLLunchBreakDefinition findLunchBreakDefinition(MobileDriveGeneratorDMLService.DMLData data, decimal lunchBreakDuration, decimal staffSetup, MobileDriveGeneratorDMLService.DMLDriveShift driveShift) {
    //     MobileDriveGeneratorDMLService.DMLLunchBreakSetting lunchBreakSetting;
    //     for (MobileDriveGeneratorDMLService.DMLLunchBreakSetting setting : data.lunchBreakSettings) {
    //         if (setting.maximumLunchBreakDuration == lunchBreakDuration) {
    //             lunchBreakSetting = setting;
    //             break;
    //         }
    //     }
    //     driveShift.lunchBreakPerperson = lunchBreakSetting.maximumLunchBreakDuration;
    //     MobileDriveGeneratorDMLService.DMLLunchBreakDefinition lunchBreakDefinition;
    //     for (MobileDriveGeneratorDMLService.DMLLunchBreakDefinition definition : lunchBreakSetting.lunchBreakDefinitions) {
    //         if (definition.minNumberOfStaff <= staffSetup && staffSetup <= definition.maxNumberOfStaff) {
    //             lunchBreakDefinition = definition;
    //         }
    //     }
    //     return lunchBreakDefinition;
    // }
//sked_drive__c drive, sked_Drive_Shift__c driveShift
    public virtual DriveStaffingComplementModel calculate2rbcEquipmentQuantity(sked_Drive_Shift__c driveShift, DriveStaffingComplementModel staffingComplement, sked_drive__c drive, driveModel driveModelMobile, driveShiftModel driveShiftModelMobile) {
        
        //staffingComplement.numberOf2rbcEquipments = 0;
        Decimal noOf2RBCAssests = 0;
        
        // HRP-11173 (Added NULL Checks)
        if(!(drive.sked_2RBC_Projected_Procedures__c == 0 || drive.sked_2RBC_Projected_Procedures__c == NULL)) {
            
            if (driveShiftModelMobile.drawHours > 1) {
                
                noOf2RBCAssests = Math.ceil( (Decimal)driveShift.sked_2RBC_Projected_Procedures__c / (driveShiftModelMobile.drawHours));
                if(noOf2RBCAssests < 1) {
                    
                    noOf2RBCAssests = 1;
                }
                //staffingComplement.numberOf2rbcEquipments = noOf2RBCAssests;
                
                driveShiftModelMobile.numberOf2rbcEquipments = noOf2RBCAssests; 
            }
            //staffingComplement.numberOf2rbc = Math.ceil(staffingComplement.numberOf2rbcEquipments / 2);
            
        } else {
            
            driveShiftModelMobile.numberOf2rbcEquipments = 0;
        }
        
        driveModelMobile.numberOf2rbcEquipments = noOf2RBCAssests; 
        //staffingComplement.map_role_resourceQuantity.put(Constants.PROCEDURE_TYPE_2RBC, staffingComplement.numberOf2rbc);
        
        return staffingComplement;
    }

    public virtual void reduceSlots(List<MobileDriveGeneratorDMLService.DMLSlot> slots, slotGeneratorConfigModel configuration) {	
        
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

    public Decimal calculateStaffCapacity(
            List<String> capacityNeededFor,
            sked_drive__c drive, sked_Drive_Shift__c driveShift, driveShiftModel driveShiftModelMobile, List<sked_Collection_Operation_SDM__c> collectionOperationSDMs, Map<Id,sked_Staffing_Decision_Matrix__c> staffingDecisionMatrices
       ) { //driveShiftModelMobile, driveModelMobile
            Id staffingDecisionMatrixId ;
            sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c();
            for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
                if((collectionOperationSdm.sked_Effective_Start_Date__c <= drive.sked_Drive_Date__c || collectionOperationSdm.sked_Effective_Start_Date__c == NULL) && 
                    (collectionOperationSdm.sked_Effective_End_Date__c >= drive.sked_Drive_Date__c || collectionOperationSdm.sked_Effective_Start_Date__c == NULL) &&
                    collectionOperationSdm.sked_Collection_Operation__c == drive.sked_Collection_Operation__c){
                        staffingDecisionMatrixId = collectionOperationSdm.sked_Staffing_Decision_Matrix__c;
                        staffingDecisionMatrix = staffingDecisionMatrices.get(staffingDecisionMatrixId);
                        break;
                }
            }
            Decimal staffCapacity = 0;
            Map<String, Decimal> map_role_resourceQuantity = new Map<String, Decimal>();
            if(driveShift.sked_jobs__r != Null){
                for(sked__Job__c job : driveShift.sked_jobs__r){
                    for (String role : capacityNeededFor) {
                        if(job.sked_Resource_Role__c != NULL && job.sked_Resource_Role__c == role){
                            if(map_role_resourceQuantity.get(role) == NULL){
                                if(role == Constants.JOB_TYPE_VP_HH){
                                    map_role_resourceQuantity.put(role, job.sked_VPHH_Quantity__c);
                                } else{
                                    map_role_resourceQuantity.put(role, job.sked__Quantity__c);
                                }
                            } 
                        }
                    }
                }
            }
            Map<string, decimal> donorCapacityMap = new Map<string, decimal>();
            donorCapacityMap.put(Constants.JOB_TYPE_DRIVER, staffingDecisionMatrix.sked_Driver_Capacity__c != NULL ? staffingDecisionMatrix.sked_Driver_Capacity__c : 0);
            donorCapacityMap.put(Constants.JOB_TYPE_DRIVER_SUPPORT, staffingDecisionMatrix.sked_Driver_Support_Capacity__c != NULL ? staffingDecisionMatrix.sked_Driver_Support_Capacity__c : 0);
            donorCapacityMap.put(Constants.PROCEDURE_TYPE_2RBC, staffingDecisionMatrix.sked_2RBC_Staff_Capacity__c != NULL ? staffingDecisionMatrix.sked_2RBC_Staff_Capacity__c : 0);
            donorCapacityMap.put(Constants.JOB_TYPE_VP_HH, staffingDecisionMatrix.sked_VP_HH_Capacity__c != NULL ? staffingDecisionMatrix.sked_VP_HH_Capacity__c : 0);
            donorCapacityMap.put(Constants.JOB_TYPE_CHARGE, staffingDecisionMatrix.sked_Charge_Capacity__c != NULL ? staffingDecisionMatrix.sked_Charge_Capacity__c : 0);
            //HRP-10474 Start
            decimal drawHours = driveShiftModelMobile.drawHours;
            
            for (String role : capacityNeededFor) {
                Decimal sdmRoleCapacity = donorCapacityMap.containsKey(role) && donorCapacityMap.get(role) != NULL ? donorCapacityMap.get(role) : 0;
                Decimal resourceQuantity = map_role_resourceQuantity.containsKey(role) && map_role_resourceQuantity.get(role) != NULL ? map_role_resourceQuantity.get(role) : 0;
                if (role.equalsIgnorecase(Constants.PROCEDURE_TYPE_2RBC)) {
                    Decimal noOf2RBCAssets = driveShiftModelMobile.numberOf2rbcEquipments;
                    Decimal noOfResourcesHaveEnough2RBCAssets = Math.min(resourceQuantity, Math.floor(noOf2RBCAssets / 2));
                    Decimal noOfResourcesNotHaveEnough2RBCAssets = Math.max(resourceQuantity - noOfResourcesHaveEnough2RBCAssets, 0);
                    Decimal capacity1 = noOfResourcesHaveEnough2RBCAssets * 2 * driveShiftModelMobile.drawHours;
                    Decimal capacity2 = noOfResourcesNotHaveEnough2RBCAssets * sdmRoleCapacity * driveShiftModelMobile.drawHours;
                    staffCapacity += capacity1 + capacity2;
                } else {
                    staffCapacity += resourceQuantity * sdmRoleCapacity *  drawHours;
                }                       
            }
            return staffCapacity;
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
        public decimal numberOfWholeBloodResources;
        public decimal numberOf2rbcResources;
        public decimal numberOfApheresisCharge;
        
          public DriveStaffingComplementModel() {
            this.map_role_resourceQuantity = new Map<String, Decimal>(); // HRP-11634
        }
    }

    public class driveShiftModel {
        public DateTime drawStart;
        public DateTime drawEnd;
        public decimal drawDuration;
        public decimal drawHours;
        public decimal numberOf2rbcEquipments;
    }

    public class driveModel {
        public DateTime drawStart;
        public DateTime drawEnd;
        public decimal drawDuration;
        public decimal drawHours;
        public decimal numberOf2rbcEquipments;
    }
}