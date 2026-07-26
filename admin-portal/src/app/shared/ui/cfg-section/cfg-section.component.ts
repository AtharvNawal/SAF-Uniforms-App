import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-cfg-section',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="cfg-section">
      <div class="eyebrow">{{ title() }}</div>
      <div style="height: 8px;"></div>
      <ng-content />
    </div>
  `,
  styles: [`:host { display: block; }`],
})
export class CfgSectionComponent {
  readonly title = input.required<string>();
}
