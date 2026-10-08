import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { DateTime } from 'c/luxon';
import { cloneDeep, isEqual } from 'c/lodash';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { DRIVE_STATUS } from 'c/slwcConstants';
import {
	userService,
	collectionOperationSlotConfigService,
	collectionOperationSlotConfigQueryModel,
	slotConfigurationDefaultService,
	slotConfigurationDefaultQueryModel,
	driveService,
	driveQueryModel
} from 'c/dataService';

const driveHelper = new DriveHelper();

// Mirrors skedCreateDCRForSlotConfigChangeBatch's own drive query (sked_Status__c != Cancel/Complete) —
// keep in sync with that class's WHERE clause, not re-derived independently.
const NON_TERMINAL_DRIVE_STATUSES = Object.values(DRIVE_STATUS).filter(
	(status) => status !== DRIVE_STATUS.CANCEL && status !== DRIVE_STATUS.COMPLETE
);

const PROCEDURE_TYPE = {
	WHOLE_BLOOD: 'Whole Blood',
	POWER_RED: 'Power Red'
};

const ADMIN_PROFILES = ['System Administrator', 'Global Admin'];

// skedSlotConfigHandler persists a blank Effective End Date as this sentinel (skedDateTimeUtils.MAX_DATE) —
// normalized back to null on read so open-ended rows keep working with the existing sort/history/continuity logic.
const MAX_DATE_STR = '4000-12-31';

const WHOLE_BLOOD_SLOT_DURATION_OPTIONS = [5, 6, 10, 12, 15, 20, 30, 60].map((minutes) => ({
	label: `${minutes}-min`,
	value: String(minutes)
}));

const POWER_RED_ROUND_INTERVAL_OPTIONS = [10, 20, 30, 40, 50, 60].map((minutes) => ({
	label: `${minutes}-min`,
	value: String(minutes)
}));

function formatMinuteOffset(minutes) {
	return `:${String(minutes % 60).padStart(2, '0')}`;
}

// Single source of truth for everything that varies by procedure type — adding a third procedure
// or wiring T8's configOverride through means extending this map, not hunting across the file.
//
// buildSavedConfig matches WBConfiguration/generate2rbcSlots() byte-for-byte only for today's one
// reachable value per procedure (Whole Blood slotDuration=15, Power Red roundInterval=60) —
// baseGenerator.js still hardcodes groupInterval/slotDuration regardless of roundInterval until T8
// wires configOverride through, so any other Power Red picklist value previews T8's future
// behavior, not today's.
const PROCEDURE_STRATEGY = {
	[PROCEDURE_TYPE.WHOLE_BLOOD]: {
		field: 'slotDuration',
		fieldLabel: 'Slot Duration',
		options: WHOLE_BLOOD_SLOT_DURATION_OPTIONS,
		defaultConfig: { slotDuration: 15 },
		buildFormConfig: (form) => ({ slotDuration: form.slotDuration }),
		buildSavedConfig: (config) => config,
		summarize: (config) => {
			const derived = driveHelper.deriveWholeBloodRoundConfig(config.slotDuration);
			const fillOrder = derived.roundConfigurations.map((r) => formatMinuteOffset(r.minutesIntoStart)).join(', ');
			return `${derived.interval}-min interval · ${derived.numberOfRounds} rounds/hr · fills ${fillOrder}`;
		}
	},
	[PROCEDURE_TYPE.POWER_RED]: {
		field: 'roundInterval',
		fieldLabel: 'Round Interval',
		options: POWER_RED_ROUND_INTERVAL_OPTIONS,
		defaultConfig: { roundInterval: 60 },
		buildFormConfig: (form) => ({ roundInterval: form.roundInterval }),
		buildSavedConfig: (config) => driveHelper.derivePowerRedRoundConfig(config.roundInterval),
		summarize: (config) => {
			const derived = driveHelper.derivePowerRedRoundConfig(config.roundInterval);
			return `${derived.roundInterval}-min round · ${derived.numberOfGroups} group(s) × ${derived.groupInterval} min · ${derived.slotDuration}-min slots`;
		}
	}
};

