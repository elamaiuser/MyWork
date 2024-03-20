public  with sharing class DriveMarketingProgramTriggerService {
    
    /*
    * JIRA Ticket: HRP - 1614, 
    * Description: 2.0 DRD AM: Selecting Publicity Order Item
    */
    
    public static void setOrderBudget( List<Drive_Marketing_Programs__c> oldDriveItems, List<Drive_Marketing_Programs__c> newDriveItems,
                                                        Map<Id,Drive_Marketing_Programs__c> oldDriveItemsMap,Map<Id,Drive_Marketing_Programs__c> newDriveItemsMap){
                                                        

		List<Marketing_Program__c> mproglist = new List<Marketing_Program__c>();
		List<Order> orderupdatelist = new List<Order>();
		
	    Set<Id> marketingprogramid = new Set<Id>();  
	    Set<Id> opportunityids = new Set<Id>();  

		Map<Id, Marketing_Program__c> mpobjectmap = new Map<Id, Marketing_Program__c>();
		
		for( Drive_Marketing_Programs__c dm : newDriveItems ){
			marketingprogramid.add( dm.Marketing_Program__c);			
		}
		
		mproglist = [select Id, Name from Marketing_Program__c where Id IN: marketingprogramid  ];
		for( Marketing_Program__c mp : mproglist ){
			mpobjectmap.put( mp.Id, mp );
		}
		
		
		for( Drive_Marketing_Programs__c dm : newDriveItems ){
			if( mpobjectmap.containsKey( dm.Marketing_Program__c )  && (mpobjectmap.get( dm.Marketing_Program__c ).Name == 'Pint Sized Hero' || mpobjectmap.get( dm.Marketing_Program__c ).Name == 'Future Blood Donor')  ){
				opportunityids.add( dm.Blood_Drive_Opportunity__c);
			}
		}
		
		if( !opportunityids.isEmpty() ){
			orderupdatelist = [ select Id from Order where OpportunityId IN:opportunityids  ];
		}
		
		if( !orderupdatelist.isEmpty() ){
			// Blank update, to recalculate Order budget
			//Schema.DescribeSObjectResult ds = Order.sObjectType.getDescribe();
            //if( ds.isUpdateable() ){}
				update orderupdatelist;
						
			
		}
		
                                                        
    }
    
}