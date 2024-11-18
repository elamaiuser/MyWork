public class BSFWeeklyStaffingRTReportController {
    public List<BSFWeeklyStaffingRoleTimeController.WeeklyStaffingRTReportWrapper> wrapper {get; set;}
    public BSFWeeklyStaffingRTReportController(){
        Date sdate;
        Date edate;

        String startDate = Apexpages.currentPage().getParameters().get('startdate');
        String endDate = Apexpages.currentPage().getParameters().get('enddate');
        String collOpIds = Apexpages.currentPage().getParameters().get('collopids');
        String driveType = Apexpages.currentPage().getParameters().get('drivetypes');
        String drivedispatch = Apexpages.currentPage().getParameters().get('dispatch');

        if(String.isNotBlank(startDate)){
            startDate = String.escapeSingleQuotes(startDate);
            startDate = startDate.escapeHtml4();
            sdate = Date.valueOf(startDate);
        }
        if(String.isNotBlank(endDate)){
            endDate = String.escapeSingleQuotes(endDate);
            endDate = endDate.escapeHtml4();
            edate = Date.valueOf(endDate);
        }
        if(String.isNotBlank(collOpIds)){
            collOpIds = String.escapeSingleQuotes(collOpIds);
            collOpIds = collOpIds.escapeHtml4();
        }
        if(String.isNotBlank(driveType)){
            driveType = String.escapeSingleQuotes(driveType);
            driveType = driveType.escapeHtml4();
        }
        if(String.isNotBlank(drivedispatch)){
            drivedispatch = String.escapeSingleQuotes(drivedispatch);
            drivedispatch = drivedispatch.escapeHtml4();
        }

        if(!Test.isRunningTest()){
            wrapper = BSFWeeklyStaffingRoleTimeController.searchRoleTimeReport(sdate,edate,drivedispatch,collOpIds,driveType);
        }
        wrapper = BSFWeeklyStaffingRoleTimeController.addBlankResources(wrapper);
        wrapper = BSFWeeklyStaffingRoleTimeController.calculateRowSpan(wrapper);

        if(ApexPages.currentPage().getParameters().get('force_download') != null 
                    && ApexPages.currentPage().getParameters().get('force_download') == 'true'){
                        ApexPages.currentPage().getHeaders().put('Content-Disposition', 'attachment; filename="WeeklyStaffingRoleTimeReport.pdf"');
        } 
    }
}