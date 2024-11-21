/*
 * Date					Developer Name			     										Comments
  *****************************************************************************************************************************************************************
 * 06/09/2025			Raktim Ghosal			One Time Batch to update Drive Date Field on Task for it's Corresponding Opportunity, Order and DOC (HRP-12700)
  ***************************************************************************************************************************************************************** 
*/
public class UpdateTaskDriveDateBatch implements Database.Batchable<SObject> {
     	
   public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT ID, What.Type, WhatId, Drive_Date__c, Status 
            FROM Task 
            WHERE What.Type IN ('Opportunity', 'Order', 'sked_Drive__c') 
            AND Drive_Date__c = NULL 
            AND Status NOT IN ('Completed', 'Cancelled')
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        try{
            Set<ID> oppId = new Set<ID>();
            Set<ID> orderId = new Set<ID>();
            Set<ID> driveId = new Set<ID>();
            
            List<Task> tasks = (List<Task>)scope;
            
            for (Task task : tasks) {
                if (task.What.Type.equalsIgnoreCase('Opportunity')) {
                    oppId.add(task.WhatId);
                } else if (task.What.Type.equalsIgnoreCase('Order')) {
                    orderId.add(task.WhatId);
                } else if (task.What.Type.equalsIgnoreCase('sked_Drive__c')) {
                    driveId.add(task.WhatId);
                }
            }
    
            Map<ID, Opportunity> getOppDate = new Map<ID, Opportunity>([Select ID, Drive_Date__c From Opportunity Where ID IN :oppId AND Drive_Date__c != NULL]);
            Map<ID, Order> getOrderDate = new Map<ID, Order>([Select ID, Drive_Date__c From Order Where ID IN :orderId AND Drive_Date__c != NULL]);
            Map<ID, sked_Drive__c> getDriveDate = new Map<ID, sked_Drive__c>([Select ID, sked_Drive_Date__c From sked_Drive__c Where ID IN :driveId]);
            
            for (Task task : tasks) {
                if (task.What.Type.equalsIgnoreCase('Opportunity') && getOppDate.containsKey(task.WhatId)) {
                    task.Drive_Date__c = getOppDate.get(task.WhatId).Drive_Date__c;
                } else if (task.What.Type.equalsIgnoreCase('Order') && getOrderDate.containsKey(task.WhatId)) {
                    task.Drive_Date__c = getOrderDate.get(task.WhatId).Drive_Date__c;
                } else if (task.What.Type.equalsIgnoreCase('sked_Drive__c') && getDriveDate.containsKey(task.WhatId)) {
                    task.Drive_Date__c = getDriveDate.get(task.WhatId).sked_Drive_Date__c;
                }
            }
            if (!tasks.isEmpty()) {
               Database.SaveResult[] results = Database.update(tasks, false);
               List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(results, 'Update Task Drive Date','UpdateTaskDriveDateBatch','UpdateTaskDriveDateBatchForOPP_Order_DOC','Error','Error in updating');
               Insert logList;
            }
    	}catch(Exception ex) {
            insert BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'UpdateTaskDriveDateBatch',
                'Execute Method Call',
                'Updates Task Drive Date for Opportunity, Order and DOC in Task',
                'Updates Task Drive Date for Opportunity, Order and DOC in Task',
                'Task',
                ''
            );
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch processing completed.');
    }
}