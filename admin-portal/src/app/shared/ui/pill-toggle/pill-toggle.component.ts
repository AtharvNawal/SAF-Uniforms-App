import { ChangeDetectionStrategy, Component, forwardRef, input } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export interface PillToggleOption<T = string> {
  value: T;
  label: string;
}

@Component({
  selector: 'app-pill-toggle',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => PillToggleComponent), multi: true },
  ],
  template: `
    <div class="pill-group" role="tablist">
      @for (opt of options(); track opt.value) {
        <button
          type="button"
          class="pill-btn"
          [class.is-active]="value === opt.value"
          [disabled]="disabled"
          (click)="select(opt.value)"
          role="tab"
          [attr.aria-selected]="value === opt.value"
        >
          {{ opt.label }}
        </button>
      }
    </div>
  `,
  styles: [`:host { display: inline-flex; }`],
})
export class PillToggleComponent implements ControlValueAccessor {
  readonly options = input.required<PillToggleOption[]>();

  value: string = '';
  disabled = false;

  private _onChange: (v: string) => void = () => {};
  private _onTouched: () => void = () => {};

  writeValue(v: string | null): void {
    this.value = v ?? '';
  }
  registerOnChange(fn: (v: string) => void): void {
    this._onChange = fn;
  }
  registerOnTouched(fn: () => void): void {
    this._onTouched = fn;
  }
  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  select(v: string): void {
    this.value = v;
    this._onChange(v);
    this._onTouched();
  }
}
