global class skedAutoApprovePTOBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    private Set<Id> recordIds;

    global skedAutoApprovePTOBatch(Set<Id> recordIds) {
        this.recordIds = recordIds;
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        List<sked_Staffing_Budget__c> staffingBudgets = [
            SELECT Id
            FROM sked_Staffing_Budget__c
            WHERE Id IN :this.recordIds
        ];
        return staffingBudgets;
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Staffing_Budget__c> newRecords) {
        List<sked_Staffing_Budget_Availability__c> staffingBudgetAvailabilities = [
            SELECT Id, sked_Availability__r.sked_Ranking__c, sked_Staffing_Budget__c, CreatedDate, sked_Availability__r.sked_Custom_Status__c,
            sked_Availability__r.sked_Recurring_Schedule__c, sked_Availability__r.sked__Resource__c,
            sked_Availability__r.sked__Resource__r.sked_Seniority_Rank__c, sked_Availability__r.sked__Resource__r.sked_Collection_Operation_Id__c,
            sked_Staffing_Budget__r.sked_Bidding_End_Date__c, sked_Availability__r.CreatedDate, sked_Availability__r.sked__Start__c
            FROM sked_Staffing_Budget_Availability__c
            WHERE sked_Staffing_Budget__c IN :newRecords
            AND sked_Availability__r.sked__Is_Available__c = FALSE
            AND sked_Availability__r.sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO
            AND (sked_Availability__r.sked_Custom_Status__c = :skedConstants.AVAILABILITY_STATUS_WAITLIST OR sked_Availability__r.sked_Custom_Status__c =: skedConstants.AVAILABILITY_STATUS_PENDING)
            AND sked_Staffing_Budget__r.sked_Request_Type__c = :skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT
            ORDER BY sked_Availability__r.sked_Recurring_Schedule__r.sked_Availability_Count__c DESC NULLS LAST,
            sked_Availability__r.sked__Resource__r.sked_Seniority_Rank__c ASC NULLS LAST,
            CreatedDate ASC
        ];

        Set<Id> resourceIds = new Set<Id>();
        for (sked_Staffing_Budget_Availability__c sba : staffingBudgetAvailabilities) {
            resourceIds.add(sba.sked_Availability__r.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Primary_Region__c, sked_FCC_Code__c,
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                sked__Primary_Region__r.sked__Timezone__c,
                (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked_Priority__c
                FROM sked__ResourceTags__r
                WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                AND sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE
                ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        Map<Id, Set<Date>> datesByResourceId = getUnavailabilityDatesByResourceId(staffingBudgetAvailabilities, resourceById);
        Map<Date, List<skedStaffingBudgetWrapper>> staffingBudgetWrappersByDate = skedStaffingBudgetUtils.getSkedStaffingBudgetWrappersByDate(datesByResourceId, resourceById);
        Map<Id, List<sked_Staffing_Budget_Availability__c>> sbasBySb = getStaffingBudgetAvailabilitesByStaffingBudgetId(staffingBudgetAvailabilities);

        List<sked__Availability__c> availabilitiesToUpdate = new List<sked__Availability__c>();
        for (List<sked_Staffing_Budget_Availability__c> sbas : sbasBySb.values()) {
            Integer index = 0;
            for (Integer i = 0; i < sbas.size(); i++) {
                sked_Staffing_Budget_Availability__c sba = sbas.get(i);
                sked__Availability__c availability = sba.sked_Availability__r;
                sked__Resource__c availabilityResource = resourceById.get(availability.sked__Resource__c);
                if (availability.CreatedDate.date() <= sba.sked_Staffing_Budget__r.sked_Bidding_End_Date__c) {
                    availability.sked_Ranking__c = ++index;
                }
                availabilitiesToUpdate.add(availability);
            }
        }

        update availabilitiesToUpdate;
    }
    
    global void finish(Database.BatchableContext BC) {
    }

    private Map<Id, Set<Date>> getUnavailabilityDatesByResourceId(List<sked_Staffing_Budget_Availability__c> sbas, Map<Id, sked__Resource__c> resourceById) {
        Map<Id, Set<Date>> datesByResourceId = new Map<Id, Set<Date>>();
        for (sked_Staffing_Budget_Availability__c sba : sbas) {
            sked__Availability__c availability = sba.sked_Availability__r;
            sked__Resource__c availabilityResource = resourceById.get(availability.sked__Resource__c);
            Set<Date> datesForResource = datesByResourceId.get(availabilityResource.Id);
            if (datesForResource == null) {
                datesForResource = new Set<Date>();
            }

            Date availabilityDate = skedDateTimeUtils.getDate(availability.sked__Start__c, availabilityResource.sked__Primary_Region__r.sked__Timezone__c);
            datesForResource.add(availabilityDate);
            datesByResourceId.put(availabilityResource.Id, datesForResource);
        } 

        return datesByResourceId;
    }

    private Map<Id, List<sked_Staffing_Budget_Availability__c>> getStaffingBudgetAvailabilitesByStaffingBudgetId(List<sked_Staffing_Budget_Availability__c> sbas) {
        Map<Id, List<sked_Staffing_Budget_Availability__c>> sbasBySb = new Map<Id, List<sked_Staffing_Budget_Availability__c>>();
        for (sked_Staffing_Budget_Availability__c sba : sbas) {
            List<sked_Staffing_Budget_Availability__c> sbasForSb = sbasBySb.get(sba.sked_Staffing_Budget__c);
            if (sbasForSb == NULL) {
                sbasForSb = new List<sked_Staffing_Budget_Availability__c>();
            }
            sbasForSb.add(sba);
            sbasBySb.put(sba.sked_Staffing_Budget__c, sbasForSb);
        }  

        return sbasBySb;
    }

}