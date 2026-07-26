import { inject } from '@angular/core';
import { CanMatchFn, Router, UrlTree } from '@angular/router';
import { AuthService } from './auth.service';

export const authGuard: CanMatchFn = async (): Promise<boolean | UrlTree> => {
  const auth = inject(AuthService);
  const router = inject(Router);

  const user = await auth.ready();
  if (user) return true;
  return router.createUrlTree(['/login']);
};
