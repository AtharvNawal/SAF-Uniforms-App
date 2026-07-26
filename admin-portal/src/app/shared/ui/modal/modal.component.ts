import {
  ChangeDetectionStrategy,
  Component,
  HostListener,
  inject,
  input,
  output,
  PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { IconComponent } from '../../icon/icon.component';

@Component({
  selector: 'app-modal',
  standalone: true,
  imports: [IconComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (open()) {
      <div class="modal-backdrop" (click)="onBackdrop()">
        <div class="modal" (click)="$event.stopPropagation()" role="dialog" aria-modal="true">
          @if (title()) {
            <header class="modal-header">
              <h2 class="modal-title">{{ title() }}</h2>
              <button type="button" class="modal-close" (click)="close.emit()" aria-label="Close">
                <app-icon name="close" [size]="16" />
              </button>
            </header>
          }
          <div class="modal-body"><ng-content /></div>
          <ng-content select="[modalFooter]" />
        </div>
      </div>
    }
  `,
})
export class ModalComponent {
  readonly open = input<boolean>(false);
  readonly title = input<string>('');
  readonly closeOnBackdrop = input<boolean>(true);

  readonly close = output<void>();

  private isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  @HostListener('document:keydown.escape')
  onEsc(): void {
    if (this.open() && this.isBrowser) this.close.emit();
  }

  onBackdrop(): void {
    if (this.closeOnBackdrop()) this.close.emit();
  }
}
