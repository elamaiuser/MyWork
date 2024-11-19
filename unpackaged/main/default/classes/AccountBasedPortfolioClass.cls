/* 
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 4/18/2023                  Ankit Kundu            Logic for HRP-9654 [Newly add Account Based Reason Field, createAccountPortfolioData]
* 8/9/2023                   Balaji N               Logic for HRP-8897 [commented code for account team Handling and added method call for accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates]
* 11/9/2023                  Ankit Kundu            Logic for HRP-10545[portfolio list is displayed in alphabetical order]
* 11/9/2023					 Balaji N				Logic for HRP-11290[MethodName:checkAndCreateAccPortfolioForSupervisor,createAccountTeamData;Date Check for Supervisor]
* 01/04/2024                 Balaji N			    Logic for HRP-10569(Method Name:createAccountTeamData;parameter changes on accTeamDateSyncOnAccPortUpdates method call)
* 01/16/2024                 Balaji N			    Logic for HRP-11401[MethodName:createAccountPortfolioData(Changes regarding exception added with same date as territory)
* 02/14/2024				 Balaji N				Logic for HRP-11138(Method :createAccountPortfolioData, isBackEndDelete)
* 08/05/2024				 Balaji N				Logic for HRP-12485(Method :createAccountPortfolioData removed dependency on Account_AM_Portfolio_Type__c)
**
*****************************************************************************
*/



