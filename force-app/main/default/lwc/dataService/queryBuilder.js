import { isNullOrEmpty } from "c/slwcUtils";

class queryBuilder {
    fromClause;
    orderClause;
    limit;
    offset;
    fields;
    conditions;
    isCountQuery;

    constructor() {
        this.fields = [];
        this.conditions = [];
        this.isCountQuery = false;
    }

    cleanConditions() {
        this.conditions = [];
    }

    stringify(value) {
        return "'" + (isNullOrEmpty(value) ? '' : value.replaceAll('\'', '\\\'')) + "'";
    }

    generateCondition(condition) {
        let result = condition.template;
        if (condition.type) {
            switch (condition.type) {
                case 'string':
                    result = condition.template.replaceAll('{0}', this.stringify(condition.value));
                    break;
                case 'array_string':
                    let params = [];
                    condition.value.forEach((param) => {
                        params.push(this.stringify(param));
                    });
                    result = condition.template.replaceAll('{0}', "(" + params.join(",") + ")");
                    break;
                case 'array':
                    let dateParams = [];
                    condition.value.forEach((param) => {
                        dateParams.push(param);
                    });
                    result = condition.template.replaceAll('{0}', "(" + dateParams.join(",") + ")");
                    break;
                default:
                    result =  condition.template.replaceAll('{0}', condition.value);
            }
        }
        else if (condition.value) {
            result =  condition.template.replaceAll('{0}', condition.value);
        }
        return result;
    }

    addCondition(condition) {
        this.conditions.push(this.generateCondition(condition));
    }

    setConditions(conditions){
        this.conditions = conditions;
    }

    addField(field) {
        if (this.fields.indexOf(field) == -1) {
            this.fields.push(field);
        }
    }

    setFromClause(clause) {
        this.fromClause = clause;
    }

    toString() {
        let statement = 'SELECT {0} FROM {1}';

        statement = statement.replace('{0}', this.fields.join(', '));
        statement = statement.replace('{1}', this.fromClause);
        if (this.conditions && this.conditions.length > 0) {
            statement += ' WHERE ' + this.conditions.join(' AND ');
        }

        if (this.orderClause) {
            statement += ' ' + this.orderClause;
        }

        if (this.limit) {
            statement += ' LIMIT ' + this.limit;
        }

        if (this.offset) {
            statement += ' OFFSET ' + this.offset;
        }

        return statement;
    }

    toSearchText(value) {
        return '%' + value + '%';
    }
}

export default queryBuilder;