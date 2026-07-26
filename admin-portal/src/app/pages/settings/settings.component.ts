import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { ThemeService, ThemeMode } from '../../core/theme/theme.service';
import {
  PillToggleComponent,
  PillToggleOption,
} from '../../shared/ui/pill-toggle/pill-toggle.component';
import { SelectComponent, SelectOption } from '../../shared/ui/select/select.component';
import { ButtonComponent } from '../../shared/ui/button/button.component';
import { CardComponent } from '../../shared/ui/card/card.component';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [
    FormsModule,
    TranslateModule,
    PillToggleComponent,
    SelectComponent,
    ButtonComponent,
    CardComponent,
    IconComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow">{{ 'settings.eyebrow' | translate }}</div>
          <h1 class="page-title">{{ 'settings.title' | translate }}</h1>
          <p class="page-sub">{{ 'settings.subtitle' | translate }}</p>
        </div>
      </header>

      <app-card>
        <div class="card-head">
          <h2 class="card-title-lg">{{ 'settings.appearanceTitle' | translate }}</h2>
          <p class="muted">{{ 'settings.appearanceSubtitle' | translate }}</p>
        </div>

        <div class="settings-row">
          <div class="settings-row-label">{{ 'settings.themeLabel' | translate }}</div>
          <app-pill-toggle
            [options]="themeOptions()"
            [ngModel]="theme.mode()"
            (ngModelChange)="setTheme($event)"
          />
        </div>

        <div class="settings-row">
          <div class="settings-row-label">{{ 'settings.localeLabel' | translate }}</div>
          <app-select [options]="localeOptions" [ngModel]="locale" disabled />
        </div>
      </app-card>

      <app-card>
        <div class="card-head danger-head">
          <h2 class="card-title-lg">{{ 'settings.dangerTitle' | translate }}</h2>
          <p class="muted">{{ 'settings.dangerSubtitle' | translate }}</p>
        </div>

        <div class="danger-row">
          <div class="danger-row-text">
            <div class="danger-row-title">{{ 'settings.reseedTitle' | translate }}</div>
            <p class="muted">{{ 'settings.reseedBody' | translate }}</p>
          </div>
          <app-btn variant="danger-ghost" [disabled]="true">
            <app-icon name="refresh" [size]="14" />
            {{ 'settings.reseedAction' | translate }}
            <span class="coming-soon">— {{ 'settings.comingSoon' | translate }}</span>
          </app-btn>
        </div>

        <div class="danger-row">
          <div class="danger-row-text">
            <div class="danger-row-title">{{ 'settings.clearCacheTitle' | translate }}</div>
            <p class="muted">{{ 'settings.clearCacheBody' | translate }}</p>
          </div>
          <app-btn variant="danger-ghost" [disabled]="true">
            <app-icon name="trash" [size]="14" />
            {{ 'settings.clearCacheAction' | translate }}
            <span class="coming-soon">— {{ 'settings.comingSoon' | translate }}</span>
          </app-btn>
        </div>
      </app-card>
    </div>
  `,
  styles: [`
    .settings-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 24px;
      padding: 14px 0;
      border-top: 1px solid var(--line);
    }
    .settings-row:first-of-type { border-top: 0; }
    .settings-row-label {
      font-size: 13px;
      font-weight: 500;
      color: var(--ink);
    }

    .danger-head { padding-bottom: 16px; }
    .danger-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 18px;
      padding: 14px 0;
      border-top: 1px solid var(--line);
    }
    .danger-row:first-of-type { border-top: 0; padding-top: 0; }
    .danger-row-text { flex: 1; min-width: 0; }
    .danger-row-title { font-size: 13px; font-weight: 600; color: var(--ink); margin-bottom: 4px; }
    .coming-soon { color: var(--ink-faint); font-weight: 400; margin-left: 6px; }
  `],
})
export class SettingsComponent {
  protected theme = inject(ThemeService);
  private translate = inject(TranslateService);

  readonly locale: string = 'en';

  readonly localeOptions: SelectOption[] = [
    { value: 'en', label: 'English' },
  ];

  readonly themeOptions = computed<PillToggleOption[]>(() => [
    { value: 'dark', label: this.translate.instant('settings.themeDark') },
    { value: 'light', label: this.translate.instant('settings.themeLight') },
    { value: 'system', label: this.translate.instant('settings.themeSystem') },
  ]);

  setTheme(mode: string): void {
    this.theme.setMode(mode as ThemeMode);
  }
}
