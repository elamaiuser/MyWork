public with sharing class UpdateNationalNameStatusController {
    @AuraEnabled
    public static string updateNationNameStatus(String recordId){
        String message = '';
        list<Account> accountList = [Select Id,National_Name_Initial_Review_Date__c,National_Name_Second_Review_Date__c, National_Name_Status__c, Initial_Reviewer__c, LastModifiedById from Account where id =: recordId ];
        list<sked__Location__c> siteList = [Select Id,National_Name_Initial_Review_Date__c,National_Name_Second_Review_Date__c, National_Name_Status__c, Initial_Reviewer__c, LastModifiedById from sked__Location__c where id =: recordId ];
        System.debug('accountList '+accountList +' recordId '+recordId);
        //Update status for Account
        if(!accountList.isEmpty())
        {
            Account account = accountList[0];
            if(UserInfo.getUserId() == account.Initial_Reviewer__c && account.National_Name_Status__c == System.Label.Initial_Review_Pending){
                account.National_Name_Status__c = System.Label.Second_Review_Pending;
                account.National_Name_Initial_Review_Date__c = System.today();
                message = 'Success:- '+System.Label.Success_Message;
                
                //update account;
                
                
            }else if(UserInfo.getUserId() == account.Initial_Reviewer__c && account.National_Name_Status__c == System.Label.Second_Review_Pending){
                message = System.Label.NationalNameSecondReviewNotDoneByInitialReviewer;
            }else if(UserInfo.getUserId() != account.Initial_Reviewer__c && account.National_Name_Status__c == System.Label.Second_Review_Pending){
                account.National_Name_Status__c = System.Label.Review_Completed;
                account.National_Name_Second_Review_Date__c = System.today();
                account.Secondary_Reviewer__c = UserInfo.getUserId();
                
                
                
                message = 'Success: '+System.Label.Success_Message;
            }else if(UserInfo.getUserId() != account.Initial_Reviewer__c && account.National_Name_Status__c == System.Label.Initial_Review_Pending){
                message = System.Label.NationalNameLoggedInUserNotInitialReviewer;
            }
        }
        
        //Update status for Site
        else if (!siteList.isEmpty())
        {
             sked__Location__c site = siteList[0];
            if(UserInfo.getUserId() == site.Initial_Reviewer__c && site.National_Name_Status__c == System.Label.Initial_Review_Pending){
                site.National_Name_Status__c = System.Label.Second_Review_Pending;
                site.National_Name_Initial_Review_Date__c = System.today();
                message = 'Success:- '+System.Label.Success_Message;
                system.debug('Site44'+site);
                //update site;
                
                
            }else if(UserInfo.getUserId() == site.Initial_Reviewer__c && site.National_Name_Status__c == System.Label.Second_Review_Pending){
                message = System.Label.NationalNameSecondReviewNotDoneByInitialReviewer;
            }else if(UserInfo.getUserId() != site.Initial_Reviewer__c && site.National_Name_Status__c == System.Label.Second_Review_Pending){
                site.National_Name_Status__c = System.Label.Review_Completed;
                site.National_Name_Second_Review_Date__c = System.today();
                site.Secondary_Reviewer__c = UserInfo.getUserId();
                system.debug('Site54'+site);
                
                
                
                message = 'Success: '+System.Label.Success_Message;
            }else if(UserInfo.getUserId() != site.Initial_Reviewer__c && site.National_Name_Status__c == System.Label.Initial_Review_Pending){
                message = System.Label.NationalNameLoggedInUserNotInitialReviewer;
            }   
        }
        try {
            System.debug('accountList '+accountList);
            if(!accountList.isEmpty())
            {
                update accountList;
            }
            else{update siteList;}
            
        }
        
        
        catch (Exception e) {
            system.debug(e);
            message = 'Exception:- '+e.getMessage()+' line of '+e.getLinenumber();
            throw new AuraHandledException(e.getMessage());
            
        }
        return message;
    }
}