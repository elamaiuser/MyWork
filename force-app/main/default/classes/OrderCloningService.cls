public without sharing class OrderCloningService  implements Callable{
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'cloneTemplateOrder' {
                    cloneTemplateOrder(
                        (List<String>) JSON.deserialize((String) params.get('param1'), List<String>.class)
                    );
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + OrderCloningService.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }
    public static void cloneTemplateOrder(List<String> oppIds) {
        Set<Id> templateIds = new Set<Id>();
        Map<Id,Order> templateOrderMap = new Map<Id,Order>();
        Map<Id,List<OrderItem>> templateProductMap = new Map<Id,List<OrderItem>>();
        List<BSF_Error_Log__c> errorLog = new List<BSF_Error_Log__c>();
        List<Order> orderList = new List<Order>();
        List<OrderItem> productList = new List<OrderItem>();

        if(oppIds == null || oppIds.isEmpty()){
            return;
        }
        try{
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id,
                                                                            Parent_Template_Id__c, 
                                                                            Is_Template__c
                                                                    FROM Opportunity
                                                                    WHERE Id IN :oppIds
                                                                    AND Is_Template__c = false
                                                                    AND Parent_Template_Id__c != null
                                                                    WITH SYSTEM_MODE]);
            for(Id oppId : oppMap.keySet()){
                templateIds.add(oppMap.get(oppId).Parent_Template_Id__c);
            }
            if(!templateIds.isEmpty()){
                List<Order> templateOrderList = [SELECT Id, 
                                                        Order_Due_Date__c, 
                                                        EffectiveDate, 
                                                        AccountId, 
                                                        OpportunityId, 
                                                        Material_Recipient__c, 
                                                        Material_Recipient_Type__c,
                                                        Comments__c, 
                                                        Publicity_Approved__c, 
                                                        Publicity_Submitted__c, 
                                                        Status, 
                                                        StatusCode,
                                                        Pricebook2Id,
                                                        Local_Recruitment_Request__c,
                                                        Local_Recruitment_Request_Need_by_Date__c,
                                                        (SELECT Id, 
                                                                OrderID, 
                                                                Product2Id, 
                                                                TotalPrice, 
                                                                ListPrice, 
                                                                Quantity, 
                                                                UnitPrice, 
                                                                PricebookEntryId 
                                                            FROM OrderItems
                                                        )
                                                    FROM Order 
                                                    WHERE OpportunityId IN :templateIds
                                                    WITH SYSTEM_MODE];
                for(Order ord : templateOrderList){
                    templateOrderMap.put(ord.OpportunityId,ord);
                    if(ord.OrderItems != null){
                        for(OrderItem product : ord.OrderItems){
                            if(templateProductMap.isEmpty() || !templateProductMap.containsKey(ord.OpportunityId)){
                                templateProductMap.put(ord.OpportunityId,new List<OrderItem>());
                            }
                            templateProductMap.get(ord.OpportunityId).add(product);
                        }
                    }
                }
            }

            if(!templateOrderMap.isEmpty()){
                Set<Id> oppIdsHavingOrder = new Set<Id>();
                for(Id oppId : oppMap.keySet()){
                    if(templateOrderMap.containsKey(oppMap.get(oppId).Parent_Template_Id__c)){
                        orderList.add(cloneOrder(templateOrderMap.get(oppMap.get(oppId).Parent_Template_Id__c),oppId));
                        oppIdsHavingOrder.add(oppId);
                    }
                }
                List<Order> existingOrders = [SELECT Id
                                                FROM Order
                                                WHERE Publicity_Approved__c = false
                                                AND Publicity_Submitted__c = false
                                                AND OpportunityId IN :oppIdsHavingOrder];
                if(!existingOrders.isEmpty()){
                    TriggerHandler.bypass('OrderTriggerHandler');
                    Database.DeleteResult[] deleteResult = Database.delete(existingOrders,false);
                    TriggerHandler.clearAllBypasses();
                    errorLog.addAll(BSF_Utilities.createErrorLog(
                                                                deleteResult,
                                                                'Delete Existing Order',
                                                                'OrderCloningService',
                                                                'syncTemplateOrdertoOpportunity',
                                                                'Error',
                                                                'Error in deleting order'
                                                            ));
                }
                if(!orderList.isEmpty()){
                    Database.SaveResult[] srList = Database.insert(orderList,false);
                    errorLog.addAll(BSF_Utilities.createErrorLog(
                                                                srList, 
                                                                'syncing Order from template to Opportunity',
                                                                'OrderCloningService',
                                                                'syncTemplateOrdertoOpportunity',
                                                                'Error',
                                                                'Error in sync Order from template to opportunity'
                                                            ));
                    Integer index = 0;
                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            Order odr = orderList.get(index);
                            if(templateProductMap.containsKey(oppMap.get(odr.OpportunityId).Parent_Template_Id__c)){
                                for(OrderItem product : templateProductMap.get(oppMap.get(odr.OpportunityId).Parent_Template_Id__c)){
                                    productList.add(cloneProduct(product,sr.getId()));
                                }
                            }
                        }
                        index++;  
                    }
                }
                if(!productList.isEmpty()){
                    Database.SaveResult[] srList = Database.insert(productList,false);
                    errorLog.addAll(BSF_Utilities.createErrorLog(
                                                                srList, 
                                                                'syncing Order from template to Opportunity',
                                                                'OrderCloningService',
                                                                'syncTemplateOrdertoOpportunity',
                                                                'Error',
                                                                'Error in sync OrderItem from template to opportunity'
                                                            ));
                }
            }
        }catch(Exception ex){
            errorLog.add(BSF_Utilities.createBsfErrorLogForExceptions(ex,
                                                                    'OrderCloningService',
                                                                    'cloneTemplateOrder',
                                                                    'syncTemplateOrdertoOpportunity', 
                                                                    'Error in sync Order from template to opportunity',
                                                                    'Order',
                                                                    JSON.Serialize(oppIds)
                                                                    ));
        }
        if(!errorLog.isEmpty()){
            Database.insert(errorLog,true);
        }
    }
    public static Order cloneOrder(Order ord, Id oppId){
        Order result = new Order();
        if(ord != null && oppId != null){
            result = ord.clone(false,false,false,false);
            result.Publicity_Approved_By__c = null;
            result.Publicity_Approved_Date__c = null;
            result.Publicity_Submitted_By__c = null;
            result.Publicity_Submitted_Date__c = null;
            result.OpportunityId = oppId;
            result.Id = null;
        }
        return result;
    }
    public static OrderItem cloneProduct(OrderItem product, Id odrId){
        OrderItem result = new OrderItem();
        if(product != null && odrId != null){
            result = product.clone(false,false,false,false);
            result.OrderId = odrId;
            result.Id = null;
        }
        return result;
    }
}