#include "hid_diag.h"

#include "host/ble_gap.h"

static struct ble_gap_event_listener g_diagListener;
static bool g_diagRegistered = false;
static uint16_t g_kbdHandle = 0;
static uint16_t g_mouseHandle = 0;

static const char* handleName(uint16_t h) {
  if (h == g_kbdHandle) return "keyboard(ID1)";
  if (h == g_mouseHandle) return "mouse(ID2)";
  return "OTHER";
}

static const char* subscribeReason(uint8_t r) {
  switch (r) {
    case BLE_GAP_SUBSCRIBE_REASON_WRITE: return "write";
    case BLE_GAP_SUBSCRIBE_REASON_TERM: return "term";
    case BLE_GAP_SUBSCRIBE_REASON_RESTORE: return "restore";
    default: return "?";
  }
}

static void printSecurity(uint16_t connHandle) {
  struct ble_gap_conn_desc desc;
  if (ble_gap_conn_find(connHandle, &desc) != 0) {
    Serial.print(" sec=unknown");
    return;
  }
  Serial.printf(" encrypted=%u authenticated=%u bonded=%u key_size=%u peer_id=",
                (unsigned)desc.sec_state.encrypted,
                (unsigned)desc.sec_state.authenticated,
                (unsigned)desc.sec_state.bonded,
                (unsigned)desc.sec_state.key_size);
  for (int i = 5; i >= 0; --i) {
    Serial.printf("%02X%s", desc.peer_id_addr.val[i], i ? ":" : "");
  }
  Serial.printf("/%u", (unsigned)desc.peer_id_addr.type);
}

static int diagGapEvent(struct ble_gap_event* event, void* arg) {
  (void)arg;
  const uint32_t t = millis();
  switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
      Serial.printf("[DIAG %lu] connect status=%d conn=%u", (unsigned long)t,
                    event->connect.status, (unsigned)event->connect.conn_handle);
      if (event->connect.status == 0) printSecurity(event->connect.conn_handle);
      Serial.println();
      break;
    case BLE_GAP_EVENT_DISCONNECT:
      Serial.printf("[DIAG %lu] disconnect reason=0x%03X\n", (unsigned long)t,
                    (unsigned)event->disconnect.reason);
      break;
    case BLE_GAP_EVENT_ENC_CHANGE:
      Serial.printf("[DIAG %lu] enc_change status=%d", (unsigned long)t,
                    event->enc_change.status);
      printSecurity(event->enc_change.conn_handle);
      Serial.println();
      break;
    case BLE_GAP_EVENT_REPEAT_PAIRING:
      Serial.printf("[DIAG %lu] repeat_pairing (old bond will be replaced)\n", (unsigned long)t);
      break;
    case BLE_GAP_EVENT_SUBSCRIBE:
      Serial.printf("[DIAG %lu] subscribe attr=%u(%s) reason=%s notify %u->%u indicate %u->%u",
                    (unsigned long)t,
                    (unsigned)event->subscribe.attr_handle,
                    handleName(event->subscribe.attr_handle),
                    subscribeReason(event->subscribe.reason),
                    (unsigned)event->subscribe.prev_notify,
                    (unsigned)event->subscribe.cur_notify,
                    (unsigned)event->subscribe.prev_indicate,
                    (unsigned)event->subscribe.cur_indicate);
      printSecurity(event->subscribe.conn_handle);
      Serial.println();
      break;
    default:
      break;
  }
  return 0;
}

void printBuildIdentity() {
  Serial.printf("Build: %s compiled %s %s\n", FIRMWARE_BUILD_ID, __DATE__, __TIME__);
}

void hidDiagBegin(uint16_t keyboardValueHandle, uint16_t mouseValueHandle) {
  g_kbdHandle = keyboardValueHandle;
  g_mouseHandle = mouseValueHandle;
  printBuildIdentity();
  Serial.printf("[DIAG] report value handles: keyboard(ID1)=%u mouse(ID2)=%u\n",
                (unsigned)g_kbdHandle, (unsigned)g_mouseHandle);
  if (!g_diagRegistered) {
    const int rc = ble_gap_event_listener_register(&g_diagListener, diagGapEvent, nullptr);
    g_diagRegistered = (rc == 0);
    Serial.printf("[DIAG] GAP listener register rc=%d\n", rc);
  }
}
