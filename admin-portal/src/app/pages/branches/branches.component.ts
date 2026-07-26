import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { FieldComponent } from '../../shared/ui/field/field.component';
import { InputComponent } from '../../shared/ui/input/input.component';
import { SelectComponent, SelectOption } from '../../shared/ui/select/select.component';
import { ToggleComponent } from '../../shared/ui/toggle/toggle.component';
import { CfgSectionComponent } from '../../shared/ui/cfg-section/cfg-section.component';
import { take } from 'rxjs/operators';
import { FirestoreDataService, BranchCfg } from '../../core/data/firestore-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { Branch } from '../../core/data/models';

const BRANCH_DEFAULTS: Record<Branch['id'], BranchCfg> = {
  army: { collar: 2.4, anchor: 'chest_left_f', offX: 0.0, offY: -0.5, sikh: true, sikhColor: '#2E2A28', align: 'none', version: 'v4', codes: ['No.1', 'No.2', 'No.3', 'No.4', 'No.5'] },
  navy: { collar: 1.8, anchor: 'chest_left_f', offX: 0.2, offY: -0.8, sikh: false, sikhColor: '#000000', align: 'none', version: 'v3', codes: ['No.1', 'No.2', 'No.3'] },
  rsaf: { collar: 2.0, anchor: 'chest_left_f', offX: 0.0, offY: -0.6, sikh: false, sikhColor: '#000000', align: 'none', version: 'v3', codes: ['No.1', 'No.2', 'No.3', 'No.4'] },
  dis: { collar: 2.2, anchor: 'chest_left_f', offX: 0.0, offY: -0.5, sikh: false, sikhColor: '#000000', align: 'none', version: 'v2', codes: ['No.3', 'No.4'] },
};

const ALL_CODES = ['No.1', 'No.2', 'No.3', 'No.4', 'No.5'] as const;
const ANCHORS = ['chest_left_f', 'chest_right_f', 'collar_left_f', 'collar_right_f'] as const;

