import { ChangeDetectionStrategy, Component, ElementRef, input, output, signal, viewChild } from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { IconComponent } from '../../icon/icon.component';

export interface PdfFile {
  name: string;
  size: number;
}

@Component({
  selector: 'app-pdf-dropzone',
  standalone: true,
  imports: [TranslateModule, IconComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div
      class="dropzone dropzone-pdf"
      [class.is-drag]="dragging()"
      [class.has-file]="file()"
      (dragover)="onDragOver($event)"
      (dragleave)="onDragLeave()"
      (drop)="onDrop($event)"
      (click)="onClick()"
    >
      <input
        #fileInput
        type="file"
        accept=".pdf"
        hidden
        (change)="onSelect($event)"
      />

      <div class="dropzone-icon"><app-icon name="pdf" [size]="28" /></div>

      @if (!file()) {
        <p class="dropzone-title">{{ 'dress.add.dropzone.title' | translate }}</p>
        <p class="dropzone-sub">{{ 'dress.add.dropzone.sub' | translate }}</p>
      } @else {
        <p class="dropzone-title">{{ file()!.name }}</p>
        <p class="dropzone-sub">
          {{ (file()!.size / 1024 / 1024).toFixed(2) }} MB ·
          {{ 'dress.add.dropzone.ready' | translate }}
        </p>
        <button
          class="link-btn link-gold"
          type="button"
          style="margin-top: 10px;"
          (click)="remove($event)"
        >
          <app-icon name="close" [size]="12" />
          {{ 'dress.add.dropzone.remove' | translate }}
        </button>
      }
    </div>
  `,
})
export class PdfDropzoneComponent {
  readonly file = input<PdfFile | null>(null);
  readonly fileChange = output<PdfFile | null>();

  readonly dragging = signal(false);
  readonly fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');

  onDragOver(e: DragEvent): void {
    e.preventDefault();
    this.dragging.set(true);
  }

  onDragLeave(): void {
    this.dragging.set(false);
  }

  onDrop(e: DragEvent): void {
    e.preventDefault();
    this.dragging.set(false);
    const f = e.dataTransfer?.files[0];
    if (f) this.fileChange.emit({ name: f.name, size: f.size });
  }

  onSelect(e: Event): void {
    const target = e.target as HTMLInputElement;
    const f = target.files?.[0];
    if (f) this.fileChange.emit({ name: f.name, size: f.size });
  }

  remove(e: Event): void {
    e.stopPropagation();
    this.fileChange.emit(null);
  }

  onClick(): void {
    if (this.file()) return;
    this.fileInput()?.nativeElement.click();
  }
}
