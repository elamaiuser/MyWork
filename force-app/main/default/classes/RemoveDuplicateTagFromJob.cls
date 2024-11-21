global class RemoveDuplicateTagFromJob implements Database.Batchable<sObject>,Database.Stateful{
    Date startDate;
    Date endDate;
    Integer limitOfRecord;
    Set<Id> jobIdSet = new Set<Id>();
    global RemoveDuplicateTagFromJob(Date startDate, Date endDate, Set<Id> jobIdSet, integer limitOfRecord){
        this.startDate = startDate;
    	this.endDate = endDate;
    	this.jobIdSet = jobIdSet;
    	this.limitOfRecord = limitOfRecord;
    }  
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        if(this.startDate != null && this.endDate != null){
            query = createJobQueryConditionDriveDate();
        }
        if(jobIdSet != null && !jobIdSet.isEmpty()){
            query = createJobQueryConditionJobIdSet();
        }
       return Database.getQueryLocator(query);
        
    }
    global void execute(Database.BatchableContext BC, List<sked__Job__c> jobss){
        set<Id> jobIdSets = new set<Id>();
        for(sked__Job__c job : jobss){
            jobIdSets.add(job.Id);
        }
        List<sked__Job__c> jobs = [Select id, sked_Drive__c, sked_Drive__r.sked_Account__c , sked_Drive__r.sked_Drive_Site__c , (Select Id, sked__Job__c,sked__Job__r.sked_Drive__c, sked__Tag__c, sked__Tag__r.Name, sked__Required__c, Name from sked__JobTags__r) from sked__Job__c where Id in: jobIdSets];
        Map<String,List<sked__Job_Tag__c>> jobVsJobTagList = new Map<String,List<sked__Job_Tag__c>>();
        
        For(sked__Job__c job : jobs){
            
            Map<String,List<sked__Job_Tag__c>> duplicateTagNameVsTagIds = new Map<String,List<sked__Job_Tag__c>>();
            
            for (sked__Job_Tag__c jobTag : job.sked__jobTags__r) {
                if(jobTag != null){
                    if(!duplicateTagNameVsTagIds.containsKey(jobTag.sked__Tag__r.Name)){
                        duplicateTagNameVsTagIds.put(jobTag.sked__Tag__r.Name,new List<sked__Job_Tag__c>());
                    }
                    duplicateTagNameVsTagIds.get(jobTag.sked__Tag__r.Name).add(jobTag);
                }
            }
            for (String tagName : duplicateTagNameVsTagIds.keySet()) {
                if(duplicateTagNameVsTagIds.get(tagName).size() > 1){
                    //jobVsJobTagList.put(job.Id,duplicateTagNameVsTagIds.get(tagName));
                    if(jobVsJobTagList.get(job.Id) != null){
                        jobVsJobTagList.get(job.Id).addAll(duplicateTagNameVsTagIds.get(tagName));
                    } else {
                        jobVsJobTagList.put(job.Id,duplicateTagNameVsTagIds.get(tagName));
                    }
                }
            }
        }
        
        Map<Id,sked__Job_Tag__c> tagToBeDeleted = new Map<Id,sked__Job_Tag__c>();
        for (Id jobId : jobVsJobTagList.keySet()) {
            Map<Id,sked__Job_Tag__c> uniqueTag = new Map<Id,sked__Job_Tag__c>();
            for(sked__Job_Tag__c jobTag : jobVsJobTagList.get(jobId)){
                if(uniqueTag.containsKey(jobTag.sked__Tag__c)){
                    tagToBeDeleted.put(jobTag.Id,jobTag);
                } else{
                    uniqueTag.put(jobTag.sked__Tag__c,jobTag);
                }
            }
        }
        if(!tagToBeDeleted.isEmpty()){
            system.debug('tagToBeDeleted :: '+tagToBeDeleted);
            Database.delete(tagToBeDeleted.values(),false);
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c = '', ApexClass__c = 'RemoveDuplicateTag', Method__c ='Batch Execute', Type__c='', Error_Description__c = 'error',Error_Description_Long__c = String.join(new List<Id>(tagToBeDeleted.keySet()),';'));
            Insert errorLog;
        }
    }
    global void finish(Database.BatchableContext bc){
        System.debug('duplicate job tag is deleted');
    }
    
    private static String createJobQueryConditionDriveDate () {
        string jobQuery = 'Select id, sked_Drive__c, sked_Drive__r.sked_Account__c , sked_Drive__r.sked_Drive_Site__c from sked__Job__c where sked_Drive__r.sked_drive_date__c >=: startDate AND sked_Drive__r.sked_drive_date__c <=: endDate';
    	return jobQuery;
    }
    private static String createJobQueryConditionJobIdSet () {
        string jobQuery = 'Select id, sked_Drive__c, sked_Drive__r.sked_Account__c , sked_Drive__r.sked_Drive_Site__c from sked__Job__c where Id in : jobIdSet';
    	return jobQuery;
    }
}