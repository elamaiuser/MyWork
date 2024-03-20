/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 6/22/2023                  Ankit Kundu            Logic for HRP-6231
 * */
public class MassUpdateOpportunity {
    @InvocableMethod(label='updateOppUsingApexandBatch' description='return list of Opportunity' category='Opportunity')
    public static void updateSelectedRecords(List<oppVariable> oppWrapper){         
        MassUpdateOpportunityBatch objbatch = new MassUpdateOpportunityBatch(oppWrapper);
        Database.executeBatch(objbatch,200);
    }
       public class oppVariable{
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
    }  
}