@isTest
private class skedDriveShiftTagCalculator_Test {

    private static skedDriveShiftTagCandidate candidate(Id tagId, String tagName, Boolean required, Decimal minimumQuantity) {
        skedDriveShiftTagCandidate c = new skedDriveShiftTagCandidate();
        c.tagId = tagId;
        c.tagName = tagName;
        c.required = required;
        c.minimumQuantity = minimumQuantity;
        return c;
    }

    private static skedDriveShiftTagCalculator.TagResult findResultByTagId(List<skedDriveShiftTagCalculator.TagResult> results, Id tagId) {
        for (skedDriveShiftTagCalculator.TagResult result : results) {
            if (result.tagId == tagId) {
                return result;
            }
        }
        return null;
    }

    // A real, inserted sked__Tag__c - this class has no fake-Id helper, and a real Tag costs
    // nothing here since these tests never touch a Drive/Account/Location at all.
    private static Id insertTag(String name) {
        sked__Tag__c tag = new sked__Tag__c(Name = name);
        insert tag;
        return tag.Id;
    }

    @isTest
    static void testCalculateDriveShiftTags_emptyLists_returnsEmptyResult() {
        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(
            new List<skedDriveShiftTagCandidate>(), new List<skedDriveShiftTagCandidate>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'With no candidates at all, the result must be empty');
    }

    @isTest
    static void testCalculateDriveShiftTags_nonRequiredDistinctNames_bothIncluded() {
        Id accountTagId = insertTag('Account Tag Fixture');
        Id locationTagId = insertTag('Location Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Cooler', false, 2) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(locationTagId, 'Lift Gate', false, 1) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Two distinct, non-required tag names must both appear in the result');
        System.assertEquals(2, findResultByTagId(results, accountTagId).minimumQuantity, 'The account tag\'s own minimumQuantity must be preserved when there is no name collision');
        System.assertEquals(1, findResultByTagId(results, locationTagId).minimumQuantity, 'The location tag\'s own minimumQuantity must be preserved when there is no name collision');
    }

