//@Description: This class contains different Opportunity split Trigger methods which is called from Opportunity split trigger handler 
/*
* 
* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 19/09/2023		    Kishore Das			    HRP-10741
*****************************************************************************************************************************************************************************
*/
public with sharing class OpportunitySplitService {
    
    /*
     * Ticket#: 3916
     * */
    public static void allowSpecificProfileUsers( List<OpportunitySplit> newItems, Map<Id,OpportunitySplit> oldMap, Map<Id,OpportunitySplit> newMap ){
        List<Id> opportunityids = new List<Id>();
        Map<Id,Id> splitAndOppIdMap = new Map<Id,Id>();
        Map<Id,Id> oppIdAndAccountIdmap = new Map<Id,Id>();
        Map<Id,Id> oppIdAndAccountDMmap = new Map<Id,Id>();
        Map<Id,Id> oppIdAndAccountAMmap = new Map<Id,Id>();
        Map<Id,List<AccountTeamMember>> accountteamIdAndAcountIdMap = new Map<Id,List<AccountTeamMember>>();
        List<Opportunity> oppsids = new List<Opportunity>();
        List<Id> accountids = new List<Id>();
        List<AccountTeamMember> accteamlists = new List<AccountTeamMember>();
        Set<Id> accountspecialists = new Set<Id>();
        If (OpportunitySplitRecursive.isOppotysplitBackEndUpdated == true  && test.isRunningTest()){
            
            return;
        }
        //By pass validation for dataLoad
        Map<String,String> mapOfprofiles=new Map<String,String>();
        String customLabelInfo=Label.OpportunitySplitService;
        if(customLabelInfo!=null && customLabelInfo.contains(';')){
        String[] splitStrings = customLabelInfo.split(';');
        for(String s1:splitStrings){
         mapOfprofiles.put(s1,s1);  
          }   
         }else if(customLabelInfo!=null && !customLabelInfo.contains(';')){
          mapOfprofiles.put(customLabelInfo,customLabelInfo);
         }

       Profile currentUserprofile = [Select Name from Profile where Id =: userinfo.getProfileid()];//Query constraints not applicable to profile query
        system.debug('currentUserprofile name '+currentUserprofile.name);

        for( OpportunitySplit opsplit : newItems ){
            opportunityids.add( opsplit.OpportunityId );
            splitAndOppIdMap.put( opsplit.Id, opsplit.OpportunityId );
        }
         
        
        oppsids = [ select AccountId,Account_Manager__c, Account.District_Manager__c, Id from Opportunity where Id in: opportunityids ];
        if( !oppsids.isEmpty() ){
            for( Opportunity opp : oppsids ){
                accountids.add( opp.AccountId );
                oppIdAndAccountIdmap.put( opp.Id, opp.AccountId );
                oppIdAndAccountDMmap.put( opp.Id, opp.Account.District_Manager__c );
                oppIdAndAccountAMmap.put(opp.id,opp.Account_Manager__c);
            }
        }
    
        if( !accountids.isEmpty() ){
            accteamlists = [ select AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId IN:accountids and TeamMemberRole IN ('Account Specialist') ];
        }
        user u = [select id,profile.Name from user where id = :userinfo.getUserId()];
        //By pass validation for dataLoad
        System.debug('mapOfprofiles.containsKey(currentUserprofile.name)->'+mapOfprofiles.containsKey(currentUserprofile.name));
        if(!mapOfprofiles.containsKey(currentUserprofile.name)){
            system.debug('one');
        if( !accteamlists.isEmpty() ){ 
            system.debug('two');
            for( AccountTeamMember ateam : accteamlists ){
                if( !accountteamIdAndAcountIdMap.containsKey( ateam.AccountId )){
                    accountteamIdAndAcountIdMap.put( ateam.AccountId, new List<AccountTeamMember>() );
                }
                accountteamIdAndAcountIdMap.get( ateam.AccountId ).add( ateam );
            }
            
            
            if( accountteamIdAndAcountIdMap.keySet().size() > 0 ){
                Id currentuser = UserInfo.getUserId();
                for( OpportunitySplit oppsplit : newItems){
                    List<AccountTeamMember> ateamlist = new List<AccountTeamMember>();
                    Id accountid = oppIdAndAccountIdmap.get(splitAndOppIdMap.get(oppsplit.Id)) ;
          Id DMId = oppIdAndAccountDMmap.get(splitAndOppIdMap.get(oppsplit.Id)) ;  
                    ID AMId = oppIdAndAccountAMmap.get(splitAndOppIdMap.get(oppsplit.Id));
                ateamlist = accountteamIdAndAcountIdMap.containsKey( accountid ) ?  accountteamIdAndAcountIdMap.get( accountid ) : new List<AccountTeamMember>() ;
                    if( ! ateamlist.isEmpty() ){
                        for( AccountTeamMember at : ateamlist ){
                            accountspecialists.add( at.UserId );
                        }
                    }
                    system.debug('accountspecialists##'+accountspecialists);
            
                    // Adding DM id if available
                    accountspecialists.add( DMId );
            
                        
                        if(!accountspecialists.contains( currentuser ) && u.profile.Name !='DRD Manager'){
                           oppsplit.addError(System.Label.OpportunitySplitErrorMsg);//part of the story HRP-10741
                         
                        }                
                }
                
            }
        }
            /*else{
            //querying Existing opportunitySpilt
            List<OpportunitySplit> existingOpptySplit = [select id,opportunityId from OpportunitySplit where OpportunityId IN:opportunityids and SplitOwnerId != :UserInfo.getUserId()];
            map<id,OpportunitySplit> opptywithOpptySplit = new map<id,opportunitySplit>();
            for(OpportunitySplit oppSplit:existingOpptySplit)
            {
                opptywithOpptySplit.put(oppSplit.opportunityId,OppSplit);
            }
            System.debug( 'existingOpptySplit'+existingOpptySplit);
            for( OpportunitySplit oppsplit : newItems){
                Id DMId = oppIdAndAccountDMmap.get(splitAndOppIdMap.get(oppsplit.Id)) ;
        Id currentuser = UserInfo.getUserId();
        if( currentuser != DMId && opptywithOpptySplit.get(oppsplit.opportunityId)!=null){
          oppsplit.addError( 'Only Account Specialist or District Manager is allowed to edit and apply. Currently there are no Account Specialist avaialble in Account Team' );
                    
        }
                
                
            }            
        }*/
    }
        
       // UserStory:HRP-3426  Start
        Set<Id> opptysplitids=new Set<Id>();
       for(OpportunitySplit oppsplits : newItems){
         opptysplitids.add(oppsplits.Id);
       }
       
       Map<Id,OpportunitySplit> mapOfOpptySplits=new Map<Id,OpportunitySplit>([SELECT Id,SplitType.DeveloperName FROM OpportunitySplit WHERE Id IN :opptysplitids ]); 
    
      for(OpportunitySplit oppsplit : newItems){
          Id DMId = oppIdAndAccountDMmap.get(oppsplit.OpportunityId) ;
        Id currentuser = UserInfo.getUserId();
        String splitType=mapOfOpptySplits.containsKey(oppsplit.id) ? mapOfOpptySplits.get(oppsplit.id).SplitType.DeveloperName:'';
                System.debug('splitType==='+splitType);
        //Overlay type
           if(currentuser == DMId && splitType == 'Overlay' && (oldMap == null|| (oldMap!=null&& oldMap.get(oppsplit.id).Split_Reason__c!=oppsplit.Split_Reason__c ) ) &&
            (oppsplit.Split_Reason__c ==Label.Split_RSMO_Donation || oppsplit.Split_Reason__c == Label.Split_Credit)
          ){
             oppsplit.addError( ' For Overlay Type, Split Reason should not be '+Label.Split_RSMO_Donation +' Or '+ Label.Split_Credit );     
        }
              
                // Story#:HRP-4647
                // Story Decription: Opportunity split record creates with Opportunity by default, and Split_Reason__c field is set blank,
                // that is why Drive/Opportunity creation from Plan a Drive button on Account throw an exception from this below if block.
                // now one more condition [oppsplit.Split_Reason__c !=null] is added here
        //Overlay Revenue
         if(currentuser == DMId && splitType == 'Revenue' && (oldMap == null ||(oldMap!=null && oldMap.get(oppsplit.id).Split_Reason__c!=oppsplit.Split_Reason__c)) &&
              (oppsplit.Split_Reason__c != null && oppsplit.Split_Reason__c !=Label.Split_RSMO_Donation && oppsplit.Split_Reason__c != Label.Split_Credit )
             ){
             oppsplit.addError( ' For Revenue Type, Split Reason should be '+Label.Split_RSMO_Donation +' Or '+ Label.Split_Credit);     
        }
      
    }
    
     // UserStory:HRP-3426  End
    }
    
    
    //HRP-3994 - CR: Assign Portfolio to Opportunity Split (Called from Trigger or Batch)
    public static List<List<OpportunitySplit>> addTeamMemberPortfolio (List<OpportunitySplit> newItems){
        //OppoSplitPortfolioReturnValue returnValue = new OppoSplitPortfolioReturnValue();
        List<List<OpportunitySplit>> returnVal = new List<List<OpportunitySplit>>();
        List<OpportunitySplit> changedOpps = new List<OpportunitySplit>();
        List<OpportunitySplit> errorOpps = new List<OpportunitySplit>();
        
        Map<id,boolean> isPortfolioChangedMap = new Map<id,boolean>();
        Boolean isMigrationEnabled=Boolean.valueOf(Label.OnlyForMigration);
        List<Id> opptyIdList = new List<Id>();
        List<Id> accountIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        
        
        
        List<Portfolio_Assignment__c> userPortfolioList = new List<Portfolio_Assignment__c>();
        
        system.debug('***OpportunitySplitService.addTeamMemberPortfolio() Called');
        
        for(OpportunitySplit oppSplit : newItems){
            opptyIdList.add(oppSplit.OpportunityId);
            userIdList.add(oppSplit.SplitOwnerId);
        }
        
        
    
        
        Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([SELECT Id, Name, AccountId, Drive_Date__c,Is_Template__c FROM Opportunity WHERE Id IN : opptyIdList]);
        
        if(userIdList != null) {
            userPortfolioList = [SELECT Id, Name, User__c,BSF_Portfolio__r.Portfolio_Type__c, Assignment_Type__c, BSF_Portfolio__c, End_Date__c, Start_Date__c FROM  Portfolio_Assignment__c WHERE User__c IN: userIdList AND BSF_Portfolio__c <> NULL ];
            system.debug('***OpportunitySplitService.addTeamMemberPortfolio() userPortfolioList : ' + userPortfolioList.toString()); 
        } else {
            system.debug('***OpportunitySplitService.addTeamMemberPortfolio() userIdList is NULL');
        }
        
        //HRP-7128 added by Balaji N
        List<id> accIdList = new List<id>();
        for(Opportunity opp : opptyMap.values())
        {
            accIdList.add(opp.AccountId);
        }
        
        List<String> typeList=new List<String>{'District Manager','Account Specialist','Booking Support','Sickle Cell Account Manager'};//Added by kishore HRP-7498

        List<Account_Portfolio_Assignment__c> accPortfolioList = [Select id,account__c,BSF_Portfolio__r.Portfolio_Type__c,bsf_Portfolio__c from Account_Portfolio_Assignment__c where account__c IN:accIdList and BSF_Portfolio__c <> NULL];
        map<id,List<id>> accIdBsfIdMap = new map<id,List<id>>();
        List<Id> BsfIds = new List<Id>();
        map<id,id> bsfaccids=new map<id,id>();
        for(Account_Portfolio_Assignment__c accportfolio : accPortfolioList)
        {
            if(!accIdBsfIdMap.containsKey(accportfolio.account__c))
            {
                List<id> bsfIdList = new List<id>();
                bsfIdList.add(accportfolio.bsf_Portfolio__c);
                accIdBsfIdMap.put(accportfolio.account__c,bsfIdList);
            }
            else
            {
                List<id> bsfIdList = accIdBsfIdMap.get(accportfolio.account__c);
                bsfIdList.add(accportfolio.bsf_Portfolio__c);
                accIdBsfIdMap.put(accportfolio.account__c,bsfIdList);
             }
            if(typeList.Contains(accportfolio.BSF_Portfolio__r.Portfolio_Type__c)){
                BsfIds.add(accportfolio.BSF_Portfolio__c);
                bsfaccids.put(accportfolio.BSF_Portfolio__c, accportfolio.Account__c);
            }  
               
        }
        
        List<Portfolio_Assignment__c> paAssignments = [SELECT Id, Name, User__c,BSF_Portfolio__r.Portfolio_Type__c, Assignment_Type__c, BSF_Portfolio__c, End_Date__c, Start_Date__c FROM  Portfolio_Assignment__c WHERE User__c IN: userIdList AND BSF_Portfolio__c in: BsfIds ];
        map<id,id> MapIds=new map<id,id>();
        for(Portfolio_Assignment__c pas:paAssignments){
            MapIds.put(pas.User__c,bsfaccids.get(pas.BSF_Portfolio__c));
        }
       /* Set<Id> opptyIdSet = new Set<Id>();
        for(OpportunitySplit oppSplit : newItems){
            opptyIdSet.add(oppSplit.OpportunityId);
        }
        List<OpportunitySplit> oppSplitOtherRec = [SELECT Id, SplitOwnerId, OpportunityId FROM OpportunitySplit WHERE OpportunityId IN : opptyIdSet];
        Map<Id,List<Id>> opportunityUserMap = new Map<Id,List<Id>>();
        for(OpportunitySplit oppSplit : oppSplitOtherRec){
            if(!opportunityUserMap.containsKey(oppSplit.OpportunityId)){
                opportunityUserMap.put(oppSplit.OpportunityId, new List<Id>());
            }
            opportunityUserMap.get(oppSplit.OpportunityId).add(oppSplit.SplitOwnerId);
        }
        */
        
        for(OpportunitySplit oppSplit : newItems){
            
             Opportunity currentOpp = opptyMap.get(oppSplit.OpportunityId);        
            
            If(oppSplit.SplitOwnerId==userInfo.getUserId() && !MapIds.keyset().contains(oppSplit.SplitOwnerId)){// MapIds.get(oppSplit.SplitOwnerId) ==null
                if(!OpportunityTriggerHandler.isSplit && !Test.isRunningTest()){
                    //oppSplit.addError('you cannot add yourself as opportunity split');
                
               }
            }
            /*
            if(opportunityUserMap.get(oppSplit.OpportunityId) != null && opportunityUserMap.get(oppSplit.OpportunityId).contains(userInfo.getUserId()) 
                    && MapIds.get(currentOpp.AccountId) ==null){
               oppSplit.addError('you cannot add yourself as opportunity split');
            }
            */
            Date effectiveDate = Date.Today();
            Id currentPortfolio = oppSplit.BSF_Portfolio__c;
            Id matchedPortfolio = null;
            if(currentOpp.Is_Template__c == true){
                continue; //this logic applies only for real opportunities, not templates
            }
            if(currentOpp != null && currentOpp.Drive_Date__c != null){
                effectiveDate = currentOpp.Drive_Date__c;
                //currentAccountId = currentOpp.AccountId;
            }
            Id currentSplitOwner = oppSplit.SplitOwnerId;
            boolean isPortfolioChanged = false;
            id accid = opptyMap.get(oppSplit.OpportunityId).AccountId;
            Integer portIndex = 0;
            system.debug('***OpportunitySplitService.addTeamMemberPortfolio() effectiveDate : ' + effectiveDate);   
            system.debug('***OpportunitySplitService.addTeamMemberPortfolio() currentPortfolio : ' + currentPortfolio);
            system.debug('***OpportunitySplitService.addTeamMemberPortfolio() currentSplitOwner : ' + currentSplitOwner);           
            
            if(userPortfolioList != null && userPortfolioList.size() > 0){
                for(Portfolio_Assignment__c portAssign : userPortfolioList) {
                   
                    if(portAssign.User__c == currentSplitOwner && portAssign.Start_Date__c <= effectiveDate && portAssign.End_Date__c >= effectiveDate ) {
                        if(accIdBsfIdMap.get(accid) != null)
                        {
                        if(accIdBsfIdMap.get(accid).contains(portAssign.BSF_Portfolio__c))
                        {
                            system.debug('Entered here 244');
                            matchedPortfolio = portAssign.BSF_Portfolio__c;
                            break;
                        }
                        else if((!accIdBsfIdMap.get(accid).contains(portAssign.BSF_Portfolio__c)) && userPortfolioList.size()-1 == portIndex)
                        {
                            system.debug('Entered here 250');
                            matchedPortfolio = portAssign.BSF_Portfolio__c;
                        }
                        }
                        system.debug('***OpportunitySplitService.addTeamMemberPortfolio() Portfolio__c matching with Opportunity Account Portfolio for the Selected Team Member found : ' + matchedPortfolio);
                        
                        portIndex++;
                    }
                }
                if(matchedPortfolio == null){
                    //No Account or User Portfolio Assignment Available for this Opportunity Split Entry
                    system.debug('***OpportunitySplitService.addTeamMemberPortfolio() Portfolio__c matching with Opportunity Account Portfolio for the Selected Team Member NOT found');
                    errorOpps.add(oppsplit);
                   // if(Trigger.isExecuting && isMigrationEnabled == false)
                    //  oppSplit.addError('The team member that you selected does not have a corresponding portfolio. Team members need to be associated to a Portfolio in order to be added to a split.');
                } else {
                    if(matchedPortfolio != oppSplit.BSF_Portfolio__c){
                        
                        oppSplit.BSF_Portfolio__c = matchedPortfolio;
                        changedOpps.add(oppSplit); 
                        //isPortfolioChanged = true;
                        system.debug('***OpportunitySplitService.addTeamMemberPortfolio() Assigned matchedPortfolio to Current Record');
                    } else {
                        //isPortfolioChanged = false;
                        system.debug('***OpportunitySplitService.addTeamMemberPortfolio() Matching Portfolio same as Current Portfolio Assigned');
                    }
                }
                    
            
            } else {
                system.debug('***OpportunitySplitService.addTeamMemberPortfolio() - NO ACCOUNT PORTFOLIO ASSIGNMENT OR USER PORTFOLIO ASSIGNMENT FOUND FOR CURRENT OPPORTUNITY SPLIT');
                //No Account or User Portfolio Assignment Available for this Opportunity Split Entry
                errorOpps.add(oppsplit);
                //if(Trigger.isExecuting && isMigrationEnabled == false)
                //  oppsplit.addError('The team member that you selected does not have a corresponding portfolio. Team members need to be associated to a Portfolio in order to be added to a split.');
                
            }
        }
        
        
        
        
        returnVal.add(changedOpps);
        returnVal.add(errorOpps);
        
        return returnVal;
    }
}