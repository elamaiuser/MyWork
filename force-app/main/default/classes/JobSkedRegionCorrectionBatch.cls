Global class JobSkedRegionCorrectionBatch implements Database.Batchable<sObject>, Database.Stateful{
    /*

	For instruction go to end :::

   */
    String query;
    Date toDate; 
    Date fromDate;
    String typeOfDrive;
    
    public JobSkedRegionCorrectionBatch(Date toDate, Date fromDate, String typeOfDrive){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.typeOfDrive = typeOfDrive;
        this.query = 'SELECT Id, sked_Type_of_Drive__c,sked_Drive_Date__c, sked_Drive_Site__c, (SELECT Id, sked__Region__c FROM sked_Jobs__r) FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND '+
                        'sked_Drive_Date__c <= :fromDate AND sked_Type_of_Drive__c = :typeOfDrive AND Drive_Status__c Not In (\'Cancel\')';
    }

    public JobSkedRegionCorrectionBatch(){
        this.query = 'SELECT Id, sked_Type_of_Drive__c,sked_Drive_Date__c, sked_Drive_Site__c, (SELECT Id, sked__Region__c FROM sked_Jobs__r) FROM sked_Drive__c WHERE sked_Drive_Date__c >= Today AND sked_Type_of_Drive__c = :typeOfDrive AND Drive_Status__c Not In (\'Cancel\')';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {   
        return Database.getQueryLocator(this.query);        
    }
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        Set<Id> locationIds = new Set<Id>();
        Set<Id> driveIds = new Set<Id>();
        Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>();
        for(sked_Drive__c drive : driveList){
            locationIds.add(drive.sked_Drive_Site__c);
            driveIds.add(drive.Id);
            mapDrive.put(drive.Id,drive);
        }
        Map<Id, sked__Location__c> mapLocation = new Map<Id, sked__Location__c>([SELECT Id, sked__Region__c, sked__Address__c,
                                                                                 sked__GeoLocation__Latitude__s,
                                                                                 sked__GeoLocation__Longitude__s,
                                                                                 (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
                                                                                  sked_Region__c
                                                                                  FROM sked_Site_Collection_Operations__r)
                                                                                 FROM sked__Location__c
                                                                                 WHERE Id IN :locationIds]);
        //sked__Job__c job : drive.sked_Jobs__r
        List<sked__Job__c> jobsNeedToUpdate = new List<sked__Job__c>();
        for(sked_Drive__c drive : driveList){
            if(drive.sked_Jobs__r != null){
                for (sked__Job__c job : drive.sked_Jobs__r) {
                    if (job.sked__Location__c != NULL && job.sked__Region__c == NULL) {
                        sked__Location__c skedLocation = mapLocation.get(job.sked__Location__c);
                        job.sked__Address__c = skedLocation.sked__Address__c;
                        job.sked__GeoLocation__Latitude__s = skedLocation.sked__GeoLocation__Latitude__s;
                        job.sked__GeoLocation__Longitude__s = skedLocation.sked__GeoLocation__Longitude__s;
                        if (skedLocation.sked_Site_Collection_Operations__r != NULL) {
                            sked_Drive__c getDrive = mapDrive.get(job.sked_Drive__c);
                            if (getDrive != NULL) {
                                for (sked_Site_Collection_Operation__c siteCO : skedLocation.sked_Site_Collection_Operations__r) {
                                    if (siteCO.sked_Start_Date__c <= getDrive.sked_Drive_Date__c && getDrive.sked_Drive_Date__c <= siteCO.sked_End_Date__c) {
                                        if( job.sked__Region__c != siteCO.sked_Region__c){
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

        if(!jobsNeedToUpdate.isEmpty()){
            update jobsNeedToUpdate;
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}