public class skedExpireStaffTradeEventsSchedulable implements Schedulable {

    public void execute(SchedulableContext SC) {
        expireStaffTradeEvents();
    }
    
    private static void expireStaffTradeEvents() {
        Set<String> shiftTradeCompletedStatuses = new Set<String>{
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_APPROVED,
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_CANCELLED,
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_DENIED,
            skedConstants.DRIVE_SHIFT_TRADE_STATUS_EXPIRED
        };

        List<sked_Drive_Shift_Trade__c> driveShiftTrades = [
            SELECT Id, sked_Status__c
            FROM sked_Drive_Shift_Trade__c
            WHERE sked_Status__c NOT IN :shiftTradeCompletedStatuses
            AND (sked_Requesting_Staff_Trading_Event_Date__c < TODAY OR sked_Trading_Staff_Trading_Event_Date__c < TODAY)
        ];

        for (sked_Drive_Shift_Trade__c dst : driveShiftTrades) {
            dst.sked_Status__c = skedConstants.DRIVE_SHIFT_TRADE_STATUS_EXPIRED;
        }

        update driveShiftTrades;
    }
}