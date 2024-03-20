/* NOTE : Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification using different profiles on DOC (11418)
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 
 *  03/08/2023				 Kishore Das		        Users other than System Admin should not have any delete record permissions(Logic for HRP-10572-->Deleted)
 *  18/08/2023				 Kishore Das				Logic for HRP-10765(Ready for National Name Review True when associated drive in Tentative status)

 *  09/20/2023				 Krapy Tuli					Logic for HRP-10359 (Update AM, DM, AM Portfolio and DM Portfolio)
 *  11/09/2023               Barnojit Sharma            Validation added to stop referring two DOC to a single BDO. (HRP-11326)
 *  12/27/2023				 Kishore Das		        Logic for HRP-11605(Newly created FS BDO's are reflecting as tentative when the DOC is reflecting as confirmed (out of sync))
 *  12/27/2023				 Barnojit Sharma		    The current 56 day validation rule that triggers when trying to change Drive Date will also be added to the Drive on Calendar. (HRP-11640)
 *  1/9/2024                 Priti Jana                 Logic for HRP-10882
 *  2/1/2024		         Fitsum Worku				Updated logic for 56 day rule so that 56th day itself is considered eligible (HRP-12034); also exculding cancelled drives
 *************************************************************************************************************************************************
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
        Map<Id, Integer> OpportunityMap = new Map<Id, Integer>();
        if(newList == null || newList.isEmpty()){
            return;
        }
        for(sked_Drive__c drv : newList){
            if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(drv.Id)
                    && oldMap.get(drv.Id).sked_Opportunity__c != null
                    && oldMap.get(drv.Id).sked_Opportunity__c != drv.sked_Opportunity__c){
                        drv.addError('BDO can not be changed/removed.');
            }else if(drv.sked_Opportunity__c != null && !drv.sked_Is_Surrogate__c
                    && (oldMap == null || oldMap.isEmpty() || (oldMap.containsKey(drv.Id)
                    && oldMap.get(drv.Id).sked_Opportunity__c == null))){
                        OpportunityMap.put(drv.sked_Opportunity__c,0);
            }
        }
        if(!OpportunityMap.isEmpty()){
            for(AggregateResult ar : [SELECT Count(Id), 
                                            sked_Opportunity__c 
                                        FROM sked_Drive__c 
                                        WHERE sked_Opportunity__c IN : OpportunityMap.keySet()
                                        AND sked_Is_Surrogate__c = false
                                        GROUP BY sked_Opportunity__c]){
                OpportunityMap.put((Id)ar.get('sked_Opportunity__c'),Integer.valueOf(ar.get('expr0')));
            }
            for(sked_Drive__c drv : newList){
                if(drv.sked_Opportunity__c != null && !drv.sked_Is_Surrogate__c
                        && OpportunityMap.get(drv.sked_Opportunity__c) > 0
                        && (oldMap == null || oldMap.isEmpty() || (oldMap.containsKey(drv.Id)
                        && oldMap.get(drv.Id).sked_Opportunity__c == null))){
                            drv.addError('DOC has been generated for this BDO.');
                }
            }
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
            Database.SaveResult[] updateResults = Database.update(oppListToUpdate, false);
            
            for (Database.SaveResult updateResult : updateResults) {
                if (updateResult.isSuccess()) {
                    System.debug('Record Successfully updated: ' + updateResult.getId());
                } else {
                    for (Database.Error error : updateResult.getErrors()) {
                        System.debug('Record Update Failed: ' + error);
                    }
                }
            }
        }
    }

    //Logic for HRP-11605 ***Ends here***
    /*
    * HRP-11640 changes starts here
    */
    public static void checkAccept56DaysVoilation(Map<Id, sked_Drive__c> oldMap, List<sked_Drive__c> newItems) {
        if(newItems == null || newItems.isEmpty() || oldMap == null || oldMap.isEmpty()){
            return;
        }
        Map<Id,Id> oppVsDocMap = new Map<Id,Id>();
        Map<Id,Id> docVsAccMap = new Map<Id,Id>();
        Map<Id,List<Date>> accVsDriveDateMap = new Map<Id,List<Date>>();
        for(sked_Drive__c doc : newItems){
            if(doc.sked_Opportunity__c != null && doc.sked_Drive_Date__c != null && oldMap.containsKey(doc.Id) 
                    && (doc.sked_Drive_Date__c != oldMap.get(doc.Id).sked_Drive_Date__c
                    || (String.isNotBlank(doc.sked_Status__c) && doc.sked_Status__c != oldMap.get(doc.Id).sked_Status__c
                    && (doc.sked_Status__c.equalsIgnoreCase('Confirmed') || doc.sked_Status__c.equalsIgnoreCase('Complete'))))){
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
}