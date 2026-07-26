import { ChangeDetectionStrategy, Component, computed, inject, OnDestroy, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { Subscription } from 'rxjs';

import { IconComponent } from '../../shared/icon/icon.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';
import { DrawerComponent } from '../../shared/ui/drawer/drawer.component';
import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { AppUser, Branch } from '../../core/data/models';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [
    FormsModule,
    TranslateModule,
    IconComponent,
    ChipComponent,
    IconBtnComponent,
    PillToggleComponent,
    DrawerComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'users.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'users.title' | translate }}</h1>
          <p class="page-sub">
            {{ 'users.subtitleFormat' | translate: { count: total() } }}
          </p>
        </div>
      </header>

      <div class="acc-toolbar">
        <div class="acc-search">
          <app-icon name="search" [size]="14" />
          <input
            class="acc-search-input"
            type="search"
            [(ngModel)]="search"
            [placeholder]="'users.searchPlaceholder' | translate"
          />
        </div>
        <div class="acc-filters">
          <app-pill-toggle [options]="branchOptions()" [(ngModel)]="branchFilter" />
          <app-pill-toggle [options]="profileOptions()" [(ngModel)]="profileFilter" />
        </div>
      </div>

      <section class="card" style="padding: 0;">
        <div class="acc-table-wrap">
          <table class="acc-table">
            <thead>
              <tr>
                <th>{{ 'users.col.uid' | translate }}</th>
                <th>{{ 'users.col.device' | translate }}</th>
                <th>{{ 'users.col.platform' | translate }}</th>
                <th>{{ 'users.col.branch' | translate }}</th>
                <th>{{ 'users.col.profile' | translate }}</th>
                <th>{{ 'users.col.lastSeen' | translate }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              @for (u of filtered(); track u.uid) {
                <tr class="acc-row" (click)="openUser(u)">
                  <td>
                    <span class="mono-tag">{{ u.uid }}</span>
                    <app-icon-btn
                      [ariaLabel]="'users.action.copyUid' | translate"
                      (click)="copyUid($event, u.uid)"
                    >
                      <app-icon name="copy" [size]="10" />
                    </app-icon-btn>
                  </td>
                  <td><span class="mono-tag dim">{{ u.dev }}</span></td>
                  <td>
                    <app-chip [kind]="u.plat === 'iOS' ? 'navy' : 'rsaf'">{{ u.plat }}</app-chip>
                  </td>
                  <td>
                    @if (branchById(u.branch); as b) {
                      <span
                        class="branch-chip"
                        [style.background]="b.base + '40'"
                        [style.borderColor]="b.color + '55'"
                        [style.color]="b.color"
                      >
                        {{ b.name }}
                      </span>
                    }
                  </td>
                  <td>
                    @if (u.complete) {
                      <span style="color: var(--ok); display: inline-flex;">
                        <app-icon name="check" [size]="14" />
                      </span>
                    } @else {
                      <span style="color: var(--err); display: inline-flex;">
                        <app-icon name="close" [size]="14" />
                      </span>
                    }
                  </td>
                  <td><span class="mono-tag dim">{{ u.seen }}</span></td>
                  <td>
                    <app-icon-btn [ariaLabel]="'users.action.open' | translate">
                      <app-icon name="chevR" [size]="12" />
                    </app-icon-btn>
                  </td>
                </tr>
              }

              @if (filtered().length === 0) {
                <tr>
                  <td colspan="7">
                    <div class="empty-state" style="padding: 28px 16px;">
                      <div class="empty-title">{{ 'users.empty.title' | translate }}</div>
                      <p class="empty-body">{{ 'users.empty.body' | translate }}</p>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </section>

      <app-drawer
        [open]="!!selected()"
        [eyebrow]="'users.drawer.eyebrow' | translate"
        [title]="selected()?.uid ?? ''"
        [sub]="selected()?.dev ?? ''"
        [closeLabel]="'users.drawer.close' | translate"
        (close)="closeUser()"
      >
        @if (selected(); as u) {
          <div class="eyebrow">{{ 'users.drawer.profileTitle' | translate }}</div>
          <div style="height: 10px;"></div>
          <div class="ro-grid">
            @for (row of drawerRows(u); track row.key) {
              <div class="ro-row">
                <span class="ro-key">{{ row.key | translate }}</span>
                <span class="ro-val">{{ row.val }}</span>
              </div>
            }
          </div>

          <div style="height: 20px;"></div>
          <div class="eyebrow">{{ 'users.drawer.statsTitle' | translate }}</div>
          <div style="height: 10px;"></div>
          <div class="ro-stats">
            <div class="ro-stat">
              <span class="ro-stat-v">{{ drawerPhotoCount() }}</span>
              <span class="ro-stat-l">{{ 'users.drawer.stat.photos' | translate }}</span>
            </div>
            <div class="ro-stat">
              <span class="ro-stat-v">—</span>
              <span class="ro-stat-l">{{ 'users.drawer.stat.models' | translate }}</span>
            </div>
            <div class="ro-stat">
              <span class="ro-stat-v">—</span>
              <span class="ro-stat-l">{{ 'users.drawer.stat.sessions' | translate }}</span>
            </div>
          </div>
        }
      </app-drawer>
    </div>
  `,
})
export class UsersComponent implements OnDestroy {
  private svc = inject(FirestoreDataService);
  private toast = inject(ToastService);
  private t = inject(TranslateService);

  readonly users = toSignal(this.svc.appUsers(), { initialValue: [] as AppUser[] });
  readonly branches = toSignal(this.svc.branches(), { initialValue: [] as Branch[] });

  readonly search = signal('');
  readonly branchFilter = signal<'all' | Branch['id']>('all');
  readonly profileFilter = signal<'all' | 'yes' | 'no'>('all');
  readonly selected = signal<AppUser | null>(null);
  readonly drawerPhotoCount = signal(0);

  private _gallerySub?: Subscription;

  readonly total = computed(() => this.users().length);

  readonly branchOptions = computed<PillToggleOption[]>(() => [
    { value: 'all', label: this.t.instant('users.filter.allBranches') },
    ...this.branches().map((b) => ({ value: b.id, label: b.short })),
  ]);

  readonly profileOptions = computed<PillToggleOption[]>(() => [
    { value: 'all', label: this.t.instant('users.filter.allProfiles') },
    { value: 'yes', label: this.t.instant('users.filter.complete') },
    { value: 'no', label: this.t.instant('users.filter.incomplete') },
  ]);

  readonly filtered = computed(() => {
    const q = this.search().toLowerCase().trim();
    const branch = this.branchFilter();
    const profile = this.profileFilter();
    return this.users().filter((u) => {
      if (q && !`${u.uid}${u.dev}`.toLowerCase().includes(q)) return false;
      if (branch !== 'all' && u.branch !== branch) return false;
      if (profile === 'yes' && !u.complete) return false;
      if (profile === 'no' && u.complete) return false;
      return true;
    });
  });

  branchById(id: Branch['id']): Branch | undefined {
    return this.branches().find((b) => b.id === id);
  }

  openUser(u: AppUser): void {
    this._gallerySub?.unsubscribe();
    this.drawerPhotoCount.set(0);
    this.selected.set(u);
    this._gallerySub = this.svc.galleryCount(u.uid).subscribe((n) => {
      this.drawerPhotoCount.set(n);
    });
  }

  closeUser(): void {
    this._gallerySub?.unsubscribe();
    this._gallerySub = undefined;
    this.drawerPhotoCount.set(0);
    this.selected.set(null);
  }

  ngOnDestroy(): void {
    this._gallerySub?.unsubscribe();
  }

  async copyUid(ev: Event, uid: string): Promise<void> {
    ev.stopPropagation();
    try {
      await navigator.clipboard.writeText(uid);
      this.toast.success(this.t.instant('users.toast.uidCopied'));
    } catch {
      /* swallow — older browsers without clipboard API */
    }
  }

  drawerRows(u: AppUser): { key: string; val: string }[] {
    const b = this.branchById(u.branch);
    return [
      { key: 'users.drawer.row.branch',          val: b?.name ?? u.branch },
      { key: 'users.drawer.row.rank',            val: u.rank ?? '—' },
      { key: 'users.drawer.row.gender',          val: u.gender ?? '—' },
      { key: 'users.drawer.row.dressCode',       val: u.dressCode ?? '—' },
      { key: 'users.drawer.row.fullName',        val: u.fullName ?? '—' },
      { key: 'users.drawer.row.vocation',        val: u.vocation ?? '—' },
      { key: 'users.drawer.row.medalRows',       val: u.medalRows?.toString() ?? '—' },
      { key: 'users.drawer.row.sikh',            val: u.isSikh === true ? 'Yes' : u.isSikh === false ? 'No' : '—' },
      { key: 'users.drawer.row.profileComplete', val: u.complete ? 'Yes' : 'No' },
    ];
  }
}
