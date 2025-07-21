/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/05/2023				 Kishore Das		        Logic for HRP-11103 (Multiple BPLs if no overlap in effective date)
 *************************************************************************************************************************************************
*/
public with sharing class AccountServiceRoleService {
    
    //Logic for HRP-11103 ***starts here***
    public static void verifyValidBPLCountInsert(List<Account_Service_Role__c> oldList, List<Account_Service_Role__c> newList) {
        
        List<Account_Service_Role__c> accountServiceRolesWithAccounts = new List<Account_Service_Role__c>();  
        List<Id> accountIds = new List<Id>(); 
        
        for (Account_Service_Role__c accountServiceRole : newList) {
            if (accountServiceRole.Account_Service_Role__c != Label.BloodProgram) {
                continue; 
            }
            
            if (accountServiceRole.Account__c != null) {
                accountIds.add(accountServiceRole.Account__c);
                accountServiceRolesWithAccounts.add(accountServiceRole); 
            }
        }
        
        if (!accountServiceRolesWithAccounts.isEmpty()) {
            checkAndErrorIfValidBPLExistsAlreadyInsert(accountIds, accountServiceRolesWithAccounts); 
        }        
    }

 	public static void checkAndErrorIfValidBPLExistsAlreadyInsert(List<Id> accountIds,  
                                                              List<Account_Service_Role__c> accountSvcRoleList) {
            List<Account_Service_Role__c> validBPLAccountServiceRoles = [
                SELECT Id, Account_Service_Role__c, Account__c, Start_Date__c, End_Date__c 
                FROM Account_Service_Role__c 
                WHERE Account_Service_Role__c =:Label.BloodProgram  
                AND Account__c IN :accountIds
            ];
        
            Map<Id, List<Account_Service_Role__c>> accountToExistingRolesMap = new Map<Id, List<Account_Service_Role__c>>();
            for (Account_Service_Role__c role : validBPLAccountServiceRoles) {
                if (!accountToExistingRolesMap.containsKey(role.Account__c)) {
                    accountToExistingRolesMap.put(role.Account__c, new List<Account_Service_Role__c>());
                }
                accountToExistingRolesMap.get(role.Account__c).add(role);
            }
        
            for (Account_Service_Role__c newRole : accountSvcRoleList) {
                List<Account_Service_Role__c> existingRolesForAccount = accountToExistingRolesMap.get(newRole.Account__c);
                if (existingRolesForAccount != null) {
                    for (Account_Service_Role__c existingRole : existingRolesForAccount) {
                        if (isDateOverlap1(existingRole, newRole)) {
                            newRole.addError(System.Label.Bpl_Error);
                            break; 
                        }
                    }
                }
            }
        }

	/*
    private static boolean isDateOverlap(Account_Service_Role__c existingRole, Account_Service_Role__c newRole) {
        Date existingStart = existingRole.Start_Date__c;
        Date existingEnd = existingRole.End_Date__c;
        Date newStart = newRole.Start_Date__c;
        Date newEnd = newRole.End_Date__c;
        
        boolean startsWithinExisting = newStart != null && (existingEnd == null || newStart <= existingEnd);
        boolean endsWithinExisting = newEnd != null && (existingStart == null || newEnd >= existingStart);
        
       return (existingStart == null || startsWithinExisting) && (existingEnd == null || endsWithinExisting);
    }
	*/
    
    public static void verifyValidBPLCountUpdate(List<Account_Service_Role__c> oldList, List<Account_Service_Role__c> newList) {
        System.debug('Entered method verifyValidBPLCountUpdate with newMap->' + newList);
        
        List<Account_Service_Role__c> accountServiceRolesWithAccounts = new List<Account_Service_Role__c>();  
        List<Id> accountIds = new List<Id>(); 
        
        for (Account_Service_Role__c accountServiceRole : newList) {
            if (accountServiceRole.Account_Service_Role__c != Label.BloodProgram) {
                continue; // Interested only in BPL role
            }
            
            if (accountServiceRole.Account__c != null) {
                accountIds.add(accountServiceRole.Account__c);
                accountServiceRolesWithAccounts.add(accountServiceRole); 
            }
        }
        
        if (!accountServiceRolesWithAccounts.isEmpty()) {
            checkAndErrorIfValidBPLExistsAlreadyForUpdate(accountIds, accountServiceRolesWithAccounts); 
        }        
    }

        public static void checkAndErrorIfValidBPLExistsAlreadyForUpdate(List<Id> accountIds,  
                                                                 List<Account_Service_Role__c> accountSvcRoleList) {
                Set<Id> updatingRoleIds = new Set<Id>();
                for (Account_Service_Role__c role : accountSvcRoleList) {
                    updatingRoleIds.add(role.Id);
                }
            
                List<Account_Service_Role__c> existingBPLRoles = [
                    SELECT Id, Account_Service_Role__c, Account__c, Start_Date__c, End_Date__c 
                    FROM Account_Service_Role__c 
                    WHERE Account_Service_Role__c = :Label.BloodProgram 
                    AND Id NOT IN :updatingRoleIds
                    AND Account__c IN :accountIds
                ];
            
                Map<Id, List<Account_Service_Role__c>> accountToExistingRolesMap = new Map<Id, List<Account_Service_Role__c>>();
                for (Account_Service_Role__c role : existingBPLRoles) {
                    if (!accountToExistingRolesMap.containsKey(role.Account__c)) {
                        accountToExistingRolesMap.put(role.Account__c, new List<Account_Service_Role__c>());
                    }
                    accountToExistingRolesMap.get(role.Account__c).add(role);
                }
            
                for (Account_Service_Role__c newRole : accountSvcRoleList) {
                    List<Account_Service_Role__c> existingRolesForAccount = accountToExistingRolesMap.get(newRole.Account__c);
                    if (existingRolesForAccount != null) {
                        for (Account_Service_Role__c existingRole : existingRolesForAccount) {
                            if (isDateOverlap1(existingRole, newRole)) {
                                newRole.addError(System.Label.Bpl_Error);
                                break; 
                            }
                        }
                    }
                }
            }


    private static boolean isDateOverlap1(Account_Service_Role__c existingRole, Account_Service_Role__c newRole) {
        Date existingStart = existingRole.Start_Date__c;
        Date existingEnd = existingRole.End_Date__c;
        Date newStart = newRole.Start_Date__c;
        Date newEnd = newRole.End_Date__c;
        
        boolean isOverlap = false;
        
        // Case 1: If existing end date is null (open-ended)
        if (existingEnd == null && newEnd !=null) {
            isOverlap = (newStart != null && newStart >= existingStart || newEnd >= existingStart);
            system.debug('isOverlap1 '+isOverlap);
        } 
        // Case 2: If new end date is null (open-ended)
        else if (newEnd == null && existingEnd !=null) {
            isOverlap = (newStart != null && newStart <= existingEnd );//|| existingStart <= newStart
            system.debug('isOverlap2 '+isOverlap);
            
        }
        // Case 3: If new end date is null and existing end date is also null
        else if (newEnd == null && existingEnd==null) {
            isOverlap = ( newStart >= existingStart || newStart <= existingStart );
            system.debug('isOverlap3 '+isOverlap);
        }
        
        // Case 4: Both dates are defined
        else {
            isOverlap = (newStart != null && newEnd != null && newStart <= existingEnd && newEnd >= existingStart);//
            system.debug('isOverlap4 '+isOverlap);
            system.debug('newStart'+newStart+'newEnd'+newEnd+'existingStart'+existingStart+'existingEnd'+existingEnd);
        }
        
        system.debug('isOverlap: ' + isOverlap);
        
        return isOverlap;
    }
    //Logic for HRP-11103 ***Ends here***
    /**
* Raise error in case account associated with account service already has valid BPL
* */

    
    /* The logic of updateCallListRecipientFlagOnOpp is moved to opportuinityContactRole Trigger Handler 
* part of HRP-6219 
*/ 
    public static void updateCallListRecipientFlagOnOpp(Map<Id,Account_Service_Role__c> oldMap, List<Account_Service_Role__c> newList){
        
        List<id> callListRecipientAccountList = new List<id>();
        for(Account_Service_Role__c accountServiceRole:newList){
			if(accountServiceRole.Account_Service_Role__c =='Call List Recipient' && (oldMap == null || (oldMap.get(accountServiceRole.id) != null && oldMap.get(accountServiceRole.id).Account_Service_Role__c != 'Call List Recipient'))){                callListRecipientAccountList.add(accountServiceRole.Account__c);
            }
        }
        List<opportunity> oppUpdateList = new List<opportunity>();         
        List<Opportunity> oppList = new List<Opportunity>([select id, Call_List_Recipient_Exist__c from opportunity where AccountId =:callListRecipientAccountList and stagename !='closed']);
        for (Opportunity opp : oppList){
            opp.Call_List_Recipient_Exist__c = true;
            oppUpdateList.add(opp);
        }
        
        //if (Schema.sObjectType.opportunity.fields.Call_List_Recipient_Exist__c.isUpdateable()) {}
        if(oppUpdateList.size()>0) {
            update oppUpdateList;  
        }
    }
    //HRP-9531 Update Account Contact_BPL__c field
    public static void updateBPLonAccount(List<Account_Service_Role__c> newItems){
        try{
            Set<Id> accountIds = new Set<Id>();
            Set<Id> asrIds = new Set<Id>();
            List<Account_Service_Role__c> asrList = new List<Account_Service_Role__c>();
            Map<Id,List<Account_Service_Role__c>> accAsrMap = new Map<Id,List<Account_Service_Role__c>>();
            if(newItems != null){
                if(Trigger.isExecuting && Trigger.isDelete){
                    asrIds = new Set<Id>(new Map<Id, Account_Service_Role__c>(newItems).keySet());
                }
                for(Account_Service_Role__c asr : newItems){
                    accountIds.add(asr.Account__c);
                }
            }
            if(!accountIds.isEmpty()){
                asrList = [SELECT Id, 
                           Contact__c, 
                           Account_Service_Role__c,
                           Account__c,
                           End_Date__c,
                           Start_Date__c 
                           FROM Account_Service_Role__c 
                           WHERE Account_Service_Role__c = 'Blood Program Leader' 
                           AND Account__c IN: accountIds 
                           AND Start_Date__c != null
                           AND Id NOT IN: asrIds
                           ORDER BY Account__c, Start_Date__c ASC];
            }
            if(!asrList.isEmpty()){
                for(Account_Service_Role__c asr : asrList){
                    if(accAsrMap.isEmpty() || !accAsrMap.containsKey(asr.Account__c)){
                        accAsrMap.put(asr.Account__c,new List<Account_Service_Role__c>());
                    }
                    accAsrMap.get(asr.Account__c).add(asr);
                }
            }
            updateAccountContactBPL(accountIds,accAsrMap);
        }catch(Exception ex){
            System.debug('An exception occurred: ' + ex.getMessage());
        }
    }
    public static void updateAccountContactBPL(Set<Id> accountIds,Map<Id,List<Account_Service_Role__c>> accAsrMap){
        List<Account> updateableAccounts = new List<Account>();
        if(accAsrMap == null || accountIds == null || accountIds.isEmpty()){
            return;
        }
        for(Id accId : accountIds){
            Id conId = null;
            Account acc = new Account(Id = accId);
            if(!accAsrMap.isEmpty() && accAsrMap.containsKey(accId)){
                for(Account_Service_Role__c asr : accAsrMap.get(accId)){
                    if(asr.Start_Date__c <= System.today() && (asr.End_Date__c == null || asr.End_Date__c > System.today())){
                        conId = asr.Contact__c;
                    }
                }
            }
            updateableAccounts.add(new Account(Id = accId,Contact_BPL__c = conId));
        }
        if(!updateableAccounts.isEmpty()){
            Database.update(updateableAccounts,false);
        }
    }

    /*
    public static void markContactAsInactive(Map<Id,Account_Service_Role__c> oldMap, List<Account_Service_Role__c> newList){
        System.debug('AccountServiceRole markContactAsInactive');
        Set<Id> contactIdsToUpdate = new Set<Id>();
        for(Account_Service_Role__c newAsr : newList){
            Account_Service_Role__c oldAsr = oldMap.get(newAsr.Id);
            // Only act if End Date is newly populated and End Reason is Deceased
            if (oldAsr.End_Date__c == null && newAsr.End_Date__c != null && newAsr.Account_Service_End_Reason__c.equalsIgnoreCase('Deceased') && newAsr.Contact__c != null) {
                contactIdsToUpdate.add(newAsr.Contact__c);
            }
        }
        if (!contactIdsToUpdate.isEmpty()) {
            List<Contact> contactsToUpdate = [SELECT Id, Active__c FROM Contact WHERE Id IN :contactIdsToUpdate];
            for (Contact con : contactsToUpdate) {
                con.Active__c = false;
            }
            update contactsToUpdate;
            System.debug('Updated Contact as Inactive');
        }
    } */
}