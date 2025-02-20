public class skedFutureCallPostCommitEventHandler extends skedPlatformEventHub {
    
    public override void onAfterInsert() {
        processNewEvents(this.context.newRecords);
    }

    public static void processNewEvents(List<sked_Future_Call_Post_Commit_Event__e> newEvents) {
        List<skedProcessEventResult> callResults = new List<skedProcessEventResult>();
        for (sked_Future_Call_Post_Commit_Event__e event : newEvents) {
            Callable classCallable = (Callable) Type.forName(event.sked_Class_Name__c).newInstance();
            callResults.add((skedProcessEventResult) classCallable.call(
                event.sked_Method_Name__c,
                new Map<String, Object>{
                    'param1' => event.sked_Parameter_1_Data__c
                }
            ));
        }
    }

    public static void publishFutureCallEvent(String className, String methodName, Object param1) {
        Eventbus.publish(new sked_Future_Call_Post_Commit_Event__e(
            sked_Class_Name__c = className,
            sked_Method_Name__c = methodName,
            sked_Parameter_1_Data__c = JSON.serialize(param1)
        ));
    }

}