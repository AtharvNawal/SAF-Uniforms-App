import { Injectable, inject } from '@angular/core';
import { Observable, of, forkJoin, combineLatest } from 'rxjs';
import { map, switchMap, take } from 'rxjs/operators';
import {
  Firestore,
  collection,
  collectionData,
  doc,
  docData,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  addDoc,
  query,
  orderBy,
  where,
  limit,
  serverTimestamp,
  Timestamp,
} from '@angular/fire/firestore';
import { Auth } from '@angular/fire/auth';
import { StorageDataService } from './storage-data.service';
import {
  Branch,
  DressCode,
  Dress,
  DressStatus,
  DressWritePayload,
  Coverage,
  CoverageStatus,
  Accessory,
  AccessoryWritePayload,
  Gender,
  ActivityEntry,
  AppUser,
  AdminAccount,
  LogicRule,
} from './models';

// ---------------------------------------------------------------------------
// Static constants — display metadata that lives in the app, not Firestore
// ---------------------------------------------------------------------------

const BRANCHES: Branch[] = [
  { id: 'army', name: 'Army', short: 'ARMY', color: '#6A8F4D', base: '#3A5A3A' },
  { id: 'navy', name: 'Navy', short: 'NAVY', color: '#3A6EA5', base: '#14213D' },
  { id: 'rsaf', name: 'RSAF', short: 'RSAF', color: '#7FC1EC', base: '#2F7FBF' },
  { id: 'dis',  name: 'DIS',  short: 'DIS',  color: '#8A9099', base: '#4A4F55' },
];

const DRESS_CODES: DressCode[] = [
  { code: 'No.1', id: 'no1', title: 'Ceremonial White',   subtitle: 'Full ceremonial with medals & sash' },
  { code: 'No.2', id: 'no2', title: 'Ceremonial Working', subtitle: 'Senior ceremonial, no sash' },
  { code: 'No.3', id: 'no3', title: 'Service Dress',      subtitle: 'Standard working dress with rank slides' },
  { code: 'No.4', id: 'no4', title: 'SAF Tee',            subtitle: 'Light combat / training' },
  { code: 'No.5', id: 'no5', title: 'Combat Smart 4',     subtitle: 'Field combat with full webbing' },
];

const SOCKETS = [
  'head_top', 'chest_left', 'chest_right', 'collar_left', 'collar_right',
  'shoulder_left', 'shoulder_right', 'sleeve_left', 'sleeve_right',
  'waist_front', 'waist_back', 'hip_left', 'hip_right', 'name_plate',
];

// Map dress_requirements doc ID → short dress code string
const DRESS_CODE_MAP: Record<string, string> = {
  no_1_dress_requirements: 'No.1',
  no_2_dress_requirements: 'No.2',
  no_3_dress_requirements: 'No.3',
  no_4_dress_requirements: 'No.4',
  no_5_dress_requirements: 'No.5',
};

// ---------------------------------------------------------------------------
// BranchCfg shape (mirrors branches.component.ts local interface)
// ---------------------------------------------------------------------------

export interface BranchCfg {
  collar: number;
  anchor: string;
  offX: number;
  offY: number;
  sikh: boolean;
  sikhColor: string;
  align: 'none' | 'forward' | 'back' | 'center';
  version: string;
  codes: string[];
  updatedAt?: string;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

@Injectable({ providedIn: 'root' })
export class FirestoreDataService {
  private firestore = inject(Firestore);
  private auth      = inject(Auth);
  private storage   = inject(StorageDataService);

  // -------------------------------------------------------------------------
  // Static streams — no Firestore read needed
  // -------------------------------------------------------------------------

  branches(): Observable<Branch[]> {
    return of(BRANCHES);
  }

  dressCodes(): Observable<DressCode[]> {
    return of(DRESS_CODES);
  }

  sockets(): Observable<string[]> {
    return of(SOCKETS);
  }

