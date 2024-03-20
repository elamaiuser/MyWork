trigger SiteTrigger on sked__Location__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
	new SiteTriggerHandler().run();
    
    /*
    if(Trigger.isBefore && Trigger.isUpdate && !checkRecursive.firstcall)
    {
        checkRecursive.firstcall = true;
        List<sked__Location__c> newSites = Trigger.new;
        map<id,sked__Location__c> oldSiteMap = Trigger.oldmap;
        map<id,sked__Location__c> newSiteMap = Trigger.newMap;
        for(sked__Location__c site : newSites){
            if( oldSiteMap.get(site.Id).sked_National_Name__c == null && site.sked_National_Name__c != null){
                site.Initial_Reviewer__c = UserInfo.getUserId();
                site.National_Name_Status__c = System.Label.Initial_Review_Pending;
            }else if(site.National_Name_Status__c == System.Label.Second_Review_Pending && site.sked_National_Name__c != null && oldSiteMap.get(site.Id).sked_National_Name__c != null && site.sked_National_Name__c != oldSiteMap.get(site.Id).sked_National_Name__c){
                site.Initial_Reviewer__c = UserInfo.getUserId();
                site.National_Name_Status__c = System.Label.Initial_Review_Pending;
                site.National_Name_Initial_Review_Date__c = null;
            }else if(site.National_Name_Status__c == System.Label.Review_Completed && site.sked_National_Name__c != oldSiteMap.get(site.Id).sked_National_Name__c){
                site.adderror(System.Label.NationalNameCannotBeUpdatedAfterReview);  
            }
        }
    }*/
}