    @isTest
    static void testCalculateDriveShiftTags_requiredAccountTag_excludedFromResult() {
        Id accountTagId = insertTag('Account Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Cooler', true, 2) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, new List<skedDriveShiftTagCandidate>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'A required tag must never appear in the result - only non-required tags become sked_Drive_Shift_Tag__c candidates');
    }

    @isTest
    static void testCalculateDriveShiftTags_nonRequiredLocationTagNameCollidesWithRequiredAccountTag_excluded() {
        Id requiredAccountTagId = insertTag('Required Account Tag Fixture');
        Id nonRequiredLocationTagId = insertTag('Non-Required Location Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(requiredAccountTagId, 'Cooler', true, null) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(nonRequiredLocationTagId, 'Cooler', false, 3) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'A name required by ANY list excludes that name entirely, even for a different, unrelated, non-required tag record with the same name');
    }

    @isTest
    static void testCalculateDriveShiftTags_sameNameAccountAndLocationTag_minimumQuantityMergedByMax() {
        Id accountTagId = insertTag('Account Tag Fixture');
        Id locationTagId = insertTag('Location Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Shared Tag', false, 3) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(locationTagId, 'Shared Tag', false, 7) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Two candidates sharing a name must collapse into exactly one result entry');
        System.assertEquals(7, results[0].minimumQuantity, 'minimumQuantity must be the MAX of the two candidates (3 and 7), not a sum or last-wins');
    }

    @isTest
    static void testCalculateDriveShiftTags_sameNameAccountAndLocationTag_tagIdAlwaysComesFromTheLastProcessedCandidate() {
        Id accountTagId = insertTag('Account Tag Fixture');
        Id locationTagId = insertTag('Location Tag Fixture');
        // The account tag has the LARGER minimumQuantity, so it wins the MAX-merge - but tagId must
        // still come from the location tag, since location tags are processed after account tags.
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Shared Tag', false, 10) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(locationTagId, 'Shared Tag', false, 2) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Two candidates sharing a name must collapse into exactly one result entry');
        System.assertEquals(locationTagId, results[0].tagId, 'tagId must come from the last-processed (location) candidate even though the account candidate won the minimumQuantity merge');
        System.assertEquals(10, results[0].minimumQuantity, 'minimumQuantity must still be the MAX (10), independent of which candidate\'s tagId survives');
    }

    @isTest
    static void testCalculateDriveShiftTags_nullMinimumQuantityOnLaterCandidate_earlierRealValueWins() {
        Id accountTagId = insertTag('Account Tag Fixture');
        Id locationTagId = insertTag('Location Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Shared Tag', false, 5) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(locationTagId, 'Shared Tag', false, null) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(5, results[0].minimumQuantity, 'A null minimumQuantity must be treated as 0 for the MAX comparison, so the earlier real value (5) wins');
    }

    @isTest
    static void testCalculateDriveShiftTags_nullMinimumQuantityOnEarlierCandidate_laterRealValueWins() {
        Id accountTagId = insertTag('Account Tag Fixture');
        Id locationTagId = insertTag('Location Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Shared Tag', false, null) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(locationTagId, 'Shared Tag', false, 5) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(5, results[0].minimumQuantity, 'A null minimumQuantity on the earlier candidate must be treated as 0, so the later real value (5) wins');
    }

    @isTest
    static void testCalculateDriveShiftTags_bothMinimumQuantityNull_resultStaysNullNotZero() {
        Id accountTagId = insertTag('Account Tag Fixture');
        Id locationTagId = insertTag('Location Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(accountTagId, 'Shared Tag', false, null) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(locationTagId, 'Shared Tag', false, null) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(null, results[0].minimumQuantity, 'Two null minimumQuantity values must stay null in the result, never coerced to a literal 0');
    }

    @isTest
    static void testCalculateDriveShiftTags_bothListsNull_returnsEmptyResultInsteadOfThrowing() {
        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(null, null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'A null accountTags/locationTags list must be treated as empty (matching the JS\'s `driveTags.accountTags || []`), not throw an NPE');
    }

    @isTest
    static void testCalculateDriveShiftTags_nonRequiredAccountTagNameCollidesWithRequiredLocationTag_excluded() {
        Id requiredLocationTagId = insertTag('Required Location Tag Fixture');
        Id nonRequiredAccountTagId = insertTag('Non-Required Account Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{ candidate(nonRequiredAccountTagId, 'Cooler', false, 3) };
        List<skedDriveShiftTagCandidate> locationTags = new List<skedDriveShiftTagCandidate>{ candidate(requiredLocationTagId, 'Cooler', true, null) };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, locationTags);
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'A name required by the LOCATION list must exclude that name entirely, even for a different, unrelated, non-required ACCOUNT tag with the same name');
    }

    @isTest
    static void testCalculateDriveShiftTags_twoNonRequiredAccountTagsShareAName_mergedByMaxWithinTheSameList() {
        Id firstAccountTagId = insertTag('First Account Tag Fixture');
        Id secondAccountTagId = insertTag('Second Account Tag Fixture');
        List<skedDriveShiftTagCandidate> accountTags = new List<skedDriveShiftTagCandidate>{
            candidate(firstAccountTagId, 'Cooler', false, 2),
            candidate(secondAccountTagId, 'Cooler', false, 6)
        };

        Test.startTest();
        List<skedDriveShiftTagCalculator.TagResult> results = skedDriveShiftTagCalculator.calculateDriveShiftTags(accountTags, new List<skedDriveShiftTagCandidate>());
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Two account tags sharing a name within the SAME list must still collapse into exactly one result entry');
        System.assertEquals(6, results[0].minimumQuantity, 'minimumQuantity must be the MAX of the two same-list candidates (2 and 6), not the first or a sum');
        System.assertEquals(secondAccountTagId, results[0].tagId, 'tagId must come from the last-processed candidate even within a single list');
    }
}
