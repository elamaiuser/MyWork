/**
* @description: This class is the controller class for SponsorPlanningReportPdf visualforce page.
**   Modification Log  ****
*  Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 10/04/2024			Barnojit Sharma			Sponsor Planning Report Revisions (HRP-10290)
 *****************************************************************************************************************************************************************************
*/
public without sharing class SponsorPlanningReportPDFController{
	public String renderAs {get; set;}
    public List<SponsorPlanningReportPDFWrapper> wrapper {get; set;}
    
    public SponsorPlanningReportPDFController(){
        String opportunityIds = Apexpages.currentPage().getParameters().get('opportunityids');
        System.debug('opportunityids : '+opportunityids);
        if(String.isNotBlank(opportunityIds)){
            opportunityIds = String.escapeSingleQuotes(opportunityIds);
            opportunityIds = opportunityIds.escapeHtml4();
            opportunityIds = opportunityIds.replace('/',',');
        }
        this.renderAs = Apexpages.currentPage().getParameters().get('renderas');
        if(String.isNotBlank(this.renderAs)){
            this.renderAs = String.escapeSingleQuotes(this.renderAs);
            this.renderAs = this.renderAs.escapeHtml4();
        }else{
            this.renderAs = 'pdf';
        }
        this.wrapper = getData(opportunityIds);
        if(ApexPages.currentPage().getParameters().get('force_download') != null 
                    && ApexPages.currentPage().getParameters().get('force_download') == 'true'
                    && String.isNotBlank(this.renderAs) && this.renderAs.equalsIgnoreCase('pdf')){
                        ApexPages.currentPage().getHeaders().put('Content-Disposition', 'attachment; filename="SponsorPlanningReport.pdf"');
        }
    }

    public static List<SponsorPlanningReportPDFWrapper> getData(String opportunityIds){
        List<SponsorPlanningReportPDFWrapper> data = new List<SponsorPlanningReportPDFWrapper>();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        Map<Id,Contact> oppVsPriConMap = new Map<Id,Contact>();
        Map<Id,sked_Drive__c> oppVsDocMap = new Map<Id,sked_Drive__c>();
        Map<Id,User> oppVsPriAMMap = new Map<Id,User>();
        Map<Id,Integer> maxDonorCapMap = new Map<Id,Integer>();
        Map<Id,Contact> oppVsAfterHoursContactMap = new Map<Id,Contact>();
        Map<Id,String> oppVsWhomtoMeetMap = new Map<Id,String>();
        Map<Id,List<Opportunity>> accVsOppMap = new Map<Id,List<Opportunity>>();
        Map<Id,List<String>> premierPartnerAffMap = new Map<Id,List<String>>();
        Map<Id,List<sked_Drive_Shift__c>> oppVsShiftsMap = new Map<Id,List<sked_Drive_Shift__c>>();
        Map<Id,List<Account_Service_Role__c>> accVsServiceRoleMap = new Map<Id,List<Account_Service_Role__c>>();
        Map<Id,List<OpportunityContactRole>> oppVsContactRoleMap = new Map<Id,List<OpportunityContactRole>>();
        Map<Id,List<Order>> oppVsOrderMap = new Map<Id,List<Order>>();
        Map<Id,List<OrderItem>> orderVsProductMap = new Map<Id,List<OrderItem>>();
        Map<Id,List<String>> accAffiliationMap = new Map<Id,List<String>>();
        Map<Id,List<String>> drvAffiliationMap = new Map<Id,List<String>>();
        Map<Id,List<sked__Account_Tag__c>> accVsTagMap = new Map<Id,List<sked__Account_Tag__c>>();
        Map<Id,List<sked_Location_Tag__c>> siteVsTagMap = new Map<Id,List<sked_Location_Tag__c>>();
        Map<Id,List<sked__Job__c>> shiftVsJobMap = new Map<Id,List<sked__Job__c>>();
        if(String.isNotBlank(opportunityIds)){
            List<String> oppIds = opportunityIds.split(',');
            opportunityMap = new Map<Id,Opportunity>([SELECT Id,
                                                                Name,
                                                                StageName,
                                                                Account_Manager__c,
                                                                AccountId,
                                                                Drive_Name__c,
                                                                Additional_Description__c,
                                                                Additional_Drive_Logistics__c,
                                                                Drive_Date__c,
                                                                Call_List_Recipient_Exist__c,
                                                                Start_Time__c,
                                                                Direct_Donors_To__c,
                                                                Anticipated_Registered_Donors_Template__c,
                                                                X2RBC_Projected_Procedures__c,
                                                                Total_Products_Projected__c,
                                                                CDA_O_Positive__c,
                                                                Total_Products_Projected_Template__c,
                                                                Security_Escort_Name__c,
                                                                DriveStatus__c,
                                                                CDA_O_Negative__c,
                                                                WholeBloodProceduresProjectedTemplate__c,
                                                                Double_Red_Procedures_Projected_Template__c,
                                                                End_Time__c,
                                                                Web_Schedule_StartDate__c,
                                                                Web_Schedule_EndDate__c ,
                                                                Online_Donor_Message__c,
                                                                Drive_Keyword__c,                      
                                                                WB_Projected_Procedures__c,
                                                                Publish_to_Call_Center__c,
                                                                Online_Scheduling_Enabled__c,
                                                                Anticipated_Registered_Donors__c,
                                                                Account.Name,
                                                                Account.Military_Authority_Name__c,
                                                                Account.Military_Authority_Phone__c,
                                                                Send_Emails__c,
                                                                Send_Mailers__c,
                                                                Account.Contact_BPL__c,
                                                                Account.Contact_BPL__r.Name,
                                                                Drive_Site__c,
                                                                Drive_Site__r.sked_Site_Contact_Email__c,
                                                                Parent_Template_Id__c,
                                                                Parent_Template_Id__r.Additional_Description__c,
                                                                Account.Next_Scheduled_Drive__c,
                                                                Account.Sponsor_Declines_Online_Scheduling__c,
                                                                Drive_Site__r.sked_No_Cell_Phones__c,
                                                                Drive_Site__r.Id,
                                                                Drive_Site__r.Name,
                                                                Drive_Site__r.sked_Room_Name__c,
                                                                Drive_Site__r.sked_Site_Contact__c,
                                                                Drive_Site__r.sked_Site_Contact__r.Name,
                                                                Drive_Site__r.sked__Address__c,
                                                                Drive_Site__r.sked_Site_Contact_Phone__c,
                                                                Drive_Site__r.sked_Site_Inspection_Completed_By__r.Name,
                                                                Drive_Site__r.sked_Wireless_Policy__c,
                                                                Drive_Site__r.sked_Directions_From_CollectionOperation__c,
                                                                Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c,
                                                                Drive_Site__r.sked_Pay_for_Parking_Details__c,
                                                                Drive_Site__r.sked_Escort_Required__c,
                                                                Drive_Site__r.Sponsor_Security_Form_Required__c,
                                                                Drive_Site__r.sked_Collection_Operation_Name__c,
                                                                Drive_Site__r.sked_Floor_Description__c,
                                                                Drive_Site__r.sked_Staff_Personal_Parking_Directions__c,
                                                                Drive_Site__r.sked_Equipment_X_Ray_Required__c,
                                                                Drive_Site__r.sked_Security_Directions__c,
                                                                Drive_Site__r.sked_Staff_List__c,
                                                                Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c,
                                                                Drive_Site__r.sked_Date_Site_Inspection_Completed__c,
                                                                Drive_Site__r.sked_Outside_stairs__c,
                                                                Drive_Site__r.sked_Room_Size__c,
                                                                Drive_Site__r.sked_Inside_stairs__c,
                                                                Drive_Site__r.sked_Elevator_Type__c,
                                                                Drive_Site__r.sked_110_outlets__c,
                                                                Drive_Site__r.sked_Site_Close__c,
                                                                Drive_Site__r.sked_Security_Information_Needed__c,
                                                                Drive_Site__r.sked_Emergency_Contact__r.Name,
                                                                Drive_Site__r.sked_Safety_Emergency_Action_Plan__c,
                                                                Drive_Site__r.sked_Automation_Suitability__c,
                                                                Drive_Site__r.sked_Elevator_Close__c,
                                                                Drive_Site__r.sked_Elevator_Open__c,
                                                                Drive_Site__r.sked_Break_location__c,
                                                                Drive_Site__r.sked_Maximum_Beds__c,
                                                                Drive_Site__r.sked_Unloading_Conditions__c,
                                                                Drive_Site__r.sked_Floor_Covering_Requirement__c,
                                                                Drive_Site__r.sked_Max_Auto_Machines__c,
                                                                Drive_Site__r.sked_Canteen_Requirements__c,
                                                                Drive_Site__r.sked_Air_conditioned__c,
                                                                Drive_Site__r.sked_Unloading_Directions_Details__c,
                                                                Drive_Site__r.sked_Site_Inspection_Completed_By__c ,
                                                                Drive_Site__r.sked_Site_Inspection_Comments__c,
                                                                Drive_Site__r.Emergency_Contact__c,
                                                                Drive_Site__r.sked_On_Site_Food_Canteen_Requirements__c,
                                                                Drive_Site__r.sked_Site_Main_Phone__c,
                                                                Drive_Site__r.sked_Site_Open__c,
                                                                Drive_Site__r.sked_Heat__c,
                                                                Drive_Site__r.sked_Restroom_Location__c 
                                                        FROM Opportunity 
                                                        WHERE Id IN: oppIds]);
            for(Id oppId : opportunityMap.keySet()){
                if(opportunityMap.get(oppId).AccountId != null){
                    accVsOppMap.put(opportunityMap.get(oppId).AccountId,new List<Opportunity>());
                    premierPartnerAffMap.put(opportunityMap.get(oppId).AccountId,new List<String>());
                    accVsServiceRoleMap.put(opportunityMap.get(oppId).AccountId,new List<Account_Service_Role__c>());
                    accAffiliationMap.put(opportunityMap.get(oppId).AccountId, new List<String>());
                    accVsTagMap.put(opportunityMap.get(oppId).AccountId, new List<sked__Account_Tag__c>());
                }
                if(opportunityMap.get(oppId).Drive_Site__c != null){
                    siteVsTagMap.put(opportunityMap.get(oppId).Drive_Site__c, new List<sked_Location_Tag__c>());
                }
                oppVsDocMap.put(oppId,null);
                oppVsPriConMap.put(oppId,null);
                oppVsPriAMMap.put(oppId,null);
                oppVsAfterHoursContactMap.put(oppId,null);
                maxDonorCapMap.put(oppId,0);
                oppVsWhomtoMeetMap.put(oppId,'');
                oppVsShiftsMap.put(oppId,new List<sked_Drive_Shift__c>());
                oppVsContactRoleMap.put(oppId,new List<OpportunityContactRole>());
                oppVsOrderMap.put(oppId,new List<Order>());
                drvAffiliationMap.put(oppId, new List<String>());
            }
        }
        if(!oppVsPriAMMap.isEmpty()){
            List<OpportunityTeamMember> oppTeamMember = [SELECT Id, 
                                                                OpportunityId,
                                                                UserId, 
                                                                User.Name,
                                                                User.Email,
                                                                User.Phone 
                                                            FROM OpportunityTeamMember 
                                                            WHERE OpportunityId IN: oppVsPriAMMap.keySet() 
                                                            AND TeamMemberRole = 'Account Manager'
                                                            AND UserId != null];
            for(OpportunityTeamMember team: oppTeamMember){
                oppVsPriAMMap.put(team.OpportunityId,team.User);
            }
        }
        if(!accVsOppMap.isEmpty()){
            List<Opportunity> pastAndFutureDrives = [SELECT Id, 
                                                                Drive_Date__c, 
                                                                DriveStatus__c, 
                                                                StageName,
                                                                Start_Time__c, 
                                                                End_Time__c,
                                                                Name,
                                                                AccountId,
                                                                Drive_Site__c,
                                                                Drive_Site__r.Name
                                                            FROM Opportunity 
                                                            WHERE AccountId IN:accVsOppMap.keySet()
                                                            AND Drive_Date__c != null
                                                            AND StageName != 'Cancelled'
                                                            ORDER BY Drive_Date__c ASC];
            for(Opportunity opp : pastAndFutureDrives){
                accVsOppMap.get(opp.AccountId).add(opp);
                oppVsPriConMap.put(opp.Id,null);
                oppVsDocMap.put(opp.Id,null);
            }
        }
        if(!oppVsDocMap.isEmpty()){
            List<sked_Drive__c> driveForPCList = [SELECT Id, 
                                                        sked_Primary_Contact__c, 
                                                        sked_Primary_Contact__r.Name,
                                                        sked_Primary_Contact__r.Primary_Phone_Number_New__c,
                                                        sked_Primary_Contact__r.Email,
                                                        sked_Opportunity__c,
                                                        sked_Drive_Productivity_Planned__c,
                                                        sked_Total_Slots__c,
                                                        sked_No_of_Scheduled_Appointments__c,
                                                        sked_Start_Time__c
                                                    FROM sked_Drive__c 
                                                    WHERE sked_Opportunity__c IN: oppVsDocMap.keySet()];    
            for(sked_Drive__c drv : driveForPCList){
                if(drv.sked_Primary_Contact__c != null){
                    oppVsPriConMap.put(drv.sked_Opportunity__c, drv.sked_Primary_Contact__r);
                }
                if(opportunityMap.containsKey(drv.sked_Opportunity__c)){
                    oppVsDocMap.put(drv.sked_Opportunity__c,drv);
                }
            }
        }
        if(!accVsServiceRoleMap.isEmpty()){
            List<Account_Service_Role__c> accCon = [SELECT Id, 
                                                            Name,
                                                            Contact__c,
                                                            Contact__r.Name,
                                                            Account_Service_Role__c,
                                                            Account__c
                                                        FROM Account_Service_Role__c
                                                        WHERE Account__c IN:accVsServiceRoleMap.keySet()
                                                        AND Contact__c != null
                                                        ORDER BY Account__c ASC, Contact__r.Name ASC];
            for(Account_Service_Role__c asr : accCon){
                accVsServiceRoleMap.get(asr.Account__c).add(asr);
            }
        }
        if(!oppVsContactRoleMap.isEmpty()){
            List<OpportunityContactRole> oppConList = [SELECT Id,
                                                                ContactId, 
                                                                role, 
                                                                OpportunityId, 
                                                                Contact.Name, 
                                                                Contact.Email, 
                                                                Contact.Primary_Phone_Number_New__c,
                                                                Contact.After_Hours_Number__c 
                                                        FROM OpportunityContactRole
                                                        WHERE OpportunityId IN:oppVsContactRoleMap.keySet()
                                                        AND ContactId != null
                                                        ORDER BY OpportunityId ASC, Contact.Name ASC];
            for(OpportunityContactRole ocr : oppConList){
                oppVsContactRoleMap.get(ocr.OpportunityId).add(ocr);
                if(String.isNotBlank(ocr.role) && ocr.role.equalsIgnoreCase('After Hours Contact')){
                    oppVsAfterHoursContactMap.put(ocr.OpportunityId,ocr.Contact);
                }
                if(String.isNotBlank(ocr.role) && ocr.role.equalsIgnoreCase('Whom to Meet')){
                    oppVsWhomtoMeetMap.put(ocr.OpportunityId,ocr.Contact.Name);
                }
            }
        }
        if(!premierPartnerAffMap.isEmpty() || !accAffiliationMap.isEmpty()){
            List<Id> affAccountIds = new List<Id>(premierPartnerAffMap.keySet());
            affAccountIds.addAll(accAffiliationMap.keySet());
            List<Account_Marketing_Program__c> accMktPrograms = [SELECT Id,
                                                                        Account__c,
                                                                        Marketing_Program__c,
                                                                        Marketing_Program__r.Name
                                                                FROM Account_Marketing_Program__c
                                                                WHERE Account__c IN:affAccountIds
                                                                AND Marketing_Program__c != null
                                                                AND Marketing_Program__r.Name != null];
            for(Account_Marketing_Program__c amp : accMktPrograms){
                if(!premierPartnerAffMap.isEmpty() && premierPartnerAffMap.containsKey(amp.Account__c)
                        && amp.Marketing_Program__r.Name.containsIgnoreCase('Premier Current')){
                            premierPartnerAffMap.get(amp.Account__c).add(amp.Marketing_Program__r.Name);
                }
                if(!accAffiliationMap.isEmpty() && accAffiliationMap.containsKey(amp.Account__c)){
                    accAffiliationMap.get(amp.Account__c).add(amp.Marketing_Program__r.Name);
                }
            }
        }
        if(!drvAffiliationMap.isEmpty()){
            List<Drive_Marketing_Programs__c> driveAffList = [SELECT Id,
                                                                        Name, 
                                                                        Marketing_Program__c,
                                                                        Marketing_Program__r.Name,
                                                                        Blood_Drive_Opportunity__c 
                                                                FROM Drive_Marketing_Programs__c
                                                                WHERE Blood_Drive_Opportunity__c IN:drvAffiliationMap.keySet()
                                                                AND Marketing_Program__c != null
                                                                AND Marketing_Program__r.Name != null];
            for(Drive_Marketing_Programs__c dmp : driveAffList){
                drvAffiliationMap.get(dmp.Blood_Drive_Opportunity__c).add(dmp.Marketing_Program__r.Name);
            }
        }
        if(!oppVsShiftsMap.isEmpty()){
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
                                                        sked_End_Time__c,
                                                        (SELECT Id,
                                                                sked_Setup_Time__c,
                                                                sked_Sponsor_Volunteer_Quantity__c,
                                                                sked_Redcross_Volunteer_Quantity__c,
                                                                sked_Drive_Shift__c
                                                        FROM sked_Jobs__r)
                                            FROM sked_Drive_Shift__c 
                                            WHERE sked_Drive__r.sked_Opportunity__c IN: oppVsShiftsMap.keySet()
                                            ORDER BY sked_Start_Time__c ASC NULLS LAST];
            for(sked_Drive_Shift__c shift : shiftData){
                oppVsShiftsMap.get(shift.sked_Drive__r.sked_Opportunity__c).add(shift);
                shiftVsJobMap.put(shift.Id,new List<sked__Job__c>());
                if(shift.sked_Max_Donor_Capacity__c != null && maxDonorCapMap.get(shift.sked_Drive__r.sked_Opportunity__c) < shift.sked_Max_Donor_Capacity__c){
                    maxDonorCapMap.put(shift.sked_Drive__r.sked_Opportunity__c,shift.sked_Max_Donor_Capacity__c.intValue());
                }
                if(shift.sked_Jobs__r != null){
                    for(sked__Job__c job : shift.sked_Jobs__r){
                        shiftVsJobMap.get(shift.Id).add(job);
                    }
                }
            }
        }
        if(!oppVsOrderMap.isEmpty()){
            List<Order> ordList = [SELECT Id,  
                                            Publicity_Comment__c, 
                                            Local_Recruitment_Request_Need_by_Date__c , 
                                            OrderNumber,
                                            Local_Recruitment_Request__c, 
                                            BudgetCurrency__c, 
                                            TotalAmount,
                                            OpportunityId,
                                            (SELECT Id, 
                                                    OrderId,
                                                    Quantity,
                                                    TotalPrice,
                                                    Product2Id,
                                                    Product2.Name 
                                            FROM OrderItems) 
                                    FROM Order 
                                    WHERE OpportunityId IN: oppVsOrderMap.keySet()
                                    ORDER BY OrderNumber ASC];
            for(Order odr : ordList){
                oppVsOrderMap.get(odr.OpportunityId).add(odr);
                orderVsProductMap.put(odr.Id, odr.OrderItems);
            }
        }
        if(!accVsTagMap.isEmpty()){
            List<sked__Account_Tag__c> accountTags = [SELECT Id, 
                                                                Name, 
                                                                sked__Account__c,
                                                                sked__Tag__c,
                                                                sked__Tag__r.Name, 
                                                                sked__Tag__r.sked__Type__c,
                                                                sked_Minimum_Quantity__c 
                                                        FROM sked__Account_Tag__c 
                                                        WHERE sked__Account__c IN: accVsTagMap.keySet()
                                                        AND sked__Tag__c != null
                                                        AND sked__Tag__r.sked__Type__c = 'Certification'];
            for(sked__Account_Tag__c atags : accountTags) {
                accVsTagMap.get(atags.sked__Account__c).add(atags);
            }
        }
        if(!siteVsTagMap.isEmpty()){
            List<sked_Location_Tag__c> locationTags = [SELECT Id, 
                                                                Name, 
                                                                sked_Location__c,
                                                                sked_Tag__c,
                                                                sked_Tag__r.Name, 
                                                                sked_Tag__r.sked__Type__c, 
                                                                sked_Minimum_Quantity__c 
                                                        FROM sked_Location_Tag__c 
                                                        WHERE sked_Location__c IN: siteVsTagMap.keySet()
                                                        AND sked_Tag__c != null
                                                        AND sked_Tag__r.sked__Type__c = 'Certification'];
            for(sked_Location_Tag__c ltags : locationTags) {
                siteVsTagMap.get(ltags.sked_Location__c).add(ltags);
            }
        }
        if(!opportunityMap.isEmpty()){
            for(Id oppId : opportunityMap.keySet()){
                SponsorPlanningReportPDFWrapper wrap = new SponsorPlanningReportPDFWrapper();
                Integer maxRoleCount = 0;
                Integer maxAffiliationCount = 0;
                Integer setupTimeConst = 0;
                wrap.accountName = opportunityMap.get(oppId).Name;
                wrap.driveDate = getFormattedDate(opportunityMap.get(oppId).Drive_Date__c,true);
                wrap.startTime = getFormattedTime(opportunityMap.get(oppId).Start_Time__c);
                wrap.endTime = getFormattedTime(opportunityMap.get(oppId).End_Time__c);
                wrap.driveStage = opportunityMap.get(oppId).StageName;
                wrap.driveStatus = opportunityMap.get(oppId).DriveStatus__c;
                if(oppVsPriAMMap.get(oppId) != null){
                    wrap.primaryAM = oppVsPriAMMap.get(oppId).Name +
                                    (oppVsPriAMMap.get(oppId).Email != null ? '<br>' + oppVsPriAMMap.get(oppId).Email : '') + 
                                    (oppVsPriAMMap.get(oppId).Phone != null ? '<br>' + oppVsPriAMMap.get(oppId).Phone : '');
                }
                if(oppVsPriConMap.get(oppId) != null){
                    wrap.primaryContact = oppVsPriConMap.get(oppId).Name;
                    wrap.primaryEmailPhone = (oppVsPriConMap.get(oppId).Email != null ? oppVsPriConMap.get(oppId).Email : '') + 
                        (oppVsPriConMap.get(oppId).Email != null && oppVsPriConMap.get(oppId).Primary_Phone_Number_New__c != null ? '\n' : '') + 
                        (oppVsPriConMap.get(oppId).Primary_Phone_Number_New__c != null ? oppVsPriConMap.get(oppId).Primary_Phone_Number_New__c : '');
                }
                wrap.anticipatedRegDonors = opportunityMap.get(oppId).Anticipated_Registered_Donors__c != null 
                                            ? String.valueOf(opportunityMap.get(oppId).Anticipated_Registered_Donors__c.intValue()) : '';
                wrap.tempAnticipatedRegDonors = opportunityMap.get(oppId).Anticipated_Registered_Donors_Template__c != null 
                                                ? String.valueOf(opportunityMap.get(oppId).Anticipated_Registered_Donors_Template__c.intValue()) : '';
                wrap.wbProcedureProjection = opportunityMap.get(oppId).WB_Projected_Procedures__c != null 
                                            ? String.valueOf(opportunityMap.get(oppId).WB_Projected_Procedures__c.intValue()) : '';
                wrap.tempWBProcedureProjection = opportunityMap.get(oppId).WholeBloodProceduresProjectedTemplate__c != null 
                                                ? String.valueOf(opportunityMap.get(oppId).WholeBloodProceduresProjectedTemplate__c.intValue()) : '';
                wrap.twoRBCProcedureProjection = opportunityMap.get(oppId).X2RBC_Projected_Procedures__c != null 
                                                    ? String.valueOf(opportunityMap.get(oppId).X2RBC_Projected_Procedures__c.intValue()) : '';
                wrap.temp2RBCProcedureProjection = opportunityMap.get(oppId).Double_Red_Procedures_Projected_Template__c != null 
                                                    ? String.valueOf(opportunityMap.get(oppId).Double_Red_Procedures_Projected_Template__c.intValue()) : '';
                wrap.totalProductProjection = opportunityMap.get(oppId).Total_Products_Projected__c != null 
                                                ? String.valueOf(opportunityMap.get(oppId).Total_Products_Projected__c.intValue()) : '';
                wrap.tempProductProjection = opportunityMap.get(oppId).Total_Products_Projected_Template__c != null 
                                            ? String.valueOf(opportunityMap.get(oppId).Total_Products_Projected_Template__c.intValue()) : '';
                wrap.presentingDonorCapacity = String.valueOf(maxDonorCapMap.get(oppId));
                wrap.tempCDAOplus = opportunityMap.get(oppId).CDA_O_Positive__c != null 
                                    ? String.valueOf(opportunityMap.get(oppId).CDA_O_Positive__c.intValue()) : '';
                wrap.tempCDAOminus = opportunityMap.get(oppId).CDA_O_Negative__c != null 
                                    ? String.valueOf(opportunityMap.get(oppId).CDA_O_Negative__c.intValue()) : '';
                wrap.additionalDriveLogistics = (String.isNotBlank(opportunityMap.get(oppId).Additional_Drive_Logistics__c) ?  
                                            opportunityMap.get(oppId).Additional_Drive_Logistics__c.replace('\n','<br>') : '');
                wrap.securityEscortName = opportunityMap.get(oppId).Security_Escort_Name__c;
                wrap.callListRecipient = opportunityMap.get(oppId).Call_List_Recipient_Exist__c ? 'Yes' : 'No';
                wrap.publishToCallCenter = opportunityMap.get(oppId).Publish_to_Call_Center__c ? 'Yes' : 'No';
                wrap.driveKeyword = opportunityMap.get(oppId).Drive_Keyword__c;
                wrap.sendEmail = opportunityMap.get(oppId).Send_Emails__c ? 'Yes' : 'No';
                wrap.directDonorsTo = opportunityMap.get(oppId).Direct_Donors_To__c;
                wrap.sendMailers = opportunityMap.get(oppId).Send_Mailers__c ? 'Yes' : 'No';
                wrap.onlineDonorMessage = opportunityMap.get(oppId).Online_Donor_Message__c;
                wrap.onlineSchedulingEnabled = opportunityMap.get(oppId).Online_Scheduling_Enabled__c;
                if(opportunityMap.get(oppId).Drive_Date__c != null){
                    wrap.driveWBEligibility = getFormattedDate(opportunityMap.get(oppId).Drive_Date__c.addDays(-56),false);
                    wrap.drivePREligibility = getFormattedDate(opportunityMap.get(oppId).Drive_Date__c.addDays(-112),false);
                }
                wrap.webSchedulingStartDate = getFormattedDate(opportunityMap.get(oppId).Web_Schedule_StartDate__c,false);
                wrap.webSchedulingEndDate = getFormattedDate(opportunityMap.get(oppId).Web_Schedule_EndDate__c,false);
                wrap.whomToMeet = oppVsWhomtoMeetMap.get(oppId);
                if(oppVsAfterHoursContactMap.get(oppId) != null){
                    wrap.afterHoursContact = oppVsAfterHoursContactMap.get(oppId).Name;
                    wrap.afterHoursContactPh = oppVsAfterHoursContactMap.get(oppId).After_Hours_Number__c;
                }
                if(!oppVsShiftsMap.get(oppId).isEmpty()){
                    wrap.shiftData = new List<ShiftWrapper>();
                    for(sked_Drive_Shift__c shift : oppVsShiftsMap.get(oppId)){
                        ShiftWrapper sftWrp = new ShiftWrapper();
                        Integer arcVol = 0;
                        Integer sponsorVol = 0;
                        sftWrp.shiftName = shift.Name;
                        sftWrp.twoRBCProcProj = shift.sked_2RBC_Projected_Procedures__c != null ? String.valueOf(shift.sked_2RBC_Projected_Procedures__c.round(RoundingMode.HALF_UP)) : '0';
                        sftWrp.twoRBCProdProj = shift.sked_2RBC_Projected_Procedures__c != null ? String.valueOf(2*shift.sked_2RBC_Projected_Procedures__c.round(RoundingMode.HALF_UP)) : '0';
                        sftWrp.wbProcProj = shift.sked_WB_Projected_Procedures__c != null ? String.valueOf(shift.sked_WB_Projected_Procedures__c.round(RoundingMode.HALF_UP)) : '0';
                        sftWrp.wbProdProj = shift.sked_WB_Projected_Procedures__c != null ? String.valueOf(shift.sked_WB_Projected_Procedures__c.round(RoundingMode.HALF_UP)) : '0';
                        sftWrp.totalProcProj = String.valueOf(Integer.valueOf(sftWrp.twoRBCProcProj) + Integer.valueOf(sftWrp.wbProcProj));
                        sftWrp.totalProdProj = String.valueOf(Integer.valueOf(sftWrp.twoRBCProdProj) + Integer.valueOf(sftWrp.wbProdProj));
                        sftWrp.shiftHour = getFormattedTime(shift.sked_Start_Time__c) + ' - ' + getFormattedTime(shift.sked_End_Time__c);
                        sftWrp.lunchBreak = getFormattedTime(shift.sked_Lunch_Break_Start_Time__c) + ' - ' + getFormattedTime(shift.sked_Lunch_Break_End_Time__c);
                        for(sked__Job__c jb : shiftVsJobMap.get(shift.Id)){
                            if(jb.sked_Redcross_Volunteer_Quantity__c != null && arcVol < jb.sked_Redcross_Volunteer_Quantity__c){
                                arcVol = jb.sked_Redcross_Volunteer_Quantity__c.intValue();
                            }
                            if(jb.sked_Sponsor_Volunteer_Quantity__c != null && sponsorVol < jb.sked_Sponsor_Volunteer_Quantity__c){
                                sponsorVol = jb.sked_Sponsor_Volunteer_Quantity__c.intValue();
                            }
                            if(jb.sked_Setup_Time__c != null && setupTimeConst < jb.sked_Setup_Time__c){
                                setupTimeConst = jb.sked_Setup_Time__c.intValue();
                            }
                        }
                        sftWrp.arcVolunteer = String.valueOf(arcVol);
                        sftWrp.sponsorVolunteer = String.valueOf(sponsorVol);
                        wrap.shiftData.add(sftWrp);
                    }
                }
                if(oppVsDocMap.get(oppId) != null){
                    wrap.driveProductivity = oppVsDocMap.get(oppId).sked_Drive_Productivity_Planned__c != null 
                                            ? String.valueOf(oppVsDocMap.get(oppId).sked_Drive_Productivity_Planned__c.setScale(2)) : '';
                    wrap.totalSlots = oppVsDocMap.get(oppId).sked_Total_Slots__c != null 
                                            ? String.valueOf(oppVsDocMap.get(oppId).sked_Total_Slots__c.intValue()) : '';
                    wrap.scheduledAppointments = oppVsDocMap.get(oppId).sked_No_of_Scheduled_Appointments__c != null 
                                            ? String.valueOf(oppVsDocMap.get(oppId).sked_No_of_Scheduled_Appointments__c.intValue()) : '';
                    wrap.setupTime = oppVsDocMap.get(oppId).sked_Start_Time__c != null 
                                    ? getFormattedTime(oppVsDocMap.get(oppId).sked_Start_Time__c.addMinutes(Integer.valueOf(0 - setupTimeConst))) : '';
                }
                if(opportunityMap.get(oppId).AccountId != null){
                    maxRoleCount = accVsServiceRoleMap.get(opportunityMap.get(oppId).AccountId).size();
                    maxAffiliationCount = accAffiliationMap.get(opportunityMap.get(oppId).AccountId).size();
                    wrap.premierPartnerAff = String.join(premierPartnerAffMap.get(opportunityMap.get(oppId).AccountId),', ');
                    wrap.militaryAuthorityName = (String.isNotBlank(opportunityMap.get(oppId).Account.Military_Authority_Name__c) ?
                                                opportunityMap.get(oppId).Account.Military_Authority_Name__c : '') + 
                                                (String.isNotBlank(opportunityMap.get(oppId).Account.Military_Authority_Name__c) 
                                                && opportunityMap.get(oppId).Account.Military_Authority_Phone__c != null ?
                                                '\n' + opportunityMap.get(oppId).Account.Military_Authority_Phone__c : '');
                    if(!accVsOppMap.get(opportunityMap.get(oppId).AccountId).isEmpty()){
                        wrap.futureDrives = new List<FutureDriveWrapper>();
                        Integer futureOppCounter = 0;
                        for(Opportunity opp : accVsOppMap.get(opportunityMap.get(oppId).AccountId)){
                            if(oppId != opp.Id && futureOppCounter < 10 
                                    && opportunityMap.get(oppId).Drive_Date__c != null 
                                    && opportunityMap.get(oppId).Drive_Date__c <= opp.Drive_Date__c
                                    /*&& opportunityMap.get(oppId).Drive_Date__c.addDays(365) >= opp.Drive_Date__c*/){
                                        FutureDriveWrapper fdw = new FutureDriveWrapper();
                                        fdw.driveDate = getFormattedDate(opp.Drive_Date__c,false);
                                        fdw.siteName = opp.Drive_Site__c != null ? opp.Drive_Site__r.Name : '';
                                        fdw.startTime = getFormattedTime(opp.Start_Time__c);
                                        fdw.endTime = getFormattedTime(opp.End_Time__c);
                                        fdw.driveStatus = opp.DriveStatus__c;
                                        fdw.driveStage = opp.StageName;
                                        fdw.primaryContactName = oppVsPriConMap.get(opp.Id) != null ? oppVsPriConMap.get(opp.Id).Name : '';
                                        wrap.futureDrives.add(fdw);
                                        futureOppCounter++;
                            }
                        }
                    }
                    if(!accVsTagMap.get(opportunityMap.get(oppId).AccountId).isEmpty()){
                        wrap.certificationData = new List<Certifications>();
                        for(sked__Account_Tag__c acctg : accVsTagMap.get(opportunityMap.get(oppId).AccountId)){
                            Certifications crt = new Certifications();
                            crt.tagType = 'Account';
                            crt.tagName = acctg.sked__Tag__r.Name;
                            crt.minimumQuantity = acctg.sked_Minimum_Quantity__c != null ? String.valueOf(acctg.sked_Minimum_Quantity__c.intValue()) : '';
                            wrap.certificationData.add(crt);
                        }
                    }
                }
                if(opportunityMap.get(oppId).Drive_Site__c != null){
                    wrap.collectionOperation = opportunityMap.get(oppId).Drive_Site__r.sked_Collection_Operation_Name__c;
                    wrap.locationName = opportunityMap.get(oppId).Drive_Site__r.Name;
                    wrap.siteWirelessPolicy = opportunityMap.get(oppId).Drive_Site__r.sked_Wireless_Policy__c;
                    wrap.floorDescription = opportunityMap.get(oppId).Drive_Site__r.sked_Floor_Description__c;
                    wrap.automationSuitability = opportunityMap.get(oppId).Drive_Site__r.sked_Automation_Suitability__c;
                    wrap.roomName = opportunityMap.get(oppId).Drive_Site__r.sked_Room_Name__c;
                    wrap.siteContact = opportunityMap.get(oppId).Drive_Site__r.sked_Site_Contact__r.Name + 
                                        (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Site_Contact_Email__c) ?  
                                        '<br>'+opportunityMap.get(oppId).Drive_Site__r.sked_Site_Contact_Email__c : '') +
                                        (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Site_Contact_Phone__c) ?  
                                        '<br>'+opportunityMap.get(oppId).Drive_Site__r.sked_Site_Contact_Phone__c : '');
                    wrap.siteAddress = opportunityMap.get(oppId).Drive_Site__r.sked__Address__c;
                    wrap.drivingDirectionFromCO = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Directions_From_CollectionOperation__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_Directions_From_CollectionOperation__c.replace('\n','<br>') : '');
                    wrap.arcVehicleParkingDirections = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_ARC_Vehicle_Parking_Directions__c.replace('\n','<br>') : '');
                    wrap.staffParkingDirections = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Staff_Personal_Parking_Directions__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_Staff_Personal_Parking_Directions__c.replace('\n','<br>') : '');
                    wrap.payForParkingDetails = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Pay_for_Parking_Details__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_Pay_for_Parking_Details__c.replace('\n','<br>') : '');
                    wrap.unloadingConditions = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Unloading_Conditions__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_Unloading_Conditions__c.replace('\n','<br>') : '');
                    wrap.unloadingDirectionDetails = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Unloading_Directions_Details__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_Unloading_Directions_Details__c.replace('\n','<br>') : '');
                    wrap.securityDirections = (String.isNotBlank(opportunityMap.get(oppId).Drive_Site__r.sked_Security_Directions__c) ?  
                                            opportunityMap.get(oppId).Drive_Site__r.sked_Security_Directions__c.replace('\n','<br>') : '');
                    wrap.securityInformationNeeded = opportunityMap.get(oppId).Drive_Site__r.sked_Security_Information_Needed__c;
                    wrap.escortRequired = opportunityMap.get(oppId).Drive_Site__r.sked_Escort_Required__c ? 'Yes' : 'No';
                    wrap.equipmentXRayRequired = opportunityMap.get(oppId).Drive_Site__r.sked_Equipment_X_Ray_Required__c ? 'Yes' : 'No';
                    wrap.preDriveSecurityDueDate = opportunityMap.get(oppId).Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c;
                    wrap.noCellPhones = opportunityMap.get(oppId).Drive_Site__r.sked_No_Cell_Phones__c ? 'Yes' : 'No';
                    wrap.staffList = opportunityMap.get(oppId).Drive_Site__r.sked_Staff_List__c;
                    wrap.sponsorSecurityFormRequired = opportunityMap.get(oppId).Drive_Site__r.Sponsor_Security_Form_Required__c;
                    wrap.emergencyActionPlan = opportunityMap.get(oppId).Drive_Site__r.sked_Safety_Emergency_Action_Plan__c;
                    wrap.siteInspectionCompletedBy = opportunityMap.get(oppId).Drive_Site__r.sked_Site_Inspection_Completed_By__r.Name;
                    wrap.emergencyContact = opportunityMap.get(oppId).Drive_Site__r.sked_Emergency_Contact__r.Name;
                    wrap.siteInspectionCompleted = getFormattedDate(opportunityMap.get(oppId).Drive_Site__r.sked_Date_Site_Inspection_Completed__c,false);
                    wrap.siteMainPhone = opportunityMap.get(oppId).Drive_Site__r.sked_Site_Main_Phone__c;
                    wrap.siteInspectionComments = opportunityMap.get(oppId).Drive_Site__r.sked_Site_Inspection_Comments__c;
                    wrap.elevatorType = opportunityMap.get(oppId).Drive_Site__r.sked_Elevator_Type__c;
                    wrap.elevatorOpen = getFormattedTime(opportunityMap.get(oppId).Drive_Site__r.sked_Elevator_Open__c);
                    wrap.roomSize = opportunityMap.get(oppId).Drive_Site__r.sked_Room_Size__c;
                    wrap.elevatorClosed = getFormattedTime(opportunityMap.get(oppId).Drive_Site__r.sked_Elevator_Close__c);
                    wrap.maximumBeds = opportunityMap.get(oppId).Drive_Site__r.sked_Maximum_Beds__c != null ?
                                        String.valueOf(opportunityMap.get(oppId).Drive_Site__r.sked_Maximum_Beds__c.intValue()) : '';
                    wrap.siteOpen = getFormattedTime(opportunityMap.get(oppId).Drive_Site__r.sked_Site_Open__c);
                    wrap.maxAutoMachines =  opportunityMap.get(oppId).Drive_Site__r.sked_Max_Auto_Machines__c != null ?
                                        String.valueOf(opportunityMap.get(oppId).Drive_Site__r.sked_Max_Auto_Machines__c.intValue()) : '';
                    wrap.siteClosed = getFormattedTime(opportunityMap.get(oppId).Drive_Site__r.sked_Site_Close__c);
                    wrap.outsideStairs = opportunityMap.get(oppId).Drive_Site__r.sked_Outside_stairs__c != null ?
                                            String.valueOf(opportunityMap.get(oppId).Drive_Site__r.sked_Outside_stairs__c.intValue()) : '';
                    wrap.airConditioned = opportunityMap.get(oppId).Drive_Site__r.sked_Air_conditioned__c ? 'Yes' : 'No';
                    wrap.insideStairs = opportunityMap.get(oppId).Drive_Site__r.sked_Inside_stairs__c != null ?
                                        String.valueOf(opportunityMap.get(oppId).Drive_Site__r.sked_Inside_stairs__c.intValue()) : '';
                    wrap.heat = opportunityMap.get(oppId).Drive_Site__r.sked_Heat__c ? 'Yes' : 'No';
                    wrap.oneOneZeroOutlets = opportunityMap.get(oppId).Drive_Site__r.sked_110_outlets__c != null ?
                                                String.valueOf(opportunityMap.get(oppId).Drive_Site__r.sked_110_outlets__c.intValue()) : '';
                    wrap.breaklocation = opportunityMap.get(oppId).Drive_Site__r.sked_Break_location__c;
                    wrap.floorCoveringRequirment = opportunityMap.get(oppId).Drive_Site__r.sked_Floor_Covering_Requirement__c;
                    wrap.restroomlocation = opportunityMap.get(oppId).Drive_Site__r.sked_Restroom_Location__c;
                    wrap.onSiteFoodRequirements = opportunityMap.get(oppId).Drive_Site__r.sked_On_Site_Food_Canteen_Requirements__c;
                    wrap.canteenKittingRequirements = opportunityMap.get(oppId).Drive_Site__r.sked_Canteen_Requirements__c;
                }
                if(opportunityMap.get(oppId).Drive_Site__c != null && !siteVsTagMap.get(opportunityMap.get(oppId).Drive_Site__c).isEmpty()){
                    if(wrap.certificationData == null){
                        wrap.certificationData = new List<Certifications>();
                    }
                    for(sked_Location_Tag__c ltags : siteVsTagMap.get(opportunityMap.get(oppId).Drive_Site__c)){
                        Certifications crt = new Certifications();
                        crt.tagType = 'Site';
                        crt.tagName = ltags.sked_Tag__r.Name;
                        crt.minimumQuantity = ltags.sked_Minimum_Quantity__c != null ? String.valueOf(ltags.sked_Minimum_Quantity__c.intValue()) : '';
                        wrap.certificationData.add(crt);
                    }
                }
                if((opportunityMap.get(oppId).AccountId != null && !accVsServiceRoleMap.get(opportunityMap.get(oppId).AccountId).isEmpty())
                        || !oppVsContactRoleMap.get(oppId).isEmpty()){
                            maxRoleCount = maxRoleCount < oppVsContactRoleMap.get(oppId).size() ? oppVsContactRoleMap.get(oppId).size() : maxRoleCount;
                            wrap.contactsData = new List<AccountDriveContacts>();
                            for(Integer i=0; i<maxRoleCount; i++){
                                AccountDriveContacts adcWrap = new AccountDriveContacts();
                                if(opportunityMap.get(oppId).AccountId != null && i < accVsServiceRoleMap.get(opportunityMap.get(oppId).AccountId).size()){
                                    adcWrap.accountContactName = accVsServiceRoleMap.get(opportunityMap.get(oppId).AccountId).get(i).Contact__r.Name;
                                    adcWrap.accountContactRole = accVsServiceRoleMap.get(opportunityMap.get(oppId).AccountId).get(i).Account_Service_Role__c;
                                }else{
                                    adcWrap.accountContactName = '';
                                    adcWrap.accountContactRole = '';
                                }
                                if(i < oppVsContactRoleMap.get(oppId).size()){
                                    adcWrap.driveContactName = oppVsContactRoleMap.get(oppId).get(i).Contact.Name;
                                    adcWrap.driveContactRole = oppVsContactRoleMap.get(oppId).get(i).role;
                                }else{
                                    adcWrap.driveContactName = '';
                                    adcWrap.driveContactRole = '';
                                }
                                wrap.contactsData.add(adcWrap);
                            }
                }
                if((opportunityMap.get(oppId).AccountId != null && !accAffiliationMap.get(opportunityMap.get(oppId).AccountId).isEmpty())
                        || !drvAffiliationMap.get(oppId).isEmpty()){
                            maxAffiliationCount = maxAffiliationCount < drvAffiliationMap.get(oppId).size() ? drvAffiliationMap.get(oppId).size() : maxAffiliationCount;
                            wrap.affiliationData = new List<AccountDriveAffiliations>();
                            for(Integer i=0; i<maxAffiliationCount; i++){
                                AccountDriveAffiliations affWrap = new AccountDriveAffiliations();
                                affWrap.accountAffiliationName = (opportunityMap.get(oppId).AccountId != null 
                                                                && i < accAffiliationMap.get(opportunityMap.get(oppId).AccountId).size()) ?
                                                                accAffiliationMap.get(opportunityMap.get(oppId).AccountId).get(i) : '';
                                affWrap.driveAffiliationName = i < drvAffiliationMap.get(oppId).size() ? drvAffiliationMap.get(oppId).get(i) : '';
                                wrap.affiliationData.add(affWrap);
                            }
                }
                if(!oppVsOrderMap.get(oppId).isEmpty()){
                    wrap.orderData = new List<OrderWrapper>();
                    for(Order odr : oppVsOrderMap.get(oppId)){
                        OrderWrapper odrwrp = new OrderWrapper();
                        odrwrp.orderNumber = odr.OrderNumber;
                        odrwrp.localRecruitmentRequest = odr.Local_Recruitment_Request__c;
                        odrwrp.localRecruitmentReqNeedDate = getFormattedDate(odr.Local_Recruitment_Request_Need_by_Date__c,false);
                        odrwrp.publicityOrderBudget = odr.BudgetCurrency__c != null ? '$'+odr.BudgetCurrency__c.format() : '';
                        odrwrp.publicityOrderAmount = odr.TotalAmount != null ? '$'+odr.TotalAmount.format() : '';
                        odrwrp.publicityComments = odr.Publicity_Comment__c;
                        if(orderVsProductMap.get(odr.Id) != null && !orderVsProductMap.get(odr.Id).isEmpty()){
                            odrwrp.publicityProductData = new List<PublicityProductsWrapper>();
                            for(OrderItem prdt : orderVsProductMap.get(odr.Id)){
                                PublicityProductsWrapper prdtWrp = new PublicityProductsWrapper();
                                prdtWrp.publicityProduct = prdt.Product2Id != null ? prdt.Product2.Name : '';
                                prdtWrp.publicityQuantity = prdt.Quantity != null ? String.valueOf(prdt.Quantity.intValue()) : '';
                                prdtWrp.productCost = prdt.TotalPrice != null ? '$'+prdt.TotalPrice.format() : '';
                                odrwrp.publicityProductData.add(prdtWrp);
                            }
                        }
                        wrap.orderData.add(odrwrp);
                    }
                }
                data.add(wrap);
            }
        }
        return data;
    }
    
    public static String getFormattedDate(Date preDate,Boolean includeDay){
        String result = '';
        if(preDate != null){
            if(includeDay == true){
                result = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day()).format('MM/dd/yyyy EEEE');
            }else{
                result = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day()).format('MM/dd/yyyy');
            }
        }
        return result;
    }

    public static String getFormattedTime(Time timeVal){
        String result = '';
        if(timeVal != null){
            result = Math.mod(timeVal.hour(), 12).toString().replaceAll('^(0)$','12').leftPad(2,'0')
                    +':'+timeVal.minute().toString().leftPad(2,'0')
                    +(timeVal.hour() < 12 ? ' AM' : ' PM');
        }
        return result;
    }

    public class SponsorPlanningReportPDFWrapper{
        public String accountName {get; set;}
        public String driveDate {get; set;}
        public String startTime {get; set;}
        public String endTime {get; set;}
        public String premierPartnerAff {get; set;}
        public String driveStage {get; set;}
        public String driveStatus {get; set;}
        public String driveProductivity {get; set;}
        public String primaryAM {get; set;}
        public String primaryContact {get; set;}
        public String primaryEmailPhone {get; set;}
        public String anticipatedRegDonors {get; set;}
        public String tempAnticipatedRegDonors {get; set;}
        public String wbProcedureProjection {get; set;}
		public String tempWBProcedureProjection {get; set;}
		public String twoRBCProcedureProjection {get; set;}
		public String temp2RBCProcedureProjection {get; set;}
		public String totalProductProjection {get; set;}
		public String tempProductProjection {get; set;}
        public String presentingDonorCapacity {get; set;}
        public String tempCDAOplus {get; set;}
        public String tempCDAOminus {get; set;}
        public String driveWBEligibility {get; set;}
        public String drivePREligibility {get; set;}
        public String totalSlots {get; set;}
        public String scheduledAppointments {get; set;}
        public String webSchedulingStartDate {get; set;}
        public String webSchedulingEndDate {get; set;}
        public String afterHoursContact {get; set;}
        public String afterHoursContactPh {get; set;}
        public String whomToMeet {get; set;}
        public String militaryAuthorityName {get; set;}
        public String collectionOperation {get; set;}
        public String locationName {get; set;}
        public String siteWirelessPolicy {get; set;}
        public String floorDescription {get; set;}
        public String automationSuitability {get; set;}
        public String roomName {get; set;}
        public String siteContact {get; set;}
        public String siteAddress {get; set;}
        public String drivingDirectionFromCO {get; set;}
        public String arcVehicleParkingDirections {get; set;}
        public String staffParkingDirections {get; set;}
        public String payForParkingDetails {get; set;}
        public String unloadingConditions {get; set;}
        public String unloadingDirectionDetails {get; set;}
        public String additionalDriveLogistics {get; set;}
        public String securityDirections {get; set;}
        public String securityEscortName {get; set;}
        public String securityInformationNeeded {get; set;}
        public String escortRequired {get; set;}
        public String setupTime {get; set;}
        public String equipmentXRayRequired {get; set;}
        public String preDriveSecurityDueDate {get; set;}
        public String noCellPhones {get; set;}
        public String staffList {get; set;}
        public String sponsorSecurityFormRequired {get; set;}
        public String emergencyActionPlan {get; set;}
        public String siteInspectionCompletedBy {get; set;}
        public String emergencyContact {get; set;}
        public String siteInspectionCompleted {get; set;}
        public String siteMainPhone {get; set;}
        public String siteInspectionComments {get; set;}
        public String elevatorType {get; set;}
        public String elevatorOpen {get; set;}
        public String roomSize {get; set;}
        public String elevatorClosed {get; set;}
        public String maximumBeds {get; set;}
        public String siteOpen {get; set;}
        public String maxAutoMachines {get; set;}
        public String siteClosed {get; set;}
        public String outsideStairs {get; set;}
        public String airConditioned {get; set;}
        public String insideStairs {get; set;}
        public String heat {get; set;}
        public String oneOneZeroOutlets {get; set;}
        public String breaklocation {get; set;}
        public String floorCoveringRequirment {get; set;}
        public String restroomlocation {get; set;}
        public String onSiteFoodRequirements {get; set;}
        public String canteenKittingRequirements {get; set;}
        public String callListRecipient {get; set;}
        public String publishToCallCenter {get; set;}
        public String driveKeyword {get; set;}
        public String sendEmail {get; set;}
        public String directDonorsTo {get; set;}
        public String sendMailers {get; set;}
        public String onlineDonorMessage {get; set;}
        public String onlineSchedulingEnabled {get; set;}
        public List<ShiftWrapper> shiftData {get; set;}
        public List<AccountDriveContacts> contactsData {get; set;}
        public List<Certifications> certificationData {get; set;}
        public List<AccountDriveAffiliations> affiliationData {get; set;}
        public List<OrderWrapper> orderData {get; set;}
        public List<FutureDriveWrapper> futureDrives {get; set;}
    }
    
    public class ShiftWrapper{
        public String shiftName {get; set;}
        public String twoRBCProcProj  {get; set;}
        public String twoRBCProdProj {get; set;}
        public String wbProcProj {get; set;}
        public String wbProdProj {get; set;}
        public String totalProcProj {get; set;}
        public String totalProdProj {get; set;}
        public String shiftHour {get; set;}
        public String lunchBreak {get; set;}
        public String arcVolunteer {get; set;}
        public String sponsorVolunteer {get; set;}
    }
    
    public class AccountDriveContacts{
        public String accountContactName {get; set;}
        public String accountContactRole {get; set;}
        public String driveContactName {get; set;}
        public String driveContactRole {get; set;}
    }

    public class Certifications{
        public String tagType {get; set;}
        public String tagName {get; set;}
        public String minimumQuantity {get; set;}
    }

    public class AccountDriveAffiliations{
        public String accountAffiliationName {get; set;}
        public String driveAffiliationName {get; set;}
    }

    public class OrderWrapper{
        public String orderNumber {get; set;}
        public String localRecruitmentRequest {get; set;}
        public String localRecruitmentReqNeedDate {get; set;}
        public String publicityOrderBudget {get; set;}
        public String publicityOrderAmount {get; set;}
        public String publicityComments {get; set;}
        public List<PublicityProductsWrapper> publicityProductData {get; set;}
    }

    public class PublicityProductsWrapper{
        public String publicityProduct {get; set;}
        public String publicityQuantity {get; set;}
        public String productCost {get; set;}
    }

    public class FutureDriveWrapper{
        public String driveDate {get; set;}
        public String siteName {get; set;}
        public String startTime {get; set;}
        public String endTime {get; set;}
        public String driveStatus {get; set;}
        public String driveStage {get; set;}
        public String primaryContactName {get; set;}
    }
}