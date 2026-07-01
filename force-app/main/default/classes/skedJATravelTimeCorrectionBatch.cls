global class skedJATravelTimeCorrectionBatch implements Database.Batchable<sked__Job_Allocation__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected Set<Id> jobAllocationIds;
    protected Set<Id> resourceIds;
    
    global skedJATravelTimeCorrectionBatch(Set<Id> inputJobAllocationIds) { 
        this.jobAllocationIds = inputJobAllocationIds;
        this.resourceIds = new SeT<Id>();
        if (this.jobAllocationIds == NULL || this.jobAllocationIds.isEmpty()) {
            List<sked__Job_Allocation__c> jobAllocations = [
                SELECT Id, sked__Resource__c
                FROM sked__Job_Allocation__c
                WHERE sked__Estimated_Travel_Time__c != NULL
                AND sked__Estimated_Travel_Time__c > 0
                AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c >= TODAY
                AND sked__Job__r.sked_Resource_Role__c != NULL
                AND sked__Status__c != 'Deleted'
            ];
            this.jobAllocationIds = new Set<Id>();
            for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
                this.jobAllocationIds.add(jobAllocation.Id);
            }
        }
    }
    
    global List<sked__Job_Allocation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked__Estimated_Travel_Time__c, sked__Resource__c,
                sked__Job__r.sked_Drive__r.sked_Collection_Operation__c, sked__Job__r.sked_Drive__r.sked_Drive_Date__c,
                sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                FROM sked__Job_Allocation__c
                WHERE Id IN :this.jobAllocationIds];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> records) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Job_Allocation__c record : records) {
            resourceIds.add(record.sked__Resource__c);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, 
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
            sked_Biomed_Collection_Op_Center__c
            FROM sked_Resource_Biomed_Collection_Ops__r)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
        List<sked__Job_Allocation__c> recordsToUpdate = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c record : records) {
            this.resourceIds.add(record.sked__Resource__c);
            
            boolean isPrimary = record.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c 
                == record.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c;
            boolean isSecondary = FALSE;
            if (!isPrimary) {
                sked__Resource__c resource = mapResource.get(record.sked__Resource__c);
                if (resource.sked_Resource_Biomed_Collection_Ops__r != NULL && !resource.sked_Resource_Biomed_Collection_Ops__r.isEmpty()) {
                    for (sked_Resource_Biomed_Collection_Op__c secondaryCO : resource.sked_Resource_Biomed_Collection_Ops__r) {
                        if (record.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c == secondaryCO.sked_Biomed_Collection_Op_Center__c) {
                            if ((secondaryCO.sked_Start_Date__c == NULL || secondaryCO.sked_Start_Date__c <= record.sked__Job__r.sked_Drive__r.sked_Drive_Date__c) 
                                && (secondaryCO.sked_End_Date__c == NULL || secondaryCO.sked_End_Date__c >= record.sked__Job__r.sked_Drive__r.sked_Drive_Date__c)){
                                isSecondary = TRUE;
                                break;
                            }
                        }
                    }
                }
            }
            if (isPrimary || isSecondary) {
                record.sked__Estimated_Travel_Time__c = 0;
                recordsToUpdate.add(record);
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {}
    
}