import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  signal,
  untracked,
  viewChild,
  ElementRef,
} from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { FieldComponent } from '../../shared/ui/field/field.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import { ModalComponent } from '../../shared/ui/modal/modal.component';
import { DrawerComponent } from '../../shared/ui/drawer/drawer.component';
import { JsonViewerComponent } from '../../shared/ui/json-viewer/json-viewer.component';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';
import { SelectComponent, SelectOption } from '../../shared/ui/select/select.component';

import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { StorageDataService } from '../../core/data/storage-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { Accessory, Branch, Dress } from '../../core/data/models';

const CAT_COLORS: Record<string, string> = {
  headdress_beret: '#6A8F4D',
  headdress_cap: '#3A6EA5',
  cap_badge: '#FFCC00',
  epaulette: '#D4A017',
  lanyard: '#ED2939',
  medal: '#FFCC00',
  badge_qualification: '#7FC1EC',
  turban_sikh: '#1F2326',
  sash: '#FAF6E8',
};

type DrawerTab = 'details' | 'images' | 'model' | 'usage';

@Component({
  selector: 'app-accessories',
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
    DrawerComponent,
    JsonViewerComponent,
    PillToggleComponent,
    SelectComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <!-- Hidden file inputs (outside drawer so they survive drawer open/close) -->
    <input #imgFileInput type="file" accept="image/png,image/jpeg,image/webp" style="display:none"
      (change)="onImageFileChange($event, 'image')" />
    <input #placeFileInput type="file" accept="image/png,image/jpeg,image/webp" style="display:none"
      (change)="onImageFileChange($event, 'placement')" />
    <input #glbFileInput type="file" accept=".glb" style="display:none"
      (change)="onGlbFileChange($event)" />

    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'accessories.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'accessories.title' | translate }}</h1>
          <p class="page-sub">
            {{ 'accessories.subtitleFormat' | translate: { items: accessories().length, categories: categoryList().length } }}
          </p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="primary" (click)="openAddModal()">
            <app-icon name="plus" [size]="14" />
            {{ 'accessories.addAccessory' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="acc-toolbar">
        <div class="acc-search">
          <app-icon name="search" [size]="14" />
          <input
            class="acc-search-input"
            type="search"
            [(ngModel)]="search"
            [placeholder]="'accessories.searchPlaceholder' | translate"
          />
          @if (search()) {
            <button class="link-btn" type="button" (click)="search.set('')">
              <app-icon name="close" [size]="12" />
            </button>
          }
        </div>
        <div class="acc-filters">
          <app-select [options]="categoryOptions()" [(ngModel)]="categoryFilter" />
          <app-pill-toggle [options]="branchOptions()" [(ngModel)]="branchFilter" />
          <app-pill-toggle [options]="genderOptions()" [(ngModel)]="genderFilter" />
          <app-select [options]="glbOptions()" [(ngModel)]="glbFilter" />
        </div>
      </div>

      <section class="card" style="padding: 0;">
        <div class="acc-table-wrap">
          <table class="acc-table">
            <thead>
              <tr>
                <th></th>
                <th>{{ 'accessories.col.id' | translate }}</th>
                <th>{{ 'accessories.col.name' | translate }}</th>
                <th>{{ 'accessories.col.category' | translate }}</th>
                <th>{{ 'accessories.col.branch' | translate }}</th>
                <th>{{ 'accessories.col.gender' | translate }}</th>
                <th>{{ 'accessories.col.img' | translate }}</th>
                <th>{{ 'accessories.col.glb' | translate }}</th>
                <th>{{ 'accessories.col.place' | translate }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              @for (a of paginated(); track a.id) {
                <tr
                  class="acc-row"
                  [class.is-selected]="selected()?.id === a.id"
                  (click)="openDrawer(a)"
                >
                  <td>
                    <div class="acc-thumb">
                      @if (a.img) {
                        <div
                          class="acc-thumb-svg"
                          [style.background]="catColor(a.cat) + '22'"
                          [style.color]="catColor(a.cat)"
                        >
                          <app-icon name="badge" [size]="16" />
                        </div>
                      } @else {
                        <span class="acc-thumb-empty">
                          <app-icon name="badge" [size]="14" />
                        </span>
                      }
                    </div>
                  </td>
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
                      >
                        {{ b.name }}
                      </span>
                    } @else {
                      <app-chip>{{ 'accessories.filter.all' | translate }}</app-chip>
                    }
                  </td>
                  <td><span class="mono-tag">{{ a.gender }}</span></td>
                  <td>
                    @if (a.img) {
                      <span style="color: var(--ok); display: inline-flex;">
                        <app-icon name="check" [size]="14" />
                      </span>
                    } @else {
                      <span style="color: var(--err); display: inline-flex;">
                        <app-icon name="close" [size]="14" />
                      </span>
                    }
                  </td>
                  <td>
                    @if (a.glb) {
                      <span style="color: var(--ok); display: inline-flex;">
                        <app-icon name="check" [size]="14" />
                      </span>
                    } @else {
                      <span style="color: var(--err); display: inline-flex;">
                        <app-icon name="close" [size]="14" />
                      </span>
                    }
                  </td>
                  <td>
                    @if (a.place) {
                      <span style="color: var(--ok); display: inline-flex;">
                        <app-icon name="check" [size]="14" />
                      </span>
                    } @else {
                      <span style="color: var(--err); display: inline-flex;">
                        <app-icon name="close" [size]="14" />
                      </span>
                    }
                  </td>
                  <td>
                    <div class="acc-row-actions">
                      <app-icon-btn ariaLabel="View" (click)="$event.stopPropagation(); openDrawer(a)">
                        <app-icon name="eye" [size]="12" />
                      </app-icon-btn>
                      <app-icon-btn ariaLabel="Edit" (click)="$event.stopPropagation(); openDrawerEdit(a)">
                        <app-icon name="edit" [size]="12" />
                      </app-icon-btn>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>

          @if (filtered().length === 0) {
            <div style="padding: 40px;">
              <section class="empty-state">
                <div class="empty-title">{{ 'accessories.empty.title' | translate }}</div>
                <p class="empty-body">{{ 'accessories.empty.body' | translate }}</p>
                <div style="margin-top: 12px;">
                  <app-btn variant="ghost" (click)="clearFilters()">
                    {{ 'accessories.empty.clear' | translate }}
                  </app-btn>
                </div>
              </section>
            </div>
          }

          <div class="acc-table-foot">
            <div style="display: flex; align-items: center; gap: 8px;">
              <span class="mono-tag dim">{{ 'accessories.footer.pageSize' | translate }}</span>
              <app-select
                [options]="pageSizeOptions"
                [ngModel]="pageSize().toString()"
                (ngModelChange)="setPageSize(+$event)"
                style="width: 90px;"
              />
            </div>
            <span class="mono-tag dim">
              {{ 'accessories.footer.showingRangeFormat' | translate: { from: pageStart(), to: pageEnd(), total: filtered().length } }}
            </span>
            <div class="pager">
              <app-icon-btn
                ariaLabel="Prev"
                [disabled]="currentPage() === 0"
                (click)="prevPage()"
              >
                <app-icon name="chevL" [size]="12" />
              </app-icon-btn>
              <span class="mono-tag">{{ currentPage() + 1 }} / {{ totalPages() }}</span>
              <app-icon-btn
                ariaLabel="Next"
                [disabled]="currentPage() >= totalPages() - 1"
                (click)="nextPage()"
              >
                <app-icon name="chevR" [size]="12" />
              </app-icon-btn>
            </div>
          </div>
        </div>
      </section>

      <!-- ------------------------------------------------------------------ -->
      <!-- Drawer                                                               -->
      <!-- ------------------------------------------------------------------ -->
      <app-drawer
        [open]="!!selected()"
        [eyebrow]="drawerEyebrow()"
        [title]="selected()?.name ?? ''"
        [sub]="selected()?.id ?? ''"
        (close)="closeDrawer()"
      >
        <nav drawerTabs class="drawer-tabs">
          @for (tab of drawerTabs; track tab.key) {
            <button
              type="button"
              class="drawer-tab"
              [class.is-active]="activeTab() === tab.key"
              (click)="activeTab.set(tab.key)"
            >
              {{ tab.labelKey | translate }}
            </button>
          }
        </nav>

        @if (selected(); as a) {

          <!-- Details tab -->
          @if (activeTab() === 'details') {
            <div class="drawer-form">
              <app-field [label]="'accessories.drawer.details.name' | translate">
                <input
                  class="input"
                  [value]="editing() ? editName() : a.name"
                  [readonly]="!editing()"
                  (input)="editName.set($any($event.target).value)"
                />
              </app-field>
              <div class="form-row">
                <app-field [label]="'accessories.drawer.details.category' | translate">
                  @if (editing()) {
                    <app-select [options]="rawCategoryOptions()" [(ngModel)]="editCat" />
                  } @else {
                    <input class="input" [value]="a.cat" readonly />
                  }
                </app-field>
                <app-field [label]="'accessories.drawer.details.branch' | translate">
                  @if (editing()) {
                    <app-select [options]="rawBranchOptions" [(ngModel)]="editBranch" />
                  } @else {
                    <input class="input" [value]="a.branch" readonly />
                  }
                </app-field>
                <app-field [label]="'accessories.drawer.details.gender' | translate">
                  @if (editing()) {
                    <app-select [options]="rawGenderOptions" [(ngModel)]="editGender" />
                  } @else {
                    <input class="input" [value]="a.gender" readonly />
                  }
                </app-field>
              </div>
              <app-field [label]="'accessories.drawer.details.rules' | translate">
                <app-json-viewer [value]="rulesJson(a)" />
              </app-field>
              <app-field [label]="'accessories.drawer.details.renderLogic' | translate">
                <app-json-viewer [value]="renderLogicJson(a)" />
              </app-field>
            </div>
          }

          <!-- Images tab -->
          @if (activeTab() === 'images') {
            <div class="drawer-form">
              <div class="form-row" style="gap: 14px;">

                <!-- Accessory image -->
                <app-field [label]="'accessories.drawer.images.accessory' | translate" style="flex: 1;">
                  <div class="img-slot">
                    @if (uploadingImg()) {
                      <div class="img-slot-preview" style="display:flex; align-items:center; justify-content:center;">
                        <span class="mono-tag">{{ 'accessories.drawer.images.uploading' | translate }}</span>
                      </div>
                    } @else if (a.imageUrl) {
                      <div class="img-slot-preview">
                        <img [src]="a.imageUrl" alt="Accessory image" style="max-width:100%; max-height:120px; object-fit:contain;" />
                      </div>
                    } @else {
                      <div class="img-slot-empty">
                        <app-icon name="badge" [size]="24" />
                      </div>
                    }
                    <div class="img-slot-info">
                      <app-btn variant="ghost" (click)="triggerImageUpload('image')" [disabled]="uploadingImg()">
                        <app-icon name="upload" [size]="12" />
                        {{ 'accessories.drawer.images.replace' | translate }}
                      </app-btn>
                      <span class="mono-tag dim" style="margin-top: 6px;">
                        accessories/{{ a.id }}/image.png
                      </span>
                    </div>
                  </div>
                </app-field>

                <!-- Placement diagram -->
                <app-field [label]="'accessories.drawer.images.placement' | translate" style="flex: 1;">
                  <div class="img-slot">
                    @if (uploadingPlace()) {
                      <div class="img-slot-preview" style="display:flex; align-items:center; justify-content:center;">
                        <span class="mono-tag">{{ 'accessories.drawer.images.uploading' | translate }}</span>
                      </div>
                    } @else if (a.placementUrl) {
                      <div class="img-slot-preview">
                        <img [src]="a.placementUrl" alt="Placement diagram" style="max-width:100%; max-height:120px; object-fit:contain;" />
                      </div>
                    } @else {
                      <div class="img-slot-empty">
                        <app-icon name="badge" [size]="24" />
                      </div>
                    }
                    <div class="img-slot-info">
                      <app-btn variant="ghost" (click)="triggerImageUpload('placement')" [disabled]="uploadingPlace()">
                        <app-icon name="upload" [size]="12" />
                        {{ 'accessories.drawer.images.replace' | translate }}
                      </app-btn>
                      <span class="mono-tag dim" style="margin-top: 6px;">
                        accessories/{{ a.id }}/placement.png
                      </span>
                    </div>
                  </div>
                </app-field>
              </div>
              <p class="muted">{{ 'accessories.drawer.images.specs' | translate }}</p>
            </div>
          }

          <!-- 3D Model tab -->
          @if (activeTab() === 'model') {
            <div class="drawer-form">
              <div class="model-viewer-frame model-viewer-frame-md">
                @if (a.glb) {
                  <div class="model-viewer-ph">
                    <app-icon name="cube" [size]="56" />
                    <span class="mono-tag">
                      {{ 'accessories.drawer.model.frameLabel' | translate: { id: a.id } }}
                    </span>
                  </div>
                } @else {
                  <div class="model-viewer-empty">
                    <app-icon name="cube" [size]="48" />
                    <p>{{ 'accessories.drawer.model.noGlb' | translate }}</p>
                  </div>
                }
              </div>
              @if (a.glb) {
                <div class="glb-meta">
                  <span class="mono-tag">models/accessories/{{ a.id }}.glb</span>
                </div>
              }
              @if (uploadingGlb()) {
                <div style="margin-top: 12px;">
                  <div class="mono-tag" style="margin-bottom: 6px;">
                    {{ 'accessories.drawer.model.progress' | translate: { pct: glbProgress() } }}
                  </div>
                  <div class="progress-bar">
                    <div class="progress-fill" [style.width]="glbProgress() + '%'"></div>
                  </div>
                </div>
              }
              <div class="form-row" style="margin-top: 14px;">
                <app-btn variant="primary" (click)="triggerGlbUpload()" [disabled]="uploadingGlb()">
                  <app-icon name="upload" [size]="12" />
                  {{ uploadingGlb()
                      ? ('accessories.drawer.model.uploading' | translate)
                      : ('accessories.drawer.model.uploadNew' | translate) }}
                </app-btn>
                <app-btn variant="ghost" [disabled]="!a.glb || uploadingGlb()" (click)="downloadGlb()">
                  <app-icon name="download" [size]="12" />
                  {{ 'accessories.drawer.model.download' | translate }}
                </app-btn>
              </div>
            </div>
          }

          <!-- Usage tab -->
          @if (activeTab() === 'usage') {
            <div class="drawer-form">
              <div class="eyebrow">{{ 'accessories.drawer.usage.referencedBy' | translate }}</div>
              <ul class="usage-list">
                @for (d of usageDresses(); track d.id) {
                  <li class="usage-row">
                    <span class="acc-thumb">
                      <span class="acc-thumb-empty">
                        <app-icon name="uniform" [size]="14" />
                      </span>
                    </span>
                    <span class="usage-name">{{ d.name }}</span>
                    <app-chip>{{ d.code }}</app-chip>
                    <span class="mono-tag dim">{{ d.status }}</span>
                  </li>
                }
              </ul>
            </div>
          }
        }

        <!-- Drawer footer -->
        <footer drawerFooter class="drawer-foot">
          @if (pendingDelete() === selected()?.id) {
            <app-btn variant="danger" (click)="deleteNow()">
              <app-icon name="trash" [size]="12" />
              {{ 'accessories.drawer.footer.confirmDelete' | translate }}
            </app-btn>
          } @else {
            <app-btn variant="danger-ghost" (click)="confirmDelete()">
              <app-icon name="trash" [size]="12" />
              {{ 'accessories.drawer.footer.delete' | translate }}
            </app-btn>
          }
          <div class="drawer-foot-right">
            @if (editing()) {
              <app-btn variant="ghost" (click)="cancelEdit()">
                {{ 'accessories.drawer.footer.cancel' | translate }}
              </app-btn>
              <app-btn variant="primary" (click)="saveChanges()">
                {{ 'accessories.drawer.footer.save' | translate }}
              </app-btn>
            } @else {
              <app-btn variant="ghost" (click)="closeDrawer()">
                {{ 'accessories.drawer.footer.discard' | translate }}
              </app-btn>
              <app-btn variant="primary" (click)="startEdit()">
                <app-icon name="edit" [size]="12" />
                {{ 'accessories.drawer.footer.edit' | translate }}
              </app-btn>
            }
          </div>
        </footer>
      </app-drawer>

      <!-- ------------------------------------------------------------------ -->
      <!-- Add Accessory modal                                                  -->
      <!-- ------------------------------------------------------------------ -->
      <app-modal
        [open]="addOpen()"
        [title]="'accessories.modal.title' | translate"
        (close)="addOpen.set(false)"
      >
        <div class="modal-form">
          <app-field [label]="'accessories.modal.idLabel' | translate">
            <input
              class="input"
              [placeholder]="'accessories.modal.idPlaceholder' | translate"
              [ngModel]="formId()"
              (ngModelChange)="formId.set($event)"
            />
          </app-field>
          <app-field [label]="'accessories.modal.nameLabel' | translate">
            <input
              class="input"
              [placeholder]="'accessories.modal.namePlaceholder' | translate"
              [ngModel]="formName()"
              (ngModelChange)="formName.set($event)"
            />
          </app-field>
          <div class="form-row">
            <app-field [label]="'accessories.modal.categoryLabel' | translate">
              <app-select [options]="rawCategoryOptions()" [(ngModel)]="formCat" />
            </app-field>
            <app-field [label]="'accessories.modal.branchLabel' | translate">
              <app-select [options]="rawBranchOptions" [(ngModel)]="formBranch" />
            </app-field>
            <app-field [label]="'accessories.modal.genderLabel' | translate">
              <app-select [options]="rawGenderOptions" [(ngModel)]="formGender" />
            </app-field>
          </div>

          <div
            class="modal-foot"
            style="display: flex; gap: 10px; justify-content: flex-end; padding-top: 8px;"
          >
            <app-btn variant="ghost" (click)="addOpen.set(false)">
              {{ 'accessories.modal.cancel' | translate }}
            </app-btn>
            <app-btn variant="primary" (click)="createAccessory()">
              {{ 'accessories.modal.create' | translate }}
            </app-btn>
          </div>
        </div>
      </app-modal>
    </div>
  `,
  styles: [`
    .progress-bar {
      height: 4px;
      background: var(--surface-2, #2a2d30);
      border-radius: 2px;
      overflow: hidden;
    }
    .progress-fill {
      height: 100%;
      background: var(--accent, #4A90D9);
      border-radius: 2px;
      transition: width 0.2s ease;
    }
  `],
})
export class AccessoriesComponent {
  private svc     = inject(FirestoreDataService);
  private storage = inject(StorageDataService);
  private toast   = inject(ToastService);
  private t       = inject(TranslateService);

  // ViewChild-equivalent signal-based DOM refs for file inputs
  private imgFileInputRef   = viewChild.required<ElementRef<HTMLInputElement>>('imgFileInput');
  private placeFileInputRef = viewChild.required<ElementRef<HTMLInputElement>>('placeFileInput');
  private glbFileInputRef   = viewChild.required<ElementRef<HTMLInputElement>>('glbFileInput');

  readonly accessories  = toSignal(this.svc.accessories(), { initialValue: [] as Accessory[] });
  readonly categoryList = toSignal(this.svc.accessoryCategories(), { initialValue: [] as string[] });
  readonly branches     = toSignal(this.svc.branches(), { initialValue: [] as Branch[] });
  readonly dresses      = toSignal(this.svc.dresses(), { initialValue: [] as Dress[] });

  // Table filter + pagination state
  readonly search         = signal('');
  readonly categoryFilter = signal<string>('all');
  readonly branchFilter   = signal<string>('all');
  readonly genderFilter   = signal<string>('all');
  readonly glbFilter      = signal<'all' | 'yes' | 'no' | 'legacy'>('all');
  readonly pageSize       = signal(20);
  readonly currentPage    = signal(0);

  // Drawer state
  readonly selected  = signal<Accessory | null>(null);
  readonly activeTab = signal<DrawerTab>('details');
  readonly addOpen   = signal(false);
  readonly editing   = signal(false);

  // Drawer edit-mode fields
  readonly editName   = signal('');
  readonly editCat    = signal('');
  readonly editBranch = signal<string>('all');
  readonly editGender = signal<string>('All');

  // Two-step delete confirmation
  readonly pendingDelete = signal<string | null>(null);

  // Upload state
  readonly uploadingImg   = signal(false);
  readonly uploadingPlace = signal(false);
  readonly uploadingGlb   = signal(false);
  readonly glbProgress    = signal(0);

  // Add modal form fields
  readonly formId     = signal('');
  readonly formName   = signal('');
  readonly formCat    = signal('');
  readonly formBranch = signal<string>('all');
  readonly formGender = signal<string>('All');

  constructor() {
    effect(() => {
      this.filtered();
      untracked(() => this.currentPage.set(0));
    });
  }

  readonly drawerTabs: { key: DrawerTab; labelKey: string }[] = [
    { key: 'details', labelKey: 'accessories.drawer.tabs.details' },
    { key: 'images',  labelKey: 'accessories.drawer.tabs.images' },
    { key: 'model',   labelKey: 'accessories.drawer.tabs.model' },
    { key: 'usage',   labelKey: 'accessories.drawer.tabs.usage' },
  ];

  readonly categoryOptions = computed<SelectOption[]>(() => [
    { value: 'all', label: this.t.instant('accessories.filter.allCategories') },
    ...this.categoryList().map((c) => ({ value: c, label: c })),
  ]);

  readonly rawCategoryOptions = computed<SelectOption[]>(() =>
    this.categoryList().map((c) => ({ value: c, label: c })),
  );

  readonly branchOptions = computed<PillToggleOption[]>(() => [
    { value: 'all', label: this.t.instant('accessories.filter.all') },
    ...this.branches().map((b) => ({ value: b.id, label: b.short })),
  ]);

  readonly rawBranchOptions: SelectOption[] = [
    { value: 'all',  label: 'All' },
    { value: 'army', label: 'Army' },
    { value: 'navy', label: 'Navy' },
    { value: 'rsaf', label: 'RSAF' },
    { value: 'dis',  label: 'DIS' },
  ];

  readonly genderOptions = computed<PillToggleOption[]>(() => [
    { value: 'all', label: this.t.instant('accessories.filter.all') },
    { value: 'M',   label: 'M' },
    { value: 'F',   label: 'F' },
  ]);

  readonly rawGenderOptions: SelectOption[] = [
    { value: 'All', label: 'All' },
    { value: 'M',   label: 'M' },
    { value: 'F',   label: 'F' },
  ];

  readonly glbOptions = computed<SelectOption[]>(() => [
    { value: 'all',    label: this.t.instant('accessories.filter.glbStatus') },
    { value: 'yes',    label: this.t.instant('accessories.filter.hasGlb') },
    { value: 'no',     label: this.t.instant('accessories.filter.missingGlb') },
    { value: 'legacy', label: this.t.instant('accessories.filter.legacy') },
  ]);

  readonly filtered = computed(() => {
    const q      = this.search().toLowerCase().trim();
    const cat    = this.categoryFilter();
    const branch = this.branchFilter();
    const gender = this.genderFilter();
    const glb    = this.glbFilter();
    return this.accessories().filter((a) => {
      if (q      && !`${a.name} ${a.id}`.toLowerCase().includes(q)) return false;
      if (cat    !== 'all' && a.cat !== cat)                         return false;
      if (branch !== 'all' && a.branch !== branch && a.branch !== 'all') return false;
      if (gender !== 'all' && a.gender !== gender && a.gender !== 'All') return false;
      if (glb === 'yes'    && !a.glb)   return false;
      if (glb === 'no'     && a.glb)    return false;
      if (glb === 'legacy' && !a.legacy) return false;
      return true;
    });
  });

  readonly paginated = computed(() => {
    const all   = this.filtered();
    const start = this.currentPage() * this.pageSize();
    return all.slice(start, start + this.pageSize());
  });

  readonly totalPages = computed(() => Math.max(1, Math.ceil(this.filtered().length / this.pageSize())));
  readonly pageStart  = computed(() => this.filtered().length === 0 ? 0 : this.currentPage() * this.pageSize() + 1);
  readonly pageEnd    = computed(() => Math.min(this.currentPage() * this.pageSize() + this.pageSize(), this.filtered().length));

  readonly pageSizeOptions: SelectOption[] = [
    { value: '10',  label: '10' },
    { value: '20',  label: '20' },
    { value: '50',  label: '50' },
    { value: '100', label: '100' },
  ];

  setPageSize(size: number): void { this.pageSize.set(size); this.currentPage.set(0); }
  prevPage(): void { this.currentPage.update((p) => Math.max(0, p - 1)); }
  nextPage(): void { this.currentPage.update((p) => Math.min(this.totalPages() - 1, p + 1)); }

  readonly drawerEyebrow = computed(() => {
    const a = this.selected();
    return a ? this.t.instant('accessories.drawer.eyebrowFormat', { cat: a.cat.toUpperCase() }) : '';
  });

  readonly usageDresses = computed(() => this.dresses().slice(0, 4));

  catColor(cat: string): string { return CAT_COLORS[cat] ?? '#8A9099'; }

  branchById(id: Accessory['branch']): Branch | undefined {
    if (id === 'all') return undefined;
    return this.branches().find((b) => b.id === id);
  }

  // -------------------------------------------------------------------------
  // Drawer open / close
  // -------------------------------------------------------------------------

  openDrawer(a: Accessory): void {
    this.selected.set(a);
    this.activeTab.set('details');
    this.editing.set(false);
    this.pendingDelete.set(null);
  }

  openDrawerEdit(a: Accessory): void {
    this.openDrawer(a);
    this.startEdit();
  }

  closeDrawer(): void {
    this.selected.set(null);
    this.editing.set(false);
    this.pendingDelete.set(null);
  }

  clearFilters(): void {
    this.search.set('');
    this.categoryFilter.set('all');
    this.branchFilter.set('all');
    this.genderFilter.set('all');
    this.glbFilter.set('all');
  }

  // -------------------------------------------------------------------------
  // Edit mode
  // -------------------------------------------------------------------------

  startEdit(): void {
    const a = this.selected();
    if (!a) return;
    this.editName.set(a.name);
    this.editCat.set(a.cat);
    this.editBranch.set(a.branch);
    this.editGender.set(a.gender);
    this.editing.set(true);
  }

  cancelEdit(): void {
    this.editing.set(false);
  }

  // -------------------------------------------------------------------------
  // JSON viewers (read-only)
  // -------------------------------------------------------------------------

  rulesJson(a: Accessory): string {
    return JSON.stringify({
      selection: 'branch_lookup',
      options:   { army: `${a.cat}_army`, navy: `${a.cat}_navy`, rsaf: `${a.cat}_rsaf`, dis: `${a.cat}_dis` },
      fallback:  `${a.cat}_army`,
      required:  true,
    }, null, 2);
  }

  renderLogicJson(a: Accessory): string {
    return JSON.stringify({ anchor: 'chest_left', offset_y_cm: 0.0, offset_x_cm: 0.0, legacy_placeholder: a.legacy }, null, 2);
  }

  // -------------------------------------------------------------------------
  // CRUD — Create
  // -------------------------------------------------------------------------

  openAddModal(): void {
    this.formId.set('');
    this.formName.set('');
    this.formCat.set(this.categoryList()[0] ?? '');
    this.formBranch.set('all');
    this.formGender.set('All');
    this.addOpen.set(true);
  }

  async createAccessory(): Promise<void> {
    const id   = this.formId().trim();
    const name = this.formName().trim();
    const cat  = this.formCat().trim();

    if (!id || !name || !cat) {
      this.toast.error(this.t.instant('accessories.toast.error.required'));
      return;
    }

    try {
      await this.svc.createAccessory(id, {
        display_name: name,
        category:     cat,
        branch_id:    this.formBranch(),
        gender:       this.formGender(),
        active:       true,
        anchor:       '',
      });
      await this.svc.addActivityLog('Created accessory', id);
      this.toast.success(this.t.instant('accessories.toast.created.title'), id);
      this.addOpen.set(false);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg === 'ID already exists') {
        this.toast.error(this.t.instant('accessories.toast.error.idExists'), id);
      } else {
        this.toast.error(this.t.instant('accessories.toast.error.createFailed'), msg);
      }
    }
  }

  // -------------------------------------------------------------------------
  // CRUD — Update
  // -------------------------------------------------------------------------

  async saveChanges(): Promise<void> {
    const a = this.selected();
    if (!a) return;
    try {
      await this.svc.updateAccessory(a.id, {
        display_name: this.editName(),
        category:     this.editCat(),
        branch_id:    this.editBranch(),
        gender:       this.editGender(),
      });
      await this.svc.addActivityLog('Updated accessory', a.id);
      this.editing.set(false);
      this.toast.success(this.t.instant('accessories.toast.saved.title'), a.name);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      this.toast.error(this.t.instant('accessories.toast.error.updateFailed'), msg);
    }
  }

  // -------------------------------------------------------------------------
  // CRUD — Delete (two-step)
  // -------------------------------------------------------------------------

  confirmDelete(): void {
    const a = this.selected();
    if (!a) return;
    this.pendingDelete.set(a.id);
    this.toast.warning(
      this.t.instant('accessories.toast.deletePrompt.title'),
      this.t.instant('accessories.toast.deletePrompt.body'),
    );
  }

  async deleteNow(): Promise<void> {
    const a = this.selected();
    if (!a || this.pendingDelete() !== a.id) return;
    try {
      await this.svc.deleteAccessory(a.id);
      this.storage.deleteAccessoryAssets(a.id).catch(() => {});
      await this.svc.addActivityLog('Deleted accessory', a.id);
      this.closeDrawer();
      this.toast.success(this.t.instant('accessories.toast.deleted.title'), a.name);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      this.toast.error(this.t.instant('accessories.toast.error.deleteFailed'), msg);
    }
  }

  // -------------------------------------------------------------------------
  // Image upload
  // -------------------------------------------------------------------------

  triggerImageUpload(type: 'image' | 'placement'): void {
    const el = type === 'image'
      ? this.imgFileInputRef().nativeElement
      : this.placeFileInputRef().nativeElement;
    el.value = '';
    el.click();
  }

  onImageFileChange(event: Event, type: 'image' | 'placement'): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    const a    = this.selected();
    if (!file || !a) return;

    if (type === 'image') this.uploadingImg.set(true);
    else                  this.uploadingPlace.set(true);

    this.storage.uploadAccessoryImage(a.id, file, type).subscribe({
      next: async (downloadUrl) => {
        try {
          const field = type === 'image' ? 'image_url' : 'placement_diagram';
          await this.svc.updateAccessory(a.id, { [field]: downloadUrl } as { image_url?: string; placement_diagram?: string });
          await this.svc.addActivityLog(`Uploaded ${type} image`, a.id);
          this.toast.success(this.t.instant('accessories.toast.uploadImg.title'), a.name);
        } catch {
          this.toast.error(this.t.instant('accessories.toast.error.uploadFailed'));
        } finally {
          if (type === 'image') this.uploadingImg.set(false);
          else                  this.uploadingPlace.set(false);
        }
      },
      error: () => {
        if (type === 'image') this.uploadingImg.set(false);
        else                  this.uploadingPlace.set(false);
        this.toast.error(this.t.instant('accessories.toast.error.uploadFailed'));
      },
    });
  }

  // -------------------------------------------------------------------------
  // GLB upload + download
  // -------------------------------------------------------------------------

  triggerGlbUpload(): void {
    const el = this.glbFileInputRef().nativeElement;
    el.value = '';
    el.click();
  }

  onGlbFileChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    const a    = this.selected();
    if (!file || !a) return;

    this.uploadingGlb.set(true);
    this.glbProgress.set(0);

    this.storage.uploadAccessoryGlb(a.id, file).subscribe({
      next: (pct)  => this.glbProgress.set(pct),
      error: ()    => {
        this.uploadingGlb.set(false);
        this.toast.error(this.t.instant('accessories.toast.error.uploadFailed'));
      },
      complete: async () => {
        try {
          await this.svc.addActivityLog('Uploaded GLB', a.id);
          this.toast.success(this.t.instant('accessories.toast.uploadGlb.title'), a.name);
        } catch { /* ignore log failure */ }
        this.uploadingGlb.set(false);
      },
    });
  }

  async downloadGlb(): Promise<void> {
    const a = this.selected();
    if (!a?.glb) return;
    try {
      const url    = await this.storage.getAccessoryGlbUrl(a.id);
      const anchor = document.createElement('a');
      anchor.href     = url;
      anchor.download = `${a.id}.glb`;
      anchor.click();
    } catch {
      this.toast.error(this.t.instant('accessories.toast.error.downloadFailed'));
    }
  }
}
