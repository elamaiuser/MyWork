/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 5/05/2023                  Ankit Kundu            Logic for HRP-6231
 * 15/01/2024                 Barnojit Sharma        Need ability to mass update the Keyword on a FS Account(HRP-10420)
 * 08/05/2024				  Priti Jana			 Logic for HRP-12112
 * ****************************************************************************/

public class MassUpdateOpportunity {
    @InvocableMethod(label='updateOppUsingApexandBatch' description='return list of Opportunity' category='Opportunity')
    public static void updateSelectedRecords(List<oppVariable> oppWrapper) { 
        Integer batchSize = Integer.valueOf(Custom_Messages__mdt.getInstance('Batch_Size_for_MassUpdateOpportunity').value__c); //HRP-12112
        MassUpdateOpportunityBatch objbatch = new MassUpdateOpportunityBatch(oppWrapper);
        Database.executeBatch(objbatch, batchSize); //HRP-12112
    }
    
    /* HRP-12112 --> Start Here
    Description : Below aura enabled method is used in BsfMassUpdateOpportunityFilteringModal custom lwc to fetch related opportunities based on certain filters
    */
    @AuraEnabled(cacheable=true) 
    public static List<Opportunity> getFilteredOpportunities(Map<String, Object> filterWrapper) {

        String oppInitialQuery = 'SELECT Id, Name, Drive_Date__c, Drive_Date_Day__c, Drive_Site__r.Operation_Type__c, Drive_Site__r.sked_Timezone__c, '+
                                 'Start_Time__c, End_Time__c, DriveStatus__c, '+
                                 'WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, '+
                                 'Plasma_Pheresis_Projected_Procedures__c, Platelet_Projected_Procedures__c '+
                                 'FROM Opportunity WHERE AccountId = :accountId';
        Date driveDateStart;
        Date driveDateEnd;

        String accountId = (String)filterWrapper.get('accountId');
        String driveName  = (string)filterWrapper.get('driveName');
        String sortBy = (String)filterWrapper.get('sortBy');
        String sortDirection = (String)filterWrapper.get('sortDirection');
        Integer recordsLimit = Integer.valueOf(filterWrapper.get('recordLimit'));
        Integer recordOffset = Integer.valueOf(filterWrapper.get('rowOffset'));
        List<String> driveStatus = filterWrapper.get('driveStatus') != NULL ? convertObjectListToStringList((List<object>)filterWrapper.get('driveStatus')) : new List<String>();
        List<String> dayOfDrive = filterWrapper.get('dayOfDrive') != NULL ? convertObjectListToStringList((List<Object>)filterWrapper.get('dayOfDrive')) : new List<String>();
        List<String> siteOperationType = filterWrapper.get('siteOperationType') != NULL ? convertObjectListToStringList((List<Object>)filterWrapper.get('siteOperationType')) : new List<String>();

        if(filterWrapper.get('driveDateStart') != NULL) {
            driveDateStart = Date.valueOf((String) filterWrapper.get('driveDateStart'));
        }
        if(filterWrapper.get('driveDateEnd') != NULL) {
            driveDateEnd = Date.valueOf((String) filterWrapper.get('driveDateEnd'));
        }
        
        if(driveDateStart != NULL) {
            oppInitialQuery += ' AND Drive_Date__c >= :driveDateStart';
        }
        if(driveDateEnd != NULL) {
            oppInitialQuery += ' AND Drive_Date__c <= :driveDateEnd';
        }
        if (String.isNotBlank(driveName)) {
            oppInitialQuery += ' AND Name LIKE \'%' + String.escapeSingleQuotes(driveName) + '%\'';
        }
        if (!driveStatus.isEmpty()) {
            oppInitialQuery += ' AND DriveStatus__c IN :driveStatus'; 
        }
        if (!dayOfDrive.isEmpty()) {
            oppInitialQuery += ' AND Drive_Date_Day__c IN :dayOfDrive';
        }
        if (!siteOperationType.isEmpty()) {
            oppInitialQuery += ' AND Drive_Site__r.Operation_Type__c IN :siteOperationType';
        }

        oppInitialQuery += ' ORDER BY Drive_Date__c DESC LIMIT :recordsLimit OFFSET :recordOffset';
        
        return Database.query(oppInitialQuery);
    }
    
    public static List<String> convertObjectListToStringList(List<Object> objectList) {
        List<String> stringList = new List<String>();
        for (Object obj : objectList) {
            if (obj instanceof String) {
                stringList.add((String) obj);
            }
        }
        return stringList;
    }
    // HRP-12112 --> Ends Here
    
    public class oppVariable {
        @InvocableVariable
        public List<Opportunity> oppToUpdate;
        @InvocableVariable
        public Integer updatedPlateletAsset;
        @InvocableVariable
        public Integer updatedPlasmaAsset;
        @InvocableVariable
        public Integer updated2rbcAsset;
        @InvocableVariable
        public String updatedCalendarDesc;      
        @InvocableVariable
        public Integer updatedAnticipatedRegisteredDonors; //Added for HRP-6231 
        @InvocableVariable
        public String updatedARegisteredDonorsReason;   //Added for HRP-6231 
        @InvocableVariable
        public String updatedOnlineDonor;
        @InvocableVariable
        public String updatedOpenToPublic;
        @InvocableVariable
        public String updatedStage;
        @InvocableVariable
        public Integer updatedPlateletPP;
        @InvocableVariable
        public Integer updatedPlasmaPheresisPP;
        @InvocableVariable
        public Integer updatedWBProjectedProc;
        @InvocableVariable
        public String updatedDRReason;
        @InvocableVariable
        public String updatedWBProcReason;
        @InvocableVariable
        public Integer updated2RBCProjProcedure;           
        @InvocableVariable
        public String updatedStartTime;
        @InvocableVariable
        public String updatedEndTime;
        @InvocableVariable
        public String updatedCancelledStage;
        @InvocableVariable
        public String updatedCancellationReason;
        @InvocableVariable
        public String updatedInitiatedBy;
        public String updatedProcessingStatus;
        @InvocableVariable
        public String updatedDriveKeyword; //added for HRP-10420
    }  
}