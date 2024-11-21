public class skedErrorUtils {
    public static String getErrorString(Database.Error error) {
        return getErrorStrings(new List<Database.Error>{error})[0];
    }

    public static List<String> getErrorStrings(List<Database.Error> errors) {
        List<String> databaseErrors = new List<String>();
        for (Database.Error error : errors) {
            databaseErrors.add(
                'Fields: ' + String.join(error.fields, ', ') +
                '\nMessage: ' + error.message + 
                '\nStatus Code: ' + error.statuscode
            );
        }

        return databaseErrors;
    }

    public static String getPartialUpdateErrorString(List<Database.SaveResult> saveResults, List<sObject> affectedRecords, String sObjectName) {
        List<String> errors = new List<String>();
        errors.addAll(buildIdentifiedErrors(saveResults, affectedRecords, sObjectName));
        errors.addAll(buildUnidentifiedErrors(saveResults, affectedRecords, sObjectName));
        return errors.size() > 0 ? 'The following errors have occured:\n' + String.join(errors, '\n') : null;
    }

    private static List<String> buildIdentifiedErrors(List<Database.SaveResult> saveResults, List<SObject> affectedRecords, String sObjectName) {
        List<String> errorParts = new List<String>();
        Map<Id, Database.SaveResult> map_recordId_saveResult = new Map<Id, Database.SaveResult>();
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.getId() != null) {
                map_recordId_saveResult.put(saveResult.getId(), saveResult);
            }
        }

        for (sObject affectedRecord : affectedRecords) {
            if (map_recordId_saveResult.containsKey(affectedRecord.Id)) {
                Database.SaveResult saveResult = map_recordId_saveResult.get(affectedRecord.Id);
                if (!saveResult.isSuccess()) {
                    errorParts.add(
                        String.format(
                            '-- Object {0} with record ID {1} --', 
                            new List<String>{sObjectName, affectedRecord.Id}
                        )
                    );
    
                    for (String detailError : getErrorStrings(saveResult.getErrors())) {
                        errorParts.add(detailError);
                    }
                }
            }
        }

        return errorParts;
    }

    private static List<String> buildUnidentifiedErrors(List<Database.SaveResult> saveResults, List<SObject> affectedRecords, String sObjectName) {
        List<String> errorParts = new List<String>();
        Map<Id, Database.SaveResult> map_recordId_saveResult = new Map<Id, Database.SaveResult>();
        List<Database.SaveResult> unidentifiedSaveResults = new List<Database.SaveResult>();
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.getId() != null) {
                map_recordId_saveResult.put(saveResult.getId(), saveResult);
            } else {
                unidentifiedSaveResults.add(saveResult);
            }
        }

        List<Id> failedRecordIdsWithUnidentifiedError = new List<Id>();
        for (sObject affectedRecord : affectedRecords) {
            if (!map_recordId_saveResult.containsKey(affectedRecord.Id)) {
                failedRecordIdsWithUnidentifiedError.add(affectedRecord.Id);
            }
        }

        if (failedRecordIdsWithUnidentifiedError.size() > 0) {
            errorParts.add(
                String.format(
                    '-- Object {0} with record IDs {1} failed by following errors --', 
                    new List<String>{sObjectName, String.join(failedRecordIdsWithUnidentifiedError, ', ')}
                )
            );

            for (Database.SaveResult saveResult : unidentifiedSaveResults) {
                for (String detailError : getErrorStrings(saveResult.getErrors())) {
                    errorParts.add(detailError);
                }
            }
        }

        return errorParts;
    }
}