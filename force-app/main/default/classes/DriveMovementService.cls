public without sharing class DriveMovementService {

    // ============================================================================
    // TRIGGER METHODS
    // ============================================================================

    public static void handleDriveChanges(Map<Id, sked_Drive__c> newMap, Map<Id, sked_Drive__c> oldMap) {
        try {
            if (newMap == null || oldMap == null) return;
            Map<Id, Set<String>> driveChanges = new Map<Id, Set<String>>();
            Set<Id> canceledDrives = new Set<Id>();

            for (sked_Drive__c newDrv : newMap.values()) {
                sked_Drive__c oldDrv = oldMap.get(newDrv.Id);
                Set<String> changes = new Set<String>();

                if (newDrv.sked_Status__c == 'Cancel' && oldDrv.sked_Status__c != 'Cancel') canceledDrives.add(newDrv.Id);
                if (newDrv.sked_Drive_Date__c != oldDrv.sked_Drive_Date__c) changes.add('DATE');
                if (newDrv.sked_Start_Time__c != oldDrv.sked_Start_Time__c || newDrv.sked_End_Time__c != oldDrv.sked_End_Time__c) changes.add('TIME');
                if (newDrv.sked_Drive_Site__c != oldDrv.sked_Drive_Site__c) changes.add('SITE');
                
                if (!changes.isEmpty()) driveChanges.put(newDrv.Id, changes);
            }

            if (!canceledDrives.isEmpty()) processTriggerCancellation(canceledDrives, 'Primary_Drive__c', 'DRIVE_CANCELED_ANY');
            if (!driveChanges.isEmpty()) processFieldChanges(driveChanges, 'DRIVE', newMap, oldMap);
        } catch (Exception ex) {
            logException(ex, 'handleDriveChanges');
        }
    }

    public static void handleJobChanges(Map<Id, sked_Drive_Delivery_Job__c> newMap, Map<Id, sked_Drive_Delivery_Job__c> oldMap) {
        try {
            if (newMap == null && oldMap != null) {
                processTriggerCancellation(oldMap.keySet(), 'Primary_Drive_Delivery_Job__c', 'JOB_DELETED_ANY');
                return;
            }

            Map<Id, Set<String>> jobChanges = new Map<Id, Set<String>>();
            for (sked_Drive_Delivery_Job__c newJob : newMap.values()) {
                sked_Drive_Delivery_Job__c oldJob = oldMap.get(newJob.Id);
                if (newJob.sked_Type__c != oldJob.sked_Type__c || newJob.sked_Pick_Up_Time__c != oldJob.sked_Pick_Up_Time__c) {
                    jobChanges.put(newJob.Id, new Set<String>{'JOB'});
                }
            }
            if (!jobChanges.isEmpty()) processFieldChanges(jobChanges, 'JOB', newMap, oldMap);
        } catch (Exception ex) {
            logException(ex, 'handleJobChanges');
        }
    }

    public static void handleLocationChanges(Map<Id, sked__Location__c> newMap, Map<Id, sked__Location__c> oldMap) {
        try {
            if (newMap == null || oldMap == null) return;
            Map<Id, Set<String>> locationChanges = new Map<Id, Set<String>>();

            for (sked__Location__c newLoc : newMap.values()) {
                sked__Location__c oldLoc = oldMap.get(newLoc.Id);
                
                if (newLoc.sked_Address_1__c != oldLoc.sked_Address_1__c ||
                    newLoc.sked_Address_2__c != oldLoc.sked_Address_2__c ||
                    newLoc.sked_City__c      != oldLoc.sked_City__c ||
                    newLoc.sked_County__c    != oldLoc.sked_County__c ||
                    newLoc.sked_State__c     != oldLoc.sked_State__c ||
                    newLoc.sked_Zip_Code__c  != oldLoc.sked_Zip_Code__c) {
                    
                    locationChanges.put(newLoc.Id, new Set<String>{'ADDRESS'});
                }
            }

            if (!locationChanges.isEmpty()) {
                processFieldChanges(locationChanges, 'LOCATION', newMap, oldMap);
            }
        } catch (Exception ex) {
            logException(ex, 'handleLocationChanges');
        }
    }

    // ============================================================================
    // CORE METHODS & NOTIFICATION PROCESSORS
    // ============================================================================

    public static void performFinalizationCore(Set<Id> movementIds, Boolean isFromUI) {
        try {
            List<Drive_Delivery_Movement__c> movesToUpd = new List<Drive_Delivery_Movement__c>();
            List<Drive_Delivery_Shipment__c> shipsToUpd = new List<Drive_Delivery_Shipment__c>();
            List<Delivery_Shipment_Integration__c> intgsToIns = new List<Delivery_Shipment_Integration__c>();
            List<Shipment_Transmission_Request__e> evtsToPub = new List<Shipment_Transmission_Request__e>();
            
            Drive_Delivery_Shipment_Config__mdt config = getShipmentConfig();

            for(Id mId : movementIds) {
                movesToUpd.add(new Drive_Delivery_Movement__c(Id = mId, Status__c = BSF_Constants.STATUS_FINAL));
                evtsToPub.add(new Shipment_Transmission_Request__e(Movement_Id__c = mId, Action_Type__c = BSF_Constants.INTEG_ACTION_CREATE));
            }

            Integer counter = 1;
            for (Drive_Delivery_Shipment__c ship : fetchShipmentsForIntegration(movementIds)) {
                ship.Status__c = BSF_Constants.STATUS_FINAL;
                String ufid = String.isNotBlank(ship.Drive_Delivery_Movement__r?.Primary_Drive__r?.sked_UFID__c) ? ship.Drive_Delivery_Movement__r.Primary_Drive__r.sked_UFID__c : BSF_Constants.NOUFID_DEFAULT;
                ship.Shipment_Number__c = ufid + BSF_Constants.UNDERSCORE + ship.Drive_Delivery_Movement__r?.Name + BSF_Constants.UNDERSCORE + Integer.valueOf(ship.Stop_Sequence_Number__c);
                shipsToUpd.add(ship);
                
                intgsToIns.add(buildIntegrationRecord(ship, config, BSF_Constants.INTEG_ACTION_CREATE, ship.Shipment_Number__c, counter++));
            }

            executeFinalizeOrWithdrawDmls(movesToUpd, shipsToUpd, new List<Delivery_Shipment_Integration__c>(), intgsToIns, evtsToPub, 'performFinalizationCore', isFromUI);
        } catch (Exception ex) {
            if (isFromUI) throw ex;
            logException(ex, 'performFinalizationCore');
        }
    }

    public static void performCancelationCore(Set<Id> movementIds, Boolean isFromUI) {
        try {
            List<Drive_Delivery_Movement__c> movementsToUpdate = new List<Drive_Delivery_Movement__c>();
            List<Drive_Delivery_Shipment__c> shipmentsToUpdate = new List<Drive_Delivery_Shipment__c>();
            List<Delivery_Shipment_Integration__c> integrationsToUpdate = new List<Delivery_Shipment_Integration__c>();
            List<Delivery_Shipment_Integration__c> integrationsToInsert = new List<Delivery_Shipment_Integration__c>();
            List<Shipment_Transmission_Request__e> eventsToPublish = new List<Shipment_Transmission_Request__e>();

            for (Id mId : movementIds) {
                movementsToUpdate.add(new Drive_Delivery_Movement__c(Id = mId, Status__c = BSF_Constants.STATUS_CANCELED));
            }

            for (Drive_Delivery_Shipment__c ship : [SELECT Id FROM Drive_Delivery_Shipment__c WHERE Drive_Delivery_Movement__c IN :movementIds WITH SYSTEM_MODE]) {
                ship.Status__c = BSF_Constants.STATUS_CANCELED; 
                shipmentsToUpdate.add(ship);
            }

            Drive_Delivery_Shipment_Config__mdt config = getShipmentConfig();
            Set<Id> movementsNeedingDeleteEvent = new Set<Id>();

            List<String> integrationStatuses = new List<String>{BSF_Constants.STATUS_IN_PROCESS, BSF_Constants.STATUS_SUCCESS};
            Integer counter = 1;
            for (Delivery_Shipment_Integration__c dsi : fetchActiveIntegrations(movementIds)) {
                if (integrationStatuses.contains(dsi.Status__c)) {
                    movementsNeedingDeleteEvent.add(dsi.Drive_Delivery_Movement__c);
                    Delivery_Shipment_Integration__c deleteRec = generateTransmissionId(dsi.Drive_Delivery_Movement__r?.Owner?.LastName, dsi.Drive_Delivery_Movement__r?.Owner?.FirstName, 
                                                                                        dsi.Drive_Delivery_Movement__r?.Name, dsi.clone(false, false, false, false), counter++);
                    deleteRec.Action_Type__c = BSF_Constants.INTEG_ACTION_DELETE;
                    deleteRec.Status__c = BSF_Constants.STATUS_IN_PROCESS;
                    integrationsToInsert.add(deleteRec);
                }
                dsi.Status__c = BSF_Constants.STATUS_CANCELED;
                integrationsToUpdate.add(dsi);
            }

            for (Id movId : movementsNeedingDeleteEvent) {
                eventsToPublish.add(new Shipment_Transmission_Request__e(Action_Type__c = BSF_Constants.INTEG_ACTION_DELETE, Movement_Id__c = movId));
            }

            executeFinalizeOrWithdrawDmls(movementsToUpdate, shipmentsToUpdate, integrationsToUpdate, integrationsToInsert, eventsToPublish, 'performCancelationCore', isFromUI);
        } catch (Exception ex) {
            if (isFromUI) throw ex;
            logException(ex, 'performCancelationCore');
        }
    }

    private static void processTriggerCancellation(Set<Id> parentIds, String parentField, String mapKey) {
        String query = 'SELECT Id, Status__c, OwnerId FROM Drive_Delivery_Movement__c WHERE Status__c != \'' + BSF_Constants.STATUS_CANCELED + '\' AND ' + parentField + ' IN :parentIds';
        List<Drive_Delivery_Movement__c> movs = Database.query(query);
        if (movs.isEmpty()) return;
        
        Set<Id> movIds = new Map<Id, Drive_Delivery_Movement__c>(movs).keySet();
        
        performCancelationCore(movIds, false);
        dispatchNotifications(movs, resolveNotificationName(mapKey));
    }

    private static void processFieldChanges(Map<Id, Set<String>> changedIds, String contextType, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        Set<Id> ids = changedIds.keySet();
        Set<String> queryFields = new Set<String>{'Id'};
        for(Schema.FieldSetMember fsm : SObjectType.Drive_Delivery_Movement__c.FieldSets.Movement_Notification_Fields.getFields()) {
            queryFields.add(fsm.getFieldPath());
        }
        String query = 'SELECT ' + String.join(new List<String>(queryFields), ', ') ;
        if (contextType == 'LOCATION'){
            Set<String> shipmentQueryFields = new Set<String>{'Id'};
            for(Schema.FieldSetMember sfsm : SObjectType.Drive_Delivery_Shipment__c.FieldSets.Shipment_Notification_Fields.getFields()) {
                shipmentQueryFields.add(sfsm.getFieldPath());
            }
            query += ', (SELECT ' + String.join(new List<String>(shipmentQueryFields), ', ') + ' FROM Drive_Delivery_Shipments__r)';
        }
        query += ' FROM Drive_Delivery_Movement__c WHERE Status__c != \'' + BSF_Constants.STATUS_CANCELED + '\' AND ';
        if (contextType == 'DRIVE'){
            query += 'Primary_Drive__c IN :ids';
        }else if (contextType == 'JOB'){
            query += 'Primary_Drive_Delivery_Job__c IN :ids';
        }else if (contextType == 'LOCATION'){
            query += 'Id IN (SELECT Drive_Delivery_Movement__c FROM Drive_Delivery_Shipment__c WHERE Ship_To_Blood_Drive_Site__c IN :ids OR Ship_From_Blood_Drive_Site__c IN :ids OR Drive__r.sked_Drive_Site__c IN :ids)';
        }
        Map<String, List<SObject>> notificationMap = new Map<String, List<SObject>>();
        List<Drive_Delivery_Movement__c> movementsToUpdate = new List<Drive_Delivery_Movement__c>();
        Set<Id> draftMovIdsForShipments = new Set<Id>();

        for (Drive_Delivery_Movement__c mov : Database.query(query)) {
            Set<Id> parentIds = new Set<Id>();
            Map<Id, List<SObject>> relatedRecords = new Map<Id, List<SObject>>();
            String relatedKey = '';
            if (contextType == 'DRIVE' && changedIds.containsKey(mov.Primary_Drive__c)){
                parentIds.add(mov.Primary_Drive__c);
            }else if (contextType == 'JOB' && changedIds.containsKey(mov.Primary_Drive_Delivery_Job__c)){
                parentIds.add(mov.Primary_Drive_Delivery_Job__c);
            }else if (contextType == 'LOCATION'){
                if (mov.Primary_Drive__r?.sked_Drive_Site__c != null && changedIds.containsKey(mov.Primary_Drive__r.sked_Drive_Site__c)) {
                    parentIds.add(mov.Primary_Drive__r.sked_Drive_Site__c);
                }else if (mov.Drive_Delivery_Shipments__r != null) {
                    for (Drive_Delivery_Shipment__c ship : mov.Drive_Delivery_Shipments__r) {
                        if (ship.Ship_From_Blood_Drive_Site__c != null && changedIds.containsKey(ship.Ship_From_Blood_Drive_Site__c)){
                            parentIds.add(ship.Ship_From_Blood_Drive_Site__c);
                            if(!relatedRecords.containsKey(ship.Ship_From_Blood_Drive_Site__c)) relatedRecords.put(ship.Ship_From_Blood_Drive_Site__c,new List<SObject>());
                            relatedRecords.get(ship.Ship_From_Blood_Drive_Site__c).add(ship);
                            relatedKey = 'FROM_';
                            break;
                        }else if (ship.Ship_To_Blood_Drive_Site__c != null && changedIds.containsKey(ship.Ship_To_Blood_Drive_Site__c)){
                            parentIds.add(ship.Ship_To_Blood_Drive_Site__c);
                            if(!relatedRecords.containsKey(ship.Ship_To_Blood_Drive_Site__c)) relatedRecords.put(ship.Ship_To_Blood_Drive_Site__c,new List<SObject>());
                            relatedRecords.get(ship.Ship_To_Blood_Drive_Site__c).add(ship);
                            relatedKey = 'TO_';
                            break;
                        }
                    }
                }
            }
            String statusUpper = mov.Status__c.toUpperCase();
            Boolean requiresUpdate = false;

            for (Id parentId : parentIds) {
                if (!changedIds.containsKey(parentId)) continue;

                for (String changeType : changedIds.get(parentId)) {
                    String resolveKey = relatedKey + contextType + '_' + changeType + '_' + statusUpper;
                    String notifName = resolveNotificationName(resolveKey);
                    
                    if (String.isNotBlank(notifName)) {
                        if (!notificationMap.containsKey(notifName)){notificationMap.put(notifName, new List<SObject>());}
                        if (relatedRecords.containsKey(parentId)){
                            notificationMap.get(notifName).addAll(relatedRecords.get(parentId));
                        }else{notificationMap.get(notifName).add(mov);}
                    }
                    
                    if (mov.Status__c == BSF_Constants.STATUS_DRAFT) {
                        draftMovIdsForShipments.add(mov.Id); 
                        if (contextType == 'JOB') {
                            sked_Drive_Delivery_Job__c newJob = (sked_Drive_Delivery_Job__c)newMap.get(parentId);
                            String type = newJob.sked_Type__c;
                            mov.Carrier__c = (type == 'Pick Up') ? 'Redcross Employee' : (type == 'VOL Pick Up' ? 'Volunteer' : mov.Carrier__c);
                            requiresUpdate = true;
                        }
                    }
                }
            }
            if (requiresUpdate) movementsToUpdate.add(mov);
        }

        if (!movementsToUpdate.isEmpty()) {
            processDmlUpdate(Database.update(movementsToUpdate, false), 'processFieldChanges');
        }

        if (!draftMovIdsForShipments.isEmpty() && contextType == 'DRIVE') {
            updateDraftShipments(draftMovIdsForShipments, changedIds, newMap, oldMap);
        }

        for (String notifKey : notificationMap.keySet()) {
            dispatchNotifications(notificationMap.get(notifKey), notifKey);
        }
    }

    private static void updateDraftShipments(Set<Id> movIds, Map<Id, Set<String>> changedIds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        List<Drive_Delivery_Shipment__c> shipments = [SELECT Id, Drive_Delivery_Movement__c, Drive_Delivery_Movement__r.Primary_Drive__c, Pickup_Start_Date__c, Pickup_End_Date__c, Delivery_Start_Date__c, Delivery_End_Date__c, Pickup_Start_Time__c, Pickup_End_Time__c, Delivery_Start_Time__c, Delivery_End_Time__c, Ship_From_Blood_Drive_Site__c, Ship_To_Blood_Drive_Site__c FROM Drive_Delivery_Shipment__c WHERE Drive_Delivery_Movement__c IN :movIds];
        List<Drive_Delivery_Shipment__c> shipmentsToUpdate = new List<Drive_Delivery_Shipment__c>();

        for (Drive_Delivery_Shipment__c ship : shipments) {
            Id driveId = ship.Drive_Delivery_Movement__r.Primary_Drive__c;
            Set<String> changes = changedIds.get(driveId);
            Boolean isUpdated = false;

            sked_Drive__c newDrive = (sked_Drive__c)newMap.get(driveId);
            sked_Drive__c oldDrive = (sked_Drive__c)oldMap.get(driveId);

            if (changes.contains('DATE')) {
                Date d = newDrive.sked_Drive_Date__c;
                if (ship.Pickup_Start_Date__c != null) ship.Pickup_Start_Date__c = d;
                if (ship.Pickup_End_Date__c != null) ship.Pickup_End_Date__c = d;
                if (ship.Delivery_Start_Date__c != null) ship.Delivery_Start_Date__c = d;
                if (ship.Delivery_End_Date__c != null) ship.Delivery_End_Date__c = d;

                if (ship.Pickup_Start_Time__c != null) ship.Pickup_Start_Datetime__c = Datetime.newInstance(d, ship.Pickup_Start_Time__c);
                if (ship.Pickup_End_Time__c != null) ship.Pickup_End_Datetime__c = Datetime.newInstance(d, ship.Pickup_End_Time__c);
                if (ship.Delivery_Start_Time__c != null) ship.Delivery_Start_Datetime__c = Datetime.newInstance(d, ship.Delivery_Start_Time__c);
                if (ship.Delivery_End_Time__c != null) ship.Delivery_End_Datetime__c = Datetime.newInstance(d, ship.Delivery_End_Time__c);
                isUpdated = true;
            }
            if (changes.contains('SITE')) {
                Id oldSite = oldDrive.sked_Drive_Site__c;
                Id newSite = newDrive.sked_Drive_Site__c;
                if (ship.Ship_From_Blood_Drive_Site__c == oldSite) { 
                    ship.Ship_From_Blood_Drive_Site__c = newSite; 
                    isUpdated = true; 
                }
                if (ship.Ship_To_Blood_Drive_Site__c == oldSite) { 
                    ship.Ship_To_Blood_Drive_Site__c = newSite; 
                    isUpdated = true; 
                }
            }
            if (isUpdated) shipmentsToUpdate.add(ship);
        }

        if (!shipmentsToUpdate.isEmpty()) {
            processDmlUpdate(Database.update(shipmentsToUpdate, false), 'updateDraftShipments');
        }
    }

    private static String resolveNotificationName(String keyContext) {
        Map<String, String> notifMap = new Map<String, String>{
            'DRIVE_CANCELED_ANY'                => BSF_Constants.NOTIFY_DRIVE_CANCELED,
            'JOB_DELETED_ANY'                   => BSF_Constants.NOTIFY_JOB_DELETED,
            'DRIVE_DATE_FINAL'                  => BSF_Constants.NOTIFY_DRIVE_DATE_FINAL,
            'DRIVE_DATE_DRAFT'                  => BSF_Constants.NOTIFY_DRIVE_DATE_DRAFT,
            'DRIVE_TIME_FINAL'                  => BSF_Constants.NOTIFY_DRIVE_TIME_FINAL,
            'DRIVE_TIME_DRAFT'                  => BSF_Constants.NOTIFY_DRIVE_TIME_DRAFT,
            'DRIVE_SITE_FINAL'                  => BSF_Constants.NOTIFY_SITE_CHANGE_FINAL,
            'DRIVE_SITE_DRAFT'                  => BSF_Constants.NOTIFY_SITE_CHANGE_DRAFT,
            'JOB_JOB_FINAL'                     => BSF_Constants.NOTIFY_JOB_CHANGE_FINAL,
            'JOB_JOB_DRAFT'                     => BSF_Constants.NOTIFY_JOB_CHANGE_DRAFT,
            'LOCATION_ADDRESS_DRAFT'            => BSF_Constants.NOTIFY_SITE_ADDRESS_DRAFT,
            'LOCATION_ADDRESS_FINAL'            => BSF_Constants.NOTIFY_SITE_ADDRESS_FINAL,
            'FROM_LOCATION_ADDRESS_DRAFT'       => BSF_Constants.NOTIFY_FROM_SITE_ADDRESS_DRAFT,
            'FROM_LOCATION_ADDRESS_FINAL'       => BSF_Constants.NOTIFY_FROM_SITE_ADDRESS_FINAL,
            'TO_LOCATION_ADDRESS_DRAFT'         => BSF_Constants.NOTIFY_TO_SITE_ADDRESS_DRAFT,
            'TO_LOCATION_ADDRESS_FINAL'         => BSF_Constants.NOTIFY_TO_SITE_ADDRESS_FINAL
        };
        return notifMap.get(keyContext);
    }

    private static void dispatchNotifications(List<SObject> records, String notificationKeys) {
        if (records != null && !records.isEmpty() && String.isNotBlank(notificationKeys)) {
            for(String devName : notificationKeys.split(',')){
                new skedCustomNotificationService(new List<String>{ devName.trim() }).generateNotifications(records);
            }
        }
    }

    private static void executeFinalizeOrWithdrawDmls(List<Drive_Delivery_Movement__c> movesToUpd, List<Drive_Delivery_Shipment__c> shipsToUpd, List<Delivery_Shipment_Integration__c> intgsToUpd, List<Delivery_Shipment_Integration__c> intgsToIns, List<Shipment_Transmission_Request__e> evtsToPub, String methodName, Boolean isFromUI) {
        
        if (isFromUI) {
            if (!movesToUpd.isEmpty()) Database.update(movesToUpd, true); 
            if (!shipsToUpd.isEmpty()) Database.update(shipsToUpd, true); 
            if (!intgsToUpd.isEmpty()) Database.update(intgsToUpd, true); 
            if (!intgsToIns.isEmpty()) Database.insert(intgsToIns, true); 
            
            if (!evtsToPub.isEmpty()) {
                List<Database.SaveResult> publishResults = EventBus.publish(evtsToPub);
                for (Database.SaveResult sr : publishResults) {
                    if (!sr.isSuccess()) {
                        throw new DmlException('Failed to publish event: ' + sr.getErrors()[0].getMessage());
                    }
                }
            }
        } else {
            if (!movesToUpd.isEmpty()) processDmlUpdate(Database.update(movesToUpd, false), methodName); 
            if (!shipsToUpd.isEmpty()) processDmlUpdate(Database.update(shipsToUpd, false), methodName); 
            if (!intgsToUpd.isEmpty()) processDmlUpdate(Database.update(intgsToUpd, false), methodName); 
            if (!intgsToIns.isEmpty()) processDmlInsert(Database.insert(intgsToIns, false), methodName); 
            if (!evtsToPub.isEmpty()) processDmlInsert(EventBus.publish(evtsToPub), methodName);
        }
    }
    
    private static void processDmlUpsert(List<Database.UpsertResult> results, String methodName) { 
        List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
            results, 'Drive Movement DML Process', 'DriveMovementService', methodName, 'DML Upsert', 'Failed to upsert record(s)'
        );
        if (errorLogs != null && !errorLogs.isEmpty()) Database.insert(errorLogs, false);
    } 
    
    private static void processDmlUpdate(List<Database.SaveResult> results, String methodName) { 
        List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
            results, 'Drive Movement DML Process', 'DriveMovementService', methodName, 'DML Update', 'Failed to update record(s)'
        );
        if (errorLogs != null && !errorLogs.isEmpty()) Database.insert(errorLogs, false);
    } 
    
    private static void processDmlInsert(List<Database.SaveResult> results, String methodName) { 
        List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
            results, 'Drive Movement DML Process', 'DriveMovementService', methodName, 'DML Insert / Publish', 'Failed to insert/publish record(s)'
        );
        if (errorLogs != null && !errorLogs.isEmpty()) Database.insert(errorLogs, false);
    } 
    
    private static void processDmlDelete(List<Database.DeleteResult> results, String methodName) { 
        List<BSF_Error_Log__c> errorLogs = BSF_Utilities.createErrorLog(
            results, 'Drive Movement DML Process', 'DriveMovementService', methodName, 'DML Delete', 'Failed to delete record(s)'
        );
        if (errorLogs != null && !errorLogs.isEmpty()) Database.insert(errorLogs, false);
    } 

    private static void logException(Exception e, String methodName) {
        BSF_Error_Log__c log = BSF_Utilities.getErrorLog(
            'Drive Movement Process', 'DriveMovementService', methodName, 'Exception', 
            e.getTypeName(), e.getMessage() + '\n' + e.getStackTraceString()
        );
        Database.insert(log, false);
    }
    
    private static Drive_Delivery_Shipment_Config__mdt getShipmentConfig() { 
        return [SELECT DeveloperName,
                        Active__c,
                        Arrive_End_Time_Offset__c,
                        Content_Type__c,
                        Depart_End_Time_Offset__c,
                        Enterprise_Name__c,
                        Freight_Controlled_By_System__c,
                        Freight_Terms__c,
                        Inbound_Interface__c,
                        Inbound_Interface_Version__c,
                        Item_Description__c,
                        Load_Type__c,
                        Non_Catalogued_Item_Name__c,
                        Organization_Name__c,
                        Prepopulate_Arrive_End_Time__c,
                        Prepopulate_Depart_End_Time__c,
                        Quantity_Unit_Of_Measure__c,
                        Queue_Name__c,
                        Retry_Threshold__c,
                        Sender__c,
                        Service_Level__c,
                        Shipment_Line_Number__c,
                        Shipment_Line_Qty_UOM__c
                FROM Drive_Delivery_Shipment_Config__mdt
                WHERE Active__c = true WITH SYSTEM_MODE LIMIT 1];
    }
    private static List<Drive_Delivery_Shipment__c> fetchShipmentsForIntegration(Set<Id> movementIds) { 
        return [SELECT Id,
                    Delivery_End_Date__c,
                    Delivery_End_Datetime__c,
                    Delivery_End_Time__c,
                    Delivery_Start_Date__c,
                    Delivery_Start_Datetime__c,
                    Delivery_Start_Time__c,
                    Drive__c,
                    Drive__r.sked_Drive_Site__c,
                    Drive__r.sked_Drive_Site__r.TMS_Site__c,
                    Drive__r.sked_Drive_Site__r.TMS_Site__r.Name,
                    Drive__r.sked_Drive_Site__r.sked_Address_1__c,
                    Drive__r.sked_Drive_Site__r.sked_City__c,
                    Drive__r.sked_Drive_Site__r.sked_State__c,
                    Drive__r.sked_Drive_Site__r.sked_Zip_Code__c,
                    Drive_Delivery_Job__c,
                    Drive_Delivery_Movement__c,
                    Drive_Delivery_Movement__r.Movement_Number__c,
                    Drive_Delivery_Movement__r.Equipment_Type__c,
                    Drive_Delivery_Movement__r.Owner.LastName,
                    Drive_Delivery_Movement__r.Owner.FirstName,
                    Drive_Delivery_Movement__r.Name,
                    Drive_Delivery_Movement__r.Primary_Drive__c,
                    Drive_Delivery_Movement__r.Primary_Drive__r.sked_UFID__c,
                    Name,
                    Pickup_End_Date__c,
                    Pickup_End_Datetime__c,
                    Pickup_End_Time__c,
                    Pickup_Start_Date__c,
                    Pickup_Start_Datetime__c,
                    Pickup_Start_Time__c,
                    Ship_From_Blood_Drive_Site__c,
                    Ship_From_Blood_Drive_Site__r.Name,
                    Ship_From_Blood_Drive_Site__r.sked_Address_1__c,
                    Ship_From_Blood_Drive_Site__r.sked_City__c,
                    Ship_From_Blood_Drive_Site__r.sked_State__c,
                    Ship_From_Blood_Drive_Site__r.sked_Zip_Code__c,
                    Ship_From_Site_Name__c,
                    Ship_From_Site_Type__c,
                    Ship_From_TMS_Site__c,
                    Ship_From_TMS_Site__r.Name,
                    Ship_To_Blood_Drive_Site__c,
                    Ship_To_Blood_Drive_Site__r.Name,
                    Ship_To_Blood_Drive_Site__r.sked_Address_1__c,
                    Ship_To_Blood_Drive_Site__r.sked_City__c,
                    Ship_To_Blood_Drive_Site__r.sked_State__c,
                    Ship_To_Blood_Drive_Site__r.sked_Zip_Code__c,
                    Ship_To_Site_Name__c,
                    Ship_To_Site_Type__c,
                    Ship_To_TMS_Site__c,
                    Ship_To_TMS_Site__r.Name,
                    Shipment_Number__c,
                    Shipment_Type__c,
                    Status__c,
                    Stop_Sequence_Number__c
                FROM Drive_Delivery_Shipment__c
                WHERE Drive_Delivery_Movement__c IN :movementIds WITH SYSTEM_MODE];
    }
    private static List<Delivery_Shipment_Integration__c> fetchActiveIntegrations(Set<Id> movementIds) {
        return [SELECT Id,
                        Action_Type__c,
                        CarrierPartnerName__c,
                        CarrierPartnerProfileName__c,
                        ClientFileName__c,
                        Content_Type__c,
                        CreationEnterpriseName__c,
                        CreationOrganizationName__c,
                        CurrentCarrierEnterpriseName__c,
                        CurrentCarrierOrganizationName__c,
                        CustomerOrderRef__c,
                        Debug_Log__c,
                        Name,
                        DeliveryDateRangeEnd__c,
                        DeliveryDateRangeStart__c,
                        Drive_Delivery_Movement__c,
                        Drive_Delivery_Movement__r.Name,
                        Drive_Delivery_Movement__r.OwnerId,
                        Drive_Delivery_Movement__r.Owner.FirstName,
                        Drive_Delivery_Movement__r.Owner.LastName,
                        Drive_Delivery_Shipment__c,
                        EquipmentType__c,
                        FreightControlledBySystem__c,
                        FreightTerms__c,
                        InboundInterface__c,
                        InboundInterfaceVersion__c,
                        InboundQueueEnterpriseName__c,
                        ItemDescription__c,
                        ItemName__c,
                        LoadType__c,
                        Movement_Number__c,
                        NonCataloguedItemName__c,
                        OrderRefNumber__c,
                        Pickup_Instructions__c,
                        PickupDateRangeEnd__c,
                        PickupDateRangeStart__c,
                        QuantityUnitOfMeasure__c,
                        QueueName__c,
                        Retry_Count__c,
                        Sender__c,
                        ServiceLevel__c,
                        ShipFromEnterpriseName__c,
                        ShipFromOrganizationName__c,
                        ShipFromPartnerSiteAlias__c,
                        ShipFromSiteName__c,
                        ShipmentLine_QuantityUnitOfMeasure2__c,
                        ShipmentLineNumber__c,
                        ShipmentNumber__c,
                        ShipmentType__c,
                        ShippedQuantity__c,
                        ShipToEnterpriseName__c,
                        ShipToOrganizationName__c,
                        ShipToPartnerSiteAlias__c,
                        ShipToSiteName__c,
                        Size__c,
                        Special_Instructions__c,
                        Status__c,
                        TempShipFromCity__c,
                        TempShipFromCountry__c,
                        TempShipFromEnterpriseName__c,
                        TempShipFromOrganizationName__c,
                        TempShipFromPostalCode__c,
                        TempShipFromSiteName__c,
                        TempShipFromState__c,
                        TempShipFromStreet1__c,
                        TempShipFromStreet2__c,
                        TempShipToCity__c,
                        TempShipToCountry__c,
                        TempShipToEnterpriseName__c,
                        TempShipToOrganizationName__c,
                        TempShipToPostalCode__c,
                        TempShipToSiteName__c,
                        TempShipToState__c,
                        TempShipToStreet1__c,
                        TempShipToStreet2__c,
                        Transmission_Date__c,
                        TransmissionId__c
                    FROM Delivery_Shipment_Integration__c 
                    WHERE Drive_Delivery_Movement__c IN :movementIds 
                    AND Action_Type__c = :BSF_Constants.INTEG_ACTION_CREATE 
                    WITH SYSTEM_MODE]; 
    }
    private static Delivery_Shipment_Integration__c buildIntegrationRecord(Drive_Delivery_Shipment__c ship, Drive_Delivery_Shipment_Config__mdt config, String actionType, String shipmentNumberOverride, Integer i) {
        Delivery_Shipment_Integration__c intRec = new Delivery_Shipment_Integration__c();

        intRec.Action_Type__c = actionType;
        intRec.Status__c = BSF_Constants.STATUS_IN_PROCESS; 
        intRec.Drive_Delivery_Shipment__c = ship.Id;
        intRec.Drive_Delivery_Movement__c = ship.Drive_Delivery_Movement__c;
                

        intRec.ShipmentNumber__c = String.isNotBlank(shipmentNumberOverride) ? shipmentNumberOverride : ship.Shipment_Number__c;
        intRec.CreationEnterpriseName__c = config.Enterprise_Name__c;
        intRec.CreationOrganizationName__c = config.Organization_Name__c;
        intRec.ShipFromEnterpriseName__c = config.Enterprise_Name__c;
        intRec.ShipFromOrganizationName__c = config.Organization_Name__c;

        Boolean isShipFromTMS = ship.Ship_From_Site_Type__c == BSF_Constants.TYPE_TMS_SITE;
        Boolean isShipFromBloodDriveWithTMS = ship.Ship_From_Site_Type__c == BSF_Constants.TYPE_BLOOD_DRIVE 
                                        && ship.Drive__r?.sked_Drive_Site__r?.TMS_Site__c != null;
        
        if (isShipFromTMS || isShipFromBloodDriveWithTMS) {
            intRec.ShipFromSiteName__c = ship.Ship_From_TMS_Site__r?.Name;
        }

        intRec.ShipFromPartnerSiteAlias__c = null;

        Boolean isShipFromBloodDriveWithoutTMS = ship.Ship_From_Site_Type__c == BSF_Constants.TYPE_BLOOD_DRIVE 
                                            && ship.Drive__r?.sked_Drive_Site__r?.TMS_Site__c == null;
        
        if (isShipFromBloodDriveWithoutTMS) {
            intRec.TempShipFromEnterpriseName__c = config.Enterprise_Name__c;
            intRec.TempShipFromOrganizationName__c = config.Organization_Name__c;
            intRec.TempShipFromSiteName__c = ship.Ship_From_Blood_Drive_Site__r?.Name;
            intRec.TempShipFromCountry__c = BSF_Constants.COUNTRY_US;
            intRec.TempShipFromState__c = ship.Ship_From_Blood_Drive_Site__r?.sked_State__c;
            intRec.TempShipFromCity__c = ship.Ship_From_Blood_Drive_Site__r?.sked_City__c;
            intRec.TempShipFromPostalCode__c = ship.Ship_From_Blood_Drive_Site__r?.sked_Zip_Code__c;
            intRec.TempShipFromStreet1__c = ship.Ship_From_Blood_Drive_Site__r?.sked_Address_1__c;
        }
        intRec.TempShipFromStreet2__c = null;

        intRec.ShipToEnterpriseName__c = config.Enterprise_Name__c;
        intRec.ShipToOrganizationName__c = config.Organization_Name__c;

        Boolean isShipToTMS = ship.Ship_To_Site_Type__c == BSF_Constants.TYPE_TMS_SITE;
        Boolean isShipToBloodDriveWithTMS = ship.Ship_To_Site_Type__c == BSF_Constants.TYPE_BLOOD_DRIVE 
                                        && ship.Drive__r?.sked_Drive_Site__r?.TMS_Site__c != null;
        
        if (isShipToTMS || isShipToBloodDriveWithTMS) {
            intRec.ShipToSiteName__c = ship.Ship_To_TMS_Site__r?.Name;
        }

        intRec.ShipToPartnerSiteAlias__c = null;

        Boolean isShipToBloodDriveWithoutTMS = ship.Ship_To_Site_Type__c == BSF_Constants.TYPE_BLOOD_DRIVE 
                                            && ship.Drive__r?.sked_Drive_Site__r?.TMS_Site__c == null;
        
        if (isShipToBloodDriveWithoutTMS) {
            intRec.TempShipToEnterpriseName__c = config.Enterprise_Name__c;
            intRec.TempShipToOrganizationName__c = config.Organization_Name__c;
            intRec.TempShipToSiteName__c = ship.Ship_To_Blood_Drive_Site__r?.Name;
            intRec.TempShipToCountry__c = BSF_Constants.COUNTRY_US;
            intRec.TempShipToState__c = ship.Ship_To_Blood_Drive_Site__r?.sked_State__c;
            intRec.TempShipToCity__c = ship.Ship_To_Blood_Drive_Site__r?.sked_City__c;
            intRec.TempShipToPostalCode__c = ship.Ship_To_Blood_Drive_Site__r?.sked_Zip_Code__c;
            intRec.TempShipToStreet1__c = ship.Ship_To_Blood_Drive_Site__r?.sked_Address_1__c;
        }
        intRec.TempShipToStreet2__c = null;
        intRec.CurrentCarrierEnterpriseName__c = null;
        intRec.CurrentCarrierOrganizationName__c = null;
        intRec.CarrierPartnerName__c = null;
        intRec.CarrierPartnerProfileName__c = null;
        intRec.PickupDateRangeStart__c = ship.Pickup_Start_Datetime__c != null ? ship.Pickup_Start_Datetime__c.format('yyyy-MM-dd\'T\'HH:mm:ssZ') : null;
        intRec.PickupDateRangeEnd__c = ship.Pickup_End_Datetime__c != null ? ship.Pickup_End_Datetime__c.format('yyyy-MM-dd\'T\'HH:mm:ssZ') : null;
        intRec.DeliveryDateRangeStart__c = ship.Delivery_Start_Datetime__c != null ? ship.Delivery_Start_Datetime__c.format('yyyy-MM-dd\'T\'HH:mm:ssZ') : null;
        intRec.DeliveryDateRangeEnd__c = ship.Delivery_End_Datetime__c != null ? ship.Delivery_End_Datetime__c.format('yyyy-MM-dd\'T\'HH:mm:ssZ') : null;
        intRec.LoadType__c = config.Load_Type__c;
        intRec.EquipmentType__c = ship.Drive_Delivery_Movement__r?.Equipment_Type__c;
        intRec.Movement_Number__c = ship.Drive_Delivery_Movement__r?.Movement_Number__c;
        intRec.OrderRefNumber__c = null;
        intRec.FreightTerms__c = config.Freight_Terms__c;
        intRec.Pickup_Instructions__c = null;
        intRec.Special_Instructions__c = null;
        intRec.FreightControlledBySystem__c = config.Freight_Controlled_By_System__c;
        intRec.ShipmentType__c = ship.Shipment_Type__c;
        intRec.Size__c = null;
        intRec.CustomerOrderRef__c = null;
        intRec.ServiceLevel__c = config.Service_Level__c;
        intRec.ShipmentLineNumber__c = null;
        intRec.ItemName__c = null;
        intRec.NonCataloguedItemName__c = null;
        intRec.ItemDescription__c = config.Item_Description__c;
        intRec.ShippedQuantity__c = null;
        intRec.QuantityUnitOfMeasure__c = null;
        intRec.QueueName__c = config.Queue_Name__c;
        intRec.InboundQueueEnterpriseName__c = config.Enterprise_Name__c;
        intRec.InboundInterface__c = config.Inbound_Interface__c;
        intRec.InboundInterfaceVersion__c = config.Inbound_Interface_Version__c;
        intRec.Sender__c = config.Sender__c;
        intRec.Content_Type__c = config.Content_Type__c;

        return generateTransmissionId(ship.Drive_Delivery_Movement__r?.Owner?.LastName, ship.Drive_Delivery_Movement__r?.Owner?.FirstName, ship.Drive_Delivery_Movement__r?.Name, intRec, i);
    }
    private static Delivery_Shipment_Integration__c generateTransmissionId(String ownerLastName, String ownerFirstName, String movementName, Delivery_Shipment_Integration__c intRec, Integer slNumber) {
        String dateTimeStr = System.now().format('yyyyMMddHHmmssSSSXX').replaceAll('[\\-\\+]', '');
        String transmissionId = (String.isNotBlank(ownerLastName) ? ownerLastName.toLowerCase() + '_' : '')+
                                (String.isNotBlank(ownerFirstName) ? ownerFirstName.substring(0, 1).toLowerCase() + '_' : '') + 
                                (String.isNotBlank(movementName) && movementName.length() > 2 ? movementName.substring(2) + '_' : '') + dateTimeStr + 
                                (slNumber != null && slNumber > 0 ? String.valueOf(slNumber) : '0');

        intRec.TransmissionId__c = transmissionId;
        intRec.ClientFileName__c = transmissionId + '.json';
        return intRec;
    }
}