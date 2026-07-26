import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-icon-btn',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <button
      class="icon-btn"
      [class.is-active]="active()"
      [type]="type()"
      [disabled]="disabled()"
      [attr.aria-label]="ariaLabel()"
      [attr.title]="ariaLabel()"
    >
      <ng-content />
    </button>
  `,
  styles: [`:host { display: inline-flex; }`],
})
export class IconBtnComponent {
  readonly ariaLabel = input<string>('');
  readonly active = input<boolean>(false);
  readonly disabled = input<boolean>(false);
  readonly type = input<'button' | 'submit'>('button');
}
