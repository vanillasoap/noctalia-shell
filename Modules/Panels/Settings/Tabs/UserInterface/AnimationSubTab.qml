import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  // Animation type options
  readonly property var animationTypeOptions: [
    { "key": "slide", "name": I18n.tr("panels.user-interface.animation-type-slide") },
    { "key": "scale", "name": I18n.tr("panels.user-interface.animation-type-scale") },
    { "key": "fade", "name": I18n.tr("panels.user-interface.animation-type-fade") },
    { "key": "popin", "name": I18n.tr("panels.user-interface.animation-type-popin") },
    { "key": "slideFade", "name": I18n.tr("panels.user-interface.animation-type-slideFade") },
    { "key": "slideScale", "name": I18n.tr("panels.user-interface.animation-type-slideScale") },
    { "key": "none", "name": I18n.tr("panels.user-interface.animation-type-none") }
  ]

  // Easing curve options
  readonly property var easingOptions: [
    { "key": "Linear", "name": "Linear" },
    { "key": "OutQuad", "name": "OutQuad" },
    { "key": "OutCubic", "name": "OutCubic" },
    { "key": "OutQuart", "name": "OutQuart" },
    { "key": "OutQuint", "name": "OutQuint" },
    { "key": "OutExpo", "name": "OutExpo" },
    { "key": "InOutQuad", "name": "InOutQuad" },
    { "key": "InOutCubic", "name": "InOutCubic" },
    { "key": "InOutQuart", "name": "InOutQuart" },
    { "key": "OutBack", "name": I18n.tr("panels.user-interface.easing-outback") },
    { "key": "OutElastic", "name": I18n.tr("panels.user-interface.easing-outelastic") },
    { "key": "OutBounce", "name": I18n.tr("panels.user-interface.easing-outbounce") }
  ]

  NToggle {
    label: I18n.tr("panels.user-interface.animation-disable-label")
    description: I18n.tr("panels.user-interface.animation-disable-description")
    checked: Settings.data.general.animationDisabled
    defaultValue: Settings.getDefaultValue("general.animationDisabled")
    onToggled: checked => Settings.data.general.animationDisabled = checked
  }

  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true
    visible: !Settings.data.general.animationDisabled

    RowLayout {
      spacing: Style.marginL
      Layout.fillWidth: true

      NValueSlider {
        Layout.fillWidth: true
        label: I18n.tr("panels.user-interface.animation-speed-label")
        description: I18n.tr("panels.user-interface.animation-speed-description")
        from: 0
        to: 2.0
        stepSize: 0.01
        value: Settings.data.general.animationSpeed
        defaultValue: Settings.getDefaultValue("general.animationSpeed")
        onMoved: value => Settings.data.general.animationSpeed = Math.max(value, 0.05)
        text: Math.round(Settings.data.general.animationSpeed * 100) + "%"
      }

      Item {
        Layout.preferredWidth: 30 * Style.uiScaleRatio
        Layout.preferredHeight: 30 * Style.uiScaleRatio

        NIconButton {
          icon: "restore"
          baseSize: Style.baseWidgetSize * 0.8
          tooltipText: I18n.tr("panels.user-interface.animation-speed-reset")
          onClicked: Settings.data.general.animationSpeed = 1.0
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    NDivider {
      Layout.fillWidth: true
    }

    // Animation Types Section
    NText {
      text: I18n.tr("panels.user-interface.animation-types-section")
      pointSize: Style.fontSizeL
      font.weight: Style.fontWeightSemiBold
      color: Color.mOnSurface
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.animation-type-panels")
      description: I18n.tr("panels.user-interface.animation-type-panels-description")
      Layout.fillWidth: true
      model: animationTypeOptions
      currentKey: Settings.data.general.panelAnimationType
      defaultValue: Settings.getDefaultValue("general.panelAnimationType")
      onSelected: key => Settings.data.general.panelAnimationType = key
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.animation-type-notifications")
      description: I18n.tr("panels.user-interface.animation-type-notifications-description")
      Layout.fillWidth: true
      model: animationTypeOptions
      currentKey: Settings.data.general.notificationAnimationType
      defaultValue: Settings.getDefaultValue("general.notificationAnimationType")
      onSelected: key => Settings.data.general.notificationAnimationType = key
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.animation-type-osd")
      description: I18n.tr("panels.user-interface.animation-type-osd-description")
      Layout.fillWidth: true
      model: animationTypeOptions
      currentKey: Settings.data.general.osdAnimationType
      defaultValue: Settings.getDefaultValue("general.osdAnimationType")
      onSelected: key => Settings.data.general.osdAnimationType = key
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.animation-type-toasts")
      description: I18n.tr("panels.user-interface.animation-type-toasts-description")
      Layout.fillWidth: true
      model: animationTypeOptions
      currentKey: Settings.data.general.toastAnimationType
      defaultValue: Settings.getDefaultValue("general.toastAnimationType")
      onSelected: key => Settings.data.general.toastAnimationType = key
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.animation-type-menus")
      description: I18n.tr("panels.user-interface.animation-type-menus-description")
      Layout.fillWidth: true
      model: animationTypeOptions
      currentKey: Settings.data.general.menuAnimationType
      defaultValue: Settings.getDefaultValue("general.menuAnimationType")
      onSelected: key => Settings.data.general.menuAnimationType = key
    }

    NDivider {
      Layout.fillWidth: true
    }

    // Easing Curves Section
    NText {
      text: I18n.tr("panels.user-interface.easing-curves-section")
      pointSize: Style.fontSizeL
      font.weight: Style.fontWeightSemiBold
      color: Color.mOnSurface
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.easing-default")
      description: I18n.tr("panels.user-interface.easing-default-description")
      Layout.fillWidth: true
      model: easingOptions
      currentKey: Settings.data.general.easingType
      defaultValue: Settings.getDefaultValue("general.easingType")
      onSelected: key => Settings.data.general.easingType = key
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.easing-fast")
      description: I18n.tr("panels.user-interface.easing-fast-description")
      Layout.fillWidth: true
      model: easingOptions
      currentKey: Settings.data.general.easingTypeFast
      defaultValue: Settings.getDefaultValue("general.easingTypeFast")
      onSelected: key => Settings.data.general.easingTypeFast = key
    }

    NComboBox {
      label: I18n.tr("panels.user-interface.easing-slow")
      description: I18n.tr("panels.user-interface.easing-slow-description")
      Layout.fillWidth: true
      model: easingOptions
      currentKey: Settings.data.general.easingTypeSlow
      defaultValue: Settings.getDefaultValue("general.easingTypeSlow")
      onSelected: key => Settings.data.general.easingTypeSlow = key
    }
  }
}
