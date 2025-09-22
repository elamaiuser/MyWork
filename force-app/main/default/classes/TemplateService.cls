/* Description: This class contains all template related functionalities

    Modification Log:
    Name              Date         Description
    ----              ----         -----------
    Priti Jana      9/22/2025     Created for HRP-7470
    
*******************************************************************************/

public with sharing class TemplateService implements Callable {

    /**************************************** CALLABLE INTERFACE  ***************************************/

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'performTemplatePrimaryContactSync' {
                    performTemplatePrimaryContactSync((Map<Id, Id>) JSON.deserialize((String) params.get('param1'), Map<Id, Id>.class));
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    /***************************************************************************************************/

    public static void populatePrimaryContact(List<Opportunity> templates) {
        Map<Id, Id> map_templateId_accountId = new Map<Id, Id>();

        for (Opportunity template : templates) {
            map_templateId_accountId.put(template.Id, template.AccountId);
        }

        if (!map_templateId_accountId.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallPostCommitEventHandler.publishFutureCallEvent(
                    TemplateService.class.getName(),
                    'performTemplatePrimaryContactSync',
                    map_templateId_accountId
                );
            } else {
                performTemplatePrimaryContactSync(map_templateId_accountId);
            }
        }
    }

    /**************************************** PRIVATE METHODS ********************************************/

    @testVisible
    private static void performTemplatePrimaryContactSync(Map<Id, Id> map_templateId_accountId) {
        Map<Id, Account_Service_Role__c> map_accountId_bplServiceRole = new Map<Id, Account_Service_Role__c>();
        List<OpportunityContactRole> driveContactRolesToInsert = new List<OpportunityContactRole>();

        List<Account_Service_Role__c> serviceRoles = [
            SELECT Id, Account__c, Contact__c, 
            Contact__r.FirstName, CreatedDate,
            Start_Date__c, Account_Service_Role__c
            FROM Account_Service_Role__c
            WHERE Account_Service_Role__c IN (:BSF_Constants.BLOOD_PROGRAM_LEADER_ROLE, :BSF_Constants.ACCOUNT_CONTACT_ROLE)
            AND Account__c IN :map_templateId_accountId.values()
            ORDER BY Account_Service_Role__c DESC
        ];

        if(serviceRoles != null && !serviceRoles.isEmpty()) {
            for (Account_Service_Role__c serviceRole : serviceRoles) {
                if(serviceRole.Account_Service_Role__c.equalsIgnoreCase(BSF_Constants.BLOOD_PROGRAM_LEADER_ROLE)) {
                    map_accountId_bplServiceRole.put(serviceRole.Account__c, serviceRole);
                }
            }
        }

        List<AccountServiceRoleWrapperModel> accountContacts = new List<AccountServiceRoleWrapperModel>();
        for (Account_Service_Role__c serviceRole : serviceRoles) {
            if(!map_accountId_bplServiceRole.containsKey(serviceRole.Account__c)) {
                AccountServiceRoleWrapperModel wrapper = new AccountServiceRoleWrapperModel();
                wrapper.serviceRole = serviceRole;
                accountContacts.add(wrapper);
            }
        }

        accountContacts.sort();

        serviceRoles.clear();
        serviceRoles.addAll(map_accountId_bplServiceRole.values());

        for(AccountServiceRoleWrapperModel wrapper : accountContacts) serviceRoles.add(wrapper.serviceRole);

        for (Id templateId : map_templateId_accountId.keySet()) {
            Id accountId = map_templateId_accountId.get(templateId);

            for (Account_Service_Role__c accountContact : serviceRoles) {
                if(accountId == accountContact.Account__c) {
                    driveContactRolesToInsert.add(createPrimaryContactObj(templateId, accountContact.Contact__c));
                    break;
                }
            }
        }  

        if(driveContactRolesToInsert != null && !driveContactRolesToInsert.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(driveContactRolesToInsert, false);
            insert (BSF_Utilities.createErrorLog(
                srList,
                'Template Drive Contact',
                'TemplateService',
                'populatePrimaryContact',
                'Error',
                'Error in populating template primary contact'
            ));
        }
    }

    @testVisible
    private static OpportunityContactRole createPrimaryContactObj(Id templateId, Id serviceRoleContactId) {
        return new OpportunityContactRole(
            OpportunityId = templateId,
            ContactId = serviceRoleContactId,
            Role = BSF_Constants.PRIMARY_CONTACT_ROLE
        );
    }

    /*********************************************************** Nested Classes ***********************************************************/
    private class AccountServiceRoleWrapperModel implements Comparable {
        public Account_Service_Role__c serviceRole;
        
        public virtual Integer compareTo(Object compareToRecord) {
            AccountServiceRoleWrapperModel compareTo = (AccountServiceRoleWrapperModel)compareToRecord;
            Integer returnValue = 0;
            
            if (serviceRole.Start_Date__c < compareTo.serviceRole.Start_Date__c) {
                returnValue = -1;
            }
            else if (serviceRole.Start_Date__c > compareTo.serviceRole.Start_Date__c) {
                returnValue = 1;
            }
            else {
                if (serviceRole.CreatedDate < compareTo.serviceRole.CreatedDate) {
                    returnValue = -1;
                }
                else if (serviceRole.CreatedDate > compareTo.serviceRole.CreatedDate) {
                    returnValue = 1;
                }
                else {
                    if (serviceRole.Contact__r.FirstName < compareTo.serviceRole.Contact__r.FirstName) {
                        returnValue = -1;
                    }
                    else if (serviceRole.Contact__r.FirstName > compareTo.serviceRole.Contact__r.FirstName) {
                        returnValue = 1;
                    }
                }
            }
            return returnValue;
        }
    }
}