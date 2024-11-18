global class skedRoleTimeVarianceAdjustment {
    public Date startDate;
    public Date endDate;
    public String varianceApplyTo;
    public Integer adjustAmount;
    public String resourceRoleGroup;
    public String siteId;
    public String daysOfWeek;

    global skedRoleTimeVarianceAdjustment(Date startDate, Date endDate, String varianceApplyTo, Integer adjustAmount, String resourceRoleGroup, String siteId, String daysOfWeek) {
        this.startDate = startDate;
        this.endDate = endDate;
        this.varianceApplyTo = varianceApplyTo;
        this.adjustAmount = adjustAmount;
        this.resourceRoleGroup = resourceRoleGroup;
        this.siteId = siteId;
        this.daysOfWeek = daysOfWeek;
    }
}