@Component({
  selector: 'app-branches',
  standalone: true,
  imports: [
    FormsModule,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    FieldComponent,
    InputComponent,
    SelectComponent,
    ToggleComponent,
    CfgSectionComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'branches.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'branches.title' | translate }}</h1>
          <p class="page-sub">{{ 'branches.subtitle' | translate }}</p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="primary" (click)="saveAll()">
            <app-icon name="check" [size]="14" />
            {{ 'branches.saveAll' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="branch-grid">
        @for (b of branches(); track b.id) {
          @let cfg = configs()[b.id];
          <article class="card card-pad branch-card">
            <header
              class="branch-card-head"
              [style.borderColor]="b.color + '40'"
            >
              <div class="branch-card-tag" [style.background]="b.color"></div>
              <div>
                <div class="eyebrow" [style.color]="b.color">{{ b.short }}</div>
                <h3 class="card-title-md">{{ b.name }}</h3>
              </div>
              <app-chip>{{ cfg.version }}</app-chip>
            </header>

            <app-cfg-section [title]="'branches.section.collar' | translate">
              <app-field [label]="'branches.field.offset' | translate">
                <app-input
                  type="number"
                  [suffix]="'cm'"
                  [ngModel]="cfg.collar"
                  (ngModelChange)="patch(b.id, { collar: +$event })"
                />
              </app-field>
            </app-cfg-section>

            <app-cfg-section [title]="'branches.section.ladiesAnchor' | translate">
              <div class="form-row">
                <app-field [label]="'branches.field.anchor' | translate">
                  <app-select
                    [options]="anchorOptions"
                    [ngModel]="cfg.anchor"
                    (ngModelChange)="patch(b.id, { anchor: $event })"
                  />
                </app-field>
                <app-field [label]="'branches.field.offsetX' | translate">
                  <app-input
                    type="number"
                    [suffix]="'cm'"
                    [ngModel]="cfg.offX"
                    (ngModelChange)="patch(b.id, { offX: +$event })"
                  />
                </app-field>
                <app-field [label]="'branches.field.offsetY' | translate">
                  <app-input
                    type="number"
                    [suffix]="'cm'"
                    [ngModel]="cfg.offY"
                    (ngModelChange)="patch(b.id, { offY: +$event })"
                  />
                </app-field>
              </div>
            </app-cfg-section>

            <app-cfg-section [title]="'branches.section.sikh' | translate">
              <div class="form-row" style="align-items: flex-start;">
                <div style="flex: 1;">
                  <div class="eyebrow">{{ 'branches.field.replacesHeadgear' | translate }}</div>
                  <div style="height: 10px;"></div>
                  <app-toggle
                    [ngModel]="cfg.sikh"
                    (ngModelChange)="patch(b.id, { sikh: $event })"
                  />
                </div>
                <app-field [label]="'branches.field.colour' | translate">
                  <app-input
                    [ngModel]="cfg.sikhColor"
                    (ngModelChange)="patch(b.id, { sikhColor: $event })"
                  />
                </app-field>
                <app-field [label]="'branches.field.alignOverride' | translate">
                  <app-select
                    [options]="alignOptions()"
                    [ngModel]="cfg.align"
                    (ngModelChange)="patch(b.id, { align: $event })"
                  />
                </app-field>
              </div>
            </app-cfg-section>

            <app-cfg-section [title]="'branches.section.codes' | translate">
              <div class="pill-multiselect">
                @for (code of allCodes; track code) {
                  <button
                    type="button"
                    class="ms-pill"
                    [class.is-on]="cfg.codes.includes(code)"
                    (click)="toggleCode(b.id, code)"
                  >
                    {{ code }}
                    @if (cfg.codes.includes(code)) {
                      <app-icon name="check" [size]="11" />
                    }
                  </button>
                }
              </div>
            </app-cfg-section>

            <footer class="branch-card-foot">
              <span class="mono-tag dim">
                {{ 'branches.lastSavedFormat' | translate: { when: cfg.updatedAt ?? '—' } }}
              </span>
              <app-btn variant="ghost" (click)="saveOne(b, cfg)">
                {{ 'branches.saveOne' | translate }}
              </app-btn>
            </footer>
          </article>
        }
      </div>
    </div>
  `,
})
export class BranchesComponent {
  private svc = inject(FirestoreDataService);
  private toast = inject(ToastService);
  private t = inject(TranslateService);

  readonly branches = toSignal(this.svc.branches(), { initialValue: [] as Branch[] });
  readonly configs = signal<Record<Branch['id'], BranchCfg>>({ ...BRANCH_DEFAULTS });

  constructor() {
    this.svc.branchConfigs().pipe(take(1)).subscribe((cfgs) => {
      this.configs.update((current) => ({ ...current, ...cfgs }));
    });
  }

  readonly allCodes = ALL_CODES;

  readonly anchorOptions: SelectOption[] = ANCHORS.map((a) => ({ value: a, label: a }));

  readonly alignOptions = computed<SelectOption[]>(() => [
    { value: 'none', label: this.t.instant('branches.align.none') },
    { value: 'forward', label: this.t.instant('branches.align.forward') },
    { value: 'back', label: this.t.instant('branches.align.back') },
    { value: 'center', label: this.t.instant('branches.align.center') },
  ]);

  patch(id: Branch['id'], partial: Partial<BranchCfg>): void {
    this.configs.update((current) => ({
      ...current,
      [id]: { ...current[id], ...partial },
    }));
  }

  toggleCode(id: Branch['id'], code: string): void {
    const current = this.configs()[id];
    const has = current.codes.includes(code);
    this.patch(id, {
      codes: has ? current.codes.filter((c) => c !== code) : [...current.codes, code],
    });
  }

  async saveAll(): Promise<void> {
    const cfgs = this.configs();
    const branchIds: Branch['id'][] = ['army', 'navy', 'rsaf', 'dis'];
    try {
      await Promise.all(branchIds.map((id) => this.svc.saveBranchConfig(id, cfgs[id])));
      await this.svc.addActivityLog('Updated all branch configs', 'All branches');
      this.toast.success(
        this.t.instant('branches.toast.allSaved.title'),
        this.t.instant('branches.toast.allSaved.body'),
      );
      this.configs.update((current) => {
        const updated = { ...current };
        for (const id of branchIds) {
          updated[id] = { ...updated[id], version: `v${parseInt(updated[id].version.slice(1)) + 1}` };
        }
        return updated;
      });
    } catch {
      this.toast.show('error', this.t.instant('branches.toast.saveFailed.title'));
    }
  }

  async saveOne(b: Branch, cfg: BranchCfg): Promise<void> {
    try {
      await this.svc.saveBranchConfig(b.id, cfg);
      await this.svc.addActivityLog('Updated branch config', `Branch: ${b.name}`);
      const nextVersion = `v${parseInt(cfg.version.slice(1)) + 1}`;
      this.patch(b.id, { version: nextVersion });
      this.toast.success(
        this.t.instant('branches.toast.oneSavedFormat.title', { name: b.name }),
        this.t.instant('branches.toast.oneSavedFormat.body', { version: nextVersion }),
      );
    } catch {
      this.toast.show('error', this.t.instant('branches.toast.saveFailed.title'));
    }
  }
}
