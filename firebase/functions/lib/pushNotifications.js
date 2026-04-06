"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyInactiveUsers = exports.onDeloadActivated = exports.onPersonalRecordCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const db = admin.firestore();
// ============================================================
// Helper: enviar notificação push para um usuário
// ============================================================
async function sendPushToUser(uid, payload) {
    var _a, _b;
    const userDoc = await db.collection("users").doc(uid).get();
    const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
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
            data: (_b = payload.data) !== null && _b !== void 0 ? _b : {},
            android: {
                notification: {
                    channelId: "general",
                    priority: "high",
                },
            },
        });
        functions.logger.info(`Push sent to ${uid}: ${payload.title}`);
    }
    catch (err) {
        functions.logger.error(`Push failed for ${uid}`, err);
        // Se token inválido, limpa
        const msg = err.code;
        if (msg === "messaging/registration-token-not-registered" ||
            msg === "messaging/invalid-registration-token") {
            await db.collection("users").doc(uid).set({ fcmToken: null }, { merge: true });
        }
    }
}
// ============================================================
// TRIGGER: Notificar PR
// Fires when a personal record is created
// ============================================================
exports.onPersonalRecordCreated = functions.firestore
    .document("users/{uid}/personalRecords/{prId}")
    .onCreate(async (snap, context) => {
    var _a, _b;
    const uid = context.params.uid;
    const data = snap.data();
    await sendPushToUser(uid, {
        title: "Recorde Pessoal!",
        body: `Novo PR em ${(_a = data.exerciseName) !== null && _a !== void 0 ? _a : "exercício"}: ${data.weight}kg × ${data.reps}`,
        data: { type: "pr", exerciseId: (_b = data.exerciseId) !== null && _b !== void 0 ? _b : "" },
    });
    return null;
});
// ============================================================
// TRIGGER: Notificar Deload
// Fires when progression_state changes to deload
// ============================================================
exports.onDeloadActivated = functions.firestore
    .document("users/{uid}/progression_state/current")
    .onUpdate(async (change, _context) => {
    var _a;
    const newState = change.after.data();
    const prevState = change.before.data();
    if (newState.phase === "deload" && prevState.phase !== "deload") {
        const uid = (_a = change.after.ref.parent.parent) === null || _a === void 0 ? void 0 : _a.id;
        if (!uid)
            return null;
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
exports.notifyInactiveUsers = functions.pubsub
    .schedule("every day 09:00")
    .timeZone("America/Sao_Paulo")
    .onRun(async () => {
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
        if (lastWorkoutSnap.empty)
            continue;
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
//# sourceMappingURL=pushNotifications.js.map