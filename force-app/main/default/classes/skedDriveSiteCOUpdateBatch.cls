global class skedDriveSiteCOUpdateBatch implements Database.Batchable<sked_Drive__c>, Database.Stateful {
    
    protected Date driveDate;
    
    public skedDriveSiteCOUpdateBatch(Date inputDate) {
        this.driveDate = inputDate != NULL ? inputDate : system.today();
    }

    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Collection_Operation__c, sked_Drive_Site__c, sked_Drive_Date__c
                FROM sked_Drive__c
                WHERE sked_Site_Collection_Operation__c = NULL
                AND sked_Drive_Date__c != NULL
                AND sked_Drive_Date__c >= :this.driveDate
                ORDER BY sked_Drive_Date__c ASC
                LIMIT 50000];
    }

    global void execute(Database.BatchableContext BC, List<sked_Drive__c> skedDrives) {
        Set<Id> siteIds = new Set<Id>();
        Date minDate = skedDrives.get(0).sked_Drive_Date__c;
        Date maxDate = skedDrives.get(0).sked_Drive_Date__c;
        for (sked_Drive__c skedDrive : skedDrives) {
            siteIds.add(skedDrive.sked_Drive_Site__c);
            minDate = minDate > skedDrive.sked_Drive_Date__c ? skedDrive.sked_Drive_Date__c : minDate;
            maxDate = maxDate <= skedDrive.sked_Drive_Date__c ? skedDrive.sked_Drive_Date__c : maxDate;
        }
        List<sked_Site_Collection_Operation__c> siteCOs = [SELECT Id, sked_Collection_Operation__c, sked_Site__c
                                                           FROM sked_Site_Collection_Operation__c
                                                           WHERE sked_Site__c IN :siteIds
                                                           AND sked_Start_Date__c <= :maxDate
                                                           AND sked_End_Date__c >= :minDate
                                                           AND sked_Collection_Operation__c != NULL
                                                           ORDER BY sked_Start_Date__c ASC];
        Map<string, sked_Site_Collection_Operation__c> mapSiteCOByKey = new Map<string, sked_Site_Collection_Operation__c>();
        for (sked_Site_Collection_Operation__c siteCO : siteCOs) {
            string key = siteCO.sked_Site__c + ':' + siteCO.sked_Collection_Operation__c;
            mapSiteCOByKey.put(key, siteCO);
        }
        
        for (sked_Drive__c skedDrive : skedDrives) {
            string key = skedDrive.sked_Drive_Site__c + ':' + skedDrive.sked_Collection_Operation__c;
            if (mapSiteCOByKey.containsKey(key)) {
                skedDrive.sked_Site_Collection_Operation__c = mapSiteCOByKey.get(key).Id;
            }
        }
        update skedDrives;
        
        this.driveDate = skedDrives.get(skedDrives.size() - 1).sked_Drive_Date__c;
    }
    
    global void finish(Database.BatchableContext BC) { }
    
}