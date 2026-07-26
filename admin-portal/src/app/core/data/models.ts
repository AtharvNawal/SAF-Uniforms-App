// TypeScript shapes used by the admin portal's data services.
// FirestoreDataService returns the same Observable<T> shapes so
// consuming screens stay unchanged after the mock→Firestore swap.

export type DressStatus = 'live' | 'placeholder' | 'draft';
export type CoverageStatus = 'live' | 'placeholder' | 'pending' | 'missing';
export type Platform = 'iOS' | 'Android';
export type Gender = 'M' | 'F' | 'All';
export type AdminRole = 'super' | 'admin';

export interface Branch {
  id: 'army' | 'navy' | 'rsaf' | 'dis';
  name: string;
  short: string;
  color: string;
  base: string;
}

export interface DressCode {
  code: string;
  id: string;
  title: string;
  subtitle: string;
}

export interface Dress {
  id: string;
  code: string;
  name: string;
  status: DressStatus;
  overrides: number;
  mandatory: number;
  optional: number;
  branches: string[];
  pdfUrl?:         string;
  mandatoryRules:  string[];
  optionalLogic:   Record<string, unknown>;
  branchOverrides: Record<string, unknown>;
}

export interface DressWritePayload {
  dress_name?:       string;
  display_name?:     string;
  doctrine_status?:  string;
  pdf_url?:          string;
  mandatory_rules?:  string[];
  optional_logic?:   Record<string, unknown>;
  branch_overrides?: Record<string, unknown>;
}

export type Coverage = Record<Branch['id'], CoverageStatus[]>;

export interface Accessory {
  id: string;
  name: string;
  cat: string;
  branch: 'army' | 'navy' | 'rsaf' | 'dis' | 'all';
  gender: Gender;
  img: boolean;
  glb: boolean;
  place: boolean;
  legacy: boolean;
  imageUrl?: string;
  placementUrl?: string;
}

export interface AccessoryWritePayload {
  display_name?: string;
  category?: string;
  branch_id?: string;
  gender?: string;
  active?: boolean;
  anchor?: string;
  image_url?: string;
  placement_diagram?: string;
}

export interface ActivityEntry {
  who: string;
  action: string;
  target: string;
  t: string;
}

export interface AppUser {
  uid: string;
  dev: string;
  plat: Platform;
  branch: Branch['id'];
  complete: boolean;
  seen: string;
  // Optional fields populated from users/{uid}/profile/current subcollection
  rank?: string;
  gender?: string;
  dressCode?: string;
  fullName?: string;
  vocation?: string;
  medalRows?: number;
  isSikh?: boolean;
}

export interface AdminAccount {
  uid: string;   // Firebase Auth UID — same as Firestore document ID
  name: string;
  email: string;
  role: AdminRole;
  initials: string;
  created: string;
  last: string;
  active: boolean;
}

export interface LogicRule {
  id: string;
  desc: string;
  params: Record<string, unknown>;
  active: boolean;
  version: string;
  modified: string;
}

// Result of a client-side GLB socket node check
export interface SocketCheckResult {
  found: string[];
  missing: string[];
}

// 3D body model metadata derived from Firebase Storage listing
export interface BodyModel {
  id: string;           // e.g. 'male_apose'
  title: string;        // e.g. 'Male A-pose'
  gender: 'M' | 'F';
  status: 'delivered' | 'placeholder';
  storagePath: string;  // e.g. 'models/bodies/male_apose.glb'
  size: string;         // e.g. '4.2 MB' — from Storage metadata, '—' if unavailable
  date: string;         // e.g. '2026-04-08 09:12' — from Storage metadata, '—' if unavailable
  socketStatus?: SocketCheckResult;
}

// Uniform matrix status per branch × dress code cell
export type UniformStatus = 'uploaded' | 'missing';
