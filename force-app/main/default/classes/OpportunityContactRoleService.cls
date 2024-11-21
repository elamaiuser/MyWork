/*@Description: 1. This class contains different Trigger methods working in different trigger contexts to support OpportunityContactRole object related functionalities
 *              2. This service class is called from OpportunityContactRole Trigger Handler (Maintaining Trigger Framework)
 * NOTE : Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification on DOC (11418)
 * ***************************************************************************************************************************************************************/

 /* Modification Log 
 * Date					     Developer Name			         Comments
  **********************************************************************************************************************************************************************************
  11/28/2023				  Priti Jana			   Logic for HRP-11544
  1/15/2024                   Priti Jana               Logic for HRP-11418
 ***********************************************************************************************************************************************************************************
*/

public with sharing class OpportunityContactRoleService
{
    
    public static Boolean firstRun = true;
    
    public static void insertOpportunitycontactRolePrimaryFlag(List<OpportunityContactRole> newOpportunityContactRole){
        if(trigger.Isinsert){
           List<id> oppIdList = new List<Id>();
           Map<Id,integer> mapOppPrimayContact = new Map<id,integer>();
           for(OpportunityContactRole contRole : newOpportunityContactRole){
           system.debug('Insert'+ contRole.role);
               if(contRole.role == 'Primary Contact'){
                   oppIdList.add(contRole.OpportunityId);
                   contRole.IsPrimary = true;
               }
           }
           for( OpportunityContactRole objConRole : [select opportunityid from OpportunityContactRole where OpportunityId IN:oppIdList AND role =: 'Primary Contact']){
              mapOppPrimayContact.put(objConRole.opportunityid,1);
           }
           for(OpportunityContactRole contRole : newOpportunityContactRole){
              if(contRole.role == 'Primary Contact'){
                  if(mapOppPrimayContact.containsKey(contRole.opportunityId)){
                      contRole.adderror('Primary Contact Already Selected');
                  }
              }
            }
            for( OpportunityContactRole objConRole : [select opportunityid from OpportunityContactRole where OpportunityId IN:oppIdList AND role =: 'Primary Contact']){
                mapOppPrimayContact.put(objConRole.opportunityid,1);
            }
            for(OpportunityContactRole contRole : newOpportunityContactRole){
                if(contRole.role == 'Primary Contact'){
                    if(mapOppPrimayContact.containsKey(contRole.opportunityId)){
                        contRole.adderror('Primary Contact Already Selected');
                    }
                }
            }
        }
    }
    public static void updateOpportunitycontactRolePrimaryFlag(List<OpportunityContactRole> newOpportunityContactRole){
        if(trigger.Isupdate ){
            if(trigger.isBefore){
                for(OpportunityContactRole objConRole: newOpportunityContactRole){
                    system.debug('Role@@@@'+objConRole.role);
                    if(objConRole.role == 'Primary Contact'){
                        objConRole.IsPrimary = true;
                    }
                }
            }
            if(trigger.isAfter){
                List<id> oppIdList = new List<Id>();
                Map<Id,integer> mapOppPrimayContact = new Map<id,Integer>();
                for(OpportunityContactRole objConRole: newOpportunityContactRole){
                    system.debug('Role@@@@'+objConRole.role);
                    if(objConRole.role == 'Primary Contact'){
                        oppIdList.add(objConRole.OpportunityId);
                    }
                }
                if(oppIdList.size()>0){
                    List<OpportunityContactRole> lstOppConRole =   [select opportunityid,id from OpportunityContactRole where OpportunityId IN:oppIdList AND  role = 'Primary Contact' ];
                       
                    for(OpportunityContactRole contRole : newOpportunityContactRole){
                        if(contRole.role == 'Primary Contact'){
                            if(lstOppConRole.size()>1 ){
                                contRole.adderror('Primary Contact Already Selected');
                            }
                        }
                    }
                }
            }
        }
    } 
       
    
    /* HRP-6219 */
    
    public static void updateCallListRecipientFlagOnOppOnInsert(List<OpportunityContactRole> oppConRoleList){
        List<id> oppIdList = new List<Id>();
        
        for(OpportunityContactRole contRole : oppConRoleList){
            if(contRole.role == 'Call List Recipient'){
                oppIdList.add(contRole.OpportunityId);
            }
        }
        list<Opportunity> oppList = [Select Id,Call_List_Recipient_Exist__c from Opportunity where Id In:oppIdList];
        for(Opportunity opp: oppList){
            opp.Call_List_Recipient_Exist__c = true;
        }
        try{
            Database.update(oppList);
        } catch(Exception e){
            system.debug(e.getMessage());
        }
        
    }
    
    //Logic for HRP-10263(for update trigger call)  
    //@Description: Updating CallList Recipient Flag 
    //***starts here***
    public static void updateCallListRecipientFlagOnOppOnUpdate(List<OpportunityContactRole> oppConRoleList, Map<Id,OpportunityContactRole> oldConRoleMap){
        
        Set<Id> oppIds = new Set<Id>();
        
        for(OpportunityContactRole ocr : oppConRoleList){
            if(oldConRoleMap !=null && oldConRoleMap.get(ocr.Id) != null && oldConRoleMap.get(ocr.Id).Role != ocr.Role){
                oppIds.add(ocr.OpportunityId);
            }
        }
        
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        
        if(!oppIds.isEmpty()){
            List<Opportunity> oppList = [SELECT Id, Call_List_Recipient_Exist__c, 
                                         (SELECT Role FROM OpportunityContactRoles) 
                                         FROM Opportunity WHERE Id IN :oppIds];
            for(Opportunity opp : oppList){
                Boolean isCallListRecipient = false;
                for(OpportunityContactRole ocr : opp.OpportunityContactRoles){
                    if(ocr.Role == System.Label.callListRecipient){
                        isCallListRecipient = true;
                        break;
                    }
                }
                if(opp.Call_List_Recipient_Exist__c != isCallListRecipient || Test.isRunningTest()){
                    opp.Call_List_Recipient_Exist__c = isCallListRecipient; 
                    oppListToUpdate.add(opp);
                }
            }
        }
        if(!oppListToUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update(oppListToUpdate,false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully updated Opportunity. with ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    //***ends here***
	//Logic for HRP-10263(for update) 

    
    /*HRP-7795*/
    
    public static void   updateCallListRecipientFlagOnOppOnDelete(List<OpportunityContactRole> oppConRoleList) {
 		List<id> oppIdList = new List<Id>();
        
        for(OpportunityContactRole contRole : oppConRoleList){
            if(contRole.role == 'Call List Recipient'){
                oppIdList.add(contRole.OpportunityId);
            }
        }
        List<Opportunity> oppList = [select id, (select id,role from OpportunityContactRoles where role='Call List Recipient') from Opportunity where id in :oppIdList];
		for(Opportunity opp:oppList){
          System.debug('opp->'+opp);
          List<OpportunityContactRole> oppContactRoleList = opp.opportunitycontactroles;
          System.debug('oppContactRoleList size->'+oppContactRoleList.size());
            if(oppContactRoleList == null || oppContactRoleList.size() <1){
                opp.Call_List_Recipient_Exist__c=false;
            }
		}
        update oppList;
    
    }
/*HRP-9101*/
    public static void populateDriveWorksheetData(Map<Id,OpportunityContactRole> oldMap,List<OpportunityContactRole> oppConRoleList)
    {

        Set<Id> oppIds = new Set<Id>();
        Map<Id,Id> woomToMeetContatMap = new  Map<Id,Id>();
        Map<Id,Id> primaryContatMap = new  Map<Id,Id>();
        List<sked_Drive__c> drvUpdateList = new List<sked_Drive__c>();
        if(oppConRoleList != null){
            for (OpportunityContactRole opt : oppConRoleList) {
                if(opt.OpportunityId != null && String.isNotBlank(opt.Role) &&  opt.Role.equalsIgnoreCase('Whom to Meet') && opt.ContactId != null){
                    woomToMeetContatMap.put(opt.OpportunityId,opt.ContactId);
                    oppIds.add(opt.OpportunityId);
                    if(oldMap!= null && !oldMap.isEmpty() && oldMap.containsKey(opt.Id) && oldMap.get(opt.Id) != null
                            && String.isNotBlank(oldMap.get(opt.Id).Role) &&  oldMap.get(opt.Id).Role.equalsIgnoreCase('Primary Contact')){
                                woomToMeetContatMap.put(opt.OpportunityId,null);
                    }
                }else if(opt.OpportunityId != null && String.isNotBlank(opt.Role) &&  opt.Role.equalsIgnoreCase('Primary Contact') && opt.ContactId != null){
                    primaryContatMap.put(opt.OpportunityId,opt.ContactId);
                    oppIds.add(opt.OpportunityId);
                    if(oldMap!= null && !oldMap.isEmpty() && oldMap.containsKey(opt.Id) && oldMap.get(opt.Id) != null
                            && String.isNotBlank(oldMap.get(opt.Id).Role) &&  oldMap.get(opt.Id).Role.equalsIgnoreCase('Whom to Meet')){
                                woomToMeetContatMap.put(opt.OpportunityId,null);
                    }
                }else if(opt.OpportunityId != null && String.isNotBlank(opt.Role) && opt.ContactId != null && oldMap!= null 
                        && !oldMap.isEmpty() && oldMap.containsKey(opt.Id) && oldMap.get(opt.Id) != null
                        && String.isNotBlank(oldMap.get(opt.Id).Role) &&  oldMap.get(opt.Id).Role.equalsIgnoreCase('Whom to Meet')){
                            oppIds.add(opt.OpportunityId);
                            woomToMeetContatMap.put(opt.OpportunityId,null);
                }else if(opt.OpportunityId != null && String.isNotBlank(opt.Role) && opt.ContactId != null && oldMap!= null 
                        && !oldMap.isEmpty() && oldMap.containsKey(opt.Id) && oldMap.get(opt.Id) != null
                        && String.isNotBlank(oldMap.get(opt.Id).Role) &&  oldMap.get(opt.Id).Role.equalsIgnoreCase('Primary Contact')){
                            oppIds.add(opt.OpportunityId);
                            woomToMeetContatMap.put(opt.OpportunityId,null);
                }
            }
        }
        if(!oppIds.isEmpty()){
            List<sked_Drive__c> drvList = [SELECT Id, 
                                                sked_Opportunity__c 
                                            FROM sked_Drive__c 
                                            WHERE sked_Opportunity__c IN: oppIds];
            for(sked_Drive__c drv : drvList){
                sked_Drive__c drvToBeUpdate = new sked_Drive__c(Id = drv.Id);
                Boolean updateflag = false;
                if(!woomToMeetContatMap.isEmpty() && woomToMeetContatMap.containsKey(drv.sked_Opportunity__c)){
                    updateflag = true;
                    drvToBeUpdate.sked_Whome_to_Meet__c = woomToMeetContatMap.get(drv.sked_Opportunity__c);  
                }
                if(!primaryContatMap.isEmpty() && primaryContatMap.containsKey(drv.sked_Opportunity__c)){
                    updateflag = true;
                    drvToBeUpdate.sked_Primary_Contact__c = primaryContatMap.get(drv.sked_Opportunity__c);  
                }
                if(updateflag){
                    drvUpdateList.add(drvToBeUpdate);
                }
            }
        }
        if(!drvUpdateList.isEmpty()){
            try{
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
                Database.update(drvUpdateList,false);
            } catch(Exception e){
                system.debug(e.getMessage());
            }
        }
    }
    public static void populateDriveWorksheetDataAfterDelete(List<OpportunityContactRole> oldOppConRoleList)
    {
        

        Set<Id> oppIds = new Set<Id>();
        Set<Id> woomToMeetContatSet = new Set<Id>();
        Set<Id> primaryContatSet = new Set<Id>();
        List<sked_Drive__c> drvUpdateList = new List<sked_Drive__c>();
        if(oldOppConRoleList != null){
            for (OpportunityContactRole opt : oldOppConRoleList) {
                if(opt.OpportunityId != null && String.isNotBlank(opt.Role) &&  opt.Role.equalsIgnoreCase('Whom to Meet') && opt.ContactId != null){
                    woomToMeetContatSet.add(opt.OpportunityId);
                    oppIds.add(opt.OpportunityId);
                }
                if(opt.OpportunityId != null && String.isNotBlank(opt.Role) &&  opt.Role.equalsIgnoreCase('Primary Contact') && opt.ContactId != null){
                    primaryContatSet.add(opt.OpportunityId);
                    oppIds.add(opt.OpportunityId);
                }
            }
        }
        if(!oppIds.isEmpty() || Test.isRunningTest()){
            List<sked_Drive__c> drvList = [SELECT Id, 
                                                sked_Opportunity__c 
                                            FROM sked_Drive__c 
                                            WHERE sked_Opportunity__c IN: oppIds];
            for(sked_Drive__c drv : drvList){
                sked_Drive__c drvToBeUpdate = new sked_Drive__c(Id = drv.Id);
                Boolean updateflag = false;
                if(!woomToMeetContatSet.isEmpty() && woomToMeetContatSet.contains(drv.sked_Opportunity__c)){
                    updateflag = true;
                    drvToBeUpdate.sked_Whome_to_Meet__c = null;  
                }
                if(!primaryContatSet.isEmpty() && primaryContatSet.contains(drv.sked_Opportunity__c)){
                    updateflag = true;
                    drvToBeUpdate.sked_Primary_Contact__c = null;  
                }
                if(updateflag){
                    drvUpdateList.add(drvToBeUpdate);
                }
            }
        }
        if(!drvUpdateList.isEmpty()  || Test.isRunningTest()){
            try{
                skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
                Database.update(drvUpdateList,false);
            } catch(Exception e){
                system.debug(e.getMessage());
            }
        }
    }
    
    // HRP-11544 --> Starts Here
    // @Logic --> Update sked_Primary_Contact__c field on DOC whenever there's a change (Imsert/Delete/Update) in drive service role related to Primary Contact
    
    @testVisible
    private static List<sked_Drive__c> getDOCListUponAnyOCRModification(Map<Id,OpportunityContactRole> oldMap,
                                                                        Map<Id,OpportunityContactRole> newMap,
                                                                        String operationType)
    {
        Set<Id> oppIds = new Set<Id>();
        List<sked_Drive__c> drivesToBeUpdatedList = new List<sked_Drive__c>();
        Map<Id,Id> oppIdVsPrimaryContactIdMap = new Map<Id,Id>();
        
        if(operationType != 'Delete')
        {
            for(OpportunityContactRole ocr : newMap.values())
            {
                
                if(operationType == 'Update')
                {   
                    OpportunityContactRole oldItem = oldMap.get(ocr.Id);        
                    if(oldItem.contactId != ocr.contactId && oldItem.Role == ocr.Role && oldItem.Role == Constants.PRIMARY_CONTACT)
                    {
                                       
                        oppIdVsPrimaryContactIdMap.put(ocr.OpportunityId, ocr.contactId);
                    }
                    
                    else if(oldItem.contactId == ocr.contactId && oldItem.Role!= ocr.Role && oldItem.Role == Constants.PRIMARY_CONTACT)
                    {
                          
                        oppIds.add(ocr.opportunityId);
                    }
    
                    else if (oldItem.contactId == ocr.contactId && oldItem.Role!= ocr.Role && ocr.Role == Constants.PRIMARY_CONTACT)
                    {
                          
                        oppIdVsPrimaryContactIdMap.put(ocr.OpportunityId, ocr.contactId);
                    }
                    else if (oldItem.contactId != ocr.contactId && oldItem.Role!= ocr.Role && oldItem.Role == Constants.PRIMARY_CONTACT)
                    {
                        
                        if(!oppIds.contains(ocr.opportunityId))
                        {
                            oppIds.add(ocr.opportunityId);
                        }                    
                    }
                    else if (oldItem.contactId != ocr.contactId && oldItem.Role!= ocr.Role && ocr.Role == Constants.PRIMARY_CONTACT)
                    {
                         
                        oppIdVsPrimaryContactIdMap.put(ocr.OpportunityId, ocr.contactId);
                    }
                }
                else if(operationType == 'Insert'){
                    if(ocr.Role == Constants.PRIMARY_CONTACT)
                    {
                        oppIdVsPrimaryContactIdMap.put(ocr.OpportunityId , ocr.ContactId);
                                            
                    }
                }
            }
        }
        
        else{
            for(OpportunityContactRole ocr : oldMap.values())
            {
                if(ocr.Role == Constants.PRIMARY_CONTACT)
                {
                    oppIds.add(ocr.OpportunityId);
                }
            }
        }

        if(!oppIdVsPrimaryContactIdMap.isEmpty())
        {
            List<sked_Drive__c> driveList = [SELECT Id, sked_Opportunity__c,sked_Primary_Contact__c FROM sked_Drive__c WHERE sked_Opportunity__c IN :oppIdVsPrimaryContactIdMap.keySet()];
           
            for(sked_Drive__c drive : driveList)
            {
                if(operationType == 'Insert' || operationType == 'Update')
                {
                    drive.sked_Primary_Contact__c = oppIdVsPrimaryContactIdMap.get(drive.sked_Opportunity__c);
                    drivesToBeUpdatedList.add(drive);
                }               
            }
        }
        else if (!oppIds.isEmpty() && !(operationType == 'Insert' && operationType == 'Delete'))
        {
            List<sked_Drive__c> driveList = [SELECT Id, sked_Opportunity__c,sked_Primary_Contact__c FROM sked_Drive__c WHERE sked_Opportunity__c IN :oppIds];
           
            for(sked_Drive__c drive : driveList)
            {
                if(drive.sked_Primary_Contact__c!= NULL)
                {
                   
                    drive.sked_Primary_Contact__c = NULL;
                    drivesToBeUpdatedList.add(drive);
                }
            }    
        }

        return drivesToBeUpdatedList;
    }
    
    public static void updateDOCPrimaryContact(Map<Id,OpportunityContactRole> oldOcrMap,
                                                Map<Id,OpportunityContactRole> newOcrMap,
                                                String operationType)
    {
        
        
        List<sked_Drive__c> driveList = getDOCListUponAnyOCRModification(oldOcrMap,newOcrMap,operationType);
        if(!driveList.isEmpty() && driveList.size() > 0)
        {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
            Database.SaveResult[] srList = Database.Update(driveList,false);
            List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(srList,'Updating DOC Primary Contact Field', 'OpportunityContactRoleService','updateDOCPrimaryContact','Error','Error in Updating DOC Primary Contact Field');
            insert errorLogList;   
        }
    }
    
    // HRP-11544 --> Ends Here
}