/* Description: This class contains all template related functionalities

    Modification Log:
    Name              Date         Description
    ----              ----         -----------
    Priti Jana      9/22/2025     Created for HRP-7470
    
*******************************************************************************/

public without sharing class TemplateService implements Callable {

    /**************************************** CALLABLE INTERFACE  ***************************************/

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'createPrimaryContactObj' {
                    createPrimaryContactObj((Map<Id, Id>) JSON.deserialize((String) params.get('param1'), Map<Id, Id>.class));
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    /***************************************************************************************************/

    public static void createPrimaryContactDriveServiceRole(List<Opportunity> templates) {
        Map<Id, Id> map_templateId_primaryContactId = new Map<Id, Id>();

        for (Opportunity template : templates) {
            if(String.isBlank(template.Primary_Drive_Contact__c)) continue;

            map_templateId_primaryContactId.put(template.Id, template.Primary_Drive_Contact__c);
        }

        if (!map_templateId_primaryContactId.isEmpty()) {
            if (!System.isBatch()) {
                skedFutureCallPostCommitEventHandler.publishFutureCallEvent(
                    TemplateService.class.getName(),
                    'createPrimaryContactObj',
                    map_templateId_primaryContactId
                );
            } else {
                createPrimaryContactObj(map_templateId_primaryContactId);
            }
        }
    }

    @InvocableMethod(label='Get Default Primary Contact' description='Get default primary contact for templates.')
    public static List<String> getDefaultPrimaryDriveContact(List<TemplateWrapper> templateWrapper) {
        Set<String> templateAccountIds = new Set<String>();
        List<String> result = new List<String>();
        Map<Id, Account_Service_Role__c> map_accountId_bplServiceRole = new Map<Id, Account_Service_Role__c>();

        if(templateWrapper == null || templateWrapper.isEmpty()) {
            return result;
        }

        for(TemplateWrapper data : templateWrapper) {
            if(String.isBlank(data.accountId)) continue;

            templateAccountIds.add(data.accountId);
        }

        List<Account_Service_Role__c> serviceRoles = [
            SELECT Id, Account__c, Contact__c, 
            Contact__r.FirstName, CreatedDate,
            Start_Date__c, Account_Service_Role__c
            FROM Account_Service_Role__c
            WHERE Account_Service_Role__c IN (:BSF_Constants.BLOOD_PROGRAM_LEADER_ROLE, :BSF_Constants.ACCOUNT_CONTACT_ROLE)
            AND Account__c IN :templateAccountIds
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

        for (String accountId : templateAccountIds) {
            for (Account_Service_Role__c accountContact : serviceRoles) {
                if(accountId == accountContact.Account__c) {
                    result.add((String)accountContact.Contact__c);
                    break;
                }
            }
        }  

        return result;
    }

    /**************************************** PRIVATE METHODS ********************************************/

    @testVisible
    private static void createPrimaryContactObj(Map<Id, Id> map_templateId_primaryContactId) {
        List<OpportunityContactRole> driveServiceRolesToInsert = new List<OpportunityContactRole>();

        for(Id templateId : map_templateId_primaryContactId.keySet()) {
            Id serviceRoleContactId = map_templateId_primaryContactId.get(templateId);

            driveServiceRolesToInsert.add(new OpportunityContactRole(
                OpportunityId = templateId,
                ContactId = serviceRoleContactId,
                Role = BSF_Constants.PRIMARY_CONTACT_ROLE
            ));
        }

        if(driveServiceRolesToInsert != null && !driveServiceRolesToInsert.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(driveServiceRolesToInsert, false);
            insert (BSF_Utilities.createErrorLog(
                srList,
                'Template Drive Contact',
                'TemplateService',
                'createPrimaryContactObj',
                'Error',
                'Error in creating template primary contact role'
            ));
        }
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

    public class TemplateWrapper {
        @InvocableVariable (label='Account Record Id' required = true)
        public String accountId;
    }
}