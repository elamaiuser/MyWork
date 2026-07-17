/*@Description: 1. This class contains different Trigger methods working in different trigger contexts to support site object related functionalities
 *              2. This service class is called from Site Trigger Handler (Maintaining Trigger Framework)
 
 * NOTE : Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification on DOC (11418)
 * ***************************************************************************************************************************************************************/

 /* Modification Log 
 * Date					     Developer Name			     Comments
  **********************************************************************************************************************************************************************************
  6/8/2023				    Kishore Das			   Logic for HRP-10085(when room name/site building name changes the related opportunity/template/drives on calendar name changes)
  6/12/2023                 Priti Jana             Logic for HRP-9889
  3/8/2023				    Kishore Das		       Users other than System Admin should not have any delete record permissions(Logic for HRP-10572 --> Deleted)
  9/27/2023                 Priti Jana             Logic for HRP-10172
  11/16/2023			    Barnojit Sharma		   Unable to Inactivate Charlottesville Integrated Fixed Site record (HRP-11543)
  11/09/2023                Barnojit Sharma        Geolocations on Sites are being lost (HRP-10835)
  11/17/2023			    Barnojit Sharma		   Sites are missing county information (HRP-11099)
  1/15/2024                 Priti Jana             Logic for HRP-11418
  03/06/2024			    Balaji N		  	   logic for HRP-12136 (Method:getSiteBuildingNameChangedAccounts,updateDivesOnCalenderForSiteBuidlingNameChange;changes in opp name logic)
  03/08/2024			    Barnojit Sharma		   Update Chapter on the site when the zip code changes. (HRP-12045)
 ***********************************************************************************************************************************************************************************
*/

