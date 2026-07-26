import { ChangeDetectionStrategy, Component, forwardRef, input } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export interface SelectOption<T = string> {
  value: T;
  label: string;
}

@Component({
  selector: 'app-select',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => SelectComponent), multi: true },
  ],
  template: `
    <div class="select-wrap">
      <select
        class="input"
        [value]="value"
        [disabled]="disabled"
        (change)="onChange($event)"
        (blur)="onTouched()"
      >
        @for (opt of options(); track opt.value) {
          <option [value]="opt.value">{{ opt.label }}</option>
        }
      </select>
      <span class="select-chevron" aria-hidden="true">
        <svg viewBox="0 0 10 6" width="10" height="6" fill="none">
          <path d="M1 1l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </span>
    </div>
  `,
  styles: [`:host { display: block; }`],
})
export class SelectComponent implements ControlValueAccessor {
  readonly options = input.required<SelectOption[]>();

  value: string = '';
  disabled = false;

  private _onChange: (v: string) => void = () => {};
  onTouched: () => void = () => {};

  writeValue(v: string | null): void {
    this.value = v ?? '';
  }
  registerOnChange(fn: (v: string) => void): void {
    this._onChange = fn;
  }
  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }
  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  onChange(e: Event): void {
    this.value = (e.target as HTMLSelectElement).value;
    this._onChange(this.value);
  }
}
