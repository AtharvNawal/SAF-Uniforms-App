import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="card" [class.card-pad]="pad()">
      <ng-content />
    </div>
  `,
  styles: [`:host { display: block; }`],
})
export class CardComponent {
  readonly pad = input<boolean>(true);
}
