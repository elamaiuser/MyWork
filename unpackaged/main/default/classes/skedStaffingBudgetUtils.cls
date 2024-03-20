public class skedStaffingBudgetUtils {

    public static Map<Date, List<skedStaffingBudgetWrapper>> getSkedStaffingBudgetWrappersByDate(Map<Id, Set<Date>> datesByResourceId, Map<Id, sked__Resource__c> resourceById) {
        Map<Date, List<skedStaffingBudgetWrapper>> skedStaffingBudgetWrappersByDate = new Map<Date, List<skedStaffingBudgetWrapper>>();

        if (!datesByResourceId.keySet().isEmpty()) {
            skedQueryBuilder queryBuilder = new skedQueryBuilder();
            queryBuilder.setFromClause('sked_Staffing_Budget_Collection_Op__c');
            queryBuilder.addFields(new List<String>{
                    'Id', 'sked_Biomed_Collection_Operation__c', 'sked_Staffing_Budget__r.sked_Roles__c', 'sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c',
                    'sked_Staffing_Budget__r.sked_Request_Type__c', 'sked_Staffing_Budget__r.sked_Total_Slots__c',
                    'sked_Staffing_Budget__r.sked_Available_Slots__c', 'sked_Staffing_Budget__r.sked_Approved_Slots_Rollup__c',
                    'sked_Staffing_Budget__r.sked_Bidding_Start_Date__c', 'sked_Staffing_Budget__r.sked_Bidding_End_Date__c'
                });
            queryBuilder.setIsOrQuery(true);

            for (Id resourceId : datesByResourceId.keySet()) { 
                sked__Resource__c resource = resourceById.get(resourceId);
                Id resourceCollectionOpId;
                String resourcePrimaryRole;
                if (resource.sked__Primary_Region__r != NULL) {
                    resourceCollectionOpId = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                }
                if (resource.sked__ResourceTags__r != NULL && !resource.sked__ResourceTags__r.isEmpty()) {
                    resourcePrimaryRole = resource.sked__ResourceTags__r.get(0).sked__Tag__r.Name;
                }
                
                if (resourceCollectionOpId != NULL && resourcePrimaryRole != NULL) {
                    Set<Date> dates = datesByResourceId.get(resourceId);
                    String collectionOpCondition = queryBuilder.generateCondition('sked_Biomed_Collection_Operation__c = {0}', resourceCollectionOpId);
                    String rolesCondition = queryBuilder.generateMSPCondition('sked_Staffing_Budget__r.sked_Roles__c INCLUDES {0}', new List<String>{resourcePrimaryRole});
                    String datesCondition = queryBuilder.generateCondition('sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c IN {0}', dates);
                    
                    queryBuilder.addConditionGroup(new List<String>{collectionOpCondition, rolesCondition, datesCondition});
                }
            }
            string sbcoQueryStr = queryBuilder.toString();
            system.debug('#sbcoQueryStr#' + sbcoQueryStr);
            for (sked_Staffing_Budget_Collection_Op__c sbco : Database.query(sbcoQueryStr)) {
                skedStaffingBudgetWrapper wrapper = new skedStaffingBudgetWrapper();
                wrapper.collectionOpId = sbco.sked_Biomed_Collection_Operation__c;
                wrapper.staffingBudget = sbco.sked_Staffing_Budget__r;
                wrapper.approvedSlots = wrapper.staffingBudget.sked_Approved_Slots_Rollup__c;
                wrapper.totalSlots = wrapper.staffingBudget.sked_Total_Slots__c;

                List<skedStaffingBudgetWrapper> wrappersForDate = skedStaffingBudgetWrappersByDate.get(wrapper.staffingBudget.sked_Staffing_Budget_Date__c);
                if (wrappersForDate == NULL) {
                    wrappersForDate = new List<skedStaffingBudgetWrapper>();
                    skedStaffingBudgetWrappersByDate.put(wrapper.staffingBudget.sked_Staffing_Budget_Date__c, wrappersForDate);
                }
                wrappersForDate.add(wrapper);
            }
        }

        return skedStaffingBudgetWrappersByDate;
    }
}