@isTest
public class Bsf_BatchCancelBloodDrivePendingTEST {
    
  
    
    static testMethod void test(){
        
        Date newdate= system.today();
        String closereason='closereason';
        
        Account a=new Account();
        a.name='account';
        a.Closure_Reason__c='closereason';
        insert a;
        
        contact c=new contact();
        c.AccountId=a.Id;
        c.FirstName='contact1';
        c.Email='abcd@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact2';
        c.Phone='7474749';
        insert c;
        
        
          
        
        sked__Location__c lc=new sked__Location__c();
        lc.sked_National_Name__c='national';
        lc.sked_Physical_Location_Type__c='inside';
        lc.sked_Site_Contact__c=c.Id;
        lc.sked_Site_Main_Phone__c='838-438-4367';
        lc.sked_Start_Date__c=system.today();
        lc.sked_End_Date__c=system.today()+1;
        lc.sked_Address_1__c='kolkata';
        lc.sked_City__c='kolkata';
        lc.sked_County__c='India';
        lc.sked_Zip_Code__c='70456';
        lc.sked_State__c='WB';
       // lc.sked_Site_Inspection_Completed_By__c=u.Id;
        lc.sked_Site_Building_Name__c='new site building';
        lc.sked_Floor_Description__c='desc';
        lc.sked_Room_Name__c='room name';
        lc.sked_Room_Size__c='Bus';
        lc.sked_Automation_Suitability__c='Suitable';
        lc.sked_Wireless_Policy__c='Accepted';
        lc.sked_Outside_stairs__c=3;
        lc.sked_Base_Description__c='base desc';
        lc.sked_Directions_From_CollectionOperation__c='sked_Directions_From_CollectionOperation__c';
        lc.sked_ARC_Vehicle_Parking_Directions__c='sked_ARC_Vehicle_Parking_Directions__c';
        lc.sked_Staff_Personal_Parking_Directions__c='sked_Staff_Personal_Parking_Directions__c';
        lc.Source__c = 'Custom New Form';
        lc.Name='site name';
        insert lc;
        
        /*
        List<Opportunity> OppList=new List<Opportunity>();
        Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Fixed Site',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = newdate+1,
        	CloseDate = newdate-1,
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp.AccountId = a.Id;
            mobileOpp.Drive_Site__c = lc.id;
			//insert mobileOpp;
			OppList.add(mobileOpp); 
        
        */
         TriggerHandler.bypass('OpportunityTriggerHandler');
        Opportunity mobileOpp1 = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Fixed Site',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive 1',
        	Drive_Date__c = newdate+1,
        	CloseDate = newdate-1,
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp1.AccountId = a.Id;
            mobileOpp1.Drive_Site__c = lc.id;
			insert mobileOpp1;
			//OppList.add(mobileOpp1);
			
       
        
        
       opportunity op=[select id,Drive_Name__c from opportunity limit 1];
       system.debug('op ###'+op);
       
        Test.startTest();
        Id accid=[select id from account limit 1].id;
        system.debug('accid&& '+accid);
        
        Bsf_BatchCancelBloodDrivePendingOpp ba= new Bsf_BatchCancelBloodDrivePendingOpp(accid,newdate,closereason);
        Id jobid= Database.executeBatch(ba);
        Test.stopTest();
        
    }
    
}