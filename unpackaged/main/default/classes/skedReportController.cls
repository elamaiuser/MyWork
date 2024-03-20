public class skedReportController {
    @AuraEnabled(cacheable=true)
    public static String getreport(id reportId, List<String> filter){
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata reportMd = describe.getReportMetadata();
        List<Reports.ReportFilter> reportFilters = reportMd.getReportFilters();
        if(!filter.isEmpty() && !filter[2].contains('None')) {
            Reports.ReportFilter newFilter = new Reports.ReportFilter();  
            newFilter.setColumn(filter[0]); 
            newFilter.setOperator(filter[1]);
            newFilter.setValue(filter[2]);
            reportFilters.add(newFilter);
        }

        Report reportRec = [SELECT
                Id
        FROM Report
        WHERE Id = :reportId];

        System.debug('REPORT FILTERS ' + reportFilters);
        Reports.ReportResults reportResult = Reports.ReportManager.runReport(reportRec.Id, reportMd, true);
    
        return JSON.serialize(reportResult);
    }
}