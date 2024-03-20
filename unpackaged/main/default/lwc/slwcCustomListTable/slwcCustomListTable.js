import { LightningElement, api } from 'lwc';

import { find, uniqueId } from 'c/lodash';
export default class SlwcCustomListTable extends LightningElement {
    @api record;
    @api columns;
    get buildListRender(){
        return this.record.map(item => {
            return {
                    row: {...item},
                    key: uniqueId('row_'),
                    value: this.columns.map(column => {
                    return {
                        isText: column.type === 'text' || column.type === 'number',
                        isDrivebag: column.type === 'driveBag',
                        isAction: column.type === 'action',
                        typeAttributes: column.typeAttributes,
                        value: item[column.fieldName],
                        key: uniqueId('field_'),
                        label: column.label,
                    }
                })
            }
        })
    }
}