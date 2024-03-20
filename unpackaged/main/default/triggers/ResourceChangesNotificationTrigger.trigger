/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 05/16/2023			Barnojit Sharma				Trigger on Resource_Changes_Notification__e Platform Event (HRP-1566)
 *****************************************************************************************************************************************************************************
*/
trigger ResourceChangesNotificationTrigger on Resource_Changes_Notification__e (after insert) {
    ResourceNotificationEmailUtil.sendNotificationEmails((List<Resource_Changes_Notification__e>) trigger.new);
}