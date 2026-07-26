import { ChangeDetectionStrategy, Component, forwardRef } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

@Component({
  selector: 'app-toggle',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => ToggleComponent), multi: true },
  ],
  template: `
    <button
      type="button"
      class="toggle"
      [class.is-on]="value"
      [disabled]="disabled"
      (click)="toggle()"
      [attr.aria-pressed]="value"
    >
      <span class="toggle-track">
        <span class="toggle-thumb"></span>
      </span>
    </button>
  `,
  styles: [`:host { display: inline-flex; }`],
})
export class ToggleComponent implements ControlValueAccessor {
  value = false;
  disabled = false;

  private _onChange: (v: boolean) => void = () => {};
  private _onTouched: () => void = () => {};

  writeValue(v: boolean | null): void {
    this.value = !!v;
  }
  registerOnChange(fn: (v: boolean) => void): void {
    this._onChange = fn;
  }
  registerOnTouched(fn: () => void): void {
    this._onTouched = fn;
  }
  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  toggle(): void {
    this.value = !this.value;
    this._onChange(this.value);
    this._onTouched();
  }
}
