global class skedRegulatedMedicalScreenerGenBatch implements System.Schedulable, Database.Batchable<sked_Drive__c> {
    
    private final Decimal TOTAL_PRODUCTS_PROJECTED = 30;
    private final String DRIVE_INDUSTRY_SCHOOL = 'High School';
    private final String DRIVE_INDUSTRY_COLLEGE = 'College';
    private final String ACC_MARKETING_PREMIER_CURRENT = 'Premier Current';
    private final String ACC_MARKETING_PREMIER_PRIOR = 'Premier Prior';
    private final String OPP_MARKETING_HONOR_MEMORY = 'In Honor/In Memory Of';
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedRegulatedMedicalScreenerGenBatch(), 200);
    }
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        Date dateThreshold = system.today().addDays(56); //8 weeks
        
        Set<Id> driveIdsHaveMedical = new Set<Id>();
        for (sked__Job__c medicalJob : [SELECT Id, sked_Drive__c
                                        FROM sked__Job__c
                                        WHERE sked_Volunteer_Role__c = :skedConstants.JOB_VOLUNTEER_ROLE_MEDICAL_SCREENER
                                        AND sked_Drive__r.sked_Drive_Date__c >= TODAY
                                        AND sked_Drive__r.sked_Drive_Date__c <= :dateThreshold
                                        AND sked_Drive__r.sked_Total_Products_Projected__c >= :TOTAL_PRODUCTS_PROJECTED 
                                        AND sked_Drive__r.sked_Drive_Site__r.sked_Physical_Location_Type__c != :skedConstants.LOCATION_TYPE_OUTSIDE
                                        AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED]) {
                                            driveIdsHaveMedical.add(medicalJob.sked_Drive__c);
                                        }
        
        return [SELECT Id, sked_Industry_Code__c, sked_Opportunity__r.AccountId, sked_Opportunity__c,
                sked_Projected_Registered_Donors__c, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c,
                sked_Drive_Site__c, sked_Collection_Operation__c, sked_Min_Shift_Start__c, sked_Max_Shift_End__c,
                (SELECT Id 
                 FROM sked_Drive_Shifts__r 
                 ORDER BY sked_Start__c ASC
                 LIMIT 1)
                FROM sked_Drive__c
                WHERE Id NOT IN :driveIdsHaveMedical
                AND sked_Projected_Registered_Donors__c != NULL
                AND sked_Min_Shift_Start__c != NULL
                AND sked_Max_Shift_End__c != NULL
                AND sked_Drive_Date__c >= TODAY 
                AND sked_Drive_Date__c <= :dateThreshold 
                AND sked_Total_Products_Projected__c >= :TOTAL_PRODUCTS_PROJECTED 
                AND sked_Drive_Site__r.sked_Physical_Location_Type__c != :skedConstants.LOCATION_TYPE_OUTSIDE];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> lsDriveRecs) {
        if (lsDriveRecs.isEmpty()) return;
        
        // get drive accounts & opps without specific 'Marketing programs'
        Set<Id> setAccIds = new Set<Id>();
        Set<Id> setOppIds = new Set<Id>();
        getMarketingAccOpp(lsDriveRecs, setAccIds, setOppIds);
        
        Map<Id, Id> mapDriveToRegion = getMapDriveToRegion(lsDriveRecs);
        
        // loop through each drive & when specific condition is met, create 'volunteer job'
        List<sked__Job__c> lsJobsToCreate = new List<sked__Job__c>();
        for (sked_Drive__c driveRec : lsDriveRecs) {
            if (!driveRec.sked_Drive_Shifts__r.isEmpty()) {
                if ((!String.isBlank(driveRec.sked_Industry_Code__c) && (driveRec.sked_Industry_Code__c == DRIVE_INDUSTRY_SCHOOL || driveRec.sked_Industry_Code__c.containsIgnoreCase(DRIVE_INDUSTRY_COLLEGE)))
                    || setAccIds.contains(driveRec.sked_Opportunity__r.AccountId)
                    || setOppIds.contains(driveRec.sked_Opportunity__c)) {
                        Decimal calculatedQty = getCalculatedQuantity(driveRec);
                        Id regionId = mapDriveToRegion.get(driveRec.Id);
                        Decimal duration = skedDateTimeUtils.getDifferentMinutes(driveRec.sked_Min_Shift_Start__c, driveRec.sked_Max_Shift_End__c);
                        
                        if (calculatedQty != NULL && !String.isBlank(regionId) && duration != NULL) {
                            sked__Job__c newSkedJob = new sked__Job__c(
                                sked_Drive__c = driveRec.Id,
                                sked_Drive_Shift__c = driveRec.sked_Drive_Shifts__r[0].Id,
                                sked__Location__c = driveRec.sked_Drive_Site__c,
                                sked__Region__c = regionId,
                                sked_Volunteer_Role__c = skedConstants.JOB_VOLUNTEER_ROLE_MEDICAL_SCREENER,
                                sked_Redcross_Volunteer_Quantity__c = calculatedQty,
                                sked_Sponsor_Volunteer_Quantity__c = 0,
                                sked__Quantity__c = calculatedQty,
                                sked__Start__c = driveRec.sked_Min_Shift_Start__c,
                                sked__Finish__c = driveRec.sked_Max_Shift_End__c,
                                sked__Duration__c = duration
                            );
                            lsJobsToCreate.add(newSkedJob);
                        }
                    }
            }
        }
        
        if (!lsJobsToCreate.isEmpty()) {
            insert lsJobsToCreate;
        }
    }
    
    private Map<Id, Id> getMapDriveToRegion(List<sked_Drive__c> lsDriveRecs) {
        Map<Id, Id> mapDriveToRegion = new Map<Id, Id>();
        
        if (lsDriveRecs.isEmpty()) {
            return mapDriveToRegion;
        }
        
        // get siteIds , collOperIds from drive
        Set<Id> setSiteIds = new Set<Id>();
        Set<Id> setColOperIds = new Set<Id>();
        for (sked_Drive__c driveRec : lsDriveRecs) {
            if (String.isBlank(driveRec.sked_Drive_Site__c) || String.isBlank(driveRec.sked_Collection_Operation__c)) {
                continue;
            }
            
            setSiteIds.add(driveRec.sked_Drive_Site__c);
            setColOperIds.add(driveRec.sked_Collection_Operation__c);
        }
        
        // get 'site collection operation' records & add in a map for lookup in next step
        Map<String, List<sked_Site_Collection_Operation__c>> mapSiteColOperToDates = new Map<String, List<sked_Site_Collection_Operation__c>>();
        for (sked_Site_Collection_Operation__c siteColOperRec :
             [SELECT Id, sked_Site__c, sked_Collection_Operation__c, sked_Region__c, sked_Start_Date__c, sked_End_Date__c 
              FROM sked_Site_Collection_Operation__c 
              WHERE sked_Site__c IN :setSiteIds AND sked_Collection_Operation__c IN :setColOperIds]) {
                  String key = siteColOperRec.sked_Site__c + ':' + siteColOperRec.sked_Collection_Operation__c;
                  List<sked_Site_Collection_Operation__c> lsCollOpers = mapSiteColOperToDates.get(key);
                  if (lsCollOpers == null) {
                      lsCollOpers = new List<sked_Site_Collection_Operation__c>();
                  }
                  lsCollOpers.add(siteColOperRec);
                  mapSiteColOperToDates.put(key, lsCollOpers);
              }
        
        // loop through each drive & find the right 'site collection operation' matching the drive date
        for (sked_Drive__c driveRec : lsDriveRecs) {
            String key = driveRec.sked_Drive_Site__c + ':' + driveRec.sked_Collection_Operation__c;
            List<sked_Site_Collection_Operation__c> lsCollOpers = mapSiteColOperToDates.get(key);
            Date driveDate = driveRec.sked_Drive_Date__c;
            if (lsCollOpers != null && driveDate != null) {
                for (sked_Site_Collection_Operation__c siteColOperRec : lsCollOpers) {
                    if (driveDate >= siteColOperRec.sked_Start_Date__c &&  driveDate <= siteColOperRec.sked_End_Date__c) {
                        if (siteColOperRec.sked_Region__c == null) {
                            continue;
                        }
                        mapDriveToRegion.put(driveRec.Id, siteColOperRec.sked_Region__c);
                        break;
                    }
                }
            }
        }
        return mapDriveToRegion;
    }
    
    private void getMarketingAccOpp(List<sked_Drive__c> lsDriveRecs, Set<Id> setAccIds, Set<Id> setOppIds) {
        Set<Id> driveAccountIds = new Set<Id>();
        Set<Id> driveOppIds = new Set<Id>();
        for (sked_Drive__c driveRec : lsDriveRecs) {
            driveAccountIds.add(driveRec.sked_Opportunity__r.AccountId);
            driveOppIds.add(driveRec.sked_Opportunity__c);
        }
        
        List<String> lsPremierPrgms = new List<String> {ACC_MARKETING_PREMIER_CURRENT, ACC_MARKETING_PREMIER_PRIOR};
            for (Account_Marketing_Program__c accMarkPgm : 
                 [SELECT Account__c 
                  FROM Account_Marketing_Program__c 
                  WHERE Marketing_Program__r.Name IN :lsPremierPrgms AND Account__c IN :driveAccountIds]) {
                      setAccIds.add(accMarkPgm.Account__c);
                  }
        
        for (Drive_Marketing_Programs__c oppMarkPgm : 
             [SELECT Id, Blood_Drive_Opportunity__c
              FROM Drive_Marketing_Programs__c 
              WHERE Marketing_Program__r.Name = :OPP_MARKETING_HONOR_MEMORY AND Blood_Drive_Opportunity__c IN :driveOppIds]) {
                  setOppIds.add(oppMarkPgm.Blood_Drive_Opportunity__c);
              }
    }
    
    private Decimal getCalculatedQuantity(sked_Drive__c driveRec) {
        Decimal noOfVolunteerDonorAmbassadors;
        
        try {
            if (driveRec.sked_Projected_Registered_Donors__c <= 70) {
                noOfVolunteerDonorAmbassadors = 1;
            } 
            else {
                noOfVolunteerDonorAmbassadors = 1 + Math.ceil((driveRec.sked_Projected_Registered_Donors__c - 70) / 60);
            }
            
            DateTime driveStartTime = DateTime.newInstance(driveRec.sked_Drive_Date__c, driveRec.sked_Start_Time__c);
            DateTime driveEndTime = DateTime.newInstance(driveRec.sked_Drive_Date__c, driveRec.sked_End_Time__c);
            Decimal driveLength = skedDateTimeUtils.getDifferentMinutes(driveStartTime, driveEndTime) / 60;
            if (driveLength > 6.5) {
                noOfVolunteerDonorAmbassadors = Math.ceil(noOfVolunteerDonorAmbassadors * 0.5);
            }
        } 
        catch (Exception e) {
            System.debug('Exception caught - ' + e.getMessage());
            noOfVolunteerDonorAmbassadors = null;
        }
        
        return noOfVolunteerDonorAmbassadors;
    }
    
    global void finish(Database.BatchableContext BC) {}
}