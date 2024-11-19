/***************************************************************************************************************************************
 * 
 * Description:      	Used to identify Non Integrated WB jobs for drives that are 6 weeks out
 * 						where the job start and end times might be incorrect due to previous
 * 						bugs with the system.  The goal is to identify these drive ahead of time and fix 
 * 						the issue by generating a DCR.
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/19/24     Fitsum Worku        Initial Code Creation
 * 
 ************************************************************************************************************************************/

global class GetDrivesWithIncorrectJobTimesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Set<Id> driveIds = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Integer numOfDays = Integer.valueOf(System.Label.Generate_DCR_For_Drives_Days_To_Add);
        Date driveDate = System.Today().AddDays(numOfDays);
        sked_Role_Time_Detail__c roleTimeDetail = new sked_Role_Time_Detail__c();
                
        //Get a list of Jobs where Drive Date 6 weeks out, Operation Type = Non Integrated WB, and Drive Status is not Cancel or Complete
        return Database.getQueryLocator ([SELECT Id, name, sked_Lead_Time__c, sked_Setup_Time__c, sked_Travel_Time__c, 
                                   sked_Site_Logistics_To__c, sked_Breakdown_Time__c, sked_Wrap_up_Time__c, 
                                   sked_Travel_Time2__c, sked_Site_Logistics_Back__c, sked__Finish__c, sked__Start__c,sked_Asset_Type__c, sked__Type__c,
                                   sked_Drive__c,
                                   sked_Drive__r.sked_Drive_Site__c, sked_Drive__r.sked_Drive_Site__r.sked_Timezone__c,
                                   sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c,
                                   sked_Drive__r.sked_Collection_Operation__r.sked_No_Travel_Time__c, sked_Drive__r.sked_Drive_Shift_Count__c, 
                                   sked_Drive__r.sked_Collection_Operation__r.sked_Breakdown_Time_Threshold__c, sked_Drive__r.sked_Collection_Operation__r.sked_Setup_Time_Threshold__c,
                                   sked_Drive_Shift__c, 
                                   sked_Drive_Shift__r.sked_Lunch_Break__c, 
                                   sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c, sked_Drive_Shift__r.sked_Lunch_Break_Duration__c, 
                                   sked_Drive_Shift__r.sked_Start_Time__c, sked_Drive_Shift__r.sked_End_Time__c
                                   FROM sked__job__c 
                                   WHERE sked_Asset_Type__c = NULL AND
                                         sked_Drive__r.sked_Drive_Date__c > :driveDate AND
                                         sked_Drive__r.sked_Drive_Site__r.Operation_Type__c = 'Non Integrated WB' AND 
                                         sked_Drive__r.sked_Status__c <> 'Cancel' AND
                                         sked_Drive__r.sked_Status__c <> 'Complete']);  
    }
    
    global void execute(Database.BatchableContext bc, List<sked__job__c> jobs) {
		 
        system.debug('### size of jobs ' + jobs.size());
        
		sked_Role_Time_Detail__c roleTimeDetail = new sked_Role_Time_Detail__c();
        //Capture a set of SiteIds to use for querying role time variances        
        Set<Id> siteIds = new Set<Id>();
        for(sked__job__c job : jobs) {
            siteIds.add(job.sked_Drive__r.sked_Drive_Site__c);
        }
             
        //Get role time details for Non Integrated WB.  Non Integrated WB uses a global role time detail
        List<sked_Role_Time_Detail__c> roleTimeDetails = [SELECT Id, sked_Effective_Start_Date__c, sked_Effective_End_Date__c, 
                                                          sked_Lead_Time__c, sked_Setup_Time__c, sked_Breakdown_Time__c, sked_Wrap_up_Time__c,
                                                          sked_Fixed_Site_Operation_Type__c
                                                          FROM sked_Role_Time_Detail__c
                                                          WHERE sked_Drive_Type__c = 'Fixed Site' AND
                                                          sked_Fixed_Site_Operation_Type__c = 'Non Integrated WB' AND
                                                          sked_Type__c = 'Global'];
        if(!roleTimeDetails.isEmpty()) {
        	roleTimeDetail = roleTimeDetails[0];
        }

		//Get role time variances for the sites        
        List<sked_Role_Time_Variance__c> roleTimeVariances = [SELECT Id, sked_Buffer_Type__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Location__c,
                                                              sked_Resource_Role_Group__c, sked_Variance_Applies_to__c, sked_Variation_Amount__c, sked_Variation_Type__c 
                                                              FROM sked_Role_Time_Variance__c
                                                              WHERE sked_Location__c IN :siteIds];
        Map<Id, List<sked_Role_Time_Variance__c>> siteRtvMap = new Map<Id, List<sked_Role_Time_Variance__c>>();   
        for (sked_Role_Time_Variance__c rtv : roleTimeVariances) {
             if(!siteRtvMap.containsKey(rtv.sked_Location__c)) {
                siteRtvMap.put(rtv.sked_Location__c, new List<sked_Role_Time_Variance__c> { rtv });
            }
            else {
                siteRtvMap.get(rtv.sked_Location__c).add(rtv);
            }
        }
        
        //Evaluate each job record
        for(sked__job__c job : jobs) {                
            //Clone the original job record.  This will be used to compare current job record values to newly generated values
            sked__job__c clonedJob = job.clone(false, true);
            
			//Zero out the values
            job.sked_Lead_Time__c = 0;
            job.sked_Breakdown_Time__c = 0;
            job.sked_Setup_Time__c = 0;
            job.sked_Wrap_up_Time__c = 0;
            job.sked_Site_Logistics_Back__c = 0; 
            job.sked_Site_Logistics_To__c = 0; 
            job.sked_Travel_Time__c = 0;
            job.sked_Travel_Time2__c = 0;
            
            //Add values from the role time detail record
            if(roleTimeDetail != null) {
                job.sked_Lead_Time__c = roleTimeDetail.sked_Lead_Time__c != NULL ? roleTimeDetail.sked_Lead_Time__c : 0;
                job.sked_Breakdown_Time__c= roleTimeDetail.sked_Breakdown_Time__c != NULL ? roleTimeDetail.sked_Breakdown_Time__c : 0;
                job.sked_Setup_Time__c = roleTimeDetail.sked_Setup_Time__c != NULL ? roleTimeDetail.sked_Setup_Time__c : 0;
                job.sked_Wrap_up_Time__c = roleTimeDetail.sked_Wrap_up_Time__c != NULL ? roleTimeDetail.sked_Wrap_up_Time__c : 0;
            }
 
            //Get travel time flags from the collection operation
            Boolean isTravelTimeIncludedForAllRoles = (job.sked_Drive__r.sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c == 'All Roles');
            Boolean skipTravelTime = job.sked_Drive__r.sked_Collection_Operation__r.sked_No_Travel_Time__c;
            
           	//Apply any role time variances that might exist for the job's site
            if(!siteRtvMap.isEmpty() && siteRtvMap.containsKey(job.sked_Drive__r.sked_Drive_Site__c)) {
                for(sked_Role_Time_Variance__c rtv : siteRtvMap.get(job.sked_Drive__r.sked_Drive_Site__c)) {
                    if(rtv.sked_Effective_Start_Date__c <= job.sked_Drive__r.sked_Drive_Date__c && rtv.sked_Effective_End_Date__c >= job.sked_Drive__r.sked_Drive_Date__c) {
                        decimal amount = rtv.sked_Variation_Amount__c;
                        set<string> appliesTo = new set<string>();
                        appliesTo.addAll(rtv.sked_Variance_Applies_to__c.split(';'));
                        
                        if (rtv.sked_Buffer_Type__c == 'Subtract') {
                            amount = -1 * amount;
                        }
                        if (appliesTo.contains('Lead Time')) {
                            job.sked_Lead_Time__c += amount;
                        }
                        if (appliesTo.contains('Setup Time')) {
                            job.sked_Setup_Time__c += amount;
                        }
                        if (appliesTo.contains('Breakdown Time')) {
                            job.sked_Breakdown_Time__c += amount;
                        }
                        if (appliesTo.contains('Wrap-up Time')) {
                            job.sked_Wrap_up_Time__c += amount;
                        }
                        if ((appliesTo.contains('Travel Time To')) && (isTravelTimeIncludedForAllRoles) && (!skipTravelTime)) { 
                            job.sked_Travel_Time__c += amount;
                        }
                        if ((appliesTo.contains('Travel Time From')) && (isTravelTimeIncludedForAllRoles) && (!skipTravelTime)) { 
                            job.sked_Travel_Time2__c += amount;
                        }  
                        if (appliesTo.contains('Site Logistics To')) 
                        {
                            job.sked_Site_Logistics_To__c += amount;
                        }
                        if (appliesTo.contains('Site Logistics Back'))
                        {
                            job.sked_Site_Logistics_Back__c += amount;
                        } 
                    }
                }
            }
	
            //Determine how much time needs to be deducted from the shift start time
            //Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(job.sked_Drive_Shift__r.sked_Start__c, job.sked_Drive_Shift__r.sked_Finish__c);
            //system.debug('### lead time ' + job.sked_Lead_Time__c);
            //system.debug('### setup time ' + job.sked_Setup_Time__c);
            //system.debug('### travel time ' + job.sked_Travel_Time__c);
            //system.debug('### site logistics ' + job.sked_Site_Logistics_To__c);
                
            Decimal durationBeforeDrawHours = job.sked_Lead_Time__c + job.sked_Setup_Time__c + job.sked_Travel_Time__c + job.sked_Site_Logistics_To__c;     
            //system.debug('### durationBeforeDrawHours ' + durationBeforeDrawHours);
            if(job.sked_Drive_Shift__r.sked_Lunch_Break__c && job.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c) {
                durationBeforeDrawHours += job.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c;
                  //system.debug('### durationBeforeDrawHours with lunch break ' + durationBeforeDrawHours);
            }            
            //Determine how much time needs to be added to the shift end time
            decimal durationAfterDrawHours = job.sked_Breakdown_Time__c + job.sked_Wrap_up_Time__c + job.sked_Travel_Time2__c + job.sked_Site_Logistics_Back__c;
			//system.debug('### durationAfterDrawHours ' + durationAfterDrawHours);
        
            Datetime drawStartTime = DateTime.newInstanceGMT(job.sked_Drive__r.sked_Drive_Date__c, job.sked_Drive_Shift__r.sked_Start_Time__c);
            Datetime drawEndTime = DateTime.newInstanceGMT(job.sked_Drive__r.sked_Drive_Date__c, job.sked_Drive_Shift__r.sked_End_Time__c);
            
            //system.debug('### drawStartTime prior to duration before ' + drawStartTime + ' >> this will be taken off ' + durationBeforeDrawHours);
            DateTime jobStart = drawStartTime.addMinutes(integer.valueOf(-durationBeforeDrawHours));   
            //system.debug('### drawStartTime prior to duration before ' + jobStart);
            DateTime jobEnd = drawEndTime.addMinutes(integer.valueOf(durationAfterDrawHours));
            //Convert per site timezone
            string toTimeZoneSidId = job.sked_Drive__r.sked_Drive_Site__r.sked_Timezone__c;
            job.sked__Start__c = skedDateTimeUtils.switchTimezone(jobStart, TimeZone.getTimeZone('GMT').getId(), toTimeZoneSidId);
            job.sked__Finish__c = skedDateTimeUtils.switchTimezone(jobEnd, TimeZone.getTimeZone('GMT').getId(), toTimeZoneSidId);
                 
            //if(job.sked_Asset_Type__c != null && job.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT) {
            //    job.sked__Start__c = jobStart;
            //    job.sked__Finish__c = jobEnd;
            //}
            
            /*system.debug('### original job start time ' + clonedJob.sked__Type__c + ' : ' + clonedJob.sked__start__c);
            system.debug('### new job start time ' + job.sked__Type__c + ' : ' + job.sked__start__c);
           	system.debug('### original job finish time ' + clonedJob.sked__Type__c + ' : ' + clonedJob.sked__Finish__c);
            system.debug('### new job finish time ' + job.sked__Type__c + ' : ' + job.sked__Finish__c);*/
       
            
            if(job.sked__start__c <> clonedJob.sked__start__c || job.sked__Finish__c <> clonedJob.sked__Finish__c) {
                if(!driveIds.contains(job.sked_Drive__c)) {
                	driveIds.add(job.sked_Drive__c);
                }
            }
        }
        
		Set<Id> drivesWithDCR = new Set<Id>();
        for(sked_Drive_Change_Request__c dcr : [SELECT Id, sked_Status__c, sked_Drive__c
                                                FROM sked_Drive_Change_Request__c
                                                WHERE sked_Drive__c IN :driveIds
                                                AND (sked_Status__c = 'Pending' 
                                                      OR sked_Status__c = 'Submitted' 
                                                      OR sked_Status__c = 'Waiting for DM Approval' 
                                                      OR sked_Status__c = 'DM Waiting for DRD Feedback' 
                                                      OR sked_status__c = 'Waiting for APS Approval' 
                                                	  OR Sked_Status__c = 'APS Waiting for DRD Feedback')]) {                                         
			drivesWithDCR.add(dcr.sked_Drive__c);
		}
        if(!driveIds.isEmpty() && !drivesWithDCR.isEmpty()) {
            driveIds.removeAll(drivesWithDCR);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        system.debug('### inside finish Jobs with incorrect times ' + driveIds.size() + '\n ' + driveIds);
        //string csvString = '';
        //for(Id driveId : driveIds) {
        //    csvString = csvString+driveId+'\n';
        //}
        //system.debug('### List: ' + csvString);
        
        List<sked_Drive__c> drives = [SELECT Id, Name, sked_Type_of_Drive__c, sked_Drive_Date__c, sked_Start_Time__c, sked_Status__c, sked_Drive_Site__c, sked_Drive_Site__r.Operation_Type__c
                                      FROM sked_Drive__c WHERE Id in :driveIds];
        
        string csvString = 'Drive Id, Drive Name, Drive Type, Drive Date, Drive Start Time, Drive Status, Site, Operation Type\n';
        for(sked_Drive__c drive : drives) {
            csvString = csvString+drive.Id+','+drive.Name+','+drive.sked_Type_of_Drive__c+','+drive.sked_Drive_Date__c+','+drive.sked_Start_Time__c+','+drive.sked_Status__c+','+drive.sked_Drive_Site__c+','+drive.sked_Drive_Site__r.Operation_Type__c+'\n';
        }
        system.debug('###csvString = ' + csvString);
        
        if(!driveIds.isEmpty()) {
       		GetDrivesForDCRBatch batchDrivesForDCR = new GetDrivesForDCRBatch(driveIds);
        	Database.executeBatch(batchDrivesForDCR, 200);
    	}
    }
}