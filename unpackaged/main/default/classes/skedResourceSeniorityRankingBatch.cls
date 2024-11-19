global class skedResourceSeniorityRankingBatch implements System.Schedulable, Database.Batchable<sked_Territory__c> {

    Set<Id> territoryIds;
    Set<Id> skedResourceIds;
    global skedResourceSeniorityRankingBatch(Set<Id> territoryIds, Set<Id> skedResourceIds) {
        this.territoryIds = territoryIds;
        this.skedResourceIds = skedResourceIds;
    }

    global skedResourceSeniorityRankingBatch() {}
    
    global List<sked_Territory__c> start(Database.BatchableContext BC) {
        if (this.territoryIds != null && !this.territoryIds.isEmpty()) {
            return [
                SELECT Id
                FROM sked_Territory__c
                WHERE Id IN :this.territoryIds AND RecordType.Name = 'ARC Region'
            ];
        }

        return [
            SELECT Id
            FROM sked_Territory__c
            WHERE RecordType.Name = 'ARC Region'
        ];
    }
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedResourceSeniorityRankingBatch(), 1);
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Territory__c> records) {
        string exceptionCodeTemplate = '{{resourceName}} holds same Seniority Rank as {{conflictedResourceName}}. Manual Ranking Priority is required.';
        for (sked_Territory__c region : records) {
            List<Biomed_Collection_Op_Center__c> collectionOpsForRegion = [
                SELECT Id
                FROM Biomed_Collection_Op_Center__c
                WHERE sked_Territory__r.sked_Parent__c = :region.Id
            ];

            List<sked__Resource__c> skedResources = [
                SELECT Id, Name, sked_Hire_Date__c, CreatedDate, sked_Manual_Ranking_Priority__c, sked_Employment_Status__c
                FROM sked__Resource__c
                WHERE sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOpsForRegion
                AND sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            ];


            if (!skedResources.isEmpty()) {
                List<resourceModel> resources = new List<resourceModel>();
                for (sked__Resource__c skedResource : skedResources) {
                    resourceModel resource = new resourceModel();
                    resource.id = skedResource.Id;
                    resource.name = skedResource.Name;
                    resource.hireDate = skedResource.sked_Hire_Date__c;
                    resource.manualRankingPriority = skedResource.sked_Manual_Ranking_Priority__c != NULL ? skedResource.sked_Manual_Ranking_Priority__c : 99999;
                    resource.isActive = skedResource.sked_Employment_Status__c == skedConstants.RESOURCE_EMPLOYMENT_STATUS_ACTIVE;
                    resources.add(resource);
                }

                resources.sort();
                for (integer i = 0; i < resources.size(); i++) {
                    resourceModel resource = resources.get(i);
                    resource.seniorityRank = i + 1;
                    if (i > 0) {
                        resourceModel previousResource = resources.get(i - 1);
                        if (previousResource != NULL 
                            && previousResource.hireDate == resource.hireDate
                            && previousResource.manualRankingPriority == resource.manualRankingPriority
                            && previousResource.isActive == resource.isActive) {
                                resource.seniorityRank = previousResource.seniorityRank;
                        }
                    }
                }
                List<sked__Resource__c> skedResourcesToUpdate = new List<sked__Resource__c>();
                List<skedHC__Exception__c> skedExceptionLogToInsert = new List<skedHC__Exception__c>();
                for (integer i = 0; i < resources.size(); i++) {
                    resourceModel resource = resources.get(i);
                    sked__Resource__c skedResource = new sked__Resource__c(
                        Id = resource.id,
                        sked_Seniority_Rank__c = resource.seniorityRank
                    );
                    skedResourcesToUpdate.add(skedResource);

                    if (i > 0) {
                        resourceModel previousResource = resources.get(i - 1);
                        if (resource.seniorityRank == previousResource.seniorityRank) {
                            string exceptionMessage = exceptionCodeTemplate.replace('{{resourceName}}', resource.name)
                                                                            .replace('{{conflictedResourceName}}', previousResource.name);
                            skedHC__Exception__c skedException = new skedHC__Exception__c(
                                skedHC__Resource__c = resource.id,
                                sked_Conflicted_Resource__c = previousResource.id,
                                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_DUPLICATE_SENIORITY_RANKING,
                                skedHC__Exception__c = exceptionMessage
                            );
                            skedExceptionLogToInsert.add(skedException);
                        }
                    }
                }
                update skedResourcesToUpdate;
                
                delete [SELECT Id
                        FROM skedHC__Exception__c
                        WHERE skedHC__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOpsForRegion
                        AND sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_RESOURCE_DUPLICATE_SENIORITY_RANKING];
                if (!skedExceptionLogToInsert.isEmpty()) {
                    insert skedExceptionLogToInsert;
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if(this.skedResourceIds!=null && !this.skedResourceIds.isEmpty()) {
            List<sked__Resource__c> skedResourcesToUpdate = new List<sked__Resource__c>();
            for (Id resourceId : this.skedResourceIds) {
                sked__Resource__c skedResource = new sked__Resource__c(
                    Id = resourceId,
                    IsChangedEmploymentStatus__c = false
                );
                skedResourcesToUpdate.add(skedResource);
            }
            update skedResourcesToUpdate;
        }
    }
    
    /*********************************************************** Nested Classes ***********************************************************/
    global class resourceModel implements Comparable {
        public Id id;
        public string name;
        public decimal manualRankingPriority;
        public Date hireDate;
        public Datetime createdDate;
        public integer seniorityRank;
        public boolean isActive;
        
        public virtual Integer compareTo(Object compareToRecord) {
            resourceModel compareTo = (resourceModel)compareToRecord;
            Integer returnValue = 0;

            if (isActive && !compareTo.isActive) {
                returnValue = -1; 
            }
            else if (!isActive && compareTo.isActive) {
                returnValue = 1;
            }
            else if (hireDate < compareTo.hireDate) {
                returnValue = -1;
            }
            else if (hireDate > compareTo.hireDate) {
                returnValue = 1;
            }
            else {
                if (manualRankingPriority < compareTo.manualRankingPriority) {
                    returnValue = -1;
                }
                else if (manualRankingPriority > compareTo.manualRankingPriority) {
                    returnValue = 1;
                }
            }

            return returnValue;
        }
    }
    
}