const SECTION_DEFS = [
	{ key: 'mobile_wb', title: 'Mobile — Whole Blood', driveType: 'Mobile', fixedSiteOperationType: null, procedureType: PROCEDURE_TYPE.WHOLE_BLOOD },
	{ key: 'mobile_pr', title: 'Mobile — Power Red', driveType: 'Mobile', fixedSiteOperationType: null, procedureType: PROCEDURE_TYPE.POWER_RED },
	{ key: 'wbfs_wb', title: 'WB Fixed Site — Whole Blood', driveType: 'Fixed Site', fixedSiteOperationType: 'Non Integrated WB', procedureType: PROCEDURE_TYPE.WHOLE_BLOOD },
	{ key: 'wbfs_pr', title: 'WB Fixed Site — Power Red', driveType: 'Fixed Site', fixedSiteOperationType: 'Non Integrated WB', procedureType: PROCEDURE_TYPE.POWER_RED }
];

const NUMERIC_FORM_FIELDS = ['slotDuration', 'roundInterval'];
const OPEN_ENDED_BLOCK_MESSAGE = 'This configuration is open-ended. Please set an End Date before adding a new row.';
const START_DATE_IMMUTABLE_MESSAGE = 'Effective Start Date cannot be changed once the configuration has taken effect.';

function normalizeEndDate(value) {
	return value === MAX_DATE_STR ? null : value;
}

function collapseConfigForRead(procedureType, jsonString) {
	if (!jsonString) {
		return null;
	}
	let parsed;
	try {
		parsed = JSON.parse(jsonString);
	} catch (e) {
		return null;
	}
	const field = PROCEDURE_STRATEGY[procedureType].field;
	return { [field]: parsed[field] };
}

function isTempRowId(id) {
	return typeof id === 'string' && id.startsWith('new-');
}

function formatConfigSummary(procedureType, config) {
	return PROCEDURE_STRATEGY[procedureType].summarize(config);
}

// DateTime.local() (not new Date().toISOString(), which is UTC) — a UTC "today" runs up to a day
// ahead of the admin's actual calendar date depending on timezone, matching the c/luxon-based
// local-date pattern already used by slwcPlanDriveCalendar.js/slwcRecurrenceDatesPicker.js.
function getTodayDateString() {
	return DateTime.local().toISODate();
}

function addDaysToDateString(dateString, days) {
	return DateTime.fromISO(dateString).plus({ days }).toISODate();
}

function compareRowsDescendingByEndDate(a, b) {
	if (!a.endDate && !b.endDate) return 0;
	if (!a.endDate) return -1;
	if (!b.endDate) return 1;
	return b.endDate.localeCompare(a.endDate);
}

function getLatestRow(rows) {
	if (!rows || !rows.length) return null;
	return [...rows].sort(compareRowsDescendingByEndDate)[0];
}

// Scans every adjacent pair and never stops early — an earlier gap must not hide a later real
// overlap, since only 'overlap' may block Confirm & Apply (server only rejects overlap; 'gap' is
// an intentional, allowed state that falls through to the org default and is surfaced as
// information, not an error). An open-ended row followed by another is classified as an overlap
// — its effective end is unbounded, so anything after it always overlaps.
function findContinuityIssues(rows) {
	const sorted = [...rows].sort((a, b) => a.startDate.localeCompare(b.startDate));
	const issues = [];
	for (let i = 0; i < sorted.length - 1; i++) {
		const current = sorted[i];
		const next = sorted[i + 1];
		if (!current.endDate) {
			issues.push({ type: 'overlap', current, next });
			continue;
		}
		const expectedNextStart = addDaysToDateString(current.endDate, 1);
		if (expectedNextStart < next.startDate) {
			issues.push({ type: 'gap', current, next });
		} else if (expectedNextStart > next.startDate) {
			issues.push({ type: 'overlap', current, next });
		}
	}
	return issues;
}

export default class SlwcCollectionOperationSlotConfig extends LightningElement {
	@api recordId;

	isLoading = false;
	profileName = null;
	originalSections = [];
	draftSections = [];
	displaySections = [];
	isReviewModalOpen = false;
	isSaving = false;
	sectionShowHistory = {};
	sectionAffectedDriveCounts = {};
	isLoadingAffectedDriveCounts = false;
	affectedDriveCountLoadFailed = false;

	rowModal = {
		isOpen: false,
		sectionKey: null,
		rowId: null,
		procedureType: null,
		form: {},
		error: '',
		blocked: false,
		blockMessage: '',
		startDateReadOnly: false,
		isActiveRecord: false
	};

