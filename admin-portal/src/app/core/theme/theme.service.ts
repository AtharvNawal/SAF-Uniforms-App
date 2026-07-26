import { Injectable, signal, computed, effect, inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export type ThemeMode = 'dark' | 'light' | 'system';
type Resolved = 'dark' | 'light';

const STORAGE_KEY = 'saf.adminTheme';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);

  private _mode = signal<ThemeMode>(this.readStored());
  readonly mode = this._mode.asReadonly();

  private _systemDark = signal(this.readSystemDark());

  readonly resolved = computed<Resolved>(() => {
    const m = this._mode();
    if (m === 'system') return this._systemDark() ? 'dark' : 'light';
    return m;
  });

  constructor() {
    effect(() => {
      const r = this.resolved();
      if (this.isBrowser) {
        document.documentElement.dataset['theme'] = r;
      }
    });

    if (this.isBrowser) {
      const mq = window.matchMedia('(prefers-color-scheme: dark)');
      const handler = (e: MediaQueryListEvent) => this._systemDark.set(e.matches);
      mq.addEventListener('change', handler);
    }
  }

  setMode(mode: ThemeMode): void {
    this._mode.set(mode);
    if (this.isBrowser) {
      try {
        localStorage.setItem(STORAGE_KEY, mode);
      } catch {
        /* ignore quota / disabled storage */
      }
    }
  }

  private readStored(): ThemeMode {
    if (!this.isBrowser) return 'dark';
    try {
      const v = localStorage.getItem(STORAGE_KEY) as ThemeMode | null;
      if (v === 'dark' || v === 'light' || v === 'system') return v;
    } catch {
      /* ignore */
    }
    return 'dark';
  }

  private readSystemDark(): boolean {
    if (!this.isBrowser) return true;
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
}
