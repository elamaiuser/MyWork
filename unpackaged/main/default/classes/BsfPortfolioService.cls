/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  03/08/2023				 Kishore Das		        Users other than System Admin should not have any delete record permissions(Logic for HRP-10572 --> Deleted)
 *  02/14/2024				 Balaji N				    logic for HRP-11138(Method :updatePortfolioAssignments, isBackEndDelete)
 *************************************************************************************************************************************************
*/


public with sharing class BsfPortfolioService {
    
    public static Boolean ALLOW_DATE_OVERRIDE = false;
    
    public static void revertStartDateOnUpdate(List<BSF_Portfolio__c> bsfPortfolioList, Map<Id,BSF_Portfolio__c> portfolioMap){
        if(!ALLOW_DATE_OVERRIDE){
            for(BSF_Portfolio__c portfolio:bsfPortfolioList){
                if(portfolioMap.get(portfolio.Id).Start_Date__c != null)
                    portfolio.Start_Date__c = portfolioMap.get(portfolio.Id).Start_Date__c;
            }
        }
    }
    
    public static void createTaskForAMOrRAOnPortfolioCreation(List<BSF_Portfolio__c> bsfPortfolioList){
        if(System.Label.Create_Task_New_Portfolio != 'Yes' && !Test.isRunningTest()){
            return;
        }
        
        try{
            List<Task> taskList = new list<Task>();
            Map<Id, Id> mapOfbsfPortfolioIdAndDMuserId = new Map<Id, Id>();
            List<BSF_Portfolio__c> getBsfPortfolioList = [Select Id,Name,CreatedDate,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Type__c ,
                                                          Parent_Portfolio__r.Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c 
                                                          FROM BSF_Portfolio__c WHERE ID IN: bsfPortfolioList  ];
            List<Id> dmPortfolios = new List<Id>();
            for(BSF_Portfolio__c dmPortfolio:getBsfPortfolioList){
                if(dmPortfolio.Parent_Portfolio__r.Portfolio_Type__c  == BSF_Constants.DISTRICT_MANAGER)
                    dmPortfolios.add(dmPortfolio.Parent_Portfolio__c);
                else if(dmPortfolio.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c  == BSF_Constants.DISTRICT_MANAGER)
                    dmPortfolios.add(dmPortfolio.Parent_Portfolio__r.Parent_Portfolio__c);
            }
            System.debug('dmPortfolios '+dmPortfolios);
            List<Portfolio_Assignment__c> portfolioAssignmentList = [SELECT Id, Name, BSF_Portfolio__c, User__c 
                                                                     FROM Portfolio_Assignment__c where BSF_Portfolio__c IN:dmPortfolios  Order By End_Date__c];
            
            for(Portfolio_Assignment__c portfolioaAssgn: portfolioAssignmentList){
                mapOfbsfPortfolioIdAndDMuserId.put(portfolioaAssgn.BSF_Portfolio__c, portfolioaAssgn.User__c);
            }
            System.debug('mapOfbsfPortfolioIdAndDMuserId '+mapOfbsfPortfolioIdAndDMuserId);
            
            Id systemUserId = [SELECT ID FROM USER WHERE isActive = TRUE AND Profile.name =:
                               System.Label.storeProfileToCreateBsfPortfolioTask limit 1].Id;
            Id taskRecordTypeId = [SELECT Id From RecordType where sobjecttype = 'Task' AND 
                                   NAME = 'General Task for Global Action'].Id;
            
            for(BSF_Portfolio__c bsf: getBsfPortfolioList){
                Id taskOwnerId = null;
                
                System.debug('bsf.Parent_Portfolio__r.Portfolio_Type__c '+bsf.Parent_Portfolio__r.Portfolio_Type__c);
                System.debug('bsf.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c '+bsf.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c);
                if(bsf.Parent_Portfolio__r.Portfolio_Type__c  == BSF_Constants.DISTRICT_MANAGER)
                    taskOwnerId =  mapOfbsfPortfolioIdAndDMuserId.get(bsf.Parent_Portfolio__c);
                else if(bsf.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER)
                    taskOwnerId =  mapOfbsfPortfolioIdAndDMuserId.get(bsf.Parent_Portfolio__r.Parent_Portfolio__c);
                
                System.debug('taskOwnerId '+taskOwnerId);
                Task tsk = new Task();
                tsk.Subject = bsf.Name + ' has been created and needs a user assigned';
                tsk.WhatId = bsf.Id;
                tsk.OwnerId = taskOwnerId != null?taskOwnerId:systemUserId;
                tsk.Status = 'New';
                tsk.RecordTypeId = taskRecordTypeId;
                tsk.ActivityDate = AddBusinessDays(Date.ValueOf(bsf.CreatedDate) ,3);
                taskList.add(tsk);
            }
            
            
            insert taskList;
        }catch(Exception ex){
            System.debug('Exception in createTaskForAMOrRAOnPortfolioCreation '+ex);
        }
        
        
    }
    public static Date AddBusinessDays(Date startDate, Integer businessDaysToAdd )
    {
        Date finalDate = startDate;
        Integer direction = businessDaysToAdd < 0 ? -1 : 1;
        while(businessDaysToAdd != 0)
        {
            finalDate = finalDate.addDays(direction);
            if (!IsWeekend(finalDate))
            {
                businessDaysToAdd -= direction;
            }
        }
        return finalDate;
    }
    public static Boolean IsWeekend(Date myDate)
    {
        String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);
    }
    
    public static void updatePortfolioAssignments(List<Bsf_Portfolio__c> newItems,Map<id,Bsf_Portfolio__c> newMap,Map<id,Bsf_Portfolio__c> oldMap)
    {
        system.debug('updatePortfolioAssignments');
        set<id> bsfId = new set<id>();
        set<id> bsfIdDm = new set<id>();
        set<string> dmPortCode = new set<string>();
        map<string,Bsf_Portfolio__c> portcodeBSfMap= new map<string,Bsf_Portfolio__c>();
        set<id> bsfIdBioAccPort = new set<id>();
        
        
        // checking end date change
        for(Bsf_Portfolio__c bsf : newItems)
        {
            if(bsf.End_Date__c != oldMap.get(bsf.id).End_Date__c)
            {
                //system.debug('Endatechanged');
                
                // DM
                if(bsf.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER || bsf.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER )
                {
                    //system.debug('DM Portfolio');
                    bsfIdDm.add(bsf.id);
                    dmPortCode.add(bsf.Portfolio_Code__c);
                    portcodeBSfMap.put(bsf.Portfolio_Code__c,bsf);
                }
                else 
                {
                    //system.debug('other Portfolio');
                    bsfId.add(bsf.id);
                }
                
            }
        }
        //updating portfolio assignments
        List<portfolio_Assignment__c> portfoliAssignList = [select id,Start_Date__c,End_Date__c,Bsf_portfolio__c,Bsf_portfolio__r.portfolio_code__c,BSF_Portfolio__r.Taxonomy_Type__c from portfolio_Assignment__c where Bsf_portfolio__c IN:bsfId or Bsf_portfolio__c IN:bsfIdDm or (Bsf_portfolio__r.Portfolio_Code__c In:dmPortCode and Bsf_portfolio__r.Taxonomy_Type__c=: BSF_Constants.ACCOUNT_SPECIALIST)];
        //system.debug('portfoliAssignList');
        List<portfolio_Assignment__c> updatePortfoliAssignList = new List<portfolio_Assignment__c>();
        List<portfolio_Assignment__c> deletePortfoliAssignList = new List<portfolio_Assignment__c>();
        for(portfolio_Assignment__c pa:portfoliAssignList)
        {
            if(oldMap!= null && (pa.Bsf_portfolio__r.Taxonomy_Type__c!=BSF_Constants.ACCOUNT_SPECIALIST ||oldMap.get(pa.Bsf_portfolio__c)!= null) ) // active ones only, already ended one we don't consider
            {
                if(pa.End_Date__c > newMap.get(pa.Bsf_portfolio__c).End_Date__c && pa.Start_Date__c < newMap.get(pa.Bsf_portfolio__c).End_Date__c &&  pa.End_Date__c >= system.today())
                {
                    //system.debug(' Portfolio assignments there'+pa.id);
                    pa.End_Date__c = newMap.get(pa.Bsf_portfolio__c).End_Date__c;
                    updatePortfoliAssignList.add(pa);
                }
                else if(pa.Start_Date__c > newMap.get(pa.Bsf_portfolio__c).End_Date__c)
                {
                    deletePortfoliAssignList.add(pa);
                }
            }
            system.debug('Portfolio assignments'+pa);
            if(pa.Bsf_portfolio__r.Taxonomy_Type__c==BSF_Constants.ACCOUNT_SPECIALIST && portcodeBSfMap!=null && portcodeBSfMap.get(pa.Bsf_portfolio__r.portfolio_code__c) != null
               && oldMap.get(portcodeBSfMap.get(pa.Bsf_portfolio__r.portfolio_code__c).id) !=null)
            {
                if(pa.End_Date__c >newMap.get(portcodeBSfMap.get(pa.Bsf_portfolio__r.portfolio_code__c).id).End_Date__c  
                   && pa.Start_Date__c < newMap.get(portcodeBSfMap.get(pa.Bsf_portfolio__r.portfolio_code__c).id).End_Date__c &&pa.End_Date__c >= system.today())
                {
                    //system.debug(' Portfolio assignments there'+pa.id);
                    pa.End_Date__c = portcodeBSfMap.get(pa.Bsf_portfolio__r.portfolio_code__c).End_Date__c;
                    updatePortfoliAssignList.add(pa);
                }
                else if(pa.Start_Date__c > newMap.get(portcodeBSfMap.get(pa.Bsf_portfolio__r.portfolio_code__c).id).End_Date__c)
                {
                    deletePortfoliAssignList.add(pa);
                }
            }
            
            
            
        }
        
        
        if(!updatePortfoliAssignList.isEmpty())
        {
            //triggerhandler.bypass('PortfolioAssignmentTriggerHandler');
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.Update(updatePortfoliAssignList,false), 'Create Portfolio','BSFPortfolioService','updatePortfolioAssignments','Error','updating BSFPortfolio Endate');
            InsertBsfErrorLog.insertBsfErrors(logList);
            //triggerhandler.clearbypass('PortfolioAssignmentTriggerHandler');
        }
        if(!deletePortfoliAssignList.isEmpty())
        {
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.delete(deletePortfoliAssignList,false), 'Create Portfolio','BSFPortfolioService','updatePortfolioAssignments','Error','deleting BSFPortfolio');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
        
        //account portfolio assignment update
        List<Account_portfolio_Assignment__c> accportfoliAssignList = [select id,Start_Date__c,End_Date__c,Bsf_portfolio__c,Bsf_portfolio__r.Portfolio_Type__c,account__c from Account_portfolio_Assignment__c where Bsf_portfolio__c IN:bsfId];
        system.debug('accportfoliAssignList'+accportfoliAssignList);
        List<Account_portfolio_Assignment__c> updateAccPortfoliAssignList = new List<Account_portfolio_Assignment__c>();
        List<Account_portfolio_Assignment__c> deleteAccPortfoliAssignList = new List<Account_portfolio_Assignment__c>();
        List<Account_portfolio_Assignment__c> recAccPortfoliAssignList = new List<Account_portfolio_Assignment__c>();
        for(Account_portfolio_Assignment__c ap:accportfoliAssignList)
        {
            bsf_Portfolio__c  bsf = newMap.get(ap.Bsf_portfolio__c);
            if(ap.End_Date__c > newMap.get(ap.Bsf_portfolio__c).End_Date__c && ap.Start_Date__c < newMap.get(ap.Bsf_portfolio__c).End_Date__c && ap.End_Date__c >= system.today()) // active ones only, already ended one we don't consider
            {
                //if territory
                
                if(bsf.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER && bsf.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE)
                {
                    //ap.End_Date__c = newMap.get(ap.Bsf_portfolio__c).End_Date__c;
                    //system.debug('recAccPortfoliAssignList'+ap);
                    recAccPortfoliAssignList.add(ap);
                }
                else //if(bsf.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER && bsf.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE )
                {
                    //system.debug('adding  portfolios:'+ ap);
                    ap.End_Date__c = newMap.get(ap.Bsf_portfolio__c).End_Date__c;
                    updateAccPortfoliAssignList.add(ap);
                    
                }
                
            }
            else if(ap.Start_Date__c > newMap.get(ap.Bsf_portfolio__c).End_Date__c)
            {
                //system.debug('adding  portfolios to delete:'+ ap);
                deleteAccPortfoliAssignList.add(ap);
            }
        }
        
        /*for(Account_Portfolio_Assignment__c ap:updateAccPortfoliAssignList)
{
system.debug('updateAccPortfoliAssignList-1-1'+ap);
}*/
        
        // territory account portfolio update and next account based update
        if(!deleteAccPortfoliAssignList.isEmpty())
        {
            BSF_Constants.isBackEndDelete=true;//HRP-11138
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.delete(deleteAccPortfoliAssignList,false), 'Create Portfolio','BSFPortfolioService','updatePortfolioAssignments','Error','deleting AccportfolioAssignments');
            InsertBsfErrorLog.insertBsfErrors(logList);
            BSF_Constants.isBackEndDelete=false;//HRP-11138
        }
        if(!recAccPortfoliAssignList.isEmpty())
        {
            system.debug('recAccPortfoliAssignList is not null');
            set<id> accIdSet = new set<id>();
            set<id> accPortIdSet = new set<id>();
            map<id,Account_portfolio_Assignment__c> accIdTerrAccportMap = new map<id,Account_portfolio_Assignment__c>();
            for(Account_portfolio_Assignment__c ap: recAccPortfoliAssignList)
            {
                accIdSet.add(ap.Account__c);
                accIdTerrAccportMap.put(ap.Account__c,ap);
                accPortIdSet.add(ap.id);
            }
            
            
            List<Account_portfolio_Assignment__c> accBasedportfoliAssignList = [select id,Start_Date__c,End_Date__c,Bsf_portfolio__c,Bsf_portfolio__r.Portfolio_Type__c,Account__c,Bsf_portfolio__r.Taxonomy_Type__c from Account_portfolio_Assignment__c 
                                                                                where Account__c IN:accIdSet and End_Date__c > today order by Start_Date__c];
            map<id,Account_portfolio_Assignment__c> accIdAccountBased = new map<id,Account_portfolio_Assignment__c>();
            for(Account_portfolio_Assignment__c ap:accBasedportfoliAssignList)
            {
                if(!accIdAccountBased.keyset().contains(ap.account__c) && ap.Bsf_portfolio__r.Taxonomy_Type__c==BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)
                {
                    accIdAccountBased.put(ap.Account__c,ap);
                }
            }
            //system.debug('accIdAccountBased'+accIdAccountBased);
            //system.debug('accBasedportfoliAssignList'+accBasedportfoliAssignList);
            list<Account_portfolio_Assignment__c> terrAccportWithnoAccExcepList = new list<Account_portfolio_Assignment__c>();
            
            for(Account_portfolio_Assignment__c ap:accBasedportfoliAssignList)
            {
                Account_portfolio_Assignment__c terrAccPort;
                if(accIdTerrAccportMap!= null)
                    terrAccPort = accIdTerrAccportMap.get(ap.Account__c);
                //system.debug('terrAccPort'+terrAccPort);
                if(terrAccPort != null && ap.Start_Date__c == terrAccPort.End_Date__c+1 &&  ap.Bsf_portfolio__r.Taxonomy_Type__c==BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE && ap.Bsf_portfolio__r.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER)
                {
                    //system.debug('adding account based portfolio'+ap.id);
                    ap.Start_Date__c = newMap.get(terrAccPort.Bsf_portfolio__c).End_Date__c + 1;
                    updateAccPortfoliAssignList.add(ap);
                }
            }
            
            for(Account_portfolio_Assignment__c ap:recAccPortfoliAssignList)
            {
                ap.End_Date__c=newMap.get(ap.Bsf_portfolio__c).End_Date__c;
                updateAccPortfoliAssignList.add(ap);
            }
        }
        
        /*for(Account_Portfolio_Assignment__c ap:updateAccPortfoliAssignList)
{
system.debug('updateAccPortfoliAssignListfinal-1'+ap);
}*/
        
        // DM and account specilaist
        if(!dmPortCode.isEmpty())
        {
            list<Bsf_Portfolio__c> accSpecialistPortList = [select id,Start_Date__c,End_Date__c,Portfolio_Code__c,Taxonomy_Type__c from Bsf_Portfolio__c where Portfolio_Code__c In:dmPortCode and Taxonomy_Type__c=: BSF_Constants.ACCOUNT_SPECIALIST];
            list<Bsf_Portfolio__c> updateAccSpecialistPortList = new list<Bsf_Portfolio__c>();
            map<id,Bsf_Portfolio__c> idbsfMap =new map<id,Bsf_Portfolio__c>();
            for(Bsf_Portfolio__c bsf :accSpecialistPortList)
            {
                if(portcodeBSfMap != null && portcodeBSfMap .get(bsf.Portfolio_Code__c)!= null)
                {
                    bsf.End_Date__c = portcodeBSfMap.get(bsf.Portfolio_Code__c).End_Date__c;
                    updateAccSpecialistPortList.add(bsf);
                    idbsfMap.put(bsf.id,bsf);
                }
            }
            
            if(!updateAccSpecialistPortList.isEmpty())
            {
                triggerhandler.bypass('BsfPortfolioTriggerHandler');
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(database.update(updateAccSpecialistPortList,false),'Create Portfolio','BSFPortfolioService','updatePortfolioAssignments','Error','updating BSFPortfolio Endate');
                InsertBsfErrorLog.insertBsfErrors(logList);
                
                triggerhandler.clearBypass('BsfPortfolioTriggerHandler');
            }
            
            
            List<Account_portfolio_Assignment__c> accBasedportfoliAssignList = [select id,Start_Date__c,End_Date__c,Bsf_portfolio__c,Account__c,Bsf_portfolio__r.parent_portfolio__c,Bsf_portfolio__r.parent_portfolio__r.parent_portfolio__c from Account_portfolio_Assignment__c 
                                                                                where Bsf_portfolio__c In:idbsfMap.keyset() or (Bsf_portfolio__r.parent_portfolio__c In: bsfIdDm or Bsf_portfolio__r.parent_portfolio__r.parent_portfolio__c In:bsfIdDm) ];
            system.debug('accBasedportfoliAssignList'+accBasedportfoliAssignList);
            
            set<id> accIdset = new set<id>();
            map<id,list<Account_portfolio_Assignment__c>> idAccSpMap = new map<id,list<Account_portfolio_Assignment__c>>();
            map<string,Account_portfolio_Assignment__c> dmIdAccPortMap = new map<string,Account_portfolio_Assignment__c>();
            for(Account_portfolio_Assignment__c ap:accBasedportfoliAssignList)
            {
                
                if(idbsfMap.keyset().contains(ap.BSF_Portfolio__c))
                {
                    if(idAccSpMap.containskey(ap.BSF_Portfolio__c))
                    {
                        //system.debug('idAccSpMap'+ap.BSF_Portfolio__c);
                        idAccSpMap.get (ap.BSF_Portfolio__c).add(ap);
                    }
                    else
                    {
                        idAccSpMap.put(ap.BSF_Portfolio__c,new list<Account_portfolio_Assignment__c>{ap});
                    }
                    
                }
                else
                {
                    accIdset.add(ap.Account__c);
                }
                
                if(bsfIdDm.contains(ap.Bsf_portfolio__r.parent_portfolio__c))
                {
                    //system.debug('dmIdAccPortMap'+ap);
                    dmIdAccPortMap.put(ap.Account__c+'_'+ap.BSF_Portfolio__r.parent_portfolio__c,ap);
                    //system.debug('Key:'+ap.Account__c+'_'+ap.BSF_Portfolio__r.parent_portfolio__c);
                }
                else if( bsfIdDm.contains(ap.Bsf_portfolio__r.parent_portfolio__r.parent_portfolio__c))
                {
                    //system.debug('dmIdAccPortMap'+ap);
                    dmIdAccPortMap.put(ap.Account__c+'_'+ap.BSF_Portfolio__r.parent_portfolio__r.parent_portfolio__c,ap);
                    //system.debug('Key:'+ap.Account__c+'_'+ap.BSF_Portfolio__r.parent_portfolio__r.parent_portfolio__c);
                }
            }
            
            for(id id: idAccSpMap.keyset())
            {
                for(Account_portfolio_Assignment__c ap :idAccSpMap.get(id) )
                {
                    //system.debug('idbsfMap'+idbsfMap.get(ap.Bsf_portfolio__c));
                    if(idbsfMap!= null && idbsfMap.get(ap.Bsf_portfolio__c) != null && idbsfMap.get(ap.Bsf_portfolio__c).Taxonomy_Type__c==BSF_Constants.ACCOUNT_SPECIALIST)
                    {
                        bsf_Portfolio__c  bsf = idbsfMap.get(ap.Bsf_portfolio__c);
                        //system.debug('bsf'+bsf);
                        if(bsf!= null && ap.End_Date__c > newMap.get(portcodeBSfMap.get(bsf.Portfolio_Code__c).id).End_Date__c  && ap.End_Date__c >= system.today() && !updateAccPortfoliAssignList.contains(ap))
                        {
                            //system.debug('adding specilaist portfolio');
                            ap.End_Date__c = bsf.End_Date__c;
                            updateAccPortfoliAssignList.add(ap);
                            
                        }
                        
                    }
                }
            }
            
            
            //system.debug('updateAccPortfoliAssignList'+updateAccPortfoliAssignList);
            
            //DM and Account specialist Teammembers
            list<accountTeamMember> dmAtmList = [select id,Start_Date__c,End_Date__c,Bsf_portfolio__c,accountId,UserId,Bsf_portfolio__r.parent_portfolio__c from accountTeamMember where accountID In:accIdset and (teammemberRole='District Manager' or teammemberRole=:bsf_Constants.AREA_BOOKING_MANAGER)];
            list<accountTeamMember> UpdatedDmAtmList = new list<accountTeamMember>();
            //system.debug('AccteamEndate '+dmAtmList);
            for(accountTeamMember atm : dmAtmList)
            {
                
                bsf_Portfolio__c  bsf = newMap.get(atm.Bsf_portfolio__c);
                if(bsf!=null)
                {
                    //system.debug('AccteamEndate'+ 'id_'+atm.id+'_'+atm.End_Date__c +'bsf'+ bsf.End_Date__c);
                    
                }
                
                if(dmIdAccPortMap != null)
                {
                    //system.debug('atmKey:'+atm.accountid+'_'+atm.Bsf_portfolio__c);
                    //system.debug('dmIdAccPortMap'+dmIdAccPortMap.get(atm.accountid+'_'+atm.BSF_Portfolio__c));
                }
                if(bsf!= null && atm.End_Date__c > newMap.get(atm.Bsf_portfolio__c).End_Date__c  && atm.End_Date__c >= system.today() && dmIdAccPortMap != null && dmIdAccPortMap.get(atm.accountid+'_'+atm.Bsf_portfolio__c) != null)
                {
                    account_portfolio_assignment__c Ap = dmIdAccPortMap.get(atm.accountid+'_'+atm.BSF_Portfolio__c);
                    //system.debug('AccteamEndate'+atm.End_Date__c +'bsf'+ bsf.End_Date__c+'_'+ap.End_Date__c);
                    
                    atm.End_Date__c = bsf.End_Date__c < Ap.End_Date__c ? bsf.End_Date__c:Ap.End_Date__c;
                    UpdatedDmAtmList.add(atm);
                }
                /*if(idbsfMap!= null && idbsfMap.get(atm.Bsf_portfolio__c) != null)
{
bsf = newMap.get(idbsfMap.get(atm.Bsf_portfolio__c).Portfolio_Code__c);
if(bsf!= null && atm.End_Date__c >= bsf.End_Date__c  && atm.End_Date__c >= system.today())
{

if(bsf != null && atm.End_Date__c >= bsf.End_Date__c  && atm.End_Date__c >= system.today())
{
UpdatedDmAtmList.add(atm);
}
}
}*/
                
            }
            
            if(!UpdatedDmAtmList.isEmpty())
            {
                //List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(database.update(UpdatedDmAtmList,false),'Create Portfolio','BSFPortfolioService','updatePortfolioAssignments','Error','updating BSFPortfolio Endate');
                //InsertBsfErrorLog.insertBsfErrors(logList);
                
            }
        }
        
        
        if(!updateAccPortfoliAssignList.isEmpty())
        {
            map<id,account_portfolio_assignment__c> updateAccPortfoliAssignMap = new map<id,account_portfolio_assignment__c>();
            for(account_portfolio_assignment__c apa:updateAccPortfoliAssignList)
            {
                updateAccPortfoliAssignMap.put(apa.id,apa);
            }
            triggerhandler.bypass('AccountPortfolioAssignmentTriggerHandler');
            
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.Update(updateAccPortfoliAssignMap.values(),false),'Create Portfolio','BSFPortfolioService','updatePortfolioAssignments','Error','updateAccPortfoliAssignList Endate');
            InsertBsfErrorLog.insertBsfErrors(logList);
            //triggerhandler.clearBypass('AccountPortfolioAssignmentTriggerHandler');
        }
    }

}