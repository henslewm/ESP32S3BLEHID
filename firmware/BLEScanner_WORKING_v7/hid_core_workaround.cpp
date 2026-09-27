#include "hid_core_workaround.h"

// Standard C++ private-member access: access checking does not apply to the
// template arguments of an explicit instantiation ([temp.spec]/6), so this
// yields a pointer to BLEService::m_characteristicMap without editing the core.
namespace {
struct ServiceCharacteristicMapTag {
  using type = BLECharacteristicMap BLEService::*;
  friend type characteristicMapMember(ServiceCharacteristicMapTag);
};

template <typename Tag, typename Tag::type Member>
struct PrivateMemberAccess {
  friend typename Tag::type characteristicMapMember(Tag) { return Member; }
};

template struct PrivateMemberAccess<ServiceCharacteristicMapTag, &BLEService::m_characteristicMap>;
}  // namespace

BLECharacteristic* hidAddInputReport(BLEHIDDevice* hid, uint8_t reportId) {
  if (hid == nullptr || hid->hidService() == nullptr) return nullptr;

  const BLEUUID reportUuid((uint16_t)0x2a4d);
  BLECharacteristic* report = new BLECharacteristic(
      reportUuid, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  // Same (Bluedroid-only) permission call as the core; ignored under NimBLE.
  report->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

  BLEDescriptor* reference = new BLEDescriptor(BLEUUID((uint16_t)0x2908));
  reference->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
  uint8_t referenceValue[] = {reportId, 0x01};  // Report ID, Input report type
  reference->setValue(referenceValue, sizeof(referenceValue));
  report->addDescriptor(reference);

  BLEService* service = hid->hidService();
  (service->*characteristicMapMember(ServiceCharacteristicMapTag{})).setByUUID(report, reportUuid);
  return report;
}
