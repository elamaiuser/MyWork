public with sharing class DriveService {
    @AuraEnabled 
    public static List<Drive> retrieveDrives(String periodId, Integer drivesToShow) {
        List<Drive> drives = new List<Drive>();

        if (String.isNotBlank(periodId)) {
            if (drivesToShow == null) {
                drivesToShow = 10;
            }
            List<Period> periods = [ select FullyQualifiedLabel,
                                            startDate,
                                            endDate
                                       from Period
                                      where id = :periodId  ];               
            
            if (!periods.isEmpty()) {
               for (Opportunity theOpportunity : [ select Name,
                                                          StageName,
                                                          CloseDate,
                                                          Drive_Source__c,
                                                          End_Time__c,
                                                          Start_Time__c,
                                                          Collections_Zip_Code__r.Collection_Operation__c,
                                                          Collections_Zip_Code__r.Collection_Operation__r.Name,
                                                          Total_Projected_Procedures__c,
                                                          (select id from sked_Drives__r)
                                                     from Opportunity 
                                                    where OwnerId = :UserInfo.getUserId() 
                                                    and CloseDate >= :periods[0].startDate 
                                                    and CloseDate <= :periods[0].endDate
                                                    and CloseDate >= :System.today()
                                                    and StageName != 'Lost'
                                                    
                                                    order by CloseDate limit :drivesToShow]) {
                    Drive theDrive = new Drive();

                    theDrive.driveId = theOpportunity.Id;
                    theDrive.driveName = theOpportunity.Name;
                    theDrive.stageName = theOpportunity.StageName;
                    theDrive.driveDate = theOpportunity.CloseDate;
                    theDrive.startTime = theOpportunity.Start_Time__c;

                    theDrive.endTime = theOpportunity.End_Time__c;

                    theDrive.totalProjectedProcedures = theOpportunity.Total_Projected_Procedures__c;

                    if (theOpportunity.Collections_Zip_Code__r != null) {
                        theDrive.collectionOpId = theOpportunity.Collections_Zip_Code__r.Collection_Operation__c;
                        theDrive.collectionOpName = theOpportunity.Collections_Zip_Code__r.Collection_Operation__r.Name;
                    }

                    if (!theOpportunity.sked_Drives__r.isEmpty()) {
                        theDrive.calendarDriveId = theOpportunity.sked_Drives__r[0].id;
                        theDrive.stageName = 'Scheduling';
                    }                     

                    drives.add(theDrive);
                }
            }
        }

        return drives;
    }

    @AuraEnabled
    public static List<Drive> retrievePriorDrives(String periodId, Integer drivesToShow) {
        List<Drive> drives = new List<Drive>();

        if (String.isNotBlank(periodId)) {
            if (drivesToShow == null) {
                drivesToShow = 10;
            }
            List<Period> periods = [ select FullyQualifiedLabel,
                                            startDate,
                                            endDate
                                       from Period
                                      where id = :periodId  ];               
            
            if (!periods.isEmpty()) {
               for (Opportunity theOpportunity : [ select Name,
                                                          StageName,
                                                          CloseDate,
                                                          Drive_Source__c,
                                                          End_Time__c,
                                                          Start_Time__c,
                                                          Total_Projected_Procedures__c,
                                                          Collections_Zip_Code__r.Collection_Operation__c,
                                                          Collections_Zip_Code__r.Collection_Operation__r.Name,
                                                          (select id from sked_Drives__r)
                                                     from Opportunity 
                                                    where OwnerId = :UserInfo.getUserId() 
                                                    and CloseDate >= :periods[0].startDate 
                                                    and CloseDate <= :periods[0].endDate
                                                    and CloseDate < :System.today()
                                                    and StageName != 'Lost'
                                                    
                                                    order by CloseDate limit :drivesToShow]) {
                    Drive theDrive = new Drive();

                    theDrive.driveId = theOpportunity.Id;
                    theDrive.driveName = theOpportunity.Name;
                    theDrive.stageName = theOpportunity.StageName;
                    theDrive.driveDate = theOpportunity.CloseDate;
                    theDrive.startTime = theOpportunity.Start_Time__c;

                    theDrive.endTime = theOpportunity.End_Time__c;

                    theDrive.totalProjectedProcedures = theOpportunity.Total_Projected_Procedures__c;

                    if (theOpportunity.Collections_Zip_Code__r != null) {
                        theDrive.collectionOpId = theOpportunity.Collections_Zip_Code__r.Collection_Operation__c;
                        theDrive.collectionOpName = theOpportunity.Collections_Zip_Code__r.Collection_Operation__r.Name;
                    }                    

                    if (!theOpportunity.sked_Drives__r.isEmpty()) {
                        theDrive.calendarDriveId = theOpportunity.sked_Drives__r[0].id;
                        theDrive.stageName = 'Scheduling';
                    }                    

                    drives.add(theDrive);
                }
            }
        }

        return drives;
    } 

    @AuraEnabled
    public static List<Drive> retrieveProspectDrives(String periodId, Integer drivesToShow) {
        List<Drive> drives = new List<Drive>();

        if (String.isNotBlank(periodId)) {
            if (drivesToShow == null) {
                drivesToShow = 10;
            }
            List<Period> periods = [ select FullyQualifiedLabel,
                                            startDate,
                                            endDate
                                       from Period
                                      where id = :periodId  ];               
            
            if (!periods.isEmpty()) {
                Date startDate = periods[0].startDate.addYears(-1);
                Date endDate = periods[0].endDate.addYears(-1);

               for (sked_Drive__c theSkeduloDrive : [ select Name,
                                                             sked_Drive_Productivity_Planned__c,
                                                             sked_Opportunity__r.Name,
                                                             sked_Opportunity__r.Id,
                                                             sked_Opportunity__r.StageName,
                                                             sked_Opportunity__r.CloseDate,
                                                             sked_Opportunity__r.Drive_Source__c,
                                                             sked_Opportunity__r.End_Time__c,
                                                             sked_Opportunity__r.Start_Time__c,
                                                             sked_Opportunity__r.Collections_Zip_Code__r.Collection_Operation__c,
                                                             sked_Opportunity__r.Collections_Zip_Code__r.Collection_Operation__r.Name,
                                                             sked_Opportunity__r.Total_Projected_Procedures__c
                                                        from sked_Drive__c 
                                                       where sked_Opportunity__r.OwnerId = :UserInfo.getUserId() 
                                                         and sked_Opportunity__r.CloseDate >= :startDate
                                                         and sked_Opportunity__r.CloseDate <= :endDate
                                                         and sked_Opportunity__r.StageName != 'Lost'
                                                         
                                                    order by sked_Drive_Productivity_Planned__c desc, sked_Opportunity__r.CloseDate limit :drivesToShow]) {
                    Drive theDrive = new Drive();

                    theDrive.driveId = theSkeduloDrive.sked_Opportunity__r.Id;
                    theDrive.calendarDriveId = theSkeduloDrive.Id;
                    theDrive.driveName = theSkeduloDrive.sked_Opportunity__r.Name;
                    theDrive.stageName = theSkeduloDrive.sked_Opportunity__r.StageName;
                    theDrive.driveDate = theSkeduloDrive.sked_Opportunity__r.CloseDate;
                    theDrive.startTime = theSkeduloDrive.sked_Opportunity__r.Start_Time__c;
                    
                    theDrive.endTime = theSkeduloDrive.sked_Opportunity__r.End_Time__c;
                 
                    theDrive.totalProjectedProcedures = theSkeduloDrive.sked_Opportunity__r.Total_Projected_Procedures__c;
                    theDrive.drivehealth = theSkeduloDrive.sked_Drive_Productivity_Planned__c;

                    if (theSkeduloDrive.sked_Opportunity__r.Collections_Zip_Code__r != null) {
                        theDrive.collectionOpId = theSkeduloDrive.sked_Opportunity__r.Collections_Zip_Code__r.Collection_Operation__c;
                        theDrive.collectionOpName = theSkeduloDrive.sked_Opportunity__r.Collections_Zip_Code__r.Collection_Operation__r.Name;
                    }                    
                  
                    drives.add(theDrive);
                }
            }
        }

        return drives;
    }     
    
    @AuraEnabled
    public static Drive retrieveDrive(String driveId) {
        Drive theDrive = new Drive();

        List<Opportunity> opps = [ select Name,
                                          StageName,
                                          CloseDate,
                                          Drive_Source__c,
                                          End_Time__c,
                                          Start_Time__c,
                                          Total_Projected_Procedures__c,
                                          (select id from sked_Drives__r)
                                     from Opportunity
                                   where Id = :driveId  ];

        if (!opps.isEmpty()) {
            theDrive.driveName = opps[0].Name;
            theDrive.stageName = opps[0].stageName;

            if (!opps[0].sked_Drives__r.isEmpty()) {
                theDrive.calendarDriveId = opps[0].sked_Drives__r[0].id;
                theDrive.stageName = 'Scheduling';
            }
        }

        theDrive.stages = new List<Stage>();

        for(Schema.picklistEntry plEntry: Opportunity.stagename.getDescribe().getPicklistValues()) {
            if (plEntry.getLabel() != 'Lost') {  
                Stage theStage = new Stage();
                theStage.label = plEntry.getLabel();
                theStage.value = plEntry.getValue();
                theDrive.stages.add(theStage);     
            }            
        } 

        Stage theStage = new Stage();
        theStage.label = 'Scheduling';
        theStage.value = 'Scheduling';
        theDrive.stages.add(theStage);         

        return theDrive;
    }     

    public static void populateDriveWorksheetData(List<sked_Drive__c> newRecords){
        if(newRecords == null){
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
                                                                Open_to_Public__c 
                                                        FROM Opportunity 
                                                        WHERE Id IN:opportunityIds]);
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
        if(opportunityMap.size() > 0){
            for(sked_Drive__c drv : newRecords){
                if(drv.sked_Opportunity__c != null && opportunityMap.containsKey(drv.sked_Opportunity__c)){
                    //drv.sked_Open_to_Public__c = opportunityMap.get(drv.sked_Opportunity__c).Open_to_Public__c;
                }
                if(drv.sked_Opportunity__c != null && contactRoleMapHM.size() > 0 && contactRoleMapHM.containsKey(drv.sked_Opportunity__c)){
                    //drv.sked_Whome_to_Meet__c = contactRoleMapHM.get(drv.sked_Opportunity__c);
                }
                if(drv.sked_Opportunity__c != null && contactRoleMapPC.size() > 0 && contactRoleMapPC.containsKey(drv.sked_Opportunity__c)){
                    drv.sked_Primary_Contact__c = contactRoleMapPC.get(drv.sked_Opportunity__c);
                }
            }
        }
    }    
    
    public class Drive {
        @AuraEnabled public List<Stage> stages;
        @AuraEnabled public String driveId;
        @AuraEnabled public String calendarDriveId;
        @AuraEnabled public String driveName;
        @AuraEnabled public String stageName;
        @AuraEnabled public Date driveDate;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal drivehealth;
        @AuraEnabled public Time startTime;
        @AuraEnabled public Time endTime;
        @AuraEnabled public String collectionOpId;
        @AuraEnabled public String collectionOpName;
        @AuraEnabled public Decimal totalProjectedProcedures;
    }

    public class Stage {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}