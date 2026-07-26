import { Routes } from '@angular/router';
import { authGuard } from './core/auth/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () =>
      import('./pages/login/login.component').then((m) => m.LoginComponent),
  },
  {
    path: '',
    canMatch: [authGuard],
    loadComponent: () =>
      import('./layout/shell.component').then((m) => m.ShellComponent),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./pages/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      {
        path: 'dress/add',
        loadComponent: () =>
          import('./pages/dress/dress-add.component').then((m) => m.DressAddComponent),
      },
      {
        path: 'dress/:id',
        loadComponent: () =>
          import('./pages/dress/dress-edit.component').then((m) => m.DressEditComponent),
      },
      {
        path: 'dress',
        loadComponent: () =>
          import('./pages/dress/dress-list.component').then((m) => m.DressListComponent),
      },
      {
        path: 'accessories',
        loadComponent: () =>
          import('./pages/accessories/accessories.component').then((m) => m.AccessoriesComponent),
      },
      {
        path: 'models',
        loadComponent: () =>
          import('./pages/models/models.component').then((m) => m.ModelsComponent),
      },
      {
        path: 'branches',
        loadComponent: () =>
          import('./pages/branches/branches.component').then((m) => m.BranchesComponent),
      },
      {
        path: 'logic',
        loadComponent: () =>
          import('./pages/logic/logic.component').then((m) => m.LogicComponent),
      },
      {
        path: 'users',
        loadComponent: () =>
          import('./pages/users/users.component').then((m) => m.UsersComponent),
      },
      {
        path: 'admins',
        loadComponent: () =>
          import('./pages/admins/admins.component').then((m) => m.AdminsComponent),
      },
      {
        path: 'settings',
        loadComponent: () =>
          import('./pages/settings/settings.component').then((m) => m.SettingsComponent),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
