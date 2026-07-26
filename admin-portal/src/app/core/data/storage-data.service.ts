import { Injectable, inject } from '@angular/core';
import { Observable, from, of, forkJoin } from 'rxjs';
import { map, catchError, switchMap } from 'rxjs/operators';
import {
  Storage,
  ref,
  listAll,
  getMetadata,
  uploadBytes,
  uploadBytesResumable,
  getDownloadURL,
  deleteObject,
} from '@angular/fire/storage';
import { BodyModel } from './models';

@Injectable({ providedIn: 'root' })
export class StorageDataService {
  private storage = inject(Storage);

  /**
   * Lists all body GLBs under models/bodies/ and returns rich BodyModel records.
   * Calls getMetadata() per item to surface file size and upload date.
   */
  bodyModels(): Observable<BodyModel[]> {
    const bodiesRef = ref(this.storage, 'models/bodies');
    return from(listAll(bodiesRef)).pipe(
      switchMap((result) => {
        if (!result.items.length) return of([] as BodyModel[]);
        return forkJoin(
          result.items.map((item) =>
            from(getMetadata(item)).pipe(
              map((meta) => this.toBodyModel(item.name, meta.size, meta.updated)),
              catchError(() => of(this.toBodyModel(item.name, null, null))),
            ),
          ),
        );
      }),
      catchError(() => of([] as BodyModel[])),
    );
  }

  /**
   * Lists all uniform GLBs under models/uniforms/ and returns a Set of
   * filenames (e.g. 'army_no3_male.glb'). The Models page uses this Set
   * to derive 'uploaded' | 'missing' for each branch × dress code cell.
   */
  uniformMatrix(): Observable<Set<string>> {
    const uniformsRef = ref(this.storage, 'models/uniforms');
    return from(listAll(uniformsRef)).pipe(
      map((result) => new Set(result.items.map((item) => item.name))),
      catchError(() => of(new Set<string>())),
    );
  }

  /**
   * Lists all accessory GLBs under models/accessories/ and returns a Set of
   * accessory IDs (filename without '.glb'). Used by FirestoreDataService to
   * populate the Accessory.glb boolean.
   */
  accessoryGlbSet(): Observable<Set<string>> {
    const accRef = ref(this.storage, 'models/accessories');
    return from(listAll(accRef)).pipe(
      map((result) =>
        new Set(
          result.items
            .map((item) => item.name.replace(/\.glb$/i, ''))
            .filter((name) => name.length > 0),
        ),
      ),
      catchError(() => of(new Set<string>())),
    );
  }

  /**
   * Uploads a PNG to accessories/{id}/image.png or accessories/{id}/placement.png.
   * Returns an Observable that emits the public download URL when complete.
   */
  uploadAccessoryImage(id: string, file: File, type: 'image' | 'placement'): Observable<string> {
    const path = `accessories/${id}/${type}.png`;
    const storageRef = ref(this.storage, path);
    return from(uploadBytes(storageRef, file)).pipe(
      switchMap((snapshot) => from(getDownloadURL(snapshot.ref))),
    );
  }

  /**
   * Uploads a GLB to models/accessories/{id}.glb.
   * Returns an Observable that emits upload progress (0–100) and completes when done.
   */
  uploadAccessoryGlb(id: string, file: File): Observable<number> {
    const path = `models/accessories/${id}.glb`;
    const storageRef = ref(this.storage, path);
    const task = uploadBytesResumable(storageRef, file);
    return new Observable<number>((observer) => {
      task.on(
        'state_changed',
        (snapshot) => {
          const pct = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
          observer.next(pct);
        },
        (err) => observer.error(err),
        () => { observer.next(100); observer.complete(); },
      );
      return () => task.cancel();
    });
  }

  /**
   * Uploads a GLB to models/bodies/{id}.glb.
   * Returns an Observable that emits upload progress (0–100) and completes when done.
   */
  uploadBodyGlb(id: string, file: File): Observable<number> {
    const path = `models/bodies/${id}.glb`;
    const storageRef = ref(this.storage, path);
    const task = uploadBytesResumable(storageRef, file);
    return new Observable<number>((observer) => {
      task.on(
        'state_changed',
        (snapshot) => {
          const pct = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
          observer.next(pct);
        },
        (err) => observer.error(err),
        () => { observer.next(100); observer.complete(); },
      );
      return () => task.cancel();
    });
  }

