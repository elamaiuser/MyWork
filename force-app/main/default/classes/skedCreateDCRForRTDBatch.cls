public class skedCreateDCRForRTDBatch implements Database.Batchable<sObject>  {
    
    protected Set<Id> coIds;
    protected Date minDate;
    protected Date maxDate;
    
    protected Map<Id, List<sked_Role_Time_Detail__c>> map_coId_rtds;
    protected List<sked_Role_Time_Detail__c> globalRtds;

    public skedCreateDCRForRTDBatch(List<sked_Role_Time_Detail__c> rtds) {
        this.initialize(rtds);
    }
    
    private void initialize(List<sked_Role_Time_Detail__c> inputRtds) {
        this.coIds = new Set<Id>();
        
        this.map_coId_rtds = new Map<Id, List<sked_Role_Time_Detail__c>>();
        this.globalRtds = new List<sked_Role_Time_Detail__c>();
        
        boolean hasGlobalRTD = FALSE;
        for (sked_Role_Time_Detail__c rtd : inputRtds) {
            if (rtd.sked_Collection_Operation__c != NULL) {
                List<sked_Role_Time_Detail__c> rtds = this.map_coId_rtds.get(rtd.sked_Collection_Operation__c);
                if (rtds == NULL) {
                    rtds = new List<sked_Role_Time_Detail__c>();
                    this.map_coId_rtds.put(rtd.sked_Collection_Operation__c, rtds);
                }
                rtds.add(rtd);
            }
            else {
                this.globalRtds.add(rtd);
            }
            
            if (this.minDate == NULL || this.minDate > rtd.sked_Effective_Start_Date__c) {
                this.minDate = rtd.sked_Effective_Start_Date__c;
            }
            if (this.maxDate == NULL || this.maxDate < rtd.sked_Effective_End_Date__c) {
                this.maxDate = rtd.sked_Effective_End_Date__c;
            }
        }
        
        this.coIds = map_coId_rtds.keySet();
        if (!this.globalRtds.isEmpty()) {
            Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([
                SELECT ID, Name, External_ID__c
                FROM Biomed_Collection_Op_Center__c
                WHERE External_ID__c != NULL
                AND Name != 'Non-Collection Area'
            ]);
            this.coIds = mapCO.keySet();
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c,
            sked_Start_Time__c, sked_Timezone__c,
            sked_Operation_Type__c, sked_Drive_Site__r.sked_Physical_Location_Type__c
            FROM sked_Drive__c
            WHERE sked_Collection_Operation__c IN :this.coIds
            AND sked_Drive_Date__c >= TODAY
            AND sked_Drive_Date__c >= :this.minDate
            AND sked_Drive_Date__c <= :this.maxDate
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE
            ORDER BY sked_Collection_Operation__c, sked_Drive_Date__c ASC
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        List<sked_Drive__c> drivesToGenerateDCR = new List<sked_Drive__c>();
        
        for (sked_Drive__c drive : drives) {
            List<sked_Role_Time_Detail__c> rtdsToProcess = new List<sked_Role_Time_Detail__c>();
            List<sked_Role_Time_Detail__c> coRtds = this.map_coId_rtds.get(drive.sked_Collection_Operation__c);
            if (coRtds != NULL && !coRtds.isEmpty()) {
                rtdsToProcess.addAll(coRtds);
            }
            if (this.globalRtds != NULL && !this.globalRtds.isEmpty()) {
                rtdsToProcess.addAll(this.globalRtds);
            }
            
            for (sked_Role_Time_Detail__c rtd : rtdsToProcess) {
                List<String> affectedWeekdays;
                if (rtd.sked_Days_of_Week__c != null && rtd.sked_Days_of_Week__c != '') {
                    affectedWeekdays = rtd.sked_Days_of_Week__c.split(';');
                }
                DateTime driveDate = DateTime.newInstance(drive.sked_Drive_Date__c, drive.sked_Start_Time__c);
                driveDate = skedDateTimeUtils.toTimezone(driveDate, drive.sked_Timezone__c);
                string driveWeekday = driveDate.format('EEEE');
                
                if (affectedWeekdays != null && !affectedWeekdays.isEmpty()) {
                    if (affectedWeekdays.contains(driveWeekday)) {
                        Boolean requiresDCR = false;
                        
                        if (rtd.sked_Drive_Type__c == skedConstants.DRIVE_TYPE_MOBILE) {
                            Boolean isInsideOutside = rtd.sked_Mobile_Type__c == skedConstants.LOCATION_TYPE_INSIDE_OUTSIDE;
                            if (isInsideOutside || rtd.sked_Mobile_Type__c == drive.sked_Drive_Site__r.sked_Physical_Location_Type__c) {
                                requiresDCR = true;
                            }
                        } 
                        else if (rtd.sked_Drive_Type__c == skedConstants.DRIVE_TYPE_FIXED_SITE) {
                            if (rtd.sked_Fixed_Site_Operation_Type__c == drive.sked_Operation_Type__c) {
                                requiresDCR = true;
                            }
                        }
                        
                        if (requiresDCR) {
                            drive.sked_RTD_Change_DCR_Required__c = true;
                            drivesToGenerateDCR.add(drive);
                        }
                    }
                }
            }
        }
        
        if (!drivesToGenerateDCR.isEmpty()) { 
            update drivesToGenerateDCR;
        }
    }

    public void finish(Database.BatchableContext BC) {
        skedCreateNonUserChangeDCRBatch.schedule();
    }

}