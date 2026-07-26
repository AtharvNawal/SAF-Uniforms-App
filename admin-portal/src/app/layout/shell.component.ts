import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Router, RouterOutlet, NavigationEnd } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';

import { TopbarComponent } from './topbar/topbar.component';
import { SidebarComponent } from './sidebar/sidebar.component';
import { MobileNavComponent } from './mobile-nav/mobile-nav.component';
import { ToastHostComponent } from './toast-host/toast-host.component';
import { AuthService } from '../core/auth/auth.service';
import { ToastService } from '../core/toast/toast.service';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [
    RouterOutlet,
    TopbarComponent,
    SidebarComponent,
    MobileNavComponent,
    ToastHostComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <app-topbar
      [mobileOpen]="mobileOpen()"
      (toggleMobile)="toggleMobile()"
      (signOut)="onSignOut()"
    />

    <div class="app-body">
      <app-sidebar
        [mobileOpen]="mobileOpen()"
        (navigated)="closeMobile()"
        (signOut)="onSignOut()"
      />
      <main class="app-main">
        <div class="app-main-inner">
          <router-outlet />
        </div>
      </main>
    </div>

    <app-mobile-nav />
    <app-toast-host />
  `,
  styles: [`
    :host { display: flex; flex-direction: column; min-height: 100vh; }
  `],
})
export class ShellComponent {
  private auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);
  private t = inject(TranslateService);

  readonly mobileOpen = signal(false);

  constructor() {
    // Close the mobile sidebar whenever a route changes.
    this.router.events.subscribe((ev) => {
      if (ev instanceof NavigationEnd) this.mobileOpen.set(false);
    });
  }

  toggleMobile(): void {
    this.mobileOpen.update((v) => !v);
  }

  closeMobile(): void {
    this.mobileOpen.set(false);
  }

  async onSignOut(): Promise<void> {
    await this.auth.signOut();
    this.toast.info(this.t.instant('toast.signedOut'));
    this.router.navigate(['/login']);
  }
}
