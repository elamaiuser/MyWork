/*
* Description: This class is used to create Drives on Calender record depending on the site operation Types 
* */

/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
  **************************************************************************
 * 06/12/2023				  Priti Jana			 Logic for HRP-9901
 * 10/5/2023                  Priti Jana             Logic for HRP-11027
 * 05/02/2024                 Priti Jana             Logic for HRP-12480
 ***************************************************************************
*/

public class DriveGeneratorService {
    
    /* Description: Call this method from batch or trigger */
    
    public static void generateDrivesOnOppInsert(List<Opportunity> oppList){
        set<Id> mobileOppList = new set<Id>();
        list<Opportunity> fixSiteOppList = new list<opportunity>();
        
    //========= By KT ===============
        set<Id> accountIdSet = new set<Id>();

        Set<Id> siteIdSet = new Set<Id>(); // HRP - 9901 - to store drive sites

        for(Opportunity opp : oppList){
            accountIdSet.add(opp.AccountId);
            siteIdSet.add(opp.Drive_Site__c); // HRP - 9901 - populating drive site set
        }

        // HRP - 9901 ----> starts Here (Fetching Related Sites)
        
        FetchRelatedDriveData.DMLSchedulingBounds schedulingBounds = FetchRelatedDriveData.reduceSchedulingBoundsFromOpportunities(oppList);
        List<Account> accounts = FetchRelatedDriveData.fetchAccounts(accountIdSet, schedulingBounds); //HRP-12480
        List<sked__Location__c> sites = FetchRelatedDriveData.fetchSites(siteIdSet , schedulingBounds);

        if(sites.isEmpty() || sites.size() < 1)
        {
            String customMessage = 'Site Not Found !';
            DriveGenerationErrorHandler.notifyUsersUponFailureAndLogErrors(NULL, oppList[0].Id, customMessage, Constants.DATA_ISSSUE, 'DriveGeneratorService', 'generateDrivesOnOppInsert');
        }
        else{

        Map<Id, Account> idVsAccount = new Map<Id, Account>(accounts);

        Map<Id, sked__Location__c> idVsSite = new Map<Id,sked__Location__c>(sites); // HRP - 9901 - map of site id with site

        for(opportunity opp:oppList)
        {
            if(opp.Type_of_Drive__c == Constants.FIX_SITE_OPP && (idVsSite.get(opp.Drive_Site__c).Operation_Type__c == Constants.NON_INTEGRATED_APH_OPERATION_TYPE || idVsSite.get(opp.Drive_Site__c).Operation_Type__c == Constants.INTEGRATED_OPERATION_TYPE || String.isBlank(idVsSite.get(opp.Drive_Site__c).Operation_Type__c))){
                fixSiteOppList.add(opp);
            }
            else if((opp.Type_of_Drive__c == Constants.FIX_SITE_OPP && idVsSite.get(opp.Drive_Site__c).Operation_Type__c == Constants.NON_INTEGRATED_WB_OPERATION_TYPE) || opp.Type_of_Drive__c == Constants.MOBILE_SITE_OPP){
                mobileOppList.add(opp.Id);
            }
        }
        // HRP - 9901 ----> ends Here
        
        if(!fixSiteOppList.isEmpty() && fixSiteOppList != NULL)
            CreateSkedDrive.createDrives(fixSiteOppList);
        if(!mobileOppList.isEmpty() && mobileOppList != NULL){
            MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
            config.oppIds = mobileOppList;
            GenerateMobileDrive.generateDrives(config);
        }
    }
}    
}