public with sharing class SiteService { 
    
    public static void updateInitialReviewer(List<sked__Location__c> newSites,  map<id,sked__Location__c> oldSiteMap) 
    {
        Set<String> allowedProfiles = new Set<String>{'APS Planner','APS Admin','APS Management'};
        //List<User> loggedInUser = [ SELECT ID , Profile.Name FROM User Where id = : UserInfo.getUserId() AND Profile.Name IN :allowedProfiles];
        String profileNameUserInfo = [SELECT Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        for(sked__Location__c site : newSites){
            if( oldSiteMap.get(site.Id).sked_National_Name__c == null && site.sked_National_Name__c != null){
                site.Initial_Reviewer__c = UserInfo.getUserId();
                site.National_Name_Status__c = System.Label.Initial_Review_Pending;
            }else if(site.National_Name_Status__c == System.Label.Second_Review_Pending && site.sked_National_Name__c != null && oldSiteMap.get(site.Id).sked_National_Name__c != null && site.sked_National_Name__c != oldSiteMap.get(site.Id).sked_National_Name__c){
                site.Initial_Reviewer__c = UserInfo.getUserId();
                site.National_Name_Status__c = System.Label.Initial_Review_Pending;
                site.National_Name_Initial_Review_Date__c = null;
            }else if(site.National_Name_Status__c == System.Label.Review_Completed && site.sked_National_Name__c != oldSiteMap.get(site.Id).sked_National_Name__c){
                if(!allowedProfiles.contains(profileNameUserInfo))
                {
                	site.adderror(System.Label.NationalNameCannotBeUpdatedAfterReview);  
                }
            }
        }
    }
    
    public static void updateOpportunitiesForSiteBuidlingNameChangeAsync(List<sked__Location__c> newSiteList, Map<Id, sked__Location__c> oldSiteMap) {
        Set<Id> siteIds = new Set<Id>();
        List<Opportunity> opportuntyUpdateList = new List<Opportunity>();

        if(newSiteList != null && !newSiteList.isEmpty()) {
            for (sked__Location__c newSite : newSiteList) {
                sked__Location__c oldSite = oldSiteMap?.get(newSite.Id);
                if ((newSite.Name != oldSite?.Name)) { //HRP-12136 sked_Site_Building_Name__c ---> Name
                    siteIds.add(newSite.Id);
                }
            }
        }
        
        if (!siteIds.isEmpty()) {
            opportuntyUpdateList = [
                SELECT Id, Name, Is_Template__c, 
                Drive_Site__c, Drive_Site_Name__c,
                Account_Name__c, Drive_Date__c,
                Account_Internal_Name__c, RecordTypeId,
                Is_Account_Internal_Name_Changed__c, Linked_Opportunity_Drives__c,
                Is_this_part_of_MultiDay_Drive__c
                FROM Opportunity 
                WHERE Drive_Site__c IN :siteIds 
                AND Is_Template__c = FALSE
            ];
            
            if(!system.isBatch() && !Test.isRunningTest() && !opportuntyUpdateList.isEmpty()) {
                UpdateOpportunityNameBatch batchOppRecs = new UpdateOpportunityNameBatch(opportuntyUpdateList, false, true);
                Database.executeBatch(batchOppRecs, 200);
            }
        }
    }
    
    /* Updating sked_Active__c = false when site end date = today
     * For future site end dates , BSF_Batch_UpdateSiteAsInactiveHelper will run everyday
     * As a part of HRP - 9276
     * */
     
    
    public static void inactiveSiteBasedOnEndDate(List<sked__Location__c> newSitesList, Map<Id, sked__Location__c> oldSiteMap)
    {
        List<sked__Location__c> siteTobeUpdated = new List<sked__Location__c>();
        Set<Id> siteIds = new Set<Id>();
        
        for(sked__Location__c newRec : newSitesList)
        {
			if(oldSiteMap != NULL && oldSiteMap.containsKey(newRec.Id))
			{
				if (newRec.sked_End_Date__c != oldSiteMap.get(newRec.id).sked_End_Date__c && newRec.sked_End_Date__c == system.today()) 
				{
                	siteIds.add(newRec.Id);
            	}
                /*
                * HRP-11543 changes starts here
                */
                if (newRec.sked_Active__c != oldSiteMap.get(newRec.id).sked_Active__c && newRec.sked_Active__c == false) 
				{
                	siteIds.add(newRec.Id);
            	}
                /*
                * HRP-11543 changes ends here
                */
			}
			
        }

		List<sked__Location__c> inactiveSiteList = [Select Id,sked_Active__c ,sked_End_Date__c from sked__Location__c where Id in :siteIds];
		if(inactiveSiteList.size() > 0)
		{
            for(sked__Location__c siteObj : inactiveSiteList)
            {
                siteObj.sked_Active__c = FALSE;
                siteObj.sked_End_Date__c = system.today(); //HRP-11543 changes
                siteTobeUpdated.add(siteObj);
            }
		}
        
        Database.SaveResult[] srList = Database.update(siteTobeUpdated , false);

	    // creating one entry in error log for the errors
        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'End Dating Site','SiteService','inactiveSiteBasedOnEndDate','Error','Error in deactivating site');
        Database.insert(logList,false);
	
    }
    
    /* Updating sked_Active__c = true when site end date > today or current site end date or null and sked_Active__c = false
     * As a part of HRP - 9276
     * */
     
    
    public static void siteActiveOnEndDateChange(List<sked__Location__c> newSitesList, Map<Id, sked__Location__c> oldSiteMap)
    {
        Set<Id> siteToBeActiveIds = new Set<Id>();
               
        for(sked__Location__c newRec : newSitesList)
        {
          if(oldSiteMap != NULL && oldSiteMap.containsKey(newRec.Id))
          {              
              sked__Location__c oldSiteRec = oldSiteMap.get(newRec.Id);
              
           	  if ((!oldSiteRec.sked_Active__c) && newRec.sked_End_Date__c != oldSiteRec.sked_End_Date__c 
                  && (newRec.sked_End_Date__c > system.today() || newRec.sked_End_Date__c > oldSiteRec.sked_End_Date__c || newRec.sked_End_Date__c == NULL))
              {
                  siteToBeActiveIds.add(newRec.Id);
              } 
          }              
              
       }
        if(!siteToBeActiveIds.isEmpty())
        {
            activateSites(siteToBeActiveIds);
        }
        
    }
    
    public static void activateSites(Set<Id> siteIdsToBeActivated)
    {
        List<sked__Location__c> siteListToBeActivated= new List<sked__Location__c>();
        
        siteListToBeActivated = [select Id , sked_Active__c from sked__Location__c where Id IN : siteIdsToBeActivated];
        
        if(!siteListToBeActivated.isEmpty())
        {
          for(sked__Location__c sObj : siteListToBeActivated)
          {
              sObj.sked_Active__c = true;
          }
        }
        
        Database.SaveResult[] srList = Database.update(siteListToBeActivated , false);
        
        // creating one entry in error log for the errors
        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Re-Activating Site','SiteService','siteActiveOnEndDateChange','Error','Error in reactivating site');
        Database.insert(logList,false);
    }
    
    /* While putting an end date to the site and if that site has future drives in a status other than withdrawn or cancelled
     * the user should be presented with a warning message - HRP - 6985
     * */
    
    public static void validateEndDateChangeOnSite(List<sked__Location__c> newSiteList , Map<Id,sked__Location__c> oldSiteMap)
    {
        Boolean isNotAllowedEndDateChange = FALSE;
        Map<Id,Date> newSiteEndDateByIdMap = new Map<Id,Date>();
        String errorMsg = 'Please make sure you cancel all drives on or after the designated site end date.';
        
        for(sked__Location__c newSiteObj :newSiteList)
        {
            sked__Location__c oldSiteObj = oldSiteMap?.get(newSiteObj.Id);
            if(newSiteObj.sked_End_Date__c!= NULL && newSiteObj.sked_End_Date__c!=oldSiteObj.sked_End_Date__c)
            {
                newSiteEndDateByIdMap.put(newSiteObj.Id, newSiteObj.sked_End_Date__c);
            }  
			/*
            * HRP-11543 changes starts here
            */
            else if(newSiteObj.sked_Active__c == false && newSiteObj.sked_Active__c!=oldSiteObj.sked_Active__c){
                newSiteEndDateByIdMap.put(newSiteObj.Id, system.Today());
            } 
            /*
            * HRP-11543 changes ends here
            */            
        }
        
        if(!newSiteEndDateByIdMap.isEmpty())
        {
            for(Opportunity relatedOpp : [Select Id,Drive_Date__c,Drive_Site__c,StageName 
                                      	  from Opportunity 
                                      	  where Drive_Site__c IN :newSiteEndDateByIdMap.keySet() 
                                          and StageName NOT IN ('Cancelled', 'Withdrawn')])
        	{
            	if(relatedOpp.Drive_Date__c >= newSiteEndDateByIdMap.get(relatedOpp.Drive_Site__c))
            	{
                	isNotAllowedEndDateChange = TRUE;
                    break;
            	}
        	}
        }
                
        for(sked__Location__c newSiteObj :newSiteList)
        {
            if(isNotAllowedEndDateChange)
            {
                newSiteObj.addError(errorMsg);                
            }
            
        }
        
    }
    /* 
    * HRP-9585 changes starts here
    * @Description: New Sites autopopulate "ADD" to National Name field.
    * @Date: 02/05/2023
    */
    public static void updateNationalName(List<sked__Location__c> newSites) 
    {
        if(newSites != null){
            for(sked__Location__c site : newSites){
                if(String.isBlank(site.sked_National_Name__c)){
                    site.sked_National_Name__c = 'ADD';
                }
            }
        }
    }
    /*
    * HRP-9585 changes Ends
    */
    
    
    //Logic for HRP-10085 for Template and Opportunity ***starts here***
    public static void updateTemplateOpportunitiesForSiteBuidlingNameChange(List<sked__Location__c> sites,Map<Id, sked__Location__c> oldSiteMap) {
        Map<Id,sked__Location__c> nameChangedSiteMap =new Map<Id,sked__Location__c>();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        
        if(sites == null || oldSiteMap == null || sites.isEmpty() || oldSiteMap.isEmpty()){
            return;
        } 
        for(sked__Location__c st : sites){
            if(!oldSiteMap.containsKey(st.Id) || oldSiteMap.get(st.Id) == null){ 
                continue;
            }
            if((String.isNotBlank(st.sked_Site_Building_Name__c) && !st.sked_Site_Building_Name__c.equals(oldSiteMap.get(st.Id).sked_Site_Building_Name__c))
                    ||(String.isNotBlank(st.sked_Room_Name__c) && !st.sked_Room_Name__c.equals(oldSiteMap.get(st.Id).sked_Room_Name__c))){
                        nameChangedSiteMap.put(st.Id,st);
                        
            }
        }
        
        if(!nameChangedSiteMap.isEmpty()){
            oppMap = new Map<Id,Opportunity>([SELECT Id
                        FROM Opportunity 
                        WHERE Drive_Site__c IN :nameChangedSiteMap.Keyset() 
                        AND Is_Template__c = true]);
             
            System.debug('oppMap: '+oppMap);
        }
        if(!system.isBatch() && !oppMap.isEmpty()) {
        	//UpdateOpportunityNameBatch batchOppRecs = new UpdateOpportunityNameBatch(oppMap.values());
        	//Database.executeBatch(batchOppRecs, 200);
            futureBlankUpdate(oppMap.Keyset());
        }
    }
     //Logic for HRP-10085 for Template and Opportunity ***ends here***
     
    
    //Logic for HRP-10085 for Drives on calendar ***starts here***
    public static void updateDivesOnCalenderForSiteBuidlingNameChange(List<sked__Location__c> sites,Map<Id, sked__Location__c> oldSiteMap)
    {
        

        Map<Id,sked__Location__c> nameChangedSiteMap =new Map<Id,sked__Location__c>();
        if(sites == null || oldSiteMap == null || sites.isEmpty() || oldSiteMap.isEmpty()){
            return;
        } 
        for(sked__Location__c st : sites){
            if(!oldSiteMap.containsKey(st.Id) || oldSiteMap.get(st.Id) == null){
                continue;
            }
            //commented part of HRP-12136
            /*if((String.isNotBlank(st.sked_Site_Building_Name__c) && !st.sked_Site_Building_Name__c.equals(oldSiteMap.get(st.Id).sked_Site_Building_Name__c))
                    ||(String.isNotBlank(st.sked_Room_Name__c) && !st.sked_Room_Name__c.equals(oldSiteMap.get(st.Id).sked_Room_Name__c)))*/
            //commented part of HRP-12136
            if(String.isNotBlank(st.Name) && !st.Name.equals(oldSiteMap.get(st.Id).Name)){//HRP-12136 condition change
                        nameChangedSiteMap.put(st.Id,st);
                        
            }
        }
        
         
        List<sked_Drive__c> DrivesList=[SELECT Id,
                                        Name,
                                        sked_Account__c,
                                        sked_Account__r.name,
                                        sked_Account__r.Internal_Name__c,
                                        sked_Drive_Site__c
                                        FROM sked_Drive__c 
                                        WHERE sked_Drive_Site__c IN :nameChangedSiteMap.Keyset()];
            
        for(sked_Drive__c sdc : DrivesList){
            String drivenameNew = '';
            
            if(sdc.sked_Account__r != null && nameChangedSiteMap.get(sdc.sked_Drive_Site__c) != null){
                drivenameNew = sdc.sked_Account__r.name + ', ';
                driveNameNew += nameChangedSiteMap.get(sdc.sked_Drive_Site__c).Name;//HRP-12136
                //commented part of HRP-12136
                /*if(String.isNotBlank(nameChangedSiteMap.get(sdc.sked_Drive_Site__c).sked_Room_Name__c)){
                    drivenameNew = drivenameNew + '-' + nameChangedSiteMap.get(sdc.sked_Drive_Site__c).sked_Room_Name__c;
                }*/
                 //commented part of HRP-12136
                sdc.Name = driveNameNew.length() > 80 ? driveNameNew.substring(0, 75) + ' ...' : driveNameNew; //HRP-12136 changed; Prev drivenameNew.length() > 80 ? drivenameNew.substring(0,80) : drivenameNew ;
            }
        }
        if(!DrivesList.isEmpty())
        {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
            //HRP-12136 start
            TriggerHandler.bypass('DriveTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
        	skedHubBase.BypassUpdateTriggers = true;
            //HRP-12136 End
            List<Database.SaveResult> saveResults = Database.update(DrivesList,false);
            //HRP-12136 start
            skedHubBase.BypassInsertTriggers = false;
        	skedHubBase.BypassUpdateTriggers = false;
            TriggerHandler.clearBypass('DriveTriggerHandler');
            //HRP-12136 End
            for(Database.SaveResult sr : saveResults){
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) 
				    {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Drives fields that affected this error: ' + err.getFields());
				    }
                }
            }
        }
    }
    //Logic for HRP-10085 for Drives on calendar ***ends here***
    
    
    //Part of Logic for HRP-10085 ***starts here***(futureBlankUpdate method is called from updateTemplateOpportunitiesForSiteBuidlingNameChange method)
    @future 
    public static void futureBlankUpdate(Set<Id> oppIds) {
        List<Opportunity> oppRec = [SELECT Id FROM Opportunity WHERE Id IN:oppIds];
        system.debug('oppRec '+oppRec);
            List<Database.SaveResult> saveResults = Database.update(oppRec,false); 
            for(Database.SaveResult sr : saveResults){
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) 
				    {
                        System.debug('The following error has occurred.');                   
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Drives fields that affected this error: ' + err.getFields()); 
				    }
                }
            }
    }
	//Part of Logic for HRP-10085  ***ends here***(futureBlankUpdate method is called from updateTemplateOpportunitiesForSiteBuidlingNameChange method)
	
    // Logic- This trigger validation won't allow users to change operation type after drive generation (Exclusing Cancelled drives)
    
    // HRP - 9889 ----> Starts Here
    public static void validateOperationTypeChange(List<sked__Location__c> newSitesList, Map<Id, sked__Location__c> oldSiteMap)
    {
        Set<Id> siteIdsForReview = new Set<Id>();
        Set<Id> siteIdRelatedToDrives = new Set<Id>();
        String siteRecordTypeName;        
        
        if(oldSiteMap != null && !newSitesList.isEmpty())
        {
            for(sked__Location__c sites : newSitesList)
            {
                siteRecordTypeName = Schema.SObjectType.sked__Location__c.getRecordTypeInfosById().get(sites.RecordTypeId).getName();
                
                // Bypass the checks for mobile sites as Operation Type is not applicable to them
                 if(!String.isBlank(oldSiteMap.get(sites.Id).Operation_Type__c) && siteRecordTypeName != NULL)
                 {
                	if(siteRecordTypeName == BSF_Constants.FIXED_SITE_RECORD_TYPE && !sites.Operation_Type__c.equals(oldSiteMap.get(sites.Id).Operation_Type__c) && !string.isBlank(sites.Operation_Type__c))
                	{
                    	siteIdsForReview.add(sites.Id);
                	} 
                 }
            }
        }

        List<sked_Drive__c> driveListRelatedToSite = [select Id, sked_Opportunity__c, sked_Status__c,
                                                            sked_Drive_Site__c from sked_Drive__c
                                                            where sked_Drive_Site__c in :siteIdsForReview
                                                            and sked_Status__c != :BSF_Constants.DOC_STATUS_CANCEL];
        if(!driveListRelatedToSite.isEmpty())
        {
            for(sked_Drive__c doc : driveListRelatedToSite)
            {
                siteIdRelatedToDrives.add(doc.sked_Drive_Site__c); 
            }
           
        }

        for(sked__Location__c newSite : newSitesList)
        {
            if(siteIdRelatedToDrives.contains(newSite.Id)) // Checking if the site id is present in the set containing drive sites related to drives
            {
                newSite.addError(system.label.Restrict_Operation_Type_Change_Error_Msg);                
            }
        }        
    }

    // HRP - 9889 ---> Ends Here
     
    /* HRP-10172 --> Starts Here
        @Description : This trigger validation won't let users (except System and Global admin users) change site's physical location type 
                       if any completed / future planned drives are tied to that site
    */
    public static void validatePhysicaLocationTypeChange(String objectName, String changeType,List<sked__Location__c> newSiteList, Map<Id,sked__Location__c> oldSiteMap)
    {
        Set<Id> siteIdsToReview = new Set<Id>();
        Set<Id> sitesNotToBeUpdated = new Set<Id>();
        List<String> adminProfileNames = new List<String>();

        // Quering the custom metadata 
        Admin_Profile_Setting__mdt adminProfileSetting = [SELECT Field_Name__c,Profile_Name__c, Error_Msg__c FROM Admin_Profile_Setting__mdt 
                                                          WHERE Object_Name__c = :objectName
                                                          AND Change_Type__c = :changeType
                                                          AND Field_Name__c = 'sked_Physical_Location_Type__c'
                                                          AND Is_Checked__c = true 
                                                          LIMIT 1];
        
        adminProfileNames = adminProfileSetting.Profile_Name__c.split(',');

        Map<Id,Profile> adminProfileIdToNameMap = new Map<Id,Profile>([SELECT Id, Name FROM Profile WHERE Name IN :adminProfileNames]);

        if(!adminProfileIdToNameMap.containsKey(UserInfo.getProfileId()))
        {
            if(!newSiteList.isEmpty())
            {
                for(sked__Location__c sites : newSiteList)
                {
                    String newValue = (String)sites.get(adminProfileSetting.Field_Name__c);
                    
                    sked__Location__c oldSite = oldSiteMap?.get(sites.Id);

                    String oldValue = oldSite!= NULL ? (String)oldSite.get(adminProfileSetting.Field_Name__c) : NULL;
                    
                    if(oldValue != NULL && !newValue.equals(oldValue))
                    {
                        siteIdsToReview.add(sites.Id);
                    }                                  
                }
            }
        }

        //Quering drives related to this site
        List<Opportunity> drivesRelatedToSite = [SELECT Id,Is_Template__c ,Drive_Site__c                                                                                   
                                                 FROM Opportunity
                                                 WHERE Drive_Site__c IN :siteIdsToReview
                                                 AND ((StageName != :BSF_Constants.STAGE_CANCELLED AND Is_Template__c = FALSE)
                                                 OR (Is_Template__c = TRUE AND Template_Status__c =:BSF_Constants.ACTIVE_TEMPLATE))];


        // Bulkifying
        if(drivesRelatedToSite.size() > 0)
        {
            for(Opportunity driveObj : drivesRelatedToSite)
            {
                sitesNotToBeUpdated.add(driveObj.Drive_Site__c);
            }
        }
        
        for(sked__Location__c siteObj : newSiteList)
        {
            // Checking if that particluar site has any booked drives
            if(!sitesNotToBeUpdated.isEmpty() && sitesNotToBeUpdated.contains(siteObj.Id))
            {
                siteObj.addError(adminProfileSetting.Error_Msg__c);
            }
        }
    }
    // HRP-10172 --> Ends Here
	/*
    * HRP-10835 changes starts here
    */
    public static void checkSiteAddress(Map<Id, sked__Location__c> oldMap , Map<Id, sked__Location__c> newMap){
        if(newMap == null || newMap.isEmpty()){
            return;
        }
        for(Id siteId : newMap.keySet()){
            if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(siteId)
                    && compareText(newMap.get(siteId).sked_Address_1__c,oldMap.get(siteId).sked_Address_1__c,false)
                    && compareText(newMap.get(siteId).sked_Address_2__c,oldMap.get(siteId).sked_Address_2__c,true)
                    && compareText(newMap.get(siteId).sked_City__c,oldMap.get(siteId).sked_City__c,false)
                    && compareText(newMap.get(siteId).sked_State__c,oldMap.get(siteId).sked_State__c,false)
                    && compareText(newMap.get(siteId).sked_Zip_Code__c,oldMap.get(siteId).sked_Zip_Code__c,false)
                    && oldMap.get(siteId).sked__GeoLocation__Latitude__s != null
                    && oldMap.get(siteId).sked__GeoLocation__Longitude__s != null
                    && newMap.get(siteId).sked__GeoLocation__Latitude__s == null
                    && newMap.get(siteId).sked__GeoLocation__Longitude__s == null){
                        newMap.get(siteId).sked__GeoLocation__Latitude__s = oldMap.get(siteId).sked__GeoLocation__Latitude__s;
                        newMap.get(siteId).sked__GeoLocation__Longitude__s = oldMap.get(siteId).sked__GeoLocation__Longitude__s;
            }
            //HRP-12533[Start->>]
             if(newMap.get(siteId).sked__GeoLocation__Longitude__s != null && (newMap.get(siteId).sked__Geolocation__Longitude__s < -180
             		|| newMap.get(siteId).sked__Geolocation__Longitude__s >= -30) || newMap.get(siteId).sked__GeoLocation__Latitude__s != null && (newMap.get(siteId).sked__GeoLocation__Latitude__s > 71 || newMap.get(siteId).sked__GeoLocation__Latitude__s < 25
             		)){
                        
                		newMap.get(siteId).addError('Geolocation must be in North America');
            }
            //HRP-12533[End->>]
        }
    }
    private static Boolean compareText(String val1, String val2, Boolean nullPass){
        Boolean result = false;
        if(nullPass == true && String.isBlank(val1) && String.isBlank(val2)){
            result = true;
        }
        if(String.isNotBlank(val1) && String.isNotBlank(val2)){
            val1 = val1.trim();
            val2 = val2.trim();
            if(val1.equalsIgnoreCase(val2)){
                result = true;
            }
        }
        return result;
    }
    /*
    * HRP-10835 changes ends here
    */
    /*
    * HRP-11099 changes starts here
    */
    public static void updateSiteCountry(Map<Id, sked__Location__c> oldMap, List<sked__Location__c> newList){
        if(newList == null || newList.isEmpty()){
            return;
        }
        List<sked__Location__c> siteToBeUpdated = new List<sked__Location__c>();
        for(sked__Location__c site : newList){
            if(String.isNotBlank(site.sked_City__c) && String.isNotBlank(site.sked_State__c)
                    && (oldMap == null || oldMap.isEmpty() || !oldMap.containsKey(site.Id)
                    || site.sked_City__c != oldMap.get(site.Id).sked_City__c 
                    || site.sked_State__c != oldMap.get(site.Id).sked_State__c)){
                        siteToBeUpdated.add(site);
            }
        }
        if(!siteToBeUpdated.isEmpty()){
            Map<String, String> countyMap = new Map<String, String>();
            List<Independent_Cities__mdt> countyMetadata = [SELECT MasterLabel, 
                                                                    State__c, 
                                                                    County_Name__c 
                                                            FROM Independent_Cities__mdt
                                                            WHERE Active__c = true];
            for(Independent_Cities__mdt mtdt : countyMetadata){
                String key = mtdt.MasterLabel.trim().toLowerCase() + '-' + mtdt.State__c.trim().toUpperCase();
                key = key.replace(' ','_');
                countyMap.put(key,mtdt.County_Name__c);
            }
            for(sked__Location__c site : newList){
                if(siteToBeUpdated.contains(site)){
                    String countryName = getCountyName(countyMap,site.sked_City__c,site.sked_State__c);
                    if(String.isNotBlank(countryName)){
                        site.sked_County__c = countryName;
                    }
                }
            }
        }
    }
    private static String getCountyName(Map<String, String> countyMap, String city, String state){
        String key = city.trim().toLowerCase() + '-' + state.trim().toUpperCase();
        key = key.replace(' ','_');
        if(!countyMap.isEmpty() && countyMap.containsKey(key)){
            return countyMap.get(key).trim();
        }else{
            return '';
        }
    }
    /*
    * HRP-11099 changes ends here
    */
    /*
    * HRP-12045 changes starts here
    */
    public static void updateSiteChapter(List<sked__Location__c> newList , Map<Id, sked__Location__c> oldMap){
        Map<String, Id> zipCodesVsChapterIdMap = new Map<String, Id>();
        if(newList != null && !newList.isEmpty()){
            for(sked__Location__c site : newList){
                if(String.isNotBlank(site.sked_Zip_Code__c) && (oldMap == null 
                        || (oldMap != null && !oldMap.isEmpty() && site.Id != null && oldMap.containsKey(site.Id)
                        && oldMap.get(site.Id).sked_Zip_Code__c != site.sked_Zip_Code__c))){
                            String zipCode = site.sked_Zip_Code__c.trim();
                            zipCode = zipCode.length() > 5 ?  zipCode.left(5) :  zipCode;                         
                            zipCodesVsChapterIdMap.put(zipCode,null);
                }
            }
        }
        System.debug('zipCodesVsChapterIdMap1 : '+zipCodesVsChapterIdMap);
        if(!zipCodesVsChapterIdMap.isEmpty()){
            for(Chapter_Blood_Region_Zip_Match__c chapterZipMatch : [SELECT Id, 
                                                                            Chapter__c,
                                                                            Chapter__r.Type__c,
                                                                            Zip__c
                                                                    FROM Chapter_Blood_Region_Zip_Match__c
                                                                    WHERE Zip__c IN :zipCodesVsChapterIdMap.keySet()
                                                                    AND Chapter__c != null
                                                                    AND Chapter__r.Type__c = 'Chapter'
                                                                    ORDER BY CreatedDate ASC]){
                zipCodesVsChapterIdMap.put(chapterZipMatch.Zip__c.trim(),chapterZipMatch.Chapter__c);
            }
        }
        System.debug('zipCodesVsChapterIdMap2 : '+zipCodesVsChapterIdMap);
        if(newList != null && !newList.isEmpty() && !zipCodesVsChapterIdMap.isEmpty()){
            for(sked__Location__c site : newList){
                if(String.isNotBlank(site.sked_Zip_Code__c)){
                    String zipCode = site.sked_Zip_Code__c.trim();
                    zipCode = zipCode.length() > 5 ?  zipCode.left(5) :  zipCode;     
                    if(zipCodesVsChapterIdMap.containsKey(zipCode)){
                        site.Chapter__c = zipCodesVsChapterIdMap.get(zipCode);
                    }
                }else{
                    site.Chapter__c = null;
                }
                System.debug('site.Chapter__c : '+site.Chapter__c);
            }
        }
    }
    /*
    * HRP-12045 changes ends here
    */

    /*
    * HRP-11270 changes Starts
    * Populate Site Type (sked__Type__c) from the Site's record type so the field is
    * never left NULL.
    */
    private static Map<Id, String> recordTypeIdToSiteType;

    private static Map<Id, String> getRecordTypeIdToSiteType() {
        if (recordTypeIdToSiteType == null) {
            // Record type Name -> valid sked__Type__c picklist value
            Map<String, String> nameToPicklist = new Map<String, String>{
                BSF_Constants.FIXED_SITE_RECORD_TYPE  => BSF_Constants.SITE_TYPE_FIXED,
                BSF_Constants.MOBILE_SITE_RECORD_TYPE => BSF_Constants.SITE_TYPE_MOBILE
            };
            recordTypeIdToSiteType = new Map<Id, String>();
            for (Schema.RecordTypeInfo rtInfo :
                    sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosById().values()) {
                if (nameToPicklist.containsKey(rtInfo.getName())) {
                    recordTypeIdToSiteType.put(rtInfo.getRecordTypeId(), nameToPicklist.get(rtInfo.getName()));
                }
            }
        }
        return recordTypeIdToSiteType;
    }

    public static void populateSiteType(List<sked__Location__c> newSites) {
        if (newSites == null) {
            return;
        }
        Map<Id, String> rtToSiteType = getRecordTypeIdToSiteType();
        for (sked__Location__c site : newSites) {
            if (String.isBlank(site.sked__Type__c)
                    && site.RecordTypeId != null
                    && rtToSiteType.containsKey(site.RecordTypeId)) {
                site.sked__Type__c = rtToSiteType.get(site.RecordTypeId);
            }
        }
    }
    /* HRP-11270 changes Ends */
}