import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  signal,
} from '@angular/core';
import { UpperCasePipe } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { switchMap } from 'rxjs/operators';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { StorageDataService } from '../../core/data/storage-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { ActivityEntry, Dress } from '../../core/data/models';

import { DressReviewPaneComponent } from './dress-review-pane.component';

@Component({
  selector: 'app-dress-edit',
  standalone: true,
  imports: [
    UpperCasePipe,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    DressReviewPaneComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      @if (dress(); as d) {
        <header class="page-header">
          <div class="page-header-text">
            <div class="eyebrow" style="color: var(--gold);">
              {{ 'dress.edit.eyebrowFormat' | translate: { code: d.code } }}
            </div>
            <h1 class="page-title">{{ d.name }}</h1>
            <p class="page-sub">
              {{ 'dress.edit.subtitle' | translate }}
              <span class="mono-tag" style="margin-left: 6px;">{{ d.id }}</span>
            </p>
          </div>
          <div class="page-header-actions">
            <app-btn variant="ghost" (click)="back()">
              <app-icon name="chevL" [size]="14" />
              {{ 'dress.edit.back' | translate }}
            </app-btn>
            <app-chip [kind]="statusChipKind(d.status)">{{ d.status | uppercase }}</app-chip>
            @if (d.status !== 'live') {
              <app-btn variant="ghost" [disabled]="saving()" (click)="saveDraft(d.id)">
                {{ 'dress.edit.saveDraft' | translate }}
              </app-btn>
              <app-btn variant="primary" [disabled]="saving()" (click)="publish(d.id)">
                {{ 'dress.edit.publish' | translate }}
              </app-btn>
            }
          </div>
        </header>

        <!-- PDF viewer -->
        <section class="card card-pad" style="margin-bottom: 16px;">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'dress.edit.pdfTitle' | translate }}
          </div>
          @if (pdfUrl()) {
            <div style="margin-top: 10px; display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
              <a
                [href]="pdfUrl()"
                target="_blank"
                rel="noopener noreferrer"
                style="display: inline-flex; align-items: center; gap: 6px; font-size: 13px;
                       padding: 6px 14px; border-radius: 6px; background: var(--surface-3);
                       color: var(--text-primary); text-decoration: none; border: 1px solid var(--line-strong);"
              >
                <app-icon name="pdf" [size]="14" />
                {{ 'dress.edit.viewPdf' | translate }}
              </a>
              <span class="mono-tag">{{ d.id }}.pdf</span>
            </div>
          } @else {
            <p class="muted" style="margin-top: 8px; font-size: 13px;">
              {{ 'dress.edit.noPdf' | translate }}
            </p>
          }
        </section>

        <!-- Rule editors via review pane -->
        <app-dress-review-pane
          [dressId]="d.id"
          [initMandatory]="d.mandatoryRules"
          [initOptional]="d.optionalLogic"
          [initBranchOverrides]="d.branchOverrides"
          [showActions]="false"
        />

        <!-- Change history -->
        <section class="card card-pad" style="margin-top: 16px;">
          <button class="acc-head" type="button" (click)="historyOpen.set(!historyOpen())">
            <div class="eyebrow" style="color: var(--gold);">
              {{ 'dress.history.title' | translate }}
            </div>
            <app-chip>
              {{ 'dress.history.editsFormat' | translate: { n: history().length } }}
            </app-chip>
            <app-icon [name]="historyOpen() ? 'chevU' : 'chevD'" [size]="14" />
          </button>
          @if (historyOpen()) {
            @if (history().length === 0) {
              <p class="muted" style="font-size: 13px; margin-top: 12px;">
                {{ 'dress.history.empty' | translate }}
              </p>
            } @else {
              <ul class="history-list">
                @for (h of history(); track $index) {
                  <li class="history-row">
                    <span class="mono-tag">{{ h.t }}</span>
                    <span class="history-who">{{ h.who }}</span>
                    <span class="history-change">{{ h.action }}</span>
                  </li>
                }
              </ul>
            }
          }
        </section>
      }
    </div>
  `,
})
export class DressEditComponent {
  private svc     = inject(FirestoreDataService);
  private storage = inject(StorageDataService);
  private route   = inject(ActivatedRoute);
  private router  = inject(Router);
  private toast   = inject(ToastService);
  private t       = inject(TranslateService);

  readonly dresses     = toSignal(this.svc.dresses(), { initialValue: [] as Dress[] });
  readonly historyOpen = signal(false);
  readonly saving      = signal(false);
  readonly pdfUrl      = signal<string>('');

  readonly paramMap = toSignal(this.route.paramMap, { initialValue: this.route.snapshot.paramMap });

  readonly dress = computed<Dress | undefined>(() => {
    const id = this.paramMap().get('id');
    if (!id) return undefined;
    const found = this.dresses().find((d) => d.id === id);
    // Populate pdfUrl from the Firestore doc field first; fall back to Storage lookup
    if (found?.pdfUrl && !this.pdfUrl()) {
      this.pdfUrl.set(found.pdfUrl);
    } else if (found && !found.pdfUrl && !this.pdfUrl()) {
      this.storage.getDressPdfUrl(id).then((url) => this.pdfUrl.set(url)).catch(() => {});
    }
    return found;
  });

  // Real change history — switches when route param changes
  readonly history = toSignal(
    this.route.paramMap.pipe(
      switchMap((pm) => {
        const id = pm.get('id') ?? '';
        return this.svc.dressHistory(id);
      }),
    ),
    { initialValue: [] as ActivityEntry[] },
  );

  statusChipKind(status: Dress['status']): 'gold' | 'warn' | 'default' {
    if (status === 'live') return 'gold';
    if (status === 'placeholder') return 'warn';
    return 'default';
  }

  async saveDraft(id: string): Promise<void> {
    this.saving.set(true);
    try {
      await this.svc.updateDress(id, { doctrine_status: 'stub_pending_pdf' });
      await this.svc.addActivityLog('Saved draft', id);
      this.toast.info(this.t.instant('dress.edit.toast.draftSaved'));
    } catch {
      this.toast.error(this.t.instant('dress.edit.toast.saveError'));
    } finally {
      this.saving.set(false);
    }
  }

  async publish(id: string): Promise<void> {
    this.saving.set(true);
    try {
      await this.svc.updateDress(id, { doctrine_status: 'pdf_aligned' });
      await this.svc.addActivityLog('Published dress', id);
      this.toast.success(this.t.instant('dress.edit.toast.published'));
    } catch {
      this.toast.error(this.t.instant('dress.edit.toast.saveError'));
    } finally {
      this.saving.set(false);
    }
  }

  back(): void {
    this.router.navigateByUrl('/dress');
  }
}
