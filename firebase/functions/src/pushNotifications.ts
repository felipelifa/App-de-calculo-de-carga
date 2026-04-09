import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const getDb = () => {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  return admin.firestore();
};

// ============================================================
// Helper: enviar notificação push para um usuário
// ============================================================
async function sendPushToUser(uid: string, payload: {
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  const db = getDb();
  const userDoc = await db.collection("users").doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) {
    functions.logger.info(`No FCM token for ${uid}`);
    return;
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data ?? {},
      android: {
        notification: {
          channelId: "general",
          priority: "high",
        },
      },
    });
    functions.logger.info(
      `Push sent to ${uid}: ${payload.title}`
    );
  } catch (err) {
    functions.logger.error(`Push failed for ${uid}`, err);
    // Se token inválido, limpa
    const msg = (err as { code?: string }).code;
    if (
      msg === "messaging/registration-token-not-registered" ||
      msg === "messaging/invalid-registration-token"
    ) {
      await db.collection("users").doc(uid).set(
        { fcmToken: null },
        { merge: true }
      );
    }
  }
}

// ============================================================
// TRIGGER: Notificar PR
// Fires when a personal record is created
// ============================================================
export const onPersonalRecordCreated = functions.firestore
  .document("users/{uid}/personalRecords/{prId}")
  .onCreate(async (snap, context) => {
    const uid = context.params.uid;
    const data = snap.data();
    await sendPushToUser(uid, {
      title: "Recorde Pessoal!",
      body: `Novo PR em ${data.exerciseName ?? "exercício"}: ${data.weight}kg × ${data.reps}`,
      data: { type: "pr", exerciseId: data.exerciseId ?? "" },
    });
    return null;
  });

// ============================================================
// TRIGGER: Notificar Deload
// Fires when progression_state changes to deload
// ============================================================
export const onDeloadActivated = functions.firestore
  .document("users/{uid}/progression_state/current")
  .onUpdate(async (change, _context) => {
    const newState = change.after.data();
    const prevState = change.before.data();

    if (newState.phase === "deload" && prevState.phase !== "deload") {
      const uid = change.after.ref.parent.parent?.id;
      if (!uid) return null;
      await sendPushToUser(uid, {
        title: "Fase de Deload",
        body: "Sua fase mudou para deload! Reduza intensidade para recuperação.",
        data: { type: "deload" },
      });
    }
    return null;
  });

// ============================================================
// SCHEDULED (daily): Checar inatividade
// Envia notificação se usuário não treina há 7+ dias
// ============================================================
export const notifyInactiveUsers = functions.pubsub
  .schedule("every day 09:00")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const db = getDb();
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const usersSnap = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .get();

    let sent = 0;
    for (const userDoc of usersSnap.docs) {
      const uid = userDoc.id;

      // Checar último workout
      const lastWorkoutSnap = await db
        .collection(`users/${uid}/workouts`)
        .orderBy("date", "desc")
        .limit(1)
        .get();

      if (lastWorkoutSnap.empty) continue;

      const lastDate = lastWorkoutSnap.docs[0].data().date;
      if (lastDate instanceof admin.firestore.Timestamp) {
        const lastWorkoutDate = lastDate.toDate();
        if (lastWorkoutDate < sevenDaysAgo) {
          await sendPushToUser(uid, {
            title: "Está sumido(a)?",
            body: "Faz mais de uma semana que não treina. Bora voltar!",
            data: { type: "inactivity" },
          });
          sent++;
        }
      }
    }
    functions.logger.info(`Inactive notifications sent: ${sent}`);
    return null;
  });
