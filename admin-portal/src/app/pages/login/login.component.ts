import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { AuthService } from '../../core/auth/auth.service';
import { ToastService } from '../../core/toast/toast.service';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { FieldComponent } from '../../shared/ui/field/field.component';
import { CardComponent } from '../../shared/ui/card/card.component';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    TranslateModule,
    ButtonComponent,
    FieldComponent,
    CardComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <main class="login-shell">
      <app-card>
        <div class="login-head">
          <div class="login-crest">
            <img src="/saf-crest.png" alt="Singapore Armed Forces" width="96" height="96" />
          </div>
          <div class="eyebrow">{{ 'login.eyebrow' | translate }}</div>
          <h1 class="login-title">{{ 'login.title' | translate }}</h1>
          <p class="login-sub">{{ 'login.subtitle' | translate }}</p>
        </div>

        <form class="login-form" [formGroup]="form" (ngSubmit)="submit()">
          <app-field [label]="'login.emailLabel' | translate">
            <input
              class="input"
              type="email"
              formControlName="email"
              autocomplete="email"
              [placeholder]="'login.emailPlaceholder' | translate"
            />
          </app-field>

          <app-field [label]="'login.passwordLabel' | translate">
            <input
              class="input"
              type="password"
              formControlName="password"
              autocomplete="current-password"
              [placeholder]="'login.passwordPlaceholder' | translate"
            />
          </app-field>

          <app-btn variant="primary" type="submit" [full]="true" [disabled]="busy() || form.invalid">
            {{ (busy() ? 'login.submitting' : 'login.submit') | translate }}
          </app-btn>

          @if (error()) {
            <p class="login-error">{{ error() }}</p>
          }
        </form>
      </app-card>
    </main>
  `,
  styles: [`
    :host { display: block; min-height: 100vh; position: relative; }
    .login-shell {
      position: relative;
      z-index: 1;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .login-shell app-card {
      width: 100%;
      max-width: 420px;
    }
    .login-head {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      text-align: center;
      padding-bottom: 24px;
      border-bottom: 1px solid var(--line);
      margin-bottom: 20px;
    }
    .login-crest {
      margin-bottom: 4px;
    }
    .login-crest img {
      border-radius: 50%;
      box-shadow: 0 0 24px rgba(255, 204, 0, 0.35);
    }
    .login-title {
      font-size: 22px;
      font-weight: 600;
      letter-spacing: -0.3px;
      color: var(--ink);
    }
    .login-sub {
      font-size: 13px;
      color: var(--ink-muted);
      max-width: 320px;
    }
    .login-form {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .login-error {
      color: var(--err);
      font-size: 13px;
      text-align: center;
      margin-top: 4px;
    }
  `],
})
export class LoginComponent {
  private auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);
  private fb = inject(FormBuilder);
  private translate = inject(TranslateService);

  readonly busy = signal(false);
  readonly error = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  async submit(): Promise<void> {
    if (this.form.invalid) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      const { email, password } = this.form.getRawValue();
      const user = await this.auth.signIn(email, password);
      const name = user.displayName ?? email.split('@')[0];
      this.toast.success(this.translate.instant('toast.signedIn', { name }));
      this.router.navigate(['/']);
    } catch (e: unknown) {
      this.error.set(this.mapError(e));
    } finally {
      this.busy.set(false);
    }
  }

  private mapError(e: unknown): string {
    const code = typeof e === 'object' && e && 'code' in e ? String((e as { code: string }).code) : '';
    if (
      code === 'auth/invalid-credential' ||
      code === 'auth/wrong-password' ||
      code === 'auth/user-not-found'
    ) {
      return this.translate.instant('login.errorInvalid');
    }
    if (code === 'auth/network-request-failed') {
      return this.translate.instant('login.errorNetwork');
    }
    return this.translate.instant('login.errorGeneric');
  }
}
