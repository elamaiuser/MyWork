//This batch needs to be run with chunk size = 1
global class skedDriveRankingBatch implements Database.Batchable<sked_Drive__c>, Database.AllowsCallouts, Database.Stateful {

    Set<Id> skedFixedSiteDrives;
    Set<Id> driveIds;
    List<String> inputKeys;
    Set<string> processedKey;
    String driveSource = '';
    String runType;
    Date driveDate;

    global skedDriveRankingBatch(String runType, String Source, Date driveDate, List<sked_Drive__c> inputDrives) {
        this.runType = runType;
        this.driveSource = source;
        this.driveDate = driveDate;
        this.driveIds = new Set<Id>();
        this.processedKey = new Set<string>();
        for (sked_Drive__c inputDrive : inputDrives) {
            this.driveIds.add(inputDrive.Id);
            if(inputDrive.sked_Type_of_Drive__c == skedConstants.DRIVE_TYPE_FIXED_SITE) {
                if (this.skedFixedSiteDrives == null) {
        			this.skedFixedSiteDrives = new Set<Id>();
    			}
    			this.skedFixedSiteDrives.add(inputDrive.Id);
            }
        }                
	}
    
    global skedDriveRankingBatch(List<sked_Drive__c> inputDrives) {
        this.driveIds = new Set<Id>();
        for (sked_Drive__c inputDrive : inputDrives) {
            this.driveIds.add(inputDrive.Id);
        }                
        this.processedKey = new Set<string>();
    }

    global skedDriveRankingBatch(Set<String> keys) {
        this.processedKey = new Set<string>();
        this.inputKeys = new List<String>();
        this.inputKeys.addAll(keys);
    }
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        List<sked_Drive__c> drives;
        if(this.driveIds != null && !this.driveIds.isEmpty()) {
            drives = [
                SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Point__c, sked_Projected_Registered_Donors__c
                FROM sked_Drive__c
                WHERE Id IN :this.driveIds
            ];
        } else if (this.inputKeys != null && !this.inputKeys.isEmpty()) {
            String key = this.inputKeys[0];
            List<String> splitKey = key.split(':');
            String collectionOpId = splitKey[0];
            Date driveDate = Date.valueOf(splitKey[1]);

            drives = [
                SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Point__c, sked_Projected_Registered_Donors__c, sked_Status__c, sked_Type_Of_Drive__c
                FROM sked_Drive__c
                WHERE sked_Drive_Date__c = :driveDate
                AND sked_Collection_Operation__c = :collectionOpId
                AND sked_Type_of_Drive__c = 'Mobile'
                AND sked_Status__c = 'Draft'
                LIMIT 1
            ];
        }

        return drives;
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        sked_Drive__c skedDrive = records.get(0);
        string driveDateStr = Json.serialize(skedDrive.sked_Drive_Date__c).replace('"', '');
        string key = skedDrive.sked_Collection_Operation__c + ':' + driveDateStr;
        if (!this.processedKey.contains(key)) {
			List<sked_Drive__c> draftDrives = [
                SELECT Id, sked_Point__c, sked_Projected_Registered_Donors__c, sked_Rank__c, CreatedDate
                FROM sked_Drive__c
                WHERE sked_Collection_Operation__c = :skedDrive.sked_Collection_Operation__c
                AND sked_Drive_Date__c = :skedDrive.sked_Drive_Date__c
                AND sked_Type_of_Drive__c = 'Mobile'
                AND sked_Status__c = 'Draft'
            ];
            
            List<driveWrapperModel> wrappers = new List<driveWrapperModel>();
            for (sked_Drive__c draftDrive : draftDrives) {
                driveWrapperModel wrapper = new driveWrapperModel();
                wrapper.skedDrive = draftDrive;
                wrappers.add(wrapper);
            }
            wrappers.sort();
            
            List<sked_Drive__c> recordsToUpdate = new List<sked_Drive__c>();
            for (integer i = 0; i < wrappers.size(); i++) {
                driveWrapperModel wrapper = wrappers.get(i);
                decimal currentRank = wrapper.skedDrive.sked_Rank__c;
                wrapper.skedDrive.sked_Rank__c = i + 1;
                if (currentRank != wrapper.skedDrive.sked_Rank__c) {
                    recordsToUpdate.add(wrapper.skedDrive);
                }
            }
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            
            this.processedKey.add(key);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (this.inputKeys != null && !this.inputKeys.isEmpty()) {
            this.inputKeys.remove(0);
            if (!this.inputKeys.isEmpty()) {
                Set<String> inputKeySet = new Set<String>();
                inputKeySet.addAll(this.inputKeys);
                Database.executeBatch(new skedDriveRankingBatch(inputKeySet), 1);
            }
        }

        Boolean isResourceAllocationNeeded = (this.driveSource == null || String.isBlank(this.driveSource)) && skedFixedSiteDrives != null && !skedFixedSiteDrives.isEmpty();
        if(!isResourceAllocationNeeded) {
            isResourceAllocationNeeded = this.driveSource != null && !String.isBlank(this.driveSource) && !this.driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_ADHOC_CALENDAR_BUILD);
        }

        if(isResourceAllocationNeeded) {
            Database.executeBatch(
                new DriveResourceAllocationBatch(
                    runType, 
                    driveSource, 
                    skedConstants.DRIVE_TYPE_FIXED_SITE,
                    this.driveDate,  
                    driveSource.equalsIgnoreCase('Calendar Build') ? new Set<Id>() : skedFixedSiteDrives), 1
                );
        } 
    }
    
    /*********************************************************** Nested Classes ***********************************************************/
    global class driveWrapperModel implements Comparable {
        public sked_Drive__c skedDrive;
        
        public virtual Integer compareTo(Object compareToRecord) {
            driveWrapperModel compareTo = (driveWrapperModel)compareToRecord;
            Integer returnValue = 0;
            
            if (skedDrive.sked_Point__c > compareTo.skedDrive.sked_Point__c) {
                returnValue = -1;
            }
            else if (skedDrive.sked_Point__c < compareTo.skedDrive.sked_Point__c) {
                returnValue = 1;
            }
            else {
                if (skedDrive.sked_Projected_Registered_Donors__c > compareTo.skedDrive.sked_Projected_Registered_Donors__c) {
                    returnValue = -1;
                }
                else if (skedDrive.sked_Projected_Registered_Donors__c < compareTo.skedDrive.sked_Projected_Registered_Donors__c) {
                    returnValue = 1;
                }
                else {
                    if (skedDrive.CreatedDate < compareTo.skedDrive.CreatedDate) {
                        returnValue = -1;
                    }
                    else if (skedDrive.CreatedDate > compareTo.skedDrive.CreatedDate) {
                        returnValue = 1;
                    }
                }
            }
            return returnValue;
        }
    }
}