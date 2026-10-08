/* NOTE : Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification using different profiles on DOC (11418)
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  03/08/2023				 Kishore Das		        Users other than System Admin should not have any delete record permissions(Logic for HRP-10572-->Deleted)
 *  18/08/2023				 Kishore Das				Logic for HRP-10765(Ready for National Name Review True when associated drive in Tentative status)
 *  09/20/2023				 Krapy Tuli					Logic for HRP-10359 (Update AM, DM, AM Portfolio and DM Portfolio)
 *  11/09/2023               Barnojit Sharma            Validation added to stop referring two DOC to a single BDO. (HRP-11326)
 *  12/27/2023				 Kishore Das		        Logic for HRP-11605(Newly created FS BDO's are reflecting as tentative when the DOC is reflecting as confirmed (out of sync))
 *  12/27/2023				 Barnojit Sharma		    The current 56 day validation rule that triggers when trying to change Drive Date will also be added to the Drive on Calendar. (HRP-11640)
 *  01/09/2024               Priti Jana                 Logic for HRP-10882
 *  02/01/2024		         Fitsum Worku				Updated logic for 56 day rule so that 56th day itself is considered eligible (HRP-12034); also exculding cancelled drives
 *  12/02/2024				 Barnojit Sharma		    BDO can not be confirmed if DCR or Pending Action is in progress. (HRP-10912)
 *  03/06/2024				 Priti Jana					Logic for HRP-12271
 *  04/25/2024				 Raktim Ghosal				Populate Drive Lead / Charge (Supervisory Role) on Drive. (HRP-12493)
 *  08/19/2024				 Priti Jana					Logic for HRP-13056
 *  10/18/2024               Priti Jana                 Logic for HRP-9815
 *  03/17/2026               Krapy Tuli                 Logic for HRP-16769 to handle Concurrent transaction and fix Incorrect conditional logic for duplicate check
 ********************************************************************************************************************************************************************
*/


