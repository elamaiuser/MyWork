/***
 *  AccountPortfolioAssignmentHelper class.
 *  This Helper class would be called from a batch when new GOATS Bio Recruitment data is received into BSF. It creates
 *  Account to BSF Portfolio Assignment records for each account as per start date/end date of taxonomy data and populates account team.
 */
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 08/29/2023				  Balaji N					 Logic for HRP-10888(assignAccountToPortfolio Method: null check on supervisor)
* 11/09/2023				  Balaji N					 Logic for HRP-11290(Method Name: assignAccountToPortfolio;Supervisor Date check)
* 02/13/2024                  Priti Jana                 Logic for HRP-12087
* 08/01/2024				  Balaji N					 Logic for HRP-12485(Method:assignAccountToPortfolio,Accounts coverd by exception)
* 11/26/2024                  Balaji N                   Logic for HRP-13866 Method:assignAccountToPortfolio System.Label.NO_SBPM_ABM in place of hard coded value
*****************************************************************************
*/
public with sharing class AccountPortfolioAssignmentHelper {
    
    /* HRP-1707 */
    
    public static void processTaxonomyData(Decimal taxoVerKey){
        
        AccountPortfolioAssignmentHelper protfolioHelper = new AccountPortfolioAssignmentHelper();
        
        List<Taxonomy__c> taxonomyRecords = [SELECT Zip_Code__c ,Start_Date__c,End_Date__c,Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                             Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,
                                             RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
                                             FROM Taxonomy__c WHERE Version_Key__c = :taxoVerKey AND RecordType.Name = :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE ];
        
        protfolioHelper.assignAccountToPortfolio(taxonomyRecords,null);
    }
    
    public void assignAccountToPortfolio(List<Taxonomy__c> taxonomyRecords,List<Account> accountList){
        List<String> zipCodes = new List<String>();
        Map<String,String> zipPortfolioKeyMap = new Map<String,String>();
        Map<String,BSF_Portfolio__c> portfolioMap = new Map<String,BSF_Portfolio__c>();
        Map<String,Taxonomy__c> zipTaxonomyMap = new Map<String,Taxonomy__c>();
        Map<String,List<Portfolio_Assignment__c>> portfolioUserMap = new Map<String,List<Portfolio_Assignment__c>>();
        Map<Id,List<AccountTeamMember>> accountTeamMap = new Map<Id,List<AccountTeamMember>>();
        List<AccountTeamMember> accTeamInsertList = new List<AccountTeamMember>();
        List<AccountTeamMember> accTeamUpdateList = new List<AccountTeamMember>();
        List<AccountTeamMember> accTeamDeleteList = new List<AccountTeamMember>();
        
        List<Account_Portfolio_Assignment__c> insertList = new List<Account_Portfolio_Assignment__c>();
        List<Account_Portfolio_Assignment__c> updateList = new List<Account_Portfolio_Assignment__c>();
        //Set<String> superAMCodeSet = new Set<String>();//HRP-12485

        for(Taxonomy__c taxoRecord:taxonomyRecords){
            zipCodes.add(taxoRecord.Zip_Code__c);
            zipTaxonomyMap.put(taxoRecord.Zip_Code__c,taxoRecord);
            if(taxoRecord.ABM_Name__c != null && taxoRecord.ABM_Name__c != 'NA' && !taxoRecord.ABM_Name__c.containsIgnoreCase(System.Label.NO_SBPM_ABM)){//HRP-13866 System.Label.NO_SBPM_ABM in place of hard coded value
            	zipPortfolioKeyMap.put(taxoRecord.Zip_Code__c,taxoRecord.RecordType.Name+'_'+taxoRecord.Division_Code__c +'_'+taxoRecord.DS_Region_Code__c+'_'+taxoRecord.Team_Code__c+'_'+taxoRecord.ABM_Code__c+'_'+taxoRecord.DRD_Territory_Code__c);
            }else{
                zipPortfolioKeyMap.put(taxoRecord.Zip_Code__c,taxoRecord.RecordType.Name+'_'+taxoRecord.Division_Code__c +'_'+taxoRecord.DS_Region_Code__c+'_'+taxoRecord.Team_Code__c+'_'+taxoRecord.DRD_Territory_Code__c);
            }
            //superAMCodeSet.add(taxoRecord.DRD_Territory_Code__c);
        }
        /*commented part of HRP-12485
        //Supervisor Taxonomy records - Start
        //Set<String> supervisorTaxoKey = new Set<String>();
        //Map<String,List<String>> supervisorTaxoMap = new Map<String,List<String>>();
        //Map<String,Taxonomy__c> suprKeyTaxo = new Map<String,Taxonomy__c>();
        
        List<Taxonomy__c> supervisorTaxoRecords = [SELECT Zip_Code__c ,Start_Date__c,End_Date__c,Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                             Team_Code__c,Team_Key__c,Team_Name__c,Type_Key__c,Type__c,RecordType.Name,Supervisor_Code__c,Supervisor_Name__c
                                             FROM Taxonomy__c WHERE End_Date__c >= TODAY AND DRD_Territory_Code__c IN :superAMCodeSet AND RecordType.Name = :BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE   Order By Start_Date__c];
        
        for(Taxonomy__c superTaxo:supervisorTaxoRecords){
           String key = superTaxo.RecordType.Name+'_'+superTaxo.Division_Code__c +'_'+superTaxo.DS_Region_Code__c+'_'+superTaxo.Team_Code__c+'_'+superTaxo.Supervisor_Code__c+'_'+superTaxo.DRD_Territory_Code__c;
            if(!supervisorTaxoKey.contains(key)){
                if(!supervisorTaxoMap.containsKey(superTaxo.DRD_Territory_Code__c)){
                    supervisorTaxoMap.put(superTaxo.DRD_Territory_Code__c,new List<String>());
                }
                supervisorTaxoMap.get(superTaxo.DRD_Territory_Code__c).add(key);
                supervisorTaxoKey.add(key);
            } 
            suprKeyTaxo.put(key,superTaxo);
        }
		commented part of HRP-12485*/
        //Supervisor Taxonomy records - End
        List<String> externalKeys = new List<String>();
        externalKeys.addAll(zipPortfolioKeyMap.values());
        //externalKeys.addAll(supervisorTaxoKey);
        
        List<Account> accts = new List<Account>();
        if(accountList != null && accountList.size() > 0){
        	accts = [Select Id,Name,BillingPostalCode,(Select Id,Account__c,Name,Start_Date__c,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.External_Key__c,BSF_Portfolio__r.Taxonomy_Type__c  FROM AccountPortfolioAssignments__r WHERE END_DATE__c >= TODAY AND BSF_Portfolio__r.Portfolio_Type__c='Account Manager' AND  BSF_Portfolio__r.Taxonomy_Type__c!=:BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE ORDER BY Start_Date__c) FROM Account WHERE Id IN :accountList]; //HRP-12485 removed Account_AM_Portfolio_Type__c;End_date_c>=Today    
        }else{
            accts = [Select Id,Name,BillingPostalCode,(Select Id,Account__c,Name,Start_Date__c,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.External_Key__c,BSF_Portfolio__r.Taxonomy_Type__c  FROM AccountPortfolioAssignments__r WHERE END_DATE__c >= TODAY AND BSF_Portfolio__r.Portfolio_Type__c='Account Manager' AND  BSF_Portfolio__r.Taxonomy_Type__c!=:BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE ORDER BY Start_Date__c) FROM Account WHERE BillingPostalCode IN :zipCodes];//HRP-12485 removed Account_AM_Portfolio_Type__c;End_date_c>=Today
        }
        
        Map<Id,Account> superAcctAssmts = new Map<Id,Account>([Select Id,Name,BillingPostalCode,(Select Id,Name,Start_Date__c,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.External_Key__c  FROM AccountPortfolioAssignments__r WHERE END_DATE__c > TODAY AND BSF_Portfolio__r.Account_Based_Portfolio__c = TRUE ORDER BY Start_Date__c) FROM Account WHERE ID IN :accts]);
        
        //for(String extKey:externalKeys)
        
        
        List<BSF_Portfolio__c> portfolios = [Select Id,Name,External_Key__c,External_Key_BackEnd__c,Portfolio_Code__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c,Territory_Portfolio__c,start_date__c,End_date__c FROM BSF_Portfolio__c WHERE External_Key_BackEnd__c IN :externalKeys AND Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER order by createdDate desc];
        List<String> teamRoleList = new List<String>();
        teamRoleList.add(BSF_Constants.ACCOUNT_MANAGER);
        teamRoleList.add(BSF_Constants.AREA_BOOKING_MANAGER);
        teamRoleList.add(BSF_Constants.DISTRICT_MANAGER);
        teamRoleList.add(BSF_Constants.SUPERVISOR);
        
        List<AccountTeamMember> accountTeamList = [Select Id, UserId ,TeamMemberRole ,Start_Date__c ,End_Date__c ,AccountId FROM AccountTeamMember WHERE AccountId IN :accts AND TeamMemberRole IN :teamRoleList   ORDER BY Start_Date__c ];
        
        for(AccountTeamMember teamMember:accountTeamList){
            if(accountTeamMap.get(teamMember.AccountId) == null){
                accountTeamMap.put(teamMember.AccountId,new List<AccountTeamMember>());
            }
            accountTeamMap.get(teamMember.AccountId).add(teamMember);
        }
        
        Set<Id> portfolioIds = new Set<Id>();
        for(BSF_Portfolio__c portfolio:portfolios){
            if(!portfolioMap.keyset().contains(portfolio.External_Key_BackEnd__c))
            {
            portfolioMap.put(portfolio.External_Key_BackEnd__c,portfolio);
            }
            if(portfolio.Territory_Portfolio__c  == TRUE){
                portfolioIds.add(portfolio.Id); //AM ID
                portfolioIds.add(portfolio.Parent_Portfolio__c); //ABM ID
                portfolioIds.add(portfolio.Parent_Portfolio__r.Parent_Portfolio__c); //DM ID
            }else if(portfolio.Territory_Portfolio__c  == FALSE){
                portfolioIds.add(portfolio.Parent_Portfolio__c);//Supervisor ID
            }
        }
        
        List<Portfolio_Assignment__c> portFolioUsers = [Select Id,Name, User__c ,Start_Date__c ,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c  FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN :portfolioIds AND End_Date__c > TODAY   ORDER BY Start_Date__c ];
        
        for(Portfolio_Assignment__c portfolioUser:portFolioUsers){
            if(portfolioUserMap.get(portfolioUser.BSF_Portfolio__c) == null){
                portfolioUserMap.put(portfolioUser.BSF_Portfolio__c,new List<Portfolio_Assignment__c>());
            }
        	portfolioUserMap.get(portfolioUser.BSF_Portfolio__c).add(portfolioUser);        
        }
        
        
        
        
        for(Account acct:accts){
        
            BSF_Portfolio__c portfolio = portfolioMap.get(zipPortfolioKeyMap.get(acct.BillingPostalCode));
            Taxonomy__c taxoRecord = zipTaxonomyMap.get(acct.BillingPostalCode);
            Boolean isABMAvaialable = false;
            
            
            if(portfolio == null || taxoRecord == null || taxoRecord.Start_Date__c == null){
                //log error in BSF_Error_Log__c , no portfolio for the account zipcode
            }else{
                if(taxoRecord.ABM_Name__c != null && taxoRecord.ABM_Name__c != 'NA' && !taxoRecord.ABM_Name__c.containsIgnoreCase(System.Label.NO_SBPM_ABM)){//HRP-13866 System.Label.NO_SBPM_ABM in place of hard coded value
            		isABMAvaialable = true;
            	}
                
                List<Portfolio_Assignment__c> currentPortfolioUsers = new List<Portfolio_Assignment__c>();
                List<Account_Portfolio_Assignment__c> actPortfolioList = acct.AccountPortfolioAssignments__r;
                List<Account_Portfolio_Assignment__c> supervisorPortfolios = new List<Account_Portfolio_Assignment__c>();
                if(superAcctAssmts.containsKey(acct.Id)){
                   supervisorPortfolios = superAcctAssmts.get(acct.Id).AccountPortfolioAssignments__r; 
                }    
                if(portfolioUserMap.get(portfolio.Id) != null){ //AM
                    currentPortfolioUsers.addAll(portfolioUserMap.get(portfolio.Id));
                }
                if(portfolioUserMap.get(portfolio.Parent_Portfolio__c) != null){ //ABM. If No ABM, this is DM.
                    currentPortfolioUsers.addAll(portfolioUserMap.get(portfolio.Parent_Portfolio__c));
                }
                
                if(isABMAvaialable){ // AM parent is ABM, ABM parent is DM. Now add DM to team.
                	if(portfolioUserMap.get(portfolio.Parent_Portfolio__r.Parent_Portfolio__c) != null){
                    	currentPortfolioUsers.addAll(portfolioUserMap.get(portfolio.Parent_Portfolio__r.Parent_Portfolio__c));
                	}    
                }
                //Supervisor portfolio changes - start
                //System.debug('supervisorTaxoMap is '+supervisorTaxoMap);
                
               /* commented part of HRP-12485
                * List<String> suprTaxoKeys = new List<String>();
                if(supervisorTaxoMap.containsKey(portfolio.Portfolio_Code__c))
                	suprTaxoKeys = supervisorTaxoMap.get(portfolio.Portfolio_Code__c);
                
                Integer suprAsignIndex = 0;
                Account_Portfolio_Assignment__c lastSuprAssignment = null;
                
                if(supervisorPortfolios.size() > 0){
                    lastSuprAssignment = supervisorPortfolios[supervisorPortfolios.size()-1];
                    for(Account_Portfolio_Assignment__c suprAssignment:supervisorPortfolios){
                        for(Integer Index=suprAsignIndex;Index<suprTaxoKeys.size();Index++){
                            BSF_Portfolio__c suprPort = portfolioMap.get(suprTaxoKeys[Index]);
                            if(suprPort != null && suprAssignment.BSF_Portfolio__c == suprPort.Id){
                                suprAsignIndex++;
                                lastSuprAssignment = suprAssignment;
                                break;
                            }
                        }
                    }    
                }
                
                if(suprAsignIndex<suprTaxoKeys.size()){
                    for(Integer Index=suprAsignIndex;Index<suprTaxoKeys.size();Index++){
                    	BSF_Portfolio__c suprPort = portfolioMap.get(suprTaxoKeys[Index]);
                        if(suprPort == null || (lastSuprAssignment != null && suprPort.Id == lastSuprAssignment.BSF_Portfolio__c))
                            continue;
                        
                        if(portfolioUserMap.containsKey(suprPort.Parent_Portfolio__c)){
                            currentPortfolioUsers.addAll(portfolioUserMap.get(suprPort.Parent_Portfolio__c));
                        }
                    }
                }
                //Supervisor portfolio changes - end
                commented part of HRP-12485*/
                if(actPortfolioList == null || actPortfolioList.size() == 0){
                    //insert new record
                    system.debug(acct);
                    Account_Portfolio_Assignment__c newActPortfolioAssignment = new Account_Portfolio_Assignment__c(Account__c = acct.Id,BSF_Portfolio__c = portfolio.Id);
                    newActPortfolioAssignment.Start_Date__c = taxoRecord.Start_Date__c;
                    newActPortfolioAssignment.End_Date__c = taxoRecord.End_Date__c;
                    
                    insertList.add(newActPortfolioAssignment);
                    
                    /*for(Integer Index=suprAsignIndex;Index<suprTaxoKeys.size();Index++){
                        BSF_Portfolio__c suprPort = portfolioMap.get(suprTaxoKeys[Index]);
                        if(suprPort == null || suprPort.End_Date__C<newActPortfolioAssignment.start_Date__c || suprPort.start_Date__c>newActPortfolioAssignment.End_Date__C) //11290 
                            continue;

                        //11290 
                        Date sDate= suprKeyTaxo.get(suprTaxoKeys[Index]).Start_Date__c;
                        Date eDate=  suprKeyTaxo.get(suprTaxoKeys[Index]).End_Date__c;
                        //11290 
                        Account_Portfolio_Assignment__c suprPortfolioAssignment = new Account_Portfolio_Assignment__c(Account__c = acct.Id,BSF_Portfolio__c=suprPort.Id);
                        suprPortfolioAssignment.Start_Date__c = sDate>=newActPortfolioAssignment.start_Date__c? sDate:newActPortfolioAssignment.start_Date__c;//11290 
                        suprPortfolioAssignment.End_Date__c = eDate<=newActPortfolioAssignment.End_Date__c? eDate:newActPortfolioAssignment.End_Date__c;//11290 
                        //insertList.add(suprPortfolioAssignment);
                    }*/
                    //populateAccountTeam(taxoRecord,newActPortfolioAssignment,currentPortfolioUsers,accountTeamMap.get(acct.Id),false,accTeamInsertList,accTeamUpdateList,accTeamDeleteList);
                    //AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(new List<Id>(acct.Id),NULL, new set<Id>(), new Map<Id, List<AccountTeamMember>>() ,accountTeamMap); //HRP-12087

                }
                else
                {
                    
						system.debug(acct);                    
                    
                    //Take last record in list. This is the record insreted for previous taxonomy unless there is switch to acocunt based portfolio and revert. 
                    Account_Portfolio_Assignment__c actPortfolioAssignment = actPortfolioList[actPortfolioList.size()-1];
                    Account_Portfolio_Assignment__c newActPortfolioAssignment = new Account_Portfolio_Assignment__c();
                    
                    if(portfolio.Id == actPortfolioAssignment.BSF_Portfolio__c)
                    {
                        if(actPortfolioAssignment.End_Date__c != taxoRecord.End_Date__c)//HRP-12485
                        {
                        	//Zip code belong to same territory and new taxonomy has differebt end date from previous version
                            actPortfolioAssignment.End_Date__c = taxoRecord.End_Date__c;
                            updateList.add(actPortfolioAssignment);
                            //populateAccountTeam(taxoRecord,actPortfolioAssignment,currentPortfolioUsers,accountTeamMap.get(acct.Id),true,accTeamInsertList,accTeamUpdateList,accTeamDeleteList);
                         }
                            
                    }
                    else
                    {
                        //End date current portfolio assignment and insert new one.
                        //HRP-12485 Start
                        if(actPortfolioAssignment.bsf_portfolio__r.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE && actPortfolioAssignment.end_date__c == BSF_Constants.maxDate)
                        {
                            continue;
                        }
                        Date newStartDate =actPortfolioAssignment.bsf_portfolio__r.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE?taxoRecord.Start_Date__c:actPortfolioAssignment.End_Date__c+1;
                        //HRP-12485 End
                        
                        if(actPortfolioAssignment.bsf_portfolio__r.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE)//HRP-12485
                        {
                            actPortfolioAssignment.End_Date__c = newStartDate - 1;
                        	updateList.add(actPortfolioAssignment);
                        }
                        
                            
                        
                        newActPortfolioAssignment.Account__c = acct.Id;
                        newActPortfolioAssignment.BSF_Portfolio__c = portfolio.Id;
                        newActPortfolioAssignment.Start_Date__c = newStartDate;//HRP-12485 taxoRecord.Start_Date__c=>newStartDate
                        newActPortfolioAssignment.End_Date__c = taxoRecord.End_Date__c;
                   //   newActPortfolioAssignment.External_Identifier__c = portfolio.External_Key__c + taxoRecord.Start_Date__c;
                        
                        insertList.add(newActPortfolioAssignment);
                        
                       // populateAccountTeam(taxoRecord,newActPortfolioAssignment,currentPortfolioUsers,accountTeamMap.get(acct.Id),false,accTeamInsertList,accTeamUpdateList,accTeamDeleteList);
                    } //end if

                    /*for(Integer Index=suprAsignIndex;Index<suprTaxoKeys.size();Index++){
                        BSF_Portfolio__c suprPort = portfolioMap.get(suprTaxoKeys[Index]);
                        if((suprPort == null) || (suprPort.End_Date__C<newActPortfolioAssignment.start_Date__c || suprPort.start_Date__c>newActPortfolioAssignment.End_Date__C))//11290
                            continue;
                            if(suprKeyTaxo != null && suprKeyTaxo.get(suprTaxoKeys[Index]) != null &&
                            lastSuprAssignment != null && suprPort.Id == lastSuprAssignment.BSF_Portfolio__c)//HRP-10888
                            {
                        	lastSuprAssignment.End_Date__c = suprKeyTaxo.get(suprTaxoKeys[Index]).Start_Date__c - 1;
                        	updateList.add(lastSuprAssignment);
                            continue;
                    	}
                        
                         //11290 
                         Date sDate= suprKeyTaxo.get(suprTaxoKeys[Index]).Start_Date__c;
                         Date eDate=  suprKeyTaxo.get(suprTaxoKeys[Index]).End_Date__c;
                         //11290 
                         system.debug('sDate'+sDate);
                        system.debug('eDate'+eDate);
                        Account_Portfolio_Assignment__c suprPortfolioAssignment = new Account_Portfolio_Assignment__c(Account__c = acct.Id,BSF_Portfolio__c=suprPort.Id);
                        suprPortfolioAssignment.Start_Date__c = sDate>=newActPortfolioAssignment.start_Date__c? sDate:newActPortfolioAssignment.start_Date__c;//11290 
                        suprPortfolioAssignment.End_Date__c = eDate<=newActPortfolioAssignment.End_Date__c? eDate:newActPortfolioAssignment.End_Date__c;//11290 
                        system.debug('suprPortfolioAssignment'+suprPortfolioAssignment);
                        insertList.add(suprPortfolioAssignment);
                    }commented part of HRP-12485*/
                }// end if
				
            }// end if
        } //end for
        Database.SaveResult[] actPortfolioInsert = Database.insert(insertList, false);
        
        Database.SaveResult[] actPortfolioupdate = Database.update(updateList, false);
        //Log Errors in BSF_Error_Log__c 
        insertErrors(actPortfolioInsert,'Account Portfolio Insert','Assign Account to Portfolio');
        insertErrors(actPortfolioupdate,'Account Portfolio Update','Assign Account to Portfolio');
        
        /*for(AccountTeamMember teamM:accTeamInsertList){
            teamM.AccountAccessLevel= 'Edit';
            teamM.CaseAccessLevel = 'Edit';
            teamM.OpportunityAccessLevel = 'Edit';
        }
        
        Database.SaveResult[] actTeamInsert = Database.insert(accTeamInsertList, false);
       
        Database.SaveResult[] actTeamUpdate = Database.update(accTeamUpdateList, false);
        
        Database.DeleteResult[] actTeamDelete = Database.delete(accTeamDeleteList, false);
        
        insertErrors(actTeamInsert,'Account Team Insert','Populate Account Team');
        insertErrors(actTeamUpdate,'Account Team Update','Populate Account Team');
        insertErrors(actTeamDelete,'Account Team Delete','Populate Account Team');*/

        //HRP-12087 --> Starts Here
		List<Account_Portfolio_Assignment__c> modifiedAccountPortfolioList = new List<Account_Portfolio_Assignment__c>();
        List<Id> accountIds = new List<Id>();
        
        
        modifiedAccountPortfolioList.addAll(updateList);
        modifiedAccountPortfolioList.addAll(insertList);

        if(!modifiedAccountPortfolioList.isEmpty())
        {
            for(Account_Portfolio_Assignment__c accPort : modifiedAccountPortfolioList)
            {
                if(!accountIds.contains(accPort.Account__c))
                {
                    accountIds.add(accPort.Account__c);
                }
            }
        }
		AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(accountIds,NULL, new set<Id>(), new Map<Id, List<AccountTeamMember>>() ,new Map<Id, List<AccountTeamMember>>());       

        //HRP-12087 --> Ends Here
    }
    
    /*public void populateAccountTeam(Taxonomy__c taxoRecord,Account_Portfolio_Assignment__c newActPortfolioAssignment,List<Portfolio_Assignment__c> userPortfolioAssigmentList,List<AccountTeamMember> accountTeamList,Boolean endDateChangeOnly,
                                    		List<AccountTeamMember> accTeamInsertList,List<AccountTeamMember> accTeamUpdateList,List<AccountTeamMember> accTeamDeleteList){
        
        
         System.debug('Inside AccountPortfolioAssignmentHelper.populateAccountTeam');                                       
         BSF_Constants.isTeamMemberCreatedFromBackend = true;                                        
         if(accountTeamList == null){
             accountTeamList = new List<AccountTeamMember>();
         }
                                                
         if(endDateChangeOnly){
            for(AccountTeamMember teamMember:accountTeamList){
            ----------- if(taxoRecord.End_Date__c == teamMember.End_Date__c){
                    teamMember.End_Date__c = newActPortfolioAssignment.End_Date__c;
                    accTeamUpdateList.add(teamMember);
                }--------
            }
        }else{
            if((accountTeamList == null || accountTeamList.size() ==0) && userPortfolioAssigmentList != null){
                
                AccountTeamMember prevAM = null;
                AccountTeamMember prevDM = null;
                AccountTeamMember prevABM = null;
                AccountTeamMember prevSUPR = null;
                
                for(Portfolio_Assignment__c userPortfolio:userPortfolioAssigmentList){
                    System.debug('userPortfolio '+userPortfolio);
                    if(userPortfolio.End_Date__c < newActPortfolioAssignment.Start_Date__c){
                        continue;
                    }
                    AccountTeamMember teamMember = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                    teamMember.UserId = userPortfolio.User__c;
                    teamMember.BSF_Portfolio__c = userPortfolio.BSF_Portfolio__c;
                    teamMember.Start_Date__c = newActPortfolioAssignment.Start_Date__c;
                    teamMember.End_Date__c = userPortfolio.End_Date__c;
                    
                    if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER){ //AM
                        teamMember.TeamMemberRole = BSF_Constants.ACCOUNT_MANAGER;
                        
                        if(prevAM != null){
                            prevAM.End_Date__c = userPortfolio.Start_Date__c - 1;
                            teamMember.Start_Date__c = userPortfolio.Start_Date__c;
                    		teamMember.End_Date__c = userPortfolio.End_Date__c;
                        }
                        
                        accTeamInsertList.add(teamMember);
                        prevAM = teamMember;
                    }else if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER){//DM
                        teamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                        
                        if(prevDM != null){
                            prevDM.End_Date__c = userPortfolio.Start_Date__c - 1;
                            teamMember.Start_Date__c = userPortfolio.Start_Date__c;
                    		teamMember.End_Date__c = userPortfolio.End_Date__c;
                        }
                        accTeamInsertList.add(teamMember);
                        prevDM = teamMember;
                    }else if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER){//ABM
                        teamMember.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
                        
                        if(prevABM != null){
                            prevABM.End_Date__c = userPortfolio.Start_Date__c - 1;
                            teamMember.Start_Date__c = userPortfolio.Start_Date__c;
                    		teamMember.End_Date__c = userPortfolio.End_Date__c;
                        }
                        accTeamInsertList.add(teamMember);
                        prevABM = teamMember;
                    }else if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.SUPERVISOR){//Supervisor
                        teamMember.TeamMemberRole = BSF_Constants.SUPERVISOR;
                        
                        if(prevSUPR != null){
                            prevSUPR.End_Date__c = userPortfolio.Start_Date__c - 1;
                            teamMember.Start_Date__c = userPortfolio.Start_Date__c;
                    		teamMember.End_Date__c = userPortfolio.End_Date__c;
                        }
                        accTeamInsertList.add(teamMember);
                        prevSUPR = teamMember;
                    }
                    
                }
            }else{
                system.debug('Its here');
                List<Portfolio_Assignment__c> amUsers = new List<Portfolio_Assignment__c>();
                List<Portfolio_Assignment__c> dmUsers = new List<Portfolio_Assignment__c>();
                List<Portfolio_Assignment__c> abmUsers = new List<Portfolio_Assignment__c>();
                List<Portfolio_Assignment__c> suprUsers = new List<Portfolio_Assignment__c>();
                
                if(userPortfolioAssigmentList != null){
                    for(Portfolio_Assignment__c userPortfolio:userPortfolioAssigmentList){
                        if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER){
                            if(userPortfolio.End_Date__c == null || userPortfolio.End_Date__c < newActPortfolioAssignment.Start_Date__c){
                                continue;
                            }
                            amUsers.add(userPortfolio);
                        }
                    }
                    
                    for(Portfolio_Assignment__c userPortfolio:userPortfolioAssigmentList){
                        if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.DISTRICT_MANAGER){
                            if(userPortfolio.End_Date__c == null || userPortfolio.End_Date__c < newActPortfolioAssignment.Start_Date__c){
                                continue;
                            }
                            dmUsers.add(userPortfolio);
                        }
                    }
                    
                    for(Portfolio_Assignment__c userPortfolio:userPortfolioAssigmentList){
                        if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.AREA_BOOKING_MANAGER){
                            if(userPortfolio.End_Date__c == null || userPortfolio.End_Date__c < newActPortfolioAssignment.Start_Date__c){
                                continue;
                            }
                            abmUsers.add(userPortfolio);
                        }
                    }
                    
                    for(Portfolio_Assignment__c userPortfolio:userPortfolioAssigmentList){
                        if(userPortfolio.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.SUPERVISOR){
                            if(userPortfolio.End_Date__c == null || userPortfolio.End_Date__c < newActPortfolioAssignment.Start_Date__c){
                                continue;
                            }
                            suprUsers.add(userPortfolio);
                        }
                    }
                }
               
                Integer amIndex = 0; 
                Integer dmIndex = 0;
                Integer abmIndex = 0;
                Integer suprIndex = 0;
                
                for(AccountTeamMember teamMember:accountTeamList){
                	if(newActPortfolioAssignment.Start_Date__c <= teamMember.End_Date__c ){
                       if(teamMember.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER && amUsers.size() > 0){
                            if(amIndex == amUsers.size()){
                        		accTeamDeleteList.add(teamMember);
                            	continue;
                        	}
                            
                     		Portfolio_Assignment__c amUserPortfolio1 = amUsers.get(amIndex);
                            
                            if(amUserPortfolio1.User__c == teamMember.UserId){
                                if(amIndex == 0){
                                	teamMember.End_Date__c =  amUserPortfolio1.End_Date__c;
                                    teamMember.TeamMemberRole = BSF_Constants.ACCOUNT_MANAGER;
                                 }else{
                                    
                                 //   teamMember.UserId = amUserPortfolio1.User__c;
                                    teamMember.Start_Date__c = amUserPortfolio1.Start_Date__c;
                                    teamMember.End_Date__c = amUserPortfolio1.End_Date__c;
                                    teamMember.TeamMemberRole = BSF_Constants.ACCOUNT_MANAGER;
                                 }
                                
                                if(newActPortfolioAssignment.Start_Date__c == system.today())
                                {
                                    teamMember.BSF_Portfolio__c = amUserPortfolio1.BSF_Portfolio__c;
                                }
                                 
                                 accTeamUpdateList.add(teamMember);
                                 if(amIndex+1 == amusers.size() && newActPortfolioAssignment.End_Date__C< teamMember.End_Date__c)
                                 {teamMember.End_Date__c = newActPortfolioAssignment.End_Date__C;}
                                    
                            }else{
                                    AccountTeamMember teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                    			    teamMemberNew.UserId = amUserPortfolio1.User__c;
                                    teamMemberNew.BSF_Portfolio__c = amUserPortfolio1.BSF_Portfolio__c;
                                    teamMemberNew.TeamMemberRole = BSF_Constants.ACCOUNT_MANAGER;

                                if(amIndex == 0){
                                    //Endating the Existing Accountteam
                                    teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                                    accTeamUpdateList.add(teamMember);
                                    
                                    //New Teammember
                                    teamMemberNew.Start_Date__c =  newActPortfolioAssignment.Start_Date__c >= amUserPortfolio1.Start_Date__C?newActPortfolioAssignment.Start_Date__c:amUserPortfolio1.Start_Date__C;
                                    teamMemberNew.End_Date__c = amUserPortfolio1.End_Date__C;
                                    
                                    
                                    //accTeamInsertList.add(teamMemberNew);
                                }else{
                                    accTeamDeleteList.add(teamMember);

                                    
                                    teamMemberNew.Start_Date__c = amUserPortfolio1.Start_Date__c;
                                    teamMemberNew.End_Date__c = amUserPortfolio1.End_Date__c;
                                    
                                    
                                    //accTeamInsertList.add(teamMemberNew);
                                }
                                
                                if(amIndex+1 == amusers.size() && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                                    teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                                }
                                    accTeamInsertList.add(teamMemberNew);
                    	    }
                            amIndex++;
                            
                            
                        }else if(teamMember.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER && amUsers.size() == 0){
                            teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                            accTeamUpdateList.add(teamMember);
                        }
                        else if(teamMember.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER && dmUsers.size() > 0){
                            if(dmIndex == dmUsers.size()){
                            	accTeamDeleteList.add(teamMember);
                            	continue;
                        	}
                            
                     		Portfolio_Assignment__c dmUserPortfolio1 = dmUsers.get(dmIndex);
                            
                            if(dmUserPortfolio1.User__c == teamMember.UserId){
                                if(dmIndex == 0){
                                	teamMember.End_Date__c =  dmUserPortfolio1.End_Date__c;
                                    teamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                                }else{
                                //    teamMember.UserId = dmUserPortfolio1.User__c;
                                    teamMember.Start_Date__c = dmUserPortfolio1.Start_Date__c;
                                    teamMember.End_Date__c = dmUserPortfolio1.End_Date__c;
                                    teamMember.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                                }
                                if(newActPortfolioAssignment.Start_Date__c == system.today())
                                {
                                    teamMember.BSF_Portfolio__c = dmUserPortfolio1.BSF_Portfolio__c;
                                }
                            
                                accTeamUpdateList.add(teamMember);
                                if(dmIndex+1 == dmusers.size() && newActPortfolioAssignment.End_Date__C< teamMember.End_Date__c)
                                 {teamMember.End_Date__c = newActPortfolioAssignment.End_Date__C;}

                                
                            }else{
                                AccountTeamMember teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                                teamMemberNew.UserId = dmUserPortfolio1.User__c;
                                teamMemberNew.BSF_Portfolio__c = dmUserPortfolio1.BSF_Portfolio__c;
                                teamMemberNew.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                                if(dmIndex == 0){
                                    
                                    teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                                    accTeamUpdateList.add(teamMember);
                                    
                                   
                    			    teamMemberNew.Start_Date__c = newActPortfolioAssignment.Start_Date__c >= dmUserPortfolio1.Start_Date__C?newActPortfolioAssignment.Start_Date__c:dmUserPortfolio1.Start_Date__C;
                                    teamMemberNew.End_Date__c = dmUserPortfolio1.End_Date__C;
                    				
                                    
                                    //accTeamInsertList.add(teamMemberNew);
                                }else{
                                    accTeamDeleteList.add(teamMember);

                                    
                                    teamMemberNew.Start_Date__c = dmUserPortfolio1.Start_Date__c;
                                    teamMemberNew.End_Date__c = dmUserPortfolio1.End_Date__c;
                                	
                                    //accTeamInsertList.add(teamMemberNew);
                                }
                                if(dmIndex+1 == dmusers.size() && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                                    teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                                }
                                    accTeamInsertList.add(teamMemberNew);
                    	    }
                            dmIndex++;
                        }else if(teamMember.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER && dmUsers.size() == 0){
                            teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                            accTeamUpdateList.add(teamMember);
                            }
                        else if(teamMember.TeamMemberRole == BSF_Constants.AREA_BOOKING_MANAGER && abmUsers.size() > 0){
                            if(abmIndex == abmUsers.size()){
                            	accTeamDeleteList.add(teamMember);
                            	continue;
                        	}
                            
                     		Portfolio_Assignment__c abmUserPortfolio1 = abmUsers.get(abmIndex);
                            
                            if(abmUserPortfolio1.User__c == teamMember.UserId){
                                if(abmIndex == 0){
                                	teamMember.End_Date__c = abmUserPortfolio1.End_Date__c;
                                    //teamMember.BSF_Portfolio__c = abmUserPortfolio1.BSF_Portfolio__c;
                                    teamMember.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
                                }else{
                                //    teamMember.UserId = abmUserPortfolio1.User__c;
                                    teamMember.Start_Date__c = abmUserPortfolio1.Start_Date__c;
                                    teamMember.End_Date__c = abmUserPortfolio1.End_Date__c;
                                    //teamMember.BSF_Portfolio__c = abmUserPortfolio1.BSF_Portfolio__c;
                                    teamMember.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
                                }

                                if(newActPortfolioAssignment.Start_Date__c == system.today())
                                {
                                    teamMember.BSF_Portfolio__c = abmUserPortfolio1.BSF_Portfolio__c;
                                }
                            
                            
                                accTeamUpdateList.add(teamMember);
                                if(abmIndex+1 == abmUsers.size() && newActPortfolioAssignment.End_Date__C< teamMember.End_Date__c)
                                 {teamMember.End_Date__c = newActPortfolioAssignment.End_Date__C;}
                                
                            }else{
                                    AccountTeamMember teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                    			    teamMemberNew.UserId = abmUserPortfolio1.User__c;
                                    teamMemberNew.BSF_Portfolio__c = abmUserPortfolio1.BSF_Portfolio__c;
                                    teamMemberNew.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
                                if(abmIndex == 0){
                                    
                                    teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                                    accTeamUpdateList.add(teamMember);
                                    
                                    
                    			    teamMemberNew.Start_Date__c = newActPortfolioAssignment.Start_Date__c >= abmUserPortfolio1.Start_Date__C?newActPortfolioAssignment.Start_Date__c:abmUserPortfolio1.Start_Date__C;
                                    teamMemberNew.End_Date__c = abmUserPortfolio1.End_Date__c;
                    				
                                    
                                    //accTeamInsertList.add(teamMemberNew);
                                }else{
                                    accTeamDeleteList.add(teamMember);
                                    //teamMember.UserId = abmUserPortfolio1.User__c;
                                    teamMemberNew.Start_Date__c = abmUserPortfolio1.Start_Date__c;
                                    teamMemberNew.End_Date__c = abmUserPortfolio1.End_Date__c;
                                	
                                    //accTeamInsertList.add(teamMemberNew);
                                }
                                if(abmIndex+1 == abmUsers.size() && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                                    teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                                }
                                    accTeamInsertList.add(teamMemberNew);
                    	    }
                            abmIndex++;
                        }
                        else if(teamMember.TeamMemberRole == BSF_Constants.AREA_BOOKING_MANAGER && abmUsers.size() == 0)
                        {
                            teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                            accTeamUpdateList.add(teamMember);
                            }
                        else if(teamMember.TeamMemberRole == BSF_Constants.SUPERVISOR && suprUsers.size() > 0){
                            if(suprIndex == suprUsers.size()){
                            	accTeamDeleteList.add(teamMember);
                            	continue;
                        	}
                            
                     		Portfolio_Assignment__c suprUserPortfolio1 = suprUsers.get(suprIndex);
                            
                            if(suprUserPortfolio1.User__c == teamMember.UserId){
                                if(suprIndex == 0){
                                	teamMember.End_Date__c = suprUserPortfolio1.End_Date__c;
                                    //teamMember.BSF_Portfolio__c = suprUserPortfolio1.BSF_Portfolio__c;
                                    teamMember.TeamMemberRole = BSF_Constants.SUPERVISOR;
                                }else{
                                //    teamMember.UserId = suprUserPortfolio1.User__c;
                                    teamMember.Start_Date__c = suprUserPortfolio1.Start_Date__c;
                                    teamMember.End_Date__c = suprUserPortfolio1.End_Date__c;
                                    //teamMember.BSF_Portfolio__c = suprUserPortfolio1.BSF_Portfolio__c;
                                    teamMember.TeamMemberRole = BSF_Constants.SUPERVISOR;
                                }

                                if(newActPortfolioAssignment.Start_Date__c == system.today())
                                {
                                    teamMember.BSF_Portfolio__c = suprUserPortfolio1.BSF_Portfolio__c;
                                }
                            
                                accTeamUpdateList.add(teamMember);
                                if(suprIndex+1 == suprUsers.size() && newActPortfolioAssignment.End_Date__C< teamMember.End_Date__c)
                                 {teamMember.End_Date__c = newActPortfolioAssignment.End_Date__C;}

                                
                            }else{
                                AccountTeamMember teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                    			    teamMemberNew.UserId = suprUserPortfolio1.User__c;
                                    teamMemberNew.BSF_Portfolio__c = suprUserPortfolio1.BSF_Portfolio__c;
                                    teamMemberNew.TeamMemberRole = BSF_Constants.SUPERVISOR;
                                if(suprIndex == 0){
                                    
                                    teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c -1;
                                    accTeamUpdateList.add(teamMember);
                                    
                                    
                    			    teamMemberNew.Start_Date__c = newActPortfolioAssignment.Start_Date__c >= suprUserPortfolio1.Start_date__c?newActPortfolioAssignment.Start_Date__c:suprUserPortfolio1.Start_Date__c ;
                                    teamMemberNew.End_Date__c = suprUserPortfolio1.End_Date__c;
                    				
                                    
                                    //accTeamInsertList.add(teamMemberNew);
                                }else{
                                    accTeamDeleteList.add(teamMember);
                                     //teamMember.UserId = suprUserPortfolio1.User__c;
                                    teamMemberNew.Start_Date__c = suprUserPortfolio1.Start_Date__c;
                                    teamMemberNew.End_Date__c = suprUserPortfolio1.End_Date__c;
                                	
                                    //accTeamInsertList.add(teamMemberNew);
                                }
                                if(suprIndex+1 == suprUsers.size() && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c ){
                                    teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                                    teamMemberNew.TeamMemberRole = BSF_Constants.SUPERVISOR;
                                }
                                    accTeamInsertList.add(teamMemberNew);
                    	    }
                            suprIndex++;
                        }
                         else if(teamMember.TeamMemberRole == BSF_Constants.SUPERVISOR && suprUsers.size() == 0)
                        {
                            teamMember.End_Date__c = newActPortfolioAssignment.Start_Date__c-1;
                            accTeamUpdateList.add(teamMember);
                            }
                	}
            	}//end for
                
                if(amIndex < amUsers.size()){
                    AccountTeamMember teamMemberNew = null;
                    for(Integer index = amIndex;index < amUsers.size();index++){
                        Portfolio_Assignment__c amUserPortfolio1 = amUsers.get(index);+
                        teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                        teamMemberNew.UserId = amUserPortfolio1.User__c;
                        teamMemberNew.BSF_Portfolio__c = amUserPortfolio1.BSF_Portfolio__c;
                        teamMemberNew.Start_Date__c = amUserPortfolio1.Start_Date__c;
                        teamMemberNew.End_Date__c = amUserPortfolio1.End_Date__c;
                        teamMemberNew.TeamMemberRole = BSF_Constants.ACCOUNT_MANAGER;
                      
                        accTeamInsertList.add(teamMemberNew);
                        
                    }        
                    if(teamMemberNew != null && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                        teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                    }  		
        		}
            
            	if(dmIndex < dmUsers.size()){
                    AccountTeamMember teamMemberNew = null;
            		for(Integer index = dmIndex;index < dmUsers.size();index++){
                        Portfolio_Assignment__c dmUserPortfolio1 = dmUsers.get(index);
                        teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                        teamMemberNew.UserId = dmUserPortfolio1.User__c;
                        teamMemberNew.BSF_Portfolio__c = dmUserPortfolio1.BSF_Portfolio__c;
                        teamMemberNew.Start_Date__c = dmUserPortfolio1.Start_Date__c;
                        teamMemberNew.End_Date__c = dmUserPortfolio1.End_Date__c;
                        teamMemberNew.TeamMemberRole = BSF_Constants.DISTRICT_MANAGER;
                     
                        accTeamInsertList.add(teamMemberNew);
                    }
                    if(teamMemberNew != null && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                        teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                    }  		
                }
                
                if(abmIndex < abmUsers.size()){
                    
                    AccountTeamMember teamMemberNew = null;
            		for(Integer index = abmIndex;index < abmUsers.size();index++){
                        Portfolio_Assignment__c abmUserPortfolio1 = abmUsers.get(index);
                        teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                        teamMemberNew.UserId = abmUserPortfolio1.User__c;
                        teamMemberNew.BSF_Portfolio__c = abmUserPortfolio1.BSF_Portfolio__c;
                        teamMemberNew.Start_Date__c = abmUserPortfolio1.Start_Date__c;
                        teamMemberNew.End_Date__c = abmUserPortfolio1.End_Date__c;
                        teamMemberNew.TeamMemberRole = BSF_Constants.AREA_BOOKING_MANAGER;
                     
                        accTeamInsertList.add(teamMemberNew);
                    }
                    if(teamMemberNew != null && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                        teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                    }  		
                }
                
                if(suprIndex < suprUsers.size()){
                    
                    AccountTeamMember teamMemberNew = null;
            		for(Integer index = suprIndex;index < suprUsers.size();index++){
                        Portfolio_Assignment__c suprUserPortfolio1 = suprUsers.get(index);
                        teamMemberNew = new AccountTeamMember(AccountId=newActPortfolioAssignment.Account__c);
                        teamMemberNew.UserId = suprUserPortfolio1.User__c;
                        teamMemberNew.BSF_Portfolio__c = suprUserPortfolio1.BSF_Portfolio__c;
                        teamMemberNew.Start_Date__c = suprUserPortfolio1.Start_Date__c;
                        teamMemberNew.End_Date__c = suprUserPortfolio1.End_Date__c;
                        teamMemberNew.TeamMemberRole = BSF_Constants.SUPERVISOR;
                     
                        accTeamInsertList.add(teamMemberNew);
                    }
                    if(teamMemberNew != null && newActPortfolioAssignment.End_Date__c < teamMemberNew.End_Date__c){
                        teamMemberNew.End_Date__c = newActPortfolioAssignment.End_Date__c;
                    }  		
                }
             }
        }
        system.debug('accTeamUpdateList:'+accTeamUpdateList);
        
    }*/
    
    public void insertErrors(Database.SaveResult[] saveErrors,String errorDesc, String processName){
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        
        for(Database.SaveResult result:saveErrors){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
        		errorList.add(BSF_Utilities.getErrorLog(processName,'BSFPortfolioHelper','createOrUpdatePortfolio','Error',errorDesc,result.getErrors()[0].getMessage()));
        	}
        }
        if(errorList.size() > 0){
            //Schema.DescribeSObjectResult ds = BSF_Error_Log__c.sObjectType.getDescribe();
            //if( ds.isCreateable() ){}
                Database.insert(errorList,false);
            
        }
    }
    
    public void insertErrors(Database.DeleteResult[] deleteErrors,String errorDesc, String processName){
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        
        for(Database.DeleteResult result:deleteErrors){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
        		errorList.add(BSF_Utilities.getErrorLog(processName,'BSFPortfolioHelper','createOrUpdatePortfolio','Error',errorDesc,result.getErrors()[0].getMessage()));
        	}
        }
        if(errorList.size() > 0){
            //Schema.DescribeSObjectResult ds = BSF_Error_Log__c.sObjectType.getDescribe();
            //if( ds.isCreateable() ){}
                Database.insert(errorList,false);
                     
            
        }
    }
    
}