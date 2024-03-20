public virtual class skedDateRange implements Comparable {

    public String recordId;
    public Date startDate;
    public Date endDate;
    public Boolean isSystemGenerated;
    public SObject record;
    public Boolean hasRecordId = recordId != null;
    public Boolean isDelete = false;

    public skedDateRange(String recordId, Date startDate, Date endDate, Boolean isSystemGenerated, SObject record) {
        this.recordId = recordId;
        this.startDate = startDate;
        this.endDate = endDate;
        this.isSystemGenerated = isSystemGenerated;
        this.record = record;
    }

    public Integer compareTo(Object dateRangeObj) {
        skedDateRange dateRange = (skedDateRange) dateRangeObj;

        if (startDate == dateRange.startDate) return dateRange.endDate.daysBetween(endDate);

        if (endDate == null || dateRange.startDate == null || dateRange.endDate < startDate) {
            return 1;
        } else if (startDate == null || dateRange.endDate == null || dateRange.startDate > endDate) {
            return -1;
        }
        
        return dateRange.startDate.daysBetween(startDate);
    }

    public override String toString() {
        return startDate + ' :: ' + endDate + ' ::: ' + recordId + ' ::: ' + isSystemGenerated + ' ::: ' + isDelete;
    }
}