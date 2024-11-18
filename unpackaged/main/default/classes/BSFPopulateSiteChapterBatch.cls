/**
 * @description: This batch class is used to populate Chapter Name on Site.
 * @createdby: Barnojit Sharma
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  4/18/2024                Barnojit Sharma            Update Chapter on the site when the zip code changes. (HRP-12045)
 *************************************************************************************************************************************************
**/
public class BSFPopulateSiteChapterBatch implements Database.Batchable<sObject>{
    DateTime startDate;
    DateTime endDate;

    public BSFPopulateSiteChapterBatch(Date sDate, Date edate){
        this.startDate = DateTime.newInstance(sDate.year(),sDate.month(),sDate.day());
        this.endDate = DateTime.newInstance(edate.year(),edate.month(),edate.day());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Chapter__c, sked_Zip_Code__c FROM sked__Location__c WHERE'+
                                        ' sked_Start_Date__c >= '+this.startDate.format('yyyy-MM-dd')+
                                        ' AND sked_Start_Date__c <= '+this.endDate.format('yyyy-MM-dd')+
                                        ' AND sked_Zip_Code__c != null');
    }

    public void execute(Database.BatchableContext bc, List<sked__Location__c> scope) {
        List<sked__Location__c> sitesToUpdate = new List<sked__Location__c>();
        Map<String, Id> zipCodesVsChapterIdMap = new Map<String, Id>();
        for(sked__Location__c site : scope){
            if(String.isNotBlank(site.sked_Zip_Code__c)){
                String zipCode = site.sked_Zip_Code__c.trim();
                zipCode = zipCode.length() > 5 ?  zipCode.left(5) :  zipCode;   
                zipCodesVsChapterIdMap.put(zipCode,null);
            }
        }
        if(!zipCodesVsChapterIdMap.isEmpty()){
            for(Chapter_Blood_Region_Zip_Match__c chapterZipMatch : [SELECT Id, 
                                                                            Chapter__c,
                                                                            Chapter__r.Type__c,
                                                                            Zip__c
                                                                    FROM Chapter_Blood_Region_Zip_Match__c
                                                                    WHERE Zip__c IN :zipCodesVsChapterIdMap.keySet()
                                                                    AND Chapter__c != null
                                                                    AND Chapter__r.Type__c = 'Chapter'
                                                                    ORDER BY CreatedDate DESC]){
                zipCodesVsChapterIdMap.put(chapterZipMatch.Zip__c.trim(),chapterZipMatch.Chapter__c);
            }
        }
        if(!zipCodesVsChapterIdMap.isEmpty()){
            for(sked__Location__c site : scope){
                Id oldChapter = site.Chapter__c;
                String zipCode = site.sked_Zip_Code__c.trim();
                zipCode = zipCode.length() > 5 ?  zipCode.left(5) :  zipCode; 
                if(zipCodesVsChapterIdMap.containsKey(zipCode)){
                    site.Chapter__c = zipCodesVsChapterIdMap.get(zipCode);
                }else{
                    site.Chapter__c = null;
                }
                if(oldChapter != site.Chapter__c){
                    sitesToUpdate.add(site);
                }
            }
        }
        if(!sitesToUpdate.isEmpty()){
            TriggerHandler.bypass('SiteTriggerHandler');
            skedHubBase.BypassUpdateTriggers = true;
            Database.SaveResult[] srListSite = Database.update(scope,false);
            List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srListSite,'updateSiteChapter','BSFPopulateSiteChapterBatch','execute','Error','Update Failed');
            if(!errorList.isEmpty()){
                Database.insert(errorList, false);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}
}