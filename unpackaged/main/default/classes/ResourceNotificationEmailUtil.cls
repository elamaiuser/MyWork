/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 05/16/2023			Barnojit Sharma				Utility Methods to send email notifications for resource updates and creation (HRP-1566)
 *****************************************************************************************************************************************************************************
*/
public inherited sharing class ResourceNotificationEmailUtil {
    private class  ResourceNotificationWrapper{
        String fieldName{get;set;}
        FieldData data{get;set;}
    }
    private class FieldData{
        String oldValue{get;set;}
        String newValue{get;set;}
    }

    public static void pushNotificationUpdateEvent(List<sked__Resource__c> newList,Map<Id,sked__Resource__c> oldMap){
        
        if(newList == null || newList.isEmpty()){
            return;
        }
        
        Id staffRcTypeId = getRecordTypeId();
        List<String> fieldList = Label.Resource_Change_Event_Field_List.split(ResourceNotificationEmailConstants.COMA);
        List<Resource_Changes_Notification__e> eventList = new List<Resource_Changes_Notification__e>();
        Map<Id,Id> ReceiverIdMap = getReceiverIdMap(newList);
        for(sked__Resource__c resource : newList){
            if(resource.Id != null && resource.recordTypeId != null && staffRcTypeId == resource.recordTypeId && ReceiverIdMap.containsKey(resource.Id)){
                
                sked__Resource__c oldResource;
                if(oldMap != null && !oldMap.isEmpty() && oldMap.containsKey(resource.Id)){
                    oldResource = oldMap.get(resource.Id);
                }
                List<ResourceNotificationWrapper> wrapper = new List<ResourceNotificationWrapper>();
                Boolean isUpdated = false;
                for(String field : fieldList){
                    field = field.trim();
                    
                    if(oldResource == null){ 
                        ResourceNotificationWrapper wpObj = new ResourceNotificationWrapper();
                        isUpdated = true;
                        wpObj.fieldName = field;
                        wpObj.data = new FieldData();
                        wpObj.data.newValue = resource.get(field) == null ? ResourceNotificationEmailConstants.BLANK : String.valueOf(resource.get(field));
                        wrapper.add(wpObj);
                    }else if(resource.get(field) != oldResource.get(field)){ 
                        
                        ResourceNotificationWrapper wpObj = new ResourceNotificationWrapper();
                        isUpdated = true;
                        wpObj.fieldName = field;
                        wpObj.data = new FieldData();
                        wpObj.data.oldValue = oldResource.get(field) == null ? ResourceNotificationEmailConstants.BLANK : String.valueOf(oldResource.get(field));
                        wpObj.data.newValue = resource.get(field) == null ? ResourceNotificationEmailConstants.BLANK : String.valueOf(resource.get(field));
                        wrapper.add(wpObj);
                    }
                }
                
                if(isUpdated){
                    
                    Resource_Changes_Notification__e newEvent = new Resource_Changes_Notification__e();
                    newEvent.Resource_First_Name__c = resource.sked_First_Name__c;
                    newEvent.Resource_Last_Name__c = resource.sked_Last_Name__c;
                    newEvent.Employee_ID__c = resource.sked_Employee_ID__c;
                    newEvent.Resource_Id__c = resource.Id;
                    newEvent.Mode_of_Operation__c = (oldResource == null) ? ResourceNotificationEmailConstants.INSERT_STR : ResourceNotificationEmailConstants.UPDATE_STR;
                    newEvent.Field_Value_JSON__c = JSON.serialize(wrapper);
                    newEvent.Receiver_User_Id__c = ReceiverIdMap.get(resource.Id);
                    eventList.add(newEvent);
                }
            }
        }
        
        if(!eventList.isEmpty()){
            
            List<Database.SaveResult> results = EventBus.publish(eventList);
        }
    }
    @TestVisible
    private static Id getRecordTypeId(){
        Id devRecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get(ResourceNotificationEmailConstants.STAFF).getRecordTypeId();
        return devRecordTypeId;
    }
    @TestVisible
    private static Map<Id,Id> getReceiverIdMap(List<sked__Resource__c> resourceList){
        Map<Id,Id> ReceiverIdMap = new Map<Id,Id>();
        if(resourceList == null || resourceList.isEmpty()){
            return ReceiverIdMap;
        }
        Map<Id,Id> resourceVsRegionMap = new Map<Id,Id>();
        Map<Id,Id> regionVsPrimarySchedulerMap = new Map<Id,Id>();
        Set<Id> regionIds = new Set<Id>();
        for(sked__Resource__c resource : resourceList){
            if(resource.sked__Primary_Region__c != null){
                regionIds.add(resource.sked__Primary_Region__c);
                resourceVsRegionMap.put(resource.Id,resource.sked__Primary_Region__c);
            }
        }
        if(!regionIds.isEmpty()){
            List<sked__Region__c> regionList = [SELECT Id,
                                                        sked_Biomed_Collection_Op_Center__c,
                                                        sked_Biomed_Collection_Op_Center__r.sked_Primary_Scheduler__c
                                                FROM sked__Region__c 
                                                WHERE Id IN: regionIds
                                                AND sked_Biomed_Collection_Op_Center__c <> null];
            for(sked__Region__c rg : regionList){
                if(rg.sked_Biomed_Collection_Op_Center__r.sked_Primary_Scheduler__c != null){
                    regionVsPrimarySchedulerMap.put(rg.Id,rg.sked_Biomed_Collection_Op_Center__r.sked_Primary_Scheduler__c);
                }
            }
        }
        if(!resourceVsRegionMap.isEmpty() && !regionVsPrimarySchedulerMap.isEmpty()){
            for(Id resourceId : resourceVsRegionMap.keySet()){
                if(regionVsPrimarySchedulerMap.containsKey(resourceVsRegionMap.get(resourceId))){
                    ReceiverIdMap.put(resourceId,regionVsPrimarySchedulerMap.get(resourceVsRegionMap.get(resourceId)));
                }
            }
        }
        return ReceiverIdMap;
    }
    public static void sendNotificationEmails(List<Resource_Changes_Notification__e> eventList){
        
        if(eventList == null || eventList.isEmpty()){
            return;
        }
        
        Map<Id,List<String>> emailBodys = new Map<Id,List<String>>();
        Map<Id,String> userNameList = new Map<Id,String>();
        for(Resource_Changes_Notification__e  event : eventList){
            
            if(emailBodys.isEmpty() || !emailBodys.containsKey(event.Receiver_User_Id__c)){
                emailBodys.put(event.Receiver_User_Id__c,new List<String>());
                userNameList.put(event.Receiver_User_Id__c,ResourceNotificationEmailConstants.BLANK);
            }
            
            List<ResourceNotificationWrapper> wrapper = new List<ResourceNotificationWrapper>();
            wrapper =(List<ResourceNotificationWrapper>) System.JSON.deserialize(event.Field_Value_JSON__c, List<ResourceNotificationWrapper>.class);
            
            String emailBody;
            if(String.isNotBlank(event.Mode_of_Operation__c) && event.Mode_of_Operation__c.equalsIgnoreCase(ResourceNotificationEmailConstants.INSERT_STR)){
                
                emailBody = ResourceNotificationEmailConstants.EMAIL_BODY_CREATE_PART1+
                            event.Resource_First_Name__c+ResourceNotificationEmailConstants.SPACE+
                            event.Resource_Last_Name__c+ResourceNotificationEmailConstants.EMAIL_BODY_CREATE_PART2+
                            ResourceNotificationEmailConstants.EMAIL_BODY_CREATE_PART3+
                            event.CreatedDate.format(ResourceNotificationEmailConstants.DATE_FORMAT)+
                            ResourceNotificationEmailConstants.EMAIL_BODY_BR;
                emailBody += generateTableContent(wrapper,true,event.Employee_ID__c);

            }else if(String.isNotBlank(event.Mode_of_Operation__c) && event.Mode_of_Operation__c.equalsIgnoreCase(ResourceNotificationEmailConstants.UPDATE_STR)){
                
                emailBody = ResourceNotificationEmailConstants.EMAIL_BODY_UPDATE_PART1+
                            event.Resource_First_Name__c+ResourceNotificationEmailConstants.SPACE+
                            event.Resource_Last_Name__c+ResourceNotificationEmailConstants.EMAIL_BODY_UPDATE_PART2+
                            ResourceNotificationEmailConstants.EMAIL_BODY_UPDATE_PART3+event.Employee_ID__c+
                            ResourceNotificationEmailConstants.EMAIL_BODY_UPDATE_PART4+
                            event.CreatedDate.format(ResourceNotificationEmailConstants.DATE_FORMAT)+
                            ResourceNotificationEmailConstants.EMAIL_BODY_BR;
                emailBody += generateTableContent(wrapper,false,null);
            }
            
            emailBodys.get(event.Receiver_User_Id__c).add(emailBody);
        }
        if(!userNameList.isEmpty()){
            List<User> userList = [SELECT Id, 
                                            Name 
                                    FROM User 
                                    WHERE Id IN: userNameList.keySet()];
            for(User ur : userList){
                userNameList.put(ur.Id,ur.Name);
            }
        }
        if(!emailBodys.isEmpty()){
            
            sendMail(emailBodys,userNameList);
        }
    }
    @TestVisible
    private static void sendMail(Map<Id,List<String>> emailBodys,Map<Id,String> userNameList){
        try{
            if((emailBodys!= null && emailBodys.size() > 0)){
                
                Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage>();
                Id orgWideEmailAddressId;
                if(String.isNotBlank(label.RESOURCE_NOTIFICATION_SENDER_EMAIL)){
                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: label.RESOURCE_NOTIFICATION_SENDER_EMAIL ];
                    if (owea.size()>0) {
                        orgWideEmailAddressId = owea.get(0).Id;
                    }
                    
                }
                
                for(Id userId : emailBodys.keySet()){
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    if(orgWideEmailAddressId != null){
                        message.setOrgWideEmailAddressId(orgWideEmailAddressId);
                    }
                    
                    message.setSaveAsActivity(false);
                    message.setTreatTargetObjectAsRecipient(true);
                    message.setTargetObjectId(userId);
                    message.optOutPolicy = ResourceNotificationEmailConstants.FILTER;
                    message.subject = ResourceNotificationEmailConstants.EMAIL_SUBJECT;
                    String htmlBody =   ResourceNotificationEmailConstants.HI+userNameList.get(userId) + 
                                        ResourceNotificationEmailConstants.SPACE+
                                        ResourceNotificationEmailConstants.COMA+
                                        ResourceNotificationEmailConstants.EMAIL_BODY_BR+ 
                                        String.join(emailBodys.get(userId),ResourceNotificationEmailConstants.BR);
                    message.setHtmlBody(htmlBody);
                    messages.add(message);
                    
                }
                if(messages.size() > 0){
                    BSF_EmailNotification.sendEmails(messages,'ResourceUpdateEmail',null);//Changes for  HRP-11608
                    /*Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    if(results[0].success){
                        
                    }else {
                        
                    }*/
                }
                
            }
        }catch(Exception expm){
            
        }
    }
    @TestVisible
    private static String generateTableContent(List<ResourceNotificationWrapper> wrapper, Boolean isInsert, String employeeNo) {
        Map<String,Schema.SObjectField> mfields = Schema.sked__Resource__c.SObjectType.getDescribe().fields.getMap();
        Map<String,String> lookupMap = new Map<String,String>();
        for(ResourceNotificationWrapper wp : wrapper) {
            
            Schema.DescribeFieldResult fieldResult = mfields.get(wp.fieldName).getDescribe();
            if(fieldResult.getType() == Schema.DisplayType.Reference){
                
                try{
                    
                    Id salesforceId = Id.valueOf(wp.data.oldValue);
                    lookupMap.put(wp.data.oldValue,ResourceNotificationEmailConstants.BLANK);
                    
                }catch(Exception idExp){}
                try{
                    
                    Id salesforceId = Id.valueOf(wp.data.newValue);
                    lookupMap.put(wp.data.newValue,ResourceNotificationEmailConstants.BLANK);
                    
                }catch(Exception idExp){}
            }
        }
        if(!lookupMap.isEmpty()){
            
            lookupMap = getRecordDetails(lookupMap);
        }
        String tableContent = ResourceNotificationEmailConstants.TABLE_PART1;
        if(isInsert){
            tableContent += ResourceNotificationEmailConstants.TABLE_PART2+
                            employeeNo+
                            ResourceNotificationEmailConstants.TABLE_PART3;
        }else{
            tableContent += ResourceNotificationEmailConstants.TABLE_PART4;
        }
        for (ResourceNotificationWrapper wp : wrapper) {
            Schema.DescribeFieldResult fieldResult = mfields.get(wp.fieldName).getDescribe();
            String oldValue = wp.data.oldValue;
            String newValue = wp.data.newValue;
            if(fieldResult.getType() == Schema.DisplayType.Reference){
                oldValue = lookupMap.containsKey(wp.data.oldValue) ? lookupMap.get(wp.data.oldValue) : wp.data.oldValue;
                newValue = lookupMap.containsKey(wp.data.newValue) ? lookupMap.get(wp.data.newValue) : wp.data.newValue;
            }
            tableContent += ResourceNotificationEmailConstants.TR_START;
            tableContent += ResourceNotificationEmailConstants.TD_START + 
                            fieldResult.getLabel() + 
                            ResourceNotificationEmailConstants.TD_CLOSE;
            if(!isInsert){
                tableContent += ResourceNotificationEmailConstants.TD_START + 
                                oldValue + 
                                ResourceNotificationEmailConstants.TD_CLOSE;
            }
            tableContent += ResourceNotificationEmailConstants.TD_START + 
                            newValue + 
                            ResourceNotificationEmailConstants.TD_CLOSE;
            tableContent += ResourceNotificationEmailConstants.TR_CLOSE;
        }
        tableContent += ResourceNotificationEmailConstants.TABLE_CLOSE;

        return tableContent;
    }
    @TestVisible
    private static Map<String,String> getRecordDetails(Map<String,String> lookupMap){
        if(lookupMap == null || lookupMap.isEmpty()){
            return lookupMap;
        }
        
        Map<String,List<String>> sobjectMap = new Map<String,List<String>>();
        for(String myid : lookupMap.keySet()){
            Id sfId = Id.valueOf(myid);
            String sObjName = sfId.getSObjectType().getDescribe().getName();
            if(sobjectMap.isEmpty() || !sobjectMap.containsKey(sObjName)){
                
                sobjectMap.put(sObjName,new List<String>());
            }
            sobjectMap.get(sObjName).add(myid);
        }
        if(!sobjectMap.isEmpty()){
            for(String sObjectName : sobjectMap.keySet()){
                List<String> idList = sobjectMap.get(sObjectName);
                
                String query = ResourceNotificationEmailConstants.QUERY_PART1+sObjectName+ResourceNotificationEmailConstants.QUERY_PART2;
                
                List<Sobject> objList = Database.query(query);
                
                for(Sobject rec : objList){
                    String recId = (String) rec.get(ResourceNotificationEmailConstants.ID_STR);
                    String recName = (String) rec.get(ResourceNotificationEmailConstants.NANE_STR);
                    lookupMap.put(recId,recName);
                    
                }
            }
        }
        return lookupMap;
    }
}