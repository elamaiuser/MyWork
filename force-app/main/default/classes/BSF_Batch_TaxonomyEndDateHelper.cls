/* 
* Modification Log 
* Date					     Developer Name			     Comments
* *******************************************************************************************************************************************************************************************************
* 11/26/2024                  Balaji N                   Logic for HRP-13866 Method:getexternalKeyTaxonomyMap System.Label.NO_SBPM_ABM in place of hard coded value
*********************************************************************************************************************************************************************************************************
*/
public class BSF_Batch_TaxonomyEndDateHelper 
{
    public static void endDateTaxonomy(list<taxonomy__c> newVerTax,list<taxonomy__c> oldVerTax)
    {
        set<id> taxRecTypeSet = new set<id>();
        Decimal versionKey;
        
        
        //map of current/old taxonomy ID and list of external keys
        map<String,taxonomy__c> taxIdExternalKeysMap = getexternalKeyTaxonomyMap (oldVerTax);
        //system.debug('taxIdExternalKeysMap '+taxIdExternalKeysMap);
        
        set<string> externalKeySet = new set<string>();
        externalKeySet.addAll(taxIdExternalKeysMap.keyset()); 
        
        
        
        //map of future/new taxonomy ID and list of external keys
        map<String,taxonomy__c> newTaxIdExternalKeysMap = getexternalKeyTaxonomyMap (newVerTax);
        set<string> externalKeySetNew = new set<string>();
        
        externalKeySetNew.addAll(newTaxIdExternalKeysMap.keyset());  
        
        //related bsf portfolio of current/old taxonomies
        List<bsf_Portfolio__c> bsfPortfolioList = [SELECT Id, External_Key__c,External_Key_BackEnd__c , Portfolio_Type__c, Taxonomy_Type__c, Territory_Portfolio__c, 
                                                   Parent_Portfolio__c, Start_Date__c, End_Date__c, Is_Expired__c, Portfolio_Code__c, Portfolio_Name__c FROM BSF_Portfolio__c
                                                   where External_Key_BackEnd__c  IN:externalKeySet order by createdDate desc];
        
        //system.debug('bsfPortfolioList'+bsfPortfolioList);
        
        
        //BSF Portfolio process
        if(!bsfPortfolioList.isEmpty())
        {
            map<string,bsf_Portfolio__c> bsfIdBSfMap = new map<string,bsf_Portfolio__c>();
            for(bsf_Portfolio__c bsf:bsfPortfolioList)
            {
                if(!bsfIdBSfMap.keyset().contains(bsf.External_Key_BackEnd__c))
                    bsfIdBSfMap.put(bsf.External_Key_BackEnd__c ,bsf);
            }
            
            map<id,bsf_Portfolio__c> bsfPortfolioToUpdateMap = new map<id,bsf_Portfolio__c>();
            List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
            //system.debug('bsfIdBSfMap'+bsfIdBSfMap);
            
                    for(string exKey: taxIdExternalKeysMap.keyset())
                    {
                        Taxonomy__c tx = new Taxonomy__c();
                        tx = taxIdExternalKeysMap.get(exKey);
                        if(!externalKeySetNew.contains(exKey))
                        {
                            
                        //system.debug('exKey '+exKey);
                        bsf_Portfolio__c bsf = new bsf_Portfolio__c ();
                        bsf = bsfIdBSfMap.get(exKey);
                        //system.debug('bsf70 '+bsf);
                        if(bsf != NULL && tx.End_Date__c != bsf.End_Date__c && bsf.Start_Date__c < bsf.End_Date__c)
                        {
                            bsf.End_Date__c = tx.End_Date__c;
                            bsfPortfolioToUpdateMap.put(bsf.id,bsf);
                            BSF_Error_Log__c log1 = BSF_Utilities.getErrorLog('Create Portfolio', 'endaate', 'endate helper', 'Debug Log','No Error - Platform Event log', 'BSFId: '+ string.valueof(bsf.id)+'_'+bsf.End_Date__c+' '+ 'TX id: '+ string.valueof(tx.id)+'_'+tx.End_Date__c);
                            logList.add(log1);
                            bsfPortfolioToUpdateMap.put(bsf.id,bsf);
                            
                        }
                      }
                    }
                
            
            
            if(!logList.isEmpty())
            {
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            if(!bsfPortfolioToUpdateMap.values().isEmpty())
            {
                
                Database.saveResult [] results = database.update(bsfPortfolioToUpdateMap.values(),false);
                List<BSF_Error_Log__c> logList1 = BSF_Utilities.createErrorLog(results, 'Create Portfolio','Tax endate helper','createDMRecords','Error','Error in upserting Bsf portfolio ');
                InsertBsfErrorLog.insertBsfErrors(logList1);
               
            }
        }
        
        List<sked_Territory__c> skedTerrList = [select id,Start_Date__c, End_Date__c,External_Id__c,External_Id_BackEnd__c from sked_Territory__c where External_Id_BackEnd__c IN :externalKeySet order by createdDate desc];
        //system.debug('skedTerrList'+skedTerrList);
        if(!skedTerrList.isEmpty())
        {
            map<string,sked_Territory__c> terrIdTerrMap = new map<string,sked_Territory__c>();
            for(sked_Territory__c terr:skedTerrList)
            {
                if(!terrIdTerrMap.keyset().contains(terr.External_Id_BackEnd__c))
                    terrIdTerrMap.put(terr.External_Id_BackEnd__c ,terr);
            }
        
        
        map<id,sked_Territory__c> terrToUpdateMap = new map<id,sked_Territory__c>();
        List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
        //system.debug('terrIdTerrMap'+terrIdTerrMap);
        set<string> terrIdSet = new set<string>();
          
            for(string exKey: taxIdExternalKeysMap.keyset())
            {
                Taxonomy__c tx = new Taxonomy__c();
                tx = taxIdExternalKeysMap.get(exKey);
                if(!externalKeySetNew.contains(exKey))
                {
                    //system.debug('exKey '+exKey);
                    sked_Territory__c terr = new sked_Territory__c ();
                    terr = terrIdTerrMap.get(exKey);
                    
                    if( terr != null && tx.End_Date__c != terr.End_Date__c && terr.Start_Date__c < tx.End_Date__c)
                    {
                        terr.End_Date__c = tx.End_Date__c;
                        BSF_Error_Log__c log1 = BSF_Utilities.getErrorLog('Create Portfolio', 'endaate', 'endate helper', 'Debug Log','No Error - Platform Event log', 'BSFId: '+ string.valueof(terr.id)+'_'+terr.End_Date__c+' '+ 'TX id: '+ string.valueof(tx.id)+'_'+tx.End_Date__c);
                        logList.add(log1);
                        terrToUpdateMap.put(terr.id,terr);
                        terrIdSet.add(string.valueof(terr.id));
                    }
                }
            }
            
            
            List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(terrIdSet,'Create Oppty Team','createOpptyTeamMembersBasedOnOppties','EndDateBatch','Success','territoriesd updated are');
            if(!successList.isEmpty())
             {
                 try{
                   insert successList;
                 }
                 catch (exception e)
                 {
                     system.debug('The exception in successList: '+e);
                 }
             }
            if(!terrToUpdateMap.values().isEmpty())
            {
                
                Database.saveResult [] results = database.update(terrToUpdateMap.values(),false);
                List<BSF_Error_Log__c> logList1 = BSF_Utilities.createErrorLog(results, 'Populate Account Team','endDateTaxonomy','Endate_Territory','Error','Error in Endate_Territory');
                InsertBsfErrorLog.insertBsfErrors(logList1);
				
            }
            
        }
    }
    
    //Method returns map of taxonomy id and list of external keys of BSFPortfolios
    public static map<String,taxonomy__c> getexternalKeyTaxonomyMap(list<taxonomy__c> taxonomyList)
    {
        map<String,taxonomy__c> taxIdExternalKeysMap = new map<String,taxonomy__c>();
        for(Taxonomy__c tx:taxonomyList)
        {
            //system.debug('tcxc'+tx.id);
            string recordtypename = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosById().get(tx.recordtypeid).getname();
            if(recordtypename == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || recordtypename == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)
            {
                
                if(tx.ABM_Name__c != null && tx.ABM_Name__c != 'NA' && !tx.ABM_Name__c.containsIgnoreCase(System.Label.NO_SBPM_ABM))//HRP-13866 System.Label.NO_SBPM_ABM in place of hard coded value
                {
                    externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Team_Code__c,'_'+tx.ABM_Code__c,'_'+tx.DRD_Territory_Code__c});
                }
                else
                {
                    externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Team_Code__c,'_'+tx.DRD_Territory_Code__c});                
                }
            }
            else if(recordtypename == BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.District_Code__c,'_'+tx.Collection_Operation_Code__c,'_'+tx.Portfolio_Code__c});
            }
            else if(recordtypename == BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE || recordtypename == BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE
                    || recordtypename == BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Portfolio_Code__c});
            }
            else if(recordtypename == BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Portfolio_Code__c});
            }
            else if(recordtypename == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Team_Code__c,'_'+tx.Supervisor_Code__c,'_'+tx.DRD_Territory_Code__c});
            }
            else if(recordtypename == BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.Division_Code__c+'_'+tx.DS_Region_Code__c,'_'+tx.Division_Code__c+'_'+tx.DS_Region_Code__c+'_'+tx.District_Code__c});
            }
            
        }
        
        return taxIdExternalKeysMap;
    }
    
    // Method returns a list of external key for a given taxonomy
    public static void externalKeyfinder (string recordtypeName,map<String,taxonomy__c> taxIdExternalKeysMap,Taxonomy__c tx,list<string> codeString)
    {
        List<string> externalKeyList = new list<string>();
        list<string> bioCollTerrRecType = new list<string>{'Division','ARC Region','District'};
            
            for(string s : codeString)
        {
            
            if(externalKeyList.isEmpty())
            {
                if(recordtypeName != BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
                {
                    externalKeyList.add(recordtypeName+s);
                    taxIdExternalKeysMap.put(recordtypeName+s,tx);
                }
                else
                {
                    externalKeyList.add('Bio_Collection_BSF'+'_'+bioCollTerrRecType[0]+s);
                    taxIdExternalKeysMap.put('Bio_Collection_BSF'+'_'+bioCollTerrRecType[0]+s,tx);
                }
            }
            else
            {
                string temp;
                if(recordtypeName != BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
                {
                    temp = externalKeyList.get(externalKeyList.size()-1)+s;   
                }
                else
                {
                    temp ='Bio_Collection_BSF'+'_'+bioCollTerrRecType[externalKeyList.size()]+s;
                }
                externalKeyList.add(temp);
                taxIdExternalKeysMap.put(temp,tx);
            }
            if(externalKeyList.size()==codeString.size() && (recordtypename == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || recordtypename == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE))
            {
                //string splited = externalKeyList.get(externalKeyList.size()-1);
                //system.debug('splited_'+splited);
                externalKeyList.add('Account Specialist'+codeString[2]);
                taxIdExternalKeysMap.put('Account Specialist'+codeString[2],tx);
                ///system.debug('splited_'+externalKeyList[3]);
            }
        }
        
        //system.debug('externalKeyList'+externalKeyList);
        //return externalKeyList;
        
    }
}