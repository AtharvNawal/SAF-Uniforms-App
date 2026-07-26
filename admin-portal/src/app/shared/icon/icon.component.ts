import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type IconName =
  | 'home' | 'uniform' | 'badge' | 'cube' | 'shield' | 'sliders' | 'users' | 'key'
  | 'gear' | 'exit' | 'bell' | 'search' | 'plus' | 'close' | 'check'
  | 'chevR' | 'chevD' | 'chevL' | 'chevU' | 'kebab' | 'edit' | 'trash'
  | 'upload' | 'download' | 'copy' | 'eye' | 'eyeOff' | 'link' | 'ext' | 'pdf'
  | 'refresh' | 'dot' | 'star' | 'filter' | 'sun' | 'moon' | 'warn' | 'info'
  | 'alert' | 'rotate';

// All 41 icons ported verbatim from
// /tmp/saf-handoff2/saf-uniforms/project/src/admin/icons.jsx
// 1.5px stroke, currentColor, 24×24 viewBox, no fill (except dot).
@Component({
  selector: 'app-icon',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg
      [attr.width]="size()"
      [attr.height]="size()"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      @switch (name()) {
        @case ('home') { <path d="M3 11l9-7 9 7v9a2 2 0 0 1-2 2h-4v-7h-6v7H5a2 2 0 0 1-2-2z"/> }
        @case ('uniform') { <path d="M8 3l-4 3v4l3 1v10h10V11l3-1V6l-4-3-3 2-2 1-3-2z"/> }
        @case ('badge') { <circle cx="12" cy="9" r="5"/><path d="M9 13l-2 8 5-3 5 3-2-8"/> }
        @case ('cube') { <path d="M12 2l9 5v10l-9 5-9-5V7z"/><path d="M3 7l9 5 9-5"/><path d="M12 12v10"/> }
        @case ('shield') { <path d="M12 3l8 3v6c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V6z"/> }
        @case ('sliders') { <path d="M4 6h10M18 6h2M4 12h2M10 12h10M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="8" cy="12" r="2"/><circle cx="18" cy="18" r="2"/> }
        @case ('users') { <circle cx="9" cy="8" r="4"/><path d="M2 21c0-4 3-7 7-7s7 3 7 7"/><circle cx="17" cy="6" r="3"/><path d="M22 19c0-3-2-5-5-5"/> }
        @case ('key') { <circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M16 7l3 3"/> }
        @case ('gear') { <circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.6-2-3.4-2.4.9a7 7 0 0 0-2-1.2L14 3h-4l-.5 2.5a7 7 0 0 0-2 1.2l-2.4-.9-2 3.4 2 1.6A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.6 2 3.4 2.4-.9a7 7 0 0 0 2 1.2L10 21h4l.5-2.5a7 7 0 0 0 2-1.2l2.4.9 2-3.4-2-1.6c.1-.4.1-.8.1-1.2z"/> }
        @case ('exit') { <path d="M15 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4"/><path d="M10 17l-5-5 5-5M5 12h11"/> }
        @case ('bell') { <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/> }
        @case ('search') { <circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/> }
        @case ('plus') { <path d="M12 5v14M5 12h14"/> }
        @case ('close') { <path d="M6 6l12 12M18 6L6 18"/> }
        @case ('check') { <path d="M5 13l4 4L19 7"/> }
        @case ('chevR') { <path d="M9 5l7 7-7 7"/> }
        @case ('chevD') { <path d="M5 9l7 7 7-7"/> }
        @case ('chevL') { <path d="M15 5l-7 7 7 7"/> }
        @case ('chevU') { <path d="M5 15l7-7 7 7"/> }
        @case ('kebab') { <circle cx="12" cy="5" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="12" cy="19" r="1.3"/> }
        @case ('edit') { <path d="M16 3l5 5L8 21H3v-5z"/> }
        @case ('trash') { <path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/> }
        @case ('upload') { <path d="M12 16V4M6 10l6-6 6 6M4 20h16"/> }
        @case ('download') { <path d="M12 4v12M6 12l6 6 6-6M4 20h16"/> }
        @case ('copy') { <rect x="8" y="8" width="13" height="13" rx="2"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/> }
        @case ('eye') { <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/> }
        @case ('eyeOff') { <path d="M3 3l18 18M10.6 6.1A10 10 0 0 1 12 6c6.5 0 10 6 10 6a18 18 0 0 1-3.4 4.3M6.7 6.7C3.8 8.7 2 12 2 12s3.5 6 10 6c1.5 0 2.8-.3 4-.8"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/> }
        @case ('link') { <path d="M10 14a4 4 0 0 1 0-6l3-3a4 4 0 1 1 6 6l-2 2M14 10a4 4 0 0 1 0 6l-3 3a4 4 0 1 1-6-6l2-2"/> }
        @case ('ext') { <path d="M14 3h7v7M21 3l-9 9M19 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h6"/> }
        @case ('pdf') { <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M9 14h1a1.5 1.5 0 0 1 0 3H9zM14 14v3M14 14h2M14 16h1.5M19 14v3M19 14h2M19 15.5h1.5"/> }
        @case ('refresh') { <path d="M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5"/> }
        @case ('dot') { <circle cx="12" cy="12" r="4" fill="currentColor" stroke="none"/> }
        @case ('star') { <path d="M12 3l3 6 6 1-4.5 4 1 6-5.5-3-5.5 3 1-6L3 10l6-1z"/> }
        @case ('filter') { <path d="M3 5h18l-7 9v6l-4-2v-4z"/> }
        @case ('sun') { <circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M5 12H3M21 12h-2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"/> }
        @case ('moon') { <path d="M21 13a9 9 0 1 1-10-10c-.7 4 2 9 10 10z"/> }
        @case ('warn') { <path d="M12 3l10 18H2z"/><path d="M12 10v5M12 18h0"/> }
        @case ('info') { <circle cx="12" cy="12" r="9"/><path d="M12 8h0M11 12h1v5h1"/> }
        @case ('alert') { <circle cx="12" cy="12" r="9"/><path d="M12 7v6M12 16h0"/> }
        @case ('rotate') { <path d="M2 12a10 10 0 0 1 17-7M22 12a10 10 0 0 1-17 7M22 5v5h-5M2 19v-5h5"/> }
      }
    </svg>
  `,
  styles: [`
    :host { display: inline-flex; line-height: 0; }
    svg { display: block; }
  `],
})
export class IconComponent {
  readonly name = input.required<IconName>();
  readonly size = input<number>(16);
}
