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
import { IconBtnComponent } from '../icon-btn/icon-btn.component';

@Component({
  selector: 'app-drawer',
  standalone: true,
  imports: [IconComponent, IconBtnComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (open()) {
      <div class="drawer-backdrop" (click)="onBackdrop()"></div>
      <aside class="drawer" role="dialog" aria-modal="true">
        <header class="drawer-head">
          <div>
            @if (eyebrow()) {
              <div class="eyebrow" style="color: var(--gold);">{{ eyebrow() }}</div>
            }
            <h2 class="drawer-title">{{ title() }}</h2>
            @if (sub()) {
              <span class="mono-tag">{{ sub() }}</span>
            }
          </div>
          <app-icon-btn (click)="close.emit()" [ariaLabel]="closeLabel()">
            <app-icon name="close" [size]="14" />
          </app-icon-btn>
        </header>
        <ng-content select="[drawerTabs]" />
        <div class="drawer-body">
          <ng-content />
        </div>
        <ng-content select="[drawerFooter]" />
      </aside>
    }
  `,
})
export class DrawerComponent {
  readonly open = input<boolean>(false);
  readonly eyebrow = input<string>('');
  readonly title = input<string>('');
  readonly sub = input<string>('');
  readonly closeLabel = input<string>('Close');
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
