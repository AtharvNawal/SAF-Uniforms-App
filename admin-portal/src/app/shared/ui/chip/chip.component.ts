import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type ChipKind = 'default' | 'gold' | 'navy' | 'warn' | 'err' | 'ok' | 'rsaf';

@Component({
  selector: 'app-chip',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span
      class="chip"
      [class.chip-gold]="kind() === 'gold'"
      [class.chip-navy]="kind() === 'navy'"
      [class.chip-warn]="kind() === 'warn'"
      [class.chip-err]="kind() === 'err'"
      [class.chip-ok]="kind() === 'ok'"
      [class.chip-rsaf]="kind() === 'rsaf'"
    >
      <ng-content />
    </span>
  `,
  styles: [`:host { display: inline-flex; }`],
})
export class ChipComponent {
  readonly kind = input<ChipKind>('default');
}
