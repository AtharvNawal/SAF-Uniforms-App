/**
 * SAF Uniform Master — device-bound identity Cloud Functions.
 *
 * `claimDeviceIdentity` is the only secure path the mobile client has to
 * recover its previous Firebase uid after an uninstall + reinstall.
 * Firestore rules forbid client-side reads of `device_registrations/*`,
 * and `signInAnonymously()` mints a fresh uid every install. This
 * callable looks up (or creates) the deviceId → uid mapping with the
 * Admin SDK and returns a custom auth token the client uses to
 * `signInWithCustomToken`.
 */

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";

initializeApp();

export { composeUniformModel } from "./composeUniformModel";

// Defence-in-depth: refuse the Nil UUID. The client never has a
// legitimate reason to send it; if one arrives, it's evidence that
// the device-side cache was corrupted (see ChangeRequest
// 2026-05-09_stable-device-id-self-heal.md). Rejecting here means
// we never orphan a real `device_registrations/<correctUuid>` entry
// behind a bogus `device_registrations/00000000-…` one.
const NIL_UUID = "00000000-0000-0000-0000-000000000000";

const ClaimRequest = z.object({
  deviceId: z
    .string()
    .uuid("deviceId must be a UUID")
    .refine((v) => v !== NIL_UUID, "deviceId must not be the Nil UUID"),
  platform: z.enum(["ios", "android"]),
});

const MarkRequest = z.object({
  deviceId: z
    .string()
    .uuid("deviceId must be a UUID")
    .refine((v) => v !== NIL_UUID, "deviceId must not be the Nil UUID"),
});

const FUNCTION_OPTIONS = { region: "asia-southeast1" } as const;

export const claimDeviceIdentity = onCall(FUNCTION_OPTIONS, async (req) => {
  const parsed = ClaimRequest.safeParse(req.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { deviceId, platform } = parsed.data;

  const db = getFirestore();
  const ref = db.doc(`device_registrations/${deviceId}`);

  let uid: string;
  let profileComplete = false;

  const snap = await ref.get();
  if (snap.exists) {
    const data = snap.data() ?? {};
    uid = data.uid as string;
    profileComplete = (data.profileComplete as boolean | undefined) ?? false;
    await ref.update({ lastSeenAt: FieldValue.serverTimestamp() });
  } else {
    // Create a fresh Firebase user via Admin SDK. We do NOT use
    // anonymous auth — we want a stable uid that survives reinstalls,
    // and the only way to get the SAME uid back later is to look it
    // up by deviceId here and issue a custom token for it.
    const user = await getAuth().createUser({});
    uid = user.uid;
    await ref.set({
      uid,
      platform,
      profileComplete: false,
      createdAt: FieldValue.serverTimestamp(),
      lastSeenAt: FieldValue.serverTimestamp(),
    });
  }

  const customToken = await getAuth().createCustomToken(uid, {
    saf_device: deviceId,
  });

  return { uid, customToken, profileComplete };
});

export const markProfileComplete = onCall(FUNCTION_OPTIONS, async (req) => {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  const parsed = MarkRequest.safeParse(req.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { deviceId } = parsed.data;

  const db = getFirestore();
  const ref = db.doc(`device_registrations/${deviceId}`);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", `Unknown deviceId ${deviceId}.`);
  }
  const owningUid = snap.data()?.uid as string | undefined;
  if (owningUid !== req.auth.uid) {
    // The signed-in user does not own this device registration —
    // refuse to flip the flag. This shouldn't happen in practice
    // because the client only calls with its own deviceId, but the
    // check protects against a hostile client guessing UUIDs.
    throw new HttpsError("permission-denied", "Device not owned by caller.");
  }

  await ref.update({
    profileComplete: true,
    lastSeenAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