  // -------------------------------------------------------------------------
  // Accessory library — Firestore + Storage GLB detection
  // -------------------------------------------------------------------------

  accessories(): Observable<Accessory[]> {
    return combineLatest([
      this.accessoriesRaw(),
      this.storage.accessoryGlbSet(),
    ]).pipe(
      map(([docs, glbSet]) => docs.map((d) => this.mapAccessory(d, glbSet))),
    );
  }

  accessoryCategories(): Observable<string[]> {
    return this.accessoriesRaw().pipe(
      map((docs) => [...new Set(docs.map((d) => d['category'] as string))].sort()),
    );
  }

  private accessoriesRaw(): Observable<Record<string, unknown>[]> {
    return collectionData(
      collection(this.firestore, 'accessory_library'),
      { idField: 'id' },
    ) as Observable<Record<string, unknown>[]>;
  }

  private mapAccessory(d: Record<string, unknown>, glbSet: Set<string>): Accessory {
    const imageUrl = (d['image_url'] as string) || undefined;
    const placementUrl = (d['placement_diagram'] as string) || undefined;
    return {
      id:           d['id'] as string,
      name:         (d['display_name'] as string) ?? '',
      cat:          (d['category'] as string) ?? '',
      branch:       this.mapBranchId(d['branch_id'] as string | undefined),
      gender:       this.mapGender(d['gender'] as string | undefined),
      img:          !!imageUrl,
      glb:          glbSet.has(d['id'] as string),
      place:        !!placementUrl,
      legacy:       !!(d['render_logic'] as Record<string, unknown> | undefined)?.['legacy_placeholder'],
      imageUrl,
      placementUrl,
    };
  }

  private mapBranchId(raw: string | undefined): Accessory['branch'] {
    if (raw === 'army' || raw === 'navy' || raw === 'rsaf' || raw === 'dis') return raw;
    return 'all';
  }

  private mapGender(raw: string | undefined): Gender {
    if (raw === 'M' || raw === 'male') return 'M';
    if (raw === 'F' || raw === 'female') return 'F';
    return 'All';
  }

  // -------------------------------------------------------------------------
  // Dress requirements
  // -------------------------------------------------------------------------

  dresses(): Observable<Dress[]> {
    return (
      collectionData(
        collection(this.firestore, 'dress_requirements'),
        { idField: 'id' },
      ) as Observable<Record<string, unknown>[]>
    ).pipe(map((docs) => docs.map((d) => this.mapDress(d))));
  }

  private mapDress(d: Record<string, unknown>): Dress {
    const id = d['id'] as string;
    const mandatoryRules  = (d['mandatory_rules']  as string[]              ) ?? [];
    const optionalLogic   = (d['optional_logic']   as Record<string, unknown>) ?? {};
    const branchOverrides = (d['branch_overrides'] as Record<string, unknown>) ?? {};
    return {
      id,
      code:            DRESS_CODE_MAP[id] ?? (d['dress_name'] as string) ?? id,
      name:            (d['display_name'] as string) ?? (d['dress_name'] as string) ?? id,
      status:          this.mapDressStatus(d['doctrine_status'] as string | undefined),
      overrides:       Object.keys(branchOverrides).length,
      mandatory:       mandatoryRules.length,
      optional:        Object.keys(optionalLogic).length,
      branches:        ['army', 'navy', 'rsaf', 'dis'],
      pdfUrl:          (d['pdf_url'] as string) || undefined,
      mandatoryRules,
      optionalLogic,
      branchOverrides,
    };
  }

  private mapDressStatus(s: string | undefined): DressStatus {
    if (s === 'pdf_aligned') return 'live';
    if (s === 'stub_pending_pdf') return 'placeholder';
    return 'draft';
  }

  // -------------------------------------------------------------------------
  // Coverage — derived from dress_requirements doctrine_status
  // -------------------------------------------------------------------------

