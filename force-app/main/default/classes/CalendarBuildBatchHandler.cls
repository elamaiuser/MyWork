/**************************************************************************************************************************************
 * 
 * Description:     This is a handler class for the "Calendar Build" batch class "CalendarBuildEvaluateDrivesBatch.cls".
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/28/21     Fitsum Worku        Initial Code Creation 
 * 07/26/23     Fitsum Worku		Updates per HRP-10179 set Accept_56_Day_Rule_Violation__c to true by default, 
 * 									set a value for drive_keyword__c, and don't set drive_status__c for calendar build opportunities
 * 12/27/23     Barnojit Sharma		As per HRP-11640 When creating a New Opportunity as part of Calendar Build, the 56 day violation 
                                   	checkbox should not be checked and it will come from the Template.
 * 2/5/2024		Priti Jana			Logic for HRP-11814
 * 02/27/24     Anil K              HRP-12141-Default accept 56 day violation to true for cloned  fixed site opportunities
 * 06/07/24	    Priti Jana		    Logic for HRP-12011
 * 08/06/24     Priti Jana          Logic for HRP-12706
 * 09/09/24		Balaji N			Logic for HRP-13265
 * 12/10/24     Priti Jana          Logic for HRP-13190
 * 01/08/25     Priti Jana          Logic for HRP-12299
 * 03/04/25     Priti Jana          Logic for HRP-11850
 **************************************************************************************************************************************/

 public with sharing class CalendarBuildBatchHandler {
    
    //Method takes in a list of opportunities from the batch process i.e. drives that have been completed or cancelled
    //x days ago.  It clones the opportunities and designates them as qualified or unqualified based on some criteria.
    public static List<Opportunity> cloneDrives(List<Opportunity> lstOpportunities) {
        List<Opportunity> lstClonedOpps = new List<Opportunity>();
		Set<Id> oppIdsSet = new Set<Id>(); //Set of the opportunity ids
        Set<Id> driveSiteIds = new Set<Id>(); //HRP-11814
        Set<Id> parentTemplateIdsSet = new Set<Id>(); //Set of the parent template ids
        Map<Id,Id> oppIdVsDriveSiteIdMap = new Map<Id,Id>(); //HRP-11814

        //Get record type Id for Mobile and Fixed opps
        Id mobileOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId();
        Id fixedOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId();

        for(Opportunity opp : lstOpportunities) {
            oppIdsSet.add(opp.Id);
            parentTemplateIdsSet.add(opp.Parent_Template_Id__c);
            driveSiteIds.add(opp.Drive_Site__c); //HRP-11814 
        }

        //Get the "days from drive date" configuration item from the custom metadata.  This will be used to calculate the 
        //targeted ask date for mobile drives
        Opportunity_Date_Setting__mdt mdtOppDateSetting = Opportunity_Date_Setting__mdt.getInstance('Targeted_Ask_Date');
        Integer numNumOfAskDays = mdtOppDateSetting?.Days_from_Drive_Date__c.intValue();
        
        List<Drive_Marketing_Programs__c> graySkiesAffiliationList = [SELECT Id, Marketing_Program__c, Blood_Drive_Opportunity__c FROM Drive_Marketing_Programs__c 
                                                                      WHERE Marketing_Program__r.Name = 'Gray Skies' AND Blood_Drive_Opportunity__c in :oppIdsSet];
        Map<Id, Id> oppWithGraySkiesMap = new Map<Id, Id>();
        For(Drive_Marketing_Programs__c dmp : graySkiesAffiliationList) {
            oppWithGraySkiesMap.put(dmp.Blood_Drive_Opportunity__c, dmp.Id);
        }
        
        // Get the related site's physical location type - HRP-11814
        Map<Id,sked__Location__c> driveSiteMap = new Map<Id,sked__Location__c>([SELECT Id, sked_Physical_location_type__c FROM sked__Location__c WHERE ID IN :driveSiteIds]);
                
        //Get the projections from the parent template
        List<Opportunity> parentTemplateOpportunityList = [SELECT Id, Anticipated_Registered_Donors__c, WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Drive_Site__c,
                                                           Start_Time__c, End_Time__c, Accept_56_Day_Rule_Violation__c, AcceptblankMilitaryAuthNamePhone__c, Direct_Donors_To__c,
                                                           No_Publicity_Needed__c, Open_to_Public__c, Drive_Keyword__c, Publish_to_Call_Center__c, Web_Scheduling_Enabled__c,
                                                           Send_Emails__c, Send_Mailers__c, Web_Scheduling_End_Date_Offset__c, Web_Scheduling_End_Time_Offset__c, 
                                                           Web_Scheduling_Start_Date_Offset__c, Platelet_Projected_Procedures__c, Plasma_Pheresis_Projected_Procedures__c,
                                                           Flow_End_Time_Field__c, Flow_Start_Time_Field__c, Type, //HRP=11814
                                                           APT_Quantity__c, APT_Required__c, //HRP-13190
                                                           Red_Cross_Volunteer_Quantity__c, Red_Cross_Volunteer_Required__c //HRP-13146
                                                           FROM Opportunity WHERE Id in :parentTemplateIdsSet];
        
        Map<Id, Opportunity> oppWithParentTemplateMap = new Map<Id, Opportunity>();
        for(Opportunity parentOpp : parentTemplateOpportunityList) {
            oppWithParentTemplateMap.put(parentOpp.Id, parentOpp);
            oppIdVsDriveSiteIdMap.put(parentOpp.Id, parentOpp.drive_site__c); //HRP-11814
        }
        
        for(Opportunity origOpp : lstOpportunities) {
            //Clone the opportunity and update some fields; by default preserveId is false i.e the ID is cleared for the new record.  isDeepClone is set to true
            Opportunity clonedOpp = origOpp.clone(false, true);
            clonedOpp.source__c = origOpp.Source__c;
            clonedOpp.Booking_Strategy__c = origOpp.Booking_Strategy__c;
            clonedOpp.Calendar_Build_Parent_Opportunity__c = origOpp.id;
            DateTime dT = Helper.getSameDayOfNextYear(origOpp.drive_date__c);
            clonedOpp.drive_date__c = Date.newInstance(dT.year(), dT.month(), dT.day());
            clonedOpp.Number_of_2RBC_Assets__c = origOpp.Number_of_2RBC_Assets__c != null ? origOpp.Number_of_2RBC_Assets__c : 0;
            clonedOpp.Number_of_Plasma_Assets__c = origOpp.Number_of_Plasma_Assets__c != null ? origOpp.Number_of_Plasma_Assets__c : 0;
            clonedOpp.Number_of_Platelet_Assets__c = origOpp.Number_of_Platelet_Assets__c != null ? origOpp.Number_of_Platelet_Assets__c : 0;
            clonedOpp.Platelet_Projected_Procedures__c = origOpp.Platelet_Projected_Procedures__c != null ? origOpp.Platelet_Projected_Procedures__c : 0;
            clonedOpp.Plasma_Pheresis_Projected_Procedures__c = origOpp.Plasma_Pheresis_Projected_Procedures__c != null ? origOpp.Plasma_Pheresis_Projected_Procedures__c : 0;
            //clonedOpp.Accept_56_Day_Rule_Violation__c = true; //HRP-10179 // Commented for HRP-11640
            if(!oppWithParentTemplateMap.isEmpty() && oppWithParentTemplateMap.containsKey(origOpp.Parent_Template_Id__c)){         
            	clonedOpp.WB_Projected_Procedures__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).WB_Projected_Procedures__c != null ? 
                    								   oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).WB_Projected_Procedures__c : 0;
            	clonedOpp.X2RBC_Projected_Procedures__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).X2RBC_Projected_Procedures__c != null ? 
                    									  oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).X2RBC_Projected_Procedures__c : 0;
                clonedOpp.Drive_Site__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Drive_SIte__c;
                clonedOpp.Start_Time__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Start_Time__c;
                clonedOpp.End_Time__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).End_Time__c;
                clonedOpp.Flow_End_Time_Field__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Flow_End_Time_Field__c;
                clonedOpp.Flow_Start_Time_Field__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Flow_Start_Time_Field__c;
                clonedOpp.Accept_56_Day_Rule_Violation__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Accept_56_Day_Rule_Violation__c; //HRP-11640
                clonedOpp.AcceptblankMilitaryAuthNamePhone__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).AcceptblankMilitaryAuthNamePhone__c;
                clonedOpp.Direct_Donors_To__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Direct_Donors_To__c;
                clonedOpp.No_Publicity_Needed__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).No_Publicity_Needed__c;
                clonedOpp.Open_to_Public__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Open_to_Public__c;
                clonedOpp.Drive_Keyword__c = clonedOpp.Drive_Keyword__c == null? oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Drive_Keyword__c:clonedOpp.Drive_Keyword__c;//HRP-13265
                clonedOpp.Publish_to_Call_Center__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Publish_to_Call_Center__c;
                clonedOpp.Web_Scheduling_Enabled__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_Enabled__c;
                clonedOpp.Send_Emails__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Send_Emails__c;
                clonedOpp.Send_Mailers__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Send_Mailers__c;
                clonedOpp.Web_Scheduling_End_Date_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_End_Date_Offset__c;
                clonedOpp.Web_Scheduling_End_Time_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_End_Time_Offset__c;
                clonedOpp.Web_Scheduling_Start_Date_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_Start_Date_Offset__c;
                clonedOpp.Web_Scheduling_Start_Date_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_Start_Date_Offset__c;
            	clonedOpp.APT_Required__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).APT_Required__c; //HRP-13190
                clonedOpp.APT_Quantity__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).APT_Quantity__c; //HRP-13190
            }
            //HRP-12011 --> Starts Here
            if(origOpp.Slot_Generator__c != NULL) {
                clonedOpp.Slot_Generator__c = origOpp.Slot_Generator__c.intValue(); 
            }
            //HRP-12011 --> Ends Here
                
            // Start HRP-10179
            if(clonedOpp.Open_to_Public__c == 'No' && String.isEmpty(clonedOpp.Drive_Keyword__c)) {
                clonedOpp.Drive_Keyword__c = System.label.CB_DRIVE_KEYWORD; 
            }
            // End HRP-10179
            clonedOpp.sked_Cancellation_Reason__c = '';
            clonedOpp.Initiated_By__c = '';
            
            //Mobile drive
            if(origOpp.RecordTypeId == mobileOppRecTypeId) {
                CalendarBuildWrapper cbWrapper = new CalendarBuildWrapper();
                //Set targeted ask date to be 180 calendar days from drive date & close date 85 calendar days from drive date
                clonedOpp.Targeted_Ask_Date__c = Helper.getCalendarDaysNoWeekend(clonedOpp.drive_date__c, 180);
                clonedOpp.CloseDate = Helper.getCalendarDaysNoWeekend(clonedOpp.Drive_Date__c, 85);
                clonedOpp.StageName = 'Discovery';
                clonedOpp.drive_status__c = '';  //HRP-10179
                if(!oppWithParentTemplateMap.isEmpty() && oppWithParentTemplateMap.containsKey(origOpp.Parent_Template_Id__c)) {
                    clonedOpp.Anticipated_Registered_Donors__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Anticipated_Registered_Donors__c != null ?
                          											oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Anticipated_Registered_Donors__c : 0;
                    
                    clonedOpp.type = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).type != NULL ?
                            oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).type :
                    		driveSiteMap.get(oppIdVsDriveSiteIdMap.get(origOpp.Parent_Template_Id__c)).sked_Physical_Location_Type__c; //HRP-11814
                    clonedOpp.Red_Cross_Volunteer_Required__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Red_Cross_Volunteer_Required__c; //HRP-13146
                    clonedOpp.Red_Cross_Volunteer_Quantity__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Red_Cross_Volunteer_Quantity__c; //HRP-13146
                    
                }
                cbWrapper = runRolloverEvaluation(origOpp, oppWithGraySkiesMap);
                if(cbWrapper.IsQualified != null) {
                    clonedOpp.Calendar_Build_Status__c = cbWrapper.IsQualified ? 'Qualified' : 'Unqualified';
                }
                // HRP-11850 : Add all the unqualifying reason with a limit of 255 characters to Calendar Build Alert field
                if(cbWrapper.UnqualifiedReasons != null && !cbWrapper.UnqualifiedReasons.isEmpty())  {
                    clonedOpp.Calendar_Build_Reasons_For_Unqualified__c = BSF_Utilities.getStringWithinLimit(string.join(cbWrapper.UnqualifiedReasons, ';'), 255);
                }
                if(cbWrapper.RolloverConsideration != null) {
                    clonedOpp.Rollover_Consideration__c = cbWrapper.RolloverConsideration;
                }
            }
            
            //Fixed drive; automatically flagged as qualified
            else if(origOpp.RecordTypeId == fixedOppRecTypeId) {
                clonedOpp.Type = origOpp.Type != NULL ? origOpp.Type : driveSiteMap.get(clonedOpp.Drive_Site__c).sked_Physical_Location_Type__c; //HRP-11814
                clonedOpp.CloseDate = clonedOpp.drive_date__c;  
                clonedOpp.StageName = 'Closed';
                clonedOpp.drive_status__c = '';  //HRP-10179
                clonedOpp.Calendar_Build_Status__c = 'Qualified';
                clonedOpp.Accept_56_Day_Rule_Violation__c = true; //HRP-12141

                //lstClonedOpps.add(clonedopp);
            }
            
            //check final time for any mismatch in physical location type, if yes, correct the cloned one - HRP-11814 --> Starts Here
            if(!clonedOpp.Type.equals(driveSiteMap.get(clonedOpp.Drive_Site__c))) {
                clonedOpp.Type = driveSiteMap.get(clonedOpp.Drive_Site__c).sked_Physical_Location_Type__c;
            }
            clonedOpp.Related_Scheduled_Drive__c = NULL;
            lstClonedOpps.add(clonedopp);
            
            // HRP-11814 --> Ends Here
        }
        return lstClonedOpps;
    }

    //Method used for determining if opportunities meet the rollover evaluation criteria
    //Details of the criteria is document on HRP-3442
    public static CalendarBuildWrapper runRolloverEvaluation(Opportunity incomingOrigOpp, Map<Id, Id> graySkiesMap) {
        CalendarBuildWrapper cbWrapper = new CalendarBuildWrapper();
        //Don't clone opps that are cancelled with a reson of 'system need'
        if(!(incomingOrigOpp.DriveStatus__c == 'Cancelled' && incomingOrigOpp.sked_Cancellation_Reason__c == 'System Need')) {
            if(incomingOrigOpp.rollover_consideration__c != null && incomingOrigOpp.rollover_consideration__c == 'Alwyas Roll') {
                if(incomingOrigOpp.Account.Account_Strategy__c != null && incomingOrigOpp.Account.Account_Strategy__c == 'Sunset') {
                    cbWrapper.IsQualified = false;
                    cbWrapper.UnqualifiedReasons.add('Always Roll On, Account Strategy is Sunset');
                }
            }

            /* Logic for HRP-12299
            	If opportunity has drive affiliation with Designation = "Gray Skies", 
                    leave the CB status blank so that it can go for other unqualifying condition check
			
            else if(!graySkiesMap.isEmpty() && graySkiesMap.containsKey(incomingOrigOpp.Id)){ //incomingOrigOpp.Drive_Designations__c != null && incomingOrigOpp.Drive_Designations__c.split(';').contains('Gray Skies')) {
                cbWrapper.IsQualified = true;
                //cbWrapper.UnqualifiedReasons = 'Drive Designation is Gray Skies';
                //cbWrapper.RolloverConsideration = 'Do Not Roll';
            }*/
            
            //If Account Strategy = "Sunset", mark as "Unqualified" and add reason to Calendar Build Alert field
            if(incomingOrigOpp.Account.Account_Strategy__c != null && incomingOrigOpp.Account.Account_Strategy__c == 'Sunset') {
                cbWrapper.IsQualified = false;
                cbWrapper.UnqualifiedReasons.add('Account Strategy is Sunset');
                cbWrapper.RolloverConsideration = 'Do Not Roll';
            }

            //If Account Status = "Lost or Defunct", mark as "Unqualified" and add reason to Calendar Build Alert field
            if(incomingOrigOpp.Account.Account_Status__c != null  && 
                (incomingOrigOpp.Account.Account_Status__c == 'Lost' || incomingOrigOpp.Account.Account_Status__c == 'Defunct')) {
                    cbWrapper.IsQualified = false;
                    cbWrapper.RolloverConsideration = 'Do Not Roll';
                    cbWrapper.UnqualifiedReasons.add('Account Status is Lost/Defunct');
            }
        }   
        return cbWrapper; 
    }

    /*HRP-12706 --> Starts Here
    * @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 8/6/2024
			* CreatedFor : HRP-12706
    * @Description : 
     		* This method will return a list of eligible opportunities to be processed and have child CB opps for next year
    *  @Parameters : 
     		* CB Log Wrapper class Instance
	*/
     
    public static DriveGenerationUtil.CalendarBuildLogWrapper getEligibleOppsToRunCb(DriveGenerationUtil.CalendarBuildLogWrapper cbLogWrapper) {
        Set<Id> parentCbIds = new Set<Id>();
        cbLogWrapper.eligibleOpportunityForCbList = new List<Opportunity>();
        cbLogWrapper.map_driveType_eligibleOppList = new Map<String, List<Opportunity>>();
        Date driveDateToEval = cbLogWrapper.driveDateToEval;
        String queryString = BSF_Utilities.createDriveQueryForCalendarBuild();
        queryString += ' WHERE (DriveStatus__c = \'Complete\' OR DriveStatus__c = \'Cancel\' OR DriveStatus__c = \'Confirmed\')';
        queryString += ' AND Rollover_Consideration__c <> \'Do Not Roll\'';
        queryString += ' AND drive_date__c = :driveDateToEval';
        
        List<Opportunity> cbOppList = Database.query(queryString);
        Map<Id, Opportunity> map_eligibleOppsId_oppDetails = new Map<Id, Opportunity>(cbOppList);

        List<Opportunity> lstOppsWithParentCB = new List<Opportunity>([SELECT Id, Calendar_Build_Parent_Opportunity__c 
                                                                        FROM Opportunity 
                                                                        WHERE Calendar_Build_Parent_Opportunity__c IN :map_eligibleOppsId_oppDetails.keySet()]);
        if(lstOppsWithParentCB != null && lstOppsWithParentCB.size() > 0) {
            for(Opportunity oppWithParentCB : lstOppsWithParentCB) {
                parentCbIds.add(oppWithParentCB.Calendar_Build_Parent_Opportunity__c);
            }
        }

        for(Opportunity opp : map_eligibleOppsId_oppDetails.values()) {
            if(!parentCbIds.contains(opp.Id)) {  //Only one Calendar Build drive is allowed to be generated for an opportunity
                cbLogWrapper.eligibleOpportunityForCbList.add(opp);
                if(!cbLogWrapper.map_driveType_eligibleOppList.containsKey(opp.Type_of_Drive__c)) {
                    cbLogWrapper.map_driveType_eligibleOppList.put(opp.Type_of_Drive__c, new List<Opportunity>());
                }
                cbLogWrapper.map_driveType_eligibleOppList.get(opp.Type_of_Drive__c).add(opp);
            }
        }
        return cbLogWrapper;
    }

    /* @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 8/6/2024
			* CreatedFor : HRP-12706
    * @Description : 
     		* This method will be used to get eligible opps to be processed by drive generation batch
    *  @Parameters : 
     		* source : Calendar Build/ Adhoc/ Business Planning / ''
            * driveDateToEval : drive date of next year's opps
	*/
    public static List<Opportunity> getEligibleDrivesToRunCb(String source, Date driveDateToEval, Set<Id> parentCbIds) {
        String queryString = BSF_Utilities.createDriveQueryForCalendarBuild();
        queryString += ' WHERE ';
        if(source != NULL && !String.isBlank(source)) {
            queryString += 'Source__c = :source AND ';
        }
        if(parentCbIds != NULL && !parentCbIds.isEmpty()) {
            queryString += 'Calendar_Build_Parent_Opportunity__c IN :parentCbIds AND ';
        }
        if(source != NULL && !String.isBlank(source) && source.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) { // No need of this check for Adhoc CB
            queryString += 'Drive_Date__c = :driveDateToEval AND ';
        }
        queryString += 'Related_Scheduled_Drive__c = NULL';
        List<Opportunity> eligibleOpps = Database.query(queryString);
        return eligibleOpps;
    }
    // HRP-12706 --> Ends Here
    
    public class CalendarBuildWrapper {
        public boolean IsQualified {get; set;}
        public List<String> UnqualifiedReasons {get; set;} //HRP-11850: Changed wrapper variable data type from String to List<String> to capture all unqualifying conditions
        public string RolloverConsideration {get; set;}
        
        public CalendarBuildWrapper () {
            this.UnqualifiedReasons = new List<String>();
        }
    }

    //HRP-11368: Starts Here -->
    public static List<Opportunity> filterOpportunitiesToCloneForAdhocRun(List<Opportunity> selectedOpps) {

        //Containers needed
        Set<Id> accountIds = new set<Id>();
        List<Opportunity> filteredOpps = new List<Opportunity>();
        Map<Date, List<Opportunity>> map_nextYearDriveDate_oppList = new Map<Date, List<Opportunity>>();
        Map<String, List<Opportunity>> map_driveDateAndAccountIdKey_oppList = new Map<String, List<Opportunity>>();
        
        for(Opportunity opp : selectedOpps) {
            if(opp.Type_of_Drive__c.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) continue;
            accountIds.add(opp.AccountId);
            DateTime dT = Helper.getSameDayOfNextYear(opp.Drive_Date__c);
            Date nextYearDate = Date.newInstance(dT.year(), dT.month(), dT.day());
            if(!map_nextYearDriveDate_oppList.containsKey(nextYearDate)) {
                map_nextYearDriveDate_oppList.put(nextYearDate, new List<Opportunity>());
            }
            map_nextYearDriveDate_oppList.get(nextYearDate).add(opp);
        }

        List<Opportunity> preExistingDrives = [SELECT Id, AccountId, Drive_Date__c 
                                                FROM Opportunity
                                                WHERE AccountId IN :accountIds
                                                AND Drive_Date__c IN :map_nextYearDriveDate_oppList.keySet()
                                                AND StageName NOT IN (:BSF_Constants.STAGE_CANCELLED)];
        
        for(Opportunity opp : preExistingDrives) {
            String key = opp.Drive_Date__c + '_' + opp.AccountId;
            if(!map_driveDateAndAccountIdKey_oppList.containsKey(key)) {
                map_driveDateAndAccountIdKey_oppList.put(key, new List<Opportunity>());
            }
            map_driveDateAndAccountIdKey_oppList.get(key).add(opp);
        }

        for(Date nextYearDate : map_nextYearDriveDate_oppList.keySet()) {
            for(Opportunity opp : map_nextYearDriveDate_oppList.get(nextYearDate)) {
                String key = nextYearDate + '_' + opp.AccountId;
                if(!map_driveDateAndAccountIdKey_oppList.containsKey(key)) filteredOpps.add(opp);
            }
        }
        return filteredOpps;
    }
    //HRP-11368: Ends Here -->
}