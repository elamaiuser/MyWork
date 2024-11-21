global with sharing class  MarketingProgramUserFilter {
   
    
    /*@InvocableMethod
    public static List<List<Marketing_Program__c>> getAccountMarketingProgramsAvailableToCurrentUser(){
        
        List<Marketing_Program__c> programList = [select id,Drive_Type__c,End_Date__c,External_Name__c,name,Recruited_By__c,Scope__c,Start_Date__c,
            (select User__c from Marketing_Program_Users__r where User__c=:UserInfo.getUserId()) 
            from Marketing_Program__c where Scope__c = 'Account' and Is_Active__c =true];
        
         System.debug('programList->'+programList);
		 //filter by current user access
         List<Marketing_Program__c> filteredProgramList = new List<Marketing_Program__c>();
         for(Marketing_Program__c pr:programList){
    		System.debug('program associated with current user->'+pr.Marketing_Program_Users__r);
			List<Marketing_Program_User__c> marketingProgramUsers = pr.Marketing_Program_Users__r;
            if(marketingProgramUsers != null && marketingProgramUsers.size()>0)
                filteredProgramList.add(pr);
         }

        List<List<Marketing_Program__c>> filteredProgramListWrapper = new List<List<Marketing_Program__c>>();
        filteredProgramListWrapper.add(filteredProgramList);
        return filteredProgramListWrapper;
    }*/
    
     @InvocableMethod
    public static List<List<Id>> getAccountMarketingProgramsAvailableToCurrentUser(){
        

            List<Id> filteredProgramList = new List<Id>();
        filteredProgramList.add('a303F000000OSXcQAO');
            filteredProgramList.add('a303F000000OSA9QAO');
         List<List<Id>> filteredProgramListWrapper = new List<List<Id>>();
        filteredProgramListWrapper.add(filteredProgramList);
        
       /*          List<List<Marketing_Program__c>> filteredProgramListWrapper = new List<List<Marketing_Program__c>>();

        * List<Marketing_Program__c> programList = [select id,Drive_Type__c,End_Date__c,External_Name__c,name,Recruited_By__c,Scope__c,Start_Date__c,
            (select User__c from Marketing_Program_Users__r where User__c=:UserInfo.getUserId()) 
            from Marketing_Program__c where Scope__c = 'Account' and Is_Active__c =true];
        
         System.debug('programList->'+programList);
		 //filter by current user access
         List<Marketing_Program__c> filteredProgramList = new List<Marketing_Program__c>();
         for(Marketing_Program__c pr:programList){
    		System.debug('program associated with current user->'+pr.Marketing_Program_Users__r);
			List<Marketing_Program_User__c> marketingProgramUsers = pr.Marketing_Program_Users__r;
            if(marketingProgramUsers != null && marketingProgramUsers.size()>0)
                filteredProgramList.add(pr);
         }

		filteredProgramListWrapper.add(programList);*/     
        return filteredProgramListWrapper;
    }
    

}