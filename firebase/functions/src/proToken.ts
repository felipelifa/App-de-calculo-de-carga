import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

// Tokens válidos (em produção, mover para Firestore collection em vez de código estático)
// Adicionar manualmente em deploy ou Firestore: proTokens/{code}
interface ProTokenDoc {
  code: string;
  maxRedemptions: number; // -1 = ilimitado, 0 = desativado
  currentRedemptions: number;
  createdAt: admin.firestore.Timestamp;
  expiresAt?: admin.firestore.Timestamp;
  label?: string; // e.g. "beta_testers", "vip_001"
}

export const redeemProToken = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Faça login para resgatar um token"
      );
    }

    const tokenCode = data.tokenCode as string;
    if (!tokenCode || tokenCode.length < 4) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Token inválido"
      );
    }

    const uid = context.auth.uid;

    // Já é Pro?
    const userDoc = await db.doc(`users/${uid}`).get();
    if (userDoc.data()?.isPro === true) {
      return { success: true, message: "Você já é Pro!" };
    }

    // Checar token em Firestore (coleção proTokens/{code})
    const tokenRef = db.doc(`proTokens/${tokenCode}`);
    const tokenDoc = await tokenRef.get();

    if (!tokenDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Token não encontrado"
      );
    }

    const tokenData = (tokenDoc.data() || {}) as Partial<ProTokenDoc>;
    const maxRedemptions = tokenData.maxRedemptions ?? 0;
    const currentRedemptions = tokenData.currentRedemptions ?? 0;

    // Checar expiração
    if (tokenData.expiresAt) {
      const now = admin.firestore.Timestamp.now();
      if (now.toMillis() > tokenData.expiresAt!.toMillis()) {
        throw new functions.https.HttpsError("expired", "Token expirado");
      }
    }

    // Checar limite de uso
    if (currentRedemptions >= maxRedemptions) {
      throw new functions.https.HttpsError(
        "already-used",
        "Token atingiu o limite de resgates"
      );
    }

    // Aplicar Pro ao usuário
    const batch = db.batch();

    // Atualizar user com isPro
    batch.set(
      db.doc(`users/${uid}`),
      {
        isPro: true,
        proActivatedAt: admin.firestore.Timestamp.now(),
        proTokenUsed: tokenCode,
      },
      { merge: true }
    );

    // Incrementar uso do token
    batch.update(tokenRef, { currentRedemptions: currentRedemptions + 1 });

    // Registrar que este token foi usado por este usuário
    batch.set(
      db.doc(`proTokens/${tokenCode}/redemptions/${uid}`),
      {
        userId: uid,
        redeemedAt: admin.firestore.Timestamp.now(),
      },
      { merge: true }
    );

    await batch.commit();

    functions.logger.info(
      `Pro token redeemed: ${tokenCode} -> ${uid}`
    );

    return { success: true, message: "Pro ativado com sucesso!" };
  }
);
