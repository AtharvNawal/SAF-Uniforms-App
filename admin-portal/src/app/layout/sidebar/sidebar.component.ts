import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import { IconComponent } from '../../shared/icon/icon.component';
import { SIDEBAR_ITEMS, SIDEBAR_FOOT, NavItem } from './sidebar-items';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, TranslateModule, IconComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <aside class="sidebar" [class.is-mobile-open]="mobileOpen()">
      <nav class="sidenav">
        <div class="sidenav-eyebrow">{{ 'nav.manage' | translate }}</div>
        <div class="sidenav-group">
          @for (item of items; track item.key) {
            <a
              class="sidenav-link"
              [routerLink]="item.route"
              routerLinkActive="is-active"
              (click)="navigated.emit()"
            >
              <span class="sidenav-active-bar"></span>
              <span class="sidenav-icon">
                <app-icon [name]="item.icon" [size]="18" />
              </span>
              <span class="sidenav-label">{{ item.labelKey | translate }}</span>
            </a>
          }
        </div>

        <div class="sidenav-spacer"></div>
        <div class="sidenav-divider"></div>

        <div class="sidenav-group">
          @for (item of foot; track item.key) {
            <a
              class="sidenav-link"
              [routerLink]="item.route"
              routerLinkActive="is-active"
              (click)="navigated.emit()"
            >
              <span class="sidenav-active-bar"></span>
              <span class="sidenav-icon">
                <app-icon [name]="item.icon" [size]="18" />
              </span>
              <span class="sidenav-label">{{ item.labelKey | translate }}</span>
            </a>
          }
          <button type="button" class="sidenav-link" (click)="signOut.emit()">
            <span class="sidenav-active-bar"></span>
            <span class="sidenav-icon"><app-icon name="exit" [size]="18" /></span>
            <span class="sidenav-label">{{ 'nav.signOut' | translate }}</span>
          </button>
        </div>
      </nav>
    </aside>
  `,
})
export class SidebarComponent {
  readonly mobileOpen = input<boolean>(false);
  readonly navigated = output<void>();
  readonly signOut = output<void>();

  readonly items: NavItem[] = SIDEBAR_ITEMS;
  readonly foot: NavItem[] = SIDEBAR_FOOT;
}
