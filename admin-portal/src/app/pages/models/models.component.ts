import {
  CUSTOM_ELEMENTS_SCHEMA,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  computed,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BehaviorSubject, switchMap } from 'rxjs';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { BranchDotComponent } from '../../shared/ui/branch-dot/branch-dot.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';

import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { StorageDataService } from '../../core/data/storage-data.service';
import { ToastService } from '../../core/toast/toast.service';
import {
  Accessory,
  BodyModel,
  Branch,
  DressCode,
  SocketCheckResult,
  UniformStatus,
} from '../../core/data/models';

// The 15 named socket nodes every body GLB must contain (per CLAUDE.md Phase-2 contract)
const EXPECTED_SOCKETS = [
  'head_top', 'cap_band_front',
  'left_collar_tip', 'right_collar_tip',
  'left_chest_pocket', 'right_chest_pocket',
  'left_shoulder_seam', 'right_shoulder_seam',
  'left_sleeve_upper', 'right_sleeve_upper',
  'belt_center',
  'left_ankle', 'right_ankle',
  'left_foot_top', 'right_foot_top',
];

type ModelsTab = 'bodies' | 'uniforms' | 'accessories' | 'placeholder';
type UniformGender = 'male' | 'female' | 'female_maternity';

interface UniformUploadTarget {
  branch: Branch['id'];
  codeKey: string;
  gender: UniformGender;
  label: string;
}

const BRANCH_IDS: Branch['id'][] = ['army', 'navy', 'rsaf', 'dis'];
const DRESS_CODE_KEYS = ['no1', 'no2', 'no3', 'no4', 'no5'];

