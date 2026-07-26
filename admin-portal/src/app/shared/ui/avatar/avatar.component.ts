import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

@Component({
  selector: 'app-avatar',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span
      class="avatar"
      [style.width.px]="size()"
      [style.height.px]="size()"
      [style.fontSize.px]="fontSize()"
      [style.background]="background()"
      [style.color]="color()"
    >
      {{ initials() }}
    </span>
  `,
  styles: [`:host { display: inline-flex; }`],
})
export class AvatarComponent {
  readonly initials = input.required<string>();
  readonly size = input<number>(32);
  readonly kind = input<'admin' | 'super'>('admin');

  readonly fontSize = computed(() => Math.max(10, Math.round(this.size() * 0.36)));

  readonly background = computed(() =>
    this.kind() === 'super'
      ? 'linear-gradient(135deg, #FFCC00, #D4A017)'
      : '#000080',
  );

  readonly color = computed(() => (this.kind() === 'super' ? '#0A0A1F' : '#FFCC00'));
}
