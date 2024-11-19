public class skedRoleTimeVarianceUtils {
    public static List<skedRoleTimeVarianceAdjustment> getAdjustmentsToAddBufferForRelatedJobs(List<sked_Role_Time_Variance__c> rtvs) {
        return getAdjustmentsToAddOrRemoveBufferForJobs(rtvs, true);
    }

    public static List<skedRoleTimeVarianceAdjustment> getAdjustmentsToModifyBufferForRelatedJobs(List<sked_Role_Time_Variance__c> rtvs, Map<Id, sked_Role_Time_Variance__c> oldMap) {
        List<skedRoleTimeVarianceAdjustment> rtvAdjustments = new List<skedRoleTimeVarianceAdjustment>();
        for (sked_Role_Time_Variance__c rtv : rtvs) {
            sked_Role_Time_Variance__c oldRtv = oldMap.get(rtv.Id);

            skedRTVAdjustmentAnalysisResult analysisResult = new skedRTVAdjustmentAnalysisResult();
            analyzeAdjustmentsByEffectiveDate(analysisResult, rtv, oldRtv);
            analyzeAdjustmentsByResourceRoleGroup(analysisResult, rtv, oldRtv);
            analyzeAdjustmentsByVarianceAffectedFields(analysisResult, rtv, oldRtv);
            analyzeAdjustmentsByDaysOfWeek(analysisResult, rtv, oldRtv);
            rtvAdjustments.addAll(analysisResult.adjustments);

            if (analysisResult.startDateToMofify != NULL && analysisResult.endDateToModify != NULL 
                && analysisResult.affectedFieldsToModify != NULL && analysisResult.resourceRoleGroupsToModify != NULL
                && analysisResult.daysOfWeekToModify != NULL
            ) {
                rtvAdjustments.add(new skedRoleTimeVarianceAdjustment(
                    analysisResult.startDateToMofify,
                    analysisResult.endDateToModify, 
                    analysisResult.affectedFieldsToModify,
                    getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c) - getAmountForCalculate(oldRtv.sked_Variation_Amount__c, oldRtv.sked_Buffer_Type__c),
                    analysisResult.resourceRoleGroupsToModify,
                    rtv.sked_Location__c,
                    analysisResult.daysOfWeekToModify
                ));
            }
        }

        return rtvAdjustments;
    }

    public static List<skedRoleTimeVarianceAdjustment> getAdjustmentsToRemoveBufferForRelatedJobs(List<sked_Role_Time_Variance__c> rtvs) {
        return getAdjustmentsToAddOrRemoveBufferForJobs(rtvs, false);
    }

    ///////////////////////////////////////////////////////////////////// PRIVATE METHODS /////////////////////////////////////////////////////////////////////
    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsToAddOrRemoveBufferForJobs(List<sked_Role_Time_Variance__c> rtvs, boolean isInsert) {
        List<skedRoleTimeVarianceAdjustment> rtvAdjustments = new List<skedRoleTimeVarianceAdjustment>();
        for (sked_Role_Time_Variance__c rtv : rtvs) {
            rtvAdjustments.add(
                new skedRoleTimeVarianceAdjustment(
                    skedDateTimeUtils.getValueOrMinDate(rtv.sked_Effective_Start_Date__c),
                    skedDateTimeUtils.getValueOrMaxDate(rtv.sked_Effective_End_Date__c), 
                    rtv.sked_Variance_Applies_to__c,
                    getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c) * (isInsert ? 1 : -1),
                    rtv.sked_Resource_Role_Group__c,
                    rtv.sked_Location__c,
                    rtv.sked_Days_of_Week__c
                )
            );
        }

        return rtvAdjustments;
    }

    private static skedRTVAdjustmentAnalysisResult analyzeAdjustmentsByEffectiveDate(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        analysisResult.adjustments.addAll(getAdjustmentsForInsertByEffectiveDate(rtv, oldRtv));
        analysisResult.adjustments.addAll(getAdjustmentsForRemoveByEffectiveDate(rtv, oldRtv));
        updateModifiedAdjustmentByEffectiveDate(analysisResult, rtv, oldRtv);
        return analysisResult;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForInsertByEffectiveDate(sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        Date newRtvStartDate = skedDateTimeUtils.getValueOrMinDate(rtv.sked_Effective_Start_Date__c);
        Date newRtvEndDate = skedDateTimeUtils.getValueOrMaxDate(rtv.sked_Effective_End_Date__c);
        Date oldRtvStartDate = skedDateTimeUtils.getValueOrMinDate(oldRtv.sked_Effective_Start_Date__c);
        Date oldRtvEndDate = skedDateTimeUtils.getValueOrMaxDate(oldRtv.sked_Effective_End_Date__c);

        if (newRtvStartDate < oldRtvStartDate) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                newRtvStartDate,
                newRtvEndDate < oldRtvStartDate ? newRtvEndDate : oldRtvStartDate.addDays(-1),
                rtv.sked_Variance_Applies_to__c,
                getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c),
                rtv.sked_Resource_Role_Group__c,
                rtv.sked_Location__c,
                rtv.sked_Days_Of_Week__c
            ));
        }

        if (newRtvEndDate > oldRtvEndDate) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                newRtvStartDate > oldRtvEndDate ? newRtvStartDate : oldRtvEndDate.addDays(1),
                newRtvEndDate,
                rtv.sked_Variance_Applies_to__c,
                getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c),
                rtv.sked_Resource_Role_Group__c,
                rtv.sked_Location__c,
                rtv.sked_Days_Of_Week__c
            ));
        }

        return adjustments;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForRemoveByEffectiveDate(sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        Date newRtvStartDate = skedDateTimeUtils.getValueOrMinDate(rtv.sked_Effective_Start_Date__c);
        Date newRtvEndDate = skedDateTimeUtils.getValueOrMaxDate(rtv.sked_Effective_End_Date__c);
        Date oldRtvStartDate = skedDateTimeUtils.getValueOrMinDate(oldRtv.sked_Effective_Start_Date__c);
        Date oldRtvEndDate = skedDateTimeUtils.getValueOrMaxDate(oldRtv.sked_Effective_End_Date__c);

        if (newRtvStartDate > oldRtvStartDate) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                oldRtvStartDate,
                newRtvStartDate > oldRtvEndDate ? oldRtvEndDate : newRtvStartDate.addDays(-1),
                oldRtv.sked_Variance_Applies_to__c,
                getAmountForCalculate(oldRtv.sked_Variation_Amount__c, oldRtv.sked_Buffer_Type__c) * -1,
                oldRtv.sked_Resource_Role_Group__c,
                oldRtv.sked_Location__c,
                oldRtv.sked_Days_Of_Week__c
            ));
        }

        if (newRtvEndDate < oldRtvEndDate) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                newRtvEndDate < oldRtvStartDate ? oldRtvStartDate : newRtvEndDate.addDays(1),
                oldRtvEndDate,
                oldRtv.sked_Variance_Applies_to__c,
                getAmountForCalculate(oldRtv.sked_Variation_Amount__c, oldRtv.sked_Buffer_Type__c) * -1,
                oldRtv.sked_Resource_Role_Group__c,
                oldRtv.sked_Location__c,
                oldRtv.sked_Days_Of_Week__c
            ));
        }

        return adjustments;
    }

    private static void updateModifiedAdjustmentByEffectiveDate(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        Date newRtvStartDate = skedDateTimeUtils.getValueOrMinDate(rtv.sked_Effective_Start_Date__c);
        Date newRtvEndDate = skedDateTimeUtils.getValueOrMaxDate(rtv.sked_Effective_End_Date__c);
        Date oldRtvStartDate = skedDateTimeUtils.getValueOrMinDate(oldRtv.sked_Effective_Start_Date__c);
        Date oldRtvEndDate = skedDateTimeUtils.getValueOrMaxDate(oldRtv.sked_Effective_End_Date__c);

        if (newRtvStartDate <= oldRtvEndDate && newRtvEndDate >= oldRtvStartDate) {
            analysisResult.startDateToMofify = skedUtils.getMaxFromDates(new List<Date>{newRtvStartDate, oldRtvStartDate});
            analysisResult.endDateToModify = skedUtils.getMinFromDates(new List<Date>{newRtvEndDate, oldRtvEndDate});
        }
    }

    private static skedRTVAdjustmentAnalysisResult analyzeAdjustmentsByResourceRoleGroup(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        analysisResult.adjustments.addAll(getAdjustmentsForInsertByResourceRoleGroup(analysisResult, rtv, oldRtv));
        analysisResult.adjustments.addAll(getAdjustmentsForRemoveByResourceRoleGroup(analysisResult, rtv, oldRtv));
        updateModifiedAdjustmentByResourceRoleGroup(analysisResult, rtv, oldRtv);
        return analysisResult;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForInsertByResourceRoleGroup(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        List<String> newRtvResourceRoleGroups = rtv.sked_Resource_Role_Group__c.split(';');    
        List<String> resourceRoleGroupForInsert = new List<String>();
        for (String newRtvResourceRoleGroup : newRtvResourceRoleGroups) {
            if (!oldRtv.sked_Resource_Role_Group__c.contains(newRtvResourceRoleGroup)) {
                resourceRoleGroupForInsert.add(newRtvResourceRoleGroup);
            }
        }

        if (resourceRoleGroupForInsert.size() > 0) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                analysisResult.startDateToMofify,
                analysisResult.endDateToModify, 
                rtv.sked_Variance_Applies_to__c,
                getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c),
                String.join(resourceRoleGroupForInsert, ';'),
                rtv.sked_Location__c,
                rtv.sked_Days_Of_Week__c
            ));
        }
        return adjustments;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForRemoveByResourceRoleGroup(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        List<String> oldRtvResourceRoleGroups = oldRtv.sked_Resource_Role_Group__c.split(';');
        List<String> resourceRoleGroupForRemove = new List<String>();
        for (String oldRtvResourceRoleGroup : oldRtvResourceRoleGroups) {
            if (!rtv.sked_Resource_Role_Group__c.contains(oldRtvResourceRoleGroup)) {
                resourceRoleGroupForRemove.add(oldRtvResourceRoleGroup);
            }
        }

        if (resourceRoleGroupForRemove.size() > 0) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                analysisResult.startDateToMofify,
                analysisResult.endDateToModify, 
                oldRtv.sked_Variance_Applies_to__c,
                getAmountForCalculate(oldRtv.sked_Variation_Amount__c, oldRtv.sked_Buffer_Type__c) * -1,
                String.join(resourceRoleGroupForRemove, ';'),
                oldRtv.sked_Location__c,
                oldRtv.sked_Days_Of_Week__c
            ));
        }
        return adjustments;
    }

    private static void updateModifiedAdjustmentByResourceRoleGroup(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<String> newRtvResourceRoleGroups = rtv.sked_Resource_Role_Group__c.split(';');
        List<String> resourceRoleGroupsToModify = new List<String>();
        for (String newRtvResourceRoleGroup : newRtvResourceRoleGroups) {
            if (oldRtv.sked_Resource_Role_Group__c.contains(newRtvResourceRoleGroup)) {
                resourceRoleGroupsToModify.add(newRtvResourceRoleGroup);
            }
        }

        if (resourceRoleGroupsToModify.size() > 0) {
            analysisResult.resourceRoleGroupsToModify = String.join(resourceRoleGroupsToModify, ';');
        }
    }

    private static skedRTVAdjustmentAnalysisResult analyzeAdjustmentsByVarianceAffectedFields(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        analysisResult.adjustments.addAll(getAdjustmentsForInsertByVarianceAffectedFields(analysisResult, rtv, oldRtv));
        analysisResult.adjustments.addAll(getAdjustmentsForRemoveByVarianceAffectedFields(analysisResult, rtv, oldRtv));
        updateModifiedAdjustmentByVarianceAffectedFields(analysisResult, rtv, oldRtv);
        return analysisResult;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForInsertByVarianceAffectedFields(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        List<String> newRtvVarianceAffectedFields = rtv.sked_Variance_Applies_to__c.split(';');    
        List<String> varianceAffectedFieldsForInsert = new List<String>();
        for (String newRtvVarianceAffectedField : newRtvVarianceAffectedFields) {
            if (!oldRtv.sked_Variance_Applies_to__c.contains(newRtvVarianceAffectedField)) {
                varianceAffectedFieldsForInsert.add(newRtvVarianceAffectedField);
            }
        }

        if (varianceAffectedFieldsForInsert.size() > 0) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                analysisResult.startDateToMofify,
                analysisResult.endDateToModify, 
                String.join(varianceAffectedFieldsForInsert, ';'),
                getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c),
                analysisResult.resourceRoleGroupsToModify,
                rtv.sked_Location__c,
                rtv.sked_Days_Of_Week__c
            ));
        }
        return adjustments;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForRemoveByVarianceAffectedFields(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        List<String> oldRtvVarianceAffectedFields = oldRtv.sked_Variance_Applies_to__c.split(';');
        List<String> varianceAffectedFieldsForRemove = new List<String>();
        for (String oldRtvVarianceAffectedField : oldRtvVarianceAffectedFields) {
            if (!rtv.sked_Variance_Applies_to__c.contains(oldRtvVarianceAffectedField)) {
                varianceAffectedFieldsForRemove.add(oldRtvVarianceAffectedField);
            }
        }

        if (varianceAffectedFieldsForRemove.size() > 0) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                analysisResult.startDateToMofify,
                analysisResult.endDateToModify, 
                String.join(varianceAffectedFieldsForRemove, ';'),
                getAmountForCalculate(oldRtv.sked_Variation_Amount__c, oldRtv.sked_Buffer_Type__c) * -1,
                analysisResult.resourceRoleGroupsToModify,
                oldRtv.sked_Location__c,
                oldRtv.sked_Days_Of_Week__c
            ));
        }
        return adjustments;
    }

    private static void updateModifiedAdjustmentByVarianceAffectedFields(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<String> newRtvVarianceAffectedFields = rtv.sked_Variance_Applies_to__c.split(';');
        List<String> varianceAffectedFieldsToModify = new List<String>();
        for (String newRtvVarianceAffectedField : newRtvVarianceAffectedFields) {
            if (oldRtv.sked_Variance_Applies_to__c.contains(newRtvVarianceAffectedField)) {
                varianceAffectedFieldsToModify.add(newRtvVarianceAffectedField);
            }
        }

        if (varianceAffectedFieldsToModify.size() > 0) {
            analysisResult.affectedFieldsToModify = String.join(varianceAffectedFieldsToModify, ';');
        }
    }

    private static skedRTVAdjustmentAnalysisResult analyzeAdjustmentsByDaysOfWeek(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        analysisResult.adjustments.addAll(getAdjustmentsForInsertByDaysOfWeek(analysisResult, rtv, oldRtv));
        analysisResult.adjustments.addAll(getAdjustmentsForRemoveByDaysOfWeek(analysisResult, rtv, oldRtv));
        updateModifiedAdjustmentByDaysOfWeek(analysisResult, rtv, oldRtv);
        return analysisResult;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForInsertByDaysOfWeek(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        List<String> newRtvDaysOfWeek = rtv.sked_Days_Of_Week__c.split(';');    
        List<String> daysOfWeekForInsert = new List<String>();
        for (String newDayOfWeek : newRtvDaysOfWeek) {
            if (!oldRtv.sked_Days_Of_Week__c.contains(newDayOfWeek)) {
                daysOfWeekForInsert.add(newDayOfWeek);
            }
        }

        if (daysOfWeekForInsert.size() > 0) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                analysisResult.startDateToMofify,
                analysisResult.endDateToModify, 
                analysisResult.affectedFieldsToModify,
                getAmountForCalculate(rtv.sked_Variation_Amount__c, rtv.sked_Buffer_Type__c),
                analysisResult.resourceRoleGroupsToModify,
                rtv.sked_Location__c,
                String.join(daysOfWeekForInsert, ';')
            ));
        }
        return adjustments;
    }

    private static List<skedRoleTimeVarianceAdjustment> getAdjustmentsForRemoveByDaysOfWeek(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<skedRoleTimeVarianceAdjustment> adjustments = new List<skedRoleTimeVarianceAdjustment>();
        List<String> oldRtvDaysOfWeek = oldRtv.sked_Days_Of_Week__c.split(';');
        List<String> daysOfWeekForRemove = new List<String>();
        for (String oldDayOfWeek : oldRtvDaysOfWeek) {
            if (!rtv.sked_Days_Of_Week__c.contains(oldDayOfWeek)) {
                daysOfWeekForRemove.add(oldDayOfWeek);
            }
        }

        if (daysOfWeekForRemove.size() > 0) {
            adjustments.add(new skedRoleTimeVarianceAdjustment(
                analysisResult.startDateToMofify,
                analysisResult.endDateToModify, 
                analysisResult.affectedFieldsToModify,
                getAmountForCalculate(oldRtv.sked_Variation_Amount__c, oldRtv.sked_Buffer_Type__c) * -1,
                analysisResult.resourceRoleGroupsToModify,
                oldRtv.sked_Location__c,
                String.join(daysOfWeekForRemove, ';')
            ));
        }
        return adjustments;
    }

    private static void updateModifiedAdjustmentByDaysOfWeek(skedRTVAdjustmentAnalysisResult analysisResult, sked_Role_Time_Variance__c rtv, sked_Role_Time_Variance__c oldRtv) {
        List<String> newRtvDaysOfWeek = rtv.sked_Days_Of_Week__c.split(';');
        List<String> daysOfWeekToModify = new List<String>();
        for (String newDayOfWeek : newRtvDaysOfWeek) {
            if (oldRtv.sked_Days_Of_Week__c.contains(newDayOfWeek)) {
                daysOfWeekToModify.add(newDayOfWeek);
            }
        }

        if (daysOfWeekToModify.size() > 0) {
            analysisResult.daysOfWeekToModify = String.join(daysOfWeekToModify, ';');
        }
    }

    private static Integer getAmountForCalculate(Decimal amount, String bufferType) {
        return bufferType == skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD ? Integer.valueOf(amount) : Integer.valueOf(amount) * -1;
    }

    private class skedRTVAdjustmentAnalysisResult {
        public Date startDateToMofify;
        public Date endDateToModify;
        public String affectedFieldsToModify;
        public String resourceRoleGroupsToModify;
        public String daysOfWeekToModify;
        public List<skedRoleTimeVarianceAdjustment> adjustments;

        public skedRTVAdjustmentAnalysisResult() {
            this.adjustments = new List<skedRoleTimeVarianceAdjustment>();
        }
    }
}