/* 
 * @description: This batch corrects # of Bus, # of DOT, # of CDL, Vehicle Type and Vehicle Capacity on the Drive
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 04/01/2025                Souvik Mukherjee	          Corrected issue with String Size too long with making debug log entries (HRP-14448)
 ************************************************************************************************************************************************
*/
public class UpdateDrivesVehicleAllocationFieldsBatch implements Database.Batchable<sObject>{
    /*
    // To run for specific date
    
    Date date1 = Date.newInstance(2023,01,30);
    Date date2 = Date.newInstance(2023,06,01);
    String typeOfDrive = 'Mobile';
    
    UpdateDrivesVehicleAllocationFieldsBatch batchObject = new UpdateDrivesVehicleAllocationFieldsBatch(date1, date2, typeOfDrive);
    Database.executeBatch(batchObject,100);
    
    //to run drive date > = today

    String typeOfDrive = 'Mobile';
    
    UpdateDrivesVehicleAllocationFieldsBatch batchObject = new UpdateDrivesVehicleAllocationFieldsBatch(typeOfDrive);
    Database.executeBatch(batchObject,100);

     */
    String query;
    Date toDate;
    Date fromDate;
    String typeOfDrive;
    Integer maxErrorMessageSize = 32000;                            //Change for HRP-14448
    
    public UpdateDrivesVehicleAllocationFieldsBatch(String typeOfDrive){
        this.typeOfDrive = typeOfDrive;
        this.query = 'SELECT Id, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, sked_Vehicle_Capacity__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= Today AND '+
            'sked_Status__c NOT IN (\'Complete\', \'Cancel\') AND sked_Type_of_Drive__c = :typeOfDrive';
        // this.query = 'SELECT Id FROM sked_Drive__c WHERE Id = \'a2m53000004qvMeAAI\'';
    }
    
