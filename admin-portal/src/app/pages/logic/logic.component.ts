import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule, FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { FieldComponent } from '../../shared/ui/field/field.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import { ModalComponent } from '../../shared/ui/modal/modal.component';
import { JsonViewerComponent } from '../../shared/ui/json-viewer/json-viewer.component';

import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { LogicRule } from '../../core/data/models';

const NEW_RULE_TEMPLATE = `{
  "threshold": 1.0,
  "applyTo": []
}`;

@Component({
  selector: 'app-logic',
  standalone: true,
  imports: [
    FormsModule,
    ReactiveFormsModule,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    FieldComponent,
    IconBtnComponent,
    ModalComponent,
    JsonViewerComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'logic.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'logic.title' | translate }}</h1>
          <p class="page-sub">{{ 'logic.subtitle' | translate }}</p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="primary" (click)="addOpen.set(true)">
            <app-icon name="plus" [size]="14" />
            {{ 'logic.addRule' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="rules-list">
        @for (r of rules(); track r.id) {
          <article class="card card-pad rule-card">
            <header class="rule-card-head">
              <div class="rule-card-id">
                <span class="mono-tag">{{ r.id }}</span>
                @if (r.active) {
                  <app-chip kind="ok">{{ 'logic.activeChip' | translate }}</app-chip>
                } @else {
                  <app-chip>{{ 'logic.inactiveChip' | translate }}</app-chip>
                }
                <app-chip>{{ r.version }}</app-chip>
              </div>
              <div class="rule-card-actions">
                <span class="mono-tag dim">
                  {{ 'logic.modifiedFormat' | translate: { when: r.modified } }}
                </span>
                <app-icon-btn
                  [ariaLabel]="'logic.editJson' | translate"
                  [active]="!!editing()[r.id]"
                  (click)="toggleEdit(r.id)"
                >
                  <app-icon name="edit" [size]="12" />
                </app-icon-btn>
              </div>
            </header>

            <app-field [label]="'logic.descriptionLabel' | translate">
              <textarea class="textarea" rows="2">{{ r.desc }}</textarea>
            </app-field>

            <div class="eyebrow" style="margin-top: 12px; display: block;">
              {{ 'logic.paramsLabel' | translate }}
            </div>
            <div style="height: 6px;"></div>

            @if (editing()[r.id]) {
              <app-json-viewer [value]="jsonOf(r.params)" />
            } @else {
              <div class="params-grid">
                @for (entry of paramRows(r.params); track entry.k) {
                  <div class="param-row">
                    <span class="mono-tag dim">{{ entry.k }}</span>
                    <span class="mono-tag">{{ entry.v }}</span>
                  </div>
                }
              </div>
            }

            <footer class="rule-card-foot">
              <app-btn
                [variant]="pendingDelete() === r.id ? 'danger' : 'danger-ghost'"
                (click)="confirmDelete(r)"
              >
                <app-icon name="trash" [size]="12" />
                {{ 'logic.delete' | translate }}
              </app-btn>
              <app-btn variant="primary" (click)="save(r)">
                {{ 'logic.save' | translate }}
              </app-btn>
            </footer>
          </article>
        }
      </div>

      <app-modal
        [open]="addOpen()"
        [title]="'logic.modal.title' | translate"
        (close)="addOpen.set(false)"
      >
        <form [formGroup]="addForm" class="modal-form" (ngSubmit)="createRule()">
          <app-field [label]="'logic.modal.idLabel' | translate">
            <input
              class="input"
              formControlName="id"
              [placeholder]="'logic.modal.idPlaceholder' | translate"
            />
          </app-field>
          <app-field [label]="'logic.modal.descriptionLabel' | translate">
            <textarea
              class="textarea"
              rows="3"
              formControlName="description"
              [placeholder]="'logic.modal.descriptionPlaceholder' | translate"
            ></textarea>
          </app-field>
          <app-field [label]="'logic.modal.paramsLabel' | translate">
            <app-json-viewer [value]="newRuleTemplate" />
          </app-field>

          <div class="modal-foot" style="display: flex; gap: 10px; justify-content: flex-end; padding-top: 8px;">
            <app-btn variant="ghost" (click)="addOpen.set(false)">
              {{ 'logic.modal.cancel' | translate }}
            </app-btn>
            <app-btn variant="primary" type="submit" [disabled]="addForm.invalid">
              {{ 'logic.modal.create' | translate }}
            </app-btn>
          </div>
        </form>
      </app-modal>
    </div>
  `,
})
export class LogicComponent {
  private svc = inject(FirestoreDataService);
  private toast = inject(ToastService);
  private t = inject(TranslateService);
  private fb = inject(FormBuilder);

  readonly rules = toSignal(this.svc.logicRules(), { initialValue: [] as LogicRule[] });
  readonly editing = signal<Record<string, boolean>>({});
  readonly addOpen = signal(false);
  readonly pendingDelete = signal<string | null>(null);

  readonly newRuleTemplate = NEW_RULE_TEMPLATE;

  readonly addForm = this.fb.nonNullable.group({
    id: ['', [Validators.required, Validators.pattern(/^[a-z0-9_]+$/)]],
    description: ['', [Validators.required, Validators.minLength(10)]],
  });

  toggleEdit(id: string): void {
    this.editing.update((m) => ({ ...m, [id]: !m[id] }));
  }

  jsonOf(params: Record<string, unknown>): string {
    return JSON.stringify(params, null, 2);
  }

  paramRows(params: Record<string, unknown>): { k: string; v: string }[] {
    return Object.entries(params).map(([k, v]) => ({
      k,
      v: typeof v === 'boolean' ? (v ? 'true' : 'false') : String(v),
    }));
  }

  async save(r: LogicRule): Promise<void> {
    try {
      await this.svc.saveLogicRule(r.id, r);
      await this.svc.addActivityLog('Updated logic rule', r.id);
      this.toast.success(this.t.instant('logic.toast.saved.title'), r.id);
    } catch {
      this.toast.show('error', this.t.instant('logic.toast.saveFailed.title'), r.id);
    }
  }

  async confirmDelete(r: LogicRule): Promise<void> {
    if (this.pendingDelete() !== r.id) {
      this.pendingDelete.set(r.id);
      this.toast.warning(this.t.instant('logic.toast.deletePrompt.titleFormat', { id: r.id }));
      return;
    }
    try {
      await this.svc.deleteLogicRule(r.id);
      await this.svc.addActivityLog('Deleted logic rule', r.id);
      this.pendingDelete.set(null);
      this.toast.success(this.t.instant('logic.toast.deleted.title'), r.id);
    } catch {
      this.pendingDelete.set(null);
      this.toast.show('error', this.t.instant('logic.toast.deleteFailed.title'), r.id);
    }
  }

  async createRule(): Promise<void> {
    if (this.addForm.invalid) return;
    const { id, description } = this.addForm.getRawValue();
    let params: Record<string, unknown> = {};
    try { params = JSON.parse(NEW_RULE_TEMPLATE); } catch { /* use empty */ }
    try {
      await this.svc.createLogicRule(id, description, params);
      await this.svc.addActivityLog('Created logic rule', id);
      this.toast.success(this.t.instant('logic.toast.created.title'), id);
      this.addForm.reset({ id: '', description: '' });
      this.addOpen.set(false);
    } catch {
      this.toast.show('error', this.t.instant('logic.toast.createFailed.title'), id);
    }
  }
}
