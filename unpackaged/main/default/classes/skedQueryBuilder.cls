public class skedQueryBuilder {

    public string fromClause;
    public string orderClause;
    public integer limitRecords;
    public integer offsetRecords;
    public Set<string> fields;
    public List<string> conditions;
    public List<String> conditionGroups;
    public boolean isCountQuery;
    public boolean isGroupQuery;
    public string groupBy;
    public boolean isOrQuery;

    public skedQueryBuilder() {
        this.fields = new Set<string>();
        this.conditions = new List<string>();
        this.conditionGroups = new List<String>();
        this.isCountQuery = false;
        this.isGroupQuery = false;
        this.isOrQuery = false;
    }

    public void setIsOrQuery(Boolean value) {
        this.isOrQuery = value;
    }

    public void cleanConditions() {
        this.conditions = new List<string>();
    }

    //syntax: condition = 'Id = {0}'; value = true
    public string generateCondition(string condition, boolean value) {
        condition = condition.replace('{0}', string.valueOf(value));
        return condition;
    }

    //syntax: condition = 'Id = {0}'; value = '123456789123456789'
    public string generateCondition(string condition, string value) {
        string param = '\'' + value + '\'';
        condition = condition.replace('{0}', string.valueOf(param));
        return condition;
    }

    public string generateLikeCondition(string condition, string value) {
        string param = '\'%' + value + '%\'';
        condition = condition.replace('{0}', string.valueOf(param));
        return condition;
    }

    public string generateMSPCondition(string condition, List<String> values) {
        String joinedValues = '(';
        for (String value : values) {
            joinedValues += '\'' + value + '\', ';
        }
        joinedValues = joinedValues.removeEnd(', ');
        joinedValues += ')';

        condition = condition.replace('{0}', string.valueOf(joinedValues));
        return condition;
    }

    //syntax: condition = 'sked__Date__c >= {0}'; value = 2018-07-30
    public string generateCondition(string condition, Date value) {
        string param = Json.serialize(value).replace('"', '');
        condition = condition.replace('{0}', param);
        return condition;
    }

    //syntax: condition = 'sked__Start__c >= {0}'; value = 2018-07-30T08:00:00.000+0000
    public string generateCondition(string condition, DateTime value) {
        string param = Json.serialize(value).replace('"', '');
        condition = condition.replace('{0}', param);
        return condition;
    }

    //syntax: condition = 'ID IN {0}', values = {'123456789123456789','123456789123456789'}
    public string generateCondition(string condition, List<string> values) {
        List<string> params = new List<string>();
        for (string value : values) {
            params.add('\'' + value + '\'');
        }
        condition = condition.replace('{0}', '(' + string.join(params, ',') + ')');
        return condition;
    }

    public string generateCondition(string condition, Set<Date> values) {
        List<string> params = new List<string>();
        for (Date value : values) {
            params.add(JSON.serialize(value).replace('"', ''));
        }

        condition = condition.replace('{0}', '(' + string.join(params, ',') + ')');
        return condition;
    }

    //syntax: condition = 'ID IN {0}', values = {'123456789123456789','123456789123456789'}
    public string generateCondition(string condition, Set<Id> values) {
        List<string> params = new List<string>();
        for (string value : values) {
            params.add('\'' + value + '\'');
        }
        condition = condition.replace('{0}', '(' + string.join(params, ',') + ')');
        return condition;
    }

    //syntax: condition = 'Id = {0}'; value = true
    public void addCondition(string condition, boolean value) {
        this.conditions.add(generateCondition(condition, value));
    }

    //syntax: condition = 'Id = {0}'; value = '123456789123456789'
    public void addCondition(string condition, string value) {
        this.conditions.add(generateCondition(condition, value));
    }

    //syntax: condition = 'sked__Date__c >= {0}'; value = 2018-07-30
    public void addCondition(string condition, Date value) {
        this.conditions.add(generateCondition(condition, value));
    }

    //syntax: condition = 'sked__Start__c >= {0}'; value = 2018-07-30T08:00:00.000+0000
    public void addCondition(string condition, DateTime value) {
        this.conditions.add(generateCondition(condition, value));
    }

    //syntax: condition = 'ID IN {0}', values = {'123456789123456789','123456789123456789'}
    public void addCondition(string condition, List<string> values) {
        this.conditions.add(generateCondition(condition, values));
    }

    //syntax: condition = 'ID IN {0}', values = {'123456789123456789','123456789123456789'}
    public void addCondition(string condition, Set<Id> values) {
        this.conditions.add(generateCondition(condition, values));
    }

    public void addCondition(string condition, Set<Date> values) {
        this.conditions.add(generateCondition(condition, values));
    }

    public void addCondition(string condition) {
        if (!this.conditions.contains(condition)) {
            this.conditions.add(condition);
        }
    }

    public void addConditions(List<string> conditions) {
        for (string condition : conditions) {
            if (!this.conditions.contains(condition)) {
                this.conditions.add(condition);
            }
        }
    }

    public void addConditionGroup(List<String> conditions) {
        this.conditionGroups.add('(' + string.join(conditions, ' AND ') + ')');
    }

    public void addField(string fieldName) {
        this.fields.add(fieldName.toLowerCase());
    }

    public void addFields(List<string> fieldNames) {
        for (string fieldName : fieldNames) {
            this.fields.add(fieldName.toLowerCase());
        }
    }

    public void addFields(Set<string> fieldNames) {
        for (string fieldName : fieldNames) {
            this.fields.add(fieldName.toLowerCase());
        }
    }

    public void setFromClause(string fromClause) {
        this.fromClause = fromClause;
    }

    public override string toString() {
        string statement = 'SELECT {0} FROM {1}';
        List<String> fieldList = new List<string>();
        fieldList.addAll(this.fields);
        statement = statement.replace('{0}', string.join(fieldList, ', '));
        statement = statement.replace('{1}', this.fromClause);

        if (!this.conditionGroups.isEmpty()) {
            statement += ' WHERE ' + string.join(this.conditionGroups, this.isOrQuery ? ' OR ' : ' AND ');
        }
        if (!this.conditions.isEmpty()) {
            statement += ' WHERE ' + string.join(this.conditions, this.isOrQuery ? ' OR ' : ' AND ');
        }

        if (!this.isCountQuery) {
            if (string.isNotBlank(orderClause)) {
                statement += ' ' + orderClause;
            }
            if (limitRecords != NULL) {
                statement += ' LIMIT ' + limitRecords;
            }
            if (offsetRecords != NULL) {
                statement += ' OFFSET ' + offsetRecords;
            }
        }
        if (this.isGroupQuery) { 
            statement += ' GROUP BY ' + this.groupBy;
        }

        return statement;
    }

    public void setGroupBy(String groupBy) {
        this.isGroupQuery = true;
        this.groupBy = groupBy;
    }

}