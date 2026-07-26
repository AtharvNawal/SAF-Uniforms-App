import { Injectable, signal } from '@angular/core';

export type ToastKind = 'success' | 'error' | 'warning' | 'info';

export interface Toast {
  id: string;
  kind: ToastKind;
  title: string;
  sub?: string;
}

const DEFAULT_TTL_MS = 4000;

@Injectable({ providedIn: 'root' })
export class ToastService {
  private _toasts = signal<Toast[]>([]);
  readonly toasts = this._toasts.asReadonly();

  show(kind: ToastKind, title: string, sub?: string, ttlMs = DEFAULT_TTL_MS): void {
    const id = `t-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    this._toasts.update((list) => [...list, { id, kind, title, sub }]);
    if (ttlMs > 0) {
      setTimeout(() => this.dismiss(id), ttlMs);
    }
  }

  success(title: string, sub?: string): void {
    this.show('success', title, sub);
  }
  error(title: string, sub?: string): void {
    this.show('error', title, sub);
  }
  warning(title: string, sub?: string): void {
    this.show('warning', title, sub);
  }
  info(title: string, sub?: string): void {
    this.show('info', title, sub);
  }

  dismiss(id: string): void {
    this._toasts.update((list) => list.filter((t) => t.id !== id));
  }

  clear(): void {
    this._toasts.set([]);
  }
}
