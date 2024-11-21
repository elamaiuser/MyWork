public class skedDateRangeUtils {

    public static List<skedDateRange> GetNewDateRanges(List<skedDateRange> dateRanges, skedDateRange systemDateRange) {
        List<skedDateRange> result = new List<skedDateRange>();

        // If it's the first record and we don't have a system one yet, this becomes the system one.
        if (dateRanges.size() == 1 && systemDateRange == null) {
            dateRanges[0].startDate = null;
            dateRanges[0].endDate = null;
            dateRanges[0].isSystemGenerated = true;
            result.add(dateRanges[0]);
            return result;
        }

        dateRanges.sort();

        result.add(new skedDateRange(null, null, dateRanges[0].startDate.addDays(-1), true, systemDateRange.record));
        for (Integer i = 0; i < dateRanges.size(); i++) {
            skedDateRange thisDateRange = dateRanges[i];
            skedDateRange nextDateRange = (i + 1 < dateRanges.size()) ? dateRanges[i+1] : null;

            if (nextDateRange == null) {
                break;
            } else {
                if (thisDateRange.endDate.daysBetween(nextDateRange.startDate) > 1) {
                    result.add(new skedDateRange(null, thisDateRange.endDate.addDays(1), 
                        nextDateRange.startDate.addDays(-1), true, systemDateRange.record
                    ));
                }
            }
        }
        result.add(new skedDateRange(null, dateRanges[dateRanges.size()-1].endDate.addDays(1), null, true, systemDateRange.record));
        return result;
    }

    public static skedDateRangeResult IsDateRangeValid(List<skedDateRange> dateRanges, skedDateRange newDateRange) {
        skedDateRangeResult result = new skedDateRangeResult();
        if (dateRanges == null || dateRanges.isEmpty()) return result;

        dateRanges.sort();
        for (skedDateRange dateRange : dateRanges) {
            Boolean overlapFound = hasOverlap(dateRange, newDateRange);
            if (overlapFound) {
                result.isSuccess = false;
                result.overlappingDateRange = dateRange;
            }
        }

        return result;
    }

    private static Boolean hasOverlap(skedDateRange dateRange, skedDateRange newDateRange) {
        Boolean overlapFound = false;
        if (newDateRange.startDate == null || newDateRange.endDate == null) {
            overlapFound = true;
        }

        if (dateRange.startDate != null && 
            (newDateRange.startDate <= dateRange.startDate && 
                newDateRange.endDate >= dateRange.startDate)) {
            overlapFound = true;
        }

        if (dateRange.endDate != null &&
            (newDateRange.startDate <= dateRange.endDate &&
                newDateRange.endDate >= dateRange.endDate)) {
            overlapFound = true;
        }

        if ((dateRange.startDate != null && dateRange.endDate != null) &&
            (dateRange.startDate < newDateRange.startDate &&
                newDateRange.endDate < dateRange.endDate)) {
            overlapFound = true;
        }

        return overlapFound;
    }

    public class skedDateRangeResult {
        public Boolean isSuccess;
        public skedDateRange overlappingDateRange;
        public List<skedDateRange> updatedDateRanges;

        public skedDateRangeResult() {
            this.isSuccess = true;
            this.updatedDateRanges = new List<skedDateRange>();
        }
    }
}