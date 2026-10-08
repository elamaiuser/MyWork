public class PublicityPackageItemTriggerService {
    
    public static void getProductImageUrl(List<Publicity_Package_Item__c> newItems, Map<Id, Publicity_Package_Item__c> oldMap) {
        for(Publicity_Package_Item__c packageItem : newItems) {
            if(packageItem.Product_Image__c != null && 
               (oldMap == null || packageItem.Product_Image__c != oldMap.get(packageItem.Id).Product_Image__c)
              ) {
                Integer start = packageItem.Product_Image__c.indexOf('src="') + 5;
                Integer finish = packageItem.Product_Image__c.indexOf('"', start);
                packageItem.Product_Image_URL__c = packageItem.Product_Image__c.substring(start, finish);
            }
        }
    }
}