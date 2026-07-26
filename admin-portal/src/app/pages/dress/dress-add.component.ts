import {
  ChangeDetectionStrategy,
  Component,
  computed,
  DestroyRef,
  inject,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { FieldComponent } from '../../shared/ui/field/field.component';
import { SelectComponent, SelectOption } from '../../shared/ui/select/select.component';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';
import { PdfDropzoneComponent, PdfFile } from '../../shared/ui/pdf-dropzone/pdf-dropzone.component';

import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { StorageDataService } from '../../core/data/storage-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { DressCode } from '../../core/data/models';

import { DressReviewPaneComponent } from './dress-review-pane.component';

@Component({
  selector: 'app-dress-add',
  standalone: true,
  imports: [
    FormsModule,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    FieldComponent,
    SelectComponent,
    PillToggleComponent,
    PdfDropzoneComponent,
    DressReviewPaneComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dress.add.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'dress.add.title' | translate }}</h1>
          <p class="page-sub">{{ 'dress.add.subtitle' | translate }}</p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="ghost" (click)="back()">
            <app-icon name="chevL" [size]="14" />
            {{ 'dress.add.backToList' | translate }}
          </app-btn>
        </div>
      </header>

      <ol class="steps-bar">
        @for (s of stepLabels(); track $index) {
          @let n = $index + 1;
          <li
            class="step"
            [class.is-active]="n === step()"
            [class.is-done]="n < step()"
          >
            <span class="step-num">
              @if (n < step()) {
                <app-icon name="check" [size]="12" />
              } @else {
                {{ n }}
              }
            </span>
            <span class="step-label">{{ s }}</span>
            @if (n < stepLabels().length) {
              <span class="step-line"></span>
            }
          </li>
        }
      </ol>

      @if (step() === 1) {
        <section class="card card-pad">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dress.add.step1.eyebrow' | translate }}
          </div>
          <h2 class="card-title-lg">{{ 'dress.add.step1.title' | translate }}</h2>
          <p class="muted" style="margin-top: 6px;">
            {{ 'dress.add.step1.subtitle' | translate }}
          </p>

          <app-pdf-dropzone [file]="file()" (fileChange)="file.set($event)" />

          <div class="form-row">
            <app-field [label]="'dress.add.step1.dressCode' | translate" style="flex: 1;">
              <app-select [options]="dressCodeOptions()" [(ngModel)]="codeId" />
            </app-field>
            <app-field [label]="'dress.add.step1.displayName' | translate" style="flex: 2;">
              <input
                class="input"
                [(ngModel)]="name"
                [placeholder]="'dress.add.step1.namePlaceholder' | translate"
              />
            </app-field>
          </div>

          <div class="form-actions">
            <app-btn variant="ghost" (click)="back()">
              {{ 'dress.add.step1.cancel' | translate }}
            </app-btn>
            <app-btn variant="primary" [disabled]="!file()" (click)="goToReview()">
              <app-icon name="sliders" [size]="14" />
              {{ 'dress.add.step1.analyse' | translate }}
            </app-btn>
          </div>
        </section>
      }

      @if (step() === 2) {
        @if (uploadProgress() !== null && uploadProgress()! < 100) {
          <div class="upload-progress-card card card-pad" style="margin-bottom: 16px;">
            <div class="upload-progress-head">
              <app-icon name="pdf" [size]="16" />
              <span class="upload-filename">{{ file()?.name }}</span>
              <span class="upload-size muted">{{ fileSizeLabel() }}</span>
              <span class="upload-pct mono-tag">{{ uploadProgress() }}%</span>
            </div>
            <div class="progress-track">
              <div class="progress-fill" [style.width.%]="uploadProgress()!"></div>
            </div>
            <p class="muted" style="font-size: 12px; margin-top: 6px;">
              {{ 'dress.add.upload.uploading' | translate }}
            </p>
          </div>
        }
        @if (uploadProgress() === 100) {
          <div class="upload-done-banner card card-pad" style="margin-bottom: 16px;">
            <app-icon name="check" [size]="14" />
            <span>{{ 'dress.add.upload.done' | translate }}</span>
            <span class="mono-tag">{{ file()?.name }}</span>
          </div>
        }

        <app-dress-review-pane
          [pdfFileName]="file()?.name ?? null"
          [pdfFileSizeLabel]="fileSizeLabel()"
          (back)="step.set(1)"
          (continue)="step.set(3)"
          (mandatoryChange)="mandatoryRules.set($event)"
          (optionalChange)="optionalLogic.set($event)"
        />
      }

      @if (step() === 3) {
        <section class="card card-pad">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dress.finalise.eyebrow' | translate }}
          </div>
          <h2 class="card-title-lg">{{ 'dress.finalise.title' | translate }}</h2>

          <div class="final-grid">
            <div class="final-card">
              <span class="dress-code-pill">{{ selectedCode().toUpperCase() }}</span>
              <h3 class="final-title">{{ displayName() }}</h3>
              <ul class="final-summary">
                <li>
                  <span>{{ 'dress.finalise.summary.mandatoryRules' | translate }}</span>
                  <span>{{ mandatoryRules().length }}</span>
                </li>
                <li>
                  <span>{{ 'dress.finalise.summary.optionalRules' | translate }}</span>
                  <span>{{ objectKeys(optionalLogic()).length }}</span>
                </li>
                <li>
                  <span>{{ 'dress.finalise.summary.branchOverrides' | translate }}</span>
                  <span>0 branches</span>
                </li>
                <li>
                  <span>{{ 'dress.finalise.summary.doctrinePdf' | translate }}</span>
                  <span class="mono-tag">{{ file()?.name ?? '—' }}</span>
                </li>
              </ul>
            </div>

            <div class="final-side">
              <app-field [label]="'dress.finalise.doctrineStatus' | translate">
                <app-pill-toggle [options]="statusOptions()" [(ngModel)]="finalStatus" />
              </app-field>

              @if (finalStatus() === 'live') {
                <div class="warn-banner">
                  <app-icon name="warn" [size]="14" />
                  <span>{{ 'dress.finalise.warnLive' | translate }}</span>
                </div>
              }

              <div class="form-actions" style="margin-top: 18px;">
                <app-btn variant="ghost" [disabled]="saving()" (click)="step.set(2)">
                  {{ 'dress.finalise.back' | translate }}
                </app-btn>
                <app-btn variant="ghost" [disabled]="saving()" (click)="confirm(false)">
                  {{ 'dress.finalise.saveAsDraft' | translate }}
                </app-btn>
                <app-btn variant="primary" [disabled]="saving()" (click)="confirm(finalStatus() === 'live')">
                  @if (saving()) {
                    {{ 'common.loading' | translate }}
                  } @else {
                    {{ 'dress.finalise.markFinal' | translate }}
                  }
                </app-btn>
              </div>
            </div>
          </div>
        </section>
      }
    </div>
  `,
  styles: [`
    .upload-progress-card { display: flex; flex-direction: column; gap: 8px; }
    .upload-progress-head { display: flex; align-items: center; gap: 10px; }
    .upload-filename { font-weight: 500; flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .upload-size { font-size: 12px; }
    .upload-pct { font-size: 12px; }
    .progress-track { height: 4px; border-radius: 2px; background: var(--surface-3); overflow: hidden; }
    .progress-fill { height: 100%; background: var(--gold); border-radius: 2px; transition: width 0.2s; }
    .upload-done-banner { display: flex; align-items: center; gap: 10px; color: var(--ok, #4caf50); font-size: 13px; }
  `],
})
export class DressAddComponent {
  private svc     = inject(FirestoreDataService);
  private storage = inject(StorageDataService);
  private toast   = inject(ToastService);
  private router  = inject(Router);
  private t       = inject(TranslateService);
  private destroy = inject(DestroyRef);

  readonly dressCodes = toSignal(this.svc.dressCodes(), { initialValue: [] as DressCode[] });

  readonly step           = signal<1 | 2 | 3>(1);
  readonly file           = signal<PdfFile | null>(null);
  readonly codeId         = signal<string>('no3');
  readonly name           = signal<string>('');
  readonly finalStatus    = signal<'draft' | 'placeholder' | 'live'>('draft');
  readonly uploadProgress = signal<number | null>(null);
  readonly pdfUrl         = signal<string>('');
  readonly mandatoryRules = signal<string[]>([]);
  readonly optionalLogic  = signal<Record<string, unknown>>({});
  readonly saving         = signal(false);

  readonly stepLabels = computed<string[]>(() => [
    this.t.instant('dress.add.steps.upload'),
    this.t.instant('dress.add.steps.review'),
    this.t.instant('dress.add.steps.finalise'),
  ]);

  readonly dressCodeOptions = computed<SelectOption[]>(() =>
    this.dressCodes().map((d) => ({ value: d.id, label: `${d.code} — ${d.title}` })),
  );

  readonly statusOptions = computed<PillToggleOption[]>(() => [
    { value: 'draft',       label: this.t.instant('dress.finalise.status.draft') },
    { value: 'placeholder', label: this.t.instant('dress.finalise.status.placeholder') },
    { value: 'live',        label: this.t.instant('dress.finalise.status.live') },
  ]);

  readonly selectedCode = computed(() => {
    const c = this.dressCodes().find((d) => d.id === this.codeId());
    return c?.code ?? 'No.3';
  });

  readonly displayName = computed(() => this.name().trim() || 'Service Dress — Untitled');

  readonly dressId = computed(() => {
    const slug = this.displayName()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_|_$/g, '');
    return `${this.codeId()}_${slug}`;
  });

  readonly fileSizeLabel = computed(() => {
    const f = this.file();
    if (!f) return '';
    const bytes = (f as unknown as { size?: number }).size ?? 0;
    if (bytes >= 1_000_000) return `${(bytes / 1_000_000).toFixed(1)} MB`;
    if (bytes >= 1_000) return `${(bytes / 1_000).toFixed(0)} KB`;
    return `${bytes} B`;
  });

  readonly objectKeys = Object.keys;

  back(): void {
    this.router.navigateByUrl('/dress');
  }

  goToReview(): void {
    if (!this.file()) {
      this.toast.warning(this.t.instant('dress.add.step1.noPdfWarn'));
      return;
    }
    this.step.set(2);
    this.uploadProgress.set(0);

    this.storage
      .uploadDressPdf(this.dressId(), (this.file() as unknown as File))
      .pipe(takeUntilDestroyed(this.destroy))
      .subscribe({
        next: (pct) => this.uploadProgress.set(pct),
        error: () => {
          this.toast.error(this.t.instant('dress.add.upload.error'));
          this.uploadProgress.set(null);
        },
        complete: () => {
          this.storage.getDressPdfUrl(this.dressId()).then((url) => this.pdfUrl.set(url));
        },
      });
  }

  async confirm(asLive: boolean): Promise<void> {
    this.saving.set(true);
    try {
      const doctrineStatus = asLive ? 'pdf_aligned' : 'stub_pending_pdf';
      await this.svc.createDress(this.dressId(), {
        dress_name:       this.codeId(),
        display_name:     this.displayName(),
        doctrine_status:  doctrineStatus,
        pdf_url:          this.pdfUrl(),
        mandatory_rules:  this.mandatoryRules(),
        optional_logic:   this.optionalLogic(),
        branch_overrides: {},
      });
      await this.svc.addActivityLog('Created dress', this.dressId());
      const title = asLive
        ? this.t.instant('dress.finalise.savedLive.title')
        : this.t.instant('dress.finalise.savedDraft.title');
      this.toast.show(asLive ? 'success' : 'info', title, this.displayName());
      this.router.navigateByUrl(`/dress/${this.dressId()}`);
    } catch (err: unknown) {
      const msg = err instanceof Error && err.message === 'ID already exists'
        ? this.t.instant('dress.add.error.idExists')
        : this.t.instant('dress.add.error.createFailed');
      this.toast.error(msg);
    } finally {
      this.saving.set(false);
    }
  }
}