  coverage(): Observable<Coverage> {
    return this.dresses().pipe(
      map((dresses) => {
        const orderedCodes = ['No.1', 'No.2', 'No.3', 'No.4', 'No.5'];
        const row = (branchId: Branch['id']): CoverageStatus[] =>
          orderedCodes.map((code) => {
            const d = dresses.find((dr) => dr.code === code);
            if (!d) return 'missing';
            return this.dressStatusToCoverage(d.status);
          });
        return {
          army: row('army'),
          navy: row('navy'),
          rsaf: row('rsaf'),
          dis:  row('dis'),
        };
      }),
    );
  }

  private dressStatusToCoverage(s: DressStatus): CoverageStatus {
    if (s === 'live') return 'live';
    if (s === 'placeholder') return 'placeholder';
    return 'missing';
  }

  // -------------------------------------------------------------------------
  // Logic rules
  // -------------------------------------------------------------------------

  logicRules(): Observable<LogicRule[]> {
    return (
      collectionData(
        collection(this.firestore, 'global_logic_rules'),
        { idField: 'id' },
      ) as Observable<Record<string, unknown>[]>
    ).pipe(map((docs) => docs.map((d) => this.mapLogicRule(d))));
  }

  private mapLogicRule(d: Record<string, unknown>): LogicRule {
    return {
      id:       d['id'] as string,
      desc:     (d['description'] as string) ?? '',
      params:   (d['params'] as Record<string, unknown>) ?? {},
      active:   (d['active'] as boolean) ?? true,
      version:  d['version'] != null ? `v${d['version']}` : 'v1',
      modified: this.formatTimestamp(d['updatedAt'] as Timestamp | undefined),
    };
  }

  // -------------------------------------------------------------------------
  // App users — users collection + profile/current subcollection
  // NOTE: N+1 reads (one per user). Acceptable at current scale.
  // For large user counts, denormalise branch/profileComplete into users/{uid}.
  // -------------------------------------------------------------------------

  appUsers(): Observable<AppUser[]> {
    const usersCol = collection(this.firestore, 'users');
    return (
      collectionData(usersCol, { idField: 'uid' }) as Observable<Record<string, unknown>[]>
    ).pipe(
      switchMap((userDocs) => {
        if (!userDocs.length) return of([] as AppUser[]);
        const profileFetches = userDocs.map((u) =>
          (
            docData(
              doc(this.firestore, `users/${u['uid']}/profile/current`),
            ) as Observable<Record<string, unknown> | undefined>
          ).pipe(
            take(1),
            map((profile) => this.mapAppUser(u, profile)),
          ),
        );
        return forkJoin(profileFetches);
      }),
    );
  }

  private mapAppUser(
    u: Record<string, unknown>,
    profile: Record<string, unknown> | undefined,
  ): AppUser {
    const platform = (u['platform'] as string | undefined);
    return {
      uid:      u['uid'] as string,
      dev:      (u['hardwareId'] as string) ?? '—',
      plat:     platform === 'android' ? 'Android' : 'iOS',
      branch:   this.mapBranchId(profile?.['branch'] as string | undefined) as Branch['id'],
      complete: !!(profile?.['fullName'] && profile?.['rank'] && profile?.['branch']),
      seen:     this.relativeTime(u['lastSeenAt'] as Timestamp | undefined),
      rank:     profile?.['rank'] as string | undefined,
      gender:   profile?.['gender'] as string | undefined,
      dressCode: profile?.['dressCode'] as string | undefined,
      fullName: profile?.['fullName'] as string | undefined,
      vocation: profile?.['vocation'] as string | undefined,
      medalRows: profile?.['medalRowCount'] as number | undefined,
      isSikh:   profile?.['isSikh'] as boolean | undefined,
    };
  }

  // -------------------------------------------------------------------------
  // Admin accounts
  // -------------------------------------------------------------------------

