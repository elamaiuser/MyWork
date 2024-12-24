/* @Description: 1. Below service class supports various opportunity relared functionalities working in different contexts.
*               2. Below service class has been called from OpportunityTriggerHandler
** NOTE : Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification on DOC (11418)

* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 4/18/2023                      Fitsum Worku             Logic for HRP-9899 (replace validation rule related to stage move back with trigger logic)
* 5/9/2023                       Priti Jana               Logic for HRP-9780
* 5/9/2023                       Priti Jana               Commented validateOnlineDonorMessage method for HRP-9887
* 2/4/2023                       Kishore Das              Logic for HRP-9562 
* 6/12/2023                      Fitsum Worku             Update to syncOpps
* 6/22/2023                      Ankit Kundu              Logic for HRP-9834 (Added error log to capture consequences when updating projection values from template opportunity to BDO)
* 7/25/2023                      Ankit Kundu              Logic for HRP-10514 (Added Platelet Procedure in Drive Sync Logic) 
* 7/26/2023                      Anil Kallu               HRP-10312- Addressed issues for opportunities being out of sync when drive change request is rejected 
* 8/4/2023                       Ankit Kundu              HRP-10416 Projected WB & 2RBC not updating when Projected Procedures is updated  
* 3/8/2023                       Kishore Das              Users other than System Admin should not have any delete record permissions(Logic for HRP-10572)(Deleted)
* 9/5/2023                       Barnojit Sharma          Centralized apex class to send Notifications from Process Builder (HRP-10482)
* 9/11/2023                      Priti Jana               Logic for HRP-10172
* 9/20/2023                      Krapy Tuli               Logic for HRP-10359 (Update AM, DM, AM Portfolio and DM Portfolio)
* 9/25/2023                      Anil Kallu               HRP-10515-Query latest values on DOC for changed fields and update on Opportunity, when request comes from DOC update    
* 10/24/2023                     Anil Kallu               HRP-10959- Perform check for valid stage transitions, from custom metadata
* 10/26/2023                     Balaji N                 Logic for HRP-10788 (Method:createRecruitmentTask,logic for task creation on Opportunity field calllistRecipient update,DuplicatePrevention,Bulk insert-platform Event)
* 11/6/2023                      Krapy Tuli               For HRP-11299 null value handle
* 11/24/2023                     Balaji N                 Logic for HRP-11281(Method name:updateOpptyOwner_AddOpptyTeamMembers,is_covering_recruiter If check)
* 12/08/2023                     Barnojit Sharma          Update Accepts Blank Military Checkbox field from the template during Opportunity creation. (HRP-11179)
* 20/12/2023                     Ankit Kundu              Projection Changes Not Updating Order Budget Formula (HRP-11457)
* 12/27/2023                     Barnojit Sharma          Calendar Build can creates Opportunities violating 56 Day Rule. (HRP-11640)
* 01/03/2024                     Balaji N                 Logic for HRP-10569(Method :updateOpptyOwner_OpptyTeam;updateOpptyOwner_AddOpptyTeamMembers,opporunity team creation for non  existing future Account team but part of Account Portfolio Assignment)
* 1/11/2024                      Priti Jana               Logic for HRP-10882
* 1/15/2024                      Priti Jana               Logic for HRP-11418
* 01/18/2024                     Balaji N                 logic for HRP-11234(Method :updateOpptyOwner_OpptyTeam;updateOpptyOwner_AddOpptyTeamMembers,Update lookups AM,DM,Owner when no coverage
* 15/02/2024                     Barnojit Sharma          Managing Plan a Drive Process and Unavailable Taxonomy. (HRP-11484)
* 12/02/2024                     Barnojit Sharma          BDO can not be confirmed if DCR or Pending Action is in progress. (HRP-10912)
* 15/02/2024                     Barnojit Sharma          DOC does not pull up AM and DM portfolio according to drive date. (HRP-11849)
* 12/02/2024                     Kishore Das              Logic for HRP-12063(Users able to move drive date within Calendar)
* 11/03/2024                     Kishore Das              Logic For HRP-12143
* 03/06/2024                     Balaji N                 logic for HRP-12136 (Method:checkOppNameChange;changes in opp name logic)
* 03/22/2024                     Balaji N                 logic for HRP-12333 (Method: getTaskOwner, changes in parameter and Hierarchy logic, Changes on the method calls from other methods)
* 04/04/2024                     Anil K                   HRP-11393- When opp is linked to two drives where one drive is already cancelled, but doesn't cancel the second one, pick one that is not cancelled
* 05/02/2024                     Krapy Tuli               Fixed typo and added some checks for HRP-12479
* 05/07/2024                     Raktim Ghosal            Only the System Admin & Global Admin can change closed Opportunities to Cancelled Stage which have drive status in completed status to cancelled.(HRP-11524)
* 06/05/2024                     Raktim Ghosal            Type B drives should generate recruitment meeting task along with Type A drives(HRP-12284).
* 06/06/2024                     Priti Jana               Logic for HRP-12011
* 06/10/2024                     Krapy Tuli               By-pass checkAccept56DaysVoilation for Automated Process user.(HRP-12837)
* 06/13/2024                     Apurba Bhattacharjee     Modifications for HRP-4878 & HRP-12631
* 07/04/2024                     Krapy Tuli               Bypass method restrictFieldChangeWhenPendingActionIsOpen- Sync Issues When Pending Action is in Progress and added check to handle Discription#3 [HRP-13045]
* 06/08/2024                     Raktim Ghosal            Publicity Material Ordering at template level(HRP-12664)
* 08/06/2024                     Barnojit Sharma          Creation of Drive Affiliation is moved from Batch apex to Platform event-driven process (Logic for HRP-10204)
* 08/14/2024                     Apurba Bhattacharjee     HRP-12700 Add Drive Date to task list
* 08/30/2024                     Barnojit Sharma          Within the Sponsor Planning Report task, populate the referencing Opp/Drive Sponsor Planning Report. (Logic for HRP-5337)
* 10/14/2024                     Souvik Mukherjee         HRP-13568 Added OpportunityId to Order SELECT SOQL
* 10/18/2024                     Balaji N                 HRP-13489 Methods populateSlotGeneratorOnOpportunity,getSlotMultiplierGlobalValue
* 10/25/2024                     Balaji N                 Logic for HRP-13489 syncTemplateOrdertoOpportunity Raktim's Changes
* 10/29/2024                     Barnojit Sharma          HRP-12142 Added sync Do Not Roll Fields
* 10/24/2024                     Barnojit Sharma          Template Order products not cascading to Opportunity Order (Logic for HRP-13521)
* 11/07/2024                     Barnojit Sharma          Update Task: 72 Hour Check in - System Generated/Details/Checklist. (Logic for HRP-12627)
* 11/11/2024                     Priti Jana               Logic for HRP-13743
* 11/12/2024                     Barnojit Sharma          Unable to create Mobile Drive when the Template has an over-budget template order (Logic for HRP-13716)
* 12/02/2024                     Barnojit Sharma          Tasks being assigned for cancelled drives and for fixed sites(Logic for HRP-13850)
* 12/10/2024                     Priti Jana               Logic for HRP-13190
* 12/10/2024                     Satyendra Vishwakarma    HRP-6051 - Anticipated Registered Donors validation when changing procedure projections
************************************************************************************************************************************************
*/

