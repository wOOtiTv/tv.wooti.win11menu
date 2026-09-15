import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property string cfg_language: "system"
    property bool cfg_enablePinnedGroups: true
    property string cfg_pinnedGroups: "[]"
    property bool cfg_pinnedOrderCustomized: false
    property string cfg_pinnedOrder: "[]"

    function currentLanguage() {
        var language = String(page.cfg_language || "system")

        if (language === "system") {
            language = String(Qt.locale().name || "en")
                .replace("-", "_")
                .split("_")[0]
                .toLowerCase()
        }

        return ["de", "en", "fr", "it", "nl"].indexOf(language) >= 0
            ? language
            : "en"
    }

    function resetTranslation(key) {
        var texts = {
            description: {
                de: "Entfernt alle Gruppen und stellt die alphabetische Standardsortierung wieder her. Angeheftete Apps bleiben erhalten.",
                en: "Removes all groups and restores the default alphabetical order. Pinned apps are kept.",
                fr: "Supprime tous les groupes et rétablit l’ordre alphabétique par défaut. Les applications épinglées sont conservées.",
                it: "Rimuove tutti i gruppi e ripristina l’ordine alfabetico predefinito. Le app fissate vengono mantenute.",
                nl: "Verwijdert alle groepen en herstelt de standaard alfabetische volgorde. Vastgemaakte apps blijven behouden."
            },
            title: {
                de: "Angeheftete Apps zurücksetzen?",
                en: "Reset pinned apps?",
                fr: "Réinitialiser les applications épinglées ?",
                it: "Ripristinare le app fissate?",
                nl: "Vastgemaakte apps herstellen?"
            },
            confirmation: {
                de: "Alle Gruppen und die benutzerdefinierte Reihenfolge werden entfernt. Die angehefteten Apps selbst bleiben angeheftet.",
                en: "All groups and the custom pinned order will be removed. Your pinned apps themselves will stay pinned.",
                fr: "Tous les groupes et l’ordre personnalisé seront supprimés. Les applications épinglées resteront épinglées.",
                it: "Tutti i gruppi e l’ordine personalizzato verranno rimossi. Le app fissate resteranno comunque fissate.",
                nl: "Alle groepen en de aangepaste volgorde worden verwijderd. De vastgemaakte apps zelf blijven vastgemaakt."
            }
        }

        var language = currentLanguage()
        return texts[key] && texts[key][language]
            ? texts[key][language]
            : texts[key].en
    }

    Item {
        implicitHeight: Kirigami.Units.gridUnit
    }

    Controls.CheckBox {
        Kirigami.FormData.label: i18n("Pinned apps:")
        text: i18n("Enable groups")
        checked: page.cfg_enablePinnedGroups
        onToggled: page.cfg_enablePinnedGroups = checked
    }

    Controls.Button {
        text: i18n("Reset to default")
        enabled: page.cfg_pinnedGroups !== "[]"
            || page.cfg_pinnedOrderCustomized
            || page.cfg_pinnedOrder !== "[]"
        onClicked: resetPinnedDialog.open()
    }

    Controls.Label {
        text: page.resetTranslation("description")
        wrapMode: Text.WordWrap
        opacity: 0.7
        Layout.fillWidth: true
    }

    Controls.Dialog {
        id: resetPinnedDialog

        title: page.resetTranslation("title")
        modal: true
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        width: Math.min(460, page.width - 40)
        x: Math.round((page.width - width) / 2)
        y: Math.max(20, Math.round((page.height - height) / 2))

        contentItem: Controls.Label {
            width: parent ? parent.width : 360
            text: page.resetTranslation("confirmation")
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            page.cfg_pinnedGroups = "[]"
            page.cfg_pinnedOrder = "[]"
            page.cfg_pinnedOrderCustomized = false
        }
    }
}
