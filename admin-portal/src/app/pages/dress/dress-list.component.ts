import {
  ChangeDetectionStrategy,
  Component,
  computed,
  HostListener,
  inject,
  signal,
} from '@angular/core';
import { UpperCasePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';

import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { Branch, Dress, DressStatus } from '../../core/data/models';

@Component({
  selector: 'app-dress-list',
  standalone: true,
  imports: [
    FormsModule,
    RouterLink,
    UpperCasePipe,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    IconBtnComponent,
    PillToggleComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dress.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'dress.title' | translate }}</h1>
          <p class="page-sub">
            {{ 'dress.subtitleFormat' | translate: { count: dresses().length } }}
          </p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="ghost">
            <app-icon name="filter" [size]="14" />
            {{ 'dress.filters' | translate }}
          </app-btn>
          <app-btn variant="primary" routerLink="/dress/add">
            <app-icon name="plus" [size]="14" />
            {{ 'dress.addDress' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="filter-bar">
        <div class="filter-group">
          <div class="eyebrow">{{ 'dress.dressCodeLabel' | translate }}</div>
          <app-pill-toggle
            [options]="codeOptions()"
            [ngModel]="codeFilter()"
            (ngModelChange)="codeFilter.set($event)"
          />
        </div>
        <div class="filter-group">
          <div class="eyebrow">{{ 'dress.statusLabel' | translate }}</div>
          <app-pill-toggle
            [options]="statusOptions()"
            [ngModel]="statusFilter()"
            (ngModelChange)="statusFilter.set($event)"
          />
        </div>
      </div>

      <div class="dress-grid">
        @for (d of filtered(); track d.id) {
          <article class="dress-card" (click)="open(d.id)">
            <div class="dress-card-top">
              <span class="dress-code-pill">{{ d.code.toUpperCase() }}</span>
              <app-chip [kind]="statusChipKind(d.status)">{{ d.status | uppercase }}</app-chip>
            </div>
            <h3 class="dress-card-title">{{ d.name }}</h3>
            <div class="dress-meta">
              <span class="meta-item">
                <app-icon name="shield" [size]="12" />
                {{ 'dress.card.overridesFormat' | translate: { n: d.overrides } }}
              </span>
              <span class="meta-item">
                <app-icon name="badge" [size]="12" />
                {{ 'dress.card.mandatoryOptionalFormat' | translate: { m: d.mandatory, o: d.optional } }}
              </span>
            </div>
            <div class="dress-card-branches">
              @for (b of branches(); track b.id) {
                <span
                  class="branch-dot"
                  [style.background]="d.branches.includes(b.id) ? b.color : 'transparent'"
                  [style.border]="d.branches.includes(b.id) ? 'none' : '1px solid var(--line-strong)'"
                ></span>
              }
              <span class="dress-card-branches-label">{{ 'dress.card.branchesLabel' | translate }}</span>
            </div>
            <footer class="dress-card-foot" (click)="$event.stopPropagation()">
              <app-btn variant="ghost" (click)="open(d.id)">
                {{ 'dress.card.view' | translate }}
              </app-btn>
              <app-btn variant="ghost" (click)="open(d.id)">
                <app-icon name="edit" [size]="12" />
                {{ 'dress.card.edit' | translate }}
              </app-btn>
              <div style="position: relative;">
                <app-icon-btn
                  [ariaLabel]="'dress.card.moreActions' | translate"
                  (click)="toggleMenu($event, d.id)"
                >
                  <app-icon name="kebab" [size]="14" />
                </app-icon-btn>
                @if (menuOpenId() === d.id) {
                  <ul class="dropdown-menu" (click)="$event.stopPropagation()">
                    <li>
                      <button class="dropdown-item" (click)="open(d.id)">
                        <app-icon name="edit" [size]="12" />
                        {{ 'dress.card.edit' | translate }}
                      </button>
                    </li>
                    <li>
                      <button
                        class="dropdown-item dropdown-item--danger"
                        (click)="handleDelete($event, d)"
                      >
                        <app-icon name="trash" [size]="12" />
                        @if (pendingDelete() === d.id) {
                          {{ 'dress.toast.deletePrompt.confirm' | translate }}
                        } @else {
                          {{ 'dress.card.menu.delete' | translate }}
                        }
                      </button>
                    </li>
                  </ul>
                }
              </div>
            </footer>
          </article>
        }

        @if (filtered().length === 0) {
          <div style="grid-column: 1 / -1;">
            <section class="empty-state">
              <div class="empty-title">{{ 'dress.empty.title' | translate }}</div>
              <p class="empty-body">{{ 'dress.empty.body' | translate }}</p>
              <div style="margin-top: 12px;">
                <app-btn variant="ghost" (click)="clearFilters()">
                  {{ 'dress.empty.clear' | translate }}
                </app-btn>
              </div>
            </section>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .dropdown-menu {
      position: absolute;
      right: 0;
      top: calc(100% + 4px);
      z-index: 200;
      min-width: 160px;
      background: var(--surface-2);
      border: 1px solid var(--line-strong);
      border-radius: 8px;
      padding: 4px;
      list-style: none;
      margin: 0;
      box-shadow: 0 8px 24px rgba(0,0,0,0.3);
    }
    .dropdown-item {
      display: flex;
      align-items: center;
      gap: 8px;
      width: 100%;
      padding: 8px 12px;
      background: none;
      border: none;
      border-radius: 6px;
      color: var(--text-primary);
      font: inherit;
      font-size: 13px;
      cursor: pointer;
      text-align: left;
    }
    .dropdown-item:hover { background: var(--surface-3); }
    .dropdown-item--danger { color: var(--err); }
    .dropdown-item--danger:hover { background: color-mix(in srgb, var(--err) 12%, transparent); }
  `],
})
export class DressListComponent {
  private svc = inject(FirestoreDataService);
  private router = inject(Router);
  private toast = inject(ToastService);
  private t = inject(TranslateService);

  readonly dresses = toSignal(this.svc.dresses(), { initialValue: [] as Dress[] });
  readonly branches = toSignal(this.svc.branches(), { initialValue: [] as Branch[] });

  readonly codeFilter = signal<string>('all');
  readonly statusFilter = signal<string>('all');
  readonly menuOpenId = signal<string | null>(null);
  readonly pendingDelete = signal<string | null>(null);

  readonly codeOptions = computed<PillToggleOption[]>(() => [
    { value: 'all', label: this.t.instant('dress.filter.all') },
    { value: 'no1', label: 'No.1' },
    { value: 'no2', label: 'No.2' },
    { value: 'no3', label: 'No.3' },
    { value: 'no4', label: 'No.4' },
    { value: 'no5', label: 'No.5' },
  ]);

  readonly statusOptions = computed<PillToggleOption[]>(() => [
    { value: 'all', label: this.t.instant('dress.filter.all') },
    { value: 'live', label: this.t.instant('dress.filter.live') },
    { value: 'placeholder', label: this.t.instant('dress.filter.placeholder') },
    { value: 'draft', label: this.t.instant('dress.filter.draft') },
  ]);

  readonly filtered = computed(() => {
    const c = this.codeFilter();
    const s = this.statusFilter();
    return this.dresses().filter((d) => {
      if (c !== 'all' && d.code.toLowerCase().replace('.', '') !== c) return false;
      if (s !== 'all' && d.status !== s) return false;
      return true;
    });
  });

  @HostListener('document:click')
  onDocumentClick(): void {
    this.menuOpenId.set(null);
    this.pendingDelete.set(null);
  }

  statusChipKind(status: DressStatus): 'gold' | 'warn' | 'default' {
    if (status === 'live') return 'gold';
    if (status === 'placeholder') return 'warn';
    return 'default';
  }

  open(id: string): void {
    this.router.navigateByUrl(`/dress/${id}`);
  }

  clearFilters(): void {
    this.codeFilter.set('all');
    this.statusFilter.set('all');
  }

  toggleMenu(ev: Event, id: string): void {
    ev.stopPropagation();
    if (this.menuOpenId() === id) {
      this.menuOpenId.set(null);
      this.pendingDelete.set(null);
    } else {
      this.menuOpenId.set(id);
      this.pendingDelete.set(null);
    }
  }

  async handleDelete(ev: Event, dress: Dress): Promise<void> {
    ev.stopPropagation();
    if (this.pendingDelete() === dress.id) {
      // Second click — confirmed delete
      try {
        this.pendingDelete.set(null);
        this.menuOpenId.set(null);
        await this.svc.deleteDress(dress.id);
        await this.svc.addActivityLog('Deleted dress requirement', dress.name);
        this.toast.success(this.t.instant('dress.toast.deleteSuccess.title'));
      } catch {
        this.toast.error(this.t.instant('dress.toast.deleteError.title'));
      }
    } else {
      // First click — show warning
      this.pendingDelete.set(dress.id);
      this.toast.warning(
        this.t.instant('dress.toast.deletePrompt.title'),
        this.t.instant('dress.toast.deletePrompt.body'),
      );
    }
  }
}