  /**
   * Uploads a GLB to models/uniforms/{branch}_{code}_{gender}.glb.
   * Returns an Observable that emits upload progress (0–100) and completes when done.
   */
  uploadUniformGlb(branch: string, code: string, gender: string, file: File): Observable<number> {
    const path = `models/uniforms/${branch}_${code}_${gender}.glb`;
    const storageRef = ref(this.storage, path);
    const task = uploadBytesResumable(storageRef, file);
    return new Observable<number>((observer) => {
      task.on(
        'state_changed',
        (snapshot) => {
          const pct = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
          observer.next(pct);
        },
        (err) => observer.error(err),
        () => { observer.next(100); observer.complete(); },
      );
      return () => task.cancel();
    });
  }

  /**
   * Uploads a GLB to models/placeholder.glb.
   * Returns an Observable that emits upload progress (0–100) and completes when done.
   */
  uploadPlaceholderGlb(file: File): Observable<number> {
    const storageRef = ref(this.storage, 'models/placeholder.glb');
    const task = uploadBytesResumable(storageRef, file);
    return new Observable<number>((observer) => {
      task.on(
        'state_changed',
        (snapshot) => {
          const pct = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
          observer.next(pct);
        },
        (err) => observer.error(err),
        () => { observer.next(100); observer.complete(); },
      );
      return () => task.cancel();
    });
  }

  /** Returns the download URL for any models/** path. */
  async getGlbUrl(storagePath: string): Promise<string> {
    return getDownloadURL(ref(this.storage, storagePath));
  }

  /** Deletes a GLB at the given storage path. */
  async deleteGlb(storagePath: string): Promise<void> {
    await deleteObject(ref(this.storage, storagePath));
  }

  /** Returns the download URL for models/accessories/{id}.glb. */
  async getAccessoryGlbUrl(id: string): Promise<string> {
    return getDownloadURL(ref(this.storage, `models/accessories/${id}.glb`));
  }

  /**
   * Uploads a PDF to dress_pdfs/{id}.pdf.
   * Returns an Observable that emits upload progress (0–100) and completes when done.
   */
  uploadDressPdf(id: string, file: File): Observable<number> {
    const path = `dress_pdfs/${id}.pdf`;
    const storageRef = ref(this.storage, path);
    const task = uploadBytesResumable(storageRef, file);
    return new Observable<number>((observer) => {
      task.on(
        'state_changed',
        (snapshot) => {
          const pct = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
          observer.next(pct);
        },
        (err) => observer.error(err),
        () => { observer.next(100); observer.complete(); },
      );
      return () => task.cancel();
    });
  }

  /** Returns the download URL for dress_pdfs/{id}.pdf. */
  async getDressPdfUrl(id: string): Promise<string> {
    return getDownloadURL(ref(this.storage, `dress_pdfs/${id}.pdf`));
  }

  /**
   * Best-effort deletion of all Storage objects for an accessory.
   * Errors are swallowed — caller should not block on this.
   */
  async deleteAccessoryAssets(id: string): Promise<void> {
    const paths = [
      `accessories/${id}/image.png`,
      `accessories/${id}/placement.png`,
      `models/accessories/${id}.glb`,
    ];
    await Promise.allSettled(paths.map((p) => deleteObject(ref(this.storage, p))));
  }

  private toBodyModel(
    filename: string,
    sizeBytes: number | null,
    updated: string | null,
  ): BodyModel {
    const id = filename.replace(/\.glb$/i, '');
    const isMaternity = id.includes('maternity');
    const isFemale = id.startsWith('female');
    return {
      id,
      title: this.bodyTitle(id),
      gender: isFemale ? 'F' : 'M',
      status: isMaternity ? 'placeholder' : 'delivered',
      storagePath: `models/bodies/${filename}`,
      size: sizeBytes != null ? this.formatBytes(sizeBytes) : '—',
      date: updated != null ? this.formatDate(updated) : '—',
    };
  }

  private bodyTitle(id: string): string {
    const titles: Record<string, string> = {
      male_apose: 'Male A-pose',
      female_apose: 'Female A-pose',
      female_maternity_apose: 'Female Maternity A-pose',
    };
    return titles[id] ?? id.replace(/_/g, ' ');
  }

  private formatBytes(bytes: number): string {
    if (bytes >= 1_000_000) return `${(bytes / 1_000_000).toFixed(2)} MB`;
    if (bytes >= 1_000) return `${(bytes / 1_000).toFixed(1)} KB`;
    return `${bytes} B`;
  }

  private formatDate(iso: string): string {
    try {
      return new Date(iso).toISOString().slice(0, 16).replace('T', ' ');
    } catch {
      return '—';
    }
  }
}