	slotDurationOptions = WHOLE_BLOOD_SLOT_DURATION_OPTIONS;
	roundIntervalOptions = POWER_RED_ROUND_INTERVAL_OPTIONS;

	get hasEditPermission() {
		return ADMIN_PROFILES.includes(this.profileName);
	}

	get placeholderRowColspan() {
		return this.hasEditPermission ? '4' : '3';
	}

	get rowModalTitle() {
		return this.rowModal.rowId ? 'Edit Configuration Row' : 'Add Configuration Row';
	}

	get isRowModalWholeBlood() {
		return this.rowModal.procedureType === PROCEDURE_TYPE.WHOLE_BLOOD;
	}

	get slotDurationValue() {
		return this.rowModal.form.slotDuration ? String(this.rowModal.form.slotDuration) : '';
	}

	get roundIntervalValue() {
		return this.rowModal.form.roundInterval ? String(this.rowModal.form.roundInterval) : '';
	}

	get rowModalMinEndDate() {
		if (!this.rowModal.form.startDate) {
			return null;
		}
		const minAfterStart = addDaysToDateString(this.rowModal.form.startDate, 1);
		const today = getTodayDateString();
		return this.rowModal.isActiveRecord && today > minAfterStart ? today : minAfterStart;
	}

	get wbLivePreview() {
		if (!this.isRowModalWholeBlood || !this.rowModal.form.slotDuration) {
			return '';
		}
		return formatConfigSummary(PROCEDURE_TYPE.WHOLE_BLOOD, { slotDuration: this.rowModal.form.slotDuration });
	}

	// Continuity (gap/overlap) and Start-Date lock checks live here. Row-field checks
	// (validateRowForm) run separately, on Save Row.
	// Warning only — the real block happens at Review & Apply (see reviewOverlapIssues).
	get rowModalContinuityWarning() {
		if (this.rowModal.blocked || !this.rowModal.form.startDate) {
			return '';
		}
		const section = this.draftSections.find((s) => s.key === this.rowModal.sectionKey);
		if (!section) {
			return '';
		}
		const otherRows = section.rows
			.filter((r) => r.id !== this.rowModal.rowId)
			.map((r) => ({ startDate: r.startDate, endDate: r.endDate }));
		const currentRow = { startDate: this.rowModal.form.startDate, endDate: this.rowModal.form.endDate || null, isCurrent: true };
		const relevantIssue = findContinuityIssues([...otherRows, currentRow]).find(
			(issue) => issue.current.isCurrent || issue.next.isCurrent
		);
		return relevantIssue ? this.describeContinuityIssue(relevantIssue, section) : '';
	}

	// Scoped to pairs where at least one row changed — the server can only reject an overlap
	// touching a record in the save transaction, so a stale overlap between two untouched rows
	// must never block Confirm & Apply.
	// isChanged only exists on displaySections rows (refreshDisplaySections diffs against
	// originalSections) — draftSections rows don't carry it, hence the lookup below.
	get reviewContinuityFindings() {
		const changedRowIds = new Set();
		this.displaySections.forEach((section) => {
			section.rows.forEach((row) => {
				if (row.isChanged) {
					changedRowIds.add(row.id);
				}
			});
		});
		const findings = [];
		this.draftSections.forEach((section) => {
			findContinuityIssues(section.rows)
				.filter((issue) => changedRowIds.has(issue.current.id) || changedRowIds.has(issue.next.id))
				.forEach((issue) => {
					findings.push({
						id: `${section.key}|${issue.current.startDate}|${issue.next.startDate}`,
						title: section.title,
						type: issue.type,
						message: this.describeContinuityIssue(issue, section)
					});
				});
		});
		return findings;
	}

	get reviewOverlapIssues() {
		return this.reviewContinuityFindings.filter((entry) => entry.type === 'overlap');
	}

	get hasReviewOverlapIssues() {
		return this.reviewOverlapIssues.length > 0;
	}

	get reviewGapNotices() {
		return this.reviewContinuityFindings.filter((entry) => entry.type === 'gap');
	}

	get hasReviewGapNotices() {
		return this.reviewGapNotices.length > 0;
	}

