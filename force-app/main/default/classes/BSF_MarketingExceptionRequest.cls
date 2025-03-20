public with sharing class BSF_MarketingExceptionRequest {
    @InvocableMethod(label='Send Marketing Exception Approval Request')
    public static void marketingExceptionRequest(List<Request> requests) {

        // Id taskId = requests[0].taskId;
        List<Id> taskIds = new List<Id>();
        for(Request req : requests) {
            taskIds.add(req.taskId);
        }
        
        List<Task> tasks = [SELECT Id, OwnerId FROM Task WHERE Id IN :taskIds];

        Map<Id, Id> taskVsQueueMap = new Map<Id, Id>();
        Map<Id, Id> queueVsTaskMap = new Map<Id, Id>();

        for (Task task : tasks) {
            taskVsQueueMap.put(task.Id, task.OwnerId);
            queueVsTaskMap.put(task.OwnerId, task.Id);
        }

        // Id queueId = [SELECT Id, OwnerId, Subject FROM Task WHERE Id = :taskId LIMIT 1].OwnerId;

        List<GroupMember> queueMembers = [SELECT Id, GroupId, Group.Name, UserOrGroupId FROM GroupMember WHERE GroupId IN :taskVsQueueMap.values()];

        Map<Id, List<GroupMember>> taskVsQueueMemberMap = new Map<Id, List<GroupMember>>();

        for (GroupMember member : queueMembers) {
            if(taskVsQueueMemberMap.containsKey(queueVsTaskMap.get(member.GroupId))){
                taskVsQueueMemberMap.get(queueVsTaskMap.get(member.GroupId)).add(member);
            }else {
                List<GroupMember> members = new List<GroupMember>();
                members.add(member);
                taskVsQueueMemberMap.put(queueVsTaskMap.get(member.GroupId), members);
            }
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
            system.debug('emailList##' + emailList);
            BSF_EmailNotification.sendEmails(emailList,'MarketingException',null);

            Id CUstomNotificationTypeId = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType where DeveloperName='Task_Custom_Notification' LIMIT 1].Id;
            BSF_CustomNotification notification = new BSF_CustomNotification()
                                                    .body('Marketing Exception has been requested. Please review and take action.')
                                                    .title('Request for Marketing Exception Approval')
                                                    .sender(Userinfo.getUserId())            			
                                                    .typeId(CUstomNotificationTypeId )
                                                    .target(taskId) // target object id
                                                    .category('MarketingException');
                
            try{
                notification.send(userIds);  
            }
            catch(Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
                System.debug('Line number: '+e.getLineNumber());
            }
        }
        
    }

    public class Request {
    @InvocableVariable(label='Task Id' required=true)
        public Id taskId;
    }
}