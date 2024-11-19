/***************************************************************************************************************************************
 * 
 * Description:      	Chained batch from the parent batch classes: GetDrivesWithIncorrectJobTimesBatch
 * 						In addition to the jobs with the incorrect job times, this batch class will tack on integrated fixed site drives
 * 						that are 6 weeks out and have a start time at the 30 minutes mark.  We will be generating a DCR for these records
 * 						so that the start time will be updated to the correct value.
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/19/24     Fitsum Worku        Initial Code Creation
 * 06/04/24		Fitsum Worku		HRP-12836 Update query to use the site operation type and not the account operation type
 * 
 ************************************************************************************************************************************/
global class GetDrivesForDCRBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Set<Id> drivesToGenerateDCRsFor;
    
	global GetDrivesForDCRBatch(Set<Id> incomingDrives)
    {
        if(!incomingDrives.isEmpty() )
        {
            drivesToGenerateDCRsFor = incomingDrives;
        }
    }
    
    global GetDrivesForDCRBatch()
    {
     	drivesToGenerateDCRsFor = new Set<Id>();
    }
    
	global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer numOfDays = Integer.valueOf(System.Label.Generate_DCR_For_Drives_Days_To_Add);
        Date driveDate = System.Today().AddDays(numOfDays);
        system.debug('### drive date: ' + driveDate);
        return Database.getQueryLocator([SELECT Id, sked_Type_of_Drive__c, sked_Start_Time__c 
                                        FROM sked_Drive__c
                                        WHERE sked_Drive_Date__c > :driveDate 
                                        AND sked_Status__c <> 'Cancel' 
                                        AND sked_Status__c <> 'Complete' 
                                        AND sked_Type_of_Drive__c = 'Fixed Site'
                                        AND sked_Operation_Type__c = 'Integrated' //HRP-12836
                                        AND sked_Plasma_Projected_Procedures__c > 0
                                        AND Id Not In(SELECT sked_Drive__c FROM sked_Drive_Change_Request__c 
                                                      WHERE sked_Status__c = 'Pending' 
                                                      OR sked_Status__c = 'Submitted' 
                                                      OR sked_Status__c = 'Waiting for DM Approval' 
                                                      OR sked_Status__c = 'DM Waiting for DRD Feedback' 
                                                      OR sked_status__c = 'Waiting for APS Approval' 
                                                      OR Sked_Status__c = 'APS Waiting for DRD Feedback')]); 
    }
    
    global void execute(Database.BatchableContext bc, List<sked_Drive__c> lstFixedDrives) {
        system.debug('### Insise GetDrivesForDCR Batch Execute lstFixedDrives ' + lstFixedDrives?.size());
        system.debug('### inside GetDrivesForDCRBatch Execute drivesToGenerateDCRsFor ' + drivesToGenerateDCRsFor?.size());
        for(sked_Drive__c drive : lstFixedDrives) {
            if(drive.sked_Start_Time__c.minute() == 30) {
                if(!drivesToGenerateDCRsFor.contains(drive.Id)) {
					drivesToGenerateDCRsFor.add(drive.Id);     
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if(drivesToGenerateDCRsFor != null) {
        	System.debug('### Final List of Drives ' + drivesToGenerateDCRsFor.size());
            List<sked_Drive__c> drives = [SELECT Id, Name, sked_Type_of_Drive__c, sked_Drive_Date__c, sked_Start_Time__c, sked_Status__c 
                                        	FROM sked_Drive__c WHERE Id in :drivesToGenerateDCRsFor];
            
            string csvString = 'Drive Id, Drive Name, Drive Type, Drive Date, Drive Start Time, Drive Status\n';
            for(sked_Drive__c drive : drives) {
                csvString = csvString+drive.Id+','+drive.Name+','+drive.sked_Type_of_Drive__c+','+drive.sked_Drive_Date__c+','+drive.sked_Start_Time__c+','+drive.sked_Status__c+'\n';
            }
            system.debug('### csvString ' + csvString);
            system.debug('### generate DCR? ' + System.Label.Generate_DCR_For_Drives);
            if(System.Label.Generate_DCR_For_Drives == 'Yes' || Test.isRunningTest()) {
                system.debug('### about to generate DCRs ');
            	//generateDCRs(drivesToGenerateDCRsFor);
            	GetDrivesForDCRCreateBatch batchRecs = new GetDrivesForDCRCreateBatch(drives);
        		Database.executeBatch(batchRecs, 50);
            	//GetDrivesForDCRCreateBatch
        	}
        }
    }
    /*
    public void generateDCRs(Set<Id> validDriveIds) {
				 
        system.debug('### validDriveIds ' + validDriveIds.size());
         
        Map<Id, sked_Drive_Change_Request__c> map_driveId_DCR = skedDriveChangeRequestUtils.GetPendingDCRByDriveId(validDriveIds, new List<String>{'sked_Regenerate_Drive__c'});
        
        system.debug('### map_driveId_DCR ' + map_driveId_DCR.size());
        
        List<sked_Drive_Change_Request__c> driveChangeRequestList = new List<sked_Drive_Change_Request__c>();
        for (Id driveId : validDriveIds) {
            sked_Drive_Change_Request__c dcr = map_driveId_DCR.get(driveId);
            if(dcr == NULL){
                dcr = new sked_Drive_Change_Request__c(sked_Drive__c = driveId);
            }
            dcr.sked_Type__c = skedUtils.addNewItemToMultiPicklist(dcr.sked_Type__c, skedConstants.DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE);
            driveChangeRequestList.add(dcr);
        }
        
        system.debug('### driveChangeRequestList ' + driveChangeRequestList.size());
        
        List<sked_Drive_Change_Request_Item__c> driveChangeRequestItemList = new List<sked_Drive_Change_Request_Item__c>(); 
        
        if (!driveChangeRequestList.isEmpty())
        { 
            upsert driveChangeRequestList;
                       
            for (sked_Drive_Change_Request__c dcr : driveChangeRequestList) {
                sked_Drive_Change_Request_Item__c dcri;
                if (dcr.sked_Drive_Change_Request_Items__r != null && !dcr.sked_Drive_Change_Request_Items__r.isEmpty()) {
                    dcri = dcr.sked_Drive_Change_Request_Items__r[0];
                } else {
                    dcri = new sked_Drive_Change_Request_Item__c(
                            sked_Drive_Change_Request__c = dcr.Id,
                            sked_Object_API_Name__c = 'sked_Drive__c',
                            sked_Field_API_Name__c = 'sked_Regenerate_Drive__c',
                            sked_Field_Label__c = 'Regenerate Drive',
                            sked_Field_Type__c = 'Boolean',
                            sked_Type__c = 'Change'
                            );
                    driveChangeRequestItemList.add(dcri);
                }
            }
            
            system.debug('### driveChangeRequestItemList ' + driveChangeRequestItemList.size());
            insert driveChangeRequestItemList;
        }
    } */
}