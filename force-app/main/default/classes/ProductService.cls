/**
 * @description: This class contains different Product Trigger methods which is called from Product Trigger Handler 
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * 10/31/2023			    Barnojit Sharma			Error when deslecting Active in Product object (HRP-11082)
 * *****************************************************************************************************************************************************************************************
 **/
public with sharing class ProductService {
    public static Boolean isExecuted = false;
    
    public static void checkRelaetdDriveDateAndSendNotification(Map<Id,Product2> oldProductMap,Map<Id,Product2> newProductMap){
        Set<Id> productIds = new Set<Id>();
        List<String> combinedKeyList = new List<String>();
        List<OrderItem> orderItemListToDelete = new List<OrderItem>();
        List<BSF_CustomNotification.CustomNotificationRequest> notificationreqList = new List<BSF_CustomNotification.CustomNotificationRequest>();


        for(Id productId : newProductMap.keySet()){
            if(oldProductMap != null && oldProductMap.containsKey(productId) 
                    && (newProductMap.get(productId).Start_Date__c != oldProductMap.get(productId).Start_Date__c
                    || newProductMap.get(productId).End_Date__c != oldProductMap.get(productId).End_Date__c)){
                        productIds.add(productId);
            }
        }

        if(!productIds.isEmpty()){
            //Check the Related OrderItems and get the related Opportunity Drives from their and check the Drive Date.
            List<OrderItem> orderItemList = [SELECT Id,
                                                    Product2Id,
                                                    OrderId,
                                                    Order.OpportunityId,
                                                    Order.Opportunity.Name, 
                                                    Order.Opportunity.DriveStatus__c,
                                                    Order.Opportunity.Drive_Date__c,
                                                    Order.Opportunity.AccountId,
                                                    Order.Opportunity.Account.Account_Manager__c
                                            FROM OrderItem 
                                            WHERE Product2Id IN: productIds
                                            AND OrderId != null
                                            AND Order.OpportunityId != null
                                            AND Order.Opportunity.DriveStatus__c != 'Cancel'
                                            AND Order.Opportunity.DriveStatus__c != null
                                            AND Order.Opportunity.Drive_Date__c != null
                                            AND Product2.Start_Date__c != null];
            for(OrderItem orderItem : orderItemList){
                //Send Bell notification if the Drive Date does not fall between the Start and End Date of the Product
                if((newProductMap.get(orderItem.Product2Id).End_Date__c == null
                        && orderItem.Order.Opportunity.Drive_Date__c >= newProductMap.get(orderItem.Product2Id).Start_Date__c)
                        || (newProductMap.get(orderItem.Product2Id).End_Date__c != null
                        && (orderItem.Order.Opportunity.Drive_Date__c < newProductMap.get(orderItem.Product2Id).Start_Date__c
                        || orderItem.Order.Opportunity.Drive_Date__c > newProductMap.get(orderItem.Product2Id).End_Date__c))){

                            String combinedKey = orderItem.Order.OpportunityId+'-'+orderItem.Product2Id;
                            orderItemListToDelete.add(orderItem);

                            if((combinedKeyList.isEmpty() || !combinedKeyList.contains(combinedKey))
                                    && orderItem.Order.Opportunity.AccountId != null
                                    && orderItem.Order.Opportunity.Account.Account_Manager__c != null){
                                        //HRP-10482 changes starts here  
                                        BSF_CustomNotification.CustomNotificationRequest notificationreq = new BSF_CustomNotification.CustomNotificationRequest();
                                        notificationreq.notificationTypeName = 'Account_Custom_Notification';
                                        notificationreq.notificationTitle = 'Publicity Item '+ newProductMap.get(orderItem.Product2Id).Name + 
                                                                            ' has been removed from the Order of this Blood Drive Opportunity: '+
                                                                            orderItem.Order.Opportunity.Name;
                                        notificationreq.notificationBody = 'The Publicity Item '+ 
                                                                            newProductMap.get(orderItem.Product2Id).Name + 
                                                                            ' has been removed from the Opportunity : '+ 
                                                                            orderItem.Order.Opportunity.Name +'. This is the description of the Product: '+
                                                                            newProductMap.get(orderItem.Product2Id).Description;
                                        notificationreq.targetId = orderItem.Order.OpportunityId;
                                        notificationreq.recipientId = orderItem.Order.Opportunity.Account.Account_Manager__c;
                                        notificationreq.notificationCategoryName = 'DriveDateOutsideProductStartEnd';
                                        notificationreqList.add(notificationreq);
                                        
                                        //HRP-10482 changes ends here  
                                        combinedKeyList.add(combinedKey);
                            }
                }
            }
        }

        if(!notificationreqList.isEmpty()){
            
                BSF_CustomNotification.sendNotification(notificationreqList); 
           
        }

        if(!orderItemListToDelete.isEmpty()){
            Database.delete(orderItemListToDelete, false);
        }
    }
}