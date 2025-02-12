Global class JobSkedRegionCorrectionBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    String query;
    Date toDate; 
    Date fromDate;
    Id driveId;
    
    public JobSkedRegionCorrectionBatch(Date toDate, Date fromDate){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.query = 'SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND sked_Drive_Date__c <= :fromDate AND sked_Status__c Not In (\'Cancel\',\'Complete\')';
    }

    public JobSkedRegionCorrectionBatch(){
        this.query = 'SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= Today AND sked_Status__c Not In (\'Cancel\',\'Complete\')';
    }

    public JobSkedRegionCorrectionBatch(Id driveId){
        this.driveId = driveId;
        this.query = 'SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c WHERE sked_Status__c Not In (\'Cancel\',\'Complete\') AND Id =: driveId';
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);        
    }
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        try {
            Set<Id> locationIds = new Set<Id>();
            Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>();
            Set<Id> driveIds = new Set<Id>();
            for(sked_Drive__c drive : driveList){
                locationIds.add(drive.sked_Drive_Site__c);
                driveIds.add(drive.Id);
                mapDrive.put(drive.Id,drive);
            }
            List<sked__Job__c> jobRelatedToDrive = [SELECT Id, sked__Location__c, sked__Region__c, sked_Drive__c, sked__Job_Status__c FROM sked__Job__c where sked__Job_Status__c Not In ('Complete','Cancelled') AND sked_Drive__c IN: driveIds];
            Map<Id, List<sked__Job__c>> mapDriveVsJobs = new Map<Id, List<sked__Job__c>>();
            for(sked__Job__c job : jobRelatedToDrive){
                list<sked__Job__c> listOfJob = new List<sked__Job__c>();
                if(mapDriveVsJobs.get(job.sked_Drive__c) != NULL){
                    listOfJob = mapDriveVsJobs.get(job.sked_Drive__c);
                    listOfJob.add(job);
                    mapDriveVsJobs.put(job.sked_Drive__c,listOfJob);
                } else{
                    listOfJob.add(job);
                    mapDriveVsJobs.put(job.sked_Drive__c,listOfJob);
                }
            }
            Map<Id, sked__Location__c> mapLocation = new Map<Id, sked__Location__c>([SELECT Id, sked__Region__c, sked__Address__c,
                                                                                    sked__GeoLocation__Latitude__s,
                                                                                    sked__GeoLocation__Longitude__s,
                                                                                    (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                                                                                    sked_Region__c
                                                                                    FROM sked_Site_Collection_Operations__r)
                                                                                    FROM sked__Location__c
                                                                                    WHERE Id IN :locationIds]);
            List<sked__Job__c> jobsNeedToUpdate = new List<sked__Job__c>();
            for(sked_Drive__c drive : driveList){
                if(mapDriveVsJobs.get(drive.Id) != NULL){
                    for (sked__Job__c job : mapDriveVsJobs.get(drive.Id)) {
                        if (job.sked__Location__c != NULL) {
                            sked__Location__c skedLocation = mapLocation.get(job.sked__Location__c);
                            if (skedLocation != NULL && skedLocation.sked_Site_Collection_Operations__r != NULL) {
                                sked_Drive__c getDrive = mapDrive.get(job.sked_Drive__c);
                                if (getDrive != NULL) {
                                    for (sked_Site_Collection_Operation__c siteCO : skedLocation.sked_Site_Collection_Operations__r) {
                                        if (siteCO.sked_Start_Date__c <= getDrive.sked_Drive_Date__c && getDrive.sked_Drive_Date__c <= siteCO.sked_End_Date__c) {
                                            if( job.sked__Region__c != NULL && job.sked__Region__c != siteCO.sked_Region__c){
                                                job.sked__Region__c = siteCO.sked_Region__c;
                                                jobsNeedToUpdate.add(job);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
            if(!jobsNeedToUpdate.isEmpty()){
                Database.SaveResult[] srList = Database.update(jobsNeedToUpdate, false);
                errorList.addAll(BSF_Utilities.createErrorLog(srList,'JobSkedRegionCorrectionBatch','JobSkedRegionCorrectionBatch','execute','Error','Update Failed'));
            }
        } catch (Exception expt) {
            BSF_Error_Log__c err = BSF_Utilities.getErrorLog('JobSkedRegionCorrectionBatch','JobSkedRegionCorrectionBatch','execute','Error',expt.getStackTraceString(),expt.getMessage());
            insert err;
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}