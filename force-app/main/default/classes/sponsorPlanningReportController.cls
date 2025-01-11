public without sharing class sponsorPlanningReportController {
    
    public class ReportDataWrapper {
        @AuraEnabled public Opportunity opp {get; set;}       
        public Boolean isSelected{get; set;}
        
        public ReportDataWrapper(Opportunity op) {
            opp = op;
            isSelected = false;
        }
    }   

    public Boolean isSelectedNote{get;set;}
    public sponsorPlanningReportController() {
        try {
            List<Id> oppIds = new List<Id>();
            if (Apexpages.currentPage().getParameters().get('ids') != null) {
                String oppIdString = Apexpages.currentPage().getParameters().get('ids');
                oppIds = oppIdString.split('/');
                getDataforPdf(oppIds);
            }
        } catch (Exception ex) {
            System.debug(ex.getLineNumber());
            System.debug(ex.getMessage());
        }
    }
    
    private String getFormattedTime(Integer hour, Integer minutes){
        String st;
        if(hour == 0){
            hour = 12;
            st = ' AM';
        }else if(hour < 12){
            st = ' AM';
        }else if(hour == 12){
            st = ' PM';
        }else if(hour > 12){
            hour = hour - 12;
            st = ' PM';
        }
        if(minutes < 10){
            return hour+':0'+minutes+st;
        }else{
            return hour+':'+minutes+st;
        }
    }
    private String dateFormat(date preDate){
        String result = '';
        if(preDate != null){
            DateTime dDate = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day());
            result = dDate.format('M/d/yyyy');
        }
        return result;
    }
    private Integer roundDecimals(Decimal input){
        Integer result = 0;
        if(input != null){
            input += 0.5;
            result = input.intValue();
        }
        return result;
    }

    public class ReportQueryWrapper{
        public Opportunity oppWrap {get; set;}
        public String startTime {get; set;}
        public String endTime {get; set;}
        public String elevatorOpenTime {get; set;}
        public String elevatorCloseTime {get; set;}
        public String siteOpenTime {get; set;}
        public String setupTimeWrap {get; set;}
        public String siteCloseTime {get; set;}
        public AccountBridgeAPI__x apiWrap {get; set;}
        public list<Account_Marketing_Program__c> accPremierAffiliationWrap {get; set;}
        public list<sked_Drive__c> driveListWrap {get;set;}
        public list<sked_Drive_Shift__c> shiftListWrap {get;set;}
        public list<ShiftWrapper> shiftListWrap2 {get;set;}
        public userWrapper primaryConListWrap {get;set;}
        public userWrapper ABMListWrap {get;set;}
        public list<sked__Job__c> jobListWrap {get;set;}
        public Decimal maxDonorCapacity{get;set;}
        public list<Decimal> lunchBrkDurationWrap {get;set;}
        public list<String> lunchBrkDurationTime {get;set;}
        public list<OpportunityContactRole> afterHoursWrap {get;set;}
        public list<OpportunityContactRole> whoomToMeetWrap {get;set;}
        public list<OpportunityContactRole> oppContactWrap {get;set;}
        public list<Account_Service_Role__c> accContactWrap {get;set;}
        public list<Account_Service_Role__c> driveRolesWrap {get;set;}
        public Date wbEligibilityWrap {get;set;}
        public Date prEligibilityWrap {get;set;}
        public list<Account_Marketing_Program__c> accAffiliationWrap {get; set;}
        public list<Drive_Marketing_Programs__c> driveAffiliationWrap {get; set;}
        public list<OrderWrapper> orderListWrap {get; set;}
        public list<Task> taskListWrap {get; set;}
        public list<DriveWrapper> pastDriveListWrap {get;set;}
        public list<DriveWrapper> futureDriveListWrap {get;set;}
        public list<sked__Account_Tag__c> accountTags {get;set;}
        public list<sked_Location_Tag__c> siteTags {get;set;}
        public list<Note> accNoteWrap {get;set;}
        public list<Note> oppNoteWrap {get;set;}
        public list<Note> siteNoteWrap {get;set;}
        public Decimal redcrossVolunteerQ {get;set;}
        public Decimal sponsorVolunteerQ {get;set;}
        OpportunityContactRole oppConRoleWrap;
    }
    
    class userWrapper{
        public String NameWrap {get;set;}
        public String PhoneWrap {get;set;}
        public String EmailWrap {get;set;}
    }

    class OrderWrapper{
        public Order orderDetails {get;set;}
        public list<OrderItem> orderItemList {get; set;}
    }

    class ShiftWrapper{
        public String name {get;set;}
        public String rbcProc {get;set;}
        public String rbcProd {get;set;}
        public String wbProc {get;set;}
        public String wbProd {get;set;}
        public String totalProc {get;set;}
        public String totalProd {get;set;}
        public String lunchBreak {get;set;}
        public String shiftHour {get;set;}
    }

    class DriveWrapper{
        public String Name {get;set;}
        public String driveDate {get;set;}
        public String driveStartTime {get;set;}
        public String driveEndTime {get;set;}
        public String addDescription {get;set;}
        public String primaryContact {get;set;}
        public String driveStatus {get;set;}
        public String driveStage {get;set;}
    }
    
    public list<ReportQueryWrapper> ReportQueryWrapperList {get; set;} 
    set<String> accNameList = new set<String>();
    set<Id> oppTeamId = new set<Id>();
    
    set<Id> accId = new set<Id>();
    
    map<Id,list<Account_Marketing_Program__c>> getAffiliations(list<Opportunity> selectedOppList, Boolean isPremier, Set<Id> accId){
        map<Id,list<Account_Marketing_Program__c>> affiliationMap = new map<Id,list<Account_Marketing_Program__c>>();
        map<Id,list<Account_Marketing_Program__c>> accIdMap = new map<Id,list<Account_Marketing_Program__c>>();
        List<Account_Marketing_Program__c> affiliationList = new List<Account_Marketing_Program__c>();
        if(isPremier == false || isPremier == null){
            affiliationList = [SELECT Id, 
                                        Name, 
                                        Marketing_Program__r.Name,
                                        Account__c, 
                                        Account__r.name 
                                FROM Account_Marketing_Program__c
                                WHERE Account__c In: accId];
        }else{
            affiliationList = [SELECT Id, 
                                        Name, 
                                        Marketing_Program__r.Name,
                                        Account__c, 
                                        Account__r.name 
                                FROM Account_Marketing_Program__c
                                WHERE Account__c In: accId
                                AND Marketing_Program__r.Name Like '%Premier Current%'];
        }
        for(Account_Marketing_Program__c amp :  affiliationList){
            if(!accIdMap.containsKey(amp.Account__c)){
                accIdMap.put(amp.Account__c, new list<Account_Marketing_Program__c>());
            }
            accIdMap.get(amp.Account__c).add(amp);
        }
        for(opportunity opp: selectedOppList){
            if(!affiliationMap.containsKey(opp.Id)){
                affiliationMap.put(opp.Id, new list<Account_Marketing_Program__c>());
            }
            if(accIdMap.containsKey(opp.AccountId)){
                for(Account_Marketing_Program__c amp :  accIdMap.get(opp.AccountId)){
                    affiliationMap.get(opp.Id).add(amp);
                }
            }
        } 
        return  affiliationMap;       
    }
    
    map<Id,list<OpportunityContactRole>>  getContacts( String Role, set<Id> opId){
        
        map<Id,list<OpportunityContactRole>> oppIdWithContactMap = new map<Id,list<OpportunityContactRole>>();
        list<OpportunityContactRole> oppConList = new list<OpportunityContactRole>();
        if(Role == ''){
            oppConList = [Select ContactId, role, OpportunityId, Contact.Name, Contact.Email, Contact.Primary_Phone_Number_New__c from OpportunityContactRole
                          where OpportunityId IN:opId];
        }else{
            oppConList  =  [Select ContactId, role, OpportunityId, Contact.Name, Contact.Email, Contact.Primary_Phone_Number_New__c, Contact.After_Hours_Number__c from OpportunityContactRole
                            where OpportunityId IN:opId and role =: Role];
        }
        
        for(OpportunityContactRole con: oppConList){
            if(!oppIdWithContactMap.containsKey(con.OpportunityId)){
                oppIdWithContactMap.put(con.OpportunityId, new list<OpportunityContactRole>());
            }
            oppIdWithContactMap.get(con.OpportunityId).add(con);
        }
        return oppIdWithContactMap;
    }
    
    List<Note> getNotes(set<Id> pId){
        return [SELECT Id, ParentId, Title FROM Note where ParentId In: pId];
    }
    
    map<Id,userWrapper> getUser(String role, Set<Id> oppIdSet){
        
        map<Id, user> oppIdWithUser = new  map<Id, user>();
        list<OpportunityTeamMember> oppTeamMember = [SELECT Id, OpportunityId, User.Name,User.Email,
                                                     User.Phone FROM OpportunityTeamMember 
                                                     where OpportunityId In: oppIdSet And TeamMemberRole =: role];
        
        map<Id,userWrapper> oppIdWithTeamName = new map<Id,userWrapper> ();
        for(OpportunityTeamMember team: oppTeamMember){
            userWrapper userWrapperObj = new userWrapper();
            userWrapperObj.NameWrap = team.User.Name;
            userWrapperObj.EmailWrap = team.User.Email;
            userWrapperObj.PhoneWrap = team.User.Phone;                
            oppIdWithTeamName.put(team.OpportunityId, userWrapperObj);     
        }
        return oppIdWithTeamName;
    }
    
    public void getDataforPdf (List<Id> oppIds) {
        try{
            ReportQueryWrapperList = new  list<ReportQueryWrapper>();  
            list<Opportunity>  selectedOppList = new list<Opportunity>();   
            
            set<Id> oppId = new set<Id>();
            set<Id> siteId = new set<Id>();
            map<Id, Id> oppIdAccId = new map<Id,Id>();
            map<Id, Id> oppIdSiteId = new map<Id,Id>();
            map<Id, list<Decimal>> oppDriveTime = new map<Id, list<Decimal>>();
            map<Id, Date> oppIdWithWbElg = new map<Id, Date>();
            map<Id, Date> oppIdWithPrElg = new map<Id, Date>();
            selectedOppList = [select Id,Name,Account_Manager__c,AccountId,Drive_Name__c,Additional_Description__c,
            Additional_Drive_Logistics__c,Drive_Date__c,Call_List_Recipient_Exist__c,Start_Time__c, Direct_Donors_To__c,
            Anticipated_Registered_Donors_Template__c, X2RBC_Projected_Procedures__c, Total_Products_Projected__c,
            CDA_O_Positive__c,Total_Products_Projected_Template__c,Security_Escort_Name__c, DriveStatus__c,
            CDA_O_Negative__c, WholeBloodProceduresProjectedTemplate__c, Double_Red_Procedures_Projected_Template__c,
        End_Time__c,Web_Schedule_StartDate__c, Web_Schedule_EndDate__c ,Online_Donor_Message__c,Drive_Keyword__c,                                          
        WB_Projected_Procedures__c,Publish_to_Call_Center__c, Online_Scheduling_Enabled__c,Anticipated_Registered_Donors__c,
        Account.Name, Account.Military_Authority_Name__c,Send_Emails__c,Send_Mailers__c, Account.Contact_BPL__c,Account.Contact_BPL__r.Name,
        Drive_Site__r.sked_Site_Contact_Email__c, Parent_Template_Id__c, Parent_Template_Id__r.Additional_Description__c,
        Account.Next_Scheduled_Drive_Updated__c,Account.Sponsor_Declines_Online_Scheduling__c, Drive_Site__r.sked_No_Cell_Phones__c,
        Drive_Site__r.Id, Drive_Site__r.Name, Drive_Site__r.sked_Room_Name__c, Drive_Site__r.sked_Site_Contact__c,Drive_Site__r.sked_Site_Contact__r.Name,
        Drive_Site__r.sked__Address__c,Drive_Site__r.sked_Site_Contact_Phone__c, Drive_Site__r.sked_Site_Inspection_Completed_By__r.Name,
        Drive_Site__r.sked_Wireless_Policy__c,Drive_Site__r.sked_Directions_From_CollectionOperation__c,
        Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c, Drive_Site__r.sked_Pay_for_Parking_Details__c,
        Drive_Site__r.sked_Escort_Required__c,Drive_Site__r.Sponsor_Security_Form_Required__c,
        Drive_Site__r.sked_Collection_Operation_Name__c, Drive_Site__r.sked_Floor_Description__c,
        Drive_Site__r.sked_Staff_Personal_Parking_Directions__c, Drive_Site__r.sked_Equipment_X_Ray_Required__c, 
        Drive_Site__r.sked_Security_Directions__c,Drive_Site__r.sked_Staff_List__c, Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c,	
        Drive_Site__r.sked_Date_Site_Inspection_Completed__c,Drive_Site__r.sked_Outside_stairs__c,
        Drive_Site__r.sked_Room_Size__c,Drive_Site__r.sked_Inside_stairs__c, Drive_Site__r.sked_Elevator_Type__c,
        Drive_Site__r.sked_110_outlets__c,Drive_Site__r.sked_Site_Close__c, Drive_Site__r.sked_Security_Information_Needed__c,
        Drive_Site__r.sked_Emergency_Contact__r.Name, Drive_Site__r.sked_Safety_Emergency_Action_Plan__c,
        Drive_Site__r.sked_Automation_Suitability__c,Drive_Site__r.sked_Elevator_Close__c,Drive_Site__r.sked_Elevator_Open__c,
        Drive_Site__r.sked_Break_location__c,Drive_Site__r.sked_Maximum_Beds__c,Drive_Site__r.sked_Unloading_Conditions__c,
        Drive_Site__r.sked_Floor_Covering_Requirement__c,Drive_Site__r.sked_Max_Auto_Machines__c,
        Drive_Site__r.sked_Canteen_Requirements__c,Drive_Site__r.sked_Air_conditioned__c, Drive_Site__r.sked_Unloading_Directions_Details__c,
        Drive_Site__r.sked_Site_Inspection_Completed_By__c , Drive_Site__r.sked_Site_Inspection_Comments__c,
        Drive_Site__r.Emergency_Contact__c, Drive_Site__r.sked_On_Site_Food_Canteen_Requirements__c,
        Drive_Site__r.sked_Site_Main_Phone__c,Drive_Site__r.sked_Site_Open__c,
        Drive_Site__r.sked_Heat__c,Drive_Site__r.sked_Restroom_Location__c from opportunity Where Id IN: oppIds];
            for(opportunity opp: selectedOppList){
                accId.add(opp.AccountId);
                oppId.add(opp.Id);
                siteId.add(opp.Drive_Site__c);
                oppIdAccId.put(opp.AccountId,opp.Id);
                oppIdSiteId.put(opp.drive_site__c, opp.Id);
                if(opp.Drive_Date__c != null){
                    oppIdWithWbElg.put(opp.Id,opp.Drive_Date__c.addDays(-56));	// Current Drive WB Eligibility
                    oppIdWithPrElg.put(opp.Id,opp.Drive_Date__c.addDays(-112)); //Current Drive PR Eligibility
                }       
            }
            /* Account External Id Part */
            map<Id, AccountBridgeAPI__x> oppIdWithExternalIdMap = new  map<Id, AccountBridgeAPI__x>();
            map<Id,AccountBridgeAPI__x> accExternalMap; 
            try{
                accExternalMap = new  map<Id, AccountBridgeAPI__x>([SELECT Id, guid__c, ExternalId FROM AccountBridgeAPI__x
                                                                    Where guid__c In: accId]);
            }catch(Exception e){
                system.debug(e.getMessage());
            }
            for(opportunity opp: selectedOppList){
                if(accExternalMap != null){
                    if(accExternalMap.containsKey(opp.AccountId)){
                        oppIdWithExternalIdMap.put(opp.Id, oppIdWithExternalIdMap.get(opp.AccountId));
                    }
                }          
            }   
            
            /* Account Affiliation Part */
            /* Premier Affiliation */
            map<Id,list<Account_Marketing_Program__c>> oppIdWithPremierAffiliationMap = getAffiliations(selectedOppList,true,accId);
            map<Id,list<Account_Marketing_Program__c>> oppIdWithAffiliationMap = getAffiliations(selectedOppList,false,accId);
            
            
            /* Contact Section */
            
            map<Id,list<OpportunityContactRole>> afterHoursContact = getContacts('After Hours Contact', oppId);
            
            map<Id,list<OpportunityContactRole>> whoomToMeetContact = getContacts('Whom to Meet', oppId);
            
            map<Id,list<OpportunityContactRole>> oppContact = getContacts('', oppId);  
            
            map<Id, list<Account_Service_Role__c>> oppIdWithAccConMap = new  map<Id, list<Account_Service_Role__c>> ();
            map<Id, list<Account_Service_Role__c>> driveRoleAccConMap = new  map<Id, list<Account_Service_Role__c>> ();
            list<Account_Service_Role__c> accCon = [Select Name,Contact__r.Name,Account_Service_Role__c,Account__c, Account__r.Name
                                                    from Account_Service_Role__c
                                                    where Account__c In:accId];
            for(Account_Service_Role__c ac: accCon){
                if (!oppIdWithAccConMap.containsKey(oppIdAccId.get(ac.Account__c))){
                    oppIdWithAccConMap.put(oppIdAccId.get(ac.Account__c), new list<Account_Service_Role__c>{ac}); 
                }else{
                    List<Account_Service_Role__c> templist = oppIdWithAccConMap.get(oppIdAccId.get(ac.Account__c));
                    templist.add(ac);
                    oppIdWithAccConMap.put(oppIdAccId.get(ac.Account__c),templist);
                }
                if(String.isBlank(ac.Account_Service_Role__c) || !ac.Account_Service_Role__c.equalsIgnoreCase('Account Contact')){
                    if (!driveRoleAccConMap.containsKey(oppIdAccId.get(ac.Account__c))){
                        driveRoleAccConMap.put(oppIdAccId.get(ac.Account__c), new list<Account_Service_Role__c>{ac}); 
                    }else{
                        List<Account_Service_Role__c> templist = driveRoleAccConMap.get(oppIdAccId.get(ac.Account__c));
                        templist.add(ac);
                        driveRoleAccConMap.put(oppIdAccId.get(ac.Account__c),templist);
                    }
                }
            }

            Map<Id, List<sked__Account_Tag__c>> mapAccountIdVsTags = new Map<Id, List<sked__Account_Tag__c>>();
            List<sked__Account_Tag__c> accountTags = [Select Id, Name, sked__Account__c,sked__Account__r.Name, sked_Minimum_Quantity__c From sked__Account_Tag__c Where sked__Account__c IN: accId];
            if (accountTags.size() > 0) {
                for (sked__Account_Tag__c atags : accountTags) {
                    if (!mapAccountIdVsTags.containsKey(atags.sked__Account__c)) {
                        mapAccountIdVsTags.put(atags.sked__Account__c, new List<sked__Account_Tag__c>());
                    }
                    mapAccountIdVsTags.get(atags.sked__Account__c).add(atags);
                }
            }

            Map<Id, List<sked_Location_Tag__c>> mapLocationIdVsTags = new Map<Id, List<sked_Location_Tag__c>>();
            List<sked_Location_Tag__c> locationTags = [Select Id, Name, sked_Location__c,sked_Location__r.name, sked_Minimum_Quantity__c From sked_Location_Tag__c Where sked_Location__c IN: siteId];
            if (locationTags.size() > 0) {
                for (sked_Location_Tag__c ltags : locationTags) {
                    if (!mapLocationIdVsTags.containsKey(ltags.sked_Location__c)) {
                        mapLocationIdVsTags.put(ltags.sked_Location__c, new List<sked_Location_Tag__c>());
                    }
                    mapLocationIdVsTags.get(ltags.sked_Location__c).add(ltags);
                }
            }
            
            /* Drives on Calender Part */
            
            map<Id, list<sked_Drive__c>> oppIdWithDriveMap = new  map<Id, list<sked_Drive__c>>();
            map<Id, list<sked_Drive_Shift__c>> oppIdWithShiftMap = new  map<Id, list<sked_Drive_Shift__c>>();
            map<Id, list<Opportunity>> accIdWithPastFutureDriveMap = new  map<Id, list<Opportunity>>();
            map<Id, String> oppIdWithPrimaryContactMap = new  map<Id, String>();
            
            map<Id,Id> driveIdWithOppIdMap = new map<Id,Id>();
            map<Id, list<Decimal>> oppIdWithLunchBrkTime = new map<Id, List<Decimal>>();
            map<Id, list<String>> oppIdWithLunchBrkTimeMap = new map<Id, List<String>>();
            List<sked_Drive__c> driveList = [SELECT Id, sked_UFID__c , sked_Opportunity__c,sked_Stage__c,sked_Total_Slots__c,
            sked_Drive_Productivity_Actual__c, sked_Drive_Productivity_Planned__c, sked_Primary_Contact__c,sked_Start_Time__c,
            sked_Opportunity__r.Flow_End_Time_Label_Text__c, sked_Opportunity__r.Flow_Start_Time_Label_Text__c,
            sked_Primary_Contact__r.Email,sked_Primary_Contact__r.Phone, sked_Primary_Contact__r.Primary_Phone_Number_New__c, sked_End_Time__c,
            sked_No_of_Scheduled_Appointments__c,sked_Drive_Date__c,Name,sked_Opportunity__r.Additional_Description__c,
            sked_Primary_Contact__r.Name FROM sked_Drive__c
            where sked_Opportunity__c In : oppId];
            List<sked_Drive_Shift__c> shiftData = [SELECT Id,
                                                            Name,
                                                            sked_Max_Donor_Capacity__c,
                                                            sked_2RBC_Projected_Procedures__c,
                                                            sked_WB_Projected_Procedures__c,
                                                            sked_Staff_Setup__c,
                                                            sked_Equipment_Allocated__c,
                                                            sked_Lunch_Break_Start_Time__c,
                                                            sked_Lunch_Break_End_Time__c,
                                                            sked_Drive__c,
                                                            sked_Drive__r.sked_Opportunity__c,
                                                            sked_Drive__r.sked_Drive_Site__c,
                                                            sked_Drive__r.sked_Account__c,
                                                            sked_Drive_Account__c,
                                                            sked_Drive_Shift_Name__c,
                                                            sked_Start_Time__c,
                                                            sked_End_Time__c 
                                                FROM sked_Drive_Shift__c 
                                                WHERE sked_Drive__r.sked_Opportunity__c IN: oppId
                                                ORDER BY Name ASC NULLS LAST];
                List<Opportunity> pastAndFutureDrives = [SELECT Id, 
                                                                Drive_Date__c, 
                                                                DriveStatus__c, 
                                                                StageName, 
                                                                Additional_Description__c, 
                                                                Parent_Template_Id__c,
                                                                Parent_Template_Id__r.Additional_Description__c,
                                                                Start_Time__c, 
                                                                End_Time__c,
                                                                Name,
                                                                AccountId
                                                            FROM Opportunity 
                                                            WHERE AccountId IN:accId
                                                            ORDER BY Drive_Date__c ASC NULLS LAST];
                    for(Opportunity opt : pastAndFutureDrives){
                        if (!accIdWithPastFutureDriveMap.containsKey(opt.AccountId)){
                            accIdWithPastFutureDriveMap.put(opt.AccountId, new list<Opportunity>());     
                        }
                        accIdWithPastFutureDriveMap.get(opt.AccountId).add(opt);
                        oppIdWithPrimaryContactMap.put(opt.Id, '');
                    }
                    if(oppIdWithPrimaryContactMap.size() > 0){
                        List<sked_Drive__c> driveForPCList = [SELECT Id, 
                                                                    sked_Primary_Contact__c, 
                                                                    sked_Primary_Contact__r.Name,
                                                                    sked_Opportunity__c
                                                                FROM sked_Drive__c 
                                                                WHERE sked_Opportunity__c IN: oppIdWithPrimaryContactMap.keySet()
                                                                AND sked_Primary_Contact__c != null];    
                        for(sked_Drive__c drv : driveForPCList){
                            oppIdWithPrimaryContactMap.put(drv.sked_Opportunity__c, drv.sked_Primary_Contact__r.Name);
                        }
                    }                              
                    for(sked_Drive__c drive: driveList){
                        system.debug('drive'+drive);
                        if (!oppIdWithDriveMap.containsKey(drive.sked_Opportunity__c)){
                            oppIdWithDriveMap.put(drive.sked_Opportunity__c, new list<sked_Drive__c>());     
                        }
                        oppIdWithDriveMap.get(drive.sked_Opportunity__c).add(drive);
                        if(!oppIdWithLunchBrkTime.containsKey(drive.sked_Opportunity__c)){
                            oppIdWithLunchBrkTime.put(drive.sked_Opportunity__c, new List<Decimal>());
                        }
                        if(!oppIdWithLunchBrkTimeMap.containsKey(drive.sked_Opportunity__c)){
                        oppIdWithLunchBrkTimeMap.put(drive.sked_Opportunity__c, new List<String>());
                        }
                        if(drive.sked_End_Time__c != null && drive.sked_Start_Time__c != null){
                            Long timeAvailable = (drive.sked_End_Time__c.hour() * 60 + drive.sked_End_Time__c.minute()) -(drive.sked_Start_Time__c.hour() * 60 + drive.sked_Start_Time__c.minute());
                            Decimal hours = timeAvailable/3600000;
                            String timeStamp = getFormattedTime(drive.sked_Start_Time__c.hour(),drive.sked_Start_Time__c.minute())+' - '+getFormattedTime(drive.sked_End_Time__c.hour(),drive.sked_End_Time__c.minute());
                            oppIdWithLunchBrkTime.get(drive.sked_Opportunity__c).add(hours);
                            oppIdWithLunchBrkTimeMap.get(drive.sked_Opportunity__c).add(timeStamp);
                        }
                        driveIdWithOppIdMap.put(drive.Id, drive.sked_Opportunity__c);

                        /*if(drive.sked_Drive_Date__c >= system.today() && drive.sked_Drive_Date__c <= system.today().addMonths(12)){
                            if (!oppIdWithFutureDriveMap.containsKey(drive.sked_Opportunity__c)){
                                oppIdWithFutureDriveMap.put(drive.sked_Opportunity__c, new list<sked_Drive__c>());     
                            }
                            oppIdWithFutureDriveMap.get(drive.sked_Opportunity__c).add(drive);
                        }else{
                            if (!oppIdWithPastDriveMap.containsKey(drive.sked_Opportunity__c)){
                                oppIdWithPastDriveMap.put(drive.sked_Opportunity__c, new list<sked_Drive__c>());     
                            }
                            oppIdWithPastDriveMap.get(drive.sked_Opportunity__c).add(drive);
                        }*/
                    }
                    for(sked_Drive_Shift__c sft : shiftData){
                        if (!oppIdWithShiftMap.containsKey(sft.sked_Drive__r.sked_Opportunity__c)){
                            oppIdWithShiftMap.put(sft.sked_Drive__r.sked_Opportunity__c, new list<sked_Drive_Shift__c>{sft});     
                        }else{
                            oppIdWithShiftMap.get(sft.sked_Drive__r.sked_Opportunity__c).add(sft);
                        }
                    }
            
            /* Primary Account Manager Part */

            map<Id,userWrapper> getPrimaryCon = getUser('Account Manager', oppId);
            
            /* Area Booking Manager Part */
            
            map<Id,userWrapper> getABM = getUser('Area Booking Manager', oppId);
            
            /* Job Object */
            map<Id, list<sked__Job__c>> jobWithOppIdMap =  new  map<Id, list<sked__Job__c>>();
            map<Id, Decimal> donorCapacityMap = new map<Id, Decimal>();
            Decimal max_setup = 0;
            String setupTime='';
            list<sked__Job__c> jobList = [Select sked_Setup_Time__c, sked_Breakdown_Time__c,sked_Drive__c,sked_Drive__r.sked_Start_Time__c, sked_Sponsor_Volunteer_Quantity__c,sked_Redcross_Volunteer_Quantity__c, sked__Type__c, sked_Drive_Shift__r.Name,
            sked_Drive_Shift__r.sked_Max_Donor_Capacity__c,Id from sked__Job__c Where sked_Drive__c In:driveIdWithOppIdMap.keySet()];
            for(sked__Job__c job: jobList){
                if(!jobWithOppIdMap.containsKey(driveIdWithOppIdMap.get(job.sked_Drive__c))){
                    jobWithOppIdMap.put(driveIdWithOppIdMap.get(job.sked_Drive__c), new list<sked__Job__c>{job});
                }
                else{
                    jobWithOppIdMap.get(driveIdWithOppIdMap.get(job.sked_Drive__c)).add(job);
                }
            }

            for(sked__Job__c job : jobList){
                if(job.sked_Setup_Time__c != null && job.sked_Setup_Time__c > max_setup){
                    max_setup = job.sked_Setup_Time__c;     
                }
                if(max_setup > 0 && job.sked_Drive__r.sked_Start_Time__c != null){
                    Integer ms = Integer.valueOf(0 - max_setup);
                setupTime = getFormattedTime(job.sked_Drive__r.sked_Start_Time__c.addMinutes(ms).hour(),job.sked_Drive__r.sked_Start_Time__c.addMinutes(ms).minute());
                }
            }

            for(Id key: jobWithOppIdMap.keySet()){
                List<sked__Job__c> jblist = jobWithOppIdMap.get(key);
                Decimal maxValue = 0;
                for(sked__Job__c job : jblist){
                    if(job.sked_Drive_Shift__r.sked_Max_Donor_Capacity__c > maxValue){
                        maxValue = job.sked_Drive_Shift__r.sked_Max_Donor_Capacity__c;
                    }
                }
                donorCapacityMap.put(key,maxValue);
            }

            
            /* Drive Affiliation Section */
            map<Id, list<Drive_Marketing_Programs__c>> oppIdWithDriveAffMap = new map<Id, list<Drive_Marketing_Programs__c>>(); 
            list<Drive_Marketing_Programs__c> driveAffList = [Select Name, Marketing_Program__r.Name,Blood_Drive_Opportunity__c 
                                                            From Drive_Marketing_Programs__c
                                                            Where Blood_Drive_Opportunity__c In:oppId];
            System.debug('driveAffList ## '+driveAffList);
            for(Drive_Marketing_Programs__c dmp: driveAffList){
                if(!oppIdWithDriveAffMap.containsKey(dmp.Blood_Drive_Opportunity__c)){
                    oppIdWithDriveAffMap.put(dmp.Blood_Drive_Opportunity__c, new list<Drive_Marketing_Programs__c>{dmp});            
                }else{
                    oppIdWithDriveAffMap.get(dmp.Blood_Drive_Opportunity__c).add(dmp);            
                }
            }
            
            /* Order Section */
            Map<Id, List<OrderItem>> orderIdWithOrderItemMap = new  Map<Id, List<OrderItem>>();
            Map<Id, List<Order>> oppIdWithOrderMap = new  Map<Id, List<Order>>();
            list<OrderItem> ordProdList = [Select OrderId,Quantity,TotalPrice,Product2.Name,Order.OpportunityId,Order.Comments__c, Order.Local_Recruitment_Request_Need_by_Date__c,
            Order.Local_Recruitment_Request__c, Order.BudgetCurrency__c, Order.OrderNumber From OrderItem Where OrderId IN: [Select OpportunityId,Id From Order Where OpportunityId IN: oppId]];
            list<Order> ordList = [Select Comments__c, Local_Recruitment_Request_Need_by_Date__c , OrderNumber,
            Local_Recruitment_Request__c, BudgetCurrency__c, OpportunityId  From Order Where OpportunityId IN: oppId];
            for(OrderItem odi: ordProdList){
                if(!orderIdWithOrderItemMap.containsKey(odi.OrderId)){
                    orderIdWithOrderItemMap.put(odi.OrderId, new list<OrderItem>{odi});            
                }else{
                    orderIdWithOrderItemMap.get(odi.OrderId).add(odi);             
                }
            }
            System.debug('orderIdWithOrderItemMap ## '+orderIdWithOrderItemMap);
            for(Order odl: ordList){
                if(!oppIdWithOrderMap.containsKey(odl.OpportunityId)){
                    oppIdWithOrderMap.put(odl.OpportunityId, new list<Order>{odl});            
                }else{
                    oppIdWithOrderMap.get(odl.OpportunityId).add(odl);            
                }
            }
            
            /* Task Section */
            map<Id, List<Task>> oppIdWithTaskMap =  new map<Id, List<Task>>();
            list<Task> taskList = [Select Status, Subject,ActivityDate,WhatId From Task Where WhatId In: oppId];
            for(task t: taskList){
                if(!oppIdWithTaskMap.containsKey(t.WhatId)){
                    oppIdWithTaskMap.put(t.WhatId, new list<Task>{t});            
                }else{
                    oppIdWithTaskMap.get(t.WhatId).add(t);            
                }
            }
            
            /* Notes Section */
            
            List<Note> accNote =  getNotes(accId);
            system.debug('note@ accNote ' + accNote);
            map<Id,list<Note>> accOppIdWithNote = new  map<Id,list<Note>>();
            
            for(Note n: accNote){
                if(!accOppIdWithNote.containsKey(oppIdAccId.get(n.ParentId))){
                    accOppIdWithNote.put(oppIdAccId.get(n.ParentId),new list<note>());
                }else{
                    accOppIdWithNote.get(oppIdAccId.get(n.ParentId)).add(n);
                }
                system.debug('note@ accOppIdWithNote ' + accOppIdWithNote);
            }
            
            
            List<Note> oppNote =getNotes(oppId);
            map<Id,list<Note>> oppIdWithNote = new  map<Id,list<Note>>();
            for(Note n: oppNote){
                if(!oppIdWithNote.containsKey(n.ParentId)){
                    oppIdWithNote.put(n.ParentId,new list<note>());
                }else{
                    oppIdWithNote.get(n.ParentId).add(n);
                }
            }
            
            List<Note> siteNote =getNotes(siteId);
            map<Id,list<Note>> siteOppIdWithNote = new  map<Id,list<Note>>();
            for(Note n: oppNote){
                if(!siteOppIdWithNote.containsKey(n.ParentId)){
                    siteOppIdWithNote.put(oppIdSiteId.get(n.ParentId),new list<note>());
                }else{
                    siteOppIdWithNote.get(oppIdSiteId.get(n.ParentId)).add(n);
                }
            }
            
            /* Creating final List */
            
            for(opportunity opp: selectedOppList){
                ReportQueryWrapper ReportQueryWrapperObj = new ReportQueryWrapper();
                ReportQueryWrapperObj.oppWrap = opp; 
                ReportQueryWrapperObj.startTime = opp.Start_Time__c != null ? getFormattedTime(opp.Start_Time__c.hour(),opp.Start_Time__c.minute()) : ''; 
                ReportQueryWrapperObj.endTime = opp.End_Time__c != null ? getFormattedTime(opp.End_Time__c.hour(),opp.End_Time__c.minute()) : ''; 
                ReportQueryWrapperObj.elevatorOpenTime = opp.Drive_Site__r.sked_Elevator_Open__c != null ? getFormattedTime(opp.Drive_Site__r.sked_Elevator_Open__c.hour(),opp.Drive_Site__r.sked_Elevator_Open__c.minute()) : ''; 
                ReportQueryWrapperObj.elevatorCloseTime = opp.Drive_Site__r.sked_Elevator_Close__c != null ? getFormattedTime(opp.Drive_Site__r.sked_Elevator_Close__c.hour(),opp.Drive_Site__r.sked_Elevator_Close__c.minute()) : ''; 
                ReportQueryWrapperObj.siteOpenTime = opp.Drive_Site__r.sked_Site_Open__c != null ? getFormattedTime(opp.Drive_Site__r.sked_Site_Open__c.hour(),opp.Drive_Site__r.sked_Site_Open__c.minute()) : ''; 
                ReportQueryWrapperObj.siteCloseTime = opp.Drive_Site__r.sked_Site_Close__c != null ? getFormattedTime(opp.Drive_Site__r.sked_Site_Close__c.hour(),opp.Drive_Site__r.sked_Site_Close__c.minute()) : ''; 
                ReportQueryWrapperObj.setupTimeWrap = setupTime;
                ReportQueryWrapperObj.apiWrap = oppIdWithExternalIdMap.get(opp.Id);
                ReportQueryWrapperObj.accPremierAffiliationWrap = oppIdWithPremierAffiliationMap.get(opp.Id);
                ReportQueryWrapperObj.driveListWrap = oppIdWithDriveMap.get(opp.Id);
                ReportQueryWrapperObj.shiftListWrap = oppIdWithShiftMap.get(opp.Id);
                ReportQueryWrapperObj.shiftListWrap2 = new List<ShiftWrapper>();
                if(ReportQueryWrapperObj.shiftListWrap != null){
                    for(sked_Drive_Shift__c sft : ReportQueryWrapperObj.shiftListWrap){
                        ShiftWrapper sftwr = new ShiftWrapper();
                        sftwr.name = sft.Name;
                        sftwr.rbcProc = sft.sked_2RBC_Projected_Procedures__c != null ? String.valueOf(roundDecimals(sft.sked_2RBC_Projected_Procedures__c)) : '0';
                        sftwr.rbcProd = sft.sked_2RBC_Projected_Procedures__c != null ? String.valueOf(2*roundDecimals(sft.sked_2RBC_Projected_Procedures__c)) : '0';
                        sftwr.wbProc = sft.sked_WB_Projected_Procedures__c != null ? String.valueOf(roundDecimals(sft.sked_WB_Projected_Procedures__c)) : '0';
                        sftwr.wbProd = sft.sked_WB_Projected_Procedures__c != null ? String.valueOf(roundDecimals(sft.sked_WB_Projected_Procedures__c)) : '0';
                        sftwr.totalProc = String.valueOf(Integer.valueOf(sftwr.rbcProc) + Integer.valueOf(sftwr.wbProc));
                        sftwr.totalProd = String.valueOf(Integer.valueOf(sftwr.rbcProd) + Integer.valueOf(sftwr.wbProd));
                        sftwr.lunchBreak = '';
                        if(sft.sked_Lunch_Break_Start_Time__c != null){
                            sftwr.lunchBreak = getFormattedTime(sft.sked_Lunch_Break_Start_Time__c.hour(),sft.sked_Lunch_Break_Start_Time__c.minute());
                        }
                        if(sft.sked_Lunch_Break_End_Time__c != null){
                            sftwr.lunchBreak = sftwr.lunchBreak + ' - ' + getFormattedTime(sft.sked_Lunch_Break_End_Time__c.hour(),sft.sked_Lunch_Break_End_Time__c.minute());
                        }
                        sftwr.shiftHour = '';
                        if(sft.sked_Start_Time__c != null){
                            sftwr.shiftHour = getFormattedTime(sft.sked_Start_Time__c.hour(),sft.sked_Start_Time__c.minute());
                        }
                        if(sft.sked_End_Time__c != null){
                            sftwr.shiftHour = sftwr.shiftHour + ' - ' + getFormattedTime(sft.sked_End_Time__c.hour(),sft.sked_End_Time__c.minute());
                        }
                        ReportQueryWrapperObj.shiftListWrap2.add(sftwr);
                    }
                }
                System.debug(oppIdWithPremierAffiliationMap);
                System.debug(opp.Id);
                ReportQueryWrapperObj.accountTags = mapAccountIdVsTags.get(opp.AccountId);
                ReportQueryWrapperObj.siteTags = mapLocationIdVsTags.get(opp.Drive_Site__c);
                ReportQueryWrapperObj.primaryConListWrap = getPrimaryCon.get(opp.Id);
                ReportQueryWrapperObj.ABMListWrap = getABM.get(opp.Id);
                ReportQueryWrapperObj.jobListWrap = jobWithOppIdMap.get(opp.Id);
                if(ReportQueryWrapperObj.jobListWrap != null){
                    ReportQueryWrapperObj.redcrossVolunteerQ = 0;
                    ReportQueryWrapperObj.sponsorVolunteerQ = 0;
                    for(sked__Job__c jbs : ReportQueryWrapperObj.jobListWrap){
                        if((jbs.sked_Redcross_Volunteer_Quantity__c != null) && (ReportQueryWrapperObj.redcrossVolunteerQ < jbs.sked_Redcross_Volunteer_Quantity__c)){
                            ReportQueryWrapperObj.redcrossVolunteerQ = jbs.sked_Redcross_Volunteer_Quantity__c;
                        }
                        if((jbs.sked_Sponsor_Volunteer_Quantity__c != null) && (ReportQueryWrapperObj.sponsorVolunteerQ < jbs.sked_Sponsor_Volunteer_Quantity__c)){
                            ReportQueryWrapperObj.sponsorVolunteerQ = jbs.sked_Sponsor_Volunteer_Quantity__c;
                        }
                    }
                }
                ReportQueryWrapperObj.maxDonorCapacity = donorCapacityMap.get(opp.Id);
                ReportQueryWrapperObj.lunchBrkDurationWrap = oppIdWithLunchBrkTime.get(opp.Id);
                ReportQueryWrapperObj.lunchBrkDurationTime = oppIdWithLunchBrkTimeMap.get(opp.Id);
                ReportQueryWrapperObj.afterHoursWrap = afterHoursContact.get(opp.Id);
                ReportQueryWrapperObj.whoomToMeetWrap = whoomToMeetContact.get(opp.Id);
                ReportQueryWrapperObj.oppContactWrap = oppContact.get(opp.Id);
                ReportQueryWrapperObj.accContactWrap = oppIdWithAccConMap.get(opp.Id);
                ReportQueryWrapperObj.driveRolesWrap = driveRoleAccConMap.get(opp.Id);
                ReportQueryWrapperObj.wbEligibilityWrap = oppIdWithWbElg.get(opp.Id);
                ReportQueryWrapperObj.prEligibilityWrap = oppIdWithPrElg.get(opp.Id);
                ReportQueryWrapperObj.accAffiliationWrap = oppIdWithAffiliationMap.get(Opp.Id);
                ReportQueryWrapperObj.driveAffiliationWrap =oppIdWithDriveAffMap.get(Opp.Id);
                System.debug('driveAffiliationWrap ## '+ReportQueryWrapperObj.driveAffiliationWrap);
                ReportQueryWrapperObj.orderListWrap = new list<OrderWrapper>();
                if(oppIdWithOrderMap.get(Opp.Id) != null){
                    for(Order odr : oppIdWithOrderMap.get(Opp.Id)){
                        OrderWrapper odrWrapper  = new OrderWrapper();
                        odrWrapper.orderDetails = odr;
                        odrWrapper.orderItemList = orderIdWithOrderItemMap.get(odr.id);
                        ReportQueryWrapperObj.orderListWrap.add(odrWrapper);
                        System.debug('orderListWrap ## '+odrWrapper);
                    }
                }
                ReportQueryWrapperObj.taskListWrap = oppIdWithTaskMap.get(Opp.Id);
                ReportQueryWrapperObj.pastDriveListWrap = new List<DriveWrapper>();
                ReportQueryWrapperObj.futureDriveListWrap = new List<DriveWrapper>();
                if(accIdWithPastFutureDriveMap.get(opp.AccountId) != null){
                    for(Opportunity opt : accIdWithPastFutureDriveMap.get(opp.AccountId)){
                        DriveWrapper dwr = new DriveWrapper();
                        if(opt.Id == opp.Id || opt.Drive_Date__c == null){
                            continue;
                        }
                        dwr.addDescription = opt.Parent_Template_Id__r.Additional_Description__c;
                        dwr.Name = opt.Name;
                        dwr.driveDate = dateFormat(opt.Drive_Date__c);
                        dwr.driveStartTime = opt.Start_Time__c != null ? getFormattedTime(opt.Start_Time__c.hour(),opt.Start_Time__c.minute()) : ''; 
                        dwr.driveEndTime = opt.End_Time__c != null ? getFormattedTime(opt.End_Time__c.hour(),opt.End_Time__c.minute()) : ''; 
                        dwr.driveStage = opt.StageName;
                        dwr.driveStatus = opt.DriveStatus__c;
                        dwr.primaryContact = oppIdWithPrimaryContactMap.containsKey(opt.Id) ? oppIdWithPrimaryContactMap.get(opt.Id) : '';
                        if((opt.Drive_Date__c <= System.Today()) && String.isNotBlank(opt.DriveStatus__c) && opt.DriveStatus__c.equalsIgnoreCase('Complete')){
                            if(ReportQueryWrapperObj.pastDriveListWrap.size() >= 3){
                                ReportQueryWrapperObj.pastDriveListWrap.remove(0);
                            }
                            ReportQueryWrapperObj.pastDriveListWrap.add(dwr);
                        }else if((opt.Drive_Date__c > System.Today()) && (opt.Drive_Date__c <= System.Today().addMonths(12))){
                            ReportQueryWrapperObj.futureDriveListWrap.add(dwr);
                        }
                    }
                }
                ReportQueryWrapperObj.accNoteWrap = accOppIdWithNote.get(opp.Id);
                ReportQueryWrapperObj.oppNoteWrap = oppIdWithNote.get(opp.Id);
                ReportQueryWrapperObj.siteNoteWrap = siteOppIdWithNote.get(opp.Id);
                System.debug('ReportQueryWrapperObj:::::::::::'+ReportQueryWrapperObj);
                ReportQueryWrapperList.add(ReportQueryWrapperObj);    
            }
        }catch(Exception ex){
            System.debug(ex.getMessage()+ex.getLineNumber());
        }
    }
    
     @AuraEnabled
    public static list<Opportunity> search(String searchAcc, String searchPortfolio, Date searchStartDate, Date searchEndDate, String searchTeamMember){
        System.debug('searchPortfolio:-'+searchPortfolio);
        System.debug('searchTeamMember:-'+searchTeamMember);
        list<Opportunity> oppListResult = new list<Opportunity>();
        List<String> accNameList = new List<String>();
        set<Id> oppTeamId = new set<Id>();
        List<ReportDataWrapper> records = new List<ReportDataWrapper>();
        String whereCondition;
        String errorMsg;
        if(searchAcc =='' && searchPortfolio =='' && searchStartDate ==null && searchEndDate == null 
           && searchTeamMember ==''){
               errorMsg = 'No Input Found';
           }
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate ==null && searchEndDate == null 
           && searchTeamMember ==''){
               whereCondition = 'Where Account.Name like \'' + String.escapeSingleQuotes(searchAcc) + '\'' ;
           }
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate == null 
           && searchTeamMember ==''){
               whereCondition = 'Where Account.Name like \'' + String.escapeSingleQuotes(searchAcc) + '\'  And ' +
                   'Drive_Date__c >=: searchStartDate';
           }
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember ==''){
               whereCondition = 'Where Account.Name like \'' + String.escapeSingleQuotes(searchAcc) + '\' And ' +
                   'Drive_Date__c >=: searchStartDate And Drive_Date__c <=: searchEndDate';
           }
        if(searchAcc =='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember ==''){
               whereCondition = 'Where Drive_Date__c >=: searchStartDate And Drive_Date__c <=: searchEndDate';
           }
        if(searchAcc =='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate == null 
           && searchTeamMember ==''){
               whereCondition = 'Where Drive_Date__c >=: searchStartDate';
           }
        if(searchAcc =='' && searchPortfolio =='' && searchStartDate ==null && searchEndDate != null 
           && searchTeamMember ==''){
               whereCondition = 'Where Drive_Date__c <=: searchEndDate';
           }
        if(searchAcc =='' && searchPortfolio !='' && searchStartDate ==null && searchEndDate == null 
           && searchTeamMember == ''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name like: '%' + String.escapeSingleQuotes(searchPortfolio) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               
               whereCondition = 'Where Account.Name IN:accNameList';
           } 
           if(searchAcc =='' && searchPortfolio !='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember == ''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name like: '%' + String.escapeSingleQuotes(searchPortfolio) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               
                 whereCondition = 'Where Account.Name IN:accNameList And Drive_Date__c >=: searchStartDate And Drive_Date__c <=:searchEndDate';
           } 
           if(searchAcc =='' && searchPortfolio !='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember != ''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name like: '%' + String.escapeSingleQuotes(searchPortfolio) + '%'
                                                             AND Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               
                 whereCondition = 'Where Id In:oppTeamId And Account.Name IN:accNameList And Drive_Date__c >=: searchStartDate And Drive_Date__c <=:searchEndDate';
           } 
        if(searchAcc !='' && searchPortfolio !='' && searchStartDate ==null && searchEndDate == null 
           && searchTeamMember ==''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name like: 
                                                             '%' + String.escapeSingleQuotes(searchPortfolio) + '%' And
                                                             Account__r.Name like: 
                                                             '%' + String.escapeSingleQuotes(searchAcc) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               
               whereCondition = 'Where Account.Name IN:accNameList';
           } 
        
        if(searchAcc !='' && searchPortfolio !='' && searchStartDate !=null && searchEndDate == null 
           && searchTeamMember ==''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name 
                                                             like: '%' + String.escapeSingleQuotes(searchPortfolio) + '%' And
                                                             Account__r.Name like: 
                                                             '%' + String.escapeSingleQuotes(searchAcc) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             } 
               
               whereCondition = 'Where Account.Name IN:accNameList And Drive_Date__c >=: searchStartDate';
           } 
        if(searchAcc !='' && searchPortfolio !='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember ==''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name 
                                                             like: '%' + String.escapeSingleQuotes(searchPortfolio) + '%' And
                                                             Account__r.Name like: 
                                                             '%' + String.escapeSingleQuotes(searchAcc) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               
               whereCondition = 'Where Account.Name IN:accNameList And Drive_Date__c >=: searchStartDate And Drive_Date__c <=:searchEndDate';
           }    
           if(searchAcc !='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember ==''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where Account__r.Name like: 
                                                             '%' + String.escapeSingleQuotes(searchAcc) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               
               whereCondition = 'Where Account.Name IN:accNameList And Drive_Date__c >=: searchStartDate And Drive_Date__c <=:searchEndDate';
           }       
        if(searchAcc =='' && searchPortfolio =='' && searchStartDate ==null && searchEndDate == null 
           && searchTeamMember !=''){
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               whereCondition = 'Where Id In:oppTeamId';
           }
           if(searchAcc =='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember !=''){
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               whereCondition = 'Where Id In:oppTeamId And Drive_Date__c >=: searchStartDate And Drive_Date__c <=:searchEndDate';
           }
        
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate ==null && searchEndDate == null 
           && searchTeamMember !=''){
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               whereCondition = 'Where Id In:oppTeamId And Account.Name like \'%' + String.escapeSingleQuotes(searchAcc) + '%\' ';
           }  
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate == null 
           && searchTeamMember !=''){
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               whereCondition = 'Where Id In:oppTeamId And Account.Name like \'%' + String.escapeSingleQuotes(searchAcc) + '%\' And Drive_Date__c >=: searchStartDate';
           }
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember !=''){
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               whereCondition = 'Where Id In:oppTeamId And Account.Name like \'%' + String.escapeSingleQuotes(searchAcc) + '%\' And Drive_Date__c >=: searchStartDate And Drive_Date__c <=:searchEndDate';
           }  
        if(searchAcc !='' && searchPortfolio =='' && searchStartDate ==null && searchEndDate != null 
           && searchTeamMember !=''){
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               
               whereCondition = 'Where Id In:oppTeamId And Account.Name like \'%' + String.escapeSingleQuotes(searchAcc) + '%\' And Drive_Date__c <=:searchEndDate';
           }
        if(searchAcc !='' && searchPortfolio !='' && searchStartDate !=null && searchEndDate != null 
           && searchTeamMember !=''){
               for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name 
                                                             FROM Account_Portfolio_Assignment__c 
                                                             where BSF_Portfolio__r.Name 
                                                             like: '%' + String.escapeSingleQuotes(searchPortfolio) + '%' And
                                                             Account__r.Name like: 
                                                             '%' + String.escapeSingleQuotes(searchAcc) + '%']){
                                                                 system.debug('accPort '+ accPort);
                                                                 accNameList.add(accPort.Account__r.Name);      
                                                                 system.debug('accNameList '+ accNameList);
                                                             }
               for(OpportunityTeamMember t:[SELECT Id, OpportunityId, Name FROM OpportunityTeamMember
                                            Where Name like: '%' + String.escapeSingleQuotes(searchTeamMember) + '%']){
                                                oppTeamId.add(t.OpportunityId);
                                            }
               whereCondition = 'Where Id In:oppTeamId And Account.Name IN:accNameList And Drive_Date__c <=:searchEndDate';
           }
      //  list<Opportunity> oppListResult = new list<Opportunity>();
        if(whereCondition != null){
            errorMsg = null;
        	String q = 'select Id,Name,Account_Manager__c,AccountId,Drive_Name__c,Additional_Description__c,'+
            'Additional_Drive_Logistics__c, Drive_Date__c, Call_List_Recipient_Exist__c,Start_Time__c,'+
            'End_Time__c,Web_Schedule_Start_Date__c, Web_Schedule_End_Date__c,Online_Donor_Message__c,Drive_Keyword__c,'+                                          
            'WB_Projected_Procedures__c,Publish_to_Call_Center__c, Online_Scheduling_Enabled__c,Anticipated_Registered_Donors__c,'+
            'Account.Name, Account.Military_Authority_Name__c,Send_Emails__c,Send_Mailers__c,'+  
            'Account.Next_Scheduled_Drive_Updated__c,Account.Sponsor_Declines_Online_Scheduling__c,'+
            'Drive_Site__r.Id, Drive_Site__r.sked_Room_Name__c, Drive_Site__r.sked_Site_Contact__c,'+
            'Drive_Site__r.sked__Address__c,Drive_Site__r.sked_Site_Contact_Phone__c,'+
            'Drive_Site__r.sked_Wireless_Policy__c,Drive_Site__r.sked_Directions_From_CollectionOperation__c,'+
            'Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c, Drive_Site__r.sked_Pay_for_Parking_Details__c,'+
            'Drive_Site__r.sked_Escort_Required__c,Drive_Site__r.Sponsor_Security_Form_Required__c,'+
            'Drive_Site__r.sked_Security_Directions__c,Drive_Site__r.sked_Staff_List__c,'+
            'Drive_Site__r.sked_Date_Site_Inspection_Completed__c,Drive_Site__r.sked_Outside_stairs__c,'+
            'Drive_Site__r.sked_Room_Size__c,Drive_Site__r.sked_Inside_stairs__c,'+
            'Drive_Site__r.sked_Canteen_Requirements__c,Drive_Site__r.sked_Air_conditioned__c,'+
            'Drive_Site__r.sked_Site_Inspection_Completed_By__c, Drive_Site__r.sked_Site_Inspection_Comments__c,'+
            'Drive_Site__r.Emergency_Contact__c, Drive_Site__r.sked_On_Site_Food_Canteen_Requirements__c,'+
            'Drive_Site__r.sked_Site_Main_Phone__c,'+ 
            'Drive_Site__r.sked_Heat__c,Drive_Site__r.sked_Restroom_Location__c from opportunity '+
             whereCondition + ' Order By Drive_Date__c ASC, Start_Time__c ASC limit 500';
             System.debug('q query:::'+q);
        	oppListResult = Database.query(q);
            for(opportunity opp: oppListResult) {
                records.add(new ReportDataWrapper(opp)); 
            }
        } 
        System.debug('Return result1 : '+oppListResult);   
        System.debug('Return result2 : '+records);    
        return oppListResult;
    }
}