/*
*
* Modification Log
* Date					Developer Name			Comments
* ***************************************************************************
* 27/04/2023				Balaji N			Logic for HRP-9951(Methods: populateRMLookupOnAccount & checkPfAssign)
* 07/28/2023               Balaji N            Logic for HRP-10793(Method:updateEndDateOfAccountTeamMembers; DML limit check for platfomr event)
* 08/09/2023	 	  	    Balaji N		    Logic for HRP-8897(Method:updateEndDateOfAccountTeamMembers,deleteAccountTeamMembers)
* 08/29/2023				Balaji N			Logic for HRP-10888(Method:updateEndDateOfAccountTeamMembers: null check)
* 10/18/2023				Balaji N			Logic for HRP-11035(Method:manageUserAssignemntForPortfolioInOtherTaxo,added BSF Error Log for DML in Other Taxonomy)
* 11/07/2023				Balaji N			Logic for HRP-11290(Method:publishPlarformEventsOnAfterInsert; Handles account Team on Portfolio Insert/Update/Delete earlier Insert only)
* 11/08/2023				Balaji N			Logic for HRP-11290 Commented createAccountTeamMembers,createAMandDM,createABMRecords,createDMRecords,createSingleLevelPortfolioRecords,updateEndDateOfAccountTeamMembers,updateacctTeammembers,deleteAccountTeamMembers,deletePortfolioAssignedMembersfromAccountTeam)
* 08/05/2024				Balaji N     		Logic for HRP-13028 (Method:publishPlarformEventsOnAfterInsert,AccTeamUpdatePortfolioAssignQueue limit check)
* 08/16/2024				Balaji N			Logic for HRP-13270 (Method:manageUserAssignemntForPortfolioInOtherTaxo; updates in supervisor taxonomy doesn't go to Bio Recruitment/Bio Account)
* */
public with sharing class PortfolioAssignmentService {
    public static Boolean isExecuted = false;
    //Added as part of HRP-999
    //Below method will add AccountTeamMembers to the Accounts when a new record is inserted to Portfolio_Assignment__c
    /*public static Boolean createAMandDM(List<Portfolio_Assignment__c> newPortfolioAssignmentList){
system.debug('Entered createAMandDM');
Set<Id> portfolioAssignmentIdSet = new Set<Id>();
Map<Id,Portfolio_Assignment__c> portfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c portfolioAssignment:newPortfolioAssignmentList){
portfolioAssignmentIdSet.add(portfolioAssignment.BSF_Portfolio__c);
portfolioUserMap.put(portfolioAssignment.BSF_Portfolio__c,portfolioAssignment);
}
List<BSF_Portfolio__c> portfolioList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:portfolioAssignmentIdSet];
Set<Id> amPortfolioId = new Set<Id>();
Set<Id> dmPortfolioId = new Set<Id>();
Map<Id,Id> AmToDMMap = new Map<Id,Id>();
Map<Id,BSF_Portfolio__c> portfolioIdMap = new Map<Id,BSF_Portfolio__c>();
if(portfolioList.size()>0){
for(BSF_Portfolio__c portfolio:portfolioList){
if(portfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER || portfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_PORTFOLIO){
amPortfolioId.add(portfolio.Id);
dmPortfolioId.add(portfolio.Parent_Portfolio__c);
AmToDMMap.put(portfolio.Id, portfolio.Parent_Portfolio__c);
portfolioIdMap.put(portfolio.Id,portfolio);
}
}
}
//Get the Users assigned to District Manager Portfolio
List<Portfolio_Assignment__c> DMUserList = [SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:dmPortfolioId AND End_Date__c > TODAY];
Map<Id,Portfolio_Assignment__c> portfolioDMMap = new Map<Id,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c DMPortfolio:DMUserList){
portfolioDMMap.put(DMPortfolio.BSF_Portfolio__c,DMPortfolio);
}
List<Account_Portfolio_Assignment__c> accountPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:amPortfolioId AND End_Date__c > TODAY];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
accIdBsfIDAccPortfolioMap.put(accountPortfolio.Account__c+'_'+accountPortfolio.BSF_Portfolio__c, accountPortfolio);
}
List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
if(portfolioUserMap.containsKey(portfolioId)){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = portfolioUserMap.get(portfolioId);
AccountTeamMember AMteamMember = new AccountTeamMember();
AMteamMember.AccountId = accId;
AMteamMember.UserId = portfolioAssign.User__c;
AMteamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
AMteamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
AMteamMember.AccountAccessLevel = 'Edit';
AMteamMember.CaseAccessLevel = 'Edit';
AMteamMember.OpportunityAccessLevel = 'Edit';
AMteamMember.TeamMemberRole = BSF_Constants.ACCOUNT_MANAGER;
AMteamMember.BSF_Portfolio__c = portfolioId;
teamMemberList.add(AMteamMember);
}
if(portfolioDMMap.containsKey(AmToDMMap.get(portfolioId))){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = portfolioDMMap.get(AmToDMMap.get(portfolioId));
AccountTeamMember DMteamMember = new AccountTeamMember();
DMteamMember.AccountId = accId;
DMteamMember.UserId = portfolioAssign.User__c;
DMteamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
DMteamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
DMteamMember.AccountAccessLevel = 'Edit';
DMteamMember.CaseAccessLevel = 'Edit';
DMteamMember.OpportunityAccessLevel = 'Edit';
DMteamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
DMteamMember.BSF_Portfolio__c = AmToDMMap.get(portfolioId);
teamMemberList.add(DMteamMember);
}
}
}
if(teamMemberList.size()>0){
System.debug('teamMemberList size: '+teamMemberList.size());
System.debug('AccountTeamMember List: '+teamMemberList);
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.upsert(teamMemberList,false), 'Create Portfolio','PortfolioAssignmentService','createAMandDM','Error','Error in Creatin AM & DM');
InsertBsfErrorLog.insertBsfErrors(logList);
return true;
}
else
{
return false;
}
}*/
    //****For the Story HRP-4623 ****
    public static void manageUserAssignemntForPortfolioInOtherTaxo(List<Portfolio_Assignment__c> portfolioAssignmentList,Map<Id,Portfolio_Assignment__c> oldPortfolioAssignmentMap,String operation){
        if(BSF_Constants.skipPortfolioAssignmentTrigger){
            return;
        }
        BSF_Constants.skipPortfolioAssignmentTrigger = true;
        Set<Id> bsfPortRecordsId=new Set<Id>();
        Map<Id,Portfolio_Assignment__c> mapOfBsfandPortFolio = new Map<Id,Portfolio_Assignment__c>();
        Map<String,Portfolio_Assignment__c> currentPortAssRecordMap = new Map<String,Portfolio_Assignment__c>();
        List<Portfolio_Assignment__c> listOfPortAssrecordsToInsert = new List<Portfolio_Assignment__c>();
        List<Portfolio_Assignment__c> listOfPortAssrecordsToUpdate = new List<Portfolio_Assignment__c>();
        List<Portfolio_Assignment__c> listTodeletePfa = new List<Portfolio_Assignment__c>();
        List<String> amPortfolioList = new List<String>{BSF_constants.BIO_RECRUITMENT_RECORD_TYPE,BSF_constants.TAXO_ACCOUNT_RECORD_TYPE};
        system.debug('currentPortAssRecordMap ##'+currentPortAssRecordMap);
        system.debug('oldPortfolioAssignmentMap##'+oldPortfolioAssignmentMap);
        for(Portfolio_Assignment__c pfAssignment:portfolioAssignmentList){
            if(pfAssignment.User__c != null){
                bsfPortRecordsId.add(pfAssignment.BSF_Portfolio__c);
            }
        }
        Map<Id,BSF_Portfolio__c> portfolioIdPortfolioMap =new Map<Id,BSF_Portfolio__c>([select Id,Portfolio_Code__c,Portfolio_type__c,Taxonomy_type__c from BSF_Portfolio__c where Id IN:bsfPortRecordsId  and
                                                                                         Portfolio_Code__c!=null AND Taxonomy_type__c IN:amPortfolioList]); //getting all  //HRP-13270
        system.debug('listOfBSFWithPfAssignment ##'+portfolioIdPortfolioMap);
        for(Portfolio_Assignment__c pfAssignment:portfolioAssignmentList){
            if(pfAssignment.User__c!=null && portfolioIdPortfolioMap != null && portfolioIdPortfolioMap.containsKey(pfAssignment.bsf_portfolio__c))//HRP-13270
            {
                mapOfBsfandPortFolio.put(pfAssignment.BSF_Portfolio__c,pfAssignment);
            }
            //HRP-13270
            else
            {
                Continue;
            }
            //HRP-13270
            if(oldPortfolioAssignmentMap != null &&
               ((oldPortfolioAssignmentMap.get(pfAssignment.Id).User__c != pfAssignment.User__c && pfAssignment.User__c!=null )||
                (oldPortfolioAssignmentMap.get(pfAssignment.Id).Start_Date__c != pfAssignment.Start_Date__c)||
                (oldPortfolioAssignmentMap.get(pfAssignment.Id).End_Date__c != pfAssignment.End_Date__c) ||
                operation == 'Delete')
              ){
                  system.debug('user 1##'+oldPortfolioAssignmentMap.get(pfAssignment.Id).User__c);
                  system.debug('portfolio code ##'+portfolioIdPortfolioMap.get(pfAssignment.BSF_Portfolio__c).Portfolio_Code__c);
                  system.debug('start date##'+oldPortfolioAssignmentMap.get(pfAssignment.Id).Start_Date__c);
                  currentPortAssRecordMap.put(oldPortfolioAssignmentMap.get(pfAssignment.Id).User__c+portfolioIdPortfolioMap.get(pfAssignment.BSF_Portfolio__c).Portfolio_Code__c+oldPortfolioAssignmentMap.get(pfAssignment.Id).Start_Date__c,pfAssignment);
              }
        }
        if(!bsfPortRecordsId.isEmpty()){
            System.debug('currentPortAssRecordMap is - > '+currentPortAssRecordMap);
            Map<String,Portfolio_Assignment__c> portfolioCodeAssignmentMap = new Map<String,Portfolio_Assignment__c>();
            Set<String>  setofPortfolioCodes = new Set<String>();
            if(!portfolioIdPortfolioMap.values().isEmpty()){
                for(BSF_Portfolio__c bsfRecord:portfolioIdPortfolioMap.values())
                {
                    setofPortfolioCodes.add(bsfRecord.Portfolio_Code__c);
                    Portfolio_Assignment__c pfAssignment1=MapOfBsfandPortFolio.get(bsfRecord.id);
                    portfolioCodeAssignmentMap.put(bsfRecord.Portfolio_Code__c,pfAssignment1);
                }
                if(!setofPortfolioCodes.isEmpty()){
                    amPortfolioList.add(BSF_constants.TAXO_SUPERVISOR_RECORD_TYPE);//HRP-13270
                    Map<Id,BSF_Portfolio__c> mapOfAllBsfwithoutAssignment = new Map<Id,BSF_Portfolio__c>(
                        [select Id,Portfolio_Code__c,Start_Date__c,End_Date__c,Portfolio_Type__c,Taxonomy_Type__c,(Select id,Name,Start_Date__c,End_Date__c, Assignment_Type__c,User__c from PortfolioAssignments__r)
                         FROM BSF_Portfolio__c WHERE Portfolio_Code__c IN:setofPortfolioCodes
                         AND  Id NOT IN:portfolioIdPortfolioMap.keySet() AND Taxonomy_type__c IN:amPortfolioList AND Is_Expired__c=false]);//HRP-13270
                    system.debug('mapOfPortfolioCodes '+mapOfAllBsfwithoutAssignment);
                    for(BSF_Portfolio__c bsfPortRec:mapOfAllBsfwithoutAssignment.values()){
                        if(operation == 'Insert'){
                            Portfolio_Assignment__c insertedPfAssignment = portfolioCodeAssignmentMap.get(bsfPortRec.Portfolio_Code__c);
                            if(insertedPfAssignment.Start_Date__c <= bsfPortRec.End_date__c)//HRP-11281 new if condition
                            {
                                Portfolio_Assignment__c ps = new Portfolio_Assignment__c();
                                ps.BSF_Portfolio__c = bsfPortRec.id;
                                ps.User__c = insertedPfAssignment.User__c;
                                ps.Start_Date__c = insertedPfAssignment.Start_Date__c;
                                ps.End_Date__c = insertedPfAssignment.End_Date__c;
                                ps.Assignment_Type__c = insertedPfAssignment.Assignment_Type__c;
                                listOfPortAssrecordsToInsert.add(ps);
                            }
                        }else{
                            for(Portfolio_Assignment__c existingPortfolioAssignment:bsfPortRec.PortfolioAssignments__r)
                            {
                                Portfolio_Assignment__c updatedOrDeletedPortfolio = currentPortAssRecordMap.get(existingPortfolioAssignment.User__c+bsfPortRec.Portfolio_Code__c+existingPortfolioAssignment.Start_Date__c);
                                system.debug('updatedOrDeletedPortfolio -> '+updatedOrDeletedPortfolio);
                                if(operation == 'Delete' && updatedOrDeletedPortfolio != null)
                                {
                                    listTodeletePfa.add(existingPortfolioAssignment);
                                }
                                else if(operation == 'Update' && updatedOrDeletedPortfolio != null)
                                {
                                    //HRP-13270
                                if(bsfPortRec.Taxonomy_Type__c == BSF_constants.TAXO_SUPERVISOR_RECORD_TYPE && existingPortfolioAssignment.End_Date__c < BSF_constants.CURRENT_DATE)
                                {
                                    Continue;
                                }
                                //HRP-13270
                                    existingPortfolioAssignment.User__c = updatedOrDeletedPortfolio.User__c;
                                    existingPortfolioAssignment.Start_Date__c = updatedOrDeletedPortfolio.Start_Date__c;
                                    existingPortfolioAssignment.End_Date__c = updatedOrDeletedPortfolio.End_Date__c;
                                    existingPortfolioAssignment.Assignment_Type__c = updatedOrDeletedPortfolio.Assignment_Type__c;
                                    listOfPortAssrecordsToUpdate.add(existingPortfolioAssignment);
                                }
                            }//for loop end
                        }
                    }
                    if(!listOfPortAssrecordsToInsert.isEmpty()){
                        system.debug('listOfPortAssrecordsToInsert '+listOfPortAssrecordsToInsert);
                        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.insert(listOfPortAssrecordsToInsert,false), 'Manage other taxoPortfolio','PortfolioAssignmentService','manageUserAssignemntForPortfolioInOtherTaxo','Error','Inserting other Taxo portfolio assignment');//HRP-11035 added BSF_Error_Log__c
                        InsertBsfErrorLog.insertBsfErrors(logList);//HRP-11035 added BSF_Error_Log__c
                    }
                    if(!listTodeletePfa.isEmpty()){
                        system.debug('listTodeletePfa '+listTodeletePfa);
                        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.delete(listTodeletePfa,false), 'Manage other taxoPortfolio','PortfolioAssignmentService','manageUserAssignemntForPortfolioInOtherTaxo','Error','deleting other Taxo portfolio assignment');//HRP-11035 added BSF_Error_Log__c
                        InsertBsfErrorLog.insertBsfErrors(logList);//HRP-11035 added BSF_Error_Log__c
                    }
                    if(!listOfPortAssrecordsToUpdate.isEmpty()){
                        system.debug('listOfPortAssrecordsToUpdate '+listOfPortAssrecordsToUpdate);
                        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.update(listOfPortAssrecordsToUpdate,false), 'Manage other taxoPortfolio','PortfolioAssignmentService','manageUserAssignemntForPortfolioInOtherTaxo','Error','updating other Taxo portfolio assignment');//HRP-11035 added BSF_Error_Log__c
                        InsertBsfErrorLog.insertBsfErrors(logList);//HRP-11035 added BSF_Error_Log__c
                    }
                }
            }
        }
    }
    public static void publishPlarformEventsOnAfterInsert(List<Portfolio_Assignment__c> newPortfolioAssignmentList,Map<Id,Portfolio_Assignment__c> oldMap){
        set<id> bsfIdSet = new set<id>();
        List<PortfolioAssignmentEvent__e> publishEvents = new List<PortfolioAssignmentEvent__e>();
        //HRP-11290 start
        for(Portfolio_Assignment__c portFolAssRecord:newPortfolioAssignmentList)
        {
            if(oldMap==null ||(oldMap!=null && OldMap.get(portFolAssRecord.id)!=null && (OldMap.get(portFolAssRecord.id).start_Date__c!= portFolAssRecord.start_Date__c || OldMap.get(portFolAssRecord.id).End_Date__c!= portFolAssRecord.End_Date__c)))
                bsfIdSet.add(portFolAssRecord.bsf_portfolio__c);
        }
        List<BSF_Portfolio__c> portfolioLinkedtoAccount1 = [Select Id,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN :bsfIdSet ];
        System.debug('portfolioLinkedtoAccount1 '+portfolioLinkedtoAccount1.size());
        for(BSF_Portfolio__c port1:portfolioLinkedtoAccount1)
        {
            bsfIdSet.add(port1.Id);
        }
        List<BSF_Portfolio__c> portfolioLinkedtoAccount2 = [Select Id,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN :bsfIdSet ];
        System.debug('portfolioLinkedtoAccount2 '+portfolioLinkedtoAccount2.size());
        for(BSF_Portfolio__c port1:portfolioLinkedtoAccount2)
        {
            bsfIdSet.add(port1.Id);
        }
        List<Account_Portfolio_Assignment__c> accPortfolioList =[SELECT Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c,BSF_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:bsfIdSet ];
        for(Account_Portfolio_Assignment__c apa:accPortfolioList)
        {
            PortfolioAssignmentEvent__e eve = new PortfolioAssignmentEvent__e();
            eve.id__c = apa.account__c ;
            eve.Object_Name__c = 'Account';
            if(oldMap==null && !trigger.isDelete)
                eve.Operation__c = 'Insert';
            publishEvents.add(eve);
            //insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='PortfolioAssignmentService',Method__c='For',Type__c='Success',Error_Description__c='Acc ID '+apa.account__c);
        }
        if(publishEvents.size()>0){
            System.debug('Enter in publishPlarformEventsOnAfterInsert before Here====='+publishEvents.size());
            //InsertBsfErrorLog.insertBsfErrors(logList);
            insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='PortfolioAssignmentService',Method__c='publishPlarformEventsOnAfterInsert',Type__c='Success',Error_Description__c='PE Size '+String.valueOf(publishEvents.size()));
            //HRP-13028  start
            if(Limits.getLimitDMLRows()-Limits.getDMLRows()>=publishEvents.size())
            {
                system.debug('publishEvents');
                EventBus.publish(publishEvents);
            }
            else
            {
                System.enqueueJob(new AccTeamUpdatePortfolioAssignQueue(publishEvents));
            }
            //HRP-13028 end
        }
        //HRP-11290 End
        //commented part of HRP-11290
        /*for(Portfolio_Assignment__c portFolAssRecord:newPortfolioAssignmentList){
PortfolioAssignmentEvent__e eve = new PortfolioAssignmentEvent__e();
eve.PortfolioAssignmentId__c = portFolAssRecord.Id ;
publishEvents.add(eve);
insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='PortfolioAssignmentService',Method__c='For',Type__c='Success',Error_Description__c='PE ID '+portFolAssRecord.Id);
}
if(publishEvents.size()>0){
System.debug('Enter in publishPlarformEventsOnAfterInsert before Here====='+publishEvents.size());
//InsertBsfErrorLog.insertBsfErrors(logList);
insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='PortfolioAssignmentService',Method__c='publishPlarformEventsOnAfterInsert',Type__c='Success',Error_Description__c='PE Size '+String.valueOf(publishEvents.size()));
EventBus.publish(publishEvents);
}*/
        //commented part of HRP-11290
    }
    /*public static void createAccountTeamMembers(List<Portfolio_Assignment__c> newPortfolioAssignmentList){
BSF_Constants.isTeamMemberCreatedFromBackend = true;
List<BSF_Portfolio__c> abmPortfoliosToPass = new List<BSF_Portfolio__c>();
List<BSF_Portfolio__c> supervisorPortfoliosToPass = new List<BSF_Portfolio__c>();
List<BSF_Portfolio__c> dmPortfoliosToPass = new List<BSF_Portfolio__c>();
List<BSF_Portfolio__c> singleLevelPortfoliosToPass = new List<BSF_Portfolio__c>();
Set<Id> portfolioAssignmentIdSet = new Set<Id>();
//Boolean values for accteam Presence
boolean createAMandDM = false;
boolean createAccountTeamMembers = false;
boolean createABMRecords = false;
boolean createDMRecords = false;
boolean createSingleLevelPortfolioRecords = false;
Map<Id,Portfolio_Assignment__c> portfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c portfolioAssignment:newPortfolioAssignmentList){
portfolioAssignmentIdSet.add(portfolioAssignment.BSF_Portfolio__c);
portfolioUserMap.put(portfolioAssignment.BSF_Portfolio__c,portfolioAssignment);
}
List<BSF_Portfolio__c> portfolioList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c,Taxonomy_Type__c FROM BSF_Portfolio__c WHERE Id IN:portfolioAssignmentIdSet];
Set<Id> amPortfolioId = new Set<Id>();
Set<Id> parentPortfolioIdOfAM = new Set<Id>();
List<BSF_Portfolio__c> amPortfolioList = new List<BSF_Portfolio__c>();
Map<Id,BSF_Portfolio__c> portfolioIdMap = new Map<Id,BSF_Portfolio__c>();
//Map<Id,List<BSF_Portfolio__c>> parentPortfolioMap = new Map<Id,List<BSF_Portfolio__c>>();
for(BSF_Portfolio__c portfolio:portfolioList){
if(portfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER || portfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_PORTFOLIO){
if(portfolio.Taxonomy_Type__c != BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
amPortfolioList.add(portfolio);
amPortfolioId.add(portfolio.Id);
portfolioIdMap.put(portfolio.Id,portfolio);
parentPortfolioIdOfAM.add(portfolio.Parent_Portfolio__c);
}
}
if(portfolio.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER || portfolio.Portfolio_Type__c == BSF_Constants.SUPERVISOR){
//call a separate method to handle ABM on the Account Team of the related Accounts
abmPortfoliosToPass.add(portfolio);
}
/*---if(portfolio.Portfolio_Type__c == BSF_Constants.SUPERVISOR){
//call a separate method to handle Supervisor insertion on the Account Team of the related Accounts
supervisorPortfoliosToPass.add(portfolio);
}---
if(portfolio.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER){
//call a separate method to handle DM insertion on the Account Team of the related Accounts
if(portfolio.Taxonomy_Type__c != BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
dmPortfoliosToPass.add(portfolio);
}
}
// Account Specialist checking has been added as part of 3807
if(portfolio.Portfolio_Type__c == BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER || portfolio.Portfolio_Type__c == BSF_Constants.NATIONAL_ACCOUNT_MANAGER || portfolio.Portfolio_Type__c == BSF_Constants.Booking_Support ||  portfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_SPECIALIST){
singleLevelPortfoliosToPass.add(portfolio);
}
}
List<BSF_Portfolio__c> parentPortfolioOfAMList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:parentPortfolioIdOfAM];
List<Portfolio_Assignment__c> createAMAndDMList = new List<Portfolio_Assignment__c>();
Set<Id> amPortfolioIdSetWithABMOrDM = new Set<Id>();
Set<Id> abmPortfolioId = new Set<Id>();
List<BSF_Portfolio__c> AMPortfolioWithABMList = new List<BSF_Portfolio__c>();
for(BSF_Portfolio__c ParentPortfolio:parentPortfolioOfAMList){
if(ParentPortfolio.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER || ParentPortfolio.Portfolio_Type__c == BSF_Constants.SUPERVISOR){
abmPortfolioId.add(ParentPortfolio.Id);
for(BSF_Portfolio__c childPortfolio:portfolioList){
if(childPortfolio.Parent_Portfolio__c == ParentPortfolio.Id){
amPortfolioIdSetWithABMOrDM.add(childPortfolio.Id);
AMPortfolioWithABMList.add(childPortfolio);
}
}
}
else if(ParentPortfolio.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER){
for(BSF_Portfolio__c childPortfolio:portfolioList){
if(childPortfolio.Parent_Portfolio__c == ParentPortfolio.Id){
createAMAndDMList.add(portfolioUserMap.get(childPortfolio.Id));
}
}
}
}
if(createAMAndDMList.size()>0){
createAMandDM=PortfolioAssignmentService.createAMandDM(createAMAndDMList);
}
if(abmPortfolioId.size()>0){
List<BSF_Portfolio__c> ABMPortfolioList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:abmPortfolioId];
Map<Id,Id> AmToABMMap = new Map<Id,Id>();
if(AMPortfolioWithABMList.size()>0){
for(BSF_Portfolio__c portfolio:AMPortfolioWithABMList){
AmToABMMap.put(portfolio.Id, portfolio.Parent_Portfolio__c);
}
}
Map<Id,Id> ABMToDMMap = new Map<Id,Id>();
Set<Id> dmPortfolioId = new Set<Id>();
if(ABMPortfolioList.size()>0){
for(BSF_Portfolio__c portfolio:ABMPortfolioList){
dmPortfolioId.add(portfolio.Parent_Portfolio__c);
ABMToDMMap.put(portfolio.Id, portfolio.Parent_Portfolio__c);
}
}
System.debug('ABMToDMMap: '+ABMToDMMap);
List<Portfolio_Assignment__c> ABMUserList = [SELECT Id,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:abmPortfolioId AND End_Date__c > TODAY];
Map<Id,Portfolio_Assignment__c> portfolioABMMap = new Map<Id,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c ABMPortfolio:ABMUserList){
portfolioABMMap.put(ABMPortfolio.BSF_Portfolio__c,ABMPortfolio);
}
List<Portfolio_Assignment__c> DMUserList = [SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:dmPortfolioId AND End_Date__c > TODAY];
Map<Id,Portfolio_Assignment__c> portfolioDMMap = new Map<Id,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c DMPortfolio:DMUserList){
portfolioDMMap.put(DMPortfolio.BSF_Portfolio__c,DMPortfolio);
}
System.debug('portfolioDMMap: '+portfolioDMMap);
List<Account_Portfolio_Assignment__c> accountPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:amPortfolioIdSetWithABMOrDM AND End_Date__c > TODAY];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
accIdBsfIDAccPortfolioMap.put(accountPortfolio.Account__c+'_'+accountPortfolio.BSF_Portfolio__c, accountPortfolio);
}
List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
if(portfolioUserMap.containsKey(portfolioId)){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = portfolioUserMap.get(portfolioId);
AccountTeamMember AMteamMember = new AccountTeamMember();
AMteamMember.AccountId = accId;
AMteamMember.UserId = portfolioUserMap.get(portfolioId).User__c;
AMteamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
AMteamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
AMteamMember.AccountAccessLevel = 'Edit';
AMteamMember.CaseAccessLevel = 'Edit';
AMteamMember.OpportunityAccessLevel = 'Edit';
AMteamMember.TeamMemberRole = portfolioIdMap.get(portfolioId).Portfolio_Type__c;
AMteamMember.BSF_Portfolio__c = portfolioId;
teamMemberList.add(AMteamMember);
}
if(portfolioABMMap.containsKey(AmToABMMap.get(portfolioId))){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = portfolioABMMap.get(AmToABMMap.get(portfolioId));
AccountTeamMember ABMTeamMember = new AccountTeamMember();
ABMTeamMember.AccountId = accId;
ABMTeamMember.UserId = portfolioABMMap.get(AmToABMMap.get(portfolioId)).User__c;
ABMTeamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
ABMTeamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
ABMTeamMember.AccountAccessLevel = 'Edit';
ABMTeamMember.CaseAccessLevel = 'Edit';
ABMTeamMember.OpportunityAccessLevel = 'Edit';
if(portfolioABMMap.get(AmToABMMap.get(portfolioId)).BSF_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase(BSF_Constants.AREA_BOOKING_MANAGER)){
ABMTeamMember.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
}
else if(portfolioABMMap.get(AmToABMMap.get(portfolioId)).BSF_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase(BSF_Constants.SUPERVISOR)){
ABMTeamMember.TeamMemberRole = BSF_Constants.SUPERVISOR;  //Added SUPERVISOR as part of HRP-4622
}
ABMTeamMember.BSF_Portfolio__c = AmToABMMap.get(portfolioId);
teamMemberList.add(ABMTeamMember);
}
System.debug('Portfolio Id: '+portfolioId);
if(portfolioDMMap.containsKey(ABMToDMMap.get(AmToABMMap.get(portfolioId)))){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = portfolioDMMap.get(ABMToDMMap.get(AmToABMMap.get(portfolioId)));
SYstem.debug('inside DM Team Member creation');
AccountTeamMember DMteamMember = new AccountTeamMember();
DMteamMember.AccountId = accId;
DMteamMember.UserId = portfolioDMMap.get(ABMToDMMap.get(AmToABMMap.get(portfolioId))).User__c;
DMteamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
DMteamMember.End_Date__c =  portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
DMteamMember.AccountAccessLevel = 'Edit';
DMteamMember.CaseAccessLevel = 'Edit';
DMteamMember.OpportunityAccessLevel = 'Edit';
DMteamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
DMteamMember.BSF_Portfolio__c = ABMToDMMap.get(AmToABMMap.get(portfolioId));
teamMemberList.add(DMteamMember);
}
}
}
if(teamMemberList.size()>0){
try{
System.debug('teamMemberList size: '+teamMemberList.size());
System.debug('AccountTeamMember List: '+teamMemberList);
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.upsert(teamMemberList,false), 'Create Portfolio','PortfolioAssignmentService','createAccountTeamMembers','Error','Error in updating DM with ABM');
InsertBsfErrorLog.insertBsfErrors(logList);
createAccountTeamMembers=true;
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
}
}
if(abmPortfoliosToPass.size()>0){
createABMRecords=PortfolioAssignmentService.createABMRecords(abmPortfoliosToPass);
}
---if(supervisorPortfoliosToPass.size()>0){
PortfolioAssignmentService.createSupervisorRecords(supervisorPortfoliosToPass);
}---
if(dmPortfoliosToPass.size()>0){
createDMRecords=PortfolioAssignmentService.createDMRecords(dmPortfoliosToPass);
}
if(singleLevelPortfoliosToPass.size()>0){
createSingleLevelPortfolioRecords=PortfolioAssignmentService.createSingleLevelPortfolioRecords(singleLevelPortfoliosToPass);
}
if(!(createAMandDM || createAccountTeamMembers || createABMRecords || createDMRecords || createSingleLevelPortfolioRecords))
{
List<Portfolio_Accounts_Processing__c> pt = [Select Id, Portfolio_progress_for_Accounts__c, Records_Processed__c, Portfolio_Assignment_Updated__c From Portfolio_Accounts_Processing__c LIMIT 1];
if (pt.size() > 0 && pt[0].Portfolio_Assignment_Updated__c)
{
pt[0].Portfolio_Assignment_Updated__c=false;
}
update pt;
}
}
public static Boolean createABMRecords(List<BSF_Portfolio__c> abmPortfolioRecords){
Set<Id> abmPortfolioIdSet = new Set<Id>();
Map<Id,Portfolio_Assignment__c> abmPortfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
for(BSF_Portfolio__c abmPortfolio:abmPortfolioRecords){
if(abmPortfolio.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER || abmPortfolio.Portfolio_Type__c == BSF_Constants.SUPERVISOR){ //Added SUPERVISOR as part of HRP-4622
abmPortfolioIdSet.add(abmPortfolio.Id);
}
}
List<Portfolio_Assignment__c> abmPortfolioUserList =[SELECT Id,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:abmPortfolioIdSet AND End_Date__c > TODAY];
for(Portfolio_Assignment__c abmPortfolioUser:abmPortfolioUserList){
abmPortfolioUserMap.put(abmPortfolioUser.BSF_Portfolio__c,abmPortfolioUser);
}
List<BSF_Portfolio__c> amPortfolioList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN:abmPortfolioIdSet AND Portfolio_Type__c ='Account Manager'];
Set<Id> amPortfolioIdSet = new Set<Id>();
Map<Id,Id> AMToABMMap = new Map<Id,Id>();
for(BSF_Portfolio__c amPortfolio:amPortfolioList){
amPortfolioIdSet.add(amPortfolio.Id);
AMToABMMap.put(amPortfolio.Id,amPortfolio.Parent_Portfolio__c);
}
List<Account_Portfolio_Assignment__c> accountAMPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:amPortfolioIdSet AND End_Date__c > TODAY];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountAMPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
accIdBsfIDAccPortfolioMap.put(accountPortfolio.Account__c+'_'+accountPortfolio.BSF_Portfolio__c, accountPortfolio);
}
List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
if(abmPortfolioUserMap.containsKey(AMToABMMap.get(portfolioId))){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = abmPortfolioUserMap.get(AMToABMMap.get(portfolioId));
AccountTeamMember ABMTeamMember = new AccountTeamMember();
ABMTeamMember.AccountId = accId;
ABMTeamMember.UserId = abmPortfolioUserMap.get(AMToABMMap.get(portfolioId)).User__c;
ABMTeamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
ABMTeamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
ABMTeamMember.AccountAccessLevel = 'Edit';
ABMTeamMember.CaseAccessLevel = 'Edit';
ABMTeamMember.OpportunityAccessLevel = 'Edit';
if(abmPortfolioUserMap.get(AMToABMMap.get(portfolioId)).BSF_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase(BSF_Constants.AREA_BOOKING_MANAGER))
{
ABMTeamMember.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
}
else if(abmPortfolioUserMap.get(AMToABMMap.get(portfolioId)).BSF_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase(BSF_Constants.SUPERVISOR))
{
ABMTeamMember.TeamMemberRole = BSF_Constants.SUPERVISOR;
}
ABMTeamMember.BSF_Portfolio__c = AMToABMMap.get(portfolioId);
teamMemberList.add(ABMTeamMember);
}
}
}
if(teamMemberList.size()>0){
try{
System.debug('teamMemberList size: '+teamMemberList.size());
System.debug('AccountTeamMember List: '+teamMemberList);
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.upsert(teamMemberList,false), 'Create Portfolio','PortfolioAssignmentService','createABMRecords','Error','Error in upserting ABM');
InsertBsfErrorLog.insertBsfErrors(logList);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
return true;
}
else
{
return false;
}
}*/
    /*public static void createSupervisorRecords(List<BSF_Portfolio__c> supervisorPortfolioRecords){
Set<Id> supervisorPortfolioIdSet = new Set<Id>();
Map<Id,Portfolio_Assignment__c> supervisorPortfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
for(BSF_Portfolio__c supervisorPortfolio:supervisorPortfolioRecords){
if(supervisorPortfolio.Portfolio_Type__c == BSF_Constants.SUPERVISOR){ //Added SUPERVISOR as part of HRP-4622
supervisorPortfolioIdSet.add(supervisorPortfolio.Id);
}
}
List<Portfolio_Assignment__c> supervisorPortfolioUserList =[SELECT Id,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:supervisorPortfolioIdSet AND End_Date__c > TODAY];
for(Portfolio_Assignment__c supervisorPortfolioUser:supervisorPortfolioUserList){
supervisorPortfolioUserMap.put(supervisorPortfolioUser.BSF_Portfolio__c,supervisorPortfolioUser);
}
List<BSF_Portfolio__c> amPortfolioList = [SELECT Id,Portfolio_Type__c,Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN:supervisorPortfolioIdSet AND Portfolio_Type__c ='Account Manager'];
Set<Id> amPortfolioIdSet = new Set<Id>();
Map<String,Id> amPortfolioCodeSupervisorIdMap = new Map<String,Id>();
for(BSF_Portfolio__c amPortfolio:amPortfolioList){
amPortfolioCodeSupervisorIdMap.put(amPortfolio.Portfolio_Code__c,amPortfolio.Parent_Portfolio__c);
}
List<Account_Portfolio_Assignment__c> accountAMPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Portfolio_Name__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__r.Portfolio_Code__c IN:amPortfolioCodeSupervisorIdMap.keySet() AND End_Date__c > TODAY];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
Map<Id,String> portfolioIdCodeMap = new Map<Id,String>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountAMPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
portfolioIdCodeMap.put(accountPortfolio.BSF_Portfolio__c,accountPortfolio.BSF_Portfolio__r.Portfolio_Code__c);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
portfolioIdCodeMap.put(accountPortfolio.BSF_Portfolio__c,accountPortfolio.BSF_Portfolio__r.Portfolio_Code__c);
}
}
List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
if(amPortfolioCodeSupervisorIdMap.containsKey(portfolioIdCodeMap.get(portfolioId))){
AccountTeamMember SupervisorTeamMember = new AccountTeamMember();
SupervisorTeamMember.AccountId = accId;
SupervisorTeamMember.UserId = supervisorPortfolioUserMap.get(amPortfolioCodeSupervisorIdMap.get(portfolioIdCodeMap.get(portfolioId))).User__c;
SupervisorTeamMember.BSF_Portfolio__c = amPortfolioCodeSupervisorIdMap.get(portfolioIdCodeMap.get(portfolioId));
SupervisorTeamMember.Start_Date__c = supervisorPortfolioUserMap.get(amPortfolioCodeSupervisorIdMap.get(portfolioIdCodeMap.get(portfolioId))).Start_Date__c;
SupervisorTeamMember.End_Date__c = supervisorPortfolioUserMap.get(amPortfolioCodeSupervisorIdMap.get(portfolioIdCodeMap.get(portfolioId))).End_Date__c;
SupervisorTeamMember.AccountAccessLevel = 'Edit';
SupervisorTeamMember.CaseAccessLevel = 'Edit';
SupervisorTeamMember.OpportunityAccessLevel = 'Edit';
SupervisorTeamMember.TeamMemberRole = BSF_Constants.SUPERVISOR;
teamMemberList.add(SupervisorTeamMember);
}
}
}
if(teamMemberList.size()>0){
try{
System.debug('teamMemberList size: '+teamMemberList.size());
System.debug('AccountTeamMember List: '+teamMemberList);
Database.upsert(teamMemberList);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
}
}*/
    /*public static Boolean createDMRecords(List<BSF_Portfolio__c> dmPortfolioRecords){
List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
Set<Id> dmPortfolioIdSet = new Set<Id>();
Map<Id,Portfolio_Assignment__c> dmPortfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
for(BSF_Portfolio__c dmPortfolio:dmPortfolioRecords){
if(dmPortfolio.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER){
dmPortfolioIdSet.add(dmPortfolio.Id);
}
}
List<Portfolio_Assignment__c> dmPortfolioUserList =[SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:dmPortfolioIdSet AND End_Date__c > TODAY ];
for(Portfolio_Assignment__c dmPortfolioUser:dmPortfolioUserList){
dmPortfolioUserMap.put(dmPortfolioUser.BSF_Portfolio__c,dmPortfolioUser);
}
List<BSF_Portfolio__c> abmPortfolios = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN:dmPortfolioIdSet];
Set<Id> abmPortfolioIdSet = new Set<Id>();
Set<Id> amPortfolioIdSet = new Set<Id>();
Map<Id,Id> ABMToDMMap = new Map<Id,Id>();
for(BSF_Portfolio__c abmPortfolio:abmPortfolios){
if(abmPortfolio.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER){ //Added SUPERVISOR as part of HRP-4622
abmPortfolioIdSet.add(abmPortfolio.Id);
ABMToDMMap.put(abmPortfolio.Id,abmPortfolio.Parent_Portfolio__c);
}
else if(abmPortfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER){
amPortfolioIdSet.add(abmPortfolio.Id);
}
}
//For the ABM or SUPERVISOR Portfolios, which reports to DM and AM reports to ABM/SUPERVISOR
if(abmPortfolioIdSet.size()>0){
List<BSF_Portfolio__c> amPortfolioList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN:abmPortfolioIdSet ];
Set<Id> amPortfolioIds = new Set<Id>();
Map<Id,Id> AMToABMMap = new Map<Id,Id>();
for(BSF_Portfolio__c amPortfolio:amPortfolioList){
amPortfolioIds.add(amPortfolio.Id);
AMToABMMap.put(amPortfolio.Id,amPortfolio.Parent_Portfolio__c);
}
List<Account_Portfolio_Assignment__c> accountAMPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:amPortfolioIds AND End_Date__c > TODAY ];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountAMPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
accIdBsfIDAccPortfolioMap.put(accountPortfolio.Account__c+'_'+accountPortfolio.BSF_Portfolio__c, accountPortfolio);
}
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
if(dmPortfolioUserMap.containsKey(ABMToDMMap.get(AMToABMMap.get(portfolioId)))){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = dmPortfolioUserMap.get(ABMToDMMap.get(AMToABMMap.get(portfolioId)));
AccountTeamMember DMTeamMember = new AccountTeamMember();
DMTeamMember.AccountId = accId;
DMTeamMember.UserId = dmPortfolioUserMap.get(ABMToDMMap.get(AMToABMMap.get(portfolioId))).User__c;
DMTeamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
DMTeamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
DMTeamMember.AccountAccessLevel = 'Edit';
DMTeamMember.CaseAccessLevel = 'Edit';
DMTeamMember.OpportunityAccessLevel = 'Edit';
DMTeamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
DMTeamMember.BSF_Portfolio__c = ABMToDMMap.get(AMToABMMap.get(portfolioId));
teamMemberList.add(DMTeamMember);
}
}
}
}
//For the AM Portfolios which does not report to ABM Portfolio but directly reports to DM Portfolio
if(amPortfolioIdSet.size()>0){
List<BSF_Portfolio__c> amPortfolioList = [SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN:dmPortfolioIdSet ];
Set<Id> amPortfolioIds = new Set<Id>();
Map<Id,Id> AMToDMMap = new Map<Id,Id>();
for(BSF_Portfolio__c amPortfolio:amPortfolioList){
amPortfolioIds.add(amPortfolio.Id);
AMToDMMap.put(amPortfolio.Id,amPortfolio.Parent_Portfolio__c);
}
List<Account_Portfolio_Assignment__c> accountAMPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:amPortfolioIds AND End_Date__c > TODAY ];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountAMPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
accIdBsfIDAccPortfolioMap.put(accountPortfolio.Account__c+'_'+accountPortfolio.BSF_Portfolio__c, accountPortfolio);
}
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
if(dmPortfolioUserMap.containsKey(AMToDMMap.get(portfolioId))){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign = dmPortfolioUserMap.get(AMToDMMap.get(portfolioId));
AccountTeamMember DMTeamMember = new AccountTeamMember();
DMTeamMember.AccountId = accId;
DMTeamMember.UserId = dmPortfolioUserMap.get(AMToDMMap.get(portfolioId)).User__c;
DMTeamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
DMTeamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
DMTeamMember.AccountAccessLevel = 'Edit';
DMTeamMember.CaseAccessLevel = 'Edit';
DMTeamMember.OpportunityAccessLevel = 'Edit';
DMTeamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
DMTeamMember.BSF_Portfolio__c = AMToDMMap.get(portfolioId);
teamMemberList.add(DMTeamMember);
}
}
}
}
if(teamMemberList.size()>0){
try{
System.debug('teamMemberList size: '+teamMemberList.size());
System.debug('AccountTeamMember List: '+teamMemberList);
List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
if(teamMemberList.size()<100)
{
Database.UpsertResult[] atmResult=Database.upsert(teamMemberList);//dml for security
for(Database.upsertResult result:atmResult)
{
if(!result.isSuccess())
{
system.debug('ID: '+result.getId()+'  ERROR: '+result.getErrors()+'   CREATED: '+ result.isCreated());
}
}
logList = BSF_Utilities.createErrorLog(atmResult, 'Create Portfolio','PortfolioAssignmentService','createDMRecords','Error','Error in upserting DM ');
InsertBsfErrorLog.insertBsfErrors(logList);
}
else
{
List<AccTeamFromPortfolioAssignmentService__e> accTeamEveList = new List<AccTeamFromPortfolioAssignmentService__e>();
integer i=0;
for(AccountTeamMember atm :teamMemberList)
{
AccTeamFromPortfolioAssignmentService__e accTeamEve = new AccTeamFromPortfolioAssignmentService__e();
accTeamEve.UserId__c=atm.UserId;
accTeamEve.AccountId__c=atm.AccountId;
accTeamEve.BSF_Portfolio__c=atm.BSF_Portfolio__c;
accTeamEve.Start_Date__c=atm.Start_Date__c;
accTeamEve.End_Date__c=atm.End_Date__c;
accTeamEve.AccountAccessLevel__c=atm.AccountAccessLevel;
accTeamEve.CaseAccessLevel__c=atm.CaseAccessLevel;
accTeamEve.OpportunityAccessLevel__c=atm.OpportunityAccessLevel;
accTeamEve.TeamMemberRole__c=atm.TeamMemberRole;
accTeamEveList.add(accTeamEve);
//BSF_Error_Log__c log = BSF_Utilities.getErrorLog('Create Portfolio', 'PortfolioAssignmentService', 'createDMRecords', 'Debug Log','No Error - Platform Event log', 'AtmID: '+ string.valueof(atm.Userid)+' '+ 'BSFId: '+ string.valueof(atm.BSF_Portfolio__c));
//logList.add(log);
if(accTeamEveList.size()==100)
{
System.debug('Enter in publishPlarformEventsOnAfterInsert before Here====='+accTeamEveList.size());
//InsertBsfErrorLog.insertBsfErrors(logList);
EventBus.publish(accTeamEveList);
accTeamEveList.clear();
logList.clear();
}
}
if(!accTeamEveList.isEmpty())
{
System.debug('Enter in publishPlarformEventsOnAfterInsert before Here====='+accTeamEveList.size());
//InsertBsfErrorLog.insertBsfErrors(logList);
EventBus.publish(accTeamEveList);
}
}
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
return true;
}
else
{
return false;
}
}
public static boolean createSingleLevelPortfolioRecords(List<BSF_Portfolio__c> singleLevelPortfoliosRecords){
Set<Id> portfolioIdSet = new Set<Id>();
Map<Id,BSF_Portfolio__c> portfolioIdMap = new Map<Id,BSF_Portfolio__c>();
for(BSF_Portfolio__c portfolio:singleLevelPortfoliosRecords){
portfolioIdMap.put(portfolio.Id,portfolio);
}
List<Portfolio_Assignment__c> portfolioUserList = [SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:portfolioIdMap.keySet() AND End_Date__c > TODAY ];
Map<Id,Portfolio_Assignment__c> portfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c portfolioUser: portfolioUserList) {
portfolioUserMap.put(portfolioUser.BSF_Portfolio__c,portfolioUser);
}
List<Account_Portfolio_Assignment__c> accountPortfolioList = [SELECT Id,Start_Date__c,End_Date__c,Account__c,BSF_Portfolio__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:portfolioIdMap.keySet() AND End_Date__c > TODAY ];
Map<Id,List<Id>> portfolioAccMap = new Map<Id,List<Id>>();
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accountPortfolio:accountPortfolioList){
if(!portfolioAccMap.containsKey(accountPortfolio.BSF_Portfolio__c)){
List<Id> accIdList = new List<Id>();
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
else{
List<Id> accIdList = portfolioAccMap.get(accountPortfolio.BSF_Portfolio__c);
accIdList.add(accountPortfolio.Account__c);
portfolioAccMap.put(accountPortfolio.BSF_Portfolio__c,accIdList);
}
accIdBsfIDAccPortfolioMap.put(accountPortfolio.Account__c+'_'+accountPortfolio.BSF_Portfolio__c, accountPortfolio);
}
List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
Set<Id> accIdSet = new Set<Id>();
for(Id portfolioId:portfolioAccMap.keySet()){
accIdSet.addAll(portfolioAccMap.get(portfolioId));
List<Id> accIdList = portfolioAccMap.get(portfolioId);
for(Id accId:accIdList){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(accId+'_'+portfolioId);
Portfolio_Assignment__c portfolioAssign =portfolioUserMap.get(portfolioId);
AccountTeamMember teamMember = new AccountTeamMember();
teamMember.AccountId = accId;
teamMember.UserId = portfolioUserMap.get(portfolioId).User__c;
teamMember.Start_Date__c = portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
teamMember.End_Date__c = portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
teamMember.AccountAccessLevel = 'Edit';
teamMember.CaseAccessLevel = 'Edit';
teamMember.OpportunityAccessLevel = 'Edit';
teamMember.TeamMemberRole = portfolioIdMap.get(portfolioId).Portfolio_Type__c;
teamMember.BSF_Portfolio__c = portfolioId;
teamMemberList.add(teamMember);
}
}
if(teamMemberList.size()>0){
try{
System.debug('teamMemberList size: '+teamMemberList.size());
System.debug('AccountTeamMember List: '+teamMemberList);
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.upsert(teamMemberList,false), 'Create Portfolio','PortfolioAssignmentService','createSingleLevelPortfolioRecords','Error','Error in upserting singleLevel portfolio user accTeam ');
InsertBsfErrorLog.insertBsfErrors(logList);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
return true;
}
else
{
return false;
}
}
public static void updateEndDateOfAccountTeamMembers(Map<Id,Portfolio_Assignment__c> newMap,Map<Id,Portfolio_Assignment__c> oldMap){
List<Id> portfolioIdList = new List<Id>();
Set<String> assignmentType= new Set<String>();
List<AccountTeamMember> teamMemberListToUpdate = new List<AccountTeamMember>();
List<PortfolioAssignmentUpdateEvent__e> publishEvents = new List<PortfolioAssignmentUpdateEvent__e>();
List<PortfolioAssignmentDeleteEvent__e> publishEventsDelete=new List<PortfolioAssignmentDeleteEvent__e>();//HRP-8897
for(Portfolio_Assignment__c portfolioAssignment: newMap.values()){
if(newMap.get(portfolioAssignment.id).Start_Date__c != oldMap.get(portfolioAssignment.id).Start_Date__c
|| newMap.get(portfolioAssignment.id).End_Date__c != oldMap.get(portfolioAssignment.id).End_Date__c)
{
portfolioIdList.add(portfolioAssignment.BSF_Portfolio__c);
assignmentType.add(portfolioAssignment.Assignment_Type__c);
}
}
List<BSF_Portfolio__c> portfolioLinkedtoAccount1 = [Select Id,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN :portfolioIdList ];
System.debug('portfolioLinkedtoAccount1 '+portfolioLinkedtoAccount1.size());
for(BSF_Portfolio__c port1:portfolioLinkedtoAccount1){
portfolioIdList.add(port1.Id);
}
List<BSF_Portfolio__c> portfolioLinkedtoAccount2 = [Select Id,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Parent_Portfolio__c IN :portfolioLinkedtoAccount1 ];
System.debug('portfolioLinkedtoAccount2 '+portfolioLinkedtoAccount2.size());
for(BSF_Portfolio__c port1:portfolioLinkedtoAccount2){
portfolioIdList.add(port1.Id);
}
List<Account_Portfolio_Assignment__c> accPortfolioList =[SELECT Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c,BSF_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:portfolioIdList ];
map<string,Account_Portfolio_Assignment__c> accIdBsfIDAccPortfolioMap= new map<string,Account_Portfolio_Assignment__c>();
map<string,AccountTeamMember> accTeamMap= new map<string,AccountTeamMember>();//HRP-8897
map<string,AccountTeamMember> accIdUserDate = new map<string,AccountTeamMember> ();
if(accPortfolioList.size()>0){
List<Id> accountIdList = new List<Id>();
for(Account_Portfolio_Assignment__c accPortfolio:accPortfolioList){
accountIdList.add(accPortfolio.Account__c);
accIdBsfIDAccPortfolioMap.put(accPortfolio.Account__c+'_'+accPortfolio.BSF_Portfolio__c, accPortfolio);
accIdBsfIDAccPortfolioMap.put(accPortfolio.Account__c+'_'+accPortfolio.BSF_Portfolio__r.Parent_Portfolio__c, accPortfolio);
accIdBsfIDAccPortfolioMap.put(accPortfolio.Account__c+'_'+accPortfolio.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c, accPortfolio);
}
List<AccountTeamMember> teamMemberList = [SELECT Id, UserId,AccountId,TeamMemberRole,Is_Covering_Recruiter__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM AccountTeamMember WHERE AccountId IN :accountIdList AND TeamMemberRole IN :assignmentType ];
accIdUserDate=accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accountIdList,bsf_constants.BYPASS_TEAMDML);//HRP-8897
list<string> accTeamRoleList = new list<string>{BSF_constants.ACCOUNT_MANAGER,BSF_constants.AREA_BOOKING_MANAGER,BSF_constants.DISTRICT_MANAGER,BSF_constants.SUPERVISOR};
for(AccountTeamMember teamMember:teamMemberList)
{
accTeamMap.put(teamMember.accountId+'_'+teamMember.UserId,teamMember);
for(Portfolio_Assignment__c portfolioAssignment:oldMap.values()){
if(teamMember.UserId == portfolioAssignment.User__c && teamMember.Is_Covering_Recruiter__c == false && teamMember.BSF_Portfolio__c != null && teamMember.TeamMemberRole == portfolioAssignment.Assignment_Type__c && teamMember.BSF_Portfolio__c== portfolioAssignment.BSF_Portfolio__c){
Account_Portfolio_Assignment__c accPortAssign = accIdBsfIDAccPortfolioMap.get(teamMember.AccountId+'_'+portfolioAssignment.BSF_Portfolio__c);
Portfolio_Assignment__c portfolioAssign = newMap.get(portfolioAssignment.Id);
PortfolioAssignmentUpdateEvent__e eve = new PortfolioAssignmentUpdateEvent__e();
eve.AccountTeamMemberId__c = teamMember.Id ;
if((accTeamRoleList.contains(teamMember.TeamMemberRole) && (accIdUserDate.keyset().contains(teamMember.accountId+'_'+teamMember.UserId))) || (!accTeamRoleList.contains(teamMember.TeamMemberRole)))//HRP-8897 only for AMnode map check
{
if(!accTeamRoleList.contains(teamMember.TeamMemberRole))//HRP-8897
{
if(accPortAssign!=null && portfolioAssign!=null) //HRP-10888 null check
{
eve.StartDate__c=portfolioAssign.Start_Date__c>accPortAssign.Start_Date__c? portfolioAssign.Start_Date__c:accPortAssign.Start_Date__c;
eve.EndDate__c=portfolioAssign.End_Date__c <accPortAssign.End_Date__c? portfolioAssign.End_Date__c:accPortAssign.End_Date__c;
}
}
//HRP-8897
else
{
eve.StartDate__c=accIdUserDate.get(teamMember.accountId+'_'+teamMember.UserId).Start_Date__c;
eve.EndDate__c=accIdUserDate.get(teamMember.accountId+'_'+teamMember.UserId).End_Date__c;
}
publishEvents.add(eve);
}
//HRP-8897
else
{
// if not in accIdUserDate key then candidate for delete
PortfolioAssignmentDeleteEvent__e  eveDelete = new PortfolioAssignmentDeleteEvent__e ();
eveDelete.AccountTeamMemberId__c = teamMember.id ;
publishEventsDelete.add(eveDelete);
}//HRP-8897
}
}
}
}
if(publishEvents.size()>0){
System.debug('Enter in PortfolioAssignmentService :updateEndDateOfAccountTeamMembers====='+publishEvents.size());
//HRP-10793 logic for DML limit check
if(Limits.getLimitDMLRows()-Limits.getDMLRows()>=publishEvents.size())
{
system.debug('publishEvents');
EventBus.publish(publishEvents);
}
else
{
System.enqueueJob(new AccTeamUpdatePortfolioAssignQueue(publishEvents));
}
//HRP-10793
}
//HRP-8897
if(publishEventsDelete.size()>0)
{
System.debug('Enter in PortfolioAssignmentService: deleteAccountTeamMembers from update platform event====='+publishEventsDelete.size());
EventBus.publish(publishEventsDelete);
}
//HRP-8897
--if(teamMemberListToUpdate.size()>0){
try{
System.debug('teamMemberListToUpdate size: '+teamMemberListToUpdate.size());
System.debug('teamMemberListToUpdate List: '+teamMemberListToUpdate);
Database.update(teamMemberListToUpdate);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
}
--
}
public static void updateacctTeammembers(List<AccountTeamMember> listOfAcctTeamMembersToUpdate){
if(!listOfAcctTeamMembersToUpdate.isEmpty()){
BSF_Constants.isTeamMemberCreatedFromBackend = true;
Database.SaveResult[] srList =  Database.update(listOfAcctTeamMembersToUpdate,false);
for (Database.SaveResult sr : srList) {
if (!sr.isSuccess()) {
for(Database.Error err : sr.getErrors()) {
System.debug('The following error has occurred in UpdateAcctTeamMembersBasedOnPortfoliotDatesUpdate Event.');
System.debug(err.getStatusCode() + ': ' + err.getMessage());
System.debug(' fields that affected this error: ' + err.getFields());
}
}
}
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','PortfolioAssignmentService','updateEndDateOfAccountTeamMembers','Error','Error in upserting accTeam enddate');
Database.insert(logList,false);
}
}
public static void deleteAccountTeamMembers(List<Portfolio_Assignment__c> portfolioAssignmentList,Map<Id,Portfolio_Assignment__c> oldPortfolioAssignmentMap){
List<Id> portfolioIdList = new List<Id>();
List<Id> userIdList = new List<Id>();
Map<String,Portfolio_Assignment__c> deletedPortfolioAssignemntMap = new Map<String,Portfolio_Assignment__c>();
List<AccountTeamMember> teamMemberDeleteList = new List<AccountTeamMember>();
List<PortfolioAssignmentDeleteEvent__e> publishEvents=new List<PortfolioAssignmentDeleteEvent__e>();
List<PortfolioAssignmentUpdateEvent__e> publishEventsForAccTeamUpdate=new List<PortfolioAssignmentUpdateEvent__e>();
for(Portfolio_Assignment__c portAssignment:portfolioAssignmentList){
portfolioIdList.add(portAssignment.BSF_Portfolio__c);
userIdList.add(portAssignment.User__c);
deletedPortfolioAssignemntMap.put((portAssignment.BSF_Portfolio__c+''+portAssignment.User__c+''+portAssignment.Assignment_Type__c).toUpperCase(),portAssignment);
}
List<AccountTeamMember> accountTeam = [SELECT Id,UserId,accountid,Start_Date__c,End_Date__c,TeamMemberRole,BSF_Portfolio__c FROM AccountTeamMember WHERE BSF_Portfolio__c IN :portfolioIdList AND UserId IN :userIdList ];
//HRP-8897
list<id> accIdList = new list<id>();
for(AccountTeamMember teamMember:accountTeam)
{
if(!accIdList.contains(teamMember.accountid))
accIdList.add(teamMember.accountid);
}
map<string,AccountTeamMember> accIdUserDate=accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accIdList,bsf_constants.BYPASS_TEAMDML);
//HRP-8897
for(AccountTeamMember teamMember:accountTeam)
{
String key = teamMember.BSF_Portfolio__c+''+teamMember.UserId+''+teamMember.TeamMemberRole;
if(deletedPortfolioAssignemntMap.containsKey(key.toUpperCase()))
{
if(!accIdUserDate.keyset().contains(teamMember.accountId+'_'+teamMember.UserId))//HRP-8897 new check onlyif the key present then accTeam is through another account portfolio assignmnet and can't be deleted
{
PortfolioAssignmentDeleteEvent__e  eve = new PortfolioAssignmentDeleteEvent__e ();
eve.AccountTeamMemberId__c = teamMember.Id ;
publishEvents.add(eve);
}
//HRP-8897
else
{
// the acc team is part of another Accountportfolio assignment. Hence update as per that
PortfolioAssignmentUpdateEvent__e eve = new PortfolioAssignmentUpdateEvent__e();
eve.AccountTeamMemberId__c = teamMember.Id ;
eve.StartDate__c=accIdUserDate.get(teamMember.accountId+'_'+teamMember.UserId).Start_Date__c;
eve.EndDate__c=accIdUserDate.get(teamMember.accountId+'_'+teamMember.UserId).End_Date__c;
publishEventsForAccTeamUpdate.add(eve);
}
//HRP-8897
//teamMemberDeleteList.add(teamMember);
}
}
if(publishEvents.size()>0){
System.debug('Enter in PortfolioAssignmentService: deleteAccountTeamMembers====='+publishEvents.size());
EventBus.publish(publishEvents);
}
//HRP-8897
if(publishEventsForAccTeamUpdate.size()>0)
{
System.debug('Enter in PortfolioAssignmentService: update Account Team from deleteAccountTeamMembers====='+publishEventsForAccTeamUpdate.size());
EventBus.publish(publishEventsForAccTeamUpdate);
}
//HRP-8897
if(publishEvents.isEmpty() && publishEventsForAccTeamUpdate.isEmpty())//HRP-8897  added publishEventsForAccTeamUpdate.isEmpty()
{
List<Portfolio_Accounts_Processing__c> pt = [Select Id, Portfolio_Assignment_Updated__c From Portfolio_Accounts_Processing__c LIMIT 1];
insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='PortfolioAssignmentService',Method__c='createAccountTeamMembers',Type__c='Success',Error_Description__c='1139 pt --> '+pt);
if (pt.size() > 0 && pt[0].Portfolio_Assignment_Updated__c)
{
pt[0].Portfolio_Assignment_Updated__c=false;
}
update pt;
}
-- if(!teamMemberDeleteList.isEmpty()){
Database.DeleteResult[] deleteResults = Database.delete(teamMemberDeleteList,false);
//Log erros for any failures
}
--
}
public static void deletePortfolioAssignedMembersfromAccountTeam(List<AccountTeamMember> listOfAcctTeamMembers ){
if(!listOfAcctTeamMembers.isEmpty()){
Database.DeleteResult[] deleteResults = Database.delete(listOfAcctTeamMembers,false);
}
}*/
    /*HRP-6442, Populating Relationship manager lookup in Account*/
    public static void populateRMLookupOnAccount(List<Portfolio_Assignment__c>newItems)
    {
        if(BSF_Constants.skipPortfolioAssignmentTrigger)
        {return;}
        //Getting Portfolio Assignment and BSF Portfolio Id for RM portfolio assignment
        set<id> rmPortfolioAssignId = new set<id>();
        map<id,Portfolio_Assignment__c> mapPortfolioAssgn = new map<id,Portfolio_Assignment__c> ();
        for(Portfolio_Assignment__c pfAssign : newItems)
        {
            if(pfAssign.Assignment_Type__c == BSF_Constants.RELATIONSHIP_MANAGER)//HRP-9951 changed Hardcoded to constant
            {
                system.debug('mapPortfolioAssgn'+mapPortfolioAssgn);
                mapPortfolioAssgn.put(pfAssign.BSF_Portfolio__c,pfAssign);
                system.debug('mapPortfolioAssgn'+mapPortfolioAssgn);
            }
        }
        if(mapPortfolioAssgn!=null){
            //getting Accounts and Populating RM lookup
            List<Account_portfolio_Assignment__c> accPortfolioList = [select id,Name,Account__r.Relationship_Manager__c,Account__c,BSF_Portfolio__c from Account_portfolio_Assignment__c where BSF_Portfolio__c in :mapPortfolioAssgn.keyset()];
            system.debug('accPortfolioList'+accPortfolioList);
            List<Account> accUpdateList = new List<Account>();
            for(Account_portfolio_Assignment__c accPfAssign : accPortfolioList)
            {
                if(mapPortfolioAssgn.get(accPfAssign.BSF_Portfolio__c).Start_Date__c <= system.today() && mapPortfolioAssgn.get(accPfAssign.BSF_Portfolio__c).End_Date__c >= system.today())
                {
                    Account acc = new account(Id=accPfAssign.Account__c,Relationship_Manager__c=mapPortfolioAssgn.get(accPfAssign.BSF_Portfolio__c).User__c);
                    accUpdateList.add(acc);
                }
            }
            if(!accUpdateList.isEmpty())
            {
                try
                {
                    AccountTeamMemberHelper.skipAccountTrigger=true;
                    update accUpdateList;
                }
                catch(exception e)
                {
                    system.debug('The error message while inserting RM lookup is: '+e);
                }
            }
        }
        //HRP-9951
        List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c, Portfolio_Assignment_Updated__c, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1];
        pt[0].Portfolio_Assignment_Updated__c = false;
        system.debug('pt'+pt);
        update pt;
        //HRP-9951 not part of the ticket, but added since touching the code
    }
    public static void assignPermissionSetWhenUserIsAM(List<Portfolio_Assignment__c> newPortfolioAssignmentList){
        Set<ID> amUserIdSet=new Set<ID>();
        for(Portfolio_Assignment__c c: newPortfolioAssignmentList){
            if(c.Assignment_Type__c==BSF_Constants.ACCOUNT_MANAGER){
                amUserIdSet.add(c.User__c);
            }
        }
        assignPermissionSet(amUserIdSet);
    }
    @future
    public static void assignPermissionSet(Set<ID> amUserIdSet){
        List<user> UserList=[select id from User where id IN:amUserIdSet];
        //system.debug('UserList###'+UserList);
        List<PermissionSet> permissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('Affiliation_Permission','Publicity_Order')];
        //PermissionSet permissionSet1 = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Publicity_Order'];//('Edge Communications','GenePoint')
        list<PermissionSetAssignment> PermissionSetList=new list<PermissionSetAssignment>();
        for(user u:UserList){
            for(permissionSet ps:permissionSet){
                PermissionSetAssignment pemissionAssignment = new PermissionSetAssignment(PermissionSetId = ps.Id,AssigneeId = u.Id );
                PermissionSetList.add(pemissionAssignment);
            }
        }
        if(!PermissionSetList.IsEmpty()){
            //system.debug('PermissionSetList'+PermissionSetList);
            insert PermissionSetList;
        }
    }
    public static void validateDateOverlap (List<Portfolio_Assignment__c> portfolioAssignmentList,Map<Id,Portfolio_Assignment__c> oldPortfolioAssignmentMap)
    {
        map<id,list<Portfolio_Assignment__c>> bsfIDPortAssignMap = new map<id,list<Portfolio_Assignment__c>>();
        set<id> portfolioIdSet = new set<id>();
        for(Portfolio_Assignment__c pa:portfolioAssignmentList)
        {
            if(oldPortfolioAssignmentMap == null ||(oldPortfolioAssignmentMap !=null
                                                    && (oldPortfolioAssignmentMap.get(pa.Id).start_date__c != pa.Start_Date__c || oldPortfolioAssignmentMap.get(pa.Id).end_Date__c != pa.End_Date__c)))
            {
                if(!bsfIDPortAssignMap.keyset().contains(pa.BSF_Portfolio__c)){
                    bsfIDPortAssignMap.put(pa.BSF_Portfolio__c,new list<Portfolio_Assignment__c>());
                }
                bsfIDPortAssignMap.get(pa.BSF_Portfolio__c).add(pa);
            }
            portfolioIdSet.add(pa.id);
        }
        list<Portfolio_Assignment__c> exstngPortAssignList =[select id,start_date__c,End_Date__c,BSF_Portfolio__c,user__r.Name from Portfolio_Assignment__c where BSF_Portfolio__c In:bsfIDPortAssignMap.keyset() and Id not IN:portfolioIdSet];
        map<id,list<Portfolio_Assignment__c>> bsfIDExstngPortAssignMap = new map<id,list<Portfolio_Assignment__c>>();
        for(Portfolio_Assignment__c pa:exstngPortAssignList)
        {
            if(!bsfIDExstngPortAssignMap.keyset().contains(pa.BSF_Portfolio__c))
                bsfIDExstngPortAssignMap.put(pa.BSF_Portfolio__c,new list<Portfolio_Assignment__c>());
            bsfIDExstngPortAssignMap.get(pa.BSF_Portfolio__c).add(pa);
        }
        map<id,BSF_portfolio__c> bsfMap = new map<id,BSF_portfolio__c>([select id,start_date__c,End_date__c from BSF_portfolio__c where id in:bsfIDPortAssignMap.keyset()]);
        system.debug(portfolioIdSet);
        system.debug(bsfIDExstngPortAssignMap);
        for(Portfolio_Assignment__c pa :portfolioAssignmentList)
        {
            if(bsfIDExstngPortAssignMap.keyset().contains(pa.BSF_Portfolio__c))
            {
                for(Portfolio_Assignment__c exPa:bsfIDExstngPortAssignMap.get(pa.BSF_Portfolio__c))
                {
                    if(((pa.Start_Date__c >= exPa.Start_Date__c && pa.Start_Date__c <= exPa.End_Date__c)||(pa.End_Date__c >= exPa.Start_Date__c && pa.End_Date__c <= exPa.End_Date__c))||
                       ((exPa.Start_Date__c >= pa.Start_Date__c && exPa.Start_Date__c <= pa.End_Date__c)||(exPa.End_Date__c >= pa.Start_Date__c && exPa.End_Date__c <= pa.End_Date__c)))
                    {
                        //system.debug();
                        pa.addError('The selected date window is already covered by the user: '+ exPa.user__r.Name+'.Kindly select a different data range or Endate the existing assignment');
                    }
                }
            }
            //HRP-11290
            if(bsfMap!=null && bsfMap.get(pa.BSF_Portfolio__c)!=null &&
               (pa.Start_Date__c > bsfMap.get(pa.BSF_Portfolio__c).end_date__c || pa.Start_Date__c < bsfMap.get(pa.BSF_Portfolio__c).Start_date__c ||
                pa.End_Date__c < bsfMap.get(pa.BSF_Portfolio__c).Start_date__c || pa.End_Date__c > bsfMap.get(pa.BSF_Portfolio__c).End_date__c))
            {
                pa.addError('Invalid Assignment-The Portfolio Assignment dates are out of related BSF Portfolio Dates');
            }
            //HRP-11290
        }
    }
    public static void checkPfAssign(List<Portfolio_Assignment__c> newItems,Map<Id, Portfolio_Assignment__c> oldMap)
    {
        Boolean hasChanged = false;
        List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c, Portfolio_Assignment_Updated__c, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1];
        if(oldMap !=null)
        {
            for(Portfolio_Assignment__c pfAssign : newItems){
                if ((pfAssign.Start_Date__c != oldMap.get(pfAssign.Id).Start_Date__c) || (pfAssign.End_Date__c != oldMap.get(pfAssign.Id).End_Date__c)) {
                    hasChanged = true;
                    break;
                }
            }
        }
        if (pt.size() > 0 && pt[0].Portfolio_progress_for_Accounts__c != null && (pt[0].Portfolio_progress_for_Accounts__c != pt[0].Records_Processed__c || pt[0].Portfolio_Assignment_Updated__c) && !BSF_Constants.skipPortfolioAssignmentTrigger) {//HRP-9951
            for(Portfolio_Assignment__c pfAssign : newItems){
                if (!Test.isRunningTest()) {
                    pfAssign.addError('Portfolio Assignment records are already in progress. Please wait');
                }
            }
        }
        else if(pt.size() > 0 ){
            if(oldMap==null || hasChanged)
            {
                pt[0].Portfolio_Assignment_Updated__c = true;
                pt[0].Records_Processed__c = 0;
                pt[0].Portfolio_progress_for_Accounts__c = 0;
                update pt;
            }
        }
        else{
            if(oldMap==null || hasChanged)
            {
                insert new Portfolio_Accounts_Processing__c(Name= 'American Red Cross',  Portfolio_progress_for_Accounts__c = 0, Portfolio_Assignment_Updated__c = true, Records_Processed__c = 0);
            }
        }
    }
}