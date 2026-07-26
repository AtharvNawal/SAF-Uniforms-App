import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type BtnVariant = 'primary' | 'ghost' | 'danger' | 'danger-ghost' | 'link' | 'icon';

@Component({
  selector: 'app-btn',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <button
      [type]="type()"
      [class.btn]="variant() !== 'icon' && variant() !== 'link'"
      [class.btn-primary]="variant() === 'primary'"
      [class.btn-ghost]="variant() === 'ghost'"
      [class.btn-danger]="variant() === 'danger'"
      [class.btn-danger-ghost]="variant() === 'danger-ghost'"
      [class.btn-full]="full()"
      [class.icon-btn]="variant() === 'icon'"
      [class.link-btn]="variant() === 'link'"
      [disabled]="disabled()"
    >
      <ng-content />
    </button>
  `,
  styles: [`:host { display: inline-flex; }`],
})
export class ButtonComponent {
  readonly variant = input<BtnVariant>('ghost');
  readonly full = input<boolean>(false);
  readonly disabled = input<boolean>(false);
  readonly type = input<'button' | 'submit'>('button');
}