	get rowModalStartDateLockedMessage() {
		return this.rowModal.rowId && this.rowModal.startDateReadOnly ? START_DATE_IMMUTABLE_MESSAGE : '';
	}

	describeContinuityIssue(issue, section) {
		if (issue.type === 'overlap') {
			if (!issue.current.endDate) {
				return `The row starting ${issue.current.startDate} is open-ended but is followed by another row — only the latest row may be open-ended.`;
			}
			return `This would leave an overlap between ${issue.current.startDate} – ${issue.current.endDate} and the row starting ${issue.next.startDate}.`;
		}
		const fallback = section.orgDefaultConfig
			? `drives in that window will use the org-wide default: ${formatConfigSummary(section.procedureType, section.orgDefaultConfig)}`
			: 'no org-wide default is configured, so drives in that window will have no slot configuration';
		return `There is a gap between ${issue.current.startDate} – ${issue.current.endDate} and the row starting ${issue.next.startDate} — ${fallback}.`;
	}

	get pendingChanges() {
		const changes = [];
		this.displaySections.forEach((section) => {
			section.rows.forEach((row) => {
				if (row.isChanged) {
					changes.push({
						id: `${section.key}-${row.id}`,
						description: `[${row.changeLabel}] ${section.title}: ${row.startDateDisplay} – ${row.endDateDisplay} — ${row.summary}`
					});
				}
			});
		});
		return changes;
	}

	get hasPendingChanges() {
		return this.pendingChanges.length > 0;
	}

	get disableReviewButton() {
		return !this.hasPendingChanges;
	}

	get disableConfirmApply() {
		return (
			!this.hasPendingChanges ||
			this.isSaving ||
			this.isLoadingAffectedDriveCounts ||
			this.affectedDriveCountLoadFailed ||
			this.hasReviewOverlapIssues
		);
	}

	get hasWholeBloodChange() {
		return this.displaySections.some(
			(section) => section.procedureType === PROCEDURE_TYPE.WHOLE_BLOOD && section.rows.some((row) => row.isChanged)
		);
	}

	connectedCallback() {
		this.loadData();
	}

