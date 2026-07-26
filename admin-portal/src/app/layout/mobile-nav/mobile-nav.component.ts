import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import { IconComponent } from '../../shared/icon/icon.component';
import { ModalComponent } from '../../shared/ui/modal/modal.component';
import { MOBILE_PRIMARY, MOBILE_OVERFLOW, NavItem } from '../sidebar/sidebar-items';

@Component({
  selector: 'app-mobile-nav',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, TranslateModule, IconComponent, ModalComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <nav class="mobile-nav">
      @for (item of primary; track item.key) {
        <a
          class="mobile-nav-item"
          [routerLink]="item.route"
          routerLinkActive="is-active"
        >
          <app-icon [name]="item.icon" [size]="20" />
          <span>{{ item.labelKey | translate }}</span>
        </a>
      }
      <button type="button" class="mobile-nav-item" (click)="moreOpen.set(true)">
        <app-icon name="kebab" [size]="20" />
        <span>{{ 'nav.more' | translate }}</span>
      </button>
    </nav>

    <app-modal [open]="moreOpen()" [title]="'nav.more' | translate" (close)="moreOpen.set(false)">
      <div class="more-grid">
        @for (item of overflow; track item.key) {
          <button type="button" class="more-grid-btn" (click)="go(item.route)">
            <app-icon [name]="item.icon" [size]="22" />
            <span>{{ item.labelKey | translate }}</span>
          </button>
        }
      </div>
    </app-modal>
  `,
  styles: [`
    .more-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 8px;
    }
    .more-grid-btn {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 14px 12px;
      border-radius: var(--r-md);
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid var(--line);
      color: var(--ink);
      font-size: 13px;
      text-align: left;
    }
    .more-grid-btn:hover { background: rgba(255, 204, 0, 0.05); border-color: rgba(255, 204, 0, 0.2); }
  `],
})
export class MobileNavComponent {
  private router = inject(Router);

  readonly moreOpen = signal(false);
  readonly primary: NavItem[] = MOBILE_PRIMARY;
  readonly overflow: NavItem[] = MOBILE_OVERFLOW;

  go(route: string): void {
    this.moreOpen.set(false);
    this.router.navigateByUrl(route);
  }
}
