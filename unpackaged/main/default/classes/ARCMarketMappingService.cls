public with sharing class ARCMarketMappingService {
	
    public static void updateAccountMarketField( List<ARC_Market_Mapping__c> newItems, Map<Id,ARC_Market_Mapping__c> oldMap, Map<Id,ARC_Market_Mapping__c> newMap ){
        Set<String> zipcodeset = new Set<String>();
        Map<String, String > zipMarketmaps = new Map<String, String >();
        
        for( ARC_Market_Mapping__c amm : newItems ){
            if( oldMap.get(amm.Id).Zip_Code__c != amm.Zip_Code__c ){
                zipcodeset.add( amm.Zip_Code__c );
                zipMarketmaps.put( oldMap.get(amm.Id).Zip_Code__c, amm.Market__c );
            }else if( oldMap.get(amm.Id).Market__c != amm.Market__c ){
                zipcodeset.add( amm.Zip_Code__c );
                zipMarketmaps.put( oldMap.get(amm.Id).Zip_Code__c, amm.Market__c );
            }
             
        }
        
        List<Account> acclist = new List<Account>();  
        acclist = getAccountByZipcode( zipcodeset );
        
        if( !acclist.isEmpty() ) {
            for( Account a : acclist ){
                a.Market__c = zipMarketmaps.get( String.valueOf( a.BillingPostalCode ) );
            }
            //Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();
            //if(ds.isUpdateable()){}
			update acclist ;
			
            
            
        }
        
    }
    
    public static void updateAccountMarketFieldOnInsert( List<ARC_Market_Mapping__c> newItems ){
        Set<String> zipcodeset = new Set<String>();
        Map<String, String > zipMarketmaps = new Map<String, String >();
        
        for( ARC_Market_Mapping__c amm : newItems ){
            zipcodeset.add( amm.Zip_Code__c );
            zipMarketmaps.put( amm.Zip_Code__c, amm.Market__c );
        }
        
        List<Account> acclist = new List<Account>();  
        acclist = getAccountByZipcode( zipcodeset );
        
        if( !acclist.isEmpty() ) {
            for( Account a : acclist ){
                a.Market__c = zipMarketmaps.get( String.valueOf( a.BillingPostalCode ) );
            }
            
            //Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();
            //if(ds.isUpdateable()){}
            update acclist ;
        }
         
    }
    
    public static List<Account> getAccountByZipcode( Set<String> zipcodeset ){
        List<Account> accs = new List<Account>();
       /* Set<String> zipcodes = new Set<String>();
        Account acobj ;
        
        for( Decimal d : zipcodeset ){
            zipcodes.add( String.valueOf(d) );
        }*/
        
        System.debug( 'zipcodes is ' + zipcodeset );
        
        accs = [select Id, BillingPostalCode, Market__c from Account where BillingPostalCode in: zipcodeset ];
        
        return accs;
    }
}