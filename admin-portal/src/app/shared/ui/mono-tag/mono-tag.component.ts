import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-mono-tag',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span class="mono-tag" [class.dim]="dim()"><ng-content /></span>`,
  styles: [`:host { display: inline-flex; }`],
})
export class MonoTagComponent {
  readonly dim = input<boolean>(false);
}
