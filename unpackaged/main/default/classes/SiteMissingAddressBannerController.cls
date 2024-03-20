/* HRP - 8347
        * A banner will show up in the site record page indicating the users that the site address is missing
        * so that it won't impact the plan a drive flow (HRP - 9832)
    */

    public class SiteMissingAddressBannerController {
      
        @AuraEnabled(cacheable=true)
        public static String checkSiteMissingAddress(String siteId)
        {
            
            String siteAddressFieldsMissingMessage = '';

            List<String> missingFields = new List<String>();
                     
              Map<String,sked__Location__c> siteMap = new Map<String,sked__Location__c>([Select Id , sked__Address__c, sked_Address_1__c, sked_City__c, sked_State__c, sked_Zip_Code__c from sked__Location__c where Id =:siteId]);           
            
               if(!siteMap.isEmpty())
                {
                    sked__Location__c siteAddressMissingObj = siteMap.get(siteId);
                
                    if(siteAddressMissingObj.sked_Address_1__c != null && siteAddressMissingObj.sked_City__c != null
                    	&& siteAddressMissingObj.sked_State__c != null && siteAddressMissingObj.sked_Zip_Code__c != null)
                    {
                        return '';
                    }
                    else
                    {
                    
                        if(siteAddressMissingObj.sked_Address_1__c == null)
                        {
                            missingFields.add('Address');                   
                        }
                    
                        if(siteAddressMissingObj.sked_City__c == null)
                        {
                            missingFields.add('City');
                        }
                        if(siteAddressMissingObj.sked_State__c == null)
                        {
                            missingFields.add('State');
                        }
                        if(siteAddressMissingObj.sked_Zip_Code__c == null)
                        {
                            missingFields.add('Zip Code');
                        }
                        if(siteAddressMissingObj.sked__Address__c == null)
                        {
                            missingFields.add('Entire Address');
                        }
                    }
                     
                        if(missingFields.size() > 0)
            			{
                			if(!missingFields.contains('Entire Address'))
                			{
                				siteAddressFieldsMissingMessage = 'Site Missing Address. Please Populate '+String.join(missingFields, ', ')+'.';  
                			}
           			 }
                         
                }
        
            return missingFields.contains('Entire Address') ? 'Site Missing Address.' : siteAddressFieldsMissingMessage;  
        
        
        }
}