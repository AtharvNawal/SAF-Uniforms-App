import { ChangeDetectionStrategy, Component, forwardRef, input } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

let __id = 0;

@Component({
  selector: 'app-input',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => InputComponent), multi: true },
  ],
  template: `
    @if (suffix()) {
      <div class="input-wrap">
        <input
          class="input"
          [id]="inputId"
          [type]="type()"
          [placeholder]="placeholder()"
          [autocomplete]="autocomplete()"
          [disabled]="disabled"
          [value]="value"
          (input)="onInput($event)"
          (blur)="onTouched()"
        />
        <span class="input-suffix">{{ suffix() }}</span>
      </div>
    } @else {
      <input
        class="input"
        [id]="inputId"
        [type]="type()"
        [placeholder]="placeholder()"
        [autocomplete]="autocomplete()"
        [disabled]="disabled"
        [value]="value"
        (input)="onInput($event)"
        (blur)="onTouched()"
      />
    }
  `,
  styles: [`:host { display: block; width: 100%; }`],
})
export class InputComponent implements ControlValueAccessor {
  readonly inputId = `app-input-${++__id}`;

  readonly type = input<'text' | 'email' | 'password' | 'number' | 'search'>('text');
  readonly placeholder = input<string>('');
  readonly autocomplete = input<string>('off');
  readonly suffix = input<string>('');

  value: string | number = '';
  disabled = false;

  private _onChange: (v: string | number) => void = () => {};
  onTouched: () => void = () => {};

  writeValue(v: string | number | null): void {
    this.value = v ?? '';
  }
  registerOnChange(fn: (v: string | number) => void): void {
    this._onChange = fn;
  }
  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }
  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  onInput(e: Event): void {
    const target = e.target as HTMLInputElement;
    this.value = this.type() === 'number' ? target.valueAsNumber : target.value;
    this._onChange(this.value);
  }
}
