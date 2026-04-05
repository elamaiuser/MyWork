/*
 * 
 * Modification Log 
 * Date					Developer Name			Comments
 * ***************************************************************************
 * 28/04/2023				Balaji N			Logic for HRP-9766 & HRP-9749 
 * 
 * */

public class PowerBIProxyController 
{
    public string redirectURL{get;set;}
 	public string jid;
    public PowerBIProxyController() {
        generateUrl(); // Populate redirectURL on page load
    }
    //This Method is called from the Report VF pages(StagingSheetReport & WeeklyStaffingRoleReport)
    public PageReference redirect() 
    {
        PageReference reference=new PageReference(generateUrl());
        reference.setRedirect(true);
        return reference;
    }
    
    public string generateUrl()
    {
        String pageName = ApexPages.currentPage().getUrl().substringAfter('apex/').split('\\?')[0];
        
        
        //WeeklyStaffingRoleReport
        if(pageName == 'WeeklyStaffingRoleReport')
        {
            String arcRegionName;
            String divisionName;
            Date today = system.today();
            Date todayPlusN = system.today()+integer.valueof(system.label.DateOffset_for_WeeklyStaff);
            string todayDate = today.month()+'%2F'+today.Day()+'%2F'+today.Year();
            string endDate = todayPlusN.month()+'%2F'+todayPlusN.Day()+'%2F'+todayPlusN.Year();
            list<sked__Resource__c> resourceId = new list<sked__Resource__c>();
            resourceId =[select id,sked__User__r.FirstName,sked__User__r.LastName,sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__c,sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name,
                         sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name from sked__Resource__c where sked__User__c =:userinfo.getUserId() Limit 1];
            if(!resourceId.isEmpty())
            {
                arcRegionName = resourceId[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name;
                divisionName = resourceId[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name;
            }
            redirectURL=system.label.WeeklyStaffingRoleReportURL+'?rp:ResourceScheduleEventStartDate='+todayDate+'&rp:CollectionsTaxonomyCurrentDivision='+divisionName+'&rp:CollectionsTaxonomyCurrentRegion='+arcRegionName+'&rp:ResourceScheduleEventEndDate='+endDate;
            
            
        }
        //WeeklyStaffingRoleReport
        
        
        
        //Staging Sheet
        if(pageName == 'StagingSheetReport')
        {
            String dJobId =Apexpages.currentPage().getParameters().get('jobId');
            if(dJobId==null)
            {
                dJobId = 'a1J5c00000XS4skEAD';
            }
            if(test.isRunningTest())
                {
                    dJobId=this.jid;
                }
            
            String driveUfid;
            String driveDate;
            if(dJobId != null)
            {
                id jobId = id.valueof(dJobId);
                sked__Job__c job = [select id,sked_Drive__c,sked_Drive__r.sked_UFID__c,sked_Drive__r.sked_Opportunity__r.Drive_date__c from sked__Job__c where id =:jobId limit 1];
                driveUfid = job.sked_Drive__r.sked_UFID__c;
                driveDate = job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.month()+'%2F'+job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.Day()+'%2F'+job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.Year();
            }
            redirectURL=system.label.StagingSheetReportURL+'&rp:FromDateDate='+driveDate+'&rp:ToDateDate='+driveDate+'&rp:DriveDriveUFID='+driveUfid;
        }
        //Staging Sheet
        
       if(pageName == 'MOEStagingSheetReport')
        {
            String dJobId =Apexpages.currentPage().getParameters().get('jobId');
            if(dJobId==null)
            {
                dJobId = 'a1J5c00000XS4skEAD';
            }
            if(test.isRunningTest())
                {
                    dJobId=this.jid;
                }
            
            String driveUfid;
            String driveDate;
            if(dJobId != null)
            {
                id jobId = id.valueof(dJobId);
                sked__Job__c job = [select id,sked_Drive__c,sked_Drive__r.sked_UFID__c,sked_Drive__r.sked_Opportunity__r.Drive_date__c from sked__Job__c where id =:jobId limit 1];
                driveUfid = job.sked_Drive__r.sked_UFID__c;
                driveDate = job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.month()+'%2F'+job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.Day()+'%2F'+job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.Year();
            }
            redirectURL=system.label.MOEStagingSheetReportURL+'&rp:FromDateDate='+driveDate+'&rp:ToDateDate='+driveDate+'&rp:DriveDriveUFID='+driveUfid;
        }

        system.debug(redirectURL);
        return redirectURL;

    }
    
    /*public   PowerBIProxyController()
    {
        String pageName = ApexPages.currentPage().getUrl().substringAfter('apex/').split('\\?')[0];
        
        
        
        
        //WeeklyStaffingRoleReport
        if(pageName == 'WeeklyStaffingRoleReport')
        {
            String arcRegionName;
            String divisionName;
            Date today = system.today();
            string todayDate = today.month()+'%2F'+today.Day()+'%2F'+today.Year();
            list<sked__Resource__c> resourceId = new list<sked__Resource__c>();
            resourceId =[select id,sked__User__r.FirstName,sked__User__r.LastName,sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__c,sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name,
                         sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name from sked__Resource__c where sked__User__c =:userinfo.getUserId() Limit 1];
            if(!resourceId.isEmpty())
            {
                arcRegionName = resourceId[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name;
                divisionName = resourceId[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name;
            }
            redirectURL='https://app.powerbi.com/groups/me/apps/1bf85886-e730-4e80-9ea2-4330448f7aa5/rdlreports/1eacf224-056a-46ad-baf4-af03654cf447'+
                '?rp:ResourceScheduleEventStartDate='+todayDate+'&rp:CollectionsTaxonomyCurrentDivision='+divisionName+
                '&rp:CollectionsTaxonomyCurrentRegion='+arcRegionName;
        }
        //WeeklyStaffingRoleReport
        
        
        //Staging Sheet
        if(pageName == 'StagingSheetReport' || pageName == 'ReportPOC')
        {
            String dJobId =Apexpages.currentPage().getParameters().get('jobId');
            if(dJobId==null)
            {
                dJobId = 'a1J5c00000XS4skEAD';
            }
            
            String driveUfid;
            String driveDate;
            if(dJobId != null)
            {
                id jobId = id.valueof(dJobId);
                sked__Job__c job = [select id,sked_Drive__c,sked_Drive__r.sked_UFID__c,sked_Drive__r.sked_Opportunity__r.Drive_date__c from sked__Job__c where id =:jobId limit 1];
                driveUfid = job.sked_Drive__r.sked_UFID__c;
                driveDate = job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.month()+'%2F'+job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.Day()+'%2F'+job.sked_Drive__r.sked_Opportunity__r.Drive_date__c.Year();
            }
            redirectURL='https://app.powerbi.com/groups/me/apps/1bf85886-e730-4e80-9ea2-4330448f7aa5/rdlreports/7ed1ce82-1f15-4528-8e48-e05c48fc0b17'+
                '?rp:FromDateDate='+driveDate+'&rp:ToDateDate='+driveDate+'&rp:DriveDriveUFID='+driveUfid;
        }
        //Staging Sheet
        
        system.debug(redirectURL);
    }*/
}