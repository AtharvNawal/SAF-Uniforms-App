import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { IconComponent } from '../../icon/icon.component';
import { IconBtnComponent } from '../icon-btn/icon-btn.component';
import { ToastService } from '../../../core/toast/toast.service';

interface JsonToken {
  text: string;
  kind: 'key' | 'str' | 'bool' | 'plain';
}

interface JsonLine {
  num: string;
  tokens: JsonToken[];
}

@Component({
  selector: 'app-json-viewer',
  standalone: true,
  imports: [TranslateModule, IconComponent, IconBtnComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="json-editor">
      <header class="je-head">
        <span class="mono-tag dim">{{ 'logic.jsonViewer.header' | translate }}</span>
        <app-icon-btn [ariaLabel]="'logic.jsonViewer.copy' | translate" (click)="copy()">
          <app-icon name="copy" [size]="12" />
        </app-icon-btn>
      </header>
      <pre class="je-pre">
@for (line of lines(); track $index) {
<div class="je-line"><span class="je-ln">{{ line.num }}</span><span class="je-content">@for (tok of line.tokens; track $index) {<span [class.je-key]="tok.kind === 'key'" [class.je-str]="tok.kind === 'str'" [class.je-bool]="tok.kind === 'bool'">{{ tok.text }}</span>}</span></div>
}</pre>
      <footer class="je-foot">
        <span style="color: var(--ok); display: inline-flex;">
          <app-icon name="check" [size]="11" />
        </span>
        <span class="mono-tag dim">{{ 'logic.jsonViewer.valid' | translate }}</span>
      </footer>
    </div>
  `,
})
export class JsonViewerComponent {
  private toast = inject(ToastService);
  private t = inject(TranslateService);

  readonly value = input.required<string>();

  readonly lines = computed<JsonLine[]>(() => {
    return this.value().split('\n').map((line, i) => ({
      num: (i + 1).toString().padStart(2, ' '),
      tokens: this.tokenize(line),
    }));
  });

  private tokenize(line: string): JsonToken[] {
    const out: JsonToken[] = [];
    let i = 0;
    while (i < line.length) {
      if (line[i] === '"') {
        let j = i + 1;
        while (j < line.length && line[j] !== '"') j++;
        const str = line.slice(i, j + 1);
        const after = line.slice(j + 1).trimStart();
        out.push({ text: str, kind: after.startsWith(':') ? 'key' : 'str' });
        i = j + 1;
        continue;
      }
      const m = line.slice(i).match(/^(true|false|null|-?\d+(\.\d+)?)/);
      if (m) {
        out.push({ text: m[0], kind: 'bool' });
        i += m[0].length;
        continue;
      }
      out.push({ text: line[i], kind: 'plain' });
      i++;
    }
    return out;
  }

  async copy(): Promise<void> {
    try {
      await navigator.clipboard.writeText(this.value());
      this.toast.success(this.t.instant('users.toast.uidCopied'));
    } catch {
      /* swallow */
    }
  }
}
