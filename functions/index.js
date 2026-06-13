const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

// =============================================
// 1. FETCH LIVE STOCK PRICE
// =============================================
// Call this from your Flutter app to get a stock price
exports.getStockPrice = functions.https.onRequest(async (req, res) => {
  // Allow requests from your Flutter app
  res.set("Access-Control-Allow-Origin", "*");

  const symbol = req.query.symbol;

  if (!symbol) {
    return res.status(400).json({ error: "Stock symbol is required" });
  }

  try {
    // Using Yahoo Finance API (free, no key needed)
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}`;
    const response = await axios.get(url);
    const data = response.data.chart.result[0];

    const price = data.meta.regularMarketPrice;
    const previousClose = data.meta.chartPreviousClose;
    const change = price - previousClose;
    const changePercent = ((change / previousClose) * 100).toFixed(2);

    return res.status(200).json({
      symbol: symbol.toUpperCase(),
      price: price,
      change: change.toFixed(2),
      changePercent: changePercent,
      currency: data.meta.currency,
    });
  } catch (error) {
    return res.status(500).json({ error: "Failed to fetch stock price" });
  }
});

// =============================================
// 2. CHECK PRICE ALERTS & SEND NOTIFICATIONS
// =============================================
// This runs automatically every 15 minutes
exports.checkPriceAlerts = functions.pubsub
  .schedule("every 15 minutes")
  .onRun(async (context) => {
    try {
      // Get all users from Firestore
      const usersSnapshot = await db.collection("users").get();

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        const uid = userDoc.id;

        if (!fcmToken) continue;

        // Get user's watchlist
        const watchlistSnapshot = await db
          .collection("users")
          .doc(uid)
          .collection("watchlist")
          .get();

        for (const stockDoc of watchlistSnapshot.docs) {
          const stockData = stockDoc.data();
          const symbol = stockData.symbol;
          const alertPrice = stockData.alertPrice;

          if (!alertPrice) continue;

          // Fetch current price
          try {
            const url = `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}`;
            const response = await axios.get(url);
            const currentPrice =
              response.data.chart.result[0].meta.regularMarketPrice;

            // Check if price crossed the alert level
            if (currentPrice >= alertPrice) {
              // Send push notification to user
              await admin.messaging().send({
                token: fcmToken,
                notification: {
                  title: `📈 Price Alert: ${symbol}`,
                  body: `${symbol} has reached ₹${currentPrice}! Your alert was set at ₹${alertPrice}`,
                },
                data: {
                  symbol: symbol,
                  price: currentPrice.toString(),
                  alertPrice: alertPrice.toString(),
                },
              });

              console.log(`Alert sent for ${symbol} to user ${uid}`);
            }
          } catch (err) {
            console.error(`Error checking price for ${symbol}:`, err);
          }
        }
      }
    } catch (error) {
      console.error("Error checking price alerts:", error);
    }

    return null;
  });

// =============================================
// 3. SAVE ALERT PRICE FOR A STOCK
// =============================================
// Call this from Flutter to set a price alert
exports.setStockAlert = functions.https.onCall(async (data, context) => {
  // Make sure user is logged in
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be logged in"
    );
  }

  const { symbol, alertPrice } = data;
  const uid = context.auth.uid;

  if (!symbol || !alertPrice) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Symbol and alert price are required"
    );
  }

  // Save alert to Firestore
  await db
    .collection("users")
    .doc(uid)
    .collection("watchlist")
    .doc(symbol)
    .set(
      {
        symbol: symbol,
        alertPrice: alertPrice,
        alertSet: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  return { success: true, message: `Alert set for ${symbol} at ₹${alertPrice}` };
});