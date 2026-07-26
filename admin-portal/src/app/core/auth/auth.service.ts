import { Injectable, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import {
  Auth,
  authState,
  signInWithEmailAndPassword,
  signOut,
  User,
} from '@angular/fire/auth';
import { Observable, firstValueFrom } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private auth = inject(Auth);

  readonly user$: Observable<User | null> = authState(this.auth);
  readonly user = toSignal(this.user$, { initialValue: null });

  signIn(email: string, password: string): Promise<User> {
    return signInWithEmailAndPassword(this.auth, email, password).then((c) => c.user);
  }

  signOut(): Promise<void> {
    return signOut(this.auth);
  }

  // Resolves once the auth state has emitted at least once — used by the
  // route guard so we don't redirect to /login before Firebase has
  // restored the cached session.
  ready(): Promise<User | null> {
    return firstValueFrom(this.user$);
  }
}
