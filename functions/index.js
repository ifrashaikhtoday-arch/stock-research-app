const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const axios = require("axios");
const cron = require("node-cron");

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin using service account key from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// =============================================
// 1. FETCH LIVE STOCK PRICE
// =============================================
app.get("/getStockPrice", async (req, res) => {
  const symbol = req.query.symbol;

  if (!symbol) {
    return res.status(400).json({ error: "Stock symbol is required" });
  }

  try {
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
// 2. SAVE ALERT PRICE FOR A STOCK
// =============================================
app.post("/setStockAlert", async (req, res) => {
  const { uid, symbol, alertPrice } = req.body;

  if (!uid || !symbol || !alertPrice) {
    return res.status(400).json({ error: "uid, symbol and alertPrice are required" });
  }

  try {
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

    return res.status(200).json({
      success: true,
      message: `Alert set for ${symbol} at ₹${alertPrice}`,
    });
  } catch (error) {
    return res.status(500).json({ error: "Failed to set alert" });
  }
});

// =============================================
// 3. CHECK PRICE ALERTS & SEND NOTIFICATIONS
// =============================================
// Runs automatically every 15 minutes
async function checkPriceAlerts() {
  console.log("Running price alert check...");
  try {
    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      const uid = userDoc.id;

      if (!fcmToken) continue;

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

        try {
          const url = `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}`;
          const response = await axios.get(url);
          const currentPrice =
            response.data.chart.result[0].meta.regularMarketPrice;

          if (currentPrice >= alertPrice) {
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
          console.error(`Error checking price for ${symbol}:`, err.message);
        }
      }
    }
  } catch (error) {
    console.error("Error checking price alerts:", error.message);
  }
}

// Schedule the check every 15 minutes
cron.schedule("*/15 * * * *", checkPriceAlerts);

// Health check route
app.get("/", (req, res) => {
  res.send("StockSense backend is running ✅");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});