  admins(): Observable<AdminAccount[]> {
    return (
      collectionData(
        collection(this.firestore, 'admin_accounts'),
        { idField: 'uid' },
      ) as Observable<Record<string, unknown>[]>
    ).pipe(map((docs) => docs.map((d) => this.mapAdmin(d))));
  }

  private mapAdmin(d: Record<string, unknown>): AdminAccount {
    const lastLogin = d['lastLogin'] as Timestamp | null | undefined;
    return {
      uid:      d['uid'] as string,
      name:     (d['name'] as string) ?? '',
      email:    (d['email'] as string) ?? '',
      role:     ((d['role'] as string) ?? 'admin') as 'super' | 'admin',
      initials: (d['initials'] as string) ?? '',
      created:  this.formatTimestamp(d['createdAt'] as Timestamp | undefined),
      last:     lastLogin ? this.relativeTime(lastLogin) : 'Never',
      active:   (d['active'] as boolean) ?? true,
    };
  }

  // -------------------------------------------------------------------------
  // Activity log
  // -------------------------------------------------------------------------

  activity(): Observable<ActivityEntry[]> {
    const q = query(
      collection(this.firestore, 'activity_log'),
      orderBy('timestamp', 'desc'),
      limit(20),
    );
    return (
      collectionData(q, { idField: 'id' }) as Observable<Record<string, unknown>[]>
    ).pipe(
      map((docs) =>
        docs.map((d) => ({
          who:    (d['who'] as string) ?? '?',
          action: (d['action'] as string) ?? '',
          target: (d['target'] as string) ?? '',
          t:      this.relativeTime(d['timestamp'] as Timestamp | undefined),
        })),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Branch configs — read (used by branches page on init)
  // -------------------------------------------------------------------------

  branchConfigs(): Observable<Record<Branch['id'], BranchCfg>> {
    return (
      collectionData(
        collection(this.firestore, 'branch_configs'),
        { idField: 'id' },
      ) as Observable<Record<string, unknown>[]>
    ).pipe(
      map((docs) => {
        const result: Partial<Record<Branch['id'], BranchCfg>> = {};
        for (const d of docs) {
          const id = d['id'] as Branch['id'];
          if (id === 'army' || id === 'navy' || id === 'rsaf' || id === 'dis') {
            result[id] = this.mapBranchCfg(d);
          }
        }
        return result as Record<Branch['id'], BranchCfg>;
      }),
    );
  }

  private mapBranchCfg(d: Record<string, unknown>): BranchCfg {
    const sikh = d['sikhTurbanLogic'] as Record<string, unknown> | undefined;
    const ladies = d['ladiesMedalAnchor'] as Record<string, unknown> | undefined;
    const ladiesOffset = ladies?.['offsetCm'] as Record<string, unknown> | undefined;
    return {
      collar:    (d['collarOffsetCm'] as number) ?? 2.0,
      anchor:    (ladies?.['anchor'] as string) ?? 'chest_left_f',
      offX:      (ladiesOffset?.['x'] as number) ?? 0,
      offY:      (ladiesOffset?.['y'] as number) ?? 0,
      sikh:      (sikh?.['replacesHeadgear'] as boolean) ?? false,
      sikhColor: (sikh?.['color'] as string) ?? '#000000',
      align:     ((sikh?.['alignmentOverride'] as string) ?? 'none') as BranchCfg['align'],
      version:   d['version'] != null ? `v${d['version']}` : 'v1',
      codes:     (d['dressCodes'] as string[]) ?? [],
      updatedAt: this.formatTimestamp(d['updatedAt'] as Timestamp | undefined),
    };
  }

  // -------------------------------------------------------------------------
  // Write methods
  // -------------------------------------------------------------------------

  galleryCount(uid: string): Observable<number> {
    return (
      collectionData(collection(this.firestore, `users/${uid}/gallery`)) as Observable<
        Record<string, unknown>[]
      >
    ).pipe(map((docs) => docs.length));
  }

  async deleteDress(id: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `dress_requirements/${id}`));
  }

  async createDress(id: string, data: DressWritePayload): Promise<void> {
    const ref = doc(this.firestore, `dress_requirements/${id}`);
    const existing = await getDoc(ref);
    if (existing.exists()) throw new Error('ID already exists');
    await setDoc(ref, {
      dress_name:       data.dress_name      ?? '',
      display_name:     data.display_name    ?? '',
      doctrine_status:  data.doctrine_status ?? 'stub_pending_pdf',
      pdf_url:          data.pdf_url         ?? '',
      mandatory_rules:  data.mandatory_rules ?? [],
      optional_logic:   data.optional_logic  ?? {},
      branch_overrides: data.branch_overrides ?? {},
      createdAt:        serverTimestamp(),
      updatedAt:        serverTimestamp(),
    });
  }

  async updateDress(id: string, data: Partial<DressWritePayload>): Promise<void> {
    const payload: Record<string, unknown> = { updatedAt: serverTimestamp() };
    if (data.display_name     !== undefined) payload['display_name']     = data.display_name;
    if (data.doctrine_status  !== undefined) payload['doctrine_status']  = data.doctrine_status;
    if (data.pdf_url          !== undefined) payload['pdf_url']          = data.pdf_url;
    if (data.mandatory_rules  !== undefined) payload['mandatory_rules']  = data.mandatory_rules;
    if (data.optional_logic   !== undefined) payload['optional_logic']   = data.optional_logic;
    if (data.branch_overrides !== undefined) payload['branch_overrides'] = data.branch_overrides;
    await updateDoc(doc(this.firestore, `dress_requirements/${id}`), payload);
  }

  dressHistory(dressId: string): Observable<ActivityEntry[]> {
    const q = query(
      collection(this.firestore, 'activity_log'),
      where('target', '==', dressId),
      orderBy('timestamp', 'desc'),
      limit(50),
    );
    return (
      collectionData(q, { idField: 'id' }) as Observable<Record<string, unknown>[]>
    ).pipe(
      map((docs) =>
        docs.map((d) => ({
          who:    (d['who']    as string) ?? '?',
          action: (d['action'] as string) ?? '',
          target: (d['target'] as string) ?? '',
          t:      this.relativeTime(d['timestamp'] as Timestamp | undefined),
        })),
      ),
    );
  }

  async saveLogicRule(id: string, rule: LogicRule): Promise<void> {
    const versionNum = rule.version
      ? parseInt(rule.version.replace('v', ''), 10)
      : 1;
    await updateDoc(doc(this.firestore, `global_logic_rules/${id}`), {
      description: rule.desc,
      params:      rule.params,
      active:      rule.active,
      version:     versionNum,
      updatedAt:   serverTimestamp(),
    });
  }

  async createLogicRule(
    id: string,
    desc: string,
    params: Record<string, unknown>,
  ): Promise<void> {
    await setDoc(doc(this.firestore, `global_logic_rules/${id}`), {
      description: desc,
      params,
      active:    true,
      version:   1,
      updatedAt: serverTimestamp(),
    });
  }

  async deleteLogicRule(id: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `global_logic_rules/${id}`));
  }

