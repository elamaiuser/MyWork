public class skedDriveVehicleTypeSyncEventTrigHandler  extends skedPlatformEventHub {
    public override void onAfterInsert() {
        processNewEvents(this.context.newRecords);
    }

    public static void processNewEvents(List<sked_DriveVehicle_Type_Sync_Event__e> newEvents) {
        List<skedProcessEventResult> callResults = new List<skedProcessEventResult>();
        for (sked_DriveVehicle_Type_Sync_Event__e event : newEvents) {
            Callable classCallable = (Callable) Type.forName(event.sked_Class_Name__c).newInstance();
            callResults.add((skedProcessEventResult) classCallable.call(
                event.sked_Method_Name__c,
                new Map<String, Object>{
                    'param1' => event.sked_Parameter_Data__c,
                    'param2' => event.sked_Parameter_2_Data__c,
                    'param3' => event.sked_Parameter_3_Data__c,
                    'param4' => event.sked_Parameter_4_Data__c
                }
            ));
        }

        // do something with call results - maybe publish notifications for failed processes?
    }

    public static void publishFutureCallEvent(String className, String methodName, Object param1) {
        publishFutureCallEvent(className, methodName, param1, null);
    }

    public static void publishFutureCallEvent(String className, String methodName, Object param1, Object param2) {
        publishFutureCallEvent(className, methodName, param1, param2, null);
    }

    public static void publishFutureCallEvent(String className, String methodName, Object param1, Object param2, Object param3) {
        publishFutureCallEvent(className, methodName, param1, param2, param3, null);
    }

    public static void publishFutureCallEvent(String className, String methodName, Object param1, Object param2, Object param3, Object param4) {
        Eventbus.publish(new sked_DriveVehicle_Type_Sync_Event__e(
            sked_Class_Name__c = className,
            sked_Method_Name__c = methodName,
            sked_Parameter_Data__c = JSON.serialize(param1),
            sked_Parameter_2_Data__c = JSON.serialize(param2),
            sked_Parameter_3_Data__c = JSON.serialize(param3),
            sked_Parameter_4_Data__c = JSON.serialize(param4)
        ));
    }
}