/***
* AS-012312->DRD User: BPL is Required to Promote Opportunity to Closed-AK
* 
* */
public with sharing class OpportunityService{ 
    public static final Id MOBILE_OPP_RECTYPEID = SObjectType.Opportunity.getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();
    public static final Id FIXED_SITE_OPP_RECTYPEID = SObjectType.Opportunity.getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId();
    
    public static map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers = new map<Id,List<AccountTeamMember>>();//HRP-10569
    
    public static Boolean isExecuted = false;
    
    //Verify if an opportunity is being closed->if being closed->needs to have a BPL assigned to the account(not Vacant BPL)
    //5/20/2022 Per HRP-7032 this check is no longer needed.  The call to this method is removed from the trigger handler.
    /*
    public static void verifyValidBPLExists(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
    if (newMap == null)
    return;
    //AS-012337-For D2D Profile Users, don't check valid BPL condition->Update on 11/22, no need to check valid BPL for any profile for Fixed site opportunities
    //Update commenting this code as this check is not tied to profiles anymore
    /*List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1 ];
    String currentUserProfileName = profileList.size() < 1 ? '' : profileList[0].Name;
    System.debug(currentUserProfileName);*/
        /*
    Set<Id> newOppMapKeys = newMap.keyset();
    Map<Id, Opportunity> accountOpportunityMap = new Map<Id, Opportunity>();
    for (Id oppId : newOppMapKeys) {
    Opportunity newOpp = newMap.get(oppId);
    System.debug('New Opportunity->' + newOpp);
    if(newOpp.Is_Template__c == true){ //if its template, don't bother further checks
    continue;
    }
    if (newOpp.StageName != 'Closed')//stagename is not closed, don't bother any futher
    continue;
    if (oldMap != null && oldMap.get(oppId).StageName == 'Closed')//If moving from closed to closed,meaning other fields got updated, no need to validate again
    continue;
    if (newOpp.Type_of_Drive__c == 'Fixed Site') //If its fixed site opportunity, dont verify valid BPL condition
    continue;
    //If moving from other stages to Closed, validate BPL exists
    accountOpportunityMap.put(newOpp.AccountId, newOpp);
    }
    if (accountOpportunityMap.size() > 0)
    checkAndAddErrorIfNoValidBPLPresent(accountOpportunityMap);
    }*/   
    
    /**
* This Method checks and adds error to the opportunity, if the account associated has no Valid BPL Rule
* */
    /*public static void checkAndAddErrorIfNoValidBPLPresent(Map<Id, Opportunity> accountOpportunityMap) {
    List<Account> accounts = [select id, (select id, Account_Service_Role__c,contact__r.lastName from Account_Contact_Roles__r) from account where id in :accountOpportunityMap.keySet()];
    for (Account account : accounts) {
    List<Account_Service_Role__c> serviceRoles = account.Account_Contact_Roles__r;
    System.debug(serviceRoles);
    boolean isBPLExists = false;
    if(accountOpportunityMap.get(account.id).Is_Template__c == true){ //if its template, don't bother further checks
    continue;
    }
    if (serviceRoles == null || serviceRoles.size() < 1) {
    System.debug('No Service Roles exist for account of opportunity id:' + accountOpportunityMap.get(account.id));
    accountOpportunityMap.get(account.id).addError('Oh, we have hit a snag. An Active BPL is required to move this Drive to Closed Stage');
    return;
    }
    boolean validBPLFound = false;
    for (Account_Service_Role__c serviceRole : serviceRoles) {
    Date today = System.today();
    Contact serviceRoleContact = serviceRole.contact__r;
    System.debug('contact of this service role->' + serviceRoleContact);
    //if vacant contact is assigned->Ignore this role
    if (serviceRoleContact != null && 'Vacant'.equalsIgnoreCase(serviceRoleContact.lastName))
    continue;
    if ('Blood Program Leader' == serviceRole.Account_Service_Role__c) {
    validBPLFound = true;
    }
    }//at end of service roles for each account, check if valid BPL exists
    if (validBPLFound == false) {
    System.debug('No valid BPL role exists for account :' + account.id);
    accountOpportunityMap.get(account.id).addError('Oh, we have hit a snag. An Active BPL is required to move this Drive to Closed Stage');
    return;
    }
    }//end of all account
    }//end of method
    
    /* OnlineDonorMessage Validation - Commented for HRP - 9887 --> Start
    public static void validateOnlineDonorMessage(Map<Id, Opportunity> oldMap, List<Opportunity> newItems) {
    for (Opportunity opt : newItems) {
    if(opt.Is_Template__c == true){ //if its template, don't bother further checks
    continue;
    }
    if ((oldMap == null || opt.Online_Donor_Message__c != oldMap.get(opt.Id).Online_Donor_Message__c) && opt.Online_Donor_Message__c != null) {
    Pattern allCaps = Pattern.compile('[a-zA-Z0-9 @~!#$()%&*+=:;,?/.\\\\]+');
    Matcher matcher = allCaps.matcher(opt.Online_Donor_Message__c);
    if (opt.Online_Donor_Message__c.replaceAll('[^a-zA-Z]', '').isAllUpperCase()) {
    System.debug(opt.Online_Donor_Message__c);
    opt.addError('The Online Donor message should not contain capital letters and/or special characters.');
    } else if (!matcher.matches()) {
    opt.addError('The Online Donor message should not contain capital letters and/or special characters');
    }
    }
    }
    }
    Commented for HRP - 9887 --> End */
    
    public static void checkAccept56DaysVoilation(Map<Id, Opportunity> oldMap, List<Opportunity> newItems) {
        Boolean isAutomatedProcess = UserInfo.getName() == BSF_Constants.AUTOMATED_PROCESS; //HRP-12837 start
        if(isAutomatedProcess) {
            return ;
        }//HRP-12837 end
        Map<Id, Date> driveDatesBackByAccId = new Map<Id, Date>();
        Map<Id, Date> driveDatesForwardByAccId = new Map<Id, Date>();
        Map<Id, List<Opportunity>> opportuniesByAccId = new Map<Id, List<Opportunity>>();
        Id mobileRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Mobile_Opp').getRecordTypeId();
        for (Opportunity opportunity : newItems) {
            if(opportunity.Is_Template__c == true){ //if its template, don't bother further checks
                continue;
            }
            /*
            * HRP-11640 changes starts here
            */
            if(Trigger.isExecuting && Trigger.isInsert && opportunity.RecordTypeId == mobileRecTypeId 
                    && String.isNotBlank(opportunity.Source__c) && opportunity.Source__c.equalsIgnoreCase('Calendar Build')){
                continue;
            }
            /*
            * HRP-11640 changes ends here
            */
            if (opportunity.RecordTypeId == mobileRecTypeId && opportunity.Drive_Name__c != 'Default Drive' &&
                        opportunity.StageName != 'Cancelled' && (oldMap == null || opportunity.Drive_Date__c != oldMap.get(opportunity.Id).Drive_Date__c
                        /*
                        * HRP-11640 changes starts here
                        */
                        || (opportunity.Drive_Status__c != oldMap.get(opportunity.Id).Drive_Status__c && (opportunity.Drive_Status__c == 'Confirmed' || opportunity.Drive_Status__c == 'Complete'))
                        || (opportunity.StageName != oldMap.get(opportunity.Id).StageName && opportunity.StageName == 'Closed'))){ 
                        /*
                        * HRP-11640 changes ends here
                        */
                            driveDatesBackByAccId.put(opportunity.AccountId, opportunity.Drive_Date__c.addDays(-56));
                            driveDatesForwardByAccId.put(opportunity.AccountId, opportunity.Drive_Date__c.addDays(+56));
                            if (opportuniesByAccId.containsKey(opportunity.AccountId)) {
                                opportuniesByAccId.get(opportunity.AccountId).add(opportunity);
                            } else {
                                opportuniesByAccId.put(opportunity.AccountId, new List<Opportunity>{
                                    opportunity
                                        });
                            }
                }
        }
        
        Set<Opportunity> tempOpts = new Set<Opportunity>();
        /*for (Opportunity opportunity : [SELECT Id,Drive_Date__c,AccountId FROM Opportunity WHERE AccountId IN:opportuniesByAccId.keySet() AND StageName != 'Cancelled' AND RecordTypeId = :mobileRecTypeId AND Id NOT IN:newItems]) {
if (opportuniesByAccId.containsKey(opportunity.AccountId)) {
for (Opportunity opty : opportuniesByAccId.get(opportunity.AccountId)) {
if (opportunity.Drive_Date__c >= driveDatesBackByAccId.get(opportunity.AccountId) &&
opportunity.Drive_Date__c <= driveDatesForwardByAccId.get(opportunity.AccountId)) {
tempOpts.add(opty);
isExecuted = true;
if (!opty.Accept_56_Day_Rule_Violation__c) {
opty.addError('This drive date violates the 56 day rule.Please acknowledge.');
}
}
}
}
}*/
        Map<Id,Opportunity> oppqueryResultMap = new Map<Id,Opportunity>( [ SELECT Id,Drive_Date__c,AccountId, Accept_56_Day_Rule_Violation__c FROM Opportunity WHERE AccountId IN:opportuniesByAccId.keySet() 
                                                                          AND StageName != 'Cancelled' 
                                                                          AND RecordTypeId = :mobileRecTypeId 
                                                                          AND Id NOT IN:newItems ] );
        
        Map<Id,Opportunity> oppqueryResultFilteredMap = new Map<Id,Opportunity>();
        Map<Id,Id> oppIdAccId = new Map<Id,Id>();
        Map<Id,Opportunity> accidOppmap = new Map<Id,Opportunity>();
        
        for( String oppid : oppqueryResultMap.keySet() ){ // 200 opp 
            if ( opportuniesByAccId.containsKey( oppqueryResultMap.get(oppid).AccountId ) ) {
                if( !oppqueryResultFilteredMap.containsKey( oppid ) ){
                    oppqueryResultFilteredMap.put( oppid, oppqueryResultMap.get(oppid) );
                    oppIdAccId.put( oppid, oppqueryResultMap.get(oppid).AccountId );
                }
            }
        }
        
        for( Opportunity opps: newItems ){            
            //if( opps.AccountId == oppIdAccId.get( opps.AccountId ) ){                
            accidOppmap.put( opps.AccountId, opps );                
            //}
        }        
        for( String oppids: oppqueryResultFilteredMap.keySet() ){    // iterating over an existing opportunity 
            Id accid = oppqueryResultFilteredMap.get(oppids).AccountId ; 
            if( oppqueryResultFilteredMap.get(oppids).Drive_Date__c > driveDatesBackByAccId.get( accid ) &&
               oppqueryResultFilteredMap.get(oppids).Drive_Date__c < driveDatesForwardByAccId.get( accid ) ){                
                   
                   tempOpts.add( accidOppmap.get( accid ) );
                   isExecuted = true;
                   if (!accidOppmap.get(accid).Accept_56_Day_Rule_Violation__c) {
                       accidOppmap.get(accid).addError('This drive date violates the 56 day rule.Please acknowledge.');
                   }                    
                   
               }
        }
        
        for (Opportunity opt : newItems) {
            if(opt.Is_Template__c == true){ //if its template, don't bother further checks
                continue;
            }
            if (!opt.hasErrors() && !tempOpts.contains(opt) && !isExecuted) {
                //opt.Accept_56_Day_Rule_Violation__c = false;
                isExecuted = true;
            }
        }
        
        
    }
    
    //This method updates the Drive Date Day field with the Day of Week value from Drive Date (if not null)
    public static void updateDriveDateDay(List<Opportunity> newItems) {
        
        System.debug('Entered method updateDriveDateDay with opp items->' + JSON.serialize(newItems));
        String dayofWeek = '';
        Datetime dt;
        if (newItems == null || newItems.size() < 1)
            return;
        for (Opportunity opp : newItems) {
            if (opp.Drive_Date__c != null) {
                
                dt = DateTime.newInstanceGmt(opp.Drive_Date__c, Time.newInstance(0,0,0,0));             
                dayofWeek = dt.formatGMT('u');
                
                if(dayofWeek == '1'){
                    opp.Drive_Date_Day__c = 'MON';
                } else if (dayofWeek == '2') {
                    opp.Drive_Date_Day__c = 'TUE';
                } else if (dayofWeek == '3') {
                    opp.Drive_Date_Day__c = 'WED';
                } else if (dayofWeek == '4') {
                    opp.Drive_Date_Day__c = 'THU';
                } else if (dayofWeek == '5') {
                    opp.Drive_Date_Day__c = 'FRI';
                } else if (dayofWeek == '6') {
                    opp.Drive_Date_Day__c = 'SAT';
                } else if (dayofWeek == '7') {
                    opp.Drive_Date_Day__c = 'SUN';
                } else {
                    opp.Drive_Date_Day__c = '';
                }
            }
        }
    }
    
    //2/10/03 new requirement HRP-9304 replaces the old requirement HRP-4875
    //With the new requirement, Direct Donors To is going to be set on the Template when the template is created.  When an opportunity is created from a template, Direct Donors To is 
    //going to default from the template
    public static void updateDirectDonorsTo(Map<Id, Opportunity> oldMap, List<Opportunity> newItems) {
        Map<Id,Id> oppDriveSiteMap = new Map<Id,Id>();
        Map<Id,sked__Location__c> driveSiteMap = null;
        String directDonorsTo;
        for (Opportunity opt : newItems) {
            if(opt.Drive_Site__c != null){
                oppDriveSiteMap.put(opt.id,opt.Drive_Site__c);
            }
        }
        
        if(oppDriveSiteMap != null && oppDriveSiteMap.size() > 0){
            driveSiteMap = new Map<Id,sked__Location__c>([SELECT Id,Name,sked_Room_Name__c FROM sked__Location__c WHERE ID IN:oppDriveSiteMap.values()]);
        }
        
        if(driveSiteMap != null && driveSiteMap.size() > 0) {        
            for (Opportunity opt : newItems) {                
                if(opt.Is_Template__c != true){ //if it is not template, don't bother further checks
                    System.debug('*** updateDirectDonorsTo - Not Template...Skipping Evaluation');
                    continue;
                }
                // HRP - 9780 ---> start (Reducing the length to 128)
                
                directDonorsTo = driveSiteMap.get(opt.Drive_Site__c).sked_Room_Name__c;
                Integer directDonorsToMaxLength =  directDonorsTo.length() >128 ? 128 : directDonorsTo.length();
                opt.Direct_Donors_To__c = directDonorsTo.substring(0,directDonorsToMaxLength); 
                
                // HRP - 9780 ---> end 
                
            }
        }
    }
    
    // HRP-5951
    //Description: stoped calling getOrCreateDefaultSite() and put a Drive_Site__c check and set Site_TBD__c
    public static void assignDefaultSiteDataIfNotPresent(List<Opportunity> newItems) {
        System.debug('Entered method assignDefaultSiteDataIfNotPresent with opp items->' + JSON.serialize(newItems));
        if (newItems == null || newItems.size() < 1)
            return;
        for (Opportunity opp : newItems) {
            if(opp.Is_Template__c == true){ //if its template, don't bother further checks
                continue;
            }
            //System.debug('opp.Drive_Site__c and opp.Drive_Name__c:' + opp.Drive_Site__c + ',' + opp.Drive_Name__c);
            //System.debug('opp:' + JSON.serialize(opp));
            //System.debug('opp:' + opp);
            
            if (opp.Drive_Date__c == null) { //happens only during conversion of lead
                //System.debug('This opportunity does not have drive data->creating default opportunity data');
                //opp.Drive_Site__c = getOrCreateDefaultSite();
                if( opp.Drive_Site__c == null ){
                    opp.Site_TBD__c = true ;
                }
                //this will be a temporary default account associated with this opportunity until lead conversion, 
                //In lead after trigger, this gets replaced with actual account associated with lead
                opp.AccountId = opp.AccountId == null ? getOrCreateDefaultAccount() : opp.AccountId;   //updated per HRP-5016
                opp.Drive_Name__c = 'Default Drive';
                opp.StageName = 'Discovery';
                Date tday = System.today();
                Date driveStartDate = tday.addDays(14);
                Date driveEndDate = tday.addDays(21);
                opp.Drive_Date__c = driveStartDate;
                opp.CloseDate = driveStartDate;
                Time startTime = Time.newInstance(10, 0, 0, 0);
                System.debug('startTime->' + startTime);
                opp.Start_Time__c = startTime;
                Time endTime = Time.newInstance(15, 30, 0, 0);
                System.debug('endTime->' + endTime);
                //opp.Flow_Start_Time_Field__c = '10:00 AM';
                opp.Flow_Start_Time_Field__c = '1500';
                
                opp.Flow_End_Time_Field__c = '1530';
                //opp.Flow_End_Time_Field__c = '3:30 PM';
                
                opp.End_Time__c = endTime;
                opp.WB_Projected_Procedures__c = 4;
                opp.X2RBC_Projected_Procedures__c = 2;
                opp.Name = 'Default Opportunity';
                opp.Anticipated_Registered_Donors__c = 25;
                
            }
            
        }
        
    }
    
    @testVisible
    private static Id getOrCreateDefaultAccount() {
        List<Account> accList = [SELECT Id from Account where name = 'Default Account'];
        if (accList.size() > 0) {
            System.debug('Found default Account from DB');
            return accList.get(0).id;
        }
        System.debug('No default Account found from DB, creating new');
        //this will be a temporary default account associated with this opportunity until lead conversion, 
        //In lead after trigger, this gets replaced with actual account associated with lead
        Account acc = new Account(name = 'Default Account');
        /*Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();
if(ds.isCreateable()){}*/
        insert acc;
        
        return acc.id;
    }
    
    //SYSTEM Generating Recruitment Meeting task during Closed Stage - HRP -2072
    public static void createRecruitmentTask(List<Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        System.debug('Entered method createRecruitmentTask with opp items->' + newItems);
        if (newItems == null || newItems.size() < 1)
            return;
        set<id> oppIds = new set<id>();
        for (Opportunity opp : newItems) {
            if(opp.Is_Template__c == true || opp.RecordTypeId != MOBILE_OPP_RECTYPEID){ //if its template, don't bother further checks //Changes for HRP-13850
                continue;
            }
            oppIds.add(opp.Id);
        }
        List<task> taskList = new list<task>();
        //Map<id, opportunity> oppMap = new Map<id, opportunity>([select id,Account.Account_Manager__c from opportunity where id = :oppIds]);
        Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Recruitment Meeting').getRecordTypeId();
        
        //part of ticket HRP-9562***starts here***
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppIds
                                                                ];
        
        
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        for (OpportunityTeamMember oppteamem : allOpportunityTeamMembers) {
            if (!oppTeamMembersMap.containsKey(oppteamem.OpportunityId)) {
                oppTeamMembersMap.put(oppteamem.OpportunityId, new List<OpportunityTeamMember>());
            }
            oppTeamMembersMap.get(oppteamem.OpportunityId).add(oppteamem);
        }
        //part of ticket HRP-9562***ends here***
        //HRP-10788
        list<Task> existingRecruitmentTaskList=[select id,whoId,whatId from task where subject = 'Recruitment Planning Meeting' and whatId in:oppIds];// Changes for HRP-7123
        map<id,task> oppidTaskMap = new map<id,task>();
        for(Task t:existingRecruitmentTaskList)
        {
            oppidTaskMap.put(t.whatId,t);
        }
        //HRP-10788
        for (Opportunity opp : newItems) {
            //HRP-10788 earlier the below if condition was only checking stageName change. added check change in Call_List_Recipient_Exist__c
            //if (!oppidTaskMap.containskey(opp.id) && (oldMap == NULL ? (opp.StageName == 'Closed' && opp.Call_List_Recipient_Exist__c) : (((opp.StageName == 'Closed' && opp.StageName != oldMap.get(opp.id).stageName) && opp.Call_List_Recipient_Exist__c) || (opp.Call_List_Recipient_Exist__c && opp.Call_List_Recipient_Exist__c != oldMap.get(opp.id).Call_List_Recipient_Exist__c) && opp.StageName == 'Closed'))) {
            if (!oppidTaskMap.containskey(opp.id) && !opp.StageName.equalsIgnoreCase('Cancelled') && (oldMap == NULL ? opp.StageName == 'Closed' : (opp.StageName == 'Closed' && opp.StageName != oldMap.get(opp.id).stageName))) // HRP-12284  //Changes for HRP-13850
              {
                task recruitmentTask = new task();
                recruitmentTask.RecordTypeId = recTypeId;
                Date taskDueDate = opp.Drive_Date__c.addDays(-50);
                String taskDueDayString = Datetime.newInstance(taskDueDate.year(), taskDueDate.month(),taskDueDate.day()).format('EEE'); 
                if(taskDueDayString.equalsIgnoreCase('Sat')){
                    taskDueDate = taskDueDate.addDays(-1);
                }else if(taskDueDayString.equalsIgnoreCase('Sun')){
                    taskDueDate = taskDueDate.addDays(-2);
                }
                recruitmentTask.ActivityDate = taskDueDate;
                recruitmentTask.OwnerId = getTaskOwner(opp, oppTeamMembersMap,Task_Reassignment_Matrix__mdt.getInstance('Recruitment_Task').Assigned_To__c);//part of ticket HRP-9562;//HRP-12333 added 3rd paarameter// Changes for HRP-7123
                recruitmentTask.subject = 'Recruitment Planning Meeting';
                recruitmentTask.WhatId = opp.id;
                recruitmentTask.Drive_Date__c = opp.Drive_Date__c; //HRP-12700
                taskList.add(recruitmentTask);
              }
        }
        if (!taskList.isEmpty())
        {
            
            list<Task_Platform_Event__e> taskPlatformEventList = new list<Task_Platform_Event__e>();//HRP-10788
            
            if(taskList.size()<=Integer.valueof(System.Label.Recruitment_Task_Limit))//HRP-10788
            {
                Database.SaveResult[] srList = Database.insert(taskList, false);
                
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            }
            //HRP-10788
            else
            {
                for(task t :taskList)
                {
                    Task_Platform_Event__e tp = new Task_Platform_Event__e();
                    tp.RecordTypeId__c=t.RecordTypeId;
                    tp.ActivityDate__c=t.ActivityDate;
                    tp.OwnerId__c=t.OwnerId;
                    tp.Subject__c=t.Subject;
                    tp.WhatId__c=t.WhatId;
                    tp.Drive_Date__c=t.Drive_Date__c; //HRP-12700
                    taskPlatformEventList.add(tp);
                }
            }
            
            if(!taskPlatformEventList.isEmpty())
            {
                Eventbus.publish(taskPlatformEventList);
            }
            //HRP-10788
        }   
    }
    
    //Generate Sponsor Planning Meeting task when Opportunity stage is set to committed or closed
    public static void createSponsorPlanningMeetingTask(List<Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        System.debug('Entered method createSponsorPlanningMeetingTask with opp items->' + newItems);
        if (newItems == null || newItems.size() < 1)
            return;
        set<id> oppIds = new set<id>();
        for (Opportunity opp : newItems) {
            //if it is a template or fixed site opportunity, don't bother further checks
            if(opp.Is_Template__c == true || opp.RecordTypeId == FIXED_SITE_OPP_RECTYPEID){ 
                continue;
            }
            oppIds.add(opp.Id);
        }
        List<task> taskList = new list<task>();
        //Map<id, opportunity> oppMap = new Map<id, opportunity>([select id,Account.Account_Manager__c from opportunity where id = :oppIds]);
        
        set<id> taskIds = new set<id>();
        String taskSubject = Task_Reassignment_Matrix__mdt.getInstance('Sponsor_Planning').Task_Subject__c;//HRP-5337 changes
        List<task> staskList = [select WhatId from task where Subject =: taskSubject And WhatId = :oppIds];//HRP-5337 changes
        for(Task t : staskList) {
            taskIds.add(t.WhatId);
        }
        Opportunity_Date_Setting__mdt mdtOppDateSetting = Opportunity_Date_Setting__mdt.getInstance('Sponsor_Planning_Meeting');
        Integer daysFromDriveDate = mdtOppDateSetting?.Days_from_Drive_Date__c.intValue();
        //part of ticket HRP-9562***starts here***
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppIds
                                                                ];
        
        
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        for (OpportunityTeamMember oppteamem : allOpportunityTeamMembers) {
            if (!oppTeamMembersMap.containsKey(oppteamem.OpportunityId)) {
                oppTeamMembersMap.put(oppteamem.OpportunityId, new List<OpportunityTeamMember>());
            }
            oppTeamMembersMap.get(oppteamem.OpportunityId).add(oppteamem);
        }
        //part of ticket HRP-9562***ends here***
        
        for (Opportunity opp : newItems) {
            if (opp.RecordTypeId == MOBILE_OPP_RECTYPEID && 
                !opp.StageName.equalsIgnoreCase('Cancelled') && //Changes for HRP-13850
                opp.Is_Template__c == false && 
                //(oldMap == null ? (opp.StageName == 'Closed' || opp.StageName == 'Committed') : ((opp.StageName == 'Closed' || opp.StageName == 'Committed') && opp.StageName != oldMap.get(opp.id).StageName)) &&//Commented for HRP-5337
                (Date.Today().daysBetween(opp.Drive_Date__c) <= Integer.ValueOf(label.SponsorPlanningMeetingTaskThresholdDays)) && //added for HRP-5337
                (taskIds.isEmpty() ||(!taskIds.isEmpty() && !taskIds.contains(opp.Id)))) {
                    task sponsorPlanningTask = new task();
                    sponsorPlanningTask.ActivityDate = opp.Drive_Date__c.addDays(-daysFromDriveDate);
                    sponsorPlanningTask.OwnerId = getTaskOwner(opp, oppTeamMembersMap,Task_Reassignment_Matrix__mdt.getInstance('Sponsor_Planning').Assigned_To__c);//part of ticket HRP-9562;//HRP-12333 added 3rd paarameter
                    sponsorPlanningTask.subject = taskSubject;//HRP-5337 changes
                    sponsorPlanningTask.Type = 'Sponsor Planning Meeting';
                    sponsorPlanningTask.Status = 'Not Started';
                    sponsorPlanningTask.Priority = 'Normal';
                    sponsorPlanningTask.Drive_Date__c = opp.Drive_Date__c; //HRP-12700
                    sponsorPlanningTask.WhatId = opp.id;
                    taskList.add(sponsorPlanningTask);
                }
        }
        if (taskList.size() > 0) {
            Database.SaveResult[] srList = Database.insert(taskList, false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
      
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }   
    } 
    
    public static void setCallListRecipientFlag(set<id> accIDs) {
        Map<id, opportunity> oppMap = new Map<id, opportunity>([select id,Accountid from opportunity where Accountid = :accIDs]);
        List<opportunity> oppList = new List<opportunity>();
        for (opportunity opp : oppMap.values()) {
            opp.Call_List_Recipient_Exist__c = true;
            oppList.add(opp);
        }
        
        if (oppList.size() > 0) {
            update oppList;
        }
    }
    
    //Update Earliest Drive Date for all Closed Blood Drive Opportunities HRP-1760
    public static void updateAccountWithEarliestDriveDate(List<Opportunity> newOppList,Map<Id, Opportunity> oldMap) {
        list<Opportunity> closedOppList = new list<Opportunity>();
        set<Id> setOfAccId = new set<Id>();
        for (Opportunity opp : newOppList) {
            if(opp.Is_Template__c == true){ //if its template, don't bother further checks
                continue;
            }
            if ((oldMap==null ||(oldMap!=null && oldMap.get(opp.id).stageName !=opp.stageName)) && opp.stageName == 'closed') {
                setOfAccId.add(opp.AccountId);
                closedOppList.add(opp);
            }
        }
        list<Opportunity> oldClosedOppListOfThisAcc = [
            select id,name,accountId,stageName, drive_date__c
            from opportunity
            where stageName = 'closed' and accountId = :setOfAccId
        ];
        if (oldClosedOppListOfThisAcc.size() > 0) {
            closedOppList.addAll(oldClosedOppListOfThisAcc);
        }
        if (closedOppList.size() > 0)
            system.debug('###QQQ');
        updateAccount(closedOppList);
        OpportunityRecursive.isOpportunity = false ;
    }
    
    public static void updateAccount(list<opportunity> closedOppList) {
        Map<Id, list<Date>> mapOfListOfAccountIdWithOppDriveDate = new Map<Id, list<Date>>();
        List<Account> list_AccountsToUpdate = new List<Account>();
        
        for (opportunity opp : closedOppList) {
            if (opp.AccountId != null) {
                if (!mapOfListOfAccountIdWithOppDriveDate.containsKey(opp.AccountId)) {
                    mapOfListOfAccountIdWithOppDriveDate.put(opp.AccountId, new List<Date>());
                }
                if (opp.Drive_Date__c != null)
                    mapOfListOfAccountIdWithOppDriveDate.get(opp.AccountId).add(opp.Drive_Date__c);
            }
        }
        
        for (id i : mapOfListOfAccountIdWithOppDriveDate.keyset()) {
            mapOfListOfAccountIdWithOppDriveDate.get(i).sort();
        }
        
        for (Account acc : [
            select id,Earliest_Drive_Date__c,account_status__c
            from account
            where id in:mapOfListOfAccountIdWithOppDriveDate.keyset()
        ]) {
            Boolean accountUpdated = false;
            if(acc.Earliest_Drive_Date__c !=mapOfListOfAccountIdWithOppDriveDate.get(acc.id).get(0))
            {
                acc.Earliest_Drive_Date__c = mapOfListOfAccountIdWithOppDriveDate.get(acc.id).get(0);
                accountUpdated=true;
            }
            if(acc.Account_Status__c =='Prospect' || acc.Account_Status__c =='Reactivate')
            {
                acc.Account_Status__c='Active';
                accountUpdated=true;
            }
            
            if(accountUpdated)
                list_AccountsToUpdate.add(acc);
        }
        Database.update(list_AccountsToUpdate);
    }
    
    
    //Added as part of HRP-1084
    //Update Default allocation fields based on Covering Recruiter and Coverage Reason
    public static void insertOrUpdateCovRecruiterOpportunitySplit(list<opportunity> newOppsList, Map<Id, Opportunity> oldOpptyMap) {
        Set<Id> accIdset = new Set<Id>();
        Set<Id> opptyIdset = new Set<Id>();
        for (Opportunity opty : newOppsList) {
            if (oldOpptyMap == null || opty.Drive_Date__c != oldOpptyMap.get(opty.Id).Drive_Date__c) {
                opptyIdset.add(opty.Id);
                accIdset.add(opty.AccountId);
            }
        }
        
        OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName = 'Overlay'];
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>([SELECT Id, Drive_Date__c,AccountId,Account.Account_Manager__c, (SELECT OpportunityId,SplitTypeId,SplitOwnerId,SplitPercentage FROM OpportunitySplits WHERE SplitTypeId = :overlaySplitType.Id AND Is_Covering_Incentive__c = true) FROM Opportunity WHERE Id IN:opptyIdset]);
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, (Select AccountId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Coverage_Reason__c,TeamMemberRole,UserId FROM AccountTeamMembers WHERE Is_Covering_Recruiter__c = true Order By Start_Date__c) FROM Account Where Id IN:accIdset]);
        
        Map<Id, OpportunitySplit> opptySplitDeleteMap = new Map<Id, OpportunitySplit>();
        List<OpportunitySplit> opptySplitInsertList = new List<OpportunitySplit>();
        
        for (Opportunity oppty : newOppsList) {
            
            if (!opptyIdset.contains(oppty.Id))
                continue;
            
            Opportunity existingOppty = opptyMap.get(oppty.Id);
            List<AccountTeamMember> acctTeamMembers = accMap.get(oppty.AccountId).AccountTeamMembers;
            Boolean noCovRecruiter = false;
            Boolean outsideDateRange = true;
            if (acctTeamMembers == null || acctTeamMembers.size() == 0) {
                noCovRecruiter = true;
            } else {
                
                for (AccountTeamMember newTeamMember : acctTeamMembers) {
                    if (oppty.Drive_Date__c >= newTeamMember.Start_Date__c && oppty.Drive_Date__c <= newTeamMember.End_Date__c) {
                        outsideDateRange = false;
                        
                        OpportunitySplit opptyAMSplit = null;
                        OpportunitySplit opptyCovRecruiterSplit = null;
                        
                        for (OpportunitySplit opptySplit : existingOppty.OpportunitySplits) {
                            if (opptySplit.SplitOwnerId == newTeamMember.UserId) {
                                opptyCovRecruiterSplit = opptySplit;
                            } else if (opptySplit.SplitOwnerId == existingOppty.Account.Account_Manager__c) {
                                opptyAMSplit = opptySplit;
                            } else {
                                opptySplitDeleteMap.put(opptySplit.Id, opptySplit);
                            }
                        }
                        
                        OpportunitySplit splitForAM = new OpportunitySplit();
                        splitForAM.SplitTypeId = overlaySplitType.Id;
                        splitForAM.OpportunityId = oppty.Id;
                        splitForAM.SplitOwnerId = existingOppty.Account.Account_Manager__c;
                        System.debug('SplitOwnerId: ' + splitForAM.SplitOwnerId);
                        splitForAM.SplitPercentage = 100;
                        splitForAM.Is_Covering_Incentive__c = true;
                        
                        //Adding Split Record for Covering Recruiter
                        OpportunitySplit splitCoveringRec = new OpportunitySplit();
                        splitCoveringRec.SplitTypeId = overlaySplitType.Id;
                        splitCoveringRec.OpportunityId = oppty.Id;
                        splitCoveringRec.SplitOwnerId = newTeamMember.UserId;
                        splitCoveringRec.SplitPercentage = 100;
                        splitCoveringRec.Is_Covering_Incentive__c = true;
                        
                        if (newTeamMember.Coverage_Reason__c == BSF_Constants.accTeamLoa) {
                            splitCoveringRec.Split_Reason__c=BSF_Constants.opSplitLoa;//HRP-11168
                            if (opptyCovRecruiterSplit == null) {
                                opptySplitInsertList.add(splitCoveringRec);
                            }   
                        } else if (newTeamMember.Coverage_Reason__c == BSF_Constants.accTeamVacant) {
                            splitCoveringRec.Split_Reason__c=BSF_Constants.opSplitVacant;//HRP-11168
                            if (opptyCovRecruiterSplit == null) {
                                opptySplitInsertList.add(splitCoveringRec);
                            }
                            if (opptyAMSplit != null) {
                                opptySplitDeleteMap.put(opptyAMSplit.Id, opptyAMSplit);
                            }
                        } 
                    }
                }
            }
            if ((noCovRecruiter || outsideDateRange) && existingOppty.OpportunitySplits != null && existingOppty.OpportunitySplits.size() > 0)
                opptySplitDeleteMap.putAll(existingOppty.OpportunitySplits); 
        }
        try {
            if (opptySplitInsertList.size() > 0)
            {
                OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                Database.insert(opptySplitInsertList);
            }
            
            if (opptySplitDeleteMap.values() != null && opptySplitDeleteMap.values().size() > 0)
            {
                OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                Database.delete(opptySplitDeleteMap.values());
            }
            
        } catch (Exception e) {
            System.debug('Error occured: ' + e.getMessage());
        }
    }
    
    //HRP-13521 changes starts
    public static void checkProductEndDate(list<Opportunity> newList, Map<Id, Opportunity> oldMap){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<Id,Id> amMap = new Map<Id,Id>();
        List<OrderItem> orderItemListToDelete = new List<OrderItem>();
        List<BSF_Error_Log__c> bsfErrorList = new List<BSF_Error_Log__c>();
        try{
            if(newList != null && !newList.isEmpty() && oldMap != null && !oldMap.isEmpty()){
                for(Opportunity opp : newList){
                    if(opp.Id != null && oldMap.containsKey(opp.Id) && !opp.Is_Template__c && opp.Drive_Date__c != null 
                            && oldMap.get(opp.Id).Drive_Date__c != opp.Drive_Date__c){
                                oppMap.put(opp.Id,opp);
                    }
                }
            }
            if(!oppMap.isEmpty()){
                List<OrderItem> odrItemList = [SELECT Id,
                                                        OrderId,
                                                        Order.OpportunityId,
                                                     Order.Opportunity.Name,
                                                     Order.Opportunity.AccountId,
                                                     Order.Opportunity.Account.Account_Manager__c,
                                                        Product2Id,
                                                        Product2.Name,
                                                        Product2.Description,
                                                        Product2.Start_Date__c,
                                                        Product2.End_Date__c 
                                                FROM OrderItem
                                                WHERE Order.OpportunityId IN :oppMap.keySet()];
                for(OrderItem oItem : odrItemList){
                    if(oItem.Product2.Start_Date__c != null && oItem.Product2.End_Date__c != null
                            && (oItem.Product2.Start_Date__c > oppMap.get(oItem.Order.OpportunityId).Drive_Date__c
                            || oItem.Product2.End_Date__c < oppMap.get(oItem.Order.OpportunityId).Drive_Date__c)){
                                orderItemListToDelete.add(oItem);
                    }else if(oItem.Product2.Start_Date__c != null && oItem.Product2.End_Date__c == null
                            && oItem.Product2.Start_Date__c > oppMap.get(oItem.Order.OpportunityId).Drive_Date__c){
                                orderItemListToDelete.add(oItem);
                    }else if(oItem.Product2.Start_Date__c == null && oItem.Product2.End_Date__c != null
                            && oItem.Product2.End_Date__c < oppMap.get(oItem.Order.OpportunityId).Drive_Date__c){
                                orderItemListToDelete.add(oItem);
                    }
                    if(oItem.Order.Opportunity.AccountId != null && oItem.Order.Opportunity.Account.Account_Manager__c != null){
                        amMap.put(oItem.Id,oItem.Order.Opportunity.Account.Account_Manager__c);
                    }
                }
            }
            if(!orderItemListToDelete.isEmpty()){
                List<CUstomNotificationType> CUstomNotificationTypeList = [SELECT Id 
                                                                            FROM CUstomNotificationType 
                                                                            WHERE DeveloperName = 'Account_Custom_Notification'];
                if(!CUstomNotificationTypeList.isEmpty() && !amMap.isEmpty()) {
                    for(OrderItem oItem : orderItemListToDelete){
                        if(amMap.containsKey(oItem.Id)){
                            new BSF_CustomNotification()
                                .body('The Publicity Item ' + oItem.Product2.Name + 
                                      ' has been removed from the Opportunity : ' + oItem.Order.Opportunity.Name + 
                                      '. This is the description of the Product: ' + oItem.Product2.Description)
                                .title('Publicity Item ' + oItem.Product2.Name + 
                                       ' has been removed from the Order of this Blood Drive Opportunity: ' + 
                                       oItem.Order.Opportunity.Name)
                                .sender(Userinfo.getUserId())
                                .typeId(CUstomNotificationTypeList[0].Id)
                                .target(oItem.Order.OpportunityId) 
                                .category('DriveDateOutsideProductStartEnd') 
                                .send(new List<String>{amMap.get(oItem.Id)});
                        }
                    }
                }
                Database.DeleteResult[] drList = Database.delete(orderItemListToDelete, false);
                List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(drList,'Delete OrderItems','OpportunityService','checkProductEndDate','Error', 'Error in Deleting OrderItems');
                if(!errorList.isEmpty()){
                    bsfErrorList.addAll(errorList);
                }
            }
        }catch(Exception ex){
            bsfErrorList.add(BSF_Utilities.createBsfErrorLogForExceptions(ex,'OpportunityService','checkProductEndDate','Delete OrderItems', 'Error in Deleting OrderItems','OrderItem',null));
            Database.insert(bsfErrorList, true);
        }
    }
    //HRP-13521 changes ends
    
    //HRP-3571 System Automatically Create Template Name
    //12/9 FWO - updated so that it can be called from "before insert trigger"
    public static void generateTemplateOppName(list<Opportunity> oppNewTmpList, map<Id, Opportunity> oppOldTmpMap) {
        String oppTmpName;
        if (oppNewTmpList.size() > 0) {
            for (opportunity opp : oppNewTmpList) {
                if ((oppOldTmpMap != null && oppOldTmpMap.get(opp.Id).is_template__c == false && opp.is_template__c == true) ||
                    (oppOldTmpMap == null && opp.is_template__c == true)) {
                        //if (oppOldTmpMap.get(opp.Id).is_template__c == false && opp.is_template__c == true) { //commented out and replaced with above to allow call from before insert
                        if (opp.Template_Status__c == null) {
                            opp.Template_Status__c = 'Active';
                        }
                        oppTmpName = opp.Account_Internal_Name__c + ' - ' + opp.Drive_Site_Name__c;
                        if (opp.Additional_Description__c != null) {
                            oppTmpName = oppTmpName + ' - ' + opp.Additional_Description__c ;
                        }
                        if (opp.Template_Status__c == 'Inactive') {
                            oppTmpName = oppTmpName + ' - ' + 'Inactive';
                        }
                        Integer nameMaxLength =  oppTmpName.length()>120? 120:oppTmpName.length();
                        Integer driveNameMaxLength =  oppTmpName.length()>255? 255:oppTmpName.length();
                        
                        opp.Name = oppTmpName.substring(0,nameMaxLength);
                        system.debug('opportunity template name##'+opp.Name);
                        opp.Drive_Name__c = oppTmpName.substring(0,driveNameMaxLength); //added to replace workflow
                    }
            }
        }
    }
    
    //12/9 FWO - updated so that it can be called from "before insert trigger"
    public static void reGenerateTemplateOppName(list<Opportunity> oppNewTmpList, map<Id, Opportunity> oppOldTmpMap) {
        String oppTmpName;
        if (oppNewTmpList.size() > 0) {
            for (opportunity opp : oppNewTmpList) {
                if (((oppOldTmpMap != null && opp.is_template__c == true && opp.is_template__c == oppOldTmpMap.get(opp.Id).is_template__c)
                     && (opp.Account_Internal_Name__c != oppOldTmpMap.get(opp.Id).Account_Internal_Name__c ||
                         opp.Additional_Description__c != oppOldTmpMap.get(opp.Id).Additional_Description__c ||
                         opp.Drive_Site_Name__c != oppOldTmpMap.get(opp.Id).Drive_Site_Name__c ||
                         opp.Template_Status__c != oppOldTmpMap.get(opp.Id).Template_Status__c)) ||
                    (oppOldTmpMap != null && opp.is_template__c)){
                        //if ((opp.is_template__c == true && opp.is_template__c == oppOldTmpMap.get(opp.Id).is_template__c) //commented out and replaced with above to allow call from before insert
                        //&& (opp.Account_Internal_Name__c != oppOldTmpMap.get(opp.Id).Account_Internal_Name__c ||
                        //opp.Additional_Description__c != oppOldTmpMap.get(opp.Id).Additional_Description__c ||
                        //opp.Drive_Site_Name__c != oppOldTmpMap.get(opp.Id).Drive_Site_Name__c ||
                        //opp.Template_Status__c != oppOldTmpMap.get(opp.Id).Template_Status__c)) {*/
                        
                        if (opp.Template_Status__c == null) {
                            opp.Template_Status__c = 'Active';
                        }
                        oppTmpName = opp.Account_Internal_Name__c + ' - ' + opp.Drive_Site_Name__c ;
                        if (opp.Additional_Description__c != null) {
                            oppTmpName = oppTmpName + ' - ' + opp.Additional_Description__c ;
                        }
                        if (opp.Template_Status__c == 'Inactive') {
                            oppTmpName = oppTmpName + ' - ' + 'Inactive';
                        } else {
                            if (opp.Name.contains('Inactive')) {
                                opp.Name.removeEnd('Inactive');
                            }
                        }
                        Integer nameMaxLength =  oppTmpName.length()>120? 120:oppTmpName.length();
                        Integer driveNameMaxLength =  oppTmpName.length()>255? 255:oppTmpName.length();
                        
                        opp.Name = oppTmpName.substring(0,nameMaxLength);
                        system.debug('opportunity template name1##'+opp.Name);     
                        opp.Drive_Name__c = oppTmpName.substring(0,driveNameMaxLength); //added to replace workflow
                    }
            }
        }
    }
    /* HRP-3593
* System Automatically Create Template Name  
*
public static void generateTemplateOppId(list<Opportunity> oppNewTmpList, map<Id, Opportunity> oppOldTmpMap) {
Integer maxTemplateId;
list<opportunity> oppTmpExistingList = [
Select id, Template_Id__c, is_template__c
from opportunity
where is_template__c = true
and Template_Id__c!=null
Order by Template_Id__c desc
];
if (oppTmpExistingList.size() > 0) {
maxTemplateId = Integer.valueof(oppTmpExistingList[0].Template_Id__c);
System.debug('maxTemplateId computed:'+maxTemplateId);
}
System.debug('oppOldTmpMap->'+oppOldTmpMap);
System.debug('oppNewTmpList->'+oppNewTmpList);


if (oppNewTmpList.size() > 0) {
for (Opportunity opp : oppNewTmpList) {
if ((oppOldTmpMap.get(opp.Id).is_template__c == false && opp.is_template__c == true)
|| opp.Template_Id__c == null){
opp.Template_Id__c = maxTemplateId == null ? '1' : String.valueOf(maxTemplateId + 1);
System.debug('opp.Template_Id__c ->'+opp.Template_Id__c);
}
maxTemplateId = maxTemplateId == null ? 1 : maxTemplateId + 1;
}
}
} */
    
    public static void templateActiveCheckValidation(list<Opportunity> oppNewList, map<Id, Opportunity> oppOldMap) {
        
        Set<Id> oppSet = new Set<Id>();
        Map<Id, Id> tempOppMap = new Map<Id, Id>();
        for (Opportunity opp : oppNewList) {
            
            System.debug('oppOldMap======' + opp.Template_Status__c);
            System.debug('opp======' + oppOldMap.get(opp.Id).Template_Status__c);
            if (opp.Parent_Template_Id__c == null && opp.Is_Template__c && opp.Template_Status__c == 'Inactive' && opp.Template_Status__c != oppOldMap.get(opp.Id).Template_Status__c) {
                
                oppSet.add(opp.id);
            }
        }
        System.debug('oppSet=====' + oppSet);
        for (Opportunity tempOpp : [select id,Parent_Template_Id__c from Opportunity where Parent_Template_Id__c IN :oppSet and Drive_Date__c >= Today
                                    AND StageName != 'Cancelled'
                                    AND StageName != 'Withdrawn']) {
                                        
                                        tempOppMap.put(tempOpp.Parent_Template_Id__c, tempOpp.Parent_Template_Id__c);
                                    }
        System.debug('tempOppMap=====' + tempOppMap);
        for (Opportunity opp : oppNewList) {
            
            if (tempOppMap.containsKey(opp.Id) && opp.Parent_Template_Id__c == null && opp.Is_Template__c && opp.Template_Status__c == 'Inactive' && opp.Template_Status__c != oppOldMap.get(opp.Id).Template_Status__c) {
                
                opp.addError('Template cannot be made inactive because of active related opportunities') ;
            }
        }  
    }
    
    // HRP-10882 --> Starts Here
    public static Map<Id,String> validateRequiredSiteFieldsBasedOnOppStage(List<Opportunity> newOppList, map<Id, Opportunity> oppOldMap)
    {        
        Set<Id> oppDriveSiteId = new Set<Id>();
        List<Opportunity> validOppList = new List<Opportunity>();
        String customErrorMessage = Custom_Messages__mdt.getInstance('Validate_Site_Fields').value__c;
        List<Site_Mandatory_Fields_Setting__mdt> siteMandatoryFieldCustomMetadataList = Site_Mandatory_Fields_Setting__mdt.getAll().values(); 
        Map<Id,String> oppIdVsErrorMsgMap = new Map<Id,String>();

        for(Opportunity newOpp : newOppList)
        {
            if(newOpp.Is_Template__c)
            {
                continue;
            }
            Opportunity oldOpp = oppOldMap.get(newOpp.Id);
            if(oldOpp != NULL && !oldOpp.stageName.equals(newOpp.stageName) && newOpp.StageName.equals(BSF_Constants.STAGE_CLOSED))
            {
                oppDriveSiteId.add(newOpp.drive_site__c);
                validOppList.add(newOpp);
            }
        }

        Map<Id,sked__Location__c> driveSiteMap = new Map<Id,sked__Location__c>([SELECT sked_Directions_From_CollectionOperation__c, sked_Floor_Description__c, 
                                                                                    sked_Outside_stairs__c, sked_Inside_stairs__c, sked_Physical_Location_Type__c, 
                                                                                    sked_Site_Main_Phone__c, sked_Room_Name__c, sked_Site_Building_Name__c, Operation_Type__c,
                                                                                    sked_Site_Contact__c, sked_Automation_Suitability__c,sked_Staff_Personal_Parking_Directions__c
                                                                                    FROM sked__Location__c where Id IN: oppDriveSiteId]);

       if(!validOppList.isEmpty() && validOppList.size() > 0)
       {
            for(Opportunity newOpp : validOppList)
            { 
                List<String> missingFieldsList = new List<String>();
                
                for(Site_Mandatory_Fields_Setting__mdt siteFieldMetdata : siteMandatoryFieldCustomMetadataList)
                {
                    List<String> recordTypeList = siteFieldMetdata.Required_For__c.split(',');
                    
                    if(driveSiteMap.get(newOpp.Drive_Site__c).get(siteFieldMetdata.Field_Name__c) == NULL && recordTypeList.contains(newOpp.Type_of_Drive__c))
                    {                         
                        missingFieldsList.add(siteFieldMetdata.Field_Label__c);
                    }
                }                   

                if(missingFieldsList.size()> 0)
                {
                    customErrorMessage = customErrorMessage.replace('[object]' , newOpp.Type_of_Drive__c+' opportunity');
                    customErrorMessage = customErrorMessage.replace('[StageOrStatus]' , 'Closed Stage');
                    customErrorMessage = customErrorMessage.replace('missingFields' , String.join(missingFieldsList, ', '));
                    oppIdVsErrorMsgMap.put(newOpp.Id, customErrorMessage);
                    
                }
            }
        }
        return oppIdVsErrorMsgMap;        
    }
    
    //HRP-10882 --> Ends Here
    
    /*public static void validateRequiredSiteFieldsBasedOnOppStage(Map<Id, Opportunity> newMap, map<Id, Opportunity> oppOldMap) {
        
        Set<Id> oppSet = new Set<Id>();
        Map<Id, Opportunity> tempOppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : newMap.values()) {
            oppSet.add(opp.id);
        }
        System.debug('oppSet=====' + oppSet);
        for (Opportunity tempOpp : [
            select id,StageName,recordtype.name,Drive_Site__r.Name,Drive_Site__r.sked__Address__c,Drive_Site__r.sked__Requires_Whitelist__c,Drive_Site__r.sked__Type__c,Drive_Site__r.sked_Active__c,
            Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c,Drive_Site__r.sked_Automation_Suitability__c,Drive_Site__r.sked_Base_Description__c,Drive_Site__r.sked_Directions_From_CollectionOperation__c,Drive_Site__r.sked_Floor_Description__c,Drive_Site__r.sked_Inside_stairs__c,Drive_Site__r.sked_National_Name__c,
            Drive_Site__r.sked_Outside_stairs__c,Drive_Site__r.sked_Pay_for_Parking_Details__c,Drive_Site__r.sked_Physical_Location_Type__c,
            Drive_Site__r.sked_Room_Name__c,Drive_Site__r.sked_Room_Size__c,Drive_Site__r.sked_Site_Building_Name__c,Drive_Site__r.sked_Site_Inspection_Completed_By__c,
            Drive_Site__r.sked_Site_Main_Phone__c,Drive_Site__r.sked_Staff_Personal_Parking_Directions__c,Drive_Site__r.sked_Travel_Time_to_Staging_Location__c
            from Opportunity
            where id IN :oppSet
        ]) {
            system.debug('------->' + tempOpp);
            system.debug('------->' + tempOpp.Drive_Site__r.sked_Travel_Time_to_Staging_Location__c);
            if (tempOpp.Drive_Site__r == null) {
                return;
            }
            /* This part is commented as skedulo will delete the field sked_Travel_Time_to_Staging_Location__c 
* and this validation is no longer required as part of the bug HRP-6221
*/
            //solicitation    //&& tempOpp.StageName != oppOldMap.get(tempOpp.Id).StageName
            /*  if (tempOpp.StageName == 'Solicitation' && tempOpp.recordtype.name == 'Mobile opp') {
if (tempOpp.Drive_Site__r.sked_Travel_Time_to_Staging_Location__c == null) {
newMap.get(tempOpp.id).addError('Site : Travel Time to Staging Location is a required field to move opportunity to Solicitation') ;
}
} 
            
            
            //Committed
            if (tempOpp.StageName == 'Committed' && tempOpp.recordtype.name == 'Mobile opp') {
                if (tempOpp.Drive_Site__r.sked__Requires_Whitelist__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Requires Whitelist is a required field to move opportunity to Committed') ;
                }
                
                if (tempOpp.Drive_Site__r.sked_Room_Size__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Room Size is a required field to move opportunity to Committed') ;
                }
                
                /*if (tempOpp.Drive_Site__r.sked_Site_Inspection_Completed_By__c == null) {
newMap.get(tempOpp.id).addError('Site : Site Inspection Completed By is a required field to move opportunity to Committed') ;
}
            }
            
            if (tempOpp.StageName == 'Closed' && tempOpp.recordtype.name == 'Mobile opp') {
                /*if (tempOpp.Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c == null) {
newMap.get(tempOpp.id).addError('Site : ARC Vehicle Parking Directions is a required field to move opportunity to Closed') ;
}
if (tempOpp.Drive_Site__r.sked_Base_Description__c == null) {
newMap.get(tempOpp.id).addError('Site : Base Description is a required field to move opportunity to Closed') ;
}
                
                if (tempOpp.Drive_Site__r.sked_Directions_From_CollectionOperation__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Directions From Collection Operation is a required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_Floor_Description__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Floor Description is a required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_Inside_stairs__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Inside stairs is a required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_National_Name__c == null) {
                    newMap.get(tempOpp.id).addError('Site : National Name is a required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_Outside_stairs__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Outside stairs required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_Pay_for_Parking_Details__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Pay for Parking Details is a required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_Physical_Location_Type__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Physical Location Type is a required field to move opportunity to Closed') ;
                }
                if (tempOpp.Drive_Site__r.sked_Site_Main_Phone__c == null) {
                    newMap.get(tempOpp.id).addError('Site : Site Main Phone is a required field to move opportunity to Closed') ;
                }
                
                /*if (tempOpp.Drive_Site__r.sked_Staff_Personal_Parking_Directions__c == null) {
newMap.get(tempOpp.id).addError('Site : Staff Personal Parking Directions is a required field to move opportunity to Closed') ;
}*
            }
            
            if (tempOpp.StageName == 'Closed' && tempOpp.Drive_Site__r.sked_National_Name__c == null) {
                newMap.get(tempOpp.id).addError('Site : National Name is a required field to move opportunity to Closed') ;
            } 
        }
    }*/
    
    //This method updates only the field Drive_Name__c on the opportunity
    public static void updateOpportunityName(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
        for (Opportunity newOpportunity : newOpportunityList) {
            Opportunity oldOpportunity = oldOpportunityMap != null && !oldOpportunityMap.isEmpty() && oldOpportunityMap.containsKey(newOpportunity.Id) ? oldOpportunityMap.get(newOpportunity.Id) : new Opportunity();
            if (!newOpportunity.is_template__c && newOpportunity.Drive_Date__c != null && (newOpportunity.Is_Account_Internal_Name_Changed__c != oldOpportunity.Is_Account_Internal_Name_Changed__c || newOpportunity.Drive_Date__c != oldOpportunity.Drive_Date__c || (newOpportunity.RecordTypeId == MOBILE_OPP_RECTYPEID && (newOpportunity.Linked_Opportunity_Drives__c != oldOpportunity.Linked_Opportunity_Drives__c || newOpportunity.Is_this_part_of_MultiDay_Drive__c != oldOpportunity.Is_this_part_of_MultiDay_Drive__c)))) {
                String oppName = '';
                Integer ddMonth = newOpportunity.Drive_Date__c.month();
                Date fyDriveDate = ddMonth > 6 ? newOpportunity.Drive_Date__c.addYears(1) : newOpportunity.Drive_Date__c;
                Datetime fyDriveDT = Datetime.newInstance(fyDriveDate, Time.newInstance(0, 0, 0, 0));
                //System.debug('OpportunityService.updateOpportunityName : fyDriveDT : ' + fyDriveDT);
                Datetime driveDT = Datetime.newInstance(newOpportunity.Drive_Date__c, Time.newInstance(0, 0, 0, 0));
                if (newOpportunity.RecordTypeId == FIXED_SITE_OPP_RECTYPEID) {
                    oppName = 'FY' + fyDriveDT.format('YY') + '_' + driveDT.format('EEEE') + '_' + driveDT.format('MMMM') + '_' + newOpportunity.Account_Internal_Name__c + '_' + driveDT.format('MMdd');
                } else if (newOpportunity.RecordTypeId == MOBILE_OPP_RECTYPEID) {
                    String quarter = (ddMonth >= 7 && ddMonth <= 9) ? 'Q1' : (ddMonth >= 10 && ddMonth <= 12) ? 'Q2' : (ddMonth >= 1 && ddMonth <= 3) ? 'Q3' : (ddMonth >= 4 && ddMonth <= 6) ? 'Q4' : '';
                    oppName = 'FY' + fyDriveDT.format('YY') + '_' + quarter + '_' + newOpportunity.Account_Internal_Name__c + '_' + driveDT.format('MMddYY') + (newOpportunity.Linked_Opportunity_Drives__c != null ? ' L' : '') + (newOpportunity.Is_this_part_of_MultiDay_Drive__c ? ' M' : '');
                }
                if (newOpportunity.Is_Account_Internal_Name_Changed__c) {
                    newOpportunity.Is_Account_Internal_Name_Changed__c = false;
                }
                //String opportunityName = newopportunity.Account_Internal_Name__c+',pp' +newopportunity.Site_Building_Name__c;
                //newOpportunity.name = opportunityName.length()<=120 ? opportunityName : opportunityName.substring(0,120);*/
                System.debug('Setting oppName as ->'+oppName);
                if (String.isNotBlank(oppName)) {
                    //system.debug('OpportunityService.updateOpportunityName oppName: ' + oppName.length());
                    Integer length = 255;
                    if(oppName.length()>= length){
                        newOpportunity.Drive_Name__c = oppName.substring(0, length); //as per story HRP-4232
                        //newOpportunity.Name=oppName.substring(0, length);
                        
                    }else{
                        newOpportunity.Drive_Name__c = oppName; //as per story HRP-4232
                        // newOpportunity.Name=oppName;
                    }
                }
            }
        }
    }
    
    // 2/3/22 updated by FWO per HRP-6172
    public static void updateOpportunitiesRelatedToTemplate(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList) {
        Map<Id, Opportunity> templateOpportunityMap = new Map<Id, Opportunity>();
        for (Opportunity newOpportunity : newOpportunityList) {
            Opportunity oldOpportunity = oldOpportunityMap?.get(newOpportunity.Id);
            
            if (newOpportunity.Is_Template__c && oldOpportunity != null && (newOpportunity.Anticipated_Registered_Donors__c != oldOpportunity.Anticipated_Registered_Donors__c ||
                                                                            newOpportunity.WB_Projected_Procedures__c != oldOpportunity.WB_Projected_Procedures__c ||
                                                                            newOpportunity.X2RBC_Projected_Procedures__c != oldOpportunity.X2RBC_Projected_Procedures__c)) {
                                                                                templateOpportunityMap.put(newOpportunity.Id, newOpportunity);
                                                                            }
        }
        if (!templateOpportunityMap.isEmpty()) {
            List<Opportunity> opportunityUpdateList = [SELECT Id, Parent_Template_Id__c, Procedure_Projections_Template__c, Projected_Registered_Donors_Template__c, Staffing_Template__c, Volunteers_Template__c, WholeBloodProceduresProjectedTemplate__c, Double_Red_Procedures_Projected_Template__c, Anticipated_Registered_Donors_Template__c, Direct_Donors_To__c FROM Opportunity WHERE Parent_Template_Id__c IN:templateOpportunityMap.keySet() AND Is_Template__c = FALSE AND Drive_Date__c >= TODAY];
            for (Opportunity opportunity : opportunityUpdateList) {
                Opportunity templateOpportunity = templateOpportunityMap.get(opportunity.Parent_Template_Id__c);
                opportunity.WholeBloodProceduresProjectedTemplate__c = templateOpportunity.WB_Projected_Procedures__c; 
                opportunity.Double_Red_Procedures_Projected_Template__c = templateOpportunity.X2RBC_Projected_Procedures__c; 
                opportunity.Anticipated_Registered_Donors_Template__c = templateOpportunity.Anticipated_Registered_Donors__c;
            }
            
            /*Commented Out for HRP-9834 [Start ->>]

if (!opportunityUpdateList.isEmpty()) {
update opportunityUpdateList;
}

Commented Out for HRP-9834 [<<- End]*/
            
            /*[ Added it for HRP-9834 
Note : It'll throw error if any sort of consequences happen when projection values are updating in BDO from related template opportunity projection values.]*/
            // [Start->>]
            Database.SaveResult[] srList = Database.update(opportunityUpdateList , false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating opportunity from template','OpportunityService','updateOpportunitiesRelatedToTemplate','Error','Error in updating Opportunity from template opportunity');
            InsertBsfErrorLog.insertBsfErrors(logList);
            // [<<-End]
        }
    }
    
    public static void autoPopulateOpportunityTemplateValues(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList) {
        List<Opportunity> lstOppsWithTBDSite = new List<Opportunity>();
        Set<Id> templateOpportunityIds = new Set<Id>();
        String templateChangedText = 'Template got changed. ' + system.now(); //HRP-12479
        
        for (Opportunity newOpportunity : newOpportunityList) {
            if (isInsertOrUpdateWithChangeInTemplate(oldOpportunityMap, newOpportunity)) {
                templateOpportunityIds.add(newOpportunity.Parent_Template_Id__c);
            }
            /* added by Satabdi as per HRP-6520 */
            else if(oldOpportunityMap != null){
                if(newOpportunity.Drive_Site__c != null && newOpportunity.Parent_Template_Id__c == null && 
                   oldOpportunityMap.get(newOpportunity.Id).Parent_Template_Id__c != newOpportunity.Parent_Template_Id__c
                   &&  !newOpportunity.Is_Template__c){
                       newOpportunity.addError('Parent Template Id can not be blank. Please select a template.');
                   }
            }
            /* Added by FWO per (HRP-6162) */
            else if(newOpportunity.Drive_Site__c == null && newOpportunity.Parent_Template_Id__c == null) {
                lstOppsWithTBDSite.add(newOpportunity);
            }
        }
        
        if (!templateOpportunityIds.isEmpty()) {
            Map<Id, Opportunity> templateOpportunityMap = new Map<Id, Opportunity>([SELECT Id,X2RBC_Projected_Procedures__c, Anticipated_Registered_Donors__c, Drive_Site__c,Direct_Donors_To__c,Site_TBD__c,Procedure_Projections_Template__c, Projected_Registered_Donors_Template__c, Staffing_Template__c, Volunteers_Template__c, WholeBloodProceduresProjectedTemplate__c, WholeBloodProceduresProjectedOriginal__c, WB_Projected_Procedures__c, Double_Red_Procedures_Projected_Template__c, Anticipated_Registered_Donors_Template__c, APT_Required__c, APT_Quantity__c FROM Opportunity WHERE Id IN:templateOpportunityIds]);
            for (Opportunity newOpportunity : newOpportunityList) {
                if (isInsertOrUpdateWithChangeInTemplate(oldOpportunityMap, newOpportunity)) {
                    //System.debug('isInsertOrUpdateWithChangeInTemplate ->true');
                    Opportunity templateOpportunity = templateOpportunityMap.get(newOpportunity.Parent_Template_Id__c);
                    newOpportunity.Procedure_Projections_Template__c = templateOpportunity.Procedure_Projections_Template__c;
                    newOpportunity.Projected_Registered_Donors_Template__c = templateOpportunity.Projected_Registered_Donors_Template__c;
                    newOpportunity.Staffing_Template__c = templateOpportunity.Staffing_Template__c;
                    newOpportunity.Volunteers_Template__c = templateOpportunity.Volunteers_Template__c;
                    
                    /* added by Satabdi as per HRP-6520 */
                    checkRecursive.skipAptRecalculation = TRUE; //HRP-13190
                    newOpportunity.Drive_Site__c = templateOpportunity.Drive_Site__c;
                    newOpportunity.Site_TBD__c = false;
                    newOpportunity.APT_Required__c = templateOpportunity.APT_Required__c; //HRP-13190
                    newOpportunity.APT_Quantity__c = templateOpportunity.APT_Quantity__c; //HRP-13190
                    newOpportunity.APT_Change_Reason__c = templateChangedText; //HRP-13190
                    
                    newOpportunity.WholeBloodProceduresProjectedTemplate__c = templateOpportunity.WholeBloodProceduresProjectedTemplate__c;
                    newOpportunity.Double_Red_Procedures_Projected_Template__c = templateOpportunity.Double_Red_Procedures_Projected_Template__c;
                    newOpportunity.Anticipated_Registered_Donors_Template__c = templateOpportunity.Anticipated_Registered_Donors_Template__c;
                    
                    if (oldOpportunityMap == null) {
                        newOpportunity.Procedure_Projections_Default__c = templateOpportunity.Procedure_Projections_Template__c;
                        newOpportunity.Projected_Registered_Donors_Default__c = templateOpportunity.Projected_Registered_Donors_Template__c;
                        newOpportunity.Staffing_Default__c = templateOpportunity.Staffing_Template__c;
                        newOpportunity.Volunteers_Default__c = templateOpportunity.Volunteers_Template__c;
                        
                        newOpportunity.Procedure_Projections_Adjusted__c = templateOpportunity.Procedure_Projections_Template__c;
                        newOpportunity.Projected_Registered_Donors_Adjusted__c = templateOpportunity.Projected_Registered_Donors_Template__c;
                        newOpportunity.Staffing_Adjusted__c = templateOpportunity.Staffing_Template__c;
                        newOpportunity.Volunteers_Adjusted__c = templateOpportunity.Volunteers_Template__c;
                        //These three fields come from plan a drive for new inserts
                        newOpportunity.WholeBloodProceduresProjectedOriginal__c = newOpportunity.WB_Projected_Procedures__c;
                        //newOpportunity.WB_Projected_Procedures__c = templateOpportunity.WholeBloodProceduresProjectedTemplate__c;
                        
                        newOpportunity.Double_Red_Procedures_Projected_Original__c = newOpportunity.X2RBC_Projected_Procedures__c;
                        //newOpportunity.X2RBC_Projected_Procedures__c = templateOpportunity.Double_Red_Procedures_Projected_Template__c;
                        
                        newOpportunity.Anticipated_Registered_Donors_Original__c = newOpportunity.Anticipated_Registered_Donors__c;
                        //newOpportunity.Anticipated_Registered_Donors__c = templateOpportunity.Anticipated_Registered_Donors_Template__c;
                        
                        /* Added by FWO per (HRP-6162) */
                        newOpportunity.WholeBloodProceduresProjectedTemplate__c = templateOpportunity.WB_Projected_Procedures__c;
                        newOpportunity.Double_Red_Procedures_Projected_Template__c = templateOpportunity.X2RBC_Projected_Procedures__c;
                        newOpportunity.Anticipated_Registered_Donors_Template__c = templateOpportunity.Anticipated_Registered_Donors__c;
                        newOpportunity.Direct_Donors_To__c = templateOpportunity.Direct_Donors_To__c;
                        
                    } else if (oldOpportunityMap?.get(newOpportunity.Id).Parent_Template_Id__c != newOpportunity.Parent_Template_Id__c) {
                        newOpportunity.WholeBloodProceduresProjectedTemplate__c = templateOpportunity.WB_Projected_Procedures__c;
                        newOpportunity.Double_Red_Procedures_Projected_Template__c = templateOpportunity.X2RBC_Projected_Procedures__c;
                        newOpportunity.Anticipated_Registered_Donors_Template__c = templateOpportunity.Anticipated_Registered_Donors__c;
                        newOpportunity.WholeBloodProcedureProjectedChangeReason__c = templateChangedText;
                        newOpportunity.DoubleRedProceduresProjectedChangeReason__c = templateChangedText;
                        newOpportunity.AnticipatedRegisterDonorChangeReason__c = templateChangedText;
                        newOpportunity.Direct_Donors_To__c = templateOpportunity.Direct_Donors_To__c;
                    }
                }
            }
        }
        
        /* Added by FWO per (HRP-6162) */
        if(lstOppsWithTBDSite != null && lstOppsWithTBDSite.size() > 0) {
            for(Opportunity opp : lstOppsWithTBDSite) {
                opp.WholeBloodProceduresProjectedOriginal__c = opp.WB_Projected_Procedures__c;
                opp.Double_Red_Procedures_Projected_Original__c = opp.X2RBC_Projected_Procedures__c;
                opp.Anticipated_Registered_Donors_Original__c = opp.Anticipated_Registered_Donors__c;
            }
        }
    }
    //HRP-10416 Start ->>
    public static void updateOppProjUnitFields(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList)
    {        
        for(opportunity opp: newOpportunityList)
        {
            /* For Before Update */
            if(oldOpportunityMap != NULL){
                if(oldOpportunityMap.get(opp.id).WB_Projected_Procedures__c != opp.WB_Projected_Procedures__c && opp.WB_Projected_Procedures__c != NULL 
                   ||(oldOpportunityMap.get(opp.id).X2RBC_Projected_Procedures__c != opp.X2RBC_Projected_Procedures__c && opp.X2RBC_Projected_Procedures__c != NULL)
                   ||(oldOpportunityMap.get(opp.id).Platelet_Projected_Procedures__c != opp.Platelet_Projected_Procedures__c && opp.Platelet_Projected_Procedures__c != NULL)
                   ||(oldOpportunityMap.get(opp.id).Plasma_Pheresis_Projected_Procedures__c != opp.Plasma_Pheresis_Projected_Procedures__c && opp.Plasma_Pheresis_Projected_Procedures__c != NULL)){
                       opp.WholeBloodProjectedUnits__c = opp.WB_Projected_Procedures__c;
                       
                       opp.Double_Red_Projected_Units__c = opp.X2RBC_Projected_Procedures__c * 2;
                       
                       opp.Apheresis_Projected_Units__c = opp.Platelet_Projected_Procedures__c;
                       
                       opp.Other_Projected_Units__c = opp.Plasma_Pheresis_Projected_Procedures__c;
                       
                   }   
            }
            /*For Before Insert */
            else if(oldOpportunityMap == NULL)
            {
                opp.WholeBloodProjectedUnits__c = opp.WB_Projected_Procedures__c;
                if(opp.X2RBC_Projected_Procedures__c != NULL)
                {
                    opp.Double_Red_Projected_Units__c = opp.X2RBC_Projected_Procedures__c * 2;
                    
                }
                opp.Apheresis_Projected_Units__c = opp.Platelet_Projected_Procedures__c;
                opp.Other_Projected_Units__c = opp.Plasma_Pheresis_Projected_Procedures__c;
                
            }
            
        }
        
        
    }
    // HRP-10416 <<-End
    public static Boolean isInsertOrUpdateWithChangeInTemplate(Map<Id, Opportunity> oldOpportunityMap, Opportunity newOpportunity) {
        //Defect fix-> this was returning true for new opp insert, instead this should have returned false
        //if(oldOpportunityMap == null && newOpportunity.Is_Template__c == false){
        //return false;
        //}
        
        Opportunity oldOpportunity = oldOpportunityMap?.get(newOpportunity.Id);
        return ((oldOpportunity == null || (oldOpportunity?.Parent_Template_Id__c != newOpportunity.Parent_Template_Id__c)) && !newOpportunity.Is_Template__c && newOpportunity.Parent_Template_Id__c != null);
    }
    
    public static void updateProjectionHistory(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList) {
        String loggedInUserName = UserInfo.getName();
        
        for (Opportunity newOpportunity : newOpportunityList) {
            Opportunity oldOpportunity = oldOpportunityMap.get(newOpportunity.Id);
            String historyToAppend = '';
            if (newOpportunity.Anticipated_Registered_Donors__c != oldOpportunity.Anticipated_Registered_Donors__c) {
                historyToAppend = formHistory('Anticipated Registered Donors got changed from ', oldOpportunity.Anticipated_Registered_Donors__c, newOpportunity.Anticipated_Registered_Donors__c, loggedInUserName, newOpportunity.AnticipatedRegisterDonorChangeReason__c);
            }
            if (newOpportunity.X2RBC_Projected_Procedures__c != oldOpportunity.X2RBC_Projected_Procedures__c || newOpportunity.WB_Projected_Procedures__c != oldOpportunity.WB_Projected_Procedures__c) {
                if (newOpportunity.X2RBC_Projected_Procedures__c != oldOpportunity.X2RBC_Projected_Procedures__c) {
                    String doubleRedHistory = formHistory('Double Red Procedures Projected got changed from ', oldOpportunity.X2RBC_Projected_Procedures__c, newOpportunity.X2RBC_Projected_Procedures__c, loggedInUserName, newOpportunity.DoubleRedProceduresProjectedChangeReason__c);
                    historyToAppend = (String.isEmpty(historyToAppend) ? doubleRedHistory : historyToAppend + '\n' + doubleRedHistory);
                }
                if (newOpportunity.WB_Projected_Procedures__c != oldOpportunity.WB_Projected_Procedures__c) {
                    String wholeHistory = formHistory('Whole Blood Procedures Projected got changed from ', oldOpportunity.WB_Projected_Procedures__c, newOpportunity.WB_Projected_Procedures__c, loggedInUserName, newOpportunity.WholeBloodProcedureProjectedChangeReason__c);
                    historyToAppend = (String.isEmpty(historyToAppend) ? wholeHistory : historyToAppend + '\n' + wholeHistory);
                }
                String totalProceduresProjectedHistory = formHistory('Total Procedures Projected got changed from ', isNumberNull(oldOpportunity.X2RBC_Projected_Procedures__c) + isNumberNull(oldOpportunity.WB_Projected_Procedures__c), isNumberNull(newOpportunity.X2RBC_Projected_Procedures__c) + isNumberNull(newOpportunity.WB_Projected_Procedures__c), loggedInUserName, newOpportunity.WholeBloodProcedureProjectedChangeReason__c);
                historyToAppend = (String.isEmpty(historyToAppend) ? totalProceduresProjectedHistory : historyToAppend + '\n' + totalProceduresProjectedHistory);
                
                
                String totalProductsProjectedHistory = formHistory('Total Products Projected got changed from ', (isNumberNull(oldOpportunity.X2RBC_Projected_Procedures__c) * 2) + isNumberNull(oldOpportunity.WB_Projected_Procedures__c), (isNumberNull(newOpportunity.X2RBC_Projected_Procedures__c) * 2) + isNumberNull(newOpportunity.WB_Projected_Procedures__c), loggedInUserName, newOpportunity.WholeBloodProcedureProjectedChangeReason__c);
                historyToAppend = historyToAppend + '\n' + totalProductsProjectedHistory;
            }
            if (String.isNotEmpty(historyToAppend)) {
                newOpportunity.Projection_History__c = (DateTime.now().format('MM/dd/yyyy hh:mm a z') + ':\n') + (String.isNotEmpty(newOpportunity.Projection_History__c) ? historyToAppend + '\n\n' + newOpportunity.Projection_History__c : historyToAppend);
            }
        }
    }
    public static String formHistory(String startingText, Decimal oldValue, Decimal newValue, String userName, String changeReason) {
        return startingText + oldValue + ' -> ' + newValue + ' by ' + userName + ' ' + DateTime.now().format('MM/dd/yyyy hh:mm a') + (String.isEmpty(changeReason) ? '' : (' (reason: ' + changeReason + ')'));
    }
    public static Decimal isNumberNull(Decimal value) {
        return (value == null ? 0 : value);
    }
    
    public static void checkOriginalValueChange(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList) {
        String originalValueChangeError = 'Original values cannot be changed';
        for (Opportunity newOpportunity : newOpportunityList) {
            Opportunity oldOpportunity = oldOpportunityMap.get(newOpportunity.Id);
            system.debug('check newOpp : '+newOpportunity);
            system.debug('check oldOpp : '+oldOpportunity);
            if (newOpportunity.Anticipated_Registered_Donors_Original__c != oldOpportunity.Anticipated_Registered_Donors_Original__c || newOpportunity.Double_Red_Procedures_Projected_Original__c != oldOpportunity.Double_Red_Procedures_Projected_Original__c || newOpportunity.WholeBloodProceduresProjectedOriginal__c != oldOpportunity.WholeBloodProceduresProjectedOriginal__c) {
                newOpportunity.addError(originalValueChangeError);
            }
        }
        
    }
    public static void duplicateSiteCheck(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList) {
        
        Map<String,String> driveSiteMap = new Map<String,String>();
        Set<String> siteSet = new Set<String>();
        Set<String> accSet = new Set<String>();
        for (Opportunity newOpportunity : newOpportunityList) {
            Opportunity oldOpportunity = oldOpportunityMap.get(newOpportunity.Id);
            system.debug('check newOpp : '+newOpportunity);
            system.debug('check oldOpp : '+oldOpportunity);
            
            if(newOpportunity.Drive_Site__c != oldOpportunity.Drive_Site__c && newOpportunity.Is_Template__c){
                
                siteSet.add(newOpportunity.Drive_Site__c);
                accSet.add(newOpportunity.AccountID);
            }
        }
        
        for(Opportunity opp : [select id,AccountID,Drive_Site__c from Opportunity where Drive_Site__c IN : siteSet and AccountID IN :accSet]){
            driveSiteMap.put(opp.Drive_Site__c+'~'+opp.AccountID,opp.Drive_Site__c+'~'+opp.AccountID);
        }
        System.debug('driveSiteMap====='+driveSiteMap) ;
        
        for(Opportunity newOpportunity : newOpportunityList){
            Opportunity oldOpportunity = oldOpportunityMap.get(newOpportunity.Id);
            System.debug('drive====='+driveSiteMap.containsKey(newOpportunity.Drive_Site__c+'~'+newOpportunity.AccountID) ) ;
            if(newOpportunity.Is_Template__c && oldOpportunity.Drive_Site__c != null && newOpportunity.Drive_Site__c != null && newOpportunity.Drive_Site__c != oldOpportunity.Drive_Site__c){
                
                if(driveSiteMap.containsKey(newOpportunity.Drive_Site__c+'~'+newOpportunity.AccountID)){
                    newOpportunity.Drive_Site__c.addError('This Site + Account combination already exists.');
                }
                else{
                    
                    newOpportunity.Drive_Site__c.addError(' This Site + Account does not exists. Please choose the current template or create a new template from the Account.');
                }
            }
        }
    }
    
    public static void cancelTasksForCancelledOpportunities(Map<Id,Opportunity> oldMap,Map<Id,Opportunity> newMap){ 
        System.debug('Entered method cancelTasksForCancelledOpportunities');    
        Set<Id> newOppMapKeys = newMap.keyset();    
        Map<Id,Opportunity> cancelledOppsMap = new Map<Id,Opportunity>();   
        for(Id oppId:newOppMapKeys) {   
            Opportunity newOpp = newMap.get(oppId); 
            System.debug('New Opportunity->'+newOpp);   
            if(newOpp.Is_Template__c == true){ //if its template, don't bother further checks  
                continue;   
            }   
            if(newOpp.StageName != 'Cancelled')//stagename is not Cancelled, don't bother any futher    
                continue;   
            System.debug('Old Opportunity->'+oldMap.get(oppId));    
            if(oldMap != null && oldMap.get(oppId).StageName == 'Cancelled'){//If moving from Cancelled  to Cancelled ,meaning other fields got updated, no need to validate again  
                continue;   
            }   
            System.debug('FWO Adding this opp to cancelled opps');                  
            //If moving from other stages to Closed, validate BPL exists    
            cancelledOppsMap.put(newOpp.Id,newOpp); 
        }   
        if(cancelledOppsMap.size()<1)   
            return; 
        cancelTasks(cancelledOppsMap);  
    }   
    
    public static void cancelTasks( Map<Id,Opportunity> cancelledOppsMap){  
        List<Task> taskList = [select id, status, whatId from task where whatId in :cancelledOppsMap.keyset()]; 
        System.debug('total tasks associated with incoming opportunities->'+taskList);  
        if(taskList == null || taskList.size()<1)   
            return; 
        for(Task tsk:taskList){ 
            tsk.status = 'Cancelled';           
        } 
        /*Schema.DescribeSObjectResult ds = Task.sObjectType.getDescribe();
if(ds.isUpdateable()){}*/
        update taskList; 
        
        
    }
    /*HRP-5002 :Global Web Scheduling ,HRP-4987=SF TimeZone Objects
* Deactivated below flow:Update Blood Drive Opportunity Collection Zip Code and moved flow logic into this method.
*/
    public static void updateWebSchedulingStart_EndDates(List<Opportunity> listOfnewOppties,Map<Id, Opportunity> mapOfOfOldOppties) {
        
        Id mobileRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId();
        Id fixedSiteRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId();  
        Set<String> setOfSitesZipCodes=new Set<String>();
        List<Opportunity> listOfFixedSiteOppties=new List<Opportunity>();
        List<Opportunity> listOfMobileOppties=new List<Opportunity>();
        Set<Id> setOfMobileTemplateOppties=new Set<Id> ();
        List<Opportunity> listOfMobileTemplateOppties=new List<Opportunity> ();
        // GlobalWebSchedulingSettings__mdt globalWebScMetaData= fetchGlobalWebScheduleMetaDate();
        Boolean WebScheduleDatesUpdated;
        Boolean isMigration = Boolean.valueOf(Label.IsMigrationEnable);
        for(Opportunity oppRecord : listOfnewOppties){
            
            //Migration defaults online scheduling to yes
            if(oppRecord.Online_Scheduling_Enabled__c !='Yes' && oppRecord.Online_Scheduling_Enabled__c !='No' && isMigration)
            {
                oppRecord.Online_Scheduling_Enabled__c='Yes';
            }
            //For new template creation Web_Sched_Offset_from_CO_Global_Settings__c will be default checked 
            //and forcefully making Web_Scheduling_Start_Time__c field null as we are unable to figure out where its getting populated
            if(oppRecord.RecordTypeId == mobileRecTypeId && mapOfOfOldOppties == null && oppRecord.Is_Template__c == true){
                //HRP-4878 & HRP-12631 --> Start
                oppRecord.Web_Sched_Offset_from_CO_Global_Settings__c = true;
                //oppRecord.Web_Scheduling_Start_Time__c = null;
                // oppRecord.Web_Scheduling_End_Date_Offset__c=globalWebScMetaData.Web_Scheduling_End_Date_Offset__c;
                // oppRecord.Web_Scheduling_End_Time_Offset__c=globalWebScMetaData.Web_Scheduling_End_Time_Offset__c;
                // oppRecord.Web_Scheduling_Start_Date_Offset__c=globalWebScMetaData.Web_Scheduling_Start_Date_Offset__c;
                // oppRecord.Web_Scheduling_Start_Time__c=globalWebScMetaData.Web_Scheduling_Start_Time__c;
                //HRP-4878 & HRP-12631 --> End
            }
            
            //Webschedule calculation only i) if migration is false or ii) if migration true and webschedules are blank
            if(!isMigration || test.isRunningTest() || (mapOfOfOldOppties == null && oppRecord.Web_Schedule_StartDate__c==null && oppRecord.Web_Schedule_EndDate__c==null && oppRecord.Web_Schedule_End_Time__c==null))
            {
                WebScheduleDatesUpdated = false;
                if((mapOfOfOldOppties == null && oppRecord.Drive_Site__c!=null) ||
                   (mapOfOfOldOppties!=null && mapOfOfOldOppties.get(oppRecord.id).Drive_Site__c!= oppRecord.Drive_Site__c && oppRecord.Drive_Site__c!=null)||
                   (mapOfOfOldOppties!=null && mapOfOfOldOppties.get(oppRecord.id).Drive_Date__c!= oppRecord.Drive_Date__c))
                {
                    setOfSitesZipCodes.add(oppRecord.Site_Zip_Code__c);      
                }
                
                if(mapOfOfOldOppties!=null &&  (mapOfOfOldOppties.get(oppRecord.id).Web_Schedule_EndDate__c != oppRecord.Web_Schedule_EndDate__c
                                                || mapOfOfOldOppties.get(oppRecord.id).Web_Schedule_StartDate__c != oppRecord.Web_Schedule_StartDate__c))
                {
                    system.debug('Webschedule dates changed');
                    WebScheduleDatesUpdated = true;
                }
                // if(mapOfOfOldOppties!=null && (mapOfOfOldOppties.get(oppRecord.id).Site_TBD__c != oppRecord.Site_TBD__c && oppRecord.Site_TBD__c)) {
                //     system.debug('Webschedule dates changed');
                //     WebScheduleDatesUpdated = true;
                // }
                if(oppRecord.RecordTypeId == fixedSiteRecTypeId &&oppRecord.Drive_Date__c!=null &&
                   ((mapOfOfOldOppties == null && oppRecord.Online_Scheduling_Enabled__c =='Yes')||
                    (mapOfOfOldOppties !=null  && oppRecord.Online_Scheduling_Enabled__c =='Yes' && 
                     (mapOfOfOldOppties.get(oppRecord.id).Online_Scheduling_Enabled__c != oppRecord.Online_Scheduling_Enabled__c
                      || mapOfOfOldOppties.get(oppRecord.id).Drive_Date__c != oppRecord.Drive_Date__c || mapOfOfOldOppties.get(oppRecord.id).End_Time__c != oppRecord.End_Time__c)&& !WebScheduleDatesUpdated)
                   )
                  ){
                      listOfFixedSiteOppties.add(oppRecord);  
                  }
                
                

                if(oppRecord.RecordTypeId == mobileRecTypeId &&
                   ((mapOfOfOldOppties == null && oppRecord.Online_Scheduling_Enabled__c =='Yes')||
                    (mapOfOfOldOppties !=null && oppRecord.Online_Scheduling_Enabled__c =='Yes' && 
                     (mapOfOfOldOppties.get(oppRecord.id).Online_Scheduling_Enabled__c != oppRecord.Online_Scheduling_Enabled__c
                      || mapOfOfOldOppties.get(oppRecord.id).Drive_Date__c != oppRecord.Drive_Date__c || mapOfOfOldOppties.get(oppRecord.id).End_Time__c != oppRecord.End_Time__c) && !WebScheduleDatesUpdated
                    ) || (mapOfOfOldOppties!=null && (mapOfOfOldOppties.get(oppRecord.id).Site_TBD__c != oppRecord.Site_TBD__c && !oppRecord.Site_TBD__c))) 
                  )
                {          
                    //System.debug('oppRecord.Site_TBD__c==> '+oppRecord.Site_TBD__c);
                    if(oppRecord.Is_Template__c == false){
                        
                        if(oppRecord.Parent_Template_Id__c!=null && oppRecord.Drive_Date__c!=null){
                            setOfMobileTemplateOppties.add(oppRecord.Parent_Template_Id__c);
                            listOfMobileTemplateOppties.add(oppRecord);
                        } else if(oppRecord.Parent_Template_Id__c ==null && oppRecord.Drive_Date__c!=null){
                            listOfMobileOppties.add(oppRecord);
                        } 
                    }  
                }
            }
        }
        
        //updating Collection Zip Code Based on DriveSite
        if(!setOfSitesZipCodes.isEmpty()){
            system.debug('entered4##');
            updateCollectionZipCode(listOfnewOppties,setOfSitesZipCodes);           
        }
        
        //Fixed Site Oppty WebSchedule StartDate,EndDate Calc        
        if(!listOfFixedSiteOppties.isEmpty()){    
            webScheduleStart_EndDateUpdateCalculation(listOfFixedSiteOppties,mapOfOfOldOppties);
        }
        //   Mobile Oppty with No Templates WebSchedule StartDate,EndDate Calc 
        if(!listOfMobileOppties.isEmpty()){    
            webScheduleStart_EndDateUpdateCalculation(listOfMobileOppties,mapOfOfOldOppties);
        }
        
        //Mobile Site Oppty WebSchedule StartDate,EndDate Calc
        if(!setOfMobileTemplateOppties.isEmpty()){          
            Map<Id,Opportunity> mapOfOppties=new Map<Id,Opportunity>([select Id,Web_Scheduling_End_Date_Offset__c,Web_Scheduling_End_Time_Offset__c,Web_Scheduling_Start_Date_Offset__c,Web_Scheduling_Start_Time__c,
                                                                      Web_Sched_Offset_from_CO_Global_Settings__c 
                                                                      from Opportunity where ID IN:setOfMobileTemplateOppties AND 
                                                                      Web_Sched_Offset_from_CO_Global_Settings__c = false AND 
                                                                      Web_Scheduling_End_Date_Offset__c!=null AND 
                                                                      Web_Scheduling_End_Time_Offset__c!=null AND 
                                                                      Web_Scheduling_Start_Date_Offset__c!=null AND
                                                                      Web_Scheduling_Start_Time__c!=null]); //HRP-4878 & HRP-12631 --> modification in the query
            
            if(mapOfOppties.isEmpty()){
                webScheduleStart_EndDateUpdateCalculation(listOfMobileTemplateOppties,mapOfOfOldOppties);
                
            } else {
                
                for(Opportunity oppRecord1 : listOfnewOppties){
                    if((isMigration && mapOfOfOldOppties == null && oppRecord1.Web_Schedule_StartDate__c==null && oppRecord1.Web_Schedule_EndDate__c==null && oppRecord1.Web_Schedule_End_Time__c==null)
                       || (!isMigration) || test.isRunningTest())
                    {
                        if(listOfMobileTemplateOppties.contains(oppRecord1))
                        {
                            if(mapOfOppties.containsKey(oppRecord1.Parent_Template_Id__c)){
                                Opportunity  currentOpptyRecord =mapOfOppties.get(oppRecord1.Parent_Template_Id__c);
                                Date driveDate=oppRecord1.Drive_Date__c;       
                                //WebSchedule StartDate Calc
                                Date driveDateAddStartDateOffSet=driveDate.addDays(Integer.valueOf(currentOpptyRecord.Web_Scheduling_Start_Date_Offset__c));
                                DateTime driveDateAddStartDateOffSetTime=driveDateAddStartDateOffSet;
                                String webStartTime=String.valueOf(currentOpptyRecord.Web_Scheduling_Start_Time__c);    
                                DateTime webSchStartDate=driveDateAddStartDateOffSetTime.addHours(Integer.valueOf(webStartTime.left(2))).addMinutes(Integer.valueOf(webStartTime.right(2)));
                                //System.debug('webSchStartDate==='+webSchStartDate);
                                
                                oppRecord1.Web_Schedule_StartDate__c=driveDateAddStartDateOffSet;
                                Time startTimeInstance= Time.newInstance(Integer.valueOf(webStartTime.left(2)),Integer.valueOf(webStartTime.right(2)),0,0);  
                                oppRecord1.Web_Schedule_Start_Time__c=startTimeInstance;
                                if(oppRecord1.TimeZone__c!=null){
                                    oppRecord1.Web_Schedule_Start_Date__c= DateTimeConverter.convertDateTimeIntoGMT(oppRecord1.TimeZone__c,driveDateAddStartDateOffSet,startTimeInstance);
                                } else {
                                    oppRecord1.Web_Schedule_Start_Date__c=webSchStartDate;
                                }
                                
                                //WebSchedule EndDate Calc 
                                Date driveDateEnd=oppRecord1.Drive_Date__c;           
                                Date driveDateAddEndDateOffSet=driveDateEnd.addDays(Integer.valueOf(currentOpptyRecord.Web_Scheduling_End_Date_Offset__c));
                                DateTime driveDateAddEndDateOffSetTime=driveDateAddEndDateOffSet;
                                Time endTime;
                                if(mapOfOfOldOppties == null && oppRecord1.Flow_End_Time_Field__c!=null){
                                    String endTimeString= oppRecord1.Flow_End_Time_Field__c;
                                    endTime = Time.newInstance( Integer.valueOf(endTimeString.left(2)),Integer.valueOf(endTimeString.right(2)),0,0);
                                } else if(mapOfOfOldOppties != null){
                                    endTime = oppRecord1.End_Time__c;   
                                }    
                                Time calculatedEndTime= endTime.addHours(Integer.valueOf(currentOpptyRecord.Web_Scheduling_End_Time_Offset__c));
                                DateTime webSchEndDate=driveDateAddEndDateOffSetTime.addHours(calculatedEndTime.hour()).addMinutes(calculatedEndTime.minute());
                                //System.debug('webSchEndDate==='+webSchEndDate);
                                
                                oppRecord1.Web_Schedule_EndDate__c=driveDateAddEndDateOffSet;
                                oppRecord1.Web_Schedule_End_Time__c=calculatedEndTime;
                                if(oppRecord1.TimeZone__c!=null){
                                    oppRecord1.Web_Schedule_End_Date__c= DateTimeConverter.convertDateTimeIntoGMT(oppRecord1.TimeZone__c,driveDateAddEndDateOffSet,calculatedEndTime);
                                } else {
                                    oppRecord1.Web_Schedule_End_Date__c=webSchEndDate; 
                                } 
                            } 
                        }
                    }
                }
                
            }
        }  
    }
    
    public static void webScheduleStart_EndDateUpdateCalculation(List<Opportunity> listOfOppties,Map<Id,Opportunity> mapOfOfOldOppties){      
        //HRP-4878 & HRP-12631 --> Starts
        Set<Id> opportunitySiteIds = new Set<Id>();
        Set<Id> opportunityDriveIds = new Set<Id>();
        for (Opportunity opp : listOfOppties) {
            if(!opp.Site_TBD__c)
                opportunitySiteIds.add(opp.Drive_Site__c);
        }

        Map<Id, sked__Location__c> siteVsSiteCoMap = new Map<Id, sked__Location__c>([SELECT Id, Name, sked_Collection_Operation__r.Name, sked_Site_Collection_Operation_Count__c, (Select Id, Name, sked_Start_Date__c, sked_End_Date__c, sked_Collection_Operation__c, sked_Collection_Operation__r.Name, 
                                                                sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Time__c, sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Date_Offset__c, sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Time_Offset__c, 
                                                                sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Date_Offset__c,sked_Collection_Operation__r.FS_Web_Scheduling_Start_Time__c, sked_Collection_Operation__r.FS_Web_Scheduling_Start_Date_Offset__c, 
                                                                sked_Collection_Operation__r.FS_Web_Scheduling_End_Time_Offset__c, sked_Collection_Operation__r.FS_Web_Scheduling_End_Date_Offset__c FROM sked_Site_Collection_Operations__r WHERE sked_Start_Date__c<= TODAY AND sked_End_Date__c>= TODAY ) FROM sked__Location__c WHERE Id IN :opportunitySiteIds]);
        
        
        Map<Id, sked_Site_Collection_Operation__c> oppIdVsCoMap = new Map<Id, sked_Site_Collection_Operation__c>();                              
        for (Opportunity opp : listOfOppties) {
            if(!opp.Site_TBD__c)
                for (sked_Site_Collection_Operation__c siteCo : siteVsSiteCoMap.get(opp.Drive_Site__c).sked_Site_Collection_Operations__r) {
                    if (opp.drive_Date__c>=siteCo.sked_Start_Date__c && opp.drive_Date__c<=siteCo.sked_End_Date__c) {
                        oppIdVsCoMap.put(opp.Id, siteCo);
                        break;
                    }
                }
        }
        //HRP-4878 & HRP-12631 --> Ends
        system.debug('Entered webScheduleStart_EndDateUpdateCalculation');
        for(Opportunity opRecord:listOfOppties){      
            Map<String, Object> webSchedulingData =  webSchedulingData(opRecord,oppIdVsCoMap);
            Date driveDate=opRecord.Drive_Date__c;       
            //WebSchedule StartDate Calc
            // Date driveDateAddStartDateOffSet=driveDate.addDays(Integer.valueOf(globalWebScMetaData.Web_Scheduling_Start_Date_Offset__c));
            Date driveDateAddStartDateOffSet=driveDate.addDays(Integer.valueOf((Decimal)webSchedulingData.get('WebSchedulingStartDateOffset')));
            DateTime driveDateAddStartDateOffSetTime=driveDateAddStartDateOffSet;
            // String webStartTime=String.valueOf(globalWebScMetaData.Web_Scheduling_Start_Time__c);    
            String webStartTime=(String)webSchedulingData.get('WebSchedulingStartTime'); 
            DateTime webSchStartDate=driveDateAddStartDateOffSetTime.addHours(Integer.valueOf(webStartTime.left(2))).addMinutes(Integer.valueOf(webStartTime.right(2)));
            System.debug('webSchStartDate==='+webSchStartDate);           
            opRecord.Web_Schedule_StartDate__c=driveDateAddStartDateOffSet;
            Time startTimeInstance= Time.newInstance(Integer.valueOf(webStartTime.left(2)),Integer.valueOf(webStartTime.right(2)),0,0);  
            opRecord.Web_Schedule_Start_Time__c=startTimeInstance;
            if(opRecord.TimeZone__c!=null){
                opRecord.Web_Schedule_Start_Date__c= DateTimeConverter.convertDateTimeIntoGMT(opRecord.TimeZone__c,driveDateAddStartDateOffSet,startTimeInstance);
            } else {
                opRecord.Web_Schedule_Start_Date__c=webSchStartDate;
            }
            
            //WebSchedule EndDate Calc 
            Date driveDateEnd=opRecord.Drive_Date__c;           
            // Date driveDateAddEndDateOffSet=driveDateEnd.addDays(Integer.valueOf(globalWebScMetaData.Web_Scheduling_End_Date_Offset__c));           
            Date driveDateAddEndDateOffSet=driveDateEnd.addDays(Integer.valueOf((Decimal)webSchedulingData.get('WebSchedulingEndDateOffset'))); 
            Time endTime;
            System.debug('opRecord.Flow_End_Time_Field__c'+opRecord.Flow_End_Time_Field__c);
            System.debug('mapOfOfOldOppties'+mapOfOfOldOppties);
            if(mapOfOfOldOppties == null && (opRecord.Flow_End_Time_Field__c!=null || opRecord.End_Time__c !=null)){
                if(opRecord.End_Time__c != null){
                    endTime = opRecord.End_Time__c;
                    System.debug('EndTime1:'+endTime);
                }  
                else{
                    String endTimeString= opRecord.Flow_End_Time_Field__c;
                    System.debug('Flow_End_Time_Field__c:'+opRecord.Flow_End_Time_Field__c);
                    endTime = Time.newInstance( Integer.valueOf(endTimeString.left(2)),Integer.valueOf(endTimeString.right(2)),0,0);  
                    System.debug('EndTime2:'+endTime);
                }              
            } else if(mapOfOfOldOppties != null){
                endTime = opRecord.End_Time__c;   
                System.debug('EndTime3:'+endTime);
            }         
            System.debug('endTime====>'+endTime);         
            // Time calculatedEndTime= endTime.addHours(Integer.valueOf(globalWebScMetaData.Web_Scheduling_End_Time_Offset__c));           
            Time calculatedEndTime= endTime.addHours(Integer.valueOf((Decimal)webSchedulingData.get('WebSchedulingEndTimeOffset'))); 
            DateTime driveDateAddEndDateOffSetTime=driveDateAddEndDateOffSet;
            DateTime webSchEndDate=driveDateAddEndDateOffSetTime.addHours(calculatedEndTime.hour()).addMinutes(calculatedEndTime.minute());
            System.debug('webSchEndDate==='+webSchEndDate);
            
            opRecord.Web_Schedule_EndDate__c=driveDateAddEndDateOffSet;            
            opRecord.Web_Schedule_End_Time__c=calculatedEndTime; 
            if(opRecord.TimeZone__c!=null){
                opRecord.Web_Schedule_End_Date__c= DateTimeConverter.convertDateTimeIntoGMT(opRecord.TimeZone__c,driveDateAddEndDateOffSet,calculatedEndTime);
            } else {
                opRecord.Web_Schedule_End_Date__c=webSchEndDate; 
            }
        }
    }
    //HRP-4878 & HRP-12631 -->
   /* HRP-4878: Setting Collection Operation Web Scheduling Values
    * The following method, webSchedulingData, takes an Opportunity record and a map of Opportunity and sked_Site_Collection_Operation__c, and 
    * returns a web scheduling offset map considering the hierarchy of web scheduling data as follows:
    * Global Settings>Colletion Operation>Opportunity Template
    */
    public static Map<String, Object> webSchedulingData(Opportunity opp, Map<Id, sked_Site_Collection_Operation__c> siteCoMap){
        Boolean hasCollectionOperation = siteCoMap.containsKey(opp.Id);
        Boolean isMobileDrive = opp.Type_of_Drive__c.equalsIgnoreCase('Mobile') ? TRUE : FALSE;
        Map<String, Object> webSchedulingData = new Map<String, Object>{'WebSchedulingStartDateOffset'=> NULL, 'WebSchedulingStartTime'=> NULL, 'WebSchedulingEndDateOffset'=> NULL, 'WebSchedulingEndTimeOffset'=> NULL};
        GlobalWebSchedulingSettings__mdt globalWebScMetaData = fetchGlobalWebScheduleMetaData().get(opp.Type_of_Drive__c);
        if(hasCollectionOperation){
            webSchedulingData.put('WebSchedulingStartDateOffset', isMobileDrive ? (siteCoMap.get(opp.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Date_Offset__c) : siteCoMap.get(opp.Id).sked_Collection_Operation__r.FS_Web_Scheduling_Start_Date_Offset__c);
            webSchedulingData.put('WebSchedulingStartTime', isMobileDrive ? (siteCoMap.get(opp.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Time__c) : siteCoMap.get(opp.Id).sked_Collection_Operation__r.FS_Web_Scheduling_Start_Time__c);
            webSchedulingData.put('WebSchedulingEndDateOffset', isMobileDrive ? (siteCoMap.get(opp.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Date_Offset__c) : siteCoMap.get(opp.Id).sked_Collection_Operation__r.FS_Web_Scheduling_End_Date_Offset__c);
            webSchedulingData.put('WebSchedulingEndTimeOffset', isMobileDrive ? (siteCoMap.get(opp.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Time_Offset__c) : siteCoMap.get(opp.Id).sked_Collection_Operation__r.FS_Web_Scheduling_End_Time_Offset__c);
        }
        //System.debug('webSchedulingData=> '+webSchedulingData);
        webSchedulingData.put('WebSchedulingStartDateOffset', webSchedulingData.get('WebSchedulingStartDateOffset') != Null ? webSchedulingData.get('WebSchedulingStartDateOffset') : globalWebScMetaData.Web_Scheduling_Start_Date_Offset__c);
        webSchedulingData.put('WebSchedulingStartTime', webSchedulingData.get('WebSchedulingStartTime')!= NULL ? webSchedulingData.get('WebSchedulingStartTime') : globalWebScMetaData.Web_Scheduling_Start_Time__c);
        webSchedulingData.put('WebSchedulingEndDateOffset', webSchedulingData.get('WebSchedulingEndDateOffset') !=NULL ? webSchedulingData.get('WebSchedulingEndDateOffset') : globalWebScMetaData.Web_Scheduling_End_Date_Offset__c);
        webSchedulingData.put('WebSchedulingEndTimeOffset', webSchedulingData.get('WebSchedulingEndTimeOffset') !=NULL ? webSchedulingData.get('WebSchedulingEndTimeOffset') : globalWebScMetaData.Web_Scheduling_End_Date_Offset__c);
        //System.debug('webSchedulingData=> '+webSchedulingData);
        return webSchedulingData;
    }

    public static Map<String,GlobalWebSchedulingSettings__mdt> fetchGlobalWebScheduleMetaData(){ 
        Map<String,GlobalWebSchedulingSettings__mdt> webSchedulingSettingsMap = new Map<String,GlobalWebSchedulingSettings__mdt>();
        List<GlobalWebSchedulingSettings__mdt> webSchedulingSettings = GlobalWebSchedulingSettings__mdt.getAll().values();  
        for (GlobalWebSchedulingSettings__mdt mdt : webSchedulingSettings) {
            webSchedulingSettingsMap.put((mdt.DeveloperName).equalsIgnoreCase('MobileDriveSettings')? 'Mobile' : 'Fixed Site', mdt);
        }
        return webSchedulingSettingsMap;    
    }
    //HRP-4878 & HRP-12631 -->
    public static GlobalWebSchedulingSettings__mdt fetchGlobalWebScheduleMetaDate(){   
        return [SELECT Id, Web_Scheduling_End_Date_Offset__c, Web_Scheduling_End_Time_Offset__c,
                Web_Scheduling_Start_Date_Offset__c,Web_Scheduling_Start_Time__c
                FROM GlobalWebSchedulingSettings__mdt limit 1];    
    }
    
    //HRP-4987=SF TimeZone Objects  
    public static void updateWebSchedulingStart_EndDates_WithoutGlobalSchedules(List<Opportunity> listOfnewOppties, Map<Id, Opportunity> mapOfOfOldOppties){
        Set<String> setOfSitesZipCodes=new Set<String>();
        Boolean isMigration = Boolean.valueOf(Label.IsMigrationEnable);
        for(Opportunity oppRecord :listOfnewOppties){
            
            if(isMigration || test.isRunningTest())
            {
                if((mapOfOfOldOppties == null && oppRecord.Drive_Site__c!=null) ||
                   (mapOfOfOldOppties!=null && mapOfOfOldOppties.get(oppRecord.id).Drive_Site__c!= oppRecord.Drive_Site__c && oppRecord.Drive_Site__c!=null)
                  ){
                      setOfSitesZipCodes.add(oppRecord.Site_Zip_Code__c);      
                  }
                
                if(mapOfOfOldOppties == null && oppRecord.Online_Scheduling_Enabled__c =='Yes' && oppRecord.Is_Template__c == false){
                    if(oppRecord.Flow_Start_Time_Field__c ==null && oppRecord.Web_Schedule_StartDate__c!=null && oppRecord.Web_Schedule_Start_Time__c!=null){
                        if(oppRecord.TimeZone__c!=null){    
                            oppRecord.Web_Schedule_Start_Date__c=DateTimeConverter.convertDateTimeIntoGMT(oppRecord.TimeZone__c,oppRecord.Web_Schedule_StartDate__c,oppRecord.Web_Schedule_Start_Time__c);
                        } else {
                            Date dateInfo=oppRecord.Web_Schedule_StartDate__c;
                            Time timeInfo=oppRecord.Web_Schedule_Start_Time__c;
                            oppRecord.Web_Schedule_Start_Date__c= DateTime.newInstance(dateInfo.year(),dateInfo.month(),dateinfo.day(), timeInfo.hour(),timeInfo.minute(),0);
                        }
                        
                    }
                    
                    if(oppRecord.Flow_End_Time_Field__c ==null && oppRecord.Web_Schedule_EndDate__c!=null && oppRecord.Web_Schedule_End_Time__c!=null){
                        if(oppRecord.TimeZone__c!=null){        
                            oppRecord.Web_Schedule_End_Date__c=DateTimeConverter.convertDateTimeIntoGMT(oppRecord.TimeZone__c,oppRecord.Web_Schedule_EndDate__c,oppRecord.Web_Schedule_End_Time__c);
                        } else {
                            Date dateInfo=oppRecord.Web_Schedule_EndDate__c;
                            Time timeInfo=oppRecord.Web_Schedule_End_Time__c;
                            oppRecord.Web_Schedule_End_Date__c= DateTime.newInstance(dateInfo.year(),dateInfo.month(),dateinfo.day(), timeInfo.hour(),timeInfo.minute(),0);
                            
                        }
                    }
                }
            }
            if(!isMigration || test.isRunningTest())
            {
                if(mapOfOfOldOppties != null && oppRecord.Online_Scheduling_Enabled__c =='Yes' && oppRecord.Is_Template__c == false){
                    
                    if((mapOfOfOldOppties.get(oppRecord.id).Web_Schedule_StartDate__c!=oppRecord.Web_Schedule_StartDate__c ||mapOfOfOldOppties.get(oppRecord.id).Web_Schedule_Start_Time__c!= oppRecord.Web_Schedule_Start_Time__c)&&
                       (oppRecord.Web_Schedule_StartDate__c!=null && oppRecord.Web_Schedule_Start_Time__c!=null)
                      ){
                          if(oppRecord.TimeZone__c!=null){    
                              oppRecord.Web_Schedule_Start_Date__c=DateTimeConverter.convertDateTimeIntoGMT(oppRecord.TimeZone__c,oppRecord.Web_Schedule_StartDate__c,oppRecord.Web_Schedule_Start_Time__c);
                          } else {
                              Date dateInfo=oppRecord.Web_Schedule_StartDate__c;
                              Time timeInfo=oppRecord.Web_Schedule_Start_Time__c;
                              oppRecord.Web_Schedule_Start_Date__c= DateTime.newInstance(dateInfo.year(),dateInfo.month(),dateinfo.day(), timeInfo.hour(),timeInfo.minute(),0);
                          }
                          
                      }
                    if((mapOfOfOldOppties.get(oppRecord.id).Web_Schedule_EndDate__c!=oppRecord.Web_Schedule_EndDate__c ||mapOfOfOldOppties.get(oppRecord.id).Web_Schedule_End_Time__c!= oppRecord.Web_Schedule_End_Time__c)&&
                       (oppRecord.Web_Schedule_EndDate__c!=null && oppRecord.Web_Schedule_Start_Time__c!=null)
                      )    {
                          if(oppRecord.TimeZone__c!=null){        
                              oppRecord.Web_Schedule_End_Date__c=DateTimeConverter.convertDateTimeIntoGMT(oppRecord.TimeZone__c,oppRecord.Web_Schedule_EndDate__c,oppRecord.Web_Schedule_End_Time__c);
                          } else {
                              Date dateInfo=oppRecord.Web_Schedule_EndDate__c;
                              Time timeInfo=oppRecord.Web_Schedule_End_Time__c;
                              oppRecord.Web_Schedule_End_Date__c= DateTime.newInstance(dateInfo.year(),dateInfo.month(),dateinfo.day(), timeInfo.hour(),timeInfo.minute(),0);
                              
                          }
                      }
                }
            }
        }
        
        //updating Collection Zip Code Based on DriveSite
        if(!setOfSitesZipCodes.isEmpty()){
            updateCollectionZipCode(listOfnewOppties,setOfSitesZipCodes);                                                                          
        }
    }
    
    public static void updateCollectionZipCode(List<Opportunity> listOfnewOppties ,set<String> setOfSitesZipCodes ){
        
        set<Id> siteIds =new set<Id>();
        for(opportunity op:listOfnewOppties){
            siteIds.add(op.Drive_Site__c);
        }
        Map<Id,List<sked_Site_Collection_Operation__c>> mapOfSiteCollectionOperation = new Map<Id,List<sked_Site_Collection_Operation__c>>();
        List<sked__Location__c> ListOfSites=[select id,(select id,sked_Start_Date__c,sked_End_Date__c,sked_Site__c,sked_Collections_Zip_Code__c from sked_Site_Collection_Operations__r) from sked__Location__c where Id IN:siteIds];
        for(sked__Location__c scollection:ListOfSites){
            mapOfSiteCollectionOperation.put( scollection.id,scollection.sked_Site_Collection_Operations__r);
        }
        
        for(Opportunity op: listOfnewOppties){
            if(mapOfSiteCollectionOperation.containsKey(Op.Drive_Site__c)){
                List<sked_Site_Collection_Operation__c> lsitOf= mapOfSiteCollectionOperation.get(op.Drive_Site__c);//sitezip
                //system.debug('entered6'+lsitOf);
                for(sked_Site_Collection_Operation__c ctr:lsitOf){
                    if(op.Drive_Date__c >= ctr.sked_Start_Date__c && ctr.sked_End_Date__c >= op.Drive_Date__c ){
                        //system.debug('ctr all1 '+ctr);
                        if(op.Collections_Zip_Code__c!=ctr.sked_Collections_Zip_Code__c){
                            //system.debug('ctr all2 '+ctr);
                            op.Collections_Zip_Code__c=ctr.sked_Collections_Zip_Code__c; 
                            //op.Online_Scheduling_Enabled__c='No';
                            break;
                        }
                    }
                }
            }
        }
        /* 
listOfCollectionOperation = [select Id,Zip__c,
sked_Start_Date__c, 
sked_End_Date__c 
from Collections_Territory__c 
where Zip__c IN:setOfSitesZipCodes];
if(!listOfCollectionZipCodes.isEmpty()){
Map<String,List<Collections_Territory__c>> mapOfZipCodes = new Map<String,List<Collections_Territory__c>>();

for(Collections_Territory__c czipCodeRecord : listOfCollectionZipCodes){
if( !mapOfZipCodes.containsKey( czipCodeRecord.Zip__c ) ){
mapOfZipCodes.put( czipCodeRecord.Zip__c, new List<Collections_Territory__c>() ) ;
}
mapOfZipCodes.get( czipCodeRecord.Zip__c ).add( czipCodeRecord ) ;
}

for(Opportunity oppRecord : listOfnewOppties){    
system.debug('entered2##'+listOfnewOppties);
if(mapOfZipCodes.containsKey(oppRecord.Site_Zip_Code__c)){
for(Collections_Territory__c  ctr :  mapOfZipCodes.get(oppRecord.Site_Zip_Code__c)  ){
system.debug('entered3##'+ctr);
if( oppRecord.Drive_Date__c >= ctr.sked_Start_Date__c && ctr.sked_End_Date__c >= oppRecord.Drive_Date__c ){
oppRecord.Collections_Zip_Code__c = ctr.Id ;
break;
}
}                        
}       
}
}            
*/
    }
    /*
public static void updateDrivesOnCalendarWithOpportunityChanges(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList) {

Map<Id, Opportunity> updateOpportunityMap = new Map<Id, Opportunity>();
Set<Id> cancelReasonSet = new Set<Id>();
Set<Id> accManagerSet = new Set<Id>();
Set<Id> ardTemplateSet = new Set<Id>();

for (Opportunity newOpportunity : newOpportunityList) {
Opportunity oldOpportunity = oldOpportunityMap?.get(newOpportunity.Id);
system.debug('OpportunityService.updateDrivesOnCalendarWithOpportunityChanges newOpp : ' + newOpportunity + '\n oldOpp : ' + oldOpportunity);

//Check if cancellation reason has changed
if(newOpportunity.sked_Cancellation_Reason__c != oldOpportunity.sked_Cancellation_Reason__c) {
updateOpportunityMap.put(newOpportunity.Id, newOpportunity);
cancelReasonSet.add(newOpportunity.Id);
}
//Check if account manager has changed
if(newOpportunity.Account_Manager__c != oldOpportunity.Account_Manager__c) { 
accManagerSet.add(newOpportunity.Id);
if(!updateOpportunityMap.ContainsKey(newOpportunity.Id)) {
updateOpportunityMap.put(newOpportunity.Id, newOpportunity);
}
}
//Check if anticipated registered donor template has changed
if(newOpportunity.Anticipated_Registered_Donors_Template__c != oldOpportunity.Anticipated_Registered_Donors_Template__c) {
ardTemplateSet.add(newOpportunity.Id);
if(!updateOpportunityMap.ContainsKey(newOpportunity.Id)) {
updateOpportunityMap.put(newOpportunity.Id, newOpportunity);
}
}
}

if (updateOpportunityMap <> null && !updateOpportunityMap.isEmpty()) {
//Get the list of drives corresponding to the opportunities that have been updated
List<sked_Drive__c> drivesToUpdateList = [SELECT Id, sked_Cancellation_Reason__c, sked_Opportunity__c, sked_Drive_Owner__c,  sked_Historical_Registered_Donors__c
FROM sked_Drive__c WHERE sked_Opportunity__c IN:updateOpportunityMap.keySet()];

//Prepare date for the update event container
List<FieldIdentifiers> driveFieldsList = new List<FieldIdentifiers>();
for (sked_Drive__c skedDrive : drivesToUpdateList) {
FieldIdentifiers driveField = new FieldIdentifiers();
driveField.Sked_Drive_Id = skedDrive.Id;
if(cancelReasonSet <> null && cancelReasonSet.contains(skedDrive.sked_Opportunity__c)) {
driveField.Sked_Cancellation_Reason = updateOpportunityMap.get(skedDrive.sked_Opportunity__c).sked_Cancellation_Reason__c == null ? '' : updateOpportunityMap.get(skedDrive.sked_Opportunity__c).sked_Cancellation_Reason__c;  
System.debug('\n #### Cancellation Reason Updated  => ' + driveField.Sked_Cancellation_Reason);
}                
if(accManagerSet <> null && accManagerSet.contains(skedDrive.sked_Opportunity__c)) {
driveField.sked_Drive_Owner = updateOpportunityMap.get(skedDrive.sked_Opportunity__c).Account_Manager__c == null ? '' : updateOpportunityMap.get(skedDrive.sked_Opportunity__c).Account_Manager__c;  
System.debug('\n #### Account Manager Updated  => ' + driveField.sked_Drive_Owner);
}
if(ardTemplateSet <> null && ardTemplateSet.contains(skedDrive.sked_Opportunity__c)) {
driveField.sked_Historical_Registered_Donors = updateOpportunityMap.get(skedDrive.sked_Opportunity__c).Anticipated_Registered_Donors_Template__c == null ? 0 : updateOpportunityMap.get(skedDrive.sked_Opportunity__c).Anticipated_Registered_Donors_Template__c;  
}
driveFieldsList.add(driveField);
}

UpdateEvent driveUpdateEvent = new UpdateEvent();
driveUpdateEvent.objectName = 'DrivesOnCalendar';
driveUpdateEvent.objectFields = driveFieldsList;
String objectDataJSON = JSON.serialize(driveUpdateEvent);

//Prepare platform event to publish
List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 
Update_Event__e event = new Update_Event__e(
Object_Data__c = objectDataJSON
);
updateEventList.add(event);

System.debug('\n #### json  => ' + objectDataJSON);

//Publish Event
if(!updateEventList.isEmpty()) {
List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);

for(Database.SaveResult eventPubResult : eventPubResultList) {
if(eventPubResult.isSuccess()) {
System.debug('\n #### Events published successfully  => ' + eventPubResult);
}
else {
for(Database.Error pubError : eventPubResult.getErrors()) {
System.debug('\n #### Event publishing failed => ' + pubError.getStatusCode() + ' => ' + pubError.getMessage());
}
}
}
}            
} 
}*/
    
    public static void deleteOpptyTeamMembers(Set<Id> setOfOpptyIds){
        
        List<OpportunityTeamMember> listofOpptyTeamMTodelete= [SELECT Id,OpportunityId,TeamMemberRole,UserId FROM OpportunityTeamMember where OpportunityId IN:setOfOpptyIds];
        if(!listofOpptyTeamMTodelete.isEmpty()){
            /*Schema.DescribeSObjectResult ds = OpportunityTeamMember.sObjectType.getDescribe();
if(ds.isDeletable()){}*/
            database.delete(listofOpptyTeamMTodelete,false);
        }
    }
    
    public static void assignFlowStartAndEndTimeValues(List<opportunity> newOppsList, Map<Id, Opportunity> oldOpportunityMap) {
        
        Map<Id, sked__Location__c> driveSiteMap = new Map<Id,sked__Location__c>();
        Set<Id> drivesToUpdate = new Set<Id>();
        
        for(Opportunity oppRecord : newOppsList){
            if(oppRecord.Drive_Site__c != null) {
                drivesToUpdate.add(oppRecord.Drive_Site__c);
            }
        }
        
        if(drivesToUpdate.size() > 0) {
            driveSiteMap = new Map<Id, sked__Location__c>([SELECT Id, Name, sked_Room_Name__c FROM sked__Location__c WHERE ID IN:drivesToUpdate]);
        }
        
        for(Opportunity opRecord : newOppsList){     
            Opportunity oldOpportunity = oldOpportunityMap?.get(opRecord.Id);
            if(oldOpportunity == null){oldOpportunity = new opportunity();}
            system.debug('OpportunityService.assignFlowStartAndEndTimeValues Here is newOpp : ' + opRecord + '\n  Here is oldOpp : ' + oldOpportunity);
            
            //Check if the start time has changed  
            if((oldOpportunity != null) && (opRecord.Start_Time__c != null && oldOpportunity.Start_Time__c != null) && 
               (opRecord.Start_Time__c != oldOpportunity.Start_Time__c)) {
                   opRecord.Flow_Start_Time_Field__c =  OneTimeFlowTimeFieldUpdateBatch.getFlowTime(opRecord.Start_Time__c);
                   opRecord.Flow_Start_Time_Label_Text__c = Helper.getStartEndTimeLabelText(opRecord.Flow_Start_Time_Field__c);
               }
            //Moved the logic to populate the Start_Time__c from WF to before insert trigger 
            ////else if(oldOpportunity.Flow_Start_Time_Field__c !=null && opRecord.Flow_Start_Time_Field__c!=null ) 
            ////{
            else if((opRecord.Start_Time__c == null && opRecord.Flow_Start_Time_Field__c != null ) ||
                    (opRecord.Flow_Start_Time_Field__c != oldOpportunity.Flow_Start_Time_Field__c)){
                        opRecord.Start_Time__c = Time.newInstance(Integer.valueOf(opRecord.Flow_Start_Time_Field__c.left(2)), Integer.valueOf(opRecord.Flow_Start_Time_Field__c.right(2)), 0, 0);
                        opRecord.Flow_Start_Time_Label_Text__c = Helper.getStartEndTimeLabelText(opRecord.Flow_Start_Time_Field__c);
                    }
            ////}
            //Check if the end time has changed
            if((oldOpportunity != null) && (opRecord.End_Time__c != null && oldOpportunity.End_Time__c != null) && 
               (opRecord.End_Time__c != oldOpportunity.End_Time__c)) {
                   opRecord.Flow_End_Time_Field__c =  OneTimeFlowTimeFieldUpdateBatch.getFlowTime(opRecord.End_Time__c);
                   opRecord.Flow_End_Time_Label_Text__c = Helper.getStartEndTimeLabelText(opRecord.Flow_End_Time_Field__c);
               }
            //Moved the logic to populate the End_Time__c from WF to before insert trigger 
            else if((opRecord.End_Time__c == null && opRecord.Flow_End_Time_Field__c != null) ||
                    (opRecord.Flow_End_Time_Field__c != oldOpportunity.Flow_End_Time_Field__c)) {
                        opRecord.End_Time__c = Time.newInstance(Integer.valueOf(opRecord.Flow_End_Time_Field__c.left(2)), Integer.valueOf(opRecord.Flow_End_Time_Field__c.right(2)), 0, 0);
                        opRecord.Flow_End_Time_Label_Text__c = Helper.getStartEndTimeLabelText(opRecord.Flow_End_Time_Field__c);
                    }
            
            if(opRecord.Start_Time__c != null && opRecord.Flow_Start_Time_Field__c == null) {
                opRecord.Flow_Start_Time_Field__c =  OneTimeFlowTimeFieldUpdateBatch.getFlowTime(opRecord.Start_Time__c);
                opRecord.Flow_Start_Time_Label_Text__c = Helper.getStartEndTimeLabelText(opRecord.Flow_Start_Time_Field__c);
            }
            if(opRecord.End_Time__c != null && opRecord.Flow_End_Time_Field__c == null) {
                opRecord.Flow_End_Time_Field__c =  OneTimeFlowTimeFieldUpdateBatch.getFlowTime(opRecord.End_Time__c); 
                opRecord.Flow_End_Time_Label_Text__c = Helper.getStartEndTimeLabelText(opRecord.Flow_End_Time_Field__c);
            }
        }
    }
    
    /* HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
* HRP-5487 :CR: Adding Account Team to Blood Drive Team  == Start
*/ 
    public static void updateOpptyOwner_OpportunityTeam(List<opportunity> newOppsList,Boolean isBeforeInsert,Boolean isAfterInsert){
        Boolean isMigrationEnabled=Boolean.valueOf(Label.IsMigrationEnable);
        if(isBeforeInsert){
            if(isMigrationEnabled == false){
                updateOpptyOwner_OpptyTeam(newOppsList,null,true,false,false);
            } 
            if(isMigrationEnabled == true || Test.isRunningTest()){
                updateOpptyOwner_Migration(newOppsList);
            }
        }
        if(isAfterInsert){
            if(newOppsList!=null && newOppsList.size()<=10){
                updateOpptyOwner_OpptyTeam(newOppsList,null,false,true,false);
            } else if(newOppsList!=null && newOppsList.size() >10){
                publishPlarformEventsOnAfterInsert(newOppsList);
            }
        }
        
    }
    
    public static void updateOpptyOwner_OpptyTeam(List<opportunity> newOppsList, Map<Id, Opportunity> oldOpptyMap,Boolean updateOpptyOwner,Boolean addOpptyTeam,Boolean chkExistingOpptyTeam){
        Set<Id> setOfAcctIds=new Set<Id>();
        Set<Id> setOfOpptyIds=new Set<Id>();
        for(opportunity opRecord:newOppsList){
            if(oldOpptyMap == null && opRecord.Drive_Date__c!=null && opRecord.AccountId!=null){
                setOfAcctIds.add(opRecord.AccountId);
            }
            
            if(oldOpptyMap != null && oldOpptyMap.get(opRecord.id).Drive_Date__c!=opRecord.Drive_Date__c &&opRecord.Drive_Date__c !=null &&
               opRecord.AccountId!=null){
                   setOfAcctIds.add(opRecord.AccountId);
                   setOfOpptyIds.add(opRecord.id);
               }    
        }
        if(!setOfAcctIds.isEmpty()){
            updateOpptyOwner_AddOpptyTeamMembers(newOppsList,setOfAcctIds,updateOpptyOwner,addOpptyTeam,chkExistingOpptyTeam,setOfOpptyIds);// HRP-10569 added setOfOpptyIds parameter
        }
    }
    
    public static void updateOpptyOwner_AddOpptyTeamMembers(List<opportunity> newOppsList,Set<Id> setOfAcctIds,Boolean updateOpptyOwner,Boolean addOpptyTeam,Boolean chkExistingOpptyTeam,Set<Id> setOfOpptyIds){//HRP-10569 added setOfOpptyIds paramete
        system.debug('INsisde updateOpptyOwner_AddOpptyTeamMembers');
        if(setOfOpptyIds!=null)//HRP-10569
        {
        
        List<OpportunityTeamMember> optyTeamMemberListToInsert = new List<OpportunityTeamMember>();
        Map<Id,Id> oppWithOwnerIdMap = new Map<Id,Id>();
        Map<Id,Id> oppWithAccMangrIdMap = new Map<Id,Id>();
        Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap = new Map<Id,Opportunity>(); //HRP-10359
        
        //HRP-10569 start 
        /*the below change adds existing & upcoming Teams into the map "mapOfAcctsWithTeamMembers"
         * mapOfAcctsWithTeamMembers is made static, so that the logic doesn't have to execute separately once for before and after update
         * */ 
        if(mapOfAcctsWithTeamMembers.isEmpty())
            {
        map<id,list<accountTeamMember>> accIdFutureAccTeamMap = new map<id,list<accountTeamMember>>();
        map<id,list<accountTeamMember>> accIdExstngAccTeamMap = new map<id,list<accountTeamMember>>();
        accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(new list<id>(setOfAcctIds),bsf_constants.BYPASS_TEAMDML,setOfOpptyIds,accIdFutureAccTeamMap,accIdExstngAccTeamMap);
        mapOfAcctsWithTeamMembers.putAll(accIdExstngAccTeamMap);
                for(id i:mapOfAcctsWithTeamMembers.keyset())
        {
            if(accIdFutureAccTeamMap != null && accIdFutureAccTeamMap.containsKey(i))
            {
                mapOfAcctsWithTeamMembers.get(i).addAll(accIdFutureAccTeamMap.get(i));
            }
            
        }
            }
            //HRP-10569 end
            
            //commented part of HRP-10569
        //List<AccountTeamMember> teamMemberList = [SELECT Id,Is_Covering_Recruiter__c,AccountId,End_Date__c,UserId,TeamMemberRole,Start_Date__c, BSF_Portfolio__c 
                                                  //FROM AccountTeamMember WHERE AccountId IN:setOfAcctIds Order By LastModifiedDate desc ];                                           
        
        /*for(AccountTeamMember atmRecord:teamMemberList){   
            if(mapOfAcctsWithTeamMembers.containsKey(atmRecord.AccountId)){
                List<AccountTeamMember> listOfAcctTeamMembers= mapOfAcctsWithTeamMembers.get(atmRecord.AccountId);
                listOfAcctTeamMembers.add(atmRecord);
                mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,listOfAcctTeamMembers);
            } else {       
                mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,new List<AccountTeamMember>{atmRecord});       
            }
        }*/
        //commented part of HRP-10569
        //HRP-11849 starts
        Map<Id, List<Account_Portfolio_Assignment__c>> accIdVsaccPortfolioAssignmentMap = new Map<Id, List<Account_Portfolio_Assignment__c>>();
        if(setOfAcctIds!= null && !setOfAcctIds.isEmpty() && Trigger.isExecuting && Trigger.isBefore){
            for (Account_Portfolio_Assignment__c pfa : [SELECT Id,
                                                                BSF_Portfolio__c,
                                                                BSF_Portfolio__r.Portfolio_Type__c,
                                                                BSF_Portfolio__r.Parent_Portfolio__c,
                                                                BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,
                                                                BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,
                                                                BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,
                                                                End_Date__c,
                                                                Start_Date__c,
                                                                Account__c
                                                        FROM Account_Portfolio_Assignment__c 
                                                        WHERE BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' 
                                                        AND Account__c IN: setOfAcctIds
                                                        AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio')]){
                if (!accIdVsaccPortfolioAssignmentMap.containsKey(pfa.Account__c)) {
                    accIdVsaccPortfolioAssignmentMap.put(pfa.Account__c, new List<Account_Portfolio_Assignment__c>()); 
                }
                accIdVsaccPortfolioAssignmentMap.get(pfa.Account__c).add(pfa);
            }
        }
        //HRP-11849 ends
        
        map<id,list<String>> oppIdLookupPopulatedListMap = new map<id,list<String>>();//HRP-11234
        map<id,AccountTeamMember> oppIdCoverageAmMap = new  map<id,AccountTeamMember>();//HRP-11234
        oppIdCoverageAmMap = AccountTeamMemberService.isCoverageAmPresent(mapOfAcctsWithTeamMembers,newOppsList);//HRP-11234
        set<id> accIdSet = new set<id>();//HRP-11234
        for(Opportunity opRecord:newOppsList){
            accIdSet.add(opRecord.accountId);
            //HRP-11234 start
            if(!oppIdLookupPopulatedListMap.containsKey(opRecord.id))
                oppIdLookupPopulatedListMap.put(opRecord.id,new list<string>());
            //HRP-11234 End
            if(mapOfAcctsWithTeamMembers.containsKey(opRecord.AccountId))    {
                Integer i=0,j=0; //HRP-10359
                for(AccountTeamMember atmRecords:mapOfAcctsWithTeamMembers.get(opRecord.AccountId)){
                    system.debug('atmRecords '+atmRecords);
                    system.debug('opRecord.Drive_Date__c '+opRecord.Drive_Date__c);
                    if(opRecord.Drive_Date__c>=atmRecords.Start_Date__c && opRecord.Drive_Date__c<=atmRecords.End_Date__c){
                        
                        if(atmRecords.TeamMemberRole == 'Account Manager' && updateOpptyOwner == true){
                            OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                            if(!atmRecords.Is_Covering_Recruiter__c)//HRP-11281
                                opRecord.OwnerId=atmRecords.UserId;
                            if((oppIdCoverageAmMap==null || (!oppIdCoverageAmMap.containsKey(opRecord.id) || (oppIdCoverageAmMap.containsKey(opRecord.id) && oppIdCoverageAmMap.get(opRecord.id).UserId !=null && oppIdCoverageAmMap.get(opRecord.id).UserId!=opRecord.Account_Manager__c))))//HRP-11234
                            {
                            opRecord.Account_Manager__c=atmRecords.UserId;
                            }
                            if(!atmRecords.Is_Covering_Recruiter__c){ //HRP-10359 start
                                if(atmRecords.BSF_Portfolio__c != NULL){
                                    opRecord.Account_Manager_Portfolio__c = atmRecords.BSF_Portfolio__c;
                                }
                            } //HRP-10359 end
                            if(!atmRecords.Is_Covering_Recruiter__c)//HRP-11281
                                oppWithOwnerIdMap.put(opRecord.id,opRecord.OwnerId);
                            oppWithAccMangrIdMap.put(opRecord.id,opRecord.Account_Manager__c);
                            i++;
                        }  //HRP-10359 start
                        if(atmRecords.TeamMemberRole == 'District Manager' && j== 0 && updateOpptyOwner == true){
                            OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                            opRecord.District_Manager__c=atmRecords.UserId;
                            if(!atmRecords.Is_Covering_Recruiter__c){
                                if(atmRecords.BSF_Portfolio__c != NULL){
                                    opRecord.District_Manager_Portfolio__c = atmRecords.BSF_Portfolio__c;
                                }
                            }
                            j++;
                        }  //HRP-10359 end
                        if(addOpptyTeam == true){
                            OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                            optyTeamMemeberToAdd.OpportunityId = opRecord.Id;
                            optyTeamMemeberToAdd.TeamMemberRole = atmRecords.TeamMemberRole;
                            if(atmRecords.TeamMemberRole==bsf_constants.ACCOUNT_MANAGER && !atmRecords.Is_Covering_Recruiter__c)
                                optyTeamMemeberToAdd.TeamMemberRole='Opportunity Owner'; 
                            optyTeamMemeberToAdd.UserId = atmRecords.UserId; 
                            optyTeamMemeberToAdd.is_AccountTeammember__c = true; 
                            optyTeamMemberListToInsert.add(optyTeamMemeberToAdd);
                        }
                        
                        //HRP-11234 start
                        if(atmRecords.TeamMemberRole == 'Account Manager')
                        {
                            
                            if(!atmRecords.Is_Covering_Recruiter__c)
                                oppIdLookupPopulatedListMap.get(opRecord.id).add('AM');
                            else
                                oppIdLookupPopulatedListMap.get(opRecord.id).add('CovAM');
                            
                        }
                        if(atmRecords.TeamMemberRole == 'District Manager')
                        {
                            if(!oppIdLookupPopulatedListMap.containsKey(opRecord.id))
                                oppIdLookupPopulatedListMap.put(opRecord.id,new list<string>());
                            
                            oppIdLookupPopulatedListMap.get(opRecord.id).add('DM');
                        }
                        //HRP-11234 End
                    }
                }
            }
            //HRP-11849 starts
            if (!accIdVsaccPortfolioAssignmentMap.isEmpty() && accIdVsaccPortfolioAssignmentMap.containsKey(opRecord.AccountId)) {
                for(Account_Portfolio_Assignment__c pfa : accIdVsaccPortfolioAssignmentMap.get(opRecord.AccountId)){
                    if(pfa.Start_Date__c <= opRecord.Drive_Date__c  && pfa.End_Date__c >= opRecord.Drive_Date__c){
                        opRecord.Account_Manager_Portfolio__c = pfa.BSF_Portfolio__c;
                        if(pfa.BSF_Portfolio__r.Parent_Portfolio__c != null 
                                && String.isNotBlank(pfa.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c)
                                && pfa.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase('District Manager')){
                                    opRecord.District_Manager_Portfolio__c = pfa.BSF_Portfolio__r.Parent_Portfolio__c;
                        }else if(pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c != null 
                                && String.isNotBlank(pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c)
                                && pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase('District Manager')){
                                    opRecord.District_Manager_Portfolio__c = pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c;
                        }else{
                            opRecord.District_Manager_Portfolio__c = null;
                        }
                        break;
                    }else{
                        opRecord.Account_Manager_Portfolio__c = null;
                        opRecord.District_Manager_Portfolio__c = null;
                    }
                }
            }
            //HRP-11849 ends
        }
        //HRP-11234 start
        map<string,OpportunityTeamMember> oppTeamToAdd = new map<string,OpportunityTeamMember>();
        AccountPortfolioAssignmentService.systemUserAsOwner(newOppsList,oppIdLookupPopulatedListMap,oppTeamToAdd,trigger.isAfter,oppWithOwnerIdMap,oppIdVsAMDMPortfoliodMap);
        optyTeamMemberListToInsert.addAll(oppTeamToAdd.values());
        //HRP-11234 end
        
        //HRP-8050
        if(updateOpptyOwner && (oppWithOwnerIdMap != null || oppWithAccMangrIdMap!= null))//HRP-11234 updateOpptyOwner check
            OpportunityService.UpdateDriveOwnerOnOppOwnerUpdate(oppWithOwnerIdMap,oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap); //HRP-10359
        
        if(chkExistingOpptyTeam == true) {
            List<OpportunityTeamMember> listOfOpptyTeamMembersToInsert=new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> listOfOpptyTeamMembersToDelete=new List<OpportunityTeamMember>();
            Map<Id,List<OpportunityTeamMember>> mapOfOpptysWithTeamMembers=new Map<Id,List<OpportunityTeamMember>>(); 
            
            
            List<OpportunityTeamMember> listOfOpptyTeamMembers=  [select Id,OpportunityId,TeamMemberRole,UserId,is_AccountTeammember__c,User.name from OpportunityTeamMember where OpportunityId IN:setOfOpptyIds];
            for(OpportunityTeamMember otmRecord:listOfOpptyTeamMembers){   
                if(mapOfOpptysWithTeamMembers.containsKey(otmRecord.OpportunityId)){
                    List<OpportunityTeamMember> lOfOpptyTeamMembers= mapOfOpptysWithTeamMembers.get(otmRecord.OpportunityId);
                    lOfOpptyTeamMembers.add(otmRecord);
                    mapOfOpptysWithTeamMembers.put(otmRecord.OpportunityId,lOfOpptyTeamMembers);
                } else 
                {       
                    mapOfOpptysWithTeamMembers.put(otmRecord.OpportunityId,new List<OpportunityTeamMember>{otmRecord});
                }
            }
            
            for(OpportunityTeamMember newOptMember:optyTeamMemberListToInsert){
                
                if(mapOfOpptysWithTeamMembers.containsKey(newOptMember.OpportunityId)){
                    Map<Id,OpportunityTeamMember> mapOfUserIds=new Map<Id,OpportunityTeamMember>();                    
                    for(OpportunityTeamMember uid:mapOfOpptysWithTeamMembers.get(newOptMember.OpportunityId)){
                        mapOfUserIds.put(uid.UserId,uid);
                    }
                    if(!mapOfUserIds.containsKey(newOptMember.UserId) || 
                       (mapOfUserIds.containsKey(newOptMember.UserId) && (newOptMember.TeamMemberRole != mapOfUserIds.get(newOptMember.UserId).TeamMemberRole || newOptMember.TeamMemberRole==BSF_Constants.OPPORTUNITY_OWNER || newOptMember.TeamMemberRole==BSF_Constants.ACCOUNT_MANAGER)  //HRP-11234 TeamMember role check
                        && mapOfUserIds.get(newOptMember.UserId).user.name!='System User') || oppWithOwnerIdMap.get(newOptMember.OpportunityId)==newOptMember.UserId){                                                      
                        listOfOpptyTeamMembersToInsert.add(newOptMember);
                    }
                }
            }
            system.debug('listOfOpptyTeamMembersToInsert'+listOfOpptyTeamMembersToInsert);
            for(Opportunity opRecord:newOppsList){
                if(mapOfOpptysWithTeamMembers.containsKey(opRecord.Id)){
                    List<OpportunityTeamMember> listOfIds= mapOfOpptysWithTeamMembers.get(opRecord.Id);
                    Map<Id,Id> mapOfUserIds=new Map<Id,Id>();
                    for(OpportunityTeamMember newOptMember:optyTeamMemberListToInsert){
                        if(newOptMember.OpportunityId == opRecord.id){
                            mapOfUserIds.put(newOptMember.UserId,newOptMember.UserId);
                        }
                    }
                    for(OpportunityTeamMember op:listOfIds){
                        if(!mapOfUserIds.containsKey(op.UserId) && op.is_AccountTeammember__c == true ){
                            listOfOpptyTeamMembersToDelete.add(op);    
                        }
                    }
                }
            }
            
            if(!listOfOpptyTeamMembersToInsert.isEmpty()){
                Database.SaveResult[] srList = Database.insert(listOfOpptyTeamMembersToInsert, false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred in AccountTeamMemberService Insert.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug(' fields that affected this error: ' + err.getFields());
                        }    
                    }
                }
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','OpportunityService','updateOpptyOwner_AddOpptyTeamMembers','Error','Error in adding Opportunity Team');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            if(!listOfOpptyTeamMembersToDelete.isEmpty()){
                /*Schema.DescribeSObjectResult ds = OpportunityTeamMember.sObjectType.getDescribe();
if(ds.isDeletable()){}*/
                Database.delete(listOfOpptyTeamMembersToDelete,false);
            }
        }
        
        if(!optyTeamMemberListToInsert.isEmpty() && chkExistingOpptyTeam == false){
            Database.SaveResult[] srList = Database.insert(optyTeamMemberListToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred in AccountTeamMemberService Insert.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug(' fields that affected this error: ' + err.getFields());
                    }     
                }
            }
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','OpportunityService','updateOpptyOwner_AddOpptyTeamMembers','Error','Error in adding Opportunity Team');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
    }
    
    // Migration for updating OpptyOwner,will run in PlatformEvent mode   
    public static void updateOpptyOwner_Migration(List<opportunity> newOppsList){
        Set<Id> setOfAcctIds=new Set<Id>();
        for(opportunity opRecord:newOppsList){
            if(opRecord.AccountId!=null){
                setOfAcctIds.add(opRecord.AccountId);
            }
        }
        
        if(!setOfAcctIds.isEmpty()){            
            Map<Id,Account> mapOfAccts=new Map<Id,Account>([select Id,Account_Manager__c,ownerId from Account where Id IN:setOfAcctIds]);            
            for(opportunity opRecord:newOppsList){
                if(opRecord.AccountId!=null && mapOfAccts.containsKey(opRecord.AccountId)){
                    Account accRecord=mapOfAccts.get(opRecord.AccountId);
                    OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                    if(accRecord.Account_Manager__c != null){
                        opRecord.OwnerId=accRecord.Account_Manager__c;
                        opRecord.Account_Manager__c=accRecord.Account_Manager__c;
                    }
                }
            }
        }
        
    }
    //Migration for adding Teammembers,will run in PlatformEvent mode
    public static void publishPlarformEventsOnAfterInsert(List<Opportunity> newOppsList){
        List<OpportunityTeamMemberEvent__e> publishEvents = new List<OpportunityTeamMemberEvent__e>();
        for(Opportunity opRecord:newOppsList){
            OpportunityTeamMemberEvent__e eve = new OpportunityTeamMemberEvent__e();
            eve.OpportunityId__c = opRecord.Id ;                  
            publishEvents.add(eve);
        }
        if(publishEvents.size()>0){
            System.debug('Enter in publishPlarformEventsOnAfterInsert before Here====='+publishEvents.size());
            EventBus.publish(publishEvents);
        }
        
    }
    public static void AddOpptyTeamMembers_Migration(List<opportunity> newOppsList){        
        Set<Id> setOfAcctIds=new Set<Id>();
        Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers=new Map<Id,List<AccountTeamMember>>();
        List<OpportunityTeamMember> optyTeamMemberListToInsert = new List<OpportunityTeamMember>();
        for(opportunity opRecord:newOppsList){
            if(opRecord.AccountId!=null){
                setOfAcctIds.add(opRecord.AccountId);
            }
        }
        
        List<AccountTeamMember> teamMemberList = [SELECT Id,Is_Covering_Recruiter__c,AccountId,End_Date__c,UserId,TeamMemberRole,Start_Date__c 
                                                  FROM AccountTeamMember WHERE AccountId IN:setOfAcctIds ];
        for(AccountTeamMember atmRecord:teamMemberList){   
            if(mapOfAcctsWithTeamMembers.containsKey(atmRecord.AccountId)){
                List<AccountTeamMember> listOfAcctTeamMembers= mapOfAcctsWithTeamMembers.get(atmRecord.AccountId);
                listOfAcctTeamMembers.add(atmRecord);
                mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,listOfAcctTeamMembers);
            } else {       
                mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,new List<AccountTeamMember>{atmRecord});       
            }
        }
        
        for(Opportunity opRecord:newOppsList){
            if(mapOfAcctsWithTeamMembers.containsKey(opRecord.AccountId))    { 
                for(AccountTeamMember atmRecords:mapOfAcctsWithTeamMembers.get(opRecord.AccountId)){
                    if(opRecord.Drive_Date__c>=atmRecords.Start_Date__c && opRecord.Drive_Date__c<=atmRecords.End_Date__c){
                        
                        OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                        optyTeamMemeberToAdd.OpportunityId = opRecord.Id;
                        optyTeamMemeberToAdd.TeamMemberRole = atmRecords.TeamMemberRole;
                        optyTeamMemeberToAdd.UserId = atmRecords.UserId;                                
                        optyTeamMemberListToInsert.add(optyTeamMemeberToAdd);
                    }          
                }
            }
        }
        
        if(!optyTeamMemberListToInsert.isEmpty()){
            Database.SaveResult[] srList = Database.insert(optyTeamMemberListToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred in AccountTeamMemberService Insert.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug(' fields that affected this error: ' + err.getFields());
                    }     
                }
            }
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','OpportunityService','AddOpptyTeamMembers_Migration','Error','Error in adding Opportunity Team');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
    /***
* HRP-5852->HRP-1615 - Salesforce COE - Oppy promotion record is not removed when the end date is changed
* When opportunity drive date will change to the future date of its associated promotion end date then remove the 
* promotion from the opportunity and notify account manager via mail
* */
    
    Public Static Void validatePromotionEndDate(list<Opportunity> newOppList, map<Id, Opportunity> oldOppMap){
        List<Id> listOfPromotionExpiredIds = new list<Id>();
        map<Id, Date> mapOfOppIdWithDriveDate = new map<Id, Date>();
        set<id> setOfOppIds = new set<id>();
        List<String> deletedOppPromoNames = new List<String> ();
        List<String> accountManagerEmailIds = new List<String> ();
        map<Id, Opportunity_Promotion__c> mapOfOppIdWithPromotion = new map<Id, Opportunity_Promotion__c>();
        Map<Opportunity_Promotion__c,OpportunityTeamMember> oppPromotionMap = new Map<Opportunity_Promotion__c,OpportunityTeamMember>();
        
        for(Opportunity newOpp: newOppList){
            system.debug('#### old drive date ' + oldOppMap.get(newOpp.Id).Drive_Date__c);
            if(newOpp.Drive_Date__c !=  oldOppMap.get(newOpp.Id).Drive_Date__c){
                // driveDateChangeOppId.add(newOpp.Id);
                mapOfOppIdWithDriveDate.put(newOpp.Id, newOpp.Drive_Date__c);
            }
        }
        
        if(!mapOfOppIdWithDriveDate.isEmpty()){
            system.debug('### mapOfOppIdWithDriveDate ' + mapOfOppIdWithDriveDate);
            list<Opportunity_Promotion__c> oppPromotionList = [SELECT Id, 
                                                               Name, 
                                                               Drive_Date__c,
                                                               Promotion__c,
                                                               Promotion__r.Name,
                                                               Promotion_End_Date__c,
                                                               Blood_Drive_Opportunity__c,
                                                               Blood_Drive_Opportunity__r.Name
                                                               FROM Opportunity_Promotion__c 
                                                               WHERE Blood_Drive_Opportunity__c 
                                                               IN: mapOfOppIdWithDriveDate.KeySet()];
            system.debug('###### oppPromotionList ' + oppPromotionList);
            for(Opportunity_Promotion__c oppPromo: oppPromotionList){
                if(oppPromo.Promotion_End_Date__c < mapOfOppIdWithDriveDate.get(oppPromo.Blood_Drive_Opportunity__c)){
                    listOfPromotionExpiredIds.add(oppPromo.Id);
                    setOfOppIds.add(oppPromo.Blood_Drive_Opportunity__c);
                    deletedOppPromoNames.add(oppPromo.Name); 
                    mapOfOppIdWithPromotion.put(oppPromo.Blood_Drive_Opportunity__c,oppPromo);
                }
            }
            system.debug('### listOfPromotionExpiredIds ' + listOfPromotionExpiredIds);
            system.debug('### setOfOppIds ' + setOfOppIds);
            
            if(!listOfPromotionExpiredIds.isEmpty()){
                
                Database.delete(listOfPromotionExpiredIds);
                list<OpportunityTeamMember> oppAccountManagerList = [SELECT Id, User.Email, User.Name, OpportunityId, Name, TeamMemberRole 
                                                                     FROM OpportunityTeamMember 
                                                                     where TeamMemberRole  = 'Account Manager' AND
                                                                     OpportunityId IN : setOfOppIds];
                system.debug('## oppAccountManagerList ' + oppAccountManagerList);
                for(OpportunityTeamMember oppAccManager : oppAccountManagerList){
                    accountManagerEmailIds.add(oppAccManager.User.Email);
                    Opportunity_Promotion__c opPromo = mapOfOppIdWithPromotion.get(oppAccManager.OpportunityId);
                    oppPromotionMap.put(opPromo,oppAccManager);
                }
                if(!oppPromotionMap.isEmpty())
                    sendOpportunityPromotionDisassociatEmail(oppPromotionMap);
            }
        }
    }
    public static void sendEmail(List<String> emailIds,List<String> affectedOppPromoNames){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        //message.toAddresses =  emailIds;
        //  emailIds.add('anil.kallu@redcross.org');
        //   emailIds.add('lakshmi.natakarani@redcross.org');
        System.debug('sendEmail==>');
        message.toAddresses =  emailIds;
        
        message.optOutPolicy = 'FILTER';
        message.subject = 'promotion/(s) has dissassociated from opportunity';
        String text = 'Hi, '+ 
            ' promotion end date has fallen under drive date of opportunity. So promotion has been removed'+
            ' from opportunity.';
        text = text+  '\n'+  '\n' ;//add two line breaks
        for(String val : affectedOppPromoNames)
        {
            text = text + val +  '\n' ;
        }
        
        message.plainTextBody = text;
        
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            BSF_EmailNotification.sendEmails(messages,'PromotionExpiry',null);//Changes for  HRP-11608
    }
    
    //HRP-6038 -> Handle Drive Affiliation creation post new opportunity inserts
    public static void createDriveAffiliations(List<Opportunity> newOppList,Map<Id,Opportunity> newOppMap){
        system.debug('inside createDriveAffiliations');
        //commented for HRP-10204
        /*Set<ID> templateIdList = new Set<ID>();
        for(Opportunity opp:newOppList){
            if(opp.Parent_Template_Id__c != null)
                templateIdList.add(opp.Parent_Template_Id__c);
        }
        CreateDriveAffiliationsBatch batchClass = new CreateDriveAffiliationsBatch(templateIdList,newOppMap);
        Database.executeBatch(batchClass, 1);*/
        DriveAffiliationHandler.getInstance(newOppList,true).run(); //Added for HRP-10204
    }
    
    //HRP-6233 & HRP-6234 && HRP-10959
    public static void updateDrivesOnCalendarStatus(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList,
                                                    Set<Id> invalidStageOppIds)
    {

        system.debug('###FWO###: Inside updateDrivesOnCalendarStatus');

        
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
        
        Map<Id, sked_Drive__c> mapOppToDriveId = new Map<Id, sked_Drive__c>();
        Map<Id, Id> mapDOCToOppId = new Map<Id, Id>();
        List<slwcDriveService.driveModel> lstOfDrives = new List<slwcDriveService.driveModel>();
        //HRP-11524 --> Starts Here
        string profileName;
        String runningUser = UserInfo.getName();
        if(runningUser != Label.OpportunityStageAllowedRunningUser) {
            profileName = [SELECT Id, Name FROM Profile WHERE Id =:UserInfo.getProfileId()].Name ;    
        }
        //HRP-11524 --> Continues
        
        //Create a set of Opportunity Ids
        Set<Id> setOppIds = new Set<Id>();
        for(Opportunity newOpp : newOpportunityList) {
            setOppIds.add(newOpp.Id);
        }        
        
        //Create a map of opportunity -> drives on calendar
        //HRP-11393- When opp is linked to two drives where one drive is already cancelled, but doesn't cancel the second one, pick one that is not cancelled
        List<sked_Drive__c> allDrivesMatchingOpp = new List<sked_Drive__c>(); //HRP--11393 , In rare cases where there is more than one drive (not surrogates) for this opp, we need to cancel them all
        
        //HRP-11524 --> Continues
        for (sked_Drive__c driveRec : [SELECT Id, sked_Opportunity__c, sked_Status__c  FROM sked_Drive__c WHERE sked_Is_Surrogate__c = false and sked_Opportunity__c IN :setOppIds]) {
                        mapOppToDriveId.put(driveRec.sked_Opportunity__c, driveRec);

            if(mapOppToDriveId.containsKey(driveRec.sked_Opportunity__c) == true && driveRec.sked_Status__c != 'Cancel'){ //for second time, if first time we picked cancelled status, replace it with correct drive
                 mapOppToDriveId.put(driveRec.sked_Opportunity__c, driveRec);
            }
            if(mapOppToDriveId.containsKey(driveRec.sked_Opportunity__c) == false){
               mapOppToDriveId.put(driveRec.sked_Opportunity__c, driveRec); //for first time, insert first drive matching opp
            }
            mapDOCToOppId.put(driveRec.Id,driveRec.sked_Opportunity__c); //added for HRP-10912
            allDrivesMatchingOpp.add(driveRec);// HRP-11393
        }
        
       
        if(!mapOppToDriveId.isEmpty()) {
            system.debug('###FWO: Inside updateDrivesOnCalendarStatus inside for loop');
            for (Opportunity newOpportunity : newOpportunityList) {
                slwcDriveService.driveModel driveModelRec = new slwcDriveService.driveModel();
                Opportunity oldOpportunity = oldOpportunityMap.get(newOpportunity.Id);
                //HRP-11524 --> Continues
                system.debug('oldOpportunity.StageName '+oldOpportunity.StageName);
                Opportunity_Stage_Check__mdt stageChecksForCurrentStage = Opportunity_Stage_Check__mdt.getInstance(oldOpportunity.StageName);
                //HRP-11524 --> Continues
                sked_Drive__c driveRec = mapOppToDriveId.get(newOpportunity.Id);
                system.debug('###FWO: Inside updateDrivesOnCalendarStatus '+driveRec);
                if(driveRec != null && (
                    invalidStageOppIds.contains(newOpportunity.Id)==false)) {//HRP 10959- Only pass opportunities that do not have error
                    system.debug('###FWO: Inside updateDrivesOnCalendarStatus 2 stage is' + newOpportunity.StageName);
                    if (newOpportunity.StageName != oldOpportunity.StageName) {
                        if(newOpportunity.stageName == 'Committed' && driveRec.sked_Status__c != 'Draft') // Adding a check on status so that required validation on opp shows up
                        { 
                            driveModelRec.status = 'Tentative';
                            driveModelRec.id = driveRec.id;
                        }
                        else if(newOpportunity.StageName == 'Closed' && driveRec.sked_Status__c != 'Draft') // Adding a check on status so that required validation on opp shows up
                        {
                            driveModelRec.status = 'Confirmed';
                            driveModelRec.id = driveRec.id;
                        }
                        else if(newOpportunity.StageName == 'Cancelled'){
                             //HRP-11524 --> Continues
                             
                                if(oldOpportunity.StageName == BSF_Constants.STAGE_CLOSED 
                                   && oldOpportunity.DriveStatus__c == BSF_Constants.DOC_STATUS_COMPLETE 
                                   && (!(String.isBlank(profileName)) && (!(stageChecksForCurrentStage.Overriding_Profiles__c).contains(profileName))) 
                                   && !(String.isBlank(newOpportunity.sked_Cancellation_Reason__c))
                                   && !(stageChecksForCurrentStage.Overriding_user__c).contains(runningUser))
                                     {   
                                        
                                        newOpportunity.addError(Label.Drive_Change_Restriction_Message);
                                     }
                                //HRP-11524 --> Ends Here
                               
                                for(sked_Drive__c skedDr: allDrivesMatchingOpp){ //HRP 11393- propogate cancelled status to all drives associated with opportunity, not just one picked
                                    slwcDriveService.driveModel driveModelRecTemp = new slwcDriveService.driveModel();

                                   driveModelRecTemp.status = 'Cancel';
                                   driveModelRecTemp.cancellationReason = newOpportunity.sked_Cancellation_Reason__c;
                                   driveModelRecTemp.id = skedDr.id;
                                   lstOfDrives.add(driveModelRecTemp);//HRP 11393-adding all matching drives, when cancelled status
                                }
                            }
                        }
                        if(driveModelRec != null && driveModelRec.id != null && newOpportunity.StageName != 'Cancelled') { //cancelled status drives are already added above
                            lstOfDrives.add(driveModelRec);
                       }
                }
            }
            if(lstOfDrives != null && lstOfDrives.size() > 0) {
                system.debug('###FWO: Inside updateDrivesOnCalendarStatus 4 lstOfDrives' + lstOfDrives);
                slwcDriveService.updateDriveStatusRequestModel driveUpdateRequest = new slwcDriveService.updateDriveStatusRequestModel();
                driveUpdateRequest.drives = lstOfDrives;
                system.debug('###FWO: Inside updateDrivesOnCalendarStatus 5 driveUpdateRequest' + driveUpdateRequest);
                try{
                    skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
                    slwcDriveService.updateDriveStatuses(driveUpdateRequest); 
                }catch(Exception exp){
                    Set<Id> oppIdSet = new Set<Id>();
                    String expMsg = exp.getMessage();
                    if(expMsg.contains(Custom_Messages__mdt.getInstance('Pending_DCR_Drives').value__c)
                           || expMsg.contains(Custom_Messages__mdt.getInstance('Pending_DCR_Opportunity').value__c)
                           || expMsg.contains('Unable to confirm drive with active Drive Change Request for a change in Drive Date. Please Approve or Reject the Request before continuing.')){
                                expMsg = Custom_Messages__mdt.getInstance('Pending_DCR_Opportunity').value__c;
                    }
                    for(slwcDriveService.driveModel drvM : driveUpdateRequest.drives){
                        oppIdSet.add(mapDOCToOppId.get(drvM.Id));
                    }
                    for(Opportunity opp : newOpportunityList){
                        if(!oppIdSet.isEmpty() && oppIdSet.contains(opp.id))
                        {
                            if(expMsg.contains(Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Account_Internal_Name_Requirment').Error_Msg_on_DOC__c))
                            {
                                expMsg = Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Account_Internal_Name_Requirment').Error_Msg_on_Opportunity__c;
                            }
                            if(expMsg.contains(Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Active_BPL_Requirement').Error_Msg_on_DOC__c))
                            {
                                expMsg = Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Active_BPL_Requirement').Error_Msg_on_Opportunity__c;
                            }
                            if(expMsg.contains(Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('WB_Procedure_Requirement').Error_Msg_on_DOC__c))
                            {
                                expMsg = Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('WB_Procedure_Requirement').Error_Msg_on_Opportunity__c;
                            }
                            if(expMsg.contains(Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Military_Auth_Setting_Requirement').Error_Msg_on_DOC__c))
                            {
                                expMsg = Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Military_Auth_Setting_Requirement').Error_Msg_on_Opportunity__c;
                            }
                            if(expMsg.contains(Validate_Opp_Stage_Drive_Status_Setting__mdt.getInstance('Site_Mandatory_Fields_Requirement').Error_Msg_on_DOC__c))
                            {
                                Map<Id,String> oppIsVsErrorMsgMap = validateRequiredSiteFieldsBasedOnOppStage(newOpportunityList,oldOpportunityMap);
                                if(oppIsVsErrorMsgMap.containsKey(opp.Id) && !String.isBlank(oppIsVsErrorMsgMap.get(opp.Id)))
                                {
                                    expMsg = oppIsVsErrorMsgMap.get(opp.Id);
                                }
                            }
                     
                            opp.addError(expMsg);
                        }
                    }
                }
            }
        }
    }
    
    //HRP-6235
    public static void createSkedFixedSiteDrive(List<Opportunity> newOpportunityList) {
        System.debug('###FWO:  createSkedFixedSiteDrive');
        List<Opportunity> lstOfNonCalendarBuildOpps = new List<Opportunity>();
        for(Opportunity opp : newOpportunityList) {
            //Means that it's not a calendar build opportunity and it's a fixed site opportunity
            if(opp.Calendar_Build_Parent_Opportunity__c == null && opp.RecordTypeId == FIXED_SITE_OPP_RECTYPEID) {
                lstOfNonCalendarBuildOpps.add(opp);
            }
        }
        
        if(lstOfNonCalendarBuildOpps != null && lstOfNonCalendarBuildOpps.size() > 0) {
            //Call either the Skedulo or Exavalu class to create 'drives on calendar' records for each cloned opportunity
            CreateSkedDrivesBatch batchOppRecs = new CreateSkedDrivesBatch(lstOfNonCalendarBuildOpps);
            Database.executeBatch(batchOppRecs, 1);
            
            /*
Drive_Generator_Selector__mdt mdtDriveGeneratorSelector = Drive_Generator_Selector__mdt.getInstance('Active_Setting');
String source = mdtDriveGeneratorSelector.Drive_Generator_To_Use__c;
if(source.toLowerCase() == 'skedulo') {
System.debug('###FWO:  createSkedFixedSiteDrive sked');
//Call batch class to create 'drives on calendar' records via trigger only for those Opps not created via calendar build
CreateSkedDrivesBatch batchOppRecs = new CreateSkedDrivesBatch(lstOfNonCalendarBuildOpps);
Database.executeBatch(batchOppRecs, 1);
}
else if (source.toLowerCase() == 'exavalu') {
System.debug('###FWO:  createSkedFixedSiteDrive exa');
DriveGeneratorService.generateDrivesOnOppInsert(lstOfNonCalendarBuildOpps);
System.debug('--> \n Exavalu call to generate drives is done. '); 
} */
        }
    }
    
    //HRP-6696
    public static void checkForSiteChangeOnOpportunity(list<Opportunity> oppNewList, map<Id, Opportunity> oppOldMap) {
        System.debug('### inside checkForSiteChangeOnOpportunity');
        for (Opportunity opp : oppNewList) {
            //check if the parent template Id has changed
            if(oppOldMap.containsKey(opp.Id) && oppOldMap.get(opp.Id).Parent_Template_Id__c != null && opp.Parent_Template_Id__c != null && 
               oppOldMap.get(opp.Id).Parent_Template_Id__c != opp.Parent_Template_Id__c &&
               oppOldMap.get(opp.Id).Parent_Template_Site__c != opp.Parent_Template_Site__c &&
               opp.Drive_Date__c != null && 
               system.today().daysBetween(opp.Drive_Date__c) <= 14 &&
               opp.Drive_Status__c == 'Confirmed'){
                   opp.addError('Site change within 2 Weeks requires cancellation or rebook.') ;
               }
        }  
    }
    
    //HRP-10515- Takes list of Drives on Calendar and returns Map with opp Id as key
    public static Map<Id, sked_Drive__c> getDocOppMap(List<sked_Drive__c> docList){
        
        Map<Id, sked_Drive__c> docOppMap = new Map<Id, sked_Drive__c>();
        if(docList !=null && docList.size()>0){
            
            for(sked_Drive__c doc:docList){
                docOppMap.put(doc.sked_Opportunity__c,doc);
            }
        }
        return docOppMap;
    }
    
    
    
    //HRP-6908
    public static void syncOppsWithDrives(List<Opportunity> lstOpps)
    {

        try{
            //HRP-10514 : added Platelet_Projected_Procedures__c for 'DriveSync' issue.
            Map<Id, Opportunity> mapOfOpportunity = new Map<Id, Opportunity>([SELECT Id, Drive_Status__c,Drive_Date_Change_Reason__c, Initiated_By__c, StageName,Platelet_Projected_Procedures__c,Plasma_Pheresis_Projected_Procedures__c, Anticipated_Registered_Donors__c, 
                                                                              WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Accepts_Automation__c, Automation_Suitability__c, APT_Quantity__c, APT_Required__c, APT_Change_Reason__c FROM Opportunity WHERE Id In :lstOpps]);//HRP-12063
            //HRP-10515-Query latest values on DOC for changed fields and update on Opportunity, when request comes from DOC update
            List<sked_Drive__c> docList = [select sked_Drive_Date__c,sked_Status__c,sked_Start_Time__c,sked_End_Time__c,sked_Drive_Site__c,sked_Replacement_Drive__c,sked_Projected_Registered_Donors__c,sked_WB_Projected_Procedures__c,sked_2RBC_Projected_Procedures__c,sked_Platelet_Projected_Procedures__c,sked_Plasma_Projected_Procedures__c,sked_Number_of_2RBC_Assets__c,
                                           sked_Number_of_Plasma_Assets__c,sked_Number_of_Platelet_Assets__c,sked_Cancellation_Reason__c,sked_Opportunity__c,
                                           sked_APT_Required__c, sked_APT_Quantity__c from sked_Drive__c 
                                           where sked_Opportunity__c in : lstOpps and sked_Is_Surrogate__c = false];
            if(Test.isRunningTest()){
                sked_Drive__c skedDr =  new sked_Drive__c(sked_Opportunity__c=lstOpps.get(0).id,sked_WB_Projected_Procedures__c=2,sked_Status__c='Draft',sked_Drive_Date__c=system.today().addDays(55));
                List<sked_Drive__c> skedDrList = new List<sked_Drive__c>();
                skedDrList.add(skedDr);
                docList= skedDrList;
                
            }            
            Map<Id, sked_Drive__c> docOppMap   =  getDocOppMap(docList);  //HRP-10515     
            if (lstOpps <> null && lstOpps.size() > 0) {
                
                string valueToLog = Json.Serialize(lstOpps);
                system.debug('###FWO... valueToLog ' + valueToLog);
                BSF_Error_Log__c log = new BSF_Error_Log__c (
                    Process_Name__c = 'Sync Opps With Drives',
                    ApexClass__c = 'OpportunityService',
                    Method__c = 'syncOppsWithDrives',
                    Type__c = 'Debug Log',
                    Error_Description__c = 'Sync Request From DoC'
                );
                log.Error_Description_Long__c = valueToLog.length() > 2500 ? valueToLog.subString(0,2500) : valueToLog;
                insert log;
                
                //Prepare data for the update event container
                List<FieldIdentifiers> oppFieldsList = new List<FieldIdentifiers>();
                
                for (Opportunity oppRec : lstOpps) {      
                    Boolean arcUpdated = false;
                    Boolean wbcUpdated = false;
                    //Boolean pltUpdated = false;
                    Boolean doubleRbcUpdated = false;
                    Map<string, object> data = oppRec.getPopulatedFieldsAsMap();
                    system.debug('#### Inside syncOppsWithDrives. Data is => ' + data);
                    //FieldIdentifiers is a Apex Class named as :'FieldIdentifiers.apexc'
                    FieldIdentifiers oppField = new FieldIdentifiers();
                    oppField.OppId = oppRec.id;
                    for (String key : data.keySet()) {
                        oppField.updatedDataKeys.add(key);
                    }
                    sked_Drive__c doc = docOppMap.get(oppRec.Id);//HRP-10515
                    
                    //HRP-10515- begin-> Update with latest values on DOC 
                    //HRP-10312 -begin-> First check if the field came in as part of drive change request, only then process it
                    if(data.containsKey('Is_Recursion_On__c') == true && //HRP-10312
                       data.get('Is_Recursion_On__c') != null && oppRec.Is_Recursion_On__c != null) {
                           oppField.Is_Recursion_On = oppRec.Is_Recursion_On__c; //HRP-10515 -> this is not a DOC object field, populated directly on Opp from SkedDriveHandler
                       }
                    if(data.containsKey('Drive_Status__c') == true && //HRP-10312
                       data.get('Drive_Status__c') != null && string.isNotBlank(oppRec.Drive_Status__c)) {// oppRec.Drive_Status__c != null) {
                           oppField.Drive_Status = doc != null? doc.sked_Status__c : oppRec.Drive_Status__c;
                           System.debug('Updating Drive_Status  to->'+oppField.Drive_Status);   
                       }
                    if(data.containsKey('Drive_Date__c') == true && data.get('Drive_Date__c') != null && oppRec.Drive_Date__c != null) { //HRP-10312
                        oppField.Drive_Date = doc != null? doc.sked_Drive_Date__c : oppRec.Drive_Date__c; //HRP-12063
                        DateTime now = DateTime.now();//HRP-12063
                        String formattedDateTime = now.format('yyyy-MM-dd HH:mm:ss');//HRP-12063
                        oppField.driveDateChangeReason='Changed from DOC on '+formattedDateTime;//HRP-12063
                        //system.debug('check the reason and drive date '+oppField.driveDateChangeReason+'drive date '+oppField.Drive_Date+'opp rec '+oppRec.Drive_Date__c+'opp rec reason'+oppRec.Drive_Date_Change_Reason__c);
                    }
                    if(data.containsKey('Start_Time__c') == true && data.containsKey('Start_Time__c') == true && data.get('Start_Time__c') != null && oppRec.Start_Time__c != null) { //HRP-10312
                        oppField.Start_Time = OneTimeFlowTimeFieldUpdateBatch.getFlowTime(doc != null? doc.sked_Start_Time__c : oppRec.Start_Time__c);
                        system.debug('#### Inside syncOppsWithDrives. oppField.Start_Time => ' + oppField.Start_Time);
                    }
                    if(data.containsKey('End_Time__c') == true && data.get('End_Time__c') != null && oppRec.End_Time__c != null) { //HRP-10312                    
                        oppField.End_Time = OneTimeFlowTimeFieldUpdateBatch.getFlowTime(doc != null? doc.sked_End_Time__c : oppRec.End_Time__c);
                    }
                    
                    
                   system.debug('#### data.containsKey(Drive_Site__c) == true => ' + String.valueOf(data.containsKey('Drive_Site__c') == true));
                   system.debug('#### data.containsKey(Anticipated_Registered_Donors__c) == true => ' + String.valueOf(data.containsKey('Anticipated_Registered_Donors__c') == true));

                    if(data.containsKey('Drive_Site__c') == true && data.get('Drive_Site__c') != null && oppRec.Drive_Site__c != null) { //HRP-10312
                        oppField.Drive_Site = doc != null? doc.sked_Drive_Site__c : oppRec.Drive_Site__c;
                    }
                    if(data.containsKey('Anticipated_Registered_Donors__c') == true){ //HRP-10312 begin
                        arcupdated = true;//HRP-10312 
                        if(oppRec.Anticipated_Registered_Donors__c != null){
                            oppField.Anticipated_Registered_Donors = Integer.valueOf(oppRec.Anticipated_Registered_Donors__c);
                        }
                        //HRP-10312 Begin
                        else{
                            oppField.Anticipated_Registered_Donors = null;
                        }
                        //HRP-10312 end
                        
                    }
                    //HRP-10312 begin
                    if(data.containsKey('WB_Projected_Procedures__c') == true){
                        wbcUpdated = true;
                        //HRP-10312 end
                        if(oppRec.WB_Projected_Procedures__c != null){
                            oppField.WB_Projected_Procedures = Integer.valueOf(oppRec.WB_Projected_Procedures__c);
                        }//HRP-10312 begin
                        else{
                            oppField.WB_Projected_Procedures = null;
                        }
                        //HRP-10312 end
                    }
                    //HRP-10312 begin
                    if(data.containsKey('X2RBC_Projected_Procedures__c') == true){
                        doubleRbcUpdated = true; //HRP-10312 end
                        if(oppRec.X2RBC_Projected_Procedures__c != null){
                            oppField.X2RBC_Projected_Procedures = Integer.valueOf(oppRec.X2RBC_Projected_Procedures__c);
                        } //HRP-10312 begin
                        else{
                            oppField.X2RBC_Projected_Procedures = null;
                        }//HRP-10312 end
                    }
                    
                    if(data.containsKey('Apheresis_Projected_Units__c') == true){//HRP-10312 
                        if(data.get('Apheresis_Projected_Units__c') != null && oppRec.Apheresis_Projected_Units__c != null) {
                            oppField.Platelet_Projected = Integer.valueOf(oppRec.Apheresis_Projected_Units__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Platelet_Projected = null;
                        }//HRP-10312 end
                    }
                    
                    if(data.containsKey('Other_Projected_Units__c') == true){//HRP-10312
                        if(data.get('Other_Projected_Units__c') != null && oppRec.Other_Projected_Units__c != null) {
                            //TODO prod has this as ->  oppField.Plasma_Pheresis_Projected = Integer.valueOf(oppRec.Other_Projected_Units__c);
                            oppField.Plasma_Pheresis_Projected = Integer.valueOf(oppRec.Other_Projected_Units__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Plasma_Pheresis_Projected = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Number_of_2RBC_Assets__c') == true){//HRP-10312
                        if(data.get('Number_of_2RBC_Assets__c') != null && oppRec.Number_of_2RBC_Assets__c != null) {
                            oppField.Number_of_2RBC_Assets = Integer.valueOf(oppRec.Number_of_2RBC_Assets__c);
                        }//HRP-10312 begin 
                        else{
                            oppField.Number_of_2RBC_Assets = null;
                        }
                        //HRP-10312 end
                    }
                    if(data.containsKey('Number_of_Plasma_Assets__c') == true){//HRP-10312 
                        
                        if(data.get('Number_of_Plasma_Assets__c') != null && oppRec.Number_of_Plasma_Assets__c != null) {
                            oppField.Number_of_Plasma_Assets = Integer.valueOf(oppRec.Number_of_Plasma_Assets__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Number_of_Plasma_Assets = null; 
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Number_of_Platelet_Assets__c') == true){//HRP-10312 begin
                        if(data.get('Number_of_Platelet_Assets__c') != null && oppRec.Number_of_Platelet_Assets__c != null) {  
                            oppField.Number_of_Platelet_Assets = Integer.valueOf(oppRec.Number_of_Platelet_Assets__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Number_of_Platelet_Assets = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Anticipated_Registered_Donors_Template__c') == true){//HRP-10312 begin
                        if(data.get('Anticipated_Registered_Donors_Template__c') != null && oppRec.Anticipated_Registered_Donors_Template__c != null) {  
                            oppField.Anticipated_Registered_Donors_Template = Integer.valueOf(oppRec.Anticipated_Registered_Donors_Template__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Anticipated_Registered_Donors_Template = null;
                        }//HRP-10312 end
                    }  
                    
                    
                    //HRP-10514 Start->>
                    if(data.containsKey('Platelet_Projected_Procedures__c') == true){//HRP-10312 
                        if(data.get('Platelet_Projected_Procedures__c') != null && oppRec.Platelet_Projected_Procedures__c != null) {  
                            oppField.Platelet_Projected_Procedure = Integer.valueOf(oppRec.Platelet_Projected_Procedures__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Platelet_Projected_Procedure = null;
                        }//HRP-10312 end
                    } 
                    //HRP-10514 <<-End
                    //HRP-10659 Start ->>
                    if(data.containsKey('Plasma_Pheresis_Projected_Procedures__c') == true){//HRP-10312 
                        if(data.get('Plasma_Pheresis_Projected_Procedures__c') != null && oppRec.Plasma_Pheresis_Projected_Procedures__c != null) {  
                            oppField.Plasma_Pheresis_Projected_Procedure = Integer.valueOf(oppRec.Plasma_Pheresis_Projected_Procedures__c);
                        }
                        else{
                            oppField.Plasma_Pheresis_Projected_Procedure = null;
                        }
                    } 

                    // HRP-12011 --> Starts Here
                    if(data.containsKey('Slot_Generator__c') == true) {
                        if(data.get('Slot_Generator__c') != NULL && oppRec.Slot_Generator__c != NULL) {  
                            oppField.Slot_Generator = (Decimal)oppRec.Slot_Generator__c;
                        }
                        else{
                            oppField.Slot_Generator = NULL;
                        }
                    }
                    if(data.containsKey('Slot_Generator_Change_Reason__c') == true) {
                        if(data.get('Slot_Generator_Change_Reason__c') != NULL && oppRec.Slot_Generator_Change_Reason__c != NULL) {
                            oppField.Slot_Generator_Change_Reason = oppRec.Slot_Generator_Change_Reason__c;
                        }
                        else{
                            oppField.Slot_Generator_Change_Reason = NULL;
                        }
                    }
                    // HRP-12011 --> Ends Here
                     
                    //HRP-13190 --> Starts Here
                    if(data.containsKey('APT_Required__c') == true) {
                        oppField.APT_Required = oppRec.APT_Required__c;
                    }
                    if(data.containsKey('APT_Quantity__c') == true) {
                        oppField.APT_Quantity = (Decimal)oppRec.APT_Quantity__c;
                    }
                    if(data.containsKey('APT_Change_Reason__c') == true) {
                        oppField.APT_Change_Reason = oppRec.APT_Change_Reason__c;
                    }
                    //HRP-13190 --> Ends Here

                    //HRP-10659 <<-End
                    if(data.containsKey('Drive_Date_Change_Reason__c') == true){//HRP-10312 begin
                        if(data.get('Drive_Date_Change_Reason__c') != null && oppRec.Drive_Date_Change_Reason__c != null) {
                            oppField.driveDateChangeReason = oppRec.Drive_Date_Change_Reason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.driveDateChangeReason = null;
                        }//HRP-10312 end
                    }
                    
                    if(data.containsKey('AnticipatedRegisterDonorChangeReason__c') == true){//HRP-10312 begin
                        if(data.get('AnticipatedRegisterDonorChangeReason__c') != null && oppRec.AnticipatedRegisterDonorChangeReason__c != null && arcUpdated == true) {
                            oppField.AnticipatedRegisterDonorChangeReason = oppRec.AnticipatedRegisterDonorChangeReason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.AnticipatedRegisterDonorChangeReason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('WholeBloodProcedureProjectedChangeReason__c') == true){//HRP-10312 
                        if(data.get('WholeBloodProcedureProjectedChangeReason__c') != null && oppRec.WholeBloodProcedureProjectedChangeReason__c != null && wbcUpdated == true) {
                            oppField.WholeBloodProcedureProjectedChangeReason = oppRec.WholeBloodProcedureProjectedChangeReason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.WholeBloodProcedureProjectedChangeReason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('DoubleRedProceduresProjectedChangeReason__c') == true){ //HRP-10312 
                        if(data.get('DoubleRedProceduresProjectedChangeReason__c') != null && oppRec.DoubleRedProceduresProjectedChangeReason__c != null && doubleRbcUpdated == true) {
                            oppField.DoubleRedProceduresProjectedChangeReason = oppRec.DoubleRedProceduresProjectedChangeReason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.DoubleRedProceduresProjectedChangeReason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Account_Manager__c') == true){//HRP-10312 
                        if(data.get('Account_Manager__c') != null && oppRec.Account_Manager__c != null) {
                            oppField.Account_Manager = oppRec.Account_Manager__c;
                        }//HRP-10312 begin
                        else{
                            oppField.Account_Manager = null;
                        } //HRP-10312 end
                    }
                    if(data.containsKey('Parent_Template_Id__c') == true){ //HRP-10312 //HRP-12479
                        if(data.get('Parent_Template_Id__c') != null && oppRec.Parent_Template_Id__c != null) {
                            oppField.Parent_Template_Id = oppRec.Parent_Template_Id__c;
                        }//HRP-10312 begin 
                        else{
                            oppField.Parent_Template_Id = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('sked_Cancellation_Reason__c') == true){//HRP-10312 
                        if(data.get('sked_Cancellation_Reason__c') != null && oppRec.sked_Cancellation_Reason__c != null && doc.sked_Cancellation_Reason__c != oppField.sked_Cancellation_Reason) {
                            oppField.sked_Cancellation_Reason = doc != null? doc.sked_Cancellation_Reason__c : oppRec.sked_Cancellation_Reason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.sked_Cancellation_Reason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Initiated_By__c') == true){//HRP-10312 
                        if(data.get('Initiated_By__c') != null && oppRec.Initiated_By__c != null && oppField.Initiated_By != oppRec.Initiated_By__c) {
                            oppField.Initiated_By = oppRec.Initiated_By__c;
                        }//HRP-10312 begin 
                        else{
                            oppField.Initiated_By = null;
                        }//HRP-10312 end
                    }
                    else {
                        //Since at the moment, DOC isn't sending us the value for initiated_by, we are making sure to maintain the current value
                        if(mapOfOpportunity.ContainsKey(oppRec.Id) && mapOfOpportunity.get(oppRec.Id).Initiated_By__c != null) {
                            oppField.Initiated_By = mapOfOpportunity.get(oppRec.Id).Initiated_By__c;
                            oppField.updatedDataKeys.add('Initiated_By__c');
                        }
                    }
                    
                    
                    //if(data.get('Enable_APH_Web_Scheduling__c') != null && oppRec.Enable_APH_Web_Scheduling__c != null) {
                    //    oppField.Enable_APH_Web_Scheduling = oppRec.Enable_APH_Web_Scheduling__c;
                    //}
                    
                    if(data.containsKey('Drive_Status__c') == true && data.get('Drive_Status__c') != null && oppRec.Drive_Status__c != null &&
                       mapOfOpportunity != null && mapOfOpportunity.ContainsKey(oppRec.Id)) {//HRP-10312 
                           
                           String latestDriveStatus = doc != null? doc.sked_Status__c : oppRec.Drive_Status__c;
                           if(latestDriveStatus == 'Cancel' && mapOfOpportunity.get(oppRec.Id).StageName != 'Cancelled') {
                               oppField.StageName = 'Cancelled';
                               oppField.updatedDataKeys.add('StageName');
                           }
                           if(latestDriveStatus == 'Tentative' && mapOfOpportunity.get(oppRec.Id).StageName != 'Committed') {
                               oppField.StageName = 'Committed';
                               oppField.updatedDataKeys.add('StageName');
                               if(mapOfOpportunity.get(oppRec.Id).Initiated_By__c != null) {
                                   oppField.Sked_Cancellation_Reason = '';
                                   oppField.Initiated_By = '';
                                   oppField.updatedDataKeys.add('Initiated_By__c');    
                                   oppField.updatedDataKeys.add('sked_Cancellation_Reason__c');
                               }
                           }
                           if(latestDriveStatus == 'Confirmed' && mapOfOpportunity.get(oppRec.Id).StageName != 'Closed') {
                               oppField.StageName = 'Closed';
                               oppField.updatedDataKeys.add('StageName');
                               if(mapOfOpportunity.get(oppRec.Id).Initiated_By__c != null) {
                                   oppField.Sked_Cancellation_Reason = '';
                                   oppField.Initiated_By = '';
                                   oppField.updatedDataKeys.add('Initiated_By__c');    
                                   oppField.updatedDataKeys.add('sked_Cancellation_Reason__c');
                               }
                           }
                           if((mapOfOpportunity.get(oppRec.Id).Drive_Status__c == 'Draft' && latestDriveStatus == 'Hold') || 
                              (mapOfOpportunity.get(oppRec.Id).Drive_Status__c == 'Hold' && latestDriveStatus == 'Draft')) {
                                  //if((oppRec.Drive_Status__c == 'Draft' || oppRec.Drive_Status__c == 'Hold') && mapOfOpportunity.get(oppRec.Id).StageName != 'Solicitation') {
                                  oppField.StageName = 'Solicitation';
                                  oppField.updatedDataKeys.add('StageName');
                              }
                       }
                    
                    oppFieldsList.add(oppField);
                }
                //HRP-10312 -End
                UpdateEvent driveUpdateEvent = new UpdateEvent();
                driveUpdateEvent.objectName = 'Opportunity';
                driveUpdateEvent.objectFields = oppFieldsList;
                String objectDataJSON = JSON.serialize(driveUpdateEvent);
                
                //Prepare platform event to publish
                List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 
                Update_Event__e event = new Update_Event__e(
                    Object_Data__c = objectDataJSON
                );
                updateEventList.add(event);
                
                System.debug('\n #### Inside syncOppsWithDrives JSON =>' + objectDataJSON);
                
                //Publish Event
                if(!updateEventList.isEmpty()) {
                    List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);
                    
                    for(Database.SaveResult eventPubResult : eventPubResultList) {
                        if(eventPubResult.isSuccess()) {
                            System.debug('\n #### Inside syncOppsWithDrives Events published successfully  => ' + eventPubResult);
                        }
                        else {
                            for(Database.Error pubError : eventPubResult.getErrors()) {
                                System.debug('\n #### Inside syncOppsWithDrives Event publishing failed => ' + pubError.getStatusCode() + ' => ' + pubError.getMessage());
                            }
                        }
                    }
                }            
            } 
        }catch(Exception ex){
            System.debug('#### Inside ex  => ' + ex);
        }
        
    }
    
    public static void deleteDriveAffiliationOnDriveDateChange (List<Opportunity> newItems,Map<Id, Opportunity> oldMap,Map<Id, Opportunity> newMap )
    {
        List<id> oppId = new List<id>();
        map<id,Opportunity> driveDateChangedOpp = new map<id,Opportunity>();
        List<Drive_Marketing_Programs__c> d_affiliationToDel = new List<Drive_Marketing_Programs__c>();
        
        for(opportunity opp : newItems)
        {
            if(oldMap.get(opp.id).drive_Date__c != newMap.get(opp.id).drive_Date__c)
            {
                oppId.add(opp.Id);
                driveDateChangedOpp.put(opp.id,opp);
            }
        }
        
        List<Drive_Marketing_Programs__c> d_affiliationExist = [select id,Marketing_Program__c,Marketing_Program__r.Booking_Start_Date__c,Marketing_Program__r.Booking_End_Date__c,Blood_Drive_Opportunity__c from Drive_Marketing_Programs__c where Blood_Drive_Opportunity__c IN :oppId ];
        for(Drive_Marketing_Programs__c dAff : d_affiliationExist)
        {
            Date bookingStart = dAff.Marketing_Program__r.Booking_Start_Date__c;
            Date bookingEnd   = dAff.Marketing_Program__r.Booking_End_Date__c;
            Date driveDate    = driveDateChangedOpp.get(dAff.Blood_Drive_Opportunity__c).drive_Date__c;
            if(!(driveDate >= bookingStart && driveDate <= bookingEnd))
            {
                d_affiliationToDel.add(dAff);
            }
        }
        
        if(!d_affiliationToDel.isEmpty())
        {
            Database.DeleteResult[] srList = Database.delete (d_affiliationToDel,false);
            
            for (Database.DeleteResult sr : srList) 
            {
                if (sr.isSuccess()) 
                {
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else 
                {        
                    for(Database.Error err : sr.getErrors()) 
                    {System.debug('The Error in deleting the DriveAffiliations is : '+err.getStatusCode() + ': ' + err.getMessage());}
                }
            }
        }
    }
    
    //HRP-6908
    public static Set<Id> checkForOppStageChange(list<Opportunity> oppNewList, map<Id, Opportunity> oppOldMap) {
        System.debug('### inside checkForOppStageChange ' + ' >>> ' + userInfo.getName());
        Set<Id> invalidStageOppIds = new Set<Id>();   
        Map<Id, sked_Drive__c> mapOppToDriveId = new Map<Id, sked_Drive__c>();
        string profileName;
        String runningUser = UserInfo.getName();
        if(runningUser != Label.OpportunityStageAllowedRunningUser) {
            profileName = [SELECT Id, Name FROM Profile WHERE Id =:UserInfo.getProfileId()].Name ;    
        }
        
        //Create a set of Opportunity Ids
        Set<Id> setOppIds = new Set<Id>();
        for(Opportunity newOpp : oppNewList) {
            setOppIds.add(newOpp.Id);
        }        
        
        //Create a map of opportunity -> drives on calendar
        for (sked_Drive__c driveRec : [SELECT Id, sked_Opportunity__c,sked_Status__c FROM sked_Drive__c WHERE sked_Is_Surrogate__c = false and sked_Opportunity__c IN :setOppIds]) {
            //HRP-11393
            if(mapOppToDriveId.containsKey(driveRec.sked_Opportunity__c) == true && driveRec.sked_Status__c != 'Cancel'){ //for second time, if first time we picked cancelled status, replace it with correct drive
                 mapOppToDriveId.put(driveRec.sked_Opportunity__c, driveRec);
            }
            if(mapOppToDriveId.containsKey(driveRec.sked_Opportunity__c) == false){
               mapOppToDriveId.put(driveRec.sked_Opportunity__c, driveRec); //for first time, insert first drive matching opp
            }        
       }
        
        for (Opportunity opp : oppNewList) {
            //check if the parent template Id has changed
            if(oppOldMap.containsKey(opp.Id) && oppOldMap.get(opp.Id).StageName != null && opp.StageName != null && oppOldMap.get(opp.Id).StageName != opp.StageName) { 
                string priorStageName = oppOldMap.get(opp.Id).StageName;
                string newStageName = opp.StageName;
                if (((newStageName == 'Committed' || newStageName == 'Closed') ||
                     (oppOldMap.get(opp.Id).Drive_Status__c != opp.Drive_Status__c && opp.Drive_Status__c == 'Confirmed')) &&
                    !(mapOppToDriveId.containsKey(opp.Id))) {
                        //opp.addError('Opportunity without a drive record cannot have a committed stage, closed stage, or confirmed drive status.') ;
                        invalidStageOppIds.add(opp.Id);
                    }
                //HRP-10959- Perform check for valid stage transitions
                //start replacement of validation rule "CannotMoveBackOnStagesThatAreCompleted" (HRP-9899)
                Opportunity_Stage_Check__mdt stageChecksForCurrentStage = Opportunity_Stage_Check__mdt.getInstance(priorStageName);


                if(stageChecksForCurrentStage != null && stageChecksForCurrentStage.Next_Stages_allowed__c!= null 
                   && (!(String.isBlank(profileName))&&((stageChecksForCurrentStage.Overriding_Profiles__c).contains(profileName) == false)) // HRP-11299
                   && (stageChecksForCurrentStage.Overriding_user__c).contains(runningUser) == false
                   && (stageChecksForCurrentStage.Next_Stages_allowed__c).contains(newStageName) ==false 
                  ){
                      opp.addError(Label.OpportunityStageErrorMessagee);
                      invalidStageOppIds.add(opp.Id);
                  }
            }
        } 
        return invalidStageOppIds;
    }
    
    //HRP-7103.
    public static void updateOppStage(list<Opportunity> oppNewList, map<Id, Opportunity> oppOldMap) {
        System.debug('### inside updateOppStage');
        
        for (Opportunity opp : oppNewList) {
            //if(opp.Is_Template__c == false && opp.Initiated_By__c != null && opp.sked_Cancellation_Reason__c != null && opp.StageName != 'Cancelled') {
            //       opp.StageName = 'Cancelled';
            //}
            
            if((opp.Is_Template__c == false && opp.Initiated_By__c != null && opp.sked_Cancellation_Reason__c != null) && 
               (oppOldMap != null && oppOldMap.containsKey(opp.Id) && oppOldMap.get(opp.Id).StageName != 'Cancelled')) {
                   opp.StageName = 'Cancelled';
               }
            
            /* The rest are updated by the platform event 
if(opp.Is_Template__c == false && opp.Drive_Status__c == 'Cancel'){
opp.StageName = 'Cancelled';
}
if(oppOldMap != null && !oppOldMap.isEmpty()) {
if(oppOldMap.containsKey(opp.Id) && oppOldMap.get(opp.Id).Drive_Status__c != null && 
(oppOldMap.get(opp.Id).Drive_Status__c == 'Draft' && opp.Drive_Status__c != null && opp.Drive_Status__c == 'Hold') ||
(oppOldMap.get(opp.Id).Drive_Status__c == 'Hold' && opp.Drive_Status__c != null && opp.Drive_Status__c == 'Draft')) 
{
opp.StageName = 'Solicitation';
}
}
if(opp.Is_Template__c == false && opp.Drive_Status__c == 'Tentative'){
opp.StageName = 'Committed';
}
if(opp.Is_Template__c == false && opp.Drive_Status__c == 'Confirmed'){
opp.StageName = 'Closed';
}*/
        } 
    }
    
    Public Static void UpdateOwnerSplit(list<Opportunity> oppNewList)
    {
        map<id,Opportunity> oppIdOppMap = new map<id,Opportunity>();
        for(Opportunity opp:oppNewList)
        {
            oppIdOppMap.put(opp.id,opp);
        }
        OpportunitySplitType revenueSplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName='Revenue' ];
        List<OpportunitySplit> oppSplitList = [Select Id,OpportunityId,Is_Covering_Incentive__c,SplitOwnerId,SplitTypeId,SplitPercentage,BSF_Portfolio__c from OpportunitySplit where OpportunityId IN :oppIdOppMap.keySet() and SplitTypeId = :revenueSplitType.id order by createdDate Desc];
        System.debug('oppSplitList: '+ oppSplitList);
        map<id,List<OpportunitySplit>> oppIdSplitMap = new map<id,List<OpportunitySplit>>();
        for (OpportunitySplit oppSplit : oppSplitList)
        {
            if(!oppIdSplitMap.containsKey(oppSplit.OpportunityId))
            {
                List<opportunitySplit> newSplitList = new List<opportunitySplit>();
                newSplitList.add(oppSplit);
                oppIdSplitMap.put(oppSplit.OpportunityId,newSplitList);
            }
            else
            {
                List<opportunitySplit> newSplitList = oppIdSplitMap.get(oppSplit.OpportunityId);
                newSplitList.add(oppSplit);
                oppIdSplitMap.put(oppSplit.OpportunityId,newSplitList);
            }
        }
        
        List<OpportunitySplit> updatedSplitList = new List<OpportunitySplit>();
        for(Opportunity opp : oppIdOppMap.values())
        {
            if(!oppIdSplitMap.containsKey(opp.id)){ //Changes regarding HRP:9120//
                continue;
            }
            if (oppIdSplitMap.containsKey(opp.id)) //Changes regarding HRP:9120//
            {
                for (OpportunitySplit oppSplit : oppIdSplitMap.get(opp.id))
                {
                    if(opp.ownerId == oppSplit.SplitOwnerId && oppSplit.SplitPercentage != 100)
                    {
                        oppSplit.SplitPercentage = 100;
                        updatedSplitList.add(oppSplit);
                    }
                    if(opp.ownerId != oppSplit.SplitOwnerId && oppSplit.SplitPercentage == 100)
                    {
                        oppSplit.SplitPercentage = 0;
                        updatedSplitList.add(oppSplit);
                    }
                }
            }
        }
        system.debug('updatedSplitList: '+updatedSplitList);
        if(!updatedSplitList.isEmpty())
        {
            OpportunitySplitService.addTeamMemberPortfolio(updatedSplitList);
            OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
            Database.SaveResult[] srList = Database.update(updatedSplitList,false);
            OpportunitySplitRecursive.isOppotysplitBackEndUpdated = false;
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    Public static void closedOpportunity72HourTaskCreation(list<Opportunity> oppNewList, map<Id, Opportunity> oppOldMap)
    {
        
        set<id> oppIds = new set<id>();
        for (Opportunity opp : oppNewList) {
            if(opp.Is_Template__c == true){ //if its template, don't bother further checks
                continue;
            }
            oppIds.add(opp.Id);
        }
        List<task> taskListInsert = new List<task>();
        Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('72 Hour Check In').getRecordTypeId();
        //part of ticket HRP-9562***starts here***
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppIds
                                                                ];
        
        
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
        for (OpportunityTeamMember oppteamem : allOpportunityTeamMembers) {
            if (!oppTeamMembersMap.containsKey(oppteamem.OpportunityId)) {
                oppTeamMembersMap.put(oppteamem.OpportunityId, new List<OpportunityTeamMember>());
            }
            oppTeamMembersMap.get(oppteamem.OpportunityId).add(oppteamem);
        }
        //part of ticket HRP-9562***ends here***
        //HRP-12627 changes starts
        Map<Id,Boolean> checkOppHas72hourTask = new  Map<Id,Boolean>();
        if(!oppIds.isEmpty()){
            List<Task> taskList = [SELECT Id, 
                                        WhatId, 
                                        Subject 
                                    FROM Task 
                                    WHERE Subject =: Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Task_Subject__c
                                    AND WhatId IN :oppIds];
            for(Task t : taskList){
                checkOppHas72hourTask.put(t.WhatId,true);
            }
        }
        Integer creationDateOffset= Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Creation_Date_Offset__c != null 
                                    ? Integer.valueOf(Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Creation_Date_Offset__c)
                                    : 0;
        //HRP-12627 changes ends
        for(opportunity opp: oppNewList)
        {
            //only creating the task for mobile opps (HRP-7781)
            if (opp.RecordTypeId == MOBILE_OPP_RECTYPEID && !opp.StageName.equalsIgnoreCase('Cancelled')) {//Changes for HRP-13850
                if(opp.Is_Template__c == false && opp.Drive_Date__c != NULL && opp.Drive_Date__c <= Date.Today().addDays(creationDateOffset) && opp.Drive_Date__c >= Date.Today() //HRP-12627
                    && (checkOppHas72hourTask.isEmpty() || !checkOppHas72hourTask.containsKey(opp.Id) || !checkOppHas72hourTask.get(opp.Id)))//HRP-12627
                {
                    Task newTask = new task();
                    newTask.RecordTypeId = recTypeId;
                    newTask.subject =Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Task_Subject__c;//HRP-12627
                    newTask.ActivityDate = Helper.AddBusinessDays(opp.Drive_Date__c,-3);
                    newTask.Drive_Date__c = opp.Drive_Date__c; //HRP-12700
                    newTask.WhatId = opp.id;
                    newTask.OwnerId =getTaskOwner(opp, oppTeamMembersMap,Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Assigned_To__c);//part of ticket HRP-9562;//HRP-12333 added 3rd paarameter
                    taskListInsert.add(newTask);
                }
            }
        }
        if (taskListInsert.size() > 0) {
            Database.SaveResult[] srList = Database.insert(taskListInsert, false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }   
    }
    
    public static void updateDoubleRedProcedures(List<Opportunity> listOfnewOppties, Map<Id, Opportunity> mapOfOfOldOppties) { 
        Id mobileRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId();
        
        for(Opportunity oppRecord : listOfnewOppties){    
            if(oppRecord.RecordTypeId == mobileRecTypeId && oppRecord.Is_Template__c == false && 
               (oppRecord.Accepts_Automation__c =='No' || oppRecord.Automation_Suitability__c =='Unsuitable')){
                   oppRecord.X2RBC_Projected_Procedures__c = 0;
               }
        }
    }
    
    //HRP-7422
    public static void primaryDriveContactRequired(Map<Id,Opportunity> OppIdMap,Map<Id,Opportunity> oppOldList){
        
        list<Id> oppId=new List<Id>(); 
        for(Opportunity opp:OppIdMap.values()){
            if(opp.Type_of_Drive__c !='Fixed Site'){
                system.debug('comes here opp.Type_of_Drive__c '+opp.Type_of_Drive__c);
                if(oppOldList.get(opp.Id).StageName!='closed' && oppOldList.get(opp.Id).Type_of_Drive__c !='Fixed Site' && Opp.StageName=='closed'){
                    system.debug('comes here 2opp.Type_of_Drive__c '+opp.Type_of_Drive__c);
                    oppId.add(opp.Id);   
                } 
            }
        }
        if(!oppId.isEmpty()){
            List<Opportunity>  oppList=[SELECT Id, Name,StageName,Type_of_Drive__c,(SELECT Contact.Name,OpportunityId,Contact.Email,Contact.Primary_Phone_Number_New__c,Role,Contact.Id,ContactId FROM OpportunityContactRoles) FROM Opportunity where Id In:oppId];
            system.debug('oppList'+oppList+' '+oppList.size());
            Map<Id,Opportunity> finalMap=new Map<Id,Opportunity>();
            for(opportunity opp:oppList){
                boolean isPrimary=false;
                for(OpportunityContactRole ocr:opp.OpportunityContactRoles){
                    if( ocr.Role!=null && ocr.Role!='' && ocr.Role.contains('Primary Contact')){
                        finalMap.put(opp.Id,opp);
                        isPrimary=true;
                        break;
                    }
                    
                }
                if(!isPrimary && OppIdMap.keyset().contains(opp.Id) && OppIdMap.get(opp.Id).Type_of_Drive__c !='Fixed Site' ){
                    system.debug('comes here  3opp.Type_of_Drive__c '+opp.Type_of_Drive__c);
                    OppIdMap.get(opp.Id).addError('Primary Drive Contact required.  Add contact with drive service role of Primary contact at the template and execute Apply to Future Drives process');   
                } 
            } 
        }
    }
    
    //HRP-7362
    public static void modifyTasksOnDriveDateChange(Map<Id,Opportunity>oldMap,list<Opportunity>newOpp,Map<Id,Opportunity>newMap)
    {
        
        set<id> oppId = new set<id>();
        map<id,id> OppIdSiteId = new map<id,id>();
        
        for(opportunity opp : newOpp)
        {
            if(oldMap.get(opp.id).drive_date__c != opp.drive_Date__c)
            {
                oppId.add(opp.id);
                if(opp.Drive_Site__c!=null)
                    OppIdSiteId.put(opp.id,opp.Drive_Site__c);
            }
        }
        
        list<task> oppTasks = [select id,subject,activityDate,whatId from task where whatId IN:oppId and (subject like 'Sponsor Planning Meeting%' or subject like 'Recruitment%' or subject like '72 Hour Check in%' or subject like 'Security Information%')];// Changes for HRP-7123
        system.debug('oppTasks'+oppTasks);
        Opportunity_Date_Setting__mdt mdtOppDateSetting = Opportunity_Date_Setting__mdt.getInstance('Sponsor_Planning_Meeting');
        Integer daysFromDriveDate = mdtOppDateSetting?.Days_from_Drive_Date__c.intValue();
        
        map<id,sked__Location__c> driveSite =new map<id,sked__Location__c>([select sked_Pre_Drive_Security_Due_Date__c from sked__Location__c where Id IN:OppIdSiteId.values()]);
        system.debug('driveSite '+driveSite);
        
        list<task> taskToUpdate = new list<task>();
        
        for(task t : oppTasks)
        {
            opportunity opp = new opportunity();
            opp=newMap.get(t.WhatId);
            if(t.subject.containsIgnoreCase('Sponsor Planning'))
            {
                t.ActivityDate=opp.Drive_Date__c.addDays(-daysFromDriveDate);
            }
            else if (t.subject.containsIgnoreCase('Recruitment Planning'))// Changes for HRP-7123
            {
                system.debug('Helper.AddBusinessDays'+Helper.AddBusinessDays(opp.Drive_Date__c, -50));
                t.ActivityDate = Helper.AddBusinessDays(opp.Drive_Date__c, -50);
            }
            else if(t.subject.containsIgnoreCase('72 Hour Check in'))
            {
                t.ActivityDate = Helper.AddBusinessDays(opp.Drive_Date__c,-3);
            }
            else if(t.subject.containsIgnoreCase('Security Information'))
            {
                
                system.debug(opp.drive_date__c+'___'+opp.Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c);
                t.ActivityDate = opp.drive_date__c - Integer.ValueOf(driveSite.get(OppIdSiteId.get(opp.id)).sked_Pre_Drive_Security_Due_Date__c);
                t.Pre_Drive_Security_Due_Date__c = driveSite.get(OppIdSiteId.get(opp.id)).sked_Pre_Drive_Security_Due_Date__c;
            }
            t.Drive_Date__c = opp.Drive_Date__c; //HRP-12700
            taskToUpdate.add(t);
        }
        
        if(!taskToUpdate.isEmpty())
        {
            Database.SaveResult[] srList = Database.Update(taskToUpdate,false);
            
        }
    }
    
    //Added as part of  HRP-8050
    //Drive owner populated in Drives on calendar
    public static void UpdateDriveOwnerOnOppOwnerUpdate(Map<Id,Id> oppWithOwnerIdMap,Map<Id,Id> oppWithAccMangrIdMap,Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap)
    {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418
        List<Sked_Drive__c> existingDrivesList = [Select id,sked_Drive_Owner__c,OwnerId,sked_Opportunity__c,Account_Manager__c,Account_Manager_Portfolio__c,District_Manager__c,District_Manager_Portfolio__c, sked_Opportunity__r.Account_Manager__c, sked_Opportunity__r.Account_Manager_Portfolio__c, sked_Opportunity__r.District_Manager__c, sked_Opportunity__r.District_Manager_Portfolio__c from Sked_Drive__c where sked_Opportunity__c IN:oppWithOwnerIdMap.keyset() OR sked_Opportunity__c IN:oppWithAccMangrIdMap.keyset() OR sked_Opportunity__c IN:oppIdVsAMDMPortfoliodMap.keyset()]; //HRP-10359 //HRP-11849 changes
        List<Sked_Drive__c> drivesOwnerAccmanUpdateList = new List<Sked_Drive__c>();
        Boolean isChanged;
        for(Sked_Drive__c drive:existingDrivesList) {
            isChanged = false;
            if(!oppWithOwnerIdMap.isEmpty() || !oppWithAccMangrIdMap.isEmpty()){//HRP-11849 changes
                if(oppWithOwnerIdMap.keyset().contains(drive.sked_Opportunity__c)
                   && oppWithOwnerIdMap.get(drive.sked_Opportunity__c)!=null && drive.OwnerId != oppWithOwnerIdMap.get(drive.sked_Opportunity__c))
                {
                    drive.OwnerId= oppWithOwnerIdMap.get(drive.sked_Opportunity__c);
                    isChanged=True;
                }     
                /*if(oppWithAccMangrIdMap.keyset().contains(drive.sked_Opportunity__c)) { //HRP-9815
                    drive.sked_Drive_Owner__c = drive.sked_Drive_Owner__c != oppWithAccMangrIdMap.get(drive.sked_Opportunity__c) ? oppWithAccMangrIdMap.get(drive.sked_Opportunity__c) : drive.sked_Drive_Owner__c; //HRP-10359
                    isChanged=True;
                }*/
            }
            //HRP-10359 start
            if((!oppIdVsAMDMPortfoliodMap.isEmpty())||(drive.Account_Manager__c == NULL || drive.Account_Manager_Portfolio__c == NULL || drive.District_Manager__c == NULL || drive.District_Manager_Portfolio__c == NULL) || ((drive.sked_Opportunity__r.Account_Manager__c == null)||(drive.Account_Manager__c != drive.sked_Opportunity__r.Account_Manager__c)) || ((drive.sked_Opportunity__r.Account_Manager_Portfolio__c == null)||(drive.Account_Manager_Portfolio__c != drive.sked_Opportunity__r.Account_Manager_Portfolio__c)) || ((drive.sked_Opportunity__r.District_Manager__c == null)||(drive.District_Manager__c != drive.sked_Opportunity__r.District_Manager__c)) || ((drive.sked_Opportunity__r.District_Manager_Portfolio__c == null)||(drive.District_Manager_Portfolio__c != drive.sked_Opportunity__r.District_Manager_Portfolio__c)) ){
                if(!oppIdVsAMDMPortfoliodMap.isEmpty()){
                    drive.Account_Manager__c= oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).Account_Manager__c == null ? null : oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).Account_Manager__c;
                    drive.Account_Manager_Portfolio__c= oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).Account_Manager_Portfolio__c == null ? null : oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).Account_Manager_Portfolio__c;
                    drive.District_Manager__c= oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).District_Manager__c == null ? null : oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).District_Manager__c;
                    drive.District_Manager_Portfolio__c= oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).District_Manager_Portfolio__c == null ? null : oppIdVsAMDMPortfoliodMap.get(drive.sked_Opportunity__c).District_Manager_Portfolio__c;
                    isChanged=True;
                } else if(oppIdVsAMDMPortfoliodMap.isEmpty()){
                    drive.Account_Manager__c= drive.sked_Opportunity__r.Account_Manager__c == null ? null : drive.sked_Opportunity__r.Account_Manager__c;
                    drive.Account_Manager_Portfolio__c= drive.sked_Opportunity__r.Account_Manager_Portfolio__c == null ? null : drive.sked_Opportunity__r.Account_Manager_Portfolio__c;
                    drive.District_Manager__c= drive.sked_Opportunity__r.District_Manager__c == null ? null : drive.sked_Opportunity__r.District_Manager__c;
                    drive.District_Manager_Portfolio__c= drive.sked_Opportunity__r.District_Manager_Portfolio__c == null ? null : drive.sked_Opportunity__r.District_Manager_Portfolio__c;
                    isChanged=True;
                }
            } //HRP-10359 end
            if(isChanged) {
                drive.sked_Drive_Owner__c = drive.Account_Manager__c;
                drivesOwnerAccmanUpdateList.add(drive);
            }    
        }
        
        if(!drivesOwnerAccmanUpdateList.isEmpty())
        {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
            Database.SaveResult[] srListDrive  = Database.Update(drivesOwnerAccmanUpdateList,false);
            for(Database.SaveResult sr : srListDrive) {
                if(sr.isSuccess()) {
                    System.debug('\n #### Events published successfully  => ' + sr);
                }
                else {
                    for(Database.Error er : sr.getErrors()) {
                        System.debug('\n #### Event publishing failed => ' + er.getStatusCode() + ' => ' + er.getMessage());
                    }  
                }
            }  
        }
    }
    
    public static void PublishEventForDriveServiceRole(List<Opportunity> lstNewOpps) {
        
        //Publish platform event to create the Drive Service Role record for each new opportunity based on the template
        List<CBDriveServicesRoleAssignmentEvent__e> dsrEvents = new List<CBDriveServicesRoleAssignmentEvent__e>();
        for(Opportunity newOpp : lstNewOpps) {
            CBDriveServicesRoleAssignmentEvent__e dsrEvent = new CBDriveServicesRoleAssignmentEvent__e();
            dsrEvent.OpportunityId__c = newOpp.Id;
            dsrEvents.add(dsrEvent);
        }
        if(dsrEvents.size() > 0) {
            System.debug('### before publishing drive service role event ' + dsrEvents.size());
            EventBus.publish(dsrEvents);
        }
    }
    
    Public static void AssignDriveSerivcesRoleForCBOpps(List<Opportunity> CBOpps) {
        
        Set<Id> templateIdSet = new Set<Id>();
        List<OpportunityContactRole> lstNewOppContactRole = new List<OpportunityContactRole>();
        
        For(Opportunity opp : CBOpps) {
            if(opp.Parent_Template_Id__c != null) {
                templateIdSet.add(opp.Parent_Template_Id__c);           
            }
        }
        
        List<OpportunityContactRole> lstOppContactRole = [SELECT Id, OpportunityId, ContactId, Role 
                                                          FROM OpportunityContactRole 
                                                          WHERE OpportunityId IN :templateIdSet];
        
        //Get the current opps contact role assignment
        List<OpportunityContactRole> lstCurrOppContactRole = [SELECT Id, OpportunityId, ContactId, Role 
                                                              FROM OpportunityContactRole 
                                                              WHERE OpportunityId IN :CBOpps];
        
        Map<Id, OpportunityContactRole> mapOcrOpp = new Map<Id, OpportunityContactRole>();
        For(OpportunityContactRole curOcr : lstCurrOppContactRole) {
            mapOcrOpp.put(curOcr.OpportunityId, curOcr);
        }
        
        For(Opportunity opp1 : CBOpps){
            For(OpportunityContactRole ocr : lstOppContactRole) {
                if(opp1.Parent_Template_Id__c == ocr.OpportunityId) {
                    OpportunityContactRole newOppContactRole = ocr.clone(false, true, false, false);
                    newOppContactRole.Migration_ID__c = null;
                    newOppContactRole.OpportunityId = opp1.Id;
                    if(!(mapOcrOpp != null && mapOcrOpp.containsKey(opp1.Id))) {
                        lstNewOppContactRole.add(newOppContactRole);   
                    }
                }
            }
        }
        insert lstNewOppContactRole;
    }
    
    //12/9 FWO - Method used to generate opportunity name (name field of non-template opportunities).  This is replacing the following workflow rules:
    //"Update Opportunity Name with No Site" and "Update Opportunity Name with Site Building"
    public static void GenerateOpportunityName(List<Opportunity> lstNewOpps, map<Id, Opportunity> oppOldTmpMap) {
        
        System.debug('### inside opportunity service GenerateOpportunityName');
        List<Opportunity> finalOppList = new List<Opportunity>();
         Map <String,Schema.RecordTypeInfo> recordTypesOpportunity = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesOpportunity.get('Mobile Opp').getRecordTypeId();
        //If initiated from account internal name change or new opp being created; quering opps again b/c read-only
        if(oppOldTmpMap == null) {
            List<Opportunity> lstLastestOpps = [SELECT Id, Name, Is_Template__c, Drive_Site__c, Account_Internal_Name__c, Site_Building_Name__c,Drive_Site_Name__c,account.name
                                                FROM Opportunity WHERE Id IN :lstNewOpps];//HRP-12136 added in query Drive_Site_Name__c
            
            finalOppList = checkOppNameChange(lstLastestOpps);
        }
        //If before update, then only check if template has changed
        else if(oppOldTmpMap != null) {
            Set<Id> oppsTemplateChangedIds = new Set<Id>();
            for(Opportunity opp : lstNewOpps){
                if(opp.Is_Template__c == false && ((opp.RecordTypeId==mobileRecTypeId && (oppOldTmpMap.get(opp.Id).Parent_Template_Id__c != Opp.Parent_Template_Id__c)) || (opp.RecordTypeId!=mobileRecTypeId &&(oppOldTmpMap.get(opp.Id).Drive_Site__c != Opp.Drive_Site__c)))){
                    oppsTemplateChangedIds.add(opp.Id);
                } 
            }
            if(!oppsTemplateChangedIds.isEmpty()) {
                List<Opportunity> lstLastestOpps = [SELECT Id, Name, Is_Template__c, Drive_Site__c, Account_Internal_Name__c, Site_Building_Name__c,Drive_Site_Name__c,account.name 
                                                    FROM Opportunity WHERE Id IN :oppsTemplateChangedIds];
                finalOppList = checkOppNameChange(lstLastestOpps);
            }
        }
        
        if(!system.isBatch() && !Test.isRunningTest() && !finalOppList.isEmpty()) {
            UpdateOpportunityNameBatch batchOppRecs = new UpdateOpportunityNameBatch(finalOppList, oppOldTmpMap);
            Database.executeBatch(batchOppRecs, 1);
        }
    }
    
    public static List<Opportunity> checkOppNameChange(List<Opportunity> incomingOppList) {
        
        List<Opportunity> finalOppList = new List<Opportunity>();
        
        for (opportunity opp : incomingOppList) {
            if(opp.Is_Template__c == false && opp.Drive_Site__c == null) {
                string tmpTbdOppName = opp.Account_Internal_Name__c + ', TBD';
                if(opp.Name != tmpTbdOppName) {
                    opp.Name =  opp.Account_Internal_Name__c + ', TBD';   
                    finalOppList.add(opp);
                }
            }                    
            else if (opp.Is_Template__c == false && opp.Drive_Site__c != null) {
                string tmpOppName = opp.account.name+', '+opp.Drive_Site_Name__c;// HRP-12136 prev -->opp.Account_Internal_Name__c + ', ' +  opp.Site_Building_Name__c
                tmpOppName = tmpOppName.length() > 80 ? tmpOppName.substring(0, 75) + ' ...' : tmpOppName;//HRP-12136
                //commented HRP-12136
                /*if(tmpOppName.length() > 120) {
                    tmpOppName = tmpOppName.substring(0,120);
                }
                */
                //commented HRP-12136
                if(opp.Name != tmpOppName) {
                    opp.Name = tmpOppName;
                    finalOppList.add(opp);
                }
            }
        }
        return finalOppList;
    }
    //HRP-9101
    public static void populateDriveWorksheetData(List<Opportunity> newItems)
    {
        
        
        Set<Id> oppIds = new Set<Id>();
        Map<Id,String> openToPublicMap = new Map<Id,String>();
        Map<Id,String> escrotNameMap = new Map<Id,String>();
        List<sked_Drive__c> drvUpdateList = new List<sked_Drive__c>();
        if(newItems != null){
            for (Opportunity opt : newItems) {
                oppIds.add(opt.Id);
                if(String.isNotBlank(opt.Open_to_Public__c)){
                    openToPublicMap.put(opt.Id,opt.Open_to_Public__c);
                }
                if(String.isNotBlank(opt.Security_Escort_Name__c)){
                    escrotNameMap.put(opt.Id,opt.Security_Escort_Name__c);
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
                if(!openToPublicMap.isEmpty() && openToPublicMap.containsKey(drv.sked_Opportunity__c)){
                    updateflag = true;
                    drvToBeUpdate.sked_Open_to_Public__c = openToPublicMap.get(drv.sked_Opportunity__c);
                }
                if(!escrotNameMap.isEmpty() && escrotNameMap.containsKey(drv.sked_Opportunity__c)){
                    updateflag = true;
                    drvToBeUpdate.sked_Security_Escort_Name__c = escrotNameMap.get(drv.sked_Opportunity__c);
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
    
    public static void populateRelatedFieldsOnDOC(List<Opportunity> oppList, Map<Id,Opportunity> oldOppMap)
    {
        Map<Id,String> openToPublicMap = new Map<Id,String>();
        Map<Id,String> escrotNameMap = new Map<Id,String>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Map<String,String>> oppFieldsRelatedToDOCMap = new Map<Id, Map<String,String>>();
        Map<String,String> relatedFieldsMap = new Map<String,String>();
        List<sked_Drive__c> driveListToBeUpdatedList = new List<sked_Drive__c>();
        Boolean updateFlag = FALSE;
        if(oppList == null || oldOppMap == NULL)
        {
            return;
        }
        for(Opportunity newOpp: oppList)
        {
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            if(oldOpp != NULL && oldOpp.Open_to_Public__c != newOpp.Open_to_Public__c)
            {
                relatedFieldsMap.put('sked_Open_to_Public__c', newOpp.Open_to_Public__c);
                //oppFieldsRelatedToDOCMap.put(newOpp.Id, relatedFieldsMap);
                //oppIds.add(newOpp.Id);
            }
            if(oldOpp != NULL && oldOpp.Security_Escort_Name__c != newOpp.Security_Escort_Name__c)
            {
                relatedFieldsMap.put('sked_Security_Escort_Name__c', newOpp.Security_Escort_Name__c);                
            }
            if(!relatedFieldsMap.isEmpty())
            {
                oppFieldsRelatedToDOCMap.put(newOpp.Id, relatedFieldsMap);
            }
            //count++;
        }
        
        if(!oppFieldsRelatedToDOCMap.isEmpty())
        {
            List<sked_Drive__c> drvList = [SELECT Id, 
                                           sked_Opportunity__c, sked_Security_Escort_Name__c, sked_Open_to_Public__c
                                           FROM sked_Drive__c 
                                           WHERE sked_Opportunity__c IN: oppFieldsRelatedToDOCMap.keySet()];
            if(drvList.size() > 0)
            {
                for(sked_Drive__c drive : drvList)
                {
                    if(oppFieldsRelatedToDOCMap.get(drive.sked_Opportunity__c).containsKey('sked_Open_to_Public__c'))
                    {
                        updateFlag = TRUE;
                        drive.sked_Open_to_Public__c = oppFieldsRelatedToDOCMap.get(drive.sked_Opportunity__c).get('sked_Open_to_Public__c');
                        system.debug(oppFieldsRelatedToDOCMap.get(drive.sked_Opportunity__c).get('sked_Open_to_Public__c'));
                    }
                    if(oppFieldsRelatedToDOCMap.get(drive.sked_Opportunity__c).containsKey('sked_Security_Escort_Name__c'))
                    {
                        updateFlag = TRUE;
                        drive.sked_Security_Escort_Name__c = oppFieldsRelatedToDOCMap.get(drive.sked_Opportunity__c).get('sked_Security_Escort_Name__c');
                        system.debug(oppFieldsRelatedToDOCMap.get(drive.sked_Opportunity__c).get('sked_Security_Escort_Name__c'));
                    }
                    if(updateFlag)
                    {
                        driveListToBeUpdatedList.add(drive);
                    }
                }
            }
        }
            
           if(driveListToBeUpdatedList.size() > 0)
           {
               skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
               Database.saveResult[] updateList = Database.update(driveListToBeUpdatedList, false);
               List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(updateList, 'Update Open to public/security escort name', 'OpportunityService', 'populateRelatedFieldsOnDOC', 'Error', 'Error in drive update');
               Insert errorLogList;
           }
            
        }
    //HRP-9439
    public static void sendOpportunityPromotionDisassociatEmail(Map<Opportunity_Promotion__c,OpportunityTeamMember> oppPromotionMap){
        System.debug('sendOpportunityPromotionDisassociatEmail==>');
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage>();
        Id orgWideEmailAddressId;
        if(String.isNotBlank(label.PROMOTION_SENDER_EMAIL)){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: label.PROMOTION_SENDER_EMAIL ];
            if (owea.size()>0) {
                orgWideEmailAddressId = owea.get(0).Id;
            }
            System.debug('orgWideEmailAddressId '+orgWideEmailAddressId);
        }
        for(Opportunity_Promotion__c opPro : oppPromotionMap.keySet()){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            if(orgWideEmailAddressId != null){
                message.setOrgWideEmailAddressId(orgWideEmailAddressId);
                message.setReplyTo(label.PROMOTION_SENDER_EMAIL);
            }
            message.toAddresses =  new List<String>{oppPromotionMap.get(opPro).User.Email};
                message.optOutPolicy = 'FILTER';
            message.subject = 'Promotion '+opPro.Promotion__r.Name+' has been disassociated from '+opPro.Blood_Drive_Opportunity__r.Name;
            String bulletPoint = '&#42;';
            String textMessage = 'Hi '+oppPromotionMap.get(opPro).User.Name+', \n\n The promotion end date has fallen under drive date of opportunity. So promotion has been removed from opportunity.\n'+
                '\n\t'+bulletPoint.unescapeHtml4()+' Drive date: '+opPro.Drive_Date__c.format()+
                '\n\t'+bulletPoint.unescapeHtml4()+' Drive name: '+opPro.Blood_Drive_Opportunity__r.Name+
                '\n\t'+bulletPoint.unescapeHtml4()+' Promotion name: '+opPro.Promotion__r.Name;
            message.plainTextBody = textMessage;
            messages.add(message);
        }
        if(messages.size() > 0){
            //Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            BSF_EmailNotification.sendEmails(messages,'PromotionExpiry',null);
            System.debug('The email was sent successfully.');
            /*if(results[0].success){
                System.debug('The email was sent successfully.');
            }else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);  
            }*/
        }
    }
    
    //HRP-8946
    public static void SetAPHWebScheduling(List<Opportunity> lstNewOpps, map<Id, Opportunity> oppOldTmpMap) {
        
        System.debug('### inside opportunity service SetAPHWebScheduling');
        
        if(oppOldTmpMap == null) {
            for(Opportunity opp : lstNewOpps){
                opp.Enable_APH_Web_Scheduling__c = opp.Web_Scheduling_Enabled__c == true ? true : false;
            }
        }
        else if(oppOldTmpMap != null) {
            for(Opportunity opp : lstNewOpps){
                if(oppOldTmpMap.get(opp.Id).Web_Scheduling_Enabled__c != Opp.Web_Scheduling_Enabled__c){
                    opp.Enable_APH_Web_Scheduling__c = opp.Web_Scheduling_Enabled__c == true ? true : false;
                } 
            }
        }
    }
    
    /*
* This is for ticket HRP-9562 to decide who will be the owner of the task.*** starts here***
*/
    public static Id getTaskOwner(Opportunity opp, Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap,string AM_DM) //HRP-12333 added paarameter AM_DM
    {
        Id accountManager=opp.Account_Manager__c;
        Id districtManager;
        Id accountSpecialist;
        Id owner=opp.OwnerId;
        
        List<OpportunityTeamMember> oppteamlist = oppTeamMembersMap.get(opp.Id);
        if (oppteamlist != null) {
            for (OpportunityTeamMember oppteamem : oppteamlist) {
                if (oppteamem.TeamMemberRole != null && oppteamem.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER) {
                    districtManager = oppteamem.UserId;
                }
                if (oppteamem.TeamMemberRole != null && oppteamem.TeamMemberRole == BSF_Constants.ACCOUNT_SPECIALIST) {
                    accountSpecialist = oppteamem.UserId;
                }
            }
        }
        if (accountManager != null && AM_DM ==BSF_Constants.ACCOUNT_MANAGER) //HRP-12333
        {
            return accountManager;
        } else if (accountSpecialist != null && AM_DM ==BSF_Constants.ACCOUNT_MANAGER) //HRP-12333 reordered specialist before DM
        {
            return accountSpecialist;
        }else if (districtManager != null) 
        {
            return districtManager;
        }  else 
        {
            return Owner;
        }
        
    }
    /*
* This is for ticket HRP-9562*** ends here***
*/
    
    /* HRP-10172 --> Starts Here
@Description : Updating Physical Location Type field from opportunity with the physical location type value from site whenever a template is changed
*/
    public static void updateTypeBasedOnPhysicalLocationType(List<Opportunity> newOppList, Map<Id,Opportunity> oldOppMap)
    {
        String physicalLocationType = '';
        Set<Id> oppId = new Set<Id>();
        List<Opportunity> finalOppUpdateList = new List<Opportunity>();
        
        
        if (newOppList == null || newOppList.size() < 1)
            return;
        
        for(Opportunity newOpp : newOppList)
        {
            Opportunity oldOpp = oldOppMap?.get(newOpp.Id);
            
            if(oldOpp!=NULL) 
            {
                // If site is changed as part of changing Parent Template Id for Mobile Opportunity
                if(!newOpp.Is_Template__c && (oldOpp.Parent_Template_Id__c != newOpp.Parent_Template_Id__c) 
                   && oldOpp.Type_of_Drive__c == BSF_Constants.MOBILE_DRIVE)
                {                       
                    if(!oppId.contains(newOpp.Id))
                    {                            
                        oppId.add(newOpp.Id);                              
                    }                              
                }
            }
        }
        
        Map<Id,Opportunity> oppMapAfterUpdate = new map<Id,Opportunity>([SELECT Id,Type,
                                                                         Parent_Template_Id__c,
                                                                         Parent_Template_Id__r.Type
                                                                         FROM Opportunity 
                                                                         WHERE ID IN :oppId]);    
        
        for(Opportunity newOppObj : oppMapAfterUpdate.values())
        {                                        
            physicalLocationType = oppMapAfterUpdate?.get(newOppObj.Id).Parent_Template_Id__r.Type;
            
            newOppObj.Type = physicalLocationType!= NULL ? physicalLocationType : NULL;
            if(newOppObj.Type != NULL)
            {
                finalOppUpdateList.add(newOppObj);
            }
            
        }                   
        
        if(finalOppUpdateList.size() > 0)
        {
            Database.SaveResult[] srList  = Database.Update(finalOppUpdateList,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Update Type Field','OpportunityService','updateTypeBasedOnPhysicalLocationType','Error','Error in updating type');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
    // HRP-10172 --> Ends Here
   // HRP-11457-> Start 
    public static void updateOrderBudget(List<Opportunity> listOppIds)
     {
         Set<Id> opportunityids = new Set<Id>();
         Map<Id, Opportunity> oppIdObject;
         oppIdObject = new Map<Id, Opportunity>([Select Id, Total_Products_Projected__c  From Opportunity where Id IN:listOppIds ]);
         //HRP-13568
         list<Order> orderList =[Select Id, OpportunityId, BudgetCurrency__c from order where OpportunityId IN: oppIdObject.keyset()];
         Map<String, List<Budget_Matrix__mdt>> oppBudgetmatrix = new Map<String, List<Budget_Matrix__mdt>>();
         
         List<Budget_Matrix__mdt> budgetMatrix = new List<Budget_Matrix__mdt>();
         Map<String, Budget_Matrix__mdt> bm = Budget_Matrix__mdt.getAll();                                          
                                            for( String bmobj : bm.keySet()){   
                                                Budget_Matrix__mdt bmx = bm.get(bmobj);
                                                if( !oppBudgetmatrix.containsKey( bmx.Type__c ) ){
                                                    oppBudgetmatrix.put(bmx.Type__c, new List<Budget_Matrix__mdt>());
                                                }
                                                oppBudgetmatrix.get(bmx.Type__c).add(bmx);                
                                            }
                                          
         for( Order od : orderList ){
           
             if( od.BudgetCurrency__c == null ){  
                                                  
                     if( oppBudgetmatrix.containsKey( 'Other' ) ){
                                                      for( Budget_Matrix__mdt bmx : oppBudgetmatrix.get('Other') ){
                                                          Decimal productProjected = oppIdObject.get(od.OpportunityId).Total_Products_Projected__c;
                                                          Decimal unitprice = bmx.Unit_Price__c;
                                                          Decimal totalBudget = productProjected * unitprice;
                                                          od.BudgetCurrency__c = totalBudget;
                                                      } 
                     }
                }
         }
         update orderList;       
     }
    /*
    * HRP-11179 changes starts here
    */
    public static void updateAcceptblankMilitaryAuthNamePhone(List<Opportunity> newList){
        if(newList == null){
            return;
        }
        Map<Id,Opportunity> templateMap;
        Set<Id> templateIds = new Set<Id>();
        for(Opportunity opp : newList){
            if(opp.Is_Template__c == false && opp.Parent_Template_Id__c != null 
                    && opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId()){
                        templateIds.add(opp.Parent_Template_Id__c);
            }
        }
        if(!templateIds.isEmpty()){
            templateMap =  new Map<Id,Opportunity>([SELECT Id, 
                                                            AcceptblankMilitaryAuthNamePhone__c 
                                                    FROM Opportunity 
                                                    WHERE Id IN:templateIds 
                                                    AND Is_Template__c = true]);
        }
        if(templateMap != null && !templateMap.isEmpty()){
            for(Opportunity opp : newList){
                if(opp.Is_Template__c == false && opp.Parent_Template_Id__c != null && templateMap.containsKey(opp.Parent_Template_Id__c)
                        && opp.recordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId()){
                            opp.AcceptblankMilitaryAuthNamePhone__c = templateMap.get(opp.Parent_Template_Id__c).AcceptblankMilitaryAuthNamePhone__c;
                } 
            }
        }
    }
    /*
    * HRP-11179 changes ends here
    */
    /* HRP-11313 [Start]->> */
    public static void TemplateImpactingRegion(Map<Id,Opportunity> newOppMap, Map<Id,Opportunity> oldOppMap){
        
        Map<Id,List<sked_Site_Collection_Operation__c>> siteCollectionOperationsMap = new Map<Id,List<sked_Site_Collection_Operation__c>>();
        Map<Id,List<sked_Territory_Collection_Operation__c>> co_TeritoryCoMap = new Map<Id,List<sked_Territory_Collection_Operation__c>>();
        //Map<Id,String> co_RegionNameMap = new Map<Id,String>();
        Map<Id,Id> newOppVsTemplateSite = new Map<Id,Id>();
        Map<Id,Id> oldOppVsTemplateSite = new Map<Id,Id>();
        Set<Id> impactedOppIds_siteChange = new Set<Id>();
        Set<Id> impactedOppIds_templateChange = new Set<Id>();
        Set<Id> impactedOppIds_templateChangeOnly = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        Set<Id> templateIds = new Set<Id>();
        Set<Id> collectionOpIds = new Set<Id>(); 
        
        if(newOppMap == null || newOppMap.isEmpty() || oldOppMap == null || oldOppMap.isEmpty()){
            return;
        }
        
        for(Id oppId : newOppMap.keySet()){
            if(oldOppMap.containsKey(oppId) && !newOppMap.get(oppId).is_template__c && newOppMap.get(oppId).Drive_Site__c != null
                    && oldOppMap.get(oppId).Drive_Site__c != null 
                    && newOppMap.get(oppId).Drive_Site__c != oldOppMap.get(oppId).Drive_Site__c
                    && newOppMap.get(oppId).Drive_Date__c != null){ 
                        impactedOppIds_siteChange.add(oppId);
                        siteIds.add(oldOppMap.get(oppId).Drive_Site__c);
                        siteIds.add(newOppMap.get(oppId).Drive_Site__c);
            }else if(newOppMap.get(oppId).RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId()
                    && !newOppMap.get(oppId).is_template__c                
                    && oldOppMap.containsKey(oppId) 
                    && newOppMap.get(oppId).Parent_Template_Id__c != null 
                    && oldOppMap.get(oppId).Parent_Template_Id__c != null 
                    && newOppMap.get(oppId).Drive_Date__c != null
                    && newOppMap.get(oppId).Parent_Template_Id__c != oldOppMap.get(oppId).Parent_Template_Id__c){ 
                        impactedOppIds_templateChange.add(oppId);
                        templateIds.add(newOppMap.get(oppId).Parent_Template_Id__c);
                        templateIds.add(oldOppMap.get(oppId).Parent_Template_Id__c);
            //HRP-11484 changes starts
            }else if(newOppMap.get(oppId).RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId()
                    && !newOppMap.get(oppId).is_template__c                
                    && oldOppMap.containsKey(oppId) 
                    && newOppMap.get(oppId).Parent_Template_Id__c != null 
                    && oldOppMap.get(oppId).Parent_Template_Id__c == null 
                    && newOppMap.get(oppId).Drive_Date__c != null
                    && newOppMap.get(oppId).Site_TBD__c){
                        impactedOppIds_templateChange.add(oppId);
                        templateIds.add(newOppMap.get(oppId).Parent_Template_Id__c);
            }
            //HRP-11484 changes ends
        }
        
        if(!templateIds.isEmpty()){
            Map<Id,Opportunity> templateList = new Map<Id,Opportunity>([SELECT Id,
                                                                        Drive_Site__c,
                                                                        Site_TBD__c 
                                                                        FROM Opportunity
                                                                        WHERE Id IN :templateIds
                                                                        AND is_template__c = true]);
            for(Id oppId : impactedOppIds_templateChange){
                if(oldOppMap.get(oppId).Parent_Template_Id__c != null
                        && templateList.containsKey(newOppMap.get(oppId).Parent_Template_Id__c)
                        && templateList.containsKey(oldOppMap.get(oppId).Parent_Template_Id__c)
                        && templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Site_TBD__c 
                        && !templateList.get(oldOppMap.get(oppId).Parent_Template_Id__c).Site_TBD__c 
                        && templateList.get(oldOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c != null){
                            newOppMap.get(oppId).addError('Change requires Cancel/Rebook due to the Site changing regions');
                }else if(oldOppMap.get(oppId).Parent_Template_Id__c != null
                        && templateList.containsKey(newOppMap.get(oppId).Parent_Template_Id__c)
                        && templateList.containsKey(oldOppMap.get(oppId).Parent_Template_Id__c)
                        && templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c != null  
                        && templateList.get(oldOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c != null  
                        && templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c 
                        != templateList.get(oldOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c){
                            impactedOppIds_siteChange.add(oppId);
                            impactedOppIds_templateChangeOnly.add(oppId);
                            newOppVsTemplateSite.put(oppId,templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c);
                            oldOppVsTemplateSite.put(oppId,templateList.get(oldOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c);
                            siteIds.add(templateList.get(oldOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c);
                            siteIds.add(templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c);
                //HRP-11484 changes starts
                }else if(oldOppMap.get(oppId).Parent_Template_Id__c == null
                        && templateList.containsKey(newOppMap.get(oppId).Parent_Template_Id__c)
                        && templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c != null){
                            impactedOppIds_siteChange.add(oppId);
                            impactedOppIds_templateChangeOnly.add(oppId);
                            newOppVsTemplateSite.put(oppId,templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c);
                            oldOppVsTemplateSite.put(oppId,null);
                            siteIds.add(templateList.get(newOppMap.get(oppId).Parent_Template_Id__c).Drive_Site__c);
                }
                //HRP-11484 changes ends
            }
        }
        
        if(!siteIds.isEmpty()){
            List<sked_Site_Collection_Operation__c> siteCollectionOperationsList = [SELECT Id,
                                                                                    sked_Collection_Operation__c,
                                                                                    sked_Collection_Operation__r.Name,
                                                                                    sked_Start_Date__c,
                                                                                    sked_Site__c, 
                                                                                    sked_End_Date__c 
                                                                                    FROM sked_Site_Collection_Operation__c 
                                                                                    WHERE sked_Site__c IN :siteIds
                                                                                    AND sked_Start_Date__c != null
                                                                                    AND sked_End_Date__c != null
                                                                                    AND sked_Collection_Operation__c != null];
            for(sked_Site_Collection_Operation__c sco : siteCollectionOperationsList){
                if(siteCollectionOperationsMap.isEmpty() || !siteCollectionOperationsMap.containsKey(sco.sked_Site__c)){
                    siteCollectionOperationsMap.put(sco.sked_Site__c, new List<sked_Site_Collection_Operation__c>());
                }
                siteCollectionOperationsMap.get(sco.sked_Site__c).add(sco);
                collectionOpIds.add(sco.sked_Collection_Operation__c);
            }
        }
        
        if(!collectionOpIds.isEmpty()){
            List<sked_Territory_Collection_Operation__c> territoryList = [SELECT Id,
                                                                                sked_Territory__c,
                                                                                sked_Territory__r.sked_Parent__c,
                                                                                sked_Territory__r.sked_Parent__r.Name,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__c,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Name,
                                                                                sked_Start_Date__c,
                                                                                sked_End_Date__c,
                                                                                sked_Collection_Operation__c 
                                                                          FROM sked_Territory_Collection_Operation__c 
                                                                          WHERE sked_Collection_Operation__c IN :collectionOpIds
                                                                          AND sked_Start_Date__c != null
                                                                          AND sked_End_Date__c != null];
            for(sked_Territory_Collection_Operation__c tco : territoryList){
                if(tco.sked_Territory__c != null && tco.sked_Territory__r.sked_Parent__c != null 
                   && tco.sked_Territory__r.sked_Parent__r.sked_Parent__c != null ){
                        if(co_TeritoryCoMap.isEmpty() || !co_TeritoryCoMap.ContainsKey(tco.sked_Collection_Operation__c)){
                            co_TeritoryCoMap.put(tco.sked_Collection_Operation__c, new List<sked_Territory_Collection_Operation__c>());
                        }
                        co_TeritoryCoMap.get(tco.sked_Collection_Operation__c).add(tco);
                   }
            }
        }
        
        if(!impactedOppIds_siteChange.isEmpty()){
            for(Id oppId : impactedOppIds_siteChange){
                Boolean nonCollectionArea = false;
                Id oldSiteId;
                Id newSiteId;
                String oldRegionName = '';
                String newRegionName = '';

                if(impactedOppIds_templateChangeOnly.contains(oppId)){
                    oldSiteId = oldOppVsTemplateSite.get(oppId);
                    newSiteId = newOppVsTemplateSite.get(oppId);
                }else{
                    oldSiteId = oldOppMap.get(oppId).Drive_Site__c;
                    newSiteId = newOppMap.get(oppId).Drive_Site__c;
                }
                if(oldSiteId != null && siteCollectionOperationsMap.containsKey(oldSiteId)){ //HRP-11484 changes
                    for(sked_Site_Collection_Operation__c sco : siteCollectionOperationsMap.get(oldSiteId)){
                        if(sco.sked_Start_Date__c <= newOppMap.get(oppId).Drive_Date__c && sco.sked_End_Date__c >= newOppMap.get(oppId).Drive_Date__c
                           && co_TeritoryCoMap.containsKey(sco.sked_Collection_Operation__c)){
                               for(sked_Territory_Collection_Operation__c tco : co_TeritoryCoMap.get(sco.sked_Collection_Operation__c)){
                                    if(tco.sked_Start_Date__c <= newOppMap.get(oppId).Drive_Date__c && tco.sked_End_Date__c >= newOppMap.get(oppId).Drive_Date__c){
                                        oldRegionName = tco.sked_Territory__r.sked_Parent__r.Name;
                                    }
                               }
                           }
                    }
                }
                
                if(siteCollectionOperationsMap.containsKey(newSiteId)){
                    for(sked_Site_Collection_Operation__c sco : siteCollectionOperationsMap.get(newSiteId)){
                        if(sco.sked_Start_Date__c <= newOppMap.get(oppId).Drive_Date__c && sco.sked_End_Date__c >= newOppMap.get(oppId).Drive_Date__c){
                            if(co_TeritoryCoMap.containsKey(sco.sked_Collection_Operation__c)){
                                for(sked_Territory_Collection_Operation__c tco : co_TeritoryCoMap.get(sco.sked_Collection_Operation__c)){
                                    if(tco.sked_Start_Date__c <= newOppMap.get(oppId).Drive_Date__c && tco.sked_End_Date__c >= newOppMap.get(oppId).Drive_Date__c){
                                        newRegionName = tco.sked_Territory__r.sked_Parent__r.Name;
                                    }
                               }
                            }
                            if(String.isNotBlank(sco.sked_Collection_Operation__r.Name) 
                               && sco.sked_Collection_Operation__r.Name.equalsIgnoreCase('Non-Collection Area')){
                                   nonCollectionArea = true;
                               }
                        }
                    }
                }
                
                //HRP-11484 changes
                if(nonCollectionArea || (oldSiteId != null && (String.isBlank(oldRegionName) || String.isBlank(newRegionName) || !oldRegionName.equals(newRegionName)))){
                    newOppMap.get(oppId).addError('Change requires Cancel/Rebook due to the Site changing regions');
                }
            }
        }
    }
    /*<- HRP-11313 [End] */
    /*
    * HRP-10912 changes starts here
    @Description : This method will block Opportunities status changed while DCR or Pending Action Request is in process.
    */
    public static void validateNoPendingDCR(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){
        if(newMap == null || newMap.isEmpty() || oldMap == null || oldMap.isEmpty()){
            return;
        }
        Map<Id, Boolean> dcrMap = new Map<Id, Boolean>(); 
        for(Id oppId : newMap.keySet()){
            if(oldMap.containsKey(oppId) && String.isNotBlank(newMap.get(oppId).StageName) 
                    && !newMap.get(oppId).StageName.equals('Cancelled')
                    && newMap.get(oppId).StageName != oldMap.get(oppId).StageName){
                        dcrMap.put(oppId,false);
               }
        }
        if(!dcrMap.isEmpty()){
            Map<Id,Id> docToOppMap = new Map<Id,Id>();
            Custom_Messages__mdt messageLabel2 = Custom_Messages__mdt.getInstance('Pending_Approval_Statuses_Drive');
            List<String> pendingApprovalStatusList = messageLabel2.value__c.split(',');
            List<sked_Drive__c> docPendingApprovalList = [SELECT Id,
                                                          sked_Approval_Status__c,
                                                          sked_Opportunity__c
                                                          FROM sked_Drive__c 
                                                          WHERE sked_Opportunity__c IN: dcrMap.keySet()];
            for(sked_Drive__c doc : docPendingApprovalList){
                docToOppMap.put(doc.Id,doc.sked_Opportunity__c);
                if(String.isNotBlank(doc.sked_Approval_Status__c) && pendingApprovalStatusList.contains(doc.sked_Approval_Status__c)){
                    dcrMap.put(doc.sked_Opportunity__c,true); //HRP-10912 changes 
                }
            }
            Custom_Messages__mdt messageLabel1 = Custom_Messages__mdt.getInstance('Pending_Statuses_DCR');
            List<String> dcrPendingStatusList = messageLabel1.value__c.split(',');
            List<sked_Drive_Change_Request__c> dcrchangeList = [SELECT Id, 
                                                                sked_Drive__c, 
                                                                sked_Status__c,
                                                                sked_Opportunity__c
                                                                FROM sked_Drive_Change_Request__c 
                                                                WHERE sked_Status__c IN: dcrPendingStatusList
                                                                AND sked_Type__c includes ('User Change') //HRP-10912 changes 
                                                                AND (sked_Opportunity__c IN: dcrMap.keySet()
                                                                     OR sked_Drive__c IN: docToOppMap.keySet())];
            for(sked_Drive_Change_Request__c dcr : dcrchangeList){
                if(dcr.sked_Opportunity__c != null){
                    dcrMap.put(dcr.sked_Opportunity__c,true);
                }else if(dcr.sked_Drive__c != null && docToOppMap.containsKey(dcr.sked_Drive__c)){
                    dcrMap.put(docToOppMap.get(dcr.sked_Drive__c),true);
                }
            }
            
            for(Id oppId : newMap.keySet()){
                if(dcrMap.containsKey(oppId) && dcrMap.get(oppId)){
                    newMap.get(oppId).addError(Custom_Messages__mdt.getInstance('Pending_DCR_Opportunity').value__c);
                }
            }
        }
    }
    /*
    * HRP-10912 changes ends here
    */
    //HRP-11849 starts(new method created)
    public static void updateAMDMPortfolioOnDOC(List<Opportunity> newList, Map<Id,Opportunity> oldMap){
        Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap = new Map<Id,Opportunity>();
        if(newList == null || newList.isEmpty()){
            return;
        }
        for(Opportunity opp : newList){
            if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(opp.Id)
                    && (opp.Account_Manager_Portfolio__c != oldMap.get(opp.Id).Account_Manager_Portfolio__c
                    || opp.District_Manager_Portfolio__c != oldMap.get(opp.Id).District_Manager_Portfolio__c)){
                        oppIdVsAMDMPortfoliodMap.put(opp.Id,opp);
            }else if(oldMap == null || oldMap.isEmpty()){
                oppIdVsAMDMPortfoliodMap.put(opp.Id,opp);
            }
        }
        if(!oppIdVsAMDMPortfoliodMap.isEmpty()){
            UpdateDriveOwnerOnOppOwnerUpdate(new Map<Id,Id>(),new Map<Id,Id>(),oppIdVsAMDMPortfoliodMap);
        }
    }
    //HRP-11849 ends
    //HRP-12143 START
  public static void restrictFieldChangeWhenPendingActionIsOpen(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){
        Boolean isAutomatedProcess = UserInfo.getName() == BSF_Constants.AUTOMATED_PROCESS;//HRP-13045 Start
        if(isAutomatedProcess) {
            return ;
        }//HRP-13045 End

        Map<Id, Id> oppToSkedDriveMap = new Map<Id, Id>();
        Map<Id, sked_Drive__c> oppVsPendingActionAndApprovalStatus = new Map<Id, sked_Drive__c>(); //HRP-13045
        System.debug('oppToSkedDriveMap: ' + oppToSkedDriveMap);
        for (sked_Drive__c drive : [SELECT Id, sked_Opportunity__c, sked_Pending_Action__c, sked_Approval_Status__c FROM sked_Drive__c WHERE sked_Opportunity__c IN :newMap.keySet()]) {//HRP-13045
            oppToSkedDriveMap.put(drive.sked_Opportunity__c, drive.Id);
            System.debug('oppToSkedDriveMap1: ' + oppToSkedDriveMap);
            oppVsPendingActionAndApprovalStatus.put(drive.sked_Opportunity__c,drive);//HRP-13045
        }
        Set<Id> skedDriveWithPendingAction = new Set<Id>();
        for (ProcessInstanceWorkItem item : [SELECT Id, ProcessInstance.Status, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId IN :oppToSkedDriveMap.values() AND ProcessInstance.Status = 'Pending']) {
            skedDriveWithPendingAction.add(item.ProcessInstance.TargetObjectId);
        }
        for (Opportunity op : newMap.values()) {
            Id relatedSkedDriveId = oppToSkedDriveMap.get(op.Id);
            if (relatedSkedDriveId != null && skedDriveWithPendingAction.contains(relatedSkedDriveId)) {//HRP-13045 start
                if(oppVsPendingActionAndApprovalStatus.containsKey(op.Id) && oppVsPendingActionAndApprovalStatus.get(op.Id).sked_Pending_Action__c == null && oppVsPendingActionAndApprovalStatus.get(op.Id).sked_Approval_Status__c == null){
                    continue;
                }//HRP-13045 end
                Opportunity oldOp = oldMap.get(op.Id);
                List<String> changedFields = getChangedFields(op, oldOp);
                if (!changedFields.isEmpty()) {
                    String fields = String.join(changedFields, ', ');
                    System.debug('Changed Fields: ' +changedFields);
                    op.addError('You cannot change '+ fields +' when there is a pending action on the related DOC record.');
                }
            }
        }
    }
    
    private static List<String> getChangedFields(Opportunity newOp, Opportunity oldOp) {
        List<String> changedFields = new List<String>();
        
        List<restrictFieldChangeWhenPendingAction__mdt> fieldsToCheck = restrictFieldChangeWhenPendingAction__mdt.getAll().values();
        Map<String, String> fieldApiNameToLabelMap = new Map<String, String>();
        for (restrictFieldChangeWhenPendingAction__mdt field : fieldsToCheck) {
            fieldApiNameToLabelMap.put(field.Field_Api_Name__c, field.Field_Label__c);
        }
        
        for (String fieldApiName : fieldApiNameToLabelMap.keySet()) {
            if (newOp.get(fieldApiName) != oldOp.get(fieldApiName)) {
                changedFields.add(fieldApiNameToLabelMap.get(fieldApiName));
            }
        }
        
        return changedFields; 
    }
    //HRP-12143 End
    // HRP-12011 --> Starts Here
    public static void populateSlotGeneratorOnOpportunity(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap, String action) {
        String slotGeneratorChangeReason = '';
        String loggedInUserProfileName = '';
        Boolean isUserChangedValue = FALSE;
        Boolean isAutomatedProcess = UserInfo.getName() == BSF_Constants.AUTOMATED_PROCESS;
        
        if(OpportunityTriggerHandler.isCalledBefore) {
            slotGeneratorChangeReason = Custom_Messages__mdt.getInstance('Slot_Generator_Chng_Rsn_on_Insert').value__c;
        } else {
            slotGeneratorChangeReason = Custom_Messages__mdt.getInstance('Slot_Generator_Chng_Rsn_on_Update').value__c;
            slotGeneratorChangeReason = slotGeneratorChangeReason.replace('{username}' , UserInfo.getName());
            slotGeneratorChangeReason = slotGeneratorChangeReason.replace('{dateTime}', String.valueOf(System.now()));
        }
        //HRP-13489 Start
        Map<Id,Id> oppIdSiteIdMap = new Map<Id,Id>();
        for(Opportunity newOpp : newOppList) 
        {
            oppIdSiteIdMap.put(newOpp.Id,newOpp.Drive_Site__c);
        }
        
        Map<Id,sked__Location__c> driveSiteIdMap =new Map<Id,sked__Location__c>([SELECT Id, Operation_Type__c FROM sked__Location__c WHERE Id = :oppIdSiteIdMap.Values()]);
        //HRP-13489 End
        
        for(Opportunity newOpp : newOppList) {
            if(newOpp.Is_Template__c) continue;
            
            //HRP-13489 Start
            sked__Location__c driveSite = new sked__Location__c();
            if(driveSiteIdMap.containsKey(newOpp.Drive_Site__c))
            {
                driveSite = driveSiteIdMap.get(newOpp.Drive_Site__c);
            }
            //HRP-13489 End
            
            if(action == 'INSERT') {

                // 1. In case of Opportunity Creation, value will be defaulted to global value
                if(newOpp.Slot_Generator__c == NULL) {
                    newOpp.Slot_Generator__c = getSlotMultiplierGlobalValue(newOpp,driveSite);//HRP-13489 2nd parameter driveSite
                    slotGeneratorChangeReason = slotGeneratorChangeReason.replace('{action}', newOpp.get('Source__c') != NULL && newOpp.Source__c.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD) ? BSF_Constants.OPP_SOURCE_CALENDAR_BUILD : BSF_Constants.OPP_SOURCE_PLAN_A_DRIVE);
                    newOpp.Slot_Generator_Change_Reason__c = slotGeneratorChangeReason;
                } else {
                    if(newOpp.get('Source__c') != NULL && newOpp.Source__c.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) {
                        slotGeneratorChangeReason = Custom_Messages__mdt.getInstance('Slot_Generator_Chng_Rsn_upon_CB').value__c;
                        newOpp.Slot_Generator_Change_Reason__c = slotGeneratorChangeReason;
                    }
                }
            } else {
                if(oldOppMap != NULL) {
                    Opportunity oldOpp = oldOppMap.get(newOpp.Id);
                    Decimal globalValueForOld = getSlotMultiplierGlobalValue(oldOpp,driveSite);//HRP-13489 2nd parameter driveSite

                    //2. In case of Call List Recipient Update
                    if(oldOpp.Call_List_Recipient_Exist__c != newOpp.Call_List_Recipient_Exist__c && BSF_Utilities.isMobileOpportunity(newOpp)) {
                        if(oldOpp.Slot_Generator__c != globalValueForOld) {
                            isUserChangedValue = TRUE;
                        }
                        if(!isUserChangedValue) {
                            newOpp.Slot_Generator__c = getSlotMultiplierGlobalValue(newOpp,driveSite);//HRP-13489 2nd parameter driveSite
                            if(!OpportunityTriggerHandler.isCalledBefore) {
                                slotGeneratorChangeReason = slotGeneratorChangeReason.replace('{action}', newOpp.Call_List_Recipient_Exist__c ? 'added' : 'removed');
                            } else {
                                slotGeneratorChangeReason = newOpp.Slot_Generator_Change_Reason__c+'.';
                            }
                            newOpp.Slot_Generator_Change_Reason__c = slotGeneratorChangeReason;
                        }
                    }

                    //3. In case of Slot Generator Update
                    else if(oldOpp.Slot_Generator__c != newOpp.Slot_Generator__c) {
                        if(!isAutomatedProcess) {
                            loggedInUserProfileName =[SELECT Id, Name FROM Profile WHERE Id =:UserInfo.getProfileId()].Name;
                            if(!BSF_Utilities.isMobileOpportunity(newOpp) && loggedInUserProfileName.equalsIgnoreCase(BSF_Constants.DRD_PROFILE)) {
                                newOpp.Slot_Generator__c.addError(Custom_Messages__mdt.getInstance('Error_Msg_FS_Slot_Multiplier_Change_DRD').value__c);
                            } else if(newOpp.Slot_Generator__c == NULL || newOpp.Slot_Generator__c == 0) {
                                newOpp.Slot_Generator__c.addError(Custom_Messages__mdt.getInstance('Error_Msg_Slot_Generator_Null_Value').value__c);
                            } else {
                                Map<String, BSF_Slot_Multiplier_Settings__mdt> map_profileName_slotMultiplierMdt = getProfileSpecificSlotMultiplierFromMetadata();
                                if(map_profileName_slotMultiplierMdt.containskey(loggedInUserProfileName)) {
                                    Decimal lowerLimit = map_profileName_slotMultiplierMdt.get(loggedInUserProfileName).Lower_Limit_Threshold__c;
                                    Decimal upperLimit = map_profileName_slotMultiplierMdt.get(loggedInUserProfileName).Upper_Limit_Threshold__c;
                                    if(!(newOpp.Slot_Generator__c >= lowerLimit && newOpp.Slot_Generator__c <= upperLimit)) {
                                        String errorMessage = map_profileName_slotMultiplierMdt.get(loggedInUserProfileName).Custom_Warning_Message__c;
                                        errorMessage = errorMessage.replace('{lowerLimit}' , String.valueOf(lowerLimit));
                                        errorMessage = errorMessage.replace('{upperLimit}' , String.valueOf(upperLimit));
                                        newOpp.Slot_Generator__c.addError(errorMessage);
                                    }
                                }
                            }   
                        }
                    } 

                    //4. In case of Slot Generator Change Reason Update by DRD for FS Drives
                    else if(oldOpp.Slot_Generator_Change_Reason__c != newOpp.Slot_Generator_Change_Reason__c && !BSF_Utilities.isMobileOpportunity(newOpp)) {
                         if(!isAutomatedProcess) {
                            loggedInUserProfileName =[SELECT Id, Name FROM Profile WHERE Id =:UserInfo.getProfileId()].Name;
                            if(loggedInUserProfileName.equalsIgnoreCase(BSF_Constants.DRD_PROFILE)) {
                                newOpp.Slot_Generator_Change_Reason__c.addError(Custom_Messages__mdt.getInstance('Error_Msg_FS_Slot_Multiplier_Change_DRD').value__c);
                            }
                         }
                    }
                }
            }
        }
    }

    private static Decimal getSlotMultiplierGlobalValue(Opportunity opp, sked__Location__c driveSite) //HRP-13489 2nd parameter driveSite
    {
        Decimal globalValue = 0;
        slwcSetting.adminSetting skedAdminSetting = new slwcSetting.adminSetting();
        Decimal paddingPercentageForFS = skedAdminSetting.callListRecipientNoneFixedSite;
        Decimal paddingPercentageForMobileWithCLR = skedAdminSetting.callListRecipient;
        Decimal paddingPercentageForMobileWithoutCLR = skedAdminSetting.callListRecipientNone;
        if(BSF_Utilities.isWbFixedSiteOpportunity(opp,driveSite) || BSF_Utilities.isMobileOpportunity(opp)) //HRP-13489 2nd parameter driveSite in BSF_Utilities.isWbFixedSiteOpportunity
        {
            globalValue = opp.Call_List_Recipient_Exist__c ? paddingPercentageForMobileWithCLR : paddingPercentageForMobileWithoutCLR;
        } else {
            globalValue = paddingPercentageForFS;
        }
        return globalValue;
    }

    private static Map<String, BSF_Slot_Multiplier_Settings__mdt> getProfileSpecificSlotMultiplierFromMetadata() {
        Map<String, BSF_Slot_Multiplier_Settings__mdt> map_profileName_slotMultiplierMdt = new Map<String, BSF_Slot_Multiplier_Settings__mdt>();
        List<BSF_Slot_Multiplier_Settings__mdt> slotMultiplierMdtList = BSF_Slot_Multiplier_Settings__mdt.getAll().values();
        for(BSF_Slot_Multiplier_Settings__mdt slotMultiplierMdt : slotMultiplierMdtList) {
            map_profileName_slotMultiplierMdt.put(slotMultiplierMdt.Profile_Name__c, slotMultiplierMdt);
        }
        return map_profileName_slotMultiplierMdt;
    }
    // HRP-12011 --> Ends Here
    
    // HRP-12664 --> Starts Here
   public static void syncTemplateOrdertoOpportunity(List<Opportunity> listOfnewOppties, Map<Id, Opportunity> mapOfOfOldOppties) {
        List<Opportunity> newOpportunityList = new List<Opportunity>();
        Map<Id, Opportunity> map_oldOppId_oldOpportunity = new Map<Id, Opportunity>();
        List<String> oppIds = new List<String>();//HRP-13716 changes
    List<Opportunity_Template_Order_Sync_Event__e> oppoOrderSyncEvents = new List<Opportunity_Template_Order_Sync_Event__e>(); //HRP-13891 changes
        for(Opportunity newOpp : listOfnewOppties) {
            if(newOpp.Id != null && mapOfOfOldOppties != null && !mapOfOfOldOppties.isEmpty() && mapOfOfOldOppties.containskey(newOpp.Id)) {//HRP-13716 Changes
                Opportunity oldOpp = mapOfOfOldOppties.get(newOpp.Id);
                    if(oldOpp != null && newOpp.Parent_Template_Id__c != null && newOpp.Parent_Template_Id__c != oldOpp.Parent_Template_Id__c ) {//&& !newOpp.Site_TBD__c) { HRP-13716 Changes
                        newOpportunityList.add(newOpp);
                        map_oldOppId_oldOpportunity.put(oldOpp.Id, oldOpp);
                        oppIds.add(newOpp.Id);//HRP-13716 changes
            //Start HRP-13891 changes
            Opportunity_Template_Order_Sync_Event__e oppoOrderSyncEvent = new Opportunity_Template_Order_Sync_Event__e();
            oppoOrderSyncEvent.OpportunityId__c = newOpp.Id;
            oppoOrderSyncEvents.add(oppoOrderSyncEvent);
            //End HRP-13891 changes
                    }
            }else if(newOpp.Id != null && newOpp.Parent_Template_Id__c != null && (mapOfOfOldOppties == null || mapOfOfOldOppties.isEmpty())){//HRP-13716 Changes
                newOpportunityList.add(newOpp);
                oppIds.add(newOpp.Id);//HRP-13716 changes
        //Start HRP-13891 changes
        Opportunity_Template_Order_Sync_Event__e oppoOrderSyncEvent = new Opportunity_Template_Order_Sync_Event__e();
        oppoOrderSyncEvent.OpportunityId__c = newOpp.Id;
        oppoOrderSyncEvents.add(oppoOrderSyncEvent);
        //End HRP-13891 changes
            }
       }
     //Commented for HRP-13891
       //OrderCloningService.cloneTemplateOrder(oppIds);//HRP-13716 changes
       //HRP-13743 --> Ends Here
     
     //Start HRP-13891 changes
     //Publish platform event to create Order record for each new opportunity based on the template
        if(oppoOrderSyncEvents.size() > 0) {
            System.debug('### before publishing Opportunity_Template_Order_Sync_Event__e event ' + oppoOrderSyncEvents.size());
            EventBus.publish(oppoOrderSyncEvents);
        }
     //End HRP-13891 changes
    }
    
    /*public static void cloneTemplateOrder(List<Opportunity> listOfOpportunities, Map<Id, Opportunity> mapOfOfOldOppties) {
        Set<ID> oppID = new Set<ID>();
        List<Order> createOppOrder = new List<Order>();
        List<OrderItem> createOppOrderItem = new List<OrderItem>();
        Map<ID, List<ID>> templateToOppIDMap = new Map<ID, List<ID>>();
        List<Order> getExistingOppOrder = new List<Order>();
        if(listOfOpportunities != null){//HRP-13716 changes
            for (Opportunity opp : listOfOpportunities) {
                if(opp.id != null && opp.Parent_Template_Id__c != null){
                    if(templateToOppIDMap.isEmpty() || !templateToOppIDMap.containsKey(opp.Parent_Template_Id__c)){
                        templateToOppIDMap.put(opp.Parent_Template_Id__c, new List<ID>());
                    }
                    templateToOppIDMap.get(opp.Parent_Template_Id__c).add(opp.Id);
                }
            }
        }

        List<Order> getTemplateOrder = [SELECT Id, Order_Due_Date__c, EffectiveDate, AccountId, OpportunityId, 
                                        Material_Recipient__c, Material_Recipient_Type__c,
                                        Comments__c, Publicity_Approved__c, Publicity_Submitted__c, Status, 
                                        StatusCode,Pricebook2Id,Local_Recruitment_Request__c,
                                        Local_Recruitment_Request_Need_by_Date__c,
                                        (
                                            SELECT Id, OrderID, Product2Id, TotalPrice, ListPrice, 
                                           Quantity, UnitPrice, PricebookEntryId 
                                           FROM OrderItems
                                        )
                                        FROM Order 
                                        WHERE OpportunityId IN :templateToOppIDMap.keySet()];
        
        if(!getTemplateOrder.isEmpty()) {   //HRP-13716 changes
            if(mapOfOfOldOppties != null) {
                getExistingOppOrder = [SELECT Id, OpportunityId, Publicity_Approved__c, Publicity_Submitted__c 
                                       FROM Order 
                                       WHERE OpportunityId IN: mapOfOfOldOppties.keySet()];//HRP-13716 changes
                    
                List<Order> deleteOppOrder = new List<Order>();
                for(Order getOrder : getExistingOppOrder) {
                    if(!getOrder.Publicity_Approved__c && !getOrder.Publicity_Submitted__c) {
                        system.debug('here to delete order');
                        deleteOppOrder.add(getOrder);
                    }
                    if(getOrder.Publicity_Approved__c || getOrder.Publicity_Submitted__c) {
                       oppID.add(getOrder.OpportunityId);
                    }
                 }
                 
                //HRP-13743 -> Added Error log entry for deletion
                 if(deleteOppOrder != NULL && !deleteOppOrder.isEmpty()) {
                    TriggerHandler.bypass('OrderTriggerHandler'); //HRP-13743
                    Database.DeleteResult[] deleteResult = Database.delete(deleteOppOrder, false); 
                    TriggerHandler.clearAllBypasses();
                    List<BSF_Error_Log__c> errorLogToInsert = BSF_Utilities.createErrorLog(
                        deleteResult,
                        'Delete Existing Order',
                        'OpportunityService',
                        'syncTemplateOrdertoOpportunity',
                        'Error',
                        'Error in deleting order'
                    );
                    if(errorLogToInsert != NULL && !errorLogToInsert.isEmpty()) {
                        system.debug('here in error log insert');
                        insert errorLogToInsert;
                    }
                }
                //HRP-13743--> Ends Here
        }
         
            for(Order cloneOrder: getTemplateOrder) {
                for(Id opp: templateToOppIDMap.get(cloneOrder.OpportunityId)) {
                    if(opp != null){
                        if(oppID != null && !oppID.isEmpty() && oppID.contains(opp)) {
                            Continue;
                        }
                        Order newOrder = new Order();
                        newOrder.EffectiveDate = cloneOrder.EffectiveDate;
                        newOrder.AccountId = cloneOrder.AccountId;
                        newOrder.Material_Recipient__c = cloneOrder.Material_Recipient__c;
                        newOrder.Material_Recipient_Type__c = cloneOrder.Material_Recipient_Type__c;
                        newOrder.Comments__c = cloneOrder.Comments__c;
                        newOrder.Publicity_Submitted__c = cloneOrder.Publicity_Submitted__c;
                        newOrder.Pricebook2Id = cloneOrder.Pricebook2Id;
                        newOrder.Status = cloneOrder.Status;
                        newOrder.Publicity_Approved__c = cloneOrder.Publicity_Approved__c;
                        newOrder.Local_Recruitment_Request__c = cloneOrder.Local_Recruitment_Request__c;
                        newOrder.Local_Recruitment_Request_Need_by_Date__c = cloneOrder.Local_Recruitment_Request_Need_by_Date__c;
                        newOrder.OpportunityId = opp;
                        createOppOrder.add(newOrder);
                        system.debug('#13716 orders : '+newOrder);
                    }
                }
            }
       }

     if(!createOppOrder.isEmpty()) {
        List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();//HRP-13716 changes
        Database.SaveResult[] srList = Database.insert(createOppOrder, false);
        logList.addAll(BSF_Utilities.createErrorLog(srList, 'syncing Order from template to Opportunity','OpportunityService','syncTemplateOrdertoOpportunity','Error','Error in sync Order from template to opportunity'));//HRP-13716 changes
        system.debug('here to insert order');
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                for(Order cloneOrder: getTemplateOrder) {
                    if(cloneOrder.OrderItems != NULL) {
                        for (OrderItem cloneOrderItem : cloneOrder.OrderItems){  
                            OrderItem newOrderItem = new OrderItem();
                            newOrderItem.OrderId = sr.getId();
                            newOrderItem.Product2Id = cloneOrderItem.Product2Id;                        
                            newOrderItem.ListPrice = cloneOrderItem.ListPrice;
                            newOrderItem.Quantity = cloneOrderItem.Quantity;
                            newOrderItem.UnitPrice = cloneOrderItem.UnitPrice;
                            newOrderItem.PricebookEntryId = cloneOrderItem.PricebookEntryId;
                            
                            if(newOrderItem.OrderId != NULL) {
                                createOppOrderItem.add(newOrderItem);
                            }
                        }
                    }
                }
            }  
        }
  
        if (!createOppOrderItem.isEmpty()) {
            Database.SaveResult[] oppOrderList = Database.insert(createOppOrderItem, false); //HRP-13716
            logList.addAll(BSF_Utilities.createErrorLog(oppOrderList, 'syncing Order from template to Opportunity','OpportunityService','syncTemplateOrdertoOpportunity','Error','Error in sync OrderItem from template to opportunity'));
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
        if (!logList.isEmpty()) {//HRP-13716
            InsertBsfErrorLog.insertBsfErrors(logList);//HRP-13716
        }
      }
  }*/
  // HRP-12664 --> Ends Here
  
    //HRP-12142 starts
    public static void syncDoNotRollFields(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        System.debug('syncDoNotRollFields : method start');
        
        if(newList != null && !newList.isEmpty()){
            for(Opportunity opp : newList){
                System.debug('syncDoNotRollFields : opp.Rollover_Consideration__c '+opp.Rollover_Consideration__c);
                System.debug('syncDoNotRollFields : opp.Do_Not_Roll__c '+opp.Do_Not_Roll__c);
                if((oldMap == null || oldMap.isEmpty()) || (opp.Id != null && oldMap.containsKey(opp.Id) 
                        && opp.Rollover_Consideration__c != oldMap.get(opp.Id).Rollover_Consideration__c)){
                            if(String.isNotBlank(opp.Rollover_Consideration__c) && opp.Rollover_Consideration__c.equalsIgnoreCase('Do Not Roll')){
                                opp.Do_Not_Roll__c = true;
                            }else{
                                opp.Do_Not_Roll__c = false;
                            }
                }else if(opp.Id != null && oldMap.containsKey(opp.Id) && opp.Do_Not_Roll__c != oldMap.get(opp.Id).Do_Not_Roll__c){
                    if(opp.Do_Not_Roll__c){
                        opp.Rollover_Consideration__c = 'Do Not Roll';
                    }else{
                        opp.Rollover_Consideration__c = null;
                    }
                }
                System.debug('syncDoNotRollFields : opp.Rollover_Consideration__c '+opp.Rollover_Consideration__c);
                System.debug('syncDoNotRollFields : opp.Do_Not_Roll__c '+opp.Do_Not_Roll__c);
            }
        }
    }
    //HRP-12142 ends
    
    //HRP-13190 --> Starts Here
    public static void captureAPTRequirements(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        List<Opportunity> oppListToRecalculateAPT = new List<Opportunity>();
        if (oldOppMap == NULL && newOppList != NULL && !newOppList.isEmpty()) {
            newOppList = BSF_Utilities.getAPTQuantity(newOppList, 'Insert');
        } else if (oldOppMap != NULL) {
            for(Opportunity newOpp : newOppList) {
                Opportunity oldOpp = oldOppMap.get(newOpp.Id);
                if (oldOpp != NULL) {
                    Boolean recalculateAptRule1 = !checkRecursive.skipAptRecalculation; //During DOC -> OPP Sync
                    Boolean recalculateAptRule2 = (oldOpp.APT_Change_Reason__c == newOpp.APT_Change_Reason__c) || ((oldOpp.APT_Change_Reason__c != newOpp.APT_Change_Reason__c) && !newOpp.APT_Change_Reason__c.containsIgnoreCase(BSF_Constants.APT_CHANGE_VIA_TEMPLATE));
                    Boolean recalculateAptRule3 = oldOpp.APT_Required__c != newOpp.APT_Required__c;
                    Boolean recalculateAptRule4 = oldOpp.Total_Projected_Procedures__c != newOpp.Total_Projected_Procedures__c;  
                    
                    if(recalculateAptRule1 && recalculateAptRule2) {
                        if(recalculateAptRule3 && !newOpp.APT_Required__c) {
                            newOpp.APT_Quantity__c = 0;
                            newOpp.APT_Change_Reason__c = (newOpp.Is_Template__c ? 'Template' : 'Opportunity') + ' APT changed by ' + userInfo.getName() + ' on '+system.now();
                        } else oppListToRecalculateAPT.add(newOpp);
                    }
                }
            }
            if(oppListToRecalculateAPT != NULL && !oppListToRecalculateAPT.isEmpty()) {
                oppListToRecalculateAPT = BSF_Utilities.getAPTQuantity(oppListToRecalculateAPT, 'Update');
            }
        }
    }
    //HRP-13190 --> Ends Here

    //HRP-6051 Starts Here
    public static void validateTheARD(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap){
        //user profile checking
        Map<String, ARD_Alert_Profiles__mdt> profilesToAlert = ARD_Alert_Profiles__mdt.getAll();
        Set<String> relevantProfiles = new Set<String>();
        for (ARD_Alert_Profiles__mdt profile : profilesToAlert.values()) {
            //System.debug('HRP-6051 profile : '+profile);
            relevantProfiles.add(profile.Label);
        }
        // Check the current user's profile
        Profile profile;
        String currentProfileName;
        //System.debug('HRP-6051 profile : '+profile+' currentProfileName:'+currentProfileName);
        try {
            profile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
            System.debug('profile : '+profile);
            currentProfileName = profile.Name;
            // You can now safely use `profile.Name`
        } catch (QueryException e) {
            // Handle the case where no profile is found
            System.debug('QueryException: No profile found for the logged-in user. Error: ' + e.getMessage()+ 'Stack Trace: ' + e.getStackTraceString());
            currentProfileName = 'NA';
        } catch (Exception ex) {
            // Handle any other unexpected exceptions
            System.debug('Unexpected exception occurred. Error: ' + ex.getMessage()+' Stack Trace: ' + ex.getStackTraceString());
            currentProfileName = 'NA';
        }

        System.debug('HRP-6051 currentProfileName :'+currentProfileName);
        if (currentProfileName != 'NA' && relevantProfiles.contains(currentProfileName)) {
            //System.debug('HRP-6051 relevantProfiles  :'+currentProfileName);
            Map<String, Object> changedFields = new Map<String, Object>();
            for (Opportunity opp : newOppList) {
                Opportunity oldOpp = oldOppMap.get(opp.Id);
                // Condition: WB/DR projection changed, ARD not updated
                
                if ((opp.WB_Projected_Procedures__c != oldOpp.WB_Projected_Procedures__c || 
                    opp.X2RBC_Projected_Procedures__c != oldOpp.X2RBC_Projected_Procedures__c) &&
                    opp.Anticipated_Registered_Donors__c == oldOpp.Anticipated_Registered_Donors__c) {
                        opp.Pending_ARD_Confirmation__c = true; 
                }else if(opp.Anticipated_Registered_Donors__c != oldOpp.Anticipated_Registered_Donors__c){
                        opp.Pending_ARD_Confirmation__c = false;
                } 
            }
        }    
    }
    //HRP-6051 Ends Here
}