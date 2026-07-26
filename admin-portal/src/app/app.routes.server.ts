import { RenderMode, ServerRoute } from '@angular/ssr';

// All admin routes are client-rendered. Firebase Auth state, Firestore
// snapshots, and Storage reads all live in the browser; prerender/SSR
// would either fail (no auth context) or thrash (real-time streams need
// a live client). The SSR server still ships the shell — App Hosting
// just isn't doing per-request rendering for any route.
export const serverRoutes: ServerRoute[] = [
  {
    path: '**',
    renderMode: RenderMode.Client,
  },
];
