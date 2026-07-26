import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { JsonPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { BranchDotComponent } from '../../shared/ui/branch-dot/branch-dot.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import { ToastService } from '../../core/toast/toast.service';
import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { Branch } from '../../core/data/models';

@Component({
  selector: 'app-dress-review-pane',
  standalone: true,
  imports: [
    JsonPipe,
    FormsModule,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    BranchDotComponent,
    IconBtnComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="card card-pad">
      <header class="review-head">
        <div>
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dress.review.eyebrow' | translate }}
          </div>
          <h2 class="card-title-lg">{{ 'dress.review.title' | translate }}</h2>
        </div>
        @if (pdfFileName()) {
          <div class="review-head-right">
            <span class="mono-tag">{{ pdfFileName() }}</span>
            @if (pdfFileSizeLabel()) {
              <span class="muted" style="font-size: 12px;">{{ pdfFileSizeLabel() }}</span>
            }
          </div>
        }
      </header>

      <!-- Mandatory rules -->
      <div class="rule-block">
        <header class="rule-block-head">
          <div class="eyebrow">{{ 'dress.review.mandatoryTitle' | translate }}</div>
          <div class="rule-block-actions">
            <app-chip>
              {{ 'dress.review.rulesChipFormat' | translate: { n: mandatory().length } }}
            </app-chip>
            <app-btn variant="ghost" (click)="addMandatory()">
              <app-icon name="plus" [size]="12" />
              {{ 'dress.review.addRule' | translate }}
            </app-btn>
          </div>
        </header>
        <div class="rule-rows">
          @for (r of mandatory(); track $index) {
            @let idx = $index;
            <div class="rule-row">
              @if (editMandatoryIdx() === idx) {
                <input
                  class="input rule-input"
                  [ngModel]="editMandatoryVal()"
                  (ngModelChange)="editMandatoryVal.set($event)"
                  (keydown.enter)="saveMandatoryEdit(idx)"
                  (keydown.escape)="editMandatoryIdx.set(null)"
                  autofocus
                />
                <app-btn variant="ghost" (click)="saveMandatoryEdit(idx)">
                  {{ 'common.save' | translate }}
                </app-btn>
                <app-btn variant="ghost" (click)="editMandatoryIdx.set(null)">
                  {{ 'common.cancel' | translate }}
                </app-btn>
              } @else {
                <span class="rule-text mono-tag">{{ r }}</span>
                <div class="rule-row-actions">
                  <app-icon-btn ariaLabel="Edit" (click)="startMandatoryEdit(idx, r)">
                    <app-icon name="edit" [size]="12" />
                  </app-icon-btn>
                  <app-icon-btn ariaLabel="Delete" (click)="deleteMandatory(idx)">
                    <app-icon name="trash" [size]="12" />
                  </app-icon-btn>
                </div>
              }
            </div>
          }
          @if (addingMandatory()) {
            <div class="rule-row">
              <input
                class="input rule-input"
                [ngModel]="newMandatoryVal()"
                (ngModelChange)="newMandatoryVal.set($event)"
                [placeholder]="'dress.review.rulePlaceholder' | translate"
                (keydown.enter)="commitNewMandatory()"
                (keydown.escape)="addingMandatory.set(false)"
                autofocus
              />
              <app-btn variant="ghost" (click)="commitNewMandatory()">
                {{ 'common.add' | translate }}
              </app-btn>
              <app-btn variant="ghost" (click)="addingMandatory.set(false)">
                {{ 'common.cancel' | translate }}
              </app-btn>
            </div>
          }
        </div>
        @if (dressId()) {
          <div style="margin-top: 8px;">
            <app-btn variant="ghost" [disabled]="savingMandatory()" (click)="saveMandatoryToFirestore()">
              @if (savingMandatory()) { {{ 'common.loading' | translate }} }
              @else { {{ 'dress.review.saveRules' | translate }} }
            </app-btn>
          </div>
        }
      </div>

      <!-- Optional logic -->
      <div class="rule-block">
        <header class="rule-block-head">
          <div class="eyebrow">{{ 'dress.review.optionalTitle' | translate }}</div>
          <div class="rule-block-actions">
            <app-chip>
              {{ 'dress.review.rulesChipFormat' | translate: { n: optionalKeys().length } }}
            </app-chip>
            <app-btn variant="ghost" (click)="addingOptional.set(true)">
              <app-icon name="plus" [size]="12" />
              {{ 'dress.review.addRule' | translate }}
            </app-btn>
          </div>
        </header>
        <div class="rule-rows">
          @for (key of optionalKeys(); track key) {
            <div class="rule-row">
              @if (editOptionalKey() === key) {
                <span class="mono-tag" style="min-width: 120px;">{{ key }}</span>
                <input
                  class="input rule-input"
                  style="flex: 1;"
                  [ngModel]="editOptionalVal()"
                  (ngModelChange)="editOptionalVal.set($event)"
                  (keydown.enter)="saveOptionalEdit(key)"
                  (keydown.escape)="editOptionalKey.set(null)"
                  autofocus
                />
                <app-btn variant="ghost" (click)="saveOptionalEdit(key)">
                  {{ 'common.save' | translate }}
                </app-btn>
                <app-btn variant="ghost" (click)="editOptionalKey.set(null)">
                  {{ 'common.cancel' | translate }}
                </app-btn>
              } @else {
                <span class="mono-tag" style="min-width: 120px;">{{ key }}</span>
                <span class="rule-text" style="flex: 1;">{{ optional()[key] | json }}</span>
                <div class="rule-row-actions">
                  <app-icon-btn ariaLabel="Edit" (click)="startOptionalEdit(key)">
                    <app-icon name="edit" [size]="12" />
                  </app-icon-btn>
                  <app-icon-btn ariaLabel="Delete" (click)="deleteOptional(key)">
                    <app-icon name="trash" [size]="12" />
                  </app-icon-btn>
                </div>
              }
            </div>
          }
          @if (addingOptional()) {
            <div class="rule-row">
              <input
                class="input rule-input"
                style="min-width: 120px; flex: 0 0 auto;"
                [ngModel]="newOptionalKey()"
                (ngModelChange)="newOptionalKey.set($event)"
                [placeholder]="'dress.review.keyPlaceholder' | translate"
                autofocus
              />
              <input
                class="input rule-input"
                style="flex: 1;"
                [ngModel]="newOptionalVal()"
                (ngModelChange)="newOptionalVal.set($event)"
                [placeholder]="'dress.review.valuePlaceholder' | translate"
                (keydown.enter)="commitNewOptional()"
                (keydown.escape)="addingOptional.set(false)"
              />
              <app-btn variant="ghost" (click)="commitNewOptional()">
                {{ 'common.add' | translate }}
              </app-btn>
              <app-btn variant="ghost" (click)="addingOptional.set(false)">
                {{ 'common.cancel' | translate }}
              </app-btn>
            </div>
          }
        </div>
        @if (dressId()) {
          <div style="margin-top: 8px;">
            <app-btn variant="ghost" [disabled]="savingOptional()" (click)="saveOptionalToFirestore()">
              @if (savingOptional()) { {{ 'common.loading' | translate }} }
              @else { {{ 'dress.review.saveRules' | translate }} }
            </app-btn>
          </div>
        }
      </div>

      <!-- Branch overrides -->
      <div class="rule-block">
        <header class="rule-block-head">
          <div class="eyebrow">{{ 'dress.review.branchOverridesTitle' | translate }}</div>
        </header>
        @for (b of branches(); track b.id) {
          <div class="branch-acc" [class.is-open]="openBranches()[b.id]">
            <button class="branch-acc-head" type="button" (click)="toggleBranch(b.id)">
              <app-branch-dot [color]="b.color" />
              <span class="branch-acc-name">{{ b.name }}</span>
              <span class="branch-acc-chev">
                <app-icon [name]="openBranches()[b.id] ? 'chevU' : 'chevD'" [size]="14" />
              </span>
            </button>
            @if (openBranches()[b.id]) {
              <div class="branch-acc-body">
                @if (editingBranch() === b.id) {
                  @if (branchJsonError()[b.id]) {
                    <p class="warn-text" style="font-size: 12px; margin-bottom: 6px;">
                      {{ branchJsonError()[b.id] }}
                    </p>
                  }
                  <textarea
                    class="input json-textarea"
                    [ngModel]="branchJsonDraft()[b.id]"
                    (ngModelChange)="updateBranchDraft(b.id, $event)"
                    rows="8"
                  ></textarea>
                  <div class="form-actions" style="margin-top: 8px;">
                    <app-btn variant="ghost" (click)="editingBranch.set(null)">
                      {{ 'common.cancel' | translate }}
                    </app-btn>
                    <app-btn variant="ghost" [disabled]="!!branchJsonError()[b.id]" (click)="saveBranchOverride(b.id)">
                      {{ 'common.save' | translate }}
                    </app-btn>
                  </div>
                } @else {
                  <pre class="json-preview">{{ branchOverrides()[b.id] | json }}</pre>
                  <app-btn variant="ghost" (click)="startBranchEdit(b.id)">
                    <app-icon name="edit" [size]="12" />
                    {{ 'common.edit' | translate }}
                  </app-btn>
                }
              </div>
            }
          </div>
        }
      </div>

      @if (showActions()) {
        <div class="form-actions">
          <app-btn variant="ghost" (click)="back.emit()">
            {{ 'dress.review.back' | translate }}
          </app-btn>
          @if (!dressId()) {
            <app-btn variant="ghost" (click)="saveDraftEmit()">
              {{ 'dress.review.saveDraft' | translate }}
            </app-btn>
          }
          <app-btn variant="primary" (click)="continue.emit()">
            {{ 'dress.review.continue' | translate }}
          </app-btn>
        </div>
      }
    </section>
  `,
  styles: [`
    .rule-rows { display: flex; flex-direction: column; gap: 6px; margin-top: 10px; }
    .rule-row { display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 6px; background: var(--surface-3); }
    .rule-text { font-size: 13px; flex: 1; }
    .rule-input { font-size: 13px; flex: 1; min-width: 0; }
    .rule-row-actions { display: flex; gap: 4px; margin-left: auto; }
    .json-textarea { width: 100%; font-family: 'JetBrains Mono', monospace; font-size: 12px; min-height: 120px; resize: vertical; }
    .json-preview { font-family: 'JetBrains Mono', monospace; font-size: 12px; white-space: pre-wrap; word-break: break-all; background: var(--surface-3); padding: 10px; border-radius: 6px; margin: 0 0 8px; }
    .warn-text { color: var(--warn, #ff9800); }
  `],
})
export class DressReviewPaneComponent {
  private svc   = inject(FirestoreDataService);
  private toast = inject(ToastService);
  private t     = inject(TranslateService);

  // Inputs
  readonly dressId          = input<string | null>(null);
  readonly initMandatory    = input<string[]>([]);
  readonly initOptional     = input<Record<string, unknown>>({});
  readonly initBranchOverrides = input<Record<string, unknown>>({});
  readonly pdfFileName      = input<string | null>(null);
  readonly pdfFileSizeLabel = input<string>('');
  readonly showActions      = input<boolean>(true);

  // Outputs
  readonly back           = output<void>();
  readonly continue       = output<void>();
  readonly mandatoryChange = output<string[]>();
  readonly optionalChange  = output<Record<string, unknown>>();

  readonly branches = toSignal(this.svc.branches(), { initialValue: [] as Branch[] });

  // Rule state — synced from inputs on first change
  readonly mandatory     = signal<string[]>([]);
  readonly optional      = signal<Record<string, unknown>>({});
  readonly branchOverrides = signal<Record<string, unknown>>({});

  // Mandatory editing
  readonly editMandatoryIdx = signal<number | null>(null);
  readonly editMandatoryVal = signal('');
  readonly addingMandatory  = signal(false);
  readonly newMandatoryVal  = signal('');
  readonly savingMandatory  = signal(false);

  // Optional editing
  readonly editOptionalKey = signal<string | null>(null);
  readonly editOptionalVal = signal('');
  readonly addingOptional  = signal(false);
  readonly newOptionalKey  = signal('');
  readonly newOptionalVal  = signal('');
  readonly savingOptional  = signal(false);

  // Branch accordions + JSON editing
  readonly openBranches   = signal<Record<string, boolean>>({});
  readonly editingBranch  = signal<string | null>(null);
  readonly branchJsonDraft = signal<Record<string, string>>({});
  readonly branchJsonError = signal<Record<string, string>>({});

  readonly optionalKeys = computed(() => Object.keys(this.optional()));

  constructor() {
    effect(() => {
      const m = this.initMandatory();
      if (m.length) this.mandatory.set([...m]);
    });
    effect(() => {
      const o = this.initOptional();
      if (Object.keys(o).length) this.optional.set({ ...o });
    });
    effect(() => {
      const bo = this.initBranchOverrides();
      if (Object.keys(bo).length) this.branchOverrides.set({ ...bo });
    });
  }

  // --- Mandatory rule helpers ---

  startMandatoryEdit(idx: number, val: string): void {
    this.editMandatoryIdx.set(idx);
    this.editMandatoryVal.set(val);
  }

  saveMandatoryEdit(idx: number): void {
    const val = this.editMandatoryVal().trim();
    if (!val) return;
    this.mandatory.update((list) => list.map((r, i) => (i === idx ? val : r)));
    this.editMandatoryIdx.set(null);
    this.mandatoryChange.emit(this.mandatory());
  }

  deleteMandatory(idx: number): void {
    this.mandatory.update((list) => list.filter((_, i) => i !== idx));
    this.mandatoryChange.emit(this.mandatory());
  }

  addMandatory(): void {
    this.addingMandatory.set(true);
    this.newMandatoryVal.set('');
  }

  commitNewMandatory(): void {
    const val = this.newMandatoryVal().trim();
    if (!val) return;
    this.mandatory.update((list) => [...list, val]);
    this.newMandatoryVal.set('');
    this.addingMandatory.set(false);
    this.mandatoryChange.emit(this.mandatory());
  }

  async saveMandatoryToFirestore(): Promise<void> {
    const id = this.dressId();
    if (!id) return;
    this.savingMandatory.set(true);
    try {
      await this.svc.updateDress(id, { mandatory_rules: this.mandatory() });
      await this.svc.addActivityLog('Updated mandatory rules', id);
      this.toast.success(this.t.instant('dress.review.toast.rulesSaved'));
    } catch {
      this.toast.error(this.t.instant('dress.review.toast.saveError'));
    } finally {
      this.savingMandatory.set(false);
    }
  }

  // --- Optional logic helpers ---

  startOptionalEdit(key: string): void {
    this.editOptionalKey.set(key);
    this.editOptionalVal.set(JSON.stringify(this.optional()[key]));
  }

  saveOptionalEdit(key: string): void {
    try {
      const parsed = JSON.parse(this.editOptionalVal());
      this.optional.update((o) => ({ ...o, [key]: parsed }));
      this.editOptionalKey.set(null);
      this.optionalChange.emit(this.optional());
    } catch {
      this.toast.error(this.t.instant('dress.review.toast.invalidJson'));
    }
  }

  deleteOptional(key: string): void {
    this.optional.update((o) => {
      const next = { ...o };
      delete next[key];
      return next;
    });
    this.optionalChange.emit(this.optional());
  }

  commitNewOptional(): void {
    const key = this.newOptionalKey().trim();
    const rawVal = this.newOptionalVal().trim();
    if (!key) return;
    let parsed: unknown = rawVal;
    try { parsed = JSON.parse(rawVal); } catch { /* keep as string */ }
    this.optional.update((o) => ({ ...o, [key]: parsed }));
    this.newOptionalKey.set('');
    this.newOptionalVal.set('');
    this.addingOptional.set(false);
    this.optionalChange.emit(this.optional());
  }

  async saveOptionalToFirestore(): Promise<void> {
    const id = this.dressId();
    if (!id) return;
    this.savingOptional.set(true);
    try {
      await this.svc.updateDress(id, { optional_logic: this.optional() });
      await this.svc.addActivityLog('Updated optional logic', id);
      this.toast.success(this.t.instant('dress.review.toast.rulesSaved'));
    } catch {
      this.toast.error(this.t.instant('dress.review.toast.saveError'));
    } finally {
      this.savingOptional.set(false);
    }
  }

  // --- Branch override helpers ---

  toggleBranch(id: string): void {
    this.openBranches.update((m) => ({ ...m, [id]: !m[id] }));
  }

  startBranchEdit(branchId: string): void {
    const current = this.branchOverrides()[branchId] ?? {};
    this.branchJsonDraft.update((d) => ({ ...d, [branchId]: JSON.stringify(current, null, 2) }));
    this.branchJsonError.update((e) => ({ ...e, [branchId]: '' }));
    this.editingBranch.set(branchId);
  }

  updateBranchDraft(branchId: string, val: string): void {
    this.branchJsonDraft.update((d) => ({ ...d, [branchId]: val }));
    try {
      JSON.parse(val);
      this.branchJsonError.update((e) => ({ ...e, [branchId]: '' }));
    } catch {
      this.branchJsonError.update((e) => ({ ...e, [branchId]: 'Invalid JSON' }));
    }
  }

  async saveBranchOverride(branchId: string): Promise<void> {
    const draft = this.branchJsonDraft()[branchId] ?? '{}';
    let parsed: unknown;
    try {
      parsed = JSON.parse(draft);
    } catch {
      this.toast.error(this.t.instant('dress.review.toast.invalidJson'));
      return;
    }
    const next = { ...this.branchOverrides(), [branchId]: parsed };
    this.branchOverrides.set(next);
    this.editingBranch.set(null);

    const id = this.dressId();
    if (id) {
      try {
        await this.svc.updateDress(id, { branch_overrides: next });
        await this.svc.addActivityLog(`Updated branch override: ${branchId}`, id);
        this.toast.success(this.t.instant('dress.review.toast.rulesSaved'));
      } catch {
        this.toast.error(this.t.instant('dress.review.toast.saveError'));
      }
    }
  }

  saveDraftEmit(): void {
    this.toast.success(this.t.instant('dress.review.saveDraftToast'));
  }
}
