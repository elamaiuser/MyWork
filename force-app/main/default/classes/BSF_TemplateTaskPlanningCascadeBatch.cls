/**
 * @description       : Batch class responsible for cascading Task Planning configurations from
 *                      Parent Templates to their child "Drive" Opportunities.
 *                      It synchronizes metadata and triggers task generation for confirmed drives.
 * @author            : Elam Pandian
 * @group             : Task Planning
 * @last modified on  : 01/19/2026
 **/
public class BSF_TemplateTaskPlanningCascadeBatch implements Database.Batchable<sObject> {
    private Set<Id> templateIds;

    /**
     * @description Constructor to initialize the batch with specific Template IDs.
     * @param ids A Set of Opportunity IDs where Is_Template__c is true.
     */

    public BSF_TemplateTaskPlanningCascadeBatch(Set<Id> ids) {
        this.templateIds = ids;
    }

    /**
     * @description Identifies child Opportunities linked to the source templates that are still
     *              active, in the future, and have not been manually overridden.
     * @param bc Standard BatchableContext.
     * @return Database.QueryLocator for the scope of child Opportunities.
     */

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query OPEN, Future Drives linked to these Templates (Not Overridden)
        return Database.getQueryLocator([
            SELECT Id, Parent_Template_Id__c, Drive_Status__c, Drive_Date__c, Planning_Path__c
            FROM Opportunity
            WHERE Parent_Template_Id__c IN :templateIds
            AND Is_Template__c = FALSE
            AND Is_Path_Overridden__c = FALSE
            AND IsClosed = FALSE
            AND Drive_Date__c >= TODAY
        ]);
    }

    /**
     * @description Orchestrates the cascade of configurations and immediately triggers task
     *              creation for any drive that is currently in a 'Confirmed' status.
     * @param bc Standard BatchableContext.
     * @param scope List of Opportunities to be processed in the current chunk.
     */

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        // 1. Cascade Logic (Clean Queue -> Clone from Template)
        Set<Id> confirmedDriveIds = BSF_TaskPlanningService.cascadeTemplateToDrives(scope);

        // 2. Trigger Task Generation for Confirmed Drives
        if(!confirmedDriveIds.isEmpty()) {
            BSF_TaskPlanningService.generateTasksFromQueue(confirmedDriveIds);
        }
    }

    /**
     * @description Simple debug log to indicate batch completion.
     * @param bc Standard BatchableContext.
     */

    public void finish(Database.BatchableContext bc) {
        System.debug('BSF_TemplateTaskPlanningCascadeBatch Finished');
    }
}