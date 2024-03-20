import { LightningElement, track, api } from 'lwc';
import { classNames } from 'c/slwcUtils';
import { userService } from 'c/dataService';

const MENU_ITEM = {
  adminSettings: 'Admin Settings',
  eventTypeSettings: 'Event Type Settings',
  exceptionSettings: 'Exception Settings',
  manageSchedules: 'Manage Schedules'
}

const MENUS = [
  {
    id: 'Administration',
    label: 'Administration',
    items: [
      // {
      //   id: MENU_ITEM.adminSettings,
      //   label: MENU_ITEM.adminSettings
      // },
      {
        id: MENU_ITEM.eventTypeSettings,
        label: MENU_ITEM.eventTypeSettings
      },
      {
        id: MENU_ITEM.exceptionSettings,
        label: MENU_ITEM.exceptionSettings
      },
      {
        id: MENU_ITEM.manageSchedules,
        label: MENU_ITEM.manageSchedules
      }
    ]
  }
]

export default class SlwcAdminConsole extends LightningElement {
  @track currentMenu = MENU_ITEM.manageSchedules;
  @track loginUser;

  get isReadonly() {
    let isAdmin = this.loginUser && this.loginUser.profileName &&
      (this.loginUser.profileName.startsWith('System Administrator') || this.loginUser.profileName.startsWith('Global Admin') || this.loginUser.profileName.startsWith('APS Admin'));
      return !isAdmin;
  }

  get MENU_ITEM() {
    return MENU_ITEM;
  }

  get menus() {
    return MENUS.map((menu) => {
      menu.items = menu.items.map((subMenu) => {
        subMenu.class = classNames({
          'slds-is-selected': subMenu.id === this.currentMenu
        });
        return subMenu;
      });
      return menu;
    })
  }

  get showEventTypeSettingsPanel() {
    return this.currentMenu === MENU_ITEM.eventTypeSettings;
  }

  get showExceptionSettingsPanel() {
    return this.currentMenu === MENU_ITEM.exceptionSettings;
  }

  get showManageSchedulePanel() {
    return this.currentMenu === MENU_ITEM.manageSchedules;
  }

  connectedCallback() {
    this.init();
  }

  init() {
    this.retrieveLoginUser();
  }

  retrieveLoginUser() {
    let service = new userService();
    return service.getLoginUser()
      .then((result) => {
        this.loginUser = result.returnedData;
      })
  }

  selectMenu(event) {
    const newMenu = event.currentTarget.dataset['value']; 
    this.currentMenu = newMenu; 
  }
}