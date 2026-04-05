/**
 * @description       : Synchronizes Task Planning configurations from Accounts to their child
 *                      Template Opportunities. This batch uses Database.Stateful to collect
 *                      affected Template IDs, which are then passed to a second batch
 *                      to continue the cascade down to individual Drive Opportunities.
 * @author            : Elam Pandian
 * @group             : Task Planning
 * @last modified on  : 01/19/2026
 **/

public class BSF_AccountTaskPlanningCascadeBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Set<Id> sourceAccountIds;
    private Set<Id> processedTemplateIds = new Set<Id>();

    /**
     * @description Constructor to initialize the batch with specific Account IDs.
     * @param accountIds A Set of Account IDs acting as the source of truth for configuration.
     */

    public BSF_AccountTaskPlanningCascadeBatch(Set<Id> accountIds) {
        this.sourceAccountIds = accountIds;
    }

    /**
     * @description Locates child Template Opportunities that are linked to the source accounts
     *              and have not been manually overridden by a user.
     * @param bc Standard BatchableContext.
     * @return Database.QueryLocator containing the Template Opportunities.
     */

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query child Templates that have NOT been manually overridden
        return Database.getQueryLocator([
            SELECT Id, AccountId, Planning_Path__c
            FROM Opportunity
            WHERE AccountId IN :sourceAccountIds
            AND Is_Template__c = TRUE
            AND Is_Path_Overridden__c = FALSE
        ]);
    }

    /**
     * @description Performs the data sync from Account to Template and collects IDs for the next phase.
     * @param bc Standard BatchableContext.
     * @param scope List of Template Opportunities in the current chunk.
     */

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        for(Opportunity templateOpportunity : scope) {
            processedTemplateIds.add(templateOpportunity.Id);
        }
        BSF_TaskPlanningService.cascadeAccountToTemplates(scope);
    }

    /**
     * @description Chains the next batch in the sequence (Template to Drive cascade)
     *              if any templates were processed.
     * @param bc Standard BatchableContext.
     */

    public void finish(Database.BatchableContext bc) {
        if(!processedTemplateIds.isEmpty()) {
            Database.executeBatch(new BSF_TemplateTaskPlanningCascadeBatch(processedTemplateIds), 50);
        }
    }
}