  async saveBranchConfig(branchId: string, cfg: BranchCfg): Promise<void> {
    const versionNum = cfg.version ? parseInt(cfg.version.replace('v', ''), 10) : 1;
    await updateDoc(doc(this.firestore, `branch_configs/${branchId}`), {
      collarOffsetCm: cfg.collar,
      ladiesMedalAnchor: {
        anchor: cfg.anchor,
        offsetCm: { x: cfg.offX, y: cfg.offY },
      },
      sikhTurbanLogic: {
        replacesHeadgear:  cfg.sikh,
        color:             cfg.sikhColor,
        alignmentOverride: cfg.align,
      },
      dressCodes: cfg.codes,
      version:    versionNum + 1,
      updatedAt:  serverTimestamp(),
    });
  }

  // -------------------------------------------------------------------------
  // Accessory library write methods
  // -------------------------------------------------------------------------

  async createAccessory(id: string, data: AccessoryWritePayload): Promise<void> {
    const ref = doc(this.firestore, `accessory_library/${id}`);
    const existing = await getDoc(ref);
    if (existing.exists()) throw new Error('ID already exists');
    await setDoc(ref, {
      display_name:     data.display_name ?? '',
      category:         data.category ?? '',
      branch_id:        data.branch_id === 'all' ? null : (data.branch_id ?? null),
      gender:           data.gender === 'All' ? null : (data.gender ?? null),
      active:           data.active ?? true,
      render_logic:     { anchor: data.anchor ?? '' },
      image_url:        '',
      placement_diagram: '',
      createdAt:        serverTimestamp(),
      updatedAt:        serverTimestamp(),
    });
  }

