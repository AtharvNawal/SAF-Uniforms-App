import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { IconComponent } from '../../shared/icon/icon.component';
import { ToastService } from '../../core/toast/toast.service';

@Component({
  selector: 'app-toast-host',
  standalone: true,
  imports: [IconComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="toast-host" aria-live="polite" aria-atomic="true">
      @for (t of svc.toasts(); track t.id) {
        <div class="toast" [class]="'toast-' + t.kind">
          <span class="toast-icon">
            <app-icon [name]="iconFor(t.kind)" [size]="16" />
          </span>
          <div class="toast-body">
            <div class="toast-title">{{ t.title }}</div>
            @if (t.sub) { <div class="toast-sub">{{ t.sub }}</div> }
          </div>
          <button type="button" class="toast-close" (click)="svc.dismiss(t.id)" aria-label="Dismiss">
            <app-icon name="close" [size]="14" />
          </button>
        </div>
      }
    </div>
  `,
})
export class ToastHostComponent {
  protected svc = inject(ToastService);

  iconFor(kind: 'success' | 'error' | 'warning' | 'info'): 'check' | 'alert' | 'warn' | 'info' {
    switch (kind) {
      case 'success': return 'check';
      case 'error': return 'alert';
      case 'warning': return 'warn';
      case 'info': return 'info';
    }
  }
}
