import QtQuick

QtObject {
  id: root

  function migrate(adapter, logger, rawJson) {
    logger.i("Migration48", "Adding animation type settings (defaults apply automatically)");

    // Animation type settings have defaults in Settings.qml, no data transformation needed
    // New settings: panelAnimationType, notificationAnimationType, osdAnimationType,
    // toastAnimationType, menuAnimationType

    return true;
  }
}