  async updateAccessory(id: string, data: Partial<AccessoryWritePayload>): Promise<void> {
    const payload: Record<string, unknown> = { updatedAt: serverTimestamp() };
    if (data.display_name  !== undefined) payload['display_name']     = data.display_name;
    if (data.category      !== undefined) payload['category']         = data.category;
    if (data.branch_id     !== undefined) payload['branch_id']        = data.branch_id === 'all' ? null : data.branch_id;
    if (data.gender        !== undefined) payload['gender']           = data.gender === 'All' ? null : data.gender;
    if (data.active        !== undefined) payload['active']           = data.active;
    if (data.anchor        !== undefined) payload['render_logic.anchor'] = data.anchor;
    if (data.image_url     !== undefined) payload['image_url']        = data.image_url;
    if (data.placement_diagram !== undefined) payload['placement_diagram'] = data.placement_diagram;
    await updateDoc(doc(this.firestore, `accessory_library/${id}`), payload);
  }

  async deleteAccessory(id: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `accessory_library/${id}`));
  }

  async addAdmin(
    uid: string,
    name: string,
    email: string,
    role: 'super' | 'admin',
  ): Promise<void> {
    const initials = name
      .split(' ')
      .map((w) => w[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
    await setDoc(doc(this.firestore, `admin_accounts/${uid}`), {
      name,
      email,
      role,
      initials,
      createdAt: serverTimestamp(),
      lastLogin: null,
      active:    true,
    });
  }

  async deactivateAdmin(uid: string): Promise<void> {
    await updateDoc(doc(this.firestore, `admin_accounts/${uid}`), {
      active: false,
    });
  }

  async addActivityLog(action: string, target: string): Promise<void> {
    const user = this.auth.currentUser;
    if (!user) return;
    const displayName = user.displayName ?? user.email ?? 'Admin';
    const who = displayName
      .split(/[\s.@]/)
      .filter((p) => p.length > 0)
      .map((p) => p[0].toUpperCase())
      .join('')
      .slice(0, 2);
    try {
      await addDoc(collection(this.firestore, 'activity_log'), {
        who,
        uid:       user.uid,
        action,
        target,
        timestamp: serverTimestamp(),
      });
    } catch {
      // Activity log failure should never surface to the user
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  private formatTimestamp(ts: Timestamp | undefined): string {
    if (!ts) return '—';
    try {
      return ts.toDate().toISOString().slice(0, 16).replace('T', ' ');
    } catch {
      return '—';
    }
  }

  private relativeTime(ts: Timestamp | undefined): string {
    if (!ts) return '—';
    try {
      const diffMs = Date.now() - ts.toMillis();
      const mins = Math.floor(diffMs / 60_000);
      if (mins < 1)  return 'Just now';
      if (mins < 60) return `${mins} min ago`;
      const hours = Math.floor(mins / 60);
      if (hours < 24) return `${hours} hr ago`;
      const days = Math.floor(hours / 24);
      if (days === 1) return 'Yesterday';
      return `${days} days ago`;
    } catch {
      return '—';
    }
  }
}
