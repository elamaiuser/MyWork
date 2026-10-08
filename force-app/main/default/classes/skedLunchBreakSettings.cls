/**
 * Neutral, drive-type-agnostic lunch-break config for a single shift - the 4 scalar fields both
 * Mobile and Fixed Site's lunch-break calculations need.
 */
public virtual class skedLunchBreakSettings {
    public Boolean lunchBreak = false;
    public Boolean lunchBreakBeforeDrawHours = false;
    public Decimal maximumLunchBreakDuration = 0;
    public Decimal unpaidLunchBreakDuration = 0;
}
