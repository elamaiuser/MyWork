public without sharing class DriveMovementController {

    public class UIResponse {
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<MovementWrapper> movements { get; set; }
    }

    public class MovementWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String movementRecordId { get; set; } 
        @AuraEnabled public String driveId { get; set; }
        @AuraEnabled public String driveName { get; set; }
        @AuraEnabled public String driveDateStr { get; set; }
        @AuraEnabled public String driveSiteId { get; set; }
        @AuraEnabled public String driveSiteName { get; set; }
        @AuraEnabled public String movementNumber { get; set; }
        @AuraEnabled public String selectedJobId { get; set; }
        @AuraEnabled public String carrier { get; set; }
        @AuraEnabled public String defaultTmsSiteId { get; set; }
        @AuraEnabled public String defaultTmsSiteName { get; set; }
        @AuraEnabled public List<Map<String, String>> assignedTmsSites { get; set; }
        @AuraEnabled public Boolean isRoundTrip { get; set; }
        @AuraEnabled public Boolean isCarrierDisabled { get; set; }
        @AuraEnabled public Boolean isDriveDisabled { get; set; }
        @AuraEnabled public Boolean isJobDisabled { get; set; }
        @AuraEnabled public Boolean isReadOnly { get; set; } 
        @AuraEnabled public List<Map<String, String>> jobOptions { get; set; }
        @AuraEnabled public List<StopWrapper> stops { get; set; }
        @AuraEnabled public String status { get; set; }
    }

    public class StopWrapper {
        @AuraEnabled public Integer sequence { get; set; }
        @AuraEnabled public String siteType { get; set; } 
        @AuraEnabled public String siteId { get; set; }
        @AuraEnabled public String siteName { get; set; }
        @AuraEnabled public String departStartStr { get; set; }
        @AuraEnabled public String departEndStr { get; set; }
        @AuraEnabled public String arriveStartStr { get; set; }
        @AuraEnabled public String arriveEndStr { get; set; }
        @AuraEnabled public Boolean isFirstStop { get; set; }
        @AuraEnabled public Boolean isLastStop { get; set; }
        @AuraEnabled public Boolean isSecondStop { get; set; }
        @AuraEnabled public Boolean canAdd { get; set; }
        @AuraEnabled public Boolean canRemove { get; set; }
        @AuraEnabled public Boolean isSiteDisabled { get; set; }
        @AuraEnabled public Boolean showDropdown { get; set; }
        @AuraEnabled public List<Map<String, String>> siteSearchResults { get; set; }
    }

    private class MovementException extends Exception {}

    private static final String SOBJ_MOVEMENT = Drive_Delivery_Movement__c.SObjectType.getDescribe().getName();
    private static final String SOBJ_SHIPMENT = Drive_Delivery_Shipment__c.SObjectType.getDescribe().getName();
    private static final String SOBJ_DRIVE = sked_Drive__c.SObjectType.getDescribe().getName();
    private static final String SOBJ_JOB = sked_Drive_Delivery_Job__c.SObjectType.getDescribe().getName();
    
    private static final String EQUIP_TYPE_CAR = 'Car';
    private static final String PREFIX_MOVEMENT = 'M-';
    private static final String ERR_INIT = 'Init Error: ';
    private static final String ERR_SAVE = 'Error Saving: ';
    private static final String ERR_FINALIZE = 'Error Finalizing: ';
    private static final String ERR_WITHDRAW = 'Error Withdrawing: ';
    private static final String ERR_MULTIPLE_FINAL = 'You cannot finalize multiple movements for the same Job simultaneously.';
    private static final String ERR_EXISTING_FINAL = 'A Final Movement already exists for Job: {0}. Only one Final Movement is allowed per Job.';
    private static final String SUCCESS_SAVE = 'Record(s) saved successfully.';
    private static final String SUCCESS_FINALIZE = 'Record(s) finalized and integration generated successfully.';
    private static final String SUCCESS_CANCEL = 'Record(s) canceled successfully.';

    @AuraEnabled
    public static UIResponse getInitialData(String recordId, String parentRecordId, String actionType, String objectApiName) {
        UIResponse response = new UIResponse();
        try {
            response.movements = new List<MovementWrapper>();
            Id pId = String.isNotBlank(parentRecordId) ? (Id)parentRecordId : null;
            Id rId = String.isNotBlank(recordId) ? (Id)recordId : null;
            
            String parentObjType = pId != null ? pId.getSObjectType().getDescribe().getName() : '';
            String recordObjType = rId != null ? rId.getSObjectType().getDescribe().getName() : '';

            if (BSF_Constants.ACTION_NEW.equalsIgnoreCase(actionType) && SOBJ_MOVEMENT.equalsIgnoreCase(parentObjType)) {
                actionType = BSF_Constants.ACTION_EDIT;
                rId = pId; 
                recordObjType = SOBJ_MOVEMENT;
            }

            TmsAssignmentResult tmsData = getTmsAssignments();

            if (BSF_Constants.ACTION_NEW.equalsIgnoreCase(actionType)) {
                response.movements.add(handleNewAction(pId, parentObjType, tmsData));
            } else if (BSF_Constants.ACTION_EDIT.equalsIgnoreCase(actionType)) {
                response.movements.add(handleEditAction(rId, recordObjType, tmsData));
            }

            response.isSuccess = true;
        } catch (Exception e) {
            response.isSuccess = false;
            response.message = ERR_INIT + e.getMessage();
        }
        return response;
    }

    @AuraEnabled
    public static List<Map<String, String>> searchSites(String searchTerm, String siteType) {
        String queryTerm = '%' + searchTerm + '%';
        List<Map<String, String>> results = new List<Map<String, String>>();
        Date todayDate = Date.today();
        
        try {
            if (BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(siteType)) {
                for(TMS_Site__c site : [SELECT Id, Name FROM TMS_Site__c WHERE Name LIKE :queryTerm AND Effective_Date__c <= :todayDate AND (End_Date__c >= :todayDate OR End_Date__c = null) WITH SYSTEM_MODE LIMIT 10]) {
                    results.add(new Map<String, String>{ 'label' => site.Name, 'value' => site.Id });
                }
            } else {
                for(sked__Location__c site : [SELECT Id, Name FROM sked__Location__c WHERE Name LIKE :queryTerm AND sked_Active__c = true WITH SYSTEM_MODE LIMIT 10]) {
                    results.add(new Map<String, String>{ 'label' => site.Name, 'value' => site.Id });
                }
            }
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
        return results;
    }

    @AuraEnabled
    public static UIResponse saveMovements(String jsonData) {
        UIResponse response = new UIResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            List<MovementWrapper> wrappers = (List<MovementWrapper>)JSON.deserialize(jsonData, List<MovementWrapper>.class);
            Set<Id> existingMovementIds = extractMovementIds(wrappers);
            
            List<Drive_Delivery_Movement__c> movementsToUpsert = prepareMovementsForUpsert(wrappers);
            processDmlUpsert(Database.upsert(movementsToUpsert, false));
            
            Map<Id, String> movStatusMap = fetchMovementStatuses(existingMovementIds);
            Map<Id, Map<Decimal, Drive_Delivery_Shipment__c>> exShipmentMap = fetchExistingShipments(existingMovementIds);
            
            List<Drive_Delivery_Shipment__c> shipmentsToUpsert = new List<Drive_Delivery_Shipment__c>();
            List<Drive_Delivery_Shipment__c> shipmentsToDelete = new List<Drive_Delivery_Shipment__c>();

            for (Integer idx = 0; idx < wrappers.size(); idx++) {
                MovementWrapper mw = wrappers[idx];
                mw.movementRecordId = movementsToUpsert[idx].Id;
                String currentStatus = movStatusMap.containsKey(mw.movementRecordId) ? movStatusMap.get(mw.movementRecordId) : BSF_Constants.STATUS_DRAFT;
                Map<Decimal, Drive_Delivery_Shipment__c> shipMapForMov = exShipmentMap.containsKey(mw.movementRecordId) ? exShipmentMap.get(mw.movementRecordId) : new Map<Decimal, Drive_Delivery_Shipment__c>();
                
                if (mw.stops == null || mw.stops.isEmpty()) continue;
                
                processWrapperStops(mw, currentStatus, shipMapForMov, shipmentsToUpsert);
                shipmentsToDelete.addAll(shipMapForMov.values());
            }

            if (!shipmentsToUpsert.isEmpty()) processDmlUpsert(Database.upsert(shipmentsToUpsert, false));
            if (!shipmentsToDelete.isEmpty()) processDmlDelete(Database.delete(shipmentsToDelete, false));

            response.movements = wrappers;
            response.isSuccess = true;
            response.message = SUCCESS_SAVE;
        } catch(Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = ERR_SAVE + e.getMessage();
        }
        return response;
    }

    @AuraEnabled
    public static UIResponse finalizeMovements(String jsonData) {
        UIResponse response = new UIResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            List<MovementWrapper> wrappers = (List<MovementWrapper>)JSON.deserialize(jsonData, List<MovementWrapper>.class);
            Set<Id> movementIds = extractMovementIds(wrappers);
            Set<Id> jobIds = extractJobIds(wrappers);

            validateFinalizeAction(jobIds, movementIds, wrappers);

            for (MovementWrapper mw : wrappers) {
                if (String.isNotBlank(mw.movementRecordId)) {
                    lockMovementWrapper(mw, BSF_Constants.STATUS_FINAL);
                }
            }

            if (!movementIds.isEmpty()) {
                DriveMovementService.performFinalizationCore(movementIds, true);
            }

            response.movements = wrappers;
            response.isSuccess = true;
            response.message = SUCCESS_FINALIZE;
        } catch(Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = ERR_FINALIZE + e.getMessage();
        }
        return response;
    }

    @AuraEnabled
    public static UIResponse withdrawMovements(String jsonData) {
        UIResponse response = new UIResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            List<MovementWrapper> wrappers = (List<MovementWrapper>)JSON.deserialize(jsonData, List<MovementWrapper>.class);
            Set<Id> movementIds = extractMovementIds(wrappers);

            for (MovementWrapper mw : wrappers) {
                if (String.isNotBlank(mw.movementRecordId)) {
                    lockMovementWrapper(mw, BSF_Constants.STATUS_CANCELED);
                }
            }

            if (!movementIds.isEmpty()) {
                DriveMovementService.performCancelationCore(movementIds, true);
            }

            response.movements = wrappers;
            response.isSuccess = true;
            response.message = SUCCESS_CANCEL;
        } catch(Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.message = ERR_WITHDRAW + e.getMessage();
        }
        return response;
    }

    private class TmsAssignmentResult {
        TMS_Site_User_Assignment__c defaultTms;
        List<Map<String, String>> assignedList = new List<Map<String, String>>();
    }

    private static TmsAssignmentResult getTmsAssignments() {
        TmsAssignmentResult result = new TmsAssignmentResult();
        for (TMS_Site_User_Assignment__c tms : [SELECT Assigned_TMS_Site__c, Assigned_TMS_Site__r.Name, Is_Default__c FROM TMS_Site_User_Assignment__c WHERE User__c = :UserInfo.getUserId() AND Is_Active__c = true WITH SYSTEM_MODE]) {
            if (tms.Is_Default__c) result.defaultTms = tms;
            result.assignedList.add(new Map<String, String>{ 'label' => tms.Assigned_TMS_Site__r.Name, 'value' => tms.Assigned_TMS_Site__c });
        }
        return result;
    }

    private static MovementWrapper handleNewAction(Id pId, String parentObjType, TmsAssignmentResult tmsData) {
        Id driveIdToQuery = null;
        Id jobIdToLock = null;
        Boolean driveLocked = false;
        Boolean jobLocked = false;

        if (SOBJ_DRIVE.equalsIgnoreCase(parentObjType)) {
            driveIdToQuery = pId; 
            driveLocked = true;
        } else if (SOBJ_JOB.equalsIgnoreCase(parentObjType)) {
            sked_Drive_Delivery_Job__c job = [SELECT sked_Drive__c FROM sked_Drive_Delivery_Job__c WHERE Id = :pId WITH SYSTEM_MODE LIMIT 1];
            driveIdToQuery = job.sked_Drive__c; 
            jobIdToLock = pId; 
            driveLocked = true; 
            jobLocked = true;
        }

        if (driveIdToQuery != null) {
            sked_Drive__c drive = [SELECT Id, Name, sked_Drive_Date__c, sked_UFID__c, sked_Drive_Site__c, sked_Drive_Site__r.Name, sked_Drive_Site__r.sked_City__c, sked_Drive_Site__r.sked_State__c FROM sked_Drive__c WHERE Id = :driveIdToQuery WITH SYSTEM_MODE LIMIT 1];
            List<sked_Drive_Delivery_Job__c> jobs = [SELECT Id, Name, sked_Type__c, sked_Pick_Up_Time__c FROM sked_Drive_Delivery_Job__c WHERE sked_Drive__c = :driveIdToQuery WITH SYSTEM_MODE];
            return buildNewMovementWrapper(drive, formatJobOptions(jobs), tmsData.defaultTms, tmsData.assignedList, driveLocked, jobLocked, jobIdToLock);
        }
        return null;
    }

    private static MovementWrapper handleEditAction(Id rId, String recordObjType, TmsAssignmentResult tmsData) {
        Id movId = SOBJ_SHIPMENT.equalsIgnoreCase(recordObjType) ? [SELECT Drive_Delivery_Movement__c FROM Drive_Delivery_Shipment__c WHERE Id = :rId WITH SYSTEM_MODE LIMIT 1].Drive_Delivery_Movement__c : rId;
        
        Drive_Delivery_Movement__c mov = [SELECT Id, Primary_Drive__c, Primary_Drive__r.Name, Primary_Drive__r.sked_Drive_Date__c, Primary_Drive__r.sked_Drive_Site__c, Primary_Drive__r.sked_Drive_Site__r.Name, Primary_Drive_Delivery_Job__c, Movement_Number__c, Carrier__c, Is_Round_Trip__c, Status__c FROM Drive_Delivery_Movement__c WHERE Id = :movId WITH SYSTEM_MODE LIMIT 1];
        List<Drive_Delivery_Shipment__c> shipments = [SELECT Id, Stop_Sequence_Number__c, Ship_From_Site_Type__c, Ship_From_TMS_Site__c, Ship_From_TMS_Site__r.Name, Ship_From_Blood_Drive_Site__c, Ship_From_Blood_Drive_Site__r.Name, Ship_To_Site_Type__c, Ship_To_TMS_Site__c, Ship_To_TMS_Site__r.Name, Ship_To_Blood_Drive_Site__c, Ship_To_Blood_Drive_Site__r.Name, Pickup_Start_Time__c, Pickup_End_Time__c, Delivery_Start_Time__c, Delivery_End_Time__c FROM Drive_Delivery_Shipment__c WHERE Drive_Delivery_Movement__c = :movId WITH SYSTEM_MODE ORDER BY Stop_Sequence_Number__c ASC];
        List<sked_Drive_Delivery_Job__c> jobs = [SELECT Id, Name, sked_Type__c, sked_Pick_Up_Time__c FROM sked_Drive_Delivery_Job__c WHERE sked_Drive__c = :mov.Primary_Drive__c WITH SYSTEM_MODE];

        return buildEditMovementWrapper(mov, shipments, formatJobOptions(jobs), tmsData.defaultTms, tmsData.assignedList); 
    }

    private static List<Map<String, String>> formatJobOptions(List<sked_Drive_Delivery_Job__c> jobs) {
        List<Map<String, String>> jobOptions = new List<Map<String, String>>();
        for (sked_Drive_Delivery_Job__c job : jobs) {
            String timeStr = String.valueOf(job.sked_Pick_Up_Time__c)?.substringBefore('.') ?? '';
            String pickupTime = String.isNotBlank(timeStr) ? timeStr.left(5) : '';
            jobOptions.add(new Map<String, String>{ 'label' => job.Name + ' - ' + job.sked_Type__c + ' - ' + timeStr, 'value' => job.Id, 'type' => job.sked_Type__c, 'pickupTime' => pickupTime });
        }
        return jobOptions;
    }

    private static MovementWrapper buildNewMovementWrapper(sked_Drive__c drive, List<Map<String, String>> jobOptions, TMS_Site_User_Assignment__c defaultTMS, List<Map<String, String>> assignedTmsList, Boolean dLocked, Boolean jLocked, Id jobIdToLock) {
        MovementWrapper mov = new MovementWrapper();
        mov.id = 'new_mov_0'; 
        mov.status = BSF_Constants.STATUS_DRAFT;
        mov.driveId = drive.Id;
        mov.driveName = drive.Name;
        mov.isReadOnly = false;
        mov.isDriveDisabled = dLocked;
        mov.isJobDisabled = jLocked;
        mov.isRoundTrip = true;
        
        if (defaultTMS != null) {
            mov.defaultTmsSiteId = defaultTMS.Assigned_TMS_Site__c;
            mov.defaultTmsSiteName = defaultTMS.Assigned_TMS_Site__r?.Name;
        }
        mov.assignedTmsSites = assignedTmsList;
        
        if (drive.sked_Drive_Date__c != null) {
            mov.driveDateStr = String.valueOf(drive.sked_Drive_Date__c);
            String dateFmt = DateTime.newInstance(drive.sked_Drive_Date__c.year(), drive.sked_Drive_Date__c.month(), drive.sked_Drive_Date__c.day()).format('MMddyy');
            String city = drive.sked_Drive_Site__r?.sked_City__c ?? '';
            String state = drive.sked_Drive_Site__r?.sked_State__c ?? '';
            String ufid = drive.sked_UFID__c ?? '';
            mov.movementNumber = PREFIX_MOVEMENT + dateFmt + BSF_Constants.UNDERSCORE + ufid + BSF_Constants.UNDERSCORE + city + BSF_Constants.UNDERSCORE + state;
        }
        mov.driveSiteId = drive.sked_Drive_Site__c;
        mov.driveSiteName = drive.sked_Drive_Site__r?.Name;
        mov.jobOptions = jobOptions;
        
        if (jobIdToLock != null) mov.selectedJobId = jobIdToLock; 
        else if (jobOptions.size() == 1) mov.selectedJobId = jobOptions[0].get('value'); 
        
        mov.stops = new List<StopWrapper>();
        for (Integer i = 1; i <= 3; i++) {
            StopWrapper stop = new StopWrapper();
            stop.sequence = i;
            stop.isFirstStop = (i == 1); stop.isSecondStop = (i == 2); stop.isLastStop = (i == 3);
            if (i == 1 || i == 3) {
                stop.siteType = BSF_Constants.TYPE_BLOOD_DRIVE; stop.siteId = drive.sked_Drive_Site__c; stop.siteName = drive.sked_Drive_Site__r?.Name; stop.isSiteDisabled = (i == 3);
            } else {
                stop.siteType = BSF_Constants.TYPE_TMS_SITE; stop.isSiteDisabled = false;
                if (defaultTMS != null) { stop.siteId = defaultTMS.Assigned_TMS_Site__c; stop.siteName = defaultTMS.Assigned_TMS_Site__r?.Name; }
            }
            stop.canAdd = !(stop.isFirstStop || stop.isLastStop); stop.canRemove = !(stop.isFirstStop || stop.isSecondStop || stop.isLastStop);
            mov.stops.add(stop);
        }
        return mov;
    }

    private static MovementWrapper buildEditMovementWrapper(Drive_Delivery_Movement__c movRecord, List<Drive_Delivery_Shipment__c> shipments, List<Map<String, String>> jobOptions, TMS_Site_User_Assignment__c defaultTMS, List<Map<String, String>> assignedTmsList) {
        MovementWrapper mov = new MovementWrapper();
        mov.id = movRecord.Id;
        mov.movementRecordId = movRecord.Id;
        mov.driveId = movRecord.Primary_Drive__c;
        mov.driveName = movRecord.Primary_Drive__r?.Name;
        mov.driveDateStr = String.valueOf(movRecord.Primary_Drive__r?.sked_Drive_Date__c);
        mov.driveSiteId = movRecord.Primary_Drive__r?.sked_Drive_Site__c;
        mov.driveSiteName = movRecord.Primary_Drive__r?.sked_Drive_Site__r?.Name;
        mov.movementNumber = movRecord.Movement_Number__c;
        mov.selectedJobId = movRecord.Primary_Drive_Delivery_Job__c;
        mov.carrier = movRecord.Carrier__c;
        mov.isRoundTrip = movRecord.Is_Round_Trip__c;
        mov.status = movRecord.Status__c;
        mov.isReadOnly = !BSF_Constants.STATUS_DRAFT.equalsIgnoreCase(movRecord.Status__c); 
        mov.isDriveDisabled = true;
        mov.isJobDisabled = mov.isReadOnly;
        mov.isCarrierDisabled = mov.isReadOnly;
        mov.jobOptions = jobOptions;
        
        if (defaultTMS != null) {
            mov.defaultTmsSiteId = defaultTMS.Assigned_TMS_Site__c;
            mov.defaultTmsSiteName = defaultTMS.Assigned_TMS_Site__r?.Name;
        }
        mov.assignedTmsSites = assignedTmsList;
        
        mov.stops = new List<StopWrapper>();
        Integer totalStops = shipments.size() + 1;
        
        for (Integer i = 0; i < totalStops; i++) {
            StopWrapper stop = new StopWrapper();
            stop.sequence = i + 1;
            stop.isFirstStop = (stop.sequence == 1); stop.isSecondStop = (stop.sequence == 2); stop.isLastStop = (stop.sequence == totalStops);

            if (!stop.isLastStop) {
                Drive_Delivery_Shipment__c ship = shipments[i];
                stop.siteType = ship.Ship_From_Site_Type__c;
                stop.siteId = BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(stop.siteType) ? ship.Ship_From_TMS_Site__c : ship.Ship_From_Blood_Drive_Site__c;
                stop.siteName = BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(stop.siteType) ? ship.Ship_From_TMS_Site__r?.Name : ship.Ship_From_Blood_Drive_Site__r?.Name;
                stop.departStartStr = String.valueOf(ship.Pickup_Start_Time__c)?.left(5) ?? '';
                stop.departEndStr = String.valueOf(ship.Pickup_End_Time__c)?.left(5) ?? '';
            }
            if (!stop.isFirstStop) {
                Drive_Delivery_Shipment__c prevShip = shipments[i-1];
                if (stop.isLastStop) {
                    stop.siteType = prevShip.Ship_To_Site_Type__c;
                    stop.siteId = BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(stop.siteType) ? prevShip.Ship_To_TMS_Site__c : prevShip.Ship_To_Blood_Drive_Site__c;
                    stop.siteName = BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(stop.siteType) ? prevShip.Ship_To_TMS_Site__r?.Name : prevShip.Ship_To_Blood_Drive_Site__r?.Name;
                }
                stop.arriveStartStr = String.valueOf(prevShip.Delivery_Start_Time__c)?.left(5) ?? '';
                stop.arriveEndStr = String.valueOf(prevShip.Delivery_End_Time__c)?.left(5) ?? '';
            }

            if (mov.isRoundTrip) {
                stop.isSiteDisabled = stop.isLastStop || stop.isFirstStop || mov.isReadOnly;
                stop.canAdd = !(stop.isFirstStop || stop.isLastStop) && !mov.isReadOnly;
                stop.canRemove = !(stop.isFirstStop || stop.isSecondStop || stop.isLastStop) && !mov.isReadOnly;
            } else {
                stop.isSiteDisabled = stop.isFirstStop || mov.isReadOnly;
                stop.canAdd = !stop.isFirstStop && !mov.isReadOnly;
                stop.canRemove = !(stop.isFirstStop || stop.isSecondStop) && !mov.isReadOnly;
            }
            mov.stops.add(stop);
        }
        return mov;
    }

    private static Time parseTime(String timeStr) {
        if (String.isBlank(timeStr)) return null;
        List<String> parts = timeStr.split(':');
        return (parts.size() >= 2) ? Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0) : null;
    }

    private static void lockMovementWrapper(MovementWrapper mw, String statusVal) {
        mw.status = statusVal;
        mw.isReadOnly = true;
        mw.isDriveDisabled = true;
        mw.isJobDisabled = true;
        mw.isCarrierDisabled = true;
        if (mw.stops != null) {
            for (StopWrapper stop : mw.stops) {
                stop.isSiteDisabled = true;
                stop.canAdd = false;
                stop.canRemove = false;
            }
        }
    }

    private static Set<Id> extractMovementIds(List<MovementWrapper> wrappers) {
        Set<Id> ids = new Set<Id>();
        for (MovementWrapper mw : wrappers) {
            if (String.isNotBlank(mw.movementRecordId)) ids.add(mw.movementRecordId);
        }
        return ids;
    }

    private static Set<Id> extractJobIds(List<MovementWrapper> wrappers) {
        Set<Id> ids = new Set<Id>();
        for (MovementWrapper mw : wrappers) {
            if (String.isNotBlank(mw.selectedJobId)) ids.add(mw.selectedJobId);
        }
        return ids;
    }

    private static List<Drive_Delivery_Movement__c> prepareMovementsForUpsert(List<MovementWrapper> wrappers) {
        List<Drive_Delivery_Movement__c> moves = new List<Drive_Delivery_Movement__c>();
        for (MovementWrapper mw : wrappers) {
            moves.add(new Drive_Delivery_Movement__c(
                Id = String.isNotBlank(mw.movementRecordId) ? mw.movementRecordId : null,
                Primary_Drive__c = mw.driveId,
                Primary_Drive_Delivery_Job__c = mw.selectedJobId,
                Movement_Number__c = mw.movementNumber,
                Carrier__c = mw.carrier,
                Equipment_Type__c = EQUIP_TYPE_CAR,
                Is_Round_Trip__c = mw.isRoundTrip,
                Status__c = String.isNotBlank(mw.status) ? mw.status : BSF_Constants.STATUS_DRAFT
            ));
        }
        return moves;
    }

    private static Map<Id, String> fetchMovementStatuses(Set<Id> existingIds) {
        Map<Id, String> statusMap = new Map<Id, String>();
        if (!existingIds.isEmpty()) {
            for (Drive_Delivery_Movement__c m : [SELECT Id, Status__c FROM Drive_Delivery_Movement__c WHERE Id IN :existingIds WITH SYSTEM_MODE]) {
                statusMap.put(m.Id, m.Status__c);
            }
        }
        return statusMap;
    }

    private static Map<Id, Map<Decimal, Drive_Delivery_Shipment__c>> fetchExistingShipments(Set<Id> existingIds) {
        Map<Id, Map<Decimal, Drive_Delivery_Shipment__c>> exMap = new Map<Id, Map<Decimal, Drive_Delivery_Shipment__c>>();
        if (!existingIds.isEmpty()) {
            for (Drive_Delivery_Shipment__c ship : [SELECT Id, Stop_Sequence_Number__c, Drive_Delivery_Movement__c FROM Drive_Delivery_Shipment__c WHERE Drive_Delivery_Movement__c IN :existingIds WITH SYSTEM_MODE]) {
                if (!exMap.containsKey(ship.Drive_Delivery_Movement__c)) exMap.put(ship.Drive_Delivery_Movement__c, new Map<Decimal, Drive_Delivery_Shipment__c>());
                exMap.get(ship.Drive_Delivery_Movement__c).put(ship.Stop_Sequence_Number__c, ship);
            }
        }
        return exMap;
    }

    private static void processWrapperStops(MovementWrapper mw, String currentStatus, Map<Decimal, Drive_Delivery_Shipment__c> shipMapForMov, List<Drive_Delivery_Shipment__c> shipmentsToUpsert) {
        Date driveDate = Date.valueOf(mw.driveDateStr);
        Integer requiredShipments = mw.stops.size() - 1;
        for (Integer i = 0; i < requiredShipments; i++) {
            StopWrapper fromStop = mw.stops[i]; 
            StopWrapper toStop = mw.stops[i+1]; 
            Decimal seq = fromStop.sequence;

            Drive_Delivery_Shipment__c ship = new Drive_Delivery_Shipment__c();
            if (shipMapForMov.containsKey(seq)) ship.Id = shipMapForMov.get(seq).Id; 
            else ship.Drive_Delivery_Movement__c = mw.movementRecordId;
            
            ship.Drive__c = mw.driveId;
            ship.Drive_Delivery_Job__c = mw.selectedJobId;
            ship.Stop_Sequence_Number__c = seq;
            ship.Shipment_Type__c = BSF_Constants.SHIPMENT_TYPE_UPP;
            ship.Status__c = currentStatus;

            ship.Ship_From_Site_Type__c = fromStop.siteType;
            ship.Ship_From_TMS_Site__c = BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(fromStop.siteType) ? fromStop.siteId : null;
            ship.Ship_From_Blood_Drive_Site__c = !BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(fromStop.siteType) ? fromStop.siteId : null;
            
            ship.Ship_To_Site_Type__c = toStop.siteType;
            ship.Ship_To_TMS_Site__c = BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(toStop.siteType) ? toStop.siteId : null; 
            ship.Ship_To_Blood_Drive_Site__c = !BSF_Constants.TYPE_TMS_SITE.equalsIgnoreCase(toStop.siteType) ? toStop.siteId : null;

            ship.Pickup_Start_Date__c = driveDate; 
            ship.Pickup_End_Date__c = driveDate;
            ship.Pickup_Start_Time__c = parseTime(fromStop.departStartStr);
            ship.Pickup_Start_Datetime__c = ship.Pickup_Start_Time__c != null ? Datetime.newInstance(driveDate, ship.Pickup_Start_Time__c) : null;
            
            ship.Pickup_End_Time__c = parseTime(fromStop.departEndStr);
            ship.Pickup_End_Datetime__c = ship.Pickup_End_Time__c != null ? Datetime.newInstance(driveDate, ship.Pickup_End_Time__c) : null;

            ship.Delivery_Start_Date__c = String.isNotBlank(toStop.arriveStartStr) ? driveDate : null;
            ship.Delivery_Start_Time__c = parseTime(toStop.arriveStartStr);
            ship.Delivery_Start_Datetime__c = ship.Delivery_Start_Time__c != null ? Datetime.newInstance(driveDate, ship.Delivery_Start_Time__c) : null;

            ship.Delivery_End_Date__c = String.isNotBlank(toStop.arriveEndStr) ? driveDate : null; 
            ship.Delivery_End_Time__c = parseTime(toStop.arriveEndStr);
            ship.Delivery_End_Datetime__c = ship.Delivery_End_Time__c != null ? Datetime.newInstance(driveDate, ship.Delivery_End_Time__c) : null;

            shipmentsToUpsert.add(ship);
            shipMapForMov.remove(seq); 
        }
    }

    private static void validateFinalizeAction(Set<Id> jobIds, Set<Id> movementIds, List<MovementWrapper> wrappers) {
        if (!jobIds.isEmpty()) {
            List<Drive_Delivery_Movement__c> existingFinals = [SELECT Id, Primary_Drive_Delivery_Job__r.Name FROM Drive_Delivery_Movement__c WHERE Primary_Drive_Delivery_Job__c IN :jobIds AND Status__c = :BSF_Constants.STATUS_FINAL AND Id NOT IN :movementIds WITH SYSTEM_MODE];
            if (!existingFinals.isEmpty()) {
                throw new MovementException(String.format(ERR_EXISTING_FINAL, new List<String>{existingFinals[0].Primary_Drive_Delivery_Job__r.Name}));
            }
            Set<Id> currentTransactionJobs = new Set<Id>();
            for (MovementWrapper mw : wrappers) {
                if (String.isNotBlank(mw.selectedJobId)) {
                    if (currentTransactionJobs.contains(mw.selectedJobId)) throw new MovementException(ERR_MULTIPLE_FINAL);
                    currentTransactionJobs.add(mw.selectedJobId);
                }
            }
        }
    }

    private static void processDmlUpsert(List<Database.UpsertResult> results) {
        List<String> errors = new List<String>();
        for (Database.UpsertResult res : results) {
            if (!res.isSuccess()) {
                for (Database.Error err : res.getErrors()) errors.add(err.getMessage());
            }
        }
        if (!errors.isEmpty()) throw new MovementException(String.join(errors, '; '));
    }

    private static void processDmlDelete(List<Database.DeleteResult> results) {
        List<String> errors = new List<String>();
        for (Database.DeleteResult res : results) {
            if (!res.isSuccess()) {
                for (Database.Error err : res.getErrors()) errors.add(err.getMessage());
            }
        }
        if (!errors.isEmpty()) throw new MovementException(String.join(errors, '; '));
    }
}