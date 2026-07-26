import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Router } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent, IconName } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { AvatarComponent } from '../../shared/ui/avatar/avatar.component';
import { BranchDotComponent } from '../../shared/ui/branch-dot/branch-dot.component';
import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { StorageDataService } from '../../core/data/storage-data.service';
import { ToastService } from '../../core/toast/toast.service';
import {
  ActivityEntry,
  AppUser,
  Accessory,
  BodyModel,
  Branch,
  CoverageStatus,
  DressCode,
} from '../../core/data/models';

interface StatCard {
  labelKey: string;
  subKey: string;
  icon: IconName;
  value: number;
}

interface QuickAction {
  i18nKey: string;
  icon: IconName;
  external?: boolean;
  run: () => void;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    DecimalPipe,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    AvatarComponent,
    BranchDotComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dashboard.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'dashboard.title' | translate }}</h1>
          <p class="page-sub">{{ 'dashboard.subtitle' | translate }}</p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="ghost" (click)="onRefresh()">
            <app-icon name="refresh" [size]="14" />
            {{ 'dashboard.refresh' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="stat-grid">
        @for (tile of stats(); track tile.labelKey) {
          <div class="stat-card">
            <div class="stat-card-icon">
              <app-icon [name]="tile.icon" [size]="22" />
            </div>
            <div class="stat-value">{{ tile.value | number }}</div>
            <div class="stat-label">{{ tile.labelKey | translate }}</div>
            <div class="stat-sub">{{ tile.subKey | translate }}</div>
          </div>
        }
      </div>

      <div class="dash-mid">
        <section class="card card-pad">
          <header class="card-head">
            <div class="eyebrow" style="color: var(--gold);">
              {{ 'dashboard.activity.title' | translate }}
            </div>
            <button class="link-btn link-gold" type="button">
              {{ 'dashboard.activity.viewAll' | translate }}
              <app-icon name="chevR" [size]="12" />
            </button>
          </header>
          <ul class="activity-list">
            @for (row of activity(); track $index) {
              <li class="activity-row">
                <span class="activity-dot"></span>
                <app-avatar [initials]="row.who" [size]="26" />
                <div class="activity-body">
                  <span class="activity-action">{{ row.action }}</span>
                  <span class="activity-target">{{ row.target }}</span>
                </div>
                <span class="activity-time">{{ row.t }}</span>
              </li>
            }
          </ul>
        </section>

        <section class="card card-pad">
          <header class="card-head">
            <div class="eyebrow" style="color: var(--gold);">
              {{ 'dashboard.quickActions.title' | translate }}
            </div>
          </header>
          <div class="quick-actions">
            @for (qa of quickActions; track qa.i18nKey) {
              <button class="quick-action" type="button" (click)="qa.run()">
                <span class="qa-icon"><app-icon [name]="qa.icon" [size]="16" /></span>
                <span class="qa-label">{{ qa.i18nKey | translate }}</span>
                <span class="qa-arrow">
                  <app-icon [name]="qa.external ? 'ext' : 'chevR'" [size]="14" />
                </span>
              </button>
            }
          </div>
        </section>
      </div>

      <section class="card card-pad">
        <header class="card-head">
          <div>
            <div class="eyebrow" style="color: var(--gold);">
              {{ 'dashboard.coverage.eyebrow' | translate }}
            </div>
            <h3 class="card-title-lg">{{ 'dashboard.coverage.title' | translate }}</h3>
          </div>
          <div class="legend">
            <span class="legend-item">
              <span class="legend-dot legend-live"></span>
              {{ 'dashboard.coverage.legend.live' | translate }}
            </span>
            <span class="legend-item">
              <span class="legend-dot legend-placeholder"></span>
              {{ 'dashboard.coverage.legend.placeholder' | translate }}
            </span>
            <span class="legend-item">
              <span class="legend-dot legend-pending"></span>
              {{ 'dashboard.coverage.legend.pending' | translate }}
            </span>
            <span class="legend-item">
              <span class="legend-dot legend-missing"></span>
              {{ 'dashboard.coverage.legend.missing' | translate }}
            </span>
          </div>
        </header>

        <div class="coverage-table">
          <div class="coverage-row coverage-head">
            <div class="coverage-rh">{{ 'dashboard.coverage.col.branch' | translate }}</div>
            @for (code of dressCodes(); track code.id) {
              <div class="coverage-ch">{{ code.code }}</div>
            }
          </div>

          @for (b of branches(); track b.id) {
            <div class="coverage-row">
              <div class="coverage-rh">
                <app-branch-dot [color]="b.color" />
                <span>{{ b.name }}</span>
              </div>
              @for (s of coverageFor(b.id); track $index) {
                <div class="coverage-cell" [class]="'coverage-' + s">
                  <span class="coverage-cell-label">
                    {{ 'dashboard.coverage.status.' + s | translate }}
                  </span>
                </div>
              }
            </div>
          }
        </div>
      </section>
    </div>
  `,
})
export class DashboardComponent {
  private svc     = inject(FirestoreDataService);
  private storage = inject(StorageDataService);
  private router  = inject(Router);
  private toast   = inject(ToastService);
  private t       = inject(TranslateService);

  // Raw data signals
  private readonly users       = toSignal(this.svc.appUsers(),            { initialValue: [] as AppUser[] });
  private readonly accessories = toSignal(this.svc.accessories(),          { initialValue: [] as Accessory[] });
  private readonly bodyModels  = toSignal(this.storage.bodyModels(),       { initialValue: [] as BodyModel[] });
  private readonly uniformSet  = toSignal(this.storage.uniformMatrix(),    { initialValue: new Set<string>() });
  private readonly glbSet      = toSignal(this.storage.accessoryGlbSet(), { initialValue: new Set<string>() });

  readonly stats = computed<StatCard[]>(() => [
    {
      icon: 'users',
      value: this.users().length,
      labelKey: 'dashboard.stat.users.label',
      subKey:   'dashboard.stat.users.sub',
    },
    {
      icon: 'cube',
      value: this.bodyModels().length + this.uniformSet().size + this.glbSet().size,
      labelKey: 'dashboard.stat.models.label',
      subKey:   'dashboard.stat.models.sub',
    },
    {
      icon: 'uniform',
      value: this.dressCodes().length,
      labelKey: 'dashboard.stat.dressCodes.label',
      subKey:   'dashboard.stat.dressCodes.sub',
    },
    {
      icon: 'badge',
      value: this.accessories().length,
      labelKey: 'dashboard.stat.accessories.label',
      subKey:   'dashboard.stat.accessories.sub',
    },
    {
      icon: 'shield',
      value: this.branches().length,
      labelKey: 'dashboard.stat.branches.label',
      subKey:   'dashboard.stat.branches.sub',
    },
  ]);

  readonly quickActions: QuickAction[] = [
    {
      i18nKey: 'dashboard.quickActions.uploadPdf',
      icon: 'upload',
      run: () => this.router.navigateByUrl('/dress/add'),
    },
    {
      i18nKey: 'dashboard.quickActions.addAccessory',
      icon: 'plus',
      run: () => this.router.navigateByUrl('/accessories'),
    },
    {
      i18nKey: 'dashboard.quickActions.uploadBody',
      icon: 'cube',
      run: () => this.router.navigateByUrl('/models'),
    },
    {
      i18nKey: 'dashboard.quickActions.sync',
      icon: 'refresh',
      run: () =>
        this.toast.info(
          this.t.instant('dashboard.toast.syncQueued.title'),
          this.t.instant('dashboard.toast.syncQueued.body'),
        ),
    },
    {
      i18nKey: 'dashboard.quickActions.firestore',
      icon: 'ext',
      external: true,
      run: () => this.toast.info(this.t.instant('dashboard.toast.firestore.title')),
    },
  ];

  readonly activity = toSignal(this.svc.activity(), { initialValue: [] as ActivityEntry[] });
  readonly branches = toSignal(this.svc.branches(), { initialValue: [] as Branch[] });
  readonly dressCodes = toSignal(this.svc.dressCodes(), { initialValue: [] as DressCode[] });
  readonly coverage = toSignal(this.svc.coverage(), {
    initialValue: { army: [], navy: [], rsaf: [], dis: [] } as Record<Branch['id'], CoverageStatus[]>,
  });

  coverageFor(id: Branch['id']): CoverageStatus[] {
    return this.coverage()[id] ?? [];
  }

  onRefresh(): void {
    this.toast.info(
      this.t.instant('dashboard.toast.refreshing.title'),
      this.t.instant('dashboard.toast.refreshing.body'),
    );
  }
}
