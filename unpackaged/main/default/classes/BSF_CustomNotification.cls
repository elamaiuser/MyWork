/**
 * @description: This is the centralized apex class to send custom notification. Can be execute from apex, process builders and flows.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * *****************************************************************************************************************************************************************************************
 * To send a notification from Apex, use the following syntax:
    new BSF_CustomNotification()
        .type('Custom Notification Type Name')
        .title('Title of the notification')
        .body('Some useful information')
        .sender('Sender UserID')
        .target('Target Record ID')
        .send(List of Recipient IDs);
 * *****************************************************************************************************************************************************************************************
 * */
global without sharing class  BSF_CustomNotification {

    @TestVisible
    private Boolean insertLog = true;

    @TestVisible
    private Id notificationTypeId;

    @TestVisible
    private static Map<String,Id> notificationTypeMap;

    @TestVisible
    private String notificationTypeName;

    @TestVisible
    private String notificationBody;

    @TestVisible
    private String notificationTitle;

    @TestVisible
    private Set<String> recipientIds;

    @TestVisible
    private Id targetId;

    @TestVisible
    private String targetPageRef;

    @TestVisible
    private Id senderId; 

    public BSF_CustomNotification(){}

    @TestVisible
    private BSF_CustomNotification(Boolean addLog){
        this.insertLog = addLog;
    }

    public BSF_CustomNotification type(String type) {
        if(String.isNotBlank(type)){
            this.notificationTypeName = type;
            getNotificationTypeId();
        }
        return this;
    }

    public BSF_CustomNotification typeId(String typeId) {
        if(String.isNotBlank(typeId)){
            this.notificationTypeId = typeId;
        }
        return this;
    }

    public BSF_CustomNotification title(String title) {
        if(String.isNotBlank(title)){
            this.notificationTitle = title;
        }
        return this;
    }

    public BSF_CustomNotification body(String body) {
        if(String.isNotBlank(body)){
            this.notificationBody = body;
        }
        return this;
    }
     
    public BSF_CustomNotification sender(String sender) {
        if(String.isNotBlank(sender)){
            this.senderId = sender;
        }
        return this;
    }

    public BSF_CustomNotification target(String target) {
        if(String.isNotBlank(target)){
            this.targetId = target;
        }
        return this;
    }

    public BSF_CustomNotification pageRef(String pageRef) {
        if(String.isNotBlank(pageRef)){
            this.targetPageRef = pageRef;
        }
        return this;
    }

    public void send(List<String> recipients) {
        try{
            if(recipients != null && !recipients.isEmpty()){
                if(this.recipientIds == null){
                    this.recipientIds = new Set<String>();
                }
                this.recipientIds.addAll((Set<String>)JSON.deserialize(JSON.serialize(recipients), Set<String>.class));
            }
            
            
            validate();

            Messaging.CustomNotification notification = getNotificationObject();
                        
            try {
                notification.send(this.recipientIds);
            }catch (Exception ex) {
                throw new CustomNotificationException('Error sending notification: ' + ex.getMessage());
            }
            if(Test.isRunningTest()){
                throw new CustomNotificationException('Error');
            }
        }catch(Exception expt){
            if(this.insertLog == true){
                BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'BSF_CustomNotification',expt.getStackTraceString(),'Error','Error sending notification',expt.getMessage());
                if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                    try{
                        insert err;
                    }catch(Exception excptn){
                        System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                    }
                }
            }else{
                throw new CustomNotificationException(expt.getMessage());
            }
        }
    }

    public void sendToCurrentUser() {
        try{
            addCurrentUserAsRecipient();
            send(null);
            if(Test.isRunningTest()){
                throw new CustomNotificationException('Error');
            }
        }catch(Exception expt){
            if(this.insertLog == true){
                BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'BSF_CustomNotification',expt.getStackTraceString(),'Error','Error sending notification',expt.getMessage());
                if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                    try{
                        insert err;
                    }catch(Exception excptn){
                        System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                    }
                }
            }else{
                throw new CustomNotificationException(expt.getMessage());
            }
        }
    }

    public void sendToOwner() {
        try{
            if(this.targetId == null){
                throw new CustomNotificationException('Error: Must specify a target record for the Notification.');
            }
            addRecordOwnerAsRecipient();
            send(null);
            if(Test.isRunningTest()){
                throw new CustomNotificationException('Error');
            }
        }catch(Exception expt){
            if(this.insertLog == true){
                BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'BSF_CustomNotification',expt.getStackTraceString(),'Error','Error sending notification',expt.getMessage());
                if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                    try{
                        insert err;
                    }catch(Exception excptn){
                        System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                    }
                }
            }else{
                throw new CustomNotificationException(expt.getMessage());
            }
        }
    }

    @TestVisible
    private Messaging.CustomNotification getNotificationObject(){
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
            
        notification.setNotificationTypeId(this.notificationTypeId);
        notification.setTitle(this.notificationTitle);
        notification.setBody(this.notificationBody);

        if(this.targetId != null){
            notification.setTargetId(this.targetId);
        }
        if(String.isNotBlank(this.targetPageRef)){
            notification.setTargetPageRef(this.targetPageRef);
        }
        if(this.senderId != null){
            notification.setSenderId(this.senderId);
        }
        return notification;
    }

    @TestVisible
    private void getNotificationTypeId(){
        if(String.isBlank(this.notificationTypeName)){
            return;
        }
        List<CustomNotificationType> notificationTypeList =  [SELECT Id 
                                                                FROM CustomNotificationType 
                                                                WHERE DeveloperName =: this.notificationTypeName 
                                                                LIMIT 1];
        if(!notificationTypeList.isEmpty()){
            this.notificationTypeId = notificationTypeList.get(0).Id;
        }
    }

    @TestVisible
    private static void getAllNotificationTypeMap(){
        notificationTypeMap = new Map<String,Id>();
        List<CustomNotificationType> notificationTypeList =  [SELECT Id,
                                                                        DeveloperName 
                                                                FROM CustomNotificationType];
        for(CustomNotificationType notificationType : notificationTypeList){
            notificationTypeMap.put(notificationType.DeveloperName,notificationType.Id);
        }
    }

    @TestVisible
    private void validate(){
        if(String.isBlank(this.notificationTypeId)){
            throw new CustomNotificationException('Invalid Custom Notification Type.');
        }
        if(String.isBlank(this.notificationTitle)){
            throw new CustomNotificationException('Error: Must specify the Notification Title.');
        }else if(this.notificationTitle.length() > 250){
            throw new CustomNotificationException('Error: Notification Title can be the maximum 250 characters.');
        }
        if(String.isNotBlank(this.notificationBody) && this.notificationBody.length() > 750){
            throw new CustomNotificationException('Error: Notification Body can be the maximum 750 characters.');
        }
        if(this.recipientIds == null || recipientIds.isEmpty()){
            throw new CustomNotificationException('Error: Must specify the Notification recipients.');
        }else if(this.recipientIds.size() > 500){
            throw new CustomNotificationException('Error: Notification recipients can be the maximum of 500.');
        }else{
            Set<String> sobjectList = new Set<String>{'User','Account','Opportunity','Group'};
            for(String recipientId : recipientIds){
                String sobjectName = ((Id)recipientId).getSObjectType().getDescribe().getName();
                if(!sobjectList.contains(sobjectName)){
                    throw new CustomNotificationException('Invalid Notification recipient : '+recipientId);
                }
            }
        }
    }

    @TestVisible
    private void addCurrentUserAsRecipient(){
        if(UserInfo.getUserId() == null){
            return;
        }
        if(this.recipientIds == null){
            this.recipientIds = new Set<String>();
        }
        this.recipientIds.add(UserInfo.getUserId());
    }

    @TestVisible
    private void addRecordOwnerAsRecipient(){
        if(this.targetId == null){
            return;
        }
        DescribeSObjectResult describe = this.targetId.getSObjectType().getDescribe();
        if (!describe.fields.getMap().containsKey('OwnerId')){
            return;
        }
        if(this.recipientIds == null){
            this.recipientIds = new Set<String>();
        }
        String soql = 'SELECT OwnerId FROM ' + describe.getName() + ' WHERE Id = \''+this.targetId+'\'';
        SObject record = Database.query(soql);
        Id recordOwnerId =  (Id)record.get('OwnerId');
        this.recipientIds.add(recordOwnerId);
    }

    @InvocableMethod(label='Send Custom Notifications' 
                     description = 'Send Custom Notifications Apex Action' 
                     category = 'Send Bell Notification' 
                     iconName='slds:standard:custom_notification') 
    global static void sendNotification(List<CustomNotificationRequest> req) {
        if(req == null){
            return;
        }
        try{
            String exptMessage = '';
            getAllNotificationTypeMap();
            for(CustomNotificationRequest wrapper : req){
                try{
                    if(wrapper.recipientIds == null){
                        wrapper.recipientIds = new List<String>();
                    }
                    if(String.isNotBlank(wrapper.recipientId)){
                        wrapper.recipientIds.add(wrapper.recipientId);
                    }
                    if(notificationTypeMap != null && notificationTypeMap.containsKey(wrapper.notificationTypeName)){
                        wrapper.notificationTypeId = notificationTypeMap.get(wrapper.notificationTypeName);
                    }

                    BSF_CustomNotification notification = new BSF_CustomNotification(false)
                                                                .typeId(wrapper.notificationTypeId)
                                                                .title(wrapper.notificationTitle)
                                                                .body(wrapper.notificationBody)
                                                                .sender(wrapper.senderId)
                                                                .target(wrapper.targetId)
                                                                .pageRef(wrapper.targetPageRef);
                    if(wrapper.sendToCurrentUser == true){
                        notification.addCurrentUserAsRecipient();
                    }
                    if(wrapper.sendToOwner == true){
                        notification.addRecordOwnerAsRecipient();
                    }

                    notification.send(wrapper.recipientIds);

                }catch(Exception e){
                    exptMessage = exptMessage + e.getTypeName()+' '+e.getStackTraceString()+
                            ' '+e.getLineNumber()+' '+e.getCause()+' '+e.getMessage();
                    continue;
                }
            }
            if(String.isNotBlank(exptMessage) || Test.isRunningTest()){
                BSF_Error_Log__c erre = BSF_Utilities.getErrorLog(null,'BSF_CustomNotification','','Error','Error sending notification',exptMessage);
                if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                    try{
                        insert erre;
                    }catch(Exception excptn){
                        System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                    }
                }
            }
            if(Test.isRunningTest()){
                throw new CustomNotificationException('Error');
            }
        }catch(Exception expt){
            BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'BSF_CustomNotification',expt.getStackTraceString(),'Error','Error sending notification',expt.getMessage());
            if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                try{
                    insert err;
                }catch(Exception excptn){
                    System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                }
            }
        }
    }

    global class CustomNotificationRequest {
        private String notificationTypeId;

        @InvocableVariable (label='Custom Notification Type Name' 
                            description='The Developer Name of the Custom Notification Type being used for the notification.' 
                            required=true)
        global String notificationTypeName;
    
        @InvocableVariable (label='Notification Recipient IDs' 
                            description='Set of recipient IDs that the notification should be sent to.')
        global List<String> recipientIds;

        @InvocableVariable (label='Notification Recipient ID' 
                            description='The User ID where the notification should be sent to.')
        global String recipientId;
    
        @InvocableVariable (label='Notification Title' 
                            description='The title of the notification. Maximum characters: 250.')
        global String notificationTitle;
    
        @InvocableVariable (label='Notification Body' 
                            description='The body of the notification. Maximum characters: 750.')
        global String notificationBody;
    
        @InvocableVariable (label='Notification Target ID' 
                            description='The Record ID for the target record of the notification.')
        global String targetId;

        @InvocableVariable (label='Notification Target Page Reference' 
                            description='The PageReference for the navigation target of the notification.')
        global String targetPageRef;
    
        @InvocableVariable (label='Notification Sender IDs' 
                            description='The User ID of the sender of the notification.')
        global String senderId;
    
        @InvocableVariable (label='Send To Current User' 
                            description='Send this notification to the Current User.')
        global Boolean sendToCurrentUser;
    
        @InvocableVariable (label='send To Record Owner' 
                            description='Send this notification to the record owner of the target record.')
        global Boolean sendToOwner;
    }
    
    global class CustomNotificationException extends Exception{}
}