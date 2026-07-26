import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { IconComponent } from '../../shared/icon/icon.component';
import { AvatarComponent } from '../../shared/ui/avatar/avatar.component';
import { AuthService } from '../../core/auth/auth.service';

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [TranslateModule, IconComponent, AvatarComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <header class="topbar">
      <div class="topbar-left">
        <button
          type="button"
          class="topbar-burger"
          (click)="toggleMobile.emit()"
          [attr.aria-label]="(mobileOpen() ? 'topbar.closeMenu' : 'topbar.openMenu') | translate"
        >
          <app-icon [name]="mobileOpen() ? 'close' : 'sliders'" [size]="18" />
        </button>

        <img class="topbar-crest" src="/saf-crest.png" alt="SAF" width="32" height="32" />
        <div class="topbar-name">
          <span class="topbar-name-1">{{ 'common.appTitle' | translate }}</span>
          <span class="topbar-name-2">{{ 'common.appSubtitle' | translate }}</span>
        </div>
      </div>

      <div class="topbar-right">
        <button
          type="button"
          class="icon-btn"
          [attr.aria-label]="'topbar.notifications' | translate"
        >
          <app-icon name="bell" [size]="16" />
        </button>

        <div class="topbar-user">
          <app-avatar [initials]="initials()" />
          <div class="topbar-user-text">
            <span class="topbar-user-name">{{ displayName() }}</span>
            <span class="topbar-user-role">{{ 'topbar.roleAdmin' | translate }}</span>
          </div>
          <button
            type="button"
            class="topbar-signout"
            (click)="signOut.emit()"
            [attr.aria-label]="'topbar.signOut' | translate"
            [title]="'topbar.signOut' | translate"
          >
            <app-icon name="exit" [size]="14" />
          </button>
        </div>
      </div>
    </header>
  `,
})
export class TopbarComponent {
  private auth = inject(AuthService);

  readonly mobileOpen = input<boolean>(false);
  readonly toggleMobile = output<void>();
  readonly signOut = output<void>();

  readonly displayName = computed(() => {
    const u = this.auth.user();
    if (!u) return '';
    if (u.displayName) return u.displayName;
    if (u.email) return u.email.split('@')[0];
    return 'Admin';
  });

  readonly initials = computed(() => {
    const name = this.displayName();
    if (!name) return 'A';
    const parts = name.split(/[.\s_-]+/).filter(Boolean);
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.slice(0, 2).toUpperCase();
  });
}
