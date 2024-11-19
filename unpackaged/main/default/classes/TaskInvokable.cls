/**
 * @description: This apex class is executed from Send Bell Notification To Task processbuilder to send custom notification.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * *****************************************************************************************************************************************************************************************
 **/
public with sharing class TaskInvokable {
    
    @InvocableMethod
    public static void sendNotificationToTaskOwner(List<Id> taskId)
    {
        
		List<Task> tasklist = [select OwnerId, WhatId, what.type,subject from Task where Id IN: taskId  ];
		system.debug('tasklist##'+tasklist);
		Map<Id,Id> taskAndAccountId = new Map<Id,Id>();
		Map<Id,Task> taskIdAndTask = new Map<Id,Task>();
		
		
		Set<Id> accids = new Set<Id>();
		for( Task tk : tasklist ){
			if( tk.what.type != null && (tk.what.type.toLowercase() == 'account' || tk.what.type.toLowercase() == 'opportunity' || tk.what.type.toLowercase() == 'order')){
				taskAndAccountId.put( tk.Id, tk.whatId );
				taskIdAndTask.put( tk.Id, tk );
			}
		}
		
        
        List<CUstomNotificationType> CUstomNotificationTypeList = [SELECT Id FROM CUstomNotificationType WHERE DeveloperName = 'Task_Custom_Notification' ];
        //List<Messaging.CustomNotification> notificationList = new List<Messaging.CustomNotification>();
        List<String> userId = new List<String>(); 
        BSF_CustomNotification notification; //HRP-10482 changes
        Id typeId;
        
        if(!CUstomNotificationTypeList.isEmpty()){
            typeId=CUstomNotificationTypeList[0].Id;
        }
        
        map<string,String> taskSubNotifyKeyMap = BSF_Constants.taskSubjectKeyMap;//HRP-11611
		if(typeId!=null){ 
			for(Id  tsk: taskAndAccountId.keySet() )
            {
                system.debug('comes here1##'+tsk);
                //HRP-11611
                String notificationKey;
                if(taskSubNotifyKeyMap.containsKey(taskIdAndTask.get(tsk).subject))
                {
                    system.debug('comes here2##'+tsk);
                    
                    notificationKey=taskSubNotifyKeyMap.get(taskIdAndTask.get(tsk).subject);
                    system.debug('comes here2.1##'+notificationKey);
                }
                //HRP-11611
				//HRP-10482 changes starts here
                notification = new BSF_CustomNotification()
								   .title('Task is assigned to you')
								   .body('Please visit the task here ' + 'lightning/r/Task/' + tsk + '/view')               
								   .sender(Userinfo.getUserId())           			
								   .typeId(typeId)
								   .target(tsk) //( taskAndAccountId.get(tsk)   ); // target object id
								   .category(notificationKey);//HRP-11611 prev 'UnmanagedAccount'-->notificationKey
				//HRP-10482 changes ends here
				userId = new List<String>();				
				userId.add( taskIdAndTask.get(tsk).OwnerId   );
                system.debug('comes here3##'+userId);
				notification.send(userId);
            }
            
        }
        
    }
    
}