import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-branch-dot',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span class="branch-dot" [style.background]="color()"></span>`,
  styles: [`:host { display: inline-flex; }`],
})
export class BranchDotComponent {
  readonly color = input.required<string>();
}
