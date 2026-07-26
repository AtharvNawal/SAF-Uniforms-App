import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-field',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <label class="field">
      @if (label()) { <span class="field-label">{{ label() }}</span> }
      <ng-content />
      @if (hint()) { <span class="field-hint">{{ hint() }}</span> }
    </label>
  `,
  styles: [`:host { display: block; }`],
})
export class FieldComponent {
  readonly label = input<string>('');
  readonly hint = input<string>('');
}
