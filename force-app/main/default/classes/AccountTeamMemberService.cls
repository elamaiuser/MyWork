/* 
* @description: This class is called from AccountTeamMember trigger handler.
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 08/05/2023                 Balaji N                    Logic for HRP-8897 (New Method: dateCheckbeforeInsertUpdate)
* 09/20/2023				 Krapy Tuli					 Logic for HRP-10359(Update AM, DM, AM Portfolio and DM Portfolio)
* 11/09/2023				 Balaji N					 Logic for HRP-11290(Method Name:uncheckCoveringRecFlagForBackEndInsert,is covering recruiter flag in update)
* 11/22/2023				 Balaji N					 Logic for HRP-11281(Method Name:coveringRecruiterOpptyTeamonPastOpp, OpportunityTeam Recalculation for covering recruiters with past Opportunities,createAccountTeamMemberHistoryRecords update & Delete scenario)
* 12/14/2023				 Balaji N					 Logic for HRP-6028(Method Name:uncheckCoveringRecFlagForBackEndInsert; commented is_covering_recruiter__c population)
* 12/14/2023				 Balaji N					 Logic for HRP-6028(Method Name:dateCheckbeforeInsertUpdate; if check to prevent covering recruiter getting dates from Portfolio assignment)
* 01/16/2024				 Balaji N   				 Logic for HRP-11919 (Method Name :uncheckCoveringRecFlagForBackEndInsert;dateCheckbeforeInsertUpdate)
* 01/03/2024                 Balaji N					 Logic for HRP-10569 (Method Name :uncheckCoveringRecFlagForBackEndInsert,parameter changes on accTeamDateSyncOnAccPortUpdates method call)
* 01/31/2024				 Balaji N                    Logic for HRP-11234 (Method Name: addAcctTeamMembers_To_BloodDriveOpptyMembers;Method call for systemUserAsOwner, New method oppLookupUpdates)
* 02/08/2024                 Balaji N                    Logic for HRP-11424 (Static map accIdUserDate, for reducing the "accTeamDateSyncOnAccPortUpdates" method call;Method:uncheckCoveringRecFlagForBackEndInsert,dateCheckbeforeInsertUpdate)
* 02/08/2024				 Balaji N					 Logic for HRP-11424 (new method stopDeletingNonCRTeamMemberFromUI)
* 02/20/2024                 Balaji N					 Logic for HRP-11234(Method : updateAccountOnTeammeberAssignment,oldMap changes)
* 03/20/2024				 Balaji N					 Logic for HRP-12052(Method : uncheckCoveringRecFlagForBackEndInsert & allowOnlyDateUpdatesForCoveringRecs, added access level default)
* 08/28/2024				 Balaji N					 Logic for HRP-13340 (Commented method populateDefaultAllocationFiledsOnUpdate,populateDefaultAllocationFiledsOnInsert,coveringRecruiterOpptyTeamonPastOpp,deleteOpportunity_Splits_Teams_OnAccountTeamMemberDelete)
************************************************************************************************************************************************
*/
public with sharing class AccountTeamMemberService {
    
    public static Boolean isAccessLevelUpdated = false;
    public static Boolean isExecuted = false;
    
    public static map<string,AccountTeamMember> accIdUserDate = new map<string,AccountTeamMember>();//HRP-11424
    
    //Added as part of HRP-2193
    //Create TeamMemberHistory Records whenver a new record is created on AccountTeamMember
    public static void createAccountTeamMemberHistoryRecords(List<AccountTeamMember> newAccountTeamMembers,map<id,AccountTeamMember>oldMap){
        List<Team_Member_History__c> teamMemberHistoryList = new  List<Team_Member_History__c>();
        set<Id> newSetIdAM =new set<Id>();
        if(newAccountTeamMembers.size()>0){
            for(AccountTeamMember teamMember:newAccountTeamMembers){
                if(teamMember.TeamMemberRole=='ACCOUNT_MANAGER'){
                   newSetIdAM.add(teamMember.Id); 
                }
                
                if(//update
                   (oldMap!= null && 
                   (oldMap.get(teamMember.id).start_date__c != teamMember.Start_Date__c || 
                    oldMap.get(teamMember.id).End_Date__c != teamMember.End_Date__c || 
                    oldMap.get(teamMember.id).Is_Covering_Recruiter__c != teamMember.Is_Covering_Recruiter__c ||
                    oldMap.get(teamMember.id).TeamMemberRole != teamMember.TeamMemberRole ||
                    oldMap.get(teamMember.id).Coverage_Reason__c != teamMember.Coverage_Reason__c))//update //HRP-11281 if check
				    || oldMap==null) //Insert or Update
                {
                Team_Member_History__c historyRecord = new Team_Member_History__c();
                historyRecord.Account__c = teamMember.AccountId;
                historyRecord.Team_Member__c = teamMember.UserId;
                historyRecord.Role__c = teamMember.TeamMemberRole;
                historyRecord.Is_Covering_Recruiter__c = teamMember.Is_Covering_Recruiter__c;
                historyRecord.Coverage_Reason__c = teamMember.Coverage_Reason__c;
                if(teamMember.Start_Date__c!=null){
                    historyRecord.Start_Date__c = teamMember.Start_Date__c;
                }
                else{
                    historyRecord.Start_Date__c = System.today();
                }
                    
                if(teamMember.End_Date__c!=null){
                    historyRecord.End_Date__c = teamMember.End_Date__c;
                }
                    //HRP-11281 start
                if(trigger.isDelete)
                {
                    if(teamMember.Start_Date__c > system.today())
                    {
                        historyRecord.End_Date__c = teamMember.Start_Date__c;
                    }
                    else if(teamMember.Start_Date__c <= system.today() && teamMember.End_Date__c >= system.today())
                    {
                        historyRecord.End_Date__c = System.today();
                    }
                    else if(teamMember.End_Date__c < system.today())
                    {
                        historyRecord.End_Date__c = teamMember.End_Date__c;
                    }
                    
                }
                    //HRP-11281 End
                    
                    
                    
                    
                
                teamMemberHistoryList.add(historyRecord);
                }
            }
        }
        
        //if (Schema.sObjectType.Team_Member_History__c.isCreateable()) {}
            Database.insert(teamMemberHistoryList);  
          
        
    }
    /* commented part of HRP-11281
    //Added as part of HRP-1084
    //Update the TeamMemberHistory Records when Team Member's Start Date, End Date and Coverage Reason are updated
    public static void updateAccountTeamMemberHistoryRecords( Map<ID, AccountTeamMember> newAccountTeamMembersMap){
        Set<Id> userIdList = new Set<Id>(); 
        Set<Id> accIdList = new Set<Id>(); 
        Map<Id,AccountTeamMember> userTeamMemberMap = new Map<Id,AccountTeamMember>();
        List<Team_Member_History__c> teamMemberHistoryListToUpdate = new List<Team_Member_History__c>();
        for(AccountTeamMember teamMember:newAccountTeamMembersMap.values()){
            userIdList.add(teamMember.UserId); 
            accIdList.add(teamMember.AccountId);
            userTeamMemberMap.put(teamMember.UserId, teamMember);
        }
        
        List<Team_Member_History__c> teamMemberHistoryList = [SELECT Id,Account__c,Team_Member__c,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Coverage_Reason__c FROM Team_Member_History__c WHERE Team_Member__c IN:userIdList AND Account__c IN:accIdList ];
        
        if(teamMemberHistoryList.size()>0){
            for(Team_Member_History__c memberHistory:teamMemberHistoryList){
                memberHistory.Start_Date__c = userTeamMemberMap.get(memberHistory.Team_Member__c).Start_Date__c;
                memberHistory.End_Date__c = userTeamMemberMap.get(memberHistory.Team_Member__c).End_Date__c;
                memberHistory.Coverage_Reason__c = userTeamMemberMap.get(memberHistory.Team_Member__c).Coverage_Reason__c;
                
                teamMemberHistoryListToUpdate.add(memberHistory);
            }
        }
        
        if(teamMemberHistoryListToUpdate.size()>0){
            try{ 
                
                    Database.update(teamMemberHistoryListToUpdate);
                 
            }catch(Exception e){
                System.debug('Error occured: '+e.getMessage());
            }     
        }
    }
    
    //Added as part of HRP-2193
    //Populate End Date on TeamMemberHistory record when an AccountTeamMember record gets deleted
    public static void populateEndDateOnAccountTeamMemberHistoryRecords(List<AccountTeamMember> deletedMappings, Map<ID, AccountTeamMember> MappingMap){
        
        System.debug('Entered populateEndDateOnAccountTeamMemberHistoryRecords');
        System.debug('MappingMap: '+MappingMap.keySet());
        Set<Id> userIdList = new Set<Id>(); 
        Set<Id> accIdList = new Set<Id>();
        List<Team_Member_History__c> teamMemberHistoryListToUpdate = new List<Team_Member_History__c>();
        
        for(AccountTeamMember teamMember:deletedMappings){
            userIdList.add(teamMember.UserId); 
            accIdList.add(teamMember.AccountId);
        }
        
        List<Team_Member_History__c> teamMemberHistoryList = [SELECT Id,Account__c,Team_Member__c,Start_Date__c,End_Date__c FROM Team_Member_History__c WHERE Team_Member__c IN:userIdList AND Account__c IN:accIdList ];
        
        System.debug('teamMemberHistoryList to Update after delete: '+teamMemberHistoryList);
        if(teamMemberHistoryList.size()>0){
            for(Team_Member_History__c memberHistory:teamMemberHistoryList){
                memberHistory.End_Date__c =  system.today();
                teamMemberHistoryListToUpdate.add(memberHistory);
            }
        }
        //if (Schema.sObjectType.Team_Member_History__c.fields.End_Date__c.isUpdateable()) {}
            Database.update(teamMemberHistoryListToUpdate);
         
    }commented part of HRP-11281*/
    
    //Added as part of HRP-1084
    //Add Account Team Members to Blood Drive Team Members when Account Team Member is inserted
    /*public static void createBloodDriveTeamMember(List<AccountTeamMember> newAccountTeamMembers){
        Set<Id> eligibleTeamMembersId = new Set<Id>();
        Set<Id> eligibleAccountId = new Set<Id>();
        for(AccountTeamMember teamMember:newAccountTeamMembers){
            eligibleTeamMembersId.add(teamMember.Id);
            eligibleAccountId.add(teamMember.AccountId);
        }
       List<Opportunity> optyList = [SELECT Id,AccountId,(SELECT Id,OpportunityId,TeamMemberRole,UserId FROM OpportunityTeamMembers) FROM Opportunity WHERE AccountId IN:eligibleAccountId ];
       List<OpportunityTeamMember> optyTeamMemberList = new List<OpportunityTeamMember>();
        
        for(AccountTeamMember teamMember:newAccountTeamMembers){
            for(Opportunity opty:optyList){
                if(opty.AccountId == teamMember.AccountId){
                    if(opty.OpportunityTeamMembers.size()==0){
                        OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                        optyTeamMemeberToAdd.OpportunityId = opty.Id;
                        optyTeamMemeberToAdd.TeamMemberRole = teamMember.TeamMemberRole;
                        optyTeamMemeberToAdd.UserId = teamMember.UserId;                                
                        optyTeamMemberList.add(optyTeamMemeberToAdd);                        
                    }
                    else{
                        for(OpportunityTeamMember optyTeamMember:opty.OpportunityTeamMembers){
                            if(optyTeamMember.UserId != teamMember.UserId){
                                OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                                optyTeamMemeberToAdd.OpportunityId = opty.Id;
                                optyTeamMemeberToAdd.TeamMemberRole = teamMember.TeamMemberRole;
                                optyTeamMemeberToAdd.UserId = teamMember.UserId;                                
                                optyTeamMemberList.add(optyTeamMemeberToAdd);       
                            }
                        }
                    }                    
                }                
            } 
        }
       
        if(optyTeamMemberList.size()>0){
            try{ 
                //if (Schema.sObjectType.OpportunityTeamMember.isCreateable()) {}
                system.debug('role5'+optyTeamMemberList);
                    Database.insert(optyTeamMemberList);
                 
            }
            catch(Exception e){
                  System.debug('Error occured: '+e.getMessage());
              }  
        }  
         
        
    }*/
    /* commented part of HRP-13340
    //Added as part of HRP-1084
    //Insert Default allocation fields and AM,Covering Recruiter fields present on Blood Drive Opportunity on the insert of Account Team Members
    public static void populateDefaultAllocationFiledsOnInsert(List<AccountTeamMember> newAccountTeamMembers){
        system.debug('Inside populateDefaultAllocationFiledsOnInsert');
        Set<Id> eligibleAccountId = new Set<Id>();
        Set<Id> eligibleTeamMembersId = new Set<Id>();
        List<AccountTeamMember> eligibleTeamMember = new List<AccountTeamMember>();
        if(newAccountTeamMembers.size()>0){
            for(AccountTeamMember teamMember: newAccountTeamMembers){
                //if(teamMember.Is_Covering_Recruiter__c == true){
                    eligibleAccountId.add(teamMember.AccountId);
                    eligibleTeamMember.add(teamMember);
                    eligibleTeamMembersId.add(teamMember.Id);
                //}
            }
        } 
        
        Map<Id,List<Opportunity>> accounToOppMap = new Map<Id,List<Opportunity>>();
        List<Opportunity> optyList = [SELECT Id,AccountId, Drive_Date__c, Account_Manager__c,OwnerId,Covering_Recruiter__c FROM Opportunity WHERE AccountId IN:eligibleAccountId ];
        Map<Id,List<OpportunitySplit>> OppToOpptSplit = new Map<Id,List<OpportunitySplit>>();	
        for(Opportunity oppty:optyList){	
            if(accounToOppMap.get(oppty.AccountId) == null){	
                accounToOppMap.put(oppty.AccountId,new List<Opportunity>());	
            }	
            accounToOppMap.get(oppty.AccountId).add(oppty);	
        }
        
        List<OpportunitySplit> opportunitySplitList = new List<OpportunitySplit>();
        OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName='Overlay' ];
        
        List<AccountTeamMember> accTeamMember = [SELECT Id, UserId,TeamMemberRole,OpportunityAccessLevel,AccountAccessLevel,CaseAccessLevel,Is_Covering_Recruiter__c,Coverage_Reason__c,Account.Account_Manager__c FROM AccountTeamMember WHERE Id IN:eligibleTeamMembersId ]; // 3
        System.debug('accTeamMember: '+accTeamMember);
        Map<Id,Id> teamMemberAMMap = new Map<Id,Id>();
		
		// If Account has its Account Manager populated
        for(AccountTeamMember teamMember:accTeamMember){
            if(teamMember.Account.Account_Manager__c != null){
            	teamMemberAMMap.put(teamMember.Id, teamMember.Account.Account_Manager__c ); 
            }
        }
        
		String accountmanagerid = null;
        // If Account Manager was not added earlier, 
        for(AccountTeamMember teamMember:accTeamMember){
            if(teamMember.Account.Account_Manager__c == null){
				if(teamMember.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER ){
					accountmanagerid = teamMember.UserId;					
				}
            }
        }
		
		// If Account has not any Account Manager
		for(AccountTeamMember teamMember:accTeamMember){
            if(teamMember.Account.Account_Manager__c == null){
				if( accountmanagerid != null  ){
					teamMemberAMMap.put(teamMember.Id, accountmanagerid ); 
				}
            }
        }
        
        System.debug('teamMemberAMMap: '+teamMemberAMMap);
        
        for(AccountTeamMember teamMember: eligibleTeamMember){
            if(!accounToOppMap.containsKey(teamMember.AccountId)){ 	
                continue;	
            }
            if(!(teamMember.Coverage_Reason__c == BSF_Constants.accTeamLoa || teamMember.Coverage_Reason__c == BSF_Constants.accTeamVacant)){	
                continue;	
            }	
            for(Opportunity opty:accounToOppMap.get(teamMember.AccountId)){
                if(opty.Drive_Date__c>=teamMember.Start_Date__c && opty.Drive_Date__c<=teamMember.End_Date__c){
                    if(teamMember.Coverage_Reason__c == BSF_Constants.accTeamLoa || teamMember.Coverage_Reason__c == BSF_Constants.accTeamVacant){
                        //Adding Split Record for Account Manager
                        //OpportunitySplit splitForAM = new OpportunitySplit();
            			splitForAM.SplitTypeId = overlaySplitType.Id;//not needed
            			splitForAM.OpportunityId = opty.Id;
                        splitForAM.SplitOwnerId = opty.OwnerId;//teamMemberAMMap.get(teamMember.Id); //OwnerId--Add AM if account manager is already existing on the team member's Account
                        System.debug('SplitOwnerId: '+splitForAM.SplitOwnerId);
            			splitForAM.SplitPercentage = 100;
						splitForAM.Is_Covering_Incentive__c = true;
                        
            			opportunitySplitList.add(splitForAM);--                       //Adding Split Record for Covering Recruiter
                        OpportunitySplit splitCoveringRec = new OpportunitySplit();
            			splitCoveringRec.SplitTypeId = overlaySplitType.Id;
            			splitCoveringRec.OpportunityId = opty.Id;
            			splitCoveringRec.SplitOwnerId = teamMember.UserId;
            			splitCoveringRec.SplitPercentage = 100;
                        splitCoveringRec.Split_Reason__c = teamMember.Coverage_Reason__c==BSF_Constants.accTeamLoa? BSF_Constants.opSplitLoa:BSF_Constants.opSplitVacant;
						splitCoveringRec.Is_Covering_Incentive__c = true;
                        
            			opportunitySplitList.add(splitCoveringRec);
                                                
                    }
                    --
                    else if(teamMember.Coverage_Reason__c == 'Vacant Territory'){
                        OpportunitySplit splitCoveringRec = new OpportunitySplit();
            			splitCoveringRec.SplitTypeId = overlaySplitType.Id;
            			splitCoveringRec.OpportunityId = opty.Id;
            			splitCoveringRec.SplitOwnerId = teamMember.UserId;
            			splitCoveringRec.SplitPercentage = 100;
						splitCoveringRec.Is_Covering_Incentive__c = true;
                        
            			opportunitySplitList.add(splitCoveringRec);
                    }--
                }                               
        	}

        }
        if(opportunitySplitList.size()>0){
            
                OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
               // if (Schema.sObjectType.OpportunitySplit.isCreateable()){}
                set<OpportunitySplit> checkNew= new set<OpportunitySplit>();
                checkNew.addAll(opportunitySplitList);
                opportunitySplitList.clear();
                opportunitySplitList.addAll(checkNew);
                system.debug('opportunitySplitList'+opportunitySplitList);
                
                Database.SaveResult[] insertResults = Database.insert(opportunitySplitList,false);
                for(Database.SaveResult saveResult:insertResults){
               System.debug('saveResult: '+saveResult.isSuccess());
               System.debug('saveResult errors: '+saveResult.getErrors());
               }
                
            
         }
    }
    
    
    
    //Added as part of HRP-1084
    //Update Default allocation fields and AM,Covering Recruiter fields present on Blood Drive Opportunity on the update of Account Team Members
      public static void populateDefaultAllocationFiledsOnUpdate(List<AccountTeamMember> oldAccountTeamMembers,List<AccountTeamMember> newAccountTeamMembers,Map<ID,AccountTeamMember> oldTeamMemberMap,Map<ID,AccountTeamMember> newTeamMemberMap){
          Map<Id,Id> teamMemberAccountIdMap = new Map<Id,Id>();
          for(AccountTeamMember teamMember:newAccountTeamMembers){
              teamMemberAccountIdMap.put(teamMember.Id,teamMember.AccountId);
          }
          OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName='Overlay' ];
          List<Opportunity> optyList = [SELECT Id, Drive_Date__c,AccountId,Account.Account_Manager__c, (SELECT OpportunityId,SplitTypeId,SplitOwnerId,SplitPercentage FROM OpportunitySplits WHERE SplitTypeId =: overlaySplitType.Id AND Is_Covering_Incentive__c = true)FROM Opportunity WHERE AccountId IN:teamMemberAccountIdMap.values() ];
      	  
          Map<Id,List<Opportunity>> accounToOppMap = new Map<Id,List<Opportunity>>();
          Map<Id,List<OpportunitySplit>> OppToOpptSplit = new Map<Id,List<OpportunitySplit>>();
          for(Opportunity oppty:optyList){
              if(accounToOppMap.get(oppty.AccountId) == null){
                  accounToOppMap.put(oppty.AccountId,new List<Opportunity>());
              }
              accounToOppMap.get(oppty.AccountId).add(oppty);
              OppToOpptSplit.put(oppty.Id,oppty.OpportunitySplits);
          }
          
          Map<Id,OpportunitySplit> opptySplitDeleteMap = new Map<Id,OpportunitySplit>();
          List<OpportunitySplit> opptySplitInsertList = new List<OpportunitySplit>();
		  Map<Id,OpportunitySplit> exisitingAMSplit = new Map<Id,OpportunitySplit>();
          
          for(AccountTeamMember newTeamMember:newAccountTeamMembers){
             AccountTeamMember oldTeamMember = oldTeamMemberMap.get(newTeamMember.Id);
              if(accounToOppMap.containsKey(newTeamMember.AccountId) && newTeamMember.Is_Covering_Recruiter__c && (newTeamMember.Start_Date__c != oldTeamMember.Start_Date__c || 
                                                           	newTeamMember.End_Date__c != oldTeamMember.End_Date__c || 
                                                            newTeamMember.UserId != oldTeamMember.UserId ||
                                                            newTeamMember.Coverage_Reason__c != oldTeamMember.Coverage_Reason__c)){
                  for(Opportunity oppty:accounToOppMap.get(newTeamMember.AccountId)){
                      if((oppty.Drive_Date__c < newTeamMember.Start_Date__c && oppty.Drive_Date__c >= oldTeamMember.Start_Date__c)
                         || (oppty.Drive_Date__c > newTeamMember.End_Date__c && oppty.Drive_Date__c <= oldTeamMember.End_Date__c)){
                         for(OpportunitySplit opptySplit:oppty.OpportunitySplits){
                            if(exisitingAMSplit.get(opptySplit.Id) == null)
                         		opptySplitDeleteMap.put(opptySplit.Id,opptySplit);    
                         }	
                      }else if(oppty.Drive_Date__c >= newTeamMember.Start_Date__c && oppty.Drive_Date__c <=newTeamMember.End_Date__c){
                         OpportunitySplit opptyAMSplit = null;
                         OpportunitySplit opptyCovRecruiterSplit = null;
                         for(OpportunitySplit opptySplit:oppty.OpportunitySplits){
                             if(opptySplit.SplitOwnerId == newTeamMember.UserId){
                                 opptyCovRecruiterSplit = opptySplit;
                             }else if(opptySplit.SplitOwnerId == oppty.Account.Account_Manager__c){
                                 opptyAMSplit = opptySplit;
                             }else{
                                 opptySplitDeleteMap.put(opptySplit.Id,opptySplit); 
                             }     
                         }
                         
                          --
                            OpportunitySplit splitForAM = new OpportunitySplit();
                            splitForAM.SplitTypeId = overlaySplitType.Id;
                            splitForAM.OpportunityId = oppty.Id;
                            splitForAM.SplitOwnerId = oppty.Account.Account_Manager__c; 
                            System.debug('SplitOwnerId: '+splitForAM.SplitOwnerId);
                            splitForAM.SplitPercentage = 100;
                            splitForAM.Is_Covering_Incentive__c = true; 
            				 -- 
                        	//Adding Split Record for Covering Recruiter
                        	OpportunitySplit splitCoveringRec = new OpportunitySplit();
            				splitCoveringRec.SplitTypeId = overlaySplitType.Id;
            				splitCoveringRec.OpportunityId = oppty.Id;
            				splitCoveringRec.SplitOwnerId = newTeamMember.UserId;
            				splitCoveringRec.SplitPercentage = 100;
                          	splitCoveringRec.Split_Reason__c =newTeamMember.Coverage_Reason__c==BSF_Constants.accTeamLoa? BSF_Constants.opSplitLoa:BSF_Constants.opSplitVacant;
							splitCoveringRec.Is_Covering_Incentive__c = true;
                          
                            if(newTeamMember.Coverage_Reason__c == BSF_Constants.accTeamLoa){
                                if(opptyCovRecruiterSplit == null){
                              		opptySplitInsertList.add(splitCoveringRec);
                            	}
                               --
                                if(opptyAMSplit == null){
                                 opptySplitInsertList.add(splitForAM);
                                }else{
                                 opptySplitDeleteMap.remove(opptyAMSplit.Id);
                                 exisitingAMSplit.put(opptyAMSplit.Id,opptyAMSplit);   
                                }--
                                
                            }else if(newTeamMember.Coverage_Reason__c == BSF_Constants.accTeamVacant){
                                if(opptyCovRecruiterSplit == null){
                              		opptySplitInsertList.add(splitCoveringRec);
                                }
                                --
                                if(opptyAMSplit != null){
                                    opptySplitDeleteMap.put(opptyAMSplit.Id,opptyAMSplit); 
                                }--
                          	}
            				
                          }
                      }
                  }
              }
          
            try{ 
                 OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                //if (Schema.sObjectType.OpportunitySplit.isCreateable()){}
                 
                    Database.insert(opptySplitInsertList);
                 
                //if (Schema.sObjectType.OpportunitySplit.isCreateable()){}
                
                    Database.delete(opptySplitDeleteMap.values());
                 
            }catch(Exception e){
                System.debug('Error occured: '+e.getMessage());
            }           
          
          --
          Map<Id, List<Opportunity>> teamMemberOptyMap = new Map<Id, List<Opportunity>>();
          for(AccountTeamMember teamMember:oldAccountTeamMembers){
              for(Opportunity opty:optyList){
                  if(teamMember.AccountId == opty.AccountId){
                      if(opty.Drive_Date__c>=teamMember.Start_Date__c && opty.Drive_Date__c<=teamMember.End_Date__c && teamMember.Is_Covering_Recruiter__c == true) {
                          if(!teamMemberOptyMap.containsKey(teamMember.Id)){
                              teamMemberOptyMap.put(teamMember.Id,new List<Opportunity>());
                          }
                          teamMemberOptyMap.get(teamMember.Id).add(opty);
                      }
                  }
              }
          }
          
          List<OpportunitySplit> optySplitListToDelete = new List<OpportunitySplit>();
          List<OpportunitySplit> optySplitListToUpdate = new List<OpportunitySplit>();
          Map<Id, List<OpportunitySplit>> matchingMemberOptyMap = new Map<Id, List<OpportunitySplit>>();
          
          for(AccountTeamMember teamMember:newAccountTeamMembers){
               System.debug('Inside new Team Members for loop Update');
              if(teamMemberOptyMap.containsKey(teamMember.Id)){
                
                  for(Opportunity opty:teamMemberOptyMap.get(teamMember.Id)){
                      if(opty.Drive_Date__c>=teamMember.Start_Date__c && opty.Drive_Date__c<=teamMember.End_Date__c  && teamMember.Is_Covering_Recruiter__c == true) {
						  System.debug('Inside matching date Update');
                          
                          
                      }
                      else{
                          for(OpportunitySplit optySplit:opty.OpportunitySplits){
                              optySplitListToDelete.add(optySplit);
                          }  
                      }
                  }                  
              }
              else{
                  system.debug('Inside else');
                  populateDefaultAllocationFiledsOnInsert(newAccountTeamMembers);
              }
          } 
          
          if(optySplitListToDelete.size()>0){
              try{
                  Database.delete(optySplitListToDelete);
              }
              catch(Exception e){
                  System.debug('Error occured: '+e.getMessage());
              }
              
          }
          if(optySplitListToUpdate.size()>0){
              try{
                  Database.update(optySplitListToUpdate);
              }
              catch(Exception e){
                  System.debug('Error occured: '+e.getMessage());
              }
              
          }--
      
      }
   commented part of HRP-13340 */
     //Added as part of HRP-1084
    //HRP-5487 :CR: Adding Account Team to Blood Drive Team  
    //Delete related Opportunity Split records when an AccountTeamMember record gets deleted
    /* commented part of HRP-13340
    public static void deleteOpportunity_Splits_Teams_OnAccountTeamMemberDelete(List<AccountTeamMember> deletedTeamMembers, Map<ID, AccountTeamMember> deletedTeamMembersMap){
       Map<Id,List<OpportunitySplit>> acctIdOpptySplitMap = new Map<Id,List<OpportunitySplit>>();
        Map<Id,List<OpportunityTeamMember>> acctIdOpptyTeamMemberMap = new Map<Id,List<OpportunityTeamMember>>();
        List<OpportunitySplit> optySplitListToDelete = new List<OpportunitySplit>();
        List<OpportunityTeamMember> optyTeamMembersListToDelete = new List<OpportunityTeamMember>(); 
        Map<Id,Id> teamMemberAccountIdMap = new Map<Id,Id>();
        Map<Id,AccountTeamMember> acctTeamMemberMap = new Map<Id,AccountTeamMember>();
        Set<Id> accTeamUserId = new Set<Id>();//HRP-13174
        for(AccountTeamMember teamMember:deletedTeamMembers){
            teamMemberAccountIdMap.put(teamMember.Id,teamMember.AccountId);
            acctTeamMemberMap.put(teamMember.AccountId,teamMember);
            accTeamUserId.add(teamMember.UserId);//HRP-13174
        }
        
        OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName='Overlay' ];
        List<Opportunity> optyList = [SELECT Id, OwnerId,Drive_Date__c,AccountId,Account.Account_Manager__c,(SELECT Id,OpportunityId,TeamMemberRole,UserId FROM OpportunityTeamMembers WHERE userId IN:accTeamUserId), (SELECT OpportunityId,SplitTypeId,SplitOwnerId,SplitPercentage FROM OpportunitySplits WHERE SplitTypeId =: overlaySplitType.Id AND Is_Covering_Incentive__c = true  AND SplitOwnerId IN:accTeamUserId) FROM Opportunity WHERE AccountId IN:teamMemberAccountIdMap.values() ];//HRP-13174
        
        
        for(Opportunity oppty:optyList){
            if(!acctIdOpptyTeamMemberMap.containsKey(oppty.AccountId)){
                acctIdOpptyTeamMemberMap.put(oppty.AccountId,new List<OpportunityTeamMember>());
            }
            if(!acctIdOpptySplitMap.containsKey(oppty.AccountId)){
                acctIdOpptySplitMap.put(oppty.AccountId,new List<OpportunitySplit>());
            }
            
            if(acctTeamMemberMap.containsKey(oppty.AccountId) &&	
					acctTeamMemberMap.get(oppty.AccountId).Start_Date__c <= oppty.Drive_Date__c &&	
					acctTeamMemberMap.get(oppty.AccountId).End_Date__c >= oppty.Drive_Date__c){
            	acctIdOpptySplitMap.get(oppty.AccountId).addAll(oppty.OpportunitySplits); 
            	acctIdOpptyTeamMemberMap.get(oppty.AccountId).addAll(oppty.OpportunityTeamMembers);
            }
        }
        
        //No logic changes,add if condition based on 5487,5486
        if(deletedTeamMembersMap != null){
            for(AccountTeamMember teamMember:deletedTeamMembers){
                if(acctIdOpptySplitMap.containsKey(teamMember.AccountId)){
                    for(OpportunitySplit optySplit:acctIdOpptySplitMap.get(teamMember.AccountId)){
                        if(teamMember.userId == optySplit.splitOwnerId){
                            optySplitListToDelete.add(optySplit);
                        }
                    }  
                }
            }
        }
        
		for(AccountTeamMember teamMember:deletedTeamMembers){        
            if(acctIdOpptyTeamMemberMap.containsKey(teamMember.AccountId)){
                for(OpportunityTeamMember optyTeamMember:acctIdOpptyTeamMemberMap.get(teamMember.AccountId)){
                    if(teamMember.userId == optyTeamMember.userId){
                        optyTeamMembersListToDelete.add(optyTeamMember);
                    }
                }  
            }
        }
            
        Boolean splitBatch = false;
        if(optySplitListToDelete.size()>0){
            try{
                if(optySplitListToDelete.size() < 100){
                    OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                    Database.DeleteResult[] drList = Database.delete(optySplitListToDelete,false);
                    
                    for(Database.DeleteResult dr : drList) {
                        if (!dr.isSuccess()) {
                            for(Database.Error err : dr.getErrors()) {
                                System.debug('Error Deleting split record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                            }
                        }
                    }
                }else{
                    splitBatch = true;
                    BSF_Batch_OpportunitySplitDelete batch1 = new BSF_Batch_OpportunitySplitDelete(optySplitListToDelete,optyTeamMembersListToDelete);
                }
            }catch(Exception e){
                System.debug('Error occured: '+e.getMessage());
            }     
        }
        
        if(optyTeamMembersListToDelete.size()>0 && splitBatch == false){
            try{
                if(optyTeamMembersListToDelete.size() < 100){
                    Database.DeleteResult[] drList = Database.delete(optyTeamMembersListToDelete,false);
                    for(Database.DeleteResult dr : drList) {
                        if (!dr.isSuccess()) {
                            for(Database.Error err : dr.getErrors()) {
                                System.debug('Error Deleting split record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                            }
                        }
                    }
                }else{
                    BSF_Batch_OpportunityTeamMember teamMemberBatch = new BSF_Batch_OpportunityTeamMember(optyTeamMembersListToDelete,new List<OpportunityTeamMember>(),'Delete',false,0);
                    Database.executeBatch(teamMemberBatch,100);
                }
            }catch(Exception e){
                System.debug('Error occured: '+e.getMessage());
            }     
        }
        
        if(!BSF_Constants.isTeamMemberCreatedFromBackend)
        AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(new List<id>(acctTeamMemberMap.Keyset()),null,new set<id>(),new map<id,list<accountTeamMember>>(),new map<id,list<accountTeamMember>> ());
    }
    commented part of HRP-13340 */
    //Added for HRP-5076: Acceptance Criteria #5
    // User will not get an option to provide access to Account , Case, Opportunity after click on Add Team Member
     public static void uncheckCoveringRecFlagForBackEndInsert(List<AccountTeamMember> newAccountTeamMembers,map<id,AccountTeamMember> oldMap){
        System.debug('BSF_Constants.isTeamMemberCreatedFromBackend '+BSF_Constants.isTeamMemberCreatedFromBackend);
        set<id> errorAtmSet = new set<id>();
        set<id> portfolioErrorAtmSet = new set<id>();
        list<id> accIdList = new list<id>();
        for(AccountTeamMember atm :newAccountTeamMembers)
        {
            //HRP-12052 start
            atm.AccountAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'None';
            //HRP-12052 end
            if(!accIdList.contains(atm.accountid))
            {
                accIdList.add(atm.accountid);
            }
        }
        //HRP-11424 Start prev this call was in dateCheckbeforeInsertUpdate method
        Map<id,list<accountTeamMember>> accIdFutureAccTeamMap = new Map<id,list<accountTeamMember>>();
        if(bsf_constants.isdateCheckbeforeInsertUpdate && !BSF_Constants.isTeamMemberCreatedFromBackend)//HRP-13340
        {
             accIdUserDate=accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(accIdList,bsf_constants.BYPASS_TEAMDML,new set<id>(),accIdFutureAccTeamMap,new map<id,list<accountTeamMember>> ());//HRP-10569 new parameters
        }
       
		//HRP-11424 End     
		   
        //HRP-11290 start
        if(BSF_Constants.isTeamMemberCreatedFromBackend == true)
        {
            for(accountTeamMember atm : newAccountTeamMembers)
            {
                //covering recruiter Handled in accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates method
                //HRP-11424 commented Start 
                /*if((oldMap!=null  && (atm.Start_Date__c!=oldMap.get(atm.id).start_date__c || atm.End_date__c!=oldMap.get(atm.id).End_date__c) && oldMap.get(atm.id).is_Covering_recruiter__c && oldMap.get(atm.id).End_date__c >= system.today()))// && !(atm.start_date__c<=oldMap.get(atm.id).start_date__c && atm.End_date__c>=oldMap.get(atm.id).End_date__c))
                {
                    //atm.Start_Date__c=oldMap.get(atm.id).start_date__c;
                    //atm.End_date__c=oldMap.get(atm.id).End_date__c;
                    //populate back end date fields,error is not needed
                }*/
                //HRP-11424 commented End
                
                   if(oldMap==null ||(oldMap!=null && (atm.start_date__c<=oldMap.get(atm.id).start_date__c && oldMap.get(atm.id).End_date__c<=atm.End_date__c) ))
                      {
                          atm.Is_Covering_Recruiter__c = false;
                          atm.Coverage_Reason__c = null;//HRP-11919
                      }
                    
                
             }
            
            
        }
        else
        {
            //HRP-11424 Start
            Map<string,AccountTeamMember> accIdUserFutureDate = new Map<string,AccountTeamMember>();
            
            for(id i: accIdFutureAccTeamMap.keyset())
            {
                for(accountTeamMember atm : accIdFutureAccTeamMap.get(i))
                {
                    string Key = atm.accountId+'_'+atm.userId;
                    if(!accIdUserFutureDate.containsKey(key))
                        accIdUserFutureDate.put(key,atm);
                }
            }
             //HRP-11424 End
            for(accountTeamMember atm : newAccountTeamMembers)
            {
                if(oldMap == null)
                {
                    //HRP-12052 Start
                    //atm.Is_Covering_Recruiter__c = true; commented part of HRP-6028
                    atm.AccountAccessLevel = 'Edit';
                    atm.OpportunityAccessLevel = 'Edit';
                    atm.CaseAccessLevel = 'None';
                    //HRP-12052 End
                }
                else
                {
                    //HRP-11424 Start
                    if(oldMap.get(atm.id).Coverage_Reason__c == null && atm.Coverage_Reason__c != null || 
                       (oldMap.get(atm.id).is_covering_recruiter__c && (oldMap.get(atm.id).Start_Date__c!= atm.Start_Date__c || oldMap.get(atm.id).End_Date__c!= atm.End_Date__c)))//HRP-11919
                    {
                        string key=atm.AccountId+'_'+atm.userId;
                        boolean cr=true;//HRP-12052 false to true
                        boolean crfuture=true;//HRP-12052 false to true
                        if(accIdUserDate!= null && accIdUserDate.containsKey(key) && !((atm.Start_Date__c < accIdUserDate.get(key).Start_Date__c  && atm.End_Date__c < accIdUserDate.get(key).Start_Date__c) || ((atm.Start_Date__c > accIdUserDate.get(key).End_Date__c))))//HRP-12052 changed oldMap to accIdUserDate and NOT logic
                          {
                              cr= false;//HRP-12052 true to false
                          }
                        if(accIdUserFutureDate != null && accIdUserFutureDate.containsKey(Key))
                        {
                            accountTeamMember futAtm =  accIdUserFutureDate.get(Key);
                            if(!((atm.Start_Date__c < futAtm.Start_Date__c  && atm.End_Date__c < futAtm.Start_Date__c) || ((atm.Start_Date__c > futAtm.End_Date__c) )))//HRP-12052 NOT logic
                            {
                                crfuture=false;//HRP-12052 true to false
                            }
                        }
                        
                        if(cr && crfuture)
                        {
                            atm.Is_Covering_Recruiter__c = true;//HRP-11919
                        }
                        else
                        {
                            portfolioErrorAtmSet.add(atm.id);
                        }
                    }
                    //HRP-11424 End
                    
                    if(oldMap.get(atm.id).is_Covering_recruiter__c && !atm.Is_Covering_Recruiter__c)
                    {
                        errorAtmSet.add(atm.id);
                    }
                }
            }
            
        }
        
        
        for(accountTeamMember atm : newAccountTeamMembers)
        {
            if(errorAtmSet.contains(atm.id))
                atm.addError('Once covering Recruiter Cannot be unchecked accountid: '+atm.accountid+' User.id: '+atm.UserId);
            else if(portfolioErrorAtmSet.contains(atm.id))//HRP-11424
                atm.addError('The covering Recruiter assignment is overlapping the portfolio assignment please add the covering recruiter before or after account team Date ');//HRP-11424
        }
        //HRP-11290 end
        
        
        /*if(BSF_Constants.isTeamMemberCreatedFromBackend == false){
for(AccountTeamMember teamMember:newAccountTeamMembers){
if(teamMember.Is_Covering_Recruiter__c == true){
if( teamMember.AccountAccessLevel == 'Read'){
teamMember.addError( 'Covering Recruiters need to have a Account Access of Read/Write');
}
if( teamMember.OpportunityAccessLevel == 'Read'){
teamMember.addError( 'Covering Recruiters need to have a Blood Drive Opportunity Access of Read/Write');
}
if( teamMember.CaseAccessLevel == 'Read'){
teamMember.addError( 'Covering Recruiters need to have a Case Access of Read/Write');
}

}
} 
}*/
        
    }
    
    
    
    
    
    //Added for HRP-5076: Acceptance Criteria #12
    //A Drd User(or any other non admin user) should not be able to edit the Team Members other than only Start Date and End Date
    public static void allowOnlyDateUpdatesForCoveringRecs(List<AccountTeamMember> newAccountTeamMembers, Map<Id,AccountTeamMember> oldAccountTeamMembersMap,Map<Id,AccountTeamMember> newAccountTeamMembersMap){
        Id autoProcessuserId = [SELECT Id FROM User WHERE alias = 'autoproc'].Id;
        String proflieName='';
        if(userinfo.getUserId()!=autoProcessuserId) {
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];// profile doesn't need security enforced
         proflieName = profileList[0].Name;
        }   
        if((!proflieName.equalsIgnoreCase('System Administrator')) || autoProcessuserId ==userinfo.getUserId() ){
            for(AccountTeamMember newTeamMember:newAccountTeamMembers){
                AccountTeamMember oldTeamMember = oldAccountTeamMembersMap.get(newTeamMember.Id);
                if(BSF_Constants.isTeamMemberCreatedFromBackend == false){
                    if(oldTeamMember.Is_Covering_Recruiter__c == true){
                      //HRP-12052 start
                        /*newTeamMember.AccountAccessLevel = 'Edit';
                        newTeamMember.OpportunityAccessLevel = 'Edit';
                        newTeamMember.CaseAccessLevel = 'None';*/
                        //HRP-12052 end
                if(newTeamMember.AccountId != oldTeamMember.AccountId 
                           ||newTeamMember.Coverage_Reason__c !=  oldTeamMember.Coverage_Reason__c
                           ||newTeamMember.TeamMemberRole !=  oldTeamMember.TeamMemberRole
                           ||newTeamMember.OpportunityAccessLevel != oldTeamMember.OpportunityAccessLevel
                           ||newTeamMember.CaseAccessLevel != oldTeamMember.CaseAccessLevel
                           ||newTeamMember.UserId != oldTeamMember.UserId
                           ||newTeamMember.Is_Covering_Recruiter__c != oldTeamMember.Is_Covering_Recruiter__c){
                               system.debug('newTeamMember'+newTeamMember);
                               system.debug('oldAccountTeamMembersMap.get(newTeamMember.Id)'+oldAccountTeamMembersMap.get(newTeamMember.Id));
                               newAccountTeamMembersMap.get(newTeamMember.Id).addError('Only Start Date and End Date can be updated for the Covering Recruiters');
                           }
                    }
                    else{
                        if(oldTeamMember.Is_Covering_Recruiter__c == false){
                           // newAccountTeamMembersMap.get(newTeamMember.Id).addError('Account Team Members can not be updated');
                        }
                    }
                }
            }     
        }
        
    }
    
    /*
    //Added for HRP-5076: Acceptance Criteria #5
    // Not required this method, this is shifted to before insert    
    public static void updateAccessLevelsOfCoveringRecruiters(List<AccountTeamMember> newTeamMemberList, Map<Id,AccountTeamMember> newTeamMemberMap){
       List<AccountTeamMember> teamMemberList = [SELECT Id,Is_Covering_Recruiter__c,AccountId,Coverage_Reason__c,TeamMemberRole,OpportunityAccessLevel,CaseAccessLevel,AccountAccessLevel 
                                                 FROM AccountTeamMember
                                                 WHERE Id IN:newTeamMemberMap.keySet()];
        System.debug( 'Update Access levels after insert' );
        List<AccountTeamMember> teamMemberUpdateList = new List<AccountTeamMember>();
        for(AccountTeamMember teamMember:teamMemberList){
            System.debug( 'Update Account Drive Case Access levels after insert' + teamMember.AccountAccessLevel  );
            if(teamMember.Is_Covering_Recruiter__c == true && BSF_Constants.isTeamMemberCreatedFromBackend == false){
                 teamMember.AccountAccessLevel = 'Edit';
                 teamMember.OpportunityAccessLevel = 'Edit';
                 teamMember.CaseAccessLevel = 'Edit';
                
                 teamMemberUpdateList.add(teamMember);
            }
        } 
        
        if(teamMemberUpdateList.size()>0){
            try{
                System.debug('updateAccessLevelsOfCoveringRecruiters.teamMemberUpdateList: '+teamMemberUpdateList);
                isAccessLevelUpdated = true;
                Database.update(teamMemberUpdateList);
            }
            catch(Exception e){
                System.debug('An Error has occured: '+e.getMessage());
            }
        }
    } */
    
    /* HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
      * HRP-5487 :CR: Adding Account Team to Blood Drive Team  == Start
      */  
     public static void addAcctTeamMembersToBloodDriveOpptyMembers(List<AccountTeamMember> newAccountTeamMembers,Map<Id,AccountTeamMember> mapOfOldAcctTeamMembers,Boolean accTeamUpdated){
       	Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers=new Map<Id,List<AccountTeamMember>>();
        List<AccountTeamMember> listofOldAcctTeamMembers=new List<AccountTeamMember>();
        Set<Id> setofAccountIds=new Set<Id>();
        Map<Id,List<Date>> accIdMinMaxDates = new Map<Id,List<Date>>();
        for(AccountTeamMember atmRecord:newAccountTeamMembers)
        {
            system.debug(atmRecord.AccountId +'atmid '+ atmRecord.Id);
            if(mapOfOldAcctTeamMembers==null ||(mapOfOldAcctTeamMembers!=null && (atmRecord.Start_Date__c!=mapOfOldAcctTeamMembers.get(atmRecord.Id).Start_Date__c || 
              atmRecord.End_Date__c!=mapOfOldAcctTeamMembers.get(atmRecord.Id).End_Date__c))){
              setofAccountIds.add(atmRecord.AccountId); 
              //HRP-13340
              if(!accIdMinMaxDates.containsKey(atmRecord.AccountId))
              {
                accIdMinMaxDates.put(atmRecord.AccountId,new List<Date>());
              }
                Date atmStartDate = mapOfOldAcctTeamMembers == null || atmRecord.Start_Date__c <= mapOfOldAcctTeamMembers.get(atmRecord.id).Start_Date__c? atmRecord.Start_Date__c:mapOfOldAcctTeamMembers.get(atmRecord.id).Start_Date__c;
                Date atmEndDate =  mapOfOldAcctTeamMembers == null || atmRecord.End_Date__c >= mapOfOldAcctTeamMembers.get(atmRecord.id).End_Date__c? atmRecord.End_Date__c:mapOfOldAcctTeamMembers.get(atmRecord.id).End_Date__c;
            
                if(accIdMinMaxDates.get(atmRecord.AccountId).isEmpty())
                {
                    accIdMinMaxDates.get(atmRecord.AccountId).add(atmStartDate);
                    accIdMinMaxDates.get(atmRecord.AccountId).add(atmEndDate);
                }
                else 
                {
                    accIdMinMaxDates.get(atmRecord.AccountId)[0] = atmStartDate < accIdMinMaxDates.get(atmRecord.AccountId)[0]? atmStartDate : accIdMinMaxDates.get(atmRecord.AccountId)[0];
                    accIdMinMaxDates.get(atmRecord.AccountId)[1] = atmEndDate   > accIdMinMaxDates.get(atmRecord.AccountId)[1]? atmEndDate   : accIdMinMaxDates.get(atmRecord.AccountId)[1];
                } 
                //HRP-13340         
           }
        }
        if(setofAccountIds.isEmpty()){
             List<Portfolio_Accounts_Processing__c> pt = [Select Id, Portfolio_progress_for_Accounts__c, Records_Processed__c, Portfolio_Assignment_Updated__c From Portfolio_Accounts_Processing__c LIMIT 1];
            if (pt.size() > 0 && pt[0].Portfolio_Assignment_Updated__c) 
            {
                pt[0].Portfolio_Assignment_Updated__c=false;
            }
            update pt;
             return;
         }
         List<UpdateOpptyTeamEvent__e> publishEvents = new List<UpdateOpptyTeamEvent__e>();
         //List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
         for(ID acctId:setofAccountIds){
             UpdateOpptyTeamEvent__e eve = new UpdateOpptyTeamEvent__e();
             eve.AcctTeamMemberId__c = acctId;
             eve.Start_Date__c = accIdMinMaxDates.get(acctId)[0];//HRP-13340
             eve.End_Date__c   = accIdMinMaxDates.get(acctId)[1];//HRP-13340			  
             publishEvents.add(eve);
             //BSF_Error_Log__c log = BSF_Utilities.getErrorLog('Populate Account Team','AccountTeamMemberService', 'addAcctTeamMembersToBloodDriveOpptyMembers', 'Debug Log','no Error-Platform Event Start log', 'AccountID:'+string.valueof(acctId) );
             //logList.add(log);
         }
         
         if(publishEvents.size()>0){
             List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c From Portfolio_Accounts_Processing__c LIMIT 1 FOR UPDATE];
             System.debug('publishEvents.size()--> '+publishEvents.size());
             if (pt.size() > 0) {
                System.debug('pt.size()--> '+pt.size());
                System.debug('pt--> '+pt);
                System.debug('publishEvents.size()--> '+publishEvents.size());
                System.debug('pt[0].Portfolio_progress_for_Accounts__c--> '+pt[0].Portfolio_progress_for_Accounts__c);
                pt[0].Portfolio_progress_for_Accounts__c = pt[0].Portfolio_progress_for_Accounts__c < 0 ? 0 : pt[0].Portfolio_progress_for_Accounts__c;
                pt[0].Portfolio_progress_for_Accounts__c = publishEvents.size() + pt[0].Portfolio_progress_for_Accounts__c;
                pt[0].Portfolio_Assignment_Updated__c = false;
                update pt;
            }else{
                insert new Portfolio_Accounts_Processing__c(Name= 'American Red Cross',  Portfolio_progress_for_Accounts__c = publishEvents.size(), Portfolio_Assignment_Updated__c = false, Records_Processed__c = 0);
            }
            EventBus.publish(publishEvents);
         }		
         
     }
    /* HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
* HRP-5487 :CR: Adding Account Team to Blood Drive Team  == End
*/    
   public static void addAcctTeamMembers_To_BloodDriveOpptyMembers(Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers,List<Opportunity> listofOppties,List<OpportunityTeamMember> listOfOpptyTeamMembersTodelete,List<OpportunityTeamMember> optyTeamMemberNotExistListToInsert){
        system.debug('addAcctTeamMembers_To_BloodDriveOpptyMembers '+mapOfAcctsWithTeamMembers);
        insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='AccountTeamMemeberService',Method__c='addAcctTeamMembers_To_BloodDriveOpptyMembers',Type__c='Success',Error_Description__c='mapOfAcctsWithTeamMembers '+String.valueOf(mapOfAcctsWithTeamMembers.size()));
        list<OpportunityTeamMember> optyTeamMemberListToInsert = new list<OpportunityTeamMember>();
        Map<Id,List<AccountTeamMember>> mapOfOpptyWithAcctTeamsToDelete=new Map<Id,List<AccountTeamMember>>();
        list<Opportunity> listofOpptiesOwnersToupdate=new list<Opportunity>();
        Set<Id> setOfOpptyIds=new Set<Id>();
        Set<String> acctTeamKeySet = new Set<String>();
        Set<String> opptyInsertTeamKeySet = new Set<String>();
        Map<Id,Id> oppWithOwnerIdMap = new Map<Id,Id>();
        Map<Id,Id> oppWithAccMangrIdMap = new Map<Id,Id>();
        Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap = new Map<Id,Opportunity>(); //HRP-10359
        /*Date leastStartDate = null;
Date maxEndDate = null;
for(Id acctId : mapOfAcctsWithTeamMembers.keySet()){
for(AccountTeamMember actTeamMember :mapOfAcctsWithTeamMembers.get(acctId)){
if(leastStartDate == null || leastStartDate > actTeamMember.Start_Date__c){
leastStartDate = actTeamMember.Start_Date__c;
}
if(maxEndDate == null || maxEndDate < actTeamMember.End_Date__c){
maxEndDate = actTeamMember.End_Date__c;
}
}
}

List<Opportunity> listofOppties =[SELECT Id,ownerId,AccountId, Drive_Date__c, Account_Manager__c,Covering_Recruiter__c FROM Opportunity WHERE AccountId IN:mapOfAcctsWithTeamMembers.keySet() AND Drive_Date__c != null AND Drive_Date__c >= :leastStartDate AND Drive_Date__c <= :maxEndDate];
*/
        List<Account> accList = [select id,Account_Manager__c,District_manager__c from Account Where Id IN:mapOfAcctsWithTeamMembers.keySet()];
        //populateAmDMLookuponDelete(mapOfAcctsWithTeamMembers,accList);//HRP-11234
        /*if(listofOppties.isEmpty()){
insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='AccountTeamMemeberService',Method__c='addAcctTeamMembers_To_BloodDriveOpptyMembers',Type__c='Success',Error_Description__c='listofOppties empty');
Database.executeBatch(new BSF_Batch_OpportunityTeamMember(new List<OpportunityTeamMember>(),new List<OpportunityTeamMember>(),'Delete',true,countAccounts),100);
return;
}*/
        
        //HRP-8050
        Map<id,AccountTeamMember> oppIdCoverageAmMap = new  Map<id,AccountTeamMember>();
        oppIdCoverageAmMap = isCoverageAmPresent(mapOfAcctsWithTeamMembers,listofOppties);
        Map<id,AccountTeamMember> oppIdCoverageDmMap = new  Map<id,AccountTeamMember>();
        oppIdCoverageDmMap = isCoverageDmPresent(mapOfAcctsWithTeamMembers,listofOppties);
        Map<String,OpportunitySplit> opportunitySplitToInsertMap = new Map<String,OpportunitySplit>();
       	Set<String> oppIdUserIdSplitSet=new Set<String>();
        Map<Id,Opportunity> oppIdOpportunityMap = new Map<Id,Opportunity>();
        //----------------------------//	
        Map<Id,Id> oppWithOldOwnerIdMap = new Map<Id,Id>();	
        Map<id,List<String>> oppIdLookupPopulatedListMap = new Map<id,List<String>>();//HRP-11234
        //------------------------------//
        
        OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName='Overlay' ];//HRP-13340
        for(Opportunity opRecord:listofOppties)
        {
            oppIdOpportunityMap.put(opRecord.Id,opRecord);
            setOfOpptyIds.add(opRecord.Id);
            if(mapOfAcctsWithTeamMembers.containsKey(opRecord.AccountId))	
            {
                for(AccountTeamMember atmRecords:mapOfAcctsWithTeamMembers.get(opRecord.AccountId))
                {
                    acctTeamKeySet.add(opRecord.AccountId+':'+atmRecords.UserId);
                    
                    if(!oppWithOldOwnerIdMap.keyset().contains(opRecord.id))
                    {
                        oppWithOldOwnerIdMap.put(opRecord.id,opRecord.OwnerId);
                    }
                        		
                    
                    //-----------------------------------------------------------------//
                    if(opRecord.Drive_Date__c>=atmRecords.Start_Date__c && opRecord.Drive_Date__c<=atmRecords.End_Date__c && ((opRecord.Drive_Date__c < System.today() && atmRecords.is_Covering_recruiter__c) || opRecord.Drive_Date__c >= System.today())) //HRP-13340
                    { //HRP-10359 start
                        if(atmRecords.TeamMemberRole == 'Account Manager')
                        {
                            if(atmRecords.Is_Covering_Recruiter__c==false)
                            {
                                opRecord.OwnerId=atmRecords.UserId; //HRP-10359
                                if(atmRecords.BSF_Portfolio__c != NULL)
                                { //HRP-10359 start
                                    opRecord.Account_Manager_Portfolio__c = atmRecords.BSF_Portfolio__c;
                                } // HRP-10359 end
                                oppWithOwnerIdMap.put(opRecord.id,opRecord.OwnerId);
                                
                            }
                            //HRP-11234
                            if((oppIdCoverageAmMap==null || (oppIdCoverageAmMap.get(opRecord.id)==null || (oppIdCoverageAmMap.containsKey(opRecord.id) && oppIdCoverageAmMap.get(opRecord.id).UserId !=null && oppIdCoverageAmMap.get(opRecord.id).UserId!=opRecord.Account_Manager__c))))
                            
                            {
                                opRecord.Account_Manager__c=atmRecords.UserId; //HRP-10359
                            }
                            //HRP-11234
                            oppWithAccMangrIdMap.put(opRecord.id,opRecord.Account_Manager__c);
                            system.debug('opRecord '+opRecord);
                            oppIdVsAMDMPortfoliodMap.put(opRecord.id,opRecord); //HRP-10359
                            listofOpptiesOwnersToupdate.add(opRecord);
                            
                        } //HRP-10359 start
                        if(atmRecords.TeamMemberRole == 'District Manager' && (oppIdCoverageDmMap.get(opRecord.id)==null || (oppIdCoverageDmMap.get(opRecord.id).UserId !=null && oppIdCoverageDmMap.get(opRecord.id).UserId!=opRecord.District_Manager__c))){
                            if(atmRecords.Is_Covering_Recruiter__c==false){
                                if(atmRecords.BSF_Portfolio__c != NULL){
                                    opRecord.District_Manager_Portfolio__c = atmRecords.BSF_Portfolio__c;
                                }
                            }
                            opRecord.District_Manager__c=atmRecords.UserId;
                            system.debug('opRecord '+opRecord);
                            oppIdVsAMDMPortfoliodMap.put(opRecord.id,opRecord);
                            listofOpptiesOwnersToupdate.add(opRecord);
                            
                        } //HRP-10359 end
                        //HRP-11234 start
                        if(atmRecords.TeamMemberRole == 'Account Manager')
                        {
                            if(!oppIdLookupPopulatedListMap.containsKey(opRecord.id))
                                oppIdLookupPopulatedListMap.put(opRecord.id,new list<string>());
                            if(!atmRecords.Is_Covering_Recruiter__c)
                            oppIdLookupPopulatedListMap.get(opRecord.id).add('AM');
                            
                            if(atmRecords.Is_Covering_Recruiter__c)
                                oppIdLookupPopulatedListMap.get(opRecord.id).add('CovAM');
                            
                        }
                        if(atmRecords.TeamMemberRole == 'District Manager')
                        {
                            if(!oppIdLookupPopulatedListMap.containsKey(opRecord.id))
                                oppIdLookupPopulatedListMap.put(opRecord.id,new list<string>());
                            
                            oppIdLookupPopulatedListMap.get(opRecord.id).add('DM');
                        }
                        //HRP-11234 End
                        //setOfOpptyIds.add(opRecord.Id);
                        
                        OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                        optyTeamMemeberToAdd.OpportunityId = opRecord.Id;
                        optyTeamMemeberToAdd.TeamMemberRole = atmRecords.TeamMemberRole;
                        //HRP-11424 Start
                        if(!atmRecords.is_covering_recruiter__c && atmRecords.TeamMemberRole==BSF_Constants.ACCOUNT_MANAGER)
                        {
                            optyTeamMemeberToAdd.TeamMemberRole=BSF_Constants.OPPORTUNITY_OWNER;
                        }
                        //HRP-11424 End 
                        optyTeamMemeberToAdd.OpportunityAccessLevel = 'Edit';
                        optyTeamMemeberToAdd.UserId = atmRecords.UserId; 
                        optyTeamMemeberToAdd.is_AccountTeammember__c = true; //is_AccountTeammember__c = true
                        optyTeamMemberListToInsert.add(optyTeamMemeberToAdd);
                        opptyInsertTeamKeySet.add(opRecord.Id+':'+atmRecords.UserId);

                        //HRP-13340 start
                        if(atmRecords.Is_Covering_Recruiter__c)
                        {
                            OpportunitySplit splitCoveringRec = new OpportunitySplit();
                            splitCoveringRec.SplitTypeId = overlaySplitType.Id;
                            splitCoveringRec.OpportunityId = opRecord.Id;
                            splitCoveringRec.SplitOwnerId = atmRecords.UserId;
                            splitCoveringRec.SplitPercentage = 100;
                            splitCoveringRec.Split_Reason__c = atmRecords.Coverage_Reason__c==BSF_Constants.accTeamLoa? BSF_Constants.opSplitLoa:BSF_Constants.opSplitVacant;
                            splitCoveringRec.Is_Covering_Incentive__c = true;
                            oppIdUserIdSplitSet.add(splitCoveringRec.OpportunityId+':'+atmRecords.UserId);
                            opportunitySplitToInsertMap.put(splitCoveringRec.OpportunityId+':'+atmRecords.UserId,splitCoveringRec);
						}
                        //HRP-13340 end
                    } 
                }
            }
            
        }
        //commented part of HRP-11234 start
        /*
//HRP-8050
if(oppWithOwnerIdMap != null || oppWithAccMangrIdMap!= null)
{
TriggerHandler.bypass('OpportunityTriggerHandler');
OpportunityService.UpdateDriveOwnerOnOppOwnerUpdate(oppWithOwnerIdMap,oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap); //HRP-10359
TriggerHandler.clearBypass('OpportunityTriggerHandler');
}

//system.debug('opptyInsertTeamKeySet'+opptyInsertTeamKeySet);
if(!listofOpptiesOwnersToupdate.isEmpty()){
Map<Id,Opportunity> mapofOpptyOwnersToUpdate=new Map<Id,Opportunity>();
mapofOpptyOwnersToUpdate.putall(listofOpptiesOwnersToupdate);
OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
TriggerHandler.bypass('OpportunityTriggerHandler');
Database.SaveResult[] srList = Database.update(mapofOpptyOwnersToUpdate.values(), false);
TriggerHandler.clearBypass('OpportunityTriggerHandler');
for (Database.SaveResult sr : srList) {
if (!sr.isSuccess()) {
for(Database.Error err : sr.getErrors()) {
System.debug('The following error has occurred in AccountTeamMemberService.'+err);                    
System.debug('errorr are '+err.getStatusCode() + ': ' + err.getMessage());
System.debug(' fields that affected this error: ' + err.getFields());
}	

}
}
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','AccountTeamMemeberService','addAcctTeamMembers_To_BloodDriveOpptyMembers','Error','Error in updating Opp with Owner & AM');
InsertBsfErrorLog.insertBsfErrors(logList);
}*/
        //commented part of HRP-11234 end
        
        
        //HRP-11234 start
        map<string,OpportunityTeamMember> oppTeamToAdd = new map<string,OpportunityTeamMember>();
        listofOpptiesOwnersToupdate.addAll(AccountPortfolioAssignmentService.systemUserAsOwner(listofOppties,oppIdLookupPopulatedListMap,oppTeamToAdd,false,oppWithOwnerIdMap,oppIdVsAMDMPortfoliodMap));
        optyTeamMemberListToInsert.addAll(oppTeamToAdd.values());
        oppLookupUpdates(oppWithOwnerIdMap,oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap,listofOpptiesOwnersToupdate,oppWithOldOwnerIdMap);
        //HRP-11234 end
        if(!setOfOpptyIds.isEmpty() )
        {

            //HRP-13340
            Map<String,OpportunitySplit> oppIdUserIdOppSplitMap=new Map<String,OpportunitySplit>();
            Map<String,OpportunitySplit> oppIdUserIdOppSplitDelMap = new Map<String,OpportunitySplit>();
            List<OpportunitySplit> oppSplitList = [SELECT OpportunityId,SplitTypeId,SplitOwnerId,SplitPercentage FROM OpportunitySplit WHERE SplitTypeId =: overlaySplitType.Id AND Is_Covering_Incentive__c = true AND OpportunityId IN:setOfOpptyIds];
            for(OpportunitySplit oppSplit :oppSplitList)
            {
                oppIdUserIdOppSplitMap.put(oppSplit.OpportunityId+':'+oppSplit.SplitOwnerId,oppSplit);
            }
            
            for(String s : oppIdUserIdOppSplitMap.KeySet())
            {
                if (!opportunitySplitToInsertMap.containsKey(s)) 
                {

                    oppIdUserIdOppSplitDelMap.put(s,oppIdUserIdOppSplitMap.get(s));
                }
                else
                {
                    opportunitySplitToInsertMap.remove(s);
                }
            }
            
            List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
            if(!oppIdUserIdOppSplitDelMap.Values().isEmpty())
            {
                OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                Database.deleteResult[] drList = Database.delete(oppIdUserIdOppSplitDelMap.Values(),false);
                logList.addAll(BSF_Utilities.createErrorLog(drList, 'Populate Account Team','AccountTeamMemeberService','addAcctTeamMembers_To_BloodDriveOpptyMembers','Error','Error in deleting Oppsplit Overlay'));
                
            }

            if(!opportunitySplitToInsertMap.Values().isEmpty())
            {
                OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                Database.SaveResult[] srList = Database.insert(opportunitySplitToInsertMap.Values(),false);
                logList.addAll(BSF_Utilities.createErrorLog(srList, 'Populate Account Team','AccountTeamMemeberService','addAcctTeamMembers_To_BloodDriveOpptyMembers','Error','Error in creating Oppsplit Overlay'));
                
            }

            if(!logList.isEmpty())
            {
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            //HRP-13340
            Map<Id,List<OpportunityTeamMember>> mapOfOpptyIdsWithTeamMembers=new Map<Id,List<OpportunityTeamMember>>();
            //List<OpportunityTeamMember> optyTeamMemberNotExistListToInsert = new List<OpportunityTeamMember>();
            //List<OpportunityTeamMember> listOfOpptyTeamMembersTodelete = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> listOfOpptyTeamMembers = [select Id,OpportunityId,Opportunity.AccountId,user.name,TeamMemberRole,OpportunityAccessLevel,UserId,is_AccountTeammember__c from OpportunityTeamMember where OpportunityId IN:setOfOpptyIds ];
            for(OpportunityTeamMember opTeamMember :listOfOpptyTeamMembers)
            {
                if(!mapOfOpptyIdsWithTeamMembers.containsKey(opTeamMember.OpportunityId))
                {
                    mapOfOpptyIdsWithTeamMembers.put(opTeamMember.OpportunityId,new List<OpportunityTeamMember>());
                }
                mapOfOpptyIdsWithTeamMembers.get(opTeamMember.OpportunityId).add(opTeamMember); 
            }
            
            
            
            for(Id oppId:mapOfOpptyIdsWithTeamMembers.keySet())
            {
                //HRP-13340
                Boolean isFutureDrive = false;
                if(oppIdOpportunityMap != Null && oppIdOpportunityMap.containsKey(oppId))
                {
                    if(oppIdOpportunityMap.get(oppId).Drive_Date__c >= System.Today())
                    {
                        isFutureDrive = true;
                    }
                            
                }
                //HRP-13340
                for(OpportunityTeamMember opTeamMember:mapOfOpptyIdsWithTeamMembers.get(oppId))
                {
                    if((isFutureDrive || ( !isFutureDrive && oppIdUserIdOppSplitDelMap.KeySet().contains(oppId+':'+opTeamMember.userId))))//HRP-13340
                    {
                        if(!opptyInsertTeamKeySet.contains(oppId+':'+opTeamMember.UserId) )
                        {
                            if(opTeamMember.TeamMemberRole == BSF_Constants.OPPORTUNITY_OWNER || opTeamMember.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER)
                            {
                                listOfOpptyTeamMembersTodelete.add(opTeamMember);
                            }
                            else if(opTeamMember.is_AccountTeammember__c)
                            {
                                listOfOpptyTeamMembersTodelete.add(opTeamMember);
                            }
                        }
                    }
                }
            }
            for(OpportunityTeamMember opTeamMembers:optyTeamMemberListToInsert)
            {
                if(mapOfOpptyIdsWithTeamMembers.containsKey(opTeamMembers.OpportunityId))
                {
                    Map<Id,OpportunityTeamMember> mapOfUserIds=new Map<Id,OpportunityTeamMember>();
                    for(OpportunityTeamMember opTeamMember:mapOfOpptyIdsWithTeamMembers.get(opTeamMembers.OpportunityId))
                    {
                        mapOfUserIds.put(opTeamMember.UserId,opTeamMember);
                    }
                    if((!mapOfUserIds.containsKey(opTeamMembers.UserId) || mapOfUserIds.get(opTeamMembers.UserId).TeamMemberRole == null || mapOfUserIds.get(opTeamMembers.UserId).TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER || mapOfUserIds.get(opTeamMembers.UserId).TeamMemberRole == BSF_Constants.OPPORTUNITY_OWNER || mapOfUserIds.get(opTeamMembers.UserId).OpportunityAccessLevel == 'Read Only' || mapOfUserIds.get(opTeamMembers.UserId).userId==oppWithOwnerIdMap.get(opTeamMembers.UserId)
                            || opTeamMembers.TeamMemberRole != mapOfUserIds.get(opTeamMembers.UserId).TeamMemberRole))//HRP-11234 added Account Manager & Opportunity Owner checks
                    {
                        opTeamMembers.is_AccountTeammember__c = true; //is_AccountTeammember__c = true
                        optyTeamMemberNotExistListToInsert.add(opTeamMembers);                  
                    }			 
                }
            }
            //commented part of HRP-11234 start
            /*
opportunityService.UpdateOwnerSplit(listofOpptiesOwnersToupdate);

//----------------------------------------------------//
//-------------------------------------------------------------------------//	
OpportunitySplitType oppSplitType = [SELECT Id, DeveloperName FROM OpportunitySplitType WHERE DeveloperName = 'Revenue' ];		
List<OpportunitySplit> oppSplit = [SELECT id,OpportunityId,SplitOwnerId,opportunity.ownerId FROM OpportunitySplit WHERE Opportunity.stageName IN ('Withdrawn','Excluded','Cancelled','Closed') AND SplitOwnerId IN: oppWithOldOwnerIdMap.values() AND SplitTypeId = : oppSplitType.Id AND OpportunityId IN :  oppWithOldOwnerIdMap.keySet()];		
List<OpportunitySplit> oppDeleteList = new List<OpportunitySplit>();		
for(opportunitySplit os : oppSplit){		
if(oppWithOldOwnerIdMap.get(os.opportunityId) == os.SplitOwnerId && oppWithOwnerIdMap.get(os.OpportunityId) != os.SplitOwnerId && os.SplitOwnerId!=os.opportunity.ownerId){		
oppDeleteList.add(os);	
system.debug(os.opportunityId+'_'+os.SplitOwnerId);
}	
} 		
Database.delete(oppDeleteList,false);	
//------------------------------------------------//
insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='AccountTeamMemeberService',Method__c='addAcctTeamMembers_To_BloodDriveOpptyMembers',Type__c='Success',Error_Description__c='Batch Execute In If');
//Database.executeBatch(new BSF_Batch_OpportunityTeamMember(listOfOpptyTeamMembersTodelete,optyTeamMemberNotExistListToInsert,'Delete',true,countAccounts),100);*/
            //commented part of HRP-11234 end
        }
        else{	
            insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='AccountTeamMemeberService',Method__c='addAcctTeamMembers_To_BloodDriveOpptyMembers',Type__c='Success',Error_Description__c='Batch Execute In Else');
            //Database.executeBatch(new BSF_Batch_OpportunityTeamMember(new List<OpportunityTeamMember>(),new List<OpportunityTeamMember>(),'Delete',true),100);	
            //Database.executeBatch(new BSF_Batch_OpportunityTeamMember(new List<OpportunityTeamMember>(),new List<OpportunityTeamMember>(),'Delete',true,countAccounts),100);
        }
        
        /* if(!optyTeamMemberListToInsert.isEmpty() && accTeamUpdated == false  ){ 
insert optyTeamMemberListToInsert;	
}
*/
        
    }
    /*
* Method Implemented part of HRP-11234 start
* populates drive record owner and assigns split values for Owner of opportunity 
* */
    public static void oppLookupUpdates(Map<Id,Id> oppWithOwnerIdMap,Map<Id,Id> oppWithAccMangrIdMap,Map<Id,Opportunity> oppIdVsAMDMPortfoliodMap,list<Opportunity> listofOpptiesOwnersToupdate,Map<Id,Id> oppWithOldOwnerIdMap)
    {
        //HRP-8050
        if(oppWithOwnerIdMap != null || oppWithAccMangrIdMap!= null)
        {
            TriggerHandler.bypass('OpportunityTriggerHandler');
            OpportunityService.UpdateDriveOwnerOnOppOwnerUpdate(oppWithOwnerIdMap,oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap); //HRP-10359
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
        }
        
        //system.debug('opptyInsertTeamKeySet'+opptyInsertTeamKeySet);
        if(!listofOpptiesOwnersToupdate.isEmpty()){
            Map<Id,Opportunity> mapofOpptyOwnersToUpdate=new Map<Id,Opportunity>();
            mapofOpptyOwnersToUpdate.putall(listofOpptiesOwnersToupdate);
            OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
            TriggerHandler.bypass('OpportunityTriggerHandler');
            Database.SaveResult[] srList = Database.update(mapofOpptyOwnersToUpdate.values(), false);
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
            
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','AccountTeamMemeberService','addAcctTeamMembers_To_BloodDriveOpptyMembers','Error','Error in updating Opp with Owner & AM');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
        
        
        
        opportunityService.UpdateOwnerSplit(listofOpptiesOwnersToupdate);
        
        OpportunitySplitType oppSplitType = [SELECT Id, DeveloperName FROM OpportunitySplitType WHERE DeveloperName = 'Revenue' ];		
        List<OpportunitySplit> oppSplit = [SELECT id,OpportunityId,SplitOwnerId,opportunity.ownerId FROM OpportunitySplit WHERE Opportunity.stageName IN ('Withdrawn','Excluded','Cancelled','Closed') AND SplitOwnerId IN: oppWithOldOwnerIdMap.values() AND SplitTypeId = : oppSplitType.Id AND OpportunityId IN :  oppWithOldOwnerIdMap.keySet()];		
        List<OpportunitySplit> oppDeleteList = new List<OpportunitySplit>();		
        for(opportunitySplit os : oppSplit){		
            if(oppWithOldOwnerIdMap.get(os.opportunityId) == os.SplitOwnerId && oppWithOwnerIdMap.get(os.OpportunityId) != os.SplitOwnerId && os.SplitOwnerId!=os.opportunity.ownerId){		
                oppDeleteList.add(os);	
                system.debug(os.opportunityId+'_'+os.SplitOwnerId);
            }	
        } 		
        Database.delete(oppDeleteList,false);	
    }
    
      //HRP-11234 End 
     public static map<id,AccountTeamMember> isCoverageAmPresent(Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers,List<Opportunity> listofOppties)
    {
        map<id,AccountTeamMember> oppIdCoverageAmMap = new  map<id,AccountTeamMember>();
        
        for(Opportunity opp:listofOppties)
        {
            if(mapOfAcctsWithTeamMembers.get(opp.AccountId)!=null)
            {
                for(AccountTeamMember atmRecords:mapOfAcctsWithTeamMembers.get(opp.AccountId))
                {
                     if(atmRecords.TeamMemberRole == 'Account Manager' && atmRecords.Is_Covering_Recruiter__c==true)
                     {
                        if(opp.Drive_Date__c>=atmRecords.Start_Date__c && opp.Drive_Date__c<=atmRecords.End_Date__c)
                        {
                            oppIdCoverageAmMap.put(opp.id,atmRecords);
                            system.debug('oppIdCoverageAmMap'+oppIdCoverageAmMap);
                        }
                	 }
                
                 }
             }
        }
        
            return oppIdCoverageAmMap;
        
        
    }
    
    //HRP-10359 Start
    public static map<id,AccountTeamMember> isCoverageDmPresent(Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers,List<Opportunity> listofOppties)
    {
        system.debug('mapOfAcctsWithTeamMembers '+mapOfAcctsWithTeamMembers);
        map<id,AccountTeamMember> oppIdCoverageDmMap = new  map<id,AccountTeamMember>();
        
        for(Opportunity opp:listofOppties)
        {
            if(mapOfAcctsWithTeamMembers.get(opp.AccountId)!=null)
            {
                for(AccountTeamMember atmRecords:mapOfAcctsWithTeamMembers.get(opp.AccountId))
                {
                    if(atmRecords.TeamMemberRole == 'District Manager' && atmRecords.Is_Covering_Recruiter__c==true)
                    {
                        if(opp.Drive_Date__c>=atmRecords.Start_Date__c && opp.Drive_Date__c<=atmRecords.End_Date__c)
                        {
                            oppIdCoverageDmMap.put(opp.id,atmRecords);
                            system.debug('oppIdCoverageDmMap'+oppIdCoverageDmMap);
                        }
                    }
                    
                }
            }
        }
        
        return oppIdCoverageDmMap;
        
        
    } //HRP-10359 end
    
   /*retired part of HRP-11234
    public static void populateAmDMLookuponDelete(Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers,List<Account> accList)
    {
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        for(Account acc : accList)
        {
            if(mapOfAcctsWithTeamMembers.get(acc.Id) == null || mapOfAcctsWithTeamMembers.get(acc.Id).size() == 0){
                continue;
            }
            for(AccountTeamMember atm : mapOfAcctsWithTeamMembers.get(acc.Id))
            {
                if(atm.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER || atm.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER){
                    atmList.add(atm);
                }
            }
        }
        
        if(!atmList.isEmpty()){
            
            TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
            //updateAccountOnTeammeberAssignment(atmList,null);
            TriggerHandler.clearBypass('AccountTeamMemberTriggerHandler');
        }
    }*/
    
    public static void updateAccountOnTeammeberAssignment(List<AccountTeamMember> newAccountTeamMembers,Map<Id,AccountTeamMember> oldMap)
    {
        list<id> accId = new list<id>();
        for(AccountTeamMember atm :newAccountTeamMembers)
        {
            if((oldMap==null ||(oldMap!=null && (oldMap.get(atm.id).start_date__c!=atm.Start_Date__c || oldMap.get(atm.id).End_date__c!=atm.End_date__c))) &&(atm.teamMemberRole == bsf_constants.ACCOUNT_MANAGER || atm.teamMemberRole == bsf_constants.DISTRICT_MANAGER))//HRP-11234
            {
                accId.add(atm.AccountId);
            }
        }
        
        AccountTeamMemberHelper.getAccountTeamMembers(accId);
    }
    
    //HRP-8897 New Method
    public static void dateCheckbeforeInsertUpdate(list<AccountTeamMember> atmList,map<id,AccountTeamMember> oldMap)
    {
        list<id> accIdList = new list<id>();
        
        for(AccountTeamMember atm :atmList)
        {
            if(!accIdList.contains(atm.accountid) && (oldMap==null ||(oldMap!=null && (atm.Start_Date__c != oldMap.get(atm.id).start_date__c || atm.End_date__c != oldMap.get(atm.id).End_date__c))))
            {
                accIdList.add(atm.accountid);
            }
        }
        
        
        for(AccountTeamMember atm:atmList)
        {
            String key = atm.AccountId+'_'+atm.userid;
            if(!(atm.Is_Covering_Recruiter__c && atm.End_Date__c>system.today()))//HRP-6028
            {
                if(accIdUserDate.containsKey(Key))
                {
                    AccountTeamMember acctm = accIdUserDate.get(key);
                    if(atm.Start_Date__c != acctm.Start_Date__c)
                    {
                        atm.Start_Date__c = acctm.Start_Date__c;
                    }
                    if(atm.End_Date__c != acctm.End_Date__c)
                    {
                        atm.End_Date__c = acctm.End_Date__c;
                    }
                    if(atm.BSF_Portfolio__c != acctm.BSF_Portfolio__c)
                    {
                        atm.BSF_Portfolio__c = acctm.BSF_Portfolio__c;
                    }
                    atm.Is_Covering_Recruiter__c=false;//HRP-11919
                    atm.Coverage_Reason__c=null;//HRP-11919
                }
            }
        }
        
    }
    
    /*Method added for HRP-11281 logic for opportunityTeam Recalculation for covering Recruiter
     *Added by Balaji N
     * */
    /* commented part of HRP-13340
    public static void coveringRecruiterOpptyTeamonPastOpp(list<AccountTeamMember> atmList,map<id,AccountTeamMember> oldMap)
    {
        system.debug('coveringRecruiterOpptyTeamonPastOpp');
		map<id,list<AccountTeamMember>> accIdAccTeamMap = new map<id,list<AccountTeamMember>>();
        map<String,AccountTeamMember> accIdAccTeam4SplitMap = new map<String,AccountTeamMember>();
        set<id> accIdSet = new set<id>();
        set<id> userIdSet = new set<id>();
        Date startDate;
        Date endDate;
        for(AccountTeamMember atm:atmList)
        {
            accIdSet.add(atm.accountId);
            //if covering Recruiter and change in dates then eligible
            if(atm.Is_Covering_Recruiter__c && ((oldMap!=null && (atm.Start_Date__c!= oldMap.get(atm.id).Start_Date__c || atm.End_Date__c!=oldMap.get(atm.id).End_Date__c)) || oldMap==null))
            {
            	if(!accIdAccTeamMap.containskey(atm.accountId))
                	accIdAccTeamMap.put(atm.accountId,new list<AccountTeamMember>());
            
            	accIdAccTeamMap.get(atm.accountId).add(atm);
            }
            if(!atm.Is_Covering_Recruiter__c && (oldMap!=null && (atm.Is_Covering_Recruiter__c!= oldMap.get(atm.id).Is_Covering_Recruiter__c)))
            {
                accIdAccTeam4SplitMap.put(atm.accountId+':'+atm.UserId,oldMap.get(atm.id));//HRP-11234 replaced new value with old value in map value
            
            	userIdSet.add(atm.UserId);
            }
            
            Date atmStartDate = oldMap == null || atm.Start_Date__c <= oldMap.get(atm.id).Start_Date__c? atm.Start_Date__c:oldMap.get(atm.id).Start_Date__c;
            Date atmEndDate =  oldMap == null || atm.End_Date__c >= oldMap.get(atm.id).End_Date__c? atm.End_Date__c:oldMap.get(atm.id).End_Date__c;
            
            if(startDate == null || (startDate != null && atmStartDate < startDate))
            {
                startDate = atmStartDate;
            }
            
            if(endDate == null || (endDate != null && atmEndDate > endDate))
            {
                endDate = atmEndDate;
            }
                
        }
        
        
        list<opportunitySplit> OpptySplitList = [Select id,splitOwnerId,OpportunityID,Opportunity.drive_Date__c,Opportunity.accountId from opportunitySplit where opportunity.AccountId in:accIdSet and splitOwnerId in :userIdSet and splitType.developerName='Overlay'];
        list<opportunitySplit> opptySplitDelList = new list<opportunitySplit>();
        for(opportunitySplit os :OpptySplitList)
        {
            string key=os.Opportunity.accountId+':'+os.splitOwnerId;
			if(accIdAccTeam4SplitMap.containskey(key) && accIdAccTeam4SplitMap.get(key).start_date__c <= os.Opportunity.drive_Date__c && accIdAccTeam4SplitMap.get(key).End_date__c >= os.Opportunity.drive_Date__c)
            {
                 opptySplitDelList.add(os);
            }
        }
        
        
        list<opportunity> oppList =[Select id,Drive_Date__c,Account_Manager__c,accountId,ownerId from opportunity where AccountId in:accIdSet AND Is_Template__c=false AND Drive_date__c < Today AND Drive_Date__c >= :startDate  AND Drive_Date__c <= :endDate];//HRP-13174
        map<string,opportunityTeamMember> opptyTeamMap = new map<string,opportunityTeamMember>();
        list<opportunityTeamMember> opptyTeamMemberList = [Select id,UserId,OpportunityID,TeamMemberRole from opportunityTeamMember where opportunity.AccountId in:accIdSet and is_AccountTeammember__c=true];
        for(opportunityTeamMember otm :opptyTeamMemberList)
        {
			opptyTeamMap.put(otm.opportunityId+':'+otm.userid,otm);            
        }
        
        list<opportunityTeamMember> opptyTeamListToInsert = new list<opportunityTeamMember>();
        list<opportunityTeamMember> opptyTeamListToDelete = new list<opportunityTeamMember>();
        list<opportunity> opptyAMUpdateList = new list<opportunity>();
        for(opportunity opp:oppList)
        {
            if(accIdAccTeamMap.containsKey(opp.accountId))
            {
            for(AccountTeamMember atm : accIdAccTeamMap.get(opp.accountId))
            {
                AccountTeamMember oldAtm = new AccountTeamMember();
                    if(oldMap != null)
                        oldAtm=oldMap.get(atm.id);
                //identify opportunities affected by date change- covered newly
                if((oldMap != null && opp.Drive_Date__c<System.today() && 
                    ((atm.Start_Date__c<oldAtm.start_date__c && atm.Start_Date__c<=opp.Drive_Date__c && oldAtm.start_date__c>=opp.Drive_Date__c) ||
                    (atm.End_date__c>oldAtm.End_date__c && atm.End_date__c>=opp.Drive_Date__c && oldAtm.End_date__c<=opp.Drive_Date__c))) ||(oldMap==null && atm.Start_Date__c<=opp.Drive_Date__c && atm.End_date__c>=opp.Drive_Date__c))
                {
                    if(!opptyTeamMap.containskey(opp.id+':'+atm.userId))
                    {
                        OpportunityTeamMember optyTeamMemeberToAdd = new OpportunityTeamMember();
                        optyTeamMemeberToAdd.OpportunityId = opp.Id;
                        optyTeamMemeberToAdd.TeamMemberRole = atm.TeamMemberRole;
                        optyTeamMemeberToAdd.OpportunityAccessLevel = 'Edit';
                        optyTeamMemeberToAdd.UserId = atm.UserId; 
                        optyTeamMemeberToAdd.is_AccountTeammember__c = true;
                        opptyTeamListToInsert.add(optyTeamMemeberToAdd);
                        if(optyTeamMemeberToAdd.TeamMemberRole==bsf_constants.ACCOUNT_MANAGER)
                        {
                            opp.Account_Manager__c = optyTeamMemeberToAdd.UserId;
                         	opptyAMUpdateList.add(opp);
                        }
                            
                    }
                }
                //identify opportunities affected by date change- moved out
                else if(oldMap != null && 
                        ((atm.Start_Date__c>oldAtm.start_date__c && oldAtm.Start_Date__c<=opp.Drive_Date__c && atm.start_date__c>=opp.Drive_Date__c) ||
                        (atm.End_date__c<oldAtm.End_date__c && oldAtm.End_date__c>=opp.Drive_Date__c && atm.End_date__c<=opp.Drive_Date__c)))
                {
                    if(opptyTeamMap.containskey(opp.id+':'+atm.userId))
                    {
                        if(opptyTeamMap.get(opp.id+':'+atm.userId).TeamMemberRole==bsf_constants.ACCOUNT_MANAGER)
                        {
                            opp.Account_Manager__c = opp.ownerId;
                            opptyAMUpdateList.add(opp);
                        }
                        opptyTeamListToDelete.add(opptyTeamMap.get(opp.id+':'+atm.userId));
					}
                }
            }
            }
        }
        
        if(!opptyTeamListToInsert.isEmpty())
            Database.insert(opptyTeamListToInsert,false);
        
        if(!opptyTeamListToDelete.isEmpty())
            Database.Delete(opptyTeamListToDelete,false);
        
        if(!opptySplitDelList.isEmpty())
            Database.Delete(opptySplitDelList,false);
            
        if(!opptyAMUpdateList.isEmpty())
        {
            //just the lookup update,no need for Trigger
            triggerHandler.bypass('OpportunityTriggerHandler');
             Database.update(opptyAMUpdateList,false);
            triggerHandler.clearBypass('OpportunityTriggerHandler');
        }
           
    }
    commented part of HRP-13340 */
    /* 
 * HRP-11424 changes starts here
 * @Description: trigger method called on After Delete, blocks delete of account team part of portfolio
 * @Date: 02/08/2024
*/
    public static void stopDeletingNonCRTeamMemberFromUI(List<AccountTeamMember> deletedTeamMembers)
    {
        if(!bsf_constants.isTeamMemberCreatedFromBackend)
        {
            Profile userProfile = [select name,id from profile where id=:userinfo.getProfileId() limit 1];
            for(AccountTeamMember atm :deletedTeamMembers)
            {
                if(!atm.is_covering_recruiter__c && !System.Label.Account_Portfolio_Account_team_Delete_Permission.contains(userProfile.name))
                    atm.addError('You cannot delete a User from Account Team which is not a covering Recruiter. Since its managed in accordance with Portfolio assignments');
            }
        }
    }
}