@Component({
  selector: 'app-models',
  standalone: true,
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  imports: [
    FormsModule,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    BranchDotComponent,
    IconBtnComponent,
    PillToggleComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <!-- Hidden file inputs -->
    <input #bodyFileInput type="file" accept=".glb" style="display:none"
      (change)="onBodyFileChange($event)" />
    <input #uniformFileInput type="file" accept=".glb" style="display:none"
      (change)="onUniformFileChange($event)" />
    <input #accFileInput type="file" accept=".glb" style="display:none"
      (change)="onAccFileChange($event)" />
    <input #placeholderFileInput type="file" accept=".glb" style="display:none"
      (change)="onPlaceholderFileChange($event)" />

    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'models.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'models.title' | translate }}</h1>
          <p class="page-sub">{{ 'models.subtitle' | translate }}</p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="ghost" (click)="rescan()">
            <app-icon name="refresh" [size]="14" />
            {{ 'models.rescan' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="sub-tabs">
        <app-pill-toggle [options]="tabOptions()" [(ngModel)]="tab" />
      </div>

      @switch (tab()) {

        <!-- ================================================================
             BODIES TAB
             ================================================================ -->
        @case ('bodies') {
          <div class="bodies-grid">
            @for (b of bodies(); track b.id) {
              @let path = b.storagePath;
              @let progress = uploadProgress().get(path);
              @let sockResult = socketResults().get(b.id);
              <article class="card card-pad model-card">
                <header class="model-card-head">
                  <div>
                    <h3 class="card-title-md">{{ b.title }}</h3>
                    <div class="model-card-meta">
                      <app-chip [kind]="b.gender === 'F' ? 'rsaf' : 'navy'">
                        {{ (b.gender === 'M' ? 'models.bodies.male' : 'models.bodies.female') | translate }}
                      </app-chip>
                      <app-chip [kind]="b.status === 'delivered' ? 'gold' : 'warn'">
                        {{ (b.status === 'delivered' ? 'models.bodies.delivered' : 'models.bodies.placeholder') | translate }}
                      </app-chip>
                    </div>
                  </div>
                </header>

                <!-- Upload progress bar -->
                @if (progress != null) {
                  <div class="upload-progress-wrap">
                    <div class="upload-progress-bar" [style.width.%]="progress"></div>
                    <span class="mono-tag dim">{{ 'models.uploading.progressFormat' | translate: { pct: progress } }}</span>
                  </div>
                } @else {
                  <div class="model-viewer-frame model-viewer-frame-md">
                    <div class="model-viewer-ph">
                      <app-icon name="cube" [size]="64" />
                      <span class="mono-tag dim">{{ b.id }}.glb</span>
                    </div>
                  </div>
                }

                <div class="model-card-meta-row">
                  <span class="mono-tag">{{ b.size }}</span>
                  <span class="mono-tag dim">{{ b.date }}</span>
                </div>

                <!-- Socket status badge -->
                @if (sockResult) {
                  <div class="socket-badge-row">
                    <span class="socket-badge socket-badge-ok">
                      <app-icon name="check" [size]="10" />
                      {{ sockResult.found.length }}
                    </span>
                    @if (sockResult.missing.length > 0) {
                      <span class="socket-badge socket-badge-err">
                        <app-icon name="close" [size]="10" />
                        {{ sockResult.missing.length }} {{ 'models.bodies.socketMissing' | translate }}
                      </span>
                    } @else {
                      <span class="socket-badge socket-badge-ok">
                        {{ 'models.bodies.socketAllOk' | translate }}
                      </span>
                    }
                  </div>
                }

                <div class="model-card-actions">
                  <app-btn variant="primary" [disabled]="progress != null"
                    (click)="triggerBodyUpload(b)">
                    <app-icon name="upload" [size]="12" />
                    {{ (b.status === 'delivered' ? 'models.bodies.replace' : 'models.bodies.uploadNew') | translate }}
                  </app-btn>
                  <app-btn variant="ghost" (click)="downloadGlb(b.storagePath, b.id + '.glb')">
                    <app-icon name="download" [size]="12" />
                    {{ 'models.bodies.download' | translate }}
                  </app-btn>
                  <app-icon-btn
                    [ariaLabel]="'models.bodies.preview' | translate"
                    (click)="openPreview(b.storagePath, b.title)"
                  >
                    <app-icon name="eye" [size]="14" />
                  </app-icon-btn>
                  <app-icon-btn
                    [ariaLabel]="'models.bodies.checkSockets' | translate"
                    [disabled]="checkingSocketFor() === b.id"
                    (click)="checkBodySockets(b)"
                  >
                    @if (checkingSocketFor() === b.id) {
                      <app-icon name="refresh" [size]="14" />
                    } @else {
                      <app-icon name="check" [size]="14" />
                    }
                  </app-icon-btn>
                  <app-icon-btn
                    [ariaLabel]="'models.bodies.viewFull' | translate"
                    (click)="openBodyModal(b)"
                  >
                    <app-icon name="info" [size]="14" />
                  </app-icon-btn>
                </div>
              </article>
            }
          </div>
        }

        <!-- ================================================================
             UNIFORMS TAB
             ================================================================ -->
        @case ('uniforms') {
          <div class="uniform-toolbar">
            <app-pill-toggle [options]="genderTabOptions()" [(ngModel)]="uniformGender" />
          </div>
          <section class="card" style="padding: 0;">
            <div class="uniform-grid">
              <div class="uniform-row uniform-row-head">
                <div class="uniform-rh">{{ 'models.uniforms.branch' | translate }}</div>
                @for (d of dressCodes(); track d.id) {
                  <div class="uniform-ch">
                    {{ d.code }}
                    <small>{{ d.title.split(' ')[0] }}</small>
                  </div>
                }
              </div>
              @for (b of branches(); track b.id) {
                <div class="uniform-row">
                  <div class="uniform-rh">
                    <app-branch-dot [color]="b.color" />
                    <span>{{ b.name }}</span>
                  </div>
                  @for (s of uniformGrid()[b.id]; track $index) {
                    @let dc = dressCodes()[$index];
                    @let uKey = uniformKey(b.id, DRESS_CODE_KEYS[$index], uniformGender());
                    @let uProgress = uploadProgress().get('models/uniforms/' + uKey + '.glb');
                    <div class="uniform-cell" [class]="'uniform-' + s">
                      @if (uProgress != null) {
                        <div class="upload-progress-wrap">
                          <div class="upload-progress-bar" [style.width.%]="uProgress"></div>
                          <span class="mono-tag dim">{{ uProgress }}%</span>
                        </div>
                      } @else if (s === 'uploaded') {
                        <div class="uniform-cell-top">
                          <span style="color: var(--gold); display: inline-flex;">
                            <app-icon name="cube" [size]="22" />
                          </span>
                          <app-chip kind="gold">{{ 'models.uniforms.uploaded' | translate }}</app-chip>
                        </div>
                        <span class="mono-tag dim">{{ uniformGender() }}</span>
                        <div class="uniform-cell-actions">
                          <button class="link-btn link-gold" type="button"
                            (click)="triggerUniformUpload(b.id, DRESS_CODE_KEYS[$index], uniformGender(), b.name + ' ' + dc?.code)">
                            {{ 'models.uniforms.replace' | translate }}
                          </button>
                          <button class="link-btn" type="button"
                            (click)="downloadGlb('models/uniforms/' + uKey + '.glb', uKey + '.glb')">
                            {{ 'models.uniforms.download' | translate }}
                          </button>
                          <button class="link-btn" type="button"
                            (click)="openPreview('models/uniforms/' + uKey + '.glb', b.name + ' ' + dc?.code + ' (' + uniformGender() + ')')">
                            {{ 'models.uniforms.preview' | translate }}
                          </button>
                        </div>
                      } @else {
                        <div class="uniform-cell-top">
                          <span style="color: var(--err); display: inline-flex;">
                            <app-icon name="alert" [size]="22" />
                          </span>
                          <app-chip kind="err">{{ 'models.uniforms.missing' | translate }}</app-chip>
                        </div>
                        <span class="mono-tag dim">{{ uKey }}.glb</span>
                        <app-btn variant="ghost"
                          (click)="triggerUniformUpload(b.id, DRESS_CODE_KEYS[$index], uniformGender(), b.name + ' ' + dc?.code)">
                          <app-icon name="upload" [size]="12" />
                          {{ 'models.uniforms.upload' | translate }}
                        </app-btn>
                      }
                    </div>
                  }
                </div>
              }
            </div>
          </section>
        }

        <!-- ================================================================
             ACCESSORIES TAB
             ================================================================ -->
        @case ('accessories') {
          <section class="card" style="padding: 0;">
            <div class="acc-table-wrap">
              <table class="acc-table">
                <thead>
                  <tr>
                    <th>{{ 'models.accessoriesCol.id' | translate }}</th>
                    <th>{{ 'models.accessoriesCol.name' | translate }}</th>
                    <th>{{ 'models.accessoriesCol.category' | translate }}</th>
                    <th>{{ 'models.accessoriesCol.branch' | translate }}</th>
                    <th>{{ 'models.accessoriesCol.glb' | translate }}</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  @for (a of accessories(); track a.id) {
                    @let accPath = 'models/accessories/' + a.id + '.glb';
                    @let accProg = uploadProgress().get(accPath);
                    <tr class="acc-row">
                      <td><span class="mono-tag">{{ a.id }}</span></td>
                      <td><span class="acc-name">{{ a.name }}</span></td>
                      <td><app-chip>{{ a.cat }}</app-chip></td>
                      <td>
                        @if (branchById(a.branch); as b) {
                          <span
                            class="branch-chip"
                            [style.background]="b.base + '40'"
                            [style.borderColor]="b.color + '55'"
                            [style.color]="b.color"
                          >{{ b.name }}</span>
                        } @else {
                          <app-chip>All</app-chip>
                        }
                      </td>
                      <td>
                        @if (accProg != null) {
                          <div class="inline-progress">
                            <div class="inline-progress-bar" [style.width.%]="accProg"></div>
                            <span class="mono-tag dim">{{ accProg }}%</span>
                          </div>
                        } @else if (a.glb) {
                          <app-chip kind="gold">{{ 'models.accessoriesCol.uploadedChip' | translate }}</app-chip>
                        } @else if (a.legacy) {
                          <app-chip kind="warn">{{ 'models.accessoriesCol.placeholderChip' | translate }}</app-chip>
                        } @else {
                          <app-chip kind="err">{{ 'models.accessoriesCol.missingChip' | translate }}</app-chip>
                        }
                      </td>
                      <td>
                        <div class="acc-row-actions">
                          @if (a.glb) {
                            <app-icon-btn ariaLabel="Replace" (click)="triggerAccUpload(a)">
                              <app-icon name="upload" [size]="12" />
                            </app-icon-btn>
                            <app-icon-btn ariaLabel="Download" (click)="downloadGlb(accPath, a.id + '.glb')">
                              <app-icon name="download" [size]="12" />
                            </app-icon-btn>
                            <app-icon-btn ariaLabel="Preview" (click)="openPreview(accPath, a.name)">
                              <app-icon name="eye" [size]="12" />
                            </app-icon-btn>
                          } @else {
                            <app-btn variant="ghost" (click)="triggerAccUpload(a)">
                              <app-icon name="upload" [size]="12" />
                              {{ 'models.accessoriesCol.upload' | translate }}
                            </app-btn>
                          }
                        </div>
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          </section>
        }

        <!-- ================================================================
             PLACEHOLDER TAB
             ================================================================ -->
        @case ('placeholder') {
          @let phProg = uploadProgress().get('models/placeholder.glb');
          <section class="card card-pad">
            <div class="info-banner">
              <app-icon name="info" [size]="14" />
              <span>{{ 'models.placeholder.banner' | translate }}</span>
            </div>
            <div style="height: 18px;"></div>
            <div class="placeholder-pane">
              <div class="model-viewer-frame model-viewer-frame-lg" style="flex: 1;">
                @if (phProg != null) {
                  <div class="upload-progress-wrap" style="width: 100%;">
                    <div class="upload-progress-bar" [style.width.%]="phProg"></div>
                    <span class="mono-tag dim">{{ phProg }}%</span>
                  </div>
                } @else {
                  <div class="model-viewer-ph">
                    <app-icon name="cube" [size]="96" />
                    <span class="mono-tag dim">{{ 'models.placeholder.frameLabel' | translate }}</span>
                  </div>
                }
              </div>
              <aside class="placeholder-meta">
                <div class="eyebrow" style="color: var(--gold);">
                  {{ 'models.placeholder.fileEyebrow' | translate }}
                </div>
                <div class="meta-list">
                  <div>
                    <span>{{ 'models.placeholder.rows.path' | translate }}</span>
                    <span class="mono-tag">gs://saf-uniforms/models/placeholder.glb</span>
                  </div>
                  <div>
                    <span>{{ 'models.placeholder.rows.usedBy' | translate }}</span>
                    <span class="mono-tag">{{ 'models.placeholder.rows.usedByValue' | translate }}</span>
                  </div>
                </div>
                <div class="form-actions">
                  <app-btn variant="primary" [disabled]="phProg != null"
                    (click)="triggerPlaceholderUpload()">
                    <app-icon name="upload" [size]="12" />
                    {{ 'models.placeholder.replace' | translate }}
                  </app-btn>
                  <app-btn variant="ghost"
                    (click)="downloadGlb('models/placeholder.glb', 'placeholder.glb')">
                    <app-icon name="download" [size]="12" />
                    {{ 'models.placeholder.download' | translate }}
                  </app-btn>
                </div>
              </aside>
            </div>
          </section>
        }
      }

      <!-- ==================================================================
           BODY SOCKET DETAIL MODAL
           ================================================================== -->
      @if (openBody(); as b) {
        @let sockResult = socketResults().get(b.id);
        <div class="modal-backdrop" (click)="openBody.set(null)">
          <div class="modal model-full" (click)="$event.stopPropagation()">
            <button class="modal-close" type="button" (click)="openBody.set(null)">
              <app-icon name="close" [size]="16" />
            </button>
            <header class="modal-header">
              <div class="eyebrow" style="color: var(--gold);">
                {{ 'models.fullModal.eyebrow' | translate }}
              </div>
              <h2 class="modal-title">{{ b.title }}</h2>
            </header>
            <div class="model-full-body">
              <div class="model-viewer-frame model-viewer-frame-lg">
                <div class="model-viewer-ph">
                  <app-icon name="cube" [size]="96" />
                  <span class="mono-tag">{{ b.id }}.glb</span>
                  <div class="viewer-ctrls">
                    <app-icon-btn ariaLabel="Front">
                      {{ 'models.fullModal.ctrls.front' | translate }}
                    </app-icon-btn>
                    <app-icon-btn ariaLabel="Side">
                      {{ 'models.fullModal.ctrls.side' | translate }}
                    </app-icon-btn>
                    <app-icon-btn ariaLabel="Back">
                      {{ 'models.fullModal.ctrls.back' | translate }}
                    </app-icon-btn>
                    <app-icon-btn [ariaLabel]="'models.fullModal.ctrls.rotate' | translate">
                      <app-icon name="rotate" [size]="12" />
                    </app-icon-btn>
                  </div>
                </div>
              </div>
              <aside class="socket-panel">
                <div class="eyebrow" style="color: var(--gold);">
                  {{ 'models.fullModal.socketsTitle' | translate }}
                </div>
                @if (!sockResult) {
                  <app-btn variant="ghost" [disabled]="checkingSocketFor() === b.id"
                    (click)="checkBodySockets(b)">
                    @if (checkingSocketFor() === b.id) {
                      <app-icon name="refresh" [size]="12" />
                      {{ 'models.bodies.checking' | translate }}
                    } @else {
                      <app-icon name="check" [size]="12" />
                      {{ 'models.bodies.checkSockets' | translate }}
                    }
                  </app-btn>
                }
                <ul class="socket-list">
                  @for (s of EXPECTED_SOCKETS; track s) {
                    @let found = sockResult ? sockResult.found.includes(s) : null;
                    <li class="socket-row">
                      <span
                        class="socket-mark"
                        [style.background]="found === true ? 'rgba(95,191,106,0.16)' : found === false ? 'rgba(216,83,63,0.16)' : 'rgba(120,120,120,0.12)'"
                        [style.color]="found === true ? '#5FBF6A' : found === false ? '#D8533F' : '#888'"
                      >
                        @if (found === true) {
                          <app-icon name="check" [size]="11" />
                        } @else if (found === false) {
                          <app-icon name="close" [size]="11" />
                        } @else {
                          <app-icon name="dot" [size]="11" />
                        }
                      </span>
                      <span class="mono-tag">{{ s }}</span>
                    </li>
                  }
                </ul>
              </aside>
            </div>
          </div>
        </div>
      }

      <!-- ==================================================================
           3D PREVIEW MODAL (model-viewer)
           ================================================================== -->
      @if (previewUrl()) {
        <div class="modal-backdrop" (click)="closePreview()">
          <div class="modal model-preview" (click)="$event.stopPropagation()">
            <button class="modal-close" type="button" (click)="closePreview()">
              <app-icon name="close" [size]="16" />
            </button>
            <header class="modal-header">
              <div class="eyebrow" style="color: var(--gold);">
                {{ 'models.preview.eyebrow' | translate }}
              </div>
              <h2 class="modal-title">{{ previewTitle() }}</h2>
            </header>
            <div class="model-preview-body">
              @if (previewLoading()) {
                <div class="model-viewer-ph" style="height: 500px;">
                  <app-icon name="cube" [size]="64" />
                  <span class="mono-tag dim">{{ 'models.preview.loading' | translate }}</span>
                </div>
              }
              <model-viewer
                [src]="previewUrl()"
                camera-controls
                auto-rotate
                shadow-intensity="1"
                style="width: 100%; height: 500px; background: var(--charcoal-2, #1a1a1a);"
                (load)="previewLoading.set(false)"
                (error)="onPreviewError()"
              ></model-viewer>
            </div>
          </div>
        </div>
      }
    </div>
  `,
})
export class ModelsComponent {
  private svc     = inject(FirestoreDataService);
  private storage = inject(StorageDataService);
  private toast   = inject(ToastService);
  private t       = inject(TranslateService);

  // Expose for template use
  readonly EXPECTED_SOCKETS = EXPECTED_SOCKETS;
  readonly DRESS_CODE_KEYS  = DRESS_CODE_KEYS;

  // File input refs
  readonly bodyFileInput        = viewChild<ElementRef<HTMLInputElement>>('bodyFileInput');
  readonly uniformFileInput     = viewChild<ElementRef<HTMLInputElement>>('uniformFileInput');
  readonly accFileInput         = viewChild<ElementRef<HTMLInputElement>>('accFileInput');
  readonly placeholderFileInput = viewChild<ElementRef<HTMLInputElement>>('placeholderFileInput');

  // Tab state
  readonly tab           = signal<ModelsTab>('bodies');
  readonly uniformGender = signal<UniformGender>('male');

  // Modal / drawer state
  readonly openBody       = signal<BodyModel | null>(null);
  readonly previewUrl     = signal<string | null>(null);
  readonly previewTitle   = signal('');
  readonly previewLoading = signal(false);

  // Upload progress — keyed by storage path, value 0-100
  readonly uploadProgress = signal<Map<string, number>>(new Map());

  // Socket check
  readonly socketResults    = signal<Map<string, SocketCheckResult>>(new Map());
  readonly checkingSocketFor = signal<string | null>(null);

  // Which body/uniform/acc is being uploaded (for file input routing)
  private pendingBodyId: string = '';
  private pendingUniformTarget: UniformUploadTarget | null = null;
  private pendingAccId: string = '';

  // BehaviorSubjects to trigger refreshes
  private readonly bodiesRefresh$  = new BehaviorSubject<void>(undefined);
  private readonly uniformRefresh$ = new BehaviorSubject<void>(undefined);
  private readonly accRefresh$     = new BehaviorSubject<void>(undefined);

  // Data streams
  readonly bodies     = toSignal(
    this.bodiesRefresh$.pipe(switchMap(() => this.storage.bodyModels())),
    { initialValue: [] as BodyModel[] },
  );
  readonly uniformSet = toSignal(
    this.uniformRefresh$.pipe(switchMap(() => this.storage.uniformMatrix())),
    { initialValue: new Set<string>() },
  );
  readonly accessories = toSignal(
    this.accRefresh$.pipe(switchMap(() => this.svc.accessories())),
    { initialValue: [] as Accessory[] },
  );

  // Static data
  readonly branches   = toSignal(this.svc.branches(),   { initialValue: [] as Branch[] });
  readonly dressCodes = toSignal(this.svc.dressCodes(),  { initialValue: [] as DressCode[] });

  // Derived
  readonly uniformGrid = computed<Record<Branch['id'], UniformStatus[]>>(() => {
    const set    = this.uniformSet();
    const gender = this.uniformGender();
    return Object.fromEntries(
      BRANCH_IDS.map((branch) => [
        branch,
        DRESS_CODE_KEYS.map((code) =>
          set.has(`${branch}_${code}_${gender}.glb`) ? 'uploaded' : 'missing',
        ),
      ]),
    ) as Record<Branch['id'], UniformStatus[]>;
  });

  readonly tabOptions = computed<PillToggleOption[]>(() => [
    { value: 'bodies',      label: this.t.instant('models.tabs.bodies') },
    { value: 'uniforms',    label: this.t.instant('models.tabs.uniforms') },
    { value: 'accessories', label: this.t.instant('models.tabs.accessories') },
    { value: 'placeholder', label: this.t.instant('models.tabs.placeholder') },
  ]);

  readonly genderTabOptions = computed<PillToggleOption[]>(() => [
    { value: 'male',             label: this.t.instant('models.uniforms.gender.male') },
    { value: 'female',           label: this.t.instant('models.uniforms.gender.female') },
    { value: 'female_maternity', label: this.t.instant('models.uniforms.gender.maternity') },
  ]);

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  uniformKey(branch: string, code: string, gender: string): string {
    return `${branch}_${code}_${gender}`;
  }

  branchById(id: Accessory['branch']): Branch | undefined {
    if (id === 'all') return undefined;
    return this.branches().find((b) => b.id === id);
  }

  rescan(): void {
    this.bodiesRefresh$.next();
    this.uniformRefresh$.next();
    this.accRefresh$.next();
    this.toast.info(this.t.instant('models.toast.rescanning'));
  }

  // -------------------------------------------------------------------------
  // Bodies — upload
  // -------------------------------------------------------------------------

  triggerBodyUpload(b: BodyModel): void {
    this.pendingBodyId = b.id;
    this.bodyFileInput()?.nativeElement.click();
  }

  onBodyFileChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file || !this.pendingBodyId) return;
    const id   = this.pendingBodyId;
    const path = `models/bodies/${id}.glb`;
    this.pendingBodyId = '';
    (event.target as HTMLInputElement).value = '';

    this.storage.uploadBodyGlb(id, file).subscribe({
      next: (pct) => this.setProgress(path, pct),
      error: (err) => {
        this.clearProgress(path);
        console.error('Body GLB upload failed', err);
        this.toast.error(this.t.instant('models.toast.uploadFailed'));
      },
      complete: () => {
        this.clearProgress(path);
        this.svc.addActivityLog('Uploaded body GLB', `${id}.glb`);
        this.toast.success(this.t.instant('models.toast.uploadBodyOk', { id }));
        this.bodiesRefresh$.next();
      },
    });
  }

  // -------------------------------------------------------------------------
  // Uniforms — upload
  // -------------------------------------------------------------------------

  triggerUniformUpload(branch: Branch['id'], codeKey: string, gender: UniformGender, label: string): void {
    this.pendingUniformTarget = { branch, codeKey, gender, label };
    this.uniformFileInput()?.nativeElement.click();
  }

  onUniformFileChange(event: Event): void {
    const file   = (event.target as HTMLInputElement).files?.[0];
    const target = this.pendingUniformTarget;
    if (!file || !target) return;
    const path = `models/uniforms/${target.branch}_${target.codeKey}_${target.gender}.glb`;
    this.pendingUniformTarget = null;
    (event.target as HTMLInputElement).value = '';

    this.storage.uploadUniformGlb(target.branch, target.codeKey, target.gender, file).subscribe({
      next: (pct) => this.setProgress(path, pct),
      error: (err) => {
        this.clearProgress(path);
        console.error('Uniform GLB upload failed', err);
        this.toast.error(this.t.instant('models.toast.uploadFailed'));
      },
      complete: () => {
        this.clearProgress(path);
        this.svc.addActivityLog('Uploaded uniform GLB', path.split('/').pop()!);
        this.toast.success(this.t.instant('models.toast.uploadUniformOk', { label: target.label }));
        this.uniformRefresh$.next();
      },
    });
  }

  // -------------------------------------------------------------------------
  // Accessories — upload (Models page tab)
  // -------------------------------------------------------------------------

  triggerAccUpload(a: Accessory): void {
    this.pendingAccId = a.id;
    this.accFileInput()?.nativeElement.click();
  }

  onAccFileChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file || !this.pendingAccId) return;
    const id   = this.pendingAccId;
    const path = `models/accessories/${id}.glb`;
    this.pendingAccId = '';
    (event.target as HTMLInputElement).value = '';

    this.storage.uploadAccessoryGlb(id, file).subscribe({
      next: (pct) => this.setProgress(path, pct),
      error: (err) => {
        this.clearProgress(path);
        console.error('Accessory GLB upload failed', err);
        this.toast.error(this.t.instant('models.toast.uploadFailed'));
      },
      complete: () => {
        this.clearProgress(path);
        this.svc.addActivityLog('Uploaded accessory GLB', `${id}.glb`);
        this.toast.success(this.t.instant('models.toast.uploadAccOk', { id }));
        this.accRefresh$.next();
      },
    });
  }

  // -------------------------------------------------------------------------
  // Placeholder — upload
  // -------------------------------------------------------------------------

  triggerPlaceholderUpload(): void {
    this.placeholderFileInput()?.nativeElement.click();
  }

  onPlaceholderFileChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    const path = 'models/placeholder.glb';
    (event.target as HTMLInputElement).value = '';

    this.storage.uploadPlaceholderGlb(file).subscribe({
      next: (pct) => this.setProgress(path, pct),
      error: (err) => {
        this.clearProgress(path);
        console.error('Placeholder GLB upload failed', err);
        this.toast.error(this.t.instant('models.toast.uploadFailed'));
      },
      complete: () => {
        this.clearProgress(path);
        this.svc.addActivityLog('Uploaded placeholder GLB', 'placeholder.glb');
        this.toast.success(this.t.instant('models.toast.uploadPlaceholderOk'));
      },
    });
  }

  // -------------------------------------------------------------------------
  // Download
  // -------------------------------------------------------------------------

  async downloadGlb(storagePath: string, filename: string): Promise<void> {
    try {
      const url = await this.storage.getGlbUrl(storagePath);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
    } catch (err) {
      console.error('GLB download failed', err);
      this.toast.error(this.t.instant('models.toast.downloadFailed'));
    }
  }

  // -------------------------------------------------------------------------
  // 3D Preview (model-viewer modal)
  // -------------------------------------------------------------------------

  async openPreview(storagePath: string, title: string): Promise<void> {
    this.previewTitle.set(title);
    this.previewLoading.set(true);
    this.previewUrl.set(null);
    try {
      const url = await this.storage.getGlbUrl(storagePath);
      this.previewUrl.set(url);
    } catch (err) {
      console.error('Preview URL fetch failed', err);
      this.previewLoading.set(false);
      this.toast.error(this.t.instant('models.toast.downloadFailed'));
    }
  }

  closePreview(): void {
    this.previewUrl.set(null);
    this.previewLoading.set(false);
  }

  onPreviewError(): void {
    this.previewLoading.set(false);
    this.toast.error(this.t.instant('models.toast.previewError'));
  }

  // -------------------------------------------------------------------------
  // Body full-detail modal
  // -------------------------------------------------------------------------

  openBodyModal(b: BodyModel): void {
    this.openBody.set(b);
  }

  // -------------------------------------------------------------------------
  // Socket check — client-side GLB binary JSON-chunk parse (Option A)
  // -------------------------------------------------------------------------

  async checkBodySockets(b: BodyModel): Promise<void> {
    if (this.checkingSocketFor() === b.id) return;
    this.checkingSocketFor.set(b.id);
    try {
      const url  = await this.storage.getGlbUrl(b.storagePath);
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const buf  = await resp.arrayBuffer();
      const view = new DataView(buf);

      // GLB binary layout: magic(4) version(4) length(4) | chunkLen(4) chunkType(4) chunkData...
      const magic = view.getUint32(0, true);
      if (magic !== 0x46546C67) throw new Error('Not a valid GLB file');
      const chunkLen  = view.getUint32(12, true);
      const chunkType = view.getUint32(16, true);
      if (chunkType !== 0x4E4F534A) throw new Error('First chunk is not JSON');

      const jsonBytes = new Uint8Array(buf, 20, chunkLen);
      const gltf      = JSON.parse(new TextDecoder().decode(jsonBytes)) as {
        nodes?: { name?: string }[];
      };
      const nodeNames = new Set<string>(
        (gltf.nodes ?? []).map((n) => n.name ?? '').filter(Boolean),
      );
      const found   = EXPECTED_SOCKETS.filter((s) => nodeNames.has(s));
      const missing = EXPECTED_SOCKETS.filter((s) => !nodeNames.has(s));

      const results = new Map(this.socketResults());
      results.set(b.id, { found, missing });
      this.socketResults.set(results);

      if (missing.length === 0) {
        this.toast.success(this.t.instant('models.toast.socketOk', { title: b.title }));
      } else {
        this.toast.warning(
          this.t.instant('models.toast.socketMissing', { n: missing.length, title: b.title }),
        );
      }
    } catch (err) {
      console.error('Socket check failed', err);
      this.toast.error(this.t.instant('models.toast.socketCheckFailed'));
    } finally {
      this.checkingSocketFor.set(null);
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  private setProgress(path: string, pct: number): void {
    this.uploadProgress.update((m) => new Map(m).set(path, pct));
  }

  private clearProgress(path: string): void {
    this.uploadProgress.update((m) => {
      const next = new Map(m);
      next.delete(path);
      return next;
    });
  }
}