	loadData() {
		this.isLoading = true;

		const slotConfigQuery = new collectionOperationSlotConfigQueryModel();
		slotConfigQuery.collectionOperationId = this.recordId;

		return Promise.all([
			new userService().getLoginUser(),
			new collectionOperationSlotConfigService().query(slotConfigQuery),
			new slotConfigurationDefaultService().query(new slotConfigurationDefaultQueryModel())
		])
			.then(([loginUserResult, overrideRows, defaultRows]) => {
				this.profileName = loginUserResult && loginUserResult.returnedData ? loginUserResult.returnedData.profileName : null;
				this.originalSections = this.buildSectionsFromRecords(overrideRows, defaultRows);
				this.draftSections = cloneDeep(this.originalSections);
				this.refreshDisplaySections();
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error',
						message: 'Failed to load Slot Configuration: ' + (error.message || 'Unknown error'),
						variant: 'error'
					})
				);
			})
			.finally(() => {
				this.isLoading = false;
			});
	}

	buildSectionsFromRecords(overrideRows, defaultRows) {
		return SECTION_DEFS.map((def) => {
			const matchesDef = (row) =>
				row.driveType === def.driveType &&
				(row.fixedSiteOperationType || null) === def.fixedSiteOperationType &&
				row.procedureType === def.procedureType;

			const matchingRows = overrideRows.filter(matchesDef);
			const orgDefaultRow = defaultRows.find(matchesDef);
			const orgDefaultConfig = orgDefaultRow ? collapseConfigForRead(def.procedureType, orgDefaultRow.configurationJson) : null;

			if (!matchingRows.length) {
				return {
					...def,
					rows: [],
					orgDefaultConfig
				};
			}

			return {
				...def,
				orgDefaultConfig,
				rows: matchingRows.map((row) => ({
					id: row.id,
					startDate: row.startDate,
					endDate: normalizeEndDate(row.endDate),
					config: collapseConfigForRead(def.procedureType, row.slotConfigurationJson)
				}))
			};
		});
	}

	handleOpenAddRow(event) {
		const sectionKey = event.currentTarget.dataset.sectionKey;
		const section = this.draftSections.find((s) => s.key === sectionKey);
		const latestRow = getLatestRow(section.rows);

		if (latestRow && !latestRow.endDate) {
			this.rowModal = {
				isOpen: true,
				sectionKey,
				rowId: null,
				procedureType: section.procedureType,
				form: {},
				error: '',
				blocked: true,
				blockMessage: OPEN_ENDED_BLOCK_MESSAGE,
				startDateReadOnly: false,
				isActiveRecord: false
			};
			return;
		}

		// Prefill from the org default shown in the "Currently using org default" banner (not the generic
		// PROCEDURE_STRATEGY fallback) so a section with no rows yet doesn't silently prefill a value that
		// differs from what the admin just saw displayed above the Add Row button.
		const prefillConfig = !latestRow && section.orgDefaultConfig ? section.orgDefaultConfig : PROCEDURE_STRATEGY[section.procedureType].defaultConfig;
		this.rowModal = {
			isOpen: true,
			sectionKey,
			rowId: null,
			procedureType: section.procedureType,
			form: {
				startDate: latestRow ? addDaysToDateString(latestRow.endDate, 1) : getTodayDateString(),
				endDate: null,
				...cloneDeep(prefillConfig)
			},
			error: '',
			blocked: false,
			blockMessage: '',
			startDateReadOnly: Boolean(latestRow),
			isActiveRecord: false
		};
	}

	handleOpenEditRow(event) {
		const { sectionKey, rowId } = event.currentTarget.dataset;
		const section = this.draftSections.find((s) => s.key === sectionKey);
		const row = section.rows.find((r) => r.id === rowId);
		const originalSection = this.originalSections.find((s) => s.key === sectionKey);
		const originalRow = originalSection && originalSection.rows.find((r) => r.id === rowId);
		const today = getTodayDateString();
		this.rowModal = {
			isOpen: true,
			sectionKey,
			rowId,
			procedureType: section.procedureType,
			form: { startDate: row.startDate, endDate: row.endDate, ...cloneDeep(row.config) },
			error: '',
			blocked: false,
			blockMessage: '',
			// Locked against the persisted Start Date, not the draft one — an unsaved edit must
			// never lock itself out of further editing.
			startDateReadOnly: Boolean(originalRow) && originalRow.startDate <= today,
			isActiveRecord: row.startDate <= today && (!row.endDate || row.endDate >= today)
		};
	}

	handleRowFieldChange(event) {
		const field = event.target.dataset.field;
		const raw = event.detail.value;
		this.rowModal = {
			...this.rowModal,
			form: {
				...this.rowModal.form,
				[field]: NUMERIC_FORM_FIELDS.includes(field) ? Number(raw) : raw || null
			}
		};
	}

	handleCancelRowModal() {
		this.rowModal = { ...this.rowModal, isOpen: false, blocked: false, startDateReadOnly: false, isActiveRecord: false, form: {} };
	}

	handleSaveRow() {
		const form = this.rowModal.form;
		const error = this.validateRowForm(form);
		if (error) {
			this.rowModal = { ...this.rowModal, error };
			return;
		}

		const config = PROCEDURE_STRATEGY[this.rowModal.procedureType].buildFormConfig(form);

		this.draftSections = this.draftSections.map((section) => {
			if (section.key !== this.rowModal.sectionKey) {
				return section;
			}
			if (this.rowModal.rowId) {
				return {
					...section,
					rows: section.rows.map((r) =>
						r.id === this.rowModal.rowId ? { ...r, startDate: form.startDate, endDate: form.endDate || null, config } : r
					)
				};
			}
			return {
				...section,
				rows: [...section.rows, { id: `new-${crypto.randomUUID()}`, startDate: form.startDate, endDate: form.endDate || null, config }]
			};
		});

		this.rowModal = { ...this.rowModal, isOpen: false };
		this.refreshDisplaySections();
	}

	validateRowForm(form) {
		if (!form.startDate) {
			return 'Start Date is required.';
		}
		if (form.endDate && form.endDate <= form.startDate) {
			return 'End Date must be blank (open-ended) or later than Start Date.';
		}
		if (this.rowModal.isActiveRecord && form.endDate && form.endDate < getTodayDateString()) {
			return 'End Date cannot be in the past for the currently active configuration.';
		}

		const strategy = PROCEDURE_STRATEGY[this.rowModal.procedureType];
		const isValidValue = strategy.options.some((opt) => Number(opt.value) === form[strategy.field]);
		return isValidValue ? '' : `${strategy.fieldLabel} must be one of the listed options.`;
	}

	handleOpenReviewModal() {
		this.isReviewModalOpen = true;
		this.loadAffectedDriveCounts();
	}

	handleCancelReviewModal() {
		if (this.isSaving) {
			return;
		}
		this.isReviewModalOpen = false;
	}

	// Query key mirrors skedCreateDCRForSlotConfigChangeBatch.appliesToDrive() exactly (CO + Drive
	// Type + Fixed-Site-Operation-Type + effective date range, no Procedure Type filter) — counts
	// here must match what that batch will actually flag after save, or the confirm number lies.
	countDrivesForRow(section, row) {
		const queryModel = new driveQueryModel();
		queryModel.collectionOpId = this.recordId;
		queryModel.eventTypes = [section.driveType];
		if (section.fixedSiteOperationType) {
			queryModel.operationTypes = [section.fixedSiteOperationType];
		}
		queryModel.startDate = row.startDate;
		if (row.endDate) {
			queryModel.endDate = row.endDate;
		}
		queryModel.statuses = NON_TERMINAL_DRIVE_STATUSES;

		return new driveService().query(queryModel).then((drives) => (drives || []).length);
	}

	// Per-section counts, never summed into one total — a drive touched by 2 sections sharing the
	// same Drive Type (e.g. Mobile x WB and Mobile x Power Red edited together) is the same physical
	// drive under both, since the batch's matching key doesn't distinguish Procedure Type. Rows
	// within one section are safe to sum: overlap is server-rejected, so their date ranges never
	// overlap and no drive is double-counted within a section.
	loadAffectedDriveCounts() {
		// isChanged only exists on displaySections rows (computed in refreshDisplaySections() by
		// diffing against originalSections) — draftSections rows never carry it, so filtering
		// draftSections here always returns nothing.
		const sectionsWithChanges = this.displaySections.filter((section) => section.rows.some((row) => row.isChanged));

		if (!sectionsWithChanges.length) {
			this.sectionAffectedDriveCounts = {};
			this.affectedDriveCountLoadFailed = false;
			this.refreshDisplaySections();
			return Promise.resolve();
		}

		this.isLoadingAffectedDriveCounts = true;
		this.affectedDriveCountLoadFailed = false;
		return Promise.all(
			sectionsWithChanges.map((section) => {
				const changedRows = section.rows.filter((row) => row.isChanged);
				return Promise.all(changedRows.map((row) => this.countDrivesForRow(section, row))).then((counts) =>
					counts.reduce((total, count) => total + count, 0)
				);
			})
		)
			.then((totals) => {
				const counts = {};
				sectionsWithChanges.forEach((section, index) => {
					counts[section.key] = totals[index];
				});
				this.sectionAffectedDriveCounts = counts;
				this.refreshDisplaySections();
			})
			.catch((error) => {
				this.affectedDriveCountLoadFailed = true;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error',
						message: 'Failed to load affected-drive counts: ' + (error.message || 'Unknown error'),
						variant: 'error'
					})
				);
			})
			.finally(() => {
				this.isLoadingAffectedDriveCounts = false;
			});
	}

	handleRetryAffectedDriveCounts() {
		this.loadAffectedDriveCounts();
	}

	handleConfirmApply() {
		const models = this.buildSaveModels();

		this.isSaving = true;
		new collectionOperationSlotConfigService()
			.saveList(models)
			.then(() => {
				this.isReviewModalOpen = false;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Saved',
						message: 'Slot Configuration updated.',
						variant: 'success'
					})
				);
				return this.loadData();
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error',
						message: 'Failed to save Slot Configuration: ' + (error.message || 'Unknown error'),
						variant: 'error'
					})
				);
			})
			.finally(() => {
				this.isSaving = false;
			});
	}

	buildSaveModels() {
		const models = [];
		this.displaySections.forEach((section) => {
			section.rows.forEach((row) => {
				if (row.isChanged) {
					models.push(this.buildRowModel(section, row));
				}
			});
		});
		return models;
	}

	buildRowModel(section, row) {
		const config = PROCEDURE_STRATEGY[section.procedureType].buildSavedConfig(row.config);

		const model = {
			collectionOperationId: this.recordId,
			driveType: section.driveType,
			fixedSiteOperationType: section.fixedSiteOperationType,
			procedureType: section.procedureType,
			startDate: row.startDate,
			endDate: row.endDate || MAX_DATE_STR,
			slotConfigurationJson: JSON.stringify(config)
		};

		if (row.id && !isTempRowId(row.id)) {
			model.id = row.id;
		}

		return model;
	}

	handleToggleHistory(event) {
		const sectionKey = event.currentTarget.dataset.sectionKey;
		this.sectionShowHistory = { ...this.sectionShowHistory, [sectionKey]: !this.sectionShowHistory[sectionKey] };
		this.refreshDisplaySections();
	}

	refreshDisplaySections() {
		const today = getTodayDateString();
		this.displaySections = this.draftSections.map((section) => {
			const originalSection = this.originalSections.find((s) => s.key === section.key);
			const originalRowsById = new Map((originalSection ? originalSection.rows : []).map((r) => [r.id, r]));
			const rows = [...section.rows].sort(compareRowsDescendingByEndDate).map((row) => {
				const originalRow = originalRowsById.get(row.id);
				let changeLabel = null;
				if (!originalRow) {
					changeLabel = 'New';
				} else if (!isEqual(row, originalRow)) {
					changeLabel = 'Edited';
				}
				const isHistory = Boolean(row.endDate) && row.endDate < today;
				const isFuture = row.startDate > today;
				const statusLabel = isHistory ? null : isFuture ? 'Upcoming' : 'Active';
				const statusBadgeClass = `slds-m-left_x-small ${isFuture ? 'slds-theme_info' : 'slds-theme_success'}`;
				return {
					...row,
					startDateDisplay: row.startDate,
					endDateDisplay: row.endDate || 'Open-ended',
					summary: row.config ? formatConfigSummary(section.procedureType, row.config) : '(invalid configuration)',
					isChanged: Boolean(changeLabel),
					changeLabel,
					isHistory,
					statusLabel,
					statusBadgeClass,
					rowClass: isHistory ? 'slds-text-color_weak' : '',
					// Opacity dim, not slds-is-disabled — that class sets pointer-events:none, which would
					// also block the Edit action still available on history rows.
					rowStyle: isHistory ? 'opacity: 0.55;' : ''
				};
			});

			const historyRows = rows.filter((row) => row.isHistory);
			const showHistory = Boolean(this.sectionShowHistory[section.key]);
			// A changed history row must never be hidden from Review & Apply — collapsing it here
			// would let "Confirm & Apply" commit an edit the admin was never shown (hasPendingChanges
			// below iterates the full `rows`, not `displayRows`, so it would stay enabled regardless).
			const displayRows = showHistory ? rows : rows.filter((row) => !row.isHistory || row.isChanged);
			const affectedDriveCount = this.sectionAffectedDriveCounts[section.key];

			// Requires an actual org default to fall back to — with none configured, "No configuration
			// rows yet." (below) is the message for an empty section instead.
			const isOrgDefault = Boolean(section.orgDefaultConfig) && !rows.some((row) => row.startDate <= today && (!row.endDate || row.endDate >= today));
			// The soonest future row, if any — getLatestRow sorts by end date (wrong axis here), so
			// this needs its own earliest-by-start-date pick rather than reusing that helper.
			const nextRow = isOrgDefault
				? rows.filter((row) => row.startDate > today).sort((a, b) => a.startDate.localeCompare(b.startDate))[0] || null
				: null;

			return {
				...section,
				rows,
				displayRows,
				isEmpty: rows.length === 0,
				allHidden: rows.length > 0 && displayRows.length === 0,
				hasHistory: historyRows.length > 0,
				showHistory,
				historyToggleLabel: showHistory ? 'Hide History' : 'Show History',
				isOrgDefault,
				orgDefaultSummary:
					isOrgDefault && section.orgDefaultConfig
						? formatConfigSummary(section.procedureType, section.orgDefaultConfig) + (nextRow ? ` (until ${nextRow.startDate})` : '')
						: null,
				affectedDriveCount,
				hasAffectedDriveCount: affectedDriveCount !== undefined
			};
		});
	}
}
