import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';

@Component({
  selector: 'app-page-stub',
  standalone: true,
  imports: [TranslateModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="page">
      <header class="page-header">
        <div class="page-header-text">
          <div class="eyebrow">{{ eyebrowKey() | translate }}</div>
          <h1 class="page-title">{{ titleKey() | translate }}</h1>
          @if (subKey()) {
            <p class="page-sub">{{ subKey() | translate }}</p>
          }
        </div>
      </header>

      <section class="empty-state">
        <div class="empty-title">{{ 'empty.comingSoon' | translate }}</div>
        <p class="empty-body">{{ 'empty.followUpPlan' | translate }}</p>
      </section>
    </div>
  `,
})
export class PageStubComponent {
  readonly eyebrowKey = input.required<string>();
  readonly titleKey = input.required<string>();
  readonly subKey = input<string>('');
}