    public UpdateDrivesVehicleAllocationFieldsBatch(Date toDate, Date fromDate, String typeOfDrive){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.typeOfDrive = typeOfDrive;
        this.query = 'SELECT Id, sked_No_of_Allocated_Buses__c, sked_No_of_Allocated_CDL__c, sked_No_of_Allocated_DOT__c, sked_Vehicle_Types__c, '+
            'sked_Vehicle_Capacity__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND '+
            'sked_Drive_Date__c <= :fromDate AND sked_Status__c != \'Cancel\' AND sked_Type_of_Drive__c = :typeOfDrive';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        try {
            Set<Id> driveIds = new Set<Id>();
            Map<Id, sked_Drive__c> map_driveId_drive = new Map<Id, sked_Drive__c>();
            for (sked_Drive__c drive : driveList) {
                driveIds.add(drive.Id);
                if(!map_driveId_drive.containsKey(drive.Id)){
                    map_driveId_drive.put(drive.Id,drive);
                }
            }
            if (!driveIds.isEmpty()) {
                List<sked__Job_Allocation__c> skedJobAllocations = [SELECT Id, sked__Job__r.sked_Drive__c, sked__Resource__r.sked__Category__c,
                                                                sked__Resource__r.sked_Pres_Donor_Capacity__c,
                                                                sked__Resource__r.sked_CDL__c, sked__Resource__r.sked_DOT__c,
                                                                sked__Job__r.sked_Drive__r.sked_No_of_Allocated_Buses__c,
                                                                sked__Job__r.sked_Drive__r.sked_No_of_Allocated_CDL__c,
                                                                sked__Job__r.sked_Drive__r.sked_No_of_Allocated_DOT__c,
                                                                sked__Job__r.sked_Drive__r.sked_Vehicle_Types__c,
                                                                sked__Job__r.sked_Drive__r.sked_Vehicle_Capacity__c
                                                                FROM sked__Job_Allocation__c
                                                                WHERE sked__Job__r.sked_Drive__c IN :driveIds
                                                                AND sked__Job__r.sked_Asset_Type__c = 'Vehicle'
                                                                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
                Map<Id, List<sked__Job_Allocation__c>> map_driveId_vehicleAllocations = new Map<Id, List<sked__Job_Allocation__c>>();
                for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                    List<sked__Job_Allocation__c> vehicleAllocations;
                    if (map_driveId_vehicleAllocations.containsKey(skedJobAllocation.sked__Job__r.sked_Drive__c)) {
                        vehicleAllocations = map_driveId_vehicleAllocations.get(skedJobAllocation.sked__Job__r.sked_Drive__c);
                    }
                    else {
                        vehicleAllocations = new List<sked__Job_Allocation__c>();
                        map_driveId_vehicleAllocations.put(skedJobAllocation.sked__Job__r.sked_Drive__c, vehicleAllocations);
                    }
                    vehicleAllocations.add(skedJobAllocation);
                }
                String ErrorLogMessage = '';
                if (!map_driveId_drive.isEmpty()) {
                    List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
                    for (string driveId : map_driveId_drive.keySet()) {
                        List<sked__Job_Allocation__c> vehicleAllocations = new List<sked__Job_Allocation__c>();
                        If(map_driveId_vehicleAllocations.containsKey(driveId)){
                            vehicleAllocations = map_driveId_vehicleAllocations.get(driveId);
                        }
                        sked_Drive__c oldDrive = map_driveId_drive.get(driveId);
                        Decimal noOfAllocatedBusesInDrive = 0;
                        Decimal noOfAllocatedCDLInDrive = 0;
                        Decimal noOfAllocatedDOTInDrive = 0;
                        string vehicleTypeListInDrive = '';
                        Decimal vehicleCapacityInDrive = 0;
                        if(oldDrive != NULL){
                            noOfAllocatedBusesInDrive = oldDrive.sked_No_of_Allocated_Buses__c == NULL ? 0 : oldDrive.sked_No_of_Allocated_Buses__c ;
                            noOfAllocatedCDLInDrive = oldDrive.sked_No_of_Allocated_CDL__c == NULL ? 0 : oldDrive.sked_No_of_Allocated_CDL__c ;
                            noOfAllocatedDOTInDrive = oldDrive.sked_No_of_Allocated_DOT__c == NULL ? 0 : oldDrive.sked_No_of_Allocated_DOT__c ;
                            vehicleTypeListInDrive = oldDrive.sked_Vehicle_Types__c == NULL ? '' : oldDrive.sked_Vehicle_Types__c ;
                            vehicleCapacityInDrive = oldDrive.sked_Vehicle_Capacity__c == NULL ? 0 : oldDrive.sked_Vehicle_Capacity__c ;
                        }
                        Integer noOfAllocatedBuses = 0;
                        Integer noOfAllocatedCDL = 0;
                        Integer noOfAllocatedDOT = 0;
                        List<string> vehicleTypeList = new List<string>();
                        decimal vehicleCapacity = 0;
                        
                        for (sked__Job_Allocation__c vehicleAllocation : vehicleAllocations) {
                            if (!vehicleTypeList.contains(vehicleAllocation.sked__Resource__r.sked__Category__c)) {
                                vehicleTypeList.add(vehicleAllocation.sked__Resource__r.sked__Category__c);
                            }
                            if (vehicleAllocation.sked__Resource__r.sked__Category__c == skedConstants.RESOURCE_CATEGORY_BUS) {
                                noOfAllocatedBuses++;
                            }
                            if (vehicleAllocation.sked__Resource__r.sked_CDL__c == TRUE) {
                                noOfAllocatedCDL++;
                            }
                            if (vehicleAllocation.sked__Resource__r.sked_DOT__c == TRUE) {
                                noOfAllocatedDOT++;
                            }
                            if (vehicleAllocation.sked__Resource__r.sked_Pres_Donor_Capacity__c != NULL) {
                                vehicleCapacity += vehicleAllocation.sked__Resource__r.sked_Pres_Donor_Capacity__c;
                            }
                        }
                        vehicleTypeList.sort();
                        if(noOfAllocatedBuses != noOfAllocatedBusesInDrive ||
                            noOfAllocatedCDL != noOfAllocatedCDLInDrive ||
                            noOfAllocatedDOT != noOfAllocatedDOTInDrive ||
                            string.join(vehicleTypeList, ';') != vehicleTypeListInDrive ||
                            vehicleCapacity != vehicleCapacityInDrive
                        ){
                            ErrorLogMessage = ErrorLogMessage + ' For this drive Id :: '+driveId + ' these value is mismatch ';
                            if(noOfAllocatedBuses != noOfAllocatedBusesInDrive){
                                ErrorLogMessage = ErrorLogMessage + 'allocated busses, ';
                            }
                            if(noOfAllocatedCDL != noOfAllocatedCDLInDrive){
                                ErrorLogMessage = ErrorLogMessage + 'CDL, ';
                            }
                            if(noOfAllocatedDOT != noOfAllocatedDOTInDrive){
                                ErrorLogMessage = ErrorLogMessage + 'Dot, ';
                            }
                            if(string.join(vehicleTypeList, ';') != vehicleTypeListInDrive){
                                ErrorLogMessage = ErrorLogMessage + 'Vehicle type list, ';
                            }
                            if(vehicleCapacity != vehicleCapacityInDrive){
                                ErrorLogMessage = ErrorLogMessage + 'vehicle Capacity ';
                            }
                            sked_Drive__c skedDrive = new sked_Drive__c(
                                Id = driveId,
                                sked_No_of_Allocated_Buses__c = noOfAllocatedBuses,
                                sked_No_of_Allocated_CDL__c = noOfAllocatedCDL,
                                sked_No_of_Allocated_DOT__c = noOfAllocatedDOT,
                                sked_Vehicle_Types__c = string.join(vehicleTypeList, ';'),
                                sked_Vehicle_Capacity__c = vehicleCapacity
                            );
                            drivesToUpdate.add(skedDrive);
                            system.debug('skedDrive :: '+skedDrive);
                            
                        }
                        
                    }
                    //update drivesToUpdate;
                    Database.SaveResult[] updateResults = Database.update(drivesToUpdate,false);
                    system.debug('drivesToUpdate is done and size is  :: '+drivesToUpdate.size());
                    List<BSF_Error_Log__c> errorLogs = new List<BSF_Error_Log__c>();

                    for (Integer i = 0; i < updateResults.size(); i++) {
                        if (!updateResults[i].isSuccess()) {
                            String failedRecordId = drivesToUpdate[i].Id;

                            String errorDetails = '';
                            for (Database.Error err : updateResults[i].getErrors()) {
                                errorDetails += 'Error: ' + err.getMessage() + '. Field: ' + err.getFields() + '\n';
                            }

                            BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                            debugLog.ApexClass__c = 'UpdateDrivesResourceRelatedField';
                            debugLog.Method__c = 'UpdateDrivesResourceRelatedField';
                            debugLog.Error_Description__c = failedRecordId;
                            //added for HRP-14448
                            if(errorDetails.length() > maxErrorMessageSize ){
                                errorDetails = errorDetails.substring(0, maxErrorMessageSize);
                            }
                            debugLog.Error_Description_Long__c = errorDetails;
                            
                            errorLogs.add(debugLog);
                        }
                    }

                    if (!errorLogs.isEmpty()) {
                        insert errorLogs;
                    }
                    if(drivesToUpdate.size()>0){
                        BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                        debugLog.ApexClass__c = 'UpdateDrivesResourceRelatedField';
                        debugLog.Method__c = 'UpdateDrivesResourceRelatedField';
                        debugLog.Error_Description__c = String.valueOf(drivesToUpdate.size());
                        //added for HRP-14448
                        if(ErrorLogMessage.length() > maxErrorMessageSize ){
                            ErrorLogMessage = ErrorLogMessage.substring(0, maxErrorMessageSize);
                        }
                        debugLog.Error_Description_Long__c = ErrorLogMessage;
                        insert debugLog;
                    }
                }
            }
            
        } catch (Exception e) {
            system.debug('The Exception is covered '+e.getMessage());
            BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
            debugLog.ApexClass__c = 'UpdateDrivesResourceRelatedFieldBatch';
            debugLog.Method__c = String.valueOf(e.getLineNumber());
            debugLog.Error_Description__c = 'Exception Caught. Please check Long Description for Details '; //changed for HRP-14448
            debugLog.Error_Description_Long__c = e.getMessage();
            insert debugLog;
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        system.debug('batch is done :: ');
    }
}