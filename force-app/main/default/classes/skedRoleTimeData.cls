/**
 * Neutral, drive-type-agnostic role-time/travel-time fields for one resource role group -
 * skedMobileDriveShiftCalculator.RoleTimeData extends this with zero added fields (Mobile has
 * nothing further to add), and a future Fixed Site shift calculator can use it directly.
 */
public virtual class skedRoleTimeData {
    public Decimal leadTime = 0;
    public Decimal travelTime = 0;
    public Decimal siteLogisticsTo = 0;
    public Decimal setupTime = 0;
    public Decimal breakdownTime = 0;
    public Decimal travelTime2 = 0;
    public Decimal siteLogisticsBack = 0;
    public Decimal wrapUpTime = 0;
    public Decimal travelTimeCoToSiteVariance = 0;
    public Decimal travelTimeSiteToCoVariance = 0;
}
