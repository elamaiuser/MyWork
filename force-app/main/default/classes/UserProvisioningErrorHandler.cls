public class UserProvisioningErrorHandler implements Callable {
    
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'insertErrorLogs' {
                return handleInsertErrorLogs(args);
            }
            when else {
                return null;
            }
        }
    }

    private Object handleInsertErrorLogs(Map<String, Object> args) {
        List<BSF_Error_Log__c> allLogsToInsert = new List<BSF_Error_Log__c>();
        
        for (Integer i = 1; i <= 4; i++) {
            String logsJson = (String) args.get('param' + i);
            
            if (String.isNotBlank(logsJson) && logsJson != 'null') {
                List<BSF_Error_Log__c> chunk = 
                    (List<BSF_Error_Log__c>) JSON.deserialize(logsJson, List<BSF_Error_Log__c>.class);
                
                if (chunk != null && !chunk.isEmpty()) {
                    allLogsToInsert.addAll(chunk);
                }
            }
        }
        
        if (!allLogsToInsert.isEmpty()) {
            Database.SaveResult[] logResults = Database.insert(allLogsToInsert, false, AccessLevel.SYSTEM_MODE);
            return true;
        }
        return false;
    }
    
    private static void dispatchErrorLogs(List<BSF_Error_Log__c> errorLogs) {
        if (errorLogs == null || errorLogs.isEmpty()) return;
        
        Integer MAX_CHARS_PER_PARAM = 120000; 
        
        List<List<BSF_Error_Log__c>> allChunks = new List<List<BSF_Error_Log__c>>();
        List<BSF_Error_Log__c> currentChunk  = new List<BSF_Error_Log__c>();
        Integer currentLength = 2;
        
        for (BSF_Error_Log__c log : errorLogs) {
            String jsonStr = JSON.serialize(log);
            Integer logLen = jsonStr.length() + 1;
            
            if (currentLength + logLen > MAX_CHARS_PER_PARAM) {
                allChunks.add(currentChunk);
                currentChunk = new List<BSF_Error_Log__c>();
                currentLength = 2;
            }
            
            currentChunk.add(log);
            currentLength += logLen;
        }
        
        if (!currentChunk.isEmpty()) {
            allChunks.add(currentChunk);
        }

        for (Integer i = 0; i < allChunks.size(); i += 4) {
            List<BSF_Error_Log__c> param1 = (i < allChunks.size())     ? allChunks[i]     : null;
            List<BSF_Error_Log__c> param2 = (i + 1 < allChunks.size()) ? allChunks[i + 1] : null;
            List<BSF_Error_Log__c> param3 = (i + 2 < allChunks.size()) ? allChunks[i + 2] : null;
            List<BSF_Error_Log__c> param4 = (i + 3 < allChunks.size()) ? allChunks[i + 3] : null;
            
            skedFutureCallEventHandler.publishFutureCallEvent(
                'UserProvisioningErrorHandler', 
                'insertErrorLogs', 
                param1, 
                param2, 
                param3, 
                param4
            );
        }
    }

    public static void handleDatabaseResults(Object results, String context, String methodname) {
        if (results == null){
            return;
        }
        List<Database.Error> errors = new List<Database.Error>();
        List<BSF_Error_Log__c> errorLogs = new List<BSF_Error_Log__c>();
        

        if (results instanceof List<Database.SaveResult>) {
            List<Database.SaveResult> srList = (List<Database.SaveResult>)results;
            List<Database.SaveResult> failedSaves = new List<Database.SaveResult>(); 
            for (Database.SaveResult sr : srList) { 
                if (!sr.isSuccess()) {
                    failedSaves.add(sr);
                    errors.addAll(sr.getErrors()); 
                }
            }
            if (!failedSaves.isEmpty()) {
                errorLogs = BSF_Utilities.createErrorLog(failedSaves, context, UserProvisioningService.class.getName(), methodname, BSF_Constants.BATCH_STATUS_ERROR, 'DML Save Error');
            }
        }
        else if (results instanceof List<Database.DeleteResult>) {
            List<Database.DeleteResult> drList = (List<Database.DeleteResult>)results;
            for (Database.DeleteResult dr : drList) { 
                if (!dr.isSuccess()){ 
                    errors.addAll(dr.getErrors()); 
                }
            }
            errorLogs = BSF_Utilities.createErrorLog(drList, context, UserProvisioningService.class.getName(), methodname, BSF_Constants.BATCH_STATUS_ERROR, 'DML Delete Error');
        }
        
        if (!errorLogs.isEmpty()) {
            dispatchErrorLogs(errorLogs);
        }
    }
}