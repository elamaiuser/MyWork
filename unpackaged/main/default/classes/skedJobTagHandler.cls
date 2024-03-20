public class skedJobTagHandler extends skedTriggerHub {

    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateJobRoleCertifications(this.context.newRecords);
        }
    }

    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateJobRoleCertifications(this.context.oldMap.values());
        }
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void updateJobRoleCertifications(List<sked__Job_Tag__c> newRecords) {
        Set<Id> jobIds = new Set<Id>();
        for (sked__Job_Tag__c newRecord : newRecords) {
            jobIds.add(newRecord.sked__Job__c);
        }
        updateJobRoleCertifications(jobIds);
    }

    /*********************************************************** Public Methods ***********************************************************/
    public static void updateJobRoleCertifications(Set<Id> jobIds) {
        List<sked__Job__c> skedJobs = [SELECT Id, sked_Role_Certifications__c,
                                       (SELECT Id, sked__Tag__r.Name, sked__Tag__r.sked__Type__c
                                        FROM sked__JobTags__r
                                        WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                                        OR sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_CERTIFICATION
                                        ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST, sked__Tag__r.Name ASC)
                                       FROM sked__Job__c
                                       WHERE Id IN :jobIds
                                       FOR UPDATE];
        List<sked__Job__c> skedJobsToUpdate = new List<sked__Job__c>();
        for (sked__Job__c skedJob : skedJobs) {
            if (skedJob.sked__JobTags__r != NULL && !skedJob.sked__JobTags__r.isEmpty()) {
                List<string> certifications = new List<string>();
                List<string> roles = new List<string>();
                for (sked__Job_Tag__c skedJobTag : skedJob.sked__JobTags__r) {
                    if (skedJobTag.sked__Tag__r.sked__Type__c == skedConstants.TAG_TYPE_CERTIFICATION) {
                    	certifications.add(skedJobTag.sked__Tag__r.Name);
                    }
                    else if (skedJobTag.sked__Tag__r.sked__Type__c == skedConstants.TAG_TYPE_ROLE) {
                    	roles.add(skedJobTag.sked__Tag__r.Name);
                    }
                }
                Set<string> tagNames = new Set<string>();
                tagNames.addAll(roles);
                tagNames.addAll(certifications);
                skedJob.sked_Role_Certifications__c = string.join(new List<String>(tagNames), ', ');
                skedJobsToUpdate.add(skedJob);
            }
        }
        if (!skedJobsToUpdate.isEmpty()) {
            update skedJobsToUpdate;
        }
    }

}