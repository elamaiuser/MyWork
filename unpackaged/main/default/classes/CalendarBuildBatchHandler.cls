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
 *                                  checkbox should not be checked and it will come from the Template.                                    
 **************************************************************************************************************************************/

public with sharing class CalendarBuildBatchHandler {
    
    //Method takes in a list of opportunities from the batch process i.e. drives that have been completed or cancelled
    //x days ago.  It clones the opportunities and designates them as qualified or unqualified based on some criteria.
    public static List<Opportunity> cloneDrives(List<Opportunity> lstOpportunities) {
        system.debug('inside cloneDrives...');
        //Get record type Id for Mobile and Fixed opps
        Id mobileOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId();
        Id fixedOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId();
        
        List<Opportunity> lstClonedOpps = new List<Opportunity>();
        
        //Set of the opportunity ids
		Set<Id> oppIdsSet = new Set<Id>();
        For(Opportunity opp : lstOpportunities) {
            oppIdsSet.add(opp.Id);
        }
        
        //Set of the parent template ids
        Set<Id> parentTemplateIdsSet = new Set<Id>();
		For(Opportunity opp : lstOpportunities) {
            parentTemplateIdsSet.add(opp.Parent_Template_Id__c);
        }
        
        //Get the "days from drive date" configuration item from the custom metadata.  This will be used to calculate the 
        //targeted ask date for mobile drives
        Opportunity_Date_Setting__mdt mdtOppDateSetting = Opportunity_Date_Setting__mdt.getInstance('Targeted_Ask_Date');
        Integer numNumOfAskDays = mdtOppDateSetting?.Days_from_Drive_Date__c.intValue();
        
        // HRP-11539
        Map<Id, Id> OppToParentCBMap = new Map<Id, Id>();
        
        List<Opportunity> lstOppsWithParentCB = [SELECT Id, Calendar_Build_Parent_Opportunity__c FROM Opportunity 
                                                 WHERE Calendar_Build_Parent_Opportunity__c IN :oppIdsSet];
        
        if(lstOppsWithParentCB != null && lstOppsWithParentCB.size() > 0)
        {
            system.debug('lstOppsWithParentCB '+lstOppsWithParentCB.size());
            for(Opportunity oppWithParentCB : lstOppsWithParentCB)
            {
				OppToParentCBMap.put(oppWithParentCB.Calendar_Build_Parent_Opportunity__c, oppWithParentCB.Id);
            }
        }
        
        List<Drive_Marketing_Programs__c> graySkiesAffiliationList = [SELECT Id, Marketing_Program__c, Blood_Drive_Opportunity__c FROM Drive_Marketing_Programs__c 
                                                                      WHERE Marketing_Program__r.Name = 'Gray Skies' AND Blood_Drive_Opportunity__c in :oppIdsSet];
        Map<Id, Id> oppWithGraySkiesMap = new Map<Id, Id>();
        For(Drive_Marketing_Programs__c dmp : graySkiesAffiliationList){
            oppWithGraySkiesMap.put(dmp.Blood_Drive_Opportunity__c, dmp.Id);
        }
                
        //Get the projections from the parent template
        List<Opportunity> parentTemplateOpportunityList = [SELECT Id, Anticipated_Registered_Donors__c, WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Drive_Site__c,
                                                           Start_Time__c, End_Time__c, Accept_56_Day_Rule_Violation__c, AcceptblankMilitaryAuthNamePhone__c, Direct_Donors_To__c,
                                                           No_Publicity_Needed__c, Open_to_Public__c, Drive_Keyword__c, Publish_to_Call_Center__c, Web_Scheduling_Enabled__c,
                                                           Send_Emails__c, Send_Mailers__c, Web_Scheduling_End_Date_Offset__c, Web_Scheduling_End_Time_Offset__c, 
                                                           Web_Scheduling_Start_Date_Offset__c, Platelet_Projected_Procedures__c, Plasma_Pheresis_Projected_Procedures__c,
                                                           Flow_End_Time_Field__c, Flow_Start_Time_Field__c
                                                           FROM Opportunity WHERE Id in :parentTemplateIdsSet];
        Map<Id, Opportunity> oppWithParentTemplateMap = new Map<Id, Opportunity>();
        For(Opportunity parentOpp : parentTemplateOpportunityList){
            oppWithParentTemplateMap.put(parentOpp.Id, parentOpp);
        }
        
        //Only one Calendar Build drive is allowed to be generated for an opportunity
        for(Opportunity origOpp : lstOpportunities)
        {    
            if(OppToParentCBMap != null && OppToParentCBMap.keySet().contains(origOpp.Id))
            {                
                System.debug('### Found existing cb drive for the opp ' + origOpp.Id);
                continue;
            }
            
            //Clone the opportunity and update some fields; by default preserveId is false i.e the ID is cleared for the new record.  isDeepClone is set to true
            Opportunity clonedOpp = origOpp.clone(false, true);
            clonedOpp.source__c = 'Calendar Build';
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
                clonedOpp.Drive_Keyword__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Drive_Keyword__c; 
                clonedOpp.Publish_to_Call_Center__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Publish_to_Call_Center__c;
                clonedOpp.Web_Scheduling_Enabled__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_Enabled__c;
                clonedOpp.Send_Emails__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Send_Emails__c;
                clonedOpp.Send_Mailers__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Send_Mailers__c;
                clonedOpp.Web_Scheduling_End_Date_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_End_Date_Offset__c;
                clonedOpp.Web_Scheduling_End_Time_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_End_Time_Offset__c;
                clonedOpp.Web_Scheduling_Start_Date_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_Start_Date_Offset__c;
                clonedOpp.Web_Scheduling_Start_Date_Offset__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Web_Scheduling_Start_Date_Offset__c;
                
            }
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
                if(!oppWithParentTemplateMap.isEmpty() && oppWithParentTemplateMap.containsKey(origOpp.Parent_Template_Id__c)){
                      clonedOpp.Anticipated_Registered_Donors__c = oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Anticipated_Registered_Donors__c != null ?
                          											 oppWithParentTemplateMap.get(origOpp.Parent_Template_Id__c).Anticipated_Registered_Donors__c : 0;
                }
                cbWrapper = runRolloverEvaluation(origOpp, oppWithGraySkiesMap);
                if(cbWrapper.IsQualified != null) {
                    clonedOpp.Calendar_Build_Status__c = cbWrapper.IsQualified ? 'Qualified' : 'Unqualified';
                }
                if(cbWrapper.UnqualifiedReasons != null) {
                    clonedOpp.Calendar_Build_Reasons_For_Unqualified__c = cbWrapper.UnqualifiedReasons;
                }
                if(cbWrapper.RolloverConsideration != null) {
                    clonedOpp.Rollover_Consideration__c = cbWrapper.RolloverConsideration;
                }
                lstClonedOpps.add(clonedOpp);      
            }
            //Fixed drive; automatically flagged as qualified
            else if(origOpp.RecordTypeId == fixedOppRecTypeId) {
                system.debug('processing fixed opp');
                clonedOpp.CloseDate = clonedOpp.drive_date__c;  
                clonedOpp.StageName = 'Closed';
                clonedOpp.drive_status__c = '';  //HRP-10179
                clonedOpp.Calendar_Build_Status__c = 'Qualified';
                lstClonedOpps.add(clonedopp);
            }
        }
        system.debug('### Returning cloned opp. ' + lstClonedOpps.size());
        return lstClonedOpps;
    }

    //Method used for determining if opportunities meet the rollover evaluation criteria
    //Details of the criteria is document on HRP-3442
    public static CalendarBuildWrapper runRolloverEvaluation(Opportunity incomingOrigOpp,  Map<Id, Id> graySkiesMap) {
        CalendarBuildWrapper cbWrapper = new CalendarBuildWrapper();
        //Don't clone opps that are cancelled with a reson of 'system need'
        if(!(incomingOrigOpp.Drive_Status__c == 'Cancelled' && incomingOrigOpp.sked_Cancellation_Reason__c == 'System Need')) {
            if(incomingOrigOpp.rollover_consideration__c != null && incomingOrigOpp.rollover_consideration__c == 'Alwyas Roll') {
                if(incomingOrigOpp.Account.Account_Strategy__c != null && incomingOrigOpp.Account.Account_Strategy__c == 'Sunset') {
                    cbWrapper.IsQualified = false;
                    cbWrapper.UnqualifiedReasons = 'Always Roll On, Account Strategy is Sunset';
                }
            }
            //If opportunity has drive affiliation with Designation = "Gray Skies", mark as "Unqualified"
            else if(!graySkiesMap.isEmpty() && graySkiesMap.containsKey(incomingOrigOpp.Id)){ //incomingOrigOpp.Drive_Designations__c != null && incomingOrigOpp.Drive_Designations__c.split(';').contains('Gray Skies')) {
                cbWrapper.IsQualified = false;
                cbWrapper.UnqualifiedReasons = 'Drive Designation is Gray Skies';
                cbWrapper.RolloverConsideration = 'Do Not Roll';
            }
            //If Account Strategy = "Sunset", mark as "Unqualified"
            else if(incomingOrigOpp.Account.Account_Strategy__c != null && incomingOrigOpp.Account.Account_Strategy__c == 'Sunset') {
                cbWrapper.IsQualified = false;
                cbWrapper.UnqualifiedReasons = 'Account Strategy is Sunset';
                cbWrapper.RolloverConsideration = 'Do Not Roll';
            }
            //If Account Status = "Lost or Defunct", mark as "Unqualified"
            else if(incomingOrigOpp.Account.Account_Status__c != null  && 
                    (incomingOrigOpp.Account.Account_Status__c == 'Lost' || incomingOrigOpp.Account.Account_Status__c == 'Defunct')) {
                        cbWrapper.IsQualified = false;
                        cbWrapper.RolloverConsideration = 'Do Not Roll';
                        cbWrapper.UnqualifiedReasons = 'Account Status is Lost/Defunct';
            }
        }   
        return cbWrapper; 
    }
    
    public class CalendarBuildWrapper {
        public boolean IsQualified {get; set;}
        public string UnqualifiedReasons {get; set;}
        public string RolloverConsideration {get; set;}
        
        public CalendarBuildWrapper () {}
    }
}