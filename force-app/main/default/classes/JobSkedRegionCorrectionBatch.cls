/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
*03/20/2025                      Harika Bolisetti            Logic for HRP-14439//Taxo Run Chaining in finish method
*/

global class JobSkedRegionCorrectionBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    String query;
    Date toDate; 
    Date fromDate;
    Id driveId;
    
    //HRP-14439
    global Decimal taxVer;
    
    //HRP-14439
    
    public JobSkedRegionCorrectionBatch(Decimal taxVer){
        
        try{//HRP-14439
            this();
            this.taxVer = taxVer;
        }catch (Exception e) {Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'Constructor', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            
        }
    }
    
    public JobSkedRegionCorrectionBatch(Date toDate, Date fromDate){
        try{//HRP-14439
            this.toDate = toDate;
            this.fromDate = fromDate;
            this.query = 'SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND sked_Drive_Date__c <= :fromDate AND sked_Status__c Not In (\'Cancel\',\'Complete\')';
        }catch (Exception e) {Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'Constructor', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }
    
    public JobSkedRegionCorrectionBatch(){
        try{//HRP-14439
            this.query = 'SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= Today AND sked_Status__c Not In (\'Cancel\',\'Complete\')';
        } catch (Exception e) { Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }
    
    public JobSkedRegionCorrectionBatch(Id driveId){
        try{//HRP-14439
            this.driveId = driveId;
            this.query = 'SELECT Id, sked_Drive_Date__c, sked_Drive_Site__c FROM sked_Drive__c WHERE sked_Status__c Not In (\'Cancel\',\'Complete\') AND Id =: driveId';
        } catch (Exception e) { //HRP-14439
            Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'Constructor', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //HRP-14439
        try{
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='JobSkedRegionCorrectionBatch',Method__c='start',Type__c='Success',
                                                             Error_Description__c='Batch Process Started',Error_Description_Long__c= this.query);
            errorLogList.add(errorLog);
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Start','Error',
                                     'Error occurred while inserting the error Record',null,taxVer);
            return Database.getQueryLocator(this.query);  
        } catch (Exception e) { //HRP-14439
            Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return null;   
        }
    }
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        try {//HRP-14439
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
        } catch (Exception e) {
        Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'Execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
                                         
        }
    }
    global void finish(Database.BatchableContext bc){
        //HRP-14439
        try{
            //Capture finish method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='JobSkedRegionCorrectionBatch',Method__c='finish',Type__c='Success',Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
            errorLogList.add(errorLog);
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Finish','Error',
                                     'Error occurred while inserting the error Record',null,taxVer);
            if(this.taxver!=null){
                Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'skedDriveDistrictBatch');   
                Database.executeBatch(new skedDriveDistrictBatch(taxver),batchSize);  
            }
        } catch (Exception e) { //HRP-14439 
            Taxo_Utilities.logErrorForException(e, 'JobSkedRegionCorrectionBatch', 'finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }
}