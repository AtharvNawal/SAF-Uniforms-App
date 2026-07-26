import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule, FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { IconComponent } from '../../shared/icon/icon.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { ChipComponent } from '../../shared/ui/chip/chip.component';
import { AvatarComponent } from '../../shared/ui/avatar/avatar.component';
import { IconBtnComponent } from '../../shared/ui/icon-btn/icon-btn.component';
import { ToggleComponent } from '../../shared/ui/toggle/toggle.component';
import { FieldComponent } from '../../shared/ui/field/field.component';
import { ModalComponent } from '../../shared/ui/modal/modal.component';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';

import { FirestoreDataService } from '../../core/data/firestore-data.service';
import { ToastService } from '../../core/toast/toast.service';
import { AdminAccount } from '../../core/data/models';

@Component({
  selector: 'app-admins',
  standalone: true,
  imports: [
    FormsModule,
    ReactiveFormsModule,
    TranslateModule,
    IconComponent,
    ButtonComponent,
    ChipComponent,
    AvatarComponent,
    IconBtnComponent,
    ToggleComponent,
    FieldComponent,
    ModalComponent,
    PillToggleComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow" style="color: var(--gold);">
            {{ 'admins.eyebrow' | translate }}
          </div>
          <h1 class="page-title">{{ 'admins.title' | translate }}</h1>
          <p class="page-sub">{{ 'admins.subtitle' | translate }}</p>
        </div>
        <div class="page-header-actions">
          <app-btn variant="primary" (click)="openAdd()">
            <app-icon name="plus" [size]="14" />
            {{ 'admins.addAdmin' | translate }}
          </app-btn>
        </div>
      </header>

      <div class="info-banner">
        <app-icon name="info" [size]="14" />
        <span>{{ 'admins.infoBanner' | translate }}</span>
      </div>

      <section class="card" style="padding: 0;">
        <table class="acc-table">
          <thead>
            <tr>
              <th></th>
              <th>{{ 'admins.col.name' | translate }}</th>
              <th>{{ 'admins.col.email' | translate }}</th>
              <th>{{ 'admins.col.role' | translate }}</th>
              <th>{{ 'admins.col.created' | translate }}</th>
              <th>{{ 'admins.col.lastLogin' | translate }}</th>
              <th>{{ 'admins.col.status' | translate }}</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            @for (a of admins(); track a.email) {
              <tr class="acc-row">
                <td>
                  <app-avatar [initials]="a.initials" [kind]="a.role" [size]="32" />
                </td>
                <td><span class="acc-name">{{ a.name }}</span></td>
                <td><span class="mono-tag">{{ a.email }}</span></td>
                <td>
                  @if (a.role === 'super') {
                    <app-chip kind="gold">{{ 'admins.role.super' | translate }}</app-chip>
                  } @else {
                    <app-chip kind="navy">{{ 'admins.role.admin' | translate }}</app-chip>
                  }
                </td>
                <td><span class="mono-tag dim">{{ a.created }}</span></td>
                <td><span class="mono-tag dim">{{ a.last }}</span></td>
                <td>
                  <app-toggle [ngModel]="a.active" [disabled]="true" />
                </td>
                <td>
                  <app-icon-btn
                    [ariaLabel]="'admins.action.deactivate' | translate"
                    [disabled]="!a.active"
                    (click)="deactivate(a)"
                  >
                    <app-icon name="kebab" [size]="14" />
                  </app-icon-btn>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </section>

      <app-modal
        [open]="addOpen()"
        [title]="'admins.modal.title' | translate"
        (close)="closeAdd()"
      >
        <form [formGroup]="form" class="modal-form" (ngSubmit)="submit()">
          <app-field [label]="'admins.modal.uidLabel' | translate">
            <input
              class="input"
              formControlName="uid"
              [placeholder]="'admins.modal.uidPlaceholder' | translate"
            />
          </app-field>
          <app-field [label]="'admins.modal.nameLabel' | translate">
            <input
              class="input"
              formControlName="name"
              [placeholder]="'admins.modal.namePlaceholder' | translate"
            />
          </app-field>
          <app-field [label]="'admins.modal.emailLabel' | translate">
            <input
              class="input"
              type="email"
              formControlName="email"
              [placeholder]="'admins.modal.emailPlaceholder' | translate"
            />
          </app-field>
          <app-field [label]="'admins.modal.roleLabel' | translate">
            <app-pill-toggle [options]="roleOptions()" formControlName="role" />
          </app-field>

          <div class="modal-foot" style="display: flex; gap: 10px; justify-content: flex-end; padding-top: 8px;">
            <app-btn variant="ghost" (click)="closeAdd()">
              {{ 'admins.modal.cancel' | translate }}
            </app-btn>
            <app-btn variant="primary" type="submit" [disabled]="form.invalid">
              {{ 'admins.modal.submit' | translate }}
            </app-btn>
          </div>
        </form>
      </app-modal>
    </div>
  `,
})
export class AdminsComponent {
  private svc = inject(FirestoreDataService);
  private toast = inject(ToastService);
  private t = inject(TranslateService);
  private fb = inject(FormBuilder);

  readonly admins = toSignal(this.svc.admins(), { initialValue: [] as AdminAccount[] });
  readonly addOpen = signal(false);
  readonly pendingDeactivate = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    uid:   ['', [Validators.required]],
    name:  ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    role:  ['admin' as 'admin' | 'super', [Validators.required]],
  });

  readonly roleOptions = computed<PillToggleOption[]>(() => [
    { value: 'admin', label: this.t.instant('admins.role.admin') },
    { value: 'super', label: this.t.instant('admins.role.super') },
  ]);

  openAdd(): void {
    this.form.reset({ uid: '', name: '', email: '', role: 'admin' });
    this.addOpen.set(true);
  }

  closeAdd(): void {
    this.addOpen.set(false);
  }

  async submit(): Promise<void> {
    if (this.form.invalid) return;
    const { uid, name, email, role } = this.form.getRawValue();
    try {
      await this.svc.addAdmin(uid, name, email, role);
      await this.svc.addActivityLog('Added admin', email);
      this.toast.success(
        this.t.instant('admins.toast.inviteSent.title'),
        this.t.instant('admins.toast.inviteSent.body'),
      );
      this.closeAdd();
    } catch {
      this.toast.show('error', this.t.instant('admins.toast.addFailed.title'));
    }
  }

  async deactivate(a: AdminAccount): Promise<void> {
    if (this.pendingDeactivate() !== a.uid) {
      this.pendingDeactivate.set(a.uid);
      this.toast.warning(this.t.instant('admins.toast.deactivatePrompt.title', { name: a.name }));
      return;
    }
    try {
      await this.svc.deactivateAdmin(a.uid);
      await this.svc.addActivityLog('Deactivated admin', a.email);
      this.pendingDeactivate.set(null);
      this.toast.success(this.t.instant('admins.toast.deactivated.title'), a.name);
    } catch {
      this.pendingDeactivate.set(null);
      this.toast.show('error', this.t.instant('admins.toast.deactivateFailed.title'));
    }
  }
}
