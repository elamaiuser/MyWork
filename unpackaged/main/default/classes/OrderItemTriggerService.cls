/*@Description: 1. This class contains different Trigger methods working in different trigger contexts to support order product related functionalities
 *              2. This service class is called from OrderItem Trigger Handler (Maintaining Trigger Framework)
 * ***************************************************************************************************************************************************************/
/*@Modification Log 
 * 
 * Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 08/03/2023			Priti Jana				Logic for HRP-10307
 * 14/07/2024           Ankit Kundu             Publicity Material Ordering at template level(HRP-12664)
 * 10/25/2024			Balaji N				Logic for HRP-13489 calculateBudgetforProductsProjected error for Budget exceeding
 *****************************************************************************************************************************************************************************
*/

public with sharing class OrderItemTriggerService {
    
    /*
* JIRA Ticket: HRP - 735, 
* Description: 2.0 DRD AM: Selecting Publicity Order Item
*/
    public static void validateProductMaterialRecipient( List<OrderItem> oldOrderItems, List<OrderItem> newOrderItems,
                                                        Map<Id,OrderItem> oldOrdersItemsMap,Map<Id,OrderItem> newOrderItemsMap){
                                                            
                                                            // MR: Material Recipient
                                                            // scenario #1:
                                                            // AND
                                                            // 1) in Order item , MR is not blank
                                                            // 2) in Order, MR type is null 
                                                            
                                                            
                                                            // scenario #2:
                                                            // AND
                                                            // 1) in Order item, MR is blank
                                                            // 2) in Order, MR type is selected 'Split'
                                                            
                                                            // Scenario #3:
                                                            // AND
                                                            // 1) in Order Item,  MR is not blank 
                                                            // 2) in Order, MR type is selected 'Same'
                                                            // 3) in order item, MR value not matched with Order MR value
                                                            
                                                            // Scenario #4:
                                                            // AND
                                                            // 1) in Order Item,  MR is not blank 
                                                            // 2) in Order, MR type is selected 'Split'
                                                            // 3) in order item, MR value not matched with Order MR value
                                                            
                                                            String materialrecipientisnull = 'Please deselect Material Recipient, because Material Recipient type is set blank in Order';
                                                            String materialrecipientProductisnull = 'Please select Material Recipient for this item';
                                                            String mrinitemnotmatchforSame = 'Selected Material Recipient not matched as in Order, ether select exact value as in Order or left it blank';
                                                            String mrinitemnotmatchforSplit = 'Selected Material Recipient not matched as in Order';
                                                            
                                                            Map<Id, Order> orderObjectmap = new Map<Id, Order>();
                                                            
                                                            List<Order> orders = new List<Order>();
                                                            
                                                            Set<Id> orderids = new Set<Id>(); 
                                                            
                                                            for( OrderItem odi : newOrderItems ){
                                                                orderids.add(odi.orderId);
                                                            }
                                                            
                                                            
                                                            orders = [ select Id, Material_Recipient_Type__c, Material_Recipient__c, Material_Recipient_Default__c from Order where Id IN:orderids ];
                                                            
                                                            if( !orders.isEmpty() ){
                                                                for( Order od : orders ){
                                                                    if( !orderObjectmap.containsKey( od.Id ) ){
                                                                        orderObjectmap.put( od.Id, od);
                                                                    }				
                                                                }
                                                            }
                                                            
                                                            
                                                            for( OrderItem odi : newOrderItems ){
                                                                if( odi.Material_Recipient__c != null ){
                                                                    if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == null   ){ // scenario #1
                                                                        odi.addError( materialrecipientisnull );
                                                                    }	
                                                                    
                                                                    else if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == 'Same' ){ // scenario #3
                                                                        String mrecipient = orderObjectmap.get( odi.orderId).Material_Recipient__c ;
                                                                        if( mrecipient != odi.Material_Recipient__c ){
                                                                            odi.addError( mrinitemnotmatchforSame );
                                                                        }
                                                                    }
                                                                    
                                                                    else if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == 'Split' ){ // scenario #4
                                                                        String [] mrecipients = orderObjectmap.get( odi.orderId).Material_Recipient__c.split(';') ;
                                                                        
                                                                        if( !mrecipients.contains( odi.Material_Recipient__c )  ){
                                                                            odi.addError( mrinitemnotmatchforSplit );
                                                                        }
                                                                    }
                                                                }
                                                                // else if( odi.Material_Recipient__c == null ){ // All covered scenario #2
                                                                // if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c != null &&  orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == 'Split' ){ //scenario #2
                                                                // odi.addError( materialrecipientProductisnull );
                                                                // }				
                                                                // }
                                                                
                                                                if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == 'Same' ){
                                                                    odi.Material_Recipient__c = orderObjectmap.get( odi.orderId).Material_Recipient_Default__c;
                                                                }			
                                                            }
                                                            // In case of Split only
                                                            String firstMR;
                                                            List<OrderItem> newOrderItemRemainingList = new List<OrderItem>();
                                                            if( newOrderItems.size() > 1 && newOrderItems[0].Material_Recipient__c != null ){
                                                                firstMR = newOrderItems[0].Material_Recipient__c;
                                                                for( OrderItem odi : newOrderItems ){
                                                                    newOrderItemRemainingList.add(odi);
                                                                }
                                                                
                                                                newOrderItemRemainingList.remove(0);
                                                                
                                                                
                                                                for( OrderItem odi : newOrderItemRemainingList ){
                                                                    if( odi.Material_Recipient__c == null ){ // All covered scenario #2
                                                                        if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c != null &&  orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == 'Split' ){ //scenario #2
                                                                            odi.Material_Recipient__c =   firstMR;
                                                                        }				
                                                                    }		
                                                                }
                                                            }else if( newOrderItems.size() > 1 && newOrderItems[0].Material_Recipient__c == null ){
                                                                for( OrderItem odi : newOrderItems ){
                                                                    if( odi.Material_Recipient__c == null ){ // All covered scenario #2
                                                                        if( orderObjectmap.get( odi.orderId).Material_Recipient_Type__c != null &&  orderObjectmap.get( odi.orderId).Material_Recipient_Type__c == 'Split' ){ //scenario #2
                                                                            odi.Material_Recipient__c =   orderObjectmap.get( newOrderItems[0].orderId).Material_Recipient_Default__c;
                                                                        }				
                                                                    }		
                                                                }
                                                                
                                                            }else if( newOrderItems.size() == 1 && newOrderItems[0].Material_Recipient__c == null ){
                                                                if( orderObjectmap.get( newOrderItems[0].orderId).Material_Recipient_Type__c != null &&  orderObjectmap.get( newOrderItems[0].orderId).Material_Recipient_Type__c == 'Split' ){ //scenario #2
                                                                    newOrderItems[0].Material_Recipient__c =   orderObjectmap.get( newOrderItems[0].orderId).Material_Recipient_Default__c;
                                                                }
                                                            }
                                                        }
    
    /*
* JIRA Ticket: HRP - 1613, 1614, 
* Description: 2.0 DRD AM: Selecting Publicity Order Item
*/
    public static void calculateBudgetforProductsProjected( List<OrderItem> oldOrderItems, List<OrderItem> newOrderItems,
                                                           Map<Id,OrderItem> oldOrdersItemsMap,Map<Id,OrderItem> newOrderItemsMap){
                                                               
                                                               
                                                               
                                                               //HRP-13489 Start
                                                               Map<Id,List<OrderItem>> orderIdOrderItemListMap = new Map<Id,List<OrderItem>>();
                                                               
                                                               for( OrderItem oit : newOrderItems )
                                                               {				
                                                                   if(!orderIdOrderItemListMap.containsKey(oit.OrderId))
                                                                       orderIdOrderItemListMap.put(oit.OrderId, new List<OrderItem>());
                                                                       orderIdOrderItemListMap.get(oit.OrderId).add(oit);
                                                               }
                                                               
                                                               Map<Id, Order> orderIdOrdermap = new Map<Id, Order>([ select Id, BudgetCurrency__c from Order where Id IN: orderIdOrderItemListMap.KeySet() ]);
                                                               //HRP-13489 End
/*Commented part of HRP-13489
for( Order ord : orderList ){
if( !orderIdOrdermap.containsKey( ord.Id ) ){
orderIdOrdermap.put( ord.Id, ord );
}
}*/
                                                               
                                                               List<OrderItem> oitemlist = [select Id, Quantity, UnitPrice,OrderId from OrderItem where orderid in:orderIdOrdermap.KeySet()];                                            
                                                               if( !oitemlist.isEmpty() ){
                                                                   for( OrderItem oitem : oitemlist )
                                                                   {        
                                                                       //HRP-13489 Start
                                                                       if(!orderIdOrderItemListMap.containsKey(oitem.OrderId))
                                                                       orderIdOrderItemListMap.put(oitem.OrderId, new List<OrderItem>());
                                                                       orderIdOrderItemListMap.get(oitem.OrderId).add(oitem);
                                                                       //HRP-13489 End
                                                                   }                                                                   
                                                               }                                                              
                                                               
                                                               //HRP-13489 Start
                                                               Map<Id,Decimal> orderIdTotalBudMap = new Map<Id,Decimal>();
                                                               for(Id ordId : orderIdOrderItemListMap.Keyset())
                                                               {
                                                                   Decimal totalProductBudget = 0.0;
                                                                   for(OrderItem oitem : orderIdOrderItemListMap.get(ordId))
                                                                   {
                                                                       Decimal eachProductBudget = oitem.Quantity * oitem.UnitPrice;
                                                                       totalProductBudget = totalProductBudget + eachProductBudget;
                                                                   }
                                                                   orderIdTotalBudMap.put(ordId,totalProductBudget);
                                                               }
                                                                 
                                                               
                                                               
                                                               //Decimal Orderbudget = orderidObjectmap.get(newOrderItems[0].OrderId).Budget__c;
                                                               //Decimal Orderbudget = orderIdOrdermap.get(newOrderItems[0].OrderId).BudgetCurrency__c;
                                                               
                                                               for( OrderItem oitem : newOrderItems )
                                                               {
                                                                   Decimal Orderbudget= orderIdOrdermap != null && orderIdOrdermap.containsKey(oitem.OrderId)?orderIdOrdermap.get(oitem.OrderId).BudgetCurrency__c:null;
                                                                   Decimal totalProductBudget = orderIdTotalBudMap != null && orderIdTotalBudMap.containsKey(oitem.OrderId)?orderIdTotalBudMap.get(oitem.OrderId):null;
                                                                   
                                                                   if( totalProductBudget!=null && Orderbudget != null && totalProductBudget > Orderbudget)
                                                                   {
                                                                       Decimal budgetdiff = totalProductBudget - Orderbudget ;
                                                                       oitem.addError('Total Budget is exceeding, please update the selection, exceeding amount is ' + budgetdiff );
                                                                   }
                                                               }
                                                               //HRP-13489 End 
                                                               
                                                           }    
    
    /*
* JIRA Ticket: HRP - 1614, 
* Description: 2.0 DRD AM: Selecting Publicity Order Item
*/
    
    /*public static void checkDrivedateAndProductStartEnddate( List<OrderItem> oldOrderItems, List<OrderItem> newOrderItems,
                                                            Map<Id,OrderItem> oldOrdersItemsMap,Map<Id,OrderItem> newOrderItemsMap){ 
                                                                
                                                                List<Product2> productList = new List<Product2>();	
                                                                List<Order> orders = new List<Order>();	
                                                                List<Opportunity> opportunities = new List<Opportunity>();	
                                                                
                                                                Set<Id> productids = new Set<Id>();
                                                                Set<Id> orderids = new Set<Id>();
                                                                Set<Id> oppids = new Set<Id>();
                                                                
                                                                Map<Id, Id> orderItemIdProductMap = new Map<Id, Id>();
                                                                Map<Id, Opportunity> oppIdOpportunityMap = new Map<Id, Opportunity>();
                                                                Map<Id, Order> orderIdOrderMap = new Map<Id, Order>();
                                                                //Map<Id, Order> orderItemIdOrderMap = new Map<Id, Order>();
                                                                Map<Id, Product2> productIdProductMap = new Map<Id, Product2>();
                                                                
                                                                for( OrderItem oit : newOrderItems ){
                                                                    productids.add(oit.Product2Id);	
                                                                    orderids.add( oit.OrderId);				
                                                                    orderItemIdProductMap.put( oit.Id, oit.Product2Id );
                                                                }
                                                                
                                                                productList = [ select Id, Start_Date__c, End_Date__c from Product2 where id in: productids ];
                                                                orders = [ select Id, OpportunityId from Order where Id in:orderids ];
                                                                
                                                                for( Product2 pd : productList ){
                                                                    productIdProductMap.put( pd.Id, pd );
                                                                }
                                                                for( Order od : orders ){
                                                                    oppids.add(od.OpportunityId);
                                                                    orderIdOrderMap.put( od.Id, od );
                                                                }
                                                                
                                                                opportunities = [ select Id, Drive_Date__c, Type_of_Drive__c from Opportunity where Id in: oppids ];
                                                                for( Opportunity op : opportunities ){
                                                                    oppIdOpportunityMap.put( op.Id, op );
                                                                }
                                                                
                                                                for( OrderItem oit : newOrderItems ){
                                                                    Date opportunityDrivedate = oppIdOpportunityMap.get( orderIdOrderMap.get( oit.OrderId ).OpportunityId  ).Drive_Date__c;
                                                                    Date productStartDate = productIdProductMap.get( orderItemIdProductMap.get(oit.Id) ).Start_Date__c;
                                                                    Date productEndDate = productIdProductMap.get( orderItemIdProductMap.get(oit.Id) ).End_Date__c;
                                                                    String drivetype = oppIdOpportunityMap.get( orderIdOrderMap.get( oit.OrderId ).OpportunityId  ).Type_of_Drive__c;
                                                                    //if( productStartDate!= null && opportunityDrivedate >= productStartDate ){ // && opportunityDrivedate <= productEndDate ){
                                                                    //continue;
                                                                    //}else{
                                                                    //oit.addError( 'Opportunity Drive date does not fall in between Product Start date and End date' );
                                                                    //}
                                                                    if( drivetype == 'Mobile' && productStartDate!= null && productEndDate == null && opportunityDrivedate < productStartDate){
                                                                        oit.addError( 'Opportunity Drive date  is less than Product Start date' );
                                                                    }else if( drivetype == 'Mobile' && productStartDate!= null && productEndDate != null && (opportunityDrivedate < productStartDate || opportunityDrivedate > productEndDate)  ){
                                                                        oit.addError( 'Opportunity Drive date does not fall in between Product Start date and End date' );
                                                                    }
                                                                }
                                                                
                                                                
                                                            }  
    /*
* JIRA Ticket: HRP - 3534, 
* Description: 1.0 User - Associate a Publicity Item to a Collection Operation
*/
    public static void checkZipCodeOnOppToAddProduct(List<OrderItem> listOfOrderItem){
        
        set<Id> productId = new set<Id>();
        map<Id, String> mapOrderIdWithCollectionOperation = new  map<Id, String>();
        list<Product_Collection_Operation__c> listOfCollectionOperation = new list<Product_Collection_Operation__c>();
        map<Id, list<String>> mapProductIdWithCollectionOperationList = new  map<Id, list<String>>();
        map<Id, list<Id>> mapOrderIdWithListOfProductId = new map<Id, list<Id>>();
        map<String, OrderItem> mapOfOrderAndProductIdWithOrderItem = new  map<String, OrderItem>();
        
        for(OrderItem ordItem: listOfOrderItem){
            String getOrderAndProductId = String.valueOf(ordItem.OrderId) + String.valueOf(ordItem.Product2Id); 
            mapOfOrderAndProductIdWithOrderItem.put(getOrderAndProductId, ordItem);
            
            productId.add(ordItem.Product2Id);
            if(!mapOrderIdWithListOfProductId.containsKey(ordItem.OrderId)){
                mapOrderIdWithListOfProductId.put(ordItem.OrderId, new List<Id> { ordItem.Product2Id });
            } else{
                mapOrderIdWithListOfProductId.get(ordItem.OrderId).add(ordItem.Product2Id);
            }     
        }
        list<Order> listOfOrder = [SELECT Id, Opportunity.Collection_Operation__c FROM Order 
                                   WHERE Id IN :mapOrderIdWithListOfProductId.keyset() ];
        for(order ord:listOfOrder){
            mapOrderIdWithCollectionOperation.put(ord.Id, ord.Opportunity.Collection_Operation__c);
        }
        if(productId.size() > 0){
            listOfCollectionOperation = [SELECT Id, Collection_Operation__r.Name, Product__c FROM Product_Collection_Operation__c
                                         WHERE Product__c IN : productId ];
        }
        if(listOfCollectionOperation.size() > 0){           
            for(Product_Collection_Operation__c code : listOfCollectionOperation){ 
                if(!mapProductIdWithCollectionOperationList.containsKey(code.Product__c)){
                    mapProductIdWithCollectionOperationList.put(code.Product__c , new list<String> {code.Collection_Operation__r.Name});
                }else{
                    mapProductIdWithCollectionOperationList.get(code.Product__c).add(code.Collection_Operation__r.Name);
                }
            }
            
            for(Id orId:mapOrderIdWithListOfProductId.keyset()){
                for(Id pId: mapOrderIdWithListOfProductId.get(orId)){
                    if(mapProductIdWithCollectionOperationList.get(pId) != NULL){
                        if(!mapProductIdWithCollectionOperationList.get(pId).contains(mapOrderIdWithCollectionOperation.get(orId))){
                            String OrderAndProductId = String.valueOf(orId) + String.valueOf(pId);
                            mapOfOrderAndProductIdWithOrderItem.get(OrderAndProductId).addError('Can not add product as collection Operation is not available');
                        }
                    }
                }
            }               
        }
    }
    
     /* HRP - 10307 --> Starts Here
      @Description - Users should not be allowed to add more than one theme product per order
      @Added By - Priti
	*/
    public static void validateOneThemePerOrder(List<OrderItem> newOrderItemList)
    {
        Set<Id> productIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> nonThemeProductIds = new Set<Id>();
        
        List<String> errorMsgs = System.Label.Restrict_Theme_Product_Add_Error_Msg.split(',');
        String errorMsgForMoreThanOneTheme = errorMsgs[0];
        String errorMsgForExistingTheme = errorMsgs[1];
        
        for (OrderItem orderItem : newOrderItemList)
        {
            productIds.add(orderItem.Product2Id); // Adding the product Ids
            OrderIds.add(orderItem.OrderId);            
        }
        
        List<Product2> themeProductList = [Select Id,Product_Id__c from Product2 where Id in : productIds and Product_Id__c like '%theme%' and (not Product_Id__c like '%size%')];
        
        if(!themeProductList.isEmpty())
        {
            for(Product2 proObj : themeProductList)
            {
                if(productIds.contains(proObj.Id))
                {
                    productIds.remove(proObj.Id);
                }
            }
        }
                
        List<OrderItem> orderItemWithExistingThemeProductList = [select Product2Id, OrderId from OrderItem where Product2.Product_Id__c like '%theme%' and (not Product2.Product_Id__c like '%size%') and OrderId in : orderIds];
        
        
            for(OrderItem ord : newOrderItemList)
            {
                if(themeProductList.size() > 1 && !productIds.contains(ord.Product2Id) && orderItemWithExistingThemeProductList.isEmpty())
                {
                    ord.addError(errorMsgForMoreThanOneTheme);                    
                }                
                else if(!orderItemWithExistingThemeProductList.isEmpty() && !productIds.contains(ord.Product2Id))
                {
                    ord.addError(errorMsgForExistingTheme);                                            
                }                
            }                                              
    }
    // HRP - 10307 --> Ends Here
     // HRP- 12664 --> Start
    public static void validateProductEndDate(List<OrderItem> newOrderItemList)
    {
        
        Set<Id> productIds = new Set<Id>();
        for (OrderItem ot : newOrderItemList) {
            productIds.add(ot.Product2Id);
        }
        
        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, End_Date__c FROM Product2 WHERE Id IN :productIds]
        );
        
        for (OrderItem ot : newOrderItemList) {
            Product2 product = productMap.get(ot.Product2Id);
            if (product != null && product.End_Date__c < System.today()) {
                //Error message will be: 'You cannot add expired product.'
                ot.addError(Custom_Messages__mdt.getInstance('Expired_Order_Product_Restriction').value__c);
            }
        }
    }   
    public static void validatedProductToOrderItem(List<OrderItem> newOrderItemList)
    {
        Set<Id> orderIds = new Set<Id>();
        for (OrderItem ot : newOrderItemList) {
            OrderIds.add(ot.OrderId);
        }
        Map<Id, Order> orders = new Map<Id, Order>([SELECT Id, Publicity_Approved__c, Publicity_Submitted__c FROM Order WHERE Id IN :orderIds]);
        for (OrderItem item : newOrderItemList) {
            Order relatedOrder = orders.get(item.OrderId);
            if (relatedOrder != null) {
                if (relatedOrder.Publicity_Approved__c || relatedOrder.Publicity_Submitted__c ) {
                    item.addError(Custom_Messages__mdt.getInstance('Add_Product_Restriction').value__c);
                }
            }
        }
    }
    // HRP- 12664 --> End
}