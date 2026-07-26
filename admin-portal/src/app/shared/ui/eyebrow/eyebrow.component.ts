import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-eyebrow',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<div class="eyebrow"><ng-content /></div>`,
  styles: [`:host { display: block; }`],
})
export class EyebrowComponent {}
