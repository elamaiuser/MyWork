public with sharing class BSF_MarketingExceptionRequest {
    @InvocableMethod(label='Send Marketing Exception Approval Request')
    public static void marketingExceptionRequest(List<Request> requests) {

        List<Id> taskIds = new List<Id>();
        for(Request req : requests) {
            taskIds.add(req.taskId);
        }
        
        List<Task> tasks = [SELECT Id, OwnerId FROM Task WHERE Id IN :taskIds];

        Map<Id, Id> taskVsQueueMap = new Map<Id, Id>();

        for (Task task : tasks) {
            taskVsQueueMap.put(task.Id, task.OwnerId);
        }

        Map<Id, List<GroupMember>> queueVsMembersMap = new Map<Id, List<GroupMember>>();
        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :taskVsQueueMap.values()]) {
            if (!queueVsMembersMap.containsKey(gm.GroupId)) {
                queueVsMembersMap.put(gm.GroupId, new List<GroupMember>());
            }
            queueVsMembersMap.get(gm.GroupId).add(gm);
        }

        Map<Id, List<GroupMember>> taskVsQueueMemberMap = new Map<Id, List<GroupMember>>();

        for (Task task : tasks) {
            if (!taskVsQueueMemberMap.containsKey(task.Id)) {
                taskVsQueueMemberMap.put(task.Id, new List<GroupMember>());
            }
            taskVsQueueMemberMap.get(task.Id).addAll(queueVsMembersMap.get(task.OwnerId));
        }


        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for (Id taskId : taskVsQueueMemberMap.keySet()) {
            List<String> userIds = new List<String>();
            String taskURL = URL.getOrgDomainURL().toExternalForm() + '/' + taskId;
            String emailBody = 'Hello,<br/><br/>' +
                        'A Marketing Exception has been requested. Please review and take action.<br/><br/>' +
                        'Please visit the task here: <a href="' + taskUrl + '">View Task</a>';
            for(GroupMember queueMember : taskVsQueueMemberMap.get(taskId)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                email.setTargetObjectId(queueMember.UserOrGroupId);
                
                email.setSubject('Request for Marketing Exception Approval');
                
                email.setTreatTargetObjectAsRecipient(true);
                
                email.setHtmlBody(emailBody);
                
                email.setSaveAsActivity(false);
                
                emailList.add(email);
                userIds.add(queueMember.UserOrGroupId);
            }
            
        }

        System.debug('emailList##' + emailList);
        if (!emailList.isEmpty()) {
            BSF_EmailNotification.sendEmails(emailList, 'MarketingException', null);
        }

        
        Id CUstomNotificationTypeId = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType where DeveloperName='Task_Custom_Notification' LIMIT 1].Id;
        Map<Id, BSF_CustomNotification> taskVsNotificationMap = new Map<Id, BSF_CustomNotification>();
        for (Id taskId : taskVsQueueMemberMap.keySet()) {
            BSF_CustomNotification notification = new BSF_CustomNotification()
                                                    .body('Marketing Exception has been requested. Please review and take action.')
                                                    .title('Request for Marketing Exception Approval')
                                                    .sender(Userinfo.getUserId())            			
                                                    .typeId(CUstomNotificationTypeId )
                                                    .target(taskId) // target object id
                                                    .category('MarketingException');
            taskVsNotificationMap.put(taskId, notification);
            
        }

        for (Id notif : taskVsNotificationMap.keySet()) {
            List<String> userIds = new List<String>();
            try {
                for (GroupMember member : taskVsQueueMemberMap.get(notif)) {
                    userIds.add(member.UserOrGroupId);
                }
                taskVsNotificationMap.get(notif).send(userIds);
            } catch (Exception e) {
                System.debug('Notification Error: ' + e.getMessage());
            }
        }
        
    }

    public class Request {
    @InvocableVariable(label='Task Id' required=true)
        public Id taskId;
    }
}