public with sharing class AccountBasedPortfolioClass {
    /*public AccountBasedPortfolioClass(){
BSF_Constants.skipAccountPortfolioAssignmentTrigger = true;
}*/
    
    /*
only profile mentioned in custom label Super_Admin_User , are allowed to assign portfolio
*/
    @AuraEnabled
    public static Boolean isAllowedForNonGeographicData(){
        Boolean isAllowed = false;
        String current_user_profile = System.label.Super_Admin_User ;
        List<Profile> userprofileobj = new List<Profile>();
        userprofileobj = [select Name from Profile where Id=: UserInfo.getProfileId()  ];
        if( !userprofileobj.isEmpty() ){
            if( current_user_profile.toLowerCase().contains( userprofileobj[0].Name.toLowerCase() ) ){
                isAllowed = true;
            }
        }
        return isAllowed;
    }
    
    /*
other than System admin, are allowed to create Account Team Members
*/
    /*@AuraEnabled
public static Boolean isAllowedToCreateTeamMembers(String concatenatedAccIds){
boolean isAllowed = true;
List<String> accIdList = concatenatedAccIds.split(';');
List<Profile> userprofileobj = new List<Profile>();
userprofileobj = [select Name from Profile where Id=: UserInfo.getProfileId() ];
System.debug('User Profile: '+userprofileobj[0].Name);
if(!((userprofileobj[0].Name.equalsIgnoreCase('System Administrator')) || 
(userprofileobj[0].Name.equalsIgnoreCase('Recruitment Admin')))){
List<Account> accList = [SELECT Id,Name,District_Manager__c FROM Account WHERE Id IN:accIdList  ];

for(Account acc:accList){
if(acc.District_Manager__c != UserInfo.getUserId()){
isAllowed = false;
}
}  
}
return  isAllowed;
}*/
    
    @AuraEnabled
    public static string getBaseURLExternalform(){
        try {
            System.debug( 'ext form is ' + System.URL.getSalesforceBaseURL().toExternalForm() );
            System.debug( 'non ext form is ' + System.URL.getSalesforceBaseURL() );
            String url =  System.URL.getSalesforceBaseURL().toExternalForm() ;
            //String[] urlarray = url.split('--');
            //url = urlarray[0] + '--' + urlarray[1] ; //url.replaceAll('my.salesforce.com', '');
            System.debug( 'url external form is ' + url );
            return url;  
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Account getAccountInstance(Id accid){
        List<Account> acclist = new List<Account>();
        acclist = [select Id, Name from Account where Id=: accid ];
        return acclist[0];
    }
    
    @AuraEnabled
    public static List<AccountInstancesWrapper> getAccountInstances(List<Id> accids){
        List<Account> acclist = new List<Account>();
        acclist = [select Id, Name from Account where Id in: accids  ];
        
        List<AccountInstancesWrapper> accinstancelist = new List<AccountInstancesWrapper>();
        AccountInstancesWrapper acw ;
        
        String url = getBaseURLExternalform();
        
        for( Account a : acclist){
            acw = new AccountInstancesWrapper();
            acw.account_id = a.Id;
            acw.account_name = a.Name;
            acw.domainurl = url.substringBefore('--c')+'.sandbox';
            
            accinstancelist.add(acw);
        }
        return accinstancelist;
    }    
    
    /*
@AuraEnabled
public static List<BSFPortfolioWrapper> getNonGeoPortfolioData(String selectedPortfolioType){

List<BSFPortfolioWrapper> bsplist = new List<BSFPortfolioWrapper>();
List<BSF_Portfolio__c> portfoliolist = new List<BSF_Portfolio__c>();
String taxonomyType = '';
try{

if(selectedPortfolioType.equals(BSF_Constants.ACCOUNT_MANAGER)){
taxonomyType = BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE ;
portfoliolist = [select Id, Portfolio_Name__c, Portfolio_Type__c,
Taxonomy_Type__c,
Parent_Portfolio__c,
Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Portfolio_Name__c,
Parent_Portfolio__r.Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c,
Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c
from BSF_Portfolio__c 
where Account_Based_Portfolio__c = true and 
Portfolio_Type__c =:BSF_Constants.ACCOUNT_MANAGER AND 
Taxonomy_Type__c =:taxonomyType ];
}else{

if(selectedPortfolioType.equals(BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER)){
taxonomyType = BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE;    
}else if(selectedPortfolioType.equals(BSF_Constants.NATIONAL_ACCOUNT_MANAGER)){
taxonomyType = BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE;   
}else if(selectedPortfolioType.equals(BSF_Constants.Booking_Support)){
taxonomyType = BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE;   
}else if(selectedPortfolioType.equals(BSF_Constants.ACCOUNT_SPECIALIST)){
taxonomyType = BSF_Constants.ACCOUNT_SPECIALIST;   
}else if(selectedPortfolioType.equals(BSF_Constants.RELATIONSHIP_MANAGER)){
taxonomyType = BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE;   
}else if(selectedPortfolioType.equals(BSF_Constants.FIXED_SITE)){
taxonomyType = BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE;   
}


portfoliolist = [select Id, Portfolio_Name__c, Portfolio_Type__c,
Taxonomy_Type__c,
Parent_Portfolio__c,
Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Portfolio_Name__c,
Parent_Portfolio__r.Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c,
Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c
from BSF_Portfolio__c 
where Account_Based_Portfolio__c = true and 
Portfolio_Type__c =:selectedPortfolioType AND 
Taxonomy_Type__c = :taxonomyType  ];   
}

if( !portfoliolist.isEmpty() ){
BSFPortfolioWrapper bsp;
for( BSF_Portfolio__c bfp : portfoliolist){
bsp = new BSFPortfolioWrapper();
bsp.portfolioid = bfp.Id ;
bsp.Portfolio_Name = bfp.Portfolio_Name__c ;
bsp.Portfolio_Type = bfp.Portfolio_Type__c;
bsplist.add(bsp);
}
}
}catch (Exception e) {
throw new AuraHandledException(e.getMessage());
}
return bsplist;
} */
    
    @AuraEnabled
    public static boolean startDatePastAllowed()
    {
        List<String> allowedProfiles = System.Label.AccPortfolioAssignmentException.split(',');
        boolean startDatePast= false;
        List<Profile> userprofileobj = new List<Profile>();
        userprofileobj = [select Name from Profile where Id=: UserInfo.getProfileId()  ];
        for(String str :allowedProfiles)
        {
            if( !userprofileobj.isEmpty() ){
                if( str.toLowerCase().contains( userprofileobj[0].Name.toLowerCase() ) ){
                    startDatePast = true;
                }
            }
        }
        
        return startDatePast;
    }
    
    @AuraEnabled
    public static List<BSFPortfolioWrapper> getNonGeoPortfolioData(String selectedPortfolioType,List<Id> AccountId){
        
        
        
        List<BSFPortfolioWrapper> bsplist = new List<BSFPortfolioWrapper>();
        List<BSF_Portfolio__c> portfoliolist = new List<BSF_Portfolio__c>();
        Set<id> dmBsfPortIdList = new Set<id>();
        String taxonomyType = '';
        
        Account acc =[Select id,District_Manager__c from Account where id =:AccountId[0]];
        
        
        
        if(acc.District_Manager__c != null && acc.District_Manager__c == userinfo.getUserId())
        {
            List<Portfolio_Assignment__c> dmBSFPortfolioList = [Select BSF_Portfolio__c from Portfolio_Assignment__c where User__c=:acc.District_Manager__c and BSF_Portfolio__r.Portfolio_Type__c=:BSF_Constants.DISTRICT_MANAGER];
            for(Portfolio_Assignment__c p:dmBSFPortfolioList)
            {
                dmBsfPortIdList.add(P.BSF_Portfolio__c);
            }
        }
        
        try{
            if(selectedPortfolioType.equals(BSF_Constants.ACCOUNT_MANAGER)){
                taxonomyType = BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE ;
                
                if(!dmBsfPortIdList.isEmpty())
                {
                    
                    portfoliolist = getPortfolio(' AND (Parent_Portfolio__r.Id IN :DmBsfPortIdList or Parent_Portfolio__r.Parent_Portfolio__r.Id IN:DmBsfPortIdList) '
                                                 ,dmBsfPortIdList,BSF_Constants.ACCOUNT_MANAGER,taxonomyType);
                }
                if(dmBsfPortIdList.isEmpty() || portfoliolist.isEmpty())
                {
                    portfoliolist= getPortfolio(' ',null,BSF_Constants.ACCOUNT_MANAGER,taxonomyType);
                    system.debug('portfoliolist'+portfoliolist);
                }
            }else{
                
                if(selectedPortfolioType.equals(BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER)){
                    taxonomyType = BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE;    
                }else if(selectedPortfolioType.equals(BSF_Constants.NATIONAL_ACCOUNT_MANAGER)){
                    taxonomyType = BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE;   
                }else if(selectedPortfolioType.equals(BSF_Constants.Booking_Support)){
                    taxonomyType = BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE;   
                }else if(selectedPortfolioType.equals(BSF_Constants.ACCOUNT_SPECIALIST)){
                    taxonomyType = BSF_Constants.ACCOUNT_SPECIALIST;   
                }else if(selectedPortfolioType.equals(BSF_Constants.RELATIONSHIP_MANAGER)){
                    taxonomyType = BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE;   
                }else if(selectedPortfolioType.equals(BSF_Constants.FIXED_SITE)){
                    taxonomyType = BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE;
                    if(!dmBsfPortIdList.isEmpty())
                    {
                        
                        portfoliolist = getPortfolio(' AND (Parent_Portfolio__r.Id IN :DmBsfPortIdList or Parent_Portfolio__r.Parent_Portfolio__r.Id IN:DmBsfPortIdList) '
                                                     ,dmBsfPortIdList,selectedPortfolioType,taxonomyType);
                    }   
                }
                
                
                if(portfoliolist.isEmpty())
                    portfoliolist = getPortfolio(' ',null,selectedPortfolioType,taxonomyType);
            }
            //HRP-10545->portfolio list is displayed in alphabetical order   
            //Start->
            if( !portfoliolist.isEmpty() ){
                for( BSF_Portfolio__c bsfport : portfoliolist ){                              
                    BSFPortfolioWrapper  bsp = new BSFPortfolioWrapper();
                    bsp.portfolioid = bsfport.Id;
                    bsp.Portfolio_Name = bsfport.Portfolio_Name__c ;
                    bsp.Start_Date = getFormattedDate(bsfport.Start_Date__c);
                    bsp.End_Date = getFormattedDate(bsfport.End_Date__c);
                    bsplist.add(bsp);                
                }
                return bsplist;
            }//<-End
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    /*public static List<BSFPortfolioWrapper> checkParentPortfolioRegionLevel(List<BSF_Portfolio__c> portfoliolist ){            
List<BSFPortfolioWrapper> portfoliosnames = new List<BSFPortfolioWrapper>();
List<BSF_Portfolio__c> validdataportfoliolist = new List<BSF_Portfolio__c>();
Map<String, List<BSFPortfolioWrapper>> portfolioNameByRegionMap = new Map<String, List<BSFPortfolioWrapper>>();
List<BSFPortfolioWrapper> nullParentPortfolioList = new List<BSFPortfolioWrapper>();
BSFPortfolioWrapper bsp ;
if( !portfoliolist.isEmpty() ){
for( BSF_Portfolio__c bsfport : portfoliolist ){
//HRP-7113 added by Balaji N
if( bsfport.Parent_Portfolio__c ==null)
{
bsp = new BSFPortfolioWrapper();
bsp.portfolioid = bsfport.Id;
bsp.Portfolio_Name = bsfport.Portfolio_Name__c ;
bsp.Start_Date = getFormattedDate(bsfport.Start_Date__c);
bsp.End_Date = getFormattedDate(bsfport.End_Date__c);
nullParentPortfolioList.add(bsp);

}//
else if( bsfport.Parent_Portfolio__c !=null ){ // FIND REGION AT FIRST LEVEL UP
if( bsfport.Parent_Portfolio__r.Portfolio_Type__c == BSF_Constants.REGION_PORTFOLIO_TYPE ){
// populate map here
if( !portfolioNameByRegionMap.containsKey(bsfport.Parent_Portfolio__r.Portfolio_Name__c) ){
portfolioNameByRegionMap.put( bsfport.Parent_Portfolio__r.Portfolio_Name__c, new List<BSFPortfolioWrapper>() );
}
bsp = new BSFPortfolioWrapper();
bsp.portfolioid = bsfport.Id;
bsp.Portfolio_Name = bsfport.Portfolio_Name__c ;
bsp.Start_Date = getFormattedDate(bsfport.Start_Date__c);
bsp.End_Date = getFormattedDate(bsfport.End_Date__c);
portfolioNameByRegionMap.get(bsfport.Parent_Portfolio__r.Portfolio_Name__c).add( bsp );

}else if(   bsfport.Parent_Portfolio__r.Parent_Portfolio__c != null ){ // FIND REGION AT SECOND LEVEL UP                                
if( bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == BSF_Constants.REGION_PORTFOLIO_TYPE ){
// populate map here
if( !portfolioNameByRegionMap.containsKey(bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c) ){
portfolioNameByRegionMap.put( bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c, new List<BSFPortfolioWrapper>() );
}
bsp = new BSFPortfolioWrapper();
bsp.portfolioid = bsfport.Id;
bsp.Portfolio_Name = bsfport.Portfolio_Name__c ;
bsp.Start_Date = getFormattedDate(bsfport.Start_Date__c);
bsp.End_Date = getFormattedDate(bsfport.End_Date__c);
portfolioNameByRegionMap.get(bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c).add( bsp );
}else if(   bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c != null ){ // FIND REGION AT THIRD LEVEL UP

// populate map here
if( bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == BSF_Constants.REGION_PORTFOLIO_TYPE ){
if( !portfolioNameByRegionMap.containsKey( bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c ) ){
portfolioNameByRegionMap.put( bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c, new List<BSFPortfolioWrapper>() );
}
bsp = new BSFPortfolioWrapper();
bsp.portfolioid = bsfport.Id;
bsp.Portfolio_Name = bsfport.Portfolio_Name__c ;
bsp.Start_Date = getFormattedDate(bsfport.Start_Date__c);
bsp.End_Date = getFormattedDate(bsfport.End_Date__c);
portfolioNameByRegionMap.get(  bsfport.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c ).add( bsp );
}

}
}
}
} // end of FOR LOOP

List<String> portfolioKeys = new List<String>();
List<String> portfolioKeyssorted = new List<String>();
for( String s1 : portfolioNameByRegionMap.keySet() ){
portfolioKeys.add( s1 );
}
portfolioKeys.sort() ;
portfolioKeyssorted = portfolioKeys ;

List<BSFPortfolioWrapper> portfoliosertedList;
for( String portkey : portfolioKeyssorted ){
portfoliosertedList = new List<BSFPortfolioWrapper>();
portfoliosertedList = portfolioNameByRegionMap.get( portkey ) ;
//portfoliosertedList.sort() ;

portfoliosnames.addAll( portfoliosertedList );
}
//HRP-7113 added by Balaji N
if(!nullParentPortfolioList.isEmpty())
{
portfoliosnames.addAll(nullParentPortfolioList);
}//
}
return portfoliosnames;
}*/
    // @AuraEnabled
    // public static AccountPortfolioWrapper getAccountPortfolioData( Id accountid ){
    //     AccountPortfolioWrapper apwrapper = new AccountPortfolioWrapper();
    //     String accid = String.escapeSingleQuotes(accountid);
    //     List<Account_Portfolio_Assignment__c> accportfolio = new List<Account_Portfolio_Assignment__c>();
    
    //     try {
    //         accportfolio = [select Id, Account__c, BSF_Portfolio__c, Start_Date__c, End_Date__c 
    //                         from Account_Portfolio_Assignment__c
    //                         where Account__c =:accid];
    
    //         if( !accportfolio.isEmpty() ){
    //             for( Account_Portfolio_Assignment__c ap : accportfolio ){
    //                 apwrapper = new AccountPortfolioWrapper();
    //                 apwrapper.accountRecid = ap.Account__c;
    //                 apwrapper.portfolioRecId = ap.BSF_Portfolio__c;
    //                 apwrapper.Start_Date = String.valueOf(ap.Start_Date__c);
    //                 apwrapper.End_Date = String.valueOf(ap.End_Date__c);
    //             }
    //         }
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    
    //     return apwrapper;
    // }
    
    /*
Creating Accoiut Portfolio data
*/
    @AuraEnabled
    public static void createAccountPortfolioData( String accportfoliodata ){
        //BSF_Constants.skipAccountPortfolioAssignmentTrigger = true;
        System.debug('skipAccountPortfolioAssignmentTrigger: '+BSF_Constants.skipAccountPortfolioAssignmentTrigger);
        Map<Id,Account> accountIdMap = new Map<Id,Account>();
        Map<Id,AccountPortfolioWrapper> accportfoliowrpmap = new Map<Id,AccountPortfolioWrapper>();
        Map<Id,Boolean> accountUpdateRequiremap = new Map<Id,Boolean>();
        Set<Id> portfolio_ids = new Set<Id>();
        Set<Id> acc_ids = new Set<Id>();
        List<Id> acc_idsList = new List<Id>();
        List<Account_Portfolio_Assignment__c> apassignList = new List<Account_Portfolio_Assignment__c>();        
        List<Account> acclist = new List<Account>();
        List<Account> accupdatelist = new List<Account>();
        Account_Portfolio_Assignment__c apassign = new Account_Portfolio_Assignment__c();
        Date st_date;
        Date en_Date;
        String portfolioType = '';
        List<AccountPortfolioWrapper> apwrp= (List<AccountPortfolioWrapper>)JSON.deserialize(accportfoliodata, List<AccountPortfolioWrapper>.class);
        string selectedAccBasedReason=null; //HRP-9654
        for(AccountPortfolioWrapper apw : apwrp ){
            st_date = Date.valueOf(apw.Start_Date);
            en_Date = date.valueof(apw.end_date);
            if(apw.selectedPortfolioType.equals(BSF_Constants.ACCOUNT_PORTFOLIO)){
                portfolioType = BSF_Constants.ACCOUNT_MANAGER;
            }else{
                portfolioType = apw.selectedPortfolioType;
            }
            acc_ids.add( apw.accountRecid);
            acc_idsList.add( apw.accountRecid );
            portfolio_ids.add( apw.portfolioRecId );
            accportfoliowrpmap.put( apw.accountRecid, apw );
            //HRP-9654 [Start->>]
            if(selectedAccBasedReason== null)
            {
                integer i = 0;
                for(string a:apw.selectedAccountbasedreason)
                {
                    
                    i++;
                    if(selectedAccBasedReason==null)
                    {
                        selectedAccBasedReason = a;
                    }
                    else if(selectedAccBasedReason!=null)
                    {
                        selectedAccBasedReason = selectedAccBasedReason+a;
                    }
                    
                    if(i<apw.selectedAccountbasedreason.size())
                    {
                        selectedAccBasedReason+=';';
                    }
                    
                }
            }
            //HRP-9654[<<-End]
        }
        
        
        
        // Query on BSF Portfolio Object
        List<BSF_Portfolio__c> bsfportfolioobj = new List<BSF_Portfolio__c>();
        bsfportfolioobj = [ select Id, Portfolio_Type__c, Parent_Portfolio__c, Portfolio_Name__c,Portfolio_Code__c,Start_Date__c,End_Date__c from BSF_Portfolio__c where Id in:portfolio_ids  ];
        
        // Query On Account for Update
        acclist = [select Id, Name from Account where Id in:acc_ids  ];        
        /*HRP-12485
         *for( Account ac : acclist ){
            if( !ac.Account_AM_Portfolio_Type__c && portfolioType.equals(BSF_Constants.ACCOUNT_MANAGER) 
               && date.valueOf(accportfoliowrpmap.get(ac.Id).Start_Date) == system.today()){
                   ac.Account_AM_Portfolio_Type__c = true;
                   accupdatelist.add(ac);
               }    
            accountIdMap.put(ac.Id, ac );        
        }
        HRP-12485*/
        try{
            //System.debug( 'Account update list is ' + accupdatelist );
            // Update Account's <AM Portfolio type> field if not checked
            /*HRP-12485
            if( !accupdatelist.isEmpty() ){
                //Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();if( ds.isUpdateable() ){}
                
                update accupdatelist;
                
                
            }
            //System.debug( 'Account update is done');
            HRP-12485*/
            // check over the existing Account Portfolio record, whether end date is greater than incoming record start date  
            if(portfolioType.equals(BSF_Constants.ACCOUNT_MANAGER)){
                List<Account_Portfolio_Assignment__c> aplist = new List<Account_Portfolio_Assignment__c>();
                aplist = [ select Id, Start_Date__c, End_Date__c, Account__c from  Account_Portfolio_Assignment__c 
                          where Account__c in: acc_ids AND BSF_Portfolio__r.Portfolio_Type__c =:BSF_Constants.ACCOUNT_MANAGER  ];
                List<Account_Portfolio_Assignment__c> aplistToUpdate = new List<Account_Portfolio_Assignment__c>();
                List<Account_Portfolio_Assignment__c> aplistTodelete = new List<Account_Portfolio_Assignment__c>();//HRP-11401
                if( !aplist.isEmpty() ){
                    date maxDate = date.newInstance(4000, 12, 31);//HRP-11401
                    for( Account_Portfolio_Assignment__c aps : aplist )
                    {   
                        //HRP-11401
                        if(st_date == aps.Start_Date__c)
                        {
                            aplistTodelete.add(aps);
                        }
                        //HRP-11401
                        else
                        {
                            if((aps.End_Date__c >=st_date && aps.Start_Date__c <st_date ) )
                            {
                                aps.End_Date__c = Date.valueOf(accportfoliowrpmap.get(aps.Account__c).Start_Date).AddDays(-1);
                                aplistToUpdate.add(aps);
                            }
                            if((aps.End_Date__c >=en_date && aps.Start_Date__c <=en_date) && st_date< aps.Start_Date__c)
                            {
                                if( Date.valueOf(accportfoliowrpmap.get(aps.Account__c).end_date)!=maxDate)//HRP-11401
                                {
                                    aps.Start_Date__c = Date.valueOf(accportfoliowrpmap.get(aps.Account__c).end_date).AddDays(1);
                                    aplistToUpdate.add(aps);
                                }
                                //HRP-11401
                                else
                                {
                                    aplistTodelete.add(aps);
                                }
                                //HRP-11401
                            }
                        }
                        
                        
                        
                        
                    }
                    //Schema.DescribeSObjectResult ds = Account_Portfolio_Assignment__c.sObjectType.getDescribe();if( ds.isUpdateable() ){}
                    system.debug('aplist'+aplist);
                    triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
                    if(!aplist.isEmpty())
                        update aplist;
                    //HRP-11401
                    if(!aplistTodelete.isEmpty())
                    {
                        BSF_Constants.isBackEndDelete=true;//HRP-11138
                        delete aplistTodelete;
                        BSF_Constants.isBackEndDelete=false;//HRP-11138
                    }
                    //HRP-11401
                    triggerHandler.Clearbypass('AccountPortfolioAssignmentTriggerHandler');
                    
                }
            }         
            //checkAndCreateAccPortfolioForSupervisor(bsfportfolioobj[0],acc_ids,Date.valueOf(apwrp[0].Start_Date), Date.valueOf(apwrp[0].End_Date));
            
            // Insert new Account Portfolio data
            Map<Id,Account_Portfolio_Assignment__c> acctPortMap = new Map<Id,Account_Portfolio_Assignment__c>();
            for(AccountPortfolioWrapper apw : apwrp ){
                apassign = new Account_Portfolio_Assignment__c();
                //apassign.Name = accountIdMap.get(apw.accountRecid).Name + '-' + bsfportfolioobj[0].Portfolio_Name__c ;
                apassign.Account__c =  apw.accountRecid;
                apassign.BSF_Portfolio__c = apw.portfolioRecId;
                apassign.Account_Based_Reason__c = selectedAccBasedReason;//HRP-9654
                apassign.Start_Date__c = Date.valueOf(apw.Start_Date);
                apassign.End_Date__c = Date.valueOf(apw.End_Date);
                apassignList.add(apassign);
                acctPortMap.put(apw.accountRecid,apassign);                   
            }
            
            if( !apassignList.isEmpty() ){
                try{
                    //Schema.DescribeSObjectResult ds = Account_Portfolio_Assignment__c.sObjectType.getDescribe();if( ds.isCreateable() ){}
                    
                    
                    insert apassignList;
                    
                    
                }
                catch(DMLException e){
                    System.debug('DMLException has occured: '+e.getMessage());
                }
                
            }
            
            System.debug('Portfolio Type: '+apwrp[0].selectedPortfolioType);
            createAccountTeamData( acc_idsList, acctPortMap,apwrp[0].portfolioRecId, apwrp[0].selectedPortfolioType, Date.valueOf(apwrp[0].Start_Date), Date.valueOf(apwrp[0].End_Date) , bsfportfolioobj[0] );
            
        } catch (Exception e) {
            System.debug('Exception is: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }        
    }
    
    /*public static void checkAndCreateAccPortfolioForSupervisor(BSF_Portfolio__c amPortfolio,Set<Id> accIdList,Date startdate, Date enddate){
        List<Account_Portfolio_Assignment__c> accPortfoliosNeedEndDateUpdateList = new List<Account_Portfolio_Assignment__c>();
        List<Account_Portfolio_Assignment__c> accPortfoliosNeedToCreate = new List<Account_Portfolio_Assignment__c>();
        List<Account_Portfolio_Assignment__c> accountPortfolioList=[SELECT Id,
                                                                    Account__c,Start_Date__c,End_Date__c,
                                                                    BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Code__c,
                                                                    BSF_Portfolio__r.Taxonomy_Type__c
                                                                    FROM Account_Portfolio_Assignment__c 
                                                                    WHERE
                                                                    Account__c IN:accIdList ];
        Set<Id> accIdSet = new Set<Id>();
        System.debug('accountPortfolioList: '+accountPortfolioList);
        Map<Id,List<Account_Portfolio_Assignment__c>> accIdAccPortfolioListMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
        for(Account_Portfolio_Assignment__c accPortfolio:accountPortfolioList){
            if(accIdAccPortfolioListMap.containsKey(accPortfolio.Account__c)){
                List<Account_Portfolio_Assignment__c> accPortfolioList = accIdAccPortfolioListMap.get(accPortfolio.Account__c);
                accPortfolioList.add(accPortfolio);
                accIdAccPortfolioListMap.put(accPortfolio.Account__c, accPortfolioList);
            }
            else{
                List<Account_Portfolio_Assignment__c> accPortfolioList = new List<Account_Portfolio_Assignment__c>();
                accPortfolioList.add(accPortfolio);
                accIdAccPortfolioListMap.put(accPortfolio.Account__c, accPortfolioList);
            }
        }
        
        for(Id accId:accIdAccPortfolioListMap.keySet()){
            boolean isSameSupervisorPortfolioExistsForThisAccount = false;
            for(Account_Portfolio_Assignment__c accPortfolio:accIdAccPortfolioListMap.get(accId)){
                if(accPortfolio.BSF_Portfolio__r.Taxonomy_Type__c.equalsIgnoreCase(BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)){
                    if(accPortfolio.BSF_Portfolio__r.Portfolio_Code__c.equalsIgnoreCase(amPortfolio.Portfolio_Code__c)){
                        isSameSupervisorPortfolioExistsForThisAccount = true;
                        accPortfolio.End_Date__c = enddate;
                        accPortfoliosNeedEndDateUpdateList.add(accPortfolio);
                        
                    }
                }
            }
            if(!isSameSupervisorPortfolioExistsForThisAccount){
                accIdSet.add(accId);
            }
        }
        
        List<Account_Portfolio_Assignment__c> supervisorAMPortfolioListToInsert = new List<Account_Portfolio_Assignment__c>();
        List<BSF_Portfolio__c> supervisorAMPortfolio = [SELECT Id,Portfolio_Code__c,Taxonomy_Type__c,
                                                        Portfolio_Name__c,Parent_Portfolio__c,Start_Date__c,End_Date__c
                                                        FROM BSF_Portfolio__c
                                                        WHERE Portfolio_Code__c =: amPortfolio.Portfolio_Code__c and end_Date__c>=: amPortfolio.start_Date__c and Start_Date__c<: amPortfolio.End_Date__c
                                                        AND Taxonomy_Type__c =: BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE  ];//11290 portolio code end_Date__c check in where
        System.debug('supervisorAMPortfolio: '+supervisorAMPortfolio);
        System.debug('accIdSet: '+accIdSet);
        if(accIdSet.size()>0 && supervisorAMPortfolio.size()>0){
            for(Id accId:accIdSet){
                Account_Portfolio_Assignment__c accPortfolioToInsert = new Account_Portfolio_Assignment__c();
                accPortfolioToInsert.Account__c = accId;
                accPortfolioToInsert.BSF_Portfolio__c = supervisorAMPortfolio[0].Id;
                accPortfolioToInsert.Start_Date__c = startdate>=supervisorAMPortfolio[0].Start_Date__c? startdate:supervisorAMPortfolio[0].Start_Date__c;//11290 portolio code date comparison
                accPortfolioToInsert.End_Date__c = enddate<=supervisorAMPortfolio[0].End_Date__c? enddate:supervisorAMPortfolio[0].End_Date__c;//11290 portolio code date comparison
                supervisorAMPortfolioListToInsert.add(accPortfolioToInsert);
            }
        }
        
        if(accPortfoliosNeedEndDateUpdateList.size()>0){
            try{
                System.debug('accPortfoliosNeedEndDateUpdateList: '+accPortfoliosNeedEndDateUpdateList);
                //Schema.DescribeSObjectResult ds = Account_Portfolio_Assignment__c.sObjectType.getDescribe();if( ds.isUpdateable() ){}
                
                BSF_Constants.skipAccountPortfolioAssignmentTrigger = true;
                Database.update(accPortfoliosNeedEndDateUpdateList);
                BSF_Constants.skipAccountPortfolioAssignmentTrigger =false;
                
                
            }
            catch(Exception e){
                System.debug('An Error has occured: '+e.getMessage());
            }
        }
        if(supervisorAMPortfolioListToInsert.size()>0){
            try{
                System.debug('supervisorAMPortfolioListToInsert: '+supervisorAMPortfolioListToInsert);
                //Schema.DescribeSObjectResult ds = Account_Portfolio_Assignment__c.sObjectType.getDescribe();if( ds.isCreateable() ){}
                
                Database.insert(supervisorAMPortfolioListToInsert);
                
                
            }
            catch(Exception e){
                System.debug('An Error has occured: '+e.getMessage());
            }
        }
    }*/
    
    /*
Create Account Team member data
*/
    
    @AuraEnabled
    public static void createAccountTeamData( List<Id> accids, Map<Id,Account_Portfolio_Assignment__c> acctPortMap,String  portfolioid, String portfolioType, Date startdate, Date enddate, BSF_Portfolio__c bsfportfolioobj ){
        System.debug('Inside createAccountTeamData');
        BSF_Constants.isTeamMemberCreatedFromBackend = true;  
        accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accids,null,new set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ()); //HRP-8897 syncs the account team as per account portfolio assignment
        //HRP-10569 parameter changes
        /*if(portfolioType.equals(BSF_Constants.ACCOUNT_PORTFOLIO)){
portfolioType = BSF_Constants.ACCOUNT_MANAGER;
}
if(portfolioType.equals(BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER)||portfolioType.equals(BSF_Constants.NATIONAL_ACCOUNT_MANAGER)||portfolioType.equals(BSF_Constants.Booking_Support)||portfolioType.equals(BSF_Constants.ACCOUNT_SPECIALIST)){

List<BSF_Portfolio__c> portfolioList = [select Id, Portfolio_Type__c, Portfolio_Name__c from BSF_Portfolio__c where Id =: portfolioid  ];

List<Portfolio_Assignment__c> portfolioAssignmentList = [SELECT Id, User__c, BSF_Portfolio__c, Start_Date__c, End_Date__c from Portfolio_Assignment__c WHERE BSF_Portfolio__c =: portfolioid  ORDER BY Start_Date__c];

try{
if( !portfolioAssignmentList.isEmpty() ) {
List<AccountTeammember> atms = new List<AccountTeammember>();
Integer index = 0;
for( Portfolio_Assignment__c pfassign : portfolioAssignmentList ){
index = index +1;
for( ID aid: accids ){
AccountTeammember atm = new AccountTeammember();
atm.AccountAccessLevel = 'Edit';
atm.CaseAccessLevel = 'Edit';
atm.OpportunityAccessLevel = 'Edit';
atm.userId = pfassign.User__c;
atm.AccountId = aid;
atm.Start_Date__c = pfassign.Start_Date__c;
atm.End_Date__c = pfassign.End_Date__c;
atm.TeamMemberRole = portfolioType;

if(index == 1){
if(startdate > pfassign.Start_Date__c) 
atm.Start_Date__c = startdate;
} 

if(index == portfolioAssignmentList.size()){
if(enddate < pfassign.End_Date__c) 
atm.End_Date__c = enddate;
}
atms.add(atm);
}

}

if(!atms.isEmpty()){
//Schema.DescribeSObjectResult ds = AccountTeammember.sObjectType.getDescribe();if( ds.isCreateable() ){}

insert atms;


}

}
} catch (Exception e) {
throw new AuraHandledException(e.getMessage());
}

}
else if(portfolioType.equals(BSF_Constants.ACCOUNT_MANAGER)){

System.debug('Inside Else Part');

List<AccountTeamMember> accTeamInsertList = new List<AccountTeamMember>();
List<AccountTeamMember> accTeamUpdateList = new List<AccountTeamMember>();
List<AccountTeamMember> accTeamDeleteList = new List<AccountTeamMember>();
Map<Id,List<AccountTeamMember>> accountTeamMap = new Map<Id,List<AccountTeamMember>>();
Map<String,BSF_Portfolio__c> portfolioMap = new Map<String,BSF_Portfolio__c>();
Map<String,List<Portfolio_Assignment__c>> portfolioUserMap = new Map<String,List<Portfolio_Assignment__c>>();

AccountPortfolioAssignmentHelper helper = new AccountPortfolioAssignmentHelper();

List<Account> accts = [Select Id,Name,BillingPostalCode,(Select Id,Name,Start_Date__c,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.External_Key__c  FROM AccountPortfolioAssignments__r WHERE END_DATE__c > TODAY ORDER BY Start_Date__c) FROM ACCOUNT WHERE ID IN :accids  ];
List<BSF_Portfolio__c> portfolios = [Select Id,Name,Portfolio_Name__c,Portfolio_Code__c,External_Key__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,Portfolio_Type__c,Start_Date__c,end_date__c FROM BSF_Portfolio__c WHERE ID = :portfolioid AND Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER  ];
//Check if there is any Supervisor Portfolio is Present for the same AM Portfolio Code
List<BSF_Portfolio__c> supervisorPortfolioList = [Select Id,Name,Portfolio_Name__c,Portfolio_Code__c,Taxonomy_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Portfolio_Code__c =: portfolios[0].Portfolio_Code__c AND end_Date__c>=: portfolios[0].Start_Date__c AND Taxonomy_Type__c =: BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE AND Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER  ];//11290 portolio code date check for EndDate
Map<String,Id> supervisorPortfolioCodeIdMap = new Map<String,Id>();
if(supervisorPortfolioList.size()>0){
for(BSF_Portfolio__c supervisorAMPortfolio:supervisorPortfolioList){
supervisorPortfolioCodeIdMap.put(supervisorAMPortfolio.Portfolio_Code__c, supervisorAMPortfolio.Parent_Portfolio__c);
}
}
List<String> teamRoleList = new List<String>();
teamRoleList.add(BSF_Constants.ACCOUNT_MANAGER);
teamRoleList.add(BSF_Constants.AREA_BOOKING_MANAGER);
teamRoleList.add(BSF_Constants.DISTRICT_MANAGER);
teamRoleList.add(BSF_Constants.SUPERVISOR);

List<AccountTeamMember> accountTeamList = [Select Id, UserId ,TeamMemberRole,Bsf_Portfolio__C,Start_Date__c ,End_Date__c ,AccountId FROM AccountTeamMember WHERE AccountId IN :accts AND TeamMemberRole IN :teamRoleList   ORDER BY Start_Date__c ];

for(AccountTeamMember teamMember:accountTeamList){
if(accountTeamMap.get(teamMember.AccountId) == null){
accountTeamMap.put(teamMember.AccountId,new List<AccountTeamMember>());
}
accountTeamMap.get(teamMember.AccountId).add(teamMember);
}

Set<Id> portfolioIds = new Set<Id>();
Map<Id,String> portfolioIdCodeMap = new Map<Id,String>();
for(BSF_Portfolio__c portfolio:portfolios){
//portfolioMap.put(portfolio.External_Key__c,portfolio);
portfolioMap.put(portfolio.Id,portfolio);
portfolioIds.add(portfolio.Id); //AM ID
portfolioIds.add(portfolio.Parent_Portfolio__c); //ABM ID
if(supervisorPortfolioCodeIdMap.containsKey(portfolio.Portfolio_Code__c)){
portfolioIds.add(supervisorPortfolioCodeIdMap.get(portfolio.Portfolio_Code__c));//Supervisor Portfolio ID
portfolioIdCodeMap.put(portfolio.Id,portfolio.Portfolio_Code__c);
}
if(portfolio.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER)
portfolioIds.add(portfolio.Parent_Portfolio__r.Parent_Portfolio__c); //DM ID
}

List<Portfolio_Assignment__c> portFolioUsers = [Select Id,Name, User__c ,Start_Date__c ,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c  FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN :portfolioIds AND End_Date__c > TODAY   ORDER BY Start_Date__c ];

for(Portfolio_Assignment__c portfolioUser:portFolioUsers){
if(!portfolioUserMap.containsKey(portfolioUser.BSF_Portfolio__c)){
portfolioUserMap.put(portfolioUser.BSF_Portfolio__c,new List<Portfolio_Assignment__c>());
}
portfolioUserMap.get(portfolioUser.BSF_Portfolio__c).add(portfolioUser);        
}

System.debug('portFolioUsers ->'+portFolioUsers.size());
System.debug('accts -> '+accts.size());
System.debug(' portfolios -> '+portfolios.size());


System.debug('Account List: '+accts);
System.debug('portfolioUserMap: '+portfolioUserMap);
//HRP-8897
for(Account acct:accts){
System.debug('1st If:portfolioid: '+portfolioid);
System.debug('portfolioMap: '+portfolioMap);
BSF_Portfolio__c portfolio = portfolioMap.get(portfolioid);
Account_Portfolio_Assignment__c newActPortfolioAssignment = acctPortMap.get(acct.Id);
List<Portfolio_Assignment__c> userPortfolioAssigmentList = new List<Portfolio_Assignment__c>();

System.debug('portfolio from PortfolioMap: '+portfolio); 

if(portfolioUserMap.get(portfolio.Id) != null){ //AM
System.debug('Portfolio Id: '+portfolio.Id);
System.debug(portfolioUserMap.get(portfolio.Id));
userPortfolioAssigmentList.addAll(portfolioUserMap.get(portfolio.Id));
}
if(portfolioUserMap.get(portfolio.Parent_Portfolio__c) != null){ //ABM. If No ABM, this is DM.
System.debug('Parent Portfolio: '+portfolio.Parent_Portfolio__c);
userPortfolioAssigmentList.addAll(portfolioUserMap.get(portfolio.Parent_Portfolio__c));
}
if(portfolioUserMap.get(portfolio.Parent_Portfolio__r.Parent_Portfolio__c) != null){ // If ABM present, this is DM. Otherwise, this does not execute.
userPortfolioAssigmentList.addAll(portfolioUserMap.get(portfolio.Parent_Portfolio__r.Parent_Portfolio__c));
}    
if(portfolioUserMap.get(supervisorPortfolioCodeIdMap.get(portfolioIdCodeMap.get(portfolio.Id)))!=null){
userPortfolioAssigmentList.addAll(portfolioUserMap.get(supervisorPortfolioCodeIdMap.get(portfolioIdCodeMap.get(portfolio.Id))));
}
System.debug('userPortfolioAssigmentList: '+userPortfolioAssigmentList);

helper.populateAccountTeam(null,newActPortfolioAssignment,userPortfolioAssigmentList,accountTeamMap.get(acct.id),false,accTeamInsertList,accTeamUpdateList,accTeamDeleteList);

}
for(AccountTeamMember teamM:accTeamInsertList){
teamM.AccountAccessLevel= 'Edit';
teamM.CaseAccessLevel = 'Edit';
teamM.OpportunityAccessLevel = 'Edit';
}


Database.SaveResult[] actTeamInsert = Database.insert(accTeamInsertList, false);

Database.SaveResult[] actTeamUpdate = Database.update(accTeamUpdateList, false);
system.debug('accTeamUpdateList'+accTeamUpdateList);
Database.DeleteResult[] actTeamDelete = Database.delete(accTeamDeleteList, false);
*/
        //HRP-8897
        //accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accids,null,new set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ()); //HRP-8897 syncs the account team as per account portfolio assignment
        //HRP-10569 added 3rd parameter
        
        /*
Set<Id> portfolioassignmentids = new Set<Id>();        
List<Portfolio_Assignment__c> passign = new List<Portfolio_Assignment__c>();
List<BSF_Portfolio__c> bsfportfolios = new List<BSF_Portfolio__c>();
Map<Id, String> portfoliomap = new Map<Id, String>();


portfolioassignmentids.add(portfolioid);
portfolioassignmentids.add(bsfportfolioobj.Parent_Portfolio__c);

bsfportfolios = [select Id, Portfolio_Type__c, Portfolio_Name__c from BSF_Portfolio__c where Id in: portfolioassignmentids];
for(BSF_Portfolio__c pf : bsfportfolios ){
portfoliomap.put( pf.Id, pf.Portfolio_Type__c);
}


passign = [select Id, User__c, BSF_Portfolio__c, Start_Date__c, End_Date__c  from Portfolio_Assignment__c 
where BSF_Portfolio__c in:portfolioassignmentids and 
( (Start_Date__c <=: startdate	and 
End_Date__c >=: startdate) OR  (Start_Date__c >:startdate) ) ];

System.debug( 'passign data is ' + passign );       

try{
if( !passign.isEmpty() ) {
List<AccountTeammember> atms = new List<AccountTeammember>();
AccountTeammember atm;
for( Portfolio_Assignment__c pfassign : passign ){
for( ID aid: accids ){
atm = new AccountTeammember();
atm.AccountAccessLevel = 'Edit';
atm.CaseAccessLevel = 'None';
atm.OpportunityAccessLevel = 'None';
atm.userId = pfassign.User__c;
atm.AccountId = aid;
atm.Start_Date__c = startdate; //pfassign.Start_Date__c ;
atm.End_Date__c = enddate; //pfassign.End_Date__c;
atm.TeamMemberRole = portfoliomap.get(pfassign.BSF_Portfolio__c);

atms.add(atm);
}

}

if(!atms.isEmpty()){
insert atms;
}

}
} catch (Exception e) {
throw new AuraHandledException(e.getMessage());
}*/
        if(portfolioType.equals(BSF_Constants.RELATIONSHIP_MANAGER)){
            System.debug('Inside RM Block');
            List<Portfolio_assignment__c> portfolioAssignmentList = [SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c=:portfolioid
                                                                     order by createdDate DESC LIMIT 1  ];
            
            Map<Id,Id> portfolioUserMap = new Map<Id,Id>();
            for(Portfolio_assignment__c portfolioAssignment:portfolioAssignmentList){
                portfolioUserMap.put(portfolioAssignment.BSF_Portfolio__c, portfolioAssignment.User__c);
            }
            
            List<Account> accList = [SELECT Id,Name,Relationship_Manager__c FROM Account WHERE Id IN:accids  ];
            List<account> accToUpdate = new List<Account>();
            for(Account account:accList){
                account.Relationship_Manager__c = portfolioUserMap.get(portfolioid);
                accToUpdate.add(account);
            }	
            
            if(accToUpdate.size()>0){
                try{
                    //Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();if( ds.isUpdateable() ){}
                    
                    update accToUpdate;
                    
                    
                    
                }
                catch(Exception e){
                    System.debug('An Error has occured: '+e.getMessage());
                }
            }
        }
        
    }
    
    public static List<BSF_Portfolio__c> getPortfolio(String condition,Set<Id>DmBsfPortIdList,string selectedPortfolioType,String taxonomyType)
    {
        String query = 'select Id, Portfolio_Name__c, Portfolio_Type__c,Taxonomy_Type__c,Start_Date__c,End_Date__c,'+
            'Parent_Portfolio__c,'+
            'Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Portfolio_Name__c,'+
            'Parent_Portfolio__r.Parent_Portfolio__c,'+
            'Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c,'+
            'Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,'+
            'Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c, Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Name__c'+
            ' from BSF_Portfolio__c'+ 
            ' where Account_Based_Portfolio__c = true and'+
            ' Portfolio_Type__c =:selectedPortfolioType AND Taxonomy_Type__c =:taxonomyType AND' +
            ' End_Date__c > TODAY'+ condition+'ORDER BY Portfolio_Name__c ASC';
        
        system.debug('query'+query);
        List<BSF_Portfolio__c> portfoliolist = database.query(query);
        return portfoliolist;
    }
    
    public static String getFormattedDate(Date dateVal){
        String dateFormatString = 'yyyy-MM-dd';
        if(dateVal == null)
            return '';
        
        Datetime dt = Datetime.newInstance(dateVal.year(), dateVal.month(),dateVal.day());
        return dt.format(dateFormatString);
    }
    
    public class AccountPortfolioWrapper{
        @AuraEnabled public String accountRecid;
        @AuraEnabled public String portfolioRecId;
        @AuraEnabled public list<string> selectedAccountbasedreason;// HRP-9654
        @AuraEnabled public String Start_Date;
        @AuraEnabled public String End_Date;
        @AuraEnabled public String selectedPortfolioType;
    }
    
    public class BSFPortfolioWrapper{
        @AuraEnabled public String portfolioid;
        @AuraEnabled public String Portfolio_Name;
        @AuraEnabled public String Portfolio_Type;
        @AuraEnabled public String Start_Date;
        @AuraEnabled public String End_Date;
    }
    
    public class AccountInstancesWrapper{
        @AuraEnabled public String account_id;
        @AuraEnabled public String account_name;
        @AuraEnabled public String domainurl;
    }
    
}