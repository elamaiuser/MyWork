/* Description : This batch will update DOC lookup field (Related_Scheduled_Drive__c) on opportunity
 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 *  12/27/2023				 Kishore Das		        Logic for HRP-11605(Newly created FS BDO's are reflecting as tentative when the DOC is reflecting as confirmed (out of sync))
 *  09/10/2024				 Priti Jana					Logic for HRP-13293
 *************************************************************************************************************************************************************************************
*/

global class BSF_BatchOnDocForDriveStatusLookUp implements Database.Batchable<sObject>{
    private Date driveDateFrom;
    private Date driveDateTo;
    private Set<Id> driveIds;
    private Set<Id> oppIds;
    
    global BSF_BatchOnDocForDriveStatusLookUp() {
        this.driveDateFrom = system.today();
    }
    
    global BSF_BatchOnDocForDriveStatusLookUp(Date driveDateFrom, Date driveDateTo, Set<Id> driveIds, Set<Id> oppIds) {
        this.driveDateFrom = driveDateFrom == NULL ? system.today() : driveDateFrom;
        this.driveDateTo = driveDateTo;
        this.driveIds = driveIds;
        this.oppIds = oppIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, sked_Opportunity__c FROM sked_Drive__c WHERE sked_Opportunity__r.Related_Scheduled_Drive__c = NULL AND sked_Opportunity__r.Is_Template__c = FALSE';
        
        if(this.driveDateFrom != NULL) {
            query+= ' AND sked_Drive_Date__c >= :driveDateFrom';
        }
        if(this.driveDateTo != NULL) {
            query+= ' AND sked_Drive_Date__c <= :driveDateTo';
        }
        if(this.driveIds != NULL) {
            query+= ' AND ID IN :driveIds';
        }
        if(this.oppIds != NULL) {
            query+= ' AND sked_Opportunity__c IN :oppIds';
        }
        
        return Database.getQueryLocator(query);  
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList) {
        
        //Call reusable method from DriveTriggerService which will take care of error handling as well
        DriveTriggerService.populateLookupOnOpportunityDoc(driveList);
        
    }
    
    global void finish(Database.BatchableContext BC) {}

}