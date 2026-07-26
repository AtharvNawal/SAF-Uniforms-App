import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-empty-state',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="empty-state">
      @if (title()) { <div class="empty-title">{{ title() }}</div> }
      @if (body()) { <p class="empty-body">{{ body() }}</p> }
      <ng-content />
    </section>
  `,
})
export class EmptyStateComponent {
  readonly title = input<string>('');
  readonly body = input<string>('');
}
