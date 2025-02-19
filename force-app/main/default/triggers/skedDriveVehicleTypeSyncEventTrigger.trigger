trigger skedDriveVehicleTypeSyncEventTrigger on sked_DriveVehicle_Type_Sync_Event__e (after insert) {
    System.debug('skedDriveVehicleTypeSyncEventTrigger on sked_DriveVehicle_Type_Sync_Event__e ====>>'+Datetime.now().format('yyyy-MM-dd HH:mm:ss.SSS'));
    skedPlatformEventHub handler = new skedPlatformEventHub();
    handler.processTriggerHandler(skedDriveVehicleTypeSyncEventTrigHandler.class);
}