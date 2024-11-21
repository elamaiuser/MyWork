import { LightningElement, track, api } from "lwc";
import { uniqueId, clone } from "c/lodash";
import { classNames } from 'c/slwcUtils';

export default class SlwcTreeGrid extends LightningElement {
  _columns;

  @track _rows = [];

  @api
  get rows() {
    return this._rows;
  }

  set rows(value) {
    this._rows = value;
    this.initialize();
  }

  @api
  get columns() {
    return this._columns;
  }

  set columns(value) {
    this._columns = value;
    this.initialize();
  }

  initialize() {
    if (this._rows && this._columns) {
      this._rows = this._rows.map((row) => {
        return {
          cells: this.getCells(row),
          children: (row["_children"] || []).map((childRow) => {
            return {
              cells: this.getCells(childRow),
              ...childRow
            };
          }),
          expanded: true,
          ...row
        };
      });
    }
  }

  getCells(row) {
    return this._columns.map((column, index) => {
      return {
        id: row[column.fieldName]?.id || uniqueId(),
        fieldName: column.fieldName,
        value: row[column.fieldName] || "",
        iconName: column.cellAttributes.iconName || "",
        initialClass: row[column.cellAttributes.class?.fieldName] || "",
        class: row[column.cellAttributes.class?.fieldName] || "",
        expandable: index === 0 && row["_children"]?.length > 0,
        type: column.type
      };
    });
  }

  handleCellClick(event) {
    let selectedCellId = event.currentTarget.dataset["id"];
    let selectedRow = this.getSelectedRow(this._rows, selectedCellId);
    let selectedCell = selectedRow.cells.find(cell => cell.id === selectedCellId);

    this.setFocusCell(selectedCell, true);
    const onchangeEvent = new CustomEvent("cellclick", {
      detail: {
        row: selectedRow,
        columnName: selectedCell.fieldName
      }
    });
    this.dispatchEvent(onchangeEvent);
  }

  getSelectedRow(rows, selectedCellId) {
    if (!rows) return null;

    let selectedRow = rows.find(row => row.cells.find(cell => cell.id === selectedCellId));
    return selectedRow || rows.reduce((selectedRow, row) => selectedRow || this.getSelectedRow(row.children, selectedCellId), null);
  }

  setFocusCell(selectedCell, isSelected) {
    selectedCell.class = classNames(selectedCell.initialClass, {
       "slds-has-focus": isSelected
    });
    this._rows = clone(this._rows);

    if (isSelected) {
      setTimeout(() => this.setFocusCell(selectedCell, false), 100);
    }
  }

  toggleExpand(event) {
    let rowId = event.currentTarget.dataset["id"];
    let row = this._rows.find(row => row.id === rowId);
    row.expanded = !row.expanded;
  }
}