public without sharing class DriveTriggerService {

    public static void updateReadyforNationalNameReview(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap){
        Map<Id,sked__Location__c> siteList = new Map<Id,sked__Location__c>();
        Map<Id,Account> accountList = new Map<Id,Account>();
        Set<Id> processedAccountIds = new Set<Id>();
        Set<Id> processedSiteIds = new Set<Id>();
        for (sked_Drive__c newRecord : newRecords) {
            if (oldMap != null && newRecord.sked_Status__c != oldMap.get(newRecord.Id).sked_Status__c) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CONFIRMED || newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_COMPLETE){ //Logic for HRP-10765   
                    sked__Location__c site = new sked__Location__c();
                    Account acc = new Account();
                    if (newRecord.sked_Drive_Site__c != null && !processedSiteIds.contains(newRecord.sked_Drive_Site__c)) {
                        site.Id = newRecord.sked_Drive_Site__c;
                        site.sked_Ready_for_National_Name_Review__c = true; 
                        siteList.put(site.Id,site);
                        processedSiteIds.add(newRecord.sked_Drive_Site__c);
                    }
                    if (newRecord.sked_Account__c != null && !processedAccountIds.contains(newRecord.sked_Account__c)) {
                        acc.Id = newRecord.sked_Account__c;
                        acc.Ready_for_National_Name_Review__c = true;
                        accountList.put(acc.Id,acc);
                        processedAccountIds.add(newRecord.sked_Account__c);
                    }
                }  
            } 
            if (oldMap == null) {
                if (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CONFIRMED || newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_COMPLETE){ //Logic for HRP-10765   
                    sked__Location__c site = new sked__Location__c();
                    Account acc = new Account();
                   if (newRecord.sked_Drive_Site__c != null && !processedSiteIds.contains(newRecord.sked_Drive_Site__c)) {
                        site.Id = newRecord.sked_Drive_Site__c;
                        site.sked_Ready_for_National_Name_Review__c = true; 
                        siteList.put(site.Id,site);
                       	processedSiteIds.add(newRecord.sked_Drive_Site__c);
                    }
                    if (newRecord.sked_Account__c != null && !processedAccountIds.contains(newRecord.sked_Account__c)) {
                        acc.Id = newRecord.sked_Account__c;
                        acc.Ready_for_National_Name_Review__c = true;
                        accountList.put(acc.Id,acc);
                        processedAccountIds.add(newRecord.sked_Account__c);
                    }
                }   
            }
        }
        
        
        if (siteList.size() > 0) {
             update siteList.values();
         }
         if (accountList.size() > 0) {
             update accountList.values();
         }
    }
    public static void populateDriveWorksheetData(List<sked_Drive__c> newRecords)
    {
        try{
            if(newRecords == null || !Schema.sObjectType.Opportunity.isAccessible()){
                return;
            }
            Set<Id> opportunityIds = new Set<Id>();
            for(sked_Drive__c drv : newRecords){
                if(drv.sked_Opportunity__c != null){
                    opportunityIds.add(drv.sked_Opportunity__c);
                }
            }
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
            Map<Id, Id> contactRoleMapHM = new Map<Id, Id>();
            Map<Id, Id> contactRoleMapPC = new Map<Id, Id>();
            if(opportunityIds.size() > 0){
                opportunityMap = new Map<Id, Opportunity>([SELECT Id, 
                                                                    Open_to_Public__c,
                                                                    Security_Escort_Name__c 
                                                            FROM Opportunity 
                                                            WHERE Id IN:opportunityIds]);
                if(Schema.sObjectType.OpportunityContactRole.isAccessible() && Schema.sObjectType.OpportunityContactRole.fields.Role.isAccessible()){
                    List<OpportunityContactRole> oppCntRole = [SELECT Id,
                                                                        ContactId,
                                                                        OpportunityId,
                                                                        Role 
                                                                FROM OpportunityContactRole
                                                                WHERE OpportunityId IN:opportunityIds
                                                                AND (Role = 'Whom to Meet'
                                                                OR Role = 'Primary Contact')];
                    for(OpportunityContactRole ocr: oppCntRole){
                        if(ocr.Role.equals('Whom to Meet')){
                            contactRoleMapHM.put(ocr.OpportunityId,ocr.ContactId);
                        }else if(ocr.Role.equals('Primary Contact')){
                            contactRoleMapPC.put(ocr.OpportunityId,ocr.ContactId);
                        }
                    }
                }
            }
            if(opportunityMap.size() > 0){
                for(sked_Drive__c drv : newRecords){
                    if(drv.sked_Opportunity__c != null && drv.sked_Open_to_Public__c == null && opportunityMap.containsKey(drv.sked_Opportunity__c)
                            && Schema.sObjectType.sked_Drive__c.fields.sked_Open_to_Public__c.isUpdateable()){
                                drv.sked_Open_to_Public__c = opportunityMap.get(drv.sked_Opportunity__c).Open_to_Public__c;
                    }
                    if(drv.sked_Opportunity__c != null && drv.sked_Whome_to_Meet__c == null && contactRoleMapHM.size() > 0 && contactRoleMapHM.containsKey(drv.sked_Opportunity__c)
                            && Schema.sObjectType.sked_Drive__c.fields.sked_Whome_to_Meet__c.isUpdateable()){
                                drv.sked_Whome_to_Meet__c = contactRoleMapHM.get(drv.sked_Opportunity__c);
                    }
                    if(drv.sked_Opportunity__c != null && drv.sked_Primary_Contact__c == null && contactRoleMapPC.size() > 0 && contactRoleMapPC.containsKey(drv.sked_Opportunity__c)
                            && Schema.sObjectType.sked_Drive__c.fields.sked_Primary_Contact__c.isUpdateable()){
                                drv.sked_Primary_Contact__c = contactRoleMapPC.get(drv.sked_Opportunity__c);
                    }
                    if(drv.sked_Opportunity__c != null && drv.sked_Security_Escort_Name__c == null && opportunityMap.containsKey(drv.sked_Opportunity__c)
                            && Schema.sObjectType.sked_Drive__c.fields.sked_Security_Escort_Name__c.isUpdateable()){
                                drv.sked_Security_Escort_Name__c = opportunityMap.get(drv.sked_Opportunity__c).Security_Escort_Name__c;
                    }
                } 
            }
        }catch(System.FinalException ex){

        }catch(Exception exp){}
    }
    
    
    
    //HRP-10359 Start
    public static void populateAMAndDM(List<sked_Drive__c> newRecords)
    {
        try{
          
            if(newRecords == null || !Schema.sObjectType.Opportunity.isAccessible()){
                return;
            }
            Set<Id> opportunityIds = new Set<Id>();
            for(sked_Drive__c drv : newRecords){
                if(drv.sked_Opportunity__c != null){
                    opportunityIds.add(drv.sked_Opportunity__c);
                }
            }
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
            if(opportunityIds.size() > 0){
                opportunityMap = new Map<Id, Opportunity>([SELECT Id, Account_Manager__c,Account_Manager_Portfolio__c,District_Manager__c,District_Manager_Portfolio__c
                                                            FROM Opportunity 
                                                            WHERE Id IN:opportunityIds]);
            }
            if(opportunityMap.size() > 0){
                for(sked_Drive__c drv : newRecords){
                    if(drv.sked_Opportunity__c != null && opportunityMap.containsKey(drv.sked_Opportunity__c)){
                                drv.Account_Manager__c = opportunityMap.get(drv.sked_Opportunity__c).Account_Manager__c != null ?  opportunityMap.get(drv.sked_Opportunity__c).Account_Manager__c: null;
                                drv.Account_Manager_Portfolio__c = opportunityMap.get(drv.sked_Opportunity__c).Account_Manager_Portfolio__c != null ?  opportunityMap.get(drv.sked_Opportunity__c).Account_Manager_Portfolio__c: null;
                                drv.District_Manager__c = opportunityMap.get(drv.sked_Opportunity__c).District_Manager__c != null ?  opportunityMap.get(drv.sked_Opportunity__c).District_Manager__c: null;
                                drv.District_Manager_Portfolio__c = opportunityMap.get(drv.sked_Opportunity__c).District_Manager_Portfolio__c != null ?  opportunityMap.get(drv.sked_Opportunity__c).District_Manager_Portfolio__c: null;
                    }
                } 
            }
        }catch(System.FinalException ex){

        }
    } //HRP-10359 End
    /*
    * HRP-11326 changes starts here
    */
    public static void validateOpportunity(Map<Id, sked_Drive__c> oldMap , List<sked_Drive__c> newList){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> currentDriveIds = new Set<Id>();//HRP-16769 start
        Set<Id> currentOppIds = new Set<Id>();
        
        for(sked_Drive__c drv : newList){
            if(drv.Id != null){
                currentDriveIds.add(drv.Id);
            }
            if(drv.sked_Opportunity__c != null){
                currentOppIds.add(drv.sked_Opportunity__c);
            }
        }

        List<sked_Drive__c> existingDriveList = [SELECT Id, sked_Opportunity__c, sked_Is_Surrogate__c FROM sked_Drive__c
                                                                                                        WHERE sked_Opportunity__c IN :currentOppIds
                                                                                                        AND Id NOT IN :currentDriveIds
                                        AND sked_Is_Surrogate__c = false
        ];

		Set<Id> duplicateForOpps = new Set<Id>();
        for(sked_Drive__c drv : existingDriveList){
            duplicateForOpps.add(drv.sked_Opportunity__c);
        }//HRP-16769 end

            for(sked_Drive__c drv : newList){

            if(oldMap != null && oldMap.containsKey(drv.Id)){
                sked_Drive__c oldDrv = oldMap.get(drv.Id);

                if(oldDrv.sked_Opportunity__c != null 
                && oldDrv.sked_Opportunity__c != drv.sked_Opportunity__c){

                    drv.addError('BDO can not be changed/removed.');
                    continue;
                }
            }
            //HRP-16769 start
            if(drv.sked_Opportunity__c != null 
            && !drv.sked_Is_Surrogate__c
            && duplicateForOpps.contains(drv.sked_Opportunity__c)){
                            drv.addError('DOC has been generated for this BDO.');
            }//HRP-16769 end
        }
    }
    /*
    * HRP-11326 changes ends here
    */
    
    //Logic for HRP-11605 ***Starts here***
    public static void populateLookupOnOpportunityDoc(List<sked_Drive__c> newList) {
        
        Map<Id, sked_Drive__c> docMap = new Map<Id, sked_Drive__c>();
        
        for (sked_Drive__c sc : newList) {
            docMap.put(sc.sked_Opportunity__c, sc);
        }
        
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        
        for (Opportunity op : [SELECT Id, Related_Scheduled_Drive__c FROM Opportunity
                               WHERE Related_Scheduled_Drive__c = null AND Id IN :docMap.keySet()]) {
                                   Opportunity oppToUpdate = new Opportunity(Id = op.Id);
                                   oppToUpdate.Related_Scheduled_Drive__c = docMap.get(op.Id).Id;
                                   oppListToUpdate.add(oppToUpdate);
                               }
        
        if (!oppListToUpdate.isEmpty()) {
            
            //HRP-13056 --> Starts Here
            TriggerHandler.bypass('OpportunityTriggerHandler');
            Database.SaveResult[] updateResults = Database.update(oppListToUpdate, false);
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
            List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLogWithObjectId(
                updateResults, 
                'Error in populating DOC lookup on Opportunity', 
                'DriveTriggerService', 
                'populateLookupOnOpportunityDoc', 
                'Error', 
                'Error in update'
            );
            Insert errorLogList;
            //HRP-13056 --> Ends Here
        }
    }

    //Logic for HRP-11605 ***Ends here***
    /*
    * HRP-11640 changes starts here
    */
    public static void checkAccept56DaysVoilation(Map<Id, sked_Drive__c> oldMap, List<sked_Drive__c> newItems) {
        Map<Id,Id> oppVsDocMap = new Map<Id,Id>();
        Map<Id,Id> docVsAccMap = new Map<Id,Id>();
        Map<Id,List<Date>> accVsDriveDateMap = new Map<Id,List<Date>>();
        List<String> driveStatusToValidate = new List<String>{BSF_Constants.DOC_STATUS_CONFIRMED};
        for(sked_Drive__c doc : newItems){
            if(doc.sked_Opportunity__c != null && doc.sked_Drive_Date__c != null && oldMap.containsKey(doc.Id) 
                    && (doc.sked_Drive_Date__c != oldMap.get(doc.Id).sked_Drive_Date__c
                    || (String.isNotBlank(doc.sked_Status__c) && doc.sked_Status__c != oldMap.get(doc.Id).sked_Status__c
                    && (driveStatusToValidate.contains(doc.sked_Status__c))))){
                        oppVsDocMap.put(doc.sked_Opportunity__c,doc.Id);
            }
        }
       
        if(!oppVsDocMap.isEmpty()){
            List<Opportunity> oppList = [SELECT Id, 
                                                AccountId, 
                                                Accept_56_Day_Rule_Violation__c,
                                         		RecordTypeId
                                        FROM Opportunity 
                                        WHERE Id IN: oppVsDocMap.keySet()];
            for(Opportunity opp : oppList){
                if(opp.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId() 
                        && opp.AccountId != null && !opp.Accept_56_Day_Rule_Violation__c){
                            docVsAccMap.put(oppVsDocMap.get(opp.Id),opp.AccountId);
                }
            }
        }
      
        if(!docVsAccMap.isEmpty()){
            List<Opportunity> oppList = [SELECT Id, 
                                                Drive_Date__c,
                                                AccountId
                                        FROM Opportunity 
                                        WHERE AccountId IN: docVsAccMap.values()
                                        //AND Accept_56_Day_Rule_Violation__c = false //HRP-12034
                                        AND StageName != 'Cancelled']; //HRP-12034
            for(Opportunity opp : oppList){
                if(!oppVsDocMap.containsKey(opp.Id) && opp.Drive_Date__c != null){
                    if(accVsDriveDateMap.isEmpty() || !accVsDriveDateMap.containsKey(opp.AccountId)){
                        accVsDriveDateMap.put(opp.AccountId, new List<Date>{opp.Drive_Date__c});
                    }else if(accVsDriveDateMap.containsKey(opp.AccountId)){
                        accVsDriveDateMap.get(opp.AccountId).add(opp.Drive_Date__c);
                    }
                }
            }
        }
       
        if(!accVsDriveDateMap.isEmpty()){
            for(sked_Drive__c doc : newItems){
                Boolean addError = false;
                if(docVsAccMap.containsKey(doc.Id) && accVsDriveDateMap.containsKey(docVsAccMap.get(doc.Id))){
                    Date fiftySixDaysBefore = doc.sked_Drive_Date__c;
                    Date fiftySixDaysAfter = doc.sked_Drive_Date__c;
                    fiftySixDaysBefore = fiftySixDaysBefore.addDays(-56);
                    fiftySixDaysAfter = fiftySixDaysAfter.addDays(56);
                    for(Date ddate : accVsDriveDateMap.get(docVsAccMap.get(doc.Id))){
                        if(fiftySixDaysBefore < ddate && fiftySixDaysAfter > ddate){ //HRP-12034
                            addError = true;
                        }
                    }
                }
                if(addError){
                    doc.addError('This drive date violates the 56 day rule. Please change the drive date.');
                }
            }
        }
    }
    /*
    * HRP-11640 changes ends here */
    
    // HRP-10882 --> Starts Here
    /* Description : Before moving the DOC to Confirmed Status - this method will validate site mandatory fields based on the custom metadata - Site_Mandatory_Fields_Setting__mdt
     * If anyone of them are missing, it'll throw an error and ask the user to populate the field
    */
    
    public static void validateRequiredSiteFieldsBasedOnDriveStatus(Map<Id,sked_Drive__c> oldMap, Map<Id,sked_Drive__c> newMap)
    {        
        Set<Id> driveSiteId = new Set<Id>();
        List<sked_Drive__c> validDrivesList = new List<sked_Drive__c>();
        String customErrorMessage = Custom_Messages__mdt.getInstance('Validate_Site_Fields').value__c;
        List<Site_Mandatory_Fields_Setting__mdt> siteMandatoryFieldCustomMetadataList = Site_Mandatory_Fields_Setting__mdt.getAll().values(); 

        for(sked_Drive__c newDrive : newMap.values())
        {
            sked_Drive__c oldDrive = oldMap.get(newDrive.Id);
            if(oldDrive != NULL && !oldDrive.sked_Status__c.equals(newDrive.sked_Status__c) && newDrive.sked_Status__c.equals(Constants.DRIVE_STATUS_CONFIRMED))
            {
                driveSiteId.add(newDrive.sked_Drive_Site__c);
                validDrivesList.add(newDrive);
            }
        }

        if(!validDrivesList.isEmpty() && validDrivesList.size() > 0)
        {
            Map<Id,sked__Location__c> driveSiteMap = new Map<Id,sked__Location__c>([SELECT sked_Directions_From_CollectionOperation__c, sked_Floor_Description__c, 
                                                                                    sked_Outside_stairs__c, sked_Inside_stairs__c, sked_Physical_Location_Type__c, 
                                                                                    sked_Site_Main_Phone__c, sked_Room_Name__c, sked_Site_Building_Name__c, Operation_Type__c,
                                                                                    sked_Site_Contact__c, sked_Automation_Suitability__c, sked_Staff_Personal_Parking_Directions__c
                                                                                    FROM sked__Location__c where Id IN: driveSiteId]);

       
            for(sked_Drive__c newDrive : validDrivesList)
            {
                List<String> missingFieldsList = new List<String>(); 
                
                for(Site_Mandatory_Fields_Setting__mdt siteFieldMetdata : siteMandatoryFieldCustomMetadataList)
                {
                    List<String> recordTypeList = siteFieldMetdata.Required_For__c.split(',');
                    
                    if(driveSiteMap.get(newDrive.sked_Drive_Site__c).get(siteFieldMetdata.Field_Name__c) == NULL && recordTypeList.contains(newDrive.sked_Type_of_Drive__c))
                    {                         
                        missingFieldsList.add(siteFieldMetdata.Field_Label__c);
                    }
                }                               

                if(missingFieldsList.size() > 0)
                {
                    customErrorMessage = customErrorMessage.replace('[object]' , newDrive.sked_Type_of_Drive__c+' drive');
                    customErrorMessage = customErrorMessage.replace('[StageOrStatus]' , 'Confirmed Status');
                    customErrorMessage = customErrorMessage.replace('missingFields' , String.join(missingFieldsList, ', '));
                    newDrive.addError(customErrorMessage);
                }
            }
        }
    }
    
    /* Description : Before moving the DOC to Tentative/Confirmed Status - this method will check below pointers
    // 1. Military name and phone field of the account is blank/populated if account type = Military
    // 2. If point 1 is true, then related opportunity's AcceptblankMilitaryAuthNamePhone__c is true/false
    // 3. If point 2 is true, drive can be successfully moved to the next status otherwise throw error
    */ 
    public static void checkMilitaryAuthoritySettingBeforeChangingStatus(List<sked_Drive__c> newRecords, Map<Id, sked_Drive__c> oldMap)
    {                
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        List<sked_Drive__c> validDOCList = new List<sked_Drive__c>();
        String customErrorMessage = Custom_Messages__mdt.getInstance('Military_Auth_Setting').value__c;
        for(sked_Drive__c drive : newRecords)
        {
            if(drive.sked_Account__c != null && drive.sked_Account_Type__c == 'Military' && drive.sked_Type_of_Drive__c == Constants.MOBILE_SITE_OPP)
            {
                oppIds.add(drive.sked_Opportunity__c);
                validDOCList.add(drive);
            }
        }
        
        if(validDOCList.size() > 0)
        {
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([select Account.Military_Authority_Name__c, Account.Military_Authority_Phone__c,
                                                                  AcceptblankMilitaryAuthNamePhone__c from Opportunity where Id IN :oppIds]);
            for (sked_Drive__c newRecord : validDOCList)
            {
                if (oldMap != null && newRecord.sked_Status__c != oldMap.get(newRecord.Id).sked_Status__c 
                                && (newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_TENTATIVE 
                                    || newRecord.sked_Status__c == skedConstants.DRIVE_STATUS_CONFIRMED))
                { 
                    if(!oppMap.isEmpty() && oppMap.get(newRecord.sked_Opportunity__c) != null && (
                                                oppMap.get(newRecord.sked_Opportunity__c)?.Account.Military_Authority_Name__c == null ||
                                                    oppMap.get(newRecord.sked_Opportunity__c)?.Account.Military_Authority_Phone__c == null))
                    {
                       
                       if(!oppMap.get(newRecord.sked_Opportunity__c).AcceptblankMilitaryAuthNamePhone__c)
                       {
                          newRecord.addError(customErrorMessage);
                       }
                     }                              
                }
            }
        }
        
	}

     // HRP-10882 --> Ends Here
    /*
    * HRP-10912 changes starts here
    @Description : This method will block Opportunities status changed while Pending Action Request is in process.
    */
    public static void validateNoPendingDCR(Map<Id, sked_Drive__c> newMap, Map<Id, sked_Drive__c> oldMap){
        if(newMap == null || newMap.isEmpty() || oldMap == null || oldMap.isEmpty()){
            return;
        }
        Map<Id, Boolean> dcrMap = new Map<Id, Boolean>(); 
        Map<Id,Id> oppToDOCMap = new Map<Id,Id>();
        Custom_Messages__mdt messageLabel1 = Custom_Messages__mdt.getInstance('Pending_Approval_Statuses_Drive');
		List<String> pendingApprovalStatusList = messageLabel1.value__c.split(',');
        for(Id driveId : newMap.keySet()){
            if(oldMap.containsKey(driveId) 
                    && newMap.get(driveId).sked_Status__c != oldMap.get(driveId).sked_Status__c
                    && !newMap.get(driveId).sked_Status__c.equalsIgnoreCase('Complete')
                    && !newMap.get(driveId).sked_Status__c.equalsIgnoreCase('Cancel')){
                        if(String.isNotBlank(oldMap.get(driveId).sked_Approval_Status__c)
                                && pendingApprovalStatusList.contains(oldMap.get(driveId).sked_Approval_Status__c)
                                && (oldMap.get(driveId).sked_Approval_Status__c == newMap.get(driveId).sked_Approval_Status__c
                                || (oldMap.get(driveId).sked_Approval_Status__c != newMap.get(driveId).sked_Approval_Status__c)
                                && pendingApprovalStatusList.contains(newMap.get(driveId).sked_Approval_Status__c))){
                                    newMap.get(driveId).addError(Custom_Messages__mdt.getInstance('Pending_DCR_Drives').value__c);
                        }
            }
        }
    }
    /*
    * HRP-10912 changes ends here
    */
    
    
    /*HRP-12493 starts here
     * Description: Populate the name of resources allocated to jobs with supervisory role on the Supervisory Role text field on Drive.
     */ 
    public static void populateDriveSupervisoryRole(Set<Id> driveIds){
        List<String> supervisoryRoles;
   
    sked_Resource_Role_Group__c roleGroup = [SELECT sked_Resource_Roles__c 
                                              FROM sked_Resource_Role_Group__c 
                                              WHERE sked_Resource_Role_Group__c = 'Supervisory roles' 
                                              ORDER BY LastModifiedDate DESC 
                                              LIMIT 1];
    
    if(roleGroup == null || String.isBlank(roleGroup.sked_Resource_Roles__c)){
        supervisoryRoles = new List<String>{BSF_Constants.SUPER_ROLE_APHERESIS_CHARGE, BSF_Constants.SUPER_ROLE_CHARGE,BSF_Constants.SUPER_ROLE_CHARGE_2RBC, BSF_Constants.SUPER_ROLE_SPECIAL_COLLECTIONS_CHARGE,BSF_Constants.SUPER_ROLE_DRIVE_LEAD, BSF_Constants.SUPER_ROLE_TEAM_SUPERVISOR};
    } else {
        supervisoryRoles = roleGroup.sked_Resource_Roles__c.split(';');
    }
        List<sked_Drive__c> drivestoUpdate = new List<sked_Drive__c>();
        if(driveIds != null && !driveIds.isEmpty()){
            Map<Id,String> oldDriveResourceMap = new Map<Id,String>();
            Map<Id, Set<String>> driveResourceMap = new Map<Id, Set<String>>();
            for(sked__Job_Allocation__c jobAllocation : (List<sked__Job_Allocation__c>)Database.query(
                                                        'SELECT Id,sked_Additional_Roles__c,sked__Job__c,sked__Job__r.sked_Drive__c,sked__Job__r.sked_Drive__r.Supervisory_Role__c,'+
                                                        'sked__Job__r.sked_Resource_Role__c,sked__Job__r.sked_Dual_Role__c,sked__Job__r.sked__Type__c,'+
                                                        'sked__Resource__c,sked__Resource__r.Name,sked__Resource__r.sked__Resource_Type__c,'+
                                                        'sked__Resource__r.RecordTypeId,sked__Resource__r.RecordType.Name,sked__Resource__r.sked_First_Name__c,'+
                                                        'sked__Resource__r.sked_Last_Name__c FROM sked__Job_Allocation__c WHERE sked__Status__c != \'Deleted\' '+
                                                        'AND sked__Job__r.sked_Drive__c IN (\'' +
                                                        String.join((List<String>)new List<Id>(driveIds), '\',\'') + '\') AND sked__Resource__r.sked__Resource_Type__c = '+
                                                        '\'Person\' AND sked__Resource__r.RecordType.Name = \'Staff\' AND (sked__Job__r.sked__Type__c IN (\'' + 
                                                        String.join(supervisoryRoles, '\',\'') + '\') OR sked__Job__r.sked_Resource_Role__c IN (\'' + 
                                                        String.join(supervisoryRoles, '\',\'') + '\') OR sked__Job__r.sked_Dual_Role__c IN (\'' + 
                                                        String.join(supervisoryRoles, '\',\'') + '\') OR sked_Additional_Roles__c INCLUDES (\'' + 
                                                        String.join(supervisoryRoles, '\',\'') + '\')'+')',AccessLevel.SYSTEM_MODE)){
                if(!driveResourceMap.containsKey(jobAllocation.sked__Job__r.sked_Drive__c)){
                    driveResourceMap.put(jobAllocation.sked__Job__r.sked_Drive__c, new Set<String>());
                }
                oldDriveResourceMap.put(jobAllocation.sked__Job__r.sked_Drive__c,jobAllocation.sked__Job__r.sked_Drive__r.Supervisory_Role__c);
                driveResourceMap.get(jobAllocation.sked__Job__r.sked_Drive__c).add(jobAllocation.sked__Resource__r.sked_First_Name__c+' '+
                                                                                    jobAllocation.sked__Resource__r.sked_Last_Name__c);
            }
            for(Id driveId : driveIds){
                sked_Drive__c drive = new sked_Drive__c(Id = driveId);
                if(driveResourceMap.containsKey(driveId) && !driveResourceMap.get(driveId).isEmpty()){
                    drive.Supervisory_Role__c = String.join(new List<String>(driveResourceMap.get(driveId)),',');
                }
                else{
                    drive.Supervisory_Role__c = null;
                    if(BSF_Constants.After_Delete == True){
                        drivestoUpdate.add(drive);
                    }
                    
                }
                if(oldDriveResourceMap.containsKey(driveId) && oldDriveResourceMap.get(driveId) != drive.Supervisory_Role__c){
                    drivestoUpdate.add(drive);
                }
                
            }
        }
        if(!drivestoUpdate.isEmpty()){
            Database.update(drivestoUpdate,false);
        }
    }
    //HRP-12493 ends here
   //HRP-12170 [Start ->>]
    public static void autoPopulateDriveProjProductFields(Map<Id, sked_Drive__c> oldDriveMap, List<sked_Drive__c> newDriveList)
    {
        for(sked_Drive__c skedDrive: newDriveList)
        {
            decimal x2rbcProjectedProcedures = skedDrive.sked_2RBC_Projected_Procedures__c != NULL ? skedDrive.sked_2RBC_Projected_Procedures__c : 0;
            decimal wbProjectedProcedures = skedDrive.sked_WB_Projected_Procedures__c != NULL ? skedDrive.sked_WB_Projected_Procedures__c : 0;
            decimal plasmaProjectedProcedures = skedDrive.sked_Plasma_Projected_Procedures__c != NULL ? skedDrive.sked_Plasma_Projected_Procedures__c : 0;
            decimal plateletProjectedProcedures = skedDrive.sked_Platelet_Projected_Procedures__c != NULL ? skedDrive.sked_Platelet_Projected_Procedures__c : 0;

            if(oldDriveMap != NULL)
            {
                if(oldDriveMap.get(skedDrive.id).sked_WB_Projected_Procedures__c != skedDrive.sked_WB_Projected_Procedures__c  
                   ||(oldDriveMap.get(skedDrive.id).sked_2RBC_Projected_Procedures__c != skedDrive.sked_2RBC_Projected_Procedures__c )
                   ||(oldDriveMap.get(skedDrive.id).sked_Platelet_Projected_Procedures__c != skedDrive.sked_Platelet_Projected_Procedures__c )
                   ||(oldDriveMap.get(skedDrive.id).sked_Plasma_Projected_Procedures__c != skedDrive.sked_Plasma_Projected_Procedures__c ))
                {
                    if(skedDrive.sked_Total_Procedures_Projected__c != NULL )
                    {
                        skedDrive.sked_Total_Procedures_Projected__c = x2rbcProjectedProcedures + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
                    }
                    if(skedDrive.sked_Total_Products_Projected__c != NULL)
                    {
                        skedDrive.sked_Total_Products_Projected__c = wbProjectedProcedures + (x2rbcProjectedProcedures * 2) +plateletProjectedProcedures + plasmaProjectedProcedures;
                    }  
                }
                  
            }
            
        }
    }
    //<<-[End] HRP-12170
    
    /*HRP-9815 --> Starts Here
    @Description : This method will update related op record's DRD Rep and DRD Rep Contact # whenever Drive owner gets changed
    */

    public static void populateDriveOwnerOnAmUpdate(Map<Id, sked_Drive__c> oldMap , List<sked_Drive__c> newList) {
        if(newList != NULL && !newList.isEmpty()) {
            for(sked_Drive__c newDrive : newList) {
                sked_Drive__c oldDrive = oldMap.get(newDrive.Id);
                if(oldDrive != NULL && oldDrive.Account_Manager__c != newDrive.Account_Manager__c) {
                    newDrive.sked_Drive_Owner__c = newDrive.Account_Manager__c;
                }
            }
        }
    }

    public static void updateDrdRepOnOpRecordUponOwnerChange(List<sked_Drive__c> newDriveList, Map<Id, sked_Drive__c> map_oldDriveId_oldDriveInfo) {
        Map<Id, String> map_driveId_driveOwner = new Map<Id, String>();
        if(newDriveList != NULL && !newDriveList.isEmpty()) {
            for(sked_Drive__c drive : newDriveList) {
                sked_Drive__c oldDrive = map_oldDriveId_oldDriveInfo != NULL && map_oldDriveId_oldDriveInfo.get(drive.Id) != NULL ? map_oldDriveId_oldDriveInfo.get(drive.Id) : new sked_Drive__c();
                if(oldDrive != NULL && (drive.sked_Drive_Owner__c != oldDrive.sked_Drive_Owner__c || drive.District_Manager__c != oldDrive.District_Manager__c)) {
                    if(drive.sked_Drive_Owner__c != NULL) {
                    	map_driveId_driveOwner.put(drive.Id, drive.sked_Drive_Owner__c);
                    } else {
                        map_driveId_driveOwner.put(drive.Id, drive.District_Manager__c);
                    }
                }
            }
        }
        if(map_driveId_driveOwner != NULL && !map_driveId_driveOwner.isEmpty()) {
            List<sked_Operation_Record__c> relatedOpRecords = [SELECT Id, sked_Drive__c, sked_DRD_Rep__c, sked_DRD_Rep_Contact__c
                                                               FROM sked_Operation_Record__c
                                                               WHERE sked_Drive__c IN :map_driveId_driveOwner.keySet()];
            if(relatedOpRecords != NULL && !relatedOpRecords.isEmpty()) {
                Map<Id, User> map_userId_user = new Map<Id, User>([SELECT Id, FirstName, LastName, WorkPhone__c FROM User WHERE Id IN :map_driveId_driveOwner.values()]);
                for(sked_Operation_Record__c opRecord : relatedOpRecords) {
                    if(map_driveId_driveOwner.get(opRecord.sked_Drive__c) != NULL) {
                        String DrdRep = map_userId_user.get(map_driveId_driveOwner.get(opRecord.sked_Drive__c)).FirstName + ' ' + map_userId_user.get(map_driveId_driveOwner.get(opRecord.sked_Drive__c)).LastName;
                        opRecord.sked_DRD_Rep__c = DrdRep;
                        opRecord.sked_DRD_Rep_Contact__c = map_userId_user.get(map_driveId_driveOwner.get(opRecord.sked_Drive__c)).WorkPhone__c;
                    } else {
                        opRecord.sked_DRD_Rep__c = null;
                        opRecord.sked_DRD_Rep_Contact__c = null;
                    }
                }
                Database.SaveResult[] opRecordUpdateResult = Database.update(relatedOpRecords, FALSE);
                List<BSF_Error_Log__c> errorlogEntry = BSF_Utilities.createErrorLogWithObjectId(
                    opRecordUpdateResult,
                    'Op Record DRD Rep  Contact # Update',
                    'DriveTriggerService',
                    'updateDrdRepOnOpRecordUponOwnerChange',
                    'Error',
                    'DRD Rep Contact # Update'
                );
                if(errorlogEntry != NULL && !errorlogEntry.isEmpty()) {
                    insert errorlogEntry;
                }
            }
        }
    }
    //HRP-9815 --> Ends Here

    //HRP-701 -> Starts Here
    public static void removeFirstTimeFlagUponDriveCompletion(List<sked_Drive__c> newDriveList, Map<Id, sked_Drive__c> map_oldDriveId_oldDrive) {
        Map<Id, sked_Drive__c> map_accountId_earliestCompletedDrive = new Map<Id, sked_Drive__c>();
        List<Opportunity> firstTimeDrivesExcludingEarliestCompletedDrive = new List<Opportunity>();

        for(sked_Drive__c newDrive : newDriveList) {
            sked_Drive__c oldDrive = map_oldDriveId_oldDrive.get(newDrive.Id);
            if(oldDrive != NULL && 
               newDrive.sked_Type_of_Drive__c == BSF_Constants.MOBILE_DRIVE &&
               newDrive.sked_Status__c != oldDrive.sked_Status__c && 
               newDrive.sked_Status__c == BSF_Constants.DOC_STATUS_COMPLETE
            ) {
                if (!map_accountId_earliestCompletedDrive.containsKey(newDrive.sked_Account__c)) {
                    map_accountId_earliestCompletedDrive.put(newDrive.sked_Account__c, newDrive);
                } else {
                    sked_Drive__c existingDrive = map_accountId_earliestCompletedDrive.get(newDrive.sked_Account__c);
                    if (existingDrive.sked_Drive_Date__c > newDrive.sked_Drive_Date__c) {
                        map_accountId_earliestCompletedDrive.put(newDrive.sked_Account__c, newDrive);
                    }
                }  
            }
        }

        Map<Id, Opportunity> map_oppId_firstTimeDrives = new Map<Id, Opportunity>(
            [SELECT Id, AccountId, Special_Circumstances__c
            FROM Opportunity
            WHERE AccountId IN :map_accountId_earliestCompletedDrive.keySet()
            AND Type_of_Drive__c = :BSF_Constants.MOBILE_DRIVE
            AND DriveStatus__c <> :BSF_Constants.DOC_STATUS_COMPLETE
            AND Special_Circumstances__c INCLUDES (:BSF_Constants.SSBS_BADGE_FIRST_TIME_DRIVE)]
        );

        for(Opportunity opp : map_oppId_firstTimeDrives.values()) {
            if(!map_accountId_earliestCompletedDrive.containsKey(opp.AccountId)) continue;

            if(opp.Id == map_accountId_earliestCompletedDrive.get(opp.AccountId).sked_Opportunity__c) {
                map_oppId_firstTimeDrives.remove(opp.Id);
            }
        }

        if(map_oppId_firstTimeDrives != NULL && !map_oppId_firstTimeDrives.isEmpty() && map_oppId_firstTimeDrives.size() > 100) {
            Database.executeBatch(new BSF_Batch_UpdateSpecialCircumstanceOnOpp('Removal', map_oppId_firstTimeDrives.values()), 100);
        } else {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            TriggerHandler.bypass('OpportunityTriggerHandler');
            skedHubBase.BypassUpdateTriggers = true;

            Database.SaveResult[] updateResults = Database.Update(BSF_Utilities.getOpportunitiesWithFirstTimeFlagRemoved(map_oppId_firstTimeDrives.values()), false);
            List<BSF_Error_Log__c> errorlogEntries = BSF_Utilities.createErrorLogWithObjectId(
                updateResults,
                'Removal of First Time Flag from Opportunities',
                'DriveTriggerService',
                'removeFirstTimeFlagUponDriveCompletion',
                'Error',
                'First Time Drive Flag Removal'
            );
            insert errorlogEntries;

            TriggerHandler.clearBypass('OpportunityTriggerHandler');
            skedHubBase.BypassUpdateTriggers = false;
        }

    }
    
    // Refactored: Events triggered post Drive Cancellation are now handled in skedDriveHandler
    /*HRP-701 -> Ends Here
    public static void handleTaskCancellation(List<sked_Drive__c> newDriveList, Map<Id, sked_Drive__c> oldDriveMap) {
        if(newDriveList == NULL || newDriveList.isEmpty() || oldDriveMap == NULL || oldDriveMap.isEmpty()) {
            return;
        }
        //Set<Id> oppIdsToCreateTasks = new Set<Id>();
        Set<Id> oppIdsToCancelTasks = new Set<Id>();
        for(sked_Drive__c newDrive : newDriveList) {
            sked_Drive__c oldDrive = oldDriveMap.get(newDrive.Id);
            if(newDrive.Id != NULL && oldDriveMap.containsKey(newDrive.Id) 
                    && newDrive.sked_Status__c != oldDrive.sked_Status__c
                    && newDrive.sked_Opportunity__c != NULL){
                        //if(newDrive.sked_Status__c == BSF_Constants.DOC_STATUS_CONFIRMED){
                            //oppIdsToCreateTasks.add(newDrive.sked_Opportunity__c);
                        if(newDrive.sked_Status__c == BSF_Constants.DOC_STATUS_CANCEL){
                            oppIdsToCancelTasks.add(newDrive.sked_Opportunity__c);
                        }

            }
        }
        /*if(!oppIdsToCreateTasks.isEmpty()) {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, OwnerId,
                                                                            Drive_Date__c,
                                                                            Account_Manager__c 
                                                                    FROM Opportunity 
                                                                    WHERE Id IN :oppIdsToCreateTasks]);
            TaskService.createOneWeekCheckInTasks(oppMap);
        }*/
        /*if(!oppIdsToCancelTasks.isEmpty()) {
            TaskService.cancelOpportunityTasks(oppIdsToCancelTasks);
        }

    }*/
}