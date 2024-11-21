public class skedResourceOverrideOneTimeBatch implements Database.Batchable<sked__Job_Allocation__c>, Database.Stateful {
    DateTime migrationDate;
    protected string lastId = '';

    public skedResourceOverrideOneTimeBatch(DateTime migrationDate) {
        this.lastId = '';
        this.migrationDate = migrationDate;
    }

    public skedResourceOverrideOneTimeBatch(DateTime migrationDate, Id lastId) {
        this.lastId = lastId;
        this.migrationDate = migrationDate;
    }
    
    public List<sked__Job_Allocation__c> start(Database.BatchableContext bc) {
        Set<String> deletedJobAllocationStatuses = new Set<String>{
            skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
            skedConstants.JOB_ALLOCATION_STATUS_DELETED
        };

        return [
            SELECT Id, sked__Job__c, sked__Resource__c,
            (SELECT Id, skedHC__Resource__c, sked_Drive__c, sked_Drive__r.sked_Collection_Operation__c, 
                sked_Drive__r.sked_Drive_Date__c
                FROM skedHC__Exception_Log__r
                WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO
                AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN)
            FROM sked__Job_Allocation__c
            WHERE CreatedDate >= :this.migrationDate
            AND sked__Status__c != :deletedJobAllocationStatuses
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 10000
        ];
    }

    public void execute(Database.BatchableContext bc, List<sked__Job_Allocation__c> jobAllocations) {
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        for (sked__Job_Allocation__c ja : jobAllocations) {
            resourceIds.add(ja.sked__Resource__c);
            jobIds.add(ja.sked__Job__c);
        }

        Map<Id, sked__Job__c> jobById = new Map<Id, sked__Job__c>([
            SELECT Id, Name, sked_Drive__r.sked_Collection_Operation__c, sked_Drive__r.sked_Drive_Date__c
            FROM sked__Job__c
            WHERE Id IN :jobIds
        ]);

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, Name, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                (SELECT Id, sked_Biomed_Collection_Op_Center__c, sked_Start_Date__c, sked_End_Date__c
                FROM sked_Resource_Biomed_Collection_Ops__r
                ),
                (SELECT Id, sked_Collection_Operation__c, sked__Start__c, sked__End__c, sked_Start_Date__c, sked_End_Date__c
                FROM sked__Resource_Overrides__r
                )
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);


        List<sked__Resource_Override__c> resourceOverrides = new List<sked__Resource_Override__c>();
        List<skedHC__Exception__c> exceptionsToDelete = new List<skedHC__Exception__c>();
        for (sked__Job_Allocation__c ja : jobAllocations) {
            sked__Job__c job = jobById.get(ja.sked__Job__c);
            Id driveCo = job.sked_Drive__r.sked_Collection_Operation__c;
            Date driveDate = job.sked_Drive__r.sked_Drive_Date__c;
            sked__Resource__c resource = resourceById.get(ja.sked__Resource__c);

            if (!skedResourceUtils.getResourceBelongsToCollectionOp(resource, driveCo, job.sked_Drive__r.sked_Drive_Date__c)) {
                resourceOverrides.add(new sked__Resource_Override__c(
                    sked__Resource__c = resource.Id,
                    sked_Collection_Operation__c = driveCo,
                    sked__Start__c = Datetime.newInstance(driveDate, Time.newInstance(0,0,0,0)),
                    sked__End__c = Datetime.newInstance(driveDate, Time.newInstance(23,59,59,0))
                ));

                if (ja.skedHC__Exception_Log__r != null && !ja.skedHC__Exception_Log__r.isEmpty()) {
                    exceptionsToDelete.addAll(ja.skedHC__Exception_Log__r);
                }
            }
        }
        
        insert resourceOverrides;
        delete exceptionsToDelete;

        this.lastId = jobAllocations.get(jobAllocations.size()-1).Id;
    }

    public void finish(Database.BatchableContext bc) {
        Set<String> deletedJobAllocationStatuses = new Set<String>{
            skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
            skedConstants.JOB_ALLOCATION_STATUS_DELETED
        };
        List<sked__Job_Allocation__c> remainingJobAllocations = [
            SELECT Id, sked__Job__c, sked__Resource__c,
            (SELECT Id, skedHC__Resource__c, sked_Drive__c, sked_Drive__r.sked_Collection_Operation__c, 
                sked_Drive__r.sked_Drive_Date__c
                FROM skedHC__Exception_Log__r
                WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO
                AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN)
            FROM sked__Job_Allocation__c
            WHERE CreatedDate >= :this.migrationDate
            AND sked__Status__c != :deletedJobAllocationStatuses
            AND Id > :this.lastId
            ORDER BY Id ASC
            LIMIT 1
        ];

        if (!remainingJobAllocations.isEmpty()) {
            Database.executeBatch(new skedResourceOverrideOneTimeBatch(this.migrationDate, this.lastId), 200);
        }
    }
}